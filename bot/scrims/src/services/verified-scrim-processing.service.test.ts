import { afterEach, describe, expect, it, vi } from 'vitest';
import { replaySubmissionService } from './replay-submission.service.js';
import { validScrimCompletionService } from './valid-scrim-completion.service.js';
import { eloRoundAdapterService } from './elo-round-adapter.service.js';
import { eloFinalizerService } from './elo-finalizer.service.js';
import { verifiedScrimProcessingService } from './verified-scrim-processing.service.js';

describe('VerifiedScrimProcessingService', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('runs replay save, canonical completion, round adaptation, and Elo finalization in order', async () => {
    const replayResult = {
      alreadyProcessed: false,
      mapsSaved: 3,
      insertedStats: 12,
      winnerTeam: 1 as const,
    };
    const completionResult = {
      scrimId: 42,
      pointsPerPlayer: 5,
      awardedPlayerIds: [1, 2, 3, 4],
      alreadyCompleted: true,
    };
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
    const eloResult = {
      scrimId: 42,
      skipped: false,
      players: [
        { playerId: 1, oldRating: 1000, newRating: 1024, ratingChange: 24, roundsAdded: 1 },
      ],
    };

    const save = vi.spyOn(replaySubmissionService, 'saveVerifiedReplay').mockResolvedValue(replayResult);
    const complete = vi.spyOn(validScrimCompletionService, 'complete').mockResolvedValue(completionResult);
    const adapt = vi.spyOn(eloRoundAdapterService, 'fromVerifiedReplay').mockResolvedValue(rounds);
    const finalize = vi.spyOn(eloFinalizerService, 'finalize').mockResolvedValue(eloResult);

    const replay = { rounds: [] };
    const result = await verifiedScrimProcessingService.process(42, replay);

    expect(save).toHaveBeenCalledWith(42, replay);
    expect(complete).toHaveBeenCalledWith(42);
    expect(adapt).toHaveBeenCalledWith(replay);
    expect(finalize).toHaveBeenCalledWith(42, rounds);
    expect(result).toEqual({
      replay: replayResult,
      completion: completionResult,
      elo: eloResult,
      eloError: null,
    });
  });

  it('preserves a valid completed scrim when Elo needs review', async () => {
    vi.spyOn(replaySubmissionService, 'saveVerifiedReplay').mockResolvedValue({
      alreadyProcessed: false,
      mapsSaved: 3,
      insertedStats: 12,
      winnerTeam: 1,
    });
    vi.spyOn(validScrimCompletionService, 'complete').mockResolvedValue({
      scrimId: 42,
      pointsPerPlayer: 5,
      awardedPlayerIds: [1, 2, 3, 4],
      alreadyCompleted: true,
    });
    vi.spyOn(eloRoundAdapterService, 'fromVerifiedReplay').mockRejectedValue(
      new Error('Ambiguous Elo finish order'),
    );
    const finalize = vi.spyOn(eloFinalizerService, 'finalize');

    const result = await verifiedScrimProcessingService.process(42, { rounds: [] });

    expect(result.completion?.pointsPerPlayer).toBe(5);
    expect(result.elo).toBeNull();
    expect(result.eloError).toBe('Ambiguous Elo finish order');
    expect(finalize).not.toHaveBeenCalled();
  });
});
