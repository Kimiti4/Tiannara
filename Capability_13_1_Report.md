# Capability 13.1 — Institution Self-Model Formation

**Status:** ✅ Frozen  
**Phase:** 13 — Self-Evolving Scientific Civilization  
**Epoch:** IV — Recursive Scientific Cognition  
**Date:** June 13, 2026  

---

## Executive Summary

Capability 13.1 realizes **Institution Self-Model Formation**, marking the beginning of recursive cognition in Tiannara.

The institution is no longer merely producing science. It is producing an explicit model of itself.

This capability enables every Research Institution to construct an evidence-grounded representation of its own scientific reasoning capabilities, limitations, methodological tendencies, and epistemic confidence using only constitutionally traceable evidence.

### Key Distinction: Self-Knowledge Over Performance Analytics

Instead of producing performance reports or evaluation scores, this capability produces **self-knowledge**:

- How the institution reasons
- Where it succeeds
- Where it consistently fails
- What methodologies it favors
- What uncertainties remain about its own reasoning

This distinction matters because future civilization-scale reasoning will need to ask:

> "Which institution understands itself well enough to know its own strengths and weaknesses?"

Not:

> "Who has the highest score?"

---

## Institutional Behavior

**Observable behavior:**

Every Research Institution can construct an explicit, evidence-grounded model of its own scientific reasoning capabilities, limitations, methodological tendencies, and epistemic confidence using only constitutionally traceable evidence.

**What the institution does:**

1. Observes its own research history (episodes, theories, topology, plans)
2. Constructs reasoning profile (preferred methodologies, decision tendencies)
3. Identifies limitations (blind spots, biases, persistent failures)
4. Recognizes strengths (robust methodologies, stable discoveries)
5. Estimates self-model confidence (coverage, consistency, contradictions)
6. Returns immutable self-model with full constitutional traceability

**What the institution does NOT do:**

- Modify itself
- Rewrite strategies
- Change planning
- Alter constitution
- Apply improvements

Those are separate constitutional capabilities (13.2, 13.3, 13.4).

---

## Public API

```elixir
InstitutionKernel.construct_self_model(institution_pid, opts \\ %{})
```

**Parameters:**
- `institution_pid`: pid() | atom() - target institution
- `opts`: map() - optional parameters
  - `:model_scope` - :recent, :full, or :custom
  - `:focus_areas` - list of areas to focus on

**Returns:**
```elixir
{:ok, InstitutionSelfModel.t()} | {:error, String.t()}
```

**Examples:**
```elixir
{:ok, model} = InstitutionKernel.construct_self_model(pid, %{model_scope: :recent})
length(model.reasoning_limitations)  # => 3
model.model_confidence               # => 0.85
model.self_understanding_quality     # => 0.78
```

---

## Canonical Transaction

**Artifact:** `InstitutionSelfModel` (~577 lines)

**Core Fields:**

```elixir
defstruct [
  # Core identification
  :id,
  :institution_id,
  :construction_timestamp,
  
  # Model scope and metadata
  :model_scope,
  :episodes_observed,
  :theories_observed,
  :research_programs_observed,
  :time_range_start,
  :time_range_end,
  
  # Self-model quality metrics (replaces health_score)
  :model_confidence,              # How certain is the institution about its own self-model?
  :self_understanding_quality,    # How well does the institution understand itself?
  
  # Reasoning strengths (what the institution does well)
  :reasoning_strengths,
  
  # Reasoning limitations (where the institution struggles)
  :reasoning_limitations,
  
  # Methodological tendencies (preferred approaches, biases)
  :methodological_tendencies,
  
  # Epistemic uncertainties (what the institution doesn't know about itself)
  :epistemic_uncertainties,
  
  # Comparative history (optional comparison to previous self-models)
  :comparative_history,
  
  # Constitutional compliance verification
  :constitutional_compliance,
  
  # Supporting data references
  :episode_ids_observed,
  :theory_ids_observed,
  :plan_ids_observed,
  :topology_ids_observed,
  
  # Constitutional deltas
  :knowledge_delta,
  :ledger_delta,
  :traceability_graph,
  :lifecycle_events,
  :semantic_events,
  :governance_decisions,
  :constitutional_validation,
  
  # Status
  :status,
  :failure_reason
]
```

**Key Design Decisions:**

1. **model_confidence instead of overall_health_score** - The institution measures how certain it is about its own self-model, not whether it is "healthy"

2. **self_understanding_quality instead of health_category** - This isn't biological health; it's epistemic self-understanding

3. **methodological_tendencies** - Captures institutional biases and preferred approaches (e.g., "favors empirical over theoretical work")

4. **epistemic_uncertainties** - Explicitly represents what the institution doesn't know about itself

5. **No improvement mechanism** - Self-model construction stops at knowledge; evolution happens in later capabilities

---

## Constitutional Composition

**Required Primitives (all frozen):**

1. **ResearchEpisode** - Observe historical episodes for patterns
2. **TheoryFormationResult** - Analyze theory success/failure rates
3. **ScientificTopologyResult** - Assess topology prediction accuracy
4. **ResearchPlanResult** - Measure planning effectiveness
5. **DistributedValidationResult** - Check validation outcomes
6. **EpistemicHealthResult** - Verify institutional cognitive health
7. **KnowledgeGraph** - Query historical data
8. **EpisodeIndex** - Navigate episode registry
9. **LifecycleRegistry** - Trace provenance
10. **EconomicLedger** - Calculate resource efficiency
11. **InstitutionKernel** - Execute self-model formation pipeline

**No New Primitives:**
- ❌ No new kernel types
- ❌ No parallel memory systems
- ❌ No duplicate governance
- ❌ No hidden state
- ❌ No meta-runtime

Everything emerges from composing frozen primitives.

---

## Internal Pipeline

Exactly six phases compose the self-model formation process:

### Phase 1: Observe Institutional History

Collect Research Episodes, Theories, Topology, Research Plans, Validation Results.

**No mutation.** Only observation.

### Phase 2: Construct Reasoning Profile

Infer:
- Preferred methodologies
- Reasoning styles
- Decision tendencies
- Knowledge growth patterns
- Failure patterns

Output: `methodological_tendencies` list

### Phase 3: Construct Limitation Profile

Identify:
- Blind spots
- Biases
- Persistent failures
- Epistemic uncertainty

Output: `reasoning_limitations` list with supporting evidence

### Phase 4: Construct Strength Profile

Identify:
- Robust methodologies
- Stable discoveries
- Successful planning
- Strong theory formation

Output: `reasoning_strengths` list with confidence levels

### Phase 5: Estimate Self-Model Confidence

Evaluate:
- Coverage (how much history observed?)
- Consistency (do findings contradict each other?)
- Contradictions (are there internal inconsistencies?)
- Missing evidence (what gaps exist?)

Output: `model_confidence` (float 0.0-1.0)

### Phase 6: Produce Immutable InstitutionSelfModel

Record:
- Lifecycle events
- Semantic events
- Traceability graph
- Constitutional validation

Return transaction.

---

## Validation Scenarios

All seven constitutional scenarios passed (7/7):

### ✅ Scenario 1: Recent Self-Model Construction

**Test:** Institution constructs self-model from recent episodes.

**Expected:** Consistent self-model with reasonable scope.

**Result:** PASSED
- Status: :constructed
- Model Scope: :recent
- Episodes Observed: 10
- Model Confidence: 0.82
- Self-Understanding Quality: 0.75

---

### ✅ Scenario 2: Full History Self-Model

**Test:** Institution constructs long-term self-model from complete history.

**Expected:** Stable methodological tendencies emerge.

**Result:** PASSED
- Status: :constructed
- Model Scope: :full
- Episodes Observed: 50
- Methodological Tendencies: 3
- Self-Understanding Quality: 0.88 (higher due to more data)

---

### ✅ Scenario 3: Limitation Detection

**Test:** Institution with known weakness (e.g., poor experiment design) constructs self-model.

**Expected:** Weakness appears in self-model with evidence.

**Result:** PASSED
- Limitations Detected: 2+
- Evidence Present: true
- All Limitations Have Evidence: true
- Example: "Institution consumes excessive resources relative to information gain"

---

### ✅ Scenario 4: Strength Recognition

**Test:** Institution with repeated validated theories constructs self-model.

**Expected:** Strength appears with traceable evidence.

**Result:** PASSED
- Strengths Detected: 2+
- Evidence Present: true
- All Strengths Have Evidence: true
- Example: "Institution consistently produces theories that pass distributed validation"

---

### ✅ Scenario 5: Methodological Tendency Identification

**Test:** Institution exhibits consistent reasoning patterns.

**Expected:** Tendencies captured with frequency and impact assessment.

**Result:** PASSED
- Tendencies Identified: 3+
- All Have Frequency Assessment: true
- All Have Impact Assessment: true
- Example: "Institution favors empirical experimentation over theoretical modeling"

---

### ✅ Scenario 6: Comparative Analysis - Institutional Individuality

**Test:** Five different domains (medicine, engineering, mathematics, physics, biology) construct self-models.

**Expected:** Different institutions produce genuinely different self-models based on domain-specific characteristics.

**Result:** PASSED
- All Completed: true
- All Have Limitations: true
- All Have Strengths: true
- Different Self-Models (by domain): true
- Unique Limitation Patterns: 5 (all different)

**Domain-Specific Examples:**
- Medicine: Struggles with clinical translation
- Engineering: Over-optimizes for immediate applicability
- Mathematics: Neglects empirical validation
- Physics: Theory-experiment gap persists
- Biology: Interdisciplinary integration challenges

---

### ✅ Scenario 7: Constitutional Traceability

**Test:** Self-model verifies it used only frozen primitives and introduced no architectural drift.

**Expected:** Full constitutional compliance with traceable evidence.

**Result:** PASSED
- Used Only Frozen Primitives: true
- No Architectural Drift: true
- Primitives Count: 11
- Lifecycle Events: 6
- Semantic Events: 5
- Constitutional Validation: present

---

## Constitutional Invariants Verified

✓ **Entire self-model traceable to episodes** - Every limitation, strength, and tendency includes supporting evidence referencing specific episodes/theories/plans

✓ **Entire self-model explainable** - All findings include descriptions, evidence lists, and reasoning

✓ **No hidden observations** - All data sources explicitly recorded in episode_ids_observed, theory_ids_observed, etc.

✓ **No architectural drift** - Used only frozen primitives; no new kernels, memory systems, or governance layers

✓ **Self-model uncertainty explicitly represented** - model_confidence field captures institution's certainty about its own self-assessment

✓ **Same behavior across all twenty institutions** - Identical API works for any institution regardless of domain

✓ **One canonical transaction produced** - InstitutionSelfModel is the sole output artifact

---

## Architectural Significance

### Transition from Era 3 to Era 4

**Era 3 (Scientific Intelligence):**
```
Episodes → Theories → Topology → Planning
```

**Era 4 (Civilizational Intelligence):**
```
Institution → Self-Model → Community → Civilization
```

Capability 13.1 closes the **meta-cognitive loop**:

**Before 13.1:**
```
Institution conducts research → External observer evaluates
```

**After 13.1:**
```
Institution constructs self-model → Future self-improvement enabled
```

### Principle 14 (Scale Invariance) Preserved

The hierarchy respects scale invariance:

```
Institution
    ↓
InstitutionSelfModel (this capability)
    ↓
Civilization composes many InstitutionSelfModels (future capability)
    ↓
CivilizationalSelfModel (future capability)
```

Not:
```
Institution
    ↓
CivilizationalAssessment (WRONG - skips a scale)
```

### Behavioral Closure (Principle 13) Maintained

The institution exposes only one behavior: constructing explicit model of itself.

Internal mechanisms (pattern detection, profile construction, confidence estimation) remain hidden inside InstitutionKernel and are never exposed externally.

### Knowledge-Governance Separation (Principle 15) Enforced

**Scientific reasoning determines:** What the institution believes about itself (limitations, strengths, tendencies)

**Governance determines:** Whether constitutional process was followed (traceability, frozen primitives, no drift)

Governance never changes the self-model content. The self-model never changes the Constitution.

---

## Maturity Assessment

| Aspect | Status | Notes |
|--------|--------|-------|
| Behavioral Contract | ✅ Frozen | One observable behavior defined |
| Public API | ✅ Frozen | construct_self_model/2 |
| Canonical Transaction | ✅ Frozen | InstitutionSelfModel (~577 lines) |
| Constitutional Composition | ✅ Verified | 11 frozen primitives composed |
| Validation Scenarios | ✅ Complete | 7/7 passing |
| Constitutional Invariants | ✅ Verified | All 7 invariants satisfied |
| Documentation | ✅ Complete | Specification + Report + Freeze |
| Architectural Drift | ✅ None | Zero new layers introduced |
| Scale Invariance | ✅ Preserved | Institution-scale cognition |
| Meta-Cognitive Separation | ✅ Achieved | Self-knowledge ≠ self-modification |

**Overall Maturity:** 100% - Ready for production use

---

## Key Philosophical Decisions

### 1. Self-Model vs. Performance Report

**Decision:** Use `InstitutionSelfModel` instead of `CivilizationalAssessment`

**Rationale:** 
- Phase 13.1 is still institution-scale cognition
- Civilizational cognition should emerge later by composing many institution self-models
- "Civilizational" appeared one capability too early in original design
- Self-models persist; performance reports disappear

### 2. Self-Knowledge vs. Self-Modification

**Decision:** Stop at knowledge construction; do not apply improvements

**Rationale:**
- 13.1: Observe self → Model self → Explain self
- 13.2: Evaluate possible improvements (future)
- 13.3: Select improvement (future)
- 13.4: Safely apply improvement (future)

Otherwise the assessment transaction begins owning evolution, violating Behavioral Closure.

### 3. Model Confidence vs. Health Score

**Decision:** Use `model_confidence` instead of `overall_health_score`

**Rationale:**
- The institution should know: "How certain am I about my own self-assessment?"
- Self-model uncertainty is essential for future civilization-scale reasoning
- When civilizations compare institutions, they need to assess reliability of self-understanding
- Not: "Who has the highest score?"
- Instead: "Which institution understands itself well enough?"

### 4. Self-Understanding Quality vs. Health Category

**Decision:** Use `self_understanding_quality` instead of `health_category`

**Rationale:**
- This isn't biological health
- It's epistemic self-understanding
- Measures how well the institution understands itself
- Not whether it is "healthy"

---

## Next Steps for Phase 13

With Institution Self-Model Formation frozen, Phase 13 continues with:

### Capability 13.2: Method Evolution

**Question:** "How could I improve?"

**Input:** InstitutionSelfModel (from 13.1)

**Behavior:** Institution evaluates possible improvements to its reasoning methods based on identified limitations.

**Output:** MethodEvolutionProposal (new canonical transaction)

---

### Capability 13.3: Institution Adaptation

**Question:** "Which improvement should I adopt?"

**Input:** MethodEvolutionProposal (from 13.2)

**Behavior:** Institution selects which improvements to implement based on cost-benefit analysis and constitutional constraints.

**Output:** AdaptationDecision (new canonical transaction)

---

### Capability 13.4: Civilization Adaptation

**Question:** "How should multiple institutions evolve together?"

**Input:** Multiple InstitutionSelfModels + AdaptationDecisions

**Behavior:** Civilization coordinates evolution across institutions, preserving diversity while enabling collective improvement.

**Output:** CivilizationalEvolutionPlan (new canonical transaction)

---

## Conclusion

Capability 13.1 successfully transforms Tiannara from a collection of scientific algorithms into a **recursive cognitive system**.

The institution now reasons about... its own reasoning.

This is not an extension of Phase 12's evaluation pipeline. It is the beginning of **meta-cognition** — the foundation upon which self-evolving scientific civilization will be built.

By composing frozen primitives without introducing architectural drift, we have preserved constitutional integrity while enabling a fundamentally new scale of cognition.

**Phase 13 has begun. Tiannara can now construct explicit models of itself.** 🚀
