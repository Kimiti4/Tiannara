"""
Capability Scoring and Scheduling System

Provides capability scoring for tools and autonomous scheduling of tasks.
Enables Tiannara to optimize tool usage and schedule background operations.
"""

from typing import Dict, Any, List, Optional, Callable
from dataclasses import dataclass
from datetime import datetime, timedelta
import logging
import time
import heapq
from pathlib import Path
import json
from threading import Thread, Event
import uuid


@dataclass
class CapabilityScore:
    """Score for a specific capability of a tool."""
    tool_name: str
    capability: str
    success_rate: float
    avg_response_time: float
    usage_count: int
    last_used: Optional[datetime] = None
    score: float = 0.0  # Combined score


@dataclass
class ScheduledTask:
    """Represents a scheduled task."""
    id: str
    name: str
    task_function: Callable
    args: tuple
    kwargs: dict
    scheduled_time: datetime
    repeat_interval: Optional[timedelta] = None  # None means run once
    active: bool = True
    last_run: Optional[datetime] = None
    next_run: Optional[datetime] = None


class CapabilityScorer:
    """Manages capability scoring for tools."""
    
    def __init__(self):
        self.logger = logging.getLogger("tiannara.analytics.capability_scorer")
        self.capability_scores: Dict[str, CapabilityScore] = {}  # key: "tool_name:capability"
        self.usage_stats: Dict[str, Dict[str, Any]] = {}  # key: "tool_name:capability"
        
    def record_usage(self, tool_name: str, capability: str, success: bool, response_time: float):
        """Record usage of a tool capability."""
        key = f"{tool_name}:{capability}"
        
        # Initialize stats if not present
        if key not in self.usage_stats:
            self.usage_stats[key] = {
                "success_count": 0,
                "total_count": 0,
                "total_response_time": 0.0,
                "last_used": None
            }
        
        stats = self.usage_stats[key]
        stats["total_count"] += 1
        if success:
            stats["success_count"] += 1
        stats["total_response_time"] += response_time
        stats["last_used"] = datetime.now()
        
        # Update capability score
        self._update_capability_score(tool_name, capability)
        
    def _update_capability_score(self, tool_name: str, capability: str):
        """Update the capability score based on usage statistics."""
        key = f"{tool_name}:{capability}"
        stats = self.usage_stats[key]
        
        success_rate = stats["success_count"] / stats["total_count"] if stats["total_count"] > 0 else 0.0
        avg_response_time = stats["total_response_time"] / stats["total_count"] if stats["total_count"] > 0 else float('inf')
        
        # Normalize response time (lower is better)
        # We'll use 1/(1+response_time) to map to 0-1 range where lower time gives higher score
        response_time_factor = 1 / (1 + avg_response_time / 1000)  # Normalize assuming ms
        
        # Combined score: weighted combination of success rate and response time
        score = (success_rate * 0.7) + (response_time_factor * 0.3)
        
        self.capability_scores[key] = CapabilityScore(
            tool_name=tool_name,
            capability=capability,
            success_rate=success_rate,
            avg_response_time=avg_response_time,
            usage_count=stats["total_count"],
            last_used=stats["last_used"],
            score=score
        )
    
    def get_best_tool_for_capability(self, capability: str) -> Optional[str]:
        """Get the tool with the highest score for a specific capability."""
        best_score = -1
        best_tool = None
        
        for key, score_obj in self.capability_scores.items():
            if score_obj.capability == capability and score_obj.score > best_score:
                best_score = score_obj.score
                best_tool = score_obj.tool_name
        
        return best_tool
    
    def get_capability_score(self, tool_name: str, capability: str) -> Optional[CapabilityScore]:
        """Get the capability score for a specific tool and capability."""
        key = f"{tool_name}:{capability}"
        return self.capability_scores.get(key)
    
    def get_all_scores_for_tool(self, tool_name: str) -> List[CapabilityScore]:
        """Get all capability scores for a specific tool."""
        return [
            score for key, score in self.capability_scores.items()
            if score.tool_name == tool_name
        ]


class AutonomousScheduler:
    """Manages autonomous scheduling of tasks."""
    
    def __init__(self):
        self.logger = logging.getLogger("tiannara.analytics.scheduler")
        self.scheduled_tasks: Dict[str, ScheduledTask] = {}
        self.task_queue = []  # Min-heap based on scheduled time
        self.running = False
        self.worker_thread: Optional[Thread] = None
        self.stop_event = Event()
        
    def schedule_task(
        self, 
        name: str, 
        task_function: Callable, 
        args: tuple = (), 
        kwargs: dict = None,
        delay: timedelta = None,
        scheduled_time: datetime = None,
        repeat_interval: timedelta = None
    ) -> str:
        """
        Schedule a task to run at a specific time or after a delay.
        
        Args:
            name: Name of the task
            task_function: Function to execute
            args: Arguments to pass to the function
            kwargs: Keyword arguments to pass to the function
            delay: Delay before running the task (alternative to scheduled_time)
            scheduled_time: Specific time to run the task (alternative to delay)
            repeat_interval: How often to repeat the task (None for one-time)
        
        Returns:
            ID of the scheduled task
        """
        if kwargs is None:
            kwargs = {}
        
        if scheduled_time is None:
            if delay is None:
                scheduled_time = datetime.now()
            else:
                scheduled_time = datetime.now() + delay
        
        task_id = str(uuid.uuid4())
        
        task = ScheduledTask(
            id=task_id,
            name=name,
            task_function=task_function,
            args=args,
            kwargs=kwargs,
            scheduled_time=scheduled_time,
            repeat_interval=repeat_interval,
            active=True,
            next_run=scheduled_time
        )
        
        self.scheduled_tasks[task_id] = task
        
        # Add to priority queue (sorted by scheduled time)
        heapq.heappush(self.task_queue, (scheduled_time, task_id))
        
        self.logger.info(f"Scheduled task '{name}' (ID: {task_id}) for {scheduled_time}")
        
        # Start the scheduler if not already running
        if not self.running:
            self.start_scheduler()
        
        return task_id
    
    def cancel_task(self, task_id: str) -> bool:
        """Cancel a scheduled task."""
        if task_id in self.scheduled_tasks:
            self.scheduled_tasks[task_id].active = False
            self.logger.info(f"Cancelled task {task_id}")
            return True
        return False
    
    def start_scheduler(self):
        """Start the scheduler worker thread."""
        if not self.running:
            self.running = True
            self.stop_event.clear()
            self.worker_thread = Thread(target=self._scheduler_worker, daemon=True)
            self.worker_thread.start()
            self.logger.info("Autonomous scheduler started")
    
    def stop_scheduler(self):
        """Stop the scheduler worker thread."""
        if self.running:
            self.running = False
            self.stop_event.set()
            if self.worker_thread:
                self.worker_thread.join(timeout=2.0)
            self.logger.info("Autonomous scheduler stopped")
    
    def _scheduler_worker(self):
        """Worker function that executes scheduled tasks."""
        while self.running and not self.stop_event.is_set():
            try:
                # Check if there are tasks to run
                now = datetime.now()
                
                # Process all tasks that are due
                while self.task_queue:
                    scheduled_time, task_id = self.task_queue[0]
                    
                    # If task is not due yet, break and wait
                    if scheduled_time > now:
                        break
                    
                    # Pop the task from the queue
                    heapq.heappop(self.task_queue)
                    
                    # Check if task exists and is active
                    if task_id in self.scheduled_tasks and self.scheduled_tasks[task_id].active:
                        task = self.scheduled_tasks[task_id]
                        
                        # Execute the task
                        self._execute_task(task)
                        
                        # Handle repeating tasks
                        if task.repeat_interval:
                            # Schedule next run
                            task.next_run = now + task.repeat_interval
                            task.scheduled_time = task.next_run
                            
                            # Add back to queue
                            heapq.heappush(self.task_queue, (task.next_run, task_id))
                        else:
                            # Remove one-time task
                            del self.scheduled_tasks[task_id]
                    
                    # Brief pause to prevent busy-waiting
                    time.sleep(0.1)
                
                # Sleep briefly before checking again
                time.sleep(0.5)
                
            except Exception as e:
                self.logger.error(f"Error in scheduler worker: {e}")
    
    def _execute_task(self, task: ScheduledTask):
        """Execute a single task."""
        try:
            self.logger.info(f"Executing scheduled task: {task.name}")
            
            start_time = time.time()
            result = task.task_function(*task.args, **task.kwargs)
            execution_time = (time.time() - start_time) * 1000  # Convert to ms
            
            task.last_run = datetime.now()
            
            self.logger.info(f"Task '{task.name}' completed successfully in {execution_time:.2f}ms")
            
            return result
        except Exception as e:
            self.logger.error(f"Task '{task.name}' failed: {e}")
            # Note: We don't remove the task here, as it might be a repeating task
    
    def get_scheduled_tasks(self) -> List[ScheduledTask]:
        """Get a list of all scheduled tasks."""
        return list(self.scheduled_tasks.values())


class AnalyticsEngine:
    """Main analytics engine combining capability scoring and scheduling."""
    
    def __init__(self):
        self.capability_scorer = CapabilityScorer()
        self.scheduler = AutonomousScheduler()
        self.logger = logging.getLogger("tiannara.analytics.engine")
        
        self.logger.info("Analytics engine initialized")
    
    def record_tool_usage(self, tool_name: str, capability: str, success: bool, response_time: float):
        """Record tool usage for capability scoring."""
        self.capability_scorer.record_usage(tool_name, capability, success, response_time)
    
    def get_best_tool_for_capability(self, capability: str) -> Optional[str]:
        """Get the best tool for a specific capability."""
        return self.capability_scorer.get_best_tool_for_capability(capability)
    
    def schedule_task(
        self, 
        name: str, 
        task_function: Callable, 
        args: tuple = (), 
        kwargs: dict = None,
        delay: timedelta = None,
        scheduled_time: datetime = None,
        repeat_interval: timedelta = None
    ) -> str:
        """Schedule a task."""
        return self.scheduler.schedule_task(
            name, task_function, args, kwargs, 
            delay, scheduled_time, repeat_interval
        )
    
    def cancel_task(self, task_id: str) -> bool:
        """Cancel a scheduled task."""
        return self.scheduler.cancel_task(task_id)
    
    def get_analytics_summary(self) -> Dict[str, Any]:
        """Get a summary of analytics."""
        # Get top performing tools for each capability
        capabilities = set(score.capability for score in self.capability_scorer.capability_scores.values())
        
        top_tools_by_capability = {}
        for capability in capabilities:
            best_tool = self.capability_scorer.get_best_tool_for_capability(capability)
            if best_tool:
                score = self.capability_scorer.get_capability_score(best_tool, capability)
                if score:
                    top_tools_by_capability[capability] = {
                        "tool_name": best_tool,
                        "score": score.score,
                        "success_rate": score.success_rate,
                        "avg_response_time": score.avg_response_time
                    }
        
        return {
            "capability_scores": len(self.capability_scorer.capability_scores),
            "scheduled_tasks": len(self.scheduler.scheduled_tasks),
            "running": self.scheduler.running,
            "top_tools_by_capability": top_tools_by_capability
        }


# Global analytics engine instance
_analytics_engine = None


def get_analytics_engine() -> AnalyticsEngine:
    """Get or create the global analytics engine instance."""
    global _analytics_engine
    if _analytics_engine is None:
        _analytics_engine = AnalyticsEngine()
    return _analytics_engine


def record_tool_usage(tool_name: str, capability: str, success: bool, response_time: float):
    """Quick access function for recording tool usage."""
    engine = get_analytics_engine()
    engine.record_tool_usage(tool_name, capability, success, response_time)


def get_best_tool_for_capability(capability: str) -> Optional[str]:
    """Quick access function for getting the best tool for a capability."""
    engine = get_analytics_engine()
    return engine.get_best_tool_for_capability(capability)


def schedule_task(
    name: str, 
    task_function: Callable, 
    args: tuple = (), 
    kwargs: dict = None,
    delay: timedelta = None,
    scheduled_time: datetime = None,
    repeat_interval: timedelta = None
) -> str:
    """Quick access function for scheduling tasks."""
    engine = get_analytics_engine()
    return engine.schedule_task(
        name, task_function, args, kwargs, 
        delay, scheduled_time, repeat_interval
    )


def cancel_task(task_id: str) -> bool:
    """Quick access function for cancelling tasks."""
    engine = get_analytics_engine()
    return engine.cancel_task(task_id)


def build_metrics(history: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Build metrics summary from evolution history.
    
    Args:
        history: List of history entries from evolution runs
        
    Returns:
        Dictionary with aggregated metrics (delta, improvements, etc.)
    """
    if not history:
        return {"delta": 0.0, "improvements": 0, "total_steps": 0}
    
    # Calculate delta (change in score over time)
    if len(history) >= 2:
        first_score = history[0].get("score", 0.0)
        last_score = history[-1].get("score", 0.0)
        delta = last_score - first_score
    else:
        delta = 0.0
    
    # Count improvements
    improvements = sum(
        1 for i in range(1, len(history))
        if history[i].get("score", 0) > history[i-1].get("score", 0)
    )
    
    return {
        "delta": round(delta, 4),
        "improvements": improvements,
        "total_steps": len(history),
        "final_score": history[-1].get("score", 0.0) if history else 0.0,
    }