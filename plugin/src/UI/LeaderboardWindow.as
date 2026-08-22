bool g_ShowMLELeaderboard = true;

void RenderMenu() {
    if (UI::MenuItem("MLE TM Leaderboard", "", g_ShowMLELeaderboard)) {
        g_ShowMLELeaderboard = !g_ShowMLELeaderboard;
    }
}

void Render() {
    if (!g_ShowMLELeaderboard) return;

    auto app = cast<CGameManiaPlanet>(GetApp());
    if (app is null || app.RootMap is null || app.RootMap.MapInfo is null) return;

    auto cmap = app.Network.ClientManiaAppPlayground;
    if (cmap is null || cmap.LocalUser is null) return;

    string mapUid = app.RootMap.MapInfo.MapUid;
    string accountId = cmap.LocalUser.WebServicesUserId;
    if (mapUid.Length == 0 || accountId.Length == 0) return;

    auto mapInfo = MapDirectory::Get(mapUid);
    auto player = PlayerDirectory::Get(accountId);
    if (mapInfo is null || player is null) return;

    auto leaderboard = mapInfo.GetLeaderboard(player.division);
    if (leaderboard is null || leaderboard.records.Length == 0) return;

    int flags = UI::WindowFlags::NoTitleBar
        | UI::WindowFlags::NoCollapse
        | UI::WindowFlags::AlwaysAutoResize
        | UI::WindowFlags::NoDocking
        | UI::WindowFlags::NoFocusOnAppearing;

    // Keep the leaderboard fixed while playing, but allow it to be moved with F3 open.
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
    uint playerRank = 0;
    LeaderboardRecord@ playerRecord = null;

    for (uint i = 0; i < leaderboard.records.Length; i++) {
        auto record = leaderboard.records[i];
        if (record.accountId == player.accountId) {
            playerRank = i + 1;
            @playerRecord = record;
            break;
        }
    }

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

    // If the local player is outside the displayed top 10, always show their own row below it.
    if (playerRecord !is null && playerRank > topCount) {
        UI::Separator();

        UI::BeginTable("MLELeaderboardLocal", 3, UI::TableFlags::SizingFixedFit);
        UI::TableSetupColumn("Pos", UI::TableColumnFlags::WidthFixed);
        UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
        UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed);

        RenderLeaderboardRow(playerRank, playerRecord, true);
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
    UI::Text(playerLabel);

    UI::TableNextColumn();
    UI::Text(FormatRaceTime(record.timeMs));
}
