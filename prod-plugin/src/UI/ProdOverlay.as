namespace ProdOverlay {
    void Render() {
        if (!S_ShowProdOverlay) return;
        if (!ProdState::IsInitialized) return;

        MatchBanner::Render();
    }
}
