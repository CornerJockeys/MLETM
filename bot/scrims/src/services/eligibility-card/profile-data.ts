import { mletmService } from '../mletm.service.js';
import { scrimPointsService, SCRIM_POINTS_ELIGIBILITY_THRESHOLD } from '../scrim-points.service.js';
import { normalizeEligibilityCardData } from './normalize.js';
import type { EligibilityCardData, FranchiseStaffRole } from './types.js';

function normalizeFranchiseStaff(value: string): FranchiseStaffRole {
  switch (String(value || '').trim().toUpperCase()) {
    case 'GM':
      return 'GM';
    case 'AGM':
      return 'AGM';
    case 'CAPT':
    case 'CAPTAIN':
    case 'C':
      return 'CAPT';
    default:
      return null;
  }
}

export async function getEligibilityCardDataByMleName(
  mleName: string,
): Promise<EligibilityCardData | null> {
  const profile = await mletmService.getPlayerByMleName(mleName);
  if (!profile) return null;

  const scrimPoints = profile.discordId
    ? await scrimPointsService.getPointsByDiscordId(profile.discordId)
    : 0;

  return normalizeEligibilityCardData({
    schemaVersion: 1,
    tmid: profile.tmid,
    accountId: profile.accountId,
    mleName: profile.mleName,
    tmName: profile.tmName,
    team: profile.team,
    division: profile.division,
    salary: profile.salary,
    status: scrimPointsService.isEligible(scrimPoints) ? 'Eligible' : 'Ineligible',
    scrimPoints,
    scrimPointsRequired: SCRIM_POINTS_ELIGIBILITY_THRESHOLD,
    franchiseStaff: normalizeFranchiseStaff(profile.franchiseStaff),
    seasonEntry: 'S3',
  });
}
