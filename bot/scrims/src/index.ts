import { DiscordBot } from './bot.js';
import { db } from './db/index.js';
import { logger } from './utils/logger.js';
import { config } from './config.js';

async function main() {
  logger.info('Starting Trackmania Scrim Bot...');

  const dbHealthy = await db.healthCheck();
  if (!dbHealthy) {
    logger.error('Database health check failed. Exiting...');
    process.exit(1);
  }
  logger.info('Database connection established');

  const bot = new DiscordBot();

  await bot.loadCommands();
  logger.info('Command handlers loaded successfully');

  const shutdown = async (signal: string) => {
    logger.info(`Received ${signal}. Shutting down gracefully...`);
    await bot.stop();
    await db.close();
    process.exit(0);
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));

  await bot.start();
  bot.initializeQueueEvents();

  logger.info(`Bot is running in ${config.app.nodeEnv} mode`);
  logger.info(
    'Legacy Elo polling is disabled; verified round results must be finalized through EloFinalizerService.',
  );
}

main().catch((error) => {
  logger.error('Fatal error during startup:', error);
  process.exit(1);
});
