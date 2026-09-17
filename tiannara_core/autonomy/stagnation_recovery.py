"""
Stagnation Recovery System for Tiannara Autonomy

Implements automatic recovery mechanisms when learning stagnation is detected.
Provides strategy switching, intervention triggers, and diversity injection
to maintain continuous improvement.

Key Features:
- Automatic strategy switching based on stagnation severity
- Forced exploration through parameter perturbation
- Diversity injection via novel mutation operators
- Adaptive learning rate adjustment
- Integration with evolution loop for seamless operation

Usage:
    from tiannara_core.autonomy.stagnation_recovery import StagnationRecovery
    
    recovery = StagnationRecovery(detector)
    
    # After each episode
    if detector.is_stagnant():
        action = recovery.apply_recovery_strategy()
        print(f"Applied: {action}")
"""

import numpy as np
import logging
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum

# Try relative import first (for package usage), fallback to absolute (for standalone)
try:
    from .stagnation_detector import StagnationDetector, StagnationSeverity, StagnationEvent
except ImportError:
    from stagnation_detector import StagnationDetector, StagnationSeverity, StagnationEvent

logger = logging.getLogger(__name__)


class RecoveryStrategy(Enum):
    """Available recovery strategies for different stagnation levels."""
    NONE = "none"                           # No action needed
    ADAPTIVE_LR = "adaptive_lr"            # Adjust learning rate
    PARAMETER_PERTURBATION = "perturbation"  # Add noise to parameters
    DIVERSITY_INJECTION = "diversity"       # Inject novel mutations
    STRATEGY_SWITCH = "strategy_switch"     # Switch to alternative strategy
    EXPLORATION_BOOST = "exploration_boost" # Increase exploration rate
    RESTART_FROM_CHECKPOINT = "restart"     # Restart from best checkpoint


@dataclass
class RecoveryAction:
    """Represents a recovery action taken by the system."""
    strategy: RecoveryStrategy
    timestamp: str
    severity: StagnationSeverity
    parameters_changed: Dict[str, Any] = field(default_factory=dict)
    expected_impact: str = ""
    success: bool = False
    post_action_metrics: Dict[str, float] = field(default_factory=dict)
    
    def to_dict(self) -> Dict:
        """Convert to dictionary for logging."""
        return {
            'strategy': self.strategy.value,
            'timestamp': self.timestamp,
            'severity': self.severity.value,
            'parameters_changed': self.parameters_changed,
            'expected_impact': self.expected_impact,
            'success': self.success,
            'post_action_metrics': self.post_action_metrics
        }


class StagnationRecovery:
    """
    Manages automatic recovery from learning stagnation.
    
    Monitors stagnation events and applies appropriate recovery strategies
    based on severity level and historical effectiveness.
    """
    
    def __init__(
        self,
        detector: StagnationDetector,
        config: Optional[Dict] = None
    ):
        """
        Initialize stagnation recovery system.
        
        Args:
            detector: StagnationDetector instance to monitor
            config: Configuration parameters (optional)
        """
        self.detector = detector
        self.config = config or {}
        
        # Recovery history
        self.recovery_actions: List[RecoveryAction] = []
        self.strategy_effectiveness: Dict[str, List[float]] = {}
        
        # Current state
        self.current_strategy: RecoveryStrategy = RecoveryStrategy.NONE
        self.consecutive_recoveries: int = 0
        self.last_recovery_episode: Optional[int] = None  # Track by episode number
        
        # Configuration defaults
        self.min_episodes_between_recovery = self.config.get(
            'min_episodes_between_recovery', 10
        )
        self.max_consecutive_recoveries = self.config.get(
            'max_consecutive_recoveries', 5
        )
        
        logger.info("StagnationRecovery initialized")
    
    def apply_recovery_strategy(self) -> Optional[RecoveryAction]:
        """
        Apply appropriate recovery strategy based on current stagnation state.
        
        Returns:
            RecoveryAction taken, or None if no action needed
        """
        # Check if recovery is needed
        if not self.detector.is_stagnant():
            return None
        
        # Get stagnation severity
        severity = self.detector.get_severity()
        
        # Check cooldown period
        if self.last_recovery_episode is not None:
            # Get current episode from detector's history
            current_episode = self.detector.episode_numbers[-1] if self.detector.episode_numbers else 0
            episodes_since = current_episode - self.last_recovery_episode
            if episodes_since < self.min_episodes_between_recovery:
                logger.debug(f"Recovery cooldown active ({episodes_since} < {self.min_episodes_between_recovery})")
                return None
        
        # Check max consecutive recoveries
        if self.consecutive_recoveries >= self.max_consecutive_recoveries:
            logger.warning(f"Max consecutive recoveries reached ({self.consecutive_recoveries})")
            return None
        
        # Select strategy based on severity
        strategy = self._select_strategy(severity)
        
        # Apply the strategy
        action = self._execute_strategy(strategy, severity)
        
        # Record the action
        self.recovery_actions.append(action)
        self.current_strategy = strategy
        self.consecutive_recoveries += 1
        # Store current episode number for cooldown tracking
        self.last_recovery_episode = self.detector.episode_numbers[-1] if self.detector.episode_numbers else 0
        
        # Track effectiveness
        strategy_key = strategy.value
        if strategy_key not in self.strategy_effectiveness:
            self.strategy_effectiveness[strategy_key] = []
        
        logger.info(f"Applied recovery strategy: {strategy.value} (severity: {severity.value})")
        return action
    
    def _select_strategy(self, severity: StagnationSeverity) -> RecoveryStrategy:
        """
        Select recovery strategy based on stagnation severity.
        
        Args:
            severity: Current stagnation severity level
            
        Returns:
            Selected recovery strategy
        """
        if severity == StagnationSeverity.MILD:
            # Try least invasive strategies first
            return self._choose_from_candidates([
                RecoveryStrategy.ADAPTIVE_LR,
                RecoveryStrategy.PARAMETER_PERTURBATION
            ])
        
        elif severity == StagnationSeverity.MODERATE:
            # More aggressive interventions
            return self._choose_from_candidates([
                RecoveryStrategy.DIVERSITY_INJECTION,
                RecoveryStrategy.EXPLORATION_BOOST,
                RecoveryStrategy.PARAMETER_PERTURBATION
            ])
        
        elif severity == StagnationSeverity.SEVERE:
            # Maximum intervention
            return self._choose_from_candidates([
                RecoveryStrategy.STRATEGY_SWITCH,
                RecoveryStrategy.RESTART_FROM_CHECKPOINT,
                RecoveryStrategy.DIVERSITY_INJECTION
            ])
        
        else:
            return RecoveryStrategy.NONE
    
    def _choose_from_candidates(self, candidates: List[RecoveryStrategy]) -> RecoveryStrategy:
        """
        Choose best strategy from candidates based on historical effectiveness.
        
        Args:
            candidates: List of candidate strategies
            
        Returns:
            Best strategy based on past performance
        """
        if not candidates:
            return RecoveryStrategy.NONE
        
        # If no history, use first candidate
        if not self.strategy_effectiveness:
            return candidates[0]
        
        # Evaluate candidates by average effectiveness
        best_strategy = None
        best_score = -1.0
        
        for strategy in candidates:
            key = strategy.value
            if key in self.strategy_effectiveness and self.strategy_effectiveness[key]:
                avg_score = np.mean(self.strategy_effectiveness[key])
                if avg_score > best_score:
                    best_score = avg_score
                    best_strategy = strategy
        
        # If no candidates have history, use first one
        return best_strategy or candidates[0]
    
    def _execute_strategy(
        self,
        strategy: RecoveryStrategy,
        severity: StagnationSeverity
    ) -> RecoveryAction:
        """
        Execute a specific recovery strategy.
        
        Args:
            strategy: Strategy to execute
            severity: Current stagnation severity
            
        Returns:
            RecoveryAction with details of execution
        """
        timestamp = datetime.now().isoformat()
        
        if strategy == RecoveryStrategy.ADAPTIVE_LR:
            return self._apply_adaptive_lr(timestamp, severity)
        
        elif strategy == RecoveryStrategy.PARAMETER_PERTURBATION:
            return self._apply_parameter_perturbation(timestamp, severity)
        
        elif strategy == RecoveryStrategy.DIVERSITY_INJECTION:
            return self._apply_diversity_injection(timestamp, severity)
        
        elif strategy == RecoveryStrategy.STRATEGY_SWITCH:
            return self._apply_strategy_switch(timestamp, severity)
        
        elif strategy == RecoveryStrategy.EXPLORATION_BOOST:
            return self._apply_exploration_boost(timestamp, severity)
        
        elif strategy == RecoveryStrategy.RESTART_FROM_CHECKPOINT:
            return self._apply_restart(timestamp, severity)
        
        else:
            return RecoveryAction(
                strategy=RecoveryStrategy.NONE,
                timestamp=timestamp,
                severity=severity,
                expected_impact="No action taken"
            )
    
    def _apply_adaptive_lr(self, timestamp: str, severity: StagnationSeverity) -> RecoveryAction:
        """
        Adjust learning rate based on stagnation patterns.
        
        Reduces LR for fine-tuning or increases for escaping local optima.
        """
        # Determine direction based on recent trend
        stats = self.detector.get_learning_curve_stats()
        recent_trend = stats.trend_slope if hasattr(stats, 'trend_slope') else 0.0
        
        if recent_trend < 0:
            # Decreasing performance - reduce LR for stability
            lr_change = -0.5  # Reduce by 50%
            impact = "Reduced learning rate for stability during decline"
        else:
            # Plateau - increase LR to escape local optimum
            lr_change = 0.3  # Increase by 30%
            impact = "Increased learning rate to escape plateau"
        
        return RecoveryAction(
            strategy=RecoveryStrategy.ADAPTIVE_LR,
            timestamp=timestamp,
            severity=severity,
            parameters_changed={'learning_rate_change': lr_change},
            expected_impact=impact
        )
    
    def _apply_parameter_perturbation(self, timestamp: str, severity: StagnationSeverity) -> RecoveryAction:
        """
        Add controlled noise to model parameters to escape local optima.
        """
        # Perturbation magnitude based on severity
        perturbation_map = {
            StagnationSeverity.MILD: 0.01,
            StagnationSeverity.MODERATE: 0.05,
            StagnationSeverity.SEVERE: 0.1
        }
        
        noise_scale = perturbation_map.get(severity, 0.05)
        
        return RecoveryAction(
            strategy=RecoveryStrategy.PARAMETER_PERTURBATION,
            timestamp=timestamp,
            severity=severity,
            parameters_changed={
                'noise_scale': noise_scale,
                'distribution': 'gaussian'
            },
            expected_impact=f"Added Gaussian noise (σ={noise_scale}) to parameters"
        )
    
    def _apply_diversity_injection(self, timestamp: str, severity: StagnationSeverity) -> RecoveryAction:
        """
        Inject novel mutation operators to increase population diversity.
        """
        # Novel mutation types
        mutation_types = [
            'structural_mutation',
            'hyperparameter_randomization',
            'architecture_variation',
            'objective_function_perturbation'
        ]
        
        # Number of mutations based on severity
        num_mutations_map = {
            StagnationSeverity.MILD: 1,
            StagnationSeverity.MODERATE: 2,
            StagnationSeverity.SEVERE: 3
        }
        
        num_mutations = num_mutations_map.get(severity, 2)
        selected_mutations = np.random.choice(
            mutation_types, 
            size=num_mutations, 
            replace=False
        ).tolist()
        
        return RecoveryAction(
            strategy=RecoveryStrategy.DIVERSITY_INJECTION,
            timestamp=timestamp,
            severity=severity,
            parameters_changed={
                'mutation_types': selected_mutations,
                'num_mutations': num_mutations
            },
            expected_impact=f"Injected {num_mutations} novel mutation operators"
        )
    
    def _apply_strategy_switch(self, timestamp: str, severity: StagnationSeverity) -> RecoveryAction:
        """
        Switch to alternative optimization/evolution strategy.
        """
        available_strategies = [
            'gradient_descent',
            'evolutionary_algorithm',
            'bayesian_optimization',
            'particle_swarm',
            'simulated_annealing'
        ]
        
        # Select strategy different from current
        current = self.config.get('current_strategy', 'gradient_descent')
        alternatives = [s for s in available_strategies if s != current]
        new_strategy = np.random.choice(alternatives)
        
        return RecoveryAction(
            strategy=RecoveryStrategy.STRATEGY_SWITCH,
            timestamp=timestamp,
            severity=severity,
            parameters_changed={
                'old_strategy': current,
                'new_strategy': new_strategy
            },
            expected_impact=f"Switched from {current} to {new_strategy}"
        )
    
    def _apply_exploration_boost(self, timestamp: str, severity: StagnationSeverity) -> RecoveryAction:
        """
        Increase exploration rate to discover new regions of search space.
        """
        # Exploration boost factors
        boost_map = {
            StagnationSeverity.MILD: 1.2,   # 20% increase
            StagnationSeverity.MODERATE: 1.5,  # 50% increase
            StagnationSeverity.SEVERE: 2.0     # 100% increase
        }
        
        boost_factor = boost_map.get(severity, 1.5)
        
        return RecoveryAction(
            strategy=RecoveryStrategy.EXPLORATION_BOOST,
            timestamp=timestamp,
            severity=severity,
            parameters_changed={
                'exploration_boost_factor': boost_factor,
                'epsilon_greedy_increase': boost_factor - 1.0
            },
            expected_impact=f"Increased exploration by {(boost_factor-1)*100:.0f}%"
        )
    
    def _apply_restart(self, timestamp: str, severity: StagnationSeverity) -> RecoveryAction:
        """
        Restart from best checkpoint with modified hyperparameters.
        """
        # Get best performance info
        stats = self.detector.get_learning_curve_stats()
        best_performance = stats.best_value if hasattr(stats, 'best_value') else 0.0
        
        # Modify hyperparameters for restart
        restart_params = {
            'learning_rate_multiplier': 0.5,  # Start with lower LR
            'batch_size_change': -0.2,        # Smaller batches for more gradient noise
            'momentum_reset': True,           # Reset momentum
            'best_performance_so_far': best_performance
        }
        
        return RecoveryAction(
            strategy=RecoveryStrategy.RESTART_FROM_CHECKPOINT,
            timestamp=timestamp,
            severity=severity,
            parameters_changed=restart_params,
            expected_impact=f"Restarted with modified params (best so far: {best_performance:.4f})"
        )
    
    def record_outcome(self, action: RecoveryAction, improvement: float):
        """
        Record the outcome of a recovery action.
        
        Args:
            action: The recovery action that was taken
            improvement: Measured improvement (positive = success)
        """
        action.success = improvement > 0
        action.post_action_metrics['improvement'] = improvement
        
        # Update strategy effectiveness tracking
        strategy_key = action.strategy.value
        if strategy_key not in self.strategy_effectiveness:
            self.strategy_effectiveness[strategy_key] = []
        
        self.strategy_effectiveness[strategy_key].append(improvement)
        
        # Keep only last 20 outcomes per strategy
        if len(self.strategy_effectiveness[strategy_key]) > 20:
            self.strategy_effectiveness[strategy_key] = \
                self.strategy_effectiveness[strategy_key][-20:]
        
        logger.info(f"Recovery outcome recorded: {action.strategy.value} "
                   f"(improvement: {improvement:+.4f})")
    
    def get_recovery_statistics(self) -> Dict[str, Any]:
        """
        Get statistics about recovery actions and effectiveness.
        
        Returns:
            Dictionary with recovery statistics
        """
        if not self.recovery_actions:
            return {
                'total_recoveries': 0,
                'strategies_used': {},
                'average_improvement': 0.0
            }
        
        # Count strategies used
        strategy_counts = {}
        for action in self.recovery_actions:
            key = action.strategy.value
            strategy_counts[key] = strategy_counts.get(key, 0) + 1
        
        # Calculate average improvement
        improvements = [
            action.post_action_metrics.get('improvement', 0.0)
            for action in self.recovery_actions
            if action.post_action_metrics
        ]
        avg_improvement = np.mean(improvements) if improvements else 0.0
        
        # Success rate
        success_count = sum(1 for a in self.recovery_actions if a.success)
        success_rate = success_count / len(self.recovery_actions) if self.recovery_actions else 0.0
        
        return {
            'total_recoveries': len(self.recovery_actions),
            'consecutive_recoveries': self.consecutive_recoveries,
            'strategies_used': strategy_counts,
            'average_improvement': float(avg_improvement),
            'success_rate': float(success_rate),
            'strategy_effectiveness': {
                k: float(np.mean(v)) if v else 0.0
                for k, v in self.strategy_effectiveness.items()
            }
        }
    
    def reset(self):
        """Reset recovery system state."""
        self.recovery_actions.clear()
        self.strategy_effectiveness.clear()
        self.current_strategy = RecoveryStrategy.NONE
        self.consecutive_recoveries = 0
        self.last_recovery_episode = None
        logger.info("StagnationRecovery state reset")
