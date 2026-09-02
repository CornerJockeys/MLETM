export const ELO_CONFIG = {
  kBase: 16,
  kMax: 32,
  kScale: 0.15,
  denominator: 400,
  normalizeByLobbySize: false,
} as const;

export interface EloRaceParticipant {
  id: string | number;
  eloScore: number;
  roundsPlayed: number;
  finishPosition: number;
  teamId?: string | number | null;
}

export interface EloRaceResult {
  playerId: string | number;
  oldElo: number;
  newElo: number;
  eloChange: number;
}

export function getEloKFactor(roundsPlayed: number): number {
  const normalizedRounds = Math.max(0, Number(roundsPlayed) || 0);
  const decay = Math.exp(-Math.abs(ELO_CONFIG.kScale) * normalizedRounds);
  return ELO_CONFIG.kBase + ELO_CONFIG.kMax * decay;
}

export function getEloExpectedScore(playerElo: number, opponentElo: number): number {
  return 1 / (1 + Math.pow(10, (opponentElo - playerElo) / ELO_CONFIG.denominator));
}

export function getEloActualScoreFromPosition(position: number, totalDrivers: number): number {
  if (totalDrivers < 2) return 1;
  if (!Number.isInteger(position) || position < 1 || position > totalDrivers) {
    throw new Error(`Invalid finish position ${position} for ${totalDrivers} drivers`);
  }
  return (totalDrivers - position) / (totalDrivers - 1);
}

export function calculateEloRaceUpdates(
  participants: EloRaceParticipant[],
): EloRaceResult[] {
  const driverCount = participants.length;
  if (driverCount === 0) return [];

  const ids = new Set<string>();
  for (const participant of participants) {
    const key = String(participant.id);
    if (ids.has(key)) {
      throw new Error(`Duplicate Elo participant id: ${key}`);
    }
    ids.add(key);
  }

  const changes = new Map<string, number>();
  for (const participant of participants) {
    changes.set(String(participant.id), 0);
  }

  for (let i = 0; i < driverCount; i++) {
    const player = participants[i];
    const playerId = String(player.id);
    const kFactor = getEloKFactor(player.roundsPlayed);
    const actualResult = getEloActualScoreFromPosition(player.finishPosition, driverCount);

    for (let j = 0; j < driverCount; j++) {
      if (i === j) continue;

      const opponent = participants[j];
      const expectedResult = getEloExpectedScore(player.eloScore, opponent.eloScore);
      let pairDelta = kFactor * (actualResult - expectedResult);

      const isTeammate =
        player.teamId !== undefined &&
        player.teamId !== null &&
        opponent.teamId !== undefined &&
        opponent.teamId !== null &&
        String(player.teamId) === String(opponent.teamId);

      if (isTeammate) {
        pairDelta *= 0.5;
      }

      changes.set(playerId, (changes.get(playerId) ?? 0) + pairDelta);
    }
  }

  return participants.map((participant) => {
    let change = changes.get(String(participant.id)) ?? 0;
    if (ELO_CONFIG.normalizeByLobbySize && driverCount > 1) {
      change /= driverCount - 1;
    }

    return {
      playerId: participant.id,
      oldElo: participant.eloScore,
      newElo: Math.round(participant.eloScore + change),
      eloChange: Number(change.toFixed(2)),
    };
  });
}
