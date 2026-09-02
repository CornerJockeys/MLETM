SET search_path TO trackmania, public;

CREATE TABLE IF NOT EXISTS player_state_events (
  id BIGSERIAL PRIMARY KEY,
  player_id INTEGER NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  event_type VARCHAR(64) NOT NULL CHECK (
    event_type IN (
      'salary_changed',
      'eligibility_gained',
      'eligibility_lost',
      'scrim_points_changed'
    )
  ),
  old_value JSONB,
  new_value JSONB,
  source VARCHAR(64) NOT NULL DEFAULT 'scrim_bot',
  source_ref VARCHAR(128),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_player_state_events_player_id
  ON player_state_events(player_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_player_state_events_type
  ON player_state_events(event_type, created_at DESC);
