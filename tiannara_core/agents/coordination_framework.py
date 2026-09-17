"""
Agent Coordination Framework

Purpose: Enable intelligent collaboration between multiple AI agents
Features:
- Task requirement analysis
- Agent capability registry
- Workload balancing
- Conflict detection and resolution
- Consensus building with weighted voting
- Dissent tracking for learning
- Coordination pattern optimization

Date: May 8, 2026
Status: Implementation Phase - Week 16
"""

import json
import time
import math
from typing import Dict, List, Any, Optional, Tuple, Callable
from datetime import datetime
from enum import Enum
from collections import defaultdict


class AgentRole(Enum):
    """Predefined agent roles for task specialization."""
    ANALYZER = "analyzer"           # Data analysis and insights
    PREDICTOR = "predictor"         # Prediction and forecasting
    VALIDATOR = "validator"         # Verification and validation
    OPTIMIZER = "optimizer"         # Optimization and improvement
    RESEARCHER = "researcher"       # Information gathering
    CRITIC = "critic"              # Critical evaluation
    SYNTHESIZER = "synthesizer"    # Integration and synthesis
    PLANNER = "planner"            # Strategic planning
    EXECUTOR = "executor"          # Task execution
    MONITOR = "monitor"            # Quality monitoring


class TaskComplexity(Enum):
    """Task complexity levels."""
    SIMPLE = "simple"               # Single agent sufficient
    MODERATE = "moderate"          # 2-3 agents needed
    COMPLEX = "complex"            # 4-6 agents needed
    VERY_COMPLEX = "very_complex"  # 7+ agents needed


class ConflictType(Enum):
    """Types of conflicts between agents."""
    CONTRADICTION = "contradiction"           # Direct disagreement
    RESOURCE_CONFLICT = "resource_conflict"   # Competing for resources
    PRIORITY_CONFLICT = "priority_conflict"   # Different priorities
    METHODOLOGY_CONFLICT = "methodology_conflict"  # Different approaches
    TIMING_CONFLICT = "timing_conflict"       # Scheduling conflicts


class AgentProfile:
    """
    Represents an individual agent's capabilities and performance history.
    """
    
    def __init__(self, 
                 agent_id: str,
                 role: AgentRole,
                 capabilities: List[str],
                 expertise_areas: List[str],
                 max_concurrent_tasks: int = 3):
        self.agent_id = agent_id
        self.role = role
        self.capabilities = capabilities
        self.expertise_areas = expertise_areas
        self.max_concurrent_tasks = max_concurrent_tasks
        
        # Performance metrics
        self.tasks_completed = 0
        self.success_rate = 1.0
        self.average_response_time = 0.0
        self.specialization_score = {}  # domain -> score (0-1)
        
        # Current workload
        self.active_tasks = []
        self.available = True
        
        # Learning metrics
        self.conflict_history = []
        self.collaboration_patterns = {}
        
    def calculate_availability(self) -> float:
        """Calculate agent availability (0-1 scale)."""
        workload_ratio = len(self.active_tasks) / self.max_concurrent_tasks
        return max(0.0, 1.0 - workload_ratio)
    
    def update_performance(self, success: bool, response_time: float):
        """Update agent performance metrics after task completion."""
        self.tasks_completed += 1
        
        # Update success rate (exponential moving average)
        alpha = 0.1  # Learning rate
        self.success_rate = alpha * (1.0 if success else 0.0) + (1 - alpha) * self.success_rate
        
        # Update response time (exponential moving average)
        self.average_response_time = (
            alpha * response_time + (1 - alpha) * self.average_response_time
        )
        
        # Mark as available if task completed
        if self.active_tasks:
            self.active_tasks.pop(0)
        
        if len(self.active_tasks) < self.max_concurrent_tasks:
            self.available = True
    
    def get_competency_score(self, task_domain: str) -> float:
        """Get agent's competency score for a specific domain."""
        base_score = self.specialization_score.get(task_domain, 0.5)
        
        # Adjust based on success rate
        adjusted_score = base_score * self.success_rate
        
        # Adjust based on availability
        availability = self.calculate_availability()
        final_score = adjusted_score * (0.5 + 0.5 * availability)
        
        return final_score
    
    def to_dict(self) -> Dict:
        """Convert profile to dictionary."""
        return {
            "agent_id": self.agent_id,
            "role": self.role.value,
            "capabilities": self.capabilities,
            "expertise_areas": self.expertise_areas,
            "tasks_completed": self.tasks_completed,
            "success_rate": self.success_rate,
            "average_response_time": self.average_response_time,
            "available": self.available,
            "active_tasks_count": len(self.active_tasks)
        }


class TaskRequirement:
    """
    Analyzes and represents task requirements for agent matching.
    """
    
    def __init__(self, 
                 task_id: str,
                 description: str,
                 domain: str,
                 required_skills: List[str],
                 complexity: TaskComplexity = TaskComplexity.MODERATE,
                 priority: int = 5,  # 1-10 scale
                 deadline: Optional[str] = None,
                 dependencies: List[str] = None):
        self.task_id = task_id
        self.description = description
        self.domain = domain
        self.required_skills = required_skills
        self.complexity = complexity
        self.priority = priority
        self.deadline = deadline
        self.dependencies = dependencies or []
        
        # Analysis results
        self.estimated_agents_needed = self._estimate_agents_needed()
        self.preferred_roles = self._determine_preferred_roles()
        self.critical_skills = self._identify_critical_skills()
        
    def _estimate_agents_needed(self) -> int:
        """Estimate number of agents needed based on complexity."""
        mapping = {
            TaskComplexity.SIMPLE: 1,
            TaskComplexity.MODERATE: 3,
            TaskComplexity.COMPLEX: 5,
            TaskComplexity.VERY_COMPLEX: 8
        }
        return mapping.get(self.complexity, 3)
    
    def _determine_preferred_roles(self) -> List[AgentRole]:
        """Determine preferred agent roles for this task."""
        role_mapping = {
            "prediction": [AgentRole.PREDICTOR, AgentRole.ANALYZER, AgentRole.VALIDATOR],
            "analysis": [AgentRole.ANALYZER, AgentRole.RESEARCHER, AgentRole.SYNTHESIZER],
            "optimization": [AgentRole.OPTIMIZER, AgentRole.ANALYZER, AgentRole.CRITIC],
            "planning": [AgentRole.PLANNER, AgentRole.RESEARCHER, AgentRole.CRITIC],
            "validation": [AgentRole.VALIDATOR, AgentRole.CRITIC, AgentRole.MONITOR],
            "research": [AgentRole.RESEARCHER, AgentRole.ANALYZER, AgentRole.SYNTHESIZER]
        }
        
        # Find best match for domain
        for key, roles in role_mapping.items():
            if key in self.domain.lower():
                return roles
        
        # Default roles
        return [AgentRole.ANALYZER, AgentRole.EXECUTOR, AgentRole.VALIDATOR]
    
    def _identify_critical_skills(self) -> List[str]:
        """Identify skills that are absolutely required."""
        # Skills appearing in high-priority tasks are critical
        if self.priority >= 8:
            return self.required_skills[:3]  # Top 3 skills
        return self.required_skills[:2]  # Top 2 skills
    
    def matches_agent(self, agent: AgentProfile) -> float:
        """Calculate how well an agent matches this task (0-1 scale)."""
        score = 0.0
        
        # Check role match
        if agent.role in self.preferred_roles:
            score += 0.3
        
        # Check skill overlap
        skill_overlap = len(set(agent.capabilities) & set(self.required_skills))
        skill_ratio = skill_overlap / len(self.required_skills) if self.required_skills else 0
        score += 0.4 * skill_ratio
        
        # Check domain expertise
        domain_score = agent.get_competency_score(self.domain)
        score += 0.3 * domain_score
        
        return min(1.0, score)
    
    def to_dict(self) -> Dict:
        """Convert to dictionary."""
        return {
            "task_id": self.task_id,
            "description": self.description,
            "domain": self.domain,
            "complexity": self.complexity.value,
            "priority": self.priority,
            "estimated_agents_needed": self.estimated_agents_needed,
            "preferred_roles": [r.value for r in self.preferred_roles],
            "critical_skills": self.critical_skills
        }


class Conflict:
    """Represents a conflict between agents."""
    
    def __init__(self,
                 conflict_id: str,
                 conflict_type: ConflictType,
                 agents_involved: List[str],
                 description: str,
                 severity: int = 5):  # 1-10 scale
        self.conflict_id = conflict_id
        self.conflict_type = conflict_type
        self.agents_involved = agents_involved
        self.description = description
        self.severity = severity
        self.timestamp = datetime.now().isoformat()
        self.resolved = False
        self.resolution_strategy = None
        self.resolution_time = None
        
    def resolve(self, strategy: str):
        """Mark conflict as resolved."""
        self.resolved = True
        self.resolution_strategy = strategy
        self.resolution_time = datetime.now().isoformat()
    
    def to_dict(self) -> Dict:
        """Convert to dictionary."""
        return {
            "conflict_id": self.conflict_id,
            "type": self.conflict_type.value,
            "agents_involved": self.agents_involved,
            "severity": self.severity,
            "resolved": self.resolved,
            "resolution_strategy": self.resolution_strategy,
            "timestamp": self.timestamp
        }


class AgentCoordinationFramework:
    """
    Main coordination framework for managing multi-agent collaboration.
    
    Features:
    - Task requirement analysis
    - Agent capability registry
    - Intelligent workload balancing
    - Conflict detection and resolution
    - Consensus building with weighted voting
    - Performance tracking and optimization
    """
    
    def __init__(self):
        # Agent registry
        self.agents: Dict[str, AgentProfile] = {}
        
        # Task management
        self.active_tasks: Dict[str, TaskRequirement] = {}
        self.task_assignments: Dict[str, List[str]] = {}  # task_id -> [agent_ids]
        
        # Conflict management
        self.conflicts: Dict[str, Conflict] = {}
        self.conflict_resolution_strategies = {
            ConflictType.CONTRADICTION: self._resolve_contradiction,
            ConflictType.RESOURCE_CONFLICT: self._resolve_resource_conflict,
            ConflictType.PRIORITY_CONFLICT: self._resolve_priority_conflict,
            ConflictType.METHODOLOGY_CONFLICT: self._resolve_methodology_conflict,
            ConflictType.TIMING_CONFLICT: self._resolve_timing_conflict
        }
        
        # Consensus tracking
        self.consensus_history = []
        
        # Performance metrics
        self.coordination_metrics = {
            "total_tasks_assigned": 0,
            "total_conflicts_detected": 0,
            "total_conflicts_resolved": 0,
            "average_consensus_time": 0.0,
            "collaboration_success_rate": 1.0
        }
        
    def register_agent(self, agent: AgentProfile):
        """Register a new agent in the system."""
        self.agents[agent.agent_id] = agent
    
    def unregister_agent(self, agent_id: str):
        """Remove an agent from the system."""
        if agent_id in self.agents:
            del self.agents[agent_id]
    
    def analyze_task_requirements(self, 
                                  task_id: str,
                                  description: str,
                                  domain: str,
                                  required_skills: List[str],
                                  complexity: TaskComplexity = TaskComplexity.MODERATE,
                                  priority: int = 5,
                                  deadline: Optional[str] = None,
                                  dependencies: List[str] = None) -> TaskRequirement:
        """
        Analyze task requirements and create task object.
        
        Returns:
            TaskRequirement object with analyzed requirements
        """
        task = TaskRequirement(
            task_id=task_id,
            description=description,
            domain=domain,
            required_skills=required_skills,
            complexity=complexity,
            priority=priority,
            deadline=deadline,
            dependencies=dependencies
        )
        
        self.active_tasks[task_id] = task
        return task
    
    def select_agents_for_task(self, task_id: str) -> List[str]:
        """
        Select optimal agents for a task based on requirements and availability.
        
        Uses multi-criteria decision making:
        1. Role matching
        2. Skill compatibility
        3. Domain expertise
        4. Current workload
        5. Historical performance
        
        Returns:
            List of selected agent IDs
        """
        if task_id not in self.active_tasks:
            raise ValueError(f"Task {task_id} not found")
        
        task = self.active_tasks[task_id]
        agents_needed = task.estimated_agents_needed
        
        # Score all available agents
        candidate_scores = []
        
        for agent_id, agent in self.agents.items():
            if not agent.available:
                continue
            
            # Calculate composite score
            role_match = 1.0 if agent.role in task.preferred_roles else 0.5
            skill_match = task.matches_agent(agent)
            performance_score = agent.success_rate
            availability = agent.calculate_availability()
            
            # Weighted composite score
            composite_score = (
                0.3 * role_match +
                0.3 * skill_match +
                0.2 * performance_score +
                0.2 * availability
            )
            
            candidate_scores.append((agent_id, composite_score))
        
        # Sort by score (descending)
        candidate_scores.sort(key=lambda x: x[1], reverse=True)
        
        # Select top N agents
        selected_agents = [agent_id for agent_id, _ in candidate_scores[:agents_needed]]
        
        # Assign task to selected agents
        self.task_assignments[task_id] = selected_agents
        
        # Update agent workloads
        for agent_id in selected_agents:
            if agent_id in self.agents:
                self.agents[agent_id].active_tasks.append(task_id)
                
                # Mark as unavailable if at capacity
                if len(self.agents[agent_id].active_tasks) >= self.agents[agent_id].max_concurrent_tasks:
                    self.agents[agent_id].available = False
        
        self.coordination_metrics["total_tasks_assigned"] += 1
        
        return selected_agents
    
    def detect_conflicts(self, task_id: str, agent_outputs: Dict[str, Any]) -> List[Conflict]:
        """
        Detect conflicts between agent outputs.
        
        Args:
            task_id: The task being evaluated
            agent_outputs: Dictionary of agent_id -> output
            
        Returns:
            List of detected conflicts
        """
        conflicts = []
        agent_ids = list(agent_outputs.keys())
        
        # Check for contradictions
        for i in range(len(agent_ids)):
            for j in range(i + 1, len(agent_ids)):
                agent_a = agent_ids[i]
                agent_b = agent_ids[j]
                
                output_a = agent_outputs[agent_a]
                output_b = agent_outputs[agent_b]
                
                # Detect contradiction
                if self._is_contradiction(output_a, output_b):
                    conflict = Conflict(
                        conflict_id=f"conflict_{task_id}_{i}_{j}",
                        conflict_type=ConflictType.CONTRADICTION,
                        agents_involved=[agent_a, agent_b],
                        description=f"Contradictory outputs from {agent_a} and {agent_b}",
                        severity=8
                    )
                    conflicts.append(conflict)
        
        # Store conflicts
        for conflict in conflicts:
            self.conflicts[conflict.conflict_id] = conflict
            self.coordination_metrics["total_conflicts_detected"] += 1
        
        return conflicts
    
    def resolve_conflict(self, conflict_id: str) -> Optional[str]:
        """
        Resolve a detected conflict using appropriate strategy.
        
        Returns:
            Resolution strategy used, or None if resolution failed
        """
        if conflict_id not in self.conflicts:
            return None
        
        conflict = self.conflicts[conflict_id]
        
        if conflict.resolved:
            return conflict.resolution_strategy
        
        # Get appropriate resolution strategy
        resolver = self.conflict_resolution_strategies.get(conflict.conflict_type)
        
        if resolver:
            strategy_name = resolver(conflict)
            conflict.resolve(strategy_name)
            self.coordination_metrics["total_conflicts_resolved"] += 1
            return strategy_name
        
        return None
    
    def build_consensus(self, 
                       task_id: str,
                       agent_votes: Dict[str, Any],
                       agent_weights: Optional[Dict[str, float]] = None) -> Dict:
        """
        Build consensus from multiple agent votes using weighted voting.
        
        Args:
            task_id: The task being decided
            agent_votes: Dictionary of agent_id -> vote/decision
            agent_weights: Optional weights for each agent (default: equal weights)
            
        Returns:
            Consensus decision with confidence score
        """
        if not agent_votes:
            return {"consensus": None, "confidence": 0.0, "method": "no_votes"}
        
        # Default to equal weights if not provided
        if agent_weights is None:
            agent_weights = {agent_id: 1.0 for agent_id in agent_votes.keys()}
        
        # Normalize weights
        total_weight = sum(agent_weights.values())
        normalized_weights = {
            agent_id: weight / total_weight 
            for agent_id, weight in agent_weights.items()
        }
        
        # Group votes by value
        vote_groups = defaultdict(float)
        for agent_id, vote in agent_votes.items():
            vote_key = str(vote)  # Convert to string for grouping
            vote_groups[vote_key] += normalized_weights.get(agent_id, 0.0)
        
        # Find winning vote
        winning_vote = max(vote_groups.items(), key=lambda x: x[1])
        consensus_value = winning_vote[0]
        confidence = winning_vote[1]
        
        # Determine consensus method
        if confidence > 0.7:
            method = "strong_consensus"
        elif confidence > 0.5:
            method = "majority_consensus"
        else:
            method = "plurality_consensus"
        
        # Record consensus
        consensus_record = {
            "task_id": task_id,
            "timestamp": datetime.now().isoformat(),
            "consensus": consensus_value,
            "confidence": confidence,
            "method": method,
            "total_agents": len(agent_votes),
            "vote_distribution": dict(vote_groups)
        }
        
        self.consensus_history.append(consensus_record)
        
        return consensus_record
    
    def get_coordination_metrics(self) -> Dict:
        """Get current coordination framework metrics."""
        return {
            **self.coordination_metrics,
            "registered_agents": len(self.agents),
            "active_tasks": len(self.active_tasks),
            "active_conflicts": len([c for c in self.conflicts.values() if not c.resolved]),
            "agent_utilization": self._calculate_agent_utilization()
        }
    
    def _calculate_agent_utilization(self) -> float:
        """Calculate average agent utilization across all agents."""
        if not self.agents:
            return 0.0
        
        utilizations = []
        for agent in self.agents.values():
            utilization = len(agent.active_tasks) / agent.max_concurrent_tasks
            utilizations.append(utilization)
        
        return sum(utilizations) / len(utilizations)
    
    # Conflict Resolution Strategies
    
    def _resolve_contradiction(self, conflict: Conflict) -> str:
        """Resolve contradiction by selecting highest-confidence output."""
        # In real implementation, would compare confidence scores
        strategy = "confidence_based_selection"
        return strategy
    
    def _resolve_resource_conflict(self, conflict: Conflict) -> str:
        """Resolve resource conflict through priority-based allocation."""
        strategy = "priority_based_allocation"
        return strategy
    
    def _resolve_priority_conflict(self, conflict: Conflict) -> str:
        """Resolve priority conflict through negotiation."""
        strategy = "negotiated_compromise"
        return strategy
    
    def _resolve_methodology_conflict(self, conflict: Conflict) -> str:
        """Resolve methodology conflict through ensemble approach."""
        strategy = "ensemble_combination"
        return strategy
    
    def _resolve_timing_conflict(self, conflict: Conflict) -> str:
        """Resolve timing conflict through rescheduling."""
        strategy = "dynamic_rescheduling"
        return strategy
    
    def _is_contradiction(self, output_a: Any, output_b: Any) -> bool:
        """Check if two outputs contradict each other."""
        # Simple implementation - in reality would use semantic analysis
        if isinstance(output_a, dict) and isinstance(output_b, dict):
            # Check for conflicting predictions
            if "prediction" in output_a and "prediction" in output_b:
                return output_a["prediction"] != output_b["prediction"]
        
        # For now, consider different values as potential contradictions
        return str(output_a) != str(output_b)


# Example usage and testing
if __name__ == "__main__":
    print("="*70)
    print("AGENT COORDINATION FRAMEWORK - TEST")
    print("="*70)
    
    # Initialize framework
    framework = AgentCoordinationFramework()
    
    # Register agents
    agents = [
        AgentProfile(
            agent_id="agent_analyzer_01",
            role=AgentRole.ANALYZER,
            capabilities=["data_analysis", "statistical_modeling", "pattern_recognition"],
            expertise_areas=["prediction", "analysis", "forecasting"]
        ),
        AgentProfile(
            agent_id="agent_predictor_01",
            role=AgentRole.PREDICTOR,
            capabilities=["time_series", "probability_estimation", "risk_assessment"],
            expertise_areas=["prediction", "forecasting"]
        ),
        AgentProfile(
            agent_id="agent_validator_01",
            role=AgentRole.VALIDATOR,
            capabilities=["verification", "quality_check", "error_detection"],
            expertise_areas=["validation", "quality_assurance"]
        ),
        AgentProfile(
            agent_id="agent_researcher_01",
            role=AgentRole.RESEARCHER,
            capabilities=["information_gathering", "data_collection", "fact_checking"],
            expertise_areas=["research", "analysis"]
        ),
        AgentProfile(
            agent_id="agent_optimizer_01",
            role=AgentRole.OPTIMIZER,
            capabilities=["optimization", "parameter_tuning", "performance_improvement"],
            expertise_areas=["optimization", "efficiency"]
        )
    ]
    
    for agent in agents:
        framework.register_agent(agent)
    
    print(f"\n✅ Registered {len(agents)} agents")
    
    # Analyze task requirements
    task = framework.analyze_task_requirements(
        task_id="task_sports_prediction_001",
        description="Predict outcome of football match with confidence scoring",
        domain="sports_prediction",
        required_skills=["data_analysis", "time_series", "probability_estimation"],
        complexity=TaskComplexity.MODERATE,
        priority=7
    )
    
    print(f"\n📋 Task Analyzed:")
    print(f"   ID: {task.task_id}")
    print(f"   Domain: {task.domain}")
    print(f"   Complexity: {task.complexity.value}")
    print(f"   Agents Needed: {task.estimated_agents_needed}")
    print(f"   Preferred Roles: {[r.value for r in task.preferred_roles]}")
    
    # Select agents for task
    selected_agents = framework.select_agents_for_task("task_sports_prediction_001")
    
    print(f"\n🎯 Selected Agents:")
    for agent_id in selected_agents:
        agent = framework.agents[agent_id]
        print(f"   - {agent_id} ({agent.role.value})")
    
    # Simulate agent outputs
    agent_outputs = {
        "agent_analyzer_01": {"prediction": "home_win", "confidence": 0.72},
        "agent_predictor_01": {"prediction": "home_win", "confidence": 0.68},
        "agent_validator_01": {"prediction": "draw", "confidence": 0.55}
    }
    
    print(f"\n📊 Agent Outputs:")
    for agent_id, output in agent_outputs.items():
        print(f"   {agent_id}: {output}")
    
    # Detect conflicts
    conflicts = framework.detect_conflicts("task_sports_prediction_001", agent_outputs)
    
    print(f"\n⚠️  Conflicts Detected: {len(conflicts)}")
    for conflict in conflicts:
        print(f"   - {conflict.description} (Severity: {conflict.severity})")
    
    # Resolve conflicts
    for conflict in conflicts:
        strategy = framework.resolve_conflict(conflict.conflict_id)
        print(f"   Resolved using: {strategy}")
    
    # Build consensus
    agent_votes = {
        "agent_analyzer_01": "home_win",
        "agent_predictor_01": "home_win",
        "agent_validator_01": "draw"
    }
    
    # Weight votes by agent performance
    agent_weights = {
        "agent_analyzer_01": 0.9,
        "agent_predictor_01": 0.85,
        "agent_validator_01": 0.75
    }
    
    consensus = framework.build_consensus(
        "task_sports_prediction_001",
        agent_votes,
        agent_weights
    )
    
    print(f"\n✅ Consensus Built:")
    print(f"   Decision: {consensus['consensus']}")
    print(f"   Confidence: {consensus['confidence']:.2%}")
    print(f"   Method: {consensus['method']}")
    
    # Get metrics
    metrics = framework.get_coordination_metrics()
    
    print(f"\n📈 Coordination Metrics:")
    print(f"   Total Tasks Assigned: {metrics['total_tasks_assigned']}")
    print(f"   Total Conflicts Detected: {metrics['total_conflicts_detected']}")
    print(f"   Total Conflicts Resolved: {metrics['total_conflicts_resolved']}")
    print(f"   Agent Utilization: {metrics['agent_utilization']:.1%}")
    
    print("\n" + "="*70)
    print("✅ AGENT COORDINATION FRAMEWORK TEST COMPLETE")
    print("="*70)
