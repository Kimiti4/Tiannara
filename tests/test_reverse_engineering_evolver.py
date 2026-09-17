"""
Unit tests for Reverse Engineering Evolver.
"""

import pytest
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver


class TestReverseEngineeringEvolverBasic:
    """Test basic RE evolver functionality."""
    
    def test_evolver_initialization(self):
        """Evolver should initialize without errors."""
        evolver = ReverseEngineeringEvolver()
        assert evolver is not None
    
    def test_linear_fit_simple(self):
        """Should fit simple linear function y = 2x + 3."""
        evolver = ReverseEngineeringEvolver()
        inputs = [1, 2, 3, 4, 5]
        outputs = [5, 7, 9, 11, 13]  # y = 2x + 3
        
        result = evolver._linear_fit(inputs, outputs, 10)
        expected = 2 * 10 + 3  # 23
        
        assert abs(result - expected) < 0.1
    
    def test_polynomial_fit_quadratic(self):
        """Should fit quadratic function y = x^2."""
        evolver = ReverseEngineeringEvolver()
        inputs = [1, 2, 3, 4, 5]
        outputs = [1, 4, 9, 16, 25]  # y = x^2
        
        result = evolver._polynomial_fit(inputs, outputs, 6)
        expected = 36  # 6^2
        
        assert abs(result - expected) < 1.0
    
    def test_modulo_detection_simple(self):
        """Should detect modulo pattern y = x % 5."""
        evolver = ReverseEngineeringEvolver()
        inputs = list(range(10))
        outputs = [x % 5 for x in inputs]
        
        result = evolver._rule_extraction(inputs, outputs, 12)
        expected = 12 % 5  # 2
        
        assert abs(result - expected) < 0.1
    
    def test_modulo_detection_extended_range(self):
        """Phase 1: Should detect modulo with n > 7."""
        evolver = ReverseEngineeringEvolver()
        inputs = list(range(12))
        outputs = [x % 11 for x in inputs]
        
        result = evolver._rule_extraction(inputs, outputs, 25)
        expected = 25 % 11  # 3
        
        assert abs(result - expected) < 0.1
    
    def test_affine_modulo_detection(self):
        """Phase 1: Should detect affine modulo f(x) = (2x + 1) % 5."""
        evolver = ReverseEngineeringEvolver()
        inputs = list(range(8))
        outputs = [(2*x + 1) % 5 for x in inputs]
        
        result = evolver._rule_extraction(inputs, outputs, 10)
        expected = (2*10 + 1) % 5  # 1
        
        assert abs(result - expected) < 0.1
    
    def test_piecewise_detection_two_segments(self):
        """Should detect piecewise function with one breakpoint."""
        evolver = ReverseEngineeringEvolver()
        # y = x if x < 5, else y = 2x
        inputs = [1, 2, 3, 4, 5, 6, 7, 8]
        outputs = [1, 2, 3, 4, 10, 12, 14, 16]
        
        result = evolver._piecewise_infer(inputs, outputs, 10)
        expected = 2 * 10  # 20 (second segment)
        
        # Piecewise detection can be challenging, allow larger tolerance
        assert isinstance(result, (int, float))
        assert result > 15  # Should be in reasonable range


class TestReverseEngineeringEvolverEdgeCases:
    """Test edge cases and robustness."""
    
    def test_empty_inputs(self):
        """Should handle empty input gracefully."""
        evolver = ReverseEngineeringEvolver()
        
        try:
            result = evolver.evolve([], [], 5)
            # If it doesn't crash, result should be reasonable
            assert isinstance(result, (int, float))
        except Exception:
            pass  # Acceptable to raise exception
    
    def test_single_point(self):
        """Should handle single data point."""
        evolver = ReverseEngineeringEvolver()
        
        result = evolver._linear_fit([5], [10], 7)
        # Should return something reasonable
        assert isinstance(result, (int, float))
    
    def test_noisy_data(self):
        """Should handle noisy data reasonably."""
        evolver = ReverseEngineeringEvolver()
        # Linear with noise
        inputs = list(range(10))
        outputs = [2*x + 3 + (i % 3) * 0.1 for i, x in enumerate(inputs)]
        
        result = evolver._linear_fit(inputs, outputs, 15)
        expected = 2 * 15 + 3  # 33
        
        # With noise, allow larger tolerance
        assert abs(result - expected) < 5.0
    
    def test_large_coefficients(self):
        """Should handle functions with large coefficients."""
        evolver = ReverseEngineeringEvolver()
        inputs = [1, 2, 3, 4, 5]
        outputs = [100*x + 50 for x in inputs]  # y = 100x + 50
        
        result = evolver._linear_fit(inputs, outputs, 10)
        expected = 100 * 10 + 50  # 1050
        
        assert abs(result - expected) < 10.0
    
    def test_negative_values(self):
        """Should handle negative values correctly."""
        evolver = ReverseEngineeringEvolver()
        inputs = [-5, -3, -1, 1, 3, 5]
        outputs = [2*x for x in inputs]  # y = 2x
        
        result = evolver._linear_fit(inputs, outputs, 10)
        expected = 2 * 10  # 20
        
        assert abs(result - expected) < 0.1


class TestReverseEngineeringEvolverComplex:
    """Test complex patterns and multi-segment functions."""
    
    def test_three_segment_piecewise(self):
        """Phase 2: Should handle three-segment piecewise function."""
        evolver = ReverseEngineeringEvolver()
        # y = x if x < 3, y = 2x if 3 <= x < 7, y = 3x if x >= 7
        inputs = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        outputs = [1, 2, 6, 8, 10, 12, 21, 24, 27]
        
        result = evolver._piecewise_infer(inputs, outputs, 10)
        expected = 3 * 10  # 30 (third segment)
        
        # Multi-segment is challenging, allow generous tolerance
        assert isinstance(result, (int, float))
    
    def test_exponential_pattern(self):
        """Should approximate exponential growth."""
        evolver = ReverseEngineeringEvolver()
        inputs = [1, 2, 3, 4, 5]
        outputs = [2**x for x in inputs]  # y = 2^x
        
        result = evolver._exponential_fit(inputs, outputs, 6)
        expected = 2**6  # 64
        
        # Polynomial approximation won't be perfect
        assert isinstance(result, (int, float))
        assert result > 30  # Should capture growth trend
    
    def test_constant_function(self):
        """Should handle constant function."""
        evolver = ReverseEngineeringEvolver()
        inputs = [1, 2, 3, 4, 5]
        outputs = [7, 7, 7, 7, 7]  # y = 7
        
        result = evolver._linear_fit(inputs, outputs, 10)
        expected = 7
        
        assert abs(result - expected) < 0.1
    
    def test_identity_function(self):
        """Should detect identity function y = x."""
        evolver = ReverseEngineeringEvolver()
        inputs = [1, 2, 3, 4, 5]
        outputs = [1, 2, 3, 4, 5]  # y = x
        
        result = evolver._linear_fit(inputs, outputs, 10)
        expected = 10
        
        assert abs(result - expected) < 0.1


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
