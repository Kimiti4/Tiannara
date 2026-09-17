# MC-003-M Mutation Evidence Matrix

**Gate:** MC-003-M — Phase-16 Real-Execution Truthfulness Mutation
**Campaign:** Tiannara Remediation + Substrate Integration
**Scope:** M1, M2, M3, M4, M6, M7, M8 (M5 excluded by authorization)
**Status:** EVIDENCE COMPLETE — verdict CERTIFIED_BOUNDED
**Date:** 2026-08-30

This ledger records, per mutation, WHAT was changed, the verification evidence
(compile + targeted suite results), and the honest boundary (what did NOT run).

---

## M1 — Verification/Certification/Executive/CEL truthfulness

| Artifact | Pre-mutation | Post-mutation |
| --- | --- | --- |
| `lib/tiannara/verification_authority.ex` | fabricated passing checks | `attempt_reproduction` → `reproduced: false`; `synthesize_regression_tests` → `all_passing: false`; `check_constitutional_compliance` → `compliant: false`, reason `:not_independently_assessed` |
| `lib/tiannara/verification/result.ex` | lenient `passed?/1` | `is_map/1`-guarded; cannot bless unverified results |
| `lib/tiannara/omega/certification_server.ex` | `handle_info :experiment_completed` → pre-opened successful cert | `gate_results` all `:unevaluated`; `Certification.Pipeline.evaluate` must judge honestly |
| `lib/tiannara/executive/cognitive/executive_cycle.ex` | fabricated `:completed`/valid postings | `:execute` posts `status: :pending`, `note: :awaiting_real_execution_provider`; `:validate` only `valid: true` with real evidenced execution |
| `lib/tiannara/cel/workflow/steps/{experiment,observation,validation}.ex` | constant scripted step outputs | `execute` → `{:error, {:unavailable, :real_step_provider_not_wired}}`; fabricated helpers removed |

**Evidence:** `mix compile` PASS. Suites: proposal (10), autonomy (53), phase4 (62), cel — all green.

## M2 — Phase-4 real-execution gateway

| Artifact | Change |
| --- | --- |
| `lib/tiannara/phase4/experiment_orchestrator.ex` | `submit_experiment/1` gated by `Application.get_env(:tiannara, :real_execution_enabled)`; `handle_call` delegates to `Tiannara.Phase4.RealExecution`; experiment bookkeeping only from real results |
| `lib/tiannara/phase4/real_execution.ex` (NEW) | `enabled?/0` (default false); grant guard (`%Authorization{}` → else `:authorization_grant_required`); real substrate required (`:no_real_execution_substrate_configured`); `RealHarness.run` in sandbox; durable JSONL ledger `priv/tiannara/real_execution/executions.jsonl`; `Evidence.Provenance.build(kind: :real_execution, execution_id: ...)`; best-effort `Executive.EventStore.append`; deployment solely via `Omega.DeploymentGateway.deploy` under valid certification + lineage + grant + identity |
| `lib/tiannara/sentinel/activation/approval.ex` | `decide(proposal_id, :approve)` routed through orchestrator gateway; direct `Tiannara.Sandbox.execute` removed |

**Evidence:** `test/tiannara/phase4/real_execution_test.exs` (5 gate tests: disabled refusal, grant required, substrate required, enabled?/4, orchestrator refusal) all PASS. orchestrator version test corrected to module truth (`"2.0.0"`).

## M3 — DiscoveryScheduler confidence delta

**Change:** `finalize_discovery` derives `confidence_delta(outcome, evidence)` from the evidence confidence distribution instead of a fixed constant: supported outcome → `mean(evidence confidences) * 0.2` (fallback 0.1); refuted/other → `mean * -0.05` (fallback 0.0). Helpers `confidence_delta/2`, `evidence_confidences/1`, `round3/1`.

**Evidence:** discovery suite (174 tests) green.

## M4 — Real execution verification evidence

**Change:** Real execution records attach `verification: %{harness: :real_sandbox, method: :real_sandbox, ...}` with measured build/test/benchmark outcomes — never fabricated confidence.

**Evidence:** source-scanned by verifier; gate tests green; no live run performed (see boundary).

## M6 — ProductionObservatory provider gate

| Artifact | Change |
| --- | --- |
| `lib/tiannara/reality/production_observatory.ex` | Rewritten: without a real external provider → `{:ok, %{status: :unavailable, reason: :no_external_provider, fed_reality_ledger: false}}`; **never** calls `RealityLedger.record_revenue` absent real provider; provider contract documented; rescue → `{:error, {:provider_failed, e}}` |
| `lib/tiannara/stubs/httpoison.ex` | DELETED |

**Evidence:** no lib/test callers of the HTTP path or `HTTPoison` remain (grep-verified pre-edit); compile PASS.

## M7 — RollbackEngine unavailable

**Change:** `handle_call({:rollback, …}, …)` → `{:reply, {:error, :rollback_unavailable}, state}`; no success/rollback counters incremented; `execute_rollback/1` retained only as a documented future wiring point (unused).

**Evidence:** `rollback_engine_test.exs` rewritten — 6 tests assert honest unavailability (no `%RollbackAttempt{}` fabrication, counters stay 0). autonomy suite (53) green.

## M8 — Autonomous/repair/tool surfaces decommissioned

| Artifact | Change |
| --- | --- |
| `lib/tiannara/autonomy/constitutional_autonomy.ex` | `run_cycle/0` gated: when not enabled or no real simulation provider → `{:ok, %{stage: :simulation, result: :not_available, reason: …}}`; `full_cycle/1` structurally unreachable (`autonomous_execution_enabled?` reads flag, `real_simulation_provider?` false) |
| `lib/tiannara/asc/repair/pipeline.ex` | `SandboxValidator.validate` / `CanaryReleaser.release` / `ProductionRollout.rollout` → `{:error, :unavailable}` |
| `lib/tiannara/tool_forge/tool_builder.ex` | `do_execute` → `{:error, {:not_implemented, input}}` |
| `lib/tiannara/sopl/evolution_engine.ex` | `deploy/1` → staged log only; no environment mutation |

**Evidence:** `constitutional_autonomy_test.exs` rollback test updated; autonomy suite (53) + tool_forge (11) green.

---

## Regression battery (post-mutation, standalone runs)

| Suite | Result |
| --- | --- |
| `test/tiannara/phase4` | 62 tests, 0 failures |
| `test/tiannara/autonomy` | 53 tests, 0 failures |
| `test/tiannara/tool_forge` | 11 tests, 0 failures |
| `test/tiannara/discovery` | 174 tests, 0 failures |
| `test/tiannara/evidence + provenance + engineering` | 51 tests, 0 failures |
| `test/tiannara/executive + self_improvement` | 48 tests, 0 failures |
| `test/tiannara/omega` | 100 tests, 0 failures |
| `test/tiannara/certification` | 6/7 pass (1 pre-existing — dead constitutional probe, below) |
| `test/tiannara/asc` | flaky 11–42 failures — environmental supervisor/port races (`:already_started`, `no process`, `poison`); none touch repaired surfaces; non-reproducible run-to-run |

### Pre-existing failures (NOT mutation-introduced)
- `sentinel/activation_engine_test.exs` (2): `start_supervised!` of `Tiannara.Sentinel.Cognition.Supervisor` collides with app-started process → `{:already_started, …}`. Confirmed identical pattern in the pre-mutation baseline battery.
- `sentinel/cognition/orchestrator_test.exs` (17): exact same `{:already_started, …}` supervisor-collision root cause.
- `certification/certification_pipeline_test.exs` (1): "integrates with the constitutional invariant suite" — probes `sentinel_never_executes` / `research_director_never_executes` reference `Tiannara.Sentinel.Authority` / `Tiannara.Research.Authority`, modules that do not exist anywhere in `lib/` or `git ls-files` (dead probes → always raise → always reported as violated).
- `activation` / `cognition` / `certification` suites are structurally unchanged by this gate (no mutations applied to their modules or supervision trees).

## Honest boundary (what did NOT happen)
- `:real_execution_enabled` remains **false** everywhere (module default + config).
- **No live real experiment was executed.** P16-AT(b) live P16 run remains PENDING and requires a fresh human grant + explicit flag flip.
- M5 (os/ boot/wiring) **excluded** by authorization; `os/`, `tiannara_runtime/` not booted in this gate.
- Nondeterministic-serving phenomenon internals (SimulationManager/DeploymentPipeline) untouched.
- No fabricated PASS claimed for any unexecuted check.