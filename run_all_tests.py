"""
Master Test Runner for All New Modules

Runs all test scripts and reports pass/fail status with dependency information.

Usage:
    python run_all_tests.py
"""

import sys
import subprocess
from pathlib import Path
from typing import Dict, List, Tuple

# Test scripts to run
TEST_SCRIPTS = [
    {
        'name': 'CausalPathTracer',
        'path': 'tiannara_core/interpretability/test_causal_path_tracer.py',
        'dependencies': ['numpy'],
        'description': 'Explainable ECM - Causal path tracing'
    },
    {
        'name': 'StagnationDetector', 
        'path': 'tiannara_core/autonomy/test_stagnation_detector.py',
        'dependencies': ['numpy', 'torch', 'dowhy'],
        'description': 'Autonomy - Performance plateau detection'
    },
    {
        'name': 'PCMCI Discovery',
        'path': 'tiannara_core/causal/test_pcmci_discovery.py',
        'dependencies': ['numpy', 'tigramite'],
        'description': 'Causal - Time-series causal discovery'
    },
    {
        'name': 'DoWhy Integration',
        'path': 'tiannara_core/causal/test_dowhy_integration.py',
        'dependencies': ['numpy', 'pandas', 'dowhy', 'sklearn'],
        'description': 'Causal - Observational causal inference'
    },
    {
        'name': 'Anonymization Engine',
        'path': 'tiannara_core/compliance/test_anonymization.py',
        'dependencies': ['numpy', 'pandas', 'diffprivlib', 'faker'],
        'description': 'Compliance - EU AI Act data anonymization'
    },
    {
        'name': 'Model Quantization',
        'path': 'tiannara_core/models/test_quantization.py',
        'dependencies': ['numpy', 'onnx', 'onnxruntime'],
        'description': 'Models - Edge deployment optimization'
    }
]


def check_dependencies(deps: List[str]) -> Tuple[bool, List[str]]:
    """Check if all dependencies are installed."""
    missing = []
    
    for dep in deps:
        try:
            if dep == 'sklearn':
                __import__('sklearn')
            elif dep == 'diffprivlib':
                __import__('diffprivlib')
            else:
                __import__(dep)
        except ImportError:
            missing.append(dep)
    
    return len(missing) == 0, missing


def run_test(script_info: Dict) -> Dict:
    """Run a single test script."""
    name = script_info['name']
    path = script_info['path']
    deps = script_info['dependencies']
    description = script_info['description']
    
    print(f"\n{'='*80}")
    print(f"Testing: {name}")
    print(f"Description: {description}")
    print(f"Dependencies: {', '.join(deps)}")
    print(f"{'='*80}")
    
    # Check dependencies
    all_installed, missing = check_dependencies(deps)
    
    if not all_installed:
        print(f"⚠️  SKIPPED - Missing dependencies: {', '.join(missing)}")
        print(f"   Install with: pip install {' '.join(missing)}")
        return {
            'name': name,
            'status': 'SKIPPED',
            'reason': f'Missing: {", ".join(missing)}'
        }
    
    # Run test
    try:
        result = subprocess.run(
            [sys.executable, path],
            capture_output=True,
            text=True,
            timeout=120  # 2 minute timeout
        )
        
        if result.returncode == 0:
            print(f"✅ PASSED")
            return {
                'name': name,
                'status': 'PASSED',
                'output_lines': len(result.stdout.split('\n'))
            }
        else:
            print(f"❌ FAILED")
            print(f"Error output (last 10 lines):")
            error_lines = result.stderr.split('\n')[-10:]
            for line in error_lines:
                print(f"   {line}")
            
            return {
                'name': name,
                'status': 'FAILED',
                'error': result.stderr[-500:]  # Last 500 chars
            }
    
    except subprocess.TimeoutExpired:
        print(f"⏱️  TIMEOUT - Test exceeded 2 minute limit")
        return {
            'name': name,
            'status': 'TIMEOUT',
            'reason': 'Exceeded 120s timeout'
        }
    except Exception as e:
        print(f"❌ ERROR - {str(e)}")
        return {
            'name': name,
            'status': 'ERROR',
            'error': str(e)
        }


def main():
    """Run all tests and generate report."""
    print("="*80)
    print("Tiannara MindCache - Module Test Suite")
    print("="*80)
    print(f"Python executable: {sys.executable}")
    print(f"Working directory: {Path.cwd()}")
    print(f"Total tests: {len(TEST_SCRIPTS)}")
    
    results = []
    
    # Run each test
    for script_info in TEST_SCRIPTS:
        result = run_test(script_info)
        results.append(result)
    
    # Generate summary report
    print("\n" + "="*80)
    print("TEST SUMMARY REPORT")
    print("="*80)
    
    passed = sum(1 for r in results if r['status'] == 'PASSED')
    failed = sum(1 for r in results if r['status'] == 'FAILED')
    skipped = sum(1 for r in results if r['status'] == 'SKIPPED')
    errors = sum(1 for r in results if r['status'] in ['TIMEOUT', 'ERROR'])
    
    print(f"\nResults:")
    print(f"  ✅ Passed:  {passed}/{len(results)}")
    print(f"  ❌ Failed:  {failed}/{len(results)}")
    print(f"  ⚠️  Skipped: {skipped}/{len(results)}")
    print(f"  ⏱️  Errors:  {errors}/{len(results)}")
    
    print(f"\nDetailed Results:")
    print("-"*80)
    
    for result in results:
        status_icon = {
            'PASSED': '✅',
            'FAILED': '❌',
            'SKIPPED': '⚠️ ',
            'TIMEOUT': '⏱️ ',
            'ERROR': '💥'
        }.get(result['status'], '?')
        
        print(f"{status_icon} {result['name']:30s} {result['status']}")
        
        if result['status'] == 'SKIPPED':
            print(f"   Reason: {result.get('reason', 'N/A')}")
        elif result['status'] in ['FAILED', 'ERROR']:
            print(f"   Details: {result.get('error', 'N/A')[:100]}...")
    
    # Installation instructions for skipped tests
    if skipped > 0:
        print(f"\n{'='*80}")
        print("DEPENDENCY INSTALLATION")
        print("="*80)
        print("\nTo run all tests, install missing dependencies:")
        print("\npip install torch dowhy tigramite pandas diffprivlib faker onnx onnxruntime scikit-learn")
        print("\nOr install individually:")
        
        skipped_deps = set()
        for result in results:
            if result['status'] == 'SKIPPED':
                # Find the script info
                for script in TEST_SCRIPTS:
                    if script['name'] == result['name']:
                        _, missing = check_dependencies(script['dependencies'])
                        skipped_deps.update(missing)
        
        for dep in sorted(skipped_deps):
            print(f"  pip install {dep}")
    
    print(f"\n{'='*80}")
    
    # Exit code
    if failed > 0 or errors > 0:
        sys.exit(1)
    else:
        print("✅ All runnable tests passed!")
        sys.exit(0)


if __name__ == '__main__':
    main()
