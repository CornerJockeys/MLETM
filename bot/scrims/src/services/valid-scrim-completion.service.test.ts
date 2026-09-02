import { afterEach, describe, expect, it, vi } from 'vitest';
import { scrimPointsService } from './scrim-points.service.js';
import { scrimService } from './scrim.service.js';
import { ValidScrimCompletionService } from './valid-scrim-completion.service.js';

function makeScrim(status: 'active' | 'completed') {
  return {
    id: 10,
    scrim_uid: 'SCRIM-10',
    league: 'Academy' as const,
    status,
    match_type: 'QUEUE' as const,
    sprocket_match_parent_id: null,
    sprocket_match_id: null,
    winner_team: null,
    elo_processed: false,
    created_at: new Date(),
    checkin_deadline: null,
    completed_at: status === 'completed' ? new Date() : null,
  };
}

describe('ValidScrimCompletionService', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('completes an active, fully checked-in scrim and awards five points', async () => {
    vi.spyOn(scrimService, 'getById').mockResolvedValue(makeScrim('active'));
    vi.spyOn(scrimService, 'getScrimPlayers').mockResolvedValue([
      { id: 1, scrim_id: 10, player_id: 101, checked_in: true, checkin_at: new Date() },
      { id: 2, scrim_id: 10, player_id: 102, checked_in: true, checkin_at: new Date() },
    ]);
    const completeScrim = vi.spyOn(scrimService, 'completeScrim').mockResolvedValue();
    const award = vi
      .spyOn(scrimPointsService, 'awardValidScrimCompletion')
      .mockResolvedValue([
        { playerId: 101, pointsBefore: 0, pointsAfter: 5, delta: 5 },
        { playerId: 102, pointsBefore: 25, pointsAfter: 30, delta: 5 },
      ]);

    const result = await new ValidScrimCompletionService().complete(10);

    expect(completeScrim).toHaveBeenCalledWith(10);
    expect(award).toHaveBeenCalledWith(10, [101, 102], 5);
    expect(result.awardedPlayerIds).toEqual([101, 102]);
    expect(result.pointsPerPlayer).toBe(5);
    expect(result.alreadyCompleted).toBe(false);
  });

  it('can safely retry an already-completed scrim without re-completing it', async () => {
    vi.spyOn(scrimService, 'getById').mockResolvedValue(makeScrim('completed'));
    vi.spyOn(scrimService, 'getScrimPlayers').mockResolvedValue([
      { id: 1, scrim_id: 10, player_id: 101, checked_in: true, checkin_at: new Date() },
    ]);
    const completeScrim = vi.spyOn(scrimService, 'completeScrim').mockResolvedValue();
    const award = vi
      .spyOn(scrimPointsService, 'awardValidScrimCompletion')
      .mockResolvedValue([]);

    const result = await new ValidScrimCompletionService().complete(10);

    expect(completeScrim).not.toHaveBeenCalled();
    expect(award).toHaveBeenCalledWith(10, [101], 5);
    expect(result.awardedPlayerIds).toEqual([]);
    expect(result.alreadyCompleted).toBe(true);
  });

  it('rejects completion when any player has not checked in', async () => {
    vi.spyOn(scrimService, 'getById').mockResolvedValue(makeScrim('active'));
    vi.spyOn(scrimService, 'getScrimPlayers').mockResolvedValue([
      { id: 1, scrim_id: 10, player_id: 101, checked_in: true, checkin_at: new Date() },
      { id: 2, scrim_id: 10, player_id: 102, checked_in: false, checkin_at: null },
    ]);

    await expect(new ValidScrimCompletionService().complete(10)).rejects.toThrow(
      'not all players checked in',
    );
  });
});
