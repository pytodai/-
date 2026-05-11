-- +goose Up
CREATE INDEX idx_user_statuses_user_expires ON user_statuses(user_id, expires_at);
CREATE INDEX idx_phone_verifications_phone  ON phone_verifications(phone, expires_at);

-- +goose Down
DROP INDEX IF EXISTS idx_user_statuses_user_expires;
DROP INDEX IF EXISTS idx_phone_verifications_phone;
