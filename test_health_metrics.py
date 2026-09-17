"""
Test Cognitive Health Metrics System
"""

import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.monitoring.health_metrics import CognitiveHealthMonitor


def test_health_metrics():
    """Test comprehensive health metrics calculation."""
    
    print("="*80)
    print("COGNITIVE HEALTH METRICS TEST")
    print("="*80)
    
    # Initialize monitor
    monitor = CognitiveHealthMonitor()
    print("\n✓ Health monitor initialized")
    
    # Test data - simulate a moderately healthy system
    test_data = {
        # Epistemic Integrity
        "total_beliefs": 100,
        "verified_beliefs": 75,
        "contradicted_beliefs": 15,
        "evidence_quality_avg": 0.72,
        
        # Contradiction Handling
        "total_contradictions": 20,
        "resolved_contradictions": 16,
        "avg_resolution_time_hours": 18,
        "suppression_incidents": 2,
        
        # Calibration (sample predictions)
        "predictions": [
            {"confidence": 0.9}, {"confidence": 0.85}, {"confidence": 0.7},
            {"confidence": 0.6}, {"confidence": 0.5}, {"confidence": 0.4},
            {"confidence": 0.3}, {"confidence": 0.8}, {"confidence": 0.75},
            {"confidence": 0.65}, {"confidence": 0.55}, {"confidence": 0.45}
        ],
        "actual_outcomes": [
            True, True, True, False, True, False,
            False, True, True, False, True, False
        ],
        
        # Causal Robustness
        "total_causal_claims": 50,
        "validated_claims": 35,
        "refuted_claims": 8,
        "avg_causal_depth": 0.68,
        
        # Diversity
        "total_theories": 30,
        "unique_perspectives": 12,
        "minority_theories_retained": 8,
        "consensus_dominance_ratio": 0.45,
        
        # Recovery
        "total_failures": 15,
        "successful_recoveries": 13,
        "avg_recovery_time_hours": 8,
        "repeated_failures": 2,
        
        # Uncertainty
        "uncertain_predictions": 25,
        "total_predictions": 100,
        "uncertainty_appropriateness": 0.75
    }
    
    print("\nGenerating health report...")
    report = monitor.generate_health_report(test_data)
    
    print(f"\n{'='*80}")
    print(f"HEALTH REPORT SUMMARY")
    print(f"{'='*80}")
    print(f"\nOverall Health Score: {report.overall_health_score:.2f}")
    print(f"Health Status: {report.health_status.upper()}")
    print(f"Health Trend: {report.health_trend}")
    
    print(f"\n{'='*80}")
    print(f"DIMENSION SCORES")
    print(f"{'='*80}")
    
    for dim, metric in report.dimensions.items():
        status_icon = "✓" if metric.score >= 0.7 else "⚠" if metric.score >= 0.5 else "✗"
        print(f"\n{status_icon} {dim.value.replace('_', ' ').title()}")
        print(f"   Score: {metric.score:.2f} | Trend: {metric.trend}")
        if metric.warning_signals:
            print(f"   Warnings:")
            for warning in metric.warning_signals:
                print(f"     - {warning}")
    
    print(f"\n{'='*80}")
    print(f"WEAKEST & STRONGEST")
    print(f"{'='*80}")
    
    if report.weakest_dimension:
        weakest_metric = report.dimensions[report.weakest_dimension]
        print(f"\nWeakest: {report.weakest_dimension.value.replace('_', ' ').title()} ({weakest_metric.score:.2f})")
    
    if report.strongest_dimension:
        strongest_metric = report.dimensions[report.strongest_dimension]
        print(f"Strongest: {report.strongest_dimension.value.replace('_', ' ').title()} ({strongest_metric.score:.2f})")
    
    if report.active_alerts:
        print(f"\n{'='*80}")
        print(f"ACTIVE ALERTS ({len(report.active_alerts)})")
        print(f"{'='*80}")
        for alert in report.active_alerts:
            print(f"\n[{alert['severity'].upper()}] {alert['message']}")
    
    if report.recommendations:
        print(f"\n{'='*80}")
        print(f"RECOMMENDATIONS")
        print(f"{'='*80}")
        for i, rec in enumerate(report.recommendations, 1):
            print(f"\n{i}. {rec}")
    
    # Test health summary
    print(f"\n{'='*80}")
    print(f"HEALTH SUMMARY (for dashboard)")
    print(f"{'='*80}")
    
    summary = monitor.get_health_summary()
    print(f"\nStatus: {summary.get('status', 'N/A')}")
    print(f"Overall Score: {summary.get('overall_score', 0):.2f}")
    print(f"Trend: {summary.get('trend', 'N/A')}")
    print(f"Active Alerts: {summary.get('alerts', 0)}")
    
    print(f"\n{'='*80}")
    print("TEST COMPLETE ✅")
    print(f"{'='*80}\n")
    
    return report


if __name__ == "__main__":
    test_health_metrics()
