// Calling this adds a new entry to the match log. It's called from Main.as
void UpdateMatchLog() {
    auto logName = GenerateMatchName();
    auto @matchLog = DB::GetMatchLog(logName);
    auto @mapRound = GetMostRecentMapIfCurrentOrAddNew(matchLog);
    AddMapRound(mapRound);
    DB::SaveMatchLog(matchLog);
}

void AddMapRound(Json::Value@ j) {
    j['rounds'].Add(GenerateMapRoundSummary(IsPodium(GetApp().Network.ClientManiaAppPlayground)));
}

Json::Value@ GenerateMapRoundSummary(bool isPodiumSummary = false) {
    auto rd = MLFeed::GetRaceData_V4();
    auto teams = MLFeed::GetTeamsMMData_V1();
    auto ko = MLFeed::GetKoData();
    auto j = Json::Object();
    j['rulesEnd'] = rd.Rules_EndTime;
    j['rulesStart'] = rd.Rules_StartTime;
    j['rulesNow'] = rd.Rules_GameTime;
    j['endTime'] = Time::Stamp;
    j['players'] = Json::Array();
    j['isOnPodium'] = isPodiumSummary;
    if (isPodiumSummary) {
        j['playerPoints'] = Json::Object();
        j['roundPoints'] = Json::Object();
        j['teams'] = Json::Object();
    }
    if (isKO) {
        j['division'] = ko.Division;
        j['kosMilestone'] = ko.KOsMilestone;
        j['kosNumber'] = ko.KOsNumber;
        j['roundNb'] = ko.RoundNb;
        j['mapRoundNb'] = ko.MapRoundNb;
        j['roundTotal'] = ko.RoundTotal;
        j['mapRoundTotal'] = ko.MapRoundTotal;
    }
    if (isTeams) {
        j['pointsRepartition'] = teams.PointsRepartition.ToJson();
    }
    j['teamScores'] = teams.ClanScores.ToJson();
    ReduceJArrayTrailingZeros(j['teamScores']);
    j['roundWinningTeam'] = teams.RoundWinningClan;
    j['roundNumber'] = teams.RoundNumber;
    j['pointsLimit'] = teams.PointsLimit;
    for (uint i = 0; i < rd.SortedPlayers_Race.Length; i++) {
        auto p = cast<MLFeed::PlayerCpInfo_V4>(rd.SortedPlayers_Race[i]);
        auto playerData = GenPlayerTimes(p);
        if (isPodiumSummary) {
            j['playerPoints'][p.Name] = p.Points;
            j['roundPoints'][p.Name] = p.RoundPoints;
            auto tn = tostring(p.TeamNum);
            if (!j['teams'].HasKey(tn)) j['teams'][tn] = Json::Array();
            j['teams'][tn].Add(p.Name);
            // only add login and wsid on podium summary to avoid bloat
            playerData['login'] = p.Login;
            playerData['wsid'] = p.WebServicesUserId;
        }
        j['players'].Add(playerData);
    }
    // print("Generated summary: " + Json::Write(j));
    return j;
}

Json::Value@ GenPlayerTimes(const MLFeed::PlayerCpInfo_V4@ p) {
    Json::Value@ j = Json::Object();
    j['cpTimes'] = p.CpTimes.ToJson();
    j['respawnTimeLoss'] = p.TimeLostToRespawnByCp.ToJson();
    j['nbRespawnsByCp'] = p.NbRespawnsByCp.ToJson();
    j['respawnTimes'] = p.RespawnTimes.ToJson();
    j['finished'] = p.IsFinished;
    j['name'] = p.Name;
    j['bestTime'] = p.BestTime;
    j['roundPoints'] = p.RoundPoints;
    j['points'] = p.Points;
    j['nbRespawns'] = p.NbRespawnsRequested;
    j['team'] = p.TeamNum;
    j['dnf'] = p.Eliminated;
    if (isKO && p.KoState !is null) {
        j['ko_alive'] = p.KoState.isAlive;
        j['ko_dnf'] = p.KoState.isDNF;
    }
    return j;
}

void ReduceJArrayTrailingZeros(Json::Value@ j) {
    if (j.GetType() != Json::Type::Array) return;
    while (j.Length > 0 && int(j[j.Length - 1]) == 0)
        j.Remove(j.Length - 1);
}
