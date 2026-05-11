package service

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"svoboden/backend/internal/db"
	"svoboden/backend/internal/middleware"
)

type AuthService struct {
	q         db.Querier
	jwtSecret string
}

func NewAuthService(q db.Querier, secret string) *AuthService {
	return &AuthService{q: q, jwtSecret: secret}
}

func (s *AuthService) RequestCode(ctx context.Context, phone string) error {
	code := "0000"
	log.Printf("[DEV] SMS code for %s: %s", phone, code)

	_, err := s.q.CreateVerification(ctx, db.CreateVerificationParams{
		Phone:     phone,
		Code:      code,
		ExpiresAt: time.Now().Add(10 * time.Minute),
	})
	return err
}

func (s *AuthService) VerifyCode(ctx context.Context, phone, code string) (string, error) {
	v, err := s.q.GetActiveVerification(ctx, phone)
	if err != nil {
		return "", fmt.Errorf("invalid or expired code")
	}
	if v.Code != code {
		return "", fmt.Errorf("invalid or expired code")
	}
	if err := s.q.MarkVerificationUsed(ctx, v.ID); err != nil {
		return "", err
	}

	user, err := s.q.GetUserByPhone(ctx, phone)
	if err != nil {
		user, err = s.q.CreateUser(ctx, phone)
		if err != nil {
			return "", fmt.Errorf("failed to create user: %w", err)
		}
	}

	claims := &middleware.Claims{
		Phone: phone,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   user.ID.String(),
			Issuer:    "svoboden",
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(30 * 24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.jwtSecret))
}
