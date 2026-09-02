import type { EligibilityCardData, RawEligibilityCardData } from './types.js';

const DEFAULT_SCRIM_POINTS_REQUIRED = 30;
const DEFAULT_SEASON_ENTRY = 'S3';
const DEFAULT_STATUS = 'Eligible';

function normalizeKey(value: string): string {
  return value.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}

function normalizeSalary(value: number | string | null | undefined): number {
  if (value === null || value === undefined || value === '') return 0;
  const salary = Number(value);
  if (!Number.isFinite(salary) || salary < 0) {
    throw new Error(`Invalid salary value: ${String(value)}`);
  }
  return salary;
}

function normalizeScrimPoints(value: number | null | undefined): number {
  if (value === null || value === undefined || value === 0) return 0;
  if (!Number.isInteger(value) || value < 0) {
    throw new Error(`Invalid scrim points value: ${String(value)}`);
  }
  return value;
}

export function normalizeEligibilityCardData(raw: RawEligibilityCardData): EligibilityCardData {
  const teamKey = normalizeKey(raw.team);
  const divisionKey = normalizeKey(raw.division);
  const seasonEntry = raw.seasonEntry?.trim() || DEFAULT_SEASON_ENTRY;
  const staff = raw.franchiseStaff ?? null;

  return {
    schemaVersion: 1,
    tmid: raw.tmid.trim(),
    accountId: raw.accountId?.trim() || null,
    mleName: raw.mleName.trim(),
    tmName: raw.tmName.trim(),
    team: raw.team.trim(),
    division: raw.division.trim(),
    salary: normalizeSalary(raw.salary),
    status: raw.status?.trim() || DEFAULT_STATUS,
    scrimPoints: normalizeScrimPoints(raw.scrimPoints),
    scrimPointsRequired:
      raw.scrimPointsRequired && raw.scrimPointsRequired > 0
        ? raw.scrimPointsRequired
        : DEFAULT_SCRIM_POINTS_REQUIRED,
    franchiseStaff: staff,
    seasonEntry,
    teamLogoKey: raw.teamLogoKey?.trim() || teamKey,
    teamFrameKey: raw.teamFrameKey?.trim() || teamKey,
    divisionStampKey: raw.divisionStampKey?.trim() || divisionKey,
    seasonStampKey: raw.seasonStampKey?.trim() || normalizeKey(seasonEntry),
    staffStampKey: raw.staffStampKey?.trim() || (staff ? normalizeKey(staff) : null),
  };
}

export function formatScrimPoints(data: EligibilityCardData): string {
  return `${data.scrimPoints}/${data.scrimPointsRequired}`;
}
