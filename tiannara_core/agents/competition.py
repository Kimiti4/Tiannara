"""
Market-Style Agent Competition System

Implements market-style agent competition where agents bid to solve tasks.
Agents compete based on their expertise and past performance.
"""

from typing import Dict, Any, List, Optional, Callable, Union
from dataclasses import dataclass
from datetime import datetime
import logging
import time
import heapq
from enum import Enum
from tiannara_core.agents.multi_agent_system import BaseAgent, AgentRole, get_multi_agent_system


@dataclass
class TaskBid:
    """Represents a bid from an agent for a task."""
    agent_name: str
    task_id: str
    bid_amount: float  # Represents confidence/efficiency metric
    estimated_completion_time: float  # In seconds
    confidence: float  # Confidence in successful completion
    specializations: List[str]  # Relevant specializations
    timestamp: float = 0.0


@dataclass
class CompetitiveTask:
    """Represents a task in the competitive marketplace."""
    id: str
    description: str
    requirements: List[str]
    priority: int  # 1-5 scale
    submission_deadline: float
    assigned_agent: Optional[str] = None
    winner_bid: Optional[TaskBid] = None
    status: str = "open"  # open, assigned, completed, failed
    submissions: List[Dict[str, Any]] = None
    created_at: float = 0.0


class BidType(Enum):
    """Types of bidding strategies."""
    CONFIDENCE_BASED = "confidence_based"
    SPEED_BASED = "speed_based"
    EXPERTISE_BASED = "expertise_based"
    HYBRID = "hybrid"


class CompetitiveAgentManager:
    """Manages competitive bidding among agents."""
    
    def __init__(self):
        self.logger = logging.getLogger("tiannara.agents.competition")
        self.tasks: Dict[str, CompetitiveTask] = {}
        self.bids: Dict[str, List[TaskBid]] = {}  # task_id -> bids
        self.agent_performance: Dict[str, Dict[str, float]] = {}  # agent_name -> metrics
        self.multi_agent_system = get_multi_agent_system()
        
        self.logger.info("Competitive agent manager initialized")
    
    def submit_task(
        self, 
        description: str, 
        requirements: List[str], 
        priority: int = 3,
        deadline_minutes: int = 10
    ) -> str:
        """Submit a task to the competitive marketplace."""
        import uuid
        task_id = f"task_{uuid.uuid4().hex[:8]}"
        
        task = CompetitiveTask(
            id=task_id,
            description=description,
            requirements=requirements,
            priority=priority,
            submission_deadline=time.time() + (deadline_minutes * 60),
            created_at=time.time()
        )
        
        self.tasks[task_id] = task
        self.bids[task_id] = []
        
        self.logger.info(f"Submitted competitive task '{task_id}' with description: {description[:50]}...")
        
        # Have agents bid on the task
        self._collect_bids(task)
        
        # Assign the task to the winning bidder
        winner = self._select_winner(task_id)
        if winner:
            self.assign_task_to_agent(task_id, winner.agent_name)
        
        return task_id
    
    def _collect_bids(self, task: CompetitiveTask):
        """Have agents submit bids for the task."""
        # Get all agents from the multi-agent system
        agents = self.multi_agent_system.agents.values()
        
        for agent in agents:
            bid = self._create_bid_for_agent(agent, task)
            if bid:
                self.bids[task.id].append(bid)
                self.logger.debug(f"Agent {agent.name} bid {bid.bid_amount:.2f} for task {task.id}")
    
    def _create_bid_for_agent(self, agent: BaseAgent, task: CompetitiveTask) -> Optional[TaskBid]:
        """Create a bid for a specific agent and task."""
        # Check if agent can handle the task based on requirements
        if not self._agent_can_handle_task(agent, task):
            return None
        
        # Calculate bid metrics
        confidence = self._calculate_agent_confidence(agent, task)
        est_completion = self._estimate_completion_time(agent, task)
        bid_amount = self._calculate_bid_amount(agent, task, confidence, est_completion)
        
        # Create bid
        bid = TaskBid(
            agent_name=agent.name,
            task_id=task.id,
            bid_amount=bid_amount,
            estimated_completion_time=est_completion,
            confidence=confidence,
            specializations=self._get_agent_specializations(agent),
            timestamp=time.time()
        )
        
        return bid
    
    def _agent_can_handle_task(self, agent: BaseAgent, task: CompetitiveTask) -> bool:
        """Check if an agent can handle the given task."""
        # Check if any of the task requirements match the agent's capabilities
        for req in task.requirements:
            for cap in agent.capabilities:
                if req.lower() in cap.description.lower() or req.lower() in cap.input_types or req.lower() in cap.output_types:
                    return True
        return False
    
    def _calculate_agent_confidence(self, agent: BaseAgent, task: CompetitiveTask) -> float:
        """Calculate an agent's confidence for a specific task."""
        # Base confidence from agent's performance stats
        base_confidence = agent.performance_stats.get("success_rate", 0.8)
        
        # Factor in the agent's familiarity with the task type
        task_similarity_factor = 0.0
        for req in task.requirements:
            for cap in agent.capabilities:
                if req.lower() in cap.description.lower():
                    task_similarity_factor = 0.3
                    break
        
        # Factor in the agent's recent performance
        recent_performance_factor = 0.0
        last_activity = agent.performance_stats.get("last_activity", 0)
        if last_activity and time.time() - last_activity < 300:  # Active in last 5 mins
            recent_performance_factor = 0.2
        
        confidence = min(1.0, base_confidence + task_similarity_factor + recent_performance_factor)
        return confidence
    
    def _estimate_completion_time(self, agent: BaseAgent, task: CompetitiveTask) -> float:
        """Estimate how long an agent will take to complete the task."""
        # Base estimate from agent's historical performance
        avg_time = agent.performance_stats.get("avg_processing_time", 10.0)
        
        # Adjust based on task complexity (simplified)
        complexity_multiplier = 1.0 + (len(task.requirements) * 0.1)
        
        return avg_time * complexity_multiplier
    
    def _calculate_bid_amount(self, agent: BaseAgent, task: CompetitiveTask, confidence: float, est_completion: float) -> float:
        """Calculate the bid amount based on agent's confidence and efficiency."""
        # Higher confidence = higher bid (more willing to take on the task)
        confidence_factor = confidence
        
        # Faster completion = higher bid (more efficient)
        speed_factor = 1.0 / (1.0 + est_completion / 10.0)  # Normalize against 10s baseline
        
        # Factor in agent's overall performance
        performance_factor = agent.performance_stats.get("success_rate", 0.8)
        
        # Combine factors with weights
        bid_amount = (confidence_factor * 0.5) + (speed_factor * 0.3) + (performance_factor * 0.2)
        
        # Apply priority multiplier
        priority_multiplier = 0.5 + (task.priority * 0.1)  # Priority 1-5 scale
        
        return bid_amount * priority_multiplier
    
    def _get_agent_specializations(self, agent: BaseAgent) -> List[str]:
        """Get an agent's specializations."""
        return [cap.name for cap in agent.capabilities]
    
    def _select_winner(self, task_id: str) -> Optional[TaskBid]:
        """Select the winning bid for a task."""
        if task_id not in self.bids or not self.bids[task_id]:
            self.logger.warning(f"No bids for task {task_id}")
            return None
        
        # Select the best bid based on our strategy
        # For now, we'll use a hybrid approach favoring high confidence + reasonable speed
        winning_bid = max(
            self.bids[task_id],
            key=lambda bid: bid.bid_amount  # Highest bid wins
        )
        
        self.logger.info(f"Selected winner for task {task_id}: {winning_bid.agent_name} with bid {winning_bid.bid_amount:.2f}")
        
        # Store the winner in the task
        task = self.tasks[task_id]
        task.winner_bid = winning_bid
        task.status = "assigned"
        
        return winning_bid
    
    def assign_task_to_agent(self, task_id: str, agent_name: str):
        """Assign a task to a specific agent."""
        if task_id not in self.tasks:
            self.logger.error(f"Task {task_id} does not exist")
            return False
        
        task = self.tasks[task_id]
        task.assigned_agent = agent_name
        task.status = "assigned"
        
        self.logger.info(f"Assigned task {task_id} to agent {agent_name}")
        
        # Execute the task with the assigned agent
        self._execute_assigned_task(task)
        
        return True
    
    def _execute_assigned_task(self, task: CompetitiveTask):
        """Execute a task assigned to an agent."""
        if not task.assigned_agent:
            self.logger.error(f"Task {task.id} has no assigned agent")
            return
        
        # Find the agent
        agent = None
        for ag in self.multi_agent_system.agents.values():
            if ag.name == task.assigned_agent:
                agent = ag
                break
        
        if not agent:
            self.logger.error(f"Assigned agent {task.assigned_agent} not found")
            return
        
        # Prepare task data
        task_data = {
            "intent": task.description,
            "requirements": task.requirements,
            "type": "competitive_task"
        }
        
        # Execute the task with the agent
        start_time = time.time()
        try:
            result = agent.process_task(task_data)
            
            execution_time = time.time() - start_time
            
            # Record performance
            self._record_agent_performance(task.assigned_agent, result.get("success", False), execution_time)
            
            # Update task status
            task.status = "completed" if result.get("success") else "failed"
            
            self.logger.info(f"Task {task.id} completed by {task.assigned_agent}, success: {result.get('success')}")
            
        except Exception as e:
            self.logger.error(f"Task {task.id} failed with exception: {e}")
            task.status = "failed"
            
            # Record failure
            self._record_agent_performance(task.assigned_agent, False, time.time() - start_time)
    
    def _record_agent_performance(self, agent_name: str, success: bool, execution_time: float):
        """Record performance metrics for an agent."""
        if agent_name not in self.agent_performance:
            self.agent_performance[agent_name] = {
                "total_tasks": 0,
                "successful_tasks": 0,
                "total_execution_time": 0.0,
                "avg_execution_time": 0.0
            }
        
        perf = self.agent_performance[agent_name]
        perf["total_tasks"] += 1
        
        if success:
            perf["successful_tasks"] += 1
        
        perf["total_execution_time"] += execution_time
        perf["avg_execution_time"] = perf["total_execution_time"] / perf["total_tasks"]
    
    def get_marketplace_status(self) -> Dict[str, Any]:
        """Get the status of the agent marketplace."""
        open_tasks = [task for task in self.tasks.values() if task.status == "open"]
        assigned_tasks = [task for task in self.tasks.values() if task.status == "assigned"]
        completed_tasks = [task for task in self.tasks.values() if task.status == "completed"]
        
        return {
            "total_tasks": len(self.tasks),
            "open_tasks": len(open_tasks),
            "assigned_tasks": len(assigned_tasks),
            "completed_tasks": len(completed_tasks),
            "total_bids": sum(len(bids) for bids in self.bids.values()),
            "agent_performance": self.agent_performance.copy(),
            "task_details": {
                task_id: {
                    "description": task.description[:50] + "..." if len(task.description) > 50 else task.description,
                    "status": task.status,
                    "assigned_agent": task.assigned_agent,
                    "priority": task.priority,
                    "bid_count": len(self.bids.get(task_id, []))
                }
                for task_id, task in self.tasks.items()
            }
        }


class MarketBasedAgentSystem:
    """Wrapper for the competitive agent system."""
    
    def __init__(self):
        self.competitive_manager = CompetitiveAgentManager()
        self.logger = logging.getLogger("tiannara.agents.market_system")
    
    def process_intent_via_competition(self, intent: str, requirements: List[str] = None, priority: int = 3) -> Dict[str, Any]:
        """Process an intent through agent competition."""
        if requirements is None:
            requirements = ["general_task"]
        
        self.logger.info(f"Starting competitive processing for intent: {intent[:50]}...")
        
        # Submit the task to the marketplace
        task_id = self.competitive_manager.submit_task(
            description=intent,
            requirements=requirements,
            priority=priority
        )
        
        # Wait for task to be completed (with timeout)
        start_wait = time.time()
        timeout = 30  # seconds
        
        while time.time() - start_wait < timeout:
            task = self.competitive_manager.tasks[task_id]
            if task.status in ["completed", "failed"]:
                break
            time.sleep(0.5)
        
        # Get task result
        task = self.competitive_manager.tasks[task_id]
        
        result = {
            "success": task.status == "completed",
            "task_id": task_id,
            "assigned_agent": task.assigned_agent,
            "status": task.status,
            "winner_bid": {
                "agent_name": task.winner_bid.agent_name if task.winner_bid else None,
                "bid_amount": task.winner_bid.bid_amount if task.winner_bid else None,
                "confidence": task.winner_bid.confidence if task.winner_bid else None,
                "estimated_completion_time": task.winner_bid.estimated_completion_time if task.winner_bid else None
            } if task.winner_bid else None
        }
        
        self.logger.info(f"Competitive processing result: {result}")
        
        return result


# Global competitive agent system instance
_competitive_agent_system = None


def get_competitive_agent_system() -> MarketBasedAgentSystem:
    """Get or create the global competitive agent system instance."""
    global _competitive_agent_system
    if _competitive_agent_system is None:
        _competitive_agent_system = MarketBasedAgentSystem()
    return _competitive_agent_system


def process_intent_via_competition(intent: str, requirements: List[str] = None, priority: int = 3) -> Dict[str, Any]:
    """Quick access function for competitive agent processing."""
    system = get_competitive_agent_system()
    return system.process_intent_via_competition(intent, requirements, priority)


def get_marketplace_status() -> Dict[str, Any]:
    """Quick access function for getting marketplace status."""
    system = get_competitive_agent_system()
    return system.competitive_manager.get_marketplace_status()