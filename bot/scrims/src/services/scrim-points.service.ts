import { db, tableName } from '../db/index.js';

export const SCRIM_POINTS_ELIGIBILITY_THRESHOLD = 30;
export const SCRIM_POINTS_PER_VALID_SCRIM = 5;

interface ScrimPointsRow {
  points: number;
}

export interface ScrimPointMutation {
  playerId: number;
  pointsBefore: number;
  pointsAfter: number;
  delta: number;
}

interface ScrimPointMutationOptions {
  reason?: string;
  source?: string;
  scrimId?: number | null;
}

export class ScrimPointsService {
  async getPoints(playerId: number): Promise<number> {
    const result = await db.query<ScrimPointsRow>(
      `SELECT points FROM ${tableName('scrim_points')} WHERE player_id = $1`,
      [playerId],
    );
    return Number(result.rows[0]?.points ?? 0);
  }

  async getPointsByDiscordId(discordId: string): Promise<number> {
    const result = await db.query<ScrimPointsRow>(
      `SELECT COALESCE(sp.points, 0)::int AS points
       FROM ${tableName('players')} p
       LEFT JOIN ${tableName('scrim_points')} sp ON sp.player_id = p.id
       WHERE p.discord_id = $1
       LIMIT 1`,
      [String(discordId).trim()],
    );
    return Number(result.rows[0]?.points ?? 0);
  }

  async setPoints(
    playerId: number,
    points: number,
    options: ScrimPointMutationOptions = {},
  ): Promise<ScrimPointMutation> {
    if (!Number.isInteger(points) || points < 0) {
      throw new Error(`Scrim points must be a non-negative integer; received ${points}`);
    }

    const client = await db.getClient();
    try {
      await client.query('BEGIN');

      const beforeResult = await client.query<ScrimPointsRow>(
        `SELECT points FROM ${tableName('scrim_points')} WHERE player_id = $1 FOR UPDATE`,
        [playerId],
      );
      const pointsBefore = Number(beforeResult.rows[0]?.points ?? 0);
      const delta = points - pointsBefore;

      await client.query(
        `INSERT INTO ${tableName('scrim_points')} (player_id, points, updated_at)
         VALUES ($1, $2, NOW())
         ON CONFLICT (player_id)
         DO UPDATE SET points = EXCLUDED.points, updated_at = NOW()`,
        [playerId, points],
      );

      if (delta !== 0) {
        await client.query(
          `INSERT INTO ${tableName('scrim_point_events')}
            (player_id, delta, points_before, points_after, reason, source, scrim_id)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [
            playerId,
            delta,
            pointsBefore,
            points,
            options.reason ?? null,
            options.source ?? 'scrim_bot',
            options.scrimId ?? null,
          ],
        );
      }

      await client.query('COMMIT');
      return { playerId, pointsBefore, pointsAfter: points, delta };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async addPoints(
    playerId: number,
    delta: number,
    options: ScrimPointMutationOptions = {},
  ): Promise<ScrimPointMutation> {
    if (!Number.isInteger(delta)) {
      throw new Error(`Scrim-point delta must be an integer; received ${delta}`);
    }

    const client = await db.getClient();
    try {
      await client.query('BEGIN');

      await client.query(
        `INSERT INTO ${tableName('scrim_points')} (player_id, points, updated_at)
         VALUES ($1, 0, NOW())
         ON CONFLICT (player_id) DO NOTHING`,
        [playerId],
      );

      const beforeResult = await client.query<ScrimPointsRow>(
        `SELECT points FROM ${tableName('scrim_points')} WHERE player_id = $1 FOR UPDATE`,
        [playerId],
      );
      const pointsBefore = Number(beforeResult.rows[0]?.points ?? 0);
      const pointsAfter = pointsBefore + delta;

      if (pointsAfter < 0) {
        throw new Error(`Scrim-point mutation would produce a negative total (${pointsAfter})`);
      }

      await client.query(
        `UPDATE ${tableName('scrim_points')}
         SET points = $2, updated_at = NOW()
         WHERE player_id = $1`,
        [playerId, pointsAfter],
      );

      if (delta !== 0) {
        await client.query(
          `INSERT INTO ${tableName('scrim_point_events')}
            (player_id, delta, points_before, points_after, reason, source, scrim_id)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [
            playerId,
            delta,
            pointsBefore,
            pointsAfter,
            options.reason ?? null,
            options.source ?? 'scrim_bot',
            options.scrimId ?? null,
          ],
        );
      }

      await client.query('COMMIT');
      return { playerId, pointsBefore, pointsAfter, delta };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async awardValidScrimCompletion(
    scrimId: number,
    playerIds: number[],
    pointsPerPlayer = SCRIM_POINTS_PER_VALID_SCRIM,
  ): Promise<ScrimPointMutation[]> {
    if (!Number.isInteger(scrimId) || scrimId <= 0) {
      throw new Error(`Invalid scrim id: ${scrimId}`);
    }
    if (!Number.isInteger(pointsPerPlayer) || pointsPerPlayer <= 0) {
      throw new Error(`Scrim completion award must be a positive integer; received ${pointsPerPlayer}`);
    }

    const uniquePlayerIds = [...new Set(playerIds.filter((id) => Number.isInteger(id) && id > 0))];
    const client = await db.getClient();
    const mutations: ScrimPointMutation[] = [];

    try {
      await client.query('BEGIN');

      for (const playerId of uniquePlayerIds) {
        const awardResult = await client.query(
          `INSERT INTO ${tableName('scrim_point_awards')} (scrim_id, player_id, points_awarded)
           VALUES ($1, $2, $3)
           ON CONFLICT (scrim_id, player_id) DO NOTHING
           RETURNING player_id`,
          [scrimId, playerId, pointsPerPlayer],
        );

        if (awardResult.rowCount === 0) {
          continue;
        }

        await client.query(
          `INSERT INTO ${tableName('scrim_points')} (player_id, points, updated_at)
           VALUES ($1, 0, NOW())
           ON CONFLICT (player_id) DO NOTHING`,
          [playerId],
        );

        const beforeResult = await client.query<ScrimPointsRow>(
          `SELECT points FROM ${tableName('scrim_points')} WHERE player_id = $1 FOR UPDATE`,
          [playerId],
        );
        const pointsBefore = Number(beforeResult.rows[0]?.points ?? 0);
        const pointsAfter = pointsBefore + pointsPerPlayer;

        await client.query(
          `UPDATE ${tableName('scrim_points')}
           SET points = $2, updated_at = NOW()
           WHERE player_id = $1`,
          [playerId, pointsAfter],
        );

        await client.query(
          `INSERT INTO ${tableName('scrim_point_events')}
            (player_id, delta, points_before, points_after, reason, source, scrim_id)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [
            playerId,
            pointsPerPlayer,
            pointsBefore,
            pointsAfter,
            'Valid scrim completion',
            'scrim_completion',
            scrimId,
          ],
        );

        mutations.push({
          playerId,
          pointsBefore,
          pointsAfter,
          delta: pointsPerPlayer,
        });
      }

      await client.query('COMMIT');
      return mutations;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  isEligible(points: number): boolean {
    return Math.max(0, Number(points) || 0) >= SCRIM_POINTS_ELIGIBILITY_THRESHOLD;
  }
}

export const scrimPointsService = new ScrimPointsService();
