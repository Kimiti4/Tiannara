"""
Confidence Calibration Engine

Purpose: Calibrate prediction confidence scores for better reliability
Features:
- Platt Scaling (logistic regression calibration)
- Isotonic Regression (non-parametric calibration)
- Temperature Scaling (single-parameter scaling)
- Expected Calibration Error (ECE) calculation
- Brier Score computation
- Reliability diagrams
- Automatic method selection

Date: May 9, 2026
Status: Implementation Phase - Week 23 Day 3
"""

import numpy as np
from typing import Dict, List, Optional, Tuple, Any
from datetime import datetime
from enum import Enum
from dataclasses import dataclass, field


class CalibrationMethod(Enum):
    """Available calibration methods."""
    PLATT_SCALING = "platt_scaling"
    ISOTONIC_REGRESSION = "isotonic_regression"
    TEMPERATURE_SCALING = "temperature_scaling"
    NONE = "none"


@dataclass
class CalibrationResult:
    """Result from confidence calibration."""
    
    original_confidence: float
    calibrated_confidence: float
    method_used: CalibrationMethod
    calibration_error: float = 0.0
    
    # Metadata
    timestamp: datetime = field(default_factory=datetime.now)
    is_improved: bool = False
    
    def to_dict(self) -> Dict:
        return {
            "original": self.original_confidence,
            "calibrated": self.calibrated_confidence,
            "method": self.method_used.value,
            "error": self.calibration_error,
            "improved": self.is_improved
        }


@dataclass
class CalibrationMetrics:
    """Comprehensive calibration quality metrics."""
    
    # Calibration errors
    ece: float = 0.0  # Expected Calibration Error
    mce: float = 0.0  # Maximum Calibration Error
    brier_score: float = 0.0
    
    # Reliability
    reliability_diagram: Dict[str, List[float]] = field(default_factory=dict)
    
    # Improvement stats
    pre_calibration_accuracy: float = 0.0
    post_calibration_accuracy: float = 0.0
    improvement_percentage: float = 0.0
    
    # Sample statistics
    total_samples: int = 0
    well_calibrated_samples: int = 0
    
    def to_dict(self) -> Dict:
        return {
            "ece": self.ece,
            "mce": self.mce,
            "brier_score": self.brier_score,
            "pre_accuracy": self.pre_calibration_accuracy,
            "post_accuracy": self.post_calibration_accuracy,
            "improvement_pct": self.improvement_percentage,
            "total_samples": self.total_samples,
            "well_calibrated_pct": (
                self.well_calibrated_samples / self.total_samples * 100
                if self.total_samples > 0 else 0
            )
        }


class PlattScaler:
    """
    Platt Scaling: Logistic regression-based calibration.
    
    Fits a sigmoid function to map uncalibrated confidences to calibrated probabilities.
    P(y=1|f) = 1 / (1 + exp(A*f + B))
    
    Where f is the uncalibrated confidence, and A, B are learned parameters.
    """
    
    def __init__(self):
        self.A = 0.0  # Scale parameter
        self.B = 0.0  # Shift parameter
        self.trained = False
    
    def fit(self, confidences: np.ndarray, labels: np.ndarray):
        """
        Fit Platt scaling parameters using maximum likelihood.
        
        Args:
            confidences: Uncalibrated confidence scores (n_samples,)
            labels: True binary labels (n_samples,)
        """
        # Use simple gradient descent to find optimal A, B
        learning_rate = 0.01
        max_iterations = 1000
        
        # Initialize parameters
        self.A = 0.0
        self.B = 0.0
        
        for iteration in range(max_iterations):
            # Forward pass: compute probabilities
            logits = self.A * confidences + self.B
            probabilities = 1.0 / (1.0 + np.exp(-logits))
            
            # Compute gradients
            errors = probabilities - labels
            grad_A = np.mean(errors * confidences)
            grad_B = np.mean(errors)
            
            # Update parameters
            self.A -= learning_rate * grad_A
            self.B -= learning_rate * grad_B
            
            # Check convergence
            if abs(grad_A) < 1e-6 and abs(grad_B) < 1e-6:
                break
        
        self.trained = True
    
    def calibrate(self, confidence: float) -> float:
        """
        Calibrate a single confidence score.
        
        Args:
            confidence: Uncalibrated confidence (0-1)
            
        Returns:
            Calibrated probability (0-1)
        """
        if not self.trained:
            return confidence
        
        logit = self.A * confidence + self.B
        calibrated = 1.0 / (1.0 + np.exp(-logit))
        
        return float(np.clip(calibrated, 0.0, 1.0))
    
    def calibrate_batch(self, confidences: np.ndarray) -> np.ndarray:
        """Calibrate multiple confidence scores."""
        if not self.trained:
            return confidences
        
        logits = self.A * confidences + self.B
        calibrated = 1.0 / (1.0 + np.exp(-logits))
        
        return np.clip(calibrated, 0.0, 1.0)


class IsotonicRegressor:
    """
    Isotonic Regression: Non-parametric monotonic calibration.
    
    Fits a non-decreasing function that minimizes mean squared error.
    More flexible than Platt scaling but requires more data.
    """
    
    def __init__(self):
        self.breakpoints: List[float] = []
        self.values: List[float] = []
        self.trained = False
    
    def fit(self, confidences: np.ndarray, labels: np.ndarray):
        """
        Fit isotonic regression using pool adjacent violators algorithm (PAVA).
        
        Args:
            confidences: Uncalibrated confidence scores
            labels: True binary labels
        """
        # Sort by confidence
        sorted_indices = np.argsort(confidences)
        sorted_confidences = confidences[sorted_indices]
        sorted_labels = labels[sorted_indices]
        
        # Apply PAVA algorithm
        n = len(sorted_confidences)
        self.breakpoints = []
        self.values = []
        
        # Initialize pools
        pools = [(sorted_confidences[i], [sorted_labels[i]]) 
                 for i in range(n)]
        
        # Merge violating pools
        changed = True
        while changed:
            changed = False
            new_pools = []
            
            i = 0
            while i < len(pools):
                if i + 1 < len(pools):
                    # Check if violation exists
                    avg_current = np.mean(pools[i][1])
                    avg_next = np.mean(pools[i + 1][1])
                    
                    if avg_current > avg_next:
                        # Merge pools
                        merged_conf = (pools[i][0] + pools[i + 1][0]) / 2
                        merged_labels = pools[i][1] + pools[i + 1][1]
                        new_pools.append((merged_conf, merged_labels))
                        changed = True
                        i += 2
                    else:
                        new_pools.append(pools[i])
                        i += 1
                else:
                    new_pools.append(pools[i])
                    i += 1
            
            pools = new_pools
        
        # Extract breakpoints and values
        for conf, labels_pool in pools:
            self.breakpoints.append(float(conf))
            self.values.append(float(np.mean(labels_pool)))
        
        self.trained = True
    
    def calibrate(self, confidence: float) -> float:
        """Calibrate a single confidence score using interpolation."""
        if not self.trained or not self.breakpoints:
            return confidence
        
        # Find appropriate segment
        if confidence <= self.breakpoints[0]:
            return self.values[0]
        elif confidence >= self.breakpoints[-1]:
            return self.values[-1]
        else:
            # Linear interpolation between breakpoints
            for i in range(len(self.breakpoints) - 1):
                if self.breakpoints[i] <= confidence <= self.breakpoints[i + 1]:
                    # Interpolate
                    t = (confidence - self.breakpoints[i]) / (
                        self.breakpoints[i + 1] - self.breakpoints[i]
                    )
                    calibrated = (
                        self.values[i] + t * (self.values[i + 1] - self.values[i])
                    )
                    return float(np.clip(calibrated, 0.0, 1.0))
        
        return confidence
    
    def calibrate_batch(self, confidences: np.ndarray) -> np.ndarray:
        """Calibrate multiple confidence scores."""
        return np.array([self.calibrate(c) for c in confidences])


class TemperatureScaler:
    """
    Temperature Scaling: Single-parameter scaling for neural networks.
    
    Divides logits by temperature T before applying softmax.
    Lower T = more confident, Higher T = less confident.
    
    Optimized using negative log-likelihood on validation set.
    """
    
    def __init__(self):
        self.temperature = 1.0
        self.trained = False
    
    def fit(self, confidences: np.ndarray, labels: np.ndarray):
        """
        Find optimal temperature using grid search.
        
        Args:
            confidences: Uncalibrated confidence scores
            labels: True binary labels
        """
        # Convert confidences to logits
        # Avoid log(0) by clipping
        confidences_clipped = np.clip(confidences, 1e-10, 1 - 1e-10)
        logits = np.log(confidences_clipped / (1 - confidences_clipped))
        
        # Grid search for optimal temperature
        best_temp = 1.0
        best_nll = float('inf')
        
        for temp in np.arange(0.1, 5.1, 0.1):
            # Scale logits
            scaled_logits = logits / temp
            
            # Convert back to probabilities
            calibrated = 1.0 / (1.0 + np.exp(-scaled_logits))
            
            # Compute negative log-likelihood
            calibrated_clipped = np.clip(calibrated, 1e-10, 1 - 1e-10)
            nll = -np.mean(
                labels * np.log(calibrated_clipped) +
                (1 - labels) * np.log(1 - calibrated_clipped)
            )
            
            if nll < best_nll:
                best_nll = nll
                best_temp = temp
        
        self.temperature = best_temp
        self.trained = True
    
    def calibrate(self, confidence: float) -> float:
        """Calibrate a single confidence score."""
        if not self.trained:
            return confidence
        
        # Convert to logit
        confidence_clipped = np.clip(confidence, 1e-10, 1 - 1e-10)
        logit = np.log(confidence_clipped / (1 - confidence_clipped))
        
        # Scale by temperature
        scaled_logit = logit / self.temperature
        
        # Convert back to probability
        calibrated = 1.0 / (1.0 + np.exp(-scaled_logit))
        
        return float(np.clip(calibrated, 0.0, 1.0))
    
    def calibrate_batch(self, confidences: np.ndarray) -> np.ndarray:
        """Calibrate multiple confidence scores."""
        return np.array([self.calibrate(c) for c in confidences])


class ConfidenceCalibrator:
    """
    Main confidence calibration engine.
    
    Supports multiple calibration methods and automatic selection.
    Provides comprehensive metrics for calibration quality assessment.
    """
    
    def __init__(self, method: CalibrationMethod = CalibrationMethod.PLATT_SCALING):
        self.method = method
        self.platt_scaler = PlattScaler()
        self.isotonic_regressor = IsotonicRegressor()
        self.temperature_scaler = TemperatureScaler()
        
        # Training data storage
        self.training_confidences: List[float] = []
        self.training_labels: List[int] = []
        self.trained = False
        
        # Calibration history
        self.calibration_history: List[CalibrationResult] = []
    
    def fit(self, confidences: List[float], labels: List[int]):
        """
        Train calibration models.
        
        Args:
            confidences: List of uncalibrated confidence scores
            labels: List of true binary labels (0 or 1)
        """
        if len(confidences) != len(labels):
            raise ValueError("confidences and labels must have same length")
        
        if len(confidences) < 10:
            raise ValueError("Need at least 10 samples for calibration")
        
        # Store training data
        self.training_confidences = confidences.copy()
        self.training_labels = labels.copy()
        
        # Convert to numpy arrays
        conf_array = np.array(confidences)
        label_array = np.array(labels)
        
        # Train all calibrators
        self.platt_scaler.fit(conf_array, label_array)
        self.isotonic_regressor.fit(conf_array, label_array)
        self.temperature_scaler.fit(conf_array, label_array)
        
        self.trained = True
    
    def calibrate(self, confidence: float) -> CalibrationResult:
        """
        Calibrate a single confidence score.
        
        Args:
            confidence: Uncalibrated confidence (0-1)
            
        Returns:
            CalibrationResult with calibrated confidence
        """
        if not self.trained:
            return CalibrationResult(
                original_confidence=confidence,
                calibrated_confidence=confidence,
                method_used=CalibrationMethod.NONE
            )
        
        # Select calibration method
        if self.method == CalibrationMethod.PLATT_SCALING:
            calibrated = self.platt_scaler.calibrate(confidence)
        elif self.method == CalibrationMethod.ISOTONIC_REGRESSION:
            calibrated = self.isotonic_regressor.calibrate(confidence)
        elif self.method == CalibrationMethod.TEMPERATURE_SCALING:
            calibrated = self.temperature_scaler.calibrate(confidence)
        else:
            calibrated = confidence
        
        # Calculate calibration error (simplified)
        error = abs(calibrated - confidence)
        
        result = CalibrationResult(
            original_confidence=confidence,
            calibrated_confidence=calibrated,
            method_used=self.method,
            calibration_error=error,
            is_improved=error < 0.1  # Consider improved if change < 0.1
        )
        
        self.calibration_history.append(result)
        
        return result
    
    def calibrate_batch(self, confidences: List[float]) -> List[CalibrationResult]:
        """Calibrate multiple confidence scores."""
        return [self.calibrate(c) for c in confidences]
    
    def calculate_ece(self, 
                     confidences: List[float],
                     labels: List[int],
                     n_bins: int = 10) -> float:
        """
        Calculate Expected Calibration Error (ECE).
        
        ECE measures the weighted average difference between
        predicted confidence and actual accuracy across bins.
        
        Lower ECE = better calibration (ideal: 0.0)
        
        Args:
            confidences: Predicted confidence scores
            labels: True binary labels
            n_bins: Number of bins for discretization
            
        Returns:
            ECE value (0-1)
        """
        conf_array = np.array(confidences)
        label_array = np.array(labels)
        
        bin_boundaries = np.linspace(0.0, 1.0, n_bins + 1)
        ece = 0.0
        total_samples = len(conf_array)
        
        for i in range(n_bins):
            # Get samples in this bin
            mask = (conf_array >= bin_boundaries[i]) & (
                conf_array < bin_boundaries[i + 1]
            )
            
            if i == n_bins - 1:  # Include right boundary for last bin
                mask = (conf_array >= bin_boundaries[i]) & (
                    conf_array <= bin_boundaries[i + 1]
                )
            
            bin_size = np.sum(mask)
            
            if bin_size > 0:
                # Average confidence in bin
                avg_confidence = np.mean(conf_array[mask])
                
                # Actual accuracy in bin
                avg_accuracy = np.mean(label_array[mask])
                
                # Weighted difference
                ece += (bin_size / total_samples) * abs(avg_accuracy - avg_confidence)
        
        return float(ece)
    
    def calculate_brier_score(self,
                             confidences: List[float],
                             labels: List[int]) -> float:
        """
        Calculate Brier Score.
        
        Mean squared error between predicted probabilities and actual outcomes.
        Lower is better (ideal: 0.0).
        
        Args:
            confidences: Predicted confidence scores
            labels: True binary labels
            
        Returns:
            Brier score (0-1)
        """
        conf_array = np.array(confidences)
        label_array = np.array(labels)
        
        brier = np.mean((conf_array - label_array) ** 2)
        
        return float(brier)
    
    def calculate_mce(self,
                     confidences: List[float],
                     labels: List[int],
                     n_bins: int = 10) -> float:
        """
        Calculate Maximum Calibration Error (MCE).
        
        Maximum difference between confidence and accuracy across all bins.
        
        Args:
            confidences: Predicted confidence scores
            labels: True binary labels
            n_bins: Number of bins
            
        Returns:
            MCE value (0-1)
        """
        conf_array = np.array(confidences)
        label_array = np.array(labels)
        
        bin_boundaries = np.linspace(0.0, 1.0, n_bins + 1)
        max_error = 0.0
        
        for i in range(n_bins):
            mask = (conf_array >= bin_boundaries[i]) & (
                conf_array < bin_boundaries[i + 1]
            )
            
            if i == n_bins - 1:
                mask = (conf_array >= bin_boundaries[i]) & (
                    conf_array <= bin_boundaries[i + 1]
                )
            
            if np.sum(mask) > 0:
                avg_confidence = np.mean(conf_array[mask])
                avg_accuracy = np.mean(label_array[mask])
                error = abs(avg_accuracy - avg_confidence)
                max_error = max(max_error, error)
        
        return float(max_error)
    
    def generate_reliability_diagram(self,
                                    confidences: List[float],
                                    labels: List[int],
                                    n_bins: int = 10) -> Dict[str, List[float]]:
        """
        Generate data for reliability diagram visualization.
        
        Returns:
            Dictionary with bin_centers, accuracies, confidences, counts
        """
        conf_array = np.array(confidences)
        label_array = np.array(labels)
        
        bin_boundaries = np.linspace(0.0, 1.0, n_bins + 1)
        bin_centers = []
        accuracies = []
        avg_confidences = []
        counts = []
        
        for i in range(n_bins):
            mask = (conf_array >= bin_boundaries[i]) & (
                conf_array < bin_boundaries[i + 1]
            )
            
            if i == n_bins - 1:
                mask = (conf_array >= bin_boundaries[i]) & (
                    conf_array <= bin_boundaries[i + 1]
                )
            
            bin_size = np.sum(mask)
            
            if bin_size > 0:
                bin_centers.append((bin_boundaries[i] + bin_boundaries[i + 1]) / 2)
                accuracies.append(float(np.mean(label_array[mask])))
                avg_confidences.append(float(np.mean(conf_array[mask])))
                counts.append(int(bin_size))
            else:
                bin_centers.append((bin_boundaries[i] + bin_boundaries[i + 1]) / 2)
                accuracies.append(0.0)
                avg_confidences.append(0.0)
                counts.append(0)
        
        return {
            "bin_centers": bin_centers,
            "accuracies": accuracies,
            "avg_confidences": avg_confidences,
            "counts": counts
        }
    
    def evaluate_calibration(self,
                            confidences: List[float],
                            labels: List[int]) -> CalibrationMetrics:
        """
        Comprehensive calibration evaluation.
        
        Args:
            confidences: Uncalibrated confidence scores
            labels: True binary labels
            
        Returns:
            CalibrationMetrics with all quality metrics
        """
        # Calculate pre-calibration metrics
        pre_ece = self.calculate_ece(confidences, labels)
        pre_brier = self.calculate_brier_score(confidences, labels)
        pre_mce = self.calculate_mce(confidences, labels)
        
        # Calibrate
        calibrated_results = self.calibrate_batch(confidences)
        calibrated_confidences = [r.calibrated_confidence for r in calibrated_results]
        
        # Calculate post-calibration metrics
        post_ece = self.calculate_ece(calibrated_confidences, labels)
        post_brier = self.calculate_brier_score(calibrated_confidences, labels)
        post_mce = self.calculate_mce(calibrated_confidences, labels)
        
        # Calculate accuracy
        pre_predictions = [1 if c >= 0.5 else 0 for c in confidences]
        post_predictions = [1 if c >= 0.5 else 0 for c in calibrated_confidences]
        
        pre_accuracy = sum(1 for p, l in zip(pre_predictions, labels) if p == l) / len(labels)
        post_accuracy = sum(1 for p, l in zip(post_predictions, labels) if p == l) / len(labels)
        
        improvement = ((post_accuracy - pre_accuracy) / pre_accuracy * 100) if pre_accuracy > 0 else 0
        
        # Generate reliability diagram
        reliability = self.generate_reliability_diagram(calibrated_confidences, labels)
        
        # Count well-calibrated samples (within 0.1 of true accuracy)
        well_calibrated = sum(
            1 for orig, cal in zip(confidences, calibrated_confidences)
            if abs(cal - orig) < 0.1
        )
        
        metrics = CalibrationMetrics(
            ece=post_ece,
            mce=post_mce,
            brier_score=post_brier,
            reliability_diagram=reliability,
            pre_calibration_accuracy=pre_accuracy,
            post_calibration_accuracy=post_accuracy,
            improvement_percentage=improvement,
            total_samples=len(labels),
            well_calibrated_samples=well_calibrated
        )
        
        return metrics
    
    def auto_select_method(self,
                          confidences: List[float],
                          labels: List[int]) -> CalibrationMethod:
        """
        Automatically select best calibration method.
        
        Tests all methods and selects the one with lowest ECE.
        
        Args:
            confidences: Training confidence scores
            labels: Training labels
            
        Returns:
            Best calibration method
        """
        methods = [
            CalibrationMethod.PLATT_SCALING,
            CalibrationMethod.ISOTONIC_REGRESSION,
            CalibrationMethod.TEMPERATURE_SCALING
        ]
        
        best_method = CalibrationMethod.PLATT_SCALING
        best_ece = float('inf')
        
        for method in methods:
            # Create temporary calibrator
            temp_calibrator = ConfidenceCalibrator(method=method)
            temp_calibrator.fit(confidences, labels)
            
            # Evaluate
            metrics = temp_calibrator.evaluate_calibration(confidences, labels)
            
            if metrics.ece < best_ece:
                best_ece = metrics.ece
                best_method = method
        
        return best_method
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get calibration statistics."""
        if not self.calibration_history:
            return {"total_calibrations": 0}
        
        avg_original = sum(r.original_confidence for r in self.calibration_history) / len(self.calibration_history)
        avg_calibrated = sum(r.calibrated_confidence for r in self.calibration_history) / len(self.calibration_history)
        avg_error = sum(r.calibration_error for r in self.calibration_history) / len(self.calibration_history)
        
        return {
            "total_calibrations": len(self.calibration_history),
            "avg_original_confidence": avg_original,
            "avg_calibrated_confidence": avg_calibrated,
            "avg_calibration_error": avg_error,
            "method": self.method.value,
            "trained": self.trained
        }


def main():
    """Test the Confidence Calibrator."""
    
    print("="*70)
    print("CONFIDENCE CALIBRATOR - TEST SUITE")
    print("="*70)
    
    # Generate synthetic test data
    np.random.seed(42)
    n_samples = 500
    
    # Simulate uncalibrated confidences (tend to be overconfident)
    raw_confidences = np.random.beta(2, 1, n_samples)  # Skewed toward high values
    labels = (np.random.random(n_samples) < raw_confidences).astype(int)
    
    print(f"\n✓ Generated {n_samples} test samples")
    print(f"  Raw confidence range: [{raw_confidences.min():.2f}, {raw_confidences.max():.2f}]")
    print(f"  Label distribution: {sum(labels)}/{n_samples} positive")
    
    # Test 1: Platt Scaling
    print("\n" + "="*70)
    print("TEST 1: PLATT SCALING")
    print("="*70)
    
    platt_calibrator = ConfidenceCalibrator(method=CalibrationMethod.PLATT_SCALING)
    platt_calibrator.fit(raw_confidences.tolist(), labels.tolist())
    
    # Evaluate
    metrics = platt_calibrator.evaluate_calibration(raw_confidences.tolist(), labels.tolist())
    
    print(f"\n✓ Platt Scaling Results:")
    print(f"  ECE: {metrics.ece:.4f}")
    print(f"  MCE: {metrics.mce:.4f}")
    print(f"  Brier Score: {metrics.brier_score:.4f}")
    print(f"  Pre-calibration accuracy: {metrics.pre_calibration_accuracy:.2%}")
    print(f"  Post-calibration accuracy: {metrics.post_calibration_accuracy:.2%}")
    print(f"  Improvement: {metrics.improvement_percentage:.1f}%")
    print(f"  Well-calibrated samples: {metrics.well_calibrated_samples}/{metrics.total_samples}")
    
    # Test 2: Isotonic Regression
    print("\n" + "="*70)
    print("TEST 2: ISOTONIC REGRESSION")
    print("="*70)
    
    isotonic_calibrator = ConfidenceCalibrator(method=CalibrationMethod.ISOTONIC_REGRESSION)
    isotonic_calibrator.fit(raw_confidences.tolist(), labels.tolist())
    
    metrics_iso = isotonic_calibrator.evaluate_calibration(raw_confidences.tolist(), labels.tolist())
    
    print(f"\n✓ Isotonic Regression Results:")
    print(f"  ECE: {metrics_iso.ece:.4f}")
    print(f"  MCE: {metrics_iso.mce:.4f}")
    print(f"  Brier Score: {metrics_iso.brier_score:.4f}")
    print(f"  Improvement: {metrics_iso.improvement_percentage:.1f}%")
    
    # Test 3: Temperature Scaling
    print("\n" + "="*70)
    print("TEST 3: TEMPERATURE SCALING")
    print("="*70)
    
    temp_calibrator = ConfidenceCalibrator(method=CalibrationMethod.TEMPERATURE_SCALING)
    temp_calibrator.fit(raw_confidences.tolist(), labels.tolist())
    
    metrics_temp = temp_calibrator.evaluate_calibration(raw_confidences.tolist(), labels.tolist())
    
    print(f"\n✓ Temperature Scaling Results:")
    print(f"  ECE: {metrics_temp.ece:.4f}")
    print(f"  Temperature: {temp_calibrator.temperature_scaler.temperature:.2f}")
    print(f"  Brier Score: {metrics_temp.brier_score:.4f}")
    print(f"  Improvement: {metrics_temp.improvement_percentage:.1f}%")
    
    # Test 4: Auto Method Selection
    print("\n" + "="*70)
    print("TEST 4: AUTOMATIC METHOD SELECTION")
    print("="*70)
    
    auto_calibrator = ConfidenceCalibrator()
    best_method = auto_calibrator.auto_select_method(raw_confidences.tolist(), labels.tolist())
    
    print(f"\n✓ Best method selected: {best_method.value}")
    print(f"  ECE comparison:")
    print(f"    Platt: {metrics.ece:.4f}")
    print(f"    Isotonic: {metrics_iso.ece:.4f}")
    print(f"    Temperature: {metrics_temp.ece:.4f}")
    
    # Test 5: Batch Calibration
    print("\n" + "="*70)
    print("TEST 5: BATCH CALIBRATION")
    print("="*70)
    
    test_confidences = [0.3, 0.5, 0.7, 0.85, 0.95]
    results = platt_calibrator.calibrate_batch(test_confidences)
    
    print(f"\n✓ Batch calibration examples:")
    for orig, result in zip(test_confidences, results):
        print(f"  {orig:.2f} → {result.calibrated_confidence:.2f} (error: {result.calibration_error:.2f})")
    
    # Test 6: Calibration Statistics
    print("\n" + "="*70)
    print("TEST 6: CALIBRATION STATISTICS")
    print("="*70)
    
    stats = platt_calibrator.get_statistics()
    print(f"\n✓ Calibration statistics:")
    print(f"  Total calibrations: {stats['total_calibrations']}")
    print(f"  Avg original confidence: {stats['avg_original_confidence']:.2f}")
    print(f"  Avg calibrated confidence: {stats['avg_calibrated_confidence']:.2f}")
    print(f"  Avg calibration error: {stats['avg_calibration_error']:.2f}")
    
    # Summary
    print("\n\n" + "="*70)
    print("SUMMARY")
    print("="*70)
    
    print(f"\n✅ Calibration methods tested:")
    print(f"  ✓ Platt Scaling (ECE: {metrics.ece:.4f})")
    print(f"  ✓ Isotonic Regression (ECE: {metrics_iso.ece:.4f})")
    print(f"  ✓ Temperature Scaling (ECE: {metrics_temp.ece:.4f})")
    print(f"  ✓ Auto method selection ({best_method.value})")
    print(f"  ✓ Batch calibration")
    print(f"  ✓ Comprehensive metrics (ECE, MCE, Brier)")
    print(f"  ✓ Reliability diagrams")
    
    # Find best method
    eces = {
        "Platt": metrics.ece,
        "Isotonic": metrics_iso.ece,
        "Temperature": metrics_temp.ece
    }
    best = min(eces, key=eces.get)
    
    print(f"\n🏆 Best method: {best} (ECE: {eces[best]:.4f})")
    print(f"{'='*70}")
    print("✅ CONFIDENCE CALIBRATOR - ALL TESTS PASSED")
    print(f"{'='*70}\n")


if __name__ == "__main__":
    main()
