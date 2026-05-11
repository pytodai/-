-- name: SendFriendRequest :one
INSERT INTO friend_requests (from_id, to_id)
VALUES ($1, $2)
ON CONFLICT (from_id, to_id) DO UPDATE SET status = 'pending', updated_at = now()
RETURNING *;

-- name: GetFriendRequest :one
SELECT * FROM friend_requests WHERE id = $1;

-- name: UpdateFriendRequestStatus :one
UPDATE friend_requests SET status = $2, updated_at = now()
WHERE id = $1
RETURNING *;

-- name: GetPendingRequestsForUser :many
SELECT fr.*, u.username as from_username
FROM friend_requests fr
JOIN users u ON u.id = fr.from_id
WHERE fr.to_id = $1 AND fr.status = 'pending'
ORDER BY fr.created_at DESC;

-- name: CreateFriendship :exec
INSERT INTO friendships (user_id, friend_id) VALUES ($1, $2), ($2, $1)
ON CONFLICT DO NOTHING;

-- name: DeleteFriendship :exec
DELETE FROM friendships WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1);

-- name: GetFriends :many
SELECT u.id, u.username, u.created_at
FROM friendships f
JOIN users u ON u.id = f.friend_id
WHERE f.user_id = $1
ORDER BY u.username;

-- name: AreFriends :one
SELECT EXISTS(
    SELECT 1 FROM friendships WHERE user_id = $1 AND friend_id = $2
) AS are_friends;

-- name: GetFriendsWithStatus :many
SELECT
    u.id,
    u.username,
    us.id AS status_id,
    us.expires_at,
    us.activities,
    us.district
FROM friendships f
JOIN users u ON u.id = f.friend_id
LEFT JOIN user_statuses us ON us.user_id = u.id AND us.expires_at > now()
WHERE f.user_id = $1
ORDER BY (us.id IS NOT NULL) DESC, u.username;
