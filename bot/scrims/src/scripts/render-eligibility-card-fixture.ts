import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { normalizeEligibilityCardData } from '../services/eligibility-card/normalize.js';
import { renderEligibilityCardSvg } from '../services/eligibility-card/render-svg.js';
import type { RawEligibilityCardData } from '../services/eligibility-card/types.js';

async function main(): Promise<void> {
  const fixturePath = path.resolve(process.cwd(), '../../shared/community-card/examples/ant.json');
  const outputDir = path.resolve(process.cwd(), 'tmp/community-card');
  const outputPath = path.join(outputDir, 'ant-eligibility-card.svg');

  const raw = JSON.parse(await readFile(fixturePath, 'utf8')) as RawEligibilityCardData;
  const data = normalizeEligibilityCardData(raw);
  const svg = await renderEligibilityCardSvg(data);

  await mkdir(outputDir, { recursive: true });
  await writeFile(outputPath, svg, 'utf8');

  console.log(`Eligibility card fixture written to ${outputPath}`);
}

main().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
