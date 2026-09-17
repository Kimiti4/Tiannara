"""
Confidence Calibration Test Script

Demonstrates uncertainty quantification capabilities including:
- Bootstrap confidence intervals
- Bayesian posterior estimation
- Analytical approximations
- Uncertainty propagation through causal chains
- Reliability diagram assessment

Usage:
    python tiannara_core/interpretability/test_confidence_calibration.py
"""

import sys
from pathlib import Path
import numpy as np

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

try:
    from tiannara_core.interpretability.confidence_calibration import (
        ConfidenceCalibration,
        CalibrationResult,
        calibrate_causal_claim
    )
    CALIBRATION_AVAILABLE = True
except ImportError as e:
    print(f"WARNING: Confidence calibration module not available: {e}")
    CALIBRATION_AVAILABLE = False


def test_bootstrap_calibration():
    """Test bootstrap-based confidence interval estimation."""
    print("\n" + "=" * 80)
    print("TEST 1: Bootstrap Calibration")
    print("=" * 80)
    
    calibrator = ConfidenceCalibration(n_bootstrap=500)
    
    # Simulate observed causal effect
    observed_effect = 0.65
    sample_size = 200
    
    result = calibrator.calibrate_effect(
        observed_effect=observed_effect,
        sample_size=sample_size,
        method='bootstrap'
    )
    
    print(f"\nObserved effect: {observed_effect}")
    print(f"Sample size: {sample_size}")
    print(f"\n{result.summary()}")
    print(f"Significant (vs 0): {result.is_significant(0)}")
    print(f"Relative uncertainty: {result.relative_uncertainty()*100:.1f}%")
    print(f"\nUncertainty notes:")
    for note in result.uncertainty_notes:
        print(f"  - {note}")
    
    assert result.point_estimate == observed_effect
    assert result.confidence_interval[0] < result.point_estimate < result.confidence_interval[1]
    assert result.method == 'bootstrap'
    assert result.sample_size == sample_size
    
    print("\n[PASS] Bootstrap calibration working correctly")
    return True


def test_bayesian_calibration():
    """Test Bayesian posterior estimation."""
    print("\n" + "=" * 80)
    print("TEST 2: Bayesian Calibration")
    print("=" * 80)
    
    calibrator = ConfidenceCalibration()
    
    # Small sample size - prior should have strong influence
    observed_effect = 0.8
    sample_size = 10
    
    result = calibrator.calibrate_effect(
        observed_effect=observed_effect,
        sample_size=sample_size,
        method='bayesian',
        prior_mean=0.0,
        prior_std=0.5
    )
    
    print(f"\nObserved effect: {observed_effect}")
    print(f"Sample size: {sample_size} (small)")
    print(f"Prior: N(0.0, 0.5)")
    print(f"\n{result.summary()}")
    print(f"\nPosterior mean shrinks toward prior due to small sample")
    print(f"Shrinkage amount: {abs(observed_effect - result.point_estimate):.3f}")
    
    # With small sample, posterior should be between prior and observation
    assert 0.0 < result.point_estimate < observed_effect
    assert result.method == 'bayesian'
    
    print("\n[PASS] Bayesian calibration working correctly")
    return True


def test_analytical_calibration():
    """Test analytical confidence interval calculation."""
    print("\n" + "=" * 80)
    print("TEST 3: Analytical Calibration")
    print("=" * 80)
    
    calibrator = ConfidenceCalibration()
    
    observed_effect = 0.45
    sample_size = 500
    
    result = calibrator.calibrate_effect(
        observed_effect=observed_effect,
        sample_size=sample_size,
        method='analytical'
    )
    
    print(f"\nObserved effect: {observed_effect}")
    print(f"Sample size: {sample_size}")
    print(f"\n{result.summary()}")
    print(f"Standard error: {result.standard_error:.4f}")
    
    # Larger sample should give narrower CI
    assert result.standard_error < 0.1  # Should be small with n=500
    assert result.method == 'analytical'
    
    print("\n[PASS] Analytical calibration working correctly")
    return True


def test_path_uncertainty_propagation():
    """Test uncertainty propagation through causal chain."""
    print("\n" + "=" * 80)
    print("TEST 4: Uncertainty Propagation Through Causal Chain")
    print("=" * 80)
    
    calibrator = ConfidenceCalibration()
    
    # Define causal path: A -> B -> C -> D
    path_effects = [
        ('skill_memory', 'pattern_recognition', 0.7),
        ('pattern_recognition', 'solution_quality', 0.6),
        ('solution_quality', 'final_outcome', 0.8)
    ]
    
    sample_sizes = [200, 200, 200]
    
    # Calibrate each edge
    calibrated_edges = calibrator.calibrate_path(
        path_effects=path_effects,
        sample_sizes=sample_sizes,
        method='bootstrap'
    )
    
    print("\nCausal Path: skill_memory -> pattern_recognition -> solution_quality -> final_outcome")
    print("\nEdge Calibrations:")
    for edge_key, cal in calibrated_edges.items():
        print(f"  {edge_key}: {cal.summary()}")
    
    # Propagate uncertainty through entire path
    total_effect_cal = calibrator.propagate_uncertainty(calibrated_edges)
    
    print(f"\nTotal Path Effect:")
    print(f"  {total_effect_cal.summary()}")
    print(f"  Expected (product): {0.7 * 0.6 * 0.8:.3f}")
    print(f"  Actual estimate: {total_effect_cal.point_estimate:.3f}")
    
    # Total effect should be approximately product of individual effects
    expected_total = 0.7 * 0.6 * 0.8
    assert abs(total_effect_cal.point_estimate - expected_total) < 0.01
    
    print("\n[PASS] Uncertainty propagation working correctly")
    return True


def test_reliability_diagram():
    """Test calibration quality assessment."""
    print("\n" + "=" * 80)
    print("TEST 5: Reliability Diagram Assessment")
    print("=" * 80)
    
    calibrator = ConfidenceCalibration()
    
    # Generate well-calibrated predictions
    np.random.seed(42)
    n_samples = 1000
    
    # Perfectly calibrated: predicted probability matches actual frequency
    predictions = np.random.uniform(0, 1, n_samples)
    outcomes = np.random.binomial(1, predictions)
    
    diagram = calibrator.assess_calibration(predictions.tolist(), outcomes.tolist())
    
    print(f"\nNumber of samples: {n_samples}")
    print(f"Expected Calibration Error (ECE): {diagram.expected_calibration_error:.4f}")
    print(f"Maximum Calibration Error (MCE): {diagram.maximum_calibration_error:.4f}")
    print(f"Well calibrated (tolerance=0.1): {diagram.is_well_calibrated(0.1)}")
    
    # Well-calibrated predictions should have low ECE
    assert diagram.expected_calibration_error < 0.1
    
    print("\nReliability Diagram (binned):")
    for i, (bin_center, obs_freq, count) in enumerate(zip(
        diagram.bins, diagram.observed_frequencies, diagram.counts
    )):
        if count > 0:
            print(f"  Bin {i+1} ({bin_center:.2f}): observed={obs_freq:.2f}, n={count}")
    
    print("\n[PASS] Reliability diagram working correctly")
    return True


def test_convenience_function():
    """Test convenience function for quick calibration."""
    print("\n" + "=" * 80)
    print("TEST 6: Convenience Function")
    print("=" * 80)
    
    result = calibrate_causal_claim(
        effect=0.55,
        sample_size=300,
        confidence_level=0.95,
        method='analytical'
    )
    
    print(f"\nQuick calibration of causal claim:")
    print(f"  {result.summary()}")
    print(f"  Significant: {result.is_significant()}")
    
    assert result.point_estimate == 0.55
    assert result.confidence_level == 0.95
    
    print("\n[PASS] Convenience function working correctly")
    return True


def test_calibration_report():
    """Test comprehensive calibration report generation."""
    print("\n" + "=" * 80)
    print("TEST 7: Calibration Report")
    print("=" * 80)
    
    calibrator = ConfidenceCalibration()
    
    # Perform multiple calibrations
    for i, (effect, n) in enumerate([(0.3, 100), (0.5, 200), (0.7, 300)]):
        calibrator.calibrate_effect(effect, n, method='bootstrap')
    
    report = calibrator.get_calibration_report()
    
    print(f"\nCalibration Report:")
    print(f"  Total calibrations: {report['total_calibrations']}")
    print(f"  Methods used: {report['methods_used']}")
    print(f"  Average relative uncertainty: {report['average_relative_uncertainty']*100:.1f}%")
    print(f"  Significant effects: {report['significant_effects']}/{report['total_effects']}")
    print(f"  Significance rate: {report['significance_rate']*100:.1f}%")
    
    assert report['total_calibrations'] == 3
    assert 'bootstrap' in report['methods_used']
    
    print("\n[PASS] Calibration report working correctly")
    return True


def main():
    """Run all tests."""
    print("\n" + "=" * 80)
    print("CONFIDENCE CALIBRATION TEST SUITE")
    print("=" * 80)
    
    if not CALIBRATION_AVAILABLE:
        print("\nCannot run tests - Confidence calibration module not available")
        print("Install required dependencies: pip install scipy numpy")
        return False
    
    tests = [
        ("Bootstrap Calibration", test_bootstrap_calibration),
        ("Bayesian Calibration", test_bayesian_calibration),
        ("Analytical Calibration", test_analytical_calibration),
        ("Uncertainty Propagation", test_path_uncertainty_propagation),
        ("Reliability Diagram", test_reliability_diagram),
        ("Convenience Function", test_convenience_function),
        ("Calibration Report", test_calibration_report),
    ]
    
    passed = 0
    failed = 0
    
    for name, test_func in tests:
        try:
            if test_func():
                passed += 1
        except Exception as e:
            print(f"\nERROR: Test failed with error: {e}")
            import traceback
            traceback.print_exc()
            failed += 1
    
    print("\n" + "=" * 80)
    print(f"RESULTS: {passed} passed, {failed} failed out of {len(tests)} tests")
    print("=" * 80)
    
    if failed == 0:
        print("\nALL TESTS PASSED!")
        return True
    else:
        print(f"\n{failed} test(s) failed")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
