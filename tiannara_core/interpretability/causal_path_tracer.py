"""
Causal Path Tracer for Explainable ECM

Tracks intervention sequences and extracts reasoning paths from 
Executable Causal Manifolds (ECM) to enable transparent, auditable
causal reasoning explanations.

Key Features:
- Intervention sequence tracking
- Causal path extraction from ECM graphs
- Node attribution scoring
- Visualization-ready DAG generation
- Integration with existing ECM graph engine

Usage:
    from tiannara_core.interpretability.causal_path_tracer import CausalPathTracer
    
    tracer = CausalPathTracer()
    
    # Track interventions during ECM execution
    tracer.start_tracking()
    ecm_graph.apply_intervention('X', value=1.0)
    ecm_graph.observe('Y')
    tracer.stop_tracking()
    
    # Extract reasoning path
    path = tracer.extract_path(target='outcome', top_k=5)
    
    # Generate visualization
    viz = tracer.generate_mermaid_viz(path)

References:
    Pearl, J. (2009). Causality: Models, Reasoning, and Inference.
    Cambridge University Press.
"""

import numpy as np
import logging
from typing import Dict, List, Optional, Tuple, Set, Any
from dataclasses import dataclass, field
from datetime import datetime
from collections import defaultdict

logger = logging.getLogger(__name__)


@dataclass
class InterventionRecord:
    """Records a single intervention in the causal graph."""
    timestamp: str
    node: str
    intervention_type: str  # 'do', 'observe', 'soft_intervention'
    value: Any
    previous_value: Any
    confidence: float = 1.0
    
    def __str__(self):
        return f"{self.intervention_type}({self.node}={self.value})"


@dataclass
class CausalPath:
    """Represents a causal reasoning path through the ECM."""
    source_node: str
    target_node: str
    intermediate_nodes: List[str]
    edges: List[Tuple[str, str, float]]  # (source, target, strength)
    total_effect: float
    path_length: int
    confidence: float
    attribution_scores: Dict[str, float] = field(default_factory=dict)
    
    def __str__(self):
        path_str = " → ".join([self.source_node] + self.intermediate_nodes + [self.target_node])
        return f"{path_str} [effect={self.total_effect:.3f}, conf={self.confidence:.2f}]"


@dataclass
class PathExplanation:
    """Complete explanation of a causal reasoning path."""
    causal_path: CausalPath
    interventions_applied: List[InterventionRecord]
    observations_made: List[Dict]
    key_insights: List[str]
    alternative_paths: List[CausalPath] = field(default_factory=list)
    uncertainty_notes: List[str] = field(default_factory=list)
    
    def summary(self) -> str:
        """Generate human-readable summary."""
        lines = [
            f"Causal Path: {self.causal_path}",
            f"Interventions: {len(self.interventions_applied)}",
            f"Key Insights:",
        ]
        for insight in self.key_insights:
            lines.append(f"  • {insight}")
        
        if self.uncertainty_notes:
            lines.append(f"Uncertainty Notes:")
            for note in self.uncertainty_notes:
                lines.append(f"  ⚠️  {note}")
        
        return "\n".join(lines)


class CausalPathTracer:
    """
    Traces causal reasoning paths through Executable Causal Manifolds.
    
    Maintains a complete audit trail of interventions, observations,
    and causal effects to enable transparent explanation generation.
    """
    
    def __init__(self, max_path_length: int = 10):
        """
        Initialize path tracer.
        
        Args:
            max_path_length: Maximum path length to extract
        """
        self.max_path_length = max_path_length
        self.is_tracking = False
        
        # Intervention history
        self.intervention_log: List[InterventionRecord] = []
        
        # Observation history
        self.observation_log: List[Dict] = []
        
        # Current causal graph state (snapshot)
        self.graph_snapshot: Optional[Dict] = None
        
        # Node activation traces (for attribution)
        self.node_activations: Dict[str, List[float]] = defaultdict(list)
        
        logger.info("CausalPathTracer initialized")
    
    def start_tracking(self):
        """Begin tracking interventions and observations."""
        self.is_tracking = True
        self.intervention_log.clear()
        self.observation_log.clear()
        self.node_activations.clear()
        logger.info("Started tracking causal interventions")
    
    def stop_tracking(self):
        """Stop tracking and finalize logs."""
        self.is_tracking = False
        logger.info(f"Stopped tracking. Recorded {len(self.intervention_log)} interventions")
    
    def record_intervention(
        self,
        node: str,
        intervention_type: str,
        value: Any,
        previous_value: Any = None,
        confidence: float = 1.0
    ):
        """
        Record an intervention on a causal graph node.
        
        Args:
            node: Target node name
            intervention_type: Type of intervention ('do', 'observe', 'soft')
            value: New value after intervention
            previous_value: Value before intervention
            confidence: Confidence in intervention effect
        """
        if not self.is_tracking:
            logger.warning("Intervention recorded but tracking not active")
        
        record = InterventionRecord(
            timestamp=datetime.now().isoformat(),
            node=node,
            intervention_type=intervention_type,
            value=value,
            previous_value=previous_value,
            confidence=confidence
        )
        
        self.intervention_log.append(record)
        
        # Track node activation
        self.node_activations[node].append(value if isinstance(value, (int, float)) else 0.0)
        
        logger.debug(f"Recorded intervention: {record}")
    
    def record_observation(
        self,
        node: str,
        value: Any,
        context: Optional[Dict] = None
    ):
        """
        Record an observation from the causal graph.
        
        Args:
            node: Observed node name
            value: Observed value
            context: Additional context (e.g., conditions, metadata)
        """
        observation = {
            'timestamp': datetime.now().isoformat(),
            'node': node,
            'value': value,
            'context': context or {}
        }
        
        self.observation_log.append(observation)
        
        # Track node activation
        self.node_activations[node].append(value if isinstance(value, (int, float)) else 0.0)
        
        logger.debug(f"Recorded observation: {node}={value}")
    
    def set_graph_snapshot(self, graph_data: Dict):
        """
        Capture current state of the causal graph.
        
        Args:
            graph_data: Dictionary representation of ECM graph
                       (nodes, edges, parameters)
        """
        self.graph_snapshot = graph_data.copy()
        logger.debug("Graph snapshot captured")
    
    def extract_path(
        self,
        target: str,
        source: Optional[str] = None,
        top_k: int = 5
    ) -> List[CausalPath]:
        """
        Extract causal paths leading to target node.
        
        Args:
            target: Target node to trace paths to
            source: Optional source node (if None, finds all paths)
            top_k: Number of top paths to return (by effect strength)
            
        Returns:
            List of CausalPath objects sorted by total effect
        """
        if self.graph_snapshot is None:
            logger.warning("No graph snapshot available for path extraction")
            return []
        
        # Build adjacency from snapshot
        nodes = self.graph_snapshot.get('nodes', [])
        edges = self.graph_snapshot.get('edges', [])
        
        # Create adjacency list with weights
        adj = defaultdict(list)
        edge_weights = {}
        
        for edge in edges:
            src, tgt, weight = edge
            adj[src].append(tgt)
            edge_weights[(src, tgt)] = weight
        
        # Find all paths using DFS
        all_paths = []
        
        if source:
            # Find paths from specific source
            paths = self._find_all_paths(adj, source, target, set())
            for path in paths:
                causal_path = self._build_causal_path(path, edge_weights)
                if causal_path:
                    all_paths.append(causal_path)
        else:
            # Find paths from all root nodes to target
            root_nodes = self._find_root_nodes(adj, nodes)
            for root in root_nodes:
                paths = self._find_all_paths(adj, root, target, set())
                for path in paths:
                    causal_path = self._build_causal_path(path, edge_weights)
                    if causal_path:
                        all_paths.append(causal_path)
        
        # Sort by total effect (descending)
        all_paths.sort(key=lambda p: abs(p.total_effect), reverse=True)
        
        # Compute attribution scores
        for path in all_paths[:top_k]:
            path.attribution_scores = self._compute_attribution(path)
        
        logger.info(f"Extracted {len(all_paths)} paths, returning top {min(top_k, len(all_paths))}")
        
        return all_paths[:top_k]
    
    def _find_all_paths(
        self,
        adj: Dict[str, List[str]],
        source: str,
        target: str,
        visited: Set[str],
        path: Optional[List[str]] = None
    ) -> List[List[str]]:
        """Find all paths from source to target using DFS."""
        if path is None:
            path = []
        
        path = path + [source]
        visited.add(source)
        
        if source == target:
            return [path]
        
        if len(path) > self.max_path_length:
            return []
        
        paths = []
        for neighbor in adj.get(source, []):
            if neighbor not in visited:
                new_paths = self._find_all_paths(adj, neighbor, target, visited.copy(), path)
                paths.extend(new_paths)
        
        return paths
    
    def _build_causal_path(
        self,
        node_sequence: List[str],
        edge_weights: Dict[Tuple[str, str], float]
    ) -> Optional[CausalPath]:
        """Build CausalPath object from node sequence."""
        if len(node_sequence) < 2:
            return None
        
        source = node_sequence[0]
        target = node_sequence[-1]
        intermediates = node_sequence[1:-1]
        
        # Extract edges and compute total effect
        edges = []
        total_effect = 1.0
        
        for i in range(len(node_sequence) - 1):
            src = node_sequence[i]
            tgt = node_sequence[i + 1]
            weight = edge_weights.get((src, tgt), 0.5)  # Default weight
            edges.append((src, tgt, weight))
            total_effect *= weight
        
        # Compute confidence based on path length and edge weights
        avg_weight = np.mean([w for _, _, w in edges])
        confidence = avg_weight ** (1 / len(edges)) if edges else 0.5
        
        return CausalPath(
            source_node=source,
            target_node=target,
            intermediate_nodes=intermediates,
            edges=edges,
            total_effect=total_effect,
            path_length=len(node_sequence),
            confidence=confidence
        )
    
    def _compute_attribution(self, path: CausalPath) -> Dict[str, float]:
        """
        Compute attribution scores for each node in the path.
        
        Uses path integral method to estimate contribution of each node.
        """
        scores = {}
        
        # Source node gets initial attribution
        scores[path.source_node] = 1.0
        
        # Propagate through path
        cumulative = 1.0
        for src, tgt, weight in path.edges:
            cumulative *= weight
            scores[tgt] = cumulative
        
        # Normalize to sum to 1
        total = sum(scores.values())
        if total > 0:
            scores = {k: v / total for k, v in scores.items()}
        
        return scores
    
    def _find_root_nodes(self, adj: Dict, nodes: List[str]) -> List[str]:
        """Find root nodes (nodes with no incoming edges)."""
        has_incoming = set()
        for src, targets in adj.items():
            for tgt in targets:
                has_incoming.add(tgt)
        
        roots = [node for node in nodes if node not in has_incoming]
        return roots if roots else nodes[:1]  # Fallback to first node
    
    def generate_mermaid_viz(self, path: CausalPath) -> str:
        """
        Generate Mermaid diagram code for visualizing causal path.
        
        Args:
            path: CausalPath to visualize
            
        Returns:
            Mermaid diagram string
        """
        lines = ["graph LR"]
        
        # Add nodes
        all_nodes = [path.source_node] + path.intermediate_nodes + [path.target_node]
        for node in all_nodes:
            attr = path.attribution_scores.get(node, 0.0)
            label = f"{node}<br/>attr={attr:.2f}"
            lines.append(f"    {node.replace(' ', '_')}['{label}']")
        
        # Add edges
        for src, tgt, weight in path.edges:
            src_id = src.replace(' ', '_')
            tgt_id = tgt.replace(' ', '_')
            lines.append(f"    {src_id} -->|w={weight:.2f}| {tgt_id}")
        
        return "\n".join(lines)
    
    def generate_explanation(
        self,
        path: CausalPath,
        include_interventions: bool = True,
        include_uncertainty: bool = True
    ) -> PathExplanation:
        """
        Generate comprehensive explanation for a causal path.
        
        Args:
            path: CausalPath to explain
            include_interventions: Include intervention history
            include_uncertainty: Include uncertainty notes
            
        Returns:
            PathExplanation with insights and context
        """
        # Generate key insights
        insights = self._generate_insights(path)
        
        # Get relevant interventions
        interventions = []
        if include_interventions:
            interventions = [
                rec for rec in self.intervention_log
                if rec.node in [path.source_node] + path.intermediate_nodes + [path.target_node]
            ]
        
        # Get relevant observations
        observations = [
            obs for obs in self.observation_log
            if obs['node'] in [path.source_node] + path.intermediate_nodes + [path.target_node]
        ]
        
        # Generate uncertainty notes
        uncertainty_notes = []
        if include_uncertainty:
            uncertainty_notes = self._assess_uncertainty(path)
        
        return PathExplanation(
            causal_path=path,
            interventions_applied=interventions,
            observations_made=observations,
            key_insights=insights,
            uncertainty_notes=uncertainty_notes
        )
    
    def _generate_insights(self, path: CausalPath) -> List[str]:
        """Generate key insights from causal path."""
        insights = []
        
        # Insight 1: Primary driver
        if path.attribution_scores:
            primary_driver = max(path.attribution_scores, key=path.attribution_scores.get)
            primary_score = path.attribution_scores[primary_driver]
            insights.append(
                f"Primary driver: {primary_driver} contributes {primary_score*100:.1f}% to outcome"
            )
        
        # Insight 2: Path strength
        if abs(path.total_effect) > 0.7:
            insights.append(f"Strong causal effect detected (magnitude: {abs(path.total_effect):.2f})")
        elif abs(path.total_effect) < 0.3:
            insights.append(f"Weak causal effect detected (magnitude: {abs(path.total_effect):.2f})")
        
        # Insight 3: Path complexity
        if path.path_length > 5:
            insights.append(f"Complex reasoning chain with {path.path_length} steps")
        elif path.path_length <= 2:
            insights.append(f"Direct causal relationship ({path.path_length} step)")
        
        # Insight 4: Key bottleneck
        min_edge = min(path.edges, key=lambda e: e[2])
        insights.append(
            f"Bottleneck: {min_edge[0]}→{min_edge[1]} has weakest link (weight={min_edge[2]:.2f})"
        )
        
        return insights
    
    def _assess_uncertainty(self, path: CausalPath) -> List[str]:
        """Assess uncertainty in causal path."""
        notes = []
        
        # Check path confidence
        if path.confidence < 0.6:
            notes.append(f"Low confidence path (confidence={path.confidence:.2f})")
        
        # Check for missing interventions
        intervened_nodes = {rec.node for rec in self.intervention_log}
        path_nodes = set([path.source_node] + path.intermediate_nodes + [path.target_node])
        unintervened = path_nodes - intervened_nodes
        
        if unintervened:
            notes.append(f"Nodes without interventions: {', '.join(unintervened)}")
        
        # Check edge weight variance
        if path.edges:
            weights = [w for _, _, w in path.edges]
            weight_variance = np.var(weights)
            if weight_variance > 0.1:
                notes.append(f"High variance in edge weights (variance={weight_variance:.2f})")
        
        return notes
    
    def get_tracking_summary(self) -> Dict:
        """Get summary of tracking session."""
        return {
            'is_tracking': self.is_tracking,
            'interventions_recorded': len(self.intervention_log),
            'observations_recorded': len(self.observation_log),
            'unique_nodes_tracked': len(self.node_activations),
            'graph_snapshot_available': self.graph_snapshot is not None
        }


def trace_causal_path(
    graph_data: Dict,
    target: str,
    source: Optional[str] = None,
    interventions: Optional[List[Dict]] = None
) -> List[CausalPath]:
    """
    Convenience function for quick causal path tracing.
    
    Args:
        graph_data: ECM graph dictionary
        target: Target node
        source: Optional source node
        interventions: List of interventions to apply
        
    Returns:
        List of causal paths
    """
    tracer = CausalPathTracer()
    tracer.set_graph_snapshot(graph_data)
    
    # Apply interventions if provided
    if interventions:
        tracer.start_tracking()
        for interv in interventions:
            tracer.record_intervention(
                node=interv['node'],
                intervention_type=interv.get('type', 'do'),
                value=interv['value']
            )
        tracer.stop_tracking()
    
    return tracer.extract_path(target=target, source=source)
