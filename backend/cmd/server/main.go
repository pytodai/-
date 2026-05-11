package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	_ "github.com/lib/pq"
	"github.com/pressly/goose/v3"
	"github.com/redis/go-redis/v9"

	"svoboden/backend/internal/cleanup"
	"svoboden/backend/internal/config"
	"svoboden/backend/internal/db"
	"svoboden/backend/internal/handler"
	"svoboden/backend/internal/middleware"
	"svoboden/backend/internal/service"
	"svoboden/backend/internal/ws"
)

func runMigrations(sqlDB *sql.DB) {
	dirs := []string{
		filepath.Join(filepath.Dir(os.Args[0]), "db", "migrations"),
		"db/migrations",
	}
	for _, dir := range dirs {
		if _, err := os.Stat(dir); err == nil {
			if err := goose.SetDialect("postgres"); err != nil {
				log.Printf("goose dialect: %v", err)
				return
			}
			if err := goose.Up(sqlDB, dir); err != nil {
				log.Printf("WARNING: migrations error (non-fatal): %v", err)
			} else {
				log.Println("migrations applied")
			}
			return
		}
	}
	log.Println("migrations directory not found, skipping")
}

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("config: %v", err)
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	sqlDB, err := sql.Open("postgres", cfg.DBUrl)
	if err != nil {
		log.Fatalf("db open: %v", err)
	}
	defer sqlDB.Close()
	if err := sqlDB.PingContext(ctx); err != nil {
		log.Fatalf("db ping: %v", err)
	}
	log.Println("database connected")

	runMigrations(sqlDB)

	var rdb *redis.Client
	if cfg.RedisURL != "" {
		opts, err := redis.ParseURL(cfg.RedisURL)
		if err != nil {
			log.Fatalf("redis url parse: %v", err)
		}
		rdb = redis.NewClient(opts)
		if err := rdb.Ping(ctx).Err(); err != nil {
			log.Printf("redis ping failed: %v — WebSocket will be unavailable", err)
			rdb = nil
		} else {
			log.Println("redis connected")
		}
	}

	queries := db.New(sqlDB)
	authSvc := service.NewAuthService(queries, cfg.JWTSecret)
	statusSvc := service.NewStatusService(queries)
	friendsSvc := service.NewFriendsService(queries)

	var hub *ws.Hub
	if rdb != nil {
		hub = ws.NewHub(rdb)
		go hub.Run(ctx)
		statusSvc.SetHub(hub)
	}

	invSvc := service.NewInvitationsService(queries, hub)

	authH := handler.NewAuthHandler(authSvc)
	statusH := handler.NewStatusHandler(statusSvc)
	friendsH := handler.NewFriendsHandler(friendsSvc)
	invH := handler.NewInvitationsHandler(invSvc)

	r := chi.NewRouter()
	r.Use(chimw.Logger)
	r.Use(chimw.Recoverer)

	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})
	r.Post("/auth/phone/request", authH.RequestPhone)
	r.Post("/auth/phone/verify", authH.VerifyPhone)

	r.Group(func(r chi.Router) {
		r.Use(middleware.JWTMiddleware(cfg.JWTSecret))

		r.Get("/me/status", statusH.GetStatus)
		r.Put("/me/status", statusH.SetStatus)
		r.Delete("/me/status", statusH.DeleteStatus)

		r.Get("/friends", friendsH.GetFriends)
		r.Post("/friends/requests", friendsH.SendRequest)
		r.Get("/friends/requests", friendsH.GetPendingRequests)
		r.Post("/friends/requests/{id}/accept", friendsH.AcceptRequest)
		r.Post("/friends/requests/{id}/decline", friendsH.DeclineRequest)
		r.Delete("/friends/{id}", friendsH.RemoveFriend)

		r.Post("/invitations", invH.SendInvitation)
		r.Get("/invitations", invH.GetPending)
		r.Post("/invitations/{id}/accept", invH.AcceptInvitation)
		r.Post("/invitations/{id}/decline", invH.DeclineInvitation)
		r.Post("/pings", invH.SendPing)
		r.Put("/me/call-me", invH.SetCallMe)
		r.Post("/me/device-token", invH.RegisterToken)

		if hub != nil {
			r.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
				userID, _ := middleware.UserIDFromContext(r.Context())
				hub.ServeWS(userID)(w, r)
			})
		}
	})

	go cleanup.RunCleaner(ctx, queries, time.Minute)

	srv := &http.Server{
		Addr:    fmt.Sprintf(":%s", cfg.Port),
		Handler: r,
	}

	go func() {
		log.Printf("listening on :%s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %v", err)
		}
	}()

	<-ctx.Done()
	log.Println("shutting down...")
	shutCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_ = srv.Shutdown(shutCtx)
}
