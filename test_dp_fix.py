"""Quick test for Algorithm Domain DP fix"""
import sys
sys.path.insert(0, '.')

from tiannara_core.evaluation.test_suites.test_algorithm_domain import AlgorithmDomainTestSuite

suite = AlgorithmDomainTestSuite()
result = suite.test_dynamic_programming()

print(f"\n{'='*60}")
print(f"Dynamic Programming Test Results")
print(f"{'='*60}")
print(f"Passed: {result['passed']}/{result['total']}")
print(f"Success Rate: {result['success_rate']:.1f}%")
print(f"Status: {'PASS' if result['success'] else 'FAIL'}")
if result['failures']:
    print(f"\nFirst 5 failures:")
    for failure in result['failures'][:5]:
        print(f"  Test {failure['test_id']}: {failure['error']}")
print(f"{'='*60}\n")
