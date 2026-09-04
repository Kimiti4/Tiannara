"""Run Both Baseline and Enhanced Experiments with Comparison Report.

Automatically runs:
1. Baseline experiment (4 domains, no abstraction)
2. Enhanced experiment (6 domains + abstraction engine)
3. Generates comprehensive comparison report

Usage:
    python tiannara_core/evaluation/run_full_comparison.py --episodes 50
"""

import sys
from pathlib import Path
import json
import time
from datetime import datetime
from typing import Dict, Any

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.run_comparative_abstraction_experiment import run_experiment


def generate_comparison_report(baseline_results: Dict[str, Any], 
                               enhanced_results: Dict[str, Any]) -> Dict[str, Any]:
    """Generate comprehensive comparison report."""
    
    print("\n" + "=" * 80)
    print("GENERATING COMPARISON REPORT")
    print("=" * 80)
    
    # Extract key metrics
    baseline_overall = baseline_results["overall"]
    enhanced_overall = enhanced_results["overall"]
    
    baseline_domains = baseline_results["per_domain"]
    enhanced_domains = enhanced_results["per_domain"]
    
    # Calculate improvements
    success_rate_improvement = (
        enhanced_overall["overall_success_rate"] - baseline_overall["overall_success_rate"]
    )
    
    improvement_percentage = (
        (success_rate_improvement / baseline_overall["overall_success_rate"] * 100)
        if baseline_overall["overall_success_rate"] > 0 else 0
    )
    
    # Domain-by-domain comparison
    domain_comparison = {}
    common_domains = set(baseline_domains.keys()) & set(enhanced_domains.keys())
    
    for domain in sorted(common_domains):
        baseline_stats = baseline_domains[domain]
        enhanced_stats = enhanced_domains[domain]
        
        domain_comparison[domain] = {
            "baseline_success_rate": baseline_stats["success_rate"],
            "enhanced_success_rate": enhanced_stats["success_rate"],
            "improvement": enhanced_stats["success_rate"] - baseline_stats["success_rate"],
            "baseline_correctness": baseline_stats["avg_correctness"],
            "enhanced_correctness": enhanced_stats["avg_correctness"]
        }
    
    # New domains in enhanced mode
    new_domains = set(enhanced_domains.keys()) - set(baseline_domains.keys())
    new_domain_stats = {
        domain: enhanced_domains[domain] for domain in new_domains
    }
    
    # Skill transfer comparison
    baseline_transfer = baseline_results.get("skill_memory_stats", {}).get("transfer_success_rate", 0.0)
    enhanced_transfer = enhanced_results.get("skill_memory_stats", {}).get("transfer_success_rate", 0.0)
    
    # Abstraction statistics
    abstraction_stats = enhanced_results.get("skill_memory_stats", {}).get("abstraction", {})
    
    # Build report
    report = {
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "summary": {
            "baseline_mode": {
                "domains": list(baseline_domains.keys()),
                "total_episodes": baseline_overall["total_episodes"],
                "success_rate": baseline_overall["overall_success_rate"],
                "elapsed_time": baseline_overall["elapsed_time_seconds"]
            },
            "enhanced_mode": {
                "domains": list(enhanced_domains.keys()),
                "total_episodes": enhanced_overall["total_episodes"],
                "success_rate": enhanced_overall["overall_success_rate"],
                "elapsed_time": enhanced_overall["elapsed_time_seconds"]
            },
            "improvements": {
                "success_rate_absolute": success_rate_improvement,
                "success_rate_percentage": improvement_percentage,
                "transfer_rate_baseline": baseline_transfer,
                "transfer_rate_enhanced": enhanced_transfer,
                "transfer_improvement": enhanced_transfer - baseline_transfer
            }
        },
        "domain_comparison": domain_comparison,
        "new_domains_in_enhanced": {
            domain: {
                "success_rate": stats["success_rate"],
                "avg_correctness": stats["avg_correctness"]
            }
            for domain, stats in new_domain_stats.items()
        },
        "abstraction_engine_performance": {
            "patterns_extracted": abstraction_stats.get("abstract_patterns", 0),
            "meta_patterns": abstraction_stats.get("meta_patterns", 0),
            "avg_pattern_success_rate": abstraction_stats.get("avg_abstract_success_rate", 0.0),
            "avg_cross_domain_score": abstraction_stats.get("avg_cross_domain_score", 0.0),
            "total_skills_processed": abstraction_stats.get("total_skills_processed", 0)
        },
        "key_findings": []
    }
    
    # Generate key findings
    findings = []
    
    if success_rate_improvement > 0:
        findings.append(
            f"✅ Overall success rate improved by {improvement_percentage:.1f}% "
            f"({baseline_overall['overall_success_rate']:.2%} → {enhanced_overall['overall_success_rate']:.2%})"
        )
    else:
        findings.append(
            f"⚠️ Overall success rate decreased by {abs(improvement_percentage):.1f}% "
            f"(needs investigation)"
        )
    
    if enhanced_transfer > baseline_transfer:
        findings.append(
            f"✅ Cross-domain transfer success rate improved from "
            f"{baseline_transfer:.2%} to {enhanced_transfer:.2%}"
        )
    
    if abstraction_stats.get("abstract_patterns", 0) > 0:
        findings.append(
            f"✅ Abstraction engine extracted {abstraction_stats['abstract_patterns']} abstract patterns "
            f"and {abstraction_stats.get('meta_patterns', 0)} meta-patterns"
        )
    
    if new_domains:
        findings.append(
            f"✅ Successfully expanded from {len(baseline_domains)} to {len(enhanced_domains)} domains"
        )
    
    # Check which domains improved
    improved_domains = [
        domain for domain, comp in domain_comparison.items()
        if comp["improvement"] > 0
    ]
    
    if improved_domains:
        findings.append(
            f"✅ {len(improved_domains)} domains showed improvement: {', '.join(improved_domains)}"
        )
    
    report["key_findings"] = findings
    
    return report


def print_comparison_summary(report: Dict[str, Any]):
    """Print human-readable comparison summary."""
    
    print("\n" + "=" * 80)
    print("COMPARISON SUMMARY")
    print("=" * 80)
    
    summary = report["summary"]
    
    print(f"\n📊 OVERALL PERFORMANCE:")
    print(f"  Baseline (4 domains):  {summary['baseline_mode']['success_rate']:.2%} success rate")
    print(f"  Enhanced (6 domains):  {summary['enhanced_mode']['success_rate']:.2%} success rate")
    print(f"  Improvement:           {summary['improvements']['success_rate_percentage']:+.1f}%")
    
    print(f"\n🔄 CROSS-DOMAIN TRANSFER:")
    print(f"  Baseline transfer rate: {summary['improvements']['transfer_rate_baseline']:.2%}")
    print(f"  Enhanced transfer rate: {summary['improvements']['transfer_rate_enhanced']:.2%}")
    print(f"  Transfer improvement:   {summary['improvements']['transfer_improvement']:+.2%}")
    
    print(f"\n🧩 DOMAIN-BY-DOMAIN COMPARISON:")
    for domain, comp in report["domain_comparison"].items():
        improvement = comp["improvement"]
        arrow = "↑" if improvement > 0 else "↓" if improvement < 0 else "→"
        print(f"  {domain:25s}: {comp['baseline_success_rate']:6.2%} {arrow} {comp['enhanced_success_rate']:6.2%} ({improvement:+.2%})")
    
    if report["new_domains_in_enhanced"]:
        print(f"\n➕ NEW DOMAINS IN ENHANCED MODE:")
        for domain, stats in report["new_domains_in_enhanced"].items():
            print(f"  {domain:25s}: {stats['success_rate']:6.2%} success, {stats['avg_correctness']:.4f} correctness")
    
    print(f"\n🎯 ABSTRACTION ENGINE:")
    abs_perf = report["abstraction_engine_performance"]
    print(f"  Patterns extracted:     {abs_perf['patterns_extracted']}")
    print(f"  Meta-patterns:          {abs_perf['meta_patterns']}")
    print(f"  Avg pattern success:    {abs_perf['avg_pattern_success_rate']:.2%}")
    print(f"  Avg cross-domain score: {abs_perf['avg_cross_domain_score']:.2f}")
    
    print(f"\n💡 KEY FINDINGS:")
    for i, finding in enumerate(report["key_findings"], 1):
        print(f"  {i}. {finding}")
    
    print("\n" + "=" * 80)


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Run full baseline vs enhanced comparison")
    parser.add_argument("--episodes", type=int, default=50,
                       help="Episodes per domain for each experiment (default: 50)")
    parser.add_argument("--output-dir", type=str, default="comparison_results",
                       help="Directory to save results (default: comparison_results)")
    
    args = parser.parse_args()
    
    # Create output directory
    output_dir = Path(args.output_dir)
    output_dir.mkdir(exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    print("=" * 80)
    print("FULL COMPARATIVE EXPERIMENT")
    print("=" * 80)
    print(f"Episodes per domain: {args.episodes}")
    print(f"Output directory: {output_dir}")
    print()
    
    # Run baseline experiment
    print("\n" + "=" * 80)
    print("PHASE 1: BASELINE EXPERIMENT (4 domains, no abstraction)")
    print("=" * 80)
    
    baseline_start = time.time()
    baseline_results = run_experiment(
        mode="baseline",
        episodes_per_domain=args.episodes,
        enable_skill_transfer=True,
        extraction_interval=9999  # Disable abstraction in baseline
    )
    baseline_time = time.time() - baseline_start
    
    # Save baseline results
    baseline_path = output_dir / f"baseline_results_{timestamp}.json"
    with open(baseline_path, 'w') as f:
        json.dump(baseline_results, f, indent=2)
    print(f"\nBaseline results saved to: {baseline_path}")
    
    # Brief pause between experiments
    print("\n" + "-" * 80)
    print("Waiting 5 seconds before enhanced experiment...")
    print("-" * 80)
    time.sleep(5)
    
    # Run enhanced experiment
    print("\n" + "=" * 80)
    print("PHASE 2: ENHANCED EXPERIMENT (6 domains + abstraction)")
    print("=" * 80)
    
    enhanced_start = time.time()
    enhanced_results = run_experiment(
        mode="enhanced",
        episodes_per_domain=args.episodes,
        enable_skill_transfer=True,
        extraction_interval=50  # Extract patterns every 50 episodes
    )
    enhanced_time = time.time() - enhanced_start
    
    # Save enhanced results
    enhanced_path = output_dir / f"enhanced_results_{timestamp}.json"
    with open(enhanced_path, 'w') as f:
        json.dump(enhanced_results, f, indent=2)
    print(f"\nEnhanced results saved to: {enhanced_path}")
    
    # Generate comparison report
    comparison_report = generate_comparison_report(baseline_results, enhanced_results)
    
    # Print summary
    print_comparison_summary(comparison_report)
    
    # Save comparison report
    report_path = output_dir / f"comparison_report_{timestamp}.json"
    with open(report_path, 'w') as f:
        json.dump(comparison_report, f, indent=2)
    print(f"\nComparison report saved to: {report_path}")
    
    # Print timing info
    print(f"\n⏱️  TIMING:")
    print(f"  Baseline experiment: {baseline_time:.2f}s")
    print(f"  Enhanced experiment: {enhanced_time:.2f}s")
    print(f"  Total time: {baseline_time + enhanced_time:.2f}s")
    
    print("\n" + "=" * 80)
    print("COMPARISON COMPLETE")
    print("=" * 80)
    print(f"\nAll results saved to: {output_dir}/")
    print(f"  - {baseline_path.name}")
    print(f"  - {enhanced_path.name}")
    print(f"  - {report_path.name}")
    
    return comparison_report


if __name__ == "__main__":
    main()
