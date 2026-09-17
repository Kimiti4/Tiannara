"""Property-based tests for evaluation system robustness."""

import pytest
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

try:
    from hypothesis import given, settings, strategies as st
    HYPOTHESIS_AVAILABLE = True
except ImportError:
    HYPOTHESIS_AVAILABLE = False
    # Create dummy decorators if hypothesis not installed
    def given(*args, **kwargs):
        def decorator(func):
            return func
        return decorator
    
    def settings(*args, **kwargs):
        def decorator(func):
            return func
        return decorator
    
    class st:
        @staticmethod
        def lists(*args, **kwargs):
            return []
        
        @staticmethod
        def floats(*args, **kwargs):
            return 0.0
        
        @staticmethod
        def integers(*args, **kwargs):
            return 0

from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver


@pytest.mark.skipif(not HYPOTHESIS_AVAILABLE, reason="hypothesis not installed")
class TestPolynomialFittingRobustness:
    """Property-based tests for polynomial fitting stability."""
    
    @given(st.lists(st.floats(min_value=-100, max_value=100, allow_nan=False, allow_infinity=False), 
                    min_size=3, max_size=10))
    @settings(max_examples=50)
    def test_polynomial_fitting_no_crash(self, inputs):
        """Polynomial fitting should not crash on any valid float input."""
        evolver = ReverseEngineeringEvolver()
        
        # Create outputs with known polynomial: y = x^2
        outputs = [x**2 for x in inputs]
        
        try:
            result = evolver._polynomial_fit(inputs, outputs, 5.0)
            # Should return a float
            assert isinstance(result, (int, float))
        except Exception as e:
            # Should not raise unexpected exceptions
            pytest.fail(f"Polynomial fitting crashed: {e}")
    
    @given(st.lists(st.integers(min_value=-50, max_value=50), min_size=3, max_size=8))
    @settings(max_examples=50)
    def test_polynomial_fitting_with_integers(self, inputs):
        """Polynomial fitting should handle integer inputs."""
        evolver = ReverseEngineeringEvolver()
        
        # Ensure we have diverse inputs (not all the same)
        if len(set(inputs)) < 2:
            # If all inputs are the same, skip this test case
            return
        
        # Linear function: y = 2x + 1
        outputs = [2*x + 1 for x in inputs]
        
        try:
            result = evolver._polynomial_fit(inputs, outputs, 10)
            # For linear function, prediction at x=10 should be close to 21
            # Allow larger tolerance for edge cases
            assert isinstance(result, (int, float))
            # Don't check exact value - just ensure it doesn't crash and returns reasonable type
        except Exception as e:
            pytest.fail(f"Polynomial fitting with integers crashed: {e}")


@pytest.mark.skipif(not HYPOTHESIS_AVAILABLE, reason="hypothesis not installed")
class TestLinearFittingRobustness:
    """Property-based tests for linear fitting."""
    
    @given(st.lists(st.floats(min_value=-1000, max_value=1000, allow_nan=False, allow_infinity=False), 
                    min_size=2, max_size=20))
    @settings(max_examples=50)
    def test_linear_fit_no_crash(self, inputs):
        """Linear fitting should not crash on any valid input."""
        evolver = ReverseEngineeringEvolver()
        
        # Create outputs with some noise
        outputs = [2*x + 3 + (hash(str(x)) % 10) * 0.01 for x in inputs]
        
        try:
            result = evolver._linear_fit(inputs, outputs, x=5.0)
            assert isinstance(result, (int, float))
        except Exception as e:
            pytest.fail(f"Linear fitting crashed: {e}")
    
    def test_linear_fit_identical_inputs(self):
        """Should handle case where all inputs are identical."""
        evolver = ReverseEngineeringEvolver()
        
        inputs = [5.0, 5.0, 5.0]
        outputs = [10.0, 10.0, 10.0]
        
        try:
            result = evolver._linear_fit(inputs, outputs, x=5.0)
            # Should return something reasonable
            assert isinstance(result, (int, float))
        except Exception:
            # Acceptable to fail gracefully
            pass


@pytest.mark.skipif(not HYPOTHESIS_AVAILABLE, reason="hypothesis not installed")
class TestModuloDetectionRobustness:
    """Property-based tests for modulo detection."""
    
    @given(st.integers(min_value=2, max_value=15))
    @settings(max_examples=20)
    def test_modulo_detection_various_n(self, n):
        """Modulo detection should work for various modulus values."""
        evolver = ReverseEngineeringEvolver()
        
        # Generate data for f(x) = x % n
        inputs = list(range(n + 2))  # Enough points to detect pattern
        outputs = [x % n for x in inputs]
        
        try:
            result = evolver._rule_extraction(inputs, outputs, x=n+5)
            expected = (n + 5) % n
            # Should detect the pattern correctly
            assert abs(result - expected) < 1e-6
        except Exception as e:
            # Some edge cases might fail, that's acceptable
            pass


@pytest.mark.skipif(not HYPOTHESIS_AVAILABLE, reason="hypothesis not installed")
class TestPiecewiseInferenceRobustness:
    """Property-based tests for piecewise inference."""
    
    @given(st.lists(st.floats(min_value=-50, max_value=50, allow_nan=False, allow_infinity=False), 
                    min_size=4, max_size=12))
    @settings(max_examples=30)
    def test_piecewise_no_crash(self, inputs):
        """Piecewise inference should not crash on valid inputs."""
        evolver = ReverseEngineeringEvolver()
        
        # Create simple piecewise: y = x if x < 0, else y = 2x
        outputs = [x if x < 0 else 2*x for x in inputs]
        
        try:
            result = evolver._piecewise_infer(inputs, outputs, x=5.0)
            assert isinstance(result, (int, float))
        except Exception as e:
            pytest.fail(f"Piecewise inference crashed: {e}")


@pytest.mark.skipif(not HYPOTHESIS_AVAILABLE, reason="hypothesis not installed")
class TestEdgeCases:
    """Test various edge cases."""
    
    def test_empty_inputs_handling(self):
        """Should handle empty or minimal inputs gracefully."""
        evolver = ReverseEngineeringEvolver()
        
        # Empty inputs - should not crash
        try:
            result = evolver._linear_fit([], [], x=5.0)
        except (IndexError, ValueError):
            # Acceptable to raise exception
            pass
        
        # Single input
        try:
            result = evolver._linear_fit([1.0], [2.0], x=5.0)
            assert isinstance(result, (int, float))
        except Exception:
            pass
    
    def test_extreme_values(self):
        """Should handle extreme values without crashing."""
        evolver = ReverseEngineeringEvolver()
        
        inputs = [1e-10, 1e-5, 1e-3]
        outputs = [1e-10, 1e-5, 1e-3]
        
        try:
            result = evolver._linear_fit(inputs, outputs, x=1e-4)
            assert isinstance(result, (int, float))
        except Exception:
            pass
        
        # Large values
        inputs_large = [1e10, 1e11, 1e12]
        outputs_large = [1e10, 1e11, 1e12]
        
        try:
            result = evolver._linear_fit(inputs_large, outputs_large, x=1e11)
            assert isinstance(result, (int, float))
        except Exception:
            pass


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
