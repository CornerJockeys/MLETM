class LayerConfig {
    string Name;
    string Path;
    string Hash;

    CGameUILayer::EUILayerType LayerType = CGameUILayer::EUILayerType::Normal;
    string AttachId = '';

    LayerConfig() {}

    LayerConfig(const string &in _ParentPath, const Json::Value &in _Data) {
        Path = Path::Join(_ParentPath, _Data['Path']);
        Hash = _Data['Hash'];
        
        const string Manialink = GetManialink();
        Name = PacksManager::GetLayerName(Manialink);

        if (Name.Length == 0) {
            throw('Can\'t find Manialink name');
        }

        if (_Data.HasKey('LayerType') && _Data['LayerType'].GetType() == Json::Type::String) {
            LayerType = CastEUILayerType(_Data['LayerType']);
        }

        if (_Data.HasKey('AttachId') && _Data['AttachId'].GetType() == Json::Type::String) {
            AttachId = _Data['AttachId'];
        }
    }

    string GetManialink() const {
        if (!IO::FileExists(Path)) {
            throw('File doesn\'t exists: "'+ Path +'"');
        }

        IO::File File(Path, IO::FileMode::Read);
        const string Manialink = File.ReadToEnd();

        const string FileHash = Crypto::Sha256(Manialink);

        if (Hash != FileHash) {
            print('Cannot load layer "'+ Path +'": Invalid hash');
            trace('info.json Layer hash: '+ Hash);
            trace('file hash: '+ FileHash);
            if (S_DisplayHashWarning) {
                RenderManager::NotifyWarning('Cannot load layer "'+ Path +'": Invalid hash');
            }

            if (!Meta::IsDeveloperMode()) {
                throw('Cannot load layer "'+ Path +'": Invalid hash');   
            }
        }

        return Manialink;
    }

    CGameUILayer::EUILayerType CastEUILayerType(const string &in _LayerType) {
        if (_LayerType == 'Normal') return CGameUILayer::EUILayerType::Normal;
        if (_LayerType == 'ScoresTable') return CGameUILayer::EUILayerType::ScoresTable;
        if (_LayerType == 'ScreenIn3d') return CGameUILayer::EUILayerType::ScreenIn3d;
        if (_LayerType == 'AltMenu') return CGameUILayer::EUILayerType::AltMenu;
        if (_LayerType == 'Markers') return CGameUILayer::EUILayerType::Markers;
        if (_LayerType == 'CutScene') return CGameUILayer::EUILayerType::CutScene;
        if (_LayerType == 'InGameMenu') return CGameUILayer::EUILayerType::InGameMenu;
        if (_LayerType == 'EditorPlugin') return CGameUILayer::EUILayerType::EditorPlugin;
        if (_LayerType == 'ManiaplanetPlugin') return CGameUILayer::EUILayerType::ManiaplanetPlugin;
        if (_LayerType == 'ManiaplanetMenu') return CGameUILayer::EUILayerType::ManiaplanetMenu;
        if (_LayerType == 'LoadingScreen') return CGameUILayer::EUILayerType::LoadingScreen;

        throw('Invalid EUILayerType: '+ _LayerType);
        return CGameUILayer::EUILayerType::Normal;
    }
}