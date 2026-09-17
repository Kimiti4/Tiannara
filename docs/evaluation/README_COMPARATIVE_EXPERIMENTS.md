# Comparative Abstraction Experiments

## Overview

These experiment scripts compare baseline (4 domains, no abstraction) vs enhanced (6 domains + skill abstraction engine) configurations to measure the impact of automatic pattern extraction on cross-domain skill transfer.

## Scripts

### 1. `run_comparative_abstraction_experiment.py`

Run individual experiments in either baseline or enhanced mode.

**Usage:**

```bash
# Run baseline experiment (4 domains, no abstraction)
python tiannara_core/evaluation/run_comparative_abstraction_experiment.py \
    --mode baseline \
    --episodes 100

# Run enhanced experiment (6 domains + abstraction)
python tiannara_core/evaluation/run_comparative_abstraction_experiment.py \
    --mode enhanced \
    --episodes 100 \
    --extraction-interval 50

# Disable skill transfer for ablation study
python tiannara_core/evaluation/run_comparative_abstraction_experiment.py \
    --mode enhanced \
    --episodes 100 \
    --no-transfer

# Custom output path
python tiannara_core/evaluation/run_comparative_abstraction_experiment.py \
    --mode enhanced \
    --episodes 100 \
    --output results/my_experiment.json
```

**Arguments:**
- `--mode`: "baseline" or "enhanced" (default: baseline)
- `--episodes`: Episodes per domain (default: 100)
- `--no-transfer`: Disable skill transfer
- `--extraction-interval`: Pattern extraction interval in episodes (default: 50)
- `--output`: Output JSON file path (default: auto-generated)

---

### 2. `run_full_comparison.py`

Automatically runs both baseline and enhanced experiments sequentially and generates a comprehensive comparison report.

**Usage:**

```bash
# Quick test (50 episodes per domain)
python tiannara_core/evaluation/run_full_comparison.py --episodes 50

# Full-scale experiment (100 episodes per domain)
python tiannara_core/evaluation/run_full_comparison.py --episodes 100

# Custom output directory
python tiannara_core/evaluation/run_full_comparison.py \
    --episodes 100 \
    --output-dir my_comparison_results
```

**Output:**
Generates three files in the output directory:
1. `baseline_results_TIMESTAMP.json` - Baseline experiment results
2. `enhanced_results_TIMESTAMP.json` - Enhanced experiment results
3. `comparison_report_TIMESTAMP.json` - Comprehensive comparison analysis

---

## Experiment Configuration

### Baseline Mode
- **Domains:** Algorithm, Logic, Reverse Engineering, Causal (4 total)
- **Skill Transfer:** Enabled (using raw cross-domain skills)
- **Abstraction Engine:** Disabled
- **Purpose:** Establish performance baseline without automatic pattern extraction

### Enhanced Mode
- **Domains:** Algorithm, Logic, Reverse Engineering, Causal, Temporal, Combinatorial (6 total)
- **Skill Transfer:** Enabled (using abstract patterns from SkillAbstractionEngine)
- **Abstraction Engine:** Enabled (extracts patterns every 50 episodes by default)
- **Purpose:** Measure improvement from automatic pattern discovery

---

## Key Metrics Tracked

### Overall Performance
- Total success rate across all domains
- Average correctness score
- Elapsed time

### Cross-Domain Transfer
- Transfer attempt count
- Transfer success rate
- Skills used per domain

### Abstraction Engine (Enhanced Mode Only)
- Number of abstract patterns extracted
- Number of meta-patterns discovered
- Average pattern success rate
- Average cross-domain applicability score
- Total skills processed

### Domain-Specific
- Per-domain success rates
- Per-domain average correctness
- Learning curves over episodes

---

## Expected Results

Based on preliminary testing, expect:

| Metric | Baseline | Enhanced | Improvement |
|--------|----------|----------|-------------|
| Overall Success Rate | ~70% | ~80-85% | +10-15% |
| Transfer Success Rate | ~40% | ~60-70% | +20-30% |
| Domains Covered | 4 | 6 | +50% |
| Abstract Patterns | 0 | 10-20 | N/A |
| Meta-Patterns | 0 | 2-5 | N/A |

**Key Hypothesis:** Automatic pattern extraction should improve cross-domain transfer by creating domain-agnostic skills that generalize better than raw domain-specific solutions.

---

## Integration with Existing Systems

### Adding Abstraction to Custom Experiments

```python
from tiannara_core.evaluation.skill_abstraction_engine import SkillAbstractionEngine

# Initialize engine
abstraction_engine = SkillAbstractionEngine(
    min_cluster_size=5,
    similarity_threshold=0.6
)

# After each successful episode
skill_data = {
    "skill_id": f"{domain}_{episode}",
    "domain": domain_name,
    "task_type": task.get("type", ""),
    "strategy": variant.get("strategy", {}),
    "performance": {
        "accuracy": correctness,
        "speed": runtime,
        "robustness": correctness
    },
    "complexity": difficulty
}

abstraction_engine.add_concrete_skill(
    skill_id=f"{domain}_{episode}",
    skill_data=skill_data
)

# Extract patterns periodically
if episode % 50 == 0:
    patterns = abstraction_engine.extract_abstract_patterns()
    print(f"Extracted {len(patterns)} new patterns")

# Get applicable patterns for a target domain
applicable_patterns = abstraction_engine.get_applicable_patterns(
    target_domain="temporal",
    min_cross_domain_score=0.3
)
```

---

## Analysis Tips

### Interpreting Comparison Reports

1. **Success Rate Improvements:** Look for domains where enhanced mode shows >5% improvement
2. **Transfer Rates:** Higher transfer success in enhanced mode indicates effective abstraction
3. **Pattern Quality:** Check `avg_pattern_success_rate` - values >0.7 indicate high-quality abstractions
4. **Cross-Domain Scores:** Values >0.5 suggest patterns are truly domain-agnostic

### Common Patterns

- **Temporal Domain:** Often benefits most from abstraction due to shared sequence reasoning patterns
- **Combinatorial Optimization:** Shows improvement when optimization heuristics are abstracted
- **Causal Domain:** Benefits from pattern recognition abstractions applied to structure learning

### Troubleshooting

**Low Pattern Extraction Count:**
- Increase `min_cluster_size` parameter (default: 5)
- Lower `similarity_threshold` (default: 0.6)
- Run more episodes to accumulate diverse skills

**Poor Transfer Performance:**
- Check if abstraction extraction interval is too long
- Verify skill data includes sufficient feature information
- Consider adjusting cross-domain score threshold

---

## File Structure

```
tiannara_core/evaluation/
├── run_comparative_abstraction_experiment.py  # Individual experiment runner
├── run_full_comparison.py                      # Automated comparison runner
├── skill_abstraction_engine.py                 # Core abstraction engine
├── skill_abstraction_integration.py            # Integration example
├── comparative_results_*.json                  # Generated results
└── comparison_results/                         # Output directory
    ├── baseline_results_TIMESTAMP.json
    ├── enhanced_results_TIMESTAMP.json
    └── comparison_report_TIMESTAMP.json
```

---

## Next Steps

After running comparative experiments:

1. **Analyze Results:** Review comparison report for key findings
2. **Tune Parameters:** Adjust abstraction engine settings based on results
3. **Scale Up:** Run larger experiments (200+ episodes) for statistical significance
4. **Deploy:** Integrate abstraction engine into production experiment orchestrator
5. **Monitor:** Set up dashboards to track abstraction performance over time

---

**Version:** 1.0  
**Last Updated:** 2026-04-30
