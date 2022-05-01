// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.13.0
// source: qUsers.sql

package db

import (
	"context"

	"github.com/google/uuid"
)

const getBannedUsers = `-- name: GetBannedUsers :many
SELECT user_id
from banned_users
WHERE lifted_at IS NULL
`

func (q *Queries) GetBannedUsers(ctx context.Context) ([]uuid.UUID, error) {
	rows, err := q.db.Query(ctx, getBannedUsers)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []uuid.UUID
	for rows.Next() {
		var user_id uuid.UUID
		if err := rows.Scan(&user_id); err != nil {
			return nil, err
		}
		items = append(items, user_id)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}
