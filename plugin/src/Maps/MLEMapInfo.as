class MLEMapInfo {
    string mapId;
    string mapUid;
    string name;
    array<string> groups;

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
}
