# Closure record — R1/Batch 1 step 4 (supporting fix) — F-ARC-239 (runtime bridge test isolation)

| Field | Value |
|---|---|
| **Finding ID** | **F-ARC-239** (new; surfaced by CI on the step-2 commit `11404ac9`) — the required `tiannara_runtime suite` job failed with `Tiannara.BridgeTest` "multiple ticks maintain bounded values": `{:ok, pid} = OmegaPhiKernel.start_link([])` failed with `{:error, {:already_started, #PID<0.9346.0>}}`. |
| **Baseline and candidate SHA** | Baseline: `11404ac9` (CI run `39658874815`, required job failed with this test). Candidate: the commit carrying this record. |
| **Changed implementation** | `tiannara_runtime/lib/tiannara_runtime/bridge/omega_phi_kernel.ex` — `start_link/1` now accepts an optional `:name`, defaulting to the module name. The production behaviour is unchanged (the application still starts the kernel under its registered name via `tiannara_runtime/lib/tiannara_runtime/bridge/supervisor.ex:25`). `tiannara_runtime/test/bridge_test.exs` — the three tests that started the kernel directly now start an **isolated** instance under a unique name through a `start_isolated_kernel/0` helper. |
| **Authority owner** | `TiannaraRuntime.Bridge.OmegaPhiKernel` (runtime project) owns the kernel; the test owns its isolation. |
| **Affected consumers** | The kernel's production child spec (unchanged behaviour); the three `OmegaPhiKernel` tests in `tiannara_runtime/test/bridge_test.exs`; the required CI job `tiannara_runtime suite (required)`. |
| **Before/after test evidence** | **Before:** the required CI job at `11404ac9` (run `39658874815`) failed with exactly this assertion — `** (MatchError) no match of right hand side value: {:error, {:already_started, #PID<0.9346.0>}}` at `test/bridge_test.exs:63`. The defect is a **race**: the module registers a global name, the application starts the same kernel, and the test starts it a second time; whether the test sees `{:ok, pid}` or `{:already_started, pid}` depends on which concurrent test module started the kernel first, which is why the required job was green on the preceding commits and red on this one. The test passes in isolation both before and after the fix, so isolation runs alone are not evidence for this defect. **After:** the same file passes 3/3 in isolation, and the required job is verified by the CI run recorded in `certification/atlas/verification_r1.md`. |
| **CI and execution evidence** | The required runtime job is the check that matters; the run id for the candidate commit is recorded in `certification/atlas/verification_r1.md`. Local: `mix test test/bridge_test.exs` (runtime project) → 31 tests, 0 failures, 3 consecutive runs. |
| **Atlas update** | `findings_ledger.csv`: new row **F-ARC-239** (status `FIXED_PENDING_VERIFICATION`) with the evidence and the acceptance criteria; `capability_register.csv`: CAP-PLT-010 (deployment/CI) annotated — no evidence-state promotion, because the runtime suite still has to be observed green on the candidate SHA. |
| **Closure status** | **FIXED_PENDING_VERIFICATION** — pending the required CI job on the candidate commit. |

## Scope note

This is **not** part of the governance cluster and is not a Batch 1 governance change. It is recorded separately
because the required CI job is the evidence channel for every Batch 1 closure record: a required job that fails for an
unrelated reason would make the governance evidence unobtainable. The change is deliberately minimal and does not
touch the kernel's behaviour, its supervision, or any assertion in the test.

**Residual:** the runtime suite contains other timing-sensitive tests (the crash-injection file F-ARC-238); the
general problem — tests that assume a globally named process is not running — is recorded as part of F-ARC-239's
scope for a later pass.
