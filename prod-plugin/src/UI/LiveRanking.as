namespace LiveRanking {
    UI::Font@ HeaderFont;
    UI::Font@ RowFont;
    UI::Font@ RowFontLarge;
    UI::Font@ SmallFont;

    const vec4 White = vec4(0.96f, 0.97f, 0.98f, 1.0f);
    const vec4 Respawn = vec4(1.0f, 0.78f, 0.20f, 1.0f);
    const vec4 Spectated = vec4(0.10f, 0.95f, 0.86f, 1.0f);

    void Initialize() {
        @HeaderFont = UI::LoadFont("DroidSans.ttf", 18);
        @RowFont = UI::LoadFont("DroidSans.ttf", 14);
        @RowFontLarge = UI::LoadFont("DroidSans.ttf", 16);
        @SmallFont = UI::LoadFont("DroidSans.ttf", 11);
    }

    void TextAt(const vec2 &in localPos, const string &in text, UI::Font@ font, const vec4 &in color) {
        UI::SetCursorPos(localPos);
        UI::PushStyleColor(UI::Col::Text, color);
        if (font !is null) UI::PushFont(font);
        UI::Text(text);
        if (font !is null) UI::PopFont();
        UI::PopStyleColor();
    }

    void DrawSpectatedBorder(UI::DrawList@ drawList, const vec2 &in windowPos, float y, float width, float height) {
        float t = 3.0f;
        drawList.AddRectFilled(vec4(windowPos + vec2(0, y), vec2(width, t)), Spectated, 0);
        drawList.AddRectFilled(vec4(windowPos + vec2(0, y + height - t), vec2(width, t)), Spectated, 0);
        drawList.AddRectFilled(vec4(windowPos + vec2(0, y), vec2(t, height)), Spectated, 0);
        drawList.AddRectFilled(vec4(windowPos + vec2(width - t, y), vec2(t, height)), Spectated, 0);
    }

    void DrawRacingStripe(
        UI::DrawList@ drawList,
        const vec2 &in windowPos,
        float x,
        float y,
        float width,
        float height,
        const vec4 &in color
    ) {
        // Parallelogram leaned 35 degrees from vertical. This prevents adjacent team
        // accents from visually merging into one straight block.
        float slant = height * 0.70f;
        drawList.AddQuadFilled(
            windowPos + vec2(x + slant, y),
            windowPos + vec2(x + width + slant, y),
            windowPos + vec2(x + width, y + height),
            windowPos + vec2(x, y + height),
            color
        );
    }

    void DrawRow(
        UI::DrawList@ drawList,
        const vec2 &in windowPos,
        const vec2 &in windowSize,
        float headerHeight,
        float rowHeight,
        uint targetIndex,
        ProdRankEntry@ entry
    ) {
        if (entry is null) return;

        float visualRank = LiveRankingState::CurrentVisualRank(entry);
        float scale = LiveRankingState::CurrentScale(entry);
        float baseHeight = rowHeight - 2.0f;
        float drawHeight = baseHeight * scale;
        float centerY = headerHeight + rowHeight * (visualRank + 0.5f);
        float y = centerY - drawHeight * 0.5f;

        vec4 primary = TeamThemes::Primary(entry.team);
        vec4 textColor = TeamThemes::TextOnPrimary(entry.team);
        vec4 stripeA = TeamThemes::RacingStripeA(entry.team);
        vec4 stripeB = TeamThemes::RacingStripeB(entry.team);
        vec4 rowColor = TeamThemes::WithAlpha(primary, S_NonBannerOpacity);

        drawList.AddRectFilled(
            vec4(windowPos + vec2(0, y), vec2(windowSize.x, drawHeight)),
            rowColor,
            0
        );

        // Dark neutral timing bed protects the gap/time readout even on very bright
        // franchise colors while leaving the majority of the row team-colored.
        float timingBedW = 82.0f;
        drawList.AddRectFilled(
            vec4(windowPos + vec2(windowSize.x - timingBedW, y), vec2(timingBedW, drawHeight)),
            vec4(0.035f, 0.045f, 0.055f, Math::Min(0.96f, S_NonBannerOpacity + 0.08f)),
            0
        );

        float stripeW = 7.0f;
        float stripeY = y + 2.0f;
        float stripeH = Math::Max(1.0f, drawHeight - 4.0f);
        DrawRacingStripe(drawList, windowPos, windowSize.x - 31.0f, stripeY, stripeW, stripeH, stripeA);
        DrawRacingStripe(drawList, windowPos, windowSize.x - 18.0f, stripeY, stripeW, stripeH, stripeB);

        if (entry.spectated) {
            DrawSpectatedBorder(drawList, windowPos, y, windowSize.x, drawHeight);
        }

        UI::Font@ activeRowFont = scale > 1.05f ? RowFontLarge : RowFont;
        float textY = y + Math::Max(3.0f, (drawHeight - 17.0f) * 0.5f);

        string position = Text::Format("%d", int(targetIndex + 1));
        TextAt(vec2(10, textY), position, activeRowFont, textColor);

        if (entry.clubTag.Length > 0) {
            TextAt(vec2(34, textY), "[" + entry.clubTag + "]", SmallFont, TeamThemes::WithAlpha(textColor, 0.82f));
            TextAt(vec2(78, textY), entry.name, activeRowFont, textColor);
        } else {
            TextAt(vec2(36, textY), entry.name, activeRowFont, textColor);
        }

        if (entry.spectated) {
            TextAt(vec2(windowSize.x - 145.0f, textY), "CAM", SmallFont, Spectated);
        }
        if (entry.respawn) {
            TextAt(vec2(windowSize.x - 110.0f, textY), "R", activeRowFont, Respawn);
        }

        TextAt(vec2(windowSize.x - 78.0f, textY), entry.timeText, activeRowFont, White);
    }

    void Render() {
        if (!S_ShowLiveRanking) return;

        LiveRankingState::SyncTeams();
        LayoutState::PrepareRanking();

        UI::PushStyleColor(UI::Col::WindowBg, vec4(0, 0, 0, 0));
        UI::PushStyleColor(UI::Col::Border, vec4(0, 0, 0, 0));
        UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(0, 0));
        UI::PushStyleVar(UI::StyleVar::WindowRounding, 0.0f);

        bool visible = UI::Begin("##MLETMProdLiveRanking", LayoutState::BroadcastWindowFlags());
        if (visible) {
            LayoutState::CaptureRanking();

            auto drawList = UI::GetWindowDrawList();
            vec2 windowPos = UI::GetWindowPos();
            vec2 windowSize = UI::GetWindowSize();

            float headerHeight = 35.0f;
            float footerHeight = 28.0f;
            float availableRows = windowSize.y - headerHeight - footerHeight;
            uint displayRows = LiveRankingState::DisplayRowCount();
            float rowHeight = availableRows / float(displayRows);

            drawList.AddRectFilled(
                vec4(windowPos, windowSize),
                vec4(0.035f, 0.045f, 0.055f, S_NonBannerOpacity),
                5.0f
            );

            TextAt(vec2(12, 7), "LIVE RANKING", HeaderFont, White);

            for (uint i = 0; i < LiveRankingState::Entries.Length && i < LiveRankingState::MaxSupportedRows; i++) {
                auto entry = LiveRankingState::Entries[i];
                if (!LiveRankingState::ShouldRenderEntry(i, entry, displayRows)) continue;
                if (LiveRankingState::IsLossAnimationActive(entry)) continue;
                DrawRow(drawList, windowPos, windowSize, headerHeight, rowHeight, i, entry);
            }
            for (uint i = 0; i < LiveRankingState::Entries.Length && i < LiveRankingState::MaxSupportedRows; i++) {
                auto entry = LiveRankingState::Entries[i];
                if (!LiveRankingState::ShouldRenderEntry(i, entry, displayRows)) continue;
                if (!LiveRankingState::IsLossAnimationActive(entry)) continue;
                DrawRow(drawList, windowPos, windowSize, headerHeight, rowHeight, i, entry);
            }

            float footerY = windowSize.y - footerHeight + 6.0f;
            TextAt(vec2(12, footerY), "R = RESPAWN", SmallFont, Respawn);
            TextAt(vec2(windowSize.x * 0.55f, footerY), "CAM = SPECTATED", SmallFont, Spectated);
        }
        UI::End();

        UI::PopStyleVar();
        UI::PopStyleVar();
        UI::PopStyleColor(2);
    }
}
