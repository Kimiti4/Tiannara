"""
Tiannara Core - Standardized Initialization

Provides the main Tiannara class with locked, standardized constructors
to prevent initialization issues and ensure consistency.
"""

from typing import Optional, Dict, Any, Union
from dataclasses import dataclass, field
import logging
import traceback

from tiannara_core.planning.fallback_planner import get_fallback_planner, deterministic_plan, calculate_deterministic_confidence
from tiannara_core.execution.confidence_scorer import get_confidence_scorer, score_execution_confidence
from tiannara_core.memory.memory import Memory
from tiannara_core.memory.failure_memory import get_failure_memory, log_failure as log_failure_mem
from tiannara_core.autonomous.orchestrator import Orchestrator
from tiannara_core.cognition.decision_engine import DecisionEngine
from tiannara_core.distributed.windows_stable_manager import run_distributed_safe, summarize_results_safe
from tiannara_core.plugins.registry import get_plugin_registry, execute_tool
from tiannara_core.goals.goal_system import get_goal_system, create_goal, get_active_goals
from tiannara_core.agents.multi_agent_system import get_multi_agent_system, process_with_agents
from tiannara_core.agents.competition import get_competitive_agent_system, process_intent_via_competition, get_marketplace_status
from tiannara_core.analytics.metrics import get_analytics_engine, record_tool_usage, get_best_tool_for_capability, schedule_task, cancel_task
from tiannara_core.evolution_to_discovery_bridge import EvolutionToDiscoveryBridge, EvolutionResult, Hypothesis
from tiannara_core.evolution.ecm_orchestrator import ECMOrchestrator, ReverseEngineeringEngine
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
    safety_mode: bool = False  # Enable extra safety checks
    enable_analytics: bool = True  # Enable capability scoring and scheduling
    enable_competition: bool = True  # Enable market-style agent competition
    enable_ecm: bool = True  # Enable Executable Causal Manifolds
    enable_evolution_bridge: bool = True  # Enable evolution to discovery bridge


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
            
            # Analytics engine (for capability scoring and scheduling)
            if self.config.enable_analytics:
                self.analytics_engine = get_analytics_engine()
            else:
                self.analytics_engine = None
            
            # ECM (Executable Causal Manifolds) system
            if self.config.enable_ecm:
                self.ecm_orchestrator = ECMOrchestrator()
                self.reverse_engineering_engine = ReverseEngineeringEngine()
            else:
                self.ecm_orchestrator = None
                self.reverse_engineering_engine = None
            
            # Evolution to discovery bridge
            if self.config.enable_evolution_bridge:
                self.evolution_bridge = EvolutionToDiscoveryBridge()
            else:
                self.evolution_bridge = None
            
            # Multi-agent system
            if self.config.enable_multi_agent:
                self.multi_agent_system = get_multi_agent_system()
            else:
                self.multi_agent_system = None
            
            # Competition-based agent system
            if self.config.enable_competition:
                self.competition_system = get_competitive_agent_system()
            else:
                self.competition_system = None
            
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
        context['safety_mode'] = self.config.safety_mode
        
        # Log intent to telemetry
        if self.telemetry:
            self.telemetry.log_intent(intent, context)
        
        self.logger.info(f"Processing intent: {intent}")
        
        try:
            # Check if this is an ECM-related intent
            if self.config.enable_ecm and self._is_ecm_intent(intent):
                ecm_result = self._process_ecm_intent(intent, context)
                if ecm_result:
                    duration_ms = (time.time() - start_time) * 1000
                    if self.telemetry:
                        self.telemetry.log_execution("ecm", True, duration_ms, ecm_result)
                    return self._process_result(ecm_result, intent, context)
            
            # Use competition-based agent system if enabled and requested
            if (self.config.enable_competition and 
                self.competition_system and 
                context.get('use_competition')):
                
                # Process via competition
                competition_result = process_intent_via_competition(
                    intent, 
                    requirements=context.get('requirements', ['general_task']), 
                    priority=context.get('priority', 3)
                )
                
                if competition_result.get("success"):
                    duration_ms = (time.time() - start_time) * 1000
                    if self.telemetry:
                        self.telemetry.log_execution("competition", True, duration_ms, competition_result)
                    return self._process_result(competition_result, intent, context)
            
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
                
                # Record tool usage for analytics if applicable
                if self.analytics_engine and plan_result["planning_method"] == "fallback":
                    self.analytics_engine.record_tool_usage(
                        tool_name="fallback_planner",
                        capability="planning",
                        success=result.get("success", False),
                        response_time=execution_duration
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
    
    def _is_ecm_intent(self, intent: str) -> bool:
        """Check if the intent is related to ECM operations."""
        ecm_keywords = [
            "analyze", "reverse engineer", "understand behavior", 
            "causal", "trace", "dependency", "relationship",
            "find pattern", "detect logic", "infer rule"
        ]
        intent_lower = intent.lower()
        return any(keyword in intent_lower for keyword in ecm_keywords)
    
    def _process_ecm_intent(self, intent: str, context: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Process an intent using ECM if applicable."""
        if not self.ecm_orchestrator:
            return None
        
        # For now, we'll handle specific ECM-related intents
        if "reverse engineer" in intent.lower():
            # Extract code or function to analyze from intent/context
            code_to_analyze = context.get('code', 'def sample_function(x):\n    return x * 2')
            inputs = context.get('inputs', {"x": 5})
            
            try:
                result = self.ecm_orchestrator.execute_ecm_cycle(
                    source_code=code_to_analyze,
                    inputs=inputs
                )
                return {
                    "success": True,
                    "result_type": "ecm_analysis",
                    "ecm_result": result
                }
            except Exception as e:
                self.logger.error(f"ECM analysis failed: {e}")
                return None
        
        elif "analyze" in intent.lower() and self.reverse_engineering_engine:
            # Handle reverse engineering intent
            try:
                # This would require specific binary/path in context
                if 'binary_path' in context:
                    result = self.reverse_engineering_engine.reverse_engineer(
                        binary_path=context['binary_path'],
                        input_samples=context.get('input_samples', [{}])
                    )
                    return {
                        "success": True,
                        "result_type": "reverse_engineering",
                        "reverse_engineering_result": result
                    }
            except Exception as e:
                self.logger.error(f"Reverse engineering failed: {e}")
                return None
        
        return None
    
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
            
            # Include safety mode in context for confidence scoring
            context['safety_mode'] = self.config.safety_mode
            
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
            
            # Log failure to memory
            if self.failure_memory:
                self.failure_memory.log_failure(
                    intent=plan_result.get("llm_plan", {}).get("intent", "unknown") or 
                          plan_result.get("fallback_plan", {}).get("intent", "unknown"),
                    error=e,
                    component="executor",
                    step="plan_execution",
                    context=context
                )
            
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
                
                # If we have an evolution bridge, translate the result to hypotheses
                if self.evolution_bridge and isinstance(evolution_result, list):
                    try:
                        evolution_results = [
                            EvolutionResult(
                                code_diff=str(getattr(item, 'code', '')),
                                fitness_score=getattr(item, 'fitness', 0.5),
                                input_output_pairs=getattr(item, 'io_pairs', []),
                                metadata=getattr(item, 'metadata', {})
                            ) for item in evolution_result if hasattr(item, 'code')
                        ]
                        
                        if evolution_results:
                            hypotheses = self.evolution_bridge.translate(evolution_results)
                            self.logger.info(f"Generated {len(hypotheses)} hypotheses from evolution results")
                            
                            return {
                                "success": False,
                                "result": "Triggered evolution and hypothesis generation",
                                "fallback_type": "evolution",
                                "evolution_result": evolution_result,
                                "hypotheses": [h.__dict__ for h in hypotheses]
                            }
                    except Exception as e:
                        self.logger.warning(f"Failed to translate evolution results to hypotheses: {e}")
                
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
        
        # Update failure memory if this was a failure
        if not result.get("success", True) and self.failure_memory:
            self.failure_memory.log_failure(
                intent=intent,
                error=result.get("error", "Unknown error"),
                component="core",
                step="result_processing",
                context=context
            )
        
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
        if "analyze" in intent_lower or "understand" in intent_lower:
            tags.append("analysis")
        if "reverse" in intent_lower or "engineer" in intent_lower:
            tags.append("reverse_engineering")
        
        # Add context-based tags
        if context.get("file_path"):
            tags.append("file_context")
        if context.get("error"):
            tags.append("error_context")
        if context.get("previous_result"):
            tags.append("follow_up")
        if context.get("code"):
            tags.append("code_context")
        if context.get("binary_path"):
            tags.append("binary_context")
        
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
                "analytics_engine": hasattr(self, 'analytics_engine') and self.analytics_engine is not None,
                "ecm_orchestrator": hasattr(self, 'ecm_orchestrator') and self.ecm_orchestrator is not None,
                "reverse_engineering_engine": hasattr(self, 'reverse_engineering_engine') and self.reverse_engineering_engine is not None,
                "evolution_bridge": hasattr(self, 'evolution_bridge') and self.evolution_bridge is not None,
                "competition_system": hasattr(self, 'competition_system') and self.competition_system is not None,
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
                "enable_competition": self.config.enable_competition,
                "enable_ecm": self.config.enable_ecm,
                "enable_evolution_bridge": self.config.enable_evolution_bridge,
                "enable_analytics": self.config.enable_analytics,
                "enable_plugins": self.config.enable_plugins,
                "enable_goals": self.config.enable_goals,
                "enable_telemetry": self.config.enable_telemetry,
                "worker_count": self.config.worker_count,
                "safety_mode": self.config.safety_mode
            }
        }
        
        # Add component-specific status
        if self.plugin_registry:
            status["plugins"] = {
                "total_tools": len(self.plugin_registry.tools),
                "tool_statistics": self.plugin_registry.get_tool_statistics()
            }
        
        if self.analytics_engine:
            status["analytics"] = self.analytics_engine.get_analytics_summary()
        
        if self.ecm_orchestrator:
            status["ecm"] = {
                "enabled": True,
                "status": "ready"
            }
        
        if self.evolution_bridge:
            status["evolution_bridge"] = {
                "enabled": True,
                "cached_hypotheses": len(self.evolution_bridge.rule_cache)
            }
        
        if self.competition_system:
            status["competition"] = get_marketplace_status()
        
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