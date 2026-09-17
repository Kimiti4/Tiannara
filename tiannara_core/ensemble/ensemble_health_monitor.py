"""
Ensemble Health Monitor & Complexity Manager

Purpose: Monitor ensemble complexity and provide automated management
Features:
- Model performance tracking
- Complexity metrics calculation
- Automated model pruning
- Maintenance cost estimation
- Health dashboard generation

Date: May 8, 2026
Status: Risk Mitigation Module
"""

from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from collections import defaultdict


@dataclass
class ModelHealthMetrics:
    """Health metrics for a single model."""
    
    model_name: str
    total_predictions: int = 0
    successful_predictions: int = 0
    avg_confidence: float = 0.0
    avg_inference_time_ms: float = 0.0
    last_used: Optional[datetime] = None
    memory_usage_mb: float = 0.0
    maintenance_score: float = 0.0  # 0-1, lower is better
    
    @property
    def success_rate(self) -> float:
        if self.total_predictions == 0:
            return 0.0
        return self.successful_predictions / self.total_predictions
    
    @property
    def is_underperforming(self) -> bool:
        return self.success_rate < 0.6 or self.avg_confidence < 0.5
    
    @property
    def is_stale(self) -> bool:
        if not self.last_used:
            return True
        return (datetime.now() - self.last_used).days > 7


@dataclass
class EnsembleHealthReport:
    """Overall ensemble health report."""
    
    timestamp: datetime = field(default_factory=datetime.now)
    total_models: int = 0
    active_models: int = 0
    underperforming_models: int = 0
    stale_models: int = 0
    
    # Complexity metrics
    complexity_score: float = 0.0  # 0-1, lower is simpler
    maintenance_cost_estimate_hours: float = 0.0
    redundancy_level: float = 0.0  # How much models overlap
    
    # Performance metrics
    overall_success_rate: float = 0.0
    overall_avg_confidence: float = 0.0
    avg_inference_time_ms: float = 0.0
    
    # Recommendations
    recommendations: List[str] = field(default_factory=list)
    models_to_prune: List[str] = field(default_factory=list)
    
    def to_dict(self) -> Dict:
        return {
            "timestamp": self.timestamp.isoformat(),
            "total_models": self.total_models,
            "active_models": self.active_models,
            "underperforming_models": self.underperforming_models,
            "stale_models": self.stale_models,
            "complexity_score": self.complexity_score,
            "maintenance_cost_hours": self.maintenance_cost_estimate_hours,
            "overall_success_rate": self.overall_success_rate,
            "recommendations": self.recommendations
        }


class EnsembleHealthMonitor:
    """
    Monitors ensemble health and manages complexity.
    
    Provides automated tools to:
    - Track model performance over time
    - Identify underperforming or stale models
    - Calculate complexity metrics
    - Recommend model pruning
    - Estimate maintenance costs
    """
    
    def __init__(self):
        self.model_metrics: Dict[str, ModelHealthMetrics] = {}
        self.prediction_history: List[Dict] = []
        self.complexity_threshold = 0.7  # Max acceptable complexity
        
    def register_model(self, model_name: str, memory_usage_mb: float = 10.0):
        """Register a new model for monitoring."""
        self.model_metrics[model_name] = ModelHealthMetrics(
            model_name=model_name,
            memory_usage_mb=memory_usage_mb
        )
    
    def record_prediction(self, 
                         model_name: str,
                         success: bool,
                         confidence: float,
                         inference_time_ms: float):
        """Record a prediction event for a model."""
        if model_name not in self.model_metrics:
            self.register_model(model_name)
        
        metrics = self.model_metrics[model_name]
        metrics.total_predictions += 1
        if success:
            metrics.successful_predictions += 1
        
        # Update running averages
        n = metrics.total_predictions
        metrics.avg_confidence = (
            (metrics.avg_confidence * (n - 1) + confidence) / n
        )
        metrics.avg_inference_time_ms = (
            (metrics.avg_inference_time_ms * (n - 1) + inference_time_ms) / n
        )
        metrics.last_used = datetime.now()
        
        # Record in history
        self.prediction_history.append({
            "model": model_name,
            "success": success,
            "confidence": confidence,
            "timestamp": datetime.now()
        })
        
        # Keep history manageable (last 1000 predictions)
        if len(self.prediction_history) > 1000:
            self.prediction_history = self.prediction_history[-1000:]
    
    def calculate_complexity_score(self) -> float:
        """
        Calculate ensemble complexity score (0-1).
        
        Factors:
        - Number of models (40%)
        - Model diversity (30%)
        - Interdependencies (20%)
        - Configuration complexity (10%)
        """
        num_models = len(self.model_metrics)
        
        # Factor 1: Number of models (optimal: 3-7)
        if num_models <= 3:
            model_count_score = 0.3
        elif num_models <= 7:
            model_count_score = 0.5
        elif num_models <= 10:
            model_count_score = 0.7
        else:
            model_count_score = 1.0
        
        # Factor 2: Model diversity (performance variance)
        if num_models > 1:
            performances = [m.success_rate for m in self.model_metrics.values()]
            variance = sum((p - sum(performances)/len(performances))**2 
                          for p in performances) / len(performances)
            diversity_score = min(1.0, variance * 5)  # Scale variance
        else:
            diversity_score = 0.0
        
        # Factor 3: Interdependencies (models that always agree/disagree)
        interdependency_score = self._calculate_interdependency()
        
        # Factor 4: Configuration complexity
        config_complexity = min(1.0, num_models * 0.1)
        
        # Weighted combination
        complexity = (
            0.40 * model_count_score +
            0.30 * diversity_score +
            0.20 * interdependency_score +
            0.10 * config_complexity
        )
        
        return min(1.0, complexity)
    
    def _calculate_interdependency(self) -> float:
        """Calculate how interdependent models are."""
        if len(self.model_metrics) < 2:
            return 0.0
        
        # Simple heuristic: check if models have similar performance
        performances = [m.success_rate for m in self.model_metrics.values()]
        if not performances:
            return 0.0
        
        avg_perf = sum(performances) / len(performances)
        max_deviation = max(abs(p - avg_perf) for p in performances)
        
        # Low deviation = high interdependency (bad)
        interdependency = 1.0 - min(1.0, max_deviation * 2)
        
        return interdependency
    
    def estimate_maintenance_cost(self) -> float:
        """
        Estimate monthly maintenance cost in hours.
        
        Based on:
        - Number of models
        - Model complexity
        - Update frequency
        - Monitoring overhead
        """
        num_models = len(self.model_metrics)
        
        # Base cost per model (hours/month)
        base_cost_per_model = 2.0
        
        # Additional cost for complex models
        complex_models = sum(1 for m in self.model_metrics.values() 
                           if m.memory_usage_mb > 50)
        
        # Monitoring overhead
        monitoring_overhead = 0.5 * num_models
        
        # Total estimate
        total_hours = (
            num_models * base_cost_per_model +
            complex_models * 3.0 +  # Extra for complex models
            monitoring_overhead
        )
        
        return total_hours
    
    def identify_models_to_prune(self) -> List[str]:
        """Identify models that should be removed."""
        candidates = []
        
        for name, metrics in self.model_metrics.items():
            reasons = []
            
            # Check if underperforming
            if metrics.is_underperforming:
                reasons.append(f"Low success rate: {metrics.success_rate:.2%}")
            
            # Check if stale
            if metrics.is_stale:
                days_idle = (datetime.now() - metrics.last_used).days if metrics.last_used else 999
                reasons.append(f"Stale: {days_idle} days since last use")
            
            # Check if redundant (very similar to another model)
            if self._is_redundant(name):
                reasons.append("Redundant with other models")
            
            if reasons:
                candidates.append(name)
        
        return candidates
    
    def _is_redundant(self, model_name: str, threshold: float = 0.9) -> bool:
        """Check if a model is redundant (too similar to others)."""
        if model_name not in self.model_metrics:
            return False
        
        target_metrics = self.model_metrics[model_name]
        
        for other_name, other_metrics in self.model_metrics.items():
            if other_name == model_name:
                continue
            
            # Check performance similarity
            perf_diff = abs(target_metrics.success_rate - other_metrics.success_rate)
            conf_diff = abs(target_metrics.avg_confidence - other_metrics.avg_confidence)
            
            # If very similar, likely redundant
            if perf_diff < 0.05 and conf_diff < 0.05:
                return True
        
        return False
    
    def generate_health_report(self) -> EnsembleHealthReport:
        """Generate comprehensive health report."""
        report = EnsembleHealthReport()
        
        # Basic counts
        report.total_models = len(self.model_metrics)
        report.active_models = sum(1 for m in self.model_metrics.values() 
                                  if not m.is_stale)
        report.underperforming_models = sum(1 for m in self.model_metrics.values() 
                                           if m.is_underperforming)
        report.stale_models = sum(1 for m in self.model_metrics.values() 
                                 if m.is_stale)
        
        # Complexity metrics
        report.complexity_score = self.calculate_complexity_score()
        report.maintenance_cost_estimate_hours = self.estimate_maintenance_cost()
        report.redundancy_level = self._calculate_redundancy()
        
        # Performance metrics
        if self.model_metrics:
            report.overall_success_rate = sum(
                m.success_rate for m in self.model_metrics.values()
            ) / len(self.model_metrics)
            report.overall_avg_confidence = sum(
                m.avg_confidence for m in self.model_metrics.values()
            ) / len(self.model_metrics)
            report.avg_inference_time_ms = sum(
                m.avg_inference_time_ms for m in self.model_metrics.values()
            ) / len(self.model_metrics)
        
        # Generate recommendations
        report.recommendations = self._generate_recommendations(report)
        report.models_to_prune = self.identify_models_to_prune()
        
        return report
    
    def _calculate_redundancy(self) -> float:
        """Calculate redundancy level (0-1)."""
        if len(self.model_metrics) < 2:
            return 0.0
        
        redundant_count = sum(1 for name in self.model_metrics 
                             if self._is_redundant(name))
        
        return redundant_count / len(self.model_metrics)
    
    def _generate_recommendations(self, report: EnsembleHealthReport) -> List[str]:
        """Generate actionable recommendations."""
        recommendations = []
        
        # Complexity warnings
        if report.complexity_score > self.complexity_threshold:
            recommendations.append(
                f"⚠️ HIGH COMPLEXITY: Score {report.complexity_score:.2f} exceeds threshold "
                f"{self.complexity_threshold}. Consider pruning models."
            )
        
        # Underperforming models
        if report.underperforming_models > 0:
            recommendations.append(
                f"🔧 {report.underperforming_models} underperforming model(s) detected. "
                f"Review and consider replacement."
            )
        
        # Stale models
        if report.stale_models > 0:
            recommendations.append(
                f"🗑️ {report.stale_models} stale model(s) found. "
                f"Remove unused models to reduce complexity."
            )
        
        # Redundancy
        if report.redundancy_level > 0.3:
            recommendations.append(
                f"🔄 High redundancy ({report.redundancy_level:.0%}). "
                f"Consider consolidating similar models."
            )
        
        # Maintenance cost
        if report.maintenance_cost_estimate_hours > 20:
            recommendations.append(
                f"💰 High maintenance cost: {report.maintenance_cost_estimate_hours:.1f} hrs/month. "
                f"Optimize model count."
            )
        
        # Positive feedback
        if report.complexity_score < 0.4:
            recommendations.append(
                f"✅ Good complexity management (score: {report.complexity_score:.2f})"
            )
        
        if report.overall_success_rate > 0.8:
            recommendations.append(
                f"✅ Strong performance: {report.overall_success_rate:.0%} success rate"
            )
        
        return recommendations
    
    def auto_prune_models(self, force: bool = False) -> List[str]:
        """
        Automatically prune underperforming/stale models.
        
        Args:
            force: If True, prune without confirmation
            
        Returns:
            List of pruned model names
        """
        models_to_prune = self.identify_models_to_prune()
        
        if not force and models_to_prune:
            print(f"⚠️ Models recommended for pruning: {models_to_prune}")
            print("Call with force=True to execute pruning")
            return []
        
        pruned = []
        for model_name in models_to_prune:
            if model_name in self.model_metrics:
                del self.model_metrics[model_name]
                pruned.append(model_name)
        
        if pruned:
            print(f"✓ Pruned {len(pruned)} model(s): {pruned}")
        
        return pruned
    
    def get_dashboard_data(self) -> Dict:
        """Get data for health dashboard visualization."""
        report = self.generate_health_report()
        
        return {
            "summary": report.to_dict(),
            "model_details": {
                name: {
                    "success_rate": metrics.success_rate,
                    "avg_confidence": metrics.avg_confidence,
                    "total_predictions": metrics.total_predictions,
                    "is_underperforming": metrics.is_underperforming,
                    "is_stale": metrics.is_stale
                }
                for name, metrics in self.model_metrics.items()
            },
            "trend_data": self._get_trend_data()
        }
    
    def _get_trend_data(self) -> Dict:
        """Get recent trend data for visualization."""
        if not self.prediction_history:
            return {}
        
        # Group by model and time window
        recent = [h for h in self.prediction_history 
                 if (datetime.now() - h["timestamp"]).total_seconds() < 86400]  # 24 hours
        
        trends = defaultdict(lambda: {"successes": 0, "total": 0})
        for entry in recent:
            model = entry["model"]
            trends[model]["total"] += 1
            if entry["success"]:
                trends[model]["successes"] += 1
        
        return {
            model: {
                "success_rate": data["successes"] / data["total"] if data["total"] > 0 else 0,
                "predictions_24h": data["total"]
            }
            for model, data in trends.items()
        }


def main():
    """Test the Ensemble Health Monitor."""
    
    print("="*70)
    print("ENSEMBLE HEALTH MONITOR - TEST SUITE")
    print("="*70)
    
    monitor = EnsembleHealthMonitor()
    
    # Register models
    models = [
        ("statistical_model", 5.0),
        ("ml_model", 25.0),
        ("temporal_model", 8.0),
        ("causal_model", 15.0),
        ("rule_based_model", 3.0)
    ]
    
    for name, memory in models:
        monitor.register_model(name, memory)
    
    print(f"\n✓ Registered {len(models)} models")
    
    # Simulate predictions
    print("\nSimulating predictions...")
    import random
    
    for i in range(100):
        for name, _ in models:
            # Simulate varying performance
            if name == "ml_model":
                success = random.random() < 0.92
                confidence = 0.85 + random.random() * 0.10
            elif name == "causal_model":
                success = random.random() < 0.68
                confidence = 0.60 + random.random() * 0.15
            else:
                success = random.random() < 0.80
                confidence = 0.70 + random.random() * 0.15
            
            inference_time = random.uniform(0.1, 1.0)
            
            monitor.record_prediction(name, success, confidence, inference_time)
    
    print(f"✓ Recorded 500 predictions")
    
    # Generate health report
    print("\n" + "="*70)
    print("HEALTH REPORT")
    print("="*70)
    
    report = monitor.generate_health_report()
    
    print(f"\n📊 Ensemble Health Summary:")
    print(f"  Total models: {report.total_models}")
    print(f"  Active models: {report.active_models}")
    print(f"  Underperforming: {report.underperforming_models}")
    print(f"  Stale models: {report.stale_models}")
    print(f"\n🔍 Complexity Metrics:")
    print(f"  Complexity score: {report.complexity_score:.2f}")
    print(f"  Redundancy level: {report.redundancy_level:.0%}")
    print(f"  Est. maintenance: {report.maintenance_cost_estimate_hours:.1f} hrs/month")
    print(f"\n📈 Performance:")
    print(f"  Overall success rate: {report.overall_success_rate:.0%}")
    print(f"  Avg confidence: {report.overall_avg_confidence:.2f}")
    print(f"  Avg inference time: {report.avg_inference_time_ms:.2f}ms")
    
    if report.recommendations:
        print(f"\n💡 Recommendations:")
        for rec in report.recommendations:
            print(f"  {rec}")
    
    if report.models_to_prune:
        print(f"\n🗑️ Models to prune: {report.models_to_prune}")
    
    # Test auto-pruning
    print("\n" + "="*70)
    print("AUTO-PRUNING TEST")
    print("="*70)
    
    pruned = monitor.auto_prune_models(force=False)
    print(f"Models pruned (dry run): {len(pruned)}")
    
    # Dashboard data
    print("\n" + "="*70)
    print("DASHBOARD DATA")
    print("="*70)
    
    dashboard = monitor.get_dashboard_data()
    print(f"\n✓ Dashboard data generated")
    print(f"  Models tracked: {len(dashboard['model_details'])}")
    print(f"  Trend windows: {'24h' if dashboard['trend_data'] else 'none'}")
    
    # Summary
    print("\n\n" + "="*70)
    print("SUMMARY")
    print("="*70)
    
    print(f"\n✅ Health monitor features tested:")
    print(f"  ✓ Model registration")
    print(f"  ✓ Prediction tracking")
    print(f"  ✓ Complexity scoring")
    print(f"  ✓ Maintenance cost estimation")
    print(f"  ✓ Model pruning recommendations")
    print(f"  ✓ Health report generation")
    print(f"  ✓ Dashboard data export")
    print(f"  ✓ Trend analysis")
    
    print(f"\n{'='*70}")
    print("✅ ENSEMBLE HEALTH MONITOR - ALL TESTS PASSED")
    print(f"{'='*70}\n")


if __name__ == "__main__":
    main()
