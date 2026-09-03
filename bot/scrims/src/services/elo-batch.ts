import type { MatchType } from '../types.js';
import { calculateEloRaceUpdates } from './elo-formula.js';

export interface BatchedEloPlayerState {
  playerId: number;
  startingRating: number;
  roundsPlayed: number;
  teamId?: string | number | null;
}

export interface BatchedEloRoundResult {
  playerId: number;
  finishPosition: number;
}

export interface BatchedEloRound {
  round: number;
  results: BatchedEloRoundResult[];
}

export interface BatchedEloPlayerResult {
  playerId: number;
  startingRating: number;
  endingRating: number;
  ratingChange: number;
  startingRoundsPlayed: number;
  endingRoundsPlayed: number;
  rounds: Array<{
    round: number;
    finishPosition: number;
    startingRating: number;
    delta: number;
    endingRating: number;
  }>;
}

export function shouldProcessElo(
  matchType: MatchType,
  enableCasualForTesting = false,
): boolean {
  if (matchType === 'CASUAL') return enableCasualForTesting;
  return true;
}

export function calculateBatchedElo(
  players: BatchedEloPlayerState[],
  rounds: BatchedEloRound[],
): BatchedEloPlayerResult[] {
  if (players.length < 2) {
    throw new Error('Batched Elo requires at least two players');
  }

  const playerIds = new Set(players.map((player) => player.playerId));
  if (playerIds.size !== players.length) {
    throw new Error('Batched Elo received duplicate player ids');
  }

  const currentRating = new Map<number, number>();
  const currentRoundsPlayed = new Map<number, number>();
  const audit = new Map<number, BatchedEloPlayerResult['rounds']>();

  for (const player of players) {
    currentRating.set(player.playerId, player.startingRating);
    currentRoundsPlayed.set(player.playerId, Math.max(0, player.roundsPlayed));
    audit.set(player.playerId, []);
  }

  const sortedRounds = [...rounds].sort((a, b) => a.round - b.round);

  for (const round of sortedRounds) {
    if (round.results.length !== players.length) {
      throw new Error(`Round ${round.round} does not contain every Elo participant`);
    }

    const seen = new Set<number>();
    for (const result of round.results) {
      if (!playerIds.has(result.playerId)) {
        throw new Error(`Round ${round.round} contains unknown player ${result.playerId}`);
      }
      if (seen.has(result.playerId)) {
        throw new Error(`Round ${round.round} contains duplicate player ${result.playerId}`);
      }
      seen.add(result.playerId);
    }

    const raceResults = calculateEloRaceUpdates(
      round.results.map((result) => {
        const player = players.find((candidate) => candidate.playerId === result.playerId)!;
        return {
          id: result.playerId,
          eloScore: currentRating.get(result.playerId)!,
          roundsPlayed: currentRoundsPlayed.get(result.playerId)!,
          finishPosition: result.finishPosition,
          teamId: player.teamId,
        };
      }),
    );

    for (const result of raceResults) {
      const playerId = Number(result.playerId);
      const finishPosition = round.results.find((entry) => entry.playerId === playerId)!.finishPosition;
      const startingRating = currentRating.get(playerId)!;
      const endingRating = result.newElo;

      audit.get(playerId)!.push({
        round: round.round,
        finishPosition,
        startingRating,
        delta: result.eloChange,
        endingRating,
      });

      currentRating.set(playerId, endingRating);
      currentRoundsPlayed.set(playerId, currentRoundsPlayed.get(playerId)! + 1);
    }
  }

  return players.map((player) => {
    const endingRating = currentRating.get(player.playerId)!;
    return {
      playerId: player.playerId,
      startingRating: player.startingRating,
      endingRating,
      ratingChange: endingRating - player.startingRating,
      startingRoundsPlayed: player.roundsPlayed,
      endingRoundsPlayed: currentRoundsPlayed.get(player.playerId)!,
      rounds: audit.get(player.playerId)!,
    };
  });
}
