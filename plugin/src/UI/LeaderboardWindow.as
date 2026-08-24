bool g_ShowMLELeaderboard = true;
bool g_ShowFullMLELeaderboard = false;
string g_SelectedTeam = "";

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

    if (mapInfo is null || player is null) return;

    bool pushedFade = false;

    // During normal play, fade with the 3-2-1 countdown and disappear at GO.
    // Keep the leaderboard fully visible when the Openplanet overlay is opened or
    // while replay viewing needs its exit control.
    if (!ReplayViewer::Viewing && !UI::IsOverlayShown()) {
        float alpha = PBMonitor::LeaderboardAlpha;
        if (alpha <= 0.01f) return;

        if (alpha < 0.999f) {
            UI::PushStyleVar(UI::StyleVar::Alpha, alpha);
            pushedFade = true;
        }
    }

    int flags = UI::WindowFlags::NoTitleBar
        | UI::WindowFlags::NoCollapse
        | UI::WindowFlags::AlwaysAutoResize
        | UI::WindowFlags::NoDocking
        | UI::WindowFlags::NoFocusOnAppearing;

    // Do not set NoMove here. Openplanet already controls when the overlay can
    // receive mouse input, and keeping the window movable lets the player place it
    // wherever they want when the overlay is open.
    UI::Begin("MLE TM Leaderboard", flags);

    UI::Text(mapInfo.name);

    UI::Text("Leaderboard");
    UI::SameLine();

    if (UI::Button("<##MLEPrevDivision")) {
        RuntimeState::CycleViewedDivision(-1);
    }

    UI::SameLine();
    string viewedDivision = RuntimeState::ViewedDivision.Length > 0
        ? RuntimeState::ViewedDivision
        : player.division;
    UI::Text("[" + viewedDivision + "]");

    UI::SameLine();
    if (UI::Button(">##MLENextDivision")) {
        RuntimeState::CycleViewedDivision(1);
    }

    if (UI::IsItemHovered()) {
        UI::SetTooltip("Your division: " + player.division);
    }

    UI::SameLine();
    UI::SetNextItemWidth(115);
    string teamFilterLabel = g_SelectedTeam.Length > 0 ? g_SelectedTeam : "All Teams";
    if (UI::BeginCombo("##MLETeamFilter", teamFilterLabel)) {
        if (UI::Selectable("All Teams", g_SelectedTeam.Length == 0)) {
            g_SelectedTeam = "";
        }

        if (player.team.Length > 0) {
            if (UI::Selectable("My Team - " + player.team, g_SelectedTeam == player.team)) {
                g_SelectedTeam = player.team;
            }
        }

        if (PlayerDirectory::Teams.Length > 0) {
            UI::Separator();

            for (uint i = 0; i < PlayerDirectory::Teams.Length; i++) {
                string team = PlayerDirectory::Teams[i];
                if (team == player.team) continue;

                if (UI::Selectable(team, g_SelectedTeam == team)) {
                    g_SelectedTeam = team;
                }
            }
        }

        UI::EndCombo();
    }

    if (UI::IsItemHovered()) {
        UI::SetTooltip("Filter the current leaderboard by team");
    }

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

    if (RuntimeState::LeaderboardLoading) {
        UI::Text("Loading " + viewedDivision + " records...");
        UI::End();
        if (pushedFade) UI::PopStyleVar();
        return;
    }

    if (leaderboard is null || leaderboard.records.Length == 0) {
        UI::Text("No " + viewedDivision + " records on this map.");
        UI::End();
        if (pushedFade) UI::PopStyleVar();
        return;
    }

    uint displayedCount = CountDisplayedRecords(leaderboard);
    if (displayedCount == 0) {
        UI::Text(
            g_SelectedTeam.Length > 0
                ? "No " + g_SelectedTeam + " records in " + viewedDivision + " on this map."
                : "No " + viewedDivision + " records on this map."
        );
        UI::End();
        if (pushedFade) UI::PopStyleVar();
        return;
    }

    if (g_ShowFullMLELeaderboard) {
        RenderFullLeaderboardTable(leaderboard, player);
    } else {
        RenderCompactLeaderboardTable(leaderboard, player);
    }

    UI::End();
    if (pushedFade) UI::PopStyleVar();
}

bool RecordPassesTeamFilter(LeaderboardRecord@ record) {
    if (record is null) return false;
    if (g_SelectedTeam.Length == 0) return true;
    return record.team == g_SelectedTeam;
}

uint CountDisplayedRecords(MapLeaderboard@ leaderboard) {
    if (leaderboard is null) return 0;

    uint count = 0;
    for (uint i = 0; i < leaderboard.records.Length; i++) {
        if (RecordPassesTeamFilter(leaderboard.records[i])) {
            count++;
        }
    }
    return count;
}

void RenderCompactLeaderboardTable(MapLeaderboard@ leaderboard, PlayerInfo@ player) {
    uint displayedCount = CountDisplayedRecords(leaderboard);
    uint topCount = Math::Min(uint(10), displayedCount);
    uint renderedCount = 0;

    UI::BeginTable("MLELeaderboardTop", 3, UI::TableFlags::SizingFixedFit);
    SetupLeaderboardColumns();
    RenderLeaderboardHeader();

    for (uint i = 0; i < leaderboard.records.Length && renderedCount < topCount; i++) {
        auto record = leaderboard.records[i];
        if (!RecordPassesTeamFilter(record)) continue;

        renderedCount++;
        RenderLeaderboardRow(leaderboard, i + 1, record, record.accountId == player.accountId, true);
    }

    UI::EndTable();

    LeaderboardRecord@ localDisplayedRecord = null;
    uint localDisplayedOrder = 0;
    uint localOriginalRank = 0;
    uint displayedOrder = 0;

    for (uint i = 0; i < leaderboard.records.Length; i++) {
        auto record = leaderboard.records[i];
        if (!RecordPassesTeamFilter(record)) continue;

        displayedOrder++;
        if (record.accountId == player.accountId) {
            @localDisplayedRecord = record;
            localDisplayedOrder = displayedOrder;
            localOriginalRank = i + 1;
            break;
        }
    }

    if (localDisplayedRecord !is null && localDisplayedOrder > topCount) {
        UI::Separator();

        UI::BeginTable("MLELeaderboardLocal", 3, UI::TableFlags::SizingFixedFit);
        SetupLeaderboardColumns();
        RenderLeaderboardRow(leaderboard, localOriginalRank, localDisplayedRecord, true, true);
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
        if (!RecordPassesTeamFilter(record)) continue;

        RenderLeaderboardRow(leaderboard, i + 1, record, record.accountId == player.accountId, false);
    }

    UI::EndTable();
    UI::EndChild();
}

void SetupLeaderboardColumns() {
    UI::TableSetupColumn("Pos", UI::TableColumnFlags::WidthFixed, 48);
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
        if (!RecordPassesTeamFilter(clubRecord)) continue;
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

void RenderLeaderboardRow(MapLeaderboard@ leaderboard, uint rank, LeaderboardRecord@ record, bool isLocalPlayer, bool showTotal) {
    UI::TableNextRow();

    UI::TableNextColumn();
    if (showTotal) {
        UI::Text(Text::Format("%d", rank) + "/" + Text::Format("%d", leaderboard.records.Length));
    } else {
        UI::Text(Text::Format("%d", rank));
    }

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
