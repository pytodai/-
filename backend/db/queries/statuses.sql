-- name: GetActiveStatus :one
SELECT * FROM user_statuses
WHERE user_id = $1
  AND expires_at > now()
ORDER BY created_at DESC
LIMIT 1;

-- name: CreateStatus :one
INSERT INTO user_statuses (user_id, expires_at, activities, district)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: DeleteActiveStatuses :exec
DELETE FROM user_statuses
WHERE user_id = $1
  AND expires_at > now();

-- name: DeleteUserStatus :exec
DELETE FROM user_statuses WHERE user_id = $1;

-- name: DeleteExpiredOlderThan :exec
DELETE FROM user_statuses WHERE expires_at < $1;
