namespace ProdState {
    bool IsInitialized = false;

    void Initialize() {
        TeamThemes::Initialize();
        MatchState::Initialize();
        RecordsState::Initialize();
        LiveRankingState::Initialize();

        MatchBanner::Initialize();
        LiveRanking::Initialize();
        RecordsPanel::Initialize();

        IsInitialized = true;
        trace("MLE TM PROD state initialized.");
    }
}
