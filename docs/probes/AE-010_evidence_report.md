# AE-010 Evidence Report — Discovery Ownership Remediation (F13)

Date: 2026-08-21T05:30Z

## 1. Authorization
- Mission: `ASC-AE-010` — Remove duplicate ownership of DiscoveryEngine and DiscoveryScheduler from ControlCenter, leaving DiscoverySupervisor as the sole owner of its three children (Engine, Scheduler, Metrics). Verify the intended topology is actually running, not merely that EOS reports healthy.
- Status: `AUTHORIZED`; operator `schtickman`

## 2. Phase A — Characterization (duplicate ownership)

```json
{
  "cc_has_engine": true,
  "disc_has_engine": false,
  "disc_sup_pid": false,
  "discovery_state": "degraded",
  "duplicate_ownership": false,
  "engine_pid": true,
  "eos_status": "degraded",
  "failed_critical": [],
  "metrics_pid": false,
  "owner_count_engine": 1
}
```

- `ControlCenter` has `DiscoveryEngine` as standalone child
- `DiscoverySupervisor` is `degraded` (not running) because its child `DiscoveryEngine` is already running elsewhere (`already_started`)
- `Metrics` never starts because parent supervisor fails

## 3. Phase B — Candidate (single owner)

```json
{
  "cc_has_engine": false,
  "cc_has_scheduler": false,
  "disc_has_engine": true,
  "disc_has_metrics": true,
  "disc_has_scheduler": true,
  "disc_health": "healthy",
  "disc_sup_pid": true,
  "eos_status": "ready",
  "failed_critical": [],
  "runtime_state": "operational",
  "gates": {
    "c2_cis": true,
    "eos_no_critical": true,
    "grounded": true,
    "health_healthy": true,
    "metrics_alive": true,
    "ownership_engine": true,
    "ownership_scheduler": true,
    "regression_em": true,
    "regression_es": true,
    "runtime_no_emergency": true,
    "supervisor_alive": true
  },
  "overall_pass": true
}
```

- After removing the two entries from `ControlCenter.@subsystems`, `DiscoverySupervisor` starts successfully with all three children
- `disc_health` → `healthy` (was `degraded`)
- `eos_status` `degraded` → `ready`, `runtime_state` `recovery` → `operational`, `failed_critical []` (clean)
- All 11 gates PASS

## 4. Verdict
- **PASS** — all gates ownership_engine, ownership_scheduler, supervisor_alive, metrics_alive, health_healthy, eos_no_critical, runtime_no_emergency, regression_es, regression_em, c2_cis, grounded
- EOS `degraded` -> `ready` (ready is clean)
- Discovery `degraded` -> `healthy`

## 5. Adoption Status
- NOT EXECUTED (requires ASC-AE-010-ADOPTION.human.yaml) — in-memory only via Code.compile_string
