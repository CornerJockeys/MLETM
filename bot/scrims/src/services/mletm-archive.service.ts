import { config } from '../config.js';
import { logger } from '../utils/logger.js';

export type ScrimArchiveStage = 'session' | 'submission' | 'result';

function trimTrailingSlash(value: string): string {
  return value.replace(/\/+$/, '');
}

export class MleTmArchiveService {
  async archive(
    scrimUid: string,
    stage: ScrimArchiveStage,
    payload: unknown,
  ): Promise<boolean> {
    const writeToken = config.mletmApi.writeToken.trim();
    if (!writeToken) {
      logger.warn('MLETM archive write token is not configured; skipping scrim artifact', {
        scrimUid,
        stage,
      });
      return false;
    }

    const baseUrl = trimTrailingSlash(config.mletmApi.baseUrl);
    const url = `${baseUrl}/v1/runtime/scrims/${encodeURIComponent(scrimUid)}/${stage}`;

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          Authorization: `Bearer ${writeToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(config.mletmApi.timeoutMs),
      });

      if (!response.ok) {
        const detail = await response.text().catch(() => '');
        throw new Error(
          `MLETM archive write failed with HTTP ${response.status}${detail ? `: ${detail}` : ''}`,
        );
      }

      logger.info('MLETM scrim artifact archived', { scrimUid, stage });
      return true;
    } catch (error) {
      // Archive persistence is intentionally best-effort during the temporary repo-backed phase.
      // A GitHub/API outage must not break queueing, replay processing, or Elo.
      logger.warn('Failed to archive MLETM scrim artifact', {
        scrimUid,
        stage,
        error,
      });
      return false;
    }
  }
}

export const mletmArchiveService = new MleTmArchiveService();
