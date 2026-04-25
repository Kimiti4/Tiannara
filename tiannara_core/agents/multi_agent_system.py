"""
Multi-Agent Specialization System

Implements specialized agents for different aspects of Tiannara's operation.
Provides the "Jarvis feel" through role-based agent collaboration.
"""

from typing import Dict, Any, List, Optional, Callable, Union
from dataclasses import dataclass, field
from enum import Enum
import logging
import time
from abc import ABC, abstractmethod

from tiannara_core.planning.fallback_planner import deterministic_plan
from tiannara_core.execution.confidence_scorer import score_execution_confidence
from tiannara_core.memory.failure_memory import log_failure
from tiannara_core.plugins.registry import execute_tool


class AgentRole(Enum):
    PLANNER = "planner"
    CRITIC = "critic"
    EXECUTOR = "executor"
    RESEARCHER = "researcher"
    OPTIMIZER = "optimizer"
    MONITOR = "monitor"


@dataclass
class AgentMessage:
    """Message passed between agents."""
    sender: str
    recipient: str
    message_type: str
    content: Dict[str, Any]
    timestamp: float = field(default_factory=time.time)
    priority: int = 1  # 1=low, 5=high
    requires_response: bool = False
    correlation_id: Optional[str] = None


@dataclass
class AgentCapability:
    """Capability description for an agent."""
    name: str
    description: str
    input_types: List[str]
    output_types: List[str]
    confidence_required: float = 0.5
    max_processing_time: float = 30.0  # seconds


class BaseAgent(ABC):
    """Base class for all specialized agents."""
    
    def __init__(self, role: AgentRole, name: str):
        self.role = role
        self.name = name
        self.logger = logging.getLogger(f"tiannara.agents.{name}")
        self.capabilities: List[AgentCapability] = []
        self.message_queue: List[AgentMessage] = []
        self.performance_stats = {
            "tasks_completed": 0,
            "success_rate": 1.0,
            "avg_processing_time": 0.0,
            "last_activity": None
        }
    
    @abstractmethod
    def process_task(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Process a task assigned to this agent."""
        pass
    
    @abstractmethod
    def can_handle(self, task: Dict[str, Any]) -> bool:
        """Check if this agent can handle the given task."""
        pass
    
    def send_message(self, recipient: str, message_type: str, content: Dict[str, Any], 
                    priority: int = 1, requires_response: bool = False):
        """Send a message to another agent."""
        message = AgentMessage(
            sender=self.name,
            recipient=recipient,
            message_type=message_type,
            content=content,
            priority=priority,
            requires_response=requires_response
        )
        # In a real system, this would go through a message broker
        self.logger.debug(f"Sent message to {recipient}: {message_type}")
    
    def receive_message(self, message: AgentMessage):
        """Receive a message from another agent."""
        self.message_queue.append(message)
        self.logger.debug(f"Received message from {message.sender}: {message.message_type}")
    
    def update_performance(self, success: bool, processing_time: float):
        """Update performance statistics."""
        self.performance_stats["tasks_completed"] += 1
        self.performance_stats["last_activity"] = time.time()
        
        # Update success rate
        completed = self.performance_stats["tasks_completed"]
        current_rate = self.performance_stats["success_rate"]
        self.performance_stats["success_rate"] = (current_rate * (completed - 1) + (1.0 if success else 0.0)) / completed
        
        # Update average processing time
        current_avg = self.performance_stats["avg_processing_time"]
        self.performance_stats["avg_processing_time"] = (current_avg * (completed - 1) + processing_time) / completed


class PlannerAgent(BaseAgent):
    """Specializes in breaking intents into executable plans."""
    
    def __init__(self):
        super().__init__(AgentRole.PLANNER, "Planner")
        self.capabilities = [
            AgentCapability(
                name="intent_planning",
                description="Convert user intents into structured plans",
                input_types=["intent", "context"],
                output_types=["plan", "steps"],
                confidence_required=0.3
            ),
            AgentCapability(
                name="step_breakdown",
                description="Break complex tasks into smaller steps",
                input_types=["complex_task"],
                output_types=["steps", "dependencies"],
                confidence_required=0.4
            )
        ]
    
    def can_handle(self, task: Dict[str, Any]) -> bool:
        """Check if this agent can handle the planning task."""
        return "intent" in task or "planning" in task.get("type", "")
    
    def process_task(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Process a planning task."""
        start_time = time.time()
        
        try:
            intent = task.get("intent", "")
            context = task.get("context", {})
            use_llm = task.get("use_llm", True)
            
            self.logger.info(f"Planning task: {intent}")
            
            # Try LLM planning first if available
            plan = None
            planning_method = "fallback"
            
            if use_llm and hasattr(self, '_llm') and self._llm:
                try:
                    plan = self._llm.plan(intent, context)
                    planning_method = "llm"
                except Exception as e:
                    self.logger.warning(f"LLM planning failed: {e}")
            
            # Use fallback planning
            if plan is None:
                plan = deterministic_plan(intent, context)
                planning_method = "fallback"
            
            # Validate plan
            if not plan:
                raise ValueError("Failed to generate plan")
            
            result = {
                "success": True,
                "plan": plan,
                "planning_method": planning_method,
                "intent": intent,
                "steps": getattr(plan, 'steps', []),
                "agent": self.name
            }
            
            processing_time = time.time() - start_time
            self.update_performance(True, processing_time)
            
            return result
            
        except Exception as e:
            processing_time = time.time() - start_time
            self.update_performance(False, processing_time)
            
            self.logger.error(f"Planning failed: {e}")
            log_failure(intent, Exception(f"Planning failed: {e}"), component="planner")
            
            return {
                "success": False,
                "error": str(e),
                "agent": self.name
            }


class CriticAgent(BaseAgent):
    """Specializes in validating and improving plans."""
    
    def __init__(self):
        super().__init__(AgentRole.CRITIC, "Critic")
        self.capabilities = [
            AgentCapability(
                name="plan_validation",
                description="Validate plan structure and logic",
                input_types=["plan"],
                output_types=["validation_result", "suggestions"],
                confidence_required=0.6
            ),
            AgentCapability(
                name="risk_assessment",
                description="Assess risks in proposed actions",
                input_types=["plan", "context"],
                output_types=["risk_analysis", "mitigations"],
                confidence_required=0.7
            )
        ]
    
    def can_handle(self, task: Dict[str, Any]) -> bool:
        """Check if this agent can handle the criticism task."""
        return "plan" in task or "validation" in task.get("type", "")
    
    def process_task(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Process a criticism/validation task."""
        start_time = time.time()
        
        try:
            plan = task.get("plan")
            context = task.get("context", {})
            
            self.logger.info(f"Criticizing plan: {type(plan).__name__}")
            
            if not plan:
                raise ValueError("No plan provided for criticism")
            
            # Validate plan structure
            validation_result = self._validate_plan_structure(plan)
            
            # Assess risks
            risk_analysis = self._assess_risks(plan, context)
            
            # Generate suggestions
            suggestions = self._generate_suggestions(plan, validation_result, risk_analysis)
            
            # Overall assessment
            is_valid = validation_result["is_valid"] and risk_analysis["overall_risk"] < 0.8
            
            result = {
                "success": True,
                "is_valid": is_valid,
                "validation": validation_result,
                "risk_analysis": risk_analysis,
                "suggestions": suggestions,
                "confidence": 1.0 - risk_analysis["overall_risk"],
                "agent": self.name
            }
            
            processing_time = time.time() - start_time
            self.update_performance(True, processing_time)
            
            return result
            
        except Exception as e:
            processing_time = time.time() - start_time
            self.update_performance(False, processing_time)
            
            self.logger.error(f"Criticism failed: {e}")
            log_failure("plan_validation", Exception(f"Criticism failed: {e}"), component="critic")
            
            return {
                "success": False,
                "error": str(e),
                "agent": self.name
            }
    
    def _validate_plan_structure(self, plan) -> Dict[str, Any]:
        """Validate the structure of a plan."""
        issues = []
        
        # Check for required attributes
        if not hasattr(plan, 'steps'):
            issues.append("Plan missing 'steps' attribute")
        elif not plan.steps:
            issues.append("Plan has no steps")
        
        # Check step dependencies
        if hasattr(plan, 'steps'):
            step_ids = {step.id for step in plan.steps if hasattr(step, 'id')}
            for step in plan.steps:
                if hasattr(step, 'depends_on'):
                    for dep in step.depends_on:
                        if dep not in step_ids:
                            issues.append(f"Step {step.id} depends on non-existent step {dep}")
        
        return {
            "is_valid": len(issues) == 0,
            "issues": issues,
            "step_count": len(getattr(plan, 'steps', []))
        }
    
    def _assess_risks(self, plan, context: Dict[str, Any]) -> Dict[str, Any]:
        """Assess risks in the plan."""
        risk_factors = []
        total_risk = 0.0
        
        # Check for risky operations
        if hasattr(plan, 'steps'):
            for step in plan.steps:
                step_risk = 0.0
                
                # Check tool risk
                if hasattr(step, 'tool'):
                    risky_tools = ["file_system", "system", "executor"]
                    if step.tool in risky_tools:
                        step_risk += 0.3
                
                # Check action risk
                if hasattr(step, 'action'):
                    risky_actions = ["delete", "remove", "format", "deploy"]
                    if any(risky in str(step.action).lower() for risky in risky_actions):
                        step_risk += 0.4
                
                # Check for approval requirement
                if hasattr(step, 'requires_approval') and not step.requires_approval:
                    step_risk += 0.2
                
                if step_risk > 0:
                    risk_factors.append({
                        "step_id": getattr(step, 'id', 'unknown'),
                        "risk": step_risk,
                        "factors": [f"Tool/action risk: {step_risk}"]
                    })
                    total_risk += step_risk
        
        # Normalize risk
        if hasattr(plan, 'steps') and plan.steps:
            overall_risk = min(1.0, total_risk / len(plan.steps))
        else:
            overall_risk = 0.5
        
        return {
            "overall_risk": overall_risk,
            "risk_factors": risk_factors,
            "risk_level": "low" if overall_risk < 0.3 else "medium" if overall_risk < 0.7 else "high"
        }
    
    def _generate_suggestions(self, plan, validation: Dict[str, Any], risk: Dict[str, Any]) -> List[str]:
        """Generate improvement suggestions."""
        suggestions = []
        
        # Structure suggestions
        for issue in validation.get("issues", []):
            suggestions.append(f"Fix: {issue}")
        
        # Risk mitigation suggestions
        if risk["overall_risk"] > 0.5:
            suggestions.append("Consider adding approval requirements for risky operations")
            suggestions.append("Add fallback steps for critical operations")
        
        # General suggestions
        if validation.get("step_count", 0) > 10:
            suggestions.append("Consider breaking into smaller sub-goals")
        
        return suggestions


class ExecutorAgent(BaseAgent):
    """Specializes in executing plans and tool calls."""
    
    def __init__(self):
        super().__init__(AgentRole.EXECUTOR, "Executor")
        self.capabilities = [
            AgentCapability(
                name="plan_execution",
                description="Execute structured plans",
                input_types=["plan", "steps"],
                output_types=["execution_result", "outputs"],
                confidence_required=0.4
            ),
            AgentCapability(
                name="tool_execution",
                description="Execute individual tool calls",
                input_types=["tool_call", "parameters"],
                output_types=["tool_result"],
                confidence_required=0.5
            )
        ]
    
    def can_handle(self, task: Dict[str, Any]) -> bool:
        """Check if this agent can handle the execution task."""
        return "execute" in task or "plan" in task or "tool" in task
    
    def process_task(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Process an execution task."""
        start_time = time.time()
        
        try:
            plan = task.get("plan")
            confidence = task.get("confidence", 0.5)
            
            self.logger.info(f"Executing plan with confidence: {confidence}")
            
            # Check confidence threshold
            if confidence < 0.3:
                raise ValueError(f"Confidence too low for execution: {confidence}")
            
            # Execute plan
            if hasattr(plan, 'steps'):
                results = []
                for step in plan.steps:
                    step_result = self._execute_step(step)
                    results.append(step_result)
                    
                    # Stop on failure
                    if not step_result.get("success", False):
                        break
                
                success = all(r.get("success", False) for r in results)
                
                result = {
                    "success": success,
                    "results": results,
                    "steps_executed": len(results),
                    "agent": self.name
                }
            else:
                # Execute as tool call
                result = self._execute_tool_call(task)
            
            processing_time = time.time() - start_time
            self.update_performance(success, processing_time)
            
            return result
            
        except Exception as e:
            processing_time = time.time() - start_time
            self.update_performance(False, processing_time)
            
            self.logger.error(f"Execution failed: {e}")
            log_failure("execution", Exception(f"Execution failed: {e}"), component="executor")
            
            return {
                "success": False,
                "error": str(e),
                "agent": self.name
            }
    
    def _execute_step(self, step) -> Dict[str, Any]:
        """Execute a single step."""
        try:
            if hasattr(step, 'tool') and hasattr(step, 'action'):
                # Execute tool call
                result = execute_tool(step.tool, getattr(step, 'params', {}))
                return {
                    "success": result.get("success", False),
                    "result": result,
                    "step_id": getattr(step, 'id', 'unknown')
                }
            else:
                # Execute generic action
                return {
                    "success": True,
                    "result": f"Executed step: {getattr(step, 'description', 'unknown')}",
                    "step_id": getattr(step, 'id', 'unknown')
                }
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "step_id": getattr(step, 'id', 'unknown')
            }
    
    def _execute_tool_call(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a tool call."""
        tool_name = task.get("tool")
        params = task.get("params", {})
        
        if not tool_name:
            raise ValueError("No tool specified for execution")
        
        result = execute_tool(tool_name, params)
        
        return {
            "success": result.get("success", False),
            "result": result,
            "tool": tool_name,
            "agent": self.name
        }


class ResearcherAgent(BaseAgent):
    """Specializes in information gathering and analysis."""
    
    def __init__(self):
        super().__init__(AgentRole.RESEARCHER, "Researcher")
        self.capabilities = [
            AgentCapability(
                name="information_gathering",
                description="Gather information from various sources",
                input_types=["query", "context"],
                output_types=["information", "sources"],
                confidence_required=0.3
            ),
            AgentCapability(
                name="context_analysis",
                description="Analyze context and provide insights",
                input_types=["context", "intent"],
                output_types=["analysis", "insights"],
                confidence_required=0.4
            )
        ]
    
    def can_handle(self, task: Dict[str, Any]) -> bool:
        """Check if this agent can handle the research task."""
        return "research" in task or "analyze" in task or "query" in task
    
    def process_task(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Process a research task."""
        start_time = time.time()
        
        try:
            query = task.get("query", "")
            context = task.get("context", {})
            
            self.logger.info(f"Researching: {query}")
            
            # Simulate research (in real system, would search databases, web, etc.)
            research_result = self._perform_research(query, context)
            
            result = {
                "success": True,
                "query": query,
                "research_result": research_result,
                "insights": self._generate_insights(research_result, context),
                "agent": self.name
            }
            
            processing_time = time.time() - start_time
            self.update_performance(True, processing_time)
            
            return result
            
        except Exception as e:
            processing_time = time.time() - start_time
            self.update_performance(False, processing_time)
            
            self.logger.error(f"Research failed: {e}")
            log_failure("research", Exception(f"Research failed: {e}"), component="researcher")
            
            return {
                "success": False,
                "error": str(e),
                "agent": self.name
            }
    
    def _perform_research(self, query: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """Perform research on the given query."""
        # Mock research implementation
        return {
            "query": query,
            "findings": [
                f"Finding 1 related to {query}",
                f"Finding 2 related to {query}"
            ],
            "sources": ["internal_knowledge", "context_analysis"],
            "confidence": 0.7
        }
    
    def _generate_insights(self, research_result: Dict[str, Any], context: Dict[str, Any]) -> List[str]:
        """Generate insights from research results."""
        insights = []
        
        findings = research_result.get("findings", [])
        if findings:
            insights.append(f"Found {len(findings)} relevant pieces of information")
        
        if context:
            insights.append("Context provides additional constraints")
        
        return insights


class OptimizerAgent(BaseAgent):
    """Specializes in learning from failures and improving performance."""
    
    def __init__(self):
        super().__init__(AgentRole.OPTIMIZER, "Optimizer")
        self.capabilities = [
            AgentCapability(
                name="failure_analysis",
                description="Analyze failures and suggest improvements",
                input_types=["failure_data", "context"],
                output_types=["analysis", "improvements"],
                confidence_required=0.5
            ),
            AgentCapability(
                name="performance_optimization",
                description="Optimize system performance based on metrics",
                input_types=["performance_data"],
                output_types=["optimization_suggestions"],
                confidence_required=0.6
            )
        ]
    
    def can_handle(self, task: Dict[str, Any]) -> bool:
        """Check if this agent can handle the optimization task."""
        return "optimize" in task or "improve" in task or "failure" in task
    
    def process_task(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Process an optimization task."""
        start_time = time.time()
        
        try:
            failure_data = task.get("failure_data")
            performance_data = task.get("performance_data")
            
            self.logger.info("Processing optimization task")
            
            improvements = []
            
            # Analyze failures
            if failure_data:
                failure_analysis = self._analyze_failures(failure_data)
                improvements.extend(failure_analysis.get("improvements", []))
            
            # Optimize performance
            if performance_data:
                performance_analysis = self._analyze_performance(performance_data)
                improvements.extend(performance_analysis.get("improvements", []))
            
            result = {
                "success": True,
                "improvements": improvements,
                "priority_ranked": sorted(improvements, key=lambda x: x.get("priority", 0), reverse=True),
                "agent": self.name
            }
            
            processing_time = time.time() - start_time
            self.update_performance(True, processing_time)
            
            return result
            
        except Exception as e:
            processing_time = time.time() - start_time
            self.update_performance(False, processing_time)
            
            self.logger.error(f"Optimization failed: {e}")
            log_failure("optimization", Exception(f"Optimization failed: {e}"), component="optimizer")
            
            return {
                "success": False,
                "error": str(e),
                "agent": self.name
            }
    
    def _analyze_failures(self, failure_data: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze failure patterns and suggest improvements."""
        improvements = []
        
        # Common failure patterns and their fixes
        failure_patterns = {
            "timeout": {"improvement": "Increase timeout values", "priority": 3},
            "connection": {"improvement": "Add retry logic with exponential backoff", "priority": 4},
            "validation": {"improvement": "Improve input validation", "priority": 2},
            "permission": {"improvement": "Check and fix permission issues", "priority": 5}
        }
        
        for pattern, fix in failure_patterns.items():
            if pattern in str(failure_data).lower():
                improvements.append({
                    "type": "failure_fix",
                    "description": fix["improvement"],
                    "priority": fix["priority"],
                    "pattern": pattern
                })
        
        return {"improvements": improvements}
    
    def _analyze_performance(self, performance_data: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze performance data and suggest optimizations."""
        improvements = []
        
        # Performance optimization suggestions
        if performance_data.get("avg_time", 0) > 10:
            improvements.append({
                "type": "performance",
                "description": "Consider caching frequently used results",
                "priority": 3
            })
        
        if performance_data.get("success_rate", 1.0) < 0.8:
            improvements.append({
                "type": "reliability",
                "description": "Improve error handling and fallback mechanisms",
                "priority": 4
            })
        
        return {"improvements": improvements}


class MultiAgentSystem:
    """
    Coordinates multiple specialized agents.
    
    Provides the main interface for the multi-agent architecture.
    """
    
    def __init__(self):
        self.logger = logging.getLogger("tiannara.multi_agent")
        
        # Initialize agents
        self.agents = {
            AgentRole.PLANNER: PlannerAgent(),
            AgentRole.CRITIC: CriticAgent(),
            AgentRole.EXECUTOR: ExecutorAgent(),
            AgentRole.RESEARCHER: ResearcherAgent(),
            AgentRole.OPTIMIZER: OptimizerAgent()
        }
        
        # Message routing (simplified)
        self.message_router = {}
        
        self.logger.info("Multi-agent system initialized")
    
    def process_intent(self, intent: str, context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Process an intent using the multi-agent system.
        
        This is the main entry point that coordinates all agents.
        """
        context = context or {}
        
        try:
            # Step 1: Planning
            plan_result = self._route_to_agent(AgentRole.PLANNER, {
                "intent": intent,
                "context": context,
                "type": "planning"
            })
            
            if not plan_result.get("success"):
                return plan_result
            
            plan = plan_result.get("plan")
            
            # Step 2: Criticism
            criticism_result = self._route_to_agent(AgentRole.CRITIC, {
                "plan": plan,
                "context": context,
                "type": "validation"
            })
            
            # Step 3: Research (if needed)
            if not criticism_result.get("is_valid", True):
                research_result = self._route_to_agent(AgentRole.RESEARCHER, {
                    "query": f"How to improve plan for: {intent}",
                    "context": context,
                    "type": "research"
                })
            
            # Step 4: Execution
            execution_result = self._route_to_agent(AgentRole.EXECUTOR, {
                "plan": plan,
                "confidence": criticism_result.get("confidence", 0.5),
                "type": "execution"
            })
            
            # Step 5: Optimization (if execution failed)
            if not execution_result.get("success"):
                optimization_result = self._route_to_agent(AgentRole.OPTIMIZER, {
                    "failure_data": execution_result,
                    "performance_data": self._get_performance_metrics(),
                    "type": "optimization"
                })
            
            return {
                "success": execution_result.get("success", False),
                "intent": intent,
                "plan_result": plan_result,
                "criticism_result": criticism_result,
                "execution_result": execution_result,
                "agent_system": "multi_agent",
                "agents_used": ["planner", "critic", "executor"]
            }
            
        except Exception as e:
            self.logger.error(f"Multi-agent processing failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "agent_system": "multi_agent"
            }
    
    def _route_to_agent(self, role: AgentRole, task: Dict[str, Any]) -> Dict[str, Any]:
        """Route a task to the appropriate agent."""
        agent = self.agents.get(role)
        
        if not agent:
            raise ValueError(f"Agent not found for role: {role}")
        
        if not agent.can_handle(task):
            raise ValueError(f"Agent {agent.name} cannot handle this task")
        
        return agent.process_task(task)
    
    def _get_performance_metrics(self) -> Dict[str, Any]:
        """Get performance metrics for all agents."""
        return {
            role.value: agent.performance_stats
            for role, agent in self.agents.items()
        }
    
    def get_agent_status(self) -> Dict[str, Any]:
        """Get status of all agents."""
        return {
            role.value: {
                "name": agent.name,
                "capabilities": [cap.name for cap in agent.capabilities],
                "performance": agent.performance_stats,
                "message_queue_size": len(agent.message_queue)
            }
            for role, agent in self.agents.items()
        }


# Global multi-agent system instance
_multi_agent_system = None

def get_multi_agent_system() -> MultiAgentSystem:
    """Get or create the global multi-agent system instance."""
    global _multi_agent_system
    if _multi_agent_system is None:
        _multi_agent_system = MultiAgentSystem()
    return _multi_agent_system

def process_with_agents(intent: str, context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Quick access function for multi-agent processing."""
    system = get_multi_agent_system()
    return system.process_intent(intent, context)
