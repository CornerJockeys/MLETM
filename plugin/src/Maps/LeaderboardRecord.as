class LeaderboardRecord {
    string accountId;
    string mleName;
    uint timeMs;
    uint respawns;
    bool provisional;

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
}
