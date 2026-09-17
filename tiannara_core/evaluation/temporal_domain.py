"""
Temporal Reasoning Domain - Task Generator

Generates temporal reasoning tasks including:
- Time series forecasting (linear, exponential, seasonal patterns)
- Event sequence prediction (temporal ordering, causality)
- Periodicity detection (cycles, rhythms)
- Temporal logic (before/after/during relationships)
"""

import random
import math
from typing import Dict, Any, List, Tuple


class TemporalTaskGenerator:
    """Generates temporal reasoning tasks with adaptive difficulty."""
    
    def __init__(self, seed: int = None):
        self.rng = random.Random(seed)
        
        # Task types
        self.task_types = [
            "time_series",      # Predict next values in sequence
            "event_sequence",   # Predict event ordering
            "periodicity",      # Detect cycles and periods
            "temporal_logic"    # Reason about temporal relationships
        ]
        
        # Adaptive difficulty tracking
        self.episode_count = 0
        self.difficulty_level = "easy"  # easy, medium, hard
        self.success_history = []
    
    def _get_difficulty_params(self, episode: int = None) -> Dict[str, Any]:
        """
        Adaptive difficulty based on episode progression and performance.
        
        Phases:
        - Episodes 0-30: Easy (short sequences, simple patterns)
        - Episodes 31-70: Medium (moderate complexity)
        - Episodes 71-100: Hard (long sequences, complex patterns)
        """
        if episode is not None:
            self.episode_count = episode
        
        # Base difficulty from episode progression
        if self.episode_count < 30:
            base_difficulty = "easy"
        elif self.episode_count < 70:
            base_difficulty = "medium"
        else:
            base_difficulty = "hard"
        
        # Adjust based on recent performance
        if len(self.success_history) >= 10:
            recent_success = sum(self.success_history[-10:]) / len(self.success_history[-10:])
            
            if recent_success > 0.7 and base_difficulty != "hard":
                if base_difficulty == "easy":
                    base_difficulty = "medium"
                elif base_difficulty == "medium":
                    base_difficulty = "hard"
            elif recent_success < 0.3 and base_difficulty != "easy":
                if base_difficulty == "hard":
                    base_difficulty = "medium"
                elif base_difficulty == "medium":
                    base_difficulty = "easy"
        
        self.difficulty_level = base_difficulty
        
        # Define parameters for each difficulty level
        params = {
            "easy": {
                "seq_length": (5, 8),           # Short sequences
                "pattern_complexity": "simple",  # Linear, constant
                "noise_level": 0.0,              # No noise
                "num_events": 3,                 # Few events
                "period_range": (2, 4)           # Short periods
            },
            "medium": {
                "seq_length": (8, 12),          # Medium sequences
                "pattern_complexity": "moderate", # Quadratic, exponential
                "noise_level": 0.1,              # Low noise
                "num_events": 5,                 # More events
                "period_range": (3, 6)           # Moderate periods
            },
            "hard": {
                "seq_length": (12, 16),         # Long sequences
                "pattern_complexity": "complex", # Seasonal, composite
                "noise_level": 0.2,              # Moderate noise
                "num_events": 7,                 # Many events
                "period_range": (4, 8)           # Longer periods
            }
        }
        
        return params[base_difficulty]
    
    def update_performance(self, success: bool):
        """Record task outcome for adaptive difficulty."""
        self.success_history.append(1 if success else 0)
        if len(self.success_history) > 20:
            self.success_history.pop(0)
    
    def generate_task(self, episode: int = None) -> Dict[str, Any]:
        """
        Generate a temporal reasoning task.
        
        Args:
            episode: Episode number for adaptive difficulty
            
        Returns:
            Dictionary with task specification
        """
        params = self._get_difficulty_params(episode)
        
        # Select task type
        task_type = self.rng.choice(self.task_types)
        
        # Generate specific task
        if task_type == "time_series":
            task = self._generate_time_series(params)
        elif task_type == "event_sequence":
            task = self._generate_event_sequence(params)
        elif task_type == "periodicity":
            task = self._generate_periodicity(params)
        else:  # temporal_logic
            task = self._generate_temporal_logic(params)
        
        task["type"] = task_type
        task["difficulty"] = self.difficulty_level
        task["episode"] = self.episode_count
        
        return task
    
    def _generate_time_series(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate time series forecasting task."""
        seq_length = self.rng.randint(*params["seq_length"])
        complexity = params["pattern_complexity"]
        noise_level = params["noise_level"]
        
        # Generate pattern
        if complexity == "simple":
            # Linear or constant
            pattern_type = self.rng.choice(["linear", "constant"])
            if pattern_type == "linear":
                slope = self.rng.uniform(-2, 2)
                intercept = self.rng.uniform(-5, 5)
                sequence = [intercept + slope * i for i in range(seq_length)]
                expected_next = intercept + slope * seq_length
                pattern_desc = f"linear (slope={slope:.2f})"
            else:  # constant
                value = self.rng.uniform(-10, 10)
                sequence = [value] * seq_length
                expected_next = value
                pattern_desc = "constant"
        
        elif complexity == "moderate":
            # Quadratic or exponential
            pattern_type = self.rng.choice(["quadratic", "exponential"])
            if pattern_type == "quadratic":
                a = self.rng.uniform(-1, 1)
                b = self.rng.uniform(-2, 2)
                c = self.rng.uniform(-5, 5)
                sequence = [a * i**2 + b * i + c for i in range(seq_length)]
                expected_next = a * seq_length**2 + b * seq_length + c
                pattern_desc = f"quadratic (a={a:.2f}, b={b:.2f})"
            else:  # exponential
                base = self.rng.uniform(1.1, 1.5)
                scale = self.rng.uniform(0.5, 2.0)
                sequence = [scale * (base ** i) for i in range(seq_length)]
                expected_next = scale * (base ** seq_length)
                pattern_desc = f"exponential (base={base:.2f})"
        
        else:  # complex
            # Seasonal or composite
            pattern_type = self.rng.choice(["seasonal", "composite"])
            if pattern_type == "seasonal":
                period = self.rng.randint(*params["period_range"])
                amplitude = self.rng.uniform(2, 5)
                trend = self.rng.uniform(-0.5, 0.5)
                sequence = [
                    trend * i + amplitude * math.sin(2 * math.pi * i / period)
                    for i in range(seq_length)
                ]
                expected_next = trend * seq_length + amplitude * math.sin(2 * math.pi * seq_length / period)
                pattern_desc = f"seasonal (period={period})"
            else:  # composite (linear + sinusoidal)
                slope = self.rng.uniform(-1, 1)
                amplitude = self.rng.uniform(1, 3)
                period = self.rng.randint(*params["period_range"])
                sequence = [
                    slope * i + amplitude * math.sin(2 * math.pi * i / period)
                    for i in range(seq_length)
                ]
                expected_next = slope * seq_length + amplitude * math.sin(2 * math.pi * seq_length / period)
                pattern_desc = f"composite (trend + period={period})"
        
        # Add noise
        if noise_level > 0:
            noisy_sequence = [x + self.rng.gauss(0, noise_level * abs(x) if x != 0 else noise_level) 
                            for x in sequence]
            sequence = noisy_sequence
        
        # Round for cleaner numbers
        sequence = [round(x, 2) for x in sequence]
        expected_next = round(expected_next, 2)
        
        return {
            "inputs": {
                "sequence": sequence,
                "length": len(sequence)
            },
            "expected_output": expected_next,
            "metadata": {
                "pattern_type": pattern_type,
                "pattern_description": pattern_desc,
                "noise_level": noise_level
            }
        }
    
    def _generate_event_sequence(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate event sequence prediction task."""
        num_events = params["num_events"]
        
        # Create events with temporal constraints
        events = [f"E{i+1}" for i in range(num_events)]
        
        # Generate valid ordering (some events must come before others)
        constraints = []
        ordering = list(range(num_events))
        self.rng.shuffle(ordering)
        
        # Add some ordering constraints
        num_constraints = min(num_events - 1, self.rng.randint(1, num_events // 2))
        for _ in range(num_constraints):
            i, j = self.rng.sample(range(num_events), 2)
            if ordering.index(i) < ordering.index(j):
                constraints.append((events[i], events[j]))
            else:
                constraints.append((events[j], events[i]))
        
        # Remove duplicates
        constraints = list(set(constraints))
        
        # Expected: complete valid ordering
        expected_ordering = [events[i] for i in ordering]
        
        return {
            "inputs": {
                "events": events,
                "constraints": constraints,
                "num_events": num_events
            },
            "expected_output": expected_ordering,
            "metadata": {
                "num_constraints": len(constraints)
            }
        }
    
    def _generate_periodicity(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate periodicity detection task."""
        seq_length = self.rng.randint(*params["seq_length"])
        period = self.rng.randint(*params["period_range"])
        
        # Generate periodic sequence
        base_pattern = [self.rng.uniform(-5, 5) for _ in range(period)]
        sequence = []
        for i in range(seq_length):
            sequence.append(base_pattern[i % period])
        
        # Add slight variation to make it realistic
        sequence = [x + self.rng.gauss(0, 0.1) for x in sequence]
        sequence = [round(x, 2) for x in sequence]
        
        return {
            "inputs": {
                "sequence": sequence,
                "length": len(sequence)
            },
            "expected_output": {
                "period": period,
                "next_values": [round(base_pattern[(seq_length + i) % period] + self.rng.gauss(0, 0.1), 2) 
                               for i in range(period)]
            },
            "metadata": {
                "true_period": period,
                "pattern_length": len(base_pattern)
            }
        }
    
    def _generate_temporal_logic(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate temporal logic reasoning task."""
        num_events = params["num_events"]
        events = [f"E{i+1}" for i in range(num_events)]
        
        # Generate temporal relationships
        relationships = []
        for i in range(num_events):
            for j in range(i+1, num_events):
                rel_type = self.rng.choice(["before", "after", "during", "overlaps"])
                if rel_type == "before":
                    relationships.append({"event1": events[i], "event2": events[j], "relation": "before"})
                elif rel_type == "after":
                    relationships.append({"event1": events[i], "event2": events[j], "relation": "after"})
                elif rel_type == "during":
                    relationships.append({"event1": events[i], "event2": events[j], "relation": "during"})
                else:  # overlaps
                    relationships.append({"event1": events[i], "event2": events[j], "relation": "overlaps"})
        
        # Query: determine relationship between two specific events
        query_i, query_j = self.rng.sample(range(num_events), 2)
        query_event1, query_event2 = events[query_i], events[query_j]
        
        # Find expected answer from relationships
        expected_relation = None
        for rel in relationships:
            if (rel["event1"] == query_event1 and rel["event2"] == query_event2):
                expected_relation = rel["relation"]
                break
            elif (rel["event1"] == query_event2 and rel["event2"] == query_event1):
                # Inverse relationship
                inverse_map = {"before": "after", "after": "before", "during": "contains", "overlaps": "overlaps"}
                expected_relation = inverse_map.get(rel["relation"], "unknown")
                break
        
        if expected_relation is None:
            expected_relation = "unknown"
        
        return {
            "inputs": {
                "events": events,
                "relationships": relationships,
                "query": {
                    "event1": query_event1,
                    "event2": query_event2
                }
            },
            "expected_output": expected_relation,
            "metadata": {
                "num_relationships": len(relationships)
            }
        }
    
    def verify_solution(self, task: Dict[str, Any], solution: Any) -> float:
        """
        Verify correctness of solution.
        
        Returns:
            Correctness score (0.0 to 1.0)
        """
        task_type = task["type"]
        expected = task["expected_output"]
        
        if task_type == "time_series":
            # Check if predicted value is close to expected
            if isinstance(solution, (int, float)):
                error = abs(solution - expected)
                tolerance = max(abs(expected) * 0.1, 1.0)  # 10% tolerance or 1.0
                return max(0.0, 1.0 - error / tolerance)
            return 0.0
        
        elif task_type == "event_sequence":
            # Check if ordering satisfies all constraints
            if not isinstance(solution, list) or len(solution) != len(expected):
                return 0.0
            
            # Check if all events are present
            if set(solution) != set(expected):
                return 0.0
            
            # Check constraints
            constraints = task["inputs"]["constraints"]
            satisfied = 0
            for constraint in constraints:
                e1, e2 = constraint
                if solution.index(e1) < solution.index(e2):
                    satisfied += 1
            
            return satisfied / len(constraints) if constraints else 1.0
        
        elif task_type == "periodicity":
            # Check if detected period matches
            if isinstance(solution, dict) and "period" in solution:
                if solution["period"] == expected["period"]:
                    return 1.0
                else:
                    # Partial credit for close periods
                    error = abs(solution["period"] - expected["period"])
                    return max(0.0, 1.0 - error / expected["period"])
            return 0.0
        
        elif task_type == "temporal_logic":
            # Exact match for relationship
            if solution == expected:
                return 1.0
            return 0.0
        
        return 0.0
