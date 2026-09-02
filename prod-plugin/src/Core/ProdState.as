namespace ProdState {
    bool IsInitialized = false;

    void Initialize() {
        TeamThemes::Initialize();
        MatchState::Initialize();
        OverlayTheme::Initialize();
        RecordsState::Initialize();
        LiveRankingState::Initialize();
        LayoutMigration::ApplyIfNeeded();

        MatchBanner::Initialize();
        LiveRanking::Initialize();
        RecordsPanel::Initialize();
        BrandingLogo::Initialize();

        IsInitialized = true;
        trace("MLE TM PROD state initialized.");
    }
}
