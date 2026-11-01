# Tiannara AI — Consolidated Audit Findings

**Coverage:** R0-A through Checkpoint 18 continuation (executive management, runtime ownership, recovery and persistence integration)  
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
| CAP-02 | Autonomous research/hypothesis/discovery path exists in source but end-to-end research quality and real-world discovery are not certified | Source-confirmed design/path; report says pre-certification baseline | Run exact-SHA pipeline tests with held-out tasks, real evidence, falsification, replication, calibrated uncertainty, and durable provenance |
| CAP-03 | Archaeology terminology conflates research-provenance reconstruction with excavation of simulated prior civilizations | Source-confirmed fail-closed excavation module; site-excavation workflow unverified | Define artifact/world/site/stratum contracts and prove a world-history-to-site-to-artifact-to-hypothesis workflow end-to-end |
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
| RL-15 | Lifecycle test coverage gap for quota/memory/spawn rollback and reconciliation | Exact-SHA test-tree gap; runtime untested | Dedicated failure-injection and resource-reconciliation integration matrix |\n| RL-16 | Freeze reports success without confirming world pause | Source-confirmed at `e71bc230...` | Acknowledged pause protocol and missing/dead/timeout tests |\n| RL-17 | Emergency kill bypasses replay stop and memory release | Source-confirmed at `e71bc230...` | Shared idempotent cleanup path and post-kill reconciliation tests |\n| RL-18 | Termination reports completion before process-down/cleanup acknowledgement | Source-confirmed at `e71bc230...` | Await process-down and result-bearing resource cleanup before terminal success |
| RL-19 | WorldRegistry name collision between metadata GenServer and Elixir Registry call sites | Source-confirmed at `e71bc230...` | Separate names, boot both services, verify registration and lookup |
| RL-20 | WorldRegistrySupervisor absent from inspected application boot graph | Source-confirmed at `e71bc230...` | Wire into canonical boot graph and prove boot-level world lifecycle |
| RL-21 | Per-world simulation loop starts stopped with no activation in tree startup | Source-confirmed at `e71bc230...`; external activation unresolved | Explicit activation contract and tick/pause/resume/termination tests |
| RL-22 | `:one_for_all` child restart reinitializes in-memory world state and snapshot history | Source-confirmed reset behavior; restart not runtime-tested | Crash each child; assert required state recovery or explicitly documented reset semantics at exact SHA |
| RL-23 | Restarted simulation loop loses running/tick state and does not self-resume | Source-confirmed | Inject child crash; verify activation/resume protocol and tick continuity or documented safe stop |
| RL-24 | Metadata registry restart loses world/lineage/count state without recovery | Source-confirmed in-memory-only state; restart consequence not runtime-tested | Restart registry with active worlds; recover/reconcile durable metadata and actual child PIDs, or fail closed |
| RL-25 | World runtime supervisor and metadata registry have independent restart domains with no demonstrated reconciliation | Source-confirmed topology; runtime outcome unverified | Inject registry and DynamicSupervisor restarts separately; prove active-world inventory and duplicate-ID handling converge |
| RL-26 | WorldMemoryStore is process-memory-only and resets on child/world restart | Source-confirmed | Persist snapshots durably or explicitly mark volatile; restart/kill tests prove retention contract and replay limits |
| RL-27 | No demonstrated same-ID restart/termination reconciliation contract | Unresolved; registry collision and absent boot wiring already confirmed in RL-19/RL-20 | End-to-end same-ID restart test proving uniqueness, registration, metadata/count consistency, and stale-process cleanup |
| RL-28 | Repeated registry termination can decrement `active_count` more than once | Source-confirmed at `e71bc230...` | Make termination idempotent by transitioning only active worlds; test duplicate and concurrent termination without negative/drifting counts |
| RL-29 | Quota state is removed before world termination is observed, while cleanup notifications are asynchronous and callback contract is invalid | Source-confirmed at `e71bc230...`; runtime result untested | Use a termination state machine; preserve reservation until process-down and cleanup reconciliation; inject supervisor/manager failure |
| RL-30 | MultiWorld supervisor removes world PID tracking before confirming process-down and can log success without observed termination | Source-confirmed at `e71bc230...`; runtime outcome untested | Monitor child, retain transitional state until DOWN, reconcile DynamicSupervisor and resources, and only then report terminal success |

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


### Resource lifecycle evidence checkpoint 3 — spawn orchestration, supervision, freeze semantics

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Mode:** Read-only. Source files were fetched at the exact SHA; the recursive Git tree was inspected. No runtime execution was performed. No source changes were made.

#### RL-16 — Freeze returns success without confirming that the world paused

**Status: Source-confirmed.** In `tiannara_runtime/lib/tiannara_runtime/multi_world/world_freeze.ex`, the `handle_call({:freeze, ...})` path calls `capture_world_state/1`, sends a `:pause` message to the registered WorldSupervisor, and immediately replies `:ok`. The notification helper uses asynchronous `send/2`; there is no acknowledgement from the world process that it received the message or entered a paused state. The supervisor's `:pause` handler also only forwards a message to a PID found in its map and does not report whether a PID existed or whether the child paused.

**Impact:** Callers can receive a successful freeze result even when the target world is absent, untracked, or has not yet paused. The placeholder capture already tracked in RL-06 compounds this: neither a real snapshot nor a confirmed pause is established.

**Closure criterion:** Validate world existence and ownership, request pause through a result-bearing protocol, await an explicit paused acknowledgement with timeout, and return success only after the required postconditions are observed. Test missing world, dead PID, timeout, and concurrent freeze/unfreeze.

#### RL-17 — Emergency kill path bypasses replay and memory cleanup

**Status: Source-confirmed.** In `tiannara_runtime/lib/tiannara_runtime/multi_world/world_supervisor.ex`, the `handle_info({:kill_world, ...})` path removes the PID from `state.worlds`, sends `Process.exit(world_pid, :kill)` when a PID exists, calls `notify_quota_termination/2`, and returns. Unlike `terminate_world_process/3`, this path does not call `DeterministicReplay.stop_recording/1` or query/release the world's MemoryManager reservation. It also does not await process termination or resource reconciliation.

**Impact:** A world killed through this message path can leave replay state active and memory accounting reserved, while the PID is removed from the supervisor's local tracking map. This is a concrete divergence between two termination paths, not merely a general concern about duplicated authorities.

**Closure criterion:** Route emergency kill through the same authoritative idempotent cleanup state machine, with an explicit emergency termination action but shared replay stop, memory release, quota reconciliation, observed process-down, and final-state verification. Add tests asserting every resource registry after emergency kill.

#### RL-18 — Termination reports completion before process-down and cleanup completion

**Status: Source-confirmed.** In `terminate_world_process/3`, the supervisor sends `Process.exit(world_pid, :shutdown)`, then requests quota termination and issues an asynchronous memory release cast, and finally logs that the world is terminated and resources released. The code does not monitor/await a `:DOWN` signal before the completion log, and the memory release API has no acknowledgement (RL-12). The emergency-kill path likewise sends an exit signal without waiting for process-down.

**Impact:** The log and caller-visible lifecycle can advance to “terminated/resources released” while the child may still be shutting down and memory accounting may not yet have changed. This creates a false completion boundary for operators and downstream orchestration.

**Closure criterion:** Separate termination-requested, process-down-observed, and cleanup-reconciled states. Await monitor confirmation and result-bearing cleanup acknowledgements before publishing terminal success. Exercise slow shutdown, unresponsive child, manager failure, and duplicate termination.

#### Checkpoint 3 disposition

The exact-SHA tree contains no `TiannaraRuntime.MultiWorld.WorldProcess` implementation or `world_process.ex` file under the runtime tree, despite the spawn tuple referencing that module. The previously recorded RL-03 remains unresolved; this checkpoint does not infer that a similarly named world component elsewhere implements the required child contract.

The spawn orchestration in `spawn_world/1` also visibly continues after quota/memory error branches rather than enclosing subsequent work in success-only control flow; this is already recorded as RL-01 and RL-02 and is not duplicated as a new finding.

No runtime claims are made. The findings above are source-confirmed only at the stated SHA.



### Resource lifecycle evidence checkpoint 4 — supervision tree and registry ownership

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`. Read-only source inspection; no runtime execution.

#### RL-19 — WorldRegistry name collision between metadata GenServer and Elixir Registry

**Status: Source-confirmed.** `world_registry.ex` defines `TiannaraRuntime.WorldRegistry` as a named GenServer holding world metadata. However, `WorldSupervisor.via_tuple/1` and `WorldSimulationLoop` use `Registry` APIs with that same name, which require an Elixir Registry process. `WorldRegistrySupervisor` starts the metadata GenServer under that name, not an Elixir Registry. The Infrastructure layer starts `Tiannara.Registry`, a different name. These services cannot safely share the same registered name.

**Impact:** World supervisor registration and lookup do not have a coherent Registry owner. The metadata GenServer cannot serve as an Elixir Registry.

**Closure:** Give the metadata service and process Registry distinct names, start each exactly once, route each API to the correct owner, and test registration/lookup, duplicate IDs, and restart.

#### RL-20 — WorldRegistrySupervisor is absent from the inspected application boot graph

**Status: Source-confirmed.** The audited `Application` child list does not include `WorldRegistrySupervisor`. The `StartupSupervisor` starts `RootSupervisor`; the inspected `RootSupervisor` composes Infrastructure, Execution, Ecology, Constraint, and Meta layers, none of which includes `WorldRegistrySupervisor`. Infrastructure starts `Tiannara.Registry`, not the world registry supervisor or a Registry named `TiannaraRuntime.WorldRegistry`.

**Impact:** The declared metadata registry and `WorldRuntimeSupervisor` are not established by the inspected application boot graph. Module definitions and child specs do not prove runtime availability.

**Closure:** Wire the required services into the canonical boot graph and prove boot-level world registration, lookup, and stop through the production path.

#### RL-21 — Per-world simulation loop starts stopped; activation is not part of tree startup

**Status: Source-confirmed for the reviewed tree; external activation unresolved.** `WorldSupervisor.init/1` includes `WorldSimulationLoop`, but its `init/1` sets `running: false`. Ticks are scheduled only after `start_simulation/1` casts `:start_simulation`. The inspected supervisor does not activate it or include an activation handshake.

**Impact:** A started supervision tree can remain inert even though its simulation-loop child is alive.

**Closure:** Make activation an explicit result-bearing part of world creation, then test tick progression, pause, resume, and termination.

#### Checkpoint 4 disposition

The per-world `WorldSupervisor` tree is separate from `MultiWorld.WorldSupervisor`, which attempts to start `TiannaraRuntime.MultiWorld.WorldProcess`; that implementation remains unresolved at this SHA (RL-03). No bridge between the two paths was established. Although the per-world tree declares `:one_for_all`, no runtime fault-injection evidence was collected to prove restart behavior, state recovery, registry re-registration, or simulation-loop resumption.


### Resource lifecycle evidence checkpoint 5 — restart, crash recovery, persistence, and registry reconciliation

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`. Source was fetched by exact commit SHA. This was read-only inspection; no runtime fault injection or source modification was performed.

#### RL-22 — `:one_for_all` restarts discard the per-world components' in-memory state

**Status: Source-confirmed reset behavior; restart outcome not runtime-tested.** `WorldSupervisor.init/1` declares `:one_for_all` over `WorldStateManager`, CAL, CIS, `WorldMemoryStore`, `WorldEventProcessor`, and `WorldSimulationLoop`. The inspected `WorldStateManager.init/1` reconstructs CAL/CIS/metrics from hard-coded defaults and the supplied config; it does not restore prior live state. `WorldMemoryStore.init/1` initializes an empty snapshot list and zero count. Thus a child failure that causes the tree to restart will reinitialize these state holders rather than restore their previous in-memory contents.

**Impact:** A supervision restart is not equivalent to world recovery. Prior decisions, metrics, snapshots, and counters may be lost. No persistence/restore protocol for these modules was found in the inspected source.

**Closure:** Define which state must survive each failure class, implement durable checkpoint/replay or explicitly declare loss/reset semantics, and inject a crash in every child while asserting recovery invariants.

#### RL-23 — Simulation-loop restart resets execution state and does not automatically resume

**Status: Source-confirmed.** `WorldSimulationLoop.init/1` sets `running: false` and `tick_count: 0`; ticks are scheduled only after `start_simulation/1`. Under the per-world `:one_for_all` strategy, a sibling failure restarts the loop too. The inspected `WorldSupervisor` does not start the simulation loop or perform a post-restart activation handshake.

**Impact:** Even if the supervisor and all child processes restart successfully, the world can return as an alive but stopped tree, with its tick counter reset. No runtime test establishes external reactivation.

**Closure:** Make world lifecycle state explicit and authoritative; restore or intentionally reset it, then acknowledge readiness/activation after every tree restart. Test crash, restart, and continued tick progression.

#### RL-24 — Metadata registry restart loses the world catalogue and counters

**Status: Source-confirmed in-memory-only state; restart behavior not runtime-tested.** `WorldRegistry.init/1` creates a fresh struct with empty `worlds` and `lineage` maps and zero `active_count` / `total_created`. No persistence or reconciliation step appears in the inspected module. Its supervisor uses `:one_for_one`, so the registry child can restart independently of `WorldRuntimeSupervisor`.

**Impact:** If the registry process restarts while world runtime children remain alive, metadata, lineage, and counts are reset while those child processes may still exist. This creates a potential orphaned-runtime / empty-catalogue split. Actual surviving-child behavior was not executed here.

**Closure:** Persist authoritative metadata or rebuild it from an authoritative runtime inventory on restart; reconcile counts and lineage; fail closed when inventory cannot be reconciled. Test registry-only restart with active worlds.

#### RL-25 — Registry and world DynamicSupervisor restart domains have no recovery/reconciliation contract

**Status: Source-confirmed topology; runtime outcome unverified.** `WorldRegistrySupervisor` starts metadata `WorldRegistry` and named `WorldRuntimeSupervisor` as siblings under `:one_for_one`. A failure of one child does not, by that strategy alone, force the other child to restart. The inspected registry has no reconciliation callback, and the application boot graph does not include `WorldRegistrySupervisor` (RL-20). Meanwhile the per-world supervisor registration calls target the conflicting registry name already recorded in RL-19.

**Impact:** Recovery cannot be considered coherent: metadata may be lost independently, live children may persist without catalogue entries, and registry registration itself is not established by the inspected boot graph. No crash/restart evidence proves convergence.

**Closure:** Resolve registry ownership and boot wiring first, then specify restart strategy and reconciliation semantics. Inject registry and DynamicSupervisor failures separately and assert inventory, registrations, metadata, and quotas converge without duplicate IDs.

#### RL-26 — WorldMemoryStore snapshots are volatile, despite replay/history role descriptions

**Status: Source-confirmed.** `WorldMemoryStore` keeps snapshots in the GenServer's in-memory list (bounded to 10,000) and initializes that list empty. Its append API is an asynchronous cast. No disk/database persistence, append acknowledgement, or restore operation appears in the inspected module. Under `:one_for_all`, this store is restarted when any sibling fails.

**Impact:** The code's timeline/replay role description is not evidence of durable history. A process or world-tree restart resets the snapshot history, and an asynchronous append caller cannot confirm that a snapshot was stored before a crash.

**Closure:** Either implement durable append/checkpoint/recovery with acknowledged writes and retention guarantees, or accurately label the store volatile and prevent it from satisfying durable replay/recovery requirements. Test abrupt process death and full runtime restart.

#### RL-27 — Same-ID restart and termination reconciliation remain unproven

**Status: Unresolved; related source defects already tracked in RL-19/RL-20.** The reviewed source does not establish a working end-to-end path that starts a world, registers it, observes its termination, removes/reconciles its metadata, and starts a replacement with the same ID safely. The current registry-name collision and missing boot wiring make a passing claim particularly unjustified. The metadata API generates a UUID on `create_world/2`, while `WorldSupervisor.start_link/1` registers by `world_config.id`; no proven transaction connects those identities and lifecycles.

**Impact:** Duplicate registration, stale metadata, orphaned child processes, or mismatched active counts cannot be ruled out. This is a verification gap, not a claim that every attempted same-ID restart necessarily fails.

**Closure:** Add a production-path test for create → start → crash/terminate → observe cleanup → restart same ID; assert exactly one owner, one registration, correct active count, no stale PID, and consistent quota/memory/replay state.

#### Checkpoint 5 disposition

The inspected source supports concrete reset/volatility findings, but no crash-injection or runtime recovery test was run. Therefore this checkpoint does not claim that every supervisor restart fails; it establishes that the code shown does not implement durable state restoration or an automatic simulation-loop resume contract, and that registry/runtime reconciliation is not demonstrated. RL-19 and RL-20 remain foundational blockers. The frozen source SHA was not changed; only this audit ledger is updated.


### Resource lifecycle evidence checkpoint 6 — termination and state-machine consistency

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`. Source files were fetched at this exact SHA. This was a read-only source review; no runtime fault injection or source modification was performed.

#### RL-28 — Repeated registry termination can decrement active count more than once

**Status: Source-confirmed.** In `tiannara_runtime/lib/tiannara_runtime/world_registry.ex`, `handle_cast({:terminate_world, world_id}, state)` decrements `active_count` whenever the world exists, without checking whether its prior status is already terminal. The code marks it `:extinct`, but a repeated termination for that same entry still enters the same branch and decrements the count again. The cast API is asynchronous, so the caller also receives no confirmation of the transition.

**Impact:** Duplicate cleanup messages can make the registry count diverge from its catalogue. This is separate from the broader registry restart/reconciliation issue in RL-24/RL-25.

**Closure:** Make the transition idempotent: only an active-to-terminal transition decrements count, and report a result that distinguishes transitioned, already terminal, and unknown world. Test duplicate, concurrent, and unknown-world termination.

#### RL-29 — Quota reservation is removed before termination is confirmed

**Status: Source-confirmed sequencing; runtime outcome untested.** In `multi_world/resource_quota.ex`, the termination callback deletes the world from `active_worlds` before notifying `MultiWorld.WorldSupervisor`; notification is a bare message. The same callback returns an invalid GenServer callback tuple (RL-11). The supervisor's termination path independently requests quota termination, removes its local PID mapping, sends an exit signal, requests asynchronous memory release, and logs completion without awaiting process-down or cleanup acknowledgement (RL-18).

**Impact:** Quota can report capacity as free before the process has stopped. If the supervisor is unavailable, the message is not confirmed delivered; if the quota callback crashes, the process may restart with default accounting. These are source-level ordering and contract defects; no claim is made that a particular run was observed to leak a world.

**Closure:** Model termination as explicit states (requested, authorized, signal delivered, process down, resources reconciled, terminal). Keep capacity reserved until the agreed terminal postconditions hold; make delivery and cleanup result-bearing and recoverable after manager restart.

#### RL-30 — MultiWorld supervisor drops PID tracking and logs completion without observing process-down

**Status: Source-confirmed.** `take_world_pid/2` deletes the world from `state.worlds` before the code sends `:shutdown` or `:kill`. The code does not monitor/await a `:DOWN` event or verify that the DynamicSupervisor has removed the child before it logs termination. The emergency-kill branch also removes tracking before signalling, then notifies quota without stopping replay or releasing memory (RL-17).

**Impact:** The supervisor's local state can say the world is absent while the process is still alive or cleanup remains incomplete. Because the mapping is already removed, later cleanup attempts may no longer have that PID available through this state. This is a risk established by the control flow, not a runtime-confirmed orphan.

**Closure:** Retain a termination-in-progress entry and monitor the child. Only remove the authoritative PID entry after observed process-down; then reconcile DynamicSupervisor, replay, quota, memory, and registry before reporting success. Ensure all normal and emergency paths share the same idempotent cleanup protocol.

#### Checkpoint 6 disposition

The reviewed source confirms three additional state-machine defects/gaps: non-idempotent registry count updates, quota release before termination confirmation, and PID tracking removal before process-down observation. RL-11, RL-17, RL-18, RL-19, RL-20, RL-24, and RL-25 remain directly relevant blockers. No runtime outcome was claimed or tested. The frozen source SHA remains unchanged; only the audit ledger was updated.


### Pre-checkpoint-7 targeted investigation — autonomous research, hypothesis formation, discovery, and prior-civilization excavation

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`. This is a targeted source/design review before lifecycle checkpoint 7. No runtime tests were executed in this investigation.

#### Finding CAP-02 — Autonomous research is architecturally represented, but end-to-end discovery capability is not certified

**Evidence:** `lib/tiannara/asc/autonomous_discovery.ex` implements a bounded cycle that gathers domain metrics, checks pipeline health, selects a candidate experiment, runs simulation and validation, records rejected hypotheses/counterexamples, and persists a fact only when validation contains non-empty checks that all pass. It distinguishes simulation/validation unavailable, timeout, crash, rejection, and knowledge-update failure rather than converting those states into successful discoveries. `lib/tiannara/agency/research_director.ex` also defines an observation/event → hypothesis generation/ranking → experiment design/execution → evidence evaluation → knowledge integration path.

However, `AUTONOMOUS_DISCOVERY_REPORT.md` explicitly labels its status **PRE-CERTIFICATION BASELINE** and says hypothesis quality is not quantitatively validated, the required experiment campaign is absent, theory replay is not independently audited, contradiction detection is smoke-tested only, uncertainty calibration lacks a campaign, and explanation quality lacks blinded scoring. These are important distinctions: a pipeline and schemas are present, but they do not prove autonomous, scientifically reliable discoveries across domains or real-world truth.

**Assessment:** Worlds/research components are designed to form hypotheses and test them in simulation; whether a running world autonomously initiates and completes this workflow is not established by the inspected world supervision tree. The reviewed `WorldSimulationLoop` does not call the autonomous discovery pipeline; it performs CAL/CIS steps and its visible event/snapshot helpers are logging/storage-oriented. Cross-world simulation results must remain labelled simulation-scoped and cannot alone certify real-world claims.

**Closure evidence:** demonstrate boot-level reachability from a world/civilization research trigger into the research pipeline; run a bounded campaign against held-out tasks; retain raw observations, controls, predictions, failed experiments, counterexamples, provenance, independent validation, replication, and calibrated uncertainty. Show that missing simulation/evidence/validation backends fail closed and that no unvalidated fact is integrated.

#### Finding CAP-03 — “Archaeology” has two distinct meanings; excavation of previous simulated civilizations is not established

**Evidence:** `ARCHAEOLOGY_AUDIT.md`, `DISCOVERY_ARCHAEOLOGY.md`, and `ARCHAEOLOGY_IMPLEMENTATION_REPORT.md` describe research/discovery archaeology: provenance, immutable lineage, replay/reconstruction, and answering why an artifact exists. Those contracts are not, by themselves, a spatial archaeological excavation system for a previous simulated world or civilization.

More decisively, `lib/tiannara/archaeology/archaeology.ex` defines `Tiannara.Archaeology.FossilExcavator`, `SemanticReconstructor`, `EpochCompressor`, and `IdentityPreserver` as **fail-closed**. The `excavate/2` function returns `{:error, :archaeology_simulation_unavailable}` unconditionally. Its module documentation says the previous implementation returned hardcoded metrics regardless of input and was falsified; the fail-closed behavior intentionally preserves that finding rather than fabricating excavation results.

The repository also contains archaeological stratum data files and numerous architecture/model documents about discovery, theory, civilization, and archaeology. Their presence proves design artifacts/data exist, not that a running world can generate a prior civilization, preserve its physical/social/technical remains, discover a buried site, excavate it, classify artifacts, infer competing historical hypotheses, and validate discoveries against evidence.

**Assessment:** The previously discussed excavation capability is represented in project concepts and data, but **a functional excavation of prior-world/civilization sites is not demonstrated at this SHA; the exposed FossilExcavator explicitly refuses execution**. Do not mark this capability as implemented or working based on documentation/test reports for provenance archaeology.

**Closure evidence:** specify a world-history and strata contract; create persistent, queryable site/stratum/artifact records tied to a particular world and epoch; implement excavation as an evidence-producing operation (not hardcoded outputs); preserve location/depth/context, chain of custody, dating uncertainty, material/composition observations, competing interpretations, and provenance; test discovery, partial excavation, contradictory artifacts, failed hypotheses, and reproducible replay against generated prior-civilization scenarios. Keep simulated archaeology evidence clearly labelled simulation-only unless independently corroborated with real-world evidence.

#### Investigation disposition before checkpoint 7

This investigation was intentionally performed after checkpoint 6 and before checkpoint 7. It did not change the frozen source or execute tests. Current answer: **the architecture includes research/hypothesis/experiment/discovery paths, but their autonomous scientific reliability and live-world integration remain uncertified; the site-excavation function is explicitly fail-closed, and no end-to-end excavation of previous simulated civilizations is proven.** The audit should carry these as open capability findings, not treat the earlier archaeology design reports as runtime proof.


### Resource lifecycle evidence checkpoint 7 — termination dispatch and spawn-admission rollback

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`. The following paths were fetched at that exact SHA: `tiannara_runtime/lib/tiannara_runtime/multi_world/world_supervisor.ex`, `resource_quota.ex`, `memory_manager.ex`, `world_registry.ex`, and `world_simulation_loop.ex`. This is a read-only source trace; no runtime tests or fault injection were run. The autonomous-research/archaeology investigation remains a separate pre-checkpoint-7 capability finding.

#### RL-31 — Termination reports completion and releases accounting without observing process-down

**Status: Source-confirmed at the frozen SHA; runtime outcome untested.** In `MultiWorld.WorldSupervisor.terminate_world_process/3`, the supervisor requests a pre-termination snapshot and stops replay, removes the world PID from its `worlds` map via `take_world_pid/2`, sends `:shutdown` if a PID was present, then asynchronously notifies `ResourceQuota` and requests memory release. It does not monitor or await a `:DOWN` signal before releasing accounting and logging “terminated and resources released.” The path also proceeds with quota notification and the completion log when no PID was found.

**Impact:** A delayed, trapped, ineffective, or otherwise incomplete termination can be represented as complete while the process or associated state still exists. This reinforces RL-29/RL-30 but is recorded as the concrete common cleanup ordering in the normal termination helper. It does not prove an orphan was observed at runtime.

**Closure evidence:** make termination a result-bearing state machine; retain the PID and reservation while termination is pending; monitor and confirm process-down; await replay-stop and memory/quota reconciliation or record explicit failures; make repeated requests idempotent; emit terminal success only after the required postconditions are observed. Fault-inject missing PID, delayed shutdown, child crash, replay failure, quota restart, and memory-manager restart.

#### RL-32 — Spawn admission failures do not stop the spawn transaction

**Status: Source-confirmed at the frozen SHA.** In `MultiWorld.WorldSupervisor.spawn_world/1`, the `request_world_spawn/1` error branch logs and evaluates `{:error, reason}` but does not return from the function. Execution continues to memory allocation and then replay initialization and child startup. The memory-allocation error branch likewise requests asynchronous quota termination and evaluates an error tuple without halting the enclosing function, so execution can continue into replay setup and child startup. This is the concrete control-flow basis of RL-01/RL-02, now traced together as one failed-transaction path; those original findings remain open and are not replaced.

**Impact:** A rejected spawn can continue side effects and start a child without successful quota/memory admission. Rollback is also not transactional: replay initialization has no acknowledgement in this path, and failure cleanup uses asynchronous accounting operations.

**Closure evidence:** rewrite admission as a fail-fast transaction with explicit stages and compensating rollback; require positive acknowledgements for quota, memory, replay readiness, and child startup; ensure every failure halts forward progress and rolls back only resources actually acquired. Test each injected failure and assert no child, replay session, quota reservation, or memory reservation remains.

#### RL-33 — Simulation loop silently substitutes default results when world state cannot be resolved

**Status: Source-confirmed at the frozen SHA; runtime consequence untested.** In `WorldSimulationLoop.execute_cal_step/1` and `execute_cis_step/2`, a missing registry entry or missing state-manager child returns a default CAL/CIS result instead of surfacing a lifecycle/integration error. The tick then continues through state-update/logging helpers and snapshot storage; the state-update and publish helpers shown in this file only emit debug messages. A missing supervisor is logged by snapshot storage, but it does not turn the tick into a failed lifecycle outcome.

**Impact:** A world tick can appear to progress while the authoritative world tree or state manager is unavailable, masking a broken registry/supervisor connection and producing default-valued snapshots. This is not evidence that every tick follows that path, nor that snapshots are durable.

**Closure evidence:** distinguish unavailable world/state from a legitimate empty result; return a typed failure and mark the tick unhealthy without advancing success counters; bind world identity to the exact supervisor/state-manager PID; add tests for registry absence, missing child, supervisor restart, and recovery, asserting no fabricated-success snapshot is persisted.

#### Checkpoint 7 disposition

The source trace confirms unsafe termination ordering, non-fail-fast spawn admission, and silent default-result fallback in the simulation loop. These are source-level findings only; runtime fault injection remains outstanding. RL-01/RL-02 and RL-28/RL-30 remain open. The frozen application source was not changed. Only this audit ledger is updated.


### Resource lifecycle evidence checkpoint 8 — manager state, replay readiness, and snapshot truthfulness

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`. Source files fetched at this exact SHA: `memory_manager.ex`, `resource_quota.ex`, `deterministic_replay.ex`, and `world_freeze.ex`. No application source was modified and no runtime tests were run. These findings establish implementation-level gaps; failure/restart outcomes still require executable tests.

#### RL-34 — Resource accounting is volatile and has no demonstrated reconciliation after manager restart

**Status: Source-confirmed; restart behavior inferred from implementation, not runtime-tested.** Both `MemoryManager` and `ResourceQuota` keep allocations/reservations in GenServer in-memory maps initialized empty by `init/1`. The inspected modules do not load a durable reservation journal or reconcile their state against the actual active world processes on startup. If a manager restarts while worlds survive, its counters can reset without evidence that those worlds stopped or their reservations were rebuilt.

**Impact:** Admission decisions can be made from incomplete accounting after a manager restart. This is a potential quota bypass / resource overcommit scenario, not an observed production incident.

**Closure evidence:** either supervise managers so a restart safely terminates dependent worlds before admission resumes, or persist reservation state and reconcile it against monitored live world identities before accepting new spawns. Test manager restart with active worlds, stale reservations, duplicate recovery, and manager restart during termination.

#### RL-35 — Memory release is asynchronous and reports no completion to its caller

**Status: Source-confirmed.** `MemoryManager.release_memory/2` uses `GenServer.cast/2`; callers cannot observe whether the release was processed. The handler clamps usage at zero but writes a zero-valued entry rather than deleting the reservation. The supervisor's termination path can therefore log completion before the accounting update is applied.

**Impact:** Cleanup cannot currently use the release call itself as a completion barrier. Retained zero entries may also make world-count/status metrics misleading.

**Closure evidence:** use a result-bearing release operation with validation, idempotency, and an acknowledgement; remove completed reservations; verify total memory equals the sum of active reservations after every lifecycle transition.

#### RL-36 — Garbage-collection accounting is simulated rather than tied to actual reclaimed memory

**Status: Source-confirmed.** `MemoryManager.handle_cast({:trigger_gc, ...})` reduces its tracked usage by a fixed estimated fraction (30%); emergency GC subtracts 50% from every world's tracked usage. The source comments explicitly describe this as simulated reduction and do not demonstrate an actual BEAM/process garbage-collection measurement or memory reclamation result.

**Impact:** The manager can report lower memory consumption without evidence that physical/runtime memory was freed. Subsequent admission and pressure decisions may be based on fictional capacity.

**Closure evidence:** distinguish estimates from measured values; obtain supported per-process/runtime memory measurements and invoke real GC only where appropriate; never reduce reserved capacity solely because an assumed percentage was freed. Test against actual process memory measurements and preserve uncertainty.

#### RL-37 — Snapshot creation does not capture authoritative world state

**Status: Source-confirmed.** `WorldFreeze.capture_world_state/1` explicitly returns a placeholder map with empty agents, coalitions, and event log, empty CAL/CIS parameters, and `random_seed: 0`; its comments say querying the world's GenServer is future work. `create_snapshot/2` stores that structure and returns a snapshot ID as if creation succeeded. `restore_world_state/2` only logs the lengths of agents and coalitions; it does not send restored state to a world process. Snapshot restore returns `:ok` after invoking that placeholder helper.

**Impact:** The exposed API can produce and restore snapshot-shaped data without preserving or restoring the actual world. Such snapshots must not be treated as valid recovery points or archaeological/historical evidence.

**Closure evidence:** define a versioned snapshot contract, capture an atomic authoritative state from the exact world process, validate completeness/checksums, persist it, restore through an acknowledged world-state API, and verify restored state by round-trip comparison. Missing world/state must return an error, not an empty snapshot.

#### RL-38 — Replay startup is asynchronous and the replay source is removed on stop

**Status: Source-confirmed.** `DeterministicReplay.start_recording/2` sends a cast and returns immediately, so `spawn_world/1` can proceed without acknowledgement that recording was initialized. The recording is stored only in the GenServer's in-memory `recording_worlds` map. `stop_recording/1` removes that map entry and returns only event count, duration, and seed; `start_replay/1` reads from the active-recording map, so the normal stop path removes the source that the replay-start function looks up. Export/import are separate file operations and are not automatically part of stop.

**Impact:** A world may start before recording readiness is confirmed; recording state is lost on manager restart; and a stopped recording cannot be replayed through the shown normal in-memory path unless it is re-imported or other code reconstructs it. The documented deterministic-replay guarantee is not established by this implementation alone.

**Closure evidence:** make recording initialization synchronous and result-bearing; finalize recordings into a durable immutable artifact; separate active sessions from finalized recordings; verify event ordering, seed/input completeness, restart recovery, and replay equivalence with end-to-end tests. Label replay as unsupported until these gates pass.

#### Checkpoint 8 disposition

The source confirms that lifecycle accounting is volatile, memory release is unacknowledged, GC accounting is simulated, snapshots are placeholders rather than authoritative state, and replay readiness/finalization is not a durable acknowledged lifecycle. These findings increase the priority of the existing RL-31/RL-32 termination/spawn work: fixing call ordering alone will not provide trustworthy resource or recovery semantics. All findings remain open pending implementation and runtime verification. Only the audit ledger was updated.


### Resource lifecycle evidence checkpoint 9 — cross-component identity and lifecycle ownership

**Audit target:** immutable application SHA `e71bc230a8d38f3a0108012685ae1a052d195b00`. Read-only source trace of `multi_world/world_supervisor.ex`, `world_registry.ex`, `multi_world/resource_quota.ex`, `multi_world/memory_manager.ex`, `multi_world/world_freeze.ex`, `multi_world/deterministic_replay.ex`, `world_fork_engine.ex`, `world_registry_supervisor.ex`, and `application.ex`. No source code was changed and no runtime tests were run.

#### RL-39 — WorldForkEngine child creation cannot preserve the requested child identity and can leave an orphan registry entry

**Status: Source-confirmed; runtime outcome untested.** `WorldForkEngine.create_child_world/2` generates `child_world_id = "W-#{UUID.uuid4()}"`, embeds it in `child_config.id`, and passes the config to `WorldRegistry.create_world/2`. But `WorldRegistry.handle_call({:create_world, ...})` unconditionally generates a new `"W-#{UUID.uuid4()}"` and does not use `config.id`. The fork engine then pattern-matches the returned ID against the originally generated ID (`{:ok, ^child_world_id}`). Those independently generated UUIDs cannot ordinarily match. The registry has already inserted and counted the new world before the match fails, so the fork path can return an error while leaving an active registry record that was never attached to a runtime child. The identity invariant is broken at the registry boundary.

**Impact:** fork results, registry metadata, lineage, and actual runtime process identity can diverge. Registry active counts can include worlds that were not successfully started; the source path has no rollback for the inserted record.

**Closure evidence:** have the registry allocate the canonical ID and pass that exact ID to all subsequent operations, or validate/reserve a caller-supplied ID atomically. Make creation transactional across registry insertion, quota admission, memory reservation, and process start; on any failure, roll back only successfully acquired resources and mark no world active. Add an end-to-end fork test asserting returned ID = registry ID = process config ID = quota key = memory key, plus injected failures after every stage.

#### RL-40 — Registry-created worlds and MultiWorld-spawned worlds use incompatible identity namespaces and independent lifecycle paths

**Status: Source-confirmed.** `WorldRegistry.create_world/2` generates IDs of form `W-<UUID>` and maintains its own `worlds`, `lineage`, and `active_count`. Independently, `MultiWorld.WorldSupervisor.spawn_world/1` generates `world_<millisecond>_<random>`, reserves quota under that second ID, allocates memory under it, starts replay under it, and uses it as the child-process config ID. The inspected creation path does not register the spawned process in `WorldRegistry`, and registry creation does not reserve quota/memory or start a process. The two mechanisms therefore do not share a canonical world identity or one authoritative lifecycle transaction.

**Impact:** separate components can disagree about whether a world exists, is active, is counted, or has a live process. A world created through one API is not necessarily addressable through the other APIs; status and capacity reports are not a unified inventory. This is an architectural/source finding, not a measured production incident.

**Closure evidence:** define one world-creation entry point and one canonical ID contract; connect registry metadata, lineage, process PID/monitor, quota reservation, memory reservation, freeze/replay, and termination to that identity. Expose a reconciliation report that compares all components and fails closed on mismatches. Test create/fork/spawn/kill/restart paths and assert each component's view converges to the same world state.

#### RL-41 — Per-world fork orchestration attempts to start a globally named WorldSupervisor as if it were an independent child

**Status: Source-confirmed design conflict; exact runtime error untested.** `WorldSupervisor.start_link/1` starts its GenServer with the global registered name `TiannaraRuntime.MultiWorld.WorldSupervisor`. `WorldForkEngine.spawn_world_supervisor/1` attempts to start that same module under `TiannaraRuntime.WorldRuntimeSupervisor` for a world config. If this path is reached while the global supervisor is already running, another instance cannot register under the same name; additionally, the global supervisor owns its own named DynamicSupervisor and a map of child PIDs rather than being a per-world process. The call also logs a start failure but returns `:ok` from `create_child_world/2`'s caller path, since `spawn_world_supervisor/1`'s return value is ignored.

**Impact:** per-world fork startup cannot reliably create an independent supervisor tree, and even a child-start failure can be reported by the fork path as success if the preceding registry-ID pattern were corrected. This compounds RL-39/RL-40; it is not proof that this code path currently succeeds, because RL-39's ID mismatch normally prevents reaching it.

**Closure evidence:** separate the singleton multi-world coordinator from a per-world worker/supervision subtree; avoid registering every per-world supervisor under one global name; propagate every child-start result and roll back registry/lineage changes on failure. Test two simultaneous worlds and a fork while the coordinator is already running.

#### Checkpoint 9 disposition

Checkpoint 9 confirms that cross-component identity is not yet a single enforced invariant: registry creation and runtime spawn generate different ID forms, fork creation ignores the caller's proposed ID and pattern-matches against a second generated UUID, and fork orchestration attempts to instantiate a globally named coordinator as a per-world child. These findings are source-confirmed at the frozen SHA. Runtime confirmation, regression tests, and remediation remain outstanding. Earlier RL-11 invalid GenServer cast callback contracts and RL-28 repeated termination accounting remain open and materially affect any future lifecycle test; they were not duplicated as new findings here. Only the audit ledger was updated.


### Resource lifecycle evidence checkpoint 10 — snapshots, persistence, replay, and recovery

**Audit target:** immutable application SHA `e71bc230a8d38f3a0108012685ae1a052d195b00`. Read-only inspection of `multi_world/world_freeze.ex`, `multi_world/deterministic_replay.ex`, `multi_world/world_supervisor.ex`, `multi_world/memory_manager.ex`, and `multi_world/resource_quota.ex`. No application source was modified and no runtime tests were run. Existing RL-34, RL-37, and RL-38 remain open; the findings below record distinct persistence and recovery consequences rather than closing or duplicating those findings.

#### RL-42 — Snapshot import is not compatible with downstream atom-key access

**Status: Source-confirmed; runtime crash not reproduced.** `WorldFreeze.import_snapshot/1` parses JSON with `Jason.decode/1`, which yields string-keyed maps, then stores that decoded map directly in `frozen_worlds`. Later paths such as `get_snapshot_info/1` access `snapshot.world_id`, `snapshot.created_at`, and `snapshot.metadata`; `list_snapshots/1` accesses `snapshot.created_at` and `snapshot.metadata`; and `restore_snapshot/2` passes decoded `snapshot.state` to `restore_world_state/2`, which accesses `state_data.agents` and `state_data.coalitions`. Those atom-key field accesses are incompatible with the string-keyed imported JSON object. The restore helper is also only logging, not applying state (RL-37).

**Impact:** an imported snapshot cannot be treated as a reliable round-trip artifact; metadata/list/restore operations can raise on missing atom keys and crash the GenServer instead of returning a typed error.

**Closure evidence:** define and validate a versioned snapshot schema, normalize keys at the import boundary, return typed errors for invalid/mismatched payloads, and test create → export → fresh manager → import → list/info → restore with the actual world state compared byte-for-byte or by canonical state hash.

#### RL-43 — Snapshot identity is timestamp-based and target-world ownership is not checked

**Status: Source-confirmed.** Snapshot IDs are generated as `snap_<world_id>_<millisecond timestamp>`; the map write replaces an existing value at the same key. The restore handler checks only whether the snapshot ID exists and does not verify that the snapshot's recorded `world_id` matches the requested target `world_id`. It then returns `:ok` after invoking the non-restoring helper.

**Impact:** snapshots created within the same millisecond for one world can overwrite each other, and the API does not enforce ownership/compatibility between a snapshot and target world. Because restoration is currently a no-op, a successful return is not evidence of rollback.

**Closure evidence:** use collision-resistant IDs, bind snapshot to canonical world identity and schema/version, reject mismatched targets, and test concurrent/rapid snapshot creation plus cross-world restore attempts. Return success only after the target state is confirmed restored.

#### RL-44 — Stopping a recording destroys the active replay/export source

**Status: Source-confirmed.** `stop_recording/1` removes the recording from `recording_worlds` via `Map.pop/2` and returns only event count, duration, and seed. Both `start_replay/1` and `export_recording/2` subsequently look up the recording in that same map, so the normal stop operation leaves neither API able to retrieve that recording unless it was exported beforehand or recreated/imported separately.

**Impact:** the expected record → stop → replay/export workflow is not supported by the source implementation. The metadata returned at stop is insufficient to reconstruct the event history.

**Closure evidence:** separate active recording state from finalized immutable recordings; make stop atomically finalize and retain the recording or return a durable artifact/reference. Test record → stop → export → import → replay, including empty and maximum-length recordings.

#### RL-45 — Replay advances a cursor but does not apply events to a world

**Status: Source-confirmed.** `step_replay/1` retrieves the next event and returns it to the caller while incrementing `current_step`; the inspected implementation does not dispatch that event to the target world process, re-run world transition logic, verify expected state hashes, or compare resulting state against the original. The module documentation's deterministic replay guarantee is therefore not established by this implementation alone.

**Impact:** this is an event-log reader/cursor, not yet evidence of deterministic world reconstruction. Identical outcomes, timing fidelity, and state equivalence remain unproven.

**Closure evidence:** define the replay execution contract, apply each event through the same authoritative transition path used by live execution, control/record all nondeterministic inputs, and compare per-step/final canonical state hashes against a known run. Include divergence detection and tests across process restart.

#### RL-46 — Snapshot and recording persistence is optional export, not automatic durable recovery

**Status: Source-confirmed.** Both modules initialize their snapshot/recording maps empty in `init/1`. Their ordinary create/start paths store data only in GenServer memory. File export is a separate explicit operation, and the inspected code has no automatic journal/checkpoint or startup recovery path for these maps. The same volatile-state concern applies to quota/memory managers already recorded in RL-34.

**Impact:** restarting a manager loses in-memory snapshots, snapshot history, active recordings, and replay state unless an external caller separately exported and re-imported artifacts. No automatic consistency protocol reconciles restored world processes with these managers.

**Closure evidence:** specify the durability boundary and recovery owner; persist finalized snapshots/recordings and required active metadata transactionally; implement startup validation/reconciliation; test manager-only restart and whole-application restart with checks that IDs, histories, seeds, events, and state hashes remain consistent.

#### Checkpoint 10 disposition

Checkpoint 10 confirms that the current source does not provide a trustworthy snapshot/restore/replay recovery contract: snapshots contain placeholder state and restoration does not mutate the world (RL-37); imported JSON maps are incompatible with atom-key access (RL-42); snapshot IDs and target ownership are insufficiently guarded (RL-43); stopping recording removes the replay/export source (RL-44); replay only returns events rather than applying them (RL-45); and persisted recovery is not automatic (RL-46). These are source-confirmed findings at the frozen SHA. Runtime behavior, crash reproduction, recovery round trips, and regression tests remain outstanding. Only the audit ledger was updated.


### Resource lifecycle evidence checkpoint 11 — boot graph, supervision, and activation

**Audit target:** immutable application SHA `e71bc230a8d38f3a0108012685ae1a052d195b00`. Read-only source inspection of `TiannaraRuntime.Application`, `TiannaraRuntime.StartupSupervisor`, `TiannaraRuntime.RootSupervisor`, `TiannaraRuntime.BootPolicy`, `TiannaraRuntime.WorldRegistrySupervisor`, `TiannaraRuntime.WorldSupervisor`, `WorldFreeze`, `DeterministicReplay`, and `DiscoveryRunner`. No application source was modified and no runtime tests were run.

#### RL-47 — Multi-world registry supervisor is not wired into the inspected runtime boot graph

**Status: Source-confirmed in the inspected startup definitions.** `TiannaraRuntime.WorldRegistrySupervisor` defines children for `WorldRegistry` and `WorldRuntimeSupervisor`, but it is absent from the child lists in `TiannaraRuntime.Application`, `TiannaraRuntime.StartupSupervisor`, and `TiannaraRuntime.RootSupervisor` at the audit SHA. The runtime application explicitly adds `WorldSupervisor`, but does not add `WorldRegistrySupervisor` in the same list.

**Impact:** the registry and runtime DynamicSupervisor documented by the Phase 5A architecture are not guaranteed to be running as part of these declared boot graphs. Registry-dependent code can therefore encounter missing-process/registry conditions unless another, separately invoked startup path provisions them. Documentation of a supervisor module is not proof it is activated.

**Closure evidence:** identify one canonical application owner for the multi-world subsystem, include the registry and its required children in that supervised tree, and test a clean full application boot by asserting the registered processes and child tree—not merely module loadability.

#### RL-48 — WorldSupervisor starts its DynamicSupervisor inside GenServer initialization rather than as an explicit supervisor child

**Status: Source-confirmed.** `TiannaraRuntime.MultiWorld.WorldSupervisor.init/1` calls `DynamicSupervisor.start_link/2` and stores the returned PID in GenServer state. The DynamicSupervisor is linked to the GenServer but is not declared as a child in the application supervisor tree. A coordinator restart consequently does not preserve the coordinator's in-memory `worlds` map; the nested DynamicSupervisor's lifecycle is coupled to that GenServer rather than represented as a separately supervised sibling/child contract.

**Impact:** restarting the coordinator can terminate its linked DynamicSupervisor and its worlds, while a restart of the coordinator alone does not reconstruct world-to-PID tracking or reconcile quota, memory, registry, freeze, and replay state. The existing `:one_for_one` application-level strategy does not itself supply that recovery protocol.

**Closure evidence:** model the coordinator and world DynamicSupervisor in an explicit supervision tree with intentional restart semantics; monitor/reconcile world processes and resource reservations after restarts; test coordinator crash, DynamicSupervisor crash, and whole-subtree restart with multiple live worlds.

#### RL-49 — WorldSupervisor is activated without its required multi-world service dependencies being explicitly activated alongside it

**Status: Source-confirmed in the inspected boot lists.** `TiannaraRuntime.Application` adds `WorldSupervisor` as an optional child, but its declared children do not add `ResourceQuota`, `MemoryManager`, `WorldFreeze`, or `DeterministicReplay`. `TiannaraRuntime.RootSupervisor` lists only Infrastructure, Execution, Ecology, and (depending on profile) Constraint/Meta authority supervisors; it contains no multi-world lifecycle service child. Yet `WorldSupervisor.spawn_world/1`, `get_status/0`, `freeze_world/1`, and termination paths call those named services. `BootPolicy.optional_child/2` checks whether a module can be loaded; it does not check that its runtime dependencies are started.

**Impact:** a successful boot of the coordinator does not establish that its spawn, status, freeze, replay, or cleanup APIs can run. Missing registered GenServers can cause exits such as `:noproc`; `Process.whereis/1` guards in some cleanup paths merely skip operations and do not restore a coherent lifecycle. This is a source-level activation gap; no runtime failure is claimed as reproduced.

**Closure evidence:** declare dependencies and startup ordering in one supervisor tree; distinguish optional module availability from required service readiness; fail boot or expose an explicit degraded capability when mandatory dependencies are absent. Add clean-boot integration tests invoking each advertised lifecycle API.

#### RL-50 — DiscoveryRunner's scheduled cycles record synthetic research artifacts rather than executing the autonomous experiment pipeline

**Status: Source-confirmed; runtime behavior not tested.** `TiannaraRuntime.StartupSupervisor` includes `TiannaraRuntime.DiscoveryRunner` as a child, so this runner is activated by that boot path. Its `handle_info(:discovery_cycle, ...)` describes challenge execution as simulated and calls `record_observation/1`, `record_hypothesis/1`, and `record_experiment/1`, then increments `cycle_count`. In the inspected cycle handler it does not call `Tiannara.ASC.AutonomousDiscovery.run_discovery_cycle/1` or `Tiannara.Agency.ResearchDirector.investigate/2`, nor does it invoke a domain simulator/validator and gate a discovery on experimental evidence. Separately, the autonomous-discovery module is not a child of the inspected runtime boot graph.

**Impact:** a running timer and increasing cycle count can be mistaken for autonomous scientific research, while the scientific execution/validation pipeline remains a separate, unproven path. This does not invalidate the existence of research code; it means the scheduled runner's activity is not evidence that real hypotheses were experimentally tested or discoveries established.

**Closure evidence:** wire a bounded research-cycle worker to the intended hypothesis → experiment → simulation → independent validation → provenance/persistence pipeline; record explicit unavailable/rejected/timeout outcomes without success-shaped artifacts; and test that a cycle's persisted discovery can be traced to actual execution and validation evidence.

#### Checkpoint 11 disposition

Checkpoint 11 finds a split activation model: the runtime application starts the multi-world coordinator without explicitly starting its registry, quota, memory, snapshot, and replay dependencies; the separate startup supervisor starts the DiscoveryRunner, whose timed cycles record simulated artifacts rather than calling the autonomous discovery pipeline. The world coordinator also owns a linked DynamicSupervisor outside an explicit supervisor child tree. These are source-confirmed boot-graph findings at the frozen SHA; startup integration, process-crash behavior, and end-to-end research execution remain untested. Only the audit ledger was updated.


### Resource lifecycle evidence checkpoint 12 — autonomous research, hypotheses, experiments, evidence, and discovery

**Audit target:** immutable application SHA `e71bc230a8d38f3a0108012685ae1a052d195b00`. Read-only source inspection of the Agency, ASC AutonomousDiscovery, canonical/domain research registry, and Artifact 13 `Tiannara.Research.ResearchDirector` pathways, including their supervisors, experiment sandbox, physics domain, hypothesis ranker, experiment planner, evidence scorer, knowledge integrator, and research queue. No application source was modified and no runtime tests were run.

#### RL-51 — Agency heartbeat-to-investigation pipeline is not activated by the main application supervisor

**Status: Source-confirmed.** `Tiannara.Agency.Supervisor` owns `Agency.Orchestrator`, `Agency.ResearchDirector`, and `Agency.SentinelHeartbeat`, and the heartbeat emits events to that orchestrator. However, `Tiannara.Application.core_children/0` does not include `Tiannara.Agency.Supervisor`. It includes `Tiannara.ASC.Agency.Sentinel`, which is a separate GenServer and calls `Tiannara.ASC.Agency.Orchestrator`, not `Tiannara.Agency.Orchestrator`. The two similarly named agency paths must not be treated as one connected pipeline.

**Impact:** the Agency heartbeat → event → hypothesis → experiment pathway is not established as an automatically running main-application capability by the inspected boot graph. Its modules and unit-level APIs exist, but this is not proof that this particular loop runs in production.

**Closure evidence:** choose and document the canonical agency pipeline, wire its supervisor into the application with declared dependencies, remove/bridge duplicate agency entry points explicitly, and test a clean application boot followed by a real heartbeat event reaching the intended research worker.

#### RL-52 — Agency experiment sandbox fabricates randomized outcomes and evidence instead of executing the experiment design

**Status: Source-confirmed.** `Tiannara.Agency.Sandbox.run_experiment/1` sleeps for 10 ms, generates success probability and success/failure from `:rand.uniform/0`, fabricates metric deltas/resource consumption, and creates three evidence items with random quality and contradiction flags. It does not inspect or execute the experiment's methodology, variables, controls, success criteria, failure conditions, or rollback plan against a simulator or real execution target. `available?/0` unconditionally returns true.

**Impact:** the Agency ResearchDirector can turn random values into an apparent experiment result, evidence strength, recommendation, confidence update, and knowledge record. These outputs are synthetic fixtures, not observations from the designed experiment. A true `available?` result is not a capability/readiness check.

**Closure evidence:** make the sandbox fail closed unless an explicit execution adapter is available; bind execution to the experiment specification and a declared simulation/real-execution mode; label fixture data as synthetic; and prove that results are derived from captured runs with reproducible inputs, outputs, and provenance.

#### RL-53 — Artifact 13 research pipeline intentionally stops at experiment planning and quarantines execution

**Status: Source-confirmed; intentional R0 safety boundary, not a false claim of execution.** `Tiannara.Research.ResearchDirector.Pipeline` accepts priorities, asks `HypothesisRanker` to generate/rank hypotheses, and queues them. On an `:advance` it plans an experiment and queues it; on the next `:advance` it calls `quarantine_experiment/1`, emits telemetry stating `:quarantined_by_R0` / `:fabrication_path_disabled`, and does not execute it. The pipeline's initialization log explicitly says fabricated experiment execution is disabled. It does not call `EvidenceScorer.score/2` or `KnowledgeIntegrator.integrate/3` in this path.

**Impact:** this pipeline currently provides priority ingestion, hypothesis generation/ranking, and experiment planning, but not an end-to-end research cycle or new validated knowledge. This is an honest fail-closed boundary. Its status/health counters must not be interpreted as completed experiments or discoveries.

**Closure evidence:** retain quarantine until a real, independently auditable execution adapter exists; then add an explicit execution lifecycle, evidence scoring over actual observations, validation gates, and knowledge integration that accepts only eligible provenance. Tests must prove the quarantine path cannot create completed/validated knowledge and that unavailable execution remains visibly quarantined.

#### RL-54 — EvidenceScorer's current metrics are heuristic placeholders, not statistical/reproducibility analysis

**Status: Source-confirmed; currently downstream of the quarantined execution path.** `EvidenceScorer.compute_evidence/2` assigns reproducibility as fixed 0.8 for three or more observations, 0.5 for one or two, and 0.2 for none; consistency is fixed 0.75 whenever any observations exist; and effect size is the arithmetic mean of `obs[:value]` divided by 100 and capped at 1.0. It does not compare independent run identities, estimate variance/uncertainty, test statistical significance, calculate a normalized effect size, or perform a falsification analysis. `falsification_attempted` is set from whether the experiment has any `failure_criteria` field, not whether a falsification attempt actually ran.

**Impact:** if this scorer is later connected without replacement, its confidence score can look quantitative while not measuring the documented properties. Current R0 quarantine prevents the ordinary ResearchDirector pipeline from feeding it experiment outcomes, but the public scorer API remains callable.

**Closure evidence:** define evidence schemas for actual repeated runs and controls; compute reproducibility from independent execution records, consistency from observed distributions, effect size with a declared baseline/scale, and falsification from recorded attempts/results. Keep unknown or insufficient samples explicitly unscored rather than assigning reassuring constants.

#### RL-55 — Canonical 20-domain registry is not connected to the separate domain ResearchDirector registry

**Status: Source-confirmed.** `Tiannara.Domains.CanonicalRegistry` initializes the 20 canonical domain records and maps them to domain modules. The separate `Tiannara.Domains.ResearchDirector` maintains its own domain map and exposes `register_domain/1`; its `init/1` starts with an empty map. The inspected main application starts both the canonical registry and this ResearchDirector, but no registration/bridge call is present in the inspected startup code or the inspected registry module. Its `discover/2`, `evaluate/2`, and `get_all_metrics/0` therefore operate against a separately maintained registry that is not populated by canonical registry initialization.

**Impact:** the existence of 20 canonical domain bindings does not mean the domain ResearchDirector can dispatch research across them. The two registries can disagree, and domain-level dispatch can return `{:error, :domain_not_found}` despite canonical module metadata existing.

**Closure evidence:** use one authoritative domain registry or add a deterministic boot-time registration adapter with validation; assert all expected domains are registered and that dispatch/metrics work for each supported domain after clean boot.

#### RL-56 — ASC AutonomousDiscovery is a bounded callable physics pilot, not a continuously autonomous 20-domain research service

**Status: Source-confirmed; execution not run in this checkpoint.** `Tiannara.ASC.AutonomousDiscovery.run_discovery_cycle/1` has a bounded experiment execution path: it collects metrics from canonical domain records, checks the bottleneck detector, selects a candidate, runs the domain module's `simulate/2` and `validate/1` under a timeout, and can persist a provenance-bearing fact or record a rejection. However, its default candidate list is hard-coded to a Physics damped-oscillator pilot and one Chemistry candidate; it does not derive experiment candidates from all 20 canonical domain modules. The optimizer selects by declared `domain_weight` only. The inspected application child lists do not start a worker/scheduler invoking `run_discovery_cycle/1`; it is a callable function, not a demonstrated continuous world-driven research loop. Physics validation is explicitly `:structural_checks`, not formal verification, and the result provenance is `:simulation`.

**Impact:** this is meaningful bounded simulation/research infrastructure, stronger than the synthetic DiscoveryRunner, but it does not establish autonomous scientific discovery across 20 domains or empirical/real-execution discoveries. A successful structural simulation result should be described as a simulation-backed finding with its verification limits, not as experimentally established real-world knowledge.

**Closure evidence:** retain the pilot's explicit identity, timeout, failure, rejection, and provenance behavior; wire a controlled research scheduler/trigger only after startup dependencies are explicit; build candidate generation from actual domain capabilities rather than a fixed two-item list; and report each result with simulation/real-execution provenance and verification level. Add per-domain execution tests and a complete boot-to-discovery-to-persisted-evidence test.

#### Checkpoint 12 disposition

Checkpoint 12 distinguishes four different capability levels. The Agency loop is not activated by the main application and its sandbox fabricates random experiment outcomes (RL-51/RL-52). Artifact 13 ResearchDirector generates and plans hypotheses/experiments but deliberately quarantines execution under R0, so no validated knowledge is produced by that path (RL-53). Its evidence scorer is heuristic and would need redesign before use (RL-54). The canonical 20-domain registry is not bridged into the separate domain ResearchDirector (RL-55). ASC AutonomousDiscovery has a bounded simulation/structural-validation pilot with provenance and persistence paths, but its default candidates and activation are not a 20-domain continuous research system (RL-56). These are source-confirmed findings at the frozen SHA; no runtime execution, statistical validation, full-cycle experiment, or production discovery was tested. Only the audit ledger was updated.


### Resource lifecycle evidence checkpoint 13 — civilization history, durable material remains, discovery, and excavation

**Audit target:** immutable application SHA `e71bc230a8d38f3a0108012685ae1a052d195b00`. Read-only source inspection of the archaeological modules, REA evolutionary-ruin model and registry, SOPL law archaeology, Sentinel civilizational epistemology archive, Phase 22 civilizational ontology specification, and multi-world state/timeline runtime. No application source was modified and no runtime tests were run.

#### RL-57 — Civilizational ontology and archaeological reconstruction are specified but explicitly have no runtime implementation

**Status: Source-confirmed.** `tiannara_runtime/priv/certification/phase22/CIVILIZATIONAL_ONTOLOGY_ARCHITECTURE.md` defines a rich hierarchy from Universe/Planet/Civilization through Institution, Infrastructure, Program, Project, Process, Capability, Artifact, Observation, and Evidence. It describes civilization identity, epoch, population, knowledge state, energy profile, infrastructure, material resources, technology, culture, and provenance. Its acceptance criteria include replayable ontology evolution and archaeological reconstruction. Crucially, the specification itself states: **“No runtime implementation exists.”**

**Impact:** this is a design target, not evidence that simulated civilizations currently create durable settlements, buildings, infrastructure, tools, material culture, or artifact-bearing sites. The desired civilizational substrate is not established by the ontology document.

**Closure evidence:** implement the ontology as runtime entities with stable identity and explicit relations; connect civilization actions and world transitions to versioned artifact/observation/evidence records; demonstrate that the resulting state is actually simulated, persisted, replayed, and queryable. Keep the specification status distinct from implementation status.

#### RL-58 — The implemented “archaeology” registries preserve evolutionary software ruins, not excavatable civilizational sites

**Status: Source-confirmed.** `Tiannara.REA.EvolutionaryRuin` represents a collapsed evolutionary organism using organism identity/type, fitness, collapse reason, pressure vector, epoch, ancestry depth, and optional trait-fossil metadata. `Tiannara.REA.ArchaeologyRegistry` stores these records in a GenServer list initialized empty and capped at 10,000 entries; the inspected implementation has no durable storage, site coordinates, geological/material strata, artifact inventory, excavation process, or independent explorer-discovery interface. `Tiannara.SOPL.LawArchaeology` separately stores failed law-genome records in an in-memory list. These are useful evolutionary/failure-history mechanisms, but they are not physical archaeology.

**Impact:** a later simulated civilization cannot, through these inspected interfaces, locate a buried settlement, inspect stratigraphy, excavate an object, associate it with a context, or reconstruct the originating civilization from material remains. A stored software/evolutionary ruin must not be counted as a discovered archaeological site.

**Closure evidence:** introduce a distinct civilizational archaeology domain: persistent site/stratum/deposit/artifact models; spatial and temporal context; preservation/degradation and disturbance; excavation observations and chain of custody; and provenance back to originating world/civilization/epoch/events. Connect discovery to exploration rather than direct access to the archive. Preserve REA/SOPL evolutionary archaeology as a separate capability.

#### RL-59 — Civilizational collapse archive is volatile and its recorded outcome contains hardcoded values

**Status: Source-confirmed.** `Tiannara.Sentinel.EpistemologyArchive` records civilization collapse in a GenServer list initialized empty. On collapse it retrieves the civilization's known discoveries, but constructs an `EconomicOutcome` with fixed values including `prediction_accuracy: 0.1`, `acm_survival_rate: 0.0`, `disease_resistance: 0.0`, `fitness_score: 0.0`, `continuity_score: 1.0`, `age: 100`, and zero energy/compute values. It then computes a collapse signature and stores an `EpistemologyRecord`. The archive's inspected code has no durable journal or world-history reconstruction path.

**Impact:** there is a civilizational collapse/epistemic memory concept, but its record is not a complete, evidence-derived account of the civilization's historical life. Several recorded metrics are assigned constants rather than measured from a historical trajectory, and the in-memory archive does not establish survival across process restart. It cannot substitute for a material archaeological record.

**Closure evidence:** source every collapse field from recorded civilization state and event history; explicitly mark unavailable fields UNKNOWN rather than filling constants; preserve immutable event/record provenance and durable storage; and verify reconstruction from the archived event sequence after restart.

#### RL-60 — Per-world runtime timeline is bounded volatile telemetry, not a durable civilization history

**Status: Source-confirmed.** `TiannaraRuntime.WorldMemoryStore` initializes each world's snapshots as an empty list, retains at most 10,000 entries, and stores them only in GenServer memory. The inspected `WorldSimulationLoop` appends a small snapshot containing CAL result, CIS result, and an Erlang unique integer timestamp; it does not capture a complete world transition, civilization/institution/infrastructure/artifact state, historical event chain, or archaeology deposit. The loop's `update_world_state/3` and `publish_events/3` helpers only log in the inspected implementation. This compounds the earlier WorldFreeze finding RL-37: its capture helper returns empty agents/coalitions/event log and default parameters, while restore only logs counts.

**Impact:** the presence of an append-only in-process snapshot API does not establish deep-time historical persistence. On process restart, the inspected store's history is reinitialized; after 10,000 entries, older snapshots are dropped. The stored CAL/CIS result samples do not contain the material/cultural evidence required for later independent excavation. No cross-restart or cross-world historical survival guarantee is established.

**Closure evidence:** create an authoritative, durable, append-only world event/history journal with stable event IDs, world/civilization/epoch identity, causal links, and schema/version metadata; persist full relevant state transitions or verifiable state deltas; define retention/archive policy without silent loss; and test restart recovery, long-horizon history, and later-world access under explicit permissions.

#### Checkpoint 13 disposition

The inspected code does not establish the requested civilization-to-civilization archaeological lifecycle. There is an explicit civilizational ontology specification, but it says runtime implementation does not exist (RL-57). Existing archaeology is primarily evolutionary/software failure archival rather than physical site discovery and excavation (RL-58). The civilizational collapse archive is volatile and uses hardcoded outcome fields (RL-59). The multi-world timeline stores bounded in-memory CAL/CIS snapshots rather than durable civilization history or material remains (RL-60). The previously inspected FossilExcavator and SemanticReconstructor remain fail-closed as recorded in the earlier audit. These are source-confirmed findings at the frozen SHA; no runtime archaeology experiment, cross-world discovery, excavation, or persistence test was performed. Only the audit ledger was updated.


### Resource lifecycle evidence checkpoint 14 — cross-system integration and capability verification

**Audit target:** immutable application SHA `e71bc230a8d38f3a0108012685ae1a052d195b00`. Read-only inspection of both OTP application entry points, runtime world tick and lifecycle services, canonical domain registry, observatory API routes/controllers, and the CIS kill execution path. No application source was modified and no runtime tests or HTTP integration tests were run.

#### RL-61 — Tiannara core and TiannaraRuntime have separate boot graphs without a demonstrated unified runtime contract

**Status: Source-confirmed separation; end-to-end bridge unverified.** `Tiannara.Application` starts the core civilization kernel, REL, OMCS, Sentinel, domain/research services, CEL, ASC (feature-flagged), and other core services. `TiannaraRuntime.Application` separately starts `TiannaraRuntime.StartupSupervisor`, its own runtime layers, and selected multi-world safety components. The runtime StartupSupervisor owns CPL, Omega, Observatory, Endpoint, RootSupervisor, and DiscoveryRunner. These are distinct OTP application/supervision graphs with different service registries and startup contracts. The inspected files do not establish a single cross-application readiness handshake or prove that core civilization/research services and the multi-world runtime share one canonical world/civilization state and lifecycle.

**Impact:** the existence of both applications and their supervisors is not evidence that a live world can invoke core civilization/research capabilities and receive durable, observable outcomes through one coherent runtime. Integration must be demonstrated across the actual process and service boundaries, not inferred from module presence or similarly named components.

**Closure evidence:** publish an explicit system context and dependency graph; define canonical world/civilization IDs and service contracts across the two applications; establish startup dependency/readiness checks and failure propagation; and run a clean combined boot test that creates a world, advances it, invokes a core capability, persists the result, and retrieves the same provenance through the observatory.

#### RL-62 — WorldSimulationLoop's advertised state-update and event-publication stages are logging placeholders

**Status: Source-confirmed.** `TiannaraRuntime.WorldSimulationLoop.execute_tick/1` calls CAL, CIS, `update_world_state/3`, `publish_events/3`, and `store_memory_snapshot/3`. The inspected implementations of `update_world_state/3` and `publish_events/3` only emit debug log messages; they do not update an authoritative world/civilization state service or publish events to an event bus. The snapshot helper stores only CAL/CIS result values. CAL/CIS lookup paths can also return default results when a world registry entry or state-manager child is missing, allowing the tick to continue with fallback data (overlaps the specific missing-state risk in RL-33).

**Impact:** a successful tick count or “published events” log does not prove a complete world transition, event delivery, or civilization evolution. Downstream research, memory, observability, and archaeology systems cannot safely treat these logs or limited snapshots as authoritative world history.

**Closure evidence:** replace logging placeholders with typed state-transition and event-publication adapters; require acknowledged state commits and event IDs; fail or explicitly mark a tick degraded when its authoritative world state is unavailable; and test that a tick's state change is visible to independent subscribers and durable history readers.

#### RL-63 — Observatory API silently substitutes synthetic data when runtime integration fails

**Status: Source-confirmed.** `tiannara_api/routes/observatory.py` calls the Elixir runtime through `call_runtime_api`, but several read endpoints catch backend exceptions and return generated mock values instead. Examples include node inspector data, predictions, causal chains, meta-control state, timeline snapshots, and universe state; universe fallback generates random agent positions, belief vectors, coherence, entropy, and statuses. The calibration endpoint creates 12 synthetic worlds with randomized metrics and counts, then evolves them through random walks when runtime calls fail. The calibration intervention endpoint applies changes to this local mock store and returns a success-shaped response rather than requiring a runtime acknowledgement.

**Impact:** users and downstream consumers can mistake synthetic state for live Tiannara execution. A runtime outage can make the observatory appear populated and responsive precisely when it should report unavailable or stale evidence. A local mock intervention can be mistaken for a real world intervention. Authentication on the router does not resolve this evidence-integrity problem.

**Closure evidence:** remove mock fallback from production endpoints or expose it only through an explicit, visibly labelled simulation/demo mode with a separate namespace and provenance; return backend-unavailable/stale responses for live views; require runtime acknowledgement and operation IDs for interventions; and test that runtime outage can never yield a live-success response or synthetic live-world record.

#### RL-64 — Observatory runtime health, service status, and boot endpoints contain hardcoded success claims

**Status: Source-confirmed.** `ObservatoryApiWeb.StatusController.index/2` constructs a health response with `status: "operational"` and a set of subsystem statuses. In the same controller file, `RuntimeController.status/2` returns a fixed service map that marks BEAM, PostgreSQL, Redis, NATS, Phoenix, React, vector DB, and telemetry as running while Python workers and Rust kernels are stopped; these values are not obtained from live process/connection checks in the inspected function. `RuntimeController.boot/2` generates a list of boot steps and marks every step `"completed"` with the current timestamp. `start_all/2` and `stop_all/2` return success-shaped messages without performing service orchestration in the inspected implementations.

**Impact:** health and mission-control screens can report operational services and completed boot steps without verifying that those services are available or that boot actions occurred. This compounds RL-63: the observability surface can manufacture both the underlying world data and the system-health narrative.

**Closure evidence:** derive each status from live supervised-process health plus dependency probes and last-success timestamps; distinguish running, ready, degraded, stale, unknown, and unavailable; make boot steps evidence-backed from actual startup events; and make start/stop endpoints either invoke a governed orchestration service with acknowledged results or return unsupported.

#### RL-65 — CIS-authorized kill can be reported as executed when delivery failed, and resource termination is log-only

**Status: Source-confirmed.** `TiannaraRuntime.CIS.ExecutionController.execute_kill/3` asks `CIS.Supervisor.authorize_kill/3`. On approval it calls `deliver_termination_command/1`, which returns false and logs “NOT delivered” if the WorldSupervisor is absent, but the caller still receives `:executed`; the module documentation explicitly defines this as authorized and attempted, not confirmed termination. Separately, `terminate_resource/3` returns `:executed` after authorization while its own documentation and handler state that cleanup is log-only and no resource subsystem is wired to it. The KillSwitch consumes the same result vocabulary and increments its executed counter on `:executed`.

**Impact:** the governance decision, command delivery, and actual effect are conflated in status reporting. A dashboard or caller can interpret `:executed` as a completed kill/resource termination when the command was undelivered or no resource operation occurred. Authorization is necessary but does not prove execution or effect.

**Closure evidence:** use separate result states for `:authorized`, `:delivery_attempted`, `:delivered`, `:effect_confirmed`, `:denied`, and `:escalated`; require an acknowledgement from the target supervisor/resource adapter; record an immutable operation ID and before/after evidence; and ensure counters and UI labels report only the strongest state actually observed.

#### Checkpoint 14 disposition

The integration review finds that the core application and runtime are separate boot graphs with no demonstrated unified lifecycle contract in the inspected entry points (RL-61). The runtime world tick's state-update and event-publication stages are logging placeholders, while missing-state fallbacks can still allow ticks to proceed (RL-62; see also RL-33). The observatory can replace backend failures with synthetic world, timeline, prediction, causal, and calibration data, and can apply local mock interventions (RL-63). Its runtime status and boot endpoints also contain hardcoded service/boot success claims (RL-64). Finally, CIS authorization is not equivalent to delivery or confirmed effect, yet the kill/resource paths can return `:executed` without either (RL-65). Together these findings mean that a successful-looking tick, dashboard, status response, or governance action is not sufficient evidence of a fully integrated operational capability. These findings are source-confirmed at the frozen SHA; no runtime integration, outage, intervention, or kill-delivery tests were performed. Only the audit ledger was updated.


### Checkpoint 15 — Governance, security and constitutional enforcement

**Baseline:** application source inspected at immutable commit `e71bc230a8d38f3a0108012685ae1a052d195b00`. This checkpoint is source inspection only; no runtime tests, authorization bypass attempts, process-restart tests, or adversarial governance campaigns were executed.

#### RL-66 — Constitution repository exposes unauthenticated commit and rollback operations

**Status: Source-confirmed.** `Tiannara.Council.ConstitutionRepository.commit/3` forwards caller-supplied constitution, amendment ID and actor directly to its GenServer. The commit handler inserts the supplied version into DETS and changes `current_version`; it does not call Council authorization, verify a completed amendment/human approval, check hard invariants, validate a signature, or check the result of `:dets.insert/2`. `rollback/2` changes the active version after only checking that the target version exists; its actor is recorded in telemetry/logging but is not authorized. The repository's DETS persistence is real, but persistence is not an authorization boundary.

**Impact:** any code path with access to these public APIs can bypass the intended amendment/human-governance process. Constitutional immutability is therefore a policy/design property, not a demonstrated runtime access-control invariant.

**Closure evidence:** make repository writes accept only a verified, single-use Council-issued amendment authorization bound to the exact old/new constitution hashes and version; verify the human approver's identity and authority; enforce immutable hard-invariant set preservation; fail on storage errors; and adversarially test direct commit/rollback attempts without valid grants.

#### RL-67 — AmendmentEngine approval is not a durable constitutional commit and its approval identity is unverified

**Status: Source-confirmed.** `Tiannara.Council.AmendmentEngine.approve/2` accepts a caller-supplied `human_id` when the amendment reaches `:awaiting_human`. The handler does not authenticate that identity or ask the Council to authorize the approval. It calls `apply_amendment/2`, which only bumps the version, then updates the AmendmentEngine's in-memory `constitution` field. It does not commit through `ConstitutionRepository`. Amendment records and their workflow state are also held in the GenServer's in-memory maps. Its simulation derives a risk score from affected-principle count/invariant flags, and its evaluation marks affected principles strengthened and all others unaffected; neither is independent verification of the proposed semantic changes.

**Impact:** the amendment engine can return an approved, version-bumped constitution that is neither the repository's active constitution nor a durable amendment record. A string passed as `human_id` is not proof of a human identity or authority.

**Closure evidence:** unify amendment and repository state into one atomic transaction; persist proposal, evidence, votes, approver identity and final constitution hash; authenticate approvers and enforce role/quorum policy; independently verify actual proposed changes against immutable invariants; and test restart/reconciliation and unauthorized approval.

#### RL-68 — Human approval queue is volatile and audit failure does not block approval state changes

**Status: Source-confirmed.** `HumanApprovalQueue.init/1` initializes `queue` and `history` as empty maps/lists. Enqueue, approve and reject mutate only this process state. These handlers call `AuditLog.append/3` but ignore its return value. The approve handler removes the request from the pending queue and places it in in-memory history before invoking the resumer; the resumer result is not used to determine the approval handler's reply. The queue has no inspected durable journal/recovery path.

**Impact:** pending requests and approval history can disappear on process restart, and a human approval/rejection can be acknowledged even when the audit log refuses the corresponding record. Approval state and its audit evidence can diverge.

**Closure evidence:** persist requests and decisions transactionally with durable audit evidence; reject or remain pending when audit storage is unavailable; use idempotent resume acknowledgements; authenticate the human principal and bind approval to a canonical payload digest, policy version and expiry; and test crash/restart at every transition.

#### RL-69 — Council emergency invocation and lifting accept caller-asserted identity and ignore audit failures

**Status: Source-confirmed.** `Tiannara.Council.invoke_emergency/2` and `lift_emergency/1` pass actor/human ID values to the GenServer. The inspected handlers change the in-memory emergency flag without authenticating the caller's identity or checking an authorization grant. Both handlers ignore the result of `AuditLog.append/3`; lifting an emergency can return `:ok` even if the audit append fails. Emergency state is initialized inactive in Council process memory, with no inspected durable recovery record.

**Impact:** the code does not establish that only an authorized human can lift emergency lockdown, nor that invocation/lifting is durably recorded. A Council restart can lose the active emergency state unless another mechanism restores it.

**Closure evidence:** require authenticated, role-scoped, signed emergency commands; separate machine-triggered invocation from human-authorized lifting; persist emergency state and audit event atomically; fail closed on audit/persistence failure; and verify restart behavior and unauthorized-lift denial.

#### RL-70 — Self-improvement gate records are caller-supplied booleans, not independently verified attestations

**Status: Source-confirmed.** `Tiannara.SelfImprovement.Pipeline.request_deployment/3` checks that required entries are `GateResult{passed: true}` and that protected-core independent verification has a non-nil source other than `:self_improvement`. It does not itself validate signatures, issuer identity, evidence references, artifact/candidate hashes, gate freshness, or revocation. The dry-run constructs gate results from local booleans and invokes the pipeline with `deployment_enabled: true`, while explicitly describing the outcome as authorization-only and never executing deployment. Thus the pipeline contract is a useful fail-closed gate shape, but its public API does not establish provenance/authenticity of gate claims.

**Impact:** a caller able to construct gate structs can satisfy the pipeline's predicates without supplying independently verifiable evidence. This does not demonstrate an active deployment bypass in the inspected dry-run, but it means the gate API alone is not a security-grade attestation boundary.

**Closure evidence:** accept signed attestations issued by registered independent verifiers; bind every attestation to the exact candidate tree/hash, test harness, policy version, time window and evidence bundle; verify issuer authorization and revocation at consumption; require a separate deployment gateway to consume a single-use grant; and test forged, stale, substituted and self-issued attestations.

#### RL-71 — ACL/OAVL and D15/ISR authority boundaries remain unproven as universal execution controls

**Status: Coverage not established; no positive claim of bypass is made.** The frozen-source searches surfaced OAVL implementations in separate Python and Elixir namespaces and a range of Council/CEL governance components, but did not establish one mandatory ACL/OAVL decision point covering every sensitive execution path. The inspected `WorldMutationEngine` has a concrete Council authorization gate; other paths reviewed in earlier checkpoints (including CIS termination and operational APIs) do not consistently prove delivery/effect or share that exact gate. Targeted repository searches for D15/ISR mutation guards did not locate a source-level enforcement path at this baseline. Therefore the required property that D15 cannot mutate ISR or upstream authority is **not demonstrated**, rather than proven false.

**Impact:** separate governance components and policy documents cannot establish universal enforcement without a traceable call graph from every sensitive entry point to an authenticated, authoritative decision and an effect-bound grant. D15's authority ceiling remains a release-blocking unknown.

**Closure evidence:** produce a complete sensitive-operation inventory and call graph; identify the canonical ACL/OAVL interfaces and prove all execution sinks are gated; establish an immutable ISR owner and deny all D15 write paths by construction; then run negative tests against direct API, internal message, restart, replay, privileged actor and emergency paths. Missing or ambiguous authorization must remain UNKNOWN/deny.

#### Checkpoint 15 disposition

The Council and WorldMutationEngine contain meaningful controls, and the AuditLog implements a real DETS-backed hash chain with integrity verification. However, the constitutional repository and amendment engine expose divergent mutation paths; human approvals and emergency state are not durably/authentically enforced in the inspected handlers; audit append failures are ignored by several governance callers; and self-improvement gate structs do not prove independent attestation authenticity. ACL/OAVL universal coverage and D15/ISR non-mutation remain unproven. **Checkpoint 15 is not a governance certification pass.** Findings RL-66–RL-71 are source-level observations at the frozen baseline; no runtime or adversarial tests were run. Only the audit ledger is updated.


### Checkpoint 16 — Build, test, fault-injection and soak verification

**Baseline:** immutable application commit `e71bc230a8d38f3a0108012685ae1a052d195b00`. Inspected GitHub Actions runs attached to this exact SHA, including fresh runs created 2026-10-31. Evidence comes from completed workflow/job records and decoded job logs. No local shell, repository checkout, or new tests were run in this checkpoint; the results below are CI executions that already occurred against the frozen commit.

#### Executed CI evidence

**Elixir CI run:** [41176699464](https://github.com/Kimiti4/Tiannara/actions/runs/41176699464) — completed with overall success.

- Root compile job: `mix compile --force` succeeded; `mix run -e ":ok"` succeeded.
- Test-placement check: passed.
- Root suite: `mix test --max-failures 25` passed; **2,524 tests, 79 properties, 0 failures, 2 skipped**, duration 291.5 seconds.
- Required `tiannara_runtime` suite: `mix test --exclude quarantine` passed; **1,863 tests, 40 properties, 0 failures, 6 excluded**, duration 44.6 seconds.
- Discovery lineage regression: **11 tests, 0 failures**.
- `tiannara_audit` verifier suite: **13 tests, 0 failures**.
- Quarantined `tiannara_runtime` suite: informational/non-blocking job failed; details recorded under RL-72.

**Cross-platform verification run:** [41176699508](https://github.com/Kimiti4/Tiannara/actions/runs/41176699508) — Linux, macOS and compare jobs all completed successfully. Both platforms emitted canonical certificate SHA-256 `4564a4b6014253837f47d8db870ba17bc7770a243cd62cdb086ceb6519faa955`. The workflow explicitly removes selected timestamp fields and sorts JSON keys before hashing. It also ran the archaeological reconstruction, mutation-testing and independent-audit scripts as workflow steps. This demonstrates reproducibility of that normalized evidence artifact, not deterministic live-world simulation or complete behavioral equivalence.

**Compilation caveat:** the compile job succeeded with numerous warnings, including references to undefined/unavailable functions or modules (examples in logs include `Tiannara.EventBus.publish/3`, `TiannaraOS.LifecycleRegistry.track_entity/4`, and `Tiannara.ASC.CMissions.OracleAE003.check/3`), clauses that can never match, incompatible types and missing `@impl` annotations. A successful compiler exit is not a warning-free or fully linked runtime certification.

#### RL-72 — Quarantined runtime tests fail while the required suite remains green

**Status: CI-confirmed.** The required runtime job excludes six tagged tests and passes. The separate `continue-on-error: true` quarantine job executed those tests and failed with **4 failures** (40 properties, 1,863 tests in the ExUnit run, 1,897 excluded). Failure evidence in the 2026-10-31 job log includes: passive mode changed its state fingerprint while OLEF periodic rebalancing ran; reactivity observed constraint load unchanged at `0.0 -> 0.0`; and two Omega robustness tests failed to obtain a privately owned CPL process because the named process was already started. The tracked inventory classifies these as service/isolation or exploratory/product findings and explains why they are excluded.

**Impact:** the green required suite is a valid statement about the non-quarantined set only. Passive-mode mutation and non-reactive constraint telemetry remain unresolved product behavior; persistence test isolation remains unresolved. `continue-on-error` deliberately prevents these failures from blocking the overall workflow.

**Closure evidence:** resolve the product behaviors and process ownership/isolation defects; re-admit each test to the required suite; demonstrate that no known safety/behavioral defect is hidden by quarantine; and keep the required gate green without retries or masking.

#### RL-73 — CI does not test the newly identified constitutional write and authority bypasses

**Status: Coverage gap confirmed by repository test inventory and targeted test search.** The root required suite includes Council approval reachability, human approval resumption, conditional grants, policy precedence, audit-log durability/recovery and related authorization tests. The frozen test tree contains no identified dedicated tests for direct `ConstitutionRepository.commit/3` or `rollback/2` authorization bypass, forged `human_id`/emergency lift, approval queue restart durability, audit-append failure propagation from the queue/emergency handlers, or forged/stale `GateResult` attestation acceptance. Targeted repository searches for those test cases returned no matching test files. The full root suite passing therefore does not close RL-66–RL-70.

**Impact:** important constitutional controls have positive-path tests, but the specific bypasses and persistence/error paths discovered in Checkpoint 15 are not demonstrated as denied under execution. Passing adjacent Council tests cannot be substituted for negative tests at the repository and privileged API boundaries.

**Closure evidence:** add adversarial tests for each RL-66–RL-70 path, including direct public API calls, forged actors, stale/substituted approvals, audit storage outage, process restart and exact candidate-hash attestation; verify expected denial and durable evidence.

#### RL-74 — CI contains no long-duration world/runtime soak or integrated lifecycle fault campaign

**Status: CI configuration and test inventory confirmed.** The inspected workflows run bounded compile/test jobs (45–60 minute timeouts) and cross-platform evidence generation. No workflow starts a multi-world runtime and sustains it for a 72-hour soak, nor performs an integrated fault campaign across world spawn, quota reservation, memory allocation, termination acknowledgement, snapshot restoration, replay, supervisor restart and recovery. The existing root `test/tiannara/soak/recovery_test.exs` validates isolated checkpoint-store recovery and time accounting using controlled test fixtures; it does not run a live world system for 72 hours. The quarantined runtime tests also expose unresolved isolation/reactivity behaviors.

**Impact:** CI proves bounded suites execute and pass under their declared exclusions, but does not prove long-run resource stability, lifecycle transactionality, persistence/replay fidelity, or recovery under real supervisor/resource failures. The historical soak-duration notes from other runs are not a substitute for reproducible, commit-bound soak evidence at this baseline.

**Closure evidence:** implement a commit-bound soak workflow with an explicit duration and heartbeat, durable checkpoint/evidence artifacts, resource and mailbox metrics, restart/recovery accounting, fault injection at each lifecycle boundary, and hard failure thresholds. Do not count unvalidated wall-clock time as validated soak time.

#### RL-75 — Compilation succeeds with unresolved static integration warnings

**Status: CI-confirmed.** The root project compiles successfully in the required CI job, but the same log contains warnings for undefined/unavailable module functions, impossible pattern clauses, incompatible types, unused code and missing GenServer callback annotations. Examples include `Tiannara.EventBus.publish/3`, `TiannaraOS.LifecycleRegistry.track_entity/4`, and `Tiannara.ASC.CMissions.OracleAE003.check/3`. The current workflow does not treat these warnings as errors; its separate `compile.profile` alias requests warnings-as-errors but is not the CI compile command inspected here.

**Impact:** a successful compile proves the compiler emitted the project, not that all integration references resolve or that all branches are reachable. Warnings such as undefined function calls may become runtime failures when the affected paths execute; impossible clauses can conceal broken error handling.

**Closure evidence:** classify every warning by module/path and reachability; repair or explicitly justify each one; enable warnings-as-errors for the certified build profile; and execute tests through every formerly warning-bearing path.

#### Checkpoint 16 disposition

The frozen commit has substantial passing CI evidence: root and runtime suites pass, audit verifier tests pass, and normalized certificate hashes match on Linux/macOS. The audit-log recovery suite includes genuine storage corruption, lock contention, forced process death, restart and chain-verification tests. These are positive results and should be retained.

However, the quarantine job has four observed failures; six tests remain excluded from the required runtime gate; Checkpoint 15's direct constitutional bypasses are not covered by dedicated tests; the CI workflows do not provide a 72-hour live-world soak or integrated resource/lifecycle fault campaign; and compilation still emits integration warnings. Thus **Checkpoint 16 is a partial verification pass, not a release certification pass**. No application code was changed; only this audit ledger was updated.


#### RL-76 — Cross-platform hash verification uses a different OTP baseline from the required runtime suite

**Status: Workflow configuration confirmed.** The required Elixir CI workflow sets OTP 28 for the root compile and `tiannara_runtime` suite. The cross-platform verification workflow sets OTP 27 for both Linux and macOS evidence generation. Therefore the matching certificate hashes prove normalized artifact equality across those two OS runners under OTP 27; they do not prove cross-platform equivalence under the OTP 28 runtime test baseline.

**Impact:** the two successful workflows cover different Erlang/OTP environments. A platform-specific or OTP-version-specific behavior in the actual runtime is not excluded by the hash comparison.

**Closure evidence:** run the relevant deterministic evidence and runtime compatibility checks on both Linux and macOS under the same pinned OTP 28 / Elixir 1.18 toolchain used by the required runtime suite, and bind the resulting artifacts to the exact commit and toolchain manifest.


### Checkpoint 17 — Remediation reconciliation and runtime audit strategy

**Audit scope:** Tiannara AI only. ESAP remains deferred. Application baseline remains the immutable source commit `e71bc230a8d38f3a0108012685ae1a052d195b00`; the audit ledger itself is maintained on `audit/consolidated-findings-r0a-2026-10-31`. This checkpoint changes no application source and does not claim any finding has been remediated.

#### 17.1 Consolidated remediation order

The register is to be remediated by shared root cause and dependency, not as isolated tickets:

1. **P0 — Authority, governance and security:** RL-66–RL-71 and RL-73. Establish authenticated principals, immutable ISR ownership, D15 non-write authority by construction, signed candidate-bound grants, atomic durable constitutional changes, quorum/human approval, audit-failure fail-closed behavior, and complete ACL/OAVL/CEL enforcement at every sensitive sink.
2. **P0 — Canonical execution and lifecycle:** RL-01–RL-15 and RL-28–RL-49, plus RL-74. Establish one world identity and lifecycle authority; transactional quota/memory admission; acknowledged child startup, termination and cleanup; idempotent reconciliation; durable manager recovery; measured resource accounting; and explicit boot dependencies.
3. **P0 — Truthful state and operational outcomes:** RL-14, RL-33 and RL-61–RL-65. Authoritative state transitions and event publication must be real; operational APIs must distinguish simulated/demo data from live state; authorization, command delivery, observed effect and reconciliation must be separate result states.
4. **P1 — Persistence, snapshot and replay:** RL-04, RL-06, RL-37–RL-46 and RL-60. Implement full-state capture, schema-safe import, world identity validation, durable atomic storage, startup recovery, event application and state-hash verification.
5. **P1 — Research and discovery:** RL-50–RL-56 and CAP-02. Connect scheduled execution to the actual discovery/research pipeline; replace random/synthetic experiment outcomes with protocol execution and measured results; require falsification, independent validation, reproducibility, calibrated uncertainty and provenance.
6. **P1 — Civilization history and archaeology:** RL-57–RL-60 and CAP-03. Define persistent world/civilization epochs, institutions, infrastructure, materials, artifacts, site/stratum coordinates and evidence links; then prove excavation and reconstruction across successive worlds.
7. **P1 — Verification infrastructure:** RL-72–RL-76. Resolve and re-admit quarantined failures, classify/fix compiler warnings, add adversarial governance and lifecycle fault tests, run a commit-bound 72-hour live-world soak, and align Linux/macOS toolchains.
8. **P2 — Capability/domain completeness:** R0-B-03, ARCH-01–02 and CAP-01. Revalidate all claimed capabilities against reachable production paths, independent tests and explicit unsupported behavior.

**Dependency rule:** do not enable broader autonomous research, self-modification or self-improvement execution before authority controls, lifecycle transactionality, durable evidence and truthful operational reporting are established. A passing downstream test cannot compensate for an unverified upstream authority or state boundary.

#### 17.2 Runtime directory inventory at the frozen baseline

The recursive Git tree for `tiannara_runtime/` at the immutable baseline was retrieved and parsed. The tree response was not truncated.

- **17,627 tree entries**: 17,229 files and 398 directories.
- **14,145 JSON files**, predominantly under `data/` and `priv/`; these are not 14,145 independent source modules and must not be audited as if they were.
- **1,578 Markdown files**, including design, implementation, completion and audit reports. These are claims/specifications to compare against executable source, not proof of implementation.
- **1,461 code files**: 1,241 `.ex`, 206 `.exs`, 12 `.rs`, and 2 `.py`.
- **1,240 files under `lib/`** and **171 code files under `test/`**.
- Largest source clusters include `world_model` (175 files), `cognitive` (161), `sentinel` (89), `opc` (86), `civilization` (61), `os` (58), `meta` (42), `oed` (33), `mathematics` (29), and `autonomous_research` (26).

These counts are inventory evidence only. They do not imply all files are compiled, reachable, production-used, or owned by the same runtime application. The directory has mixed namespaces (`tiannara_runtime`, `tiannara`, `world_model`, plus data, generated evidence and documentation), so path names alone are not a reliable architecture map.

#### 17.3 Efficient audit method for the large runtime tree

Use a layered, evidence-first audit rather than reading every file sequentially:

**A. Freeze and inventory**
- Pin the exact candidate SHA and record tree SHA, toolchain, app roots and build configuration.
- Classify every tree entry as executable source, test, configuration, generated/data artifact, migration, documentation, native code or build output.
- Build a source manifest with path, module, source hash, owning OTP application/supervisor, declared dependencies, test references and status.
- Separate tracked historical/generated JSON from runtime persistence stores; determine whether each file is fixture, seed, artifact, checkpoint or active input.

**B. Build the execution and ownership graph**
- Start at `mix.exs`, application callback(s), config, supervisors and child specifications.
- Trace each requested system from public entry point/API or message ingress through callers, supervisors, dependencies and effect sinks.
- Record module ownership, startup reachability, configuration/readiness, message/data contracts, persistence and failure behavior.
- Search both callers and callees. A module existing, compiling or having tests does not establish production reachability.
- Use targeted searches and dependency clusters to reduce the review set; fetch complete source for the modules on each critical path. Do not use filename or documentation claims as closure evidence.

**C. Audit each subsystem with one common evidence template**
For every module and capability, record: intended responsibility; actual implementation; entry points; callers; startup status; data contracts; state ownership; external effects; authorization gates; persistence; error/timeout/retry behavior; concurrency and restart semantics; tests; CI evidence; unsupported/placeholder paths; and unresolved dependencies.

**D. Verify in increasing cost**
1. Static source and call-graph tracing.
2. Unit tests for invariants and error branches.
3. Integration tests through the real supervisor/application graph.
4. Adversarial authorization, fault injection, restart and recovery.
5. Live multi-system scenarios and long-duration soak.
6. Independent review of exact-commit artifacts.

Every claim is classified as **verified**, **partially verified**, **source-only**, **specified-only**, **unreachable/unwired**, **placeholder/simulated**, **unsupported/fail-closed**, or **unknown**. No simulated evidence satisfies a runtime gate.

#### 17.4 Planned subsystem audit sequence

The next audit program will cover the user's requested systems, grouped by shared dependencies:

1. **Executive management and control plane** — executive decision/command lifecycle, priorities, delegation, memory, observability, orchestration and human override.
2. **Cognitive architecture and intelligence** — perception/input, attention, working/long-term memory, world models, reasoning, planning, decision-making, metacognition, communication and uncertainty.
3. **Immunity and resilience** — anomaly/threat detection, containment, quarantine, recovery, fault tolerance, immune memory, false-positive/negative behavior and authority boundaries.
4. **Research, discovery and scientific auditing** — hypothesis lifecycle, experiment design/execution, evidence scoring, falsification, replication, knowledge integration, provenance and discovery certification.
5. **Mathematics and computational science** — declared mathematical domains, algorithms, numerical stability, solver correctness, property tests, performance and unsupported/theatrical functions.
6. **Self-modification and self-improvement** — candidate generation, isolated evaluation, independent verification, constitutional authorization, approval, deployment, rollback and post-deployment monitoring.
7. **Security and governance** — identity, authentication, authorization, ACL/OAVL/CEL, secrets, trust boundaries, audit logs, supply chain, sandboxing and D15/ISR invariants.
8. **Cross-system intelligence integration** — prove that the above systems exchange authoritative, provenance-bearing data and coordinate through real runtime paths rather than parallel, unconnected implementations.

The sequence is dependency-aware, not a claim that each group is independent. Security/governance controls are traced across every group, and shared executive, cognitive, memory and event infrastructure is audited once as a common dependency before relying on it downstream.

#### Checkpoint 17 disposition

**Reconciliation complete; implementation not started.** The existing findings are organized into dependency-ordered remediation workstreams. A reproducible tree inventory establishes that the runtime directory is large but tractable when separated into source, tests, documentation and generated data. The next phase should begin with a source manifest and boot/ownership graph, then audit the executive-management/control plane as the first subsystem. No application findings are closed by this checkpoint.


### Checkpoint 18 — Runtime System Atlas and executive-management audit (initial pass)

**Scope and baseline:** The audit includes the tracked repository-root `lib/` tree corresponding to the user's `Tiannara-MindCache-Prosthetic\\lib` path, in addition to `tiannara_runtime/`. The source inspected is pinned to `e71bc230a8d38f3a0108012685ae1a052d195b00`. The connected repository provides tracked source; it does not prove that the user's current local Windows working tree has no uncommitted or divergent files. Local-only differences remain uninspected until a local archive/upload or commit is supplied. No application source was modified and no runtime tests were run in this checkpoint.

#### 18.1 Repository-root `lib/` inventory and overlap

At the frozen baseline, the repository-root `lib/` contains 1,660 tracked files, 1,656 of which are code files. Major module clusters include `lib/tiannara/asc` (267), `os` (220), `sentinel` (65), `discovery` (51), `forecasting` (51), `cel` (50), `omega` (48), `rea` (43), `executive` (31), `audit` (19), `research` (15), `self_improvement` (10), `memory` (8), and `math` (6). These are path counts, not proof of reachability or capability.

The root `lib/` and `tiannara_runtime/lib/` have distinct namespace families and separate application/runtime concepts. Treat them as separate ownership domains until application startup, dependencies, shared state and adapters prove otherwise. In particular, do not assume that an identically named executive, memory, research, security or world subsystem is the same implementation.

#### 18.2 Executive management execution path

The root `Tiannara.Application` child list includes `Tiannara.Executive.Supervisor` and `Tiannara.Executive.Cognitive.ExecutiveCognitiveRuntime`. The Executive supervisor starts EventStore, EventBus, ExecutiveMemory and Coordinator as separate `one_for_one` children. The ECR supervisor starts Blackboard, WorkingMemory, ContextManager, AttentionScheduler, ReflectionEngine, ExecutiveCycle and HeartbeatEngine. This establishes declared boot wiring in source; it does not by itself prove successful production startup or readiness.

#### RL-77 — Executive coordinator reports successful execution without checking the command result

**Status: Source-confirmed; runtime reproduction not performed.** `Tiannara.Executive.Coordinator.handle_call({:submit, ...})` uses `Consensus.evaluate(cmd, :simple)`, approves the command, calls `execute_command/1`, discards the returned value, increments `metrics.executed`, publishes `command.executed` with `result: :ok`, and replies `:ok`. The plan stored in state is the approved command; it is not changed to `:executed` or `:failed`. The execution helper can return errors for unknown actions or from ExecutiveMemory operations.

**Impact:** callers and metrics can be told an action executed when the underlying memory operation failed or returned an error. Status may remain `:approved` despite the reported execution event. This is a direct command-outcome truthfulness defect.

**Closure evidence:** preserve the actual execution result; transition the command to executed only on verified success and failed otherwise; publish outcome matching the real result; test every action's success/failure path and status/metric consistency.

#### RL-78 — Executive coordinator hardcodes permissive single-validator consensus for every submitted command

**Status: Source-confirmed.** The only submission path invokes `Consensus.evaluate(cmd, :simple)` regardless of action or command metadata. `simple_consensus/1` approves all actions except `:gc`, `:compact` and `:rebuild`. The majority, constitutional and emergency modes are not selected by the coordinator's submit path. `get_validators/0` defaults to a single validator that always returns `:approve` when no validators are configured.

**Impact:** the existence of multiple consensus modes does not mean they govern command execution. Ordinary memory mutations receive unconditional approval under the default validator configuration, with no demonstrated principal authentication or policy-specific authorization in this path. Destructive operations are rejected in simple mode rather than being routed to the required stronger approval process.

**Closure evidence:** derive required authorization mode from a trusted policy for each command; fail closed if validator identities/configuration are absent; authenticate approvers; bind approvals to command and candidate hashes; test spoofing, absent validators, denial, timeout and approval threshold behavior.

#### RL-79 — ECR cognitive cycle advances and reports phase success without demonstrating phase work

**Status: Source-confirmed.** `ExecutiveCycle.execute_phase/1` returns `:ok` for every phase in the normal paths. `:investigate` silently returns `:ok` when Sentinel or ResearchDirector are absent; `:execute` explicitly only posts a pending marker and does not execute a plan; `:validate` checks whether blackboard entries have `status == :executed` and records a boolean, without independently validating an execution receipt; `:observe` substitutes a synthetic nominal system-health observation when Sentinel is absent. The cycle increments phase/cycle counters and emits status telemetry from the returned `:ok`.

**Impact:** cycle completion and successful phase telemetry can be mistaken for actual observation, investigation, execution and validation. The code is partly transparent about the execution provider being absent, but the aggregate cycle status remains success-shaped and fallback observation resembles live health.

**Closure evidence:** use typed phase outcomes (completed, skipped, unavailable, failed, simulated); propagate dependency absence and operation errors; require authenticated execution receipts and independent validation; never classify fallback/mock observations as production signals; test each missing-dependency and failure path.

#### RL-80 — ECR health endpoint hardcodes healthy status

**Status: Source-confirmed.** `ExecutiveCognitiveRuntime.health/0` returns `status: :healthy` unconditionally while collecting uptime, cycle count, last reflection and attention count. It does not derive health from child supervisor state, heartbeat freshness, phase failures, cognitive dependency readiness or degraded state.

**Impact:** Sentinel and Omega health aggregation can receive a healthy result even when ECR children are missing, stale or repeatedly failing. This undermines operational monitoring and any governance or self-improvement decision based on health.

**Closure evidence:** derive health from live child probes, heartbeat age, cycle progress, phase failure/skipped counts and dependency readiness; expose unknown/degraded/unavailable states; test child crash, stale heartbeat and dependency loss.

#### RL-81 — Executive EventStore is not the event sink for the ExecutiveMemory/Coordinator event path

**Status: Source-confirmed for inspected modules; global caller inventory remains open.** The Executive supervisor starts EventStore and EventBus. ExecutiveMemory writes/deletes publish events to EventBus; Coordinator publishes command outcomes to EventBus. Neither inspected path appends those events to EventStore, and EventBus only delivers messages to volatile subscribers. EventStore is separately appendable and has some external callers, but the core executive memory/command events are not shown as durably journaled.

**Impact:** the advertised append-only executive event history does not cover core executive writes and command outcomes through the inspected execution path. Restart or subscriber absence can lose these events even though EventStore is running.

**Closure evidence:** define one authoritative event transaction/outbox path; persist required events before acknowledging state mutation; make append failure visible and fail closed where auditability is required; verify restart replay, ordering, duplicate handling and corruption recovery. Complete caller inventory before claiming EventStore has no other uses.

#### RL-82 — CivilizationKernel exposes unauthenticated state bypass and rollback paths

**Status: Source-confirmed.** `TiannaraOS.CivilizationKernel.human_override/1` accepts a caller-supplied map and directly installs it without identity authentication, Council grant, human approval verification or normal resource/tenant validation. `rollback/1` similarly installs a caller-supplied target state, preserving only the prior memory field and appending an in-memory audit event; no authenticated authorization or state validation is performed. `validate_state/1` returns `:ok` for any non-`TiannaraOS.State` value, and `validate_security_profile/1` returns `:ok` for non-map inputs.

**Impact:** the public GenServer APIs provide bypass paths around the kernel's own claimed canonical-state invariants. The bypass is explicit in comments, but caller identity and human authority are not established in the inspected functions. The permissive fallback validation also allows malformed/noncanonical values to pass the validator.

**Closure evidence:** require authenticated, signed and scoped human/Council authorization for override and rollback; validate exact canonical state type/schema and all invariants; bind rollback to a verified checkpoint and audit record; reject malformed security-profile inputs; test direct API calls, forged actors, invalid tenant/resource states and audit failure.

#### RL-83 — ExecutiveMemory can erase degraded recovery status during startup

**Status: Source-confirmed; exact failure reproduction not performed.** In `ExecutiveMemory.startup/1`, if `Recovery.startup_recovery/1` returns an error, the code attempts to open the store and sets the local status to `:degraded`. Later in the same startup function, after warming ETS and running a deep check, it unconditionally calls `State.activate(state)`, which changes status to `:active` regardless of the earlier degraded status or whether the deep check marked corruption.

**Impact:** startup may expose an unrecovered or newly opened store as active after a recovery failure. This can cause dependent executive/research systems to treat incomplete or potentially empty state as authoritative.

**Closure evidence:** preserve degraded/corrupt status until explicit integrity and recovery gates pass; never convert recovery failure into active readiness; distinguish fresh-empty initialization from failed recovery of existing data; test corrupted/unopenable files and deep-check failure through the full startup path.

#### 18.3 Initial executive subsystem disposition

- **Executive supervision:** source-declared in the root application; runtime readiness not tested here.
- **Executive command coordination:** source-level outcome and authorization defects identified (RL-77–78).
- **Executive memory:** DETS/ETS persistence and recovery mechanisms exist, but the startup status defect and core event-journal gap require remediation/verification (RL-81, RL-83).
- **Executive cognitive runtime:** a scheduled eight-phase loop exists, but some phases are placeholders/skips and health is hardcoded (RL-79–80).
- **Civilization kernel:** canonical state substrate exists, but direct override/rollback and permissive type validation are release-blocking security/governance concerns (RL-82).
- **Local Windows workspace:** tracked repository source was inspected; local uncommitted/divergent files are not verified.

#### Checkpoint 18 disposition

**Initial source audit complete for the executive-management/control-plane slice; broader runtime atlas and the remaining requested subsystems are not complete.** RL-77–RL-83 are source-level findings, not runtime-reproduced defects. No application code was modified and no tests were executed. Continue with a full caller/ownership graph and then audit the remaining executive services, CEL/Ω control plane, immunity, cognition, research, mathematics, self-modification and security as separate dependency-linked slices.


### Checkpoint 18 continuation — executive and runtime ownership reconciliation

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Mode:** Read-only source inspection of both repository-root `lib/` and `tiannara_runtime/lib/`. Findings are source-confirmed at the pinned SHA; no runtime reproduction or test execution was performed. No application source was changed.

#### RL-84 — Resurrection marks the runtime as running after failed or incomplete recovery

**Status: Source-confirmed.** In `TiannaraRuntime.OS.Persistence.ResurrectionEngine`, `restore_queues/0` and `restore_runtime_state/0` are placeholder functions that log and return `true`; they do not restore queues or runtime state. The resurrection report sets `certified` from `recovery_report.hash_verification_passed` alone, so the certification predicate does not require successful restoration of queues or runtime state. In `TiannaraRuntime.Startup.run_resurrection/0`, the result is reduced to a boolean, but `mark_running/0` is called unconditionally after the attempt, including when `resurrect/0` returns an error.

**Impact:** a failed or incomplete recovery can be followed by a persistent `running` marker. The next boot may therefore lose the distinction between a successfully recovered runtime and one that merely attempted recovery. The recovery report also overstates restoration because its restoration fields are currently placeholder success values.

**Closure evidence:** implement real queue/runtime restoration with verifiable postconditions; certify only when hash verification and every required restore/replay check pass; do not mark running until recovery certification and startup readiness both pass; test corrupt chains, missing checkpoints, partial restore, failed writes and repeated crash/restart.

#### RL-85 — Runtime application has two competing supervision ownership boundaries

**Status: Source-confirmed.** `TiannaraRuntime.StartupSupervisor` describes itself as the single source of truth and owns CPL, Omega, COP, Endpoint, RootSupervisor and DiscoveryRunner under `:rest_for_one`. However, `TiannaraRuntime.Application.start/2` adds CIS.Supervisor, MultiWorld.KillSwitch, MultiWorld.WorldSupervisor, CIS.ExecutionController, Resources.QuotaGovernor, Memory.LineageCompression and Causal.GCK as additional children of the outer `TiannaraRuntime.Supervisor` under `:one_for_one`. Those children are not descendants of StartupSupervisor and are not covered by its restart ordering or status map.

**Impact:** the source contains separate lifecycle authorities for the core runtime and important safety/control-plane components. A failure/restart of one branch does not necessarily restart or reconcile dependent siblings in the other branch. The comment describing dependency order is not, by itself, a supervision dependency.

**Closure evidence:** define one authoritative ownership graph; place dependent safety/control-plane children under the appropriate supervisor or encode explicit dependency/reconciliation behavior; test kill-chain ordering, sibling failure, supervisor restart and full application recovery.

#### RL-86 — Optional child admission can leave safety/control-plane capabilities absent without failing startup

**Status: Source-confirmed.** The runtime application uses `BootPolicy.optional_child/1` for the CIS supervisor, KillSwitch, WorldSupervisor, ExecutionController, QuotaGovernor, LineageCompression and GCK. `optional_child/2` returns an empty child list when a module is not loaded. The StartupSupervisor status/all-running checks cover CPL, Omega, COP and RootSupervisor, not these additional children; the separate application supervisor does not expose a complete readiness contract for them in the inspected code.

**Impact:** a successful application start or a positive StartupSupervisor status does not establish that the safety, kill-delivery, resource-governance and causal components are present. Optionality is not equivalent to a certified degraded mode.

**Closure evidence:** classify each child as required, explicitly optional, or feature-gated; make missing required safety dependencies fail boot; expose per-child readiness and dependency status; test missing-module and failed-start cases and ensure system status cannot report full readiness.

#### RL-87 — Three executive-memory implementations have no demonstrated shared authority or reconciliation contract

**Status: Source-confirmed for the inspected modules; full caller inventory remains open.** The root tree contains `Tiannara.Executive.ExecutiveMemory` (under the Executive supervisor), `Tiannara.CEL.ExecutiveMemory` (a separate DETS-backed decision/mission history service), and the runtime tree contains `TiannaraRuntime.Omega.ExecutiveMemory` (an in-memory map with local ETF snapshots and CPL checkpoints). They expose different APIs and persistence formats. The inspected startup and caller paths do not establish a common canonical record identity, transaction boundary, conflict policy, event ordering or reconciliation process between these stores.

**Impact:** executive decisions, operational memory and runtime continuity may be represented in multiple stores without a proven consistency model. This can produce divergent histories or misleading claims of durable, unified executive memory.

**Closure evidence:** designate the authoritative store for each data class; define stable IDs, schemas, provenance and transaction/outbox contracts; specify replication/reconciliation and conflict handling; prove restart/replay and cross-store consistency with integration tests. Do not merge the stores merely because their names are similar.

#### RL-88 — CEL Executive health and constitutional score are fixed success-shaped values

**Status: Source-confirmed.** `Tiannara.CEL.Executive.handle_call(:healthy, ...)` always returns `true`. Its constitutional-score handler returns fixed health/alignment/transparency/explainability/evidence/oversight values rather than deriving them from live dependencies, decision records, audit results or readiness. The objective-definition handler updates local state and sends a decision record to CEL ExecutiveMemory without checking a durable receipt.

**Impact:** the CEL executive can appear healthy and highly aligned without evidence that its memory dependency, audit path or objective state is operational. Static scores must not be consumed as measured governance evidence.

**Closure evidence:** derive health and scores from live probes and evidence-backed measurements; propagate unavailable/degraded/error states; require durable record acknowledgement for objectives; test dependency failure, stale evidence and audit-store failure.

#### RL-89 — CEL ExecutiveMemory acknowledges asynchronous writes before durable success is known

**Status: Source-confirmed.** `Tiannara.CEL.ExecutiveMemory.record_decision/2` and `record_mission_outcome/2` use `GenServer.cast/2`, so callers receive no persistence result. The cast handler calls `:dets.insert/2` but ignores its return value and then returns `{:noreply, state}`. The public callers can therefore continue without knowing whether the record was durably accepted.

**Impact:** objective/mission flows may report success while their decision or outcome history was not persisted. This weakens the audit and continuity guarantees expected of executive memory.

**Closure evidence:** use a result-bearing synchronous write or durable outbox/acknowledgement protocol; check and propagate DETS errors; test write failure, process crash, restart readback and duplicate/idempotent record handling.

#### RL-90 — CPL returns success when event or checkpoint persistence fails

**Status: Source-confirmed.** In `TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer`, event and checkpoint handlers call `persist_event/2` and `persist_checkpoint/2`, then reply with success regardless of the persistence result. Both helpers rescue write/encoding errors, log a warning and return normally rather than propagating an error. The in-memory event/checkpoint state can therefore advance while disk persistence has failed.

**Impact:** callers and Omega readiness services may receive successful event/checkpoint acknowledgements that represent only in-memory acceptance. A subsequent process/node restart can lose acknowledged evidence, breaking the event-chain and recovery guarantees.

**Closure evidence:** make persistence helpers return tagged results; update authoritative state and acknowledge only after successful durable write (or use a proven WAL/outbox transaction); propagate failures into health and failure observatory; test filesystem errors, partial writes, crash between write and acknowledgement, replay and hash-chain verification.

#### 18.4 Cross-tree executive-management disposition

- Root CEL Executive, CEL ExecutiveMemory, Executive Coordinator/Memory and runtime Omega ExecutiveMemory/CPL are separate state and control surfaces. A canonical cross-tree authority contract has not been demonstrated.
- Runtime boot currently has an outer application supervisor plus a nested StartupSupervisor, with important control-plane children outside the latter's restart/status boundary.
- Recovery and persistence paths contain success-shaped outcomes that are not equivalent to verified durable restoration.
- These findings increase the priority of a canonical executive/control-plane architecture, but do not justify merging modules or moving ownership before the dependency and caller graph is complete.

**Checkpoint 18 continuation disposition:** RL-84–RL-90 are open source-level findings at the frozen SHA. No application code was modified and no tests were run. Continue the caller/ownership graph before remediation; then proceed through cognition/intelligence, immunity, research/discovery, mathematics, self-modification/self-improvement and security/governance.

### Checkpoint 18 continuation — cognitive architecture and intelligence (initial source pass)

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** Root ECR/Ω cognitive loops and the `tiannara_runtime/lib/tiannara_runtime/cognitive/` package. Source inspection only; no runtime tests or application changes.

#### RL-91 — Two root cognitive loops advance from the same heartbeat without a unified phase authority

**Status: Source-confirmed.** `Tiannara.Executive.Cognitive.HeartbeatEngine` emits the `[:tiannara, :ecr, :heartbeat]` telemetry event and directly casts `ExecutiveCycle.advance/0`. Separately, `Tiannara.Omega.AgencyLoop` attaches to that same telemetry event and advances its own six-phase sequence. Both loops use the same `ExecutiveBlackboard` and `WorkingMemory`, but maintain separate phase indices, histories and completion counters. The root application starts ECR and `Tiannara.Omega.OmegaRuntime`, whose child list includes AgencyLoop.

**Impact:** cognitive processing can be advanced by two independent state machines on each heartbeat, with interleaved writes to shared working memory and blackboard. There is no explicit arbitration, transaction boundary or canonical phase owner in the inspected path. This creates ambiguity about which loop owns observation, investigation, learning and improvement state.

**Closure evidence:** define one canonical cognitive orchestration authority or document and enforce a strict parent/child contract between the loops; sequence shared-state mutations; attach correlation/cycle IDs; test ordering, duplicate work, concurrent heartbeat and restart behavior.

#### RL-92 — Root cognitive interpretation and reflection are explicitly mock/template outputs

**Status: Source-confirmed.** `ContextManager.build_context/1` groups observations by type and assigns fixed urgency values by category; it emits a hard-coded `confidence: 0.85`, a `"Mock interpretation"` assumption and a statement that true causal relationships are not established. `ReflectionEngine.perform_reflection/0` returns a fixed list of assumptions, contradictions (always empty), bottlenecks, missing knowledge and next experiments with fixed `confidence: 0.7`; it does not derive those fields from the current cycle's evidence or prior outcomes.

**Impact:** these modules provide useful scaffolding and candidly label some limitations, but they do not yet establish evidence-grounded interpretation, contradiction detection, causal reasoning or adaptive self-reflection. Their numeric confidence fields are constants, not calibrated estimates.

**Closure evidence:** derive interpretations and reflections from identified observations, hypotheses and outcomes; preserve source references and uncertainty; implement contradiction/falsification checks; calibrate confidence against held-out outcomes; ensure mock/template mode is explicitly typed and cannot satisfy production cognition gates.

#### RL-93 — Runtime mission transition validation does not perform the transition, while direct status mutation bypasses it

**Status: Source-confirmed.** `TiannaraRuntime.Cognitive.Engines.MissionController.transition/3` checks the current status and allowed transition, but returns only `:ok` and does not return an updated mission. The separate `set_status/2` function changes the mission status to any supplied value without consulting the allowed-transition map.

**Impact:** callers cannot use the nominal transition function to atomically apply a valid lifecycle transition, while the direct setter can bypass the lifecycle rules. The two public APIs therefore do not provide one reliable mission state machine.

**Closure evidence:** make transition return the updated immutable mission (or persist an acknowledged transition); remove/restrict arbitrary status mutation; validate all state transitions through one function; test every allowed and forbidden edge and verify the resulting mission fingerprint/state.

#### RL-94 — Runtime cognitive policy engine is a policy list, not an enforcing decision gate

**Status: Source-confirmed for the inspected module.** `TiannaraRuntime.Cognitive.Decision.PolicyEngine.register_policy/2` appends a policy without invoking its separately defined `validate_policy/1`. `get_policies/2` only filters by scope. The module has no decision-evaluation or enforcement function that evaluates the declared constraints against a candidate, risk assessment, evidence or execution request. The inspected runtime `RootSupervisor` graph also does not declare a dedicated cognitive supervisor or cognitive decision service.

**Impact:** the existence of default policy maps and a policy registry does not establish constitutional policy enforcement in the runtime cognitive path. Policies can be malformed or remain inert unless another caller independently implements enforcement.

**Closure evidence:** define a single policy-evaluation contract; validate and version policies on registration; evaluate every decision/execution candidate against the applicable policy set; bind approvals to evidence and candidate fingerprints; prove deny/allow/conditional behavior through the actual runtime call graph and adversarial tests.

#### 18.5 Cognitive architecture disposition

- Root ECR and Ω AgencyLoop are both started and share cognitive state surfaces, but no single phase authority or coordination contract has been demonstrated.
- Root interpretation/reflection currently contain explicit mock/template behavior; do not classify them as evidence-grounded cognition.
- The runtime cognitive package contains versioned structs and helper engines, but its mission transition and policy enforcement contracts are incomplete in the inspected modules.
- This is an initial cognitive slice, not a complete audit of perception, memory consolidation, world-model reasoning, planning, metacognition or language/dialogue.

**Checkpoint 18 cognitive disposition:** RL-91–RL-94 remain open source-level findings at the frozen SHA. No code was changed and no tests were run. Continue the cognitive caller/ownership graph before moving to immunity and research/discovery.

### Checkpoint 18 continuation — immunity and resilience (initial source pass)

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** root `Tiannara.CIS` and runtime `TiannaraRuntime.CIS` / kill-control components. Source inspection only; no runtime tests or application changes.

#### RL-95 — Root CIS has no demonstrated event-driven immune observation loop

**Status: Source-confirmed for the inspected supervisor and registry.** Root `Tiannara.CIS.Supervisor` starts `CISRegistry`, `CollapsePredictor`, `ImmuneDecisionEngine` and `RegulationExecutor`. However, `CISRegistry.init/1` starts an empty child list; it does not register or monitor immune responses. The inspected root CIS supervisor exposes no event subscription or routing API, and no link is established between predictor output, decision evaluation and response execution in these modules.

**Impact:** the presence of a supervised CIS process tree does not establish a continuously observing, event-driven immune system. A caller can manually invoke individual functions, but an autonomous detection → decision → containment → recovery path is not demonstrated.

**Closure evidence:** define authenticated event ingress and canonical threat/incident records; connect observation, risk assessment, decision and response through one supervised workflow; demonstrate end-to-end fault injection and verify that real production incidents are detected and contained.

#### RL-96 — Root CIS regulation execution is log-only

**Status: Source-confirmed.** `Tiannara.CIS.RegulationExecutor.execute/2` logs the requested action, appends it to an in-memory `executed_actions` list and returns `:ok`. It does not invoke a quarantine, isolation, resource restriction, rollback, restart or recovery provider. The `ImmuneDecisionEngine` only maps severity greater than 0.7 to the symbolic response `:quarantine`, otherwise `:monitor`; no enforcement bridge from that response to a real quarantine operation is present in the inspected modules.

**Impact:** an immune response can be represented as executed even though only a log/state update occurred. This is not evidence of containment or recovery.

**Closure evidence:** return typed proposal/authorized/delivered/applied/verified outcomes; connect actions to real effect providers behind governance authorization; require postcondition evidence and test that unavailable providers never produce an applied/success result.

#### RL-97 — Root collapse-risk calculation substitutes optimistic telemetry defaults

**Status: Source-confirmed.** `Tiannara.CIS.CollapsePredictor.gather_live_telemetry/0` queries three health functions, but then injects `memory_pressure: 0.0` and `dets_health: true` rather than measuring those conditions. `validate_telemetry/1` requires only the three health keys, so those defaults are accepted as if they were observed telemetry. Risk weights are fixed constants.

**Impact:** memory pressure and DETS degradation can be absent from the risk calculation while the output still carries an evidence count and numeric risk score. A computed score is not a complete or calibrated collapse assessment.

**Closure evidence:** gather memory/DETS status from authoritative live sources; distinguish measured, inferred, defaulted and unavailable fields; reject or downgrade incomplete telemetry; calibrate weights against retained incident/outcome data; test missing, stale, malformed and contradictory observations.

#### RL-98 — Runtime CIS arbitration defaults to approval without identity- or evidence-bound authorization

**Status: Source-confirmed.** `TiannaraRuntime.CIS.Supervisor` is a GenServer arbitration kernel, distinct from the root `Tiannara.CIS.Supervisor` OTP supervisor. Its public `set_safety_mode/1` changes global safety mode without an actor, authenticated principal, Council grant or approval record. The decision function approves most combinations by default; for example, `:normal` mode with `:critical` severity returns `:approve`, and world suspension is approved for every mode except `:lockdown`. Decisions are recorded in a bounded in-memory list and emitted to Logger, not shown as durable, signed authorization evidence.

**Impact:** the API's existence and decision log do not establish constitutional authorization. Any caller able to reach the GenServer API can change the global mode, and most unspecified cases resolve to approval. A restart also loses the in-memory arbitration history and safety mode.

**Closure evidence:** bind every request to authenticated actor, target, operation, reason, evidence and policy version; require explicit policy outcomes with fail-closed defaults; protect safety-mode changes with Council/human authorization; persist tamper-evident decision receipts; test forged actors, malformed severity, missing evidence, restart and lockdown invariants.

#### RL-99 — Generic runtime ExecutionController path fails open when CIS is absent

**Status: Source-confirmed.** In `TiannaraRuntime.CIS.ExecutionController.handle_call({:execute, ...})`, an absent CIS process is mapped to `safety_mode = :normal`; the request then returns `:ok` and increments execution count. This differs from the module's kill path, which calls `CIS.Supervisor.authorize_kill/3` and will fail if the arbitration process is unavailable.

**Impact:** the generic public execution API can authorize an operation when the CIS kernel is missing. The fail-closed behavior documented for the kill path does not extend to the generic execution path.

**Closure evidence:** route every effectful operation through an explicit authorization result; treat missing CIS/Council/policy services as unavailable and deny; separate non-effectful validation from effectful execution; test missing-process and dependency-restart scenarios.

#### RL-100 — Runtime diversity/collapse/recovery workers are inert and outside the declared boot graph

**Status: Source-confirmed.** `TiannaraRuntime.CIS.DiversityRegulator`, `CollapseDetector` and `RecoveryOrchestrator` are defined in `tiannara_runtime/lib/tiannara_runtime/supervisors.ex`; their `init/1` functions only initialize counters and they expose no monitoring, detection or intervention APIs in the inspected definitions. They are children of `TiannaraRuntime.AEO.Supervisor`, but the runtime `RootSupervisor` child graph and `TiannaraRuntime.Application` child list inspected at the frozen SHA do not start `AEO.Supervisor`. The separately started `TiannaraRuntime.CIS.Supervisor` is the arbitration GenServer, not this AEO child supervisor.

**Impact:** documentation and module names can suggest active immune monitoring/recovery, but these workers are inert and their owning supervisor is not part of the declared runtime boot path. The similarly named CIS components also have different ownership and responsibilities across the two trees.

**Closure evidence:** choose one canonical runtime immune architecture; wire its supervisor into the actual application graph with explicit required/optional semantics; implement and test real monitoring, detection and recovery behaviors; expose readiness proving each worker is alive and processing real signals.

#### 18.6 Immunity and resilience disposition

- Root CIS has a grounded-input risk predictor but incomplete telemetry, symbolic response decisions and a log-only executor; an autonomous containment/recovery loop is not demonstrated.
- Runtime CIS arbitration is a separate GenServer authority with permissive defaults and no authenticated decision context in the inspected API.
- Runtime diversity/collapse/recovery workers are inert in the inspected source and their AEO supervisor is not part of the declared boot graph.
- Kill delivery and false `:executed` outcomes remain covered by RL-14 and the runtime execution findings; do not treat this initial CIS pass as a complete kill-chain certification.

**Checkpoint 18 immunity disposition:** RL-95–RL-100 remain open source-level findings at the frozen SHA. No code was changed and no tests were run. Continue into research/discovery and then mathematics, self-modification/self-improvement and security/governance, while preserving the cross-tree ownership distinctions.

### Checkpoint 18 continuation — research, hypothesis and discovery (initial source pass)

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** root ResearchDirector/KnowledgeIntegrator and selected runtime Phase 16.1 research modules. Source inspection only; no runtime tests or application changes.

#### Positive control observation — root ResearchDirector quarantines unexecuted experiments

The root `Tiannara.Research.ResearchDirector.Pipeline` explicitly records that R0 quarantine is active. Its advance path generates hypotheses and experiment plans, but when an experiment reaches the next stage it calls `quarantine_experiment/1` and emits `:quarantined_by_R0`; it does not fabricate and persist an experiment result. Preserve this truthful refusal until a real execution provider and evidence path are certified. This positive control does not close the independent findings below.

#### RL-101 — KnowledgeIntegrator reports integration success when Executive Memory persistence is absent or fails

**Status: Source-confirmed.** `KnowledgeIntegrator.handle_call({:integrate, ...})` calls `persist_to_executive_memory/1`, then emits integration telemetry and replies `:ok`. The persistence helper itself returns `:ok` when ExecutiveMemory is not running and catches all exceptions/exits from `ExecutiveMemory.put/3`, also returning `:ok`. The in-memory knowledge list and integrated counter are advanced regardless.

**Impact:** a validated finding can be reported as integrated even though no durable Executive Memory record was written. The current `:real_execution` and confidence checks do not establish successful persistence.

**Closure evidence:** propagate a durable write receipt; distinguish accepted, persisted, unavailable and failed; do not increment integrated counters or publish success before the authoritative store confirms the write; test absent store, write error, crash and readback.

#### RL-102 — ResearchDirector health endpoint hardcodes healthy status

**Status: Source-confirmed.** `Tiannara.Research.ResearchDirector.health/0` returns `status: :healthy` unconditionally while separately reading queue, ranker, planner, scorer and integrator counters. It does not derive health from child readiness, worker availability, quarantine/error rates or pipeline progress.

**Impact:** monitoring can classify the research subsystem as healthy when a required child is unavailable or the pipeline is stalled. Counts do not constitute readiness.

**Closure evidence:** probe every supervised child and its functional readiness; expose degraded/unknown states, queue age, stalled work, quarantine and persistence errors; test child loss and pipeline stagnation.

#### RL-103 — Phase 16.1 “Supervisor” is a caller-owned ETS initializer, not an OTP supervisor

**Status: Source-confirmed.** `TiannaraRuntime.AutonomousResearch.Phase16_1.Supervisor` does not use `Supervisor`, start a process or own a supervision tree. `init_all_tables/0` creates public named ETS tables in the calling process. The Phase 16.1 modules also create their tables lazily from their own API calls. ETS tables are owned by the process that creates them, so their lifetime is coupled to whichever caller happens to initialize them; the tables are public and therefore do not provide write isolation.

**Impact:** research state can disappear when a transient table-owning caller exits, and multiple callers can race to initialize or mutate shared tables. The module name and table list do not establish durable or supervised research state.

**Closure evidence:** use one long-lived supervised table owner or a durable store; define table ownership, access controls, restart/recovery and schema migration; test owner crash, concurrent initialization, process restart and persisted readback.

#### RL-104 — Runtime HypothesisEngine generates generic statements and fixed confidence rather than evidence-derived hypotheses

**Status: Source-confirmed.** `HypothesisEngine.create_hypothesis/3` ignores its `context` argument. `build_hypothesis/3` derives the ID from canonicalized evidence, but sets the statement to a generic string based only on a short question-ID prefix and fixes `confidence` and `uncertainty` at `0.5`. Validation only checks for hypothesis ID, question ID and a binary statement; it does not validate evidential support, falsifiability, uncertainty calibration or the evidence references.

**Impact:** the artifact is content-addressed to input evidence but its scientific claim is not actually derived from that evidence. A structurally valid hypothesis record must not be treated as a scientifically formed or calibrated hypothesis.

**Closure evidence:** generate a claim that explicitly references observations and context; require testable predictions and falsification criteria; validate evidence IDs and provenance; calculate uncertainty from a defined method; test contradictory, empty and insufficient evidence.

#### RL-105 — Runtime ResearchPlanner emits generic programs with no experiment plans

**Status: Source-confirmed.** `ResearchPlanner.build_program/1` creates a generic description from the question ID, emits one generic objective and a default statistical/evidence/stopping contract, and sets `"experiments" => []`. Its timestamp is fixed at `2000-01-01T00:00:00Z`. The deterministic ID is based only on the question ID, not the full research inputs or constraints.

**Impact:** the output is a static research-program template, not a plan derived from the evidence gap, hypothesis, domain, constraints or experiment design. Different research contexts for the same question ID can map to the same program ID.

**Closure evidence:** construct plans from validated question/hypothesis/evidence-gap and resource inputs; include concrete experiment references and dependencies; bind IDs to canonical complete inputs; distinguish template generation from executable research planning.

#### RL-106 — Runtime TheoryEngine returns new theories without registering them

**Status: Source-confirmed.** `TheoryEngine.create_theory/3` initializes the ETS table and builds a theory map, but returns it without inserting it into `:theories`. The module's `lookup_theory/1` and `list_theories/0` read only that table. A newly created theory therefore cannot be found through the module's own lookup/list APIs unless a separate uninspected caller inserts it.

**Impact:** the public create API suggests stateful theory creation while the record is not registered in the theory store. Subsequent proposal/supersession workflows cannot rely on that API as the canonical theory write.

**Closure evidence:** make create an acknowledged store operation or rename it to a pure builder; test create → lookup → list → restart/recovery and ensure hash/provenance invariants.

#### RL-107 — Runtime discovery-lineage replay returns a replay-shaped result without verifying stored lineage

**Status: Source-confirmed.** `DiscoveryLineage.replay_lineage/2` calls `rebuild_lineage_entry/2`, which hashes the supplied artifact ID and inputs and returns a map with `"replayed" => true`. It does not load the original lineage entry, compare input hashes, verify parent/output hashes or compare the reconstructed artifact to a stored certified artifact.

**Impact:** the returned `replayed: true` flag means only that a new minimal map was constructed; it does not prove deterministic replay or lineage integrity. This can be mistaken for scientific reproducibility evidence.

**Closure evidence:** load the original immutable lineage; verify every input, parent and output hash; compare reconstructed artifact hashes; return explicit verified/diverged/unavailable outcomes; test modified inputs, missing parents and tampered lineage.

#### 18.7 Research and discovery disposition

- The root ResearchDirector's R0 quarantine is a useful truthfulness safeguard: it plans and then quarantines experiments rather than fabricating outcomes.
- The root KnowledgeIntegrator can still report success without durable persistence, and ResearchDirector health is not a readiness measurement.
- Runtime Phase 16.1 contains useful research data-model scaffolding, but the inspected hypothesis, planner, theory and lineage implementations do not yet establish evidence-grounded hypothesis formation, executable experiment planning, theory registration or verified replay.
- This is an initial slice. It does not complete the audit of the separate Discovery pipeline, real experiment execution providers, falsification/replication, archaeology, or the full evidence-certification chain.

**Checkpoint 18 research disposition:** RL-101–RL-107 remain open source-level findings at the frozen SHA. No code was changed and no tests were run. Continue by tracing actual discovery/experiment execution and evidence certification before moving to mathematics and self-modification/self-improvement.

### Checkpoint 18 continuation — mathematics and formal reasoning (initial source pass)

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** root `Tiannara.Math` kernels and runtime Phase 16.X mathematics runtime/registry. Source inspection only; no runtime tests or application changes.

#### Positive control observations

The root tree includes bounded, candidly scoped mathematics: `ProofKernel` explicitly limits its supported formal fragment and does not claim external reality; `Optimization.gradient_descent/4` returns numerical candidates with convergence diagnostics and does not claim global optimality; `nash_equilibrium/2` explicitly returns unavailable; and `CounterexampleSearch` correctly states that exhausting a supplied finite domain is not a global proof. Preserve these truthfulness boundaries.

#### RL-108 — Runtime ExpressionExecutor reports completion without performing the expression operation

**Status: Source-confirmed.** `MathematicsRuntime.ExpressionExecutor.execute/1` accepts operation names such as simplify, expand, differentiate and integrate, but its body only constructs a result map containing the original expression ID, requested operation and `status: "completed"`. It does not load the expression, invoke `SymbolicEngine`, transform an expression tree or return a computed artifact.

**Impact:** a supported-operation label and completion status can be mistaken for actual symbolic computation.

**Closure evidence:** invoke the real symbolic engine and return the computed canonical expression plus input/output hashes; otherwise return an explicit unavailable/unsupported result. Test each operation against known mathematical identities and invalid expressions.

#### RL-109 — Runtime verification and replay coordinators certify metadata rather than mathematical correctness or recomputation

**Status: Source-confirmed.** `VerificationCoordinator.verify/1` sets `verification_status: "verified"` for proof, expression and conjecture results, and also for every unknown result type; it does not call a proof checker or formal verification engine. `ReplayCoordinator.check/1` hashes only `request_id`, `type` and `status`. `ReplayCoordinator.replay/1` constructs a replay-shaped status map and computes the same metadata hash; it does not re-execute the mathematical operation or compare outputs.

**Impact:** the runtime can label an operation verified and replayed without checking its mathematical result or reproducing the computation. These statuses cannot be used as proof/certification evidence.

**Closure evidence:** dispatch verification to type-specific checkers; reject unknown types; require proof-kernel/formal-verification receipts; replay from immutable input and dependency artifacts, recompute outputs and compare canonical output hashes; test tampering and divergent results.

#### RL-110 — Runtime dependency resolution marks every declared dependency resolved without resolving it

**Status: Source-confirmed.** `MathematicsRuntime.DependencyResolver.resolve/1` sorts the request's dependency IDs and maps each to `%{"resolved" => true}`. It does not query MathematicsRegistry, verify existence, check lifecycle state, validate dependency type or traverse transitive dependencies.

**Impact:** downstream scheduling/execution can proceed with missing, archived, frozen or incompatible mathematical dependencies while carrying a success-shaped resolved flag.

**Closure evidence:** resolve each dependency against the authoritative registry; validate lifecycle/type/version and transitive closure; fail closed on missing/cyclic/incompatible references; test unknown IDs, frozen artifacts and dependency graph cycles.

#### RL-111 — MathematicsRegistry state is public caller-owned ETS rather than supervised durable registry state

**Status: Source-confirmed.** `MathematicsRegistry.init_table/0` creates a public named ETS table directly in whichever process first invokes it. The module has no table-owning GenServer/supervisor or persistence/recovery contract in the inspected implementation. The table is writable by any process in the VM and its lifetime is tied to its owner process.

**Impact:** registry contents can disappear when the first caller exits, and arbitrary processes can mutate artifact registrations/lifecycle state outside the module's validation functions.

**Closure evidence:** establish a long-lived supervised owner or durable transactional store; restrict write access to the registry API; add recovery/schema migration; test owner crash, restart, concurrent registration and unauthorized mutation.

#### RL-112 — Typed MathematicsRuntime convenience APIs do not bind the requested operation type

**Status: Source-confirmed.** `execute_proof/1`, `execute_conjecture/1` and `execute_verification/1` call `execute(request, %{type: "..."} )`, but `execute/2` expects keyword options and the supplied map is passed only to the scheduler, whose `schedule/2` ignores its options. Dispatch later reads `request["type"]`, defaulting to `"expression"`. Thus a request without an explicit string `"type"` sent through one of the typed convenience APIs is dispatched as an expression rather than the named operation.

**Impact:** callers can request proof/conjecture/verification through a typed API but receive expression dispatch or an unrelated error, depending on request contents.

**Closure evidence:** encode and validate operation type in the request before dependency resolution; use one canonical type representation; test each convenience API with omitted, conflicting and invalid type fields.

#### RL-113 — Root Bayesian and entropy functions do not validate probability distributions

**Status: Source-confirmed.** `Tiannara.Math.Probability.bayes_update/3` checks only that `evidence_prob > 0`; it does not validate that prior and likelihood are finite probabilities in [0,1], that evidence probability is valid or that the posterior is a valid probability. `shannon_entropy/1` filters non-positive entries but does not reject values greater than 1, non-finite values or a list whose probabilities do not sum to 1.

**Impact:** invalid inputs can produce numeric outputs that look like valid Bayesian posteriors or Shannon entropy values. Downstream confidence/risk calculations can consume mathematically invalid quantities.

**Closure evidence:** validate finite numeric inputs and probability bounds; define normalization policy explicitly (reject vs normalize); check denominator and posterior consistency; test negative, >1, NaN/infinite, zero-sum and non-normalized distributions.

#### RL-114 — Runtime mathematical validation campaign converts thrown campaign failures into successful transport results

**Status: Source-confirmed.** `Mathematics.Validation.Validator.run_campaign/2` catches exceptions and exits from a campaign and returns `{:ok, %{status: :error, ...}}` rather than an error tuple. The outer `run/1` therefore takes the success-shaped branch for a crashed campaign and relies on the embedded `status: :error` to aggregate the overall result.

**Impact:** callers that treat the outer `{:ok, result}` as execution success can misread a crashed campaign. The internal aggregate does detect the embedded error, but the public transport contract is ambiguous.

**Closure evidence:** return an explicit error tuple for execution failure or use a distinct tagged completed-with-errors result; ensure every consumer checks the aggregate status and campaign statuses; test raised, exited, timeout and malformed campaign results.

#### 18.8 Mathematics disposition

- Root proof checking, bounded optimization and finite-domain counterexample search have useful explicit limits and truthful unsupported states.
- Runtime Phase 16.X contains substantial schemas and campaign scaffolding, but the inspected top-level execution path contains metadata-only expression completion, unconditional verification labels, metadata-only replay and placeholder dependency resolution.
- The runtime MathematicsRegistry has a separate ETS ownership/access problem; root probability helpers lack input-domain validation.
- Certification reports and passing campaign declarations are not substitutes for verifying that campaigns exercise the real mathematical execution path.

**Checkpoint 18 mathematics disposition:** RL-108–RL-114 remain open source-level findings at the frozen SHA. No code was changed and no tests were run. Continue with self-modification/self-improvement and then the security/governance cross-cut before consolidating the full architecture atlas.

### Checkpoint 18 continuation — self-improvement and self-modification (initial source pass)

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** root Ω.4 ConstitutionalAutonomy, deployment/rollback, separate SelfImprovement dry-run pipeline, and ToolForge. Source inspection only; no runtime tests or application changes.

#### Positive control observations

- `ConstitutionalAutonomy.Orchestrator` refuses to run its full cycle unless real execution is enabled and a real simulation provider exists; `real_simulation_provider?/0` currently returns `false`. This prevents its normal orchestrator path from reaching simulated deployment.
- `RollbackEngine.rollback/2` truthfully returns `{:error, :rollback_unavailable}` rather than fabricating a successful rollback.
- The separate `Tiannara.SelfImprovement.Pipeline` defaults deployment to disabled and requires explicit gate results; protected-core changes additionally require an independent-verification gate. The real-code sandbox backends copy the baseline into a temporary workspace and run build/test/benchmark commands there.

These safeguards should be preserved. The findings below concern bypassable public paths and the integrity of gate evidence.

#### RL-115 — DeploymentPipeline can mark arbitrary input as deployed without validation or simulation proof

**Status: Source-confirmed.** `DeploymentPipeline.deploy/1` accepts any map and does not require a validated proposal, a passing simulation verdict, a certificate, or an authenticated approval. If `simulation[:proposal]` is absent, it defaults to an empty map and `human_required` becomes false; `proceed_with_deployment/3` then moves the record to `:monitoring`. The handler increments `total_deployed` at initiation. The orchestrator's hardcoded no-provider gate does not prevent direct calls to this public API.

**Impact:** callers can create deployment records and increment the deployed counter without a verified improvement artifact or the full constitutional workflow. The current path records lifecycle metadata; it does not prove code was deployed.

**Closure evidence:** make deployment consume an immutable, signed/certified simulation artifact and validated proposal ID; verify all required gates and approvals inside the deployment authority itself; distinguish initiated, applied, monitored, promoted and rolled back; deny arbitrary maps and direct bypass calls.

#### RL-116 — SimulationManager manufactures improvement measurements from random baselines and a formula

**Status: Source-confirmed.** `SimulationManager.measure_baseline/1` creates latency and throughput using `:rand.uniform/0`, uses a random error rate, and measures only current VM memory. `simulate_improvement/2` derives proposed metrics by multiplying baseline values by `expected_impact`; it does not apply a patch, run an isolated system, or benchmark the changed implementation. It then labels a ratio above 1.05 statistically significant without a sampling distribution or statistical test.

**Impact:** direct callers can receive plausible-looking but synthetic performance evidence. The normal ConstitutionalAutonomy orchestrator is currently blocked by `real_simulation_provider?/0 == false`, but the public SimulationManager API itself is not a real simulation provider.

**Closure evidence:** require a real isolated sandbox/build/test/benchmark provider; preserve raw samples and environment metadata; use statistical comparison only when sample sizes and assumptions justify it; label synthetic estimates as estimates and make them ineligible for deployment.

#### RL-117 — SelfImprovement dry-run can self-assert independent verification through a caller-controlled boolean

**Status: Source-confirmed.** `DryRun.execute/2` reads `config.independent_verification`; when truthy, `build_gate_results/6` creates an `independent_verification` GateResult with source `:external_auditor`. The protected-core sandbox pre-check and constitutional review also trust this boolean. `Pipeline.independent_verified?/1` accepts any non-nil source other than `:self_improvement`; it does not verify a signature, auditor identity, external receipt or evidence binding.

**Impact:** a caller-controlled boolean can be converted into an apparently external verification attestation. The protected-core boundary is therefore not independently authenticated by the inspected implementation.

**Closure evidence:** accept only a signed verification receipt from a configured independent verifier; bind it to the exact patch hash, baseline hash, target set and test results; verify signer authorization and expiry; never derive external provenance from a boolean or caller-supplied source label.

#### RL-118 — Protected-core target detection relies on exact labels rather than canonical target identity

**Status: Source-confirmed.** `ProtectedCore.touches_protected?/1` checks whether any supplied target is exactly one of `:authorization`, `:constitutional`, `:audit` or `:safety`. The inspected gate does not canonicalize file paths, module names, aliases or nested subsystem identities before checking. `DryRun` passes `patch.targets` directly into this equality check.

**Impact:** a protected file/module can be represented by a different string, path or alias and fail to match the protected labels. Whether a particular patch can exploit this depends on the upstream target contract, which remains to be traced.

**Closure evidence:** resolve patch targets to canonical repository paths and module ownership; classify protected paths from a separately governed manifest; reject unknown/unresolved targets; test aliases, path variants, nested modules and mixed target lists.

#### RL-119 — ToolForge's human-review step is not an approval gate and generated tools are mostly placeholders

**Status: Source-confirmed.** `ToolForgeEngine.request_human_review/2` constructs a HAI ReviewRequest but does not submit it to a review router or await a decision; it returns `:ok` after construction and rescues every exception to `:ok`. The pipeline therefore logs that human review passed regardless of whether HAI is available or a human approved. In `ToolBuilder`, generated Elixir tools implement `do_execute/1` as an explicit `:not_implemented` error, while generated Python tools return a fixed status/input echo rather than a specification-derived implementation.

**Impact:** a generated artifact can pass ToolForge's validation and be described as human-reviewed even though no approval occurred and the tool's core behavior is not implemented. Build success must not be conflated with operational capability.

**Closure evidence:** integrate with an authenticated HAI review workflow and require a durable decision receipt; distinguish generated, built, tested, approved and deployed states; generate implementations from verified specifications; run real behavioral, security and integration tests before promotion.

#### RL-120 — Deployment monitoring state has no observed deployment or automatic rollback mechanism

**Status: Source-confirmed.** `DeploymentPipeline.proceed_with_deployment/3` creates a checkpoint ID, sets timestamps and moves the deployment to `:monitoring`; it does not apply a code/configuration change, start a monitoring process or schedule a promotion/rollback decision. The `monitoring_until` field is metadata only in the inspected module. The separate RollbackEngine explicitly reports rollback unavailable.

**Impact:** a deployment can remain labelled `:monitoring` without a verified deployment substrate, actual health observation or automatic rollback. The pipeline's monitoring stage is currently a record state, not demonstrated operational monitoring.

**Closure evidence:** connect to a real deployment provider and checkpoint store; require deployment receipts; run health/performance monitoring against defined thresholds; trigger and verify rollback against the actual checkpoint; distinguish unavailable rollback from rollback-ready.

#### 18.9 Self-improvement disposition

- The normal Ω.4 orchestrator is safely blocked from full-cycle simulation/deployment because no real simulation provider is configured.
- The separate dry-run pipeline has a useful real sandbox abstraction and explicit protected-core intent, but caller-supplied independent-verification metadata can satisfy the gate without an authenticated external receipt.
- Direct DeploymentPipeline and SimulationManager APIs bypass the orchestrator's no-provider guard and can produce synthetic simulation/deployment records.
- ToolForge currently builds templates/placeholders and does not enforce actual human approval.

**Checkpoint 18 self-improvement disposition:** RL-115–RL-120 remain open source-level findings at the frozen SHA. No code was changed and no tests were run. Continue with security/governance and cross-system authority before proposing any remediation.

### Checkpoint 18 continuation — constitutional security and governance (initial source pass)

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** root Council, human approval, policy/constitution repositories and CEL service control. Source inspection only; no runtime tests or application changes.

#### Positive control observations

- Council's authorization path re-evaluates a human-approved decision against policy and RuleEngine rather than treating the approval record alone as authorization.
- `Authorization.permitted?/1` grants only `:approved`; conditional grants have a separate evidence-condition check.
- Council's AuditLog has a hash chain, DETS sync, corruption detection and an explicit degraded mode that rejects new appends.
- CEL Kernel restart/halt paths consult Council and use strict authorization predicates.

These are meaningful safeguards, but the inspected mutation and identity paths still contain bypasses.

#### RL-121 — Human approvals and emergency lifting trust caller-supplied human identifiers

**Status: Source-confirmed.** `HumanApprovalQueue.approve/3` and `reject/3` accept a caller-supplied `human_id`, record it as the decision-maker and do not authenticate the principal, check a role/credential, verify a signed session or consult an identity provider. `Council.invoke_emergency/2` similarly trusts its supplied actor. More critically, `Council.lift_emergency/1` clears an active emergency for any supplied `human_id` without verifying that the caller is an authorized human.

**Impact:** the audit record can identify an unverified string/atom as a human approver or emergency lifter. The human-final-authority boundary is not established by the existence of an approval queue or actor field.

**Closure evidence:** derive principal identity from an authenticated session/token that callers cannot self-assert; enforce role/authority and multi-factor/second-person policy for sensitive actions; bind approval to exact payload hash and policy version; require authenticated human authority to lift emergency; test spoofed IDs and unauthorized callers.

#### RL-122 — Council PolicyRegistry policy mutation is not authorization-gated or schema-validated

**Status: Source-confirmed.** `PolicyRegistry.register_policy/1` writes the supplied policy directly into the in-memory policy map, including replacing an existing policy with the same ID. `disable_policy/1` disables any registered policy. Neither operation calls Council authorization, requires human approval, validates the policy schema/priority/action/conditions or records a durable policy-version receipt. If no policy matches, `evaluate/2` returns `{:default_approve, nil}` and delegates to RuleEngine.

**Impact:** policy definitions governing human approval and simulation requirements can be changed or disabled through direct service APIs without a demonstrated constitutional amendment/authorization process. The fallback RuleEngine remains a safeguard, but it does not replace the missing governance controls over policy lifecycle.

**Closure evidence:** make policy registry mutation Council-authorized and auditable; freeze non-overridable baseline policies; validate policy schemas and conflict/priority rules; require versioned signed policy artifacts; test policy overwrite, disable, wildcard and default paths.

#### RL-123 — ConstitutionRepository exposes direct commit/rollback without Council authorization and ignores write results

**Status: Source-confirmed.** `ConstitutionRepository.commit/3` writes the supplied constitution directly to DETS and updates `current_version` without validating an approved amendment, checking actor authority, verifying immutable constitutional constraints or checking the result of `:dets.insert/2`. `rollback/2` changes the current-version pointer for any existing version based on a caller-supplied actor, without Council authorization or a corresponding AuditLog append in the handler.

**Impact:** callers can mutate the canonical constitution pointer through direct APIs without the normal governance path. A failed DETS write can also be followed by a success-shaped response and an updated in-memory current version.

**Closure evidence:** make commit/rollback private to a Council-governed amendment service; require verified ratification and immutable-core checks; check DETS insert/sync results before acknowledgement; append a durable audit event atomically; test direct unauthorized calls, failed writes, rollback and restart consistency.

#### RL-124 — AmendmentEngine's simulation/evaluation are heuristic labels and approval is not authenticated or committed to the canonical repository

**Status: Source-confirmed.** `AmendmentEngine.run_simulation/2` assigns risk from the count of affected principles and whether any proposed change has type `:invariant`; it does not simulate the proposed constitutional changes against runtime behavior. `evaluate_against_principles/2` marks affected principles `:strengthened` and all others `:unaffected` without evaluating the content of the changes. `approve/2` accepts any caller-supplied `human_id` after the amendment reaches `:awaiting_human`; it updates only the AmendmentEngine's in-memory constitution and amendment state. The inspected path does not commit the new constitution through `ConstitutionRepository`.

**Impact:** the amendment flow can report simulated/evaluated/approved states without a substantive simulation, semantic constitutional review, authenticated human ratification or canonical persisted constitution update.

**Closure evidence:** require actual before/after principle evaluation and adversarial simulation; authenticate ratifiers and enforce quorum/role requirements; bind approvals to the exact proposed constitution hash; commit through the canonical repository only after ratification and verified durable write; test restart and repository readback.

#### RL-125 — CEL Kernel restart_service ignores the supplied actor in the Council authorization payload

**Status: Source-confirmed.** `CEL.Kernel.restart_service/2` accepts `actor` but calls `Council.authorize(:architectural_change, %{action: :restart, service: id}, nil)`; the actor is omitted from the payload and no ExecutionContext is passed. The policy and approval queue therefore bind to the action/service payload, not the identity of the caller requesting the restart.

**Impact:** an approval for a particular service restart is not tied to the requesting principal. Combined with the unauthenticated approval API, the authorization receipt cannot prove who requested or approved the operation.

**Closure evidence:** construct ExecutionContext from authenticated identity; include actor, purpose, target, evidence and request correlation in the authorization payload; bind approval to that exact context; reject missing or mismatched principals; test cross-actor approval reuse.

#### RL-126 — CEL ServiceRegistry mutators can change the boot/service graph without Council authorization

**Status: Source-confirmed.** `ServiceRegistry.register/1`, `deprecate/1` and `replace/2` directly mutate the service-spec map in the GenServer. The handlers do not consult Council, validate a signed service manifest, enforce immutable critical-service ownership or append an audit event. `replace/2` also marks the old ID deprecated and inserts the new spec without first validating the replacement or confirming the old ID exists.

**Impact:** the service boot order, dependency graph and module selected for a service ID can be changed through direct registry APIs without a demonstrated architectural-change authorization. This is a control-plane and supply-chain trust boundary.

**Closure evidence:** require Council approval for service graph changes; validate module identity, dependency closure, criticality, capabilities and version; preserve immutable signed manifests and change history; atomically validate replacements; test unauthorized mutation and malformed dependency graphs.

#### 18.10 Security and governance disposition

- Council has stronger authorization/evidence structure than the earlier executive and runtime CIS paths, but human identity is not authenticated at the approval/emergency APIs.
- Policy and service registries expose direct mutation paths without Council authorization.
- The canonical constitution repository exposes direct commit/rollback methods that bypass ratification and ignore persistence results.
- The amendment engine's simulation/evaluation are heuristic summaries, not substantive constitutional simulation, and its approval state is not shown committed to the canonical repository.
- CEL Kernel uses Council on service restart/halt, but restart authorization omits the supplied actor.

**Checkpoint 18 security/governance disposition:** RL-121–RL-126 remain open source-level findings at the frozen SHA. No code was changed and no tests were run. The next step is a cross-system authority graph: identify every public effect/mutation API, its authenticated principal, Council gate, evidence receipt, durable audit record and actual effect provider.

### Checkpoint 18.11 — provisional cross-system authority and ownership graph

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Purpose:** reconcile the executive, cognitive, immune, research, mathematics, self-improvement and governance source passes into one provisional control/ownership map. This is a source-declared graph, not a runtime-observed process graph.

```text
ROOT TIANNARA APPLICATION (root lib/)
│
├─ Council.Supervisor  [constitutional authority]
│  ├─ AuditLog
│  ├─ ConstitutionRepository
│  ├─ PolicyRegistry
│  ├─ HumanApprovalQueue → HumanApprovalResumer → Council re-evaluation
│  ├─ AmendmentEngine
│  ├─ ConstitutionalMonitor
│  └─ Council
│
├─ CEL.Kernel  [service boot/control plane]
│  ├─ DynamicSupervisor for CEL services
│  └─ ServiceRegistry / BootSequencer
│      └─ service graph mutation APIs require separate governance review
│
├─ Executive.Supervisor  [executive coordination]
│  ├─ EventStore
│  ├─ EventBus
│  ├─ ExecutiveMemory
│  └─ Coordinator
│
├─ ExecutiveCognitiveRuntime  [ECR loop]
│  ├─ Blackboard / WorkingMemory / ContextManager / Attention
│  ├─ ReflectionEngine / ExecutiveCycle / Heartbeat
│  └─ heartbeat telemetry also advances Omega.AgencyLoop
│
├─ OmegaRuntime
│  ├─ RuntimeHealthAggregator
│  ├─ ConstitutionalComplianceMonitor
│  ├─ Observatory
│  └─ AgencyLoop
│
├─ ResearchDirector  [root research pipeline]
│  ├─ HypothesisRanker / ExperimentPlanner / ResearchQueue
│  ├─ EvidenceScorer / KnowledgeIntegrator
│  └─ Pipeline (R0 experiment quarantine)
│
├─ CIS.Supervisor  [root CIS supervisor]
│  ├─ empty CISRegistry
│  ├─ CollapsePredictor
│  ├─ ImmuneDecisionEngine
│  └─ RegulationExecutor
│
└─ ConstitutionalAutonomy / ToolForge
   ├─ Ω.4 proposal/validation/simulation/deployment/rollback
   └─ tool generation and review request plumbing


SEPARATE RUNTIME APPLICATION (tiannara_runtime/lib/)
│
└─ TiannaraRuntime.Application
   └─ outer Supervisor (:one_for_one)
      ├─ StartupSupervisor (:rest_for_one)
      │  ├─ ConstitutionalPersistenceLayer
      │  ├─ Omega
      │  ├─ COP
      │  ├─ Endpoint
      │  ├─ RootSupervisor
      │  └─ DiscoveryRunner
      │
      ├─ CIS.Supervisor (GenServer arbitration kernel)
      ├─ MultiWorld.KillSwitch
      ├─ MultiWorld.WorldSupervisor
      ├─ CIS.ExecutionController
      ├─ Resources.QuotaGovernor
      ├─ Memory.LineageCompression
      └─ Causal.GCK

   AEO.Supervisor (contains runtime diversity/collapse/recovery stubs)
   └─ not in the inspected Application/RootSupervisor boot graph
```

#### Authority and integration seams

1. **Constitutional decision vs. executive execution:** Council is the root constitutional decision authority, but the root Executive Coordinator uses its own simple consensus path and does not demonstrate Council authorization for each submitted command (RL-77/RL-78). CEL Kernel restart/halt is Council-gated, but service registry mutation and actor binding remain gaps (RL-122/RL-125/RL-126).
2. **Emergency and override authority:** root CivilizationKernel caller-supplied human override/rollback paths bypass Council authorization and validation (RL-82); Council emergency lifting and human approvals do not authenticate the claimed human identity (RL-121).
3. **Cognitive orchestration:** ECR and Omega AgencyLoop are separate phase machines triggered by the same heartbeat and writing shared memory/blackboard state (RL-91). Their phase success is not equivalent to completed research, execution or learning (RL-79/RL-92).
4. **Research and knowledge authority:** root ResearchDirector quarantines experiments, which is a positive control, but KnowledgeIntegrator can report success without durable memory persistence (RL-101). Runtime Phase 16.1 ETS research stores have no demonstrated supervised owner (RL-103).
5. **Immune and kill authority:** root CIS is separate from runtime CIS arbitration. Runtime kill operations pass through CIS ExecutionController for the dedicated kill path, but the generic execute path defaults to normal when CIS is absent (RL-99). Runtime diversity/collapse/recovery workers are not active in the inspected boot graph (RL-100).
6. **Mathematical verification authority:** the root ProofKernel is bounded and explicit about its limits; the runtime MathematicsRuntime has metadata-only verification/replay and expression completion paths (RL-108/RL-109). Its output must not be accepted as a certificate without real computation and independent checking.
7. **Self-improvement authority:** normal Ω.4 orchestration is blocked because no real simulation provider exists, but direct SimulationManager/DeploymentPipeline APIs can create synthetic simulation/deployment states (RL-115/RL-116). The separate dry-run pipeline's independent-verification flag is caller-controlled (RL-117).
8. **Persistence and evidence authority:** root EventStore/EventBus/ExecutiveMemory and CEL ExecutiveMemory are distinct; runtime Omega ExecutiveMemory and CPL add more stores. No canonical cross-tree event/decision transaction or reconciliation contract has been demonstrated (RL-81/RL-87/RL-90/RL-101/RL-103/RL-111).

#### Provisional architecture conclusions

- The repository contains multiple separately supervised applications/control planes; names and documentation do not establish a shared authority contract.
- The highest-risk gaps are not simply missing algorithms: they are authorization bypasses, false success/verification, unowned or volatile state, unverified human identity, and unclear execution/persistence receipts.
- The architecture should be reconciled around explicit authority boundaries and evidence contracts before module consolidation. Preserve the root Council as constitutional authority; preserve human control over constitutional/self-modification decisions; do not let runtime CIS, CEL, Ω, or D15-like subsystems silently assume Council authority.
- No implementation change is authorized by this audit. Remediation should be sequenced only after the remaining caller graph and cross-system tests establish the actual production paths.

**Checkpoint 18.11 disposition:** provisional source-declared ownership graph recorded. The audit is not complete: remaining work includes exact caller/effect tracing for all public mutation APIs, immunity-to-kill end-to-end behavior, discovery experiment execution/replication/archaeology, full mathematical campaign-to-runtime binding, and verification of all security boundaries.

### Checkpoint 18.12 — runtime authority and effect tracing

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Mode:** Read-only source trace across `CIS.Supervisor`, `ExecutionController`, `KillSwitch`, `WorldSupervisor`, and quota systems. No application files modified.

#### RL-127 — Execution is reported despite failed delivery or unconfirmed termination

**Status: Source-confirmed.** The execution path reports an operation as executed even when command delivery fails or process termination has not been observed. Message delivery, process exit and completed cleanup are distinct states.

**Closure evidence:** expose separate authorization, delivery, termination-observation and reconciliation outcomes; test unavailable targets and failed delivery.

#### RL-128 — Emergency shutdown acknowledgement does not perform shutdown

**Status: Source-confirmed.** Emergency shutdown returns `:initiated`, but the inspected handler performs no shutdown action.

**Closure evidence:** bind acknowledgement to an actual shutdown request and verify the resulting runtime state and process population.

#### RL-129 — Public world termination bypasses documented CIS authorization

**Status: Source-confirmed.** Public termination APIs provide a route around the documented CIS authorization path.

**Closure evidence:** inventory every termination entry point; enforce one authorization boundary and test direct API bypass attempts.

#### RL-130 — World spawning continues after quota or memory allocation rejection

**Status: Source-confirmed.** Error branches log and return error tuples locally but do not halt the enclosing spawn function. Subsequent initialization and child-start operations can continue without successful reservations.

**Closure evidence:** prove quota and memory admission are mandatory gates and every partial allocation is rolled back.

#### RL-131 — ResourceQuota cast handlers return invalid GenServer callback tuples

**Status: Source-confirmed.** The inspected cast handlers return `{:ok, state}`-shaped values rather than `{:noreply, state}`.

**Closure evidence:** correct callback contracts and exercise every cast branch while asserting the process remains alive and state is reconciled.

#### RL-132 — Integration tests do not exercise authorization through actual world-process exit

**Status: Coverage gap confirmed.** The test described as a complete kill flow invokes generic `ExecutionController.execute/4`, which does not exercise the dedicated CIS authorization and delivery functions. Its passing result cannot certify the production kill chain.

**Closure evidence:** start a real world through the production spawn path, issue an authorized termination, observe process exit, and verify all registries and resource accounting.

#### RL-133 — CIS arbitration is fixed severity/mode mapping, not evidence-based operation policy

**Status: Source-confirmed.** The inspected arbitration is a fixed severity/mode table; it does not demonstrate evidence-grounded, operation-specific policy evaluation.

**Closure evidence:** bind each operation to policy, evidence, actor, target, context and a traceable authorization decision; test contradictory and insufficient evidence.

#### RL-134 — Root CIS decisions are not connected to verified enforcement

**Status: Source-confirmed.** Root `ImmuneDecisionEngine` can produce `:quarantine` or `:monitor`, but the root `RegulationExecutor` records the requested action without demonstrating that the corresponding regulatory effect occurred.

**Closure evidence:** require an effect provider, result-bearing acknowledgement and independent observation of the regulated state.

#### RL-135 — Runtime immune responses lack a grounded signal-to-effect evidence chain

**Status: Source-confirmed.** The runtime collapse predictor uses a random risk value rather than deriving risk from the supplied snapshot. The immune engine maps incoming signals to fixed regulation commands, and the executor sends casts without requiring confirmation of the resulting state.

**Closure evidence:** derive risk from validated observations; retain signal, features, decision, policy, command, effect receipt and observed postcondition; test false signals and failed enforcement.

#### Checkpoint 18.12 disposition

RL-127–RL-135 remain open. The presence of an arbitration path is not proof of authorized effect, and a success-shaped response is not proof of process termination or completed resource reconciliation.

### Checkpoint 18.13 — world lifecycle, persistence and archaeological continuity

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Repository:** `Kimiti4/Tiannara`  
**Mode:** Immutable source inspection through GitHub at the exact baseline. No application source modifications and no runtime tests in this checkpoint.

#### RL-136 — WorldFreeze snapshots are volatile and do not capture actual world state

**Status: Source-confirmed.** In `tiannara_runtime/lib/tiannara_runtime/multi_world/world_freeze.ex`, `capture_world_state/1` explicitly describes querying the world's GenServer as future work and returns placeholder agents, coalitions, CIS/CAL parameters, event history and RNG state. Snapshot history and snapshot payloads are stored in the GenServer's in-memory maps.

**Impact:** a snapshot can be returned and listed without representing the actual world or surviving WorldFreeze process loss.

**Closure evidence:** capture from the authoritative world owner; persist a versioned complete state artifact; verify hashes and schema; restart the runtime and prove exact round-trip recovery.

#### RL-137 — Snapshot restoration does not restore the world

**Status: Source-confirmed.** `restore_world_state/2` only logs agent and coalition counts. It does not send state to the world process or reconstruct a running world. Snapshot import similarly decodes JSON into in-memory storage without establishing a durable archive or authenticated identity.

**Closure evidence:** restore into an isolated world, compare canonical state roots and event positions, and prove failed/partial restores cannot be reported as successful.

#### RL-138 — WorldRegistry lineage and extinction records are volatile

**Status: Source-confirmed.** `tiannara_runtime/lib/tiannara_runtime/world_registry.ex` stores world metadata, parent-to-child lineage and counters in GenServer state only. Termination marks a world `:extinct`; no durable historical record or restart reconstruction is implemented in the inspected module. `list_worlds/0` returns active worlds only.

**Impact:** process restart can erase the registry's world identities and lineage; extinction is not an independently addressable historical archive.

**Closure evidence:** durable append-only world catalogue and lineage records, restart reconstruction, immutable identity, and queries that include extinct worlds.

#### RL-139 — WorldRegistry accepts missing parents and can corrupt active counts on repeated extinction

**Status: Source-confirmed.** `create_world/2` does not validate that a supplied parent exists; `get_generation/2` silently returns zero for an unknown parent. `terminate_world/1` decrements `active_count` whenever the world record exists, without requiring its prior status to be active. Repeated termination can therefore decrement the count more than once.

**Closure evidence:** enforce parent foreign-key and status invariants; make extinction idempotent; derive or reconcile counters from authoritative records; test missing parents and repeated termination.

#### RL-140 — WorldForkEngine child identity is inconsistent with WorldRegistry identity

**Status: Source-confirmed.** `tiannara_runtime/lib/tiannara_runtime/world_fork_engine.ex` generates a child ID, then calls `WorldRegistry.create_world/2`, which independently generates another UUID. The caller pattern-matches the registry result against the first ID. The inspected code therefore cannot establish a consistent child identity and can fail at the case match.

**Closure evidence:** allocate the canonical ID once and pass it through registry, supervisor, process, event and lineage records; assert identity equality end-to-end.

#### RL-141 — Fork success can be reported when child supervisor startup fails

**Status: Source-confirmed.** `WorldForkEngine.create_child_world/2` ignores the result of `spawn_world_supervisor/1` and proceeds to add the child to lineage and return success. A failed supervisor start can therefore leave a registry/lineage record for a child that is not running.

**Closure evidence:** propagate startup errors; atomically roll back registry and lineage changes; verify a live child process and resource reservations before returning success.

#### RL-142 — Fork cloning does not demonstrate a complete live-world state clone

**Status: Source-confirmed.** `deep_clone_state/1` copies only `cal_state`, `cis_state`, `coalitions`, `entropy` and `coherence` from the registry metadata. The inspected path does not obtain a consistent snapshot from the authoritative live parent process or preserve complete agent, event, RNG and persistence state.

**Closure evidence:** freeze or otherwise obtain a consistent parent snapshot; clone the canonical state artifact; record parent snapshot hash and mutation delta; test deterministic divergence and parent immutability.

#### RL-143 — Extinction is not coupled to durable final-state archival

**Status: Source-confirmed at the inspected paths.** WorldRegistry extinction only changes metadata status. The MultiWorld termination path attempts a pre-termination WorldFreeze snapshot, but that snapshot is placeholder and volatile (RL-136); stopping deterministic recording removes the active recording from in-memory state, while export is a separate explicit operation. No atomic finalization protocol binds final state, event history, lineage, termination reason and resource reconciliation into a durable historical record.

**Closure evidence:** require a finalization transaction or recoverable staged protocol that seals final snapshot, event-log root, lineage, termination metadata and resource receipts before marking a world archived/extinct.

#### RL-144 — Archaeological reconstruction of prior simulated civilizations is unavailable

**Status: Source-confirmed.** Root `lib/tiannara/archaeology/archaeology.ex` implements FossilExcavator, SemanticReconstructor, EpochCompressor and IdentityPreserver as explicit fail-closed functions returning `{:error, :archaeology_simulation_unavailable}`. This is an honest refusal, not an implemented excavation capability. `SCIENTIFIC_ARCHAEOLOGY.md` specifies a reconstruction procedure but states that an independent long-horizon replay bundle is absent. The runtime archaeology audit's one-record/9-artifact coverage does not establish prior-world excavation.

**Impact:** no demonstrated end-to-end path allows a later world to discover and reconstruct the artifacts, institutions, technologies, observations and knowledge of an extinct world.

**Closure evidence:** create immutable world-history archives and a canonical archaeological index; demonstrate discovery by a later world without direct access to the extinct world's process; verify artifact provenance, stratigraphic context, evidence hashes, reconstruction uncertainty, contradictory evidence and reproducible findings.

#### RL-145 — Historical archaeology specifications and executable runtime archives are not connected

**Status: Source-confirmed gap.** `DISCOVERY_ARCHAEOLOGY.md` reports a validation kernel that reconstructs state from immutable map/list artifacts and explicitly leaves end-to-end archaeology across legacy registries pending a canonical export adapter. `SCIENTIFIC_ARCHAEOLOGY.md` requires manifests, hashes, schema versions, replay and state-root comparisons, but no independent long-horizon archaeological replay bundle is present. The runtime snapshot and registry implementations inspected above do not supply that durable artifact chain.

**Closure evidence:** connect live world event/state writers to canonical archival exports; independently ingest and reconstruct those exports; verify ordering, lineage, evidence roots and state roots across restart and long-horizon replay.

#### Checkpoint 18.13 — positive controls and disposition

- The root archaeology functions now fail closed instead of returning fabricated recovery scores. Preserve this behavior until real recovery substrate exists.
- `SCIENTIFIC_ARCHAEOLOGY.md` and `DISCOVERY_ARCHAEOLOGY.md` contain useful integrity and reconstruction specifications, but they are not evidence that the live multi-world runtime produces the required archives.
- WorldRegistry's extinct status, WorldFreeze's snapshot API and DeterministicReplay's export API are not equivalent to a durable historical archive.
- No source changes or runtime tests were performed in this checkpoint.

**Checkpoint 18.13 disposition:** RL-136–RL-145 remain open. The next audit pass should trace the authoritative world process implementation and all state/event writers, then determine whether the root world model, runtime world registry, replay/event stores and archaeological schemas can be joined into one verified world-history archive without conflating their separate ownership boundaries.

### Checkpoint 18.14 — authoritative world state, event ownership and historical persistence

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Method:** Exact-baseline source inspection of root world model, reality graph, mutation engine, snapshots, versioning, temporal replay, executive event store and runtime world-process paths. No application files modified; no runtime tests executed.

#### RL-146 — Durable mutation record can diverge from actual world-model effect

**Status: Source-confirmed.** `UnifiedWorldModel.create_entity/1` first records an authorized mutation through `WorldMutationEngine.mutate/3`, then attempts the graph write and only afterwards updates local counters and publishes the entity event. A failed graph write can leave a durable mutation record without a corresponding graph entity. Conversely, the mutation engine inserts the DETS mutation record before audit-receipt verification; if audit verification fails, it returns an error while exposing that the mutation was already recorded.

**Closure evidence:** define explicit prepared/committed/compensating/failed states; reconcile the mutation log, graph, counters, audit receipt and event publication; inject failures after each stage and prove recovery is idempotent.

#### RL-147 — UnifiedRealityGraph is process-memory state, not a durable canonical graph

**Status: Source-confirmed.** `Tiannara.Graph.UnifiedRealityGraph.init/1` creates an in-memory `:digraph`. Node and edge mutations call `ExecutiveMemory.record_event/4` through a helper that rescues exceptions and returns `:ok`; this does not persist the graph itself or prove that all graph mutations were durably recorded. A graph process restart can lose nodes and edges while separate mutation or executive records survive.

**Closure evidence:** establish a durable canonical graph representation or deterministic reconstruction from an authoritative append-only source; verify graph state roots after restart and compare node/edge counts and contents.

#### RL-148 — SnapshotManager snapshot hashes do not attest to complete state

**Status: Source-confirmed.** Root `Tiannara.World.SnapshotManager.take_snapshot/0` records counts and a hash derived from snapshot ID plus entity count, not a canonical serialization of the world state. `create_snapshot/2` captures entities from at most 10,000 queried IDs but does not capture a complete relationship set or bind the snapshot to a mutation-log offset/state root. Snapshot lists are kept in the GenServer's memory and truncated to 24 entries. Restore adds entity records into the graph but does not demonstrate a complete atomic restoration of graph relationships, mutation history, counters and runtime state.

**Closure evidence:** versioned full-state manifests, complete entity/relationship capture, mutation-log position, canonical state hash, durable artifact storage, integrity validation and isolated round-trip restoration.

#### RL-149 — VersionManager versions, branches and tags are volatile and can falsely imply rollback success

**Status: Source-confirmed.** `Tiannara.World.VersionManager.init/1` explicitly initializes versions, branches and tags in memory. Version creation writes a decision best-effort but does not durably persist the version record. During rollback, `UnifiedRealityGraph.add_entity/1` failures are rescued/caught and ignored; the handler can still append an in-memory rollback record and return `{:ok, version_number}`. Branch merge also uses a shallow `Map.merge/2` of snapshots without demonstrated conflict detection or complete graph reconciliation.

**Closure evidence:** durable version/branch records, content-addressed snapshots, explicit merge conflicts, result-bearing graph restoration, and postcondition checks proving restored state equals the requested version.

#### RL-150 — TemporalWorldEngine does not reconstruct historical state

**Status: Source-confirmed.** `historical_entity_state/2` requests mutation history with `since: DateTime.utc_now()`, which excludes earlier mutations under the documented time filter. The helper `replay_mutations_for_entity/3` returns only the requested entity ID, timestamp and a `:historical` status; it does not apply the retrieved mutations. `time_travel_query/2` filters current query results by creation time rather than reconstructing entity state at the target timestamp. Counterfactual application marks a generic result as simulated instead of applying the hypothetical mutations, and state comparison returns a fixed empty diff.

**Closure evidence:** select mutations up to the requested timestamp from a durable snapshot/log boundary; apply real mutation semantics in an isolated state; compare the reconstructed state root against known checkpoints; test update/delete/relation changes, boundary timestamps and invalid history.

#### RL-151 — ReplayEngine explicitly refuses replay because its executable mutation source is unconfigured

**Status: Source-confirmed.** Root `Tiannara.World.ReplayEngine.handle_call({:replay, ...})` returns `{:error, :replay_source_unavailable}` and logs that no executable mutation source is configured. The capability metadata advertises deterministic replay and state recovery, but the operational path refuses to perform them.

**Closure evidence:** connect the replay engine to the canonical mutation source, execute mutations against an isolated world model, verify event ordering and final state root, and ensure mismatched/corrupt artifacts fail closed.

#### RL-152 — Executive EventStore durability and integrity are overstated

**Status: Source-confirmed.** `Tiannara.Executive.EventStore` defaults to `/tmp/tiannara_executive_events.log`. Its append handler frames the event and calls `IO.binwrite/2` but ignores the write result, increments the count and replies `:ok`. It does not explicitly sync the file before acknowledgement. The reader silently stops parsing when it encounters a truncated or malformed trailing frame, with no corruption status returned to the caller. This store is for executive events and is not shown to be the authoritative store for every world mutation.

**Closure evidence:** use an appropriate durable path and defined sync policy; check write/sync results before acknowledgement; detect and report corrupt/truncated frames; retain sequence and integrity metadata; prove restart recovery and establish which world-event writers are required to use this store.

#### Checkpoint 18.14 disposition

- The root mutation engine provides useful authorization and DETS-backed mutation records, but its records and the graph effects are not one atomic commit.
- UnifiedRealityGraph is in-memory; SnapshotManager does not capture or hash a complete canonical state; VersionManager is in-memory and can report rollback success after swallowed graph errors.
- TemporalWorldEngine is not a functioning historical reconstruction engine at this baseline, and ReplayEngine explicitly refuses replay because its source is unavailable.
- Executive EventStore writes framed events to a temporary-path file by default, ignores append write results, and does not report trailing-frame corruption.
- The runtime world-process implementation is not present at the inspected `tiannara_runtime/lib/tiannara_runtime/multi_world/world_process.ex` path at this exact SHA. A similarly named current/default-branch file is not evidence for the frozen baseline. The bridge between runtime world execution and root graph/mutation storage remains unresolved.

**Checkpoint 18.14 disposition:** RL-146–RL-152 remain open source-level findings. No runtime behavior was executed in this pass. The next target is the exact-SHA boot/ownership graph and all world-state/event writers, to establish which process actually owns the live simulation state and whether any production path bridges it to the root durable mutation records.


### Checkpoint 18.15 — exact-baseline runtime ownership and event-writer bridge

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Method:** Exact-SHA inspection of runtime simulation loop, per-world supervisor, state manager, memory store, event processor, ecology world/universe servers, and root application/world mutation interfaces. Repository search results from later default-branch revisions were not treated as frozen-baseline proof. No application files modified; no runtime tests executed.

#### RL-153 — Simulation ticks do not commit canonical world mutations

**Status: Source-confirmed at the inspected runtime path.** `tiannara_runtime/lib/tiannara_runtime/world_simulation_loop.ex` executes CAL/CIS steps and updates `TiannaraRuntime.WorldStateManager`, but `update_world_state/3` and `publish_events/3` only emit debug log messages. Its `store_memory_snapshot/3` sends CAL/CIS result maps and a unique integer timestamp to `WorldMemoryStore`; it does not capture a complete world state or mutation-log position. The inspected loop does not call `Tiannara.World.WorldMutationEngine`, `Tiannara.World.UnifiedWorldModel`, or `Tiannara.Graph.UnifiedRealityGraph`.

**Impact:** A successful tick is not evidence that canonical entity/relationship state was changed, durably recorded, or can be reconstructed. Runtime CAL/CIS state and root-world mutations can diverge without a shared commit boundary.

**Closure evidence:** define the canonical state owner and a single mutation/effect contract; route actual state transitions through it; bind each committed transition to ordered event ID, world ID, parent/version, mutation-log offset and resulting state root; inject failures between state update, event append and acknowledgement; verify restart recovery and replay.

#### RL-154 — World event processor is not the simulation loop's event writer, and its timeline is volatile

**Status: Source-confirmed at the inspected paths.** `TiannaraRuntime.WorldEventProcessor` exposes casts for CAL, CIS, state, snapshot and world events and attempts NATS publication. The inspected `WorldSimulationLoop` calls none of those APIs; its event publisher is logging only. Separately, `TiannaraRuntime.WorldMemoryStore` keeps snapshots in GenServer state, starts with an empty list on initialization, and trims history to 10,000 entries. The inspected store has no durable backing or restart-recovery path.

**Impact:** The existence of NATS publishing functions and an append-named memory API does not establish that actual world mutations enter an authoritative, durable, ordered archive. A runtime process/supervisor restart loses the in-memory snapshot timeline.

**Closure evidence:** demonstrate real production call sites from each mutation writer to a durable append-only archive; check publication/append results rather than using fire-and-forget casts as commit evidence; record sequence numbers, hashes and schema versions; test process/node restart, duplicate delivery, gaps, corrupt frames and replay against known state roots.

#### RL-155 — Runtime state ownership is split across incompatible world representations

**Status: Source-confirmed architecture gap in inspected components.** The per-world runtime supervisor owns a `WorldStateManager` containing CAL state, CIS state, metrics and configuration, plus a separate volatile `WorldMemoryStore`. The ecology path (`Tiannara.WorldServer` and `Tiannara.UniverseServer`) separately holds civilization maps, ecological fields, entropy, drift and tick counters; its visible dynamics include identity resource evolution, random entropy and a fixed drift vector. The root `Tiannara.World.UnifiedWorldModel` and DETS-backed `WorldMutationEngine` form another state/mutation path. The runtime and root have separate application entry modules (`TiannaraRuntime.Application` and `Tiannara.Application`); the inspected runtime tick has no bridge to the root mutation APIs.

**Impact:** No single inspected owner contains the complete live world (agents/civilizations, environment, simulation clock, CAL/CIS decisions and canonical entity relationships) together with a durable mutation history. Snapshotting any one of these representations alone cannot prove complete-world recovery or archaeological reconstruction.

**Closure evidence:** publish a responsibility/ownership matrix for every state field and writer; choose one canonical world identity and state schema; define adapters for subsystem-specific projections without making them competing authorities; prove that all live writers produce ordered canonical events and that derived views can be rebuilt from the archive.

#### RL-156 — Archaeological history cannot yet be sourced from the live runtime event path

**Status: Source-confirmed consequence of RL-144–RL-155 at the inspected paths.** The archaeology functions previously inspected fail closed when no archaeology simulation is available (RL-144). The runtime tick does not commit canonical mutations (RL-153), the event processor is not called by that loop (RL-154), and its per-world snapshot history is volatile. The root mutation log, in-memory graph and executive event store are not shown to be a complete, ordered archive of runtime-world evolution (RL-146–RL-152).

**Impact:** There is no demonstrated, end-to-end source artifact from which a later world could independently excavate an extinct world and reproduce its agents, events, discoveries, institutions, technologies and uncertainty/provenance. Do not replace the current fail-closed archaeology response with simulated success scores.

**Closure evidence:** first establish a durable canonical world-history archive and export manifest; then demonstrate extinction finalization, later-world discovery without access to the original process, independent reconstruction in isolation, artifact/stratigraphic provenance, contradiction handling and state-root/replay verification.

#### Checkpoint 18.15 disposition

- The missing `world_process.ex` path remains unresolved at the frozen SHA; later default-branch search hits do not prove that implementation exists at the audited commit.
- The most concrete runtime state owner found in the inspected Phase 5A path is `WorldStateManager` for CAL/CIS/metrics, not a complete world model. The ecology path owns a different, separately volatile representation.
- The inspected simulation loop's state-update and event-publish helpers are logging placeholders; its snapshot records CAL/CIS outputs rather than full canonical world state.
- Root `WorldMutationEngine` is a useful governed, DETS-backed mutation record source, but it is not wired into the inspected runtime tick and is not atomic with the root graph effect (RL-146–RL-147).
- A canonical archaeological archive cannot be selected by choosing one existing snapshot API: runtime snapshots are volatile/incomplete, root snapshots do not attest to full state (RL-148), and temporal/replay engines do not currently reconstruct history (RL-150–RL-151).
- No runtime tests were executed in this checkpoint. These are source-level findings, not claims about behavior beyond the inspected paths.

**Checkpoint 18.15 disposition:** RL-153–RL-156 remain open. Next step: complete the exact-baseline writer/caller inventory and application-startup reachability map, then define a single canonical world-history archive contract before any implementation or remediation is authorized.


### Checkpoint 18.16 — boot reachability and deployable application boundaries

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Method:** Exact-SHA inspection of both Mix project definitions, the runtime StartupSupervisor/RootSupervisor and authority-layer child lists, and the root Tiannara application child list. No runtime tests executed; no source files modified.

#### RL-157 — Root Tiannara and Tiannara Runtime are separate OTP application roots without a declared application dependency bridge

**Status: Source-confirmed project configuration.** Root `mix.exs` declares application `:tiannara`, starts `Tiannara.Application`, and assembles a `tiannara` release. `tiannara_runtime/mix.exs` separately declares application `:tiannara_runtime`, starts `TiannaraRuntime.Application`, and has its own dependency list and runtime release configuration. The runtime project's listed local path dependency is `../forward_provenance`, not the root Tiannara Mix application. The inspected configurations do not declare the root application as a dependency of the runtime application or establish that both application supervisors always run together in the same node.

**Impact:** Cross-project references in source or matching module names do not prove shared-process reachability, common boot order, or that the root mutation/graph services exist when runtime code executes. A deployment may boot one application without the other unless an external release/orchestration contract explicitly starts and verifies both.

**Closure evidence:** document and test the supported release topology; assert required applications and service registrations at boot; verify all required root mutation, memory and graph services are live before runtime worlds are admitted; exercise the actual production release entrypoint and restart/failure paths. If they are intended to be separate services, specify and test a versioned transport contract instead of relying on in-process calls.

#### RL-158 — Per-world Phase 5A simulation loop is not established as the canonical live-world driver

**Status: Source-confirmed boot-path limitation.** The runtime application's top-level child list starts `TiannaraRuntime.MultiWorld.WorldSupervisor`, which is a manager for dynamically spawned worlds; the per-world supervisor that contains `WorldSimulationLoop` is created by the world-spawn path, not by merely starting the manager. The separate runtime RootSupervisor's Ecology layer starts `Tiannara.UniverseSupervisor`, and the ecology universe seeds its own `Tiannara.WorldServer` instances and civilizations. The inspected runtime startup path therefore contains two different world lifecycles: dynamically spawned Phase 5A worlds and the ecology universe's own worlds. No inspected boot code makes the latter's live state the input/output of the Phase 5A loop or the root `UnifiedWorldModel`.

**Impact:** It is not yet established which path is the intended authoritative simulation for autonomous world evolution, whether the Phase 5A loop is active for any production world by default, or whether ecological worlds receive the same safety, event, persistence and archaeology guarantees.

**Closure evidence:** map every boot child and dynamic spawn call to an actual running world process; instrument world IDs and owner PIDs across lifecycle paths; demonstrate one canonical tick through agent/civilization state transition, governed mutation, durable event append and replay; explicitly classify any legacy or experimental world path as non-authoritative or migrate it behind the canonical contract.

#### Checkpoint 18.16 disposition

- The exact baseline contains two Mix application definitions and two application entry modules. The inspected config alone does not prove both applications run in one production release or node.
- Runtime StartupSupervisor/RootSupervisor establishes a boot hierarchy for runtime layers, but the per-world Phase 5A loop is only inside dynamically spawned per-world supervisors; starting the world manager does not itself prove a Phase 5A world exists.
- The Ecology layer starts a separate universe/world path, making live-world ownership and the canonical simulation driver unresolved.
- RL-157–RL-158 remain open. No tests or production release boot were executed in this checkpoint.

**Checkpoint 18.16 disposition:** Continue with a source-level caller inventory for world spawning, agent/civilization mutation, event publication, and startup registration at the frozen SHA. Do not begin source remediation until the intended canonical runtime path and cross-application deployment contract are explicit.


### Checkpoint 18.17 — exact-baseline world-writer and lifecycle caller inventory

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Method:** Exact-SHA source inspection of `MultiWorld.WorldSupervisor`, per-world `WorldSupervisor`, `WorldSimulationLoop`, `WorldStateManager`, `WorldEventProcessor`, `WorldMemoryStore`, `DeterministicReplay`, `WorldForkEngine`, `MultiWorld.Events.EventStore`, `StartupSupervisor`, `UniverseSupervisor`, `UniverseServer`, `WorldServer`, and root `WorldMutationEngine`. No tests executed; no application source files modified.

#### RL-159 — Multi-world spawn rejection does not fail closed

**Status: Source-confirmed.** In `tiannara_runtime/lib/tiannara_runtime/multi_world/world_supervisor.ex`, `spawn_world/1` matches the quota result and logs an error when it receives `{:error, reason}`, but then continues to memory allocation, recording initialization and child creation. The memory-allocation case similarly logs rejection, requests quota termination and returns an error tuple from the case expression, but its value is ignored by the enclosing function, which continues. Only the later child-start result controls the final return.

**Impact:** Quota or memory-allocation rejection is not a reliable gate on world creation. A caller may receive a successful spawn result despite a preceding safeguard rejection; the attempted quota cleanup is asynchronous and does not itself prove that subsequent work stopped.

**Closure evidence:** restructure spawn as a fail-fast `with`/explicit state machine; prove no recording or child start occurs after either rejection; test quota and allocation failures independently and together; verify reservation rollback and absence of leaked quota/memory accounting after every failure.

#### RL-160 — CAL/CIS state changes are asynchronous and are not committed with a tick record

**Status: Source-confirmed.** `WorldSimulationLoop.execute_cal_step/1` and `execute_cis_step/2` issue `WorldStateManager.update_cal_state/2`, `update_cis_state/2` and `update_metrics/2` casts, then continue. The manager merges those maps in separate GenServer callbacks. The tick does not await acknowledgements or capture an atomic before/after world state. Its snapshot records the returned CAL/CIS result maps with an Erlang unique integer timestamp, rather than the confirmed post-update manager state.

**Impact:** A snapshot or downstream observer can run without proof that all state casts were applied; partial tick effects are possible if a process fails between updates. The timestamp is not a durable sequence number or mutation-log offset.

**Closure evidence:** make a tick a bounded transaction/command with explicit world ID and sequence; return acknowledgements for state effects; append a durable event with before/after state roots and effect outcomes; inject process failures between effects and prove deterministic recovery.

#### RL-161 — Event processor and deterministic recorder are not connected to the real Phase 5A tick

**Status: Source-confirmed at inspected caller.** `WorldSimulationLoop.publish_events/3` only logs. It does not invoke any `WorldEventProcessor.publish_*/2` or `publish_world_event/3` API, nor `MultiWorld.DeterministicReplay.record_event/4`. The per-world supervisor starts an event processor, but starting that child does not connect it to the loop. The tick does append CAL/CIS result snapshots to `WorldMemoryStore`, but this store is separate from the event processor and replay recorder.

**Impact:** The advertised NATS event stream and deterministic replay APIs are not evidence that real CAL/CIS state transitions are captured. A world may tick without an event that can reproduce the transition.

**Closure evidence:** test production call-chain reachability from each state-changing operation to the canonical event append; require event acknowledgement before reporting a committed tick; verify event ordering and payload completeness against observed state transitions.

#### RL-162 — Phase 5E EventStore is volatile, with collision-prone event identity

**Status: Source-confirmed.** `TiannaraRuntime.MultiWorld.Events.EventStore` creates a named public ETS ordered set during GenServer initialization and writes records keyed by `{timestamp, event_id, event}`. Its ID is formed from world ID and millisecond timestamp. The store has no durable backing or restart recovery in the inspected module; reinitializing the owning process recreates the table. Two events for the same world within one millisecond can produce the same ETS key and overwrite one another. Its documentation describes lifecycle/security telemetry (spawn, risk, regulation, freeze, termination), not a complete stream of all world mutations.

**Impact:** It cannot serve as the canonical archaeological record; events may disappear on restart or collide, and the covered event domain is not complete-world history.

**Closure evidence:** use durable append-only storage with monotonic per-world sequence and globally unique event IDs; check write/fsync outcomes; add checksummed frames/schema versions, restart recovery and corruption tests; explicitly distinguish operational telemetry from canonical mutation history.

#### RL-163 — World fork registration and child-process creation are not one checked lifecycle operation

**Status: Source-confirmed.** In `WorldForkEngine.create_child_world/2`, the child world is registered through `WorldRegistry.create_world/2`; after successful registration, `spawn_world_supervisor/1` is called but its return value is ignored, then `WorldRegistry.add_child/2` is called and the fork returns `{:ok, child_world_id}`. Thus a failed supervisor start can leave a registered child and parent lineage entry while the caller is told the fork succeeded. The fork event is published later and is not a durable commit receipt.

**Impact:** Registry lineage may contain a child with no running execution process; recovery and archaeological lineage can disagree with the actual live-world population.

**Closure evidence:** use a compensating transaction or durable lifecycle state machine; propagate child-start failure; roll back or mark failed registrations; reconcile registry, supervisor children and event archive after restart; test every partial-failure point.

#### RL-164 — Ecology-world and Phase 5A lifecycle events do not share a demonstrated canonical writer

**Status: Source-confirmed integration gap.** `UniverseServer` seeds `WorldServer` processes and civilizations; `WorldServer` mutates its own in-memory civilization map and on ticks evolves entropy/drift and sends casts to civilization processes. The inspected `WorldServer` tick and `spawn_civ` handlers do not call the root `WorldMutationEngine`, `UnifiedWorldModel`, `UnifiedRealityGraph`, Phase 5A `WorldEventProcessor`, or Phase 5E `EventStore`. In contrast, root-world callers such as `UnifiedWorldModel` and `OntologyManager` do invoke `WorldMutationEngine` for their own entity/ontology operations. These are different write domains, not a single canonical history.

**Impact:** Root semantic entities and ecology-world/civilization evolution are not shown to form one complete replayable timeline. A later-world archaeology process cannot reliably infer ecology-world state from the root mutation log alone.

**Closure evidence:** define canonical IDs and typed event schemas for world/civilization/agent state; enumerate every state writer and require it to emit the same durable event contract; prove that root semantic projections and ecology projections can be rebuilt independently from the canonical log without hidden in-memory state.

#### Checkpoint 18.17 disposition

- Spawn safeguards currently fail open at the control-flow level (RL-159).
- Tick effects are asynchronous and lack a single acknowledged commit boundary (RL-160).
- The Phase 5A loop does not call the event processor or deterministic replay recorder (RL-161).
- Phase 5E EventStore is an in-memory operational event table, not a durable complete-world archive (RL-162).
- World-fork registration can outlive a failed child start while returning success (RL-163).
- Ecology-world/civilization writes do not share a demonstrated canonical writer with the root mutation ledger (RL-164).
- These are source-level conclusions from the listed exact-baseline modules. No runtime test, integration test, or production boot was performed.

**Checkpoint 18.17 disposition:** RL-159–RL-164 remain open. Next checkpoint should inventory all production callers of `WorldMutationEngine`, `WorldMemoryStore`, `WorldEventProcessor`, `DeterministicReplay`, and Phase 5E `EventStore`, separating real mutation writers from test/example/telemetry callers. Only then define the canonical event contract and remediation order.
