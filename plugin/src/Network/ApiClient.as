[Setting category="MLE TM" name="API Base URL" description="Base URL for the MLE TM backend API. Clear this value to use local snapshot data only."]
string S_ApiBaseUrl = "https://mle-tm-temp-api.mschifanoiii.workers.dev";

namespace ApiClient {
    bool HealthCheckRunning = false;
    bool LastHealthCheckOk = false;
    int LastHealthStatusCode = 0;
    string LastHealthResponse = "";

    string NormalizeBaseUrl() {
        string baseUrl = S_ApiBaseUrl;
        while (baseUrl.EndsWith("/")) {
            baseUrl = baseUrl.SubStr(0, baseUrl.Length - 1);
        }
        return baseUrl;
    }

    bool IsConfigured() {
        return NormalizeBaseUrl().Length > 0;
    }

    Net::HttpRequest@ Get(const string &in path) {
        if (!path.StartsWith("/")) {
            throw("MLE TM API request path must start with '/'.");
        }

        string baseUrl = NormalizeBaseUrl();
        if (baseUrl.Length == 0) {
            throw("MLE TM API base URL is not configured.");
        }

        auto req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Get;
        req.Url = baseUrl + path;
        req.Start();
        return req;
    }

    PlayerInfo@ GetPlayer(const string &in accountId) {
        if (!IsConfigured()) return null;

        try {
            auto req = Get("/players/" + accountId);
            trace("MLE TM API player lookup: " + req.Url);

            while (!req.Finished()) {
                yield();
            }

            int statusCode = req.ResponseCode();
            string response = req.String();

            if (statusCode != 200) {
                warn(
                    "MLE TM API player lookup failed: HTTP "
                    + Text::Format("%d", statusCode)
                    + " - "
                    + response
                );
                return null;
            }

            auto playerJson = Json::Parse(response);
            if (playerJson.GetType() != Json::Type::Object) {
                warn("MLE TM API player lookup returned invalid JSON.");
                return null;
            }

            auto player = PlayerInfo(
                playerJson["accountId"],
                playerJson["tmid"],
                playerJson["mleName"],
                playerJson["tmName"],
                playerJson["team"],
                playerJson["rosterSlot"],
                playerJson["salary"],
                playerJson["league"],
                playerJson["division"],
                playerJson["rostered"]
            );

            trace("MLE TM API player lookup passed: " + player.mleName);
            return player;
        } catch {
            error("MLE TM API player lookup threw an exception.");
            return null;
        }
    }

    MLEMapInfo@ GetMap(const string &in mapUid) {
        if (!IsConfigured()) return null;

        try {
            auto req = Get("/maps/" + mapUid);
            trace("MLE TM API map lookup: " + req.Url);

            while (!req.Finished()) {
                yield();
            }

            int statusCode = req.ResponseCode();
            string response = req.String();

            if (statusCode != 200) {
                warn(
                    "MLE TM API map lookup failed: HTTP "
                    + Text::Format("%d", statusCode)
                    + " - "
                    + response
                );
                return null;
            }

            auto mapJson = Json::Parse(response);
            if (mapJson.GetType() != Json::Type::Object) {
                warn("MLE TM API map lookup returned invalid JSON.");
                return null;
            }

            array<string> groups;
            if (mapJson.HasKey("groups") && mapJson["groups"].GetType() == Json::Type::Array) {
                auto groupsJson = mapJson["groups"];
                for (uint i = 0; i < groupsJson.Length; i++) {
                    groups.InsertLast(string(groupsJson[i]));
                }
            }

            auto mapInfo = MLEMapInfo(
                mapJson["mapId"],
                mapJson["mapUid"],
                mapJson["name"],
                groups
            );

            trace("MLE TM API map lookup passed: " + mapInfo.name);
            return mapInfo;
        } catch {
            error("MLE TM API map lookup threw an exception.");
            return null;
        }
    }

    MapLeaderboard@ GetLeaderboard(const string &in mapUid, const string &in division) {
        if (!IsConfigured()) return null;

        try {
            auto req = Get("/maps/" + mapUid + "/leaderboards/" + division);
            trace("MLE TM API leaderboard lookup: " + req.Url);

            while (!req.Finished()) {
                yield();
            }

            int statusCode = req.ResponseCode();
            string response = req.String();

            if (statusCode != 200) {
                warn(
                    "MLE TM API leaderboard lookup failed: HTTP "
                    + Text::Format("%d", statusCode)
                    + " - "
                    + response
                );
                return null;
            }

            auto leaderboardJson = Json::Parse(response);
            if (leaderboardJson.GetType() != Json::Type::Object
                || !leaderboardJson.HasKey("records")
                || leaderboardJson["records"].GetType() != Json::Type::Array) {
                warn("MLE TM API leaderboard lookup returned invalid JSON.");
                return null;
            }

            auto leaderboard = MapLeaderboard(division);
            auto recordsJson = leaderboardJson["records"];

            for (uint i = 0; i < recordsJson.Length; i++) {
                auto recordJson = recordsJson[i];
                if (recordJson.GetType() != Json::Type::Object) continue;

                string team = recordJson.HasKey("team") ? string(recordJson["team"]) : "";
                string clubTag = recordJson.HasKey("clubTag") ? string(recordJson["clubTag"]) : "";
                string clubTagFormat = recordJson.HasKey("clubTagFormat") ? string(recordJson["clubTagFormat"]) : "";
                string clubId = recordJson.HasKey("clubId") ? string(recordJson["clubId"]) : "";
                string replayUrl = recordJson.HasKey("replayUrl") ? string(recordJson["replayUrl"]) : "";

                leaderboard.records.InsertLast(LeaderboardRecord(
                    recordJson["accountId"],
                    recordJson["mleName"],
                    uint(recordJson["timeMs"]),
                    uint(recordJson["respawns"]),
                    false,
                    team,
                    clubTag,
                    clubTagFormat,
                    clubId,
                    replayUrl
                ));
            }

            trace(
                "MLE TM API leaderboard lookup passed: "
                + division
                + " - "
                + Text::Format("%d", leaderboard.records.Length)
                + " record(s)"
            );
            return leaderboard;
        } catch {
            error("MLE TM API leaderboard lookup threw an exception.");
            return null;
        }
    }

    void HealthCheck() {
        if (HealthCheckRunning) return;

        if (!IsConfigured()) {
            trace("MLE TM API not configured; local snapshots active.");
            return;
        }

        HealthCheckRunning = true;
        LastHealthCheckOk = false;
        LastHealthStatusCode = 0;
        LastHealthResponse = "";

        try {
            auto req = Get("/health");
            trace("MLE TM API health check: " + req.Url);

            while (!req.Finished()) {
                yield();
            }

            LastHealthStatusCode = req.ResponseCode();
            LastHealthResponse = req.String();
            LastHealthCheckOk = LastHealthStatusCode >= 200 && LastHealthStatusCode < 300;

            if (LastHealthCheckOk) {
                trace(
                    "MLE TM API health check passed: HTTP "
                    + Text::Format("%d", LastHealthStatusCode)
                    + " - "
                    + LastHealthResponse
                );
            } else {
                warn(
                    "MLE TM API health check failed: HTTP "
                    + Text::Format("%d", LastHealthStatusCode)
                    + " - "
                    + LastHealthResponse
                );
            }
        } catch {
            error("MLE TM API health check threw an exception.");
        }

        HealthCheckRunning = false;
    }
}
