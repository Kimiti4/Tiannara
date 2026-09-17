(function() {
  let statusTimer = null;
  let notificationTimer = null;
  let currentView = 'dashboard';

  function init() {
    startClock();
    bindNavigation();
    bindNotifications();
    loadProfiles();
    loadCoaFrame();
    fetchStatus();
    statusTimer = setInterval(fetchStatus, 30000);
    listenForEvents();
    document.getElementById('qaValidate').addEventListener('click', validateEnv);
    document.getElementById('qaBoot').addEventListener('click', () => startBoot());
    document.getElementById('qaShutdown').addEventListener('click', shutdownAll);
    document.getElementById('qaEmergencyStop').addEventListener('click', emergencyStopAll);
    document.getElementById('qaDiagnostics').addEventListener('click', runDiag);
    document.getElementById('svcRefresh').addEventListener('click', fetchStatus);
    document.getElementById('diagRun').addEventListener('click', runDiag);
    document.getElementById('logsRefresh').addEventListener('click', loadLogs);
    document.getElementById('logsClear').addEventListener('click', () => { document.getElementById('logContainer').innerHTML = '<div class="log-placeholder">No log entries yet</div>'; });
    document.getElementById('snapSave').addEventListener('click', saveSnapshot);
    document.getElementById('snapRefresh').addEventListener('click', loadSnapshots);
    document.getElementById('coaRefresh').addEventListener('click', loadCoaFrame);
    document.getElementById('btnStartBoot').addEventListener('click', () => startBoot(getSelectedProfile()));
    document.getElementById('btnEmergencyStop').addEventListener('click', emergencyStopAll);
    document.getElementById('btnSafeMode').addEventListener('click', safeMode);
  }

  function getSelectedProfile() { const s = document.getElementById('profileSelect'); return s ? s.value : 'development'; }

  async function loadProfiles() {
    if (!window.tiannara) return;
    try {
      const profiles = await window.tiannara.getProfiles();
      const sel = document.getElementById('profileSelect');
      if (!sel || !profiles) return;
      sel.innerHTML = '';
      profiles.forEach(p => {
        const opt = document.createElement('option');
        opt.value = p.id; opt.textContent = `${p.label} (${p.id})`;
        sel.appendChild(opt);
      });
    } catch (_) {}
  }

  function startClock() {
    const el = document.getElementById('desktopClock');
    function tick() {
      const now = new Date();
      el.textContent = now.toLocaleTimeString('en-US', { hour12: false }) + ' UTC';
    }
    tick();
    setInterval(tick, 1000);
  }

  function bindNavigation() {
    document.querySelectorAll('.sidebar-item').forEach(item => {
      item.addEventListener('click', () => {
        const view = item.dataset.view;
        document.querySelectorAll('.sidebar-item').forEach(n => n.classList.remove('active'));
        item.classList.add('active');
        showView(view);
      });
    });
  }

  function showView(name) {
    document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
    const target = document.getElementById('view-' + name);
    if (target) {
      target.classList.add('active');
      currentView = name;
      if (name === 'logs') loadLogs();
      if (name === 'snapshots') loadSnapshots();
      if (name === 'diagnostics') fetchStatus();
      if (name === 'services') fetchStatus();
    }
  }

  function bindNotifications() {
    const closeBtn = document.getElementById('notificationClose');
    if (closeBtn) closeBtn.addEventListener('click', hideNotification);
  }

  function listenForEvents() {
    if (window.tiannara) {
      window.tiannara.onSystemEvent(function(event) {
        if (event.type === 'boot-complete') {
          showNotification('Boot sequence complete', 'success');
          updateStatusUI(event.status || []);
        }
        if (event.type === 'status-update') {
          updateStatusUI(event.status || []);
        }
      });
    }
  }

  async function fetchStatus() {
    if (!window.tiannara) return;
    try {
      const status = await window.tiannara.getSystemStatus();
      updateStatusUI(status);
    } catch (_) {}
  }

  function updateStatusUI(status) {
    if (!Array.isArray(status)) return;
    // Top bar
    const bar = document.getElementById('topStatusBar');
    if (bar) {
      const critical = status.filter(s => s.state === 'FAILED' || s.state === 'RECOVERING');
      const running = status.filter(s => s.state === 'RUNNING');
      bar.innerHTML = critical.length > 0
        ? `<span class="desktop-status-item"><span class="desktop-status-dot critical"></span><span class="desktop-status-label">${critical.length} FAILED</span></span>`
        : `<span class="desktop-status-item"><span class="desktop-status-dot healthy"></span><span class="desktop-status-label">${running.length}/${status.length} RUNNING</span></span>`;
    }

    // Dashboard stats
    const running = status.filter(s => s.state === 'RUNNING').length;
    const failed = status.filter(s => s.state === 'FAILED').length;
    const allUp = running === status.length && status.length > 0;

    document.getElementById('dashStatus').innerHTML = `<span class="status-dot ${allUp ? 'healthy' : failed > 0 ? 'critical' : 'warning'}"></span> ${allUp ? 'All Systems Online' : failed > 0 ? `${failed} Failed` : 'Partial'}`;
    document.getElementById('dashRunning').textContent = running;
    document.getElementById('dashFailed').textContent = failed;

    const uptimeEl = document.getElementById('dashUptime');
    const runningSvc = status.find(s => s.state === 'RUNNING' && s.uptime > 0);
    if (runningSvc) {
      const sec = Math.floor(runningSvc.uptime / 1000);
      uptimeEl.textContent = `${Math.floor(sec / 60)}m ${sec % 60}s`;
    } else {
      uptimeEl.textContent = '--';
    }

    document.getElementById('dashServices').textContent = `Services: ${running}/${status.length}`;

    // Services grid
    const grid = document.getElementById('servicesGridFull');
    if (grid) {
      grid.innerHTML = '';
      status.forEach(svc => {
        const card = document.createElement('div');
        card.className = `service-card-full ${svc.state.toLowerCase()}`;
        card.innerHTML = `
          <div class="svc-header">
            <span class="svc-name">${svc.name}</span>
            <span class="svc-state ${svc.state.toLowerCase()}">${svc.state}</span>
          </div>
          <div class="svc-body">
            <div class="svc-meta"><span class="svc-label">Status</span><span>${svc.statusMessage || svc.state}</span></div>
            ${svc.pid ? `<div class="svc-meta"><span class="svc-label">PID</span><span>${svc.pid}</span></div>` : ''}
            ${svc.healthScore != null ? `<div class="svc-meta"><span class="svc-label">Health</span><span>${(svc.healthScore * 100).toFixed(0)}%</span></div>` : ''}
            ${svc.lastError ? `<div class="svc-meta"><span class="svc-label svc-error">Error</span><span class="svc-error">${svc.lastError}</span></div>` : ''}
          </div>
        `;
        card.addEventListener('click', () => toggleServiceCard(card));
        grid.appendChild(card);
      });
    }

    // Mini log
    updateMiniLog(status);
  }

  function toggleServiceCard(card) {
    const body = card.querySelector('.svc-body');
    if (body) {
      body.style.display = body.style.display === 'none' ? '' : 'none';
    }
  }

  function updateMiniLog(status) {
    const body = document.getElementById('miniLogBody');
    if (!body) return;
    const entries = [];
    status.forEach(s => {
      if (s.state === 'FAILED') entries.push({ type: 'error', text: `${s.name} FAILED: ${s.lastError || 'Unknown'}` });
      if (s.state === 'RUNNING') entries.push({ type: 'success', text: `${s.name} running` });
      if (s.state === 'RECOVERING') entries.push({ type: 'warning', text: `${s.name} recovering...` });
    });
    body.innerHTML = entries.slice(-8).reverse().map(e =>
      `<div class="mini-log-entry ${e.type}"><span class="mini-log-dot"></span>${e.text}</div>`
    ).join('');
    if (!entries.length) body.innerHTML = '<div class="mini-log-entry">No recent events</div>';
  }

  async function validateEnv() {
    if (!window.tiannara) { showNotification('Electron API unavailable', 'error'); return; }
    showNotification('Validating environment...', 'info');
    try {
      const result = await window.tiannara.validateEnvironment();
      const passes = result.results.filter(r => r.pass).length;
      const total = result.results.length;
      showNotification(`Environment: ${passes}/${total} checks passed${result.allPass ? '' : ' (warnings)'}`, result.allPass ? 'success' : 'warning');
    } catch (err) {
      showNotification('Validation failed: ' + err.message, 'error');
    }
  }

  async function startBoot(profile) {
    if (!window.tiannara) { showNotification('Electron API unavailable', 'error'); return; }
    showNotification(`Booting with profile: ${profile || 'development'}...`, 'info');
    try {
      const result = await window.tiannara.startBoot(profile || 'development');
      showNotification(result ? 'Boot complete' : 'Boot finished with issues', result ? 'success' : 'warning');
      fetchStatus();
    } catch (err) {
      showNotification('Boot failed: ' + err.message, 'error');
    }
  }

  async function shutdownAll() {
    if (!window.tiannara) { showNotification('Electron API unavailable', 'error'); return; }
    showNotification('Shutting down...', 'info');
    try {
      await window.tiannara.shutdown();
      showNotification('All services stopped', 'success');
      fetchStatus();
    } catch (err) {
      showNotification('Shutdown failed: ' + err.message, 'error');
    }
  }

  async function emergencyStopAll() {
    if (!window.tiannara) { showNotification('Electron API unavailable', 'error'); return; }
    showNotification('EMERGENCY STOP', 'error');
    try {
      await window.tiannara.emergencyStop();
      showNotification('Emergency stop executed', 'error');
      fetchStatus();
    } catch (err) {
      showNotification('Emergency stop failed: ' + err.message, 'error');
    }
  }

  async function safeMode() {
    if (!window.tiannara) { showNotification('Electron API unavailable', 'error'); return; }
    showNotification('Entering safe mode...', 'warning');
    try {
      await window.tiannara.safeMode();
      showNotification('Safe mode activated', 'warning');
      fetchStatus();
    } catch (err) {
      showNotification('Safe mode failed: ' + err.message, 'error');
    }
  }

  async function runDiag() {
    if (!window.tiannara) { showNotification('Electron API unavailable', 'error'); return; }
    showNotification('Running diagnostics...', 'info');
    try {
      const diag = await window.tiannara.runDiagnostics();
      const container = document.getElementById('diagResult');
      if (!container) return;

      let html = `<div class="diag-summary">
        <div class="diag-header">Diagnostic Report — ${new Date(diag.timestamp).toLocaleString()}</div>
        <div class="diag-stats">
          <span class="diag-stat"><span class="diag-stat-label">Profile</span><span>${diag.profile}</span></span>
          <span class="diag-stat"><span class="diag-stat-label">Healthy</span><span class="diag-healthy">${diag.healthy}</span></span>
          <span class="diag-stat"><span class="diag-stat-label">Failed</span><span class="diag-failed">${diag.failed}</span></span>
          <span class="diag-stat"><span class="diag-stat-label">Total</span><span>${diag.total}</span></span>
        </div>
      </div>`;

      html += '<div class="diag-table-wrap"><table class="diag-table"><tr><th>Service</th><th>State</th><th>PID</th><th>Port</th><th>Health</th><th>Restarts</th><th>Error</th></tr>';
      diag.services.forEach(s => {
        html += `<tr class="diag-row-${s.state.toLowerCase()}">
          <td>${s.service}</td><td class="td-state">${s.state}</td>
          <td>${s.pid || '--'}</td>
          <td>${s.port || '--'}</td>
          <td>${s.healthScore != null ? (s.healthScore * 100).toFixed(0) + '%' : '--'}</td>
          <td>${s.restartCount || 0}</td>
          <td class="td-error">${s.lastError || ''}</td>
        </tr>`;
      });
      html += '</table></div>';
      container.innerHTML = html;
      showNotification('Diagnostics complete', 'success');
    } catch (err) {
      showNotification('Diagnostics failed: ' + err.message, 'error');
    }
  }

  async function loadLogs() {
    if (!window.tiannara) return;
    try {
      const logs = await window.tiannara.getLogs(200);
      const container = document.getElementById('logContainer');
      if (!container) return;
      if (!logs || logs.length === 0) {
        container.innerHTML = '<div class="log-placeholder">No log entries yet</div>';
        return;
      }
      container.innerHTML = logs.map(l => {
        let cls = 'log-entry';
        if (l.type === 'error' || l.type === 'critical') cls += ' log-error';
        else if (l.type === 'warning') cls += ' log-warning';
        else if (l.type === 'success') cls += ' log-success';
        else if (l.type === 'highlight') cls += ' log-highlight';
        return `<div class="${cls}"><span class="log-time">${new Date(l.ts).toLocaleTimeString()}</span><span class="log-msg">${escapeHtml(l.msg)}</span></div>`;
      }).join('');
      container.scrollTop = container.scrollHeight;
    } catch (_) {}
  }

  async function saveSnapshot() {
    if (!window.tiannara) { showNotification('Electron API unavailable', 'error'); return; }
    showNotification('Saving snapshot...', 'info');
    try {
      const path = await window.tiannara.saveSnapshot('manual');
      showNotification(`Snapshot saved: ${path}`, 'success');
      loadSnapshots();
    } catch (err) {
      showNotification('Snapshot failed: ' + err.message, 'error');
    }
  }

  async function loadSnapshots() {
    const container = document.getElementById('snapshotGrid');
    if (!container) return;
    container.innerHTML = '<div class="snap-placeholder">Use "Save Snapshot" to create a snapshot</div>';
  }

  async function loadCoaFrame() {
    const frame = document.getElementById('coaFrame');
    if (!frame) return;
    if (window.tiannara) {
      try {
        const p = await window.tiannara.getCoaPath();
        frame.src = p;
      } catch (_) { frame.src = 'http://localhost:4000/coa/index.html'; }
    } else {
      frame.src = 'http://localhost:4000/coa/index.html';
    }
  }

  function showNotification(msg, type) {
    const el = document.getElementById('desktopNotification');
    const textEl = document.getElementById('notificationText');
    if (!el || !textEl) return;
    el.classList.remove('visible', 'success', 'error', 'info', 'warning');
    el.classList.add(type || 'info');
    textEl.textContent = msg;
    requestAnimationFrame(function() { el.classList.add('visible'); });
    if (notificationTimer) clearTimeout(notificationTimer);
    notificationTimer = setTimeout(hideNotification, 4000);
  }

  function hideNotification() {
    const el = document.getElementById('desktopNotification');
    if (el) el.classList.remove('visible');
  }

  function escapeHtml(str) {
    const d = document.createElement('div');
    d.textContent = str;
    return d.innerHTML;
  }

  document.addEventListener('DOMContentLoaded', init);
})();
