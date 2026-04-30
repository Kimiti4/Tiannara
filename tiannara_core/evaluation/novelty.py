"""
Novelty Tracking - Intelligence signal to prevent system stagnation.

Tracks novelty of execution patterns using vector distance metrics.
Feed this with trace embeddings, output features, or causal vectors.
"""

import numpy as np


class NoveltyTracker:
    """
    Tracks novelty of feature vectors over time.
    
    High novelty indicates new/unexplored behavior patterns.
    Low novelty indicates convergence or repetitive behavior.
    """

    def __init__(self):
        """Initialize novelty tracker with empty history."""
        self.history = []

    def compute_novelty(self, vector: list) -> float:
        """
        Compute novelty score for a given feature vector.
        
        Args:
            vector: Feature vector representing current state/behavior
            
        Returns:
            Novelty score (higher = more novel, typically 0.0-1.0+)
        """
        if not self.history:
            # First observation is maximally novel
            self.history.append(vector)
            return 1.0

        # Calculate average distance from all historical vectors
        distances = [
            np.linalg.norm(np.array(vector) - np.array(h))
            for h in self.history
        ]

        novelty = float(np.mean(distances))
        self.history.append(vector)

        return novelty

    def reset(self):
        """Clear novelty history (useful for domain changes)."""
        self.history = []

    def get_history_size(self) -> int:
        """Get number of vectors tracked."""
        return len(self.history)
