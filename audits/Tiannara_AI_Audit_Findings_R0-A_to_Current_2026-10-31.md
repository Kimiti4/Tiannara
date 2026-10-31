# Tiannara AI — Consolidated Audit Findings

**Coverage:** R0-A through the resource-lifecycle audit checkpoint  
**Prepared:** 2026-10-31  
**Scope:** Tiannara AI only. ESAP is deferred until Tiannara AI audit, remediation, verification, and refinement are closed.  
**Audit posture:** Evidence-led and read-only. This record consolidates findings available in the audit context; it does not claim unresolved items were re-tested or closed.

## 1. Executive status

Tiannara AI is **not yet certifiable as production-ready** on the evidence recorded here. Several defects are source-confirmed or reported against exact commits, but runtime integration, lifecycle reconciliation, evidence integrity, and end-to-end verification remain unresolved.

Rules:
- **UNKNOWN ≠ PASS.**
- A patch, isolated passing test, or documentation statement is not closure by itself.
- Every status change requires evidence tied to the exact candidate commit.
- Simulated evidence must not satisfy runtime gates.
- Keep audits read-only unless implementation is explicitly authorized.
- Later default-branch files are not evidence for behavior at an earlier audited SHA.

## 2. Audit sequence and baselines

Agreed sequence: R0-A (baseline/build), R0-B (inventory/evidence integrity), R1 (evidence integrity and safety), R2 (architecture/integration), R3 (capability verification), R4 (end-to-end production readiness), R5 (stabilization/certification).

Key commits:
- R0-A baseline: `b829254d032f9e0b5cf4c44725c8cf451800dad0`
- Resource-lifecycle checkpoint: `e71bc230a8d38f3a0108012685ae1a052d195b00`
- Earlier AEO/RAC hardening context: `bf613bde`; later reported hardening commits `cac083b5`, `e7f81b97`, `00fca8c3`. These references do not establish closure of every related finding.

## 3. R0-A — baseline build and test blockers

Historical findings at the frozen baseline:
- Extra `end` / syntax error in `lib/tiannara/math/optimization.ex` prevented Elixir compilation.
- An ExUnit test was misplaced under `lib/.../explanation.ex` instead of the test tree.
- Python failures included undefined names `np`, `a`, and `b`.
- `tiannara_core` import and test-collection failures were reported.
- Missing `requirements-production.txt` was reported as a deployment/build blocker.
- Python lint/collection and cross-platform compile failures were reported.
- A complete fresh reproduction and cross-platform rerun were not verified in the recorded baseline.

Subsequent reported progress:
- `lib/tiannara/math/optimization.ex` later compiled after correcting `validate_vector/1`.
- User later reported both CI failures resolved.
- These are narrow progress reports, not proof that every original blocker has been closed by a complete exact-SHA matrix.

## 4. R0-B — inventory and evidence integrity

### Quarantine
- A quarantine path exists, but a historical assertion equivalent to `length(quarantined) >= 0 or length(real) > 0` is ineffective because its first clause is always true for a list length.
- Quarantine persistence/replay, contaminated-data handling, and coverage of all evidence writers were not proven.
- Input-to-decision-to-outcome provenance remains an audit target.

### AC-001 domain registry
- A canonical 20-domain registry/deprecation path was reported.
- Compatibility between consumers expecting records versus identifiers, and actual runtime integration, remained unresolved.
- Registry declarations do not prove all consumers use the canonical registry or that each domain is executable.

**Status:** Partial. Do not infer complete evidence integrity or domain integration from registry code or quarantine paths alone.

## 5. Architecture, integration, and capability truthfulness

### AEO / RAC
- `lib/tiannara/aeo.ex`: reported five tests and one production caller in a forecasting adapter; runtime adapter unconfigured and fail-closed.
- RAC: reported four tests, zero production callers, and checkers unconfigured/fail-closed.
- Local tests do not establish operational reachability or end-to-end enforcement.
- Related audit artifact: TIA-ISD-001 draft; IF-001/IF-002/IF-003 and UEP v1.0 were referenced in the audit context.

### Runtime / orchestration claims
ASC world/civilization/agent counts, GRCC/MSCL percentages, CIS alert counts, and soak-test claims require reproducible telemetry, exact-candidate logs, and a defined measurement method. Long soak duration or zero alerts alone does not prove correctness without health criteria, failure injection, and retained evidence.

### Capability honesty
Real, partial, specified-only, unsupported, and placeholder/theatrical behavior must be distinguished. Prior audit context classified `bayes_update/3` as real, statistics/information functionality as partial, and `optimize/solve_ode` as theatrical or not genuinely implemented in the reviewed context. Revalidate these classifications against exact-SHA source and tests before certification.

## 6. Resource lifecycle audit — immutable checkpoint `e71bc230a8d38f3a0108012685ae1a052d195b00`

This checkpoint was explicitly read-only; no source files or commits were to be changed during that audit pass.

### RL-01 — Spawn continues after quota rejection
**Status:** Source-confirmed at checkpoint. The quota-error branch does not reliably halt the enclosing spawn flow; later memory/replay/child-start steps can still run.  
**Risk:** World creation proceeds without successful quota admission and can leave partial state or incomplete cleanup.

### RL-02 — Spawn continues after memory-allocation rejection
**Status:** Source-confirmed at checkpoint. The memory-allocation error branch does not reliably stop the enclosing spawn flow.  
**Risk:** Inconsistent quota, memory, replay, and supervision state.

### RL-03 — Child implementation / supervisor bridge unresolved
**Status:** Unresolved at inspected paths; not a claim of global absence. The spawn path references `TiannaraRuntime.MultiWorld.WorldProcess`, but a matching production implementation could not be confirmed at the audited SHA. A later/default-branch `fixes.md` snippet is not proof of implementation at this checkpoint.

A separate `TiannaraRuntime.WorldSupervisor` starts a `:one_for_all` per-world tree containing `WorldStateManager`, `CAL.Engine`, `CIS.Engine`, `WorldMemoryStore`, `WorldEventProcessor`, and `WorldSimulationLoop`. It registers via `WorldRegistry` using an ID derived from `world_config.id`. The production bridge between this tree and `MultiWorld.WorldProcess` was not established.

### RL-04 — Replay initialization is asynchronous and unacknowledged
**Status:** Source-confirmed. `DeterministicReplay.start_recording/2` uses `GenServer.cast/2` and returns before initialization is acknowledged, so child execution may begin before recording is ready.  
**Risk:** Missing initial events, nondeterministic recordings, false confidence in replay completeness.

### RL-05 — Invalid replay callback returns
**Status:** Source-confirmed. Reviewed `DeterministicReplay.handle_cast/2` branches return values such as `{:ok, state}` or `:ok` rather than the required `{:noreply, state}`.  
**Risk:** Runtime callback failure or process termination. Earlier checkpoints also flagged `ResourceQuota` and `MemoryManager` callback contracts; verify their exact source and targeted tests before upgrading their evidence status.

### RL-06 — Snapshot/freeze is a placeholder
**Status:** Placeholder source-confirmed; real snapshot semantics unverified. `WorldFreeze.capture_world_state/1` describes the real query as future work and returns a placeholder structure, previously described as empty agent/coalition structures.  
**Risk:** Freeze/snapshot/restore may appear available without preserving world state. Implement and round-trip test it, or explicitly disable/refuse it.

### RL-07 — Split termination/cleanup authority
**Status:** Multiple paths reported; ordering and idempotence unverified.
- `ResourceQuota.terminate_world/2` sends an asynchronous termination message toward the world supervisor.
- The supervisor separately requests quota termination and memory release.
- Kill handling removes a PID from its tracking map before calling `Process.exit/2`.
- `ExecutionController` logs when a kill-delivery target is unavailable.
- Dynamic-supervisor termination observation does not prove quota, memory, replay, PID, and registry reconciliation.

**Risk:** Duplicate/missed cleanup, stale accounting, memory leaks, active replay sessions, PID tracking drift, or logged-but-undelivered kill requests.

### RL-08 — End-to-end kill delivery not demonstrated
**Status:** Runtime-unverified. A log entry or local kill function is insufficient. Prove an authorized request reaches the actual supervised world process, the process terminates, and all resource registries reconcile.

### RL-09 — Lifecycle integration matrix incomplete
**Status:** Not demonstrated as closed. No captured evidence proves an exact-SHA end-to-end matrix for normal exit, crash, quota rejection, memory rejection, replay-start failure, authorized kill, unavailable target, and repeated termination/cleanup.


### Resource lifecycle evidence checkpoint 2 — same immutable SHA

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Mode:** Read-only. Repository source and the audited commit were not modified. Findings below are based on source files retrieved at that exact SHA and the exact-SHA file tree; no local runtime execution was performed in this checkpoint.

#### RL-10 — MemoryManager callback contracts are invalid

**Status: Source-confirmed.** In `tiannara_runtime/lib/tiannara_runtime/multi_world/memory_manager.ex`:
- `handle_cast({:release, ...})`, `handle_cast({:trigger_gc, ...})`, and `handle_cast(:emergency_gc, ...)` return `{:ok, state}` tuples rather than the required `{:noreply, state}`.
- `handle_info(:check_memory, state)` also returns `{:ok, state}` rather than `{:noreply, state}`.

These are invalid GenServer callback return contracts. When one of these callbacks is invoked, the GenServer can terminate instead of reliably applying the requested update. Because the manager stores accounting in process state, a supervisor restart can also discard in-memory reservations unless recovery/persistence is explicitly implemented. The precise restart consequence depends on the actual supervision configuration and was not runtime-tested here.

#### RL-11 — ResourceQuota cast callbacks are invalid across the quota lifecycle

**Status: Source-confirmed.** In `tiannara_runtime/lib/tiannara_runtime/multi_world/resource_quota.ex`, the `handle_cast/2` branches for usage reporting, world termination (including unknown-world termination), and limit updates return `{:ok, state}` or `{:ok, new_state}`, not `{:noreply, state}`. The invalid contract is therefore not confined to one rare branch: ordinary quota reports and cleanup requests exercise it.

**Impact:** A termination cast can mutate the in-memory state and send a supervisor message before returning an invalid callback result and crashing the quota process. If the process restarts with default state, quota reservations and totals may be lost. Exact runtime restart behavior and ordering still require a focused test.

#### RL-12 — Memory release is asynchronous and has no completion contract

**Status: Source-confirmed.** `MemoryManager.release_memory/2` uses `GenServer.cast/2`, so its caller cannot observe whether release was applied. The supervisor then logs that resources were released immediately after issuing the cast, not after an acknowledgement. Combined with RL-10, the current release callback is not reliable evidence of successful accounting reconciliation.

**Closure criterion:** use a synchronous, result-bearing release operation or an explicit acknowledgement/reconciliation protocol; test that the caller observes success only after accounting is updated, and that failure is visible.

#### RL-13 — Memory accounting accepts unvalidated allocation/release amounts

**Status: Source-confirmed.** `allocate_memory/2` and `release_memory/2` do not validate that their MB argument is a non-negative integer. The allocation check only tests whether usage exceeds upper limits; a negative request can lower recorded usage, and a negative release amount can increase it. The spawn estimate also derives from caller-provided `max_agents` and `max_coalitions` and only applies an upper cap (`min(total, 512)`), not a lower bound or input validation.

**Impact:** Invalid configuration or direct API input can corrupt the accounting model and undermine quota enforcement. Add strict validation and boundary tests; rejected values must leave state unchanged.

#### RL-14 — Kill result vocabulary overstates delivery and completion

**Status: Source-confirmed.** In `tiannara_runtime/lib/tiannara_runtime/cis/execution_controller.ex`, the authorized kill branch computes `delivered = deliver_termination_command(world_id)`, logs that value, but returns `:executed` regardless of whether `delivered` is `false`. In `KillSwitch`, an `:executed` result is added to `killed_worlds`. Even a successful `send/2` proves message enqueueing, not that the target world terminated or its resources reconciled.

The existing `test/multi_world/kill_switch_activation_test.exs` has end-to-end process-termination tests for simple probe children, including isolation of a bystander. That is useful limited evidence, but it does not test the production `spawn_world/1` path, quota/memory reservations, replay stop, or registry/accounting convergence. The test directory `test/multi_world/` contains only this kill-switch test file at the audited SHA; no dedicated MemoryManager, ResourceQuota, or spawn failure-path test file is present there.

**Closure criterion:** distinguish authorization, delivery, observed process termination, and completed resource reconciliation as separate states. A missing supervisor or unavailable world must not be reported as killed. Tests must assert all authoritative registries and accounting after the operation.

#### RL-15 — Lifecycle test evidence does not cover accounting failure paths

**Status: Coverage gap confirmed by exact-SHA test-tree inspection; runtime behavior untested.** The only test under `tiannara_runtime/test/multi_world/` is `kill_switch_activation_test.exs`. Its probe child is started directly through `start_child/2`, bypassing `spawn_world/1` reservations and replay initialization. No evidence in this checkpoint demonstrates the required matrix for quota rejection, memory rejection, replay-start failure, child-start failure rollback, repeated cleanup, same-ID restart, negative allocation/release, or reconciliation of quota + memory + replay + PID tracking.

This is a statement about the inspected test location and demonstrated assertions, not a claim that no indirectly relevant tests exist anywhere else in the repository.

#### Checkpoint 2 disposition

The audit remains read-only and open. The new findings strengthen the concern from “asynchronous cleanup may race” to “the accounting callbacks themselves have invalid GenServer return contracts, so cleanup and usage-report paths can terminate their managers.” Do not infer actual runtime restart behavior without execution evidence at the exact candidate SHA. No fixes are applied in this checkpoint.

## 7. Consolidated finding register

| ID | Finding | Evidence status | Closure evidence required |
|---|---|---|---|
| R0-A-01 | Elixir compile syntax failure at frozen baseline | Historical finding; narrow fix later reported | Compile and CI at exact candidate SHA |
| R0-A-02 | ExUnit test misplaced under `lib` | Historical finding; comprehensive closure not evidenced | Test-tree check, compile/test collection, exact-SHA CI |
| R0-A-03 | Python undefined names/import/collection failures | Historical finding; full closure unestablished | Lint, imports, collection, suite at exact SHA |
| R0-A-04 | Missing production requirements file | Historical reported blocker; closure unestablished | Packaging/deployment build |
| R0-B-01 | Ineffective quarantine assertion | Confirmed audit finding | Positive/negative tests that fail if quarantine is absent or wrong |
| R0-B-02 | Quarantine persistence/replay and writer coverage | Unproven | Persistence, replay, contamination, writer inventory tests |
| R0-B-03 | AC-001 consumer/runtime integration | Partial/unresolved | Consumer compatibility matrix and integration tests for all canonical domains |
| ARCH-01 | AEO adapter unconfigured/fail-closed | Prior audit finding | Configured production caller plus fail-closed/end-to-end evidence |
| ARCH-02 | RAC tests but no production callers/checkers configured | Prior audit finding | Production reachability and checker enforcement |
| CAP-01 | Placeholder/theatrical capability claims | Prior classification; revalidate at candidate SHA | Capability-to-code-to-test matrix and truthful unsupported responses |
| RL-01 | Spawn proceeds after quota error | Source-confirmed at `e71bc230...` | Prove no allocation/start after rejection |
| RL-02 | Spawn proceeds after memory error | Source-confirmed at `e71bc230...` | Prove rollback and no child/replay start |
| RL-03 | `WorldProcess` / supervisor bridge unresolved | Unresolved at inspected paths | Exact-SHA implementation plus integration test of intended world tree |
| RL-04 | Replay start asynchronous without acknowledgement | Source-confirmed | Acknowledged start; child waits for recording readiness |
| RL-05 | Invalid replay callback returns | Source-confirmed | Correct callback contracts and branch coverage |
| RL-06 | World freeze capture is placeholder | Placeholder source-confirmed | Real capture/restore round-trip or explicit refusal |
| RL-07 | Cleanup authority split | Paths reported; ordering/idempotence unverified | One authoritative termination state machine and reconciliation tests |
| RL-08 | Kill delivery not proven end-to-end | Runtime-unverified | Authorized request → process termination → registry/resource reconciliation |
| RL-09 | Lifecycle failure-path matrix incomplete | Not closed | Exact-SHA integration tests for all failure and repeated-cleanup paths |
| RL-10 | MemoryManager callback contracts invalid (`handle_cast/2`, `handle_info/2`) | Source-confirmed at `e71bc230...` | Correct callback returns; prove manager stays alive and accounting persists/reconciles |
| RL-11 | ResourceQuota cast callback contracts invalid | Source-confirmed at `e71bc230...` | Correct callback returns; prove quota manager stays alive through reports and termination |
| RL-12 | Memory release asynchronous without acknowledgement | Source-confirmed; completion unproven | Result-bearing release or explicit acknowledgement and postcondition tests |
| RL-13 | Memory allocation/release amounts not validated | Source-confirmed at `e71bc230...` | Reject negative/non-integer values without changing accounting |
| RL-14 | Kill reports `:executed` even if delivery fails; killed registry reflects command result | Source-confirmed at `e71bc230...` | Separate authorization/delivery/termination/reconciliation outcomes |
| RL-15 | Lifecycle test coverage gap for quota/memory/spawn rollback and reconciliation | Exact-SHA test-tree gap; runtime untested | Dedicated failure-injection and resource-reconciliation integration matrix |

## 8. Recommended remediation order

1. **Fix callback contracts first.** Correct invalid `GenServer` returns in `ResourceQuota`, `MemoryManager`, and `DeterministicReplay`; test every callback branch.
2. **Make spawn transactional.** Sequence quota reservation, memory reservation, replay initialization, child startup, and commit. On failure, halt and roll back all prior reservations/sessions/processes. Require replay-ready acknowledgement before child execution.
3. **Resolve the production child/supervision path.** Confirm `WorldProcess` at the exact candidate SHA or explicitly document it missing. Prove the intended per-world tree starts and registers.
4. **Establish one authoritative termination path.** Make cleanup idempotent; reconcile child state, quota, memory, replay, PID maps, and registries after normal exit, crash, rejection, and authorized kill.
5. **Replace or disable fake snapshot behavior.** Implement real capture/restore with round-trip tests, or make it explicitly unsupported/fail-closed.
6. **Run lifecycle integration tests.** Cover successful spawn, quota/memory rejection, replay initialization failure, child-start failure, normal exit, crash, authorized kill, unavailable target, and repeated termination. Assert resource counters and registry state before/after.
7. **Record exact-candidate evidence.** Pin SHA, commands, test output, environment, and artifacts. Change status only when evidence meets closure criteria.

## 9. Evidence and reporting rules

For each finding, record ID, severity/impact, exact repository and SHA, file path/line range, reproduction command/raw result, expected/actual behavior, failure-injection coverage, runtime evidence distinct from simulation, remediation commit, exact-candidate retest, limitations, and disposition.

Evidence labels:
- **Source-confirmed** — visible in source at stated SHA.
- **Test-confirmed** — reproduced by a test at stated SHA.
- **Runtime-confirmed** — observed end-to-end in actual runtime at stated SHA.
- **Partial** — some components verified, integration/coverage incomplete.
- **Unresolved** — evidence missing or path not confirmed.
- **Not closed** — closure criteria unmet.

Do not mark a finding fixed solely because a patch exists or a later branch contains an implementation.

## 10. Current disposition

**Audit remains open. Production readiness is not established.** Immediate risks are non-transactional spawn, invalid GenServer callbacks in replay/quota/memory managers, asynchronous unacknowledged release, unvalidated memory amounts, placeholder snapshot capture, a kill-result vocabulary that can overstate completion, and unproven cleanup reconciliation. The checkpoint 2 source review does not substitute for runtime execution. R0-A/R0-B and architecture findings also require exact-SHA closure evidence.

**No repository source code was changed by this audit record.** Checkpoint 2 adds audit evidence only. This is an audit ledger, not a source patch or certification report.
