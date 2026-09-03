import { db, tableName } from '../db/index.js';
import type { Scrim, EloRating, League } from '../types.js';
import { logger } from '../utils/logger.js';
import { mletmArchiveService } from './mletm-archive.service.js';

/**
 * Legacy match-level Elo processor retained for old admin/tooling paths.
 * New verified scrims should use EloFinalizerService with canonical round orders.
 */
export class EloService {
  private readonly scrimsTable = tableName('scrims');
  private readonly scrimPlayersTable = tableName('scrim_players');
  private readonly matchPlayerStatsTable = tableName('match_player_stats');
  private readonly eloRatingsTable = tableName('elo_ratings');
  private readonly eloHistoryTable = tableName('elo_history');

  calculateNewRating(currentRating: number, opponentRating: number, result: number): number {
    const K = 32;
    const expectedScore = 1 / (1 + Math.pow(10, (opponentRating - currentRating) / 400));
    return Math.round(currentRating + K * (result - expectedScore));
  }

  async processMatch(scrimId: number): Promise<void> {
    const client = await db.getClient();
    try {
      await client.query('BEGIN');

      const scrimResult = await client.query<Scrim>(
        `SELECT * FROM ${this.scrimsTable} WHERE id = $1`,
        [scrimId],
      );
      const scrim = scrimResult.rows[0];

      if (!scrim) throw new Error(`Scrim ${scrimId} not found`);
      if (scrim.status !== 'completed') throw new Error(`Scrim ${scrimId} is not completed`);
      if (scrim.match_type === 'CASUAL' || scrim.league === 'Casual') {
        throw new Error(
          `Casual scrim ${scrimId} cannot use legacy Elo processing; use EloFinalizerService with verified round results`,
        );
      }
      if (scrim.elo_processed) {
        logger.info(`Elo already processed for scrim ${scrimId}`);
        await client.query('ROLLBACK');
        return;
      }
      if (!scrim.winner_team) {
        throw new Error(`Scrim ${scrimId} has no winner_team set`);
      }

      const ratingLeague: League = scrim.league;
      const playersResult = await client.query<{ player_id: number; team_id: number }>(
        `SELECT sp.player_id, mps.team_id
         FROM ${this.scrimPlayersTable} sp
         LEFT JOIN ${this.matchPlayerStatsTable} mps
           ON sp.player_id = mps.player_id AND mps.scrim_id = sp.scrim_id
         WHERE sp.scrim_id = $1
         GROUP BY sp.player_id, mps.team_id`,
        [scrimId],
      );
      const players = playersResult.rows;

      const ratings = new Map<number, EloRating>();
      for (const player of players) {
        const ratingResult = await client.query<EloRating>(
          `SELECT * FROM ${this.eloRatingsTable} WHERE player_id = $1 AND league = $2`,
          [player.player_id, ratingLeague],
        );

        ratings.set(
          player.player_id,
          ratingResult.rows[0] ?? {
            id: 0,
            player_id: player.player_id,
            league: ratingLeague,
            rating: 1000,
            wins: 0,
            losses: 0,
            rounds_played: 0,
            updated_at: new Date(),
          },
        );
      }

      const team1 = players.filter((player) => player.team_id === 1);
      const team2 = players.filter((player) => player.team_id === 2);
      if (team1.length === 0 || team2.length === 0) {
        logger.warn(`Missing team assignments for scrim ${scrimId}, skipping legacy Elo calculation`);
        await client.query('ROLLBACK');
        return;
      }

      const team1AvgRating =
        team1.reduce((sum, player) => sum + ratings.get(player.player_id)!.rating, 0) / team1.length;
      const team2AvgRating =
        team2.reduce((sum, player) => sum + ratings.get(player.player_id)!.rating, 0) / team2.length;
      const team1Result = scrim.winner_team === 1 ? 1 : 0;
      const team2Result = scrim.winner_team === 2 ? 1 : 0;

      const outputPlayers: Array<{
        playerId: number;
        team: 1 | 2;
        isWin: boolean;
        oldRating: number;
        newRating: number;
        ratingChange: number;
      }> = [];

      for (const player of team1) {
        const current = ratings.get(player.player_id)!;
        const newRating = this.calculateNewRating(current.rating, team2AvgRating, team1Result);
        await this.updatePlayerRating(
          client,
          player.player_id,
          scrim.id,
          ratingLeague,
          current,
          newRating,
          team1Result === 1,
        );
        outputPlayers.push({
          playerId: player.player_id,
          team: 1,
          isWin: team1Result === 1,
          oldRating: current.rating,
          newRating,
          ratingChange: newRating - current.rating,
        });
      }

      for (const player of team2) {
        const current = ratings.get(player.player_id)!;
        const newRating = this.calculateNewRating(current.rating, team1AvgRating, team2Result);
        await this.updatePlayerRating(
          client,
          player.player_id,
          scrim.id,
          ratingLeague,
          current,
          newRating,
          team2Result === 1,
        );
        outputPlayers.push({
          playerId: player.player_id,
          team: 2,
          isWin: team2Result === 1,
          oldRating: current.rating,
          newRating,
          ratingChange: newRating - current.rating,
        });
      }

      await client.query(
        `UPDATE ${this.scrimsTable} SET elo_processed = TRUE WHERE id = $1`,
        [scrimId],
      );

      await client.query('COMMIT');
      logger.info(`Legacy Elo processed for scrim ${scrimId}`);

      await mletmArchiveService.archive(scrim.scrim_uid, 'result', {
        scrimId: scrim.id,
        scrimUid: scrim.scrim_uid,
        league: ratingLeague,
        winnerTeam: scrim.winner_team,
        completedAt: scrim.completed_at
          ? new Date(scrim.completed_at).toISOString()
          : new Date().toISOString(),
        sprocket: {
          matchParentId: scrim.sprocket_match_parent_id ?? null,
          matchId: scrim.sprocket_match_id ?? null,
        },
        players: outputPlayers,
        eloMode: 'legacy_match_level',
      });
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error(`Error processing Elo for scrim ${scrimId}:`, error);
      throw error;
    } finally {
      client.release();
    }
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

  private async updatePlayerRating(
    client: any,
    playerId: number,
    scrimId: number,
    league: League,
    currentRating: EloRating,
    newRating: number,
    isWin: boolean,
  ): Promise<void> {
    await client.query(
      `INSERT INTO ${this.eloRatingsTable} (player_id, league, rating, wins, losses, rounds_played, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW())
       ON CONFLICT (player_id, league)
       DO UPDATE SET
         rating = $3,
         wins = ${this.eloRatingsTable}.wins + $7,
         losses = ${this.eloRatingsTable}.losses + $8,
         updated_at = NOW()`,
      [
        playerId,
        league,
        newRating,
        isWin ? 1 : 0,
        isWin ? 0 : 1,
        currentRating.rounds_played ?? 0,
        isWin ? 1 : 0,
        isWin ? 0 : 1,
      ],
    );

    await client.query(
      `INSERT INTO ${this.eloHistoryTable} (player_id, scrim_id, old_rating, new_rating)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT DO NOTHING`,
      [playerId, scrimId, currentRating.rating, newRating],
    );
  }
}

export const eloService = new EloService();
