namespace LayoutState {
    const float MinBannerW = 520.0f;
    const float MinBannerH = 70.0f;
    const float MinRankingW = 230.0f;
    const float MinRankingH = 190.0f;
    const float MinRecordsW = 180.0f;
    const float MinRecordsH = 110.0f;

    float ClampMin(float value, float minimum) {
        return value < minimum ? minimum : value;
    }

    int BroadcastWindowFlags() {
        int flags = UI::WindowFlags::NoTitleBar
            | UI::WindowFlags::NoCollapse
            | UI::WindowFlags::NoDocking
            | UI::WindowFlags::NoFocusOnAppearing;

        if (!S_LayoutSetupMode) {
            flags |= UI::WindowFlags::NoMove;
            flags |= UI::WindowFlags::NoResize;
        }
        return flags;
    }

    void PrepareBanner() {
        UI::SetNextWindowPos(int(S_BannerX), int(S_BannerY), UI::Cond::Always);
        UI::SetNextWindowSize(int(S_BannerW), int(S_BannerH), UI::Cond::Always);
    }

    void CaptureBanner() {
        if (!S_LayoutSetupMode) return;
        vec2 p = UI::GetWindowPos();
        vec2 s = UI::GetWindowSize();
        S_BannerX = p.x;
        S_BannerY = p.y;
        S_BannerW = ClampMin(s.x, MinBannerW);
        S_BannerH = ClampMin(s.y, MinBannerH);
    }

    void PrepareRanking() {
        UI::SetNextWindowPos(int(S_RankingX), int(S_RankingY), UI::Cond::Always);
        UI::SetNextWindowSize(int(S_RankingW), int(S_RankingH), UI::Cond::Always);
    }

    void CaptureRanking() {
        if (!S_LayoutSetupMode) return;
        vec2 p = UI::GetWindowPos();
        vec2 s = UI::GetWindowSize();
        S_RankingX = p.x;
        S_RankingY = p.y;
        S_RankingW = ClampMin(s.x, MinRankingW);
        S_RankingH = ClampMin(s.y, MinRankingH);
    }

    void PrepareRecords() {
        UI::SetNextWindowPos(int(S_RecordsX), int(S_RecordsY), UI::Cond::Always);
        UI::SetNextWindowSize(int(S_RecordsW), int(S_RecordsH), UI::Cond::Always);
    }

    void CaptureRecords() {
        if (!S_LayoutSetupMode) return;
        vec2 p = UI::GetWindowPos();
        vec2 s = UI::GetWindowSize();
        S_RecordsX = p.x;
        S_RecordsY = p.y;
        S_RecordsW = ClampMin(s.x, MinRecordsW);
        S_RecordsH = ClampMin(s.y, MinRecordsH);
    }

    void ResetDefaults() {
        // 1920x1080 broadcast-safe defaults based on the approved mockup.
        S_BannerX = 580.0f;
        S_BannerY = 0.0f;
        S_BannerW = 760.0f;
        S_BannerH = 86.0f;

        S_RankingX = 14.0f;
        S_RankingY = 48.0f;
        S_RankingW = 300.0f;
        S_RankingH = 250.0f;

        S_RecordsX = 1640.0f;
        S_RecordsY = 48.0f;
        S_RecordsW = 260.0f;
        S_RecordsH = 150.0f;
    }

    string ModeLabel() {
        return S_LayoutSetupMode ? "SETUP" : "LIVE / LOCKED";
    }
}
