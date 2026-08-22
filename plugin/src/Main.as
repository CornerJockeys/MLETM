void Main() {
    trace("MLE TM plugin loaded.");

    if (!PlayerDirectory::Initialize()) {
        error("MLE TM: player directory failed to initialize.");
        return;
    }

    startnew(IdentifyLocalPlayer);
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
