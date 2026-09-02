SET search_path TO trackmania, public;

CREATE TABLE IF NOT EXISTS scrim_points (
  player_id INTEGER PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
  points INTEGER NOT NULL DEFAULT 0 CHECK (points >= 0),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS scrim_point_events (
  id BIGSERIAL PRIMARY KEY,
  player_id INTEGER NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  delta INTEGER NOT NULL,
  points_before INTEGER NOT NULL CHECK (points_before >= 0),
  points_after INTEGER NOT NULL CHECK (points_after >= 0),
  reason VARCHAR(255),
  source VARCHAR(64) NOT NULL DEFAULT 'scrim_bot',
  scrim_id INTEGER REFERENCES scrims(id) ON DELETE SET NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scrim_point_events_player_id
  ON scrim_point_events(player_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_scrim_point_events_scrim_id
  ON scrim_point_events(scrim_id)
  WHERE scrim_id IS NOT NULL;
