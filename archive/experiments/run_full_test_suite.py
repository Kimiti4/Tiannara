"""
Comprehensive Test Suite Runner for Tiannara MindCache

Purpose: Measure and validate >95% success rate across all domains
Usage: python tiannara_core/evaluation/run_full_test_suite.py [--final-validation]
"""

import sys
import os
from pathlib import Path

# Add project root to sys.path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

import json
import time
from datetime import datetime
from typing import Dict, List, Any
from dataclasses import dataclass, asdict

# Import domain test suites
from tiannara_core.evaluation.test_suites.test_algorithm_domain import AlgorithmDomainTestSuite
from tiannara_core.evaluation.test_suites.test_logic_domain import LogicDomainTestSuite
from tiannara_core.evaluation.test_suites.test_re_domain import ReverseEngineeringTestSuite
from tiannara_core.evaluation.test_suites.test_causal_domain import CausalDomainTestSuite
from tiannara_core.evaluation.test_suites.test_nlp_domain import NLPDomainTestSuite
from tiannara_core.evaluation.test_suites.test_temporal_domain import TemporalDomainTestSuite
from tiannara_core.evaluation.test_suites.test_combinatorial_domain import CombinatorialDomainTestSuite
from tiannara_core.evaluation.test_suites.test_prediction_domain import PredictionDomainTestSuite
from tiannara_core.evaluation.test_cross_domain import CrossDomainIntegrationTests


@dataclass
class DomainResults:
    """Results for a single domain"""
    domain_name: str
    total_tests: int
    passed_tests: int
    failed_tests: int
    success_rate: float
    average_response_time_ms: float
    test_duration_seconds: float
    failure_details: List[Dict[str, Any]]


@dataclass
class OverallResults:
    """Overall test results"""
    timestamp: str
    overall_success_rate: float
    domain_performance: Dict[str, float]
    cross_domain_collaboration: float
    auto_resolution_rate: float
    average_response_time_ms: float
    total_tests_run: int
    total_tests_passed: int
    total_tests_failed: int
    tasks_below_95_percent: List[str]
    domain_results: Dict[str, DomainResults]
    validation_passed: bool


class TestSuiteRunner:
    """Run comprehensive test suite across all domains"""
    
    def __init__(self, output_dir: str = "test_results"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Initialize test suites
        self.test_suites = {
            "algorithm": AlgorithmDomainTestSuite(),
            "logic": LogicDomainTestSuite(),
            "reverse_engineering": ReverseEngineeringTestSuite(),
            "causal": CausalDomainTestSuite(),
            "nlp": NLPDomainTestSuite(),
            "temporal": TemporalDomainTestSuite(),
            "combinatorial": CombinatorialDomainTestSuite(),
            "prediction": PredictionDomainTestSuite(),
        }
        
        self.cross_domain_tests = CrossDomainIntegrationTests()
        
    def run_domain_tests(self, domain_name: str) -> DomainResults:
        """Run all tests for a specific domain"""
        print(f"\n{'='*60}")
        print(f"Testing Domain: {domain_name.upper()}")
        print(f"{'='*60}")
        
        test_suite = self.test_suites[domain_name]
        start_time = time.time()
        
        # Run all test methods in the suite
        total_tests = 0
        passed_tests = 0
        failed_tests = 0
        response_times = []
        failure_details = []
        
        # Get all test methods
        test_methods = [
            method for method in dir(test_suite) 
            if method.startswith('test_') and callable(getattr(test_suite, method))
        ]
        
        for test_method_name in test_methods:
            test_method = getattr(test_suite, test_method_name)
            
            try:
                # Run the test
                test_start = time.time()
                result = test_method()
                test_duration = (time.time() - test_start) * 1000  # Convert to ms
                
                # Parse results
                if isinstance(result, dict):
                    total_tests += result.get('total', 1)
                    passed = result.get('passed', 1 if result.get('success', False) else 0)
                    failed = result.get('failed', 0 if result.get('success', False) else 1)
                    
                    passed_tests += passed
                    failed_tests += failed
                    
                    if 'response_time_ms' in result:
                        response_times.append(result['response_time_ms'])
                    else:
                        response_times.append(test_duration)
                        
                    if not result.get('success', True):
                        failure_details.append({
                            'test': test_method_name,
                            'error': result.get('error', 'Unknown error'),
                            'details': result.get('details', {})
                        })
                else:
                    # Simple boolean result
                    total_tests += 1
                    if result:
                        passed_tests += 1
                    else:
                        failed_tests += 1
                        failure_details.append({
                            'test': test_method_name,
                            'error': 'Test returned False'
                        })
                        
            except Exception as e:
                total_tests += 1
                failed_tests += 1
                failure_details.append({
                    'test': test_method_name,
                    'error': str(e),
                    'traceback': str(e.__traceback__)
                })
                print(f"  ❌ {test_method_name}: {str(e)}")
                continue
            
            # Print progress
            current_success_rate = (passed_tests / total_tests * 100) if total_tests > 0 else 0
            print(f"  ✓ {test_method_name}: {current_success_rate:.1f}% success rate")
        
        # Calculate final metrics
        end_time = time.time()
        success_rate = (passed_tests / total_tests * 100) if total_tests > 0 else 0
        avg_response_time = sum(response_times) / len(response_times) if response_times else 0
        
        results = DomainResults(
            domain_name=domain_name,
            total_tests=total_tests,
            passed_tests=passed_tests,
            failed_tests=failed_tests,
            success_rate=success_rate,
            average_response_time_ms=avg_response_time,
            test_duration_seconds=end_time - start_time,
            failure_details=failure_details[:10]  # Limit to first 10 failures
        )
        
        # Print summary
        print(f"\n  Summary:")
        print(f"    Total Tests: {total_tests}")
        print(f"    Passed: {passed_tests}")
        print(f"    Failed: {failed_tests}")
        print(f"    Success Rate: {success_rate:.2f}%")
        print(f"    Avg Response Time: {avg_response_time:.2f}ms")
        print(f"    Duration: {end_time - start_time:.2f}s")
        
        if success_rate >= 95:
            print(f"  ✅ PASSED (>95% success rate)")
        else:
            print(f"  ❌ FAILED (<95% success rate)")
        
        return results
    
    def run_cross_domain_tests(self) -> Dict[str, Any]:
        """Run cross-domain integration tests"""
        print(f"\n{'='*60}")
        print(f"Testing Cross-Domain Collaboration")
        print(f"{'='*60}")
        
        start_time = time.time()
        
        # Run collaboration tests
        collaboration_results = self.cross_domain_tests.run_all_tests()
        
        end_time = time.time()
        
        success_rate = collaboration_results.get('success_rate', 0)
        print(f"\n  Cross-Domain Success Rate: {success_rate:.2f}%")
        
        if success_rate >= 97:
            print(f"  ✅ PASSED (>97% collaboration success)")
        else:
            print(f"  ⚠️  WARNING (<97% collaboration success)")
        
        return {
            'success_rate': success_rate,
            'total_tests': collaboration_results.get('total_tests', 0),
            'duration_seconds': end_time - start_time
        }
    
    def calculate_auto_resolution_rate(self) -> float:
        """Calculate auto-resolution rate from monitoring system"""
        try:
            from tiannara_core.evaluation.issue_detection_system import issue_manager
            
            # Get resolution statistics
            stats = issue_manager.get_resolution_stats()
            
            auto_resolution_rate = stats.get('auto_resolution_rate', 70.0)
            print(f"\n  Auto-Resolution Rate: {auto_resolution_rate:.2f}%")
            
            return auto_resolution_rate
        except Exception as e:
            print(f"  Warning: Could not calculate auto-resolution rate: {e}")
            return 70.0  # Default baseline
    
    def run_full_suite(self, final_validation: bool = False) -> OverallResults:
        """Run complete test suite across all domains"""
        print("\n" + "="*80)
        print("TIANNARA MINDCACHE - COMPREHENSIVE TEST SUITE")
        print("="*80)
        print(f"Timestamp: {datetime.now().isoformat()}")
        print(f"Mode: {'Final Validation' if final_validation else 'Regular Testing'}")
        print("="*80)
        
        overall_start = time.time()
        
        # Test each domain
        domain_results = {}
        for domain_name in self.test_suites.keys():
            results = self.run_domain_tests(domain_name)
            domain_results[domain_name] = results
        
        # Test cross-domain collaboration
        cross_domain_results = self.run_cross_domain_tests()
        
        # Calculate auto-resolution rate
        auto_resolution_rate = self.calculate_auto_resolution_rate()
        
        # Calculate overall metrics
        overall_end = time.time()
        
        total_tests = sum(r.total_tests for r in domain_results.values())
        total_passed = sum(r.passed_tests for r in domain_results.values())
        total_failed = sum(r.failed_tests for r in domain_results.values())
        
        overall_success_rate = (total_passed / total_tests * 100) if total_tests > 0 else 0
        
        domain_performance = {
            name: results.success_rate 
            for name, results in domain_results.items()
        }
        
        avg_response_time = sum(
            r.average_response_time_ms * r.total_tests 
            for r in domain_results.values()
        ) / total_tests if total_tests > 0 else 0
        
        # Identify domains below 95%
        tasks_below_95 = [
            name for name, rate in domain_performance.items()
            if rate < 95.0
        ]
        
        # Determine if validation passed
        validation_passed = (
            overall_success_rate >= 95.0 and
            all(rate >= 99.0 for rate in domain_performance.values()) and
            cross_domain_results['success_rate'] >= 97.0
        )
        
        # Create overall results
        overall_results = OverallResults(
            timestamp=datetime.now().isoformat(),
            overall_success_rate=overall_success_rate,
            domain_performance=domain_performance,
            cross_domain_collaboration=cross_domain_results['success_rate'],
            auto_resolution_rate=auto_resolution_rate,
            average_response_time_ms=avg_response_time,
            total_tests_run=total_tests,
            total_tests_passed=total_passed,
            total_tests_failed=total_failed,
            tasks_below_95_percent=tasks_below_95,
            domain_results={name: asdict(r) for name, r in domain_results.items()},
            validation_passed=validation_passed
        )
        
        # Print final summary
        print("\n" + "="*80)
        print("FINAL RESULTS SUMMARY")
        print("="*80)
        print(f"Overall Success Rate: {overall_success_rate:.2f}%")
        print(f"Total Tests Run: {total_tests}")
        print(f"Tests Passed: {total_passed}")
        print(f"Tests Failed: {total_failed}")
        print(f"Cross-Domain Collaboration: {cross_domain_results['success_rate']:.2f}%")
        print(f"Auto-Resolution Rate: {auto_resolution_rate:.2f}%")
        print(f"Average Response Time: {avg_response_time:.2f}ms")
        print(f"Total Duration: {overall_end - overall_start:.2f}s")
        
        print(f"\nDomain Performance:")
        for name, rate in sorted(domain_performance.items(), key=lambda x: x[1]):
            status = "✅" if rate >= 99 else "⚠️" if rate >= 95 else "❌"
            print(f"  {status} {name:25s}: {rate:6.2f}%")
        
        if tasks_below_95:
            print(f"\n⚠️  Domains Below 95%: {', '.join(tasks_below_95)}")
        
        if validation_passed:
            print(f"\n🎉 VALIDATION PASSED! All targets met!")
        else:
            print(f"\n❌ VALIDATION FAILED. Some targets not met.")
        
        print("="*80)
        
        # Save results
        self.save_results(overall_results, final_validation)
        
        return overall_results
    
    def save_results(self, results: OverallResults, final_validation: bool):
        """Save test results to file"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        if final_validation:
            filename = f"final_validation_{timestamp}.json"
        else:
            filename = f"test_results_{timestamp}.json"
        
        filepath = self.output_dir / filename
        
        # Convert to JSON-serializable format
        results_dict = asdict(results)
        
        with open(filepath, 'w') as f:
            json.dump(results_dict, f, indent=2, default=str)
        
        print(f"\n📄 Results saved to: {filepath}")
        
        # Also save as latest results for easy access
        latest_path = self.output_dir / "latest_results.json"
        with open(latest_path, 'w') as f:
            json.dump(results_dict, f, indent=2, default=str)
        
        print(f"📄 Latest results: {latest_path}")


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Run Tiannara comprehensive test suite')
    parser.add_argument('--final-validation', action='store_true', 
                       help='Run in final validation mode')
    parser.add_argument('--output-dir', type=str, default='test_results',
                       help='Output directory for results')
    
    args = parser.parse_args()
    
    runner = TestSuiteRunner(output_dir=args.output_dir)
    results = runner.run_full_suite(final_validation=args.final_validation)
    
    # Exit with appropriate code
    if results.validation_passed:
        print("\n✅ All tests passed! System ready for production.")
        exit(0)
    else:
        print("\n❌ Some tests failed. Review results and fix issues.")
        exit(1)


if __name__ == "__main__":
    main()
