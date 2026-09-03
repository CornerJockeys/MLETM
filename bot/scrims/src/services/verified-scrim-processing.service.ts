import { logger } from '../utils/logger.js';
import type { RawReplay, ReplaySaveResult } from './replay-submission.service.js';
import { replaySubmissionService } from './replay-submission.service.js';
import { validScrimCompletionService, type ValidScrimCompletionResult } from './valid-scrim-completion.service.js';
import { eloRoundAdapterService } from './elo-round-adapter.service.js';
import { eloFinalizerService, type EloFinalizeResult } from './elo-finalizer.service.js';

export interface VerifiedScrimProcessingResult {
  replay: ReplaySaveResult;
  completion: ValidScrimCompletionResult | null;
  elo: EloFinalizeResult | null;
  eloError: string | null;
}

/**
 * Canonical post-verification pipeline.
 *
 * Future replay/API handlers should call this service rather than invoking the
 * low-level replay saver directly. Verified match persistence and eligibility
 * are authoritative; Elo is downstream and may be retried/reviewed without
 * invalidating an otherwise valid submitted scrim.
 */
export class VerifiedScrimProcessingService {
  async process(scrimId: number, replay: RawReplay): Promise<VerifiedScrimProcessingResult> {
    const replayResult = await replaySubmissionService.saveVerifiedReplay(scrimId, replay);

    if (replayResult.alreadyProcessed) {
      return {
        replay: replayResult,
        completion: null,
        elo: { scrimId, skipped: true, skipReason: 'already_processed', players: [] },
        eloError: null,
      };
    }

    // Valid completion owns the canonical +5 scrim-point award. Its award path
    // is idempotent, so retry/recovery cannot grant the same scrim twice.
    const completion = await validScrimCompletionService.complete(scrimId);

    try {
      const rounds = await eloRoundAdapterService.fromVerifiedReplay(replay);
      const elo = await eloFinalizerService.finalize(scrimId, rounds);
      return {
        replay: replayResult,
        completion,
        elo,
        eloError: null,
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('Verified scrim saved but Elo finalization needs review/retry', {
        scrimId,
        error,
      });

      return {
        replay: replayResult,
        completion,
        elo: null,
        eloError: message,
      };
    }
  }
}

export const verifiedScrimProcessingService = new VerifiedScrimProcessingService();
