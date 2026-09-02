namespace ProdTestControls {
    array<string> DemoMaps = {"BATTERY", "MELODRAMA", "NIRVANA", "SKRRRT", "WHATEVER"};
    array<string> DemoTeams = {"DODGERS", "HIVE", "HURRICANES", "JETS", "FLAMES", "SABRES", "SPECTRE", "WIZARDS"};

    int FindValueIndex(const array<string>@ values, const string &in value) {
        string key = value.ToUpper();
        for (uint i = 0; i < values.Length; i++) {
            if (values[i] == key) return int(i);
        }
        return -1;
    }

    string NextValue(const array<string>@ values, const string &in value) {
        if (values.Length == 0) return value;
        int index = FindValueIndex(values, value);
        uint next = index < 0 ? 0 : (uint(index + 1) % values.Length);
        return values[next];
    }

    void ResetDemo() {
        S_ShowProdOverlay = true;
        S_ShowMatchBanner = true;
        S_ShowLiveRanking = true;
        S_ShowRecordsPanel = true;
        S_ShowMleLogo = true;
        S_BannerPreset = 0;
        S_LockBannerAspect = true;
        S_NonBannerOpacity = 0.88f;
        S_RankingRowCount = 6;
        S_LayoutSetupMode = false;
        S_UseLiveRaceData = false;
        S_LiveTeamAIsBlue = false;

        ChatVisibility::SetHidden(false);

        S_TestDivision = "CHAMPION LEAGUE";
        S_TestMatchLabel = "M7";
        S_TestMapName = "BATTERY";
        S_TestTeamAName = "FLAMES";
        S_TestTeamBName = "HURRICANES";
        S_TestTeamAMapScore = 1;
        S_TestTeamBMapScore = 0;
        S_TestTeamARoundWins = 2;
        S_TestTeamBRoundWins = 1;
        S_TestOverallWR = "0:41.686";
        S_TestDivisionWR = "0:43.247";

        MatchState::SyncFromSettings();
        RecordsState::SyncFromSettings();
        LiveRankingState::Reset();
        LiveDataSource::LastUpdateOk = true;
        LiveDataSource::Status = "Simulation mode";
        LayoutState::FitCurrentResolution();
        AssetReloadGuard::Request();
    }

    void CycleDivision() {
        string division = S_TestDivision.ToUpper();
        if (division == "CHAMPION LEAGUE" || division == "CHAMPION" || division == "CL") {
            S_TestDivision = "MASTER LEAGUE";
        } else if (division == "MASTER LEAGUE" || division == "MASTER" || division == "ML") {
            S_TestDivision = "ACADEMY LEAGUE";
        } else {
            S_TestDivision = "CHAMPION LEAGUE";
        }
    }

    void NextMap() {
        S_TestMapName = NextValue(DemoMaps, S_TestMapName);
    }

    void NextTeamA() {
        string next = NextValue(DemoTeams, S_TestTeamAName);
        if (next == S_TestTeamBName && DemoTeams.Length > 1) next = NextValue(DemoTeams, next);
        S_TestTeamAName = next;
        LiveRankingState::SyncTeams();
    }

    void NextTeamB() {
        string next = NextValue(DemoTeams, S_TestTeamBName);
        if (next == S_TestTeamAName && DemoTeams.Length > 1) next = NextValue(DemoTeams, next);
        S_TestTeamBName = next;
        LiveRankingState::SyncTeams();
    }

    void Render() {
        if (!S_ShowTestControls || !UI::IsOverlayShown()) return;

        UI::SetNextWindowSize(500, 920, UI::Cond::FirstUseEver);
        int flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::NoDocking;

        bool visible = UI::Begin("MLE TM PROD - Test Controls", flags);
        if (visible) {
            UI::Text("Broadcast widgets");
            S_ShowProdOverlay = UI::Checkbox("Master overlay", S_ShowProdOverlay);
            S_ShowMatchBanner = UI::Checkbox("Match banner", S_ShowMatchBanner);
            S_ShowLiveRanking = UI::Checkbox("Live ranking", S_ShowLiveRanking);
            S_ShowRecordsPanel = UI::Checkbox("WR panel", S_ShowRecordsPanel);
            S_ShowMleLogo = UI::Checkbox("MLE TM logo", S_ShowMleLogo);

            UI::Separator();
            UI::Text("Banner presentation");
            if (UI::Button("PROD Broadcast##preset")) S_BannerPreset = 0;
            UI::SameLine();
            if (UI::Button("Community##preset")) S_BannerPreset = 1;
            UI::SameLine();
            if (UI::Button("Minimal##preset")) S_BannerPreset = 2;
            UI::Text("Preset: " + (S_BannerPreset == 0 ? "PROD Broadcast" : (S_BannerPreset == 1 ? "Community" : "Minimal")));
            S_LockBannerAspect = UI::Checkbox("Lock banner aspect ratio", S_LockBannerAspect);

            UI::Separator();
            UI::Text("Operator / layout");
            bool oldSetupMode = S_LayoutSetupMode;
            S_LayoutSetupMode = UI::Checkbox("Setup mode - unlock drag/resize", S_LayoutSetupMode);
            if (oldSetupMode != S_LayoutSetupMode) {
                ProdHotkeys::NotifyState(S_LayoutSetupMode ? "Overlay SETUP mode - widgets unlocked" : "Overlay LIVE mode - widgets locked");
            }
            UI::Text("Mode: " + LayoutState::ModeLabel() + " | Screen: " + LayoutState::CurrentResolutionLabel());
            if (UI::Button("Fit current screen")) LayoutState::FitCurrentResolution();
            UI::SameLine();
            if (UI::Button("720p")) LayoutState::ApplyReferenceScale(720.0f / 1080.0f);
            UI::SameLine();
            if (UI::Button("900p")) LayoutState::ApplyReferenceScale(900.0f / 1080.0f);
            UI::SameLine();
            if (UI::Button("1080p")) LayoutState::ApplyReferenceScale(1.0f);
            UI::Text("Use Fit current screen on laptops/sub-1080p displays so every widget stays on-screen.");

            S_NonBannerOpacity = UI::SliderFloat("Non-banner opacity", S_NonBannerOpacity, 0.20f, 1.00f);

            bool chatHidden = ChatVisibility::Hidden;
            bool nextChatHidden = UI::Checkbox("Hide game chat locally", chatHidden);
            if (nextChatHidden != chatHidden) ChatVisibility::SetHidden(nextChatHidden);
            UI::Text("Chat: " + ChatVisibility::Status);

            UI::Separator();
            UI::Text("External presentation overrides");
            S_EnableLocalThemeOverrides = UI::Checkbox("Enable local theme/logo overrides", S_EnableLocalThemeOverrides);
            if (UI::Button("Open Overlay folder")) OverlayTheme::OpenFolder();
            UI::SameLine();
            if (UI::Button("Reload theme/assets safely")) AssetReloadGuard::Request();
            UI::Text("Folder: " + OverlayTheme::StorageRoot());
            UI::Text("Team logos: Overlay/teams/<Team>.png");
            UI::Text("MLE logo: Overlay/branding/MLETM.png");
            UI::Text("Theme: " + OverlayTheme::Status);
            UI::Text("Branding: " + BrandingLogo::Source);

            UI::Separator();
            UI::Text("Data source");
            bool wasLive = S_UseLiveRaceData;
            S_UseLiveRaceData = UI::Checkbox("Use live MLFeed race data", S_UseLiveRaceData);
            if (wasLive && !S_UseLiveRaceData) LiveRankingState::Reset();
            S_LiveTeamAIsBlue = UI::Checkbox("Team A = Trackmania Blue", S_LiveTeamAIsBlue);
            UI::Text("Status: " + LiveDataSource::Status);

            UI::Separator();
            UI::Text("Match state / simulation");
            if (UI::Button("Cycle division")) CycleDivision();
            UI::SameLine();
            UI::Text(S_TestDivision);

            UI::Text("Match number");
            if (UI::Button("M -")) ProdHotkeys::AdjustMatchNumber(-1);
            UI::SameLine();
            UI::Text(S_TestMatchLabel);
            UI::SameLine();
            if (UI::Button("M +")) ProdHotkeys::AdjustMatchNumber(1);

            if (UI::Button("Next map")) NextMap();
            UI::SameLine();
            UI::Text(S_TestMapName);

            if (UI::Button("Next Team A")) NextTeamA();
            UI::SameLine();
            if (UI::Button("Next Team B")) NextTeamB();
            UI::SameLine();
            if (UI::Button("Swap")) ProdHotkeys::SwapTeams();
            UI::Text(S_TestTeamAName + " vs " + S_TestTeamBName);

            UI::Text("Map score");
            if (UI::Button("A + Map")) ProdHotkeys::AdjustMapScore(true, 1);
            UI::SameLine();
            if (UI::Button("A - Map")) ProdHotkeys::AdjustMapScore(true, -1);
            UI::SameLine();
            UI::Text(tostring(S_TestTeamAMapScore) + " - " + tostring(S_TestTeamBMapScore));
            UI::SameLine();
            if (UI::Button("B + Map")) ProdHotkeys::AdjustMapScore(false, 1);
            UI::SameLine();
            if (UI::Button("B - Map")) ProdHotkeys::AdjustMapScore(false, -1);

            UI::Text("Round score");
            if (UI::Button("A + Round")) ProdHotkeys::AdjustRoundScore(true, 1);
            UI::SameLine();
            if (UI::Button("A - Round")) ProdHotkeys::AdjustRoundScore(true, -1);
            UI::SameLine();
            UI::Text(tostring(S_TestTeamARoundWins) + " - " + tostring(S_TestTeamBRoundWins));
            UI::SameLine();
            if (UI::Button("B + Round")) ProdHotkeys::AdjustRoundScore(false, 1);
            UI::SameLine();
            if (UI::Button("B - Round")) ProdHotkeys::AdjustRoundScore(false, -1);
            if (UI::Button("Clear rounds")) {
                S_TestTeamARoundWins = 0;
                S_TestTeamBRoundWins = 0;
            }

            UI::Separator();
            UI::Text("Ranking simulation");
            UI::Text("Positions: " + LiveRankingState::DisplayRowModeLabel());
            if (UI::Button("Auto##rankingRows")) S_RankingRowCount = 0;
            UI::SameLine();
            if (UI::Button("4##rankingRows")) S_RankingRowCount = 4;
            UI::SameLine();
            if (UI::Button("6##rankingRows")) S_RankingRowCount = 6;
            UI::SameLine();
            if (UI::Button("8##rankingRows")) S_RankingRowCount = 8;
            if (UI::Button("Simulate placement change")) LiveRankingState::SimulatePlacementChange();
            if (UI::Button("Toggle respawn indicator")) LiveRankingState::ToggleRespawn();
            UI::SameLine();
            if (UI::Button("Next spectated player")) LiveRankingState::NextSpectated();
            if (UI::Button("Reset ranking")) LiveRankingState::Reset();

            UI::Separator();
            UI::Text("Records simulation");
            if (UI::Button("Alternate WR values")) {
                if (S_TestOverallWR == "0:41.686") {
                    S_TestOverallWR = "0:40.912";
                    S_TestDivisionWR = "0:42.508";
                } else {
                    S_TestOverallWR = "0:41.686";
                    S_TestDivisionWR = "0:43.247";
                }
            }

            UI::Separator();
            UI::Text("Default hotkeys: F7 overlay | F8 chat | F9 setup | F10 banner | F11 ranking | F12 WR");
            UI::Text("Emergency score/layout/preset/reload hotkeys are available to bind under Openplanet Settings > PROD Hotkeys.");

            if (UI::Button("RESET ALL DEMO STATE")) ResetDemo();
            UI::Text("This control window only renders while Openplanet is open.");
        }
        UI::End();
    }
}
