"""Quick test of combinatorial, RE, and temporal domains."""

import sys
from pathlib import Path

project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

print("=" * 80)
print("DOMAIN STATUS CHECK - Combinatorial, RE, Temporal")
print("=" * 80)

# Test Combinatorial Domain
print("\n1. COMBINATORIAL DOMAIN")
print("-" * 80)
try:
    from tiannara_core.evaluation.test_suites.test_combinatorial_domain import CombinatorialDomainTestSuite
    suite = CombinatorialDomainTestSuite()
    
    tests = [
        ("Knapsack", suite.test_knapsack_problems),
        ("Traveling Salesman", suite.test_traveling_salesman),
        ("Graph Coloring", suite.test_graph_coloring),
        ("Scheduling", suite.test_scheduling_problems),
        ("Constraint Satisfaction", suite.test_constraint_satisfaction),
        ("Edge Cases", suite.test_edge_cases),
    ]
    
    total_passed = 0
    total_tests = 0
    
    for name, test_func in tests:
        result = test_func()
        total_passed += result['passed']
        total_tests += result['total']
        status = "PASS" if result['success_rate'] >= 99 else "FAIL"
        print(f"  {name:30s}: {result['success_rate']:6.2f}% ({result['passed']:3d}/{result['total']:3d}) {status}")
    
    overall_rate = (total_passed / total_tests * 100) if total_tests > 0 else 0
    print(f"\n  Overall: {overall_rate:.2f}% ({total_passed}/{total_tests})")
    print(f"  Status: {'100% COMPLIANT' if overall_rate >= 99 else 'BELOW TARGET'}")
    
except Exception as e:
    print(f"  ERROR: {e}")
    import traceback
    traceback.print_exc()

# Test Reverse Engineering Domain
print("\n2. REVERSE ENGINEERING DOMAIN")
print("-" * 80)
try:
    from tiannara_core.evaluation.test_suites.test_re_domain import ReverseEngineeringTestSuite
    suite = ReverseEngineeringTestSuite()
    
    tests = [
        ("Function Inference", suite.test_function_inference),
        ("Algorithm Recognition", suite.test_algorithm_recognition),
        ("Code Analysis", suite.test_code_analysis),
        ("Pattern Matching", suite.test_pattern_matching),
        ("Edge Cases", suite.test_edge_cases),
    ]
    
    total_passed = 0
    total_tests = 0
    
    for name, test_func in tests:
        result = test_func()
        total_passed += result['passed']
        total_tests += result['total']
        status = "PASS" if result['success_rate'] >= 99 else "FAIL"
        print(f"  {name:30s}: {result['success_rate']:6.2f}% ({result['passed']:3d}/{result['total']:3d}) {status}")
    
    overall_rate = (total_passed / total_tests * 100) if total_tests > 0 else 0
    print(f"\n  Overall: {overall_rate:.2f}% ({total_passed}/{total_tests})")
    print(f"  Status: {'100% COMPLIANT' if overall_rate >= 99 else 'BELOW TARGET'}")
    
except Exception as e:
    print(f"  ERROR: {e}")
    import traceback
    traceback.print_exc()

# Test Temporal Domain
print("\n3. TEMPORAL DOMAIN")
print("-" * 80)
try:
    from tiannara_core.evaluation.test_suites.test_temporal_domain import TemporalDomainTestSuite
    suite = TemporalDomainTestSuite()
    
    tests = [
        ("Time Series Forecasting", suite.test_time_series_forecasting),
        ("Anomaly Detection", suite.test_anomaly_detection),
        ("Change Point Detection", suite.test_change_point_detection),
        ("Seasonal Decomposition", suite.test_seasonal_decomposition),
        ("Pattern Recognition", suite.test_pattern_recognition),
        ("Edge Cases", suite.test_edge_cases),
    ]
    
    total_passed = 0
    total_tests = 0
    
    for name, test_func in tests:
        result = test_func()
        total_passed += result['passed']
        total_tests += result['total']
        status = "PASS" if result['success_rate'] >= 99 else "FAIL"
        print(f"  {name:30s}: {result['success_rate']:6.2f}% ({result['passed']:3d}/{result['total']:3d}) {status}")
    
    overall_rate = (total_passed / total_tests * 100) if total_tests > 0 else 0
    print(f"\n  Overall: {overall_rate:.2f}% ({total_passed}/{total_tests})")
    print(f"  Status: {'100% COMPLIANT' if overall_rate >= 99 else 'BELOW TARGET'}")
    
except Exception as e:
    print(f"  ERROR: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 80)
print("CHECK COMPLETE")
print("=" * 80)
