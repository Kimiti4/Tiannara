"""
RECURSIVE GOVERNOR - Bounded Metacognition Controller

Purpose: Prevent recursive reasoning collapse by intelligently terminating
deep reflection chains based on novelty delta, coherence score, and depth limits.

Based on audit.md recommendation for bounded metacognition infrastructure.
"""

import time
from typing import Dict, Any, Optional, List
from dataclasses import dataclass, field


@dataclass
class RecursionState:
    """Tracks the state of a recursive reasoning chain."""
    depth: int = 0
    max_depth: int = 10
    novelty_history: List[float] = field(default_factory=list)
    coherence_history: List[float] = field(default_factory=list)
    start_time: float = field(default_factory=time.time)
    termination_reason: Optional[str] = None
    
    @property
    def elapsed_time(self) -> float:
        return time.time() - self.start_time
    
    @property
    def avg_novelty(self) -> float:
        if not self.novelty_history:
            return 1.0
        return sum(self.novelty_history[-5:]) / len(self.novelty_history[-5:])
    
    @property
    def avg_coherence(self) -> float:
        if not self.coherence_history:
            return 1.0
        return sum(self.coherence_history[-5:]) / len(self.coherence_history[-5:])
    
    @property
    def novelty_delta(self) -> float:
        if len(self.novelty_history) < 2:
            return 1.0
        recent = self.novelty_history[-3:]
        return max(recent) - min(recent)


class RecursiveGovernor:
    """
    Controls recursive metacognitive processes to prevent:
    - Infinite loops
    - Abstraction drift
    - Context fragmentation
    - Confidence inflation
    
    Implements bounded metacognition as recommended by audit.md.
    """
    
    def __init__(
        self,
        max_depth: int = 10,
        novelty_threshold: float = 0.02,
        coherence_minimum: float = 0.6,
        time_limit_seconds: float = 30.0,
        diminishing_returns_factor: float = 0.3
    ):
        """
        Initialize recursive governor with safety parameters.
        
        Args:
            max_depth: Maximum recursion depth before forced termination
            novelty_threshold: Minimum novelty delta to continue recursion
            coherence_minimum: Minimum coherence score to maintain trust
            time_limit_seconds: Wall-clock time limit for recursion chain
            diminishing_returns_factor: Threshold where improvement per step becomes negligible
        """
        self.max_depth = max_depth
        self.novelty_threshold = novelty_threshold
        self.coherence_minimum = coherence_minimum
        self.time_limit_seconds = time_limit_seconds
        self.diminishing_returns_factor = diminishing_returns_factor
        
        # Active recursion states (keyed by context_id)
        self.active_states: Dict[str, RecursionState] = {}
        
        # Termination statistics
        self.termination_stats = {
            'depth_limit': 0,
            'novelty_plateau': 0,
            'coherence_drop': 0,
            'time_limit': 0,
            'diminishing_returns': 0,
            'manual_override': 0
        }
    
    def start_recursion(self, context_id: str = "default") -> RecursionState:
        """Initialize a new recursion tracking state."""
        state = RecursionState(max_depth=self.max_depth)
        self.active_states[context_id] = state
        return state
    
    def should_terminate(
        self,
        context_id: str = "default",
        current_novelty: Optional[float] = None,
        current_coherence: Optional[float] = None,
        custom_check: Optional[callable] = None
    ) -> tuple[bool, str]:
        """
        Determine if recursion should terminate based on multiple factors.
        
        Args:
            context_id: Identifier for this recursion chain
            current_novelty: Novelty score of current reflection (0-1)
            current_coherence: Coherence score of current reasoning (0-1)
            custom_check: Optional custom termination predicate
            
        Returns:
            Tuple of (should_terminate, reason)
        """
        state = self.active_states.get(context_id)
        if not state:
            state = self.start_recursion(context_id)
        
        # Update metrics if provided
        if current_novelty is not None:
            state.novelty_history.append(current_novelty)
        if current_coherence is not None:
            state.coherence_history.append(current_coherence)
        
        # Increment depth
        state.depth += 1
        
        # Check termination conditions in priority order
        
        # 1. Hard depth limit
        if state.depth > self.max_depth:
            state.termination_reason = f"Depth limit exceeded ({state.depth}/{self.max_depth})"
            self.termination_stats['depth_limit'] += 1
            return True, state.termination_reason
        
        # 2. Time limit
        if state.elapsed_time > self.time_limit_seconds:
            state.termination_reason = f"Time limit exceeded ({state.elapsed_time:.1f}s/{self.time_limit_seconds}s)"
            self.termination_stats['time_limit'] += 1
            return True, state.termination_reason
        
        # 3. Novelty plateau (no new insights being generated)
        if len(state.novelty_history) >= 3 and state.novelty_delta < self.novelty_threshold:
            state.termination_reason = f"Novelty plateau detected (delta={state.novelty_delta:.4f} < {self.novelty_threshold})"
            self.termination_stats['novelty_plateau'] += 1
            return True, state.termination_reason
        
        # 4. Coherence drop (reasoning becoming inconsistent)
        if current_coherence is not None and current_coherence < self.coherence_minimum:
            state.termination_reason = f"Coherence below minimum ({current_coherence:.2f} < {self.coherence_minimum})"
            self.termination_stats['coherence_drop'] += 1
            return True, state.termination_reason
        
        # 5. Diminishing returns check
        if len(state.novelty_history) >= 5:
            recent_improvements = [
                state.novelty_history[i] - state.novelty_history[i-1]
                for i in range(-4, 0)
            ]
            avg_improvement = sum(recent_improvements) / len(recent_improvements)
            if avg_improvement < self.diminishing_returns_factor:
                state.termination_reason = f"Diminishing returns (avg improvement={avg_improvement:.4f})"
                self.termination_stats['diminishing_returns'] += 1
                return True, state.termination_reason
        
        # 6. Custom check (user-defined termination logic)
        if custom_check is not None:
            try:
                should_stop, reason = custom_check(state)
                if should_stop:
                    state.termination_reason = reason or "Custom termination condition met"
                    self.termination_stats['manual_override'] += 1
                    return True, state.termination_reason
            except Exception as e:
                # If custom check fails, continue recursion but log warning
                pass
        
        # All checks passed - continue recursion
        return False, "Continuing recursion"
    
    def get_recursion_summary(self, context_id: str = "default") -> Dict[str, Any]:
        """Get summary of recursion chain for logging/analysis."""
        state = self.active_states.get(context_id)
        if not state:
            return {'error': 'No active recursion state'}
        
        return {
            'context_id': context_id,
            'depth': state.depth,
            'max_depth': self.max_depth,
            'elapsed_time_seconds': round(state.elapsed_time, 2),
            'avg_novelty': round(state.avg_novelty, 4),
            'avg_coherence': round(state.avg_coherence, 4),
            'novelty_delta': round(state.novelty_delta, 4),
            'termination_reason': state.termination_reason or "Not terminated",
            'novelty_history_length': len(state.novelty_history),
            'coherence_history_length': len(state.coherence_history),
            'efficiency_score': self._calculate_efficiency(state)
        }
    
    def _calculate_efficiency(self, state: RecursionState) -> float:
        """Calculate efficiency score for this recursion chain."""
        if state.depth == 0:
            return 0.0
        
        # Efficiency = (average novelty * average coherence) / depth
        # Higher is better (more insight per recursion step)
        efficiency = (state.avg_novelty * state.avg_coherence) / state.depth
        return round(min(1.0, efficiency), 4)
    
    def reset(self, context_id: Optional[str] = None):
        """Reset recursion state(s)."""
        if context_id:
            if context_id in self.active_states:
                del self.active_states[context_id]
        else:
            self.active_states.clear()
    
    def get_termination_statistics(self) -> Dict[str, int]:
        """Get aggregate termination statistics across all chains."""
        return self.termination_stats.copy()


# Example usage and testing
if __name__ == "__main__":
    print("="*80)
    print("RECURSIVE GOVERNOR - Testing Bounded Metacognition")
    print("="*80)
    
    governor = RecursiveGovernor(
        max_depth=10,
        novelty_threshold=0.02,
        coherence_minimum=0.6,
        time_limit_seconds=5.0
    )
    
    # Simulate a recursive reasoning chain
    context_id = "test_recursion_1"
    governor.start_recursion(context_id)
    
    print("\nSimulating recursive reflection chain...\n")
    
    for step in range(15):  # Try to go beyond max_depth
        # Simulate decreasing novelty (typical in deep recursion)
        simulated_novelty = max(0.0, 0.8 - (step * 0.1))
        simulated_coherence = max(0.0, 0.9 - (step * 0.05))
        
        should_stop, reason = governor.should_terminate(
            context_id=context_id,
            current_novelty=simulated_novelty,
            current_coherence=simulated_coherence
        )
        
        print(f"Step {step+1:2d}: Novelty={simulated_novelty:.2f}, "
              f"Coherence={simulated_coherence:.2f}")
        
        if should_stop:
            print(f"  ⛔ TERMINATED: {reason}")
            break
        else:
            print(f"  ✅ Continuing...")
    
    # Print summary
    summary = governor.get_recursion_summary(context_id)
    print("\n" + "="*80)
    print("RECURSION SUMMARY")
    print("="*80)
    for key, value in summary.items():
        print(f"  {key}: {value}")
    
    print("\nTermination Statistics:")
    stats = governor.get_termination_statistics()
    for reason, count in stats.items():
        if count > 0:
            print(f"  {reason}: {count}")
    
    print("\n✅ Recursive Governor test complete!")
