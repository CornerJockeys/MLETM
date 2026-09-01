namespace ProdState {
    bool IsInitialized = false;

    void Initialize() {
        MatchState::Initialize();
        MatchBanner::Initialize();

        IsInitialized = true;
        trace("MLE TM PROD state initialized.");
    }
}
