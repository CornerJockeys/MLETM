namespace PacksManager {
    uint G_UILayersCount;
    dictionary G_Configs;
    array<string> G_EnabledConfigs;

    void LoadConfigs() {
        G_Configs = {};

        const string Root = IO::FromStorageFolder('');

        const array<string>@ Folders = IO::IndexFolder(Root, false);
        for (uint i = 0; i < Folders.Length; i++) {
            const string Path = Folders[i];

            // Get Id
            string Id;
            const array<string> Parts = Path.Split('/');
            for (uint j = Parts.Length - 1; j >= 0; j--) {
                if (Parts[j].Length > 0) {
                    Id = Parts[j];
                    break;
                }
            }
            
            if (IO::FileExists(Path)) {
                trace('Invalid Pack Config: "' + Path + '" is a file');
                continue;
            }

            const string InfoFile = Path::Join(Path, 'info.json');
            if (!IO::FileExists(InfoFile)) {
                trace('Invalid Pack Config: "' + Path + '" has no info.json file');
                continue;
            }

            IO::File File(InfoFile, IO::FileMode::Read);
            if (File.Size() <= 0) {
                trace('Invalid Pack Config: "' + InfoFile + '" is not readable');
                continue;
            }

            const string FileContent = File.ReadToEnd();

            const string InfoFileHash = Crypto::Sha256(FileContent);

            if (C_InterfacesPacksHashes.Find(InfoFileHash) < 0) {
                print('Invalid Pack Config "'+ Id +'": Invalid hash');
                trace('info.json hash: '+ InfoFileHash);
                if (S_DisplayHashWarning) {
                    RenderManager::NotifyWarning('Invalid Pack Config "'+ Id +'": Invalid hash');
                }

                if (!Meta::IsDeveloperMode()) {
                    trace('Invalid Pack Config "'+ Id +'": Invalid hash');
                    continue;
                }
            }

            try {
                const PackConfig Config(Path, FileContent);
                G_Configs[Id] = Config;
            } catch {
                warn('Invalid Pack Config: "'+ Path +'" is an invalid\nException Message: '+ getExceptionInfo());
            }
        }

        if (S_EnabledConfigs.Length > 0) {
            G_EnabledConfigs = S_EnabledConfigs.Split(',');
        }

        for (uint i = 0; i < G_EnabledConfigs.Length; i++) {
            const string Id = G_EnabledConfigs[i];
            if (G_Configs.Exists(Id)) {
                continue;
            }
            
            RenderManager::NotifyWarning("Enabled interfaces " + Id + " has been deleted.");
            G_EnabledConfigs.RemoveAt(i);
        }

        InjectInterfacesIfNeeded();
    }

    void InjectInterfacesIfNeeded() {
        CTrackManiaNetwork@ Network = cast<CTrackManiaNetwork>(GetApp().Network);
        CGameManiaAppPlayground@ ManiaApp = Network.ClientManiaAppPlayground;
        CTrackManiaNetworkServerInfo@ ServerInfo = cast<CTrackManiaNetworkServerInfo>(Network.ServerInfo);

        if (ManiaApp !is null) {
            MwFastBuffer<CGameUILayer@> UILayers = ManiaApp.UILayers;

            dictionary IndexedLayers = GetIndexedUILayers(UILayers);

            for (uint i = 0; i < G_EnabledConfigs.Length; i++) {
                const string Id = G_EnabledConfigs[i];

                const PackConfig@ Config = PacksManager::GetConfig(Id);


                if (!Config.ModeMatch(string(ServerInfo.CurScriptRelName))) {
                    continue;
                }

                for (uint j = 0; j < Config.UnloadModules.Length; j++) {
                    const string ModuleId = Config.UnloadModules[j];

                    if (IndexedLayers.Exists(ModuleId)) {
                        print('Removing UI Layer: "' + ModuleId + '"');
                        CGameUILayer@ Layer = cast<CGameUILayer>(IndexedLayers[ModuleId]);

                        /**
                         * Some UILayer can have Maniascript that can interact with the game, even hidden.
                         * So it's safer to destroy them.
                         */
                        ManiaApp.UILayerDestroy(Layer);
                    }
                }

                for (uint j = 0; j < Config.Layers.Length; j++) {
                    const LayerConfig@ LayerConfig = Config.Layers[j];

                    CGameUILayer@ Layer;
                    if (IndexedLayers.Exists(LayerConfig.Name)) {
                        print('Updating Layer "'+ LayerConfig.Name +'"');
                        @Layer = cast<CGameUILayer>(IndexedLayers[LayerConfig.Name]);
                    } else {
                        print('Creating new Layer "'+ LayerConfig.Name +'"');
                        @Layer = ManiaApp.UILayerCreate();
                    }

                    const string Manialink = LayerConfig.GetManialink();
                    Layer.ManialinkPage = Manialink;
                    Layer.AttachId = LayerConfig.AttachId;
                    Layer.Type = LayerConfig.LayerType;
                }
            }
            G_UILayersCount = UILayers.Length;
        }
    }

    void EnableInterface(const string &in _Id) {
        trace('Enabling Interface: '+ _Id);

        const int Index = G_EnabledConfigs.Find(_Id);
        if (Index >= 0) {
            trace("Can't disable config \""+ _Id +"\": already enabled");
            return;
        }

        G_EnabledConfigs.InsertLast(_Id);
        S_EnabledConfigs = string::Join(G_EnabledConfigs, ',');

        InjectInterfacesIfNeeded();
    }

    void DisableInterface(const string &in _Id) {
        trace('Disabling Interface: '+ _Id);

        const int Index = G_EnabledConfigs.Find(_Id);
        if (Index < 0) {
            trace("Can't disable config \""+ _Id +"\": not enabled");
            return;
        }
        G_EnabledConfigs.RemoveAt(Index);

        S_EnabledConfigs = string::Join(G_EnabledConfigs, ',');
    }

    PackConfig@ GetConfig(const string &in _Id) {
        if (PacksManager::G_Configs.Exists(_Id)) {
            return cast<PackConfig>(PacksManager::G_Configs[_Id]);
        }
        return null;
    }

    dictionary GetIndexedUILayers(MwFastBuffer<CGameUILayer@> _UILayers) {
        dictionary IndexedLayers;

        for (uint i = 0; i < _UILayers.Length; i++) {
            CGameUILayer@ UILayer = _UILayers[i];

            const string Name = GetLayerName(UILayer.ManialinkPage);
            if (Name.Length > 0) {
                IndexedLayers[Name] = @UILayer;
            }
        }
        return IndexedLayers;
    }

    string GetLayerName(const string &in _Manialink) {
        array<string> FirstLines = _Manialink.Split("\n", 5);

        if (FirstLines.Length > 0) {
            for (uint j = 0; j < FirstLines.Length - 1; j++) {
                if (FirstLines[j].Contains('<manialink ')) {
                    string[] match = Regex::Search(FirstLines[j], 'name="(\\w*)"');
                    if (match.Length == 2) {
                        return match[1];
                    }
                }
            }
        }

        return '';
    }

    void Yield() {
        CTrackManiaNetwork@ Network = cast<CTrackManiaNetwork>(GetApp().Network);

        if (Network.ClientManiaAppPlayground !is null) {
            CGameManiaAppPlayground @ManiaApp = Network.ClientManiaAppPlayground;
            MwFastBuffer<CGameUILayer@> UILayers = ManiaApp.UILayers;

            /**
             * Gamemode can inject UILayer at any time
             * IMO, it's better to check count instead of gamemode name or anything else
             */
            if (G_UILayersCount != UILayers.Length) {
                G_UILayersCount = UILayers.Length;
                InjectInterfacesIfNeeded();
            }
        } else {
            G_UILayersCount = 0;
        }
    }
}