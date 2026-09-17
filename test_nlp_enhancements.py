"""Quick test for NLP Domain enhancements"""
import sys
sys.path.insert(0, '.')

from tiannara_core.evaluation.test_suites.test_nlp_domain import NLPDomainTestSuite

suite = NLPDomainTestSuite()

print("\n" + "="*80)
print("NLP DOMAIN ENHANCEMENT TESTS")
print("="*80)

# Test intent recognition
print("\n1. Intent Recognition Tests...")
result = suite.test_intent_recognition()
print(f"   Passed: {result['passed']}/{result['total']} ({result['success_rate']:.1f}%)")
print(f"   Status: {'✅ PASS' if result['success'] else '❌ FAIL'}")

# Test context preservation
print("\n2. Context Preservation Tests...")
result = suite.test_context_preservation()
print(f"   Passed: {result['passed']}/{result['total']} ({result['success_rate']:.1f}%)")
print(f"   Status: {'✅ PASS' if result['success'] else '❌ FAIL'}")

# Test semantic similarity
print("\n3. Semantic Similarity Tests...")
result = suite.test_semantic_similarity()
print(f"   Passed: {result['passed']}/{result['total']} ({result['success_rate']:.1f}%)")
print(f"   Status: {'✅ PASS' if result['success'] else '❌ FAIL'}")

print("\n" + "="*80)
print("NLP Enhancement Summary:")
print("="*80 + "\n")
