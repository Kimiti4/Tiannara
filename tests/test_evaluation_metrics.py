"""Unit tests for evaluation metrics."""

import pytest
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.metrics import Metrics


class TestMetricsClass:
    """Test suite for Metrics class."""
    
    def test_correctness_success(self):
        """Successful result should return 1.0."""
        metrics = Metrics()
        result = {"success": True}
        assert metrics.correctness(result) == 1.0
    
    def test_correctness_failure(self):
        """Failed result should return 0.0."""
        metrics = Metrics()
        result = {"success": False}
        assert metrics.correctness(result) == 0.0
    
    def test_correctness_missing_key(self):
        """Missing success key should return 0.0."""
        metrics = Metrics()
        result = {"output": 5.0}
        assert metrics.correctness(result) == 0.0
    
    def test_runtime_calculation(self):
        """Should calculate runtime correctly."""
        metrics = Metrics()
        runtime = metrics.runtime(start_time=100.0, end_time=105.5)
        assert runtime == 5.5
    
    def test_runtime_negative_protection(self):
        """Should protect against negative runtime."""
        metrics = Metrics()
        runtime = metrics.runtime(start_time=105.0, end_time=100.0)
        assert runtime == 0.0  # Should be clamped to 0
    
    def test_error_rate_with_error(self):
        """Result with error should return 1.0."""
        metrics = Metrics()
        result = {"error": True}
        assert metrics.error_rate(result) == 1.0
    
    def test_error_rate_without_error(self):
        """Result without error should return 0.0."""
        metrics = Metrics()
        result = {"error": False}
        assert metrics.error_rate(result) == 0.0
    
    def test_output_size_string(self):
        """Should calculate string output size."""
        metrics = Metrics()
        result = {"output": "hello"}
        assert metrics.output_size(result) == 5
    
    def test_output_size_list(self):
        """Should calculate list output size as string length."""
        metrics = Metrics()
        result = {"output": [1, 2, 3]}
        # Converts to string "[1, 2, 3]" which is 9 characters
        assert metrics.output_size(result) == 9
    
    def test_consistency_identical(self):
        """Identical outputs should have low consistency score."""
        metrics = Metrics()
        outputs = [5.0, 5.0, 5.0]
        consistency = metrics.consistency(outputs)
        # 1 unique / 3 total = 0.333
        assert abs(consistency - 0.333) < 0.01
    
    def test_consistency_varied(self):
        """Varied outputs should have lower consistency."""
        metrics = Metrics()
        outputs = [1.0, 5.0, 10.0]
        consistency = metrics.consistency(outputs)
        assert consistency > 0.0  # Some variance


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
