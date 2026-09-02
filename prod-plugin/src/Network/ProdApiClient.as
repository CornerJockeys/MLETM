class ProdDivisionRecord {
    uint timeMs;
    string accountId;
    string mleName;
    string team;

    ProdDivisionRecord(uint timeMs, const string &in accountId, const string &in mleName, const string &in team) {
        this.timeMs = timeMs;
        this.accountId = accountId;
        this.mleName = mleName;
        this.team = team;
    }
}

class ProdAccessResult {
    bool requestOk;
    bool authorized;
    bool advancedStats;
    string role;
    string accountId;
    string authMode;

    ProdAccessResult() {
        requestOk = false;
        authorized = false;
        advancedStats = false;
        role = "";
        accountId = "";
        authMode = "";
    }
}

namespace ProdApiClient {
    string NormalizeBaseUrl() {
        string baseUrl = S_ProdApiBaseUrl;
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
            throw("MLE TM PROD API request path must start with '/'.");
        }

        string baseUrl = NormalizeBaseUrl();
        if (baseUrl.Length == 0) {
            throw("MLE TM PROD API base URL is not configured.");
        }

        auto req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Get;
        req.Url = baseUrl + path;
        req.Start();
        return req;
    }

    ProdDivisionRecord@ GetFastestDivisionRecord(const string &in mapUid, const string &in division) {
        if (!IsConfigured() || mapUid.Length == 0 || division.Length == 0) return null;

        try {
            auto req = Get("/v1/maps/" + mapUid + "/leaderboards/" + division.ToUpper());
            while (!req.Finished()) yield();

            if (req.ResponseCode() != 200) {
                warn("MLE TM PROD division WR lookup failed: HTTP " + tostring(req.ResponseCode()));
                return null;
            }

            auto root = Json::Parse(req.String());
            if (root.GetType() != Json::Type::Object
                || !root.HasKey("records")
                || root["records"].GetType() != Json::Type::Array) {
                warn("MLE TM PROD division WR lookup returned invalid JSON.");
                return null;
            }

            auto records = root["records"];
            if (records.Length == 0) return null;

            uint bestTime = 0;
            string bestAccountId = "";
            string bestName = "";
            string bestTeam = "";

            for (uint i = 0; i < records.Length; i++) {
                auto record = records[i];
                if (record.GetType() != Json::Type::Object || !record.HasKey("timeMs")) continue;

                uint timeMs = uint(record["timeMs"]);
                if (timeMs == 0 || (bestTime > 0 && timeMs >= bestTime)) continue;

                bestTime = timeMs;
                bestAccountId = record.HasKey("accountId") ? string(record["accountId"]) : "";
                bestName = record.HasKey("mleName") ? string(record["mleName"]) : "";
                bestTeam = record.HasKey("team") ? string(record["team"]) : "";
            }

            if (bestTime == 0) return null;
            return ProdDivisionRecord(bestTime, bestAccountId, bestName, bestTeam);
        } catch {
            warn("MLE TM PROD division WR lookup threw: " + getExceptionInfo());
            return null;
        }
    }

    ProdAccessResult@ GetProdAccess(const string &in accountId) {
        auto result = ProdAccessResult();
        result.accountId = accountId;

        if (!IsConfigured() || accountId.Length == 0) return result;

        try {
            auto req = Get("/v1/prod/access/account/" + accountId);
            while (!req.Finished()) yield();

            if (req.ResponseCode() != 200) {
                warn("MLE TM PROD access lookup failed: HTTP " + tostring(req.ResponseCode()));
                return result;
            }

            auto root = Json::Parse(req.String());
            if (root.GetType() != Json::Type::Object) return result;

            result.requestOk = true;
            result.authorized = root.HasKey("authorized") && bool(root["authorized"]);
            result.advancedStats = root.HasKey("advancedStats") && bool(root["advancedStats"]);
            result.role = root.HasKey("role") ? string(root["role"]) : "";
            result.authMode = root.HasKey("authMode") ? string(root["authMode"]) : "";
            return result;
        } catch {
            warn("MLE TM PROD access lookup threw: " + getExceptionInfo());
            return result;
        }
    }
}
