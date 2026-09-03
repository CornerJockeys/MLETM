import { existsSync } from 'node:fs';
import path from 'node:path';
import type { EligibilityCardAssetRefs, EligibilityCardData } from './types.js';

const MODULE_ASSET_ROOT = path.resolve(__dirname, '../../../../../shared/community-card/assets');

function resolveDefaultAssetRoot(): string {
  const candidates = [
    process.env.ELIGIBILITY_CARD_ASSET_ROOT,
    MODULE_ASSET_ROOT,
    path.resolve(process.cwd(), 'shared/community-card/assets'),
    path.resolve(process.cwd(), '../../shared/community-card/assets'),
  ].filter((candidate): candidate is string => Boolean(candidate));

  return candidates.find((candidate) => existsSync(candidate)) ?? MODULE_ASSET_ROOT;
}

const DEFAULT_ASSET_ROOT = resolveDefaultAssetRoot();

export function resolveEligibilityCardAssets(
  data: EligibilityCardData,
  assetRoot = DEFAULT_ASSET_ROOT,
): EligibilityCardAssetRefs {
  const teamDir = path.join(assetRoot, 'teams', data.teamFrameKey);

  return {
    teamFrame: path.join(teamDir, 'frame.png'),
    teamLogo: path.join(teamDir, 'logo.png'),
    divisionStamp: path.join(assetRoot, 'divisions', `${data.divisionStampKey}.png`),
    seasonStamp: path.join(assetRoot, 'seasons', `${data.seasonStampKey}.png`),
    staffStamp: data.staffStampKey
      ? path.join(assetRoot, 'staff', `${data.staffStampKey}.png`)
      : null,
  };
}
