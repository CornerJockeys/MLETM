import { config } from '../config.js';
import { db, tableName } from '../db/index.js';
import type { EloRating, Scrim } from '../types.js';
import { calculateBatchedElo, shouldProcessElo, type BatchedEloRound } from './elo-batch.js';
import { playerStateEventsService } from './player-state-events.service.js';

interface EloParticipantRow {
  player_id: number;
  team_id: number | null;
}

export interface EloFinalizeResult {
  scrimId: number;
  skipped: boolean;
  skipReason?: 'casual_policy' | 'already_processed';
  players: Array<{
    playerId: number;
    oldRating: number;
    newRating: number;
    ratingChange: number;
    roundsAdded: number;
  }>;
}

export class EloFinalizerService {
  private readonly scrimsTable = tableName('scrims');
  private readonly scrimPlayersTable = tableName('scrim_players');
  private readonly matchPlayerStatsTable = tableName('match_player_stats');
  private readonly eloRatingsTable = tableName('elo_ratings');
  private readonly eloHistoryTable = tableName('elo_history');

  async finalize(scrimId: number, rounds: BatchedEloRound[]): Promise<EloFinalizeResult> {
    const client = await db.getClient();
    try {
      await client.query('BEGIN');

      const scrimResult = await client.query<Scrim>(
        `SELECT * FROM ${this.scrimsTable} WHERE id = $1 FOR UPDATE`,
        [scrimId],
      );
      const scrim = scrimResult.rows[0];
      if (!scrim) throw new Error(`Scrim ${scrimId} not found`);
      if (scrim.status !== 'completed') {
        throw new Error(`Scrim ${scrimId} must be completed before Elo finalization`);
      }

      if (scrim.elo_processed) {
        await client.query('ROLLBACK');
        return { scrimId, skipped: true, skipReason: 'already_processed', players: [] };
      }

      if (!shouldProcessElo(scrim.match_type, config.elo.enableCasualForTesting)) {
        await client.query(
          `UPDATE ${this.scrimsTable} SET elo_processed = TRUE WHERE id = $1`,
          [scrimId],
        );
        await client.query('COMMIT');
        return { scrimId, skipped: true, skipReason: 'casual_policy', players: [] };
      }

      if (rounds.length === 0) {
        throw new Error(`Scrim ${scrimId} has no Elo rounds to finalize`);
      }

      const participantsResult = await client.query<EloParticipantRow>(
        `SELECT sp.player_id, MIN(mps.team_id)::int AS team_id
         FROM ${this.scrimPlayersTable} sp
         LEFT JOIN ${this.matchPlayerStatsTable} mps
           ON mps.scrim_id = sp.scrim_id AND mps.player_id = sp.player_id
         WHERE sp.scrim_id = $1
         GROUP BY sp.player_id
         ORDER BY sp.player_id`,
        [scrimId],
      );
      const participants = participantsResult.rows;
      if (participants.length < 2) {
        throw new Error(`Scrim ${scrimId} does not have enough Elo participants`);
      }

      const ratings = new Map<number, EloRating>();
      for (const participant of participants) {
        const ratingResult = await client.query<EloRating>(
          `SELECT * FROM ${this.eloRatingsTable}
           WHERE player_id = $1 AND league = $2
           FOR UPDATE`,
          [participant.player_id, scrim.league],
        );

        ratings.set(
          participant.player_id,
          ratingResult.rows[0] ?? {
            id: 0,
            player_id: participant.player_id,
            league: scrim.league,
            rating: 1000,
            wins: 0,
            losses: 0,
            rounds_played: 0,
            updated_at: new Date(),
          },
        );
      }

      const calculated = calculateBatchedElo(
        participants.map((participant) => {
          const rating = ratings.get(participant.player_id)!;
          return {
            playerId: participant.player_id,
            startingRating: rating.rating,
            roundsPlayed: rating.rounds_played ?? 0,
            teamId: participant.team_id,
          };
        }),
        rounds,
      );

      for (const result of calculated) {
        const current = ratings.get(result.playerId)!;
        const teamId = participants.find((participant) => participant.player_id === result.playerId)?.team_id;
        const isWin = scrim.winner_team !== null && teamId === scrim.winner_team;
        const isLoss = scrim.winner_team !== null && teamId !== null && teamId !== scrim.winner_team;

        await client.query(
          `INSERT INTO ${this.eloRatingsTable}
            (player_id, league, rating, wins, losses, rounds_played, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, NOW())
           ON CONFLICT (player_id, league)
           DO UPDATE SET
             rating = EXCLUDED.rating,
             wins = ${this.eloRatingsTable}.wins + $4,
             losses = ${this.eloRatingsTable}.losses + $5,
             rounds_played = EXCLUDED.rounds_played,
             updated_at = NOW()`,
          [
            result.playerId,
            scrim.league,
            result.endingRating,
            isWin ? 1 : 0,
            isLoss ? 1 : 0,
            result.endingRoundsPlayed,
          ],
        );

        await client.query(
          `INSERT INTO ${this.eloHistoryTable}
            (player_id, scrim_id, old_rating, new_rating, round_breakdown)
           VALUES ($1, $2, $3, $4, $5::jsonb)
           ON CONFLICT (player_id, scrim_id) DO NOTHING`,
          [
            result.playerId,
            scrimId,
            current.rating,
            result.endingRating,
            JSON.stringify(result.rounds),
          ],
        );
      }

      await client.query(
        `UPDATE ${this.scrimsTable} SET elo_processed = TRUE WHERE id = $1`,
        [scrimId],
      );

      await client.query('COMMIT');

      // Events are deliberately emitted after the authoritative Elo transaction.
      // A notification/event failure must never roll back competitive data.
      await Promise.all(
        calculated.map((result) =>
          playerStateEventsService.recordEloChange({
            playerId: result.playerId,
            eloBefore: result.startingRating,
            eloAfter: result.endingRating,
            sourceRef: String(scrimId),
            metadata: {
              matchType: scrim.match_type,
              league: scrim.league,
              roundsProcessed: result.rounds.length,
            },
          }).catch(() => null),
        ),
      );

      return {
        scrimId,
        skipped: false,
        players: calculated.map((result) => ({
          playerId: result.playerId,
          oldRating: result.startingRating,
          newRating: result.endingRating,
          ratingChange: result.ratingChange,
          roundsAdded: result.endingRoundsPlayed - result.startingRoundsPlayed,
        })),
      };
    } catch (error) {
      try {
        await client.query('ROLLBACK');
      } catch {
        // Transaction may already have been committed or rolled back on a handled return path.
      }
      throw error;
    } finally {
      client.release();
    }
  }
}

export const eloFinalizerService = new EloFinalizerService();
