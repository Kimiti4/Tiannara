# Checkpoint 18.96 — System Ownership and Production Authority Audit

**Repository:** `Kimiti4/Tiannara`  
**Audited source ref:** `b829254d032f9e0b5cf4c44725c8cf451800dad0` (`main`)  
**Audit branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Method:** Static source inspection through GitHub repository files and code search  
**Code changes:** None  
**Builds/tests/runtime execution:** Not performed

## 1. Objective

Establish, independently, (1) whether a module is a stub or substantive implementation, (2) which implementation production consumers resolve to, and (3) whether the candidate is started and integrated. Directory names and implementation-looking filenames are not sufficient evidence of production authority.

This checkpoint is a focused first pass over the four high-risk integrations and the stub registry identified in the preceding audit. It is not a complete audit of every system in the inventory.

## 2. Findings confirmed against the audited source ref

### CP18.96-F01 — StubRegistry has no established startup owner

**Classification:** `UNCONNECTED`  
**Priority:** High

Evidence:
- `lib/tiannara/stubs/stub_registry.ex` defines a GenServer and `start_link/1`.
- `lib/tiannara/stubs/stub.ex` records calls only when `Process.whereis(Tiannara.StubRegistry)` is non-nil. If it is absent, calls are skipped; no failure is raised and no alternative durable telemetry path is established in this macro.
- The root application's declared `core_children/0` list in `lib/tiannara/application.ex` does not include `Tiannara.StubRegistry`.
- The runtime application's direct startup path is `TiannaraRuntime.Application` → `TiannaraRuntime.StartupSupervisor`. The latter's declared children are CPL, Omega, COP, endpoint, RootSupervisor and DiscoveryRunner; it does not include StubRegistry.
- Repository code search found the module definition and macro reference, but no application startup invocation for `Tiannara.StubRegistry.start_link/1`.

**Conclusion:** The registry implementation exists, but the inspected startup graphs do not establish it as an active supervised service. Stub call tracking must be treated as unverified/unavailable unless another startup path is found. A GenServer module existing in source is not evidence it is running.

### CP18.96-F02 — Stage-6 scientific capital resolves to a stub with a tuple/number contract mismatch

**Classification:** `ACTIVE_STUB`  
**Priority:** Critical

Evidence:
- `lib/tiannara/os/recursive_civilization_runner.ex` calls `TiannaraOS.ScientificCapitalLedger.calculate_delta(policy, transactions)`.
- `lib/tiannara/stubs/os_scientific_capital_ledger.ex` defines that exact module identity and returns `{:ok, 0}`.
- The runner then evaluates `previous_capital + delta_capital`, where `previous_capital` is numeric. The stub's tuple return is not a numeric delta and will raise a type error if this execution path is reached.
- A separate substantive candidate exists at `lib/tiannara/os/kernel/scientific_capital_ledger.ex`, defining `TiannaraOS.Kernel.ScientificCapitalLedger`. That is a different module identity and is not the module called by the runner at this call site.

**Conclusion:** The substantive candidate does not currently establish production ownership for the Stage-6 call. The runner is wired to the stub identity. The return-contract mismatch is a deterministic defect in the inspected path; runtime reproduction was not performed.

### CP18.96-F03 — Stage-6 GenerationHistory writes are stubbed; CAI is also stubbed

**Classification:** `ACTIVE_STUB`  
**Priority:** Critical

Evidence:
- `lib/tiannara/os/recursive_civilization_runner.ex` calls `GenerationHistory.append_to_file(history, csv_path)`.
- `lib/tiannara/stubs/generation_history.ex` defines the global `GenerationHistory` module. Its `append_to_file/2` delegates to `stub_result/3` with default `:ok`; it does not write the CSV.
- The same stub's `calculate_cai/1` returns fixed `0.0`, so Stage-6 CAI output is not calculated by the substantive implementation at this call site.
- A substantive module exists at `lib/tiannara/os/kernel/generation_history.ex`, under the distinct identity `TiannaraOS.Kernel.GenerationHistory`. Its source contains a real `append_to_file/2` implementation (directory creation and file-writing path), but the runner's unqualified `GenerationHistory` call resolves to the global stub module, not this namespaced candidate.
- The stub's `new/1` evaluates the namespaced candidate's `new/1` as its default argument, but that does not make `calculate_cai/1` or `append_to_file/2` production-backed.

**Conclusion:** The Stage-6 history persistence and CAI consumers remain wired to stub behavior. A successful `:ok` return is not evidence that a record was persisted.

### CP18.96-F04 — ASC Crucible can be marked complete without Crucible verification

**Classification:** `ACTIVE_STUB`  
**Priority:** Critical

Evidence:
- `lib/tiannara/asc/pipeline/phases.ex` maps `:crucible` to `Tiannara.ASC.Crucible.Supervisor`.
- `lib/tiannara/stubs/crucible_supervisor.ex` defines that exact module identity; `run/1` returns `{:ok, :stub}`.
- `lib/tiannara/asc/pipeline/worker.ex` treats `{:ok, :stub}` as a successful phase result and schedules the next phase.
- `lib/tiannara/asc/sub_civ/supervisor.ex` has the Crucible supervisor child commented out with the explicit TODO to create it.
- The worker also returns `{:ok, :stub}` from its generic fallback when a phase handler is missing, so absence of a handler can also advance the pipeline.

**Conclusion:** The pipeline's current success semantics permit a project to pass the Crucible phase without verification. The real Crucible supervisor is not established in the inspected sub-civilization supervision tree.

### CP18.96-F05 — CTL BranchValidator is bound to a stub; uppercase candidate is not contract-compatible

**Classification:** `ACTIVE_STUB` for the consumer path; `PARTIAL_IMPLEMENTATION` for the alternate candidate  
**Priority:** High

Evidence:
- `lib/tiannara/ctl/branch_validator.ex` aliases `Tiannara.Ctl.CausalRegistry` and invokes `get_branch/1`.
- `lib/tiannara/stubs/causal_registry.ex` defines that exact module identity and returns `{:ok, %{stress: 0.0}}` for every branch ID.
- `lib/tiannara/ctl/causal_registry.ex` defines a different module identity: `Tiannara.CTL.CausalRegistry` (uppercase `CTL`). It has supervisor scaffolding, an empty child list, a no-op `register_branch/2`, and a mocked `get_active_branches/0` returning 10,000. It does not implement the consumer-required `get_branch/1` contract.
- The consumer therefore does not resolve to the uppercase candidate, and that candidate cannot satisfy the current validator interface.

**Conclusion:** Branch validation currently accepts synthetic zero-stress records through the active stub. The alternate module is incomplete and is not a valid drop-in replacement.

## 3. Ownership register — focused systems

| Capability | Consumer-resolved module | Alternate candidate | Current classification | Operational conclusion |
|---|---|---|---|---|
| Stub call registry | `Tiannara.StubRegistry` | Same module | `UNCONNECTED` | Startup not established; call recording is conditional |
| Scientific capital (Stage 6) | `TiannaraOS.ScientificCapitalLedger` | `TiannaraOS.Kernel.ScientificCapitalLedger` | `ACTIVE_STUB` | Wrong module identity and tuple/number mismatch |
| Generation history (Stage 6) | `GenerationHistory` | `TiannaraOS.Kernel.GenerationHistory` | `ACTIVE_STUB` | CSV append and CAI calls are stubbed |
| ASC Crucible | `Tiannara.ASC.Crucible.Supervisor` | No verified production supervisor | `ACTIVE_STUB` | Pipeline advances on stub success |
| CTL causal registry | `Tiannara.Ctl.CausalRegistry` | `Tiannara.CTL.CausalRegistry` | `ACTIVE_STUB` / `PARTIAL_IMPLEMENTATION` | Active consumer gets zero-stress stub; alternate lacks required API |

## 4. Corrections and precision notes to the preceding checkpoint

1. The Stage-6 capital issue is more specific than a generic namespace mismatch: the exact module called by the runner is the stub `TiannaraOS.ScientificCapitalLedger`, and its `{:ok, 0}` return is then used as a number. This is a direct type-contract failure.
2. The Stage-6 history stub does more than falsely report persistence: its `calculate_cai/1` also returns a fixed zero. These are separate stubbed capabilities under the same module.
3. The CTL alternate candidate is not simply a production implementation with different capitalization. It has no `get_branch/1`, no branch storage, and a mocked active-branch count.
4. StubRegistry's lack of startup wiring means absence of recorded calls cannot be interpreted as evidence that a stub was unused.

## 5. Evidence limits

- The audit is static. No Elixir compilation, unit/integration tests, application boot, process inspection, or runtime call tracing was executed.
- Search and file inspection were performed against source ref `b829254d032f9e0b5cf4c44725c8cf451800dad0`. Runtime behavior and deployment configuration remain to be tested.
- This is a focused checkpoint, not completion of the full inventory-wide ownership register.
- No implementation has been selected for consolidation or retirement. That decision requires contract mapping, dependency/caller enumeration, startup evidence, persistence/recovery review, and independent tests.
- The two Elixir applications must remain separate audit subjects until their actual deployment and process topology is proven. A module's presence in one application's tree does not prove it is active in the other.

## 6. Required next verification work

1. Enumerate every reference to the five module identities above, including dynamic module resolution and configuration-driven calls.
2. Trace all startup paths from each OTP application entry point through nested supervisors; establish whether the root app, runtime app, or both are deployed in the target topology.
3. Inspect and compare the full contracts and persistence semantics of the substantive scientific-capital and generation-history candidates.
4. Build an explicit phase-completion contract for ASC: only independently evidenced Crucible verification may permit transition to `:api_evolution`; missing handlers and stub results must fail closed or remain `UNKNOWN`.
5. Trace CTL branch registration, storage, lookup, and validation consumers; do not replace the stub with the uppercase candidate until the required contract and real state ownership exist.
6. Add boot-level tests proving StubRegistry supervision and call capture, plus consumer-level tests that reject the present stub outputs.
7. Extend this same evidence model across all duplicated systems in the inventory; classify each as `CANONICAL_PRODUCTION`, `PRODUCTION_CANDIDATE`, `ACTIVE_STUB`, `PARTIAL_IMPLEMENTATION`, `LEGACY_IMPLEMENTATION`, `DUPLICATE_AUTHORITY`, `UNCONNECTED`, or `UNKNOWN`.

**Checkpoint disposition:** `OPEN — STATIC FINDINGS CONFIRMED; RUNTIME VERIFICATION PENDING`. No production code was changed.
