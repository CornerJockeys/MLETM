class LeaderboardRecord {
    string accountId;
    string mleName;
    uint timeMs;
    uint respawns;

    LeaderboardRecord(
        const string &in accountId,
        const string &in mleName,
        uint timeMs,
        uint respawns
    ) {
        this.accountId = accountId;
        this.mleName = mleName;
        this.timeMs = timeMs;
        this.respawns = respawns;
    }
}
