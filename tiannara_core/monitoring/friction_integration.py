"""
DELIBERATE FRICTION INTEGRATION

Purpose: Auto-select reasoning modes based on task context and coordinate
multi-agent deliberation with controlled friction.

Based on next.md (lines 231-265):
"Most systems fail because they optimize too aggressively.
You need anti-optimization architecture."

Architecture:
Extends the existing DeliberateFrictionSystem with:
1. Automatic mode selection based on task characteristics
2. Multi-agent coordination with diverse reasoning modes
3. Friction level monitoring and adjustment
4. Integration with health metrics and reality anchors
"""

import time
import logging
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, field
from enum import Enum

logger = logging.getLogger(__name__)

# Import existing friction system
from tiannara_core.monitoring.deliberate_friction import (
    DeliberateFrictionSystem,
    ReasoningMode,
    ModeConfiguration,
    MODE_CONFIGS
)


class TaskComplexity(Enum):
    """Task complexity levels for mode selection."""
    SIMPLE = "simple"               # Straightforward, low uncertainty
    MODERATE = "moderate"           # Some complexity, moderate uncertainty
    COMPLEX = "complex"             # High complexity, significant uncertainty
    CRITICAL = "critical"           # High-stakes, must be correct


class RiskLevel(Enum):
    """Risk level for automatic mode escalation."""
    LOW = "low"                     # Low consequences if wrong
    MEDIUM = "medium"               # Moderate consequences
    HIGH = "high"                   # Serious consequences if wrong
    CRITICAL = "critical"           # Catastrophic if wrong


@dataclass
class TaskContext:
    """Context information about a reasoning task."""
    task_id: str
    description: str
    domain: str                     # e.g., "physics", "economics", "ethics"
    complexity: TaskComplexity
    risk_level: RiskLevel
    time_constraint: Optional[float] = None  # Deadline in seconds (None = no constraint)
    available_evidence_count: int = 0
    prior_failure_history: bool = False      # Has this type failed before?
    requires_creativity: bool = False        # Needs novel solutions?
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class ModeSelection:
    """Result of automatic mode selection."""
    task_id: str
    selected_mode: ReasoningMode
    confidence: float               # Confidence in mode selection
    rationale: str                  # Why this mode was chosen
    alternative_modes: List[ReasoningMode]  # Other modes to consider
    estimated_completion_time: float  # Expected time to complete
    friction_level: float           # 0.0 (no friction) to 1.0 (maximum friction)


@dataclass
class MultiAgentDeliberation:
    """Results from multi-agent deliberation with diverse modes."""
    task_id: str
    participating_agents: Dict[str, ReasoningMode]  # agent_id -> mode
    individual_conclusions: Dict[str, Any]          # agent_id -> conclusion
    consensus_reached: bool
    consensus_confidence: float
    disagreement_points: List[str]
    synthesis: Optional[Any] = None
    deliberation_rounds: int = 0
    timestamp: float = field(default_factory=time.time)


class FrictionIntegration:
    """
    Integrates deliberate friction with automatic mode selection and multi-agent coordination.
    
    Prevents:
    - Monoculture cognition (all agents thinking the same way)
    - Premature optimization (rushing to conclusions)
    - Deceptive shortcuts (taking easy but wrong paths)
    - Reward hacking (gaming metrics instead of solving problems)
    """
    
    def __init__(self, friction_system: Optional[DeliberateFrictionSystem] = None):
        """
        Initialize friction integration.
        
        Args:
            friction_system: Existing deliberate friction system (creates new if None)
        """
        self.friction_system = friction_system or DeliberateFrictionSystem()
        self.mode_selections: Dict[str, ModeSelection] = {}
        self.deliberations: Dict[str, MultiAgentDeliberation] = {}
        
        logger.info(f"[Friction Integration] Initialized with {len(MODE_CONFIGS)} reasoning modes")
    
    def select_mode(self, task_context: TaskContext) -> ModeSelection:
        """
        Automatically select the best reasoning mode for a task.
        
        Decision logic based on:
        - Task complexity
        - Risk level
        - Time constraints
        - Evidence availability
        - Failure history
        
        Args:
            task_context: Information about the task
            
        Returns:
            ModeSelection with chosen mode and rationale
        """
        import uuid
        
        task_id = task_context.task_id or f"TASK_{uuid.uuid4().hex[:8]}"
        
        # Mode selection logic
        selected_mode, confidence, rationale = self._determine_optimal_mode(task_context)
        
        # Determine alternative modes for diversity
        alternative_modes = self._get_alternative_modes(selected_mode, task_context)
        
        # Estimate completion time based on mode friction
        base_time = task_context.time_constraint or 3600  # Default 1 hour
        friction_multiplier = self._get_friction_multiplier(selected_mode)
        estimated_time = base_time * friction_multiplier
        
        # Calculate friction level
        friction_level = self._calculate_friction_level(selected_mode)
        
        selection = ModeSelection(
            task_id=task_id,
            selected_mode=selected_mode,
            confidence=confidence,
            rationale=rationale,
            alternative_modes=alternative_modes,
            estimated_completion_time=estimated_time,
            friction_level=friction_level
        )
        
        self.mode_selections[task_id] = selection
        
        logger.info(f"[Mode Selection] Task: {task_id}")
        logger.info(f"  Selected Mode: {selected_mode.value}")
        logger.info(f"  Confidence: {confidence:.2f}")
        logger.info(f"  Rationale: {rationale}")
        logger.info(f"  Friction Level: {friction_level:.2f}")
        logger.info(f"  Estimated Time: {estimated_time:.0f}s")
        
        return selection
    
    def _determine_optimal_mode(self, context: TaskContext) -> Tuple[ReasoningMode, float, str]:
        """Determine the optimal reasoning mode based on task context."""
        
        # Critical risk always uses conservative mode
        if context.risk_level == RiskLevel.CRITICAL:
            return (
                ReasoningMode.CONSERVATIVE,
                0.95,
                "Critical risk level requires maximum evidence and caution"
            )
        
        # High risk with complexity uses skeptical mode
        if context.risk_level == RiskLevel.HIGH and context.complexity in [TaskComplexity.COMPLEX, TaskComplexity.CRITICAL]:
            return (
                ReasoningMode.SKEPTICAL,
                0.90,
                "High risk + complexity requires aggressive assumption challenging"
            )
        
        # Creative tasks with moderate risk
        if context.requires_creativity and context.risk_level in [RiskLevel.LOW, RiskLevel.MEDIUM]:
            return (
                ReasoningMode.CREATIVE,
                0.85,
                "Creativity requirement allows weak-signal synthesis"
            )
        
        # Complex tasks without high risk use exploratory mode
        if context.complexity in [TaskComplexity.COMPLEX, TaskComplexity.CRITICAL]:
            return (
                ReasoningMode.EXPLORATORY,
                0.80,
                "High complexity requires maximizing idea diversity"
            )
        
        # Tasks with failure history use arbitration
        if context.prior_failure_history:
            return (
                ReasoningMode.ARBITRATION,
                0.85,
                "Prior failures require comparing competing frameworks"
            )
        
        # Moderate complexity with medium risk
        if context.complexity == TaskComplexity.MODERATE and context.risk_level == RiskLevel.MEDIUM:
            return (
                ReasoningMode.SKEPTICAL,
                0.75,
                "Moderate complexity benefits from assumption challenging"
            )
        
        # Simple tasks with low risk can use creative/exploratory
        if context.complexity == TaskComplexity.SIMPLE and context.risk_level == RiskLevel.LOW:
            return (
                ReasoningMode.EXPLORATORY,
                0.70,
                "Simple task allows exploration without excessive friction"
            )
        
        # Default: arbitration for balanced approach
        return (
            ReasoningMode.ARBITRATION,
            0.65,
            "Default balanced approach comparing multiple perspectives"
        )
    
    def _get_alternative_modes(self, primary: ReasoningMode, context: TaskContext) -> List[ReasoningMode]:
        """Get alternative modes to consider for diversity."""
        all_modes = list(ReasoningMode)
        alternatives = [m for m in all_modes if m != primary]
        
        # Prioritize alternatives based on context
        if context.requires_creativity:
            # Move CREATIVE to front if not primary
            if ReasoningMode.CREATIVE in alternatives:
                alternatives.remove(ReasoningMode.CREATIVE)
                alternatives.insert(0, ReasoningMode.CREATIVE)
        
        if context.risk_level in [RiskLevel.HIGH, RiskLevel.CRITICAL]:
            # Prioritize CONSERVATIVE and SKEPTICAL
            safe_modes = [ReasoningMode.CONSERVATIVE, ReasoningMode.SKEPTICAL]
            for mode in safe_modes:
                if mode in alternatives and mode != primary:
                    alternatives.remove(mode)
                    alternatives.insert(0, mode)
        
        return alternatives[:3]  # Return top 3 alternatives
    
    def _get_friction_multiplier(self, mode: ReasoningMode) -> float:
        """Get time multiplier based on mode friction level."""
        multipliers = {
            ReasoningMode.EXPLORATORY: 1.5,   # 50% more time for exploration
            ReasoningMode.SKEPTICAL: 2.0,     # 2x time for thorough skepticism
            ReasoningMode.CONSERVATIVE: 2.5,  # 2.5x time for conservative approach
            ReasoningMode.CREATIVE: 1.3,      # 30% more time for creativity
            ReasoningMode.ARBITRATION: 1.8    # 80% more time for comparison
        }
        return multipliers.get(mode, 1.5)
    
    def _calculate_friction_level(self, mode: ReasoningMode) -> float:
        """Calculate friction level (0.0-1.0) for a mode."""
        levels = {
            ReasoningMode.EXPLORATORY: 0.4,
            ReasoningMode.SKEPTICAL: 0.8,
            ReasoningMode.CONSERVATIVE: 0.95,
            ReasoningMode.CREATIVE: 0.5,
            ReasoningMode.ARBITRATION: 0.7
        }
        return levels.get(mode, 0.5)
    
    def coordinate_multi_agent_deliberation(
        self,
        task_context: TaskContext,
        num_agents: int = 3,
        max_rounds: int = 5
    ) -> MultiAgentDeliberation:
        """
        Coordinate multiple agents with diverse reasoning modes.
        
        Each agent uses a different reasoning mode to ensure cognitive diversity.
        
        Args:
            task_context: Information about the task
            num_agents: Number of agents to deploy (default 3)
            max_rounds: Maximum deliberation rounds
            
        Returns:
            MultiAgentDeliberation with results from all agents
        """
        import uuid
        
        task_id = task_context.task_id or f"TASK_{uuid.uuid4().hex[:8]}"
        
        # Select diverse modes for agents
        primary_selection = self.select_mode(task_context)
        assigned_modes = [primary_selection.selected_mode]
        
        # Assign alternative modes to other agents
        for alt_mode in primary_selection.alternative_modes:
            if len(assigned_modes) < num_agents:
                assigned_modes.append(alt_mode)
        
        # Fill remaining agents with diverse modes if needed
        all_modes = list(ReasoningMode)
        while len(assigned_modes) < num_agents:
            for mode in all_modes:
                if mode not in assigned_modes:
                    assigned_modes.append(mode)
                    if len(assigned_modes) >= num_agents:
                        break
        
        # Simulate agent deliberation (in production, would run actual agents)
        participating_agents = {}
        individual_conclusions = {}
        
        for i, mode in enumerate(assigned_modes):
            agent_id = f"AGENT_{i+1}"
            participating_agents[agent_id] = mode
            
            # Simulate agent reasoning with assigned mode
            conclusion = self._simulate_agent_reasoning(task_context, mode)
            individual_conclusions[agent_id] = conclusion
        
        # Check for consensus
        consensus_reached, consensus_confidence = self._check_consensus(individual_conclusions)
        
        # Identify disagreement points
        disagreement_points = self._identify_disagreements(individual_conclusions)
        
        # Synthesize if consensus reached or after max rounds
        synthesis = None
        if consensus_reached or len(disagreement_points) == 0:
            synthesis = self._synthesize_conclusions(individual_conclusions)
        
        deliberation = MultiAgentDeliberation(
            task_id=task_id,
            participating_agents=participating_agents,
            individual_conclusions=individual_conclusions,
            consensus_reached=consensus_reached,
            consensus_confidence=consensus_confidence,
            disagreement_points=disagreement_points,
            synthesis=synthesis,
            deliberation_rounds=max_rounds
        )
        
        self.deliberations[task_id] = deliberation
        
        logger.info(f"[Multi-Agent Deliberation] Task: {task_id}")
        logger.info(f"  Agents Deployed: {len(participating_agents)}")
        for agent_id, mode in participating_agents.items():
            logger.info(f"    - {agent_id}: {mode.value}")
        logger.info(f"  Consensus: {'YES' if consensus_reached else 'NO'} (confidence: {consensus_confidence:.2f})")
        logger.info(f"  Disagreement Points: {len(disagreement_points)}")
        
        return deliberation
    
    def _simulate_agent_reasoning(self, context: TaskContext, mode: ReasoningMode) -> Dict[str, Any]:
        """Simulate agent reasoning with a specific mode."""
        # In production, this would run actual agent with mode configuration
        import random
        
        # Get mode configuration
        config = MODE_CONFIGS.get(mode)
        
        # Simulate conclusion based on mode characteristics
        if mode == ReasoningMode.CONSERVATIVE:
            confidence = random.uniform(config.min_confidence_threshold, 0.95)
            conclusion_type = "cautious"
        elif mode == ReasoningMode.SKEPTICAL:
            confidence = random.uniform(0.5, config.min_confidence_threshold)
            conclusion_type = "challenging"
        elif mode == ReasoningMode.CREATIVE:
            confidence = random.uniform(0.4, 0.7)
            conclusion_type = "novel"
        elif mode == ReasoningMode.EXPLORATORY:
            confidence = random.uniform(0.3, 0.6)
            conclusion_type = "diverse"
        else:  # ARBITRATION
            confidence = random.uniform(0.6, 0.85)
            conclusion_type = "balanced"
        
        return {
            "mode": mode.value,
            "conclusion_type": conclusion_type,
            "confidence": confidence,
            "evidence_used": random.randint(config.min_evidence_count, config.min_evidence_count + 5),
            "alternatives_generated": config.require_alternatives
        }
    
    def _check_consensus(self, conclusions: Dict[str, Any]) -> Tuple[bool, float]:
        """Check if agents have reached consensus."""
        if not conclusions:
            return False, 0.0
        
        # Extract confidence values
        confidences = [c.get("confidence", 0.5) for c in conclusions.values()]
        
        # Calculate agreement based on confidence similarity
        avg_confidence = sum(confidences) / len(confidences)
        confidence_variance = sum((c - avg_confidence) ** 2 for c in confidences) / len(confidences)
        
        # Low variance = high agreement
        agreement_score = max(0.0, 1.0 - confidence_variance * 10)
        
        # Consensus threshold: >0.7 agreement
        consensus_reached = agreement_score > 0.7
        
        return consensus_reached, agreement_score
    
    def _identify_disagreements(self, conclusions: Dict[str, Any]) -> List[str]:
        """Identify points of disagreement between agents."""
        disagreements = []
        
        # Check for different conclusion types
        conclusion_types = set(c.get("conclusion_type", "") for c in conclusions.values())
        if len(conclusion_types) > 1:
            disagreements.append(f"Different reasoning approaches: {', '.join(conclusion_types)}")
        
        # Check for confidence disparities
        confidences = [c.get("confidence", 0.5) for c in conclusions.values()]
        if max(confidences) - min(confidences) > 0.3:
            disagreements.append(f"Significant confidence disparity: {min(confidences):.2f} vs {max(confidences):.2f}")
        
        # Check for evidence count differences
        evidence_counts = [c.get("evidence_used", 0) for c in conclusions.values()]
        if max(evidence_counts) - min(evidence_counts) > 3:
            disagreements.append(f"Evidence usage varies significantly: {min(evidence_counts)} vs {max(evidence_counts)}")
        
        return disagreements
    
    def _synthesize_conclusions(self, conclusions: Dict[str, Any]) -> Dict[str, Any]:
        """Synthesize conclusions from multiple agents."""
        if not conclusions:
            return {}
        
        # Weight by confidence
        weighted_confidence = sum(
            c.get("confidence", 0.5) for c in conclusions.values()
        ) / len(conclusions)
        
        # Average evidence usage
        avg_evidence = sum(
            c.get("evidence_used", 0) for c in conclusions.values()
        ) / len(conclusions)
        
        return {
            "synthesis_type": "weighted_average",
            "confidence": weighted_confidence,
            "avg_evidence_used": avg_evidence,
            "num_contributors": len(conclusions),
            "timestamp": time.time()
        }
    
    def get_integration_statistics(self) -> Dict[str, Any]:
        """Get statistics about friction integration."""
        mode_counts = {}
        for selection in self.mode_selections.values():
            mode_name = selection.selected_mode.value
            mode_counts[mode_name] = mode_counts.get(mode_name, 0) + 1
        
        consensus_count = sum(
            1 for d in self.deliberations.values() if d.consensus_reached
        )
        
        return {
            "total_mode_selections": len(self.mode_selections),
            "total_deliberations": len(self.deliberations),
            "mode_distribution": mode_counts,
            "consensus_rate": consensus_count / max(1, len(self.deliberations)),
            "avg_friction_level": sum(
                s.friction_level for s in self.mode_selections.values()
            ) / max(1, len(self.mode_selections))
        }
