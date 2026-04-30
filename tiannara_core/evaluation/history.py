"""
Evaluation History - Learning memory for trend analysis.

Stores evaluation records and provides analytics for detecting
improvement trends, best performances, and learning dynamics.
"""


class EvaluationHistory:
    """Maintains history of evaluations for learning signal analysis."""

    def __init__(self):
        """Initialize empty evaluation history."""
        self.records = []

    def log(self, entry: dict):
        """
        Log an evaluation record.
        
        Args:
            entry: Dictionary containing evaluation results with at least 'score' key
        """
        # Add timestamp if not present
        if "timestamp" not in entry:
            import time
            entry["timestamp"] = time.time()
        
        # Add episode ID if not present
        if "episode_id" not in entry:
            entry["episode_id"] = len(self.records)
            
        self.records.append(entry)

    def get_best(self) -> dict:
        """
        Get the highest-scoring evaluation record.
        
        Returns:
            Best record or None if no records exist
        """
        return max(self.records, key=lambda x: x.get("score", 0.0), default=None)

    def get_recent(self, n: int = 10) -> list:
        """
        Get the most recent n evaluation records.
        
        Args:
            n: Number of recent records to retrieve
            
        Returns:
            List of recent records (newest last)
        """
        return self.records[-n:]

    def improvement_rate(self) -> float:
        """
        Calculate overall improvement from first to last record.
        
        Returns:
            Score difference (positive = improvement, negative = degradation)
        """
        if len(self.records) < 2:
            return 0.0
        return self.records[-1].get("score", 0.0) - self.records[0].get("score", 0.0)

    def average_score(self, n: int = None) -> float:
        """
        Calculate average score over records.
        
        Args:
            n: Number of recent records to average (None = all records)
            
        Returns:
            Average score
        """
        records = self.records[-n:] if n else self.records
        if not records:
            return 0.0
        return sum(r.get("score", 0.0) for r in records) / len(records)

    def score_trend(self, window: int = 10) -> str:
        """
        Analyze recent score trend.
        
        Args:
            window: Number of recent records to analyze
            
        Returns:
            Trend description: 'improving', 'declining', 'stable', or 'insufficient_data'
        """
        if len(self.records) < window:
            return "insufficient_data"
        
        recent = self.records[-window:]
        scores = [r.get("score", 0.0) for r in recent]
        
        # Simple linear trend
        first_half = sum(scores[:len(scores)//2]) / (len(scores)//2)
        second_half = sum(scores[len(scores)//2:]) / (len(scores) - len(scores)//2)
        
        diff = second_half - first_half
        
        if diff > 0.05:
            return "improving"
        elif diff < -0.05:
            return "declining"
        else:
            return "stable"

    def get_statistics(self) -> dict:
        """
        Get comprehensive statistics about evaluation history.
        
        Returns:
            Dictionary with statistical summaries
        """
        if not self.records:
            return {
                "total_records": 0,
                "average_score": 0.0,
                "best_score": 0.0,
                "worst_score": 0.0,
                "improvement_rate": 0.0,
                "trend": "no_data",
            }
        
        scores = [r.get("score", 0.0) for r in self.records]
        
        return {
            "total_records": len(self.records),
            "average_score": sum(scores) / len(scores),
            "best_score": max(scores),
            "worst_score": min(scores),
            "improvement_rate": self.improvement_rate(),
            "trend": self.score_trend(),
        }

    def clear(self):
        """Clear all records (useful for domain changes)."""
        self.records = []
