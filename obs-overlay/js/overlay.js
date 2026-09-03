(() => {
  const teams = window.MLETM_TEAMS;
  const divisionColors = window.MLETM_DIVISIONS;
  const initialState = window.MLETM_cloneState(window.MLETM_DEMO_STATE);
  const defaultLayout = window.MLETM_cloneState(initialState.layout || {});
  const layoutStorageKey = 'mletm-prod-overlay-layout-v1';
  let state = window.MLETM_cloneState(initialState);
  let layoutEdit = false;

  const $ = (id) => document.getElementById(id);
  const root = $('overlay');

  const cameraSvg = `
    <svg class="camera-icon" viewBox="0 0 24 24" aria-label="Spectated player">
      <path d="M3 7.5A2.5 2.5 0 0 1 5.5 5h8A2.5 2.5 0 0 1 16 7.5v1.2l4-2.1A1 1 0 0 1 21.5 7.5v9a1 1 0 0 1-1.5.9L16 15.3v1.2a2.5 2.5 0 0 1-2.5 2.5h-8A2.5 2.5 0 0 1 3 16.5v-9Z"/>
    </svg>`;

  const sidePaint = Object.freeze({
    A: { primary: '#066fe8', secondary: '#62b4ff', accent: '#a7d7ff' },
    B: { primary: '#d92b34', secondary: '#ff747c', accent: '#ffb0b5' },
  });

  const widgetElements = Object.freeze({
    banner: 'match-banner',
    records: 'records',
    ranking: 'ranking',
  });

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
    if (state.colorMode === 'redBlue') {
      if (teamKey === state.teamA.key) return sidePaint.A;
      if (teamKey === state.teamB.key) return sidePaint.B;
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
    const paintA = displayPaint(state.teamA.key);
    const paintB = displayPaint(state.teamB.key);

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
          <span class="rank-time"></span>
          <span class="rank-stripes" aria-hidden="true"></span>`;
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

  function ensureLayout() {
    if (!state.layout) state.layout = window.MLETM_cloneState(defaultLayout);
    Object.keys(widgetElements).forEach((key) => {
      if (!state.layout[key]) state.layout[key] = window.MLETM_cloneState(defaultLayout[key]);
    });
  }

  function renderLayout() {
    ensureLayout();
    root.classList.toggle('layout-edit', layoutEdit);
    Object.entries(widgetElements).forEach(([key, id]) => {
      const el = $(id);
      const position = state.layout[key];
      if (!el || !position) return;
      el.style.left = `${position.x}px`;
      el.style.top = `${position.y}px`;
    });
  }

  function loadSavedLayout() {
    try {
      const saved = JSON.parse(localStorage.getItem(layoutStorageKey) || 'null');
      if (!saved || typeof saved !== 'object') return;
      ensureLayout();
      Object.keys(widgetElements).forEach((key) => {
        if (!saved[key]) return;
        const x = Number(saved[key].x);
        const y = Number(saved[key].y);
        if (Number.isFinite(x) && Number.isFinite(y)) state.layout[key] = { x, y };
      });
    } catch (_) {}
  }

  function saveLayout() {
    try {
      localStorage.setItem(layoutStorageKey, JSON.stringify(state.layout));
    } catch (_) {}
  }

  function emitStateChanged() {
    window.dispatchEvent(new CustomEvent('mletm-state-changed', { detail: window.MLETM_cloneState(state) }));
  }

  function render() {
    renderBanner();
    renderRanking();
    renderRecords();
    renderVisibility();
    renderLayout();
  }

  function clamp(value, min, max) { return Math.max(min, Math.min(max, value)); }

  function cycleTeam(currentKey, excludedKey) {
    const keys = Object.keys(teams);
    let next = (keys.indexOf(currentKey) + 1) % keys.length;
    if (keys[next] === excludedKey) next = (next + 1) % keys.length;
    return keys[next];
  }

  function replaceRankingTeam(oldKey, newKey) {
    state.ranking.forEach((player) => {
      if (player.team === oldKey) player.team = newKey;
    });
  }

  function dispatch(action, payload = {}) {
    switch (action) {
      case 'RESET':
        state = window.MLETM_cloneState(initialState);
        layoutEdit = false;
        saveLayout();
        break;
      case 'SET_LAYOUT_EDIT':
        layoutEdit = Boolean(payload.enabled);
        renderLayout();
        return true;
      case 'RESET_LAYOUT':
        state.layout = window.MLETM_cloneState(defaultLayout);
        saveLayout();
        break;
      case 'SET_WIDGET_POSITION': {
        const key = String(payload.widget || '');
        if (!(key in widgetElements)) return false;
        ensureLayout();
        state.layout[key] = { x: Number(payload.x) || 0, y: Number(payload.y) || 0 };
        saveLayout();
        break;
      }
      case 'TOGGLE_COLOR_MODE': state.colorMode = state.colorMode === 'team' ? 'redBlue' : 'team'; break;
      case 'SET_COLOR_MODE': state.colorMode = payload.mode === 'redBlue' ? 'redBlue' : 'team'; break;
      case 'TOGGLE_WIDGET': if (payload.widget in state.visibility) state.visibility[payload.widget] = !state.visibility[payload.widget]; break;
      case 'SET_MATCH_LABEL': state.matchLabel = String(payload.value ?? '').slice(0, 40); break;
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
      case 'NEXT_TEAM_A': {
        const oldKey = state.teamA.key;
        const newKey = cycleTeam(oldKey, state.teamB.key);
        state.teamA.key = newKey;
        replaceRankingTeam(oldKey, newKey);
        break;
      }
      case 'NEXT_TEAM_B': {
        const oldKey = state.teamB.key;
        const newKey = cycleTeam(oldKey, state.teamA.key);
        state.teamB.key = newKey;
        replaceRankingTeam(oldKey, newKey);
        break;
      }
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
      default: return false;
    }
    render();
    emitStateChanged();
    return true;
  }

  function setupDragging() {
    root.addEventListener('pointerdown', (event) => {
      if (!layoutEdit || event.button !== 0) return;
      const widget = event.target.closest('.widget');
      if (!widget) return;

      const key = Object.keys(widgetElements).find((candidate) => widgetElements[candidate] === widget.id);
      if (!key) return;

      ensureLayout();
      const origin = { ...state.layout[key] };
      const startX = event.clientX;
      const startY = event.clientY;
      event.preventDefault();

      const move = (moveEvent) => {
        const maxX = 1920 - widget.offsetWidth;
        const maxY = 1080 - widget.offsetHeight;
        state.layout[key].x = Math.round(clamp(origin.x + moveEvent.clientX - startX, 0, Math.max(0, maxX)));
        state.layout[key].y = Math.round(clamp(origin.y + moveEvent.clientY - startY, 0, Math.max(0, maxY)));
        renderLayout();
      };

      const finish = () => {
        window.removeEventListener('pointermove', move);
        window.removeEventListener('pointerup', finish);
        window.removeEventListener('pointercancel', finish);
        saveLayout();
        emitStateChanged();
      };

      window.addEventListener('pointermove', move);
      window.addEventListener('pointerup', finish, { once: true });
      window.addEventListener('pointercancel', finish, { once: true });
    });
  }

  window.MLETMOverlay = {
    dispatch,
    getState: () => window.MLETM_cloneState(state),
    setState(next) {
      state = window.MLETM_cloneState(next);
      ensureLayout();
      render();
    },
  };

  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || data.type !== 'mletm-action') return;
    dispatch(data.action, data.payload || {});
  });

  loadSavedLayout();
  setupDragging();
  render();
})();
