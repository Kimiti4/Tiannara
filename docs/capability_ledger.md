# TIANNARA CAPABILITY LEDGER — WHAT EXISTS vs WHAT IS PENDING

**Status:** EVIDENCE-BACKED, WORKING-TREE STATE
**Date:** 2026-09-22
**Branch:** `local/pr4` (HEAD `b564fbe`)
**Auditor role:** independent verification pass (no runtime self-report accepted as proof)
**Supersedes:** the "MISSING" rows of `docs/production_completion_baseline.md` §3.1 where contradicted below

---

## 0. How to read this document

Statuses are the constitutional vocabulary and are never collapsed:

| Status | Meaning (enforced strictly here) |
|---|---|
| `IMPLEMENTED` | Real execution path exists, is reachable from boot, and does real work |
| `PARTIAL` | Real core exists; named sub-capabilities or integration edges are absent |
| `STUB` | Module exists, returns fixed/placeholder values, is declared as a stub |
| `THEATRICAL` | Module presents itself as working, over-claims, and produces no real work |
| `BROKEN` | Path exists but fails in normal use |
| `UNUSED` | Real code, no reachable consumer |
| `UNVERIFIED` | Not demonstrated either way in this pass |
| `UNKNOWN` | Cannot be determined from available evidence |

**Evidence rule applied:** a green gate, a passing interface, a supervisor child, or a module's own
health report is **never** accepted as evidence of capability. Every claim below cites a file:line,
a measured boot fact, or an exact command.

**Reproduction:** `docs/production_completion_baseline.md` §2 records the boot/probe commands.
Audit tooling lives in `tools/audit/`.

---

## 1. Headline verdict

The architecture is **substantially ahead of executable capability in the discovery/research plane**,
and **substantially behind in one specific, structural way: the constitutional gates validate a
service's own self-report rather than validating the service's behaviour.**

Five capabilities are genuinely production-grade today; five are named for real but are not real;
the remainder are real-but-incomplete.

### 1.1 Genuinely operational (measured, not asserted)

1. **Runtime orchestration / OTP supervision** — `Tiannara.Application` boots **61 children**
   at first pass → **63 measured 2026-09-23** (+LiveProjection, +CTL.CausalRegistry; dev probe
   `Status: ready`) (31 supervisors / 30 workers at first pass), 473 registered names, 773 processes, 196 ETS tables, ~102 MB.
2. **CEL executive kernel + 5-gate admission** — EOS boot report `status: :ready`, **34 services all
   `:ok`**, 1 874 ms, 5 gates each (`resource/health/capability/constitution/dependency`).
3. **Constitutional council framework** — 18 `council/` modules incl. rule engine (240 L),
   audit log (327 L), amendment engine, policy registry, human approval queue.
4. **Provenance substrate** — `World.ProvenanceEngine` `:ok`; `forward_provenance` dependency wired
   across 24 modules.
5. **Capability discovery / archaeology** — 21 CRAV modules (`runtime_atlas` 799 L, `challenge_runner`
   904 L, `soak_test` 916 L, `runtime_census` 530 L, `runtime_dependency_graph` 497 L,
   `dead_code_detector` 477 L, `supervisor_integrity` 358 L, `activation_matrix` 352 L).
   *This is the repository's strongest asset — and §3.1 shows why it is also the most necessary one.*

### 1.2 Named, supervised, and not real

| Named capability | What actually happens |
|---|---|
| `deterministic_replay` / `sandboxed_execution` / `state_recovery` | `replay/3` returns `{:error, :replay_source_unavailable}` (`world/replay_engine.ex:69-72`) |
| 20 domain research organs | `generate_hypotheses/1` returns `{:ok, []}` *(unchanged 09-23 — D-A2/B11)* |
| ~~17 domain simulators~~ | **Remediated 2026-09-23:** the constant `simulate/2` verdicts were quarantined → `{:error, :simulation_unavailable}` (18 modules; `domain_quarantine_test.exs` 5/5) |
| ~~Causal Tensegrity branch validation~~ | **Remediated 2026-09-23 (D-B):** validator reads the real stateful registry and fails closed; the case-twin stub was deleted (live probe: `validate_merge(ghost, ghost) → {:error, :branch_not_found}`) |

### 1.3 The single most important structural finding

**The constitutional gates are answered by the gated party, so a service that cannot do its job
admits itself with a perfect score.**

> **Partially remediated 2026-09-23 (third pass).** The *failure paths* are now honest: a raising,
> non-struct, or uncomputable score fails the constitution kernel (`ConstitutionalScore.unavailable/1`,
> all zeros → never boot-ready); `BootSequencer.check_constitution/2` no longer converts exceptions to
> `:pass`; explicit stubs are refused at the constitution gate itself; and the first service caught
> fabricating through the old swallow path — `mission_director`, whose scorer raised `:badarith` at
> every fresh boot and was certified `1.0` — was root-caused and fixed (D-A9, D-A10). Measured: boot
> flipped `failed → ready` only after that root fix, with 34/34 services `:ok` under gates that can
> now demonstrably fail. **The core violation remains open (B12/F-A):** returned score *values* are
> still self-asserted (`ReplayEngine` still advertises perfect components) because no independent
> recompute exists yet. Evidence: `tools/audit/evidence_2026-09-23_gatefix_*` (4 files),
> `tools/audit/boot_report_diag.exs`.

The code block below is the **pre-remediation** kernel (preserved for lineage; the catch-to-default
shown no longer exists). `CEL.Kernel.check_constitutional_score/1` (historical, pre-2026-09-23) called
the service's own `constitutional_score/0` and **only rescued exceptions — it never validated the
returned values**:

```elixir
defp check_constitutional_score(spec) do
  {mod, fun, args} = spec.constitutional_score_check
  try do
    apply(mod, fun, args)
  catch
    _, _ -> ConstitutionalScore.default(spec.id)
  end
end
```

`Tiannara.World.ReplayEngine.constitutional_score/0` (`world/replay_engine.ex:34-45`) returns
`health: 1.0, constitutional_alignment: 1.0, transparency: 1.0, explainability: 1.0,
evidence_quality: 1.0, human_oversight: 1.0` — while its only real operation returns
`:replay_source_unavailable`. It is registered as a live CEL service declaring
`provides: [:deterministic_replay, :sandboxed_execution, :state_recovery]`
(`cel/kernel/service_registry.ex:236-240`) and is therefore **admitted at boot with all 5 gates
`:ok`**, and named healthy in the live Ω health report.

This is a direct violation of the project's own Certification Rule
(`Generators never certify themselves` / `Validation code must never trust self-reported metrics`)
and the root cause of a green gate over a theatrical service.

---

## 2. Status by completion wave (the eight-wave program)

| Wave | Deliverable | Status | Evidence |
|---|---|---|---|
| 0 | Truth baseline | **IMPLEMENTED** | `docs/production_completion_baseline.md` (325 L) + `tools/audit/` probes |
| 1 | Constitutional core closure | **PARTIAL → IMPROVED** | boot/CEL/council/provenance real; authorization closure not universal; audit-log durability defect (§3.2); **gates now fail closed on error/stub (2026-09-23, D-A9/A10); B12 independent recompute of score values still open** |
| 2 | Make advertised subsystems real | **PARTIAL → IMPROVED** | replay now fails closed; `ReadOnlyHTTP` + `LiveProjection` added; **D-A3 constants quarantined fail-closed 2026-09-23 (18 `simulate/2` + 16 `validate/1` now return named unavailable errors); empty organs (D-A2, 20/31 `generate_hypotheses`) remain; residual constant `evaluate/1` + `metrics/0` = D-A11** |
| 3 | Integrate the organism (U0 loop) | **NOT DEMONSTRATED** | no single-trace bounded mission across all 15 loop stages exists |
| 4 | Immune system real (detect→…→verify) | **PARTIAL** | CIS resident; chaos/fault injection exists; recovery-verifies-recovery not demonstrated end-to-end in production topology |
| 5 | Production execution | **PARTIAL** | profiles `dev/research/production/benchmark/safe-mode/distributed`; **no `demo`, no `personal`**; start path requires PostgreSQL 5432 + Redis 6379 + NATS 4222 |
| 6 | Production certification | **NOT EXECUTABLE** | suite is red (§2.1); no machine-readable certification artifact |
| 7 | Demo + personal deployment | **ABSENT** | profiles and runbooks do not exist |

### 2.1 Regression suite state (measured)

`mix test` is **not green**: ≥99 failures with 204 crash markers. Root cause is characterised, not
guessed: tests call `start_supervised!(Tiannara.ASC.Core.Supervisor)` while the application already
boots it under `asc.enabled: true` (`config/config.exs`), producing `{:already_started, pid}`.
Isolated reproduction: `mix test test/tiannara/asc/core/boot_test.exs` → `2 tests, 2 failures`.

**Rule for remediation:** fix topology alignment. Never disable ASC to make tests pass, and never
weaken an assertion. `test/tiannara/asc/core/supervisor_topology_test.exs` (written 09-22 13:29) is
the newest file in the tree and is the intended anchor for this fix.

**Compilation:** `mix compile --no-deps-check` → clean (redefinition warnings only).

---

## 3. New defects found in this pass

All are reproducible from the cited path. None is a documentation gap; all are behaviour.

| # | Defect | Evidence | Severity |
|---|---|---|---|
| **D-C** | **Gate self-reporting** — `constitutional_score/0` is unvalidated; a service that cannot execute still admits itself with six 1.0s and is named healthy | `cel/kernel.ex:136-143`, `world/replay_engine.ex:34-45`, `cel/kernel/service_registry.ex:236-240` | **CRITICAL** |
| ~~**D-B**~~ **Remediated 2026-09-23** | **A stub was aliased into a real validation path** — `Ctl.BranchValidator` aliased `Tiannara.Ctl.CausalRegistry` (the stub: `get_branch/1` → constant `{:ok, %{stress: 0.0}}`); the real `Tiannara.CTL.CausalRegistry` had no `get_branch/1` and zero callers, so every merge passed on a constant. **Root cause was deeper than the alias: on case-insensitive filesystems the twin beam files collide — exactly one of the two modules survived each compile, non-deterministically** (proved live: boot crash `module ... does not exist`; the surviving beam contained `__tiannara_stub__`; source scan found this as the only case-twin among 2,193 modules). Fixed: validator unaliased and fails closed (`:registry_unavailable` / `:threshold_configuration_absent` / `:branch_not_found` / `:branch_evidence_incomplete`), real registry rewritten as a stateful GenServer with stress validated in `0..1` and `{:ok, count}` measurement, **stub file deleted**, registry booted as an application child, stress threshold moved to config with fail-closed-absent semantics. Tests: `ctl_branch_validator_test.exs` (8) | `ctl/branch_validator.ex`, `ctl/causal_registry.ex`, `stubs/causal_registry.ex` (deleted), `application.ex`, `config/config.exs` | **CRITICAL → REMEDIATED** |
| **D-A2** | **Research organs are empty** — `generate_hypotheses(_context), do: {:ok, []}` in **20 of 31** `domains/` files *(scope note 2026-09-23: the §7 step-3 quarantine deliberately targeted `simulate/2`/`validate/1` only; empty organs remain — tracked as B11)* | `lib/tiannara/domains/*.ex` | **HIGH** |
| ~~**D-A3**~~ **Remediated (quarantined) 2026-09-23** | **Domain simulators were constants with authoritative-sounding names** — e.g. `:flight_worthy`, `:sustainable`, `:manufacturable`, `:efficacious`; `validate/1` returned `{:ok, %{valid: true}}` unconditionally; some fabricated measurements (`medicine`: `trial_phase: :phase_2`; `governance`: `constitutional_alignment: 0.94`). **Quarantined:** 18 constant `simulate/2` → `{:error, :simulation_unavailable}`, 16 constant `validate/1` → `{:error, :validation_unavailable}` with per-file provenance comments; real computations kept callable (physics RK4, chemistry graph, FormalVerification-backed validates). The only production caller (`ASC.AutonomousDiscovery`) already handled `{:error, reason}` arms, so the loop now honestly reports `:simulation_unavailable` instead of integrating fabricated validations. Regression: `domain_quarantine_test.exs` (5 tests) | `lib/tiannara/domains/*.ex` (20 files) | **HIGH → QUARANTINED** |
| ~~**D-A1**~~ **Remediated 2026-09-23** | The hardcoded `CTL.CausalRegistry.get_active_branches/0 → 10_000` with the comment `# Mock 10k branches for the explosion test` was removed with the registry rewrite: it now returns `{:ok, count}` of actually registered branches (asserted `refute count == 10_000` in `ctl_branch_validator_test.exs`) | `ctl/causal_registry.ex` | HIGH → **REMEDIATED** |
| **D-A6** | **601 corrupted council audit logs** — `council_audit_log.dets.corrupted.*` from 2026-08-16 → today: the constitutional audit trail corrupts and is archived on nearly every boot | repo root, `council/` audit-log durability test now present (09-22 04:17) | HIGH |
| **D-A8** | **Dead validator** — `Tiannara.CIS.validate_plan/1` returns `{:ok, plan}` unconditionally and has no callees *(path corrected 2026-09-24: module lives in `lib/tiannara/cis_constraint.ex:17-20`; source comment reads "Placeholder: all plans valid for now"; 0 callers re-verified by filesystem grep)* | `lib/tiannara/cis_constraint.ex` | MEDIUM |
| **D-A4** | **Parallel unbooted application roots — eight per baseline §2.1 Finding A, across ≥4 languages** — `tiannara_runtime/` (separate Mix app), `tiannara_core/` (Python), `tiannara_api/` (FastAPI), `tiannara_saas/` (Next.js), `tiannara_gui/`, `tiannara_observatory/`, `tiannara_audit/`, `tiannara_pros/` inflate apparent capability while being invisible to boot, census and CI | repo root, baseline §2.1 | MEDIUM |
| **D-A5** | **Test isolation is illusory** — `config/test.exs` uses `System.unique_integer([:positive])`, which repeats per VM → stale DETS is inherited and silently "repaired" | `config/test.exs` | MEDIUM |
| **D-A7** | **Activation is ~21 %** — 864 modules loaded, 383 `Tiannara.*`, against 1,847 declared | measured boot census | INFORMATIONAL |
| **D-A9** | **Second fail-open layer in the constitution gate (found during remediation)** — `BootSequencer.check_constitution/2` caught *every* exception and returned `:pass`; together with the kernel's catch-to-default this double-swallowed scoring failures into a green boot | `cel/kernel/boot_sequencer.ex:116-123` (pre-fix); `evidence_2026-09-23_gatefix_badarith_diag.out` | **HIGH → REMEDIATED 2026-09-23** |
| **D-A10** | **A crashing scorer was certified perfect (found by the repaired gate)** — `MissionDirector.constitutional_score/0` raised `:badarith` at every fresh boot (`stats.total_missions \|\| 1` keeps 0; `0` is truthy → division by zero) and the kernel certified it `1.0`; its process-down branch also fabricated `total_missions: 1`. Root-caused: zero-guard added, absent process now yields `ConstitutionalScore.unavailable/1`. Boot went `failed → ready` only after this fix, with the gate reporting the real `:badarith` in between | `cel/services/mission_director.ex:34-55` (pre-fix); `evidence_2026-09-23_gatefix_boot_failed_pre_fix.out` | **HIGH → REMEDIATED 2026-09-23** |
| **D-A11** | **Domain `evaluate/1` and `metrics/0` still fabricate (found during the D-A3 sweep)** — 5 confirmed constant `evaluate/1`: `architecture` `structural_soundness: 0.93`, `chemistry` `confidence: 0.91`, `governance` `alignment_score: 0.82`, `logistics` `optimality: 0.91`, `robotics` `feasibility: 0.88` (7 others use real `bayes_update`; the 8 multi-line bodies are all real computations — Shannon entropy / Nash equilibrium — and were verified in the same pass); **19 of 20 `metrics/0` return hardcoded counts** (e.g. `medicine` `active_hypotheses: 205`) — only `physics` is `metrics_source: :state_derived`. Outside the §7 step-3 gate; next quarantine candidate | `lib/tiannara/domains/*.ex` (`evaluate`, `metrics`) | **HIGH — OPEN** |
| **D-A12** | **Executive DETS recovery ladder is wired to a non-existent OTP function (found by the pre-commit probe re-run)** — `executive/dets_store.ex:68-69` calls `:dets.repair_file/1`; measured on OTP 28: `repair_file/1 → false`, `repair_continuation/1 → false`. `Recovery.attempt_repair/1` (`recovery.ex:31-41`) therefore raises `UndefinedFunctionError` inside its `case` instead of returning, so the designed ladder open → repair → **backup promotion** → fresh **never reaches the backup fallback** — while `startup_recovery/1` is called from two live `ExecutiveMemory` sites (`executive_memory.ex:353,526`). Smallest corrective change: make `DetsStore.repair/1` return a named fail-closed `{:error, :dets_repair_unavailable}` so the `{:error, reason}` arm routes to backup promotion (real repair = delete/restore semantics, separate work) | `executive/dets_store.ex:68`, `executive/recovery.ex:31-41`, `executive_memory.ex:353,526`; `tools/audit/evidence_2026-09-23_precommit_theatrical_probe.out` §3 | **HIGH — OPEN** |

---

## 4. The 39 capability families — EXISTS / PENDING

| # | Capability family | Status | Exists (evidence) | Pending edge |
|---|---|---|---|---|
| 1 | Constitutional cognitive operating environment | `PARTIAL` | CEL kernel + 5 gates + council + executive memory, all resident | A cognitive environment whose gates validate self-reports is not yet a constitutional one → **D-C blocks this family** |
| 2 | Epistemic / evidence-first reasoning | `PARTIAL` | provenance engine, evidence ledger, explicit `CERTIFIED/PARTIAL/UNKNOWN/THEATRICAL` vocabulary in certification artifacts | Truth-tracking is **not enforced at admission**: ReplayEngine is admitted as capable (§1.3) |
| 3 | Knowledge validation (ingest→evidence→contradiction→revision) | `PARTIAL` | knowledge-flow audit (`crav/knowledge_flow.ex`, 285 L), institutional memory, knowledge-capital boundary test | No demonstrated pipeline that refuses an unsupported claim or preserves competing hypotheses in the live loop |
| 4 | Autonomous scientific discovery | `PARTIAL` *(was `STUB`→`THEATRICAL`; theatrical half remediated 2026-09-23)* | `AutonomousResearchEngine` exists; `Physics.execute_experiment` bridge is real; **34 constant organ verdicts quarantined fail-closed (18 `simulate/2` + 16 `validate/1`; `domain_quarantine_test.exs` 5/5; ADE's existing `{:error, reason}` arms now report `:simulation_unavailable` instead of integrating fakes)** | 20/31 organs still return `{:ok, []}` (D-A2/B11); no real hypothesis→experiment→evidence closure |
| 5 | World modeling | `PARTIAL` | `UnifiedRealityGraph`, `UnifiedWorldModel`, `WorldMutationEngine`, provenance engine — all live | Replay unavailable; 5 000 ms `GenServer.call` timeout observed live; graph state not recovered after kill |
| 6 | Planetary / civilization modeling | `PARTIAL` / scale `UNVERIFIED` | 13 resident civilization services incl. `PolicySimulationEngine`, `LongTermForecastEngine`, `IntergenerationalEquityEngine` | The 12 worlds / 84 civilizations / 23 800 agents figure is **not reproducible from tracked artifacts** |
| 7 | Civilization-scale intelligence | `UNVERIFIED` | Multi-domain module surface exists | No measured civilian-scale research run against HEAD |
| 8 | Mathematical / formal substrate | `PARTIAL` | **Real and small:** `calculus.ex` 209 L (RK4 `solve_ode/3`), `probability.ex` 21 L (`bayes_update/3`, `shannon_entropy/1`), `statistics.ex` 15 L, `graphs.ex` 25 L | `optimization.ex` 11 L decommissioned to explicit `:unavailable`; **zero symbolic / proof / SMT / theorem modules exist (0 matches)** |
| 9 | Autonomous software engineering | `PARTIAL` | `asc/implementation/compiler.ex` (`System.cmd`), sandbox backends `local/container/ci`, `asc/adoption/adopter.ex`, repro manifests | CI backend `:ci_not_configured`; ToolForge execution is a stub; no governed terminal consumer in production |
| 10 | ESAP — software compiler | `PARTIAL` | Deterministic-identity + provenance + lowering concepts present | **Single backend adapter** (`adapter/elixir.ex`); `deployment_mode: :artifact_only` → backend-neutrality is designed, not demonstrated |
| 11 | Autonomous software evolution | `PARTIAL`, fail-closed `IMPLEMENTED` | `ProposalGenome` + `FitnessEvaluator` (real multi-dimensional logic: invariant checks, viability projection, recommendation), evolution modules, fail-closed fitness semantics | No demonstrated generation→build→execute→fitness→promotion cycle in production |
| 12 | Self-monitoring | `IMPLEMENTED` | Sentinel, `RuntimeVerifier` per-subsystem certificate hashes, Ω health aggregator (`:partial`, 5/6), runtime census, supervisor integrity | Honest reporting is real — but see **D-C**: health is only as truthful as the self-report it aggregates |
| 13 | Self-diagnosis / archaeology | `IMPLEMENTED` | 21 CRAV modules; `archaeology/archaeology.ex`; `runtime_atlas` 799 L, `discovery_chain` 240 L, `dead_code_detector` 477 L | — |
| 14 | Self-repair | `PARTIAL` | Crucible builder/breaker/attacker/validator (2 000+ L), repair ecology + phylogeny, **RepairLibrary live ETS = 18 016 patterns** | Repair → promotion → authorization closure unproven; promotion gates not exercised against HEAD |
| 15 | Constitutional governance | `PARTIAL` (framework `IMPLEMENTED`) | 18 council modules, invariant registry + 3 invariant test suites, human approval queue, amendment engine | Durability defect **D-A6**; gates do not constrain behaviour → **D-C** |
| 16 | Authorization as a first-class capability | `PARTIAL` | `phase4/real_execution.ex` fails closed (`enabled?` default **false**), requires a `HumanDelivery.Authorization` grant; `DeploymentGateway` enforces certification + lineage + grant; two-key adoption gate; **B4 minting landed 09-22: `Authorization.human_grant/2-3` requires `AuthenticatedHumanIdentity` at both delivery APIs (`human_authorization_identity_test.exs` 2/2)** | Minting coverage is narrow (no credential/session persistence, revocation, or external identity verification); **no universal authorization→effect closure** |
| 17 | Effect identity / consequential-action integrity | `PARTIAL → IMPROVED` | `omega/deployment_effect_identity_test.exs` (09-22 04:11), `omega/human_authorization_identity_test.exs` (04:14), `ReadOnlyHTTP.effect_identity/1` binds SHA-256 to `{:read_only_get, url}` | D165 class closed only in Ω deployment + external-read paths; not a global invariant |
| 18 | Provenance & lineage | `IMPLEMENTED` (substrate) | `world/provenance_engine.ex` `:ok`; `forward_provenance` dep in 24 modules; metric-with-provenance | Lineage does not yet extend across the full causal loop (no such loop exists) |
| 19 | Evidence & certification system | `PARTIAL` | `certification/` manifest + evidence ledger + missing-capability register; MC001-M3 theatrical decommission executed | Certification cannot be trusted while gates are self-reported (**D-C**); no executable certification artifact |
| 20 | Deterministic replay | `THEATRICAL` (now fail-closed) | Replay now **honestly** returns `{:error, :replay_source_unavailable}` | No executable mutation source; the service nevertheless advertises `:deterministic_replay` with a perfect score (**D-C**) |
| 21 | Observation architecture | `PARTIAL` | `sentinel/observatory.ex` 381 L, `operational_observatory.ex` 305 L, `observation_buffer`, `observation_scheduler`; `Tiannara.Observatory` is a 37 L logging façade | No authoritative projection-backed publication contract for the UI |
| 22 | **Live state reconstruction (LiveProjection)** | **`PARTIAL` — corrected: EXISTS** | `observatory/live_projection.ex` 90 L, wired at `application.ex:102`, test `observatory/live_projection_test.exs` (09-22 06:28) | **`gap_recovery`: 0 matches repo-wide**; `capability_negotiation` exists only in `os/institution_kernel.ex` → the two named sub-capabilities are absent |
| 23 | Runtime orchestration | `IMPLEMENTED` | 61 children / 31 supervisors / 30 workers at first pass → **63 children measured 2026-09-23**; DetsLifecycle; resource manager, scheduler, priority engine, workflow engine | Several `TiannaraOS.*` modules boot while the rest of TiannaraOS does not |
| 24 | Failure containment / fail-closed | `PARTIAL → IMPROVED` | Replay now fails closed; fail-closed `:unavailable` in `math/optimization`, `foundations/mathematics/calculus`, `domains/physics`; `chaos/*`; CIS resident | Gates cannot detect theatrical behaviour (**D-C**); CIS recovery loop in production topology unproven |
| 25 | Recovery & persistence | `PARTIAL` | `executive/{persistence,recovery,snapshot,transaction,migration,dets_store,corruption_detector,ets_cache}`, `storage/{dets_lifecycle,rotator,paths}`, `soak/*` (7 modules), storage contexts | **D-A12 (found 09-23): the repair step itself raises** (`:dets.repair_file/1` does not exist on OTP 28) so the open→repair→backup ladder skips its backup fallback; graph state not recovered after kill (U8 caveat); live `Could not warm ETS cache from DETS`; audit-log corruption recurring (608 archives) |
| 26 | **External world interface** | **`PARTIAL` — corrected: bounded read-only ingress EXISTS** | `external/read_only_http.ex` 96 L: **GET-only**, `:inets`/`:httpc` (no HTTP dep needed), effect-bound grant `{:external_read, url}`, authenticated-identity check, host allowlist (localhost/127.0.0.1/::1), `autoredirect: false`, 1 MiB cap, SHA-256 `effect_identity/1`; test at 09-22 06:31 | **Write egress absent**; allowlist is loopback-only; ingress beyond loopback unproven. U0's `C11 EGRESS ✗` now applies specifically to *mutating* egress |
| 27 | Multi-domain capability generation | `PARTIAL` | Domain-neutral genome concepts | Single target backend; see #10 |
| 28 | Security intelligence | `PARTIAL` | `phase4/adversarial`, Crucible `attacker` 504 L / `breaker` 671 L, `chaos/{fault,blueprint,runner,epistemic_integrity}`, 14 adversarial/boundary/invariant suites | Security is enforced at the Ω deployment sink, not as a system-wide authority invariant |
| 29 | Continuous self-improvement | `PARTIAL` | `self_improvement/*`, sandbox, adoption, statistical benchmark test | No promoted, evidence-backed improvement of a real capability |
| 30 | Capability discovery | `IMPLEMENTED` — **and now proven necessary** | runtime census, activation matrix, runtime atlas, observatory coverage, discovery chain, dead-code detector | Coverage must be *re-run and trusted*; §1.3 is exactly the class of defect this family exists to catch and did not |
| 31 | Autonomous mission execution (ASC / C-Mission) | `PARTIAL` | `asc/c_missions/*`, real subprocess primitives in 19 files, repro manifests | No bounded governed mission executed end-to-end |
| 32 | AgencyLoop / autonomous agency | `IMPLEMENTED` (experimental) | Live: 5 loops, 50 observations, `observe→analyze→investigate→communicate→improve→learn` | Not proof of safe general autonomy; prior 72 h soak exposed persistence/memory handling problems |
| 33 | Memory architecture | `PARTIAL` | CEL ExecutiveMemory DETS+ETS (`:ok`) with retry/degradation tests (3 test files); `memory/{memory,ladder}.ex`; institutional + civilization memory | `stubs/longitudinal_memory.ex` is an honest stub; no years-scale retention demonstrated; warm-cache failure observed |
| 34 | Simulation as laboratory | `PARTIAL` | `simulation/{simulation_engine,simulation_supervisor,impact_forecaster,scenario_builder}`, `multiworld/{world_forker,world_comparison_analyzer}`, resident `policy_simulation_engine`, `cci/civilization_experiment_runtime` | Not coupled to the governed research loop; no FEA/CFD; `Physics.simulate/2` integrates only a supported ODE spec |
| 35 | Challenge execution / adversarial verification | `PARTIAL` | `challenge_runner.ex` 904 L; `soak_test.ex` 916 L; chaos suites; 14 adversarial/boundary/invariant test files | Campaigns not run against the production loop; the six certification tiers are not all executed against HEAD |
| 36 | **Constitutional participation graph** | **`IMPLEMENTED` — corrected: EXISTS** | `crav/participation_graph.ex` 382 L: aggregates process mailbox statistics, telemetry handler counts, `SubsystemRegistry` heartbeats and ETS sizes into per-subsystem `participation_score`; emits `[:tiannara, :crav, :participation, :computed]` | It measures *whether a subsystem is doing work*; it does **not** yet map *who can act / who constrains / where authority enters* — the authority-topology half is pending |
| 37 | Observatory as operating console | `PARTIAL` (UI-first) | 27 LiveViews (**measured**, not 39), `MissionControl`, channels, controllers, `TiannaraWeb.Endpoint` live | UI sits on a thin observation layer; must be re-based on the `LiveProjection` contract before it can be called authoritative |
| 38 | Meta-level self-understanding | `PARTIAL` | `os/{program_self_evaluation,speciation_detector,state_jtms}`, `meta_cognition`, `epistemic_mirror/*`, `sentinel/d2/*`, `meta_governor`, `omega/capability_briefing` | No demonstrated self-model answering "what am I capable of / what evidence supports it / is it reachable" as a governed capability |
| 39 | Constitutional entropy / drift accounting | `PARTIAL` | `os/kernel/{constitutional_entropy_tracker,constitutional_drift_journal}`; `stabilization/olef/entropy_tracker` (EVID-0003 `IMPLEMENTED`); live ETS `conservation_laws` (6), `law_history` (6) | No governed entropy accounting across architecture/dependency/runtime/knowledge; not surfaced in certification |

**Tally:** `IMPLEMENTED` 6 · `PARTIAL` 27 · `STUB/THEATRICAL` 1 · `UNVERIFIED` 2 · absent-by-design (research extensions left out of scope) 3.
*(2026-09-23 update: family 4's theatrical half remediated — its constant verdicts now fail closed;
net shift `STUB/THEATRICAL` → `PARTIAL`: **6 / 28 / 0 / 2 / 3** = 39.)*

---

## 5. The causal loop, edge by edge

The target-state loop is not one thing; it is 15 edges. Measured status of each:

```
human objective
   │  ✅ CEL MissionDirector present            → PARTIAL
perception / ingestion
   │  ✅ LiveProjection + ReadOnlyHTTP (loopback) → PARTIAL
reality model
   │  ✅ UnifiedRealityGraph/WoldModel live      → PARTIAL (5 s timeout)
knowledge
   │  ✅ institutional memory, knowledge flow    → PARTIAL
epistemic assessment
   │  ❌ no refusal-of-unsupported-claim path    → PENDING
governance
   │  ✅ council, invariants, approval queue     → PARTIAL (durability defect)
planning
   │  ✅ CEL planner + priority engine           → PARTIAL
engineering
   │  ✅ ESAP compiler (single backend)          → PARTIAL
authorization
   │  ✅ RealExecution fails closed + grants     → PARTIAL (nothing mints grants)
execution
   │  ❌ no governed terminal consumer           → PENDING
external consequence
   │  ⚠️ loopback read-only only                 → PENDING (write)
observation
   │  ✅ LiveProjection                          → PARTIAL
reality update
   │  ✅ WorldMutationEngine                     → PARTIAL
knowledge update
   │  ✅ memory + provenance                     → PARTIAL
health verification
   │  ⚠️ nominally present, self-reported        → BLOCKED BY D-C
continuous improvement
      ✅ AgencyLoop live                          → PARTIAL
```

**Verdict on the loop: NOT DEMONSTRATED.** Three edges are missing outright (`epistemic assessment`
as a refusal mechanism, `execution` as a governed sink, mutating `external consequence`), and the
`health verification` edge cannot be trusted until **D-C** is fixed. The U0 bounded single-trace
mission therefore still cannot be constructed.

---

## 6. Corrections to previous audit statements (lineage preserved)

Per the constitutional rules, classifications are **not** silently upgraded or downgraded. Both
directions are recorded:

| Earlier statement | Corrected finding | Direction |
|---|---|---|
| "Live state reconstruction — MISSING; no `live_projection` anywhere in `lib/`" (baseline §3, row 20) | `observatory/live_projection.ex` exists (90 L), is a booted child (`application.ex:102`), and has a fresh test | **UPGRADE** correctness of my own prior statement — the module was added in the working tree after that row was written |
| "Constitutional participation graph — MISSING; no participation-graph module" (baseline §3, row 36) | `crav/participation_graph.ex` (382 L) exists and computes real participation scores from mailbox/telemetry/ETS data | **UPGRADE**; pending part narrowed to the authority-topology half |
| "External world interface — MISSING; no HTTP client at all" (baseline §3, row 25) | Bounded read-only egress **and** ingress exist via `:inets`/`:httpc`; the *mutating* egress path is what remains absent | **UPGRADE**; claim narrowed to write egress |
| Production start path depends on the unbooted `TiannaraRuntime` CPL | Hard dependency **removed**; `TiannaraRuntimeWeb.Endpoint` is guarded by `Code.ensure_loaded?` (`mix/tasks/tiannara.start.ex:360-363`) | **UPGRADE** |
| Profile requirement `DEMO / PERSONAL / RESEARCH / SAFE` | `RESEARCH` and `SAFE` (`safe-mode`) exist; `DEV / PRODUCTION / BENCHMARK / DISTRIBUTED` also exist; **`DEMO` and `PERSONAL` do not** | **PARTIAL UPGRADE** |
| "39 LiveViews" (baseline §3, rows 19, 38) | **27** LiveViews measured under `lib/tiannara/web/live` | **DOWNGRADE** |
| "The constitution gate swallows failures into an all-1.0 default; gates cannot fail" (§1.3, baseline §7.2 F-A mechanics) | The failure *mechanics* are now fail-closed (kernel `unavailable/1`, sequencer no more `catch → :pass`, stubs refused at the constitution gate); measured boot `failed → ready` only after `mission_director`'s real `:badarith` was root-caused — i.e. the gate demonstrably gates | **CORRECTED (mechanics); score *values* remain self-reported — B12 open** |
| "61 top-level children" (baseline §2 live measurement) | **Measured 63** (dev probe 2026-09-23): 61 (HEAD) + `Observatory.LiveProjection` (09-22 remediation, uncommitted) + `Tiannara.CTL.CausalRegistry` (this pass) — `git diff application.ex` shows exactly these two child additions, closing the arithmetic; probe line `asc_enabled=true, 63 top-level children` / `Status: ready` | **UPDATE (measured)** |
| "`Tiannara.CTL.CausalRegistry` defined twice" (baseline §2.1 Finding D) | Duplicate **eliminated 2026-09-23**: the `Tiannara.Ctl.CausalRegistry` case-twin stub was deleted after its beam-file collision was proved; exactly one definition remains (only case-twin among 2,193 modules) | **UPDATE** |
| "13 modules declare `use Tiannara.Stub`" (baseline §2.1 Finding E) | Now **12** — `stubs/causal_registry.ex` deleted with D-B remediation; the remaining 12 honest stubs are unchanged | **UPDATE** |
| "\"Nothing mints grants\"" (this table's row 16, originally from MC003) | B4 remediated 2026-09-22: `Authorization.human_grant/2-3` + `AuthenticatedHumanIdentity` required at both delivery APIs; coverage remains narrow (row 16 pending edge) | **CORRECTED** |

No historical evidence, failure ID, certificate or remediation record has been rewritten.

---

## 7. Shortest evidence-backed path (ordered by risk removed per unit of effort)

Each step is a *smallest corrective change* that converts an unproven claim into measured capability.
Do not implement a whole architectural layer because a document describes it.

| Order | Action | Why first | Gate that must go green |
|---|---|---|---|
| **1** | **D-C — make gates validate behaviour, not self-report.** Require each service's `constitutional_score/0` to be accompanied by executed evidence; make `:unavailable`/`:stub` services report a non-passing score; have the kernel cross-check declared `provides:` against actual returned results **[PARTIAL 2026-09-23: fail-closed mechanics landed — raising/non-struct/absent scores now fail via `unavailable/1`, explicit stubs refused at the constitution gate, silent `catch → :pass` removed (D-A9), first fabricated-through-catch scorer root-caused (D-A10); independent recompute of score values and `provides:` cross-check still open = B12]** | Everything downstream inherits gate integrity. Without this, every later "PASS" is unproven and Wave 6 is meaningless | partially green: a deliberately broken scorer **fails** admission (proven, `boot_sequencer_gate_honesty_test.exs`); value-level cross-check not yet |
| **2** | **D-B — delete the stub alias from the validation path** (`ctl/branch_validator.ex:7`) and make branch validation fail closed while `CTL.CausalRegistry` has no implementation **[EXECUTED 2026-09-23 — deeper than specified: case-twin beam collision proved as root cause, stub file deleted, real registry implemented as a stateful GenServer + booted as a child, threshold config-driven fail-closed; 8 regression tests green]** | A validator whose verdict is a constant is an authority hole | ✓ green: branch comparison against the real registry; constant returns removed; unregistered branches fail closed (`ctl_branch_validator_test.exs`, 8/8) |
| **3** | **D-A2/D-A3 — quarantine or implement the domain organs.** Make the 20 empty `generate_hypotheses/1` and 17 constant `simulate/2` return `:unavailable` until real **[EXECUTED (simulate/validate half) 2026-09-23 — 18 constant `simulate/2` + 16 constant `validate/1` quarantined to named `{:error, …unavailable}` fail-closed returns; real computations preserved; `domain_quarantine_test.exs` 5/5 green. D-A2 empty organs unchanged (B11); residual constant `evaluate/1`/`metrics/0` catalogued as D-A11]** | Removes fabricated domain authority (`:flight_worthy`, `constitutional_alignment: 0.94`) | ✓ green: no constant-valued `simulate/2`/`validate/1` remains callable (post-sweep grep: 0 constant patterns; 39-test combined batch) |
| **4** | **D-A6 — audit-log durability.** Root-cause `council_audit_log.dets.corrupted.*` (601 files) | The constitutional trail is the evidence base for #1 | zero corruption across 10 cold boots |
| **5** | **Test topology alignment.** Reconcile `start_supervised!(ASC.Core.Supervisor)` with `asc.enabled: true` | A red suite cannot certify anything | `mix test` green without weakening a single assertion |
| **6** | **Grant minting + one real governed sink.** One minting path, one terminal consumer, verified at the sink | Closes the authorization→effect edge end-to-end | one bounded mission with one trace ID, authorization evidence at the sink |
| **7** | **LiveProjection gap-recovery.** Only after #1–#6 | Named sub-capability genuinely absent | projection reconstructs after simulated gap |

### Do not spend tokens on, yet

More architecture documents · the 27 LiveViews · multi-backend generation · recursive
evolution / transcendence concepts · civilization-scale re-runs · symbolic/proof substrate.
And do **not** rewrite what is already real: CEL kernel, supervision tree, provenance engine,
council framework, CRAV archaeology, Crucible.

### Stop conditions currently in force

The remediation already present in the working tree is **uncommitted**. Committing it, choosing
branch topology, and any change that would make an external consequential action possible are
**authorization decisions** and are not taken here.

---

## 8. System matrix (implementation / integration / verification / production)

| System | Implementation | Integration | Verification | Production |
|---|---|---|---|---|
| Runtime & supervision | `IMPLEMENTED` | `IMPLEMENTED` | `PARTIAL` | `PARTIAL` |
| CEL kernel & gates | `IMPLEMENTED` | `IMPLEMENTED` | **`BROKEN`** (self-report, D-C) | `PARTIAL` |
| Constitutional council | `IMPLEMENTED` | `IMPLEMENTED` | `PARTIAL` | `PARTIAL` |
| Authorization / effect identity | `PARTIAL` | `PARTIAL` | `PARTIAL` | `PARTIAL` |
| Provenance | `IMPLEMENTED` | `PARTIAL` | `PARTIAL` | `PARTIAL` |
| Memory (ExecutiveMemory) | `IMPLEMENTED` | `PARTIAL` | `PARTIAL` | `PARTIAL` |
| Events (EventStore/EventBus) | `IMPLEMENTED` | `PARTIAL` | `PARTIAL` | `PARTIAL` |
| Reality / world model | `PARTIAL` | `PARTIAL` | `PARTIAL` | `PARTIAL` |
| Replay | `THEATRICAL` → fail-closed | `UNUSED` | `PARTIAL` | **`ABSENT`** |
| Knowledge / research organs | `STUB` | `UNUSED` | `UNVERIFIED` | **`ABSENT`** |
| Engineering / ESAP | `PARTIAL` | `PARTIAL` | `PARTIAL` | `PARTIAL` |
| CIS / immune | `PARTIAL` | `PARTIAL` | `PARTIAL` | `PARTIAL` |
| Self-monitoring / archaeology | `IMPLEMENTED` | `IMPLEMENTED` | `PARTIAL` | `PARTIAL` |
| Self-repair / Crucible | `PARTIAL` | `PARTIAL` | `PARTIAL` | `PARTIAL` |
| Observation / LiveProjection | `PARTIAL` | `IMPLEMENTED` (booted) | `PARTIAL` | `PARTIAL` |
| External world | `PARTIAL` (loopback read-only) | `PARTIAL` | `PARTIAL` | **`ABSENT`** |
| Execution / external sink | `PARTIAL` | `UNUSED` | `UNVERIFIED` | **`ABSENT`** |
| Certification | `PARTIAL` | `PARTIAL` | **`NOT EXECUTABLE`** | **`ABSENT`** |
| Deployment / profiles | `PARTIAL` | `PARTIAL` | `UNVERIFIED` | **`ABSENT`** |

---

## 9. Executive status

| Question | Answer |
|---|---|
| Production readiness | **FAIL** |
| Demo readiness | **FAIL** (`DEMO` profile does not exist) |
| Personal deployment readiness | **FAIL** (`PERSONAL` profile does not exist; start requires PostgreSQL/Redis/NATS) |
| End-to-end organism loop | **FAIL** (three edges missing; health edge untrustworthy) |
| Critical blocking defects | **2** (D-C gate self-report; D-B stub in validation path) |
| UNKNOWN / UNVERIFIED production requirements | still `UNVERIFIED`: civilization scale, distributed node loss, long-duration soak at HEAD |

**Bottom line:** Tiannara today is a **real constitutional runtime with a theatrical research
plane**. The runtime's bones are genuine and unusually well-instrumented; what is missing is
not architecture but the property that makes architecture meaningful — *that a system which cannot
do a thing cannot claim it*. Fix D-C and D-B before adding a single capability.
---

## 10. Archived prior ledger — unique sections preserved (lineage)

> Consolidated 2026-09-22. `docs/production_capability_ledger.md` duplicated this file's
> 39-capability table under a parallel C-series of finding IDs (single-source-of-truth
> violation). Its unique measurement, defect, queue and limitation sections are preserved
> verbatim below. Its §2 (C-series 39-row table) is superseded by §4 above and was **not**
> carried forward: rows were already stale at consolidation (e.g. it reported LiveProjection
> MISSING while `lib/tiannara/observatory/live_projection.ex` + its test exist). C-series
> IDs are enumerated in §10.5.

### 10.1 Baseline measurements (production ledger §1)

## 1. Baseline measurements (measured, not inferred)

### 1.1 Live boot probe

Method: `mix run --no-halt`, then ERPC probe over `--sname` distribution; process
tree and ETS census read from the live node.

| Measurement | Value |
| --- | --- |
| `Tiannara.Application` supervised children | **61** (31 supervisors / 30 workers) |
| Registered process names | 473 |
| Live processes | 773 |
| ETS tables | 196 |
| Node memory | 102 MB |
| CEL EOS boot report | `status: :ready`, **34 services `:ok`**, 1,874 ms |
| CEL gates per service | 5 (`resource`, `health`, `capability`, `constitution`, `dependency`) |
| Ω health aggregator self-report | `status: :partial`, **5/6 subsystems healthy** |
| Ω agency loop | live: `observe → analyze → investigate → communicate → improve → learn`, 5 loops, 50 observations |
| RepairLibrary | live ETS, **18,016** patterns |

### 1.2 Activation census (declared vs actually loaded)

| Measurement | Value |
| --- | --- |
| Modules loaded in the VM | 864 |
| `Tiannara.*` modules loaded | 383 |
| `defmodule` declarations in `lib/` | 1,847 |
| **Approximation of activation** | **≈ 21 %** |

This ~21 % figure is the single most important structural fact in the repository:
the overwhelming majority of declared modules are compiled and dormant at boot.
It is why capability discovery/archaeology (row 29) is load-bearing rather than
cosmetic, and why *"there is code for it"* must never be read as *"Tiannara can do it."*

### 1.3 Test-suite state

| Suite | Result |
| --- | --- |
| Full `mix test` (pre-remediation) | **NOT GREEN** — ≥99 failures, 204 crash markers |
| Full-suite root cause (isolated) | `{:already_started, pid}` — tests called `start_supervised!(Tiannara.ASC.Core.Supervisor)` while `asc.enabled: true` already boots it globally |
| Focused remediation batch (12 files) | **22 tests, 1 failure** |
| That 1 failure | **fixed and re-verified → 7 tests, 0 failures** (§3, finding C10) |

The full-suite root cause is a *topology alignment* defect, not a missing capability.
Per program rule 15 it must be fixed by aligning the topology — **never** by
disabling ASC or weakening assertions.

---


### 10.2 Defects from that pass — C-series (production ledger §3)

## 3. Defects found in this pass (new, with exact evidence)

| ID | Severity | Defect | Evidence |
| --- | --- | --- | --- |
| **C1** | **CRITICAL** | **The constitutional gate is self-certifying by construction.** The Kernel asks each service for *its own* constitutional score and swallows any failure into a default: `check_constitutional_score(spec)` → `apply(mod, fun, args)` inside `try` with `catch _, _ -> ConstitutionalScore.default(spec.id)`. `Tiannara.World.ReplayEngine` returned a hardcoded `1.0` and consequently **passed all five gates** while being theatrical. This violates the repository's own rules — *Validation must never trust runtime output or self-reported metrics* and *generators never certify themselves* (`.clinerules`: Validation Rules, Certification Rules) | `lib/tiannara/cel/kernel.ex:136-143`; registry wiring `lib/tiannara/cel/kernel/service_registry.ex:236-240`; contrast `lib/tiannara/world/replay_engine.ex:55-77` |
| **C2** | HIGH | **`Tiannara.StubRegistry` has no consumers.** The macro records every stub call, but nothing — no gate, no health check, no census, no certification — ever reads it. Stub instrumentation is dormant. (Partially mitigated: the new boot capability gate detects *macro* stubs structurally via `__tiannara_stub__/0`.) | `lib/tiannara/stubs/stub_registry.ex`; only referents `lib/tiannara/stubs/stub.ex:36-42` |
| **C3** | HIGH | **`Tiannara.Ctl.CausalRegistry` module-name case mismatch binds a caller to a stub instead of the real module.** The real registry is `Tiannara.CTL.CausalRegistry` (`ctl/causal_registry.ex:1`); the caller's alias resolves to `Tiannara.Ctl.CausalRegistry`, which is the decommission stub (`stubs/causal_registry.ex:1`). Latent, not live: `Tiannara.Ctl.BranchValidator` has **zero callers**. | `ctl/branch_validator.ex:7,14-15` vs `ctl/causal_registry.ex:1` and `stubs/causal_registry.ex:1` |
| **C4** | HIGH | **A stub returns a fabricated measurement presented as a reading:** `get_branch/1` → `{:ok, %{stress: 0.0}}`. A caller cannot distinguish "measured stress 0.0" from "no data", which is precisely the failure the Phase 17.8+ Proof Rule forbids (fallback values that let execution proceed when evidence is absent). | `lib/tiannara/stubs/causal_registry.ex:4-6` |
| **C5** | HIGH | **Success-shaped stubs on the self-repair path:** `{:ok, %{patch_id: …, type: :stub}}` and `{:ok, :stub}`. Outer shape is success, so a `{:ok, X}` caller proceeds. Self-repair is the architecture's most distinctive claim and its implementation is a Phase-H stub. | `asc/repair/pipeline.ex:24,27`; `asc/operations/civilization.ex:30-31,35` |
| **C6** | **CRITICAL** | **Fabricated domain evidence across the scientific layer.** 20/31 domain modules: `generate_hypotheses(_context), do: {:ok, []}`. 18 modules: `validate(_experiment), do: {:ok, %{valid: true}}` — unconditional. 20 modules: `simulate/2` returns a hardcoded verdict atom. Two modules fabricate *quantitative* results: `governance.validate` → `constitutional_alignment: 0.94`; `medicine.validate` → `trial_phase: :phase_2`. Under the Phase 17.8+ Proof Rule these are prohibited inputs (hardcoded domain measurements and theory rules presented as evidence). | `lib/tiannara/domains/*.ex` (measured: 20 of 31 files affected; e.g. `governance.ex`, `medicine.ex`, `physics.ex`) |
| **C7** | MEDIUM | **Advertised capability is not reconciled with runtime capability.** `ReplayEngine` is registered with `provides: [:deterministic_replay, :sandboxed_execution, :state_recovery]` while `replay/4` returns `{:error, :replay_source_unavailable}`. The registry is therefore not a truthful capability manifest. | `cel/kernel/service_registry.ex:238` vs `world/replay_engine.ex:69-72` |
| **C8** | MEDIUM | **`FitnessEvaluator.compare_fitness/2` divides by the baseline score without a zero guard** → `ArithmeticError` (badarith) whenever `baseline_fitness == 0`. A constitutional fitness comparison that crashes on a legitimate zero baseline. Also: `calculate_confidence/1` starts from a hardcoded `0.7` and `estimate_lifespan/1` from `base_months 12` — hardcoded weights in a constitutional evaluator. | `lib/tiannara/os/governance/fitness_evaluator.ex` (`compare_fitness/2`, `calculate_confidence/1`, `estimate_lifespan/1`) |
| **C9** | MEDIUM | **`Tiannara.CIS.validate_plan/1` returns `{:ok, plan}` unconditionally**, regardless of plan content — a fake-success path in the immune system. | `lib/tiannara/cis.ex` |
| **C10** | **CRITICAL (fixed & verified)** | **The research loop crashed on unknown-workflow events.** `handle_workflow_failure/2` and `update_experiment_on_workflow_done/3` passed the **entire GenServer state** to `find_experiment_by_workflow/2`, so `Enum.find_value` iterated unrelated state entries (including a `DateTime`) and raised `KeyError: key :workflow_ids not found in ~U[...]`, crashing `handle_info` instead of ignoring the event. Both call sites corrected to `state.experiments`; payload access hardened to `Map.get/2` (because `event_payload/1` can legitimately return `%{}`). Verified: `7 tests, 0 failures`. | `lib/tiannara/phase4/experiment_orchestrator.ex:491,550` (was), `:609-613` (contract note), fix verified via `test/tiannara/phase4/event_bus_envelope_test.exs` + `test/tiannara/phase4/experiment_orchestrator_test.exs` |

### 3.1 The dangerous pair

C1 and C6 compound. C6 puts fabricated results into the scientific layer; C1 makes the
gate chain accept a service's own assertion of constitutional health. Together they
mean a subsystem can be **both hollow and certified**. Closing C1 (independent
recomputation of constitutional score) is therefore higher value than any single
domain implementation, because it restores the gate's authority for *every* future fix.

---


### 10.3 Pending work queue as recorded then (production ledger §4)

## 4. Pending work queue (ordered by evidence value per unit of effort)

1. **C1 — make the constitutional gate independent.** Recompute the score in the Kernel
   (or from ledger evidence) instead of applying the service's own function; make
   `catch` produce a *failing* score, never a passing default. Restores gate authority.
2. **C6 — de-fabricate the domain layer.** Convert the 18 unconditional
   `validate → {:ok, valid: true}`, 20 hardcoded `simulate/2` verdicts and 20
   `{:ok, []}` hypothesis generators into explicit `{:unavailable, reason}` + named
   constitutional failure artifacts. Removing a false capability beats implementing
   a new one.
3. **C5 — stop success-shaping stub returns** on the repair path; make them named
   failures so nothing downstream can treat them as repairs.
4. **Full-suite topology alignment** (`{:already_started, pid}`) — fix the topology,
   never the assertions. This is what turns "≥99 failures" into a usable regression gate.
5. **C7 — reconcile the service registry** with runtime capability, so the registry
   becomes a truthful manifest (and the census can fail on drift).
6. **Corrupted audit-log residue** — 601 `council_audit_log.dets.corrupted.*` files;
   root-cause the boot-time corruption, then archive deliberate remediation evidence.
7. **Graph recovery after kill** (U8) and the `UnifiedRealityGraph` 5 s call timeout.
8. **Grant minting** — nothing mints `HumanDelivery.Authorization` grants yet, so
   the authorized-execution path has no production entrance.

**Explicitly out of scope for v1** (do not spend tokens): implementing further
historical architecture documents, the 27 LiveViews' polish, multi-backend code
generation, recursive evolution/transcendence concepts, and re-running
civilization-scale simulations.

---


### 10.4 Notes and honest limitations (production ledger §5)

## 5. Notes and honest limitations

**N1 — version number.** `mix.exs` declares `version: "0.3.5"`, which does not match
the "v1" target language. This is a naming/governance question for the certification
artifacts, not a capability question; flagged, not changed.

**N2 — classification asymmetry.** Rows marked `IMPLEMENTED` were confirmed by *live
observation* (boot probe, ERPC calls, passing contract tests). Rows marked `PARTIAL`
were confirmed to have real code that was *not* exercised end-to-end. Rows marked
`UNVERIFIED` were not observable from tracked artifacts at all. No row was upgraded
on the strength of documentation.

**N3 — the ~21 % activation figure is an approximation** (loaded modules / declared
modules), not a precise capability metric: some declared modules are CLI tasks,
test helpers, or deliberately dormant. It is directionally decisive even so.

**N4 — this ledger does not certify anything.** Per the certification rules, a
certificate requires an independent auditor that consumes only ledger, evidence,
replay and manifests. This document is an evidence-bearing *classification*, and it
deliberately leaves the certification decision open.

**N5 — lineage preserved.** Prior failure IDs, the MC-series remediation records,
the U-series audit caveats and the 601-file corruption residue remain untouched.
Nothing historical was rewritten to make the project look cleaner.

### 10.5 C-series finding IDs (production ledger §3; preserved verbatim in §10.2 above)

| ID | One-line title (full text in §10.2) | Severity |
|---|---|---|
| C1 | Constitutional gate is self-certifying by construction | CRITICAL |
| C2 | `Tiannara.StubRegistry` has no consumers | HIGH |
| C3 | `Tiannara.Ctl.CausalRegistry` case mismatch binds caller to the stub | HIGH |
| C4 | Stub returns fabricated `stress: 0.0` measurement | HIGH |
| C5 | Success-shaped stubs on the self-repair path | HIGH |
| C6 | Fabricated domain evidence across the scientific layer | CRITICAL |
| C7 | Advertised `provides:` not reconciled with runtime capability | MEDIUM |
| C8 | `FitnessEvaluator.compare_fitness/2` badarith on zero baseline | MEDIUM |
| C9 | `CIS.validate_plan/1` returns `{:ok, plan}` unconditionally | MEDIUM |
| C10 | Research loop crashed on unknown-workflow events | CRITICAL (fixed & verified) |

The superseded production-ledger §2 table was a duplicate classification of the same
39 capability families now recorded in §4 (under D-series row references), and several
of its rows were already stale when consolidated. It carried no findings beyond those
row classifications, so it was retired rather than copied — this is the one piece of
the prior ledger not preserved verbatim, and it is recorded here as deliberately
retained in supersession, not silently dropped.
