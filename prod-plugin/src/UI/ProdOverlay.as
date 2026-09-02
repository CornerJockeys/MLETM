namespace ProdOverlay {
    void SyncSimulationState() {
        MatchState::SyncFromSettings();
        RecordsState::SyncFromSettings();
        LiveRankingState::SyncTeams();
        LiveDataSource::SetSimulationStatus();
    }

    void UpdateState() {
        if (!ProdState::IsInitialized) return;

        if (S_UseLiveRaceData && LiveDataSource::CanUseLive()) {
            LiveDataSource::Update();
        } else {
            // Simulation remains fully usable in the main menu, local play, developer
            // mode, or when optional live dependencies are not installed.
            SyncSimulationState();
        }
    }

    void RenderControls() {
        if (!ProdState::IsInitialized) return;
        // Dev/operator controls intentionally live in Render(), where they are tied to
        // the Openplanet overlay instead of the clean broadcast interface layer.
        ProdTestControls::Render();
    }

    void RenderBroadcast() {
        if (!ProdState::IsInitialized || !S_ShowProdOverlay) return;

        MatchBanner::Render();
        LiveRanking::Render();
        RecordsPanel::Render();
    }
}
