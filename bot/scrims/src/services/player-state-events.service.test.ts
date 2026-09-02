import { describe, expect, it, vi } from 'vitest';
import { PlayerStateEventsService } from './player-state-events.service.js';

describe('PlayerStateEventsService', () => {
  it('does not emit an eligibility event when eligibility does not change', async () => {
    const service = new PlayerStateEventsService();
    const record = vi.spyOn(service, 'record');

    const result = await service.recordEligibilityTransition({
      playerId: 1,
      eligibleBefore: false,
      eligibleAfter: false,
      pointsBefore: 20,
      pointsAfter: 25,
    });

    expect(result).toBeNull();
    expect(record).not.toHaveBeenCalled();
  });

  it('classifies crossing the threshold as eligibility_gained', async () => {
    const service = new PlayerStateEventsService();
    const record = vi.spyOn(service, 'record').mockResolvedValue({
      id: 1,
      player_id: 1,
      event_type: 'eligibility_gained',
      old_value: null,
      new_value: null,
      source: 'scrim_completion',
      source_ref: 'scrim:10',
      metadata: {},
      created_at: new Date(),
    });

    await service.recordEligibilityTransition({
      playerId: 1,
      eligibleBefore: false,
      eligibleAfter: true,
      pointsBefore: 25,
      pointsAfter: 30,
      source: 'scrim_completion',
      sourceRef: 'scrim:10',
    });

    expect(record).toHaveBeenCalledWith(
      expect.objectContaining({
        playerId: 1,
        eventType: 'eligibility_gained',
        oldValue: { eligible: false, scrimPoints: 25 },
        newValue: { eligible: true, scrimPoints: 30 },
      }),
    );
  });

  it('classifies dropping below the threshold as eligibility_lost', async () => {
    const service = new PlayerStateEventsService();
    const record = vi.spyOn(service, 'record').mockResolvedValue({
      id: 2,
      player_id: 1,
      event_type: 'eligibility_lost',
      old_value: null,
      new_value: null,
      source: 'admin',
      source_ref: null,
      metadata: {},
      created_at: new Date(),
    });

    await service.recordEligibilityTransition({
      playerId: 1,
      eligibleBefore: true,
      eligibleAfter: false,
      pointsBefore: 30,
      pointsAfter: 25,
      source: 'admin',
    });

    expect(record).toHaveBeenCalledWith(
      expect.objectContaining({ eventType: 'eligibility_lost' }),
    );
  });

  it('does not emit a salary event when salary is unchanged', async () => {
    const service = new PlayerStateEventsService();
    const record = vi.spyOn(service, 'record');

    const result = await service.recordSalaryChange({
      playerId: 1,
      salaryBefore: 8.5,
      salaryAfter: 8.5,
    });

    expect(result).toBeNull();
    expect(record).not.toHaveBeenCalled();
  });
});
