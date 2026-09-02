namespace RecordsDataSource {
    bool RefreshRunning = false;
    string LastAppliedKey = "";
    string LastRequestedKey = "";
    uint LastAttemptAt = 0;
    string PendingMapUid = "";
    string PendingDivision = "";
    string Status = "Simulation records";

    const uint RetryDelayMs = 30000;
    const uint NadeoAuthTimeoutMs = 10000;

    string CurrentMapUid() {
        auto app = cast<CTrackMania>(GetApp());
        if (app is null || app.RootMap is null || app.RootMap.MapInfo is null) return "";
        return app.RootMap.MapInfo.MapUid;
    }

    string CurrentKey(const string &in mapUid, const string &in division) {
        return mapUid + "|" + division;
    }

#if DEPENDENCY_NADEOSERVICES
    uint FetchWorldRecord(const string &in mapUid) {
        try {
            NadeoServices::AddAudience("NadeoLiveServices");
            uint authStarted = Time::Now;
            while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
                if (Time::Now - authStarted >= NadeoAuthTimeoutMs) {
                    warn("MLE TM PROD Nadeo WR auth timed out.");
                    return 0;
                }
                sleep(100);
            }

            string url = NadeoServices::BaseURLLive()
                + "/api/token/leaderboard/group/Personal_Best/map/"
                + mapUid
                + "/top?length=1&onlyWorld=true&offset=0";

            auto req = NadeoServices::Get("NadeoLiveServices", url);
            req.Start();
            while (!req.Finished()) yield();

            if (req.ResponseCode() != 200) {
                warn("MLE TM PROD world WR lookup failed: HTTP " + tostring(req.ResponseCode()));
                return 0;
            }

            auto root = req.Json();
            if (root.GetType() != Json::Type::Object || !root.HasKey("tops")) return 0;
            auto tops = root["tops"];
            if (tops.GetType() != Json::Type::Array || tops.Length == 0) return 0;
            if (!tops[0].HasKey("top") || tops[0]["top"].GetType() != Json::Type::Array || tops[0]["top"].Length == 0) return 0;
            if (!tops[0]["top"][0].HasKey("score")) return 0;

            return uint(tops[0]["top"][0]["score"]);
        } catch {
            warn("MLE TM PROD world WR lookup threw: " + getExceptionInfo());
            return 0;
        }
    }
#else
    uint FetchWorldRecord(const string &in mapUid) {
        return 0;
    }
#endif

    void RefreshAsync() {
        string mapUid = PendingMapUid;
        string division = PendingDivision;
        string key = CurrentKey(mapUid, division);

        uint worldTime = FetchWorldRecord(mapUid);
        auto divisionRecord = ProdApiClient::GetFastestDivisionRecord(mapUid, division);
        uint divisionTime = divisionRecord is null ? 0 : divisionRecord.timeMs;

        // Do not apply stale results after a map/division change.
        string currentMapUid = CurrentMapUid();
        string currentDivision = RecordsState::DivisionCode(MatchState::Division);
        if (currentMapUid == mapUid && currentDivision == division && S_UseLiveRecords) {
            string sourceStatus;
            if (worldTime > 0 && divisionTime > 0) {
                sourceStatus = "Live: Nadeo world WR + MLE " + division + " WR";
            } else if (worldTime > 0) {
                sourceStatus = "Partial: Nadeo world WR; MLE " + division + " WR unavailable";
            } else if (divisionTime > 0) {
                sourceStatus = "Partial: MLE " + division + " WR; Nadeo world WR unavailable";
            } else {
                sourceStatus = "Live record sources unavailable";
            }

            RecordsState::ApplyLive(worldTime, divisionTime, sourceStatus);
            Status = sourceStatus;
            LastAppliedKey = key;
        }

        RefreshRunning = false;
    }

    bool RetryDue(const string &in key) {
        if (key != LastRequestedKey) return true;
        if (LastAttemptAt == 0) return true;
        return Time::Now - LastAttemptAt >= RetryDelayMs;
    }

    void RequestRefresh(const string &in mapUid, const string &in division) {
        if (RefreshRunning || mapUid.Length == 0 || division.Length == 0) return;

        string key = CurrentKey(mapUid, division);
        if (!RetryDue(key)) return;

        PendingMapUid = mapUid;
        PendingDivision = division;
        LastRequestedKey = key;
        LastAttemptAt = Time::Now;
        RefreshRunning = true;
        Status = "Loading live record data...";
        startnew(RefreshAsync);
    }

    void ForceRefresh() {
        LastRequestedKey = "";
        LastAttemptAt = 0;
        LastAppliedKey = "";
    }

    void Update() {
        if (!S_UseLiveRecords) {
            if (RecordsState::LiveDataActive) RecordsState::SyncFromSettings();
            Status = "Simulation records";
            return;
        }

        string mapUid = CurrentMapUid();
        string division = RecordsState::DivisionCode(MatchState::Division);
        if (mapUid.Length == 0) {
            Status = "Live records waiting for a loaded map";
            return;
        }

        string key = CurrentKey(mapUid, division);
        if (key == LastAppliedKey) return;
        RequestRefresh(mapUid, division);
    }
}
