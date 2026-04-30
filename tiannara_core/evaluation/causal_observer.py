"""
Causal Observation Engine - Tracks patterns in evaluation metrics.

Observes metric correlations and builds causal understanding of
which factors influence success.
"""

from typing import Dict, List, Any
from collections import defaultdict


class CausalObserver:
    """Tracks causal relationships between metrics and outcomes."""

    def __init__(self):
        """Initialize causal observer."""
        self.observations = []
        self.metric_correlations = defaultdict(list)
        self.success_patterns = defaultdict(lambda: {"count": 0, "total_score": 0.0})

    def observe(self, episode: int, metrics: Dict[str, float], score: float, 
                task_type: str, success: bool):
        """
        Record an observation for causal analysis.
        
        Args:
            episode: Episode number
            metrics: Evaluation metrics dictionary
            score: Final evaluation score
            task_type: Type of algorithm task
            success: Whether the solution was correct
        """
        observation = {
            "episode": episode,
            "metrics": metrics.copy(),
            "score": score,
            "task_type": task_type,
            "success": success,
        }
        
        self.observations.append(observation)
        
        # Track patterns by task type
        pattern_key = task_type
        self.success_patterns[pattern_key]["count"] += 1
        self.success_patterns[pattern_key]["total_score"] += score
        
        # Track metric correlations
        for metric_name, metric_value in metrics.items():
            self.metric_correlations[metric_name].append({
                "value": metric_value,
                "score": score,
                "success": success
            })

    def get_task_performance(self) -> Dict[str, Dict[str, float]]:
        """
        Get performance statistics by task type.
        
        Returns:
            Dictionary mapping task types to performance stats
        """
        result = {}
        
        for task_type, stats in self.success_patterns.items():
            if stats["count"] > 0:
                result[task_type] = {
                    "count": stats["count"],
                    "avg_score": stats["total_score"] / stats["count"]
                }
        
        return result

    def get_metric_insights(self) -> Dict[str, Dict[str, float]]:
        """
        Analyze which metrics correlate with high scores.
        
        Returns:
            Dictionary with metric correlation insights
        """
        insights = {}
        
        for metric_name, observations in self.metric_correlations.items():
            if len(observations) < 5:
                continue
            
            # Calculate correlation with score
            values = [obs["value"] for obs in observations]
            scores = [obs["score"] for obs in observations]
            
            # Simple correlation calculation
            if len(values) >= 2:
                avg_val = sum(values) / len(values)
                avg_score = sum(scores) / len(scores)
                
                numerator = sum((v - avg_val) * (s - avg_score) 
                              for v, s in zip(values, scores))
                denom_val = sum((v - avg_val) ** 2 for v in values) ** 0.5
                denom_score = sum((s - avg_score) ** 2 for s in scores) ** 0.5
                
                if denom_val > 0 and denom_score > 0:
                    correlation = numerator / (denom_val * denom_score)
                else:
                    correlation = 0.0
                
                insights[metric_name] = {
                    "correlation_with_score": correlation,
                    "avg_value": avg_val,
                    "num_observations": len(observations)
                }
        
        return insights

    def get_causal_summary(self) -> Dict[str, Any]:
        """
        Get comprehensive causal analysis summary.
        
        Returns:
            Dictionary with causal insights
        """
        if not self.observations:
            return {"status": "no_data"}
        
        total = len(self.observations)
        successful = sum(1 for obs in self.observations if obs["success"])
        
        return {
            "total_observations": total,
            "success_rate": successful / total if total > 0 else 0.0,
            "task_performance": self.get_task_performance(),
            "metric_insights": self.get_metric_insights(),
            "trend": self._analyze_trend()
        }

    def _analyze_trend(self) -> str:
        """Analyze overall trend in observations."""
        if len(self.observations) < 10:
            return "insufficient_data"
        
        # Compare first half vs second half
        mid = len(self.observations) // 2
        first_half_scores = [obs["score"] for obs in self.observations[:mid]]
        second_half_scores = [obs["score"] for obs in self.observations[mid:]]
        
        avg_first = sum(first_half_scores) / len(first_half_scores)
        avg_second = sum(second_half_scores) / len(second_half_scores)
        
        diff = avg_second - avg_first
        
        if diff > 0.05:
            return "improving"
        elif diff < -0.05:
            return "declining"
        else:
            return "stable"

    def get_recent_observations(self, n: int = 10) -> List[Dict[str, Any]]:
        """Get most recent observations."""
        return self.observations[-n:]
