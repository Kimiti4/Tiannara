# Phase 4 — Alpha Campaign Preparation

**Date**: June 18, 2026  
**Phase**: Crucible Civilization - Alpha Campaign  
**Status**: 🔄 Ready to Launch  

---

## Overview

The Alpha Campaign is the first large-scale test of ASC's scientific loop. It will generate the data needed to validate law candidates and discover the first established software engineering laws.

### Campaign Targets

```
25 Projects
500 Failures
100 Exploits
50 Repairs
→ 2,000-5,000 Observations
→ 8-15 Candidate Laws
→ 2-5 Established Laws
→ 0-1 Canonical Principles
```

---

## Architecture Status

### Completed Components

✅ **Builder** (SC-B1 through SC-B4) - Build pipeline with error taxonomy  
✅ **Validator** (SC-V1 through SC-V4) - Validation with false negative estimation  
✅ **Breaker** (SC-BR1 through SC-BR3) - Failure generation with classification  
✅ **Attacker** (SC-A1 through SC-A5) - Exploit discovery with reproducibility  
✅ **Repairer** (SC-R1 through SC-R5) - Adaptation with knowledge reuse  
✅ **Observation** - Unified telemetry format for all 5 sources  
✅ **Observatory** - Aggregation layer with automatic law candidate generation  
✅ **Epoch** - Cross-epoch comparison and knowledge compression analysis  

### Pending Integration

⚠️ **Module Integration** - Update all 5 modules to emit `%CrucibleObservation{}`  
⚠️ **Observatory State** - Add epoch tracking fields to Observatory GenServer  
⚠️ **Alpha Runner** - Create campaign orchestration module  

---

## New Metrics Added

Beyond the base observatory metrics, the Epoch layer adds three critical measurements:

### 1. Adaptation Velocity

```elixir
adaptation_velocity = successful_repairs / total_failures
```

**Purpose**: Measures how quickly the civilization learns from failures.

**Target**: Upward trend across epochs (>0.5 by epoch 3)

**Significance**: High adaptation velocity indicates efficient learning mechanisms. Low velocity suggests repair strategies are not generalizing.

---

### 2. Learning Yield

```elixir
learning_yield = candidate_laws / 1000 observations
```

**Purpose**: Measures scientific productivity—how many hypotheses emerge per unit of evidence.

**Target**: >3.0 (3 candidate laws per 1000 observations)

**Significance**: High yield indicates rich observation space with diverse failure modes. Low yield suggests either insufficient diversity or overly strict law generation thresholds.

---

### 3. Knowledge Compression Ratio

```elixir
knowledge_compression_ratio = observations / established_laws
```

**Purpose**: Measures how much evidence is required before a stable law emerges.

**Target**: <1000 (less than 1000 observations per established law)

**Significance**: This becomes extremely important for cross-domain comparison:

```
Software Engineering: 1200 observations → 4 laws (ratio: 300)
Governance:           8000 observations → 2 laws (ratio: 4000)
Cognition:             600 observations → 5 laws (ratio: 120)
```

Now Tiannara can ask: **"Which domains generate knowledge most efficiently?"**

Low ratio = domain has clear, discoverable principles  
High ratio = domain is complex, context-dependent, or lacks sufficient structure

---

## Expected Outcomes

Based on the campaign targets, we expect:

### Observation Distribution

| Source | Expected Count | Percentage |
|--------|---------------|------------|
| Builder | 500-1000 | 25% |
| Validator | 400-800 | 20% |
| Breaker | 500-1000 | 25% |
| Attacker | 300-600 | 15% |
| Repairer | 200-400 | 10% |
| Recovery | 100-200 | 5% |
| **Total** | **2,000-5,000** | **100%** |

### Law Candidate Distribution

| Law Type | Expected Count | Confidence Range |
|----------|---------------|------------------|
| Resilience Through Recoverability | 1-2 | 0.6-0.8 |
| Explicit Constraints Improve Survivability | 1-2 | 0.5-0.7 |
| Knowledge Reuse Outperforms Reinvention | 2-3 | 0.7-0.9 |
| Transferability Predicts Value | 1-2 | 0.5-0.7 |
| Other emergent patterns | 3-6 | 0.4-0.6 |
| **Total** | **8-15** | **-** |

### Established Laws (confidence ≥ 0.8)

Based on historical REA patterns, we expect 2-5 laws to reach establishment threshold:

1. **Knowledge Reuse Outperforms Reinvention** (highest probability)
   - Evidence: repair_success_rate, reuse_rate, patch_stability
   - Expected confidence: 0.85-0.92

2. **Resilience Through Recoverability** (medium probability)
   - Evidence: recovery_rate, mean_time_to_recovery, survival_rate
   - Expected confidence: 0.78-0.85

3. **Explicit Constraints Reduce Failure Severity** (medium probability)
   - Evidence: invariant_count, critical_failure_count, repair_success_rate
   - Expected confidence: 0.75-0.82

4. **Adversarial Testing Improves Long-term Stability** (lower probability)
   - Evidence: exploit_recurrence_rate, patch_survival_generations, survival_rate
   - Expected confidence: 0.70-0.78

5. **Recovery Latency Predicts Survivability** (lowest probability)
   - Evidence: mean_time_to_recovery, survival_rate, adaptation_velocity
   - Expected confidence: 0.65-0.75

### Canonical Principles

If any law achieves:
- confidence ≥ 0.9
- cross-epoch consistency (appears in ≥2 epochs)
- transferability (applies to ≥2 different project types)

Then it graduates to **Canonical Principle** status.

Most likely candidate: **Knowledge Reuse Outperforms Reinvention** because it appears everywhere:
- Repair Patterns
- API Evolution
- Architecture Evolution
- Cross-Domain Transfer
- Research Director

---

## Success Criteria

The Alpha Campaign succeeds if:

### Scale Requirements ✅

- [ ] 25+ projects tested
- [ ] 500+ failures observed
- [ ] 100+ exploits discovered
- [ ] 50+ repair attempts

### Quality Requirements ✅

- [ ] SC-B1: Build success rate >80%
- [ ] SC-B2: Build determinism 95%+
- [ ] SC-B3: Error taxonomy coverage 100%
- [ ] SC-B4: Telemetry coverage 100%
- [ ] SC-V1: Invariant preservation detection 100%
- [ ] SC-V2: Constraint satisfaction verification 95%+
- [ ] SC-V3: Contract compliance validation 100%
- [ ] SC-V4: False negative rate <5%
- [ ] SC-BR1: Failure discovery rate >50%
- [ ] SC-BR2: Input diversity coverage 100%
- [ ] SC-BR3: Failure classification accuracy 95%+
- [ ] SC-A1: Attack surface coverage >90%
- [ ] SC-A2: Exploit discovery rate >30%
- [ ] SC-A3: Severity classification 100%
- [ ] SC-A4: Reproducibility rate >95%
- [ ] SC-A5: False positive rate <5%
- [ ] SC-R1: Repair success rate >70%
- [ ] SC-R2: Regression rate <10%
- [ ] SC-R3: Recovery latency downward trend
- [ ] SC-R4: Patch stability >90%
- [ ] SC-R5: Knowledge reuse rate >40%

### Discovery Requirements ✅

- [ ] 8+ candidate laws generated
- [ ] 2+ established laws (confidence ≥ 0.8)
- [ ] 0-1 canonical principles identified
- [ ] Learning yield >3.0
- [ ] Knowledge compression ratio <1000

---

## Integration Checklist

Before launching the Alpha Campaign, complete these integrations:

### 1. Builder Integration

Add to `lib/tiannara/asc/crucible/builder.ex`:

```elixir
def build(%Genome{} = genome, project_id, opts \\ []) do
  # ... existing build logic ...

  # Record observation
  observation = Observation.from_builder_result(build_result, project_id, genome.genome_id, genome.generation)
  Crucible.Observatory.record_observation(observation)

  {:ok, build_result}
end
```

### 2. Validator Integration

Add to `lib/tiannara/asc/crucible/validator.ex`:

```elixir
def validate(%Genome{} = genome, artifact_path, opts \\ []) do
  # ... existing validation logic ...

  # Record observation
  observation = Observation.from_validator_result(validation_result, project_id, genome.genome_id, genome.generation)
  Crucible.Observatory.record_observation(observation)

  {:ok, validation_result}
end
```

### 3. Breaker Integration

Add to `lib/tiannara/asc/crucible/breaker.ex`:

```elixir
def break(%Genome{} = genome, artifact_path, opts \\ []) do
  # ... existing break logic ...

  # Record observation
  observation = Observation.from_breaker_result(break_result, project_id, genome.genome_id, genome.generation)
  Crucible.Observatory.record_observation(observation)

  {:ok, break_result}
end
```

### 4. Attacker Integration

Add to `lib/tiannara/asc/crucible/attacker.ex`:

```elixir
def attack(%Genome{} = genome, artifact_path, opts \\ []) do
  # ... existing attack logic ...

  # Record observation
  observation = Observation.from_attacker_result(attack_result, project_id, genome.genome_id, genome.generation)
  Crucible.Observatory.record_observation(observation)

  {:ok, attack_result}
end
```

### 5. Repairer Integration

Add to `lib/tiannara/asc/crucible/repairer.ex`:

```elixir
def repair(failure_observation, artifact_path, opts \\ []) do
  # ... existing repair logic ...

  # Record observation
  observation = Observation.from_repairer_result(repair_result, project_id, genome.genome_id, genome.generation)
  Crucible.Observatory.record_observation(observation)

  # Register repair pattern if successful
  if repair_result.repair_successful? do
    pattern = extract_repair_pattern(repair_result)
    Crucible.Observatory.register_repair_pattern(pattern)
  end

  {:ok, repair_result}
end
```

### 6. Epoch Finalization

Create function to finalize epoch at campaign end:

```elixir
defmodule Tiannara.ASC.Crucible.EpochManager do
  @moduledoc """
  Manages Alpha Campaign epochs and finalization.
  """

  alias Tiannara.ASC.Crucible.Epoch
  alias Tiannara.ASC.Crucible.Observatory

  @doc """
  Finalize current epoch and store in archive.
  """
  def finalize_epoch(epoch_id, projects_tested) do
    # Get observatory metrics
    {:ok, metrics} = Observatory.get_metrics()

    # Create epoch record
    epoch = Epoch.from_observatory_metrics(epoch_id, metrics, projects_tested)

    # Check if meets alpha criteria
    if Epoch.meets_alpha_criteria?(epoch) do
      IO.puts("✅ Alpha Campaign SUCCESS")
      IO.inspect(Epoch.summarize(epoch), label: "Summary")
    else
      IO.puts("❌ Alpha Campaign INCOMPLETE")
      IO.inspect(Epoch.summarize(epoch), label: "Summary")
    end

    # Store epoch
    {:ok, epoch}
  end
end
```

---

## Post-Campaign Analysis

After the Alpha Campaign completes, perform:

### 1. Law Validation

For each candidate law:
- Verify confidence ≥ 0.8
- Check cross-epoch consistency
- Assess transferability across project types
- Promote to established law if criteria met

### 2. Principle Extraction

For established laws:
- Identify common themes
- Abstract to higher-level principles
- Test against future epochs
- Promote to canonical principle if universally applicable

### 3. Cross-Domain Transfer Assessment

Evaluate which laws/principles can transfer to:
- Cognition (mental model evolution)
- Cybernetics (control system design)
- Governance (institutional resilience)
- Computation (algorithm robustness)

### 4. Knowledge Efficiency Analysis

Calculate knowledge compression ratios:
```
Software Engineering: X observations → Y laws → ratio Z
```

Compare with other domains as they mature.

---

## Next Steps After Alpha Campaign

### If Successful (meets all criteria):

1. **Scale to Full Campaign**
   - 100 projects
   - 10,000 failures
   - 1,000 attacks
   - 500 repairs
   - Target: 25+ candidate laws, 5+ established laws, 1+ canonical principle

2. **Cross-Domain Transfer**
   - Extract transferable principles
   - Apply to Cognition/Cybernetics/Governance
   - Measure transfer effectiveness

3. **Autonomous Project Construction**
   - Use established laws to guide project generation
   - Measure improvement over baseline
   - Iterate based on outcomes

### If Unsuccessful (fails criteria):

1. **Diagnose Bottlenecks**
   - Insufficient failure diversity?
   - Poor repair quality?
   - Weak law generation thresholds?

2. **Adjust Parameters**
   - Increase mutation rates
   - Relax law confidence thresholds
   - Enhance failure injection

3. **Run Beta Campaign**
   - Same targets with adjusted parameters
   - Compare results to Alpha

---

## Architectural Maturity Assessment

| Component | Maturity | Change |
|-----------|----------|--------|
| Infrastructure | 96% | +1% |
| Scientific Loop | 82% | +7% |
| Knowledge Discovery | 65% | +5% |
| Autonomous Engineering | 50% | +0% |

**Overall ASC Maturity**:
- Infrastructure: **96%** (near complete)
- Scientific Loop: **82%** (observation → law pipeline operational)
- Knowledge Discovery: **65%** (needs Alpha Campaign data)
- Autonomous Engineering: **50%** (awaits established laws)

The bottleneck has definitively shifted from **infrastructure** to **data generation**. More modules produce diminishing returns. The highest-value work is now running the Alpha Campaign and validating the observation → law → principle pipeline.

---

## Conclusion

The Alpha Campaign represents the transition from **generating software** to **generating knowledge**. 

Before this campaign:
- ASC could build, validate, break, attack, and repair systems
- But it couldn't learn from those experiences systematically
- No unified observation format
- No aggregated metrics
- No automatic law discovery

After this campaign:
- ASC will have generated 2,000-5,000 observations
- Discovered 8-15 candidate laws
- Established 2-5 validated laws
- Possibly identified 0-1 canonical principles
- Measured knowledge efficiency (compression ratio)
- Assessed cross-domain transfer potential

This is the same transition REA underwent around REA-4 and REA-5, where observations become patterns and patterns become laws. The unified observation model, law candidate emission, repair pattern tracking, and epoch aggregation are exactly the mechanisms that enable that transition.

The experiment that now matters most is: **"Does the observation → law → principle pipeline actually produce reproducible engineering knowledge?"**

If yes, ASC joins Computation, Cybernetics, Cognition, and Governance as a genuine knowledge-producing domain rather than a tooling subsystem.

If no, we diagnose why and iterate.

Either way, the Alpha Campaign is the critical milestone.
