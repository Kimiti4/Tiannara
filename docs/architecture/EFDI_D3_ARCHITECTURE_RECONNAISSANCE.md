# EFDI D3 — Decision Intelligence: Architecture Reconnaissance

Status: COMPLETE
Scope: Survey all existing decision/action/authorization/AEO/CIS/Research/World Model
infrastructure before implementing D3. Classify each capability as
**REUSE / ADAPTER / EXTEND / NEW / UNKNOWN** so D3 composes existing Tiannara
infrastructure and does NOT create a parallel decision ontology.

## Central D3 invariant

> A decision must be evaluated using the information and uncertainty available
> when the decision was made, not hindsight.

Capitalized into: FORECAST QUALITY ≠ DECISION QUALITY ≠ OUTCOME QUALITY.
BAD OUTCOME → BAD DECISION (and GOOD OUTCOME → GOOD DECISION) are FORBIDDEN.

## Classification matrix

| Capability | Module(s) | Classification | D3 role |
|---|---|---|---|
| Decision struct (alternatives, EV, utility, risk, reversibility) | (none) | **NEW** | `Tiannara.Forecasting.Decision` |
| Decision engine (expected-value selection) | (none) | **NEW** | `Tiannara.Forecasting.DecisionEngine` |
| Decision registry (immutable + versioning) | `ForecastRegistry` (pattern) | **NEW** (mirror) | `Tiannara.Forecasting.DecisionRegistry` |
| Decision-time snapshot | (none) | **NEW** | `Tiannara.Forecasting.DecisionSnapshot` |
| Decision quality (ex-ante, hindsight-isolated) | `Calibration` (pattern) | **NEW** | `Tiannara.Forecasting.DecisionQuality` |
| Decision review / postmortem | (none) | **NEW** | `Tiannara.Forecasting.DecisionReview` |
| Pre-mortem | (none) | **NEW** | `Tiannara.Forecasting.PreMortem` |
| Value of information | `Discovery.Adaptive.OpportunityCostEstimator` | **REUSE (pattern)** | `Tiannara.Forecasting.ValueOfInformation` recomputes via D2 Forecast uncertainty |
| Forecast composition | `Tiannara.Forecasting.{ForecastEngine, Forecast, Contracts}` | **REUSE** | D3 alternatives hold Forecast distributions |
| Bayes / entropy | `Tiannara.Math.Probability` | **REUSE** | posterior / uncertainty |
| Normalization | `Tiannara.Constraints` | **REUSE** | probability integrity |
| ID generation | `Tiannara.Executive.Types.new_id/0` | **REUSE** | decision IDs |
| Event/audit | `Tiannara.Executive.{Event, EventStore}` | **REUSE** | decision lifecycle + replay |
| Command lifecycle | `Tiannara.Executive.Command` | **EXTEND (boundary)** | selected action → command for execution |
| Constitutional authorization | `Tiannara.Council.authorize/3`, `Council.Authorization` | **REUSE** | decision → authorization gate (never bypassed) |
| Authority boundary | `Tiannara.Omega.AuthorityVerifier` | **REUSE** | D3 decision module must NOT possess execution/deployment capability |
| Decision trace / audit replay | `Tiannara.HAI.DecisionTraceExplorer` | **REUSE** | decision traces |
| World counterfactual "what if X" | `Tiannara.World.TemporalWorldEngine.counterfactual_state/2` | **REUSE (surface)** | consequence estimation input |
| Blast radius / causal | `Tiannara.World.UnifiedRealityGraph` | **REUSE (surface)** | consequence estimation input |
| CIS pathogen check | `Tiannara.CIS.{PathogenDetector, OverreactionMonitor, ImmuneMemory}` | **REUSE (boundary)** | CIS retains authority to constrain/block/modify |
| Research Director bridge | `Tiannara.Research.ResearchDirector.ingest_priorities/1` | **ADAPTER (boundary)** | expose VoI / info-gain decisions for experiments |
| Evidence confidence | `Tiannara.Sentinel.Verification` | **REUSE (surface)** | decision evidence confidence |
| Governance health | `Tiannara.Sentinel.Governance` | **REUSE (surface)** | consult before committing |
| AEO execution | `Tiannara.AEO` | **ADAPTER (boundary)** | D3 selects → AEO translates intent → Runtime |
| Council adapter contract | (new) | **ADAPTER (new contract)** | `Forecasting.Adapters.Decision` behaviour |

## Boundary principles (D3 never oversteps)

- Decision recommendation ≠ authorization. Decision confidence ≠ authorization.
- Expected value ≠ authorization.
- D3 never bypasses constitutional authorization (`Council.authorize/3`).
- CIS retains authority to constrain/block/modify/require evidence/require
  authorization.
- Decision Quality ≠ (outcome == desired outcome). All four
  (good/bad decision) × (good/bad outcome) combinations must be representable.
- Failure attribution (luck/skill/survivorship) belongs to D4. D3 only performs
  structured postmortem; no luck/skill attribution.
- Baseline/alternative integrity: EV computed from decision-time distributions,
  never from hindsight.

## Reuse rule (prompt §)

Do NOT replace Signal, Evidence, Forecast, Calibration, Mathematics, Research
Director, CIS, World Model, AEO. Do NOT create duplicate decision ontologies.
`Executive.Command` remains the execution request vehicle (D3 extends at the
boundary, not replacing).

## Integration contract (AEO + Research bridge)

Forecast → Decision Analysis → Decision → (Council authorize) → AEO → Action.
Where additional information could change the preferred action, D3 exposes a
research bridge → Research Director → Experiment → Evidence → D2 Forecast
Update → D3 re-evaluation.
