namespace RecordsPanel {
    UI::Font@ LabelFont;
    UI::Font@ TimeFont;

    const vec4 White = vec4(0.96f, 0.97f, 0.98f, 1.0f);
    const vec4 Panel = vec4(0.035f, 0.045f, 0.055f, 0.93f);
    const vec4 Accent = vec4(0.122f, 0.749f, 0.361f, 1.0f);

    void Initialize() {
        @LabelFont = UI::LoadFont("DroidSans.ttf", 13);
        @TimeFont = UI::LoadFont("DroidSans.ttf", 22);
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
        if (!S_ShowRecordsPanel) return;

        UI::SetNextWindowPos(1640, 48, UI::Cond::FirstUseEver);
        UI::SetNextWindowSize(260, 150, UI::Cond::FirstUseEver);

        UI::PushStyleColor(UI::Col::WindowBg, vec4(0, 0, 0, 0));
        UI::PushStyleColor(UI::Col::Border, vec4(0, 0, 0, 0));
        UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(0, 0));
        UI::PushStyleVar(UI::StyleVar::WindowRounding, 0.0f);

        int flags = UI::WindowFlags::NoTitleBar
            | UI::WindowFlags::NoCollapse
            | UI::WindowFlags::NoDocking
            | UI::WindowFlags::NoFocusOnAppearing;

        bool visible = UI::Begin("##MLETMProdRecords", flags);
        if (visible) {
            auto drawList = UI::GetWindowDrawList();
            vec2 windowPos = UI::GetWindowPos();
            vec2 windowSize = UI::GetWindowSize();

            drawList.AddRectFilled(vec4(windowPos, windowSize), Panel, 5.0f);
            drawList.AddRectFilled(
                vec4(windowPos + vec2(0, windowSize.y - 3.0f), vec2(windowSize.x, 3.0f)),
                Accent,
                0
            );

            float half = windowSize.y * 0.5f;
            drawList.AddRectFilled(
                vec4(windowPos + vec2(12, half), vec2(windowSize.x - 24.0f, 1.0f)),
                vec4(0.22f, 0.23f, 0.26f, 1.0f),
                0
            );

            TextAt(vec2(14, 10), RecordsState::OverallLabel, LabelFont, White);
            TextAt(vec2(14, 30), RecordsState::OverallTime, TimeFont, White);

            TextAt(vec2(14, half + 8.0f), RecordsState::DivisionLabel, LabelFont, MatchState::DivisionColor);
            TextAt(vec2(14, half + 28.0f), RecordsState::DivisionTime, TimeFont, White);
        }
        UI::End();

        UI::PopStyleVar();
        UI::PopStyleVar();
        UI::PopStyleColor(2);
    }
}
