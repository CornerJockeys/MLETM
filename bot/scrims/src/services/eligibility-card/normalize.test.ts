import { describe, expect, it } from 'vitest';
import { formatScrimPoints, normalizeEligibilityCardData } from './normalize.js';

const base = {
  tmid: 'T0001',
  mleName: 'Ant',
  tmName: 'AntHill12',
  team: 'Jets',
  division: 'AL',
  salary: 8.5,
  franchiseStaff: 'GM' as const,
  seasonEntry: 'S3',
};

describe('normalizeEligibilityCardData', () => {
  it('normalizes null scrim points to zero', () => {
    const data = normalizeEligibilityCardData({ ...base, scrimPoints: null });
    expect(data.scrimPoints).toBe(0);
    expect(formatScrimPoints(data)).toBe('0/30');
  });

  it('does not cap scrim points above the eligibility threshold', () => {
    const data = normalizeEligibilityCardData({ ...base, scrimPoints: 35 });
    expect(formatScrimPoints(data)).toBe('35/30');
  });

  it('uses the team key for both the logo and team-specific frame by default', () => {
    const data = normalizeEligibilityCardData({ ...base, scrimPoints: 35 });
    expect(data.teamLogoKey).toBe('jets');
    expect(data.teamFrameKey).toBe('jets');
  });

  it('omits the staff stamp when the player is not franchise staff', () => {
    const data = normalizeEligibilityCardData({
      ...base,
      franchiseStaff: null,
      scrimPoints: 0,
    });
    expect(data.staffStampKey).toBeNull();
  });
});
