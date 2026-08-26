import { Player } from '../types.js';
import { logger } from '../utils/logger.js';
import { mletmService } from './mletm.service.js';
import { playerService } from './player.service.js';

export type PlayerResolutionSource = 'sprocket' | 'mletm';

export interface PlayerResolution {
  player: Player;
  source: PlayerResolutionSource;
}

/**
 * Resolve the Discord user who invoked a bot action into the local Player shape
 * consumed by queue/scrim logic.
 *
 * Discord ID is the only identity key. `displayName` is presentation metadata
 * from Discord and is never used to find or match a player.
 */
export class PlayerResolverService {
  async resolvePlayer(
    discordId: string,
    displayName: string,
  ): Promise<PlayerResolution | null> {
    const normalizedDiscordId = String(discordId || '').trim();
    if (!normalizedDiscordId) {
      logger.warn('Player resolution rejected because Discord ID was empty');
      return null;
    }

    // Preferred path: preserve the bot's existing Sprocket/MLEDB integration.
    // If no usable Trackmania identity is available there, fall back to MLETM.
    try {
      const sprocketPlayer = await playerService.syncPlayerFromSprocket(
        normalizedDiscordId,
        displayName,
      );

      if (sprocketPlayer) {
        return {
          player: sprocketPlayer,
          source: 'sprocket',
        };
      }
    } catch (error) {
      logger.warn('Sprocket player resolution failed; trying MLETM fallback', {
        discordId: normalizedDiscordId,
        error,
      });
    }

    let profile;
    try {
      profile = await mletmService.getPlayerByDiscordId(normalizedDiscordId);
    } catch (error) {
      logger.error('MLETM fallback player resolution failed', {
        discordId: normalizedDiscordId,
        error,
      });
      return null;
    }

    if (!profile) {
      return null;
    }

    const league = mletmService.deriveLeague(profile.league);
    if (!league) {
      logger.warn('MLETM player has unsupported league', {
        discordId: normalizedDiscordId,
        league: profile.league,
      });
      return null;
    }

    const player = await playerService.syncPlayerFromMleTm(
      normalizedDiscordId,
      displayName,
      profile.accountId,
      league,
    );

    if (!player) {
      return null;
    }

    logger.info('Player resolved through MLETM fallback', {
      discordId: normalizedDiscordId,
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
