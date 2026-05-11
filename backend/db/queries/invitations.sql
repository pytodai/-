-- name: CreateInvitation :one
INSERT INTO invitations (from_id, to_id, message, activity, expires_at)
VALUES ($1, $2, $3, $4, now() + interval '24 hours')
RETURNING *;

-- name: GetInvitation :one
SELECT * FROM invitations WHERE id = $1;

-- name: GetPendingInvitationsForUser :many
SELECT i.*, u.phone AS from_phone
FROM invitations i
JOIN users u ON u.id = i.from_id
WHERE i.to_id = $1 AND i.status = 'pending' AND i.expires_at > now()
ORDER BY i.created_at DESC;

-- name: GetSentInvitations :many
SELECT i.*, u.phone AS to_phone
FROM invitations i
JOIN users u ON u.id = i.to_id
WHERE i.from_id = $1 AND i.status = 'pending' AND i.expires_at > now()
ORDER BY i.created_at DESC;

-- name: UpdateInvitationStatus :one
UPDATE invitations SET status = $2, updated_at = now()
WHERE id = $1
RETURNING *;

-- name: CreatePing :one
INSERT INTO pings (from_id, to_id) VALUES ($1, $2) RETURNING *;

-- name: CountPingsFromUser :one
SELECT COUNT(*) FROM pings
WHERE from_id = $1 AND created_at > now() - interval '1 hour';

-- name: UpsertCallMeFlag :exec
INSERT INTO call_me_flags (user_id, expires_at)
VALUES ($1, now() + interval '4 hours')
ON CONFLICT (user_id) DO UPDATE SET enabled_at = now(), expires_at = now() + interval '4 hours';

-- name: DeleteCallMeFlag :exec
DELETE FROM call_me_flags WHERE user_id = $1;

-- name: GetActiveCallMeFlag :one
SELECT * FROM call_me_flags WHERE user_id = $1 AND expires_at > now();

-- name: UpsertDeviceToken :exec
INSERT INTO device_tokens (user_id, token, platform)
VALUES ($1, $2, $3)
ON CONFLICT (token) DO UPDATE SET user_id = $1;

-- name: DeleteDeviceToken :exec
DELETE FROM device_tokens WHERE token = $1;

-- name: GetDeviceTokensForUser :many
SELECT token FROM device_tokens WHERE user_id = $1 AND platform = 'ios';
