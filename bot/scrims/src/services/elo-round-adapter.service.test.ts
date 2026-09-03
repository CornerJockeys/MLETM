import { afterEach, describe, expect, it, vi } from 'vitest';
import { db } from '../db/index.js';
import { eloRoundAdapterService } from './elo-round-adapter.service.js';
import type { RawReplay } from './replay-submission.service.js';

function mockPlayerResolution(ids: Record<string, number>) {
  return vi.spyOn(db, 'query').mockImplementation(async (_text: string, params?: unknown[]) => {
    const key = String(params?.[0] ?? '');
    const id = ids[key];
    return {
      rows: id ? [{ id }] : [],
      rowCount: id ? 1 : 0,
      command: 'SELECT',
      oid: 0,
      fields: [],
    } as any;
  });
}

describe('EloRoundAdapterService', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('builds sequential finishing orders from per-round points', async () => {
    mockPlayerResolution({ a: 1, b: 2, c: 3, d: 4 });

    const replay: RawReplay = {
      maps: [
        {
          name: 'Test Map',
          rounds: [
            {
              roundNumber: 0,
              players: [
                { id: 'a', name: 'A', roundPoints: 4 },
                { id: 'b', name: 'B', roundPoints: 2 },
                { id: 'c', name: 'C', roundPoints: 3 },
                { id: 'd', name: 'D', roundPoints: 1 },
              ],
            },
            {
              roundNumber: 1,
              players: [
                { id: 'a', name: 'A', roundPoints: 1 },
                { id: 'b', name: 'B', roundPoints: 4 },
                { id: 'c', name: 'C', roundPoints: 2 },
                { id: 'd', name: 'D', roundPoints: 3 },
              ],
            },
          ],
        },
      ],
    };

    await expect(eloRoundAdapterService.fromVerifiedReplay(replay)).resolves.toEqual([
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

  it('rejects an ambiguous tied finishing order instead of guessing', async () => {
    mockPlayerResolution({ a: 1, b: 2, c: 3, d: 4 });

    const replay: RawReplay = {
      rounds: [
        {
          players: [
            { id: 'a', name: 'A', roundPoints: 4 },
            { id: 'b', name: 'B', roundPoints: 3 },
            { id: 'c', name: 'C', roundPoints: 0 },
            { id: 'd', name: 'D', roundPoints: 0 },
          ],
        },
      ],
    };

    await expect(eloRoundAdapterService.fromVerifiedReplay(replay)).rejects.toThrow(
      'Ambiguous Elo finish order',
    );
  });

  it('ignores zero-score noncompetitive rounds', async () => {
    mockPlayerResolution({ a: 1, b: 2, c: 3, d: 4 });

    const replay: RawReplay = {
      rounds: [
        {
          players: [
            { id: 'a', name: 'A', roundPoints: 0 },
            { id: 'b', name: 'B', roundPoints: 0 },
            { id: 'c', name: 'C', roundPoints: 0 },
            { id: 'd', name: 'D', roundPoints: 0 },
          ],
        },
        {
          players: [
            { id: 'a', name: 'A', roundPoints: 4 },
            { id: 'b', name: 'B', roundPoints: 3 },
            { id: 'c', name: 'C', roundPoints: 2 },
            { id: 'd', name: 'D', roundPoints: 1 },
          ],
        },
      ],
    };

    const rounds = await eloRoundAdapterService.fromVerifiedReplay(replay);
    expect(rounds).toHaveLength(1);
    expect(rounds[0].round).toBe(1);
  });
});
