namespace PBMonitor {
    bool WasFinished = false;
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
        }

        auto raceData = MLFeed::GetRaceData_V4();
        if (raceData is null) {
            WasFinished = false;
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
            return;
        }

        bool isFinished = localRacePlayer.IsFinished;

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
        LastMapUid = "";
    }
}
