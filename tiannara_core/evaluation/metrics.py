"""
Core Measurement Layer - Extracts raw signals from execution results.

This module provides fundamental metrics without weighting, serving as
the foundation for the evaluation system.
"""


class Metrics:
    """Extracts raw measurement signals from execution results."""

    def correctness(self, result: dict) -> float:
        """
        Measure correctness of a result.
        
        Args:
            result: Dictionary containing execution result with 'success' key
            
        Returns:
            1.0 if successful, 0.0 otherwise
        """
        return 1.0 if result.get("success") else 0.0

    def runtime(self, start_time: float, end_time: float) -> float:
        """
        Calculate execution runtime.
        
        Args:
            start_time: Start timestamp
            end_time: End timestamp
            
        Returns:
            Runtime in seconds (non-negative)
        """
        return max(0.0, end_time - start_time)

    def error_rate(self, result: dict) -> float:
        """
        Determine if an error occurred.
        
        Args:
            result: Dictionary containing execution result with 'error' key
            
        Returns:
            1.0 if error occurred, 0.0 otherwise
        """
        return 1.0 if result.get("error") else 0.0

    def output_size(self, result: dict) -> int:
        """
        Measure output size in characters.
        
        Args:
            result: Dictionary containing execution result with 'output' key
            
        Returns:
            Length of output string
        """
        output = str(result.get("output", ""))
        return len(output)

    def consistency(self, outputs: list) -> float:
        """
        Measure variance across repeated runs.
        
        Args:
            outputs: List of output values from multiple runs
            
        Returns:
            Consistency score (lower is more consistent)
        """
        if not outputs:
            return 0.0
        unique_outputs = len(set(map(str, outputs)))
        total_outputs = len(outputs)
        return unique_outputs / total_outputs
