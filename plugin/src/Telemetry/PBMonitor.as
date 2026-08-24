namespace PBMonitor {
    bool WasFinished = false;
    bool LocalRunActive = false;
    string LastMapUid = "";

    void MonitorLoop() {
        while (true) {
            CheckLocalFinish();
            sleep(100);
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
            LocalRunActive = false;
        }

        auto raceData = MLFeed::GetRaceData_V4();
        if (raceData is null) {
            WasFinished = false;
            LocalRunActive = false;
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
            LocalRunActive = false;
            return;
        }

        bool isFinished = localRacePlayer.IsFinished;

        // Keep the board visible before the run starts and after the finish. Once the
        // local player is spawned and the race clock is actually running, hide it.
        LocalRunActive = localRacePlayer.IsSpawned
            && !isFinished
            && localRacePlayer.CurrentRaceTime > 0;

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
        LocalRunActive = false;
        LastMapUid = "";
    }
}
