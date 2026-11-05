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


### Checkpoint 18.18 — exact-baseline caller reachability and event-writer classification

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Method:** Repeated repository code-search plus exact-SHA fetches of the five target modules and their identified caller paths. Search results on the current default branch were treated as discovery only; conclusions below are grounded in source fetched at the frozen SHA. No tests executed; no application source files modified.

#### Caller inventory

| Component | Caller(s) observed at the frozen baseline | Classification |
|---|---|---|
| Root `Tiannara.World.WorldMutationEngine` | `UnifiedWorldModel`, `OntologyManager`, `ConflictResolver`, `RealityCoordinator`, `WorldIntegrationCoordinator` | Actual root semantic-entity, ontology, graph-integration and conflict-resolution mutation paths. No call from the inspected Phase 5A tick or ecology `WorldServer` path. |
| `TiannaraRuntime.WorldMemoryStore` | `WorldSimulationLoop.store_memory_snapshot/3` | Actual Phase 5A tick caller, but appends only CAL/CIS result maps, by asynchronous cast, into volatile per-process state. |
| `TiannaraRuntime.WorldEventProcessor` | No production caller found for its five `publish_*` APIs in the repository search; per-world supervisor starts the process | API/process is present, but the inspected simulation loop's `publish_events/3` only logs. No verified production call from the tick to these event APIs. Search coverage is not proof that no indirect/reflection-based caller exists; none was found in the inspected call paths. |
| `TiannaraRuntime.MultiWorld.DeterministicReplay` | `MultiWorld.WorldSupervisor` calls `start_recording/2` on spawn and `stop_recording/1` during termination; no production `record_event/4` call found | Lifecycle opens/closes recording sessions, but the inspected real tick does not feed events to the recorder. Examples/documentation contain event-recording calls, not evidence of live production capture. |
| `TiannaraRuntime.MultiWorld.Events.EventStore` | `TiannaraRuntime.Cortex.ImmuneCortex.assess_risk` calls `record_event/2`; remaining matches are its own documentation and status/usage documentation | Operational immune-risk telemetry caller, not a general world-mutation writer. The store's own source uses in-memory ETS and millisecond world-scoped IDs as described in RL-162. |

#### RL-165 — DeterministicReplay recording sessions have no verified live event producer

**Status: Source-confirmed for inspected production paths.** The multi-world spawn path starts a recording session and termination attempts to stop it. However, repository code search found no production call to `TiannaraRuntime.MultiWorld.DeterministicReplay.record_event/4`; the matches were documentation/examples. The actual Phase 5A tick does not call it, and its `publish_events/3` helper only logs. The recorder's internal GenServer state is not itself a durable world-history archive.

**Impact:** Starting a recording session is not evidence that world evolution was recorded. Replay/fidelity claims cannot be based on the lifecycle calls alone; a session may contain no authoritative transition stream.

**Closure evidence:** identify the real canonical state-transition writer; route every committed transition through the recorder/archive with acknowledged sequence and state-root linkage; test a nontrivial live world, stop/restart, export/import, and independently replay to the same state root.

#### RL-166 — WorldEventProcessor is started but no live tick-to-publisher call chain was found

**Status: Source-confirmed for inspected paths.** `WorldEventProcessor` defines asynchronous cast APIs for CAL, CIS, state, snapshot and generic world events. The per-world supervisor starts the process, but the Phase 5A loop's event helper only emits a debug log and does not invoke those APIs. Repository search found no call sites for the five publishing APIs at the audited source baseline.

**Impact:** Process existence and NATS-publishing code do not prove that real world transitions enter the event stream. Even if another subsystem publishes telemetry, the inspected loop does not establish complete or acknowledged tick-event delivery.

**Closure evidence:** add explicit production wiring from each committed transition to a defined event API; make event delivery outcome observable; test event payload completeness, ordering, broker-unavailable behavior, retries and duplicate handling. Keep event transport separate from the durable canonical archive.

#### RL-167 — Phase 5E EventStore is currently used as immune-risk telemetry, not as the world-history writer

**Status: Source-confirmed caller classification.** At the frozen source baseline, the production caller located for `TiannaraRuntime.MultiWorld.Events.EventStore.record_event/2` is `Cortex.ImmuneCortex`, which records `:world_risk_assessed` and associated assessment metadata. Other search hits are module documentation or usage/status documents. The module writes directly to an ETS table and increments a counter asynchronously; it does not demonstrate a unified stream of world-state transitions.

**Impact:** Its presence can support a narrow risk-assessment telemetry use case, but cannot substantiate a complete history of agent/civilization changes, discoveries, mutations, or extinct-world state. This reinforces RL-162; it does not close or supersede it.

**Closure evidence:** retain a separately scoped telemetry stream if useful, but define a canonical durable event writer with explicit event taxonomy and require every world-state writer to commit to it. Prove coverage through a writer-to-event matrix and replay/restore tests.

#### Checkpoint 18.18 disposition

- The root mutation engine has real callers, but the located callers are root semantic/ontology/integration operations; the Phase 5A tick and ecology-world writers remain outside that path in the inspected baseline (RL-164, RL-165–RL-167).
- The Phase 5A tick calls `WorldMemoryStore` for result-map snapshots, not `WorldEventProcessor` or `DeterministicReplay.record_event/4`.
- The deterministic recorder is opened/closed by lifecycle code, but no live production event producer was found; recording-session creation alone is not replay evidence.
- Phase 5E EventStore's located runtime use is immune-risk telemetry, not a canonical mutation archive.
- Search-based absence claims are limited to repository search and inspected call paths; no claim is made that every possible indirect caller has been exhaustively ruled out.
- RL-159–RL-167 remain open. No runtime tests, integration tests, or production boot were performed.

**Checkpoint 18.18 disposition:** The caller inventory does not identify an existing component that can be promoted as the canonical complete-world history without design work. Next step: specify the canonical event/commit contract and ownership matrix first, then map each identified writer to it before authorizing remediation.


### Checkpoint 18.19 — canonical world-event contract and ownership matrix

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Purpose:** Specify the minimum canonical event/commit contract and test it against the existing writers before any source remediation.  
**Method:** Exact-SHA inspection of `WorldMutationEngine`, `UnifiedWorldModel`, root `Tiannara.Executive.EventStore`, root `SnapshotManager`, Phase 5A `WorldSimulationLoop`, ecology `WorldServer`, Phase 16.1 `DiscoveryArchaeology`, `DeterministicReplay`, and Phase 5E `EventStore`. No tests executed; no application source files modified.

#### Contract decision (audit proposal, not yet implemented or ratified)

The audit does **not** designate any existing event store as the canonical world-history source. The minimum contract for a future canonical writer is:

1. **Stable event identity:** globally unique `event_id`; separate `world_id`, `universe_id`, `civilization_id`, `agent_id` and artifact/discovery identifiers when applicable. Identity fields must not be inferred from wall-clock milliseconds.
2. **Explicit ordering:** monotonic per-world `sequence` allocated at the commit boundary; wall-clock time and monotonic runtime time are supplementary metadata, not ordering authorities.
3. **Typed transition envelope:** `schema_version`, `event_type`, `aggregate_type`, `aggregate_id`, `operation_id`, `causation_id`, `correlation_id`, actor/subsystem, authorization/provenance reference, payload, previous-state version/root and resulting-state version/root.
4. **Commit semantics:** a state transition is considered committed only when its canonical event and state effect have a recoverable relationship. The implementation must define atomic transaction or an explicit write-ahead/outbox/reconciliation protocol; it must never report success while silently losing either side.
5. **Durability and recovery:** acknowledged writes survive process restart; startup detects truncated/corrupt frames, validates checksums/sequence continuity, and reports recovery/degradation rather than silently treating a partial log as complete.
6. **Idempotency and concurrency:** stable operation/idempotency key; duplicate retry cannot apply the same mutation twice; concurrent writers cannot reuse sequence numbers or produce ambiguous order.
7. **Evidence integrity:** event payloads are canonicalized before hashing; state roots are computed over the relevant complete canonical state, not snapshot ID plus entity count. Hashes establish integrity only if the covered data and algorithm are explicit.
8. **Replay contract:** replay consumes the committed canonical event sequence from a declared checkpoint and verifies resulting state roots. A seed, lifecycle session, telemetry record, snapshot of CAL/CIS outputs, or replay-shaped API alone is not replay evidence.
9. **Separation of concerns:** canonical world-state events, operational/security telemetry, transport notifications, derived research artifacts and snapshots remain distinct streams or clearly typed projections. Telemetry must not be mistaken for state-transition history.
10. **Ownership and completeness:** every writer of world, ecology, civilization, agent, research-discovery and archaeology state is listed in a writer registry and must either commit canonical events or explicitly declare itself non-authoritative/derived.

#### Writer-ownership matrix at the frozen baseline

| Writer/subsystem | Existing write behavior | Contract gap / required disposition |
|---|---|---|
| `WorldMutationEngine` | Stores mutation records in DETS with mutation ID, type/spec/context, authorization references, timestamp, status and rollback data. | Strongest identified root mutation ledger, but not sufficient by itself: record insertion precedes verified audit receipt; the caller can receive an audit error while the mutation record remains. It does not prove atomicity with the actual graph/entity effect. |
| `UnifiedWorldModel` + `UnifiedRealityGraph` | Calls mutation engine, then applies entity changes to an in-memory graph and updates process-local counters/events. | State effect and mutation record are separate writes; graph failure after ledger insertion can leave a record without the corresponding entity. Must be governed by commit/recovery semantics and full-state version/root. |
| Root `Tiannara.Executive.EventStore` | Framed binary log with synchronous GenServer call; defaults to `/tmp/tiannara_executive_events.log`; `IO.binwrite/2` result is ignored and count advances without explicit sync. | A candidate for executive event history only after durability/error handling and scope/ownership are proved. It is not shown to be the canonical source for all world mutations. |
| Phase 5A `WorldSimulationLoop` + `WorldStateManager` | Tick uses CAL/CIS results and asynchronous state casts; event helper only logs; memory store gets result-map snapshots. | No demonstrated canonical world-state commit or event publication at tick boundary. Must not report simulation progress as committed historical state until a state/effect/event contract exists. |
| Ecology `WorldServer` / `CivilizationServer` | Independent in-memory ecology/civilization process state; world tick evolves entropy/drift and sends casts to civilization processes. | Separate writer path not connected in inspected source to root mutation ledger, canonical graph or Phase 5A recorder. Must be migrated or explicitly bridged with versioned events. |
| Phase 5A `WorldMemoryStore` | In-memory list of CAL/CIS result snapshots. | Derived operational snapshot cache, not canonical event log or durable state checkpoint. |
| Phase 5A `WorldEventProcessor` | Asynchronous NATS publishing API; no tick-to-publisher call chain found. | Transport projection only; delivery acknowledgement/retry and canonical persistence cannot be delegated implicitly to this process. |
| Phase 5A `DeterministicReplay` | In-memory recording sessions/events; session started/stopped by lifecycle; no live `record_event/4` producer found in inspected paths. | Replay adapter, not authoritative persistence. Must consume committed canonical events and persist/export validated recording artifacts. |
| Phase 5E `MultiWorld.Events.EventStore` | ETS telemetry; located production caller is immune-risk assessment. | Keep as operational telemetry if needed; not the canonical mutation log. |
| Phase 16.1 `DiscoveryArchaeology` | Pure function returns a hash-derived archaeology ID and metadata map. | Metadata construction does not persist evidence, link source artifacts, verify a discovery lineage, or create a replayable archaeological record. Must emit a derived artifact referencing immutable source event/artifact IDs and provenance. |
| Snapshot/restore | Root snapshot manager captures entity snapshots but uses a hash based on snapshot ID plus entity count; runtime freeze/snapshot paths are volatile or partial (RL-136–RL-148). | Snapshot must name canonical sequence/checkpoint and hash complete serialized state; restore must verify root and reconcile graph, relationships, counters and mutation offset. |

#### RL-168 — Root mutation records and semantic state effects do not share a demonstrated atomic commit

**Status: Source-confirmed.** `UnifiedWorldModel.create_entity/1` calls `WorldMutationEngine.mutate/3` before `UnifiedRealityGraph.add_entity/1`. The mutation engine inserts its DETS record, then calls the audit verification path; if audit receipt verification fails, it returns an error that includes `mutation_recorded: true`. A subsequent graph failure can also leave the mutation record present while the entity operation returns an error.

**Impact:** Callers can observe an unsuccessful operation even though a mutation record exists, and a recorded mutation does not alone prove the intended state effect committed. This makes naïve replay of mutation records unsafe without outcome/status reconciliation.

**Closure evidence:** specify transaction/WAL/outbox semantics, distinguish proposed/authorized/committed/failed/compensated states, and test failures between each persistence/effect/audit boundary plus crash/restart recovery.

#### RL-169 — Root Executive EventStore is not proven to be a durable canonical world log

**Status: Source-confirmed.** The store defaults to a file under `/tmp`, ignores the return value of `IO.binwrite/2`, increments its count and returns `:ok` without an explicit sync/durability acknowledgement, and silently returns parsed events from a reader that stops at malformed/truncated frames (previously recorded as RL-152). The audited source does not establish that all world-state writers append to it.

**Impact:** A successful append response is not sufficient evidence that a complete event is durably recoverable, and its current scope does not make it a universal world-history source.

**Closure evidence:** choose an explicit durable storage location and durability level, check write/sync errors, surface corrupt-tail recovery state, verify event counts against parsed frames, and prove writer coverage before assigning canonical authority.

#### RL-170 — Discovery archaeology metadata is not a persisted, provenance-linked discovery record

**Status: Source-confirmed for the inspected Phase 16.1 module.** `DiscoveryArchaeology.record/2` canonicalizes a supplied context, hashes its JSON to derive an archaeology ID, and returns a map. The inspected function does not persist that map or validate links to immutable observation, hypothesis, experiment, theory or source-world event artifacts.

**Impact:** A deterministic identifier and metadata shape do not prove that the discovery can be independently traced or reconstructed from the source world's durable evidence.

**Closure evidence:** persist a versioned archaeology artifact with immutable source artifact/event IDs, hashes, method/version, uncertainty and derivation lineage; validate source availability and replay/reconstruction evidence independently.

#### Checkpoint 18.19 disposition

- The proposed contract is a design gate for later remediation, not a claim that the contract already exists or has been accepted as architecture.
- The existing root mutation ledger, root Executive EventStore, Phase 5A memory/event/replay components, Phase 5E telemetry store and archaeology metadata function have different scopes and failure semantics. None is currently demonstrated as the complete canonical history across the inspected world writers.
- RL-168–RL-170 are added; RL-159–RL-167 and all prior findings remain open unless separately closed with evidence.
- No tests, integration runs, runtime boot or application source edits were performed.

**Checkpoint 18.19 disposition:** Do not begin broad remediation yet. Next checkpoint should validate this proposed contract against the authoritative constitutional/governance constraints and startup/runtime ownership, then convert it into a versioned ADR and a per-writer conformance/test matrix. Only after approval should implementation be planned.


### Checkpoint 18.20 — constitutional authority, CEL executive readiness, and ToolForge execution boundary

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Method:** Exact-SHA reads of `lib/tiannara/application.ex`, CEL Kernel, BootSequencer, ServiceRegistry, Council, ToolForge ToolBuilder/Engine/Supervisor and CEL design/governance material. Current-default-branch search results were used only to discover paths; conclusions below use exact-baseline source. This is a read-only source audit; no test execution or application-source edits were performed.

#### Constitutional authority and canonical ownership

The source distinguishes governance authority from technical execution ownership:

- `Tiannara.Council` owns the runtime authorization API and evaluates declarative policy plus the constitutional RuleEngine. Hard-invariant violations can withdraw an apparent policy approval.
- CEL Kernel calls Council authorization for service restart and kernel halt. The halt path requires a full permitted authorization; restart also accepts a conditional grant when its predicates are satisfied.
- The reviewed Council/CEL paths establish an authorization authority, not a canonical world-state writer. They do not designate the root mutation engine, executive event store, Phase 5A world state, or ecology state as the universal world-history owner.
- The CEL design transcript `cel.md` expressly warns that it is a design transcript, not implementation evidence, and that many described capabilities are not implemented. Its proposed architecture therefore cannot be treated as ratification of the canonical event contract from Checkpoint 18.19.

**Disposition:** Constitutional approval and event/state ownership must remain separate concepts. The proposed canonical world-event contract remains an audit proposal pending an explicit, versioned constitutional/architectural decision and a named technical owner. No current component is promoted to canonical authority by this checkpoint.

#### RL-171 — Production application startup does not synchronously gate readiness on CEL boot

**Status: Source-confirmed.** `Tiannara.Application.start/2` starts the root supervision tree, then in production invokes the CEL boot function through `Task.start/1`. The root application returns `{:ok, pid}` without waiting for the CEL boot report. CEL boot errors are logged; a returned report with `:degraded` or `:failed` is logged and does not cause the root application start to fail. The synchronous boot branch is restricted to test mode.

**Impact:** A process supervisor can report application startup success while the executive kernel is still booting or has failed/degraded. Consumers that begin work before checking CEL runtime state can operate without the executive services that are supposed to coordinate them. Logging a failed boot is not a readiness gate.

**Closure evidence:** define root readiness semantics and an explicit startup barrier/health contract; test delayed boot, critical-service failure, degraded noncritical service, CEL process crash, and dependent API/worker admission. Demonstrate that the deployment/readiness signal cannot become healthy before required CEL services are ready.

#### RL-172 — CEL ServiceRegistry mutation APIs do not enforce Council authorization or durable governance evidence

**Status: Source-confirmed for the reviewed API path.** `ServiceRegistry.register/1`, `deprecate/1`, and `replace/2` are public GenServer-call APIs. Their handlers mutate the in-memory registry directly; the inspected handlers do not call Council authorization, validate a signed/ratified registry change, or persist an audit-backed registry version. `replace/2` marks the old entry deprecated and inserts the new entry without validating the old ID or the new specification's dependency/identity integrity.

**Impact:** The registry that defines CEL's service inventory and boot order can be changed through an API path that does not demonstrate the constitutional authorization boundary. The registry is also process-local, so its mutation history is not a durable, replayable governance record. This finding concerns the mutation APIs reviewed; it does not assert that every caller or deployment environment can reach them remotely.

**Closure evidence:** enumerate all registry mutation callers and threat boundaries; enforce Council authorization for high-impact changes; validate schemas, IDs, dependencies and cycles; persist versioned signed change records; test denied changes, replay, restart recovery, tampering and concurrent updates.

#### RL-173 — CEL's boot resource gate is supplied as an unconditional success callback

**Status: Source-confirmed.** CEL Kernel calls `BootSequencer.boot/4` with a resource checker that returns `:sufficient` for every service. The BootSequencer does invoke the resource gate, but the production caller does not supply an observed resource assessment.

**Impact:** The presence of a resource gate in the boot sequence does not establish resource admission. Services can pass this gate without measured CPU, memory, disk, process-count or configured capacity evidence. This weakens the meaning of a CEL `:ready` report.

**Closure evidence:** connect a bounded, observable resource assessment with thresholds and freshness; fail closed on missing/invalid measurements; test pressure, measurement failure, capacity exhaustion and recovery. Do not substitute a constant callback for runtime evidence.

#### RL-174 — ToolForge-generated Elixir tools contain a non-implemented execution body

**Status: Source-confirmed.** The Elixir source template generated by `ToolBuilder` defines `do_execute/1` as returning `{:error, {:not_implemented, input}}`. The generated wrapper nevertheless increments its execution counter after calling that function and wraps the return value in `{:ok, result}`; the generated test only asserts `{:ok, _}`, so it accepts the nested not-implemented error as a successful execution response.

**Impact:** A generated tool can pass its generated smoke test while its actual capability is absent. Its health/execution counters can imply activity without proving successful work. A build artifact is not an executable capability.

**Closure evidence:** generated implementation must be derived from a typed specification and provide real side effects or explicit `:unavailable`; generated tests must assert semantic postconditions and failure behavior, not merely wrapper shape; independent execution must verify output and side effects against the specification.

#### RL-175 — ToolForge Python template returns an implementation-shaped placeholder

**Status: Source-confirmed.** The generated Python template's `do_execute` is explicitly marked TODO and returns a dictionary with status `implemented` plus the original input. The generated HTTP execution route treats that returned dictionary as a successful result and increments its execution counter.

**Impact:** The Python output can report an implementation-shaped success without performing the requested operation. This is a false capability signal and is more dangerous than an explicit unavailable response because downstream consumers may trust the result.

**Closure evidence:** remove success-shaped placeholders; return an explicit unavailable/error until a real implementation is generated, independently built and semantically verified; test that the output cannot claim success without a specified observable effect.

#### RL-176 — ToolForge human review is recorded as passed without waiting for or checking an approval

**Status: Source-confirmed.** In `ToolForgeEngine.request_human_review/2`, the code constructs a `HAI.Domain.ReviewRequest` but discards the result and returns `:ok`. If request construction raises, the rescue branch also returns `:ok`. The pipeline then logs “Human review passed” and returns the generated tool as `{:ok, tool}`. The inspected path does not retrieve an approval decision, bind it to the exact artifact hash, or verify reviewer identity/authority.

**Impact:** The human-review step is not an approval gate. ToolForge can label a generated artifact reviewed/passed when request creation failed or when no human decision was obtained. This conflicts with the requirement that humans retain authority over high-impact system changes.

**Closure evidence:** create a durable pending review bound to exact artifact/spec hashes; return pending rather than success until an authorized human decision is verified; enforce expiry, reviewer identity, decision scope and revocation; test missing queue, failed request, rejection, stale approval and artifact substitution.

#### RL-177 — ToolForge pipeline has no demonstrated deployment or runtime-registration stage

**Status: Source-confirmed for the inspected ToolForge implementation.** `ToolForgeEngine` tracks `tools_built` and `tools_deployed`, but its pipeline ends after source generation, shallow nonempty/name validation and the ineffective review step. The engine increments the built counter and retains the generated artifact; no deployment/activation/registration call appears in the inspected pipeline. The generated build instructions ask an operator to add the module to a supervision tree. The supervisor starts only ToolBuilder and ToolForgeEngine.

**Impact:** A successful `engineer_tool/1` response means a generated artifact was produced, not that it compiled, passed independent tests, was safely deployed, became reachable, or can be rolled back. The `tools_deployed` statistic is not evidence of an operational deployment.

**Closure evidence:** define explicit artifact lifecycle states (designed, generated, compiled, tested, independently verified, human-approved, staged, deployed, health-verified, rollback-capable); persist each transition with artifact digest and provenance; require isolated execution and resource/network controls; prove activation, failure rollback and post-deployment behavior. Until then ToolForge must report build-only capability.

#### Checkpoint 18.20 disposition

- Council is the constitutional authorization mechanism in the reviewed runtime paths; it is not the technical owner of canonical world history.
- The CEL boot pipeline has meaningful fail-closed constitutional-score and health logic, but production startup is asynchronous and its resource checker is unconditionally sufficient. A root application start is therefore not proof of CEL readiness.
- The ServiceRegistry's public mutation handlers do not demonstrate authorization, validation or durable governance history.
- ToolForge's generated Elixir/Python execution templates do not implement the described tool behavior; the human-review step does not wait for approval; the pipeline does not demonstrate deployment or activation.
- RL-171–RL-177 are added. All earlier findings remain open unless independently closed with exact-candidate evidence.
- No tests, application runtime boot, integration runs or source changes were performed. This checkpoint is source inspection only.

**Checkpoint 18.20 disposition:** CEL and ToolForge are now explicit priority audit targets. Next, continue CEL's service-by-service dependency/capability/health/score audit and ToolForge's specification-to-code, compiler/test, sandbox, artifact-integrity, authorization and lifecycle audit. Keep both read-only until the full evidence map and remediation order are approved.


### Checkpoint 18.21 — CEL registry inventory and boot dependency integrity

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Method:** Exact-SHA source inspection of CEL ServiceRegistry, BootSequencer, Kernel, ExecutiveMemory, EventStore, EventBus, ConstitutionalScorePipeline and UnifiedRealityGraph. This is a read-only source audit; no test execution or source changes.

#### CEL inventory baseline

The exact-baseline `ServiceRegistry.canonical_services/0` declares 33 service entries, including executive memory and event storage, event bus, constitutional score pipeline, capability graph, resource manager, identity/trust manager, priority engine, executive scheduler, metrics, runtime policy, world graph/mutation/provenance/model/version/ontology/snapshot/replay, conflict services, knowledge/evidence/epistemic services, research/experiment/discovery services, mission director, workflow engine, executive state manager, decision predictor and executive digital twin.

The registry metadata is an intended service contract, not proof that every advertised capability is implemented, independently tested, connected to callers, or operational. The audit will validate those separately, service by service.

#### RL-178 — CEL boot can proceed past a failed noncritical dependency

**Status: Source-confirmed.** `BootSequencer.boot/4` determines dependency eligibility using `not Enum.any?(spec.depends_on, &(&1 in failed_crit))`. The `failed_crit` accumulator is updated only by `handle_failed/6`, while `handle_degraded/6` records a degraded service but leaves `failed_crit` unchanged. Thus, if a dependency is noncritical and fails to start or fails a gate, a dependent service can still be attempted even though the prerequisite is not running. The registry includes dependent services whose prerequisites include high/medium criticality services (for example, `:executive_scheduler` depends on high-criticality `:resource_manager`).

**Impact:** A dependent service may start and potentially be counted as healthy despite a required service being absent. The resulting boot report does not establish dependency-complete readiness.

**Closure evidence:** maintain explicit per-service terminal outcomes and gate each dependent on every declared prerequisite reaching an allowed operational state; define whether degraded dependencies are ever acceptable per service; test failure of each dependency class and assert dependents are skipped or explicitly degraded, never silently booted as ready.

#### RL-179 — CEL dependency sorting does not fail boot explicitly on cycles or unresolved dependencies

**Status: Source-confirmed.** `ServiceRegistry.topological_sort/1` and `do_sort/4` log an error and return the accumulated partial order when no remaining service has an empty dependency list. The function does not return an error tuple or invalid-graph marker to BootSequencer. A cycle or dependency on an ID absent from the registry therefore yields a partial list; BootSequencer receives that list as its boot order and does not independently validate that all active registry entries were included.

**Impact:** Invalid registry topology can be converted into an apparently usable partial boot plan. Depending on which services were omitted, boot may report ready/degraded based only on the subset it attempted, rather than declaring the service graph invalid.

**Closure evidence:** validate the complete active graph before starting any child; reject unknown dependency IDs, cycles, duplicate IDs and inconsistent requires/provides declarations; return structured graph errors and refuse boot; test self-cycles, multi-node cycles, missing IDs, deprecated dependencies and disconnected components.

#### Service-level evidence notes (not yet final findings)

- `ExecutiveMemory` opens DETS at a relative path and falls back to public volatile ETS if DETS open fails, emitting a degraded telemetry event. Its record path appends to the CEL EventStore and then updates an index. This requires deeper examination of fallback semantics, index rebuild/recovery, snapshot consistency and lineage correctness.
- CEL `EventStore` rejects append while degraded and uses DETS for append/read. Its `healthy?` handler checks degraded state and DETS table availability. Retention/pruning and offset behavior require further examination before treating it as canonical world history.
- CEL `EventBus` persists event payloads through EventStore and stores failed-delivery events in a DETS DLQ. Its `:healthy` handler returns `true` unconditionally; the registry health MFA is `health/0`, so the precise wrapper/health mapping must be reconciled against the module's exported API and BootSequencer's health interpretation. No conclusion of end-to-end delivery correctness is made yet.
- `ConstitutionalScorePipeline` stores rolling score windows in process memory. Its fallback extraction assigns neutral 0.5 values to unrecognized telemetry events; an empty window returns a score with health 1.0 and several 0.5 dimensions. This is an analytics stream, not independent evidence of every service's constitutional compliance.
- `UnifiedRealityGraph` keeps its graph in an in-memory `:digraph`; its `historical_state/1` handler ignores the supplied timestamp and returns current counts. This is consistent with earlier world-persistence findings and is not evidence of historical reconstruction.

#### Checkpoint 18.21 disposition

- Registry inventory baseline: 33 services declared.
- RL-178 and RL-179 added.
- The inventory is not a certification list. Every service still requires implementation, caller, data ownership, health honesty, constitutional evidence, resource, restart, and failure-path inspection.
- No tests were run and no application source was changed.
- Continue with the critical executive substrate first: ExecutiveMemory, EventStore, EventBus, CapabilityGraph, ResourceManager, IdentityTrustManager, PriorityEngine and ExecutiveScheduler. Then audit world/research/mission services and the remaining registry entries. ToolForge remains a separate priority workstream after CEL's service inventory has been reconciled.


### Checkpoint 18.22 — CEL critical substrate: ExecutiveMemory and EventStore

**Audit target:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Method:** Exact-SHA inspection of ExecutiveMemory, EventStore, CapabilityGraph, ResourceManager, IdentityTrustManager, PriorityEngine and ExecutiveScheduler. This pass concentrated on ExecutiveMemory/EventStore code paths; remaining services are not certified by this checkpoint. No tests were run and no source was changed.

#### RL-180 — ExecutiveMemory's declared CEL dependency omits its EventStore prerequisite

**Status: Source-confirmed.** The ServiceRegistry entry for `:executive_memory` declares `depends_on: []`. The ExecutiveMemory module's own `dependencies/0` declares `[:event_store]`, and its `record/3` handler calls `EventStore.append/2`. Because the kernel boots according to ServiceRegistry metadata, not the module's separate dependency declaration, the boot graph does not enforce this prerequisite.

**Impact:** CEL can start ExecutiveMemory before EventStore. The memory service may appear booted while its primary record operation cannot yet succeed. The mismatch also means two competing dependency declarations exist, with no demonstrated consistency check.

**Closure evidence:** establish one authoritative dependency source or mechanically validate registry metadata against each service module; test boot order and startup failure when EventStore is unavailable; require readiness only after the dependency is operational.

#### RL-181 — ExecutiveMemory's volatile fallback does not provide a working record path

**Status: Source-confirmed by code path.** On DETS open failure, ExecutiveMemory creates a new ETS table and stores its reference in state, marking the backend degraded. However, the record handler unconditionally calls `store_index/2`, which unconditionally invokes `:dets.insert(@table_name, ...)`; it does not use the ETS reference or branch on `state.backend`. The EventStore append occurs before this index write. Thus the fallback backend does not implement the record path it advertises; an ETS fallback record attempt can fail after the event has already been appended to EventStore.

**Additional health inconsistency:** ExecutiveMemory's `health/0` checks `:dets.info(@table_name)` even when init selected ETS fallback, while its `constitutional_score/0` returns fixed 1.0 values rather than deriving the score from the degraded backend state.

**Impact:** The fallback can create split outcomes (durable EventStore append followed by memory-index failure/process crash), and the reported constitutional score can claim perfect health despite fallback degradation. A recovery path is not established.

**Closure evidence:** either remove the fallback and fail startup closed, or implement a fully tested backend abstraction for record/index/lineage/snapshot/recovery; make health and constitutional scoring reflect actual backend state; inject DETS failures and prove no partial-success or false-health result.

#### RL-182 — CEL EventStore pruning deletes historical events without a demonstrated archival handoff

**Status: Source-confirmed for the EventStore implementation.** `EventStore.prune/0` computes a cutoff from `Application.get_env(:tiannara, :dets_event_retention_hours, 168)` and deletes every stored event whose timestamp is older than that cutoff. The inspected pruning path deletes DETS keys directly; it does not first require a verified immutable archive, snapshot checkpoint, replay-equivalence proof or downstream retention receipt.

**Impact:** The store cannot be treated as a permanent canonical history source while its ordinary retention path deletes older records without a demonstrated archival contract. Any world/research/governance history placed here could become unrecoverable after pruning unless a separate archive path is proven.

**Closure evidence:** distinguish operational event retention from immutable canonical history; require archive-before-delete with content hashes, sequence/offset continuity, verified restore and audit receipts; test retention expiry, archive failure, interrupted pruning and replay across archive boundaries.

#### Checkpoint 18.22 disposition

- ExecutiveMemory has a registry/module dependency mismatch, an unusable DETS-to-ETS fallback record path, and health/constitutional reporting that does not faithfully represent fallback degradation.
- EventStore has an explicit 168-hour default pruning policy and no archive-before-delete requirement in the inspected prune path. It is therefore not suitable as the sole permanent history authority as currently evidenced.
- RL-180–RL-182 added. CapabilityGraph, ResourceManager, IdentityTrustManager, PriorityEngine and ExecutiveScheduler were discovered and partially inspected, but remain open for deeper caller/effect, persistence, security, fairness, and failure-path audits.
- No tests or runtime boot were performed; these are source-confirmed findings, not runtime verification.


## Checkpoint 18.23 — CEL critical service execution, trust, resource and scheduling audit

**Source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** `CapabilityGraph`, `ResourceManager`, `IdentityTrustManager`, `PriorityEngine`, `ExecutiveScheduler`, plus PriorityEngine outcome-signal and learning-model implementations.  
**Method/status:** Static source inspection. No runtime boot, tests, fault injection, or production resource measurements were performed in this checkpoint. Findings below are source-confirmed behaviors or limitations; production runtime impact remains to be verified.

### RL-183 — CapabilityGraph is volatile and not a canonical capability authority
**Severity:** HIGH  
**Evidence:** `lib/tiannara/cel/services/capability_graph.ex` constructs an in-memory protected `:digraph` during `init/1`, seeds a fixed subsystem/capability set, and stores metadata/deprecation state in the GenServer state. No durable graph reload or authoritative reconciliation with the service registry is present in the inspected module.  
**Impact:** Capability registrations, graph relationships, deprecations and derived topology are lost on process restart unless an external reconstruction mechanism exists; none was demonstrated in the inspected service. This is not yet a durable, authoritative capability inventory.

### RL-184 — CapabilityGraph accepts incomplete and cyclic relationships while recording mutations best-effort
**Severity:** HIGH  
**Evidence:** `add_edge_internal/4` calls `ensure_vertex/2` for both endpoints, creating absent vertices rather than requiring registered capability/subsystem/mission entities. `handle_call({:add_edge,...})` detects a dependency cycle after insertion, emits a warning/event, increments a counter, but does not reject or roll back the edge. `record_mutation/3` rescues exceptions and returns `:ok`, so failed ExecutiveMemory audit writes do not prevent graph mutation.  
**Impact:** The graph can contain relationships to undeclared entities and known cyclic dependencies; an apparently successful mutation need not have durable audit evidence. Consumers cannot treat graph validity or audit completeness as enforced invariants.

### RL-185 — CapabilityGraph provider ranking uses fallback and fixed scoring inputs
**Severity:** MEDIUM  
**Evidence:** `compute_provider_score/2` uses IdentityTrustManager trust where available, but substitutes `0.8` on unknown identity, error or process exit; remaining score contributions are constants `0.7` and `0.9`. `find_optimal_provider/1` rejects candidates based on whether the *capability ID* is in the deprecated set, rather than checking each provider's own operational/deprecation state.  
**Impact:** A provider can receive a favorable ranking without verified identity/trust data, and the ranking does not establish measured load, execution history or current capability health. Deprecation filtering is not aligned with provider status.

### RL-186 — ResourceManager capacity and reservation accounting do not enforce real quotas
**Severity:** CRITICAL  
**Evidence:** `lib/tiannara/cel/services/resource_manager.ex` initializes fixed totals (CPU 100, memory 65,536 MB, GPU 8, storage 10,000 GB); `init_pools/0` returns an empty map. `compute_available/1` adds the 20% sustainability reserve to remaining capacity instead of withholding it. `do_allocate/3` adds each request to aggregate allocation but stores only one reservation per service ID, overwriting any prior reservation. The not-ready retry path recursively calls `handle_call({:allocate, nil, nil},...)`, losing the original service ID and request.  
**Impact:** Capacity is not tied to measured host resources; available capacity can exceed the configured total; repeated allocations can desynchronise reservation and aggregate accounting; retry after deferred initialization cannot correctly replay the request. The manager cannot currently be trusted as an enforcement-grade quota authority.

### RL-187 — ResourceManager release is unauthenticated, asynchronous and not tied to actual job lifecycle
**Severity:** HIGH  
**Evidence:** Public `release/2` sends a cast with caller-supplied resource amounts. The handler subtracts those amounts (clamped at zero) and deletes the entire service reservation, without matching the release to the recorded reservation or an allocation identifier. No caller identity, authorization, allocation token, or idempotency key is checked.  
**Impact:** A caller can release resources not associated with its allocation or erase a reservation while leaving other allocations accounted inconsistently. Cast semantics provide no synchronous confirmation that resources were released.

### RL-188 — IdentityTrustManager uses volatile identities and non-governed trust mutations
**Severity:** CRITICAL  
**Evidence:** `lib/tiannara/cel/services/identity_trust_manager.ex` initializes a small identity map in memory with credentials hashed from literal strings such as `kernel_secret`, `registry_secret`, `memory_secret` and `bus_secret`. Registration returns a hash derived from a generated secret, but identities are not persisted. `report_violation/2` and `report_success/1` are public casts that alter trust without authenticated actor, signed evidence, authorization, bounds validation or durable audit in the inspected handlers. `authorize_action/2` checks capability membership and trust >= 0.3; it does not verify a presented credential.  
**Impact:** Identity and trust state are not restart-durable; initial credentials are predictable from source; trust can be changed through unverified reports; authorization is a capability/trust lookup, not demonstrated credential-backed authentication. Credential hashing alone does not establish secure credential lifecycle or authorization.

### RL-189 — PriorityEngine learning is volatile and part of its event-ingestion path uses synthetic labels
**Severity:** HIGH  
**Evidence:** `lib/tiannara/cel/services/priority_engine.ex` initializes weights and signal/calibration buffers in process state with no durable checkpoint/reload in the inspected module. For EventBus workflow topics, `handle_info({:event,...})` constructs fixed feature vectors `[0.5,0.5,0.5,...]` and fixed target scores `0.8`/ `0.2` based only on event type. `Priority.OutcomeSignal.composite_score/3` also embeds a fixed outcome score and fixed baseline contribution. `LearningModel.calibration_score/2` returns `1.0` for an empty calibration set. Learning-event persistence is best-effort and swallows errors.  
**Impact:** A subset of model updates is trained against constructed labels rather than independently verified workflow outcomes; a perfect empty-window calibration result is misleading; model state can reset on restart. Current metrics do not establish calibrated, independently validated priority predictions.

### RL-190 — ExecutiveScheduler does not implement priority ordering or guaranteed fairness
**Severity:** HIGH  
**Evidence:** `lib/tiannara/cel/services/executive_scheduler.ex` inserts jobs into `:queue` and `request_next` always dequeues the oldest item. Aging updates `effective_priority` but does not reorder the queue. `starved_missions` is incremented per aged job on every aging cycle and is not reset when jobs progress or complete.  
**Impact:** PriorityEngine output and aging do not determine dispatch order; repeated counting can inflate starvation metrics. Priority-aware scheduling and fairness guarantees are not established.

### RL-191 — ExecutiveScheduler drops resource allocations on completion and preemption
**Severity:** CRITICAL  
**Evidence:** `submit_work/3` calls `ResourceManager.allocate/2`. The completion cast removes the running-job entry and emits an event but never calls `ResourceManager.release/2`. The preemption handler removes a running or queued job but neither releases its allocation nor demonstrates cancellation/termination of the worker executing it.  
**Impact:** Resource reservations can remain allocated after work ends or is preempted; workers may continue executing after scheduler state says a job was preempted. This can cause capacity leakage and divergence between scheduler, worker and resource-manager state.

### RL-192 — ExecutiveScheduler execution and recovery state is volatile and completion is unacknowledged
**Severity:** HIGH  
**Evidence:** Queue, running-job map, counters and timestamps live only in GenServer state. `complete_job/2` is a cast, and unknown job IDs are silently ignored. The inspected service has no durable job journal, worker lease/heartbeat, crash recovery, retry/resume protocol, or completion acknowledgement.  
**Impact:** A scheduler restart loses queued/running work state; callers cannot establish that a completion was accepted; worker loss and partial execution are not reconciled.

### RL-193 — ExecutiveScheduler does not validate work contracts before resource admission
**Severity:** HIGH  
**Evidence:** `submit_work/3` reads `:resources` from `work_spec`, then passes the entire `work_spec` to `PriorityEngine.calculate_priority/1`, whose public API accepts a `CivilizationalEvent` struct. The inspected handler has no explicit schema/type validation, mission authorization, capability/provider verification, or admission transaction tying resource allocation to successful queue insertion.  
**Impact:** Invalid work shapes can cause runtime failure after resource allocation, leaving reservations behind; the boundary does not demonstrate authenticated, typed, transactionally admitted work.

**Checkpoint disposition:** 11 findings added (RL-183–RL-193). No finding is closed. No remediation was performed. Continue CEL audit with MissionDirector and WorkflowEngine, then reconcile the remaining CEL service inventory before beginning the separate ToolForge lifecycle workstream.


## Checkpoint 18.24 — MissionDirector and WorkflowEngine lifecycle audit

**Source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** `lib/tiannara/cel/services/mission_director.ex`, `lib/tiannara/cel/services/workflow_engine.ex`, workflow outcome telemetry and orchestration call paths.  
**Method/status:** Static source inspection only. No runtime tests, crash recovery exercise, persistence-failure injection, or governance-path execution was performed.

### RL-194 — MissionDirector starts after mission-store initialization failure
**Severity:** CRITICAL  
**Evidence:** `MissionDirector.init/1` logs an error if `:dets.open_file/2` fails but still returns `{:ok, %{total_missions: 0, missions_by_status: %{}}}`. Subsequent mission operations call `:dets.insert/2`, `:dets.lookup/2` and `:dets.traverse/2` directly without checking that the table is open or that the operation succeeded.  
**Impact:** The service can be considered started while its mission persistence substrate is unavailable; later calls may fail/crash rather than returning an explicit degraded/not-ready result. This is fail-open startup behavior for mission state.

### RL-195 — MissionDirector persistence and transition audit are best-effort, not transactional
**Severity:** HIGH  
**Evidence:** `persist_mission/1` returns the raw `:dets.insert/2` result, but callers such as create/add-program/add-objective/launch/validation/completion do not check it before returning success. `record_transition/3` rescues all errors and returns `:ok`; event publication does likewise. Mission data, transition evidence and emitted events are not committed atomically.  
**Impact:** A caller can receive a successful mission/program/objective/workflow/validation/completion response without durable mission state or corresponding audit evidence. Partial updates and silent audit loss are possible.

### RL-196 — MissionDirector validation accepts presence, not verified evidence
**Severity:** CRITICAL  
**Evidence:** `submit_validation/2` only checks `length(evidence) >= 1`, then appends the supplied terms and sets the objective status to `:validated`. The inspected handler does not validate evidence schema, source identity, signatures, provenance, experiment linkage, independent review, reproducibility, falsification status, or constitutional approval.  
**Impact:** Arbitrary nonempty caller-provided data can advance an objective to validated. The state transition is not proof that a scientific claim or deliverable passed a verification gate.

### RL-197 — MissionDirector completion assessment is caller-authored and assessor identity is unverified
**Severity:** HIGH  
**Evidence:** `complete_mission/3` constructs the ImpactAssessment directly from caller-supplied numeric fields and assessor term. The gate only counts objectives still `:in_progress` or `:pending`; it does not verify the assessor's identity/authority, assessment evidence, metric derivation, or independent impact measurement.  
**Impact:** Mission completion and reported impact can be asserted without a demonstrated trusted assessor or evidence-backed impact calculation.

### RL-198 — MissionDirector status statistics are not reconstructed from durable mission records
**Severity:** MEDIUM  
**Evidence:** On initialization the service sets total/status counts to zero without traversing existing DETS mission records. `:stats` returns this in-memory state; several mutations such as add-program/objective do not update the counts.  
**Impact:** After restart or state transitions, mission counts and status metrics can disagree with persisted mission records; the metrics are not authoritative lifecycle evidence.

### RL-199 — WorkflowEngine does not restore persisted workflow state into its live state map
**Severity:** CRITICAL  
**Evidence:** On successful DETS open, `init/1` calls `recover_interrupted_workflows/0` only to log the returned list length, then initializes `workflows: %{}` and counters to zero. The recovery helper scans running workflows, writes a failed copy, but returns the original running workflow value from its map callback. Other persisted paused/terminal workflows are not loaded into the GenServer map in the inspected initialization path.  
**Impact:** The DETS file is not used to reconstruct the service's operational workflow state. Existing workflow IDs may be unavailable through get/status/active APIs after restart; interrupted workflows are not restored as actionable or reconciled with resource ownership.

### RL-200 — WorkflowEngine acknowledges start and lifecycle transitions without requiring persistence success
**Severity:** CRITICAL  
**Evidence:** `do_start_workflow/2` calls `persist_workflow/1` but ignores its return value, then records events, updates in-memory state and replies `{:ok, workflow_id}`. Pause, resume, cancel, checkpoint, step-success, failure and completion paths likewise invoke persistence without consistently checking the result before advancing state or acknowledging the caller. Persistence retries can eventually give up while retaining only in-memory state.  
**Impact:** The engine can report accepted/advanced/completed work that is not durably recorded. A crash can erase acknowledged state and make external orchestration inconsistent with actual execution.

### RL-201 — WorkflowEngine's advertised Council-gated high-impact execution is not demonstrated
**Severity:** HIGH  
**Evidence:** The high-impact path calls `ExecutiveDigitalTwin.simulate_strategy/1` and rejects a simulation recommendation of `:reject`; otherwise it attaches simulation evidence and starts the workflow. The inspected `handle_call({:start,...})` path does not request a Council authorization decision or verify a ratified policy/approval artifact before dispatch.  
**Impact:** Simulation advice is treated as the high-impact gate in this path; it does not establish the separately advertised Council-gated authorization boundary.

### RL-202 — CapabilityGraph provider discovery does not delegate execution to the selected provider
**Severity:** HIGH  
**Evidence:** `execute_step/2` calls `CapabilityGraph.find_optimal_provider/1` and receives a provider ID, but then invokes `step.module.execute(step.input, workflow.context)` directly. The provider ID is used only for success/failure trust reporting; no provider dispatch, authenticated provider invocation, or provider-result verification is present in this execution function.  
**Impact:** Capability selection is advisory/telemetry in the inspected path, not actual provider delegation. The workflow can execute a local step module while reporting a selected provider as the execution provider.

### RL-203 — Workflow step execution blocks the WorkflowEngine GenServer and has no enforced step timeout
**Severity:** HIGH  
**Evidence:** `handle_info({:advance_workflow,...})` calls `execute_next_step/2`, which directly calls `execute_step/2` and then `step.module.execute/2` in the GenServer process. The inspected path has no isolated worker, monitored task, deadline, cancellation token, or bounded execution timeout.  
**Impact:** A slow or hung step blocks workflow control calls, pause/cancel requests, other workflow advances and recovery handling. Failure containment and responsiveness are not established.

### RL-204 — WorkflowEngine crash recovery marks interrupted workflows failed without reconciling resources or compensation
**Severity:** CRITICAL  
**Evidence:** `recover_interrupted_workflows/0` changes a running workflow to failed and attempts to persist it, but does not invoke saga compensation or `release_resources/1`. It returns the original workflow value rather than the recovered value. The init caller does not load either form into the live workflow map.  
**Impact:** Interrupted workflows can retain resource allocations, leave external side effects uncompensated and disappear from operational state. The recovery routine does not establish a reconciled post-crash lifecycle.

### RL-205 — WorkflowEngine saga compensation records failures but does not enforce successful rollback
**Severity:** HIGH  
**Evidence:** `compensate_completed_steps/2` logs compensation failures and records `:compensation_failed` entries, but still returns `{:ok, workflow_with_log}`. Cancellation/failure paths then set terminal status to `:cancelled` or `:failed` and release resources without requiring every compensation to succeed or retaining an explicit unresolved-compensation state that blocks downstream completion.  
**Impact:** A workflow can be labelled cancelled/failed after incomplete compensation without a verified stable postcondition. The advertised saga rollback guarantee is not enforced.

### RL-206 — Workflow resource allocation is not scoped to a unique workflow reservation
**Severity:** HIGH  
**Evidence:** `do_start_workflow/2` allocates using the constant service key `:workflow_engine`, and `release_resources/1` releases under the same key. The ResourceManager stores one reservation per service ID (RL-186/187), while multiple workflows can be active concurrently.  
**Impact:** Concurrent workflows share/overwrite one reservation identity; releasing one workflow can release the aggregate reservation for others, while allocations can be lost or leaked. Workflow-level resource ownership is not represented.

### RL-207 — Workflow retention pruning deletes terminal records without a demonstrated archival receipt
**Severity:** HIGH  
**Evidence:** `prune/0` deletes terminal workflow DETS records older than the configured retention cutoff directly. The inspected function does not require an immutable archive, checkpoint, replay equivalence proof or downstream retention receipt before deletion.  
**Impact:** Workflow lifecycle and evidence history can be permanently removed without demonstrated archival continuity, weakening auditability and reproducibility.

**Checkpoint disposition:** 14 findings added (RL-194–RL-207). No finding is closed. No remediation was performed. Continue the CEL audit with remaining registered services and cross-service lifecycle/caller reconciliation; ToolForge remains a distinct later workstream.


## Checkpoint 18.25 — CEL observability, policy, prediction and digital-twin audit

**Source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** ExecutiveMetrics, RuntimePolicyEngine, ExecutiveStateManager, DecisionPredictor, ExecutiveDigitalTwin.  
**Method/status:** Static source inspection only. No runtime tests, prediction backtests, simulation validation, policy enforcement tests or persistence fault injection were run.

### RL-208 — ExecutiveMetrics mission-outcome ingestion discards the derived KPI data
**Severity:** MEDIUM  
**Evidence:** `ExecutiveMetrics.handle_cast({:mission_outcome,...})` derives mission KPI values and attempts to record them in ExecutiveMemory, but returns the unchanged state. Those values do not update KPI aggregates, history, calibration, or mission outcome counters in this service.  
**Impact:** The public ingestion API can accept mission outcomes without those outcomes contributing to the metrics it exposes; consumers may mistake an event write attempt for integrated KPI accounting.

### RL-209 — ExecutiveMetrics uses default-success rates for missing or empty denominators
**Severity:** HIGH  
**Evidence:** `calc_rate(nil, _)`, `calc_rate(_, nil)` and `calc_rate(_, 0)` all return `1.0`. The collector obtains workflow/scheduler/priority/state data through calls that rescue failures and substitute empty maps or nil, so unavailable measurements can flow into apparently successful rates. `constitutional_score/0` also defaults missing success/recovery rates to 1.0.  
**Impact:** Missing telemetry, service unavailability and zero observations can be represented as perfect success/recovery, creating false confidence in executive KPIs and constitutional alignment.

### RL-210 — ExecutiveMetrics does not persist its KPI history or alerts as service state
**Severity:** MEDIUM  
**Evidence:** KPI maps, history and alerts are held only in GenServer state; history is capped at 50 samples. Event recording is best-effort and rescued. Initialization starts with empty history/alerts and no replay/reload path.  
**Impact:** Restart loses the trend/alert state used by dashboards and decision-makers; attempted event logging is not demonstrated as a durable reconstruction mechanism.

### RL-211 — RuntimePolicyEngine policy changes are volatile and not authorization-gated
**Severity:** CRITICAL  
**Evidence:** `RuntimePolicyEngine.init/1` initializes `policies: %{}`; put/disable handlers mutate this map only. `put_policy/1` accepts a RuntimePolicy struct without checking actor authority, signed approval, immutable policy version lineage, or a Council authorization decision. `disable_policy/2` accepts an actor term and records it as metadata without authenticating it. The audit helper rescues errors and returns `:ok`.  
**Impact:** Policies disappear on restart and policy activation/deactivation can be performed through public service calls without a demonstrated governance or durable audit gate. This is not a production-grade policy authority.

### RL-212 — RuntimePolicyEngine permits permissive decisions when no policy matches
**Severity:** CRITICAL  
**Evidence:** `handle_call({:evaluate,...})` returns `{:allowed, %{reason: "no_matching_policy"}}` when no active policy matches. The inspected evaluator has no mandatory baseline policy, deny-by-default mode, completeness check, or indication that the policy set is unavailable/incomplete.  
**Impact:** Missing, expired, unregistered or nonmatching policy coverage defaults to allow. This is unsafe for a runtime enforcement boundary where unknown policy state must not be treated as permission.

### RL-213 — RuntimePolicyEngine selects one matching policy without conflict resolution or cumulative constraints
**Severity:** HIGH  
**Evidence:** Applicable policies are sorted by priority and only the first is used. The inspected path does not detect equal-priority conflicts, combine restrictive constraints, enforce a mandatory deny override, or prove that priority ordering is ratified.  
**Impact:** Conflicting policy outcomes can be silently hidden by ordering; a permissive high-priority policy can supersede a restrictive lower-priority policy without a demonstrated constitutional conflict rule.

### RL-214 — ExecutiveStateManager publishes snapshots without durable versioned snapshot records
**Severity:** HIGH  
**Evidence:** The manager generates random snapshot IDs and holds the current snapshot/counter in process state. It publishes a subset to EventBus and calls ExecutiveMemory.record_event, but does not persist the complete ExecutiveState snapshot as a versioned durable artifact in the inspected code. Publication and recording return values are not checked before state advances.  
**Impact:** The full snapshot used for governance/diagnostics cannot be reconstructed from the manager's current state after restart; successful generation counters do not prove that the complete snapshot was durably stored or delivered.

### RL-215 — ExecutiveStateManager converts unavailable critical services into zero/empty values
**Severity:** HIGH  
**Evidence:** Snapshot getters rescue failures and substitute values such as zero active missions/workflows, empty capability/resource maps, zero queue depth and zero human reviews. `calculate_snapshot_confidence/1` only checks whether three service-health keys exist and subtracts a fixed 0.2 per missing key; it does not account for the many other getters that may have failed or for stale/unknown values.  
**Impact:** Service outages and query errors can appear as a healthy empty system. Snapshot confidence and aggregate state are not a complete representation of source coverage or freshness.

### RL-216 — ExecutiveStateManager emits a hard-coded policy version and placeholder knowledge-ingestion rate
**Severity:** MEDIUM  
**Evidence:** `build_snapshot/1` assigns `policy_version: "1.0.0"` rather than querying the active policy set; `get_knowledge_ingestion_rate/0` always returns `0.0`.  
**Impact:** Snapshot fields do not reliably describe current runtime policy or knowledge-ingestion activity and must not be interpreted as measured operational state.

### RL-217 — DecisionPredictor mission forecasts use no historical mission evidence and a fixed prior
**Severity:** CRITICAL  
**Evidence:** `find_similar_missions/1` always returns `[]`; `compute_base_success_rate([])` returns a fixed `0.7`. The mission prediction handler therefore has no historical sample and computes uncertainty as 1.0, while still returning a numeric predicted success rate and confidence interval.  
**Impact:** A forecast can look quantitative without any retrieved comparable mission outcomes. The fixed prior is not a learned or evidence-derived base rate.

### RL-218 — DecisionPredictor resource and overload forecasts are synthetic rather than measurement-backed
**Severity:** CRITICAL  
**Evidence:** `check_resource_availability/1` always returns `%{sufficient: true, bottlenecks: []}`. `query_historical_load/2` generates an artificial linear sequence based on the requested horizon rather than querying measured service history. Resource exhaustion also falls back to hard-coded pool and zero allocation values when ResourceManager calls fail.  
**Impact:** Mission feasibility can be overstated and overload forecasts can report trends unsupported by observations. Resource availability and forecast output are not safe admission evidence.

### RL-219 — DecisionPredictor dependency-failure and experiment recommendations are fixed examples
**Severity:** HIGH  
**Evidence:** `predict_dependency_failures` returns two fixed inferred dependency records; `recommend_experiments` returns a fixed list with hard-coded information-gain/cost/duration values. Telemetry events are received but `handle_info({:telemetry_event,...})` discards them; prediction history and accurate-prediction counters are not updated in the inspected handlers.  
**Impact:** These APIs present example-shaped data as predictions/recommendations without an evidence-generation pipeline or observed outcome feedback.

### RL-220 — DecisionPredictor risk assessment uses a narrow resource-cost heuristic
**Severity:** HIGH  
**Evidence:** `compute_predictive_risk/2` uses only `payload.resource_cost`, defaults missing cost to zero and divides by a fixed 1000 threshold. The risk result is combined with Council RuleEngine confidence using fixed 0.6/0.4 weights.  
**Impact:** Missing resource-cost data is treated as zero predictive risk; other material risk dimensions are not represented by this predictor calculation. The resulting overall score is not a validated general risk estimate.

### RL-221 — ExecutiveDigitalTwin simulation is stochastic and depends on unvalidated synthetic predictions
**Severity:** CRITICAL  
**Evidence:** `run_simulation/4` obtains a prediction through DecisionPredictor and uses `:rand.uniform()` to determine whether each step succeeds. DecisionPredictor's inspected mission predictor has no historical mission data and uses synthetic resource/capability inputs (RL-217–219). Unknown prediction is recorded as a step outcome of `:unknown` while simulation proceeds to later steps.  
**Impact:** Identical strategy inputs can produce different simulation outcomes; simulation success is not deterministic/reproducible evidence and is downstream of unvalidated forecasts. Unknown steps do not necessarily block a favorable final report.

### RL-222 — ExecutiveDigitalTwin does not execute or validate strategy step semantics in its sandbox
**Severity:** CRITICAL  
**Evidence:** The simulation loop does not invoke a step implementation or validate a step contract; it asks DecisionPredictor for a prediction. `deduct/2` ignores the prediction and adds a fixed 0.05 to every resource value (capped at 1.0). No actual resource model, state transition semantics, invariants, or measured execution outcomes are applied.  
**Impact:** The twin is a probabilistic scenario generator, not a demonstrated faithful digital twin of the live executive system or strategy execution environment.

### RL-223 — ExecutiveDigitalTwin does not enforce sandbox isolation or validate simulation inputs
**Severity:** HIGH  
**Evidence:** The sandbox is a local map initialized from current ResourceManager/CapabilityGraph reads, with hard-coded fallback data if those calls fail. The inspected simulation handler does not validate strategy schema, step count/type, recovery plan structure or provenance before processing; `run_simulation/4` has a step-count cap but no independent sandbox process or side-effect isolation mechanism.  
**Impact:** The module's state-isolation claim is not established by an enforced isolation boundary; malformed or untrusted inputs and unavailable source services can produce misleading reports.

### RL-224 — ExecutiveDigitalTwin labels simulation reports validated without independent validation
**Severity:** HIGH  
**Evidence:** The service exposes `validated_simulations` in its state and computes constitutional evidence quality from that counter, but the inspected simulation/counterfactual handlers only increment `total_simulations`; no independent validator, ground-truth comparison, or validation counter update exists in this module.  
**Impact:** The advertised validated-simulation metric has no demonstrated producer and cannot substantiate simulation fidelity.

**Checkpoint disposition:** 17 findings added (RL-208–RL-224). No finding is closed. No remediation was performed. Next: reconcile the complete CEL registry against implemented modules, runtime callers, actual supervision/startup, declared dependencies, and production evidence; then proceed through any remaining registered services before starting ToolForge as a separate audit stream.


## Checkpoint 18.26 — CEL registry, declared dependency and boot-contract reconciliation

**Source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** `ServiceRegistry.canonical_services/0`, each inspected service's `dependencies/0`, BootSequencer dependency behavior and registry health-check declarations.  
**Method/status:** Static source reconciliation. No boot execution or module-start matrix was run. The canonical registry contains 34 non-deprecated service specifications in the inspected baseline.

### RL-225 — Registry dependency graph diverges from service-declared dependencies
**Severity:** CRITICAL  
**Evidence:** The registry's `depends_on` entries do not consistently match each service module's `dependencies/0`. Examples: MissionDirector module declares `:workflow_engine` but registry omits it; WorkflowEngine module declares `:event_store`, `:executive_digital_twin` and `:identity_trust_manager` in addition to other dependencies, while registry omits those and does not include the twin/trust edge; ExecutiveStateManager module declares `:event_store` but registry omits it; DecisionPredictor module declares `:identity_trust_manager` but registry omits it; ExecutiveDigitalTwin module declares `:decision_predictor` but registry instead declares `:executive_scheduler` and omits its actual predictor edge.  
**Impact:** Boot order and dependency-failure propagation are computed from a graph that does not represent the dependencies declared by the services themselves. Services can be started before required dependencies, and a dependency failure can fail to block a dependent. The registry cannot currently be treated as a correct executable dependency authority.

### RL-226 — Active registry includes explicitly unvalidated Phase 4 services
**Severity:** HIGH  
**Evidence:** The registry labels Tier 5 as "Phase 4 design specs (not yet validated)" but registers AutonomousResearchEngine and ExperimentOrchestrator with `deprecated: false`; DiscoverySupervisor is also active. Boot order/discover exclude only deprecated entries, not unvalidated or not-yet-certified services.  
**Impact:** Design-stage research/experiment services are eligible for normal boot and discovery despite the registry's own unvalidated designation. No explicit certification/readiness state prevents their capabilities from being presented as active.

### RL-227 — Registry health checks are not consistently aligned with the service's authoritative health API
**Severity:** HIGH  
**Evidence:** EventBus exposes both `healthy?/0` (a GenServer query) and `health/0` (process-presence check). The registry health_check is `{EventBus, :health, []}`, while the EventBus `:healthy` handler returns true unconditionally (previously noted in Checkpoint 18.21). This does not evaluate its degraded/persistence/delivery state. Other inspected service health functions frequently return healthy solely when the process is registered.  
**Impact:** Boot health gates can pass services whose underlying storage, event delivery or degraded state is unhealthy. Process liveness is being used as a proxy for service correctness.

### RL-228 — Service capability declarations are not tied to verified executable probes
**Severity:** HIGH  
**Evidence:** Registry `provides`/module `capabilities/0` are descriptive atom lists. BootSequencer's capability gate only rejects modules explicitly marked with `__tiannara_stub__/0`; its independent corroboration probe treats most advertised capabilities as `:unverified` and only has a specialized probe for `:deterministic_replay`. A service can therefore pass the capability gate without every advertised capability being exercised.  
**Impact:** Capability declarations can be counted as available despite no proof that their advertised operations are callable, correctly wired, or semantically effective. Registry capability coverage is not an executable capability certification.

### RL-229 — BootSequencer's dependency gate does not independently validate the dependency graph per service
**Severity:** HIGH  
**Evidence:** `run_gates/5` invokes `run_gate(:dependency, ..., fn -> :pass end)`; actual dependency handling is a separate `deps_ok` check against `failed_critical` before the gate sequence. That check uses registry `depends_on` only and considers only failed-critical services; it does not verify prerequisite process liveness/health at the moment of dependent startup, nor compare registry dependencies with module declarations. Degraded prerequisites are not added to `failed_critical` (RL-178).  
**Impact:** A recorded dependency gate pass does not establish that actual dependencies are running and healthy. The boot report can overstate dependency integrity.

### RL-230 — ServiceRegistry accepts structurally invalid service specifications
**Severity:** HIGH  
**Evidence:** `register/1` checks only whether the ID already exists before inserting the supplied term; it does not validate required keys/types, module loading, health/score MFA exports, dependency existence, capability schema, criticality or version. `replace/2` does not check that the old ID exists and can insert a new spec while creating/overwriting state entries without validation.  
**Impact:** Runtime registry mutation can introduce malformed or unbootable specs and broken dependency graphs. This compounds RL-172's missing governance/durable authorization: the registry is neither structurally validated nor governed at the mutation boundary.

### RL-231 — Registry mutation and boot inventory are volatile
**Severity:** HIGH  
**Evidence:** ServiceRegistry initializes from `canonical_services/0` on every start and holds runtime register/deprecate/replace changes only in GenServer state. No durable versioned registry snapshot or replay/reconciliation path is present in the inspected module.  
**Impact:** Runtime registry changes disappear on restart; the system cannot demonstrate a durable, auditable history of which service inventory and dependency graph governed a particular boot.

**Checkpoint disposition:** 7 findings added (RL-225–RL-231). No finding is closed. No remediation was performed. This checkpoint completes the initial 33-entry CEL registry reconciliation at the declaration/boot-contract level only; it does not certify that all 33 service implementations, callers, startup paths and runtime behavior have been exhaustively audited. Continue by auditing the remaining world, knowledge, evidence, research and discovery services individually, then reconcile CEL end-to-end before beginning ToolForge.


## Checkpoint 18.27 — Knowledge coordination, conflict resolution, evidence and epistemic integrity

**Source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** ConflictResolutionEngine, ConflictDetector, KnowledgeCoordinator, KnowledgeFlowEngine, KnowledgeEvolutionEngine, EvidenceValidator, EpistemicIntegrityService.  
**Method/status:** Static source inspection only. No runtime event-flow tests, evidence authenticity tests, conflict-resolution exercises, or scheduled evolution runs were performed.

### RL-232 — ConflictDetector's entity event path is a no-op
**Severity:** HIGH  
**Evidence:** Both `world.entity.created` and `world.entity.updated` handlers call `detect_conflicts_for_entity/1`; that function unconditionally returns `[]`.  
**Impact:** The advertised immediate per-entity contradiction/duplicate/ontology/confidence detection does not occur through those event handlers. Only the separate periodic/manual full sweep can detect the limited cases implemented there.

### RL-233 — ConflictDetector's logical contradiction detection only recognizes pre-existing refutation edges
**Severity:** HIGH  
**Evidence:** `detect_logical_contradictions/1` enumerates knowledge entities and looks for outgoing relationships of type `:refutes`; it does not independently reason over propositions, predicates, evidence or semantic incompatibility. The detector's event path does not derive new contradictions.  
**Impact:** The capability name overstates the implementation: it detects explicit refutation links, not general logical contradictions.

### RL-234 — ConflictDetector can report successful detection when conflict persistence fails
**Severity:** HIGH  
**Evidence:** The periodic `:detect_all` path catches exits from ConflictResolutionEngine.record_conflict/1 but still increments `total_conflicts_detected` and `unresolved_conflicts` by the number found. Event handlers do not consistently catch or reconcile failed writes.  
**Impact:** Detection counters can report conflicts that were never durably recorded or escalated. Detection and persisted conflict state are not transactionally reconciled.

### RL-235 — ConflictResolutionEngine can close a conflict while human review is only pending
**Severity:** CRITICAL  
**Evidence:** `apply_resolution(conflict, :request_human_review)` enqueues a HumanApprovalQueue item and returns a resolution record with `resolved_by: :human_pending`; the caller then unconditionally changes the conflict status to `:resolved`. No approval decision is retrieved or verified.  
**Impact:** A conflict requiring human arbitration can be represented as resolved before a human has reviewed or decided it. This undermines human authority and epistemic conflict governance.

### RL-236 — ConflictResolutionEngine conflict resolution can partially commit world and conflict state
**Severity:** CRITICAL  
**Evidence:** `record_conflict` writes the DETS conflict record before creating the contradiction entity; failure to create the entity returns an error but leaves the conflict record. On resolution, the service updates the DETS record and then calls UnifiedWorldModel.update_entity, ExecutiveMemory.record_decision and EventBus.publish without checking their results.  
**Impact:** Conflict status, contradiction entity, audit history and events can diverge. A resolved conflict may have no corresponding world-state mutation or durable decision evidence.

### RL-237 — ConflictResolutionEngine conflict detection treats missing entities as a measurement discrepancy
**Severity:** HIGH  
**Evidence:** `detect_conflict/2` maps any failure to retrieve either entity into `{:ok, %{conflict_type: :measurement_discrepancy,...}}`. When both entities exist, same-domain or missing-domain pairs are also classified as measurement discrepancies without comparing measurements.  
**Impact:** Missing entities and unexamined entity pairs can be presented as detected measurement conflicts; the result is not evidence of an actual discrepancy.

### RL-238 — ConflictResolutionEngine confidence-weighted resolution is advisory and does not resolve or mutate the conflict
**Severity:** HIGH  
**Evidence:** `resolve_entities/3` with `:confidence_weighted` returns a winner/loser proposal but does not update/refute entities, persist a resolution, or change conflict status. The `:merge` branch defaults missing entity confidence to 0.5, uses the maximum confidence rather than evidence fusion, and pattern-matches successful entity creation.  
**Impact:** API semantics do not clearly distinguish a proposed resolution from a committed one; merge can fabricate confidence and may crash on a failed create.

### RL-239 — ConflictResolutionEngine retention pruning deletes resolved conflict records without archive proof
**Severity:** HIGH  
**Evidence:** `prune/0` deletes resolved DETS records older than the retention cutoff directly. It does not require an immutable archive receipt, replay proof, or confirmation that associated world entities and decision records remain retrievable.  
**Impact:** Conflict history can be removed without demonstrated audit continuity.

### RL-240 — KnowledgeCoordinator duplicate detection is not implemented
**Severity:** HIGH  
**Evidence:** `find_similar_entities/1` unconditionally returns `:unique`. The ingestion path therefore never searches for semantic or structural duplicates and always attempts a new entity when invoked.  
**Impact:** The advertised duplicate elimination/evidence fusion behavior is not implemented in the ingestion path; duplicate knowledge can proliferate.

### RL-241 — KnowledgeCoordinator evidence fusion accepts unverified evidence and caller-controlled weights
**Severity:** CRITICAL  
**Evidence:** `fuse_evidence_internal/3` averages `confidence` fields supplied in evidence terms and combines that average with caller-supplied `weight`; it clamps the result but does not authenticate sources, verify signatures, validate evidence schema, deduplicate evidence, establish independence, or prevent correlated/repeated evidence from increasing confidence. It ignores the result of UnifiedWorldModel.update_entity and EvidenceValidator.validate_entity_evidence.  
**Impact:** Repeated, correlated, fabricated or caller-weighted evidence can raise confidence without demonstrated evidentiary independence or successful persistence/validation.

### RL-242 — KnowledgeCoordinator permits high-impact promotion using caller-supplied boolean approval
**Severity:** CRITICAL  
**Evidence:** Promotion to principle/generalized understanding/scientific discovery proceeds when `context.human_approved == true` or impact level defaults to `:low`. The service does not verify an approval record, reviewer identity, signature, approval scope, artifact hash or Council decision.  
**Impact:** A caller can self-assert human approval or omit impact metadata to pass the high-impact promotion gate.

### RL-243 — KnowledgeCoordinator validation orchestration does not itself verify the validation outcome
**Severity:** HIGH  
**Evidence:** `validate_knowledge/2` constructs a WorkflowEngine workflow with a Validation step and returns the workflow ID when WorkflowEngine accepts it. It does not await or consume the eventual validation result, bind a validated evidence artifact to the entity, or update a validated-knowledge count on successful completion.  
**Impact:** Workflow admission can be mistaken for completed knowledge validation; the coordinator does not establish the validation postcondition.

### RL-244 — KnowledgeCoordinator statistics and certification evidence are not durable or reconciled
**Severity:** MEDIUM  
**Evidence:** Knowledge item/validated/pending/principle counters are in-memory and initialized to zero. Ingestion increments total items, but there is no demonstrated durable reconstruction or consistent validated counter update. Discovery certification records a decision/event best-effort and returns the certifier report without persisting a versioned certification artifact in this service.  
**Impact:** Coordinator metrics reset on restart and do not provide a reliable inventory of accepted, validated or certified knowledge.

### RL-245 — KnowledgeFlowEngine reports propagation success for destinations that are not actually updated
**Severity:** CRITICAL  
**Evidence:** `propagate_to_domain/2` returns `{:ok, :executive_memory}`, `{:ok, :unified_world_model}` and `{:ok, :governance}` without performing a write or governance operation. Other destination branches call EventBus.publish but ignore its return value and then return success. The CCI impact and engineering application outputs are fixed examples.  
**Impact:** Propagation ledger can claim targets were reached when no operation occurred or publication failed. Cross-domain knowledge delivery metrics are not evidence of actual integration.

### RL-246 — KnowledgeFlowEngine propagation ledger and counters are volatile
**Severity:** HIGH  
**Evidence:** `propagation_ledger`, total and propagated counters are held in GenServer state and initialized empty; no durable reload/reconciliation is present.  
**Impact:** Restart erases propagation history and makes stagnation detection and coverage metrics incomplete.

### RL-247 — KnowledgeEvolutionEngine scheduled evolution functions are no-ops
**Severity:** CRITICAL  
**Evidence:** `decay_stale_knowledge/0`, `promote_emerging_patterns/0` and `merge_duplicates/0` all return `:ok` without performing work. The periodic and manual evolve paths nevertheless increment `evolutions_processed`.  
**Impact:** The service reports completed evolution cycles without aging, confidence decay, pattern promotion or duplicate merging.

### RL-248 — KnowledgeEvolutionEngine promotes entities using arbitrary supplied evidence and fixed confidence increments
**Severity:** HIGH  
**Evidence:** `promote_entity/2` accepts any `new_evidence` term, advances exactly one stage and adds 0.1 to confidence without invoking EvidenceValidator, checking evidence quality/independence, or requiring stage-specific criteria. It ignores the result of UnifiedWorldModel.update_entity before returning success.  
**Impact:** Knowledge maturity and confidence can be increased without evidence-backed stage criteria or confirmed world-state persistence.

### RL-249 — KnowledgeEvolutionEngine retirement acknowledges refutation without checking mutation result
**Severity:** HIGH  
**Evidence:** `retire_entity/2` calls UnifiedWorldModel.refute_entity/2 and records a decision, but ignores the mutation result and returns `:ok`; counters are incremented regardless.  
**Impact:** The service can report knowledge retired when the canonical entity was not successfully refuted.

### RL-250 — EvidenceValidator does not validate evidence authenticity or independence
**Severity:** CRITICAL  
**Evidence:** `validate_entity_evidence_internal/1` reconstructs lineage and counts evidence terms. For high-confidence entities it only rejects zero evidence; it does not verify source identity, signatures, source reliability, timestamp integrity, independence, experiment execution, raw data, reproducibility or falsification. The declared `@min_evidence_for_high_confidence 2` is not used in the decision.  
**Impact:** A high-confidence entity with one arbitrary evidence item can pass this check; the validator establishes evidence presence, not evidence validity.

### RL-251 — EvidenceValidator treats missing provenance as acceptable for lower-confidence entities
**Severity:** HIGH  
**Evidence:** When ProvenanceEngine reconstruction fails, entities below the 0.8 threshold return `{:ok, :valid}`.  
**Impact:** The service's broad provenance-verification claim is not enforced for all entities; missing provenance can be silently treated as valid rather than unknown/invalid.

### RL-252 — EvidenceValidator violation state is volatile and scheduled validation can crash on query failure
**Severity:** HIGH  
**Evidence:** Active violations and validation counters exist only in GenServer state. The sweep pattern-matches `{:ok, result} = WorldQueryEngine.find(...)` and scheduled handler destructures the result of `handle_call/3`; query errors or unexpected return shapes can crash the service.  
**Impact:** Restart loses unresolved violation records; a world-query failure can terminate validation rather than producing an explicit degraded/unknown result.

### RL-253 — EpistemicIntegrityService assigns ideal integrity scores to empty datasets
**Severity:** HIGH  
**Evidence:** Empty knowledge-entity sets yield evidence quality 1.0; empty world sets yield provenance completeness 1.0; no active theories yield stale-theory rate 0.0. Initial state uses the same ideal defaults before any check has run.  
**Impact:** No observations can be represented as perfect epistemic integrity instead of unknown/no-data, creating false assurance.

### RL-254 — EpistemicIntegrityService checks only bounded samples and does not expose truncation
**Severity:** HIGH  
**Evidence:** Entity and theory queries use limits of 10,000 and 100,000 without pagination or a completeness indicator. Completeness and quality ratios are calculated over returned results only.  
**Impact:** Large knowledge bases can be partially sampled while reports appear to describe the full corpus; integrity metrics may miss violations beyond the query limit.

### RL-255 — EpistemicIntegrityService report generation is not fail-safe or durably versioned
**Severity:** HIGH  
**Evidence:** `run_integrity_check/0` pattern-matches expected success from ConflictDetector.stats and WorldQueryEngine.find; no error-to-unknown handling exists. State is volatile and ExecutiveMemory.record_decision result is ignored.  
**Impact:** Query errors can crash the service; completed reports are not shown to be durably versioned or independently reproducible.

**Checkpoint disposition:** 24 findings added (RL-232–RL-255). No finding is closed. No remediation was performed. Continue with AutonomousResearchEngine, ExperimentOrchestrator and DiscoverySupervisor, then reconcile all CEL service callers, startup, governance and evidence flow.


## Checkpoint 18.28 — Autonomous research, experiment orchestration and discovery subsystem

**Source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** AutonomousResearchEngine, ExperimentOrchestrator, RealExecution, RealHarness, DiscoverySupervisor, DiscoveryEngine, DiscoveryScheduler, DiscoveryMetrics and the Observation/Experiment/Validation workflow steps.  
**Method/status:** Static source inspection only. No sandbox execution, discovery cycle, real experiment, authorization-grant integration test, or persistence/recovery test was run.

### RL-256 — AutonomousResearchEngine generates generic hypothesis templates rather than evidence-derived hypotheses
**Severity:** CRITICAL  
**Evidence:** `generate_hypotheses/2` maps recommendation types to fixed generic statements (e.g. a targeted experiment, replication experiment, or new observational test). It does not derive variables, competing hypotheses, predicted outcomes, controls, falsification criteria or a testable model from source evidence.  
**Impact:** The advertised autonomous hypothesis-generation capability is not demonstrated as a research reasoning pipeline; it creates templated prompts for downstream workflow dispatch.

### RL-257 — AutonomousResearchEngine dispatches workflow steps whose real providers are explicitly unavailable
**Severity:** CRITICAL  
**Evidence:** Its validation workflow uses `Tiannara.CEL.Workflow.Steps.Observation`, `Experiment` and `Validation`. At the frozen baseline, each step's `execute/2` explicitly returns `{:error, {:unavailable, :real_step_provider_not_wired}}`.  
**Impact:** The default autonomous research path cannot perform the advertised observation, experiment or validation work through these steps. A workflow being created/dispatched is not evidence of research execution.

### RL-258 — AutonomousResearchEngine program and hypothesis lifecycle is volatile and incompletely closed
**Severity:** HIGH  
**Evidence:** Active programs, hypotheses, workflow IDs and counters live only in GenServer state; no durable reload/reconciliation is present. Completion updates a program status but does not remove it from `active_programs`; a program with failed workflow dispatches can remain active without a terminal failure.  
**Impact:** Restart loses research lifecycle state, completed programs can consume the concurrency limit indefinitely, and failed/undispatched validation can leave programs unresolved.

### RL-259 — AutonomousResearchEngine ingests workflow completion as research evidence without verifying the workflow result
**Severity:** CRITICAL  
**Evidence:** Completion handling reads caller/event payload `outcome_evidence` and `final_confidence`, builds an experimental-result entity and calls KnowledgeCoordinator.ingest_discovery/1. It does not independently retrieve the workflow's persisted step results, verify that real observation/experiment/validation occurred, or verify evidence provenance before ingestion; the ingestion result is ignored.  
**Impact:** Event payload claims can be promoted into knowledge without an independently verified execution record. A completion event alone is treated as sufficient evidence of a completed validation program.

### RL-260 — ExperimentOrchestrator's public submission path bypasses its declared experiment lifecycle gates
**Severity:** HIGH  
**Evidence:** `submit_experiment/1` checks `real_execution_enabled` then directly calls `RealExecution.execute/1`. The handler does not invoke the module's `check_concurrent_limit/1`, `check_constitutional_gate/2`, resource estimation/admission, environment selection, experiment-entity creation, or workflow-dispatch lifecycle. These helper paths are separate from the public real-execution gateway.  
**Impact:** The advertised concurrency, resource-aware scheduling and constitutional gating capabilities are not demonstrated on the actual public submission path. The real-execution grant gate remains present, but it is not equivalent to all declared orchestration controls.

### RL-261 — RealExecution returns an accepted execution result even when RealHarness verdict is failure
**Severity:** CRITICAL  
**Evidence:** RealHarness returns `{:ok, %Result{verdict: {:fail, ...}}` when tests fail or benchmark regression occurs. RealExecution's `{:ok, sandbox_result}` branch builds verification and proceeds to return `{:ok, ...}` without requiring `verification.verdict == :pass`.  
**Impact:** A failed test/benchmark run can be represented by the public execution API as a successful execution call. Callers must inspect the nested verdict; the top-level success tuple is not a pass/certification signal.

### RL-262 — RealExecution can report success after execution-ledger persistence failure
**Severity:** HIGH  
**Evidence:** `record_execution/3` rescues filesystem/JSON errors, logs them and returns normally. The caller ignores the return value from `close_execution/...`; lifecycle close failure is only logged. Executive EventStore append is best-effort.  
**Impact:** The execution path can return success without a confirmed durable execution ledger append or terminal provenance lifecycle record, contrary to the module's stated always-persistent ledger contract.

### RL-263 — RealExecution substitutes unknown provenance when canonical provenance construction fails
**Severity:** HIGH  
**Evidence:** `build_provenance/2` returns `Provenance.unknown(...)` if Provenance.build fails, but the caller does not reject that result before returning the execution as successful.  
**Impact:** An execution can be returned without a valid canonical `:real_execution` provenance record; the presence of a provenance-shaped value is not proof of valid lineage.

### RL-264 — ExperimentOrchestrator stores real execution records only in volatile process state
**Severity:** HIGH  
**Evidence:** The real submission handler writes a completed experiment map into `state.experiments` and increments counters; no DETS/database reload, durable experiment record, or recovery scan is present in the inspected module.  
**Impact:** Experiment history, results and counts disappear on process restart even though RealExecution may have a separate execution ledger. The orchestrator cannot reconstruct its own lifecycle from that ledger in the inspected path.

### RL-265 — ExperimentOrchestrator result aggregation assumes fields not present in its real-execution result shape
**Severity:** HIGH  
**Evidence:** The public real-execution path stores `result: %{execution_id: ..., verification: ...}` and `eig: nil`. `aggregate_results/1` expects result fields `confidence` and `findings`, and reads EIG as a numeric value; absent confidence/findings default to zero/empty.  
**Impact:** Aggregation of records created through the actual public submission path discards verification details and reports zero confidence/EIG rather than aggregating the real sandbox evidence.

### RL-266 — ExperimentOrchestrator does not require a passing verification verdict before marking an experiment completed
**Severity:** CRITICAL  
**Evidence:** On any `{:ok, %{execution_id: ..., verification: verification}}` from RealExecution, the handler sets status `:completed` and increments completed_experiments. RL-261 establishes that RealExecution returns `:ok` even when the nested RealHarness verdict is `{:fail, ...}`.  
**Impact:** Failed tests or benchmark regressions can be counted as completed experiments and exposed as successful lifecycle outcomes.

### RL-267 — DiscoveryEngine stores discoveries and evidence only in volatile memory
**Severity:** HIGH  
**Evidence:** DiscoveryEngine initializes `discoveries: %{}`, `active_workflows: %{}` and stats in GenServer state; create/route evidence mutate only this state. No durable persistence or restart reconstruction is present in the inspected engine.  
**Impact:** Discovery objects, evidence collections and workflow associations are lost on restart; the discovery engine cannot provide durable discovery lineage from its own store.

### RL-268 — DiscoveryEngine route_evidence reports an integrity result without enforcing it
**Severity:** HIGH  
**Evidence:** `route_evidence/2` integrates supplied results, adds them to the discovery, calls DiscoveryLineage.verify_integrity(updated), and returns the integrity value. It does not reject or quarantine the updated discovery when integrity verification fails.  
**Impact:** Evidence can be retained/routed despite a failed lineage integrity check; integrity is diagnostic output rather than a mandatory gate.

### RL-269 — DiscoveryScheduler uses bounded live-world scans and converts source failures into empty evidence
**Severity:** HIGH  
**Evidence:** `fetch_world_entities/0` limits graph scan to 500 entities and returns `[]` if UnifiedRealityGraph is absent, query fails, or retrieval errors occur. Integrity report converts an empty entity list into all-zero/empty measures; active-conflict report marks analysis incomplete but does not fail the cycle.  
**Impact:** Partial or unavailable world data can be treated as an empty discovery surface. The scheduler does not demonstrate full-corpus coverage or a hard stop when source coverage is unavailable.

### RL-270 — DiscoveryScheduler's cycle completion and dispatch counters do not establish successful experiment execution
**Severity:** HIGH  
**Evidence:** The scheduler increments `total_experiments_executed` by `length(dispatched)` where dispatched entries are workflow IDs accepted by WorkflowEngine. It runs a DiscoveryQualityAssessor and logs non-pass recommendations, but does not gate cycle completion or undo dispatch for failed QA.  
**Impact:** Workflow admission is counted as experiment execution; quality failures are warnings rather than enforced certification barriers.

### RL-271 — DiscoveryScheduler marks workflow dispatch separately from real experiment execution and does not prove an execution backend
**Severity:** HIGH  
**Evidence:** The scheduler dispatches ExperimentStep and ValidationStep workflows. The inspected default CEL Observation/Experiment/Validation steps explicitly return unavailable; discovery-specific ExperimentStep/ValidationStep are separate modules and require their own provider/runtime verification. The scheduler's accepted workflow ID is treated as dispatch success.  
**Impact:** Discovery workflow dispatch is not proof that the selected experiment ran against a real instrument/sandbox or that validation was performed. Discovery-specific steps must be audited independently before any execution claim.

### RL-272 — DiscoveryMetrics uses volatile counters and misleading no-data health defaults
**Severity:** MEDIUM  
**Evidence:** All metrics are in-memory and reset on init. `get_health_score` sets completion rate to 1.0 when no discoveries were initiated; summary uses zero completion rate but still assigns success rate 0.5 when there are no outcomes.  
**Impact:** Restart erases discovery metrics, and health score can appear favorable with no discovery activity or outcome evidence.

### RL-273 — DiscoverySupervisor health reflects child process presence, not child operational readiness
**Severity:** HIGH  
**Evidence:** `health/0` checks only whether DiscoveryEngine, DiscoveryScheduler and DiscoveryMetrics processes are registered. It does not call each child's own health/constitutional score or verify dependencies, event subscriptions, persistence, provider availability or discovery-cycle success.  
**Impact:** The supervisor can report healthy when children are alive but operationally unable to perform discovery or preserve evidence.

**Checkpoint disposition:** 18 findings added (RL-256–RL-273). No finding is closed. No remediation was performed. Continue with DiscoveryScheduler's complete stage implementations, discovery step providers, discovery certification/quality/provenance components and remaining registered world/knowledge modules; then complete the CEL-wide runtime/caller/readiness matrix before ToolForge.


## Checkpoint 18.29 — Discovery step providers, hypothesis generation, certification and lineage validation

**Source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** Discovery ExperimentStep/ValidationStep, HypothesisGenerator, EvidenceIntegrator, DiscoveryCertifier, StatisticalValidator, ReplicationPlanner, EvidenceAuditor, DiscoveryQualityAssessor and its detectors, DiscoveryLineage.  
**Method/status:** Static source inspection only. No statistical simulation/calibration, independent replication, step-provider execution, lineage tampering test or certification test suite was run.

### RL-274 — Discovery hypothesis generation is template substitution, not evidence-driven hypothesis construction
**Severity:** HIGH  
**Evidence:** `HypothesisGenerator.generate/2` selects fixed per-domain string templates and substitutes the KnowledgeGap description. Hypothesis records are created with empty evidence and predictions, zero confidence, and no derived variables, operational definitions, predicted observations, competing models or falsification protocol.  
**Impact:** The generator provides candidate wording but does not establish autonomous scientific hypothesis generation or evidence-grounded model construction.

### RL-275 — Discovery ExperimentStep interprets two stored values as a general experiment
**Severity:** HIGH  
**Evidence:** `Discovery.Steps.ExperimentStep.execute/2` reads two entity attribute values and calculates absolute numeric difference (or 0/1 equality for non-numeric values). It classifies divergence above tolerance as `:confirmed` and divergence within tolerance as `:refuted`; it does not execute an experimental intervention, control variables, collect instrument measurements, or compare against a preregistered prediction.  
**Impact:** The step is a two-value comparison primitive, not a general experiment executor. Its outcome labels can be misinterpreted as hypothesis confirmation/refutation without a defined experimental model.

### RL-276 — Discovery ExperimentStep converts missing observations into inconclusive output without failing source integrity
**Severity:** HIGH  
**Evidence:** `read_value/1` returns nil on missing entity, missing value, lookup error or exception; `compute_divergence/2` then returns nil and the step emits an inconclusive evidence record. The step still returns `{:ok, ...}` and publishes evidence events.  
**Impact:** Missing or unavailable observation sources can be represented as a successful step with inconclusive evidence, without a structured source-coverage failure or explicit distinction between missing data and a genuine inconclusive measurement.

### RL-277 — Discovery ValidationStep performs threshold classification, not independent validation
**Severity:** CRITICAL  
**Evidence:** `ValidationStep.execute/2` reads an upstream evidence map and checks whether its outcome is decisive and confidence exceeds a caller-provided/default threshold. It does not rerun the experiment, inspect raw measurements, verify provenance/signatures, perform replication, or independently recompute the result. Missing evidence produces an `:inconclusive` output inside a successful `{:ok,...}` step result.  
**Impact:** A confidence threshold is treated as validation. The step does not provide independent scientific verification and can promote upstream claims without validating their source.

### RL-278 — Discovery ValidationStep does not enforce a trusted evidence schema or promotion policy
**Severity:** HIGH  
**Evidence:** The step accepts any map and trusts supplied `:outcome` and `:confidence` fields; `promotion_threshold` is caller-controlled and defaults to 0.5. It does not verify evidence identity, lineage hash, source, experiment authorization, replication count, or a ratified threshold.  
**Impact:** Callers can influence whether evidence is labelled promotable by choosing the payload and threshold; the validation outcome is not a governed certification decision.

### RL-279 — Discovery EvidenceIntegrator integration path does not validate incoming result records
**Severity:** HIGH  
**Evidence:** `DiscoveryEngine.route_evidence/2` converts terms into DiscoveryResult structs and calls `EvidenceIntegrator.integrate/2`; it does not call `validate_evidence/1` or `validate_result/1`. The integrator groups and aggregates fields directly.  
**Impact:** Malformed, incomplete or semantically invalid result records can enter discovery evidence aggregation without the module's own validation API being applied.

### RL-280 — Discovery evidence aggregation does not establish independent source authenticity or experimental independence
**Severity:** HIGH  
**Evidence:** `EvidenceIntegrator.integrate/2` groups by experiment ID, concatenates evidence terms and sums confidence deltas. `evaluate_evidence/2` classifies based on supplied outcome/delta. No source authentication, evidence deduplication, correlation analysis or experiment execution proof is performed.  
**Impact:** Aggregated outcomes and confidence changes can reflect duplicated/correlated or unauthenticated input rather than independent observations.

### RL-281 — StatisticalValidator's p-value and power are heuristic scores, not statistical tests
**Severity:** CRITICAL  
**Evidence:** `compute_p_value/1` derives p from the fraction of `:confirmed` outcomes and discovery confidence (`max(0.001, 1.0 - consistency * confidence)`). `compute_power/2` uses a fixed exponential function of evidence count and heuristic effect size. No null distribution, test statistic, sampling model, variance assumptions, preregistered test or sample-size design is used.  
**Impact:** Certification can report statistical significance and sufficient power without a statistically valid inferential test. A numeric p-value/power from this implementation must not be treated as scientific statistical evidence.

### RL-282 — ReplicationPlanner counts evidence labels rather than completed independent replications
**Severity:** CRITICAL  
**Evidence:** `plan/1` generates proposed replication descriptions; it does not dispatch or execute them. `sufficiently_replicated?/1` counts evidence records containing an item with `type: :replication`, without verifying distinct experiment IDs, independent data/source, different methodology, or completed replication workflows. Certification then reports replication_count as a hard-coded 2 when this boolean passes.  
**Impact:** Two caller-labelled replication evidence items can satisfy the replication gate without two independent completed replications.

### RL-283 — DiscoveryCertifier can certify using heuristic statistical and replication evidence
**Severity:** CRITICAL  
**Evidence:** `DiscoveryCertifier.validate/1` combines the StatisticalValidator heuristic, ReplicationPlanner boolean, EvidenceAuditor score and QA score. It treats statistical significance/power and replication sufficiency as authoritative inputs; it does not require a separately authenticated execution/replication registry or an external statistical validation artifact.  
**Impact:** A discovery may receive `:certified` based on heuristic p-value/power and evidence labels rather than verified independent experimental replication and valid statistical inference.

### RL-284 — DiscoveryCertifier assigns long certification expiry without ongoing evidence refresh
**Severity:** HIGH  
**Evidence:** Certified discoveries receive a fixed five-year expiry and provisional discoveries one year. The inspected certifier does not define a periodic recertification mechanism tied to new evidence, source changes, retractions or model drift.  
**Impact:** Certification can remain represented as valid for years despite changing evidence or later refutation, absent an external expiry/revocation mechanism.

### RL-285 — EvidenceAuditor's source-diversity and independence checks trust caller-supplied labels
**Severity:** HIGH  
**Evidence:** Source diversity counts unique `source` values in evidence maps; independence counts unique experiment IDs. It does not authenticate sources, identify common upstream datasets/actors, verify actual separate execution, or detect shared instrumentation/analysis.  
**Impact:** Different labels/IDs can be counted as independent evidence without proving source diversity or independence.

### RL-286 — DiscoveryQualityAssessor's quality checks are structural heuristics, not proof of scientific validity
**Severity:** HIGH  
**Evidence:** Completeness checks whether pipeline lists are nonempty; falsifiability checks a boolean field; reproducibility checks whether criteria fields are populated. Confirmation-bias, circular-reasoning and anomaly detectors inspect a narrow set of map fields and metadata.  
**Impact:** A discovery can receive high QA scores from populated fields and self-declared flags without verified experimental design, execution, preregistration, raw data, replication or independent review.

### RL-287 — DiscoveryLineage integrity hash is not a content-bound tamper-evident chain
**Severity:** HIGH  
**Evidence:** `calculate_integrity_hash/1` hashes only each lineage event name and inspected timestamp joined into a string. It does not bind event payloads, evidence hashes, parent hash, actor identity, signatures or canonical discovery state. `verify_integrity/1` checks nonempty lineage, terminal event and timestamp ordering only.  
**Impact:** Material changes to discovery content/evidence can leave the lineage hash unchanged; the integrity result does not establish tamper-evident provenance.

### RL-288 — Discovery certification is not persisted as a durable signed artifact by KnowledgeCoordinator
**Severity:** HIGH  
**Evidence:** KnowledgeCoordinator invokes DiscoveryCertifier, records a best-effort ExecutiveMemory decision and publishes an event, but does not store the complete ValidationReport/Certification with immutable input hashes, validator version, evidence manifest, signature or revocation lineage.  
**Impact:** A certification response is not demonstrated as a durable, independently verifiable certificate bound to the exact discovery and evidence snapshot.

**Checkpoint disposition:** 15 findings added (RL-274–RL-288). No finding is closed. No remediation was performed. Continue the remaining registered service audit (world graph/model/mutation/provenance/version/snapshot/replay and knowledge/evidence services not already covered), then perform caller and boot-path reconciliation. ToolForge remains deferred until CEL is fully audited.


## Checkpoint 18.30 — Ontology, provenance and world-query service audit

**Source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** OntologyManager, ProvenanceEngine, WorldQueryEngine and CanonicalWorldState schema.  
**Method/status:** Static source inspection only. No DETS restart test, mutation failure injection, schema property test, query completeness test or provenance forgery test was run.

### RL-289 — OntologyManager opens durable storage but does not restore concepts or mappings into memory
**Severity:** CRITICAL  
**Evidence:** On successful DETS open, `init/1` initializes `concepts: %{}`, `mappings: %{}` and all counters to zero. It does not traverse/load existing `:concept` and `:mapping` records. All read APIs use the in-memory maps.  
**Impact:** Concepts/mappings written to DETS become invisible to active_concepts, semantic_lineage, cross_domain_mappings and merge/split/retire operations after restart. The service has a persistence file but does not recover its operational ontology state.

### RL-290 — OntologyManager acknowledges mutations without checking durable or canonical world writes
**Severity:** CRITICAL  
**Evidence:** Define/merge/split/retire handlers ignore return values from DETS writes, UnifiedWorldModel operations, WorldMutationEngine.mutate, ExecutiveMemory.record_decision and EventBus.publish. Multi-record operations write several DETS records sequentially without transaction/rollback.  
**Impact:** Ontology state, canonical world state, mutation history, audit records and events can diverge while the API returns success. Partial merge/split operations can leave inconsistent concept graphs.

### RL-291 — OntologyManager concept definition and mapping accept unverified caller-supplied semantics
**Severity:** HIGH  
**Evidence:** `define_concept/1` stores caller-provided name/domain/definition/parent IDs/provenance without schema validation or verifying parent existence. `map_concepts/3` does not verify either concept exists and accepts caller-supplied mapping type, confidence, evidence and provenance without validation.  
**Impact:** Invalid concepts, dangling parent references and mappings to nonexistent concepts can be recorded as valid ontology state. Confidence/provenance are declarations rather than verified evidence.

### RL-292 — OntologyManager concept merges and splits mutate ontology without a governed approval gate
**Severity:** HIGH  
**Evidence:** Merge/split/retire handlers directly mutate DETS and call WorldMutationEngine; no Council authorization, human approval, signed change proposal, impact assessment or immutable approval reference is checked in the inspected handlers.  
**Impact:** Structural changes to Tiannara's concept ontology are not shown to be subject to the project's required governance boundary.

### RL-293 — OntologyManager merge/split/retire can lose cross-store consistency
**Severity:** HIGH  
**Evidence:** Merge creates merged concept and deprecates both sources in DETS before the world mutation call; split writes all child concepts and deprecates source before mutation; retire writes the retired record before mutation. Mutation results are ignored, and merge/split/retire do not update or verify corresponding canonical world entities consistently.  
**Impact:** The DETS ontology and canonical world graph can disagree about active concepts, lineage and successor relationships.

### RL-294 — ProvenanceEngine is volatile despite advertising persistent lineage tracking
**Severity:** CRITICAL  
**Evidence:** `ProvenanceEngine.init/1` initializes `records: %{}`; record/reconstruct/verify operate only on that map. No DETS/database reload or durable provenance record is present. ExecutiveMemory/EventBus calls are side effects, not used to reconstruct records.  
**Impact:** Provenance records disappear on restart, so evidence lineage and confidence paths are not a durable source of truth.

### RL-295 — ProvenanceEngine record operation accepts unverified provenance and overwrites prior entity lineage
**Severity:** CRITICAL  
**Evidence:** `record_provenance/1` accepts caller-supplied entity ID, origin, contributors, evidence, confidence, uncertainty and owner without schema validation, source authentication, signatures or immutable versioning. `Map.put(state.records, entity_id, record)` replaces any previous record for that entity.  
**Impact:** Callers can overwrite lineage and evidence history or introduce fabricated contributor/evidence references. Provenance is mutable self-reported metadata, not a tamper-evident evidence chain.

### RL-296 — ProvenanceEngine verification checks only field presence and a one-sided confidence bound
**Severity:** HIGH  
**Evidence:** `verify_provenance/1` checks required keys and flags only when confidence + uncertainty > 1.01; it does not reject negative/out-of-range values, require sum near 1.0, resolve contributor existence, detect cycles, authenticate source records or verify content hashes/signatures.  
**Impact:** A provenance record can be labelled complete despite invalid numeric values, missing contributors or tampered evidence.

### RL-297 — ProvenanceEngine statistics read a nonexistent state field
**Severity:** MEDIUM  
**Evidence:** Initialization stores `total: 0`, while `:stats` returns `state.total_records`; that key is absent.  
**Impact:** The stats handler can raise a KeyError rather than returning a valid service report; health/constitutional scoring based on this service is not reliable.

### RL-298 — WorldQueryEngine silently truncates search and provides an incomplete total
**Severity:** HIGH  
**Evidence:** `search/2` calls `find(limit: 1000)`, filters that bounded result in memory and returns the number of matches in that truncated subset as `total_matches`. `find/1` queries the graph with `limit + offset`, then drops offset and returns `total: length(ids)`, which is not a total corpus count when results are limited.  
**Impact:** Search and query consumers can treat a partial page as a complete result set and receive misleading totals; no pagination cursor or completeness indicator is provided.

### RL-299 — WorldQueryEngine prediction/explanation outputs use fixed heuristics rather than validated causal evidence
**Severity:** MEDIUM  
**Evidence:** `predict/2` assigns impact using fixed entity-type constants multiplied by confidence and ignores the requested change_type in the impact calculation. `explain/1` falls back to "default prior" text when provenance is absent.  
**Impact:** These outputs are heuristic summaries, not calibrated predictions or complete causal explanations; consumers must not treat them as independent evidence.

### RL-300 — CanonicalWorldState schema is not shown to be enforced by every world write path
**Severity:** HIGH  
**Evidence:** CanonicalWorldState defines required fields, domain/type constraints and confidence/provenance checks, but the inspected schema module itself only exposes `validate_entity/1`; no universal write-boundary enforcement was demonstrated in the inspected OntologyManager, KnowledgeCoordinator, ProvenanceEngine or world mutation call paths. Several of those services construct entity maps and call downstream create/update functions while ignoring their results.  
**Impact:** A declared canonical schema does not guarantee every entity entering the world model satisfies it. End-to-end enforcement must be verified at the single canonical mutation boundary and across all writers.

**Checkpoint disposition:** 12 findings added (RL-289–RL-300). No finding is closed. No remediation was performed. Next: finish the remaining registry/world-service writer audit and perform caller-to-authority reconciliation; then compile the full CEL production-readiness matrix.


## Checkpoint 18.31 — CEL runtime boot, process ownership and recovery integration

**Source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** `Tiannara.CEL.Kernel`, `BootSequencer`, `Tiannara.Application`, `ControlCenter` integration and dynamic service lifecycle.  
**Method/status:** Static source inspection only. No application boot, child crash, repeated boot, restart authorization or shutdown exercise was run.

### RL-301 — CEL service children are temporary and are not automatically restarted after a crash
**Severity:** CRITICAL  
**Evidence:** Kernel `start_service/2` creates every registry child with `restart: :temporary` under DynamicSupervisor. The inspected Kernel has no automatic monitor/restart loop for unexpected service process exits; restart is an explicit `restart_service/2` call.  
**Impact:** A CEL service crash removes that service from the running system and it remains down until a separately authorized manual restart. One-for-one DynamicSupervisor strategy does not restart temporary children.

### RL-302 — BootSequencer leaves services running when health/constitution/capability/resource gates fail
**Severity:** CRITICAL  
**Evidence:** Kernel starter launches the service before BootSequencer runs health, constitutional, capability and resource gates. On a gate failure, BootSequencer records failed/degraded status but does not terminate the started child. Kernel `record_pids/2` only records entries whose final status is `:ok`; failed/degraded children are not added to the tracked service PID map.  
**Impact:** A service that fails its boot gate can remain alive and operationally untracked. It may continue handling calls despite not passing readiness, and Kernel halt/restart operations may not manage it.

### RL-303 — Kernel manual restart does not rerun boot readiness gates
**Severity:** HIGH  
**Evidence:** `do_restart/2` terminates the tracked old PID and invokes `start_service/2`, then logs success and updates the PID map. It does not rerun health, constitutional score, capability, resource or dependency gates.  
**Impact:** A restarted service is treated as restarted successfully based on child startup alone; the system does not establish that it has returned to a boot-ready state.

### RL-304 — Kernel restart authorization does not bind the supplied actor to the Council request
**Severity:** HIGH  
**Evidence:** `handle_call({:restart_service, id, actor},...)` calls `Council.authorize(:architectural_change, %{action: :restart, service: id}, nil)`; the supplied `actor` is not included in the authorization request.  
**Impact:** The restart API's actor argument is not bound to the authorization decision in the inspected path. Attribution and principal-specific authorization cannot be established from this call.

### RL-305 — Kernel boot report and process registry omit started-but-degraded/failed children
**Severity:** HIGH  
**Evidence:** BootSequencer's service result can be `:degraded` or `:failed` after the starter has already returned a PID. Kernel `record_pids/2` only records `:ok` results and does not retain the PID for those other statuses.  
**Impact:** Kernel's service_pid inventory does not represent every child it actually started; service lifecycle management and post-boot reconciliation are incomplete.

### RL-306 — Kernel halt only terminates tracked service PIDs
**Severity:** HIGH  
**Evidence:** `handle_call({:halt,...})` iterates `state.service_pids` and terminates those children. Started-but-untracked children from failed/degraded boot gates (RL-302/305) are not included.  
**Impact:** A requested executive shutdown can leave CEL service processes running after Kernel transitions to shutdown.

### RL-307 — Application root readiness is independent of production CEL readiness
**Severity:** HIGH  
**Evidence:** In production, Application.start/2 launches `boot_fn` through `Task.start/1` and immediately returns `{:ok, pid}` for the root supervisor. The task logs CEL boot errors but does not propagate them to application startup status. This overlaps RL-171 but is retained here as the runtime-readiness consequence.  
**Impact:** External process supervision/readiness checks can observe the Tiannara application as started while CEL is still booting, degraded or failed.

### RL-308 — ControlCenter constitutional audit inputs are hard-coded rather than collected from live governance evidence
**Severity:** HIGH  
**Evidence:** `ControlCenter.run_constitutional_audit/1` constructs `system_state` with fixed values including hidden uncertainty 0, mandatory reviews completed/required 0, lineage violations 0, safety violations 0, coupling violations 0, evolutions deployed 0, evolution validations 0 and objective alignment 0.9. It then passes this map to ConstitutionalAuditor.audit/1.  
**Impact:** The resulting audit can report compliance from synthetic/default inputs rather than a measured inventory of actual reviews, lineage, safety, coupling and evolution evidence. It cannot independently certify CEL readiness.

### RL-309 — ControlCenter treats module-only registration as healthy
**Severity:** MEDIUM  
**Evidence:** `start_subsystem/2` returns `{:ok, :module_only}` for modules without start_link/1; `subsystem_alive?/1` unconditionally returns true for `pid: :module_only`.  
**Impact:** A module's mere loadability/export surface is counted as a healthy running subsystem, which conflates code presence with operational readiness.

**Checkpoint disposition:** 9 findings added (RL-301–RL-309). No finding is closed. No remediation was performed. Continue with final cross-system CEL caller, supervision, storage and authority reconciliation, then build a complete per-service readiness classification. ToolForge remains deferred.


## Checkpoint 18.32 — Discovery pipeline analyzer and provider registration audit

**Source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** GapAnalyzer, ContradictionAnalyzer, DiscoveryPrioritizer and Discovery.Steps.ProviderSeeder.  
**Method/status:** Static source inspection only. No live discovery cycle, provider registration test, resource-budget execution test or contradiction corpus benchmark was run.

### RL-310 — GapAnalyzer defaults missing integrity inputs to optimistic values
**Severity:** HIGH  
**Evidence:** `analyze/1` reads contradiction rate defaulting to 0.0, evidence quality defaulting to 1.0, stale theory rate defaulting to 0.0 and provenance completeness defaulting to 1.0. Missing report fields therefore create no corresponding knowledge gaps.  
**Impact:** Incomplete/unavailable integrity reports can be interpreted as clean evidence conditions rather than unknown coverage, suppressing research work that should be triggered by uncertainty.

### RL-311 — ContradictionAnalyzer assigns impact from a fixed classification table
**Severity:** MEDIUM  
**Evidence:** Direct/inferred/contextual contradictions receive fixed impacts 0.9/0.6/0.4; unknown impact is a simple entity-count multiplier. The analyzer does not inspect consequence severity, evidence quality, affected dependency graph or uncertainty.  
**Impact:** Ranking is a heuristic ordering, not an evidence-calibrated measure of contradiction impact.

### RL-312 — DiscoveryPrioritizer's budget filter is advisory and does not reserve or verify resources
**Severity:** HIGH  
**Evidence:** `filter_by_budget/2` sums caller-provided `estimated_cost.compute` and `time_hours` fields and filters the list. It does not consult ResourceManager, reserve capacity, validate cost estimates, or reconcile actual usage. Empty budget means no budget filter at all.  
**Impact:** The prioritizer can return work that exceeds real resource capacity; it is not a resource admission controller.

### RL-313 — DiscoveryPrioritizer diversity enforcement relies on caller-provided causal-model metadata
**Severity:** MEDIUM  
**Evidence:** Monoculture and diversity checks group hypotheses by `metadata.causal_model`, defaulting missing values to `:unknown`. They do not independently identify model equivalence or semantic similarity.  
**Impact:** Diversity metrics can be manipulated by metadata labels and do not establish genuinely independent causal approaches.

### RL-314 — ProviderSeeder registration success does not establish provider execution compatibility
**Severity:** HIGH  
**Evidence:** ProviderSeeder registers two capability atoms and declares a provides edge. It does not execute either provider or validate input/output contracts at registration; the capability graph's provider score uses the previously recorded heuristic/fallback scoring (RL-185).  
**Impact:** A successful registration indicates graph metadata was accepted, not that the provider is callable, correct, or suitable for a specific workload.

### RL-315 — DiscoverySupervisor and DiscoveryEngine do not own one durable end-to-end discovery record
**Severity:** HIGH  
**Evidence:** DiscoverySupervisor supervises DiscoveryEngine, DiscoveryScheduler and DiscoveryMetrics, but their operational state is separate and in-memory. Scheduler active workflows, Engine discovery records/evidence and Metrics counters do not share a durable transaction or recovery journal.  
**Impact:** A discovery may exist in one process's state while workflow tracking or metrics are lost in another; restart cannot reconstruct one authoritative discovery lifecycle from these services.

**Registry count correction:** A direct count of `%{id: ..., module: ...}` entries in `ServiceRegistry.canonical_services/0` returns **34**, not 33. Checkpoint 18.26's count statement has been corrected in this ledger. The 34th entry is not an additional service discovered later; the earlier count was an arithmetic error.

**Checkpoint disposition:** 6 findings added (RL-310–RL-315). No finding is closed. No remediation was performed. Next: complete the final registered-service coverage map and reconcile all system writers/callers and readiness evidence. CEL is not yet certified production-ready; ToolForge remains deferred.


## Checkpoint 18.33 — Constitutional scoring and kernel state-machine enforcement

**Source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Scope:** ConstitutionalScorePipeline, ExecutiveService.Base, ConstitutionalScore, RuntimeStates and Kernel boot-state transitions.  
**Method/status:** Static source inspection only. No telemetry replay, score calibration, transition-state test or boot sequence execution was performed.

### RL-316 — ConstitutionalScorePipeline treats empty observation windows as healthy
**Severity:** HIGH  
**Evidence:** `aggregate_window([], service_id)` returns `health: 1.0` and neutral 0.5 dimensions. The pipeline's own `health/0` unconditionally returns `:healthy`; it does not distinguish no observations, stale observations, missing telemetry or failed collection. The pipeline state is volatile and initialized with no windows.  
**Impact:** Absence of score evidence can be presented as healthy service status; a score record does not prove the service was observed or assessed.

### RL-317 — ConstitutionalScorePipeline maps unrelated telemetry into synthetic neutral scores
**Severity:** HIGH  
**Evidence:** Only `[:tiannara, :executive, :constitutional]` extracts supplied score dimensions. All other attached telemetry events (EventBus publish, memory record, mission complete) fall through to fixed 0.5 alignment/transparency/evidence values. The aggregate assigns health 1.0, explainability as alignment × 0.9 and human oversight 0.6 regardless of observation evidence.  
**Impact:** A service's score window can reflect generic telemetry volume rather than actual constitutional performance, evidence quality or human oversight. The aggregate is not an independent measurement of those dimensions.

### RL-318 — Kernel boot bypasses RuntimeStates transition validation
**Severity:** HIGH  
**Evidence:** Public `transition/1` checks `RuntimeStates.valid_transition?/2`, but the boot handler uses private `transition_state/2` directly with `status_to_state/1`. RuntimeStates declares `:booting` may transition only to `:initializing`, `:emergency` or `:shutdown`; a successful boot maps directly to `:operational`, and degraded boot maps to `:recovery`. Neither is an allowed direct transition from `:booting`.  
**Impact:** The formal runtime state machine is not enforced on the principal boot path; recorded transition history can contain transitions that the declared state machine rejects.

**Checkpoint disposition:** 3 findings added (RL-316–RL-318). No finding is closed. No remediation was performed. Registry count remains 34. Next: compile the service-by-service readiness matrix, trace remaining cross-service callers and authority boundaries, and identify the runtime evidence required to close each finding. ToolForge remains deferred until the Tiannara AI/CEL audit is complete.


## Checkpoint 18.34 — CEL 34-service source-readiness matrix (provisional)

**Source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Registry inventory:** 34 non-deprecated specifications.  
**Method/status:** Consolidated from static source findings in Checkpoints 18.20–18.33 and earlier world/runtime checkpoints. This is a source-readiness classification, not a runtime certification. No service is marked production-ready from this audit because runtime boot, load, fault, persistence recovery, security and end-to-end evidence gates have not been executed as part of this checkpoint.

| Registry service | Source-readiness classification | Main blocking evidence |
|---|---|---|
| ExecutiveMemory | NOT READY | DETS-to-ETS fallback record path is broken; event dependency metadata mismatch; score/health inconsistency (RL-180/181) |
| EventStore | NOT READY | Retention deletes history without archive handoff; separate competing event stores/canonical history unresolved (RL-182 and earlier world-event findings) |
| EventBus | NOT READY | Health can report healthy unconditionally; delivery/persistence truth not established (Checkpoint 18.21) |
| ConstitutionalScorePipeline | NOT READY | Volatile windows; empty window reports healthy; generic telemetry maps to synthetic scores (RL-316/317) |
| CapabilityGraph | NOT READY | Volatile graph; cycles accepted; mutation audit best-effort; provider scores use fallback/fixed inputs (RL-183–185) |
| ResourceManager | NOT READY | Hard-coded capacity; incorrect reserve; inconsistent reservations; unauthenticated asynchronous release (RL-186/187) |
| IdentityTrustManager | NOT READY | Volatile identities; source-derived credentials; unverified trust mutation; authorization does not verify credentials (RL-188) |
| PriorityEngine | NOT READY | Volatile model; synthetic training labels; empty calibration can be perfect (RL-189) |
| ExecutiveScheduler | NOT READY | FIFO dispatch; no guaranteed fairness; resource release and worker cancellation/recovery incomplete (RL-190–193) |
| ExecutiveMetrics | NOT READY | Mission outcome ingestion does not update metrics; missing/empty data can produce perfect rates; volatile history (RL-208–210) |
| RuntimePolicyEngine | NOT READY | Volatile unauthenticated policy mutation; no-match defaults to allow; no conflict resolution (RL-211–213) |
| UnifiedRealityGraph | NOT READY | In-memory graph and historical timestamp query defect; canonical world history not established (RL-146–152, RL-168–170) |
| WorldMutationEngine | NOT READY | Mutation/state/event split-commit and canonical commit semantics unresolved (RL-146–153, RL-168–170) |
| ProvenanceEngine | NOT READY | In-memory mutable records; weak verification; broken stats field (RL-294–297) |
| UnifiedWorldModel | NOT READY | In-memory graph coupling and non-atomic mutation/state persistence; event failures can be swallowed (RL-146–153, RL-168–170) |
| VersionManager | NOT READY | In-memory/shallow merge and rollback failures suppressed (RL-146–152) |
| OntologyManager | NOT READY | DETS records not reloaded; mutation writes unchecked; no governance gate (RL-289–293) |
| SnapshotManager | NOT READY | Snapshot hash does not cover full state; restore can be partial (RL-146–152) |
| ReplayEngine | NOT READY | Deterministic replay unavailable/not proven; no canonical committed event source (RL-146–152, RL-165–170) |
| ConflictResolutionEngine | NOT READY | Human-pending can be marked resolved; multi-store partial commits; false conflict classifications (RL-235–239) |
| ConflictDetector | NOT READY | Entity event detection no-op; logical detection limited to existing refutation edges; persistence failures distort counters (RL-232–234) |
| KnowledgeCoordinator | NOT READY | Duplicate detection no-op; evidence fusion trusts supplied confidence; caller boolean can satisfy human approval (RL-240–244) |
| KnowledgeFlowEngine | NOT READY | No-op destinations recorded as successful; delivery results ignored; volatile ledger (RL-245/246) |
| KnowledgeEvolutionEngine | NOT READY | Scheduled evolution routines are no-ops; promotion uses fixed confidence increment (RL-247–249) |
| EvidenceValidator | NOT READY | Evidence presence is mistaken for authenticity/independence; missing provenance can pass for lower confidence (RL-250–252) |
| EpistemicIntegrityService | NOT READY | Empty corpus receives ideal scores; bounded queries; failures not converted to unknown (RL-253–255) |
| AutonomousResearchEngine | NOT READY | Generic hypotheses; default workflow steps unavailable; completion payload treated as evidence; volatile lifecycle (RL-256–259) |
| ExperimentOrchestrator | NOT READY | Public path bypasses declared gates; failed sandbox verdict can count as completed; volatile records (RL-260–266) |
| DiscoverySupervisor | NOT READY | Child process presence treated as operational health; children lack shared durable lifecycle (RL-267/273/315) |
| MissionDirector | NOT READY | Mission-store failure does not fail startup; evidence-presence validation; caller-authored impact; persistence unchecked (RL-194–198) |
| WorkflowEngine | NOT READY | Workflow recovery does not restore live state; start acknowledged despite persistence failure; step execution and compensation incomplete (RL-199–207) |
| ExecutiveStateManager | NOT READY | Snapshots not fully durable; missing services become zero/empty; placeholder policy/ingestion fields (RL-214–216) |
| DecisionPredictor | NOT READY | Fixed prior; synthetic load history; resource availability always true; fixed predictions/recommendations (RL-217–220) |
| ExecutiveDigitalTwin | NOT READY | Randomized outcomes; synthetic predictors; no step semantics; no independent fidelity validation (RL-221–224) |

### Overall CEL source-audit disposition

1. **34/34 registry entries** are represented in this source-readiness matrix.
2. **0/34 are certified production-ready** by this audit.
3. The most critical shared blockers are: no proven canonical durable world-event/commit authority; inconsistent service dependency graph; untrusted evidence and identity paths; ungoverned policy/ontology/knowledge transitions; resource and scheduler lifecycle divergence; research/experiment certification based on weak or synthetic evidence; and boot/recovery paths that can report or leave services in an unready state.
4. The matrix does not imply every subordinate module, caller, or external integration has been exhaustively inspected. Discovery subcomponents and cross-service call paths remain open audit work.
5. No source changes or remediation were performed. No finding was closed. Runtime verification remains outstanding.

**Next checkpoint:** CEL cross-service caller and authority reconciliation. Trace all state writers, event publishers/subscribers, evidence producers/consumers, Council authorization calls, service boot owners, and duplicate/competing runtime paths. Produce a capability-to-caller-to-enforcement-to-evidence matrix and a runtime verification plan. Only after those are reconciled should the Tiannara AI audit be considered complete and ToolForge begin as its own lifecycle audit.


## Checkpoint 18.35 — Cross-service caller and authority reconciliation

**Frozen application source:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Method:** Read-only static source inspection of the frozen commit. No application source was changed. No runtime boot, integration test, fault injection, or soak was run in this checkpoint.

### 18.35.1 Cross-service capability-to-caller-to-enforcement-to-evidence matrix

| Capability / boundary | Source-confirmed caller or producer | Enforcement actually observed | Evidence / result | Audit disposition |
|---|---|---|---|---|
| Canonical entity create | `UnifiedWorldModel.create_entity/1` → `WorldMutationEngine.mutate/3` → `UnifiedRealityGraph.add_entity/1` | Council decision and machine-authorization wrapping/consumption occur in WorldMutationEngine for this path | Mutation record, graph write, optional provenance record, EventBus event | **PARTIAL**: these are sequential writes, not one atomic commit; graph failure can follow a successful mutation record |
| Entity update/refutation/stage transition | UnifiedWorldModel handlers call WorldMutationEngine then directly update graph and publish | Council gate is invoked through mutation engine, but graph update result is ignored in update/refute/stage paths | Mutation ID and event attempted; no shared transaction/commit receipt | **PARTIAL**: audit record may say executed while canonical graph update fails |
| Entity deletion | UnifiedWorldModel.delete_entity/2 | Explicit machine authorization presence/status/expiry/scope/effect binding checks and one-shot consume; then graph deletion | Audit record and event attempted after graph mutation | **PARTIAL**: graph removal and audit/event are not one atomic transaction; no runtime proof |
| Other graph writers | Public UnifiedRealityGraph add/remove APIs; ontology/reality integration paths identified in caller search | Graph API itself validates basic shape but does not enforce Council authorization or mutation-engine mediation | In-memory graph mutation log only | **NOT CLOSED**: complete writer inventory and every direct caller still require exact-commit callsite enumeration |
| World mutation history | WorldMutationEngine | Council.authorize(:world_mutation), decision check, machine grant mint/bind/verify/consume, DETS mutation record | DETS mutation record plus ExecutiveMemory/EventBus/audit attempts | **PARTIAL**: authorization and effect binding exist on this route; record is inserted before graph state changes and audit failure can return error after insertion |
| Event publication | UnifiedWorldModel, WorldMutationEngine, ProvenanceEngine, KnowledgeCoordinator and other services | EventBus appends through EventStore before attempting delivery | EventStore offset; optional DLQ on backpressure delivery failure | **PARTIAL**: callers frequently ignore publish return values; ordinary delivery uses asynchronous send and cannot establish consumer processing |
| Event subscriptions | KnowledgeCoordinator subscribes to discovery.completed, experiment.completed, world.entity.updated | Subscriber PID map is in-memory; no durable consumer offsets or acknowledgement protocol observed | Event messages delivered to process mailbox | **NOT CERTIFIED**: restart/replay/duplicate handling and complete subscriber inventory unverified |
| Provenance creation | UnifiedWorldModel conditionally calls ProvenanceEngine.record_provenance/1 | No independent authentication or immutability enforcement observed at record boundary | In-memory record and telemetry/event attempts | **NOT CERTIFIED**: record result is ignored by entity creation path; overwrite/restart concerns remain (RL-294–297) |
| Evidence validation | KnowledgeCoordinator calls EvidenceValidator.validate_entity_evidence/1 after evidence fusion | Validator reconstructs lineage and checks evidence-count/shape criteria; no demonstrated authenticity or independent replication gate | Validation return exists but caller does not enforce it before returning successful fusion | **NOT CERTIFIED**: validation is not a mandatory certification boundary |
| Discovery certification | KnowledgeCoordinator.certify_discovery/1 calls DiscoveryCertifier.certified?/1 and validate/1 | Heuristic statistical/replication/evidence/quality scoring; no Council authorization or signed certification sink established | Validation report and discovery.certified event | **NOT CERTIFIED**: certification can be emitted from computed report without verified experimental execution or independently authenticated evidence |
| Council authorization | WorldMutationEngine world mutation route; ResourceManager for requests over 50%; Kernel restart/halt routes | WorldMutationEngine rejects requires_human/rejected decisions and verifies bound machine grant; ResourceManager bypasses Council for requests at or below 50%; Kernel restart passes nil context and omits supplied actor from authorization payload | Council Authorization struct and AuditLog attempts | **PARTIAL**: governance is route-specific, not a universal state-writer guard; actor/context binding is inconsistent |
| Human approval | Council HumanApprovalQueue / resume path | Council source describes re-evaluation after human grant, but not all state-changing APIs are proven to require it | Approval queue and audit records | **UNKNOWN / PARTIAL**: no end-to-end human identity/signature-to-effect proof for all high-impact operations |
| Resource allocation | ResourceManager.allocate/2; WorkflowEngine references ResourceManager | Council gate only above 50% of configured capacity; below threshold direct allocation; capacities are hard-coded; release is asynchronous cast | In-memory allocation/reservation maps and telemetry | **NOT CERTIFIED**: no physical/runtime capacity attestation, durable reservation, or end-to-end allocation receipt |
| Service boot | Kernel.boot/0 → BootSequencer.boot/4 → ServiceRegistry.boot_order/0 | Health, constitutional score and resource callbacks are invoked; Kernel supplies resource callback that always returns :sufficient | Boot report and tracked PIDs | **NOT CERTIFIED**: resource gate is non-operative; registry dependency ordering and module dependency declarations can diverge (RL-178–179, RL-225–231) |
| Service restart/recovery | Kernel.restart_service/2 → do_restart/2 | Council authorization, but supplied actor is not bound; restarted service is started without rerunning readiness gates | New PID and audit attempt | **NOT CERTIFIED**: process start is not readiness/recovery proof (RL-303–306) |

### 18.35.2 New cross-service findings

**RL-319 — Canonical graph writes are not transactionally coupled to mutation authorization/history.**  
At the frozen source, UnifiedWorldModel calls WorldMutationEngine before applying the corresponding UnifiedRealityGraph mutation. For create, a successful mutation record is followed by graph insertion; for update/refute/stage transitions, graph mutation results are not checked before the handler reports success. The mutation engine records status :executed before the graph write occurs. This permits mutation history, graph state, provenance and event state to diverge. This reinforces, but does not replace, RL-146, RL-153 and RL-168. **Static source-confirmed; runtime failure injection not run.**

**RL-320 — EventBus publication is not an end-to-end delivery or processing guarantee.**  
EventBus appends the event to EventStore before delivery. In the default non-backpressure mode it sends messages asynchronously and returns success without checking recipient liveness or processing. The DLQ path is conditional on backpressure delivery failure; replay returns :ok after attempting sends and does not establish consumer acknowledgement. EventStore append success therefore proves durable enqueue only, not subscriber processing. **Static source-confirmed; delivery/restart behavior not runtime-tested.**

**RL-321 — Provenance and evidence validation are not mandatory write/certification gates.**  
UnifiedWorldModel conditionally invokes ProvenanceEngine.record_provenance/1 after graph insertion and does not enforce its result before returning entity creation success. KnowledgeCoordinator invokes EvidenceValidator after evidence fusion but does not use the validation result to reject, quarantine or prevent successful fusion. This compounds RL-241, RL-250 and RL-294–297. **Static source-confirmed.**

**RL-322 — Discovery certification output is not bound to verified execution or Council-approved promotion.**  
KnowledgeCoordinator invokes DiscoveryCertifier against the supplied Discovery struct and emits discovery.certified using the calculated result. DiscoveryCertifier derives its report from the struct's experiments/evidence and heuristic validator components; this call path does not itself retrieve authoritative experiment execution records, verify signed evidence lineage, or obtain Council authorization for a consequential promotion. Existing weaknesses RL-259–260 and RL-274–288 therefore cross the service boundary into the certification consumer. **Static source-confirmed; no real discovery was certified in this checkpoint.**

**RL-323 — Council enforcement is selective rather than universal across state-changing services.**  
WorldMutationEngine applies a substantial Council/machine-authorization gate, but UnifiedRealityGraph exposes direct mutation APIs without an equivalent gate at the graph boundary. ResourceManager only calls Council.authorize when a request exceeds 50% of its configured capacity. Thus a caller able to reach a direct writer or make a smaller allocation does not traverse the same authorization boundary. The exact complete set of direct graph writers remains to be enumerated. **Static source-confirmed for the observed APIs and threshold; exhaustive caller inventory remains open.**

**RL-324 — Service boot's resource-readiness evidence is synthetic, not measured.**  
Kernel passes BootSequencer a resource-check callback that unconditionally returns :sufficient. ResourceManager itself uses fixed capacity values and its health callback returns :healthy independently of its ready flag. Consequently, the boot report's resource gate cannot demonstrate that actual resource capacity is available or that ResourceManager is operationally ready. **Static source-confirmed; runtime resource exhaustion was not tested.**

### 18.35.3 Reconciled authority and evidence boundaries

1. **Council authorization is not the same as canonical state ownership.** Council can decide whether an operation is permitted; it does not provide the atomic world-state commit, durable event sequence, or replay authority.
2. **WorldMutationEngine is a governed mutation-recording path, not yet a proven universal world-state gateway.** Direct graph APIs and other world/runtime writers mean its mutation log cannot currently be treated as the complete world history.
3. **EventStore is not proof of event consumption.** An append offset proves the event was accepted by the store; it does not prove all intended subscribers processed it or committed their consequences.
4. **Provenance presence is not provenance verification.** A caller-supplied provenance map, in-memory record, or evidence count does not establish source authenticity, independence, reproducibility, or complete lineage.
5. **A certification report is not execution evidence.** Certification must be linked to immutable experiment inputs, actual runner outputs, independent validation/replication, evidence hashes, authority decision, and a durable revocation/expiry record.
6. **Service registration is not operational readiness.** A registered capability and successful process start do not establish usable dependencies, actual resource availability, recovery behavior, or a functioning caller path.

### 18.35.4 Runtime verification plan — not executed

| Verification ID | Required experiment | Required pass evidence |
|---|---|---|
| R35-01 Writer inventory | Enumerate every caller of UnifiedRealityGraph add/remove entity/relationship and every CanonicalWorldState writer across root app and runtime app | Complete callsite inventory tied to exact commit; each writer either routes through governed mutation gateway or has an explicit reviewed authority contract |
| R35-02 Mutation/graph atomicity | Inject graph write failure after Council authorization and mutation-record insertion for create/update/refute/delete/relationship | No false :executed record; no split state; recovery/reconciliation proves one committed outcome |
| R35-03 Authorization bypass | Attempt direct graph writes and direct service API mutations with absent, invalid, expired, replayed and wrong-target authority | All unauthorized effects refused; no graph/history/event side effects |
| R35-04 Event delivery | Kill subscriber before send, during processing and after processing-before-ack; restart and replay; force EventStore and DLQ failures | Stable event IDs/offsets, idempotent consumer effects, durable acknowledgements, observable retry/DLQ terminal states, no silent loss/duplicate effect |
| R35-05 Provenance gate | Submit missing, forged, overwritten, cyclic, incomplete and unavailable provenance; force ProvenanceEngine failure | Invalid lineage cannot be treated as validated or promoted; durable provenance receipt is bound to entity version/hash |
| R35-06 Evidence/certification | Submit fabricated experiment structs, missing runner output, correlated sources, duplicate evidence and failed replication; compare against genuine independently reproduced run | Certification fails closed unless source authenticity, execution identity, independent evidence and validation are verified |
| R35-07 Human/Council authority | Exercise every high-impact operation with no approval, pending approval, wrong human, stale approval, policy rejection and valid approval | Signed actor identity, exact effect binding, one-shot authorization, policy re-evaluation, durable audit and enforced consequence |
| R35-08 Resource accounting | Concurrent allocations at below/above threshold; overcommit; crash between allocate/use/release; stale reservation | Measured capacity, atomic reservation, bounded overcommit, lease/recovery semantics and complete accounting |
| R35-09 Boot/dependency readiness | Inject missing/degraded dependencies, resource shortage, cycle, failed health/score check, duplicate start and service crash during boot | No dependent starts on unmet prerequisite; no synthetic resource pass; accurate readiness and complete PID/ownership tracking |
| R35-10 Recovery and replay | Restart each stateful service and the whole root/runtime system from persisted state and event offsets | Reconstructed state root matches committed history; no reliance on volatile maps or telemetry as canonical recovery source |

### 18.35.5 Checkpoint disposition

- Cross-service source inspection has confirmed several boundaries are implemented only partially and several declarations overstate the guarantee provided by the caller path.
- New findings added: **RL-319–RL-324**.
- Findings closed: **0**.
- Application source changes: **0**.
- Runtime verification: **not performed**.
- The capability-to-caller-to-enforcement-to-evidence matrix is a source-based reconciliation, not a certification of runtime behavior.
- The complete direct-writer and subscriber inventories remain open. Root/runtime duplicate ownership and full service recovery remain open.
- ToolForge remains an integral Tiannara AI subsystem and must receive its own detailed audit before Tiannara AI's overall audit can be closed; it is not excluded from the final readiness decision.

**Next checkpoint:** 18.36 — exhaustive writer/subscriber/caller inventory across both Tiannara root application and `tiannara_runtime`, including direct graph writes, alternate EventBus implementations, and unregistered/orphan service paths.


## Checkpoint 18.36 — Root/runtime writer, event-bus and caller inventory

**Frozen application source:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Method:** Inspected the frozen commit tree and source for high-risk graph, event, synchronization, snapshot, versioning, ontology and runtime files. GitHub code-search results from the repository's current default branch were not used as proof for this frozen baseline; conclusions below are tied to files fetched at the frozen SHA. This is a bounded static inventory, not a claim that every callsite in the 2,896 Elixir files has been exhaustively enumerated. No runtime tests or source modifications were performed.

### 18.36.1 Canonical and competing graph/state writers

| Writer / path | Observed operation | Governance / evidence route | Disposition |
|---|---|---|---|
| `Tiannara.World.UnifiedWorldModel` | Calls `WorldMutationEngine.mutate/3`, then `Tiannara.World.UnifiedRealityGraph` for create/update/refute/relationship/delete paths | Council/machine grant through mutation engine on supported paths; mutation record precedes graph write | Governed path exists but is not atomic; RL-319 |
| `Tiannara.World.SnapshotManager` restore | Recreates entities by directly calling `UnifiedRealityGraph.add_entity/1` | No WorldMutationEngine/Council call in the restore write path | Direct writer; snapshot restoration bypasses the governed mutation gateway |
| `Tiannara.World.VersionManager` rollback | Calls `UnifiedRealityGraph.add_entity/1` with stored snapshot; rescues/catches and suppresses write errors | No WorldMutationEngine/Council call in rollback write path | Direct writer; rollback can report completion while graph restoration failed |
| `Tiannara.World.RealityCoordinator` migration/conflict resolution | At least one source-wins path inserts graph entity before calling WorldMutationEngine; other migration paths record mutation after graph write | Ordering differs from canonical UWM path | Direct write precedes authorization/history record on observed path |
| `Tiannara.World.WorldIntegrationCoordinator` | Uses WorldMutationEngine for sync/conflict bookkeeping; exact downstream graph mutation delegated through source adapters and requires adapter-specific inventory | Not all adapter writes inspected | Partial; adapter write authority remains unknown |
| `Tiannara.Graph.UnifiedRealityGraph` | Separate GenServer with `add_node/3`, `add_edge/4`, `ingest_edge/5` APIs and its own graph state | Independent of `Tiannara.World.UnifiedRealityGraph`; no common governed mutation boundary established in this file | Competing graph/history surface; relationship to canonical world state unproven |
| `Tiannara.Runtime.WorldStateManager` (runtime app) | PID-addressed GenServer accepts asynchronous CAL/CIS state updates and metric updates | No root WorldMutationEngine, Council or canonical world commit call in these handlers | Separate mutable runtime state; canonical ownership and synchronization contract unproven |
| `Tiannara.World.OntologyManager` | Maintains concept/mapping state; some merge/split/retire paths call WorldMutationEngine, while define/map paths update its own state | Governance use is operation-dependent; local state is separate from graph mutation | Separate ontology state owner; consistency with canonical world remains unproven (RL-289–293) |

### 18.36.2 Event-bus and event-store implementation inventory

The frozen tree contains multiple independently implemented event paths:

| Implementation | API / delivery shape | Persistence / subscriber semantics | Status |
|---|---|---|---|
| `Tiannara.CEL.Services.EventBus` | Topic publish/subscribe, replay, DLQ | Appends to `Tiannara.CEL.Services.EventStore`; subscriber registry is process memory; sends to PIDs | Primary CEL bus inspected in 18.35; durable consumer acknowledgements not established |
| `Tiannara.CEL.EventBus` | `ingest_event/2` via cast; health/constitutional handlers | Separate GenServer; not shown as a facade over CEL.Services.EventBus | Distinct bus; live publisher/subscriber topology unknown |
| `Tiannara.Executive.EventBus` | Typed event publish via call; PID/type subscriptions | In-memory subscriber list and dead-letter list; monitors subscribers | Separate delivery path; not the CEL topic bus |
| `Tiannara.Runtime.EventBus` | Server-addressed publish cast and subscribe call | In-memory event history/subscriber set | Separate, volatile bus |
| `Tiannara.ASC.Core.EventBus` | Registry topic subscribe and direct process sends | Local Registry delivery; no durable store in module | Separate process-local bus |
| `Tiannara.EventBus` in `tiannara_runtime` | Registry subscribe and broadcast API | Telemetry plus Registry delivery; distinct runtime namespace | Separate runtime bus; relationship to root CEL bus not proven |
| `Tiannara.CEL.Services.EventBusSafe` | Rescue wrapper around CEL.Services.EventBus | Does not provide independent storage/delivery guarantees | Facade, not a separate durable bus |
| `Tiannara.Executive.EventStore` | Separate executive append API | Earlier audit found /tmp-backed best-effort behavior and no proof of canonical world history | Not interchangeable with CEL EventStore |
| `Tiannara.Runtime.MultiWorld.Events.EventStore` | ETS insert, timestamp/event ID ordering, count cast | ETS-owned runtime event data; no shared CEL event sequence | Separate volatile runtime store |

**Subscriber examples confirmed at the frozen source:** WorldStateSynchronizer subscribes to world entity/relationship, discovery, experiment, simulation, mission and engineering topics; ConflictDetector subscribes to world entity create/update; KnowledgeCoordinator subscribes to discovery/experiment completion and entity updates; VersionManager subscribes to world.mutation.executed; PriorityEngine and Phase4 research/experiment services subscribe to workflow events. This is a sample of actual subscriber code, not a complete subscriber census.

### 18.36.3 Synchronization, restore and replay findings

**RL-325 — Snapshot restore bypasses the governed world mutation path.**  
SnapshotManager restores snapshot entities by invoking UnifiedRealityGraph.add_entity/1 directly. The inspected restore path does not call WorldMutationEngine or Council authorization for each restored entity and does not establish a single authorized restore transaction. This bypasses the governance and mutation-history boundary identified in RL-319/RL-323. Static source-confirmed; restore authorization behavior not runtime-tested.

**RL-326 — Version rollback is a second direct canonical graph writer and suppresses restore failures.**  
VersionManager rollback writes the target snapshot directly through UnifiedRealityGraph.add_entity/1 and rescues/catches failures as :ok in the inspected block. It does not route the graph write through WorldMutationEngine. This means rollback can fail to restore the graph while the caller proceeds without a surfaced error. Static source-confirmed; failure injection not run.

**RL-327 — RealityCoordinator performs graph mutation before its governed mutation record on a source-wins path.**  
The observed conflict-resolution path inserts the incoming entity through UnifiedRealityGraph.add_entity/1 and only afterwards calls WorldMutationEngine.mutate/3. A rejected/failed authorization or mutation record can therefore leave a graph write without its corresponding governed mutation record. This is a separate ordering defect from the UWM mutation-before-graph path (RL-319). Static source-confirmed; no runtime test.

**RL-328 — Tiannara contains parallel graph and event histories without a proven reconciliation contract.**  
The frozen root tree contains both `Tiannara.World.UnifiedRealityGraph` and `Tiannara.Graph.UnifiedRealityGraph`, plus independent CEL, Executive, Runtime and ASC event-bus implementations and multiple event stores. The modules expose separate state/delivery mechanisms. No inspected source establishes a single canonical event sequence, graph authority, or mandatory adapter/reconciliation path across all these surfaces. This overlaps earlier root/runtime split findings RL-157–164 and the canonical-history findings RL-168/RL-300, but records the concrete parallel implementations found in this checkpoint. Static source-confirmed existence; runtime co-start/traffic relationship UNKNOWN.

**RL-329 — WorldStateSynchronizer replay API does not replay events or rebuild state.**  
The inspected `handle_call({:replay, offset}, ...)` returns `{:ok, %{replayed_from: offset}}` without reading EventStore, applying events, or verifying a reconstructed state root. Its event subscriptions therefore do not establish a functioning durable recovery mechanism. Static source-confirmed; no runtime replay attempted.

**RL-330 — Runtime world-state updates are a separate asynchronous state mutation surface.**  
`tiannara_runtime/lib/tiannara_runtime/world_state_manager.ex` exposes PID-addressed `GenServer.cast` updates for CAL state, CIS state and metrics. The inspected module does not bind these updates to root canonical world commits, event offsets, actor authorization, or a durable replay record. This reinforces the two-world-lifecycle and asynchronous-acknowledgement findings RL-157–164. Static source-confirmed for this module; upstream/downstream adapter inventory remains open.

### 18.36.4 Caller and subscriber census limitations

1. The frozen source tree contains 2,896 Elixir source/test files in the root and runtime library directories; this checkpoint inspected targeted files and a bounded set of call paths, not every possible dynamic invocation, macro-generated call, adapter callback or Python caller.
2. GitHub's code-search connector searches the repository default branch, not the supplied historical SHA. Search results from that service were therefore excluded from frozen-baseline proof. The source conclusions here use exact-SHA file fetches and tree paths.
3. Direct writer examples are now confirmed for SnapshotManager, VersionManager and RealityCoordinator. A complete callsite inventory across every root/runtime writer remains open.
4. Event subscriber examples are confirmed, but a full topic-to-publisher-to-subscriber table and process ownership/co-start proof remain open.
5. Runtime event bus and event store implementations are not assumed to be active merely because their modules exist. Which supervisors start them, whether they share topics, and whether traffic crosses app boundaries are UNKNOWN pending runtime inspection.

### 18.36.5 Required next verification

- Enumerate exact-SHA direct writer callsites for every graph API and state-mutating adapter, including dynamic calls and Python bridges.
- Map each event topic to all publishers, subscribers, bus module, event store, delivery acknowledgement and consumer consequence.
- Inspect root and runtime supervision trees/configuration to determine which parallel buses, stores and graph owners actually start together.
- Inject authorization rejection and graph/storage failure into snapshot restore, version rollback and RealityCoordinator migration; assert no ungoverned side effects.
- Prove synchronizer replay by killing consumers, restarting from durable offsets and comparing reconstructed state hashes to committed snapshots.
- Establish whether legacy Graph.UnifiedRealityGraph and runtime WorldStateManager are live dependencies, compatibility layers, test-only modules, or orphaned paths using startup references and runtime traces.

### 18.36.6 Checkpoint disposition

- New findings: **RL-325–RL-330**.
- Findings closed: **0**.
- Application source modifications: **0**.
- Runtime verification: **not performed**.
- Direct writers and multiple independent buses are source-confirmed; complete callsite/subscriber census and live ownership remain open.
- ToolForge remains part of Tiannara AI's full audit scope and must be audited before overall closure.
  
**Next checkpoint:** 18.37 — supervisor/startup ownership reconciliation for every graph, event bus, event store and synchronizer identified here; prove which implementations are actually started, duplicated, dormant or orphaned, and map each to its callers and dependencies.


## Checkpoint 18.37 — Supervisor and startup ownership reconciliation

**Frozen application source:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Method:** Static inspection of root and `tiannara_runtime` application entrypoints, supervision trees, boot configuration, CEL Kernel and registry. No application source changes, runtime boots, process inspection or fault-injection tests were performed.

### 18.37.1 Application boundary

| Property | Root `:tiannara` application | `:tiannara_runtime` application |
|---|---|---|
| OTP entrypoint | `Tiannara.Application` | `TiannaraRuntime.Application` |
| Top-level supervisor | `Tiannara.Application` | `TiannaraRuntime.Supervisor` |
| Main startup path | core children + loop children + optional ASC children; then CEL Kernel boot | StartupSupervisor + additional optional/required runtime children |
| Main runtime orchestration | CEL Kernel + DynamicSupervisor + 34-service registry | StartupSupervisor → RootSupervisor with Infrastructure/Execution/Ecology/Constraint/Meta layers |
| World runtime | root CEL world services and root graph | MultiWorld WorldSupervisor / WorldRegistrySupervisor and Ecology.UniverseSupervisor |
| Event infrastructures | CEL Services EventBus/EventStore, Executive EventBus/EventStore, Runtime EventBus, CEL EventBus and ASC EventBus | Runtime EventBus/Registry, Omega SentinelEventBus, MultiWorld EventStore and NATS |
| Application dependency | root mix.exs declares local `forward_provenance`; no direct dependency on `:tiannara_runtime` was found in the inspected dependency list | runtime mix.exs declares local `../forward_provenance`; no direct dependency on root `:tiannara` was found in the inspected dependency list |
| Co-start proof | Source entrypoint exists | Source entrypoint exists; whether production deploy launches both applications/nodes together is UNKNOWN |

### 18.37.2 Root application startup ownership

1. `Tiannara.Application.start/2` starts `core_children ++ loop_children ++ asc_children(asc_enabled?)` under a one-for-one supervisor.
2. CEL Kernel is a direct root child. It creates a named DynamicSupervisor, `Tiannara.CEL.ServiceSupervisor`.
3. After root supervisor startup, `Tiannara.Application` invokes CEL Kernel boot. In production it does so inside `Task.start/1`; the root application can return successfully while CEL boot is still running or has failed.
4. CEL Kernel asks BootSequencer to start registry services dynamically. The 34 registry services are not ordinary static root children; they are children of the CEL DynamicSupervisor, with `restart: :temporary`.
5. DiscoverySupervisor is started manually after a successful CEL boot, outside the root application's declared static child list. The source checks for an existing registered process, but the start call is not itself a child spec of the root supervisor.
6. `Tiannara.Executive.Supervisor` is separately a root child and starts Executive.EventStore, Executive.EventBus, ExecutiveMemory and Coordinator. These are distinct modules from the CEL Services EventStore/EventBus services started dynamically by CEL Kernel.
7. Root config sets `asc.enabled: true`. Therefore the root application's `asc_children(true)` includes ASC.Core.Supervisor, engineering/reality/civilization supervisors, ASC.Supervisor and ToolForge.ToolForgeSupervisor. ToolForge is not a separate application; it is a root Tiannara child in this configuration. PhaseΩ also conditionally registers ToolForge for its own subsystem boot sequence.

### 18.37.3 Runtime application startup ownership

1. `TiannaraRuntime.Application` starts `TiannaraRuntime.StartupSupervisor` and then adds optional children including CIS.Supervisor, MultiWorld.KillSwitch, MultiWorld.WorldSupervisor, CIS.ExecutionController, QuotaGovernor, LineageCompression and GCK.
2. StartupSupervisor starts CPL, Omega.Supervisor, COP/Observatory, RuntimeWeb.Endpoint, RootSupervisor and DiscoveryRunner under `:rest_for_one`.
3. RootSupervisor starts Infrastructure, Execution, Ecology, and (for stable/research profiles) Constraint and Meta authority supervisors, also under `:rest_for_one`.
4. Runtime config sets boot_profile to `:stable`, so Constraint and Meta are included by default.
5. Infrastructure starts Phoenix.PubSub, registries, SharedMemory, NATS.Supervisor and optional telemetry. Execution starts OPC.CoreSupervisor and optional OPC.Supervisor. Ecology starts UniverseSupervisor plus optional OLEF/OCM/RRG supervisors.
6. The separate WorldRegistrySupervisor exists and defines WorldRegistry plus a DynamicSupervisor, but it is not among the direct children in the inspected Runtime.Application list or RootSupervisor's five authority layers. Its live start ownership is therefore **not established** by the inspected startup path.
7. MultiWorld.WorldSupervisor is started as a child in Runtime.Application, but it is the supervisor for per-world children; its own source defines a per-world named supervisor and is not the same as the root WorldRegistrySupervisor.
8. Runtime EventBus is not directly started by Runtime.Application's top-level child list. Runtime Infrastructure starts a duplicate-key Registry used by Tiannara.EventBus, while `Tiannara.Runtime.EventBus` is started only when `Tiannara.Runtime.Supervisor` is explicitly started with a suitable caller. The inspected root runtime startup does not establish that this optional supervisor is started.
9. Omega.Supervisor does start a distinct `TiannaraRuntime.Omega.SentinelEventBus` and its own monitoring/audit services. It is a local in-VM event bus with bounded in-memory history and a CPL mirror, not the CEL Services EventBus.

### 18.37.4 Startup and ownership findings

**RL-331 — Tiannara root and runtime remain separately bootable OTP applications without a proven unified deployment contract.**  
The root and runtime each define their own Mix application entrypoint, root supervisor and dependency set. Neither inspected mix dependency list directly depends on the other application. The source does not prove whether deployment starts both, one, or distinct nodes, nor does it define a versioned inter-application ownership/health contract for canonical world state. This reinforces RL-157/RL-158. Static source-confirmed; deployment topology UNKNOWN.

**RL-332 — Runtime StartupSupervisor is not the sole top-level owner of runtime children.**  
Runtime.Application starts StartupSupervisor and then appends MultiWorld.KillSwitch, MultiWorld.WorldSupervisor, CIS.ExecutionController, QuotaGovernor, LineageCompression and GCK as siblings under TiannaraRuntime.Supervisor. This contradicts the StartupSupervisor documentation that all system startup must go through it and creates two top-level ownership layers. Static source-confirmed; runtime duplicate child IDs/process conflicts not tested.

**RL-333 — Root CEL service children use temporary restart semantics and are not restarted by their DynamicSupervisor after crash.**  
CEL Kernel creates DynamicSupervisor children with `restart: :temporary`. A service crash therefore does not automatically restart that child. Kernel's PID map is populated from the boot report and is not shown monitoring/reconciling subsequent service death. This reinforces RL-301/RL-305. Static source-confirmed; process-kill test not run.

**RL-334 — DiscoverySupervisor is manually started outside the root supervision tree.**  
The root application invokes DiscoverySupervisor.start_link/1 from the asynchronous CEL boot task after successful boot. This process is not represented as a child of Tiannara.Application or CEL ServiceSupervisor in the inspected path. A failure of that process does not have a demonstrated parent restart policy. This supplements RL-273 and RL-301. Static source-confirmed; restart behavior not tested.

**RL-335 — Multiple distinct executive/event-store owners are deliberately started within the root app, but no shared history contract is established.**  
Root application starts Executive.Supervisor (Executive.EventStore/EventBus) while CEL Kernel separately starts CEL Services.EventStore/EventBus. Both are named, separately stateful service families with different APIs and persistence behavior. Their coexistence is source-confirmed; whether a strict adapter/partition contract prevents split-brain histories is UNKNOWN. This supplements RL-328.

**RL-336 — Runtime WorldRegistrySupervisor has no established parent in the inspected production startup graph.**  
The module defines WorldRegistry and WorldRuntimeSupervisor, but the inspected Runtime.Application and RootSupervisor child graphs do not include it. Runtime MultiWorld.WorldSupervisor is separately started. Consequently, the claimed registry-backed world lifecycle is not proven to be the active owner. Static source-confirmed for the inspected child graphs; dynamic/manual start paths remain UNKNOWN.

**RL-337 — Root PhaseΩ and root OTP supervision both participate in ToolForge startup/registration.**  
With root config ASC enabled, ToolForge.ToolForgeSupervisor is included in ASC children and is also conditionally registered with PhaseΩ BootSequencer. The source comment says PhaseΩ registration is intended to adopt already-running subsystems, but the exact behavior of both paths and whether they always resolve to one PID is not runtime-proven. This creates a potential duplicate-start/ownership ambiguity for a critical Tiannara subsystem. ToolForge remains in Tiannara AI scope. Static source-confirmed dual startup/registration paths; duplicate process outcome UNKNOWN.

**RL-338 — Runtime event bus implementations have different and incomplete startup ownership.**  
Runtime Infrastructure starts Tiannara.EventRegistry, but not Tiannara.Runtime.EventBus. Omega.Supervisor starts Omega.SentinelEventBus. TiannaraRuntime.EventBus relies on the Registry path, while Tiannara.Runtime.EventBus has its own GenServer and is only started by its optional Runtime.Supervisor. These are distinct APIs with different persistence and subscriber semantics. No single runtime bus owner or complete publisher/subscriber routing contract is established. Static source-confirmed; runtime traffic mapping UNKNOWN.

### 18.37.5 Active, optional, dormant and unknown classification

| Component | Source startup classification | What can be asserted |
|---|---|---|
| Root CEL Kernel | Root child | Starts with root application; 34 services boot asynchronously in production |
| CEL EventStore/EventBus | CEL dynamic children | Intended to start during CEL boot; actual live process status not observed |
| Executive EventStore/EventBus | Executive.Supervisor children | Included in root static supervision tree |
| Root World.UnifiedRealityGraph | CEL dynamic child | Intended to start during CEL boot; live process status UNKNOWN |
| Root Graph.UnifiedRealityGraph | No parent established in inspected root child graph | Startup ownership UNKNOWN |
| Root Runtime.Supervisor / Runtime.EventBus | Explicitly parameterized optional supervisor | Not established as a child in root app's inspected child graph |
| DiscoverySupervisor | Manually started after CEL boot | Not under an inspected permanent supervisor |
| Runtime StartupSupervisor | Runtime.Application child | Included in runtime top-level tree |
| Runtime RootSupervisor | StartupSupervisor child | Included; stable profile includes five authority layers |
| Runtime Omega.SentinelEventBus | Omega.Supervisor child | Included under runtime startup |
| Runtime EventBus (Registry broadcast) | Requires Tiannara.EventRegistry | Registry starts; bus module itself is not a process |
| Runtime MultiWorld.WorldSupervisor | Runtime.Application sibling | Included as a child; per-world spawn activity not established |
| Runtime WorldRegistrySupervisor | No parent found in inspected startup graph | Active ownership UNKNOWN |
| Runtime MultiWorld.EventStore | No direct parent established in inspected startup graph | Process/ETS ownership UNKNOWN; Omega audit explicitly checks whether it exists |
| ToolForge.ToolForgeSupervisor | Root ASC child when ASC enabled; PhaseΩ subsystem registration too | Startup intent confirmed; actual PID ownership/duplicate behavior UNKNOWN |

### 18.37.6 Runtime verification plan — not executed

| ID | Experiment | Required evidence |
|---|---|---|
| R37-01 | Start root app alone and runtime app alone in isolated BEAM nodes | Exact registered process inventory, application tree and readiness report for each |
| R37-02 | Start both using intended production deployment | One authoritative owner per canonical state store, graph, bus and world lifecycle; no name collisions or split ownership |
| R37-03 | Kill each CEL service process | Supervisor restart or explicit fail-closed degradation, refreshed PID map and readiness revocation |
| R37-04 | Kill DiscoverySupervisor | Defined restart/disable policy, no silently stale discovery health |
| R37-05 | Inspect actual runtime child trees for WorldRegistrySupervisor, MultiWorld.EventStore, Runtime.Supervisor and Graph.UnifiedRealityGraph | Prove active/dormant/orphan status and identify manual/dynamic callers |
| R37-06 | Trace root and runtime event topics end-to-end | Publisher → bus → store → subscriber → durable consequence, with acknowledgements and offsets |
| R37-07 | Start root with ASC enabled and observe ToolForge | Exactly one supervised ToolForge PID; PhaseΩ adopts rather than duplicates; crash recovery works |
| R37-08 | Crash Runtime.RootSupervisor children under rest_for_one | Correct dependent restart order and preserved durable state |
| R37-09 | Compare registry service declarations to actual booted processes and executable capability probes | No service reports ready solely because a process exists or a module is loadable |

### 18.37.7 Checkpoint disposition

- New findings: **RL-331–RL-338**.
- Findings closed: **0**.
- Application source modifications: **0**.
- Runtime verification: **not performed**.
- Root and runtime startup trees are source-confirmed to be separate. Actual deployment co-start and process ownership remain UNKNOWN.
- The source confirms startup intent for ToolForge within the root Tiannara application; its actual runtime PID ownership and duplicate-start behavior remain to be verified.
- ToolForge is not excluded or deferred from the Tiannara AI final audit; the specific ToolForge implementation audit remains outstanding.

**Next checkpoint:** 18.38 — targeted lifecycle contract audit for root/runtime world owners, service process registration and dynamic child reconciliation; determine whether the two application trees can safely co-exist and identify the single canonical world lifecycle owner before any remediation.


## Checkpoint 18.38 — CEL whole-system awareness and coherence capability

**Frozen application source:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Method:** Static source inspection of CEL Kernel, ServiceRegistry, CapabilityGraph, RuntimePolicyEngine, EventBus and application startup. Targeted expected system-inventory/introspection/coherence modules were also checked by exact path; the queried paths were absent. This is not a complete repository-wide symbol search and does not prove that no equivalent functionality exists elsewhere. No runtime tests or source modifications were performed.

### 18.38.1 Required CEL whole-system model

CEL's intended system awareness must extend beyond the 34 registered executive services. The authoritative inventory needs to cover:

1. **Applications and deployment units:** root `:tiannara`, `:tiannara_runtime`, dependencies, release profiles, nodes, environment/configuration and application start order.
2. **Processes and ownership:** supervisors, child specs, registered names, dynamic children, restart strategy, health/readiness, lifecycle and process ownership.
3. **Code and capabilities:** modules, public APIs, callbacks, actual executable implementations, contracts, versions, feature flags and declared vs implemented capability.
4. **Connections:** caller/callee edges, event publishers/subscribers, topics, API routes, adapters, queues, storage access and cross-application bridges.
5. **State authority:** canonical world/entity owners, graph writers, event logs, snapshots, caches, replicas, derived state and recovery/replay ownership.
6. **Governance:** Council authorization, human approval, actor/effect binding, ACL/ABAC, policy enforcement, constitutional constraints and immutable audit evidence.
7. **Evidence and operations:** tests, CI/build artifacts, runtime traces, execution receipts, health observations, failure history, recovery drills and provenance.
8. **Coherence constraints:** single-writer rules, dependency compatibility, interface/schema compatibility, event contract compatibility, no orphan capabilities, no duplicate authorities, no cycles, no silent no-op adapters and no missing enforcement/evidence paths.

Each inventory edge must carry source/version, observed time, evidence type, confidence/status and verification method. Static declarations, build-time discovery, runtime observation and tested behavior must remain distinct. An absent observation must be UNKNOWN, not interpreted as absence or health.

### 18.38.2 Existing CEL capability vs requirement

| Required function | Source-confirmed implementation | Gap |
|---|---|---|
| Enumerate CEL executive services | ServiceRegistry.all/discover returns the canonical in-memory registry set; 34 services in this baseline | Covers only declared registry entries, not the whole repository, root app, runtime app, adapters, stores or unregistered services |
| Discover service capabilities | Each registered spec declares `provides`, `requires`, `depends_on`, module and health/score callbacks | Declarations are not reconciled with public APIs, actual callers, executable behavior or runtime traffic |
| Dependency ordering | ServiceRegistry.boot_order sorts registered service specs | Prior findings RL-178–179: unresolved/cyclic dependencies can yield incomplete ordering; does not cover all application/supervisor/API/data dependencies |
| Capability graph | CapabilityGraph maintains a graph of capability/provider relationships and runs redundancy checks | It is not shown ingesting the complete source tree, both application supervision graphs, API/event/store edges, governance or evidence graph |
| Runtime process awareness | Kernel records service PIDs from boot report and checks process names for registry modules | Snapshot of boot PIDs; no demonstrated continuous whole-node process/supervisor inventory, crash reconciliation or runtime connection tracing |
| Health and constitutional readiness | Kernel calls each registered service's configured health and score callbacks | Process health can be superficial; score callbacks can be synthetic; resource callback is hard-coded :sufficient (RL-324) |
| Cross-system coherence detection | No exact-path system-wide introspector/coherence analyzer was found in targeted checks | No proven complete coherence scan, drift detection, orphan detection or cross-app reconciliation engine |
| Autonomous repair orchestration | Kernel supports Council-authorized restart; RuntimePolicyEngine supports policy evaluation | Restart is not architectural repair; no demonstrated evidence-backed plan/patch/test/rollback pipeline for arbitrary disconnected systems |
| Repair authorization | Council is consulted on selected operations; human review and authority defects recorded elsewhere | No universal action classification, exact effect-bound grant, signed approval and post-change independent verification across all repairs |
| Persistent system knowledge | ExecutiveMemory/EventStore and CapabilityGraph exist | No proven durable, versioned, complete system atlas linked to source commit, runtime topology and test/evidence lineage |

### 18.38.3 New findings

**RL-339 — CEL's service discovery is registry-scoped, not whole-system discovery.**  
At the frozen source, ServiceRegistry initializes from a fixed canonical_services/0 list and discover/0 returns the active non-deprecated entries from that in-memory map. Kernel boot and readiness operate on these service specs. The API does not itself enumerate all loaded modules, OTP applications, supervisor trees, public APIs, event consumers, storage owners, routes, adapters or runtime callers. This means CEL cannot derive complete Tiannara system awareness from this registry alone. Static source-confirmed. Other discovery mechanisms elsewhere in the repository have not been exhaustively ruled out.

**RL-340 — Capability declarations are not reconciled against executable implementation and observed connections.**  
Service specs carry provides/requires/dependency declarations, while module callbacks report capabilities and dependencies. The inspected boot path checks health and constitutional score but does not verify that every provided capability has a real implementation, every required capability has a connected provider, or each declared connection has a functioning caller/consumer and evidence receipt. Existing findings RL-174–176, RL-232, RL-245, RL-257 and RL-314 demonstrate concrete examples of declaration/implementation/caller gaps. Static source-confirmed for the inspected registry/kernel path; full-repository alternatives UNKNOWN.

**RL-341 — CapabilityGraph is not established as Tiannara's authoritative system architecture graph.**  
CapabilityGraph is a CEL service with a capability/provider graph and redundancy checks, but no inspected integration proves that it ingests the full root/runtime application topology, supervisor ownership, all code/API/event/data edges, canonical state writers, governance boundaries and verification evidence. Its current existence therefore cannot be treated as proof that CEL understands the entire system. Static source inspection; complete dynamic ingestion paths remain UNKNOWN.

**RL-342 — CEL has no demonstrated closed-loop system coherence repair capability.**  
The inspected Kernel supports boot, state transition, restart and halt; RuntimePolicyEngine evaluates stored policies; CapabilityGraph reports capability relationships. These pieces do not form a demonstrated pipeline that discovers a discrepancy, establishes evidence/root cause, proposes a governed change, obtains required approval, applies the exact authorized change, runs independent tests, verifies runtime connection and records rollback/recovery evidence. Restarting a process or registering a provider is not proof of architectural repair. Static source inspection; equivalent orchestration elsewhere not exhaustively ruled out.

### 18.38.4 Required architecture: System Atlas + Coherence Engine

The audit recommends specifying a first-class CEL-owned **System Atlas** and **System Coherence Engine**. This is a design requirement, not a claim that these components already exist.

**System Atlas — continuously reconciled system model**
- Immutable/versioned inventory snapshots keyed to exact source commit, build/release and runtime instance.
- Nodes for applications, modules, services, processes, APIs, capabilities, stores, world owners, policies, tests and evidence.
- Typed edges for imports, calls, dependencies, supervision, publication/subscription, reads/writes, authorization, provenance, build artifacts and runtime execution.
- Each edge records declared/source-derived/runtime-observed/test-verified provenance separately.
- Ownership and authority metadata: canonical owner, permitted writers, approvers, consumers, recovery source and data classification.
- Incremental source/build/runtime ingestion plus periodic full reconciliation.
- Unknown, stale, contradictory and unobserved states represented explicitly; never auto-promoted to healthy or connected.

**System Coherence Engine — continuous discrepancy analysis**
- Detect missing provider/consumer, dead API, unhandled event, unused/orphan module, duplicate service, duplicate canonical writer, incompatible schema/version, circular dependency, stale registry, false readiness, missing provenance, ungoverned mutation, untested adapter, failed recovery and unsupported capability.
- Rank findings by constitutional risk, state authority, criticality, blast radius and evidence strength.
- Generate a traceable repair proposal with affected graph nodes/edges, root cause, exact files/contracts, prerequisites, tests, migration/rollback and residual risk.
- Require Council/human approval for protected architecture, authority, canonical state, security, governance and self-modification changes.
- Apply only the approved bounded change through controlled execution; verify exact changed artifacts and independent tests; compare before/after atlas; rollback on failed postconditions.
- Record immutable finding → authorization → change → build/test → runtime verification → acceptance evidence.
- Re-scan after each repair and continue until no known discrepancy remains; unknown areas remain explicitly unresolved.

**Authority boundary:** CEL may continuously discover, analyze, prioritize and prepare repairs. It may automatically perform only explicitly pre-authorized, low-risk reversible operations within bounded policy. It must not alter the Constitution, Council authority, ACL/OAVL/CEL enforcement, canonical world ownership, human approval rules, or its own upstream authority. No repair may certify itself solely on its own generated evidence.

### 18.38.5 Minimum capability acceptance criteria

| ID | Acceptance requirement | Pass evidence |
|---|---|---|
| SA-01 | Enumerate both OTP applications, all configured apps, supervisors and children | Complete source + runtime inventory with unknowns and profile distinctions |
| SA-02 | Inventory all code modules, public entrypoints and executable capabilities | Exact-commit module/API map; implementation probes and test references |
| SA-03 | Map all dependencies and actual caller/callee edges | Static call graph plus runtime traces; declared-vs-observed discrepancy report |
| SA-04 | Map event paths end-to-end | Topic publishers, bus, store, subscribers, acknowledgements and resulting state |
| SA-05 | Map every canonical state store and writer | One authority owner per state aggregate; every writer and recovery path identified |
| SA-06 | Map governance and evidence boundaries | Every consequential action linked to actor, policy, approval, evidence and audit receipt |
| SA-07 | Detect incoherence and missing connections | Seeded known defects reliably detected with no false PASS on unknown evidence |
| SA-08 | Generate repair plans | Reproducible plan with root cause, impact, exact changes, tests and rollback |
| SA-09 | Enforce approval and execution boundary | Unauthorized, stale, replayed or out-of-scope approvals refuse without side effects |
| SA-10 | Independently verify repairs | Separate verifier proves build, tests, live connection and postconditions |
| SA-11 | Preserve system knowledge over time | Versioned atlas, drift history, finding lifecycle, immutable evidence and reproducible query |
| SA-12 | Operate continuously and recover | Scheduled/incremental scans, event-triggered reconciliation, crash recovery, stale-scan detection and resource budgets |

### 18.38.6 Runtime verification plan — not executed

1. Seed the atlas from the exact frozen source tree and both Mix projects; compare inventory against supervisor trees and registry declarations.
2. Introduce controlled test fixtures: an unregistered module, orphan provider, missing consumer, duplicate writer, unused event topic, schema mismatch, stale service PID and a no-op implementation. Confirm each is detected and classified correctly.
3. Start root and runtime applications separately and together; compare observed processes/edges to the source-derived atlas.
4. Kill a registered service and remove a subscriber; verify the atlas marks runtime connection/readiness stale or failed rather than still connected.
5. Change a capability declaration without implementation and implementation without declaration; verify drift detection.
6. Submit repair proposals with no approval, wrong actor, stale approval and changed effect; prove refusal.
7. Approve a bounded reversible test repair; verify exact artifact binding, isolated build/tests, independent runtime verification, post-repair rescan and rollback on induced failure.
8. Measure completeness, false-positive/false-negative rates, scan freshness, scan duration, resource cost and evidence reproducibility.

### 18.38.7 Checkpoint disposition

- New findings: **RL-339–RL-342**.
- Findings closed: **0**.
- Application source modifications: **0**.
- Runtime verification: **not performed**.
- The existing CEL registry and CapabilityGraph provide a foundation, but the inspected implementation does not demonstrate whole-system awareness or closed-loop coherence repair.
- System Atlas and System Coherence Engine are recorded as required architectural capabilities, not as implemented systems.
- ToolForge remains part of the Tiannara system inventory and must be represented in the Atlas, including its supervisor, callers, generated-tool execution, review/approval and deployment boundaries.
- The next checkpoint must inspect the existing codebase for equivalent system inventory, architecture graph, self-diagnosis, repair orchestration and verification components before proposing any new implementation or duplicating existing work.

**Next checkpoint:** 18.39 — repository-wide discovery of existing system-atlas, introspection, coherence, self-diagnosis, repair-planning and verification capabilities; map them to CEL callers and evidence, then determine the smallest gap-closing architecture.


## Checkpoint 18.39 — Existing system awareness, cybersecurity, governance and self-modification inventory

**Frozen application source:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Method:** Recursive Git tree inventory (26,142 files; tree response not truncated), filtered source paths under root `lib/` and `tiannara_runtime/lib/`, followed by exact-file inspection of selected CEL, Sentinel, ASC immunity/incident response, repair, Council and self-improvement modules. This is a targeted source audit, not a full implementation/callsite audit of all 5,148 broadly named paths. No runtime execution or source modification.

### 18.39.1 Architectural responsibility model

CEL and related governance/execution/audit/security systems collectively need four continuous responsibilities:

- **System awareness and coherence:** know all applications, components, interfaces, dependencies, state authorities, runtime instances, policy boundaries and evidence paths; detect drift, disconnection, incoherence and missing capability.
- **Cybersecurity and system immunity:** prevent compromise; detect malicious/unauthorized activity, exploitation, tampering, privilege escalation, data exfiltration and integrity failures; preserve forensic evidence; contain/quarantine affected components; recover safely and verify.
- **Governed self-modification:** observe improvement opportunities, diagnose root causes, formulate proposals, generate bounded changes, test in isolation, verify adversarially and independently, obtain approval, execute through controlled effects, monitor canary/rollout, rollback and preserve full lineage.
- **Independent assurance:** verify that the security/governance/repair mechanisms themselves remain intact and cannot silently suppress alerts, rewrite policy, falsify evidence, disable monitoring or alter their own authority.

These are system responsibilities, not a claim that one CEL process should own every security decision or hold unrestricted privileges. Separate enforcement and verification authorities are required.

### 18.39.2 Existing source components discovered

The frozen tree contains substantial candidate systems. Their names and documentation do not establish production readiness or integration.

| Area | Existing source candidates | Initial evidence-based assessment |
|---|---|---|
| CEL executive/capability awareness | `Tiannara.CEL.Kernel`, Kernel.ServiceRegistry, CEL.CapabilityRegistry, CEL.Services.CapabilityGraph | Executive service registry and capability/provider/mission graph exist. Scope remains narrower than whole-repository/system/runtime awareness (RL-339–341). |
| Security observation and anomaly detection | `Tiannara.Sentinel.AnomalyDetector`, telemetry anomaly detectors, Sentinel monitors, ASC Agency Sentinel | Sentinel anomaly detector accepts telemetry but the inspected concrete detector clauses cover only three named subsystem/signal combinations (MSCL pressure, GRCC diversity, CTL consistency); unmatched signals return `:none`. This is not evidence of broad cyber threat detection. |
| Immune coordination | `Tiannara.Sentinel.ImmuneCoordinator`, `Tiannara.ASC.Immunity.EpistemicThreat`, `Tiannara.ASC.SelfModel.SystemicRiskScanner` | Threat/risk data structures and macro-risk scanner exist. ImmuneCoordinator's inspected shadow test uses a random score; observe-only returns 1.0; live intervention and quarantine functions only log and return `:ok`. Not an operational containment mechanism. |
| Incident response and rollback | `Tiannara.ASC.Reality.IncidentResponseEngine`, `RollbackEngine` | Incident engine tracks deployment monitors/alerts in process memory and calls rollback for critical alerts. RollbackEngine's snapshot/history are in-memory; rollback records completion but inspected code does not restore captured runtime state (capture contains only deployment ID/time/version). |
| Self-modification governance | `Tiannara.ASC.Governance.SelfModificationGovernor` | File-prefix denylist protects a few namespaces; otherwise returns `:allow`. Not a comprehensive path canonicalization, identity/effect-bound authorization, immutable protected-surface inventory or Council approval workflow. |
| Self-improvement pipeline | `Tiannara.SelfImprovement.Pipeline`, Proposal, GateResult, ProtectedCore | Pipeline defines stages and requires tests, benchmark, adversarial validation, constitutional review and human approval; protected-core change requires an independent verification GateResult from a non-self-improvement source. Deployment disabled by default. This is a useful policy/model contract, not evidence of a connected production change pipeline. |
| Sandbox | `Tiannara.SelfImprovement.Sandbox.Harness` | Applies a supplied function to a copied baseline state and runs supplied assertions/benchmark. It does not itself demonstrate OS/container isolation, arbitrary repository patch application, dependency/network isolation, resource limits or execution of the real generated code artifact. |
| Repair | `Tiannara.ASC.Crucible.Repairer`, RepairReuseEngine, ASC.Repair.Pipeline | Repair ecosystem and pattern reuse exist. Repairer source includes random 40% pattern matching, probabilistic repair outcomes, synthetic patched-artifact result and deploy path; ASC.Repair.Pipeline explicitly returns unavailable for root-cause analysis, patch generation, sandbox validation, canary and production rollout. Existing fail-closed unavailability is preferable to false success, but no complete production repair path is established. |
| Governance and authorization | `Tiannara.Council.Authorization`, Council, AuditLog, HumanApprovalQueue, Omega authority/effect components | Meaningful authorization and governed-effect primitives exist. The previously recorded cross-system findings still apply: enforcement is selective and no universal end-to-end gate is established. |
| Independent audit and verification | `Tiannara.Sentinel.Verification`, audit modules, OAVL, Omega verification and authority verifiers | Multiple verification/audit components exist. Their full independence, coverage, deployment wiring and ability to audit their own enforcement plane remain to be proven. |
| System self-model and risk | `Tiannara.ASC.SelfModel.CivilizationGraph`, SystemicRiskScanner; architecture/dependency registries and graphs | Self-model and macro-risk scanning exist, but the inspected scanner consumes a supplied CivilisationGraph and its epistemic blindspot check is explicitly a placeholder. No proof it continuously derives a complete live system model. |
| Tool creation and evolution | ToolForge, ASC evolution, repair ecology, capability evolution | These remain within Tiannara scope. ToolForge's known findings RL-174–177 remain open; its generated tool execution, review, registration, deployment and security boundaries must be included in the complete map. |

### 18.39.3 New findings

**RL-343 — Sentinel's inspected anomaly detector is not a general cybersecurity detection system.**  
The source documents telemetry anomaly detection across subsystems, but the concrete `detect_anomaly/3` clauses inspected cover only three hard-coded signal patterns and all other inputs return `:none`. The separate observation-vs-prediction detector is statistical deviation analysis, not by itself detection of authentication abuse, exploit attempts, malicious code, privilege escalation, secret access, data exfiltration, supply-chain compromise or tampering. A complete cybersecurity sensor/telemetry/threat-model coverage map is not established. Static source-confirmed for this module; other security detectors require separate audit.

**RL-344 — Sentinel ImmuneCoordinator's apparent shadow validation and quarantine do not perform real containment.**  
The inspected implementation creates a shadow ID string, uses a random confidence score (or 1.0 for `:observe_only`), and its live intervention/quarantine helpers only log and return `:ok`. A high score triggers a nominal live-intervention log; a low score triggers a nominal quarantine log. No actual isolation, access revocation, process/network containment, forensic capture or post-containment verification is implemented in this path. Static source-confirmed.

**RL-345 — Incident rollback is not demonstrated to restore the affected system.**  
IncidentResponseEngine triggers RollbackEngine on critical anomaly, but RollbackEngine's inspected snapshot is an in-memory map with minimal metadata; rollback selects a snapshot and appends a `:completed` record without applying restored artifacts or state. Thus a reported rollback completion is not proof of recovery. This is separate from earlier snapshot/history findings and needs integration/runtime proof. Static source-confirmed.

**RL-346 — SelfModificationGovernor's path-prefix denylist is not a sufficient protected-core authorization boundary.**  
The governor protects only a short list of path prefixes and returns `:allow` for other paths. The inspected function does not canonicalize paths, resolve symlinks, normalize traversal, classify transitive effects, bind actor/authorization to an exact patch digest, consult Council, or require independent verification. Its protected list also differs in representation/scope from SelfImprovement.ProtectedCore's subsystem atoms. It cannot serve as the sole authorization boundary for self-modification. Static source-confirmed.

**RL-347 — SelfImprovement pipeline gate results are caller-supplied data, not independently authenticated attestations.**  
Pipeline.request_deployment/3 accepts a proposal and arbitrary gate_results map; it checks struct fields such as `%GateResult{passed: true}` and a non-nil independent-verification source not equal to `:self_improvement`. The inspected contract does not verify signatures, verifier identity/trust, artifact digest, test-run identity, freshness, scope, replay protection or that evidence actually corresponds to the exact patch being deployed. Human approval is likewise represented as a gate result in this function. The deployment flag defaults false, which is a safe default, but the gate representation alone does not establish a secure approval/evidence chain. Static source-confirmed.

**RL-348 — SelfImprovement.Sandbox is a pure state-transform harness, not a demonstrated isolated code-execution sandbox.**  
The harness applies a supplied function to a baseline state and runs supplied assertions and a benchmark. The inspected path does not create an OS/container boundary or demonstrate filesystem, process, network, credential, resource and syscall restrictions for untrusted generated code. It also does not itself bind results to a repository patch/build artifact. It must not be treated as sufficient containment for arbitrary self-modifying code. Static source-confirmed for this harness.

**RL-349 — Existing repair components do not establish an end-to-end safe production self-repair pipeline.**  
ASC.Repair.Pipeline explicitly fails closed as unavailable for root-cause analysis, patch generation, sandbox validation, canary release and production rollout. The separate Repairer contains random pattern matching and probabilistic/synthetic repair/deployment outcomes. Therefore neither can be credited as an end-to-end evidence-backed production repair route from the inspected source. Static source-confirmed for these paths; other repair routes require caller and runtime audit.

### 18.39.4 Security and self-modification target architecture

The audit establishes the following required separation of duties:

1. **CEL System Atlas and Coherence Engine:** system inventory, connection map, drift/coherence analysis, security asset/dependency map and orchestration of findings.
2. **Security enforcement plane:** identity, authentication, authorization, least privilege, secrets management, secure configuration, input validation, dependency/supply-chain controls, network/process isolation, integrity protection and policy enforcement at every consequential effect.
3. **Sentinel detection plane:** host/application/API/network/dependency/build/runtime telemetry, behavior baselines, threat intelligence where available, anomaly and rule/signature detection, tamper detection and alert correlation.
4. **Immune/incident response plane:** preserve evidence first where safe, classify/contain/quarantine, revoke credentials/tokens, isolate affected workloads, protect canonical state, recover from verified clean checkpoints and validate restoration. Destructive or broad actions must be bounded and governed.
5. **Council/governance plane:** immutable policy/constitution, actor identity, exact effect-bound grants, approval thresholds, two-person or independent approval for critical changes, revocation and audit logging.
6. **Self-modification execution plane:** proposal → exact patch digest → dependency/impact analysis → isolated build/test → adversarial/security tests → independent verification → constitutional/Council review → human approval where required → one-shot authorized deployment → canary → continuous monitoring → rollback/recovery.
7. **Independent audit plane:** verifier separate from generator/executor; inspect authorization, exact artifact, build provenance, test evidence, runtime effects, policy integrity and post-change system atlas. No self-certification of protected controls.
8. **Meta-security and meta-governance:** monitor the monitors, authorization registries, audit logs, policy stores, signing keys, update mechanisms and recovery paths. Security controls must have protected roots of trust and independently observable tamper signals.

### 18.39.5 Non-negotiable self-modification and cyber-safety invariants

- Constitution, Council supremacy, ACL/OAVL/CEL authority boundaries and protected audit/security roots cannot be rewritten by the subsystem they constrain.
- Generated code cannot possess deployment authority merely because it can generate or test a candidate.
- Every executable change is bound to exact source/patch/build hashes and a one-time, scope-limited authorization.
- Approval cannot be replayed, transferred to a different artifact, widened in scope or reused after expiry/revocation.
- Tests and verification must be independent of the generator and execution path for protected or high-impact changes.
- Runtime enforcement must re-check authorization at the terminal effect, not only at proposal time.
- Unknown, missing, stale or contradictory security evidence means UNKNOWN/blocked for high-impact operations, never PASS.
- Incident containment must preserve forensics and avoid destroying the only valid recovery source.
- CEL/Sentinel/repair systems cannot disable or suppress their own watchdog, audit, alert, authorization or rollback mechanisms.
- Self-improvement is permitted within bounded authority; changes to governance, security roots, identity, canonical state or self-modification controls require independent authority and human/Council governance.
- All repairs are followed by a whole-system coherence and security rescan.

### 18.39.6 Checkpoint disposition

- New findings: **RL-343–RL-349**.
- Findings closed: **0**.
- Existing candidate systems found: extensive Sentinel, ASC immunity, incident response, Council, OAVL, self-improvement, sandbox, repair, audit and verification modules.
- Production cybersecurity capability: **not established** by this targeted inspection.
- Production self-modification capability: **not established**; a fail-closed self-improvement contract exists, but evidence binding, isolated execution, deployment integration and independent verification require deeper audit.
- Runtime/security tests: not performed.
- Source modifications: 0.
- ToolForge remains in scope for both system-awareness and cybersecurity/self-modification threat analysis.

**Next checkpoint:** 18.40 — trace actual startup ownership, callers and enforcement paths for Sentinel, immune coordination, incident response, Council authorization, self-improvement, repair, OAVL and audit/verification. Determine which components are live, dormant, duplicated, bypassable or disconnected before designing any replacement.


## Checkpoint 18.40 — Integration and authority tracing

**Frozen application source:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Ledger branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Method:** Exact-file source inspection and repository code-search for startup registration, callers and enforcement paths across root `lib/` and `tiannara_runtime/lib/`. No runtime tests, exploit attempts or source modifications. This is static callsite/startup evidence; it does not claim a complete runtime security assessment.

### 18.40.1 Startup and monitoring integration

- Root `Tiannara.Application.core_children/0` starts `Tiannara.Council.Supervisor`, `Tiannara.Sentinel.Supervisor`, `Tiannara.Sentinel.SentinelRuntime`, `Tiannara.Autonomy.ConstitutionalAutonomy` and `Tiannara.Omega.OmegaRuntime`.
- `Tiannara.Sentinel.Supervisor` supervises `AnomalyDetector` and `ImmuneCoordinator`.
- `Tiannara.Sentinel.SentinelRuntime` separately supervises ObservationBuffer, PatternDetector, AnomalyClassifier, PriorityEngine and ObservationScheduler.
- The live `SentinelBridge.build_heartbeat_opts/1` is wired into `Tiannara.Omega.Supervisor`, which starts `Sentinel.Heartbeat.Server` and the Ω event/agency pipeline. However, the root `Tiannara.Application` starts `OmegaRuntime`, not `Omega.Supervisor`. `Tiannara.Omega.Supervisor` has a separate `Tiannara.Omega.Application` entry point and is also started by scripts/tests. The root application's child list therefore does not establish that this heartbeat bridge and its terminal GovernanceGate are active in the same production tree.
- The source shows multiple monitoring architectures, but their relationship, duplicate coverage, event routing and common security authority are not established.

### 18.40.2 Council and authorization enforcement

Positive evidence:
- Council is a root-supervised service. Its `authorize/3` path consults PolicyRegistry and RuleEngine; the latter checks hard invariants including human final authority, no self-amendment and audit-log immutability.
- CEL Kernel's `restart_service/2` and `halt/2` explicitly consult `Council.authorize/3` and use strict grant predicates.
- `TiannaraOS.Governance.CapabilityChecker` checks institutional domain authority, capability and active status; `verify_actor_authorization/4` additionally checks that an actor is a listed member.

Negative enforcement evidence:
- `Council.lift_emergency/1` accepts a caller-supplied `human_id`; the handler records that value but performs no identity, credential, signature, quorum or independent approval check before clearing emergency state.
- `ConstitutionRepository.commit/3` and `rollback/2` are direct GenServer APIs. Their handlers write/select the active constitution version without invoking Council authorization, actor verification, quorum or human approval.
- `PolicyRegistry.register_policy/1` and `disable_policy/1` directly mutate the live policy map without an authorization check in their handlers.
- The CapabilityChecker is a separate capability API; the inspected Council, ConstitutionRepository and PolicyRegistry mutation handlers do not call it. The inspected CEL kernel uses Council for restart/halt, but its public `transition/1` handler changes executive runtime state using only a transition-validity check.
- These are local in-node APIs, not proof of an externally reachable remote exploit. They do establish that the source does not enforce the same identity/effect-bound authorization boundary at these mutation endpoints.

### 18.40.3 Self-modification and ToolForge

- Repository code search found one production source caller of `SelfModificationGovernor.authorize_patch/1`: `Tiannara.ASC.Civilization.Specialists.Auditor.audit/2`. The governor checks a small path-prefix denylist and otherwise returns `:allow`; it receives only a target path, not actor identity, exact patch digest, requested effects or Council grant.
- ToolForge's engine runs design → build → minimal non-empty/name validation → `request_human_review/2`. That function constructs `Tiannara.HAI.Domain.ReviewRequest`, ignores its return value and returns `:ok`; exceptions are rescued and also return `:ok`. The engine consequently treats request construction as "Human review passed" and returns the generated tool.
- The ToolForge path inspected does not call Council, CapabilityChecker, OAVL or SelfModificationGovernor. `ToolBuilder.build_to_disk/2` exposes a direct file-writing API; no production caller was found in code search. Generated tools are not automatically deployed by the inspected engine (`tools_deployed` is initialized but not incremented in the inspected paths).
- Root startup gates ToolForge behind `asc_enabled?/0`, but feature-flag gating is not per-artifact authorization or execution isolation.

### 18.40.4 Audit and evidence integrity

- Council AuditLog implements DETS persistence, SHA-256 previous-entry chaining, chain verification and periodic Merkle-root calculation. This is a meaningful integrity mechanism.
- AuditLog explicitly enters degraded mode when storage cannot be opened/recovered; appends then return `{:error, :storage_degraded}`.
- The Council emergency handler ignores the result of `AuditLog.append/3` and still returns `:ok` after activating emergency state. CEL Kernel's `log_to_council/2` catches failures and returns `:ok`. Thus durable audit success is not a mandatory precondition for these recorded operations.
- No independent external anchoring or separately administered integrity monitor for the Council log was established by this checkpoint.

### 18.40.5 OAVL and ACL scope

- The Elixir `Tiannara.OAVL.DiscoveryVerifier` explicitly describes itself as a discovery-coherence scorer, not an effect authorization gate; it returns the original discovery unchanged.
- The Python `tiannara_core/defense/oavl.py` combines a policy check and alignment scorer with keyword-based cross-ontology/stabilizer heuristics. It is a text/concept evaluation path, not demonstrated runtime process, filesystem, network, credential or deployment enforcement.
- The institutional CapabilityChecker is a real local check, but its presence does not demonstrate universal mediation of the above mutation and execution APIs.
- Therefore neither OAVL nor ACL can currently be credited as a universal security reference monitor for Tiannara's consequential effects.

### 18.40.6 New findings

**RL-350 — Sentinel heartbeat integration is not established in the root application boot path.**  
The root application starts Sentinel.Supervisor and SentinelRuntime, but the SentinelBridge-backed Heartbeat.Server is a child of the separate Omega.Supervisor. Root startup starts OmegaRuntime instead. The distinct Omega application entry point and script/test startup paths do not prove that the heartbeat/agency/GovernanceGate tree is active alongside the root application in production. Multiple monitoring paths exist, but a single verified end-to-end security event path is not established.

**RL-351 — Council authority can be bypassed at direct governance mutation endpoints.**  
The emergency-lift handler trusts a supplied human identifier without authenticating it. ConstitutionRepository commit/rollback and PolicyRegistry register/disable handlers perform state mutation without Council authorization or CapabilityChecker actor verification. These local APIs provide mutation paths outside the intended governance gate. This finding concerns source-level enforcement boundaries; remote exploitability and deployment exposure remain unassessed.

**RL-352 — CEL Kernel exposes an executive state-transition API without Council authorization.**  
`transition/1` accepts a requested state and checks only `RuntimeStates.valid_transition?/2`; unlike restart and halt, it does not consult Council. The effect is limited to the kernel's recorded runtime state in the inspected handler, but it is still an ungoverned executive control surface.

**RL-353 — ToolForge's human-review step is not an approval gate.**  
The inspected ToolForge pipeline constructs a ReviewRequest but does not enqueue it, await a human decision, verify a grant or bind approval to the generated artifact. It returns `:ok` even when request construction raises. ToolForge does not invoke Council or SelfModificationGovernor in the inspected path. Generated-tool build success must not be interpreted as approval or deployment authorization.

**RL-354 — SelfModificationGovernor is not a system-wide self-modification enforcement point.**  
The only source caller found is the ASC Auditor. The governor accepts only a target path and uses a limited string-prefix denylist; ToolForge and the inspected direct disk-writing API do not call it. It cannot currently be credited with mediating every self-modification or generated-code effect.

**RL-355 — Durable audit evidence is not mandatory for all consequential governance operations.**  
AuditLog fails closed for its own append when degraded, but Council emergency activation ignores append failure and CEL Kernel logging catches failures. Thus an operation can report success without a durable audit record. Hash chaining is useful but does not, by itself, prevent privileged mutation of the log store or provide independent external anchoring.

**RL-356 — OAVL and institutional ACL are not demonstrated as universal runtime effect guards.**  
The inspected OAVL implementations evaluate discovery/concept coherence; neither is shown mediating process, filesystem, network, credential, policy-store or deployment effects. CapabilityChecker provides useful institution/domain/capability checks, but the inspected Council mutation and ToolForge execution paths do not invoke it. Universal enforcement remains unproven.

### 18.40.7 Direct answer to the critical test

| Threat question | Source-backed answer at this checkpoint |
|---|---|
| Can a subsystem disable or bypass Sentinel? | No general production exploit was executed. Monitoring is split across independently started trees; the source does not establish a protected, independently watched Sentinel root or universal authorization on monitor-control APIs. |
| Can a subsystem bypass Council? | **Yes, at specific local API boundaries:** constitution commit/rollback, policy register/disable and emergency lift do not authenticate/authorize the caller in their inspected handlers. |
| Can a subsystem manipulate CEL's understanding? | CEL's earlier registry/system-awareness limitations remain open. This checkpoint also finds an ungoverned runtime-state transition API. Whole-system inventory integrity and independent observation are not established. |
| Can a subsystem alter its own code without independent authorization? | ToolForge's reviewed path does not invoke Council or SelfModificationGovernor, and its human-review helper returns success without obtaining approval. This establishes an unsafe source-level gate, not proof that an arbitrary actor can deploy code in a live environment. |
| Can it suppress or falsify audit evidence? | AuditLog has hash-chain checks, but audit failure does not block all consequential operations; external anchoring and independent protection of the log store are not established. |

### 18.40.8 Disposition

- New findings: **RL-350–RL-356**.
- Findings closed: **0**.
- Source modifications: **0**.
- Runtime tests or exploit attempts: **not performed**.
- Root application startup: Council, Sentinel.Supervisor, SentinelRuntime and OmegaRuntime are statically registered.
- SentinelBridge heartbeat tree: separate Omega.Supervisor entry point; production co-start not established.
- Council: meaningful authorization machinery exists, but direct mutation APIs lack consistent caller authentication and authorization.
- ToolForge: build pipeline is present; human review is not an enforced approval gate in the inspected path.
- AuditLog: cryptographic chain verification exists, but durable audit success is not required by all inspected operations.

**Next checkpoint:** 18.41 — trace incident response and containment callers, self-improvement pipeline exact-artifact/evidence handling, protected-core checks, independent verifier trust, and repair/rollback effect execution. Then trace all production callsites that can write files, alter policy/constitution, start/stop processes, deploy generated code or change runtime authority. Keep every finding open until exact effect-path evidence proves remediation.


## Checkpoint 18.41 — Incident response, recovery and self-modification execution

**Frozen application source:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Method:** Exact-file inspection of incident response, rollback, self-improvement, sandbox backends, Phase-4 real execution, deployment gateway, adoption and repair components; repository-wide caller searches. No runtime tests, exploit attempts or source modifications.

### 18.41.1 Incident response and recovery

- Root `Tiannara.Application` starts `ASC.Reality.Supervisor` only when `asc_enabled?/0` is true. That supervisor starts `IncidentResponseEngine` and `RollbackEngine`; therefore these services are not guaranteed to run in the default ASC-disabled configuration.
- `IncidentResponseEngine.report_anomaly/3` is a public cast API. Its handler records an alert in process memory, classifies a fixed set of anomaly atoms and calls `RollbackEngine.rollback/1` for critical alerts. Repository code search did not surface a production caller of `report_anomaly/3`; source-level invocation from Sentinel or the root security event path is not established.
- `RollbackEngine.create_snapshot/1` captures only deployment ID, timestamp and a version timestamp; its declared artefacts are labels (`:runtime_config`, `:active_connections`, `:data_state`), not captured bytes or restorable state. Snapshots and rollback history are in-memory.
- `RollbackEngine.rollback/2` selects a snapshot and appends a record with `status: :completed` and `restored_artefacts`; it does not restore files, configuration, connections or data.
- `Reality.Director.rollback/1` updates deployment status to `:rolled_back` even though the rollback engine result may be an error or a success-shaped record without restored effects.
- The separate `Tiannara.Autonomy.RollbackEngine` path was already recorded in the prior remediation inventory as explicitly unavailable; it must not be confused with the Reality rollback module.

### 18.41.2 Self-improvement pipeline and real sandbox capabilities

The earlier inventory requires refinement: a real-code sandbox infrastructure does exist.

- `SelfImprovement.Sandbox.RealHarness` copies a baseline, applies a code patch, runs build/tests/benchmark commands and tears down the environment.
- `Sandbox.Backend.Local` runs real subprocesses in a temporary copied worktree with timeouts. It is not an OS security boundary; subprocesses run with the host user's privileges.
- `Sandbox.Backend.Container` runs commands in Docker/Podman with `--network none` by default, CPU and memory limits, and a wall-clock timeout. This is stronger isolation than the abstract state-transform Harness, but the inspected command does not establish a read-only root filesystem, dropped capabilities, non-root identity, PID limits, seccomp/AppArmor profile or protection of the host-side patch-application phase.
- `Sandbox.Backend.CI` is an injectable remote-CI contract, not proof of a configured CI provider.
- The backends are invoked by dry-run APIs (`SelfImprovement.DryRun`, `Omega.DryRun`) and tests. Repository search did not establish a supervised production self-improvement executor invoking RealHarness and then a deployment sink.
- The generic `SelfImprovement.Pipeline` remains an authorization contract: it accepts caller-supplied GateResult structs, checks their `passed` fields and a non-self-improvement source label for protected-core verification, and returns `:deployment_authorized` when explicitly enabled. It does not execute a patch or authenticate/bind the supplied gate evidence to the patch digest.

### 18.41.3 A stronger, separate Phase-4 governed execution path

A significant positive discovery is `Tiannara.Phase4.RealExecution` and `Omega.DeploymentGateway`.

- `Phase4.RealExecution.execute/1` requires `real_execution_enabled: true`, an Authorization struct, a configured backend/baseline/patch/specification, and admission through `Phase4.ExecutionGovernance.begin/2`.
- ExecutionGovernance derives a canonical effect identity, checks grant status and expiry, checks durable MintRegistry registration and binding, atomically claims/consumes a one-shot grant and records a fail-closed Council AuditLog edge.
- The real execution path fingerprints the patch term into the canonical effect descriptor, runs RealHarness and records execution/provenance information.
- Optional deployment is routed through `Omega.DeploymentGateway.deploy/6`. The gateway checks candidate approval, certification, lineage, grant, authenticated identity, candidate immutability, durable mint registration, effect binding, single-use consumption and a fail-closed audit append before transitioning the candidate to deployed.
- `Phase4.ExperimentOrchestrator.submit_experiment/1` delegates to RealExecution when the feature flag is enabled. The inspected source does not establish that this orchestrator is registered in the root application's supervised production tree; its caller/startup path needs a separate closure check.
- This is meaningful evidence of a stronger governed effect path. It does not make the generic SelfImprovement.Pipeline, ToolForge or every other file/deployment sink inherit those protections automatically.

### 18.41.4 Controlled adoption path

`ASC.Adoption.Adopter` is another meaningful, bounded mechanism:

- Requires a machine evidence record with `verdict: :accept_eligible` and candidate on the declared front.
- Requires a human authorization artifact with exact mission, candidate, branch, decision, date and human fields.
- Requires execution from `main`, checks the branch and exact declared diff scope, snapshots files and creates a rollback tag before applying the selected branch files.
- Runs compile, scoped tests and a boot smoke; on validation failure it invokes rollback.
- This is a manually invoked, narrowly scoped adoption workflow, not universal runtime self-modification governance. The authorization file is structurally validated but the inspected parser does not cryptographically authenticate the named human or signed approval artifact.

### 18.41.5 Repair paths

- `ASC.Repair.Pipeline` now explicitly returns `{:error, :unavailable}` for root-cause analysis, patch generation, sandbox validation, canary release and production rollout. This is honest fail-closed behavior, not a false claim of repair success.
- `ASC.Crucible.Repairer` remains a separate path. Its pattern match uses random selection; repair success/regression are randomly sampled and the patch result is a synthetic `"patched_artifact"` string. It records telemetry/observations and can register a repair pattern, but the inspected apply path does not modify the supplied artifact.
- `RepairReuseEngine` and campaign callers exist, but no evidence from this checkpoint establishes a secure production chain from diagnosis through patch generation, isolated execution, approval, deployment and verified recovery.

### 18.41.6 New findings

**RL-357 — Incident-response alert ingestion is not connected to the monitored security event path.**  
The Reality IncidentResponseEngine exposes `report_anomaly/3`, but repository caller search did not surface a production caller from Sentinel, CEL or another root security event path. It is also supervised only when ASC is enabled. The engine's in-memory alert handling and critical rollback trigger therefore do not establish a continuously active, system-wide incident response service.

**RL-358 — Reality rollback reports completion without restoring captured system state.**  
The snapshot stores only metadata and artefact labels; rollback writes a `:completed` history record without restoring actual deployment files, configuration, connections or data. Reality.Director can mark a deployment `:rolled_back` without validating restoration. This is a false recovery signal, not a usable recovery mechanism.

**RL-359 — Real sandbox backends exist, but patch application is not confined to the sandbox directory.**  
Both Local and Container backends apply `CodePatch.files` by joining caller-supplied relative paths to the host temporary workdir and writing them without canonicalizing the result or checking that the resolved path remains beneath the workdir. A path containing traversal segments can therefore escape the intended workspace during the host-side patch-application step; this occurs before containerized build/test execution. The Local backend also runs arbitrary commands as the host user. The Container backend has useful network/resource controls but does not protect the host patch-application step. Treat untrusted generated patches as unsafe until path containment and stronger isolation are enforced.

**RL-360 — Real self-improvement evaluation is disconnected from general deployment authorization.**  
RealHarness and Local/Container backends are real evaluation capabilities, but their general self-improvement callers are dry-run paths. The generic Pipeline accepts unverified caller-supplied GateResult structs and does not execute or deploy the exact evaluated artifact. Phase4.RealExecution/ExecutionGovernance/DeploymentGateway provide a stronger, separate governed execution route, but the inspected code does not make that route mandatory for all self-modification sinks. The system therefore has two materially different assurance levels rather than one universal change-control path.

**RL-361 — Two-key adoption validates human approval fields but does not authenticate the human artifact.**  
ASC Adoption checks exact scope, machine evidence and required human authorization fields, and performs compile/test/boot validation with rollback. However, the inspected Gate parser treats the `HUMAN` field as text and does not verify a cryptographic signature, authenticated identity or independently issued approval token. This is a useful procedural gate but not cryptographic proof of human authorization.

### 18.41.7 Revision to earlier findings

- **RL-348 is refined, not closed.** The abstract Harness is not arbitrary-code isolation, but RealHarness plus Local and Container backends do provide real code evaluation, with the Container backend applying meaningful network and resource controls. RL-359 records the newly identified host-side patch path escape and remaining isolation gaps. Neither backend has been runtime-tested in this checkpoint.
- **RL-347 remains open.** Phase4 ExecutionGovernance demonstrates stronger exact-effect-bound grant handling in a separate execution path, but it does not authenticate the generic SelfImprovement Pipeline's caller-supplied gate attestations.
- **RL-345 remains open.** The Reality rollback engine is explicitly non-restorative. The separate Autonomy rollback path reports unavailable rather than fabricating restoration.
- No findings were closed.

### 18.41.8 Disposition

- New findings: **RL-357–RL-361**.
- Findings closed: **0**.
- Source modifications: **0**.
- Runtime tests and exploit attempts: **not performed**.
- Real sandbox: implemented; production self-improvement integration not established.
- Strong effect-bound deployment gateway: implemented in the separate Phase-4/Omega path; universal adoption not established.
- Two-key adoption: implemented as a manual bounded workflow; cryptographic human identity proof not established.
- Incident response and rollback: not established as operational system-wide containment and recovery.

**Next checkpoint:** 18.42 — security boundary and tamper-resistance audit. Trace the complete root startup and service registry for Phase4, Omega and ASC; inspect MintRegistry ownership and persistence, human identity authentication, DeploymentGateway's terminal state mutation, adoption rollback correctness, and all host-side file/process/network effects. Specifically test by static reasoning and then isolated tests whether path traversal, symlink traversal, stale grants, registry restart, process restart or audit-store failure can bypass the intended boundaries. Do not run destructive tests against the working repository.


## Checkpoint 18.42 — Security boundary and tamper-resistance audit

**Frozen source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Audit ledger branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Method:** source inspection and call-path tracing only. No source files were modified; no destructive or live exploit tests were run.

### 18.42.1 Findings that materially strengthen the current picture

- `Tiannara.Omega.MintRegistry` implements a durable event file for mint, bind and consume records and reconstructs state at process startup. Its client API refuses when the named GenServer is unavailable, and its documented corrupt-file behavior is fail-closed (previous grants become unavailable rather than being admitted). It also records effect binding and checks registry/struct agreement.
- MintRegistry's minter check restricts registration to an allowlist of originating modules based on the in-node call stack. The source explicitly describes this as an in-node trusted-code boundary, not a cryptographic capability. A compromised allowlisted module or sufficiently privileged code in the same BEAM node remains outside this protection.
- `ExecutionGovernance.begin/2` checks grant status and expiry, requires registry registration, binds the grant to a canonical effect identity, claims a node-local ETS effect key and consumes the grant before execution. Its audit helper treats failed or unexpected audit append results as errors.
- `DeploymentGateway` has a distinct candidate deployment transition and checks candidate status, certification shape, non-empty lineage, grant/candidate match, expiry, identity/grant human-ID match, candidate content hash, durable registry registration, effect binding, one-shot consumption and audit append. This is materially stronger than a simple approval flag.
- These are implemented mechanisms in source, not proof that all production paths start them, that all sinks use them, or that the durable storage is protected from a compromised host/process.

### 18.42.2 New findings

**RL-362 — Human identity authentication accepts any non-empty string as a credential.**  
In `AuthenticatedHumanIdentity.authenticate/3`, the inspected credential validator accepts any non-empty binary; it does not compare the credential to an account-specific secret, verify a password hash against an identity store, validate a signature, or call an external identity provider. `authenticated?/1` checks only that `authenticated_at` is non-nil. Therefore the struct's name and timestamp do not establish proof that the claimed human actually authenticated. DeploymentGateway's identity/grant ID comparison is useful but depends on this weak identity constructor. This is source-confirmed; no runtime impersonation test was run.

**RL-363 — Durable authorization records are not demonstrated to be tamper-resistant against host-level or same-node compromise.**  
MintRegistry appends size-prefixed records and rebuilds in-memory state on restart, which provides persistence and replay-state continuity. The inspected code and module contract do not establish cryptographic signatures/MACs over each record, an independently protected external anchor, restrictive filesystem ownership/permissions, or detection of a validly encoded file being rewritten by a process with write access. Hash-chained Council AuditLog is a separate mechanism and is not, by itself, proof that the MintRegistry file cannot be altered. Status: integrity protection and host permissions remain unverified, not a claim that arbitrary file rewriting was successfully exploited.

**RL-364 — DeploymentGateway's public ETS mutex is not a security boundary.**  
The gateway creates a named public ETS lock table and serializes its local check/commit section using insert-new. Public ETS access permits other processes in the same node to alter or delete lock rows. The MintRegistry's serialized one-shot consume remains an independent and stronger at-most-once guard, so the mutex exposure alone does not prove duplicate deployment is possible; it does mean the mutex must not be treated as tamper-proof protection. Multi-node/distributed deployment semantics and restart behavior were not runtime-tested.

**RL-365 — Sandbox path traversal remains a confirmed host-side write boundary defect; symlink resistance is also unproven.**  
Both Local and Container backends write `Path.join(env.workdir, rel_path)` after creating parent directories, without canonicalizing the destination and checking containment beneath the workdir. The write happens on the host before container execution. Traversal segments can escape the intended workspace. The code also does not reject symlinked path components or demonstrate no-follow/descriptor-relative safe writes; symlink-based escape therefore remains a high-priority unverified variant. No exploit was executed.

**RL-366 — Real execution is not equivalent to successful certification or deployment.**  
`RealExecution.execute/1` records the sandbox verdict, then performs its audit gate and calls `maybe_deploy/3`; the return value from `maybe_deploy/3` is not used to determine the returned success-shaped execution result in the inspected branch. The returned map contains verification and sandbox data but does not clearly distinguish “evaluation completed” from “deployment committed” at its top level. Consumers must not interpret a successful execution response as proof that deployment succeeded. Exact sink behavior requires a follow-up caller/contract audit.

**RL-367 — Registry and audit restart/failure guarantees are only partially established.**  
MintRegistry source documents append-and-replay persistence and fail-closed behavior when unavailable/corrupt, while ExecutionGovernance and DeploymentGateway fail closed on audit append errors. However, this checkpoint did not run process-restart, power-loss/partial-write, registry-corruption, audit-store failure, or cross-node concurrency tests. It also did not establish that the registry/audit files are on durable storage with protected permissions or that all consequential operations route through these fail-closed APIs. These properties remain UNKNOWN until tested against a disposable isolated environment.

### 18.42.3 Boundary and coverage disposition

- **Strongest verified-by-source route:** Phase4 ExecutionGovernance + MintRegistry + Omega DeploymentGateway.
- **Identity root of trust:** not established; RL-362 is open.
- **MintRegistry persistence:** append/replay design present; tamper resistance and crash durability not independently tested (RL-363, RL-367).
- **Deployment terminal transition:** Candidate exposes a gateway-specific deploy transition; source indicates this route for that candidate type, but universal deployment-sink exclusivity across the whole repository has not been proven.
- **Sandbox:** real evaluation exists, but host-side traversal is a source-confirmed defect; symlink defenses and OS/container isolation remain incomplete/unverified (RL-365).
- **Generic self-modification / ToolForge / repair paths:** previous findings RL-353, RL-354, RL-359, RL-360 remain open; no universal shared enforcement root is established.
- **Root startup/service ownership:** application starts core supervisors and conditionally adds ASC children, but this checkpoint did not establish every Phase4/Omega executor is supervised and used by every production caller.
- **Audit failure:** specific governed paths contain fail-closed audit checks, but prior findings RL-351 and RL-355 remain open for other APIs that bypass authorization or ignore audit failures.

### 18.42.4 Status

- New findings: **RL-362–RL-367**.
- Findings closed: **0**.
- Source modifications: **0**.
- Runtime tests, exploit attempts, restart tests and fault injection: **not performed**.
- No production-readiness claim is made.

**Next checkpoint:** 18.43 — trace all deployment and file/process/network effect sinks against the actual startup graph; enumerate direct candidate state mutations and every `File.write`/`System.cmd`/deployment path; then design non-destructive tests in a disposable checkout for identity forgery, traversal/symlink containment, registry restart/corruption, audit-store failure and concurrent grant consumption. Keep the frozen source baseline unchanged and record every result here.


## Checkpoint 18.43 — Consequential effect-sink and production-call-graph audit

**Frozen source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Ledger branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Scope:** trace deployment, candidate-state, filesystem and process-execution sinks and map isolated tests. Source inspection only; no runtime/exploit tests or source modifications.

### 18.43.1 Production reachability: the strongest gateway is not proven to be the live deployment path

- `Omega.DeploymentGateway.deploy/6` calls `Candidate.deploy_transition/1`, which is the candidate module's only transition from `:approved` to `:deployed`. Generic `Candidate.transition/2` does not permit that transition.
- Repository call-map/search evidence identifies gateway use in adversarial verification scenarios and reports **zero production callers**. This means the gateway's strong checks are not evidence of a production deployment path being protected; it may be a well-designed but test-only enforcement boundary.
- `Phase4.ExperimentOrchestrator.submit_experiment/1` delegates to `RealExecution.execute/1` only when the real-execution flag is enabled, but service registration or supervision alone does not prove any production caller submits real experiments. A live end-to-end deployment chain remains unproven.
- `ASC.Adoption.Adopter.adopt/1` is reachable through the explicit Mix task `mix asc.adopt`; this is a bounded manual adoption path, distinct from the generic ToolForge/self-improvement paths.
- `Tiannara.BaseReality.Workspace.write_blueprints/2` writes validated synthesis artifacts to a configured workspace using sanitized filenames and exclusive file creation, and returns `source_control: :not_committed`. Its compatibility function `commit_blueprints/2` delegates to the same write-only behavior. This path is not itself a production deployment/commit sink.

### 18.43.2 New findings

**RL-368 — DeploymentGateway's production exclusivity is not established; current call-map evidence says it has zero production callers.**  
Candidate's `:approved → :deployed` transition is structurally restricted to `deploy_transition/1`, and the gateway has meaningful checks. But repository call-map evidence locates its callers in adversarial test scenarios only, with no production callers. Thus source supports a test-enforced transition boundary, not a demonstrated operational deployment gateway. The exact full-repository search at the frozen baseline and runtime caller telemetry remain follow-up verification.

**RL-369 — Multiple effectful subsystems coexist outside the Omega candidate-deployment state machine.**  
The repository contains separate file-writing and process-execution paths, including sandbox backend patch writes and `System.cmd` build/test commands, ASC adoption's Git/compile/test operations, worktree management, and physical-deployment orchestration. These may be legitimate, bounded workflows, but they are not all equivalent to `Candidate.deploy_transition/1` and cannot be secured merely by proving that one gateway owns that candidate status transition. A sink-by-sink authority map is required; the generic “single mandatory deployment path” claim is too broad unless scoped to that candidate type and that transition.

**RL-370 — Physical deployment manager defaults to a simulated adapter that reports actions as successful without physical actuation.**  
`Tiannara.ASC.Reality.PhysicalDeploymentManager` defaults to `SimulatedAdapter`. The adapter records the requested action in in-memory state and returns `result: :success`; it does not establish real hardware execution. Any consumer treating this result as physical deployment evidence would overstate the observed effect. This is a source-level semantic/evidence boundary finding, not a claim that real hardware was actuated.

### 18.43.3 Consequential sink inventory (partial; do not treat as exhaustive)

| Sink/path | Observed effect | Current assurance |
|---|---|---|
| `Sandbox.Backend.Local.apply_patch/2` | Host-side writes into temporary workdir; optional `patch` subprocess | Traversal containment absent; arbitrary configured commands run as host user (RL-359) |
| `Sandbox.Backend.Container.apply_patch/2` | Host-side writes before container build/test | Container network/resource controls do not protect the host-side patch write (RL-359) |
| Sandbox build/test/benchmark | `System.cmd` via backend | Local process is not OS-isolated; container isolation hardening not fully established |
| `ASC.Adoption.Adopter` | Git checkout/diff/snapshot/tag/file replacement, compile/tests/boot smoke, rollback on failure | Manual exact-scope workflow; human artifact authentication remains open (RL-361) |
| `Omega.DeploymentGateway` | Candidate state transition and deployment record; audit append | Strong local checks, but production reachability/exclusivity not established (RL-368) |
| `Phase4.RealExecution` | RealHarness execution, execution ledger/provenance, optional gateway call | Feature-flagged; caller and deployment-result semantics need follow-up (RL-366) |
| `BaseReality.Workspace` | Writes generated schematic artifacts to configured workspace | Exclusive file creation and sanitized filename; artifact writing only, not source-control commit |
| `ASC.Reality.PhysicalDeploymentManager` + `SimulatedAdapter` | In-memory action record and success-shaped result | Simulation must not be treated as physical effect (RL-370) |
| `ASC.Reality.IncidentResponseEngine` / rollback | In-memory anomaly/rollback bookkeeping | Operational event connection and restorative rollback remain open (RL-357, RL-358) |
| Other `System.cmd`, `File.write`, worktree, script and registry call sites | Build, tests, Git operations, reports, logs, registries and generated artifacts | Repository-wide inventory remains incomplete; classify by caller, input trust, privilege and authority before closure |

### 18.43.4 Isolated test plan — designed, not executed

Use a disposable checkout and dedicated temporary root; never point destructive tests at the working repository, real user home, production registry/audit files, or real deployment targets.

1. **Identity forgery:** call `authenticate/3` with a non-empty arbitrary string and a chosen human ID; record whether an identity is accepted. Then try fabricated structs and mismatched human IDs at the gateway. Expected security requirement: only a verifiable credential/session from a trusted identity authority may establish authentication; structs/timestamps alone must not.
2. **Traversal containment:** use a temporary baseline and a patch filename containing parent-directory traversal. Place a sentinel file outside the sandbox root and assert its bytes remain unchanged; assert the backend rejects the patch before writing. Run separately for Local and Container backends because patch application is host-side.
3. **Symlink traversal:** create a symlink inside the temporary workdir that points to another file beneath the test-owned temporary root; patch through the symlink and verify the outside sentinel is unchanged. Skip safely if symlink creation is unsupported. This is distinct from parent-segment traversal.
4. **MintRegistry restart:** use a unique test-only `dets_base_path`; mint, bind and consume a grant, stop/restart the registry, and assert status, binding, decision reference and consumed state are preserved. Never use the default/shared registry path.
5. **Registry corruption/partial record:** on a disposable copy, truncate or alter the registry file; restart and assert no prior grant becomes authorized. Check whether corruption is distinguishable from a genuinely empty registry and whether it raises an observable alert.
6. **Audit-store failure:** configure a test-only audit path that cannot be opened/appended; attempt each governed consequential operation and assert no success/commit is reported. Also test the previously identified unguarded Council/CEL APIs separately.
7. **Concurrent consume/deploy:** issue N concurrent consume attempts against one test grant; require exactly one success. Separately test gateway concurrency, lock-holder death, registry restart, and cross-node behavior only where distributed execution is supported.
8. **Result semantics:** make the sandbox pass while the optional deployment path fails; assert the returned result clearly says “evaluation succeeded, deployment failed/not attempted,” never implying a deployment commit.
9. **Simulated physical action:** invoke a test action through SimulatedAdapter and assert evidence explicitly labels it simulated and cannot satisfy a real-world completion gate.
10. **Audit trail and cleanup:** each test records exact source commit, test input hash, expected result, observed result and cleanup confirmation; all temp paths are unique and removed only after assertions.

These tests have **not** been run. The expected outcomes above are acceptance criteria, not observed results.

### 18.43.5 Status and carry-forward

- New findings: **RL-368–RL-370**.
- Findings closed: **0**.
- Source modifications: **0**.
- Runtime tests, exploit attempts, fault injection and hardware actions: **not performed**.
- Confirmed code facts: identity accepts any non-empty binary; Local/Container patch writes lack path containment; candidate deploy transition is restricted to the gateway function; BaseReality workspace is write-only; physical manager defaults to simulated adapter.
- Important qualification: source search/call-map evidence indicates the gateway has no production callers, but complete deployment-sink exclusivity and full runtime reachability are still not proven. Treat unknown paths as UNKNOWN, not PASS.

**Next checkpoint:** 18.44 — execute the safe tests from §18.43.4 in an isolated disposable checkout, beginning with identity forgery and traversal/symlink containment, then registry restart/corruption, audit-store failure and concurrent consumption. Record commands, exact test fixture paths, actual outputs and cleanup evidence here. If execution environment access is unavailable, retain these as unexecuted test specifications and do not label them passed.


## Checkpoint 18.44 — safe-test execution readiness and static validation

**Frozen source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Audit ledger branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Mode:** read-only source inspection; no source changes.

### 18.44.1 Execution environment check

The available GitHub connector can read repository files and update the audit ledger, but it does not provide a repository shell or test runner. The attached execution container has no Tiannara checkout at the inspected locations, and its filesystem check found no local `Tiannara` directory. No repository clone or dependency installation was performed. Consequently, I could not safely execute `mix test`, run a disposable-checkout exploit test, or perform fault injection in this turn. **All runtime tests remain NOT RUN; no test is marked passed or failed.**

### 18.44.2 Static validation against frozen source

1. **Identity forgery — confirmed source weakness remains.** `AuthenticatedHumanIdentity.authenticate/3` accepts any non-empty binary as a credential, stores its SHA-256 digest, and stamps the current time. There is no verifier, trusted identity-provider/session check, or comparison against a stored credential in this module. `authenticated?/1` checks only whether `authenticated_at` is non-nil. A digest of caller-supplied text proves neither credential validity nor human identity. This supports RL-362; it is static source evidence, not an executed forgery test.
2. **Traversal and symlink containment — confirmed source weakness remains.** Both `Sandbox.Backend.Local.apply_patch/2` and `Sandbox.Backend.Container.apply_patch/2` form output paths using `Path.join(env.workdir, rel_path)`, create the parent directory, then write the content. The reviewed path does not canonicalize and enforce containment beneath `env.workdir` before the write, nor does it establish symlink-safe resolution. Containerized build/test execution does not protect this host-side write. This supports RL-365; no sentinel, traversal, or symlink test was executed.
3. **MintRegistry durability — design is present; durability not empirically validated.** The source documents an append-only event file, state reconstruction at startup, serialized GenServer transitions, and fail-closed behavior for an unavailable registry. The reviewed code routes calls through a registered GenServer and maps call exits to `:registry_unavailable`. These source claims do not establish restart recovery, partial-write handling, corruption alerting, filesystem permissions, or concurrent behavior without runtime tests.
4. **Test-path discovery limitation.** GitHub code search did not return a directly matching identity test or MintRegistry test from the search queries used. This does not establish that no such tests exist: code search is not a complete test inventory, and no checkout-wide test listing was possible.

### 18.44.3 Safe execution handoff

Run only in a fresh disposable checkout pinned to the frozen source commit, after dependencies and the expected Elixir/OTP toolchain are available:

- Record `git rev-parse HEAD`, Elixir/OTP versions, `git status --short`, and the exact test command/output.
- Locate existing tests first with `rg -n 'AuthenticatedHumanIdentity|MintRegistry|apply_patch|Sandbox.Backend.(Local|Container)' test`.
- Add temporary test-only fixtures or tests on a separate disposable worktree; do not change production source during this audit checkpoint.
- For traversal and symlink tests, create a unique temporary baseline, sandbox workdir, and sentinel outside the sandbox root but still inside the test-owned temporary directory. Assert rejection and unchanged sentinel contents; clean up in an `after` block.
- For registry restart/corruption/concurrency tests, configure a unique temporary `dets_base_path` or explicit test path, never the default registry location. Verify all processes stop and temporary files are removed.
- Preserve raw outputs and classify each case as PASS, FAIL, BLOCKED, or NOT RUN. A source-level prediction is not a test result.

### 18.44.4 Status

- New findings: **none**; this checkpoint validated previously recorded findings rather than expanding the finding register.
- Findings closed: **0**.
- Source modifications: **0**.
- Runtime tests, exploit attempts, registry fault injection and concurrency tests: **NOT RUN** (no local checkout/test-runner available).
- Static confirmation: RL-362 identity verification weakness; RL-365 host-side patch path containment weakness.
- Open evidence gap: restart, corruption, audit failure, concurrency and result-semantics behaviors remain unverified at runtime.

**Next checkpoint:** 18.45 — continue the consequential-effect sink inventory from the frozen source: enumerate direct filesystem writes, subprocess launches, Git/worktree operations, network/service calls and physical-action adapters; map each sink to its caller, input trust, authorization gate, audit outcome and rollback semantics. Keep this source-only unless a safe isolated test runner becomes available. UNKNOWN remains UNKNOWN, not PASS.


## Checkpoint 18.45 — consequential-effect sink inventory (partial)

**Frozen source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Audit mode:** read-only source review; no source modifications or runtime execution.  
**Coverage qualification:** this is a targeted sink inventory based on fetched files and code-search results, not a complete repository-wide enumeration. Search-index misses do not prove absence.

### 18.45.1 Sink inventory

| Sink / subsystem | Observed effect | Gate and evidence | Risk / remaining proof |
|---|---|---|---|
| `Sandbox.Backend.Local.apply_patch/2` | Writes caller-provided patch files into a host temporary worktree; diff mode launches host `patch` | No canonical containment check is visible before the file writes; host commands run under the current OS user | RL-365 remains open. Traversal/symlink behavior and caller reachability need isolated tests and caller mapping. |
| `Sandbox.Backend.Container.apply_patch/2` | Performs the same host-side writes before container build/test execution | Container limits apply to commands run inside the container, not the preceding host write | RL-365 remains open; container selection alone is not a boundary for patch application. |
| `ASC.CMissions.Runner` | Creates/destroys worktrees, writes fixed hypothesis patches, runs `mix test` and benchmark subprocesses, writes benchmark output | Hypothesis IDs and target filenames shown here are fixed internal values; test/benchmark subprocesses are executed with the current host user's privileges | No new finding from the fixed paths in this reviewed section. Confirm caller access, worktree cleanup on every exceptional path, and whether subprocesses can reach untrusted code before treating as a hardened sandbox. |
| `ASC.Adoption.Adopter` | Runs Git branch/tag/diff/checkout operations, snapshots files, applies branch files to the current production worktree, runs compile/tests/boot smoke, and writes adoption record | Checks a machine evidence artifact, human authorization artifact fields, branch, declared diff scope, and post-change validation; prior RL-361 records that human artifact identity is not cryptographically authenticated | High-impact path, deliberately separated from generic self-improvement. Continue checking authorization authenticity, path normalization/containment, concurrent invocations, tag collision, and rollback completeness. |
| `ASC.Reality.PhysicalDeploymentManager` + `SimulatedAdapter` | Calls adapter `execute_action/1`; current default adapter records action in GenServer memory and returns `result: :success` | Stage and emergency-stop checks exist, but the adapter is explicitly simulated; `approve/3` records a caller-supplied `approver` value without verifying identity in the reviewed function | RL-370 remains open. New RL-372 records the unverified approval identity. No physical hardware action was performed. |
| `TiannaraOS.RepositoryTwin.create_twin/4` | Writes artifact/file-map entries beneath a generated scratch path | The reviewed writer uses `Path.join(twin_path, file_name)`, creates parent directories, then writes; no canonical containment validation is visible in this function | New RL-371: file names supplied through the API can potentially escape the intended repository-twin directory via traversal or symlink-sensitive paths. Actual exploitability depends on caller reachability, path semantics and filesystem state; no test was run. |
| `TiannaraOS.RepositoryTwin.commit_changes/4` | Writes each supplied file update under `twin.path` before updating in-memory simulated commit metadata | Same join-and-write pattern; no containment validation is visible in the reviewed function | Included under RL-371. This is a simulated repository abstraction, but the writes are real host filesystem effects and must not be assumed harmless merely because Git behavior is simulated. |
| `Omega.DeploymentGateway` | Records candidate deployment state and audit event after grant/candidate/effect checks | Strong local checks are described in source; earlier call-map evidence indicates zero production callers | RL-368 remains open: gate quality does not establish that every production deployment path is routed through it. |
| `BaseReality.Workspace` | Writes generated schematic/blueprint files to configured workspace | Filename sanitization and exclusive creation were noted in Checkpoint 18.43; API reports write-only, not source-control commit | Confirm workspace root canonicalization, symlink behavior and caller-supplied workspace trust before asserting containment. |
| Other filesystem, subprocess, network and hardware sinks | Not exhaustively enumerated in this checkpoint | GitHub search produced only partial matches; source fetches covered selected modules | Inventory remains incomplete. No claim is made that all sinks have been found or that unreviewed sinks are safe. |

### 18.45.2 New findings

#### RL-371 — RepositoryTwin file writes do not establish containment beneath the generated twin root

**Evidence:** At the frozen source baseline, `TiannaraOS.RepositoryTwin.create_twin/4` and `commit_changes/4` construct write targets with `Path.join(twin_path, file_name)` or `Path.join(twin.path, file_name)`, create parent directories, and write the supplied content. The reviewed code does not resolve and verify the final path remains within the intended twin root before writing.

**Impact:** If an untrusted caller can control file names or updates, path traversal may turn a simulated repository operation into writes elsewhere accessible to the Tiannara OS process. Symlink interactions also need separate validation. The `scratch/` naming convention is not itself a security boundary.

**Confidence/status:** Source-confirmed missing containment check in the reviewed write paths; exploitability and external reachability are **not runtime verified**. No traversal attempt was made. **Open.**

**Required evidence for closure:** isolated tests for parent traversal and symlink escape; sentinel files outside the twin root remain byte-identical; invalid paths are rejected before any write; callers and trust boundaries are traced; tests include platform-specific path behavior.

#### RL-372 — Physical deployment approval records an unverified approver value

**Evidence:** `Tiannara.ASC.Reality.PhysicalDeploymentManager.handle_call({:approve, id, approver, note}, ...)` accepts the supplied `approver` value and records it with `decision: :approved` and a timestamp when the deployment is at `:pending_approval`. The reviewed handler does not authenticate the approver or validate a signed/verified approval artifact. This is distinct from the module's default simulated adapter: the approval-state weakness exists in the manager's authorization record regardless of whether a real adapter is later configured.

**Impact:** A caller that can invoke this GenServer API may be able to create an approval record using an arbitrary identity string. Whether an untrusted external caller can reach the API and whether a real adapter can be selected in production are not established here. The API's local stage check does not establish human identity or authorization.

**Confidence/status:** Source-confirmed absence of identity verification in the reviewed handler; reachable exploitability and production hardware configuration are **not verified**. No approval or hardware action was executed. **Open.**

**Required evidence for closure:** bind approval to the authenticated identity mechanism and a deployment-specific, integrity-protected approval artifact; enforce approver authorization and separation of duties; reject empty, forged and mismatched identities; verify approval binds to the exact design/plan digest; test concurrent approval, emergency-stop and stage-transition behavior with a simulated adapter only.

### 18.45.3 Remediation ordering recommendation

1. **Priority 0 — containment and identity boundaries:** fix RL-365 and RL-371 path containment, RL-362 credential verification, and RL-372 physical approval authentication before enabling any untrusted patch or real hardware adapter.
2. **Priority 1 — governance completeness:** resolve RL-368 deployment-gateway reachability/exclusivity, RL-361 adoption artifact authenticity, and RL-357/RL-358 incident/rollback limitations.
3. **Priority 2 — evidence and resilience:** execute registry restart/corruption/concurrency tests, audit-store failure tests, cleanup/failure-path tests, and result-semantics tests in an isolated checkout.
4. **After each remediation batch:** add regression tests, run the relevant tests and broader suite, inspect the exact diff, verify the audit record and rollback path, then repeat the sink audit for bypasses. Do not mark a finding closed from code changes alone.

This ordering is a recommendation; no remediation was applied in this checkpoint.

### 18.45.4 Status

- New findings: **RL-371–RL-372**.
- Findings closed: **0**.
- Source modifications: **0**.
- Runtime tests, exploit attempts, subprocess execution and hardware actions: **NOT RUN**.
- Frozen source commit remains unchanged: `e71bc230a8d38f3a0108012685ae1a052d195b00`.
- The inventory is partial. UNKNOWN remains UNKNOWN, not PASS.

**Next checkpoint:** 18.46 — expand the sink inventory using module-by-module source traversal from `lib/` and `tiannara_runtime/lib/`, focusing on write-capable repository/workspace APIs, generated-code writers, subprocess wrappers, and network/hardware adapters. Trace public entry points and production callers for RL-371/RL-372 before proposing source changes. Keep audit and remediation separate until a deliberate remediation batch is authorized.


## Checkpoint 18.46 — expanded write/subprocess sink inventory and caller reachability

**Frozen source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Ledger branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Mode:** read-only source inspection. No source modifications, runtime tests, exploits, subprocesses or hardware actions were performed.  
**Coverage:** targeted source traversal plus GitHub code-search results; not a complete whole-repository inventory. Code search is partial and appears to index the current default branch for results, so all code-level assertions below were checked by fetching source at the frozen ref.

### 18.46.1 RL-371 and RL-372 caller/reachability follow-up

**RepositoryTwin (RL-371):**
- Frozen-source functions confirmed: legacy `create_twin/4` writes each supplied `file_name` using `Path.join(twin_path, file_name)`; stateful `create_twin/4` passes artifact maps to `write_artifacts_to_disk/2`, which similarly joins supplied keys to the twin path; `commit_changes/4` joins caller-supplied update keys to `twin.path` and writes them before updating simulated commit metadata.
- Code search found direct examples in `test/tiannara/os/repository_twin_world_test.exs` and `test/tiannara/os/tool_ecology_test.exs`. These demonstrate test use, not production reachability. The available code-search results did not establish a complete production caller map.
- **Assessment:** RL-371 remains open. Missing containment is confirmed in the reviewed functions; actual traversal/symlink exploitation, caller trust, and runtime impact remain unverified. There is no basis to call this safe because the abstraction is named a “twin”; the functions perform real host filesystem writes.

**PhysicalDeploymentManager (RL-372):**
- Public `approve/3` and `execute/2` APIs directly send messages to the registered GenServer. The approval handler accepts the supplied approver value and stores it without identity verification, as previously recorded.
- The execute handler permits calls when the deployment stage is one of `:simulated`, `:dry_run`, `:supervised`, or `:autonomous` and the emergency-stop flag is not active. The inspected handler does not itself require a verified approval object or authenticate the caller. Stage advancement has a separate state machine, but the exact complete transition path and production adapter configuration have not been proven here.
- Search found a deployment test that calls `advance/1`, `approve/3`, and `execute/2`; this establishes test coverage/use, not production reachability. The default adapter remains simulated in the reviewed module; no physical action was performed.
- **Assessment:** RL-372 remains open. Do not infer that a real hardware adapter is active. Before enabling one, bind authenticated approval to the exact plan/design digest and enforce authorization at the consequential execution boundary, not only in a caller convention.

### 18.46.2 Additional filesystem and subprocess sinks observed

| Sink | Source-confirmed behavior | Risk / required follow-up |
|---|---|---|
| `Tiannara.ToolForge.ToolBuilder.handle_call({:build_to_disk, spec, output_dir}, ...)` | Writes generated source and test files using `Path.join(output_dir, filename)`, mkdirs parents, and writes contents. Generated source keys include `spec.name`; the test path is joined under `output_dir/test`. | Validate generated names and canonical final paths beneath the designated output root, including symlinks. Trace who can submit `spec` and choose `output_dir`. The reviewed path lacks an explicit containment check. |
| `TiannaraRuntime.OS.Persistence.ExperimentJournal` | Builds journal path as `Path.join([storage_path, "experiments", "#{experiment_id}.journal.json"])`; public APIs accept `experiment_id`, and persistence writes serialized journal content to the derived path. | New RL-373: experiment ID is used as a path component without visible validation/canonical containment in the reviewed functions. Traversal could redirect a journal write outside the intended experiments directory if the ID is attacker-controlled and path semantics permit it. Caller reachability and exploitability are unverified. |
| `TiannaraRuntime.OS.Persistence.ResurrectionEngine` | Writes `clean` / `running` markers beneath configured CPL storage; several recovery/statistics helpers read JSON files and default some missing/error metrics to zero or 100% success. | Storage path is configuration-derived, not shown as arbitrary request input here. Error-default metrics can conceal missing/corrupt evidence; inspect full recovery flow and caller assumptions before treating reported metrics as verified recovery. |
| `TiannaraRuntime.OS.Resurrection.ExperimentJournal` | Exposes in-memory journal lifecycle and computes hashes; this inspected module is distinct from the persistence journal. | Do not conflate a hash in memory with durable, authenticated provenance. Continue tracing its serialization/callers and whether a canonical persistence layer is used. |
| `ASC.CMissions.Runner` | Writes fixed internal hypothesis patch files to a supplied worktree path and runs `mix test` and benchmark commands with `System.cmd`. | Fixed filenames reduce direct filename injection in the reviewed clauses, but the worktree root and caller permissions/cleanup still require traceability. Exceptions between worktree creation and cleanup may leave temporary worktrees; no execution test was run. |
| `ASC.Adoption.Adopter` | Executes Git branch, diff, tag, checkout and revision commands; copies snapshot files; writes a temporary boot-smoke script; runs compile, scoped tests and boot smoke; writes an adoption record. | Reconfirms RL-361 and the high-impact adoption path. Continue validating the provenance of authorization/evidence artifacts, scope path normalization, failure rollback and concurrent invocations. |
| `TiannaraRuntime` certification / Mix tasks | Search results include `System.cmd("elixirc", ...)` in a validation Mix task and a certification runner invoking test commands. | Treat as developer/certification execution paths unless production caller evidence says otherwise; command execution is not itself proof of production exploitability. |

### 18.46.3 New finding

#### RL-373 — experiment journal persistence derives a filesystem path from an unvalidated experiment ID

**Evidence:** At the frozen source baseline, `TiannaraRuntime.OS.Persistence.ExperimentJournal` constructs the journal path using the configured CPL storage path, the `experiments` directory, and the caller-supplied `experiment_id` interpolated into a filename ending in `.journal.json`. Its persistence helper creates the parent directory and writes the serialized journal. The reviewed code does not show validation of the ID as a single safe path component or canonical containment of the final target beneath the experiments directory.

**Potential impact:** If an untrusted caller can supply an ID containing traversal components, a journal persistence operation may write outside the intended journal directory, within the runtime process's filesystem permissions. Whether path normalization, caller validation elsewhere, or access restrictions prevent exploitation is not established by this local source review.

**Status/confidence:** Source-confirmed path construction and write; exploitability and caller trust/reachability are **not runtime verified**. No exploit was attempted. **Open.**

**Closure criteria:** trace all callers and ID sources; reject separators, traversal and platform-specific path forms before I/O; resolve/check final path containment and account for symlink races; add isolated tests with an outside sentinel that must remain unchanged; verify rejection occurs before parent creation/write.

### 18.46.4 Scope and findings disposition

- New finding: **RL-373**.
- Findings closed: **0**.
- Source modifications: **0**.
- Runtime tests, traversal attempts, subprocess execution and hardware actions: **NOT RUN**.
- Frozen source baseline unchanged: `e71bc230a8d38f3a0108012685ae1a052d195b00`.
- The inventory remains partial; search misses are not evidence that a sink or caller does not exist.
- Existing RL-365, RL-361, RL-368, RL-371 and RL-372 remain open. ToolBuilder output containment is an additional review target but is not assigned a separate finding in this checkpoint pending caller/trust-boundary analysis.

**Next checkpoint:** 18.47 — trace callers and input provenance for ToolBuilder, persistent ExperimentJournal, RepositoryTwin, and PhysicalDeploymentManager; inspect exact path/name validation and startup/configuration wiring in both `lib/` and `tiannara_runtime/lib/`. Then consolidate overlapping filesystem-containment findings and prepare a test matrix for the first remediation batch. Do not modify source until remediation is explicitly authorized; UNKNOWN remains UNKNOWN, not PASS.


## Checkpoint 18.47 — caller provenance, public entry points, and algorithmic monoculture controls

**Frozen source baseline:** `e71bc230a8d38f3a0108012685ae1a052d195b00`  
**Mode:** read-only source inspection. No source changes, runtime tests, path exploits, subprocesses or physical actions were performed.  
**Coverage note:** exact source files were fetched at the frozen ref. Repository code search is partial and does not establish absence of callers.

### 18.47.1 RL-373 — experiment journal input provenance

- `TiannaraRuntime.OS.Persistence.ExperimentJournal` exposes `create_journal/3`, `record_stage/5`, `set_checkpoint/1`, `complete/2`, `fail/2`, and `get_resume_stage/1` using an `experiment_id` argument. The private `journal_file_path/1` interpolates that ID into a filename beneath the configured CPL storage directory's `experiments` subdirectory; `persist_journal/1` creates parents and writes the file.
- The code-search pass found the module's own definitions but did not establish a complete production caller map. A separate in-memory module, `TiannaraRuntime.OS.Resurrection.ExperimentJournal`, exists; it must not be mistaken for proof that the persistence module's path construction is safe.
- **Disposition:** RL-373 remains open. Input provenance, caller trust and exploitation are unknown. Require explicit identifier validation and final-path containment plus isolated traversal/symlink tests.

### 18.47.2 ToolBuilder output and generated-code boundary

- `Tiannara.ToolForge.ToolBuilder.build_to_disk/2` is a public function accepting a `ToolSpecification` and caller-selected `output_dir`. The server writes each generated source/test filename with `Path.join`, creates parent directories, and writes content. The reviewed code contains no explicit final-path containment or symlink-safe write check.
- Code search did not establish a production caller for `build_to_disk/2`; this is **not** evidence that no caller exists. It is a write-capable API whose caller permissions and output-root trust boundary remain to be traced.
- No new numbered finding assigned in this checkpoint. Keep it as an open containment review target alongside RL-365/RL-371/RL-373 until caller and filename validation evidence is gathered.

### 18.47.3 Physical deployment approval is reachable through a web-controller method

- At the frozen ref, `Tiannara.Web.CRAVChallengeController.physical_plan/2` forwards a request-derived design to `PhysicalDeploymentManager.plan/1`; `physical_approve/2` derives `approver` and `note` from request parameters and forwards the selected action to approve/reject/abort/emergency-stop; `physical_advance/2` forwards an ID to `advance/1`. This establishes a controller-level entry point in source, but does **not** establish that the route is mounted, exposed externally, or protected/unprotected by authentication middleware.
- Combined with RL-372, the handler records a supplied approver value without authenticating it. Do not treat a request parameter as proof of human approval. Before a real adapter can be enabled, authenticate the requester, authorize the specific action, bind signed approval to the exact design/plan digest, enforce the approval invariant at execution time, and verify route middleware/configuration. No hardware action was performed.

### 18.47.4 Algorithmic monoculture — system map and evidence boundary

The source contains several components intended to measure or counter diversity; no single one is yet proven to be an end-to-end, system-wide monoculture control:

1. **`Tiannara.Discovery.Advanced.HypothesisDiversityEngine`** — the most directly relevant source module for *hypothesis monoculture*. It computes causal, prediction, abstraction and prior diversity scores, combines them, and emits recommendations when selected dimensions fall below thresholds. This is a measurement/recommendation surface; the reviewed code alone does not prove that recommendations are enforced by every research pipeline.
2. **`Tiannara.ASC.MetaScienceEngine`** — computes a hypothesis-diversity score and emits a bottleneck/recommendation when it falls below 0.4, including cross-domain and analogical generation. This indicates a research-process feedback mechanism, not proof that diverse hypotheses are actually generated or retained.
3. **`Tiannara.Sentinel.Observatories.EpistemicDiversityTracker`** in `tiannara_runtime/lib` — exposes per-observatory and mesh diversity-index/modifier calls. Its collection coverage, scoring semantics, consumers, alerting, and authority to block monoculture-causing changes remain to be traced.
4. **CIS / Domain Cortex / GRCC-related constraints** — existing architecture and audit artifacts describe domain-diversity and monoculture checks. Documentation and test/gauntlet names are not runtime proof; verify exact implementation, production wiring, thresholds, and whether a low-diversity signal changes selection/adoption behavior.
5. **Research selection and knowledge integration** — these are critical downstream controls: diversity must influence candidate generation, experiment selection, evidence review, knowledge integration, and adoption. A score alone cannot prevent convergence if downstream ranking, shared objectives, common priors, or approval policy continue to select one dominant approach.

**Audit conclusion:** If asking which system *deals with algorithmic monoculture*, the closest direct owner in the reviewed source is `HypothesisDiversityEngine`, supported by `MetaScienceEngine` and the runtime `EpistemicDiversityTracker`; CIS/domain-diversity controls are additional intended guardrails. This is a distributed responsibility, not yet demonstrated as one enforced end-to-end control. The audit must trace callers and action effects before assigning a “prevents monoculture” status.

**Minimum acceptance criteria for an effective anti-monoculture system:**
- Measure diversity across algorithm families, causal assumptions, representations, objectives, data/provenance, and research methods—not just domain labels.
- Detect concentration/collapse over time and identify correlated/shared lineage among nominally different candidates.
- Actively generate or admit genuinely different alternatives when diversity falls, then evaluate them with comparable evidence.
- Preserve minority hypotheses and local/domain-specific approaches until fair testing; do not force consensus just to increase a scalar score.
- Prevent a single shared metric, model, prior, or governance path from silently dominating every candidate.
- Keep immutable evidence and human-governed policy changes; test that low-diversity conditions trigger the expected action and that cosmetic diversity cannot pass.

### 18.47.5 Disposition

- New findings: none in this checkpoint; RL-373 and RL-365/RL-371/RL-372 remain open.
- Findings closed: **0**.
- Source modifications: **0**.
- Runtime tests, exploit attempts, subprocess execution and hardware actions: **NOT RUN**.
- Next checkpoint: **18.48** — trace actual callers and enforcement effects for `HypothesisDiversityEngine`, `MetaScienceEngine`, `EpistemicDiversityTracker`, CIS/domain diversity, and research candidate selection/adoption. In parallel, continue the filesystem entry-point map and verify route authentication/mounting for physical deployment. Do not claim anti-monoculture prevention from score computation or documentation alone.


### Checkpoint 18.48 — independent error detection, correction, and anti-doubling-down controls

**Scope and method:** Read-only source inspection at frozen source baseline `e71bc230a8d38f3a0108012685ae1a052d195b00`. This checkpoint follows the actual caller/effect path for epistemic diversity, meta-science, research ranking/scoring/integration, and physical-deployment route exposure. No source files were changed. No runtime tests, exploits, subprocesses, or hardware actions were performed.

#### 18.48.1 — What currently addresses a single agent doubling down

The closest existing components are complementary, not a single proven independent correction system:

- `Tiannara.Research.HypothesisRanker` (`lib/tiannara/research/hypothesis_ranker.ex`, source blob `3e9e18387b5a4bf7e7f36ac7043598df94a38364`) creates hypotheses from priorities and ranks supplied hypotheses by EIG, feasibility, and urgency. It stores generated hypotheses in process state. The inspected rank path does not itself compare a claim against an independent verifier or force a disconfirming test before ranking/adoption.
- `Tiannara.Research.EvidenceScorer` (`lib/tiannara/research/evidence_scorer.ex`, blob `ef57427f20416888dd8ed37b0f24f9486d39545e`) computes a confidence score from observations. The current source assigns reproducibility by observation count (0.2/0.5/0.8), consistency as 0.75 for any nonempty observation set, and effect size from mean observation value divided by 100. `falsification_attempted` is inferred from presence of `experiment[:failure_criteria]`, not proof that an adversarial test actually ran. This scoring path is therefore not sufficient evidence of independent factual verification.
- `Tiannara.Research.KnowledgeIntegrator` (`lib/tiannara/research/knowledge_integrator.ex`, blob `41a8718241e4cb682184a24c11729baa244591a9`) rejects non-`:real_execution` evidence and evidence below 0.7 confidence before integration. That is a useful execution-mode/threshold gate, but the inspected gate trusts the supplied evidence structure and confidence value; it does not independently recalculate whether the claim survived falsification or contradiction analysis.
- `Tiannara.Discovery.Advanced.HypothesisDiversityEngine` (`lib/tiannara/discovery/advanced/hypothesis_diversity_engine.ex`, blob `fbd336dbdb58a3895b58d785522947931c9e0300`) computes causal, prediction, novelty/abstraction and prior-diversity metrics and emits recommendations. Its direct source does not enforce candidate inclusion, preserve minority hypotheses, or block selection when diversity is low.
- `Tiannara.ASC.MetaScienceEngine` (`lib/tiannara/asc/meta_science_engine.ex`, blob `9434dcd8fe8b2c8948479a565465af48346bd71b`) detects low hypothesis diversity and unusually high confirmation rates and recommends cross-domain/analogical hypotheses and disconfirming evidence. Its `apply_improvements/1` publishes high-priority recommendations to `meta_science.improvements`; it does not directly enforce a research hold or prove that the receiving pipeline changes its candidate set. Its diversity calculation is based on supplied `hypothesis_types`, with no types defaulting to 0.5, so missing data can appear moderately diverse.
- `Tiannara.Sentinel.Observatories.EpistemicDiversityTracker` (`tiannara_runtime/lib/tiannara/sentinel/observatories/epistemic_diversity_tracker.ex`, blob `00bc66b1b5f38a92b505564b2207467067086e48`) records action counts in volatile GenServer state and computes normalized Shannon entropy. The benchmark (`.../validation/consensus_benchmark.ex`, blob `34065eb841e6e954f19f159a56f9a47d09664a80`) reports `monoculture_detection_rate: 1.0` as an assumption and `adversarial_suite_pass_rate: consensus_accuracy` as a proxy; those fields are not measured proof of detection or adversarial success. Health reporting (`.../observatories/core/health_report.ex`, blob `328c65d62aa8546b24eb3a03116f5433274ad537`) includes a literal placeholder `disagreement_archives: 0 >= 100`, which always fails. The reliability tracker uses the diversity modifier in its weight calculation, but that is a metric adjustment rather than a mandatory claim-correction gate.
- Existing tests cover diversity score ranges, one constructed comparison between two hypothesis sets, and MetaScience recommendation generation. They do not prove an end-to-end scenario in which a wrong agent claim is contradicted, independently re-tested, prevented from being reinforced, corrected, and removed or downgraded in downstream memory.

#### 18.48.2 — Finding RL-374: independent epistemic correction is not an enforced end-to-end gate

**Status:** OPEN — source-confirmed design gap; production-wide reachability and runtime exploitability not tested.

**Evidence:** The reviewed components expose scores, candidate rankings, recommendations and threshold-based knowledge integration. The inspected paths do not establish an obligatory independent verifier, a mandatory contradiction/disconfirmation stage, a calibrated evidence-based confidence update, or a universal block on re-promoting a claim that has failed independent testing. The evidence scorer's current heuristic values and the benchmark's explicit proxy/assumption fields make it unsafe to treat their outputs alone as certification.

**Risk:** A mistaken hypothesis can be ranked, evaluated using weak or correlated evidence, assigned an overconfident score, and potentially reintegrated without a demonstrably independent challenge. An agent can repeat its own rationale and count repetition as support. A consensus of agents that share assumptions, data, code, or model lineage can reinforce the same error rather than independently validate it.

**Required control design (proposed; not implemented in this audit):**
1. Treat every consequential claim as a versioned, provenance-carrying claim with explicit assumptions, evidence, uncertainty, falsification conditions, and dependencies.
2. Require a genuinely separate challenge path to attempt disconfirmation: independently derive alternatives, seek counterevidence, check source provenance, test edge cases, and reproduce the result where feasible. Independence must be measured by method/data/lineage, not just a different agent ID.
3. Separate proposal, challenge, evidence adjudication, and memory integration. The proposing agent must not be the sole judge of its own claim.
4. Update confidence from evidence quality and calibrated outcomes; missing, correlated, synthetic, stale, or unverifiable evidence must not count as independent confirmation. UNKNOWN must remain UNKNOWN.
5. On material contradiction, automatically mark the claim disputed, freeze confidence escalation and consequential downstream actions, preserve dissenting hypotheses, and queue re-test. Do not silently overwrite history.
6. Require explicit resolution before restoring a disputed claim to trusted memory. Preserve prior versions, provenance and reasoned decision trail; use human authorization for consequential policy or self-modification changes.
7. Test against adversarial cases: confident false claim, repeated self-citation, correlated agents, cherry-picked evidence, contradictory observations, missing provenance, verifier failure, and a claim that remains unresolved. Verify both false-positive and false-negative behavior.
8. Make CEL able to inspect the complete claim→evidence→verifier→decision→memory lineage and detect disconnected or bypassed controls, while CEL itself remains governed by the constitution and human-authority boundary.

**Closure criteria:** Caller and supervisor map complete; independent verifier and mandatory enforcement points identified; tests demonstrate that contradiction blocks confidence escalation/integration and consequential execution; recovery/reconsideration is auditable; no simulated or self-reported pass can satisfy real evidence gates; relevant test suite actually run and results attached.

#### 18.48.3 — Physical deployment route cross-check

At the frozen baseline, `lib/tiannara/web/router.ex` (blob `917c749e023ff86d59200798b93dfe4bfd9c11f0`) mounts `POST /api/v1/reality/physical`, `POST /api/v1/reality/physical/:id/advance`, `POST /api/v1/reality/physical/:id/approve`, and `POST /api/v1/reality/physical/:id/abort` in the `:api` pipeline, which visibly contains only `accepts(["json"])`. No authentication/authorization plug appears in that pipeline. This confirms route mounting and the absence of auth plugs in the inspected router pipeline; deployment environment, upstream proxy controls and other middleware were not verified. Keep RL-372 open: request-supplied approver identity and physical action controls need authenticated, authorized, plan-digest-bound approvals at the execution boundary before any real adapter can be considered safe.

#### 18.48.4 Disposition and next work

- New finding: **RL-374 — independent epistemic correction is not an enforced end-to-end gate** (OPEN).
- RL-365, RL-371, RL-372 and RL-373 remain open; no findings closed.
- Source modifications: **0**. Runtime tests/exploit attempts/subprocesses/hardware actions: **NOT RUN**.
- Checkpoint 18.49 should trace the actual discovery candidate-selection and knowledge-re-evaluation paths (including scheduler and memory consumers), confirm whether disputed/rejected claims can be reintroduced, and map any existing contradiction-analysis components to enforcement points. Keep the proposed correction loop separate from implementation until the audit identifies its real integration boundaries.


### Checkpoint 18.49 — rejected-claim re-entry, discovery selection, and memory re-evaluation

**Scope and method:** Read-only inspection of discovery selection, contradiction analysis, research queue/quarantine, knowledge integration, and memory re-evaluation at frozen source baseline `e71bc230a8d38f3a0108012685ae1a052d195b00`. Search excerpts are treated as discovery aids only; the cited implementation files were fetched at the frozen ref. No code changes or runtime tests were performed.

#### 18.49.1 — Discovery diversity is partially enforced, but does not establish epistemic correctness

- `lib/tiannara/discovery/discovery_prioritizer.ex` (blob `75ccb7be0eacef1c453ca03d9c73096fc2ad688e`) does more than merely warn: `rank_with_diversity/1` sorts discoveries and runs `enforce_diversity/1`, with caps of three per domain and two per causal model. `DiscoveryScheduler.run_cycle/1` calls this ranking and selects up to three discoveries for dispatch. This is a real bounded diversity mechanism on that scheduler path.
- The guard is narrow: it constrains domain and `metadata[:causal_model]` counts, not evidence-source independence, shared assumptions, model lineage, data leakage, objective diversity, or whether the claim is correct. Missing causal-model metadata collapses to `:unknown`, which can cause unrelated unknowns to be grouped together. `detect_monoculture/1` reports warnings; it does not itself prove that all system-wide candidate paths use the same selection gate.
- `DiscoveryScheduler` uses `ContradictionAnalyzer` to turn active conflicts into research gaps, then generates hypotheses/predictions/experiments and dispatches selected workflows. This routes detected conflicts into follow-up research; it does not, in the inspected path, mark the underlying claim disputed in all knowledge stores or block that claim from other downstream use.
- `lib/tiannara/discovery/contradiction_analyzer.ex` (blob `528739ec970a7944250fcec4b50cbc545a1ea060`) assigns type from simple fields and fixed impact values (direct 0.9, inferred 0.6, contextual 0.4; unknown based on entity count). It ranks conflicts heuristically; this is not a proof of logical inconsistency or an independent resolution verdict.

#### 18.49.2 — Research quarantine helps, but rejected-claim re-entry and re-evaluation are not closed

- `lib/tiannara/research/research_director.ex` at the frozen baseline logs “R0 quarantine active” and, when its queue reaches an experiment, records a quarantine event instead of persisting a fabricated result. This is a concrete guard on that legacy pipeline's experiment-result path.
- The same pipeline's ingest path generates and ranks hypotheses and enqueues them. The quarantine handler does not by itself establish a system-wide prohibition on other experiment paths or other consumers integrating results. Treat this as a path-specific safeguard, not universal protection.
- `lib/tiannara/research/knowledge_integrator.ex` (blob `41a8718241e4cb682184a24c11729baa244591a9`) rejects integration unless the caller supplies `execution_mode: :real_execution` and confidence is at least 0.7. However, it trusts the supplied evidence map and confidence rather than independently recomputing evidence validity, and its `persist_to_executive_memory/1` catches and suppresses failures. The knowledge item records `re_evaluation_due` seven days later, but this module exposes no due-item query or scheduled re-evaluation handler in the inspected file. A due timestamp is not proof that re-evaluation happens.
- `KnowledgeIntegrator` keeps its own knowledge in GenServer memory and writes a copy to ExecutiveMemory when available. The inspected `real_knowledge/1` accessor filters only that process-local list by quarantine flag and execution mode. It is not a global query over every memory, world-model, research, or runtime store.
- The frozen source's `DiscoveryScheduler` handles completed workflows as `:supported` when the workflow outcome is `:success`, otherwise `:inconclusive`; confidence delta uses the confidence values found in step evidence, and defaults to +0.1 when a supported outcome has no confidence values. That fallback and outcome mapping deserve tests: success is not automatically the same as independently verified truth. No evidence here establishes a universal reverse update that demotes or retracts previously integrated knowledge when a later contradiction appears.

#### 18.49.3 — Finding RL-375: contradiction handling does not universally invalidate and re-evaluate downstream claims

**Status:** OPEN — source-confirmed integration gap; full production call graph and runtime behavior remain unverified.

**Evidence:** Contradictions can become discovery gaps; diversity selection constrains a subset of scheduler candidates; the ResearchDirector quarantine blocks its own legacy fabricated-result path; and KnowledgeIntegrator applies execution-mode/confidence checks. The inspected sources do not connect these into a mandatory end-to-end lifecycle that marks an affected claim disputed, freezes consequential use, triggers independent re-evaluation, propagates a corrected status to all dependent memories, and prevents stale/rejected versions from being promoted again.

**Risk:** A claim may be contradicted in one subsystem while another store or consumer continues using its prior status. It may be rediscovered and promoted based on a separate evidence path, or its re-evaluation deadline may pass without any visible re-evaluation. This is a plausible architecture risk; no runtime re-entry exploit was performed.

**Required controls (proposed, not implemented):**
1. Introduce a canonical claim identity/version and a system-wide status transition contract: proposed → supported / disputed / rejected / superseded, with append-only provenance.
2. When a material contradiction is recorded, publish a typed event keyed to claim/version and dependency lineage; all memory, world-model, research-ranking, and consequential-action consumers must either acknowledge the new state or fail closed.
3. Block confidence increases, trusted-memory promotion, and consequential action while a material contradiction is unresolved. Preserve alternative hypotheses and the original evidence rather than overwriting history.
4. Make re-evaluation operational: due-item scheduler, independently sourced new evidence, version-aware recalculation, stale-claim warnings, failure/timeout states, and auditable completion records. A timestamp alone is insufficient.
5. Require provenance-backed verification at the integration boundary, not just caller-supplied `execution_mode` and confidence. A claimed real execution must be bound to an authenticated run record and exact evidence digest.
6. Test: contradiction after prior integration; conflict propagates to each consumer; rejected claim cannot be re-promoted without new qualifying evidence; missing verifier or memory write fails closed; duplicate/out-of-order events remain idempotent; expiry and scheduler downtime are visible; unrelated claims remain unaffected.

#### 18.49.4 — Disposition

- New finding: **RL-375 — contradiction handling does not universally invalidate and re-evaluate downstream claims** (OPEN).
- RL-374 remains OPEN: independent epistemic correction is not enforced end-to-end.
- RL-365, RL-371, RL-372, RL-373 remain OPEN; no findings closed.
- Source modifications: **0**. Runtime tests, re-entry exploits, subprocesses, and hardware actions: **NOT RUN**.
- Checkpoint 18.50: trace all consumers of the canonical contradiction/evidence events and ExecutiveMemory knowledge records; determine which components can still read or act on disputed/stale knowledge, and whether the proposed claim lifecycle can be enforced without bypassing constitutional and human-approval boundaries.

### Checkpoint 18.50 — discovery proof obligations, life-preservation outcomes, and the Type-I civilization mission

**Scope and method:** Read-only source inspection at frozen baseline `e71bc230a8d38f3a0108012685ae1a052d195b00`. This checkpoint answers two linked questions: whether Tiannara's reasoning/research pipeline can produce and prove discoveries rather than merely rank or label them, and whether the long-term mission—preserving life and helping humanity advance toward a Type I civilization—is translated into enforceable research priorities, outcome measures, evidence, and safety controls. This is an architecture/source audit, not a claim that the mission is impossible or that no relevant code exists elsewhere. No source changes, runtime tests, experiments, or physical actions were performed.

#### 18.50.1 — The intended discovery loop exists in outline, but “success” is not equivalent to proof

- `lib/tiannara/discovery/discovery_scheduler.ex` (blob `6736d3e32b7666b62a46d9bf42e588dfce003a2a`) assembles a real workflow shape: it examines active conflicts, turns contradiction analysis into research gaps, generates hypotheses/predictions/experiments, ranks candidates with diversity constraints, and dispatches selected workflows. This is meaningful orchestration, but source presence and dispatch do not prove an experiment ran correctly or that its conclusion is true.
- The scheduler's inspected completion path maps workflow `:success` to `:supported`; when a supported outcome has no extracted confidence values, `confidence_delta/2` defaults to `+0.1`. That makes workflow completion capable of increasing confidence without the inspected path demonstrating independent replication, successful falsification attempts, or a verified evidence artifact. A success-shaped status must not be treated as a scientific verdict.
- `lib/tiannara/research/evidence_scorer.ex` (blob `ef57427f20416888dd8ed37b0f24f9486d39545e`) calculates a numeric confidence score from heuristic terms. In the inspected implementation, reproducibility is assigned from observation count (0.2/0.5/0.8), consistency is 0.75 for any nonempty observation set, and `falsification_attempted` is inferred from the presence of `experiment[:failure_criteria]` rather than a record proving those criteria were actually tested. These values may help triage, but they do not establish statistical validity, independent replication, causal identification, or proof.
- `lib/tiannara/research/knowledge_integrator.ex` (blob `41a8718241e4cb682184a24c11729baa244591a9`) requires caller-supplied `:real_execution` and confidence at or above 0.7, but the inspected gate trusts the supplied evidence/confidence. Its persistence path catches and suppresses ExecutiveMemory errors, and its seven-day `re_evaluation_due` value is not accompanied in this module by a due-item scheduler/handler. Therefore a high score, a claimed execution mode, a stored deadline, or a successful workflow status must not be represented as independent proof or as evidence of continuing re-evaluation.
- `lib/tiannara/research/research_director.ex` has an R0 quarantine that prevents fabricated results from being persisted on its own legacy experiment path. This is a useful guard, but it does not certify every other research/execution route and does not substitute for a shared, verified evidence contract.

#### 18.50.2 — Finding RL-376: scientific discovery proof obligations are not enforced end-to-end

**Status:** OPEN — source-confirmed gap in the inspected discovery/research path; whole-repository caller coverage and runtime behavior remain unverified.

**Risk:** Tiannara could promote an interesting hypothesis or a successful workflow into “supported knowledge” without a demonstrated independent challenge, reproducible evidence package, calibrated uncertainty, or contradiction check. That is the exact failure mode where one agent can repeat its own mistaken reasoning and increase confidence rather than discover its mistake.

**Required control design (proposed, not implemented here):**

1. Define a versioned **Discovery Claim** contract: precise claim and scope; assumptions; prior knowledge; prediction; falsification criteria; method and data provenance; execution identity; environment/configuration; raw observations; analysis; uncertainty; limitations; independent-review result; contradictions; and immutable evidence digest.
2. Enforce a staged state machine: `proposed → experiment_planned → executed → evidence_validated → independently_challenged → replicated_or_bounded → adjudicated → integrated`. Missing artifacts, simulations, synthetic results, unsupported outcomes, or unavailable validators must remain `unknown/inconclusive` or fail closed—not become `supported`.
3. Separate proposer, executor, verifier, and adjudicator roles. Independence must account for shared data, code, instruments, methods, assumptions, and lineage—not merely different agent IDs. Require replication or a clearly justified alternative evidence standard appropriate to the domain.
4. Make falsification executable and auditable: record which failure criteria were tested, test run IDs, outcomes, counterevidence, and untested criteria. The existence of a criterion is not proof it was attempted.
5. Calibrate confidence against historical outcomes and domain-appropriate statistical methods. Keep heuristic priority scores separate from evidentiary confidence. No unconditional positive confidence delta for a success status with missing evidence.
6. Propagate contradictions to all claim versions, memory stores, research rankings, world models, reports, and consequential action gates. Preserve rejected hypotheses and reasons so the same discredited claim cannot silently re-enter as a new discovery without qualifying new evidence.
7. Make CEL/System Atlas inspect the complete claim → plan → execution → raw evidence → independent challenge → adjudication → memory/use lineage, identify missing edges and alternate consumers, and report gaps. CEL must not certify its own work; constitution and human authority remain above CEL, especially for self-modification or consequential deployment.
8. Require end-to-end tests for fabricated success, empty/missing evidence, correlated replicas, deliberately wrong results, contradictory observations after integration, verifier/persistence failure, stale evidence, duplicate/out-of-order events, and recovery after restart. Tests must show both correct rejection and legitimate discovery retention.

#### 18.50.3 — Life preservation and Type-I civilization are a mission, not yet a verified outcome contract in the inspected path

The long-term goal remains relevant and should not be reduced to “maximize discoveries.” The user's intended direction is to help preserve life and support humanity's advancement toward a Type I civilization through validated science, technology, and accumulated knowledge. Prior architectural intent includes a continuous cognitive loop (observe → interpret → prioritize → investigate → plan → execute → validate → learn), a Research Director, a unified reality/knowledge graph with lineage and contradiction handling, civilization/world simulation, and archaeology/history that can preserve and reconstruct knowledge from prior worlds or civilizations. These are design intentions; this checkpoint does not certify their end-to-end implementation or effectiveness.

The inspected research components do not themselves establish a verifiable mission-level contract linking each research priority to a measurable life-preservation or civilizational capability outcome. No evidence in this checkpoint proves that a Type-I roadmap is computed, that civilization-scale resource/energy indicators are measured against authoritative baselines, or that research portfolios are optimized under explicit biosafety, ecological, societal, and human-governance constraints. This is a scoped evidence gap, not a claim that no such documents or components exist anywhere in the repository.

**Proposed mission-to-evidence hierarchy:**

- **Level 1 — Life and catastrophic-risk protection:** identify hazards and uncertainty; prioritize prevention, resilience, early warning, recovery, and biodiversity/ecosystem protection. Measure validated risk reduction, warning lead time, recovery capability, false alarms/missed hazards, and harms introduced by interventions.
- **Level 2 — Reliable scientific capability:** develop and verify instruments, materials, energy systems, medicine/biology, food/water systems, climate/ecology, infrastructure, computation, and mathematical/scientific methods. Each claimed improvement needs domain-specific evidence, independent challenge, replication where feasible, safety review, and a documented failure envelope.
- **Level 3 — Knowledge continuity and civilizational memory:** preserve provenance-rich discoveries, raw data, negative results, methods, designs, software/toolchains, physical artifacts, and historical/archaeological evidence with durable formats, redundancy, integrity checks, rights/context, and recoverability tests. Simulated civilizations or reconstructed artifacts must be clearly labelled as simulations/reconstructions, not historical evidence.
- **Level 4 — Civilization-scale modelling:** define explicit, sourceable indicators for energy capture/use, storage, transmission, material throughput, ecological impact, resilience, access, and governance. Distinguish the Kardashev Type-I concept from a precise universal threshold: select a declared definition, unit system, baseline, time horizon, and uncertainty range before reporting progress. Simulations can compare scenarios but cannot certify real-world progress without external observations and validated models.
- **Level 5 — Governed translation to action:** route discoveries through risk review, human authorization where consequential, staged deployment, monitoring, rollback/recovery, and post-deployment evidence. The system must optimize for human benefit and preservation of life—not raw energy use, capability growth, or self-expansion at any cost.

**Non-negotiable boundary:** Tiannara can research, model, advise, and help validate candidate interventions; it must not infer authority to conduct high-impact experiments, manipulate people or ecosystems, deploy physical systems, or self-modify constitutional/governance rules merely because a mission score suggests benefit. Human authority, safety constraints, uncertainty disclosure, and reversible staging remain binding.

#### 18.50.4 — Disposition and next audit targets

- New finding: **RL-376 — scientific discovery proof obligations are not enforced end-to-end** (OPEN).
- RL-374 remains OPEN: independent epistemic correction is not enforced end-to-end.
- RL-375 remains OPEN: contradiction handling does not universally invalidate and re-evaluate downstream claims.
- No findings closed. Source modifications: **0**. Runtime tests, experiments, and physical actions: **NOT RUN**.
- Next checkpoint 18.51 should trace the concrete mission/strategy and world-model/archaeology components that claim to represent civilization progress and preserved discoveries; distinguish authoritative observations from simulation outputs; identify real storage/recovery paths for research artifacts; and map each mission metric to a source, owner, validation gate, and downstream consumer. Keep implementation separate until that audit map is grounded.

### Checkpoint 18.51 — civilization roadmap, archaeological evidence, and preservation of all life

**Scope and method:** Read-only inspection at frozen source baseline `e71bc230a8d38f3a0108012685ae1a052d195b00`. Explicit mission clarification from the user: **“life” means all life, including plant and animal life**, not humans alone. The scope therefore includes humans and other animals, plants, fungi, microorganisms and other living systems, along with the habitats and ecological relationships on which they depend. This checkpoint examines civilization-roadmap documents, world-model implementations, scientific archaeology specifications and their stated verification status. Source/document inspection only; no code changes, runtime tests, replay bundles, ecological measurements or physical actions were performed.

#### 18.51.1 — The Type-I roadmap is specified, but the inspected planning document explicitly says runtime implementation does not exist

- `tiannara_runtime/priv/certification/phase22/KARDASHEV_PLANNING_ARCHITECTURE.md` (blob `05bb54c00863c183c55505f8030d68d170958624`) describes roadmaps for energy capture, infrastructure, science and engineering, and says Kardashev progression must not be pursued at the expense of human well-being or constitutional integrity. Its acceptance criteria include verifiable milestones, risk assessment, replay and archaeology. Crucially, the document explicitly states **“No runtime implementation exists.”** The roadmap is therefore a specification, not proof of a functioning civilization-planning capability at this frozen baseline.
- `tiannara_runtime/priv/certification/phase22/KARDASHEV_METRICS.md` (blob `1cf324eaf796baa3d02deeaddc9982051b8274d5`) lists readiness and transition metrics, including scientific, engineering, infrastructure, institutional and energy readiness, planetary coordination, capability maturity, transition confidence, replay stability and archaeology completeness. The inspected metric contract does not establish a comprehensive, mandatory life-preservation/ecological-integrity score or prove that its values are computed from authoritative external observations. Targets in a document are not measured outcomes.
- The mission must therefore not optimize energy capture or technology growth as a standalone objective. A Type-I trajectory should be evaluated alongside the state of the biosphere, human and non-human welfare, ecosystem integrity, equitable resilience, resource constraints and uncertainty. The energy/civilization scale is one dimension of progress, not a sufficient definition of a flourishing civilization.

#### 18.51.2 — World-model prediction and contradiction detection contain a concrete non-evidentiary path

- `lib/tiannara/graph/world_model.ex` (blob `3521f3b4e3707eb2f139bd517b30a489060c8826`) describes `predict_outcome/1` as graph traversal, then returns fixed `collapse_probability: 0.05` and `success_probability: 0.95` rather than deriving those probabilities from a validated predictive model. Its `detect_contradictions/0` returns an empty list with a comment indicating simulation. These are source-visible placeholders on this implementation path, not validated predictive or contradiction-detection results.
- `lib/tiannara/core/world_model.ex` (blob `e6badff7bebebc55398bf17699132054966cd46c`) documents a broad canonical-reality model containing entities, beliefs, causal graph, timelines, predictions, uncertainty and ontology. The inspected excerpt shows an in-memory-style map update and confidence-threshold query, but does not itself establish a durable, globally authoritative store or prove every system uses this representation.
- These similarly named world-model modules make ownership and production routing an explicit audit question: callers, supervisors, adapters, data stores and deployment configuration must be mapped before asserting that the placeholder graph implementation is the only active path. Until that is verified, its fixed probabilities and empty contradiction result must not be presented as system-wide behavior; equally, no caller may treat those values as real-world evidence.

#### 18.51.3 — Archaeology contracts preserve important scientific history, but end-to-end coverage is incomplete

- `SCIENTIFIC_ARCHAEOLOGY.md` (blob `8ad4859f6e35d074faac0545818b13be63929c51`) specifies preservation of observations, hypotheses, experiments, evidence, negative results, refutations, theory revisions, laws, reversals and certificates as immutable versioned records. It describes hash/manifest verification, replay with recorded seeds and logical clocks, state-root comparison, graph reconstruction and reporting of missing strata without deleting them. It explicitly states that no independent long-horizon archaeology replay bundle is present and certification remains blocked.
- `DISCOVERY_ARCHAEOLOGY.md` (blob `b99b1f30e04e653993be59b931ed25a98b7f9b9f`) reports validation-kernel checks for deterministic theory revision lineage, tampered-evidence detection, order-independent graph reconstruction, reconstructed balances and ownership attribution. It also states that end-to-end archaeology across legacy Phase 15 registries remains pending an independent auditor and canonical export adapter. This is scoped kernel evidence, not whole-system archaeology certification.
- `ARCHAEOLOGY_IMPLEMENTATION_REPORT.md` (blob `69c5cd8019c8a9eddb9fd894dad2f65cee497b72`) describes a broader runtime-object provenance architecture and reports completion. These status claims must be reconciled with the narrower scientific-archaeology document that says independent long-horizon replay is missing. Different scopes and claims must remain distinct until artifact-level evidence demonstrates that they agree.
- A robust preservation system must archive failed experiments, negative findings, uncertainty, original observations, methods, provenance and revisions—not only accepted discoveries. For archaeology of previous simulated worlds/civilizations, it must distinguish generated simulation artifacts from observations of actual past societies or physical archaeological sites. Reconstructed histories must retain confidence, alternative interpretations and missing evidence rather than being relabelled as direct observation.

#### 18.51.4 — Finding RL-377: life-preservation and ecological integrity are not established as enforceable mission-level gates

**Status:** OPEN — source/document evidence gap; complete repository-wide search, external-data integrations and runtime enforcement remain unverified.

**Scope clarification:** Tiannara's preservation-of-life mission covers **all life**, including humans, non-human animals, plants, fungi and microorganisms, plus the ecological relationships and habitats needed to sustain life. This does not mean every organism or ecosystem can be protected from every natural process; it means the system must explicitly account for life and ecological effects rather than treating non-human life as invisible or merely as a resource.

**Evidence:** The inspected Kardashev planning specification emphasizes energy, infrastructure, science, engineering and human well-being, while the listed readiness metrics do not establish a mandatory, independently measured all-life/ecological-integrity gate. No evidence in this checkpoint establishes that a proposal with severe unmeasured biodiversity loss, habitat destruction, animal harm, plant-system damage, microbial/ecological disruption or long-term biosphere risk is automatically held from recommendation or action.

**Risk:** A civilization roadmap could improve an energy or capability score while worsening extinction risk, ecosystem resilience, soil and water systems, biodiversity, or the welfare of sentient animals. A general “environmental risk” field is insufficient unless relevant impacts are measured, uncertainties exposed, thresholds governed, and adverse results connected to enforceable decision gates.

**Required control design (proposed, not implemented by this checkpoint):**
1. Make preservation of life a first-class constitutional mission constraint covering humans and non-human life, with explicit ecosystem dependencies and time horizons.
2. For each consequential proposal, require a context-appropriate impact assessment: species and habitat effects, biodiversity, animal welfare where relevant, plant communities, microbial/ecosystem processes, water/soil/air, cumulative impacts, reversibility, uncertainty and plausible indirect effects.
3. Use authoritative, dated and geographically appropriate observations with provenance; distinguish measured field data, remote sensing, expert inference, model outputs, synthetic data and simulations.
4. Apply precautionary holds when plausible severe or irreversible harm cannot be adequately assessed. Missing ecological evidence must not be silently treated as zero harm.
5. Require independent ecological/scientific review and authorized human decision-making for high-impact interventions. Do not let a civilization-score optimizer trade away unrepresented life or bypass constitutional review.
6. Track both intended benefits and observed harms after deployment; stop, mitigate or roll back when monitored outcomes breach approved thresholds.
7. Test that scenarios with increased energy/technology but major biodiversity loss, habitat damage or severe animal harm are not automatically scored as mission successes.

#### 18.51.5 — Finding RL-378: a graph world-model path returns fixed predictive probabilities and no contradictions

**Status:** OPEN — source-confirmed behavior in `lib/tiannara/graph/world_model.ex`; callers, production reachability and system-wide impact not established.

**Risk:** If a consumer treats the returned 0.95 success probability or 0.05 collapse probability as an evidence-derived forecast, it could overstate confidence in interventions. An empty contradiction list from a path explicitly marked as simulation cannot establish that no contradictions exist. This is especially hazardous if these outputs inform civilization-scale or ecological decisions.

**Required controls:** Identify every caller and runtime route; label simulated/placeholder outputs as non-evidentiary; reject their use as real-world validation; replace them only through a separately audited implementation using calibrated models, traceable inputs, uncertainty intervals, out-of-sample evaluation and comparison against observed outcomes. Until then, this path must not certify safety, ecological outcomes, transition readiness or discovery truth.

#### 18.51.6 — Disposition and next targets

- New findings: **RL-377 — all-life preservation and ecological integrity are not established as enforceable mission-level gates** (OPEN); **RL-378 — graph world-model path returns fixed predictive probabilities and no contradictions** (OPEN).
- RL-374, RL-375 and RL-376 remain OPEN. No findings closed.
- Source modifications: **0**. Runtime tests, archaeological replay, ecological measurements and physical actions: **NOT RUN**.
- Next checkpoint 18.52: trace callers and supervisors for both world-model implementations; identify the actual source, persistence and consumer paths for Kardashev metrics; map any planetary/ecological/life-related models and data feeds; inspect which proposals and actions consume those outputs; and reconcile archaeology completion claims against executable, independently replayable artifacts. Keep the frozen source baseline and distinguish specified, implemented, connected, measured and independently verified capabilities.



### Checkpoint 18.52 — world-model routing, civilization metrics, ecological observability, and archaeology evidence

**Audit boundary:** Source inspection only, pinned to `e71bc230a8d38f3a0108012685ae1a052d195b00`. Repository-wide search results were used to locate candidate paths, then key files were fetched at the frozen commit. Search indexing is not proof of complete caller enumeration. No source files were changed.

#### 18.52.1 — The “canonical world model” is specified more broadly than the inspected implementation demonstrates

- `lib/tiannara/core/world_model.ex` defines a `WorldModel` struct with entities, beliefs, causal graph, timeline, predictions, ontology, uncertainty and version metadata. `new/0` creates an empty in-memory value; `update/3` returns a modified struct. By itself this module does not establish durable persistence, a singleton authoritative store, synchronization across shards, or automatic propagation to every subsystem.
- `lib/tiannara/core.ex` holds a world-model value inside a returned Core state map and updates that state through explicit function calls. Its own documentation says MetaCognition consultation is not implemented on this path and preserves the prior state on error. This is evidence of a state-passing implementation, not proof of a universal canonical reality service.
- Search identified additional world-model consumers and parallel implementations, including `lib/tiannara/core/world_model/runtime_api.ex`, `lib/tiannara/core/world_model/api.ex`, `lib/tiannara/core/world_model/belief_system.ex`, shard-scoped `EntityRegistry`/supervisor code, and `lib/tiannara/graph/world_model.ex`. They represent different interfaces and state lifecycles; no evidence yet proves one authoritative shared representation, a complete bidirectional synchronization protocol, or consistent epistemic semantics across them.
- **Audit disposition:** Treat “single source of truth” as an architectural claim until the ownership map, startup/supervision, durable stores, shard boundaries, callers, update propagation and failure/recovery semantics are verified. CEL’s whole-system understanding will need a generated, source-backed capability/dependency graph that includes these parallel models and marks unknown edges rather than assuming connectivity.

#### 18.52.2 — Finding RL-378 refined: fixed graph-world-model probabilities are reached by a demonstration entry point

- `lib/tiannara/graph/world_model.ex` calls `UnifiedRealityGraph.trace_impact/2` and returns fixed probabilities `0.05` and `0.95`; `detect_contradictions/0` returns `[]` with an explicit simulation comment.
- The frozen-baseline search found a direct caller in `run_production_crucible.exs`, where the returned success probability is logged as the predicted success of an intervention. That script labels itself a 14-day simulation/demo, but its log messages describe production deployment and a measured boot-time reduction without evidence in the script that those actions or measurements actually occurred. Therefore the output is demonstrably consumed by a demonstration path, while real production reachability remains unverified.
- `UnifiedRealityGraph.trace_impact/2` is marked deprecated in favor of `trace_lineage/1` or `blast_radius/1`. The inspected graph module keeps its graph in a GenServer-owned `:digraph`; this source excerpt does not establish durable recovery across process restart. An impact trace is graph traversal, not a calibrated forecast.
- Search also found `lib/tiannara/core/world_model/runtime_api.ex` with a separate `predict_outcome/2` helper that uses a simplified base likelihood of `0.8`. It is another independent prediction path, not evidence that the graph module is the only source. Full caller and consumer enumeration remains pending.
- **Required control:** label all such outputs by implementation, execution mode and evidence class; never let a demo, fixed prior or graph traversal satisfy forecast validation, ecological impact review, safety certification, or civilization readiness. Tests must prove that placeholder or stale predictions are rejected by every consequential consumer.

#### 18.52.3 — Finding RL-379: Kardashev metrics are specified, but computation and authoritative evidence paths are not established

**Status:** OPEN — design/runtime integration and measurement evidence gap.

- `tiannara_runtime/priv/certification/phase22/KARDASHEV_METRICS.md` specifies targets for scientific, engineering, infrastructure, institutional and energy readiness; planetary coordination; capability maturity; transition confidence; replay stability; and archaeology completeness. It says readiness is a composite, coordination a weighted average, capability maturity a domain average, and transition confidence calibrated. The inspected document does not define the underlying canonical observations, units, formulas, source authority, freshness bounds, missing-data treatment, uncertainty propagation, independent evaluator, or executable computation.
- `KARDASHEV_PLANNING_ARCHITECTURE.md` explicitly states “No runtime implementation exists.” The declared targets are therefore not proof that the metrics are computed, achieved or safe to use as gates.
- The Phase 25.9 Civilization Panel specification adds environmental/resource/social sustainability and intergenerational equity indicators, plus civilizational health dimensions. It names CMFCSE and other Phase 25 engines as data sources, but the inspected specification does not define biodiversity, habitat, animal welfare, plant communities, microbial/ecosystem function, or ecological thresholds as mandatory mission gates. Nor does this document alone prove that its named sources emit independently measured, current values.
- Observatory search results include dashboard/API routes for civilization/Kardashev data, while the inspected status controller contains hard-coded example subsystem/status data and pseudo-random resource values. These are not evidence of actual planetary measurements. The exact live route and data provenance for Kardashev projection remain to be traced.
- **Required control:** publish versioned metric contracts with units, formulas, baselines, source provenance, collection time, uncertainty, calibration and missing/stale-data semantics. The transition index must not average away severe life-preservation violations. A failed or absent life/ecology gate must block readiness certification, not be offset by energy or engineering scores.

#### 18.52.4 — Finding RL-380: archaeology coverage can report “complete” without proving completeness or durable replay

**Status:** OPEN — source-confirmed limitation in the inspected archaeology implementation; end-to-end callers and other implementations still need mapping.

- `tiannara_runtime/lib/tiannara_runtime/autonomous_research/phase16_1/research_archaeology.ex` stores records in a public named ETS table. `record/2` inserts a record keyed by a derived artifact ID, while `coverage_report/0` returns the current table size as `coverage_complete`, and hard-codes `coverage_partial: 0` and `coverage_missing: 0`. It does not compare the count against an authoritative expected artifact inventory or verify lineage/evidence/replay for each record.
- The ETS table is in-memory and owned by the process that creates it; the inspected module does not implement durable archival or restart reconstruction. `explain/1` returns a generic provenance explanation and stored lineage references, but does not itself validate that those references resolve to immutable evidence.
- This implementation cannot, by itself, support a truthful claim of complete archaeological coverage or independently replayable history. This is consistent with `SCIENTIFIC_ARCHAEOLOGY.md` stating that no independent long-horizon replay bundle is present and certification remains blocked.
- `ARCHAEOLOGY_IMPLEMENTATION_REPORT.md` says “all runtime objects” have metadata and reports replay tests as passed, while `DISCOVERY_ARCHAEOLOGY.md` narrows its acceptance to a validation kernel and says legacy-registry end-to-end coverage is pending. These claims may concern different scopes; they must be reconciled by a manifest of artifacts, exact test commands/results, immutable test outputs and independent replay evidence before any global completion claim.
- **Required control:** separate `records_seen`, `expected_records`, `coverage_verified`, `coverage_missing`, `lineage_validated`, `replay_verified` and `durability_status`; never infer coverage from table size alone. Make missing strata visible and fail certification closed when the expected inventory, durable export, hashes, replay roots or independent auditor are absent.

#### 18.52.5 — All-life/ecological data and decision routing remain unverified

- Searches for biodiversity/ecological/environment/life-related source paths did not return a traceable end-to-end implementation in the indexed results used for this checkpoint. This is a search limitation, not proof that no such code exists.
- The Civilization Panel document includes generic environmental sustainability but does not demonstrate authoritative ecological data feeds, context-specific impact assessment, precautionary holds, independent review or post-action harm monitoring.
- The audit therefore cannot certify that ecosystem or non-human-life risks are represented in the same decision path as civilization planning, model predictions, executive intent, AEO/OED validation and consequential runtime actions. Follow-up must trace actual routes and consumers at the frozen baseline rather than infer absence from keyword search alone.

#### 18.52.6 — Disposition and next targets

- New finding: **RL-379 — Kardashev metrics lack an established executable, authoritative measurement path** (OPEN).
- New finding: **RL-380 — archaeology coverage can report complete from an in-memory record count without proving completeness or replay** (OPEN).
- RL-377 remains OPEN; RL-378 remains OPEN and is refined with a direct demonstration-script caller plus a separate simplified prediction path. RL-374–RL-376 remain OPEN. No findings closed.
- Source modifications: **0**. Runtime tests, full caller enumeration, ecological measurement validation and independent archaeology replay: **NOT RUN**.
- Next checkpoint 18.53: trace `RuntimeAPI.predict_outcome/2` and every validation caller (including whether validation errors actually stop execution); inspect the live Observatory civilization/Kardashev routes and named CMFCSE/Phase 25 source modules; map life/ecology data and decision-gate consumers using file paths and imports, not keyword search alone; inspect CEL’s dependency/capability inventory path for missing-edge detection. Continue on the same frozen source baseline and ledger branch.


### Checkpoint 18.53 — runtime validation, ecology, and CEL capability graph

**Boundary:** Source inspection only at frozen baseline `e71bc230a8d38f3a0108012685ae1a052d195b00`. No source files changed.

**RL-381 — Runtime validation may discard errors and return success (OPEN).** In `lib/tiannara/core/world_model/runtime_api.ex`, `validate_runtime_operation/2` evaluates `unless` expressions whose error/warning tuples are discarded; execution continues and the final expression is `{:ok, :validated}` if no exception occurs. A missing entity can instead cause an exception when `entity.type` is accessed. The local prediction helper returns fixed likelihood 0.8 and confidence 0.7, independent of input. Direct callers were not established by indexed search. Required: explicit short-circuit validation, typed rejection, and caller-level tests for absent entities, forbidden operations, constraint failures, malformed inputs and mismatched predictions.

**RL-378 remains OPEN.** `Tiannara.Graph.WorldModel.predict_outcome/1` traverses a graph but returns fixed 0.05 collapse and 0.95 success probabilities; contradiction detection returns an empty list for simulation. A separate RuntimeAPI path uses fixed values too. The demo script consumes the graph probability, but production-gate reachability is not established. Neither path may certify consequential actions or ecological safety.

**RL-382 — Ecology implementation is not a verified live pipeline (OPEN).** `lib/tiannara/domains/ecology.ex` computes entropy from caller-supplied biodiversity data but returns empty discoveries/hypotheses/experiments; simulation and validation return unavailable errors; metrics are nil with `data_source: :unavailable`. This is a truthful quarantine. The Phase 25.3 biosphere and Phase 25.9 planetary-panel documents specify ecosystems, biodiversity and candidate data sources, but do not prove live ingestion, dated observations, provenance or decision gates. `tiannara_runtime/lib/tiannara/sentinel/monitors/ecological_monitor.ex` starts with empty state and contains no monitoring logic in the inspected file. End-to-end observation → assessment → review → action gate → post-action monitoring remains unverified. Missing measurements must not be interpreted as zero harm; the all-life scope includes plants, animals, fungi, microorganisms, habitats and ecosystem relationships.

**CEL capability inventory limitation.** `lib/tiannara/cel/services/capability_graph.ex` models declared capabilities, dependencies and mission consumers and exposes graph-analysis APIs. This does not establish automatic extraction of every source, runtime, configuration, build, data-feed and governance dependency. Graph health scores based on graph statistics do not prove inventory completeness. Required: reconcile graph edges against source/call graphs, supervision, configuration, CI/build paths and runtime telemetry; make unknown edges explicit and avoid self-certifying completeness.

**Observatory route limitation.** `tiannara_observatory/apps/observatory_ui/src/lib/api.ts` calls `/civilization/kardashev`, expecting `status` and `projection`. The candidate controller path could not be fetched at this frozen ref, so backend computation, persistence, provenance and freshness remain unknown. Trace route → handler → service → observation → storage → UI before treating it as live data.

**Disposition:** RL-381 and RL-382 added OPEN; RL-377 through RL-380 remain OPEN. No findings closed. Source modifications: 0. Runtime tests and end-to-end route checks: NOT RUN.

**Next checkpoint 18.54:** locate the actual Kardashev route handler; inspect Phase 25.1–25.3 observation/digital-twin implementation; trace capability graph persistence and callers; trace runtime validation callers and execution paths.


### Checkpoint 18.54 — planetary observation paths, Kardashev route, and CEL graph wiring

**Scope and method.** Inspected frozen source at `e71bc230a8d38f3a0108012685ae1a052d195b00`, including the Observatory router/controller, Kardashev engine, ObservationBus facade, CEL CapabilityGraph, and WorldModel RuntimeAPI. Source-only audit; no runtime tests or endpoint requests executed.

**RL-383 OPEN — Kardashev endpoint wiring and values are not evidence-backed.** The router declares `GET /api/v1/civilization/kardashev` targeting `CILController.kardashev_status` (`tiannara_observatory/apps/observatory_api/lib/observatory_api_web/router.ex`). The inspected handler implementing `kardashev_status/2` is in `StatusController`, while the expected `CILController` source path could not be fetched at the frozen ref and indexed search did not establish the handler there. Thus the actual route-to-handler binding remains unresolved. The ObservationBus facade delegates to `ObservationBus.CIL.Civilization.KardashevEngine`; its `init/1` initializes fixed levels, energy values, growth rate, projections, and a fresh `updated_at` timestamp, and `get_status/0` returns that in-memory state. No observation source, units validation, provenance, freshness validation, uncertainty, or measured-input computation is present in that engine. A current timestamp therefore does not establish current measurement. Do not use this output as authoritative civilizational measurement or as a life/ecology safety gate.

**RL-384 OPEN — Phase 25 planetary observation/digital-twin implementation remains unverified.** The Phase 25.9 panel and Phase 25.3 biosphere model describe PSE (planetary state), CGON (observations), and CPDT (digital twin) as dependencies/data sources. Attempts to fetch plausible Phase 25.1–25.3 runtime implementation paths returned 404; indexed searches for the expected PSE/CGON/CPDT runtime symbols did not establish their executable modules. This is a path/search limitation, not proof that no implementation exists. The required chain remains unverified: external observation ingestion → timestamps/source/license/units/provenance and quality checks → normalized planetary state → digital-twin model version and uncertainty → independent validation → ecological impact assessment → authorization gate → post-action monitoring. Missing or stale ecological data must not be interpreted as zero harm.

**RL-385 OPEN — CEL CapabilityGraph is a finite seeded in-memory graph, not demonstrated whole-system inventory.** `lib/tiannara/cel/services/capability_graph.ex` creates a protected `:digraph` in `init/1`, seeds six named subsystems and a finite list of capabilities/dependencies, and stores metadata/counters in the GenServer state. Export enumerates the current graph. The inspected implementation does not establish durable graph persistence/reconstruction or automatic extraction of all source, runtime, configuration, build, data-feed, supervision, and governance dependencies. A graph export or healthy/statistics response only describes currently registered vertices/edges; it cannot certify whole-system coverage. Existing mutation recording to ExecutiveMemory does not by itself prove complete, durable reconstruction. CEL must reconcile declared graph edges with independent source/call/build/supervision/runtime evidence, explicitly represent unknown edges, and report coverage gaps rather than self-certify completeness.

**RL-381 follow-up — runtime validation call reachability remains unresolved.** Search for `validate_runtime_operation(` at the frozen source found its definition in `lib/tiannara/core/world_model/runtime_api.ex`, but no additional direct call site in indexed results. Search indexing is not a complete call graph, so production reachability remains unknown. The function's previously recorded discarded `unless` error tuples and fixed prediction values remain an open safety defect until callers and enforcement paths are traced and tests prove rejection behavior.

**Disposition:** RL-383, RL-384, and RL-385 added OPEN. RL-377 through RL-382 remain OPEN; no findings closed. Source modifications: 0. Runtime tests and live endpoint checks: NOT RUN.

**Next checkpoint 18.55:** resolve the route target/controller implementation from the frozen tree; inspect Observatory startup supervision and Kardashev engine consumers; locate Phase 25 modules by repository tree/search rather than guessed paths; trace CapabilityGraph callers and ExecutiveMemory mutation durability; continue mapping CEL whole-system inventory evidence.


### Checkpoint 18.55 — route dispatch and CEL graph audit

**Scope:** frozen baseline `e71bc230a8d38f3a0108012685ae1a052d195b00`; source inspection only, no build, tests, or live HTTP request.

**RL-386 OPEN — Kardashev route dispatch unresolved.** The router maps `/api/v1/civilization/kardashev` to `CILController.kardashev_status`. The expected `cil_controller.ex` path returns 404 at this ref; indexed search locates `kardashev_status/2` in `StatusController`, which calls ObservationBus status/projection functions. This is evidence of a route/handler mismatch, but not proof of runtime failure: another module definition or route compilation behavior was not ruled out. Inspect full module declarations and verify with a build and route request before claiming the endpoint works.

**RL-387 OPEN — CapabilityGraph can acknowledge mutations after audit-record failure.** `lib/tiannara/cel/services/capability_graph.ex` implements `record_mutation/3` by calling `ExecutiveMemory.record_event/2` inside `try/rescue`, returning `:ok` on rescue. Mutation handlers can then return successful results without confirming the audit event. Governance-sensitive changes therefore lack guaranteed audit correspondence. Surface persistence failures and fail closed or use a durable outbox before acknowledging; test memory outages, write errors, restart and replay.

**CEL integration — partial, not comprehensive.** `Tiannara.CEL.Services.ExecutiveStateManager` consumes `CapabilityGraph.stats/0` for capability totals and single-point-of-failure counts. This confirms a summary consumer, not system-wide reconciliation across source, runtime, build, supervision, data feeds and governance. Graph statistics and `healthy: true` do not establish inventory completeness; no denominator or unknown-edge coverage proof was found in inspected code.

**Kardashev follow-up.** `ObservationBus.CIL.Civilization.KardashevEngine.init/1` seeds fixed energy values, current level, growth rate and projections, then timestamps the state. Status returns this in-memory state; projection ETA uses a simple fixed-rate formula. No measurement ingestion, provenance or freshness validation appears in this module. RL-383 remains OPEN.

**Disposition:** RL-386 and RL-387 added OPEN; RL-377 through RL-385 remain OPEN; no findings closed. Source modifications: 0. Runtime validation NOT RUN.

**Next checkpoint 18.56:** find all CILController definitions and route/build wiring; trace Kardashev supervision and input writers; inspect ExecutiveMemory persistence contracts and graph mutation callers; look for CEL reconciliation joining source inventory, builds, supervision and runtime evidence.


### Checkpoint 18.56 — route/build resolution, engine wiring, and audit persistence

**Scope and evidence boundary:** source inspection at frozen source ref `e71bc230a8d38f3a0108012685ae1a052d195b00`; no source edits, build, endpoint request, or runtime tests performed.

- **RL-386 remains OPEN; route mismatch is now better localized.** The router maps `/api/v1/civilization/kardashev` to `CILController.kardashev_status` (`tiannara_observatory/apps/observatory_api/lib/observatory_api_web/router.ex:103`). The candidate `controllers/cil_controller.ex` path returns 404 at this ref; `StatusController` contains a `kardashev_status/2` handler that calls ObservationBus status/projection functions. This supports a likely controller dispatch/build defect, but does not prove compile or request behavior; alternate generated/aliased modules and actual route compilation were not tested. Resolve by aligning route target and verified handler, then compile and exercise the route.
- **Kardashev engine is supervisor-declared, but inputs remain unsubstantiated.** `ObservationBus.CIL.Civilization.Supervisor` includes `KardashevEngine` as a child. The engine initializes fixed values (level 0.72, energy 18,000 TW, growth 0.025 and projections), timestamps initialization with `DateTime.utc_now()`, and exposes read-only status/projection calls; no state-update or observation-ingestion handler appears in this module. This confirms intended supervision wiring in source, not that the application boots or that values are measured. RL-379 and RL-383 remain OPEN.
- **RL-387 remains OPEN; durable event append and mutation acknowledgement disagree.** `ExecutiveMemory.record_event` returns `{:ok, id}` only after `EventStore.append/2` succeeds and returns `{:error, reason}` on append failure. On DETS open failure it explicitly falls back to volatile ETS and marks itself degraded. In contrast, `CapabilityGraph.record_mutation/3` rescues exceptions and returns `:ok`; graph mutation handlers do not check that helper's outcome before proceeding. Consequently the graph can acknowledge a mutation without confirming its audit record; this is distinct from ExecutiveMemory's explicit append error handling. Require a checked result or durable outbox for governance-sensitive changes, surface degraded persistence to callers, and test append failure, process exit, restart and replay.
- **Whole-system CEL reconciliation remains unproven.** CapabilityGraph seeds a finite set of subsystem/capability vertices and dependency edges in `init/1`; its declared graph API and ExecutiveStateManager statistics are not evidence of automated reconciliation across source files, build outputs, application supervision trees, runtime processes/telemetry, data feeds, and governance/authorization relationships. Search results alone cannot prove no such reconciler exists elsewhere. CEL must label inventory coverage and unknown edges explicitly, cross-check independent inventories, and refuse to represent an incomplete graph as whole-system understanding.
- **Finding disposition:** RL-386 and RL-387 remain OPEN; RL-379 and RL-383 remain OPEN; no finding closed. Source modifications: 0. Runtime/build/endpoint validation: NOT RUN.

**Next checkpoint 18.57:** inspect route compilation/build configuration and controller module definitions across the observatory app; trace all writes to Kardashev state and data provenance; inspect EventStore durability, synchronization and restart behavior; trace CapabilityGraph mutation handlers for ignored audit outcomes and identify any separate evidence-backed whole-system reconciliation pipeline.


### Checkpoint 18.57 — route/build resolution, engine wiring, and audit persistence

**Scope:** frozen source ref `e71bc230a8d38f3a0108012685ae1a052d195b00`; source inspection only.

- **Kardashev controller module is present, but split across a file.** The fetched `status_controller.ex` contains both `ObservatoryApiWeb.StatusController` and a later `ObservatoryApiWeb.CILController` module; `kardashev_status/2` is defined in the latter section of that file. The separately named `controllers/cil_controller.ex` path returns 404 at this ref, but that alone is not a missing-module defect. This resolves the earlier path-based uncertainty about whether a CILController definition exists.
- **Route target still requires build/runtime confirmation.** Router maps `/api/v1/civilization/kardashev` to `CILController.kardashev_status`, and the same module/function is source-defined in `status_controller.ex`. No Mix compilation, route introspection, HTTP request, or endpoint test was run, so successful dispatch remains UNVERIFIED rather than failed or passed.
- **Kardashev process is supervised but not evidence-fed in the inspected implementation.** `ObservationBus.CIL.Civilization.Supervisor` includes `KardashevEngine`; the broader CIL supervisor includes the civilization supervisor. Engine `init/1` seeds fixed values and `updated_at`; the inspected engine has status/projection reads but no state-update or external observation-ingestion handler. No authoritative measured input, units/quality/provenance/freshness check, or independent validation was established.
- **ExecutiveMemory reports append errors, but its index path is weaker than its event-store path.** `ExecutiveMemory.handle_call({:record,...})` checks `EventStore.append/2` and returns `{:error, reason}` on append failure. On success, it calls `store_index/2`, which invokes `:dets.insert/2` without checking the return value; lineage/lesson queries read this DETS index, while replay reads EventStore. A successful append therefore does not establish that the secondary index is consistent or queryable. Additionally, if DETS cannot open at startup, ExecutiveMemory enters volatile ETS degraded mode, but the inspected record handler still routes writes through EventStore and the index helper still targets the DETS table. Exact behavior under this mixed degraded state is not runtime-tested.
- **EventStore persistence is explicit but not equivalent to complete audit durability.** It writes to DETS and returns append errors; startup failure sets degraded mode and append refuses writes. Some read APIs return empty lists or offset zero when degraded, which can be mistaken for an empty history unless callers also check health/stats. No crash/restart, fsync durability, archive rotation, corruption, or concurrency test was executed.
- **RL-387 follow-up remains OPEN.** CapabilityGraph's `record_mutation/3` catches/rescues audit-write failures and returns `:ok`; mutation handlers ignore whether the corresponding event was durably recorded. ExecutiveMemory's append error result does not repair that swallowed outcome. Require a checked audit result or durable outbox before acknowledging governance-sensitive mutations, and test EventStore outage, DETS/index failure, restart and replay.
- **Whole-system CEL reconciliation remains UNVERIFIED.** Searches and inspected graph/state-manager sources establish a finite capability graph and aggregate statistics, not a reconciler that cross-checks source inventory, build outputs, application supervision trees, live runtime processes/telemetry, data feeds, and governance edges. Search coverage is not proof no other reconciler exists. Unknown/missing edges must remain explicit and graph completeness must not be inferred from healthy status or counts.

**Disposition:** RL-386 route concern narrowed: module/function are source-defined in the same controller file; runtime dispatch remains unverified. RL-387 remains OPEN. Related durability/reconciliation gaps remain OPEN; no findings closed. Source modifications: 0. Runtime/build/endpoint validation: NOT RUN.

**Next checkpoint 18.58:** inspect Kardashev state-writing alternatives and the complete controller/router/build setup; trace EventStore pruning/rotation and executive-memory index recovery contracts; examine other CEL graph reconciliation/inventory modules and any claimed source/runtime/build coverage evidence.


### Checkpoint 18.58 — retention, rotation, and recovery contracts

**Scope:** frozen source ref `e71bc230a8d38f3a0108012685ae1a052d195b00`; source inspection only.

- **Kardashev writer search:** exact symbol searches found the engine initialization and read APIs, but no matching `handle_cast`, update handler, or writer for its seeded energy/level fields. The inspected GenServer exposes only status/projection calls. Search indexing is incomplete, so this is not proof that no external replacement/restart/configuration exists; no authoritative observation feed or writer was established.
- **Controller/build wiring:** `CILController` and `kardashev_status/2` are defined in `status_controller.ex`; router points to that module/function. Observatory API Mix config declares the in-umbrella `observation_bus` dependency. This is coherent source-level wiring, not a successful compile or HTTP dispatch proof.
- **RL-388 OPEN — EventStore retention and archive policy do not establish long-term audit preservation.** EventStore's default event retention is 168 hours (7 days), while Rotator defaults to retaining at most two archives and expiring archives after 60 minutes. Rotation archives the old complete DETS file, but archive reaping deletes expired/overflow archives. Thus the implementation provides bounded operational retention, not indefinite audit-history preservation; the inspected code does not establish an immutable external archive/anchor for pruned events. Confirm required retention policy, legal/mission audit obligations, backups and external anchoring before treating EventStore as a durable historical audit record.
- **RL-389 OPEN — EventStore prune can report deletions without checking each delete result.** `handle_call(:prune,...)` gathers stale keys, calls `:dets.delete/2` via `Enum.each` while discarding each return, then replies `{:ok, length(stale_keys)}`. A failed delete can therefore be counted as pruned. The lifecycle manager logs the reported count as completed pruning. Check every delete outcome, report partial failure, and verify remaining keys.
- **RL-390 OPEN — ExecutiveMemory secondary index write and degraded backend mismatch.** Event append success is followed by unchecked `:dets.insert/2`; lineage, lesson search and snapshots use this index, while replay reads EventStore. At startup DETS-open failure selects volatile ETS state, but the record path still appends to EventStore and writes the named DETS table; the fallback ETS reference is not used by the inspected read/write functions. No recovery/rebuild path from EventStore into the index was established. Make EventStore canonical, rebuild/validate the index, surface index degradation, and test restart and partial failures.
- **Rotation/lifecycle qualifications:** Rotator documents a careful sync/close/rename sequence and attempts rollback, but the inspected rollback is best-effort and its reopen result is only logged. DetsLifecycle catches rotation errors and logs them, but its sweep does not retain a per-store failed/degraded state or expose a failure counter in the inspected code. These are recovery/observability gaps to validate with fault-injection; no failure was executed here.
- **CEL inventory reconciliation:** targeted searches for a source scanner/runtime graph reconciliation module did not surface a concrete end-to-end reconciler. This is search evidence only; no claim of global absence. Existing capability graph remains finite/declared and does not itself prove coverage of all code/build/runtime/data/governance relationships.

**Disposition:** RL-388, RL-389 and RL-390 added OPEN. RL-386 remains narrowed to unverified runtime dispatch; RL-387 remains OPEN. No findings closed. Source modifications: 0. Runtime/build/fault-injection tests: NOT RUN.

**Next checkpoint 18.59:** trace EventStore callers and audit consumers for retention assumptions; inspect ResilientDETS and storage backup/restore/verification; examine lifecycle registration retry claims and failure telemetry; continue CEL whole-system inventory discovery from concrete repository/build/runtime collectors.



### Checkpoint 18.59 — event consumers, storage recovery, and CEL inventory

**Scope:** frozen source ref `e71bc230a8d38f3a0108012685ae1a052d195b00`; source inspection only. Tests were read, not executed.

- **EventStore consumers and history:** `ExecutiveMemory` is a concrete consumer: it appends events, reads EventStore for replay, and maintains a separate DETS index for lineage/lessons/snapshots. The source establishes this consumer path, but the inspected callers do not establish a contractual audit-retention period longer than the seven-day default. RL-388 therefore remains OPEN as a preservation-policy gap, not a claim that a particular security/audit consumer requires a longer period. Historical probe artifacts mention the append path, but are not proof of current end-to-end durability.
- **RL-391 OPEN — DetsLifecycle registration is not self-healing after lifecycle restart.** Each store registers by calling `DetsLifecycle.register/1` during its own `init/1`. The lifecycle GenServer starts with an empty `stores: %{}` map; its sweep iterates only that map and has no discovery/re-registration mechanism. If DetsLifecycle restarts while a registered store remains alive under an independent supervisor, the registry is lost and the live store does not call register again. The module documentation explicitly claims missed registrations are retried on the next sweep, but the inspected sweep does not implement that retry. The root application starts DetsLifecycle before CEL boot, which supports initial registration ordering, but does not solve an isolated lifecycle-process restart. Reconcile the documentation and implement supervised re-registration/discovery or shared durable registration; expose missing-store coverage.
- **RL-392 OPEN — ResilientDETS may transition to a fresh empty store after failed repair without a verified recovery gate.** On `{:needs_repair, _}`, it attempts a file copy to a timestamped `.corrupt.` path but only logs a copy failure; it then retries with `repair: true`. If repair fails, it attempts to rename the original to `.quarantine.` (discarding the rename result) and opens a fresh DETS file. The EventStore caller explicitly uses `repair: false`, which routes through this helper. No checksum/record-count validation, verified archive/quarantine success requirement, restore workflow, operator approval, or explicit data-loss state was established in the inspected helper. This can permit service startup on a new empty store after repair failure, while preservation of the old data is not guaranteed by checked return values. Require verified preservation and explicit degraded/restore decision before creating a fresh canonical store.
- **Storage tests reviewed (not run):** Rotator retention tests assert the configured archive cap/TTL and live-file survival; lifecycle tests cover successful rotation, compaction, empty-store rotation and successful prune counts. The prune test store itself also ignores individual delete results. These tests do not establish corrupt-store recovery, failed archive/quarantine handling, failed DETS deletes, restore integrity, lifecycle restart/re-registration, or end-to-end audit retention. Test presence is not a pass result.
- **CEL inventory reconciliation:** the CapabilityGraph remains an explicitly seeded, in-memory graph. The ExecutiveStateManager consumes only graph counts/SPOF/deprecated totals and converts several service-query failures into empty/zero defaults; its confidence calculation only counts three missing service-health keys. These summaries do not establish whole-repository, build, supervision, runtime-process, data-feed, or governance-edge inventory. No concrete cross-source reconciler was established in this checkpoint; search coverage is incomplete and is not proof of global absence.
- **ResilientDETS path confirmed:** `lib/tiannara/cel/services/resilient_dets.ex`. The initially guessed `lib/tiannara/storage/resilient_dets.ex` path does not exist at the frozen ref; this is a path correction, not a missing-module finding. Root `Tiannara.Application` places DetsLifecycle in core children before CEL kernel boot, so initial boot ordering is source-defined. No supervisor restart experiment or test execution was performed.

**Disposition:** RL-391 and RL-392 added OPEN. RL-388 through RL-390 remain OPEN. No findings closed. Source modifications: 0. Runtime/build/fault-injection/restart/restore tests: NOT RUN.

**Next checkpoint 18.60:** inspect the full CEL service registry and boot/reconciliation lifecycle, including service discovery, dependency declarations, runtime registration/unregistration, health-score defaults, and how service inventory is compared against repository/build/supervision reality. Then trace EventStore/ExecutiveMemory failure propagation into constitutional and security decision consumers. Continue the all-life and human-authority audit after these infrastructure dependencies.



### Checkpoint 18.60 — CEL registry, boot dependencies, and runtime reconciliation

**Scope:** frozen source ref `e71bc230a8d38f3a0108012685ae1a052d195b00`; source inspection only. No runtime, build, restart, or fault-injection tests were executed.

- **Registry is a static catalogue, not whole-system discovery.** `ServiceRegistry.init/1` loads `canonical_services/0`; `discover/0` merely returns non-deprecated entries from that same in-memory map. It does not scan repository modules, build artifacts, supervision children, live processes, telemetry registrations, data feeds, or governance authorities. `register/1` adds caller-supplied specs, but no cross-source reconciler or completeness proof is present in the inspected module. RL-385 remains OPEN; this checkpoint narrows the registry's actual discovery semantics.
- **RL-393 OPEN — Boot dependency sorting can silently omit services when dependencies are missing or cyclic.** `topological_sort/1` returns the accumulated partial order when no remaining node has an empty dependency list; it only logs the cycle. It does not return a structured error or list of omitted services. An unknown dependency likewise remains unresolved and can stop sorting. `BootSequencer.boot/4` consumes the returned list and builds its result only from those entries; the final status is derived from failed/degraded/skipped results, not from a comparison with the full active registry. Thus an incomplete boot order can be reported without an explicit missing/cyclic-service disposition. Validate every dependency against the active registry and fail closed with a complete diagnostic before starting services.
- **RL-394 OPEN — Boot sequencer permits dependents to start when a prerequisite is degraded.** Dependency gating checks only whether a dependency is in `failed_critical`. `handle_degraded/6` does not add the degraded service to that list. Therefore a later service can pass the dependency check even when one of its declared prerequisites failed a non-critical gate and was marked degraded. The boot report may remain degraded, but the dependent is still started; this does not enforce the declared dependency contract. Define explicit acceptable prerequisite states per edge and block or quarantine dependents when the prerequisite is not sufficiently healthy.
- **RL-395 OPEN — CEL service processes are temporary children without automatic restart or kernel liveness reconciliation.** `Kernel.start_service/2` creates child specs with `restart: :temporary`; a service process that exits is not restarted by the DynamicSupervisor. The kernel records service PIDs after boot but the inspected Kernel has no `handle_info({:DOWN,...})` reconciliation path and no periodic comparison of recorded PIDs against live processes/health. The explicit `restart_service/2` path is manual and Council-authorized. This leaves a gap between initial boot certification and continued service availability; add supervised restart policy or explicit fail-closed loss detection, dependent-service handling, and re-certification.
- **Registry/boot authority boundaries:** registry specs are seeded in memory and can be mutated through register/deprecate/replace calls; `replace/2` marks the old entry deprecated and inserts the new spec without validating the new module, dependency closure, duplicate ID semantics or authorization in this module. This is recorded as an audit surface, not a separate finding until callers and external authorization boundaries are traced. Kernel restart authorization currently calls `Council.authorize(..., nil)` despite accepting an `actor` argument; actor attribution/authorization semantics require a focused Council trace before a separate finding is assigned.
- **Constitutional boot checks:** BootSequencer has substantial fail-closed score and independent-evidence logic, including process liveness, health observation, freshness and capability probes. However, advertised capabilities without an implemented probe are explicitly `:unverified`, and only a narrow special case (`:deterministic_replay`) is actively probed. A boot pass therefore is not evidence that every advertised capability works. The resource checker supplied by Kernel is hard-coded to `:sufficient`; no live resource gate is wired through this boot call. This narrows the meaning of boot certification and remains subject to capability-by-capability verification.
- **Event and executive-state consumers:** EventStore returns explicit storage errors for append/replay failures, but ExecutiveStateManager's periodic snapshot handler ignores the return values from both EventBus.publish and ExecutiveMemory.record_event, then increments its snapshot counter and updates its last-snapshot timestamp. Consequently the published/recorded side effects can fail while the local state advances as though the snapshot cycle completed. The EventStore itself refuses append in degraded mode, but some read/count APIs intentionally return empty lists or zero in degraded mode; consumers must consult health/degraded state rather than interpret these as genuine empty history. This checkpoint confirms a concrete propagation gap for executive-state snapshots; security and constitutional decision consumers require further tracing.
- **CEL whole-system visibility remains unproven.** The registry's canonical list is a service catalogue; CapabilityGraph is a separate seeded in-memory capability graph; ExecutiveStateManager consumes aggregate scores and selected service summaries, with multiple rescue defaults to empty maps, zero counts or empty lists. No source-backed reconciliation among these authorities and repository/build/supervision/runtime/data/governance inventories was established. Do not treat registry count, graph count, or a healthy boot report as system completeness.

**Disposition:** RL-393, RL-394 and RL-395 added OPEN. RL-385, RL-388–RL-392 and all prior findings remain OPEN. No findings closed. Source modifications: 0. Runtime/build/restart/fault-injection tests: NOT RUN.

**Next checkpoint 18.61:** trace the ExecutiveService registration/health pipeline and ConstitutionalScorePipeline end-to-end; determine how scores are collected, cached, aged, invalidated after process death, and consumed by Council authorization and emergency decisions. Trace EventBus and ExecutiveMemory write failures into those consumers, including the ExecutiveStateManager snapshot path. Then inspect caller authorization and actor attribution for Kernel lifecycle operations.


### Checkpoint 18.61 — constitutional scoring, health reconciliation, Council authority, and attribution

**Audit boundary:** frozen source commit `68d27377d60e17543bc0ec4901a9ee141852a0e0` in `Kimiti4/Tiannara`. Source inspection only. No source code was modified. No Mix compilation, runtime execution, test suite, fault injection, or authorization integration test was run. Targeted GitHub code search was used for caller discovery; search-index absence is not treated as proof of global absence.

#### 18.61.1 — ConstitutionalScorePipeline is not an evidence-backed certification source

Inspected `lib/tiannara/cel/services/constitutional_score_pipeline.ex`:

- `health/0` always returns `:healthy`.
- `constitutional_score/0` returns hard-coded values (health/alignment/transparency/explainability 1.0, evidence quality 0.95, human oversight 0.6); it does not read the observation window.
- `record_observation/2` is an asynchronous cast. The in-memory window retains at most 100 observations per service, with no durable store or explicit eviction/expiry based on age.
- Constitutional telemetry uses defaults of 0.5 for absent alignment/transparency/evidence-quality metadata. Other attached telemetry events are converted to the same generic 0.5 observation, regardless of their actual semantics.
- Empty windows return a plausible score with health 1.0 and other components 0.5. Aggregated windows also hard-code health 1.0 and human oversight 0.6; explainability is inferred from alignment rather than independently observed.
- No validation of score types/ranges, evidence identity, source provenance, or observation freshness is visible in this module.
- The kernel's boot path invokes each service's registered `constitutional_score_check`; for this service that callback is the hard-coded `constitutional_score/0`, not the telemetry aggregation API. The two paths are therefore not joined for this service's boot certification.

**RL-396 OPEN — ConstitutionalScorePipeline self-certifies from hard-coded values rather than its own observed evidence.** The telemetry window does not feed the service's registered constitutional-score callback, so boot certification can consume the hard-coded score independently of the pipeline's observations.

**RL-397 OPEN — Missing and semantically unrelated telemetry is converted into plausible scores.** Missing score metadata defaults to 0.5, and non-constitutional events receive generic 0.5 dimensions. Unknown, malformed, or non-applicable evidence is not preserved as unavailable.

**RL-398 OPEN — Score observations lack demonstrated freshness, provenance, validation, persistence, and process-death invalidation.** A bounded count window is not a time bound; the inspected aggregation can include arbitrarily old observations until displaced. Recomputing `computed_at` does not refresh the underlying evidence.

#### 18.61.2 — ExecutiveStateManager can report completion without durable side effects

Inspected `lib/tiannara/cel/services/executive_state_manager.ex`:

- The periodic `:generate_snapshot` handler calls `EventBus.publish/2` and `ExecutiveMemory.record_event/3` but discards both return values.
- It then advances `current_snapshot`, increments `snapshots_generated`, and updates `last_snapshot_at` regardless of those results.
- The `force_snapshot` path also increments its counter and updates the timestamp after `build_snapshot/1` without establishing successful publication or persistence.
- Several source-query helpers rescue failures into empty maps, zero counts, `:unknown`, or empty lists. Examples include service health, resource allocation, scheduler, mission/workflow state, and capability statistics.
- `calculate_snapshot_confidence/1` only checks whether three selected service-health keys exist. It does not measure successful collection coverage across all snapshot inputs or distinguish unavailable data from genuine zero/empty observations.

**RL-399 OPEN — ExecutiveStateManager advances snapshot state when publication or memory recording fails.** Local snapshot counters/timestamps can claim completion without confirmed EventBus publication or ExecutiveMemory persistence.

**RL-400 OPEN — Executive-state confidence can conceal unavailable and incomplete source observations.** Rescue defaults and a three-key presence check permit incomplete snapshots to receive confidence values that do not represent actual collection coverage.

#### 18.61.3 — ConstitutionalMonitor defaults to perfect health when it has no evidence

Inspected `lib/tiannara/council/constitutional_monitor.ex`:

- The monitor starts with an empty `service_scores` map and `last_report: nil`.
- Its empty-input branch reports `aggregate_constitutional_score: 1.0` while `services_monitored: 0`.
- For each reported service, absent alignment, transparency, explainability, evidence-quality, and human-oversight fields default to 1.0.
- `report_score/2` stamps the current time, but no age-based expiry, source timestamp validation, service inventory reconciliation, or stale-score invalidation is implemented in the inspected module.
- The aggregate uses only constitutional alignment; the other reported dimensions do not affect that aggregate.
- Targeted caller searches did not establish a direct connection from `ConstitutionalScorePipeline.record_observation/2` or `all_scores/0` into `ConstitutionalMonitor.report_score/2`. This is an integration gap not yet proven globally absent; broader call-graph/runtime verification remains required.
- `ExecutiveStateManager.get_constitutional_status/0` maps an unavailable/other monitor result to `:compliant` through its catch-all branch, rather than preserving unknown.

**RL-401 OPEN — ConstitutionalMonitor can report a perfect aggregate with zero monitored services or incomplete score fields.** Empty or missing evidence is treated as full compliance, and stale score invalidation is not established. This can flow into ExecutiveStateManager's `:compliant` fallback when the monitor report is unavailable.

#### 18.61.4 — Kernel lifecycle authorization does not preserve the requesting actor

Inspected `lib/tiannara/cel/kernel.ex`, `lib/tiannara/council/council.ex`, `lib/tiannara/council/execution_context.ex`, and `lib/tiannara/council/rule_engine.ex`:

- `Kernel.restart_service/2` accepts an `actor`, but the handler calls `Council.authorize(:architectural_change, %{action: :restart, service: id}, nil)`. The actor is absent from both the authorization payload and execution context.
- `Kernel.halt/2` includes actor in its payload but still supplies `nil` as the Council execution context. No typed `ExecutionContext` carrying the actor, intent, correlation ID, evidence, and parent lineage is created at this boundary.
- The RuleEngine's accountability assessment reads `payload.actor`; the restart payload therefore scores accountability using its missing-actor fallback.
- Council's authorization API accepts an optional ExecutionContext. The execution-context type explicitly has an actor and correlation ID, but the inspected kernel lifecycle calls do not supply one.

**RL-402 OPEN — Kernel restart authorization drops the caller identity before Council evaluation.** The actor parameter is unused in the restart authorization request; the Council cannot attribute that authorization to the caller from the supplied payload/context. Halt carries actor only as an untyped payload field, not as a structured execution principal/context.

#### 18.61.5 — Council decisions and lifecycle effects lack a proven mandatory audit transaction

- In `Council.handle_call({:authorize, ...})`, normal decisions are evaluated and returned without a general append of the resulting authorization decision to `Council.AuditLog`. The inspected path logs selected exceptional events (for example emergency blocks and hard-invariant overrides), not every approval, conditional grant, deferral, or rejection.
- Kernel lifecycle success logging uses `log_to_council/2`, which catches all failures and returns `:ok`; its caller proceeds regardless of whether the audit append succeeded.
- The kernel audit helper records actor as the fixed value `:kernel`. For restart, the passed actor has already been discarded; for halt, actor appears only in payload.
- These source paths do not establish an atomic or otherwise mandatory link among authorization request, evaluated decision, actor/principal, conditions/evidence, effect execution, and durable audit record. No runtime failure was injected.

**RL-403 OPEN — Ordinary Council authorization outcomes are not mandatorily appended to the audit log in the inspected authorization handler.** The returned authorization object is not itself proof of a durable decision record; normal approvals and denials lack a demonstrated universal append at the decision boundary.

**RL-404 OPEN — Kernel lifecycle actions can proceed when their post-action audit append fails.** `log_to_council/2` suppresses append failures, and lifecycle handlers do not require confirmed durable audit evidence before acknowledging the effect. Actor attribution is further weakened by the fixed `:kernel` audit actor.

#### 18.61.6 — Disposition and next checkpoint

- New findings RL-396 through RL-404: **OPEN**.
- RL-393 through RL-395 and earlier findings remain OPEN; no findings were closed.
- No source code changes. No runtime/build/test/fault-injection validation was performed.
- Search-index non-results are treated as incomplete discovery evidence, not proof of global absence.

**Required remediation direction:** preserve unknown/stale/missing evidence as explicit non-certifying states; compute scores from validated, provenance-bearing observations; reconcile every registered and discovered service against live process and health state; make Council authorization carry a structured principal/context and correlation lineage; require durable decision/effect audit records or fail closed; and test all failure paths including monitor silence, telemetry loss, stale scores, process death, audit-store degradation, and partial snapshot writes.

**Next checkpoint 18.62:** trace the complete Council decision lifecycle from policy/rule evaluation through human approval, conditional-grant satisfaction, authorization consumption, execution, and audit persistence. Inspect emergency invocation/lifting authority and actor attribution; determine whether any caller can bypass Council or replay/forge a grant; trace whether authorization records are bound to exact effect payloads, expiry, nonce/idempotency, and correlation context. Continue the security and human-final-authority audit without treating policy documentation or an Authorization struct as proof of enforcement.


# Checkpoint 18.61 — hardware integration addendum

**Frozen source:** `68d27377d60e17543bc0ec4901a9ee141852a0e0`  
**Scope:** physical deployment, hardware adapter contract, safety verification, telemetry adapters, Meta Hardware subsystem, and tests.  
**Method:** source inspection and targeted caller/path searches only. No hardware was attached; no runtime, compilation, tests, electrical safety checks, or physical actuation was performed.

## Hardware-related source inventory

| Path | What it contains | Evidence classification |
|---|---|---|
| `lib/tiannara/asc/reality/physical_adapter.ex` | Generic adapter callbacks: capabilities, status, execute_action, emergency_stop | Interface contract only |
| `lib/tiannara/asc/reality/physical_deployment_manager.ex` | Deployment lifecycle, approval stage, adapter dispatch, emergency stop/resume | Implemented orchestration, default adapter is simulated |
| `lib/tiannara/asc/reality/adapters/simulated_adapter.ex` | In-memory action recording and simulated E-stop state | Explicit simulation, not hardware |
| `lib/tiannara/asc/reality/safety_verification_engine.ex` | Safety constraint checks | Currently unconditional pass implementation |
| `lib/tiannara/asc/reality/reality_supervisor.ex` | Supervises simulated adapter, safety engine and deployment manager | Runtime wiring for simulation |
| `lib/tiannara/telemetry/adapter.ex` | Generic telemetry behaviour and live BEAM RuntimeAdapter | Runtime metrics only; no hardware adapter found in targeted search |
| `lib/tiannara/meta/hardware/supervisor.ex` | Registry, HorizonScheduler and three EHTC workers | Internal compute subsystem |
| `lib/tiannara/meta/hardware/horizon_scheduler.ex` | Routes payloads to EHTC workers | Internal queue routing |
| `lib/tiannara/meta/hardware/event_horizon_tensor_core.ex` | Queues payloads and spawns compute tasks; comments explicitly describe simulation | Simulated/internal compute, not a device driver |
| `test/tiannara/asc/reality/physical_deployment_manager_test.exs` | Lifecycle tests using SimulatedAdapter | Tests simulation and stage logic only |
| `test/tiannara/asc/reality/physical_deployment_property_test.exs` | Property tests of approval lifecycle using SimulatedAdapter | Tests simulation and stage logic only |

The existing MC-003-A0 architecture assessment independently classifies hardware/robotics execution as absent and the SimulatedAdapter as simulation. The present source inspection is consistent with that assessment.

## Detailed observations

### H-01 — No concrete physical-device adapter established

The PhysicalAdapter behaviour is a useful abstraction, but the inspected implementation is only `Adapters.SimulatedAdapter`. The telemetry behaviour has a live BEAM runtime adapter but no concrete sensor/device telemetry adapter was identified in targeted repository searches. No verified driver integration for GPIO, I2C, SPI, UART/serial, USB, CAN, ROS/ROS 2, microcontroller firmware, or robot control was found in this pass.

This is a bounded finding: the search does not prove that no hardware-related file exists anywhere in the repository. A full path inventory and dependency/caller graph is still needed.

**RL-405 OPEN — Physical hardware integration is not demonstrated by the current deployment adapter path.** The configured default adapter is simulated and records actions in memory; no concrete hardware adapter or verified device I/O path was established.

### H-02 — Safety verification unconditionally passes every constraint

In `SafetyVerificationEngine.check_constraint/3`, every constraint returns `status: :pass` without inspecting the constraint, artifact, or parameters. Thus `verify/2` can report `passed: true` and `critical_safe: true` even though no physical bounds, interlocks, emergency-stop circuit, power limits, collision envelope, watchdog, or device-specific hazards have been measured or validated.

**RL-406 OPEN — Physical safety verification is non-evidentiary.** The safety gate reports pass for all supplied artifacts because the constraint checker is unconditional; it cannot certify a physical deployment.

### H-03 — Physical lifecycle labels exceed the evidence they represent

The manager permits transitions from `:simulated` to `:dry_run` to `:supervised` without recording simulation results, dry-run evidence, a supervisor identity, or supervision observations. The next transition to `:autonomous` checks only whether the adapter's `status/0` returns `%{active: true}`. With the simulated adapter, a single recorded action sets active true. That is not evidence of a completed simulation, supervised operation, or safety case.

**RL-407 OPEN — Deployment stage transitions can assert dry-run, supervised and autonomous states without corresponding evidence.** The stage names are not bound to verifiable stage artifacts or independent acceptance checks.

### H-04 — Adapter contract and manager disagree on E-stop reset

The PhysicalAdapter behaviour declares `emergency_stop/0` but does not declare `clear_estop/0`. The manager's `resume/1` unconditionally calls `deployment.adapter.clear_estop()`. This works for the current SimulatedAdapter because it defines an extra function, but a conforming future hardware adapter need not implement it. The manager also does not inspect or independently verify the return from the emergency-stop callback before updating its own `estop_active` flag.

**RL-408 OPEN — E-stop lifecycle is not fully specified or verified by the adapter contract.** A conforming adapter may not implement the manager's reset call, and the manager treats the stop callback as successful without independent confirmation of the physical safe state.

### H-05 — Approval identity is caller-supplied data, not authenticated authority

`approve/3` accepts an arbitrary `approver` value and records it in the deployment struct. The inspected path does not authenticate that identity, bind approval to a user/session/credential, require a Council authorization, or bind the approval cryptographically to the exact design/plan/safety evidence hash. The test uses the literal string `"tiannara-admin"`; this demonstrates data recording, not authentication.

**RL-409 OPEN — Physical deployment approval is not bound to authenticated human authority or immutable approved artifact identity.** A caller-supplied approver string can populate the approval field without proof of identity or evidence that the exact plan being executed was approved.

### H-06 — Action dispatch has no adapter capability or action-schema enforcement at the manager boundary

The adapter exposes `capabilities/0`, but `PhysicalDeploymentManager.execute/2` does not consult it before forwarding an arbitrary action map to `execute_action/1`. It checks deployment stage and the manager's E-stop flag only. The simulated adapter accepts and records arbitrary action maps. No device-specific range checks, typed command schema, units, interlocks, rate limits, authorization token, command expiry, replay protection, or feedback-confirmation contract is visible here.

**RL-410 OPEN — Physical action dispatch is not bound to declared adapter capabilities or validated device-specific command constraints.** The manager forwards arbitrary action maps to the selected adapter once the lifecycle stage permits execution.

## Hardware subsystem distinction

The `Tiannara.Meta.Hardware` tree is not evidence of robotics/device integration. Its supervisor starts a Registry, a HorizonScheduler and three EventHorizonTensorCore workers. The EHTC module describes itself as simulating tensor-core work; it drains queued payloads and spawns tasks that apply internal transforms and parity validation. No GPU driver, CUDA/OpenCL/Vulkan device enumeration, PCIe access, accelerator telemetry, or external hardware device protocol is established by these inspected files. Treat the GPU execution bridge claims in the Phase 5F.11 report separately and verify the actual source/callers before classifying them as hardware execution.

## Test evidence and limits

The physical deployment unit and property tests exercise the staged lifecycle with SimulatedAdapter. They establish behavior of the in-memory simulator and approval-stage transition logic under test conditions. They do not demonstrate physical device discovery, electrical I/O, real actuator control, sensor feedback, fail-safe behavior on a real controller, loss-of-connection handling, watchdog expiry, hardware-in-loop tests, or independent safety certification. Tests were not run in this audit pass.

## Disposition

- RL-405 through RL-410: **OPEN**.
- No existing findings closed.
- No source code modified.
- No hardware attached; no physical actuation attempted.
- No runtime/build/test verification performed.

## Required next investigation

1. Perform a complete tree inventory for hardware, robotics, embedded, device, sensor, actuator, firmware, ROS, GPIO, I2C, SPI, UART, USB, CAN, CUDA, ROCm, OpenCL and Vulkan references, including ignored/excluded paths and dependency manifests.
2. Trace every caller of PhysicalDeploymentManager and every configured adapter, including configuration paths and feature flags.
3. Inspect the GPU bridge source and prove whether it reaches an actual accelerator API or only schedules CPU-side/simulated work.
4. Inspect the robotics/control modules for sensor ingestion, state estimation, control loops, actuator command generation, feedback, watchdogs and emergency-stop wiring.
5. Define a hardware-in-loop verification plan with simulated, bench, fault-injection and independently reviewed safety stages. Do not connect or actuate real equipment until safety gates and human authorization are demonstrated.


# Checkpoint 18.62 — Council authorization, human approval, emergency authority, and audit durability

**Scope:** Council policy/rule evaluation, authorization predicates, human-approval queue and resumer, emergency invoke/lift, audit-log append durability, and the authorization hand-off to execution.
**Method:** Read-only source inspection on the audit branch. This checkpoint did not execute runtime tests, build the project, perform fault injection, or prove a complete repository-wide call graph. Source hashes below identify the exact files inspected; they are not a claim that all files came from one frozen source commit.

## Source evidence examined

| Path | Retrieved source blob SHA | Relevant scope |
|---|---|---|
| `lib/tiannara/council/council.ex` | `26564ecd3e4b67aecb27948c591dfb294fae9dcd` | authorization dispatch, emergency invoke/lift, human resumption |
| `lib/tiannara/council/authorization.ex` | `b323caf37dff786953fc183b6ab5b151c42c6c92` | full and conditional grant predicates |
| `lib/tiannara/council/human_approval_queue.ex` | `7b54511eec3c41881d34f5abbd6029593b3a9165` | approval identity, queue/history, exact-payload lookup |
| `lib/tiannara/council/human_approval_resumer.ex` | `f0f994aa03bd218c53f4436842ce8767965f2bda` | asynchronous resumption |
| `lib/tiannara/council/audit_log.ex` | `eb0ac2760008adba5d9ab1ffab75f01c9983c6dc` | DETS append and sync result handling |
| `lib/tiannara/cel/kernel.ex` | `31823da23d55a3686ac6e393f562e2acd28bbf55` | representative authorization consumption at kernel lifecycle boundary |

## Findings

### RL-411 OPEN — Emergency invocation and lifting lack an authorization gate and fail-closed audit prerequisite

`Council.invoke_emergency(actor, reason)` accepts caller-provided actor/reason and sets emergency state after calling `AuditLog.append/3`; the append result is ignored. `Council.lift_emergency(human_id)` similarly accepts a caller-provided identifier, logs an event without checking the result, and clears emergency state. Neither inspected handler verifies the actor's authority or requires a separate authenticated human authorization before changing state.

**Risk:** a caller able to reach these APIs may assert an identity, invoke emergency mode, or lift it without demonstrated authorization; the state transition can be acknowledged while its audit event was not durably recorded. This finding is about the inspected API path; authentication at an external caller boundary was not established.

**Closure evidence:** authenticated principal/role checks at the authoritative boundary; constitutional policy for invoke and lift; independent/dual approval where required; audit append success required before state transition; tests for forged identity, unauthorized lift, and audit-store degradation.

### RL-412 OPEN — Human approval records caller-supplied identity without authentication in the queue API

`HumanApprovalQueue.approve(request_id, human_id, notes)` records the supplied `human_id` as `decided_by` and appends a log entry, but the inspected queue module does not authenticate that identity or validate an approval credential. The reject path has the same caller-supplied identity shape. The queue and its history are held in GenServer memory in the inspected implementation.

**Risk:** the recorded name alone is not proof that an authorized human approved the request; queue state and approval history can also be lost on process/application restart unless another durable recovery path exists. External authentication and persistence/recovery were not proven by this file inspection.

**Closure evidence:** authenticated human principal from a trusted identity boundary, authorization scoped to the request, durable approval record bound to the exact request/payload hash, and restart/recovery tests.

### RL-413 OPEN — Public human-resumption API does not validate the referenced approval record

`Council.resume_human_approval(request_id, decision_type, payload)` evaluates the supplied decision and includes `request_id` in an audit event, but the function itself does not fetch the request, verify its status is approved, compare its stored decision type/payload, or bind the resulting authorization to the approval's authenticated actor. The supervised resumer does fetch an approved queue record before calling it; however, the Council function is publicly callable as an exported module function.

**Risk:** a consumer that trusts this API's returned `Authorization` as proof of human approval could bypass the queue's approval-state checks. This source finding does not claim that arbitrary external callers can directly execute an effect; the complete effect-consumer graph remains to be established.

**Closure evidence:** make resumption accept an opaque, validated approval capability or keep the operation behind a single authoritative API that verifies request state, exact payload hash, human identity, and single-use status before returning a grant.

### RL-414 OPEN — Approved human decisions remain reusable and have no demonstrated expiry or one-time consumption

`HumanApprovalQueue.approved_request/2` searches retained history for an approved record matching decision type and exact payload. The inspected code does not consume or invalidate the record when it is returned, and the record has no expiry or nonce field. Council authorization can therefore retrieve the same approved history record again for repeated matching requests.

**Risk:** a previously approved operation may be authorized repeatedly or replayed later if its payload remains identical, even if the approval was intended for a single execution or a limited time window.

**Closure evidence:** explicit scope and expiry, one-time grant consumption, unique nonce/idempotency key, binding to the exact artifact/effect and current constitutional version, and concurrent replay tests.

### RL-415 OPEN — Conditional-grant evidence matching does not require affirmative pass semantics

`Authorization.condition_satisfied?/2` considers a condition satisfied when an evidence map matches the relevant `principle`, `principle_id`, or `check`, provided `passed` is not explicitly `false`. It does not require `passed: true` or inspect the evidence entry's `verdict` for an affirmative result. RuleEngine evidence entries can contain a principle and a verdict without a `passed` field.

**Risk:** a matching evidence entry that is neutral or otherwise not an affirmative pass can satisfy a conditional grant's condition. The structural checks reduce some risks (including non-empty evidence, no listed violations, score threshold, and no required human review), but they do not repair the condition-level ambiguity.

**Closure evidence:** use typed, provenance-bearing condition results with explicit `status: :passed`; fail closed on missing/unknown/neutral evidence; bind each condition to the exact policy and artifact; test missing status, neutral verdict, mismatched check, and explicit failure.

### RL-416 OPEN — Audit append reports success without checking DETS sync outcome

In `AuditLog.handle_call({:append, ...})`, the code handles a successful `:dets.insert/2` and then discards the result of `:dets.sync/1` before replying `{:ok, entry}`. The public append contract therefore can report success without verifying that the sync operation succeeded.

**Risk:** callers that require a durable audit record may proceed on a success response even when the persistence flush failed. This is distinct from callers that ignore an explicit `{:error, ...}` result: here the sync result itself is discarded by the audit-log implementation.

**Closure evidence:** propagate sync failure, do not advance the authoritative chain tip or report success unless the durability contract is met, expose degraded state, and inject insert/sync/storage failures in tests.

### RL-417 OPEN — Human approval returns before resumption and audit completion are confirmed

`HumanApprovalQueue.approve/3` stores the approval and invokes `HumanApprovalResumer.resume/1`, which sends an asynchronous cast. The approval handler then returns `:ok` without waiting for the resumer to produce and record a decision. In the resumer, the return values of `HumanApprovalQueue.record_resume/2` and `AuditLog.append/3` are not checked.

**Risk:** an approval API success response means the approval record was accepted, not that re-evaluation completed, the resulting authorization was recorded, or the resumption audit entry was persisted. Consumers must not treat the approval response alone as a completed or executable grant.

**Closure evidence:** expose distinct states for approved, resumption-pending, evaluated, durably recorded, and executable; propagate failure; reconcile interrupted resumptions after restart; and test queue, Council, and audit-log failure at every transition.

## Cross-cutting disposition

- RL-411 through RL-417: **OPEN**.
- RL-393 through RL-410 and all earlier findings remain open unless separately closed with exact-candidate evidence.
- This checkpoint is source inspection only. No source code was changed; no build, test suite, runtime execution, emergency exercise, or audit-storage fault injection was performed.
- The existing RL-403 concern about mandatory audit of ordinary authorization outcomes remains open and is not treated as closed by this checkpoint.
- Authorization data structures and policy descriptions are not execution proof. Each effect consumer must be inventoried and shown to validate the grant immediately before the effect, including actor, exact payload/artifact, expiry, replay protection, required conditions, and durable audit outcome.

**Next checkpoint 18.63:** build the caller-to-effect authorization map across CEL, physical deployment/hardware, self-modification, and other consequential execution paths. For each path, establish whether it uses Council, how it consumes full/conditional/human grants, whether the grant is bound to the exact effect and actor, and what happens on Council/audit failure. Continue read-only until implementation is explicitly authorized.


# Checkpoint 18.63 — Caller-to-effect authorization map: CEL, physical deployment, self-modification, and deployment replay

**Method:** Read-only source inspection. The audit queried repository code search and retrieved the exact source files listed below. This is a focused caller-to-effect map, not an exhaustive proof that every consequential call site in the repository has been found. No build, test, runtime execution, hardware actuation, or fault injection was performed.

## Source evidence examined

| Path | Retrieved source blob SHA | Relevant scope |
|---|---|---|
| `lib/tiannara/cel/kernel.ex` | `fe120d61dcd03a7542b888cf8cce6f1f4e357430` | CEL service restart/halt authorization consumers |
| `lib/tiannara/asc/reality/physical_deployment_manager.ex` | `94030decab03ff4e92b20345390e6f3793b24c1e` | physical deployment approval, execution, abort, E-stop/resume |
| `lib/tiannara/asc/reality/physical_adapter.ex` | `735b1b95103750704df235afa1c92b02ff0d18f2` | hardware adapter effect interface |
| `lib/tiannara/asc/reality/adapters/simulated_adapter.ex` | `704e7432dfd70f422f372652e3816323b59730cd` | simulated action execution and E-stop |
| `lib/tiannara/asc/reality/safety_verification_engine.ex` | `d68b8bb4ceef4908eba0906dd638d29d0cfc32c8` | safety verification result production |
| `tiannara_runtime/lib/tiannara_runtime/self_compilation/rewrite_engine.ex` | `c6f627cb2044a2c5218a988af47f8f8b9289c030` | self-compilation validation/application path |
| `lib/tiannara/omega/deployment_gateway/deployment_registry.ex` | `8894176a43901e5152ff3c0e86817a705d7d7bb8` | authorization-ID replay registry |
| `lib/tiannara/asc/adoption/adopter.ex` | `e5017c87049d27ea255f386ad427ee0c4bd83e28` | production adoption's two-key preflight and post-validation |

## Caller-to-effect map

| Path | Gate observed | Effect / disposition |
|---|---|---|
| CEL `restart_service/2` → terminate/start service | Council authorization, but actor omitted from payload/context; both `:approved` and `:conditional` are accepted without checking conditions | **Conditional grant bypass at this consumer** |
| CEL `halt/2` → terminate tracked services | Council approval required; actor included in payload, context passed as `nil` | Actor provenance is caller-provided; no structured authenticated execution context is passed |
| Physical deployment `approve/3` → set approval field | Stage check only; `approver` is caller-supplied | No Council/authentication call visible in this manager |
| Physical deployment `execute/2` → adapter `execute_action/1` | Stage must be simulated/dry-run/supervised/autonomous; E-stop flag must be false | No fresh Council grant, actor, action-to-grant binding, or durable audit check at the effect boundary |
| Physical deployment `resume/1` → adapter `clear_estop/0` | Deployment ID exists | No approval/authentication or re-verification gate visible before clearing E-stop |
| Self-compilation `RewriteEngine` → `SafetyValidator.validate` → `apply_rules` | Local input/stability/validator checks | No Council/human approval call in the inspected path; current `apply_rules/2` returns `:applied` placeholders and does not apply subsystem changes |
| ASC adoption `Adopter.adopt/1` → checkout changed files on production line | Verified human authorization artifact, mission/candidate/branch agreement, eligibility evidence, exact declared diff scope, rollback snapshot, compile/tests/boot smoke | Stronger explicit gates in this path; however, inspected code does not show Council authorization or authenticated actor binding, and the adopted tag command result is ignored |
| Omega deployment replay registry | Checks authorization ID against a file | Read failure returns `false` (not already deployed); append returns raw `File.write/3` result, which callers must check; no atomic check-and-record transaction shown in this module |

## Findings

### RL-418 OPEN — CEL restarts accept conditional authorization as if it were unconditional

In `CEL.Kernel.handle_call({:restart_service, id, actor}, ...)`, the Council request is `Council.authorize(:architectural_change, %{action: :restart, service: id}, nil)`: the supplied actor is not included. Both `%Authorization{decision: :approved}` and `%Authorization{decision: :conditional}` take the same `do_restart/2` path. The consumer does not call `Authorization.conditional_grant?/1` or otherwise verify conditions.

**Risk:** a conditional decision can trigger a service restart even when its conditions have not been met; attribution and actor-bound policy are also weakened at this boundary.

**Closure evidence:** accept only `Authorization.permitted?/1` or explicitly validate a conditional grant and its evidence; pass an authenticated `ExecutionContext`; test unmet, unknown, and satisfied conditions at the actual restart handler.

### RL-419 OPEN — Physical deployment effect is not bound to a Council grant or authenticated operator

The physical manager stores the supplied `approver` value as an approval record, advances based on that record, and dispatches `execute_action(action)` based on lifecycle stage and the local E-stop flag. The inspected `approve`, `advance`, and `execute` handlers do not call the Council or verify an authenticated approver. The action passed to the adapter is not shown as bound to a one-use authorization artifact, and the effect handler receives no actor identity.

**Risk:** the lifecycle state is acting as a substitute for an independently authenticated, effect-specific authorization. The stage gate is useful but does not by itself prove who approved the action or that the approved action equals the executed action.

**Closure evidence:** authenticated approval principal; immutable hash of the deployment plan and exact action set; grant bound to plan hash, adapter/device, actor, expiry, and constitution version; fresh authorization check immediately before every effect; durable audit record before dispatch.

### RL-420 OPEN — Physical deployment resume clears E-stop without a demonstrated authorization or safety recheck

`PhysicalDeploymentManager.handle_call({:resume, id}, ...)` calls `deployment.adapter.clear_estop()` and clears `estop_active` when the deployment ID exists. The inspected handler does not require a reason, authenticated actor, independent approval, fresh safety verification, or confirmation that the cause of the stop has been removed.

**Risk:** an emergency stop can be cleared by a caller with access to the manager API without evidence that resumption is safe. This is a source-level control gap; external access controls were not established in this inspection.

**Closure evidence:** stop-cause latch and diagnostic record; authenticated, policy-authorized resume; independent approval for high-risk hardware; re-run safety/interlock checks; verify adapter stop state and audit successful/failed resume attempts.

### RL-421 OPEN — Safety verification engine unconditionally marks every configured constraint as passed

`SafetyVerificationEngine.check_constraint/3` ignores both the constraint and the artifact/parameters and returns `status: :pass`. Consequently, `verify/2` computes `passed: true` and `critical_safe: true` from placeholder results rather than constraint-specific checks. `PhysicalDeploymentManager.plan/1` accepts a verification whose `passed` field is true, and its lifecycle can then advance through the safety-review gate.

**Risk:** the manager's safety gate can provide false assurance and allow a plan to progress without actually checking bounds, side effects, fail-safe mechanisms, monitoring, or privacy constraints.

**Closure evidence:** implement each constraint against the actual artifact, parameters, hardware capabilities and operational limits; represent unknown/unimplemented checks as UNKNOWN/FAIL; add negative tests proving each critical violation blocks planning and advancement.

### RL-422 OPEN — Self-compilation reports success/version advancement without a demonstrated modification or governance approval

The inspected rewrite engine calls its safety validator, then `apply_rules/2`; each supported subsystem branch currently returns the literal `:applied` with comments that the integration is still to be implemented. The caller nevertheless records a new version, increments success statistics, and returns `status: :compiled`. No Council authorization or human-approval gate is present in this inspected path.

**Risk:** status and version records can imply a successful self-modification when the inspected implementation performs no actual subsystem mutation. If real mutation is later wired into this path, the same missing governance hand-off would be a critical control gap.

**Closure evidence:** distinguish validated/proposed/simulated/applied states; only report applied after verifying an actual content/state diff and post-change identity; bind human-approved change artifact and rollback snapshot; enforce constitutional authorization immediately before mutation; prove behavior with before/after hashes and rollback tests.

### RL-423 OPEN — Deployment replay registry fails open when its record file cannot be read

`DeploymentRegistry.already_deployed?/2` returns `false` for any `File.read/1` error, treating unavailable or unreadable replay state as if the authorization ID had not been used. The check and subsequent append are separate operations in the inspected API; no atomic reservation/consume operation is shown.

**Risk:** when replay state is missing, inaccessible, truncated, or concurrently accessed, a previously used authorization may not be recognized, or two callers may pass the check before either records deployment.

**Closure evidence:** fail closed on registry read/parse errors; validate truncated/corrupt records explicitly; use a durable atomic single-use grant reservation/consume operation with concurrency protection; test read failures, corrupt tails, simultaneous attempts, and crash recovery.

### RL-424 OPEN — CEL service lifecycle transition API has no Council authorization check in the inspected handler

The public `CEL.Kernel.transition(new_state)` sends a request to a handler that validates only `RuntimeStates.valid_transition?/2` before changing the kernel runtime state. No actor or Council authorization is passed in that call path.

**Risk:** if this API is reachable by untrusted or insufficiently privileged callers, a caller may request a structurally valid runtime-state transition without a policy decision. The source inspection does not establish whether an external authenticated boundary restricts access.

**Closure evidence:** establish all callers and process/network boundaries; require an authenticated actor and explicit transition policy at the authoritative boundary; test unauthorized but structurally valid transitions and preserve emergency-safe transitions.

## Existing control noted — ASC adoption

The inspected `ASC.Adoption.Adopter` performs explicit authorization-artifact verification, mission/candidate/branch matching, machine-evidence checks, exact diff-scope comparison, rollback snapshot/tag creation, and post-adoption compile/test/boot-smoke validation. This is a stronger control pattern than the direct CEL restart and physical-deployment paths above. It is not treated as proof that every adoption failure path is safe: notably, the result of creating the adopted tag is ignored, and the inspected flow does not establish authenticated human identity or a mandatory durable Council audit event.

## Disposition and next step

- RL-418 through RL-424: **OPEN**.
- All prior findings remain open unless separately closed with exact-candidate evidence.
- No source code was modified and no tests or runtime/hardware actions were performed.
- **Checkpoint 18.64:** audit all callers and consumers of `Authorization`, `conditional_grant?`, deployment registry checks, hardware adapters, and self-modification APIs. Establish whether these focused gaps are isolated or repeated, then define the minimal authoritative enforcement boundary and regression-test matrix before any remediation is attempted.


# Checkpoint 18.64 — authorization consumer coverage and replay-boundary verification

**Method:** Read-only source inspection at frozen source commit `b829254d032f9e0b5cf4c44725c8cf451800dad0`. No source code was modified; no tests, build, runtime execution, hardware actuation, or fault injection were performed.

## Source evidence

| Path | Retrieved source blob SHA | Scope |
|---|---|---|
| `lib/tiannara/omega/deployment_gateway.ex` | `78777f91ee0b73ea1dd5069dc79d8e0f6a24c05c` | candidate deployment gate, identity/grant checks and replay locking |
| `lib/tiannara/omega/deployment_gateway/deployment_registry.ex` | `8894176a43901e5152ff3c0e86817a705d7d7bb8` | replay record read/write and decoding |
| `lib/tiannara/omega/human_delivery/authorization.ex` | `beabd8de7b4fe7793d16bb77dd374627627a43e0` | grant lifecycle, candidate/explanation binding and expiry |
| `lib/tiannara/omega/human_delivery/authenticated_human_identity.ex` | `901bb2022929c3439f683a38403476ad685f9f3f` | identity construction and authentication predicate |
| `lib/tiannara/cel/kernel.ex` | `fe120d61dcd03a7542b888cf8cce6f1f4e357430` | CEL restart and transition consumers |
| `lib/tiannara/asc/reality/physical_deployment_manager.ex` | `94030decab03ff4e92b20345390e6f3793b24c1e` | physical approval, execution and E-stop/resume |
| `tiannara_runtime/lib/tiannara_runtime/self_compilation/rewrite_engine.ex` | `c6f627cb2044a2c5218a988af47f8f8b9289c030` | self-compilation result semantics |

## Positive controls and qualifications

The Omega deployment gateway is materially stronger than the physical deployment manager and CEL restart handler. It checks candidate approval status, certification verdict, non-empty lineage, grant presence, grant-to-proposal match, expiry, identity/grant human-ID agreement, and candidate content hash. It wraps its check/commit sequence in an ETS mutex keyed by registry path, intended to prevent same-node concurrent attempts sharing that path.

The authorization grant has a lifecycle (prepared → pending_authorization → granted), human ID, TTL, explanation ID, and optional candidate content hash. However, a human ID is not proof of an authenticated human. Replay protection is also optional: a nil registry path skips both the already-deployed check and recording.

## Findings

### RL-425 OPEN — Deployment gateway can report success when replay-registry persistence fails

When a registry path is supplied, DeploymentGateway.do_deploy/6 calls DeploymentRegistry.record_deployment/3 but does not pattern-match or propagate its return value. It then returns a successful deployment tuple regardless of whether File.write/3 returned an error.

**Risk:** the caller can receive success while the authorization remains replayable after restart or on a subsequent invocation.

**Closure evidence:** require a successful durable registry commit before returning success; propagate write, directory, flush, and storage failures; test unwritable paths, partial writes, process interruption between effect and record, and restart replay.

### RL-426 OPEN — Authenticated-human identity structs can be forged by direct construction

AuthenticatedHumanIdentity is a public Elixir struct with public fields. Its authenticated?/1 predicate returns true for any instance with a non-nil authenticated_at field. It does not verify a signature, opaque server-issued token, trusted issuer, or registry entry. The inspected authenticate/3 function accepts any non-empty binary credential; no credential validation against an identity provider or stored secret is performed in this module. The deployment gateway trusts this predicate and compares only identity.human_id with grant.human_id.

**Risk:** a caller able to construct the struct can fabricate a matching identity and satisfy the gateway check without passing through authenticate/3. Even that helper establishes non-emptiness, not credential validity against an authority.

**Closure evidence:** use an unforgeable opaque identity capability issued by a trusted authentication boundary; verify issuer/signature/session validity, authentication strength and freshness at the effect boundary; test direct struct forgery and invalid/revoked credentials.

### RL-427 OPEN — Replay protection is optional and the registry fails open on read/parse corruption

The gateway explicitly treats a nil registry_path as success for its replay check and skips recording. With a path, DeploymentRegistry.already_deployed?/2 maps every File.read/1 error to false. Its decoder silently returns an empty list for a truncated trailing record and does not validate each decoded tuple's schema. The ETS mutex serializes only callers sharing the same in-process table/key; it is not a durable cross-node single-use grant mechanism.

**Risk:** deployments that omit the optional path have no replay protection. Missing/unreadable registry state or a corrupt tail can be treated as unused; distributed instances do not share the in-memory mutex. This refines RL-423: the gateway has a same-node critical section, but optionality and storage semantics still fail the durable fail-closed requirement.

**Closure evidence:** make replay protection mandatory for production deployment; use a transactional durable store with atomic unique grant consumption across nodes; fail closed on read, decode, schema and integrity errors; test corruption, missing/unreadable state, concurrent multi-node attempts, restart and crash recovery. RL-423 remains OPEN with this refined scope.

### RL-428 OPEN — Physical deployment API has no effect-specific authorization at dispatch

The complete manager source confirms that approve/3 stores a supplied approver string; advance/1 trusts the stored approved decision; execute/2 dispatches a caller-supplied action when the stage is in the allowed set and E-stop is false; and resume/1 clears adapter E-stop solely when the deployment ID exists. These handlers do not consume an authenticated actor, Council grant, plan/action hash binding, per-action authorization, or fresh safety check.

**Risk:** lifecycle stage is being used as the authorization token. The action chosen at dispatch is not demonstrably bound to the human-approved plan. The resume path can clear the stop latch without showing that the stop cause was resolved.

**Closure evidence:** bind an authenticated principal and one-use Council authorization to the immutable plan and exact action; revalidate policy and safety at dispatch; require an independently authorized resume protocol with stop-cause diagnostics and interlock confirmation; audit every attempt and result durably.

### RL-429 OPEN — Self-compilation success counters describe validation, not an applied change

RewriteEngine validates mutated rules, but apply_rules/2 returns the literal :applied for each supported subsystem and comments state that subsystem integration is pending. The engine then increments version and success counters and returns status: :compiled. No actual subsystem update or before/after state comparison is performed in this path.

This corroborates RL-422 rather than establishing a separate mutation path. Keep RL-422 OPEN; RL-429 is supporting evidence, not an independent exploit finding.

## Enforcement-boundary map

| Consequential path | Observed enforcement | Disposition |
|---|---|---|
| Omega candidate deployment | Strong candidate/grant/expiry/content-hash checks; identity predicate forgeable; replay registry optional and write result ignored | Partial; RL-425–427 OPEN |
| CEL service restart | Conditional decision treated as unconditional; actor omitted | RL-418 OPEN |
| CEL runtime-state transition | Structural transition validation only | RL-424 OPEN |
| Physical deployment | Caller-supplied approval identity; stage-only dispatch; E-stop resume without reauthorization | RL-419, RL-420, RL-428 OPEN |
| Physical safety review | Unconditional pass behavior already recorded | RL-421 OPEN |
| Runtime self-compilation | Placeholder apply and false compiled/version result | RL-422 / RL-429 OPEN |
| ASC adoption | Human artifact, evidence, scope, rollback and validation checks; identity/audit/tag-result gaps remain | Positive partial pattern; not certified |

## Minimal authoritative enforcement boundary — design requirement, not implementation

1. **Authenticated principal:** trusted, unforgeable identity with role/authority and fresh authentication evidence.
2. **Exact effect binding:** immutable target, artifact/plan hash, operation/action, parameters, device/subsystem, environment and constitution/policy version.
3. **Typed authorization:** distinguish approved, conditional, human-required, denied, deferred and unknown. Conditional grants require explicit affirmative evidence immediately before effect.
4. **Freshness and single use:** expiry, nonce, revocation, replay prevention and atomic consumption across runtime instances.
5. **Independent safety gate:** actual constraint checks and hardware interlocks; UNKNOWN or unavailable safety evidence blocks effect.
6. **Durable audit before effect:** verify durable authorization/effect-intent record before dispatch; record outcome and reconciliation afterward. Audit failure blocks consequential action except explicitly designed emergency-stop behavior.
7. **Effect adapter boundary:** no alternate route to physical, deployment, lifecycle or self-modification effects; adapters receive validated effect capabilities, not bare actions.
8. **Human governance:** constitutional authority remains above CEL; high-impact self-modification and life-affecting physical actions require defined human/independent approvals. CEL coordinates and audits but cannot mint constitutional authority.

This is an audit-derived design requirement, not evidence that a shared enforcement service currently exists.

## Regression-test matrix required before remediation closure

| Area | Required cases |
|---|---|
| Identity | forged struct; empty/invalid/revoked credential; expired session; wrong human; insufficient role |
| Decision semantics | approved; conditional with all conditions passed; conditional with missing/unknown/failed condition; human-required; denied; deferred |
| Binding | wrong candidate hash; wrong proposal; changed parameters; wrong target/device; changed policy/constitution version |
| Replay/concurrency | same grant twice; simultaneous same-node and multi-node use; registry missing/unreadable/corrupt; partial write; restart; crash between effect and commit |
| Audit | append/sync failure; storage unavailable; chain discontinuity; outcome-recording failure |
| Hardware | action outside approved plan; stale interlock; E-stop active; resume without clearance; unknown adapter state; simulated adapter cannot certify physical effect |
| Self-modification | placeholder adapter; no actual diff; diff outside approved scope; failed post-change verification; rollback failure; missing human approval |
| CEL | missing/forged actor; unfulfilled conditional grant; unauthorized state transition; restart failure; audit unavailable |

## Disposition

- RL-425, RL-426, RL-427, RL-428: **OPEN**.
- RL-429 corroborates RL-422; do not count it as an independent exploit finding.
- RL-423 remains **OPEN**, refined by RL-427: the gateway mutex is a positive partial control, but optional registry use, fail-open reads/decoding, and unchecked persistence prevent a durable replay guarantee.
- RL-418 through RL-424 and all prior findings remain open.
- No source files were changed; no tests/build/runtime/hardware actions or fault injection were performed.
- **Next checkpoint 18.65:** inventory every caller of DeploymentGateway.deploy/6, every physical-adapter implementation and caller, every self-compilation public entry point, and every direct service/lifecycle transition caller. Establish whether these APIs are production-reachable and whether alternate effect paths bypass the proposed boundary.


# Checkpoint 18.65 — production reachability and alternate effect-path inventory

**Method:** Read-only source inspection at frozen source commit `b829254d032f9e0b5cf4c44725c8cf451800dad0`, including targeted code search, application supervision, service registry, domain entry points, physical-adapter implementations and self-compilation entry points. Search absence is not treated as proof of global absence unless supported by the inspected source inventory and supervision tree. No source changes, builds, tests, runtime execution, hardware actuation or fault injection occurred.

## Source evidence examined

| Path | Retrieved source blob SHA | Scope |
|---|---|---|
| `lib/tiannara/application.ex` | *blob SHA not retained in retrieval output* | main application children and ASC feature-flagged supervisors |
| `lib/tiannara/phase4/experiment_orchestrator.ex` | `5d37f9e20f5945a02ea26982c0449c5f35d7eb43` | submission API, GenServer target and RealExecution delegation |
| `lib/tiannara/phase4/real_execution.ex` | `28c1343b939793d878643eac918d0c79f1c55568` | sandbox execution grant guard and optional deployment call |
| `lib/tiannara/phase4/physics_pilot_execution.ex` | `99e190553ca1757327994de0ed72d3e6d4983411` | alternate physics-pilot path and ledger handling |
| `lib/tiannara/domains/physics.ex` | `88737ec54f67054269aa27f863c35ae0bbe8a1ef` | physics experiment entry point and routing |
| `lib/tiannara/sentinel/activation/approval.ex` | `6c408c6f8a949dd4d9bd6718e3c21110049e1591` | approval-to-experiment caller |
| `lib/tiannara/asc/reality/reality_supervisor.ex` | `8bd538a1911ce2b71b02045fc9d578d54176d2a0` | ASC physical deployment supervision |
| `lib/tiannara/asc/reality/physical_deployment_manager.ex` | `94030decab03ff4e92b20345390e6f3793b24c1e` | manager API and effect dispatch |
| `lib/tiannara/asc/reality/adapters/simulated_adapter.ex` | `704e7432dfd70f422f372652e3816323b59730cd` | sole concrete adapter located by search |
| `tiannara_runtime/lib/tiannara_runtime/self_compilation/supervisor.ex` | `e5c9f0724a3a9349fb5af5ad2f657a690eb47028` | public self-compilation facade and child declarations |
| `tiannara_runtime/lib/tiannara_runtime/self_compilation/rewrite_engine.ex` | `c6f627cb2044a2c5218a988af47f8f8b9289c030` | self-compilation implementation |
| `lib/tiannara/omega/deployment_gateway.ex` | `78777f91ee0b73ea1dd5069dc79d8e0f6a24c05c` | candidate deploy path and gateway checks |
| `lib/tiannara/cel/kernel/service_registry.ex` | `76e2861046ae51d4f94157b688037213d58099ac` | registered service inventory |

*Evidence limitation:* the exact blob SHA for `application.ex` was not retained in the retrieval output, so no SHA is asserted for that row. Its fetched source content was inspected. All other listed blob SHAs were returned directly by the file retrievals.

## Caller and supervision map

### 1. Omega deployment and Phase-4 execution

- `Omega.DeploymentGateway.deploy/6` has a call from `Phase4.RealExecution.maybe_deploy/3`, plus the adversarial verification scenarios. The historical MC-003 inventory identified the gateway as test-scenario-only at the frozen SHA; the newly inspected RealExecution call is a conditional code path, not proof of a production caller.
- `RealExecution.execute/1` is called by `ExperimentOrchestrator.handle_call/3`.
- `ExperimentOrchestrator.submit_experiment/1` has source callers in `Domains.Physics.execute_experiment/1` and `Sentinel.Activation.Approval.decide/2`.
- `Tiannara.Application.core_children/0` does not include `ExperimentOrchestrator`; the canonical CEL service registry's registration is metadata, not a GenServer start. The main app has no demonstrated supervisor child for this GenServer in the inspected children list.
- `submit_experiment/1` returns `:real_execution_not_enabled` when the flag is false (the default). If the flag is enabled while the GenServer remains unstarted, the `GenServer.call/3` has no demonstrated running target and can exit rather than return a controlled refusal.
- The ASC `Reality.Supervisor` is added only when `asc_enabled?()` is true; this is a separate feature-gated path, not evidence that the Phase-4 orchestrator is supervised.

### 2. Physics pilot alternate route

`Domains.Physics.execute_experiment/1` routes to `PhysicsPilotExecution.execute/1` when a grant is present and `:real_execution_enabled` is true. This path does not call `RealExecution.execute/1` or `DeploymentGateway.deploy/6`. It performs a numerical RK4 simulation and structural validation, records a ledger entry, and returns results. This is a real computation over a model, not physical-world experimentation or a deployment effect. The grant check in the pilot is status/expiry-only; it does not bind the grant to the exact pilot parameters or a verified human identity in the inspected module.

### 3. Physical deployment / hardware

`PhysicalDeploymentManager` is included under `ASC.Reality.Supervisor`, but that supervisor is included in the main application only when ASC is enabled. The manager defaults every deployment to `SimulatedAdapter`. The only concrete adapter implementation found by targeted search is `SimulatedAdapter`; it records actions in an in-memory list and returns a simulated success result. No physical hardware implementation, device transport, or real adapter caller was established at this frozen SHA. This is consistent with the prior MC-003 execution inventory and must not be described as hardware actuation.

### 4. Self-compilation

`Tiannara.SelfCompilation.Supervisor.compile_subsystem/3` exposes a GenServer call into `RewriteEngine`. Its supervisor declares the rewrite engine and supporting components as children. However, no production caller of `compile_subsystem/3` or start of this supervisor from the main Tiannara application was found in the inspected source searches. The separate runtime application's boot integration remains to be verified independently. The earlier RL-422 placeholder apply/status issue therefore remains OPEN; no live self-modification path was established here.

### 5. CEL restart and lifecycle transition

Targeted searches for direct `CEL.Kernel.transition/1` and `restart_service/2` callers did not return production call sites. The handlers remain callable module APIs and the earlier RL-418/RL-424 source findings remain open. The absence of search matches is not proof that no indirect, dynamic, RPC, or external caller exists. A full boundary review must inspect all public interfaces, process registrations, telemetry/event command dispatch, and runtime call graphs.

## New findings

### RL-430 OPEN — Phase-4 experiment submission has callers but its GenServer is not wired into the main application supervision tree

`Domains.Physics.execute_experiment/1` and `Sentinel.Activation.Approval.decide/2` call `ExperimentOrchestrator.submit_experiment/1`. That API calls `GenServer.call(ExperimentOrchestrator, ...)` when real execution is enabled. The main `Tiannara.Application` child list does not include `ExperimentOrchestrator`, and the CEL ServiceRegistry only declares service metadata; registration does not start the process. The default-disabled flag masks this wiring defect with a refusal response. Enabling the flag without separately starting the GenServer can cause caller exits rather than a controlled service-unavailable result.

**Risk:** an advertised single execution gateway is disconnected from normal application boot. A configuration change can turn a predictable disabled refusal into an unhandled process-call failure; the supposed sole production execution path is not operationally established.

**Closure evidence:** explicitly supervise the orchestrator with declared dependencies and readiness checks, or remove/disable its advertised entry points; test default-disabled, enabled-and-healthy, enabled-but-not-started, dependency-degraded and restart scenarios at the exact candidate SHA.

### RL-431 OPEN — RealExecution accepts any Authorization struct without checking grant status or expiry before running the sandbox

`RealExecution.guard_grant/1` accepts every `%Authorization{}` value as `:ok`. It does not require `status: :granted`, check `Authorization.expired?/1`, or bind the grant to the exact experiment spec before `RealHarness.run/4`. The optional later deployment gateway has stronger checks, but the sandbox execution has already happened before `maybe_deploy/3` is called.

**Risk:** a denied, pending, expired or otherwise invalid authorization struct can pass the sandbox-execution gate. The sandbox is isolated, but it performs real subprocess build/test/benchmark work and processes a caller-supplied patch; this is not equivalent to production deployment, yet the authorization contract is still false.

**Closure evidence:** require a granted, unexpired, authenticated and exact-spec-bound authorization before opening the execution lifecycle or starting the sandbox; fail closed on unknown status; test pending, denied, expired, mismatched and forged grants. Preserve the separate deployment gate for any deployment side effect.

### RL-432 OPEN — Physics pilot reports successful execution even when its durable ledger write fails

`PhysicsPilotExecution.record_execution/2` writes the JSONL ledger with `File.write!/3`, but rescues any exception, logs an error and returns `:ok`. The caller's `with` therefore continues and returns a successful execution result even when the durable evidence ledger could not be written. The EventStore append is explicitly best-effort as well.

**Risk:** callers may treat an experiment as durably evidenced when the canonical ledger is absent or unwritable. This violates the stated evidence-before-confidence and durable-recording contract, even though the computation itself may have completed.

**Closure evidence:** propagate ledger creation/write/flush failures as execution failures or a clearly separate non-certifiable outcome; verify durable append semantics; record reconciliation state and test unwritable directory, partial write, process interruption and EventStore degradation.

## Cross-cutting disposition

- RL-430, RL-431, RL-432: **OPEN**.
- RL-418 through RL-429 and all earlier findings remain open.
- The Omega gateway is conditionally reachable in source through RealExecution, but the Phase-4 orchestrator is not wired into the inspected main application supervision tree; no production deployment was demonstrated.
- Physical deployment remains simulated at this source baseline: ASC feature flag gates its supervisor, the manager defaults to SimulatedAdapter, and no real adapter implementation was located.
- The physics pilot is model simulation with numerical integration, not hardware actuation or an external experiment.
- The self-compilation supervisor and API exist, but an operational production boot/caller path was not established.
- No source code was changed; no build, tests, runtime execution, hardware actuation or fault injection was performed.
- **Next checkpoint 18.66:** verify the separate `tiannara_runtime` OTP application's actual supervision tree and whether `SelfCompilation.Supervisor` is started; trace every public entry point to RewriteEngine and RollbackManager; inspect all adapter modules/interfaces outside `lib/tiannara/asc/reality/adapters`; and map the exact external HTTP/command interfaces that can invoke CEL, deployment and physical-manager APIs. Also reconcile the Phase-4 caller and supervision contradictions against the exact app startup code and config profiles.


## Checkpoint 18.66 — runtime boot graph, self-modification reachability, and external physical-control API

**Inspection basis:** frozen source commit `b829254d032f9e0b5cf4c44725c8cf451800dad0`. Read-only GitHub source inspection. No source edits, build, tests, live HTTP requests, runtime boot, hardware connection, or actuation were performed.

### Source files and blob identities inspected

- `tiannara_runtime/lib/tiannara_runtime/application.ex` — `02a079abe2c1092b74686e1b11e95265d09ea25f`
- `tiannara_runtime/lib/tiannara_runtime/startup_supervisor.ex` — `eaaec6cd69c57486984625f5f033cd05691ab98b`
- `tiannara_runtime/lib/tiannara_runtime/runtime_layers/supervisors.ex` — `54b0be85fc5e5b616acdc39e09d785e5e976e1a8`
- `tiannara_runtime/lib/tiannara_runtime/self_compilation/supervisor.ex` — `e5c9f0724a3a9349fb5af5ad2f657a690eb47028`
- `tiannara_runtime/lib/tiannara_runtime/self_compilation/rewrite_engine.ex` — `c6f627cb2044a2c5218a988af47f8f8b9289c030`
- `tiannara_runtime/lib/tiannara_runtime/ccr/ccr_bridge.ex` — `091d49bbcf43784412f316daa7ab63988ebe590d`
- `lib/tiannara/web/router.ex` — `917c749e023ff86d59200798b93dfe4bfd9c11f0`
- `lib/tiannara/web/crav_challenge_controller.ex` — `403b7177633cbb187d7388df86dc5bd02eb40046`
- `lib/tiannara/asc/reality/physical_adapter.ex` — `735b1b95103750704df235afa1c92b02ff0d18f2`
- `lib/tiannara/asc/reality/physical_deployment_manager.ex` — `94030decab03ff4e92b20345390e6f3793b24c1e`
- `lib/tiannara/asc/reality/adapters/simulated_adapter.ex` — `704e7432dfd70f422f372652e3816323b59730cd`
- `lib/tiannara/asc/reality/reality_supervisor.ex` — `8bd538a1911ce2b71b02045fc9d578d54176d2a0`
- `lib/tiannara/phase4/experiment_orchestrator.ex` — `5d37f9e20f5945a02ea26982c0449c5f35d7eb43`

### Findings

#### RL-433 — Self-compilation supervisor is absent from the runtime's declared boot graph
**Status: OPEN**

The runtime Mix application starts `TiannaraRuntime.Application`, which starts `TiannaraRuntime.StartupSupervisor`; that starts `TiannaraRuntime.RootSupervisor`. The root's stable profile starts Infrastructure, Execution, Ecology, Constraint and Meta supervisors. Its research profile adds NDE/TWP/OSL experimental supervisors. Neither profile includes `Tiannara.SelfCompilation.Supervisor`. The separate supervisor declares RewriteEngine, RuleExtractor, RuleMutator, SafetyValidator, MetaOntologyGuard, VersionTracker, RollbackManager, AdaptiveLearner and PerformanceMonitor children, but its `start_link/1` is not called by the inspected boot graph. Its public APIs use named GenServer calls and therefore are not operationally backed merely because their modules compile.

CCR Bridge also contains a fallback that reports `{:ok, :rollback_simulated}` when its expected self-compilation RollbackManager is absent. The inspected runtime tree does not start that manager under the referenced name. This can turn a missing rollback capability into a success-shaped result.

**Closure evidence:** explicitly wire the approved self-modification subsystem into a governed boot profile or remove/disable the misleading callable APIs; verify exact module-name consistency; make missing rollback a hard unavailable/failure state; prove startup, liveness, authorized invocation, real target mutation, durable versioning, rollback and recovery with fault-injection tests. No self-modification should become active without Constitutional Council policy and required human approval.

#### RL-434 — Physical-deployment mutation endpoints have no visible authentication/authorization boundary
**Status: OPEN — HIGH PRIORITY SECURITY**

The Phoenix router places `/api/v1/reality/physical` GET and POST routes in a pipeline that only declares JSON acceptance. The controller's corresponding handlers directly call PhysicalDeploymentManager. In particular, POST handlers expose plan, advance, approve/reject, abort and emergency-stop operations. The approve handler accepts the `approver` identity from request parameters and defaults it to the literal `human-operator`; the manager stores that supplied string as the approver. The inspected router/controller path contains no authentication plug, principal extraction, authorization decision, Council-grant validation, or binding between an authenticated actor and the requested deployment effect.

This is a source-level finding about the visible route/controller path, not proof that an upstream reverse proxy or deployment environment supplies no protection. Such external controls were not available in this source inspection and must not be assumed. If the application is reachable without a separately enforced trusted gateway, an unauthenticated caller may be able to forge approval identity and invoke deployment lifecycle operations.

**Closure evidence:** enforce authentication at the application boundary; derive principal identity from a verified credential/session rather than request parameters; require role/attribute authorization and a fresh, single-use Council grant bound to deployment ID, exact action, parameters and adapter; require durable audit before effects; add negative HTTP integration tests for anonymous, forged-identity, unauthorized, replayed and mismatched-effect requests. Emergency stop should remain separately available through a narrowly scoped, authenticated safety path with independently verified behavior.

#### RL-435 — Hardware adapter abstraction currently has only a simulated implementation in the inspected ASC adapter package
**Status: OPEN**

The PhysicalAdapter behaviour specifies capabilities, status, execute_action and emergency_stop. The PhysicalDeploymentManager defaults to SimulatedAdapter; the inspected Reality.Supervisor starts that simulated adapter and the manager. The concrete adapter's execute_action only appends the action to an in-memory list and returns a success-shaped simulated result. Repository code search for implementations of the PhysicalAdapter behaviour found the SimulatedAdapter implementation; no concrete physical device adapter was identified in the inspected results. This does not prove no hardware integration exists elsewhere in the repository or outside it.

**Closure evidence:** inventory all hardware/robotics/device integration modules and transport interfaces across root `lib`, `tiannara_runtime/lib` and other declared audit boundaries; identify actual device drivers, protocol clients, safety interlocks, telemetry provenance and deployment configuration; otherwise classify physical execution as unsupported and fail closed. Require hardware-in-the-loop evidence before any physical capability claim.

### Additional reconciliation

- `TiannaraRuntime.RootSupervisor` does include an Execution supervisor, which starts required `Tiannara.OPC.CoreSupervisor` and optional `Tiannara.OPC.Supervisor`; that does not start the separate self-compilation supervisor.
- The separate runtime OTP application is wired through `mix.exs` to `TiannaraRuntime.Application`. This corrects the earlier uncertainty about whether the separate runtime has an application entry point; it does not establish that all declared subsystems are started or healthy.
- The Phase-4 orchestrator source calls `RealExecution.execute/1`, but the inspected main `Tiannara.Application.core_children/0` does not directly include the orchestrator. Search results found registration metadata but no `start_link` call site. The prior finding RL-430 remains open.
- The physical deployment API exposes lifecycle operations but does not itself demonstrate hardware actuation: the configured default adapter is simulated and stores results in memory.
- The router's browser pipeline has CSRF/security-header plugs; these are not substitutes for API authentication/authorization. The JSON API pipeline shown here contains only content negotiation.
- Source searches are not exhaustive proof against dynamic dispatch, runtime injection, reverse-proxy enforcement or external hardware services.

### Cross-cutting disposition

- RL-433, RL-434 and RL-435: **OPEN**.
- RL-430 through RL-432 and all earlier findings remain open.
- Do not mark self-modification, physical actuation, rollback, or human approval as operational based on module declarations or simulated success responses.
- No source code was changed; no build, tests, runtime execution, live API requests, hardware actuation or fault injection was performed.

**Next checkpoint 18.67:** inspect the remaining Tiannara web controllers and endpoint configuration for authentication, authorization, CORS, rate limiting and trusted-proxy assumptions; trace every physical-manager action and all adapter/robotics integrations across the full repository; inspect CEL service registration versus actual process ownership; and map the Phase-4 orchestrator's registration/start lifecycle and configuration gates.


## Checkpoint 18.67 — API boundary review and CEL boot-path correction

**Inspection basis:** frozen source commit `b829254d032f9e0b5cf4c44725c8cf451800dad0`. Read-only source inspection. No source edits, builds, tests, runtime boot, HTTP requests, or hardware actuation.

### Source files and blob identities inspected

- `lib/tiannara/application.ex` — `1429f81fde9de3c31d4a9dc91b23c5b635670496`
- `lib/tiannara/web/endpoint.ex` — `33b31db677d896a183e93e4d9def817236ee3be2`
- `lib/tiannara/web/router.ex` — `917c749e023ff86d59200798b93dfe4bfd9c11f0`
- `lib/tiannara/web/crav_challenge_controller.ex` — `403b7177633cbb187d7388df86dc5bd02eb40046`
- `lib/tiannara/cel/kernel.ex` — `fe120d61dcd03a7542b888cf8cce6f1f4e357430`
- `lib/tiannara/cel/kernel/boot_sequencer.ex` — `f9ebb5a9d096b89f6da0864a357907d5febfd93c`
- `lib/tiannara/cel/kernel/service_registry.ex` — `76e2861046ae51d4f94157b688037213d58099ac`
- `lib/tiannara/phase4/experiment_orchestrator.ex` — `5d37f9e20f5945a02ea26982c0449c5f35d7eb43`
- `lib/tiannara/phase4/real_execution.ex` — `28c1343b939793d878643eac918d0c79f1c55568`
- `lib/tiannara/asc/reality/reality_supervisor.ex` — `8bd538a1911ce2b71b02045fc9d578d54176d2a0`
- `lib/tiannara/asc/reality/physical_adapter.ex` — `735b1b95103750704df235afa1c92b02ff0d18f2`
- `lib/tiannara/asc/reality/adapters/simulated_adapter.ex` — `704e7432dfd70f422f372652e3816323b59730cd`
- `config/config.exs` — `a27a3c160cfe3d47afad62aacd321ec4183557d4`

### Important correction to checkpoint 18.66 / RL-430

The earlier conclusion that the Phase-4 ExperimentOrchestrator has no boot path was too strong. The main application calls `Tiannara.CEL.Kernel.boot()` after starting the top-level supervisor. The kernel invokes `BootSequencer.boot/4`, which obtains the registry boot order and dynamically starts each registered service using `DynamicSupervisor.start_child/2`. The canonical service registry includes both `AutonomousResearchEngine` and `ExperimentOrchestrator`. Thus, under a successful CEL boot, the orchestrator **does have a dynamic startup path**, even though it is not a static child of `Tiannara.Application`.

RL-430 is therefore corrected: **do not treat absence from the static supervision list as proof that the orchestrator is never started.** Remaining concerns are distinct and still open: production boot is launched through unlinked `Task.start/1` and is asynchronous; DynamicSupervisor children are declared `:temporary`; the orchestrator has no demonstrated production submission caller; and real execution is disabled by default unless `:real_execution_enabled` is explicitly true. No runtime observation was made to establish successful service startup in a deployed environment.

### Findings

#### RL-436 — Main Phoenix endpoint applies wildcard CORS to the entire application, including physical-control API routes
**Status: OPEN — SECURITY CONFIGURATION**

`TiannaraWeb.Endpoint` applies `CORSPlug` with `origin: "*"` and permits GET, POST, PUT, DELETE, PATCH and OPTIONS for the whole endpoint. The router's `/api/v1/reality/physical` routes include POST operations for planning, advancing, approving/rejecting, aborting and emergency stop. Wildcard CORS does not itself bypass server-side authentication, but it allows browser scripts from arbitrary origins to make cross-origin requests subject to the other browser controls and response-access rules. Combined with RL-434's missing visible API authentication/authorization path, this increases exposure and warrants explicit origin restriction. The endpoint also permits the Authorization header but the inspected router/controller does not consume a verified principal on the physical routes.

**Closure evidence:** replace wildcard CORS with environment-specific trusted origins; separate read-only and mutation route policies; enforce server-side authentication/authorization independently of CORS; test preflight and actual requests from allowed and disallowed origins. Do not treat CORS as an access-control mechanism.

#### RL-437 — CEL boot is asynchronous and detached from successful application startup in production
**Status: OPEN**

After the main supervisor starts, the application starts CEL boot using `Task.start(boot_fn)` outside test mode. The application returns `{:ok, pid}` without waiting for CEL's boot report or checking its outcome. CEL boot can later fail or report degraded status while the OTP application has already logged and returned successful startup. This creates a gap between application-level “started successfully” and verified operational readiness. It also complicates safe exposure of API operations that depend on dynamically booted services.

**Closure evidence:** expose a readiness state that distinguishes process startup from constitutional/runtime readiness; gate sensitive endpoints and effectful work until required services pass real boot checks; retain and monitor the boot task result; fail deployment readiness on critical boot failures; exercise delayed, failed and degraded boot cases.

### CEL boot and Phase-4 reconciliation

- `Tiannara.Application.start/2` starts the static supervision tree, registers Phase-Ω subsystem metadata, then invokes CEL boot synchronously only in test mode; production uses `Task.start/1`.
- `Tiannara.CEL.Kernel.boot/0` starts registered services dynamically with child restart policy `:temporary`; this remains subject to RL-395's no-automatic-restart concern.
- `BootSequencer` starts registry services in topological order; the orchestrator and autonomous research engine are both registered. Registry registration is not itself startup, but the CEL boot caller is.
- Search of production source still found no caller of `ExperimentOrchestrator.submit_experiment/1`. Dynamic startup therefore does not establish that experiments are actually submitted.
- `RealExecution.execute/1` requires `:real_execution_enabled` and an Authorization struct; the grant guard still only checks struct shape (RL-431), and the configured default is false.
- The ASC Reality supervisor starts `SimulatedAdapter` and PhysicalDeploymentManager when ASC is enabled. The inspected PhysicalAdapter implementation inventory still yielded only SimulatedAdapter; no physical hardware driver was identified in this pass.
- The main endpoint's wildcard CORS is a separate configuration concern from the unauthenticated physical API route path (RL-434); neither finding should be conflated with browser CORS semantics.

### Disposition

- RL-434, RL-436 and RL-437: **OPEN**.
- RL-435 remains open; adapter search is limited to indexed source matches and is not a mathematical proof of absence across every integration boundary.
- RL-430 is **corrected as described above**; its static-tree-only rationale is withdrawn. Any separate concerns about async boot, dynamic child restart semantics and absent submission callers remain tracked under RL-395, RL-437 and the Phase-4 integration gap.
- RL-431 and RL-432 remain open.
- No source code was changed; no build, tests, runtime execution, live HTTP requests, hardware actuation or fault injection was performed.

**Next checkpoint 18.68:** inspect the Python FastAPI production entry point and gateway authentication wiring, verify whether the API gateway and Phoenix endpoints share any trust boundary, enumerate the full set of mutating HTTP routes and their guards, and trace hardware integration packages beyond the ASC adapter directory (including ROS, Meta.Hardware and external transport bridges).


## Checkpoint 18.68 — Python/Phoenix trust boundaries, mutation routes and hardware integration

**Inspection basis:** frozen source commit `b829254d032f9e0b5cf4c44725c8cf451800dad0`. This checkpoint is source inspection only. It does not establish deployed network topology, reverse-proxy policy or live exploitability.

### Source files inspected

- `tiannara_api/main.py` — `f8883a9d4fbd3b329e52a8e7a73e5d3ab5145500`
- `tiannara_api/gateway/main.py` — `663ea5cc3607a33a26625024aaecaae9c2d5f2bb`
- `tiannara_api/gateway/auth.py` — `4620330040d4d81184aaa56e62355d8388a3fdf3`
- `tiannara_api/middleware/production_auth.py` — `eb14e6001a51215587ef2f01569da3ccd57ef001`
- `tiannara_api/middleware/jwt_context.py` — `01a17956b0829c2435d2c13544148197d17b90fd`
- `tiannara_api/middleware/api_key_auth.py` — `e25072eff1fb0707615a90c9ae63a1f8c36d1d78`
- `tiannara_api/security/auth_deps.py` — `6693bd62981cb8e9b708e73b747875bd20a9abc4`
- `tiannara_api/middleware/tier_access_control.py` — `bcc962f6e3c53acc1613fda422280e87253c14de`
- `tiannara_api/routes/meta_ecology.py` — `89e7794a77f8c242d96960bd205480f2357e2364`
- `tiannara_api/routes/workflows.py` — `b4f729165779a752961bff9ac6bc52ff0a69e5d6`
- `tiannara_api/routes/automations.py` — `bd27bfabaf00ffbd19cba630dae599dc96bc256e`
- `tiannara_api/routes/evolution.py` — `0356076fee06de0ff7b4fd36ee407f3d32992141`
- `lib/tiannara/web/router.ex` — `917c749e023ff86d59200798b93dfe4bfd9c11f0`
- `lib/tiannara/web/crav_challenge_controller.ex` — `403b7177633cbb187d7388df86dc5bd02eb40046`
- `lib/tiannara/application.ex` — `1429f81fde9de3c31d4a9dc91b23c5b635670496`
- `lib/tiannara/meta/hardware/supervisor.ex` — `36065776076735727b21bd6b707a9cdeec85a89e`
- `lib/tiannara/meta/hardware/horizon_scheduler.ex` — `22707b379cdf75053b165a44940c1133da8c454c`
- `lib/tiannara/meta/hardware/event_horizon_tensor_core.ex` — `8bdbc2f1c9bef6b831746ca89f20721838c84fe4`
- `lib/tiannara/meta/hardware/gravitational_shear.ex` — `fa906f86762e7353720f4c58a1b8d877b058b654`
- `lib/tiannara/meta/hardware/hawking_decoder.ex` — `2d2dc7fbab180f73d62ae12a486ed1623a151662`
- `lib/tiannara/asc/reality/physical_deployment_manager.ex` — `94030decab03ff4e92b20345390e6f3793b24c1e`

### RL-438 — Meta-Ecology telemetry ingestion and WebSocket stream have no route-level authentication
**Status: OPEN — INTEGRITY / AVAILABILITY / DATA TRUST**

The production FastAPI app mounts `meta_ecology_router` at `/api/v1/meta-ecology`. `ProductionAuthMiddleware` protects only its explicit prefix list (`/autonomous`, `/memory`, `/modules`, `/discovery`, `/evolution`, `/autonomy`, `/api/v1/core`, `/api/v1/cognitive`, `/api/v1/observatory`, `/api/v1/analyze`). The mounted Meta-Ecology prefix is not in that list. The router's POST `/ingest` overwrites the global telemetry state with the request payload verbatim, and its WebSocket `/stream` accepts a connection and emits that state without authentication or source verification. No route dependency or signature validation is present in the inspected router. This creates a source-level unauthenticated telemetry injection/read path in the FastAPI app; an externally reachable deployment could permit forged telemetry and disclosure of ingested telemetry. Actual reachability depends on deployment routing and network controls, which were not inspected.

**Closure evidence:** authenticate the Elixir-to-Python producer using mutually authenticated transport or signed, replay-protected messages; validate schema, source identity, freshness and sequence; separate producer ingest from user-facing stream authorization; apply explicit auth to both HTTP and WebSocket handshakes; add negative tests for missing, invalid, replayed and cross-tenant messages.

### RL-439 — Phoenix JSON API exposes multiple state-changing operational routes without visible authentication/authorization plugs
**Status: OPEN — HIGH PRIORITY SECURITY / GOVERNANCE**

The inspected `TiannaraWeb.Router` API pipeline only applies JSON content negotiation. Within that pipeline, state-changing routes include `POST /api/v1/discovery/seed`, `POST /api/v1/interaction`, `POST /api/challenges/run`, `POST /api/crav/soak_test/start`, `POST /api/crav/soak_test/stop`, `POST /api/crav/atlas/generate`, `POST /api/crav/alpha_launch/launch`, `POST /api/crav/alpha_launch/abort`, and `POST /api/crav/campaign/trigger`, in addition to the physical deployment routes already tracked by RL-434. No authentication plug, verified principal assignment, authorization policy or Council grant check appears in the router's `:api` pipeline. The corresponding inspected controller functions directly invoke seeding, soak-test, launch/abort and campaign scheduling operations. This is a source-visible control-plane exposure, not proof that the endpoints are internet reachable or that an upstream gateway does not protect them.

**Closure evidence:** enforce a single verified identity and policy layer at the Phoenix boundary, not merely in an optional proxy; classify read, research, operational and physical effects separately; require explicit actor/effect-bound Council grants and human approval for governed high-impact actions; audit before effects; deny by default; verify with unauthenticated, forged-identity, insufficient-role, stale/replayed-grant and audit-store-failure HTTP tests. Keep emergency-stop narrowly available through a separately designed safety path.

### Python API and gateway trust-boundary reconciliation

The repository contains at least two distinct FastAPI app constructions: `tiannara_api.main:app` (the production entry point inspected here) and `tiannara_api.gateway.main:app`. The gateway app has its own middleware: in production it requires a valid JWT or active API key for all paths except its public-prefix list, which includes `/api/v1/gateway`; it also applies configurable CORS origins. The main app instead uses `ProductionAuthMiddleware` with a narrower protected-prefix allowlist and separate JWT context population. The gateway app's auth middleware is not shown as wrapping or being mounted around the main app in the inspected entry points. No shared ASGI composition or trusted gateway-to-Phoenix identity propagation was established. Thus, the existence of a stronger gateway does not establish that all main-app or Phoenix routes inherit its protection. This remains an architecture/integration gap pending deployment topology and reverse-proxy configuration review.

Positive controls: the main app uses restricted configured CORS origins; `ProductionAuthMiddleware` fails closed for its protected prefixes in production; the evolution router uses `Depends(require_auth)`; workflow and automation routes use tier decorators that require a populated authenticated request state; `require_auth` validates JWT/API key against user records in production. However, tier checks are not a substitute for resource ownership: the inspected workflow handlers explicitly contain a TODO to filter by JWT user ID, and list/get/update/delete operations use global in-memory dictionaries. This is a tenant-isolation concern to track in the SaaS/API audit, not proof that all tier-decorated routes are unauthenticated.

### Hardware integration inventory refinement

The top-level `Tiannara.Application.core_children/0` explicitly starts `Tiannara.Meta.Hardware.Supervisor`; its supervisor starts a Registry, HorizonScheduler and three EventHorizonTensorCore GenServers. This is a real OTP startup path, correcting any implication that Meta.Hardware is merely an unstarted directory. However, the inspected modules describe and implement a computational simulation: EventHorizonTensorCore's moduledoc says it simulates an EHTC; GravitationalShear explicitly describes pure Elixir simulation; payload processing maps numeric values, computes a checksum-like result and calls a parity validator. Comments mention simulated NIF/CUDA offload, but no NIF, CUDA runtime, device driver, ROS client, fieldbus or physical actuator interface is implemented in these inspected files. The supervisor's presence therefore establishes a running software subsystem by design, not physical hardware integration. This reinforces RL-435 and narrows the distinction: Meta.Hardware is an OTP-managed simulated compute subsystem, not evidence of device-control capability.

The ASC PhysicalDeploymentManager remains separate. Its default adapter is SimulatedAdapter, and the previously inspected adapter implementation only records simulated actions. The Phoenix physical routes and manager methods remain subject to RL-434/RL-435. Search for ROS/ROS2, rclpy/rospy, MQTT, Modbus, CAN and serial integration did not yield a verified concrete physical driver in this pass; search non-results are not proof that no such code exists anywhere in the repository.

### Disposition

- RL-438: **OPEN** — unauthenticated Meta-Ecology telemetry ingest and stream in the inspected production FastAPI app.
- RL-439: **OPEN** — multiple Phoenix mutating operational routes lack visible authentication/authorization in the router pipeline; RL-434 remains the specific physical-control subset.
- RL-434, RL-435, RL-436 and RL-437 remain **OPEN**.
- Python main app and gateway are distinct app constructions; a common trusted deployment boundary was not demonstrated.
- Meta.Hardware is top-level supervised but its inspected processing is explicitly simulated; this is not physical hardware evidence.
- No source code was changed; no builds, tests, runtime execution, live HTTP requests, deployment/proxy inspection or hardware actuation were performed.

**Next checkpoint 18.69:** inspect the remaining Phoenix controller mutation handlers and their downstream service effects; trace the full Python auth dependency/decorator coverage for mutating routers and tenant ownership; inspect repository manifests/configuration and any external hardware bridge packages for concrete ROS/ROS2, serial, CAN, Modbus, MQTT or vendor-driver implementations. Keep deployment topology and physical capability UNKNOWN until directly evidenced.


## Checkpoint 18.69 — controller effects, API tenant isolation and CEL audit status

**Inspection basis:** frozen source commit `b829254d032f9e0b5cf4c44725c8cf451800dad0`. Read-only inspection; no runtime or deployment assumptions are promoted to facts.

### Additional source review

- `lib/tiannara/web/router.ex` — `917c749e023ff86d59200798b93dfe4bfd9c11f0`
- `lib/tiannara/web/crav_challenge_controller.ex` — `403b7177633cbb187d7388df86dc5bd02eb40046`
- `tiannara_api/main.py` — `f8883a9d4fbd3b329e52a8e7a73e5d3ab5145500`
- `tiannara_api/gateway/main.py` — `663ea5cc3607a33a26625024aaecaae9c2d5f2bb`
- `tiannara_api/routes/workflows.py` — `b4f729165779a752961bff9ac6bc52ff0a69e5d6`
- `tiannara_api/routes/automations.py` — `bd27bfabaf00ffbd19cba630dae599dc96bc256e`
- `tiannara_api/routes/evolution.py` — `0356076fee06de0ff7b4fd36ee407f3d32992141`
- `tiannara_api/routes/meta_ecology.py` — `89e7794a77f8c242d96960bd205480f2357e2364`
- `certification/TIANNARA_PHASE16_EXECUTION_AUDIT.md` and `certification/remediation/MC003-A0-EXECUTION-INVENTORY.md` were discovered as relevant prior execution-audit records; their claims are design/audit artifacts and were not treated as proof of current runtime behavior.

### RL-440 — Workflow and automation resources lack visible tenant ownership enforcement
**Status: OPEN — TENANT ISOLATION / AUTHORIZATION**

The workflow router's endpoints use a tier decorator, but its list handler explicitly contains a TODO to filter by JWT user ID; the inspected handlers store objects in module-global in-memory dictionaries and fetch/update/delete by resource ID without checking that the resource belongs to the authenticated user. Automation handlers follow the same global-dictionary pattern and do not visibly compare resource ownership to the authenticated principal. Tier authentication can establish a user and subscription level, but it does not itself establish ownership of a specific workflow or automation. If these routers are exposed to multiple users, knowledge of an identifier may permit cross-tenant read or mutation; reachability and exploitability were not tested.

**Closure evidence:** persist owner/tenant IDs on every resource; scope list/get/update/delete/execute queries to the verified principal and tenant; enforce ownership again at execution boundaries; deny by default; add multi-tenant tests for ID guessing, cross-tenant mutation, workflow execution, automation trigger/toggle, and missing principal.

### RL-441 — Phoenix boot/readiness responses can assert readiness without checking the represented subsystems
**Status: OPEN — OBSERVABILITY / OPERATIONAL SAFETY**

The inspected `CRAVChallengeController.boot_status/2` constructs a fixed list of phases with every phase marked `complete` and returns status `ready`; it does not query the actual environment, infrastructure, runtime, API, frontend or health phase before asserting those values. The `runtime_status/2` handler does check a limited list of ports/modules, but that is not what `boot_status/2` uses. Consequently, the boot-status endpoint's positive state is a static response, not evidence that CEL, constitutional governance, downstream services, Python API, or hardware interfaces are ready. This finding is about the endpoint's evidentiary quality; it does not imply that every subsystem is down.

**Closure evidence:** derive readiness from live, bounded checks with explicit UNKNOWN/DEGRADED/READY states; tie critical dependencies to actual CEL boot reports and governance gates; avoid defaulting missing checks to complete; add tests for absent, delayed, failed and degraded dependencies; keep process liveness distinct from application readiness and physical readiness.

### Controller effect trace and route disposition

The Phoenix router uses an API pipeline containing only JSON acceptance; it has no visible authentication/authorization plug. Controller handlers for challenge execution dispatch named challenge functions, while soak-test, atlas, launch/abort and campaign routes are registered as POST mutations. The physical deployment plan/advance/approve/abort routes call the physical deployment manager and remain the subset tracked under RL-434. This pass did not establish an upstream proxy, network policy or deployment topology, so the findings remain source-level exposure risks rather than confirmed externally reachable vulnerabilities.

### CEL audit completion assessment

**The CEL audit is not complete.** Checkpoints 18.60–18.69 have accumulated meaningful findings and corrections, but this is an ongoing, bounded source audit rather than a completed whole-system certification. The canonical service registry and boot sequencer are not a complete inventory of all running components, and static source inspection does not establish deployed behavior. Outstanding work includes, at minimum:

1. Finish the CEL service inventory and reconcile registry, boot sequence, supervisor trees, dynamically started children, actual call sites, health/liveness, and undeclared services.
2. Trace all authority-bearing transitions and effect paths end-to-end: constitutional authority, Council decisions, human approval, grant binding/expiry/replay, actor identity, audit-before-effect, durable audit failure, and rollback.
3. Close the security boundary review across Phoenix, both FastAPI apps, WebSockets, gateway/proxy configuration, service-to-service identity, and tenant ownership.
4. Complete hardware inventory across all repository roots/packages and transport/configuration boundaries; distinguish simulation, software model, hardware-in-the-loop and real device evidence.
5. Review research/discovery claims and evidence lineage so that proposed, simulated, inferred, executed and independently reproduced discoveries cannot be conflated.
6. Verify self-modification and self-improvement paths against the user's governance requirements: Council authority remains superior to CEL; human approval for improvements; immutable constitution/hash-chain audit; no self-authorized mutation of upstream authority.
7. Execute an evidence plan in an appropriate environment: static checks, unit/integration/security tests, boot failure injection, API negative tests, soak/restart tests, and hardware-in-the-loop only where actual hardware and safe controls exist. Record each as NOT RUN until evidence is captured.
8. Reconcile every open finding against a fix commit and reproducible closure evidence. Updating the report or finding a source path is not closure.

### Recommended sequence

- **Immediate:** address RL-434/RL-438/RL-439 and RL-436 (route auth, telemetry trust, CORS and principal propagation), then RL-440 (tenant ownership) and RL-441 (false readiness claims). Do not expose mutation endpoints until an effective boundary is verified.
- **Next audit phase:** resume CEL-wide inventory and authority/effect trace, beginning with service discovery completeness and dynamic child lifecycle, then Council-to-effect authorization and audit durability.
- **Parallel workstream:** hardware/transport inventory and research-evidence provenance; do not infer physical capability from simulated adapters or design documents.
- **Exit gate:** declare CEL audit complete only after the scope/inventory is reconciled, all findings have dispositions, high-risk controls have reproducible verification, unresolved items are explicitly accepted or blocked, and runtime/hardware claims have matching evidence. This checkpoint does not meet that gate.

### Disposition

- RL-440 and RL-441: **OPEN**.
- RL-434 through RL-439 remain **OPEN** as applicable; no finding is closed by this inspection.
- No source code was changed; no tests, builds, live HTTP requests, deployment inspection, fault injection or hardware actuation were performed.

**Next checkpoint 18.70:** start the CEL-wide service/authority reconciliation, compare registry and boot order with static supervisor trees and call-site references, then trace the highest-risk Council authorization and audit-before-effect paths. Keep the report append-only and treat unresolved evidence as UNKNOWN.


## Checkpoint 18.70 — CEL inventory/authority reconciliation and adjacent substrate spot-audit

**Inspection basis:** frozen source commit `b829254d032f9e0b5cf4c44725c8cf451800dad0`. This is a bounded source inspection, not a complete audit of AEO, Meta-SOPL, GRCC, ASC or REA. No tests, runtime execution, external deployment inspection or hardware-in-the-loop work was performed.

### CEL reconciliation observations

Reviewed:
- `lib/tiannara/cel/kernel/service_registry.ex` — `76e2861046ae51d4f94157b688037213d58099ac`
- `lib/tiannara/cel/kernel/boot_sequencer.ex` — `f9ebb5a9d096b89f6da0864a357907d5febfd93c`
- `lib/tiannara/cel/kernel.ex` — `fe120d61dcd03a7542b888cf8cce6f1f4e357430`
- `lib/tiannara/application.ex` — `1429f81fde9de3c31d4a9dc91b23c5b635670496`

The main OTP application has a substantial static child list, while CEL separately maintains a canonical service registry and dynamically starts registry entries. PhaseOmega has another subsystem registry/boot sequencer. These are three overlapping inventories with different scopes; none is shown here to reconcile every static child, dynamically started child, PhaseOmega registration, and runtime process into one authoritative graph. In particular, many top-level children are not CEL service-registry entries, and PhaseOmega's registration list is a subset rather than a complete projection of `core_children/0` plus conditional children. Treat whole-system completeness as **UNKNOWN**.

**RL-442 — OPEN — CEL boot gates can convert missing/failed constitutional checks into a pass and resource readiness is hard-coded.** `BootSequencer.check_constitution/2` catches any throw/exit/error and returns `:pass`; `Kernel.check_constitutional_score/1` catches and supplies a default score. The production kernel supplies `:sufficient` for every resource check. The dependency gate itself is a constant `:pass`. This means a failed or unavailable constitutional score computation can be represented as passing, and resource sufficiency is not measured by this boot path. This is a source-level control defect; no live boot was executed. **Closure:** fail closed on missing/exceptional score; bind dependency gate to validated dependencies/capabilities; use real resource measurements with UNKNOWN on failure; add failure-injection tests proving critical services cannot become READY on missing evidence.

**RL-443 — OPEN — CEL restart authorization omits the requesting actor/context and accepts conditional decisions as executable approval.** `Kernel.handle_call({:restart_service, id, actor}, ...)` does not use `actor`; it calls `Council.authorize/3` with a nil context and proceeds for both `:approved` and `:conditional`. The subsequent audit helper catches all failures and returns `:ok`. This does not establish actor-bound, effect-bound, durable authorization/audit before restart. **Closure:** bind authenticated actor, service, exact restart effect, expiry/nonce and Council decision; define and enforce conditional obligations before effect; make durable audit failure block the effect; test denial, expired/replayed grants and audit-store failure.

**RL-444 — OPEN — CEL service inventory mutation has no visible authority gate in the registry API.** The inspected public GenServer calls `register/1`, `deprecate/1` and `replace/2` mutate the in-memory canonical registry without caller identity, Council grant, audit record or immutable policy check in these handlers. This is not proof that no external wrapper exists, but direct callers can reach these public functions unless constrained elsewhere. **Closure:** enforce authenticated principal and Council-authorized, scoped change grants inside the mutation boundary; validate schema, dependency references and uniqueness; append durable before/after audit; protect bootstrap roots and constitutional services from self-authorized replacement.

### Adjacent substrate spot-audit

**AEO:** `lib/tiannara/aeo.ex` (`25f10219fea31c487f65327d0f352942afd4897b`) exposes the named intent-to-execution bridge, but `translate_intent/1` returns a fixed placeholder graph and `submit_to_runtime/1` returns a fixed `:submitted_to_runtime` value. The domain-team helper sorts supplied weights but does not establish a runtime dispatch. A search found a forecasting adapter calling the submit function, but that call does not make the implementation operational. **RL-445 — OPEN:** AEO's advertised translation/submission boundary is placeholder behavior, not a demonstrated execution bridge. Closure requires typed validated plans, OED/constitutional validation, real runtime submission with correlation/acknowledgement, failure propagation, and end-to-end tests.

**Meta-SOPL:** `tiannara_runtime/lib/tiannara_runtime/core_stack/meta_sopl_governor.ex` (`357093c04cf01ec9f1190b525d034edf86f24aba`) schedules periodic mutation-rate changes using `:rand.uniform/0`, rather than reading measured telemetry as the module comments describe. It casts a `MetaAdjustment` to `SafetyCortex` without checking the recipient exists or confirming acceptance; only mutation_rate is changed in local state. **RL-446 — OPEN:** Meta-SOPL's feedback/effect contract is not evidenced as telemetry-driven or acknowledged. Closure requires authenticated telemetry inputs with provenance/freshness, deterministic bounded policy evaluation, explicit SafetyCortex acknowledgement/rejection, durable audit, and proof that downstream constraints—not direct state mutation—are the only effect.

**GRCC:** `tiannara_runtime/lib/tiannara_runtime/core_stack/grcc_supervisor.ex` (`6c361154acb06407bd196f21373727405fd9c42d`) currently declares an empty child list, despite its state-generation-kernel description. A separate runtime GRCC simulation cortex and lineage modules exist elsewhere, so this does not prove GRCC as a whole is absent. It does mean this named supervisor contributes no child processes of its own. **RL-447 — OPEN:** GRCC supervisor-to-generator wiring is not present in this module; reconcile intended ownership with actual lineage/ecology supervisors, event inputs/outputs, lifecycle and CEL discovery.

**ASC:** `lib/tiannara/asc/core/asc_metrics.ex` (`9d63168d1c9959c3f161b1ab45880aaa4f6aaa2e`) returns a default health value of 0.5 for phases with no health metric. This creates a plausible numeric baseline rather than exposing missing observations as UNKNOWN. ASC is also feature-flagged in `Tiannara.Application.asc_children/1`, while some adjacent ASC agency/mission components are listed in always-on children; the split needs an explicit dependency/availability contract. **RL-448 — OPEN:** ASC health metrics can mask missing phase observations, and feature-gated versus always-on ASC components need lifecycle reconciliation. Closure requires UNKNOWN for absent data, evidence timestamps/provenance, explicit enabled/disabled/degraded semantics, and tests across both flag states.

**REA:** `scripts/rea_5_1_a_arch.exs` (`96eafac762fa8c176a0e7f53f01ac26da58b67cd`) explicitly labels Stage A as simulated, constructs mocked niche assignments/weights, and invokes its validation at file load. It cannot establish scientific speciation or empirical evolutionary behavior. `scripts/rea_5_1_a_metric.exs` (`6e41040a048c1282ea01fba2608b39b864e057bb`) constructs a random synthetic graph and synthetic archetype panel; its “real traversal” is real computation over generated in-memory data, not traversal of an independently observed real-world substrate. **RL-449 — OPEN:** REA evidence labels need a strict boundary between simulated architecture checks, synthetic computational experiments, instrumented runtime experiments and empirical biological/ecological evidence. Closure requires explicit evidence class, seed/config/data provenance, reproducibility, independent baselines, uncertainty and no promotion from synthetic traversal to real-world discovery.

### Status and remaining work

- New findings RL-442 through RL-449: **OPEN**.
- This checkpoint does not close earlier findings.
- AEO, Meta-SOPL, GRCC, ASC and REA received only targeted spot checks; each requires a dedicated subsystem audit of source tree, supervision, interfaces, contracts, authority, data lineage, failure behavior, tests and runtime evidence.
- Other systems/substrates named for future review, including further GRCC pathways, research/discovery, hardware integration, and governance/execution links, remain in scope.
- No source code was changed. No tests/builds/runtime/HTTP/security/fault-injection/physical-device checks were run.

**Next checkpoint 18.71:** continue the inventory across PhaseOmega and runtime supervisor trees, reconcile the three registries against actual processes and call sites; then audit AEO end-to-end plan validation and runtime submission, followed by Meta-SOPL-to-CIS/SafetyCortex authority and acknowledgement. Keep the remaining AEO/Meta-SOPL/GRCC/ASC/REA work explicitly open.


## Checkpoint 18.71 — PhaseΩ boot-verification semantics and AEO/Meta-SOPL/GRCC/ASC/REA follow-through

**Inspection basis:** frozen source commit `b829254d032f9e0b5cf4c44725c8cf451800dad0`. This is source inspection only. No tests, builds, runtime boot, live services or empirical experiments were executed.

### PhaseΩ integration findings

Reviewed `lib/tiannara/phase_omega/activator.ex`, `boot_sequencer.ex`, `subsystem_registry.ex`, `runtime_verifier.ex`, and the runtime authority supervisors.

**RL-450 — OPEN — PhaseΩ boot health probes can report success without evaluating the probe result.** In `BootSequencer.verify_health/2`, the configured `{module, function, args}` is invoked but its return value is discarded; any non-raising return (including `false`, `{:error, reason}`, or a degraded marker) becomes `:ok`. In the `:already_started` branch, the result of `verify_health/2` is itself discarded and the subsystem is returned as successfully started. Consequently, configured health probes do not currently establish health according to their result contract. **Closure:** define an explicit accepted health-result algebra; reject false/error/unknown results; propagate health failures from the already-started branch; add tests for true/false/error/raise/exit and pre-existing unhealthy processes.

**RL-451 — OPEN — PhaseΩ boot reports success to its caller even when individual subsystem boots fail.** `BootSequencer.do_boot/1` records failed subsystems, attempts rollback, and marks phase `:degraded`, but the GenServer `:boot` handler unconditionally replies `:ok`. `Activator.bootstrap/0` treats `:ok` as “All dark subsystems booted successfully” and proceeds to runtime verification/dependency reporting. This makes the caller-facing result inconsistent with the internal results and can overstate successful activation. **Closure:** return a structured result with per-subsystem outcomes and an explicit overall status; have the activator distinguish ready/degraded/failed; prevent a success log or dependent activation on partial failure; test one failed critical and one failed noncritical subsystem.

The registry's `RuntimeVerifier` also treats absent PID/health responders as `:skip`; overall status is degraded only if no check fails. This is more honest than an automatic pass in some cases, but it means a module-loaded record with no PID can still avoid a hard failure. The policy for required process liveness must be explicit by subsystem type/criticality.

### Cross-substrate reconciliation

**AEO:** The base `Tiannara.AEO` module remains placeholder-backed: fixed execution-graph placeholder and fixed submission acknowledgement. A forecasting adapter calls `submit_to_runtime/1`, but wraps its result in another `{:ok, ...}` tuple, so the adapter's declared `{:ok, term()} | {:error, term()}` contract may produce a nested success tuple. This is a contract/integration concern; no runtime consumer test was run. RL-445 remains OPEN. Closure must include a real command/plan dispatch, result correlation and failure propagation, and contract tests at the adapter boundary.

**Meta-SOPL:** The independent `tiannara_runtime` root supervisor includes `Meta.Supervisor` under the `:stable` and `:research` profiles; `Meta.Supervisor` starts `RateModulationSupervisor`. This establishes a source-level startup path in that runtime profile, correcting any implication that Meta-SOPL has no supervisor path. However, the governor still uses random drift rather than measured telemetry and casts to SafetyCortex without acknowledgement. RL-446 remains OPEN.

**GRCC:** The empty `Tiannara.GRCC.StateGeneratorSupervisor` is intentionally placed under `Tiannara.OPC.CoreSupervisor`; its own module comment says world/civilization state is supervised separately by `TiannaraRuntime.Ecology.Supervisor` via `Tiannara.UniverseSupervisor`. Therefore, the empty child list alone does **not** establish that GRCC is unwired or absent. RL-447 is **REVISED**: the remaining question is whether the intended lineage/token/state-generation modules and interfaces are connected to this split execution/ecology ownership, not whether this supervisor must itself own children. Do not close until the ownership map and call/event paths are traced.

**ASC:** `Tiannara.ASC.Core.Metrics.global_health/0` averages five phase-health values and substitutes `0.5` whenever a phase has no health observation. This is a fabricated midpoint for missing evidence, not a measured neutral health. RL-448 remains OPEN.

**REA:** The Stage A script explicitly describes itself as simulated traversal and uses mocked niche classification/weights. The Stage B script generates a random in-memory graph and a fixed archetype panel, then performs actual traversal over that synthetic graph. It is valid as a synthetic computational exercise, but not evidence about an independently observed biological/ecological system. Both scripts invoke their validation functions at file load. RL-449 remains OPEN; evidence classification must be preserved at the experiment-result boundary.

### Status and next work

- RL-450 and RL-451: **OPEN**.
- RL-445, RL-446, RL-448, RL-449: **OPEN**.
- RL-447: **OPEN, scope corrected**; empty supervisor is intentional according to source comments, but GRCC's split ownership and real call paths remain unverified.
- CEL and PhaseΩ inventories remain unreconciled; this checkpoint did not test runtime process discovery or activation.
- AEO, Meta-SOPL, GRCC, ASC and REA remain only partially audited. Additional dedicated reviews are still required for governance authority, persistence, data lineage, external interfaces, tests and runtime evidence.

**Next checkpoint 18.72:** trace PhaseΩ health/boot contracts into the actual callers and compare its registry against the runtime root supervisor and CEL registry; then trace GRCC's actual lineage/state-generation modules across Execution/Ecology and Meta-SOPL's telemetry source/constraint acceptance. Continue the AEO execution boundary and REA evidence registry review.

No source code was changed. No tests/builds/runtime/HTTP/fault-injection/physical-device checks were run.


## Checkpoint 18.72 — PhaseΩ dependency semantics, GRCC split ownership, and forward evidence integration

**Inspection basis:** frozen source commit `b829254d032f9e0b5cf4c44725c8cf451800dad0`. Source-only inspection; no tests, builds, runtime boot, external services or physical systems were exercised.

### New findings

**RL-452 — OPEN — PhaseΩ dependency resolution silently removes dependencies absent from the boot specification and does not reject cycles.** In `BootSequencer.resolve_order/2`, each dependency list is filtered to names present in `specs`. Missing dependencies are therefore removed from the ordering graph rather than treated as a boot blocker. The depth-first sorter returns when it encounters a node already in `visiting`, without returning a cycle error. Although the activator separately logs missing dependencies and cycles from the registry, `check_dependency_graph/0` returns `:ok` regardless, and the boot sequencer resolves only its own specification subset. **Closure:** fail closed for missing required dependencies and cycles; distinguish optional dependencies explicitly; produce a validated DAG before any start; test missing, optional, self-cycle, multi-node cycle and mixed graph cases.

**RL-453 — OPEN — PhaseOmega boot certificates do not attest to the running artifact or successful health evidence.** `generate_certificate/2` hashes subsystem name, current timestamp, and MD5 hashes of the declared dependency and child-name lists. It does not bind source/build identity, runtime instance identity, health-probe evidence, dependency certificate hashes, configuration, or observed child processes. The certificate can therefore be read as a startup-record identifier, but not as a verifiable certificate that the declared subsystem implementation and dependencies were actually healthy. **Closure:** either rename/restrict it to a boot record, or bind a canonical signed evidence envelope containing artifact/build digest, runtime instance, validated dependencies, observed children, health evidence, configuration digest and issuer authority; verify the chain independently.

**RL-454 — OPEN — Forward provenance is explicitly not integrated with runtime producers or evidence consumers.** The frozen `TIA_FORWARD_PROVENANCE_INTEGRATION_STOP.yaml` states that the standalone forward-provenance subsystem is demonstrated separately but runtime integration is absent and unauthorized at that gate. The companion integration reconnaissance records three competing execution-ID generators (forward provenance, OPC ExecutionRuntime, Phase-4 RealExecution), no shared execution identity mapping, no distributed parent/child execution linkage, and no implemented runtime-equivalence event sequence. It also says the integration test plan K–T is not executable until runtime-facing integration exists. This materially limits claims that REA/ASC/Research Director/knowledge promotion/certification currently share a verified provenance chain. The document's historical status and test claims are recorded as source assertions, not independently rerun here. **Closure:** resolve certification authority; implement only approved forward-only producer emission and consumer verification; reconcile identities without rewriting historical records; add runtime tests for retry, partial/timeout/cancelled runs, metric lineage, tampering, stale certificates, cross-runtime identity substitution and distributed parent linkage; keep all historical unknowns unchanged.

### Cross-system trace conclusions

**PhaseOmega:** `RuntimeVerifier.verify_all/0` returns `:ok` after running checks and stores detailed results separately. Per-record checks classify absent PID and absent `healthy?/0` responder as `:skip`; the aggregate becomes `:degraded` if no check fails but at least one is not `:pass`. This is not a direct false PASS, but criticality-specific requirements are not applied in this verifier. A critical subsystem with no PID/responding health interface can remain merely degraded instead of being blocked. Its API also does not return the aggregate result to the activator. This reinforces RL-450/451; it is not separately numbered to avoid duplicating the same boot/readiness defect.

**GRCC:** `GRCC.StateGeneratorSupervisor` has no children and explicitly states it owns token generation/state-machine evolution only, while `UniverseSupervisor` is started separately under `TiannaraRuntime.Ecology.Supervisor`. The inspected supervisor does not itself implement token generation or lineage state machines. The split may be intentional, but the concrete module ownership/call path remains unresolved. RL-447 remains OPEN with corrected scope. The search/inspection performed here did not establish the complete GRCC implementation or its event/data flow.

**Meta-SOPL:** `RateModulationSupervisor` starts `Governor` under the independent runtime root's Meta layer. The governor initializes fixed parameter values, then periodically adds random drift to mutation_rate. It sends `{:meta_adjustment, adjustment}` to SafetyCortex via an asynchronous cast and updates its local state without an acknowledgement or recorded acceptance/rejection. This confirms RL-446 and makes downstream acceptance, bounds enforcement and audit evidence a required follow-up.

**AEO:** Source confirms `translate_intent/1` returns `:execution_graph_placeholder` and `submit_to_runtime/1` returns `{:ok, :submitted_to_runtime}` without dispatch. The D3 adapter wraps the latter in `{:ok, ...}`, yielding nested success if the bridge retains its current tuple return. RL-445 remains OPEN.

**REA/evidence architecture:** The claim registry itself marks several claims PARTIAL/UNKNOWN, UNTESTED or INCONCLUSIVE and explicitly distinguishes analytical/module validation from empirical grounding. The forward-provenance stop document provides an explicit integration boundary: no historical backfill or reinterpretation, and no runtime certificate authority wiring before authority is resolved. Preserve these restrictions. No new empirical discovery claim is certified by this checkpoint.

### Status and next work

- RL-452, RL-453, RL-454: **OPEN**.
- RL-445, RL-446, RL-448, RL-449, RL-450, RL-451 remain **OPEN**.
- RL-447 remains **OPEN, corrected scope**.
- CEL/PhaseOmega/runtime-root inventories remain unreconciled.
- AEO, Meta-SOPL, GRCC, ASC and REA remain partially audited; this checkpoint is not a substrate completion certificate.

**Next checkpoint 18.73:** reconcile the exact runtime root child tree against the application child tree, PhaseOmega declared specs and CEL service registry; trace GRCC lineage/state producers and consumers; inspect SafetyCortex's handling of MetaAdjustment; and inspect provenance/claim-promotion call sites for any current consumer that treats unverified legacy evidence as certified. Do not integrate or mutate any system as part of this read-only audit.

No source code was changed. No tests/builds/runtime/HTTP/fault-injection/physical-device checks were run.


## Checkpoint 18.73 — supervisor/registry reconciliation, GRCC execution boundary, MetaAdjustment handling, and knowledge-promotion provenance

**Inspection basis:** frozen source commit `b829254d032f9e0b5cf4c44725c8cf451800dad0`. Read-only source inspection. No tests, builds, runtime boot, NATS services, live API calls, or physical operations were run.

### New findings

**RL-455 — OPEN — Knowledge promotion does not enforce the forward-provenance certification policy.** `lib/tiannara/world/knowledge_coordinator.ex` exposes two promotion paths. `promote_to_knowledge/1` accepts an entity when confidence is at least 0.4 and its evidence list contains at least one item, then promotes it and publishes `knowledge.promoted`; it does not require a forward certificate, certificate reference, or verified primary-evidence lineage. `promote_memory_stage/3` gates selected higher stages on a caller-supplied `human_approved` flag or low impact, but likewise has no forward-certificate check. `fuse_evidence_internal/3` calls `EvidenceValidator.validate_entity_evidence/1` but discards its return value. The validator reconstructs the legacy `ProvenanceEngine` lineage and treats a missing lineage as valid below its 0.8 high-confidence threshold; it does not verify a forward-provenance certificate. `KnowledgeFlowEngine` subscribes to `knowledge.promoted` and propagates the entity based on stage, without checking certificate/lineage status. This is inconsistent with `TIA_PROVENANCE_CERTIFICATION_POLICY.yaml`, which states that only forward-certified primary evidence may enter scientific promotion as certified input and that missing/contested certified lineage must be quarantined. The integration reconnaissance also explicitly records that knowledge items have no certificate reference in lineage today and marks the promotion gate mechanics unresolved. This finding does **not** authorize backfilling or reinterpreting historical claims. **Closure:** preserve all existing historical states; introduce a forward-only promotion gate that verifies certificate authority, evidence-envelope linkage, primary/derived lineage and status before certified promotion/propagation; keep uncertified or unknown items explicitly provisional/quarantined; propagate validator failures; test missing, stale, revoked, contested, mismatched and valid certificates plus low/high confidence cases.

**RL-456 — OPEN — The source defines multiple runtime inventories without an authoritative crosswalk, so registry membership cannot be treated as a complete system inventory.** The main `Tiannara.Application` declares its own direct child tree and dynamically builds optional ASC children. Its `register_subsystems/0` separately defines a PhaseΩ boot subset (14 subsystem specifications in that function, plus conditional ToolForge) and separately registers ROS. The PhaseΩ activator has another manually maintained running-subsystem list (17 entries including conditional ASC) and then invokes BEAM process auto-discovery. CEL's `ServiceRegistry.canonical_services/0` independently declares 32 dynamic services, started through the CEL Kernel's `DynamicSupervisor`. Separately, `TiannaraRuntime.Application` starts `StartupSupervisor`, which starts `TiannaraRuntime.RootSupervisor` with Infrastructure, Execution, Ecology, Constraint and Meta authority supervisors according to boot profile. These are distinct registries and startup graphs; the inspected source does not provide a canonical identity/ownership/dependency crosswalk that proves their populations, optionality, runtime instance identity and health requirements reconcile. This does not prove that any individual listed service is absent; it means registry counts, module discovery or one supervisor's children cannot establish whole-system coverage. **Closure:** define a versioned authoritative subsystem manifest with stable subsystem IDs, owning application/supervisor, boot profile/feature conditions, dependencies, criticality, runtime instance and health contract; derive or validate CEL and PhaseΩ views against it; report unregistered, multiply-owned, stale and discovered-but-unowned processes explicitly; test each profile and feature-flag combination.

### Cross-system trace refinements

**GRCC (RL-447 remains OPEN; scope refined, not duplicated):** The Elixir path is `RootSupervisor → Execution.Supervisor → OPC.CoreSupervisor → GRCC.StateGeneratorSupervisor`, but the GRCC supervisor's child list is empty. The ecology path separately starts `Tiannara.UniverseSupervisor` under `Ecology.Supervisor`. The Python `tiannara_runtime/python_cortex/grcc_simulation_cortex.py` exposes NATS subjects for simulation requests/results and CIS interventions, but its own `run_simulation_step/1` says the GRCC v10/v11 logic is TODO and currently simulates lineage population changes, entropy and niches. The source inspected here does not establish that this Python process is launched/supervised by the OTP startup graph or that its outputs are authoritative world-state lineage. The named Elixir supervisor's documented split ownership may be intentional; the unresolved issue is the real producer/consumer and lifecycle path, not the empty child list alone. **Closure:** identify the authoritative GRCC state/lineage implementation, map all Elixir/Python producers and consumers, prove process startup and message contracts, distinguish synthetic simulation from authoritative ecology state, and test lineage identity, ordering, loss/replay and failure handling.

**Meta-SOPL (RL-446 remains OPEN):** The governor emits `MetaAdjustment` by cast; SafetyCortex's matching handler only adds the struct fields to its bounded in-memory intervention log and returns `{:noreply, ...}`. No adjustment validation, policy decision, bounds check, acknowledgement/rejection, parameter application or durable audit is performed in this handler. The governor advances its local mutation-rate value immediately after sending. This confirms that the observed connection is advisory logging rather than an enforced feedback-control path. No new finding number is assigned to avoid duplication.

**Forward provenance / historical firewall:** The policy explicitly prohibits certificates for pre-T0/legacy unverified evidence, historical bundle backfill, certificate regeneration/repair/reinterpretation, and requires absent/contested certified lineage to be quarantined. The integration reconnaissance explicitly marks the KnowledgeStore promotion gate and certificate reference in knowledge lineage unresolved. The runtime promotion code described in RL-455 therefore exposes an implementation/policy gap for future promotion; it does not establish that any particular historical claim was actually promoted as forward-certified. Historical records remain untouched and their status remains UNKNOWN/UNRESOLVED where previously recorded.

### Status and next work

- **RL-455, RL-456: OPEN.**
- **RL-445, RL-446, RL-447, RL-448, RL-449, RL-450, RL-451, RL-452, RL-453, RL-454: OPEN** (RL-447 scope refined; RL-446 acceptance path refined).
- The runtime ownership/registry reconciliation is a source-level mapping only; no live process tree or boot-profile matrix was observed.
- GRCC, Meta-SOPL, knowledge promotion/provenance, AEO, ASC and REA still require dedicated subsystem-level audits. CEL audit is not complete.
- No source code was changed. No tests/builds/runtime/HTTP/NATS/fault-injection/security exercises/physical-device checks were run.

**Next checkpoint 18.74:** continue the read-only audit into CEL's knowledge/evidence services and their promotion call sites, trace actual GRCC NATS publishers/subscribers and Python process launch ownership, and reconcile the authoritative manifest question against runtime discovery and boot-profile behavior. Then continue dedicated AEO/ASC/REA and hardware-interface coverage without treating declared interfaces or synthetic computation as operational proof.


## Checkpoint 18.74 — CEL promotion semantics, GRCC transport reachability, and discovery certification levels

**Inspection basis:** frozen source commit `b829254d032f9e0b5cf4c44725c8cf451800dad0`. Read-only source inspection only. No NATS server, Python cortex, OTP runtime, API, tests, builds or hardware were started or exercised.

### New findings

**RL-457 — OPEN — The documented Python↔Elixir GRCC NATS loop is not connected through the inspected production startup/transport graph.** The Python cortex uses the actual `nats-py` client and subscribes to `grcc.sim.step.request` and `cis.intervention.trigger`, publishing `grcc.sim.step.result` and `cis.intervention.ack`. The Elixir `TiannaraRuntime.EventGateway` declares the matching GRCC result subscriptions, but its `connect_nats/0` unconditionally returns `{:error, :unavailable}`; its reconnect loop therefore cannot establish a connection through this implementation. The EventGateway is not a child of the inspected `StartupSupervisor`, `RootSupervisor` or `NATS.Supervisor`. The separately supervised `NATS.Supervisor` starts a local Registry-backed `NATS.Bus`, a custom `Connection`, Publisher and Subscriber. That Subscriber listens to `tiannara.simulation.grcc.>` and related `tiannara.simulation.*` subjects rather than the Python cortex's `grcc.sim.step.result`; its registered-process delivery path sends `{:nats_message, ...}`, while the Subscriber defines no corresponding `handle_info/2` handler (its `handle_message/2` API uses a cast with a different tuple). The custom Connection opens a TCP listener on port 4222 and parses newline-delimited JSON maps; this is not the NATS protocol expected by `nats-py`/Gnat. If a real NATS server already owns that port, this listener cannot bind; if it binds, it is still not a compatible NATS server. Thus the repository contains separate pieces and a documented subject topology, but the inspected production path does not establish a working GRCC round trip. **Closure:** select one actual NATS implementation and one canonical connection owner; supervise the gateway and clients explicitly; use a compatible NATS server/client protocol; align exact subject names and payload schemas; route inbound messages to state/CIS handlers; define ack, timeout, retry, idempotency and provenance contracts; add integration tests with a real NATS server and both processes, including disconnect/reconnect and malformed/duplicate/stale messages. Until then, classify the Python cortex as a standalone simulation component, not an operationally integrated GRCC/CIS loop.

**RL-458 — OPEN — Discovery certification API marks provisional discoveries as `certified: true`.** `DiscoveryCertifier.certified?/1` returns true for both `:certified` and `:provisional`. `KnowledgeCoordinator.handle_call({:certify_discovery, ...})` stores that boolean in the decision record, publishes it as `discovery.certified` payload field `certified`, and returns it to the caller alongside the detailed `certification_level`. Consequently, a provisional result (which by definition may still require independent replication or statistical power) is represented by a positive boolean named `certified`. Consumers that rely on the boolean rather than the level/conditions can misclassify provisional evidence as fully certified. The detailed level is present in the same event, so this is a semantic contract defect, not proof that every consumer ignores the level. **Closure:** replace the boolean with an explicit certification-level/status algebra; reserve `certified: true` for `:certified` only; represent provisional separately with its conditions and expiry; require downstream consumers to fail closed on unknown/missing levels; add contract tests for all five levels (`:certified`, `:provisional`, `:uncertified`, `:rejected`, and any future level).

### CEL promotion and provenance trace (RL-455 refinement)

The direct promotion path in `KnowledgeCoordinator` was rechecked. `promote_to_knowledge/1` requires only confidence >= 0.4, at least one evidence item and not already promoted before invoking `KnowledgeEvolutionEngine`; `promote_memory_stage/3` uses a caller-provided `human_approved` flag or defaults `impact_level` to `:low` for high-stage promotion. The event consumer in `KnowledgeFlowEngine` propagates promoted entities by stage without verifying forward-certificate status. `EvidenceValidator` checks the legacy `ProvenanceEngine` lineage and permits missing lineage below the high-confidence threshold; the coordinator's evidence-fusion path invokes it but discards its return value. This reinforces RL-455. No evidence was found in this bounded pass that historical claims have actually been backfilled or certified; the forward-only historical firewall remains mandatory.

### Runtime ownership and hardware scope

The source confirms that `TiannaraRuntime.RootSupervisor` starts Infrastructure, Execution and Ecology in all profiles, with Constraint and Meta in stable/research profiles; research adds optional NDE/TWP/OSL. `StartupSupervisor` starts that root, but does not start `EventGateway` or the Python cortex. This is source-declared ownership, not a live boot-profile observation.

Hardware integration remains incomplete in this checkpoint. The earlier source pass found the ASC physical deployment manager defaulting to a simulated adapter and Meta.Hardware components using simulated/offload-placeholder behavior; this pass did not establish a concrete, supervised physical driver path or hardware-in-the-loop evidence. No new hardware finding is assigned here; the hardware audit remains open.

### Status and next work

- **RL-457, RL-458: OPEN.**
- **RL-455, RL-456 remain OPEN.**
- **RL-445 through RL-454 remain OPEN**; no prior finding is closed by this checkpoint.
- CEL knowledge promotion, evidence validation and discovery certification require a complete consumer/call-site audit; GRCC requires real transport integration evidence; AEO, ASC, REA, Meta-SOPL and hardware interfaces remain partially audited.
- No source code was changed. No tests/builds/runtime/NATS/HTTP/fault-injection/security exercises/physical-device checks were run.

**Next checkpoint 18.75:** trace every consumer of `discovery.certified` and knowledge-promotion events; inspect the complete forward-certificate verifier and its authority/expiry/revocation behavior; trace concrete ASC and Meta.Hardware adapter implementations and all physical deployment entry points; then continue CEL service coverage and AEO/REA contract audits. Preserve the distinction between provisional, certified, simulated, runtime-observed and empirical evidence.

No source code was changed. No tests/builds/runtime/HTTP/NATS/fault-injection/physical-device checks were run.


## Checkpoint 18.76 — CEL event semantics, forward certificate verification, and hardware execution accounting

**Basis:** frozen source `b829254d032f9e0b5cf4c44725c8cf451800dad0`. Read-only source inspection/search only. No tests, builds, runtime boot, live API, NATS, fault-injection, or physical-device operations were run. The fetched report branch contained 18.74 but no persisted 18.75 section; this entry records 18.76 without asserting an 18.75 result.

### New findings

**RL-459 — OPEN — Forward-provenance Verifier ACCEPT does not establish affirmative authorization or current certificate state.** `TiannaraOS.Provenance.Verifier.verify/1` checks manifest hashes, source/contract identities, execution linkage, result payload hash, metric recomputation, certificate-to-metric object-hash binding, and presence of required graph edge types. It does not inspect the certificate envelope's `decision` or `authority`, validate edge endpoints/bindings, resolve the immutable record through `CertificateIssuance.resolve/1`, or consult `CertificateLifecycle.current_state/1`. Thus ACCEPT is a bundle integrity/binding verdict, not proof that the decision is affirmative, the issuer is authorized, or the certificate is currently VALID. Separate predicate-local issuance and lifecycle modules do exist: issuance creates immutable VALID records; lifecycle supports VALID/SUSPENDED/UNVERIFIABLE transitions. REVOKED and SUPERSEDED transitions remain explicitly closed; no expiry mechanism was identified in the inspected lifecycle. **Closure:** retain separate integrity and authorization/current-state verdicts; validate decision, issuer, issuance record, lifecycle state and policy before any consumer treats a certificate as currently authoritative; unknown state must remain UNKNOWN/BLOCKED.

**RL-460 — OPEN — One KnowledgeCoordinator promotion event is ignored by KnowledgeFlowEngine due to a stage mismatch.** `promote_to_knowledge/1` publishes `knowledge.promoted` with `stage: :knowledge`. `KnowledgeFlowEngine` handles that topic only for `:pattern`, `:model`, `:principle`, `:generalized_understanding`, or `:scientific_discovery`; `:knowledge` falls through without propagation. The alternate memory-stage path publishes its target stage and may match the filter, but does not repair this path. **Closure:** define a canonical stage enum/event contract and test every promotion API against every emitted stage.

### Cross-system refinements

- **RL-458:** frozen-source search found `discovery.certified` published by KnowledgeCoordinator but no matching subscriber. KnowledgeFlowEngine subscribes to `discovery.published`, not `discovery.certified`. This is a bounded search result, not proof that no external/dynamic consumer exists; the boolean/level ambiguity remains open.
- **RL-455/RL-454:** `CertificateIssuance` and `CertificateLifecycle` are distinct forward-provenance modules in this snapshot. Issuance has a policy gate, first-writer-wins issuer registry and append-only ledger; lifecycle consumes issuance records and supports VALID/SUSPENDED/UNVERIFIABLE transitions. Revocation/supersession are explicitly closed. These predicate-local modules are not enforced by CEL KnowledgeCoordinator's legacy promotion path, which still lacks forward-certificate checks. This corrects any broad claim that no forward issuance/lifecycle implementation exists; the remaining issue is integration and verifier semantics. No certificate was issued or lifecycle transition run.
- **RL-428/RL-434/RL-435:** ASC PhysicalDeploymentManager defaults to SimulatedAdapter. That adapter advertises simulated hardware, records actions in memory and returns synthetic success. RealitySupervisor supervises the simulated adapter and manager; RealityDirector routes physical targets to the manager. Phoenix exposes physical plan/advance/approve/abort routes in its JSON API pipeline; the controller takes the approver string from request parameters/default. This reinforces existing findings; no duplicate assigned. No concrete physical driver, HIL test or actuation path established.
- **Meta.Hardware:** EventHorizonTensorCore explicitly simulates processing. It drains batches, starts asynchronous tasks, ignores Task.Supervisor.start_child return values and increments processed_count at dispatch rather than successful completion; no completion/error acknowledgement is emitted. HorizonScheduler tries alternate cores on backpressure but logs and returns total_saturation when all are full, dropping the payload. This is simulated compute, not hardware execution.

### Status and next work

- **RL-459, RL-460 OPEN; RL-457, RL-458 OPEN; RL-455, RL-456 OPEN.**
- **RL-445 through RL-454 remain OPEN.** Forward issuance/lifecycle predicates exist locally but CEL promotion integration and current-state verification are not established.
- CEL-wide service coverage, AEO, ASC, REA, Meta-SOPL and hardware integration audits remain incomplete.
- No source code was changed; no tests/builds/runtime/HTTP/NATS/fault-injection/security exercises/physical-device checks were run.

**Next checkpoint 18.77:** trace REA causal-lineage and discovery-to-knowledge paths; inspect remaining ASC execution/deployment adapters and Meta.Hardware task-supervisor ownership/failure handling; reconcile forward issuance/lifecycle against KnowledgeCoordinator and external verification surfaces; continue CEL inventory and AEO dispatch contract audit.


## Checkpoint 18.77 — REA lineage/causal path, Meta.Hardware task accounting, ASC adapter boundary, and AEO dispatch

**Basis:** frozen source `b829254d032f9e0b5cf4c44725c8cf451800dad0`. Read-only source inspection/search. No tests, builds, runtime boot, API calls, task execution, or hardware operations were run.

### New finding

**RL-461 — OPEN — Meta.Hardware counts queued payloads as processed when tasks are only dispatched, without observing task start/completion/result.** `EventHorizonTensorCore.handle_info(:process_batch, ...)` drains up to 50 payloads, calls `Task.Supervisor.start_child/2` for each, ignores each return value, and then decrements queue depth and increments `processed_count` by the full batch size. A failed task start therefore still counts as processed; a task that later crashes or returns a parity-validation failure is also not reflected in core state. The worker's `process_tensor/2` return value is not captured or reported to the GenServer. The task supervisor is present in the main application's top-level child list, but that ownership does not supply per-payload completion semantics. **Closure:** distinguish accepted, dispatched, started, succeeded, failed and dropped counts; check task-start results; attach stable payload/task IDs; report completion/error to the owning core; bound in-flight work; and add tests for supervisor unavailable, task-start failure, worker crash, parity failure, duplicate completion and shutdown with in-flight payloads.

### REA and causal-lineage audit

- `REA.Supervisor` declares the LineageRegistry, ArchaeologyRegistry, causal Graph and ChannelMonitor under supervision.
- The four primary evolutionary organism modules (Civilization, EpistemologySpecies, LawSpecies, MetaGenome) register root identities, mutation descendants, recombination descendants and extinction records with LineageRegistry. This corrects a possible concern from partial search: recombination does register identities; no missing-recombination-registration finding is assigned.
- `UniversalEvolutionEngine.tick_population/2` archives extinct organisms into ArchaeologyRegistry with causal attribution, runs selection/reproduction, and emits organism signals when `emit_signals/1` exists. `SimulationRunner.run/1` constructs four synthetic populations and ticks the engine; at configured snapshot intervals it records population/fitness/extinction summaries to ChannelMonitor.
- The causal Graph stores registered channels, queues emitted signals in memory, delivers pressure by target population/epoch and stores bounded per-channel history. ChannelMonitor records epoch population metrics and computes report values from its available observations.
- This is a real source-level simulation pipeline with explicit identity and causal registries; it is not evidence of validated causal inference about independently observed biological/ecological systems. The previously documented REA Stage A/B synthetic-data boundary (RL-449) remains. No empirical-system evidence or live REA run was produced in this checkpoint.

### AEO and D3 dispatch refinement (RL-445)

- `Tiannara.AEO.translate_intent/1` returns the fixed atom `:execution_graph_placeholder`; `submit_to_runtime/1` returns `{:ok, :submitted_to_runtime}` without calling Runtime or a dispatcher.
- `Forecasting.Adapters.DecisionImpl.submit_intent/1` wraps that return in `{:ok, ...}`, so the result is nested success-shaped data, not a runtime submission receipt. It does not demonstrate an execution ID, accepted command, runtime queue, policy/effect binding, or completion.
- The D3 adapter's authorization method does call Council when the Council process exists and returns an explicit unavailable error otherwise; that authorization behavior does not change the inert AEO dispatch implementation.
- This reinforces RL-445 and does not receive a duplicate ID. The D3 integration documents and diagrams are design/contract descriptions, not evidence that the AEO bridge dispatches.

### ASC adapter boundary refinement

- The inspected `PhysicalAdapter` is a behaviour contract only. Repository search found `SimulatedAdapter` as the concrete implementation in the ASC Reality adapter directory; it advertises `hardware: :simulated` and stores actions in an in-memory GenServer list.
- `PhysicalDeploymentManager` allows the adapter module to be selected from deployment design data, defaulting to SimulatedAdapter. The contract permits future concrete adapters but no concrete hardware implementation was established by this source search. A caller-selected module is not, by itself, evidence of a supervised, trusted, physically connected or safety-qualified adapter.
- Existing RL-428/RL-434/RL-435 and 18.76 refinements remain open. No new ASC finding assigned.

### Status and next work

- **RL-461 OPEN.**
- **RL-459, RL-460, RL-457, RL-458, RL-455, RL-456 remain OPEN.**
- **RL-445 through RL-454 remain OPEN.** AEO dispatch remains a fixed acknowledgement; REA recombination registration is present and no defect is assigned for that path.
- REA simulation pipeline is source-connected, but its empirical-science boundary remains; Meta.Hardware is simulation/task-dispatch only; ASC has no established physical adapter.
- CEL whole-system service coverage and AEO/REA integration audits remain incomplete.
- No source code changed; no tests/builds/runtime/API/task execution/fault-injection/physical-device checks were run.

**Next checkpoint 18.78:** trace REA causal-channel producers against channel topology and consumers; inspect the complete ChannelMonitor metric derivations and any empirical-data ingestion; verify all Meta.Hardware worker result and shutdown paths; inspect ASC adapter selection trust boundary and physical endpoint authorization; continue CEL service registry versus actual supervisor/boot coverage.


## Checkpoint 18.78 — REA causal topology and measurement, hardware worker lifecycle, ASC adapter trust boundary, and CEL activation coverage

**Basis:** frozen source `b829254d032f9e0b5cf4c44725c8cf451800dad0`. Read-only source inspection and bounded repository search. No tests, builds, runtime boot, simulation execution, API calls, fault injection, or physical operations were run.

### New findings

**RL-462 — OPEN — REA's canonical causal topology is not part of the main application/REA supervisor startup path.** `Tiannara.REA.Supervisor.init/1` starts the Graph and ChannelMonitor but does not load `Tiannara.REA.Causal.Topology.default/0`. The Graph initializes with empty channel maps. The main `Tiannara.Application.core_children/0` inspected for this baseline does not include `Tiannara.REA.Supervisor`, and its `register_subsystems/0` list does not register REA. The separate PhaseΩ `WiringEngine` defines an REA spec, but its `wire_all/0` call is reached through `PhaseOmega.Activator.bootstrap/0`; bounded call-site search found that bootstrap invoked by the explicit `mix phase_omega_scan` task, not by the normal application start path. Canonical topology loading was found in scripts and test/benchmark helpers, not in the REA supervisor or SimulationRunner. Thus the source contains a ten-channel topology and a working source-level graph algorithm, but this pass did not establish that normal application boot starts REA or loads that topology. **Closure:** choose one authoritative production activation path; include REA supervisor in the boot graph with verified dependencies; load and validate a versioned topology as part of REA initialization; expose channel-count/topology hash in readiness; and test production boot from a clean state. This refines RL-456's cross-inventory concern and does not claim the REA subsystem can never be started manually.

**RL-463 — OPEN — Causal Graph ignores each channel's configured transfer function.** The canonical topology configures `Channel.min_signal/1` for civilization-cohesion-to-meta-resilience and `Channel.max_signal/1` for epistemic-success-to-meta-innovation, alongside mean aggregators for other channels. However, `Graph.handle_call({:collect, ...})` always computes `signal_avg = Channel.mean(decayed)`; it never invokes `ch.transfer_fn`. Consequently the configured min/max semantics do not affect delivered pressure, and the resulting graph behavior differs from the declared topology. **Closure:** invoke a validated channel aggregation function (or a closed typed aggregation enum) during delivery; validate its output and failure behavior; add tests showing mean/min/max produce distinct expected results and ensure topology metadata matches executed semantics.

**RL-464 — OPEN — ChannelMonitor labels proxy calculations as causal stabilization/collapse metrics and counts empty channel epochs as samples.** `Graph.collect_pressures/2` creates a history row for every enabled target channel on every collection, even when no signal arrived; in that case the mean is zero and the row still contributes to history length and aligned sample count. `ChannelMonitor.compute_metrics/3` gates on history/snapshot lengths, then aligns these rows with same-epoch population fitness/extinction snapshots. Its `stabilization_effect` is `max(0, variance(low_signal_fitness) - variance(high_signal_fitness))`, not a measured before/after reduction in population variance or an identified causal effect. Its `collapse_correlation` correlates signal with `1.0 - extinctions`; because extinctions is a count, this is not a normalized extinction frequency and can become negative when an epoch has multiple extinctions. The `pressures` argument recorded by `SimulationRunner` is always `%{}` and is not used by these metric calculations. `SimulationRunner` constructs synthetic populations; no empirical ecological/biological ingestion was found in this bounded path search. **Closure:** distinguish observed-signal samples from empty collection epochs; define explicit denominators and time windows; use target-population variance before/after a defined intervention for stabilization; define normalized extinction rates; control for lag/confounders and baselines; label descriptive associations as such; and require independently sourced empirical data before presenting results as real-world ecological evidence.

### REA causal producer and consumer trace

- The four organism modules (Civilization, EpistemologySpecies, LawSpecies, MetaGenome) expose `emit_signals/1`; `UniversalEvolutionEngine.tick_population/2` invokes these for survivors and submits each signal to `Graph.emit/1`.
- The canonical topology contains ten directed channels among the four synthetic populations. Graph indexes channels by source/target, filters emitted signals by source population and signal type, queues them with configured delay, and collects due signals for the target population on subsequent ticks.
- Graph delivery applies channel decay and weight, but, per RL-463, uses mean aggregation for every channel. Channel history is generated at collection time, including zero-signal collections.
- REA.Supervisor supervises the registries, graph and monitor when started. The normal application startup path and explicit PhaseΩ scan path remain distinct; no live boot was performed to establish which path is active in a deployed environment.
- The pipeline is source-connected as a simulation. It does not establish empirical causal inference, independently measured ecological outcomes, or validated plant/animal preservation interventions. RL-449's synthetic-data boundary remains.

### Meta.Hardware worker result and shutdown refinement

- The inspected EventHorizonTensorCore has no custom `terminate/2`, drain protocol, in-flight task registry, task monitor, or completion message handler. It removes payloads from its queue before task outcomes are known.
- `Task.Supervisor.start_child/2` results are ignored; worker return values are not reported to the core. The task supervisor is a main-application child, but no per-payload lifecycle protocol is implemented.
- No graceful queue drain or explicit cancellation/settlement of outstanding tasks is implemented in the core. Supervisor shutdown therefore does not produce a core-level record distinguishing completed, failed, cancelled, or lost work.
- This further specifies RL-461; no new hardware finding assigned. Processing remains simulated and no NIF/CUDA/physical hardware execution was demonstrated.

### ASC adapter selection trust-boundary refinement

- `PhysicalDeploymentManager.plan/1` assigns `deployment.adapter = Map.get(design, :adapter, SimulatedAdapter)` without a visible allowlist, behaviour validation, capability policy, trusted adapter registry, or proof the selected module is supervised/connected.
- Later manager paths invoke module functions directly for `capabilities/0`, `status/0`, `execute_action/1`, `emergency_stop/0`, and `clear_estop/0`. The adapter behaviour specifies callbacks but does not itself authenticate or qualify implementations.
- This strengthens existing RL-428/RL-435 adapter trust and supervision concerns; no duplicate finding assigned. No caller-supplied module was executed and no physical endpoint was contacted.

### CEL registry versus boot coverage refinement

- The canonical CEL ServiceRegistry is a declarative service inventory with module, dependencies, provided/required capabilities, health and constitutional-score callbacks. The CEL BootSequencer starts these service specs under its own DynamicSupervisor; this is a separate inventory from the main application's direct child tree and PhaseΩ subsystem registry.
- The PhaseΩ WiringEngine defines an REA subsystem spec and dependency graph, but the main application has a separate manually maintained registration list. The explicit Activator bootstrap path performs runtime discovery and wires dark subsystems; bounded call-site search located its invocation in the Mix task `phase_omega_scan`.
- This confirms the inventories have distinct activation mechanisms and reinforces RL-456. It does not prove that every declared CEL service is absent or inactive; per-service startup and readiness require runtime evidence.
- Existing BootSequencer semantics remain: dependencies are skipped only when present in `failed_critical`; noncritical degraded dependencies are not equivalent to a healthy prerequisite. This is already covered by RL-394 and is not duplicated.

### Status and next work

- **RL-462, RL-463, RL-464 OPEN.**
- **RL-461 OPEN** with worker completion, failure accounting and graceful shutdown gaps further specified.
- **RL-456 refinement:** REA, CEL, main OTP application and PhaseΩ inventories/activation paths remain separate; no single verified production crosswalk is established.
- **RL-428/RL-435 refinements:** adapter module selection is caller-controlled in the inspected manager path and lacks a visible trusted-adapter qualification boundary.
- **RL-449 remains OPEN:** REA simulation is not empirical ecological validation.
- No source code changed; no tests/builds/runtime boot/simulation/API/fault-injection/physical-device operations were run.

**Next checkpoint 18.79:** inspect REA startup/activation call sites and PhaseΩ dependency enforcement in more depth; audit signal producer values and their biological/ecological meaning; inspect all channel topology mutation/evolution paths for preservation of transfer semantics; trace Meta.Hardware scheduler saturation/drop observability and task supervisor shutdown ownership; trace ASC adapter inputs from Phoenix/API controllers through the manager; and continue the CEL canonical-service inventory against actual start_link/health contracts. Assign RL-465+ only for independently supported, non-duplicate findings.


## Checkpoint 18.79 — REA signal contract, PhaseΩ health probes, scheduler drops, and ASC physical-plan input trace

**Basis:** frozen source `b829254d032f9e0b5cf4c44725c8cf451800dad0`. Read-only source inspection and bounded repository search. No tests, builds, runtime boot, simulation execution, API calls, fault injection, or physical operations were run.

### New findings

**RL-465 — OPEN — REA producer timestamps violate the Signal epoch contract and crash causal Graph signal ingestion.** `REA.Causal.Signal.t` declares `emitted_epoch: non_neg_integer()`; `Signal.emit/5` also specifies a non-negative integer epoch. However, all four inspected organism producers — `Ecology.Civilization`, `Sentinel.D2.EpistemologySpecies`, `SOPL.LawSpecies`, and `SOPL.MetaGenome` — set the emitted epoch from private `current_epoch/0` functions returning `DateTime.utc_now()`. The Graph's `handle_cast({:emit, sig}, ...)` computes `sig.emitted_epoch + ch.delay` to populate `arrives_at`; adding an integer delay to a DateTime struct raises an arithmetic error. If that is corrected in isolation, the collection path also computes `epoch - sig.emitted_epoch`, where the simulation supplies an integer epoch and the producer supplies DateTime, another incompatible arithmetic operation. The Graph is a supervised GenServer under REA.Supervisor, so a producer cast can crash/restart it and lose its in-memory channel/inflight/history state. This invalidates the assumption that source-level signal producers imply functioning causal delivery. **Closure:** use one canonical integer simulation epoch (passed from the engine into producers) or a separate explicitly typed wall-clock timestamp field; validate at Signal construction; add producer-to-Graph integration tests for all four organism types, delayed arrival, decay, and restart behavior; prove no Graph crash and correct delivered pressure. Do not mix wall-clock timestamps and logical simulation epochs.

**RL-466 — OPEN — PhaseΩ BootSequencer treats any non-raising health probe as healthy, ignoring its result.** `Tiannara.PhaseOmega.BootSequencer.verify_health/2` executes `apply(mod, fun, args)` and then unconditionally returns `:ok`; it only converts exceptions/exits to errors. The `WiringEngine.rea_healthy?/0` probe returns `:ok` when all expected processes are alive and `{:error, "some children not alive"}` otherwise. The sequencer therefore accepts that explicit unhealthy return as a successful probe, transitions the subsystem to healthy, and issues a startup certificate. The already-started supervisor branch also calls `verify_health/2` and then returns success. **Closure:** define a strict health-probe result contract and match only explicit healthy values (e.g. `:ok` or `:healthy`); map error, false, unknown, malformed and unexpected results to failure/degraded according to criticality; preserve the returned evidence in registry health state; test healthy, unhealthy, exception, exit, malformed and already-started paths.

### Signal producer semantic trace

- Civilization emits truth stock, compute capacity, economic output, cohesion, entropy/monoculture metrics and domain aptitude values. These are internal simulation state values, not independently measured civilization-wide observables.
- Epistemology emits cognitive yield, coherence, and operator success computed as `length(operator_set) * cognitive_yield / 10`; no independent operator execution-success sample is used in this producer.
- LawSpecies emits adaptive capacity as symmetry stability, reciprocal pathology-count as perturbation survival, and emergent-property count times 0.1 as diversity index.
- MetaGenome emits last evaluation fitness as resilience, but its diversity and innovation values are fixed binary proxies selected from strategy thresholds/probabilities (0.8/0.2 and 0.9/0.1), not measured population diversity or observed innovation outcomes.
- These semantic limitations reinforce RL-449's synthetic/proxy evidence boundary. They are not separately numbered in this checkpoint because the timestamp contract failure already prevents reliable ingestion and the proxy semantics require a dedicated follow-up comparing all fitness/pressure units and normalization assumptions.

### PhaseΩ dependency and activation trace refinement

- `PhaseOmega.Activator.bootstrap/0` calls runtime discovery, wiring, dependency checks and the PhaseΩ BootSequencer. Bounded call-site search located the direct invocation in the explicit Mix task `phase_omega_scan`; the normal `Tiannara.Application.start/2` path instead calls its own `register_subsystems/0` and starts CEL Kernel boot asynchronously in production.
- PhaseΩ `resolve_order/2` filters dependencies to names already present in its local spec set, and `boot_ordered/5` continues through all ordered names without checking whether a dependency previously failed. These behaviors are already represented by RL-393/RL-394 and are not duplicated.
- `WiringEngine.rea_healthy?/0` is a concrete example of a health probe returning a meaningful error tuple, which PhaseΩ currently discards under RL-466.

### Meta.Hardware saturation and ASC physical-plan input trace

- HorizonScheduler iterates configured HSV IDs and retries on backpressure or other returned errors. When all cores reject, it logs a saturation message and returns `{:error, :total_saturation}`; the inspected scheduler does not persist a drop record, retry queue, dead-letter entry, or metrics counter.
- EventHorizonTensorCore still drains queue entries before worker outcomes and increments `processed_count` by dispatched batch size; RL-461 remains the controlling finding for lifecycle accounting. This checkpoint did not establish a production caller of `HorizonScheduler.route_payload/1` in the bounded call-site search.
- ASC RealityDirector constructs the physical design from artifact and rollout params and calls `PhysicalDeploymentManager.plan/1`. The plan contains an adapter module selected by `design[:adapter]` or defaults to SimulatedAdapter. The inspected RealityDirector `physical_design/3` does not itself supply an adapter; caller-provided rollout params are retained in the design but are not converted into a trusted adapter identity there. Existing RL-428/RL-435 and 18.78 adapter trust-boundary refinements remain; no duplicate assigned.
- No physical controller file at the initially assumed path was found in this frozen snapshot. This does not establish that no API/controller route exists elsewhere; the controller-to-director path remains open for later repository-wide route tracing.

### Status and next work

- **RL-465, RL-466 OPEN.**
- **RL-462–464 OPEN** from 18.78; REA runtime signal delivery now has an additional contract-level blocker (RL-465).
- **RL-461 OPEN:** dispatch is still counted as processed before task completion; no durable saturation/drop accounting established.
- **RL-393/RL-394 remain OPEN:** PhaseΩ dependency omissions and failed-dependency continuation are not duplicated.
- **RL-449 remains OPEN:** REA outputs are simulation/proxy outputs, not empirical ecological evidence.
- No source code changed; no tests/builds/runtime boot/simulation/API/fault-injection/physical-device operations were run.

**Checkpoint 18.80 scope (completed in the following section):** trace exact route/controller entry points into RealityDirector and PhysicalDeploymentManager; audit topology evolution (ChannelEvolutionEngine) for atomic Graph updates and transfer-function preservation; inspect all Signal construction call sites and logical epoch propagation; determine whether REA can be booted through any normal production child path beyond PhaseΩ scan; inspect task supervisor restart/shutdown ownership and scheduler drop observability; and compare CEL service health callback semantics against BootSequencer's result handling. Assign RL-467+ only for independently supported, non-duplicate findings.


## Checkpoint 18.80 — causal topology mutation integrity and production reachability cross-check

**Basis:** frozen source `b829254d032f9e0b5cf4c44725c8cf451800dad0`. Read-only source inspection and bounded repository search. No tests, builds, runtime boot, simulation execution, API calls, fault injection, or physical operations were run.

### New finding

**RL-467 — OPEN — REA Graph re-registration duplicates source/target index entries and multiplies causal-channel effects.** `Tiannara.REA.Causal.Graph.handle_call({:register, ch}, ...)` replaces the channel in the canonical `channels` map by ID, but unconditionally prepends that ID to `by_target[ch.target.population]` and `by_source[ch.source.population]`. It does not remove an existing ID from either index or enforce uniqueness. Existing-channel updates therefore leave duplicate index entries. This is not merely a theoretical API misuse: `ChannelEvolutionEngine.apply_population_genomes/1` calls `Graph.register(updated)` for existing channels during the evolutionary loop (the UniversalEvolutionEngine invokes that engine every 100 epochs when a meta-genome population exists); `ReplacementRegistry.do_promote/2` also registers replacement channels and re-registers the original channel as disabled. Consequences in Graph are concrete: `incoming/1` and `outgoing/1` return repeated channel records; `handle_cast({:emit, sig}, ...)` iterates the duplicated source index and creates multiple in-flight deliveries for the same channel/signal; `collect_pressures/2` iterates duplicated target entries and sums the same channel's contribution multiple times, while overwriting the same history key. Repeated topology evolution can therefore amplify delivered pressure according to the number of re-registrations, even though `all/0` still returns one map entry per channel ID. This corrupts causal semantics and any downstream metrics derived from those pressures. **Closure:** make registration an idempotent upsert that removes prior index membership before applying the new endpoints, or derive indexes from the canonical channel map; enforce uniqueness and consistency invariants; test repeated same-ID updates, endpoint changes, enabled/disabled transitions, duplicate signal emission, pressure totals, and long-running evolution. Verify index cardinality equals the unique channel set after every mutation.

### Topology evolution and transfer-function refinement

- `ChannelEvolutionEngine.evolve/2` extracts every organism's `causal_genome`, but `apply_population_genomes/1` applies only `hd(genomes)`; the stated aggregate/dominant-genome decision is not implemented as aggregation or a documented selection policy. Organisms without a genome receive a fresh random genome via `CausalGenome.random/0`, so missing genome data can introduce unrecorded random topology parameters into the pass.
- Existing-channel evolution updates weight, delay, decay and enabled state but leaves `transfer_fn` unchanged. The Graph collector currently ignores `transfer_fn` and always uses `Channel.mean/1` (RL-463). Thus even if a channel's transfer function were preserved through mutation, runtime delivery does not honor it.
- Topological event records returned by `record_topological_changes/3` hard-code `epoch: 0` rather than the `epoch` argument. The returned list is not shown in the inspected UniversalEvolutionEngine caller being persisted or consumed.
- Replacement proposal evaluation compares the latest delivered-pressure observation for the proposed channel with the latest observation for the original channel; it does not establish a matched intervention/baseline window. The registry's `run_audit/1` is a placeholder returning `%{verdict: :grounded}`. These limitations reinforce the existing proxy/causal-evidence boundary (RL-449, RL-464); no duplicate finding assigned here.

### Production reachability and route trace refinement

- The main `Tiannara.Application.core_children/0` list does not include `Tiannara.REA.Supervisor`; its separate `register_subsystems/0` list also does not define REA. The REA supervisor's child list does not load `Topology.default/0`. The PhaseΩ WiringEngine does define REA, but the normal application path inspected does not call its Activator bootstrap; the bounded prior call-site trace located the Activator at the explicit `phase_omega_scan` task. This reinforces RL-462/RL-456: a declared supervisor/spec and a scanner reference do not establish normal production REA startup or topology initialization.
- The physical deployment test invokes `Tiannara.ASC.Reality.Director.deploy/3`, which calls `PhysicalDeploymentManager.plan/1` for a physical target. The inspected controller file exposes separate list/get operations against PhysicalDeploymentManager; this test is source-level integration coverage of the Director-to-manager call, not proof of a live externally reachable route, authenticated principal, or physical adapter.
- The main application starts `Tiannara.Meta.Hardware.Supervisor`, but the bounded repository search found no caller of `HorizonScheduler.route_payload/1` outside its own definition. The scheduler's saturation return/drop behavior therefore remains a source-level capability with no production dispatch route established in this pass (RL-461 lifecycle/drop accounting remains open).

### Status and next work

- **RL-467 OPEN.**
- **RL-465, RL-466 OPEN** from 18.79.
- **RL-462–464 OPEN**; topology mutation integrity now has an additional independent blocker (RL-467).
- **RL-461 OPEN:** no production scheduler caller was located in bounded search; dispatch/completion and saturation/drop accounting remain unproven.
- **RL-449 remains OPEN:** REA signal values and topology evaluation remain synthetic/proxy evidence, not empirical ecological or causal validation.
- No source code changed; no tests/builds/runtime boot/simulation/API/fault-injection/physical-device operations were run.

**Next checkpoint 18.81:** trace the complete Phoenix/API controller route set and authentication boundary into ASC RealityDirector and PhysicalDeploymentManager; inspect ChannelEvolutionEngine genome-selection and replacement promotion semantics against constitutional authority; trace every Graph mutation caller and define idempotent index invariants; inspect all REA signal producers for canonical epoch propagation and unit/range validation; and continue the CEL/PhaseΩ/main-application activation crosswalk. Assign RL-468+ only for independently supported, non-duplicate findings.


## Checkpoint 18.81 — physical deployment route semantics and REA topology governance

**Basis:** frozen source `b829254d032f9e0b5cf4c44725c8cf451800dad0`. Read-only source inspection and bounded repository search. No tests, builds, runtime boot, simulation execution, API calls, fault injection, or physical operations were run.

### New findings

**RL-468 — OPEN — REA replacement promotion activates a candidate before constitutional supersession succeeds.** `ReplacementRegistry.do_promote/2` first calls `Graph.register(p.proposed_channel)`, then calls `CausalConstitution.register_supersession/2`, then attempts `CausalConstitution.supersede/1`. The replacement is therefore inserted into the active causal Graph before the constitutional gate returns. If supersession fails, the error branch does nothing: it neither disables nor removes the candidate. The original channel is disabled only in the success branch. The constitution explicitly rejects constitutional-tier channels and requires structural-tier channels to reach their configured `supersession_window` (50 in `build_bounds/1)); the registry's own evaluation state is not passed as a proof of those wins. In addition, `run_audit/1` is a placeholder that unconditionally returns `%{verdict: :grounded}`, and the result of `register_supersession/2` is ignored. Consequently a proposal can be labelled promoted after the placeholder audit and leave its replacement channel active even when the constitution refuses supersession, with both old and new channels potentially enabled. **Closure:** perform evidence-backed audit and constitutional eligibility checks before any Graph mutation; require a verifiable supersession record tied to the exact replacement digest and completed evidence window; apply the Graph and constitution transition atomically or with compensating rollback; reject promotion if any registration/supersession operation fails; test constitutional, structural-insufficient-wins, missing-constitution and successful cases, asserting the active Graph state after each.

**RL-469 — OPEN — REA genome application registers novel causal channels without constitutional admission or mutation validation.** `ChannelEvolutionEngine.apply_population_genomes/1` validates mutations for an existing channel by calling `CausalConstitution.validate_mutation/2`, but registers every `dom.novel_proposals` entry directly with `Graph.register/1`. No matching constitution admission, tier assignment, bounds creation, provenance validation, or approval is performed in this path. The constitution's `validate_mutation/2` also returns `:ok` when a channel ID is absent from its constitution map, so an unknown channel is not fail-closed if that API is used as the only gate. A novel proposal can therefore enter the active Graph without an explicit constitutional classification or policy record. **Closure:** require new-channel admission to create and validate a constitutional profile before Graph registration; reject unknown channel IDs for governed mutations unless an explicit experimental-admission policy applies; bind channel identity, endpoints, signal type, transfer semantics and provenance to the admission record; test unknown IDs, each tier, malformed profiles and rejected novel proposals.

**RL-470 — OPEN — Phoenix physical-approval endpoint defaults unknown decision values to approval.** The router mounts `POST /api/v1/reality/physical/:id/approve` in the JSON-only `:api` pipeline. In `CRAVChallengeController.physical_approve/2`, missing decision defaults to `"approved"`; the case explicitly handles `"reject"`, `"abort"`, and `"emergency_stop"`, while every other value falls through to `PhysicalDeploymentManager.approve/3`. A misspelled, unsupported, or arbitrary decision string is therefore interpreted as approval rather than rejected. This is an independent fail-open input-validation defect, in addition to the existing authentication/identity and route-boundary findings RL-434/RL-439. The router's API pipeline itself only applies JSON content negotiation; no authentication plug is visible in this router. **Closure:** require an explicit enumerated decision; reject missing and unknown values with a client error; make approval a distinct explicit action, never a catch-all; test omitted, valid, invalid, case-variant and malicious decision strings. Authentication, actor authorization and approval-to-plan-digest binding remain separately required under existing findings.

### Route and governance refinements

- The complete Phoenix route set includes GET list/detail/adapter endpoints and POST plan/advance/approve/abort endpoints under `/api/v1/reality/physical`. The plan controller constructs a request-derived design and forwards it to `PhysicalDeploymentManager.plan/1`; advance forwards the deployment ID; approval derives decision, approver and note from request parameters; abort forwards a request-derived reason. This confirms the controller routes are mounted in source and strengthens RL-434/RL-439; it does not establish external network reachability or a live deployment.
- `physical_advance/2` does not itself provide actor identity or authorization context; the manager's stage machine checks the deployment stage and approval record, but the controller's `:api` pipeline contains no visible authentication plug. The manager stores the supplied approver string as approval metadata, not as proof of authenticated human identity. Existing RL-428/RL-434 remain controlling; no duplicate assigned.
- `ChannelEvolutionEngine` receives the logical simulation epoch, but its organism callback contract is `emit_signals(organism)` with no epoch argument. The four producers each call private `current_epoch/0` for signal timestamps, while the UniversalEvolutionEngine passes only the organism into `emit_signals/1`. This reinforces RL-465's producer/consumer epoch mismatch; no duplicate assigned.
- Existing-channel genome updates call `CausalConstitution.validate_mutation/2` before `Graph.register/1`, but the application chooses only `hd(genomes)` and silently ignores invalid mutation results. Novel proposals take a different, unvalidated direct-registration path (RL-469).
- The bounded search did not identify a normal main-application child or direct `REA.Supervisor.start_link/1` call. The main application and PhaseΩ activation findings remain as recorded in RL-462/RL-456; no claim is made that manual or out-of-band startup is impossible.

### Status and next work

- **RL-468, RL-469, RL-470 OPEN.**
- **RL-465, RL-466 OPEN** from 18.79.
- **RL-467 OPEN** from 18.80; duplicate Graph index membership remains a separate runtime-integrity defect.
- **RL-462–464 OPEN**; **RL-461 OPEN**.
- **RL-428/RL-434/RL-439 remain OPEN** for adapter trust, physical deployment authorization and Phoenix mutation-route protection; this checkpoint adds route-semantic refinements without treating them as closed.
- **RL-449 remains OPEN:** REA's causal outputs and topology evaluation are simulation/proxy evidence, not empirical ecological validation.
- No source code changed; no tests/builds/runtime boot/simulation/API/fault-injection/physical-device operations were run.

**Next checkpoint 18.82:** trace constitutional profile creation and enactment to determine whether any normal REA boot path establishes channel tiers before evolution; inspect all replacement-proposal producers and evidence-window updates (including whether structural wins can ever reach the required threshold); trace ASC physical route deployment/configuration and upstream middleware boundaries without assuming source routes are externally reachable; and audit REA organism metric units/ranges and the Graph's delayed-signal lifecycle after correcting the epoch contract. Assign RL-471+ only for independently supported, non-duplicate findings.
