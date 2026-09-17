# Phase 5A Validation Campaign

## 🎯 Purpose

Validate that ASC has crossed the threshold from **Evolution Simulator** to **Adaptive Engineering Civilization** after fixing the persistence boundary bug.

## 📊 Configuration

- **10 projects** × **20 generations** = **200 project-generations**
- Focus on core adaptation metrics only
- Clean slate (no pre-existing patterns)

## ✅ Success Criteria

All four must be met:

1. **Repair Success Rate > 20%**
2. **Knowledge Reuse Rate > 10%**
3. **Adaptation Velocity > 0**
4. **Average Fitness(G20) > Average Fitness(G1)**

## 🚀 How to Run

### In WSL2 Terminal:

```bash
cd ~/projects/tiannara
mix run scripts/evolution_phase5a_validation.exs
```

### Expected Runtime:
- Compilation: ~3-5 minutes (first time in WSL2)
- Campaign execution: ~10-15 minutes
- Total: ~15-20 minutes

## 📈 What to Watch For

During execution, look for these indicators of successful adaptation:

### Positive Signs ✅
- `🔄 Attempting pattern reuse` messages appearing regularly
- `✅ Pattern reuse SUCCESS` appearing more frequently as generations progress
- `🌍 Cross-project transfer detected` showing knowledge spreading
- `📈 Adaptation Velocity` showing positive values
- Increasing fitness scores across generations

### Concerning Signs ⚠️
- All repairs generating new patterns (no reuse)
- Consistently low or negative adaptation velocity
- No cross-project transfers occurring
- Fitness not improving over generations

## 🔬 Scientific Significance

If this campaign succeeds, it proves:

1. **Memory integrity restored**: Patterns persist correctly across generations
2. **Semantic matching works**: FailureClassifier enables flexible pattern reuse
3. **Cross-project transfer active**: Knowledge spreads between different projects
4. **Evolutionary dynamics operational**: System is genuinely adapting, not just simulating

This would mark the transition from:
```
Observation Layer → Adaptation Layer
```

And establish Tiannara as an **Adaptive Engineering Civilization** rather than just an Evolution Simulator.

## 📝 Next Steps After Campaign

Based on results:

### If ALL criteria met:
→ Proceed to Phase 5B: TransferEngine implementation
→ Begin law discovery from repair patterns
→ Implement Canonical Principle promotion

### If SOME criteria met:
→ Analyze which metrics failed and why
→ Tune semantic matching confidence thresholds
→ Adjust fitness calculation weights
→ Re-run validation

### If NO criteria met:
→ Investigate RepairExecutor effectiveness
→ Check if failure classification is too broad/narrow
→ Verify ETS population is correct
→ Debug pattern matching logic

## 🧪 Expected Results (Hypothesis)

Based on architecture analysis:

```
Knowledge Reuse:      15-40%
Repair Success:       25-60%
Adaptation Velocity:  Small but positive (0.1-0.5% per generation)
Fitness Improvement:  5-15% from G1 to G20
```

First law candidates likely to emerge:
- "Knowledge reuse improves repair success"
- "Repeated repair patterns outperform novel generation"
- "Boundary-condition failures dominate early generations"
- "Rollback-capable systems recover faster than patch-only"

---

*Run Date: $(date)*
*Campaign Script: scripts/evolution_phase5a_validation.exs*
