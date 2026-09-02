import { describe, expect, it } from 'vitest';
import {
  calculateEloRaceUpdates,
  getEloActualScoreFromPosition,
  getEloExpectedScore,
  getEloKFactor,
} from './elo-formula.js';

describe('reference Elo formula', () => {
  it('uses the configured decaying K-factor', () => {
    expect(getEloKFactor(0)).toBeCloseTo(48, 6);
    expect(getEloKFactor(50)).toBeGreaterThan(16);
    expect(getEloKFactor(50)).toBeLessThan(17);
  });

  it('returns a 0.5 expected score for equal ratings', () => {
    expect(getEloExpectedScore(1500, 1500)).toBeCloseTo(0.5, 8);
  });

  it('maps finishing positions to equal intervals', () => {
    expect(getEloActualScoreFromPosition(1, 6)).toBe(1);
    expect(getEloActualScoreFromPosition(2, 6)).toBe(0.8);
    expect(getEloActualScoreFromPosition(6, 6)).toBe(0);
  });

  it('reproduces the reference six-driver calculation shape', () => {
    const results = calculateEloRaceUpdates([
      { id: 'DriverA', eloScore: 1600, roundsPlayed: 50, finishPosition: 1, teamId: 'Red' },
      { id: 'DriverB', eloScore: 1600, roundsPlayed: 50, finishPosition: 2, teamId: 'Red' },
      { id: 'DriverC', eloScore: 1500, roundsPlayed: 20, finishPosition: 3, teamId: 'Blue' },
      { id: 'DriverD', eloScore: 1500, roundsPlayed: 20, finishPosition: 4, teamId: 'Blue' },
      { id: 'DriverE', eloScore: 1400, roundsPlayed: 5, finishPosition: 5, teamId: 'Green' },
      { id: 'DriverF', eloScore: 1400, roundsPlayed: 5, finishPosition: 6, teamId: 'Green' },
    ]);

    expect(results).toHaveLength(6);
    expect(results[0].newElo).toBeGreaterThan(1600);
    expect(results[5].newElo).toBeLessThan(1400);
  });

  it('halves teammate pairwise influence', () => {
    const teammates = calculateEloRaceUpdates([
      { id: 1, eloScore: 1500, roundsPlayed: 0, finishPosition: 1, teamId: 'A' },
      { id: 2, eloScore: 1500, roundsPlayed: 0, finishPosition: 2, teamId: 'A' },
    ]);
    const opponents = calculateEloRaceUpdates([
      { id: 1, eloScore: 1500, roundsPlayed: 0, finishPosition: 1, teamId: 'A' },
      { id: 2, eloScore: 1500, roundsPlayed: 0, finishPosition: 2, teamId: 'B' },
    ]);

    expect(Math.abs(teammates[0].eloChange)).toBeCloseTo(
      Math.abs(opponents[0].eloChange) / 2,
      2,
    );
  });
});
