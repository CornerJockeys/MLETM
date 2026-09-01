namespace MatchBanner {
    UI::Font@ TeamFont;
    UI::Font@ ScoreFont;
    UI::Font@ MetaFont;

    const vec4 White = vec4(0.96f, 0.97f, 0.98f, 1.0f);
    const vec4 Charcoal = vec4(0.035f, 0.045f, 0.055f, 0.97f);
    const vec4 EmptyRound = vec4(0.15f, 0.16f, 0.18f, 0.96f);

    void Initialize() {
        @TeamFont = UI::LoadFont("DroidSans.ttf", 22);
        @ScoreFont = UI::LoadFont("DroidSans.ttf", 30);
        @MetaFont = UI::LoadFont("DroidSans.ttf", 14);
    }

    void TextAt(const vec2 &in localPos, const string &in text, UI::Font@ font, const vec4 &in color) {
        UI::SetCursorPos(localPos);
        UI::PushStyleColor(UI::Col::Text, color);
        if (font !is null) UI::PushFont(font);
        UI::Text(text);
        if (font !is null) UI::PopFont();
        UI::PopStyleColor();
    }

    void ImageAt(const vec2 &in localPos, UI::Texture@ texture, float size) {
        if (texture is null || size <= 0.0f) return;
        UI::SetCursorPos(localPos);
        UI::Image(texture, vec2(size, size));
    }

    void Render() {
        if (!S_ShowMatchBanner) return;

        LayoutState::PrepareBanner();

        UI::PushStyleColor(UI::Col::WindowBg, vec4(0, 0, 0, 0));
        UI::PushStyleColor(UI::Col::Border, vec4(0, 0, 0, 0));
        UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(0, 0));
        UI::PushStyleVar(UI::StyleVar::WindowRounding, 0.0f);

        bool visible = UI::Begin("##MLETMProdMatchBanner", LayoutState::BroadcastWindowFlags());
        if (visible) {
            LayoutState::CaptureBanner();

            auto drawList = UI::GetWindowDrawList();
            vec2 windowPos = UI::GetWindowPos();
            vec2 windowSize = UI::GetWindowSize();

            float mainHeight = windowSize.y * 0.72f;
            float scoreWidth = windowSize.x * 0.16f;
            float sideWidth = (windowSize.x - scoreWidth) * 0.5f;

            drawList.AddRectFilled(vec4(windowPos, vec2(sideWidth, mainHeight)), MatchState::TeamAPrimary, 0);
            drawList.AddRectFilled(vec4(windowPos + vec2(sideWidth, 0), vec2(scoreWidth, mainHeight)), Charcoal, 0);
            drawList.AddRectFilled(vec4(windowPos + vec2(sideWidth + scoreWidth, 0), vec2(sideWidth, mainHeight)), MatchState::TeamBPrimary, 0);

            drawList.AddRectFilled(vec4(windowPos, vec2(5, mainHeight)), MatchState::TeamASecondary, 0);
            drawList.AddRectFilled(vec4(windowPos + vec2(windowSize.x - 5, 0), vec2(5, mainHeight)), MatchState::TeamBSecondary, 0);

            float infoWidth = windowSize.x * 0.58f;
            float infoX = (windowSize.x - infoWidth) * 0.5f;
            drawList.AddRectFilled(
                vec4(windowPos + vec2(infoX, mainHeight), vec2(infoWidth, windowSize.y - mainHeight)),
                Charcoal,
                0
            );
            drawList.AddRectFilled(
                vec4(windowPos + vec2(infoX, mainHeight), vec2(infoWidth, 2)),
                MatchState::DivisionColor,
                0
            );

            float logoSize = Math::Max(0.0f, mainHeight - 10.0f);
            auto teamALogo = OverlayTheme::GetTeamLogo(MatchState::TeamAName);
            auto teamBLogo = OverlayTheme::GetTeamLogo(MatchState::TeamBName);
            ImageAt(vec2(8.0f, 5.0f), teamALogo, logoSize);
            ImageAt(vec2(windowSize.x - logoSize - 8.0f, 5.0f), teamBLogo, logoSize);

            float teamATextX = teamALogo is null ? 18.0f : logoSize + 16.0f;
            TextAt(vec2(teamATextX, 8), MatchState::TeamAName, TeamFont, White);
            TextAt(vec2(sideWidth + scoreWidth + 18, 8), MatchState::TeamBName, TeamFont, White);

            string scoreText = Text::Format("%d - %d", MatchState::TeamAMapScore, MatchState::TeamBMapScore);
            TextAt(vec2(sideWidth + scoreWidth * 0.22f, 4), scoreText, ScoreFont, White);

            float slotWidth = sideWidth * 0.055f;
            float slotHeight = 7.0f;
            float gap = 5.0f;
            float totalSlotsWidth = slotWidth * 5.0f + gap * 4.0f;
            float slotY = mainHeight - 15.0f;
            float teamAStartX = sideWidth - totalSlotsWidth - 16.0f;
            float teamBStartX = sideWidth + scoreWidth + 16.0f;

            for (int i = 0; i < 5; i++) {
                vec4 teamAColor = i < MatchState::TeamARoundWins ? White : EmptyRound;
                float teamAX = teamAStartX + float(i) * (slotWidth + gap);
                drawList.AddRectFilled(
                    vec4(windowPos + vec2(teamAX, slotY), vec2(slotWidth, slotHeight)),
                    teamAColor,
                    slotHeight * 0.5f
                );

                vec4 teamBColor = i < MatchState::TeamBRoundWins ? White : EmptyRound;
                float teamBX = teamBStartX + float(i) * (slotWidth + gap);
                drawList.AddRectFilled(
                    vec4(windowPos + vec2(teamBX, slotY), vec2(slotWidth, slotHeight)),
                    teamBColor,
                    slotHeight * 0.5f
                );
            }

            float metaY = mainHeight + 4.0f;
            TextAt(vec2(infoX + 14.0f, metaY), MatchState::Division, MetaFont, MatchState::DivisionColor);
            TextAt(vec2(infoX + infoWidth * 0.49f, metaY), MatchState::MatchLabel, MetaFont, White);
            TextAt(vec2(infoX + infoWidth * 0.70f, metaY), MatchState::MapName, MetaFont, White);
        }
        UI::End();

        UI::PopStyleVar();
        UI::PopStyleVar();
        UI::PopStyleColor(2);
    }
}
