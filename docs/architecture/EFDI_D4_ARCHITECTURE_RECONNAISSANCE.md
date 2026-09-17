# EFDI D4 — Counterfactual / Attribution: Architecture Reconnaissance

Status: COMPLETE (live repository scan)
Scope: Survey all existing causal / counterfactual / intervention / do-calculus /
attribution / selection / regression / replay infrastructure before implementing
D4. Classify each capability as **REUSE / ADAPTER / EXTEND / NEW** so D4 composes
existing Tiannara infrastructure and does NOT create a parallel causal mathematics
or a parallel decision ontology.

## Central D4 invariant

> A counterfactual is a labeled analytical record — never a fact, never an edit to
> observed history, never a lesson, and never an execution interface.

Capitalized into:
- COUNTERFACTUAL ≠ FACT (`OBSERVED` assignable only via the D1 ingestion path)
- CORRELATION ≠ CAUSATION (intervention explicitness, unsupported-assumption flags)
- LUCK ≠ SKILL (`NOT_ATTRIBUTED` default + evidence thresholds)
- BAD OUTCOME ≠ BAD DECISION (D3 evaluation sealed from outcomes — temporal firewall)
- UNCERTAINTY ≠ ERROR (`UNKNOWN/UNDERDETERMINED` first-class)
- HISTORY ≠ HINDSIGHT (no post-outcome data in decision-time evaluation)

## Epistemic correction to the D4 Gate Design Package

The D4 Gate Design Package declared: *"Actual Tiannara codebase — not available in
this session — UNKNOWN until scan"* and marked I-01/I-02/I-03/I-04/I-11/I-13/I-14
as `UNKNOWN (REPO_SCAN_PENDING)`, with several as "likely NEW". **That premise was
false.** The repository is available in this session and the inventory below is the
result of a completed read-only scan (grep/glob over `lib/`, `tiannara_runtime/`,
`certification/`). Every row previously `UNKNOWN` is now classified with a concrete
module citation. The material consequence: **the causal graph, intervention/do-
operator, counterfactual branching, scenario simulation, replay, event-sourcing,
and certification-harness machinery already exists.** The genuinely NEW surface for
D4 is much smaller than the design package proposed and is concentrated in the
*decision-context* record layer (status ontology, luck/skill attribution,
survivorship/selection, RTM, temporal firewall) — reusing, not rebuilding, the world-
model counterfactual substrate beneath it.

## Classification matrix (result of live scan)

| Capability | Module(s) found | Classification | D4 role |
|---|---|---|---|
| Causal graph substrate | `TiannaraRuntime.WorldModel.Ontology.CausalGraph` (nodes, edges, latent_variables, confounders, do_calculus_level 1/2/3, graph_fingerprint); `WorldModel` holds `causal_graph` | **REUSE** (substrate) | D4 references/accepted DAGs; never re-learns structure |
| Causal discovery / graph validation | `TiannaraRuntime.WorldModel.CausalDiscovery.GraphValidator.validate_do_calculus/1`; `Pipeline.{StructureLearning, EquationLearning, ModelCertification, ModelAssembly}`; `Tiannara.World.UnifiedRealityGraph`; `Tiannara.Stabilization.CTL` (`validate_causality/1`, `stabilize_causality/1`) | **REUSE** | D4 defers graph soundness/do-calculus validation to canonical substrate |
| Intervention / do-operator semantics | `TiannaraRuntime.WorldModel.Ontology.Intervention` (do_operator: atomic \| conditional \| stochastic, target_variable, set_value); `...Counterfactual.Intervention`; `Tiannara.REA.OrbitMemory.CausalDo.evaluate_do_intervention/3` | **ADAPTER** | explicit InterventionSpec (OBSERVE vs SET) maps to existing do-operator semantics |
| Counterfactual branching / records | `TiannaraRuntime.WorldModel.Counterfactual.*` (CounterfactualEngine, CounterfactualWorld, CounterfactualRegistry, CounterfactualReplay, CounterfactualValidation, CounterfactualEvidence, CounterfactualArchaeology, BranchGenerator, BranchNode, BranchComparison, BranchComparator, AlternativeTimelineBuilder, DivergencePoint, Intervention, ScenarioOutcome); main-app `Tiannara.World.TemporalWorldEngine.counterfactual_state/2`; `Tiannara.Simulation.MultiWorld.{WorldForker, CounterfactualExplorer}` (`fork_counterfactual/3`, `explore/3`); `Tiannara.Core.WorldModel.TimelineManager.create_counterfactual/3` | **REUSE / ADAPTER** | content-addressed branch-from-baseline already exists (parent_fingerprint, replay_fingerprint, ensure_id hashing); D4 binds the *decision snapshot* as the baseline |
| Do-calculus / causal-effect evaluation | `CausalDo.evaluate_do_intervention`; `validate_do_calculus/1` (GraphValidator) | **REUSE** | D4 never computes a parallel intervention calculus |
| Scenario / simulation engines | `Tiannara.CEL.Services.ExecutiveDigitalTwin.{simulate_strategy, run_counterfactual}`; multiworld simulation; `Tiannara.Forecasting.FutureSimulator` (planner.ex); `WorldStateSynchronizer` (simulation.completed) | **REUSE** | D4 consumes read-only simulation results; zero execution interfaces |
| World-state snapshots | `Tiannara.World.{VersionManager, SnapshotManager, CanonicalWorldState}`; `Executive.Snapshot` | **REUSE** (read adapter) | baseline state referenced by hash/version; never written by D4 |
| Event sourcing / provenance | `Tiannara.Executive.{Event, EventStore, EventBus, Lineage}`; `Tiannara.World.ProvenanceEngine`; `Tiannara.Evidence.Provenance` | **REUSE** | D4 lineage events appended to EventStore; no parallel ledger |
| Evidence store + references | `Tiannara.Evidence.{Provenance, HistoricalQuarantine, CertificationGate}`; `Tiannara.Forecasting.Adapters.EvidenceImpl` | **REUSE** | assumption_evidence_map refs point into D1 evidence paths |
| Probability / Bayesian substrate | `Tiannara.Math.Probability`; D2 `Forecast` (probability + confidence + uncertainty) | **REUSE** | counterfactual outcome distributions are D2-compatible |
| Base rates / reference classes | `Tiannara.Forecasting.BaseRateEngine` | **ADAPTER** | D4 reference-class registry wraps D2 base-rate lookups |
| Decision snapshots (immutable) | `Tiannara.Forecasting.{Decision, DecisionSnapshot, DecisionRegistry, DecisionReview}` | **REUSE** (read-only) | D4 consumes snapshots read-only; temporal firewall at type+storage+verifier layers |
| Outcome records | `Tiannara.Forecasting.{Outcome, DecisionReview}`; `Contracts.DecisionOutcome` (`guard_outcome/2` hindsight isolation) | **REUSE** | post-decision outcome refs legal only in outcome/counterfactual fields |
| Uncertainty representation | D1 `Signal` (confidence + uncertainty), D2 `Forecast` | **REUSE** | D4 statuses map onto uncertainty; never collapse to 0/FALSE |
| Sensitivity analysis | `Tiannara.Forecasting.ValueOfInformation.decision_sensitivity/1` (D3) | **EXTEND** (D3) | robustness/noise decomposition deferred to D5 |
| Replay / determinism | `Tiannara.World.ReplayEngine`; `CounterfactualReplay` (fingerprints); D3 verifier live regression | **REUSE** | D4 determinism proofs reuse fingerprint + replay infra |
| Certification harness | `certification/forecasting/{verifiers, contracts, authorization}`; V1–V19 independent verifier pattern; `priv/tiannara/authorization/*.human.yaml` convention | **EXTEND** | V20–V35 no-trust verifier; D4-CONTRACT/D4-AUTHORIZATION |
| OBSERVED / HYPOTHETICAL / COUNTERFACTUAL status ontology (decision records) | world-model CF implies parent-vs-branch distinction; no decision-context record statuses | **NEW** (thin) | `CounterfactualRecord` statuses; never boolean collapse |
| Luck/skill attribution (decision layer) | `DecisionReview` freezes `attribution: :not_attributed`; `Tiannara.REA.Causal.Attribution` (ruin/causal context); `CounterfactualExplorer.attribute_causality/3` (world context) | **NEW** (borrow patterns) | bounded state machine, `NOT_ATTRIBUTED` default, thresholds |
| Survivorship / selection + denominator registry | none found | **NEW** | denominator registry; `UNKNOWN_SELECTION_EFFECT` first-class |
| Regression-to-mean analyzer | none found | **NEW** | non-causal by construction; no causal-claim field |
| Temporal firewall verifier (D4→D3) | D3 `consistent?/2`, `guard_outcome/2`; verifier pattern | **NEW** | external temporal lint + D3 snapshot hash recompute (V26) |
| Noise measurement | `ValueOfInformation.decision_sensitivity` only; no decomposition | **DEFERRED → D5** | D4 must not emit noise scores |
| Institutional lessons / memory | `SignalValue` references `:efdi_outcomes_provider` config (D6 hook); no lesson store | **DEFERRED → D6** | D4 must not emit lessons |

## Boundary principles (D4 never oversteps)

- Counterfactual output is **decision-support**, never autonomous verdict, never
  authorization, never execution. D4 exposes zero execution interfaces; AEO remains
  the sole executor.
- D4 writes **new records only**. Observed history, D3 decision snapshots, D1
  evidence, D2 forecasts, World Model state, EventStore core, CIS, Council, and AEO
  are never modified by D4.
- `OBSERVED` status is assignable only by the D1 ingestion path; no counterfactual
  node can be promoted to observed.
- No merge operation exists; counterfactuals are edges from a content-addressed
  baseline, never edits to it.
- No new probability calculus, no new causal calculus, no parallel world model, no
  D5/D6 outputs.
- Attribution never overreaches: default `NOT_ATTRIBUTED`; single outcomes cannot be
  attributed; correlation never promoted to influence without an intervention spec.

## Reuse rule (campaign §2)

Do NOT replace CausalGraph/CausalDiscovery/do-calculus, WorldModel counterfactual
pipeline, MultiWorld simulation, CausalDo, REA.Causal.Attribution, EventStore, D1
Evidence, D2 Forecast/BaseRate, D3 DecisionSnapshot. D4 composes them through
read-only adapters. Where the substrate lives in the separate `tiannara_runtime`
Mix project (`TiannaraRuntime.WorldModel.*`), the D4 implementation contract must
resolve the dependency wiring vs. composing the main-app substrate
(`TemporalWorldEngine.counterfactual_state/2`, `MultiWorld.fork_counterfactual/3`,
`CausalDo`, `REA.Causal.*`, `UnifiedRealityGraph`, `ReplayEngine`) — that is an
adapter decision, not a justification for new machinery.

## Integration contract

D1 Signal/Evidence → D2 Forecast/BaseRate → D3 DecisionSnapshot →
**D4 CounterfactualRecord / AttributionReport / SelectionEffectReport /
RegressionToMeanReport** (read-only inputs: snapshot by hash, world baseline by
version, evidence refs, reference classes) → lineage events → Executive/EventStore.
D4 NEVER feeds back into D3 evaluation (temporal firewall).