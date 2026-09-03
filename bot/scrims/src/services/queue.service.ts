import { QueueEntry, QueueState, League, Player, Scrim, Map } from '../types.js';
import { logger } from '../utils/logger.js';
import { config } from '../config.js';
import { playerService } from './player.service.js';
import { playerResolverService } from './player-resolver.service.js';
import { banService } from './ban.service.js';
import { mapService } from './map.service.js';
import { scrimService } from './scrim.service.js';
import { casualScrimService } from './casual-scrim.service.js';
import { EventEmitter } from 'events';

export type QueueMode = 'DIVISIONAL' | 'CASUAL';
type QueueKey = League | 'Casual';

export interface QueuePopEvent {
  scrim: Scrim;
  players: Player[];
  maps: Map[];
}

export interface QueueScrimCancelResult {
  success: boolean;
  message: string;
  scrimId: number;
  scrimUid?: string;
  restoredPlayerIds: number[];
}

/**
 * In-memory queue management service.
 * Divisional queues remain league-scoped; Casual is one mixed-division queue.
 */
export class QueueService extends EventEmitter {
  private queues: QueueState = {};

  constructor() {
    super();
    this.initializeQueues();
  }

  private initializeQueues(): void {
    const queueKeys: QueueKey[] = ['Academy', 'Champion', 'Master', 'Casual'];
    for (const queueKey of queueKeys) {
      this.queues[queueKey] = [];
    }
    logger.info('Queue service initialized', { queueKeys });
  }

  async joinQueue(
    discordId: string,
    _username: string,
    mode: QueueMode = 'DIVISIONAL',
  ): Promise<{
    success: boolean;
    message: string;
    position?: number;
  }> {
    try {
      const resolution = await playerResolverService.resolvePlayer(discordId, _username);
      const player = resolution?.player;

      if (!player || !resolution) {
        return {
          success: false,
          message:
            'I could not resolve your Trackmania league profile. Make sure your Discord ID is linked in MLE or Sprocket.',
        };
      }

      logger.info('Queue player identity resolved', {
        discordId,
        playerId: player.id,
        source: resolution.source,
        mode,
      });

      const isBanned = await banService.isPlayerBanned(player.id);
      if (isBanned) {
        const timeRemaining = await banService.getBanTimeRemaining(player.id);
        const minutes = Math.ceil(timeRemaining / 60);
        return {
          success: false,
          message: `You are banned from queueing for ${minutes} more minute(s).`,
        };
      }

      for (const [queueKey, entries] of Object.entries(this.queues)) {
        if (entries.some((entry) => entry.discordId === discordId)) {
          return {
            success: false,
            message: `You are already in the ${queueKey} queue.`,
          };
        }
      }

      const queueKey: QueueKey = mode === 'CASUAL' ? 'Casual' : player.league;
      const queue = this.queues[queueKey];
      const entry: QueueEntry = {
        playerId: player.id,
        discordId: player.discord_id,
        username: player.discord_username,
        joinedAt: new Date(),
      };

      queue.push(entry);
      logger.info('Player joined queue', {
        playerId: player.id,
        playerLeague: player.league,
        queueKey,
        queueSize: queue.length,
      });

      if (queue.length >= 4) {
        await this.popQueue(queueKey);
      }

      return {
        success: true,
        message: `You joined the ${queueKey} queue! (${queue.length}/4)`,
        position: queue.length,
      };
    } catch (error) {
      logger.error('Error joining queue:', { discordId, mode, error });
      return {
        success: false,
        message: 'An error occurred while joining the queue.',
      };
    }
  }

  async leaveQueue(discordId: string): Promise<{
    success: boolean;
    message: string;
  }> {
    try {
      for (const [queueKey, entries] of Object.entries(this.queues)) {
        const index = entries.findIndex((entry) => entry.discordId === discordId);
        if (index !== -1) {
          entries.splice(index, 1);
          logger.info('Player left queue', { discordId, queueKey, queueSize: entries.length });
          return {
            success: true,
            message: `You left the ${queueKey} queue.`,
          };
        }
      }

      return {
        success: false,
        message: 'You are not in any queue.',
      };
    } catch (error) {
      logger.error('Error leaving queue:', { discordId, error });
      return {
        success: false,
        message: 'An error occurred while leaving the queue.',
      };
    }
  }

  async cancelQueueScrim(scrimId: number): Promise<QueueScrimCancelResult> {
    try {
      const scrim = await scrimService.getById(scrimId);
      if (!scrim) {
        return {
          success: false,
          message: `Scrim ${scrimId} was not found.`,
          scrimId,
          restoredPlayerIds: [],
        };
      }

      if (scrim.match_type !== 'QUEUE' && scrim.match_type !== 'CASUAL') {
        return {
          success: false,
          message: `Scrim ${scrim.scrim_uid} is not a queue scrim.`,
          scrimId,
          scrimUid: scrim.scrim_uid,
          restoredPlayerIds: [],
        };
      }

      if (scrim.status === 'completed' || scrim.status === 'cancelled') {
        return {
          success: false,
          message: `Scrim ${scrim.scrim_uid} is already ${scrim.status}.`,
          scrimId,
          scrimUid: scrim.scrim_uid,
          restoredPlayerIds: [],
        };
      }

      if (scrim.status !== 'checking_in' && scrim.status !== 'active') {
        return {
          success: false,
          message: `Scrim ${scrim.scrim_uid} cannot be cancelled while it is ${scrim.status}.`,
          scrimId,
          scrimUid: scrim.scrim_uid,
          restoredPlayerIds: [],
        };
      }

      const scrimPlayers = await scrimService.getScrimPlayers(scrimId);
      const playerIdsToRestore =
        scrim.status === 'checking_in'
          ? scrimPlayers
              .filter((scrimPlayer) => scrimPlayer.checked_in)
              .map((scrimPlayer) => scrimPlayer.player_id)
          : scrimPlayers.map((scrimPlayer) => scrimPlayer.player_id);

      await scrimService.cancelScrim(scrimId);
      const queueKey: QueueKey = scrim.match_type === 'CASUAL' ? 'Casual' : (scrim.league as League);
      const restoredPlayers = await this.restorePlayersToQueue(playerIdsToRestore, queueKey);

      logger.info('Admin cancelled queue scrim', {
        scrimId,
        scrimUid: scrim.scrim_uid,
        status: scrim.status,
        matchType: scrim.match_type,
        restoredCount: restoredPlayers.length,
      });

      return {
        success: true,
        message: `Cancelled scrim ${scrim.scrim_uid}. Returned ${restoredPlayers.length} player(s) to the ${queueKey} queue.`,
        scrimId,
        scrimUid: scrim.scrim_uid,
        restoredPlayerIds: restoredPlayers.map((player) => player.id),
      };
    } catch (error) {
      logger.error('Error cancelling queue scrim:', { scrimId, error });
      return {
        success: false,
        message: 'An error occurred while cancelling the scrim.',
        scrimId,
        restoredPlayerIds: [],
      };
    }
  }

  getQueueStatus(): Record<QueueKey, number> {
    return {
      Academy: this.queues.Academy?.length || 0,
      Champion: this.queues.Champion?.length || 0,
      Master: this.queues.Master?.length || 0,
      Casual: this.queues.Casual?.length || 0,
    };
  }

  getLeagueQueue(queueKey: QueueKey): QueueEntry[] {
    return this.queues[queueKey] || [];
  }

  isPlayerInQueue(discordId: string): {
    inQueue: boolean;
    queue?: QueueKey;
    league?: League;
    position?: number;
  } {
    for (const [queueKey, entries] of Object.entries(this.queues)) {
      const index = entries.findIndex((entry) => entry.discordId === discordId);
      if (index !== -1) {
        return {
          inQueue: true,
          queue: queueKey as QueueKey,
          ...(queueKey === 'Casual' ? {} : { league: queueKey as League }),
          position: index + 1,
        };
      }
    }
    return { inQueue: false };
  }

  private async popQueue(queueKey: QueueKey): Promise<void> {
    const queue = this.queues[queueKey];
    if (queue.length < 4) {
      logger.warn('Attempted to pop queue with less than 4 players', {
        queueKey,
        queueSize: queue.length,
      });
      return;
    }

    const queuedPlayers = queue.splice(0, 4);
    try {
      const playerIds = queuedPlayers.map((player) => player.playerId);
      const players = await playerService.getByIds(playerIds);
      const maps = await mapService.selectMapsForScrim(playerIds, 3);
      const scrim =
        queueKey === 'Casual'
          ? await casualScrimService.create(playerIds, maps)
          : await scrimService.createScrim(queueKey, playerIds, maps);

      logger.info('Queue popped', {
        queueKey,
        scrimId: scrim.id,
        scrimUid: scrim.scrim_uid,
        matchType: scrim.match_type,
        playerIds,
        playerLeagues: players.map((player) => player.league),
        mapIds: maps.map((map) => map.id),
      });

      this.emit('queuePop', {
        scrim,
        players,
        maps,
      } as QueuePopEvent);

      this.startCheckInTimeout(scrim.id);
    } catch (error) {
      // Put the exact four players back at the front in their original order.
      this.queues[queueKey] = [...queuedPlayers, ...this.queues[queueKey]];
      logger.error('Error popping queue; players restored', { queueKey, error });
    }
  }

  private startCheckInTimeout(scrimId: number): void {
    const timeoutMs = config.queue.checkInTimeout * 1000;

    setTimeout(async () => {
      try {
        const scrim = await scrimService.getById(scrimId);
        if (!scrim || scrim.status !== 'checking_in') return;

        const allCheckedIn = await scrimService.areAllPlayersCheckedIn(scrimId);
        if (allCheckedIn) return;

        const noShowPlayerIds = await scrimService.getNoShowPlayers(scrimId);
        logger.info('Check-in timeout expired', {
          scrimId,
          matchType: scrim.match_type,
          noShowCount: noShowPlayerIds.length,
        });

        for (const playerId of noShowPlayerIds) {
          await banService.applyDodgePenalty(playerId);
        }

        await scrimService.cancelScrim(scrimId);

        const scrimPlayers = await scrimService.getScrimPlayers(scrimId);
        const checkedInPlayers = scrimPlayers
          .filter((scrimPlayer) => scrimPlayer.checked_in)
          .map((scrimPlayer) => scrimPlayer.player_id);

        const queueKey: QueueKey = scrim.match_type === 'CASUAL' ? 'Casual' : (scrim.league as League);
        if (checkedInPlayers.length > 0) {
          await this.restorePlayersToQueue(checkedInPlayers, queueKey);
        }

        this.emit('checkInTimeout', {
          scrimId,
          noShowPlayerIds,
          checkedInPlayers,
        });
      } catch (error) {
        logger.error('Error processing check-in timeout:', { scrimId, error });
      }
    }, timeoutMs);
  }

  private async returnPlayerToQueue(player: Player, queueKey: QueueKey): Promise<void> {
    const queue = this.queues[queueKey];
    const entry: QueueEntry = {
      playerId: player.id,
      discordId: player.discord_id,
      username: player.discord_username,
      joinedAt: new Date(),
    };

    if (!queue.some((existing) => existing.playerId === player.id)) {
      queue.unshift(entry);
    }

    logger.info('Player returned to queue with priority', {
      playerId: player.id,
      playerLeague: player.league,
      queueKey,
    });
  }

  private async restorePlayersToQueue(playerIds: number[], queueKey: QueueKey): Promise<Player[]> {
    if (playerIds.length === 0) return [];

    const players = await playerService.getByIds(playerIds);
    for (const player of players) {
      await this.returnPlayerToQueue(player, queueKey);
    }

    return players;
  }

  clearLeagueQueue(queueKey: QueueKey): number {
    const queue = this.queues[queueKey];
    const count = queue.length;
    this.queues[queueKey] = [];
    logger.info('Queue cleared', { queueKey, removedPlayers: count });
    return count;
  }

  clearAllQueues(): number {
    let totalCleared = 0;
    for (const queueKey of Object.keys(this.queues)) {
      totalCleared += this.clearLeagueQueue(queueKey as QueueKey);
    }
    return totalCleared;
  }
}

export const queueService = new QueueService();
