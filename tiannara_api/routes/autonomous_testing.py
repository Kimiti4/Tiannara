"""
Autonomous Testing API Routes

Endpoints for receiving and querying autonomous test results.
Integrates with Core dashboard for real-time monitoring.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
import json
from pathlib import Path

router = APIRouter(prefix="/api/autonomy", tags=["autonomous-testing"])

# In-memory storage (replace with database in production)
test_results_store: Dict[str, List[Dict]] = {}


class TestResultItem(BaseModel):
    """Individual test result."""
    test_name: str
    status: str
    duration: float
    error_message: Optional[str] = None
    coverage_percent: Optional[float] = None


class DomainTestReport(BaseModel):
    """Complete domain test report."""
    domain: str
    timestamp: str
    total_tests: int
    passed: int
    failed: int
    skipped: int
    pass_rate: float
    coverage_percent: Optional[float] = None
    duration_seconds: float
    missing_dependencies: List[str] = Field(default_factory=list)
    installed_dependencies: List[str] = Field(default_factory=list)
    auto_fixes_applied: List[str] = Field(default_factory=list)
    test_results: List[TestResultItem] = Field(default_factory=list)


@router.post("/test-results")
async def submit_test_results(report: DomainTestReport):
    """
    Submit autonomous test results from TestOrchestrator.
    
    This endpoint receives test reports and stores them for dashboard display.
    """
    try:
        # Store in memory
        if report.domain not in test_results_store:
            test_results_store[report.domain] = []
        
        test_results_store[report.domain].append(report.dict())
        
        # Keep only last 10 reports per domain
        if len(test_results_store[report.domain]) > 10:
            test_results_store[report.domain] = test_results_store[report.domain][-10:]
        
        # Save to file for persistence
        report_dir = Path(__file__).parent.parent.parent / "test_reports" / report.domain
        report_dir.mkdir(parents=True, exist_ok=True)
        
        report_file = report_dir / f"latest_report.json"
        with open(report_file, 'w') as f:
            json.dump(report.dict(), f, indent=2, default=str)
        
        return {
            "status": "success",
            "message": f"Test results stored for domain: {report.domain}",
            "pass_rate": report.pass_rate,
            "total_tests": report.total_tests
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to store test results: {str(e)}")


@router.get("/test-results/{domain}")
async def get_domain_test_results(domain: str, limit: int = 5):
    """
    Get recent test results for a specific domain.
    
    Args:
        domain: Domain name (nlp, predictive, causal, etc.)
        limit: Number of recent reports to return (default: 5)
    
    Returns:
        List of recent test reports
    """
    if domain not in test_results_store:
        # Try to load from file
        report_file = Path(__file__).parent.parent.parent / "test_reports" / domain / "latest_report.json"
        if report_file.exists():
            with open(report_file, 'r') as f:
                report_data = json.load(f)
                return [report_data]
        else:
            return []
    
    return test_results_store[domain][-limit:]


@router.get("/test-results")
async def get_all_test_results():
    """
    Get latest test results for all domains.
    
    Returns summary of most recent test for each domain.
    """
    summary = {}
    
    for domain, reports in test_results_store.items():
        if reports:
            latest = reports[-1]
            summary[domain] = {
                "pass_rate": latest.get("pass_rate", 0),
                "total_tests": latest.get("total_tests", 0),
                "passed": latest.get("passed", 0),
                "failed": latest.get("failed", 0),
                "coverage_percent": latest.get("coverage_percent"),
                "timestamp": latest.get("timestamp"),
                "duration_seconds": latest.get("duration_seconds"),
                "installed_dependencies": latest.get("installed_dependencies", []),
                "auto_fixes_applied": latest.get("auto_fixes_applied", [])
            }
    
    return summary


@router.post("/test-domain/{domain}")
async def trigger_autonomous_test(domain: str, auto_fix: bool = True):
    """
    Trigger autonomous testing for a specific domain.
    
    This endpoint starts the TestOrchestrator to run tests autonomously.
    The process runs in the background and results are submitted via callback.
    
    Args:
        domain: Domain to test
        auto_fix: Whether to apply automatic fixes (default: True)
    
    Returns:
        Job ID for tracking test execution
    """
    import asyncio
    import uuid
    
    job_id = str(uuid.uuid4())
    
    async def run_test():
        """Run test in background."""
        try:
            from tiannara_core.tests.autonomous_test_manager import TestOrchestrator
            
            orchestrator = TestOrchestrator()
            report = orchestrator.test_domain_autonomously(
                domain=domain,
                auto_fix=auto_fix
            )
            
            # Results automatically submitted to dashboard via DashboardReporter
            logger.info(f"Test complete for {domain}: {report.pass_rate:.1f}% pass rate")
        
        except Exception as e:
            logger.error(f"Test failed for {domain}: {e}")
    
    # Run in background
    asyncio.create_task(run_test())
    
    return {
        "job_id": job_id,
        "status": "started",
        "domain": domain,
        "message": f"Autonomous test started for domain: {domain}"
    }


@router.post("/test-all-domains")
async def trigger_all_domain_tests(auto_fix: bool = True):
    """
    Trigger autonomous testing for all domains.
    
    Runs tests sequentially for all registered domains.
    """
    import asyncio
    import uuid
    
    job_id = str(uuid.uuid4())
    
    async def run_all_tests():
        """Run all domain tests in background."""
        try:
            from tiannara_core.tests.autonomous_test_manager import TestOrchestrator
            
            orchestrator = TestOrchestrator()
            results = orchestrator.test_all_domains(auto_fix=auto_fix)
            
            logger.info(f"All domain tests complete. Results: {len(results)} domains tested")
        
        except Exception as e:
            logger.error(f"Failed to run all domain tests: {e}")
    
    # Run in background
    asyncio.create_task(run_all_tests())
    
    return {
        "job_id": job_id,
        "status": "started",
        "message": "Autonomous tests started for all domains"
    }


@router.get("/test-status")
async def get_test_status():
    """
    Get overall testing status across all domains.
    
    Returns aggregated statistics and health indicators.
    """
    all_results = await get_all_test_results()
    
    total_domains = len(all_results)
    healthy_domains = sum(1 for r in all_results.values() if r.get("pass_rate", 0) >= 95)
    warning_domains = sum(1 for r in all_results.values() if 50 <= r.get("pass_rate", 0) < 95)
    critical_domains = sum(1 for r in all_results.values() if r.get("pass_rate", 0) < 50)
    
    avg_pass_rate = 0
    if all_results:
        avg_pass_rate = sum(r.get("pass_rate", 0) for r in all_results.values()) / len(all_results)
    
    return {
        "total_domains": total_domains,
        "healthy_domains": healthy_domains,
        "warning_domains": warning_domains,
        "critical_domains": critical_domains,
        "average_pass_rate": round(avg_pass_rate, 2),
        "last_updated": datetime.now().isoformat(),
        "domains": all_results
    }
