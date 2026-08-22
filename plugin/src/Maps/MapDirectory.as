namespace MapDirectory {
    dictionary Maps;
    int SchemaVersion = 0;
    string GeneratedAt;

    bool Initialize() {
        Maps.DeleteAll();
        SchemaVersion = 0;
        GeneratedAt = "";

        IO::FileSource file("data/maps.json");
        auto snapshot = Json::Parse(file.ReadToEnd());

        if (snapshot.GetType() != Json::Type::Object) {
            error("MLE TM: maps.json root is not a JSON object.");
            return false;
        }

        if (!snapshot.HasKey("schemaVersion") || !snapshot.HasKey("maps")) {
            error("MLE TM: maps.json is missing schemaVersion or maps.");
            return false;
        }

        SchemaVersion = snapshot["schemaVersion"];
        if (snapshot.HasKey("generatedAt")) {
            GeneratedAt = snapshot["generatedAt"];
        }

        auto mapsJson = snapshot["maps"];
        if (mapsJson.GetType() != Json::Type::Object) {
            error("MLE TM: maps.json maps value is not a JSON object.");
            return false;
        }

        auto mapUids = mapsJson.GetKeys();
        uint loaded = 0;

        for (uint i = 0; i < mapUids.Length; i++) {
            string mapUid = mapUids[i];
            auto mapJson = mapsJson[mapUid];

            if (mapJson.GetType() != Json::Type::Object) {
                warn("MLE TM: skipping malformed map record for Map UID " + mapUid);
                continue;
            }

            array<string> groups;
            if (mapJson.HasKey("groups") && mapJson["groups"].GetType() == Json::Type::Array) {
                auto groupsJson = mapJson["groups"];
                for (uint g = 0; g < groupsJson.Length; g++) {
                    groups.InsertLast(string(groupsJson[g]));
                }
            }

            auto mapInfo = MLEMapInfo(
                mapJson["mapId"],
                mapUid,
                mapJson["name"],
                groups
            );

            @Maps[mapUid] = mapInfo;
            loaded++;
        }

        trace("MLE TM map snapshot loaded: " + loaded + " map(s), schema v" + SchemaVersion);
        return true;
    }

    MLEMapInfo@ Get(const string &in mapUid) {
        if (!Maps.Exists(mapUid)) return null;
        return cast<MLEMapInfo>(Maps[mapUid]);
    }
}
