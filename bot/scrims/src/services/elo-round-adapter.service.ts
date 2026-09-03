import { db, tableName } from '../db/index.js';
import type { RawReplay } from './replay-submission.service.js';
import type { BatchedEloRound } from './elo-batch.js';

interface ReplayRoundPlayer {
  id?: string | null;
  name?: string;
  roundPoints?: number;
}

function normalizeName(name?: string): string {
  if (!name) return '';
  return name.trim().replace(/[\W_]+$/, '');
}

function replayMaps(replay: RawReplay) {
  if (Array.isArray(replay.maps)) return replay.maps;
  if (replay.map) return [replay.map];
  if (Array.isArray(replay.rounds)) return [{ rounds: replay.rounds }];
  return [];
}

export class EloRoundAdapterService {
  private readonly playersTable = tableName('players');

  async fromVerifiedReplay(replay: RawReplay): Promise<BatchedEloRound[]> {
    const maps = replayMaps(replay);
    const rounds: BatchedEloRound[] = [];
    let sequence = 0;

    for (const map of maps) {
      for (const rawRound of map.rounds ?? []) {
        const rawPlayers = (rawRound.players ?? []) as ReplayRoundPlayer[];
        if (rawPlayers.length === 0) continue;

        // Zero-score rounds are not competitive results (warmup/empty/incomplete).
        // Do not manufacture an Elo ordering for them.
        if (!rawPlayers.some((player) => (player.roundPoints ?? 0) > 0)) continue;

        const resolved = await Promise.all(
          rawPlayers.map(async (player) => ({
            playerId: await this.resolvePlayerId(player),
            roundPoints: player.roundPoints ?? 0,
            replayName: normalizeName(player.name) || 'Unknown',
          })),
        );

        const unresolved = resolved.filter((player) => player.playerId === null);
        if (unresolved.length > 0) {
          throw new Error(
            `Unable to resolve Elo round player(s): ${unresolved.map((player) => player.replayName).join(', ')}`,
          );
        }

        const ids = resolved.map((player) => player.playerId as number);
        if (new Set(ids).size !== ids.length) {
          throw new Error('Verified replay round resolved the same player more than once');
        }

        const sorted = [...resolved].sort((a, b) => b.roundPoints - a.roundPoints);
        for (let index = 1; index < sorted.length; index++) {
          if (sorted[index - 1].roundPoints === sorted[index].roundPoints) {
            throw new Error(
              `Ambiguous Elo finish order: ${sorted[index - 1].replayName} and ${sorted[index].replayName} both have ${sorted[index].roundPoints} round points`,
            );
          }
        }

        sequence += 1;
        rounds.push({
          round: sequence,
          results: sorted.map((player, index) => ({
            playerId: player.playerId as number,
            finishPosition: index + 1,
          })),
        });
      }
    }

    if (rounds.length === 0) {
      throw new Error('Verified replay did not contain any scored rounds for Elo');
    }

    return rounds;
  }

  private async resolvePlayerId(player: ReplayRoundPlayer): Promise<number | null> {
    const accountId = player.id?.trim();
    if (accountId) {
      const result = await db.query<{ id: number }>(
        `SELECT id FROM ${this.playersTable} WHERE $1 = ANY(platform_account_ids) LIMIT 2`,
        [accountId],
      );
      if (result.rows.length > 1) {
        throw new Error(`Multiple players matched Trackmania account ${accountId}`);
      }
      if (result.rows.length === 1) return result.rows[0].id;
    }

    const name = normalizeName(player.name);
    if (!name) return null;

    const result = await db.query<{ id: number }>(
      `SELECT id FROM ${this.playersTable} WHERE discord_username = $1 LIMIT 2`,
      [name],
    );
    if (result.rows.length > 1) {
      throw new Error(`Multiple players matched replay name ${name}`);
    }
    return result.rows[0]?.id ?? null;
  }
}

export const eloRoundAdapterService = new EloRoundAdapterService();
