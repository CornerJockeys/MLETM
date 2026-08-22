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
            @LocalPlayer = PlayerDirectory::Get(AccountId);

            trace("MLE TM local TM Account ID: " + AccountId);
            if (LocalPlayer is null) {
                warn("MLE TM: local player is not present in the MLE player directory.");
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
            @CurrentMap = MapDirectory::Get(MapUid);

            trace("MLE TM current Map UID: " + MapUid);
            if (CurrentMap is null) {
                warn("MLE TM: current map is not present in the MLE map directory.");
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

        @CurrentLeaderboard = CurrentMap.GetLeaderboard(LocalPlayer.division);
        if (CurrentLeaderboard is null) {
            warn("MLE TM: no " + LocalPlayer.division + " leaderboard is available for " + CurrentMap.name);
            return;
        }

        for (uint i = 0; i < CurrentLeaderboard.records.Length; i++) {
            auto record = CurrentLeaderboard.records[i];
            if (record.accountId == LocalPlayer.accountId) {
                LocalRank = i + 1;
                @LocalRecord = record;
                break;
            }
        }

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

    void ClearPlayableContext() {
        HasPlayableContext = false;
        MapUid = "";
        @CurrentMap = null;
        @CurrentLeaderboard = null;
        @LocalRecord = null;
        LocalRank = 0;
    }
}
