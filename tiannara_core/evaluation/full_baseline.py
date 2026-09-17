"""
Full Baseline Test Runner

Purpose: Run comprehensive tests on all domains and generate detailed report
Usage: python tiannara_core/evaluation/full_baseline.py
"""

import sys
from pathlib import Path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

import json
import time
from datetime import datetime
from typing import Dict, Any

print("="*80)
print("TIANNARA MINDCACHE - FULL BASELINE TEST")
print("="*80)
print(f"Timestamp: {datetime.now().isoformat()}")
print("="*80)

results = {}
total_tests_run = 0
total_tests_passed = 0
domain_success_rates = {}

# Test each domain
domains_to_test = [
    ('algorithm', 'AlgorithmDomainTestSuite', 'test_sorting_algorithms'),
    ('combinatorial', 'CombinatorialDomainTestSuite', 'test_knapsack_problems'),
    ('causal', 'CausalDomainTestSuite', 'test_causal_discovery'),
    ('temporal', 'TemporalDomainTestSuite', 'test_time_series_forecasting'),
    ('re', 'ReverseEngineeringTestSuite', 'test_function_inference'),
    ('nlp', 'NLPDomainTestSuite', 'test_email_generation'),
    ('logic', 'LogicDomainTestSuite', 'test_logical_puzzles'),
    ('prediction', 'PredictionDomainTestSuite', 'run_all_tests'),
]

for domain_name, suite_class, test_method in domains_to_test:
    print(f"\n{'='*80}")
    print(f"Testing {domain_name.upper()} Domain...")
    print(f"{'='*80}")
    
    try:
        # Import and instantiate suite
        if domain_name == 'algorithm':
            from tiannara_core.evaluation.test_suites.test_algorithm_domain import AlgorithmDomainTestSuite
            suite = AlgorithmDomainTestSuite()
        elif domain_name == 'combinatorial':
            from tiannara_core.evaluation.test_suites.test_combinatorial_domain import CombinatorialDomainTestSuite
            suite = CombinatorialDomainTestSuite()
        elif domain_name == 'causal':
            from tiannara_core.evaluation.test_suites.test_causal_domain import CausalDomainTestSuite
            suite = CausalDomainTestSuite()
        elif domain_name == 'temporal':
            from tiannara_core.evaluation.test_suites.test_temporal_domain import TemporalDomainTestSuite
            suite = TemporalDomainTestSuite()
        elif domain_name == 're':
            from tiannara_core.evaluation.test_suites.test_re_domain import ReverseEngineeringTestSuite
            suite = ReverseEngineeringTestSuite()
        elif domain_name == 'nlp':
            from tiannara_core.evaluation.test_suites.test_nlp_domain import NLPDomainTestSuite
            suite = NLPDomainTestSuite()
        elif domain_name == 'logic':
            from tiannara_core.evaluation.test_suites.test_logic_domain import LogicDomainTestSuite
            suite = LogicDomainTestSuite()
        elif domain_name == 'prediction':
            from tiannara_core.evaluation.test_suites.test_prediction_domain import PredictionDomainTestSuite
            suite = PredictionDomainTestSuite()
        
        print(f"[OK] Suite instantiated successfully")
        
        # Run the test method
        test_func = getattr(suite, test_method)
        print(f"Running {test_method}...")
        
        start_time = time.time()
        result = test_func()
        duration = time.time() - start_time
        
        # Extract metrics (handle both formats)
        success_rate = result.get('success_rate', 0)
        total = result.get('total', result.get('total_tests', 0))  # Support both keys
        passed = result.get('passed', 0)
        failed = result.get('failed', total - passed)
        avg_response_time = result.get('average_response_time_ms', 0)
        
        total_tests_run += total
        total_tests_passed += passed
        
        domain_success_rates[domain_name] = success_rate
        
        results[domain_name] = {
            'test_method': test_method,
            'success_rate': success_rate,
            'total_tests': total,
            'passed': passed,
            'failed': failed,
            'avg_response_time_ms': avg_response_time,
            'duration_seconds': duration,
            'status': 'PASS' if success_rate >= 95 else 'FAIL',
            'sample_failures': result.get('failures', [])[:3]
        }
        
        print(f"[OK] Tests completed in {duration:.2f}s")
        print(f"  Success Rate: {success_rate:.1f}% ({passed}/{total})")
        print(f"  Avg Response Time: {avg_response_time:.2f}ms")
        print(f"  Status: {'[PASS]' if success_rate >= 95 else '[FAIL]'}")
        
        if failed > 0:
            print(f"  Sample Failures:")
            for failure in result.get('failures', [])[:3]:
                print(f"    - Test {failure['test_id']}: {failure['error'][:100]}")
        
    except Exception as e:
        print(f"[ERROR] testing {domain_name}: {str(e)}")
        import traceback
        traceback.print_exc()
        
        results[domain_name] = {
            'status': 'ERROR',
            'error': str(e)
        }

# Calculate overall metrics
overall_success_rate = (total_tests_passed / total_tests_run * 100) if total_tests_run > 0 else 0

print(f"\n{'='*80}")
print("OVERALL RESULTS")
print(f"{'='*80}")
print(f"Total Tests Run: {total_tests_run}")
print(f"Total Tests Passed: {total_tests_passed}")
print(f"Overall Success Rate: {overall_success_rate:.1f}%")
print(f"Target: 95-98%")
print(f"Status: {'[ON TRACK]' if overall_success_rate >= 95 else '[NEEDS IMPROVEMENT]'}")

print(f"\n{'='*80}")
print("DOMAIN PERFORMANCE SUMMARY")
print(f"{'='*80}")
print(f"{'Domain':<20} {'Success Rate':<15} {'Status':<10}")
print(f"{'-'*20} {'-'*15} {'-'*10}")

for domain, rate in sorted(domain_success_rates.items(), key=lambda x: x[1]):
    status = '[OK]' if rate >= 99 else ('[WARN]' if rate >= 95 else '[FAIL]')
    print(f"{domain:<20} {rate:>6.1f}%       {status}")

# Save results
output_file = Path('test_results/full_baseline.json')
output_file.parent.mkdir(parents=True, exist_ok=True)

baseline_report = {
    'timestamp': datetime.now().isoformat(),
    'overall_success_rate': overall_success_rate,
    'total_tests_run': total_tests_run,
    'total_tests_passed': total_tests_passed,
    'domain_performance': domain_success_rates,
    'detailed_results': results,
    'target_met': overall_success_rate >= 95
}

with open(output_file, 'w') as f:
    json.dump(baseline_report, f, indent=2)

print(f"\n[OK] Results saved to: {output_file}")
print(f"{'='*80}")
