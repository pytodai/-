-- +goose Up
CREATE TABLE invitations (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    to_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message      TEXT,
    status       TEXT NOT NULL DEFAULT 'pending', -- pending | accepted | declined | expired
    activity     TEXT,
    expires_at   TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '24 hours'),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE pings (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    to_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE call_me_flags (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    enabled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '4 hours')
);

CREATE TABLE device_tokens (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token      TEXT NOT NULL UNIQUE,
    platform   TEXT NOT NULL DEFAULT 'ios',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_invitations_to     ON invitations(to_id, status);
CREATE INDEX idx_invitations_from   ON invitations(from_id);
CREATE INDEX idx_pings_to_created   ON pings(to_id, created_at DESC);
CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);

-- +goose Down
DROP TABLE IF EXISTS device_tokens;
DROP TABLE IF EXISTS call_me_flags;
DROP TABLE IF EXISTS pings;
DROP TABLE IF EXISTS invitations;
