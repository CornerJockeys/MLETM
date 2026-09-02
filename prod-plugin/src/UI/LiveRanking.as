namespace LiveRanking {
    UI::Font@ HeaderFont;
    UI::Font@ RowFont;
    UI::Font@ RowFontLarge;
    UI::Font@ SmallFont;

    const vec4 White = vec4(0.96f, 0.97f, 0.98f, 1.0f);
    const vec4 Panel = vec4(0.035f, 0.045f, 0.055f, 0.93f);
    const vec4 RowA = vec4(0.055f, 0.065f, 0.078f, 0.94f);
    const vec4 RowB = vec4(0.070f, 0.080f, 0.092f, 0.94f);
    const vec4 Respawn = vec4(0.95f, 0.66f, 0.18f, 1.0f);
    const vec4 Spectated = vec4(0.12f, 0.82f, 0.76f, 1.0f);

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
        float baseHeight = rowHeight - 1.0f;
        float drawHeight = baseHeight * scale;
        float centerY = headerHeight + rowHeight * (visualRank + 0.5f);
        float y = centerY - drawHeight * 0.5f;

        vec4 rowColor = (targetIndex % 2 == 0) ? RowA : RowB;
        vec4 primary = TeamThemes::Primary(entry.team);
        vec4 stripeA = TeamThemes::RacingStripeA(entry.team);
        vec4 stripeB = TeamThemes::RacingStripeB(entry.team);

        drawList.AddRectFilled(
            vec4(windowPos + vec2(0, y), vec2(windowSize.x, drawHeight)),
            rowColor,
            0
        );
        drawList.AddRectFilled(
            vec4(windowPos + vec2(0, y), vec2(5.0f, drawHeight)),
            primary,
            0
        );

        // Keep the first compile pass on proven rectangle primitives. The color model
        // already uses secondary + alternate franchise colors; the final cosmetic pass
        // can turn these into slanted quads without touching ranking state.
        drawList.AddRectFilled(
            vec4(windowPos + vec2(windowSize.x - 9.0f, y), vec2(4.0f, drawHeight)),
            stripeA,
            0
        );
        drawList.AddRectFilled(
            vec4(windowPos + vec2(windowSize.x - 4.0f, y), vec2(4.0f, drawHeight)),
            stripeB,
            0
        );

        UI::Font@ activeRowFont = scale > 1.05f ? RowFontLarge : RowFont;
        float textY = y + Math::Max(3.0f, (drawHeight - 17.0f) * 0.5f);

        string position = Text::Format("%d", int(targetIndex + 1));
        TextAt(vec2(10, textY), position, activeRowFont, White);
        TextAt(vec2(36, textY), entry.name, activeRowFont, White);
        TextAt(vec2(windowSize.x - 82.0f, textY), entry.timeText, activeRowFont, White);

        if (entry.respawn) {
            TextAt(vec2(windowSize.x - 105.0f, textY), "R", activeRowFont, Respawn);
        }
        if (entry.spectated) {
            TextAt(vec2(24, textY), ">", activeRowFont, Spectated);
        }
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

            drawList.AddRectFilled(vec4(windowPos, windowSize), Panel, 5.0f);
            drawList.AddRectFilled(
                vec4(windowPos + vec2(0, headerHeight - 2.0f), vec2(windowSize.x, 2.0f)),
                TeamThemes::MleGradientStart(),
                0
            );

            TextAt(vec2(12, 7), "LIVE RANKING", HeaderFont, White);

            // Draw ordinary/gaining rows first. A row losing position is drawn last so
            // its temporary enlargement remains visually on top while it drops. We keep
            // up to 16 racers buffered even when only a top-N subset is displayed, which
            // lets rows animate cleanly across the visible cutoff instead of popping.
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
            TextAt(vec2(windowSize.x * 0.52f, footerY), "> = SPECTATED", SmallFont, Spectated);
        }
        UI::End();

        UI::PopStyleVar();
        UI::PopStyleVar();
        UI::PopStyleColor(2);
    }
}
