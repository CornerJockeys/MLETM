namespace ProdTestControls {
    array<string> DemoMaps = {"BATTERY", "MELODRAMA", "NIRVANA", "SKRRRT", "WHATEVER"};

    int FindMapIndex(const string &in mapName) {
        string key = mapName.ToUpper();
        for (uint i = 0; i < DemoMaps.Length; i++) {
            if (DemoMaps[i] == key) return int(i);
        }
        return -1;
    }

    void ResetDemo() {
        S_ShowProdOverlay = true;
        S_ShowMatchBanner = true;
        S_ShowLiveRanking = true;
        S_ShowRecordsPanel = true;
        S_UseLiveRaceData = false;
        S_LiveTeamAIsBlue = false;

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
        int index = FindMapIndex(S_TestMapName);
        uint next = index < 0 ? 0 : (uint(index + 1) % DemoMaps.Length);
        S_TestMapName = DemoMaps[next];
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

        UI::SetNextWindowSize(410, 560, UI::Cond::FirstUseEver);
        int flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::NoDocking;

        bool visible = UI::Begin("MLE TM PROD - Test Controls", flags);
        if (visible) {
            UI::Text("Broadcast widgets");
            S_ShowProdOverlay = UI::Checkbox("Master overlay", S_ShowProdOverlay);
            S_ShowMatchBanner = UI::Checkbox("Match banner", S_ShowMatchBanner);
            S_ShowLiveRanking = UI::Checkbox("Live ranking", S_ShowLiveRanking);
            S_ShowRecordsPanel = UI::Checkbox("WR panel", S_ShowRecordsPanel);

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

            if (UI::Button("Swap teams")) SwapTeams();
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
            if (UI::Button("B - Round")) AddRoundB(-1);

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
            if (UI::Button("RESET ALL DEMO STATE")) ResetDemo();
            UI::Text("This control window only renders while Openplanet is open.");
        }
        UI::End();
    }
}
