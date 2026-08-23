bool g_ShowMLELeaderboard = true;

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

    RenderLeaderboardTable(leaderboard, player);

    UI::End();
}

void RenderLeaderboardTable(MapLeaderboard@ leaderboard, PlayerInfo@ player) {
    uint topCount = Math::Min(uint(10), leaderboard.records.Length);

    UI::BeginTable("MLELeaderboardTop", 3, UI::TableFlags::SizingFixedFit);
    UI::TableSetupColumn("Pos", UI::TableColumnFlags::WidthFixed);
    UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
    UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed);

    RenderLeaderboardHeader();

    for (uint i = 0; i < topCount; i++) {
        auto record = leaderboard.records[i];
        RenderLeaderboardRow(i + 1, record, record.accountId == player.accountId);
    }

    UI::EndTable();

    if (RuntimeState::LocalRecord !is null && RuntimeState::LocalRank > topCount) {
        UI::Separator();

        UI::BeginTable("MLELeaderboardLocal", 3, UI::TableFlags::SizingFixedFit);
        UI::TableSetupColumn("Pos", UI::TableColumnFlags::WidthFixed);
        UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
        UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed);

        RenderLeaderboardRow(RuntimeState::LocalRank, RuntimeState::LocalRecord, true);
        UI::EndTable();
    }
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

void RenderLeaderboardRow(uint rank, LeaderboardRecord@ record, bool isLocalPlayer) {
    UI::TableNextRow();

    UI::TableNextColumn();
    UI::Text(Text::Format("%d", rank));

    UI::TableNextColumn();
    string playerLabel = record.mleName;
    if (isLocalPlayer) playerLabel += "  (You)";
    if (record.provisional) playerLabel += "  *";
    UI::Text(playerLabel);

    UI::TableNextColumn();
    UI::Text(FormatRaceTime(record.timeMs));

    if (record.provisional && UI::IsItemHovered()) {
        UI::SetTooltip("Local PB - awaiting backend confirmation");
    }
}
