"""Quick diagnostic for Logic Domain test failures"""
import sys
sys.path.insert(0, '.')

from tiannara_core.evaluation.test_suites.test_logic_domain import LogicDomainTestSuite

suite = LogicDomainTestSuite()

print("="*80)
print("LOGIC DOMAIN DIAGNOSTIC")
print("="*80)

# Test constraint checking
print("\n1. Constraint Checking Tests...")
result = suite.test_constraint_checking()
print(f"   Passed: {result['passed']}/{result['total']} ({result['success_rate']:.1f}%)")
print(f"   Status: {'✅ PASS' if result['success'] else '❌ FAIL'}")
if result['failures']:
    print(f"\n   First 5 failures:")
    for failure in result['failures'][:5]:
        print(f"     Test {failure['test_id']}: {failure['error']}")

# Test contradiction detection
print("\n2. Contradiction Detection Tests...")
result = suite.test_contradiction_detection()
print(f"   Passed: {result['passed']}/{result['total']} ({result['success_rate']:.1f}%)")
print(f"   Status: {'✅ PASS' if result['success'] else '❌ FAIL'}")
if result['failures']:
    print(f"\n   First 5 failures:")
    for failure in result['failures'][:5]:
        print(f"     Test {failure['test_id']}: {failure['error']}")

# Test deductive reasoning
print("\n3. Deductive Reasoning Tests...")
result = suite.test_deductive_reasoning()
print(f"   Passed: {result['passed']}/{result['total']} ({result['success_rate']:.1f}%)")
print(f"   Status: {'✅ PASS' if result['success'] else '❌ FAIL'}")
if result['failures']:
    print(f"\n   First 5 failures:")
    for failure in result['failures'][:5]:
        print(f"     Test {failure['test_id']}: {failure['error']}")

print("\n" + "="*80)
print("Diagnostic Complete")
print("="*80 + "\n")
