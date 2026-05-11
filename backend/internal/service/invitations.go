package service

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/google/uuid"
	"svoboden/backend/internal/db"
	"svoboden/backend/internal/ws"
)

type InvitationsService struct {
	q   db.Querier
	hub *ws.Hub
}

func NewInvitationsService(q db.Querier, hub *ws.Hub) *InvitationsService {
	return &InvitationsService{q: q, hub: hub}
}

func (s *InvitationsService) SendInvitation(ctx context.Context, toID string, message, activity string) (*db.Invitation, error) {
	callerID, err := callerUUID(ctx)
	if err != nil {
		return nil, err
	}
	tid, err := uuid.Parse(toID)
	if err != nil {
		return nil, fmt.Errorf("invalid to_id")
	}
	inv, err := s.q.CreateInvitation(ctx, db.CreateInvitationParams{
		FromID:   callerID,
		ToID:     tid,
		Message:  sql.NullString{String: message, Valid: message != ""},
		Activity: sql.NullString{String: activity, Valid: activity != ""},
	})
	if err != nil {
		return nil, err
	}
	if s.hub != nil {
		_ = s.hub.Publish(ctx, ws.Message{
			Type:   "invitation",
			UserID: tid.String(),
			Data: map[string]any{
				"id":       inv.ID.String(),
				"from_id":  callerID.String(),
				"message":  message,
				"activity": activity,
			},
		})
	}
	return &inv, nil
}

func (s *InvitationsService) GetPending(ctx context.Context) ([]db.GetPendingInvitationsForUserRow, error) {
	callerID, err := callerUUID(ctx)
	if err != nil {
		return nil, err
	}
	return s.q.GetPendingInvitationsForUser(ctx, callerID)
}

func (s *InvitationsService) GetSent(ctx context.Context) ([]db.GetSentInvitationsRow, error) {
	callerID, err := callerUUID(ctx)
	if err != nil {
		return nil, err
	}
	return s.q.GetSentInvitations(ctx, callerID)
}

func (s *InvitationsService) Respond(ctx context.Context, invID string, accept bool) error {
	callerID, err := callerUUID(ctx)
	if err != nil {
		return err
	}
	iid, err := uuid.Parse(invID)
	if err != nil {
		return fmt.Errorf("invalid invitation id")
	}
	inv, err := s.q.GetInvitation(ctx, iid)
	if err == sql.ErrNoRows {
		return fmt.Errorf("invitation not found")
	}
	if err != nil {
		return err
	}
	if inv.ToID != callerID {
		return fmt.Errorf("not authorized")
	}
	status := "declined"
	if accept {
		status = "accepted"
	}
	updated, err := s.q.UpdateInvitationStatus(ctx, db.UpdateInvitationStatusParams{
		ID:     iid,
		Status: status,
	})
	if err != nil {
		return err
	}
	if s.hub != nil {
		_ = s.hub.Publish(ctx, ws.Message{
			Type:   "invitation_response",
			UserID: updated.FromID.String(),
			Data:   map[string]any{"id": iid.String(), "status": status},
		})
	}
	return nil
}

func (s *InvitationsService) SendPing(ctx context.Context, toID string) error {
	callerID, err := callerUUID(ctx)
	if err != nil {
		return err
	}
	tid, err := uuid.Parse(toID)
	if err != nil {
		return fmt.Errorf("invalid to_id")
	}
	count, err := s.q.CountPingsFromUser(ctx, callerID)
	if err != nil {
		return err
	}
	if count >= 5 {
		return fmt.Errorf("rate limit: max 5 pings per hour")
	}
	ping, err := s.q.CreatePing(ctx, db.CreatePingParams{
		FromID: callerID,
		ToID:   tid,
	})
	if err != nil {
		return err
	}
	if s.hub != nil {
		_ = s.hub.Publish(ctx, ws.Message{
			Type:   "ping",
			UserID: tid.String(),
			Data:   map[string]any{"from_id": callerID.String(), "ping_id": ping.ID.String()},
		})
	}
	return nil
}

func (s *InvitationsService) SetCallMe(ctx context.Context, enabled bool) error {
	callerID, err := callerUUID(ctx)
	if err != nil {
		return err
	}
	if enabled {
		return s.q.UpsertCallMeFlag(ctx, callerID)
	}
	return s.q.DeleteCallMeFlag(ctx, callerID)
}

func (s *InvitationsService) RegisterDeviceToken(ctx context.Context, token, platform string) error {
	callerID, err := callerUUID(ctx)
	if err != nil {
		return err
	}
	return s.q.UpsertDeviceToken(ctx, db.UpsertDeviceTokenParams{
		UserID:   callerID,
		Token:    token,
		Platform: platform,
	})
}
