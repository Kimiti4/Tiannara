import sys, warnings
warnings.filterwarnings('ignore')
sys.path.insert(0, '.')

from tiannara_core.evaluation.test_suites.test_logic_domain import LogicDomainTestSuite

suite = LogicDomainTestSuite()
test_methods = [m for m in dir(suite) if m.startswith('test_')]

total_passed = 0
total_tests = 0

print('Testing Logic Domain after checkpoint fix...\n')
for method_name in test_methods:
    try:
        test_method = getattr(suite, method_name)
        result = test_method()
        passed = result.get('passed', 0)
        total = result.get('total', 0)
        total_passed += passed
        total_tests += total
        rate = (passed / total * 100) if total > 0 else 0
        status = 'OK' if rate == 100 else f'{rate:.2f}%'
        print(f'{method_name:40s} {status} ({passed}/{total})')
    except Exception as e:
        print(f'{method_name:40s} ERROR: {str(e)[:60]}')

success_rate = (total_passed / total_tests * 100) if total_tests > 0 else 0
print(f'\n{"="*70}')
print(f'Logic Domain: {success_rate:.2f}% ({total_passed}/{total_tests})')
print(f'Status: {"MASTERED ✅" if success_rate >= 99 else "NEEDS WORK ⚠️"}')
