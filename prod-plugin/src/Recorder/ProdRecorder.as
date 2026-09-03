#if DEPENDENCY_MLFEEDRACEDATA && DEPENDENCY_MLHOOK

class ProdTelemetrySample {
    int raceTimeMs;
    float speedKph;
    vec3 position;

    ProdTelemetrySample(int raceTimeMs, float speedKph, const vec3 &in position) {
        this.raceTimeMs = raceTimeMs;
        this.speedKph = speedKph;
        this.position = position;
    }

    Json::Value@ ToJson() const {
        auto row = Json::Array();
        row.Add(raceTimeMs);
        row.Add(speedKph);
        row.Add(position.x);
        row.Add(position.y);
        row.Add(position.z);
        return row;
    }
}

class ProdRecorderPlayerCache {
    string accountId;
    string login;
    string name;
    int teamNum = -1;
    uint startTime = 0;

    bool frozen = false;
    bool finished = false;
    bool dnf = false;
    bool disappeared = false;
    bool teamChangedDuringRound = false;
    uint disappearedAtMs = 0;

    int finishPosition = -1;
    int finishTimeMs = -1;
    int roundPoints = 0;
    int totalPoints = 0;
    int raceRank = 0;
    int raceRespawnRank = 0;
    int theoreticalRaceTimeMs = -1;
    int totalRespawnLossMs = 0;
    float latencyEstimateMs = 0.0f;

    array<int> cpTimesMs;
    array<int> respawnTimesMs;
    array<int> respawnsByCp;
    array<int> respawnLossByCpMs;
    uint respawnCount = 0;

    int lastObservedCpCount = 0;
    uint lastObservedRespawnCount = 0;
    uint lastSeenAtMs = 0;
    uint lastTelemetrySampleAtMs = 0;
    bool telemetryEverAvailable = false;
    array<ProdTelemetrySample@> telemetry;

    ProdRecorderPlayerCache(const MLFeed::PlayerCpInfo_V4@ player) {
        UpdateIdentity(player);
        teamNum = player.TeamNum;
        startTime = player.StartTime;
        lastObservedCpCount = player.CpCount;
        lastObservedRespawnCount = player.NbRespawnsRequested;
        UpdateFrom(player);
    }

    string StableKey() const {
        if (accountId.Length > 0) return accountId;
        if (login.Length > 0) return login;
        return name;
    }

    void UpdateIdentity(const MLFeed::PlayerCpInfo_V4@ player) {
        if (accountId.Length == 0 && player.WebServicesUserId.Length > 0) accountId = player.WebServicesUserId;
        if (login.Length == 0 && player.Login.Length > 0) login = player.Login;
        if (name.Length == 0 && player.Name.Length > 0) name = player.Name;
    }

    void CopyInts(const array<int>@ source, array<int>@ target) {
        target.Resize(source is null ? 0 : source.Length);
        if (source is null) return;
        for (uint i = 0; i < source.Length; i++) target[i] = source[i];
    }

    void UpdateFrom(const MLFeed::PlayerCpInfo_V4@ player) {
        if (player is null || frozen) return;

        UpdateIdentity(player);
        lastSeenAtMs = Time::Now;
        disappeared = false;
        disappearedAtMs = 0;
        if ((player.TeamNum == 1 || player.TeamNum == 2) && player.TeamNum != teamNum) teamChangedDuringRound = true;

        finished = player.IsFinished;
        dnf = player.Eliminated;
        finishTimeMs = player.IsFinished ? player.FinishTime : finishTimeMs;
        roundPoints = player.RoundPoints;
        totalPoints = player.Points;
        raceRank = int(player.RaceRank);
        raceRespawnRank = int(player.RaceRespawnRank);
        theoreticalRaceTimeMs = player.TheoreticalRaceTime;
        totalRespawnLossMs = int(player.TimeLostToRespawns);
        latencyEstimateMs = player.latencyEstimate;
        respawnCount = player.NbRespawnsRequested;

        CopyInts(player.CpTimes, cpTimesMs);
        CopyInts(player.RespawnTimes, respawnTimesMs);
        CopyInts(player.NbRespawnsByCp, respawnsByCp);
        CopyInts(player.TimeLostToRespawnByCp, respawnLossByCpMs);
    }

    void SampleTelemetry(const MLFeed::PlayerCpInfo_V4@ player) {
        if (player is null || frozen || !S_RecorderCaptureTelemetry) return;
        uint now = Time::Now;
        uint interval = uint(Math::Max(S_RecorderTelemetryIntervalMs, 50));
        if (lastTelemetrySampleAtMs > 0 && now - lastTelemetrySampleAtMs < interval) return;

        auto gamePlayer = player.FindCSmPlayer();
        if (gamePlayer is null || gamePlayer.ScriptAPI is null) return;
        auto scriptPlayer = cast<CSmScriptPlayer>(gamePlayer.ScriptAPI);
        if (scriptPlayer is null) return;

        int raceTime = player.CurrentRaceTime;
        float speedKph = scriptPlayer.Speed * 3.6f;
        telemetry.InsertLast(ProdTelemetrySample(raceTime, speedKph, scriptPlayer.Position));
        lastTelemetrySampleAtMs = now;
        telemetryEverAvailable = true;
    }

    void FreezeFinished(int position) {
        if (frozen) return;
        finished = true;
        dnf = false;
        finishPosition = position;
        if (finishTimeMs < 0 && cpTimesMs.Length > 0) finishTimeMs = cpTimesMs[cpTimesMs.Length - 1];
        frozen = true;
    }

    void FinalizeUnfinished(bool wasDisappeared) {
        if (frozen) return;
        finished = false;
        dnf = true;
        disappeared = disappeared || wasDisappeared;
        frozen = true;
    }

    Json::Value@ IntArrayToJson(const array<int>@ values) const {
        auto j = Json::Array();
        for (uint i = 0; i < values.Length; i++) j.Add(values[i]);
        return j;
    }

    Json::Value@ ToJson() const {
        auto j = Json::Object();
        j["accountId"] = accountId;
        j["login"] = login;
        j["name"] = name;
        j["teamNum"] = teamNum;
        j["startTimeMs"] = int(startTime);

        j["finished"] = finished;
        j["dnf"] = dnf;
        j["disappeared"] = disappeared;
        j["finishPosition"] = finishPosition;
        j["finishTimeMs"] = finishTimeMs;
        j["roundPoints"] = roundPoints;
        j["totalPoints"] = totalPoints;
        j["raceRank"] = raceRank;
        j["raceRespawnRank"] = raceRespawnRank;
        j["theoreticalRaceTimeMs"] = theoreticalRaceTimeMs;
        j["totalRespawnLossMs"] = totalRespawnLossMs;
        j["latencyEstimateMs"] = latencyEstimateMs;
        j["cpTimesMs"] = IntArrayToJson(cpTimesMs);

        auto respawns = Json::Object();
        respawns["count"] = int(respawnCount);
        respawns["timesMs"] = IntArrayToJson(respawnTimesMs);
        respawns["byCp"] = IntArrayToJson(respawnsByCp);
        respawns["timeLossMs"] = totalRespawnLossMs;
        respawns["timeLossByCpMs"] = IntArrayToJson(respawnLossByCpMs);
        j["respawns"] = respawns;

        auto capture = Json::Object();
        capture["frozenAtFinish"] = finished && frozen;
        capture["disappearedBeforeFinalize"] = disappeared;
        capture["teamChangedDuringRound"] = teamChangedDuringRound;
        capture["telemetryAvailable"] = telemetryEverAvailable;
        capture["lastSeenAtMs"] = int(lastSeenAtMs);
        j["capture"] = capture;

        auto telemetryJson = Json::Object();
        telemetryJson["available"] = telemetryEverAvailable;
        telemetryJson["sampleIntervalMs"] = Math::Max(S_RecorderTelemetryIntervalMs, 50);
        auto format = Json::Array();
        format.Add("raceTimeMs");
        format.Add("speedKph");
        format.Add("x");
        format.Add("y");
        format.Add("z");
        telemetryJson["sampleFormat"] = format;
        auto samples = Json::Array();
        for (uint i = 0; i < telemetry.Length; i++) samples.Add(telemetry[i].ToJson());
        telemetryJson["samples"] = samples;
        j["telemetry"] = telemetryJson;

        return j;
    }
}

class ProdRecorderRoundCache {
    string roundKey;
    string serverLogin;
    string serverName;
    string gameMode;
    string mapUid;
    string mapName;

    int mapCpCount = 0;
    int mapCpsToFinish = 0;
    int raceNumber = -1;
    int roundNumberAtOpen = -1;
    int rulesStartMs = -1;
    int rulesEndMs = -1;
    uint openedAtUnix = 0;
    uint finalizedAtUnix = 0;

    int blueScoreBefore = 0;
    int redScoreBefore = 0;
    int blueScoreAfter = 0;
    int redScoreAfter = 0;
    int roundWinningTeam = -1;
    int pointsLimit = -1;
    array<int> pointsRepartition;

    bool resultSeen = false;
    uint resultSeenAtMs = 0;
    bool finalized = false;
    int finishSequence = 0;

    array<ProdRecorderPlayerCache@> players;

    ProdRecorderRoundCache() {}

    ProdRecorderPlayerCache@ FindByIdentity(const string &in accountId, const string &in login, const string &in name) {
        for (uint i = 0; i < players.Length; i++) {
            auto cached = players[i];
            if (accountId.Length > 0 && cached.accountId == accountId) return cached;
            if (login.Length > 0 && cached.login == login) return cached;
            if (name.Length > 0 && cached.name == name) return cached;
        }
        return null;
    }

    ProdRecorderPlayerCache@ Find(const MLFeed::PlayerCpInfo_V4@ player) {
        if (player is null) return null;
        return FindByIdentity(player.WebServicesUserId, player.Login, player.Name);
    }

    Json::Value@ IntArrayToJson(const array<int>@ values) const {
        auto j = Json::Array();
        for (uint i = 0; i < values.Length; i++) j.Add(values[i]);
        return j;
    }

    Json::Value@ ToJson(bool includeTelemetry = true) const {
        auto j = Json::Object();
        j["roundKey"] = roundKey;
        j["raceNumber"] = raceNumber;
        j["roundNumberAtOpen"] = roundNumberAtOpen;
        j["rulesStartMs"] = rulesStartMs;
        j["rulesEndMs"] = rulesEndMs;
        j["openedAt"] = int(openedAtUnix);
        j["finalizedAt"] = int(finalizedAtUnix);

        auto scoreBefore = Json::Array();
        scoreBefore.Add(blueScoreBefore);
        scoreBefore.Add(redScoreBefore);
        j["teamScoreBefore"] = scoreBefore;
        auto scoreAfter = Json::Array();
        scoreAfter.Add(blueScoreAfter);
        scoreAfter.Add(redScoreAfter);
        j["teamScoreAfter"] = scoreAfter;

        j["roundWinningTeam"] = roundWinningTeam;
        j["pointsLimit"] = pointsLimit;
        j["pointsRepartition"] = IntArrayToJson(pointsRepartition);

        auto playerArray = Json::Array();
        int captured = 0;
        int identityComplete = 0;
        int telemetryAvailable = 0;
        for (uint i = 0; i < players.Length; i++) {
            auto p = players[i];
            auto playerJson = p.ToJson();
            if (!includeTelemetry) playerJson["telemetry"] = Json::Object();
            playerArray.Add(playerJson);
            captured++;
            if (p.accountId.Length > 0) identityComplete++;
            if (p.telemetryEverAvailable) telemetryAvailable++;
        }
        j["players"] = playerArray;

        auto integrity = Json::Object();
        integrity["participatingPlayers"] = int(players.Length);
        integrity["capturedPlayers"] = captured;
        integrity["expectedLeaguePlayers"] = S_RecorderExpectedLeaguePlayers;
        integrity["identityCompletePlayers"] = identityComplete;
        integrity["telemetryAvailablePlayers"] = telemetryAvailable;
        integrity["resultSeen"] = resultSeen;
        integrity["complete"] = resultSeen && captured == S_RecorderExpectedLeaguePlayers;
        j["integrity"] = integrity;

        return j;
    }
}

namespace ProdRecorder {
    const int RecorderSchemaVersion = 1;
    const string RecorderRootName = "Recorder";
    const string CurrentRoundFileName = "Recorder/current-round.json";
    const string MatchesFolderName = "Recorder/matches";
    const string FinalizedRoundsFolderName = "Recorder/finalized-rounds";

    ProdRecorderRoundCache@ CurrentRound = null;
    Json::Value@ CurrentMatch = null;
    string CurrentMatchServerLogin;
    string CurrentMatchFileName;
    uint CurrentMatchCreatedAt = 0;

    int LastStartNewRace = -123;
    int PendingRaceNumber = -1;
    bool PendingRoundOpen = false;
    bool LastEnabledState = false;
    string Status = "Recorder not initialized";
    string LastPersistReason = "";

    bool DependenciesAvailable() { return true; }

    void Debug(const string &in message) {
        if (S_RecorderDebugLogging) trace("[PROD Recorder] " + message);
    }

    string RootPath() { return IO::FromStorageFolder(RecorderRootName); }
    string CurrentRoundPath() { return IO::FromStorageFolder(CurrentRoundFileName); }
    string MatchesFolderPath() { return IO::FromStorageFolder(MatchesFolderName); }
    string FinalizedRoundsFolderPath() { return IO::FromStorageFolder(FinalizedRoundsFolderName); }

    void EnsureFolders() {
        if (!IO::FolderExists(RootPath())) IO::CreateFolder(RootPath(), true);
        if (!IO::FolderExists(MatchesFolderPath())) IO::CreateFolder(MatchesFolderPath(), true);
        if (!IO::FolderExists(FinalizedRoundsFolderPath())) IO::CreateFolder(FinalizedRoundsFolderPath(), true);
    }

    string SafeFilePart(const string &in input) {
        string safe = input.Replace("|", "_").Replace(":", "_").Replace("#", "_");
        safe = safe.Replace("?", "_").Replace("*", "_").Replace('"', '_');
        safe = safe.Replace("<", "_").Replace(">", "_").Replace("/", "_").Replace("\\", "_");
        return safe;
    }

    void Initialize() {
        EnsureFolders();
        LastEnabledState = S_RecorderEnabled;
        Status = S_RecorderEnabled ? "Recorder armed" : "Recorder disabled";
        Debug(Status);
    }

    void OpenFolder() {
        EnsureFolders();
        OpenExplorerPath(RootPath());
    }

    CTrackManiaNetworkServerInfo@ ServerInfo() {
        auto app = cast<CTrackMania>(GetApp());
        if (app is null || app.Network is null || app.Network.ServerInfo is null) return null;
        return cast<CTrackManiaNetworkServerInfo>(app.Network.ServerInfo);
    }

    void CopyInts(const array<int>@ source, array<int>@ target) {
        target.Resize(source is null ? 0 : source.Length);
        if (source is null) return;
        for (uint i = 0; i < source.Length; i++) target[i] = source[i];
    }

    string BuildRoundKey(const string &in serverLogin, const string &in mapUid, int rulesStartMs, int raceNumber) {
        return serverLogin + "|" + mapUid + "|" + tostring(rulesStartMs) + "|" + tostring(raceNumber);
    }

    void EnsureMatchSession(CTrackManiaNetworkServerInfo@ serverInfo) {
        if (serverInfo is null) return;
        if (CurrentMatch !is null && CurrentMatchServerLogin == serverInfo.ServerLogin) return;

        CurrentMatchServerLogin = serverInfo.ServerLogin;
        CurrentMatchCreatedAt = Time::Stamp;
        string sessionKey = CurrentMatchServerLogin + "|" + tostring(CurrentMatchCreatedAt);
        CurrentMatchFileName = MatchesFolderName + "/" + SafeFilePart(sessionKey) + ".json";

        @CurrentMatch = Json::Object();
        CurrentMatch["schemaVersion"] = RecorderSchemaVersion;

        auto source = Json::Object();
        source["plugin"] = "MLE TM PROD";
        source["pluginVersion"] = "0.1.8";
        source["recorderVersion"] = RecorderSchemaVersion;
        CurrentMatch["source"] = source;

        auto session = Json::Object();
        session["sessionKey"] = sessionKey;
        session["createdAt"] = int(CurrentMatchCreatedAt);
        session["serverLogin"] = serverInfo.ServerLogin;
        session["serverName"] = serverInfo.ServerName;
        session["gameMode"] = serverInfo.CurGameModeStr;
        CurrentMatch["session"] = session;
        CurrentMatch["maps"] = Json::Array();
        SaveCurrentMatch();
        Debug("Created match session " + sessionKey);
    }

    Json::Value@ FindOrCreateMatchMap(ProdRecorderRoundCache@ round) {
        auto maps = CurrentMatch["maps"];
        for (uint i = 0; i < maps.Length; i++) {
            if (string(maps[i]["uid"]) == round.mapUid) return maps[i];
        }

        auto map = Json::Object();
        map["uid"] = round.mapUid;
        map["name"] = round.mapName;
        map["cpCount"] = round.mapCpCount;
        map["cpsToFinish"] = round.mapCpsToFinish;
        map["rounds"] = Json::Array();
        maps.Add(map);
        return maps[maps.Length - 1];
    }

    bool MatchAlreadyHasRound(const string &in roundKey) {
        if (CurrentMatch is null) return false;
        auto maps = CurrentMatch["maps"];
        for (uint i = 0; i < maps.Length; i++) {
            auto rounds = maps[i]["rounds"];
            for (uint r = 0; r < rounds.Length; r++) {
                if (string(rounds[r]["roundKey"]) == roundKey) return true;
            }
        }
        return false;
    }

    void SaveCurrentMatch() {
        if (CurrentMatch is null || CurrentMatchFileName.Length == 0) return;
        EnsureFolders();
        Json::ToFile(IO::FromStorageFolder(CurrentMatchFileName), CurrentMatch);
    }

    void PersistCurrentRound(const string &in reason) {
        if (CurrentRound is null) return;
        EnsureFolders();
        Json::ToFile(CurrentRoundPath(), CurrentRound.ToJson(true));
        LastPersistReason = reason;
        Debug("Persisted " + CurrentRound.roundKey + " | " + reason);
    }

    void PersistFinalizedRound(ProdRecorderRoundCache@ round) {
        if (round is null) return;
        EnsureFolders();
        string fileName = FinalizedRoundsFolderName + "/" + SafeFilePart(round.roundKey) + ".json";
        Json::ToFile(IO::FromStorageFolder(fileName), round.ToJson(true));
    }

    int CountEligibleParticipants(const MLFeed::HookRaceStatsEventsBase_V4@ raceData) {
        if (raceData is null) return 0;
        int count = 0;
        for (uint i = 0; i < raceData.SortedPlayers_Race_Respawns.Length; i++) {
            auto p = cast<MLFeed::PlayerCpInfo_V4>(raceData.SortedPlayers_Race_Respawns[i]);
            if (p is null) continue;
            if (p.TeamNum != 1 && p.TeamNum != 2) continue;
            if (!p.PlayerIsRacing && !p.IsFinished && p.StartTime == 0) continue;
            count++;
        }
        return count;
    }

    bool TryOpenRound(const MLFeed::HookRaceStatsEventsBase_V4@ raceData, const MLFeed::HookTeamsMMEventsBase_V1@ teams) {
        if (!PendingRoundOpen || raceData is null || teams is null || teams.WarmUpIsActive) return false;
        if (CountEligibleParticipants(raceData) == 0) return false;

        auto app = cast<CTrackMania>(GetApp());
        auto serverInfo = ServerInfo();
        if (app is null || app.RootMap is null || app.RootMap.MapInfo is null || serverInfo is null) return false;

        EnsureMatchSession(serverInfo);

        auto round = ProdRecorderRoundCache();
        round.serverLogin = serverInfo.ServerLogin;
        round.serverName = serverInfo.ServerName;
        round.gameMode = serverInfo.CurGameModeStr;
        round.mapUid = app.RootMap.MapInfo.MapUid;
        round.mapName = app.RootMap.MapInfo.Name;
        round.mapCpCount = int(raceData.CPCount);
        round.mapCpsToFinish = int(raceData.CPsToFinish);
        round.raceNumber = PendingRaceNumber;
        round.roundNumberAtOpen = teams.RoundNumber;
        round.rulesStartMs = int(raceData.Rules_StartTime);
        round.openedAtUnix = Time::Stamp;
        round.pointsLimit = teams.PointsLimit;
        if (teams.ClanScores !is null && teams.ClanScores.Length > 2) {
            round.blueScoreBefore = teams.ClanScores[1];
            round.redScoreBefore = teams.ClanScores[2];
        }
        CopyInts(teams.PointsRepartition, round.pointsRepartition);
        round.roundKey = BuildRoundKey(round.serverLogin, round.mapUid, round.rulesStartMs, round.raceNumber);

        for (uint i = 0; i < raceData.SortedPlayers_Race_Respawns.Length; i++) {
            auto p = cast<MLFeed::PlayerCpInfo_V4>(raceData.SortedPlayers_Race_Respawns[i]);
            if (p is null) continue;
            if (p.TeamNum != 1 && p.TeamNum != 2) continue;
            if (!p.PlayerIsRacing && !p.IsFinished && p.StartTime == 0) continue;
            if (round.Find(p) !is null) continue;
            round.players.InsertLast(ProdRecorderPlayerCache(p));
        }

        @CurrentRound = round;
        PendingRoundOpen = false;
        Status = "Recording race " + tostring(round.raceNumber) + " | " + tostring(round.players.Length) + " players";
        Debug("ROUND OPENED " + round.roundKey + " | players=" + tostring(round.players.Length));
        for (uint i = 0; i < round.players.Length; i++) {
            auto cached = round.players[i];
            Debug("  participant: " + cached.name + " | team=" + tostring(cached.teamNum) + " | account=" + cached.accountId);
        }
        PersistCurrentRound("countdown_complete");
        return true;
    }

    const MLFeed::PlayerCpInfo_V4@ FindLivePlayer(const MLFeed::HookRaceStatsEventsBase_V4@ raceData, ProdRecorderPlayerCache@ cached) {
        if (raceData is null || cached is null) return null;
        for (uint i = 0; i < raceData.SortedPlayers_Race_Respawns.Length; i++) {
            auto p = cast<MLFeed::PlayerCpInfo_V4>(raceData.SortedPlayers_Race_Respawns[i]);
            if (p is null) continue;
            if (cached.accountId.Length > 0 && p.WebServicesUserId == cached.accountId) return p;
            if (cached.login.Length > 0 && p.Login == cached.login) return p;
            if (cached.name.Length > 0 && p.Name == cached.name) return p;
        }
        return null;
    }

    int FinishPositionFromTeams(const MLFeed::HookTeamsMMEventsBase_V1@ teams, ProdRecorderPlayerCache@ cached) {
        if (teams is null || cached is null) return -1;
        if (teams.PlayersFinishedLogins !is null && cached.login.Length > 0) {
            for (uint i = 0; i < teams.PlayersFinishedLogins.Length; i++) {
                if (teams.PlayersFinishedLogins[i] == cached.login) return int(i) + 1;
            }
        }
        if (teams.PlayersFinishedNames !is null && cached.name.Length > 0) {
            for (uint i = 0; i < teams.PlayersFinishedNames.Length; i++) {
                if (teams.PlayersFinishedNames[i] == cached.name) return int(i) + 1;
            }
        }
        return -1;
    }

    bool FreezeFromFinishLists(const MLFeed::HookTeamsMMEventsBase_V1@ teams) {
        if (CurrentRound is null || teams is null) return false;
        bool changed = false;
        for (uint i = 0; i < CurrentRound.players.Length; i++) {
            auto cached = CurrentRound.players[i];
            if (cached.frozen) continue;
            int position = FinishPositionFromTeams(teams, cached);
            if (position < 1) continue;
            CurrentRound.finishSequence = Math::Max(CurrentRound.finishSequence, position);
            cached.FreezeFinished(position);
            Debug("PLAYER FROZEN " + cached.name + " | P" + tostring(position) + " | finish=" + tostring(cached.finishTimeMs));
            changed = true;
        }
        return changed;
    }

    void UpdateActiveRound(const MLFeed::HookRaceStatsEventsBase_V4@ raceData, const MLFeed::HookTeamsMMEventsBase_V1@ teams) {
        if (CurrentRound is null || CurrentRound.finalized || raceData is null || teams is null) return;

        bool checkpointEvent = false;
        bool respawnEvent = false;
        bool finishEvent = false;
        uint now = Time::Now;

        for (uint i = 0; i < CurrentRound.players.Length; i++) {
            auto cached = CurrentRound.players[i];
            if (cached.frozen) continue;

            auto p = FindLivePlayer(raceData, cached);
            if (p is null) {
                if (!cached.disappeared) {
                    if (cached.disappearedAtMs == 0) cached.disappearedAtMs = now;
                    else if (now - cached.disappearedAtMs >= uint(S_RecorderDisappearGraceMs)) {
                        cached.disappeared = true;
                        Debug("PLAYER DISAPPEARED " + cached.name + " | last CP=" + tostring(cached.lastObservedCpCount));
                    }
                }
                continue;
            }

            int previousCp = cached.lastObservedCpCount;
            uint previousRespawns = cached.lastObservedRespawnCount;
            cached.UpdateFrom(p);
            cached.SampleTelemetry(p);

            if (p.CpCount > previousCp) {
                cached.lastObservedCpCount = p.CpCount;
                checkpointEvent = true;
                Debug("CHECKPOINT " + cached.name + " | CP" + tostring(p.CpCount) + " | " + tostring(p.LastCpTime));
            } else {
                cached.lastObservedCpCount = p.CpCount;
            }

            if (p.NbRespawnsRequested > previousRespawns) {
                cached.lastObservedRespawnCount = p.NbRespawnsRequested;
                respawnEvent = true;
                Debug("RESPAWN " + cached.name + " | count=" + tostring(p.NbRespawnsRequested) + " | CP=" + tostring(p.LastRespawnCheckpoint));
            } else {
                cached.lastObservedRespawnCount = p.NbRespawnsRequested;
            }

            if (p.IsFinished && !cached.frozen) {
                int position = FinishPositionFromTeams(teams, cached);
                if (position < 1) position = ++CurrentRound.finishSequence;
                else CurrentRound.finishSequence = Math::Max(CurrentRound.finishSequence, position);
                cached.FreezeFinished(position);
                finishEvent = true;
                Debug("PLAYER FROZEN " + cached.name + " | P" + tostring(position) + " | finish=" + tostring(cached.finishTimeMs));
            }
        }

        if (FreezeFromFinishLists(teams)) finishEvent = true;

        if (finishEvent) PersistCurrentRound("finish");
        else if (respawnEvent) PersistCurrentRound("respawn");
        else if (checkpointEvent) PersistCurrentRound("checkpoint");

        if (teams.RoundWinningClan >= 0 && !CurrentRound.resultSeen) {
            CurrentRound.resultSeen = true;
            CurrentRound.resultSeenAtMs = now;
            CurrentRound.roundWinningTeam = teams.RoundWinningClan;
            Debug("ROUND RESULT SEEN | winner=" + tostring(teams.RoundWinningClan));
        }
        if (CurrentRound.resultSeen && now - CurrentRound.resultSeenAtMs >= uint(S_RecorderFinalizeDelayMs)) {
            FinalizeCurrentRound(raceData, teams, "round_result");
        }
    }

    void FinalizeCurrentRound(const MLFeed::HookRaceStatsEventsBase_V4@ raceData, const MLFeed::HookTeamsMMEventsBase_V1@ teams, const string &in reason) {
        if (CurrentRound is null || CurrentRound.finalized) return;

        if (raceData !is null) CurrentRound.rulesEndMs = int(raceData.Rules_EndTime);
        CurrentRound.finalizedAtUnix = Time::Stamp;
        if (teams !is null) {
            if (teams.RoundWinningClan >= 0) {
                CurrentRound.roundWinningTeam = teams.RoundWinningClan;
                CurrentRound.resultSeen = true;
            }
            if (teams.ClanScores !is null && teams.ClanScores.Length > 2) {
                CurrentRound.blueScoreAfter = teams.ClanScores[1];
                CurrentRound.redScoreAfter = teams.ClanScores[2];
            }
        }

        for (uint i = 0; i < CurrentRound.players.Length; i++) {
            auto cached = CurrentRound.players[i];
            if (cached.frozen) continue;
            auto p = FindLivePlayer(raceData, cached);
            if (p !is null) cached.UpdateFrom(p);
            cached.FinalizeUnfinished(p is null || cached.disappeared);
            Debug("PLAYER FINALIZED UNFINISHED " + cached.name + " | disappeared=" + tostring(cached.disappeared));
        }

        CurrentRound.finalized = true;
        PersistCurrentRound("finalize_" + reason);
        PersistFinalizedRound(CurrentRound);

        if (!MatchAlreadyHasRound(CurrentRound.roundKey)) {
            auto map = FindOrCreateMatchMap(CurrentRound);
            map["rounds"].Add(CurrentRound.ToJson(true));
            SaveCurrentMatch();
        } else {
            Debug("Duplicate finalized round ignored: " + CurrentRound.roundKey);
        }

        if (IO::FileExists(CurrentRoundPath())) IO::Delete(CurrentRoundPath());
        Status = "Last round saved: race " + tostring(CurrentRound.raceNumber) + " | " + tostring(CurrentRound.players.Length) + " players";
        Debug("ROUND FINALIZED " + CurrentRound.roundKey + " | reason=" + reason);
        @CurrentRound = null;
    }

    void HandleRaceStart(const MLFeed::HookRaceStatsEventsBase_V4@ raceData, const MLFeed::HookTeamsMMEventsBase_V1@ teams) {
        if (teams is null) return;

        int startNewRace = teams.StartNewRace;
        if (teams.WarmUpIsActive) {
            LastStartNewRace = startNewRace;
            return;
        }

        if (LastStartNewRace == -123) {
            LastStartNewRace = startNewRace;
            Debug("Race counter baseline=" + tostring(startNewRace) + "; waiting for next countdown.");
            return;
        }

        if (startNewRace >= 1 && startNewRace != LastStartNewRace) {
            if (CurrentRound !is null && !CurrentRound.finalized) {
                Debug("New race arrived before prior round finalized; finalizing prior cache as superseded.");
                FinalizeCurrentRound(raceData, teams, "next_race_started");
            }
            LastStartNewRace = startNewRace;
            PendingRaceNumber = startNewRace;
            PendingRoundOpen = true;
            Debug("COUNTDOWN COMPLETE signal | StartNewRace=" + tostring(startNewRace));
        }

        if (PendingRoundOpen) TryOpenRound(raceData, teams);
    }

    void HandleMapOrServerLoss() {
        if (CurrentRound is null) return;
        Debug("Map/server disappeared while a round cache was active; preserving current-round.json for recovery.");
        PersistCurrentRound("map_or_server_loss");
        Status = "Recorder cache preserved after map/server loss";
        @CurrentRound = null;
    }

    void Update(float dt) {
        if (S_RecorderEnabled != LastEnabledState) {
            LastEnabledState = S_RecorderEnabled;
            Debug(S_RecorderEnabled ? "Recorder enabled" : "Recorder disabled");
            if (!S_RecorderEnabled && CurrentRound !is null) PersistCurrentRound("recorder_disabled");
        }
        if (!S_RecorderEnabled) {
            Status = "Recorder disabled";
            return;
        }

        auto app = cast<CTrackMania>(GetApp());
        auto serverInfo = ServerInfo();
        if (app is null || app.CurrentPlayground is null || app.RootMap is null || serverInfo is null || serverInfo.ServerLogin.Length == 0) {
            HandleMapOrServerLoss();
            return;
        }

        auto raceData = MLFeed::GetRaceData_V4();
        auto teams = MLFeed::GetTeamsMMData_V1();
        if (raceData is null || teams is null) {
            Status = "Recorder waiting for MLFeed race/team data";
            return;
        }

        HandleRaceStart(raceData, teams);
        UpdateActiveRound(raceData, teams);
    }

    void Shutdown() {
        if (CurrentRound !is null) PersistCurrentRound("plugin_shutdown");
    }
}

#else

namespace ProdRecorder {
    string Status = "Recorder unavailable - MLFeed/MLHook missing";
    string LastPersistReason = "";
    bool DependenciesAvailable() { return false; }
    void Initialize() {}
    void Update(float dt) {}
    void Shutdown() {}
    void OpenFolder() {
        string root = IO::FromStorageFolder("Recorder");
        if (!IO::FolderExists(root)) IO::CreateFolder(root, true);
        OpenExplorerPath(root);
    }
}

#endif
