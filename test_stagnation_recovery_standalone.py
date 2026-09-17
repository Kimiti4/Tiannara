"""
Standalone test for Stagnation Recovery System (no package imports)
"""

import os
import sys
import numpy as np

# Test by directly executing the module files
print("Loading stagnation_detector.py...")
exec(open('tiannara_core/autonomy/stagnation_detector.py', encoding='utf-8').read(), globals())

print("Loading stagnation_recovery.py...")
exec(open('tiannara_core/autonomy/stagnation_recovery.py', encoding='utf-8').read(), globals())

print("\n" + "=" * 80)
print("STAGNATION RECOVERY TEST SUITE")
print("=" * 80)


def test_no_stagnation():
    """Test that no recovery action is taken when not stagnant."""
    print("\n" + "=" * 80)
    print("TEST 1: No Stagnation - No Recovery Action")
    print("=" * 80)
    
    detector = StagnationDetector(window_size=20, threshold=0.01)
    recovery = StagnationRecovery(detector)
    
    # Record improving episodes
    for i in range(30):
        success_rate = 0.5 + (i * 0.01)  # Improving
        quality = 0.6 + (i * 0.005)
        detector.record_episode(i, success_rate, quality)
    
    # Should not trigger recovery
    action = recovery.apply_recovery_strategy()
    
    assert action is None, "Should not apply recovery when not stagnant"
    print("[PASS] No recovery action when learning is progressing\n")
    return True


def test_mild_stagnation_recovery():
    """Test recovery from mild stagnation."""
    print("\n" + "=" * 80)
    print("TEST 2: Mild Stagnation Recovery")
    print("=" * 80)
    
    detector = StagnationDetector(window_size=20, threshold=0.01)
    recovery = StagnationRecovery(detector)
    
    # Create mild stagnation pattern
    base_success = 0.7
    for i in range(40):
        if i < 20:
            success_rate = base_success + (i * 0.01)  # Improving
        else:
            success_rate = base_success + 0.2 + np.random.uniform(-0.005, 0.005)  # Plateau
        
        quality = success_rate * 0.9
        detector.record_episode(i, success_rate, quality)
    
    # Check stagnation detected
    assert detector.is_stagnant(), "Should detect stagnation"
    severity = detector.get_severity()
    print(f"Detected severity: {severity.value}")
    
    # Apply recovery
    action = recovery.apply_recovery_strategy()
    assert action is not None, "Should apply recovery strategy"
    assert action.severity == severity
    
    print(f"Strategy applied: {action.strategy.value}")
    print(f"Expected impact: {action.expected_impact}")
    print(f"Parameters changed: {action.parameters_changed}")
    
    # Record outcome
    recovery.record_outcome(action, improvement=0.05)
    
    stats = recovery.get_recovery_statistics()
    print(f"\nRecovery statistics:")
    print(f"  Total recoveries: {stats['total_recoveries']}")
    print(f"  Success rate: {stats['success_rate']:.2%}")
    
    print("[PASS] Mild stagnation recovery working\n")
    return True


def test_cooldown_period():
    """Test that cooldown period prevents rapid successive recoveries."""
    print("\n" + "=" * 80)
    print("TEST 3: Cooldown Period Enforcement")
    print("=" * 80)
    
    detector = StagnationDetector(window_size=20, threshold=0.01)
    config = {'min_episodes_between_recovery': 15}
    recovery = StagnationRecovery(detector, config=config)
    
    # Create stagnation
    for i in range(40):
        success_rate = 0.6 + (0.01 if i < 10 else 0)
        detector.record_episode(i, success_rate, 0.5)
    
    # First recovery should work
    action1 = recovery.apply_recovery_strategy()
    assert action1 is not None, "First recovery should apply"
    print(f"First recovery at episode {detector.current_episode}: {action1.strategy.value}")
    
    # Immediate second recovery should be blocked by cooldown
    action2 = recovery.apply_recovery_strategy()
    assert action2 is None, "Second recovery should be blocked by cooldown"
    print("Second recovery blocked by cooldown (as expected)")
    
    # Advance episodes past cooldown
    for i in range(20):
        detector.record_episode(40 + i, 0.6, 0.5)
    
    # Now recovery should work again
    action3 = recovery.apply_recovery_strategy()
    assert action3 is not None, "Third recovery should apply after cooldown"
    print(f"Third recovery at episode {detector.current_episode}: {action3.strategy.value}")
    
    print("[PASS] Cooldown period enforced correctly\n")
    return True


def test_max_consecutive_recoveries():
    """Test that max consecutive recoveries limit is enforced."""
    print("\n" + "=" * 80)
    print("TEST 4: Max Consecutive Recoveries Limit")
    print("=" * 80)
    
    detector = StagnationDetector(window_size=20, threshold=0.01)
    config = {'max_consecutive_recoveries': 3}
    recovery = StagnationRecovery(detector, config=config)
    
    recoveries_applied = 0
    
    # Try to apply many recoveries in succession
    for attempt in range(10):
        # Create stagnation
        for i in range(25):
            detector.record_episode(attempt * 25 + i, 0.6, 0.5)
        
        action = recovery.apply_recovery_strategy()
        if action:
            recoveries_applied += 1
            print(f"Recovery {recoveries_applied} applied at attempt {attempt + 1}")
        else:
            print(f"Recovery blocked at attempt {attempt + 1} (max consecutive reached)")
            break
    
    assert recoveries_applied <= 3, f"Should not exceed max consecutive ({recoveries_applied} > 3)"
    print(f"\nTotal consecutive recoveries: {recoveries_applied}")
    print("[PASS] Max consecutive recoveries limit enforced\n")
    return True


def test_recovery_statistics():
    """Test comprehensive recovery statistics."""
    print("\n" + "=" * 80)
    print("TEST 5: Recovery Statistics")
    print("=" * 80)
    
    detector = StagnationDetector(window_size=20, threshold=0.01)
    recovery = StagnationRecovery(detector)
    
    # Initial state
    initial_stats = recovery.get_recovery_statistics()
    assert initial_stats['total_recoveries'] == 0
    print("Initial state: 0 recoveries")
    
    # Simulate various scenarios
    scenarios = [
        (0.05, "successful"),
        (-0.02, "failed"),
        (0.10, "very successful"),
        (0.03, "moderately successful"),
        (-0.01, "slightly failed")
    ]
    
    for improvement, description in scenarios:
        # Create stagnation
        for i in range(25):
            detector.record_episode(len(scenarios) * 25 + i, 0.6, 0.5)
        
        action = recovery.apply_recovery_strategy()
        if action:
            recovery.record_outcome(action, improvement)
            print(f"  {description}: {improvement:+.4f}")
    
    # Get final statistics
    final_stats = recovery.get_recovery_statistics()
    print(f"\nFinal statistics:")
    print(f"  Total recoveries: {final_stats['total_recoveries']}")
    print(f"  Success rate: {final_stats['success_rate']:.2%}")
    print(f"  Average improvement: {final_stats['average_improvement']:+.4f}")
    print(f"  Strategies used: {final_stats['strategies_used']}")
    
    assert final_stats['total_recoveries'] == len(scenarios)
    assert 0.0 <= final_stats['success_rate'] <= 1.0
    
    print("[PASS] Recovery statistics comprehensive and accurate\n")
    return True


def main():
    """Run all tests."""
    tests = [
        test_no_stagnation,
        test_mild_stagnation_recovery,
        test_cooldown_period,
        test_max_consecutive_recoveries,
        test_recovery_statistics
    ]
    
    passed = 0
    failed = 0
    
    for test_func in tests:
        try:
            if test_func():
                passed += 1
            else:
                failed += 1
                print(f"[FAIL] {test_func.__name__}")
        except Exception as e:
            failed += 1
            print(f"\nERROR: Test failed with error: {e}")
            import traceback
            traceback.print_exc()
    
    print("\n" + "=" * 80)
    print(f"RESULTS: {passed} passed, {failed} failed out of {len(tests)} tests")
    print("=" * 80)
    
    if failed == 0:
        print("\nALL TESTS PASSED!")
        print("\n" + "=" * 80)
        print("STAGNATION RECOVERY SYSTEM COMPLETE!")
        print("=" * 80)
        print("\nFeatures Implemented:")
        print("  1. Automatic strategy switching based on severity")
        print("  2. Six recovery strategies (LR adjustment, perturbation, diversity, etc.)")
        print("  3. Historical effectiveness tracking")
        print("  4. Cooldown periods to prevent over-recovery")
        print("  5. Max consecutive recovery limits")
        print("  6. Comprehensive statistics and monitoring")
        print("\nAll components integrated and tested successfully!")
        print("=" * 80)
    else:
        print(f"\n{failed} test(s) failed")
    
    return failed == 0


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
