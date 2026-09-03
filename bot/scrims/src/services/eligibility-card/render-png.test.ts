import { describe, expect, it } from 'vitest';
import { renderEligibilityCardPng } from './render-png.js';
import type { EligibilityCardData } from './types.js';

const PNG_SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

const testCard: EligibilityCardData = {
  schemaVersion: 1,
  tmid: 'TTEST',
  accountId: null,
  mleName: 'Test Player',
  tmName: 'TestTM',
  team: 'Free Agent',
  division: 'AL',
  salary: 5,
  status: 'Ineligible',
  scrimPoints: 0,
  scrimPointsRequired: 30,
  franchiseStaff: null,
  seasonEntry: 'S3',
  teamLogoKey: 'unknown',
  teamFrameKey: 'unknown',
  divisionStampKey: 'al',
  seasonStampKey: 's3',
  staffStampKey: null,
};

describe('renderEligibilityCardPng', () => {
  it('renders a valid non-empty PNG buffer', async () => {
    const png = await renderEligibilityCardPng(testCard);

    expect(png.length).toBeGreaterThan(1000);
    expect(png.subarray(0, PNG_SIGNATURE.length)).toEqual(PNG_SIGNATURE);
  });
});
