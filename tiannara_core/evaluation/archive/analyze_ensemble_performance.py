"""Analyze Ensemble Performance Issues."""

import json
from pathlib import Path

# Load results
results_file = Path("multi_domain_episodes.jsonl")
with open(results_file, 'r') as f:
    results = [json.loads(line) for line in f]

print("Ensemble Performance Analysis")
print("=" * 80)

# Separate ensemble vs single-domain
ensemble_eps = [r for r in results if r.get("used_method") == "ensemble"]
single_eps = [r for r in results if r.get("used_method") == "single_domain"]

print(f"\nTotal Episodes: {len(results)}")
print(f"  Ensemble: {len(ensemble_eps)} ({len(ensemble_eps)/len(results)*100:.1f}%)")
print(f"  Single-domain: {len(single_eps)} ({len(single_eps)/len(results)*100:.1f}%)")

print(f"\nSuccess Rates:")
ensemble_success = sum(1 for r in ensemble_eps if r["success"]) / len(ensemble_eps) if ensemble_eps else 0
single_success = sum(1 for r in single_eps if r["success"]) / len(single_eps) if single_eps else 0
print(f"  Ensemble: {ensemble_success:.1%}")
print(f"  Single-domain: {single_success:.1%}")

print(f"\nSuccess by Domain:")
for domain in ["algorithm", "logic", "reverse_engineering", "causal"]:
    ens_domain = [r for r in ensemble_eps if r["domain"] == domain]
    sing_domain = [r for r in single_eps if r["domain"] == domain]
    
    ens_rate = sum(1 for r in ens_domain if r["success"]) / len(ens_domain) if ens_domain else 0
    sing_rate = sum(1 for r in sing_domain if r["success"]) / len(sing_domain) if sing_domain else 0
    
    print(f"  {domain.upper():25s}: Ensemble={ens_rate:.1%} ({len(ens_domain):2d}) | Single={sing_rate:.1%} ({len(sing_domain):2d})")

print(f"\nComposite Strategies per Episode:")
avg_comp_ens = sum(r.get("composite_strategies", 0) for r in ensemble_eps) / len(ensemble_eps) if ensemble_eps else 0
avg_comp_sing = sum(r.get("composite_strategies", 0) for r in single_eps) / len(single_eps) if single_eps else 0
print(f"  Ensemble episodes: {avg_comp_ens:.2f} avg composites")
print(f"  Single-domain episodes: {avg_comp_sing:.2f} avg composites")

print(f"\nTransferred Skills per Episode:")
avg_skills_ens = sum(r.get("transferred_skills", 0) for r in ensemble_eps) / len(ensemble_eps) if ensemble_eps else 0
avg_skills_sing = sum(r.get("transferred_skills", 0) for r in single_eps) / len(single_eps) if single_eps else 0
print(f"  Ensemble episodes: {avg_skills_ens:.2f} avg skills")
print(f"  Single-domain episodes: {avg_skills_sing:.2f} avg skills")

print("\n" + "=" * 80)
print("Key Insights:")
print("-" * 80)

if ensemble_success < single_success:
    print(f"PROBLEM: Ensemble is UNDERPERFORMING by {single_success - ensemble_success:.1%}")
    print("\nPossible causes:")
    print("  1. Confidence threshold too low - allowing bad ensembles")
    print("  2. Cross-domain predictions are noisy/unreliable")
    print("  3. Weighted averaging dilutes good single-domain predictions")
    print("\nRecommendations:")
    print("  - Raise confidence thresholds (currently ~0.6-0.75)")
    print("  - Require higher skill transfer quality before using ensemble")
    print("  - Consider voting instead of weighted averaging")
else:
    print(f"SUCCESS: Ensemble is IMPROVING by {ensemble_success - single_success:.1%}")
