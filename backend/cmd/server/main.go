package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	_ "github.com/lib/pq"

	"svoboden/backend/internal/cleanup"
	"svoboden/backend/internal/config"
	"svoboden/backend/internal/db"
	"svoboden/backend/internal/handler"
	"svoboden/backend/internal/middleware"
	"svoboden/backend/internal/service"
)

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

	queries := db.New(sqlDB)
	authSvc := service.NewAuthService(queries, cfg.JWTSecret)
	statusSvc := service.NewStatusService(queries)
	authH := handler.NewAuthHandler(authSvc)
	statusH := handler.NewStatusHandler(statusSvc)

	r := chi.NewRouter()
	r.Use(chimw.Logger)
	r.Use(chimw.Recoverer)

	r.Post("/auth/phone/request", authH.RequestPhone)
	r.Post("/auth/phone/verify", authH.VerifyPhone)

	r.Group(func(r chi.Router) {
		r.Use(middleware.JWTMiddleware(cfg.JWTSecret))
		r.Get("/me/status", statusH.GetStatus)
		r.Put("/me/status", statusH.SetStatus)
		r.Delete("/me/status", statusH.DeleteStatus)
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
