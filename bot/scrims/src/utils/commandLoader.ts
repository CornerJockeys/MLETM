import { Collection } from 'discord.js';
import { readdir } from 'fs/promises';
import { join } from 'path';
import { pathToFileURL } from 'url';
import { logger } from './logger.js';

export interface Command {
  data: {
    name: string;
    toJSON: () => any;
  };
  execute: (...args: any[]) => Promise<void>;
  autocomplete?: (...args: any[]) => Promise<void>;
}

export async function loadCommands(): Promise<Collection<string, Command>> {
  const commands = new Collection<string, Command>();

  const commandsPath = join(__dirname, '..', 'commands');

  logger.info(`Loading commands from: ${commandsPath}`);

  try {
    const allFiles = await readdir(commandsPath);
    logger.debug(`Files in commands directory: ${allFiles.join(', ')}`);

    const commandFiles = allFiles.filter(file => file.endsWith('.js'));
    logger.debug(`JS files found: ${commandFiles.join(', ')}`);

    for (const file of commandFiles) {
      const filePath = join(commandsPath, file);
      const commandUrl = pathToFileURL(filePath).href;
      const command = await import(commandUrl) as Command;

      if ('data' in command && 'execute' in command) {
        commands.set(command.data.name, command);
        logger.info(`Loaded command: ${command.data.name}`);
      } else {
        logger.warn(`Command at ${filePath} is missing required "data" or "execute" property`);
      }
    }

    logger.info(`Successfully loaded ${commands.size} commands`);
    return commands;
  } catch (error) {
    logger.error('Error loading commands:', error);
    throw error;
  }
}
