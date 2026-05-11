package service

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"svoboden/backend/internal/db"
	"svoboden/backend/internal/geocode"
	"svoboden/backend/internal/middleware"
	"svoboden/backend/internal/ws"
)

type StatusService struct {
	q   db.Querier
	hub *ws.Hub
}

func (s *StatusService) SetHub(h *ws.Hub) {
	s.hub = h
}

func NewStatusService(q db.Querier) *StatusService {
	return &StatusService{q: q}
}

type SetStatusParams struct {
	DurationMinutes int      `json:"duration_minutes"`
	Activities      []string `json:"activities"`
	Lat             *float64 `json:"lat"`
	Lon             *float64 `json:"lon"`
}

func (s *StatusService) GetActiveStatus(ctx context.Context) (*db.UserStatus, error) {
	userID, ok := middleware.UserIDFromContext(ctx)
	if !ok {
		return nil, fmt.Errorf("unauthorized")
	}
	uid, err := uuid.Parse(userID)
	if err != nil {
		return nil, fmt.Errorf("invalid user ID: %w", err)
	}
	status, err := s.q.GetActiveStatus(ctx, uid)
	if err != nil {
		return nil, err
	}
	return &status, nil
}

func (s *StatusService) SetStatus(ctx context.Context, params SetStatusParams) (*db.UserStatus, error) {
	userID, ok := middleware.UserIDFromContext(ctx)
	if !ok {
		return nil, fmt.Errorf("unauthorized")
	}
	uid, err := uuid.Parse(userID)
	if err != nil {
		return nil, fmt.Errorf("invalid user ID: %w", err)
	}

	if err := s.q.DeleteActiveStatuses(ctx, uid); err != nil {
		return nil, err
	}

	expiresAt := time.Now().Add(time.Duration(params.DurationMinutes) * time.Minute)

	acts := params.Activities
	if acts == nil {
		acts = []string{}
	}

	createParams := db.CreateStatusParams{
		UserID:     uid,
		ExpiresAt:  expiresAt,
		Activities: acts,
	}

	if params.Lat != nil {
		createParams.Lat = sql.NullFloat64{Float64: *params.Lat, Valid: true}
	}
	if params.Lon != nil {
		createParams.Lon = sql.NullFloat64{Float64: *params.Lon, Valid: true}
	}

	if params.Lat != nil && params.Lon != nil {
		if d := geocode.ReverseGeocode(ctx, *params.Lat, *params.Lon); d != "" {
			createParams.District = sql.NullString{String: d, Valid: true}
		}
	}

	status, err := s.q.CreateStatus(ctx, createParams)
	if err != nil {
		return nil, err
	}
	if s.hub != nil {
		_ = s.hub.Publish(ctx, ws.Message{
			Type:   "status_set",
			UserID: uid.String(),
			Data: map[string]any{
				"expires_at":  status.ExpiresAt.UTC().Format("2006-01-02T15:04:05Z"),
				"activities": status.Activities,
				"district":   status.District.String,
			},
		})
	}
	return &status, nil
}

func (s *StatusService) ClearStatus(ctx context.Context) error {
	userID, ok := middleware.UserIDFromContext(ctx)
	if !ok {
		return fmt.Errorf("unauthorized")
	}
	uid, err := uuid.Parse(userID)
	if err != nil {
		return fmt.Errorf("invalid user ID: %w", err)
	}
	err = s.q.DeleteUserStatus(ctx, uid)
	if err == nil && s.hub != nil {
		_ = s.hub.Publish(ctx, ws.Message{Type: "status_cleared", UserID: uid.String()})
	}
	return err
}
