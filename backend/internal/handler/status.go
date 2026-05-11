package handler

import (
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"svoboden/backend/internal/db"
	"svoboden/backend/internal/service"
)

type StatusHandler struct {
	svc *service.StatusService
}

func NewStatusHandler(svc *service.StatusService) *StatusHandler {
	return &StatusHandler{svc: svc}
}

type statusResponse struct {
	ID         string    `json:"id"`
	ExpiresAt  time.Time `json:"expires_at"`
	Activities []string  `json:"activities"`
	District   *string   `json:"district,omitempty"`
}

func toStatusResponse(s *db.UserStatus) statusResponse {
	resp := statusResponse{
		ID:         s.ID.String(),
		ExpiresAt:  s.ExpiresAt,
		Activities: s.Activities,
	}
	if s.District.Valid {
		d := s.District.String
		resp.District = &d
	}
	return resp
}

func (h *StatusHandler) GetStatus(w http.ResponseWriter, r *http.Request) {
	status, err := h.svc.GetActiveStatus(r.Context())
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			writeJSON(w, http.StatusNotFound, map[string]string{"error": "no active status"})
			return
		}
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	resp := toStatusResponse(status)
	writeJSON(w, http.StatusOK, resp)
}

func (h *StatusHandler) SetStatus(w http.ResponseWriter, r *http.Request) {
	var params service.SetStatusParams
	if err := json.NewDecoder(r.Body).Decode(&params); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid body"})
		return
	}
	if params.DurationMinutes <= 0 {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "duration_minutes must be positive"})
		return
	}
	status, err := h.svc.SetStatus(r.Context(), params)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusCreated, toStatusResponse(status))
}

func (h *StatusHandler) DeleteStatus(w http.ResponseWriter, r *http.Request) {
	if err := h.svc.ClearStatus(r.Context()); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
