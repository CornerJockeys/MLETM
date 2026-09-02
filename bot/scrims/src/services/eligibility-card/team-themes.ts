export interface EligibilityCardTeamTheme {
  key: string;
  name: string;
  primary: string;
  secondary: string;
  accent: string;
  logoFile: string;
}

const THEMES: Record<string, EligibilityCardTeamTheme> = {
  dodgers: { key: 'dodgers', name: 'Dodgers', primary: '#041e42', secondary: '#e7e9ea', accent: '#000666', logoFile: 'Dodgers.png' },
  hive: { key: 'hive', name: 'Hive', primary: '#ffa000', secondary: '#111111', accent: '#ff5959', logoFile: 'Hive.png' },
  hurricanes: { key: 'hurricanes', name: 'Hurricanes', primary: '#005030', secondary: '#f47321', accent: '#006600', logoFile: 'Hurricanes.png' },
  jets: { key: 'jets', name: 'Jets', primary: '#0a2b58', secondary: '#c7102e', accent: '#ff002a', logoFile: 'Jets.png' },
  flames: { key: 'flames', name: 'Flames', primary: '#c92a06', secondary: '#f6c432', accent: '#b22c00', logoFile: 'Flames.png' },
  sabres: { key: 'sabres', name: 'Sabres', primary: '#f36a22', secondary: '#111111', accent: '#ff8259', logoFile: 'Sabres.png' },
  spectre: { key: 'spectre', name: 'Spectre', primary: '#58427c', secondary: '#4dcf74', accent: '#00ff66', logoFile: 'Spectre.png' },
  wizards: { key: 'wizards', name: 'Wizards', primary: '#0066b2', secondary: '#fdb927', accent: '#0061ff', logoFile: 'Wizards.png' },
};

const FALLBACK: EligibilityCardTeamTheme = {
  key: 'unknown',
  name: 'Unknown',
  primary: '#30343a',
  secondary: '#f2f2f2',
  accent: '#666666',
  logoFile: 'Unknown.png',
};

export function getEligibilityCardTeamTheme(teamKey: string): EligibilityCardTeamTheme {
  return THEMES[teamKey.toLowerCase()] ?? FALLBACK;
}

export const ELIGIBILITY_CARD_TEAM_THEMES = THEMES;
