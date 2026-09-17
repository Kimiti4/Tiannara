# Quick Start: Comparative Abstraction Experiments

## TL;DR - Run Everything in One Command

```bash
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic

# Run full comparison (baseline + enhanced) with 50 episodes each
python tiannara_core/evaluation/run_full_comparison.py --episodes 50
```

This will:
1. ✅ Run baseline experiment (4 domains, no abstraction)
2. ✅ Run enhanced experiment (6 domains + abstraction engine)
3. ✅ Generate comparison report
4. ✅ Save all results to `comparison_results/` directory

---

## Step-by-Step Guide

### Step 1: Quick Test (5 minutes)

Test that everything works with a minimal run:

```bash
python tiannara_core/evaluation/run_comparative_abstraction_experiment.py --mode baseline --episodes 5
```

Expected output:
```
================================================================================
LARGE-SCALE COMPARATIVE EXPERIMENT - BASELINE MODE
================================================================================
Mode: baseline
Episodes per domain: 5
...
Overall Success Rate: XX.XX%
Total Episodes: 20
Results saved to: comparative_results_baseline_TIMESTAMP.json
```

### Step 2: Run Full Comparison (30-60 minutes)

Run both experiments automatically:

```bash
python tiannara_core/evaluation/run_full_comparison.py --episodes 50
```

This takes ~30-60 minutes depending on your system.

**What happens:**
1. Baseline experiment runs (4 domains × 50 episodes = 200 episodes)
2. Results saved to `comparison_results/baseline_results_TIMESTAMP.json`
3. 5-second pause
4. Enhanced experiment runs (6 domains × 50 episodes = 300 episodes)
5. Results saved to `comparison_results/enhanced_results_TIMESTAMP.json`
6. Comparison report generated and saved to `comparison_results/comparison_report_TIMESTAMP.json`
7. Summary printed to console

### Step 3: Review Results

Open the comparison report:

```bash
# View JSON report
cat comparison_results/comparison_report_TIMESTAMP.json

# Or open in your favorite JSON viewer
code comparison_results/comparison_report_TIMESTAMP.json
```

Look for these key sections:
- `summary.improvements` - Overall performance gains
- `domain_comparison` - Per-domain improvements
- `abstraction_engine_performance` - Pattern extraction stats
- `key_findings` - Automated insights

---

## Common Use Cases

### Use Case 1: Validate Abstraction Engine Works

```bash
# Run small enhanced experiment
python tiannara_core/evaluation/run_comparative_abstraction_experiment.py \
    --mode enhanced \
    --episodes 20 \
    --extraction-interval 10
```

Check that patterns are extracted:
```
[Abstraction Engine] Extracting patterns at episode 10...
[Abstraction Engine] Extracted 2 new patterns
[Abstraction Engine] Total patterns: 2
```

### Use Case 2: Measure Transfer Improvement

```bash
# Run baseline with transfer enabled
python tiannara_core/evaluation/run_comparative_abstraction_experiment.py \
    --mode baseline \
    --episodes 100

# Run enhanced with transfer enabled
python tiannara_core/evaluation/run_comparative_abstraction_experiment.py \
    --mode enhanced \
    --episodes 100

# Compare transfer rates in results JSON files
```

### Use Case 3: Ablation Study (No Transfer)

```bash
# Test if abstraction helps even without explicit transfer
python tiannara_core/evaluation/run_comparative_abstraction_experiment.py \
    --mode enhanced \
    --episodes 100 \
    --no-transfer
```

### Use Case 4: Tune Abstraction Parameters

```bash
# Extract patterns more frequently (every 25 episodes)
python tiannara_core/evaluation/run_comparative_abstraction_experiment.py \
    --mode enhanced \
    --episodes 100 \
    --extraction-interval 25

# Extract less frequently (every 100 episodes)
python tiannara_core/evaluation/run_comparative_abstraction_experiment.py \
    --mode enhanced \
    --episodes 200 \
    --extraction-interval 100
```

---

## Understanding the Output

### Console Output Example

```
📊 OVERALL PERFORMANCE:
  Baseline (4 domains):  72.50% success rate
  Enhanced (6 domains):  83.75% success rate
  Improvement:           +15.5%

🔄 CROSS-DOMAIN TRANSFER:
  Baseline transfer rate: 42.30%
  Enhanced transfer rate: 68.50%
  Transfer improvement:   +26.20%

🧩 DOMAIN-BY-DOMAIN COMPARISON:
  algorithm                : 75.00% ↑ 82.00% (+7.00%)
  logic                    : 70.00% ↑ 78.00% (+8.00%)
  reverse_engineering      : 68.00% ↑ 75.00% (+7.00%)
  causal                   : 77.00% ↑ 85.00% (+8.00%)

➕ NEW DOMAINS IN ENHANCED MODE:
  temporal                 : 80.00% success, 0.7200 correctness
  combinatorial            : 76.00% success, 0.6800 correctness

🎯 ABSTRACTION ENGINE:
  Patterns extracted:     12
  Meta-patterns:          3
  Avg pattern success:    85.40%
  Avg cross-domain score: 0.68

💡 KEY FINDINGS:
  1. ✅ Overall success rate improved by 15.5%
  2. ✅ Cross-domain transfer success rate improved from 42.30% to 68.50%
  3. ✅ Abstraction engine extracted 12 abstract patterns and 3 meta-patterns
```

### JSON Report Structure

```json
{
  "timestamp": "2026-04-30 15:30:00",
  "summary": {
    "baseline_mode": {...},
    "enhanced_mode": {...},
    "improvements": {
      "success_rate_absolute": 0.1125,
      "success_rate_percentage": 15.52,
      "transfer_improvement": 0.262
    }
  },
  "domain_comparison": {...},
  "abstraction_engine_performance": {...},
  "key_findings": [...]
}
```

---

## Troubleshooting

### Problem: Import Error

```
ModuleNotFoundError: No module named 'tiannara_core'
```

**Solution:** Make sure you're in the project root directory:
```bash
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic
python tiannara_core/evaluation/run_full_comparison.py --episodes 50
```

### Problem: No Patterns Extracted

If you see:
```
[Abstraction Engine] Extracted 0 new patterns
```

**Solutions:**
1. Run more episodes (need at least 50+ for meaningful clustering)
2. Lower similarity threshold in code:
   ```python
   SkillAbstractionEngine(min_cluster_size=3, similarity_threshold=0.5)
   ```
3. Check that skills are being stored (look for "Transfer attempts" in output)

### Problem: Experiment Takes Too Long

**Solutions:**
1. Reduce episodes: `--episodes 20` instead of `--episodes 100`
2. Increase extraction interval: `--extraction-interval 100`
3. Run baseline only first to estimate time

### Problem: Low Success Rates

If success rates are <50%, this is expected for difficult tasks. The key metric is **relative improvement** between baseline and enhanced modes, not absolute success rate.

---

## Next Steps After Running

1. **Review Key Findings:** Look at the `key_findings` section in the comparison report
2. **Identify Best Domains:** Which domains showed the most improvement?
3. **Analyze Patterns:** What types of abstract patterns were extracted?
4. **Tune Parameters:** Adjust based on results
5. **Scale Up:** Run larger experiments (200+ episodes) for statistical significance

---

## Command Reference

| Command | Purpose | Time Estimate |
|---------|---------|---------------|
| `--mode baseline --episodes 5` | Quick test | 1 min |
| `--mode enhanced --episodes 20` | Validate abstraction | 5 min |
| `run_full_comparison.py --episodes 50` | Full comparison | 30-60 min |
| `run_full_comparison.py --episodes 100` | Large-scale test | 60-120 min |
| `--mode enhanced --no-transfer` | Ablation study | Varies |

---

## Getting Help

For detailed documentation, see:
- `README_COMPARATIVE_EXPERIMENTS.md` - Comprehensive usage guide
- `ABSTRACTION_INTEGRATION_SUMMARY.md` - Technical implementation details
- `skill_abstraction_integration.py` - Code examples

---

**Ready to start?** Run this command now:

```bash
python tiannara_core/evaluation/run_full_comparison.py --episodes 50
```
