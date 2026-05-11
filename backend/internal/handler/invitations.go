package handler

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"svoboden/backend/internal/service"
)

type InvitationsHandler struct {
	svc *service.InvitationsService
}

func NewInvitationsHandler(svc *service.InvitationsService) *InvitationsHandler {
	return &InvitationsHandler{svc: svc}
}

func (h *InvitationsHandler) SendInvitation(w http.ResponseWriter, r *http.Request) {
	var body struct {
		ToID     string `json:"to_id"`
		Message  string `json:"message"`
		Activity string `json:"activity"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ToID == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "to_id required"})
		return
	}
	inv, err := h.svc.SendInvitation(r.Context(), body.ToID, body.Message, body.Activity)
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{
		"id":     inv.ID.String(),
		"status": inv.Status,
	})
}

func (h *InvitationsHandler) GetPending(w http.ResponseWriter, r *http.Request) {
	invs, err := h.svc.GetPending(r.Context())
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	type row struct {
		ID           string `json:"id"`
		FromID       string `json:"from_id"`
		FromUsername string `json:"from_username"`
		Message      string `json:"message,omitempty"`
		Activity     string `json:"activity,omitempty"`
	}
	out := make([]row, 0, len(invs))
	for _, i := range invs {
		out = append(out, row{
			ID:           i.ID.String(),
			FromID:       i.FromID.String(),
			FromUsername: i.FromUsername,
			Message:      i.Message.String,
			Activity:     i.Activity.String,
		})
	}
	writeJSON(w, http.StatusOK, out)
}

func (h *InvitationsHandler) AcceptInvitation(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if err := h.svc.Respond(r.Context(), id, true); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *InvitationsHandler) DeclineInvitation(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if err := h.svc.Respond(r.Context(), id, false); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *InvitationsHandler) SendPing(w http.ResponseWriter, r *http.Request) {
	var body struct {
		ToID string `json:"to_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ToID == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "to_id required"})
		return
	}
	if err := h.svc.SendPing(r.Context(), body.ToID); err != nil {
		writeJSON(w, http.StatusTooManyRequests, map[string]string{"error": err.Error()})
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *InvitationsHandler) SetCallMe(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Enabled bool `json:"enabled"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid body"})
		return
	}
	if err := h.svc.SetCallMe(r.Context(), body.Enabled); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *InvitationsHandler) RegisterToken(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Token    string `json:"token"`
		Platform string `json:"platform"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Token == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "token required"})
		return
	}
	if body.Platform == "" {
		body.Platform = "ios"
	}
	if err := h.svc.RegisterDeviceToken(r.Context(), body.Token, body.Platform); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
