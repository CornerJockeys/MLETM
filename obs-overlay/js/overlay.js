(() => {
  const teams = window.MLETM_TEAMS;
  const divisionColors = window.MLETM_DIVISIONS;
  const initialState = window.MLETM_cloneState(window.MLETM_DEMO_STATE);
  let state = window.MLETM_cloneState(initialState);

  const $ = (id) => document.getElementById(id);
  const root = $('overlay');

  const cameraSvg = `
    <svg class="camera-icon" viewBox="0 0 24 24" aria-label="Spectated player">
      <path d="M3 7.5A2.5 2.5 0 0 1 5.5 5h8A2.5 2.5 0 0 1 16 7.5v1.2l4-2.1A1 1 0 0 1 21.5 7.5v9a1 1 0 0 1-1.5.9L16 15.3v1.2a2.5 2.5 0 0 1-2.5 2.5h-8A2.5 2.5 0 0 1 3 16.5v-9Z"/>
    </svg>`;

  function hexToRgb(hex) {
    const clean = hex.replace('#', '');
    const value = parseInt(clean, 16);
    return { r: (value >> 16) & 255, g: (value >> 8) & 255, b: value & 255 };
  }

  function readableText(hex) {
    const { r, g, b } = hexToRgb(hex);
    const luma = (r * .299 + g * .587 + b * .114) / 255;
    return luma >= .50 ? '#11151a' : '#f5f7fa';
  }

  function rgba(hex, alpha) {
    const { r, g, b } = hexToRgb(hex);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }

  function currentTeams() {
    return { a: teams[state.teamA.key], b: teams[state.teamB.key] };
  }

  function displayPaint(teamKey) {
    const { a, b } = currentTeams();
    if (state.colorMode === 'redBlue') {
      if (teamKey === a.name) return { primary: '#066fe8', secondary: '#62b4ff', accent: '#a7d7ff' };
      if (teamKey === b.name) return { primary: '#d92b34', secondary: '#ff747c', accent: '#ffb0b5' };
    }
    const team = teams[teamKey] || { primary: '#30343a', secondary: '#dfe4ea', accent: '#87909b' };
    return { primary: team.primary, secondary: team.secondary, accent: team.accent };
  }

  function renderImage(img, src, name) {
    img.classList.remove('logo-missing', 'active');
    img.alt = name;
    if (!src) {
      img.removeAttribute('src');
      img.classList.add('logo-missing');
      return;
    }
    img.onerror = () => img.classList.add('logo-missing');
    img.onload = () => img.classList.remove('logo-missing');
    img.src = src;
  }

  function renderWordmark(img, src, name) {
    img.classList.remove('active');
    if (!src) {
      img.removeAttribute('src');
      return;
    }
    img.alt = `${name} wordmark`;
    img.onerror = () => img.classList.remove('active');
    img.onload = () => img.classList.add('active');
    img.src = src;
  }

  function renderPips(container, wins) {
    container.replaceChildren();
    for (let i = 0; i < 5; i += 1) {
      const pip = document.createElement('span');
      pip.className = `round-pip${i < wins ? ' won' : ''}`;
      container.appendChild(pip);
    }
  }

  function renderBanner() {
    const { a, b } = currentTeams();
    const paintA = displayPaint(a.name);
    const paintB = displayPaint(b.name);

    root.style.setProperty('--team-a-primary', paintA.primary);
    root.style.setProperty('--team-a-secondary', paintA.secondary);
    root.style.setProperty('--team-b-primary', paintB.primary);
    root.style.setProperty('--team-b-secondary', paintB.secondary);
    root.style.setProperty('--division', divisionColors[state.division] || '#1fbf5c');

    $('team-a-name').textContent = a.name;
    $('team-b-name').textContent = b.name;
    $('team-a-name').style.color = readableText(paintA.primary);
    $('team-b-name').style.color = readableText(paintB.primary);
    renderImage($('team-a-logo'), a.logo, a.name);
    renderImage($('team-b-logo'), b.logo, b.name);
    renderWordmark($('team-a-wordmark'), a.wordmark, a.name);
    renderWordmark($('team-b-wordmark'), b.wordmark, b.name);

    $('team-a-score').textContent = state.teamA.mapScore;
    $('team-b-score').textContent = state.teamB.mapScore;
    renderPips($('team-a-rounds'), state.teamA.roundWins);
    renderPips($('team-b-rounds'), state.teamB.roundWins);

    $('division').textContent = state.division;
    $('match-label').textContent = state.matchLabel;
    $('map-name').textContent = state.mapName;
  }

  function renderRanking() {
    $('ranking-round').textContent = `ROUND ${state.round}`;
    const container = $('ranking-rows');
    const existing = new Map([...container.children].map((node) => [node.dataset.id, node]));

    state.ranking.forEach((player, index) => {
      const team = teams[player.team] || { tag: '', primary: '#30343a', secondary: '#dfe4ea', accent: '#87909b' };
      const paint = displayPaint(player.team);
      let row = existing.get(player.id);
      if (!row) {
        row = document.createElement('div');
        row.className = 'rank-row';
        row.dataset.id = player.id;
        row.innerHTML = `
          <span class="rank-position"></span>
          <span class="rank-player"><span class="rank-tag"></span><span class="rank-name"></span></span>
          <span class="rank-status"></span>
          <span class="rank-time"></span>`;
        container.appendChild(row);
      }
      existing.delete(player.id);

      row.style.setProperty('--rank', index);
      row.style.setProperty('--row-primary', paint.primary);
      row.style.setProperty('--row-secondary', paint.secondary);
      row.style.setProperty('--row-accent', paint.accent);
      row.style.background = rgba(paint.primary, .90);
      row.style.color = readableText(paint.primary);
      row.classList.toggle('spectated', Boolean(player.spectated));

      row.querySelector('.rank-position').textContent = index + 1;
      row.querySelector('.rank-tag').textContent = team.tag ? `[${team.tag}]` : '';
      row.querySelector('.rank-name').textContent = player.name;
      row.querySelector('.rank-time').textContent = player.timeText;

      const status = row.querySelector('.rank-status');
      if (player.spectated) status.innerHTML = cameraSvg;
      else if (player.respawn) status.innerHTML = '<span class="respawn-indicator">R</span>';
      else status.replaceChildren();
    });

    existing.forEach((node) => node.remove());
  }

  function renderRecords() {
    $('world-record').textContent = state.records.world;
    $('division-record').textContent = state.records.division;
    $('division-record-label').textContent = `${state.division} RECORD`;
  }

  function renderVisibility() {
    root.classList.toggle('hide-banner', !state.visibility.banner);
    root.classList.toggle('hide-ranking', !state.visibility.ranking);
    root.classList.toggle('hide-records', !state.visibility.records);
  }

  function render() {
    renderBanner();
    renderRanking();
    renderRecords();
    renderVisibility();
  }

  function clamp(value, min, max) { return Math.max(min, Math.min(max, value)); }

  function cycleTeam(currentKey, excludedKey) {
    const keys = Object.keys(teams);
    let next = (keys.indexOf(currentKey) + 1) % keys.length;
    if (keys[next] === excludedKey) next = (next + 1) % keys.length;
    return keys[next];
  }

  function dispatch(action, payload = {}) {
    switch (action) {
      case 'RESET': state = window.MLETM_cloneState(initialState); break;
      case 'TOGGLE_COLOR_MODE': state.colorMode = state.colorMode === 'team' ? 'redBlue' : 'team'; break;
      case 'SET_COLOR_MODE': state.colorMode = payload.mode === 'redBlue' ? 'redBlue' : 'team'; break;
      case 'TOGGLE_WIDGET': if (payload.widget in state.visibility) state.visibility[payload.widget] = !state.visibility[payload.widget]; break;
      case 'SCORE_DELTA': {
        const side = payload.side === 'B' ? state.teamB : state.teamA;
        side.mapScore = clamp(side.mapScore + Number(payload.delta || 0), 0, 99);
        break;
      }
      case 'ROUND_DELTA': {
        const side = payload.side === 'B' ? state.teamB : state.teamA;
        side.roundWins = clamp(side.roundWins + Number(payload.delta || 0), 0, 5);
        break;
      }
      case 'SWAP_TEAMS': [state.teamA, state.teamB] = [state.teamB, state.teamA]; break;
      case 'NEXT_TEAM_A': state.teamA.key = cycleTeam(state.teamA.key, state.teamB.key); break;
      case 'NEXT_TEAM_B': state.teamB.key = cycleTeam(state.teamB.key, state.teamA.key); break;
      case 'NEXT_SPECTATED': {
        const current = state.ranking.findIndex((p) => p.spectated);
        state.ranking.forEach((p) => { p.spectated = false; });
        state.ranking[(current + 1 + state.ranking.length) % state.ranking.length].spectated = true;
        break;
      }
      case 'TOGGLE_RESPAWN': {
        const target = state.ranking[Number(payload.index ?? 3) % state.ranking.length];
        target.respawn = !target.respawn;
        break;
      }
      case 'SHUFFLE_RANKING': {
        const first = state.ranking.shift();
        state.ranking.splice(3, 0, first);
        break;
      }
      case 'ROUND_DELTA_NUMBER': state.round = clamp(state.round + Number(payload.delta || 0), 1, 99); break;
      case 'NEXT_MAP': {
        const maps = ['BATTERY', 'MELODRAMA', 'NIRVANA', 'SKRRRT', 'WHATEVER'];
        state.mapName = maps[(maps.indexOf(state.mapName) + 1) % maps.length];
        break;
      }
      case 'MATCH_DELTA': {
        const current = Number(String(state.matchLabel).replace(/\D/g, '')) || 1;
        state.matchLabel = `M${clamp(current + Number(payload.delta || 0), 1, 99)}`;
        break;
      }
      default: return false;
    }
    render();
    window.dispatchEvent(new CustomEvent('mletm-state-changed', { detail: window.MLETM_cloneState(state) }));
    return true;
  }

  window.MLETMOverlay = {
    dispatch,
    getState: () => window.MLETM_cloneState(state),
    setState(next) { state = window.MLETM_cloneState(next); render(); },
  };

  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || data.type !== 'mletm-action') return;
    dispatch(data.action, data.payload || {});
  });

  render();
})();
