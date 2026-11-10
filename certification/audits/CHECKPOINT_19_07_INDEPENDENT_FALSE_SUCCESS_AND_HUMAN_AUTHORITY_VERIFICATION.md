# Checkpoint 19.07 — Independent Verification of False-Success Paths and Human-Authority Enforcement

**Date:** 2026-11-10  
**Repository:** `Kimiti4/Tiannara`  
**Branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Audit branch head at start:** `3c7e25537204c9f151c40b5f2859e199708a0883`  
**Source baseline:** `07b1a6b4e9871b297386595982683ee9512b8725`  
**Source tree:** `17d9d632aebcd130e7a5deb46451c44dc9c47524`  
**Prior report:** `certification/audits/CHECKPOINT_19_06_EXHAUSTIVE_IMPLEMENTATION_BODY_STUB_AND_FALSE_SUCCESS_AUDIT.md`  
**Status:** `PARTIAL_EVIDENCE — OPEN`  
**Mode:** Read-only independent static verification and negative-test specification.

---

## 1. Executive disposition

This checkpoint independently re-fetched the seven findings' cited implementation bodies at the pinned source baseline and traced selected callers, test coverage and startup ownership.

**Result:** the two critical source-level defects RL-558 and RL-562 are independently confirmed. Their source paths are root-application-startup-backed. Neither was dynamically executed, and neither finding is closed.

The other five findings were also rechecked at source level. Their implementation defects are confirmed to the extent stated below, but release/deployment reachability or downstream decision consumption remains unknown where not demonstrated.

No production code, tests, runtime configuration, state, deployment manifests or governance authority were changed. No build, test suite, runtime boot, endpoint request, model export, simulation, physical actuation or CI workflow was executed.

This is a targeted independent verification, not a claim that every consumer or deployment route has been enumerated.

## 2. Evidence baseline and method

The audit branch currently points to `3c7e25537204c9f151c40b5f2859e199708a0883`. That branch-head commit's parent is the 19.06 report commit `95cf9e40dd9e437848d09b5332c758885088798c`.

Checkpoint 19.06 identifies source baseline `07b1a6b4e9871b297386595982683ee9512b8725` and tree `17d9d632aebcd130e7a5deb46451c44dc9c47524`. All source bodies listed in this report were fetched using that exact source baseline, not inferred from default-branch search results.

Evidence classes used:
- `SOURCE_CONFIRMED`: implementation behavior is directly visible in the pinned source.
- `STARTUP_PATH_CONFIRMED`: static application/supervisor composition starts the relevant process.
- `TEST_GAP_CONFIRMED`: checked-in tests do not exercise the identified negative case.
- `RELEASE_OR_EXTERNAL_REACHABILITY_UNKNOWN`: deployment/runtime ingress or downstream consumer was not established.
- `NOT_EXECUTED`: no dynamic test or runtime observation was performed.

## 3. Independent verification matrix

| Finding | Source-level result | Startup / ingress result | Test / runtime result | Disposition |
|---|---|---|---|---|
| RL-557 | Fixed providers and constant collector values re-confirmed | Runtime Observatory release/consumer path not independently established | No telemetry run | OPEN; source defect confirmed, deployed reachability UNKNOWN |
| RL-558 | Invalid impact levels fall through to `:approved`; constructor accepts them | Root application → OperationsSupervisor → ControlCenter → ReviewRouter startup path confirmed | Existing tests cover valid levels only; no invalid-level test; no runtime test | OPEN; CRITICAL source and startup path confirmed |
| RL-559 | ReviewRequest is constructed then discarded; rescue returns `:ok` | ToolForge is included only when ASC is enabled; application default is disabled | Existing ToolForge integration test treats pipeline success as expected and does not assert a human decision; no runtime test | OPEN; false-success path confirmed, feature-flag gated |
| RL-560 | Random/sample dashboard, insight and prediction data plus static active capabilities re-confirmed | FastAPI main imports analytics-insights router; exact include-router mount is statically present | No HTTP request or deployed API test | OPEN; mounted source path confirmed, deployment reachability UNKNOWN |
| RL-561 | Exporter emits Identity placeholder; validator initializes accuracy to 100.0 and original function is optional | Production model-export ingress not established | No export/inference test run | OPEN; generic semantic defect confirmed, production consumer UNKNOWN |
| RL-562 | ControlCenter supplies hard-coded zero violation/review counts and fixed score; auditor treats missing counters as zero | Root application → OperationsSupervisor → ControlCenter; scheduled audit path confirmed | No auditor test or runtime audit execution found in the inspected test set | OPEN; CRITICAL source and startup path confirmed |
| RL-563 | Selected child processes initialize counters and only answer status calls | Root application starts Physics, Stabilization and Topology supervisors; nested Physics supervisors start the inspected children | No runtime behavior tests executed | OPEN; selected startup-backed no-op children confirmed |

## 4. Critical verification: RL-558 — invalid HAI impact levels

### 4.1 Source evidence

Pinned source files and blob identities:

- `lib/tiannara/hai/domain.ex` — `4a8ffe859a2611de1a3df032509a431d1ee55163`
- `lib/tiannara/hai/review_router.ex` — `54a09fc1c2b143b61edecf0b615c229011b335fa`
- `test/tiannara/hai/review_router_test.exs` — `20844345ec28a63d844d0c53aea1200313b6473e`
- `lib/tiannara/control_center.ex` — `7e8c675714553eea58e73d642b3c3dc87bdc3960`
- `lib/tiannara/operations/operations_supervisor.ex` — `d7cccc0135ec2e907a7e4178f8a4ad822cc9028f`
- `lib/tiannara/application.ex` — `142d6c18122720a332569cbdf36ae492604273a0`

`ReviewRequest.impact_levels/0` enumerates `[:low, :medium, :high, :critical, :civilizational]`. However, `ReviewRequest.new/1` applies caller attributes using `struct(attrs)` without validating the value of the known `:impact_level` field.

`ReviewRouter.determine_routing/1` has explicit clauses for mandatory levels and medium, followed by `defp determine_routing(_impact_level), do: :approved`. Therefore nil, an unknown atom or another non-enumerated value reaches automatic approval. `ReviewRequest.mandatory_review?/1` returns false for such values.

### 4.2 Startup and decision-boundary trace

Static composition:

1. `Tiannara.Application.core_children/0` includes `Tiannara.Operations.OperationsSupervisor`.
2. `OperationsSupervisor.init/1` starts `Tiannara.ControlCenter`.
3. ControlCenter's `@subsystems` includes `Tiannara.HAI.ReviewRouter`.
4. ControlCenter's `boot_all_subsystems/1` calls `start_subsystem/2`, which invokes the module's `start_link/1`.

This confirms a root application startup path for the router at this source baseline. It does not prove that every external deployment uses this root application or that a particular invalid review was submitted in a live system.

### 4.3 Existing test gap

The checked-in ReviewRouter tests exercise low, high, critical and civilizational values. They do not submit nil, an unknown atom, malformed strings or future enum values. The test named around valid impact levels only iterates over the valid list; it does not prove invalid values are rejected.

The same source also exposes a separate authority concern for remediation planning: `record_decision/3` ignores the GenServer caller identity and accepts a decision/rationale without checking an authenticated human principal or decision enum. This is recorded here as an additional verification requirement under RL-558, not as proof that a remote attacker can reach the GenServer.

### 4.4 Required negative tests

- Constructor rejects nil, unknown atom, malformed string and absent impact level.
- Router rejects the same values even if a caller bypasses the constructor.
- Unknown/future enum values never enter `:approved`.
- Only `:low` may be auto-approved if the governance policy explicitly permits it; all other accepted levels require the defined review lifecycle.
- Decision recording rejects unauthorized/non-human principals, invalid decisions, missing rationale where required, and decisions against non-pending requests.
- Every approval event carries authenticated actor identity, decision provenance and the exact review/request digest.
- Integration test proves no invalid input can authorize a downstream operation.

**Acceptance invariant:** no unrecognized or missing impact classification can yield approval, and no high-impact decision can be considered human-approved without a verifiable authorized human decision.

## 5. Critical verification: RL-562 — synthetic constitutional audit evidence

### 5.1 Source evidence

Pinned source files and blob identities:

- `lib/tiannara/control_center.ex` — `7e8c675714553eea58e73d642b3c3dc87bdc3960`
- `lib/tiannara/evolution/constitutional_auditor.ex` — `c0063363b49a8294946a5b3c2ac0225856bfc047`
- `lib/tiannara/operations/operations_supervisor.ex` — `d7cccc0135ec2e907a7e4178f8a4ad822cc9028f`
- `lib/tiannara/application.ex` — `142d6c18122720a332569cbdf36ae492604273a0`

ControlCenter's `run_constitutional_audit/1` constructs the `system_state` passed to the auditor. It derives capability count and verification count from its own subsystem and health-history maps, but hardcodes hidden uncertainty, mandatory reviews completed/required, lineage violations, safety violations, coupling violations, evolutions deployed and evolution validations to zero, and objective alignment to 0.9.

The auditor then interprets missing fields as safe defaults: zero for violation/review counts and 1.0 for objective alignment. In particular:
- human judgment passes when mandatory reviews required is zero;
- uncertainty, lineage and safety checks pass when the supplied counts are zero;
- verification pace and evolution-validation balance default to ratio 1.0 when their denominators are zero;
- overall status becomes `:compliant` whenever all eight checks pass.

The code therefore confirms a synthetic-input path capable of generating a compliant audit without consulting the authoritative human-review, uncertainty, lineage and safety evidence sources.

### 5.2 Startup and output trace

The root application starts OperationsSupervisor, which starts ControlCenter. ControlCenter schedules the constitutional audit on a 24-hour interval and also exposes a cast trigger. The audit result is stored as `last_audit`; the periodic report includes `last_audit_status`.

This proves a root-startup-backed path that can generate and retain a compliance status. It does **not** establish that this status is consumed by a release gate, deployment authority or other downstream decision-maker. That consumer/release propagation remains UNKNOWN and must be traced before claiming an externally actionable bypass.

### 5.3 Required negative tests

- Missing every required evidence field yields UNKNOWN/incomplete, never compliant.
- Explicit zero counts without evidence references yield UNKNOWN, not zero violations.
- Evidence records must be signed/provenance-bound, current, scoped to the same system snapshot and independently verified.
- Stale, contradictory, malformed, replayed or tampered evidence prevents compliance.
- Mandatory-review denominator cannot be zero merely because no review ledger was queried.
- Auditor computes status only from typed evidence results; exceptions/unavailable providers cannot be converted into safe defaults.
- Integration test proves ControlCenter cannot emit `:compliant` when any authoritative source is missing or unavailable.

**Acceptance invariant:** compliance is impossible unless all required constitutional evidence is present, current, independently verifiable and bound to the audited system state.

## 6. Remaining five findings — independent observations

### RL-557 — Observatory metrics

Re-fetched provider bodies confirm:
- simulation success rate always returns `{:ok, 0.0}`;
- experiment success rate always returns `{:ok, 0.0}`;
- prediction validation rate always returns `{:ok, 0.0}`;
- design verification/success rates always return `{:ok, 0.0}`;
- certification success rate always returns `{:ok, 1.0}`;
- active theory registry always returns `{:ok, []}`;
- unknown registry count always returns `{:ok, 0}`.

The runtime Observatory metrics collector also contains direct constant values and collapses provider failures to numeric zero in inspected functions. The metric code is in the separate `tiannara_runtime` source project. The deployment/release and consumer chain for this collector was not independently established in this checkpoint. Keep that reachability UNKNOWN; do not treat the runtime source path as proof that a particular deployed Observatory displays these values.

### RL-559 — ToolForge review

`request_human_review/2` constructs a `ReviewRequest` with medium impact and discards the returned struct. It does not submit to `Tiannara.HAI.ReviewRouter`, retrieve a pending review or await a decision. It returns `:ok`, including from its rescue clause. The pipeline then logs “Human review passed”.

The root application adds ToolForge only when ASC is enabled; `asc_enabled?/0` defaults to false. The false-success path is therefore feature-flag gated. The checked-in ToolForge integration test expects a tool build to succeed but does not assert that a human review exists or has been decided. No live ASC-enabled run was performed.

### RL-560 — customer analytics

The pinned analytics route body uses `random` values for dashboard metrics, generated sample insight records and random prediction values/confidence intervals. The capabilities endpoint returns a static list with capabilities labelled active. The source comments explicitly describe database/Core integration as TODO/sample behavior.

The FastAPI main module imports the analytics-insights router and includes it in the application router composition. This confirms a mounted source route, not an observed request in a deployed environment. No API request or deployment configuration was exercised.

### RL-561 — ONNX exporter

The pinned exporter calls the supplied NumPy function to inspect sample output shape/dtype, then creates an ONNX `Identity` node from the first input rather than translating the function's computation. Without sample inputs it creates a minimal graph with no model computation. The validator initializes accuracy to 100.0; `original_func` is optional, so the reported accuracy is not necessarily backed by a comparison oracle.

The production ingress/consumer for this exporter remains UNKNOWN. No ONNX export or inference was executed. Closure must require semantic graph translation or typed refusal, plus an independent reference oracle for every accuracy claim.

### RL-563 — supervised no-op children

The root application starts Physics, Stabilization and Topology supervisors. The Physics supervisor starts NDE and IRD supervisors; NDE starts `Tiannara.Physics.NDE.ChaosAnalyzer`, and IRD starts `Tiannara.Physics.IRD.NATSIntegration`. The inspected child bodies initialize only counters and implement only a status call, without analysis or NATS integration behavior.

This confirms startup-backed examples of status-only children, not every child under the three subsystem trees. The broader set of children and their declared contracts still requires a complete per-child audit. No runtime message/analysis behavior was exercised.

## 7. Cross-finding test plan and evidence requirements

| Test family | Required negative/positive cases | Required oracle |
|---|---|---|
| HAI review | nil/unknown/malformed impact; unauthorized actor; invalid decision; pending/rejected/deferred lifecycle | Authorized human principal, signed decision record, request digest |
| Constitutional audit | absent, stale, contradictory, replayed, fabricated and valid evidence | Independent evidence-source verifiers bound to one snapshot |
| ToolForge | no router, no reviewer, timeout, reject, defer, forged approval, accepted decision | Persisted HAI decision tied to exact tool artifact digest |
| Observatory | genuine zero, nonzero, missing, stale, provider exception, inconsistent providers | Authoritative metric ledger, timestamp, source/version provenance |
| Analytics API | demo mode vs production mode; no provider; random seed changes; tenant isolation | Persistent tenant-scoped usage records and actual model execution receipts |
| ONNX | non-identity function, multi-input function, absent oracle, mismatched output, malformed graph | Independent reference function and numerical comparison over multiple vectors |
| Supervised children | child receives real event/message, valid state transition, provider unavailable, restart | Declared subsystem contract and observable effect, not process liveness alone |

Tests must distinguish:
- `PASS`: the claimed behavior was executed and verified;
- `FAIL`: a negative invariant was violated;
- `UNKNOWN`: the necessary source, provider or oracle was unavailable;
- `NOT_RUN`: no execution occurred.

No test may convert `UNKNOWN` or `NOT_RUN` into `PASS`.

## 8. Remediation order and governance constraints

1. RL-558: close invalid-impact auto-approval and establish authenticated human decision provenance.
2. RL-562: remove synthetic constitutional evidence and make missing evidence UNKNOWN.
3. RL-559: wire ToolForge into the canonical HAI lifecycle; no pipeline success without a persisted decision.
4. RL-557: bind metrics to authoritative providers; distinguish zero from unavailable/stale.
5. RL-560: remove synthetic data from production analytics routes or make demo-only routes explicit and isolated.
6. RL-561: implement genuine export or reject unsupported functions; require an accuracy oracle.
7. RL-563: classify every child against its declared contract and canonical owner before implementing or retiring it.

No remediation is authorized by this audit. Constitutional Council remains the higher authority; ControlCenter, CEL, dashboards and local subsystems must not become replacement constitutional authorities. Preserve separate root/runtime project boundaries unless ownership, release composition and state migration are independently proven.

## 9. Checkpoint disposition

- RL-557–RL-563: all remain OPEN.
- RL-558 and RL-562: CRITICAL source defects independently re-confirmed; root startup paths confirmed statically.
- RL-559: false-success path confirmed; ASC-gated.
- RL-560: synthetic routes confirmed in mounted FastAPI source; deployed reachability UNKNOWN.
- RL-561: semantic exporter/validator defect confirmed; production ingress UNKNOWN.
- RL-563: selected status-only child implementations and nested startup paths confirmed; full child inventory remains incomplete.
- New finding IDs: none; this checkpoint strengthens evidence and records additional RL-558 authorization-test requirements.
- Production code changed: no.
- Tests/build/runtime/CI executed: no.
- Deployment/physical actuation: no.

**Final status:** `PARTIAL_EVIDENCE — OPEN`.

**Next checkpoint 19.08:** execute isolated negative tests for RL-558 and RL-562 first, then trace every downstream consumer of the HAI approval result and ControlCenter audit status. Tests must run against a disposable/test configuration, not a live production environment. Produce a human-ratifiable remediation plan only after the test oracles and evidence contracts are specified.
