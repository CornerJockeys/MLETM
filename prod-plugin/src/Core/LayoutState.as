namespace LayoutState {
    const float ReferenceWidth = 1920.0f;
    const float ReferenceHeight = 1080.0f;
    const float BannerAspect = 8.60f;

    const float MinBannerW = 520.0f;
    const float MinBannerH = 60.0f;
    const float MinRankingW = 230.0f;
    const float MinRankingH = 190.0f;
    const float MinRecordsW = 180.0f;
    const float MinRecordsH = 110.0f;
    const float MinLogoW = 72.0f;
    const float MinLogoH = 72.0f;

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
        float oldW = S_BannerW;
        float oldH = S_BannerH;
        float nextW = ClampMin(s.x, MinBannerW);
        float nextH = ClampMin(s.y, MinBannerH);

        if (S_LockBannerAspect) {
            float dw = Math::Abs(nextW - oldW) / Math::Max(oldW, 1.0f);
            float dh = Math::Abs(nextH - oldH) / Math::Max(oldH, 1.0f);
            if (dw >= dh) {
                nextH = nextW / BannerAspect;
            } else {
                nextW = nextH * BannerAspect;
            }
        }

        S_BannerX = p.x;
        S_BannerY = p.y;
        S_BannerW = ClampMin(nextW, MinBannerW);
        S_BannerH = ClampMin(nextH, MinBannerH);
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

    void PrepareLogo() {
        UI::SetNextWindowPos(int(S_LogoX), int(S_LogoY), UI::Cond::Always);
        UI::SetNextWindowSize(int(S_LogoW), int(S_LogoH), UI::Cond::Always);
    }

    void CaptureLogo() {
        if (!S_LayoutSetupMode) return;
        vec2 p = UI::GetWindowPos();
        vec2 s = UI::GetWindowSize();
        float size = Math::Max(ClampMin(s.x, MinLogoW), ClampMin(s.y, MinLogoH));
        S_LogoX = p.x;
        S_LogoY = p.y;
        S_LogoW = size;
        S_LogoH = size;
    }

    float ClampLayoutScale(float scale) {
        return Math::Clamp(scale, 0.45f, 1.50f);
    }

    void ApplyReferenceScale(float requestedScale) {
        float scale = ClampLayoutScale(requestedScale);

        S_BannerW = 860.0f * scale;
        S_BannerH = 100.0f * scale;
        S_BannerX = (ReferenceWidth * scale - S_BannerW) * 0.5f;
        S_BannerY = 0.0f;

        S_RankingX = 14.0f * scale;
        S_RankingY = 60.0f * scale;
        S_RankingW = 320.0f * scale;
        S_RankingH = 260.0f * scale;

        S_RecordsW = 280.0f * scale;
        S_RecordsH = 150.0f * scale;
        S_RecordsX = ReferenceWidth * scale - S_RecordsW - 14.0f * scale;
        S_RecordsY = 60.0f * scale;

        S_LogoW = 140.0f * scale;
        S_LogoH = 140.0f * scale;
        S_LogoX = ReferenceWidth * scale - S_LogoW - 40.0f * scale;
        S_LogoY = ReferenceHeight * scale - S_LogoH - 40.0f * scale;
    }

    void FitCurrentResolution() {
        float widthScale = float(Display::GetWidth()) / ReferenceWidth;
        float heightScale = float(Display::GetHeight()) / ReferenceHeight;
        ApplyReferenceScale(Math::Min(widthScale, heightScale));
    }

    void ResetDefaults() {
        ApplyReferenceScale(1.0f);
    }

    string CurrentResolutionLabel() {
        return tostring(Display::GetWidth()) + "x" + tostring(Display::GetHeight());
    }

    string ModeLabel() {
        return S_LayoutSetupMode ? "SETUP" : "LIVE / LOCKED";
    }
}
