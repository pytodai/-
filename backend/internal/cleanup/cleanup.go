package cleanup

import (
	"context"
	"log"
	"time"

	"svoboden/backend/internal/db"
)

// RunCleaner periodically deletes status rows expired more than 24h ago.
func RunCleaner(ctx context.Context, queries db.Querier, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			cutoff := time.Now().Add(-24 * time.Hour)
			if err := queries.DeleteExpiredOlderThan(ctx, cutoff); err != nil && ctx.Err() == nil {
				log.Printf("cleanup error: %v", err)
			}
		}
	}
}
