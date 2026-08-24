namespace MedalTarget {
    enum Medal {
        None,
        Bronze,
        Silver,
        Gold,
        Author
    }

    UI::Texture@ BronzeTexture;
    UI::Texture@ SilverTexture;
    UI::Texture@ GoldTexture;
    UI::Texture@ AuthorTexture;

    void Initialize() {
        @BronzeTexture = UI::LoadTexture("assets/bronze.png");
        @SilverTexture = UI::LoadTexture("assets/silver.png");
        @GoldTexture = UI::LoadTexture("assets/gold.png");
        @AuthorTexture = UI::LoadTexture("assets/author.png");
    }

    uint GetTime(Medal medal) {
        auto app = cast<CTrackMania>(GetApp());
        if (app is null || app.RootMap is null || app.RootMap.ChallengeParameters is null) {
            return 0;
        }

        auto params = app.RootMap.ChallengeParameters;

        switch (medal) {
            case Medal::Bronze:
                return params.BronzeTime;
            case Medal::Silver:
                return params.SilverTime;
            case Medal::Gold:
                return params.GoldTime;
            case Medal::Author:
                return params.AuthorTime;
        }

        return 0;
    }

    Medal GetNext(uint playerTimeMs) {
        uint bronzeTime = GetTime(Medal::Bronze);
        uint silverTime = GetTime(Medal::Silver);
        uint goldTime = GetTime(Medal::Gold);
        uint authorTime = GetTime(Medal::Author);

        if (bronzeTime > 0 && (playerTimeMs == 0 || playerTimeMs > bronzeTime)) {
            return Medal::Bronze;
        }

        if (silverTime > 0 && playerTimeMs > silverTime) {
            return Medal::Silver;
        }

        if (goldTime > 0 && playerTimeMs > goldTime) {
            return Medal::Gold;
        }

        if (authorTime > 0 && playerTimeMs > authorTime) {
            return Medal::Author;
        }

        return Medal::None;
    }

    string GetName(Medal medal) {
        switch (medal) {
            case Medal::Bronze:
                return "Bronze";
            case Medal::Silver:
                return "Silver";
            case Medal::Gold:
                return "Gold";
            case Medal::Author:
                return "Author";
        }

        return "";
    }

    UI::Texture@ GetTexture(Medal medal) {
        switch (medal) {
            case Medal::Bronze:
                return BronzeTexture;
            case Medal::Silver:
                return SilverTexture;
            case Medal::Gold:
                return GoldTexture;
            case Medal::Author:
                return AuthorTexture;
        }

        return null;
    }
}
