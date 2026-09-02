namespace ProdHotkeys {
    array<string> HotkeyMaps = {"BATTERY", "MELODRAMA", "NIRVANA", "SKRRRT", "WHATEVER"};
    array<string> HotkeyTeams = {"DODGERS", "HIVE", "HURRICANES", "JETS", "FLAMES", "SABRES", "SPECTRE", "WIZARDS"};

    void NotifyState(const string &in message) {
        UI::ShowNotification("MLE TM PROD", message, vec4(0.10f, 0.65f, 0.45f, 0.35f), 2500);
    }

    string NextInList(const array<string>@ values, const string &in current) {
        if (values.Length == 0) return current;
        string key = current.ToUpper();
        for (uint i = 0; i < values.Length; i++) {
            if (values[i] == key) return values[(i + 1) % values.Length];
        }
        return values[0];
    }

    void ToggleMaster() {
        S_ShowProdOverlay = !S_ShowProdOverlay;
        NotifyState(S_ShowProdOverlay ? "Broadcast overlay enabled" : "Broadcast overlay hidden");
    }

    void ToggleSetupMode() {
        S_LayoutSetupMode = !S_LayoutSetupMode;
        NotifyState(S_LayoutSetupMode ? "Overlay SETUP mode - widgets unlocked" : "Overlay LIVE mode - widgets locked");
    }

    void ToggleBanner() { S_ShowMatchBanner = !S_ShowMatchBanner; }
    void ToggleRanking() { S_ShowLiveRanking = !S_ShowLiveRanking; }
    void ToggleRecords() { S_ShowRecordsPanel = !S_ShowRecordsPanel; }
    void ToggleMleLogo() { S_ShowMleLogo = !S_ShowMleLogo; }

    void ToggleChat() {
        ChatVisibility::Toggle();
        NotifyState(ChatVisibility::Hidden ? "Game chat hidden locally" : "Game chat restored");
    }

    void NextBannerPreset() {
        S_BannerPreset = (S_BannerPreset + 1) % 3;
        NotifyState("Banner preset: " + tostring(S_BannerPreset));
    }

    int MatchNumber() {
        string value = S_TestMatchLabel.ToUpper();
        if (value.StartsWith("M")) value = value.SubStr(1);
        int parsed = Text::ParseInt(value);
        return parsed < 1 ? 1 : parsed;
    }

    void AdjustMatchNumber(int delta) {
        int next = MatchNumber() + delta;
        if (next < 1) next = 1;
        if (next > 99) next = 99;
        S_TestMatchLabel = "M" + tostring(next);
        NotifyState("Match: " + S_TestMatchLabel);
    }

    void CycleDivision() {
        string division = S_TestDivision.ToUpper();
        if (division == "ACADEMY LEAGUE" || division == "ACADEMY" || division == "AL") S_TestDivision = "CHAMPION LEAGUE";
        else if (division == "CHAMPION LEAGUE" || division == "CHAMPION" || division == "CL") S_TestDivision = "MASTER LEAGUE";
        else S_TestDivision = "ACADEMY LEAGUE";
        NotifyState("Division: " + S_TestDivision);
    }

    void NextMap() {
        S_TestMapName = NextInList(HotkeyMaps, S_TestMapName);
        NotifyState("Map: " + S_TestMapName);
    }

    void NextTeamA() {
        string next = NextInList(HotkeyTeams, S_TestTeamAName);
        if (next == S_TestTeamBName) next = NextInList(HotkeyTeams, next);
        S_TestTeamAName = next;
        LiveRankingState::SyncTeams();
        NotifyState("Team A: " + S_TestTeamAName);
    }

    void NextTeamB() {
        string next = NextInList(HotkeyTeams, S_TestTeamBName);
        if (next == S_TestTeamAName) next = NextInList(HotkeyTeams, next);
        S_TestTeamBName = next;
        LiveRankingState::SyncTeams();
        NotifyState("Team B: " + S_TestTeamBName);
    }

    void SwapTeams() {
        string teamName = S_TestTeamAName;
        S_TestTeamAName = S_TestTeamBName;
        S_TestTeamBName = teamName;

        int mapScore = S_TestTeamAMapScore;
        S_TestTeamAMapScore = S_TestTeamBMapScore;
        S_TestTeamBMapScore = mapScore;

        int roundScore = S_TestTeamARoundWins;
        S_TestTeamARoundWins = S_TestTeamBRoundWins;
        S_TestTeamBRoundWins = roundScore;

        LiveRankingState::SyncTeams();
        NotifyState("Broadcast teams swapped");
    }

    void AdjustMapScore(bool teamA, int delta) {
        if (teamA) S_TestTeamAMapScore = Math::Max(0, S_TestTeamAMapScore + delta);
        else S_TestTeamBMapScore = Math::Max(0, S_TestTeamBMapScore + delta);
    }

    void AdjustRoundScore(bool teamA, int delta) {
        if (teamA) S_TestTeamARoundWins = MatchState::ClampRoundWins(S_TestTeamARoundWins + delta);
        else S_TestTeamBRoundWins = MatchState::ClampRoundWins(S_TestTeamBRoundWins + delta);
    }

    void ClearRounds() {
        S_TestTeamARoundWins = 0;
        S_TestTeamBRoundWins = 0;
        NotifyState("Round score cleared");
    }

    void CycleRankingRows() {
        if (S_RankingRowCount == 0) S_RankingRowCount = 4;
        else if (S_RankingRowCount == 4) S_RankingRowCount = 6;
        else if (S_RankingRowCount == 6) S_RankingRowCount = 8;
        else S_RankingRowCount = 0;
        NotifyState("Ranking positions: " + LiveRankingState::DisplayRowModeLabel());
    }

    void AdjustOpacity(float delta) {
        S_NonBannerOpacity = Math::Clamp(S_NonBannerOpacity + delta, 0.20f, 1.00f);
        NotifyState("Non-banner opacity: " + Text::Format("%.2f", S_NonBannerOpacity));
    }

    void ToggleLiveData() {
        S_UseLiveRaceData = !S_UseLiveRaceData;
        if (!S_UseLiveRaceData) LiveRankingState::Reset();
        NotifyState(S_UseLiveRaceData ? "Live MLFeed requested" : "Simulation data active");
    }

    void FlipBlueSide() {
        S_LiveTeamAIsBlue = !S_LiveTeamAIsBlue;
        NotifyState(S_LiveTeamAIsBlue ? "Team A mapped to Trackmania Blue" : "Team A mapped to Trackmania Red");
    }

    bool Handle(bool down, VirtualKey key) {
        if (!S_EnableBroadcastHotkeys || !down) return false;

        if (key == S_HotkeyMasterOverlay) { ToggleMaster(); return true; }
        if (key == S_HotkeyChat) { ToggleChat(); return true; }
        if (key == S_HotkeySetupMode) { ToggleSetupMode(); return true; }
        if (key == S_HotkeyBanner) { ToggleBanner(); return true; }
        if (key == S_HotkeyRanking) { ToggleRanking(); return true; }
        if (key == S_HotkeyRecords) { ToggleRecords(); return true; }
        if (key == S_HotkeyMleLogo) { ToggleMleLogo(); return true; }
        if (key == S_HotkeyNextBannerPreset) { NextBannerPreset(); return true; }
        if (key == S_HotkeyFitLayout) { LayoutState::FitCurrentResolution(); NotifyState("Layout fitted to " + LayoutState::CurrentResolutionLabel()); return true; }
        if (key == S_HotkeyResetLayout) { LayoutState::ResetDefaults(); NotifyState("Layout reset to 1080p default"); return true; }
        if (key == S_HotkeyMatchPrev) { AdjustMatchNumber(-1); return true; }
        if (key == S_HotkeyMatchNext) { AdjustMatchNumber(1); return true; }
        if (key == S_HotkeyCycleDivision) { CycleDivision(); return true; }
        if (key == S_HotkeyNextMap) { NextMap(); return true; }
        if (key == S_HotkeyNextTeamA) { NextTeamA(); return true; }
        if (key == S_HotkeyNextTeamB) { NextTeamB(); return true; }
        if (key == S_HotkeySwapTeams) { SwapTeams(); return true; }
        if (key == S_HotkeyTeamAMapPlus) { AdjustMapScore(true, 1); return true; }
        if (key == S_HotkeyTeamAMapMinus) { AdjustMapScore(true, -1); return true; }
        if (key == S_HotkeyTeamBMapPlus) { AdjustMapScore(false, 1); return true; }
        if (key == S_HotkeyTeamBMapMinus) { AdjustMapScore(false, -1); return true; }
        if (key == S_HotkeyTeamARoundPlus) { AdjustRoundScore(true, 1); return true; }
        if (key == S_HotkeyTeamARoundMinus) { AdjustRoundScore(true, -1); return true; }
        if (key == S_HotkeyTeamBRoundPlus) { AdjustRoundScore(false, 1); return true; }
        if (key == S_HotkeyTeamBRoundMinus) { AdjustRoundScore(false, -1); return true; }
        if (key == S_HotkeyClearRounds) { ClearRounds(); return true; }
        if (key == S_HotkeyRankingRows) { CycleRankingRows(); return true; }
        if (key == S_HotkeyOpacityPlus) { AdjustOpacity(0.05f); return true; }
        if (key == S_HotkeyOpacityMinus) { AdjustOpacity(-0.05f); return true; }
        if (key == S_HotkeyReloadAssets) { AssetReloadGuard::Request(); NotifyState("Asset reload queued"); return true; }
        if (key == S_HotkeyToggleLiveData) { ToggleLiveData(); return true; }
        if (key == S_HotkeyFlipBlueSide) { FlipBlueSide(); return true; }

        return false;
    }
}
