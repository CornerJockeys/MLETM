class PackConfig {
    string Name;
    string Author;
    string Version;
    array<string> Modes;
    array<LayerConfig> Layers;
    array<string> UnloadModules;

    PackConfig() {}

    PackConfig(const string &in _ParentPath, const string &in _Json) {
        const Json::Value@ Data = Json::Parse(_Json);

        Name = Data['Name'];
        Author = Data['Author'];
        Version = Data['Version'];

        if (Data.HasKey('Modes') && Data['Modes'].GetType() == Json::Type::Array) {
            for (uint i = 0; i < Data['Modes'].Length; i++) {
                Modes.InsertLast(Data['Modes'][i]);
            }
        }

        if (Data.HasKey('Layers') && Data['Layers'].GetType() == Json::Type::Array) {
            for (uint i = 0; i < Data['Layers'].Length; i++) {
                try {
                    const LayerConfig LayerConfig(_ParentPath, Data['Layers'][i]);

                    Layers.InsertLast(LayerConfig);
                } catch {
                    warn("Can't load layer \""+ i +"\" of Interface Config: \""+ Name +"\"\nException Message: " + getExceptionInfo());
                }
            }
        }

        if (Data.HasKey('UnloadModules') && Data['UnloadModules'].GetType() == Json::Type::Array) {
            for (uint i = 0; i < Data['UnloadModules'].Length; i++) {
                UnloadModules.InsertLast(Data['UnloadModules'][i]);
            }
        }
    }

    string getPrettyModes() const {
        if (Modes.Find('any') >= 0) return 'any';

        const string Pattern = '(?:.*(?:/|\\\\|^))(.*)\\.Script\\.txt';

        string Result;

        for (uint i = 0; i < Modes.Length; i++) {
            if (i > 0) Result += '\n';

            const string Mode = Modes[i];

            const array<string> Matches = Regex::Match(Mode, Pattern);

            if (Matches.Length > 1) {
                string Match = Matches[1];
                
                if (Match.Contains('TM_')) {
                    array<string> Exploded = Match.Split('_');               
                    Result += Exploded[1];
                } else {
                    Result += Match;
                }
            }
        }

        return Result;
    }

    bool ModeMatch(const string &in _SearchedMode) const {
        const string SearchedMode = _SearchedMode.ToLower();
        for (uint i = 0; i < Modes.Length; i++) {
            const string Mode = Modes[i].ToLower();
            if (Mode == "any" || Mode == SearchedMode) return true;
        }

        return false;
    }
}