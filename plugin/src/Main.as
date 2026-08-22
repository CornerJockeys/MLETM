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

    // Wait until Trackmania exposes the local user.
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
                trace("Roster Slot: " + player.rosterSlot);
                return;
            }
        }

        sleep(250);
    }
}

void IdentifyCurrentMap() {
    auto app = cast<CGameManiaPlanet>(GetApp());

    // Wait until a map is loaded and Trackmania exposes its UID.
    while (true) {
        if (app.RootMap !is null && app.RootMap.MapInfo !is null) {
            string mapUid = app.RootMap.MapInfo.MapUid;
            if (mapUid.Length > 0) {
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
                return;
            }
        }

        sleep(250);
    }
}
