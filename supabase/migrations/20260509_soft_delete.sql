-- Soft-delete pattern: add deleted_at column to modules, topics, and study_sessions.
-- Queries filter WHERE deleted_at IS NULL (handled in application layer via _activeRows).
-- Delete operations must UPDATE deleted_at = NOW() instead of hard DELETE.

ALTER TABLE modules        ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE topics         ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE study_sessions ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- Partial indexes so existing queries remain fast on the active (non-deleted) rows.
CREATE INDEX IF NOT EXISTS idx_modules_active        ON modules        (user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_topics_active         ON topics         (module_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_study_sessions_active ON study_sessions (user_id)  WHERE deleted_at IS NULL;
