# ASC-AE-009 VERDICT — DiscoveryMetrics Lifecycle Investigation (F13)

**Date:** 2026-08-21T04:45Z
**Mission:** ASC-AE-009
**Verdict:** **A — REQUIRED** (remediation authorized)

## Phase A — Failure Mechanics (discovered, not hardcoded)

**Start:** `Tiannara.Discovery.DiscoverySupervisor.start_link([])` after canonical boot:

```
** (EXIT) already started: #PID<0.454.0>
  shutdown: failed to start child: Tiannara.Discovery.DiscoveryEngine
```

**State:**
- `DiscoverySupervisor` whereis `nil` (failed to start, degraded)
- `DiscoveryEngine` whereis `#PID<0.454.0>` alive (already running)
- `DiscoveryScheduler` whereis alive
- `DiscoveryMetrics` whereis `nil` (never started because parent failed)
- `sup_children` for `DiscoverySupervisor` = `[]` (supervisor dead, no children)
- `Health` = `{:degraded, [:discovery_metrics]}` (true EOS output)

**Restart:** Not applicable — supervisor never successfully started, so no restart intensity to check. Manual `start_link` reproduces the same `already_started` failure.

## Phase B — Dependency & Ordering

**Metrics init dependencies:** None (pure state map, no DETS, no service calls). Not a dependency failure.

**Boot order:**
- `ControlCenter` `@subsystems` includes `{DiscoveryEngine, :discovery_engine}` and `{DiscoveryScheduler, :discovery_scheduler}` as standalone children (lines 33-34 of `control_center.ex`)
- `DiscoverySupervisor` (CEL service `discovery_supervisor`) also lists `DiscoveryEngine` as its first child

**Recent-change impact:** AE-004/AE-007 did not alter these, but AE-007's addition of CIS made the boot more observable; the duplicate ownership was pre-existing and was masked by the global F9 false emergency.

**Ordering defect:** `ControlCenter` boots first (as a top-level `Tiannara.Application` child), starts `DiscoveryEngine`/`Scheduler`. Later, `DiscoverySupervisor` (via `Tiannara.CEL.Kernel` ServiceRegistry boot) tries to start the same named processes and fails.

## Phase C — Intent Discovery

**Design intent evidence:**
- `DiscoverySupervisor` moduledoc: Owns `Engine`, `Scheduler`, `Metrics` as its three children (lines 11-13 of `discovery_supervisor.ex`)
- `ServiceRegistry` `discovery_supervisor` spec: `criticality: :medium, depends_on: [:executive_memory, :executive_service_bus]` — the *supervisor* is the CEL service, not the individual engines
- `ControlCenter` `@subsystems` list: Treats `DiscoveryEngine`/`Scheduler` as standalone subsystems, duplicate to the supervisor's children

**Consumer analysis:**
- `DiscoveryScheduler` actively calls `DiscoveryEngine.create_discovery` and `route_evidence` (lines 147-157 of `discovery_scheduler.ex`)
- `DiscoveryMetrics` is consumed by nothing critical for discovery progress — `Engine`/`Scheduler` are functional without it (Step1 showed `functional: true` for engine/scheduler)
- Health contract `[:degraded, [:discovery_metrics]]` penalizes Metrics absence, but **no component hard-depends on Metrics output** — Metrics is telemetry/observability for the discovery pipeline, not a blocking dependency

**Evidence matrix:**
- Design says supervisor should own all three → **REQUIRED for supervisor integrity**
- No hard consumer for Metrics output → **Metrics itself is OPTIONAL for core discovery, but supervisor must still start**
- The duplicate ownership of Engine/Scheduler is the *cause* of the supervisor's failure, which then prevents Metrics from starting

**Verdict rules:**
- **A — REQUIRED:** The supervisor must own Engine/Scheduler/Metrics as a unit; the duplicate standalone ownership in `ControlCenter` is the defect. **Remediate by removing the duplicate.**
- **B — OPTIONAL** is rejected: Choosing "Metrics is optional, so remove it from health" would be convenience, not intent. The health contract correctly reflects that Metrics belongs in the supervisor, but the supervisor cannot start due to duplicate ownership — fixing ownership fixes Metrics.
- **C — INSUFFICIENT_EVIDENCE** is rejected: Intent is clear from both supervisor definition and the duplicate list.

## Verdict

**Hypothesis discriminated:** **H1 — Duplicate Ownership**

**Remedy authorized:** **Topology fix (single owner)**

**Next mission:** `ASC-AE-010` — Remove `DiscoveryEngine` and `DiscoveryScheduler` from `ControlCenter` `@subsystems` (lines 33-34), leaving `DiscoverySupervisor` as the single owner. Preserve `DiscoveryMetrics` as a child of the supervisor. Verify that after the fix:
- `DiscoverySupervisor` starts successfully (`whereis` alive)
- `Engine`, `Scheduler`, `Metrics` all alive under the supervisor
- `health` → `:healthy` (no longer degraded)
- No regression in F12/F9/F10/F11

**No adoption artifact for this investigation** — this verdict is read-only. Remediation requires separate `ASC-AE-010` authorization and adoption.

## Regression Guard

Any remediation candidate that makes a genuinely-degraded Discovery report healthy without fixing the duplicate ownership is **REJECTED**.
