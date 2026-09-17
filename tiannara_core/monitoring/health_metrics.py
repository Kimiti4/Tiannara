"""
COGNITIVE HEALTH METRICS SYSTEM

Purpose: Track comprehensive cognitive health beyond simple success metrics.

Based on next.md (lines 267-296):
"Stop measuring only success. If the system optimizes only accuracy, completion,
reward, speed - it will evolve deceptive shortcuts.

Add health metrics:
- epistemic integrity,
- contradiction handling,
- calibration accuracy,
- causal robustness,
- diversity preservation,
- recovery from false beliefs,
- uncertainty quality."

Architecture:
Monitors 7 core health dimensions with real-time scoring and alerts.
Provides early warning of cognitive degradation before performance drops.
"""

import time
import json
import logging
from pathlib import Path

logger = logging.getLogger(__name__)
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum


class HealthDimension(Enum):
    """Core dimensions of cognitive health."""
    EPISTEMIC_INTEGRITY = "epistemic_integrity"           # Truth-seeking quality
    CONTRADICTION_HANDLING = "contradiction_handling"     # How well conflicts managed
    CALIBRATION_ACCURACY = "calibration_accuracy"         # Confidence matches evidence
    CAUSAL_ROBUSTNESS = "causal_robustness"               # Causal chain validity
    DIVERSITY_PRESERVATION = "diversity_preservation"     # Idea/theory diversity
    RECOVERY_QUALITY = "recovery_quality"                 # Bounce-back from errors
    UNCERTAINTY_QUALITY = "uncertainty_quality"           # Honest uncertainty expression


@dataclass
class HealthMetric:
    """Single health metric measurement."""
    dimension: HealthDimension
    score: float                    # 0.0-1.0, current health score
    trend: str                      # "improving", "stable", "declining"
    
    # Context
    timestamp: float = field(default_factory=time.time)
    domain: Optional[str] = None
    sample_size: int = 0
    
    # Details
    contributing_factors: Dict[str, float] = field(default_factory=dict)
    warning_signals: List[str] = field(default_factory=list)
    
    # Historical
    previous_score: float = 0.0
    change_rate: float = 0.0        # Score change per hour


@dataclass
class CognitiveHealthReport:
    """Comprehensive cognitive health assessment."""
    report_id: str
    overall_health_score: float     # Weighted average of all dimensions
    health_status: str              # "healthy", "warning", "critical"
    
    # Context
    timestamp: float = field(default_factory=time.time)
    
    # Dimension scores
    dimensions: Dict[HealthDimension, HealthMetric] = field(default_factory=dict)
    
    # Alerts
    active_alerts: List[Dict] = field(default_factory=list)
    
    # Trends
    health_trend: str = "stable"               # Overall trend direction
    weakest_dimension: Optional[HealthDimension] = None
    strongest_dimension: Optional[HealthDimension] = None
    
    # Recommendations
    recommendations: List[str] = field(default_factory=list)


class CognitiveHealthMonitor:
    """
    Continuous cognitive health monitoring system.
    
    Tracks 7 core dimensions and provides early warning of degradation.
    """
    
    def __init__(self, storage_path: Optional[str] = None):
        self.storage_path = storage_path or "runs/health_metrics.jsonl"
        self.metrics_history: List[CognitiveHealthReport] = []
        self.alert_thresholds = {
            HealthDimension.EPISTEMIC_INTEGRITY: 0.7,
            HealthDimension.CONTRADICTION_HANDLING: 0.65,
            HealthDimension.CALIBRATION_ACCURACY: 0.75,
            HealthDimension.CAUSAL_ROBUSTNESS: 0.7,
            HealthDimension.DIVERSITY_PRESERVATION: 0.6,
            HealthDimension.RECOVERY_QUALITY: 0.65,
            HealthDimension.UNCERTAINTY_QUALITY: 0.7,
        }
        
        # Dimension weights for overall score
        self.dimension_weights = {
            HealthDimension.EPISTEMIC_INTEGRITY: 0.20,      # Most important
            HealthDimension.CONTRADICTION_HANDLING: 0.15,
            HealthDimension.CALIBRATION_ACCURACY: 0.15,
            HealthDimension.CAUSAL_ROBUSTNESS: 0.15,
            HealthDimension.DIVERSITY_PRESERVATION: 0.15,
            HealthDimension.RECOVERY_QUALITY: 0.10,
            HealthDimension.UNCERTAINTY_QUALITY: 0.10,
        }
    
    def calculate_epistemic_integrity(
        self,
        total_beliefs: int,
        verified_beliefs: int,
        contradicted_beliefs: int,
        evidence_quality_avg: float
    ) -> HealthMetric:
        """
        Calculate epistemic integrity score.
        
        Measures how well the system maintains truth-seeking behavior.
        High integrity = beliefs align with evidence, contradictions resolved.
        """
        if total_beliefs == 0:
            return HealthMetric(
                dimension=HealthDimension.EPISTEMIC_INTEGRITY,
                score=1.0,
                trend="stable",
                warning_signals=["No beliefs tracked yet"]
            )
        
        # Components
        verification_rate = verified_beliefs / max(total_beliefs, 1)
        contradiction_rate = contradicted_beliefs / max(total_beliefs, 1)
        
        # Formula: weighted combination
        score = (
            verification_rate * 0.4 +
            (1 - contradiction_rate) * 0.3 +
            evidence_quality_avg * 0.3
        )
        
        # Determine trend
        trend = self._calculate_trend(HealthDimension.EPISTEMIC_INTEGRITY, score)
        
        # Warning signals
        warnings = []
        if contradiction_rate > 0.3:
            warnings.append(f"High contradiction rate: {contradiction_rate:.1%}")
        if evidence_quality_avg < 0.6:
            warnings.append(f"Low evidence quality: {evidence_quality_avg:.2f}")
        if verification_rate < 0.5:
            warnings.append(f"Low verification rate: {verification_rate:.1%}")
        
        return HealthMetric(
            dimension=HealthDimension.EPISTEMIC_INTEGRITY,
            score=score,
            trend=trend,
            sample_size=total_beliefs,
            contributing_factors={
                "verification_rate": verification_rate,
                "contradiction_rate": contradiction_rate,
                "evidence_quality": evidence_quality_avg
            },
            warning_signals=warnings
        )
    
    def calculate_contradiction_handling(
        self,
        total_contradictions: int,
        resolved_contradictions: int,
        avg_resolution_time_hours: float,
        suppression_incidents: int
    ) -> HealthMetric:
        """
        Calculate contradiction handling quality.
        
        Measures how effectively the system manages conflicting information.
        Good handling = contradictions detected, preserved, and resolved.
        """
        if total_contradictions == 0:
            return HealthMetric(
                dimension=HealthDimension.CONTRADICTION_HANDLING,
                score=1.0,
                trend="stable",
                warning_signals=["No contradictions detected yet"]
            )
        
        # Components
        resolution_rate = resolved_contradictions / max(total_contradictions, 1)
        suppression_rate = suppression_incidents / max(total_contradictions, 1)
        
        # Time factor (faster is better, but not too fast)
        time_score = max(0, 1 - (avg_resolution_time_hours / 168))  # Normalize to 1 week
        
        # Formula
        score = (
            resolution_rate * 0.4 +
            (1 - suppression_rate) * 0.35 +
            time_score * 0.25
        )
        
        trend = self._calculate_trend(HealthDimension.CONTRADICTION_HANDLING, score)
        
        warnings = []
        if suppression_rate > 0.1:
            warnings.append(f"Contradiction suppression detected: {suppression_rate:.1%}")
        if resolution_rate < 0.5:
            warnings.append(f"Low resolution rate: {resolution_rate:.1%}")
        if avg_resolution_time_hours > 72:
            warnings.append(f"Slow resolution: {avg_resolution_time_hours:.1f} hours")
        
        return HealthMetric(
            dimension=HealthDimension.CONTRADICTION_HANDLING,
            score=score,
            trend=trend,
            sample_size=total_contradictions,
            contributing_factors={
                "resolution_rate": resolution_rate,
                "suppression_rate": suppression_rate,
                "avg_resolution_time": avg_resolution_time_hours
            },
            warning_signals=warnings
        )
    
    def calculate_calibration_accuracy(
        self,
        predictions: List[Dict[str, float]],
        actual_outcomes: List[bool]
    ) -> HealthMetric:
        """
        Calculate calibration accuracy.
        
        Measures if confidence levels match actual success rates.
        Well-calibrated: 80% confidence → 80% accuracy.
        """
        if len(predictions) < 10:
            return HealthMetric(
                dimension=HealthDimension.CALIBRATION_ACCURACY,
                score=1.0,
                trend="stable",
                warning_signals=["Insufficient data for calibration"]
            )
        
        # Bin predictions by confidence level
        bins = {
            "0.9-1.0": {"predicted": 0, "actual": 0},
            "0.7-0.9": {"predicted": 0, "actual": 0},
            "0.5-0.7": {"predicted": 0, "actual": 0},
            "0.3-0.5": {"predicted": 0, "actual": 0},
            "0.0-0.3": {"predicted": 0, "actual": 0},
        }
        
        for pred, outcome in zip(predictions, actual_outcomes):
            confidence = pred.get("confidence", 0.5)
            
            if confidence >= 0.9:
                bins["0.9-1.0"]["predicted"] += 1
                bins["0.9-1.0"]["actual"] += 1 if outcome else 0
            elif confidence >= 0.7:
                bins["0.7-0.9"]["predicted"] += 1
                bins["0.7-0.9"]["actual"] += 1 if outcome else 0
            elif confidence >= 0.5:
                bins["0.5-0.7"]["predicted"] += 1
                bins["0.5-0.7"]["actual"] += 1 if outcome else 0
            elif confidence >= 0.3:
                bins["0.3-0.5"]["predicted"] += 1
                bins["0.3-0.5"]["actual"] += 1 if outcome else 0
            else:
                bins["0.0-0.3"]["predicted"] += 1
                bins["0.0-0.3"]["actual"] += 1 if outcome else 0
        
        # Calculate calibration error (lower is better)
        total_error = 0
        total_count = 0
        
        for bin_range, counts in bins.items():
            if counts["predicted"] > 0:
                expected_rate = float(bin_range.split("-")[0]) + 0.1  # Midpoint approx
                actual_rate = counts["actual"] / counts["predicted"]
                error = abs(expected_rate - actual_rate)
                total_error += error * counts["predicted"]
                total_count += counts["predicted"]
        
        calibration_error = total_error / max(total_count, 1)
        score = max(0, 1 - calibration_error)
        
        trend = self._calculate_trend(HealthDimension.CALIBRATION_ACCURACY, score)
        
        warnings = []
        if calibration_error > 0.3:
            warnings.append(f"Poor calibration: error={calibration_error:.2f}")
        
        return HealthMetric(
            dimension=HealthDimension.CALIBRATION_ACCURACY,
            score=score,
            trend=trend,
            sample_size=len(predictions),
            contributing_factors={
                "calibration_error": calibration_error
            },
            warning_signals=warnings
        )
    
    def calculate_causal_robustness(
        self,
        total_causal_claims: int,
        validated_claims: int,
        refuted_claims: int,
        avg_causal_depth: float
    ) -> HealthMetric:
        """
        Calculate causal robustness.
        
        Measures validity and depth of causal reasoning.
        Robust causality = claims validated, deep mechanisms identified.
        """
        if total_causal_claims == 0:
            return HealthMetric(
                dimension=HealthDimension.CAUSAL_ROBUSTNESS,
                score=1.0,
                trend="stable",
                warning_signals=["No causal claims made yet"]
            )
        
        validation_rate = validated_claims / max(total_causal_claims, 1)
        refutation_rate = refuted_claims / max(total_causal_claims, 1)
        
        # Formula
        score = (
            validation_rate * 0.5 +
            (1 - refutation_rate) * 0.3 +
            avg_causal_depth * 0.2
        )
        
        trend = self._calculate_trend(HealthDimension.CAUSAL_ROBUSTNESS, score)
        
        warnings = []
        if refutation_rate > 0.3:
            warnings.append(f"High causal refutation rate: {refutation_rate:.1%}")
        if avg_causal_depth < 0.5:
            warnings.append(f"Shallow causal reasoning: depth={avg_causal_depth:.2f}")
        
        return HealthMetric(
            dimension=HealthDimension.CAUSAL_ROBUSTNESS,
            score=score,
            trend=trend,
            sample_size=total_causal_claims,
            contributing_factors={
                "validation_rate": validation_rate,
                "refutation_rate": refutation_rate,
                "avg_causal_depth": avg_causal_depth
            },
            warning_signals=warnings
        )
    
    def calculate_diversity_preservation(
        self,
        total_theories: int,
        unique_perspectives: int,
        minority_theories_retained: int,
        consensus_dominance_ratio: float
    ) -> HealthMetric:
        """
        Calculate diversity preservation.
        
        Measures if the system maintains idea/theory diversity.
        Good diversity = multiple perspectives preserved, no premature consensus.
        """
        if total_theories == 0:
            return HealthMetric(
                dimension=HealthDimension.DIVERSITY_PRESERVATION,
                score=1.0,
                trend="stable",
                warning_signals=["No theories tracked yet"]
            )
        
        perspective_diversity = unique_perspectives / max(total_theories, 1)
        minority_retention = minority_theories_retained / max(total_theories, 1)
        
        # Lower consensus dominance is better (prevents monoculture)
        consensus_health = 1 - consensus_dominance_ratio
        
        # Formula
        score = (
            perspective_diversity * 0.35 +
            minority_retention * 0.35 +
            consensus_health * 0.3
        )
        
        trend = self._calculate_trend(HealthDimension.DIVERSITY_PRESERVATION, score)
        
        warnings = []
        if consensus_dominance_ratio > 0.7:
            warnings.append(f"High consensus dominance: {consensus_dominance_ratio:.1%}")
        if minority_retention < 0.2:
            warnings.append(f"Low minority theory retention: {minority_retention:.1%}")
        
        return HealthMetric(
            dimension=HealthDimension.DIVERSITY_PRESERVATION,
            score=score,
            trend=trend,
            sample_size=total_theories,
            contributing_factors={
                "perspective_diversity": perspective_diversity,
                "minority_retention": minority_retention,
                "consensus_dominance": consensus_dominance_ratio
            },
            warning_signals=warnings
        )
    
    def calculate_recovery_quality(
        self,
        total_failures: int,
        successful_recoveries: int,
        avg_recovery_time_hours: float,
        repeated_failures: int
    ) -> HealthMetric:
        """
        Calculate recovery quality from failures.
        
        Measures how well the system bounces back from errors.
        Good recovery = fast, complete, no repetition.
        """
        if total_failures == 0:
            return HealthMetric(
                dimension=HealthDimension.RECOVERY_QUALITY,
                score=1.0,
                trend="stable",
                warning_signals=["No failures to recover from yet"]
            )
        
        recovery_rate = successful_recoveries / max(total_failures, 1)
        repeat_failure_rate = repeated_failures / max(total_failures, 1)
        
        # Time factor
        time_score = max(0, 1 - (avg_recovery_time_hours / 48))  # Normalize to 2 days
        
        # Formula
        score = (
            recovery_rate * 0.4 +
            time_score * 0.3 +
            (1 - repeat_failure_rate) * 0.3
        )
        
        trend = self._calculate_trend(HealthDimension.RECOVERY_QUALITY, score)
        
        warnings = []
        if recovery_rate < 0.7:
            warnings.append(f"Low recovery rate: {recovery_rate:.1%}")
        if repeat_failure_rate > 0.2:
            warnings.append(f"High repeated failure rate: {repeat_failure_rate:.1%}")
        
        return HealthMetric(
            dimension=HealthDimension.RECOVERY_QUALITY,
            score=score,
            trend=trend,
            sample_size=total_failures,
            contributing_factors={
                "recovery_rate": recovery_rate,
                "avg_recovery_time": avg_recovery_time_hours,
                "repeat_failure_rate": repeat_failure_rate
            },
            warning_signals=warnings
        )
    
    def calculate_uncertainty_quality(
        self,
        uncertain_predictions: int,
        total_predictions: int,
        uncertainty_appropriateness: float
    ) -> HealthMetric:
        """
        Calculate uncertainty quality.
        
        Measures if the system expresses appropriate uncertainty.
        Good uncertainty = honest about limitations, not overconfident.
        """
        if total_predictions == 0:
            return HealthMetric(
                dimension=HealthDimension.UNCERTAINTY_QUALITY,
                score=1.0,
                trend="stable",
                warning_signals=["No predictions made yet"]
            )
        
        uncertainty_rate = uncertain_predictions / max(total_predictions, 1)
        
        # Ideal uncertainty rate depends on domain complexity
        # For now, reward appropriate uncertainty expression
        score = uncertainty_appropriateness
        
        trend = self._calculate_trend(HealthDimension.UNCERTAINTY_QUALITY, score)
        
        warnings = []
        if uncertainty_rate < 0.1 and total_predictions > 100:
            warnings.append("Very low uncertainty expression - possible overconfidence")
        if uncertainty_appropriateness < 0.6:
            warnings.append(f"Poor uncertainty calibration: {uncertainty_appropriateness:.2f}")
        
        return HealthMetric(
            dimension=HealthDimension.UNCERTAINTY_QUALITY,
            score=score,
            trend=trend,
            sample_size=total_predictions,
            contributing_factors={
                "uncertainty_rate": uncertainty_rate,
                "appropriateness": uncertainty_appropriateness
            },
            warning_signals=warnings
        )
    
    def generate_health_report(
        self,
        metrics_data: Dict[str, any]
    ) -> CognitiveHealthReport:
        """
        Generate comprehensive health report from collected metrics.
        
        Args:
            metrics_data: Dictionary containing all metric inputs
        
        Returns:
            Complete health assessment report
        """
        import uuid
        
        # Calculate all dimensions
        dimensions = {}
        
        # 1. Epistemic Integrity
        dimensions[HealthDimension.EPISTEMIC_INTEGRITY] = self.calculate_epistemic_integrity(
            total_beliefs=metrics_data.get("total_beliefs", 0),
            verified_beliefs=metrics_data.get("verified_beliefs", 0),
            contradicted_beliefs=metrics_data.get("contradicted_beliefs", 0),
            evidence_quality_avg=metrics_data.get("evidence_quality_avg", 0.5)
        )
        
        # 2. Contradiction Handling
        dimensions[HealthDimension.CONTRADICTION_HANDLING] = self.calculate_contradiction_handling(
            total_contradictions=metrics_data.get("total_contradictions", 0),
            resolved_contradictions=metrics_data.get("resolved_contradictions", 0),
            avg_resolution_time_hours=metrics_data.get("avg_resolution_time_hours", 24),
            suppression_incidents=metrics_data.get("suppression_incidents", 0)
        )
        
        # 3. Calibration Accuracy
        dimensions[HealthDimension.CALIBRATION_ACCURACY] = self.calculate_calibration_accuracy(
            predictions=metrics_data.get("predictions", []),
            actual_outcomes=metrics_data.get("actual_outcomes", [])
        )
        
        # 4. Causal Robustness
        dimensions[HealthDimension.CAUSAL_ROBUSTNESS] = self.calculate_causal_robustness(
            total_causal_claims=metrics_data.get("total_causal_claims", 0),
            validated_claims=metrics_data.get("validated_claims", 0),
            refuted_claims=metrics_data.get("refuted_claims", 0),
            avg_causal_depth=metrics_data.get("avg_causal_depth", 0.5)
        )
        
        # 5. Diversity Preservation
        dimensions[HealthDimension.DIVERSITY_PRESERVATION] = self.calculate_diversity_preservation(
            total_theories=metrics_data.get("total_theories", 0),
            unique_perspectives=metrics_data.get("unique_perspectives", 0),
            minority_theories_retained=metrics_data.get("minority_theories_retained", 0),
            consensus_dominance_ratio=metrics_data.get("consensus_dominance_ratio", 0.5)
        )
        
        # 6. Recovery Quality
        dimensions[HealthDimension.RECOVERY_QUALITY] = self.calculate_recovery_quality(
            total_failures=metrics_data.get("total_failures", 0),
            successful_recoveries=metrics_data.get("successful_recoveries", 0),
            avg_recovery_time_hours=metrics_data.get("avg_recovery_time_hours", 12),
            repeated_failures=metrics_data.get("repeated_failures", 0)
        )
        
        # 7. Uncertainty Quality
        dimensions[HealthDimension.UNCERTAINTY_QUALITY] = self.calculate_uncertainty_quality(
            uncertain_predictions=metrics_data.get("uncertain_predictions", 0),
            total_predictions=metrics_data.get("total_predictions", 0),
            uncertainty_appropriateness=metrics_data.get("uncertainty_appropriateness", 0.7)
        )
        
        # Calculate overall health score (weighted average)
        overall_score = sum(
            metric.score * self.dimension_weights[dim]
            for dim, metric in dimensions.items()
        )
        
        # Determine health status
        if overall_score >= 0.8:
            health_status = "healthy"
        elif overall_score >= 0.6:
            health_status = "warning"
        else:
            health_status = "critical"
        
        # Identify weakest/strongest dimensions
        weakest = min(dimensions.items(), key=lambda x: x[1].score)
        strongest = max(dimensions.items(), key=lambda x: x[1].score)
        
        # Generate alerts
        alerts = []
        for dim, metric in dimensions.items():
            threshold = self.alert_thresholds[dim]
            if metric.score < threshold:
                alerts.append({
                    "dimension": dim.value,
                    "severity": "critical" if metric.score < threshold * 0.8 else "warning",
                    "message": f"{dim.value.replace('_', ' ').title()}: {metric.score:.2f} (threshold: {threshold})",
                    "recommendations": metric.warning_signals
                })
        
        # Generate recommendations
        recommendations = self._generate_recommendations(dimensions, overall_score)
        
        # Create report
        report = CognitiveHealthReport(
            report_id=str(uuid.uuid4()),
            overall_health_score=overall_score,
            health_status=health_status,
            dimensions=dimensions,
            active_alerts=alerts,
            health_trend=self._determine_overall_trend(dimensions),
            weakest_dimension=weakest[0],
            strongest_dimension=strongest[0],
            recommendations=recommendations
        )
        
        # Store report
        self.metrics_history.append(report)
        self._save_report(report)
        
        return report
    
    def _calculate_trend(self, dimension: HealthDimension, current_score: float) -> str:
        """Calculate trend based on historical data."""
        # Find previous measurements for this dimension
        previous_scores = [
            report.dimensions[dimension].score
            for report in self.metrics_history[-10:]  # Last 10 reports
            if dimension in report.dimensions
        ]
        
        if len(previous_scores) < 2:
            return "stable"
        
        recent_avg = sum(previous_scores[-3:]) / 3
        older_avg = sum(previous_scores[:3]) / 3
        
        diff = recent_avg - older_avg
        
        if diff > 0.05:
            return "improving"
        elif diff < -0.05:
            return "declining"
        else:
            return "stable"
    
    def _determine_overall_trend(self, dimensions: Dict[HealthDimension, HealthMetric]) -> str:
        """Determine overall health trend."""
        trends = [metric.trend for metric in dimensions.values()]
        
        improving_count = trends.count("improving")
        declining_count = trends.count("declining")
        
        if improving_count > declining_count + 2:
            return "improving"
        elif declining_count > improving_count + 2:
            return "declining"
        else:
            return "stable"
    
    def _generate_recommendations(
        self,
        dimensions: Dict[HealthDimension, HealthMetric],
        overall_score: float
    ) -> List[str]:
        """Generate actionable recommendations based on health status."""
        recommendations = []
        
        # Overall recommendations
        if overall_score < 0.6:
            recommendations.append(
                "CRITICAL: Overall cognitive health is degraded. Consider pausing complex reasoning tasks."
            )
        
        # Dimension-specific recommendations
        for dim, metric in dimensions.items():
            if metric.score < self.alert_thresholds[dim]:
                if dim == HealthDimension.EPISTEMIC_INTEGRITY:
                    recommendations.append(
                        "Improve epistemic integrity: Increase evidence collection, resolve contradictions."
                    )
                elif dim == HealthDimension.CONTRADICTION_HANDLING:
                    recommendations.append(
                        "Enhance contradiction handling: Review suppressed conflicts, accelerate resolution."
                    )
                elif dim == HealthDimension.CALIBRATION_ACCURACY:
                    recommendations.append(
                        "Recalibrate confidence: Review prediction accuracy vs stated confidence."
                    )
                elif dim == HealthDimension.CAUSAL_ROBUSTNESS:
                    recommendations.append(
                        "Strengthen causal reasoning: Validate more causal claims, deepen analysis."
                    )
                elif dim == HealthDimension.DIVERSITY_PRESERVATION:
                    recommendations.append(
                        "Preserve diversity: Encourage minority perspectives, reduce consensus pressure."
                    )
                elif dim == HealthDimension.RECOVERY_QUALITY:
                    recommendations.append(
                        "Improve recovery: Analyze repeated failures, implement prevention strategies."
                    )
                elif dim == HealthDimension.UNCERTAINTY_QUALITY:
                    recommendations.append(
                        "Express uncertainty: Be more honest about knowledge limitations."
                    )
        
        return recommendations
    
    def _save_report(self, report: CognitiveHealthReport):
        """Save report to storage."""
        try:
            # Convert to dict for JSON serialization
            report_dict = {
                "report_id": report.report_id,
                "timestamp": report.timestamp,
                "overall_health_score": report.overall_health_score,
                "health_status": report.health_status,
                "dimensions": {
                    dim.value: {
                        "score": metric.score,
                        "trend": metric.trend,
                        "sample_size": metric.sample_size,
                        "warning_signals": metric.warning_signals
                    }
                    for dim, metric in report.dimensions.items()
                },
                "active_alerts": report.active_alerts,
                "health_trend": report.health_trend,
                "weakest_dimension": report.weakest_dimension.value if report.weakest_dimension else None,
                "strongest_dimension": report.strongest_dimension.value if report.strongest_dimension else None,
                "recommendations": report.recommendations
            }
            
            # Append to JSONL file
            path = Path(self.storage_path)
            path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(path, "a") as f:
                f.write(json.dumps(report_dict) + "\n")
        
        except Exception as e:
            logger.warning(f"Failed to save health report: {e}")
    
    def get_health_summary(self) -> Dict:
        """Get current health summary for dashboard."""
        if not self.metrics_history:
            return {
                "status": "no_data",
                "message": "No health metrics collected yet"
            }
        
        latest = self.metrics_history[-1]
        
        return {
            "overall_score": latest.overall_health_score,
            "status": latest.health_status,
            "trend": latest.health_trend,
            "dimensions": {
                dim.value: {
                    "score": metric.score,
                    "trend": metric.trend
                }
                for dim, metric in latest.dimensions.items()
            },
            "alerts": len(latest.active_alerts),
            "weakest": latest.weakest_dimension.value if latest.weakest_dimension else None,
            "recommendations": latest.recommendations[:3]  # Top 3
        }
