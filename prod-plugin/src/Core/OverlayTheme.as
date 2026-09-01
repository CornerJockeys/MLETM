class TeamLogoAsset {
    string team;
    string sourcePath;
    bool usingOverride;
    UI::Texture@ texture;

    TeamLogoAsset(const string &in team) {
        this.team = team;
        sourcePath = "";
        usingOverride = false;
        @texture = null;
    }
}

namespace OverlayTheme {
    const string StorageRootName = "Overlay";
    const string TeamFolderName = "Overlay/teams";
    const string ThemeFileName = "Overlay/theme.json";
    const string ReadmeFileName = "Overlay/README.txt";

    dictionary Logos;
    string Status = "Not initialized";
    bool LastReloadOk = false;

    string StorageRoot() { return IO::FromStorageFolder(StorageRootName); }
    string TeamFolder() { return IO::FromStorageFolder(TeamFolderName); }
    string ThemeFile() { return IO::FromStorageFolder(ThemeFileName); }
    string ReadmeFile() { return IO::FromStorageFolder(ReadmeFileName); }

    bool IsHexDigit(const string &in c) {
        string x = c.ToLower();
        return x == "0" || x == "1" || x == "2" || x == "3" || x == "4"
            || x == "5" || x == "6" || x == "7" || x == "8" || x == "9"
            || x == "a" || x == "b" || x == "c" || x == "d" || x == "e" || x == "f";
    }

    uint HexDigit(const string &in c) {
        string x = c.ToLower();
        if (x == "0") return 0;
        if (x == "1") return 1;
        if (x == "2") return 2;
        if (x == "3") return 3;
        if (x == "4") return 4;
        if (x == "5") return 5;
        if (x == "6") return 6;
        if (x == "7") return 7;
        if (x == "8") return 8;
        if (x == "9") return 9;
        if (x == "a") return 10;
        if (x == "b") return 11;
        if (x == "c") return 12;
        if (x == "d") return 13;
        if (x == "e") return 14;
        if (x == "f") return 15;
        return 0;
    }

    uint ParseHexPair(const string &in value, uint start) {
        return HexDigit(value.SubStr(start, 1)) * 16 + HexDigit(value.SubStr(start + 1, 1));
    }

    bool TryParseColor(const string &in raw, vec4 &out color) {
        string value = raw;
        if (value.StartsWith("#")) value = value.SubStr(1);
        if (value.Length != 6) return false;

        for (uint i = 0; i < value.Length; i++) {
            if (!IsHexDigit(value.SubStr(i, 1))) return false;
        }

        uint r = ParseHexPair(value, 0);
        uint g = ParseHexPair(value, 2);
        uint b = ParseHexPair(value, 4);
        color = vec4(float(r) / 255.0f, float(g) / 255.0f, float(b) / 255.0f, 1.0f);
        return true;
    }

    string DefaultThemeJson() {
        return "{\n"
            + "  \"schemaVersion\": 1,\n"
            + "  \"notes\": \"Optional PROD presentation overrides. Delete values or this file to use bundled MLE defaults.\",\n"
            + "  \"teams\": {\n"
            + "    \"DODGERS\":    { \"primary\": \"#041e42\", \"secondary\": \"#e7e9ea\", \"racingStripe2\": \"#666666\" },\n"
            + "    \"HIVE\":       { \"primary\": \"#ffa000\", \"secondary\": \"#111111\", \"racingStripe2\": \"#ff5959\" },\n"
            + "    \"HURRICANES\": { \"primary\": \"#005030\", \"secondary\": \"#f47321\", \"racingStripe2\": \"#006600\" },\n"
            + "    \"JETS\":       { \"primary\": \"#0a2b58\", \"secondary\": \"#c7102e\", \"racingStripe2\": \"#ff002a\" },\n"
            + "    \"FLAMES\":     { \"primary\": \"#c92a06\", \"secondary\": \"#f6c432\", \"racingStripe2\": \"#b22c00\" },\n"
            + "    \"SABRES\":     { \"primary\": \"#f36a22\", \"secondary\": \"#111111\", \"racingStripe2\": \"#ff8259\" },\n"
            + "    \"SPECTRE\":    { \"primary\": \"#58427c\", \"secondary\": \"#4dcf74\", \"racingStripe2\": \"#00ff66\" },\n"
            + "    \"WIZARDS\":    { \"primary\": \"#0066b2\", \"secondary\": \"#fdb927\", \"racingStripe2\": \"#0061ff\" }\n"
            + "  }\n"
            + "}\n";
    }

    string DefaultReadme() {
        return "MLE TM PROD - Overlay Overrides\n"
            + "================================\n\n"
            + "This folder is intentionally user-editable for authorized production workflows.\n\n"
            + "teams/\n"
            + "  Drop a PNG named exactly Dodgers.png, Hive.png, Hurricanes.png, Jets.png,\n"
            + "  Flames.png, Sabres.png, Spectre.png, or Wizards.png to override that team's\n"
            + "  bundled logo. Transparent PNGs are recommended.\n\n"
            + "theme.json\n"
            + "  Optional team-color overrides. Invalid/missing values fall back to bundled\n"
            + "  MLE defaults. Reload from the PROD control panel after editing.\n\n"
            + "The plugin is designed to fail safe: removing this folder restores bundled assets.\n";
    }

    void WriteTextFileIfMissing(const string &in path, const string &in contents) {
        if (IO::FileExists(path)) return;
        IO::File file(path, IO::FileMode::Write);
        auto lines = contents.Split("\n");
        for (uint i = 0; i < lines.Length; i++) file.WriteLine(lines[i]);
        file.Close();
    }

    void EnsureStorage() {
        string root = StorageRoot();
        if (!IO::FolderExists(root)) IO::CreateFolder(root, true);

        string teams = TeamFolder();
        if (!IO::FolderExists(teams)) IO::CreateFolder(teams, true);

        WriteTextFileIfMissing(ThemeFile(), DefaultThemeJson());
        WriteTextFileIfMissing(ReadmeFile(), DefaultReadme());
    }

    void ResetThemeColorsToBundled() {
        // Rebuild the palette rather than trying to remember prior overrides.
        TeamThemes::Initialize();
        MatchState::SyncFromSettings();
    }

    void ApplyTeamColorOverride(const string &in teamName, Json::Value@ value) {
        if (value is null || value.GetType() != Json::Type::Object) return;
        auto theme = TeamThemes::Get(teamName);
        if (theme is null || theme is TeamThemes::Fallback) return;

        vec4 parsed;
        if (value.HasKey("primary") && TryParseColor(string(value["primary"]), parsed)) {
            theme.homePrimary = parsed;
        }
        if (value.HasKey("secondary") && TryParseColor(string(value["secondary"]), parsed)) {
            theme.homeSecondary = parsed;
        }
        if (value.HasKey("racingStripe2") && TryParseColor(string(value["racingStripe2"]), parsed)) {
            theme.alternateSecondary = parsed;
        }
    }

    bool LoadThemeJson() {
        ResetThemeColorsToBundled();
        if (!S_EnableLocalThemeOverrides) {
            Status = "Local overrides disabled; bundled theme active";
            return true;
        }
        if (!IO::FileExists(ThemeFile())) return true;

        try {
            IO::File file(ThemeFile(), IO::FileMode::Read);
            string raw = file.ReadToEnd();
            file.Close();

            auto root = Json::Parse(raw);
            if (root.GetType() != Json::Type::Object) {
                Status = "theme.json root must be an object; using bundled colors";
                return false;
            }

            if (!root.HasKey("teams") || root["teams"].GetType() != Json::Type::Object) return true;
            auto teams = root["teams"];
            auto names = TeamThemes::Teams.GetKeys();
            for (uint i = 0; i < names.Length; i++) {
                string name = names[i];
                if (teams.HasKey(name)) ApplyTeamColorOverride(name, teams[name]);
            }
            MatchState::SyncFromSettings();
            return true;
        } catch {
            warn("MLE TM PROD theme reload failed: " + getExceptionInfo());
            Status = "theme.json parse failed; using bundled colors";
            ResetThemeColorsToBundled();
            return false;
        }
    }

    void ClearLogoCache() {
        Logos.DeleteAll();
    }

    UI::Texture@ TryLoadTexture(const string &in path, const string &in teamName) {
        if (path.Length == 0) return null;
        try {
            return UI::LoadTexture(path);
        } catch {
            warn("MLE TM PROD failed to load logo for " + teamName + " from " + path + ": " + getExceptionInfo());
            return null;
        }
    }

    TeamLogoAsset@ GetLogoAsset(const string &in teamName) {
        string key = teamName.ToUpper();
        TeamLogoAsset@ asset = null;
        if (Logos.Get(key, @asset) && asset !is null) return asset;

        @asset = TeamLogoAsset(key);
        auto team = TeamThemes::Get(key);
        string overridePath = IO::FromStorageFolder("Overlay/teams/" + team.overrideLogoFile);

        if (S_EnableLocalThemeOverrides && IO::FileExists(overridePath)) {
            @asset.texture = TryLoadTexture(overridePath, key);
            if (asset.texture !is null) {
                asset.sourcePath = overridePath;
                asset.usingOverride = true;
            }
        }

        // Packaged plugin assets live in Openplanet's virtual plugin filesystem, so do
        // not test them with IO::FileExists. Attempt the load directly and fail safe.
        if (asset.texture is null && team.bundledLogoPath.Length > 0) {
            @asset.texture = TryLoadTexture(team.bundledLogoPath, key);
            if (asset.texture !is null) asset.sourcePath = team.bundledLogoPath;
        }

        Logos[key] = @asset;
        return asset;
    }

    UI::Texture@ GetTeamLogo(const string &in teamName) {
        auto asset = GetLogoAsset(teamName);
        return asset is null ? null : asset.texture;
    }

    bool IsUsingLogoOverride(const string &in teamName) {
        auto asset = GetLogoAsset(teamName);
        return asset !is null && asset.usingOverride;
    }

    void Reload() {
        EnsureStorage();
        ClearLogoCache();
        bool themeOk = LoadThemeJson();
        LastReloadOk = themeOk;
        if (themeOk && S_EnableLocalThemeOverrides) Status = "Theme loaded; bundled fallbacks ready";
        trace("MLE TM PROD overlay theme reloaded: " + Status);
    }

    void OpenFolder() {
        EnsureStorage();
        OpenExplorerPath(StorageRoot());
    }

    void Initialize() {
        EnsureStorage();
        Reload();
    }
}
