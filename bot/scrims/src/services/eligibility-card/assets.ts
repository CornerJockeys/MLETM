import path from 'node:path';
import type { EligibilityCardAssetRefs, EligibilityCardData } from './types.js';

const DEFAULT_ASSET_ROOT = path.resolve(process.cwd(), '../../shared/community-card/assets');

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
