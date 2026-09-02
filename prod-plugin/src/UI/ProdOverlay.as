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
            SyncSimulationState();
        }
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
