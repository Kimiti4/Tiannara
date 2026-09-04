import sys, warnings
warnings.filterwarnings('ignore')
sys.path.insert(0, '.')

from tiannara_core.evaluation.test_suites.test_algorithm_domain import AlgorithmDomainTestSuite

suite = AlgorithmDomainTestSuite()
test_methods = [m for m in dir(suite) if m.startswith('test_')]

total_passed = 0
total_tests = 0

print('Checking Algorithm Domain failures...\n')
for method_name in test_methods:
    try:
        test_method = getattr(suite, method_name)
        result = test_method()
        passed = result.get('passed', 0)
        total = result.get('total', 0)
        total_passed += passed
        total_tests += total
        rate = (passed / total * 100) if total > 0 else 0
        if rate < 100:
            print(f'FAILING: {method_name:45s} {rate:6.2f}% ({passed}/{total})')
    except Exception as e:
        print(f'ERROR:   {method_name:45s} {str(e)[:60]}')

success_rate = (total_passed / total_tests * 100) if total_tests > 0 else 0
print(f'\n{"="*70}')
print(f'Algorithm Domain: {success_rate:.2f}% ({total_passed}/{total_tests})')
