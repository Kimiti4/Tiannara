"""
Confidence Calibration for Explainable ECM

Quantifies uncertainty in causal claims using multiple calibration methods.
Provides confidence intervals, reliability diagrams, and uncertainty-aware explanations.

Key Features:
- Bootstrap-based confidence intervals for causal effects
- Bayesian posterior estimation with prior knowledge
- Reliability diagram construction for calibration assessment
- Uncertainty propagation through causal chains
- Integration with CausalPathTracer and CounterfactualEngine

Usage:
    from tiannara_core.interpretability.confidence_calibration import ConfidenceCalibration
    
    calibrator = ConfidenceCalibration()
    
    # Calibrate a causal effect estimate
    result = calibrator.calibrate_effect(
        observed_effect=0.65,
        sample_size=1000,
        method='bootstrap'
    )
    
    # Get confidence interval
    ci = result.confidence_interval  # (0.58, 0.72)
    
    # Assess calibration quality
    quality = calibrator.assess_calibration(result)

References:
    Murphy, K.P. (2012). Machine Learning: A Probabilistic Perspective.
    Efron, B., & Tibshirani, R.J. (1994). An Introduction to the Bootstrap.
    Guo, C., et al. (2017). On Calibration of Modern Neural Networks.
"""

import logging
import numpy as np
from dataclasses import dataclass, field
from typing import List, Dict, Tuple, Optional, Any
from datetime import datetime

logger = logging.getLogger(__name__)

# Check for scipy availability
try:
    from scipy.stats import norm
    SCIPY_AVAILABLE = True
except ImportError:
    SCIPY_AVAILABLE = False
    logger.warning("scipy not available. Using normal approximation fallback.")


def _get_z_score(confidence_level: float) -> float:
    """
    Get z-score for given confidence level.
    Uses scipy if available, otherwise uses approximation.
    """
    if SCIPY_AVAILABLE:
        return norm.ppf((1 + confidence_level) / 2)
    else:
        # Approximation for common confidence levels
        # For 95% CI: z ≈ 1.96, for 90% CI: z ≈ 1.645, for 99% CI: z ≈ 2.576
        approximations = {
            0.90: 1.645,
            0.95: 1.96,
            0.99: 2.576
        }
        # Use closest approximation or default to 1.96
        return approximations.get(confidence_level, 1.96)


@dataclass
class CalibrationResult:
    """Result of confidence calibration."""
    point_estimate: float
    confidence_interval: Tuple[float, float]
    confidence_level: float  # e.g., 0.95 for 95% CI
    standard_error: float
    sample_size: int
    method: str  # 'bootstrap', 'bayesian', 'analytical'
    calibration_quality: Optional[float] = None  # How well-calibrated (0-1)
    uncertainty_notes: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def is_significant(self, threshold: float = 0.0) -> bool:
        """Check if effect is significantly different from threshold."""
        return self.confidence_interval[0] > threshold or self.confidence_interval[1] < threshold
    
    def relative_uncertainty(self) -> float:
        """Calculate relative uncertainty (CI width / point estimate)."""
        if abs(self.point_estimate) < 1e-10:
            return float('inf')
        ci_width = self.confidence_interval[1] - self.confidence_interval[0]
        return ci_width / abs(self.point_estimate)
    
    def summary(self) -> str:
        """Generate human-readable summary."""
        ci_lower, ci_upper = self.confidence_interval
        return (
            f"Effect: {self.point_estimate:.3f} "
            f"[{ci_lower:.3f}, {ci_upper:.3f}] "
            f"(SE={self.standard_error:.3f}, n={self.sample_size})"
        )


@dataclass
class ReliabilityDiagram:
    """Calibration curve showing predicted vs actual confidence."""
    bins: List[float]  # Predicted confidence bins
    observed_frequencies: List[float]  # Actual frequencies in each bin
    counts: List[int]  # Number of samples in each bin
    expected_calibration_error: float  # ECE score
    maximum_calibration_error: float  # MCE score
    
    def is_well_calibrated(self, tolerance: float = 0.1) -> bool:
        """Check if predictions are well-calibrated."""
        return self.expected_calibration_error < tolerance


class ConfidenceCalibration:
    """
    Quantifies uncertainty in causal claims using statistical methods.
    
    Provides multiple calibration approaches:
    - Bootstrap resampling for empirical confidence intervals
    - Bayesian inference with prior distributions
    - Analytical approximations for simple cases
    - Reliability diagrams for calibration assessment
    """
    
    def __init__(self, default_confidence: float = 0.95, n_bootstrap: int = 1000):
        """
        Initialize confidence calibrator.
        
        Args:
            default_confidence: Default confidence level for intervals (default: 0.95)
            n_bootstrap: Number of bootstrap samples (default: 1000)
        """
        self.default_confidence = default_confidence
        self.n_bootstrap = n_bootstrap
        self.calibration_history: List[CalibrationResult] = []
        
        logger.info(f"ConfidenceCalibration initialized (confidence={default_confidence}, "
                   f"bootstrap_samples={n_bootstrap})")
    
    def calibrate_effect(
        self,
        observed_effect: float,
        sample_size: int,
        method: str = 'bootstrap',
        effect_samples: Optional[List[float]] = None,
        prior_mean: float = 0.0,
        prior_std: float = 1.0,
        **kwargs
    ) -> CalibrationResult:
        """
        Calibrate a causal effect estimate.
        
        Args:
            observed_effect: Point estimate of causal effect
            sample_size: Number of observations
            method: Calibration method ('bootstrap', 'bayesian', 'analytical')
            effect_samples: Individual effect samples (for bootstrap)
            prior_mean: Prior mean for Bayesian method
            prior_std: Prior std for Bayesian method
            
        Returns:
            CalibrationResult with confidence interval and uncertainty metrics
        """
        if method == 'bootstrap':
            return self._bootstrap_calibration(
                observed_effect, sample_size, effect_samples
            )
        elif method == 'bayesian':
            return self._bayesian_calibration(
                observed_effect, sample_size, prior_mean, prior_std
            )
        elif method == 'analytical':
            return self._analytical_calibration(
                observed_effect, sample_size
            )
        else:
            raise ValueError(f"Unknown calibration method: {method}")
    
    def _bootstrap_calibration(
        self,
        observed_effect: float,
        sample_size: int,
        effect_samples: Optional[List[float]] = None
    ) -> CalibrationResult:
        """Bootstrap-based confidence interval estimation."""
        
        # Generate bootstrap samples if not provided
        if effect_samples is None:
            # Assume normal distribution around observed effect
            estimated_std = max(abs(observed_effect) * 0.2, 0.1)  # Reasonable default
            effect_samples = np.random.normal(observed_effect, estimated_std, sample_size)
        else:
            effect_samples = np.array(effect_samples)
            sample_size = len(effect_samples)
        
        # Perform bootstrap resampling
        bootstrap_means = []
        for _ in range(self.n_bootstrap):
            resample = np.random.choice(effect_samples, size=sample_size, replace=True)
            bootstrap_means.append(np.mean(resample))
        
        bootstrap_means = np.array(bootstrap_means)
        
        # Calculate confidence interval
        alpha = 1 - self.default_confidence
        lower_percentile = (alpha / 2) * 100
        upper_percentile = (1 - alpha / 2) * 100
        
        ci_lower = np.percentile(bootstrap_means, lower_percentile)
        ci_upper = np.percentile(bootstrap_means, upper_percentile)
        
        # Calculate standard error
        standard_error = np.std(bootstrap_means, ddof=1)
        
        result = CalibrationResult(
            point_estimate=observed_effect,
            confidence_interval=(float(ci_lower), float(ci_upper)),
            confidence_level=self.default_confidence,
            standard_error=float(standard_error),
            sample_size=sample_size,
            method='bootstrap',
            uncertainty_notes=[
                f"Bootstrap CI based on {self.n_bootstrap} resamples",
                f"Relative uncertainty: {(ci_upper - ci_lower) / abs(observed_effect) * 100:.1f}%"
                if abs(observed_effect) > 1e-10 else "N/A (effect near zero)"
            ]
        )
        
        self.calibration_history.append(result)
        logger.debug(f"Bootstrap calibration: {result.summary()}")
        
        return result
    
    def _bayesian_calibration(
        self,
        observed_effect: float,
        sample_size: int,
        prior_mean: float = 0.0,
        prior_std: float = 1.0
    ) -> CalibrationResult:
        """Bayesian posterior estimation with conjugate priors."""
        
        # Assume normal likelihood with known variance
        # Use weakly informative prior by default
        likelihood_variance = 1.0 / sample_size  # Simplified assumption
        
        # Posterior parameters (conjugate normal-normal model)
        prior_precision = 1.0 / (prior_std ** 2)
        likelihood_precision = 1.0 / likelihood_variance
        
        posterior_precision = prior_precision + likelihood_precision
        posterior_mean = (
            (prior_precision * prior_mean + likelihood_precision * observed_effect) /
            posterior_precision
        )
        posterior_std = np.sqrt(1.0 / posterior_precision)
        
        # Calculate credible interval
        z_score = _get_z_score(self.default_confidence)
        
        ci_lower = posterior_mean - z_score * posterior_std
        ci_upper = posterior_mean + z_score * posterior_std
        
        result = CalibrationResult(
            point_estimate=float(posterior_mean),
            confidence_interval=(float(ci_lower), float(ci_upper)),
            confidence_level=self.default_confidence,
            standard_error=float(posterior_std),
            sample_size=sample_size,
            method='bayesian',
            metadata={
                'prior_mean': prior_mean,
                'prior_std': prior_std,
                'posterior_precision': float(posterior_precision)
            },
            uncertainty_notes=[
                f"Bayesian posterior with N({prior_mean:.2f}, {prior_std:.2f}) prior",
                f"Posterior shrinks toward prior when sample size is small"
            ]
        )
        
        self.calibration_history.append(result)
        logger.debug(f"Bayesian calibration: {result.summary()}")
        
        return result
    
    def _analytical_calibration(
        self,
        observed_effect: float,
        sample_size: int
    ) -> CalibrationResult:
        """Analytical confidence interval using normal approximation."""
        
        # Estimate standard error (simplified - assumes effect is correlation-like)
        # For correlations: SE ≈ sqrt((1-r²)/(n-2))
        estimated_se = np.sqrt((1 - observed_effect**2) / max(sample_size - 2, 1))
        
        # Calculate confidence interval
        z_score = _get_z_score(self.default_confidence)
        
        ci_lower = observed_effect - z_score * estimated_se
        ci_upper = observed_effect + z_score * estimated_se
        
        result = CalibrationResult(
            point_estimate=observed_effect,
            confidence_interval=(float(ci_lower), float(ci_upper)),
            confidence_level=self.default_confidence,
            standard_error=float(estimated_se),
            sample_size=sample_size,
            method='analytical',
            uncertainty_notes=[
                f"Normal approximation CI (z={z_score:.2f})",
                f"Assumes approximately normal sampling distribution"
            ]
        )
        
        self.calibration_history.append(result)
        logger.debug(f"Analytical calibration: {result.summary()}")
        
        return result
    
    def calibrate_path(
        self,
        path_effects: List[Tuple[str, str, float]],
        sample_sizes: List[int],
        method: str = 'bootstrap'
    ) -> Dict[str, CalibrationResult]:
        """
        Calibrate all edges in a causal path.
        
        Args:
            path_effects: List of (source, target, effect_size) tuples
            sample_sizes: Sample sizes for each edge
            
        Returns:
            Dictionary mapping edge keys to calibration results
        """
        calibrated_edges = {}
        
        for (source, target, effect), n in zip(path_effects, sample_sizes):
            edge_key = f"{source}→{target}"
            result = self.calibrate_effect(
                observed_effect=effect,
                sample_size=n,
                method=method
            )
            calibrated_edges[edge_key] = result
        
        return calibrated_edges
    
    def propagate_uncertainty(
        self,
        path_calibrations: Dict[str, CalibrationResult]
    ) -> CalibrationResult:
        """
        Propagate uncertainty through a causal chain.
        
        Uses delta method for variance propagation:
        Var(f(X,Y)) ≈ (∂f/∂X)² Var(X) + (∂f/∂Y)² Var(Y)
        
        For product of effects: Var(X*Y) ≈ Y² Var(X) + X² Var(Y)
        
        Args:
            path_calibrations: Calibrated effects for each edge in path
            
        Returns:
            Combined calibration for entire path
        """
        if not path_calibrations:
            raise ValueError("No calibrations provided")
        
        # Extract effects and variances
        effects = []
        variances = []
        
        for edge_key, cal in path_calibrations.items():
            effects.append(cal.point_estimate)
            variances.append(cal.standard_error ** 2)
        
        # Calculate total effect (product for serial mediation)
        total_effect = np.prod(effects)
        
        # Propagate variance using delta method
        total_variance = 0.0
        for i, (effect, variance) in enumerate(zip(effects, variances)):
            # Partial derivative of product w.r.t. effect_i
            partial_deriv = total_effect / effect if abs(effect) > 1e-10 else 0
            total_variance += (partial_deriv ** 2) * variance
        
        total_se = np.sqrt(total_variance)
        
        # Calculate confidence interval
        z_score = _get_z_score(self.default_confidence)
        
        ci_lower = total_effect - z_score * total_se
        ci_upper = total_effect + z_score * total_se
        
        result = CalibrationResult(
            point_estimate=float(total_effect),
            confidence_interval=(float(ci_lower), float(ci_upper)),
            confidence_level=self.default_confidence,
            standard_error=float(total_se),
            sample_size=min(cal.sample_size for cal in path_calibrations.values()),
            method='propagation',
            metadata={
                'num_edges': len(path_calibrations),
                'individual_effects': effects,
                'individual_variances': variances
            },
            uncertainty_notes=[
                f"Uncertainty propagated through {len(path_calibrations)} edges",
                f"Total effect is product of individual effects",
                f"Weakest link contributes most to uncertainty"
            ]
        )
        
        self.calibration_history.append(result)
        logger.debug(f"Propagated uncertainty: {result.summary()}")
        
        return result
    
    def assess_calibration(
        self,
        predictions: List[float],
        outcomes: List[bool],
        n_bins: int = 10
    ) -> ReliabilityDiagram:
        """
        Assess calibration quality using reliability diagram.
        
        Args:
            predictions: Predicted probabilities/confidences
            outcomes: Binary outcomes (True/False)
            n_bins: Number of bins for reliability diagram
            
        Returns:
            ReliabilityDiagram with calibration metrics
        """
        predictions = np.array(predictions)
        outcomes = np.array(outcomes, dtype=float)
        
        # Create bins
        bin_edges = np.linspace(0, 1, n_bins + 1)
        bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
        
        observed_freqs = []
        counts = []
        
        for i in range(n_bins):
            mask = (predictions >= bin_edges[i]) & (predictions < bin_edges[i+1])
            if i == n_bins - 1:  # Include right edge for last bin
                mask = (predictions >= bin_edges[i]) & (predictions <= bin_edges[i+1])
            
            if np.sum(mask) > 0:
                observed_freq = np.mean(outcomes[mask])
                count = np.sum(mask)
            else:
                observed_freq = 0.0
                count = 0
            
            observed_freqs.append(float(observed_freq))
            counts.append(int(count))
        
        # Calculate Expected Calibration Error (ECE)
        ece = 0.0
        mce = 0.0
        total_samples = len(predictions)
        
        for i in range(n_bins):
            if counts[i] > 0:
                gap = abs(bin_centers[i] - observed_freqs[i])
                ece += (counts[i] / total_samples) * gap
                mce = max(mce, gap)
        
        diagram = ReliabilityDiagram(
            bins=bin_centers.tolist(),
            observed_frequencies=observed_freqs,
            counts=counts,
            expected_calibration_error=float(ece),
            maximum_calibration_error=float(mce)
        )
        
        logger.info(f"Calibration assessment: ECE={ece:.3f}, MCE={mce:.3f}")
        
        return diagram
    
    def get_calibration_report(self) -> Dict[str, Any]:
        """Generate comprehensive calibration report."""
        if not self.calibration_history:
            return {"status": "no_calibrations_performed"}
        
        # Aggregate statistics
        methods_used = set(r.method for r in self.calibration_history)
        avg_relative_uncertainty = np.mean([
            r.relative_uncertainty() for r in self.calibration_history
            if not np.isinf(r.relative_uncertainty())
        ])
        
        significant_effects = sum(
            1 for r in self.calibration_history if r.is_significant()
        )
        
        return {
            "total_calibrations": len(self.calibration_history),
            "methods_used": list(methods_used),
            "average_relative_uncertainty": float(avg_relative_uncertainty),
            "significant_effects": significant_effects,
            "total_effects": len(self.calibration_history),
            "significance_rate": significant_effects / len(self.calibration_history),
            "recent_calibrations": [
                {
                    "method": r.method,
                    "estimate": r.point_estimate,
                    "ci": r.confidence_interval,
                    "se": r.standard_error
                }
                for r in self.calibration_history[-5:]
            ]
        }


def calibrate_causal_claim(
    effect: float,
    sample_size: int,
    confidence_level: float = 0.95,
    method: str = 'bootstrap'
) -> CalibrationResult:
    """
    Convenience function for quick causal claim calibration.
    
    Args:
        effect: Observed causal effect size
        sample_size: Number of observations
        confidence_level: Desired confidence level (default: 0.95)
        method: Calibration method
        
    Returns:
        CalibrationResult with confidence interval
    """
    calibrator = ConfidenceCalibration(default_confidence=confidence_level)
    return calibrator.calibrate_effect(
        observed_effect=effect,
        sample_size=sample_size,
        method=method
    )
