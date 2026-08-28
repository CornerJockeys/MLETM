import { config as dotenvConfig } from 'dotenv';

dotenvConfig();

type SprocketIntegrationMode = 'required' | 'optional' | 'disabled';

interface Config {
  discord: {
    token: string;
    guildId: string;
    clientId: string;
  };
  database: {
    url: string;
    schema: string;
  };
  queue: {
    checkInTimeout: number;
    mapHistoryDays: number;
    minMapPoolSize: number;
  };
  bans: {
    dodgeBan1: number;
    dodgeBan2: number;
    dodgeBan3: number;
    dodgeWindow: number;
  };
  mletmApi: {
    baseUrl: string;
    timeoutMs: number;
    writeToken: string;
  };
  sprocket: {
    integrationMode: SprocketIntegrationMode;
  };
  appScript: {
    baseUrl: string;
  };
  app: {
    nodeEnv: string;
    port: number;
    logLevel: string;
  };
  leagues: string[];
}

function getEnvVar(key: string, defaultValue?: string): string {
  const value = process.env[key] ?? defaultValue;
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

function getEnvNumber(key: string, defaultValue: number): number {
  const value = process.env[key];
  if (!value) return defaultValue;
  const parsed = parseInt(value, 10);
  if (isNaN(parsed)) {
    throw new Error(`Environment variable ${key} must be a number`);
  }
  return parsed;
}

function getSprocketIntegrationMode(): SprocketIntegrationMode {
  const value = getEnvVar('SPROCKET_INTEGRATION_MODE', 'optional').trim().toLowerCase();
  if (value === 'required' || value === 'optional' || value === 'disabled') {
    return value;
  }
  throw new Error('SPROCKET_INTEGRATION_MODE must be required, optional, or disabled');
}

export const config: Config = {
  discord: {
    token: getEnvVar('DISCORD_BOT_TOKEN'),
    guildId: getEnvVar('DISCORD_GUILD_ID'),
    clientId: getEnvVar('DISCORD_CLIENT_ID'),
  },
  database: {
    url: getEnvVar('DATABASE_URL'),
    schema: getEnvVar('DATABASE_SCHEMA', 'trackmania'),
  },
  queue: {
    checkInTimeout: getEnvNumber('QUEUE_CHECK_IN_TIMEOUT', 300),
    mapHistoryDays: getEnvNumber('MAP_HISTORY_DAYS', 14),
    minMapPoolSize: getEnvNumber('MIN_MAP_POOL_SIZE', 10),
  },
  bans: {
    dodgeBan1: getEnvNumber('DODGE_BAN_1', 300),
    dodgeBan2: getEnvNumber('DODGE_BAN_2', 1800),
    dodgeBan3: getEnvNumber('DODGE_BAN_3', 7200),
    dodgeWindow: getEnvNumber('DODGE_WINDOW', 86400),
  },
  mletmApi: {
    baseUrl: getEnvVar(
      'MLETM_API_BASE_URL',
      'https://mle-tm-temp-api.mschifanoiii.workers.dev',
    ),
    timeoutMs: getEnvNumber('MLETM_API_TIMEOUT_MS', 5000),
    writeToken: process.env.MLETM_API_WRITE_TOKEN?.trim() ?? '',
  },
  sprocket: {
    integrationMode: getSprocketIntegrationMode(),
  },
  appScript: {
    baseUrl: getEnvVar('APPSCRIPT_BASE_URL'),
  },
  app: {
    nodeEnv: getEnvVar('NODE_ENV', 'development'),
    port: getEnvNumber('PORT', 3000),
    logLevel: getEnvVar('LOG_LEVEL', 'info'),
  },
  leagues: getEnvVar('LEAGUES', 'Academy,Champion,Master').split(','),
};
