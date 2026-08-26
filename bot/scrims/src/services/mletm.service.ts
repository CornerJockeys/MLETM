import { config } from '../config.js';
import { League } from '../types.js';
import { logger } from '../utils/logger.js';

export interface MleTmPlayerProfile {
  accountId: string;
  tmid: string;
  mleName: string;
  tmName: string;
  discordId: string;
  team: string;
  franchiseStaff: string;
  rosterSlot: string;
  salary: number;
  league: string;
  division: string;
  rostered: boolean;
}

function trimTrailingSlash(value: string): string {
  return value.replace(/\/+$/, '');
}

export class MleTmService {
  /**
   * Resolve a Trackmania player from the MLETM API using Discord ID.
   * Discord usernames are intentionally not part of this lookup.
   */
  async getPlayerByDiscordId(discordId: string): Promise<MleTmPlayerProfile | null> {
    const normalizedDiscordId = String(discordId || '').trim();
    if (!normalizedDiscordId) {
      return null;
    }

    const baseUrl = trimTrailingSlash(config.mletmApi.baseUrl);
    const url = `${baseUrl}/v1/players/discord/${encodeURIComponent(normalizedDiscordId)}`;

    let response: Response;
    try {
      response = await fetch(url, {
        method: 'GET',
        headers: {
          Accept: 'application/json',
        },
        signal: AbortSignal.timeout(config.mletmApi.timeoutMs),
      });
    } catch (error) {
      logger.error('MLETM API player lookup request failed', {
        discordId: normalizedDiscordId,
        error,
      });
      throw error;
    }

    if (response.status === 404) {
      return null;
    }

    if (!response.ok) {
      throw new Error(`MLETM API player lookup failed with HTTP ${response.status}`);
    }

    const profile = (await response.json()) as Partial<MleTmPlayerProfile>;

    if (
      !profile ||
      typeof profile.accountId !== 'string' ||
      typeof profile.discordId !== 'string' ||
      typeof profile.league !== 'string'
    ) {
      throw new Error('MLETM API returned an invalid player payload');
    }

    if (profile.discordId.trim() !== normalizedDiscordId) {
      throw new Error('MLETM API returned a Discord ID that does not match the lookup key');
    }

    return {
      accountId: profile.accountId,
      tmid: String(profile.tmid ?? ''),
      mleName: String(profile.mleName ?? ''),
      tmName: String(profile.tmName ?? ''),
      discordId: profile.discordId,
      team: String(profile.team ?? 'FA'),
      franchiseStaff: String(profile.franchiseStaff ?? ''),
      rosterSlot: String(profile.rosterSlot ?? ''),
      salary: Number(profile.salary ?? 0),
      league: profile.league,
      division: String(profile.division ?? ''),
      rostered: Boolean(profile.rostered),
    };
  }

  deriveLeague(league: string): League | null {
    switch (String(league || '').trim().toUpperCase()) {
      case 'ACADEMY':
        return 'Academy';
      case 'CHAMPION':
        return 'Champion';
      case 'MASTER':
        return 'Master';
      default:
        return null;
    }
  }
}

export const mletmService = new MleTmService();
