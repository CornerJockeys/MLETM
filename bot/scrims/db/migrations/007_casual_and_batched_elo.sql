SET search_path TO trackmania, public;

-- Casual scrims use the normal scrim lifecycle but do not affect production Elo.
ALTER TABLE scrims DROP CONSTRAINT IF EXISTS scrims_match_type_check;
ALTER TABLE scrims
  ADD CONSTRAINT scrims_match_type_check
  CHECK (match_type IN ('QUEUE', 'CASUAL', 'SCHEDULED'));

-- The reference Elo formula decays K based on lifetime rounds processed.
ALTER TABLE elo_ratings
  ADD COLUMN IF NOT EXISTS rounds_played INTEGER NOT NULL DEFAULT 0
  CHECK (rounds_played >= 0);

-- One finalized history row is still written per player/scrim. This JSON keeps
-- the per-round calculations that produced that final change for auditing.
ALTER TABLE elo_history
  ADD COLUMN IF NOT EXISTS round_breakdown JSONB;

-- Raw Elo changes are internal/admin events only. Delivery layers must not
-- expose these through player-facing Discord output.
ALTER TABLE player_state_events DROP CONSTRAINT IF EXISTS player_state_events_event_type_check;
ALTER TABLE player_state_events
  ADD CONSTRAINT player_state_events_event_type_check
  CHECK (
    event_type IN (
      'salary_changed',
      'eligibility_gained',
      'eligibility_lost',
      'scrim_points_changed',
      'elo_changed'
    )
  );
