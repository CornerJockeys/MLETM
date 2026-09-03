import { randomUUID } from 'crypto';
import { db, tableName } from '../db/index.js';
import type { Map, Scrim } from '../types.js';
import { config } from '../config.js';
import { logger } from '../utils/logger.js';

export class CasualScrimService {
  private readonly scrimsTable = tableName('scrims');
  private readonly scrimPlayersTable = tableName('scrim_players');
  private readonly scrimMapsTable = tableName('scrim_maps');

  async create(playerIds: number[], maps: Map[]): Promise<Scrim> {
    if (playerIds.length !== 4) {
      throw new Error('Casual scrim must have exactly 4 players');
    }

    const client = await db.getClient();
    try {
      await client.query('BEGIN');

      const scrimUid = `CASUAL-${randomUUID()}`;
      const checkinDeadline = new Date(Date.now() + config.queue.checkInTimeout * 1000);

      const scrimResult = await client.query<Scrim>(
        `INSERT INTO ${this.scrimsTable}
          (scrim_uid, league, status, match_type, created_at, checkin_deadline)
         VALUES ($1, 'Casual', 'checking_in', 'CASUAL', NOW(), $2)
         RETURNING *`,
        [scrimUid, checkinDeadline],
      );
      const scrim = scrimResult.rows[0];

      for (const playerId of playerIds) {
        await client.query(
          `INSERT INTO ${this.scrimPlayersTable} (scrim_id, player_id, checked_in)
           VALUES ($1, $2, FALSE)`,
          [scrim.id, playerId],
        );
      }

      for (let index = 0; index < maps.length; index++) {
        await client.query(
          `INSERT INTO ${this.scrimMapsTable} (scrim_id, map_id, map_order)
           VALUES ($1, $2, $3)`,
          [scrim.id, maps[index].id, index + 1],
        );
      }

      await client.query('COMMIT');

      logger.info('Casual scrim created', {
        scrimId: scrim.id,
        scrimUid,
        playerIds,
        mapIds: maps.map((map) => map.id),
      });

      return scrim;
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Error creating Casual scrim', { playerIds, error });
      throw error;
    } finally {
      client.release();
    }
  }
}

export const casualScrimService = new CasualScrimService();
