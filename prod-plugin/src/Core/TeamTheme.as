class TeamTheme {
    string name;
    string clubTag;
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
        const string &in clubTag,
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
        this.clubTag = clubTag;
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

    vec4 WithAlpha(const vec4 &in color, float alpha) {
        return vec4(color.x, color.y, color.z, Math::Clamp(alpha, 0.0f, 1.0f));
    }

    float Luma(const vec4 &in color) {
        return color.x * 0.299f + color.y * 0.587f + color.z * 0.114f;
    }

    vec4 ReadableTextOn(const vec4 &in background) {
        // Keep white on dark franchise colors, but switch to near-black on bright
        // primaries such as Hive/Sabres where white loses too much contrast.
        return Luma(background) >= 0.58f ? Color(0x11151a) : Color(0xffffff);
    }

    void Add(TeamTheme@ theme) {
        if (theme is null) return;
        Teams[theme.name.ToUpper()] = @theme;
    }

    void Initialize() {
        Teams.DeleteAll();

        @Fallback = TeamTheme(
            "UNKNOWN", "MLE",
            0x30343a, 0xf2f2f2,
            0x30343a, 0xf2f2f2,
            0x30343a, 0xf2f2f2,
            "", "Unknown.png"
        );

        // Official MLE TM franchise palette and club tags. Club tags mirror the same
        // authoritative mapping consumed by the OPS plugin/backend.
        Add(TeamTheme("DODGERS",    "DOD",  0x041e42, 0xe7e9ea, 0xbfbfbf, 0x000666, 0x000666, 0x666666, "assets/teams/Dodgers.png",    "Dodgers.png"));
        Add(TeamTheme("HIVE",       "HIVE", 0xffa000, 0x111111, 0x3f3f3f, 0xff9f00, 0x262626, 0xff5959, "assets/teams/Hive.png",       "Hive.png"));
        Add(TeamTheme("HURRICANES", "HUR",  0x005030, 0xf47321, 0xff6532, 0x006628, 0xbfbfbf, 0x006600, "assets/teams/Hurricanes.png", "Hurricanes.png"));
        Add(TeamTheme("JETS",       "JETS", 0x0a2b58, 0xc7102e, 0xff002a, 0x002766, 0xffffff, 0xff002a, "assets/teams/Jets.png",       "Jets.png"));
        Add(TeamTheme("FLAMES",     "FLUM", 0xc92a06, 0xf6c432, 0xffb232, 0xb22c00, 0xbfbfbf, 0xb22c00, "assets/teams/Flames.png",     "Flames.png"));
        Add(TeamTheme("SABRES",     "SAB",  0xf36a22, 0x111111, 0x3f3f3f, 0xff6532, 0xff3f00, 0xff8259, "assets/teams/Sabres.png",     "Sabres.png"));
        Add(TeamTheme("SPECTRE",    "SPE",  0x58427c, 0x4dcf74, 0x00ff66, 0xd632ff, 0xffffff, 0x00ff66, "assets/teams/Spectre.png",    "Spectre.png"));
        Add(TeamTheme("WIZARDS",    "WIZ",  0x0066b2, 0xfdb927, 0xff9f00, 0x0044b2, 0x666666, 0x0061ff, "assets/teams/Wizards.png",    "Wizards.png"));

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

    string ClubTag(const string &in teamName) {
        return Get(teamName).clubTag;
    }

    vec4 TextOnPrimary(const string &in teamName) {
        return ReadableTextOn(Primary(teamName));
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
