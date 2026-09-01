class MLEMapInfo {
    string mapId;
    string mapUid;
    string name;
    array<string> groups;
    array<MapLeaderboard@> leaderboards;

    MLEMapInfo(
        const string &in mapId,
        const string &in mapUid,
        const string &in name,
        const array<string> &in groups
    ) {
        this.mapId = mapId;
        this.mapUid = mapUid;
        this.name = name;
        this.groups = groups;
    }

    MapLeaderboard@ GetLeaderboard(const string &in division) {
        for (uint i = 0; i < leaderboards.Length; i++) {
            if (leaderboards[i].division == division) return leaderboards[i];
        }
        return null;
    }
}
