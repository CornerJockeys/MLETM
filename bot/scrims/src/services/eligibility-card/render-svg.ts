import { formatScrimPoints } from './normalize.js';
import type { EligibilityCardData } from './types.js';

function escapeXml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
}

export function renderEligibilityCardSvg(data: EligibilityCardData): string {
  const staffStamp = data.franchiseStaff
    ? `<g transform="translate(560 90)">
        <circle cx="67.5" cy="67.5" r="61" fill="#101723" stroke="#d7dde8" stroke-width="5"/>
        <text x="67.5" y="34" text-anchor="middle" font-size="18" font-weight="700" fill="#d7dde8">FRANCHISE</text>
        <text x="67.5" y="84" text-anchor="middle" font-size="36" font-weight="800" fill="#ffffff">${escapeXml(data.franchiseStaff)}</text>
        <text x="67.5" y="116" text-anchor="middle" font-size="18" font-weight="700" fill="#d7dde8">STAFF</text>
      </g>`
    : '';

  const rows = [
    ['MLE NAME', data.mleName],
    ['TM NAME', data.tmName],
    ['TEAM', data.team],
    ['STATUS', data.status],
  ];

  const tableRows = rows
    .map(([label, value], index) => {
      const y = 995 + index * 62;
      return `<text x="125" y="${y}" font-size="21" font-weight="700" fill="#9aa8bd">${escapeXml(label)}</text>
        <text x="465" y="${y}" text-anchor="end" font-size="24" font-weight="800" fill="#ffffff">${escapeXml(value)}</text>`;
    })
    .join('\n');

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1350" viewBox="0 0 1080 1350">
  <defs>
    <linearGradient id="cardBg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#111827"/>
      <stop offset="1" stop-color="#060b14"/>
    </linearGradient>
  </defs>

  <!-- Temporary vector fallback. Team-specific frame artwork will replace this layer. -->
  <rect width="1080" height="1350" rx="54" fill="url(#cardBg)"/>
  <rect x="28" y="28" width="1024" height="1294" rx="42" fill="none" stroke="#8aa0bb" stroke-width="8"/>

  <text x="95" y="115" font-size="36" font-weight="900" fill="#ffffff">MLETM</text>
  <text x="95" y="154" font-size="24" font-weight="800" fill="#8aa0bb">COMMUNITY</text>

  ${staffStamp}

  <g transform="translate(715 90)">
    <circle cx="67.5" cy="67.5" r="61" fill="#101723" stroke="#d7dde8" stroke-width="5"/>
    <text x="67.5" y="76" text-anchor="middle" font-size="38" font-weight="900" fill="#ffffff">${escapeXml(data.division)}</text>
    <text x="67.5" y="108" text-anchor="middle" font-size="16" font-weight="700" fill="#d7dde8">DIVISION</text>
  </g>

  <g transform="translate(870 90)">
    <circle cx="67.5" cy="67.5" r="61" fill="#101723" stroke="#d7dde8" stroke-width="5"/>
    <text x="67.5" y="76" text-anchor="middle" font-size="38" font-weight="900" fill="#ffffff">${escapeXml(data.seasonEntry)}</text>
    <text x="67.5" y="108" text-anchor="middle" font-size="16" font-weight="700" fill="#d7dde8">SEASON</text>
  </g>

  <rect x="85" y="190" width="430" height="500" rx="26" fill="#0b1220" stroke="#25334a" stroke-width="3"/>
  <text x="300" y="430" text-anchor="middle" font-size="26" font-weight="800" fill="#536179">PORTRAIT / TEAM ART</text>

  <text x="560" y="320" font-size="78" font-weight="900" fill="#ffffff">${escapeXml(data.mleName)}</text>
  <text x="560" y="382" font-size="33" font-weight="700" fill="#9aa8bd">${escapeXml(data.tmName)}</text>

  <rect x="95" y="715" width="405" height="215" rx="22" fill="#0b1220" stroke="#25334a" stroke-width="3"/>
  <text x="297" y="780" text-anchor="middle" font-size="26" font-weight="800" fill="#9aa8bd">SALARY</text>
  <text x="297" y="875" text-anchor="middle" font-size="76" font-weight="900" fill="#ffffff">${escapeXml(String(data.salary))}</text>

  <rect x="95" y="955" width="405" height="290" rx="22" fill="#0b1220" stroke="#25334a" stroke-width="3"/>
  ${tableRows}

  <rect x="565" y="625" width="420" height="365" rx="26" fill="#0b1220" stroke="#25334a" stroke-width="3"/>
  <text x="775" y="805" text-anchor="middle" font-size="34" font-weight="900" fill="#ffffff">${escapeXml(data.team.toUpperCase())}</text>
  <text x="775" y="850" text-anchor="middle" font-size="20" font-weight="700" fill="#64748b">TEAM LOGO</text>

  <rect x="625" y="1030" width="320" height="150" rx="22" fill="#0b1220" stroke="#25334a" stroke-width="3"/>
  <text x="785" y="1082" text-anchor="middle" font-size="23" font-weight="800" fill="#9aa8bd">SCRIM PTS</text>
  <text x="785" y="1150" text-anchor="middle" font-size="54" font-weight="900" fill="#ffffff">${escapeXml(formatScrimPoints(data))}</text>

  <text x="540" y="1305" text-anchor="middle" font-size="22" font-weight="700" fill="#536179">MLE TM ELIGIBILITY CARD</text>
</svg>`;
}
