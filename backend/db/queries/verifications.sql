-- name: CreateVerification :one
INSERT INTO phone_verifications (phone, code, expires_at)
VALUES ($1, $2, $3)
RETURNING *;

-- name: GetActiveVerification :one
SELECT * FROM phone_verifications
WHERE phone = $1
  AND used = false
  AND expires_at > now()
ORDER BY created_at DESC
LIMIT 1;

-- name: MarkVerificationUsed :exec
UPDATE phone_verifications SET used = true WHERE id = $1;
