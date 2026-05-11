package service

import (
	"context"
	"database/sql"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"svoboden/backend/internal/db"
	"svoboden/backend/internal/middleware"
	"svoboden/backend/internal/push"
)

type FriendsService struct {
	q    db.Querier
	apns *push.Client
}

func NewFriendsService(q db.Querier, apns *push.Client) *FriendsService {
	return &FriendsService{q: q, apns: apns}
}

func (s *FriendsService) SendRequest(ctx context.Context, toUsername string) (*db.FriendRequest, error) {
	callerID, err := callerUUID(ctx)
	if err != nil {
		return nil, err
	}
	toUsername = strings.ToLower(strings.TrimSpace(toUsername))
	target, err := s.q.GetUserByUsername(ctx, toUsername)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}
	if err != nil {
		return nil, err
	}
	if target.ID == callerID {
		return nil, fmt.Errorf("cannot add yourself")
	}
	fr, err := s.q.SendFriendRequest(ctx, db.SendFriendRequestParams{
		FromID: callerID,
		ToID:   target.ID,
	})
	if err != nil {
		return nil, err
	}
	if s.apns != nil {
		tokens, _ := s.q.GetDeviceTokensForUser(ctx, target.ID)
		if len(tokens) > 0 {
			go s.apns.SendToTokens(tokens, "Заявка в друзья", "Кто-то хочет добавить тебя", map[string]any{
				"type":       "friend_request",
				"request_id": fr.ID.String(),
				"from_id":    callerID.String(),
			})
		}
	}
	return &fr, nil
}

func (s *FriendsService) GetPendingRequests(ctx context.Context) ([]db.GetPendingRequestsForUserRow, error) {
	callerID, err := callerUUID(ctx)
	if err != nil {
		return nil, err
	}
	return s.q.GetPendingRequestsForUser(ctx, callerID)
}

func (s *FriendsService) RespondToRequest(ctx context.Context, requestID string, accept bool) error {
	callerID, err := callerUUID(ctx)
	if err != nil {
		return err
	}
	rid, err := uuid.Parse(requestID)
	if err != nil {
		return fmt.Errorf("invalid request id")
	}
	fr, err := s.q.GetFriendRequest(ctx, rid)
	if err == sql.ErrNoRows {
		return fmt.Errorf("request not found")
	}
	if err != nil {
		return err
	}
	if fr.ToID != callerID {
		return fmt.Errorf("not authorized")
	}

	status := "declined"
	if accept {
		status = "accepted"
	}
	_, err = s.q.UpdateFriendRequestStatus(ctx, db.UpdateFriendRequestStatusParams{
		ID:     rid,
		Status: status,
	})
	if err != nil {
		return err
	}

	if accept {
		err = s.q.CreateFriendship(ctx, db.CreateFriendshipParams{
			UserID:   callerID,
			FriendID: fr.FromID,
		})
	}
	return err
}

func (s *FriendsService) GetFriends(ctx context.Context) ([]db.GetFriendsWithStatusRow, error) {
	callerID, err := callerUUID(ctx)
	if err != nil {
		return nil, err
	}
	return s.q.GetFriendsWithStatus(ctx, callerID)
}

func (s *FriendsService) RemoveFriend(ctx context.Context, friendID string) error {
	callerID, err := callerUUID(ctx)
	if err != nil {
		return err
	}
	fid, err := uuid.Parse(friendID)
	if err != nil {
		return fmt.Errorf("invalid friend id")
	}
	return s.q.DeleteFriendship(ctx, db.DeleteFriendshipParams{
		UserID:   callerID,
		FriendID: fid,
	})
}

func callerUUID(ctx context.Context) (uuid.UUID, error) {
	idStr, ok := middleware.UserIDFromContext(ctx)
	if !ok {
		return uuid.UUID{}, fmt.Errorf("unauthorized")
	}
	uid, err := uuid.Parse(idStr)
	if err != nil {
		return uuid.UUID{}, fmt.Errorf("invalid user id")
	}
	return uid, nil
}
