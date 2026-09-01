class ProdRankEntry {
    string name;
    string team;
    string timeText;
    int teamSlot;
    bool respawn;
    bool spectated;

    ProdRankEntry(const string &in name, int teamSlot, const string &in timeText) {
        this.name = name;
        this.teamSlot = teamSlot;
        this.team = teamSlot == 0 ? MatchState::TeamAName : MatchState::TeamBName;
        this.timeText = timeText;
        respawn = false;
        spectated = false;
    }
}

namespace LiveRankingState {
    array<ProdRankEntry@> Entries;
    uint SimulationStep = 0;

    void Reset() {
        Entries.RemoveRange(0, Entries.Length);

        Entries.InsertLast(ProdRankEntry("SPAMMIEJ", 0, "0:31.728"));
        Entries.InsertLast(ProdRankEntry("MASSAAA", 1, "+0.084"));
        Entries.InsertLast(ProdRankEntry("QUISBY", 0, "+0.216"));
        Entries.InsertLast(ProdRankEntry("SHORTY.DE", 1, "+0.381"));
        Entries.InsertLast(ProdRankEntry("LINKTM_", 0, "+0.553"));
        Entries.InsertLast(ProdRankEntry("SCRAPIE98", 1, "+0.912"));

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
        auto entry = Entries[fromIndex];
        Entries.RemoveAt(fromIndex);
        Entries.InsertAt(toIndex, entry);
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
        trace("MLE TM PROD live ranking simulation initialized.");
    }
}
