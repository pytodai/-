-- +goose Up
-- Точные координаты больше не хранятся — только обобщённое название района.
UPDATE user_statuses SET lat = NULL, lon = NULL WHERE lat IS NOT NULL OR lon IS NOT NULL;
ALTER TABLE user_statuses DROP COLUMN IF EXISTS lat;
ALTER TABLE user_statuses DROP COLUMN IF EXISTS lon;

-- +goose Down
ALTER TABLE user_statuses ADD COLUMN lat DOUBLE PRECISION;
ALTER TABLE user_statuses ADD COLUMN lon DOUBLE PRECISION;
