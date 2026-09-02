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

    void DrawTeamNameAccent(
        UI::DrawList@ drawList,
        const vec2 &in windowPos,
        float x,
        float y,
        float width,
        const vec4 &in accent,
        bool strong
    ) {
        int lineCount = strong ? 7 : 4;
        float spacing = strong ? 13.0f : 18.0f;
        float lineH = strong ? 18.0f : 13.0f;
        vec4 color = TeamThemes::WithAlpha(accent, strong ? 0.78f : 0.52f);
        for (int i = 0; i < lineCount; i++) {
            float lx = x + float(i) * spacing;
            if (lx > x + width) break;
            drawList.AddLine(
                windowPos + vec2(lx + lineH * 0.70f, y),
                windowPos + vec2(lx, y + lineH),
                color,
                strong ? 3.0f : 2.0f
            );
        }
    }

    void DrawLogoBed(
        UI::DrawList@ drawList,
        const vec2 &in windowPos,
        float x,
        float y,
        float size,
        const vec4 &in accent
    ) {
        float pad = 3.0f;
        drawList.AddRectFilled(
            vec4(windowPos + vec2(x - pad, y - pad), vec2(size + pad * 2.0f, size + pad * 2.0f)),
            vec4(0.025f, 0.030f, 0.038f, 0.96f),
            4.0f
        );
        drawList.AddRectFilled(
            vec4(windowPos + vec2(x - pad, y + size), vec2(size + pad * 2.0f, 3.0f)),
            accent,
            0
        );
    }

    void DrawTeamBackgrounds(
        UI::DrawList@ drawList,
        const vec2 &in windowPos,
        float windowWidth,
        float mainHeight,
        float sideWidth,
        float scoreWidth
    ) {
        float angle = S_BannerPreset == 1 ? 24.0f : 14.0f;

        if (S_BannerPreset == 2) {
            drawList.AddRectFilled(vec4(windowPos, vec2(sideWidth, mainHeight)), MatchState::TeamAPrimary, 0);
            drawList.AddRectFilled(vec4(windowPos + vec2(sideWidth + scoreWidth, 0), vec2(sideWidth, mainHeight)), MatchState::TeamBPrimary, 0);
        } else {
            drawList.AddQuadFilled(
                windowPos + vec2(0, 0),
                windowPos + vec2(sideWidth + angle, 0),
                windowPos + vec2(sideWidth - angle, mainHeight),
                windowPos + vec2(0, mainHeight),
                MatchState::TeamAPrimary
            );
            drawList.AddQuadFilled(
                windowPos + vec2(sideWidth + scoreWidth - angle, 0),
                windowPos + vec2(windowWidth, 0),
                windowPos + vec2(windowWidth, mainHeight),
                windowPos + vec2(sideWidth + scoreWidth + angle, mainHeight),
                MatchState::TeamBPrimary
            );
        }

        drawList.AddRectFilled(
            vec4(windowPos + vec2(sideWidth - 4.0f, 0), vec2(scoreWidth + 8.0f, mainHeight)),
            Charcoal,
            0
        );

        if (S_BannerPreset != 2) {
            drawList.AddQuadFilled(
                windowPos + vec2(sideWidth - 14.0f, 0),
                windowPos + vec2(sideWidth - 7.0f, 0),
                windowPos + vec2(sideWidth - 21.0f, mainHeight),
                windowPos + vec2(sideWidth - 28.0f, mainHeight),
                MatchState::TeamASecondary
            );
            drawList.AddQuadFilled(
                windowPos + vec2(sideWidth + scoreWidth + 7.0f, 0),
                windowPos + vec2(sideWidth + scoreWidth + 14.0f, 0),
                windowPos + vec2(sideWidth + scoreWidth + 28.0f, mainHeight),
                windowPos + vec2(sideWidth + scoreWidth + 21.0f, mainHeight),
                MatchState::TeamBSecondary
            );
        }
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

            DrawTeamBackgrounds(drawList, windowPos, windowSize.x, mainHeight, sideWidth, scoreWidth);

            float infoWidth = windowSize.x * 0.60f;
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

            float logoSize = Math::Max(0.0f, mainHeight - 18.0f);
            float logoY = 8.0f;
            float teamALogoX = 10.0f;
            float teamBLogoX = windowSize.x - logoSize - 10.0f;
            DrawLogoBed(drawList, windowPos, teamALogoX, logoY, logoSize, MatchState::TeamASecondary);
            DrawLogoBed(drawList, windowPos, teamBLogoX, logoY, logoSize, MatchState::TeamBSecondary);

            auto teamALogo = OverlayTheme::GetTeamLogo(MatchState::TeamAName);
            auto teamBLogo = OverlayTheme::GetTeamLogo(MatchState::TeamBName);
            ImageAt(vec2(teamALogoX, logoY), teamALogo, logoSize);
            ImageAt(vec2(teamBLogoX, logoY), teamBLogo, logoSize);

            float teamATextX = teamALogoX + logoSize + 18.0f;
            float teamBTextX = sideWidth + scoreWidth + 26.0f;
            bool community = S_BannerPreset == 1;
            if (S_BannerPreset != 2) {
                DrawTeamNameAccent(drawList, windowPos, teamATextX + 3.0f, 27.0f, sideWidth - teamATextX - 8.0f, MatchState::TeamASecondary, community);
                DrawTeamNameAccent(drawList, windowPos, teamBTextX + 3.0f, 27.0f, teamBLogoX - teamBTextX - 8.0f, MatchState::TeamBSecondary, community);
            }

            vec4 teamAText = TeamThemes::TextOnPrimary(MatchState::TeamAName);
            vec4 teamBText = TeamThemes::TextOnPrimary(MatchState::TeamBName);
            TextAt(vec2(teamATextX + 2.0f, 10.0f), MatchState::TeamAName, TeamFont, TeamThemes::WithAlpha(MatchState::TeamASecondary, 0.92f));
            TextAt(vec2(teamATextX, 8.0f), MatchState::TeamAName, TeamFont, teamAText);
            TextAt(vec2(teamBTextX + 2.0f, 10.0f), MatchState::TeamBName, TeamFont, TeamThemes::WithAlpha(MatchState::TeamBSecondary, 0.92f));
            TextAt(vec2(teamBTextX, 8.0f), MatchState::TeamBName, TeamFont, teamBText);

            string scoreText = tostring(MatchState::TeamAMapScore) + " - " + tostring(MatchState::TeamBMapScore);
            TextAt(vec2(sideWidth + scoreWidth * 0.22f, 6), scoreText, ScoreFont, White);

            float slotWidth = sideWidth * 0.050f;
            float slotHeight = 7.0f;
            float gap = 5.0f;
            float totalSlotsWidth = slotWidth * 5.0f + gap * 4.0f;
            float slotY = mainHeight - 14.0f;
            float teamAStartX = sideWidth - totalSlotsWidth - 24.0f;
            float teamBStartX = sideWidth + scoreWidth + 24.0f;

            for (int i = 0; i < 5; i++) {
                vec4 teamAColor = i < MatchState::TeamARoundWins ? White : EmptyRound;
                float teamAX = teamAStartX + float(i) * (slotWidth + gap);
                drawList.AddRectFilled(vec4(windowPos + vec2(teamAX, slotY), vec2(slotWidth, slotHeight)), teamAColor, slotHeight * 0.5f);

                vec4 teamBColor = i < MatchState::TeamBRoundWins ? White : EmptyRound;
                float teamBX = teamBStartX + float(i) * (slotWidth + gap);
                drawList.AddRectFilled(vec4(windowPos + vec2(teamBX, slotY), vec2(slotWidth, slotHeight)), teamBColor, slotHeight * 0.5f);
            }

            float metaY = mainHeight + 5.0f;
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
