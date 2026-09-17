"""
Load Tester - Performance benchmarking framework

Benchmarks system at 1000+ concurrent users, identifies bottlenecks,
and generates detailed performance reports.
"""

import logging
import time
import threading
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass, field
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed

logger = logging.getLogger(__name__)


@dataclass
class LoadTestConfig:
    """Configuration for load testing."""
    concurrent_users: int = 100
    requests_per_user: int = 50
    ramp_up_seconds: int = 30
    test_duration_seconds: int = 300
    target_endpoint: str = "/api/v1/query"
    payload_generator: Optional[Callable] = None
    

@dataclass
class TestResult:
    """Results from a load test run."""
    test_id: str
    start_time: datetime
    end_time: datetime
    total_requests: int
    successful_requests: int
    failed_requests: int
    avg_response_time_ms: float
    p95_response_time_ms: float
    p99_response_time_ms: float
    max_response_time_ms: float
    requests_per_second: float
    error_rate: float
    
    @property
    def success_rate(self) -> float:
        return self.successful_requests / max(self.total_requests, 1)


class LoadTester:
    """Automated load testing framework.
    
    Features:
    - Concurrent user simulation
    - Configurable request patterns
    - Real-time metrics collection
    - Detailed performance reports
    - Error tracking and analysis
    """
    
    def __init__(self, config: Optional[LoadTestConfig] = None):
        self.config = config or LoadTestConfig()
        self.results: List[TestResult] = []
        self._running = False
        
    def run_test(self, request_fn: Callable) -> TestResult:
        """Execute a load test with configured parameters.
        
        Args:
            request_fn: Function that makes a single request
            
        Returns:
            TestResult with comprehensive metrics
        """
        logger.info(f"Starting load test: {self.config.concurrent_users} concurrent users")
        
        test_id = f"test_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        start_time = datetime.now()
        
        response_times = []
        success_count = 0
        failure_count = 0
        
        def worker(user_id: int):
            nonlocal success_count, failure_count
            for req_num in range(self.config.requests_per_user):
                try:
                    start_req = time.time()
                    request_fn(user_id=user_id, request_num=req_num)
                    elapsed = (time.time() - start_req) * 1000
                    response_times.append(elapsed)
                    success_count += 1
                except Exception as e:
                    logger.error(f"Request failed: {e}")
                    failure_count += 1
        
        # Execute with thread pool
        with ThreadPoolExecutor(max_workers=self.config.concurrent_users) as executor:
            futures = [
                executor.submit(worker, user_id) 
                for user_id in range(self.config.concurrent_users)
            ]
            
            for future in as_completed(futures):
                try:
                    future.result()
                except Exception as e:
                    logger.error(f"Worker error: {e}")
        
        end_time = datetime.now()
        
        # Calculate metrics
        result = self._calculate_metrics(
            test_id=test_id,
            start_time=start_time,
            end_time=end_time,
            response_times=response_times,
            success_count=success_count,
            failure_count=failure_count
        )
        
        self.results.append(result)
        logger.info(f"Load test complete: {result.requests_per_second:.2f} req/s")
        
        return result
    
    def _calculate_metrics(
        self,
        test_id: str,
        start_time: datetime,
        end_time: datetime,
        response_times: List[float],
        success_count: int,
        failure_count: int
    ) -> TestResult:
        """Calculate comprehensive test metrics."""
        
        total_requests = success_count + failure_count
        duration_seconds = (end_time - start_time).total_seconds()
        
        sorted_times = sorted(response_times) if response_times else [0]
        
        avg_response = sum(sorted_times) / len(sorted_times)
        p95_idx = int(len(sorted_times) * 0.95)
        p99_idx = int(len(sorted_times) * 0.99)
        
        return TestResult(
            test_id=test_id,
            start_time=start_time,
            end_time=end_time,
            total_requests=total_requests,
            successful_requests=success_count,
            failed_requests=failure_count,
            avg_response_time_ms=avg_response,
            p95_response_time_ms=sorted_times[min(p95_idx, len(sorted_times)-1)],
            p99_response_time_ms=sorted_times[min(p99_idx, len(sorted_times)-1)],
            max_response_time_ms=max(sorted_times),
            requests_per_second=total_requests / max(duration_seconds, 0.001),
            error_rate=failure_count / max(total_requests, 1)
        )
    
    def get_report(self) -> Dict[str, Any]:
        """Generate comprehensive test report."""
        if not self.results:
            return {"status": "no_tests_run"}
        
        latest = self.results[-1]
        return {
            "latest_test": {
                "test_id": latest.test_id,
                "duration_seconds": (latest.end_time - latest.start_time).total_seconds(),
                "throughput_rps": latest.requests_per_second,
                "avg_response_ms": latest.avg_response_time_ms,
                "p95_response_ms": latest.p95_response_time_ms,
                "p99_response_ms": latest.p99_response_time_ms,
                "error_rate": latest.error_rate,
                "success_rate": latest.success_rate
            },
            "historical_summary": {
                "total_tests": len(self.results),
                "avg_throughput": sum(r.requests_per_second for r in self.results) / len(self.results),
                "best_throughput": max(r.requests_per_second for r in self.results)
            }
        }
