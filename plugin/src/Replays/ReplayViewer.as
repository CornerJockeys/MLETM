namespace ReplayViewer {
    bool Loading = false;
    bool Viewing = false;
    bool Exiting = false;

    string PendingReplayUrl = "";
    string PendingPlayerName = "";
    string PendingAccountId = "";
    string ViewingPlayerName = "";
    string ViewingAccountId = "";

    bool HasLoadedGhost = false;
    MwId LoadedGhostInstance;
    string LoadedMapUid = "";

    void Notify(const string &in message) {
        UI::ShowNotification("MLE TM", message);
    }

    bool IsReplayAvailable(LeaderboardRecord@ record) {
        return record !is null
            && !record.provisional
            && record.replayUrl.Length > 0;
    }

    bool IsLoadingRecord(LeaderboardRecord@ record) {
        return record !is null
            && Loading
            && PendingAccountId == record.accountId;
    }

    bool IsWatchingRecord(LeaderboardRecord@ record) {
        if (record is null
            || !Viewing
            || !HasLoadedGhost
            || LoadedMapUid != RuntimeState::MapUid
            || ViewingAccountId != record.accountId) {
            return false;
        }

        // With Ghosts++ available, verify Trackmania is actually targeting the exact
        // ghost instance MLE TM loaded. This avoids treating an unrelated PB/background
        // ghost or other spectator state as this leaderboard replay being watched.
        if (GhostPlusPlus::IsAvailable()) {
            return GhostPlusPlus::IsWatchingGhostInstance(LoadedGhostInstance);
        }

        // Built-in fallback: before Ghosts++ integration we already own the complete
        // replay lifecycle, so our Viewing/account state remains authoritative.
        return true;
    }

    void Request(LeaderboardRecord@ record) {
        if (record is null) return;

        if (!IsReplayAvailable(record)) {
            Notify("No replay is available for this record.");
            return;
        }

        if (Loading || Exiting) {
            Notify("Replay state is currently changing.");
            return;
        }

        if (!Permissions::PlayRecords()) {
            Notify("Trackmania does not currently allow replay playback for this account.");
            return;
        }

        PendingReplayUrl = record.replayUrl;
        PendingPlayerName = record.mleName;
        PendingAccountId = record.accountId;
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

    void RequestExit() {
        if (!Viewing || Exiting) return;
        startnew(Exit);
    }

    void Exit() {
        if (Exiting) return;
        Exiting = true;

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
            Exiting = false;
            return;
        }

        auto localPlayer = cast<CSmPlayer>(currentPlayground.Players[0]);
        if (localPlayer is null || localPlayer.ScriptAPI is null) {
            warn("MLE TM replay viewer: local player was unavailable during replay exit.");
            Notify("Could not restore the local player.");
            Exiting = false;
            return;
        }

        auto scriptPlayer = cast<CSmScriptPlayer>(localPlayer.ScriptAPI);

        // Tell Trackmania's own race script that record spectating has ended. This is
        // the piece that manual ForceSpectator changes do not fully restore by themselves.
        MLHook::Queue_PG_SendCustomEvent("TMGame_Record_Spectate", {""});

        // Give the native event queue a frame to restore its own spectator/race state.
        yield();
        yield();

        playgroundScript.Ghosts_SetStartTime(-1);
        playgroundScript.UIManager.UIAll.UISequence = CGamePlaygroundUIConfig::EUISequence::Playing;
        playgroundScript.UIManager.UIAll.ForceSpectator = false;
        playgroundScript.UIManager.UIAll.SpectatorForceCameraType = 15;
        playgroundScript.UIManager.UIAll.Spectator_SetForcedTarget_Clear();

        auto spawn = GetDefaultMapSpawn(playgroundScript);
        if (spawn !is null) {
            playgroundScript.SpawnPlayer(
                scriptPlayer,
                0,
                0,
                spawn,
                playgroundScript.Now
            );

            // SpawnPlayer gets the car back into the mode; a following RespawnPlayer
            // makes the return equivalent to a normal player-triggered respawn.
            yield();
            playgroundScript.RespawnPlayer(scriptPlayer);
        } else {
            playgroundScript.RespawnPlayer(scriptPlayer);
        }

        if (HasLoadedGhost
            && LoadedMapUid == RuntimeState::MapUid
            && playgroundScript.GhostMgr !is null) {
            playgroundScript.GhostMgr.Ghost_Remove(LoadedGhostInstance);
        }

        HasLoadedGhost = false;
        Viewing = false;
        ViewingPlayerName = "";
        ViewingAccountId = "";
        Exiting = false;

        trace("MLE TM replay viewer: returned to driving.");
        Notify("Returned to driving.");
    }

    void LoadPendingReplay() {
        string replayUrl = PendingReplayUrl;
        string playerName = PendingPlayerName;
        string accountId = PendingAccountId;

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
        ViewingAccountId = accountId;

        trace("MLE TM replay viewer: spectating replay for " + playerName + ".");
        Notify("Viewing replay for " + playerName + ".");
        Loading = false;
    }
}
