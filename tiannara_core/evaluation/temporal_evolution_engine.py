"""
Temporal Reasoning Domain - Evolution Engine

Implements mutation operators for temporal reasoning tasks:
- Pattern transformation (linear → quadratic, etc.)
- Sequence manipulation (extend, truncate, interpolate)
- Noise injection and removal
- Period detection refinement
"""

import random
import math
from typing import Dict, Any, Optional, Callable, List
from tiannara_core.evaluation.temporal_domain import TemporalTaskGenerator


class TemporalEvolver:
    """Evolves temporal reasoning solutions through mutation."""
    
    def __init__(self, seed: int = None):
        self.rng = random.Random(seed)
        
        # Mutation operators
        self.mutation_operators = [
            "pattern_transform",      # Change pattern type
            "sequence_extend",        # Extend sequence prediction
            "noise_adjustment",       # Add/remove noise
            "period_refinement",      # Adjust detected period
            "constraint_relaxation",  # Relax temporal constraints
            "interpolation"           # Interpolate missing values
        ]
        
        # Operator statistics
        self.operator_stats = {op: {"success": 0, "total": 0} for op in self.mutation_operators}
    
    def create_variant(self, task: Dict[str, Any], episode: int = 0,
                      external_skills: Optional[List] = None) -> Optional[Callable]:
        """
        Create a mutated variant for solving the temporal task.
        
        Args:
            task: Task specification from TemporalTaskGenerator
            episode: Episode number (for adaptive mutation)
            external_skills: Skills from other domains for transfer
            
        Returns:
            Callable that attempts to solve the task, or None if creation fails
        """
        task_type = task.get("type")
        
        # Select mutation operator based on task type
        if task_type == "time_series":
            operator = self.rng.choice(["pattern_transform", "sequence_extend", "noise_adjustment"])
        elif task_type == "event_sequence":
            operator = self.rng.choice(["constraint_relaxation", "interpolation"])
        elif task_type == "periodicity":
            operator = self.rng.choice(["period_refinement", "pattern_transform"])
        else:  # temporal_logic
            operator = self.rng.choice(["constraint_relaxation", "interpolation"])
        
        # Apply external skills if available (cross-domain transfer)
        if external_skills:
            transferred_solution = self._apply_external_skills(task, external_skills)
            if transferred_solution:
                return transferred_solution
        
        # Create base solution strategy
        if task_type == "time_series":
            base_strategy = self._create_time_series_strategy(task)
        elif task_type == "event_sequence":
            base_strategy = self._create_event_sequence_strategy(task)
        elif task_type == "periodicity":
            base_strategy = self._create_periodicity_strategy(task)
        else:  # temporal_logic
            base_strategy = self._create_temporal_logic_strategy(task)
        
        if not base_strategy:
            return None
        
        # Apply mutation
        mutated_strategy = self._apply_mutation(base_strategy, operator, task)
        
        return mutated_strategy
    
    def _apply_external_skills(self, task: Dict[str, Any], 
                              external_skills: List) -> Optional[Callable]:
        """
        Apply skills from other domains to solve temporal task.
        
        Cross-domain transfer opportunities:
        - Algorithm domain: Pattern recognition, mathematical operations
        - Logic domain: Constraint satisfaction, deduction
        - Causal domain: Understanding dependencies
        """
        for skill in external_skills:
            skill_type = skill.get("skill_type", "").lower()
            
            # Transfer pattern recognition from algorithm domain
            if skill_type in ["pattern_recognition", "sequence_analysis"]:
                if task["type"] == "time_series":
                    return self._create_pattern_based_solver(task, skill)
            
            # Transfer constraint solving from logic domain
            elif skill_type in ["constraint_satisfaction", "logical_deduction"]:
                if task["type"] in ["event_sequence", "temporal_logic"]:
                    return self._create_constraint_solver(task, skill)
            
            # Transfer dependency analysis from causal domain
            elif skill_type in ["causal_inference", "dependency_analysis"]:
                if task["type"] in ["event_sequence", "temporal_logic"]:
                    return self._create_dependency_solver(task, skill)
        
        return None
    
    def _create_pattern_based_solver(self, task: Dict[str, Any], 
                                    skill: Dict[str, Any]) -> Callable:
        """Create solver using transferred pattern recognition skill."""
        sequence = task["inputs"]["sequence"]
        
        def solver(**kwargs):
            # Use skill's pattern detection method
            if len(sequence) < 2:
                return sequence[-1] if sequence else 0
            
            # Detect trend using skill
            diffs = [sequence[i+1] - sequence[i] for i in range(len(sequence)-1)]
            avg_diff = sum(diffs) / len(diffs)
            
            # Extrapolate
            return sequence[-1] + avg_diff
        
        return solver
    
    def _create_constraint_solver(self, task: Dict[str, Any], 
                                 skill: Dict[str, Any]) -> Callable:
        """Create solver using transferred constraint satisfaction skill."""
        constraints = task["inputs"].get("constraints", [])
        events = task["inputs"].get("events", [])
        
        def solver(**kwargs):
            # Topological sort based on constraints
            if not constraints:
                return events
            
            # Build dependency graph
            graph = {e: [] for e in events}
            for c1, c2 in constraints:
                if c1 in graph and c2 in graph:
                    graph[c1].append(c2)
            
            # Simple topological sort
            visited = set()
            order = []
            
            def dfs(node):
                if node in visited:
                    return
                visited.add(node)
                for neighbor in graph.get(node, []):
                    dfs(neighbor)
                order.append(node)
            
            for event in events:
                dfs(event)
            
            return list(reversed(order))
        
        return solver
    
    def _create_dependency_solver(self, task: Dict[str, Any], 
                                 skill: Dict[str, Any]) -> Callable:
        """Create solver using transferred causal inference skill."""
        relationships = task["inputs"].get("relationships", [])
        query = task["inputs"].get("query", {})
        
        def solver(**kwargs):
            event1 = query.get("event1")
            event2 = query.get("event2")
            
            # Search for direct relationship
            for rel in relationships:
                if rel["event1"] == event1 and rel["event2"] == event2:
                    return rel["relation"]
                elif rel["event1"] == event2 and rel["event2"] == event1:
                    # Inverse relationship
                    inverse_map = {
                        "before": "after", 
                        "after": "before", 
                        "during": "contains", 
                        "overlaps": "overlaps"
                    }
                    return inverse_map.get(rel["relation"], "unknown")
            
            return "unknown"
        
        return solver
    
    def _create_time_series_strategy(self, task: Dict[str, Any]) -> Optional[Callable]:
        """Create base strategy for time series forecasting."""
        sequence = task["inputs"]["sequence"]
        
        if len(sequence) < 2:
            return None
        
        def solver(**kwargs):
            # Simple linear extrapolation
            if len(sequence) >= 2:
                diff = sequence[-1] - sequence[-2]
                return sequence[-1] + diff
            return sequence[-1] if sequence else 0
        
        return solver
    
    def _create_event_sequence_strategy(self, task: Dict[str, Any]) -> Optional[Callable]:
        """Create base strategy for event sequence ordering."""
        events = task["inputs"].get("events", [])
        constraints = task["inputs"].get("constraints", [])
        
        def solver(**kwargs):
            # Return events in order, respecting constraints
            if not constraints:
                return events
            
            # Simple greedy approach: satisfy as many constraints as possible
            ordering = events[:]
            for c1, c2 in constraints:
                if c1 in ordering and c2 in ordering:
                    idx1, idx2 = ordering.index(c1), ordering.index(c2)
                    if idx1 > idx2:
                        # Swap to satisfy constraint
                        ordering[idx1], ordering[idx2] = ordering[idx2], ordering[idx1]
            
            return ordering
        
        return solver
    
    def _create_periodicity_strategy(self, task: Dict[str, Any]) -> Optional[Callable]:
        """Create base strategy for periodicity detection."""
        sequence = task["inputs"]["sequence"]
        
        if len(sequence) < 4:
            return None
        
        def solver(**kwargs):
            # Try different periods and find best match
            best_period = 1
            best_score = float('inf')
            
            for period in range(1, len(sequence) // 2 + 1):
                # Calculate variance within each phase
                phases = [[] for _ in range(period)]
                for i, val in enumerate(sequence):
                    phases[i % period].append(val)
                
                # Score: average variance within phases
                score = sum(
                    sum((x - sum(phase)/len(phase))**2 for x in phase) / len(phase)
                    for phase in phases if phase
                ) / period
                
                if score < best_score:
                    best_score = score
                    best_period = period
            
            return {"period": best_period}
        
        return solver
    
    def _create_temporal_logic_strategy(self, task: Dict[str, Any]) -> Optional[Callable]:
        """Create base strategy for temporal logic reasoning."""
        relationships = task["inputs"].get("relationships", [])
        query = task["inputs"].get("query", {})
        
        def solver(**kwargs):
            event1 = query.get("event1")
            event2 = query.get("event2")
            
            # Direct lookup
            for rel in relationships:
                if rel["event1"] == event1 and rel["event2"] == event2:
                    return rel["relation"]
            
            return "unknown"
        
        return solver
    
    def _apply_mutation(self, base_strategy: Callable, operator: str, 
                       task: Dict[str, Any]) -> Callable:
        """Apply mutation operator to base strategy."""
        
        if operator == "pattern_transform":
            return self._mutate_pattern_transform(base_strategy, task)
        elif operator == "sequence_extend":
            return self._mutate_sequence_extend(base_strategy, task)
        elif operator == "noise_adjustment":
            return self._mutate_noise_adjustment(base_strategy, task)
        elif operator == "period_refinement":
            return self._mutate_period_refinement(base_strategy, task)
        elif operator == "constraint_relaxation":
            return self._mutate_constraint_relaxation(base_strategy, task)
        elif operator == "interpolation":
            return self._mutate_interpolation(base_strategy, task)
        else:
            return base_strategy
    
    def _mutate_pattern_transform(self, base_strategy: Callable, 
                                  task: Dict[str, Any]) -> Callable:
        """Transform pattern detection strategy."""
        def mutated_solver(**kwargs):
            try:
                # Try multiple pattern types and select best
                base_pred = base_strategy(**kwargs)
                
                # Also try quadratic fit
                sequence = task["inputs"]["sequence"]
                if len(sequence) >= 3:
                    # Simple quadratic approximation
                    n = len(sequence)
                    x_mean = (n - 1) / 2
                    y_mean = sum(sequence) / n
                    
                    # Calculate coefficients (simplified)
                    numerator = sum((i - x_mean) * (sequence[i] - y_mean) for i in range(n))
                    denominator = sum((i - x_mean)**2 for i in range(n))
                    
                    if denominator != 0:
                        slope = numerator / denominator
                        quad_pred = sequence[-1] + slope
                        
                        # Blend predictions
                        return 0.7 * base_pred + 0.3 * quad_pred
                
                return base_pred
            except Exception:
                return base_strategy(**kwargs)
        
        return mutated_solver
    
    def _mutate_sequence_extend(self, base_strategy: Callable, 
                               task: Dict[str, Any]) -> Callable:
        """Extend sequence prediction with longer horizon."""
        def mutated_solver(**kwargs):
            base_pred = base_strategy(**kwargs)
            
            # Predict multiple steps ahead
            sequence = task["inputs"]["sequence"]
            if len(sequence) >= 2:
                # Calculate trend over last few points
                window = min(3, len(sequence))
                recent = sequence[-window:]
                diffs = [recent[i+1] - recent[i] for i in range(len(recent)-1)]
                avg_diff = sum(diffs) / len(diffs)
                
                # Accelerating trend
                if len(diffs) >= 2:
                    acceleration = diffs[-1] - diffs[0]
                    return base_pred + acceleration * 0.5
            
            return base_pred
        
        return mutated_solver
    
    def _mutate_noise_adjustment(self, base_strategy: Callable, 
                                task: Dict[str, Any]) -> Callable:
        """Adjust noise handling in prediction."""
        def mutated_solver(**kwargs):
            sequence = task["inputs"]["sequence"]
            
            # Smooth sequence before prediction
            if len(sequence) >= 3:
                # Moving average smoothing
                smoothed = []
                window = 3
                for i in range(len(sequence)):
                    start = max(0, i - window // 2)
                    end = min(len(sequence), i + window // 2 + 1)
                    smoothed.append(sum(sequence[start:end]) / (end - start))
                
                # Create modified task with smoothed sequence
                modified_task = task.copy()
                modified_task["inputs"] = task["inputs"].copy()
                modified_task["inputs"]["sequence"] = smoothed
                
                return base_strategy(**modified_task)
            
            return base_strategy(**kwargs)
        
        return mutated_solver
    
    def _mutate_period_refinement(self, base_strategy: Callable, 
                                 task: Dict[str, Any]) -> Callable:
        """Refine period detection with better scoring."""
        def mutated_solver(**kwargs):
            result = base_strategy(**kwargs)
            
            if isinstance(result, dict) and "period" in result:
                period = result["period"]
                sequence = task["inputs"]["sequence"]
                
                # Try neighboring periods
                best_period = period
                best_score = float('inf')
                
                for test_period in range(max(1, period-2), period+3):
                    if test_period >= len(sequence) // 2:
                        continue
                    
                    # Autocorrelation score
                    score = 0
                    for lag in range(test_period):
                        if lag + test_period < len(sequence):
                            score += abs(sequence[lag] - sequence[lag + test_period])
                    
                    if score < best_score:
                        best_score = score
                        best_period = test_period
                
                return {"period": best_period}
            
            return result
        
        return mutated_solver
    
    def _mutate_constraint_relaxation(self, base_strategy: Callable, 
                                     task: Dict[str, Any]) -> Callable:
        """Relax constraints for more flexible solutions."""
        def mutated_solver(**kwargs):
            try:
                return base_strategy(**kwargs)
            except Exception:
                # If strict constraint satisfaction fails, return any valid ordering
                events = task["inputs"].get("events", [])
                return events
        
        return mutated_solver
    
    def _mutate_interpolation(self, base_strategy: Callable, 
                             task: Dict[str, Any]) -> Callable:
        """Add interpolation for missing or uncertain values."""
        def mutated_solver(**kwargs):
            result = base_strategy(**kwargs)
            
            # If result is uncertain, use interpolation
            if isinstance(result, (int, float)):
                sequence = task["inputs"]["sequence"]
                if len(sequence) >= 2:
                    # Linear interpolation between last two points
                    interp = 2 * sequence[-1] - sequence[-2]
                    # Blend with base prediction
                    return 0.8 * result + 0.2 * interp
            
            return result
        
        return mutated_solver
    
    def update_operator_stats(self, operator: str, success: bool):
        """Track operator performance for adaptive selection."""
        if operator in self.operator_stats:
            self.operator_stats[operator]["total"] += 1
            if success:
                self.operator_stats[operator]["success"] += 1
    
    def get_best_operators(self, top_k: int = 3) -> List[str]:
        """Get top-performing operators based on success rate."""
        operators_with_rates = []
        for op, stats in self.operator_stats.items():
            if stats["total"] > 0:
                rate = stats["success"] / stats["total"]
                operators_with_rates.append((op, rate))
            else:
                operators_with_rates.append((op, 0.5))  # Default prior
        
        # Sort by success rate
        operators_with_rates.sort(key=lambda x: x[1], reverse=True)
        return [op for op, _ in operators_with_rates[:top_k]]
