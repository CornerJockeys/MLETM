namespace RuntimeState {
    string AccountId;
    string MapUid;
    string ViewedDivision;
    array<string> TeamOptions;

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

    void LoadTeamOptions() {
        if (TeamOptions.Length > 0) {
            TeamOptions.RemoveRange(0, TeamOptions.Length);
        }

        if (ApiClient::GetTeams(TeamOptions)) {
            trace("MLE TM team filter source: backend API");
            return;
        }

        for (uint i = 0; i < PlayerDirectory::Teams.Length; i++) {
            TeamOptions.InsertLast(PlayerDirectory::Teams[i]);
        }

        trace("MLE TM team filter source: local snapshot fallback");
    }

    bool SetDefaultViewedDivisionFromPlayer() {
        if (LocalPlayer is null) return false;

        string playerDivision = LocalPlayer.division.ToUpper();
        if (playerDivision != "AL" && playerDivision != "CL" && playerDivision != "ML") {
            warn("MLE TM: cannot set default leaderboard division from unsupported player division: " + playerDivision);
            return false;
        }

        ViewedDivision = playerDivision;
        LeaderboardDirty = true;
        LeaderboardLoading = false;
        @CurrentLeaderboard = null;
        @LocalRecord = null;
        LocalRank = 0;

        trace("MLE TM default leaderboard division: " + ViewedDivision);
        return true;
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
            LoadTeamOptions();

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

                SetDefaultViewedDivisionFromPlayer();
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

            // Every newly loaded map starts on the local player's canonical division.
            // Manual AL/CL/ML/combined browsing remains independent after that.
            SetDefaultViewedDivisionFromPlayer();
            LeaderboardDirty = true;
        }

        if (ViewedDivision.Length == 0 && LocalPlayer !is null) {
            SetDefaultViewedDivisionFromPlayer();
        }

        if (LeaderboardDirty) {
            ResolveLeaderboard();
        }

        HasPlayableContext = true;
    }

    bool IsSupportedViewedDivision(const string &in division) {
        return division == "AL"
            || division == "CL"
            || division == "ML"
            || division == "CL/ML"
            || division == "ALL";
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
            } else if (ViewedDivision == "ML") {
                RequestViewedDivision("CL/ML");
            } else if (ViewedDivision == "CL/ML") {
                RequestViewedDivision("ALL");
            } else {
                RequestViewedDivision("AL");
            }
            return;
        }

        if (ViewedDivision == "AL") {
            RequestViewedDivision("ALL");
        } else if (ViewedDivision == "ALL") {
            RequestViewedDivision("CL/ML");
        } else if (ViewedDivision == "CL/ML") {
            RequestViewedDivision("ML");
        } else if (ViewedDivision == "ML") {
            RequestViewedDivision("CL");
        } else {
            RequestViewedDivision("AL");
        }
    }

    MapLeaderboard@ ResolveSingleLeaderboard(const string &in mapUid, const string &in division) {
        MapLeaderboard@ resolvedLeaderboard = ApiClient::GetLeaderboard(mapUid, division);

        if (resolvedLeaderboard is null) {
            auto localMap = MapDirectory::Get(mapUid);
            if (localMap !is null) {
                @resolvedLeaderboard = localMap.GetLeaderboard(division);
            }

            if (resolvedLeaderboard !is null) {
                trace("MLE TM " + division + " leaderboard source: local snapshot fallback");
            }
        } else {
            trace("MLE TM " + division + " leaderboard source: backend API");
        }

        if (resolvedLeaderboard is null) {
            @resolvedLeaderboard = MapLeaderboard(division);
        }

        return resolvedLeaderboard;
    }

    void InsertCombinedRecord(MapLeaderboard@ combined, LeaderboardRecord@ record) {
        if (combined is null || record is null) return;

        // A player should normally only belong to one division, but deduplicate by
        // account ID anyway so stale/migrated data cannot create two ALL-view rows.
        for (uint i = 0; i < combined.records.Length; i++) {
            auto existing = combined.records[i];
            if (existing.accountId != record.accountId) continue;

            if (existing.timeMs <= record.timeMs) return;
            combined.records.RemoveAt(i);
            break;
        }

        uint insertAt = combined.records.Length;
        for (uint i = 0; i < combined.records.Length; i++) {
            if (record.timeMs < combined.records[i].timeMs) {
                insertAt = i;
                break;
            }
        }

        combined.records.InsertAt(insertAt, record);
    }

    void MergeLeaderboardInto(MapLeaderboard@ combined, MapLeaderboard@ source) {
        if (combined is null || source is null) return;

        for (uint i = 0; i < source.records.Length; i++) {
            InsertCombinedRecord(combined, source.records[i]);
        }
    }

    MapLeaderboard@ ResolveViewedLeaderboard(const string &in mapUid, const string &in view) {
        if (view == "CL/ML") {
            auto combined = MapLeaderboard("CL/ML");
            MergeLeaderboardInto(combined, ResolveSingleLeaderboard(mapUid, "CL"));
            MergeLeaderboardInto(combined, ResolveSingleLeaderboard(mapUid, "ML"));
            return combined;
        }

        if (view == "ALL") {
            auto combined = MapLeaderboard("ALL");
            MergeLeaderboardInto(combined, ResolveSingleLeaderboard(mapUid, "AL"));
            MergeLeaderboardInto(combined, ResolveSingleLeaderboard(mapUid, "CL"));
            MergeLeaderboardInto(combined, ResolveSingleLeaderboard(mapUid, "ML"));
            return combined;
        }

        return ResolveSingleLeaderboard(mapUid, view);
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

        MapLeaderboard@ resolvedLeaderboard = ResolveViewedLeaderboard(targetMapUid, targetDivision);

        // The UI can request another division while the HTTP request(s) above are in
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

    bool ViewedLeaderboardIncludesLocalDivision() {
        if (LocalPlayer is null) return false;
        if (ViewedDivision == LocalPlayer.division) return true;
        if (ViewedDivision == "ALL") return true;

        return ViewedDivision == "CL/ML"
            && (LocalPlayer.division == "CL" || LocalPlayer.division == "ML");
    }

    bool ApplyProvisionalPB(uint timeMs, uint respawns) {
        if (CurrentLeaderboard is null || LocalPlayer is null || timeMs == 0) return false;

        // Combined views may contain the local player's real division, but a view that
        // excludes it must never receive their provisional result.
        if (!ViewedLeaderboardIncludesLocalDivision()) {
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
