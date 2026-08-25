namespace GhostTabUI {
    class TabRequest {
        LeaderboardRecord@ record;
        vec2 anchorScreen;
        bool rowHovered;

        TabRequest(LeaderboardRecord@ record, const vec2 &in anchorScreen, bool rowHovered) {
            @this.record = record;
            this.anchorScreen = anchorScreen;
            this.rowHovered = rowHovered;
        }
    }

    array<TabRequest@> Requests;

    string HoverAccountId = "";
    uint HoverUntil = 0;
    const uint HoverGraceMs = 450;

    void BeginFrame() {
        Requests.RemoveRange(0, Requests.Length);
    }

    void Queue(LeaderboardRecord@ record, const vec2 &in anchorScreen, bool rowHovered) {
        if (record is null) return;
        Requests.InsertLast(TabRequest(record, anchorScreen, rowHovered));
    }

    void KeepExpanded(const string &in accountId) {
        HoverAccountId = accountId;
        HoverUntil = Time::Now + HoverGraceMs;
    }

    bool ShouldExpand(LeaderboardRecord@ record, bool rowHovered) {
        if (record is null) return false;
        if (rowHovered) return true;

        return HoverAccountId == record.accountId
            && Time::Now <= HoverUntil;
    }

    void SquareInnerEdge(const vec4 &in backgroundColor) {
        // The popout window itself is rounded so the exposed left edge forms the
        // half-pill. Fill the right half back in as a rectangle so the edge touching
        // the leaderboard is perfectly flat instead of looking like a detached bubble.
        auto drawList = UI::GetWindowDrawList();
        vec2 windowPos = UI::GetWindowPos();
        vec2 windowSize = UI::GetWindowSize();

        drawList.AddRectFilled(
            vec4(
                windowPos + vec2(windowSize.x * 0.5f, 0),
                vec2(windowSize.x * 0.5f, windowSize.y)
            ),
            backgroundColor,
            0
        );
    }

    void RenderRequest(TabRequest@ request) {
        if (request is null || request.record is null) return;

        auto record = request.record;
        bool active = GhostToggle::IsActive(record);
        bool loading = GhostToggle::IsLoading(record);
        bool canToggle = GhostToggle::CanUseGhost(record, false);

        // Inactive rows stay completely clean until the player hovers them. Active
        // ghosts keep a small nub visible so several enabled ghosts can be identified
        // at once without dedicating a permanent leaderboard column to the controls.
        if (!canToggle && !active && !loading) return;

        if (request.rowHovered) {
            KeepExpanded(record.accountId);
        }

        bool expanded = ShouldExpand(record, request.rowHovered);
        if (!expanded && !active && !loading) return;

        // Use zero window padding so these dimensions describe the actual silhouette.
        // The expanded control overlaps the leaderboard by 3 px. The collapsed nub
        // is mostly tucked under the leaderboard edge, leaving only its outer tip.
        float tabWidth = expanded ? 30.0f : 10.0f;
        float tabHeight = 22.0f;
        float exposedWidth = expanded ? 27.0f : 5.0f;
        float collapsedInwardOffset = expanded ? 0.0f : 25.0f;

        // These windows persist across frames, so force the calculated position every
        // frame. Without Cond::Always, the collapsed nub can remain at the expanded
        // tab's old position and look like a detached island.
        UI::SetNextWindowPos(
            int(request.anchorScreen.x - exposedWidth + collapsedInwardOffset),
            int(request.anchorScreen.y - 3.0f),
            UI::Cond::Always
        );

        vec4 leaderboardBg = UI::GetStyleColor(UI::Col::WindowBg);
        UI::PushStyleColor(UI::Col::WindowBg, leaderboardBg);
        UI::PushStyleColor(UI::Col::Border, leaderboardBg);

        UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(0, 0));
        UI::PushStyleVar(UI::StyleVar::WindowRounding, tabHeight * 0.5f);

        int flags = UI::WindowFlags::NoTitleBar
            | UI::WindowFlags::NoCollapse
            | UI::WindowFlags::AlwaysAutoResize
            | UI::WindowFlags::NoDocking
            | UI::WindowFlags::NoFocusOnAppearing
            | UI::WindowFlags::NoMove;

        bool tabVisible = UI::Begin("##MLEGhostTab_" + record.accountId, flags);
        if (tabVisible) {
            SquareInnerEdge(leaderboardBg);

            UI::BeginDisabled(expanded && (loading || !canToggle));
            bool clicked = UI::InvisibleButton(
                expanded ? "##MLEGhostToggle" : "##MLEGhostActiveNub",
                vec2(tabWidth, tabHeight)
            );
            UI::EndDisabled();

            bool controlHovered = UI::IsItemHovered();

            if (expanded) {
                // Draw the eye directly into the button rectangle. Keep this independent
                // from ImGui layout so optical positioning cannot extend window bounds.
                vec4 buttonRect = UI::GetItemRect();
                auto drawList = UI::GetWindowDrawList();
                drawList.AddText(
                    vec2(buttonRect.x - 2.0f, buttonRect.y + 5.0f),
                    UI::GetStyleColor(UI::Col::Text),
                    Icons::Eye
                );
            }

            if (controlHovered) {
                KeepExpanded(record.accountId);

                if (loading) {
                    UI::SetTooltip("Loading " + record.mleName + "'s ghost...");
                } else if (active) {
                    UI::SetTooltip("Disable " + record.mleName + "'s ghost");
                } else if (canToggle) {
                    UI::SetTooltip("Enable " + record.mleName + "'s ghost");
                } else {
                    UI::SetTooltip("Ghost control unavailable right now");
                }
            }

            if (expanded && clicked) {
                GhostToggle::Toggle(record);
                KeepExpanded(record.accountId);
            }
        }
        UI::End();

        UI::PopStyleVar();
        UI::PopStyleVar();
        UI::PopStyleColor(2);
    }

    void Flush() {
        for (uint i = 0; i < Requests.Length; i++) {
            RenderRequest(Requests[i]);
        }
        Requests.RemoveRange(0, Requests.Length);
    }
}
