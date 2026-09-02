namespace BrandingLogo {
    UI::Texture@ LogoTexture;
    UI::Font@ FallbackFont;
    string Source = "Not loaded";

    void EnsureExternalFolder() {
        string folder = IO::FromStorageFolder("Overlay/branding");
        if (!IO::FolderExists(folder)) IO::CreateFolder(folder, true);
    }

    void Reload() {
        EnsureExternalFolder();
        @LogoTexture = null;
        Source = "Fallback text";

        string overridePath = IO::FromStorageFolder("Overlay/branding/MLETM.png");
        if (S_EnableLocalThemeOverrides && IO::FileExists(overridePath)) {
            try {
                @LogoTexture = UI::LoadTexture(overridePath);
                Source = "External Overlay/branding/MLETM.png";
                return;
            } catch {
                warn("MLE TM PROD branding override failed: " + getExceptionInfo());
            }
        }

        try {
            @LogoTexture = UI::LoadTexture("assets/branding/MLETM.png");
            Source = "Bundled assets/branding/MLETM.png";
        } catch {
            // Branding remains usable before the binary asset is added to the repo.
            @LogoTexture = null;
        }
    }

    void Initialize() {
        @FallbackFont = UI::LoadFont("DroidSans.ttf", 24);
        Reload();
    }

    void Render() {
        if (!S_ShowMleLogo) return;

        LayoutState::PrepareLogo();
        UI::PushStyleColor(UI::Col::WindowBg, vec4(0, 0, 0, 0));
        UI::PushStyleColor(UI::Col::Border, vec4(0, 0, 0, 0));
        UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(0, 0));
        UI::PushStyleVar(UI::StyleVar::WindowRounding, 0.0f);

        bool visible = UI::Begin("##MLETMProdBrandingLogo", LayoutState::BroadcastWindowFlags());
        if (visible) {
            LayoutState::CaptureLogo();
            vec2 size = UI::GetWindowSize();

            if (LogoTexture !is null) {
                UI::Image(LogoTexture, size);
            } else {
                auto drawList = UI::GetWindowDrawList();
                vec2 pos = UI::GetWindowPos();
                drawList.AddRectFilled(vec4(pos, size), vec4(0.035f, 0.045f, 0.055f, S_NonBannerOpacity), 5.0f);
                UI::SetCursorPos(vec2(12, size.y * 0.40f));
                UI::PushStyleColor(UI::Col::Text, TeamThemes::MleGradientStart());
                if (FallbackFont !is null) UI::PushFont(FallbackFont);
                UI::Text("MLE TM");
                if (FallbackFont !is null) UI::PopFont();
                UI::PopStyleColor();
            }
        }
        UI::End();

        UI::PopStyleVar();
        UI::PopStyleVar();
        UI::PopStyleColor(2);
    }
}
