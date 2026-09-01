class TeamTheme {
    string name;
    vec4 homePrimary;
    vec4 homeSecondary;
    vec4 awayPrimary;
    vec4 awaySecondary;
    vec4 alternatePrimary;
    vec4 alternateSecondary;
    string bundledLogoPath;
    string overrideLogoFile;

    TeamTheme(
        const string &in name,
        uint homePrimary,
        uint homeSecondary,
        uint awayPrimary,
        uint awaySecondary,
        uint alternatePrimary,
        uint alternateSecondary,
        const string &in bundledLogoPath,
        const string &in overrideLogoFile
    ) {
        this.name = name;
        this.homePrimary = TeamThemes::Color(homePrimary);
        this.homeSecondary = TeamThemes::Color(homeSecondary);
        this.awayPrimary = TeamThemes::Color(awayPrimary);
        this.awaySecondary = TeamThemes::Color(awaySecondary);
        this.alternatePrimary = TeamThemes::Color(alternatePrimary);
        this.alternateSecondary = TeamThemes::Color(alternateSecondary);
        this.bundledLogoPath = bundledLogoPath;
        this.overrideLogoFile = overrideLogoFile;
    }
}

namespace TeamThemes {
    dictionary Teams;
    TeamTheme@ Fallback;

    vec4 Color(uint rgb, float alpha = 1.0f) {
        return vec4(
            float((rgb >> 16) & 0xff) / 255.0f,
            float((rgb >> 8) & 0xff) / 255.0f,
            float(rgb & 0xff) / 255.0f,
            alpha
        );
    }

    void Add(TeamTheme@ theme) {
        if (theme is null) return;
        Teams[theme.name.ToUpper()] = @theme;
    }

    void Initialize() {
        Teams.DeleteAll();

        @Fallback = TeamTheme(
            "UNKNOWN",
            0x30343a, 0xf2f2f2,
            0x30343a, 0xf2f2f2,
            0x30343a, 0xf2f2f2,
            "", "Unknown.png"
        );

        // Official MLE TM franchise palette from the S2 Hex Guide.
        Add(TeamTheme("DODGERS",    0x041e42, 0xe7e9ea, 0xbfbfbf, 0x000666, 0x000666, 0x666666, "assets/teams/Dodgers.png",    "Dodgers.png"));
        Add(TeamTheme("HIVE",       0xffa000, 0x111111, 0x3f3f3f, 0xff9f00, 0x262626, 0xff5959, "assets/teams/Hive.png",       "Hive.png"));
        Add(TeamTheme("HURRICANES", 0x005030, 0xf47321, 0xff6532, 0x006628, 0xbfbfbf, 0x006600, "assets/teams/Hurricanes.png", "Hurricanes.png"));
        Add(TeamTheme("JETS",       0x0a2b58, 0xc7102e, 0xff002a, 0x002766, 0xffffff, 0xff002a, "assets/teams/Jets.png",       "Jets.png"));
        Add(TeamTheme("FLAMES",     0xc92a06, 0xf6c432, 0xffb232, 0xb22c00, 0xbfbfbf, 0xb22c00, "assets/teams/Flames.png",     "Flames.png"));
        Add(TeamTheme("SABRES",     0xf36a22, 0x111111, 0x3f3f3f, 0xff6532, 0xff3f00, 0xff8259, "assets/teams/Sabres.png",     "Sabres.png"));
        Add(TeamTheme("SPECTRE",    0x58427c, 0x4dcf74, 0x00ff66, 0xd632ff, 0xffffff, 0x00ff66, "assets/teams/Spectre.png",    "Spectre.png"));
        Add(TeamTheme("WIZARDS",    0x0066b2, 0xfdb927, 0xff9f00, 0x0044b2, 0x666666, 0x0061ff, "assets/teams/Wizards.png",    "Wizards.png"));

        trace("MLE TM PROD team theme directory initialized: " + Teams.GetKeys().Length + " teams.");
    }

    TeamTheme@ Get(const string &in teamName) {
        TeamTheme@ theme = null;
        string key = teamName.ToUpper();
        if (Teams.Get(key, @theme) && theme !is null) return theme;
        return Fallback;
    }

    vec4 Primary(const string &in teamName) {
        return Get(teamName).homePrimary;
    }

    vec4 Secondary(const string &in teamName) {
        return Get(teamName).homeSecondary;
    }

    vec4 RacingStripeA(const string &in teamName) {
        return Get(teamName).homeSecondary;
    }

    vec4 RacingStripeB(const string &in teamName) {
        return Get(teamName).alternateSecondary;
    }

    vec4 DivisionColor(const string &in divisionName) {
        string key = divisionName.ToUpper();
        if (key == "AL" || key == "ACADEMY" || key == "ACADEMY LEAGUE") return Color(0x0085fa);
        if (key == "CL" || key == "CHAMPION" || key == "CHAMPION LEAGUE") return Color(0x7e55ce);
        if (key == "ML" || key == "MASTER" || key == "MASTER LEAGUE") return Color(0xd10057);
        return Color(0x1fbf5c);
    }

    vec4 MleGradientStart() { return Color(0x1fbf5c); }
    vec4 MleGradientEnd() { return Color(0x02bae9); }
}
