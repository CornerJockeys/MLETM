const string StorageDir = IO::FromStorageFolder("");

void InitializeDb() {
    // scan files mb
}

// the most recently requested match log
Json::Value@ currMatchLog;

namespace DB {
    dictionary loadedMatches;


    Json::Value@ GetMatchLog(const string &in logName) {
        if (!loadedMatches.Exists(logName)) {
            @loadedMatches[logName] = NewMatchLog(logName);
        }
        @currMatchLog = cast<Json::Value>(loadedMatches[logName]);
        return currMatchLog;
    }

    Json::Value@ NewMatchLog(const string &in logName) {
        auto j = Json::Object();
        j['name'] = logName;
        j['logName'] = logName + ".json";
        j['serverLogin'] = currServerLogin;
        j['gameMode'] = currGameMode;
        j['serverName'] = currServerName;
        j['maps'] = Json::Array();
        j['createdTs'] = Time::Stamp;
        return j;
    }

    void SaveMatchLog(Json::Value@ j) {
        string fileName = j['logName'];
        auto path = IO::FromStorageFolder(fileName);
        print("Writing file: " + path);
        Json::ToFile(path, j);
    }

    bool RemoveAndDeleteMatchLogIfEmpty(const string &in logName) {
        auto ln = logName.EndsWith(".json") ? logName.SubStr(0, logName.Length - 5) : logName;
        auto path = IO::FromStorageFolder(ln + ".json");
        bool remLoadedMatch = loadedMatches.Exists(ln);
        bool delFile = IO::FileExists(path);
        if (remLoadedMatch) loadedMatches.Delete(ln);
        if (delFile) IO::Delete(path);
        return delFile || remLoadedMatch;
    }
}

Json::Value@ GetMostRecentMapIfCurrentOrAddNew(Json::Value@ j) {
    auto maps = j['maps'];
    if (maps.Length == 0 || currMapUid != maps[maps.Length - 1]['uid']) {
        maps.Add(NewMatchMap());
    }
    return maps[maps.Length - 1];
}

Json::Value@ NewMatchMap() {
    auto j = Json::Object();
    j['uid'] = currMapUid;
    j['name'] = currMapName;
    j['rounds'] = Json::Array();
    return j;
}
