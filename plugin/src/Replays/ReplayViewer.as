namespace ReplayViewer {
    bool Loading = false;
    bool Viewing = false;
    string PendingReplayUrl = "";
    string PendingPlayerName = "";
    string ViewingPlayerName = "";

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

    CGameScriptMapSpawn@ GetDefaultMapSpawn(CSmArenaRulesMode@ playgroundScript) {
        bool spawnIsMultilap = false;
        CGameScriptMapSpawn@ spawn;

        for (uint i = 0; i < playgroundScript.MapLandmarks.Length; i++) {
            auto landmark = playgroundScript.MapLandmarks[i];
            bool isMultilap = landmark.Tag == "StartFinish";

            if (!(landmark.Tag == "Spawn" || isMultilap)) continue;

            if (isMultilap) {
                if (landmark.PlayerSpawn !is null
                    && landmark.Waypoint !is null
                    && landmark.Waypoint.IsMultiLap) {
                    spawnIsMultilap = true;
                    @spawn = landmark.PlayerSpawn;
                }
            } else if (spawn is null || spawnIsMultilap) {
                spawnIsMultilap = false;
                @spawn = landmark.PlayerSpawn;
            }
        }

        return spawn;
    }

    void Exit() {
        auto app = cast<CTrackMania>(GetApp());
        auto playgroundScript = app is null
            ? null
            : cast<CSmArenaRulesMode>(app.PlaygroundScript);
        auto currentPlayground = app is null
            ? null
            : cast<CSmArenaClient>(app.CurrentPlayground);

        if (playgroundScript is null
            || currentPlayground is null
            || currentPlayground.Players.Length == 0
            || playgroundScript.UIManager is null
            || playgroundScript.UIManager.UIAll is null) {
            warn("MLE TM replay viewer: unable to restore the local player.");
            Notify("Could not exit replay cleanly in this session.");
            return;
        }

        auto localPlayer = cast<CSmPlayer>(currentPlayground.Players[0]);
        if (localPlayer is null || localPlayer.ScriptAPI is null) {
            warn("MLE TM replay viewer: local player was unavailable during replay exit.");
            Notify("Could not restore the local player.");
            return;
        }

        playgroundScript.Ghosts_SetStartTime(-1);
        playgroundScript.UIManager.UIAll.UISequence = CGamePlaygroundUIConfig::EUISequence::Playing;
        playgroundScript.UIManager.UIAll.ForceSpectator = false;
        playgroundScript.UIManager.UIAll.SpectatorForceCameraType = 15;
        playgroundScript.UIManager.UIAll.Spectator_SetForcedTarget_Clear();

        auto spawn = GetDefaultMapSpawn(playgroundScript);
        if (spawn !is null) {
            playgroundScript.SpawnPlayer(
                cast<CSmScriptPlayer>(localPlayer.ScriptAPI),
                0,
                0,
                spawn,
                playgroundScript.Now
            );
        } else {
            playgroundScript.RespawnPlayer(cast<CSmScriptPlayer>(localPlayer.ScriptAPI));
        }

        if (HasLoadedGhost
            && LoadedMapUid == RuntimeState::MapUid
            && playgroundScript.GhostMgr !is null) {
            playgroundScript.GhostMgr.Ghost_Remove(LoadedGhostInstance);
        }

        HasLoadedGhost = false;
        Viewing = false;
        ViewingPlayerName = "";

        trace("MLE TM replay viewer: returned to driving.");
        Notify("Returned to driving.");
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

        Viewing = true;
        ViewingPlayerName = playerName;

        trace("MLE TM replay viewer: spectating replay for " + playerName + ".");
        Notify("Viewing replay for " + playerName + ".");
        Loading = false;
    }
}
