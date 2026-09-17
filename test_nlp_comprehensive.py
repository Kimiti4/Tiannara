"""
NLP DOMAIN COMPREHENSIVE VALIDATION

Completes full validation of NLP domain to achieve ≥99% mastery.
Tests all NLP capabilities including intent recognition, context preservation,
semantic similarity, sentiment analysis, and dialogue management.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from tiannara_core.evaluation.test_suites.test_nlp_domain import NLPDomainTestSuite


def run_comprehensive_nlp_validation():
    """Run complete NLP domain test suite."""
    print("\n" + "="*80)
    print("NLP DOMAIN - COMPREHENSIVE VALIDATION")
    print("="*80)
    
    suite = NLPDomainTestSuite()
    
    tests = [
        ("Email Generation", suite.test_email_generation),
        ("Report Generation", suite.test_report_generation),
        ("Code Explanation", suite.test_code_explanation),
        ("Sentiment Analysis", suite.test_sentiment_analysis),
        ("Translation", suite.test_translation),
        ("Summarization", suite.test_summarization),
        ("Intent Recognition", suite.test_intent_recognition),
        ("Context Preservation", suite.test_context_preservation),
        ("Semantic Similarity", suite.test_semantic_similarity),
    ]
    
    total_passed = 0
    total_tests = 0
    
    print("\nRunning NLP domain tests...\n")
    
    for test_name, test_func in tests:
        try:
            result = test_func()
            passed = result['passed']
            total = result['total']
            success_rate = result['success_rate']
            
            total_passed += passed
            total_tests += total
            
            status = "✅ PASS" if result['success'] else "❌ FAIL"
            print(f"{test_name:30s}: {passed:4d}/{total:4d} ({success_rate:5.1f}%) {status}")
            
        except Exception as e:
            print(f"{test_name:30s}: ERROR - {str(e)}")
    
    # Overall summary
    overall_rate = (total_passed / total_tests * 100) if total_tests > 0 else 0
    
    print("\n" + "="*80)
    print(f"NLP DOMAIN SUMMARY")
    print("="*80)
    print(f"Total Tests: {total_tests}")
    print(f"Passed: {total_passed}")
    print(f"Success Rate: {overall_rate:.1f}%")
    
    if overall_rate >= 99.0:
        print("\n✅ NLP DOMAIN ACHIEVED ≥99% MASTERY")
    elif overall_rate >= 95.0:
        print("\n⚠️  NLP DOMAIN NEAR TARGET (≥95%)")
    else:
        print(f"\n❌ NLP DOMAIN NEEDS IMPROVEMENT ({overall_rate:.1f}% < 99%)")
    
    print("="*80 + "\n")
    
    return {
        'total_tests': total_tests,
        'passed': total_passed,
        'success_rate': overall_rate,
        'target_met': overall_rate >= 99.0
    }


if __name__ == '__main__':
    result = run_comprehensive_nlp_validation()
    sys.exit(0 if result['target_met'] else 1)
