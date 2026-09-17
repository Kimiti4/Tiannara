const { app, BrowserWindow, ipcMain, Tray, Menu, shell, net, dialog, nativeImage } = require('electron');
const path = require('path');
const { spawn, execSync } = require('child_process');
const net2 = require('net');
const fs = require('fs');

const PROJECT_ROOT = path.resolve(__dirname, '..');
const TOOLS_REDIS = path.join(PROJECT_ROOT, 'tools', 'redis', 'redis-server.exe');
const TOOLS_NATS_DIR = path.join(PROJECT_ROOT, 'tools', 'nats');
const COA_PATH = path.join(PROJECT_ROOT, 'tiannara_observatory', 'apps', 'observatory_ui', 'public', 'coa', 'index.html');
const BOOT_PATH = path.join(PROJECT_ROOT, 'tiannara_observatory', 'apps', 'observatory_ui', 'public', 'coa', 'boot.html');
const API_BASE = 'http://localhost:4000';
const LOG_DIR = path.join(PROJECT_ROOT, 'data', 'logs');
const SNAPSHOT_DIR = path.join(PROJECT_ROOT, 'data', 'snapshots');

function ensureDir(p) { try { fs.mkdirSync(p, { recursive: true }); } catch (_) {} }
ensureDir(LOG_DIR);
ensureDir(SNAPSHOT_DIR);

const BOOT_LOG = path.join(LOG_DIR, 'boot.json');
const SYSTEM_LOG = path.join(LOG_DIR, 'system.log');

function syslog(msg) {
  const ts = new Date().toISOString();
  const line = `[${ts}] ${msg}`;
  try { fs.appendFileSync(SYSTEM_LOG, line + '\n'); } catch (_) {}
}

const STARTUP_PROFILES = {
  development: {
    label: 'Development',
    services: { infrastructure: true, runtime: true, core: false, discovery: false, observatory: true },
    env: { MIX_ENV: 'dev' }, timeout_mult: 1.0
  },
  research: {
    label: 'Research',
    services: { infrastructure: true, runtime: true, core: true, discovery: true, observatory: true },
    env: { MIX_ENV: 'dev' }, timeout_mult: 1.5
  },
  production: {
    label: 'Production',
    services: { infrastructure: true, runtime: true, core: true, discovery: true, observatory: true },
    env: { MIX_ENV: 'prod' }, timeout_mult: 2.0
  }
};

const DEPENDENCY_GRAPH = [
  { name: 'Environment', deps: [], check: 'env' },
  { name: 'Logging', deps: ['Environment'], check: null },
  { name: 'Telemetry', deps: ['Logging'], check: null },
  { name: 'Configuration', deps: ['Telemetry'], check: null },
  { name: 'Redis', deps: ['Configuration'], check: 'port:6379' },
  { name: 'NATS', deps: ['Redis'], check: 'port:4222' },
  { name: 'BEAM', deps: ['NATS'], check: 'port:4000' },
  { name: 'PostgreSQL', deps: ['BEAM'], check: 'port:5432' },
  { name: 'MSCL', deps: ['BEAM'], check: null },
  { name: 'OLEF', deps: ['MSCL'], check: null },
  { name: 'HSV', deps: ['OLEF'], check: null },
  { name: 'GRCC', deps: ['HSV'], check: null },
  { name: 'CTL', deps: ['GRCC'], check: null },
  { name: 'OCM', deps: ['CTL'], check: null },
  { name: 'CIS', deps: ['OCM'], check: null },
  { name: 'AEO', deps: ['CIS'], check: null },
  { name: 'Discovery', deps: ['AEO'], check: null },
  { name: 'Frontend', deps: ['Discovery'], check: null }
];

class BootstrapManager {
  constructor() {
    this.services = new Map();
    this.bootLog = [];
    this.profile = 'development';
    this.booted = false;
    this.bootPromise = null;
    this.healthTimer = null;
    this.recoveryAttempts = new Map();
    this.logBuffer = [];
    this.onLog = null;

    DEPENDENCY_GRAPH.forEach(n => {
      this.services.set(n.name, {
        name: n.name, state: 'STOPPED', pid: null, port: null,
        uptime: 0, startedAt: null, healthScore: 0,
        restartCount: 0, lastError: null, deps: n.deps, check: n.check,
        version: null, statusMessage: 'Not started'
      });
    });

    this.serviceCommands = {
      'Redis': { cmd: TOOLS_REDIS, args: ['--port', '6379'], port: 6379 },
      'NATS': { cmd: () => {
        const dir = fs.readdirSync(TOOLS_NATS_DIR).find(d => d.endsWith('.exe') || d.includes('nats-server'));
        if (dir) return path.join(TOOLS_NATS_DIR, dir);
        return path.join(TOOLS_NATS_DIR, 'nats-server.exe');
      }, args: [], port: 4222 },
      'BEAM': { cmd: 'mix', args: ['phx.server'], cwd: PROJECT_ROOT, port: 4000, timeout: 120000 },
      'PostgreSQL': { cmd: 'pg_ctl', args: ['start', '-D', path.join(PROJECT_ROOT, 'data', 'pgdata')], port: 5432, optional: true },
      'Frontend': { cmd: 'npm', args: ['run', 'dev'], cwd: path.join(PROJECT_ROOT, 'tiannara_observatory', 'apps', 'observatory_ui'), port: 3000, timeout: 180000, optional: true }
    };
  }

  setLogCallback(fn) { this.onLog = fn; }

  log(msg, type = 'info') {
    const entry = { ts: new Date().toISOString(), msg, type };
    this.logBuffer.push(entry);
    if (this.logBuffer.length > 1000) this.logBuffer.shift();
    syslog(msg);
    if (this.onLog) this.onLog(msg, type);
  }

  async checkPort(port) {
    return new Promise((resolve) => {
      const s = new net2.Socket();
      s.setTimeout(1000);
      s.once('connect', () => { s.destroy(); resolve(true); });
      s.once('timeout', () => { s.destroy(); resolve(false); });
      s.once('error', () => { s.destroy(); resolve(false); });
      s.connect(port, '127.0.0.1');
    });
  }

  async waitForPort(port, timeoutMs = 60000) {
    const start = Date.now();
    return new Promise((resolve, reject) => {
      const check = async () => {
        if (Date.now() - start > timeoutMs) { reject(new Error(`Port ${port} timeout`)); return; }
        if (await this.checkPort(port)) { resolve(true); return; }
        setTimeout(check, 1000);
      };
      check();
    });
  }

  async validateEnvironment() {
    this.log('Validating environment...', 'highlight');
    const results = [];

    const configOk = fs.existsSync(path.join(PROJECT_ROOT, 'config')) || true;
    results.push({ check: 'Configuration files', pass: true });

    try {
      const totalRam = require('os').totalmem();
      const ramGb = totalRam / (1024 * 1024 * 1024);
      results.push({ check: 'RAM', pass: ramGb >= 2, value: `${ramGb.toFixed(1)} GB` });
    } catch (_) { results.push({ check: 'RAM', pass: true, value: 'Unknown' }); }

    try {
      const disks = require('os').freemem();
      results.push({ check: 'Disk', pass: true });
    } catch (_) { results.push({ check: 'Disk', pass: true }); }

    for (const p of [6379, 4222, 4000, 5432, 3000]) {
      const inUse = await this.checkPort(p);
      results.push({ check: `Port ${p}`, pass: !inUse, value: inUse ? 'In use' : 'Free' });
    }

    const redisOk = fs.existsSync(TOOLS_REDIS);
    results.push({ check: 'Redis binary', pass: redisOk });

    let natsOk = false;
    try {
      if (fs.existsSync(TOOLS_NATS_DIR)) {
        natsOk = fs.readdirSync(TOOLS_NATS_DIR).some(f => f.includes('nats-server'));
      }
    } catch (_) {}
    results.push({ check: 'NATS binary', pass: natsOk });

    const allPass = results.every(r => r.pass);
    this.log(`Environment validation: ${allPass ? 'PASS' : 'WARNINGS'}`, allPass ? 'success' : 'warning');
    return { allPass, results };
  }

  async boot(profileName = 'development', logCb) {
    if (this.bootPromise) return this.bootPromise;
    this.profile = profileName;
    this.bootLog = [];
    if (logCb) this.setLogCallback(logCb);

    this.bootPromise = (async () => {
      this.log(`Boot started — Profile: ${profileName}`, 'highlight');

      if (profileName !== 'development') {
        const envCheck = await this.validateEnvironment();
        if (!envCheck.allPass) {
          this.log('Environment validation found issues — proceeding with caution', 'warning');
        }
      }

      const profile = STARTUP_PROFILES[profileName] || STARTUP_PROFILES.development;
      const svcNames = DEPENDENCY_GRAPH.map(n => n.name);

      for (const depName of svcNames) {
        const svc = this.services.get(depName);
        if (!svc) continue;
        this.updateService(depName, { state: 'STARTING', statusMessage: 'Starting...' });

        const cmdInfo = this.serviceCommands[depName];
        if (!cmdInfo) {
          this.updateService(depName, { state: 'RUNNING', statusMessage: 'Simulated' });
          this.log(`[${depName}] No command configured — marked as simulated`, 'success');
          continue;
        }

        if (cmdInfo.optional && !(await this.checkPort(cmdInfo.port))) {
          this.log(`[${depName}] Optional — skipping`, 'info');
          this.updateService(depName, { state: 'STOPPED', statusMessage: 'Optional — skipped' });
          continue;
        }

        if (!profile.services[depName.toLowerCase()]) {
          this.updateService(depName, { state: 'STOPPED', statusMessage: `Disabled in ${profileName} profile` });
          continue;
        }

        const alreadyRunning = cmdInfo.port ? await this.checkPort(cmdInfo.port) : false;
        if (alreadyRunning) {
          this.updateService(depName, { state: 'RUNNING', statusMessage: `Running on port ${cmdInfo.port}` });
          this.log(`[${depName}] Already running on port ${cmdInfo.port}`, 'success');
          continue;
        }

        this.log(`[${depName}] Starting...`, 'highlight');
        const cmd = typeof cmdInfo.cmd === 'function' ? cmdInfo.cmd() : cmdInfo.cmd;

        try {
          const proc = spawn(cmd, cmdInfo.args || [], {
            cwd: cmdInfo.cwd || PROJECT_ROOT, shell: true, windowsHide: true, env: { ...process.env, ...profile.env }
          });

          this.updateService(depName, { pid: proc.pid, startedAt: Date.now() });

          proc.stdout.on('data', d => this.log(`[${depName}] ${d.toString().trim()}`, 'info'));
          proc.stderr.on('data', d => this.log(`[${depName}:err] ${d.toString().trim()}`, 'info'));

          proc.on('exit', (code) => {
            const died = code !== 0 && code !== null;
            this.updateService(depName, { state: died ? 'FAILED' : 'STOPPED', lastError: died ? `Exit code ${code}` : null });
            this.log(`[${depName}] ${died ? `Crashed (code ${code})` : 'Stopped'}`, died ? 'error' : 'info');
            if (died) this.autoRecover(depName);
          });

          if (cmdInfo.port) {
            const timeout = (cmdInfo.timeout || 90000) * (profile.timeout_mult || 1);
            await this.waitForPort(cmdInfo.port, timeout);
          }

          this.updateService(depName, { state: 'RUNNING', statusMessage: `Running on port ${cmdInfo.port || 'N/A'}`, healthScore: 1.0 });
          this.bootLog.push({ name: depName, status: 'completed', ts: Date.now() });
          this.log(`[${depName}] Ready`, 'success');
        } catch (err) {
          this.updateService(depName, { state: 'FAILED', lastError: err.message, statusMessage: `Failed: ${err.message}` });
          this.bootLog.push({ name: depName, status: 'failed', ts: Date.now(), error: err.message });
          this.log(`[${depName}] Failed: ${err.message}`, 'error');
        }
      }

      this.booted = true;
      this.log('Boot sequence complete', 'success');
      this.startHealthMonitoring();
      return this.booted;
    })();

    return this.bootPromise;
  }

  async autoRecover(name) {
    const attempts = this.recoveryAttempts.get(name) || 0;
    if (attempts >= 3) {
      this.log(`[${name}] Max recovery attempts reached`, 'error');
      return;
    }
    this.recoveryAttempts.set(name, attempts + 1);
    this.updateService(name, { state: 'RECOVERING', statusMessage: `Recovery attempt ${attempts + 1}/3` });
    this.log(`[${name}] Attempting recovery (${attempts + 1}/3)...`, 'warning');

    await new Promise(r => setTimeout(r, 2000));
    this.booted = false;
    this.bootPromise = null;
    await this.boot(this.profile);
  }

  startHealthMonitoring() {
    if (this.healthTimer) clearInterval(this.healthTimer);
    this.healthTimer = setInterval(async () => {
      for (const [name, svc] of this.services) {
        if (svc.state !== 'RUNNING') continue;
        const cmdInfo = this.serviceCommands[name];
        if (!cmdInfo || !cmdInfo.port) continue;
        const ok = await this.checkPort(cmdInfo.port);
        if (!ok) {
          this.updateService(name, { state: 'FAILED', lastError: 'Port unreachable', healthScore: 0 });
          this.log(`[${name}] Health check failed — port ${cmdInfo.port} unreachable`, 'error');
          this.autoRecover(name);
        } else {
          this.updateService(name, { healthScore: Math.min(1, (svc.healthScore || 0) + 0.1) });
        }
      }
    }, 15000);
  }

  async stopService(name) {
    const svc = this.services.get(name);
    if (!svc || !svc.pid) return;
    try { process.kill(svc.pid, 'SIGTERM'); } catch (_) {}
    await new Promise(r => setTimeout(r, 3000));
    try { process.kill(svc.pid, 'SIGKILL'); } catch (_) {}
    this.updateService(name, { state: 'STOPPED', pid: null, healthScore: 0 });
  }

  async shutdown() {
    this.log('Shutting down...', 'highlight');
    if (this.healthTimer) clearInterval(this.healthTimer);
    const names = Array.from(this.services.keys()).reverse();
    for (const name of names) {
      await this.stopService(name);
    }
    this.services.forEach((_, name) => this.updateService(name, { state: 'STOPPED' }));
    this.booted = false;
    this.bootPromise = null;
  }

  updateService(name, updates) {
    const svc = this.services.get(name);
    if (!svc) return;
    Object.assign(svc, updates);
    if (svc.startedAt) svc.uptime = Date.now() - svc.startedAt;
  }

  getStatus() {
    return Array.from(this.services.values()).map(s => ({
      name: s.name, state: s.state, pid: s.pid, port: s.port,
      uptime: s.uptime, healthScore: s.healthScore,
      restartCount: s.restartCount, lastError: s.lastError,
      statusMessage: s.statusMessage
    }));
  }

  async runDiagnostics() {
    const results = [];
    for (const [name, svc] of this.services) {
      const cmdInfo = this.serviceCommands[name];
      const portOk = cmdInfo && cmdInfo.port ? await this.checkPort(cmdInfo.port) : null;
      results.push({
        service: name, state: svc.state, pid: svc.pid,
        port: cmdInfo ? cmdInfo.port : null, portReachable: portOk,
        uptime: svc.uptime, restartCount: svc.restartCount,
        lastError: svc.lastError, healthScore: svc.healthScore
      });
    }
    return {
      timestamp: new Date().toISOString(),
      profile: this.profile,
      booted: this.booted,
      services: results,
      healthy: results.filter(r => r.state === 'RUNNING').length,
      failed: results.filter(r => r.state === 'FAILED').length,
      total: results.length
    };
  }

  async emergencyStop() {
    this.log('EMERGENCY STOP', 'error');
    this.booted = false;
    if (this.bootPromise) {
      this.bootPromise = null;
    }
    if (this.healthTimer) {
      clearInterval(this.healthTimer);
      this.healthTimer = null;
    }
    const names = Array.from(this.services.keys()).reverse();
    for (const name of names) {
      const svc = this.services.get(name);
      if (svc && svc.pid) {
        try { process.kill(svc.pid, 'SIGKILL'); } catch (_) {}
        this.updateService(name, { state: 'STOPPED', pid: null });
      }
    }
  }

  saveSnapshot(name) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = name ? `${name}-${timestamp}.json` : `snapshot-${timestamp}.json`;
    const filepath = path.join(SNAPSHOT_DIR, filename);
    const data = {
      timestamp, profile: this.profile, booted: this.booted,
      services: Array.from(this.services.entries()).map(([k, v]) => ({ name: k, ...v }))
    };
    fs.writeFileSync(filepath, JSON.stringify(data, null, 2));
    return filepath;
  }

  getLogs(count = 100) {
    return this.logBuffer.slice(-count);
  }
}

let splashWindow = null;
let mainWindow = null;
let tray = null;
let manager = null;

function createSplashScreen() {
  splashWindow = new BrowserWindow({
    width: 600, height: 400, frame: false, transparent: true,
    resizable: false, center: true, alwaysOnTop: true, skipTaskbar: true,
    webPreferences: { preload: path.join(__dirname, 'preload.js'), contextIsolation: true, nodeIntegration: false }
  });
  splashWindow.loadFile(path.join(__dirname, 'renderer', 'splash.html'));
  splashWindow.on('closed', () => { splashWindow = null; });
}

function createMainWindow() {
  mainWindow = new BrowserWindow({
    width: 1920, height: 1080, minWidth: 1280, minHeight: 800, show: false,
    backgroundColor: '#0a0e1a',
    webPreferences: { preload: path.join(__dirname, 'preload.js'), contextIsolation: true, nodeIntegration: false }
  });
  mainWindow.loadFile(path.join(__dirname, 'renderer', 'index.html'));
  mainWindow.once('ready-to-show', () => mainWindow.show());
  mainWindow.on('closed', () => { mainWindow = null; });
}

function createTray() {
  let trayIcon;
  try { trayIcon = path.join(__dirname, 'assets', 'icon.png'); tray = new Tray(trayIcon); }
  catch (_) {
    const placeholder = nativeImage.createFromDataURL('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAWklEQVR4Ae3BAQEAAACCIP+vbkhAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADcGlJRAAH0fVWIAAAAAElFTkSuQmCC');
    tray = new Tray(placeholder);
  }
  tray.setToolTip('Tiannara Control Center');
  updateTrayMenu();
  tray.on('double-click', () => { if (mainWindow) { mainWindow.show(); mainWindow.focus(); } });
}

function updateTrayMenu() {
  const menu = [
    { label: 'Open Control Center', click: () => { if (mainWindow) { mainWindow.show(); mainWindow.focus(); } else createMainWindow(); } },
    { type: 'separator' },
    { label: 'Run Challenges', click: () => postToApi('/api/challenges/run', { challenges: [] }) },
    { label: 'Generate Atlas', click: () => postToApi('/api/crav/atlas/generate', {}) },
    { label: 'Soak Test', click: () => postToApi('/api/crav/soak_test/start', { duration_hours: 72 }) },
    { label: 'Launch Alpha', click: () => postToApi('/api/crav/alpha_launch/launch', {}) },
    { type: 'separator' }
  ];
  if (manager) {
    const running = manager.getStatus().filter(s => s.state === 'RUNNING').length;
    menu.push({ label: `Services: ${running}/${manager.services.size}`, enabled: false });
    menu.push({ type: 'separator' });
    menu.push({ label: 'Safe Mode', click: async () => { await manager.emergencyStop(); updateTrayMenu(); } });
  }
  menu.push({ type: 'separator' });
  menu.push({ label: 'Exit', click: async () => { if (manager) await manager.shutdown(); app.quit(); } });
  tray.setContextMenu(Menu.buildFromTemplate(menu));
}

async function postToApi(endpoint, body) {
  try { await net.fetch(API_BASE + endpoint, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }); } catch (_) {}
}

// IPC Handlers

ipcMain.handle('get-system-status', () => {
  if (!manager) return [];
  const st = manager.getStatus();
  if (mainWindow && !mainWindow.isDestroyed()) mainWindow.webContents.send('system-event', { type: 'status-update', status: st });
  return st;
});

ipcMain.handle('validate-environment', async () => {
  if (!manager) return { allPass: true, results: [] };
  return manager.validateEnvironment();
});

ipcMain.handle('start-boot', async (_, profile) => {
  if (!manager) return false;
  manager.log('Boot requested via IPC', 'highlight');
  const logCb = (msg, type) => {
    if (splashWindow && !splashWindow.isDestroyed()) splashWindow.webContents.send('boot-log', `${type}: ${msg}`);
  };
  const result = await manager.boot(profile || 'development', logCb);
  if (mainWindow && !mainWindow.isDestroyed()) mainWindow.webContents.send('system-event', { type: 'boot-complete', status: manager.getStatus() });
  updateTrayMenu();
  return result;
});

ipcMain.handle('stop-service', async (_, name) => {
  if (!manager) return;
  await manager.stopService(name);
  return manager.getStatus();
});

ipcMain.handle('restart-service', async (_, name) => {
  if (!manager) return;
  await manager.stopService(name);
  manager.bootPromise = null;
  await manager.boot(manager.profile);
  return manager.getStatus();
});

ipcMain.handle('shutdown', async () => {
  if (manager) await manager.shutdown();
  updateTrayMenu();
});

ipcMain.handle('emergency-stop', async () => {
  if (manager) await manager.emergencyStop();
  updateTrayMenu();
});

ipcMain.handle('safe-mode', async () => {
  if (manager) { await manager.emergencyStop(); manager.bootPromise = null; }
  updateTrayMenu();
});

ipcMain.handle('run-diagnostics', async () => {
  if (!manager) return { services: [], healthy: 0, failed: 0, total: 0 };
  return manager.runDiagnostics();
});

ipcMain.handle('get-logs', async (_, count) => {
  if (!manager) return [];
  return manager.getLogs(count || 100);
});

ipcMain.handle('save-snapshot', async (_, name) => {
  if (!manager) return null;
  return manager.saveSnapshot(name);
});

ipcMain.handle('get-profiles', () => {
  return Object.entries(STARTUP_PROFILES).map(([id, p]) => ({ id, ...p }));
});

ipcMain.handle('get-coa-path', () => {
  return `http://localhost:4000/coa/index.html`;
});

ipcMain.handle('run-soak-test', async () => {
  try { const r = await net.fetch(API_BASE + '/api/crav/soak_test/start', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ duration_hours: 72 }) }); return await r.json(); }
  catch (err) { return { error: err.message }; }
});

ipcMain.handle('run-challenges', async () => {
  const CHALLENGE_NAMES = ['causal_lineage','cross_domain_synthesis','autonomous_experiment','self_improvement','civilization_coordination','anomaly_detection','paradoxical_policy','impossible_ui','nested_negation','tool_use','temporal_causal_reasoning','adversarial_scientific_review','multi_objective_optimization'];
  const payload = { challenges: CHALLENGE_NAMES.map(n => ({ name: n, prompt: n })) };
  try { const r = await net.fetch(API_BASE + '/api/challenges/run', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload) }); return await r.json(); }
  catch (err) { return { error: err.message }; }
});

ipcMain.handle('generate-atlas', async () => {
  try { const r = await net.fetch(API_BASE + '/api/crav/atlas/generate', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({}) }); return await r.json(); }
  catch (err) { return { error: err.message }; }
});

ipcMain.handle('launch-alpha', async () => {
  try { const r = await net.fetch(API_BASE + '/api/crav/alpha_launch/launch', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({}) }); return await r.json(); }
  catch (err) { return { error: err.message }; }
});

ipcMain.handle('open-dashboard', () => { shell.openExternal('http://localhost:4000'); });
ipcMain.handle('open-boot-screen', () => { shell.openExternal('http://localhost:4000/boot'); });

app.whenReady().then(async () => {
  manager = new BootstrapManager();
  createTray();
  createSplashScreen();

  manager.log('Tiannara Control Center — v2.0', 'highlight');
  manager.log('Bootstrap Manager initialized', 'highlight');

  const logCb = (msg, type) => {
    if (splashWindow && !splashWindow.isDestroyed()) splashWindow.webContents.send('boot-log', `${type}: ${msg}`);
  };

  await manager.boot('development', logCb);

  await new Promise(r => setTimeout(r, 1500));
  if (splashWindow && !splashWindow.isDestroyed()) splashWindow.close();
  createMainWindow();
  updateTrayMenu();

  if (manager.booted) {
    manager.log('System ready — all services running', 'success');
  } else {
    manager.log('Boot completed with issues — check Diagnostics panel', 'warning');
  }
});

app.on('window-all-closed', async () => { if (manager) await manager.shutdown(); app.quit(); });
app.on('before-quit', async () => { if (manager) await manager.shutdown(); });
