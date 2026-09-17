const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('tiannara', {
  // Status & bootstrap
  getSystemStatus: () => ipcRenderer.invoke('get-system-status'),
  validateEnvironment: () => ipcRenderer.invoke('validate-environment'),
  startBoot: (profile) => ipcRenderer.invoke('start-boot', profile),
  getProfiles: () => ipcRenderer.invoke('get-profiles'),

  // Service management
  stopService: (name) => ipcRenderer.invoke('stop-service', name),
  restartService: (name) => ipcRenderer.invoke('restart-service', name),
  shutdown: () => ipcRenderer.invoke('shutdown'),
  emergencyStop: () => ipcRenderer.invoke('emergency-stop'),
  safeMode: () => ipcRenderer.invoke('safe-mode'),

  // Diagnostics & logs
  runDiagnostics: () => ipcRenderer.invoke('run-diagnostics'),
  getLogs: (count) => ipcRenderer.invoke('get-logs', count),
  saveSnapshot: (name) => ipcRenderer.invoke('save-snapshot', name),

  // Operations
  runSoakTest: () => ipcRenderer.invoke('run-soak-test'),
  runChallenges: () => ipcRenderer.invoke('run-challenges'),
  generateAtlas: () => ipcRenderer.invoke('generate-atlas'),
  launchAlpha: () => ipcRenderer.invoke('launch-alpha'),

  // Navigation
  openDashboard: () => ipcRenderer.invoke('open-dashboard'),
  openBootScreen: () => ipcRenderer.invoke('open-boot-screen'),
  getCoaPath: () => ipcRenderer.invoke('get-coa-path'),

  // Events
  onBootLog: (callback) => ipcRenderer.on('boot-log', (_, msg) => callback(msg)),
  onSystemEvent: (callback) => ipcRenderer.on('system-event', (_, event) => callback(event))
});
