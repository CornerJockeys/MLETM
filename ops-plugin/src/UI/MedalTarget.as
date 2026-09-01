namespace MedalTarget {
    enum Medal {
        None,
        Bronze,
        Silver,
        Gold,
        Author,
        Warrior,
        Champion
    }

    UI::Texture@ BronzeTexture;
    UI::Texture@ SilverTexture;
    UI::Texture@ GoldTexture;
    UI::Texture@ AuthorTexture;
    UI::Texture@ ChampionTexture;

    void Initialize() {
        @BronzeTexture = UI::LoadTexture("assets/bronze.png");
        @SilverTexture = UI::LoadTexture("assets/silver.png");
        @GoldTexture = UI::LoadTexture("assets/gold.png");
        @AuthorTexture = UI::LoadTexture("assets/author.png");
        @ChampionTexture = UI::LoadTexture("assets/champion_medal.png");
    }

    uint GetTime(Medal medal) {
        if (medal == Medal::Warrior) {
#if DEPENDENCY_WARRIORMEDALS
            return WarriorMedals::GetWMTime();
#else
            return 0;
#endif
        }

        if (medal == Medal::Champion) {
#if DEPENDENCY_CHAMPIONMEDALS
            return ChampionMedals::GetCMTime();
#else
            return 0;
#endif
        }

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
        array<Medal> medals = {
            Medal::Bronze,
            Medal::Silver,
            Medal::Gold,
            Medal::Author,
            Medal::Warrior,
            Medal::Champion
        };

        Medal nextMedal = Medal::None;
        uint nextTime = 0;

        for (uint i = 0; i < medals.Length; i++) {
            Medal medal = medals[i];
            uint targetTime = GetTime(medal);
            if (targetTime == 0) continue;

            if (playerTimeMs == 0) {
                // With no PB yet, show the slowest available medal as the first target.
                if (nextMedal == Medal::None || targetTime > nextTime) {
                    nextMedal = medal;
                    nextTime = targetTime;
                }
                continue;
            }

            // Already-achieved targets are not candidates. Of the remaining targets,
            // choose the closest one below the player's PB rather than assuming a
            // fixed ordering between third-party medal systems.
            if (targetTime >= playerTimeMs) continue;

            if (nextMedal == Medal::None || targetTime > nextTime) {
                nextMedal = medal;
                nextTime = targetTime;
            }
        }

        return nextMedal;
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
            case Medal::Warrior:
                return "Warrior";
            case Medal::Champion:
                return "Champion";
        }

        return "";
    }

    const UI::Texture@ GetTexture(Medal medal) {
        switch (medal) {
            case Medal::Bronze:
                return BronzeTexture;
            case Medal::Silver:
                return SilverTexture;
            case Medal::Gold:
                return GoldTexture;
            case Medal::Author:
                return AuthorTexture;
            case Medal::Warrior:
#if DEPENDENCY_WARRIORMEDALS
                return WarriorMedals::GetIconWarrior32();
#else
                return null;
#endif
            case Medal::Champion:
                return ChampionTexture;
        }

        return null;
    }
}
