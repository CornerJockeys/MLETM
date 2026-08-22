namespace PlayerDirectory {
    dictionary Players;

    void InitializeForIdentityTest() {
        Players.DeleteAll();

        auto corners = PlayerInfo(
            "971ea404-8900-4748-9acc-6c57b02ae2a5",
            "T0159",
            "Corners",
            "Corners-",
            "Jets",
            "D",
            5.0,
            "ACADEMY",
            true
        );

        @Players[corners.accountId] = corners;
    }

    PlayerInfo@ Get(const string &in accountId) {
        if (!Players.Exists(accountId)) return null;
        return cast<PlayerInfo>(Players[accountId]);
    }
}
