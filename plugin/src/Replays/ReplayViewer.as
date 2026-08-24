namespace ReplayViewer {
    bool Loading = false;
    string PendingReplayUrl = "";
    string PendingPlayerName = "";

    bool HasLoadedGhost = false;
    MwId LoadedGhostInstance;
    string LoadedMapUid = "";

    void Notify(const string &in message) {
        UI::ShowNotification("MLE TM", message);
    }

    void Request(LeaderboardRecord@ record) {
        if (record is null) return;

        if (record.provisional || record.replayUrl.Length == 0) {
            Notify("No replay is available for this record.");
            return;
        }

        if (Loading) {
            Notify("A replay is already loading.");
            return;
        }

        if (!Permissions::PlayRecords()) {
            Notify("Trackmania does not currently allow replay playback for this account.");
            return;
        }

        PendingReplayUrl = record.replayUrl;
        PendingPlayerName = record.mleName;
        Loading = true;
        startnew(LoadPendingReplay);
    }

    void LoadPendingReplay() {
        string replayUrl = PendingReplayUrl;
        string playerName = PendingPlayerName;

        auto app = cast<CTrackMania>(GetApp());
        auto playgroundScript = app is null
            ? null
            : cast<CSmArenaRulesMode>(app.PlaygroundScript);

        if (playgroundScript is null
            || playgroundScript.DataFileMgr is null
            || playgroundScript.GhostMgr is null) {
            warn("MLE TM replay loader: playground ghost services are unavailable.");
            Notify("Replay viewing is not available in this session.");
            Loading = false;
            return;
        }

        auto dataFileMgr = playgroundScript.DataFileMgr;
        auto ghostMgr = playgroundScript.GhostMgr;
        auto task = dataFileMgr.Ghost_Download("", replayUrl);

        while (task.IsProcessing) {
            yield();
        }

        if (task.HasFailed || !task.HasSucceeded || task.Ghost is null) {
            warn("MLE TM replay loader: replay download failed for " + playerName + ".");
            dataFileMgr.TaskResult_Release(task.Id);
            Notify("Replay download failed for " + playerName + ".");
            Loading = false;
            return;
        }

        if (HasLoadedGhost && LoadedMapUid == RuntimeState::MapUid) {
            ghostMgr.Ghost_Remove(LoadedGhostInstance);
        }

        LoadedGhostInstance = ghostMgr.Ghost_Add(task.Ghost, true);
        HasLoadedGhost = true;
        LoadedMapUid = RuntimeState::MapUid;

        dataFileMgr.TaskResult_Release(task.Id);

        trace("MLE TM replay loader: loaded replay for " + playerName + ".");
        Notify("Loaded replay for " + playerName + ".");
        Loading = false;
    }
}
