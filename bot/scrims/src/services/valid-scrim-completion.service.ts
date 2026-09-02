import { logger } from '../utils/logger.js';
import { scrimPointsService, SCRIM_POINTS_PER_VALID_SCRIM } from './scrim-points.service.js';
import { scrimService } from './scrim.service.js';

export interface ValidScrimCompletionResult {
  scrimId: number;
  pointsPerPlayer: number;
  awardedPlayerIds: number[];
  alreadyCompleted: boolean;
}

export class ValidScrimCompletionService {
  async complete(scrimId: number): Promise<ValidScrimCompletionResult> {
    const scrim = await scrimService.getById(scrimId);
    if (!scrim) {
      throw new Error(`Scrim ${scrimId} was not found`);
    }

    const alreadyCompleted = scrim.status === 'completed';
    if (!alreadyCompleted && scrim.status !== 'active') {
      throw new Error(
        `Scrim ${scrimId} cannot be completed from status ${scrim.status}; expected active`,
      );
    }

    const players = await scrimService.getScrimPlayers(scrimId);
    if (players.length === 0) {
      throw new Error(`Scrim ${scrimId} has no players`);
    }

    const allCheckedIn = players.every((player) => player.checked_in === true);
    if (!allCheckedIn) {
      throw new Error(`Scrim ${scrimId} is not a valid completion because not all players checked in`);
    }

    // If a previous process marked the scrim completed and died before awarding points,
    // this is intentionally safe to call again. scrim_point_awards prevents duplicates.
    if (!alreadyCompleted) {
      await scrimService.completeScrim(scrimId);
    }

    const mutations = await scrimPointsService.awardValidScrimCompletion(
      scrimId,
      players.map((player) => player.player_id),
      SCRIM_POINTS_PER_VALID_SCRIM,
    );

    logger.info('Valid scrim completion processed', {
      scrimId,
      pointsPerPlayer: SCRIM_POINTS_PER_VALID_SCRIM,
      awardedPlayerIds: mutations.map((mutation) => mutation.playerId),
      alreadyCompleted,
    });

    return {
      scrimId,
      pointsPerPlayer: SCRIM_POINTS_PER_VALID_SCRIM,
      awardedPlayerIds: mutations.map((mutation) => mutation.playerId),
      alreadyCompleted,
    };
  }
}

export const validScrimCompletionService = new ValidScrimCompletionService();
