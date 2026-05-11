package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	DBUrl          string
	RedisURL       string
	JWTSecret      string
	Port           string
	APNSKeyBase64  string
	APNSKeyID      string
	APNSTeamID     string
	APNSBundleID   string
	APNSProduction bool
}

func Load() (*Config, error) {
	_ = godotenv.Load()
	cfg := &Config{
		DBUrl:          os.Getenv("DB_URL"),
		RedisURL:       os.Getenv("REDIS_URL"),
		JWTSecret:      os.Getenv("JWT_SECRET"),
		Port:           os.Getenv("PORT"),
		APNSKeyBase64:  os.Getenv("APNS_KEY_BASE64"),
		APNSKeyID:      os.Getenv("APNS_KEY_ID"),
		APNSTeamID:     os.Getenv("APNS_TEAM_ID"),
		APNSBundleID:   os.Getenv("APNS_BUNDLE_ID"),
		APNSProduction: os.Getenv("APNS_PRODUCTION") == "true",
	}
	if cfg.DBUrl == "" {
		return nil, fmt.Errorf("DB_URL is required")
	}
	if cfg.JWTSecret == "" {
		return nil, fmt.Errorf("JWT_SECRET is required")
	}
	if cfg.Port == "" {
		cfg.Port = "8080"
	}
	return cfg, nil
}
