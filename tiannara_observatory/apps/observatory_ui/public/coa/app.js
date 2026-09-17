const TCC = (() => {
  const API_BASE = (() => {
    try {
      if (window.location && window.location.protocol === 'file:') {
        return 'http://localhost:4000/api/v1';
      }
      if (window.location && window.location.origin) {
        return `${window.location.origin}/api/v1`;
      }
    } catch (_) {}
    return '/api/v1';
  })();
  const REFRESH_INTERVAL = 30000;
  let currentSection = 'dashboard';
  let currentExpTab = 'running';
  let currentKnowledgeCat = 'principles';
  let currentAiRoom = 'general';
  let aiMessages = {};
  let refreshTimer = null;

  function init() {
    startClock();
    bindNavigation();
    bindBackButtons();
    bindRuntimeControls();
    bindExperimentTabs();
    bindKnowledgeCategories();
    bindAiAssistant();
    bindAiForm();
    bindAiQuickActions();
    bindOperations();
    bindPhysicalControls();
    fetchDashboard();
    refreshTimer = setInterval(refreshAll, REFRESH_INTERVAL);
  }

  function startClock() {
    const el = document.getElementById('systemTime');
    function tick() {
      const now = new Date();
      el.textContent = now.toLocaleTimeString('en-US', { hour12: false }) + ' UTC';
    }
    tick();
    setInterval(tick, 1000);
  }

  function bindNavigation() {
    document.querySelectorAll('.nav-item').forEach(item => {
      item.addEventListener('click', () => {
        const section = item.dataset.section;
        document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
        item.classList.add('active');
        showSection(section);
      });
    });
  }

  function bindBackButtons() {
    document.querySelectorAll('.btn-back').forEach(btn => {
      btn.addEventListener('click', () => {
        showSection('dashboard');
        document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
        document.querySelector('.nav-item[data-section="dashboard"]').classList.add('active');
      });
    });
  }

  function showSection(name) {
    document.querySelectorAll('.section').forEach(s => s.classList.add('hidden'));
    const target = document.getElementById('section-' + name);
    if (target) {
      target.classList.remove('hidden');
      currentSection = name;
      fetchSectionData(name);
    }
  }

  function bindRuntimeControls() {
    const btnStart = document.getElementById('btnStartAll');
    const btnStop = document.getElementById('btnStopAll');
    const btnRestart = document.getElementById('btnRestart');
    const btnSafe = document.getElementById('btnSafeMode');

    if (btnStart) btnStart.addEventListener('click', () => runtimeAction('start_all'));
    if (btnStop) btnStop.addEventListener('click', () => runtimeAction('stop_all'));
    if (btnRestart) btnRestart.addEventListener('click', () => runtimeAction('restart'));
    if (btnSafe) btnSafe.addEventListener('click', () => runtimeAction('safe_mode'));
  }

  async function runtimeAction(action) {
    try {
      await fetchJSON(`${API_BASE}/runtime/${action}`, { method: 'POST' });
      toast(`Runtime: ${action} initiated`, 'success');
      fetchRuntimeStatus();
    } catch (err) {
      toast(`Runtime action failed: ${action}`, 'error');
    }
  }

  function bindExperimentTabs() {
    document.querySelectorAll('.tab-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentExpTab = btn.dataset.tab;
        fetchExperiments();
      });
    });
  }

  function bindKnowledgeCategories() {
    document.querySelectorAll('.cat-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.cat-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentKnowledgeCat = btn.dataset.cat;
        fetchKnowledge();
      });
    });
  }

  function bindAiAssistant() {
    const toggle = document.getElementById('aiToggle');
    const assistant = document.getElementById('aiAssistant');
    if (toggle && assistant) {
      toggle.addEventListener('click', (e) => {
        e.stopPropagation();
        assistant.classList.toggle('collapsed');
      });
      assistant.querySelector('.ai-header').addEventListener('click', () => {
        assistant.classList.toggle('collapsed');
      });
    }

    document.querySelectorAll('.ai-room-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.ai-room-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentAiRoom = btn.dataset.room;
        renderAiMessages();
      });
    });
  }

  function bindAiForm() {
    const form = document.getElementById('aiForm');
    if (form) {
      form.addEventListener('submit', (e) => {
        e.preventDefault();
        sendAiMessage();
      });
    }
  }

  function bindAiQuickActions() {
    document.querySelectorAll('.ai-quick-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const input = document.getElementById('aiInput');
        if (input) {
          input.value = btn.dataset.action;
          sendAiMessage();
        }
      });
    });
  }

  async function sendAiMessage() {
    const input = document.getElementById('aiInput');
    const text = input.value.trim();
    if (!text) return;
    input.value = '';

    if (!aiMessages[currentAiRoom]) aiMessages[currentAiRoom] = [];

    aiMessages[currentAiRoom].push({ role: 'user', text, time: new Date().toISOString() });
    renderAiMessages();

    try {
      const res = await fetchJSON(`${API_BASE}/interaction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ room: currentAiRoom, message: text })
      });
      if (res && res.data) {
        aiMessages[currentAiRoom].push({
          role: 'assistant',
          text: res.data.message || res.data.response || 'Acknowledged',
          time: res.data.timestamp || new Date().toISOString()
        });
      }
    } catch (err) {
      aiMessages[currentAiRoom].push({
        role: 'system',
        text: 'Awaiting response...',
        time: new Date().toISOString()
      });
    }
    renderAiMessages();
  }

  function renderAiMessages() {
    const container = document.getElementById('aiMessages');
    if (!container) return;
    const messages = aiMessages[currentAiRoom] || [];
    if (messages.length === 0) {
      container.innerHTML = '<div class="ai-message system">Assistant ready.</div>';
      return;
    }
    container.innerHTML = '';
    messages.forEach(msg => {
      const el = document.createElement('div');
      el.className = `ai-message ${msg.role}`;
      el.textContent = msg.text;
      container.appendChild(el);
    });
    container.scrollTop = container.scrollHeight;
  }

  async function fetchDashboard() {
    try {
      const [health, status, resources] = await Promise.allSettled([
        fetchJSON(`${API_BASE}/health`),
        fetchJSON(`${API_BASE}/status`),
        fetchJSON(`${API_BASE}/resources`)
      ]);

      if (health.status === 'fulfilled' && health.value) {
        updateSystemStatus('connected', health.value.status || 'Connected');
      } else {
        updateSystemStatus('error', 'API Unreachable');
      }

      if (status.status === 'fulfilled' && status.value) {
        const d = status.value.data || status.value;
        setDashValue('dashRuntime', '● Healthy', 'healthy');
        setDashText('dashResearch', d.experiments_running ? `${d.experiments_running} Experiments Running` : 'Awaiting data...');
        setDashText('dashObservatories', d.observatories_active ? `${d.observatories_active} Active` : 'Awaiting data...');
        setDashText('dashWorlds', d.worlds || 'Awaiting data...');
        setDashText('dashCivilizations', d.civilizations || 'Awaiting data...');
        setDashText('dashAgents', d.agents ? formatNumber(d.agents) : 'Awaiting data...');
        setDashText('dashDiscoveries', d.discoveries_today ? `${d.discoveries_today} today` : 'Awaiting data...');
      }

      if (resources.status === 'fulfilled' && resources.value) {
        const r = resources.value.data || resources.value;
        updateResourceBar('Cpu', r.cpu, '%');
        updateResourceBar('Ram', r.ram, ' GB', 32);
        updateResourceBar('Gpu', r.gpu, '%');
        updateResourceBar('Storage', r.storage, ' TB', 10);
      }

      fetchRuntimeStatus();
    } catch (err) {
      updateSystemStatus('error', 'Connection Failed');
    }
  }

  function setDashText(id, text) {
    const el = document.getElementById(id);
    if (el) el.textContent = text;
  }

  function setDashValue(id, text, dotClass) {
    const el = document.getElementById(id);
    if (el) el.innerHTML = `<span class="status-dot ${dotClass}"></span> <span>${text.replace('● ', '')}</span>`;
  }

  function updateResourceBar(name, value, suffix, max) {
    const bar = document.getElementById('bar' + name);
    const val = document.getElementById('val' + name);
    if (!bar || !val) return;
    if (value === undefined || value === null) {
      val.textContent = '--' + suffix.trim();
      return;
    }
    const numVal = typeof value === 'number' ? value : parseFloat(value);
    if (isNaN(numVal)) {
      val.textContent = '--' + suffix.trim();
      return;
    }
    const pct = max ? (numVal / max) * 100 : numVal;
    bar.style.width = Math.min(pct, 100) + '%';
    val.textContent = (suffix === ' GB' || suffix === ' TB') ? `${numVal}${suffix}` : `${Math.round(numVal)}${suffix}`;
  }

  async function fetchRuntimeStatus() {
    try {
      const res = await fetchJSON(`${API_BASE}/runtime/status`);
      const services = res.data || res.services || {};
      const grid = document.getElementById('servicesGrid');
      if (!grid) return;
      const serviceNames = ['BEAM', 'PostgreSQL', 'Redis', 'NATS', 'Phoenix', 'React', 'Python Workers', 'Rust Kernels', 'Vector DB', 'Telemetry'];

      grid.innerHTML = '';
      serviceNames.forEach(name => {
        const key = name.toLowerCase().replace(/\s+/g, '_');
        const status = services[key] || services[name] || 'unknown';
        const card = document.createElement('div');
        let statusClass = 'loading';
        let statusText = 'Awaiting data...';

        if (status === 'running' || status === 'ok' || status === 'active') {
          statusClass = 'running';
          statusText = 'Running';
        } else if (status === 'stopped' || status === 'down') {
          statusClass = 'stopped';
          statusText = 'Stopped';
        } else if (status === 'degraded') {
          statusClass = 'degraded';
          statusText = 'Degraded';
        }

        card.className = `service-card ${statusClass}`;
        card.innerHTML = `<span class="service-name">${escapeHtml(name)}</span><span class="service-status">${statusText}</span>`;
        grid.appendChild(card);
      });

      fetchBootStatus();
    } catch (err) {
      const grid = document.getElementById('servicesGrid');
      if (grid) {
        grid.querySelectorAll('.service-card').forEach(card => {
          card.className = 'service-card loading';
          card.querySelector('.service-status').textContent = 'Error';
        });
      }
    }
  }

  async function fetchBootStatus() {
    try {
      const res = await fetchJSON(`${API_BASE}/runtime/boot`);
      const steps = res.data || res.steps || [];
      const bootNames = ['Environment', 'Infrastructure', 'Runtime', 'MSCL', 'OLEF', 'GRCC', 'CTL', 'OCM', 'CIS', 'AEO', 'Discovery', 'Frontend'];
      const container = document.getElementById('bootSteps');
      if (!container) return;

      container.innerHTML = '';
      bootNames.forEach((name, i) => {
        const step = steps[i] || {};
        const status = step.status || 'pending';
        const div = document.createElement('div');
        let check = '⏳';
        let cls = '';

        if (status === 'completed' || status === 'ok' || status === true) {
          check = '✓';
          cls = 'completed';
        } else if (status === 'failed' || status === 'error' || status === false) {
          check = '✗';
          cls = 'failed';
        }

        div.className = `boot-step ${cls}`;
        div.innerHTML = `<span class="boot-check">${check}</span><span class="boot-label">${escapeHtml(name)}</span>`;
        container.appendChild(div);
      });
    } catch (err) {
    }
  }

  async function fetchSectionData(name) {
    const endpoint = name;
    const bodyEl = document.getElementById(name + 'Body') || document.getElementById(name + 'List') || document.getElementById(name + 'Tree');

    if (name === 'runtime') {
      fetchRuntimeStatus();
      return;
    }

    if (name === 'experiments') {
      fetchExperiments();
      return;
    }

    if (name === 'knowledge') {
      fetchKnowledge();
      return;
    }

    if (name === 'dashboard') {
      fetchDashboard();
      return;
    }

    if (!bodyEl) return;
    bodyEl.innerHTML = '<div class="loading-state"><div class="spinner"></div><span>Awaiting data...</span></div>';

    try {
      const res = await fetchJSON(`${API_BASE}/${endpoint}`);
      renderSectionData(name, bodyEl, res);
    } catch (err) {
      bodyEl.innerHTML = '<div class="loading-state"><span>Unable to connect. Awaiting data...</span></div>';
    }
  }

  function renderSectionData(name, container, data) {
    const items = data.data || data.items || data;

    if (Array.isArray(items) && items.length === 0) {
      container.innerHTML = '<div class="loading-state"><span>No data available</span></div>';
      return;
    }

    if (Array.isArray(items)) {
      container.innerHTML = '';
      items.forEach(item => {
        const card = document.createElement('div');
        card.className = 'experiment-card';
        const title = item.name || item.title || item.id || 'Entry';
        const detail = item.description || item.status || item.detail || '';
        card.innerHTML = `<div class="experiment-title">${escapeHtml(String(title))}</div><div class="experiment-meta">${escapeHtml(String(detail))}</div>`;
        container.appendChild(card);
      });
    } else if (typeof items === 'object' && items !== null) {
      container.innerHTML = '';
      Object.entries(items).forEach(([key, value]) => {
        const card = document.createElement('div');
        card.className = 'experiment-card';
        card.innerHTML = `<div class="experiment-title">${escapeHtml(key)}</div><div class="experiment-meta">${escapeHtml(String(typeof value === 'object' ? JSON.stringify(value) : value))}</div>`;
        container.appendChild(card);
      });
    } else {
      container.innerHTML = `<div class="loading-state"><span>${escapeHtml(String(items))}</span></div>`;
    }
  }

  async function fetchExperiments() {
    const container = document.getElementById('experimentList');
    if (!container) return;
    container.innerHTML = '<div class="loading-state"><div class="spinner"></div><span>Awaiting data...</span></div>';

    try {
      const res = await fetchJSON(`${API_BASE}/experiments?status=${currentExpTab}`);
      const items = res.data || res.experiments || [];

      if (!Array.isArray(items) || items.length === 0) {
        container.innerHTML = '<div class="loading-state"><span>No experiments in this state</span></div>';
        return;
      }

      container.innerHTML = '';
      items.forEach(item => {
        const card = document.createElement('div');
        card.className = 'experiment-card';
        const title = item.objective || item.name || item.title || 'Experiment';
        const hypothesis = item.hypothesis || item.hypotheses || '';
        const runtime = item.runtime || item.duration || '';
        const discoveries = item.discoveries || 0;

        card.innerHTML = `
          <div class="experiment-title">${escapeHtml(String(title))}</div>
          <div class="experiment-meta">
            ${hypothesis ? `<span>H: ${escapeHtml(String(hypothesis))}</span>` : ''}
            ${runtime ? `<span>Runtime: ${escapeHtml(String(runtime))}</span>` : ''}
            <span>Discoveries: ${discoveries}</span>
          </div>
        `;
        container.appendChild(card);
      });
    } catch (err) {
      container.innerHTML = '<div class="loading-state"><span>Unable to load experiments</span></div>';
    }
  }

  async function fetchKnowledge() {
    const container = document.getElementById('knowledgeTree');
    if (!container) return;
    container.innerHTML = '<div class="loading-state"><div class="spinner"></div><span>Awaiting data...</span></div>';

    try {
      const res = await fetchJSON(`${API_BASE}/knowledge?category=${currentKnowledgeCat}`);
      const items = res.data || res.items || [];

      if (!Array.isArray(items) || items.length === 0) {
        container.innerHTML = '<div class="loading-state"><span>No knowledge entries in this category</span></div>';
        return;
      }

      container.innerHTML = '';
      items.forEach(item => {
        const node = document.createElement('div');
        node.className = 'knowledge-node';
        const label = item.name || item.title || item.id || 'Entry';
        node.innerHTML = `<span class="knowledge-node-label">${escapeHtml(String(label))}</span>`;
        container.appendChild(node);
      });
    } catch (err) {
      container.innerHTML = '<div class="loading-state"><span>Unable to load knowledge graph</span></div>';
    }
  }

  function updateSystemStatus(state, text) {
    const indicator = document.querySelector('.status-indicator');
    const textEl = document.getElementById('statusText');
    if (!indicator || !textEl) return;
    indicator.classList.remove('connected', 'error');
    if (state === 'connected') indicator.classList.add('connected');
    else if (state === 'error') indicator.classList.add('error');
    textEl.textContent = text;
  }

  function refreshAll() {
    if (currentSection === 'dashboard') {
      fetchDashboard();
    } else {
      fetchSectionData(currentSection);
    }
  }

  function toast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    if (!container) return;
    const el = document.createElement('div');
    el.className = `toast toast-${type}`;
    el.innerHTML = `<span>${escapeHtml(message)}</span><button class="toast-dismiss">&times;</button>`;
    el.querySelector('.toast-dismiss').addEventListener('click', () => el.remove());
    container.appendChild(el);
    setTimeout(() => { if (el.parentNode) el.remove(); }, 5000);
  }

  async function fetchJSON(url, options = {}, retries = 2) {
    for (let attempt = 1; attempt <= retries + 1; attempt++) {
      try {
        const res = await fetch(url, {
          headers: { 'Accept': 'application/json', ...options.headers },
          ...options
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return await res.json();
      } catch (err) {
        if (attempt <= retries) await new Promise(r => setTimeout(r, 1000 * attempt));
        else throw err;
      }
    }
  }

  function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  function formatNumber(num) {
    if (typeof num !== 'number') return String(num);
    return num.toLocaleString();
  }

  let soakPollTimer = null;
  let lastAtlasData = null;

  const CHALLENGE_NAMES = [
    'causal_lineage',
    'cross_domain_synthesis',
    'autonomous_experiment',
    'self_improvement',
    'civilization_coordination',
    'anomaly_detection',
    'paradoxical_policy',
    'impossible_ui',
    'nested_negation',
    'tool_use',
    'temporal_causal_reasoning',
    'adversarial_scientific_review',
    'multi_objective_optimization'
  ];

  function bindOperations() {
    const btnSoakStart = document.getElementById('btnSoakStart');
    const btnSoakStop = document.getElementById('btnSoakStop');
    const btnSoakStatus = document.getElementById('btnSoakStatus');
    const btnAlphaLaunch = document.getElementById('btnAlphaLaunch');
    const btnAlphaAbort = document.getElementById('btnAlphaAbort');
    const btnAtlasGenerate = document.getElementById('btnAtlasGenerate');
    const btnAtlasExport = document.getElementById('btnAtlasExport');
    const btnAtlasPrint = document.getElementById('btnAtlasPrint');
    const btnRunChallenges = document.getElementById('btnRunChallenges');
    const btnCampaignTrigger = document.getElementById('btnTriggerCampaign');

    if (btnSoakStart) btnSoakStart.addEventListener('click', startSoakTest);
    if (btnSoakStop) btnSoakStop.addEventListener('click', stopSoakTest);
    if (btnSoakStatus) btnSoakStatus.addEventListener('click', fetchSoakStatus);
    if (btnAlphaLaunch) btnAlphaLaunch.addEventListener('click', launchAlpha);
    if (btnAlphaAbort) btnAlphaAbort.addEventListener('click', abortAlpha);
    if (btnAtlasGenerate) btnAtlasGenerate.addEventListener('click', generateAtlas);
    if (btnAtlasExport) btnAtlasExport.addEventListener('click', exportAtlas);
    if (btnAtlasPrint) btnAtlasPrint.addEventListener('click', printAtlas);
    if (btnRunChallenges) btnRunChallenges.addEventListener('click', runAllChallenges);
    if (btnCampaignTrigger) btnCampaignTrigger.addEventListener('click', triggerCampaign);

    const btnSeed = document.getElementById('btnSeed');
    if (btnSeed) btnSeed.addEventListener('click', seedPipeline);

    fetchLoop();
    fetchASC();
    fetchPipeline();
    setInterval(fetchLoop, 20000);
    setInterval(fetchASC, 30000);
    setInterval(fetchPipeline, 15000);
  }

  const PIPE_STAGES = [
    'observation', 'unknown_detection', 'hypothesis', 'experiment_schedule',
    'experiment_execute', 'evidence', 'knowledge_integration', 'graph_growth',
    'discovery_promotion'
  ];

  const PIPE_MARKS = {
    growing: '🟢', present: '🔵', flat: '🔵', regressed: '🟡',
    uninstrumented: '⚪', error: '🔴'
  };

  async function seedPipeline() {
    if (!confirm('Inject 4 provenance-tagged seed entities (observation contradiction, stale theory, low-confidence reading) into the world model?')) return;
    setOpsFeedback('pipeFeedback', 'Seeding epistemic pressure...', 'info');
    try {
      await fetchJSON('/api/v1/discovery/seed', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
      });
      setOpsFeedback('pipeFeedback', 'Seeded. Watch unknown_detection / graph_growth for movement.', 'success');
      fetchPipeline();
    } catch (err) {
      setOpsFeedback('pipeFeedback', 'Seed failed: ' + err.message, 'error');
    }
  }

  async function fetchPipeline() {
    try {
      const res = await fetchJSON('/api/v1/discovery/pipeline');
      const d = res.data || res;
      renderPipeline(d.pipeline);
    } catch (err) {
      // silent — the pipeline panel is best-effort
    }
  }

  function renderPipeline(p) {
    const body = document.getElementById('pipeBody');
    const panel = document.getElementById('pipePanel');
    const stallBadge = document.getElementById('pipeStallBadge');
    if (!body || !p || !p.stages) return;
    panel.style.display = '';
    body.innerHTML = PIPE_STAGES.map(stage => {
      const s = p.stages[stage] || {};
      const status = s.status || 'uninstrumented';
      const mark = PIPE_MARKS[status] || '⚪';
      const isStall = p.first_stall && p.first_stall.stage === stage;
      let value = (typeof s.value === 'number') ? s.value : '—';
      if (stage === 'knowledge_integration' && typeof s.value === 'number' &&
          typeof p.seeded_inputs === 'number') {
        value = s.value + ' earned (of ' + (s.value + p.seeded_inputs) + ' observable)';
      }
      return `<tr class="${isStall ? 'stall' : ''}">
        <td class="pipe-stage">${stage}${isStall ? ' <span class="pipe-stall-tag">◀ STALL</span>' : ''}</td>
        <td class="pipe-status pipe-${status}">${mark} ${status}</td>
        <td class="pipe-value">${value}</td>
      </tr>`;
    }).join('');
    let seededEl = document.getElementById('pipeSeeded');
    if (!seededEl) {
      seededEl = document.createElement('div');
      seededEl.id = 'pipeSeeded';
      seededEl.className = 'pipe-seeded';
      panel.appendChild(seededEl);
    }
    seededEl.textContent = (typeof p.seeded_inputs === 'number')
      ? `seeded_inputs (epistemic-seed pipeline inputs): ${p.seeded_inputs}`
      : 'seeded_inputs: N/A';
    if (stallBadge) {
      if (p.first_stall) {
        stallBadge.style.display = '';
        stallBadge.textContent = 'FIRST STALL: ' + p.first_stall.stage + ' (' + p.first_stall.status + ')';
      } else {
        stallBadge.style.display = 'none';
      }
    }
  }

  function setOpsFeedback(id, msg, type) {
    const el = document.getElementById(id);
    if (!el) return;
    el.textContent = msg;
    el.className = 'ops-feedback ' + (type || '');
  }

  function setOpsSpinner(id, show) {
    const el = document.getElementById(id);
    if (el) el.style.display = show ? '' : 'none';
  }

  function toggleEl(id, show) {
    const el = document.getElementById(id);
    if (el) el.style.display = show ? '' : 'none';
  }

  async function startSoakTest() {
    setOpsSpinner('soakSpinner', true);
    setOpsFeedback('soakFeedback', 'Starting 72h soak test...', 'info');
    try {
      await fetchJSON(API_BASE.replace('/api/v1','') + '/api/crav/soak_test/start', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ duration_hours: 72 })
      });
      setOpsFeedback('soakFeedback', 'Soak test started. Polling status every 30s...', 'success');
      toggleEl('btnSoakStart', false);
      toggleEl('btnSoakStop', true);
      toggleEl('btnSoakStatus', true);
      toggleEl('soakProgress', true);
      if (soakPollTimer) clearInterval(soakPollTimer);
      fetchSoakStatus();
      soakPollTimer = setInterval(fetchSoakStatus, 30000);
    } catch (err) {
      setOpsFeedback('soakFeedback', 'Failed to start soak test: ' + err.message, 'error');
    }
    setOpsSpinner('soakSpinner', false);
  }

  async function fetchSoakStatus() {
    try {
      const res = await fetchJSON('/api/crav/soak_test/status');
      const d = res.data || res;
      const elapsed = d.elapsed_hours != null ? d.elapsed_hours.toFixed(2) : '--';
      const target = d.target_hours || 72;
      const pct = d.progress_pct != null ? Math.min(d.progress_pct, 100) : 0;

      document.getElementById('soakElapsed').textContent = elapsed + 'h / ' + target + 'h';
      document.getElementById('soakHealthChecks').textContent = d.health_checks != null ? d.health_checks : '--';
      document.getElementById('soakChallenges').textContent = d.challenges != null ? d.challenges : '--';
      document.getElementById('soakDiscoveries').textContent = d.discoveries != null ? d.discoveries : '--';
      document.getElementById('soakProgressBar').style.width = pct + '%';

      setLiveValue(document.getElementById('soakPhase'), String(d.phase || '--').toUpperCase());
      setLiveValue(document.getElementById('soakAvailability'), (d.availability_pct != null ? d.availability_pct : '--') + '%');
      setLiveValue(document.getElementById('soakPassRate'), (d.challenge_pass_rate != null ? d.challenge_pass_rate : '--') + '%');
      setLiveValue(document.getElementById('soakMemory'), (d.memory_mb != null ? d.memory_mb : '--') + ' MB');

      const mb = d.memory_mb || 0;
      const memBar = document.getElementById('soakMemoryBar');
      if (memBar) memBar.style.width = Math.min(mb / 512 * 100, 100) + '%';

      const leak = d.leak || {};
      const leakEl = document.getElementById('soakLeakBadge');
      const leakRow = document.getElementById('soakLeakRow');
      if (leakEl && leak.samples > 0) {
        const detected = !!leak.detected;
        leakEl.textContent = 'LEAK ' + (detected ? 'DETECTED' : 'OK') + '  slope ' + (leak.slope_mb_per_h || 0) + ' MB/h  growth ' + (leak.growth_pct || 0) + '%';
        leakEl.className = 'badge ' + (detected ? 'badge-danger' : 'badge-ok');
        if (leakRow) leakRow.style.display = '';
      }

      setLiveValue(document.getElementById('soakDiscCycles'), d.discovery_cycles != null ? d.discovery_cycles : '--');
      setLiveValue(document.getElementById('soakGaps'), d.gaps_detected != null ? d.gaps_detected : '--');
      setLiveValue(document.getElementById('soakHypotheses'), d.hypotheses_generated != null ? d.hypotheses_generated : '--');
      setLiveValue(document.getElementById('soakKnowledge'), d.knowledge_entities != null ? d.knowledge_entities : '--');

      const disc = d.discovery || {};
      const discEl = document.getElementById('soakDiscStatus');
      if (discEl && disc.status) {
        const st = disc.status;
        discEl.textContent = 'DISCOVERY: ' + String(disc.label || st).toUpperCase();
        discEl.className = 'badge ' + (st === 'active' || st === 'healthy_quiet' ? 'badge-ok' : st === 'scheduler_down' ? 'badge-danger' : 'badge-warn');
      }

      if (d.verdict) {
        const verdictEl = document.getElementById('soakVerdict');
        const verdictRow = document.getElementById('soakVerdictRow');
        if (verdictEl) {
          verdictEl.textContent = 'VERDICT ' + String(d.verdict).toUpperCase();
          verdictEl.className = 'badge ' + (d.verdict === 'pass' ? 'badge-ok' : 'badge-danger');
          if (verdictRow) verdictRow.style.display = '';
        }
      }

      if (!d.running && soakPollTimer) {
        clearInterval(soakPollTimer);
        soakPollTimer = null;
        setOpsFeedback('soakFeedback', 'Soak test completed.', 'success');
        toggleEl('btnSoakStart', true);
        toggleEl('btnSoakStop', false);
        toggleEl('btnSoakStatus', false);
      }
    } catch (err) {
      setOpsFeedback('soakFeedback', 'Status poll failed: ' + err.message, 'error');
    }
  }

  async function stopSoakTest() {
    setOpsSpinner('soakSpinner', true);
    try {
      await fetchJSON('/api/crav/soak_test/stop', { method: 'POST' });
      setOpsFeedback('soakFeedback', 'Soak test stopped.', 'info');
      if (soakPollTimer) {
        clearInterval(soakPollTimer);
        soakPollTimer = null;
      }
      toggleEl('btnSoakStart', true);
      toggleEl('btnSoakStop', false);
      toggleEl('btnSoakStatus', false);
    } catch (err) {
      setOpsFeedback('soakFeedback', 'Failed to stop: ' + err.message, 'error');
    }
    setOpsSpinner('soakSpinner', false);
  }

  async function launchAlpha() {
    setOpsSpinner('alphaSpinner', true);
    setOpsFeedback('alphaFeedback', 'Running pre-flight checklist...', 'info');
    toggleEl('alphaChecklist', false);
    toggleEl('alphaCertificate', false);
    try {
      const preflight = await fetchJSON('/api/crav/alpha_launch/preflight', { method: 'POST' });
      renderAlphaChecklist(preflight.data || preflight);

      const res = await fetchJSON('/api/crav/alpha_launch/launch', { method: 'POST' });
      const d = res.data || res;
      toggleEl('btnAlphaLaunch', false);
      toggleEl('btnAlphaAbort', true);
      if (d.certificate) {
        renderAlphaCertificate(d.certificate);
      }
      setOpsFeedback('alphaFeedback', 'Alpha launch initiated.', 'success');
    } catch (err) {
      setOpsFeedback('alphaFeedback', 'Alpha launch failed: ' + err.message, 'error');
    }
    setOpsSpinner('alphaSpinner', false);
  }

  function renderAlphaChecklist(data) {
    const el = document.getElementById('alphaChecklist');
    if (!el) return;
    toggleEl('alphaChecklist', true);
    const checks = ['crav_ready', 'runtime_census', 'discovery_chain', 'observatory_coverage', 'soak_test', 'compliance'];
    let html = '';
    checks.forEach(function(name) {
      const item = data[name];
      const pass = item && item.pass;
      const cls = pass ? 'pass' : 'fail';
      const icon = pass ? '✓' : '✗';
      const val = item ? (item.value != null ? item.value : (item.pass ? 'PASS' : 'FAIL')) : 'N/A';
      const reason = item && item.reason ? ' — ' + escapeHtml(String(item.reason)) : '';
      html += '<div class="ops-check-item ' + cls + '"><span class="ops-check-name">' + icon + ' ' + escapeHtml(name) + reason + '</span><span class="ops-check-value">' + escapeHtml(String(val)) + '</span></div>';
    });
    el.innerHTML = html;
  }

  function renderAlphaCertificate(cert) {
    const el = document.getElementById('alphaCertificate');
    if (!el) return;
    toggleEl('alphaCertificate', true);
    const rows = [
      ['Certificate ID', cert.certificate_id || '--'],
      ['Issued At', cert.issued_at || '--'],
      ['Recommendation', cert.recommendation || '--'],
      ['Signed By', cert.signed_by || '--'],
      ['Version', cert.version || '--']
    ];
    let html = '';
    rows.forEach(function(r) {
      html += '<div class="ops-cert-row"><span class="ops-cert-label">' + escapeHtml(r[0]) + '</span><span class="ops-cert-value">' + escapeHtml(String(r[1])) + '</span></div>';
    });
    if (cert.hash) {
      html += '<div class="ops-cert-hash">SHA-256: ' + escapeHtml(cert.hash) + '</div>';
    }
    if (cert.launch_conditions) {
      html += '<div style="margin-top:0.5rem;font-size:0.7rem;color:var(--text-secondary);">Launch Conditions:</div>';
      Object.keys(cert.launch_conditions).forEach(function(k) {
        html += '<div class="ops-cert-row"><span class="ops-cert-label">' + escapeHtml(k) + '</span><span class="ops-cert-value">' + escapeHtml(String(cert.launch_conditions[k])) + '</span></div>';
      });
    }
    el.innerHTML = html;
  }

  async function abortAlpha() {
    setOpsSpinner('alphaSpinner', true);
    try {
      await fetchJSON('/api/crav/alpha_launch/abort', { method: 'POST' });
      setOpsFeedback('alphaFeedback', 'Alpha launch aborted.', 'info');
      toggleEl('btnAlphaLaunch', true);
      toggleEl('btnAlphaAbort', false);
      toggleEl('alphaChecklist', false);
      toggleEl('alphaCertificate', false);
    } catch (err) {
      setOpsFeedback('alphaFeedback', 'Abort failed: ' + err.message, 'error');
    }
    setOpsSpinner('alphaSpinner', false);
  }

  async function generateAtlas() {
    setOpsSpinner('atlasSpinner', true);
    setOpsFeedback('atlasFeedback', 'Generating runtime atlas...', 'info');
    toggleEl('atlasSummary', false);
    toggleEl('btnAtlasExport', false);
    toggleEl('btnAtlasPrint', false);
    try {
      const res = await fetchJSON('/api/crav/atlas/generate', { method: 'POST' });
      const d = res.data || res;
      lastAtlasData = d;
      renderAtlasSummary(d);
      toggleEl('btnAtlasExport', true);
      toggleEl('btnAtlasPrint', true);
      setOpsFeedback('atlasFeedback', 'Atlas generated.', 'success');
    } catch (err) {
      setOpsFeedback('atlasFeedback', 'Atlas generation failed: ' + err.message, 'error');
    }
    setOpsSpinner('atlasSpinner', false);
  }

  function renderAtlasSummary(data) {
    const el = document.getElementById('atlasSummary');
    if (!el) return;
    toggleEl('atlasSummary', true);
    const subsystems = data.subsystems || [];
    const running = subsystems.filter(function(s) { return s.state === 'running'; }).length;
    const dormant = subsystems.filter(function(s) { return s.state === 'dormant'; }).length;
    const planned = subsystems.filter(function(s) { return s.state === 'planned'; }).length;
    const telCov = data.telemetry_coverage || {};
    const readiness = data.alpha_readiness || {};
    const certStatus = data.certification_status || {};

    const stats = [
      ['Subsystems', subsystems.length],
      ['Running', running],
      ['Dormant', dormant],
      ['Planned', planned],
      ['Telemetry Coverage', (telCov.percentage || 0) + '%'],
      ['Alpha Readiness', (readiness.overall || 0) + '%'],
      ['Recommendation', readiness.recommendation || '--'],
      ['Certified', certStatus.overall_certificate ? 'YES' : 'NO']
    ];

    let html = '';
    stats.forEach(function(s) {
      html += '<div class="ops-stat"><span class="ops-stat-label">' + escapeHtml(s[0]) + '</span><span class="ops-stat-value">' + escapeHtml(String(s[1])) + '</span></div>';
    });
    el.innerHTML = html;
  }

  function exportAtlas() {
    if (!lastAtlasData) return;
    const blob = new Blob([JSON.stringify(lastAtlasData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'tiannara_runtime_atlas.json';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    setOpsFeedback('atlasFeedback', 'Atlas exported as JSON.', 'success');
  }

  function printAtlas() {
    if (!lastAtlasData) return;
    const win = window.open('', '_blank');
    if (!win) {
      setOpsFeedback('atlasFeedback', 'Pop-up blocked. Allow pop-ups to print.', 'error');
      return;
    }
    const d = lastAtlasData;
    const subsystems = d.subsystems || [];
    const telCov = d.telemetry_coverage || {};
    const readiness = d.alpha_readiness || {};
    let html = '<html><head><title>Tiannara Runtime Atlas</title><style>';
    html += 'body{font-family:monospace;padding:2rem;background:#0a0e1a;color:#e8ecf4;}';
    html += 'h1{color:#00d9ff;}h2{color:#00d9ff;margin-top:2rem;}';
    html += 'table{border-collapse:collapse;width:100%;margin:1rem 0;}';
    html += 'th,td{border:1px solid #1a2035;padding:0.4rem 0.75rem;text-align:left;font-size:0.85rem;}';
    html += 'th{background:#111827;color:#00d9ff;}';
    html += '.running{color:#00ff9f;}.dormant{color:#ffb800;}.planned{color:#5a6478;}';
    html += '</style></head><body>';
    html += '<h1>' + escapeHtml(d.title || 'Tiannara Runtime Atlas') + '</h1>';
    html += '<p>Version: ' + escapeHtml(String(d.version || '--')) + ' | Generated: ' + escapeHtml(String(d.generated_at || '--')) + '</p>';
    html += '<p>Subsystems: ' + subsystems.length + ' | Telemetry: ' + (telCov.percentage || 0) + '% | Readiness: ' + (readiness.overall || 0) + '%</p>';
    html += '<h2>Subsystems</h2><table><tr><th>Name</th><th>State</th><th>Description</th><th>Dependencies</th></tr>';
    subsystems.forEach(function(s) {
      const st = s.state || 'unknown';
      html += '<tr><td>' + escapeHtml(String(s.name || '--')) + '</td><td class="' + st + '">' + escapeHtml(st) + '</td><td>' + escapeHtml(String(s.description || '--')) + '</td><td>' + escapeHtml(Array.isArray(s.dependencies) ? s.dependencies.join(', ') : '--') + '</td></tr>';
    });
    html += '</table></body></html>';
    win.document.write(html);
    win.document.close();
    win.print();
    setOpsFeedback('atlasFeedback', 'Atlas print dialog opened.', 'success');
  }

  async function runAllChallenges() {
    setOpsSpinner('challengesSpinner', true);
    setOpsFeedback('challengesFeedback', 'Running all 13 challenges...', 'info');
    toggleEl('challengesResults', false);

    const payload = {
      challenges: CHALLENGE_NAMES.map(function(name) {
        return { name: name, prompt: name };
      })
    };

    try {
      const res = await fetchJSON('/api/challenges/run', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      renderChallengeResults(res);
      setOpsFeedback('challengesFeedback', 'All challenges completed.', 'success');
    } catch (err) {
      setOpsFeedback('challengesFeedback', 'Challenge run failed: ' + err.message, 'error');
    }
    setOpsSpinner('challengesSpinner', false);
  }

  function renderChallengeResults(data) {
    const el = document.getElementById('challengesResults');
    if (!el) return;
    toggleEl('challengesResults', true);

    const results = data.results || {};
    let html = '';
    CHALLENGE_NAMES.forEach(function(name) {
      const r = results[name];
      let status = 'unknown';
      let statusLabel = '???';
      let confidence = '--';
      let execTime = '--';

      if (r) {
        if (r.status === 'executed' || r.status === 'ok' || r.status === 'completed') {
          status = 'pass';
          statusLabel = 'PASS';
        } else if (r.status === 'error' || r.status === 'failed') {
          status = 'fail';
          statusLabel = 'FAIL';
        } else if (r.status === 'module_not_available' || r.status === 'unknown_challenge') {
          status = 'unknown';
          statusLabel = 'N/A';
        } else {
          status = 'pass';
          statusLabel = 'PASS';
        }
        confidence = r.confidence != null ? r.confidence.toFixed(2) : (r.status || '--');
        execTime = r.execution_time_us != null ? (r.execution_time_us / 1000).toFixed(1) + 'ms' : '--';
        if (r.result && r.result.execution_time_us != null) {
          execTime = (r.result.execution_time_us / 1000).toFixed(1) + 'ms';
        }
      }

      html += '<div class="ops-result-item">';
      html += '<span class="ops-result-status ' + status + '">' + statusLabel + '</span>';
      html += '<span class="ops-result-name">' + escapeHtml(name) + '</span>';
      html += '<span class="ops-result-meta"><span>conf: ' + escapeHtml(String(confidence)) + '</span><span>time: ' + escapeHtml(String(execTime)) + '</span></span>';
      html += '</div>';
    });
    el.innerHTML = html;
  }

  async function triggerCampaign() {
    const btn = document.getElementById('btnTriggerCampaign');
    const status = document.getElementById('campaignTriggerStatus');
    if (!btn) return;
    btn.disabled = true;
    btn.textContent = 'Triggering…';
    if (status) status.textContent = 'Triggering pipeline...';
    try {
      const r = await fetchJSON(API_BASE + '/crav/campaign/trigger', { method: 'POST' });
      if (status) status.textContent = r.status === 'accepted' ? 'Pipeline triggered ✓' : 'Error: ' + (r.message || 'unknown');
      if (r.status === 'accepted') toast('Campaign pipeline triggered', 'success');
    } catch (e) {
      if (status) status.textContent = 'Failed to trigger';
      toast('Campaign trigger failed', 'error');
    }
    btn.disabled = false;
    btn.textContent = 'Trigger Campaign';
  }

  function setLiveValue(el, next) {
    if (!el) return;
    const cur = el.textContent;
    const val = String(next);
    if (cur !== val) {
      el.textContent = val;
      el.classList.remove('flash');
      void el.offsetWidth;
      el.classList.add('flash');
    }
  }

  async function fetchLoop() {
    try {
      const r = await fetchJSON(API_BASE + '/feedback/loop');
      const d = r || {};
      const closed = d.cycles > 0;
      const arc = document.getElementById('loopArc');
      const badge = document.getElementById('loopBadge');

      if (arc) {
        arc.style.strokeDashoffset = closed ? '0' : '264';
        arc.style.stroke = closed ? 'var(--success)' : 'var(--critical)';
      }
      if (badge) {
        badge.textContent = closed ? 'Loop Closed' : 'Loop Open';
        badge.className = 'status-badge ' + (closed ? 'operational dot' : 'critical dot');
      }
      setLiveValue(document.getElementById('loopCycles'), d.cycles);
      const last = document.getElementById('loopLast');
      if (last) last.textContent = d.last_at || '—';
    } catch (e) { /* keep last state */ }
  }

  const ASC_PHASES = [
    { id: 'research',     name: 'Research',      phase: '6'  },
    { id: 'meta_science', name: 'Meta-Science',  phase: '7'  },
    { id: 'engineering',  name: 'Engineering',   phase: '8'  },
    { id: 'reality',      name: 'Reality',       phase: '9'  },
    { id: 'civilization', name: 'Civilization',  phase: '10' }
  ];

  async function fetchASC() {
    const grid = document.getElementById('ascGrid');
    if (!grid) return;
    try {
      const r = await fetchJSON(API_BASE + '/asc/status');
      const phases = r.phases || {};

      grid.innerHTML = ASC_PHASES.map(function(p) {
        const s = phases[p.id] || { healthy: 0, total: 0 };
        const h = s.total === 0 ? 'warn' : (s.healthy === s.total ? 'ok' : (s.healthy === 0 ? 'danger' : 'warn'));
        return '<div class="asc-cell" data-h="' + h + '">' +
          '<div class="asc-name">' + escapeHtml(p.name) + ' <span class="faint mono">P' + p.phase + '</span></div>' +
          '<div class="asc-meta mono">' + s.healthy + '/' + s.total + ' services</div></div>';
      }).join('');

      var totalH = 0, totalT = 0;
      Object.keys(phases).forEach(function(k) {
        totalH += phases[k].healthy || 0;
        totalT += phases[k].total || 0;
      });
      var sum = document.getElementById('ascSummary');
      if (sum) {
        sum.textContent = totalH + '/' + totalT + ' healthy';
        sum.className = 'status-badge ' + (totalH === totalT && totalT > 0 ? 'operational' : 'degraded');
      }
    } catch (e) { /* keep last */ }
  }

  // ── Helpers ──────────────────────────────────────────────
  const CIRC = 326.7; // 2πr for r=52
  function healthColor(v){ return v > 0.7 ? '--success' : v > 0.4 ? '--warning' : '--critical'; }
  function riskColor(v){ return v > 0.6 ? '--critical' : v > 0.3 ? '--warning' : '--success'; }
  function cssVar(name){ return getComputedStyle(document.documentElement).getPropertyValue(name).trim(); }

  function setGauge(arcEl, valEl, frac, colorVar){
    if (!arcEl || !valEl) return;
    arcEl.style.strokeDashoffset = String(CIRC * (1 - Math.max(0, Math.min(1, frac))));
    arcEl.style.stroke = cssVar(colorVar);
    setLiveValue(valEl, Math.round(frac * 100));
  }

  function markFreshness(panelId, freshness){
    document.getElementById(panelId).classList.toggle('stale', freshness === 'stale');
  }

  // fetch URL relative to API_BASE (strip trailing /api/v1 for top-level api routes)
  function civUrl(path){ return API_BASE.replace('/api/v1','') + '/api/v1' + path; }

  // ── CIVILIZATION ─────────────────────────────────────────
  const CIV_DOMAINS = ['technology','ecology','energy','governance','medicine','logistics','education','manufacturing','scientific_output'];
  let civPlan = null, civHorizon = 10;

  document.querySelectorAll('.horizon-tab').forEach(function(tab) {
    tab.addEventListener('click', function() {
      document.querySelectorAll('.horizon-tab').forEach(function(t) { t.setAttribute('aria-selected', 'false'); });
      tab.setAttribute('aria-selected', 'true');
      civHorizon = parseInt(tab.dataset.horizon, 10);
      renderCivTargets();
    });
  });

  async function fetchCiv(){
    const err = document.getElementById('civError');
    const empty = document.getElementById('civEmpty');
    try {
      const [sr, pr, dr] = await Promise.all([
        fetch(civUrl('/civilizational/state')).then(function(r) { return r.json(); }),
        fetch(API_BASE + '/civilization/plan').then(function(r) { return r.json(); }).catch(function() { return {}; }),
        fetch(API_BASE + '/civilization/decisions').then(function(r) { return r.json(); }).catch(function() { return []; })
      ]);
      err.hidden = true;
      var state = sr.state || {};
      civPlan = pr.plan || pr || null;
      markFreshness('civPanel', sr.freshness);

      var hasData = CIV_DOMAINS.some(function(d) { return typeof state[d] === 'number'; });
      empty.hidden = hasData;
      document.getElementById('civDomains').style.display = hasData ? '' : 'none';

      renderCivDomains(state);
      renderCivTargets();
      renderCivPriorities(civPlan);
      renderCivDecisions(Array.isArray(dr) ? dr : (dr.decisions || []));
    } catch (e) { err.hidden = false; }
  }

  function renderCivDomains(state){
    var el = document.getElementById('civDomains');
    el.innerHTML = CIV_DOMAINS.map(function(d) {
      var v = typeof state[d] === 'number' ? state[d] : 0;
      return '<div class="domain-row">' +
        '<span class="domain-name">' + d.replace(/_/g,' ') + '</span>' +
        '<div class="domain-track">' +
          '<div class="domain-fill" data-domain="' + d + '" style="width:' + (v*100).toFixed(0) + '%;background:var(' + healthColor(v) + ');"></div>' +
          '<div class="domain-target" data-domain="' + d + '" style="left:' + (v*100).toFixed(0) + '%;"></div>' +
        '</div>' +
        '<span class="domain-val mono">' + (v*100).toFixed(0) + '</span>' +
      '</div>';
    }).join('');
  }

  function renderCivTargets(){
    if (!civPlan || !civPlan.horizons) return;
    var horizon = civPlan.horizons.find(function(h) { return h.horizon_years === civHorizon; });
    if (!horizon || !horizon.objectives) return;
    var targets = {};
    horizon.objectives.forEach(function(o) { targets[o.domain] = o.target; });
    document.querySelectorAll('.domain-target').forEach(function(tick) {
      var d = tick.dataset.domain;
      if (typeof targets[d] === 'number') tick.style.left = (targets[d]*100).toFixed(0) + '%';
    });
  }

  function renderCivPriorities(plan){
    var el = document.getElementById('civPriorities');
    var priorities = (plan && plan.priorities) || [];
    el.innerHTML = priorities.length
      ? priorities.slice(0,4).map(function(p,i) { return '<div class="feed-item"><span class="idx">' + String(i+1).padStart(2,'0') + '</span><span class="body"><strong>' + escapeHtml(String(p.priority || 'priority')) + '</strong> · ' + escapeHtml(String(p.urgency || '')) + '</span></div>'; }).join('')
      : '<div class="state-box" style="padding:var(--sp-3)"><span class="faint">No priorities set</span></div>';
  }

  function renderCivDecisions(decisions){
    var el = document.getElementById('civDecisions');
    el.innerHTML = decisions.length
      ? decisions.slice(0,4).map(function(d) { return '<div class="feed-item"><span class="idx">◆</span><span class="body"><strong>' + escapeHtml(String(d.type || 'decision')) + '</strong> — ' + escapeHtml(String(d.action || '')) + '</span></div>'; }).join('')
      : '<div class="state-box" style="padding:var(--sp-3)"><span class="faint">No decisions recorded</span></div>';
  }

  // ── RISK ─────────────────────────────────────────────────
  async function fetchRisk(){
    var err = document.getElementById('riskError');
    try {
      var d = await fetch(civUrl('/civilizational/risk')).then(function(r) { return r.json(); });
      err.hidden = true;
      var risk = d.risk || {};
      markFreshness('riskPanel', d.freshness);

      setGauge(document.getElementById('riskArc'), document.getElementById('riskValue'), risk.overall_risk || 0, riskColor(risk.overall_risk || 0));

      var cats = (risk.risks || []).slice().sort(function(a,b) { return b.probability - a.probability; });
      document.getElementById('riskList').innerHTML = cats.map(function(c,i) {
        return '<div class="risk-row' + (i===0?' top':'') + '">' +
          '<span class="risk-name">' + escapeHtml(String(c.category)) + '</span>' +
          '<div class="risk-track"><div class="risk-fill" style="width:' + (c.probability*100).toFixed(0) + '%;background:var(' + riskColor(c.probability) + ');"></div></div>' +
          '<span class="risk-pct mono">' + (c.probability*100).toFixed(0) + '%</span>' +
        '</div>';
      }).join('');

      var top = cats[0];
      document.getElementById('riskMitigation').innerHTML = top
        ? 'Highest risk: <strong style="color:var(--text-primary)">' + escapeHtml(String(top.category)) + '</strong> — ' + escapeHtml(String(top.mitigation || 'no mitigation defined'))
        : '';
    } catch (e) { err.hidden = false; }
  }

  // ── SUSTAINABILITY ───────────────────────────────────────
  var sustHistory = [];
  var STATUS_BADGE = { sustainable:'badge-ok', transitional:'badge-info', at_risk:'badge-warn', critical:'badge-danger' };

  async function fetchSust(){
    var err = document.getElementById('sustError');
    try {
      var d = await fetch(civUrl('/civilizational/sustainability')).then(function(r) { return r.json(); });
      err.hidden = true;
      var s = d.sustainability || {};
      markFreshness('sustPanel', d.freshness);

      setGauge(document.getElementById('sustArc'), document.getElementById('sustValue'), s.score || 0, healthColor(s.score || 0));

      var badge = document.getElementById('sustStatus');
      badge.textContent = (s.status || '—').replace(/_/g,' ');
      badge.className = 'badge ' + (STATUS_BADGE[s.status] || 'badge-neutral');

      var dims = s.dimensions || {};
      document.getElementById('sustDims').innerHTML = Object.keys(dims).map(function(k) {
        var v = dims[k];
        return '<div class="dim-row">' +
          '<span class="dim-name">' + escapeHtml(k) + '</span>' +
          '<div class="dim-track"><div class="dim-fill" style="width:' + (v*100).toFixed(0) + '%;background:var(' + healthColor(v) + ');"></div></div>' +
          '<span class="mono" style="font-size:var(--text-sm);text-align:right;">' + (v*100).toFixed(0) + '</span>' +
        '</div>';
      }).join('');

      var recs = s.recommendations || [];
      document.getElementById('sustRecs').innerHTML = recs.length
        ? recs.map(function(rc) { return '<div class="feed-item"><span class="idx">→</span><span class="body">' + escapeHtml(String(rc.action || rc)) + '</span></div>'; }).join('')
        : '<div class="state-box" style="padding:var(--sp-3)"><span class="faint">No recommendations — trajectory healthy</span></div>';

      // trend sparkline
      sustHistory.push(s.score || 0);
      if (sustHistory.length > 40) sustHistory.shift();
      drawSparkline('sustSpark', sustHistory);
    } catch (e) { err.hidden = false; }
  }

  function drawSparkline(id, data){
    var svg = document.getElementById(id);
    if (!svg || data.length < 2) { if (svg) svg.innerHTML = ''; return; }
    var W = 200, H = 40, pad = 2;
    var min = Math.min.apply(null, data), max = Math.max.apply(null, data), span = (max - min) || 1;
    var pts = data.map(function(v,i) {
      var x = pad + (i / (data.length - 1)) * (W - pad*2);
      var y = H - pad - ((v - min) / span) * (H - pad*2);
      return x.toFixed(1) + ',' + y.toFixed(1);
    });
    var line = pts.join(' ');
    var area = pad + ',' + (H-pad) + ' ' + line + ' ' + (W-pad) + ',' + (H-pad);
    svg.innerHTML = '<polygon class="area" points="' + area + '"/><polyline points="' + line + '"/>';
  }

  // ── PIPELINE TELEMETRY ────────────────────────────────────

  async function fetchPT(){
    var err = document.getElementById('ptError');
    try {
      var d = await fetch(civUrl('/campaign/telemetry')).then(function(r) { return r.json(); });
      err.hidden = true;
      markFreshness('ptPanel', d.freshness);

      var cycles = d.cycles || {};
      document.getElementById('ptCycleCount').textContent = cycles.count || 0;
      document.getElementById('ptAvgMs').textContent = cycles.avg_ms != null ? cycles.avg_ms : '—';
      document.getElementById('ptP95Ms').textContent = cycles.p95_ms != null ? cycles.p95_ms : '—';
      document.getElementById('ptLastMs').textContent = cycles.last_ms != null ? cycles.last_ms : '—';

      var fbk = d.feedback || {};
      document.getElementById('ptFeedbackCount').textContent = fbk.count || 0;

      // badge
      var badge = document.getElementById('ptStatus');
      if (!d.cycles || d.cycles.count < 1) {
        badge.textContent = 'No Data';
        badge.className = 'badge badge-neutral';
      } else {
        var lastOk = document.querySelector('#ptTimeline .pt-timeline-dot.ok');
        badge.textContent = lastOk ? 'Active' : 'Running';
        badge.className = 'badge badge-info';
      }

      // per-phase bars
      var phases = d.phases || {};
      document.getElementById('ptPhases').innerHTML = Object.keys(phases).sort().map(function(k) {
        var p = phases[k];
        var total = p.ok + p.fail;
        var okPct = total > 0 ? (p.ok / total * 100).toFixed(0) : 0;
        var cls = okPct >= 80 ? 'ok' : (okPct >= 50 ? 'warn' : 'danger');
        return '<div class="pt-bar">' +
          '<span class="pt-label" style="min-width:7em;">' + escapeHtml(k) + '</span>' +
          '<div class="pt-bar-fill"><div class="pt-bar-fill-inner ' + cls + '" style="width:' + okPct + '%"></div></div>' +
          '<span class="pt-stat" style="min-width:5ch;">' + p.ok + '/' + total + '</span>' +
          '<span class="pt-meta">' + (p.last_ms != null ? p.last_ms + 'ms' : '') + '</span>' +
        '</div>';
      }).join('') || '<div class="pt-bar"><span class="faint">No phase data yet</span></div>';

      // recent cycle timeline
      var recent = cycles.recent || [];
      document.getElementById('ptTimeline').innerHTML = recent.length
        ? recent.map(function(c) {
            var col = c.ok ? 'ok' : 'fail';
            var ts = c.at ? new Date(c.at).toLocaleTimeString() : '';
            return '<div class="pt-timeline-item">' +
              '<span class="pt-timeline-dot ' + col + '"></span>' +
              '<span>' + (c.duration_ms != null ? c.duration_ms + 'ms' : '—') + '</span>' +
              '<span class="pt-meta">' + ts + '</span>' +
            '</div>';
          }).join('')
        : '<div class="pt-meta">No cycles recorded yet</div>';
    } catch (e) { err.hidden = false; }
  }

  // ── PHYSICAL DEPLOYMENT ──────────────────────────────────
  const PHYS_STAGES = ['planned','safety_reviewed','pending_approval','approved','simulated','dry_run','supervised','autonomous','completed'];
  const PHYS_TERMINAL = ['rejected','rolled_back','aborted'];
  const PHYS_STAGE_LABELS = { planned:'Planned', safety_reviewed:'Safety Reviewed', pending_approval:'Human Gate', approved:'Approved', simulated:'Simulated', dry_run:'Dry Run', supervised:'Supervised', autonomous:'Autonomous', completed:'Completed', rejected:'Rejected', rolled_back:'Rolled Back', aborted:'Aborted' };
  let physCache = [];
  let physSelectedId = null;

  async function fetchPhysical(){
    const err = document.getElementById('physError');
    const empty = document.getElementById('physEmpty');
    try {
      const res = await fetch(API_BASE + '/reality/physical').then(function(r) { return r.json(); });
      const list = (res.data || res.deployments || []);
      err.hidden = true;
      empty.hidden = list.length > 0;
      document.getElementById('physRows').style.display = list.length > 0 ? '' : 'none';
      physCache = list;
      renderPhysical(list);
      document.getElementById('physPanel').classList.remove('stale');
    } catch (e) { err.hidden = false; }
  }

  function renderPhysical(deployments){
    const filter = document.getElementById('physFilterSelect').value;
    const visible = deployments.filter(function(d) {
      if (filter === 'all') return true;
      if (filter === 'pending_approval') return d.stage === 'pending_approval';
      if (filter === 'active') return PHYS_STAGES.indexOf(d.stage) >= 0 && d.stage !== 'planned' && d.stage !== 'completed';
      if (filter === 'terminal') return PHYS_TERMINAL.indexOf(d.stage) >= 0;
      return true;
    });

    document.getElementById('physRows').innerHTML = visible.length
      ? visible.map(physRow).join('')
      : '<div id="physRowPlaceholder" class="state-box" style="padding:var(--sp-3)"><span class="faint">No deployments in this view.</span></div>';

    var approved = 0, pending = 0;
    deployments.forEach(function(d) {
      if (d.stage === 'pending_approval') pending++;
      if (PHYS_STAGES.indexOf(d.stage) >= 4) approved++;
    });

    setGauge(document.getElementById('physArc'), document.getElementById('physGauge'),
      deployments.length ? approved / deployments.length : 0, pending > 0 ? '--warning' : '--success');

    var badge = document.getElementById('physStatus');
    if (pending > 0) {
      badge.textContent = pending + ' Awaiting Approval';
      badge.className = 'badge badge-warn';
    } else if (deployments.length === 0) {
      badge.textContent = 'No Data';
      badge.className = 'badge badge-neutral';
    } else {
      badge.textContent = 'All Clear';
      badge.className = 'badge badge-ok';
    }

    renderLaunchTrack(deployments);

    if (physSelectedId) {
      var stillThere = deployments.some(function(d) { return d.id === physSelectedId; });
      if (stillThere) selectPhysical(physSelectedId);
    }
  }

  function renderLaunchTrack(deployments){
    const el = document.getElementById('physLaunchTrack');
    const active = deployments.find(function(d) { return PHYS_STAGES.indexOf(d.stage) >= 0 && d.stage !== 'completed'; }) || deployments[deployments.length - 1];
    if (!active) {
      el.innerHTML = '<div class="state-box" style="padding:var(--sp-3)"><span class="faint">No active launch track</span></div>';
      return;
    }
    const idx = PHYS_STAGES.indexOf(active.stage);
    const pieces = [];
    PHYS_STAGES.forEach(function(stage, i) {
      if (i > 0) pieces.push('<span class="ph-connector' + (i <= idx ? ' ph-connector-live' : '') + '"></span>');
      const stateCls = i < idx ? 'ph-done' : (i === idx ? 'ph-live' : '');
      const isGate = stage === 'pending_approval';
      pieces.push('<div class="ph-node ' + stateCls + (isGate ? ' ph-gate' : '') + '">' +
        '<span class="ph-dot"></span>' +
        '<span class="ph-label">' + PHYS_STAGE_LABELS[stage] + '</span>' +
        (isGate ? '<span class="ph-gate-chevron"></span>' : '') +
      '</div>');
    });
    el.innerHTML = pieces.join('');
  }

  function physRow(d){
    const stage = d.stage || 'planned';
    const time = (d.stage_times && d.stage_times[stage]) || '—';
    const approvedBy = d.approval ? (d.approval.approver || d.approval.decision || 'approved') : '—';
    return '<div class="phys-entry">' +
      '<div class="phys-row' + (physSelectedId === d.id ? ' selected' : '') + '" data-stage="' + stage + '" data-id="' + escapeHtml(String(d.id)) + '">' +
        '<span class="phys-index">' + escapeHtml(String(d.id)) + '</span>' +
        '<span class="phys-title">' +
          '<span class="phys-name">' + escapeHtml(String(d.name || d.id)) + '</span>' +
          '<span class="phys-sublabel">' + escapeHtml(String(d.adapter || 'simulated')) + ' · <span class="phys-approved-by">' + escapeHtml(approvedBy) + '</span></span>' +
        '</span>' +
        '<span class="ph-node"><span class="ph-dot"></span><span class="ph-label">' + PHYS_STAGE_LABELS[stage] + '</span></span>' +
        '<span class="ph-connector ' + (stage === 'completed' ? 'ph-connector-live' : '') + '"></span>' +
        '<span class="ph-gate ' + (stage === 'pending_approval' ? 'ph-gate-live' : '') + '">' +
          '<span class="ph-gate-chevron"></span>' +
          '<span class="ph-gate-label">' + (stage === 'pending_approval' ? 'HUMAN GATE' : '') + '</span>' +
        '</span>' +
      '</div>' +
      '<div class="phys-meta">' +
        '<span>' + escapeHtml(time) + '</span>' +
        '<span>' + ((d.summary && d.summary.safety) || 0) + ' safety checks</span>' +
        '<span>' + ((d.summary && d.summary.steps) || 0) + ' steps</span>' +
      '</div>' +
    '</div>';
  }

  function selectPhysical(id){
    const d = physCache.find(function(x) { return x.id === id; });
    if (!d) return;
    physSelectedId = id;
    document.querySelectorAll('.phys-row').forEach(function(row) {
      row.classList.toggle('selected', row.dataset.id === id);
    });

    const stage = d.stage || 'planned';
    const idx = PHYS_STAGES.indexOf(stage);
    const pct = Math.round(((idx >= 0 ? idx : 0) + 1) / PHYS_STAGES.length * 100);
    const time = (d.stage_times && d.stage_times[stage]) || '—';
    const step = (d.plan && d.plan.steps && d.plan.steps.length) ? String(d.plan.steps[d.plan.steps.length - 1]) : '—';

    document.getElementById('physDetails').innerHTML =
      '<div class="phys-plan-step"><span class="eyebrow">Plan Step</span><span class="mono" id="physPlanStep">' + escapeHtml(step) + '</span></div>' +
      '<div class="phys-plan-step"><span class="eyebrow">Timestamp</span><span class="mono" id="physTimestamp">' + escapeHtml(time) + '</span></div>' +
      '<div class="phys-progress-row"><span class="eyebrow">Progress</span><div class="phys-progress"><div class="phys-progress-fill" id="physProgress" style="width:' + pct + '%"></div></div><span class="mono">' + pct + '%</span></div>' +
      '<div class="phys-approval">' + (d.approval
        ? '<span class="badge badge-ok">' + escapeHtml(String(d.approval.decision)) + ' · ' + escapeHtml(String(d.approval.approver || 'human')) + '</span>'
        : '<span class="faint">No approval decision</span>') +
        (d.estop_active ? '<span class="badge badge-danger">E-STOP ARMED</span>' : '') +
      '</div>';

    document.getElementById('physCapabilities').innerHTML =
      '<span class="eyebrow">Adapter</span><div class="phys-caps">' +
        '<span class="badge badge-info">' + escapeHtml(String(d.adapter || 'simulated')) + '</span>' +
        '<span class="badge badge-neutral">stage ' + escapeHtml(stage) + '</span>' +
      '</div>';

    const terminal = PHYS_TERMINAL.indexOf(stage) >= 0;
    document.getElementById('physApproveBtn').hidden = stage !== 'pending_approval';
    document.getElementById('physRejectBtn').hidden = stage !== 'pending_approval';
    document.getElementById('physAbortBtn').hidden = terminal;
    document.getElementById('physEstopBtn').hidden = terminal;
  }

  async function postPhysical(id, action){
    if (!id) return;
    try {
      const res = await fetchJSON(API_BASE + '/reality/physical/' + encodeURIComponent(id) + '/approve', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ decision: action, approver: 'human-operator', note: 'COA action: ' + action })
      });
      if (res.status !== 'ok') throw new Error(res.reason || 'action failed');
      toast('Physical: ' + action + ' → ' + id, 'success');
      fetchPhysical();
    } catch (err) { toast('Physical action failed: ' + action, 'error'); }
  }

  function bindPhysicalControls(){
    const approveBtn = document.getElementById('physApproveBtn');
    const rejectBtn = document.getElementById('physRejectBtn');
    const abortBtn = document.getElementById('physAbortBtn');
    const estopBtn = document.getElementById('physEstopBtn');
    const filter = document.getElementById('physFilterSelect');
    const rows = document.getElementById('physRows');

    if (approveBtn) approveBtn.addEventListener('click', function() { postPhysical(physSelectedId, 'approved'); });
    if (rejectBtn) rejectBtn.addEventListener('click', function() { postPhysical(physSelectedId, 'reject'); });
    if (abortBtn) abortBtn.addEventListener('click', function() { postPhysical(physSelectedId, 'abort'); });
    if (estopBtn) estopBtn.addEventListener('click', function() { postPhysical(physSelectedId, 'emergency_stop'); });
    if (filter) filter.addEventListener('change', function() { renderPhysical(physCache); });
    if (rows) rows.addEventListener('click', function(e) {
      const row = e.target.closest('.phys-row');
      if (row) selectPhysical(row.dataset.id);
    });
  }

  // ── Polling for civ/risk/sust/pt ─────────────────────────
  fetchCiv();  fetchRisk();  fetchSust();  fetchPT();
  fetchPhysical();
  setInterval(fetchCiv, 60000);
  setInterval(fetchRisk, 45000);
  setInterval(fetchSust, 45000);
  setInterval(fetchPT, 30000);
  setInterval(fetchPhysical, 30000);

  // ── Runtime bridge connection status ─────────────────────
  const BRIDGE_LABELS = { connected: 'Runtime Live', degraded: 'Degraded', disconnected: 'Offline' };

  async function fetchBridgeStatus() {
    const el = document.getElementById('bridgeStatus');
    const label = document.getElementById('bridgeLabel');
    if (!el || !label) return;
    try {
      const r = await fetch(API_BASE + '/bridge/status');
      const d = await r.json();
      const st = d.status || 'disconnected';
      el.dataset.state = st;
      label.textContent = BRIDGE_LABELS[st] + ' · ' + (d.mode || '?');
    } catch (e) {
      el.dataset.state = 'disconnected';
      label.textContent = 'Offline';
    }
  }
  setInterval(fetchBridgeStatus, 10000);
  fetchBridgeStatus();

  document.addEventListener('DOMContentLoaded', init);

  return { toast, refreshAll, showSection };
})();
