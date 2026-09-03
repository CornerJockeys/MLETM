import sharp from 'sharp';
import { renderEligibilityCardSvg } from './render-svg.js';
import type { EligibilityCardData } from './types.js';

export async function renderSvgToPng(svg: string): Promise<Buffer> {
  return sharp(Buffer.from(svg, 'utf8')).png().toBuffer();
}

export async function renderEligibilityCardPng(data: EligibilityCardData): Promise<Buffer> {
  const svg = await renderEligibilityCardSvg(data);
  return renderSvgToPng(svg);
}
