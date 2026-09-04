param(
  [switch]$NoDashboard,
  [switch]$NoBrowser
)

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$RuntimeDir = Join-Path $Root "tiannara_runtime"
$DashboardDir = Join-Path $Root "tiannara_internal_dashboard"
$LogDir = Join-Path $Root "logs"

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Tiannara Discovery Challenge — Stage Alpha" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ── Kill anything on our ports ────────────────────────────────
Write-Host "→ Cleaning up ports..." -ForegroundColor Yellow
Get-NetTCPConnection -LocalPort 8004 -ErrorAction SilentlyContinue | ForEach-Object {
  Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
}
Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | ForEach-Object {
  Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

# ── Compile runtime ───────────────────────────────────────────
Write-Host "→ Compiling runtime..." -ForegroundColor Yellow
Set-Location $RuntimeDir
mix compile 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "✖ Compilation failed. Run 'mix compile' in tiannara_runtime/ to debug." -ForegroundColor Red
  exit 1
}
Write-Host "  ✓ Compiled" -ForegroundColor Green

# ── Start runtime (background) ────────────────────────────────
Write-Host "→ Starting runtime (port 8004)..." -ForegroundColor Yellow
$RuntimeLog = Join-Path $LogDir "runtime.log"
$runtimeJob = Start-Job -ScriptBlock {
  param($dir, $log)
  Set-Location $dir
  mix run --no-halt *>&1 | Out-File $log -Encoding utf8
} -ArgumentList $RuntimeDir, $RuntimeLog

# Wait for runtime to be ready
$ready = $false
for ($i = 0; $i -lt 60; $i++) {
  Start-Sleep -Seconds 2
  try {
    $r = Invoke-WebRequest -Uri "http://localhost:8004/api/v1/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
    if ($r.StatusCode -eq 200) {
      $ready = $true
      break
    }
  } catch {}
}
if (-not $ready) {
  Write-Host "  ✖ Runtime failed to start within 120s. Check logs\runtime.log" -ForegroundColor Red
  exit 1
}
Write-Host "  ✓ Runtime ready (all systems healthy)" -ForegroundColor Green

# ── Start dashboard ───────────────────────────────────────────
if (-not $NoDashboard) {
  Write-Host "→ Starting dashboard (port 3000)..." -ForegroundColor Yellow
  $DashboardLog = Join-Path $LogDir "dashboard.log"
  $dashJob = Start-Job -ScriptBlock {
    param($dir, $log)
    Set-Location $dir
    npm run dev *>&1 | Out-File $log -Encoding utf8
  } -ArgumentList $DashboardDir, $DashboardLog

  # Wait for dashboard
  $dashReady = $false
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Seconds 2
    try {
      $r = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
      if ($r.StatusCode -eq 200) {
        $dashReady = $true
        break
      }
    } catch {}
  }
  if ($dashReady) {
    Write-Host "  ✓ Dashboard ready" -ForegroundColor Green
    if (-not $NoBrowser) {
      Start-Process "http://localhost:3000/observatory"
    }
  } else {
    Write-Host "  ⚠ Dashboard may still be starting. Check logs\dashboard.log" -ForegroundColor Yellow
  }
}

# ── Show status ───────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Tiannara Alpha — RUNNING" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Runtime API:  http://localhost:8004/api/v1/health"
if (-not $NoDashboard) {
  Write-Host "  Dashboard:    http://localhost:3000/observatory"
}
Write-Host "  Logs:         $LogDir"
Write-Host ""

# Show system status
try {
  $status = Invoke-RestMethod -Uri "http://localhost:8004/api/v1/system/status" -ErrorAction Stop
  Write-Host "  Systems:" -ForegroundColor White
  $status.systems.PSObject.Properties | ForEach-Object {
    $icon = if ($_.Value) { "✓" } else { "✖" }
    $color = if ($_.Value) { "Green" } else { "Red" }
    Write-Host "    $icon $($_.Name)" -ForegroundColor $color
  }

  $metrics_count = ($status.metrics.PSObject.Properties | Measure-Object).Count
  if ($metrics_count -gt 0) {
    Write-Host "  Metrics categories: $metrics_count" -ForegroundColor White
  }
} catch {
  Write-Host "  ⚠ Could not fetch status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Press Ctrl+C to stop all processes" -ForegroundColor DarkGray

# Keep script alive
while ($true) {
  Start-Sleep -Seconds 10
  # Check processes are alive
  $runtimeAlive = $runtimeJob.State -eq "Running"
  if (-not $runtimeAlive) {
    Write-Host "  ✖ Runtime stopped unexpectedly. Check logs\runtime.log" -ForegroundColor Red
    break
  }
}
