namespace RuntimeState {
    string AccountId;
    string MapUid;

    PlayerInfo@ LocalPlayer = null;
    MLEMapInfo@ CurrentMap = null;
    MapLeaderboard@ CurrentLeaderboard = null;
    LeaderboardRecord@ LocalRecord = null;
    uint LocalRank = 0;

    bool HasPlayableContext = false;

    void MonitorLoop() {
        while (true) {
            Refresh();
            sleep(250);
        }
    }

    void Refresh() {
        auto app = cast<CGameManiaPlanet>(GetApp());
        if (app is null || app.RootMap is null || app.RootMap.MapInfo is null) {
            ClearPlayableContext();
            return;
        }

        auto cmap = app.Network.ClientManiaAppPlayground;
        if (cmap is null || cmap.LocalUser is null) {
            ClearPlayableContext();
            return;
        }

        string nextAccountId = cmap.LocalUser.WebServicesUserId;
        string nextMapUid = app.RootMap.MapInfo.MapUid;

        if (nextAccountId.Length == 0 || nextMapUid.Length == 0) {
            ClearPlayableContext();
            return;
        }

        bool playerChanged = nextAccountId != AccountId;
        bool mapChanged = nextMapUid != MapUid;

        if (playerChanged) {
            AccountId = nextAccountId;
            @LocalPlayer = ApiClient::GetPlayer(AccountId);

            if (LocalPlayer is null) {
                @LocalPlayer = PlayerDirectory::Get(AccountId);
                if (LocalPlayer !is null) {
                    trace("MLE TM player identity source: local snapshot fallback");
                }
            } else {
                trace("MLE TM player identity source: backend API");
            }

            trace("MLE TM local TM Account ID: " + AccountId);
            if (LocalPlayer is null) {
                warn("MLE TM: local player is not present in the backend or local MLE player directory.");
            } else {
                trace("MLE player identified: " + LocalPlayer.mleName);
                trace("Team: " + LocalPlayer.team);
                trace("League: " + LocalPlayer.league);
                trace("Division: " + LocalPlayer.division);
                trace("Roster Slot: " + LocalPlayer.rosterSlot);
            }
        }

        if (mapChanged) {
            MapUid = nextMapUid;
            @CurrentMap = ApiClient::GetMap(MapUid);

            if (CurrentMap is null) {
                @CurrentMap = MapDirectory::Get(MapUid);
                if (CurrentMap !is null) {
                    trace("MLE TM map metadata source: local snapshot fallback");
                }
            } else {
                trace("MLE TM map metadata source: backend API");
            }

            trace("MLE TM current Map UID: " + MapUid);
            if (CurrentMap is null) {
                warn("MLE TM: current map is not present in the backend or local MLE map directory.");
            } else {
                trace("MLE map identified: " + CurrentMap.name);
                trace("Map ID: " + CurrentMap.mapId);
                trace("Division group(s): " + string::Join(CurrentMap.groups, ", "));
            }
        }

        if (playerChanged || mapChanged) {
            ResolveLeaderboard();
        }

        HasPlayableContext = true;
    }

    void ResolveLeaderboard() {
        @CurrentLeaderboard = null;
        @LocalRecord = null;
        LocalRank = 0;

        if (LocalPlayer is null || CurrentMap is null) return;

        @CurrentLeaderboard = ApiClient::GetLeaderboard(MapUid, LocalPlayer.division);

        if (CurrentLeaderboard is null) {
            auto localMap = MapDirectory::Get(MapUid);
            if (localMap !is null) {
                @CurrentLeaderboard = localMap.GetLeaderboard(LocalPlayer.division);
            }

            if (CurrentLeaderboard !is null) {
                trace("MLE TM leaderboard source: local snapshot fallback");
            }
        } else {
            trace("MLE TM leaderboard source: backend API");
        }

        if (CurrentLeaderboard is null) {
            warn("MLE TM: no " + LocalPlayer.division + " leaderboard is available for " + CurrentMap.name);
            return;
        }

        RefreshLocalLeaderboardPosition();

        trace(
            "MLE leaderboard ready: "
            + CurrentMap.name
            + " ["
            + CurrentLeaderboard.division
            + "] - "
            + Text::Format("%d", CurrentLeaderboard.records.Length)
            + " record(s)"
        );
    }

    void RefreshLocalLeaderboardPosition() {
        @LocalRecord = null;
        LocalRank = 0;

        if (CurrentLeaderboard is null || LocalPlayer is null) return;

        for (uint i = 0; i < CurrentLeaderboard.records.Length; i++) {
            auto record = CurrentLeaderboard.records[i];
            if (record.accountId == LocalPlayer.accountId) {
                LocalRank = i + 1;
                @LocalRecord = record;
                break;
            }
        }
    }

    bool ApplyProvisionalPB(uint timeMs, uint respawns) {
        if (CurrentLeaderboard is null || LocalPlayer is null || timeMs == 0) return false;

        int existingIndex = -1;
        uint previousTime = 0;

        for (uint i = 0; i < CurrentLeaderboard.records.Length; i++) {
            auto record = CurrentLeaderboard.records[i];
            if (record.accountId != LocalPlayer.accountId) continue;

            existingIndex = int(i);
            previousTime = record.timeMs;

            if (record.timeMs <= timeMs) {
                return false;
            }
            break;
        }

        if (existingIndex >= 0) {
            CurrentLeaderboard.records.RemoveAt(uint(existingIndex));
        }

        auto provisionalRecord = LeaderboardRecord(
            LocalPlayer.accountId,
            LocalPlayer.mleName,
            timeMs,
            respawns,
            true
        );

        uint insertAt = CurrentLeaderboard.records.Length;
        for (uint i = 0; i < CurrentLeaderboard.records.Length; i++) {
            if (timeMs < CurrentLeaderboard.records[i].timeMs) {
                insertAt = i;
                break;
            }
        }

        CurrentLeaderboard.records.InsertAt(insertAt, provisionalRecord);
        RefreshLocalLeaderboardPosition();

        string previousText = previousTime > 0 ? FormatRaceTime(previousTime) : "unranked";
        trace(
            "MLE TM provisional PB applied: "
            + LocalPlayer.mleName
            + " "
            + previousText
            + " -> "
            + FormatRaceTime(timeMs)
            + " | rank "
            + Text::Format("%d", LocalRank)
        );

        return true;
    }

    void ClearPlayableContext() {
        HasPlayableContext = false;
        MapUid = "";
        @CurrentMap = null;
        @CurrentLeaderboard = null;
        @LocalRecord = null;
        LocalRank = 0;
    }
}
