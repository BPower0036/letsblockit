-- name: CreateListForUser :one
INSERT INTO filter_lists (user_id)
VALUES ($1)
RETURNING token;

-- name: GetListForUser :one
SELECT token,
       downloaded,
       (SELECT COUNT(*) FROM filter_instances WHERE filter_instances.user_id = $1) AS instance_count
FROM filter_lists
WHERE filter_lists.user_id = $1
LIMIT 1;

-- name: CountListsForUser :one
SELECT COUNT(*)
FROM filter_lists
WHERE user_id = $1;

-- name: RotateListToken :exec
UPDATE filter_lists
SET token      = gen_random_uuid(),
    downloaded = false
WHERE user_id = $1
  AND token = $2;

-- name: HasUserDownloadedList :one
SELECT downloaded
FROM filter_lists
WHERE filter_lists.user_id = $1
LIMIT 1;

-- name: GetListForToken :one
SELECT id, user_id, downloaded
FROM filter_lists
WHERE token = $1
LIMIT 1;

-- name: MarkListDownloaded :exec
UPDATE filter_lists
SET downloaded    = true,
    downloaded_at = NOW()
WHERE id = $1;

-- name: GetActiveFiltersForUser :many
SELECT filter_name, params
FROM filter_instances
WHERE user_id = $1;

-- name: CreateInstanceForUserAndFilter :exec
INSERT INTO filter_instances (filter_list_id, user_id, filter_name, params)
VALUES ((SELECT id FROM filter_lists WHERE user_id = $1), $1, $2, $3);

-- name: UpdateInstanceForUserAndFilter :exec
UPDATE filter_instances
SET params     = $3,
    updated_at = NOW()
WHERE (user_id = $1 AND filter_name = $2);

-- name: GetInstanceForUserAndFilter :one
SELECT params
FROM filter_instances
WHERE (user_id = $1 AND filter_name = $2);

-- name: CountInstanceForUserAndFilter :one
SELECT COUNT(*)
FROM filter_instances
WHERE (user_id = $1 AND filter_name = $2);

-- name: DeleteInstanceForUserAndFilter :exec
DELETE
FROM filter_instances
WHERE (user_id = $1 AND filter_name = $2);

-- name: GetInstancesForList :many
SELECT filter_name, params
FROM filter_instances
WHERE filter_list_id = $1
ORDER BY filter_name ASC;

-- name: GetStats :one
SELECT (SELECT COUNT(*) FROM filter_lists)                                                  as lists_total,
       (SELECT COUNT(*) FROM filter_lists WHERE downloaded IS TRUE)                         as lists_active,
       (SELECT COUNT(*) FROM filter_lists WHERE downloaded_at >= NOW() - INTERVAL '7 DAYS') as lists_fresh;

-- name: GetInstanceStats :many
SELECT COUNT(*), filter_name
FROM filter_instances
GROUP BY filter_name;

-- name: GetBannedUsers :many
SELECT user_id
from banned_users
WHERE lifted_at IS NULL;

-- name: GetFilterTemplates :many
SELECT *
FROM filter_templates;

-- name: RegisterNewTemplate :one
INSERT INTO filter_templates (filter_name, template_hash)
VALUES ($1, $2)
RETURNING *;

-- name: RegisterUpdatedTemplate :one
UPDATE filter_templates
SET template_hash = $2,
    updated_at    = NOW()
WHERE id = $1
RETURNING *;
