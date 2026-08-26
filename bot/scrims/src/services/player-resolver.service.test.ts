import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Player } from '../types.js';
import { mletmService } from './mletm.service.js';
import { PlayerResolverService } from './player-resolver.service.js';
import { playerService } from './player.service.js';

vi.mock('./mletm.service.js');
vi.mock('./player.service.js');
vi.mock('../utils/logger.js');

describe('PlayerResolverService', () => {
  const sprocketPlayer: Player = {
    id: 1,
    discord_id: '244688236167823361',
    discord_username: 'Ant',
    league: 'Academy',
    created_at: new Date(),
    updated_at: new Date(),
  };

  const mletmPlayer: Player = {
    ...sprocketPlayer,
    id: 2,
    platform_account_ids: ['d7da5be8-5117-442a-a4fa-bd00f4dc4be9'],
  };

  const mletmProfile = {
    accountId: 'd7da5be8-5117-442a-a4fa-bd00f4dc4be9',
    tmid: 'T0001',
    mleName: 'Ant',
    tmName: 'AntHill12',
    discordId: '244688236167823361',
    team: 'Jets',
    franchiseStaff: 'GM',
    rosterSlot: 'A',
    salary: 8.5,
    league: 'ACADEMY',
    division: 'AL',
    rostered: true,
  };

  let resolver: PlayerResolverService;

  beforeEach(() => {
    vi.clearAllMocks();
    resolver = new PlayerResolverService();
    vi.mocked(mletmService.deriveLeague).mockReturnValue('Academy');
  });

  it('uses Sprocket first when Discord ID resolves there', async () => {
    vi.mocked(playerService.syncPlayerFromSprocket).mockResolvedValue(sprocketPlayer);

    const result = await resolver.resolvePlayer('244688236167823361', 'Ant');

    expect(result).toEqual({ player: sprocketPlayer, source: 'sprocket' });
    expect(playerService.syncPlayerFromSprocket).toHaveBeenCalledWith(
      '244688236167823361',
      'Ant',
    );
    expect(mletmService.getPlayerByDiscordId).not.toHaveBeenCalled();
  });

  it('falls back to MLETM using the same Discord ID when Sprocket has no usable player', async () => {
    vi.mocked(playerService.syncPlayerFromSprocket).mockResolvedValue(null);
    vi.mocked(mletmService.getPlayerByDiscordId).mockResolvedValue(mletmProfile);
    vi.mocked(playerService.syncPlayerFromMleTm).mockResolvedValue(mletmPlayer);

    const result = await resolver.resolvePlayer('244688236167823361', 'Some Display Name');

    expect(result).toEqual({ player: mletmPlayer, source: 'mletm' });
    expect(mletmService.getPlayerByDiscordId).toHaveBeenCalledWith('244688236167823361');
    expect(playerService.syncPlayerFromMleTm).toHaveBeenCalledWith(
      '244688236167823361',
      'Some Display Name',
      mletmProfile.accountId,
      'Academy',
    );
  });

  it('falls back to MLETM when the Sprocket lookup errors', async () => {
    vi.mocked(playerService.syncPlayerFromSprocket).mockRejectedValue(new Error('Sprocket unavailable'));
    vi.mocked(mletmService.getPlayerByDiscordId).mockResolvedValue(mletmProfile);
    vi.mocked(playerService.syncPlayerFromMleTm).mockResolvedValue(mletmPlayer);

    const result = await resolver.resolvePlayer('244688236167823361', 'Ant');

    expect(result?.source).toBe('mletm');
    expect(mletmService.getPlayerByDiscordId).toHaveBeenCalledWith('244688236167823361');
  });

  it('trims Discord ID before either identity source sees it', async () => {
    vi.mocked(playerService.syncPlayerFromSprocket).mockResolvedValue(null);
    vi.mocked(mletmService.getPlayerByDiscordId).mockResolvedValue(mletmProfile);
    vi.mocked(playerService.syncPlayerFromMleTm).mockResolvedValue(mletmPlayer);

    await resolver.resolvePlayer('  244688236167823361  ', 'Ant');

    expect(playerService.syncPlayerFromSprocket).toHaveBeenCalledWith(
      '244688236167823361',
      'Ant',
    );
    expect(mletmService.getPlayerByDiscordId).toHaveBeenCalledWith('244688236167823361');
  });

  it('never attempts a username-only lookup when Discord ID is empty', async () => {
    const result = await resolver.resolvePlayer('   ', 'Ant');

    expect(result).toBeNull();
    expect(playerService.syncPlayerFromSprocket).not.toHaveBeenCalled();
    expect(mletmService.getPlayerByDiscordId).not.toHaveBeenCalled();
  });

  it('returns null when neither source resolves the Discord ID', async () => {
    vi.mocked(playerService.syncPlayerFromSprocket).mockResolvedValue(null);
    vi.mocked(mletmService.getPlayerByDiscordId).mockResolvedValue(null);

    const result = await resolver.resolvePlayer('999999999999999999', 'Unknown');

    expect(result).toBeNull();
  });
});
