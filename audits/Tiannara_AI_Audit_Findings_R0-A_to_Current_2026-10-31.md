# Tiannara AI — Consolidated Audit Findings

**Coverage:** R0-A through resource-lifecycle checkpoint 5 (restart, crash recovery, persistence, registry reconciliation)  
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
