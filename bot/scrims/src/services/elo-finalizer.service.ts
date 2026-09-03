import { config } from '../config.js';
import { db, tableName } from '../db/index.js';
import type { EloRating, League, Scrim } from '../types.js';
import { calculateBatchedElo, shouldProcessElo, type BatchedEloRound } from './elo-batch.js';
import { playerStateEventsService } from './player-state-events.service.js';

interface EloParticipantRow {
  player_id: number;
  player_league: League;
  team_id: number | null;
}

export interface EloFinalizeResult {
  scrimId: number;
  skipped: boolean;
  skipReason?: 'casual_policy' | 'already_processed';
  players: Array<{
    playerId: number;
    league: League;
    oldRating: number;
    newRating: number;
    ratingChange: number;
    roundsAdded: number;
  }>;
}

export class EloFinalizerService {
  private readonly scrimsTable = tableName('scrims');
  private readonly playersTable = tableName('players');
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
        `SELECT
           sp.player_id,
           p.league AS player_league,
           MIN(mps.team_id)::int AS team_id
         FROM ${this.scrimPlayersTable} sp
         JOIN ${this.playersTable} p ON p.id = sp.player_id
         LEFT JOIN ${this.matchPlayerStatsTable} mps
           ON mps.scrim_id = sp.scrim_id AND mps.player_id = sp.player_id
         WHERE sp.scrim_id = $1
         GROUP BY sp.player_id, p.league
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
          [participant.player_id, participant.player_league],
        );

        ratings.set(
          participant.player_id,
          ratingResult.rows[0] ?? {
            id: 0,
            player_id: participant.player_id,
            league: participant.player_league,
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
        const participant = participants.find((entry) => entry.player_id === result.playerId)!;
        const isWin = scrim.winner_team !== null && participant.team_id === scrim.winner_team;
        const isLoss =
          scrim.winner_team !== null &&
          participant.team_id !== null &&
          participant.team_id !== scrim.winner_team;

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
            participant.player_league,
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

      await Promise.all(
        calculated.map((result) => {
          const participant = participants.find((entry) => entry.player_id === result.playerId)!;
          return playerStateEventsService.recordEloChange({
            playerId: result.playerId,
            eloBefore: result.startingRating,
            eloAfter: result.endingRating,
            sourceRef: String(scrimId),
            metadata: {
              visibility: 'internal_only',
              matchType: scrim.match_type,
              scrimLeague: scrim.league,
              ratingLeague: participant.player_league,
              casualTestOverride:
                scrim.match_type === 'CASUAL' && config.elo.enableCasualForTesting,
              roundsProcessed: result.rounds.length,
            },
          }).catch(() => null);
        }),
      );

      return {
        scrimId,
        skipped: false,
        players: calculated.map((result) => {
          const participant = participants.find((entry) => entry.player_id === result.playerId)!;
          return {
            playerId: result.playerId,
            league: participant.player_league,
            oldRating: result.startingRating,
            newRating: result.endingRating,
            ratingChange: result.ratingChange,
            roundsAdded: result.endingRoundsPlayed - result.startingRoundsPlayed,
          };
        }),
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
