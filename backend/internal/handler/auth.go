package handler

import (
	"encoding/json"
	"net/http"

	"svoboden/backend/internal/service"
)

type AuthHandler struct {
	svc *service.AuthService
}

func NewAuthHandler(svc *service.AuthService) *AuthHandler {
	return &AuthHandler{svc: svc}
}

type requestPhoneBody struct {
	Phone string `json:"phone"`
}

type verifyPhoneBody struct {
	Phone string `json:"phone"`
	Code  string `json:"code"`
}

func (h *AuthHandler) RequestPhone(w http.ResponseWriter, r *http.Request) {
	var body requestPhoneBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Phone == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "phone required"})
		return
	}
	if err := h.svc.RequestCode(r.Context(), body.Phone); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *AuthHandler) VerifyPhone(w http.ResponseWriter, r *http.Request) {
	var body verifyPhoneBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Phone == "" || body.Code == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "phone and code required"})
		return
	}
	token, err := h.svc.VerifyCode(r.Context(), body.Phone, body.Code)
	if err != nil {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"token": token})
}
