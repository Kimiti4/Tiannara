# CAPABILITY 13.1 SPECIFICATION — Civilizational Self-Assessment

**Status**: 📝 Specification  
**Phase**: 13 — Self-Evolving Scientific Civilization  
**Epoch**: IV — Meta-Cognitive Evolution  

---

## Institutional Behavior

**The institution evaluates its own scientific performance and discovers weaknesses in its reasoning methods.**

Observable behavior:
- Institution produces a self-assessment report analyzing past research effectiveness
- Report identifies patterns of success/failure across multiple research programs
- Report recommends methodological improvements for future research
- Assessment is traceable to actual episodes, theories, and topology metrics
- Different institutions produce different assessments based on their history

---

## Public API

```elixir
InstitutionKernel.assess_scientific_performance(institution_pid, opts \\ %{})
```

**Parameters:**
- `institution_pid`: pid() | atom() - target institution
- `opts`: map() - optional parameters
  - `:assessment_scope` - :recent (last 10 episodes), :full (all episodes), :custom (specify range)
  - `:focus_areas` - list of areas to assess (:theory_formation, :experiment_design, :topology_analysis, :research_planning)
  - `:comparison_baseline` - optional baseline to compare against (previous assessment or peer institution)

**Returns:**
```elixir
{:ok, CivilizationalAssessment.t()} | {:error, String.t()}
```

---

## Canonical Transaction

**CivilizationalAssessment** (~650 lines estimated)

Fields:
- `:id` - unique assessment identifier
- `:institution_id` - institution that performed assessment
- `:assessment_timestamp` - when assessment was created
- `:scope` - what was assessed (:recent, :full, :custom)
- `:episodes_analyzed` - number of episodes included in assessment
- `:theories_analyzed` - number of theories included
- `:research_programs_analyzed` - number of programs evaluated
- `:performance_metrics` - map of quantitative metrics
  - `:theory_success_rate` - percentage of theories validated
  - `:experiment_efficiency` - average information gain per resource unit
  - `:topology_accuracy` - how well topology predictions matched reality
  - `:planning_effectiveness` - correlation between planned and actual outcomes
- `:reasoning_weaknesses` - list of identified weaknesses
  - `:weakness_id` - unique identifier
  - `:category` - :theory_formation, :experiment_design, :topology_analysis, :research_planning
  - `:description` - human-readable description
  - `:evidence` - supporting data (episode IDs, theory IDs, metrics)
  - `:severity` - :low, :medium, :high, :critical
  - `:recommended_improvement` - suggested methodological change
- `:strengths` - list of identified strengths (same structure as weaknesses)
- `:methodological_recommendations` - list of recommended changes to scientific process
  - `:recommendation_id` - unique identifier
  - `:area` - which area to improve
  - `:current_method` - current approach
  - `:proposed_method` - improved approach
  - `:expected_benefit` - anticipated improvement
  - `:implementation_cost` - estimated effort to adopt
  - `:priority` - :immediate, :short_term, :long_term
- `:comparative_analysis` - optional comparison to baseline
  - `:baseline_id` - what we're comparing to
  - `:improvements` - areas that improved
  - `:regressions` - areas that declined
  - `:stable_patterns` - consistent behaviors
- `:constitutional_compliance` - verification that assessment followed constitutional process
  - `:used_only_frozen_primitives` - boolean
  - `:primitives_used` - list of primitive types composed
  - `:no_architectural_drift` - boolean
- `:lifecycle_events` - audit trail of assessment creation
- `:status` - :completed, :failed, :partial
- `:failure_reason` - if failed, why

---

## Constitutional Composition

This capability composes ONLY frozen primitives:

### Required Primitives

1. **ResearchEpisode** - Analyze past episodes for patterns
2. **TheoryFormationResult** - Evaluate theory success rates
3. **ScientificTopologyResult** - Assess topology prediction accuracy
4. **ResearchPlanResult** - Measure planning effectiveness
5. **EpistemicHealthResult** - Check institutional cognitive health
6. **KnowledgeGraph** - Query historical data
7. **LifecycleRegistry** - Trace provenance
8. **EconomicLedger** - Calculate resource efficiency

### No New Primitives

❌ No new kernel types  
❌ No parallel memory systems  
❌ No duplicate governance  
❌ No hidden state  

Everything emerges from composing existing InstitutionKernel capabilities.

---

## Internal Pipeline

Six phases, following frozen pattern:

### Phase 1: Collect Historical Data
- Query KnowledgeGraph for episodes within scope
- Retrieve TheoryFormationResults
- Retrieve ScientificTopologyResults
- Retrieve ResearchPlanResults
- Retrieve EpistemicHealthResults
- Aggregate into assessment dataset

### Phase 2: Calculate Performance Metrics
- Theory success rate = validated theories / total theories
- Experiment efficiency = Σ(information_gain / cost) / count
- Topology accuracy = correct predictions / total predictions
- Planning effectiveness = correlation(planned_outcomes, actual_outcomes)
- Record all metrics with evidence trails

### Phase 3: Identify Reasoning Weaknesses
- Pattern detection: Where do failures cluster?
- Statistical analysis: Which methods underperform?
- Comparative analysis: How does this compare to peers/baseline?
- Generate weakness descriptions with evidence
- Assign severity based on impact magnitude

### Phase 4: Identify Strengths
- Inverse of Phase 3: Where do successes cluster?
- Identify robust methods worth preserving
- Document successful patterns for reuse
- Assign confidence levels to strength claims

### Phase 5: Generate Methodological Recommendations
- For each weakness, propose improvement
- Estimate implementation cost
- Estimate expected benefit
- Prioritize by ROI (benefit/cost ratio)
- Ensure recommendations are actionable (not abstract)

### Phase 6: Verify Constitutional Compliance
- Confirm only frozen primitives were used
- Verify no architectural drift occurred
- Record lifecycle events
- Produce final assessment artifact
- Return to caller

---

## Validation Scenarios

Seven scenarios testing civilizational self-assessment:

### Scenario 1: Recent Performance Assessment
**Given:** Institution with 10+ recent episodes  
**When:** Institution performs self-assessment with scope=:recent  
**Then:** Assessment includes all recent episodes, calculates metrics, produces report  

### Scenario 2: Full History Assessment
**Given:** Institution with extensive episode history  
**When:** Institution performs self-assessment with scope=:full  
**Then:** Assessment analyzes entire history, identifies long-term patterns  

### Scenario 3: Weakness Detection
**Given:** Institution with known reasoning failures (e.g., poor experiment design)  
**When:** Institution performs self-assessment  
**Then:** Assessment correctly identifies the weakness with evidence  

### Scenario 4: Strength Recognition
**Given:** Institution with consistently successful methods  
**When:** Institution performs self-assessment  
**Then:** Assessment correctly identifies strengths with confidence levels  

### Scenario 5: Methodological Recommendation Generation
**Given:** Institution with identified weaknesses  
**When:** Institution performs self-assessment  
**Then:** Assessment produces actionable recommendations with cost/benefit estimates  

### Scenario 6: Comparative Analysis
**Given:** Two institutions with different histories  
**When:** Both perform self-assessment  
**Then:** Assessments differ based on institutional context (different weaknesses, strengths, recommendations)  

### Scenario 7: Constitutional Traceability
**Given:** Completed assessment  
**When:** Assessment is examined  
**Then:** Full traceability to frozen primitives, no architectural drift detected  

---

## Constitutional Invariants

1. **Only Frozen Primitives Used** - Assessment must compose existing primitives, never introduce new ones
2. **Single Observable Behavior** - One public API, one canonical transaction
3. **Complete Traceability** - Every metric traceable to specific episodes/theories/plans
4. **No Hidden State** - All assessment data derived from KnowledgeGraph queries
5. **Behavioral Closure** - Algorithms internal, only assessment result exposed
6. **Scale Invariance** - Assessment works at institution scale, composable to ecology/civilization
7. **Knowledge-Governance Separation** - Assessment reports findings, doesn't modify Constitution

---

## Architectural Significance

This capability represents the first step toward **self-evolving scientific cognition**.

Before 13.1:
```
Institution conducts research
    ↓
Produces episodes, theories, plans
    ↓
External observer evaluates
```

After 13.1:
```
Institution conducts research
    ↓
Produces episodes, theories, plans
    ↓
Institution evaluates ITS OWN performance
    ↓
Discovers weaknesses
    ↓
Recommends improvements
    ↓
Future research improves
```

This closes the meta-cognitive loop: **the institution learns how to learn better**.

---

## Expected Deliverables

1. **Canonical Transaction**: `lib/tiannara/os/civilizational_assessment.ex` (~650 lines)
2. **Public API**: `InstitutionKernel.assess_scientific_performance/2` in `lib/tiannara/os/institution_kernel.ex`
3. **Internal Pipeline**: Six phases in InstitutionKernel
4. **Validation Script**: `run_capability_13_1_validation.exs` (7 scenarios)
5. **Capability Report**: `Capability_13_1_Report.md`
6. **Freeze Documentation**: `CAPABILITY_13_1_FROZEN.md`

---

## Success Criteria

✓ One observable behavior defined  
✓ One public API implemented  
✓ One canonical transaction created  
✓ Seven validation scenarios passing  
✓ Constitutional invariants verified  
✓ Capability report generated  
✓ Capability frozen  
✓ Constitutional Capability Matrix updated  
✓ **No architectural drift introduced**  

---

**Next Step**: Implement canonical transaction artifact (`CivilizationalAssessment`)
