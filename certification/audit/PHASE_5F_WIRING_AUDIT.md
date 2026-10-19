# Phase 5F Wiring Audit (P2) — Integration Truth Table

**Date:** 2026-10-19 · **Branch:** `local/pr4` · **Mode:** read-only
**Method:** boot tree read from source; callers found by repo-wide grep of
`*.ex`; status vocabulary from `PHASE_5F_STATUS_CORRECTION.md`
(implemented / tested / wired / production-ready / absent).
Nothing below wires, renames, or deletes anything — integration actions are
listed as *required work* only.

## 0. The real boot tree (what "wired" means here)

`application.ex:21-24` → `StartupSupervisor` (`startup_supervisor.ex:30-42`,
`:rest_for_one`): CPL → Omega (10 leaves) → Observatory → Phoenix Endpoint →
`RootSupervisor` → DiscoveryRunner.

`RootSupervisor.init` (`runtime_layers/supervisors.ex:202-208`), default
profile `:stable`:

| Layer | Children (source) |
|---|---|
| Infrastructure (`:70-77`) | NATS.Supervisor (required), Telemetry (optional) |
| Execution (`:98-100`) | `Tiannara.OPC.CoreSupervisor` (required), `Tiannara.OPC.Supervisor` (optional) |
| Ecology (`:121-125`) | `Tiannara.UniverseSupervisor` (required), **Legacy OLEF FieldSupervisor**, OCM, `Tiannara.RRG.Supervisor` (optional) |
| Constraint (`:150-156`) | IRD, CCR, HSV, ACF (optional), SafetyCortex (required) |
| Meta (`:177-180`) | **only** `Tiannara.MetaSOPL.RateModulationSupervisor` (required) + `Tiannara.Meta.ChronogramMatrix` (optional) — ChronogramMatrix added by W1 (`3690efbd`) |

Application level (`application.ex:28-37`, after StartupSupervisor, W1 `3690efbd`):
`CIS.Supervisor` → `CIS.ExecutionController` → `QuotaGovernor` →
`LineageCompression` → `Causal.GCK` — all `BootPolicy.optional_child`,
dependency-ordered (arbitration kernel before its callers).

Everything not in this table is **unwired** regardless of implementation or
docs. `optional_child` skips missing modules with a warning; `required_child`
raises (`runtime_layers/supervisors.ex:6-21`).

## 1. Integration truth table

| System | Phase | Implem. | Tests | Wired? | Production-ready | Key evidence |
|---|---|---|---|---|---|---|
| ChronogramMatrix | 5F.4 | yes (305 LOC) | 20 (local) | **yes** (W1 `3690efbd`) | no | wired into Meta layer via `optional_child` (`supervisors.ex:178`); real callers: `gck/chronogram_gate.ex:39-49`, `meta/metastability/*` (OCG/OCAL/Resonance/Kernel), `cis/execution_controller.ex:68-83`, `legacy/cis/*`; boot test `test/tiannara/cis/boot_wiring_test.exs` |
| GCK gate | 5F.4 | yes | yes | **NO** (depends on unwired ChronogramMatrix) | no | thresholds 0.92/0.75 real (`gck/chronogram_gate.ex:60,63`); `validate_read/2` always-allow; entropy = map-size placeholder |
| OMRL | 5F.3 | yes (567 LOC) | 23 (local) | **NO** | no | moduledoc claims JetStream publish (`observer_memory_reconciliation.ex:55`) but impl is a stub: `# Would integrate with NATS publisher here` + `Logger.debug` (`:541-556`); defaults all `0.5` (`:67-69`); divergence hardcoded `0.5` (`:506`) |
| OLEF (5F.5 stack) | 5F.5 | yes | partial | **half** | no | **wired:** Legacy `TiannaraRuntime.Legacy.Tiannara.OLEF.FieldSupervisor` via optional_child (`supervisors.ex:123`). **Unwired:** canonical `Tiannara.OLEF.*` reachable only from `Tiannara.P9XEcosystem.Supervisor` (`lib/tiannara/supervisors.ex:164`) which has **zero references** repo-wide; the repo's own TODO at `meta/opc/stabilization/mscl_budget_gate.ex` moduledoc admits 5F.5 "is not wired" (correction banner added in P1b) |
| MSCL (5F.5 set) | 5F.5 | yes (≈310 LOC named set) | yes | **NO** | no | C-02; three same-acronym systems documented in P1b ownership notes |
| OPC | 5F.6 | parsers/validators/OIR yes | ≈117 (local) | **half** | no | **wired:** `OPC.CoreSupervisor` required + `OPC.Supervisor` optional (`supervisors.ex:99-100`). **Unwired/blocked:** `compile_physics/2` zero production callers; main-app facade fail-closes `{:error, :physics_substrate_unavailable}`; execution quarantined `:simulated_execution_quarantined` (P1c `7855aa6d`) |
| RRG (rate-limit graph) | 5F.7/5F.12 | yes (~2k LOC) | 21 | **yes** (optional_child `:125`; `rrg/supervisor.ex:1`) | partial | naming: C-09/C-13 (3 systems share acronym; canonical = Rate-limiting Ontological Graph) |
| Runtime Revelation Governor | 5F.7 | 51 LOC policy | minimal | **NO** | no | `rrg/governor.ex` unsupervised; ownership note added P1b |
| Babel | 5F.11 | yes | 14 (local) | **NO** | no | `encrypt_causal_payload/4` — only definition site in `lib/` (grep `*.ex` = 1 hit), zero production callers; "topological key" = unkeyed SHA-256; claim C-08 |
| CIS safety stack | 5F.3.5 | **restored** | 48+ (local) | **yes** (W1 `3690efbd`) | no | contract restored `f64785df`; boot-wired `3690efbd` as application-level `optional_child` (CIS.Supervisor → ExecutionController → QuotaGovernor → LineageCompression → GCK, dependency order); chain callable/testable/booted; still not production-ready (duplicates remain C-11, ExecutionController delivery path is log-only) |
| OCG/OCAL/OCAL integration | 5F.2 | yes | tests exist (untracked-to-CI on this branch) | **NO** | no | Meta layer starts only MetaSOPL (`supervisors.ex:177-180`); they run only when tests start them |

**Result:** of 11 audited systems, 4 have real boot paths (RRG graph, OPC
supervisors, ChronogramMatrix, CIS safety stack — the latter two via W1
`3690efbd`), 2 are half-wired (OLEF legacy, OPC surface), the rest are
implemented-or-partial but unwired. **None is production-ready** (wired +
verified callers + fail-closed contracts).

## 2. Missing 5F.9 / 5F.10 components — classification

Per operator instruction, each missing component is classified
`absent` / `deferred` / `elsewhere`:

### 5F.9 (RODL + OLEF)
| Claimed component | Classification | Evidence |
|---|---|---|
| `Tiannara.Runtime.RODL.Supervisor` | **absent** | no `defmodule` anywhere (grep) |
| `Tiannara.Runtime.OLEF.GradientSolver` | **absent** (markdown-only) | actual OLEF field math lives under `legacy/olef/` — that is **elsewhere**, but not the claimed module |
| `opc/v3/olef/rodl.ex` | **elsewhere (name collision)** | different system: "Real-time Observer Definition Language" |
| Choice A / AOE | **absent** | zero artifacts; no deferral document found |
| Choice B RODL core (`opc/v3/rodl` delegation) | **elsewhere** | tiny, test-only |

Verdict: 5F.9 is **half absent**; the completion doc's supervision claims
are disproven (C-06).

### 5F.10 (CRA / distributed resilience)
| Claimed component | Classification | Evidence |
|---|---|---|
| `Tiannara.Runtime.CRA.Supervisor` | **absent** | no `defmodule` |
| 5 CRA GenServers (ShutdownIntentDetector, ClusterStressMonitor, …) | **elsewhere** | implemented (~265 LOC), run only in tests — unwired |
| Partition tolerance | **absent** | no artifacts |
| Cross-node authority transfer | **absent** | no artifacts |
| Duplicate decision dedup | **absent** | no artifacts |
| Cross-node snapshot consistency | **absent** | no artifacts |
| Resource budget reconciliation | **absent** | no artifacts |

Verdict: 5F.10's external scope is **absent entirely** (C-07); nothing in
the repo defers it with a design doc — if a deferral decision exists it is
outside this checkout (note: closest artifact `docs/architecture/MARKDOWN_DIRECTORY_AUDIT.md`
classifies 5F6–5F9 as *proposals to defer*).

## 3. Test/CI tracking gap (feeds 5F-P3)

- `Elixir CI` (all pushes) runs the **root** Mix project
  (`.github/workflows/elixir_ci.yml` root `mix test`); the root app does not
  reference `tiannara_runtime`, so **runtime suites do not run on this
  branch's pushes** (CIS contract, quarantine, OPC, OCG… all local-only here).
- `phase_5f2_tests.yml` runs runtime meta tests but only for
  `main|develop` pushes (its `paths:` + `branches:` filters).
- `config/test.exs:42-44` sets `config :tiannara_runtime,
  TiannaraRuntime.Application, start_app: false` — **dead key**: no
  consumer anywhere in `lib/` (grep = 0). Local `mix test` in
  `tiannara_runtime/` therefore boots the full app implicitly, but no
  workflow on this branch verifies that either.
- `tiannara_runtime` filesystem has **166 `.exs` test files vs 39 tracked**
  (§10 of `DIRECTORY_AUDIT_2026-10-19.md`) — most tests are invisible to
  version control and CI.

## 4. Required integration work (NOT performed — needs explicit approval)

Ordering follows the operator's "smallest safe path" rule:

1. **CIS safety stack wiring** (C-10): **DONE (`3690efbd`, operator-approved
   W1)** — 5F.3.5 children restored as application-level
   `BootPolicy.optional_child` in dependency order (CIS.Supervisor →
   ExecutionController → QuotaGovernor → LineageCompression → GCK);
   ChronogramMatrix wired into the Meta layer before its callers;
   `ExecutionController.handle_cast(:reset)` added (parity with the other
   four CIS modules); boot test + fail-closed terminate/restart test.
   CI green (Elixir CI + Cross-Platform) on `3690efbd`. Not
   production-ready: delivery path log-only, duplicates (C-11) remain.
2. **ChronogramMatrix/OMRL/OCG supervision**: add to `Meta.Supervisor`
   (`supervisors.ex:177-180`) via `optional_child`; fix OMRL's NATS stub
   (`observer_memory_reconciliation.ex:541-556`) before any event promise
   is documented again.
3. **OLEF canonical set**: either re-parent `Tiannara.OLEF.*` under a live
   supervisor or declare `P9XEcosystem` retired (deletion needs approval).
4. **Babel**: real key material + a caller before any integration claim.
5. **CI**: run `tiannara_runtime` suites on branch pushes; remove the dead
   `start_app` key or implement it; track-or-prune the 127 untracked test
   files.
