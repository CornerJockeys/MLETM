namespace RuntimeState {
    string AccountId;
    string MapUid;
    string ViewedDivision;

    PlayerInfo@ LocalPlayer = null;
    MLEMapInfo@ CurrentMap = null;
    MapLeaderboard@ CurrentLeaderboard = null;
    LeaderboardRecord@ LocalRecord = null;
    uint LocalRank = 0;

    bool HasPlayableContext = false;
    bool LeaderboardDirty = false;
    bool LeaderboardLoading = false;

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

                // A new local player starts on their own division. From this point on,
                // ViewedDivision is independent and may be AL, CL, or ML on any map.
                ViewedDivision = LocalPlayer.division;
                LeaderboardDirty = true;
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

            LeaderboardDirty = true;
        }

        if (ViewedDivision.Length == 0 && LocalPlayer !is null) {
            ViewedDivision = LocalPlayer.division;
            LeaderboardDirty = true;
        }

        if (LeaderboardDirty) {
            ResolveLeaderboard();
        }

        HasPlayableContext = true;
    }

    bool IsSupportedViewedDivision(const string &in division) {
        return division == "AL" || division == "CL" || division == "ML";
    }

    void RequestViewedDivision(const string &in division) {
        string nextDivision = division.ToUpper();
        if (!IsSupportedViewedDivision(nextDivision)) return;
        if (nextDivision == ViewedDivision && CurrentLeaderboard !is null) return;

        ViewedDivision = nextDivision;
        LeaderboardDirty = true;
        LeaderboardLoading = true;
        @CurrentLeaderboard = null;
        @LocalRecord = null;
        LocalRank = 0;

        trace("MLE TM requested leaderboard division: " + ViewedDivision);
    }

    void CycleViewedDivision(int direction) {
        if (direction >= 0) {
            if (ViewedDivision == "AL") {
                RequestViewedDivision("CL");
            } else if (ViewedDivision == "CL") {
                RequestViewedDivision("ML");
            } else {
                RequestViewedDivision("AL");
            }
            return;
        }

        if (ViewedDivision == "AL") {
            RequestViewedDivision("ML");
        } else if (ViewedDivision == "ML") {
            RequestViewedDivision("CL");
        } else {
            RequestViewedDivision("AL");
        }
    }

    void ResolveLeaderboard() {
        if (LocalPlayer is null || CurrentMap is null || ViewedDivision.Length == 0) {
            LeaderboardDirty = false;
            LeaderboardLoading = false;
            @CurrentLeaderboard = null;
            @LocalRecord = null;
            LocalRank = 0;
            return;
        }

        string targetMapUid = MapUid;
        string targetDivision = ViewedDivision;

        LeaderboardDirty = false;
        LeaderboardLoading = true;

        MapLeaderboard@ resolvedLeaderboard = ApiClient::GetLeaderboard(targetMapUid, targetDivision);

        if (resolvedLeaderboard is null) {
            auto localMap = MapDirectory::Get(targetMapUid);
            if (localMap !is null) {
                @resolvedLeaderboard = localMap.GetLeaderboard(targetDivision);
            }

            if (resolvedLeaderboard !is null) {
                trace("MLE TM leaderboard source: local snapshot fallback");
            }
        } else {
            trace("MLE TM leaderboard source: backend API");
        }

        // The UI can request another division while the HTTP request above is in
        // flight. Never let an older response replace the newly requested view.
        if (targetMapUid != MapUid || targetDivision != ViewedDivision) {
            LeaderboardLoading = LeaderboardDirty;
            return;
        }

        if (resolvedLeaderboard is null) {
            @resolvedLeaderboard = MapLeaderboard(targetDivision);
            warn("MLE TM: no " + targetDivision + " leaderboard records are available for " + CurrentMap.name);
        }

        @CurrentLeaderboard = resolvedLeaderboard;
        LeaderboardLoading = false;
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

        // Browsing another division must never turn the local player's new run into
        // a record for that viewed division. Their actual division remains canonical.
        if (ViewedDivision != LocalPlayer.division) {
            trace(
                "MLE TM provisional PB skipped while viewing "
                + ViewedDivision
                + "; local player division is "
                + LocalPlayer.division
            );
            return false;
        }

        int existingIndex = -1;
        uint previousTime = 0;

        string existingTeam = "";
        string existingClubTag = "";
        string existingClubTagFormat = "";
        string existingClubId = "";

        for (uint i = 0; i < CurrentLeaderboard.records.Length; i++) {
            auto record = CurrentLeaderboard.records[i];
            if (record.accountId != LocalPlayer.accountId) continue;

            existingIndex = int(i);
            previousTime = record.timeMs;

            existingTeam = record.team;
            existingClubTag = record.clubTag;
            existingClubTagFormat = record.clubTagFormat;
            existingClubId = record.clubId;

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
            true,
            existingTeam,
            existingClubTag,
            existingClubTagFormat,
            existingClubId
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
        LeaderboardLoading = false;
        LeaderboardDirty = false;
    }
}
