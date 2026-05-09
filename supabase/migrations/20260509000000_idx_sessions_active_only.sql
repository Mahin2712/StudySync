CREATE INDEX IF NOT EXISTS idx_sessions_active_only
ON study_sessions(is_active)
WHERE is_active = true;
