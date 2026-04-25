"""
Goal Persistence System

Manages long-term goals that persist across sessions.
Enables true autonomy with multi-session mission support.
"""

from typing import Dict, Any, List, Optional, Callable
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
import json
import uuid
import logging
from pathlib import Path


class GoalStatus(Enum):
    PENDING = "pending"
    ACTIVE = "active"
    IN_PROGRESS = "in_progress"
    PAUSED = "paused"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class GoalPriority(Enum):
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    CRITICAL = 4


@dataclass
class GoalStep:
    """Individual step within a goal."""
    id: str
    description: str
    status: GoalStatus = GoalStatus.PENDING
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())
    started_at: Optional[str] = None
    completed_at: Optional[str] = None
    result: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    retry_count: int = 0
    max_retries: int = 3
    dependencies: List[str] = field(default_factory=list)
    estimated_duration: Optional[float] = None  # in minutes
    actual_duration: Optional[float] = None


@dataclass
class Goal:
    """Persistent goal with multi-session support."""
    id: str
    objective: str
    description: str
    status: GoalStatus = GoalStatus.PENDING
    priority: GoalPriority = GoalPriority.MEDIUM
    progress: float = 0.0  # 0.0 to 1.0
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())
    updated_at: str = field(default_factory=lambda: datetime.now().isoformat())
    started_at: Optional[str] = None
    completed_at: Optional[str] = None
    steps: List[GoalStep] = field(default_factory=list)
    context: Dict[str, Any] = field(default_factory=dict)
    tags: List[str] = field(default_factory=list)
    parent_goal_id: Optional[str] = None
    sub_goal_ids: List[str] = field(default_factory=list)
    success_criteria: Optional[str] = None
    failure_conditions: List[str] = field(default_factory=list)
    estimated_completion: Optional[str] = None
    session_id: Optional[str] = None
    
    def add_step(self, description: str, dependencies: Optional[List[str]] = None) -> GoalStep:
        """Add a new step to the goal."""
        step = GoalStep(
            id=f"step_{uuid.uuid4().hex[:8]}",
            description=description,
            dependencies=dependencies or []
        )
        self.steps.append(step)
        self.updated_at = datetime.now().isoformat()
        return step
    
    def update_progress(self):
        """Update progress based on step completion."""
        if not self.steps:
            self.progress = 0.0
            return
        
        completed_steps = sum(1 for step in self.steps if step.status == GoalStatus.COMPLETED)
        self.progress = completed_steps / len(self.steps)
        self.updated_at = datetime.now().isoformat()
    
    def get_next_steps(self) -> List[GoalStep]:
        """Get steps that can be executed next (dependencies satisfied)."""
        if self.status not in [GoalStatus.ACTIVE, GoalStatus.IN_PROGRESS]:
            return []
        
        completed_step_ids = {step.id for step in self.steps if step.status == GoalStatus.COMPLETED}
        
        ready_steps = []
        for step in self.steps:
            if step.status == GoalStatus.PENDING:
                # Check if all dependencies are completed
                if all(dep_id in completed_step_ids for dep_id in step.dependencies):
                    ready_steps.append(step)
        
        return ready_steps
    
    def mark_step_started(self, step_id: str):
        """Mark a step as started."""
        for step in self.steps:
            if step.id == step_id and step.status == GoalStatus.PENDING:
                step.status = GoalStatus.IN_PROGRESS
                step.started_at = datetime.now().isoformat()
                self.updated_at = datetime.now().isoformat()
                
                if self.status == GoalStatus.PENDING:
                    self.status = GoalStatus.IN_PROGRESS
                    self.started_at = datetime.now().isoformat()
                break
    
    def mark_step_completed(self, step_id: str, result: Optional[Dict[str, Any]] = None):
        """Mark a step as completed."""
        for step in self.steps:
            if step.id == step_id and step.status == GoalStatus.IN_PROGRESS:
                step.status = GoalStatus.COMPLETED
                step.completed_at = datetime.now().isoformat()
                step.result = result
                
                if step.started_at:
                    start_time = datetime.fromisoformat(step.started_at)
                    end_time = datetime.fromisoformat(step.completed_at)
                    step.actual_duration = (end_time - start_time).total_seconds() / 60  # minutes
                
                self.update_progress()
                break
    
    def mark_step_failed(self, step_id: str, error: str):
        """Mark a step as failed and handle retries."""
        for step in self.steps:
            if step.id == step_id and step.status == GoalStatus.IN_PROGRESS:
                step.error = error
                step.retry_count += 1
                
                if step.retry_count >= step.max_retries:
                    step.status = GoalStatus.FAILED
                    self.status = GoalStatus.FAILED
                    self.completed_at = datetime.now().isoformat()
                else:
                    step.status = GoalStatus.PENDING
                    step.started_at = None
                
                self.updated_at = datetime.now().isoformat()
                break


class GoalSystem:
    """
    Manages persistent goals across sessions.
    
    Provides storage, retrieval, and management of long-term goals.
    """
    
    def __init__(self, storage_path: str = "data/goals.json"):
        self.storage_path = Path(storage_path)
        self.storage_path.parent.mkdir(parents=True, exist_ok=True)
        
        self.logger = logging.getLogger("tiannara.goals")
        
        # In-memory storage
        self.goals: Dict[str, Goal] = {}
        self.session_id = f"session_{uuid.uuid4().hex[:8]}"
        
        # Load existing goals
        self.load_goals()
    
    def load_goals(self):
        """Load goals from storage."""
        if not self.storage_path.exists():
            self.logger.info("No existing goals file found")
            return
        
        try:
            with open(self.storage_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            for goal_data in data.get('goals', []):
                goal = self._deserialize_goal(goal_data)
                self.goals[goal.id] = goal
            
            self.logger.info(f"Loaded {len(self.goals)} goals from storage")
            
        except Exception as e:
            self.logger.error(f"Failed to load goals: {e}")
    
    def save_goals(self):
        """Save goals to storage."""
        try:
            data = {
                'goals': [self._serialize_goal(goal) for goal in self.goals.values()],
                'last_saved': datetime.now().isoformat(),
                'session_id': self.session_id
            }
            
            with open(self.storage_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            
            self.logger.debug(f"Saved {len(self.goals)} goals to storage")
            
        except Exception as e:
            self.logger.error(f"Failed to save goals: {e}")
    
    def create_goal(self, 
                   objective: str,
                   description: str,
                   priority: GoalPriority = GoalPriority.MEDIUM,
                   context: Optional[Dict[str, Any]] = None,
                   tags: Optional[List[str]] = None,
                   success_criteria: Optional[str] = None,
                   parent_goal_id: Optional[str] = None) -> str:
        """
        Create a new goal.
        
        Args:
            objective: What the goal aims to achieve
            description: Detailed description of the goal
            priority: Priority level
            context: Additional context information
            tags: Tags for categorization
            success_criteria: Criteria for successful completion
            parent_goal_id: ID of parent goal if this is a sub-goal
            
        Returns:
            ID of the created goal
        """
        goal = Goal(
            id=f"goal_{uuid.uuid4().hex[:8]}",
            objective=objective,
            description=description,
            priority=priority,
            context=context or {},
            tags=tags or [],
            success_criteria=success_criteria,
            parent_goal_id=parent_goal_id,
            session_id=self.session_id
        )
        
        self.goals[goal.id] = goal
        
        # Add to parent's sub-goals if applicable
        if parent_goal_id and parent_goal_id in self.goals:
            self.goals[parent_goal_id].sub_goal_ids.append(goal.id)
        
        self.save_goals()
        self.logger.info(f"Created goal: {goal.id} - {objective}")
        
        return goal.id
    
    def get_goal(self, goal_id: str) -> Optional[Goal]:
        """Get a goal by ID."""
        return self.goals.get(goal_id)
    
    def get_active_goals(self, status_filter: Optional[GoalStatus] = None) -> List[Goal]:
        """Get active goals, optionally filtered by status."""
        goals = list(self.goals.values())
        
        if status_filter:
            goals = [g for g in goals if g.status == status_filter]
        else:
            # Default to active/in-progress goals
            goals = [g for g in goals if g.status in [GoalStatus.ACTIVE, GoalStatus.IN_PROGRESS]]
        
        # Sort by priority and creation time
        goals.sort(key=lambda g: (g.priority.value, g.created_at), reverse=True)
        
        return goals
    
    def get_goals_by_tag(self, tag: str) -> List[Goal]:
        """Get goals with a specific tag."""
        return [g for g in self.goals.values() if tag in g.tags]
    
    def get_goals_by_priority(self, priority: GoalPriority) -> List[Goal]:
        """Get goals with a specific priority."""
        return [g for g in self.goals.values() if g.priority == priority]
    
    def update_goal_status(self, goal_id: str, status: GoalStatus):
        """Update the status of a goal."""
        if goal_id not in self.goals:
            return False
        
        goal = self.goals[goal_id]
        old_status = goal.status
        goal.status = status
        goal.updated_at = datetime.now().isoformat()
        
        # Handle status transitions
        if status == GoalStatus.COMPLETED and old_status != GoalStatus.COMPLETED:
            goal.completed_at = datetime.now().isoformat()
            goal.progress = 1.0
        elif status == GoalStatus.ACTIVE and old_status == GoalStatus.PENDING:
            goal.started_at = datetime.now().isoformat()
        
        self.save_goals()
        self.logger.info(f"Updated goal {goal_id} status: {old_status} -> {status}")
        
        return True
    
    def add_step_to_goal(self, goal_id: str, description: str, dependencies: Optional[List[str]] = None) -> Optional[str]:
        """Add a step to a goal."""
        if goal_id not in self.goals:
            return None
        
        goal = self.goals[goal_id]
        step = goal.add_step(description, dependencies)
        
        self.save_goals()
        self.logger.info(f"Added step {step.id} to goal {goal_id}")
        
        return step.id
    
    def execute_goal_step(self, goal_id: str, step_id: str, executor: Callable) -> bool:
        """
        Execute a specific step of a goal.
        
        Args:
            goal_id: ID of the goal
            step_id: ID of the step to execute
            executor: Function to execute the step
            
        Returns:
            True if successful, False otherwise
        """
        if goal_id not in self.goals:
            return False
        
        goal = self.goals[goal_id]
        step = next((s for s in goal.steps if s.id == step_id), None)
        
        if not step or step.status != GoalStatus.PENDING:
            return False
        
        # Mark step as started
        goal.mark_step_started(step_id)
        
        try:
            # Execute the step
            result = executor(goal, step)
            
            # Mark step as completed
            goal.mark_step_completed(step_id, result)
            
            # Check if goal is completed
            if all(s.status == GoalStatus.COMPLETED for s in goal.steps):
                self.update_goal_status(goal_id, GoalStatus.COMPLETED)
            
            self.save_goals()
            self.logger.info(f"Successfully executed step {step_id} for goal {goal_id}")
            
            return True
            
        except Exception as e:
            # Mark step as failed
            goal.mark_step_failed(step_id, str(e))
            
            self.save_goals()
            self.logger.error(f"Failed to execute step {step_id} for goal {goal_id}: {e}")
            
            return False
    
    def get_goal_progress(self, goal_id: str) -> Dict[str, Any]:
        """Get detailed progress information for a goal."""
        if goal_id not in self.goals:
            return {}
        
        goal = self.goals[goal_id]
        
        step_counts = {}
        for status in GoalStatus:
            step_counts[status.value] = sum(1 for step in goal.steps if step.status == status)
        
        return {
            "goal_id": goal_id,
            "objective": goal.objective,
            "status": goal.status.value,
            "progress": goal.progress,
            "total_steps": len(goal.steps),
            "step_counts": step_counts,
            "next_steps": [step.id for step in goal.get_next_steps()],
            "created_at": goal.created_at,
            "updated_at": goal.updated_at,
            "estimated_completion": goal.estimated_completion
        }
    
    def get_system_overview(self) -> Dict[str, Any]:
        """Get overview of the entire goal system."""
        total_goals = len(self.goals)
        status_counts = {}
        priority_counts = {}
        
        for status in GoalStatus:
            status_counts[status.value] = sum(1 for g in self.goals.values() if g.status == status)
        
        for priority in GoalPriority:
            priority_counts[priority.name] = sum(1 for g in self.goals.values() if g.priority == priority)
        
        # Calculate average progress
        active_goals = [g for g in self.goals.values() if g.status in [GoalStatus.ACTIVE, GoalStatus.IN_PROGRESS]]
        avg_progress = sum(g.progress for g in active_goals) / len(active_goals) if active_goals else 0.0
        
        return {
            "total_goals": total_goals,
            "active_goals": len(active_goals),
            "status_distribution": status_counts,
            "priority_distribution": priority_counts,
            "average_progress": avg_progress,
            "session_id": self.session_id,
            "last_saved": self.storage_path.stat().st_mtime if self.storage_path.exists() else None
        }
    
    def cleanup_completed_goals(self, days: int = 30) -> int:
        """Remove completed goals older than specified days."""
        cutoff = datetime.now() - timedelta(days=days)
        
        to_remove = []
        for goal_id, goal in self.goals.items():
            if (goal.status == GoalStatus.COMPLETED and 
                goal.completed_at and 
                datetime.fromisoformat(goal.completed_at) < cutoff):
                to_remove.append(goal_id)
        
        for goal_id in to_remove:
            del self.goals[goal_id]
        
        if to_remove:
            self.save_goals()
            self.logger.info(f"Cleaned up {len(to_remove)} completed goals")
        
        return len(to_remove)
    
    def _serialize_goal(self, goal: Goal) -> Dict[str, Any]:
        """Serialize a goal for storage."""
        return {
            "id": goal.id,
            "objective": goal.objective,
            "description": goal.description,
            "status": goal.status.value,
            "priority": goal.priority.value,
            "progress": goal.progress,
            "created_at": goal.created_at,
            "updated_at": goal.updated_at,
            "started_at": goal.started_at,
            "completed_at": goal.completed_at,
            "steps": [
                {
                    "id": step.id,
                    "description": step.description,
                    "status": step.status.value,
                    "created_at": step.created_at,
                    "started_at": step.started_at,
                    "completed_at": step.completed_at,
                    "result": step.result,
                    "error": step.error,
                    "retry_count": step.retry_count,
                    "max_retries": step.max_retries,
                    "dependencies": step.dependencies,
                    "estimated_duration": step.estimated_duration,
                    "actual_duration": step.actual_duration
                }
                for step in goal.steps
            ],
            "context": goal.context,
            "tags": goal.tags,
            "parent_goal_id": goal.parent_goal_id,
            "sub_goal_ids": goal.sub_goal_ids,
            "success_criteria": goal.success_criteria,
            "failure_conditions": goal.failure_conditions,
            "estimated_completion": goal.estimated_completion,
            "session_id": goal.session_id
        }
    
    def _deserialize_goal(self, data: Dict[str, Any]) -> Goal:
        """Deserialize a goal from storage."""
        goal = Goal(
            id=data["id"],
            objective=data["objective"],
            description=data["description"],
            status=GoalStatus(data["status"]),
            priority=GoalPriority(data["priority"]),
            progress=data["progress"],
            created_at=data["created_at"],
            updated_at=data["updated_at"],
            started_at=data.get("started_at"),
            completed_at=data.get("completed_at"),
            context=data.get("context", {}),
            tags=data.get("tags", []),
            parent_goal_id=data.get("parent_goal_id"),
            sub_goal_ids=data.get("sub_goal_ids", []),
            success_criteria=data.get("success_criteria"),
            failure_conditions=data.get("failure_conditions", []),
            estimated_completion=data.get("estimated_completion"),
            session_id=data.get("session_id")
        )
        
        # Deserialize steps
        goal.steps = []
        for step_data in data.get("steps", []):
            step = GoalStep(
                id=step_data["id"],
                description=step_data["description"],
                status=GoalStatus(step_data["status"]),
                created_at=step_data["created_at"],
                started_at=step_data.get("started_at"),
                completed_at=step_data.get("completed_at"),
                result=step_data.get("result"),
                error=step_data.get("error"),
                retry_count=step_data.get("retry_count", 0),
                max_retries=step_data.get("max_retries", 3),
                dependencies=step_data.get("dependencies", []),
                estimated_duration=step_data.get("estimated_duration"),
                actual_duration=step_data.get("actual_duration")
            )
            goal.steps.append(step)
        
        return goal


# Global goal system instance
_goal_system = None

def get_goal_system() -> GoalSystem:
    """Get or create the global goal system instance."""
    global _goal_system
    if _goal_system is None:
        _goal_system = GoalSystem()
    return _goal_system

def create_goal(objective: str, description: str, **kwargs) -> str:
    """Quick access function for creating goals."""
    system = get_goal_system()
    return system.create_goal(objective, description, **kwargs)

def get_active_goals() -> List[Goal]:
    """Quick access function for getting active goals."""
    system = get_goal_system()
    return system.get_active_goals()

def execute_goal_step(goal_id: str, step_id: str, executor: Callable) -> bool:
    """Quick access function for executing goal steps."""
    system = get_goal_system()
    return system.execute_goal_step(goal_id, step_id, executor)
