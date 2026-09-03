window.MLETM_TEAMS = Object.freeze({
  DODGERS:    { name: 'DODGERS',    tag: 'DOD',  primary: '#041e42', secondary: '#e7e9ea', accent: '#666666', logo: '../prod-plugin/assets/teams/Dodgers.png',    wordmark: '' },
  HIVE:       { name: 'HIVE',       tag: 'HIVE', primary: '#ffa000', secondary: '#111111', accent: '#ff5959', logo: '../prod-plugin/assets/teams/Hive.png',       wordmark: '' },
  HURRICANES: { name: 'HURRICANES', tag: 'HUR',  primary: '#005030', secondary: '#f47321', accent: '#006600', logo: '../prod-plugin/assets/teams/Hurricanes.png', wordmark: '' },
  JETS:       { name: 'JETS',       tag: 'JETS', primary: '#0a2b58', secondary: '#c7102e', accent: '#ff002a', logo: '../prod-plugin/assets/teams/Jets.png',       wordmark: '' },
  FLAMES:     { name: 'FLAMES',     tag: 'FLUM', primary: '#c92a06', secondary: '#f6c432', accent: '#b22c00', logo: '../prod-plugin/assets/teams/Flames.png',     wordmark: '' },
  SABRES:     { name: 'SABRES',     tag: 'SAB',  primary: '#f36a22', secondary: '#111111', accent: '#ff8259', logo: '../prod-plugin/assets/teams/Sabres.png',     wordmark: '' },
  SPECTRE:    { name: 'SPECTRE',    tag: 'SPE',  primary: '#58427c', secondary: '#4dcf74', accent: '#00ff66', logo: '../prod-plugin/assets/teams/Spectre.png',    wordmark: '' },
  WIZARDS:    { name: 'WIZARDS',    tag: 'WIZ',  primary: '#0066b2', secondary: '#fdb927', accent: '#0061ff', logo: '../prod-plugin/assets/teams/Wizards.png',    wordmark: '' },
});

window.MLETM_DIVISIONS = Object.freeze({
  AL: '#0085fa',
  CL: '#7e55ce',
  ML: '#d10057',
});

window.MLETM_DEMO_STATE = {
  colorMode: 'team', // team | redBlue
  visibility: { banner: true, ranking: true, records: true },
  layout: {
    banner: { x: 360, y: 28 },
    records: { x: 34, y: 202 },
    ranking: { x: 34, y: 296 },
  },
  division: 'CL',
  matchLabel: 'M7',
  mapName: 'BATTERY',
  round: 3,
  teamA: { key: 'FLAMES', mapScore: 1, roundWins: 2 },
  teamB: { key: 'HURRICANES', mapScore: 0, roundWins: 1 },
  records: { world: '0:41.686', division: '0:43.247' },
  ranking: [
    { id: 'p1', name: 'PlayerOne',   team: 'FLAMES',     timeText: '0:42.018', respawn: false, spectated: false },
    { id: 'p2', name: 'PlayerTwo',   team: 'HURRICANES', timeText: '+0.147',   respawn: false, spectated: true  },
    { id: 'p3', name: 'PlayerThree', team: 'FLAMES',     timeText: '+0.338',   respawn: false, spectated: false },
    { id: 'p4', name: 'PlayerFour',  team: 'HURRICANES', timeText: '+0.511',   respawn: true,  spectated: false },
    { id: 'p5', name: 'PlayerFive',  team: 'FLAMES',     timeText: '+0.822',   respawn: false, spectated: false },
    { id: 'p6', name: 'PlayerSix',   team: 'HURRICANES', timeText: '+1.096',   respawn: false, spectated: false },
  ],
};

window.MLETM_cloneState = function cloneState(value) {
  return JSON.parse(JSON.stringify(value));
};
