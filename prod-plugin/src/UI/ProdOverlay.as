namespace ProdOverlay {
    void SyncSimulationState() {
        MatchState::SyncFromSettings();
        if (!S_UseLiveRecords) RecordsState::SyncFromSettings();
        LiveRankingState::SyncTeams();
        LiveDataSource::SetSimulationStatus();
    }

    void UpdateState() {
        if (!ProdState::IsInitialized) return;

        if (S_UseLiveRaceData && LiveDataSource::CanUseLive()) {
            LiveDataSource::Update();
        } else {
            SyncSimulationState();
        }

        // Record data is independent of MLFeed and can work on local maps.
        RecordsDataSource::Update();
    }

    void RenderControls() {
        if (!ProdState::IsInitialized) return;
        ProdTestControls::Render();
    }

    void RenderBroadcast() {
        if (!ProdState::IsInitialized || !S_ShowProdOverlay) return;

        MatchBanner::Render();
        LiveRanking::Render();
        RecordsPanel::Render();
        BrandingLogo::Render();
    }
}
