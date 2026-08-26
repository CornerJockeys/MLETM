import { Player } from '../types.js';
import { logger } from '../utils/logger.js';
import { mletmService } from './mletm.service.js';
import { playerService } from './player.service.js';

export type PlayerResolutionSource = 'sprocket' | 'mletm';

export interface PlayerResolution {
  player: Player;
  source: PlayerResolutionSource;
}

export class PlayerResolverService {
  async resolvePlayer(
    discordId: string,
    discordUsername: string,
  ): Promise<PlayerResolution | null> {
    try {
      const sprocketPlayer = await playerService.syncPlayerFromSprocket(
        discordId,
        discordUsername,
      );

      if (sprocketPlayer) {
        return {
          player: sprocketPlayer,
          source: 'sprocket',
        };
      }
    } catch (error) {
      logger.warn('Sprocket player resolution failed; trying MLETM fallback', {
        discordId,
        error,
      });
    }

    const profile = await mletmService.getPlayerByDiscordId(discordId);
    if (!profile) {
      return null;
    }

    const league = mletmService.deriveLeague(profile.league);
    if (!league) {
      logger.warn('MLETM player has unsupported league', {
        discordId,
        league: profile.league,
      });
      return null;
    }

    const player = await playerService.syncPlayerFromMleTm(
      discordId,
      discordUsername,
      profile.accountId,
      league,
    );

    if (!player) {
      return null;
    }

    logger.info('Player resolved through MLETM fallback', {
      discordId,
      accountId: profile.accountId,
      league,
    });

    return {
      player,
      source: 'mletm',
    };
  }
}

export const playerResolverService = new PlayerResolverService();
