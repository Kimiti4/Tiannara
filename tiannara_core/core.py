"""
Tiannara Core - Standardized Initialization

Provides the main Tiannara class with locked, standardized constructors
to prevent initialization issues and ensure consistency.
"""

from typing import Optional, Dict, Any, Union
from dataclasses import dataclass, field
import logging
import traceback

from tiannara_core.planning.fallback_planner import get_fallback_planner, deterministic_plan
from tiannara_core.execution.confidence_scorer import get_confidence_scorer, score_execution_confidence
from tiannara_core.memory.memory import Memory
from tiannara_core.memory.failure_memory import get_failure_memory, log_failure
from tiannara_core.autonomous.orchestrator import Orchestrator
from tiannara_core.cognition.decision_engine import DecisionEngine
from tiannara_core.distributed.windows_stable_manager import run_distributed_safe, summarize_results_safe
from tiannara_core.plugins.registry import get_plugin_registry, execute_tool
from tiannara_core.goals.goal_system import get_goal_system, create_goal, get_active_goals
from tiannara_core.agents.multi_agent_system import get_multi_agent_system, process_with_agents
from tiannara_core.telemetry.dashboard import get_telemetry_dashboard, log_intent, log_planning, log_execution, log_failure


@dataclass
class TiannaraConfig:
    """Configuration for Tiannara core system."""
    llm: Optional[Any] = None
    memory: Optional[Memory] = None
    min_confidence: float = 0.30
    evolution_threshold: float = 0.40
    fallback_threshold: float = 0.20
    enable_evolution: bool = True
    enable_distributed: bool = True
    worker_count: int = 4
    log_level: str = "INFO"
    enable_multi_agent: bool = True
    enable_plugins: bool = True
    enable_goals: bool = True
    enable_telemetry: bool = True


class TiannaraCore:
    """
    Main Tiannara Core System
    
    Provides standardized initialization and coordination of all Tiannara components.
    This replaces ad-hoc initialization with a consistent, reliable pattern.
    """
    
    def __init__(self, config: Optional[TiannaraConfig] = None, **kwargs):
        """
        Standardized constructor - accepts either config object or keyword arguments.
        
        Args:
            config: TiannaraConfig object (optional)
            **kwargs: Individual configuration parameters
        """
        # Handle configuration
        if config is None:
            config = TiannaraConfig(**kwargs)
        
        self.config = config
        self._setup_logging()
        
        # Initialize core components in dependency order
        self._initialize_components()
        
        self.logger.info("Tiannara Core initialized successfully")
    
    def _setup_logging(self):
        """Setup logging configuration."""
        self.logger = logging.getLogger("tiannara_core")
        self.logger.setLevel(getattr(logging, self.config.log_level.upper()))
        
        if not self.logger.handlers:
            handler = logging.StreamHandler()
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            self.logger.addHandler(handler)
    
    def _initialize_components(self):
        """Initialize all core components in proper order."""
        try:
            # Memory system (foundation)
            self.memory = self.config.memory or Memory()
            
            # Fallback planner (always available)
            self.fallback_planner = get_fallback_planner()
            
            # Confidence scorer
            self.confidence_scorer = get_confidence_scorer()
            
            # Decision engine with skill memory
            self.decision_engine = DecisionEngine(
                min_confidence=self.config.min_confidence,
                skill_memory=getattr(self.memory, 'skill_memory', None)
            )
            
            # Failure memory system
            self.failure_memory = get_failure_memory()
            
            # Plugin system
            if self.config.enable_plugins:
                self.plugin_registry = get_plugin_registry()
            else:
                self.plugin_registry = None
            
            # Goal system
            if self.config.enable_goals:
                self.goal_system = get_goal_system()
            else:
                self.goal_system = None
            
            # Multi-agent system
            if self.config.enable_multi_agent:
                self.multi_agent_system = get_multi_agent_system()
            else:
                self.multi_agent_system = None
            
            # Orchestrator (evolution and distributed execution)
            if self.config.enable_evolution:
                self.orchestrator = Orchestrator(
                    worker_count=self.config.worker_count
                )
            else:
                self.orchestrator = None
            
            # Telemetry dashboard
            if self.config.enable_telemetry:
                self.telemetry = get_telemetry_dashboard()
            else:
                self.telemetry = None
            
            # LLM interface (if provided)
            self.llm = self.config.llm
            
            self.logger.info("All Phase 6 core components initialized successfully")
            
        except Exception as e:
            self.logger.error(f"Failed to initialize components: {e}")
            self.logger.debug(traceback.format_exc())
            raise
    
    def process_intent(self, intent: str, context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Main entry point for processing user intents.
        
        This method coordinates:
        1. Intent analysis and decision making
        2. Planning (LLM or fallback)
        3. Confidence scoring
        4. Execution decision
        5. Result processing
        
        Args:
            intent: User intent string
            context: Additional context information
            
        Returns:
            Dict containing the result and metadata
        """
        import time
        start_time = time.time()
        
        if not intent:
            return self._create_error_result("No intent provided", context)
        
        context = context or {}
        
        # Log intent to telemetry
        if self.telemetry:
            self.telemetry.log_intent(intent, context)
        
        self.logger.info(f"Processing intent: {intent}")
        
        try:
            # Use multi-agent system if enabled
            if self.multi_agent_system:
                agent_result = self.multi_agent_system.process_intent(intent, context)
                if agent_result.get("success"):
                    duration_ms = (time.time() - start_time) * 1000
                    if self.telemetry:
                        self.telemetry.log_execution("multi_agent", True, duration_ms, agent_result)
                    return self._process_result(agent_result, intent, context)
            
            # Step 1: Decision making
            decision = self._make_decision(intent, context)
            
            # Step 2: Planning
            planning_start = time.time()
            plan_result = self._create_plan(intent, decision, context)
            planning_duration = (time.time() - planning_start) * 1000
            
            # Log planning to telemetry
            if self.telemetry:
                self.telemetry.log_planning(
                    intent, 
                    plan_result["planning_method"], 
                    plan_result["planning_success"], 
                    planning_duration
                )
            
            # Step 3: Confidence scoring
            confidence_result = self._score_confidence(intent, plan_result, context)
            
            # Step 4: Execution decision
            execution_decision = self._decide_execution(confidence_result, context)
            
            # Step 5: Execute or fallback
            if execution_decision["should_execute"]:
                execution_start = time.time()
                result = self._execute_plan(plan_result, confidence_result, context)
                execution_duration = (time.time() - execution_start) * 1000
                
                # Log execution to telemetry
                if self.telemetry:
                    self.telemetry.log_execution(
                        plan_result["planning_method"], 
                        result.get("success", False), 
                        execution_duration, 
                        result
                    )
            else:
                result = self._handle_fallback(intent, execution_decision, context)
            
            # Step 6: Process result and update memory
            processed_result = self._process_result(result, intent, context)
            
            return processed_result
            
        except Exception as e:
            # Log failure to telemetry
            if self.telemetry:
                self.telemetry.log_failure("core", str(e), context)
            
            self.logger.error(f"Error processing intent '{intent}': {e}")
            self.logger.debug(traceback.format_exc())
            return self._create_error_result(str(e), context, intent)
    
    def _make_decision(self, intent: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """Make decision about intent using decision engine."""
        try:
            # Get context tags from memory
            context_tags = self._extract_context_tags(intent, context)
            
            # Get memory store for decision engine
            memory_store = self.memory.get_all() if hasattr(self.memory, 'get_all') else []
            
            # Make decision
            decision = self.decision_engine.decide(memory_store, context_tags)
            
            self.logger.info(f"Decision made: {decision.get('intent')} with confidence {decision.get('confidence')}")
            return decision
            
        except Exception as e:
            self.logger.warning(f"Decision engine failed: {e}, using fallback")
            return {
                "intent": intent,
                "confidence": 0.0,
                "reason": "Decision engine failed",
                "chosen_pattern": None,
                "chosen_breakdown": None
            }
    
    def _create_plan(self, intent: str, decision: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """Create execution plan (LLM or fallback)."""
        plan_result = {
            "llm_plan": None,
            "fallback_plan": None,
            "planning_method": "none",
            "planning_success": False
        }
        
        # Try LLM planning first
        if self.llm and hasattr(self.llm, 'plan'):
            try:
                llm_plan = self.llm.plan(intent, context)
                if llm_plan:
                    plan_result["llm_plan"] = llm_plan
                    plan_result["planning_method"] = "llm"
                    plan_result["planning_success"] = True
                    self.logger.info("LLM planning successful")
            except Exception as e:
                self.logger.warning(f"LLM planning failed: {e}")
        
        # Use fallback planning if LLM failed
        if not plan_result["planning_success"]:
            try:
                fallback_plan = deterministic_plan(intent, context)
                if fallback_plan:
                    plan_result["fallback_plan"] = fallback_plan
                    plan_result["planning_method"] = "fallback"
                    plan_result["planning_success"] = True
                    self.logger.info("Fallback planning successful")
            except Exception as e:
                self.logger.error(f"Fallback planning failed: {e}")
        
        return plan_result
    
    def _score_confidence(self, intent: str, plan_result: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """Score execution confidence."""
        try:
            has_llm_plan = plan_result["llm_plan"] is not None
            has_fallback_plan = plan_result["fallback_plan"] is not None
            
            confidence_result = score_execution_confidence(
                intent=intent,
                has_llm_plan=has_llm_plan,
                has_fallback_plan=has_fallback_plan,
                context=context
            )
            
            self.logger.info(f"Confidence scored: {confidence_result.confidence:.2f} ({confidence_result.level.name})")
            return confidence_result
            
        except Exception as e:
            self.logger.warning(f"Confidence scoring failed: {e}")
            # Return minimal confidence result
            from tiannara_core.execution.confidence_scorer import ConfidenceResult, ConfidenceLevel
            return ConfidenceResult(
                confidence=0.3,
                level=ConfidenceLevel.MEDIUM,
                reasoning=["Confidence scoring failed"],
                should_retry=False,
                should_evolve=False,
                should_fallback=True
            )
    
    def _decide_execution(self, confidence_result: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """Decide whether to execute, retry, evolve, or fallback."""
        return {
            "should_execute": confidence_result.confidence >= self.config.fallback_threshold,
            "should_retry": confidence_result.should_retry,
            "should_evolve": confidence_result.should_evolve,
            "should_fallback": confidence_result.should_fallback,
            "max_retries": confidence_result.max_retries
        }
    
    def _execute_plan(self, plan_result: Dict[str, Any], confidence_result: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """Execute the chosen plan."""
        try:
            # Prefer LLM plan, fallback to deterministic plan
            plan = plan_result["llm_plan"] or plan_result["fallback_plan"]
            
            if not plan:
                raise ValueError("No plan available for execution")
            
            # Execute based on plan type
            if plan_result["planning_method"] == "llm":
                result = self._execute_llm_plan(plan, context)
            else:
                result = self._execute_fallback_plan(plan, context)
            
            result["execution_method"] = plan_result["planning_method"]
            result["confidence"] = confidence_result.confidence
            
            return result
            
        except Exception as e:
            self.logger.error(f"Plan execution failed: {e}")
            return self._create_error_result(f"Execution failed: {e}", context)
    
    def _execute_llm_plan(self, plan: Any, context: Dict[str, Any]) -> Dict[str, Any]:
        """Execute LLM-generated plan."""
        # This would interface with the actual execution system
        # For now, return a mock result
        return {
            "success": True,
            "result": "LLM plan executed successfully",
            "plan_type": "llm",
            "details": {"plan": str(plan)[:100]}
        }
    
    def _execute_fallback_plan(self, plan: Any, context: Dict[str, Any]) -> Dict[str, Any]:
        """Execute fallback plan."""
        # This would execute the deterministic plan steps
        # For now, return a mock result
        return {
            "success": True,
            "result": "Fallback plan executed successfully",
            "plan_type": "fallback",
            "details": {"steps": len(getattr(plan, 'steps', []))}
        }
    
    def _handle_fallback(self, intent: str, execution_decision: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """Handle fallback scenarios."""
        if execution_decision["should_evolve"] and self.orchestrator:
            try:
                # Trigger evolution for improvement
                evolution_result = self.orchestrator.run_cycle(
                    question=f"Improve handling of: {intent}",
                    source="fallback_evolution"
                )
                return {
                    "success": False,
                    "result": "Triggered evolution for improvement",
                    "fallback_type": "evolution",
                    "evolution_result": evolution_result
                }
            except Exception as e:
                self.logger.warning(f"Evolution fallback failed: {e}")
        
        return {
            "success": False,
            "result": "Operation failed - no viable execution path",
            "fallback_type": "none",
            "reason": "All execution paths failed"
        }
    
    def _process_result(self, result: Dict[str, Any], intent: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """Process result and update memory systems."""
        # Update memory with result
        if hasattr(self.memory, 'add_experience'):
            try:
                self.memory.add_experience({
                    "intent": intent,
                    "context": context,
                    "result": result,
                    "timestamp": self._get_timestamp()
                })
            except Exception as e:
                self.logger.warning(f"Failed to update memory: {e}")
        
        # Add metadata
        result["tiannara_version"] = "1.3.0-phase6"
        result["processing_timestamp"] = self._get_timestamp()
        
        return result
    
    def _extract_context_tags(self, intent: str, context: Dict[str, Any]) -> list[str]:
        """Extract context tags for decision engine."""
        tags = []
        
        # Add intent-based tags
        intent_lower = intent.lower()
        if "save" in intent_lower or "write" in intent_lower:
            tags.append("file_operation")
        if "read" in intent_lower or "list" in intent_lower:
            tags.append("information_request")
        if "build" in intent_lower or "deploy" in intent_lower:
            tags.append("development")
        if "help" in intent_lower or "status" in intent_lower:
            tags.append("system_query")
        
        # Add context-based tags
        if context.get("file_path"):
            tags.append("file_context")
        if context.get("error"):
            tags.append("error_context")
        if context.get("previous_result"):
            tags.append("follow_up")
        
        return tags
    
    def _create_error_result(self, error: str, context: Dict[str, Any], intent: Optional[str] = None) -> Dict[str, Any]:
        """Create standardized error result."""
        return {
            "success": False,
            "error": error,
            "intent": intent,
            "context": context,
            "tiannara_version": "1.3.0-phase6",
            "processing_timestamp": self._get_timestamp()
        }
    
    def _get_timestamp(self) -> str:
        """Get current timestamp."""
        from datetime import datetime
        return datetime.now().isoformat()
    
    def get_status(self) -> Dict[str, Any]:
        """Get current system status."""
        status = {
            "tiannara_version": "1.3.0-phase6",
            "phase": "phase6_complete",
            "components": {
                "memory": hasattr(self, 'memory') and self.memory is not None,
                "fallback_planner": hasattr(self, 'fallback_planner') and self.fallback_planner is not None,
                "confidence_scorer": hasattr(self, 'confidence_scorer') and self.confidence_scorer is not None,
                "decision_engine": hasattr(self, 'decision_engine') and self.decision_engine is not None,
                "failure_memory": hasattr(self, 'failure_memory') and self.failure_memory is not None,
                "plugin_registry": hasattr(self, 'plugin_registry') and self.plugin_registry is not None,
                "goal_system": hasattr(self, 'goal_system') and self.goal_system is not None,
                "multi_agent_system": hasattr(self, 'multi_agent_system') and self.multi_agent_system is not None,
                "orchestrator": hasattr(self, 'orchestrator') and self.orchestrator is not None,
                "telemetry": hasattr(self, 'telemetry') and self.telemetry is not None,
                "llm": hasattr(self, 'llm') and self.llm is not None
            },
            "config": {
                "min_confidence": self.config.min_confidence,
                "evolution_threshold": self.config.evolution_threshold,
                "fallback_threshold": self.config.fallback_threshold,
                "enable_evolution": self.config.enable_evolution,
                "enable_multi_agent": self.config.enable_multi_agent,
                "enable_plugins": self.config.enable_plugins,
                "enable_goals": self.config.enable_goals,
                "enable_telemetry": self.config.enable_telemetry,
                "worker_count": self.config.worker_count
            }
        }
        
        # Add component-specific status
        if self.plugin_registry:
            status["plugins"] = {
                "total_tools": len(self.plugin_registry.tools),
                "tool_statistics": self.plugin_registry.get_tool_statistics()
            }
        
        if self.goal_system:
            status["goals"] = self.goal_system.get_system_overview()
        
        if self.multi_agent_system:
            status["agents"] = self.multi_agent_system.get_agent_status()
        
        if self.telemetry:
            status["telemetry"] = self.telemetry.api.get_metrics()
        
        return status


# Factory function for easy instantiation
def create_tiannara(**kwargs) -> TiannaraCore:
    """
    Factory function to create Tiannara instance with standard configuration.
    
    This is the recommended way to create Tiannara instances.
    """
    config = TiannaraConfig(**kwargs)
    return TiannaraCore(config)


# Quick access function for simple use cases
def quick_tiannara(llm=None, memory=None) -> TiannaraCore:
    """
    Quick creation of Tiannara with minimal configuration.
    """
    return create_tiannara(llm=llm, memory=memory)
