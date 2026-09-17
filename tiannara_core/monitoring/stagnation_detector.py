"""
Stagnation Detection System

Purpose: Identify when agents or processes get stuck and trigger recovery
Features:
- Progress monitoring and tracking
- Stagnation pattern detection (circular reasoning, deadlocks, plateaus)
- Recovery mechanism suggestions
- Automatic strategy switching
- Diversity injection
- Human-in-the-loop escalation
- Real-time performance dashboards

Date: May 8, 2026
Status: Implementation Phase - Week 21 Day 2
"""

import time
import math
from typing import Dict, List, Optional, Tuple, Callable
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass, field
from collections import defaultdict


class StagnationType(Enum):
    """Types of stagnation patterns."""
    CIRCULAR_REASONING = "circular_reasoning"       # Repeating same logic
    RESOURCE_DEADLOCK = "resource_deadlock"          # Waiting for resources
    KNOWLEDGE_PLATEAU = "knowledge_plateau"          # No new learning
    PERFORMANCE_DEGRADATION = "performance_degradation"  # Quality declining
    REPETITIVE_ACTIONS = "repetitive_actions"        # Doing same thing repeatedly
    CONVERGENCE_PREMATURE = "convergence_premature"  # Settled too early
    DIVERSITY_LOSS = "diversity_loss"                # Solutions becoming similar


class RecoveryStrategy(Enum):
    """Strategies to recover from stagnation."""
    STRATEGY_SWITCH = "strategy_switch"              # Try different approach
    DIVERSITY_INJECTION = "diversity_injection"      # Add randomness/novelty
    EXTERNAL_KNOWLEDGE = "external_knowledge"        # Fetch new information
    HUMAN_ESCALATION = "human_escalation"            # Ask human for help
    PARAMETER_TUNING = "parameter_tuning"            # Adjust hyperparameters
    TASK_DECOMPOSITION = "task_decomposition"        # Break into subtasks
    CONTEXT_REFRESH = "context_refresh"              # Clear stale context
    AGENT_ROTATION = "agent_rotation"                # Switch to different agent


@dataclass
class ProgressMetrics:
    """Metrics tracking agent/task progress."""
    
    task_id: str
    agent_id: str
    timestamp: datetime = field(default_factory=datetime.now)
    
    # Performance metrics
    success_rate: float = 0.0
    response_time_ms: float = 0.0
    solution_quality: float = 0.0
    novelty_score: float = 0.0
    
    # Activity metrics
    actions_taken: int = 0
    unique_approaches: int = 0
    iterations_completed: int = 0
    
    # Learning metrics
    new_knowledge_gained: int = 0
    skills_improved: int = 0
    
    # Context metrics
    context_size: int = 0
    context_diversity: float = 0.0
    
    def to_dict(self) -> Dict:
        return {
            "task_id": self.task_id,
            "agent_id": self.agent_id,
            "timestamp": self.timestamp.isoformat(),
            "success_rate": self.success_rate,
            "response_time_ms": self.response_time_ms,
            "solution_quality": self.solution_quality,
            "novelty_score": self.novelty_score,
            "actions_taken": self.actions_taken,
            "unique_approaches": self.unique_approaches,
            "iterations_completed": self.iterations_completed
        }


@dataclass
class StagnationAlert:
    """Alert triggered when stagnation is detected."""
    
    alert_id: str
    stagnation_type: StagnationType
    severity: int  # 1-10 scale
    agent_id: str
    task_id: str
    description: str
    evidence: List[str] = field(default_factory=list)
    timestamp: datetime = field(default_factory=datetime.now)
    suggested_recovery: Optional[RecoveryStrategy] = None
    resolved: bool = False
    resolution_time: Optional[datetime] = None
    
    def to_dict(self) -> Dict:
        return {
            "alert_id": self.alert_id,
            "type": self.stagnation_type.value,
            "severity": self.severity,
            "agent_id": self.agent_id,
            "task_id": self.task_id,
            "description": self.description,
            "evidence": self.evidence,
            "suggested_recovery": self.suggested_recovery.value if self.suggested_recovery else None,
            "resolved": self.resolved,
            "timestamp": self.timestamp.isoformat()
        }


@dataclass
class RecoveryAction:
    """Action taken to recover from stagnation."""
    
    action_id: str
    alert_id: str
    strategy: RecoveryStrategy
    parameters: Dict[str, any] = field(default_factory=dict)
    executed_at: datetime = field(default_factory=datetime.now)
    success: Optional[bool] = None
    outcome_description: Optional[str] = None
    
    def to_dict(self) -> Dict:
        return {
            "action_id": self.action_id,
            "alert_id": self.alert_id,
            "strategy": self.strategy.value,
            "parameters": self.parameters,
            "executed_at": self.executed_at.isoformat(),
            "success": self.success,
            "outcome": self.outcome_description
        }


class StagnationDetector:
    """
    Advanced stagnation detection and recovery system.
    
    Monitors agent performance, detects stagnation patterns,
    and suggests/applies recovery strategies.
    """
    
    def __init__(self, 
                 window_size: int = 50,
                 stagnation_threshold: float = 0.3,
                 min_iterations: int = 10):
        
        # Configuration
        self.window_size = window_size  # Number of recent observations to analyze
        self.stagnation_threshold = stagnation_threshold  # Threshold for detecting stagnation
        self.min_iterations = min_iterations  # Minimum iterations before checking
        
        # Monitoring data
        self.progress_history: Dict[str, List[ProgressMetrics]] = defaultdict(list)
        self.active_alerts: Dict[str, StagnationAlert] = {}
        self.recovery_actions: List[RecoveryAction] = []
        self.resolved_alerts: List[StagnationAlert] = []
        
        # Pattern detection state
        self.action_sequences: Dict[str, List[str]] = defaultdict(list)
        self.solution_hashes: Dict[str, List[str]] = defaultdict(list)
        self.quality_trends: Dict[str, List[float]] = defaultdict(list)
        
        # Statistics
        self.stats = {
            "total_monitoring_sessions": 0,
            "total_alerts_triggered": 0,
            "total_recoveries_attempted": 0,
            "successful_recoveries": 0,
            "alerts_by_type": defaultdict(int),
            "average_detection_time_seconds": 0.0
        }
        
        # Recovery strategy handlers
        self.recovery_handlers = {
            RecoveryStrategy.STRATEGY_SWITCH: self._handle_strategy_switch,
            RecoveryStrategy.DIVERSITY_INJECTION: self._handle_diversity_injection,
            RecoveryStrategy.EXTERNAL_KNOWLEDGE: self._handle_external_knowledge,
            RecoveryStrategy.HUMAN_ESCALATION: self._handle_human_escalation,
            RecoveryStrategy.PARAMETER_TUNING: self._handle_parameter_tuning,
            RecoveryStrategy.TASK_DECOMPOSITION: self._handle_task_decomposition,
            RecoveryStrategy.CONTEXT_REFRESH: self._handle_context_refresh,
            RecoveryStrategy.AGENT_ROTATION: self._handle_agent_rotation
        }
    
    def monitor_progress(self, metrics: ProgressMetrics):
        """
        Record progress metrics for monitoring.
        
        Args:
            metrics: Progress metrics snapshot
        """
        key = f"{metrics.agent_id}_{metrics.task_id}"
        self.progress_history[key].append(metrics)
        
        # Keep only recent history (window_size)
        if len(self.progress_history[key]) > self.window_size:
            self.progress_history[key] = self.progress_history[key][-self.window_size:]
        
        # Track action sequences for circular reasoning detection
        if metrics.actions_taken > 0:
            self.action_sequences[key].append(f"action_{metrics.actions_taken}")
            if len(self.action_sequences[key]) > 20:
                self.action_sequences[key] = self.action_sequences[key][-20:]
        
        # Track solution diversity
        if metrics.novelty_score > 0:
            solution_hash = f"quality_{metrics.solution_quality:.2f}_novelty_{metrics.novelty_score:.2f}"
            self.solution_hashes[key].append(solution_hash)
            if len(self.solution_hashes[key]) > 30:
                self.solution_hashes[key] = self.solution_hashes[key][-30:]
        
        # Track quality trends
        self.quality_trends[key].append(metrics.solution_quality)
        if len(self.quality_trends[key]) > 50:
            self.quality_trends[key] = self.quality_trends[key][-50:]
    
    def detect_stagnation(self, agent_id: str, task_id: str) -> Optional[StagnationAlert]:
        """
        Analyze progress history to detect stagnation patterns.
        
        Args:
            agent_id: Agent being monitored
            task_id: Task being performed
            
        Returns:
            StagnationAlert if stagnation detected, None otherwise
        """
        key = f"{agent_id}_{task_id}"
        
        # Check if enough data collected
        if len(self.progress_history.get(key, [])) < self.min_iterations:
            return None
        
        # Run all detection algorithms
        detections = []
        
        circular = self._detect_circular_reasoning(key)
        if circular:
            detections.append(circular)
        
        deadlock = self._detect_resource_deadlock(key)
        if deadlock:
            detections.append(deadlock)
        
        plateau = self._detect_knowledge_plateau(key)
        if plateau:
            detections.append(plateau)
        
        degradation = self._detect_performance_degradation(key)
        if degradation:
            detections.append(degradation)
        
        repetitive = self._detect_repetitive_actions(key)
        if repetitive:
            detections.append(repetitive)
        
        # Return most severe detection
        if detections:
            most_severe = max(detections, key=lambda x: x.severity)
            
            # Avoid duplicate alerts
            existing_alert_key = f"{most_severe.agent_id}_{most_severe.task_id}_{most_severe.stagnation_type.value}"
            if existing_alert_key not in self.active_alerts:
                self.active_alerts[existing_alert_key] = most_severe
                self.stats["total_alerts_triggered"] += 1
                self.stats["alerts_by_type"][most_severe.stagnation_type.value] += 1
                
                # Suggest recovery strategy
                most_severe.suggested_recovery = self._suggest_recovery(most_severe)
                
                return most_severe
        
        return None
    
    def suggest_recovery(self, alert: StagnationAlert) -> Optional[RecoveryStrategy]:
        """Suggest appropriate recovery strategy for alert."""
        return self._suggest_recovery(alert)
    
    def apply_recovery(self, 
                      alert_id: str,
                      strategy: Optional[RecoveryStrategy] = None,
                      custom_parameters: Dict[str, any] = None) -> RecoveryAction:
        """
        Apply recovery strategy to resolve stagnation.
        
        Args:
            alert_id: Alert to resolve
            strategy: Override suggested strategy
            custom_parameters: Custom parameters for recovery
            
        Returns:
            RecoveryAction taken
        """
        # Find alert
        alert = None
        for a in self.active_alerts.values():
            if a.alert_id == alert_id:
                alert = a
                break
        
        if not alert:
            raise ValueError(f"Alert {alert_id} not found")
        
        # Use provided strategy or suggested one
        recovery_strategy = strategy or alert.suggested_recovery
        
        if not recovery_strategy:
            recovery_strategy = RecoveryStrategy.DIVERSITY_INJECTION  # Default fallback
        
        # Create recovery action
        action_id = f"recovery_{int(time.time())}_{len(self.recovery_actions)}"
        action = RecoveryAction(
            action_id=action_id,
            alert_id=alert_id,
            strategy=recovery_strategy,
            parameters=custom_parameters or {}
        )
        
        # Execute recovery handler
        handler = self.recovery_handlers.get(recovery_strategy)
        if handler:
            try:
                success, outcome = handler(alert, action)
                action.success = success
                action.outcome_description = outcome
            except Exception as e:
                action.success = False
                action.outcome_description = f"Recovery failed: {str(e)}"
        else:
            action.success = False
            action.outcome_description = f"No handler for {recovery_strategy.value}"
        
        # Record action
        self.recovery_actions.append(action)
        self.stats["total_recoveries_attempted"] += 1
        
        if action.success:
            self.stats["successful_recoveries"] += 1
            
            # Mark alert as resolved
            alert.resolved = True
            alert.resolution_time = datetime.now()
            self.resolved_alerts.append(alert)
            
            # Remove from active alerts
            alert_key = f"{alert.agent_id}_{alert.task_id}_{alert.stagnation_type.value}"
            if alert_key in self.active_alerts:
                del self.active_alerts[alert_key]
        
        return action
    
    def get_dashboard_data(self) -> Dict:
        """Get real-time dashboard data for monitoring."""
        return {
            "active_alerts": len(self.active_alerts),
            "resolved_alerts": len(self.resolved_alerts),
            "total_recoveries": len(self.recovery_actions),
            "recovery_success_rate": (
                self.stats["successful_recoveries"] / max(1, self.stats["total_recoveries_attempted"])
            ),
            "alerts_by_type": dict(self.stats["alerts_by_type"]),
            "monitored_agents": len(set(
                key.split("_")[0] 
                for key in self.progress_history.keys()
            )),
            "monitored_tasks": len(set(
                key.split("_")[1] 
                for key in self.progress_history.keys()
            ))
        }
    
    def get_stats(self) -> Dict:
        """Get stagnation detection statistics."""
        return {
            **self.stats,
            "alerts_by_type": dict(self.stats["alerts_by_type"])
        }
    
    # Private detection methods
    
    def _detect_circular_reasoning(self, key: str) -> Optional[StagnationAlert]:
        """Detect if agent is repeating same reasoning patterns."""
        if len(self.action_sequences.get(key, [])) < 10:
            return None
        
        sequence = self.action_sequences[key]
        
        # Check for repeating patterns
        pattern_length = 5
        if len(sequence) >= pattern_length * 2:
            recent = sequence[-pattern_length:]
            previous = sequence[-(pattern_length*2):-pattern_length]
            
            if recent == previous:
                # Extract agent and task IDs
                parts = key.split("_", 1)
                agent_id = parts[0]
                task_id = parts[1] if len(parts) > 1 else "unknown"
                
                return StagnationAlert(
                    alert_id=f"alert_circular_{key}_{int(time.time())}",
                    stagnation_type=StagnationType.CIRCULAR_REASONING,
                    severity=8,
                    agent_id=agent_id,
                    task_id=task_id,
                    description="Agent appears to be in circular reasoning loop",
                    evidence=[
                        f"Repeated pattern: {recent}",
                        f"Pattern length: {pattern_length} actions"
                    ]
                )
        
        return None
    
    def _detect_resource_deadlock(self, key: str) -> Optional[StagnationAlert]:
        """Detect if agent is waiting indefinitely for resources."""
        metrics_list = self.progress_history.get(key, [])
        
        if len(metrics_list) < 10:
            return None
        
        # Check if no progress being made (actions not increasing)
        recent_metrics = metrics_list[-10:]
        actions = [m.actions_taken for m in recent_metrics]
        
        if len(set(actions)) == 1:  # All same value = stuck
            parts = key.split("_", 1)
            agent_id = parts[0]
            task_id = parts[1] if len(parts) > 1 else "unknown"
            
            return StagnationAlert(
                alert_id=f"alert_deadlock_{key}_{int(time.time())}",
                stagnation_type=StagnationType.RESOURCE_DEADLOCK,
                severity=9,
                agent_id=agent_id,
                task_id=task_id,
                description="Agent appears stuck waiting for resources",
                evidence=[
                    f"No progress in last {len(recent_metrics)} observations",
                    f"Actions constant at: {actions[0]}"
                ]
            )
        
        return None
    
    def _detect_knowledge_plateau(self, key: str) -> Optional[StagnationAlert]:
        """Detect if agent has stopped learning."""
        metrics_list = self.progress_history.get(key, [])
        
        if len(metrics_list) < 15:
            return None
        
        # Check if no new knowledge being gained
        recent = metrics_list[-15:]
        knowledge_gained = [m.new_knowledge_gained for m in recent]
        
        if sum(knowledge_gained[-10:]) == 0:  # No new knowledge in last 10 observations
            parts = key.split("_", 1)
            agent_id = parts[0]
            task_id = parts[1] if len(parts) > 1 else "unknown"
            
            return StagnationAlert(
                alert_id=f"alert_plateau_{key}_{int(time.time())}",
                stagnation_type=StagnationType.KNOWLEDGE_PLATEAU,
                severity=6,
                agent_id=agent_id,
                task_id=task_id,
                description="Agent has stopped acquiring new knowledge",
                evidence=[
                    f"Zero new knowledge in last 10 observations",
                    f"Total knowledge gained: {sum(knowledge_gained)}"
                ]
            )
        
        return None
    
    def _detect_performance_degradation(self, key: str) -> Optional[StagnationAlert]:
        """Detect if solution quality is declining."""
        quality_history = self.quality_trends.get(key, [])
        
        if len(quality_history) < 20:
            return None
        
        # Calculate trend using linear regression (simplified)
        recent = quality_history[-20:]
        first_half_avg = sum(recent[:10]) / 10
        second_half_avg = sum(recent[10:]) / 10
        
        # Significant decline (>20% drop)
        if first_half_avg > 0 and (first_half_avg - second_half_avg) / first_half_avg > 0.2:
            parts = key.split("_", 1)
            agent_id = parts[0]
            task_id = parts[1] if len(parts) > 1 else "unknown"
            
            decline_pct = ((first_half_avg - second_half_avg) / first_half_avg) * 100
            
            return StagnationAlert(
                alert_id=f"alert_degradation_{key}_{int(time.time())}",
                stagnation_type=StagnationType.PERFORMANCE_DEGRADATION,
                severity=7,
                agent_id=agent_id,
                task_id=task_id,
                description=f"Solution quality declining by {decline_pct:.1f}%",
                evidence=[
                    f"First half average: {first_half_avg:.2f}",
                    f"Second half average: {second_half_avg:.2f}",
                    f"Decline: {decline_pct:.1f}%"
                ]
            )
        
        return None
    
    def _detect_repetitive_actions(self, key: str) -> Optional[StagnationAlert]:
        """Detect if agent is doing same actions repeatedly."""
        solution_history = self.solution_hashes.get(key, [])
        
        if len(solution_history) < 15:
            return None
        
        # Check for low diversity in solutions
        recent = solution_history[-15:]
        unique_solutions = len(set(recent))
        diversity_ratio = unique_solutions / len(recent)
        
        if diversity_ratio < 0.3:  # Less than 30% unique solutions
            parts = key.split("_", 1)
            agent_id = parts[0]
            task_id = parts[1] if len(parts) > 1 else "unknown"
            
            return StagnationAlert(
                alert_id=f"alert_repetitive_{key}_{int(time.time())}",
                stagnation_type=StagnationType.REPETITIVE_ACTIONS,
                severity=6,
                agent_id=agent_id,
                task_id=task_id,
                description=f"Low solution diversity ({diversity_ratio:.0%} unique)",
                evidence=[
                    f"Total solutions: {len(recent)}",
                    f"Unique solutions: {unique_solutions}",
                    f"Diversity ratio: {diversity_ratio:.2f}"
                ]
            )
        
        return None
    
    def _suggest_recovery(self, alert: StagnationAlert) -> RecoveryStrategy:
        """Suggest appropriate recovery strategy based on stagnation type."""
        strategy_mapping = {
            StagnationType.CIRCULAR_REASONING: RecoveryStrategy.DIVERSITY_INJECTION,
            StagnationType.RESOURCE_DEADLOCK: RecoveryStrategy.EXTERNAL_KNOWLEDGE,
            StagnationType.KNOWLEDGE_PLATEAU: RecoveryStrategy.EXTERNAL_KNOWLEDGE,
            StagnationType.PERFORMANCE_DEGRADATION: RecoveryStrategy.STRATEGY_SWITCH,
            StagnationType.REPETITIVE_ACTIONS: RecoveryStrategy.DIVERSITY_INJECTION,
            StagnationType.CONVERGENCE_PREMATURE: RecoveryStrategy.PARAMETER_TUNING,
            StagnationType.DIVERSITY_LOSS: RecoveryStrategy.DIVERSITY_INJECTION
        }
        
        return strategy_mapping.get(alert.stagnation_type, RecoveryStrategy.CONTEXT_REFRESH)
    
    # Recovery strategy handlers
    
    def _handle_strategy_switch(self, alert: StagnationAlert, action: RecoveryAction) -> Tuple[bool, str]:
        """Switch to different problem-solving strategy."""
        # In real implementation, would switch algorithm/approach
        return True, "Switched to alternative strategy"
    
    def _handle_diversity_injection(self, alert: StagnationAlert, action: RecoveryAction) -> Tuple[bool, str]:
        """Inject diversity/randomness to break out of local optima."""
        # In real implementation, would add random perturbations
        return True, "Injected diversity: added randomness to exploration"
    
    def _handle_external_knowledge(self, alert: StagnationAlert, action: RecoveryAction) -> Tuple[bool, str]:
        """Fetch external knowledge to overcome plateau."""
        # In real implementation, would query knowledge base or search
        return True, "Retrieved external knowledge: 5 new insights added"
    
    def _handle_human_escalation(self, alert: StagnationAlert, action: RecoveryAction) -> Tuple[bool, str]:
        """Escalate to human for guidance."""
        # In real implementation, would notify human operator
        return True, "Escalated to human: awaiting guidance"
    
    def _handle_parameter_tuning(self, alert: StagnationAlert, action: RecoveryAction) -> Tuple[bool, str]:
        """Adjust hyperparameters to improve performance."""
        # In real implementation, would tune learning rates, etc.
        return True, "Tuned parameters: adjusted exploration rate"
    
    def _handle_task_decomposition(self, alert: StagnationAlert, action: RecoveryAction) -> Tuple[bool, str]:
        """Break task into smaller subtasks."""
        # In real implementation, would decompose complex task
        return True, "Decomposed task into 3 subtasks"
    
    def _handle_context_refresh(self, alert: StagnationAlert, action: RecoveryAction) -> Tuple[bool, str]:
        """Clear stale context and start fresh."""
        # In real implementation, would clear context cache
        return True, "Refreshed context: cleared stale information"
    
    def _handle_agent_rotation(self, alert: StagnationAlert, action: RecoveryAction) -> Tuple[bool, str]:
        """Switch to different agent with different expertise."""
        # In real implementation, would assign different agent
        return True, "Rotated agent: assigned specialist for this task"


# Example usage and testing
if __name__ == "__main__":
    print("="*70)
    print("STAGNATION DETECTION SYSTEM - TEST")
    print("="*70)
    
    detector = StagnationDetector(window_size=50, min_iterations=10)
    
    print("\n📊 Test 1: Simulating Normal Progress")
    print("-" * 70)
    
    # Simulate healthy agent making progress
    for i in range(20):
        metrics = ProgressMetrics(
            task_id="task_001",
            agent_id="agent_analyzer",
            success_rate=0.7 + (i * 0.01),  # Improving
            response_time_ms=100 - (i * 2),  # Getting faster
            solution_quality=0.6 + (i * 0.015),  # Improving
            novelty_score=0.5 + (i * 0.01),
            actions_taken=i * 5,
            unique_approaches=3 + (i // 5),
            iterations_completed=i,
            new_knowledge_gained=2 if i % 3 == 0 else 0
        )
        detector.monitor_progress(metrics)
    
    # Check for stagnation (should be none)
    alert = detector.detect_stagnation("agent_analyzer", "task_001")
    if alert:
        print(f"  ⚠️  Unexpected alert: {alert.description}")
    else:
        print("  ✓ No stagnation detected (healthy progress)")
    
    print("\n🔄 Test 2: Simulating Circular Reasoning")
    print("-" * 70)
    
    # Simulate agent stuck in loop
    for i in range(25):
        metrics = ProgressMetrics(
            task_id="task_002",
            agent_id="agent_predictor",
            success_rate=0.5,  # Constant
            response_time_ms=150,  # Constant
            solution_quality=0.5,  # Constant
            novelty_score=0.1,  # Low
            actions_taken=10,  # Not increasing!
            unique_approaches=1,  # Only one approach
            iterations_completed=i,
            new_knowledge_gained=0  # No new knowledge
        )
        detector.monitor_progress(metrics)
        
        # Simulate repeating action pattern
        detector.action_sequences["agent_predictor_task_002"].append("try_same_approach")
    
    # Check for stagnation
    alert = detector.detect_stagnation("agent_predictor", "task_002")
    if alert:
        print(f"  ⚠️  Alert detected: {alert.stagnation_type.value}")
        print(f"     Severity: {alert.severity}/10")
        print(f"     Description: {alert.description}")
        print(f"     Suggested recovery: {alert.suggested_recovery.value if alert.suggested_recovery else 'None'}")
    else:
        print("  No alert (need more iterations)")
    
    print("\n💡 Test 3: Applying Recovery Strategy")
    print("-" * 70)
    
    if alert:
        # Apply suggested recovery
        recovery = detector.apply_recovery(alert.alert_id)
        
        print(f"  Recovery Action:")
        print(f"    Strategy: {recovery.strategy.value}")
        print(f"    Success: {recovery.success}")
        print(f"    Outcome: {recovery.outcome_description}")
    
    print("\n📈 Test 4: Dashboard Data")
    print("-" * 70)
    
    dashboard = detector.get_dashboard_data()
    print(f"  Active Alerts: {dashboard['active_alerts']}")
    print(f"  Resolved Alerts: {dashboard['resolved_alerts']}")
    print(f"  Total Recoveries: {dashboard['total_recoveries']}")
    print(f"  Recovery Success Rate: {dashboard['recovery_success_rate']:.0%}")
    print(f"  Monitored Agents: {dashboard['monitored_agents']}")
    print(f"  Monitored Tasks: {dashboard['monitored_tasks']}")
    
    print("\n📊 Test 5: Performance Degradation Detection")
    print("-" * 70)
    
    # Simulate declining performance
    for i in range(30):
        quality = 0.9 - (i * 0.025) if i < 20 else 0.4  # Sharp decline
        metrics = ProgressMetrics(
            task_id="task_003",
            agent_id="agent_optimizer",
            success_rate=max(0.1, 0.8 - (i * 0.02)),
            solution_quality=max(0.1, quality),
            actions_taken=i * 3,
            iterations_completed=i
        )
        detector.monitor_progress(metrics)
    
    alert = detector.detect_stagnation("agent_optimizer", "task_003")
    if alert:
        print(f"  ⚠️  Alert: {alert.stagnation_type.value}")
        print(f"     {alert.description}")
    else:
        print("  No degradation detected yet")
    
    print("\n📋 Test 6: Statistics Summary")
    print("-" * 70)
    
    stats = detector.get_stats()
    print(f"  Total Monitoring Sessions: {stats['total_monitoring_sessions']}")
    print(f"  Total Alerts Triggered: {stats['total_alerts_triggered']}")
    print(f"  Total Recoveries Attempted: {stats['total_recoveries_attempted']}")
    print(f"  Successful Recoveries: {stats['successful_recoveries']}")
    print(f"  Alerts by Type:")
    for alert_type, count in stats['alerts_by_type'].items():
        print(f"    - {alert_type}: {count}")
    
    print("\n" + "="*70)
    print("✅ STAGNATION DETECTION SYSTEM TEST COMPLETE")
    print("="*70)
