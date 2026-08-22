namespace PlayerDirectory {
    dictionary Players;
    int SchemaVersion = 0;
    string GeneratedAt;

    bool Initialize() {
        Players.DeleteAll();
        SchemaVersion = 0;
        GeneratedAt = "";

        IO::FileSource file("data/players.json");
        auto snapshot = Json::Parse(file.ReadToEnd());

        if (snapshot.GetType() != Json::Type::Object) {
            error("MLE TM: players.json root is not a JSON object.");
            return false;
        }

        if (!snapshot.HasKey("schemaVersion") || !snapshot.HasKey("players")) {
            error("MLE TM: players.json is missing schemaVersion or players.");
            return false;
        }

        SchemaVersion = snapshot["schemaVersion"];
        if (snapshot.HasKey("generatedAt")) {
            GeneratedAt = snapshot["generatedAt"];
        }

        auto playersJson = snapshot["players"];
        if (playersJson.GetType() != Json::Type::Object) {
            error("MLE TM: players.json players value is not a JSON object.");
            return false;
        }

        auto accountIds = playersJson.GetKeys();
        uint loaded = 0;

        for (uint i = 0; i < accountIds.Length; i++) {
            string accountId = accountIds[i];
            auto playerJson = playersJson[accountId];

            if (playerJson.GetType() != Json::Type::Object) {
                warn("MLE TM: skipping malformed player record for Account ID " + accountId);
                continue;
            }

            auto player = PlayerInfo(
                accountId,
                playerJson["tmid"],
                playerJson["mleName"],
                playerJson["tmName"],
                playerJson["team"],
                playerJson["rosterSlot"],
                playerJson["salary"],
                playerJson["league"],
                playerJson["rostered"]
            );

            @Players[accountId] = player;
            loaded++;
        }

        trace("MLE TM player snapshot loaded: " + loaded + " player(s), schema v" + SchemaVersion);
        return true;
    }

    PlayerInfo@ Get(const string &in accountId) {
        if (!Players.Exists(accountId)) return null;
        return cast<PlayerInfo>(Players[accountId]);
    }
}
