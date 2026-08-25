namespace PBMonitor {
    bool WasFinished = false;
    bool CountdownLatched = false;
    bool KeepHiddenAfterRespawn = false;
    uint LastRespawnsRequested = 0;
    uint LastStartTime = 0;
    float LeaderboardAlpha = 1.0f;
    string LastMapUid = "";

    bool PBTransitionActive = false;
    uint PBTransitionStartedAt = 0;
    uint PBTransitionOldRank = 0;
    uint PBTransitionNewRank = 0;
    uint PBTransitionOldTotal = 0;
    uint PBTransitionNewTotal = 0;
    uint PBTransitionOldTime = 0;
    uint PBTransitionNewTime = 0;
    bool PBTransitionOldWasProvisional = false;
    string PBTransitionMapUid = "";
    string PBTransitionDivision = "";

    const float CountdownFadeMs = 3000.0f;
    const int CountdownDetectWindowMs = 4000;

    const uint PBTransitionSlideMs = 1050;
    const uint PBTransitionHoldMs = 1950;
    const uint PBTransitionTotalMs = PBTransitionSlideMs * 2 + PBTransitionHoldMs;

    void MonitorLoop() {
        while (true) {
            CheckLocalFinish();
            sleep(25);
        }
    }

    void ClearPBTransition() {
        PBTransitionActive = false;
        PBTransitionStartedAt = 0;
        PBTransitionOldRank = 0;
        PBTransitionNewRank = 0;
        PBTransitionOldTotal = 0;
        PBTransitionNewTotal = 0;
        PBTransitionOldTime = 0;
        PBTransitionNewTime = 0;
        PBTransitionOldWasProvisional = false;
        PBTransitionMapUid = "";
        PBTransitionDivision = "";
    }

    bool IsPBTransitionActive() {
        if (!PBTransitionActive) return false;

        if (PBTransitionMapUid != RuntimeState::MapUid
            || PBTransitionDivision != RuntimeState::ViewedDivision) {
            ClearPBTransition();
            return false;
        }

        uint elapsed = Time::Now - PBTransitionStartedAt;
        if (elapsed >= PBTransitionTotalMs) {
            ClearPBTransition();
            return false;
        }

        return true;
    }

    float SmoothPBTransition(float t) {
        t = Math::Clamp(t, 0.0f, 1.0f);
        return t * t * (3.0f - 2.0f * t);
    }

    float GetPBTransitionScrollProgress() {
        if (!IsPBTransitionActive()) return 1.0f;

        uint elapsed = Time::Now - PBTransitionStartedAt;

        if (elapsed < PBTransitionSlideMs) {
            float t = float(elapsed) / float(PBTransitionSlideMs);
            return 0.5f * SmoothPBTransition(t);
        }

        uint secondSlideStart = PBTransitionSlideMs + PBTransitionHoldMs;
        if (elapsed < secondSlideStart) {
            return 0.5f;
        }

        float t = float(elapsed - secondSlideStart) / float(PBTransitionSlideMs);
        return 0.5f + 0.5f * SmoothPBTransition(t);
    }

    void StartPBTransition(
        uint oldRank,
        uint oldTotal,
        uint oldTime,
        bool oldWasProvisional,
        uint newRank,
        uint newTotal,
        uint newTime
    ) {
        PBTransitionOldRank = oldRank;
        PBTransitionOldTotal = oldTotal;
        PBTransitionOldTime = oldTime;
        PBTransitionOldWasProvisional = oldWasProvisional;
        PBTransitionNewRank = newRank;
        PBTransitionNewTotal = newTotal;
        PBTransitionNewTime = newTime;
        PBTransitionMapUid = RuntimeState::MapUid;
        PBTransitionDivision = RuntimeState::ViewedDivision;
        PBTransitionStartedAt = Time::Now;
        PBTransitionActive = true;
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
            ClearPBTransition();
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
                uint oldRank = RuntimeState::LocalRank;
                uint oldTotal = RuntimeState::CurrentLeaderboard !is null
                    ? RuntimeState::CurrentLeaderboard.records.Length
                    : 0;
                uint oldTime = RuntimeState::LocalRecord !is null
                    ? RuntimeState::LocalRecord.timeMs
                    : 0;
                bool oldWasProvisional = RuntimeState::LocalRecord !is null
                    && RuntimeState::LocalRecord.provisional;

                bool applied = RuntimeState::ApplyProvisionalPB(
                    uint(bestTime),
                    respawns > 0 ? uint(respawns) : 0
                );

                if (applied) {
                    uint newTotal = RuntimeState::CurrentLeaderboard !is null
                        ? RuntimeState::CurrentLeaderboard.records.Length
                        : oldTotal;

                    StartPBTransition(
                        oldRank,
                        oldTotal,
                        oldTime,
                        oldWasProvisional,
                        RuntimeState::LocalRank,
                        newTotal,
                        uint(bestTime)
                    );
                }
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
        ClearPBTransition();
    }
}
