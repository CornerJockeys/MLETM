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

        if (RuntimeState::TeamOptions.Length > 0) {
            UI::Separator();

            for (uint i = 0; i < RuntimeState::TeamOptions.Length; i++) {
                string team = RuntimeState::TeamOptions[i];
                if (team.Length == 0 || team == player.team) continue;

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
    bool canShowNoTimeLocal = !g_ShowFullMLELeaderboard && ShouldShowLocalPlaceholder(player);
    if (displayedCount == 0 && !canShowNoTimeLocal) {
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

bool ShouldShowLocalPlaceholder(PlayerInfo@ player) {
    if (player is null) return false;
    return g_SelectedTeam.Length == 0 || g_SelectedTeam == player.team;
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
        bool isLocalPlayer = record.accountId == player.accountId;
        RenderLeaderboardRow(leaderboard, i + 1, record, isLocalPlayer, false);
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

    bool showRankedLocalRow = localDisplayedRecord !is null && localDisplayedOrder > topCount;
    bool showNoTimeLocalRow = localDisplayedRecord is null && ShouldShowLocalPlaceholder(player);

    if (showRankedLocalRow || showNoTimeLocalRow) {
        UI::Separator();

        UI::BeginTable("MLELeaderboardLocal", 3, UI::TableFlags::SizingFixedFit);
        SetupLeaderboardColumns();

        if (showRankedLocalRow) {
            RenderLeaderboardRow(leaderboard, localOriginalRank, localDisplayedRecord, true, true);
            RenderNextMedalTargetRow(localDisplayedRecord.timeMs);
        } else {
            RenderNoTimeLocalRow(leaderboard, player);
            RenderNextMedalTargetRow(0);
        }

        UI::EndTable();
    }
}

void RenderNoTimeLocalRow(MapLeaderboard@ leaderboard, PlayerInfo@ player) {
    UI::TableNextRow();

    UI::TableNextColumn();
    UI::Text("--/" + Text::Format("%d", leaderboard.records.Length));

    UI::TableNextColumn();

    // Reuse a teammate's authoritative club display when one exists on this board.
    // If nobody from the team has a record yet, the player's name alone is enough
    // to represent the unranked local row without inventing club data.
    LeaderboardRecord@ teamDisplayRecord = null;
    for (uint i = 0; i < leaderboard.records.Length; i++) {
        auto record = leaderboard.records[i];
        if (record.team != player.team) continue;
        if (record.clubTagFormat.Length == 0 && record.clubTag.Length == 0) continue;

        @teamDisplayRecord = record;
        break;
    }

    bool renderedClubTag = false;
    if (teamDisplayRecord !is null) {
        if (teamDisplayRecord.clubTagFormat.Length > 0) {
            UI::Text(FormatClubTagForUi(teamDisplayRecord.clubTagFormat));
            renderedClubTag = true;
        } else if (teamDisplayRecord.clubTag.Length > 0) {
            UI::Text(teamDisplayRecord.clubTag);
            renderedClubTag = true;
        }

        if (renderedClubTag) {
            if (UI::IsItemHovered()) {
                RenderClubHoverTooltip(leaderboard, teamDisplayRecord);
            }
            UI::SameLine();
        }
    }

    UI::Text(player.mleName + "  (You)");

    UI::TableNextColumn();
    UI::Text("-:--.---");
}

void RenderNextMedalTargetRow(uint playerTimeMs) {
    MedalTarget::Medal nextMedal = MedalTarget::GetNext(playerTimeMs);
    if (nextMedal == MedalTarget::Medal::None) return;

    uint targetTime = MedalTarget::GetTime(nextMedal);
    if (targetTime == 0) return;

    UI::TableNextRow();

    UI::TableNextColumn();
    UI::Text("");

    UI::TableNextColumn();
    UI::Text("Next:");

    auto texture = MedalTarget::GetTexture(nextMedal);
    if (texture !is null) {
        UI::SameLine();
        UI::Image(texture, vec2(18, 18));
    }

    UI::SameLine();
    UI::Text(MedalTarget::GetName(nextMedal));

    UI::TableNextColumn();
    UI::Text(FormatRaceTime(targetTime));
}

void RenderFullLeaderboardTable(MapLeaderboard@ leaderboard, PlayerInfo@ player) {
    UI::BeginChild("MLELeaderboardFullScroll", vec2(285, 360), true);

    UI::BeginTable("MLELeaderboardFull", 3, UI::TableFlags::SizingFixedFit);
    SetupLeaderboardColumns();
    RenderLeaderboardHeader();

    for (uint i = 0; i < leaderboard.records.Length; i++) {
        auto record = leaderboard.records[i];
        if (!RecordPassesTeamFilter(record)) continue;

        bool isLocalPlayer = record.accountId == player.accountId;
        RenderLeaderboardRow(leaderboard, i + 1, record, isLocalPlayer, false);
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

string FormatPlayerSalary(float salary) {
    string value = Text::Format("%.2f", salary);

    while (value.EndsWith("0")) {
        value = value.SubStr(0, value.Length - 1);
    }
    if (value.EndsWith(".")) {
        value = value.SubStr(0, value.Length - 1);
    }

    return value;
}

void RenderClubHoverTooltip(MapLeaderboard@ leaderboard, LeaderboardRecord@ hoveredRecord) {
    if (leaderboard is null || hoveredRecord is null) return;

    string title = hoveredRecord.team.Length > 0 ? hoveredRecord.team : hoveredRecord.clubTag;
    if (hoveredRecord.clubTag.Length > 0 && hoveredRecord.clubTag != title) {
        title += " [" + hoveredRecord.clubTag + "]";
    }

    uint matchingCount = 0;
    uint topThreePlacementSum = 0;
    uint topThreeTimeSum = 0;

    UI::BeginTooltip();
    UI::Text(title);
    UI::Separator();

    if (UI::BeginTable("##MLEClubHoverTable", 4, UI::TableFlags::SizingFixedFit)) {
        UI::TableSetupColumn("Pos", UI::TableColumnFlags::WidthFixed, 42);
        UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
        UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed, 82);
        UI::TableSetupColumn("Salary", UI::TableColumnFlags::WidthFixed, 58);

        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text("Pos");
        UI::TableNextColumn();
        UI::Text("Player");
        UI::TableNextColumn();
        UI::Text("Time");
        UI::TableNextColumn();
        UI::Text("Salary");

        for (uint i = 0; i < leaderboard.records.Length; i++) {
            auto clubRecord = leaderboard.records[i];
            if (!RecordPassesTeamFilter(clubRecord)) continue;
            if (!RecordsShareDisplayedClub(hoveredRecord, clubRecord)) continue;

            uint placement = i + 1;
            matchingCount++;

            if (matchingCount <= 3) {
                topThreePlacementSum += placement;
                topThreeTimeSum += clubRecord.timeMs;
            }

            float salary = clubRecord.salary;
            if (salary < 0.0f
                && RuntimeState::LocalPlayer !is null
                && clubRecord.accountId == RuntimeState::LocalPlayer.accountId) {
                salary = RuntimeState::LocalPlayer.salary;
            }

            UI::TableNextRow();

            UI::TableNextColumn();
            UI::Text("#" + Text::Format("%d", placement));

            UI::TableNextColumn();
            UI::Text(clubRecord.mleName);

            UI::TableNextColumn();
            UI::Text(FormatRaceTime(clubRecord.timeMs));

            UI::TableNextColumn();
            UI::Text(salary >= 0.0f ? FormatPlayerSalary(salary) : "—");
        }

        UI::EndTable();
    }

    if (matchingCount >= 3) {
        UI::Separator();
        float averagePlacement = float(topThreePlacementSum) / 3.0f;
        uint averageTime = (topThreeTimeSum + 1) / 3;
        UI::Text("Top 3 Avg Pos: " + Text::Format("%.2f", averagePlacement));
        UI::Text("Top 3 Avg Time: " + FormatRaceTime(averageTime));
    }

    UI::EndTooltip();
}

bool PushPodiumTextColor(uint rank) {
    if (rank == 1) {
        UI::PushStyleColor(UI::Col::Text, vec4(1.00f, 0.76f, 0.16f, 1.00f));
        return true;
    }

    if (rank == 2) {
        UI::PushStyleColor(UI::Col::Text, vec4(0.78f, 0.82f, 0.88f, 1.00f));
        return true;
    }

    if (rank == 3) {
        UI::PushStyleColor(UI::Col::Text, vec4(0.80f, 0.50f, 0.28f, 1.00f));
        return true;
    }

    return false;
}

string FormatPBTransitionRank(uint rank, uint total, bool showTotal) {
    if (rank == 0) {
        return showTotal
            ? "--/" + Text::Format("%d", total)
            : "--";
    }

    if (showTotal) {
        return Text::Format("%d", rank) + "/" + Text::Format("%d", total);
    }

    return Text::Format("%d", rank);
}

string FormatPBPlacementChange() {
    if (PBMonitor::PBTransitionOldRank == 0) return "NEW";

    if (PBMonitor::PBTransitionNewRank < PBMonitor::PBTransitionOldRank) {
        return "▲" + Text::Format(
            "%d",
            PBMonitor::PBTransitionOldRank - PBMonitor::PBTransitionNewRank
        );
    }

    return "—";
}

string FormatPBTimeDelta(uint oldTime, uint newTime) {
    if (oldTime == 0 || newTime >= oldTime) return "";

    uint delta = oldTime - newTime;
    if (delta >= 60000) {
        return "-" + FormatRaceTime(delta);
    }

    uint seconds = delta / 1000;
    uint millis = delta % 1000;

    string millisText = Text::Format("%d", millis);
    if (millis < 100) millisText = "0" + millisText;
    if (millis < 10) millisText = "0" + millisText;

    return "-" + Text::Format("%d", seconds) + "." + millisText;
}

bool BeginPBTransitionCell(const string &in id) {
    UI::PushStyleColor(UI::Col::ChildBg, vec4(0, 0, 0, 0));
    UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(0, 0));
    UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));

    int flags = UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoScrollWithMouse;
    return UI::BeginChild(id, vec2(0, UI::GetTextLineHeight()), false, flags);
}

void EndPBTransitionCell() {
    float maxScroll = UI::GetScrollMaxY();
    if (maxScroll > 0.0f) {
        UI::SetScrollY(maxScroll * PBMonitor::GetPBTransitionScrollProgress());
    }

    UI::EndChild();
    UI::PopStyleVar();
    UI::PopStyleVar();
    UI::PopStyleColor();
}

void RenderPBTransitionPlayerIdentity(LeaderboardRecord@ record, bool provisional) {
    bool renderedClubTag = false;

    if (record.clubTagFormat.Length > 0) {
        UI::Text(FormatClubTagForUi(record.clubTagFormat));
        renderedClubTag = true;
    } else if (record.clubTag.Length > 0) {
        UI::Text(record.clubTag);
        renderedClubTag = true;
    }

    if (renderedClubTag) {
        UI::SameLine();
    }

    string playerLabel = record.mleName + "  (You)";
    if (provisional) playerLabel += "  *";
    UI::Text(playerLabel);
}

void RenderPBTransitionRow(LeaderboardRecord@ record, bool showTotal) {
    UI::TableNextRow();

    UI::TableNextColumn();
    bool posCellVisible = BeginPBTransitionCell("##MLEPBTransitionPos");
    if (posCellVisible) {
        bool oldPodium = PushPodiumTextColor(PBMonitor::PBTransitionOldRank);
        UI::Text(FormatPBTransitionRank(
            PBMonitor::PBTransitionOldRank,
            PBMonitor::PBTransitionOldTotal,
            showTotal
        ));
        if (oldPodium) UI::PopStyleColor();

        UI::Text(FormatPBPlacementChange());

        bool newPodium = PushPodiumTextColor(PBMonitor::PBTransitionNewRank);
        UI::Text(FormatPBTransitionRank(
            PBMonitor::PBTransitionNewRank,
            PBMonitor::PBTransitionNewTotal,
            showTotal
        ));
        if (newPodium) UI::PopStyleColor();
    }
    EndPBTransitionCell();

    UI::TableNextColumn();
    bool playerCellVisible = BeginPBTransitionCell("##MLEPBTransitionPlayer");
    if (playerCellVisible) {
        RenderPBTransitionPlayerIdentity(record, PBMonitor::PBTransitionOldWasProvisional);
        UI::Text(
            PBMonitor::PBTransitionOldRank == 0
                ? "First MLE Time"
                : "PB Improvement"
        );
        RenderPBTransitionPlayerIdentity(record, true);
    }
    EndPBTransitionCell();

    UI::TableNextColumn();
    bool timeCellVisible = BeginPBTransitionCell("##MLEPBTransitionTime");
    if (timeCellVisible) {
        UI::Text(
            PBMonitor::PBTransitionOldTime > 0
                ? FormatRaceTime(PBMonitor::PBTransitionOldTime)
                : "-:--.---"
        );
        UI::Text(FormatPBTimeDelta(
            PBMonitor::PBTransitionOldTime,
            PBMonitor::PBTransitionNewTime
        ));
        UI::Text(FormatRaceTime(PBMonitor::PBTransitionNewTime));
    }
    EndPBTransitionCell();
}

void RenderLeaderboardRow(MapLeaderboard@ leaderboard, uint rank, LeaderboardRecord@ record, bool isLocalPlayer, bool showTotal) {
    if (isLocalPlayer && PBMonitor::IsPBTransitionActive()) {
        RenderPBTransitionRow(record, showTotal);
        return;
    }

    UI::TableNextRow();

    UI::TableNextColumn();

    vec2 rowWindowPos = UI::GetWindowPos();
    vec2 rowCursorPos = UI::GetCursorPos();
    vec2 ghostTabAnchor = vec2(
        rowWindowPos.x,
        rowWindowPos.y + rowCursorPos.y - UI::GetScrollY()
    );
    bool rowHovered = false;

    bool hasPodiumColor = PushPodiumTextColor(rank);

    if (showTotal) {
        UI::Text(Text::Format("%d", rank) + "/" + Text::Format("%d", leaderboard.records.Length));
    } else {
        UI::Text(Text::Format("%d", rank));
    }
    rowHovered = rowHovered || UI::IsItemHovered();

    if (hasPodiumColor) {
        UI::PopStyleColor();
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
        bool clubHovered = UI::IsItemHovered();
        rowHovered = rowHovered || clubHovered;
        if (clubHovered) {
            RenderClubHoverTooltip(leaderboard, record);
        }
        UI::SameLine();
    }

    string playerLabel = record.mleName;
    if (isLocalPlayer) playerLabel += "  (You)";
    if (record.provisional) playerLabel += "  *";
    UI::Text(playerLabel);

    bool playerHovered = UI::IsItemHovered();
    rowHovered = rowHovered || playerHovered;

    if (!record.provisional && record.replayUrl.Length > 0) {
        if (playerHovered) {
            UI::SetTooltip(ReplayViewer::Loading ? "Loading replay..." : "Click to load replay");
        }

        if (UI::IsItemClicked()) {
            ReplayViewer::Request(record);
        }
    }

    UI::TableNextColumn();
    UI::Text(FormatRaceTime(record.timeMs));

    bool timeHovered = UI::IsItemHovered();
    rowHovered = rowHovered || timeHovered;

    if (record.provisional && timeHovered) {
        UI::SetTooltip("Local PB - awaiting backend confirmation");
    } else if (record.recordSetAt.Length > 0 && timeHovered) {
        UI::SetTooltip("Set: " + record.recordSetAt);
    }

    GhostTabUI::Render(record, ghostTabAnchor, rowHovered);
}
