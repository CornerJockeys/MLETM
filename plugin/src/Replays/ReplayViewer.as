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
            || playgroundScript.GhostMgr is null
            || playgroundScript.UIManager is null
            || playgroundScript.UIManager.UIAll is null) {
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

        // Ghost playback uses the mode's shared ghost clock. If the map has already
        // been running longer than the replay, a newly-added ghost can already be
        // "finished" and therefore invisible. Restart that clock before spectating.
        playgroundScript.Ghosts_SetStartTime(playgroundScript.Now);

        auto currentPlayground = cast<CSmArenaClient>(app.CurrentPlayground);
        if (currentPlayground !is null && currentPlayground.Players.Length > 0) {
            auto localPlayer = cast<CSmPlayer>(currentPlayground.Players[0]);
            if (localPlayer !is null && localPlayer.ScriptAPI !is null) {
                playgroundScript.UnspawnPlayer(cast<CSmScriptPlayer>(localPlayer.ScriptAPI));
            }
        }

        playgroundScript.UIManager.UIAll.ForceSpectator = true;
        playgroundScript.UIManager.UIAll.SpectatorForceCameraType = 3;
        playgroundScript.UIManager.UIAll.Spectator_SetForcedTarget_Ghost(LoadedGhostInstance);

        trace("MLE TM replay viewer: spectating replay for " + playerName + ".");
        Notify("Viewing replay for " + playerName + ".");
        Loading = false;
    }
}
