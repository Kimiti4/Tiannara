Yes. If I were the **lead architect for Tiannara's forecasting/foresight capability**, I would not design it as merely a collection of prediction algorithms.

I would design it as a **persistent Forecasting & Foresight Intelligence Substrate** whose architecture is deliberately capable of absorbing better forecasting methods discovered later without having to redesign the foundation.

The key principle would be:

> **Do not build Tiannara to contain today's best forecasting technique. Build it so that Tiannara can discover, evaluate, validate, compose, and permanently integrate better forecasting techniques tomorrow.**

That is a materially different architecture.

## 1. The capability I would actually build

I would make the hierarchy:

```text
                         CONSTITUTIONAL COUNCIL
                                  │
                                  ▼
                         EPISTEMIC GOVERNANCE
                                  │
                                  ▼
                 ┌────────────────────────────────┐
                 │ FORECASTING & FORESIGHT CORE   │
                 └────────────────────────────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          ▼                       ▼                       ▼
   Forecast Engine          Signal Intelligence      Uncertainty Engine
          │                       │                       │
          ▼                       ▼                       ▼
   Model Registry           Signal Registry         Calibration
          │                       │                       │
          └───────────────────────┼───────────────────────┘
                                  ▼
                         Ensemble / Synthesis
                                  │
                                  ▼
                       Scenario & Futures Engine
                                  │
                                  ▼
                     Counterfactual / Causal Engine
                                  │
                                  ▼
                       Experiment Selection
                                  │
                                  ▼
                     Research / Engineering Loop
                                  │
                                  ▼
                       Real-World Observation
                                  │
                                  ▼
                         Forecast Postmortem
                                  │
                                  ▼
                         Knowledge Integration
                                  │
                                  ▼
                      Forecasting Architecture
                             Evolution
```

The important part is the **bottom-to-top feedback loop**.

Tiannara shouldn't simply:

> predict → see whether right

It should learn:

> predict → observe → score → diagnose → identify why → determine whether the failure was signal/model/data/luck/regime/etc. → generate improvement hypothesis → test improvement → validate → preserve → deploy bounded improvement.

That is how the capability remains strong **after the initial implementation**.

---

# 2. The first major novel component: Forecast Genome

I would make every forecasting system representable as a composable **Forecast Genome**.

Not just:

```text
model = ARIMA
```

but something like:

```text
ForecastGenome
│
├── problem_definition
├── target_definition
├── horizon
├── observation_model
├── data_sources
├── signal_extractors
├── transformations
├── base_rates
├── priors
├── candidate_models
├── causal_assumptions
├── regime_detector
├── ensemble_policy
├── calibration_method
├── uncertainty_model
├── abstention_policy
├── decision_policy
├── scoring_policy
├── update_policy
└── provenance
```

This becomes enormously important.

A future Tiannara could discover:

> "This regime detector improves forecasting during structural transitions."

It shouldn't need a new architecture.

It should be able to evolve:

```text
Genome A
   ↓
replace regime detector
   ↓
Genome B
   ↓
benchmark
   ↓
Genome B statistically superior
   ↓
validation
   ↓
promote
```

That gives you **architectural evolvability**.

---

# 3. Forecast Genome Mutation Engine

I would go one step further.

Create a controlled:

```text
ForecastGenomeMutator
```

capable of generating candidate forecasting architectures.

For example:

```text
mutate_signal()
mutate_model()
mutate_ensemble()
mutate_prior()
mutate_horizon()
mutate_regime_detector()
mutate_calibration()
mutate_abstention()
mutate_feature_selection()
mutate_update_policy()
```

But critically:

**mutation never equals deployment.**

It produces:

```text
candidate
    ↓
sandbox
    ↓
historical replay
    ↓
out-of-sample evaluation
    ↓
stress test
    ↓
statistical comparison
    ↓
replication
    ↓
Council/gate
    ↓
promotion
```

This fits Tiannara's existing evolutionary philosophy extremely well.

---

# 4. Forecast Lineage Graph

Every forecast should have ancestry.

For example:

```text
F-0001
   │
   ├── F-0007
   │      │
   │      └── F-0018
   │
   └── F-0011
          │
          └── F-0023
```

Each forecast should know:

```text
forecast_id
parent_forecast
model_version
signal_versions
data_snapshot
knowledge_version
assumptions
priors
calibration_state
regime
random_seed
timestamp
```

This allows Tiannara to answer:

> Why did this forecast exist?

and eventually:

> Which architectural lineage produces the best forecasts?

That's much more powerful than a conventional prediction log.

---

# 5. A dedicated Forecast Knowledge Graph

I'd add:

```text
ForecastKnowledgeGraph
```

with relationships such as:

```text
SIGNAL
  ↓
supports
  ↓
HYPOTHESIS
  ↓
used_by
  ↓
MODEL
  ↓
produces
  ↓
FORECAST
  ↓
resolves_to
  ↓
OUTCOME
```

But also:

```text
MODEL
  ↓
fails_under
  ↓
REGIME
```

and:

```text
SIGNAL
  ↓
correlated_with
  ↓
SIGNAL
```

and:

```text
FORECAST
  ↓
contradicted_by
  ↓
EVIDENCE
```

and:

```text
EXPERIMENT
  ↓
reduced_uncertainty_of
  ↓
HYPOTHESIS
```

This gives Tiannara **forecasting memory**, rather than simply historical data.

---

# 6. Signal Intelligence should be a first-class subsystem

This is one of the most important things I'd build.

Not:

```text
features → model
```

but:

```text
Signal Intelligence
```

that continuously evaluates:

### Signal quality

```text
predictive_power
stability
independence
redundancy
latency
noise
regime_dependence
causal_plausibility
distribution_shift
```

And importantly:

### Signal lifecycle

```text
DISCOVERED
    ↓
UNTESTED
    ↓
VALIDATING
    ↓
WEAK
    ↓
USEFUL
    ↓
ROBUST
    ↓
REGIME_BOUND
    ↓
DEPRECATED
```

A signal should never become permanently trusted merely because it worked.

---

# 7. Signal Interaction Discovery

This could become genuinely interesting.

Instead of only testing:

```text
signal A
signal B
signal C
```

Tiannara should investigate:

```text
A + B
A + C
B + C
A × regime
B × horizon
A conditioned on B
```

because some information only becomes useful conditionally.

For example:

```text
Signal A:
weak

Signal B:
weak

A | B:
strong
```

The system should be able to discover that.

But this needs severe multiple-testing controls to avoid manufacturing false discoveries.

---

# 8. The Base-Rate Engine

I would make base rates impossible to accidentally omit.

Every forecast should ask:

```text
What normally happens?
```

before:

```text
What do we think will happen this time?
```

So:

```text
BaseRateEngine
```

with:

```text
historical_frequency()
conditional_frequency()
regime_frequency()
seasonal_frequency()
domain_frequency()
reference_class()
```

And:

```text
compare_model_to_base_rate()
```

becomes mandatory.

This prevents sophisticated models from getting congratulated for beating a trivial baseline by almost nothing.

---

# 9. The "Should I Predict?" engine

This is one of the capabilities I'd consider particularly important.

Tiannara should be able to say:

> **This problem currently does not contain enough predictable information.**

Therefore:

```text
Predict
```

should not always be the answer.

Create:

```text
PredictabilityEstimator
```

that estimates:

```text
signal_to_noise
historical_predictability
model_disagreement
uncertainty
regime_stability
data_quality
forecastability
```

Output:

```text
PREDICT
LOW_CONFIDENCE_PREDICT
ABSTAIN
COLLECT_MORE_DATA
RUN_EXPERIMENT
```

That is much closer to genuine forecasting intelligence.

---

# 10. Forecast Abstention Engine

This deserves its own component.

```text
AbstentionEngine
```

Tiannara should learn when:

> "I don't know."

But also distinguish:

```text
I don't know
```

from:

```text
The world itself appears intrinsically difficult to predict.
```

and:

```text
We lack sufficient data.
```

and:

```text
The regime has changed.
```

Those are different epistemic states.

---

# 11. Regime Detection Engine

This is essential for long-term forecasting.

Markets, economies, engineering systems, ecosystems, cybersecurity environments and even software systems can change regimes.

So:

```text
RegimeEngine
```

should detect:

```text
stationary
trend
seasonal
volatile
structural_break
distribution_shift
adversarial
unknown
```

and maintain:

```text
regime_probability
```

rather than pretending regime classification is certain.

Then forecasts become:

```text
P(outcome | regime 1)
P(outcome | regime 2)
P(outcome | regime 3)
```

rather than one fragile global prediction.

---

# 12. Forecast Ensemble Intelligence

Don't hard-code:

```text
average(model1, model2, model3)
```

Build an:

```text
EnsembleIntelligenceEngine
```

that evaluates:

```text
model accuracy
calibration
independence
regime performance
horizon performance
domain performance
failure correlation
```

A critical variable:

```text
error_correlation
```

Two models that disagree philosophically but make identical errors aren't really independent.

Tiannara should discover that.

---

# 13. Model Diversity Engine

I'd explicitly measure:

```text
model monoculture
```

because ensembles can create the illusion of diversity.

Example:

```text
Model A → transformer
Model B → transformer variant
Model C → transformer variant
Model D → transformer variant
```

looks like four models.

But their failures could be highly correlated.

So:

```text
ModelDiversityScore
```

should measure actual independence.

---

# 14. Forecast Calibration Laboratory

This should become one of Tiannara's permanent scientific instruments.

Functions such as:

```text
calibrate()
recalibrate()
reliability_curve()
brier_score()
log_score()
sharpness()
resolution()
discrimination()
calibration_error()
confidence_error()
```

And crucially:

```text
calibration_by_domain()
calibration_by_horizon()
calibration_by_regime()
calibration_by_model()
```

A forecaster with:

```text
90% confidence
```

should eventually demonstrate that roughly 90% of comparable predictions resolve correctly.

Otherwise Tiannara should downgrade that forecasting architecture.

---

# 15. Forecast Reputation Engine

Not reputation based on:

> "This model performed well recently."

Instead:

```text
ForecasterReputation
```

based on:

```text
sample_size
calibration
Brier
log_loss
resolution
robustness
domain
horizon
regime
replication
failure_modes
```

So a model could have:

```text
excellent short-horizon performance
poor long-horizon performance
```

rather than receiving one global score.

---

# 16. The Luck-vs-Skill Engine

This is another capability I would absolutely build.

```text
SkillAttributionEngine
```

Run:

```text
actual history
alternative histories
Monte Carlo worlds
randomized outcomes
counterfactual environments
```

and ask:

> Could this performance plausibly have happened by luck?

This prevents Tiannara from accidentally evolving toward:

```text
successful → trusted
```

instead of:

```text
successful → investigate why → replicate → attribute → validate
```

---

# 17. Alternative-History Simulator

I'd make this a reusable service:

```text
AlternativeHistoryEngine
```

For every important forecasting system:

```text
What happened?
What could have happened?
How often would this forecasting architecture have succeeded?
```

This is extremely important for distinguishing:

```text
forecasting skill
```

from:

```text
one favorable trajectory
```

---

# 18. Decision Quality ≠ Forecast Accuracy

Tiannara should store:

```text
Forecast
Decision
Outcome
```

as separate entities.

For example:

```text
Forecast:
70% probability

Decision:
don't act because downside risk was unacceptable

Outcome:
event occurs
```

The forecast could be good and the decision could be good even if the outcome was unfavorable.

So build:

```text
DecisionQualityEvaluator
```

separate from:

```text
ForecastAccuracyEvaluator
```

This will become very important when Tiannara starts assisting engineering, research and strategic decisions.

---

# 19. Counterfactual Decision Engine

Then:

```text
CounterfactualDecisionEngine
```

can ask:

```text
What if we had acted?
What if we had not acted?
What if probability was 10% higher?
What if the forecast was wrong?
What if the regime changed?
```

This connects forecasting to Tiannara's broader scientific/engineering architecture.

---

# 20. Forecast-to-Experiment Engine

This is where I think Tiannara could become substantially more powerful than a conventional forecasting platform.

Instead of:

> "What will happen?"

Tiannara asks:

> "What experiment would most improve our ability to predict what happens?"

Architecture:

```text
Knowledge Gap
      ↓
Candidate Experiments
      ↓
Expected Information Gain
      ↓
Expected Forecast Improvement
      ↓
Cost / Risk
      ↓
Experiment Priority
```

So the objective becomes:

```text
maximize expected knowledge gained per unit cost/risk
```

This connects directly to the Research Director.

---

# 21. Forecast Value of Information

I'd explicitly implement:

```text
forecast_value_of_information()
```

because information isn't equally useful.

A piece of information might:

```text
reduce uncertainty 2%
```

but have almost no decision value.

Another might:

```text
reduce uncertainty 1%
```

but completely change an engineering decision.

Therefore Tiannara needs:

```text
information_gain
+
decision_value
```

rather than information gain alone.

---

# 22. Contradiction Engine

Forecasting systems need to actively seek evidence against themselves.

Create:

```text
DisconfirmingEvidenceEngine
```

Functions:

```text
find_contradictions()
search_disconfirming_evidence()
stress_assumption()
challenge_model()
generate_counterexample()
```

Every significant forecast should have:

```text
supporting evidence
contradicting evidence
missing evidence
```

This directly implements the constitutional principle:

> Truth has priority over confidence.

---

# 23. Forecast Adversarial Laboratory

I would make adversarial forecasting a permanent subsystem.

```text
ForecastAdversary
```

Generate:

```text
misleading signals
fake correlations
data leakage
timestamp manipulation
regime changes
outliers
missing observations
selection bias
survivorship bias
confirmation traps
narrative traps
```

Then see whether Tiannara detects them.

---

# 24. Narrative-vs-Data Separation

This is particularly useful for real-world forecasting.

I'd create:

```text
NarrativeSignal
ObservedSignal
```

as different epistemic types.

For example:

```text
"Analysts expect X"
```

should never automatically become:

```text
X is likely
```

Instead:

```text
Narrative:
analysts expect X

Evidence:
historical accuracy of this narrative source = ...

Independent evidence:
...

Updated forecast:
...
```

This protects Tiannara against persuasive narratives.

---

# 25. Forecast Source Reliability Engine

Every external source gets an empirical record.

```text
SourceReliability
```

measuring:

```text
accuracy
timeliness
bias
noise
missingness
correlation
domain
horizon
revision_frequency
```

Then Tiannara can learn:

> Source A is useful for short-term weather but poor for long-range economic forecasting.

That's far more useful than a generic source trust score.

---

# 26. Temporal Data Integrity Layer

For forecasting, I'd make temporal integrity almost constitutional.

Functions:

```text
freeze_cutoff()
verify_timestamp()
detect_future_leakage()
detect_revision_leakage()
reconstruct_information_state()
```

Most importantly:

```text
What did Tiannara know at T0?
```

must be reconstructable.

Otherwise historical forecasting tests can become contaminated by hindsight.

---

# 27. Forecast Replay Engine

This is a must-have codebase.

```text
ForecastReplayEngine
```

Given:

```text
forecast_id
data_snapshot
model_version
knowledge_state
random_seed
```

it should reproduce:

```text
exact forecast
```

or explain why reproduction is impossible.

That gives you:

**scientific reproducibility for forecasting.**

---

# 28. Forecast Time Machine

I'd build a higher-level service around replay:

```text
ForecastTimeMachine
```

It reconstructs Tiannara's epistemic state at any historical point.

For example:

```text
2026-09-13 08:00
```

and asks:

> What would Tiannara have predicted using only information available then?

That becomes extraordinarily useful for preventing hindsight bias.

---

# 29. Forecast Postmortem Engine

After resolution:

```text
Forecast
   ↓
Outcome
   ↓
Postmortem
```

Automatically classify the error:

```text
DATA_ERROR
SIGNAL_ERROR
BASE_RATE_ERROR
MODEL_ERROR
CALIBRATION_ERROR
REGIME_SHIFT
CAUSAL_ERROR
RANDOM_OUTCOME
LEAKAGE
IMPLEMENTATION_ERROR
UNKNOWN
```

Then:

```text
generate_learning_hypothesis()
```

rather than blindly changing the model.

---

# 30. Forecast Failure Knowledge Base

Every failure becomes structured knowledge.

Example:

```yaml
failure:
  type: regime_shift

context:
  domain: energy
  horizon: 24h

observed:
  model_confidence: 0.82

actual:
  outcome: ...

lesson:
  prior_model_assumption_invalid: true

recommended:
  activate_regime_detection: true
```

Over time Tiannara develops something very valuable:

> **knowledge about how its own predictions fail.**

---

# 31. Forecast Architecture Evolution Engine

This is the part I would make deliberately compatible with Tiannara's larger evolution framework.

```text
ForecastArchitectureEvolution
```

Input:

```text
performance degradation
new research
new mathematical method
new signal
new model
new failure pattern
new scientific discovery
```

Output:

```text
candidate architectural improvement
```

Then:

```text
Generate
↓
Sandbox
↓
Benchmark
↓
Compare
↓
Stress
↓
Replicate
↓
Validate
↓
Gate
↓
Deploy
↓
Monitor
↓
Preserve lineage
```

Exactly the philosophy you've established for Tiannara.

---

# 32. Research Intake for Forecasting

This is what allows future knowledge to strengthen the foundation.

Tiannara should be able to ingest a new forecasting paper or discovery and extract:

```text
method
assumptions
domain
mathematics
data requirements
claimed improvement
limitations
failure conditions
benchmark
replication status
```

Then:

```text
Research
   ↓
Hypothesis
   ↓
Implementation candidate
   ↓
Benchmark
   ↓
Replication
   ↓
Forecast Genome candidate
```

A paper should **never automatically modify the forecasting system**.

It becomes evidence for an architectural candidate.

---

# 33. Forecast Method Registry

I'd maintain:

```text
ForecastMethodRegistry
```

with categories:

```text
BASE_RATE
PERSISTENCE
STATISTICAL
BAYESIAN
CAUSAL
TIME_SERIES
STATE_SPACE
DYNAMICAL
SIMULATION
MACHINE_LEARNING
ENSEMBLE
SCENARIO
EXPERT
HYBRID
NOVEL
```

Each method carries:

```text
assumptions
strengths
weaknesses
domains
horizons
computational_cost
data_requirements
validation_status
```

This makes new methods plug-in components instead of architectural rewrites.

---

# 34. Mathematical Forecasting Kernel

Given Tiannara's mathematics philosophy, I would explicitly establish:

```text
Probability
Statistics
Bayesian inference
Information theory
Time-series analysis
Stochastic processes
Dynamical systems
Optimization
Causal inference
Decision theory
Game theory
Uncertainty quantification
```

as foundational services.

Not separate mathematical islands.

They should compose.

For example:

```text
Bayesian model
+
regime detection
+
causal model
+
simulation
+
decision theory
```

could form one forecasting genome.

---

# 35. Distribution Shift Detector

This is absolutely mandatory.

```text
DistributionShiftEngine
```

detect:

```text
covariate shift
label shift
concept drift
structural break
measurement drift
source drift
regime change
```

Then forecast confidence should automatically be affected.

For example:

```text
Normal calibration:
0.78

Distribution shift detected:
HIGH

Effective confidence:
0.54
```

Rather than allowing historical performance to create false confidence in a changed world.

---

# 36. Forecast Uncertainty Decomposition

Don't store only:

```text
confidence = 75%
```

Break uncertainty into:

```text
aleatoric uncertainty
epistemic uncertainty
model uncertainty
data uncertainty
parameter uncertainty
regime uncertainty
measurement uncertainty
```

That allows Tiannara to decide:

> More data will help.

versus:

> More data won't solve this because the process itself is stochastic.

That distinction is enormously important.

---

# 37. Forecast Horizon Intelligence

Models should understand their own horizon.

For example:

```text
5 minutes
15 minutes
1 hour
1 day
1 month
10 years
```

should not be treated as the same problem.

Build:

```text
HorizonProfiler
```

that learns:

```text
predictability_decay(horizon)
```

and automatically determines when prediction becomes essentially uninformative.

---

# 38. Multi-Horizon Forecasting

Instead of:

```text
predict X
```

Tiannara should produce:

```text
5m distribution
15m distribution
1h distribution
4h distribution
1d distribution
7d distribution
```

and ensure they are **temporally coherent**.

That's a powerful capability.

---

# 39. Scenario Engine

For difficult long-term problems, probability alone isn't enough.

Build:

```text
ScenarioEngine
```

producing:

```text
baseline
optimistic
pessimistic
disruptive
adversarial
unknown/novel
```

but attach probabilities where justified.

For example:

```text
Scenario A: 41%
Scenario B: 27%
Scenario C: 18%
Scenario D: 9%
Unknown: 5%
```

And the system should preserve the possibility that the scenario set itself is incomplete.

---

# 40. Unknown-Unknown Detection

This is probably one of the hardest capabilities.

I would explicitly create:

```text
ModelAdequacyMonitor
```

asking:

> Is the model's world representation adequate for this prediction?

Warning states:

```text
MODEL_CONFIDENCE_HIGH
MODEL_ADEQUACY_LOW
```

This is much safer than:

```text
high confidence = reliable prediction
```

---

# 41. Forecast Confidence vs Confidence-in-Confidence

I'd preserve two quantities:

```text
P(event)
```

and:

```text
P(forecast_model_is_well_calibrated)
```

For example:

```text
P(event) = 0.82

P(calibration_valid) = 0.61
```

That should substantially affect how Tiannara communicates the prediction.

This is a particularly useful epistemic distinction.

---

# 42. Forecast Integrity Monitor

A continuously running supervisor:

```text
ForecastIntegritySupervisor
```

checks:

```text
calibration collapse
data leakage
model drift
signal contamination
model monoculture
confidence inflation
forecast distribution anomalies
prediction clustering
unusual abstention
unexpected error correlation
```

This should connect directly into CIS.

---

# 43. CIS + Forecasting

I would make forecasting one of CIS's major epistemic sensors.

CIS could detect:

```text
forecasting instability
```

such as:

```text
confidence ↑
accuracy ↓
```

or:

```text
model agreement ↑
independent evidence ↓
```

which could indicate **epistemic collapse**.

That is potentially more valuable than simply monitoring individual prediction errors.

---

# 44. Forecast Health Score

Not one simplistic number.

I'd create a vector:

```text
ForecastHealth
{
    calibration
    robustness
    diversity
    data_quality
    regime_stability
    signal_quality
    reproducibility
    uncertainty_quality
    sample_sufficiency
    distribution_shift
}
```

Then Tiannara can reason about *why* forecasting health is degrading.

---

# 45. The most important code-level interfaces

If I were defining the architecture today, I'd want interfaces roughly like:

```text
Forecast.create()
Forecast.freeze()
Forecast.resolve()
Forecast.score()
Forecast.explain()
Forecast.replay()

Signal.discover()
Signal.evaluate()
Signal.compare()
Signal.correlate()
Signal.retire()

Model.register()
Model.evaluate()
Model.calibrate()
Model.stress_test()
Model.compare()

Regime.detect()
Regime.classify()
Regime.transition_probability()

Ensemble.compose()
Ensemble.optimize()
Ensemble.diversity()

Predictability.estimate()
Predictability.abstain()

Evidence.ingest()
Evidence.reliability()
Evidence.contradictions()

Experiment.propose()
Experiment.rank()
Experiment.execute()
Experiment.evaluate_information_gain()

Counterfactual.simulate()
Counterfactual.compare()

Postmortem.analyze()
Postmortem.classify_failure()
Postmortem.generate_hypothesis()

Evolution.generate_candidate()
Evolution.benchmark()
Evolution.replicate()
Evolution.promote()

Knowledge.extract()
Knowledge.validate()
Knowledge.integrate()
```

The exact function signatures should be determined during implementation design, but these **responsibilities** should exist.

---

# 46. The codebase structure I'd aim for

Conceptually:

```text
forecasting/
│
├── core/
│   ├── forecast.ex
│   ├── forecast_state.ex
│   ├── forecast_resolution.ex
│   └── forecast_lineage.ex
│
├── signals/
│   ├── signal.ex
│   ├── signal_registry.ex
│   ├── signal_evaluator.ex
│   ├── signal_interaction.ex
│   └── signal_reliability.ex
│
├── models/
│   ├── model_registry.ex
│   ├── model_contract.ex
│   ├── model_evaluator.ex
│   └── model_version.ex
│
├── probability/
│   ├── bayesian.ex
│   ├── calibration.ex
│   ├── distributions.ex
│   └── uncertainty.ex
│
├── regimes/
│   ├── detector.ex
│   ├── transition.ex
│   └── shift_detection.ex
│
├── ensembles/
│   ├── composer.ex
│   ├── diversity.ex
│   └── weighting.ex
│
├── baselines/
│   ├── random.ex
│   ├── persistence.ex
│   ├── climatology.ex
│   └── historical.ex
│
├── experiments/
│   ├── information_gain.ex
│   ├── experiment_selection.ex
│   └── forecast_value.ex
│
├── counterfactual/
│   ├── alternative_history.ex
│   ├── decision.ex
│   └── simulation.ex
│
├── evaluation/
│   ├── brier.ex
│   ├── log_score.ex
│   ├── calibration.ex
│   ├── sharpness.ex
│   └── benchmark.ex
│
├── adversarial/
│   ├── leakage.ex
│   ├── noise.ex
│   ├── shift.ex
│   └── manipulation.ex
│
├── postmortem/
│   ├── analyzer.ex
│   ├── failure_taxonomy.ex
│   └── learning.ex
│
├── evolution/
│   ├── genome.ex
│   ├── mutator.ex
│   ├── candidate.ex
│   └── promotion.ex
│
├── knowledge/
│   ├── forecast_knowledge.ex
│   ├── method_registry.ex
│   └── research_intake.ex
│
└── integrity/
    ├── supervisor.ex
    ├── leakage_monitor.ex
    ├── calibration_monitor.ex
    └── epistemic_health.ex
```

I would **not necessarily implement all of this immediately**.

The architecture should accommodate it.

---

# 47. The really important part: the "learning contract"

This is what would make the system future-proof.

Every new forecasting insight enters through:

```text
NEW KNOWLEDGE
      ↓
CLAIM
      ↓
EVIDENCE
      ↓
HYPOTHESIS
      ↓
IMPLEMENTATION CANDIDATE
      ↓
BENCHMARK
      ↓
REPLICATION
      ↓
FAILURE ANALYSIS
      ↓
COMPARISON WITH CURRENT SYSTEM
      ↓
PROMOTION DECISION
```

And **never**:

```text
new paper
↓
change production
```

or:

```text
new successful prediction
↓
trust model
```

That would violate Tiannara's own epistemic architecture.

---

# 48. The capability should therefore have three loops

This is how I would ultimately conceptualize it.

### Loop A — Prediction

```text
Observe
 ↓
Represent
 ↓
Model
 ↓
Forecast
 ↓
Calibrate
 ↓
Decide/abstain
```

### Loop B — Learning

```text
Outcome
 ↓
Score
 ↓
Postmortem
 ↓
Failure attribution
 ↓
Knowledge
 ↓
Model improvement
```

### Loop C — Evolution

```text
Research
 ↓
Novel method
 ↓
Candidate architecture
 ↓
Benchmark
 ↓
Replication
 ↓
Validation
 ↓
Promotion
```

Together:

```text
                ┌──────────────────┐
                │   PREDICT        │
                └────────┬─────────┘
                         ↓
                     OBSERVE
                         ↓
                      SCORE
                         ↓
                   POSTMORTEM
                         ↓
                      LEARN
                         ↓
                  RESEARCH / DISCOVER
                         ↓
                  GENERATE CANDIDATE
                         ↓
                    BENCHMARK
                         ↓
                    VALIDATE
                         ↓
                     PROMOTE
                         │
                         └──────────→ PREDICT
```

That is the **self-strengthening forecasting architecture** I would want Tiannara to possess.

---

## My priority ranking

If we are deciding what is **absolutely foundational** rather than attempting to build everything at once:

| Priority | Capability                         | Why                                      |
| -------- | ---------------------------------- | ---------------------------------------- |
| **P0**   | Immutable Forecast Ledger          | Scientific reproducibility               |
| **P0**   | Forecast Schema + Lineage          | Know exactly what was predicted and why  |
| **P0**   | Baseline Engine                    | Prevent fake intelligence                |
| **P0**   | Calibration Engine                 | Know whether probabilities mean anything |
| **P0**   | Outcome/Resolution Engine          | Close the prediction loop                |
| **P0**   | Replay/Time Machine                | Eliminate hindsight ambiguity            |
| **P0**   | Signal Registry                    | Manage learned signals                   |
| **P0**   | Model Registry                     | Manage competing forecasters             |
| **P0**   | Uncertainty Engine                 | Separate uncertainty types               |
| **P0**   | Abstention/Predictability Engine   | Know when not to predict                 |
| **P1**   | Regime Engine                      | Handle changing worlds                   |
| **P1**   | Ensemble Intelligence              | Combine complementary models             |
| **P1**   | Alternative-History Engine         | Separate luck from skill                 |
| **P1**   | Postmortem Engine                  | Turn failures into knowledge             |
| **P1**   | Contradiction Engine               | Actively attack forecasts                |
| **P1**   | Adversarial Lab                    | Detect fragility                         |
| **P1**   | Experiment/Information-Gain Engine | Improve knowledge strategically          |
| **P1**   | Decision Quality Engine            | Separate forecast from decision          |
| **P2**   | Forecast Genome                    | Evolvable forecasting architectures      |
| **P2**   | Genome Mutation Engine             | Generate new architectures               |
| **P2**   | Forecast Architecture Evolution    | Incorporate future discoveries           |
| **P2**   | Research Intake                    | Convert research into candidates         |
| **P2**   | Forecast Knowledge Graph           | Long-term institutional memory           |
| **P2**   | Unknown-Unknown/Model Adequacy     | Detect limits of the representation      |
| **P2**   | CIS Forecast Integrity             | Detect epistemic degradation             |

### The deepest architectural principle

I would make **Forecast Architecture Evolution** the crown jewel.

Because the objective isn't:

> "Build Tiannara a great forecasting model."

It is:

> **"Build Tiannara a scientific system that can discover what makes forecasting better, prove that it is better, preserve that knowledge, and safely incorporate it into its forecasting architecture."**

That means if, five years from now, Tiannara discovers a forecasting technique substantially better than anything we know today, **the architecture should already have a legitimate path for that discovery to enter the system without destroying its epistemic guarantees.**

That is the difference between a **forecasting module** and a **forecasting intelligence capability**.

And I would treat the latter as the target.


Yes. For this capability, I would make the code-quality rules **stricter than ordinary application code**, because forecasting code can silently produce plausible but wrong scientific conclusions.

The governing principle should be:

> **Forecasting code is scientific instrumentation. A defect can become a false belief, and a false belief can propagate into research, engineering, or decisions. Therefore correctness, provenance, reproducibility, calibration, and failure transparency take precedence over feature velocity.**

## Forecasting & Foresight — Code Quality Constitution

# Tiannara Forecasting & Foresight

## Code Quality & Engineering Rules

### 1. Core Rule

Every forecasting component MUST be:

* deterministic where appropriate
* reproducible
* testable
* observable
* explainable
* replaceable
* versioned
* provenance-preserving
* failure-transparent
* independently benchmarkable
* safe to evolve

No component may gain authority merely because it produces plausible predictions.

---

# 2. Epistemic Safety Rules

## 2.1 Never confuse prediction with truth

Code MUST preserve the distinction between:

```text
observation
signal
evidence
assumption
hypothesis
model
forecast
decision
outcome
knowledge
```

These MUST NOT be represented as interchangeable generic maps or strings.

Bad:

```elixir
%{"value" => 0.82}
```

Preferred:

```elixir
%ForecastProbability{
  event: event_id,
  probability: 0.82,
  forecast_id: forecast_id
}
```

---

## 2.2 Never encode confidence as correctness

Forbidden:

```elixir
if confidence > 0.8 do
  :correct
end
```

Confidence MUST never directly imply correctness.

Confidence represents an epistemic state.

Correctness can only be evaluated after resolution against an appropriate outcome.

---

## 2.3 Never hide uncertainty

Functions MUST NOT silently convert:

```text
unknown
insufficient_data
model_failure
distribution_shift
unpredictable
missing_evidence
```

into:

```text
0
false
success
low confidence
```

unless that transformation is explicitly defined by the contract.

---

# 3. Immutable Forecast Rule

Once issued, a forecast MUST be immutable.

A forecast MUST contain enough information to reconstruct its epistemic state:

```text
forecast_id
question
target
horizon
created_at
information_cutoff
data_snapshot
model_versions
signal_versions
base_rate
assumptions
probabilities
uncertainty
confidence
alternatives
disconfirming_evidence
random_seed
software_version
knowledge_version
```

Corrections MUST create a new forecast/version rather than mutate the historical record.

---

# 4. Temporal Integrity

Forecasting code MUST explicitly distinguish:

```text
event_time
observation_time
ingestion_time
forecast_time
resolution_time
```

Never assume they are equivalent.

Every historical replay MUST be able to answer:

> What information was actually available at the forecasting cutoff?

Future information MUST NOT enter historical forecasting.

---

# 5. No Data Leakage

Every forecasting implementation MUST have tests for:

* future leakage
* target leakage
* timestamp leakage
* post-outcome leakage
* revision leakage
* survivorship bias
* selection leakage
* train/test contamination

A model that passes ordinary accuracy tests but fails leakage tests is **NOT VALID**.

---

# 6. Baseline-First Rule

Every new forecasting model MUST be compared against appropriate baselines.

At minimum where applicable:

```text
random
persistence
historical/base-rate
simple statistical
current production/best-known
```

A sophisticated model MUST NOT be accepted merely because it performs well in isolation.

The question is:

> Does it provide measurable improvement over an appropriate baseline?

---

# 7. Out-of-Sample Requirement

Forecasting code MUST distinguish:

```text
training
validation
testing
out-of-sample evaluation
live evaluation
```

Never use the same observations to:

```text
discover
tune
select
and certify
```

a forecasting method.

---

# 8. Calibration Is a First-Class Contract

Probability-producing functions MUST be evaluated for calibration.

Required metrics may include:

```text
Brier score
log loss
calibration error
reliability
resolution
sharpness
discrimination
```

Code MUST NOT expose:

```text
confidence = 0.92
```

without preserving the calibration context behind that probability.

---

# 9. Distribution Predictions

Where appropriate, prefer:

```text
P(event)
prediction interval
credible interval
quantile distribution
scenario distribution
```

over unsupported point predictions.

For example:

Bad:

```elixir
forecast_price = 81200
```

Better:

```elixir
%ForecastDistribution{
  median: 81200,
  q10: ...,
  q25: ...,
  q50: ...,
  q75: ...,
  q90: ...
}
```

The representation must match the epistemic structure of the problem.

---

# 10. Abstention Is a Valid Output

Every forecasting subsystem MUST be capable of returning:

```text
predict
low_confidence_predict
abstain
insufficient_data
unpredictable
distribution_shift
model_invalid
request_more_information
```

`abstain` MUST NOT be treated as an implementation failure.

In some environments, correctly refusing to make a prediction is a successful forecast-system behavior.

---

# 11. Predictability Before Prediction

Where feasible, the pipeline SHOULD evaluate:

```text
data_quality
signal_strength
historical_predictability
regime_stability
model adequacy
forecast horizon
```

before committing to a prediction.

The system should be able to determine:

```text
"this problem is currently not sufficiently predictable"
```

rather than forcing an answer.

---

# 12. Signal Registry Rules

Every signal MUST have:

```text
signal_id
version
definition
source
domain
horizon
data requirements
creation method
validation status
performance history
known failure modes
regime dependence
correlations
provenance
```

Signals MUST have explicit lifecycle states:

```text
DISCOVERED
UNTESTED
VALIDATING
QUALIFIED
ROBUST
REGIME_BOUND
DEPRECATED
REJECTED
```

No experimental signal may silently become trusted production input.

---

# 13. Signal Independence

The system MUST measure signal redundancy and correlation.

Never assume:

```text
signal_A
signal_B
signal_C
```

constitute three independent sources merely because they have different names.

Where possible, track:

```text
correlation
conditional dependence
common source
common transformation
common model origin
error correlation
```

---

# 14. Model Registry Rules

Every forecasting model MUST be registered and versioned.

Required metadata:

```text
model_id
version
algorithm
assumptions
parameters
training_data
training_cutoff
dependencies
random_seed
hyperparameters
known limitations
supported domains
supported horizons
validation results
failure modes
```

Models MUST NOT be identified only by a human-readable name.

---

# 15. No Hidden State

Forecasting functions SHOULD be as close as possible to:

```text
input + explicit configuration + explicit model state
→ output
```

Avoid hidden:

```text
global variables
implicit caches
mutable process state
ambient configuration
unstated random seeds
time-dependent behavior
```

If state is required, it MUST be explicit, versioned, and observable.

---

# 16. Randomness Rules

Randomness MUST be explicit.

Tests MUST be reproducible using recorded seeds.

Bad:

```elixir
:rand.uniform()
```

inside scientific logic without controlled state.

Preferred architecture:

```text
seed
→ RNG state
→ simulation
→ recorded result
```

The system MUST preserve enough information to reproduce stochastic experiments.

---

# 17. Numerical Stability

Numerical code MUST explicitly consider:

```text
overflow
underflow
NaN
Infinity
division by zero
loss of precision
ill-conditioned matrices
floating-point accumulation
probability normalization
log-space calculations
extreme distributions
```

Probabilities MUST remain mathematically valid:

```text
0 <= P <= 1
```

and probability distributions MUST satisfy their appropriate normalization constraints.

---

# 18. Never Silently Repair Invalid Mathematics

Bad:

```elixir
probability = min(max(probability, 0.0), 1.0)
```

when the value is mathematically invalid.

Clamping can hide a defect.

Instead:

```text
detect
→ record
→ reject or explicitly transform
→ explain
```

If a numerical stabilization is intentional, it MUST be documented and tested.

---

# 19. Mathematical Functions Need Contracts

Every mathematical function MUST define:

```text
domain
inputs
units
assumptions
output
invariants
failure conditions
numerical limitations
```

For example:

```text
bayes_update
```

must specify:

```text
prior requirements
likelihood requirements
evidence representation
normalization
zero-probability behavior
numerical stability
```

---

# 20. Units Must Be Explicit

Never mix:

```text
seconds
milliseconds
minutes
hours
days
```

implicitly.

Never mix:

```text
percent
fraction
basis points
absolute values
log returns
simple returns
```

without explicit conversion.

Domain quantities SHOULD carry unit metadata or use typed wrappers where practical.

---

# 21. Forecast Horizon Must Be Explicit

A forecast MUST declare its horizon.

For example:

```text
5_seconds
5_minutes
1_hour
24_hours
7_days
10_years
```

Do not allow a model's horizon to be inferred implicitly from surrounding code.

---

# 22. Regime Awareness

Models capable of regime-dependent behavior MUST explicitly represent regime state.

Never assume:

```text
historical distribution == current distribution
```

The system MUST be able to represent:

```text
stable
transition
unknown
distribution_shift
structural_break
```

---

# 23. Distribution Shift Must Affect Trust

A detected distribution shift MUST be observable by the forecasting layer.

Where appropriate it should cause:

```text
confidence reduction
model downgrade
abstention
recalibration
alternative model selection
additional evidence request
```

Never allow historical calibration to remain blindly authoritative after a detected regime change.

---

# 24. Ensemble Rules

Ensembles MUST preserve component identity.

Never reduce:

```text
Model A
Model B
Model C
```

to an unexplained average.

Record:

```text
component models
weights
weight rationale
correlation
regime
calibration
ensemble version
```

Ensemble diversity MUST be measurable.

---

# 25. Model Monoculture Detection

The system SHOULD detect when multiple supposedly independent models share:

```text
data
features
architecture
assumptions
training source
failure modes
```

An ensemble MUST NOT receive diversity credit merely because its models have different names.

---

# 26. Alternative-History Testing

Important forecasting claims SHOULD be evaluated across:

```text
Monte Carlo worlds
alternative histories
counterfactual trajectories
randomized environments
```

This helps distinguish:

```text
skill
luck
selection
survivorship
```

---

# 27. Postmortem Rules

Every resolved forecast SHOULD produce a structured postmortem.

At minimum:

```text
forecast
actual outcome
error
supporting evidence
contradicting evidence
missed evidence
signal performance
model performance
base-rate comparison
regime
data quality
luck contribution
failure classification
learning hypothesis
```

The system MUST NOT simply learn:

```text
wrong prediction
→ reverse model
```

It must first determine why the prediction failed.

---

# 28. Failure Taxonomy

Forecast failures MUST be classifiable.

Minimum taxonomy:

```text
DATA_ERROR
SIGNAL_ERROR
BASE_RATE_ERROR
MODEL_ERROR
CALIBRATION_ERROR
REGIME_SHIFT
CAUSAL_ERROR
LEAKAGE
OVERFIT
UNDERFIT
MEASUREMENT_ERROR
RANDOM_OUTCOME
ADVERSARIAL_INPUT
MODEL_CORRELATION
IMPLEMENTATION_ERROR
UNKNOWN
```

`UNKNOWN` is a valid and important result.

---

# 29. Contradiction-First Testing

Every significant forecasting model MUST have tests designed to disprove it.

Required concepts:

```text
counterexample
disconfirming evidence
stress assumption
boundary condition
failure regime
```

Passing only supportive tests is insufficient.

---

# 30. Multiple-Testing Protection

Any system that searches many signals, models, hypotheses, or feature combinations MUST account for multiple testing.

Otherwise:

```text
many experiments
→ some appear successful by chance
→ false discovery
```

Potential controls include:

```text
holdout datasets
pre-registration
correction procedures
replication
false-discovery controls
independent validation
```

The exact statistical method must depend on the experiment.

---

# 31. No Hindsight Learning

Post-outcome information MUST NOT silently enter the pre-outcome knowledge state.

The system must maintain:

```text
knowledge_state_at_T0
```

separately from:

```text
knowledge_state_after_outcome
```

---

# 32. Replayability

Every important forecast MUST be replayable.

Given:

```text
forecast_id
data_snapshot
model_version
signal_versions
knowledge_version
configuration
seed
```

Tiannara SHOULD reproduce the original forecast.

If reproduction is impossible, the reason MUST be recorded.

---

# 33. Provenance

Every important forecasting output MUST answer:

```text
Where did this number come from?
Which data?
Which signals?
Which models?
Which assumptions?
Which mathematical transformations?
Which knowledge?
Which software version?
```

No unexplained derived value should become authoritative knowledge.

---

# 34. Research Intake Safety

New forecasting research MUST enter through:

```text
research
→ claim
→ evidence
→ hypothesis
→ candidate implementation
→ benchmark
→ replication
→ validation
→ promotion
```

Never:

```text
paper
→ production
```

Never:

```text
interesting result
→ trusted capability
```

---

# 35. Forecast Genome Rules

Forecast architectures SHOULD be composable.

A Forecast Genome MUST identify:

```text
signals
transformations
models
priors
base rates
regime detector
ensemble
calibration
uncertainty
abstention
decision policy
```

Genome mutation MUST produce candidates, never automatic production changes.

---

# 36. Evolution Safety

Every forecasting improvement MUST follow:

```text
GENERATE
↓
EVALUATE
↓
BENCHMARK
↓
COMPARE
↓
STRESS TEST
↓
REPLICATE
↓
VALIDATE
↓
GATE
↓
PROMOTE
↓
MONITOR
↓
PRESERVE LINEAGE
```

No shortcut is permitted for production promotion.

---

# 37. Backward Compatibility

Forecast schemas, evidence schemas, model contracts, and stored forecast records MUST be versioned.

A new forecasting implementation MUST NOT silently reinterpret historical forecasts.

Schema migrations MUST preserve historical meaning.

---

# 38. API Design

Public forecasting APIs MUST be:

```text
small
explicit
typed
versioned
deterministic where appropriate
```

Avoid APIs with dozens of optional flags.

Prefer structured configuration:

```elixir
%ForecastRequest{
  target: ...,
  horizon: ...,
  cutoff: ...,
  evidence: ...,
  model_policy: ...,
  uncertainty_policy: ...
}
```

---

# 39. No Generic "Magic" Functions

Avoid functions such as:

```text
predict()
analyze()
evaluate()
learn()
improve()
```

when their semantics are ambiguous.

Prefer explicit operations:

```text
forecast_probability()
estimate_predictability()
score_brier()
detect_distribution_shift()
calibrate_model()
generate_counterfactual()
classify_forecast_failure()
```

Function names should expose the scientific operation.

---

# 40. Side Effects

Scientific computation SHOULD be separated from side effects.

Prefer:

```text
pure calculation
→ structured result
→ persistence
→ external action
```

rather than:

```text
forecast()
→ database mutation
→ external request
→ hidden logging
```

This makes experiments reproducible and safe.

---

# 41. External Actions

Forecasting code MUST NOT directly trigger high-impact external actions.

The architecture should separate:

```text
forecast
→ recommendation
→ decision
→ authorization
→ action
```

A high-confidence forecast MUST NOT bypass human or constitutional governance.

---

# 42. Observability

Every forecasting subsystem MUST expose:

```text
latency
throughput
error rate
forecast count
abstention rate
calibration
model drift
data quality
distribution shift
model disagreement
signal health
```

Observability MUST NOT alter scientific results.

---

# 43. Metrics Must Not Become Objectives Accidentally

A model MUST NOT be optimized against a metric merely because that metric is convenient.

For every evaluation metric document:

```text
what it measures
what it ignores
known failure modes
appropriate use
```

Avoid optimizing a proxy while claiming improvement in the underlying capability.

---

# 44. Benchmark Isolation

Certification benchmarks MUST be isolated from development/tuning datasets.

The benchmark MUST be:

```text
versioned
protected
immutable
independently reproducible
```

Changing the benchmark after observing results is prohibited without explicit versioning and justification.

---

# 45. Stress Testing

Every significant forecasting component SHOULD undergo:

```text
normal inputs
missing inputs
extreme inputs
corrupt inputs
delayed inputs
duplicate inputs
contradictory inputs
distribution shifts
large workloads
long-duration operation
```

---

# 46. Property-Based Testing

Where mathematical invariants exist, use property-based testing.

Examples:

```text
probabilities remain valid
distributions normalize
Bayesian updates preserve required invariants
forecast lineage remains acyclic
timestamps maintain ordering constraints
scores remain within valid domains
replay produces equivalent results
```

---

# 47. Metamorphic Testing

Where exact outputs are not expected, test relationships.

Examples:

```text
duplicating irrelevant data should not radically change forecast
permuting independent observations should preserve invariant results
unit conversion should preserve physical meaning
equivalent mathematical representations should produce equivalent outputs
```

---

# 48. Differential Testing

Important mathematical implementations SHOULD be compared against:

```text
independent implementation
trusted reference implementation
analytical solution
high-precision computation
simulation
```

This is especially important for:

```text
probability
statistics
optimization
dynamical systems
numerical methods
```

---

# 49. Test Categories

Every major forecasting component SHOULD maintain:

```text
unit tests
property tests
integration tests
regression tests
numerical tests
statistical tests
replay tests
leakage tests
adversarial tests
stress tests
long-duration tests
benchmark tests
```

Certification tests MUST remain distinguishable from ordinary development tests.

---

# 50. Performance

Optimize only after correctness.

Required order:

```text
correctness
→ reproducibility
→ profiling
→ optimization
→ benchmark
→ regression guard
```

Never sacrifice epistemic correctness for a benchmark improvement without explicit evidence that the change preserves the scientific contract.

---

# 51. Concurrency

Because Tiannara runs on BEAM/OTP:

Forecasting processes MUST avoid shared mutable state.

Prefer:

```text
isolated processes
immutable state
message passing
supervision
explicit state transitions
```

Long-running experiments MUST be supervised and recoverable.

---

# 52. Fault Tolerance

A failed model MUST NOT crash the forecasting system.

A failed signal MUST NOT corrupt other signals.

A corrupt data source MUST NOT invalidate historical forecasts.

A failed ensemble component MUST be isolated.

Failures MUST become structured evidence.

---

# 53. No Silent Fallbacks

Forbidden:

```text
model failed
→ silently use another model
```

unless fallback behavior is part of the explicit contract.

The system MUST record:

```text
primary model failed
fallback activated
fallback reason
fallback model
effect on forecast
```

---

# 54. Version Everything That Can Change a Forecast

Version:

```text
code
model
parameters
signals
data
features
knowledge
prompts/configuration
random seeds
external sources
calibration
ensemble weights
regime detector
```

If changing it could change the forecast, it needs provenance.

---

# 55. Reproducibility Levels

Forecast reproducibility SHOULD be classified:

```text
R0 — not reproducible
R1 — approximately reproducible
R2 — deterministic replay
R3 — exact computational replay
R4 — independently replicated
```

Certification should state the achieved level.

---

# 56. Knowledge Promotion

A forecasting observation MUST NOT automatically become knowledge.

Promotion should follow:

```text
Observation
↓
Evidence
↓
Replication
↓
Validation
↓
Knowledge
```

Knowledge SHOULD retain:

```text
confidence
scope
limitations
supporting evidence
contradicting evidence
last validation
```

---

# 57. Deprecation

Forecasting methods, signals and models MUST be removable.

A component should be deprecated when:

```text
performance degrades
assumptions fail
better method supersedes it
data source disappears
regime dependence invalidates it
maintenance cost exceeds value
```

Deprecation MUST preserve historical lineage.

Never delete historical forecasting knowledge merely because the method is obsolete.

---

# 58. No "Best Model" Without Context

Never store:

```text
best_model = X
```

without qualification.

Instead:

```text
best_model_for(
  domain,
  horizon,
  regime,
  metric,
  data_conditions
)
```

Forecast superiority is contextual.

---

# 59. Scientific Claims Must Be Traceable to Tests

Any statement such as:

```text
Model X improves forecasting
Signal Y is predictive
Method Z is robust
```

MUST resolve to:

```text
benchmark
dataset
metric
sample size
comparison
uncertainty
replication status
```

No unsupported capability claims.

---

# 60. Final Architectural Rule

The forecasting system MUST optimize for:

```text
truth
over confidence

calibration
over persuasion

evidence
over narrative

replication
over novelty

robustness
over benchmark gaming

abstention
over fabricated certainty

learning
over static performance

architecture evolution
over permanent attachment to one method
```

The ultimate success condition is not:

> Tiannara predicts correctly often.

It is:

> **Tiannara can determine when prediction is possible, make calibrated forecasts when it is, recognize when it is failing, understand why it failed, discover better forecasting methods, rigorously validate those methods, and safely incorporate validated improvements without compromising epistemic integrity.**

The most important distinction is that these should become **engineering invariants**, not merely style guidelines. In particular, I would make **immutability, temporal integrity, provenance, calibration, replayability, leakage prevention, abstention, baseline comparison, and gated evolution** hard architectural contracts. Everything else can evolve around those foundations.

Yes. And I would make one important correction to the previous design:

**The architecture is strong, but the current implementation pattern shown in the uploaded forecasting code is not yet production-grade.** It is closer to a **reference/prototype substrate**. The production-hardening phase must therefore verify the *actual mathematical and epistemic behavior*, not simply add more modules.

For example, the current implementation has useful structural pieces—immutable/frozen forecasts, lineage, baselines, calibration, postmortems, genome evolution, etc.  But several implementations are currently placeholders or heuristic approximations and therefore cannot yet be treated as certified forecasting capability.

The production objective should be:

> **Turn the forecasting/foresight and EFDI architecture from a collection of capability-shaped modules into a scientifically validated, reproducible, observable, fault-tolerant, continuously testable production subsystem.**

---

# 1. First: establish the distinction

I would formally create four states:

```text
THEATRICAL
    ↓
IMPLEMENTED
    ↓
VALIDATED
    ↓
PRODUCTION-CERTIFIED
```

This distinction is essential.

A function existing in:

```text
lib/tiannara/forecasting/
```

does **not** mean Tiannara possesses that capability.

Likewise:

```text
def detect(...)
```

does not mean Tiannara can reliably detect regimes.

Your current regime detector is a good example. It currently classifies regimes largely from simple mean/variance thresholds and even supplies fixed regime probabilities. 

That is useful scaffolding.

It is **not yet a scientifically validated regime-detection capability**.

The same applies to the current predictability estimator, which uses heuristic weights over history length, data quality and signal strength. 

So the first production rule should be:

> **No capability receives CERTIFIED status merely because an implementation exists.**

---

# 2. Create a Forecasting Capability Certification Model

Every component should have a certification record.

For example:

```yaml
capability:
  id: F-REGIME-DETECTION
  version: 0.1.0

implementation:
  status: IMPLEMENTED

mathematical:
  status: PARTIAL

empirical:
  status: NOT_VALIDATED

reproducibility:
  status: PENDING

adversarial:
  status: PENDING

scalability:
  status: PENDING

production:
  status: BLOCKED

blockers:
  - no validated statistical regime detector
  - no out_of_sample benchmark
  - no calibration evidence
```

Then Tiannara can never accidentally confuse:

```text
code exists
```

with:

```text
capability is trustworthy
```

---

# 3. Production certification should have 12 gates

I would make the forecasting/EFDI production pipeline:

```text
P0  CONTRACT
 ↓
P1  MATHEMATICAL CORRECTNESS
 ↓
P2  DATA / TEMPORAL INTEGRITY
 ↓
P3  DETERMINISTIC REPRODUCIBILITY
 ↓
P4  STATISTICAL VALIDATION
 ↓
P5  OUT-OF-SAMPLE VALIDATION
 ↓
P6  ADVERSARIAL / FAILURE TESTING
 ↓
P7  PERFORMANCE / SCALE
 ↓
P8  FAULT TOLERANCE
 ↓
P9  OBSERVABILITY / AUDIT
 ↓
P10 SECURITY / GOVERNANCE
 ↓
P11 LIVE SHADOW VALIDATION
 ↓
P12 PRODUCTION CERTIFICATION
```

**No skipped gates.**

---

# 4. P0 — Freeze the capability contract

Before improving implementation, define exactly what each subsystem claims to do.

For example:

```text
Forecasting
Signal Intelligence
Predictability
Calibration
Regime Detection
Ensemble Intelligence
Counterfactuals
Postmortem
Forecast Evolution
EFDI
```

Each gets:

```text
Purpose
Inputs
Outputs
Invariants
Assumptions
Failure states
Evidence requirements
Metrics
Dependencies
Security boundaries
Performance requirements
```

This fits the existing Tiannara philosophy of explicit interfaces and independent verification.

---

# 5. P1 — Mathematical correctness

This is where I would be particularly strict.

The current code contains several mathematical shortcuts that should **not** survive certification.

For example, ensemble weighting currently uses inverse error:

```text
1 / (error + epsilon)
```

as the weighting mechanism. 

That is acceptable as an experimental baseline.

It is not a universally justified ensemble method.

Similarly, the current counterfactual engine samples outcomes directly from a supplied probability. 

That is **Monte Carlo sampling**, not a complete causal counterfactual model.

Therefore each mathematical subsystem needs:

```text
analytical reference
+
independent implementation
+
property tests
+
boundary tests
+
numerical stability tests
+
known-answer tests
```

---

# 6. P2 — Temporal/data integrity

This deserves constitutional status.

Every forecast must carry an explicit:

```text
forecast_time
information_cutoff
observation_time
event_time
resolution_time
```

And:

```text
dataset_version
source_version
feature_version
knowledge_state
```

The fundamental invariant:

> **No information whose availability timestamp is later than the forecast cutoff may influence the forecast.**

Build a dedicated:

```text
TemporalIntegrityEngine
```

with:

```text
verify_cutoff/2
detect_future_leakage/2
reconstruct_information_state/2
verify_event_order/2
verify_revision_state/2
```

This should be a **hard production gate**, not merely a test.

---

# 7. P3 — Exact replay

The Forecast Time Machine should become real infrastructure.

Given:

```text
forecast_id
data_snapshot
model_version
signal_versions
knowledge_version
configuration
random_seed
software_commit
environment
```

Tiannara should reconstruct the forecast.

Your current lineage implementation records parent/child relationships, which is useful, but production lineage needs considerably more than parent IDs. 

I would require:

```text
FORECAST_REPLAYABLE
```

before certification.

---

# 8. P4 — Statistical validation

This is where "prediction capability" becomes scientifically meaningful.

Every forecasting method needs:

### Accuracy

```text
Brier
Log Loss
MAE
RMSE
CRPS
```

where appropriate.

### Calibration

```text
reliability
ECE
calibration slope
calibration intercept
coverage
```

### Sharpness

How concentrated are predictions?

### Resolution

Can the system meaningfully distinguish high- and low-probability cases?

### Discrimination

Can it rank outcomes appropriately?

### Baseline improvement

```text
model
vs
naive
vs
historical
vs
persistence
vs
current champion
```

The question isn't:

> "Did it predict correctly?"

It is:

> **"Did it provide statistically defensible predictive information beyond an appropriate baseline?"**

---

# 9. P5 — Out-of-sample certification

I would make this extremely strict.

Use:

```text
historical training
→ validation
→ frozen test
→ rolling-origin evaluation
→ live shadow
```

For time-dependent systems, ordinary random train/test splitting is often inappropriate.

Use temporal evaluation:

```text
T1 → train
T2 → validate

T1+T2 → train
T3 → validate

T1+T2+T3 → train
T4 → validate
```

This lets Tiannara determine whether forecasting survives time.

---

# 10. P6 — Adversarial validation

Your existing adversarial layer is a good starting point, but currently some pieces are simple heuristics—for example, the manipulation detector is essentially a z-score/outlier detector. 

Production hardening should expand it to:

```text
data corruption
timestamp corruption
future leakage
missing data
duplicate data
outliers
adversarial signals
distribution shifts
regime changes
source failures
model poisoning
confidence manipulation
correlated model failures
```

And test:

> Does Tiannara become **more confident** when the evidence becomes misleading?

That is one of the most dangerous failure modes.

---

# 11. P7 — Scale and performance

Production means we need evidence for:

```text
1 forecast
100 forecasts
10,000 forecasts
1,000,000 forecasts
```

Measure:

```text
latency
throughput
memory
CPU
GC pressure
ETS/DETS pressure
message queue pressure
NATS pressure
persistence throughput
replay throughput
```

And importantly:

```text
forecast correctness
```

must not degrade under load.

---

# 12. P8 — Failure isolation

Because Tiannara is OTP-based, exploit BEAM's strengths.

Structure:

```text
ForecastSupervisor
├── SignalSupervisor
├── ModelSupervisor
├── CalibrationSupervisor
├── RegimeSupervisor
├── EvaluationSupervisor
├── ReplaySupervisor
├── PostmortemSupervisor
└── IntegritySupervisor
```

A bad model should die without killing:

```text
forecast ledger
```

A bad signal source should not corrupt:

```text
historical forecasts
```

A failed external feed should produce:

```text
SOURCE_UNAVAILABLE
```

—not fake values.

---

# 13. P9 — Observability

Production forecasting requires two kinds of telemetry.

### System telemetry

```text
latency
throughput
errors
memory
CPU
queue depth
process health
```

### Epistemic telemetry

This is more important.

```text
calibration drift
confidence inflation
model disagreement
signal degradation
distribution shift
abstention rate
forecast error
forecast bias
regime instability
data freshness
source reliability
```

I would make a dedicated:

```text
ForecastObservability
```

and connect it to CIS.

---

# 14. P10 — Governance

Forecasting should never directly mutate Tiannara's authoritative knowledge.

Use:

```text
Forecast
   ↓
Evidence
   ↓
Evaluation
   ↓
Knowledge Candidate
   ↓
Validation
   ↓
Knowledge Promotion
```

Similarly:

```text
New forecasting method
   ↓
Research Candidate
   ↓
Sandbox
   ↓
Benchmark
   ↓
Replication
   ↓
Gate
   ↓
Production Candidate
   ↓
Human/Council authorization where required
```

This is consistent with the broader Tiannara design: the Research Director should prioritize experiments by expected information gain and uncertainty reduction rather than endlessly generating discoveries. 

---

# 15. P11 — Live shadow mode

This is the bridge between laboratory and production.

Run:

```text
CURRENT_PRODUCTION
        │
        ├── actual decisions
        │
        └── Candidate Forecasting System
                  │
                  └── predictions only
```

Candidate systems must **not control production**.

For a sufficiently long period:

```text
predict
→ record
→ wait
→ resolve
→ score
→ compare
```

Only after the candidate demonstrates superiority should promotion even be considered.

---

# 16. P12 — Production certification

Certification should require something like:

```yaml
production_certification:

  mathematical_correctness: PASS
  temporal_integrity: PASS
  leakage_tests: PASS

  reproducibility: PASS
  statistical_validation: PASS
  out_of_sample: PASS

  calibration: PASS
  baseline_superiority: PASS

  adversarial: PASS
  stress: PASS
  scalability: PASS
  fault_recovery: PASS

  observability: PASS
  provenance: PASS
  auditability: PASS
  security: PASS

  shadow_mode: PASS

  regression_suite: PASS
  long_duration: PASS

  governance: PASS
  rollback: PASS

  status: CERTIFIED
```

Otherwise:

```text
NOT_CERTIFIED
```

---

# 17. Most important correction: don't build "production" on the current Store abstraction

The uploaded implementation uses a generic `Store.put/append/get` pattern extensively. For example, the ledger writes frozen forecasts through `Store.put`. 

That's excellent for proving architecture and building tests.

But production requires a real persistence contract.

I would separate:

```text
Forecast Domain
       ↓
Persistence Port
       ↓
┌──────────────┬───────────────┐
│              │               │
ETS/DETS       PostgreSQL      immutable archive
dev/test       production      long-term evidence
```

The domain should not know whether persistence is ETS, PostgreSQL, or another backend.

This also makes the forecasting system replaceable and scalable.

---

# 18. Make every boundary an interface

For example:

```elixir
defmodule Tiannara.Forecasting.Ports.ForecastRepository do
  @callback append(Forecast.t()) ::
              {:ok, Forecast.t()} | {:error, term()}

  @callback get(Forecast.id()) ::
              {:ok, Forecast.t()} | {:error, :not_found}
end
```

Then:

```text
ForecastRepository.Memory
ForecastRepository.Postgres
ForecastRepository.Archive
```

can be independently tested.

Same for:

```text
DataSource
SignalProvider
ModelRunner
Clock
RNG
EvidenceStore
ExperimentRunner
ExternalFeed
```

This is how you prevent the forecasting architecture from becoming coupled to today's implementation.

---

# 19. Make clocks injectable

Don't scatter:

```elixir
System.system_time(...)
```

through scientific code.

The current implementation does this in multiple places—for example, resolution timestamps and knowledge edges.  

Instead:

```elixir
Tiannara.Time.now()
```

with:

```text
SystemClock
FrozenClock
ReplayClock
SimulationClock
```

This is essential for:

* replay
* simulation
* temporal testing
* deterministic experiments
* historical reconstruction.

---

# 20. Same with randomness

Your current RNG abstraction is directionally correct because simulations receive explicit seeds. 

Make this constitutional:

```text
No scientific stochastic computation without an explicit RNG context.
```

Record:

```text
algorithm
seed
stream
draw count
```

where reproducibility requires it.

---

# 21. EFDI should sit above Forecasting, not duplicate it

I would now clarify the architecture:

```text
                 MATHEMATICS
                      │
                      ▼
              EVIDENCE SUBSTRATE
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
   FORECASTING               EXPERIMENTATION
          │                       │
          └───────────┬───────────┘
                      ▼
                   EFDI
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
     DECISION      RESEARCH      ENGINEERING
     SUPPORT       PRIORITY      PRIORITY
```

EFDI should answer:

> **Given what Tiannara currently knows, what should humans investigate, build, test, monitor, or reconsider?**

Forecasting answers:

> **What is likely to happen?**

EFDI answers:

> **What does that imply for evidence, decisions and action?**

That distinction prevents duplicated logic.

---

# 22. EFDI production contract

EFDI should never simply consume:

```text
prediction = 0.8
```

It should consume something like:

```yaml
forecast:
  probability: 0.80

forecast_quality:
  calibration: 0.91
  sample_size: 1832
  out_of_sample: true
  regime_stability: 0.72

uncertainty:
  epistemic: 0.21
  aleatoric: 0.34

evidence:
  supporting: 14
  contradictory: 5

decision_context:
  impact: high
  reversibility: medium
```

Then EFDI can reason about **forecast quality**, not merely forecast magnitude.

---

# 23. Introduce Decision Reliability

This is one of the strongest hardening additions I'd make.

A decision should carry:

```text
forecast_quality
+
evidence_quality
+
uncertainty
+
reversibility
+
consequence
+
optionality
```

So Tiannara could distinguish:

```text
HIGH forecast confidence
LOW decision confidence
```

from:

```text
LOW forecast confidence
LOW consequence
```

The correct action could be completely different.

---

# 24. Build a "Production Readiness Matrix"

For every forecasting capability:

| Capability       | Code | Math | Empirical | Replay | Adversarial | Scale | Governance | Status  |
| ---------------- | ---- | ---- | --------- | ------ | ----------- | ----- | ---------- | ------- |
| Forecast Ledger  | ✓    | ✓    | —         | ✓      | ✓           | P     | ✓          | Pending |
| Baselines        | ✓    | P    | P         | P      | P           | P     | ✓          | Pending |
| Calibration      | ✓    | P    | ✗         | P      | P           | P     | ✓          | Blocked |
| Predictability   | ✓    | ✗    | ✗         | P      | P           | P     | ✓          | Blocked |
| Regime Detection | ✓    | ✗    | ✗         | P      | ✗           | P     | ✓          | Blocked |
| Ensemble         | ✓    | P    | ✗         | P      | P           | P     | ✓          | Blocked |
| Counterfactual   | ✓    | ✗    | ✗         | P      | P           | P     | ✓          | Blocked |
| Postmortem       | ✓    | P    | P         | P      | P           | P     | ✓          | Pending |
| Genome Evolution | ✓    | P    | ✗         | P      | ✗           | P     | ✗          | Blocked |
| EFDI             | ✓    | P    | ✗         | P      | P           | P     | ✗          | Blocked |

`P = pending evidence`.

That table is deliberately conservative.

---

# 25. Do not let "production ready" become one giant gate

There should be separate certification levels:

```text
C0  STRUCTURAL
C1  UNIT VERIFIED
C2  MATHEMATICALLY VERIFIED
C3  EMPIRICALLY VALIDATED
C4  REPRODUCIBLE
C5  ADVERSARIAL HARDENED
C6  PERFORMANCE VALIDATED
C7  SHADOW VALIDATED
C8  PRODUCTION CERTIFIED
```

A capability can therefore be:

```text
Calibration = C3
Regime Detection = C1
Ledger = C7
Genome Evolution = C2
```

instead of the whole subsystem being falsely labeled "complete."

---

# 26. Production requires a permanent regression corpus

Build:

```text
forecasting/
  certification/
    fixtures/
    historical/
    adversarial/
    mathematical/
    leakage/
    regime/
    calibration/
    replay/
```

Every discovered failure becomes a permanent regression case.

This creates:

```text
failure
 ↓
test
 ↓
permanent institutional memory
```

That fits Tiannara's broader philosophy exceptionally well.

---

# 27. Production requires a Champion/Challenger system

Never overwrite the existing forecasting architecture immediately.

Use:

```text
CHAMPION
   │
   ├── live/shadow
   │
   └── compare
          ▲
          │
      CHALLENGER
```

Candidate replacement must demonstrate:

```text
better predictive performance
AND
no unacceptable calibration degradation
AND
no increased failure severity
AND
no unacceptable computational cost
AND
no regression in robustness
```

Then promote.

---

# 28. Rollback must be instantaneous

Every production forecasting component needs:

```text
current
previous
known-good
candidate
```

states.

Promotion:

```text
candidate → current
```

must be reversible:

```text
current → previous
```

without reconstructing the system manually.

---

# 29. Never automatically learn from one prediction

This is extremely important.

Suppose Tiannara predicts:

```text
70%
```

and it fails.

Do **not** immediately modify the model.

Instead:

```text
failure
 ↓
classify
 ↓
was it noise?
 ↓
was it data?
 ↓
was it model?
 ↓
was it regime?
 ↓
was it calibration?
 ↓
was it an unknown?
 ↓
generate hypothesis
 ↓
test hypothesis
```

The current postmortem subsystem already points in this direction by classifying failure types and generating targeted replay/signal-audit hypotheses.  

Production hardening means making that process **evidence-based rather than heuristic**.

---

# 30. Make self-improvement conservative

The evolution system is potentially the most dangerous subsystem.

Current genome mutation can alter components such as:

```text
signal_extractors
candidate_models
ensemble_policy
calibration_method
regime_detector
```



That's exactly the right architectural direction.

But production rules should be:

```text
Mutation ≠ Improvement

Improvement ≠ Validation

Validation ≠ Deployment
```

Instead:

```text
mutation
 ↓
candidate
 ↓
isolated benchmark
 ↓
historical replay
 ↓
frozen holdout
 ↓
adversarial test
 ↓
replication
 ↓
shadow mode
 ↓
governance gate
 ↓
promotion
```

---

# 31. Make production code boring

This is important.

The research layer can be extremely sophisticated.

The production execution layer should be boring:

```text
typed
explicit
small
deterministic
observable
well-tested
versioned
fault-tolerant
```

Don't put experimental mathematics directly inside production supervisors.

Use:

```text
Research implementation
       ↓
validated artifact
       ↓
production adapter
```

This preserves Tiannara's ability to experiment without destabilizing the runtime.

---

# 32. The final architecture I would freeze toward

```text
                    ┌───────────────────────┐
                    │   CONSTITUTIONAL      │
                    │      GOVERNANCE       │
                    └───────────┬───────────┘
                                │
                    ┌───────────▼───────────┐
                    │ MATHEMATICAL SUBSTRATE│
                    └───────────┬───────────┘
                                │
                    ┌───────────▼───────────┐
                    │   EVIDENCE / REALITY  │
                    │       SUBSTRATE        │
                    └───────────┬───────────┘
                                │
          ┌─────────────────────┼─────────────────────┐
          ▼                     ▼                     ▼
     SIGNAL INTEL         FORECAST CORE         EXPERIMENTS
          │                     │                     │
          └─────────────────────┼─────────────────────┘
                                ▼
                         UNCERTAINTY CORE
                                │
                                ▼
                       CALIBRATION / SCORING
                                │
                                ▼
                     COUNTERFACTUAL / SCENARIO
                                │
                                ▼
                              EFDI
                                │
             ┌──────────────────┼──────────────────┐
             ▼                  ▼                  ▼
         DECISIONS          RESEARCH          ENGINEERING
             │                  │                  │
             └──────────────────┼──────────────────┘
                                ▼
                           REAL WORLD
                                │
                                ▼
                            OUTCOMES
                                │
                                ▼
                          POSTMORTEMS
                                │
                                ▼
                         KNOWLEDGE GRAPH
                                │
                                ▼
                     FORECAST ARCHITECTURE
                           EVOLUTION
                                │
                                ▼
                      VALIDATION / GATES
                                │
                                └──────→ back to core
```

This also fits the broader Tiannara architecture where mathematical capability is intended to underpin all domains rather than remain merely one domain among many. 

---

# 33. The actual production-development sequence I recommend

**Do not implement all the fancy forecasting features first.**

I would do this:

### Stage 0 — Architecture freeze

Define:

```text
schemas
contracts
states
invariants
failure taxonomy
certification states
provenance requirements
```

### Stage 1 — Make the core scientifically correct

```text
Forecast
Ledger
Resolution
Lineage
Clock
RNG
Replay
Temporal integrity
```

### Stage 2 — Make mathematics trustworthy

```text
Probability
Bayesian
Statistics
Calibration
Scoring
Uncertainty
```

### Stage 3 — Make empirical forecasting real

```text
baselines
rolling validation
benchmarking
out-of-sample evaluation
calibration
```

### Stage 4 — Make it robust

```text
regime detection
distribution shift
signal reliability
ensemble diversity
abstention
```

### Stage 5 — Make it adversarially strong

```text
leakage
noise
manipulation
counterfactual
alternative histories
stress
```

### Stage 6 — Make it operationally strong

```text
OTP supervision
persistence
telemetry
NATS
backpressure
recovery
scaling
```

### Stage 7 — Build EFDI

Only after forecasting evidence is trustworthy.

### Stage 8 — Build evolutionary forecasting

Only after the evaluation infrastructure can reliably distinguish improvement from noise.

### Stage 9 — Shadow mode

Run against real-world streams without authority.

### Stage 10 — Production certification

Only capabilities satisfying the complete gate become production-authoritative.

---

# 34. And I would add one permanent rule to Tiannara's Constitution

> **No forecasting capability may modify authoritative knowledge, decision policy, production behavior, or its own forecasting architecture solely because a prediction was successful. Every claimed improvement must survive reproducible evaluation, appropriate baselines, out-of-sample testing, calibration analysis, adversarial testing, and governance appropriate to its impact.**

That one rule protects the entire self-improvement loop from becoming a **self-reinforcing superstition engine**.

Your uploaded roadmap already recognizes a closely related danger: Tiannara could become increasingly good at generating discoveries while becoming insufficiently good at validating them—the "Research Expansion Trap." 

For forecasting, the equivalent danger is:

```text
more predictions
      ↓
more apparent successes
      ↓
more confidence
      ↓
more self-modification
      ↓
less independent validation
      ↓
epistemic collapse
```

The production architecture should deliberately prevent that.

## The target state

I would therefore **not declare the current forecasting/EFDI code production-ready yet**.

I would declare it:

> **Architecturally promising / implementation substrate established / production certification blocked pending mathematical, empirical, temporal, reproducibility, adversarial, and operational validation.**

That is the scientifically honest status.

And once hardened, the goal is not merely for Tiannara to have "a forecasting module." It should have a **Forecasting Scientific Instrument** that can continuously demonstrate whether it is getting better—and an EFDI layer capable of turning those calibrated forecasts into better research and engineering decisions.

That is much closer to what Tiannara needs if mathematics, prediction, and foresight are going to become foundational capabilities for discovering and engineering things that don't yet exist.

Yes — I agree with the review.

The correct status for the previous artifact is:

```text
IMPLEMENTED
```

not:

```text
VALIDATED
```

and not:

```text
PRODUCTION-CERTIFIED
```

The most important correction is that the system must not allow structural presence, plausible heuristics, or self-supplied approvals to become evidence of production trust.

Below is the corrected production-hardening layer. These files either replace the corresponding previous files or add new required subsystems.

---

# 1. Updated application bootstrap

```elixir
# lib/tiannara/forecasting/application.ex
defmodule Tiannara.Forecasting.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Tiannara.Forecasting.Adapters.MemoryRegistry,
      Tiannara.Forecasting.Adapters.MemoryForecastRepository,
      Tiannara.Forecasting.Adapters.MemoryEvidenceStore,
      Tiannara.Forecasting.Governance.AuthorizationLedger,
      Tiannara.Forecasting.Experiments.Ledger,
      Tiannara.Forecasting.Integrity.Supervisor
    ]

    {:ok, sup} =
      Supervisor.start_link(children,
        strategy: :one_for_one,
        name: Tiannara.Forecasting.Supervisor
      )

    :ok = Tiannara.Forecasting.Capability.Engine.seed_defaults()

    {:ok, sup}
  end
end
```

---

# 2. Canonical hashing

```elixir
# lib/tiannara/forecasting/kernel/canonical_hash.ex
defmodule Tiannara.Forecasting.Kernel.CanonicalHash do
  @moduledoc false

  def sha256_hex(term) do
    term
    |> normalize()
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  def normalize(%_{} = struct) do
    {:struct, struct.__struct__, normalize(Map.from_struct(struct))}
  end

  def normalize(term) when is_map(term) do
    normalized =
      term
      |> Enum.map(fn {k, v} -> {normalize(k), normalize(v)} end)
      |> Enum.sort()

    {:map, normalized}
  end

  def normalize(term) when is_list(term) do
    {:list, Enum.map(term, &normalize/1)}
  end

  def normalize(term) when is_tuple(term) do
    {:tuple, term |> Tuple.to_list() |> Enum.map(&normalize/1)}
  end

  def normalize(term) when is_atom(term) do
    {:atom, Atom.to_string(term)}
  end

  def normalize(term) when is_integer(term) do
    {:int, term}
  end

  def normalize(term) when is_float(term) do
    {:float, :erlang.float_to_binary(term, [:short])}
  end

  def normalize(term) when is_binary(term) do
    {:binary, term}
  end

  def normalize(term) do
    {:unknown, inspect(term, limit: :infinity, printable_limit: :infinity)}
  end
end
```

---

# 3. Governance authorization ledger

This separates **authorization** from the capability record.

```elixir
# lib/tiannara/forecasting/governance/authorization_ledger.ex
defmodule Tiannara.Forecasting.Governance.AuthorizationLedger do
  @moduledoc false
  use GenServer

  alias Tiannara.Forecasting.Kernel.{CanonicalHash, Clock, ID}

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def digest(term) do
    CanonicalHash.sha256_hex(term)
  end

  def authorize(attrs) do
    GenServer.call(__MODULE__, {:authorize, attrs})
  end

  def get(authorization_id) do
    case :ets.lookup(:tf_authorizations, authorization_id) do
      [{^authorization_id, authorization}] -> {:ok, authorization}
      [] -> {:error, :not_found}
    end
  end

  def list do
    :ets.tab2list(:tf_authorizations) |> Enum.map(&elem(&1, 1))
  end

  @impl true
  def init(_) do
    if :ets.whereis(:tf_authorizations) == :undefined do
      :ets.new(:tf_authorizations, [:set, :protected, :named_table])
    end

    {:ok, %{}}
  end

  @impl true
  def handle_call({:authorize, attrs}, _from, state) do
    attrs = Map.new(attrs)

    required = [
      :capability_id,
      :capability_version,
      :decision,
      :authorized_by,
      :constitutional_rule,
      :evidence_digest,
      :gate_snapshot_digest
    ]

    missing = Enum.reject(required, &Map.has_key?(attrs, &1))

    reply =
      cond do
        missing != [] ->
          {:error, {:missing_authorization_fields, missing}}

        attrs.decision not in [:approve, :deny] ->
          {:error, :invalid_authorization_decision}

        true ->
          authorization = %{
            id: ID.new("AUTH"),
            capability_id: attrs.capability_id,
            capability_version: attrs.capability_version,
            decision: attrs.decision,
            authorized_by: attrs.authorized_by,
            constitutional_rule: attrs.constitutional_rule,
            evidence_digest: attrs.evidence_digest,
            gate_snapshot_digest: attrs.gate_snapshot_digest,
            timestamp: Clock.now_unix(),
            expires_at: Map.get(attrs, :expires_at)
          }

          :ets.insert(:tf_authorizations, {authorization.id, authorization})
          {:ok, authorization}
      end

    {:reply, reply, state}
  end
end
```

---

# 4. Corrected capability certification

This removes self-supplied approval from the capability object.

```elixir
# lib/tiannara/forecasting/capability/certification.ex
defmodule Tiannara.Forecasting.Capability.Certification do
  @moduledoc false

  @gates [
    :contract,
    :mathematical_correctness,
    :temporal_integrity,
    :deterministic_reproducibility,
    :statistical_validation,
    :out_of_sample,
    :adversarial,
    :performance_scale,
    :fault_tolerance,
    :observability_audit,
    :security_governance,
    :live_shadow
  ]

  defstruct capability_id: nil,
            version: "0.1.0",
            implementation_status: :implemented,
            gates: %{},
            blockers: [],
            authorization_id: nil,
            production_state: :blocked,
            updated_at: nil

  def gates, do: @gates

  def new(capability_id, version, now) do
    %__MODULE__{
      capability_id: capability_id,
      version: version,
      gates: Map.new(@gates, &{&1, %{status: :pending, evidence: nil, at: nil}}),
      updated_at: now
    }
  end

  def record_gate(%__MODULE__{} = capability, gate, result, evidence, now)
      when gate in @gates and result in [:pass, :fail, :pending] do
    gates =
      Map.put(capability.gates, gate, %{
        status: result,
        evidence: evidence,
        at: now
      })

    blockers =
      if result == :fail do
        Enum.uniq([gate | capability.blockers])
      else
        List.delete(capability.blockers, gate)
      end

    %{capability | gates: gates, blockers: blockers, updated_at: now}
  end

  def missing_gates(%__MODULE__{} = capability) do
    Enum.filter(@gates, fn gate ->
      get_in(capability.gates, [gate, :status]) != :pass
    end)
  end

  def eligible?(%__MODULE__{} = capability) do
    missing_gates(capability) == []
  end

  def production?(%__MODULE__{} = capability) do
    capability.production_state == :certified
  end

  def state(%__MODULE__{} = capability) do
    cond do
      production?(capability) -> :production_certified
      eligible?(capability) -> :eligible_for_authorization
      validated?(capability) -> :validated
      capability.implementation_status == :implemented -> :implemented
      true -> :theatrical
    end
  end

  defp validated?(%__MODULE__{} = capability) do
    Enum.all?(
      [
        :mathematical_correctness,
        :statistical_validation,
        :out_of_sample,
        :deterministic_reproducibility
      ],
      fn gate ->
        get_in(capability.gates, [gate, :status]) == :pass
      end
    )
  end
end
```

---

# 5. Corrected capability engine

Certification now requires a separate governance authorization artifact.

```elixir
# lib/tiannara/forecasting/capability/engine.ex
defmodule Tiannara.Forecasting.Capability.Engine do
  @moduledoc false

  alias Tiannara.Forecasting.Capability.Certification
  alias Tiannara.Forecasting.Governance.AuthorizationLedger
  alias Tiannara.Forecasting.Adapters.MemoryRegistry
  alias Tiannara.Forecasting.Kernel.Clock

  @default_capabilities [
    :forecast_core,
    :calibration,
    :regime_detection,
    :predictability,
    :ensemble,
    :counterfactual,
    :evolution,
    :efdi
  ]

  def seed_defaults do
    Enum.each(@default_capabilities, fn capability_id ->
      register_capability(capability_id)
    end)

    :ok
  end

  def register_capability(capability_id, version \\ "0.1.0") do
    capability = Certification.new(capability_id, version, Clock.now_unix())
    MemoryRegistry.put_capability(capability)
    {:ok, capability}
  end

  def get(capability_id) do
    MemoryRegistry.get_capability(capability_id)
  end

  def record_gate(capability_id, gate, result, evidence \\ %{}) do
    with {:ok, capability} <- get(capability_id) do
      updated =
        Certification.record_gate(
          capability,
          gate,
          result,
          evidence,
          Clock.now_unix()
        )

      MemoryRegistry.put_capability(updated)
      {:ok, updated}
    end
  end

  def certify(capability_id, authorization_id) do
    with {:ok, capability} <- get(capability_id),
         :ok <- ensure_eligible(capability),
         {:ok, authorization} <- AuthorizationLedger.get(authorization_id),
         :ok <- validate_authorization(capability, authorization),
         :ok <- validate_gate_digest(capability, authorization) do
      updated = %{
        capability
        | authorization_id: authorization_id,
          production_state: :certified,
          updated_at: Clock.now_unix()
      }

      MemoryRegistry.put_capability(updated)
      {:ok, updated}
    end
  end

  def matrix do
    MemoryRegistry.list_capabilities()
    |> Enum.map(fn capability ->
      %{
        capability_id: capability.capability_id,
        version: capability.version,
        state: Certification.state(capability),
        production_state: capability.production_state,
        authorization_id: capability.authorization_id,
        blockers: capability.blockers,
        missing_gates: Certification.missing_gates(capability),
        gates: capability.gates
      }
    end)
  end

  def confidence_in_confidence(capability_id) do
    state =
      case get(capability_id) do
        {:ok, capability} -> Certification.state(capability)
        _ -> :theatrical
      end

    value =
      case state do
        :production_certified -> 0.9
        :validated -> 0.6
        :eligible_for_authorization -> 0.3
        :implemented -> 0.2
        _ -> 0.05
      end

    %{
      value: value,
      state: state,
      rationale:
        "Confidence-in-confidence is derived from certification state and separate governance authorization. It is not outcome confidence."
    }
  end

  defp ensure_eligible(capability) do
    missing = Certification.missing_gates(capability)

    if missing == [] do
      :ok
    else
      {:error, {:capability_not_eligible, missing}}
    end
  end

  defp validate_authorization(capability, authorization) do
    now = Clock.now_unix()

    cond do
      authorization.decision != :approve ->
        {:error, :authorization_not_approved}

      authorization.capability_id != capability.capability_id ->
        {:error, :authorization_capability_mismatch}

      authorization.capability_version != capability.version ->
        {:error, :authorization_version_mismatch}

      authorization.expires_at != nil and authorization.expires_at <= now ->
        {:error, :authorization_expired}

      true ->
        :ok
    end
  end

  defp validate_gate_digest(capability, authorization) do
    digest = AuthorizationLedger.digest(capability.gates)

    if digest == authorization.gate_snapshot_digest do
      :ok
    else
      {:error, :gate_snapshot_mismatch}
    end
  end
end
```

---

# 6. Vintage-aware temporal integrity

```elixir
# lib/tiannara/forecasting/core/temporal_integrity.ex
defmodule Tiannara.Forecasting.Core.TemporalIntegrity do
  @moduledoc false

  def verify_request(%{cutoff: cutoff, observations: observations}) do
    with :ok <- verify_cutoff(cutoff),
         {:ok, warnings} <- verify_observations(observations, cutoff) do
      {:ok, %{warnings: warnings}}
    end
  end

  def verify_cutoff(cutoff) when is_integer(cutoff), do: :ok
  def verify_cutoff(_), do: {:error, {:temporal_integrity, :invalid_cutoff}}

  def verify_observations([], _cutoff), do: {:ok, []}

  def verify_observations(observations, cutoff) when is_list(observations) do
    Enum.reduce_while(observations, {:ok, []}, fn observation, {:ok, acc_warnings} ->
      case verify_observation(observation, cutoff) do
        {:ok, warnings} -> {:cont, {:ok, acc_warnings ++ warnings}}
        error -> {:halt, error}
      end
    end)
  end

  def verify_observations(_, _), do: {:error, {:temporal_integrity, :invalid_observations}}

  def reconstruct_information_state(observations, cutoff) do
    Enum.filter(observations, fn observation ->
      availability =
        Map.get(observation, :availability_time) ||
          Map.get(observation, :ingestion_time, 0)

      revision_time = Map.get(observation, :revision_time)

      availability <= cutoff and
        (is_nil(revision_time) or revision_time <= cutoff)
    end)
  end

  def detect_future_leakage(features, cutoff) when is_map(features) do
    Enum.filter(features, fn
      {_key, value} when is_integer(value) -> value > cutoff
      {_key, %{available_at: available_at}} -> available_at > cutoff
      {_key, _value} -> false
    end)
  end

  defp verify_observation(observation, cutoff) do
    with {:ok, event_time} <- fetch_required(observation, :event_time),
         {:ok, observation_time} <- fetch_required(observation, :observation_time),
         {:ok, ingestion_time} <- fetch_required(observation, :ingestion_time),
         {:ok, publication_time} <- fetch_optional(observation, :publication_time),
         {:ok, availability_time} <- fetch_optional(observation, :availability_time),
         {:ok, revision_time} <- fetch_optional(observation, :revision_time) do
      warnings = []

      availability_time =
        if is_nil(availability_time) do
          inferred =
            [ingestion_time, publication_time]
            |> Enum.reject(&is_nil/1)
            |> Enum.max(fn -> ingestion_time end)

          warnings = [:availability_time_inferred | warnings]
          {inferred, warnings}
        else
          {availability_time, warnings}
        end

      {availability_time, warnings} =
        case availability_time do
          {value, warnings} -> {value, warnings}
          value when is_integer(value) -> {value, warnings}
        end

      cond do
        event_time > observation_time ->
          {:error, {:temporal_integrity, {:temporal_order_violation, :event_time}}}

        publication_time != nil and publication_time < observation_time ->
          {:error, {:temporal_integrity, {:temporal_order_violation, :publication_time}}}

        publication_time != nil and availability_time < publication_time ->
          {:error, {:temporal_integrity, {:temporal_order_violation, :availability_time}}}

        revision_time != nil and revision_time < observation_time ->
          {:error, {:temporal_integrity, {:temporal_order_violation, :revision_time}}}

        revision_time != nil and revision_time > cutoff ->
          {:error, {:temporal_integrity, {:future_timestamp, :revision_time}}}

        ingestion_time > cutoff ->
          {:error, {:temporal_integrity, {:future_timestamp, :ingestion_time}}}

        availability_time > cutoff ->
          {:error, {:temporal_integrity, {:future_timestamp, :availability_time}}}

        true ->
          {:ok, Enum.reverse(warnings)}
      end
    end
  end

  defp fetch_required(observation, key) do
    case Map.fetch(observation, key) do
      {:ok, value} when is_integer(value) -> {:ok, value}
      _ -> {:error, {:temporal_integrity, {:invalid_timestamp, key}}}
    end
  end

  defp fetch_optional(observation, key) do
    case Map.fetch(observation, key) do
      :error -> {:ok, nil}
      {:ok, value} when is_integer(value) -> {:ok, value}
      _ -> {:error, {:temporal_integrity, {:invalid_timestamp, key}}}
    end
  end
end
```

---

# 7. Execution manifest

```elixir
# lib/tiannara/forecasting/core/execution_manifest.ex
defmodule Tiannara.Forecasting.Core.ExecutionManifest do
  @moduledoc false

  alias Tiannara.Forecasting.Kernel.CanonicalHash

  defstruct forecast_id: nil,
            request_digest: nil,
            data_snapshot_digest: nil,
            feature_snapshot_digest: nil,
            source_snapshot_digest: nil,
            model_manifest: nil,
            signal_manifest: nil,
            calibration_manifest: nil,
            regime_manifest: nil,
            knowledge_version: nil,
            configuration_digest: nil,
            software_commit: nil,
            dependency_lock_digest: nil,
            runtime_version: nil,
            rng_record: nil,
            manifest_digest: nil,
            cryptographic_profile: :sha256_canonical_v1,
            environment_attestation: :self_reported

  def build(params) do
    params = Map.new(params)

    fields = %{
      forecast_id: Map.get(params, :forecast_id),
      request_digest: digest(Map.fetch!(params, :request)),
      data_snapshot_digest: digest(Map.get(params, :data_snapshot, %{})),
      feature_snapshot_digest: digest(Map.get(params, :feature_snapshot, %{})),
      source_snapshot_digest: digest(Map.get(params, :source_snapshot, %{})),
      model_manifest: Map.get(params, :model_manifest, %{status: :unspecified}),
      signal_manifest: Map.get(params, :signal_manifest, %{status: :unspecified}),
      calibration_manifest: Map.get(params, :calibration_manifest, %{status: :unspecified}),
      regime_manifest: Map.get(params, :regime_manifest, %{status: :unspecified}),
      knowledge_version: Map.get(params, :knowledge_version, :unknown),
      configuration_digest: digest(Map.get(params, :configuration, %{})),
      software_commit: Map.get(params, :software_commit, :unknown),
      dependency_lock_digest: Map.get(params, :dependency_lock_digest, :unknown),
      runtime_version: Map.get(params, :runtime_version, :unknown),
      rng_record: Map.fetch!(params, :rng_record),
      cryptographic_profile: :sha256_canonical_v1,
      environment_attestation: Map.get(params, :environment_attestation, :self_reported)
    }

    manifest = struct(__MODULE__, fields)

    manifest_digest =
      manifest
      |> Map.from_struct()
      |> Map.delete(:manifest_digest)
      |> digest()

    %{manifest | manifest_digest: manifest_digest}
  end

  def reconstruct_from_forecast(forecast) do
    build(%{
      forecast_id: forecast.id,
      request: forecast.request,
      data_snapshot: forecast.data_snapshot,
      feature_snapshot: forecast.feature_versions,
      source_snapshot: forecast.source_versions,
      model_manifest: forecast.execution_manifest.model_manifest,
      signal_manifest: forecast.execution_manifest.signal_manifest,
      calibration_manifest: forecast.execution_manifest.calibration_manifest,
      regime_manifest: forecast.execution_manifest.regime_manifest,
      knowledge_version: forecast.execution_manifest.knowledge_version,
      configuration: %{
        model_policy: forecast.request.model_policy,
        horizon: forecast.request.horizon,
        horizon_unit: forecast.request.horizon_unit,
        target: forecast.request.target,
        domain: forecast.request.domain
      },
      software_commit: forecast.execution_manifest.software_commit,
      dependency_lock_digest: forecast.execution_manifest.dependency_lock_digest,
      runtime_version: forecast.execution_manifest.runtime_version,
      rng_record: forecast.execution_manifest.rng_record,
      environment_attestation: forecast.execution_manifest.environment_attestation
    })
  end

  def verify(%__MODULE__{} = original, %__MODULE__{} = current) do
    fields = [
      :request_digest,
      :data_snapshot_digest,
      :feature_snapshot_digest,
      :source_snapshot_digest,
      :model_manifest,
      :signal_manifest,
      :calibration_manifest,
      :regime_manifest,
      :knowledge_version,
      :configuration_digest,
      :software_commit,
      :dependency_lock_digest,
      :runtime_version,
      :rng_record
    ]

    mismatches =
      Enum.filter(fields, fn field ->
        Map.get(original, field) != Map.get(current, field)
      end)

    %{
      match: mismatches == [],
      mismatches: mismatches,
      original_digest: original.manifest_digest,
      current_digest: current.manifest_digest,
      environment_attestation: original.environment_attestation
    }
  end

  defp digest(term) do
    CanonicalHash.sha256_hex(term)
  end
end
```

---

# 8. Updated forecast struct

```elixir
# lib/tiannara/forecasting/core/forecast.ex
defmodule Tiannara.Forecasting.Core.Forecast do
  @moduledoc false

  alias Tiannara.Forecasting.Kernel.{Clock, ID}
  alias Tiannara.Forecasting.Core.{ExecutionManifest, ProbabilityDistribution}

  defstruct id: nil,
            schema_version: 3,
            question: nil,
            target: nil,
            domain: nil,
            horizon: nil,
            forecast_time: nil,
            information_cutoff: nil,
            data_snapshot: %{},
            feature_versions: %{},
            source_versions: %{},
            model_versions: %{},
            signal_versions: %{},
            genome_id: nil,
            parent_forecast_id: nil,
            base_rate: nil,
            assumptions: [],
            evidence_ids: [],
            disconfirming_evidence_ids: [],
            probabilities: nil,
            uncertainty: nil,
            confidence_in_confidence: nil,
            random_seed: nil,
            rng_record: nil,
            execution_manifest: nil,
            temporal_warnings: [],
            software_version: nil,
            knowledge_version: nil,
            request: nil,
            certification_context: %{},
            reproducibility_level: :R2,
            state: :draft

  def draft(params) do
    params = Map.new(params)

    required = [
      :request,
      :probabilities,
      :base_rate,
      :model_versions,
      :execution_manifest,
      :software_version,
      :knowledge_version,
      :uncertainty,
      :confidence_in_confidence
    ]

    missing = Enum.reject(required, &Map.has_key?(params, &1))

    cond do
      missing != [] ->
        {:error, {:missing_forecast_fields, missing}}

      not match?(%ProbabilityDistribution{}, params.probabilities) ->
        {:error, :invalid_probability_distribution}

      not match?(%ExecutionManifest{}, params.execution_manifest) ->
        {:error, :invalid_execution_manifest}

      true ->
        request = params.request
        id = ID.new("F")
        now = Clock.now_unix()

        defaults = %{
          id: id,
          question: request.question,
          target: request.target,
          domain: request.domain,
          horizon: request.horizon,
          forecast_time: now,
          information_cutoff: request.cutoff,
          data_snapshot: %{
            observations:
              Tiannara.Forecasting.Core.TemporalIntegrity.reconstruct_information_state(
                request.observations,
                request.cutoff
              )
          },
          feature_versions: request.feature_versions,
          source_versions: request.source_versions,
          assumptions: request.assumptions,
          evidence_ids: request.evidence,
          parent_forecast_id: request.parent_forecast_id,
          random_seed: params.execution_manifest.rng_record.seed,
          rng_record: params.execution_manifest.rng_record,
          temporal_warnings: Map.get(params, :temporal_warnings, []),
          reproducibility_level: :R2,
          state: :draft,
          schema_version: 3
        }

        forecast = struct(__MODULE__, Map.merge(defaults, params))
        {:ok, forecast}
    end
  end

  def freeze(%__MODULE__{state: :draft} = forecast) do
    {:ok, %{forecast | state: :frozen}}
  end

  def freeze(%__MODULE__{state: state}) do
    {:error, {:invalid_forecast_state_transition, state, :frozen}}
  end

  def explain(%__MODULE__{} = forecast) do
    %{
      id: forecast.id,
      provenance: %{
        request: forecast.request,
        data_snapshot: forecast.data_snapshot,
        feature_versions: forecast.feature_versions,
        source_versions: forecast.source_versions,
        model_versions: forecast.model_versions,
        signal_versions: forecast.signal_versions,
        execution_manifest: forecast.execution_manifest,
        temporal_warnings: forecast.temporal_warnings,
        base_rate: forecast.base_rate,
        assumptions: forecast.assumptions,
        software_version: forecast.software_version,
        knowledge_version: forecast.knowledge_version,
        certification_context: forecast.certification_context
      }
    }
  end
end
```

---

# 9. Corrected replay engine

```elixir
# lib/tiannara/forecasting/core/replay_engine.ex
defmodule Tiannara.Forecasting.Core.ReplayEngine do
  @moduledoc false

  alias Tiannara.Forecasting.Kernel.RNGContext
  alias Tiannara.Forecasting.Core.{ExecutionManifest, ProbabilityDistribution}

  def replay(forecast) do
    runner = Application.fetch_env!(:tiannara_forecast, :model_runner)

    with {:ok, manifest} <- ensure_manifest(forecast.execution_manifest),
         {:ok, rng} <- ensure_rng(manifest.rng_record) do
      current_manifest = ExecutionManifest.reconstruct_from_forecast(forecast)
      manifest_verification = ExecutionManifest.verify(manifest, current_manifest)

      model_ref =
        case Map.keys(forecast.model_versions) do
          [model_id | _] ->
            %{model_id: model_id, version: Map.get(forecast.model_versions, model_id)}

          [] ->
            %{model_id: "baseline-historical", version: 1}
        end

      case runner.run(model_ref, forecast.request, rng) do
        {:ok, result} ->
          distribution_match =
            distributions_equal?(result.distribution, forecast.probabilities)

          status =
            if manifest_verification.match and distribution_match do
              :reproduced
            else
              :not_reproduced
            end

          reproducibility_level =
            reproducibility_level(
              manifest_verification.match,
              distribution_match,
              manifest.environment_attestation
            )

          {:ok,
           %{
             status: status,
             reproducibility_level: reproducibility_level,
             manifest_verification: manifest_verification,
             model_version: result.model_version,
             rng_record: RNGContext.record(result.rng),
             note:
               "R4 cryptographic reproducibility is not claimed unless independent environment attestation and canonicalization validation exist."
           }}

        error ->
          error
      end
    end
  end

  defp ensure_manifest(nil), do: {:error, :missing_execution_manifest}
  defp ensure_manifest(%ExecutionManifest{} = manifest), do: {:ok, manifest}
  defp ensure_manifest(_), do: {:error, :invalid_execution_manifest}

  defp ensure_rng(nil), do: {:error, :missing_rng_record}
  defp ensure_rng(record), do: {:ok, RNGContext.from_record(record)}

  defp reproducibility_level(false, _, _), do: :R0
  defp reproducibility_level(true, false, _), do: :R0

  defp reproducibility_level(true, true, :independent_attested), do: :R3

  defp reproducibility_level(true, true, _), do: :R2

  defp distributions_equal?(
         %ProbabilityDistribution{events: events_a},
         %ProbabilityDistribution{events: events_b}
       ) do
    keys_a = events_a |> Map.keys() |> Enum.sort()
    keys_b = events_b |> Map.keys() |> Enum.sort()

    keys_a == keys_b and
      Enum.all?(keys_a, fn key ->
        abs(Map.fetch!(events_a, key) - Map.fetch!(events_b, key)) <= 1.0e-9
      end)
  end
end
```

---

# 10. Predictability analyzer

This separates data sufficiency from forecastability, while still marking the implementation as heuristic.

```elixir
# lib/tiannara/forecasting/predictability/analyzer.ex
defmodule Tiannara.Forecasting.Predictability.Analyzer do
  @moduledoc false

  def analyze(%{observations: observations, flags: flags}) do
    values = Enum.map(observations, &Map.get(&1, :value))
    valid_values? = Enum.all?(values, &valid_value?/1)
    sample_size = length(values)

    data_sufficiency = data_sufficiency(sample_size, valid_values?)

    cond do
      not valid_values? ->
        %{
          decision: :ABSTAIN,
          data_sufficiency: data_sufficiency,
          predictability_score: 0.0,
          forecastability: 0.0,
          reasons: [:invalid_values],
          limitations: [:heuristic, :not_statistically_validated]
        }

      Map.get(flags, :distribution_shift, false) ->
        %{
          decision: :RUN_EXPERIMENT,
          data_sufficiency: data_sufficiency,
          predictability_score: 0.0,
          forecastability: 0.0,
          reasons: [:distribution_shift_detected],
          limitations: [:heuristic, :not_statistically_validated]
        }

      data_sufficiency.level == :insufficient ->
        %{
          decision: :COLLECT_MORE_DATA,
          data_sufficiency: data_sufficiency,
          predictability_score: 0.0,
          forecastability: 0.0,
          reasons: [:insufficient_history],
          limitations: [:heuristic, :not_statistically_validated]
        }

      true ->
        base_rate = mean(values)
        entropy = binary_entropy(base_rate)
        lag1 = lag1_autocorrelation(values)
        persistence_error = persistence_brier(values)
        baseline_error = constant_brier(values, base_rate)

        predictability_score =
          clamp(max(abs(lag1), 1 - entropy), 0.0, 1.0)

        forecastability =
          clamp(1 - min(1.0, baseline_error), 0.0, 1.0)

        decision =
          cond do
            predictability_score < 0.15 -> :ABSTAIN
            predictability_score < 0.35 -> :LOW_CONFIDENCE_PREDICT
            true -> :PREDICT
          end

        %{
          decision: decision,
          data_sufficiency: data_sufficiency,
          predictability_score: predictability_score,
          forecastability: forecastability,
          diagnostics: %{
            sample_size: sample_size,
            base_rate: base_rate,
            entropy: entropy,
            lag1_autocorrelation: lag1,
            persistence_brier: persistence_error,
            baseline_brier: baseline_error
          },
          reasons: [:heuristic_predictability_analysis],
          limitations: [
            :not_a_validated_forecastability_proof,
            :no_null_model_comparison,
            :no_information_theoretic_certification
          ]
        }
    end
  end

  defp data_sufficiency(sample_size, valid_values?) do
    level =
      cond do
        not valid_values? -> :invalid
        sample_size < 10 -> :insufficient
        sample_size < 30 -> :marginal
        true -> :adequate
      end

    %{
      level: level,
      sample_size: sample_size,
      valid_values: valid_values?
    }
  end

  defp valid_value?(value) do
    is_number(value) and value >= 0 and value <= 1
  end

  defp mean([]), do: 0.0
  defp mean(values), do: Enum.sum(values) / length(values)

  defp binary_entropy(p) when p <= 0.0 or p >= 1.0, do: 0.0

  defp binary_entropy(p) do
    -p * :math.log2(p) - (1 - p) * :math.log2(1 - p)
  end

  defp lag1_autocorrelation(values) when length(values) < 3, do: 0.0

  defp lag1_autocorrelation(values) do
    xs = Enum.drop(values, -1)
    ys = Enum.drop(values, 1)

    mean_x = mean(xs)
    mean_y = mean(ys)

    numerator =
      Enum.zip(xs, ys)
      |> Enum.reduce(0.0, fn {x, y}, acc ->
        acc + (x - mean_x) * (y - mean_y)
      end)

    denominator_x = variance_term(xs, mean_x)
    denominator_y = variance_term(ys, mean_y)

    if denominator_x == 0 or denominator_y == 0 do
      0.0
    else
      numerator / :math.sqrt(denominator_x * denominator_y)
    end
  end

  defp persistence_brier(values) when length(values) < 2, do: :unknown

  defp persistence_brier(values) do
    pairs =
      values
      |> Enum.chunk_every(2, 1, :discard)

    errors =
      Enum.map(pairs, fn [previous, actual] ->
        :math.pow(previous - actual, 2)
      end)

    mean(errors)
  end

  defp constant_brier(values, constant) do
    values
    |> Enum.map(fn value -> :math.pow(constant - value, 2) end)
    |> mean()
  end

  defp variance_term(values, mean) do
    Enum.reduce(values, 0.0, fn value, acc ->
      acc + :math.pow(value - mean, 2)
    end)
  end

  defp clamp(value, min, max) do
    value |> max(min) |> min(max)
  end
end
```

---

# 11. Regime detector corrected to scores, not probabilities

```elixir
# lib/tiannara/forecasting/regimes/detector.ex
defmodule Tiannara.Forecasting.Regimes.Detector do
  @moduledoc false

  def detect(series) when is_list(series) do
    if length(series) < 8 or not valid_series?(series) do
      {:ok,
       %{
         regime: :unknown,
         regime_score: %{unknown: 1.0},
         probability_claim: false,
         certification_status: :implemented_not_validated,
         note: "Insufficient or invalid series. Scores are not probabilities."
       }}
    else
      slope = linear_slope(series)
      variance = variance(series)
      break = half_difference(series)

      scores = %{
        stationary: 1.0 / (1.0 + abs(slope) + variance + break),
        trend: abs(slope),
        volatile: variance,
        structural_break: break,
        unknown: 0.05
      }

      normalized_scores = normalize_scores(scores)
      regime = normalized_scores |> Enum.max_by(fn {_k, v} -> v end) |> elem(0)

      {:ok,
       %{
         regime: regime,
         regime_score: normalized_scores,
         probability_claim: false,
         diagnostics: %{
           slope: slope,
           variance: variance,
           half_mean_difference: break
         },
         certification_status: :implemented_not_validated,
         note:
           "These are heuristic regime scores. They must not be interpreted as calibrated probabilities."
       }}
    end
  end

  defp valid_series?(series) do
    Enum.all?(series, &is_number/1)
  end

  defp mean([]), do: 0.0
  defp mean(values), do: Enum.sum(values) / length(values)

  defp variance(values) do
    m = mean(values)

    values
    |> Enum.map(fn value -> :math.pow(value - m, 2) end)
    |> Enum.sum()
    |> Kernel./(length(values))
  end

  defp linear_slope(series) do
    n = length(series)
    xs = Enum.to_list(0..(n - 1))
    mean_x = (n - 1) / 2
    mean_y = mean(series)

    covariance =
      Enum.zip(xs, series)
      |> Enum.reduce(0.0, fn {x, y}, acc ->
        acc + (x - mean_x) * (y - mean_y)
      end)

    variance_x =
      Enum.reduce(xs, 0.0, fn x, acc ->
        acc + :math.pow(x - mean_x, 2)
      end)

    if variance_x == 0 do
      0.0
    else
      covariance / variance_x
    end
  end

  defp half_difference(series) do
    half = div(length(series), 2)
    {left, right} = Enum.split(series, half)

    if left == [] or right == [] do
      0.0
    else
      abs(mean(left) - mean(right))
    end
  end

  defp normalize_scores(scores) do
    positive = Map.new(scores, fn {k, v} -> {k, max(0.0, v)} end)
    sum = positive |> Map.values() |> Enum.sum()

    if sum <= 0 do
      %{unknown: 1.0}
    else
      Map.new(positive, fn {k, v} -> {k, v / sum} end)
    end
  end
end
```

---

# 12. Hypothesis-based postmortem analyzer

```elixir
# lib/tiannara/forecasting/postmortem/analyzer.ex
defmodule Tiannara.Forecasting.Postmortem.Analyzer do
  @moduledoc false

  alias Tiannara.Forecasting.Core.TemporalIntegrity
  alias Tiannara.Forecasting.Evaluation.Scoring

  @failure_taxonomy [
    :DATA_ERROR,
    :SIGNAL_ERROR,
    :BASE_RATE_ERROR,
    :MODEL_ERROR,
    :CALIBRATION_ERROR,
    :REGIME_SHIFT,
    :CAUSAL_ERROR,
    :LEAKAGE,
    :OVERFIT,
    :UNDERFIT,
    :MEASUREMENT_ERROR,
    :RANDOM_OUTCOME,
    :ADVERSARIAL_INPUT,
    :MODEL_CORRELATION,
    :IMPLEMENTATION_ERROR,
    :UNKNOWN
  ]

  def failure_taxonomy, do: @failure_taxonomy

  def analyze(forecast, resolution, context \\ %{}) do
    brier = Scoring.brier(forecast.probabilities, resolution.outcome)

    log_score =
      case Scoring.log_score(forecast.probabilities, resolution.outcome) do
        {:ok, value} -> value
        {:error, reason} -> {:error, reason}
      end

    temporal_result = TemporalIntegrity.verify_request(forecast.request)
    temporal_ok = match?({:ok, _}, temporal_result)

    hypotheses =
      []
      |> add_hypothesis(
        not temporal_ok or Map.get(context, :leakage, false),
        :LEAKAGE,
        0.85,
        ["Temporal integrity violation or explicit leakage flag"],
        []
      )
      |> add_hypothesis(
        Map.get(context, :distribution_shift, false),
        :REGIME_SHIFT,
        0.65,
        ["Reported distribution shift"],
        ["No independent regime validation"]
      )
      |> add_hypothesis(
        brier > 0.5,
        :MODEL_ERROR,
        0.55,
        ["High Brier error"],
        ["Brier error alone does not prove model causality"]
      )
      |> add_hypothesis(
        brier > 0.25,
        :CALIBRATION_ERROR,
        0.40,
        ["Moderate probability error"],
        ["Calibration requires out-of-sample evidence"]
      )
      |> add_hypothesis(
        brier <= 0.25,
        :RANDOM_OUTCOME,
        max(0.2, 1 - brier),
        ["Forecast error is small"],
        ["Good score does not prove model skill"]
      )
      |> Enum.sort_by(& &1.confidence, :desc)

    primary = List.first(hypotheses)

    %{
      forecast_id: forecast.id,
      resolution_outcome: resolution.outcome,
      scores: %{
        brier: brier,
        log_score: log_score
      },
      temporal_integrity_ok: temporal_ok,
      failure_type: :hypothesis_set,
      primary_hypothesis: primary && primary.cause,
      failure_hypotheses: hypotheses,
      automatic_model_update: false,
      epistemic_status: :hypotheses_not_knowledge,
      required_validation: [
        :replay,
        :baseline_comparison,
        :out_of_sample_evaluation,
        :adversarial_review,
        :replication
      ]
    }
  end

  defp add_hypothesis(hypotheses, false, _cause, _confidence, _evidence_for, _evidence_against) do
    hypotheses
  end

  defp add_hypothesis(hypotheses, true, cause, confidence, evidence_for, evidence_against) do
    [
      %{
        cause: cause,
        confidence: confidence,
        status: :hypothesis,
        evidence_for: evidence_for,
        evidence_against: evidence_against
      }
      | hypotheses
    ]
  end
end
```

---

# 13. Expanded calibration suite

```elixir
# lib/tiannara/forecasting/probability/calibration.ex
defmodule Tiannara.Forecasting.Probability.Calibration do
  @moduledoc false

  def reliability_curve(pairs, bins \\ 10) when is_list(pairs) do
    grouped =
      Enum.group_by(pairs, fn {predicted, _observed} ->
        min(bins - 1, trunc(predicted * bins))
      end)

    Map.new(grouped, fn {bin, items} ->
      {bin,
       %{
         predicted: avg_predicted(items),
         observed: avg_observed(items),
         count: length(items)
       }}
    end)
  end

  def expected_calibration_error([], _bins), do: {:error, :empty_pairs}

  def expected_calibration_error(pairs, bins \\ 10) when is_list(pairs) do
    with :ok <- validate_pairs(pairs) do
      curve = reliability_curve(pairs, bins)
      total = length(pairs)

      ece =
        Enum.reduce(curve, 0.0, fn {_bin, data}, acc ->
          acc + data.count / total * abs(data.predicted - data.observed)
        end)

      {:ok, ece}
    end
  end

  def report([], _opts), do: {:error, :empty_pairs}

  def report(pairs, opts \\ []) when is_list(pairs) do
    with :ok <- validate_pairs(pairs) do
      bins = Keyword.get(opts, :bins, 10)
      curve = reliability_curve(pairs, bins)
      total = length(pairs)

      ece =
        Enum.reduce(curve, 0.0, fn {_bin, data}, acc ->
          acc + data.count / total * abs(data.predicted - data.observed)
        end)

      mce =
        curve
        |> Map.values()
        |> Enum.map(fn data -> abs(data.predicted - data.observed) end)
        |> Enum.max(fn -> 0.0 end)

      brier =
        Enum.reduce(pairs, 0.0, fn {p, observed}, acc ->
          acc + :math.pow(p - observed, 2)
        end) / total

      log_loss = log_loss(pairs)

      {:ok,
       %{
         sample_size: total,
         out_of_sample: Keyword.get(opts, :out_of_sample, false),
         reliability_curve: curve,
         ece: ece,
         mce: mce,
         brier: brier,
         log_loss: log_loss,
         interval_coverage: :not_applicable,
         sharpness: :requires_distributional_forecasts,
         resolution: :requires_more_semantics,
         note:
           "Calibration metrics are not sufficient alone. Out-of-sample validation and proper scoring context are required."
       }}
    end
  end

  defp avg_predicted(items) do
    Enum.sum(Enum.map(items, fn {p, _} -> p end)) / length(items)
  end

  defp avg_observed(items) do
    Enum.sum(Enum.map(items, fn {_, observed} -> observed * 1.0 end)) / length(items)
  end

  defp validate_pairs(pairs) do
    if Enum.all?(pairs, fn {p, observed} ->
         is_number(p) and p >= 0 and p <= 1 and observed in [0, 1]
       end) do
      :ok
    else
      {:error, :invalid_calibration_pairs}
    end
  end

  defp log_loss(pairs) do
    result =
      Enum.reduce_while(pairs, 0.0, fn {p, observed}, acc ->
        probability_observed =
          if observed == 1 do
            p
          else
            1 - p
          end

        if probability_observed <= 0 do
          {:halt, {:error, :zero_probability}}
        else
          {:cont, acc - :math.log(probability_observed)}
        end
      end)

    case result do
      {:error, _} = error -> error
      sum when is_float(sum) -> {:ok, sum / length(pairs)}
    end
  end
end
```

---

# 14. Tamper-evident immutable forecast repository

```elixir
# lib/tiannara/forecasting/adapters/memory_forecast_repository.ex
defmodule Tiannara.Forecasting.Adapters.MemoryForecastRepository do
  @moduledoc false
  @behaviour Tiannara.Forecasting.Ports.ForecastRepository
  use GenServer

  alias Tiannara.Forecasting.Kernel.{CanonicalHash, Clock}

  @genesis_hash "0000000000000000000000000000000000000000000000000000000000000000"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    tables = [
      {:tf_forecasts, :set},
      {:tf_resolutions, :set},
      {:tf_lineage, :bag},
      {:tf_postmortems, :set},
      {:tf_ledger_meta, :set}
    ]

    Enum.each(tables, fn {name, type} ->
      if :ets.whereis(name) == :undefined do
        :ets.new(name, [type, :protected, :named_table])
      end
    end)

    {:ok, %{}}
  end

  @impl true
  def append_forecast(forecast) do
    GenServer.call(__MODULE__, {:append_forecast, forecast})
  end

  @impl true
  def get_forecast(id) do
    case :ets.lookup(:tf_forecasts, id) do
      [{^id, envelope}] -> {:ok, envelope.forecast}
      [] -> {:error, :not_found}
    end
  end

  @impl true
  def list_forecasts do
    :ets.tab2list(:tf_forecasts)
    |> Enum.map(&elem(&1, 1))
    |> Enum.sort_by(& &1.sequence)
    |> Enum.map(& &1.forecast)
  end

  def list_sealed_records do
    :ets.tab2list(:tf_forecasts)
    |> Enum.map(&elem(&1, 1))
    |> Enum.sort_by(& &1.sequence)
  end

  def verify_chain do
    records = list_sealed_records()

    result =
      Enum.reduce_while(records, {:ok, @genesis_hash, 0}, fn envelope, {:ok, previous_hash, count} ->
        expected_hash =
          CanonicalHash.sha256_hex(%{
            previous_hash: previous_hash,
            sequence: envelope.sequence,
            forecast: envelope.forecast
          })

        cond do
          envelope.previous_hash != previous_hash ->
            {:halt, {:error, {:broken_chain, envelope.forecast.id, :previous_hash_mismatch}}}

          envelope.record_hash != expected_hash ->
            {:halt, {:error, {:broken_chain, envelope.forecast.id, :record_hash_mismatch}}}

          true ->
            {:cont, {:ok, envelope.record_hash, count + 1}}
        end
      end)

    case result do
      {:ok, _last_hash, count} -> {:ok, %{records: count}}
      error -> error
    end
  end

  @impl true
  def append_resolution(resolution) do
    GenServer.call(__MODULE__, {:append_resolution, resolution})
  end

  @impl true
  def get_resolution(forecast_id) do
    case :ets.lookup(:tf_resolutions, forecast_id) do
      [{^forecast_id, resolution}] -> {:ok, resolution}
      [] -> {:error, :not_found}
    end
  end

  @impl true
  def list_resolutions do
    :ets.tab2list(:tf_resolutions) |> Enum.map(&elem(&1, 1))
  end

  @impl true
  def append_lineage(lineage) do
    GenServer.call(__MODULE__, {:append_lineage, lineage})
  end

  @impl true
  def lineage_children(parent_id) do
    :ets.lookup(:tf_lineage, parent_id) |> Enum.map(&elem(&1, 1))
  end

  @impl true
  def append_postmortem(postmortem) do
    GenServer.call(__MODULE__, {:append_postmortem, postmortem})
  end

  @impl true
  def get_postmortem(forecast_id) do
    case :ets.lookup(:tf_postmortems, forecast_id) do
      [{^forecast_id, postmortem}] -> {:ok, postmortem}
      [] -> {:error, :not_found}
    end
  end

  @impl true
  def handle_call({:append_forecast, forecast}, _from, state) do
    reply =
      if :ets.member(:tf_forecasts, forecast.id) do
        {:error, :immutable_record_exists}
      else
        {previous_hash, sequence} = current_seal()

        record_hash =
          CanonicalHash.sha256_hex(%{
            previous_hash: previous_hash,
            sequence: sequence,
            forecast: forecast
          })

        envelope = %{
          forecast: forecast,
          record_hash: record_hash,
          previous_hash: previous_hash,
          sequence: sequence,
          sealed_at: Clock.now_unix()
        }

        :ets.insert(:tf_forecasts, {forecast.id, envelope})
        :ets.insert(:tf_ledger_meta, {:seal, %{last_hash: record_hash, sequence: sequence + 1}})

        {:ok, forecast}
      end

    {:reply, reply, state}
  end

  @impl true
  def handle_call({:append_resolution, resolution}, _from, state) do
    reply =
      if :ets.member(:tf_resolutions, resolution.forecast_id) do
        {:error, :resolution_already_exists}
      else
        :ets.insert(:tf_resolutions, {resolution.forecast_id, resolution})
        {:ok, resolution}
      end

    {:reply, reply, state}
  end

  @impl true
  def handle_call({:append_lineage, lineage}, _from, state) do
    :ets.insert(:tf_lineage, {lineage.parent_forecast, lineage})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:append_postmortem, postmortem}, _from, state) do
    reply =
      if :ets.member(:tf_postmortems, postmortem.forecast_id) do
        {:error, :postmortem_already_exists}
      else
        :ets.insert(:tf_postmortems, {postmortem.forecast_id, postmortem})
        {:ok, postmortem}
      end

    {:reply, reply, state}
  end

  defp current_seal do
    case :ets.lookup(:tf_ledger_meta, :seal) do
      [{:seal, %{last_hash: last_hash, sequence: sequence}}] -> {last_hash, sequence}
      [] -> {@genesis_hash, 0}
    end
  end
end
```

---

# 15. Evidence-based evolution gates

```elixir
# lib/tiannara/forecasting/evolution/evolution.ex
defmodule Tiannara.Forecasting.Evolution.Genome do
  @moduledoc false

  alias Tiannara.Forecasting.Kernel.ID

  defstruct genome_id: nil,
            problem_definition: nil,
            target_definition: nil,
            horizon: nil,
            data_sources: [],
            signal_extractors: [],
            transformations: [],
            base_rates: [],
            priors: [],
            candidate_models: [],
            causal_assumptions: [],
            regime_detector: nil,
            ensemble_policy: nil,
            calibration_method: nil,
            uncertainty_model: nil,
            abstention_policy: nil,
            decision_policy: nil,
            scoring_policy: nil,
            update_policy: nil,
            provenance: %{}

  def new(attrs) do
    attrs = Map.new(attrs)
    struct(__MODULE__, Map.put_new(attrs, :genome_id, ID.new("GEN")))
  end

  def mutate(%__MODULE__{} = genome, field, value) do
    if Map.has_key?(genome, field) do
      mutated = %{genome | genome_id: genome.genome_id <> "-M"}
      mutated = Map.put(mutated, field, value)

      audit = %{
        mutation: field,
        production_effect: :none,
        note: "Mutation creates a candidate only. It does not deploy."
      }

      {:ok, mutated, audit}
    else
      {:error, {:unknown_genome_field, field}}
    end
  end
end

defmodule Tiannara.Forecasting.Evolution.Candidate do
  @moduledoc false

  alias Tiannara.Forecasting.Adapters.MemoryRegistry
  alias Tiannara.Forecasting.Kernel.{Clock, ID}

  @required_evidence_fields [
    :status,
    :test_suite_version,
    :dataset_digest,
    :baseline_digest,
    :candidate_digest,
    :metric_results,
    :threshold,
    :actual_value,
    :evidence_artifact,
    :timestamp
  ]

  def new(genome, parent_id \\ nil) do
    candidate = %{
      id: ID.new("CAND"),
      genome_id: genome.genome_id,
      parent_id: parent_id,
      status: :generated,
      gates: %{},
      created_at: Clock.now_unix()
    }

    MemoryRegistry.put_candidate(candidate)
    {:ok, candidate}
  end

  def required_gates do
    [:benchmark, :replay, :out_of_sample, :adversarial, :shadow]
  end

  def record_gate_evidence(candidate_id, gate, evidence) do
    evidence = Map.new(evidence)

    with {:ok, candidate} <- MemoryRegistry.get_candidate(candidate_id),
         :ok <- validate_gate_evidence(evidence) do
      updated = %{
        candidate
        | gates: Map.put(candidate.gates, gate, evidence),
          status: :gate_updated
      }

      MemoryRegistry.put_candidate(updated)
      {:ok, updated}
    end
  end

  defp validate_gate_evidence(evidence) do
    missing = Enum.reject(@required_evidence_fields, &Map.has_key?(evidence, &1))

    cond do
      missing != [] ->
        {:error, {:missing_gate_evidence_fields, missing}}

      evidence.status not in [:pass, :fail, :pending] ->
        {:error, :invalid_gate_status}

      true ->
        :ok
    end
  end
end

defmodule Tiannara.Forecasting.Evolution.Promotion do
  @moduledoc false

  alias Tiannara.Forecasting.Adapters.MemoryRegistry
  alias Tiannara.Forecasting.Capability.Engine
  alias Tiannara.Forecasting.Capability.Certification
  alias Tiannara.Forecasting.Governance.AuthorizationLedger
  alias Tiannara.Forecasting.Evolution.Candidate

  def promote(candidate_id, capability_id, authorization_id) do
    with {:ok, candidate} <- MemoryRegistry.get_candidate(candidate_id),
         {:ok, capability} <- Engine.get(capability_id),
         {:ok, authorization} <- AuthorizationLedger.get(authorization_id),
         :ok <- check_candidate_gates(candidate),
         :ok <- check_capability_certified(capability),
         :ok <- check_authorization(capability, authorization) do
      previous =
        case MemoryRegistry.get_champion(:current) do
          {:ok, current} -> current
          _ -> nil
        end

      if previous do
        MemoryRegistry.put_champion(:previous, previous)
      end

      MemoryRegistry.put_champion(:current, candidate_id)
      MemoryRegistry.put_champion(:candidate, nil)

      {:ok,
       %{
         promoted: candidate_id,
         previous: previous,
         rollback_available: previous != nil
       }}
    end
  end

  def rollback do
    case MemoryRegistry.get_champion(:previous) do
      {:ok, previous} ->
        MemoryRegistry.put_champion(:current, previous)
        {:ok, %{restored: previous}}

      _ ->
        {:error, :no_previous_champion}
    end
  end

  defp check_candidate_gates(candidate) do
    missing =
      Enum.reject(Candidate.required_gates(), fn gate ->
        gate_evidence = Map.get(candidate.gates, gate)
        is_map(gate_evidence) and Map.get(gate_evidence, :status) == :pass
      end)

    if missing == [] do
      :ok
    else
      {:error, {:missing_candidate_gate_evidence, missing}}
    end
  end

  defp check_capability_certified(capability) do
    if Certification.production?(capability) do
      :ok
    else
      {:error, :capability_not_production_certified}
    end
  end

  defp check_authorization(capability, authorization) do
    now = Tiannara.Forecasting.Kernel.Clock.now_unix()

    cond do
      authorization.decision != :approve ->
        {:error, :authorization_not_approved}

      authorization.capability_id != capability.capability_id ->
        {:error, :authorization_capability_mismatch}

      authorization.capability_version != capability.version ->
        {:error, :authorization_version_mismatch}

      authorization.expires_at != nil and authorization.expires_at <= now ->
        {:error, :authorization_expired}

      true ->
        :ok
    end
  end
end
```

---

# 16. Statistical experiment ledger

```elixir
# lib/tiannara/forecasting/experiments/experiment_engine.ex
defmodule Tiannara.Forecasting.Experiments.Ledger do
  @moduledoc false
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def propose(experiment) do
    GenServer.call(__MODULE__, {:propose, experiment})
  end

  def record_result(experiment_id, result) do
    GenServer.call(__MODULE__, {:record_result, experiment_id, result})
  end

  def get(experiment_id) do
    case :ets.lookup(:tf_experiments, experiment_id) do
      [{^experiment_id, experiment}] -> {:ok, experiment}
      [] -> {:error, :not_found}
    end
  end

  def list do
    :ets.tab2list(:tf_experiments) |> Enum.map(&elem(&1, 1))
  end

  def results(experiment_id) do
    :ets.lookup(:tf_experiment_results, experiment_id) |> Enum.map(&elem(&1, 1))
  end

  @impl true
  def init(_) do
    if :ets.whereis(:tf_experiments) == :undefined do
      :ets.new(:tf_experiments, [:set, :protected, :named_table])
    end

    if :ets.whereis(:tf_experiment_results) == :undefined do
      :ets.new(:tf_experiment_results, [:bag, :protected, :named_table])
    end

    {:ok, %{}}
  end

  @impl true
  def handle_call({:propose, experiment}, _from, state) do
    if :ets.member(:tf_experiments, experiment.id) do
      {:reply, {:error, :experiment_already_exists}, state}
    else
      :ets.insert(:tf_experiments, {experiment.id, experiment})
      {:reply, {:ok, experiment}, state}
    end
  end

  @impl true
  def handle_call({:record_result, experiment_id, result}, _from, state) do
    if :ets.member(:tf_experiments, experiment_id) do
      result = Map.put(result, :experiment_id, experiment_id)
      :ets.insert(:tf_experiment_results, {experiment_id, result})
      {:reply, {:ok, result}, state}
    else
      {:reply, {:error, :experiment_not_found}, state}
    end
  end
end

defmodule Tiannara.Forecasting.Experiments.Experiment do
  @moduledoc false

  alias Tiannara.Forecasting.Kernel.{Clock, ID}

  defstruct id: nil,
            hypothesis: nil,
            null_hypothesis: nil,
            alternative_hypothesis: nil,
            target: nil,
            dataset_digest: nil,
            cutoff: nil,
            sample_size: nil,
            splitting_strategy: nil,
            baseline: nil,
            candidate: nil,
            metrics_plan: [],
            multiple_testing_policy: nil,
            stopping_rule: nil,
            pre_registered_at: nil,
            status: :pre_registered

  def new(attrs) do
    attrs = Map.new(attrs)

    struct(__MODULE__, attrs)
    |> Map.put(:id, Map.get(attrs, :id, ID.new("EXP")))
    |> Map.put(:pre_registered_at, Clock.now_unix())
  end
end

defmodule Tiannara.Forecasting.Experiments.Engine do
  @moduledoc false

  alias Tiannara.Forecasting.Experiments.{Experiment, Ledger}

  @required_fields [
    :hypothesis,
    :null_hypothesis,
    :alternative_hypothesis,
    :target,
    :dataset_digest,
    :cutoff,
    :sample_size,
    :splitting_strategy,
    :baseline,
    :candidate,
    :metrics_plan,
    :multiple_testing_policy,
    :stopping_rule
  ]

  def propose(attrs) do
    attrs = Map.new(attrs)
    missing = Enum.reject(@required_fields, &Map.has_key?(attrs, &1))

    if missing != [] do
      {:error, {:missing_experiment_fields, missing}}
    else
      experiment = Experiment.new(attrs)
      Ledger.propose(experiment)
    end
  end

  def record_result(experiment_id, result) do
    Ledger.record_result(experiment_id, Map.new(result))
  end

  def get(experiment_id), do: Ledger.get(experiment_id)
  def list, do: Ledger.list()
  def results(experiment_id), do: Ledger.results(experiment_id)
end
```

---

# 17. Improved epistemic observability

```elixir
# lib/tiannara/forecasting/integrity/integrity.ex
defmodule Tiannara.Forecasting.Integrity.Supervisor do
  @moduledoc false
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{last_report: nil}, name: __MODULE__)
  end

  def last_report do
    GenServer.call(__MODULE__, :last_report)
  end

  @impl true
  def init(state) do
    schedule()
    {:ok, state}
  end

  @impl true
  def handle_info(:tick, state) do
    report = Tiannara.Forecasting.Integrity.EpistemicObservatory.report()
    schedule()
    {:noreply, %{state | last_report: report}}
  end

  @impl true
  def handle_call(:last_report, _from, state) do
    {:reply, state.last_report, state}
  end

  defp schedule do
    interval = Application.get_env(:tiannara_forecast, :integrity_interval_ms, 60_000)
    Process.send_after(self(), :tick, interval)
  end
end

defmodule Tiannara.Forecasting.Integrity.EpistemicObservatory do
  @moduledoc false

  alias Tiannara.Forecasting.Capability.Engine
  alias Tiannara.Forecasting.Governance.AuthorizationLedger
  alias Tiannara.Forecasting.Probability.{Calibration, ProbabilityDistribution}

  def report do
    repo = Application.fetch_env!(:tiannara_forecast, :forecast_repo)

    forecasts = repo.list_forecasts()
    resolutions = repo.list_resolutions()
    forecast_map = Map.new(forecasts, fn forecast -> {forecast.id, forecast} end)

    calibration_pairs = build_calibration_pairs(forecast_map, resolutions)

    calibration =
      case Calibration.report(calibration_pairs, out_of_sample: false) do
        {:ok, metrics} -> metrics
        {:error, reason} -> %{status: :insufficient_data, reason: reason}
      end

    chain_status =
      if Code.ensure_loaded?(repo) and function_exported?(repo, :verify_chain, 0) do
        repo.verify_chain()
      else
        :ledger_chain_not_supported
      end

    %{
      forecast_count: length(forecasts),
      resolved_count: length(resolutions),
      calibration: calibration,
      capability_matrix: Engine.matrix(),
      authorization_count: length(AuthorizationLedger.list()),
      ledger_chain_status: chain_status,
      abstention_rate: :unknown,
      replay_failure_rate: :unknown,
      signal_decay: :unknown,
      data_freshness: :unknown,
      generated_at: Tiannara.Forecasting.Kernel.Clock.now_unix(),
      telemetry_status: :partial_epistemic_observatory
    }
  end

  defp build_calibration_pairs(forecast_map, resolutions) do
    Enum.flat_map(resolutions, fn resolution ->
      forecast = Map.get(forecast_map, resolution.forecast_id)

      with %_{} = forecast <- forecast,
           {:ok, probability} <-
             ProbabilityDistribution.probability(forecast.probabilities, :event) do
        outcome_binary =
          case resolution.outcome do
            :event -> 1
            :no_event -> 0
            _ -> nil
          end

        if is_nil(outcome_binary) do
          []
        else
          [{probability, outcome_binary}]
        end
      else
        _ -> []
      end
    end)
  end
end
```

---

# 18. Updated API

```elixir
# lib/tiannara/forecasting/api.ex
defmodule Tiannara.Forecasting.API do
  @moduledoc false

  alias Tiannara.Forecasting.Core.{
    ExecutionManifest,
    Forecast,
    ForecastLineage,
    ForecastRequest,
    ForecastResolution,
    ReplayEngine,
    TemporalIntegrity,
    Uncertainty
  }

  alias Tiannara.Forecasting.Kernel.RNGContext

  alias Tiannara.Forecasting.Baselines.BaseRateEngine
  alias Tiannara.Forecasting.Predictability.Analyzer
  alias Tiannara.Forecasting.Postmortem.Analyzer
  alias Tiannara.Forecasting.Capability.Engine
  alias Tiannara.Forecasting.Governance.AuthorizationLedger
  alias Tiannara.Forecasting.Experiments.Engine, as: ExperimentEngine
  alias Tiannara.Forecasting.EFDI.{ForecastQuality, Recommendation}

  def issue_forecast(attrs) do
    with {:ok, request} <- ForecastRequest.new(attrs),
         {:ok, temporal_report} <- TemporalIntegrity.verify_request(request) do
      predictability = Analyzer.analyze(request)

      case predictability.decision do
        decision when decision in [:PREDICT, :LOW_CONFIDENCE_PREDICT] ->
          create_forecast(request, temporal_report, predictability)

        _ ->
          {:ok, {:abstain, predictability}}
      end
    end
  end

  def resolve_forecast(forecast_id, outcome, attrs \\ %{}) do
    with {:ok, forecast} <- repo().get_forecast(forecast_id),
         {:ok, resolution} <- ForecastResolution.new(forecast, outcome, attrs),
         {:ok, saved} <- repo().append_resolution(resolution) do
      {:ok, saved}
    end
  end

  def run_postmortem(forecast_id, context \\ %{}) do
    with {:ok, forecast} <- repo().get_forecast(forecast_id),
         {:ok, resolution} <- repo().get_resolution(forecast_id) do
      postmortem = Analyzer.analyze(forecast, resolution, context)

      with {:ok, saved} <- repo().append_postmortem(postmortem) do
        {:ok, saved}
      end
    end
  end

  def replay_forecast(forecast_id) do
    with {:ok, forecast} <- repo().get_forecast(forecast_id) do
      ReplayEngine.replay(forecast)
    end
  end

  def recommend_decision(forecast_id, decision_context \\ %{}) do
    with {:ok, forecast} <- repo().get_forecast(forecast_id) do
      quality = ForecastQuality.from_forecast(forecast)
      {:ok, Recommendation.recommend(forecast, quality, decision_context)}
    end
  end

  def register_capability(capability_id, version \\ "0.1.0") do
    Engine.register_capability(capability_id, version)
  end

  def record_capability_gate(capability_id, gate, result, evidence \\ %{}) do
    Engine.record_gate(capability_id, gate, result, evidence)
  end

  def authorize_capability(capability_id, authorized_by, evidence_digest, opts \\ []) do
    with {:ok, capability} <- Engine.get(capability_id) do
      gate_snapshot_digest = AuthorizationLedger.digest(capability.gates)

      AuthorizationLedger.authorize(%{
        capability_id: capability_id,
        capability_version: capability.version,
        decision: :approve,
        authorized_by: authorized_by,
        constitutional_rule:
          Keyword.get(opts, :constitutional_rule, "Tiannara Constitutional Governance"),
        evidence_digest: evidence_digest,
        gate_snapshot_digest: gate_snapshot_digest,
        expires_at: Keyword.get(opts, :expires_at)
      })
    end
  end

  def certify_capability(capability_id, authorization_id) do
    Engine.certify(capability_id, authorization_id)
  end

  def certification_matrix do
    Engine.matrix()
  end

  def verify_ledger_chain do
    repo = repo()

    if Code.ensure_loaded?(repo) and function_exported?(repo, :verify_chain, 0) do
      repo.verify_chain()
    else
      {:error, :ledger_chain_not_supported}
    end
  end

  def propose_experiment(attrs) do
    ExperimentEngine.propose(attrs)
  end

  def record_experiment_result(experiment_id, result) do
    ExperimentEngine.record_result(experiment_id, result)
  end

  defp create_forecast(request, temporal_report, predictability) do
    rng = RNGContext.new(request.rng_seed)
    model_ref = %{model_id: "baseline-historical", version: 1}

    with {:ok, base_rate} <- BaseRateEngine.historical_frequency(request),
         {:ok, run} <- runner().run(model_ref, request, rng) do
      manifest =
        ExecutionManifest.build(%{
          forecast_id: nil,
          request: request,
          data_snapshot: %{
            observations:
              TemporalIntegrity.reconstruct_information_state(
                request.observations,
                request.cutoff
              )
          },
          feature_snapshot: request.feature_versions,
          source_snapshot: request.source_versions,
          model_manifest: %{
            model_ref: model_ref,
            runner: runner()
          },
          signal_manifest: %{status: :unspecified},
          calibration_manifest: %{status: :unspecified},
          regime_manifest: %{status: :unspecified},
          knowledge_version:
            Application.get_env(:tiannara_forecast, :knowledge_version, "seed"),
          configuration: %{
            model_policy: request.model_policy,
            horizon: request.horizon,
            horizon_unit: request.horizon_unit,
            target: request.target,
            domain: request.domain
          },
          software_commit:
            Application.get_env(:tiannara_forecast, :software_commit, "dev"),
          dependency_lock_digest:
            Application.get_env(:tiannara_forecast, :dependency_lock_digest, "dev"),
          runtime_version: to_string(:erlang.system_info(:otp_release)),
          rng_record: RNGContext.record(rng)
        })

      confidence_in_confidence = Engine.confidence_in_confidence(:forecast_core)

      params = %{
        request: request,
        probabilities: run.distribution,
        base_rate: base_rate,
        model_versions: %{run.model_version.model_id => run.model_version.version},
        execution_manifest: manifest,
        temporal_warnings: temporal_report.warnings,
        uncertainty: Uncertainty.explicit_mock(),
        confidence_in_confidence: confidence_in_confidence,
        software_version:
          Application.get_env(:tiannara_forecast, :software_version, "dev"),
        knowledge_version:
          Application.get_env(:tiannara_forecast, :knowledge_version, "seed"),
        certification_context: %{
          forecast_core: confidence_in_confidence.state,
          predictability: predictability.limitations
        }
      }

      with {:ok, draft} <- Forecast.draft(params),
           {:ok, frozen} <- Forecast.freeze(draft),
           {:ok, saved} <- repo().append_forecast(frozen) do
        ForecastLineage.record(request.parent_forecast_id, saved.id)
        {:ok, saved}
      end
    end
  end

  defp repo do
    Application.fetch_env!(:tiannara_forecast, :forecast_repo)
  end

  defp runner do
    Application.fetch_env!(:tiannara_forecast, :model_runner)
  end
end
```

---

# Confirmation

Yes.

The corrected runtime layer above incorporates the review’s critical requirements:

- Certification no longer self-authorizes.
- Authorization is a separate immutable governance artifact.
- Replay uses an execution manifest, not just RNG.
- Reproducibility levels are explicitly limited.
- Temporal integrity now includes availability, publication, and revision semantics.
- Predictability is separated from data sufficiency and marked heuristic.
- Regime outputs are scores, not probabilities.
- Postmortems produce competing hypotheses, not fake causal certainty.
- Calibration is expanded beyond ECE.
- Evolution gates require structured evidence artifacts.
- The forecast ledger is tamper-evident via hash chaining.
- Experiments are pre-registered records.
- Epistemic observability is upgraded from a mock report to a partial operational observer.

The system remains:

```text
IMPLEMENTED
```

and is still not:

```text
VALIDATED
```

or:

```text
PRODUCTION-CERTIFIED
```

I reviewed the complete pasted artifact. The direction is **substantially correct**, but I would **not accept the statement that the hardening layer has fully solved the earlier problems**.

The correct overall status remains:

```text
IMPLEMENTED
NOT VALIDATED
NOT PRODUCTION-CERTIFIED
```

That status is explicitly preserved by the artifact itself. 

### The important finding

The new layer fixes several architectural weaknesses, especially:

* separate authorization artifact
* execution manifest
* vintage-aware temporal metadata
* explicit reproducibility levels
* heuristic regime scores
* hypothesis-based postmortems
* expanded calibration
* evidence-bearing evolution gates
* hash-chained forecast records
* experiment pre-registration
* epistemic observability

Those are real improvements. 

However, **there are still several certification-blocking flaws in the implementation itself.**

## 1. Governance authorization is still not truly independent

This is the biggest one.

The code now separates authorization into `AuthorizationLedger`, which is architecturally better. But the public API still exposes:

```text
authorize_capability(capability_id, authorized_by, evidence_digest, opts)
```

and directly creates an approval with:

```text
decision: :approve
authorized_by: authorized_by
```

There is no demonstrated Constitutional Council verification in that path. 

So the system has changed from:

> capability record self-authorizes

to:

> API caller can create a separate approval artifact.

That is **better separation**, but it is not yet genuine governance independence.

### Required correction

Authorization should be an **input from the governance authority**, not something the forecasting runtime can manufacture.

Conceptually:

```text
Forecasting
    │
    ├── produces evidence
    │
    └── requests authorization
              │
              ▼
      Constitutional Council
              │
        approve / deny
              │
              ▼
       Authorization Ledger
              │
              ▼
          Certification
```

The forecasting subsystem should not possess an unrestricted `approve` capability.

---

## 2. Gate evidence is structured, but still self-asserted

The evolution gate now requires:

```text
status
test_suite_version
dataset_digest
baseline_digest
candidate_digest
metric_results
threshold
actual_value
evidence_artifact
timestamp
```

which is a good improvement. 

But `validate_gate_evidence/1` only checks **presence and basic status validity**.

It does not verify:

```text
evidence_artifact actually exists
        ↓
artifact hash matches
        ↓
dataset matches
        ↓
candidate matches
        ↓
baseline matches
        ↓
metrics were actually computed
        ↓
threshold predicate is satisfied
```

Therefore:

```text
structured evidence ≠ verified evidence
```

This distinction is extremely important for Tiannara.

The next layer should be an **Evidence Verifier**, not simply a richer evidence schema.

---

## 3. Certification can become stale after a gate changes

This is a serious state-consistency issue.

Suppose:

```text
forecast_core
12/12 gates PASS
authorization approved
certified
```

Then someone calls:

```text
record_capability_gate(..., :statistical_validation, :fail, ...)
```

The capability's gate state changes, but `production_state` remains:

```text
:certified
```

because `record_gate/5` does not revoke certification. 

That violates the intended invariant:

```text
CERTIFIED
    iff
all required gates pass
AND
valid authorization exists
AND
authorization matches current evidence snapshot
```

### Required invariant

Any material change to:

* gate evidence
* capability version
* implementation
* model
* dependency
* configuration
* evidence snapshot

must invalidate the certification.

For example:

```text
CERTIFIED
   ↓ gate/evidence mutation
CERTIFICATION_INVALIDATED
   ↓
REVALIDATION_REQUIRED
```

This should be tested adversarially.

---

## 4. Promotion has the same stale-authorization problem

`Promotion.promote/3` checks:

* candidate gates
* capability production certification
* authorization identity/version
* authorization expiry

but it doesn't establish that the authorization is bound to the **exact candidate being promoted**. 

The authorization is fundamentally capability-level:

```text
capability_id
capability_version
```

rather than:

```text
candidate_id
candidate_digest
candidate_gate_snapshot_digest
promotion_policy_digest
```

That leaves an important gap:

```text
authorized capability
        ≠
authorized candidate
```

For evolutionary systems, those must be explicitly bound.

---

## 5. The experiment subsystem is currently a ledger, not an experiment engine

This is perhaps the largest scientific gap.

The artifact calls it a:

> Statistical experiment ledger

and it does successfully record hypotheses, null/alternative hypotheses, datasets, cutoffs, sample size, baselines, metrics, multiple-testing policy and stopping rule. 

But the implementation doesn't actually perform the scientific workflow.

It can:

```text
propose()
record_result()
get()
list()
results()
```

It does not yet independently perform:

```text
hypothesis
    ↓
dataset reconstruction
    ↓
temporal split
    ↓
baseline execution
    ↓
candidate execution
    ↓
scoring
    ↓
confidence intervals
    ↓
effect size
    ↓
null comparison
    ↓
multiple-testing correction
    ↓
replication
    ↓
evidence artifact
    ↓
certification predicate
```

So I would rename its current status internally:

```text
EXPERIMENT_LEDGER_IMPLEMENTED
EXPERIMENT_ENGINE NOT_IMPLEMENTED
```

rather than allowing the existence of `Experiments.Engine` to imply scientific experimentation capability.

---

## 6. Predictability is still mathematically too weak

The artifact correctly labels the implementation heuristic. 

But this formula:

```text
predictability_score =
  max(abs(lag1_autocorrelation), 1 - entropy)
```

has a conceptual problem.

A high value can arise simply because the target distribution is highly imbalanced.

For example, if an event almost never occurs:

```text
p ≈ 0
entropy ≈ 0
1 - entropy ≈ 1
```

and therefore the system can report extremely high "predictability" despite having little useful predictive structure.

So this should **not become a certification metric**.

The next version should separate:

```text
data sufficiency
signal strength
baseline skill
predictability
forecastability
model skill
irreducible uncertainty
distribution shift
```

and require out-of-sample/null-model evidence.

---

## 7. Temporal integrity improved, but the availability inference is questionable

This section is much better than the original because it distinguishes event, observation, publication, ingestion, availability and revision time. 

But:

```elixir
[ingestion_time, publication_time]
|> Enum.reject(&is_nil/1)
|> Enum.max()
```

is not generally a valid definition of availability.

If information was published at:

```text
10:00
```

but Tiannara ingested it at:

```text
10:05
```

then the information was externally available at 10:00, not 10:05.

For leakage prevention, you need to distinguish:

```text
externally_available_at
system_received_at
system_ingested_at
```

rather than infer one from the others.

Most importantly, **unknown availability should generally remain unknown**, not silently become inferred availability.

---

## 8. The hash chain is tamper-evident, but not yet durable immutability

The hash chaining is a good step:

```text
record[n]
    contains previous_hash
        ↓
record_hash
        ↓
record[n+1]
```

and the repository can verify the chain. 

But because the actual ledger is ETS:

```text
ETS
 ↓
process restart
 ↓
state disappears
```

it isn't a production evidence archive.

Also, only forecasts participate in the demonstrated chain. Resolutions, postmortems, lineage and experiments are separate ETS structures.

Eventually Tiannara needs something closer to:

```text
Evidence Event
     ↓
canonical serialization
     ↓
content hash
     ↓
previous-event hash
     ↓
append-only durable store
     ↓
external/archive checkpoint
```

The current implementation is therefore correctly **tamper-evident prototype infrastructure**, not a production immutable evidence system.

---

# 9. Replay is improved but still not true historical replay

The manifest is an excellent addition. It records data, features, sources, model, signals, calibration, regime, knowledge, configuration, software, dependencies, runtime and RNG. 

But replay still calls the **current configured runner**:

```text
runner.run(...)
```

against the reconstructed request.

Therefore:

```text
same manifest
+
same current runner
+
same RNG
=
same result
```

doesn't necessarily prove:

```text
historical environment
+
historical information state
+
historical dependencies
+
historical implementation
=
historical execution
```

The artifact itself appropriately limits the claim to R2/R3 and explicitly avoids claiming R4 without independent attestation. 

That is correct.

The next milestone should be **independent replay**, not merely more metadata.

---

# 10. `confidence_in_confidence` should not be a fixed state lookup

This:

```text
production_certified → 0.9
validated            → 0.6
eligible              → 0.3
implemented           → 0.2
```

is still essentially a manually assigned ordinal scale. 

It is useful as a UI/status abstraction, but I would **not call it a probability**.

Better:

```text
epistemic_state:
  implementation: ...
  validation: ...
  reproducibility: ...
  calibration: ...
  evidence_integrity: ...
  distribution_shift: ...
  governance: ...
```

Then derive a bounded **trust profile**, not pretend that `0.6` has a mathematically meaningful interpretation.

---

# My overall verdict

I would classify the submitted hardening layer like this:

| Area                            | Status                          |
| ------------------------------- | ------------------------------- |
| Architecture                    | **Strong**                      |
| Separation of governance        | **Improved**                    |
| Forecast provenance             | **Strong foundation**           |
| Temporal integrity              | **Improved / incomplete**       |
| Replay                          | **Implemented / limited**       |
| Calibration                     | **Implemented / not validated** |
| Predictability                  | **Heuristic**                   |
| Regime detection                | **Heuristic**                   |
| Postmortem                      | **Hypothesis-level**            |
| Evolution lineage               | **Good foundation**             |
| Evidence verification           | **Missing**                     |
| Scientific experiment execution | **Missing**                     |
| Durable evidence storage        | **Missing**                     |
| Certification revocation        | **Missing**                     |
| Candidate-bound authorization   | **Missing**                     |
| Independent replay              | **Missing**                     |
| Production certification        | **BLOCKED**                     |

## Therefore I would NOT move directly to certification testing.

The next engineering phase should be:

```text
HARDENED IMPLEMENTATION
        ↓
EVIDENCE VERIFICATION
        ↓
SCIENTIFIC EXPERIMENT ENGINE
        ↓
CERTIFICATION INVARIANTS
        ↓
ADVERSARIAL TESTING
        ↓
REAL SHADOW FORECASTING
        ↓
REPLICATION
        ↓
VALIDATION
        ↓
GOVERNANCE AUTHORIZATION
        ↓
PRODUCTION CERTIFICATION
```

And, importantly, **do not add more forecasting algorithms yet**.

The highest-value next subsystem is the machinery that can answer:

> **"Why should Tiannara believe that this forecasting capability deserves trust?"**

That is much more valuable than adding another model.

The artifact itself correctly establishes the foundational principle that the system remains implemented rather than validated or production-certified. 

**My recommendation: accept this artifact as a substantial hardening milestone, but open a new validation phase rather than treating it as the final production-hardening implementation.**

Yes. I accept the review and the corrected status:

```text
IMPLEMENTED
NOT VALIDATED
NOT PRODUCTION-CERTIFIED
```

The previous hardening layer was a real milestone, but it is not sufficient for certification. The next phase must focus on **verification, evidence binding, certification invariants, independent governance, and scientific execution**, not on adding more forecasting algorithms.

Below is the next validation-phase runtime layer. It addresses the certification-blocking issues identified in the review.

---

# 1. Updated configuration

```elixir
# config/config.exs
import Config

config :tiannara_forecast,
  clock: Tiannara.Forecasting.Kernel.SystemClock,
  forecast_repo: Tiannara.Forecasting.Adapters.MemoryForecastRepository,
  evidence_store: Tiannara.Forecasting.Adapters.MemoryEvidenceStore,
  model_runner: Tiannara.Forecasting.Adapters.MockModelRunner,

  # Governance
  governance_council: Tiannara.Forecasting.Governance.DenyAllCouncil,
  allow_mock_council_approvals: false,

  # Evidence verification
  evidence_verifier: Tiannara.Forecasting.Evidence.DefaultVerifier,

  # Replay
  independent_replayer: nil,

  # Experiments
  experiment_executor: Tiannara.Forecasting.Experiments.MockComparisonExecutor,

  software_version: "0.3.0",
  software_commit: "unset",
  dependency_lock_digest: "unset",
  knowledge_version: "seed-0",
  integrity_interval_ms: 60_000
```

---

# 2. Updated application bootstrap

```elixir
# lib/tiannara/forecasting/application.ex
defmodule Tiannara.Forecasting.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Tiannara.Forecasting.Adapters.MemoryRegistry,
      Tiannara.Forecasting.Adapters.MemoryForecastRepository,
      Tiannara.Forecasting.Adapters.MemoryEvidenceStore,
      Tiannara.Forecasting.Evidence.ArtifactStore,
      Tiannara.Forecasting.Evidence.EventLog,
      Tiannara.Forecasting.Governance.AuthorizationLedger,
      Tiannara.Forecasting.Experiments.Ledger,
      Tiannara.Forecasting.Integrity.Supervisor
    ]

    {:ok, sup} =
      Supervisor.start_link(children,
        strategy: :one_for_one,
        name: Tiannara.Forecasting.Supervisor
      )

    :ok = Tiannara.Forecasting.Capability.Engine.seed_defaults()

    {:ok, sup}
  end
end
```

---

# 3. Governance council port

The forecasting runtime can request authorization, but it cannot manufacture approval by default.

```elixir
# lib/tiannara/forecasting/governance/council_port.ex
defmodule Tiannara.Forecasting.Governance.CouncilPort do
  @moduledoc false

  @callback request_decision(authorization_request :: map()) ::
              {:ok, decision :: map()} | {:error, term()}
end
```

```elixir
# lib/tiannara/forecasting/governance/deny_all_council.ex
defmodule Tiannara.Forecasting.Governance.DenyAllCouncil do
  @moduledoc false
  @behaviour Tiannara.Forecasting.Governance.CouncilPort

  @impl true
  def request_decision(request) do
    {:ok,
     %{
       decision: :deny,
       authorized_by: nil,
       council_id: "deny-all-council",
       reason: :no_governance_authority_configured,
       request_id: request.id
     }}
  end
end
```

```elixir
# lib/tiannara/forecasting/governance/mock_council.ex
defmodule Tiannara.Forecasting.Governance.MockCouncil do
  @moduledoc false
  @behaviour Tiannara.Forecasting.Governance.CouncilPort

  @impl true
  def request_decision(request) do
    if Application.get_env(:tiannara_forecast, :allow_mock_council_approvals, false) do
      {:ok,
       %{
         decision: :approve,
         authorized_by: :mock_constitutional_council,
         council_id: "mock-constitutional-council",
         request_id: request.id,
         note: "Mock approval for controlled testing only. Not production governance."
       }}
    else
      {:ok,
       %{
         decision: :deny,
         authorized_by: nil,
         council_id: "mock-constitutional-council",
         reason: :mock_council_approvals_disabled,
         request_id: request.id
       }}
    end
  end
end
```

---

# 4. Authorization ledger with request/decision separation

```elixir
# lib/tiannara/forecasting/governance/authorization_ledger.ex
defmodule Tiannara.Forecasting.Governance.AuthorizationLedger do
  @moduledoc false
  use GenServer

  alias Tiannara.Forecasting.Kernel.{Clock, ID}

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def record_request(request) do
    GenServer.call(__MODULE__, {:record_request, request})
  end

  def get_request(request_id) do
    case :ets.lookup(:tf_authorization_requests, request_id) do
      [{^request_id, request}] -> {:ok, request}
      [] -> {:error, :not_found}
    end
  end

  def list_requests do
    :ets.tab2list(:tf_authorization_requests) |> Enum.map(&elem(&1, 1))
  end

  def record_decision(decision_attrs) do
    GenServer.call(__MODULE__, {:record_decision, decision_attrs})
  end

  def get_authorization(authorization_id) do
    case :ets.lookup(:tf_authorizations, authorization_id) do
      [{^authorization_id, authorization}] -> {:ok, authorization}
      [] -> {:error, :not_found}
    end
  end

  def list_authorizations do
    :ets.tab2list(:tf_authorizations) |> Enum.map(&elem(&1, 1))
  end

  @impl true
  def init(_) do
    if :ets.whereis(:tf_authorization_requests) == :undefined do
      :ets.new(:tf_authorization_requests, [:set, :protected, :named_table])
    end

    if :ets.whereis(:tf_authorizations) == :undefined do
      :ets.new(:tf_authorizations, [:set, :protected, :named_table])
    end

    {:ok, %{}}
  end

  @impl true
  def handle_call({:record_request, request}, _from, state) do
    reply =
      if :ets.member(:tf_authorization_requests, request.id) do
        {:error, :authorization_request_already_exists}
      else
        :ets.insert(:tf_authorization_requests, {request.id, request})
        {:ok, request}
      end

    {:reply, reply, state}
  end

  @impl true
  def handle_call({:record_decision, decision_attrs}, _from, state) do
    decision_attrs = Map.new(decision_attrs)

    reply =
      with {:ok, request_id} <- fetch_required(decision_attrs, :request_id),
           {:ok, request} <- get_request(request_id),
           {:ok, decision} <- fetch_required(decision_attrs, :decision),
           :ok <- validate_decision(decision) do
        authorization = %{
          id: ID.new("AUTH"),
          request_id: request.id,
          subject_type: request.subject_type,
          subject_id: request.subject_id,
          subject_version: request.subject_version,
          subject_digest: request.subject_digest,
          gate_snapshot_digest: request.gate_snapshot_digest,
          evidence_digest: request.evidence_digest,
          decision: decision,
          authorized_by: Map.get(decision_attrs, :authorized_by),
          council_id: Map.get(decision_attrs, :council_id),
          constitutional_rule: request.constitutional_rule,
          reason: Map.get(decision_attrs, :reason),
          expires_at: Map.get(decision_attrs, :expires_at),
          timestamp: Clock.now_unix()
        }

        :ets.insert(:tf_authorizations, {authorization.id, authorization})
        {:ok, authorization}
      end

    {:reply, reply, state}
  end

  defp fetch_required(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:missing_field, key}}
    end
  end

  defp validate_decision(decision) when decision in [:approve, :deny], do: :ok
  defp validate_decision(_), do: {:error, :invalid_authorization_decision}
end
```

---

# 5. Governance engine

```elixir
# lib/tiannara/forecasting/governance/engine.ex
defmodule Tiannara.Forecasting.Governance.Engine do
  @moduledoc false

  alias Tiannara.Forecasting.Kernel.{CanonicalHash, Clock, ID}
  alias Tiannara.Forecasting.Governance.AuthorizationLedger
  alias Tiannara.Forecasting.Capability.Engine, as: CapabilityEngine
  alias Tiannara.Forecasting.Evolution.Candidate

  def request_capability_authorization(capability_id, requester, evidence_digest, opts \\ []) do
    with {:ok, capability} <- CapabilityEngine.get(capability_id) do
      request = %{
        id: ID.new("AUTHREQ"),
        subject_type: :capability,
        subject_id: capability.capability_id,
        subject_version: capability.version,
        subject_digest: CanonicalHash.sha256_hex(capability),
        gate_snapshot_digest: CanonicalHash.sha256_hex(capability.gates),
        evidence_digest: evidence_digest,
        requested_by: requester,
        constitutional_rule:
          Keyword.get(opts, :constitutional_rule, "Tiannara Constitutional Governance"),
        created_at: Clock.now_unix()
      }

      submit_request(request)
    end
  end

  def request_candidate_authorization(candidate_id, requester, evidence_digest, opts \\ []) do
    with {:ok, candidate} <- Tiannara.Forecasting.Adapters.MemoryRegistry.get_candidate(candidate_id) do
      request = %{
        id: ID.new("AUTHREQ"),
        subject_type: :candidate,
        subject_id: candidate.id,
        subject_version: Map.get(candidate, :version, 1),
        subject_digest: Candidate.digest(candidate),
        gate_snapshot_digest: Candidate.gate_digest(candidate),
        evidence_digest: evidence_digest,
        requested_by: requester,
        constitutional_rule:
          Keyword.get(opts, :constitutional_rule, "Tiannara Constitutional Governance"),
        created_at: Clock.now_unix()
      }

      submit_request(request)
    end
  end

  defp submit_request(request) do
    with {:ok, _request} <- AuthorizationLedger.record_request(request) do
      council = Application.fetch_env!(:tiannara_forecast, :governance_council)

      case council.request_decision(request) do
        {:ok, decision_attrs} ->
          AuthorizationLedger.record_decision(
            Map.put(decision_attrs, :request_id, request.id)
          )

        error ->
          error
      end
    end
  end
end
```

---

# 6. Evidence artifact store

```elixir
# lib/tiannara/forecasting/evidence/artifact_store.ex
defmodule Tiannara.Forecasting.Evidence.ArtifactStore do
  @moduledoc false
  use GenServer

  alias Tiannara.Forecasting.Kernel.{CanonicalHash, Clock, ID}

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def register(content) do
    GenServer.call(__MODULE__, {:register, content})
  end

  def get(artifact_id) do
    case :ets.lookup(:tf_evidence_artifacts, artifact_id) do
      [{^artifact_id, artifact}] -> {:ok, artifact}
      [] -> {:error, :not_found}
    end
  end

  def list do
    :ets.tab2list(:tf_evidence_artifacts) |> Enum.map(&elem(&1, 1))
  end

  @impl true
  def init(_) do
    if :ets.whereis(:tf_evidence_artifacts) == :undefined do
      :ets.new(:tf_evidence_artifacts, [:set, :protected, :named_table])
    end

    {:ok, %{}}
  end

  @impl true
  def handle_call({:register, content}, _from, state) do
    digest = CanonicalHash.sha256_hex(content)

    artifact = %{
      id: ID.new("ART"),
      digest: digest,
      content: content,
      registered_at: Clock.now_unix()
    }

    :ets.insert(:tf_evidence_artifacts, {artifact.id, artifact})
    {:reply, {:ok, artifact}, state}
  end
end
```

---

# 7. Evidence verifier

```elixir
# lib/tiannara/forecasting/evidence/verifier.ex
defmodule Tiannara.Forecasting.Evidence.Verifier do
  @moduledoc false

  @callback verify(evidence :: map()) :: :ok | {:error, term()}
end
```

```elixir
# lib/tiannara/forecasting/evidence/default_verifier.ex
defmodule Tiannara.Forecasting.Evidence.DefaultVerifier do
  @moduledoc false
  @behaviour Tiannara.Forecasting.Evidence.Verifier

  alias Tiannara.Forecasting.Evidence.ArtifactStore

  @impl true
  def verify(evidence) do
    evidence = Map.new(evidence)

    with {:ok, artifact_ref} <- fetch_required(evidence, :evidence_artifact),
         {:ok, artifact_id} <- fetch_required(artifact_ref, :artifact_id),
         {:ok, claimed_digest} <- fetch_required(artifact_ref, :digest),
         {:ok, artifact} <- ArtifactStore.get(artifact_id),
         :ok <- verify_digest(artifact.digest, claimed_digest),
         :ok <- verify_bound_digests(artifact.content, evidence),
         :ok <- verify_threshold(artifact.content, evidence) do
      :ok
    end
  end

  defp fetch_required(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:missing_field, key}}
    end
  end

  defp verify_digest(actual, claimed) do
    if actual == claimed do
      :ok
    else
      {:error, :artifact_digest_mismatch}
    end
  end

  defp verify_bound_digests(content, evidence) do
    content = if is_map(content), do: content, else: %{}

    checks = [
      {:dataset_digest, Map.get(evidence, :dataset_digest)},
      {:baseline_digest, Map.get(evidence, :baseline_digest)},
      {:candidate_digest, Map.get(evidence, :candidate_digest)}
    ]

    Enum.reduce_while(checks, :ok, fn
      {_key, nil}, acc ->
        {:cont, acc}

      {key, expected}, acc ->
        actual = Map.get(content, key)

        if actual == expected do
          {:cont, acc}
        else
          {:halt, {:error, {:bound_digest_mismatch, key}}}
        end
    end)
  end

  defp verify_threshold(content, evidence) do
    threshold = Map.get(evidence, :threshold)
    metric_results = Map.get(content, :metric_results, %{})

    case threshold do
      nil ->
        {:error, :missing_threshold_predicate}

      %{} = threshold ->
        metric = Map.get(threshold, :metric)
        operator = Map.get(threshold, :operator)
        limit = Map.get(threshold, :value)
        actual = Map.get(metric_results, metric, Map.get(evidence, :actual_value))

        cond do
          is_nil(metric) or is_nil(operator) or is_nil(limit) ->
            {:error, :invalid_threshold_predicate}

          is_nil(actual) ->
            {:error, :missing_actual_metric}

          not compare(actual, operator, limit) ->
            {:error, :threshold_not_satisfied}

          true ->
            :ok
        end

      _ ->
        {:error, :invalid_threshold_predicate}
    end
  end

  defp compare(actual, :<=, limit), do: actual <= limit
  defp compare(actual, :<, limit), do: actual < limit
  defp compare(actual, :>=, limit), do: actual >= limit
  defp compare(actual, :>, limit), do: actual > limit
  defp compare(actual, :==, limit), do: actual == limit
  defp compare(_actual, _operator, _limit), do: false
end
```

---

# 8. Evidence event log

This is still in-memory, but it establishes a broader evidence-event chain beyond forecasts only.

```elixir
# lib/tiannara/forecasting/evidence/event_log.ex
defmodule Tiannara.Forecasting.Evidence.EventLog do
  @moduledoc false
  use GenServer

  alias Tiannara.Forecasting.Kernel.{CanonicalHash, Clock}

  @genesis_hash "0000000000000000000000000000000000000000000000000000000000000000"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def append_event(type, payload) do
    GenServer.call(__MODULE__, {:append_event, type, payload})
  end

  def list_events do
    :ets.tab2list(:tf_evidence_events)
    |> Enum.map(&elem(&1, 1))
    |> Enum.sort_by(& &1.sequence)
  end

  def verify_chain do
    events = list_events()

    result =
      Enum.reduce_while(events, {:ok, @genesis_hash, 0}, fn event, {:ok, previous_hash, count} ->
        expected_hash =
          CanonicalHash.sha256_hex(%{
            previous_hash: previous_hash,
            sequence: event.sequence,
            type: event.type,
            payload: event.payload
          })

        cond do
          event.previous_hash != previous_hash ->
            {:halt, {:error, {:broken_evidence_chain, event.id, :previous_hash_mismatch}}}

          event.event_hash != expected_hash ->
            {:halt, {:error, {:broken_evidence_chain, event.id, :event_hash_mismatch}}}

          true ->
            {:cont, {:ok, event.event_hash, count + 1}}
        end
      end)

    case result do
      {:ok, _last_hash, count} -> {:ok, %{events: count}}
      error -> error
    end
  end

  @impl true
  def init(_) do
    if :ets.whereis(:tf_evidence_events) == :undefined do
      :ets.new(:tf_evidence_events, [:set, :protected, :named_table])
    end

    if :ets.whereis(:tf_evidence_event_meta) == :undefined do
      :ets.new(:tf_evidence_event_meta, [:set, :protected, :named_table])
    end

    {:ok, %{}}
  end

  @impl true
  def handle_call({:append_event, type, payload}, _from, state) do
    {previous_hash, sequence} = current_seal()

    event_hash =
      CanonicalHash.sha256_hex(%{
        previous_hash: previous_hash,
        sequence: sequence,
        type: type,
        payload: payload
      })

    event = %{
      id: Tiannara.Forecasting.Kernel.ID.new("EVIDEVT"),
      type: type,
      payload: payload,
      previous_hash: previous_hash,
      sequence: sequence,
      event_hash: event_hash,
      recorded_at: Clock.now_unix()
    }

    :ets.insert(:tf_evidence_events, {event.id, event})
    :ets.insert(:tf_evidence_event_meta, {:seal, %{last_hash: event_hash, sequence: sequence + 1}})

    {:reply, {:ok, event}, state}
  end

  defp current_seal do
    case :ets.lookup(:tf_evidence_event_meta, :seal) do
      [{:seal, %{last_hash: last_hash, sequence: sequence}}] -> {last_hash, sequence}
      [] -> {@genesis_hash, 0}
    end
  end
end
```

---

# 9. Certification with revocation and trust profiles

```elixir
# lib/tiannara/forecasting/capability/certification.ex
defmodule Tiannara.Forecasting.Capability.Certification do
  @moduledoc false

  @gates [
    :contract,
    :mathematical_correctness,
    :temporal_integrity,
    :deterministic_reproducibility,
    :statistical_validation,
    :out_of_sample,
    :adversarial,
    :performance_scale,
    :fault_tolerance,
    :observability_audit,
    :security_governance,
    :live_shadow
  ]

  defstruct capability_id: nil,
            version: "0.1.0",
            implementation_status: :implemented,
            gates: %{},
            blockers: [],
            authorization_id: nil,
            production_state: :blocked,
            invalidated_reason: nil,
            updated_at: nil

  def gates, do: @gates

  def new(capability_id, version, now) do
    %__MODULE__{
      capability_id: capability_id,
      version: version,
      gates: Map.new(@gates, &{&1, %{status: :pending, evidence: nil, at: nil}}),
      updated_at: now
    }
  end

  def record_gate(%__MODULE__{} = capability, gate, result, evidence, now)
      when gate in @gates and result in [:pass, :fail, :pending] do
    gates =
      Map.put(capability.gates, gate, %{
        status: result,
        evidence: evidence,
        at: now
      })

    blockers =
      if result == :fail do
        Enum.uniq([gate | capability.blockers])
      else
        List.delete(capability.blockers, gate)
      end

    base = %{capability | gates: gates, blockers: blockers, updated_at: now}

    if capability.production_state == :certified do
      %{
        base
        | production_state: :invalidated,
          authorization_id: nil,
          invalidated_reason: {:gate_state_changed, gate}
      }
    else
      base
    end
  end

  def missing_gates(%__MODULE__{} = capability) do
    Enum.filter(@gates, fn gate ->
      get_in(capability.gates, [gate, :status]) != :pass
    end)
  end

  def eligible?(%__MODULE__{} = capability) do
    missing_gates(capability) == []
  end

  def production?(%__MODULE__{} = capability) do
    capability.production_state == :certified
  end

  def state(%__MODULE__{} = capability) do
    cond do
      capability.production_state == :invalidated -> :certification_invalidated
      production?(capability) -> :production_certified
      eligible?(capability) -> :eligible_for_authorization
      validated?(capability) -> :validated
      capability.implementation_status == :implemented -> :implemented
      true -> :theatrical
    end
  end

  defp validated?(%__MODULE__{} = capability) do
    Enum.all?(
      [
        :mathematical_correctness,
        :statistical_validation,
        :out_of_sample,
        :deterministic_reproducibility
      ],
      fn gate ->
        get_in(capability.gates, [gate, :status]) == :pass
      end
    )
  end
end
```

```elixir
# lib/tiannara/forecasting/capability/engine.ex
defmodule Tiannara.Forecasting.Capability.Engine do
  @moduledoc false

  alias Tiannara.Forecasting.Capability.Certification
  alias Tiannara.Forecasting.Governance.AuthorizationLedger
  alias Tiannara.Forecasting.Adapters.MemoryRegistry
  alias Tiannara.Forecasting.Kernel.{CanonicalHash, Clock}

  @default_capabilities [
    :forecast_core,
    :calibration,
    :regime_detection,
    :predictability,
    :ensemble,
    :counterfactual,
    :evolution,
    :efdi
  ]

  def seed_defaults do
    Enum.each(@default_capabilities, fn capability_id ->
      register_capability(capability_id)
    end)

    :ok
  end

  def register_capability(capability_id, version \\ "0.1.0") do
    capability = Certification.new(capability_id, version, Clock.now_unix())
    MemoryRegistry.put_capability(capability)
    {:ok, capability}
  end

  def get(capability_id) do
    MemoryRegistry.get_capability(capability_id)
  end

  def record_gate(capability_id, gate, result, evidence \\ %{}) do
    with {:ok, capability} <- get(capability_id) do
      updated =
        Certification.record_gate(
          capability,
          gate,
          result,
          evidence,
          Clock.now_unix()
        )

      MemoryRegistry.put_capability(updated)
      {:ok, updated}
    end
  end

  def certify(capability_id, authorization_id) do
    with {:ok, capability} <- get(capability_id),
         :ok <- ensure_eligible(capability),
         {:ok, authorization} <- AuthorizationLedger.get_authorization(authorization_id),
         :ok <- validate_authorization(capability, authorization),
         :ok <- validate_binding(capability, authorization) do
      updated = %{
        capability
        | authorization_id: authorization_id,
          production_state: :certified,
          invalidated_reason: nil,
          updated_at: Clock.now_unix()
      }

      MemoryRegistry.put_capability(updated)
      {:ok, updated}
    end
  end

  def matrix do
    MemoryRegistry.list_capabilities()
    |> Enum.map(fn capability ->
      %{
        capability_id: capability.capability_id,
        version: capability.version,
        state: Certification.state(capability),
        production_state: capability.production_state,
        invalidated_reason: capability.invalidated_reason,
        authorization_id: capability.authorization_id,
        blockers: capability.blockers,
        missing_gates: Certification.missing_gates(capability),
        gates: capability.gates
      }
    end)
  end

  def trust_profile(capability_id) do
    state =
      case get(capability_id) do
        {:ok, capability} -> Certification.state(capability)
        _ -> :theatrical
      end

    trust_level =
      case state do
        :production_certified -> :high
        :validated -> :medium
        :eligible_for_authorization -> :low
        :implemented -> :low
        :certification_invalidated -> :none
        _ -> :none
      end

    %{
      kind: :trust_profile,
      state: state,
      trust_level: trust_level,
      numeric_probability: nil,
      rationale:
        "Trust profile is an epistemic status, not a probability. It must not be interpreted as P(correct).",
      generated_at: Clock.now_unix()
    }
  end

  def capability_digest(capability) do
    CanonicalHash.sha256_hex(capability)
  end

  defp ensure_eligible(capability) do
    missing = Certification.missing_gates(capability)

    if missing == [] do
      :ok
    else
      {:error, {:capability_not_eligible, missing}}
    end
  end

  defp validate_authorization(capability, authorization) do
    now = Clock.now_unix()

    cond do
      authorization.decision != :approve ->
        {:error, :authorization_not_approved}

      authorization.subject_type != :capability ->
        {:error, :authorization_subject_type_mismatch}

      authorization.subject_id != capability.capability_id ->
        {:error, :authorization_capability_mismatch}

      authorization.subject_version != capability.version ->
        {:error, :authorization_version_mismatch}

      authorization.expires_at != nil and authorization.expires_at <= now ->
        {:error, :authorization_expired}

      true ->
        :ok
    end
  end

  defp validate_binding(capability, authorization) do
    cond do
      authorization.subject_digest != capability_digest(capability) ->
        {:error, :capability_digest_mismatch}

      authorization.gate_snapshot_digest != CanonicalHash.sha256_hex(capability.gates) ->
        {:error, :gate_snapshot_mismatch}

      true ->
        :ok
    end
  end
end
```

---

# 10. Candidate-bound evidence and promotion

```elixir
# lib/tiannara/forecasting/evolution/evolution.ex
defmodule Tiannara.Forecasting.Evolution.Genome do
  @moduledoc false

  alias Tiannara.Forecasting.Kernel.ID

  defstruct genome_id: nil,
            problem_definition: nil,
            target_definition: nil,
            horizon: nil,
            data_sources: [],
            signal_extractors: [],
            transformations: [],
            base_rates: [],
            priors: [],
            candidate_models: [],
            causal_assumptions: [],
            regime_detector: nil,
            ensemble_policy: nil,
            calibration_method: nil,
            uncertainty_model: nil,
            abstention_policy: nil,
            decision_policy: nil,
            scoring_policy: nil,
            update_policy: nil,
            provenance: %{}

  def new(attrs) do
    attrs = Map.new(attrs)
    struct(__MODULE__, Map.put_new(attrs, :genome_id, ID.new("GEN")))
  end

  def mutate(%__MODULE__{} = genome, field, value) do
    if Map.has_key?(genome, field) do
      mutated = %{genome | genome_id: genome.genome_id <> "-M"}
      mutated = Map.put(mutated, field, value)

      audit = %{
        mutation: field,
        production_effect: :none,
        note: "Mutation creates a candidate only. It does not deploy."
      }

      {:ok, mutated, audit}
    else
      {:error, {:unknown_genome_field, field}}
    end
  end
end

defmodule Tiannara.Forecasting.Evolution.Candidate do
  @moduledoc false

  alias Tiannara.Forecasting.Adapters.MemoryRegistry
  alias Tiannara.Forecasting.Kernel.{CanonicalHash, Clock, ID}

  @required_evidence_fields [
    :status,
    :test_suite_version,
    :dataset_digest,
    :baseline_digest,
    :candidate_digest,
    :metric_results,
    :threshold,
    :actual_value,
    :evidence_artifact,
    :timestamp
  ]

  def new(genome, parent_id \\ nil) do
    candidate = %{
      id: ID.new("CAND"),
      version: 1,
      genome_id: genome.genome_id,
      parent_id: parent_id,
      status: :generated,
      gates: %{},
      created_at: Clock.now_unix()
    }

    MemoryRegistry.put_candidate(candidate)
    {:ok, candidate}
  end

  def required_gates do
    [:benchmark, :replay, :out_of_sample, :adversarial, :shadow]
  end

  def digest(candidate) do
    CanonicalHash.sha256_hex(candidate)
  end

  def gate_digest(candidate) do
    CanonicalHash.sha256_hex(candidate.gates)
  end

  def record_gate_evidence(candidate_id, gate, evidence) do
    evidence = Map.new(evidence)
    verifier = Application.get_env(:tiannara_forecast, :evidence_verifier)

    with {:ok, candidate} <- MemoryRegistry.get_candidate(candidate_id),
         :ok <- validate_gate_evidence(evidence),
         :ok <- verifier.verify(evidence) do
      verified_evidence =
        Map.merge(evidence, %{
          verified_at: Clock.now_unix(),
          verification_status: :verified
        })

      updated = %{
        candidate
        | gates: Map.put(candidate.gates, gate, verified_evidence),
          status: :gate_updated
      }

      MemoryRegistry.put_candidate(updated)
      {:ok, updated}
    end
  end

  defp validate_gate_evidence(evidence) do
    missing = Enum.reject(@required_evidence_fields, &Map.has_key?(evidence, &1))

    cond do
      missing != [] ->
        {:error, {:missing_gate_evidence_fields, missing}}

      evidence.status not in [:pass, :fail, :pending] ->
        {:error, :invalid_gate_status}

      true ->
        :ok
    end
  end
end

defmodule Tiannara.Forecasting.Evolution.Promotion do
  @moduledoc false

  alias Tiannara.Forecasting.Adapters.MemoryRegistry
  alias Tiannara.Forecasting.Capability.Engine
  alias Tiannara.Forecasting.Capability.Certification
  alias Tiannara.Forecasting.Governance.AuthorizationLedger
  alias Tiannara.Forecasting.Evolution.Candidate

  def promote(candidate_id, capability_id, authorization_id) do
    with {:ok, candidate} <- MemoryRegistry.get_candidate(candidate_id),
         {:ok, capability} <- Engine.get(capability_id),
         {:ok, authorization} <- AuthorizationLedger.get_authorization(authorization_id),
         :ok <- check_candidate_gates(candidate),
         :ok <- check_capability_certified(capability),
         :ok <- check_candidate_authorization(candidate, authorization) do
      previous =
        case MemoryRegistry.get_champion(:current) do
          {:ok, current} -> current
          _ -> nil
        end

      if previous do
        MemoryRegistry.put_champion(:previous, previous)
      end

      MemoryRegistry.put_champion(:current, candidate_id)
      MemoryRegistry.put_champion(:candidate, nil)

      {:ok,
       %{
         promoted: candidate_id,
         previous: previous,
         rollback_available: previous != nil
       }}
    end
  end

  def rollback do
    case MemoryRegistry.get_champion(:previous) do
      {:ok, previous} ->
        MemoryRegistry.put_champion(:current, previous)
        {:ok, %{restored: previous}}

      _ ->
        {:error, :no_previous_champion}
    end
  end

  defp check_candidate_gates(candidate) do
    missing =
      Enum.reject(Candidate.required_gates(), fn gate ->
        gate_evidence = Map.get(candidate.gates, gate)
        is_map(gate_evidence) and Map.get(gate_evidence, :status) == :pass
      end)

    if missing == [] do
      :ok
    else
      {:error, {:missing_candidate_gate_evidence, missing}}
    end
  end

  defp check_capability_certified(capability) do
    if Certification.production?(capability) do
      :ok
    else
      {:error, :capability_not_production_certified}
    end
  end

  defp check_candidate_authorization(candidate, authorization) do
    now = Tiannara.Forecasting.Kernel.Clock.now_unix()

    cond do
      authorization.decision != :approve ->
        {:error, :authorization_not_approved}

      authorization.subject_type != :candidate ->
        {:error, :authorization_subject_type_mismatch}

      authorization.subject_id != candidate.id ->
        {:error, :authorization_candidate_mismatch}

      authorization.subject_digest != Candidate.digest(candidate) ->
        {:error, :candidate_digest_mismatch}

      authorization.gate_snapshot_digest != Candidate.gate_digest(candidate) ->
        {:error, :candidate_gate_snapshot_mismatch}

      authorization.expires_at != nil and authorization.expires_at <= now ->
        {:error, :authorization_expired}

      true ->
        :ok
    end
  end
end
```

---

# 11. Strict temporal integrity without inferred availability

```elixir
# lib/tiannara/forecasting/core/temporal_integrity.ex
defmodule Tiannara.Forecasting.Core.TemporalIntegrity do
  @moduledoc false

  def verify_request(%{cutoff: cutoff, observations: observations}) do
    with :ok <- verify_cutoff(cutoff),
         {:ok, warnings} <- verify_observations(observations, cutoff) do
      {:ok, %{warnings: warnings}}
    end
  end

  def verify_cutoff(cutoff) when is_integer(cutoff), do: :ok
  def verify_cutoff(_), do: {:error, {:temporal_integrity, :invalid_cutoff}}

  def verify_observations([], _cutoff), do: {:ok, []}

  def verify_observations(observations, cutoff) when is_list(observations) do
    Enum.reduce_while(observations, {:ok, []}, fn observation, {:ok, acc_warnings} ->
      case verify_observation(observation, cutoff) do
        {:ok, warnings} -> {:cont, {:ok, acc_warnings ++ warnings}}
        error -> {:halt, error}
      end
    end)
  end

  def verify_observations(_, _), do: {:error, {:temporal_integrity, :invalid_observations}}

  def reconstruct_information_state(observations, cutoff) do
    Enum.filter(observations, fn observation ->
      externally_available_at = Map.get(observation, :externally_available_at)
      revision_time = Map.get(observation, :revision_time)

      not is_nil(externally_available_at) and
        externally_available_at <= cutoff and
        (is_nil(revision_time) or revision_time <= cutoff)
    end)
  end

  defp verify_observation(observation, cutoff) do
    with {:ok, event_time} <- fetch_required(observation, :event_time),
         {:ok, observation_time} <- fetch_required(observation, :observation_time),
         {:ok, externally_available_at} <- fetch_required(observation, :externally_available_at),
         {:ok, ingestion_time} <- fetch_required(observation, :ingestion_time),
         {:ok, publication_time} <- fetch_optional(observation, :publication_time),
         {:ok, revision_time} <- fetch_optional(observation, :revision_time) do
      reference_time =
        if is_nil(publication_time) do
          observation_time
        else
          publication_time
        end

      cond do
        event_time > observation_time ->
          {:error, {:temporal_integrity, {:temporal_order_violation, :event_time}}}

        publication_time != nil and publication_time < observation_time ->
          {:error, {:temporal_integrity, {:temporal_order_violation, :publication_time}}}

        externally_available_at < reference_time ->
          {:error, {:temporal_integrity, {:temporal_order_violation, :externally_available_at}}}

        revision_time != nil and revision_time < observation_time ->
          {:error, {:temporal_integrity, {:temporal_order_violation, :revision_time}}}

        revision_time != nil and revision_time > cutoff ->
          {:error, {:temporal_integrity, {:future_timestamp, :revision_time}}}

        externally_available_at > cutoff ->
          {:error, {:temporal_integrity, {:future_timestamp, :externally_available_at}}}

        ingestion_time > cutoff ->
          {:error, {:temporal_integrity, {:future_timestamp, :ingestion_time}}}

        true ->
          {:ok, []}
      end
    end
  end

  defp fetch_required(observation, key) do
    case Map.fetch(observation, key) do
      {:ok, value} when is_integer(value) -> {:ok, value}
      _ -> {:error, {:temporal_integrity, {:invalid_or_missing_timestamp, key}}}
    end
  end

  defp fetch_optional(observation, key) do
    case Map.fetch(observation, key) do
      :error -> {:ok, nil}
      {:ok, value} when is_integer(value) -> {:ok, value}
      _ -> {:error, {:temporal_integrity, {:invalid_timestamp, key}}}
    end
  end
end
```

---

# 12. Improved predictability analyzer

```elixir
# lib/tiannara/forecasting/predictability/analyzer.ex
defmodule Tiannara.Forecasting.Predictability.Analyzer do
  @moduledoc false

  def analyze(%{observations: observations, flags: flags}) do
    values = Enum.map(observations, &Map.get(&1, :value))
    valid_values? = Enum.all?(values, &valid_value?/1)
    sample_size = length(values)

    data_sufficiency = data_sufficiency(sample_size, valid_values?)

    cond do
      not valid_values? ->
        %{
          decision: :ABSTAIN,
          data_sufficiency: data_sufficiency,
          predictability_score: 0.0,
          forecastability: 0.0,
          reasons: [:invalid_values],
          limitations: [:heuristic, :not_statistically_validated]
        }

      Map.get(flags, :distribution_shift, false) ->
        %{
          decision: :RUN_EXPERIMENT,
          data_sufficiency: data_sufficiency,
          predictability_score: 0.0,
          forecastability: 0.0,
          reasons: [:distribution_shift_detected],
          limitations: [:heuristic, :not_statistically_validated]
        }

      data_sufficiency.level == :insufficient ->
        %{
          decision: :COLLECT_MORE_DATA,
          data_sufficiency: data_sufficiency,
          predictability_score: 0.0,
          forecastability: 0.0,
          reasons: [:insufficient_history],
          limitations: [:heuristic, :not_statistically_validated]
        }

      true ->
        base_rate = mean(values)
        imbalance = abs(base_rate - 0.5) * 2
        entropy = binary_entropy(base_rate)
        lag1 = lag1_autocorrelation(values)
        constant_brier = constant_brier(values, base_rate)
        persistence_error = persistence_brier(values)

        baseline_skill =
          if constant_brier > 1.0e-6 and is_number(persistence_error) do
            max(0.0, (constant_brier - persistence_error) / constant_brier)
          else
            0.0
          end

        signal_strength = abs(lag1)

        nontrivial_predictability =
          clamp(0.7 * signal_strength + 0.3 * baseline_skill, 0.0, 1.0)

        trivial_forecastability = clamp(1 - entropy, 0.0, 1.0)

        decision =
          cond do
            nontrivial_predictability < 0.15 -> :ABSTAIN
            nontrivial_predictability < 0.35 -> :LOW_CONFIDENCE_PREDICT
            true -> :PREDICT
          end

        %{
          decision: decision,
          data_sufficiency: data_sufficiency,
          predictability_score: nontrivial_predictability,
          forecastability: trivial_forecastability,
          diagnostics: %{
            sample_size: sample_size,
            base_rate: base_rate,
            base_rate_imbalance: imbalance,
            entropy: entropy,
            lag1_autocorrelation: lag1,
            constant_brier: constant_brier,
            persistence_brier: persistence_error,
            baseline_skill: baseline_skill,
            signal_strength: signal_strength
          },
          reasons: [:nontrivial_predictability_analysis],
          limitations: [
            :heuristic,
            :no_null_model,
            :no_out_of_sample_validation,
            :not_a_certification_metric
          ]
        }
    end
  end

  defp data_sufficiency(sample_size, valid_values?) do
    level =
      cond do
        not valid_values? -> :invalid
        sample_size < 10 -> :insufficient
        sample_size < 30 -> :marginal
        true -> :adequate
      end

    %{
      level: level,
      sample_size: sample_size,
      valid_values: valid_values?
    }
  end

  defp valid_value?(value) do
    is_number(value) and value >= 0 and value <= 1
  end

  defp mean([]), do: 0.0
  defp mean(values), do: Enum.sum(values) / length(values)

  defp binary_entropy(p) when p <= 0.0 or p >= 1.0, do: 0.0

  defp binary_entropy(p) do
    -p * :math.log2(p) - (1 - p) * :math.log2(1 - p)
  end

  defp lag1_autocorrelation(values) when length(values) < 3, do: 0.0

  defp lag1_autocorrelation(values) do
    xs = Enum.drop(values, -1)
    ys = Enum.drop(values, 1)

    mean_x = mean(xs)
    mean_y = mean(ys)

    numerator =
      Enum.zip(xs, ys)
      |> Enum.reduce(0.0, fn {x, y}, acc ->
        acc + (x - mean_x) * (y - mean_y)
      end)

    denominator_x = variance_term(xs, mean_x)
    denominator_y = variance_term(ys, mean_y)

    if denominator_x == 0 or denominator_y == 0 do
      0.0
    else
      numerator / :math.sqrt(denominator_x * denominator_y)
    end
  end

  defp persistence_brier(values) when length(values) < 2, do: :unknown

  defp persistence_brier(values) do
    values
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [previous, actual] -> :math.pow(previous - actual, 2) end)
    |> mean()
  end

  defp constant_brier(values, constant) do
    values
    |> Enum.map(fn value -> :math.pow(constant - value, 2) end)
    |> mean()
  end

  defp variance_term(values, mean) do
    Enum.reduce(values, 0.0, fn value, acc ->
      acc + :math.pow(value - mean, 2)
    end)
  end

  defp clamp(value, min, max) do
    value |> max(min) |> min(max)
  end
end
```

---

# 13. Minimal experiment execution engine

This is still not a certified scientific engine, but it moves beyond a pure ledger.

```elixir
# lib/tiannara/forecasting/experiments/executor.ex
defmodule Tiannara.Forecasting.Experiments.Executor do
  @moduledoc false

  @callback execute(experiment :: map(), dataset :: list(), opts :: keyword()) ::
              {:ok, map()} | {:error, term()}
end
```

```elixir
# lib/tiannara/forecasting/experiments/mock_comparison_executor.ex
defmodule Tiannara.Forecasting.Experiments.MockComparisonExecutor do
  @moduledoc false
  @behaviour Tiannara.Forecasting.Experiments.Executor

  alias Tiannara.Forecasting.Kernel.RNGContext

  @impl true
  def execute(experiment, dataset, opts \\ []) do
    dataset =
      dataset
      |> Enum.sort_by(&Map.get(&1, :time, 0))

    sample_size = length(dataset)

    cond do
      sample_size < 10 ->
        {:error, :insufficient_dataset_size}

      not valid_dataset?(dataset) ->
        {:error, :invalid_dataset_rows}

      true ->
        test_fraction = Keyword.get(opts, :test_fraction, 0.3)
        test_size = max(1, round(sample_size * test_fraction))
        test_set = Enum.take(dataset, -test_size)

        baseline_metrics = metrics(test_set, :baseline)
        candidate_metrics = metrics(test_set, :candidate)

        with {:ok, baseline_brier} <- Map.fetch(baseline_metrics, :brier) |> normalize_fetch(),
             {:ok, candidate_brier} <- Map.fetch(candidate_metrics, :brier) |> normalize_fetch() do
          difference = candidate_brier - baseline_brier
          improvement = baseline_brier - candidate_brier

          bootstrap =
            bootstrap_confidence_interval(test_set, experiment, Keyword.get(opts, :bootstrap_samples, 200))

          significant =
            case bootstrap do
              {:ok, ci} -> elem(ci, 1) < 0
              _ -> false
            end

          {:ok,
           %{
             executor: :mock_comparison_executor,
             status: if(significant and improvement > 0, do: :pass, else: :fail),
             sample_size: sample_size,
             test_size: test_size,
             splitting_strategy: experiment.splitting_strategy,
             metrics: %{
               baseline: baseline_metrics,
               candidate: candidate_metrics,
               difference_candidate_minus_baseline_brier: difference,
               improvement_baseline_minus_candidate_brier: improvement
             },
             confidence_interval: bootstrap,
             multiple_testing_policy: experiment.multiple_testing_policy,
             stopping_rule: experiment.stopping_rule,
             note:
               "Minimal executable comparison engine. Still requires independent validation before certification use."
           }}
        end
    end
  end

  defp normalize_fetch(:error), do: {:error, :missing_metric}
  defp normalize_fetch({:ok, value}), do: {:ok, value}

  defp valid_dataset?(dataset) do
    Enum.all?(dataset, fn row ->
      is_number(Map.get(row, :outcome)) and
        is_number(Map.get(row, :baseline)) and
        is_number(Map.get(row, :candidate))
    end)
  end

  defp metrics(rows, key) do
    outcomes = Enum.map(rows, &Map.get(&1, :outcome))
    predictions = Enum.map(rows, &Map.get(&1, key))

    brier =
      Enum.zip(predictions, outcomes)
      |> Enum.reduce(0.0, fn {p, y}, acc -> acc + :math.pow(p - y, 2) end)
      |> Kernel./(length(rows))

    log_score = log_score(predictions, outcomes)

    %{
      brier: brier,
      log_score: log_score,
      sample_size: length(rows)
    }
  end

  defp log_score(predictions, outcomes) do
    result =
      Enum.zip(predictions, outcomes)
      |> Enum.reduce_while(0.0, fn {p, y}, acc ->
        probability_observed =
          if y == 1 do
            p
          else
            1 - p
          end

        if probability_observed <= 0 do
          {:halt, {:error, :zero_probability}}
        else
          {:cont, acc - :math.log(probability_observed)}
        end
      end)

    case result do
      {:error, _} = error -> error
      sum when is_float(sum) -> {:ok, sum / length(predictions)}
    end
  end

  defp bootstrap_confidence_interval(test_set, experiment, samples) do
    rng = RNGContext.new(:erlang.phash2({experiment.id, test_set}))

    {differences, _rng_final} =
      Enum.map_reduce(List.duplicate(nil, samples), rng, fn _, current_rng ->
        {sample_rows, next_rng} = resample(test_set, current_rng)

        baseline =
          sample_rows
          |> Enum.map(fn row -> :math.pow(row.baseline - row.outcome, 2) end)
          |> mean()

        candidate =
          sample_rows
          |> Enum.map(fn row -> :math.pow(row.candidate - row.outcome, 2) end)
          |> mean()

        {candidate - baseline, next_rng}
      end)

    sorted = Enum.sort(differences)
    lower = percentile(sorted, 2.5)
    upper = percentile(sorted, 97.5)

    {:ok, {lower, upper}}
  end

  defp resample(rows, rng) do
    n = length(rows)

    Enum.map_reduce(List.duplicate(nil, n), rng, fn _, current_rng ->
      {index, next_rng} = RNGContext.next_int(current_rng, n)
      {Enum.at(rows, index - 1), next_rng}
    end)
  end

  defp mean([]), do: 0.0
  defp mean(values), do: Enum.sum(values) / length(values)

  defp percentile(sorted, pct) do
    n = length(sorted)

    if n == 0 do
      0.0
    else
      rank = pct / 100 * (n - 1)
      lower = Float.floor(rank) |> trunc()
      upper = min(lower + 1, n - 1)
      weight = rank - lower
      Enum.at(sorted, lower) * (1 - weight) + Enum.at(sorted, upper) * weight
    end
  end
end
```

```elixir
# lib/tiannara/forecasting/experiments/experiment_engine.ex
defmodule Tiannara.Forecasting.Experiments.Ledger do
  @moduledoc false
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def propose(experiment) do
    GenServer.call(__MODULE__, {:propose, experiment})
  end

  def record_result(experiment_id, result) do
    GenServer.call(__MODULE__, {:record_result, experiment_id, result})
  end

  def get(experiment_id) do
    case :ets.lookup(:tf_experiments, experiment_id) do
      [{^experiment_id, experiment}] -> {:ok, experiment}
      [] -> {:error, :not_found}
    end
  end

  def list do
    :ets.tab2list(:tf_experiments) |> Enum.map(&elem(&1, 1))
  end

  def results(experiment_id) do
    :ets.lookup(:tf_experiment_results, experiment_id) |> Enum.map(&elem(&1, 1))
  end

  @impl true
  def init(_) do
    if :ets.whereis(:tf_experiments) == :undefined do
      :ets.new(:tf_experiments, [:set, :protected, :named_table])
    end

    if :ets.whereis(:tf_experiment_results) == :undefined do
      :ets.new(:tf_experiment_results, [:bag, :protected, :named_table])
    end

    {:ok, %{}}
  end

  @impl true
  def handle_call({:propose, experiment}, _from, state) do
    if :ets.member(:tf_experiments, experiment.id) do
      {:reply, {:error, :experiment_already_exists}, state}
    else
      :ets.insert(:tf_experiments, {experiment.id, experiment})
      {:reply, {:ok, experiment}, state}
    end
  end

  @impl true
  def handle_call({:record_result, experiment_id, result}, _from, state) do
    if :ets.member(:tf_experiments, experiment_id) do
      result = Map.put(result, :experiment_id, experiment_id)
      :ets.insert(:tf_experiment_results, {experiment_id, result})
      {:reply, {:ok, result}, state}
    else
      {:reply, {:error, :experiment_not_found}, state}
    end
  end
end

defmodule Tiannara.Forecasting.Experiments.Experiment do
  @moduledoc false

  alias Tiannara.Forecasting.Kernel.{Clock, ID}

  defstruct id: nil,
            hypothesis: nil,
            null_hypothesis: nil,
            alternative_hypothesis: nil,
            target: nil,
            dataset_digest: nil,
            cutoff: nil,
            sample_size: nil,
            splitting_strategy: nil,
            baseline: nil,
            candidate: nil,
            metrics_plan: [],
            multiple_testing_policy: nil,
            stopping_rule: nil,
            pre_registered_at: nil,
            status: :pre_registered

  def new(attrs) do
    attrs = Map.new(attrs)

    struct(__MODULE__, attrs)
    |> Map.put(:id, Map.get(attrs, :id, ID.new("EXP")))
    |> Map.put(:pre_registered_at, Clock.now_unix())
  end
end

defmodule Tiannara.Forecasting.Experiments.Engine do
  @moduledoc false

  alias Tiannara.Forecasting.Experiments.{Experiment, Ledger}
  alias Tiannara.Forecasting.Evidence.ArtifactStore
  alias Tiannara.Forecasting.Kernel.Clock

  @required_fields [
    :hypothesis,
    :null_hypothesis,
    :alternative_hypothesis,
    :target,
    :dataset_digest,
    :cutoff,
    :sample_size,
    :splitting_strategy,
    :baseline,
    :candidate,
    :metrics_plan,
    :multiple_testing_policy,
    :stopping_rule
  ]

  def propose(attrs) do
    attrs = Map.new(attrs)
    missing = Enum.reject(@required_fields, &Map.has_key?(attrs, &1))

    if missing != [] do
      {:error, {:missing_experiment_fields, missing}}
    else
      experiment = Experiment.new(attrs)
      Ledger.propose(experiment)
    end
  end

  def execute(experiment_id, dataset, opts \\ []) do
    executor = Application.fetch_env!(:tiannara_forecast, :experiment_executor)

    with {:ok, experiment} <- Ledger.get(experiment_id),
         {:ok, result} <- executor.execute(experiment, dataset, opts),
         {:ok, artifact} <- ArtifactStore.register(result) do
      recorded = %{
        result: result,
        artifact_id: artifact.id,
        artifact_digest: artifact.digest,
        executed_at: Clock.now_unix()
      }

      Ledger.record_result(experiment_id, recorded)
      {:ok, recorded}
    end
  end

  def get(experiment_id), do: Ledger.get(experiment_id)
  def list, do: Ledger.list()
  def results(experiment_id), do: Ledger.results(experiment_id)
end
```

---

# 14. Replay with independent replay hook

```elixir
# lib/tiannara/forecasting/core/replay_engine.ex
defmodule Tiannara.Forecasting.Core.ReplayEngine do
  @moduledoc false

  alias Tiannara.Forecasting.Kernel.RNGContext
  alias Tiannara.Forecasting.Core.{ExecutionManifest, ProbabilityDistribution}

  def replay(forecast) do
    runner = Application.fetch_env!(:tiannara_forecast, :model_runner)

    with {:ok, manifest} <- ensure_manifest(forecast.execution_manifest),
         {:ok, rng} <- ensure_rng(manifest.rng_record) do
      current_manifest = ExecutionManifest.reconstruct_from_forecast(forecast)
      manifest_verification = ExecutionManifest.verify(manifest, current_manifest)

      model_ref =
        case Map.keys(forecast.model_versions) do
          [model_id | _] ->
            %{model_id: model_id, version: Map.get(forecast.model_versions, model_id)}

          [] ->
            %{model_id: "baseline-historical", version: 1}
        end

      case runner.run(model_ref, forecast.request, rng) do
        {:ok, result} ->
          distribution_match =
            distributions_equal?(result.distribution, forecast.probabilities)

          self_match? = manifest_verification.match and distribution_match

          independent_report = run_independent_replay(forecast)

          reproducibility_level =
            reproducibility_level(self_match?, independent_report)

          {:ok,
           %{
             status: if(self_match?, do: :self_reproduced, else: :not_reproduced),
             reproducibility_level: reproducibility_level,
             manifest_verification: manifest_verification,
             independent_replay: independent_report,
             model_version: result.model_version,
             rng_record: RNGContext.record(result.rng),
             note:
               "R4 cryptographic reproducibility is not claimed without independent replay and environment attestation."
           }}

        error ->
          error
      end
    end
  end

  defp ensure_manifest(nil), do: {:error, :missing_execution_manifest}
  defp ensure_manifest(%ExecutionManifest{} = manifest), do: {:ok, manifest}
  defp ensure_manifest(_), do: {:error, :invalid_execution_manifest}

  defp ensure_rng(nil), do: {:error, :missing_rng_record}
  defp ensure_rng(record), do: {:ok, RNGContext.from_record(record)}

  defp run_independent_replay(forecast) do
    case Application.get_env(:tiannara_forecast, :independent_replayer) do
      nil ->
        {:error, :independent_replayer_not_configured}

      module ->
        case module.replay(forecast) do
          {:ok, %{distribution: distribution}} ->
            {:ok, distributions_equal?(distribution, forecast.probabilities)}

          error ->
            error
        end
    end
  end

  defp reproducibility_level(false, _independent_report), do: :R0

  defp reproducibility_level(true, {:ok, true}), do: :R3

  defp reproducibility_level(true, {:ok, false}), do: :R1

  defp reproducibility_level(true, _independent_not_available), do: :R2

  defp distributions_equal?(
         %ProbabilityDistribution{events: events_a},
         %ProbabilityDistribution{events: events_b}
       ) do
    keys_a = events_a |> Map.keys() |> Enum.sort()
    keys_b = events_b |> Map.keys() |> Enum.sort()

    keys_a == keys_b and
      Enum.all?(keys_a, fn key ->
        abs(Map.fetch!(events_a, key) - Map.fetch!(events_b, key)) <= 1.0e-9
      end)
  end
end
```

---

# 15. Updated API

This removes direct approval creation and adds validation-phase operations.

```elixir
# lib/tiannara/forecasting/api.ex
defmodule Tiannara.Forecasting.API do
  @moduledoc false

  alias Tiannara.Forecasting.Core.{
    ExecutionManifest,
    Forecast,
    ForecastLineage,
    ForecastRequest,
    ForecastResolution,
    ReplayEngine,
    TemporalIntegrity,
    Uncertainty
  }

  alias Tiannara.Forecasting.Kernel.RNGContext

  alias Tiannara.Forecasting.Baselines.BaseRateEngine
  alias Tiannara.Forecasting.Predictability.Analyzer
  alias Tiannara.Forecasting.Postmortem.Analyzer
  alias Tiannara.Forecasting.Capability.Engine
  alias Tiannara.Forecasting.Governance.Engine, as: GovernanceEngine
  alias Tiannara.Forecasting.Evidence.ArtifactStore
  alias Tiannara.Forecasting.Evidence.EventLog
  alias Tiannara.Forecasting.Experiments.Engine, as: ExperimentEngine
  alias Tiannara.Forecasting.Evolution.Candidate
  alias Tiannara.Forecasting.Evolution.Promotion
  alias Tiannara.Forecasting.EFDI.{ForecastQuality, Recommendation}

  def issue_forecast(attrs) do
    with {:ok, request} <- ForecastRequest.new(attrs),
         {:ok, temporal_report} <- TemporalIntegrity.verify_request(request) do
      predictability = Analyzer.analyze(request)

      case predictability.decision do
        decision when decision in [:PREDICT, :LOW_CONFIDENCE_PREDICT] ->
          create_forecast(request, temporal_report, predictability)

        _ ->
          {:ok, {:abstain, predictability}}
      end
    end
  end

  def resolve_forecast(forecast_id, outcome, attrs \\ %{}) do
    with {:ok, forecast} <- repo().get_forecast(forecast_id),
         {:ok, resolution} <- ForecastResolution.new(forecast, outcome, attrs),
         {:ok, saved} <- repo().append_resolution(resolution) do
      EventLog.append_event(:forecast_resolution, %{
        forecast_id: forecast_id,
        outcome: outcome
      })

      {:ok, saved}
    end
  end

  def run_postmortem(forecast_id, context \\ %{}) do
    with {:ok, forecast} <- repo().get_forecast(forecast_id),
         {:ok, resolution} <- repo().get_resolution(forecast_id) do
      postmortem = Analyzer.analyze(forecast, resolution, context)

      with {:ok, saved} <- repo().append_postmortem(postmortem) do
        EventLog.append_event(:forecast_postmortem, %{
          forecast_id: forecast_id,
          primary_hypothesis: saved.primary_hypothesis
        })

        {:ok, saved}
      end
    end
  end

  def replay_forecast(forecast_id) do
    with {:ok, forecast} <- repo().get_forecast(forecast_id) do
      ReplayEngine.replay(forecast)
    end
  end

  def recommend_decision(forecast_id, decision_context \\ %{}) do
    with {:ok, forecast} <- repo().get_forecast(forecast_id) do
      quality = ForecastQuality.from_forecast(forecast)
      {:ok, Recommendation.recommend(forecast, quality, decision_context)}
    end
  end

  def register_capability(capability_id, version \\ "0.1.0") do
    Engine.register_capability(capability_id, version)
  end

  def record_capability_gate(capability_id, gate, result, evidence \\ %{}) do
    Engine.record_gate(capability_id, gate, result, evidence)
  end

  def request_capability_authorization(capability_id, requester, evidence_digest, opts \\ []) do
    GovernanceEngine.request_capability_authorization(
      capability_id,
      requester,
      evidence_digest,
      opts
    )
  end

  def request_candidate_authorization(candidate_id, requester, evidence_digest, opts \\ []) do
    GovernanceEngine.request_candidate_authorization(
      candidate_id,
      requester,
      evidence_digest,
      opts
    )
  end

  def certify_capability(capability_id, authorization_id) do
    Engine.certify(capability_id, authorization_id)
  end

  def certification_matrix do
    Engine.matrix()
  end

  def trust_profile(capability_id) do
    Engine.trust_profile(capability_id)
  end

  def register_evidence_artifact(content) do
    ArtifactStore.register(content)
  end

  def record_candidate_gate_evidence(candidate_id, gate, evidence) do
    Candidate.record_gate_evidence(candidate_id, gate, evidence)
  end

  def promote_candidate(candidate_id, capability_id, authorization_id) do
    Promotion.promote(candidate_id, capability_id, authorization_id)
  end

  def propose_experiment(attrs) do
    ExperimentEngine.propose(attrs)
  end

  def execute_experiment(experiment_id, dataset, opts \\ []) do
    ExperimentEngine.execute(experiment_id, dataset, opts)
  end

  def append_evidence_event(type, payload) do
    EventLog.append_event(type, payload)
  end

  def verify_evidence_event_log do
    EventLog.verify_chain()
  end

  def verify_ledger_chain do
    repo = repo()

    if Code.ensure_loaded?(repo) and function_exported?(repo, :verify_chain, 0) do
      repo.verify_chain()
    else
      {:error, :ledger_chain_not_supported}
    end
  end

  defp create_forecast(request, temporal_report, predictability) do
    rng = RNGContext.new(request.rng_seed)
    model_ref = %{model_id: "baseline-historical", version: 1}

    with {:ok, base_rate} <- BaseRateEngine.historical_frequency(request),
         {:ok, run} <- runner().run(model_ref, request, rng) do
      manifest =
        ExecutionManifest.build(%{
          forecast_id: nil,
          request: request,
          data_snapshot: %{
            observations:
              TemporalIntegrity.reconstruct_information_state(
                request.observations,
                request.cutoff
              )
          },
          feature_snapshot: request.feature_versions,
          source_snapshot: request.source_versions,
          model_manifest: %{
            model_ref: model_ref,
            runner: runner()
          },
          signal_manifest: %{status: :unspecified},
          calibration_manifest: %{status: :unspecified},
          regime_manifest: %{status: :unspecified},
          knowledge_version:
            Application.get_env(:tiannara_forecast, :knowledge_version, "seed"),
          configuration: %{
            model_policy: request.model_policy,
            horizon: request.horizon,
            horizon_unit: request.horizon_unit,
            target: request.target,
            domain: request.domain
          },
          software_commit:
            Application.get_env(:tiannara_forecast, :software_commit, "unset"),
          dependency_lock_digest:
            Application.get_env(:tiannara_forecast, :dependency_lock_digest, "unset"),
          runtime_version: to_string(:erlang.system_info(:otp_release)),
          rng_record: RNGContext.record(rng)
        })

      trust_profile = Engine.trust_profile(:forecast_core)

      params = %{
        request: request,
        probabilities: run.distribution,
        base_rate: base_rate,
        model_versions: %{run.model_version.model_id => run.model_version.version},
        execution_manifest: manifest,
        temporal_warnings: temporal_report.warnings,
        uncertainty: Uncertainty.explicit_mock(),
        confidence_in_confidence: trust_profile,
        software_version:
          Application.get_env(:tiannara_forecast, :software_version, "dev"),
        knowledge_version:
          Application.get_env(:tiannara_forecast, :knowledge_version, "seed"),
        certification_context: %{
          forecast_core: trust_profile,
          predictability: predictability.limitations
        }
      }

      with {:ok, draft} <- Forecast.draft(params),
           {:ok, frozen} <- Forecast.freeze(draft),
           {:ok, saved} <- repo().append_forecast(frozen) do
        ForecastLineage.record(request.parent_forecast_id, saved.id)

        EventLog.append_event(:forecast_issued, %{
          forecast_id: saved.id,
          trust_level: trust_profile.trust_level
        })

        {:ok, saved}
      end
    end
  end

  defp repo do
    Application.fetch_env!(:tiannara_forecast, :forecast_repo)
  end

  defp runner do
    Application.fetch_env!(:tiannara_forecast, :model_runner)
  end
end
```

---

# Final status

This layer remains:

```text
IMPLEMENTED
NOT VALIDATED
NOT PRODUCTION-CERTIFIED
```

It improves the validation substrate by adding:

- governance request/decision separation
- default deny-all council
- candidate-bound authorization
- evidence artifact verification
- certification invalidation on gate change
- strict external availability temporal integrity
- nontrivial predictability separation from base-rate imbalance
- minimal executable experiment comparison
- independent replay hook
- evidence event log
- trust profiles instead of fake numeric confidence

But it still does **not** establish production certification. The next phase remains:

```text
EVIDENCE VERIFICATION
↓
SCIENTIFIC EXPERIMENT EXECUTION
↓
CERTIFICATION INVARIANTS
↓
ADVERSARIAL TESTING
↓
SHADOW FORECASTING
↓
REPLICATION
↓
VALIDATION
↓
GOVERNANCE AUTHORIZATION
↓
PRODUCTION CERTIFICATION
```