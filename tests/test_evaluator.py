"""Unit tests for the Evaluator component."""

import pytest
import sys
from pathlib import Path
import time

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.evaluator import Evaluator


class TestEvaluatorBasic:
    """Test basic Evaluator functionality."""
    
    def test_evaluator_initialization(self):
        """Evaluator should initialize without errors."""
        evaluator = Evaluator()
        assert evaluator is not None
    
    def test_evaluate_success_case(self):
        """Should evaluate successful function execution."""
        evaluator = Evaluator()
        
        def good_function(**kwargs):
            return {"output": 42, "success": True}
        
        task_inputs = {"x": 5}
        result = evaluator.evaluate(good_function, task_inputs)
        
        assert "metrics" in result
        assert "correctness" in result["metrics"]
        assert result["metrics"]["correctness"] == 1.0
    
    def test_evaluate_failure_case(self):
        """Should handle function that raises exceptions."""
        evaluator = Evaluator()
        
        def bad_function(**kwargs):
            raise ValueError("Test error")
        
        task_inputs = {"x": 5}
        result = evaluator.evaluate(bad_function, task_inputs)
        
        assert "metrics" in result
        assert result["metrics"]["error"] == 1.0
    
    def test_evaluate_timeout(self):
        """Should handle functions that take too long."""
        evaluator = Evaluator()
        evaluator.timeout_seconds = 0.1  # 100ms timeout
        
        def slow_function(**kwargs):
            time.sleep(1)  # Sleep for 1 second
            return {"output": 42, "success": True}
        
        task_inputs = {"x": 5}
        result = evaluator.evaluate(slow_function, task_inputs)
        
        # Should have timed out or completed quickly
        assert result["metrics"]["error"] == 1.0 or result["metrics"]["runtime"] < 0.5
    
    def test_evaluate_returns_dict(self):
        """Evaluate should return a dictionary with expected keys."""
        evaluator = Evaluator()
        
        def simple_function(**kwargs):
            return kwargs.get("x", 0) * 2
        
        result = evaluator.evaluate(simple_function, {"x": 5})
        
        assert isinstance(result, dict)
        assert "metrics" in result
        assert "runtime" in result["metrics"]
        assert "correctness" in result["metrics"]
    
    def test_evaluate_measures_runtime(self):
        """Should accurately measure function runtime."""
        evaluator = Evaluator()
        
        def timed_function(**kwargs):
            time.sleep(0.05)  # 50ms
            return 42
        
        start = time.time()
        result = evaluator.evaluate(timed_function, {})
        end = time.time()
        
        runtime = result["metrics"]["runtime"]
        assert runtime >= 0.05  # At least 50ms
        assert runtime < (end - start) + 0.1  # Reasonable upper bound
    
    def test_evaluate_with_kwargs(self):
        """Should pass kwargs to function correctly."""
        evaluator = Evaluator()
        
        def multi_arg_function(x, y, z=10):
            return x + y + z
        
        result = evaluator.evaluate(multi_arg_function, {"x": 1, "y": 2, "z": 3})
        
        assert result["metrics"]["correctness"] == 1.0
    
    def test_evaluate_output_capture(self):
        """Should capture function output."""
        evaluator = Evaluator()
        
        def returning_function(**kwargs):
            return {"value": 100, "status": "ok", "success": True}
        
        result = evaluator.evaluate(returning_function, {})
        
        assert "outputs" in result
        assert len(result["outputs"]) > 0


class TestEvaluatorEdgeCases:
    """Test edge cases and error handling."""
    
    def test_evaluate_none_function(self):
        """Should handle None function gracefully."""
        evaluator = Evaluator()
        
        try:
            result = evaluator.evaluate(None, {})
            # If it doesn't crash, check it reports error
            assert result["metrics"]["error"] == 1.0
        except (TypeError, AttributeError):
            # Acceptable to raise exception
            pass
    
    def test_evaluate_empty_inputs(self):
        """Should handle empty input dictionary."""
        evaluator = Evaluator()
        
        def no_arg_function():
            return 42
        
        result = evaluator.evaluate(no_arg_function, {})
        assert result["metrics"]["correctness"] == 1.0
    
    def test_evaluate_complex_output(self):
        """Should handle complex output types."""
        evaluator = Evaluator()
        
        def complex_output(**kwargs):
            return {
                "list": [1, 2, 3],
                "dict": {"nested": True},
                "tuple": (4, 5, 6)
            }
        
        result = evaluator.evaluate(complex_output, {})
        assert result["metrics"]["correctness"] == 1.0
    
    def test_multiple_evaluations(self):
        """Should handle multiple sequential evaluations."""
        evaluator = Evaluator()
        
        results = []
        for i in range(5):
            def func(**kwargs):
                return i
            
            result = evaluator.evaluate(func, {})
            results.append(result)
        
        assert len(results) == 5
        assert all(r["metrics"]["correctness"] == 1.0 for r in results)


class TestEvaluatorMetrics:
    """Test that evaluator computes metrics correctly."""
    
    def test_correctness_metric_computation(self):
        """Correctness should be 1.0 for successful execution."""
        evaluator = Evaluator()
        
        def success_func(**kwargs):
            return True
        
        result = evaluator.evaluate(success_func, {})
        assert result["metrics"]["correctness"] == 1.0
    
    def test_error_rate_metric_computation(self):
        """Error rate should be 1.0 for failed execution."""
        evaluator = Evaluator()
        
        def fail_func(**kwargs):
            raise RuntimeError("Intentional failure")
        
        result = evaluator.evaluate(fail_func, {})
        assert result["metrics"]["error"] == 1.0
    
    def test_runtime_metric_positive(self):
        """Runtime should always be non-negative."""
        evaluator = Evaluator()
        
        def instant_func(**kwargs):
            return None
        
        result = evaluator.evaluate(instant_func, {})
        assert result["metrics"]["runtime"] >= 0.0
    
    def test_novelty_metric_present(self):
        """Novelty metric should be computed."""
        evaluator = Evaluator()
        
        def simple_func(**kwargs):
            return {"output": 42, "success": True}
        
        result = evaluator.evaluate(simple_func, {})
        assert "novelty" in result["metrics"]
        assert 0.0 <= result["metrics"]["novelty"] <= 1.0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
