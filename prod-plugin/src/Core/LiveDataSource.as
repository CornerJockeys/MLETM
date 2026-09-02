namespace LiveDataSource {
    bool LastUpdateOk = false;
    string Status = "Simulation mode";

    bool IsAvailable() {
#if DEPENDENCY_MLFEEDRACEDATA && DEPENDENCY_MLHOOK
        return true;
#else
        return false;
#endif
    }

    bool HasPlayground() {
        return GetApp().CurrentPlayground !is null;
    }

    bool CanUseLive() {
        return IsAvailable() && HasPlayground();
    }

    void SetSimulationStatus() {
        LastUpdateOk = true;
        if (!IsAvailable()) {
            Status = "Simulation mode - MLFeed/MLHook unavailable";
        } else if (!HasPlayground()) {
            Status = "Simulation mode - no active playground";
        } else {
            Status = "Simulation mode";
        }
    }

    string Pad2(int value) {
        string text = tostring(value);
        return value < 10 ? "0" + text : text;
    }

    string Pad3(int value) {
        string text = tostring(value);
        if (value < 10) return "00" + text;
        if (value < 100) return "0" + text;
        return text;
    }

    string FormatMs(int timeMs) {
        if (timeMs < 0) return "--";
        int minutes = timeMs / 60000;
        int seconds = (timeMs % 60000) / 1000;
        int millis = timeMs % 1000;
        return tostring(minutes) + ":" + Pad2(seconds) + "." + Pad3(millis);
    }

    string FormatGap(int gapMs) {
        if (gapMs < 0) gapMs = -gapMs;
        return "+" + Text::Format("%.3f", float(gapMs) / 1000.0f);
    }

    int ResolveTeamSlot(int teamNum) {
        if (teamNum != 1 && teamNum != 2) return -1;
        if (S_LiveTeamAIsBlue) return teamNum == 1 ? 0 : 1;
        return teamNum == 2 ? 0 : 1;
    }

    void UpdateMapName() {
        auto app = cast<CTrackMania>(GetApp());
        if (app is null || app.RootMap is null || app.RootMap.MapInfo is null) return;

        string mapName = app.RootMap.MapInfo.Name;
        if (mapName.Length > 0) MatchState::MapName = mapName.ToUpper();
    }

#if DEPENDENCY_MLFEEDRACEDATA && DEPENDENCY_MLHOOK
    void UpdateRoundScore() {
        auto teams = MLFeed::GetTeamsMMData_V1();
        if (teams is null || teams.ClanScores is null || teams.ClanScores.Length < 3) return;

        int blueScore = teams.ClanScores[1];
        int redScore = teams.ClanScores[2];

        if (S_LiveTeamAIsBlue) {
            MatchState::TeamARoundWins = MatchState::ClampRoundWins(blueScore);
            MatchState::TeamBRoundWins = MatchState::ClampRoundWins(redScore);
        } else {
            MatchState::TeamARoundWins = MatchState::ClampRoundWins(redScore);
            MatchState::TeamBRoundWins = MatchState::ClampRoundWins(blueScore);
        }
    }

    void UpdateRanking() {
        auto raceData = MLFeed::GetRaceData_V4();
        if (raceData is null) {
            LastUpdateOk = false;
            Status = "MLFeed race data unavailable";
            return;
        }

        array<ProdRankEntry@> liveEntries;
        int leaderCp = -1;
        int leaderCpTime = -1;

        for (uint i = 0; i < raceData.SortedPlayers_Race_Respawns.Length; i++) {
            auto player = cast<MLFeed::PlayerCpInfo_V4>(raceData.SortedPlayers_Race_Respawns[i]);
            if (player is null) continue;
            if (player.TeamNum != 1 && player.TeamNum != 2) continue;
            if (!player.PlayerIsRacing && !player.IsFinished) continue;

            int teamSlot = ResolveTeamSlot(player.TeamNum);
            if (teamSlot < 0) continue;

            string timeText;
            if (liveEntries.Length == 0) {
                leaderCp = player.CpCount;
                leaderCpTime = player.LastCpTime;
                timeText = player.IsFinished ? FormatMs(player.FinishTime) : "CP " + tostring(player.CpCount);
            } else if (player.CpCount == leaderCp && player.LastCpTime > 0 && leaderCpTime > 0) {
                timeText = FormatGap(player.LastCpTime - leaderCpTime);
            } else if (player.IsFinished) {
                timeText = FormatMs(player.FinishTime);
            } else {
                timeText = "CP " + tostring(player.CpCount);
            }

            string identity = player.WebServicesUserId.Length > 0 ? player.WebServicesUserId : player.Name;
            auto entry = ProdRankEntry(player.Name, teamSlot, timeText, identity);
            entry.respawn = player.NbRespawnsRequested > 0;
            entry.spectated = false;
            liveEntries.InsertLast(entry);

            // Keep more racers buffered than may currently be visible so top-N cutoff
            // changes and placement transitions remain smooth.
            if (liveEntries.Length >= LiveRankingState::MaxSupportedRows) break;
        }

        if (liveEntries.Length == 0) {
            LastUpdateOk = false;
            Status = "No active team racers found";
            return;
        }

        LiveRankingState::ApplySnapshot(liveEntries);
        LastUpdateOk = true;
        Status = "Live MLFeed: " + tostring(liveEntries.Length)
            + " racers | showing " + LiveRankingState::DisplayRowModeLabel();
    }
#endif

    void Update() {
        // Team names, map-series score, division, match label and WR values remain
        // MLE/manual state for now. MLFeed owns race-local state only when available.
        MatchState::SyncFromSettings();
        RecordsState::SyncFromSettings();

        if (!CanUseLive()) {
            SetSimulationStatus();
            return;
        }

#if DEPENDENCY_MLFEEDRACEDATA && DEPENDENCY_MLHOOK
        UpdateMapName();
        UpdateRoundScore();
        UpdateRanking();
#else
        SetSimulationStatus();
#endif
    }
}
