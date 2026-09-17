# EFDI D4 — Classification Matrix (live repository scan)

Status: COMPLETE (read-only scan of `lib/`, `tiannara_runtime/`, `certification/`)
Rule applied: **never NEW where canonical capability can safely be reused** (§2).
This supersedes the rows previously marked `UNKNOWN (REPO_SCAN_PENDING)` in the
D4 Gate Design Package — the codebase was available, and the rows below cite the
actual modules found.

Legend: **REUSE** = call canonical module as-is · **ADAPTER** = thin read-only
boundary over canonical module · **EXTEND** = extend the established pattern ·
**NEW** = genuinely absent, must be built minimal · **DEFERRED** = explicitly out of
scope (D5/D6 boundary).

| # | Capability | Classification | Evidence (module) |
|---|---|---|---|
| C-01 | Causal graph substrate | **REUSE** | `TiannaraRuntime.WorldModel.Ontology.CausalGraph` (do_calculus_level, graph_fingerprint), `WorldModel.causal_graph` |
| C-02 | Causal structure learning / discovery | **REUSE** | `WorldModel.CausalDiscovery.*`, `WorldModel.Pipeline.StructureLearning` |
| C-03 | Causal graph validation (nodes, acyclicity, lineage, replay) | **REUSE** | `WorldModel.Validation.Validator`, `WorldModel.Pipeline.ModelCertification` |
| C-04 | Do-calculus validation | **REUSE** | `WorldModel.CausalDiscovery.GraphValidator.validate_do_calculus/1`, `CausalGraph.do_calculus_level` |
| C-05 | Intervention specification (do-operator) | **ADAPTER** | `WorldModel.Ontology.Intervention` (atomic/conditional/stochastic), `WorldModel.Counterfactual.Intervention` |
| C-06 | Intervention effect evaluation | **REUSE** | `Tiannara.REA.OrbitMemory.CausalDo.evaluate_do_intervention/3` |
| C-07 | Causal graph stabilization / paradox detection | **REUSE** | `Tiannara.Stabilization.CTL` (`validate_causality/1`, `detect_paradox/1`, `stabilize_causality/1`) |
| C-08 | Counterfactual world / branch construction | **REUSE** | `WorldModel.Counterfactual.{CounterfactualEngine, CounterfactualWorld, BranchGenerator, AlternativeTimelineBuilder, DivergencePoint}` |
| C-09 | Counterfactual registry / store | **REUSE** | `WorldModel.Counterfactual.CounterfactualRegistry` (ETS), `CounterfactualArchaeology` |
| C-10 | Counterfactual replay / determinism / fingerprint | **REUSE** | `WorldModel.Counterfactual.{CounterfactualReplay, CounterfactualEvidence}`, `lib/tiannara/world/replay_engine.ex` |
| C-11 | Branch tree / comparison | **REUSE** | `WorldModel.Counterfactual.{BranchNode, BranchComparison, BranchComparator}` |
| C-12 | Counterfactual-world simulation forking | **REUSE** | `lib/tiannara/simulation/multiworld/{world_forker,counterfactual_explorer,world_comparison_analyzer,constraint_relaxer}.ex` |
| C-13 | Temporal "what-if" state query | **REUSE** | `Tiannara.World.TemporalWorldEngine.counterfactual_state/2` |
| C-14 | Causal attribution (world/ruin domain) | **REUSE** | `Tiannara.REA.Causal.Attribution.attribute/1`, `Simulation.MultiWorld.CounterfactualExplorer.attribute_causality/3` |
| C-15 | World-state snapshots (baselines) | **REUSE** | `Tiannara.World.{VersionManager, SnapshotManager}`, `Executive.Snapshot` |
| C-16 | Event sourcing / lineage | **REUSE** | `Tiannara.Executive.{Event, EventStore, EventBus, Lineage}`, `World.ProvenanceEngine` |
| C-17 | Evidence store + provenance refs | **REUSE** | `Tiannara.Evidence.{Provenance, HistoricalQuarantine, CertificationGate}` |
| C-18 | Decision snapshots (immutable baseline) | **REUSE** (read-only) | `Tiannara.Forecasting.{Decision, DecisionSnapshot, DecisionRegistry}` |
| C-19 | Outcome records (hindsight-isolated) | **REUSE** | `Tiannara.Forecasting.{Outcome, DecisionReview}`, `Contracts.DecisionOutcome` |
| C-20 | Probability substrate | **REUSE** | `Tiannara.Math.Probability`, D2 `Forecast` (probability+confidence+uncertainty) |
| C-21 | Base rates / reference classes | **ADAPTER** | `Tiannara.Forecasting.BaseRateEngine` |
| C-22 | Independent verification pattern | **EXTEND** | `certification/forecasting/verifiers/EFDI_D3_independent_verification.py` (V1–V19), `EFDI_D{1,2,3}_(CONTRACT|AUTHORIZATION).md` conventions |
| C-23 | Status ontology (OBSERVED/HYPOTHETICAL/COUNTERFACTUAL/…) for decision records | **NEW** | none found — hin layer over C-08 store semantics |
| C-24 | Luck/skill attribution (decision layer) | **NEW** | none found — D3 `DecisionReview` freezes `:not_attributed`; borrow C-14 patterns |
| C-25 | Survivorship / selection detector + denominator registry | **NEW** | none found |
| C-26 | Regression-to-mean analyzer (non-causal) | **NEW** | none found |
| C-27 | Temporal firewall verifier (D4→D3) | **NEW** | extends D3 `consistent?/2`, `guard_outcome/2` + V-verifier pattern |
| C-28 | Noise measurement | **DEFERRED → D5** | only `ValueOfInformation.decision_sensitivity` exists |
| C-29 | Institutional lessons / memory | **DEFERRED → D6** | `SignalValue` outcome-provider hook only |

## Consequences for the D4 contract

1. The design package's assumption that D4 must build its own causal graph, do-
   operator, geometry, branch/registry, replay, simulation, event store, snapshots,
   evidence, probability, or certification machinery is **superseded**. All exist.
2. The buildable, genuinely-new D4 surface is small and decision-context-specific:
   status ontology (C-23), luck/skill attribution (C-24), survivorship/selection
   (C-25), RTM (C-26), temporal firewall (C-27) — every one composed over canonical
   REUSE rows.
3. The `TiannaraRuntime.WorldModel.*` substrate lives in the separate
   `tiannara_runtime` Mix project. The implementation contract must either (a) wire
   that dependency into the forecasting build, or (b) compose the main-app
   equivalents (`TemporalWorldEngine.counterfactual_state/2`,
   `MultiWorld.fork_counterfactual/3`, `CausalDo`, `REA.Causal.Attribution`,
   `UnifiedRealityGraph`, `ReplayEngine`). Both satisfy §2; (b) avoids cross-project
   coupling. Decision recorded in the D4 contract, not in code.
4. Anything deeper than `ValueOfInformation.decision_sensitivity` is D5 territory:
   D4 must not emit noise scores; D6 territory: D4 must not emit lessons.