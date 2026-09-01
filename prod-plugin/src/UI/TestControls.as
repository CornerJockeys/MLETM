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
        LayoutState::ResetDefaults();
        OverlayTheme::Reload();
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
    }

    void AddRoundA(int delta) {
        S_TestTeamARoundWins = MatchState::ClampRoundWins(S_TestTeamARoundWins + delta);
    }

    void AddRoundB(int delta) {
        S_TestTeamBRoundWins = MatchState::ClampRoundWins(S_TestTeamBRoundWins + delta);
    }

    void Render() {
        if (!S_ShowTestControls) return;
        if (!UI::IsOverlayShown()) return;

        UI::SetNextWindowSize(430, 720, UI::Cond::FirstUseEver);
        int flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::NoDocking;

        bool visible = UI::Begin("MLE TM PROD - Test Controls", flags);
        if (visible) {
            UI::Text("Broadcast widgets");
            S_ShowProdOverlay = UI::Checkbox("Master overlay", S_ShowProdOverlay);
            S_ShowMatchBanner = UI::Checkbox("Match banner", S_ShowMatchBanner);
            S_ShowLiveRanking = UI::Checkbox("Live ranking", S_ShowLiveRanking);
            S_ShowRecordsPanel = UI::Checkbox("WR panel", S_ShowRecordsPanel);

            UI::Separator();
            UI::Text("Operator / layout");
            bool oldSetupMode = S_LayoutSetupMode;
            S_LayoutSetupMode = UI::Checkbox("Setup mode - unlock drag/resize", S_LayoutSetupMode);
            if (oldSetupMode != S_LayoutSetupMode) {
                ProdHotkeys::NotifyState(S_LayoutSetupMode ? "Overlay SETUP mode - widgets unlocked" : "Overlay LIVE mode - widgets locked");
            }
            UI::Text("Mode: " + LayoutState::ModeLabel());
            if (UI::Button("Reset widget layout")) LayoutState::ResetDefaults();

            bool chatHidden = ChatVisibility::Hidden;
            bool nextChatHidden = UI::Checkbox("Hide game chat locally", chatHidden);
            if (nextChatHidden != chatHidden) ChatVisibility::SetHidden(nextChatHidden);
            UI::Text("Chat: " + ChatVisibility::Status);

            UI::Separator();
            UI::Text("External presentation overrides");
            S_EnableLocalThemeOverrides = UI::Checkbox("Enable local theme/logo overrides", S_EnableLocalThemeOverrides);
            if (UI::Button("Open Overlay folder")) OverlayTheme::OpenFolder();
            UI::SameLine();
            if (UI::Button("Reload theme/assets")) OverlayTheme::Reload();
            UI::Text("Theme: " + OverlayTheme::Status);
            UI::Text("Missing or invalid overrides always fall back to bundled MLE defaults.");

            UI::Separator();
            UI::Text("Data source");
            bool wasLive = S_UseLiveRaceData;
            S_UseLiveRaceData = UI::Checkbox("Use live MLFeed race data", S_UseLiveRaceData);
            if (wasLive && !S_UseLiveRaceData) {
                LiveRankingState::Reset();
            }
            S_LiveTeamAIsBlue = UI::Checkbox("Team A = Trackmania Blue", S_LiveTeamAIsBlue);
            UI::Text("Status: " + LiveDataSource::Status);
            UI::Text("Live mode overrides map name, round score, ranking and respawns.");

            UI::Separator();
            UI::Text("Match state / simulation");

            if (UI::Button("Cycle division")) CycleDivision();
            UI::SameLine();
            UI::Text(S_TestDivision);

            if (UI::Button("Next map")) NextMap();
            UI::SameLine();
            UI::Text(S_TestMapName);

            if (UI::Button("Next Team A")) NextTeamA();
            UI::SameLine();
            if (UI::Button("Next Team B")) NextTeamB();
            UI::SameLine();
            if (UI::Button("Swap")) SwapTeams();
            UI::Text(S_TestTeamAName + " vs " + S_TestTeamBName);

            UI::Text("Map score");
            if (UI::Button("A + Map")) S_TestTeamAMapScore++;
            UI::SameLine();
            if (UI::Button("A - Map") && S_TestTeamAMapScore > 0) S_TestTeamAMapScore--;
            UI::SameLine();
            UI::Text(Text::Format("%d - %d", S_TestTeamAMapScore, S_TestTeamBMapScore));
            UI::SameLine();
            if (UI::Button("B + Map")) S_TestTeamBMapScore++;
            UI::SameLine();
            if (UI::Button("B - Map") && S_TestTeamBMapScore > 0) S_TestTeamBMapScore--;

            UI::Text("Round score");
            if (UI::Button("A + Round")) AddRoundA(1);
            UI::SameLine();
            if (UI::Button("A - Round")) AddRoundA(-1);
            UI::SameLine();
            UI::Text(Text::Format("%d - %d", S_TestTeamARoundWins, S_TestTeamBRoundWins));
            UI::SameLine();
            if (UI::Button("B + Round")) AddRoundB(1);
            UI::SameLine();
            if (UI::Button("B - Round") && S_TestTeamBRoundWins > 0) AddRoundB(-1);

            if (UI::Button("Clear rounds")) {
                S_TestTeamARoundWins = 0;
                S_TestTeamBRoundWins = 0;
            }

            UI::Separator();
            UI::Text("Ranking simulation");
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
            UI::Text("Hotkeys: F7 overlay | F8 chat | F9 setup | F10 banner | F11 ranking | F12 WR");
            UI::Text("All are configurable in Openplanet settings and never block game input.");

            if (UI::Button("RESET ALL DEMO STATE")) ResetDemo();
            UI::Text("This control window only renders while Openplanet is open.");
        }
        UI::End();
    }
}
