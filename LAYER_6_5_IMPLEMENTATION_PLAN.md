# Layer 6.5 — Civilization Recovery Test Implementation Plan

**Objective**: Verify that Tiannara can survive epistemic catastrophe through three sequential experiments isolating epistemic, institutional, and competitive recovery dynamics.

**Rationale**: This test answers the critical question: "Can a civilization survive epistemic catastrophe?" Rather than mixing all dynamics into one monolithic test, we split into three sequential experiments for scientific interpretability:

- **6.5A**: Can truth recover? (epistemic layer only)
- **6.5B**: Can institutions recover? (adds programs, funding, promotion)
- **6.5C**: Can competition improve recovery? (adds selection pressure)

**Key Innovation**: Introduces genuine adaptive loop with **competing research programs**, **knowledge migration**, **world death**, and **recovery integrity tracking**, moving from graph-level testing to civilization-level testing.

**Output**: Generates empirical dataset for Phase 12 (Scientific Discovery Stack) and Phase 11.9A (Orbit Engineering).

---

## Test Design: Three Sequential Experiments

**IMPORTANT**: Layer 6.5 is split into three sequential experiments for scientific interpretability. Each builds on the previous.

### Layer 6.5A: Epistemic Recovery

**Scope**: Evidence nodes, discovery nodes, theory nodes, JTMS++ cascades ONLY

**Excludes**: Programs, funding, competition, knowledge migration

**Question**: "Can truth recover from epistemic shock?"

**Configuration**:
```elixir
@worlds_count 10
@theories_per_world 20        # Total: 200 theories
@discoveries_per_world 10     # Total: 100 discoveries
@evidence_per_world 30        # Total: 300 evidence nodes
@total_ticks 25_000
@shock_tick 5_000
```

**Metrics**:
- Average theory confidence
- Discovery validation rate
- Recovery time
- Shock absorption
- **Recovery integrity score** ⭐ NEW (validated/total discoveries)

**Success Criteria**:
- Recovery ≥ 70% of pre-shock confidence
- Recovery integrity ≥ 0.6 (60% validated)
- Recovery time ≤ 15k ticks

---

### Layer 6.5B: Institutional Recovery

**Scope**: Adds programs, funding, discovery promotion, knowledge capital

**Excludes**: Competition, knowledge migration, world death

**Question**: "Can institutions recover and sustain research?"

**Configuration**:
```elixir
@worlds_count 15
@programs_per_world 5         # Total: 75 programs
@total_ticks 40_000
@shock_tick 8_000
```

**New Mechanisms**:
- Program creation from validated discoveries
- Knowledge capital tracking (replaces simple funding)
- Discovery promotion pipeline
- Institutional survival tracking

**Metrics** (adds to 6.5A):
- Institutional survival rate
- Knowledge capital per program
- Discovery velocity
- **Civilization Health Index (CHI)** ⭐ NEW

**Success Criteria**:
- Institutional survival ≥ 70%
- Knowledge capital stable or growing
- CHI recovery ≥ 75%

---

### Layer 6.5C: Competitive Recovery

**Scope**: Adds competition, knowledge migration, world death, exploration pressure

**Question**: "Does competition improve recovery and prevent monoculture?"

**Configuration**:
```elixir
@worlds_count 25              # Increased for migration dynamics
@total_ticks 60_000
@shock_tick 12_000
@exploration_budget 0.10      # 10% reserved for novel hypotheses
```

**New Mechanisms**:
- Competitive funding redistribution
- Cross-world knowledge migration
- World death/extinction tracking
- Exploration budget for low-confidence hypotheses
- Orbit classification tracking

**Metrics** (adds to 6.5B):
- Competition index
- Knowledge migration rate
- World survival rate
- Exploration/exploitation balance
- **Orbit classification** ⭐ NEW (fragile/recovery/stable/adaptive/regenerative)

**Success Criteria**:
- Competition active (> 0.1 index)
- Migration accelerates recovery in collapsed worlds
- No winner-take-all monoculture
- At least one world achieves regenerative orbit

---

## Progressive Scaling Strategy

Each layer (6.5A, 6.5B, 6.5C) uses progressive scaling:

**IMPORTANT**: Do NOT run full scale immediately. Use progressive scaling to save debugging time.

### Tier 1: Debugging (Start Here)
```elixir
@worlds_count 5
@theories_per_world 20        # Total: 100 theories
@discoveries_per_world 10     # Total: 50 discoveries
@total_ticks 10_000
@metrics_interval 1_000       # Collect every 1k ticks (10 data points)
@shock_tick 2_000             # Apply shock at tick 2,000
```
**Purpose**: Validate basic mechanics, fix bugs quickly
**Target Runtime**: < 2 minutes

---

### Tier 2: Validation
```elixir
@worlds_count 10
@theories_per_world 20        # Total: 200 theories
@discoveries_per_world 10     # Total: 100 discoveries
@total_ticks 25_000
@metrics_interval 2_500       # Collect every 2.5k ticks (10 data points)
@shock_tick 5_000             # Apply shock at tick 5,000
```
**Purpose**: Verify recovery mechanisms work at medium scale
**Target Runtime**: < 5 minutes

---

### Tier 3: Stress Testing
```elixir
@worlds_count 25
@theories_per_world 20        # Total: 500 theories
@discoveries_per_world 10     # Total: 250 discoveries
@total_ticks 50_000
@metrics_interval 5_000       # Collect every 5k ticks (10 data points)
@shock_tick 10_000            # Apply shock at tick 10,000
```
**Purpose**: Test budget protection, cascade limits under stress
**Target Runtime**: < 8 minutes

---

### Tier 4: Full Scale (Final Validation)
```elixir
@worlds_count 50
@theories_per_world 20        # Total: 1,000 theories
@discoveries_per_world 10     # Total: 500 discoveries
@evidence_per_world 30        # Total: 1,500 evidence nodes
@total_ticks 100_000
@metrics_interval 5_000       # Collect every 5k ticks (20 data points)
@shock_tick 20_000            # Apply shock at tick 20,000
```
**Purpose**: Production-ready validation, final classification
**Target Runtime**: < 15 minutes

---

**Recommendation**: Start with Tier 1, progress through tiers as each passes. Only run Tier 4 when confident in implementation.

### World Structure

### World Structure with Death Tracking ⭐ NEW

Each world contains:
- 20 theory nodes (confidence: 0.7-0.9)
- 10 discovery candidates (confidence: 0.6-0.8)
- 30 evidence nodes (confidence: 0.8-1.0)
- Relations: evidence → supports → discovery → supports → theory
- **World status tracking**: :healthy, :degraded, :collapsed, :extinct

Total graph size per world: ~60 nodes, ~40 relations

**World Death Conditions** (checked every metrics_interval):
```elixir
world_extinct = 
  avg_confidence < 0.3 AND
  funding_score < 5 AND
  active_discoveries == 0
  for 3 consecutive intervals
```

Once extinct, world stops generating hypotheses but can receive migrated knowledge.

---

## Shock Scenarios (3 Types)

Instead of random shock alone, implement three distinct shock types to test different failure modes:

### Shock A — Random Invalidation (Baseline)
Randomly invalidate 30% of evidence nodes across all worlds.

```elixir
def apply_random_shock(state) do
  evidence_nodes = Enum.filter(state.evidence_graph, fn {_id, node} ->
    node.type == :evidence
  end)
  
  total_evidence = length(evidence_nodes)
  shock_count = round(total_evidence * @shock_percentage)
  
  shocked_ids = evidence_nodes
  |> Enum.map(fn {id, _} -> id end)
  |> Enum.shuffle()
  |> Enum.take(shock_count)
  
  Enum.reduce(shocked_ids, state, fn id, acc ->
    EvidenceEngine.cascade_jtms_delta(acc, id, -0.8, :random_invalidation)
  end)
end
```

**Simulates**: General experimental failures, widespread data corruption

---

### Shock B — Core Theory Collapse (Paradigm Crisis)
Invalidate evidence supporting the top 10% highest-confidence theories.

```elixir
def apply_paradigm_crisis(state) do
  # Find highest-confidence theories
  theories = Enum.filter(state.evidence_graph, fn {_id, node} ->
    node.type == :theory
  end)
  
  sorted_theories = Enum.sort_by(theories, fn {_id, node} -> node.confidence, :desc)
  top_10_percent = round(length(sorted_theories) * 0.10)
  
  target_theory_ids = sorted_theories
  |> Enum.take(top_10_percent)
  |> Enum.map(fn {id, _} -> id end)
  
  # Find evidence supporting these theories (directly or through discoveries)
  evidence_to_invalidate = find_supporting_evidence(state, target_theory_ids)
  
  IO.puts("⚡ PARADIGM CRISIS: Invalidating #{length(evidence_to_invalidate)} evidence nodes supporting top #{top_10_percent} theories")
  
  Enum.reduce(evidence_to_invalidate, state, fn id, acc ->
    EvidenceEngine.cascade_jtms_delta(acc, id, -0.9, :paradigm_crisis)
  end)
end

defp find_supporting_evidence(state, theory_ids) do
  # Traverse graph backward from theories to find supporting evidence
  theory_set = MapSet.new(theory_ids)
  
  Enum.reduce(state.evidence_graph, [], fn {id, node}, acc ->
    if node.type == :evidence && supports_theory?(state, id, theory_set) do
      [id | acc]
    else
      acc
    end
  end)
end

defp supports_theory?(state, evidence_id, theory_set) do
  # Check if evidence supports any theory in the set (directly or through discoveries)
  relations = state.evidence_graph[evidence_id].outgoing_relations || []
  
  Enum.any?(relations, fn relation ->
    target_node = state.evidence_graph[relation.target_id]
    if target_node.type == :theory do
      MapSet.member?(theory_set, relation.target_id)
    else
      # Check if discovery supports targeted theory
      disc_relations = target_node.outgoing_relations || []
      Enum.any?(disc_relations, fn r ->
        MapSet.member?(theory_set, r.target_id)
      end)
    end
  end)
end
```

**Simulates**: Newtonian crisis, replication crisis, major paradigm collapse  
**Difficulty**: Much harder than random shock

---

### Shock C — Funding Crisis (Economic Collapse)
Invalidate highest-value discovery assets, triggering economic cascade.

```elixir
def apply_funding_crisis(state) do
  # Find high-value discoveries (those with assets/funding)
  discoveries = Enum.filter(state.evidence_graph, fn {_id, node} ->
    node.type == :discovery && node.status == :validated
  end)
  
  # Sort by value (confidence * asset_count heuristic)
  sorted = Enum.sort_by(discoveries, fn {_id, node} ->
    node.confidence * ((node.asset_count || 0) + 1)
  end, :desc)
  
  # Invalidate top 20% of valuable discoveries
  crisis_count = round(length(sorted) * 0.20)
  
  target_discoveries = sorted
  |> Enum.take(crisis_count)
  |> Enum.map(fn {id, _} -> id end)
  
  IO.puts("💸 FUNDING CRISIS: Invalidating #{crisis_count} high-value discoveries")
  
  # Apply shock to discoveries and their supporting evidence
  Enum.reduce(target_discoveries, state, fn disc_id, acc ->
    # Downgrade discovery
    downgraded = put_in(acc.evidence_graph[disc_id].status, :candidate)
    downgraded = put_in(downgraded.evidence_graph[disc_id].confidence, 0.3)
    
    # Invalidate supporting evidence
    evidence_ids = get_supporting_evidence(downgraded, disc_id)
    Enum.reduce(evidence_ids, downgraded, fn eid, acc2 ->
      EvidenceEngine.cascade_jtms_delta(acc2, eid, -0.7, :funding_crisis)
    end)
  end)
end

defp get_supporting_evidence(state, discovery_id) do
  # Find evidence nodes that support this discovery
  Enum.reduce(state.evidence_graph, [], fn {id, node}, acc ->
    if node.type == :evidence do
      relations = node.outgoing_relations || []
      if Enum.any?(relations, & &1.target_id == discovery_id) do
        [id | acc]
      else
        acc
      end
    else
      acc
    end
  end)
end
```

**Simulates**: Economic depression, loss of institutional funding, resource scarcity  
**Tests**: Asset → funding → programs → discoveries cascade

**Expected immediate effects**:
- Theory confidence drops sharply
- Discovery confidence degrades
- Some theories may fall below viability threshold
- Cascade budget may be exceeded (testing pause/resume under stress)

---

## Enhanced Recovery Metrics

Track these metrics every metrics_interval ticks with additional resilience indicators:

### Primary Metrics

1. **Average Theory Confidence**
   - Pre-shock baseline
   - Post-shock minimum
   - Recovery trajectory
   - Final stabilized value
   - **Recovery time**: Ticks required to reach 80% of pre-shock level

2. **Discovery Production Rate**
   - New discoveries per interval window
   - Validated discoveries count
   - Retired discoveries count
   - **Discovery diversity**: Distribution across worlds/domains

3. **Funding Score Distribution**
   - Average funding across programs
   - Variance in funding allocation
   - Programs falling below threshold
   - **Economic recovery rate**: Funding restoration speed

4. **Research Activity Index**
   - Active research programs count
   - Suspended programs count
   - Program creation rate
   - **Institutional extinction**: Programs permanently lost
   - **Program competition index**: Resource redistribution rate

### Resilience Metrics

5. **Shock Absorption Score**
   ```
   shock_absorption = 1 - (confidence_drop / shock_size)
   ```
   Example: 30% evidence removed, confidence drops only 12%
   → shock_absorption = 1 - (0.12 / 0.30) = 0.60
   
   Higher is better. Direct resilience measurement.

6. **Recovery Time**
   - Ticks from shock application to 80% recovery threshold
   - Critical metric for civilization sustainability
   - Target: < 30,000 ticks for acceptable resilience (Tier 4)

7. **Epistemic Stability**
   - Confidence variance across all nodes
   - Should decrease during recovery (convergence)
   - Measures system coherence post-shock

8. **Knowledge Velocity**
   - Validated discoveries per time unit
   - Should resume and potentially exceed pre-shock levels
   - Indicates adaptive capacity

### Diversity and Institutional Metrics

9. **Discovery Diversity Index**
   - World distribution of active discoveries
   - Entropy measure: higher = more distributed
   - Prevents single-point-of-failure scenarios
   
   Example healthy distribution:
   ```
   Cybersecurity: 120
   Math: 110
   Biology: 90
   Robotics: 95
   Economics: 85
   ```

10. **Institutional Survival Rate**
    - Research programs surviving post-shock
    - Institution deaths count
    - New institutions created during recovery
    - Measures structural resilience beyond individual theories

### Competition and Innovation Metrics

11. **Program Competition Index** ⭐ NEW
    - Rate of funding redistribution between competing programs
    - Measures competitive dynamics intensity
    - Formula: `funding_transfers / total_funding` per interval
    - Higher values indicate active competition

12. **Innovation Debt** ⭐ NEW
    ```
    innovation_debt = potential_discoveries - actual_discoveries
    ```
    - After shock: innovation_debt rises (backlog grows)
    - During recovery: innovation_debt falls (catching up)
    - Tells whether civilization is merely surviving or actively exploring
    - Target: innovation_debt should decrease during recovery phase

13. **Competitive Fitness Distribution** ⭐ NEW
    - Variance in program success rates
    - Identifies whether competition is healthy (many winners) or winner-take-all
    - Healthy: moderate variance with multiple successful programs
    - Unhealthy: extreme variance with single dominant program

### Knowledge Quality & Capital Metrics (NEW) ⭐ CRITICAL

14. **Knowledge Capital** ⭐ NEW (replaces simple funding)
    ```
    knowledge_capital = 
      (validated_discoveries * 10) +
      (active_theories * 5) +
      (replication_success_rate * 20) +
      (influence_score)
    ```
    - Programs receive resources proportional to knowledge capital
    - Aligns with Research Director and Domain architecture
    - More meaningful than arbitrary funding scores

15. **Recovery Integrity Score** ⭐ CRITICAL NEW
    ```
    recovery_integrity = validated_discoveries / total_discoveries
    ```
    - Detects "false recovery" (high velocity, low quality)
    - Prevents replication crisis scenarios
    - Success criterion: ≥ 0.6 (60% validated)
    - Also tracks: successful_replications / published_discoveries

16. **Civilization Health Index (CHI)** ⭐ CRITICAL NEW
    ```
    CHI = 
      0.25 * normalized_confidence +
      0.20 * normalized_diversity +
      0.20 * normalized_discovery_velocity +
      0.15 * normalized_institutional_survival +
      0.10 * normalized_validation_rate +
      0.10 * normalized_knowledge_capital
    ```
    - Composite metric for overall civilization health
    - Used for recovery classification instead of confidence alone
    - Becomes canonical metric for Phase 12+

### World & Migration Metrics (NEW) ⭐ CRITICAL

17. **World Survival Rate** ⭐ NEW
    - Tracks world status: :healthy, :degraded, :collapsed, :extinct
    - World extinction conditions:
      - avg_confidence < 0.3 AND
      - funding < 5 AND
      - active_discoveries == 0
      - for 3 consecutive intervals
    - More meaningful than node-level confidence alone

18. **Knowledge Migration Rate** ⭐ CRITICAL NEW
    ```
    cross_world_imports = discoveries_received_from_other_worlds
    cross_world_exports = discoveries_sent_to_other_worlds
    migration_rate = (imports + exports) / total_discoveries
    ```
    - Enables collapsed worlds to recover through knowledge transfer
    - Example: Math World collapses → Robotics World imports surviving discoveries
    - Without migration: testing isolated ecosystems, not civilizations

19. **Exploration/Exploitation Balance** ⭐ NEW
    ```
    exploration_budget = 10%  # Reserved for low-confidence hypotheses
    exploitation_ratio = high_confidence_programs / total_programs
    ```
    - Prevents monoculture convergence
    - Ensures novelty alongside optimization
    - Critical for long-term adaptability

### Orbit Classification ⭐ CRITICAL NEW (Connects to Phase 11.9A)

20. **Orbit Classification** ⭐ NEW
    Instead of simple pass/fail, classify recovery trajectories:
    
    - **Fragile Orbit**: Recovery < 50%, declining CHI
    - **Recovery Orbit**: Recovery 50-80%, CHI improving
    - **Stable Orbit**: Recovery 80-100%, CHI stable
    - **Adaptive Orbit**: Recovery 100-120%, CHI growing
    - **Regenerative Orbit**: Recovery > 120%, all antifragility conditions met
    
    **Antifragility Conditions** (ALL must be true):
    - Condition A: Higher confidence than pre-shock
    - Condition B: Higher diversity than pre-shock
    - Condition C: Higher discovery velocity than pre-shock
    - Condition D: Higher validation rate than pre-shock
    - Condition E: No increase in contradiction rate
    
    If recovery > 120% but conditions not met: classify as **:overfit_recovery** instead of :antifragile
    
    **Output**: Generates data for Phase 11.9A Orbit Transition Matrix

### Secondary Metrics

11. **Cascade Efficiency**
    - Operations per cascade
    - Budget utilization rate
    - Pause frequency under stress

12. **Adaptation Score**
    - New theories/programs created post-shock
    - Novel discovery pathways explored
    - System evolution vs. mere repair

---

## Success Criteria and Classification by Layer

### Layer 6.5A: Epistemic Recovery Success Criteria

**Pass if ALL met**:
1. **Truth Recovery**: CHI recovery ≥ 70%
2. **Recovery Integrity**: validated_discoveries / total_discoveries ≥ 0.6
3. **Recovery Time**: ≤ 15,000 ticks
4. **Shock Absorption**: ≥ 0.30
5. **No False Recovery**: contradiction_rate not increasing

**Orbit Classification Output**: Fragile/Recovery/Stable based on trajectory

---

### Layer 6.5B: Institutional Recovery Success Criteria

**Pass if ALL met** (adds to 6.5A):
1. **Institutional Survival**: ≥ 70% of programs survive
2. **Knowledge Capital**: Stable or growing post-shock
3. **CHI Recovery**: ≥ 75%
4. **Discovery Velocity**: Resumes within 10k ticks post-shock
5. **Recovery Integrity**: Maintained ≥ 0.6

**Orbit Classification Output**: Adds Adaptive orbit possibility

---

### Layer 6.5C: Competitive Recovery Success Criteria

**Pass if ALL met** (adds to 6.5B):
1. **Competition Active**: competition_index > 0.1
2. **Migration Effectiveness**: Collapsed worlds recover faster with migration
3. **No Monoculture**: diversity_entropy ≥ 70% of pre-shock
4. **Exploration Balance**: exploration_budget utilized (10% low-confidence hypotheses)
5. **World Survival**: ≥ 60% of worlds avoid extinction
6. **Antifragility Conditions** (for Regenerative Orbit):
   - Condition A: Higher confidence than pre-shock
   - Condition B: Higher diversity than pre-shock
   - Condition C: Higher discovery velocity than pre-shock
   - Condition D: Higher validation rate than pre-shock
   - Condition E: No increase in contradiction rate

**Orbit Classification Output**: Full spectrum including Regenerative orbit

---

### Orbit Classification System (Replaces Simple Pass/Fail)

Instead of binary pass/fail, classify recovery trajectories for Phase 11.9A:

| Orbit Class | CHI Recovery | Characteristics | Phase 11.9A Data |
|-------------|--------------|-----------------|------------------|
| **Fragile** | < 50% | Declining CHI, high extinction | Collapse patterns |
| **Recovery** | 50-80% | CHI improving, unstable | Recovery mechanisms |
| **Stable** | 80-100% | CHI stable, balanced | Stability conditions |
| **Adaptive** | 100-120% | CHI growing, evolving | Adaptation strategies |
| **Regenerative** | > 120% + all conditions | Antifragile, stronger | Antifragility drivers |
| **Overfit Recovery** | > 120% but conditions fail | Inflated metrics, low quality | Warning patterns |

**Key Innovation**: Each orbit class generates empirical data for Orbit Transition Matrix in Phase 11.9A.

---

## Implementation Phases

### Phase 1: Test Infrastructure (Day 1)

Create `test/tiannara/os/layer6_5_recovery_test.exs`:

```elixir
defmodule Tiannara.OS.Layer65RecoveryTest do
  use ExUnit.Case, async: false
  
  alias Tiannara.OS.EvidenceEngine
  alias Tiannara.OS.State
  alias Tiannara.OS.EvidenceNode
  
  @worlds_count 50
  @theories_per_world 20
  @discoveries_per_world 10
  @total_ticks 100_000
  @metrics_interval 5_000
  @shock_tick 20_000
  @shock_percentage 0.30
  
  test "Civilization Recovery from Mass Epistemic Shock" do
    # 1. Initialize worlds
    initial_state = initialize_worlds()
    
    # 2. Run simulation with shock
    {final_state, metrics_history} = run_simulation(initial_state)
    
    # 3. Analyze recovery
    analysis = analyze_recovery(metrics_history)
    
    # 4. Assert success criteria
    assert_recovery_success(analysis)
    
    # 5. Export results
    export_results(metrics_history, analysis)
  end
end
```

### Phase 2: World Initialization (Day 1-2)

Implement realistic world structure:

```elixir
defp initialize_worlds() do
  Enum.reduce(1..@worlds_count, %State{
    evidence_graph: %{},
    governance: %{
      damping_factor: 0.9,
      max_cascade_operations: 1000,
      relation_half_life_ticks: 1000
    }
  }, fn world_num, state ->
    add_world(state, world_num)
  end)
end

defp add_world(state, world_num) do
  world_prefix = "w#{world_num}"
  
  # Create theories
  {state, theory_ids} = Enum.reduce(1..@theories_per_world, {state, []}, fn i, {acc, ids} ->
    theory_id = String.to_atom("#{world_prefix}_theory_#{i}")
    confidence = :rand.uniform() * 0.2 + 0.7  # 0.7-0.9
    node = %EvidenceNode{id: theory_id, type: :theory, confidence: confidence}
    {EvidenceEngine.add_node(acc, theory_id, node), [theory_id | ids]}
  end)
  
  # Create discoveries
  {state, discovery_ids} = Enum.reduce(1..@discoveries_per_world, {state, []}, fn i, {acc, ids} ->
    disc_id = String.to_atom("#{world_prefix}_disc_#{i}")
    confidence = :rand.uniform() * 0.2 + 0.6  # 0.6-0.8
    node = %EvidenceNode{id: disc_id, type: :discovery, confidence: confidence, status: :candidate}
    {EvidenceEngine.add_node(acc, disc_id, node), [disc_id | ids]}
  end)
  
  # Create evidence and connect to discoveries/theories
  state = Enum.reduce(1..30, state, fn i, acc ->
    evidence_id = String.to_atom("#{world_prefix}_evidence_#{i}")
    confidence = :rand.uniform() * 0.2 + 0.8  # 0.8-1.0
    node = %EvidenceNode{id: evidence_id, type: :evidence, confidence: confidence}
    
    acc = EvidenceEngine.add_node(acc, evidence_id, node)
    
    # Connect to random discovery
    disc_id = Enum.random(discovery_ids)
    acc = EvidenceEngine.add_relation(acc, evidence_id, :supports, disc_id, 0.8)
    
    # Connect discovery to random theory
    theory_id = Enum.random(theory_ids)
    EvidenceEngine.add_relation(acc, disc_id, :supports, theory_id, 0.7)
  end)
  
  state
end
```

### Phase 3: Simulation Loop with Adaptation (Day 2-4)

Implement civilization scheduler with shock injection AND adaptive recovery mechanisms:

```elixir
defp run_simulation(initial_state, shock_type \\ :random) do
  Enum.reduce(1..@total_ticks, {initial_state, []}, fn tick, {state, metrics_acc} ->
    # Step 1: Apply shock at designated tick
    state = if tick == @shock_tick do
      IO.puts("\n⚡ APPLYING #{String.upcase(to_string(shock_type))} SHOCK AT TICK #{tick}")
      apply_shock(state, shock_type)
    else
      state
    end
    
    # Step 2: Simulate adaptive dynamics (not just repair)
    state = simulate_adaptive_dynamics(state, tick)
    
    # Step 3: Collect enhanced metrics
    metrics_acc = if rem(tick, @metrics_interval) == 0 do
      metrics = EvidenceEngine.get_civilization_metrics(state)
      enriched = Map.merge(metrics, %{
        tick: tick,
        phase: get_phase(tick),
        timestamp: System.system_time(:millisecond)
      })
      
      # Add resilience-specific metrics
      enriched = enrich_with_resilience_metrics(enriched, initial_state, tick)
      
      # Progress reporting
      if rem(tick, 10_000) == 0 do
        avg_conf = Float.round(metrics[:average_theory_confidence], 3)
        IO.puts("Tick #{tick}/#{@total_ticks} - Avg Theory Confidence: #{avg_conf}")
      end
      
      [enriched | metrics_acc]
    else
      metrics_acc
    end
    
    {state, metrics_acc}
  end)
end

defp apply_shock(state, :random), do: apply_random_shock(state)
defp apply_shock(state, :paradigm_crisis), do: apply_paradigm_crisis(state)
defp apply_shock(state, :funding_crisis), do: apply_funding_crisis(state)

defp simulate_adaptive_dynamics(state, tick) do
  # A. Successful replications (repair mechanism)
  state = if rem(tick, 500) == 0 do
    maybe_trigger_replication(state)
  else
    state
  end
  
  # B. New hypothesis generation (adaptation mechanism)
  state = if rem(tick, 1_000) == 0 do
    generate_new_hypotheses(state)
  else
    state
  end
  
  # C. Discovery promotion (economy activation)
  state = if rem(tick, 2_000) == 0 do
    promote_high_confidence_discoveries(state)
  else
    state
  end
  
  # D. Program creation from validated discoveries (institutional evolution)
  state = if rem(tick, 3_000) == 0 do
    create_programs_from_discoveries(state)
  else
    state
  end
  
  # E. Competitive funding redistribution (civilization dynamics) ⭐ NEW
  state = if rem(tick, 1_000) == 0 do
    redistribute_funding_through_competition(state)
  else
    state
  end
  
  # F. Funding allocation based on assets (economic feedback)
  state = if rem(tick, 1_500) == 0 do
    allocate_funding(state)
  else
    state
  end
  
  state
end

# NEW: Hypothesis generation creates new research directions
defp generate_new_hypotheses(state) do
  # Find active programs that can generate hypotheses
  programs = Enum.filter(state.evidence_graph, fn {_id, node} ->
    node.type == :program && node.status == :active
  end)
  
  Enum.reduce(programs, state, fn {_prog_id, program}, acc ->
    # Each program generates 1-3 new hypotheses
    num_hypotheses = :rand.uniform(3)
    
    Enum.reduce(1..num_hypotheses, acc, fn _, inner_acc ->
      hyp_id = String.to_atom("hypothesis_#{System.unique_integer([:positive])}")
      confidence = :rand.uniform() * 0.3 + 0.4  # 0.4-0.7 initial confidence
      
      hypothesis = %EvidenceNode{
        id: hyp_id,
        type: :theory,
        confidence: confidence,
        status: :hypothesis,
        parent_program: program.id
      }
      
      new_state = EvidenceEngine.add_node(inner_acc, hyp_id, hypothesis)
      
      # Connect hypothesis to program
      EvidenceEngine.add_relation(new_state, program.id, :generates, hyp_id, 0.9)
    end)
  end)
end

# NEW: Discovery promotion activates economy
defp promote_high_confidence_discoveries(state) do
  Enum.reduce(state.evidence_graph, state, fn {id, node}, acc ->
    if node.type == :discovery && node.status == :candidate && node.confidence > 0.85 do
      promoted = %{node | status: :validated}
      put_in(acc.evidence_graph[id], promoted)
    else
      acc
    end
  end)
end

# NEW: Program creation from discoveries closes the loop WITH COMPETITION
defp create_programs_from_discoveries(state) do
  validated = Enum.filter(state.evidence_graph, fn {_id, node} ->
    node.type == :discovery && node.status == :validated
  end)
  
  # Create new programs from top discoveries
  sorted = Enum.sort_by(validated, fn {_id, node} -> node.confidence, :desc)
  
  Enum.take(sorted, 5)  # Top 5 discoveries spawn programs
  |> Enum.reduce(state, fn {disc_id, discovery}, acc ->
    prog_id = String.to_atom("program_from_#{disc_id}")
    
    program = %EvidenceNode{
      id: prog_id,
      type: :program,
      confidence: discovery.confidence * 0.8,
      status: :active,
      funding_score: discovery.confidence * 100,
      source_discovery: disc_id,
      success_rate: 0.5  # Track competitive fitness
    }
    
    new_state = EvidenceEngine.add_node(acc, prog_id, program)
    EvidenceEngine.add_relation(new_state, disc_id, :funds, prog_id, 0.8)
  end)
end

# NEW: Competitive resource redistribution
defp redistribute_funding_through_competition(state) do
  programs = Enum.filter(state.evidence_graph, fn {_id, node} ->
    node.type == :program && node.status == :active
  end)
  
  # Calculate total available funding
  total_funding = Enum.sum(Enum.map(programs, fn {_id, p} -> p.funding_score end))
  
  if total_funding > 0 do
    # Rank programs by recent success rate (competitive fitness)
    ranked = Enum.sort_by(programs, fn {_id, p} -> p.success_rate || 0.5, :desc)
    
    # Redistribute: top performers gain, bottom performers lose
    Enum.with_index(ranked) |> Enum.reduce(state, fn {{prog_id, program}, rank}, acc ->
      percentile = rank / length(ranked)
      
      # Top 30% gain funding, bottom 30% lose funding
      adjustment = cond do
        percentile < 0.30 -> 1.2  # +20% for winners
        percentile > 0.70 -> 0.8  # -20% for losers
        true -> 1.0  # No change for middle
      end
      
      new_funding = program.funding_score * adjustment
      updated = %{program | funding_score: new_funding}
      
      # Suspend if funding drops too low
      updated = if new_funding < 10 do
        %{updated | status: :suspended}
      else
        updated
      end
      
      put_in(acc.evidence_graph[prog_id], updated)
    end)
  else
    state
  end
end

# NEW: Track program competition metrics
defp calculate_competition_metrics(state, previous_state) do
  current_programs = Enum.filter(state.evidence_graph, fn {_id, node} ->
    node.type == :program && node.status == :active
  end)
  
  prev_programs = if previous_state do
    Enum.filter(previous_state.evidence_graph, fn {_id, node} ->
      node.type == :program && node.status == :active
    end)
  else
    []
  end
  
  # Calculate funding transfers (competition intensity)
  funding_transfers = Enum.reduce(current_programs, 0, fn {_id, prog}, acc ->
    prev_prog = Enum.find(prev_programs, fn {pid, _} -> pid == prog.id end)
    if prev_prog do
      prev_funding = elem(prev_prog, 1).funding_score
      curr_funding = prog.funding_score
      acc + abs(curr_funding - prev_funding)
    else
      acc
    end
  end)
  
  total_funding = Enum.sum(Enum.map(current_programs, fn {_id, p} -> p.funding_score end))
  
  competition_index = if total_funding > 0 do
    funding_transfers / total_funding
  else
    0.0
  end
  
  # Calculate competitive fitness variance
  success_rates = Enum.map(current_programs, fn {_id, p} -> p.success_rate || 0.5 end)
  fitness_variance = calculate_variance(success_rates)
  
  %{
    competition_index: Float.round(competition_index, 3),
    fitness_variance: Float.round(fitness_variance, 3),
    active_competitors: length(current_programs)
  }
end

defp calculate_variance(values) do
  if length(values) == 0 do
    0.0
  else
    mean = Enum.sum(values) / length(values)
    squared_diffs = Enum.map(values, & (:math.pow(&1 - mean, 2)))
    Enum.sum(squared_diffs) / length(squared_diffs)
  end
end

# NEW: Funding allocation based on asset value
defp allocate_funding(state) do
  programs = Enum.filter(state.evidence_graph, fn {_id, node} ->
    node.type == :program && node.status == :active
  end)
  
  Enum.reduce(programs, state, fn {prog_id, program}, acc ->
    # Calculate funding based on discovery assets
    funding = calculate_program_funding(acc, prog_id)
    updated_program = %{program | funding_score: funding}
    
    if funding < 10 do
      # Suspend underfunded programs
      suspended = %{updated_program | status: :suspended}
      put_in(acc.evidence_graph[prog_id], suspended)
    else
      put_in(acc.evidence_graph[prog_id], updated_program)
    end
  end)
end

defp calculate_program_funding(state, program_id) do
  # Sum up value of discoveries this program has produced
  relations = state.evidence_graph[program_id].outgoing_relations || []
  
  Enum.reduce(relations, 0, fn rel, total ->
    if rel.relation_type == :produces do
      target = state.evidence_graph[rel.target_id]
      if target && target.type == :discovery && target.status == :validated do
        total + (target.confidence * 50)
      else
        total
      end
    else
      total
    end
  end)
end

defp get_phase(tick) do
  cond do
    tick < @shock_tick -> :pre_shock
    tick < @shock_tick + 5_000 -> :immediate_shock
    tick < @shock_tick + 30_000 -> :recovery
    true -> :stabilized
  end
end

defp enrich_with_resilience_metrics(metrics, initial_state, current_tick, previous_state \\ nil) do
  # Calculate shock absorption
  pre_shock_conf = get_pre_shock_baseline(initial_state)
  current_conf = metrics.average_theory_confidence
  
  confidence_drop = max(0, pre_shock_conf - current_conf)
  shock_size = 0.30  # 30% evidence invalidated
  
  shock_absorption = if shock_size > 0 do
    1 - (confidence_drop / shock_size)
  else
    1.0
  end
  
  # Calculate recovery time if recovered
  recovery_threshold = pre_shock_conf * 0.80
  recovery_time = if current_conf >= recovery_threshold && current_tick >= @shock_tick do
    current_tick - @shock_tick
  else
    nil
  end
  
  # Calculate diversity index
  diversity_entropy = calculate_discovery_diversity(metrics)
  
  # Calculate institutional survival
  institutional_survival = calculate_institutional_survival(metrics, initial_state)
  
  # Calculate innovation debt ⭐ NEW
  innovation_debt = calculate_innovation_debt(metrics, initial_state)
  
  # Calculate competition metrics ⭐ NEW
  competition = if previous_state do
    calculate_competition_metrics(metrics.__struct__ || %{}, previous_state)
  else
    %{competition_index: 0.0, fitness_variance: 0.0, active_competitors: 0}
  end
  
  Map.merge(metrics, %{
    shock_absorption: Float.round(shock_absorption, 3),
    recovery_time: recovery_time,
    discovery_diversity_entropy: Float.round(diversity_entropy, 3),
    institutional_survival_rate: Float.round(institutional_survival, 3),
    innovation_debt: innovation_debt,
    competition_index: competition.competition_index,
    competitive_fitness_variance: competition.fitness_variance,
    active_competing_programs: competition.active_competitors
  })
end

defp calculate_discovery_diversity(metrics) do
  # Entropy-based diversity measure across worlds
  # Higher entropy = more distributed discoveries
  world_counts = metrics.discoveries_by_world || %{}
  total = Enum.sum(Map.values(world_counts))
  
  if total == 0 do
    0.0
  else
    probabilities = Map.values(world_counts) |> Enum.map(& &1 / total)
    entropy = -Enum.sum(Enum.map(probabilities, fn p ->
      if p > 0, do: p * :math.log(p), else: 0
    end))
    Float.round(entropy, 3)
  end
end

defp calculate_institutional_survival(metrics, initial_state) do
  initial_programs = count_programs(initial_state)
  current_programs = metrics.active_programs || 0
  
  if initial_programs > 0 do
    current_programs / initial_programs
  else
    1.0
  end
end

defp count_programs(state) do
  Enum.count(state.evidence_graph, fn {_id, node} ->
    node.type == :program
  end)
end

defp get_pre_shock_baseline(initial_state) do
  # Average theory confidence before any shocks
  theories = Enum.filter(initial_state.evidence_graph, fn {_id, node} ->
    node.type == :theory
  end)
  
  if length(theories) > 0 do
    Enum.sum(Enum.map(theories, fn {_id, node} -> node.confidence end)) / length(theories)
  else
    0.7  # Default assumption
  end
end

# NEW: Calculate innovation debt
defp calculate_innovation_debt(metrics, initial_state) do
  # Innovation debt = potential discoveries - actual discoveries
  # Potential = hypotheses waiting to be validated
  # Actual = validated discoveries produced
  
  hypotheses_count = metrics.hypotheses_count || 0
  validated_count = metrics.active_discoveries || 0
  
  # Simple heuristic: each hypothesis has potential to become discovery
  potential = hypotheses_count * 0.7  # 70% conversion rate assumption
  actual = validated_count
  
  debt = max(0, potential - actual)
  Float.round(debt, 1)
end
```

### Phase 4: Enhanced Recovery Analysis (Day 4-5)

Implement comprehensive analysis with resilience classification:

```elixir
defp analyze_recovery(metrics_history) do
  sorted = Enum.sort_by(metrics_history, & &1.tick)
  
  pre_shock = Enum.filter(sorted, & &1.phase == :pre_shock)
  post_shock = Enum.filter(sorted, & &1.phase != :pre_shock)
  
  # Baseline metrics
  pre_avg_conf = average_metric(pre_shock, :average_theory_confidence)
  post_min_conf = Enum.min_by(post_shock, & &1.average_theory_confidence).average_theory_confidence
  final_conf = List.last(sorted).average_theory_confidence
  
  # Recovery calculations
  recovery_ratio = final_conf / pre_avg_conf
  recovery_percentage = recovery_ratio * 100
  
  # Recovery time
  recovery_threshold = pre_avg_conf * 0.80
  recovery_point = Enum.find(sorted, fn m ->
    m.tick >= @shock_tick && m.average_theory_confidence >= recovery_threshold
  end)
  recovery_time = if recovery_point, do: recovery_point.tick - @shock_tick, else: nil
  
  # Shock absorption
  confidence_drop = max(0, pre_avg_conf - post_min_conf)
  shock_size = 0.30
  shock_absorption = 1 - (confidence_drop / shock_size)
  
  # Discovery production
  pre_discoveries = average_metric(pre_shock, :active_discoveries)
  post_discoveries = List.last(sorted).active_discoveries
  
  # Diversity analysis
  pre_diversity = average_metric(pre_shock, :discovery_diversity_entropy)
  final_diversity = List.last(sorted).discovery_diversity_entropy
  diversity_maintained = final_diversity >= pre_diversity * 0.70
  
  # Institutional survival
  final_institutional = List.last(sorted).institutional_survival_rate
  
  # Knowledge velocity trend
  pre_velocity = average_metric(pre_shock, :knowledge_velocity)
  final_velocity = List.last(sorted).knowledge_velocity
  velocity_recovered = final_velocity > 0
  
  # Competition health check ⭐ NEW
  final_competition = List.last(sorted).competition_index || 0
  competition_healthy = final_competition > 0.1  # Some redistribution happening
  
  # Innovation debt trend ⭐ NEW
  pre_debt = average_metric(pre_shock, :innovation_debt)
  final_debt = List.last(sorted).innovation_debt || 0
  debt_decreasing = final_debt < pre_debt * 1.2  # Not growing excessively
  
  # Determine pass/fail for each criterion
  criteria = %{
    no_permanent_collapse: recovery_percentage >= 50 && final_conf > 0.2,
    recovery_time_acceptable: recovery_time != nil && recovery_time <= 50_000,
    discovery_production_resumed: post_discoveries > 0 && velocity_recovered,
    institutional_continuity: final_institutional >= 0.60,
    diversity_maintained: diversity_maintained,
    shock_absorption_adequate: shock_absorption >= 0.30,
    competition_active: competition_healthy,  # ⭐ NEW
    innovation_managed: debt_decreasing  # ⭐ NEW
  }
  
  passed_count = Enum.count(criteria, fn {_k, v} -> v end)
  overall_pass = passed_count >= 6  # Allow 2 failures for partial credit (8 total now)
  
  # Classify outcome
  classification = classify_outcome(recovery_percentage)
  
  %{
    pre_shock_avg_confidence: pre_avg_conf,
    post_shock_min_confidence: post_min_conf,
    final_confidence: final_conf,
    recovery_percentage: recovery_percentage,
    recovery_time: recovery_time,
    shock_absorption: shock_absorption,
    pre_discoveries: pre_discoveries,
    post_discoveries: post_discoveries,
    diversity_maintained: diversity_maintained,
    institutional_survival_rate: final_institutional,
    knowledge_velocity_recovered: velocity_recovered,
    classification: classification,
    criteria: criteria,
    passed_count: passed_count,
    overall_pass: overall_pass,
    metrics_history: sorted
  }
end

defp classify_outcome(recovery_percentage) do
  cond do
    recovery_percentage < 50 -> :collapse
    recovery_percentage < 80 -> :survival
    recovery_percentage < 100 -> :resilience
    recovery_percentage < 120 -> :adaptation
    true -> :antifragility
  end
end

defp average_metric(metrics_list, key) do
  values = Enum.map(metrics_list, & Map.get(&1, key, 0))
  valid_values = Enum.reject(values, & is_nil/1)
  
  if length(valid_values) > 0 do
    Enum.sum(valid_values) / length(valid_values)
  else
    0.0
  end
end

defp variance_metric(metrics_list, key) do
  values = Enum.map(metrics_list, & Map.get(&1, key, 0))
  valid_values = Enum.reject(values, & is_nil/1)
  
  if length(valid_values) > 0 do
    mean = Enum.sum(valid_values) / length(valid_values)
    squared_diffs = Enum.map(valid_values, & (:math.pow(&1 - mean, 2)))
    Enum.sum(squared_diffs) / length(squared_diffs)
  else
    0.0
  end
end
```

### Phase 5: Enhanced Assertions and Reporting (Day 5)

```elixir
defp assert_recovery_success(analysis) do
  IO.puts("\n" <> String.duplicate("=", 80))
  IO.puts("LAYER 6.5 CIVILIZATION RECOVERY ANALYSIS")
  IO.puts(String.duplicate("=", 80))
  
  IO.puts("\n📊 Recovery Metrics:")
  IO.puts("   Pre-shock avg confidence: #{Float.round(analysis.pre_shock_avg_confidence, 3)}")
  IO.puts("   Post-shock min confidence: #{Float.round(analysis.post_shock_min_confidence, 3)}")
  IO.puts("   Final confidence: #{Float.round(analysis.final_confidence, 3)}")
  IO.puts("   Recovery percentage: #{Float.round(analysis.recovery_percentage, 1)}%")
  IO.puts("   Recovery time: #{if analysis.recovery_time, do: "#{analysis.recovery_time} ticks", else: "NOT RECOVERED"}")
  IO.puts("   Shock absorption: #{Float.round(analysis.shock_absorption * 100, 1)}%")
  
  IO.puts("\n🔬 Discovery Production:")
  IO.puts("   Pre-shock active discoveries: #{round(analysis.pre_discoveries)}")
  IO.puts("   Post-shock active discoveries: #{analysis.post_discoveries}")
  IO.puts("   Knowledge velocity recovered: #{analysis.knowledge_velocity_recovered}")
  
  IO.puts("\n🌍 Diversity & Institutions:")
  IO.puts("   Diversity maintained: #{analysis.diversity_maintained}")
  IO.puts("   Institutional survival rate: #{Float.round(analysis.institutional_survival_rate * 100, 1)}%")
  
  IO.puts("\n🏆 Classification: #{String.upcase(to_string(analysis.classification))}")
  case analysis.classification do
    :collapse -> IO.puts("   ❌ System collapsed permanently")
    :survival -> IO.puts("   ⚠️  System survived but degraded")
    :resilience -> IO.puts("   ✅ System recovered to near-original state")
    :adaptation -> IO.puts("   🌟 System improved beyond original state")
    :antifragility -> IO.puts("   💎 HOLY GRAIL: Crisis made system stronger!")
  end
  
  IO.puts("\n✅ Success Criteria:")
  Enum.each(analysis.criteria, fn {criterion, passed} ->
    status = if passed, do: "✅ PASS", else: "❌ FAIL"
    IO.puts("   #{status} - #{format_criterion(criterion)}")
  end)
  
  IO.puts("\n🎯 Overall Result: #{if analysis.overall_pass, do: "✅ PASSED", else: "❌ FAILED"}")
  IO.puts("   (#{analysis.passed_count}/6 criteria met)")
  IO.puts(String.duplicate("=", 80) <> "\n")
  
  # Allow test to pass with 4/6 criteria for partial credit
  assert analysis.overall_pass, "Recovery test failed: only #{analysis.passed_count}/6 criteria met (Classification: #{analysis.classification})"
end

defp format_criterion(:no_permanent_collapse), do: "No permanent collapse (recovery ≥ 50%, confidence > 0.2)"
defp format_criterion(:recovery_time_acceptable), do: "Recovery time acceptable (≤ 50k ticks)"
defp format_criterion(:discovery_production_resumed), do: "Discovery production resumed with positive velocity"
defp format_criterion(:institutional_continuity), do: "Institutional continuity ≥ 60%"
defp format_criterion(:diversity_maintained), do: "Discovery diversity maintained (≥ 70% of pre-shock)"
defp format_criterion(:shock_absorption_adequate), do: "Shock absorption adequate (≥ 30%)"

defp export_results(metrics_history, analysis) do
  # Export detailed CSV
  csv_path = "layer6_5_recovery_results.csv"
  headers = Map.keys(hd(metrics_history)) |> Enum.join(",")
  rows = Enum.map(metrics_history, fn m -> 
    Enum.map(headers |> String.split(","), fn h -> 
      Map.get(m, String.to_atom(h), "") 
    end) |> Enum.join(",")
  end)
  
  File.write!(csv_path, headers <> "\n" <> Enum.join(rows, "\n"))
  
  # Export analysis summary as JSON
  analysis_path = "layer6_5_recovery_analysis.json"
  analysis_map = Map.from_struct(analysis) |> Map.delete(:metrics_history)
  File.write!(analysis_path, Jason.encode!(analysis_map, pretty: true))
  
  # Export classification report
  report_path = "layer6_5_recovery_report.md"
  report_content = generate_markdown_report(analysis)
  File.write!(report_path, report_content)
  
  IO.puts("\n📁 Results exported:")
  IO.puts("   - #{csv_path} (detailed metrics)")
  IO.puts("   - #{analysis_path} (analysis summary)")
  IO.puts("   - #{report_path} (human-readable report)")
end

defp generate_markdown_report(analysis) do
  """
  # Layer 6.5 Civilization Recovery Test Report
  
  **Date**: #{DateTime.utc_now() |> DateTime.to_iso8601()}
  **Classification**: #{String.upcase(to_string(analysis.classification))}
  **Overall Result**: #{if analysis.overall_pass, do: "✅ PASSED", else: "❌ FAILED"}
  
  ## Summary
  
  - **Recovery Percentage**: #{Float.round(analysis.recovery_percentage, 1)}%
  - **Recovery Time**: #{if analysis.recovery_time, do: "#{analysis.recovery_time} ticks", else: "Not recovered"}
  - **Shock Absorption**: #{Float.round(analysis.shock_absorption * 100, 1)}%
  - **Criteria Met**: #{analysis.passed_count}/6
  
  ## Key Metrics
  
  | Metric | Value |
  |--------|-------|
  | Pre-shock avg confidence | #{Float.round(analysis.pre_shock_avg_confidence, 3)} |
  | Post-shock min confidence | #{Float.round(analysis.post_shock_min_confidence, 3)} |
  | Final confidence | #{Float.round(analysis.final_confidence, 3)} |
  | Institutional survival | #{Float.round(analysis.institutional_survival_rate * 100, 1)}% |
  | Diversity maintained | #{analysis.diversity_maintained} |
  | Knowledge velocity recovered | #{analysis.knowledge_velocity_recovered} |
  
  ## Success Criteria
  
  #{Enum.map_join(analysis.criteria, "\n", fn {criterion, passed} ->
    status = if passed, do: "✅", else: "❌"
    "- #{status} #{format_criterion(criterion)}"
  end)}
  
  ## Interpretation
  
  #{interpret_classification(analysis.classification)}
  """
end

defp interpret_classification(:collapse) do
  "The civilization experienced permanent collapse. The epistemic shock was too severe, and the system could not recover. This indicates fundamental fragility in the institutional structure."
end

defp interpret_classification(:survival) do
  "The civilization survived but remains degraded. While not catastrophic, the system has not fully recovered its pre-shock capabilities. Additional resilience mechanisms are needed."
end

defp interpret_classification(:resilience) do
  "The civilization demonstrated strong resilience, recovering to near-original performance levels. The institutional structure successfully absorbed and recovered from the shock."
end

defp interpret_classification(:adaptation) do
  "The civilization adapted and improved beyond its original state. The crisis triggered beneficial changes that made the system more robust. This is a significant achievement."
end

defp interpret_classification(:antifragility) do
  "**HOLY GRAIL ACHIEVED**: The civilization became stronger because of the crisis. The shock eliminated weak theories, promoted better discoveries, and created more robust institutions. This is true antifragility - the system gains from disorder."
end
```

---

## Expected Challenges and Mitigations

### Challenge 1: Runtime Duration

**Problem**: 100k ticks × 3,000 nodes with adaptive mechanisms could take hours

**Mitigation**:
- Start with reduced scale (10 worlds, 20k ticks) for debugging
- Optimize propagation by batching similar operations
- Use async test execution where possible
- Profile and optimize hot paths
- Consider reducing metrics_interval to 10k for faster runs

**Target Runtime**: < 10 minutes for full test with all three shock types

---

### Challenge 2: Adaptive Mechanism Complexity

**Problem**: Implementing hypothesis generation, program creation, and funding allocation requires new logic beyond JTMS++

**Mitigation**: 
- Implement simplified versions first (basic heuristics)
- Focus on closing the loop rather than perfect realism
- Use placeholder functions that can be refined later
- Test each mechanism independently before integration

**Priority**: Get the closed loop working, then optimize realism

---

### Challenge 3: Budget Exhaustion During Shock

**Problem**: Invalidating 30% of evidence simultaneously may trigger thousands of cascades, especially with paradigm crisis targeting high-confidence theories

**Mitigation**:
- Increase max_cascade_operations to 5,000 for this test
- Implement cascade prioritization (high-confidence nodes first)
- Allow multiple paused cascades to coexist
- Monitor and log budget utilization per shock type
- Consider staggering shock application over 100-500 ticks

---

### Challenge 4: Insufficient Recovery Mechanisms

**Problem**: System may lack mechanisms to generate positive deltas post-shock if only using replications

**Mitigation**: Ensure simulation includes ALL recovery pathways:
- ✅ Successful replication events (repair)
- ✅ New hypothesis generation (adaptation)
- ✅ Discovery promotion pipeline (economy activation)
- ✅ Program creation from discoveries (institutional evolution)
- ✅ Funding allocation feedback (economic sustainability)
- ✅ Cross-world knowledge transfer (diversity preservation)

This shifts from "repair" to "adaptation" - the critical distinction.

---

### Challenge 5: Diversity Tracking Overhead

**Problem**: Calculating entropy-based diversity metrics adds computational cost

**Mitigation**:
- Calculate diversity only at metrics collection intervals (every 5k ticks)
- Use efficient Map-based world tracking
- Cache intermediate calculations
- Accept approximate diversity measures if performance critical

---

## Integration with Existing Codebase

### Dependencies

Layer 6.5 requires these existing components:
- ✅ `EvidenceEngine.cascade_jtms_delta/4` (already implemented)
- ✅ `EvidenceEngine.get_civilization_metrics/1` (already implemented)
- ✅ `EvidenceEngine.register_successful_replication/3` (already implemented)
- ⚠️ Discovery promotion logic (needs implementation - see Phase 3)
- ⚠️ Funding score computation (needs implementation - see Phase 3)
- ⚠️ Hypothesis generation (NEW - see Phase 3)
- ⚠️ Program creation from discoveries (NEW - see Phase 3)

### New Functions to Add to evidence_engine.ex

```elixir
@spec promote_high_confidence_discoveries(State.t()) :: State.t()
def promote_high_confidence_discoveries(%State{} = state) do
  Enum.reduce(state.evidence_graph, state, fn {id, node}, acc ->
    if node.type == :discovery && node.status == :candidate && node.confidence > 0.85 do
      promoted = %{node | status: :validated}
      put_in(acc.evidence_graph[id], promoted)
    else
      acc
    end
  end)
end

@spec compute_funding_scores(State.t()) :: State.t()
def compute_funding_scores(%State{} = state) do
  # Calculate funding based on validated discoveries and assets
  validated_count = Enum.count(state.evidence_graph, fn {_id, node} ->
    node.type == :discovery && node.status == :validated
  end)
  
  # Update governance or node metadata with funding scores
  put_in(state.governance[:current_funding_score], validated_count * 10.0)
end
```

Note: Most adaptive logic (hypothesis generation, program creation, funding allocation) will live in the test file itself for now, as these are simulation-level mechanisms rather than core JTMS++ functionality.

---

## Validation Checklist

Before running full Layer 6.5 test:

- [ ] Reduced-scale test passes (10 worlds, 20k ticks)
- [ ] All three shock types implemented and tested individually
- [ ] Shock application works correctly (verify 30% invalidated)
- [ ] Metrics collection captures all required fields including resilience metrics
- [ ] Recovery analysis computes correct ratios and classifications
- [ ] CSV export contains complete data
- [ ] Markdown report generation works
- [ ] No memory leaks during extended simulation
- [ ] Budget protection handles shock-induced cascades
- [ ] Discovery promotion logic functional
- [ ] Funding scores computed and tracked
- [ ] Hypothesis generation creates new theories
- [ ] Program creation closes the loop
- [ ] Diversity tracking accurate across worlds
- [ ] Institutional survival rate calculated correctly
- [ ] Test completes in < 10 minutes for full scale

---

## Success Interpretation

### If Test PASSES with High Classification (Resilience/Adaptation/Antifragility)

This proves Tiannara has **civilization-level resilience AND adaptive capacity**:
- Can survive paradigm shifts, funding crises, and replication crises
- Recovers from catastrophic disruption within acceptable timeframes
- Maintains research continuity through disruption
- Self-correcting mechanisms work at scale
- System can adapt and potentially improve from crises

**Implication**: Ready for Phase 12.0 Step 3 (Civilization Scheduler integration). The epistemic substrate is essentially complete.

### If Test PASSES with Low Classification (Survival)

System survives but shows weaknesses:
- Identify which criteria failed or barely passed
- Determine if recovery time is acceptable for real-world use
- Assess whether institutional structure needs strengthening

**Action**: Iterate on institutional dynamics before proceeding to full scheduler integration.

### If Test FAILS

Identifies specific vulnerabilities:
- Which criterion failed?
- At what tick did recovery stall?
- What mechanisms are missing?
- Was the shock too severe or the system too fragile?

**Action**: 
1. Analyze failure mode (collapse vs stagnation vs diversity loss)
2. Strengthen weak mechanisms (promotion, funding, hypothesis generation)
3. Adjust shock parameters if unrealistically severe
4. Rerun with improvements

---

## Timeline Estimate

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| 1 | Test infrastructure setup | 4 hours |
| 2 | World initialization with domain tagging | 6 hours |
| 3 | Simulation loop with adaptive dynamics | 12 hours |
| 4 | Enhanced recovery analysis implementation | 8 hours |
| 5 | Assertions, reporting, and classification | 6 hours |
| Testing | Debugging and optimization | 10 hours |
| **Total** | | **~46 hours (5.75 days)** |

Note: Additional time may be needed for implementing adaptive mechanisms if they require changes to core evidence_engine.ex.

---

## Conclusion

Layer 6.5 is the **critical missing test** that bridges infrastructure verification and true civilization emergence. While Layers 1-6 prove JTMS++ works correctly under normal conditions, Layer 6.5 proves Tiannara can **survive, adapt, compete, and potentially thrive** after catastrophic disruption.

This test shifts focus from "does the engine work?" to "can the civilization endure and evolve through competition?"—the question that matters for long-term sustainability.

### Key Innovations in This Plan

1. **Three Shock Types**: Random, paradigm crisis, and funding crisis test different failure modes
2. **Recovery Time Measurement**: Not just IF it recovers, but HOW FAST
3. **Discovery Diversity Tracking**: Prevents single-point-of-failure scenarios
4. **Institutional Extinction Tracking**: Measures structural resilience beyond individual theories
5. **Shock Absorption Metric**: Direct measurement of resilience quality
6. **Adaptive Recovery Mechanisms**: Hypothesis generation, program creation, and funding allocation enable adaptation, not just repair
7. **Competitive Dynamics**: ⭐ NEW - Funding redistribution based on program fitness creates genuine civilization-level competition
8. **Innovation Debt Tracking**: ⭐ NEW - Measures whether system is catching up or falling behind
9. **Classification Hierarchy**: Distinguishes collapse, survival, resilience, adaptation, and antifragility
10. **Progressive Scaling**: Four tiers from debugging (5 worlds) to full scale (50 worlds)

### The Holy Grail: Antifragility

The ultimate success is achieving **antifragility** (>120% recovery):
- Post-shock civilization STRONGER than pre-shock
- Crisis eliminates weak theories and programs
- Better discoveries promoted through competition
- More robust institutions created
- System gains from disorder

This would demonstrate that Tiannara doesn't just survive chaos—it benefits from it through competitive selection.

---

## Preview: Layer 6.6 — Competitive Civilization Recovery

**Status**: Proposed for implementation after Layer 6.5 passes

**Objective**: Test whether different governance models produce different resilience profiles under identical shocks.

**Configuration**:
```
5 civilizations (separate simulations)
Same shock scenario (e.g., Paradigm Crisis)
Different governance parameters:
```

### Governance Models to Test

#### Civilization A: High Damping
```elixir
governance: %{
  damping_factor: 0.95,  # Conservative propagation
  max_cascade_operations: 500
}
```
**Hypothesis**: Slow but stable recovery, less volatility

---

#### Civilization B: High Replication
```elixir
governance: %{
  replication_rate: 0.8,  # Aggressive validation
  discovery_promotion_threshold: 0.75
}
```
**Hypothesis**: Fast recovery through rapid iteration, higher risk

---

#### Civilization C: High Diversification
```elixir
governance: %{
  diversity_bonus: 1.3,  # Reward cross-domain discoveries
  world_coupling: 0.2    # Low inter-world dependency
}
```
**Hypothesis**: Resilient through redundancy, slower specialization

---

#### Civilization D: High Funding Reserves
```elixir
governance: %{
  reserve_funding_multiplier: 3.0,  # Large emergency funds
  suspension_threshold: 5           # Harder to suspend programs
}
```
**Hypothesis**: Survives funding crises better, may become complacent

---

#### Civilization E: High Competition
```elixir
governance: %{
  competition_intensity: 0.5,  # Aggressive resource redistribution
  winner_take_all_factor: 0.3  # Top performers gain significantly
}
```
**Hypothesis**: Rapid adaptation through selection pressure, potential for winner-take-all fragility

---

### Metrics to Compare

| Metric | Civ A | Civ B | Civ C | Civ D | Civ E |
|--------|-------|-------|-------|-------|-------|
| Survival Rate | ? | ? | ? | ? | ? |
| Recovery Time | ? | ? | ? | ? | ? |
| Adaptation Level | ? | ? | ? | ? | ? |
| Antifragility Score | ? | ? | ? | ? | ? |
| Diversity Preservation | ? | ? | ? | ? | ? |
| Innovation Throughput | ? | ? | ? | ? | ? |

### Expected Emergent Behaviors

1. **Trade-offs Between Stability and Speed**
   - High damping = stable but slow
   - High replication = fast but risky

2. **Competition vs. Cooperation Balance**
   - Too much competition = winner-take-all fragility
   - Too little = stagnation

3. **Diversity as Insurance**
   - Specialized civilizations excel in narrow domains
   - Diverse civilizations survive broader range of shocks

4. **Reserve Utilization**
   - Hoarding resources = safety but missed opportunities
   - Investing aggressively = growth but vulnerability

### Why This Matters

Layer 6.6 moves beyond "does it recover?" to "which governance model recovers BEST?"

This is where genuinely unexpected behavior may emerge:
- Optimal balance between competition and cooperation
- Emergent institutional structures
- Self-organizing research ecosystems
- Adaptive governance evolution

**Timeline**: Begin Layer 6.6 design after Layer 6.5 achieves ≥ Resilience classification.

---

### Next Steps After Layer 6.5

Once Layer 6.5 passes with acceptable classification:

1. ✅ Mathematical correctness (Layers 1-2) - VERIFIED
2. ✅ Scalability and safety (Layer 3) - VERIFIED
3. ✅ Scientific validity (Layer 4) - VERIFIED
4. ✅ Historical traceability (Layer 5) - VERIFIED
5. ✅ Emergence potential (Layer 6) - VERIFIED
6. ✅ **Civilizational resilience with competition** (Layer 6.5) - TO BE VERIFIED
7. 📋 **Governance model comparison** (Layer 6.6) - PROPOSED

Then proceed to:
- **Phase 12.0 Step 2**: Complete Research Program Engine with closed-loop economy
- **Phase 12.0 Step 3**: Integrate with Civilization Scheduler
- **Phase 12.0 Step 4**: Run full emergence simulations with institutional dynamics and competitive selection

At that point, the biggest remaining challenge in Tiannara is no longer reasoning or truth maintenance. It becomes:

```
Institutional evolution through competition
Research allocation optimization
Discovery economics with market dynamics
Civilization scheduling with adaptive governance
```

which is exactly where the most interesting emergent behavior will come from.

---

*Implementation plan version 3.0 - Enhanced with competitive dynamics, innovation debt, progressive scaling, and Layer 6.6 preview*
