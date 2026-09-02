SET search_path TO trackmania, public;

CREATE TABLE IF NOT EXISTS scrim_point_awards (
  scrim_id INTEGER NOT NULL REFERENCES scrims(id) ON DELETE CASCADE,
  player_id INTEGER NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  points_awarded INTEGER NOT NULL CHECK (points_awarded > 0),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (scrim_id, player_id)
);

CREATE INDEX IF NOT EXISTS idx_scrim_point_awards_player_id
  ON scrim_point_awards(player_id, created_at DESC);
