[Setting category="MLE TM - Ghost Test" name="Enable top two leaderboard ghosts (temporary)"]
bool S_TestTopTwoLeaderboardGhosts = false;

namespace GhostToggle {
    class ActiveGhost {
        string accountId;
        string playerName;
        string mapUid;
        MwId instanceId;

        ActiveGhost(
            const string &in accountId,
            const string &in playerName,
            const string &in mapUid,
            const MwId &in instanceId
        ) {
            this.accountId = accountId;
            this.playerName = playerName;
            this.mapUid = mapUid;
            this.instanceId = instanceId;
        }
    }

    array<ActiveGhost@> ActiveGhosts;
    array<string> LoadingAccountIds;
    array<string> TestAccountIds;

    string TrackedMapUid = "";
    bool LastTestSetting = false;

    void Notify(const string &in message) {
        UI::ShowNotification("MLE TM", message);
    }

    int FindActiveIndex(const string &in accountId) {
        for (uint i = 0; i < ActiveGhosts.Length; i++) {
            if (ActiveGhosts[i].accountId == accountId) return int(i);
        }
        return -1;
    }

    int FindLoadingIndex(const string &in accountId) {
        for (uint i = 0; i < LoadingAccountIds.Length; i++) {
            if (LoadingAccountIds[i] == accountId) return int(i);
        }
        return -1;
    }

    bool IsActive(const string &in accountId) {
        return FindActiveIndex(accountId) >= 0;
    }

    bool IsActive(LeaderboardRecord@ record) {
        return record !is null && IsActive(record.accountId);
    }

    bool IsLoading(const string &in accountId) {
        return FindLoadingIndex(accountId) >= 0;
    }

    bool IsLoading(LeaderboardRecord@ record) {
        return record !is null && IsLoading(record.accountId);
    }

    uint ActiveCount() {
        return ActiveGhosts.Length;
    }

    void RemoveLoadingMarker(const string &in accountId) {
        int index = FindLoadingIndex(accountId);
        if (index >= 0) {
            LoadingAccountIds.RemoveAt(uint(index));
        }
    }

    void ClearTrackingOnly() {
        ActiveGhosts.RemoveRange(0, ActiveGhosts.Length);
        LoadingAccountIds.RemoveRange(0, LoadingAccountIds.Length);
        TestAccountIds.RemoveRange(0, TestAccountIds.Length);
    }

    void EnsureMapState() {
        string currentMapUid = RuntimeState::MapUid;
        if (currentMapUid == TrackedMapUid) return;

        // Trackmania destroys the old map's ghost manager when the map changes, so
        // there is nothing useful to remove from it here. Just discard our stale IDs.
        ClearTrackingOnly();
        TrackedMapUid = currentMapUid;
        LastTestSetting = false;

        if (TrackedMapUid.Length > 0) {
            trace("MLE TM ghost toggle state reset for map: " + TrackedMapUid);
        }
    }

    bool CanUseGhost(LeaderboardRecord@ record, bool notifyFailure = true) {
        if (!GhostPlusPlus::IsAvailable()) {
            if (notifyFailure) Notify("Ghost++ is required for leaderboard ghost controls.");
            return false;
        }

        if (record is null || record.provisional || record.replayUrl.Length == 0) {
            if (notifyFailure) Notify("No ghost is available for this record.");
            return false;
        }

        if (!Permissions::PlayRecords()) {
            if (notifyFailure) Notify("Trackmania does not currently allow record ghosts for this account.");
            return false;
        }

        if (ReplayViewer::Loading || ReplayViewer::Viewing || ReplayViewer::Exiting) {
            if (notifyFailure) Notify("Exit replay viewing before changing driving ghosts.");
            return false;
        }

        return true;
    }

    void Toggle(LeaderboardRecord@ record) {
        EnsureMapState();
        if (!CanUseGhost(record)) return;

        if (IsActive(record)) {
            Remove(record.accountId);
            return;
        }

        if (IsLoading(record)) {
            RemoveLoadingMarker(record.accountId);
            Notify("Cancelled ghost load for " + record.mleName + ".");
            return;
        }

        Add(record);
    }

    void Add(LeaderboardRecord@ record) {
        EnsureMapState();
        if (!CanUseGhost(record)) return;
        if (IsActive(record) || IsLoading(record)) return;

        string mapUid = RuntimeState::MapUid;
        if (mapUid.Length == 0) {
            Notify("No active map is available for ghost loading.");
            return;
        }

        LoadingAccountIds.InsertLast(record.accountId);

        trace("MLE TM ghost loading: " + record.mleName);
        startnew(
            LoadGhost,
            array<string> = {
                record.accountId,
                record.mleName,
                mapUid,
                record.replayUrl
            }
        );
    }

    void LoadGhost(ref@ data) {
        auto args = cast<array<string>>(data);
        if (args is null || args.Length < 4) return;

        string accountId = args[0];
        string playerName = args[1];
        string mapUid = args[2];
        string replayUrl = args[3];

        auto app = cast<CTrackMania>(GetApp());
        auto playgroundScript = app is null
            ? null
            : cast<CSmArenaRulesMode>(app.PlaygroundScript);

        if (playgroundScript is null
            || playgroundScript.DataFileMgr is null
            || playgroundScript.GhostMgr is null) {
            RemoveLoadingMarker(accountId);
            Notify("Ghost loading is not available in this session.");
            return;
        }

        auto dataFileMgr = playgroundScript.DataFileMgr;
        auto task = dataFileMgr.Ghost_Download("", replayUrl);

        while (task.IsProcessing) {
            yield();
        }

        if (task.HasFailed || !task.HasSucceeded || task.Ghost is null) {
            dataFileMgr.TaskResult_Release(task.Id);
            RemoveLoadingMarker(accountId);
            warn("MLE TM ghost download failed for " + playerName + ".");
            Notify("Ghost download failed for " + playerName + ".");
            return;
        }

        // The user may have cancelled this ghost or changed maps while it downloaded.
        // Never add a completed request into a different map/session.
        if (!IsLoading(accountId) || RuntimeState::MapUid != mapUid) {
            dataFileMgr.TaskResult_Release(task.Id);
            RemoveLoadingMarker(accountId);
            return;
        }

        auto refreshedApp = cast<CTrackMania>(GetApp());
        @playgroundScript = refreshedApp is null
            ? null
            : cast<CSmArenaRulesMode>(refreshedApp.PlaygroundScript);

        if (playgroundScript is null || playgroundScript.GhostMgr is null) {
            dataFileMgr.TaskResult_Release(task.Id);
            RemoveLoadingMarker(accountId);
            return;
        }

        // This mirrors Ghost++'s own multi-ghost loading path: download the ghost and
        // add it to the current ghost manager without forcing spectator mode or
        // resetting the global ghost timeline. Ghost++ intercepts Ghost_Add itself.
        MwId instanceId = playgroundScript.GhostMgr.Ghost_Add(task.Ghost, true);
        dataFileMgr.TaskResult_Release(task.Id);
        RemoveLoadingMarker(accountId);

        ActiveGhosts.InsertLast(ActiveGhost(
            accountId,
            playerName,
            mapUid,
            instanceId
        ));

        trace(
            "MLE TM ghost active: "
            + playerName
            + " | active ghosts: "
            + Text::Format("%d", ActiveGhosts.Length)
        );
        Notify("Ghost enabled: " + playerName + ".");
    }

    void Remove(const string &in accountId) {
        EnsureMapState();

        int loadingIndex = FindLoadingIndex(accountId);
        if (loadingIndex >= 0) {
            LoadingAccountIds.RemoveAt(uint(loadingIndex));
        }

        int activeIndex = FindActiveIndex(accountId);
        if (activeIndex < 0) return;

        auto entry = ActiveGhosts[uint(activeIndex)];

        auto app = cast<CTrackMania>(GetApp());
        auto playgroundScript = app is null
            ? null
            : cast<CSmArenaRulesMode>(app.PlaygroundScript);

        if (entry.mapUid == RuntimeState::MapUid
            && playgroundScript !is null
            && playgroundScript.GhostMgr !is null) {
            playgroundScript.GhostMgr.Ghost_Remove(entry.instanceId);
        }

        string playerName = entry.playerName;
        ActiveGhosts.RemoveAt(uint(activeIndex));

        trace(
            "MLE TM ghost removed: "
            + playerName
            + " | active ghosts: "
            + Text::Format("%d", ActiveGhosts.Length)
        );
        Notify("Ghost disabled: " + playerName + ".");
    }

    LeaderboardRecord@ GetAvailableRecordAt(uint availableIndex) {
        auto leaderboard = RuntimeState::CurrentLeaderboard;
        if (leaderboard is null) return null;

        uint found = 0;
        for (uint i = 0; i < leaderboard.records.Length; i++) {
            auto record = leaderboard.records[i];
            if (!CanUseGhost(record, false)) continue;

            if (found == availableIndex) return record;
            found++;
        }

        return null;
    }

    void StartTopTwoTest() {
        TestAccountIds.RemoveRange(0, TestAccountIds.Length);

        for (uint slot = 0; slot < 2; slot++) {
            auto record = GetAvailableRecordAt(slot);
            if (record is null) continue;

            TestAccountIds.InsertLast(record.accountId);
            Add(record);
        }

        if (TestAccountIds.Length == 0) {
            Notify("No leaderboard ghosts are available for the test.");
            return;
        }

        trace("MLE TM multi-ghost test requested for " + Text::Format("%d", TestAccountIds.Length) + " ghost(s).");
    }

    void StopTopTwoTest() {
        array<string> accounts;
        for (uint i = 0; i < TestAccountIds.Length; i++) {
            accounts.InsertLast(TestAccountIds[i]);
        }
        TestAccountIds.RemoveRange(0, TestAccountIds.Length);

        for (uint i = 0; i < accounts.Length; i++) {
            Remove(accounts[i]);
        }
    }

    void MonitorLoop() {
        while (true) {
            EnsureMapState();

            if (S_TestTopTwoLeaderboardGhosts != LastTestSetting) {
                LastTestSetting = S_TestTopTwoLeaderboardGhosts;

                if (S_TestTopTwoLeaderboardGhosts) {
                    StartTopTwoTest();
                } else {
                    StopTopTwoTest();
                }
            }

            sleep(200);
        }
    }
}
