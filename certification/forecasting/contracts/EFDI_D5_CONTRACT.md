# EFDI D5 CONTRACT — Noise, Judgment Variability, Robustness & Sensitivity Intelligence

contract_id: EFDI_D5_CONTRACT
version: 1.0.0
status: PENDING_COUNCIL_AUTHORIZATION
supersedes: none
depends_on: EFDI D1–D4 certified boundary (300/300 tests, V1–V35)
governing_law: Tiannara Constitutional Engineering Instructions; EFDI D5 Master Prompt

---

## §0 AUTHORITY & EFFECTIVENESS

0.1 This contract has NO implementation authority until an executed
    authorization/EFDI_D5_AUTHORIZATION.md exists, granted by the human Council
    through the established process. A template is not authorization.
0.2 This contract is immutable once authorized. Any change produces a new version
    (§18) with its own authorization. Analyses permanently cite the contract
    version under which they ran.
0.3 All quantitative thresholds in this contract were fixed BEFORE any D5
    observation exists. This is the anti-threshold-laundering guarantee (§14).

## §1 SCOPE

IN SCOPE (operational layer over canonical substrate):
  S1  repeated-judgment execution records
  S2  perturbation specification, pre-registration, budgeting
  S3  controlled evaluation orchestration (bounded)
  S4  noise classification (identifiability-constrained)
  S5  robustness / sensitivity classification (coverage-scoped)
  S6  regime tagging and aggregation guards
  S7  temporal labeling (decision-time vs post-outcome)
  S8  disagreement preservation and derived aggregation
  S9  activation of the reserved D2 Forecast.disagreement extension point

OUT OF SCOPE (hard prohibitions):
  N1  new statistics / probability / entropy / disagreement mathematics
  N2  institutional lessons (D6 territory)
  N3  execution, authorization, or any Council/CIS/AEO bypass
  N4  modification of any D1–D4 record outside §15.1's single sanctioned path
  N5  parallel world model, causal engine, memory system
  N6  classification of any kind from unexecuted or under-powered analysis

## §2 ONTOLOGY (record types and states)

R1  PerturbationPlan      — pre-registered, immutable after registration
R2  JudgmentRun           — one execution: identity, versions, seed, output hash
R3  RunSet                — runs grouped by plan; carries crossing_structure
R4  DisagreementRecord    — individual judgments PRIMARY; aggregates DERIVED
R5  NoiseAnalysis         — per-source estimates + identifiability verdicts
R6  SensitivityFinding    — baseline vs perturbed: delta, direction, crossings, flips
R7  RobustnessAnalysis    — class + mandatory coverage_manifest
R8  RegimeTag             — {temporal, environmental, domain, population,
                           system_version, model_version}
R9  TemporalLabel         — DECISION_TIME | POST_OUTCOME_ANALYSIS (computed, §9)

States never collapse to booleans. UNKNOWN / UNDERDETERMINED / INSUFFICIENT_*
are first-class values on every classifiable field (§12).

## §3 CANONICAL REUSE OBLIGATION

3.1 Variance, dispersion: Numerics.variance/1 and Statistics module ONLY.
3.2 Effect sizes (bias magnitude): Numerics.cohens_d/2 with small-sample
    correction noted in the finding's assumptions field.
3.3 Distributional shift between baseline and perturbed output distributions:
    Foundations.InformationTheory KL divergence with bootstrap confidence
    interval; below minimum sample (§4), report UNKNOWN, not a point value.
3.4 Categorical dispersion: Shannon entropy via Foundations.InformationTheory.
3.5 Probability semantics: Math.Probability only. No D5-defined probability.
3.6 Bias evidence at portfolio scale: D2 Calibration records (reuse, read-only).
3.7 Lineage/provenance: EventStore only. No parallel ledger.
3.8 Disagreement ethics: extend the DistributedValidationResult precedent —
    preserve disagreement before aggregation (§11).

## §4 REPEATED JUDGMENTS — "what constitutes sufficient repetition?"

4.1 SINGLE_OBSERVATION vs REPEATED_EVIDENCE is an explicit RunSet state.
    n = 1 NEVER supports any noise, stability, or robustness claim.
4.2 Repetition tiers (fixed pre-data; justification mandatory and recorded):
      TIER-0  n < 5        → no estimate permitted; all noise fields UNKNOWN
      TIER-1  5 ≤ n < 32   → PROVISIONAL estimate reportable;
                             NO classification; flag PROVISIONAL
      TIER-2  n ≥ 32       → classifiable
    Justification for n = 32: for a standard-deviation estimator under the
    documented normality assumption, the 95% CI relative half-width is
    ≈ 1.96/√(2(n−1)) ≈ 25% at n = 32. Below this, a noise classification would
    rest on an estimate whose own uncertainty exceeds the classification
    granularity. Non-numeric or non-normal outputs use rank/IQR-based
    estimation with the same tier logic; if no valid estimator applies, UNKNOWN.
4.3 Repetition DEPTH (identical reruns) measures occasion/sampling variability.
    Repetition BREADTH (crossed designs) is required for source attribution
    (§6.2). Depth without breadth ⇒ noise magnitude only, no source claims.

## §5 PERTURBATION MODEL — "what may be changed, and by how much?"

5.1 Closed dimension set (no others exist):
    PROMPT · EVIDENCE_ORDER · MODEL · EVALUATOR · PARAMETER · PRIOR ·
    SCENARIO · SAMPLING · TEMPORAL
5.2 Every PerturbationPlan declares, BEFORE execution: target, dimensions,
    per-dimension budget, rationale, expected invariance (if any), and full
    variant list. Plans are immutable post-registration; appendices require a
    new plan id and are permanently flagged LATE_ADDED (cannot support
    classification — exploratory only). This is the anti-selective-perturbation
    rule.
5.3 Budget types per dimension:
      categorical swap  — declared variant set (e.g., paraphrase set, order set)
      ordinal           — declared position permutations
      continuous        — bounded ε on a declared scale; the scale and ε are
                          plan fields, never chosen after observing outputs
5.4 Perturbation validity:
      VALID      — varies one declared dimension within budget
      INVALID    — varies undeclared dimensions, exceeds budget, or touches
                   immutable inputs (decision-time evidence, historical records)
      CONTAMINATION — a "perturbation" that alters what was known at decision
                   time. This is not perturbation; it is temporal violation (§9).
5.5 NOMINAL vs EXTREME tiers: each dimension's budget splits into a nominal
    band (reasonable variation) and an extreme band (stress). Robustness
    classes read these tiers differently (§7).

## §6 NOISE SEMANTICS — "when is variability legitimately noise?"

6.1 DEFINITION: Noise is unwanted variability under IRRELEVANT perturbation —
    variation in dimensions the contract declares should not matter
    (evidence order, semantically equivalent phrasing, resampling, evaluator
    identity on identical mandates). Variability under RELEVANT perturbation
    (evidence, priors, assumptions, parameters) is SENSITIVITY, not noise.
    The legitimacy declaration in the PerturbationPlan is what separates them.
    This is why VARIANCE ≠ NOISE is enforced structurally, not rhetorically.
6.2 Identifiability gate (crossing structure → attributable source):
      identical reruns                     → sampling/occasion variability only
      evaluators × fixed model/evidence    → evaluator noise
      models × fixed evidence/evaluator    → model noise (lineage-dependent, §6.5)
      orderings × all else fixed           → evidence-order noise
      paraphrases × all else fixed         → prompt noise
    A source estimate exists ONLY if the RunSet crossing isolates it.
    Unisolated source ⇒ that source's field = UNKNOWN. No borrowing, no
    imputation.
6.3 NOISE_CLASS per tested source: NEGLIGIBLE | LOW | MODERATE | HIGH | UNKNOWN,
    banded by the contract-fixed thresholds of §14 applied to the estimator CI
    (band applied to the CI, never to a bare point estimate).
6.4 BIAS is separate and requires a directional reference:
      portfolio scale — D2 Calibration drift records (reuse)
      target scale    — reference class / base rate with declared validity
    Bias magnitude reported via cohens_d/2 with assumptions.
    Insufficient directional reference ⇒ BIAS_STATUS = UNKNOWN.
    Consistent directional deviation ≠ noise; unpredictable swing ≠ bias.
6.5 Model-consensus integrity: consensus strength is reported only with lineage
    metadata. Effective independent model count is computed from DECLARED
    lineage families. Any model with unknown lineage ⇒
    MODEL_CONSENSUS_STRENGTH = UNKNOWN (no numeric effective count emitted).
    Scripted output available: "The apparent consensus is based on correlated
    models."

## §7 ROBUSTNESS SEMANTICS — "what evidence before calling something robust?"

7.1 Materiality (what counts as "changed"):
      M1  recommendation flip (A>B becomes B>A, or enters/leaves top choice)
          — ALWAYS material; categorical, no threshold
      M2  contract-threshold crossing (e.g., probability crosses a decision
          threshold declared by D3) — ALWAYS material
      M3  continuous output movement |Δ| > ε_material, where ε_material is a
          per-target-class contract parameter = the smallest change that could
          alter a recommendation in that target class. Default: 10% of the
          declared decision-relevant range; any deviation from default requires
          a written justification record attached to the plan (pre-data).
7.2 Classes (each carries the FULL coverage_manifest; a class may never be
    reported without it):
      ROBUST             — all declared dimensions executed ≥ minimum coverage;
                           zero material changes under nominal tier
      MODERATELY_ROBUST  — all declared dimensions executed; material change
                           only under extreme tier; none under nominal
      SENSITIVE          — ≥1 material change under nominal tier; recommended
                           option stable in majority of runs
      FRAGILE            — recommendation flip or threshold crossing under
                           nominal tier in majority of runs
      UNSTABLE           — material variability under IDENTICAL reruns alone
                           (occasion noise dominates the measurement itself)
      UNKNOWN            — any declared dimension unexecuted, or below §4
                           minimums, or budget-exhausted (§10)
7.3 UNTESTED ≠ ROBUST: no class above UNKNOWN may be emitted unless every
    declared dimension has executed, complete, valid runs.
7.4 Confidence and robustness are separate axes on R7. No combined field exists
    in the schema. HIGH_CONFIDENCE + FRAGILE and LOW_CONFIDENCE + ROBUST must
    both be representable (acceptance sentences of Master Prompt §35).

## §8 REGIME SEMANTICS — "when are results invalid to aggregate?"

8.1 Every analysis carries RegimeTag R8. Each regime dimension is declared
    SENSITIVE or INVARIANT for the analysis template.
8.2 Aggregating results whose RegimeTags differ on any SENSITIVE dimension is
    prohibited: aggregate = UNKNOWN and REGIME_MISMATCH is recorded.
8.3 Robustness demonstrated in one regime never transfers to another.
    Cross-regime claims require re-execution under the new tag.

## §9 TEMPORAL SEMANTICS — "what was available at the relevant time?"

9.1 TemporalLabel is COMPUTED from timestamps, never self-declared:
      DECISION_TIME          — every referenced input has timestamp ≤ the
                               target's decision_time (verified against the D3
                               snapshot / evidence store)
      POST_OUTCOME_ANALYSIS  — any referenced input postdates decision_time
9.2 POST_OUTCOME_ANALYSIS is legitimate analysis, permanently labeled. It can
    never write into decision-quality, forecast-quality-at-decision-time, or
    calibration fields.
9.3 The D4→D3 firewall pattern is extended to D5: D5 holds read-only handles to
    D2/D3/D4 records; mutation attempts are rejected and emitted as adversarial
    audit events to EventStore.

## §10 BUDGET — "what prevents combinatorial explosion?"

10.1 Hard maxima (contract-fixed; enforced at plan submission, before any run):
       MAX_RUNS_PER_ANALYSIS              = 512
       MAX_VARIANTS_PER_DIMENSION         = 8
       MAX_MODELS_PER_ANALYSIS            = 6
       MAX_EVALUATORS_PER_ANALYSIS        = 6
       MAX_PERTURBATION_DIMENSIONS        = 5
       MAX_TOTAL_RUNS_PER_BUDGET_PERIOD   = configured, telemetry-monitored
     Justification: 6 models × 6 evaluators × 8 variants × 5 dimensions
     full-factorial ≈ 864,000 runs; the maxima plus §10.2 cap actual execution
     at ≤ 512 while preserving one-at-a-time + bounded crossed coverage.
10.2 Design family: one-at-a-time per dimension + ONE bounded crossed subset
     for identifiability (§6.2). Full factorial designs are unrepresentable.
10.3 Budget exhaustion is deterministic: over-budget plans are REJECTED at
     submission, never truncated mid-run. Analyses executed under partial
     coverage (e.g., dimension dropped for cause) carry PARTIAL_COVERAGE and
     may classify only as UNKNOWN or within tested scope, explicitly stated.
10.4 No uncontrolled spawning: D5 orchestrates runs; it never spawns agents,
     external executions, or self-extending analysis chains.

## §11 AGGREGATION — "how are individual judgments preserved?"

11.1 Individual judgments (R4) are primary, append-only, content-addressed,
     and permanently recoverable — extending the DistributedValidationResult
     minority-position precedent to model/evaluator/perturbation analysis.
11.2 Aggregates are DERIVED records: method + version + input hashes recorded;
     an independent verifier can recompute every aggregate from individuals.
11.3 Permitted aggregation methods (closed set; each documents semantics and
     assumptions in §17's method registry): median; trimmed mean (declared k);
     linear pool with declared weights; rank aggregation (declared method).
     Unlisted methods are invalid.
11.4 No aggregate may delete, overwrite, or shadow an individual judgment.
     Minority positions carry identity and are cited in any consensus output,
     which must also report dispersion and consensus strength (§6.5).

## §12 UNKNOWN SEMANTICS — "what conditions prevent classification?"

Truth table (enforced by API shape; coercion to 0/false/low-confidence is
structurally impossible):

  condition                                          forced state
  ─────────────────────────────────────────────────  ─────────────────────────
  one model tested                                   MODEL_DISAGREEMENT = UNKNOWN
  one evaluator used                                 EVALUATOR_NOISE = UNKNOWN
  zero valid runs of a declared dimension            ROBUSTNESS = UNKNOWN
  n below TIER-2 (§4) for a noise source             NOISE_ESTIMATE = UNKNOWN
  crossing structure does not isolate a source       SOURCE_ATTRIBUTION = UNKNOWN
  any model lineage unknown                          MODEL_CONSENSUS_STRENGTH = UNKNOWN
  regime mismatch on sensitive dimension             AGGREGATE = UNKNOWN
  no directional reference                           BIAS_STATUS = UNKNOWN
  budget partial / dimension unexecuted              coverage-scoped UNKNOWN
  KL/entropy below minimum sample                    distribution metric = UNKNOWN

## §13 PROVENANCE & REPLAY

13.1 Every derived finding traces:
     INPUT → PERTURBATION_PLAN (pre-registered) → RUN (identity, model version,
     evaluator identity, seed, environment, config, timestamp, output hash) →
     AGGREGATION (method, version) → CLASSIFICATION (contract_version,
     threshold_set hash).
13.2 All lifecycle events append to EventStore. No parallel ledger.
13.3 Replay: identical inputs + contract version must reproduce the
     classification, or the analysis is permanently flagged NONDETERMINISTIC
     with bounded divergence documented. Silent nondeterminism is a defect.

## §14 THRESHOLD INTEGRITY — ANTI-THRESHOLD-LAUNDERING

14.1 ALL quantitative thresholds (tier minima §4, noise bands §6.3, ε_material
     §7.1, budgets §10, metric minimum samples) live in THIS CONTRACT, nowhere
     else. Code and configuration may read them; they may not define them.
14.2 Thresholds are frozen at authorization time. Changing any threshold
     requires a new contract version (§18), effective only for analyses
     submitted after the new version's authorization.
14.3 Every classification cites contract_version + threshold_set hash.
     The independent verifier recomputes classifications against the CITED
     version — post-hoc threshold substitution is therefore detectable and is
     an adversarial test case (§17).
14.4 No threshold may be added or modified after the first observation exists
     in the population it would govern. This is the pre-registration rule.

## §15 INTEGRATION BOUNDARIES

15.1 D2 — activation of the reserved Forecast.:disagreement extension point.
     LIVE VERIFIED (2026-09-02, source scan): the `:disagreement` field already
     exists on the D2 `Forecast` struct (`Forecast.new/1` reads `m[:disagreement]`)
     and is preserved immutably by `ForecastRegistry` (same id → no-op; id →
     one record).
     The ONLY sanctioned write path is an APPEND-ONLY version:
       D5 → Forecast.version(base_forecast, %{disagreement: derived_record}) →
           ForecastRegistry.register/1
     which produces a NEW immutable Forecast version whose `lineage` records the
     prior forecast id and whose `forecast_version` bumps. The original forecast
     is never rewritten.
     D5 never alters probability, confidence, evidence, or base-rate fields; it
     sets ONLY the reserved `:disagreement` field on a NEW version.
     CONDITIONAL CLAUSE: if, at implementation start, the D2 source no longer
     exposes this append-only version path for `:disagreement`, D5 stores
     disagreement in derived records keyed by forecast id and the activation is
     DEFERRED — implementation STOPS for Council guidance rather than touching
     D2 immutability. (At contract time this path IS present; the clause guards
     against drift.)
     IMPLEMENTATION-START RE-VERIFICATION (2026-09-02, HEAD 3bd1601): the
     append-only version path IS present and intact. `:disagreement` reserved
     field confirmed at contracts.ex:73; `Forecast.version/2` (forecast.ex:84)
     produces a new immutable version with lineage and forecast_version bump;
     `ForecastRegistry.register/1` (forecast_registry.ex:58) never overwrites
     (same id → returns existing). Conditional clause satisfied — proceed; the
     D2 write path remains activated via versioning, never in-place mutation.
15.2 D3 — read-only. Decision-robustness findings ANNOTATE; recommendation
     flips never rewrite the decision record.
15.3 D4 — read-only. Counterfactual sensitivity never moves a record within
     D4's status ontology; HYPOTHETICAL cannot drift toward OBSERVED.
15.4 World Model — read-only reference. EventStore — append-only lineage.
15.5 Council/CIS/AEO — untouched; D5 exposes zero execution interfaces.

## §16 FORBIDDEN BEHAVIOR (summary — each maps to a gate)

Equating agreement with correctness · equating disagreement with error ·
equating confidence with robustness · equating variance with noise ·
inferring bias or noise from insufficient data · averaging away minority
judgments · modifying historical forecasts/decisions · unlabeled post-outcome
analysis · robustness claims without perturbation coverage · noise claims
without repetition · arbitrary thresholds · parallel probability/causal/world/
memory systems · authorizing execution · beginning D6.

## §17 CERTIFICATION GATES — CONTRACT-DERIVED (V36–V60 CANDIDATE RANGE)

Gates are derived from clauses, not inherited blindly. Traceability:

  gate   clause(s)        property
  ─────  ───────────────  ──────────────────────────────────────────────────
  V36    §0, §14, §18     contract integrity, versioning, threshold freeze
  V37    §3, §15          canonical math reuse; no duplicate engine
  V38    §9.3, §15        immutable source preservation (hash battery)
  V39    §4               repeated-judgment tiers; n=1 never supports claims
  V40    §6.2             evaluator disagreement + identifiability
  V41    §6.5             model disagreement; correlated-lineage consensus case
  V42    §5               plan completeness; malformed/undeclared rejected;
                          LATE_ADDED cannot classify
  V43    §7.1             materiality recomputation (flips, crossings, ε)
  V44    §7.2–7.3         class matches evidence table; untested ⇒ UNKNOWN
  V45    §12              full UNKNOWN truth-table battery; no coercion
  V46    §7.4             confidence/robustness separated axes
  V47    §6.1–6.4         bias vs noise separation; relevance distinction
  V48    §8               regime mismatch rejection
  V49    §9               temporal firewall; computed labels; POST_OUTCOME barred
  V50    §15.1            D2 integration incl. conditional clause behavior
  V51    §15.2            D3 integration; annotation-only
  V52    §15.3            D4 ontology integrity
  V53    §10              budget enforcement at submission; PARTIAL_COVERAGE
  V54    §13.3            replay determinism / documented nondeterminism
  V55    §14, §5.2        threshold-laundering + selective-perturbation attacks
  V56    §11              minority preservation; aggregate recomputation
  V57    §13.1–13.2       provenance chain completeness; n mandatory
  V58    §9.3             historical immutability across D1–D4
  V59    §15.5            no execution/authorization bypass
  V60    §1 scope         full regression: 300/300 D1–D4 + complete D5 suite

Final gate list may be refined during implementation ONLY with equivalence
documented; coverage may increase, never silently shrink.

## §18 CONTRACT GOVERNANCE

18.1 Amendment = new version + new authorization. No in-place edits.
18.2 Analyses permanently cite their governing version; re-certification under
     a new version is a fresh campaign decision, not a rewrite of history.
18.3 Interpretation disputes resolve to the stricter epistemic reading.
