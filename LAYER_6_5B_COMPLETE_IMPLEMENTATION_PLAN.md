# Layer 6.5B Institutional Recovery - Complete Implementation Plan

**Date**: June 13, 2026  
**Purpose**: Prove that institutions can create adaptive knowledge production through evolution  
**Key Question**: "Can institutions learn to recover faster?" (not just "can they recover?")

---

## Executive Summary

Layer 6.5A proved JTMS++ works correctly for truth maintenance. Layer 6.5B will test whether **Research Programs as Knowledge Conversion Engines** can evolve better research strategies through crises, achieving not just recovery but **adaptation and antifragility**.

**Critical Insight**: JTMS++ maintains truth. Research Programs convert uncertainty into validated knowledge. The system evolves by learning which research strategies work best under pressure.

**Primary Metrics** (Three Dimensions):
1. **Knowledge Generation Rate**: Raw productivity (hypotheses + evidence + discoveries)
2. **Knowledge Conversion Rate**: Quality (validated / candidate discoveries)
3. **Knowledge Retention Rate**: Durability (validated surviving shocks / validated before shock)
4. **Recovery Speed Improvement**: Adaptation (recovery time decreases across shocks)
5. **Knowledge Velocity Acceleration**: Antifragility (post-shock velocity > pre-shock velocity)

---

## What Layer 6.5B Must Prove

### Core Paradigm Shift

**JTMS++ Role**: Maintain, Propagate, Revise, Retire truth (PROVEN in 6.5A)

**Research Program Role**: Convert uncertainty → validated knowledge through evolving strategies

**NOT**: Programs as recovery sources

**INSTEAD**: Programs as knowledge conversion engines that learn from crises

### Success Ladder (5 Levels)

#### Level 1 — Survival
```
Programs remain active after shocks
```

#### Level 2 — Recovery
```
Programs restore confidence through validation
```

#### Level 3 — Adaptation ⭐ **KEY METRIC**
```
Recovery time improves across shocks:
Shock 1: 20,000 ticks
Shock 2: 12,000 ticks  
Shock 3: 7,000 ticks
```
Even if confidence drops the same amount, faster recovery = adaptation.

#### Level 4 — Evolution
```
Programs evolve better research strategies:
- Aggressive Exploration gains funding
- Conservative Validation proves more durable
- Cross-Domain Synthesis emerges
```

#### Level 5 — Antifragility ⭐ **ULTIMATE GOAL**
```
Post-shock knowledge velocity > Pre-shock velocity
AND
Recovery time decreases after every crisis
```
The civilization becomes BETTER at producing knowledge BECAUSE of disruption.

---

## Core Components to Implement

### 1. Research Programs as Knowledge Conversion Engines

#### Program Structure
```elixir
%ResearchProgram{
  id: :program_id,
  domain: :physics,
  status: :active | :suspended | :terminated,
  funding: float(),           # Knowledge capital allocated
  team_size: integer(),       # Number of researchers
  
  # RESEARCH STRATEGY GENOME ⭐ NEW
  strategy_genome: %{
    exploration_rate: float(),      # 0.0-1.0 (novel vs established)
    validation_priority: float(),   # 0.0-1.0 (replicate vs discover)
    cross_domain_synthesis: float(), # 0.0-1.0 (interdisciplinary)
    anomaly_sensitivity: float(),    # 0.0-1.0 (focus on outliers)
    risk_tolerance: float()          # 0.0-1.0 (bold vs conservative)
  },
  
  performance_metrics: %{
    discoveries_produced: integer(),
    validation_rate: float(),
    knowledge_velocity: float(),
    recovery_time_ticks: integer(),  # Time to recover from last shock
    strategy_effectiveness: float()  # How well this genome performs
  }
}
```

#### Strategy Genomes (Evolutionary Component) ⭐ CRITICAL NEW

Programs inherit and evolve research strategies:

**Aggressive Exploration**: High exploration_rate, low validation_priority
- Pros: Generates many novel hypotheses
- Cons: Low conversion rate, high failure rate

**Conservative Validation**: Low exploration_rate, high validation_priority
- Pros: High conversion rate, stable
- Cons: Slow innovation, may miss breakthroughs

**Replication First**: Very high validation_priority
- Pros: Builds robust knowledge base
- Cons: Doesn't generate new discoveries

**Cross-Domain Synthesis**: High cross_domain_synthesis
- Pros: Innovative combinations, unexpected insights
- Cons: Complex, harder to validate

**Anomaly Hunting**: High anomaly_sensitivity
- Pros: Finds edge cases, challenges assumptions
- Cons: May chase noise instead of signal

#### Program Behaviors (Knowledge Conversion Pipeline)

1. **Hypothesis Generation** (Strategy-dependent)
   - Use strategy genome to determine approach
   - Generate candidates based on exploration_rate
   - Balance novelty vs. established knowledge

2. **Experiment Design** (Strategy-dependent)
   - Choose validation vs. discovery focus
   - Allocate resources based on risk_tolerance
   - Decide cross-domain vs. focused approach

3. **Evidence Production**
   - Run experiments → produce evidence nodes
   - Evidence quality depends on validation_priority
   - Track methodology effectiveness

4. **Discovery Validation**
   - Test candidate discoveries
   - Calculate conversion rate
   - Update strategy effectiveness metrics

5. **Strategy Evolution** ⭐ NEW
   - Successful strategies gain funding
   - Failed strategies lose funding or mutate
   - Crossover between successful programs
   - Mutation introduces variation

6. **Methodology Asset Creation** ⭐ NEW
   - Successful approaches become reusable assets
   - Future programs inherit proven methods
   - Creates compounding improvement

### 2. Knowledge Capital System

#### Formula
```elixir
knowledge_capital = 
  (validated_discoveries * 10) +
  (active_theories * 5) +
  (replication_success_rate * 20) +
  (influence_score)
```

#### Funding Allocation
- Programs receive resources proportional to knowledge capital
- High-performing programs get more funding
- Low-performing programs face termination
- Creates selection pressure for effective research

### 3. Discovery Economy

#### Discovery Exchange
- Programs can share discoveries
- Cross-pollination between domains
- Import/export mechanisms
- Prevents siloed knowledge

#### Discovery Assets
- Validated discoveries become assets
- Can be "spent" to fund new research
- Create positive feedback loop
- Reward successful programs

### 4. Multi-Dimensional Knowledge Tracking ⭐ ENHANCED

#### Five Critical Metrics

**1. Knowledge Generation Rate** (Productivity)
```elixir
generation_rate = (new_hypotheses + new_evidence + new_discoveries) / time_interval
```
Measures raw output volume.

**2. Knowledge Conversion Rate** (Quality) ⭐ KEY METRIC
```elixir
conversion_rate = validated_discoveries / candidate_discoveries
```
A civilization generating 100 discoveries that validate 2 is WEAKER than one generating 20 that validate 10.

**3. Knowledge Retention Rate** (Durability) ⭐ NEW
```elixir
retention_rate = validated_surviving_shocks / validated_before_shock
```
Measures how much validated knowledge survives crises.

**4. Recovery Speed** (Adaptation) ⭐ MOST IMPORTANT
```elixir
# Track recovery time for each shock
shock_1_recovery_time = 20_000 ticks
shock_2_recovery_time = 12_000 ticks
shock_3_recovery_time = 7_000 ticks

# Calculate improvement
adaptation_ratio = shock_1_time / shock_3_time  # Should be > 1.0
```
If recovery gets FASTER across shocks = ADAPTATION (even if confidence drops same amount).

**5. Knowledge Velocity Acceleration** (Antifragility) ⭐ ULTIMATE METRIC
```elixir
pre_shock_velocity = validated_per_interval_before
post_shock_velocity = validated_per_interval_after

antifragility_ratio = post_shock_velocity / pre_shock_velocity

# If > 1.0 AND recovery_time decreasing = ANTIFRAGILE
```
The civilization produces MORE knowledge BECAUSE of disruption.

---

## Test Configuration

### Tier 1: Basic Institutional Recovery (Debugging)
- **Worlds**: 5
- **Programs per world**: 3 (total: 15)
- **Ticks**: 25,000
- **Shocks**: 1 at tick 5,000
- **Focus**: Verify programs activate and produce discoveries

### Tier 2: Validation (Moderate Scale)
- **Worlds**: 10
- **Programs per world**: 5 (total: 50)
- **Ticks**: 40,000
- **Shocks**: 2 at ticks 10k, 25k
- **Focus**: Measure knowledge velocity improvement

### Tier 3: Stress Testing
- **Worlds**: 25
- **Programs per world**: 5 (total: 125)
- **Ticks**: 60,000
- **Shocks**: 3 at ticks 15k, 30k, 45k
- **Focus**: Sustained recovery under pressure

### Tier 4: Full Scale
- **Worlds**: 50
- **Programs per world**: 5 (total: 250)
- **Ticks**: 100,000
- **Shocks**: 5 at ticks 15k, 30k, 50k, 70k, 85k
- **Focus**: Long-term institutional resilience

---

## Success Criteria (5-Level Ladder)

### Level 1: Survival ✅ Minimum Viable
1. ✅ Programs remain active after shocks (>70% survive)
2. ✅ Programs produce new discoveries (generation_rate > 0)
3. ✅ Strategy genomes persist across generations
4. ✅ No catastrophic collapse

### Level 2: Recovery ✅ Basic Functionality
1. ✅ Confidence decline slower than 6.5A baseline
2. ✅ Conversion rate > 0.2 (20% of candidates validated)
3. ✅ Retention rate > 0.5 (50% of validated knowledge survives)
4. ✅ Programs detect damage and respond

### Level 3: Adaptation ⭐ **KEY TARGET**
1. ✅ Recovery time improves across shocks:
   - Shock 1 recovery: baseline
   - Shock 2 recovery: < 80% of Shock 1 time
   - Shock 3 recovery: < 60% of Shock 1 time
2. ✅ Adaptation ratio > 1.5 (recovery 50% faster by Shock 3)
3. ✅ Strategy effectiveness metrics show learning
4. ✅ Successful strategies gain funding share

### Level 4: Evolution ⭐ **ADVANCED**
1. ✅ Strategy genomes evolve (mutation + selection visible)
2. ✅ Diverse strategies coexist (no monoculture)
3. ✅ Methodology assets created and reused
4. ✅ Cross-domain synthesis emerges naturally
5. ✅ Program performance correlates with strategy fit to domain

### Level 5: Antifragility ⭐ **ULTIMATE GOAL**
1. ✅ Post-shock velocity > Pre-shock velocity (antifragility_ratio > 1.0)
2. ✅ Recovery time decreases after EVERY crisis
3. ✅ Knowledge production ACCELERATES due to disruption
4. ✅ System demonstrates meta-learning (learns how to learn)
5. ✅ Civilization becomes more innovative under pressure

---

## Comparison with Layer 6.5A

| Metric | 6.5A (Baseline) | 6.5B Target | Improvement |
|--------|-----------------|-------------|-------------|
| Recovery mechanism | Passive (+0.0005/tick) | Active (strategy-driven) | Qualitative change |
| Knowledge generation | ~0 (no production) | >0 (active production) | Infinite % increase |
| Conversion rate | N/A (no validation) | >0.2 (20% validate) | New capability |
| Retention rate | Low (passive decay) | >0.5 (50% survive) | Durability |
| Recovery speed | N/A (no recovery) | Improving across shocks | ADAPTATION |
| Antifragility | N/A | Ratio > 1.0 possible | ANTIFRAGILE |
| Strategy evolution | N/A | Genomes evolve | EVOLUTION |
| Institutional survival | N/A | >70% programs survive | Resilience |

---

## Implementation Phases

### Phase B1: Program Infrastructure (Week 1)
- [ ] Create ResearchProgram struct
- [ ] Implement program initialization
- [ ] Add program tracking to State
- [ ] Create basic program lifecycle (activate/suspend/terminate)

### Phase B2: Knowledge Capital (Week 1)
- [ ] Implement knowledge capital formula
- [ ] Add funding allocation mechanism
- [ ] Create performance tracking
- [ ] Implement resource distribution

### Phase B3: Active Research Behaviors (Week 2)
- [ ] Implement damage detection
- [ ] Add hypothesis generation
- [ ] Create experiment execution
- [ ] Implement evidence production

### Phase B4: Discovery Economy (Week 2)
- [ ] Create Discovery Exchange
- [ ] Implement Discovery Assets
- [ ] Add cross-program sharing
- [ ] Create import/export mechanisms

### Phase B5: Knowledge Velocity Tracking (Week 3)
- [ ] Add velocity metrics
- [ ] Implement pre/post shock comparison
- [ ] Create adaptation ratio calculation
- [ ] Add reporting and visualization

### Phase B6: Testing & Validation (Week 3-4)
- [ ] Run Tier 1 (debugging)
- [ ] Fix issues
- [ ] Run Tier 2 (validation)
- [ ] Run Tier 3 (stress)
- [ ] Run Tier 4 (full scale)

---

## Integration with Existing Systems

### JTMS++ Integration
- Programs create new evidence nodes → trigger cascades
- Validated discoveries boost confidence → propagate
- Failed experiments degrade confidence → propagate
- All tracked in dependency_history

### Phase 12 Integration
- Program performance feeds Scientific Discovery Stack
- Successful strategies stored as institutional memory
- Failed approaches flagged for avoidance
- Learning accumulates across shocks

### Future Layer 6.5C Integration
- Programs compete for limited resources
- Knowledge migration between worlds
- Winner-take-all dynamics emerge
- Evolutionary pressure on research strategies

---

## Risk Mitigation

### Risk 1: Programs Don't Activate
**Mitigation**: Start with simple activation rules, verify in Tier 1

### Risk 2: Knowledge Production Too Slow
**Mitigation**: Tune production rates, ensure meaningful output

### Risk 3: Funding Mechanism Unstable
**Mitigation**: Use conservative allocation formulas, monitor closely

### Risk 4: Complexity Overwhelms Simulation
**Mitigation**: Progressive scaling, profile performance at each tier

---

## Expected Outcomes

### If Successful
- Proves institutions matter for recovery
- Demonstrates active knowledge production beats passive healing
- Validates Research Program architecture
- Provides baseline for Layer 6.5C competition

### If Partially Successful
- Shows programs help but insufficient alone
- Identifies which mechanisms need strengthening
- Guides refinements before competition layer

### If Unsuccessful
- Reveals fundamental flaws in program design
- May need to revisit Phase 12 Step 1 assumptions
- Could indicate need for different recovery paradigm

---

## Files to Create

### Test Files
1. `test/tiannara/os/layer6_5b_institutional_recovery_test.exs` - Main test suite
2. `test/tiannara/os/layer6_5b_tier1_basic_test.exs` - Tier 1 debugging
3. `test/tiannara/os/layer6_5b_tier2_validation_test.exs` - Tier 2 validation
4. `test/tiannara/os/layer6_5b_tier3_stress_test.exs` - Tier 3 stress
5. `test/tiannara/os/layer6_5b_tier4_fullscale_test.exs` - Tier 4 full scale

### Module Files
1. `lib/tiannara/os/research_program.ex` - Program struct and logic
2. `lib/tiannara/os/knowledge_capital.ex` - Capital calculation
3. `lib/tiannara/os/discovery_exchange.ex` - Sharing mechanism
4. `lib/tiannara/os/program_manager.ex` - Lifecycle management

### Documentation
1. `LAYER_6_5B_IMPLEMENTATION_PLAN.md` - This document
2. `LAYER_6_5B_RESULTS.md` - Results summary
3. `LAYER_6_5B_KNOWLEDGE_VELOCITY_ANALYSIS.md` - Velocity metrics deep dive

---

## Next Steps After 6.5B

Regardless of outcome, proceed to:

### Layer 6.5C: Competitive Recovery
- Add competition between programs/worlds
- Implement knowledge migration
- Test if competition drives innovation
- Measure evolutionary dynamics

### Then: Full Integration
- Combine 6.5A (epistemic) + 6.5B (institutional) + 6.5C (competitive)
- Run comprehensive civilization simulation
- Validate complete recovery pipeline
- Prepare for Phase 12 integration

---

## Conclusion

Layer 6.5B is not about fixing JTMS++ (already proven sound). It's about adding the **missing organ**: active knowledge production through evolving Research Programs.

### The Key Insight

**JTMS++ maintains truth. Research Programs convert uncertainty into validated knowledge.**

The system evolves by learning which research strategies work best under pressure.

### Three-Layer Architecture

Once complete, Tiannara will have:

1. **Truth Maintenance** (JTMS++ - Layer 6.5A ✅ PROVEN)
   - Maintain, propagate, revise, retire truth
   - Linear scaling, no explosive behavior
   - Sound mathematics

2. **Knowledge Production** (Research Programs - Layer 6.5B 🚧 IN PROGRESS)
   - Convert uncertainty → validated knowledge
   - Evolve research strategies through crises
   - Learn from disruption

3. **Knowledge Selection** (Competition - Layer 6.5C ⏳ FUTURE)
   - Select effective strategies
   - Eliminate ineffective approaches
   - Drive innovation through competition

### From Coherent to Self-Renewing

Layer 6.5A proved Tiannara is:
```
Epistemically Coherent
Scalable
Traceable
Recoverable
```

Layer 6.5B will transform it to:
```
Self-Renewing
Adaptive
Evolutionary
Potentially Antifragile
```

### The Ultimate Test

Not confidence recovery.

Not knowledge velocity.

**This**: 

```
Shock 1: Recovery time = 20,000 ticks
Shock 2: Recovery time = 12,000 ticks
Shock 3: Recovery time = 7,000 ticks

Post-shock velocity > Pre-shock velocity

Strategy genomes evolve toward effectiveness
```

If achieved, you've created the first **self-improving scientific civilization runtime** that becomes better at producing knowledge BECAUSE of disruption, not despite it.

That is much closer to the long-term vision of Tiannara than simply building a larger JTMS.

---

## Strategic Roadmap

**Phase 1**: Truth Maintenance ✅ COMPLETE (Layer 6.5A)
- JTMS++ validated
- Propagation proven sound
- Scaling characteristics measured

**Phase 2**: Knowledge Production 🚧 CURRENT (Layer 6.5B)
- Implement Research Programs as conversion engines
- Add strategy genomes for evolution
- Measure adaptation and antifragility
- Prove institutions can learn

**Phase 3**: Knowledge Selection ⏳ NEXT (Layer 6.5C)
- Add competition between programs/worlds
- Implement knowledge migration
- Test evolutionary dynamics
- Prove selection drives innovation

**Phase 4**: Integration ⏳ FUTURE
- Combine all three layers
- Run comprehensive civilization simulation
- Validate complete self-improvement pipeline
- Prepare for Phase 12 Scientific Discovery Stack integration

This is the path from epistemic coherence to self-renewing intelligence.
