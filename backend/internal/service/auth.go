package service

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
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

func normalizeUsername(u string) string {
	return strings.ToLower(strings.TrimSpace(u))
}

func validateUsername(u string) error {
	if len(u) < 3 || len(u) > 32 {
		return fmt.Errorf("username must be 3-32 characters")
	}
	for _, r := range u {
		if !(r >= 'a' && r <= 'z') && !(r >= '0' && r <= '9') && r != '_' && r != '.' {
			return fmt.Errorf("username may contain only lowercase letters, digits, '_' and '.'")
		}
	}
	return nil
}

func validatePassword(p string) error {
	if len(p) < 6 {
		return fmt.Errorf("password must be at least 6 characters")
	}
	return nil
}

func (s *AuthService) Register(ctx context.Context, username, password string) (string, error) {
	username = normalizeUsername(username)
	if err := validateUsername(username); err != nil {
		return "", err
	}
	if err := validatePassword(password); err != nil {
		return "", err
	}

	if _, err := s.q.GetUserByUsername(ctx, username); err == nil {
		return "", fmt.Errorf("username already taken")
	} else if !errors.Is(err, sql.ErrNoRows) {
		return "", err
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	user, err := s.q.CreateUser(ctx, db.CreateUserParams{
		Username:     username,
		PasswordHash: string(hash),
	})
	if err != nil {
		return "", fmt.Errorf("failed to create user: %w", err)
	}
	return s.signToken(user.ID.String(), username)
}

func (s *AuthService) Login(ctx context.Context, username, password string) (string, error) {
	username = normalizeUsername(username)
	user, err := s.q.GetUserByUsername(ctx, username)
	if err != nil {
		return "", fmt.Errorf("invalid username or password")
	}
	if user.PasswordHash == "" {
		return "", fmt.Errorf("invalid username or password")
	}
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return "", fmt.Errorf("invalid username or password")
	}
	return s.signToken(user.ID.String(), username)
}

func (s *AuthService) signToken(userID, username string) (string, error) {
	claims := &middleware.Claims{
		Username: username,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID,
			Issuer:    "svoboden",
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(30 * 24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.jwtSecret))
}

func sqlNullString(s string) sql.NullString {
	return sql.NullString{String: s, Valid: s != ""}
}
