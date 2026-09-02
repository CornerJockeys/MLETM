[Setting hidden]
int S_ProdLayoutSchemaVersion = 0;

namespace LayoutMigration {
    const int CurrentSchemaVersion = 2;

    void ApplyIfNeeded() {
        if (S_ProdLayoutSchemaVersion >= CurrentSchemaVersion) return;

        // v2 introduces the larger aspect-locked banner, resolution-aware placement,
        // and the standalone MLE TM logo widget. Apply once, then preserve producer
        // layout changes across normal plugin reloads.
        LayoutState::FitCurrentResolution();
        S_ProdLayoutSchemaVersion = CurrentSchemaVersion;
        trace("MLE TM PROD layout migrated to schema " + tostring(CurrentSchemaVersion));
    }
}
