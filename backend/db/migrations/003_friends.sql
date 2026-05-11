-- +goose Up
CREATE TABLE friend_requests (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    to_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status     TEXT NOT NULL DEFAULT 'pending', -- pending | accepted | declined
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (from_id, to_id)
);

CREATE TABLE friendships (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, friend_id)
);

CREATE INDEX idx_friend_requests_to    ON friend_requests(to_id, status);
CREATE INDEX idx_friend_requests_from  ON friend_requests(from_id);
CREATE INDEX idx_friendships_user      ON friendships(user_id);

-- +goose Down
DROP TABLE IF EXISTS friendships;
DROP TABLE IF EXISTS friend_requests;
