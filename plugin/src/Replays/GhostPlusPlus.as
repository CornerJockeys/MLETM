namespace GhostPlusPlus {
    bool Available = false;

    void Initialize() {
#if DEPENDENCY_GHOSTS_PP
        Available = true;

        // Call one exported Ghosts++ function during startup so this is more than a
        // compile-time dependency check. We do not change replay behavior yet.
        bool spectatingGhost = Ghosts_PP::IsSpectatingGhost();
        trace(
            "MLE TM Ghosts++ integration ready. Spectating ghost: "
            + (spectatingGhost ? "yes" : "no")
        );
#else
        Available = false;
        trace("MLE TM Ghosts++ integration unavailable; built-in replay controls remain active.");
#endif
    }

    bool IsAvailable() {
        return Available;
    }

    bool IsSpectatingGhost() {
#if DEPENDENCY_GHOSTS_PP
        return Ghosts_PP::IsSpectatingGhost();
#else
        return false;
#endif
    }
}
