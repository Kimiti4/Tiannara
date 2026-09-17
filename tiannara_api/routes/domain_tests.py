"""
Domain Test Results API Routes

Provides endpoints for accessing domain test results.
"""

from fastapi import APIRouter
from tiannara_api.services.domain_test_runner import test_runner

router = APIRouter(
    prefix="/domain-tests",
    tags=["domain-tests"],
)


@router.get("/results")
async def get_domain_test_results():
    """Get current domain test results."""
    return {
        "success": True,
        "results": test_runner.get_results()
    }


@router.get("/results/{domain_name}")
async def get_domain_test_result(domain_name: str):
    """Get test result for specific domain."""
    result = test_runner.get_domain_result(domain_name)
    if result is None:
        return {
            "success": False,
            "error": f"Domain '{domain_name}' not found"
        }
    
    return {
        "success": True,
        "domain": domain_name,
        "result": result
    }


@router.post("/run/{domain_name}")
async def run_domain_test(domain_name: str):
    """Manually trigger test run for a specific domain."""
    try:
        if domain_name == "temporal":
            result = test_runner._run_temporal_tests()
        elif domain_name == "combinatorial":
            result = test_runner._run_combinatorial_tests()
        elif domain_name == "reverse_engineering":
            result = test_runner._run_re_tests()
        else:
            return {
                "success": False,
                "error": f"Unknown domain: {domain_name}"
            }
        
        test_runner.results[domain_name] = {
            'success_rate': result.get('success_rate', 0),
            'total_tests': result.get('total', 0),
            'passed_tests': result.get('passed', 0),
            'failed_tests': result.get('failed', 0),
            'last_run': result.get('last_run'),
            'status': 'PASS' if result.get('success_rate', 0) >= 99 else 'FAIL'
        }
        
        return {
            "success": True,
            "domain": domain_name,
            "result": test_runner.results[domain_name]
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }


@router.post("/auto-fix/{domain_name}")
async def auto_fix_domain(domain_name: str):
    """Trigger auto-fix for a failing domain."""
    try:
        success_rate = test_runner.attempt_auto_fix(domain_name)
        return {
            "success": True,
            "domain": domain_name,
            "success_rate": success_rate,
            "result": test_runner.results.get(domain_name)
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }


@router.post("/diagnostics")
async def run_diagnostics():
    """Run comprehensive diagnostics on all domains with auto-fix."""
    try:
        results = test_runner.run_comprehensive_diagnostics()
        return {
            "success": True,
            "diagnostics": results,
            "current_results": test_runner.get_results()
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }
