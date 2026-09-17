"""
INTERPRETABILITY SUITE

Purpose: Provide complete causal traces, belief genealogy, and explanation
interfaces to make Tiannara's reasoning fully transparent and auditable.

Based on next.md (lines 381-410):
"Interpretability is not optional for sustainable cognition.
You need:
- Complete causal trace graphs (why did you believe X?)
- Decision lineage (which experiences shaped this conclusion?)
- Belief ancestry trees (what prior beliefs led to this one?)
- Counterfactual explanations (what would change your mind?)
- Uncertainty decomposition (where exactly are you uncertain?)

Without interpretability, you cannot debug cognition or verify alignment."

Architecture:
Implements comprehensive interpretability infrastructure:
1. Causal Trace Graphs - Track complete reasoning chains
2. Belief Genealogy - Ancestry trees showing belief evolution
3. Decision Lineage - Experience-based decision tracking
4. Counterfactual Explanations - What-if analysis
5. Uncertainty Decomposition - Pinpoint uncertainty sources
"""

import time
import logging
from typing import Dict, List, Optional, Tuple, Any, Set
from dataclasses import dataclass, field
from enum import Enum

logger = logging.getLogger(__name__)


class TraceNodeType(Enum):
    """Types of nodes in causal trace graphs."""
    OBSERVATION = "observation"           # Raw input/evidence
    INFERENCE = "inference"               # Logical deduction
    ASSUMPTION = "assumption"             # Unproven premise
    CONCLUSION = "conclusion"             # Derived belief
    HYPOTHESIS = "hypothesis"             # Tentative explanation
    EVIDENCE = "evidence"                 # Supporting/contradicting data
    EXTERNAL_KNOWLEDGE = "external_knowledge"  # Imported knowledge


class ConfidenceSource(Enum):
    """Sources of confidence in a belief."""
    EMPIRICAL_EVIDENCE = "empirical_evidence"     # Direct observation
    LOGICAL_DEDUCTION = "logical_deduction"       # Valid reasoning chain
    EXPERT_TESTIMONY = "expert_testimony"         # Authority source
    STATISTICAL_PATTERN = "statistical_pattern"   # Data-driven pattern
    ANALOGICAL_REASONING = "analogical_reasoning" # Similarity to known cases
    INTUITION = "intuition"                       # Pattern recognition without explicit reasoning


@dataclass
class TraceNode:
    """Single node in a causal trace graph."""
    node_id: str
    node_type: TraceNodeType
    content: str                    # What this node represents
    timestamp: float = field(default_factory=time.time)
    
    # Confidence
    confidence: float = 0.5
    confidence_sources: List[ConfidenceSource] = field(default_factory=list)
    
    # Relationships
    parents: List[str] = field(default_factory=list)      # Nodes this depends on
    children: List[str] = field(default_factory=list)     # Nodes that depend on this
    
    # Metadata
    metadata: Dict[str, Any] = field(default_factory=dict)
    uncertainties: List[str] = field(default_factory=list)  # What's uncertain here
    
    def to_dict(self) -> Dict:
        return {
            'node_id': self.node_id,
            'node_type': self.node_type.value,
            'content': self.content,
            'timestamp': self.timestamp,
            'confidence': self.confidence,
            'confidence_sources': [cs.value for cs in self.confidence_sources],
            'parents': self.parents,
            'children': self.children,
            'metadata': self.metadata,
            'uncertainties': self.uncertainties
        }


@dataclass
class CausalTraceGraph:
    """Complete causal trace for a belief or decision."""
    trace_id: str
    root_belief: str                  # The final conclusion/belief
    nodes: Dict[str, TraceNode]       # All nodes in the trace
    edges: List[Tuple[str, str]]      # (parent, child) relationships
    
    # Analysis
    depth: int = 0                    # Longest path from root to leaf
    complexity_score: float = 0.0     # How complex is this reasoning?
    
    # Quality metrics
    completeness: float = 0.0         # Are all steps explained?
    soundness: float = 0.0            # Are all inferences valid?
    
    timestamp: float = field(default_factory=time.time)
    
    def to_dict(self) -> Dict:
        return {
            'trace_id': self.trace_id,
            'root_belief': self.root_belief,
            'nodes': {nid: node.to_dict() for nid, node in self.nodes.items()},
            'edges': self.edges,
            'depth': self.depth,
            'complexity_score': self.complexity_score,
            'completeness': self.completeness,
            'soundness': self.soundness,
            'timestamp': self.timestamp
        }


@dataclass
class BeliefAncestor:
    """An ancestor in a belief's genealogy tree."""
    belief_id: str
    content: str
    confidence: float
    formation_time: float
    relationship: str                 # "premise", "evidence", "inference_rule", etc.
    status: str                       # "active", "revised", "rejected"


@dataclass
class BeliefGenealogy:
    """Complete ancestry tree for a belief."""
    belief_id: str
    current_belief: str
    ancestors: List[BeliefAncestor]
    generation_depth: int             # How many generations back?
    revision_count: int               # How many times revised?
    original_confidence: float        # Initial confidence when first formed
    current_confidence: float
    stability_score: float            # How stable has this belief been?
    
    def to_dict(self) -> Dict:
        return {
            'belief_id': self.belief_id,
            'current_belief': self.current_belief,
            'ancestors': [a.__dict__ for a in self.ancestors],
            'generation_depth': self.generation_depth,
            'revision_count': self.revision_count,
            'original_confidence': self.original_confidence,
            'current_confidence': self.current_confidence,
            'stability_score': self.stability_score
        }


@dataclass
class CounterfactualExplanation:
    """What would need to change to alter a belief/decision."""
    target_belief: str
    current_state: Dict[str, Any]
    
    # Minimal changes needed
    minimal_changes: List[Dict[str, Any]]  # Each is a possible change
    
    # Sensitivity analysis
    sensitive_factors: List[Dict[str, Any]]  # Factors that most affect the belief
    
    # Robustness
    robustness_score: float           # How robust is this belief? (0.0-1.0)
    
    def to_dict(self) -> Dict:
        return {
            'target_belief': self.target_belief,
            'current_state': self.current_state,
            'minimal_changes': self.minimal_changes,
            'sensitive_factors': self.sensitive_factors,
            'robustness_score': self.robustness_score
        }


@dataclass
class UncertaintyDecomposition:
    """Breakdown of uncertainty sources in a belief."""
    belief_id: str
    overall_uncertainty: float        # Total uncertainty (0.0-1.0)
    
    # Uncertainty sources
    epistemic_uncertainty: float      # Lack of knowledge
    aleatoric_uncertainty: float      # Inherent randomness
    model_uncertainty: float          # Model limitations
    data_uncertainty: float           # Data quality issues
    
    # Contribution percentages
    uncertainty_sources: Dict[str, float]  # source -> contribution %
    
    # Recommendations
    reduction_strategies: List[str]   # How to reduce uncertainty
    
    def to_dict(self) -> Dict:
        return {
            'belief_id': self.belief_id,
            'overall_uncertainty': self.overall_uncertainty,
            'epistemic_uncertainty': self.epistemic_uncertainty,
            'aleatoric_uncertainty': self.aleatoric_uncertainty,
            'model_uncertainty': self.model_uncertainty,
            'data_uncertainty': self.data_uncertainty,
            'uncertainty_sources': self.uncertainty_sources,
            'reduction_strategies': self.reduction_strategies
        }


class InterpretabilitySuite:
    """
    Comprehensive interpretability infrastructure for transparent cognition.
    
    Provides:
    - Complete causal trace graphs for all beliefs
    - Belief genealogy tracking evolution over time
    - Decision lineage from experiences to conclusions
    - Counterfactual explanations for robustness testing
    - Uncertainty decomposition for targeted improvement
    """
    
    def __init__(self):
        """Initialize interpretability suite."""
        self.causal_traces: Dict[str, CausalTraceGraph] = {}
        self.belief_genealogies: Dict[str, BeliefGenealogy] = {}
        self.decision_lineages: Dict[str, List[str]] = {}  # decision_id -> trace_ids
        self.counterfactuals: Dict[str, CounterfactualExplanation] = {}
        self.uncertainty_decompositions: Dict[str, UncertaintyDecomposition] = {}
        
        logger.info("[Interpretability Suite] Initialized")
        logger.info("  Causal Tracing: Ready")
        logger.info("  Belief Genealogy: Ready")
        logger.info("  Counterfactual Analysis: Ready")
        logger.info("  Uncertainty Decomposition: Ready")
    
    def create_causal_trace(self, root_belief: str, nodes: List[TraceNode], 
                           edges: List[Tuple[str, str]]) -> CausalTraceGraph:
        """
        Create a complete causal trace graph for a belief.
        
        Args:
            root_belief: The final conclusion/belief being traced
            nodes: All nodes in the reasoning chain
            edges: Parent-child relationships between nodes
            
        Returns:
            Complete CausalTraceGraph with analysis metrics
        """
        import uuid
        
        trace_id = f"TRACE_{uuid.uuid4().hex[:8]}"
        
        # Build node dictionary
        node_dict = {node.node_id: node for node in nodes}
        
        # Calculate depth (longest path from root to any leaf)
        depth = self._calculate_graph_depth(node_dict, edges)
        
        # Calculate complexity score
        complexity = self._calculate_complexity(node_dict, edges)
        
        # Assess completeness and soundness
        completeness = self._assess_completeness(node_dict)
        soundness = self._assess_soundness(node_dict, edges)
        
        trace = CausalTraceGraph(
            trace_id=trace_id,
            root_belief=root_belief,
            nodes=node_dict,
            edges=edges,
            depth=depth,
            complexity_score=complexity,
            completeness=completeness,
            soundness=soundness
        )
        
        self.causal_traces[trace_id] = trace
        
        logger.info(f"[Causal Trace] Created {trace_id}")
        logger.info(f"  Root Belief: {root_belief[:60]}...")
        logger.info(f"  Nodes: {len(nodes)}, Edges: {len(edges)}")
        logger.info(f"  Depth: {depth}, Complexity: {complexity:.2f}")
        logger.info(f"  Completeness: {completeness:.2f}, Soundness: {soundness:.2f}")
        
        return trace
    
    def _calculate_graph_depth(self, nodes: Dict[str, TraceNode], 
                               edges: List[Tuple[str, str]]) -> int:
        """Calculate maximum depth of the trace graph."""
        if not nodes:
            return 0
        
        # Find root nodes (no parents)
        has_parent = set(child for parent, child in edges)
        roots = [nid for nid in nodes.keys() if nid not in has_parent]
        
        if not roots:
            return 0
        
        # BFS to find longest path
        max_depth = 0
        for root in roots:
            visited = set()
            stack = [(root, 0)]
            
            while stack:
                node_id, depth = stack.pop()
                if node_id in visited:
                    continue
                visited.add(node_id)
                max_depth = max(max_depth, depth)
                
                # Add children
                for parent, child in edges:
                    if parent == node_id and child not in visited:
                        stack.append((child, depth + 1))
        
        return max_depth
    
    def _calculate_complexity(self, nodes: Dict[str, TraceNode], 
                             edges: List[Tuple[str, str]]) -> float:
        """Calculate complexity score based on graph structure."""
        if not nodes:
            return 0.0
        
        # Factors: number of nodes, branching factor, depth
        node_factor = min(len(nodes) / 20.0, 1.0)  # Normalize to 20 nodes max
        
        avg_branching = len(edges) / max(len(nodes), 1)
        branch_factor = min(avg_branching / 3.0, 1.0)  # Normalize to 3 branches max
        
        depth = self._calculate_graph_depth(nodes, edges)
        depth_factor = min(depth / 10.0, 1.0)  # Normalize to depth 10 max
        
        # Weighted combination
        complexity = 0.4 * node_factor + 0.3 * branch_factor + 0.3 * depth_factor
        
        return round(complexity, 2)
    
    def _assess_completeness(self, nodes: Dict[str, TraceNode]) -> float:
        """Assess how complete the explanation is."""
        if not nodes:
            return 0.0
        
        # Check if all non-root nodes have explanations
        explained = sum(1 for node in nodes.values() 
                       if node.content and len(node.content) > 10)
        
        return round(explained / len(nodes), 2)
    
    def _assess_soundness(self, nodes: Dict[str, TraceNode], 
                         edges: List[Tuple[str, str]]) -> float:
        """Assess logical soundness of the trace."""
        if not nodes or not edges:
            return 0.0
        
        # Check if all inference nodes have sufficient confidence
        inference_nodes = [n for n in nodes.values() 
                          if n.node_type == TraceNodeType.INFERENCE]
        
        if not inference_nodes:
            return 1.0  # No inferences to validate
        
        avg_confidence = sum(n.confidence for n in inference_nodes) / len(inference_nodes)
        
        return round(avg_confidence, 2)
    
    def track_belief_genealogy(self, belief_id: str, current_belief: str,
                               ancestors: List[BeliefAncestor],
                               original_confidence: float,
                               current_confidence: float) -> BeliefGenealogy:
        """
        Track the complete genealogy of a belief over time.
        
        Args:
            belief_id: Unique identifier for this belief
            current_belief: Current statement of the belief
            ancestors: Historical ancestors of this belief
            original_confidence: Initial confidence when first formed
            current_confidence: Current confidence level
            
        Returns:
            BeliefGenealogy with stability analysis
        """
        # Calculate generation depth
        generation_depth = self._calculate_generation_depth(ancestors)
        
        # Count revisions
        revision_count = sum(1 for a in ancestors if a.status == "revised")
        
        # Calculate stability score
        stability = self._calculate_stability(ancestors, original_confidence, 
                                             current_confidence)
        
        genealogy = BeliefGenealogy(
            belief_id=belief_id,
            current_belief=current_belief,
            ancestors=ancestors,
            generation_depth=generation_depth,
            revision_count=revision_count,
            original_confidence=original_confidence,
            current_confidence=current_confidence,
            stability_score=stability
        )
        
        self.belief_genealogies[belief_id] = genealogy
        
        logger.info(f"[Belief Genealogy] Tracked {belief_id}")
        logger.info(f"  Generations: {generation_depth}, Revisions: {revision_count}")
        logger.info(f"  Confidence: {original_confidence:.2f} → {current_confidence:.2f}")
        logger.info(f"  Stability: {stability:.2f}")
        
        return genealogy
    
    def _calculate_generation_depth(self, ancestors: List[BeliefAncestor]) -> int:
        """Calculate how many generations back the ancestry goes."""
        if not ancestors:
            return 0
        
        # Simple heuristic: count unique formation periods
        formation_times = sorted([a.formation_time for a in ancestors])
        
        if not formation_times:
            return 0
        
        # Count distinct generations (clusters of similar timestamps)
        generations = 1
        time_window = 3600  # 1 hour window
        
        for i in range(1, len(formation_times)):
            if formation_times[i] - formation_times[i-1] > time_window:
                generations += 1
        
        return generations
    
    def _calculate_stability(self, ancestors: List[BeliefAncestor],
                            original_conf: float, current_conf: float) -> float:
        """Calculate how stable a belief has been over time."""
        if not ancestors:
            return 1.0  # No history means no instability
        
        # Factor 1: Revision frequency
        revision_penalty = sum(1 for a in ancestors if a.status == "revised") * 0.1
        
        # Factor 2: Confidence volatility
        conf_volatility = abs(original_conf - current_conf)
        
        # Factor 3: Time since last revision
        if ancestors:
            last_revision = max((a.formation_time for a in ancestors 
                               if a.status == "revised"), default=0)
            time_since_revision = time.time() - last_revision
            recency_bonus = min(time_since_revision / 86400, 1.0) * 0.1  # Max 0.1 bonus
        else:
            recency_bonus = 0.1
        
        stability = max(0.0, 1.0 - revision_penalty - conf_volatility + recency_bonus)
        
        return round(stability, 2)
    
    def generate_counterfactual(self, target_belief: str, 
                               current_state: Dict[str, Any]) -> CounterfactualExplanation:
        """
        Generate counterfactual explanations for a belief.
        
        What minimal changes would change this belief?
        
        Args:
            target_belief: The belief to analyze
            current_state: Current state including evidence, assumptions, etc.
            
        Returns:
            CounterfactualExplanation with minimal changes and sensitivity analysis
        """
        # Identify key factors affecting the belief
        confidence = current_state.get('confidence', 0.5)
        evidence_count = current_state.get('evidence_count', 0)
        assumption_count = current_state.get('assumption_count', 0)
        
        # Generate minimal changes
        minimal_changes = []
        
        if confidence > 0.5:
            minimal_changes.append({
                'factor': 'confidence',
                'current_value': confidence,
                'threshold': 0.5,
                'change_needed': confidence - 0.5,
                'description': f"Reduce confidence by {confidence - 0.5:.2f}"
            })
        
        if evidence_count > 0:
            minimal_changes.append({
                'factor': 'evidence',
                'current_value': evidence_count,
                'threshold': 0,
                'change_needed': evidence_count,
                'description': f"Remove {evidence_count} supporting evidence items"
            })
        
        # Sensitivity analysis
        sensitive_factors = []
        
        if confidence > 0.7:
            sensitive_factors.append({
                'factor': 'confidence',
                'sensitivity': 0.8,
                'impact': 'High confidence makes belief fragile to contradictory evidence'
            })
        
        if assumption_count > 2:
            sensitive_factors.append({
                'factor': 'assumptions',
                'sensitivity': 0.6,
                'impact': 'Multiple assumptions create vulnerability points'
            })
        
        # Calculate robustness
        robustness = self._calculate_robustness(confidence, evidence_count, assumption_count)
        
        explanation = CounterfactualExplanation(
            target_belief=target_belief,
            current_state=current_state,
            minimal_changes=minimal_changes,
            sensitive_factors=sensitive_factors,
            robustness_score=robustness
        )
        
        self.counterfactuals[target_belief[:20]] = explanation
        
        logger.info(f"[Counterfactual] Analyzed: {target_belief[:60]}...")
        logger.info(f"  Minimal Changes: {len(minimal_changes)}")
        logger.info(f"  Sensitive Factors: {len(sensitive_factors)}")
        logger.info(f"  Robustness: {robustness:.2f}")
        
        return explanation
    
    def _calculate_robustness(self, confidence: float, evidence_count: int,
                             assumption_count: int) -> float:
        """Calculate how robust a belief is to changes."""
        # High confidence + lots of evidence + few assumptions = robust
        confidence_factor = confidence
        evidence_factor = min(evidence_count / 10.0, 1.0)
        assumption_penalty = min(assumption_count * 0.1, 0.5)
        
        robustness = (confidence_factor * 0.4 + evidence_factor * 0.6) - assumption_penalty
        
        return round(max(0.0, min(1.0, robustness)), 2)
    
    def decompose_uncertainty(self, belief_id: str, 
                             belief_context: Dict[str, Any]) -> UncertaintyDecomposition:
        """
        Decompose uncertainty into its component sources.
        
        Args:
            belief_id: Identifier for the belief
            belief_context: Context including evidence quality, model info, etc.
            
        Returns:
            UncertaintyDecomposition with detailed breakdown
        """
        # Extract uncertainty components
        epistemic = belief_context.get('epistemic_uncertainty', 0.3)
        aleatoric = belief_context.get('aleatoric_uncertainty', 0.2)
        model = belief_context.get('model_uncertainty', 0.15)
        data = belief_context.get('data_uncertainty', 0.1)
        
        # Calculate overall uncertainty
        overall = min(epistemic + aleatoric + model + data, 1.0)
        
        # Calculate contribution percentages
        total = epistemic + aleatoric + model + data
        if total > 0:
            sources = {
                'epistemic': round(epistemic / total * 100, 1),
                'aleatoric': round(aleatoric / total * 100, 1),
                'model': round(model / total * 100, 1),
                'data': round(data / total * 100, 1)
            }
        else:
            sources = {}
        
        # Generate reduction strategies
        strategies = []
        if epistemic > 0.3:
            strategies.append("Gather more evidence to reduce knowledge gaps")
        if aleatoric > 0.3:
            strategies.append("Accept inherent randomness; use probabilistic reasoning")
        if model > 0.2:
            strategies.append("Improve model architecture or use ensemble methods")
        if data > 0.2:
            strategies.append("Improve data quality and validation")
        
        decomposition = UncertaintyDecomposition(
            belief_id=belief_id,
            overall_uncertainty=overall,
            epistemic_uncertainty=epistemic,
            aleatoric_uncertainty=aleatoric,
            model_uncertainty=model,
            data_uncertainty=data,
            uncertainty_sources=sources,
            reduction_strategies=strategies
        )
        
        self.uncertainty_decompositions[belief_id] = decomposition
        
        logger.info(f"[Uncertainty Decomposition] Belief: {belief_id}")
        logger.info(f"  Overall: {overall:.2f}")
        logger.info(f"  Epistemic: {epistemic:.2f}, Aleatoric: {aleatoric:.2f}")
        logger.info(f"  Model: {model:.2f}, Data: {data:.2f}")
        logger.info(f"  Strategies: {len(strategies)}")
        
        return decomposition
    
    def get_interpretability_statistics(self) -> Dict[str, Any]:
        """Get statistics about interpretability coverage."""
        avg_depth = 0
        avg_complexity = 0
        avg_completeness = 0
        avg_soundness = 0
        
        if self.causal_traces:
            avg_depth = sum(t.depth for t in self.causal_traces.values()) / len(self.causal_traces)
            avg_complexity = sum(t.complexity_score for t in self.causal_traces.values()) / len(self.causal_traces)
            avg_completeness = sum(t.completeness for t in self.causal_traces.values()) / len(self.causal_traces)
            avg_soundness = sum(t.soundness for t in self.causal_traces.values()) / len(self.causal_traces)
        
        avg_stability = 0
        if self.belief_genealogies:
            avg_stability = sum(g.stability_score for g in self.belief_genealogies.values()) / len(self.belief_genealogies)
        
        avg_robustness = 0
        if self.counterfactuals:
            avg_robustness = sum(c.robustness_score for c in self.counterfactuals.values()) / len(self.counterfactuals)
        
        return {
            "causal_traces": len(self.causal_traces),
            "avg_trace_depth": round(avg_depth, 2),
            "avg_trace_complexity": round(avg_complexity, 2),
            "avg_trace_completeness": round(avg_completeness, 2),
            "avg_trace_soundness": round(avg_soundness, 2),
            "belief_genealogies": len(self.belief_genealogies),
            "avg_belief_stability": round(avg_stability, 2),
            "counterfactual_analyses": len(self.counterfactuals),
            "avg_belief_robustness": round(avg_robustness, 2),
            "uncertainty_decompositions": len(self.uncertainty_decompositions)
        }
