namespace PBMonitor {
    bool WasFinished = false;
    bool CountdownLatched = false;
    bool KeepHiddenAfterRespawn = false;
    uint LastRespawnsRequested = 0;
    uint LastStartTime = 0;
    float LeaderboardAlpha = 1.0f;
    string LastMapUid = "";

    const float CountdownFadeMs = 3000.0f;
    const int CountdownDetectWindowMs = 4000;

    void MonitorLoop() {
        while (true) {
            CheckLocalFinish();
            sleep(25);
        }
    }

    void CheckLocalFinish() {
        if (!RuntimeState::HasPlayableContext || RuntimeState::AccountId.Length == 0) {
            ResetFinishState();
            return;
        }

        if (RuntimeState::MapUid != LastMapUid) {
            LastMapUid = RuntimeState::MapUid;
            WasFinished = false;
            CountdownLatched = false;
            KeepHiddenAfterRespawn = false;
            LastRespawnsRequested = 0;
            LastStartTime = 0;
            LeaderboardAlpha = 1.0f;
        }

        auto raceData = MLFeed::GetRaceData_V4();
        if (raceData is null) {
            WasFinished = false;
            CountdownLatched = false;
            KeepHiddenAfterRespawn = false;
            LastRespawnsRequested = 0;
            LastStartTime = 0;
            LeaderboardAlpha = 1.0f;
            return;
        }

        MLFeed::PlayerCpInfo_V4@ localRacePlayer = null;

        for (uint i = 0; i < raceData.SortedPlayers_Race.Length; i++) {
            auto player = cast<MLFeed::PlayerCpInfo_V4>(raceData.SortedPlayers_Race[i]);
            if (player is null) continue;

            if (player.WebServicesUserId == RuntimeState::AccountId) {
                @localRacePlayer = player;
                break;
            }
        }

        if (localRacePlayer is null) {
            WasFinished = false;
            CountdownLatched = false;
            KeepHiddenAfterRespawn = false;
            LastRespawnsRequested = 0;
            LastStartTime = 0;
            LeaderboardAlpha = 1.0f;
            return;
        }

        bool isFinished = localRacePlayer.IsFinished;
        int raceTime = localRacePlayer.CurrentRaceTime;
        uint respawnsRequested = localRacePlayer.NbRespawnsRequested;
        uint startTime = localRacePlayer.StartTime;

        // MLFeed resets NbRespawnsRequested back to zero when a full race restart
        // advances StartTime. That means a restart can erase the respawn-count signal
        // before we ever observe an increase. Watch both signals while the board is
        // already hidden: an ordinary checkpoint respawn raises the counter, while a
        // full restart advances StartTime.
        bool respawnDetected = respawnsRequested > LastRespawnsRequested;
        bool restartDetected = LastStartTime > 0 && startTime > LastStartTime;

        if (!isFinished
            && LeaderboardAlpha <= 0.001f
            && (respawnDetected || restartDetected)) {
            KeepHiddenAfterRespawn = true;
        }

        LastRespawnsRequested = respawnsRequested;
        LastStartTime = startTime;

        // MLFeed measures CurrentRaceTime against the player's StartTime. During the
        // pre-start countdown that makes raceTime negative, reaching zero at GO.
        // Latch onto that countdown, fade through the final three seconds, then stay
        // hidden for the run until the player finishes. If the player restarted while
        // the board was already hidden, KeepHiddenAfterRespawn overrides that fade.
        if (isFinished) {
            CountdownLatched = false;
            KeepHiddenAfterRespawn = false;
            LeaderboardAlpha = 1.0f;
        } else {
            if (raceTime >= -CountdownDetectWindowMs && raceTime <= 0) {
                CountdownLatched = true;
            }

            if (KeepHiddenAfterRespawn) {
                LeaderboardAlpha = 0.0f;
            } else if (CountdownLatched) {
                if (raceTime <= -int(CountdownFadeMs)) {
                    LeaderboardAlpha = 1.0f;
                } else if (raceTime < 0) {
                    LeaderboardAlpha = Math::Clamp(float(-raceTime) / CountdownFadeMs, 0.0f, 1.0f);
                } else {
                    LeaderboardAlpha = 0.0f;
                }
            } else {
                LeaderboardAlpha = 1.0f;
            }
        }

        if (isFinished && !WasFinished) {
            int bestTime = localRacePlayer.BestTime;
            int respawns = localRacePlayer.NbRespawnsRequested;

            if (bestTime > 0) {
                RuntimeState::ApplyProvisionalPB(
                    uint(bestTime),
                    respawns > 0 ? uint(respawns) : 0
                );
            }
        }

        WasFinished = isFinished;
    }

    void ResetFinishState() {
        WasFinished = false;
        CountdownLatched = false;
        KeepHiddenAfterRespawn = false;
        LastRespawnsRequested = 0;
        LastStartTime = 0;
        LeaderboardAlpha = 1.0f;
        LastMapUid = "";
    }
}
