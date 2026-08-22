class MapLeaderboard {
    string division;
    array<LeaderboardRecord@> records;

    MapLeaderboard(const string &in division) {
        this.division = division;
    }
}
