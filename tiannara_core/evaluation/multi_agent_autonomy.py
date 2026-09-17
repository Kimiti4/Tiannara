"""
Multi-Agent Autonomy System for Tiannara Evaluation.

Implements upgrades.md requirement for autonomous agents:
- Sub-agent spawning for parallel execution
- High-level command decomposition
- Autonomous path planning
- Dynamic orchestration with load balancing

This enables the system to tackle complex tasks by breaking them down
and distributing work across specialized agents.
"""

import time
import uuid
from typing import Dict, List, Any, Optional, Callable
from dataclasses import dataclass, field
from enum import Enum
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading


class AgentState(Enum):
    """Possible states for an agent."""
    IDLE = "idle"
    WORKING = "working"
    WAITING = "waiting"
    COMPLETED = "completed"
    FAILED = "failed"


class AgentRole(Enum):
    """Specialized roles for agents."""
    PLANNER = "planner"
    EXECUTOR = "executor"
    CRITIC = "critic"
    ORCHESTRATOR = "orchestrator"


@dataclass
class AgentTask:
    """Represents a task assigned to an agent."""
    task_id: str
    description: str
    task_type: str
    inputs: Dict[str, Any]
    priority: int = 0  # Higher = more important
    deadline: Optional[float] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class AgentResult:
    """Result from an agent's work."""
    task_id: str
    agent_id: str
    success: bool
    output: Any = None
    error: Optional[str] = None
    confidence: float = 0.0
    execution_time: float = 0.0
    timestamp: float = field(default_factory=time.time)


class SubAgent:
    """
    Individual agent that can execute tasks.
    
    Each agent has a specific role and can work on assigned tasks.
    Agents report results back to the orchestrator.
    """
    
    def __init__(self, agent_id: str, role: AgentRole, capabilities: List[str]):
        """
        Initialize sub-agent.
        
        Args:
            agent_id: Unique identifier
            role: Agent's specialization
            capabilities: List of task types this agent can handle
        """
        self.agent_id = agent_id
        self.role = role
        self.capabilities = capabilities
        self.state = AgentState.IDLE
        self.current_task: Optional[AgentTask] = None
        self.completed_tasks = 0
        self.failed_tasks = 0
        
        # Performance tracking
        self.total_execution_time = 0.0
        self.avg_confidence = 0.0
        
    def can_handle(self, task: AgentTask) -> bool:
        """Check if this agent can handle the given task."""
        return task.task_type in self.capabilities
    
    def execute_task(self, task: AgentTask, executor_func: Callable) -> AgentResult:
        """
        Execute a task using the provided executor function.
        
        Args:
            task: Task to execute
            executor_func: Function that performs the actual work
            
        Returns:
            AgentResult with outcome
        """
        self.state = AgentState.WORKING
        self.current_task = task
        start_time = time.time()
        
        try:
            # Execute the task
            result = executor_func(task.inputs)
            
            execution_time = time.time() - start_time
            self.total_execution_time += execution_time
            self.completed_tasks += 1
            self.state = AgentState.COMPLETED
            
            return AgentResult(
                task_id=task.task_id,
                agent_id=self.agent_id,
                success=True,
                output=result,
                confidence=0.9,  # Default confidence
                execution_time=execution_time
            )
            
        except Exception as e:
            execution_time = time.time() - start_time
            self.total_execution_time += execution_time
            self.failed_tasks += 1
            self.state = AgentState.FAILED
            
            return AgentResult(
                task_id=task.task_id,
                agent_id=self.agent_id,
                success=False,
                error=str(e),
                execution_time=execution_time
            )
        
        finally:
            self.current_task = None
            self.state = AgentState.IDLE
    
    def get_stats(self) -> Dict[str, Any]:
        """Get agent performance statistics."""
        total_tasks = self.completed_tasks + self.failed_tasks
        success_rate = (
            self.completed_tasks / total_tasks
            if total_tasks > 0 else 0
        )
        
        return {
            "agent_id": self.agent_id,
            "role": self.role.value,
            "state": self.state.value,
            "capabilities": self.capabilities,
            "completed_tasks": self.completed_tasks,
            "failed_tasks": self.failed_tasks,
            "success_rate": success_rate,
            "avg_execution_time": (
                self.total_execution_time / total_tasks
                if total_tasks > 0 else 0
            )
        }


class TaskDecomposer:
    """
    Decomposes high-level commands into sub-tasks for agents.
    
    Takes complex tasks and breaks them down into smaller,
    parallelizable units that can be distributed to agents.
    """
    
    def __init__(self):
        self.decomposition_rules: Dict[str, Callable] = {}
    
    def register_rule(self, task_type: str, decomposer_func: Callable):
        """
        Register a decomposition rule for a task type.
        
        Args:
            task_type: Type of task this rule handles
            decomposer_func: Function that decomposes the task
        """
        self.decomposition_rules[task_type] = decomposer_func
    
    def decompose(self, high_level_task: AgentTask) -> List[AgentTask]:
        """
        Decompose a high-level task into sub-tasks.
        
        Args:
            high_level_task: Complex task to break down
            
        Returns:
            List of sub-tasks
        """
        # Check if we have a specific rule for this task type
        if high_level_task.task_type in self.decomposition_rules:
            return self.decomposition_rules[high_level_task.task_type](high_level_task)
        
        # Default: no decomposition needed
        return [high_level_task]
    
    def decompose_multi_domain(self, task: AgentTask) -> List[AgentTask]:
        """
        Example: Decompose multi-domain task into domain-specific sub-tasks.
        
        This is a sample decomposition strategy.
        """
        domains = task.metadata.get("domains", [])
        sub_tasks = []
        
        for i, domain in enumerate(domains):
            sub_task = AgentTask(
                task_id=f"{task.task_id}_sub_{i}",
                description=f"Solve {domain} component of {task.description}",
                task_type=domain,
                inputs=task.inputs.copy(),
                priority=task.priority,
                metadata={"parent_task": task.task_id, "domain": domain}
            )
            sub_tasks.append(sub_task)
        
        return sub_tasks


class AgentOrchestrator:
    """
    Main orchestrator for multi-agent system.
    
    Manages agent pool, distributes tasks, collects results,
    and provides autonomous decision-making.
    """
    
    def __init__(self, max_workers: int = 4):
        """
        Initialize orchestrator.
        
        Args:
            max_workers: Maximum number of parallel agents
        """
        self.max_workers = max_workers
        self.agents: Dict[str, SubAgent] = {}
        self.decomposer = TaskDecomposer()
        self.executor = ThreadPoolExecutor(max_workers=max_workers)
        
        # Task tracking
        self.pending_tasks: List[AgentTask] = []
        self.completed_results: Dict[str, AgentResult] = {}
        
        # Statistics
        self.total_tasks_submitted = 0
        self.total_tasks_completed = 0
        self.lock = threading.Lock()
        
        # Auto-spawn default agents
        self._spawn_default_agents()
    
    def _spawn_default_agents(self):
        """Spawn default set of agents with different capabilities."""
        # Algorithm specialist
        self.spawn_agent(
            role=AgentRole.EXECUTOR,
            capabilities=["sorting", "arithmetic", "search", "optimization", "graph", "string_transform"]
        )
        
        # Logic specialist
        self.spawn_agent(
            role=AgentRole.EXECUTOR,
            capabilities=["pattern_recognition", "boolean_logic", "sequence_completion", "logical_deduction"]
        )
        
        # Reverse engineering specialist
        self.spawn_agent(
            role=AgentRole.EXECUTOR,
            capabilities=["reverse_engineering"]
        )
        
        # Causal specialist
        self.spawn_agent(
            role=AgentRole.EXECUTOR,
            capabilities=["causal_system"]
        )
        
        # Critic agent for validation
        self.spawn_agent(
            role=AgentRole.CRITIC,
            capabilities=["validation", "verification"]
        )
    
    def spawn_agent(self, role: AgentRole, capabilities: List[str]) -> str:
        """
        Spawn a new agent with specified capabilities.
        
        Args:
            role: Agent's role
            capabilities: What the agent can do
            
        Returns:
            Agent ID
        """
        agent_id = f"agent_{uuid.uuid4().hex[:8]}"
        agent = SubAgent(agent_id, role, capabilities)
        self.agents[agent_id] = agent
        return agent_id
    
    def submit_task(self, task: AgentTask) -> str:
        """
        Submit a task for execution.
        
        Args:
            task: Task to execute
            
        Returns:
            Task ID
        """
        with self.lock:
            self.pending_tasks.append(task)
            self.total_tasks_submitted += 1
        
        return task.task_id
    
    def submit_and_execute(self, task: AgentTask, executor_func: Callable) -> AgentResult:
        """
        Submit task and execute it immediately (synchronous).
        
        Args:
            task: Task to execute
            executor_func: Function to execute the task
            
        Returns:
            Result from execution
        """
        # Find best agent for this task
        best_agent = self._select_best_agent(task)
        
        if best_agent is None:
            return AgentResult(
                task_id=task.task_id,
                agent_id="none",
                success=False,
                error="No suitable agent found"
            )
        
        # Execute task
        result = best_agent.execute_task(task, executor_func)
        
        with self.lock:
            self.completed_results[task.task_id] = result
            self.total_tasks_completed += 1
        
        return result
    
    def execute_parallel(self, tasks: List[AgentTask], executor_func: Callable) -> List[AgentResult]:
        """
        Execute multiple tasks in parallel.
        
        Args:
            tasks: List of tasks to execute
            executor_func: Function to execute each task
            
        Returns:
            List of results
        """
        results = []
        futures = {}
        
        # Submit all tasks
        for task in tasks:
            best_agent = self._select_best_agent(task)
            if best_agent:
                future = self.executor.submit(best_agent.execute_task, task, executor_func)
                futures[future] = task
        
        # Collect results as they complete
        for future in as_completed(futures):
            task = futures[future]
            try:
                result = future.result()
                results.append(result)
                
                with self.lock:
                    self.completed_results[task.task_id] = result
                    self.total_tasks_completed += 1
                    
            except Exception as e:
                results.append(AgentResult(
                    task_id=task.task_id,
                    agent_id="error",
                    success=False,
                    error=str(e)
                ))
        
        return results
    
    def _select_best_agent(self, task: AgentTask) -> Optional[SubAgent]:
        """
        Select the best agent for a task based on capabilities and load.
        
        Args:
            task: Task to assign
            
        Returns:
            Best agent or None if no suitable agent
        """
        suitable_agents = [
            agent for agent in self.agents.values()
            if agent.can_handle(task) and agent.state == AgentState.IDLE
        ]
        
        if not suitable_agents:
            # If no idle agents, pick one with fewest completed tasks
            suitable_agents = [
                agent for agent in self.agents.values()
                if agent.can_handle(task)
            ]
        
        if not suitable_agents:
            return None
        
        # Select agent with highest success rate
        best_agent = max(
            suitable_agents,
            key=lambda a: (a.completed_tasks / max(a.completed_tasks + a.failed_tasks, 1))
        )
        
        return best_agent
    
    def get_agent_stats(self) -> Dict[str, Any]:
        """Get statistics for all agents."""
        return {
            agent_id: agent.get_stats()
            for agent_id, agent in self.agents.items()
        }
    
    def get_overall_stats(self) -> Dict[str, Any]:
        """Get overall system statistics."""
        total_tasks = self.total_tasks_completed
        successful = sum(
            1 for r in self.completed_results.values()
            if r.success
        )
        
        return {
            "total_agents": len(self.agents),
            "max_workers": self.max_workers,
            "total_tasks_submitted": self.total_tasks_submitted,
            "total_tasks_completed": total_tasks,
            "successful_tasks": successful,
            "success_rate": successful / total_tasks if total_tasks > 0 else 0,
            "pending_tasks": len(self.pending_tasks)
        }
    
    def shutdown(self):
        """Shutdown the orchestrator and release resources."""
        self.executor.shutdown(wait=True)
