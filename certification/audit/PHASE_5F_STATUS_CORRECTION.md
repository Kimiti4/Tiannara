# Phase 5F Status Correction Register (2026-10-19)

**Purpose.** The Phase 5F completion/integration claims in this repository
contain provably false statements. Per operator ruling (5F remediation P1):
historical claims are **preserved for traceability** and marked
*superseded or disproven with evidence* — nothing is erased. Each flagged
document carries a banner pointing at its entry here.

**Method.** Two read-only audits (5F.2–5F.5 and 5F.6–5F.11, 2026-10-19)
against branch `local/pr4`, plus git history inspection. Every verdict below
cites file:line or commit evidence.

## Status vocabulary (required distinction)

| Status | Meaning |
|---|---|
| **Implemented** | Code exists with the claimed behavior |
| **Tested** | Automated tests exist and pass (says nothing about wiring) |
| **Wired** | Started in a supervision tree with a live boot path from `Application` |
| **Production-ready** | Wired **and** verified callers **and** fail-closed contracts — **no Phase 5F component currently qualifies** |
| **Absent** | Claimed but not found anywhere in the repo |
| **Restored** | Previously broken contract re-established under this remediation |

## Register

### C-01 — 5F.4 "application.ex starts ChronogramMatrix automatically" — DISPROVEN
- **Claim:** `tiannara_runtime/PHASE_5F4_COMPLETION_STATUS.md:96-109`
  ("Updated `application.ex` to start ChronogramMatrix supervisor
  automatically").
- **Evidence:** `git log -S ChronogramMatrix -- application.ex` → empty
  (never wired); the 5F.3.5 children it lists (ExecutionController,
  QuotaGovernor, LineageCompression, GCK) were **removed** from
  `application.ex` in `8610c558` ("Fix dialyzer type mismatches and unused
  variables" — no safety rationale).
- **Truth:** ChronogramMatrix is implemented (305 LOC, 20 tests) but
  unwired; zero supervisors reference it.

### C-02 — "production-ready and fully integrated" (5F.4/5F.5) — DISPROVEN
- **Claims:** `PHASE_5F4_COMPLETION_STATUS.md:268`,
  `PHASE_5F5_CORE_IMPLEMENTATION_COMPLETE.md:3,206,372`,
  `PHASE_5F5_COMPLETION_STATUS.md:156,337`.
- **Evidence:** the named `Tiannara.MSCL.*`/`Tiannara.OLEF.*` modules are
  reachable only via `Tiannara.P9XEcosystem.Supervisor`, which is in no
  application boot tree; the repo's own TODO at
  `meta/opc/stabilization/mscl_budget_gate.ex:65-67` says "replace with real
  MSCL call when 5F.5 is wired in" (and names a module that does not exist).
- **Truth:** implemented + tested, **not wired**, not production-ready.

### C-03 — "Phase 5F.5 ~3,500 lines ✅ / ALL PHASES COMPLETE" — DISPROVEN
- **Claim:** `PHASE_5_COMPLETE_SUMMARY.md` (lines 4, 24).
- **Evidence:** named 5F.5 modules total ≈ 800 LOC (figure double-counts
  `Tiannara.Meta.MSCL` labeled "Phase 5F.1", 5F.6's MSCLBudgetGate, legacy
  copies, root-app OLEF); 5F.9 Option A (AOE) has **zero artifacts**; all
  five external 5F.10 distributed-resilience subsystems are absent.
- **Truth:** "all phases complete" is false.

### C-04 — 5F.6 "PRODUCTION READY" — DISPROVEN
- **Claims:** `PHASE_5F6_OPC_IMPLEMENTATION_COMPLETE.md:3`;
  `scripts/verify_phase_5f6_opc.exs:129` prints "Phase 5F.6 OPC is
  PRODUCTION READY!".
- **Evidence:** `ObserverPhysicsCompiler.compile_physics/2` has zero
  production callers; the main-app facade
  (`lib/tiannara/physics/opc.ex`) returns
  `{:error, :physics_substrate_unavailable}` from every function;
  GPU execution fabricates outputs (`sin(i*0.1)+cos(i*0.05)` at
  `opc/runtime/gpu_execution_bridge.ex:326-338`); 5 of 6 claimed backends
  absent (GLSL only).
- **Truth:** parsers/validators/OIR implemented + tested (≈117 tests);
  execution simulated; production-ready claim false. (Fabricated execution
  results are quarantined under 5F-P1c — see remediation status.)
- **Remediated (5F-P1c, `7855aa6d`):** both execution entry points now
  fail closed with `{:error, :simulated_execution_quarantined}` (runtime
  config gate `:opc_execution_quarantine`, default on), internal generators
  tag outputs `simulated: true` / `execution_mode: :simulated`, moduledoc
  states no GPU execution occurs; 5 quarantine contract tests. Quarantine
  work also uncovered and repaired three pre-existing async-path crashes:
  wrong `:queue.out` case pattern, `send(self(), ...)` inside the worker
  task (messages never reached the bridge), and `%{job | error: ...}`
  `KeyError` on job maps lacking the key.
- **Remediated (5F-P3, `b480338c` + `14c7988a`):** `ExecutionRuntime`
  result status is now `:simulated` (`execution_mode: :simulated`) and the
  provenance `Producer.complete` payload records `"status" => "simulated"`
  — cert-path-safe because `RuntimeContract.certifiable?/1` accepts only
  `"completed"`; instrumentation test asserts the honest shape (its
  pre-existing `:already_started` setup failure was baseline-confirmed by
  stash before the fix); `scripts/verify_phase_5f6_opc.exs` no longer
  prints unconditional "PRODUCTION READY" — it computes module presence,
  boot wiring, export existence (`compile_to_glsl/1` and
  `generate_shader_hash/1` are ABSENT), quarantine state, and execution
  status, and exits 1 (current run: 26 checks, 4 failed).
- **Adjacent, out of scope:** `lib/tiannara_runtime/dfg/latent_runtime.ex:39-40`
  still fabricates `%{status: :executed}` from `execute_single_op` —
  recorded here; not remediated in P3.

### C-05 — 5F.8 OED "supervised layer" — DISPROVEN (absent modules)
- **Claim:** `PHASE_5F8_OED_IMPLEMENTATION_COMPLETE.md` — "Implemented
  Runtime Modules: `Tiannara.Runtime.OED.Supervisor`" and
  `Tiannara.Runtime.Kernel` supervision.
- **Evidence:** neither `defmodule` exists anywhere (the only OED
  supervisor is the unrelated `Tiannara.OED.Supervisor`,
  `lib/tiannara/oed/supervisor.ex`); OED's own 5 modules (~200 LOC) start
  only in test setup.
- **Truth:** supervision claims absent; OED code implemented, unwired.

### C-06 — 5F.9 RODL supervisor/GradientSolver — DISPROVEN (absent modules)
- **Claim:** `PHASE_5F9_RODL_IMPLEMENTATION_COMPLETE.md` —
  `Tiannara.Runtime.RODL.Supervisor`, `Tiannara.Runtime.OLEF.GradientSolver`,
  Kernel supervision.
- **Evidence:** supervisor nonexistent; GradientSolver markdown-only
  (actual field stack lives in `lib/tiannara_runtime/legacy/olef/`);
  Option A (AOE) has zero artifacts; `opc/v3/olef/rodl.ex` is a different
  language ("Real-time Observer Definition Language").
- **Truth:** half the claimed phase is absent; the rest is tiny/unwired.

### C-07 — 5F.10 CRA supervisor — DISPROVEN (absent modules)
- **Claim:** `PHASE_5F10_CRA_IMPLEMENTATION_COMPLETE.md` —
  `Tiannara.Runtime.CRA.Supervisor` + Kernel supervision.
- **Evidence:** neither module exists; the 5 CRA GenServers (~265 LOC) run
  only in tests; the external 5F.10 scope (partitions, cross-node
  authority, dedup, snapshot consistency, budget reconciliation) is
  **entirely absent** from the repo.
- **Truth:** CRA code real-ish, wiring claim false, external scope absent.

### C-08 — 5F.11 "integrated into application supervisor" — OVERSTATED
- **Claim:** `PHASE_5F11_IMPLEMENTATION_COMPLETE.md:2,80,231`.
- **Evidence:** `encrypt_causal_payload/…` has zero production callers
  (only its own module + test); Babel protocol itself is genuine with
  14/14 tests; "topological key" is unkeyed SHA-256 over a public string.
- **Truth:** implemented + tested, **not wired**; integration claim false.

### C-09 — 5F.12 "Recursive Reality Governor" — MISNAMED
- **Claim:** `PHASE_5F12_RRG_IMPLEMENTATION_COMPLETE.md:1` (~1,400 LOC,
  "third" RRG definition over the same `rrg/**` directory).
- **Evidence:** `rrg/rrg.ex:3` moduledoc says "Rate-limiting Ontological
  Graph"; `rrg/governor.ex:3` says "Runtime Revelation Governor" (51-line
  unsupervised policy). Three distinct systems share the acronym RRG.
- **Truth:** code real, name/ownership ambiguous — canonical naming in
  C-13.

### C-10 — KillSwitch safety chain ("cannot bypass", "5 critical
### vulnerabilities FIXED") — DISPROVEN, now RESTORED
- **Claims:** commit `92b833ce` message; historical 5F.3.5 completion
  docs; `PHASE_5F_SYSTEM_AUDIT.md:131,290` dependency graph.
- **Evidence:** `8610c558` gutted `CIS.Supervisor` (333→30 LOC, losing
  `authorize_kill/3`) and orphaned the whole stack while callers kept
  calling → `UndefinedFunctionError` on the safety chain; three duplicate
  kill-switch modules coexist.
- **Remediated:** **RESTORED in `f64785df` (5F-P0)** — `authorize_kill/3`,
  `authorize_resource_termination/3`, `authorize_world_suspension/3`,
  `get_stats/0`, `clear_log/0`, `:reset`, plus
  `ExecutionController.execute_kill/3`/`terminate_resource/3` re-added with
  the original `51847461` decision contract; 12 pinned contract tests
  (`tiannara_runtime/test/tiannara/cis/authorization_contract_test.exs`),
  48/48 green with the 5F.3.5/5F.4 suites. **Still true:** the chain is
  not wired into any supervision tree (deliberate — wiring requires
  explicit approval), and duplicates remain (C-11).

### C-11 — "Eliminated duplicate KillSwitch implementations" — DISPROVEN
- **Evidence:** three kill-switch modules coexist:
  `multi_world/kill_switch.ex` (246 LOC), `hardened_kill_switch.ex` (270),
  `kill_switch_causal.ex` (170); `world_supervisor.ex:111-144` calls
  `KillSwitch.get_killed_worlds/0`/`request_kill/2`/`confirm_kill/2` which
  do not exist on the unified KillSwitch (dead API).
- **Status:** flagged for consolidation; **no deletions without explicit
  scope approval.**

### C-12 — Phase numbering: external design doc vs repo (canonical map)
| Phase | Repo canonical meaning (source) |
|---|---|
| 5F.7 | Runtime Revelation Governor (`rrg/governor.ex`) — booted system is the Rate-limiting Ontological Graph (`rrg/rrg.ex`) |
| 5F.8 | Ontological Escape Dynamics + ISRD (`markdown/5F8.md:1`) |
| 5F.9 | RODL + OLEF ("Choice B"; Choice A/AOE never built) |
| 5F.10 | Causal Redundancy Autogenesis (CRA) |
| 5F.11 | Babel Substrate (+ GPU bridge bundled in the doc) |
| 5F.12 | OMCE↔OLEF bridge / (also labelled "RRG") |
External documents that call 5F.8 "multi-history physics execution" or
5F.10 "distributed resilience" describe **unbuilt scope** (C-03/C-07).

### C-13 — RRG acronym: three systems, one name (canonical naming)
1. **Rate-limiting Ontological Graph** — `rrg/rrg.ex:3` (~2,000 LOC,
   actually booted via `runtime_layers/supervisors.ex:125`) — canonical for
   the booted `Tiannara.RRG` namespace.
2. **Runtime Revelation Governor** — `rrg/governor.ex:3` (51-line policy,
   unsupervised) — canonical name for 5F.7.
3. **Recursive Reality Governor** — `PHASE_5F12_RRG_IMPLEMENTATION_COMPLETE.md`
   — **retired name**; same code as (1).
Renaming code namespaces is deferred (destructive; needs approval);
documentation must use the canonical names above.

### C-14 — "Public Repo Audit Scope.txt" — ABSENT
- Not present anywhere in the repo or local checkout (glob/grep). Closest
  in-repo audit artifacts: `docs/architecture/MARKDOWN_DIRECTORY_AUDIT.md`
  (classifies 5F6–5F9 as **proposals to defer**) and
  `tiannara_runtime/PHASE_5F_SYSTEM_AUDIT.md` (self-reports "16 missing
  modules (67% of required stack)").

## What the audits confirmed as genuinely true (do not "correct")

- 5F.4 ChronogramMatrix: 305 LOC / 20 tests / GCK thresholds 0.92 & 0.75
  verbatim (`gck/chronogram_gate.ex:60,63`); `validate_read/2` always-allow
  stub; entropy = map-size placeholder.
- 5F.3 OMRL weighted-merge engine (567 LOC, 23 tests) — divergence score
  hardcoded 0.5, NATS publish = Logger.debug stub.
- 5F.6 OPC parsers/validators/OIR (≈8.9k LOC, ≈117 tests).
- 5F.11 Babel non-commutative operator rotation (14/14 tests).
- CIS safety contract — **restored** (C-10).

## Remediation status

| Item | Status |
|---|---|
| C-01..C-09, C-11..C-14 | Banners added to flagged docs (this change) |
| C-10 safety chain | **RESTORED** `f64785df` + contract tests, CI green |
| Supervision wiring of any 5F stack | **Not done — requires explicit operator scope approval** |
| Duplicate/renaming consolidation (C-11/C-13) | Deferred — destructive, needs approval |
| OPC fabricated-execution quarantine (C-04) | **DONE** `7855aa6d` — fail-closed sync+async, tagged outputs, 5 tests, 3 async crashes repaired |
| ExecutionRuntime simulated-status honesty (C-04, P3) | **DONE** `b480338c` — result `:simulated`, Producer payload `"simulated"`, instrumentation test green against app-booted runtime |
| Verification scripts honesty (P3) | **DONE** `14c7988a` — 5F.6 script: 26 computed checks, 4 real failures, exit 1; 5F.5 script: boot-wiring audit before script-local starts, 30 checks, 3 real failures, exit 1 |
| Untracked 5F.5/MSCL test (P3 tracking) | **DONE (this change)** — `test/tiannara/meta/metastability/phase_5f5_mscl_test.exs` 21/21 green, added to git |
