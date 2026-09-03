import { Client, EmbedBuilder, TextChannel } from 'discord.js';
import { QueuePopEvent, queueService } from '../services/queue.service.js';
import { UrlGenerator } from '../utils/urlGenerator.js';
import { logger } from '../utils/logger.js';
import { buildCheckInActionRow, buildQueuePopPrompt } from './checkinInteractions.js';

export class QueueEventHandler {
  constructor(private client: Client) {
    this.setupEventListeners();
  }

  private setupEventListeners(): void {
    queueService.on('queuePop', async (event: QueuePopEvent) => {
      await this.handleQueuePop(event);
    });

    queueService.on('checkInTimeout', async (event: any) => {
      await this.handleCheckInTimeout(event);
    });

    logger.info('Queue event handlers initialized');
  }

  private async handleQueuePop(event: QueuePopEvent): Promise<void> {
    const { scrim, players, maps } = event;
    const isCasual = scrim.match_type === 'CASUAL';
    const scrimLabel = isCasual ? 'Casual Scrim' : `${scrim.league} League`;

    logger.info('Handling queue pop', {
      scrimId: scrim.id,
      scrimUid: scrim.scrim_uid,
      playerCount: players.length,
      league: scrim.league,
      matchType: scrim.match_type,
    });

    const urlData = UrlGenerator.createUrlData(
      scrim.scrim_uid,
      players.map((player) => player.discord_username),
      maps.map((map) => map.name),
    );
    const formUrl = UrlGenerator.generateWebAppUrl(urlData);

    const embed = new EmbedBuilder()
      .setColor(0x00ff00)
      .setTitle('🎮 Scrim Match Found!')
      .setDescription(`**${scrimLabel}** - Scrim ID: \`${scrim.scrim_uid}\``)
      .addFields(
        {
          name: '👥 Players',
          value: players.map((player) => `• ${player.discord_username}`).join('\n'),
          inline: true,
        },
        {
          name: '🗺️ Maps',
          value: maps.map((map, index) => `${index + 1}. ${map.name}`).join('\n'),
          inline: true,
        },
        {
          name: '⏰ Check-in Deadline',
          value: scrim.checkin_deadline
            ? `<t:${Math.floor(new Date(scrim.checkin_deadline).getTime() / 1000)}:R>`
            : '5 minutes',
          inline: false,
        },
        {
          name: '📝 Submit Results',
          value: `[Click here to submit match results](${formUrl})`,
          inline: false,
        },
      )
      .setFooter({ text: 'Use the Check in button to confirm your participation' })
      .setTimestamp();

    for (const player of players) {
      try {
        const user = await this.client.users.fetch(player.discord_id);
        await user.send({
          content: buildQueuePopPrompt(),
          embeds: [embed],
          components: [buildCheckInActionRow()],
        });

        logger.info('Sent queue pop DM', {
          playerId: player.id,
          discordId: player.discord_id,
        });
      } catch (error) {
        logger.error('Failed to send queue pop DM', {
          playerId: player.id,
          discordId: player.discord_id,
          error,
        });
      }
    }

    await this.postToScrimChannel(isCasual ? 'Casual' : scrim.league, embed);
  }

  private async handleCheckInTimeout(event: {
    scrimId: number;
    noShowPlayerIds: number[];
    checkedInPlayers: number[];
  }): Promise<void> {
    const { scrimId, noShowPlayerIds, checkedInPlayers } = event;

    logger.info('Handling check-in timeout', {
      scrimId,
      noShowCount: noShowPlayerIds.length,
      checkedInCount: checkedInPlayers.length,
    });

    for (const playerId of noShowPlayerIds) {
      try {
        const { playerService } = await import('../services/player.service.js');
        const { banService } = await import('../services/ban.service.js');

        const player = await playerService.getById(playerId);
        if (!player) continue;

        const user = await this.client.users.fetch(player.discord_id);
        const ban = await banService.getActiveBan(playerId);

        const banDuration = ban
          ? Math.ceil((new Date(ban.ban_end).getTime() - new Date(ban.ban_start).getTime()) / 60000)
          : 0;

        const embed = new EmbedBuilder()
          .setColor(0xff0000)
          .setTitle('❌ Queue Dodge Penalty')
          .setDescription('You failed to check in for your scrim match.')
          .addFields(
            {
              name: '⛔ Penalty',
              value: `Banned from queueing for **${banDuration} minutes**`,
              inline: true,
            },
            {
              name: '🔢 Recent Dodges',
              value: ban ? `${ban.dodge_count} in last 24h` : '1',
              inline: true,
            },
          )
          .setFooter({ text: 'Please check in promptly when a match is found!' })
          .setTimestamp();

        await user.send({ embeds: [embed] });
        logger.info('Sent dodge penalty notification', { playerId, banDuration });
      } catch (error) {
        logger.error('Failed to send dodge penalty DM', { playerId, error });
      }
    }

    for (const playerId of checkedInPlayers) {
      try {
        const { playerService } = await import('../services/player.service.js');
        const player = await playerService.getById(playerId);
        if (!player) continue;

        const user = await this.client.users.fetch(player.discord_id);
        const embed = new EmbedBuilder()
          .setColor(0xffa500)
          .setTitle('⚠️ Match Cancelled')
          .setDescription('Your scrim was cancelled because not all players checked in.')
          .addFields({
            name: "✅ You've been returned to the queue",
            value: 'You have priority and will be matched with the next available players.',
            inline: false,
          })
          .setTimestamp();

        await user.send({ embeds: [embed] });
        logger.info('Sent match cancelled notification', { playerId });
      } catch (error) {
        logger.error('Failed to send match cancelled DM', { playerId, error });
      }
    }
  }

  private async postToScrimChannel(queueLabel: string, embed: EmbedBuilder): Promise<void> {
    try {
      const channelId = process.env[`SCRIM_CHANNEL_${queueLabel.toUpperCase()}`];

      if (!channelId) {
        logger.debug(`No scrim channel configured for ${queueLabel}`);
        return;
      }

      const channel = await this.client.channels.fetch(channelId);
      if (channel?.isTextBased()) {
        const heading = queueLabel === 'Casual' ? 'Casual Scrim Match Found!' : `${queueLabel} Scrim Match Found!`;
        await (channel as TextChannel).send({
          content: [
            `🎮 **${heading}**`,
            '',
            'Use the **Check in now** button below to confirm your spot here.',
          ].join('\n'),
          embeds: [embed],
          components: [buildCheckInActionRow()],
        });

        logger.info('Posted to scrim channel', { queueLabel, channelId });
      }
    } catch (error) {
      logger.error('Failed to post to scrim channel', { queueLabel, error });
    }
  }
}
