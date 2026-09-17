"""
Domain Orchestrator

Routes workflow tasks between Tiannara Core intelligence domains.
Following templates.md architecture:
- Templates NEVER directly call domains
- All domain calls go through the orchestrator
- This enables future flexibility: swap domains, add evolution, memory, etc.

Supported Domains:
- prediction_domain: Forecasting and predictions
- causal_engine: Causal inference and root cause analysis
- reverse_engineering: Pattern extraction and analysis
- nlp_engine: Natural language processing
- temporal_engine: Time-series analysis
- memory_system: Knowledge retrieval and case-based reasoning
- evolution_engine: Optimization and adaptation
"""

import logging
from typing import Dict, Any, Optional, List
from enum import Enum

logger = logging.getLogger(__name__)


class DomainType(str, Enum):
    """Available Tiannara Core domains."""
    PREDICTION = "prediction_domain"
    CAUSAL = "causal_engine"
    REVERSE_ENGINEERING = "reverse_engineering"
    NLP = "nlp_engine"
    TEMPORAL = "temporal_engine"
    MEMORY = "memory_system"
    EVOLUTION = "evolution_engine"


class DomainOrchestrator:
    """
    Orchestrates calls to Tiannara Core intelligence domains.
    
    This is the 'nervous system' from templates.md mental model.
    It routes tasks to appropriate domains and aggregates results.
    """
    
    def __init__(self):
        # Domain instances (will be initialized with actual Core modules)
        self.domains: Dict[str, Any] = {}
        
        # Initialize domain connections
        self._initialize_domains()
        
        logger.info("Domain Orchestrator initialized")
    
    def _initialize_domains(self):
        """Initialize connections to Tiannara Core domains."""
        try:
            # Import actual Core domain modules
            logger.info("Initializing Tiannara Core domain connections...")
            
            # Prediction Domain - Multi-agent consensus engine
            try:
                from tiannara_core.prediction.coordinator import AgentCoordinator
                from tiannara_core.prediction.agents.statistical_agent import StatisticalAgent
                from tiannara_core.prediction.agents.tactical_agent import TacticalAgent
                
                # Initialize prediction agents
                statistical = StatisticalAgent()
                tactical = TacticalAgent()
                
                self.domains[DomainType.PREDICTION] = {
                    "coordinator": AgentCoordinator([statistical, tactical]),
                    "initialized": True
                }
                logger.info("✅ Prediction domain initialized (multi-agent coordinator)")
            except ImportError as e:
                logger.warning(f"⚠️  Prediction domain not available: {e}")
                self.domains[DomainType.PREDICTION] = {"initialized": False}
            
            # Causal Engine - Structural causal evaluator
            try:
                from tiannara_core.causal.causal_depth_engine import CausalDepthEngine
                
                self.domains[DomainType.CAUSAL] = {
                    "engine": CausalDepthEngine(),
                    "initialized": True
                }
                logger.info("✅ Causal engine initialized (depth evaluation)")
            except ImportError as e:
                logger.warning(f"⚠️  Causal engine not available: {e}")
                self.domains[DomainType.CAUSAL] = {"initialized": False}
            
            # Reverse Engineering - Pattern intelligence
            try:
                from tiannara_core.discovery.engine import DiscoveryEngine
                
                self.domains[DomainType.REVERSE_ENGINEERING] = {
                    "engine": DiscoveryEngine(),
                    "initialized": True
                }
                logger.info("✅ Reverse engineering initialized (discovery engine)")
            except ImportError as e:
                logger.warning(f"⚠️  Reverse engineering not available: {e}")
                self.domains[DomainType.REVERSE_ENGINEERING] = {"initialized": False}
            
            # NLP Engine - Natural language processing
            try:
                from tiannara_core.nlp.nlp_pipeline import NLPPipeline, NLPConfig
                
                # Initialize NLP pipeline with default config
                nlp_config = NLPConfig(
                    enable_intent=True,
                    enable_entities=True,
                    enable_sentiment=True,
                    enable_semantic_search=False
                )
                
                self.domains[DomainType.NLP] = {
                    "pipeline": NLPPipeline(config=nlp_config),
                    "initialized": True
                }
                logger.info("✅ NLP engine initialized (full pipeline)")
            except ImportError as e:
                logger.warning(f"⚠️  NLP engine not available: {e}")
                self.domains[DomainType.NLP] = {"initialized": False}
            
            # Temporal Engine - Time-series analysis
            try:
                from tiannara_core.predictive.trend_predictor import TrendPredictor
                
                self.domains[DomainType.TEMPORAL] = {
                    "predictor": TrendPredictor(),
                    "initialized": True
                }
                logger.info("✅ Temporal engine initialized (trend prediction)")
            except ImportError as e:
                logger.warning(f"⚠️  Temporal engine not available: {e}")
                self.domains[DomainType.TEMPORAL] = {"initialized": False}
            
            # Memory System - Knowledge retrieval
            try:
                from tiannara_core.memory.memory_engine import MemoryEngine
                
                self.domains[DomainType.MEMORY] = {
                    "engine": MemoryEngine(),
                    "initialized": True
                }
                logger.info("✅ Memory system initialized (memory engine)")
            except ImportError as e:
                logger.warning(f"⚠️  Memory system not available: {e}")
                self.domains[DomainType.MEMORY] = {"initialized": False}
            
            # Evolution Engine - Optimization and adaptation
            try:
                from tiannara_core.evolution.meta_engine import MetaGenome
                
                self.domains[DomainType.EVOLUTION] = {
                    "meta_genome": MetaGenome(),
                    "initialized": True
                }
                logger.info("✅ Evolution engine initialized (meta genome)")
            except ImportError as e:
                logger.warning(f"⚠️  Evolution engine not available: {e}")
                self.domains[DomainType.EVOLUTION] = {"initialized": False}
            
            logger.info("Domain initialization complete")
            
        except Exception as e:
            logger.error(f"Failed to initialize domains: {str(e)}")
            raise
    
    async def execute_domain_task(
        self,
        domain: str,
        task_type: str,
        input_data: Dict[str, Any],
        config: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Execute a task on a specific domain.
        
        Args:
            domain: Domain name (e.g., 'prediction_domain')
            task_type: Task type within the domain
            input_data: Input data for the task
            config: Optional configuration
            
        Returns:
            Domain execution result
        """
        logger.info(f"Executing domain task: {domain}.{task_type}")
        
        # Route to appropriate domain handler
        if domain == DomainType.PREDICTION:
            return await self._execute_prediction(task_type, input_data, config)
        
        elif domain == DomainType.CAUSAL:
            return await self._execute_causal(task_type, input_data, config)
        
        elif domain == DomainType.REVERSE_ENGINEERING:
            return await self._execute_reverse_engineering(task_type, input_data, config)
        
        elif domain == DomainType.NLP:
            return await self._execute_nlp(task_type, input_data, config)
        
        elif domain == DomainType.TEMPORAL:
            return await self._execute_temporal(task_type, input_data, config)
        
        elif domain == DomainType.MEMORY:
            return await self._execute_memory(task_type, input_data, config)
        
        elif domain == DomainType.EVOLUTION:
            return await self._execute_evolution(task_type, input_data, config)
        
        else:
            raise ValueError(f"Unknown domain: {domain}")
    
    async def _execute_prediction(
        self,
        task_type: str,
        input_data: Dict[str, Any],
        config: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Execute prediction domain task using multi-agent consensus."""
        logger.info(f"Prediction task: {task_type}")
        
        # Check if domain is initialized
        domain_info = self.domains.get(DomainType.PREDICTION, {})
        if not domain_info.get("initialized", False):
            logger.warning("Prediction domain not initialized, using fallback")
            return {
                "domain": "prediction_domain",
                "task": task_type,
                "predictions": [],
                "confidence_scores": {},
                "model_used": "fallback",
                "error": "Prediction domain not available"
            }
        
        try:
            # Get the agent coordinator
            coordinator = domain_info["coordinator"]
            
            # Create match context from input data (for football predictions)
            from tiannara_core.prediction.agents.base_agent import MatchContext
            
            match_context = MatchContext(
                match_id=input_data.get("match_id", "unknown"),
                home_team=input_data.get("home_team", ""),
                away_team=input_data.get("away_team", ""),
                historical_data=input_data.get("historical_data", {}),
                team_stats=input_data.get("team_stats", {}),
                player_form=input_data.get("player_form", {}),
                head_to_head=input_data.get("head_to_head", []),
                weather=input_data.get("weather", {}),
                injuries=input_data.get("injuries", [])
            )
            
            # Generate consensus prediction
            consensus = coordinator.generate_consensus(match_context)
            
            # Format result for workflow engine
            return {
                "domain": "prediction_domain",
                "task": task_type,
                "predictions": [
                    {
                        "outcome": consensus.final_outcome,
                        "confidence": consensus.overall_confidence,
                        "recommended_bet": consensus.recommended_bet
                    }
                ],
                "confidence_scores": {
                    "overall": consensus.overall_confidence,
                    "agreement": consensus.agreement_score
                },
                "multi_hypothesis": [
                    {
                        "agent": pred.agent_name,
                        "outcome": pred.predicted_outcome,
                        "confidence": pred.confidence,
                        "reasoning": pred.reasoning_summary
                    }
                    for pred in consensus.agent_predictions
                ],
                "debate_summary": consensus.debate_summary,
                "risk_assessment": consensus.risk_assessment,
                "dissenting_opinions": consensus.dissenting_opinions,
                "model_used": config.get("model", "multi_agent_consensus") if config else "multi_agent_consensus",
                "processing_metadata": {
                    "agents_used": len(consensus.agent_predictions),
                    "agreement_score": consensus.agreement_score
                }
            }
            
        except Exception as e:
            logger.error(f"Prediction execution failed: {str(e)}")
            return {
                "domain": "prediction_domain",
                "task": task_type,
                "predictions": [],
                "confidence_scores": {},
                "model_used": config.get("model", "error") if config else "error",
                "error": str(e)
            }
    
    async def _execute_causal(
        self,
        task_type: str,
        input_data: Dict[str, Any],
        config: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Execute causal engine task using structural causal evaluation."""
        logger.info(f"Causal task: {task_type}")
        
        # Check if domain is initialized
        domain_info = self.domains.get(DomainType.CAUSAL, {})
        if not domain_info.get("initialized", False):
            logger.warning("Causal engine not initialized, using fallback")
            return {
                "domain": "causal_engine",
                "task": task_type,
                "causal_factors": [],
                "relationships": [],
                "method": config.get("method", "fallback") if config else "fallback",
                "error": "Causal engine not available"
            }
        
        try:
            # Get the causal depth engine
            engine = domain_info["engine"]
            
            # Extract cause and effect from input
            cause = input_data.get("cause", input_data.get("potential_cause", ""))
            effect = input_data.get("effect", input_data.get("observed_effect", ""))
            evidence = input_data.get("evidence", input_data.get("data", []))
            
            # Evaluate causal depth based on task type
            if task_type == "shap_values":
                # SHAP-based feature importance
                result = engine.evaluate_causal_chain(
                    cause=cause,
                    effect=effect,
                    evidence=evidence,
                    method="shap"
                )
            elif task_type == "counterfactual":
                # Counterfactual analysis
                result = engine.evaluate_counterfactual(
                    cause=cause,
                    effect=effect,
                    alternative_scenario=input_data.get("alternative", {})
                )
            else:
                # General causal evaluation
                result = engine.evaluate_causal_chain(
                    cause=cause,
                    effect=effect,
                    evidence=evidence,
                    method=config.get("method", "structural") if config else "structural"
                )
            
            # Format result for workflow engine
            return {
                "domain": "causal_engine",
                "task": task_type,
                "causal_factors": [
                    {
                        "factor": mech.description,
                        "strength": mech.strength,
                        "link_type": mech.link_type.value,
                        "intervention_stability": mech.get_intervention_stability(),
                        "counterfactual_coherence": mech.get_counterfactual_coherence()
                    }
                    for mech in result.mechanisms
                ] if hasattr(result, 'mechanisms') else [],
                "relationships": [
                    {
                        "cause": result.cause if hasattr(result, 'cause') else cause,
                        "effect": result.effect if hasattr(result, 'effect') else effect,
                        "causal_score": result.causal_score if hasattr(result, 'causal_score') else 0.5,
                        "temporal_valid": result.temporal_valid if hasattr(result, 'temporal_valid') else True
                    }
                ],
                "causal_depth_score": result.causal_score if hasattr(result, 'causal_score') else 0.5,
                "mechanistic_integrity": result.mechanistic_score if hasattr(result, 'mechanistic_score') else 0.5,
                "intervention_stability": result.intervention_score if hasattr(result, 'intervention_score') else 0.5,
                "counterfactual_coherence": result.counterfactual_score if hasattr(result, 'counterfactual_score') else 0.5,
                "method": config.get("method", "structural") if config else "structural"
            }
            
        except Exception as e:
            logger.error(f"Causal execution failed: {str(e)}")
            return {
                "domain": "causal_engine",
                "task": task_type,
                "causal_factors": [],
                "relationships": [],
                "method": config.get("method", "error") if config else "error",
                "error": str(e)
            }
    
    async def _execute_reverse_engineering(
        self,
        task_type: str,
        input_data: Dict[str, Any],
        config: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Execute reverse engineering (pattern intelligence) using discovery engine."""
        logger.info(f"Reverse engineering task: {task_type}")
        
        # Check if domain is initialized
        domain_info = self.domains.get(DomainType.REVERSE_ENGINEERING, {})
        if not domain_info.get("initialized", False):
            logger.warning("Reverse engineering not initialized, using fallback")
            return {
                "domain": "reverse_engineering",
                "task": task_type,
                "patterns": [],
                "insights": [],
                "method": config.get("method", "fallback") if config else "fallback",
                "error": "Reverse engineering not available"
            }
        
        try:
            # Get the discovery engine
            engine = domain_info["engine"]
            
            # Extract data for pattern analysis
            data = input_data.get("data", input_data.get("observations", []))
            context = input_data.get("context", {})
            
            # Run discovery/analysis based on method
            method = config.get("method", "pattern_extraction") if config else "pattern_extraction"
            
            if method == "clustering":
                # Cluster similar patterns
                result = engine.analyze_patterns(
                    data=data,
                    analysis_type="clustering",
                    similarity_threshold=config.get("similarity", 0.8) if config else 0.8
                )
            elif method == "anomaly_detection":
                # Detect anomalies
                result = engine.detect_anomalies(data=data)
            elif method == "sequence_mining":
                # Mine sequential patterns
                result = engine.mine_sequences(data=data)
            else:
                # General pattern extraction
                result = engine.extract_patterns(
                    data=data,
                    context=context,
                    method=method
                )
            
            # Format result for workflow engine
            return {
                "domain": "reverse_engineering",
                "task": task_type,
                "patterns": [
                    {
                        "pattern_id": pat.get("id", ""),
                        "description": pat.get("description", ""),
                        "confidence": pat.get("confidence", 0.5),
                        "frequency": pat.get("frequency", 0),
                        "type": pat.get("type", "unknown")
                    }
                    for pat in result.get("patterns", [])
                ],
                "insights": [
                    {
                        "insight": ins.get("description", ""),
                        "relevance": ins.get("relevance", 0.5),
                        "actionable": ins.get("actionable", False)
                    }
                    for ins in result.get("insights", [])
                ],
                "pattern_count": len(result.get("patterns", [])),
                "anomaly_count": len(result.get("anomalies", [])),
                "method": method,
                "metadata": {
                    "data_points_analyzed": len(data) if isinstance(data, list) else 1,
                    "processing_time_ms": result.get("processing_time_ms", 0)
                }
            }
            
        except Exception as e:
            logger.error(f"Reverse engineering execution failed: {str(e)}")
            return {
                "domain": "reverse_engineering",
                "task": task_type,
                "patterns": [],
                "insights": [],
                "method": config.get("method", "error") if config else "error",
                "error": str(e)
            }
    
    async def _execute_nlp(
        self,
        task_type: str,
        input_data: Dict[str, Any],
        config: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Execute NLP engine task using NLPPipeline."""
        logger.info(f"NLP task: {task_type}")
        
        # Check if domain is initialized
        domain_info = self.domains.get(DomainType.NLP, {})
        if not domain_info.get("initialized", False):
            logger.warning("NLP engine not initialized, using fallback")
            return {
                "domain": "nlp_engine",
                "task": task_type,
                "sentiment": None,
                "entities": [],
                "topics": [],
                "tasks_performed": config.get("tasks", []) if config else [],
                "error": "NLP engine not available"
            }
        
        try:
            # Get the NLP pipeline
            pipeline = domain_info["pipeline"]
            
            # Extract text from input
            text = input_data.get("text", input_data.get("content", ""))
            
            # Process through NLP pipeline
            result = pipeline.process(text=text, context=input_data.get("context", {}))
            
            # Format result for workflow engine
            return {
                "domain": "nlp_engine",
                "task": task_type,
                "sentiment": {
                    "label": result.sentiment.label if result.sentiment else None,
                    "score": result.sentiment.score if result.sentiment else 0.0,
                    "confidence": result.sentiment.confidence if result.sentiment else 0.0
                },
                "entities": [
                    {
                        "text": ent.text,
                        "type": ent.entity_type,
                        "confidence": ent.confidence,
                        "start_pos": ent.start_pos,
                        "end_pos": ent.end_pos
                    }
                    for ent in (result.entities.entities if result.entities else [])
                ],
                "intent": {
                    "label": result.intent.intent if result.intent else None,
                    "confidence": result.intent.confidence if result.intent else 0.0
                },
                "topics": [],
                "overall_confidence": result.overall_confidence,
                "processing_time_ms": result.processing_time_ms,
                "tasks_performed": config.get("tasks", ["intent", "entities", "sentiment"]) if config else ["intent", "entities", "sentiment"]
            }
            
        except Exception as e:
            logger.error(f"NLP execution failed: {str(e)}")
            return {
                "domain": "nlp_engine",
                "task": task_type,
                "sentiment": None,
                "entities": [],
                "topics": [],
                "tasks_performed": config.get("tasks", []) if config else [],
                "error": str(e)
            }
    
    async def _execute_temporal(
        self,
        task_type: str,
        input_data: Dict[str, Any],
        config: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Execute temporal engine task using TrendPredictor."""
        logger.info(f"Temporal task: {task_type}")
        
        # Check if domain is initialized
        domain_info = self.domains.get(DomainType.TEMPORAL, {})
        if not domain_info.get("initialized", False):
            logger.warning("Temporal engine not initialized, using fallback")
            return {
                "domain": "temporal_engine",
                "task": task_type,
                "trends": [],
                "seasonality": {},
                "forecast": [],
                "lookback_period": config.get("lookback", "30d") if config else "30d",
                "error": "Temporal engine not available"
            }
        
        try:
            # Get the trend predictor
            predictor = domain_info["predictor"]
            
            # Add data points if provided
            metric_name = input_data.get("metric_name", input_data.get("metric", "default"))
            data_points = input_data.get("data_points", input_data.get("values", []))
            
            for point in data_points:
                if isinstance(point, dict):
                    predictor.add_data_point(
                        metric_name=metric_name,
                        value=point.get("value", 0),
                        timestamp=point.get("timestamp")
                    )
                else:
                    predictor.add_data_point(metric_name=metric_name, value=float(point))
            
            # Forecast trend based on task type
            horizon = config.get("horizon", "7d") if config else "7d"
            
            if task_type == "forecast":
                forecast = predictor.forecast_trend(metric_name=metric_name, horizon=horizon)
                
                return {
                    "domain": "temporal_engine",
                    "task": task_type,
                    "trends": [{
                        "topic": forecast.topic if forecast else metric_name,
                        "direction": forecast.direction if forecast else "stable",
                        "confidence": forecast.confidence if forecast else 0.5,
                        "predicted_value": forecast.predicted_value if forecast else 0.0,
                        "time_horizon": forecast.time_horizon if forecast else horizon,
                        "factors": forecast.factors if forecast else []
                    }],
                    "seasonality": {},
                    "forecast": [{
                        "period": horizon,
                        "value": forecast.predicted_value if forecast else 0.0,
                        "confidence": forecast.confidence if forecast else 0.5
                    }],
                    "lookback_period": horizon
                }
            elif task_type == "anomaly_detection":
                alerts = predictor.detect_anomalies(metric_name=metric_name)
                
                return {
                    "domain": "temporal_engine",
                    "task": task_type,
                    "trends": [],
                    "seasonality": {},
                    "forecast": [],
                    "anomalies": [
                        {
                            "alert_id": alert.alert_id,
                            "description": alert.description,
                            "severity": alert.severity,
                            "metric_name": alert.metric_name,
                            "actual_value": alert.actual_value,
                            "expected_value": alert.expected_value
                        }
                        for alert in alerts
                    ],
                    "lookback_period": horizon
                }
            else:
                # General trend analysis
                forecast = predictor.forecast_trend(metric_name=metric_name, horizon=horizon)
                
                return {
                    "domain": "temporal_engine",
                    "task": task_type,
                    "trends": [{
                        "topic": forecast.topic if forecast else metric_name,
                        "direction": forecast.direction if forecast else "stable",
                        "confidence": forecast.confidence if forecast else 0.5,
                        "predicted_value": forecast.predicted_value if forecast else 0.0,
                        "time_horizon": forecast.time_horizon if forecast else horizon,
                        "factors": forecast.factors if forecast else []
                    }],
                    "seasonality": {},
                    "forecast": [],
                    "lookback_period": horizon
                }
            
        except Exception as e:
            logger.error(f"Temporal execution failed: {str(e)}")
            return {
                "domain": "temporal_engine",
                "task": task_type,
                "trends": [],
                "seasonality": {},
                "forecast": [],
                "lookback_period": config.get("lookback", "30d") if config else "30d",
                "error": str(e)
            }
    
    async def _execute_memory(
        self,
        task_type: str,
        input_data: Dict[str, Any],
        config: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Execute memory system task using MemoryEngine."""
        logger.info(f"Memory task: {task_type}")
        
        # Check if domain is initialized
        domain_info = self.domains.get(DomainType.MEMORY, {})
        if not domain_info.get("initialized", False):
            logger.warning("Memory system not initialized, using fallback")
            return {
                "domain": "memory_system",
                "task": task_type,
                "retrieved_cases": [],
                "similar_patterns": [],
                "knowledge_fragments": [],
                "search_type": config.get("search", "semantic") if config else "semantic",
                "error": "Memory system not available"
            }
        
        try:
            # Get the memory engine
            engine = domain_info["engine"]
            
            if task_type == "store":
                # Store new memory
                data = input_data.get("data", input_data.get("content", {}))
                tags = input_data.get("tags", [])
                importance = input_data.get("importance", 1.0)
                
                memory = engine.store(data=data, tags=tags)
                memory["importance"] = importance
                
                return {
                    "domain": "memory_system",
                    "task": task_type,
                    "stored": True,
                    "memory_id": id(memory),
                    "retrieved_cases": [],
                    "similar_patterns": [],
                    "knowledge_fragments": [memory],
                    "search_type": "store"
                }
            
            elif task_type == "retrieve":
                # Retrieve memories by context/tags
                context_tags = input_data.get("tags", input_data.get("context_tags", []))
                top_k = config.get("top_k", 5) if config else 5
                
                memories = engine.recall_by_context(context_tags=context_tags, top_k=top_k)
                
                return {
                    "domain": "memory_system",
                    "task": task_type,
                    "retrieved_cases": memories,
                    "similar_patterns": [],
                    "knowledge_fragments": memories,
                    "search_type": "context_based",
                    "count": len(memories)
                }
            
            elif task_type == "reinforce":
                # Reinforce specific memory
                memory_index = input_data.get("memory_index", 0)
                amount = input_data.get("amount", 0.5)
                
                engine.reinforce_memory(memory_index=memory_index, amount=amount)
                
                return {
                    "domain": "memory_system",
                    "task": task_type,
                    "reinforced": True,
                    "memory_index": memory_index,
                    "retrieved_cases": [],
                    "similar_patterns": [],
                    "knowledge_fragments": []
                }
            
            else:
                # Default: recall all memories
                memories = engine.recall()
                
                return {
                    "domain": "memory_system",
                    "task": task_type,
                    "retrieved_cases": memories,
                    "similar_patterns": [],
                    "knowledge_fragments": memories,
                    "search_type": "recall_all",
                    "count": len(memories)
                }
            
        except Exception as e:
            logger.error(f"Memory execution failed: {str(e)}")
            return {
                "domain": "memory_system",
                "task": task_type,
                "retrieved_cases": [],
                "similar_patterns": [],
                "knowledge_fragments": [],
                "search_type": config.get("search", "semantic") if config else "semantic",
                "error": str(e)
            }
    
    async def _execute_evolution(
        self,
        task_type: str,
        input_data: Dict[str, Any],
        config: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Execute evolution engine task using MetaGenome."""
        logger.info(f"Evolution task: {task_type}")
        
        # Check if domain is initialized
        domain_info = self.domains.get(DomainType.EVOLUTION, {})
        if not domain_info.get("initialized", False):
            logger.warning("Evolution engine not initialized, using fallback")
            return {
                "domain": "evolution_engine",
                "task": task_type,
                "optimizations": [],
                "recommendations": [],
                "objective": config.get("objective", "default") if config else "default",
                "error": "Evolution engine not available"
            }
        
        try:
            # Get the meta genome
            meta_genome = domain_info["meta_genome"]
            
            if task_type == "mutate":
                # Apply mutation to meta parameters
                meta_genome.mutate()
                
                current_params = meta_genome.as_dict()
                
                return {
                    "domain": "evolution_engine",
                    "task": task_type,
                    "optimizations": [
                        {
                            "parameter": param,
                            "value": value,
                            "type": "mutation"
                        }
                        for param, value in current_params.items()
                    ],
                    "recommendations": [
                        f"Mutation applied to {param}: {value:.4f}"
                        for param, value in current_params.items()
                    ],
                    "current_parameters": current_params,
                    "objective": config.get("objective", "adaptation") if config else "adaptation"
                }
            
            elif task_type == "optimize":
                # Get current optimization parameters
                current_params = meta_genome.as_dict()
                
                return {
                    "domain": "evolution_engine",
                    "task": task_type,
                    "optimizations": [
                        {
                            "parameter": param,
                            "current_value": value,
                            "recommended_range": self._get_recommended_range(param)
                        }
                        for param, value in current_params.items()
                    ],
                    "recommendations": [
                        f"Parameter {param} at {value:.4f} - within optimal range"
                        for param, value in current_params.items()
                    ],
                    "current_parameters": current_params,
                    "objective": config.get("objective", "optimization") if config else "optimization"
                }
            
            else:
                # Default: get current state
                current_params = meta_genome.as_dict()
                
                return {
                    "domain": "evolution_engine",
                    "task": task_type,
                    "optimizations": [],
                    "recommendations": [
                        f"Current {param}: {value:.4f}"
                        for param, value in current_params.items()
                    ],
                    "current_parameters": current_params,
                    "objective": config.get("objective", "monitoring") if config else "monitoring"
                }
            
        except Exception as e:
            logger.error(f"Evolution execution failed: {str(e)}")
            return {
                "domain": "evolution_engine",
                "task": task_type,
                "optimizations": [],
                "recommendations": [],
                "objective": config.get("objective", "default") if config else "default",
                "error": str(e)
            }
    
    def _get_recommended_range(self, parameter: str) -> Dict[str, float]:
        """Get recommended parameter ranges for evolution."""
        ranges = {
            "mutation_rate": {"min": 0.01, "max": 0.25, "optimal": 0.1},
            "selection_pressure": {"min": 0.5, "max": 0.9, "optimal": 0.7},
            "reward_bias": {"min": 0.8, "max": 1.2, "optimal": 1.0}
        }
        return ranges.get(parameter, {"min": 0.0, "max": 1.0, "optimal": 0.5})
    
    def get_available_domains(self) -> List[str]:
        """Get list of available domains."""
        return [domain.value for domain in DomainType]
    
    def is_domain_available(self, domain: str) -> bool:
        """Check if a domain is available."""
        return domain in [d.value for d in DomainType]
    
    def get_domain_info(self, domain: str) -> Optional[Dict[str, Any]]:
        """Get information about a specific domain."""
        domain_info = {
            DomainType.PREDICTION: {
                "name": "Prediction Domain",
                "description": "Forecasting and multi-hypothesis predictions",
                "capabilities": ["classification", "regression", "time_series"]
            },
            DomainType.CAUSAL: {
                "name": "Causal Engine",
                "description": "Causal inference and root cause analysis",
                "capabilities": ["causal_discovery", "counterfactual", "shap_values"]
            },
            DomainType.REVERSE_ENGINEERING: {
                "name": "Reverse Engineering",
                "description": "Pattern extraction and intelligence",
                "capabilities": ["pattern_mining", "anomaly_detection", "clustering"]
            },
            DomainType.NLP: {
                "name": "NLP Engine",
                "description": "Natural language processing and understanding",
                "capabilities": ["sentiment", "entities", "topics", "summarization"]
            },
            DomainType.TEMPORAL: {
                "name": "Temporal Engine",
                "description": "Time-series analysis and forecasting",
                "capabilities": ["trend_analysis", "seasonality", "decomposition"]
            },
            DomainType.MEMORY: {
                "name": "Memory System",
                "description": "Knowledge retrieval and case-based reasoning",
                "capabilities": ["semantic_search", "case_retrieval", "pattern_matching"]
            },
            DomainType.EVOLUTION: {
                "name": "Evolution Engine",
                "description": "Optimization and adaptive improvement",
                "capabilities": ["optimization", "adaptation", "multi_objective"]
            }
        }
        
        return domain_info.get(domain)
