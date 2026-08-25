class LeaderboardRecord {
    string accountId;
    string mleName;
    uint timeMs;
    uint respawns;
    bool provisional;

    string team;
    string clubTag;
    string clubTagFormat;
    string clubId;
    string replayUrl;
    string recordSetAt;
    float salary = -1.0f;

    LeaderboardRecord(
        const string &in accountId,
        const string &in mleName,
        uint timeMs,
        uint respawns,
        bool provisional = false
    ) {
        this.accountId = accountId;
        this.mleName = mleName;
        this.timeMs = timeMs;
        this.respawns = respawns;
        this.provisional = provisional;
    }

    LeaderboardRecord(
        const string &in accountId,
        const string &in mleName,
        uint timeMs,
        uint respawns,
        bool provisional,
        const string &in team,
        const string &in clubTag,
        const string &in clubTagFormat,
        const string &in clubId,
        const string &in replayUrl = "",
        const string &in recordSetAt = "",
        float salary = -1.0f
    ) {
        this.accountId = accountId;
        this.mleName = mleName;
        this.timeMs = timeMs;
        this.respawns = respawns;
        this.provisional = provisional;
        this.team = team;
        this.clubTag = clubTag;
        this.clubTagFormat = clubTagFormat;
        this.clubId = clubId;
        this.replayUrl = replayUrl;
        this.recordSetAt = recordSetAt;
        this.salary = salary;
    }
}
