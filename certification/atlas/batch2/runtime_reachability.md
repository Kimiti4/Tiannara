# Batch 2 — runtime reachability execution record

**Boundary:** D-ARC-005 (interim, `decisions_register.md:36`). The root application `:tiannara` and
`tiannara_runtime` remain separate releases/processes for this phase. Neither application was loaded into the
other's BEAM and no source trees were merged. This record does not resolve OP-01, OP-02, OP-03 or the 28 duplicate
module names.

**Base revision:** `8ff5ec83ce44049d764cca283578b41bb54724c7` (`local/pr4`, 2026-10-22).
**Code state tested:** base `8ff5ec83` plus the **uncommitted** working-tree changes listed below. There is not yet
a `source_code_revision` commit for this step. The code diff object is
`6d2cabdd6a2ba7fc473f3a9dd218cb823db03207` (SHA-256 of the diff file:
`1D983CC3913C1E8D8CDED9F6DB9A4EB6564A85ACBF2C3F5A8DB86818F16468DE`). The evidence below is therefore
**provisional** and does not close any finding under the Register 6 rule.

## Code changes exercised

| File | Change |
|---|---|
| `tiannara_runtime/lib/tiannara_runtime/application.ex` | Starts `TiannaraRuntime.MultiWorld.WorldSupervisor` as an optional child after the kill switch and before the execution controller. Starting the supervisor does not spawn a world. Also reads `:cpl_storage_path` and `:omega_storage_path` from application env and passes them to `StartupSupervisor` so test runs can redirect persistence writes. |
| `tiannara_runtime/lib/tiannara_runtime/multi_world/world_supervisor.ex` | Replaces the `DynamicSupervisor` callback module with a `GenServer` that owns a private named `DynamicSupervisor` (`...WorldSupervisor.Dynamics`), records `world_id -> pid`, and handles `{:kill_world, ...}`. `find_world_pid/1` previously returned the first child regardless of `world_id`; lookup is now keyed by `world_id`. |
| `tiannara_runtime/lib/tiannara_runtime/multi_world/kill_switch.ex` | Replaces `Task.async/1` with detached `Task.start/1` in the request path so Task result/`:DOWN` mail no longer arrives at the GenServer as unexpected messages. |
| `tiannara_runtime/test/multi_world/kill_switch_activation_test.exs` | Adds an end-to-end regression test: start a supervised probe world through `WorldSupervisor.start_child/2`, request termination through `KillSwitch.request_termination/3`, assert the child stops, assert the kill is reported in `get_killed_worlds/0`, repeat for recovery, and assert the supervisor remains alive. |
| `tiannara_runtime/config/test.exs` | Redirects CPL, Omega executive-memory, Mnesia, and the `forward_provenance` identity-authority ledger into a timestamped `_build/test/tmp/<run>` directory, so test runs no longer write into the repository `data/` tree or `Mnesia.nonode@nohost`. |
| `tiannara_runtime/test/opc_execution_runtime_instrumentation_test.exs` | After its per-test ledger path is removed, restores the configured test ledger path instead of deleting the env and falling back to `data/identity_authority_ledger.jsonl`. |

File SHA-256 values:

| File | SHA-256 |
|---|---|
| `application.ex` | `60A37E05523B04A7C149AC0F50BAD36AA3AB9497B1DDD17D851B089C4B56BB17` |
| `world_supervisor.ex` | `146EBF16EA9687FE3C43B3A5789B3693B7CD3769633A801F4D25AE7FC044CFE6` |
| `kill_switch.ex` | `AAAD0C69582981977D32D2D6739311FFB9266D525E1B4645281A608560BCDDE2` |
| `kill_switch_activation_test.exs` | `0AF13FE338EFE6742B6C154209940D3C0362D07CE3EB956DEC2FB84A15DDA495` |
| `config/test.exs` | `0792086D99A18369261A1F64908FA8101ED526DFAC52284E3396D94E1DF96AF6` |
| `opc_execution_runtime_instrumentation_test.exs` | `DB5072B85C9F0E9F767C54D05B28FA4C384A2BA3F1E7174FDEAD90DCA5A82D9B` |

## Step 2 — isolated safe-mode boot

**Command shape (from `tiannara_runtime/`, `MIX_ENV=dev`):**

```powershell
mix run --no-start <isolated harness>
```

The harness changes CWD to a scratch directory, creates `_build` there (PropCheck requires `_build/propcheck.ctex`
relative to CWD), points `:mnesia` at scratch, sets `:cpl_storage_path` to scratch, sets `boot_profile: :minimal`,
then calls `Application.ensure_all_started(:tiannara_runtime)`.

**Run 3 (pre-supervisor-fix baseline):** `app_start {:ok, [... :tiannara_runtime]}`; `startup_status` all true
(`runtime`, `supervisor`, `cpl`, `omega`, `cop`); `all_running` true; top supervisor alive; CIS, KillSwitch,
ExecutionController and QuotaGovernor alive; `world_supervisor_alive: false` at that revision; Endpoint alive on
8004; boot profile `:minimal`; CIS mode `:normal` -> `:lockdown`; `authorize_kill` = `:deny`; `execute_kill` =
`:denied`; CPL events written under the scratch directory. **Evidence:**
`certification/atlas/batch2/evidence/safe_boot_run3.txt` SHA-256
`B30CC0D45B84B015EB69958006AD6876ACC4D27F74FCC89BAC54E938B8E24BAA`.

**Run 7 (final source, after the world-supervisor fix and CPL/Omega storage-path plumbing):** all-true startup
status (`runtime`, `supervisor`, `cpl`, `omega`, `cop`); top supervisor alive; `world_supervisor_alive: true`;
`authorize_kill` `:deny` and `execute_kill` `:denied` under lockdown; the report lists 27 CPL event files under the
scratch `data/cpl/events` directory and the repository `data/` tree was not touched. **Evidence:**
`certification/atlas/batch2/evidence/safe_boot_run7.txt` SHA-256
`44FB1BC759AA92AF6CCC55079D011DAB014EEBD5F99281C2950D50923C71B7AF`. Run 6 (SHA-256
`6EC215CA6AE8DECAB4D409805EE96CAAB205EA5CBA72012065CB456A341E6CDC`) was the first all-true boot after the
world-supervisor/CPL fix; run 7 supersedes it for the final code state.

**Known limitation:** run 1 (before `--no-start` was used) started the app in the project CWD and wrote 24 CPL
event files into `tiannara_runtime/data/cpl/events`; those 24 new files were deleted, but the run also touched
`tiannara_runtime/Mnesia.nonode@nohost/{DECISION_TAB.LOG,LATEST.LOG}`. The Mnesia log changes cannot be restored.
Run 2 failed before boot because PropCheck could not create `_build/propcheck.ctex` under the scratch CWD.

## Step 3 — kill-switch execution before ordinary world execution

### Before the change

`WorldSupervisor` was not in the boot tree. A direct `ExecutionController.execute_kill("probe-world-before", ...,
:critical)` returned `:executed`, but the log said:

`CIS.ExecutionController WorldSupervisor not registered — termination command NOT delivered`

No child could be stopped; the switch could only report an attempted execution.

**Evidence:** `certification/atlas/batch2/evidence/kill_chain_before.txt`
SHA-256 `A3D778B1ABCD425596879E7D0C2F9F588A7F7D1D4646DD18EFA110826229DEC7`.

### A defect exposed by the first after-run

Simply starting `WorldSupervisor` was not sufficient. Its callback module used `use DynamicSupervisor` and defined
`handle_info/2` clauses, but `DynamicSupervisor` only calls the callback module's `init/1`; the custom
`handle_info/2` clauses are dead. Every delivered kill message was logged as:

`DynamicSupervisor received unexpected message: {:kill_world, ...}`

The kill was reported as delivered and recorded in `killed_worlds`, but the supervised child stayed alive. The
lookup also ignored `world_id` and would have killed the first child. This is part of F-ARC-240: the delivery edge
was unreachable even after the supervisor was started.

The final code wraps a private `DynamicSupervisor` in a `GenServer`, records `world_id -> pid` on
`start_child/2`, and handles run through the canonical `KillSwitch -> ExecutionController -> CIS.Supervisor ->
WorldSupervisor` path.

### After the change

Two consecutive attempts through `KillSwitch.request_termination/3`, each with a newly supervised probe world:

- attempt 1: child start `{:ok, pid}`, request `:requested`, child stopped `true`, kill record `:killed`,
  `killed_worlds ["probe-world-1"]`, supervisor alive after `true`;
- attempt 2: child start `{:ok, pid}`, request `:requested`, child stopped `true`, kill record `:killed`,
  `killed_worlds ["probe-world-1", "probe-world-2"]`, supervisor alive after `true`;
- final `WorldSupervisor` and `KillSwitch` both alive; `StartupSupervisor.all_running?` true.

**Evidence:** `certification/atlas/batch2/evidence/kill_chain_after.txt`
SHA-256 `34091080B1BE8266087771DBA03FE7D412FAC9D1453FE214A43137FB19A8704C`.

**Repository regression test:** `mix test test/multi_world/kill_switch_activation_test.exs` (MIX_ENV=test) ->
**8 tests, 0 failures**, including the new end-to-end termination test. **Evidence (pre-isolation run):**
`certification/atlas/batch2/evidence/kill_switch_activation_test.log`, SHA-256
`C811AC3B99934831F60FA2779659274B69D34B5E5538765462C401ACF6E7B09B`.

**Isolated rerun:** after the storage-path/test-config change, the expanded suite passed **9 tests, 0 failures** with
zero new `data/cpl`, `data/omega`, or `Mnesia.nonode@nohost` writes in the repository. The added test starts a target
world and an unrelated bystander world, kills the target through the canonical chain, asserts the bystander is still
alive and absent from `killed_worlds`, then kills the bystander to prove recovery. **Evidence:**
`certification/atlas/batch2/evidence/kill_switch_activation_test_isolated.log`, SHA-256
`DB7EB3BAC06701585154324D8627DC3EFA7E9E492FE70C91B8A56F7C42736F94`.

**Artifact limitation of the pre-isolation run:** the runtime test suite had no CPL/Omega/Mnesia isolation
(launch-boundary B4 / F-ARC-018). The test run wrote 38 CPL event files into `tiannara_runtime/data/cpl/events`; 6
were newly created and were deleted, and 32 pre-existing untracked event files were overwritten (their original
contents cannot be restored). The run also recreated
`tiannara_runtime/Mnesia.nonode@nohost/{DECISION_TAB.LOG,LATEST.LOG}`. This is recorded as an isolation incident,
not as an intentional artifact change.

**Isolation remediation:** `config/test.exs` now directs CPL, Omega executive memory, Mnesia, and the
`forward_provenance` identity-authority ledger to a timestamped directory under `_build/test/tmp`;
`application.ex` passes `:cpl_storage_path` and `:omega_storage_path` through to the startup supervisor. The first
isolated full-suite attempt still appended two records to `data/identity_authority_ledger.jsonl` at 09:40 because the
OPC instrumentation test deleted its ledger env on exit; that test now restores the configured test path. The final
isolated full runtime suite (Step 5) made **zero** CPL, Omega, Mnesia, or identity-ledger writes. The overwritten CPL
files, the pre-existing `data/omega/executive_memory/snapshot.etf` (written by the earlier non-isolated full-suite
attempt at 08:19:40), and the identity-ledger records appended by the first isolated attempt were left untouched,
not restored or deleted.

## Step 4 — integration edges

All checks were run from the isolated scratch boot. **Evidence:**
`certification/atlas/batch2/evidence/edge_probe.txt`, SHA-256
`92FB496BEC630A83E0152DD12AAC71D5420BBB0B274E70F99BBA9FFE7A5F848B`.

| Edge | Observation | Finding |
|---|---|---|
| Status endpoint | `GET /api/v1/health` -> 200 with all five systems true; `GET /api/v1/system/status` -> 200, `overall_health: HEALTHY`; `GET /api/v1/cpl/stats` -> 200, `cpl_alive: true` | Runtime status reports its own boot tree only. |
| Kubernetes probes | `GET /health/live` -> 404; `GET /health/ready` -> 404; `/health/startup` was not implemented either | The declared k8s probes do not match `TiannaraRuntimeWeb.Router`; F-ARC-229/open deployment edge. |
| NATS listener conflict | With a dummy listener occupying 4222 before boot, the app still booted (`all_running: true`); `NATS.Connection.get_status` returned `%{connected: false, listen_socket: nil, port: 4222}` | Confirms launch-boundary U-B2-2: binding failure is a warning plus silent degradation, not fail-closed. F-ARC-228 remains open. |
| Event gateway | `TiannaraRuntime.EventGateway` was `:not_running`; the module is not in the boot tree and its private `connect_nats/0` is hard-coded to `{:error, :unavailable}` | F-ARC-228: there is no real NATS event-transport edge. The Observability stream processor logged "NATS unavailable ... degraded local-buffer mode" and repeated reconnection attempts. |
| Runtime -> Python observatory | `tiannara_runtime/lib/tiannara_runtime/ecology/universe_server.ex:283` posts telemetry to `http://localhost:8004/api/v1/meta-ecology/ingest`. The Python route exists at `tiannara_api/routes/meta_ecology.py:31`, but the runtime's own dev endpoint also binds 8004, so the POST hit the runtime router and returned 404 (`Phoenix.Router.NoRouteError`). | The runtime-to-Python telemetry edge is real in intent but unreachable under the current port ownership. This is a concrete F-ARC-228/F-ARC-229 boundary issue; it is recorded in D-ARC-017 rather than assigned a new finding id. |
| ControlCenter ownership | `Tiannara.ControlCenter` exists only in the root project (`lib/tiannara/control_center.ex`, started by `Tiannara.Operations.OperationsSupervisor`). The runtime has no ControlCenter module or child, and `/api/v1/system/status` does not claim one. | F-ARC-235 disposition: ControlCenter is a root `:tiannara` authority, not a runtime authority under D-ARC-005. A Register-7 decision is still required to record that disposition; no runtime boot change is made here. |
| Prod config / release | `Test-Path tiannara_runtime/config/prod.exs` -> `False`; `MIX_ENV=prod mix compile` -> `File.Error ... config/prod.exs: no such file or directory`; `tiannara_runtime/mix.exs` has no `releases/0`; `_build` has no `prod` | F-ARC-014 and F-ARC-229 remain open. **Evidence:** `certification/atlas/batch2/evidence/prod_compile.log`, SHA-256 `0A5F20A07E17C7FB319FEF01D5B69141489E6238D3BB8F2F135364F11F44FA0E`. |

## Step 5 — test isolation and suite validation

Evidence `.log` files were normalized from PowerShell's UTF-16LE-with-BOM capture to UTF-8 without BOM so they are
reviewable in git; their text content is unchanged. The SHA-256 values below are for the committed UTF-8 files.

- `MIX_ENV=test mix test --no-compile --exclude quarantine` (runtime, full suite): **40 properties, 1863 tests, 0
  failures, 6 excluded**, finished in 479.5 seconds. **Evidence:**
  `certification/atlas/batch2/evidence/runtime_full_suite.log`, SHA-256
  `78126BD1C4549D0EA32833509A5DBC493105EA5A62EE29908AE64E5B86C4B115`.
- Repository writes during that run: `data/cpl` recent files = 0, `data/omega` recent files = 0,
  `Mnesia.nonode@nohost` recent files = 0, and the identity-authority ledger mtime/size were unchanged.
- `opc_execution_runtime_instrumentation_test.exs` passed **3 tests, 0 failures** with its per-test ledger redirected
  to a temporary path and the configured test ledger path restored on exit; the repository ledger was unchanged.
  **Evidence:** `certification/atlas/batch2/evidence/opc_ledger_isolation.log`, SHA-256
  `F4D0C7668A1F366EC5FD21E2B4470F88C3756D77C7C1C733C123DCCEC3C39911`.
- `AuthorizationContractTest` (the test that timed out during the first, interrupted full-suite attempt) passed
  **12 tests, 0 failures** in isolation. **Evidence:**
  `certification/atlas/batch2/evidence/authorization_contract_test.log`, SHA-256
  `CA7D993F2FB7B03BAF592A185AF930B5CAA37AE67FB9A28A75E9D713D39B33A1`. The earlier timeout is not treated as
  evidence of a code failure because it did not reproduce in isolation and the first run was interrupted.
- The first full-suite attempt is not used as evidence: it was interrupted after a 30-second `ExUnit.TimeoutError`
  in `AuthorizationContractTest` and the shell/VM continued for hours. A second full-suite attempt passed but
  appended two identity-ledger records before ledger isolation was complete; the final run above supersedes both.

## Findings status after this pass

| Finding | Status | Basis |
|---|---|---|
| **F-ARC-240** | `FIXED_PENDING_VERIFICATION` — not closed | Kill switch now starts the world supervisor, the delivery callback is live, two supervised children were stopped through the canonical chain, and the isolated regression suite passes (9/0), including an unrelated-world survivor check and a recovery kill. The full runtime suite passes (1863 tests, 0 failures). The changes are uncommitted and have not been run in CI; no exact `source_code_revision` or CI run exists yet. |
| F-ARC-234 (`WorldProcess` only in Markdown) | OPEN | No `WorldProcess` module was added; the probe uses a supervised test child. Normal world spawning remains unimplemented. |
| F-ARC-226 (launcher never starts runtime) | OPEN / partially evidenced | The app can be started in an isolated dev boot, but no tracked launcher, release, Compose service or CI boot job starts it. |
| F-ARC-228 (event transport) | OPEN | NATS listener degrades silently when 4222 is occupied; `EventGateway` is not started and hard-codes `:unavailable`; runtime telemetry to the Python observatory collides on 8004. |
| F-ARC-235 (ControlCenter) | OPEN / disposition recorded | Root-only authority; Register-7 decision still outstanding. |
| F-ARC-014 / F-ARC-229 (prod config/release) | OPEN | Runtime prod config is absent; prod compile fails; no release definition or CI artifact. |
| F-ARC-018 / launch-boundary B4 (persistence and state hygiene) | **OPEN** — test isolation only partial mitigation | `config/test.exs` redirects CPL, Omega, Mnesia, and the identity-authority ledger to `_build/test/tmp`; targeted and final full runtime suites made zero repository writes in those stores. This does **not** satisfy F-ARC-018's broader acceptance criteria: configurable Python store paths, a merged store-ownership map, and clean-checkout persistence requirements remain outstanding. The pre-isolation incident (32 overwritten CPL files, Mnesia logs, `data/omega` snapshot) and the first isolated suite's two identity-ledger appends remain recorded. |
| F-ARC-227 (observatory mock fallback) | NOT CHECKED | Outside this pass. |
| F-GOV-025 | OPEN, unchanged | No privileged effect was enabled; the kill test used a temporary supervised probe child only. |

## What this pass did not do

- It did not commit or push anything, so the evidence is not yet boundary-bound to a `source_code_revision`.
- It ran the full runtime suite in isolation but did not run the root `:tiannara` suite or a CI job; the evidence
  remains provisional until both are bound to a commit. The pre-isolation artifact incident is recorded and not
  repaired.
- It did not fix `WorldProcess`, NATS transport, the Python observatory path, production config/release, or
  ControlCenter ownership.
- It did not enable normal world execution. `WorldSupervisor` is started with no worlds; the only child used was a
  test probe.
