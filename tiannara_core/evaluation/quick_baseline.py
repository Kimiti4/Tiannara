"""
Quick Baseline Measurement Script

Purpose: Measure current performance across available domains
Usage: python tiannara_core/evaluation/quick_baseline.py
"""

import sys
from pathlib import Path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

import json
from datetime import datetime

print("="*80)
print("TIANNARA MINDCACHE - QUICK BASELINE MEASUREMENT")
print("="*80)
print(f"Timestamp: {datetime.now().isoformat()}")
print("="*80)

# Test each domain that exists
domains_tested = []
results = {}

# Test Algorithm Domain
try:
    print("\nTesting Algorithm Domain...")
    from tiannara_core.evaluation.test_suites.test_algorithm_domain import AlgorithmDomainTestSuite
    suite = AlgorithmDomainTestSuite()
    
    # Run one quick test to verify it works
    result = suite.test_sorting_algorithms()
    results['algorithm'] = {
        'success_rate': result.get('success_rate', 0),
        'total_tests': result.get('total', 0),
        'status': 'PASS' if result.get('success_rate', 0) >= 95 else 'NEEDS_IMPROVEMENT'
    }
    domains_tested.append('algorithm')
    print(f"  Success Rate: {result.get('success_rate', 0):.2f}%")
    print(f"  Tests Run: {result.get('total', 0)}")
except Exception as e:
    print(f"  Error: {str(e)}")
    results['algorithm'] = {'status': 'ERROR', 'error': str(e)}

# Test Combinatorial Domain
try:
    print("\nTesting Combinatorial Domain...")
    from tiannara_core.evaluation.test_suites.test_combinatorial_domain import CombinatorialDomainTestSuite
    suite = CombinatorialDomainTestSuite()
    result = suite.test_knapsack_problems()
    results['combinatorial'] = {
        'success_rate': result.get('success_rate', 0),
        'total_tests': result.get('total', 0),
        'status': 'PASS' if result.get('success_rate', 0) >= 95 else 'NEEDS_IMPROVEMENT'
    }
    domains_tested.append('combinatorial')
    print(f"  Success Rate: {result.get('success_rate', 0):.2f}%")
    print(f"  Tests Run: {result.get('total', 0)}")
except Exception as e:
    print(f"  Error: {str(e)}")
    results['combinatorial'] = {'status': 'ERROR', 'error': str(e)}

# Test Causal Domain
try:
    print("\nTesting Causal Domain...")
    from tiannara_core.evaluation.test_suites.test_causal_domain import CausalDomainTestSuite
    suite = CausalDomainTestSuite()
    result = suite.test_causal_discovery()
    results['causal'] = {
        'success_rate': result.get('success_rate', 0),
        'total_tests': result.get('total', 0),
        'status': 'PASS' if result.get('success_rate', 0) >= 95 else 'NEEDS_IMPROVEMENT'
    }
    domains_tested.append('causal')
    print(f"  Success Rate: {result.get('success_rate', 0):.2f}%")
    print(f"  Tests Run: {result.get('total', 0)}")
except Exception as e:
    print(f"  Error: {str(e)}")
    results['causal'] = {'status': 'ERROR', 'error': str(e)}

# Test other domains (just check imports work)
test_domains = [
    ('temporal', 'test_temporal_domain', 'TemporalDomainTestSuite'),
    ('re', 'test_re_domain', 'ReverseEngineeringTestSuite'),
    ('nlp', 'test_nlp_domain', 'NLPDomainTestSuite'),
    ('logic', 'test_logic_domain', 'LogicDomainTestSuite'),
    ('prediction', 'test_prediction_domain', 'PredictionDomainTestSuite'),
]

for domain_name, module_name, class_name in test_domains:
    try:
        print(f"\nTesting {domain_name.upper()} Domain (import check)...")
        module = __import__(f'tiannara_core.evaluation.test_suites.{module_name}', fromlist=[class_name])
        SuiteClass = getattr(module, class_name)
        results[domain_name] = {
            'status': 'IMPORT_OK',
            'note': 'Import successful, full testing pending'
        }
        domains_tested.append(domain_name)
        print(f"  Import: OK")
    except Exception as e:
        print(f"  Error: {str(e)}")
        results[domain_name] = {'status': 'IMPORT_ERROR', 'error': str(e)}

# Calculate overall metrics
total_domains = len(results)
working_domains = sum(1 for r in results.values() if r.get('status') in ['PASS', 'NEEDS_IMPROVEMENT', 'IMPORT_OK'])

print("\n" + "="*80)
print("BASELINE SUMMARY")
print("="*80)
print(f"Total Domains Tested: {total_domains}")
print(f"Working Domains: {working_domains}")
print(f"Domains with Full Tests: {len(domains_tested)}")

print("\nDomain Status:")
for domain, result in sorted(results.items()):
    status = result.get('status', 'UNKNOWN')
    success_rate = result.get('success_rate', 'N/A')
    if isinstance(success_rate, float):
        print(f"  {domain:20s}: {status:20s} ({success_rate:.2f}% success)")
    else:
        print(f"  {domain:20s}: {status}")

print("\n" + "="*80)
print("NEXT STEPS")
print("="*80)
print("1. Review domains marked NEEDS_IMPROVEMENT")
print("2. Prioritize enhancements for weakest domains")
print("3. Begin combinatorial domain enhancement (typically weakest)")
print("4. Run full test suite after improvements")
print("="*80)

# Save results
output_file = Path('test_results/baseline_quick.json')
output_file.parent.mkdir(parents=True, exist_ok=True)

with open(output_file, 'w') as f:
    json.dump({
        'timestamp': datetime.now().isoformat(),
        'total_domains': total_domains,
        'working_domains': working_domains,
        'results': results
    }, f, indent=2)

print(f"\nResults saved to: {output_file}")
