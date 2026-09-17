"""
Explanation Engine for Explainable ECM

Master orchestrator that integrates all explainability components into a unified API.
Provides end-to-end explanation generation with caching, auditing, and compliance support.

Key Features:
- Unified API for causal path extraction, counterfactuals, and narratives
- Automatic confidence calibration for all explanations
- Immutable audit logging for regulatory compliance
- Caching layer for performance optimization
- Audience-adaptive explanation generation
- Integration with ECM graphs and intervention tracking

Usage:
    from tiannara_core.interpretability.explanation_engine import ExplanationEngine
    
    engine = ExplanationEngine()
    
    # Generate comprehensive explanation for a decision
    explanation = engine.explain_decision(
        ecm_graph=graph,
        target_node="final_outcome",
        audience="end_user"
    )
    
    # Answer what-if question
    result = engine.answer_what_if(
        graph=graph,
        question="What if we increased skill_memory by 0.2?"
    )
    
    # Get audit trail for compliance
    records = engine.get_audit_records(user_id="user_123")

References:
    Miller, T. (2019). Explanation in artificial intelligence: Insights from the social sciences.
    EU AI Act Articles 13-15: Transparency and explainability requirements
"""

import logging
import hashlib
import numpy as np
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime

from .causal_path_tracer import CausalPathTracer, CausalPath, PathExplanation
from .counterfactual_engine import CounterfactualEngine, CounterfactualResult, CounterfactualQuery
from .nlg import NaturalLanguageGenerator, NarrativeExplanation, AudienceLevel
from .confidence_calibration import ConfidenceCalibration, CalibrationResult
from .audit_trail import ExplanationAuditTrail

logger = logging.getLogger(__name__)


@dataclass
class ComprehensiveExplanation:
    """Complete explanation combining all components."""
    # Core explanation
    explanation_text: str
    explanation_type: str  # 'causal_path', 'counterfactual', 'combined'
    
    # Causal structure
    causal_path: Optional[CausalPath] = None
    interventions_applied: Optional[List[Dict]] = None
    
    # Uncertainty quantification
    confidence: float = 1.0
    calibration_result: Optional[CalibrationResult] = None
    
    # Metadata
    target_node: str = ""
    source_nodes: List[str] = field(default_factory=list)
    audience_level: str = "technical"
    
    # Audit information
    record_id: Optional[str] = None
    timestamp: str = ""
    
    # Additional context
    alternative_paths: List[CausalPath] = field(default_factory=list)
    uncertainty_notes: List[str] = field(default_factory=list)
    mermaid_diagram: Optional[str] = None


class ExplanationEngine:
    """
    Master orchestrator for the Explainable ECM system.
    
    Integrates:
    - CausalPathTracer: Extract reasoning paths from ECM graphs
    - CounterfactualEngine: Answer what-if questions
    - NaturalLanguageGenerator: Convert to human-readable narratives
    - ConfidenceCalibration: Quantify uncertainty
    - ExplanationAuditTrail: Log for compliance
    
    Provides caching, unified API, and automatic component orchestration.
    """
    
    def __init__(
        self,
        audit_db_path: str = "explanation_audit.db",
        cache_enabled: bool = True,
        default_audience: str = "technical"
    ):
        """
        Initialize explanation engine.
        
        Args:
            audit_db_path: Path to audit trail database
            cache_enabled: Enable explanation caching
            default_audience: Default audience level for explanations
        """
        # Initialize components
        self.path_tracer = CausalPathTracer()
        self.counterfactual_engine = CounterfactualEngine()
        self.nlg = NaturalLanguageGenerator()
        self.calibrator = ConfidenceCalibration()
        self.audit_trail = ExplanationAuditTrail(db_path=audit_db_path)
        
        # Configuration
        self.cache_enabled = cache_enabled
        self.default_audience = default_audience
        self.explanation_cache: Dict[str, ComprehensiveExplanation] = {}
        
        logger.info(f"ExplanationEngine initialized (cache={cache_enabled}, "
                   f"audience={default_audience})")
    
    def explain_decision(
        self,
        ecm_graph: Dict,
        target_node: str,
        source_node: Optional[str] = None,
        audience: Optional[str] = None,
        include_counterfactuals: bool = True,
        include_uncertainty: bool = True,
        user_id: Optional[str] = None,
        session_id: Optional[str] = None
    ) -> ComprehensiveExplanation:
        """
        Generate comprehensive explanation for a decision/outcome.
        
        Orchestrates all components:
        1. Extract causal path from ECM graph
        2. Calibrate confidence in the path
        3. Generate natural language narrative
        4. Optionally generate counterfactual explanations
        5. Log to audit trail
        
        Args:
            ecm_graph: The ECM graph (nodes and edges)
            target_node: Node to explain
            source_node: Optional source node (if None, finds best path)
            audience: Audience level ('technical', 'regulatory', 'end_user')
            include_counterfactuals: Include what-if analysis
            include_uncertainty: Include confidence calibration
            user_id: User requesting explanation (for audit)
            session_id: Session context (for audit)
            
        Returns:
            ComprehensiveExplanation with all components integrated
        """
        audience = audience or self.default_audience
        
        # Check cache first
        cache_key = self._generate_cache_key(
            "decision", target_node, source_node, audience
        )
        if self.cache_enabled and cache_key in self.explanation_cache:
            logger.debug(f"Cache hit for {cache_key}")
            return self.explanation_cache[cache_key]
        
        # Step 1: Extract causal path
        causal_path = None
        try:
            causal_path = self.path_tracer.extract_path(
                target=target_node,
                source=source_node
            )
        except Exception as e:
            logger.warning(f"Path extraction failed: {e}. Using fallback path.")
        
        # Fallback: create simple path from graph edges
        if not causal_path:
            logger.info("Creating fallback path from graph edges")
            causal_path = self._create_fallback_path(ecm_graph, target_node, source_node)
        
        if not causal_path:
            raise ValueError(f"No causal path found to target node: {target_node}")
        
        # Step 2: Calibrate confidence
        calibration_result = None
        confidence = 1.0
        
        if include_uncertainty and causal_path.edges:
            # Calibrate each edge
            edge_effects = [(src, tgt, weight) for src, tgt, weight in causal_path.edges]
            sample_sizes = [100] * len(edge_effects)  # Default assumption
            
            calibrated_edges = self.calibrator.calibrate_path(
                path_effects=edge_effects,
                sample_sizes=sample_sizes,
                method='bootstrap'
            )
            
            # Propagate uncertainty through path
            calibration_result = self.calibrator.propagate_uncertainty(calibrated_edges)
            confidence = calibration_result.point_estimate
        
        # Step 3: Generate narrative
        narrative = self.nlg.explain_path(
            causal_path=causal_path,
            audience=audience,
            include_uncertainty=include_uncertainty
        )
        
        # Step 4: Generate counterfactuals (optional)
        counterfactual_result = None
        if include_counterfactuals:
            try:
                counterfactual_result = self.counterfactual_engine.find_minimal_intervention(
                    graph=ecm_graph,
                    current_outcome=confidence,
                    desired_outcome=min(confidence + 0.1, 1.0),
                    target_node=target_node
                )
            except Exception as e:
                logger.warning(f"Counterfactual generation failed: {e}")
        
        # Step 5: Build comprehensive explanation
        explanation = ComprehensiveExplanation(
            explanation_text=narrative.detailed_explanation,
            explanation_type="causal_path",
            causal_path=causal_path,
            confidence=confidence,
            calibration_result=calibration_result,
            target_node=target_node,
            source_nodes=[edge[0] for edge in causal_path.edges[:1]] if causal_path.edges else [],
            audience_level=audience,
            alternative_paths=causal_path.alternative_paths if hasattr(causal_path, 'alternative_paths') else [],
            uncertainty_notes=calibration_result.uncertainty_notes if calibration_result else [],
            mermaid_diagram=self.path_tracer.generate_mermaid_viz(causal_path),
            timestamp=datetime.now().isoformat()
        )
        
        # Add counterfactual insights if available
        if counterfactual_result:
            explanation.interventions_applied = [
                {
                    'node': change.node,
                    'current_value': change.current_value,
                    'required_value': change.required_value,
                    'impact': change.estimated_impact
                }
                for change in counterfactual_result.changes
            ]
            explanation.explanation_type = "combined"
        
        # Step 6: Log to audit trail
        record_id = self.audit_trail.log_explanation(
            explanation_text=explanation.explanation_text,
            explanation_type=explanation.explanation_type,
            target_node=target_node,
            source_nodes=explanation.source_nodes,
            confidence=confidence,
            calibration_result={
                'point_estimate': calibration_result.point_estimate,
                'confidence_interval': calibration_result.confidence_interval,
                'method': calibration_result.method
            } if calibration_result else None,
            user_id=user_id,
            session_id=session_id,
            metadata={
                'audience': audience,
                'has_counterfactuals': counterfactual_result is not None
            }
        )
        explanation.record_id = record_id
        
        # Cache the result
        if self.cache_enabled:
            self.explanation_cache[cache_key] = explanation
        
        logger.info(f"Generated explanation for {target_node} (record: {record_id})")
        return explanation
    
    def answer_what_if(
        self,
        graph: Dict,
        question: str,
        audience: Optional[str] = None,
        user_id: Optional[str] = None
    ) -> ComprehensiveExplanation:
        """
        Answer a what-if counterfactual question.
        
        Args:
            graph: ECM graph
            question: Natural language question (e.g., "What if X increased?")
            audience: Audience level
            user_id: User ID for audit
            
        Returns:
            ComprehensiveExplanation with counterfactual analysis
        """
        audience = audience or self.default_audience
        
        # Parse question and create counterfactual query
        # Simple parsing: extract node and value from "What if X increased by Y?"
        import re
        match = re.search(r'if\s+(\w+)\s+(?:increased|decreased|changed)\s+(?:by\s+)?([\d.]+)?', question, re.IGNORECASE)
        
        if match:
            target_node = match.group(1)
            change_value = float(match.group(2)) if match.group(2) else 0.1
            
            query = CounterfactualQuery(
                query_type='intervention',
                target_variable=target_node,
                intervention={target_node: change_value}
            )
        else:
            # Fallback: use first word as node
            words = question.split()
            target_node = words[3] if len(words) > 3 else "unknown"
            query = CounterfactualQuery(
                query_type='intervention',
                target_variable=target_node,
                intervention={target_node: 0.1}
            )
        
        # Generate counterfactual
        result = self.counterfactual_engine.answer_counterfactual(
            graph=graph,
            query=query
        )
        
        # Generate narrative
        narrative = self.nlg.explain_counterfactual(
            counterfactual_result=result,
            audience=audience
        )
        
        # Build explanation
        explanation = ComprehensiveExplanation(
            explanation_text=narrative.detailed_explanation,
            explanation_type="counterfactual",
            interventions_applied=[{
                'node': result.query.target_variable,
                'intervention': result.query.intervention,
                'value': result.query.intervention.get(result.query.target_variable, 0.0) if result.query.intervention else 0.0
            }],
            target_node=result.query.target_variable,
            audience_level=audience,
            timestamp=datetime.now().isoformat()
        )
        
        # Log to audit trail
        record_id = self.audit_trail.log_explanation(
            explanation_text=explanation.explanation_text,
            explanation_type="counterfactual",
            target_node=result.query.target_variable,
            confidence=1.0,
            user_id=user_id,
            metadata={'question': question}
        )
        explanation.record_id = record_id
        
        logger.info(f"Answered what-if question (record: {record_id})")
        return explanation
    
    def get_audit_records(
        self,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
        explanation_type: Optional[str] = None,
        target_node: Optional[str] = None,
        user_id: Optional[str] = None,
        limit: int = 100
    ) -> List[Dict]:
        """
        Retrieve audit records for compliance review.
        
        Args:
            start_date: Filter by start date (ISO format)
            end_date: Filter by end date (ISO format)
            explanation_type: Filter by type
            target_node: Filter by target node
            user_id: Filter by user
            limit: Maximum records to return
            
        Returns:
            List of audit record dictionaries
        """
        records = self.audit_trail.search_explanations(
            start_date=start_date,
            end_date=end_date,
            explanation_type=explanation_type,
            target_node=target_node,
            user_id=user_id,
            limit=limit
        )
        
        # Convert to dictionaries for easier consumption
        return [
            {
                'record_id': r.record_id,
                'timestamp': r.timestamp,
                'explanation_type': r.explanation_type,
                'target_node': r.target_node,
                'confidence': r.confidence,
                'user_id': r.user_id
            }
            for r in records
        ]
    
    def export_compliance_report(
        self,
        output_path: str,
        format: str = "json",
        start_date: Optional[str] = None,
        end_date: Optional[str] = None
    ) -> str:
        """
        Export compliance report for regulatory audit.
        
        Args:
            output_path: Path to output file
            format: Export format ('json' or 'csv')
            start_date: Optional date filter
            end_date: Optional date filter
            
        Returns:
            Path to exported file
        """
        return self.audit_trail.export_audit_report(
            output_path=output_path,
            format=format,
            start_date=start_date,
            end_date=end_date
        )
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get statistics about explanation generation and audit trail."""
        return {
            "cache_size": len(self.explanation_cache),
            "cache_enabled": self.cache_enabled,
            "audit_trail": self.audit_trail.get_statistics()
        }
    
    def clear_cache(self):
        """Clear explanation cache."""
        self.explanation_cache.clear()
        logger.info("Explanation cache cleared")
    
    def _generate_cache_key(
        self,
        explanation_type: str,
        target_node: str,
        source_node: Optional[str],
        audience: str
    ) -> str:
        """Generate cache key for explanation."""
        key_data = f"{explanation_type}:{target_node}:{source_node}:{audience}"
        return hashlib.md5(key_data.encode()).hexdigest()
    
    def _create_fallback_path(
        self,
        ecm_graph: Dict,
        target_node: str,
        source_node: Optional[str] = None
    ) -> Optional[CausalPath]:
        """
        Create a simple causal path from graph edges when tracer fails.
        
        Args:
            ecm_graph: Graph with 'nodes' and 'edges' keys
            target_node: Target node to reach
            source_node: Optional source node
            
        Returns:
            CausalPath or None if no path found
        """
        edges = ecm_graph.get('edges', [])
        nodes = ecm_graph.get('nodes', [])
        
        if not edges:
            return None
        
        # Build adjacency list
        adj = {}
        for src, tgt, weight in edges:
            if src not in adj:
                adj[src] = []
            adj[src].append((tgt, weight))
        
        # Find path using BFS
        if source_node is None:
            # Find all nodes that can reach target
            source_node = self._find_best_source(adj, target_node, nodes)
            if source_node is None:
                return None
        
        # BFS to find path
        from collections import deque
        queue = deque([(source_node, [source_node], [])])
        visited = {source_node}
        
        while queue:
            current, path_nodes, path_edges = queue.popleft()
            
            if current == target_node:
                # Found path
                total_effect = np.prod([w for _, _, w in path_edges]) if path_edges else 1.0
                
                # Calculate attribution scores based on edge weights
                attribution_scores = {}
                if path_edges:
                    abs_weights = [abs(w) for _, _, w in path_edges]
                    total_weight = sum(abs_weights)
                    if total_weight > 0:
                        for i, (src, tgt, w) in enumerate(path_edges):
                            attr_key = f"{src}→{tgt}"
                            attribution_scores[attr_key] = abs(w) / total_weight
                    else:
                        # Equal attribution if all weights are zero
                        for i, (src, tgt, w) in enumerate(path_edges):
                            attr_key = f"{src}→{tgt}"
                            attribution_scores[attr_key] = 1.0 / len(path_edges)
                
                return CausalPath(
                    source_node=source_node,
                    target_node=target_node,
                    intermediate_nodes=path_nodes[1:-1],
                    edges=path_edges,
                    total_effect=float(total_effect),
                    path_length=len(path_edges),
                    confidence=0.8,  # Default confidence for fallback
                    attribution_scores=attribution_scores
                )
            
            for neighbor, weight in adj.get(current, []):
                if neighbor not in visited:
                    visited.add(neighbor)
                    new_edges = path_edges + [(current, neighbor, weight)]
                    queue.append((neighbor, path_nodes + [neighbor], new_edges))
        
        return None
    
    def _find_best_source(self, adj: Dict, target: str, nodes: List[str]) -> Optional[str]:
        """Find the best source node (node with no incoming edges)."""
        # Find nodes that have outgoing edges but no incoming edges
        has_outgoing = set(adj.keys())
        has_incoming = set()
        for src, neighbors in adj.items():
            for tgt, _ in neighbors:
                has_incoming.add(tgt)
        
        # Source nodes are those with outgoing but no incoming
        potential_sources = has_outgoing - has_incoming
        
        if potential_sources:
            return list(potential_sources)[0]
        elif nodes:
            return nodes[0]  # Fallback to first node
        else:
            return None


def create_explanation_engine(
    audit_db_path: str = "explanation_audit.db",
    cache_enabled: bool = True,
    default_audience: str = "technical"
) -> ExplanationEngine:
    """
    Convenience function to create an explanation engine instance.
    
    Args:
        audit_db_path: Path to audit trail database
        cache_enabled: Enable caching
        default_audience: Default audience level
        
    Returns:
        ExplanationEngine instance
    """
    return ExplanationEngine(
        audit_db_path=audit_db_path,
        cache_enabled=cache_enabled,
        default_audience=default_audience
    )
