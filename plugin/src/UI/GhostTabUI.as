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

        float tabWidth = expanded ? 32.0f : 10.0f;
        float tabHeight = 20.0f;

        // anchorScreen is the left edge of the current leaderboard window/child at
        // this row's vertical position. The small standalone window lets the control
        // genuinely protrude outside the leaderboard instead of consuming table width.
        UI::SetNextWindowPos(
            int(request.anchorScreen.x - tabWidth + 3.0f),
            int(request.anchorScreen.y - 2.0f)
        );

        UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(2, 2));
        UI::PushStyleVar(UI::StyleVar::WindowRounding, 10.0f);
        UI::PushStyleVar(UI::StyleVar::FrameRounding, 10.0f);

        int flags = UI::WindowFlags::NoTitleBar
            | UI::WindowFlags::NoCollapse
            | UI::WindowFlags::AlwaysAutoResize
            | UI::WindowFlags::NoDocking
            | UI::WindowFlags::NoFocusOnAppearing
            | UI::WindowFlags::NoMove;

        bool tabVisible = UI::Begin("##MLEGhostTab_" + record.accountId, flags);
        if (tabVisible) {
            if (expanded) {
                UI::BeginDisabled(loading || !canToggle);
                bool clicked = UI::Button(Icons::Eye + "##MLEGhostToggle", vec2(24, tabHeight));
                UI::EndDisabled();

                bool controlHovered = UI::IsItemHovered();
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

                if (clicked) {
                    GhostToggle::Toggle(record);
                    KeepExpanded(record.accountId);
                }
            } else {
                // Active/loading rows leave only this rounded nub visible. Hovering it
                // re-expands the eye control on the next frame.
                UI::Button("##MLEGhostActiveNub", vec2(8, tabHeight));
                if (UI::IsItemHovered()) {
                    KeepExpanded(record.accountId);
                    UI::SetTooltip(
                        loading
                            ? "Loading " + record.mleName + "'s ghost..."
                            : record.mleName + "'s ghost is active"
                    );
                }
            }
        }
        UI::End();

        UI::PopStyleVar();
        UI::PopStyleVar();
        UI::PopStyleVar();
    }

    void Flush() {
        for (uint i = 0; i < Requests.Length; i++) {
            RenderRequest(Requests[i]);
        }
        Requests.RemoveRange(0, Requests.Length);
    }
}
