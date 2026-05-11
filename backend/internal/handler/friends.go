package handler

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"svoboden/backend/internal/service"
)

type FriendsHandler struct {
	svc *service.FriendsService
}

func NewFriendsHandler(svc *service.FriendsService) *FriendsHandler {
	return &FriendsHandler{svc: svc}
}

func (h *FriendsHandler) GetFriends(w http.ResponseWriter, r *http.Request) {
	friends, err := h.svc.GetFriends(r.Context())
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	type friendResp struct {
		ID         string   `json:"id"`
		Phone      string   `json:"phone"`
		StatusID   *string  `json:"status_id,omitempty"`
		ExpiresAt  *string  `json:"expires_at,omitempty"`
		Activities []string `json:"activities,omitempty"`
		District   *string  `json:"district,omitempty"`
	}
	out := make([]friendResp, 0, len(friends))
	for _, f := range friends {
		fr := friendResp{
			ID:    f.ID.String(),
			Phone: f.Phone,
		}
		if f.StatusID.Valid {
			s := f.StatusID.UUID.String()
			fr.StatusID = &s
			t := f.ExpiresAt.Time.UTC().Format("2006-01-02T15:04:05Z")
			fr.ExpiresAt = &t
			fr.Activities = f.Activities
		}
		if f.District.Valid {
			fr.District = &f.District.String
		}
		out = append(out, fr)
	}
	writeJSON(w, http.StatusOK, out)
}

func (h *FriendsHandler) SendRequest(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Phone string `json:"phone"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Phone == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "phone required"})
		return
	}
	fr, err := h.svc.SendRequest(r.Context(), body.Phone)
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{
		"id":     fr.ID.String(),
		"status": fr.Status,
	})
}

func (h *FriendsHandler) GetPendingRequests(w http.ResponseWriter, r *http.Request) {
	reqs, err := h.svc.GetPendingRequests(r.Context())
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	type reqResp struct {
		ID        string `json:"id"`
		FromPhone string `json:"from_phone"`
		FromID    string `json:"from_id"`
	}
	out := make([]reqResp, 0, len(reqs))
	for _, rq := range reqs {
		out = append(out, reqResp{
			ID:        rq.ID.String(),
			FromPhone: rq.FromPhone,
			FromID:    rq.FromID.String(),
		})
	}
	writeJSON(w, http.StatusOK, out)
}

func (h *FriendsHandler) AcceptRequest(w http.ResponseWriter, r *http.Request) {
	rid := chi.URLParam(r, "id")
	if err := h.svc.RespondToRequest(r.Context(), rid, true); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *FriendsHandler) DeclineRequest(w http.ResponseWriter, r *http.Request) {
	rid := chi.URLParam(r, "id")
	if err := h.svc.RespondToRequest(r.Context(), rid, false); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *FriendsHandler) RemoveFriend(w http.ResponseWriter, r *http.Request) {
	fid := chi.URLParam(r, "id")
	if err := h.svc.RemoveFriend(r.Context(), fid); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
