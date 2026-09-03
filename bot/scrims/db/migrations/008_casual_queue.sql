SET search_path TO trackmania, public;

-- Players remain assigned to Academy/Champion/Master. Casual exists only as a
-- neutral scrim-level bucket for mixed-division lobbies.
ALTER TABLE scrims DROP CONSTRAINT IF EXISTS scrims_league_check;
ALTER TABLE scrims
  ADD CONSTRAINT scrims_league_check
  CHECK (league IN ('Academy', 'Champion', 'Master', 'Casual'));
