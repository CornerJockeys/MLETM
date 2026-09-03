import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
} from 'discord.js';
import { queueService, type QueueMode } from '../services/queue.service.js';
import { logger } from '../utils/logger.js';

export const data = new SlashCommandBuilder()
  .setName('queue')
  .setDescription('Manage your queue status')
  .addSubcommand(subcommand =>
    subcommand
      .setName('join')
      .setDescription('Join a divisional or Casual scrim queue')
      .addStringOption(option =>
        option
          .setName('type')
          .setDescription('Queue type')
          .setRequired(false)
          .addChoices(
            { name: 'Divisional', value: 'DIVISIONAL' },
            { name: 'Casual', value: 'CASUAL' },
          ),
      ),
  )
  .addSubcommand(subcommand =>
    subcommand
      .setName('leave')
      .setDescription('Leave the current queue'),
  )
  .addSubcommand(subcommand =>
    subcommand
      .setName('status')
      .setDescription('Check current queue status'),
  )
  .addSubcommand(subcommand =>
    subcommand
      .setName('list')
      .setDescription('List all players in queues'),
  );

export async function execute(interaction: ChatInputCommandInteraction) {
  const subcommand = interaction.options.getSubcommand();

  try {
    switch (subcommand) {
      case 'join':
        await handleJoin(interaction);
        break;
      case 'leave':
        await handleLeave(interaction);
        break;
      case 'status':
        await handleStatus(interaction);
        break;
      case 'list':
        await handleList(interaction);
        break;
      default:
        await interaction.reply({
          content: 'Unknown subcommand.',
          ephemeral: true,
        });
    }
  } catch (error) {
    logger.error('Error executing queue command:', error);
    const errorMessage = {
      content: 'An error occurred while processing your request.',
      ephemeral: true,
    };

    if (interaction.replied || interaction.deferred) {
      await interaction.followUp(errorMessage);
    } else {
      await interaction.reply(errorMessage);
    }
  }
}

async function handleJoin(interaction: ChatInputCommandInteraction) {
  const discordId = interaction.user.id;
  const username = interaction.user.username;
  const mode = (interaction.options.getString('type') ?? 'DIVISIONAL') as QueueMode;

  const result = await queueService.joinQueue(discordId, username, mode);

  await interaction.reply({
    content: result.message,
    ephemeral: !result.success,
  });
}

async function handleLeave(interaction: ChatInputCommandInteraction) {
  const result = await queueService.leaveQueue(interaction.user.id);

  await interaction.reply({
    content: result.message,
    ephemeral: true,
  });
}

async function handleStatus(interaction: ChatInputCommandInteraction) {
  const status = queueService.getQueueStatus();

  const embed = new EmbedBuilder()
    .setColor(0x0099ff)
    .setTitle('Queue Status')
    .setDescription('Divisional queues stay separated; Casual accepts players from any division.')
    .addFields(
      { name: 'Academy', value: `${status.Academy}/4 players`, inline: true },
      { name: 'Champion', value: `${status.Champion}/4 players`, inline: true },
      { name: 'Master', value: `${status.Master}/4 players`, inline: true },
      { name: 'Casual', value: `${status.Casual}/4 players`, inline: true },
    )
    .setTimestamp();

  await interaction.reply({ embeds: [embed] });
}

async function handleList(interaction: ChatInputCommandInteraction) {
  const status = queueService.getQueueStatus();
  const queueKeys = ['Academy', 'Champion', 'Master', 'Casual'] as const;

  const embed = new EmbedBuilder()
    .setColor(0x0099ff)
    .setTitle('Queue Lists')
    .setDescription('All players currently in queues');

  let hasPlayers = false;
  for (const queueKey of queueKeys) {
    const queue = queueService.getLeagueQueue(queueKey);
    if (queue.length === 0) continue;

    hasPlayers = true;
    const players = queue.map((player, index) => `${index + 1}. ${player.username}`).join('\n');
    embed.addFields({ name: `${queueKey} (${status[queueKey]}/4)`, value: players });
  }

  if (!hasPlayers) {
    embed.setDescription('No players currently in any queue.');
  }

  embed.setTimestamp();
  await interaction.reply({ embeds: [embed] });
}
