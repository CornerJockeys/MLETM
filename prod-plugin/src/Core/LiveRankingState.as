class ProdRankEntry {
    string identity;
    string name;
    string team;
    string timeText;
    int teamSlot;
    bool respawn;
    bool spectated;

    bool rankInitialized;
    bool transitionActive;
    bool losingPosition;
    float visualRank;
    float fromRank;
    float targetRank;
    uint transitionStartedAt;

    ProdRankEntry(const string &in name, int teamSlot, const string &in timeText, const string &in identity = "") {
        this.identity = identity.Length > 0 ? identity : name;
        this.name = name;
        this.teamSlot = teamSlot;
        this.team = teamSlot == 0 ? MatchState::TeamAName : MatchState::TeamBName;
        this.timeText = timeText;
        respawn = false;
        spectated = false;

        rankInitialized = false;
        transitionActive = false;
        losingPosition = false;
        visualRank = 0.0f;
        fromRank = 0.0f;
        targetRank = 0.0f;
        transitionStartedAt = 0;
    }
}

namespace LiveRankingState {
    array<ProdRankEntry@> Entries;
    uint SimulationStep = 0;

    const uint TransitionGrowMs = 90;
    const uint TransitionMoveMs = 300;
    const uint TransitionShrinkMs = 130;
    const uint TransitionTotalMs = TransitionGrowMs + TransitionMoveMs + TransitionShrinkMs;
    const float LossScale = 1.12f;

    float Smooth(float t) {
        t = Math::Clamp(t, 0.0f, 1.0f);
        return t * t * (3.0f - 2.0f * t);
    }

    float CurrentVisualRank(ProdRankEntry@ entry) {
        if (entry is null) return 0.0f;
        if (!entry.rankInitialized) return entry.targetRank;
        if (!entry.transitionActive) return entry.targetRank;

        uint elapsed = Time::Now - entry.transitionStartedAt;
        if (elapsed >= TransitionTotalMs) {
            entry.visualRank = entry.targetRank;
            entry.transitionActive = false;
            entry.losingPosition = false;
            return entry.targetRank;
        }

        float moveT;
        if (entry.losingPosition) {
            if (elapsed <= TransitionGrowMs) {
                moveT = 0.0f;
            } else {
                moveT = float(elapsed - TransitionGrowMs) / float(TransitionMoveMs);
            }
        } else {
            moveT = float(elapsed) / float(TransitionMoveMs);
        }

        moveT = Smooth(moveT);
        entry.visualRank = entry.fromRank + (entry.targetRank - entry.fromRank) * moveT;
        return entry.visualRank;
    }

    float CurrentScale(ProdRankEntry@ entry) {
        if (entry is null || !entry.transitionActive || !entry.losingPosition) return 1.0f;

        uint elapsed = Time::Now - entry.transitionStartedAt;
        if (elapsed < TransitionGrowMs) {
            return 1.0f + (LossScale - 1.0f) * Smooth(float(elapsed) / float(TransitionGrowMs));
        }

        uint shrinkStart = TransitionGrowMs + TransitionMoveMs;
        if (elapsed < shrinkStart) return LossScale;
        if (elapsed >= TransitionTotalMs) return 1.0f;

        float t = float(elapsed - shrinkStart) / float(TransitionShrinkMs);
        return LossScale + (1.0f - LossScale) * Smooth(t);
    }

    bool IsLossAnimationActive(ProdRankEntry@ entry) {
        if (entry is null) return false;
        CurrentVisualRank(entry);
        return entry.transitionActive && entry.losingPosition;
    }

    void SetImmediateRank(ProdRankEntry@ entry, uint rankIndex) {
        if (entry is null) return;
        entry.rankInitialized = true;
        entry.transitionActive = false;
        entry.losingPosition = false;
        entry.visualRank = float(rankIndex);
        entry.fromRank = float(rankIndex);
        entry.targetRank = float(rankIndex);
        entry.transitionStartedAt = 0;
    }

    void SetTargetRank(ProdRankEntry@ entry, uint rankIndex) {
        if (entry is null) return;

        float nextRank = float(rankIndex);
        if (!entry.rankInitialized) {
            SetImmediateRank(entry, rankIndex);
            return;
        }

        float currentRank = CurrentVisualRank(entry);
        if (Math::Abs(currentRank - nextRank) < 0.001f) {
            entry.targetRank = nextRank;
            return;
        }

        entry.fromRank = currentRank;
        entry.targetRank = nextRank;
        entry.visualRank = currentRank;
        entry.losingPosition = nextRank > currentRank;
        entry.transitionActive = true;
        entry.transitionStartedAt = Time::Now;
    }

    void RefreshTargetRanks() {
        for (uint i = 0; i < Entries.Length; i++) {
            SetTargetRank(Entries[i], i);
        }
    }

    void Reset() {
        Entries.RemoveRange(0, Entries.Length);

        Entries.InsertLast(ProdRankEntry("SPAMMIEJ", 0, "0:31.728"));
        Entries.InsertLast(ProdRankEntry("MASSAAA", 1, "+0.084"));
        Entries.InsertLast(ProdRankEntry("QUISBY", 0, "+0.216"));
        Entries.InsertLast(ProdRankEntry("SHORTY.DE", 1, "+0.381"));
        Entries.InsertLast(ProdRankEntry("LINKTM_", 0, "+0.553"));
        Entries.InsertLast(ProdRankEntry("SCRAPIE98", 1, "+0.912"));

        for (uint i = 0; i < Entries.Length; i++) SetImmediateRank(Entries[i], i);
        if (Entries.Length > 2) Entries[2].spectated = true;
        SimulationStep = 0;
    }

    void SyncTeams() {
        for (uint i = 0; i < Entries.Length; i++) {
            Entries[i].team = Entries[i].teamSlot == 0 ? MatchState::TeamAName : MatchState::TeamBName;
        }
    }

    void MoveEntry(uint fromIndex, uint toIndex) {
        if (fromIndex >= Entries.Length || toIndex >= Entries.Length || fromIndex == toIndex) return;

        // Resolve every active transition before changing the target order. This means
        // repeated checkpoint updates start from the row's actual on-screen position
        // instead of snapping back to its previous target.
        for (uint i = 0; i < Entries.Length; i++) CurrentVisualRank(Entries[i]);

        auto entry = Entries[fromIndex];
        Entries.RemoveAt(fromIndex);
        Entries.InsertAt(toIndex, entry);
        RefreshTargetRanks();
    }

    void ApplySnapshot(array<ProdRankEntry@>@ snapshot) {
        if (snapshot is null || snapshot.Length == 0) return;

        dictionary existing;
        for (uint i = 0; i < Entries.Length; i++) {
            auto current = Entries[i];
            if (current is null) continue;
            CurrentVisualRank(current);
            existing[current.identity] = @current;
        }

        array<ProdRankEntry@> nextEntries;
        for (uint i = 0; i < snapshot.Length && i < 6; i++) {
            auto incoming = snapshot[i];
            if (incoming is null) continue;

            ProdRankEntry@ entry = null;
            if (existing.Get(incoming.identity, @entry) && entry !is null) {
                entry.name = incoming.name;
                entry.teamSlot = incoming.teamSlot;
                entry.timeText = incoming.timeText;
                entry.respawn = incoming.respawn;
                entry.team = incoming.teamSlot == 0 ? MatchState::TeamAName : MatchState::TeamBName;
            } else {
                @entry = incoming;
                SetImmediateRank(entry, nextEntries.Length);
            }
            nextEntries.InsertLast(entry);
        }

        Entries = nextEntries;
        RefreshTargetRanks();
        SyncTeams();
    }

    void SimulatePlacementChange() {
        if (Entries.Length < 4) return;

        uint mode = SimulationStep % 4;
        if (mode == 0) {
            MoveEntry(2, 0);
        } else if (mode == 1) {
            MoveEntry(0, 3);
        } else if (mode == 2) {
            MoveEntry(4, 1);
        } else {
            MoveEntry(3, 5);
        }

        SimulationStep++;
    }

    void ToggleRespawn() {
        if (Entries.Length == 0) return;
        uint index = SimulationStep % Entries.Length;
        Entries[index].respawn = !Entries[index].respawn;
    }

    void NextSpectated() {
        if (Entries.Length == 0) return;

        int current = -1;
        for (uint i = 0; i < Entries.Length; i++) {
            if (Entries[i].spectated) {
                current = int(i);
                Entries[i].spectated = false;
                break;
            }
        }

        uint next = current < 0 ? 0 : (uint(current + 1) % Entries.Length);
        Entries[next].spectated = true;
    }

    void Initialize() {
        Reset();
        trace("MLE TM PROD live ranking state initialized.");
    }
}
