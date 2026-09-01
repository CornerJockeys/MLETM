namespace LiveRanking {
    UI::Font@ HeaderFont;
    UI::Font@ RowFont;
    UI::Font@ SmallFont;

    const vec4 White = vec4(0.96f, 0.97f, 0.98f, 1.0f);
    const vec4 Muted = vec4(0.68f, 0.70f, 0.73f, 1.0f);
    const vec4 Panel = vec4(0.035f, 0.045f, 0.055f, 0.93f);
    const vec4 RowA = vec4(0.055f, 0.065f, 0.078f, 0.94f);
    const vec4 RowB = vec4(0.070f, 0.080f, 0.092f, 0.94f);
    const vec4 Respawn = vec4(0.95f, 0.66f, 0.18f, 1.0f);
    const vec4 Spectated = vec4(0.12f, 0.82f, 0.76f, 1.0f);

    void Initialize() {
        @HeaderFont = UI::LoadFont("DroidSans.ttf", 18);
        @RowFont = UI::LoadFont("DroidSans.ttf", 14);
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

    void Render() {
        if (!S_ShowLiveRanking) return;

        LiveRankingState::SyncTeams();

        UI::SetNextWindowPos(14, 48, UI::Cond::FirstUseEver);
        UI::SetNextWindowSize(300, 250, UI::Cond::FirstUseEver);

        UI::PushStyleColor(UI::Col::WindowBg, vec4(0, 0, 0, 0));
        UI::PushStyleColor(UI::Col::Border, vec4(0, 0, 0, 0));
        UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(0, 0));
        UI::PushStyleVar(UI::StyleVar::WindowRounding, 0.0f);

        int flags = UI::WindowFlags::NoTitleBar
            | UI::WindowFlags::NoCollapse
            | UI::WindowFlags::NoDocking
            | UI::WindowFlags::NoFocusOnAppearing;

        bool visible = UI::Begin("##MLETMProdLiveRanking", flags);
        if (visible) {
            auto drawList = UI::GetWindowDrawList();
            vec2 windowPos = UI::GetWindowPos();
            vec2 windowSize = UI::GetWindowSize();

            float headerHeight = 35.0f;
            float footerHeight = 28.0f;
            float availableRows = windowSize.y - headerHeight - footerHeight;
            float rowHeight = availableRows / 6.0f;

            drawList.AddRectFilled(vec4(windowPos, windowSize), Panel, 5.0f);
            drawList.AddRectFilled(
                vec4(windowPos + vec2(0, headerHeight - 2.0f), vec2(windowSize.x, 2.0f)),
                vec4(0.122f, 0.749f, 0.361f, 0.9f),
                0
            );

            TextAt(vec2(12, 7), "LIVE RANKING", HeaderFont, White);

            for (uint i = 0; i < LiveRankingState::Entries.Length && i < 6; i++) {
                auto entry = LiveRankingState::Entries[i];
                if (entry is null) continue;

                float y = headerHeight + rowHeight * float(i);
                vec4 rowColor = (i % 2 == 0) ? RowA : RowB;
                vec4 primary = MatchState::ResolvePrimaryColor(entry.team);
                vec4 secondary = MatchState::ResolveSecondaryColor(entry.team);

                drawList.AddRectFilled(
                    vec4(windowPos + vec2(0, y), vec2(windowSize.x, rowHeight - 1.0f)),
                    rowColor,
                    0
                );
                drawList.AddRectFilled(
                    vec4(windowPos + vec2(0, y), vec2(5.0f, rowHeight - 1.0f)),
                    primary,
                    0
                );

                // Temporary straight racing stripes. Once the first Openplanet render is
                // validated these become the slanted secondary/alternate stripes.
                drawList.AddRectFilled(
                    vec4(windowPos + vec2(windowSize.x - 9.0f, y), vec2(4.0f, rowHeight - 1.0f)),
                    secondary,
                    0
                );
                drawList.AddRectFilled(
                    vec4(windowPos + vec2(windowSize.x - 4.0f, y), vec2(4.0f, rowHeight - 1.0f)),
                    primary,
                    0
                );

                string position = Text::Format("%d", int(i + 1));
                TextAt(vec2(10, y + 5.0f), position, RowFont, White);
                TextAt(vec2(36, y + 5.0f), entry.name, RowFont, White);
                TextAt(vec2(windowSize.x - 82.0f, y + 5.0f), entry.timeText, RowFont, White);

                if (entry.respawn) {
                    TextAt(vec2(windowSize.x - 105.0f, y + 5.0f), "R", RowFont, Respawn);
                }
                if (entry.spectated) {
                    TextAt(vec2(24, y + 5.0f), ">", RowFont, Spectated);
                }
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
