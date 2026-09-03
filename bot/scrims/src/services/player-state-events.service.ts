import { db, tableName } from '../db/index.js';

export type PlayerStateEventType =
  | 'salary_changed'
  | 'eligibility_gained'
  | 'eligibility_lost'
  | 'scrim_points_changed'
  | 'elo_changed';

export interface PlayerStateEventInput {
  playerId: number;
  eventType: PlayerStateEventType;
  oldValue?: unknown;
  newValue?: unknown;
  source?: string;
  sourceRef?: string | null;
  metadata?: Record<string, unknown>;
}

export interface PlayerStateEventRecord {
  id: number;
  player_id: number;
  event_type: PlayerStateEventType;
  old_value: unknown;
  new_value: unknown;
  source: string;
  source_ref: string | null;
  metadata: Record<string, unknown>;
  created_at: Date;
}

export class PlayerStateEventsService {
  async record(input: PlayerStateEventInput): Promise<PlayerStateEventRecord> {
    const result = await db.query<PlayerStateEventRecord>(
      `INSERT INTO ${tableName('player_state_events')}
        (player_id, event_type, old_value, new_value, source, source_ref, metadata)
       VALUES ($1, $2, $3::jsonb, $4::jsonb, $5, $6, $7::jsonb)
       RETURNING *`,
      [
        input.playerId,
        input.eventType,
        input.oldValue === undefined ? null : JSON.stringify(input.oldValue),
        input.newValue === undefined ? null : JSON.stringify(input.newValue),
        input.source ?? 'scrim_bot',
        input.sourceRef ?? null,
        JSON.stringify(input.metadata ?? {}),
      ],
    );

    return result.rows[0];
  }

  async recordScrimPointsChange(input: {
    playerId: number;
    pointsBefore: number;
    pointsAfter: number;
    source?: string;
    sourceRef?: string | null;
    metadata?: Record<string, unknown>;
  }): Promise<PlayerStateEventRecord | null> {
    if (input.pointsBefore === input.pointsAfter) return null;

    return this.record({
      playerId: input.playerId,
      eventType: 'scrim_points_changed',
      oldValue: input.pointsBefore,
      newValue: input.pointsAfter,
      source: input.source,
      sourceRef: input.sourceRef,
      metadata: input.metadata,
    });
  }

  async recordEligibilityTransition(input: {
    playerId: number;
    eligibleBefore: boolean;
    eligibleAfter: boolean;
    pointsBefore?: number;
    pointsAfter?: number;
    source?: string;
    sourceRef?: string | null;
    metadata?: Record<string, unknown>;
  }): Promise<PlayerStateEventRecord | null> {
    if (input.eligibleBefore === input.eligibleAfter) return null;

    return this.record({
      playerId: input.playerId,
      eventType: input.eligibleAfter ? 'eligibility_gained' : 'eligibility_lost',
      oldValue: {
        eligible: input.eligibleBefore,
        ...(input.pointsBefore === undefined ? {} : { scrimPoints: input.pointsBefore }),
      },
      newValue: {
        eligible: input.eligibleAfter,
        ...(input.pointsAfter === undefined ? {} : { scrimPoints: input.pointsAfter }),
      },
      source: input.source,
      sourceRef: input.sourceRef,
      metadata: input.metadata,
    });
  }

  async recordSalaryChange(input: {
    playerId: number;
    salaryBefore: number;
    salaryAfter: number;
    source?: string;
    sourceRef?: string | null;
    metadata?: Record<string, unknown>;
  }): Promise<PlayerStateEventRecord | null> {
    if (input.salaryBefore === input.salaryAfter) return null;

    return this.record({
      playerId: input.playerId,
      eventType: 'salary_changed',
      oldValue: input.salaryBefore,
      newValue: input.salaryAfter,
      source: input.source,
      sourceRef: input.sourceRef,
      metadata: input.metadata,
    });
  }

  /** Internal/admin-only event. Raw Elo must not be exposed by Discord-facing consumers. */
  async recordEloChange(input: {
    playerId: number;
    eloBefore: number;
    eloAfter: number;
    sourceRef?: string | null;
    metadata?: Record<string, unknown>;
  }): Promise<PlayerStateEventRecord | null> {
    if (input.eloBefore === input.eloAfter) return null;

    return this.record({
      playerId: input.playerId,
      eventType: 'elo_changed',
      oldValue: input.eloBefore,
      newValue: input.eloAfter,
      source: 'elo_finalizer',
      sourceRef: input.sourceRef,
      metadata: { visibility: 'internal', ...(input.metadata ?? {}) },
    });
  }
}

export const playerStateEventsService = new PlayerStateEventsService();
