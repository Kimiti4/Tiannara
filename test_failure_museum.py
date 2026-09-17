"""
TEST SUITE FOR FAILURE MUSEUM SYSTEM

Validates:
1. Failure archiving and retrieval
2. Search by type, domain, and tags
3. Similarity detection (preventive warnings)
4. Failure replay for learning reinforcement
5. Museum tour functionality
6. Statistics and analytics
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from tiannara_core.monitoring.failure_museum import (
    FailureMuseum,
    FailureRecord,
    FailureType
)


def test_failure_archiving():
    """Test: Can archive and retrieve failure records?"""
    print("\n" + "="*70)
    print("TEST 1: Failure Archiving and Retrieval")
    print("="*70)
    
    museum = FailureMuseum()
    
    # Archive a failed theory
    failed_theory = FailureRecord(
        failure_id="theory_001",
        failure_type=FailureType.FAILED_THEORY,
        title="Correlation-Only Prediction Model",
        description="Theory that relied solely on statistical correlation without causal mechanisms. Failed when distribution shifted.",
        domain="prediction",
        initial_confidence=0.85,
        failure_severity=0.7,
        supporting_evidence=[
            "Strong historical correlation (r=0.92)",
            "High predictive accuracy on training data"
        ],
        contradicting_evidence=[
            "Failed completely on out-of-distribution test cases",
            "No mechanistic explanation for observed patterns"
        ],
        failure_trigger="Distribution shift in production environment",
        root_cause="Overfitting to spurious correlations without understanding underlying mechanisms",
        lesson_learned="Always require causal justification, not just statistical fit",
        prevention_strategy="Use causal depth scoring alongside predictive accuracy",
        tags=["correlation", "overfitting", "distribution_shift"]
    )
    
    museum.archive_failure(failed_theory)
    
    # Retrieve and verify
    retrieved = museum.get_failure("theory_001")
    assert retrieved is not None, "Failed to retrieve archived failure"
    assert retrieved.title == failed_theory.title, "Title mismatch"
    assert retrieved.failure_severity == 0.7, "Severity mismatch"
    
    print(f"   [PASS] Archived failure: {retrieved.title}")
    print(f"   [PASS] Failure type: {retrieved.failure_type.value}")
    print(f"   [PASS] Severity: {retrieved.failure_severity}")
    print(f"   [PASS] Lesson: {retrieved.lesson_learned[:60]}...")
    
    return True


def test_search_functionality():
    """Test: Can search failures by type, domain, and tags?"""
    print("\n" + "="*70)
    print("TEST 2: Search Functionality")
    print("="*70)
    
    museum = FailureMuseum()
    
    # Archive multiple failures across types and domains
    failures = [
        FailureRecord(
            failure_id=f"fail_{i}",
            failure_type=ft,
            title=f"{ft.value.replace('_', ' ').title()} Example {i}",
            description=f"Test failure of type {ft.value}",
            domain=domain,
            failure_severity=0.5 + i * 0.1,
            tags=[domain, ft.value, f"test_{i}"]
        )
        for i, (ft, domain) in enumerate([
            (FailureType.FAILED_THEORY, "prediction"),
            (FailureType.REWARD_HACK, "optimization"),
            (FailureType.DECEPTIVE_SHORTCUT, "reasoning"),
            (FailureType.HALLUCINATED_CAUSALITY, "causal_inference"),
            (FailureType.BAD_SYNTHESIS, "integration"),
        ])
    ]
    
    for failure in failures:
        museum.archive_failure(failure)
    
    # Test search by type
    reward_hacks = museum.search_by_type(FailureType.REWARD_HACK)
    assert len(reward_hacks) == 1, f"Expected 1 reward hack, got {len(reward_hacks)}"
    print(f"   [PASS] Search by type: Found {len(reward_hacks)} reward hack(s)")
    
    # Test search by domain
    prediction_failures = museum.search_by_domain("prediction")
    assert len(prediction_failures) == 1, f"Expected 1 prediction failure, got {len(prediction_failures)}"
    print(f"   [PASS] Search by domain: Found {len(prediction_failures)} prediction failure(s)")
    
    # Test search by tags
    tagged = museum.search_by_tags(["optimization", "reward_hack"])
    assert len(tagged) >= 1, f"Expected at least 1 tagged failure, got {len(tagged)}"
    print(f"   [PASS] Search by tags: Found {len(tagged)} matching failure(s)")
    
    return True


def test_similarity_detection():
    """Test: Can detect similar failures to prevent recurrence?"""
    print("\n" + "="*70)
    print("TEST 3: Similarity Detection (Preventive Warning)")
    print("="*70)
    
    museum = FailureMuseum()
    
    # Archive a known failure pattern
    museum.archive_failure(FailureRecord(
        failure_id="pattern_001",
        failure_type=FailureType.OVERCONFIDENCE_SPIKE,
        title="Premature Certainty Without Sufficient Evidence",
        description="System became overconfident after limited positive examples, ignoring contradictory signals.",
        domain="decision_making",
        failure_severity=0.8,
        tags=["overconfidence", "insufficient_evidence", "premature_conclusion"],
        lesson_learned="Require minimum evidence threshold before high confidence"
    ))
    
    # Simulate current situation approaching same pattern
    current_context = {
        'domain': 'decision_making',
        'tags': ['overconfidence', 'rapid_learning'],
        'description': 'Making quick decisions with limited data showing early success'
    }
    
    similar = museum.find_similar_failures(current_context, max_results=3)
    
    assert len(similar) > 0, "Should find at least one similar failure"
    assert similar[0][0].failure_id == "pattern_001", "Should match archived pattern"
    assert similar[0][1] > 0.3, f"Similarity score {similar[0][1]} too low"
    
    print(f"   [PASS] Found {len(similar)} similar failure(s)")
    print(f"   [PASS] Best match: {similar[0][0].title}")
    print(f"   [PASS] Similarity score: {similar[0][1]:.2f}")
    print(f"   [PASS] Warning: {similar[0][0].lesson_learned}")
    
    return True


def test_failure_replay():
    """Test: Can replay failures for learning reinforcement?"""
    print("\n" + "="*70)
    print("TEST 4: Failure Replay for Learning")
    print("="*70)
    
    museum = FailureMuseum()
    
    # Archive a failure
    museum.archive_failure(FailureRecord(
        failure_id="replay_test",
        failure_type=FailureType.COLLAPSED_REASONING,
        title="Circular Reasoning in Causal Chain",
        description="Reasoning chain contained circular dependency: A causes B, B causes C, C causes A.",
        domain="causal_reasoning",
        failure_severity=0.9,
        root_cause="Lack of cycle detection in reasoning graph",
        lesson_learned="Always validate acyclicity in causal chains",
        prevention_strategy="Implement topological sort validation before accepting causal claims"
    ))
    
    # Replay the failure
    replay = museum.replay_failure("replay_test")
    
    assert replay is not None, "Replay should return summary"
    assert replay['failure_id'] == "replay_test", "Wrong failure replayed"
    assert 'warning' in replay, "Replay should include warning"
    assert replay['times_replayed'] == 1, "Replay count should be 1"
    
    print(f"   [PASS] Replayed: {replay['title']}")
    print(f"   [PASS] Lesson: {replay['lesson']}")
    print(f"   [PASS] Prevention: {replay['prevention']}")
    print(f"   [PASS] Times replayed: {replay['times_replayed']}")
    
    # Replay again to verify counter increments
    replay2 = museum.replay_failure("replay_test")
    assert replay2['times_replayed'] == 2, "Replay count should increment"
    
    print(f"   [PASS] Second replay count: {replay2['times_replayed']}")
    
    return True


def test_museum_tour():
    """Test: Does museum tour provide curated learning experience?"""
    print("\n" + "="*70)
    print("TEST 5: Museum Tour (Curated Learning)")
    print("="*70)
    
    museum = FailureMuseum()
    
    # Archive diverse failures
    for i in range(8):
        ft = list(FailureType)[i % len(FailureType)]
        museum.archive_failure(FailureRecord(
            failure_id=f"tour_fail_{i}",
            failure_type=ft,
            title=f"Tour Example {i}: {ft.value}",
            description=f"Sample failure for museum tour testing",
            domain=f"domain_{i % 3}",
            failure_severity=0.3 + (i * 0.1),  # Varying severity
            tags=[f"tag_{i}"]
        ))
    
    # Conduct general tour (all types)
    tour_results = museum.conduct_museum_tour(max_failures=5)
    
    assert len(tour_results) <= 5, f"Tour should have at most 5 failures, got {len(tour_results)}"
    assert len(tour_results) > 0, "Tour should have at least 1 failure"
    
    print(f"   [PASS] General tour included {len(tour_results)} failures")
    
    # Verify tours prioritize high-severity failures
    if len(tour_results) > 1:
        severities = [r['severity'] for r in tour_results]
        assert severities == sorted(severities, reverse=True), \
            "Tour should prioritize high-severity failures"
        print(f"   [PASS] Tour correctly prioritized high-severity failures")
    
    # Conduct type-specific tour
    type_tour = museum.conduct_museum_tour(
        failure_type=FailureType.REWARD_HACK,
        max_failures=3
    )
    
    print(f"   [PASS] Type-specific tour (REWARD_HACK): {len(type_tour)} failures")
    
    # Conduct domain-specific tour
    domain_tour = museum.conduct_museum_tour(
        domain="domain_0",
        max_failures=3
    )
    
    print(f"   [PASS] Domain-specific tour (domain_0): {len(domain_tour)} failures")
    
    return True


def test_statistics_and_analytics():
    """Test: Does statistics provide comprehensive museum analytics?"""
    print("\n" + "="*70)
    print("TEST 6: Statistics and Analytics")
    print("="*70)
    
    museum = FailureMuseum()
    
    # Archive diverse set of failures
    for i in range(15):
        ft = list(FailureType)[i % len(FailureType)]
        museum.archive_failure(FailureRecord(
            failure_id=f"stats_fail_{i}",
            failure_type=ft,
            title=f"Statistical Test Failure {i}",
            description=f"Failure for statistics testing",
            domain=f"domain_{i % 4}",
            failure_severity=0.2 + (i * 0.05),
            tags=[f"stats_tag_{i % 5}"]
        ))
    
    # Replay some failures
    museum.replay_failure("stats_fail_0")
    museum.replay_failure("stats_fail_0")  # Replay twice
    museum.replay_failure("stats_fail_1")
    
    # Get statistics
    stats = museum.get_statistics()
    
    assert stats['total_failures'] == 15, f"Expected 15 total failures, got {stats['total_failures']}"
    assert 'by_type' in stats, "Stats missing type breakdown"
    assert 'by_domain' in stats, "Stats missing domain breakdown"
    assert 'severity_distribution' in stats, "Stats missing severity distribution"
    assert stats['total_replays'] == 3, f"Expected 3 total replays, got {stats['total_replays']}"
    
    print(f"   [PASS] Total failures: {stats['total_failures']}")
    print(f"   [PASS] Total replays: {stats['total_replays']}")
    print(f"   [PASS] Never replayed: {stats['never_replayed']}")
    print(f"   [PASS] Failure types: {len(stats['by_type'])} categories")
    print(f"   [PASS] Domains: {len(stats['by_domain'])} domains")
    print(f"\n   Severity Distribution:")
    for level, count in stats['severity_distribution'].items():
        print(f"      {level}: {count}")
    
    return True


def test_persistence():
    """Test: Can save and load museum from disk?"""
    print("\n" + "="*70)
    print("TEST 7: Persistence (Save/Load)")
    print("="*70)
    
    import tempfile
    import json
    
    # Create temporary file
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        temp_path = f.name
    
    try:
        # Create museum and archive failures
        museum1 = FailureMuseum(storage_path=temp_path)
        
        museum1.archive_failure(FailureRecord(
            failure_id="persist_test",
            failure_type=FailureType.FAILED_THEORY,
            title="Persistence Test Failure",
            description="Testing save/load functionality",
            domain="testing",
            failure_severity=0.6,
            tags=["persistence", "test"]
        ))
        
        # Force save
        museum1._save_to_disk()
        
        # Verify file exists and has content
        assert os.path.exists(temp_path), "Persistence file not created"
        
        with open(temp_path, 'r') as f:
            data = json.load(f)
        
        assert 'failures' in data, "Saved data missing failures"
        assert 'persist_test' in data['failures'], "Saved data missing test failure"
        
        print(f"   [PASS] Saved {len(data['failures'])} failure(s) to disk")
        
        # Load into new museum instance
        museum2 = FailureMuseum(storage_path=temp_path)
        
        retrieved = museum2.get_failure("persist_test")
        assert retrieved is not None, "Failed to retrieve persisted failure"
        assert retrieved.title == "Persistence Test Failure", "Retrieved failure has wrong title"
        
        print(f"   [PASS] Loaded failure from disk: {retrieved.title}")
        print(f"   [PASS] Persistence round-trip successful")
        
    finally:
        # Cleanup
        if os.path.exists(temp_path):
            os.remove(temp_path)
    
    return True


def run_all_tests():
    """Execute all failure museum tests."""
    print("\n" + "="*70)
    print("FAILURE MUSEUM TEST SUITE")
    print("="*70)
    
    tests = [
        ("Failure Archiving and Retrieval", test_failure_archiving),
        ("Search Functionality", test_search_functionality),
        ("Similarity Detection", test_similarity_detection),
        ("Failure Replay", test_failure_replay),
        ("Museum Tour", test_museum_tour),
        ("Statistics and Analytics", test_statistics_and_analytics),
        ("Persistence", test_persistence),
    ]
    
    results = []
    for name, test_func in tests:
        try:
            passed = test_func()
            results.append((name, passed))
        except Exception as e:
            print(f"\n   [FAIL] {name}: {str(e)}")
            import traceback
            traceback.print_exc()
            results.append((name, False))
    
    # Summary
    print("\n" + "="*70)
    print("TEST SUMMARY")
    print("="*70)
    
    passed_count = sum(1 for _, passed in results if passed)
    total_count = len(results)
    
    for name, passed in results:
        status = "[PASS]" if passed else "[FAIL]"
        print(f"   {status} {name}")
    
    print(f"\n   Overall: {passed_count}/{total_count} tests passed")
    
    if passed_count == total_count:
        print("\n   [EXCELLENT] All failure museum tests passed!")
    else:
        print(f"\n   [WARNING] {total_count - passed_count} test(s) failed")
    
    return passed_count == total_count


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
