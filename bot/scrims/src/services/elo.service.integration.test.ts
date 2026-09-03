import { afterEach, describe, expect, it, vi } from 'vitest';
import { db } from '../db/index.js';
import { eloFinalizerService } from './elo-finalizer.service.js';
import { eloService } from './elo.service.js';

describe('EloService', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('calculateNewRating (legacy regression helper)', () => {
    it('keeps the old helper stable without using it for persistence', () => {
      expect(eloService.calculateNewRating(1000, 1000, 1)).toBe(1016);
      expect(eloService.calculateNewRating(1000, 1200, 1)).toBe(1024);
      expect(eloService.calculateNewRating(1200, 1000, 0)).toBe(1176);
    });
  });

  describe('persisted round recovery', () => {
    it('reconstructs canonical round orders from stored round_points', async () => {
      vi.spyOn(db, 'query').mockResolvedValue({
        rows: [
          { map_order: 1, player_id: 1, round_points: [4, 1] },
          { map_order: 1, player_id: 2, round_points: [2, 4] },
          { map_order: 1, player_id: 3, round_points: [3, 2] },
          { map_order: 1, player_id: 4, round_points: [1, 3] },
        ],
        rowCount: 4,
        command: 'SELECT',
        oid: 0,
        fields: [],
      } as any);

      await expect(eloService.buildPersistedEloRounds(42)).resolves.toEqual([
        {
          round: 1,
          results: [
            { playerId: 1, finishPosition: 1 },
            { playerId: 3, finishPosition: 2 },
            { playerId: 2, finishPosition: 3 },
            { playerId: 4, finishPosition: 4 },
          ],
        },
        {
          round: 2,
          results: [
            { playerId: 2, finishPosition: 1 },
            { playerId: 4, finishPosition: 2 },
            { playerId: 3, finishPosition: 3 },
            { playerId: 1, finishPosition: 4 },
          ],
        },
      ]);
    });

    it('routes manual/admin processMatch retries through the batched finalizer', async () => {
      const rounds = [
        {
          round: 1,
          results: [
            { playerId: 1, finishPosition: 1 },
            { playerId: 2, finishPosition: 2 },
            { playerId: 3, finishPosition: 3 },
            { playerId: 4, finishPosition: 4 },
          ],
        },
      ];

      vi.spyOn(eloService, 'buildPersistedEloRounds').mockResolvedValue(rounds);
      const finalize = vi.spyOn(eloFinalizerService, 'finalize').mockResolvedValue({
        scrimId: 42,
        skipped: false,
        players: [],
      });

      await eloService.processMatch(42);

      expect(finalize).toHaveBeenCalledWith(42, rounds);
    });

    it('rejects persisted tied point orders rather than guessing', async () => {
      vi.spyOn(db, 'query').mockResolvedValue({
        rows: [
          { map_order: 1, player_id: 1, round_points: [4] },
          { map_order: 1, player_id: 2, round_points: [3] },
          { map_order: 1, player_id: 3, round_points: [0] },
          { map_order: 1, player_id: 4, round_points: [0] },
        ],
        rowCount: 4,
        command: 'SELECT',
        oid: 0,
        fields: [],
      } as any);

      await expect(eloService.buildPersistedEloRounds(42)).rejects.toThrow(
        'Ambiguous Elo finish order',
      );
    });
  });
});
