namespace ProdOverlay {
    void Render() {
        if (!ProdState::IsInitialized) return;

        // Test controls are intentionally independent of the master broadcast toggle
        // so a producer can recover the overlay after hiding it during a test.
        ProdTestControls::Render();

        if (!S_ShowProdOverlay) return;

        MatchBanner::Render();
        LiveRanking::Render();
        RecordsPanel::Render();
    }
}
