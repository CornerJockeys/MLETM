namespace AssetReloadGuard {
    bool Pending = false;

    void Request() {
        Pending = true;
        OverlayTheme::Status = "Asset reload queued";
    }

    void Update() {
        if (!Pending) return;
        Pending = false;

        // UI textures may still be referenced by the active draw frame when a button
        // is clicked. Reload only from Update(), between presentation frames, so the
        // texture cache is never destroyed from inside a render callback.
        OverlayTheme::Reload();
        BrandingLogo::Reload();
    }
}
