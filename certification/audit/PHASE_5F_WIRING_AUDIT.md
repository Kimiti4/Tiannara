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
| Infrastructure (`:70-81`) | NATS.Supervisor (required), Telemetry (optional) + `Tiannara.EventRegistry` duplicate-key Registry for `Tiannara.EventBus` (W3 `9307d6ed`) |
| Execution (`:98-100`) | `Tiannara.OPC.CoreSupervisor` (required), `Tiannara.OPC.Supervisor` (optional) |
| Ecology (`:125-135`) | `Tiannara.UniverseSupervisor` (required), **Legacy OLEF FieldSupervisor**, **canonical `Tiannara.OLEF.Supervisor` (PressureSolver + GradientRouter — W3 `9307d6ed`)**, OCM, `Tiannara.RRG.Supervisor` (optional) |
| Constraint (`:150-156`) | IRD, CCR, HSV, ACF (optional), SafetyCortex (required) |
| Meta (`:177-195`) | `Tiannara.MetaSOPL.RateModulationSupervisor` (required) + `Tiannara.Meta.ChronogramMatrix` (optional) — W1 (`3690efbd`) — then 6 optional children added by W2 (`07971bf9`) in dependency order: `NATS.MetaEvolutionStreamManager`, `Tiannara.Meta.MSCL` (5F.1), `TiannaraRuntime.MCK`, `Tiannara.Meta.ObserverArbitrationLayer` (OCAL), `Tiannara.Meta.ObserverCollapseGovernor` (OCG), `Tiannara.Meta.ObserverMemoryReconciliation` (OMRL) |

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
| GCK gate | 5F.4 | yes | yes | **yes via booted callers** (W1 `3690efbd`) | no | plain function module; callers now booted: `cis/execution_controller.ex:72` (W1 application-level child) and legacy CIS (Ecology layer); ChronogramMatrix data dependency booted (W1) — previous "depends on unwired ChronogramMatrix" reason retired; thresholds 0.92/0.75 real (`gck/chronogram_gate.ex:60,63`); `validate_read/2` always-allow; entropy = map-size placeholder |
| OMRL | 5F.3 | yes (567 LOC) | 23 (local) + 1 boot test | **yes** (W2 `07971bf9`) | no | wired as Meta-layer `optional_child` (last — calls OCG/MSCL); NATS stub **fixed**: publishes via `MetaEvolutionStreamManager` → local Bus (`observer_memory_reconciliation.ex`, `publish_reconciliation_event`); hydration bugs fixed: alias `Tiannara.Meta.MCK` (nonexistent) → `Tiannara.Meta.MSCL`, `hydrate_oss` now `OCG.get_score/1`, both `catch :exit`; remaining: defaults all `0.5` (`:67-69`), divergence hardcoded `0.5` (`:506`) |
| OLEF (5F.5 stack) | 5F.5 | yes | partial + `test/tiannara/olef/boot_wiring_w3_test.exs` | **yes** (W3 `9307d6ed`) | no | **wired:** Legacy `TiannaraRuntime.Legacy.Tiannara.OLEF.FieldSupervisor` (Ecology, pre-W3) and canonical `Tiannara.OLEF.Supervisor` → PressureSolver + GradientRouter re-parented into the Ecology layer (W3 `9307d6ed`, non-destructive — `Tiannara.P9XEcosystem.Supervisor` left in place, still unwired/zero-referenced); prerequisite `Tiannara.EventRegistry` (EventBus backing) added to Infrastructure; canonical `Tiannara.OLEF.FieldSupervisor`/`DiffusionModel`/`NodeRegistry` remain on-demand library modules (were never P9XEcosystem children); the 5F.5 `Tiannara.MSCL.*` set under P9XEcosystem is still unwired (separate row) |
| MSCL (5F.5 set) | 5F.5 | yes (≈310 LOC named set) | yes | **NO** | no | C-02; three same-acronym systems documented in P1b ownership notes |
| OPC | 5F.6 | parsers/validators/OIR yes | ≈117 (local) | **half** | no | **wired:** `OPC.CoreSupervisor` required + `OPC.Supervisor` optional (`supervisors.ex:99-100`). **Unwired/blocked:** `compile_physics/2` zero production callers; main-app facade fail-closes `{:error, :physics_substrate_unavailable}`; execution quarantined `:simulated_execution_quarantined` (P1c `7855aa6d`) |
| RRG (rate-limit graph) | 5F.7/5F.12 | yes (~2k LOC) | 21 | **yes** (optional_child `:125`; `rrg/supervisor.ex:1`) | partial | naming: C-09/C-13 (3 systems share acronym; canonical = Rate-limiting Ontological Graph) |
| Runtime Revelation Governor | 5F.7 | 51 LOC policy | minimal | **NO** | no | `rrg/governor.ex` unsupervised; ownership note added P1b |
| Babel | 5F.11 | yes | 14 (local) | **NO** | no | `encrypt_causal_payload/4` — only definition site in `lib/` (grep `*.ex` = 1 hit), zero production callers; "topological key" = unkeyed SHA-256; claim C-08 |
| CIS safety stack | 5F.3.5 | **restored** | 48+ (local) | **yes** (W1 `3690efbd`) | no | contract restored `f64785df`; boot-wired `3690efbd` as application-level `optional_child` (CIS.Supervisor → ExecutionController → QuotaGovernor → LineageCompression → GCK, dependency order); chain callable/testable/booted; still not production-ready (duplicates remain C-11, ExecutionController delivery path is log-only) |
| OCG/OCAL/OMRL integration | 5F.2/5F.3 | yes | tests exist + `test/tiannara/meta/boot_wiring_w2_test.exs` | **yes** (W2 `07971bf9`) | no | wired as Meta-layer `optional_child` in dependency order (MSCL → MCK → OCAL → OCG → OMRL, after MetaEvolutionStreamManager); OCG gained `get_score/1` (was missing — compile warning); `hydrate_msf` `rescue` → `catch :exit` (GenServer.call to absent process exits); `MetaEvolutionStreamManager.publish` crash fixed (`Jason.encode!` → `Jason.encode` + logged drop; tuple payloads previously killed the GenServer and cascaded the one_for_one Meta supervisor mid-test). Note: `Tiannara.Meta.Supervisor` (`meta/supervisor.ex`) remains an orphan — wiring went through `TiannaraRuntime.Meta.Supervisor` (§4's smallest-safe-path) instead |

**Result:** of 11 audited systems, 7 have real boot paths (RRG graph, OPC
supervisors, ChronogramMatrix + CIS safety stack + GCK gate callers via W1
`3690efbd`, OMRL + OCG/OCAL observer stack via W2 `07971bf9`, canonical
OLEF supervisor via W3 `9307d6ed`), 1 is half-wired (OPC surface), the
rest are implemented-or-partial but unwired. **None is production-ready**
(wired + verified callers + fail-closed contracts).

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

> **SUPERSEDED (2026-10-20, CI-suite widening — evidence:
> `TIANNARA_RUNTIME_TEST_INVENTORY.md`):** all bullets below were true as of
> 2026-10-19 and are now closed. `Elixir CI` gained a required
> `tiannara_runtime suite` job + a non-blocking quarantine job (`3d3ae924`);
> all 166 test files + 2 support helpers are tracked (`c9a0306c`); the dead
> `start_app` key is removed (`7343f1c7`); the runtime suite is green on every
> push (run `39388434031`). Original text kept verbatim below.

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
2. **ChronogramMatrix/OMRL/OCG supervision**: **DONE (`07971bf9`,
   operator-approved W2)** — 5F.2/5F.3 observer stack (MetaEvolutionStreamManager,
   MSCL 5F.1, MCK, OCAL, OCG, OMRL) added to the Meta layer
   (`TiannaraRuntime.Meta.Supervisor`, `supervisors.ex:181-195`) via
   `optional_child` in dependency order (MSCL → MCK → OCAL → OCG → OMRL);
   OMRL's NATS stub replaced with a real
   `MetaEvolutionStreamManager.publish/2` call (local Bus), hydration
   bugs fixed (nonexistent `Tiannara.Meta.MCK` alias → MSCL, missing
   `OCG.get_score/1` added, `rescue` → `catch :exit` for GenServer
   exits); `MetaEvolutionStreamManager` payload encoding hardened
   (`Jason.encode!` crash on tuple payloads killed the GenServer and
   cascaded the one_for_one Meta supervisor during tests).
   Boot test `test/tiannara/meta/boot_wiring_w2_test.exs` (4 tests).
   CI green (Elixir CI + Cross-Platform) on `07971bf9` — Elixir CI's
   first suite run died on a transient `atom_tab` index exhaustion VM
   crash mid-suite (no test assertion failures; W1 suite log has no
   such crash), rerun passed both workflows. Note: the
   pre-existing orphan `Tiannara.Meta.Supervisor` (`meta/supervisor.ex`)
   was NOT used — wiring went through `TiannaraRuntime.Meta.Supervisor`
   per §4's smallest-safe-path. Not production-ready: OMRL defaults
   `0.5`, divergence hardcoded, no fail-closed contract audit.
3. **OLEF canonical set**: **DONE (`9307d6ed`, operator-approved W3)** —
   non-destructive re-parent chosen over retirement: `Tiannara.OLEF.Supervisor`
   (PressureSolver + GradientRouter) added to the Ecology layer via
   `optional_child` (`runtime_layers/supervisors.ex`); prerequisite
   `Tiannara.EventRegistry` (duplicate-key Registry backing
   `Tiannara.EventBus` — PressureSolver.init subscribes through it)
   added to the Infrastructure layer so it boots first;
   `Tiannara.P9XEcosystem.Supervisor` left in place, unwired, undeleted
   (its remaining children — MSCL 5F.5 set, CIS, P9X, GRCC — are NOT
   re-parented; that would be a larger scope decision);
   `:already_started` tolerance added to `p9x_ecosystem_test` and
   `a10_test` setups (boot-wiring test pattern);
   boot test `test/tiannara/olef/boot_wiring_w3_test.exs` (3 tests,
   incl. EventBus pressure_update round-trip through the live
   PressureSolver). CI green (Elixir CI + Cross-Platform) on `9307d6ed`.
   Note: `test/tiannara/mscl/adaptive_controller_test.exs` (untracked at the
   time, one of the audit's 127) got the same setup tolerance locally; it was
   tracked together with the rest of the suite in `c9a0306c` (§4 item 5, now
   DONE).
4. **Babel**: real key material + a caller before any integration claim.
5. **CI**: **DONE (`c9a0306c`, `3d3ae924`, `d4747586`, `c7214a50`,
   `7343f1c7`, operator-approved CI-suite widening)** — all 166 test files +
   2 support helpers tracked (fresh-checkout `mix test` works); required
   `tiannara_runtime suite (required)` job on all pushes/PRs, fail-closed on
   nonzero exit, plus a visibly-separate non-blocking quarantine job
   (`continue-on-error`); `start_app` dead key removed (grep-verified no
   consumer; the comment claimed boot was disabled while tests booted the app
   implicitly — removal documented in `config/test.exs`); P9X flake fixed by
   statistical soundness (N=64, P≈6.3e-7), never retries; 6 tests quarantined
   with reasons/re-admission conditions (2 Stage B omega, 4 Stage C product
   findings). Three CI-only failures diagnosed and fixed (no_mocks
   loaded-vs-active conflation, passive population env-dependence →
   quarantine, CPL checkpoint string-key crash). First fully green required
   run: `39388434031`. Evidence: `TIANNARA_RUNTIME_TEST_INVENTORY.md`.
