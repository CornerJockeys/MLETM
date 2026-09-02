import { readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import type { EligibilityCardData } from './types.js';
import { getEligibilityCardTeamTheme } from './team-themes.js';

const PROD_TEAM_LOGO_BASE = 'https://raw.githubusercontent.com/CornerJockeys/MLETM/main/prod-plugin/assets/teams';

function toDataUri(buffer: Buffer, mimeType: string): string {
  return `data:${mimeType};base64,${buffer.toString('base64')}`;
}

export async function loadTeamLogoDataUri(
  data: EligibilityCardData,
  localPath: string,
): Promise<string | null> {
  if (existsSync(localPath)) {
    return toDataUri(await readFile(localPath), 'image/png');
  }

  const theme = getEligibilityCardTeamTheme(data.teamLogoKey);
  if (theme.key === 'unknown') return null;

  try {
    const response = await fetch(`${PROD_TEAM_LOGO_BASE}/${encodeURIComponent(theme.logoFile)}`);
    if (!response.ok) return null;
    return toDataUri(Buffer.from(await response.arrayBuffer()), 'image/png');
  } catch {
    return null;
  }
}
