class PlayerInfo {
    string accountId;
    string tmid;
    string mleName;
    string tmName;
    string team;
    string rosterSlot;
    float salary;
    string league;
    string division;
    bool rostered;

    PlayerInfo(
        const string &in accountId,
        const string &in tmid,
        const string &in mleName,
        const string &in tmName,
        const string &in team,
        const string &in rosterSlot,
        float salary,
        const string &in league,
        const string &in division,
        bool rostered
    ) {
        this.accountId = accountId;
        this.tmid = tmid;
        this.mleName = mleName;
        this.tmName = tmName;
        this.team = team;
        this.rosterSlot = rosterSlot;
        this.salary = salary;
        this.league = league;
        this.division = division;
        this.rostered = rostered;
    }
}
