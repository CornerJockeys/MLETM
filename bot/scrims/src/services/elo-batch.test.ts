import { describe, expect, it } from 'vitest';
import { calculateBatchedElo } from './elo-batch.js';

describe('calculateBatchedElo', () => {
  it('carries temporary ratings and rounds played forward between rounds', () => {
    const result = calculateBatchedElo(
      [
        { playerId: 1, startingRating: 1000, roundsPlayed: 0, teamId: 1 },
        { playerId: 2, startingRating: 1000, roundsPlayed: 0, teamId: 1 },
        { playerId: 3, startingRating: 1000, roundsPlayed: 0, teamId: 2 },
        { playerId: 4, startingRating: 1000, roundsPlayed: 0, teamId: 2 },
      ],
      [
        {
          round: 1,
          results: [
            { playerId: 1, finishPosition: 1 },
            { playerId: 3, finishPosition: 2 },
            { playerId: 2, finishPosition: 3 },
            { playerId: 4, finishPosition: 4 },
          ],
        },
        {
          round: 2,
          results: [
            { playerId: 4, finishPosition: 1 },
            { playerId: 2, finishPosition: 2 },
            { playerId: 3, finishPosition: 3 },
            { playerId: 1, finishPosition: 4 },
          ],
        },
      ],
    );

    const player1 = result.find((player) => player.playerId === 1)!;
    expect(player1.rounds).toHaveLength(2);
    expect(player1.rounds[1].startingRating).toBe(player1.rounds[0].endingRating);
    expect(player1.startingRoundsPlayed).toBe(0);
    expect(player1.endingRoundsPlayed).toBe(2);
    expect(player1.endingRating - player1.startingRating).toBe(player1.ratingChange);
  });

  it('uses lifetime rounds played as the starting K-factor input', () => {
    const newPlayer = calculateBatchedElo(
      [
        { playerId: 1, startingRating: 1000, roundsPlayed: 0 },
        { playerId: 2, startingRating: 1000, roundsPlayed: 0 },
      ],
      [{ round: 1, results: [{ playerId: 1, finishPosition: 1 }, { playerId: 2, finishPosition: 2 }] }],
    );

    const veteran = calculateBatchedElo(
      [
        { playerId: 1, startingRating: 1000, roundsPlayed: 100 },
        { playerId: 2, startingRating: 1000, roundsPlayed: 100 },
      ],
      [{ round: 1, results: [{ playerId: 1, finishPosition: 1 }, { playerId: 2, finishPosition: 2 }] }],
    );

    expect(Math.abs(newPlayer[0].ratingChange)).toBeGreaterThan(Math.abs(veteran[0].ratingChange));
  });

  it('rejects incomplete round inputs rather than silently rating partial lobbies', () => {
    expect(() =>
      calculateBatchedElo(
        [
          { playerId: 1, startingRating: 1000, roundsPlayed: 0 },
          { playerId: 2, startingRating: 1000, roundsPlayed: 0 },
        ],
        [{ round: 1, results: [{ playerId: 1, finishPosition: 1 }] }],
      ),
    ).toThrow('does not contain every Elo participant');
  });
});
