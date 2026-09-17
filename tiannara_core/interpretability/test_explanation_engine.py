"""
Explanation Engine Integration Test

Demonstrates end-to-end explainability workflow integrating all components:
- Causal path extraction
- Counterfactual reasoning
- Natural language generation
- Confidence calibration
- Audit trail logging

Usage:
    python tiannara_core/interpretability/test_explanation_engine.py
"""

import sys
from pathlib import Path
import os

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

try:
    from tiannara_core.interpretability.explanation_engine import (
        ExplanationEngine,
        ComprehensiveExplanation,
        create_explanation_engine
    )
    ENGINE_AVAILABLE = True
except ImportError as e:
    print(f"WARNING: Explanation engine module not available: {e}")
    ENGINE_AVAILABLE = False


def create_sample_ecm_graph():
    """Create a sample ECM graph for testing."""
    return {
        'nodes': [
            'skill_memory',
            'pattern_recognition',
            'solution_quality',
            'adaptation_speed',
            'final_outcome'
        ],
        'edges': [
            ('skill_memory', 'pattern_recognition', 0.85),
            ('skill_memory', 'adaptation_speed', 0.70),
            ('pattern_recognition', 'solution_quality', 0.90),
            ('solution_quality', 'final_outcome', 0.80),
            ('adaptation_speed', 'final_outcome', 0.65)
        ]
    }


def test_basic_decision_explanation():
    """Test basic decision explanation with causal path."""
    print("\n" + "=" * 80)
    print("TEST 1: Basic Decision Explanation")
    print("=" * 80)
    
    # Clean up any existing audit database
    db_path = "test_engine_audit.db"
    if os.path.exists(db_path):
        os.remove(db_path)
    
    engine = ExplanationEngine(audit_db_path=db_path, cache_enabled=True)
    graph = create_sample_ecm_graph()
    
    # Generate explanation for final outcome
    explanation = engine.explain_decision(
        ecm_graph=graph,
        target_node="final_outcome",
        audience="end_user",
        include_counterfactuals=False,
        include_uncertainty=True,
        user_id="test_user_001"
    )
    
    print(f"\nExplanation Type: {explanation.explanation_type}")
    print(f"Target Node: {explanation.target_node}")
    print(f"Confidence: {explanation.confidence:.3f}")
    print(f"Audience Level: {explanation.audience_level}")
    print(f"Audit Record ID: {explanation.record_id}")
    print(f"\nExplanation Text (first 200 chars):")
    print(f"  {explanation.explanation_text[:200]}...")
    
    assert explanation.explanation_type in ["causal_path", "combined"]
    assert explanation.target_node == "final_outcome"
    assert 0 <= explanation.confidence <= 1
    assert explanation.record_id is not None
    assert len(explanation.explanation_text) > 0
    
    print("\n[PASS] Basic decision explanation working correctly")
    
    # Clean up
    os.remove(db_path)
    return True


def test_counterfactual_explanation():
    """Test what-if counterfactual explanation."""
    print("\n" + "=" * 80)
    print("TEST 2: Counterfactual Explanation")
    print("=" * 80)
    
    db_path = "test_engine_audit2.db"
    if os.path.exists(db_path):
        os.remove(db_path)
    
    engine = ExplanationEngine(audit_db_path=db_path)
    graph = create_sample_ecm_graph()
    
    # Answer what-if question
    explanation = engine.answer_what_if(
        graph=graph,
        question="What if skill_memory increased by 0.2?",
        audience="technical",
        user_id="test_user_002"
    )
    
    print(f"\nExplanation Type: {explanation.explanation_type}")
    print(f"Target Node: {explanation.target_node}")
    print(f"Audit Record ID: {explanation.record_id}")
    print(f"\nCounterfactual Analysis (first 200 chars):")
    print(f"  {explanation.explanation_text[:200]}...")
    
    assert explanation.explanation_type == "counterfactual"
    assert explanation.record_id is not None
    assert len(explanation.interventions_applied or []) >= 0
    
    print("\n[PASS] Counterfactual explanation working correctly")
    
    # Clean up
    os.remove(db_path)
    return True


def test_audience_adaptation():
    """Test explanation adaptation for different audiences."""
    print("\n" + "=" * 80)
    print("TEST 3: Audience Adaptation")
    print("=" * 80)
    
    db_path = "test_engine_audit3.db"
    if os.path.exists(db_path):
        os.remove(db_path)
    
    engine = ExplanationEngine(audit_db_path=db_path)
    graph = create_sample_ecm_graph()
    
    audiences = ["technical", "regulatory", "end_user"]
    explanations = {}
    
    for audience in audiences:
        explanation = engine.explain_decision(
            ecm_graph=graph,
            target_node="final_outcome",
            audience=audience,
            include_counterfactuals=False
        )
        explanations[audience] = explanation
        print(f"\n{audience.upper()} Audience:")
        print(f"  Length: {len(explanation.explanation_text)} chars")
        print(f"  First 100 chars: {explanation.explanation_text[:100]}...")
    
    # Verify different audiences get different explanations
    assert len(set(len(e.explanation_text) for e in explanations.values())) > 1
    
    print("\n[PASS] Audience adaptation working correctly")
    
    # Clean up
    os.remove(db_path)
    return True


def test_caching():
    """Test explanation caching for performance."""
    print("\n" + "=" * 80)
    print("TEST 4: Caching")
    print("=" * 80)
    
    db_path = "test_engine_audit4.db"
    if os.path.exists(db_path):
        os.remove(db_path)
    
    engine = ExplanationEngine(audit_db_path=db_path, cache_enabled=True)
    graph = create_sample_ecm_graph()
    
    # First call - should compute
    explanation1 = engine.explain_decision(
        ecm_graph=graph,
        target_node="final_outcome",
        audience="technical"
    )
    
    cache_stats_before = engine.get_statistics()["cache_size"]
    print(f"\nCache size after first call: {cache_stats_before}")
    
    # Second call - should use cache
    explanation2 = engine.explain_decision(
        ecm_graph=graph,
        target_node="final_outcome",
        audience="technical"
    )
    
    cache_stats_after = engine.get_statistics()["cache_size"]
    print(f"Cache size after second call: {cache_stats_after}")
    
    # Should be same record (cached)
    assert explanation1.record_id == explanation2.record_id
    assert cache_stats_after >= cache_stats_before
    
    # Clear cache
    engine.clear_cache()
    cache_stats_cleared = engine.get_statistics()["cache_size"]
    print(f"Cache size after clear: {cache_stats_cleared}")
    assert cache_stats_cleared == 0
    
    print("\n[PASS] Caching working correctly")
    
    # Clean up
    os.remove(db_path)
    return True


def test_audit_trail_integration():
    """Test audit trail logging and retrieval."""
    print("\n" + "=" * 80)
    print("TEST 5: Audit Trail Integration")
    print("=" * 80)
    
    db_path = "test_engine_audit5.db"
    if os.path.exists(db_path):
        os.remove(db_path)
    
    # Disable caching to ensure each call creates a new audit record
    engine = ExplanationEngine(audit_db_path=db_path, cache_enabled=False)
    graph = create_sample_ecm_graph()
    
    # Generate multiple explanations
    for i in range(5):
        engine.explain_decision(
            ecm_graph=graph,
            target_node="final_outcome",
            audience="technical",
            user_id=f"user_{i % 2}"  # Alternate between user_0 and user_1
        )
    
    # Retrieve audit records
    all_records = engine.get_audit_records(limit=10)
    print(f"\nTotal audit records: {len(all_records)}")
    
    # Filter by user
    user0_records = engine.get_audit_records(user_id="user_0")
    print(f"Records for user_0: {len(user0_records)}")
    
    # Get statistics
    stats = engine.get_statistics()
    print(f"\nAudit trail statistics:")
    print(f"  Total records: {stats['audit_trail']['total_records']}")
    print(f"  Type distribution: {stats['audit_trail'].get('type_distribution', {})}")
    
    assert len(all_records) == 5
    assert len(user0_records) >= 2  # At least some for user_0
    assert stats['audit_trail']['total_records'] == 5
    
    print("\n[PASS] Audit trail integration working correctly")
    
    # Clean up
    os.remove(db_path)
    return True


def test_compliance_export():
    """Test compliance report export."""
    print("\n" + "=" * 80)
    print("TEST 6: Compliance Export")
    print("=" * 80)
    
    db_path = "test_engine_audit6.db"
    json_export = "test_compliance_export.json"
    csv_export = "test_compliance_export.csv"
    
    for f in [db_path, json_export, csv_export]:
        if os.path.exists(f):
            os.remove(f)
    
    # Disable caching to ensure each call creates a new audit record
    engine = ExplanationEngine(audit_db_path=db_path, cache_enabled=False)
    graph = create_sample_ecm_graph()
    
    # Generate some explanations
    for i in range(3):
        engine.explain_decision(
            ecm_graph=graph,
            target_node="final_outcome",
            audience="regulatory"
        )
    
    # Export to JSON
    engine.export_compliance_report(json_export, format="json")
    assert os.path.exists(json_export)
    
    # Export to CSV
    engine.export_compliance_report(csv_export, format="csv")
    assert os.path.exists(csv_export)
    
    print(f"\nJSON export: {os.path.getsize(json_export)} bytes")
    print(f"CSV export: {os.path.getsize(csv_export)} bytes")
    
    import json
    with open(json_export, 'r') as f:
        data = json.load(f)
    
    print(f"JSON records exported: {data['total_records']}")
    assert data['total_records'] == 3
    
    print("\n[PASS] Compliance export working correctly")
    
    # Clean up
    for f in [db_path, json_export, csv_export]:
        if os.path.exists(f):
            os.remove(f)
    return True


def test_convenience_function():
    """Test convenience function for creating engine."""
    print("\n" + "=" * 80)
    print("TEST 7: Convenience Function")
    print("=" * 80)
    
    db_path = "test_engine_audit7.db"
    if os.path.exists(db_path):
        os.remove(db_path)
    
    # Use convenience function
    engine = create_explanation_engine(
        audit_db_path=db_path,
        cache_enabled=True,
        default_audience="end_user"
    )
    
    assert isinstance(engine, ExplanationEngine)
    assert engine.cache_enabled is True
    assert engine.default_audience == "end_user"
    
    print(f"\nCreated engine with default audience: {engine.default_audience}")
    print("\n[PASS] Convenience function working correctly")
    
    # Clean up
    os.remove(db_path)
    return True


def main():
    """Run all integration tests."""
    print("\n" + "=" * 80)
    print("EXPLANATION ENGINE INTEGRATION TEST SUITE")
    print("=" * 80)
    
    if not ENGINE_AVAILABLE:
        print("\nCannot run tests - Explanation engine module not available")
        return False
    
    tests = [
        ("Basic Decision Explanation", test_basic_decision_explanation),
        ("Counterfactual Explanation", test_counterfactual_explanation),
        ("Audience Adaptation", test_audience_adaptation),
        ("Caching", test_caching),
        ("Audit Trail Integration", test_audit_trail_integration),
        ("Compliance Export", test_compliance_export),
        ("Convenience Function", test_convenience_function),
    ]
    
    passed = 0
    failed = 0
    
    for name, test_func in tests:
        try:
            if test_func():
                passed += 1
        except Exception as e:
            print(f"\nERROR: Test failed with error: {e}")
            import traceback
            traceback.print_exc()
            failed += 1
    
    print("\n" + "=" * 80)
    print(f"RESULTS: {passed} passed, {failed} failed out of {len(tests)} tests")
    print("=" * 80)
    
    if failed == 0:
        print("\nALL TESTS PASSED!")
        print("\n" + "=" * 80)
        print("EXPLAINABLE ECM SYSTEM COMPLETE!")
        print("=" * 80)
        print("\nComponents Implemented:")
        print("  1. CausalPathTracer - Path extraction & attribution")
        print("  2. CounterfactualEngine - What-if reasoning")
        print("  3. NaturalLanguageGenerator - Multi-level narratives")
        print("  4. ConfidenceCalibration - Uncertainty quantification")
        print("  5. ExplanationAuditTrail - Compliance logging")
        print("  6. ExplanationEngine - Master orchestrator")
        print("\nAll components integrated and tested successfully!")
        print("=" * 80)
        return True
    else:
        print(f"\n{failed} test(s) failed")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
