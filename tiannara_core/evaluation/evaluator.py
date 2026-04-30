"""
Master Evaluator - Integrates all evaluation components.

This is the primary interface for evaluating system performance.
It orchestrates metrics extraction, novelty tracking, stability checking,
scoring, and history logging to produce comprehensive evaluation results.
"""

import time
import threading
from typing import Callable, Any, Dict, List

from .metrics import Metrics
from .novelty import NoveltyTracker
from .stability import StabilityChecker
from .scoring import Scorer
from .history import EvaluationHistory


class Evaluator:
    """
    Master evaluation system combining multiple intelligence signals.
    
    Produces multi-dimensional scores that feed causal and evolution loops,
    enabling true learning signals across different domains.
    """

    def __init__(self, weights: dict = None):
        """
        Initialize evaluator with all sub-components.
        
        Args:
            weights: Optional custom weights for scoring (passed to Scorer)
        """
        self.metrics = Metrics()
        self.novelty = NoveltyTracker()
        self.stability = StabilityChecker()
        self.scorer = Scorer(weights=weights)
        self.history = EvaluationHistory()
        
        # Performance fix: Timeout configuration
        self.timeout_seconds = 5  # Max 5 seconds per function call
    
    def _execute_with_timeout(self, func: Callable, inputs: Dict[str, Any], timeout: float = None) -> Dict[str, Any]:
        """
        Performance fix: Execute function with timeout to prevent hanging.
        
        Uses threading to enforce time limit on function execution.
        Works on Windows (unlike signal.SIGALRM).
        
        Args:
            func: Function to execute
            inputs: Input parameters
            timeout: Timeout in seconds (uses self.timeout_seconds if None)
            
        Returns:
            Result dictionary or error dict if timeout/exception
        """
        if timeout is None:
            timeout = self.timeout_seconds
        
        result_container = {"result": None, "error": None}
        
        def target():
            try:
                result_container["result"] = func(**inputs)
            except Exception as e:
                result_container["error"] = e
        
        thread = threading.Thread(target=target)
        thread.daemon = True
        thread.start()
        thread.join(timeout=timeout)
        
        if thread.is_alive():
            # Thread still running after timeout - kill it
            return {
                "error": f"Execution exceeded {timeout}s timeout",
                "success": False,
                "timeout": True
            }
        
        if result_container["error"] is not None:
            return {
                "error": str(result_container["error"]),
                "success": False,
                "exception_type": type(result_container["error"]).__name__
            }
        
        result = result_container["result"]
        # Ensure result has success flag
        if not isinstance(result, dict):
            result = {"output": result, "success": True}
        elif "success" not in result:
            result["success"] = True
        
        return result

    def evaluate(
        self,
        func: Callable,
        inputs: Dict[str, Any],
        runs: int = 3
    ) -> Dict[str, Any]:
        """
        Evaluate a function across multiple runs with comprehensive metrics.
        
        This is the main evaluation method that orchestrates all components:
        1. Executes function multiple times
        2. Extracts raw metrics
        3. Computes stability
        4. Calculates novelty
        5. Produces weighted score
        6. Logs to history
        
        Args:
            func: Function to evaluate (should accept **inputs)
            inputs: Dictionary of input parameters
            runs: Number of execution runs for stability analysis
            
        Returns:
            Dictionary containing:
                - score: Final intelligence score (0.0-1.0)
                - metrics: Dictionary of individual metric values
                - outputs: List of all execution outputs
                - episode_id: Unique identifier for this evaluation
        """
        outputs = []
        start = time.time()

        # Execute function multiple times with timeout protection
        for _ in range(runs):
            result = self._execute_with_timeout(func, inputs)
            outputs.append(result)

        end = time.time()

        # Extract metrics
        correctness = sum(
            self.metrics.correctness(r) for r in outputs
        ) / len(outputs)

        runtime = self.metrics.runtime(start, end)

        error = sum(
            self.metrics.error_rate(r) for r in outputs
        ) / len(outputs)

        stability_score = self.stability.evaluate(outputs)

        # Build feature vector for novelty tracking
        # This captures the essential characteristics of this evaluation
        vector = [
            correctness,
            runtime,
            error,
            stability_score,
        ]

        novelty_score = self.novelty.compute_novelty(vector)

        # Compile metric bundle
        metric_bundle = {
            "correctness": correctness,
            "runtime": runtime,
            "error": error,
            "stability": stability_score,
            "novelty": novelty_score,
        }

        # Compute final weighted score
        final_score = self.scorer.compute(metric_bundle)

        # Build evaluation record
        record = {
            "metrics": metric_bundle,
            "score": final_score,
            "outputs": outputs,
            "num_runs": runs,
        }

        # Log to history
        self.history.log(record)

        return record

    def evaluate_single(self, func: Callable, inputs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Quick evaluation with single run (no stability analysis).
        
        Use this for fast evaluations where stability isn't critical.
        
        Args:
            func: Function to evaluate
            inputs: Input parameters
            
        Returns:
            Evaluation record (same structure as evaluate())
        """
        return self.evaluate(func, inputs, runs=1)

    def get_history_statistics(self) -> Dict[str, Any]:
        """
        Get statistics about all evaluations performed.
        
        Returns:
            Dictionary with historical statistics
        """
        return self.history.get_statistics()

    def get_best_evaluation(self) -> Dict[str, Any]:
        """
        Get the best evaluation result so far.
        
        Returns:
            Best evaluation record or None
        """
        return self.history.get_best()

    def reset(self):
        """
        Reset all evaluation state (useful for domain changes).
        
        Clears history and novelty tracker while preserving configuration.
        """
        self.history.clear()
        self.novelty.reset()

    def update_weights(self, new_weights: dict):
        """
        Update scoring weights dynamically.
        
        Args:
            new_weights: New weight configuration
        """
        self.scorer.update_weights(new_weights)
