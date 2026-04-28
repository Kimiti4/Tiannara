"""
Windows-Stable Distributed Manager

Provides stable multiprocessing with automatic fallback for Windows systems.
Addresses pipe permission issues and other Windows-specific problems.
"""

import os
import sys
import statistics
import traceback
import logging
from typing import List, Dict, Any, Optional, Callable, Union
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor, as_completed
from multiprocessing import get_context, Process
from dataclasses import dataclass
import time
import threading


# Define types for better type hinting
TaskFunction = Callable[..., Any]
TaskResultData = Dict[str, Any]


@dataclass
class ExecutionResult:
    """Result of distributed execution with enhanced metadata."""
    result: TaskResultData
    worker_id: int
    backend: str
    execution_time: float
    success: bool
    error: Optional[str] = None
    task_id: Optional[str] = None
    timestamp: float = time.time()


class WindowsStableManager:
    """
    Windows-stable distributed execution manager.
    
    Automatically detects the best execution backend and provides
    graceful fallback when multiprocessing fails.
    """
    
    def __init__(self, default_workers: int = 4, force_backend: Optional[str] = None):
        self.default_workers = default_workers
        self.force_backend = force_backend
        self.logger = logging.getLogger("tiannara.distributed")
        
        # Detect optimal backend for this platform
        self.optimal_backend = self._detect_optimal_backend()
        
        # Track backend performance
        self.backend_performance = {
            "process": {"success_rate": 1.0, "avg_time": 0.0, "attempts": 0},
            "thread": {"success_rate": 1.0, "avg_time": 0.0, "attempts": 0},
            "serial": {"success_rate": 1.0, "avg_time": 0.0, "attempts": 0}
        }
    
    def _detect_optimal_backend(self) -> str:
        """Detect the optimal backend for the current platform."""
        if self.force_backend:
            return self.force_backend
        
        # Windows: prefer threading due to pipe issues
        if os.name == "nt":
            self.logger.info("Windows detected - defaulting to thread backend")
            return "thread"
        
        # Unix-like systems: can use multiprocessing
        return "process"
    
    def run_distributed(self, 
                       tasks: List[Dict[str, Any]] | List[Callable],
                       workers: Optional[int] = None,
                       backend: Optional[str] = None,
                       task_type: str = "config") -> List[ExecutionResult]:
        """
        Run tasks distributed across workers.
        
        Args:
            tasks: Either a list of configuration dictionaries or callable functions
            workers: Number of workers (auto-detected if None)
            backend: Force specific backend ("process", "thread", "serial")
            task_type: Type of tasks ("config" for configs or "function" for callables)
            
        Returns:
            List of ExecutionResult objects
        """
        if not tasks:
            return []
        
        # Determine worker count
        worker_count = self._determine_worker_count(tasks, workers)
        
        # Determine backend
        execution_backend = backend or self.optimal_backend
        
        self.logger.info(f"Running {len(tasks)} {task_type} tasks with {worker_count} workers using {execution_backend} backend")
        
        # Execute with chosen backend
        if execution_backend == "process":
            results = self._run_with_processes(tasks, worker_count, task_type)
        elif execution_backend == "thread":
            results = self._run_with_threads(tasks, worker_count, task_type)
        else:
            results = self._run_serial(tasks, task_type)
        
        # Update backend performance metrics
        self._update_performance_metrics(execution_backend, results)
        
        return results
    
    def _run_with_processes(self, tasks: List[Dict[str, Any]] | List[Callable], 
                          workers: int, task_type: str) -> List[ExecutionResult]:
        """Run using multiprocessing with better task handling."""
        results = []
        
        try:
            # Use spawn context for better compatibility
            ctx = get_context("spawn")
            
            if task_type == "config":
                # Config-based tasks
                with ProcessPoolExecutor(max_workers=workers, mp_context=ctx) as executor:
                    # Submit all tasks
                    future_to_config = {
                        executor.submit(self._safe_worker_run, task, i): (task, i)
                        for i, task in enumerate(tasks)
                    }
                    
                    # Collect results as they complete
                    for future in as_completed(future_to_config):
                        config, worker_id = future_to_config[future]
                        
                        try:
                            result_data, exec_time = future.result(timeout=300)  # 5 minute timeout
                            results.append(ExecutionResult(
                                result=result_data,
                                worker_id=worker_id,
                                backend="process",
                                execution_time=exec_time,
                                success=True
                            ))
                        except Exception as e:
                            self.logger.warning(f"Process worker {worker_id} failed: {e}")
                            results.append(ExecutionResult(
                                result={"score": 0.0, "error": str(e)},
                                worker_id=worker_id,
                                backend="process",
                                execution_time=0.0,
                                success=False,
                                error=str(e)
                            ))
            else:
                # Function-based tasks
                with ProcessPoolExecutor(max_workers=workers, mp_context=ctx) as executor:
                    # Submit all tasks
                    future_to_task = {
                        executor.submit(self._execute_task, task, None, None, f"task_{i}", i): (task, i)
                        for i, task in enumerate(tasks)
                    }
                    
                    # Collect results as they complete
                    for future in as_completed(future_to_task):
                        task, task_id = future_to_task[future]
                        
                        try:
                            result_data = future.result(timeout=300)  # 5 minute timeout
                            results.append(ExecutionResult(
                                result=result_data,
                                worker_id=task_id % workers,
                                backend="process",
                                execution_time=result_data.get("execution_time", 0.0),
                                success=result_data.get("success", False),
                                task_id=result_data.get("task_id", f"task_{task_id}")
                            ))
                        except Exception as e:
                            self.logger.warning(f"Process task {task_id} failed: {e}")
                            results.append(ExecutionResult(
                                result={"score": 0.0, "error": str(e)},
                                worker_id=task_id % workers,
                                backend="process",
                                execution_time=0.0,
                                success=False,
                                error=str(e),
                                task_id=f"task_{task_id}"
                            ))
            
            self.logger.info(f"Process execution completed: {len(results)} results")
            
        except Exception as e:
            self.logger.error(f"Process backend failed completely: {e}")
            self.logger.debug(traceback.format_exc())
            
            # Fallback to threading
            self.logger.info("Falling back to thread backend")
            return self._run_with_threads(tasks, workers, task_type)
        
        return results
    
    def _run_with_threads(self, tasks: List[Dict[str, Any]] | List[Callable], 
                        workers: int, task_type: str) -> List[ExecutionResult]:
        """Run using threading with enhanced task management."""
        results = []
        
        try:
            with ThreadPoolExecutor(max_workers=workers) as executor:
                if task_type == "config":
                    # Config-based tasks
                    future_to_config = {
                        executor.submit(self._safe_worker_run, task, i): (task, i)
                        for i, task in enumerate(tasks)
                    }
                    
                    # Collect results as they complete
                    for future in as_completed(future_to_config):
                        config, worker_id = future_to_config[future]
                        
                        try:
                            result_data, exec_time = future.result(timeout=600)  # 10 minute timeout
                            results.append(ExecutionResult(
                                result=result_data,
                                worker_id=worker_id,
                                backend="thread",
                                execution_time=exec_time,
                                success=True
                            ))
                        except Exception as e:
                            self.logger.warning(f"Thread worker {worker_id} failed: {e}")
                            results.append(ExecutionResult(
                                result={"score": 0.0, "error": str(e)},
                                worker_id=worker_id,
                                backend="thread",
                                execution_time=0.0,
                                success=False,
                                error=str(e)
                            ))
                else:
                    # Function-based tasks
                    future_to_task = {
                        executor.submit(self._execute_task, task, None, None, f"task_{i}", i): (task, i)
                        for i, task in enumerate(tasks)
                    }
                    
                    # Collect results as they complete
                    for future in as_completed(future_to_task):
                        task, task_id = future_to_task[future]
                        
                        try:
                            result_data = future.result(timeout=600)  # 10 minute timeout
                            results.append(ExecutionResult(
                                result=result_data,
                                worker_id=task_id % workers,
                                backend="thread",
                                execution_time=result_data.get("execution_time", 0.0),
                                success=result_data.get("success", False),
                                task_id=result_data.get("task_id", f"task_{task_id}")
                            ))
                        except Exception as e:
                            self.logger.warning(f"Thread task {task_id} failed: {e}")
                            results.append(ExecutionResult(
                                result={"score": 0.0, "error": str(e)},
                                worker_id=task_id % workers,
                                backend="thread",
                                execution_time=0.0,
                                success=False,
                                error=str(e),
                                task_id=f"task_{task_id}"
                            ))
            
            self.logger.info(f"Thread execution completed: {len(results)} results")
            
        except Exception as e:
            self.logger.error(f"Thread backend failed completely: {e}")
            self.logger.debug(traceback.format_exc())
            
            # Final fallback to serial
            self.logger.info("Falling back to serial execution")
            return self._run_serial(tasks, task_type)
        
        return results
    
    def _determine_worker_count(self, configs: List[Dict[str, Any]], workers: Optional[int]) -> int:
        """Determine optimal worker count."""
        if workers:
            return max(1, min(int(workers), len(configs)))
        
        # Auto-detect based on CPU and config count
        cpu_count = os.cpu_count() or 2
        
        # Windows: be more conservative with threading
        if os.name == "nt":
            return max(1, min(cpu_count // 2, len(configs), self.default_workers))
        
        # Unix: can be more aggressive
        return max(1, min(cpu_count, len(configs), self.default_workers))
    
    def _run_with_processes(self, configs: List[Dict[str, Any]], workers: int) -> List[ExecutionResult]:
        """Run using multiprocessing (Unix preferred)."""
        results = []
        
        try:
            # Use spawn context for better compatibility
            ctx = get_context("spawn")
            
            with ProcessPoolExecutor(max_workers=workers, mp_context=ctx) as executor:
                # Submit all tasks
                future_to_config = {
                    executor.submit(self._safe_worker_run, config, i): (config, i)
                    for i, config in enumerate(configs)
                }
                
                # Collect results as they complete
                for future in as_completed(future_to_config):
                    config, worker_id = future_to_config[future]
                    
                    try:
                        result_data, exec_time = future.result(timeout=300)  # 5 minute timeout
                        results.append(ExecutionResult(
                            result=result_data,
                            worker_id=worker_id,
                            backend="process",
                            execution_time=exec_time,
                            success=True
                        ))
                    except Exception as e:
                        self.logger.warning(f"Process worker {worker_id} failed: {e}")
                        results.append(ExecutionResult(
                            result={"score": 0.0, "error": str(e)},
                            worker_id=worker_id,
                            backend="process",
                            execution_time=0.0,
                            success=False,
                            error=str(e)
                        ))
            
            self.logger.info(f"Process execution completed: {len(results)} results")
            
        except Exception as e:
            self.logger.error(f"Process backend failed completely: {e}")
            self.logger.debug(traceback.format_exc())
            
            # Fallback to threading
            self.logger.info("Falling back to thread backend")
            return self._run_with_threads(configs, workers)
        
        return results
    
    def _run_with_threads(self, configs: List[Dict[str, Any]], workers: int) -> List[ExecutionResult]:
        """Run using threading (Windows safe)."""
        results = []
        
        try:
            with ThreadPoolExecutor(max_workers=workers) as executor:
                # Submit all tasks
                future_to_config = {
                    executor.submit(self._safe_worker_run, config, i): (config, i)
                    for i, config in enumerate(configs)
                }
                
                # Collect results as they complete
                for future in as_completed(future_to_config):
                    config, worker_id = future_to_config[future]
                    
                    try:
                        result_data, exec_time = future.result(timeout=600)  # 10 minute timeout
                        results.append(ExecutionResult(
                            result=result_data,
                            worker_id=worker_id,
                            backend="thread",
                            execution_time=exec_time,
                            success=True
                        ))
                    except Exception as e:
                        self.logger.warning(f"Thread worker {worker_id} failed: {e}")
                        results.append(ExecutionResult(
                            result={"score": 0.0, "error": str(e)},
                            worker_id=worker_id,
                            backend="thread",
                            execution_time=0.0,
                            success=False,
                            error=str(e)
                        ))
            
            self.logger.info(f"Thread execution completed: {len(results)} results")
            
        except Exception as e:
            self.logger.error(f"Thread backend failed completely: {e}")
            self.logger.debug(traceback.format_exc())
            
            # Final fallback to serial
            self.logger.info("Falling back to serial execution")
            return self._run_serial(configs)
        
        return results
    
    def _run_serial(self, configs: List[Dict[str, Any]]) -> List[ExecutionResult]:
        """Run serially (ultimate fallback)."""
        results = []
        
        self.logger.info("Running serial execution")
        
        for i, config in enumerate(configs):
            try:
                result_data, exec_time = self._safe_worker_run(config, i)
                results.append(ExecutionResult(
                    result=result_data,
                    worker_id=i,
                    backend="serial",
                    execution_time=exec_time,
                    success=True
                ))
            except Exception as e:
                self.logger.warning(f"Serial execution {i} failed: {e}")
                results.append(ExecutionResult(
                    result={"score": 0.0, "error": str(e)},
                    worker_id=i,
                    backend="serial",
                    execution_time=0.0,
                    success=False,
                    error=str(e)
                ))
        
        return results
    
    def _execute_task(self, task: TaskFunction, task_args: Union[tuple, None], task_kwargs: Union[dict, None], 
                     task_id: Optional[str] = None, worker_id: int = 0) -> TaskResultData:
        """Execute a single task with error handling and metadata tracking."""
        start_time = time.time()
        
        try:
            # Handle different task types
            if task_args is None and task_kwargs is None:
                result = task()
            elif task_args is not None and task_kwargs is None:
                result = task(*task_args)
            elif task_args is None and task_kwargs is not None:
                result = task(**task_kwargs)
            else:
                result = task(*task_args, **task_kwargs)
            
            execution_time = time.time() - start_time
            
            # Ensure result has required metadata
            if isinstance(result, dict):
                result_data = result
            else:
                # Wrap non-dict results in a standard format
                result_data = {
                    "result": result,
                    "score": float(result) if isinstance(result, (int, float)) else 0.0
                }
            
            result_data.update({
                "success": True,
                "execution_time": execution_time,
                "worker_id": worker_id
            })
            
            if task_id:
                result_data["task_id"] = task_id
                
            return result_data
            
        except Exception as e:
            execution_time = time.time() - start_time
            self.logger.debug(f"Task {task_id or worker_id} error: {e}")
            
            # Return error result with metadata
            error_result = {
                "success": False,
                "error": str(e),
                "error_type": type(e).__name__,
                "execution_time": execution_time,
                "worker_id": worker_id,
                "traceback": traceback.format_exc()
            }
            
            if task_id:
                error_result["task_id"] = task_id
                
            return error_result
    
    def _safe_worker_run(self, config: Dict[str, Any], worker_id: int) -> tuple[Dict[str, Any], float]:
        """Safely run worker with timing and error handling."""
        start_time = time.time()
        
        try:
            result = run_worker(config)
            exec_time = time.time() - start_time
            
            # Ensure result has required fields
            if not isinstance(result, dict):
                result = {"result": result, "score": float(result) if isinstance(result, (int, float)) else 0.0}
            
            result.update({
                "success": True,
                "worker_id": worker_id,
                "execution_time": exec_time
            })
            
            return result, exec_time
            
        except Exception as e:
            exec_time = time.time() - start_time
            self.logger.debug(f"Worker {worker_id} error: {e}")
            
            # Return error result with enhanced metadata
            return {
                "success": False,
                "score": 0.0,
                "worker_id": worker_id,
                "error": str(e),
                "error_type": type(e).__name__,
                "config": config.get("worker_id", "unknown"),
                "traceback": traceback.format_exc()
            }, exec_time
    
    def _update_performance_metrics(self, backend: str, results: List[ExecutionResult]):
        """Update backend performance metrics."""
        if not results:
            return
        
        successful = [r for r in results if r.success]
        success_rate = len(successful) / len(results)
        avg_time = statistics.mean([r.execution_time for r in results]) if results else 0.0
        
        self.backend_performance[backend].update({
            "success_rate": success_rate,
            "avg_time": avg_time,
            "attempts": self.backend_performance[backend]["attempts"] + 1
        })
        
        # Adjust optimal backend if needed
        self._maybe_adjust_optimal_backend()
    
    def _maybe_adjust_optimal_backend(self):
        """Adjust optimal backend based on performance."""
        # Only adjust after several attempts
        total_attempts = sum(perf["attempts"] for perf in self.backend_performance.values())
        if total_attempts < 10:
            return
        
        # Check if current optimal backend is underperforming
        current_perf = self.backend_performance[self.optimal_backend]
        
        if current_perf["success_rate"] < 0.8:
            # Find better backend
            for backend, perf in self.backend_performance.items():
                if (perf["success_rate"] > current_perf["success_rate"] + 0.1 and 
                    perf["attempts"] >= 3):
                    self.logger.info(f"Switching optimal backend from {self.optimal_backend} to {backend}")
                    self.optimal_backend = backend
                    break
    
    def get_performance_summary(self) -> Dict[str, Any]:
        """Get performance summary for all backends."""
        return {
            "optimal_backend": self.optimal_backend,
            "platform": os.name,
            "backend_performance": self.backend_performance.copy(),
            "recommendations": self._generate_recommendations()
        }
    
    def _generate_recommendations(self) -> List[str]:
        """Generate performance recommendations."""
        recommendations = []
        
        # Check for problematic backends
        for backend, perf in self.backend_performance.items():
            if perf["attempts"] >= 5 and perf["success_rate"] < 0.7:
                recommendations.append(f"Consider avoiding {backend} backend - low success rate ({perf['success_rate']:.1%})")
        
        # Platform-specific recommendations
        if os.name == "nt":
            if self.backend_performance["process"]["success_rate"] < 0.8:
                recommendations.append("On Windows, thread backend is more reliable than process backend")
        else:
            if self.backend_performance["thread"]["success_rate"] < 0.8:
                recommendations.append("On Unix systems, process backend may perform better for CPU-bound tasks")
        
        return recommendations
    
    def test_backends(self, test_configs: Optional[List[Dict[str, Any]]] = None) -> Dict[str, Any]:
        """Test all backends with a small workload."""
        if test_configs is None:
            # Create minimal test configs
            test_configs = [
                {
                    "worker_id": i,
                    "question": "test_backend",
                    "population_size": 5,
                    "generations": 2,
                    "fitness_function": "test"
                }
                for i in range(min(3, self.default_workers))
            ]
        
        test_results = {}
        
        for backend in ["serial", "thread", "process"]:
            self.logger.info(f"Testing {backend} backend...")
            
            try:
                results = self.run_distributed(test_configs, workers=2, backend=backend)
                test_results[backend] = {
                    "success": True,
                    "results_count": len(results),
                    "success_rate": len([r for r in results if r.success]) / len(results) if results else 0,
                    "avg_time": statistics.mean([r.execution_time for r in results]) if results else 0
                }
            except Exception as e:
                test_results[backend] = {
                    "success": False,
                    "error": str(e)
                }
        
        return test_results


# Global manager instance
_windows_manager = None

def get_windows_stable_manager(**kwargs) -> WindowsStableManager:
    """Get or create the global Windows-stable manager instance."""
    global _windows_manager
    if _windows_manager is None:
        _windows_manager = WindowsStableManager(**kwargs)
    return _windows_manager

def run_distributed_safe(tasks: List[Dict[str, Any]] | List[Callable],
                        workers: Optional[int] = None,
                        backend: Optional[str] = None,
                        task_type: str = "config") -> List[Dict[str, Any]]:
    """
    Safe distributed execution that works reliably on Windows.
    
    This is the main entry point for distributed execution.
    
    Args:
        tasks: List of configuration dictionaries or callable functions
        workers: Number of workers (auto-detected if None)
        backend: Force specific backend ("process", "thread", "serial")
        task_type: Type of tasks ("config" for configs or "function" for callables)
        
    Returns:
        List of result dictionaries sorted by score descending
    """
    manager = get_windows_stable_manager()
    
    # Run with Windows-stable manager
    execution_results = manager.run_distributed(tasks, workers, backend, task_type)
    
    # Convert back to original format
    results = []
    for exec_result in execution_results:
        result = exec_result.result.copy()
        result["execution_backend"] = exec_result.backend
        result["execution_time"] = exec_result.execution_time
        if "task_id" in exec_result.result:
            result["task_id"] = exec_result.result["task_id"]
        results.append(result)
    
    # Sort by score if available
    return sorted(results, key=lambda item: item.get("score", 0.0), reverse=True)

def summarize_results_safe(results: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Safe results summarization with enhanced metadata and error tracking."""
    if not results:
        return {
            "total_tasks": 0,
            "successful": 0,
            "failed": 0,
            "success_rate": 0.0,
            "avg_score": 0.0,
            "best_score": 0.0,
            "backend_distribution": {},
            "error_summary": {
                "total_errors": 0,
                "error_types": {},
                "error_distribution": {}
            },
            "execution_summary": {
                "total_time": 0.0,
                "avg_time": 0.0,
                "fastest_task": 0.0,
                "slowest_task": 0.0
            }
        }
    
    scores = []
    error_types = {}
    backend_counts = {}
    execution_times = []
    successful_count = 0
    error_count = 0
    
    for item in results:
        # Score tracking
        score = float(item.get("score", 0.0) or 0.0)
        if score > 0:
            scores.append(score)
        
        # Backend tracking
        backend = item.get("execution_backend", "unknown")
        backend_counts[backend] = backend_counts.get(backend, 0) + 1
        
        # Error tracking
        if not item.get("success", True):
            error_count += 1
            error_type = item.get("error_type", "UnknownError")
            error_types[error_type] = error_types.get(error_type, 0) + 1
            
            # Track error by backend
            backend_counts[backend] = backend_counts.get(backend, 0) + 1
        
        # Success tracking
        if score > 0 or item.get("success", False):
            successful_count += 1
            
        # Execution time tracking
        exec_time = item.get("execution_time", 0.0)
        if exec_time > 0:
            execution_times.append(exec_time)
    
    # Calculate metrics
    total_tasks = len(results)
    success_rate = successful_count / total_tasks if total_tasks else 0.0
    
    summary = {
        "total_tasks": total_tasks,
        "successful": successful_count,
        "failed": error_count,
        "success_rate": success_rate,
        "avg_score": round(statistics.fmean(scores), 4) if scores else 0.0,
        "best_score": round(max(scores), 4) if scores else 0.0,
        "backend_distribution": backend_counts,
        "error_summary": {
            "total_errors": error_count,
            "error_types": error_types,
            "error_distribution": {
                backend: round(count / total_tasks, 2) 
                for backend, count in backend_counts.items()
            }
        },
        "execution_summary": {
            "total_time": round(sum(execution_times), 2) if execution_times else 0.0,
            "avg_time": round(statistics.fmean(execution_times), 2) if execution_times else 0.0,
            "fastest_task": round(min(execution_times), 2) if execution_times else 0.0,
            "slowest_task": round(max(execution_times), 2) if execution_times else 0.0
        }
    }