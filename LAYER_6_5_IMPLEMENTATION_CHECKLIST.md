# Layer 6.5 Implementation Checklist - Three Sequential Experiments

**Status**: Ready to Begin  
**Start With**: Layer 6.5A (Epistemic Recovery)  
**Estimated Total Time**: ~60 hours (7.5 days)

---

## Layer 6.5A: Epistemic Recovery (~15 hours)

### Scope
- Evidence nodes, discovery nodes, theory nodes
- JTMS++ cascades ONLY
- NO programs, funding, competition, or migration

### Question
"Can truth recover from epistemic shock?"

### Configuration
- 10 worlds
- 20 theories/world (200 total)
- 10 discoveries/world (100 total)
- 30 evidence/world (300 total)
- 25,000 ticks
- Shock at tick 5,000

---

### Phase A1: Test Infrastructure (3 hours)
- [ ] Create `test/tiannara/os/layer6_5a_epistemic_recovery_test.exs`
- [ ] Set up ExUnit test structure
- [ ] Define module constants (@worlds_count, @total_ticks, etc.)
- [ ] Add logging and progress reporting
- [ ] Configure metrics collection every 1,000 ticks

### Phase A2: World Initialization (3 hours)
- [ ] Implement world creation function
- [ ] Create theory nodes (confidence 0.7-0.9)
- [ ] Create discovery nodes (confidence 0.6-0.8, status :candidate)
- [ ] Create evidence nodes (confidence 0.8-1.0)
- [ ] Establish relations: evidence → supports → discovery → supports → theory
- [ ] Verify graph structure (60 nodes, ~40 relations per world)

### Phase A3: Shock Implementation (3 hours)
- [ ] Implement random shock (Shock A)
- [ ] Implement paradigm crisis (Shock B)
- [ ] Implement funding crisis (Shock C) - simplified for 6.5A
- [ ] Apply shock at tick 5,000
- [ ] Verify 30% evidence invalidated
- [ ] Test each shock type individually

### Phase A4: Metrics Collection (3 hours)
- [ ] Track average theory confidence
- [ ] Calculate recovery time
- [ ] Measure shock absorption
- [ ] **Calculate recovery integrity** (validated/total discoveries) ⭐ NEW
- [ ] Track contradiction rate
- [ ] Export metrics to CSV

### Phase A5: Analysis & Classification (3 hours)
- [ ] Calculate CHI (simplified version for 6.5A)
- [ ] Implement orbit classification (Fragile/Recovery/Stable)
- [ ] Check success criteria:
  - [ ] CHI recovery ≥ 70%
  - [ ] Recovery integrity ≥ 0.6
  - [ ] Recovery time ≤ 15k ticks
  - [ ] Shock absorption ≥ 0.30
  - [ ] Contradiction rate not increasing
- [ ] Generate markdown report
- [ ] Assert pass/fail

### Tier Testing for 6.5A
- [ ] **Tier 1**: 5 worlds, 10k ticks (< 2 min) - Debug
- [ ] **Tier 2**: 10 worlds, 25k ticks (< 5 min) - Validate
- [ ] Run full scale once tiers pass

---

## Layer 6.5B: Institutional Recovery (~20 hours)

### Scope
- Adds programs, funding, discovery promotion, knowledge capital
- NO competition, migration, or world death

### Question
"Can institutions recover and sustain research?"

### Configuration
- 15 worlds
- 5 programs/world (75 total)
- 40,000 ticks
- Shock at tick 8,000

---

### Phase B1: Program Infrastructure (4 hours)
- [ ] Extend world initialization to include programs
- [ ] Create program nodes with initial funding
- [ ] Link programs to discoveries/theories
- [ ] Track program status (:active, :suspended)

### Phase B2: Knowledge Capital System (4 hours)
- [ ] **Implement knowledge capital calculation** ⭐ NEW
  ```elixir
  knowledge_capital = 
    (validated_discoveries * 10) +
    (active_theories * 5) +
    (replication_success_rate * 20) +
    (influence_score)
  ```
- [ ] Replace simple funding scores with knowledge capital
- [ ] Update program resource allocation logic

### Phase B3: Discovery Promotion Pipeline (4 hours)
- [ ] Implement promote_high_confidence_discoveries/1
- [ ] Threshold: confidence > 0.85 → status :validated
- [ ] Call every 2,000 ticks
- [ ] Track promotion rate

### Phase B4: Program Creation from Discoveries (4 hours)
- [ ] Implement create_programs_from_discoveries/1
- [ ] Top validated discoveries spawn new programs
- [ ] Link: discovery → funds → program
- [ ] Call every 3,000 ticks

### Phase B5: Enhanced Metrics (4 hours)
- [ ] Calculate full CHI (all 6 components)
- [ ] Track institutional survival rate
- [ ] Monitor knowledge capital per program
- [ ] Measure discovery velocity
- [ ] Maintain recovery integrity tracking
- [ ] Update orbit classification (adds Adaptive possibility)

### Success Criteria for 6.5B
- [ ] Institutional survival ≥ 70%
- [ ] Knowledge capital stable or growing
- [ ] CHI recovery ≥ 75%
- [ ] Discovery velocity resumes within 10k ticks
- [ ] Recovery integrity maintained ≥ 0.6

### Tier Testing for 6.5B
- [ ] **Tier 1**: 8 worlds, 20k ticks (< 3 min) - Debug
- [ ] **Tier 2**: 15 worlds, 40k ticks (< 8 min) - Validate

---

## Layer 6.5C: Competitive Recovery (~25 hours)

### Scope
- Adds competition, knowledge migration, world death, exploration pressure

### Question
"Does competition improve recovery and prevent monoculture?"

### Configuration
- 25 worlds (increased for migration dynamics)
- 60,000 ticks
- Shock at tick 12,000
- Exploration budget: 10%

---

### Phase C1: Competitive Dynamics (5 hours)
- [ ] Implement redistribute_funding_through_competition/1
- [ ] Rank programs by success rate
- [ ] Top 30% gain +20%, bottom 30% lose -20%
- [ ] Suspend programs below threshold
- [ ] Calculate competition index
- [ ] Call every 1,000 ticks

### Phase C2: Knowledge Migration ⭐ CRITICAL (5 hours)
- [ ] Implement cross_world_imports tracking
- [ ] Implement cross_world_exports tracking
- [ ] Create migrate_knowledge/2 function
- [ ] Collapsed worlds can receive discoveries from healthy worlds
- [ ] Calculate migration rate
- [ ] Call every 2,000 ticks
- [ ] Verify migration accelerates recovery

### Phase C3: World Death Tracking ⭐ CRITICAL (4 hours)
- [ ] Add world.status field (:healthy, :degraded, :collapsed, :extinct)
- [ ] Implement check_world_extinction/1
- [ ] Conditions: confidence < 0.3 AND funding < 5 AND discoveries == 0 for 3 intervals
- [ ] Extinct worlds stop generating hypotheses
- [ ] Extinct worlds can still receive migrations
- [ ] Track world survival rate

### Phase C4: Exploration Pressure (3 hours)
- [ ] Reserve 10% budget for low-confidence hypotheses
- [ ] Implement generate_exploratory_hypotheses/1
- [ ] Track exploration/exploitation balance
- [ ] Prevent monoculture convergence
- [ ] Call every 1,500 ticks

### Phase C5: Advanced Antifragility Detection (4 hours)
- [ ] Implement 5-condition antifragility check:
  - [ ] Condition A: Higher confidence
  - [ ] Condition B: Higher diversity
  - [ ] Condition C: Higher velocity
  - [ ] Condition D: Higher validation rate
  - [ ] Condition E: No contradiction increase
- [ ] Detect overfit_recovery (>120% but conditions fail)
- [ ] Classify regenerative orbits

### Phase C6: Orbit Classification for Phase 11.9A (4 hours)
- [ ] Implement full orbit classification system
- [ ] Fragile/Recovery/Stable/Adaptive/Regenerative/Overfit
- [ ] Generate Orbit Transition Matrix data
- [ ] Export orbit classifications to JSON
- [ ] Prepare data format for Phase 11.9A

### Success Criteria for 6.5C
- [ ] Competition active (> 0.1 index)
- [ ] Migration accelerates recovery in collapsed worlds
- [ ] No winner-take-all monoculture (diversity ≥ 70%)
- [ ] Exploration budget utilized (10% low-confidence)
- [ ] World survival ≥ 60%
- [ ] At least one world achieves regenerative orbit
- [ ] All 5 antifragility conditions met (for regenerative classification)

### Tier Testing for 6.5C
- [ ] **Tier 1**: 10 worlds, 30k ticks (< 5 min) - Debug
- [ ] **Tier 2**: 15 worlds, 45k ticks (< 10 min) - Validate
- [ ] **Tier 3**: 25 worlds, 60k ticks (< 15 min) - Full scale

---

## Integration & Documentation (After All Layers Pass)

### Phase D1: Cross-Layer Analysis (3 hours)
- [ ] Compare 6.5A vs 6.5B vs 6.5C results
- [ ] Identify which mechanisms contribute most to recovery
- [ ] Analyze orbit distribution across layers
- [ ] Document insights for Phase 12

### Phase D2: Phase 11.9A Data Preparation (2 hours)
- [ ] Format orbit transition data
- [ ] Create Orbit Transition Matrix input files
- [ ] Document trajectory patterns
- [ ] Prepare handoff to Orbit Engineering team

### Phase D3: Phase 12 Knowledge Objects (2 hours)
- [ ] Extract successful recovery patterns
- [ ] Store as institutional knowledge
- [ ] Create "Best Practices per Shock Type" database
- [ ] Document for Scientific Discovery Stack integration

### Phase D4: Final Reporting (2 hours)
- [ ] Create comprehensive Layer 6.5 report
- [ ] Update VERIFICATION_INDEX.md
- [ ] Archive all CSV/JSON exports
- [ ] Prepare presentation for stakeholders

---

## Common Pitfalls to Avoid

### ❌ Don't Skip Layers
- **Wrong**: Jump straight to 6.5C
- **Right**: Complete 6.5A → 6.5B → 6.5C sequentially

### ❌ Don't Ignore Recovery Integrity
- **Wrong**: Only track confidence recovery
- **Right**: Always validate recovery_integrity ≥ 0.6

### ❌ Don't Forget Migration in 6.5C
- **Wrong**: Test isolated worlds
- **Right**: Enable cross-world knowledge transfer

### ❌ Don't Hardcode Thresholds
- **Wrong**: Magic numbers throughout
- **Right**: Module constants for easy tuning

### ❌ Don't Skip Tier Testing
- **Wrong**: Run full scale immediately
- **Right**: Progress through tiers as each passes

---

## Success Indicators

### Layer 6.5A Passing Means
- ✅ Epistemic substrate fundamentally sound
- ✅ JTMS++ cascades work correctly
- ✅ Ready for institutional dynamics

### Layer 6.5B Passing Means
- ✅ Institutions can sustain research
- ✅ Knowledge capital model works
- ✅ Promotion pipeline functional
- ✅ Ready for competition

### Layer 6.5C Passing Means
- ✅ Competition improves recovery
- ✅ Migration prevents permanent collapse
- ✅ Exploration prevents monoculture
- ✅ Regenerative orbits achievable
- ✅ **Epistemic substrate essentially complete**
- ✅ Ready for Phase 12 integration

---

## Files to Create

1. `test/tiannara/os/layer6_5a_epistemic_recovery_test.exs`
2. `test/tiannara/os/layer6_5b_institutional_recovery_test.exs`
3. `test/tiannara/os/layer6_5c_competitive_recovery_test.exs`
4. `lib/tiannara/os/knowledge_migration.ex` (NEW module)
5. `lib/tiannara/os/orbit_classifier.ex` (NEW module)
6. `output/layer6_5a_results.csv`
7. `output/layer6_5b_results.csv`
8. `output/layer6_5c_results.csv`
9. `output/orbit_transition_matrix.json`
10. `output/layer6_5_comprehensive_report.md`

---

## Timeline Summary

| Layer | Hours | Cumulative | Calendar Days |
|-------|-------|------------|---------------|
| 6.5A | 15 | 15 | ~2 days |
| 6.5B | 20 | 35 | ~4.5 days |
| 6.5C | 25 | 60 | ~7.5 days |
| Integration | 9 | 69 | ~8.5 days |

**Total**: ~69 hours (8.5 working days)

**Recommendation**: Start Monday, aim to complete 6.5A by Wednesday, 6.5B by Friday, 6.5C by following Wednesday, integration by following Friday.

---

*Checklist created: June 13, 2026*  
*Ready to begin implementation*  
*Next action: Start Phase A1 (Test Infrastructure for 6.5A)*
