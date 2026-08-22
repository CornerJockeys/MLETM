void Main() {
    trace("MLE TM plugin loaded.");

    if (!PlayerDirectory::Initialize()) {
        error("MLE TM: player directory failed to initialize.");
        return;
    }

    if (!MapDirectory::Initialize()) {
        error("MLE TM: map directory failed to initialize.");
        return;
    }

    startnew(IdentifyLocalPlayer);
    startnew(IdentifyCurrentMap);
}

void IdentifyLocalPlayer() {
    auto app = cast<CGameManiaPlanet>(GetApp());

    while (true) {
        auto cmap = app.Network.ClientManiaAppPlayground;
        if (cmap !is null && cmap.LocalUser !is null) {
            string accountId = cmap.LocalUser.WebServicesUserId;
            if (accountId.Length > 0) {
                trace("MLE TM local TM Account ID: " + accountId);

                auto player = PlayerDirectory::Get(accountId);
                if (player is null) {
                    warn("MLE TM: local player is not present in the MLE player directory.");
                    return;
                }

                trace("MLE player identified: " + player.mleName);
                trace("Team: " + player.team);
                trace("League: " + player.league);
                trace("Division: " + player.division);
                trace("Roster Slot: " + player.rosterSlot);
                return;
            }
        }

        sleep(250);
    }
}

void IdentifyCurrentMap() {
    auto app = cast<CGameManiaPlanet>(GetApp());

    while (true) {
        auto cmap = app.Network.ClientManiaAppPlayground;
        if (app.RootMap !is null && app.RootMap.MapInfo !is null && cmap !is null && cmap.LocalUser !is null) {
            string mapUid = app.RootMap.MapInfo.MapUid;
            string accountId = cmap.LocalUser.WebServicesUserId;

            if (mapUid.Length > 0 && accountId.Length > 0) {
                trace("MLE TM current Map UID: " + mapUid);

                auto mapInfo = MapDirectory::Get(mapUid);
                if (mapInfo is null) {
                    warn("MLE TM: current map is not present in the MLE map directory.");
                    return;
                }

                trace("MLE map identified: " + mapInfo.name);
                trace("Map ID: " + mapInfo.mapId);
                trace("Map UID: " + mapInfo.mapUid);
                trace("Division group(s): " + string::Join(mapInfo.groups, ", "));

                auto player = PlayerDirectory::Get(accountId);
                if (player is null) {
                    warn("MLE TM: cannot select leaderboard because local player is not in the player directory.");
                    return;
                }

                LogLeaderboard(mapInfo, player);
                return;
            }
        }

        sleep(250);
    }
}

void LogLeaderboard(MLEMapInfo@ mapInfo, PlayerInfo@ player) {
    auto leaderboard = mapInfo.GetLeaderboard(player.division);
    if (leaderboard is null) {
        warn("MLE TM: no " + player.division + " leaderboard is available for " + mapInfo.name);
        return;
    }

    trace("MLE leaderboard: " + mapInfo.name + " [" + leaderboard.division + "]");

    uint topCount = Math::Min(uint(10), leaderboard.records.Length);
    uint playerRank = 0;
    LeaderboardRecord@ playerRecord = null;

    for (uint i = 0; i < leaderboard.records.Length; i++) {
        auto record = leaderboard.records[i];

        if (i < topCount) {
            trace(Text::Format("%d. %s %s", i + 1, record.mleName, FormatRaceTime(record.timeMs)));
        }

        if (record.accountId == player.accountId) {
            playerRank = i + 1;
            @playerRecord = record;
        }
    }

    if (playerRecord !is null) {
        trace(Text::Format("Your position: %d / %d - %s %s", playerRank, leaderboard.records.Length, playerRecord.mleName, FormatRaceTime(playerRecord.timeMs)));
    } else {
        trace("Your position: no record in this leaderboard snapshot.");
    }
}

string FormatRaceTime(uint timeMs) {
    uint minutes = timeMs / 60000;
    uint seconds = (timeMs % 60000) / 1000;
    uint millis = timeMs % 1000;
    return Text::Format("%d:%02d.%03d", minutes, seconds, millis);
}
