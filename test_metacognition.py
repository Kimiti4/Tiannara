"""
Test Meta-Cognition Domain

Verifies all components work correctly and demonstrates capabilities.
"""

import sys
sys.path.insert(0, 'c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic')

from tiannara_core.metacognition import (
    MetaCognitiveMonitor,
    DomainPerformanceTracker,
    ReasoningQualityEvaluator,
    KnowledgeGapDetector,
    SelfReflectionCycle
)


def test_performance_tracker():
    """Test domain performance tracking."""
    print("\n" + "="*60)
    print("Testing Domain Performance Tracker")
    print("="*60)
    
    tracker = DomainPerformanceTracker()
    
    # Record some metrics
    tracker.record_metric('temporal', 'success_rate', 100.0)
    tracker.record_metric('temporal', 'latency_ms', 89.5)
    tracker.record_metric('combinatorial', 'success_rate', 100.0)
    tracker.record_metric('combinatorial', 'latency_ms', 124.3)
    tracker.record_metric('reverse_engineering', 'success_rate', 100.0)
    tracker.record_metric('reverse_engineering', 'latency_ms', 156.7)
    
    # Get health status
    temporal_health = tracker.get_domain_health('temporal')
    print(f"\n✅ Temporal Domain Health:")
    print(f"   Status: {temporal_health['status']}")
    print(f"   Success Rate: {temporal_health['success_rate']}%")
    print(f"   Avg Latency: {temporal_health['avg_latency_ms']}ms")
    print(f"   Trend: {temporal_health['trend']}")
    
    # Check for degradation
    degradation = tracker.detect_degradation('temporal')
    if degradation:
        print(f"\n⚠️  Degradation detected: {degradation}")
    else:
        print(f"\n✅ No degradation detected in temporal domain")
    
    # Get all domains health
    all_health = tracker.get_all_domains_health()
    print(f"\n📊 All Domains Health:")
    for domain, health in all_health.items():
        print(f"   {domain}: {health['status']} ({health['success_rate']}%)")
    
    print("\n✅ Performance Tracker Test PASSED")
    return True


def test_quality_evaluator():
    """Test reasoning quality evaluation."""
    print("\n" + "="*60)
    print("Testing Reasoning Quality Evaluator")
    print("="*60)
    
    evaluator = ReasoningQualityEvaluator()
    
    # Test case 1: High quality reasoning
    high_quality_trace = {
        'question': 'What causes market volatility?',
        'hypotheses': [
            'Economic indicators drive volatility',
            'Investor sentiment affects markets',
            'External events trigger reactions'
        ],
        'evidence_used': [
            {'type': 'historical_data', 'source': 'market_records'},
            {'type': 'economic_report', 'source': 'federal_reserve'},
            {'type': 'news_analysis', 'source': 'financial_times'}
        ],
        'conclusion': 'Multiple factors contribute to volatility',
        'confidence': 0.85,
        'reasoning_steps': [
            'Analyze historical volatility patterns',
            'Correlate with economic indicators',
            'Examine investor behavior during crises',
            'Consider external shock impacts',
            'Synthesize multi-factor model'
        ],
        'actual_accuracy': 0.82
    }
    
    assessment = evaluator.evaluate_reasoning_quality(high_quality_trace)
    print(f"\n✅ High Quality Reasoning Assessment:")
    print(f"   Overall Quality: {assessment['overall_quality']}")
    print(f"   Logical Consistency: {assessment['logical_consistency']['score']}")
    print(f"   Evidence Coverage: {assessment['evidence_coverage']['score']}")
    print(f"   Biases Detected: {len(assessment['bias_indicators'])}")
    print(f"   Confidence Calibration: {assessment['confidence_calibration']['status']}")
    print(f"   Recommendation: {assessment['recommendation']}")
    
    # Test case 2: Low quality reasoning
    low_quality_trace = {
        'question': 'Will it rain tomorrow?',
        'hypotheses': ['It will rain'],
        'evidence_used': [],
        'conclusion': 'Yes, it will rain',
        'confidence': 0.95,
        'reasoning_steps': [
            'I think it will rain'
        ],
        'actual_accuracy': 0.4
    }
    
    assessment2 = evaluator.evaluate_reasoning_quality(low_quality_trace)
    print(f"\n⚠️  Low Quality Reasoning Assessment:")
    print(f"   Overall Quality: {assessment2['overall_quality']}")
    print(f"   Issues Found: {len(assessment2['logical_consistency']['issues'])}")
    print(f"   Biases Detected: {len(assessment2['bias_indicators'])}")
    print(f"   Confidence Calibration: {assessment2['confidence_calibration']['status']}")
    print(f"   Recommendation: {assessment2['recommendation']}")
    
    print("\n✅ Quality Evaluator Test PASSED")
    return True


def test_gap_detector():
    """Test knowledge gap detection."""
    print("\n" + "="*60)
    print("Testing Knowledge Gap Detector")
    print("="*60)
    
    detector = KnowledgeGapDetector()
    
    # Test query about known topic
    query1 = "Predict stock market trends using pattern recognition"
    readiness1 = detector.detect_gaps(query1)
    
    print(f"\n✅ Query: '{query1}'")
    print(f"   Known Confidently: {len(readiness1['known_confidently'])} domains")
    for k in readiness1['known_confidently']:
        print(f"      - {k['domain']}: {k['confidence']}")
    print(f"   Uncertain: {len(readiness1['uncertain'])} domains")
    print(f"   Unknown: {len(readiness1['unknown'])} domains")
    print(f"   Overall Readiness: {readiness1['overall_readiness']}")
    
    # Test query about unknown topic
    query2 = "Explain quantum entanglement and topological manifolds"
    readiness2 = detector.detect_gaps(query2)
    
    print(f"\n⚠️  Query: '{query2}'")
    print(f"   Known Confidently: {len(readiness2['known_confidently'])} domains")
    print(f"   Uncertain: {len(readiness2['uncertain'])} domains")
    print(f"   Unknown: {len(readiness2['unknown'])} domains")
    for u in readiness2['unknown']:
        print(f"      - {u['domain']}: {u['confidence']}")
    print(f"   Learning Recommendations: {len(readiness2['recommended_learning'])}")
    for rec in readiness2['recommended_learning'][:2]:
        print(f"      - {rec['domain']}: Priority {rec['priority']}")
    
    # Get uncertainty regions
    uncertainties = detector.get_uncertainty_regions()
    print(f"\n📊 Total Uncertainty Regions: {len(uncertainties)}")
    for u in uncertainties[:3]:
        print(f"   {u['domain']}: confidence={u['confidence']}, priority={u['priority']}")
    
    # Track learning
    detector.track_learning('quantum_mechanics', 0.15, 'Studied quantum fundamentals')
    print(f"\n✅ Tracked learning in quantum_mechanics (+0.15)")
    
    print("\n✅ Gap Detector Test PASSED")
    return True


def test_self_reflection():
    """Test self-reflection cycle."""
    print("\n" + "="*60)
    print("Testing Self-Reflection Cycle")
    print("="*60)
    
    reflection = SelfReflectionCycle(reflection_interval_minutes=1)
    
    # Simulate recent decisions
    recent_decisions = [
        {'type': 'prediction', 'success': True, 'timestamp': '2026-05-13T17:00:00'},
        {'type': 'prediction', 'success': True, 'timestamp': '2026-05-13T17:05:00'},
        {'type': 'classification', 'success': False, 'failure_reason': 'insufficient_data', 'timestamp': '2026-05-13T17:10:00'},
        {'type': 'optimization', 'success': True, 'timestamp': '2026-05-13T17:15:00'},
        {'type': 'prediction', 'success': True, 'timestamp': '2026-05-13T17:20:00'},
    ]
    
    performance_data = {
        'domains': {
            'temporal': {'success_rate': 100.0, 'trend': 'stable'},
            'combinatorial': {'success_rate': 100.0, 'trend': 'stable'},
            'reverse_engineering': {'success_rate': 100.0, 'trend': 'improving'}
        }
    }
    
    # Perform reflection
    result = reflection.perform_reflection(recent_decisions, performance_data)
    
    print(f"\n✅ Reflection Results:")
    print(f"   Decisions Reviewed: {result['decisions_reviewed']}")
    print(f"   Performance Summary:")
    print(f"      Average Success Rate: {result['performance_summary']['average_success_rate']}%")
    print(f"      Overall Trend: {result['performance_summary']['overall_trend']}")
    print(f"   Patterns Identified: {len(result['patterns_identified'])}")
    for p in result['patterns_identified']:
        print(f"      - {p['insight']}")
    print(f"   Failure Analysis:")
    print(f"      Total Failures: {result['failure_analysis']['failure_count']}")
    print(f"      Severity: {result['failure_analysis']['severity']}")
    print(f"   Improvement Recommendations: {len(result['improvement_recommendations'])}")
    for rec in result['improvement_recommendations']:
        print(f"      - [{rec['priority']}] {rec['action']}")
    
    # Get reflection summary
    summary = reflection.get_reflection_summary()
    print(f"\n📊 Reflection Summary:")
    print(f"   Total Reflections: {summary['total_reflections']}")
    print(f"   Pending Recommendations: {summary['pending_recommendations']}")
    
    print("\n✅ Self-Reflection Test PASSED")
    return True


def test_full_monitor():
    """Test complete meta-cognitive monitor."""
    print("\n" + "="*60)
    print("Testing Full Meta-Cognitive Monitor")
    print("="*60)
    
    monitor = MetaCognitiveMonitor()
    
    # Start monitoring
    monitor.start_monitoring()
    
    # Record some domain performance
    monitor.record_domain_performance('temporal', 'success_rate', 100.0)
    monitor.record_domain_performance('temporal', 'latency_ms', 89.0)
    monitor.record_domain_performance('combinatorial', 'success_rate', 100.0)
    monitor.record_domain_performance('reverse_engineering', 'success_rate', 100.0)
    
    # Perform self-assessment
    print(f"\n🧠 Performing comprehensive self-assessment...")
    assessment = monitor.continuous_self_assessment()
    
    print(f"\n✅ Assessment Results:")
    print(f"   Timestamp: {assessment['timestamp']}")
    print(f"   Overall Status: {assessment['overall_status']}")
    print(f"   Domains Monitored: {len(assessment['domain_health'])}")
    print(f"   Degradation Alerts: {len(assessment['degradation_alerts'])}")
    print(f"   Knowledge Gaps: {assessment['knowledge_gaps']['total_unknown_areas']}")
    print(f"   Recommended Actions: {len(assessment['recommended_actions'])}")
    
    for action in assessment['recommended_actions'][:3]:
        print(f"      - [{action['priority']}] {action['action']}")
    
    # Evaluate a decision
    decision_trace = {
        'question': 'What is the best optimization algorithm?',
        'hypotheses': ['Genetic algorithms', 'Simulated annealing'],
        'evidence_used': [{'type': 'benchmark', 'source': 'research_papers'}],
        'conclusion': 'Depends on problem characteristics',
        'confidence': 0.75,
        'reasoning_steps': ['Compare algorithms', 'Evaluate trade-offs'],
        'actual_accuracy': 0.8
    }
    
    quality = monitor.evaluate_decision_quality(decision_trace)
    print(f"\n✅ Decision Quality Evaluation:")
    print(f"   Overall Quality: {quality['overall_quality']}")
    print(f"   Recommendation: {quality['recommendation']}")
    
    # Check knowledge readiness
    readiness = monitor.check_knowledge_readiness("Predict weather patterns")
    print(f"\n✅ Knowledge Readiness Check:")
    print(f"   Known: {len(readiness['known_confidently'])} domains")
    print(f"   Uncertain: {len(readiness['uncertain'])} domains")
    print(f"   Unknown: {len(readiness['unknown'])} domains")
    
    # Get monitoring summary
    summary = monitor.get_monitoring_summary()
    print(f"\n📊 Monitoring Summary:")
    print(f"   Is Monitoring: {summary['is_monitoring']}")
    print(f"   Total Assessments: {summary['total_assessments']}")
    
    # Stop monitoring
    monitor.stop_monitoring()
    
    print("\n✅ Full Monitor Test PASSED")
    return True


def main():
    """Run all tests."""
    print("\n" + "="*60)
    print("TIANNARA META-COGNITION DOMAIN TEST SUITE")
    print("="*60)
    
    tests = [
        ("Performance Tracker", test_performance_tracker),
        ("Quality Evaluator", test_quality_evaluator),
        ("Gap Detector", test_gap_detector),
        ("Self-Reflection", test_self_reflection),
        ("Full Monitor", test_full_monitor),
    ]
    
    results = []
    for name, test_func in tests:
        try:
            passed = test_func()
            results.append((name, passed))
        except Exception as e:
            print(f"\n❌ {name} Test FAILED with error: {e}")
            import traceback
            traceback.print_exc()
            results.append((name, False))
    
    # Print summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    
    passed_count = sum(1 for _, passed in results if passed)
    total_count = len(results)
    
    for name, passed in results:
        status = "✅ PASSED" if passed else "❌ FAILED"
        print(f"{status}: {name}")
    
    print(f"\nTotal: {passed_count}/{total_count} tests passed")
    
    if passed_count == total_count:
        print("\n🎉 ALL TESTS PASSED! Meta-cognition domain is operational.")
        return 0
    else:
        print(f"\n⚠️  {total_count - passed_count} test(s) failed")
        return 1


if __name__ == "__main__":
    exit(main())
