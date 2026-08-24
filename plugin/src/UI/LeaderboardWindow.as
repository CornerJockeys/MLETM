bool g_ShowMLELeaderboard = true;
bool g_ShowFullMLELeaderboard = false;

void RenderMenu() {
    if (UI::MenuItem("MLE TM Leaderboard", "", g_ShowMLELeaderboard)) {
        g_ShowMLELeaderboard = !g_ShowMLELeaderboard;
    }
}

void Render() {
    if (!g_ShowMLELeaderboard) return;
    if (!RuntimeState::HasPlayableContext) return;

    auto mapInfo = RuntimeState::CurrentMap;
    auto player = RuntimeState::LocalPlayer;
    auto leaderboard = RuntimeState::CurrentLeaderboard;

    if (mapInfo is null || player is null || leaderboard is null || leaderboard.records.Length == 0) return;

    int flags = UI::WindowFlags::NoTitleBar
        | UI::WindowFlags::NoCollapse
        | UI::WindowFlags::AlwaysAutoResize
        | UI::WindowFlags::NoDocking
        | UI::WindowFlags::NoFocusOnAppearing;

    if (!UI::IsOverlayShown()) {
        flags |= UI::WindowFlags::NoMove;
    }

    UI::Begin("MLE TM Leaderboard", flags);

    UI::Text(mapInfo.name);
    UI::Text(player.league + " League  [" + player.division + "]");
    UI::Separator();

    if (UI::Button(g_ShowFullMLELeaderboard ? "Compact View" : "Full Leaderboard")) {
        g_ShowFullMLELeaderboard = !g_ShowFullMLELeaderboard;
    }

    if (ReplayViewer::Viewing) {
        UI::SameLine();

        UI::BeginDisabled(ReplayViewer::Exiting);
        if (UI::Button(ReplayViewer::Exiting ? "Exiting..." : "Exit Replay")) {
            ReplayViewer::RequestExit();
        }
        UI::EndDisabled();

        if (UI::IsItemHovered() && ReplayViewer::ViewingPlayerName.Length > 0) {
            UI::SetTooltip("Return from " + ReplayViewer::ViewingPlayerName + "'s replay");
        }
    }

    UI::Separator();

    if (g_ShowFullMLELeaderboard) {
        RenderFullLeaderboardTable(leaderboard, player);
    } else {
        RenderCompactLeaderboardTable(leaderboard, player);
    }

    UI::End();
}

void RenderCompactLeaderboardTable(MapLeaderboard@ leaderboard, PlayerInfo@ player) {
    uint topCount = Math::Min(uint(10), leaderboard.records.Length);

    UI::BeginTable("MLELeaderboardTop", 3, UI::TableFlags::SizingFixedFit);
    SetupLeaderboardColumns();
    RenderLeaderboardHeader();

    for (uint i = 0; i < topCount; i++) {
        auto record = leaderboard.records[i];
        RenderLeaderboardRow(leaderboard, i + 1, record, record.accountId == player.accountId);
    }

    UI::EndTable();

    if (RuntimeState::LocalRecord !is null && RuntimeState::LocalRank > topCount) {
        UI::Separator();

        UI::BeginTable("MLELeaderboardLocal", 3, UI::TableFlags::SizingFixedFit);
        SetupLeaderboardColumns();
        RenderLeaderboardRow(leaderboard, RuntimeState::LocalRank, RuntimeState::LocalRecord, true);
        UI::EndTable();
    }
}

void RenderFullLeaderboardTable(MapLeaderboard@ leaderboard, PlayerInfo@ player) {
    UI::BeginChild("MLELeaderboardFullScroll", vec2(285, 360), true);

    UI::BeginTable("MLELeaderboardFull", 3, UI::TableFlags::SizingFixedFit);
    SetupLeaderboardColumns();
    RenderLeaderboardHeader();

    for (uint i = 0; i < leaderboard.records.Length; i++) {
        auto record = leaderboard.records[i];
        RenderLeaderboardRow(leaderboard, i + 1, record, record.accountId == player.accountId);
    }

    UI::EndTable();
    UI::EndChild();
}

void SetupLeaderboardColumns() {
    UI::TableSetupColumn("Pos", UI::TableColumnFlags::WidthFixed, 36);
    UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
    UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed, 85);
}

void RenderLeaderboardHeader() {
    UI::TableNextRow();

    UI::TableNextColumn();
    UI::Text("Pos");

    UI::TableNextColumn();
    UI::Text("Player");

    UI::TableNextColumn();
    UI::Text("Time");
}

string FormatClubTagForUi(const string &in tagFormat) {
    return tagFormat.Replace("$", "\\$");
}

bool RecordsShareDisplayedClub(LeaderboardRecord@ a, LeaderboardRecord@ b) {
    if (a is null || b is null) return false;

    if (a.clubId.Length > 0 && b.clubId.Length > 0) {
        return a.clubId == b.clubId;
    }

    if (a.team.Length > 0 && b.team.Length > 0) {
        return a.team == b.team;
    }

    return a.clubTag.Length > 0 && a.clubTag == b.clubTag;
}

string BuildClubHoverText(MapLeaderboard@ leaderboard, LeaderboardRecord@ hoveredRecord) {
    if (leaderboard is null || hoveredRecord is null) return "";

    string title = hoveredRecord.team.Length > 0 ? hoveredRecord.team : hoveredRecord.clubTag;
    if (hoveredRecord.clubTag.Length > 0 && hoveredRecord.clubTag != title) {
        title += " [" + hoveredRecord.clubTag + "]";
    }

    string tooltip = title;
    uint matchingCount = 0;
    uint topThreePlacementSum = 0;

    for (uint i = 0; i < leaderboard.records.Length; i++) {
        auto clubRecord = leaderboard.records[i];
        if (!RecordsShareDisplayedClub(hoveredRecord, clubRecord)) continue;

        uint placement = i + 1;
        matchingCount++;

        if (matchingCount <= 3) {
            topThreePlacementSum += placement;
        }

        tooltip += "\n#" + Text::Format("%d", placement)
            + "  " + clubRecord.mleName
            + "  " + FormatRaceTime(clubRecord.timeMs);
    }

    if (matchingCount >= 3) {
        float averagePlacement = float(topThreePlacementSum) / 3.0f;
        tooltip += "\n\nTop 3 Avg Pos: " + Text::Format("%.2f", averagePlacement);
    }

    return tooltip;
}

void RenderLeaderboardRow(MapLeaderboard@ leaderboard, uint rank, LeaderboardRecord@ record, bool isLocalPlayer) {
    UI::TableNextRow();

    UI::TableNextColumn();
    UI::Text(Text::Format("%d", rank));

    UI::TableNextColumn();

    bool renderedClubTag = false;

    if (record.clubTagFormat.Length > 0) {
        UI::Text(FormatClubTagForUi(record.clubTagFormat));
        renderedClubTag = true;
    } else if (record.clubTag.Length > 0) {
        UI::Text(record.clubTag);
        renderedClubTag = true;
    }

    if (renderedClubTag) {
        if (UI::IsItemHovered()) {
            UI::SetTooltip(BuildClubHoverText(leaderboard, record));
        }
        UI::SameLine();
    }

    string playerLabel = record.mleName;
    if (isLocalPlayer) playerLabel += "  (You)";
    if (record.provisional) playerLabel += "  *";
    UI::Text(playerLabel);

    if (!record.provisional && record.replayUrl.Length > 0) {
        if (UI::IsItemHovered()) {
            UI::SetTooltip(ReplayViewer::Loading ? "Loading replay..." : "Click to load replay");
        }

        if (UI::IsItemClicked()) {
            ReplayViewer::Request(record);
        }
    }

    UI::TableNextColumn();
    UI::Text(FormatRaceTime(record.timeMs));

    if (record.provisional && UI::IsItemHovered()) {
        UI::SetTooltip("Local PB - awaiting backend confirmation");
    }
}
