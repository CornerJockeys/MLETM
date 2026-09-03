import { db, tableName } from '../db/index.js';
import type { EloRating, League } from '../types.js';
import type { BatchedEloRound } from './elo-batch.js';
import { eloFinalizerService } from './elo-finalizer.service.js';

interface PersistedRoundPointsRow {
  map_order: number;
  player_id: number;
  round_points: number[] | null;
}

/**
 * Elo query/recovery service.
 *
 * The old fixed-K match-level processor has been retired. `processMatch` now
 * rebuilds canonical round finishing orders from verified persisted stats and
 * delegates to EloFinalizerService, so admin retry tooling cannot bypass the
 * batched per-round Elo model.
 */
export class EloService {
  private readonly scrimsTable = tableName('scrims');
  private readonly scrimMapsTable = tableName('scrim_maps');
  private readonly matchPlayerStatsTable = tableName('match_player_stats');
  private readonly eloRatingsTable = tableName('elo_ratings');
  private readonly eloHistoryTable = tableName('elo_history');

  /**
   * Retained only as a formula regression helper for older unit tests/tools.
   * It is not used to persist MLE TM Elo.
   */
  calculateNewRating(currentRating: number, opponentRating: number, result: number): number {
    const K = 32;
    const expectedScore = 1 / (1 + Math.pow(10, (opponentRating - currentRating) / 400));
    return Math.round(currentRating + K * (result - expectedScore));
  }

  async processMatch(scrimId: number): Promise<void> {
    const rounds = await this.buildPersistedEloRounds(scrimId);
    await eloFinalizerService.finalize(scrimId, rounds);
  }

  async buildPersistedEloRounds(scrimId: number): Promise<BatchedEloRound[]> {
    const rowsResult = await db.query<PersistedRoundPointsRow>(
      `SELECT sm.map_order, mps.player_id, mps.round_points
       FROM ${this.scrimMapsTable} sm
       JOIN ${this.matchPlayerStatsTable} mps
         ON mps.scrim_id = sm.scrim_id AND mps.map_id = sm.map_id
       WHERE sm.scrim_id = $1
       ORDER BY sm.map_order, mps.player_id`,
      [scrimId],
    );

    if (rowsResult.rows.length === 0) {
      throw new Error(`Scrim ${scrimId} has no persisted round points for Elo`);
    }

    const byMap = new Map<number, PersistedRoundPointsRow[]>();
    for (const row of rowsResult.rows) {
      const rows = byMap.get(row.map_order) ?? [];
      rows.push(row);
      byMap.set(row.map_order, rows);
    }

    const rounds: BatchedEloRound[] = [];
    let sequence = 0;

    for (const mapOrder of [...byMap.keys()].sort((a, b) => a - b)) {
      const playerRows = byMap.get(mapOrder)!;
      const roundCount = Math.max(...playerRows.map((row) => row.round_points?.length ?? 0));

      for (let roundIndex = 0; roundIndex < roundCount; roundIndex++) {
        const placements = playerRows.map((row) => ({
          playerId: row.player_id,
          roundPoints: row.round_points?.[roundIndex] ?? 0,
        }));

        // Empty/warmup/incomplete rounds do not produce Elo.
        if (!placements.some((placement) => placement.roundPoints > 0)) continue;

        const sorted = [...placements].sort((a, b) => b.roundPoints - a.roundPoints);
        for (let index = 1; index < sorted.length; index++) {
          if (sorted[index - 1].roundPoints === sorted[index].roundPoints) {
            throw new Error(
              `Ambiguous Elo finish order in scrim ${scrimId}, map ${mapOrder}, round ${roundIndex + 1}: players ${sorted[index - 1].playerId} and ${sorted[index].playerId} both have ${sorted[index].roundPoints} round points`,
            );
          }
        }

        sequence += 1;
        rounds.push({
          round: sequence,
          results: sorted.map((placement, index) => ({
            playerId: placement.playerId,
            finishPosition: index + 1,
          })),
        });
      }
    }

    if (rounds.length === 0) {
      throw new Error(`Scrim ${scrimId} has no scored persisted rounds for Elo`);
    }

    return rounds;
  }

  async getPlayerEloSummary(playerId: number, league?: League): Promise<{
    ratings: EloRating[];
    history: Array<{
      scrim_id: number;
      scrim_uid: string;
      old_rating: number;
      new_rating: number;
      change_amount: number;
      created_at: Date;
    }>;
  }> {
    const params: unknown[] = [playerId];
    const leagueFilter = league ? `AND er.league = $${params.push(league)}` : '';
    const ratingsResult = await db.query<EloRating>(
      `SELECT * FROM ${this.eloRatingsTable} er WHERE er.player_id = $1 ${leagueFilter} ORDER BY er.league`,
      params,
    );

    const historyParams: unknown[] = [playerId];
    const historyLeagueFilter = league ? `AND s.league = $${historyParams.push(league)}` : '';
    const historyResult = await db.query<{
      scrim_id: number;
      scrim_uid: string;
      old_rating: number;
      new_rating: number;
      change_amount: number;
      created_at: Date;
    }>(
      `SELECT eh.scrim_id, s.scrim_uid, eh.old_rating, eh.new_rating, eh.change_amount, eh.created_at
       FROM ${this.eloHistoryTable} eh
       JOIN ${this.scrimsTable} s ON s.id = eh.scrim_id
       WHERE eh.player_id = $1 ${historyLeagueFilter}
       ORDER BY eh.created_at DESC
       LIMIT 20`,
      historyParams,
    );

    return {
      ratings: ratingsResult.rows,
      history: historyResult.rows,
    };
  }
}

export const eloService = new EloService();
