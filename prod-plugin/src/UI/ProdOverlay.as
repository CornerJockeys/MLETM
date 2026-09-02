namespace ProdOverlay {
    void SyncSimulationState() {
        MatchState::SyncFromSettings();
        RecordsState::SyncFromSettings();
        LiveRankingState::SyncTeams();
        LiveDataSource::SetSimulationStatus();
    }

    void Render() {
        if (!ProdState::IsInitialized) return;

        // Test controls are intentionally independent of the master broadcast toggle
        // so a producer can recover the overlay after hiding it during a test.
        ProdTestControls::Render();

        if (S_UseLiveRaceData && LiveDataSource::CanUseLive()) {
            LiveDataSource::Update();
        } else {
            // Simulation remains fully usable in the main menu, local play, developer
            // mode, or when the optional MLFeed dependencies are not installed.
            SyncSimulationState();
        }

        if (!S_ShowProdOverlay) return;

        MatchBanner::Render();
        LiveRanking::Render();
        RecordsPanel::Render();
    }
}
