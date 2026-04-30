"""
Stability Checking - Reliability signal for system behavior.

Measures consistency across multiple execution runs.
High stability = consistent behavior
Low stability = chaotic/unpredictable system
"""


class StabilityChecker:
    """Evaluates stability of outputs across repeated executions."""

    def evaluate(self, outputs: list) -> float:
        """
        Evaluate stability based on output consistency.
        
        Args:
            outputs: List of output values from multiple runs
            
        Returns:
            Stability score (1.0 = perfectly stable, 0.0 = completely unstable)
        """
        if not outputs:
            return 0.0

        # Count unique outputs vs total outputs
        unique = len(set(map(str, outputs)))
        total = len(outputs)

        # Stability is inverse of variance
        return 1.0 - (unique / total)

    def evaluate_with_threshold(self, outputs: list, threshold: float = 0.5) -> dict:
        """
        Evaluate stability with detailed diagnostics.
        
        Args:
            outputs: List of output values from multiple runs
            threshold: Minimum acceptable stability score
            
        Returns:
            Dictionary with stability score and diagnostic info
        """
        stability = self.evaluate(outputs)
        
        return {
            "stability": stability,
            "is_stable": stability >= threshold,
            "unique_outputs": len(set(map(str, outputs))),
            "total_runs": len(outputs),
        }
