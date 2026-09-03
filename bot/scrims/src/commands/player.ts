import {
  AutocompleteInteraction,
  ChatInputCommandInteraction,
  EmbedBuilder,
  SlashCommandBuilder,
} from 'discord.js';
import { getEligibilityCardDataByMleName } from '../services/eligibility-card/profile-data.js';
import { formatScrimPoints } from '../services/eligibility-card/normalize.js';
import { mletmService } from '../services/mletm.service.js';
import { logger } from '../utils/logger.js';

export const data = new SlashCommandBuilder()
  .setName('player')
  .setDescription('View an MLE Trackmania player eligibility card')
  .addStringOption((option) =>
    option
      .setName('name')
      .setDescription('MLE player name')
      .setRequired(true)
      .setAutocomplete(true),
  );

export async function autocomplete(interaction: AutocompleteInteraction): Promise<void> {
  const focused = interaction.options.getFocused();

  try {
    const players = await mletmService.searchPlayers(focused, 25);
    await interaction.respond(
      players.map((player) => ({
        name: [player.mleName, player.tmName ? `TM: ${player.tmName}` : null]
          .filter(Boolean)
          .join(' · ')
          .slice(0, 100),
        value: player.mleName.slice(0, 100),
      })),
    );
  } catch (error) {
    logger.warn('Player autocomplete failed', { focused, error });
    await interaction.respond([]);
  }
}

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  const mleName = interaction.options.getString('name', true).trim();
  await interaction.deferReply();

  try {
    const card = await getEligibilityCardDataByMleName(mleName);
    if (!card) {
      await interaction.editReply(`No MLE Trackmania player was found for **${mleName}**.`);
      return;
    }

    // Temporary preview until the SVG -> PNG step is wired in.
    const embed = new EmbedBuilder()
      .setTitle(`${card.mleName} — Eligibility Card`)
      .setDescription(`Trackmania: **${card.tmName}**`)
      .addFields(
        { name: 'Team', value: card.team, inline: true },
        { name: 'Division', value: card.division || '—', inline: true },
        { name: 'Salary', value: String(card.salary), inline: true },
        { name: 'Status', value: card.status, inline: true },
        { name: 'Scrim Points', value: formatScrimPoints(card), inline: true },
        { name: 'Franchise Staff', value: card.franchiseStaff ?? '—', inline: true },
      )
      .setFooter({ text: 'Eligibility card image output pending PNG renderer' });

    await interaction.editReply({ embeds: [embed] });
  } catch (error) {
    logger.error('Error executing /player command', { mleName, error });
    await interaction.editReply('An error occurred while loading that player eligibility card.');
  }
}
