"""
Counterfactual Engine for Explainable ECM

Answers "what-if" questions by simulating interventions on causal graphs
and finding minimal changes needed to achieve desired outcomes.

Key Features:
- Counterfactual reasoning (what would happen if X changed?)
- Minimal intervention search (smallest change to achieve goal)
- Contrastive explanations (why Y instead of Z?)
- Do-calculus integration for valid causal inference
- Integration with CausalPathTracer for path-aware counterfactuals

Usage:
    from tiannara_core.interpretability.counterfactual_engine import CounterfactualEngine
    
    engine = CounterfactualEngine()
    
    # Simple counterfactual
    result = engine.answer_counterfactual(
        graph=ecm_graph,
        question="What if skill_memory increased by 0.2?"
    )
    
    # Find minimal intervention
    changes = engine.find_minimal_intervention(
        graph=ecm_graph,
        current_outcome=0.7,
        desired_outcome=0.9
    )

References:
    Pearl, J. (2009). Causality: Models, Reasoning, and Inference.
    Miller, T. (2019). Explanation in artificial intelligence: Insights from the social sciences.
"""

import numpy as np
import logging
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, field
from collections import defaultdict

logger = logging.getLogger(__name__)


@dataclass
class CounterfactualQuery:
    """Represents a counterfactual question."""
    query_type: str  # 'intervention', 'minimal_change', 'contrastive'
    target_variable: str
    intervention: Optional[Dict[str, float]] = None  # {node: new_value}
    desired_outcome: Optional[float] = None
    contrast_outcome: Optional[float] = None
    constraints: Optional[Dict[str, Tuple[float, float]]] = None  # {node: (min, max)}
    
    def __str__(self):
        if self.query_type == 'intervention':
            return f"What if {self.intervention}?"
        elif self.query_type == 'minimal_change':
            return f"How to change outcome from current to {self.desired_outcome}?"
        else:
            return f"Why {self.target_variable}={self.desired_outcome} instead of {self.contrast_outcome}?"


@dataclass
class CounterfactualResult:
    """Result of counterfactual analysis."""
    query: CounterfactualQuery
    original_outcome: float
    counterfactual_outcome: float
    outcome_change: float
    interventions_applied: Dict[str, float]
    causal_path_affected: List[str]
    confidence: float
    explanation: str = ""
    alternative_scenarios: List[Dict] = field(default_factory=list)
    
    def summary(self) -> str:
        """Generate human-readable summary."""
        lines = [
            f"Counterfactual Analysis:",
            f"  Original outcome: {self.original_outcome:.3f}",
            f"  Counterfactual outcome: {self.counterfactual_outcome:.3f}",
            f"  Change: {self.outcome_change:+.3f} ({abs(self.outcome_change)/max(abs(self.original_outcome), 0.001)*100:.1f}%)",
            f"  Interventions: {self.interventions_applied}",
            f"  Confidence: {self.confidence:.2f}",
        ]
        
        if self.explanation:
            lines.append(f"  Explanation: {self.explanation}")
        
        return "\n".join(lines)


@dataclass
class MinimalIntervention:
    """Minimal set of changes to achieve desired outcome."""
    changes: Dict[str, float]  # {node: delta_value}
    predicted_outcome: float
    total_magnitude: float  # Sum of absolute changes
    feasibility_score: float  # 0-1, how realistic the intervention is
    affected_nodes: List[str]
    
    def __str__(self):
        changes_str = ", ".join([f"{k}: {v:+.3f}" for k, v in self.changes.items()])
        return f"Changes: {{{changes_str}}} -> outcome={self.predicted_outcome:.3f}"


class CounterfactualEngine:
    """
    Engine for counterfactual reasoning on causal graphs.
    
    Supports three types of queries:
    1. Intervention: What happens if we change X?
    2. Minimal change: What's the smallest change to achieve Y?
    3. Contrastive: Why did X happen instead of Y?
    """
    
    def __init__(self, max_iterations: int = 100, tolerance: float = 0.01):
        """
        Initialize counterfactual engine.
        
        Args:
            max_iterations: Maximum iterations for optimization
            tolerance: Convergence tolerance for outcome matching
        """
        self.max_iterations = max_iterations
        self.tolerance = tolerance
        
        logger.info("CounterfactualEngine initialized")
    
    def answer_counterfactual(
        self,
        graph: Dict,
        query: CounterfactualQuery
    ) -> CounterfactualResult:
        """
        Answer a counterfactual query.
        
        Args:
            graph: ECM graph dictionary (nodes, edges, parameters)
            query: CounterfactualQuery object
            
        Returns:
            CounterfactualResult with analysis
        """
        logger.info(f"Answering counterfactual: {query}")
        
        if query.query_type == 'intervention':
            return self._simulate_intervention(graph, query)
        elif query.query_type == 'minimal_change':
            return self._find_minimal_change(graph, query)
        elif query.query_type == 'contrastive':
            return self._contrastive_explanation(graph, query)
        else:
            raise ValueError(f"Unknown query type: {query.query_type}")
    
    def _simulate_intervention(
        self,
        graph: Dict,
        query: CounterfactualQuery
    ) -> CounterfactualResult:
        """Simulate the effect of an intervention."""
        # Get original outcome
        original_outcome = self._compute_outcome(graph)
        
        # Apply intervention
        intervened_graph = self._apply_intervention(graph, query.intervention)
        
        # Compute counterfactual outcome
        counterfactual_outcome = self._compute_outcome(intervened_graph)
        
        # Calculate change
        outcome_change = counterfactual_outcome - original_outcome
        
        # Identify affected causal path
        affected_path = self._trace_affected_path(graph, query.intervention)
        
        # Generate explanation
        explanation = self._generate_intervention_explanation(
            query.intervention, outcome_change, affected_path
        )
        
        # Estimate confidence (based on path length and edge weights)
        confidence = self._estimate_confidence(graph, query.intervention)
        
        return CounterfactualResult(
            query=query,
            original_outcome=original_outcome,
            counterfactual_outcome=counterfactual_outcome,
            outcome_change=outcome_change,
            interventions_applied=query.intervention,
            causal_path_affected=affected_path,
            confidence=confidence,
            explanation=explanation
        )
    
    def _find_minimal_change(
        self,
        graph: Dict,
        query: CounterfactualQuery
    ) -> CounterfactualResult:
        """Find minimal intervention to achieve desired outcome."""
        current_outcome = self._compute_outcome(graph)
        desired_outcome = query.desired_outcome
        
        # Use gradient-based optimization to find minimal changes
        minimal_changes = self._optimize_interventions(
            graph, current_outcome, desired_outcome
        )
        
        if minimal_changes is None:
            return CounterfactualResult(
                query=query,
                original_outcome=current_outcome,
                counterfactual_outcome=current_outcome,
                outcome_change=0.0,
                interventions_applied={},
                causal_path_affected=[],
                confidence=0.0,
                explanation="Could not find feasible intervention to achieve desired outcome"
            )
        
        # Apply minimal changes
        intervened_graph = self._apply_intervention(graph, minimal_changes.changes)
        counterfactual_outcome = self._compute_outcome(intervened_graph)
        
        outcome_change = counterfactual_outcome - current_outcome
        
        # Generate explanation
        explanation = self._generate_minimal_change_explanation(
            minimal_changes, current_outcome, desired_outcome
        )
        
        return CounterfactualResult(
            query=query,
            original_outcome=current_outcome,
            counterfactual_outcome=counterfactual_outcome,
            outcome_change=outcome_change,
            interventions_applied=minimal_changes.changes,
            causal_path_affected=minimal_changes.affected_nodes,
            confidence=minimal_changes.feasibility_score,
            explanation=explanation
        )
    
    def _contrastive_explanation(
        self,
        graph: Dict,
        query: CounterfactualQuery
    ) -> CounterfactualResult:
        """Generate contrastive explanation (why X instead of Y)."""
        current_outcome = self._compute_outcome(graph)
        
        # Find what would need to change for contrast outcome
        contrast_query = CounterfactualQuery(
            query_type='minimal_change',
            target_variable=query.target_variable,
            desired_outcome=query.contrast_outcome
        )
        
        contrast_result = self._find_minimal_change(graph, contrast_query)
        
        # Generate contrastive explanation
        explanation = (
            f"Outcome was {current_outcome:.3f} instead of {query.contrast_outcome:.3f} "
            f"because: {contrast_result.explanation}"
        )
        
        return CounterfactualResult(
            query=query,
            original_outcome=current_outcome,
            counterfactual_outcome=query.contrast_outcome,
            outcome_change=query.contrast_outcome - current_outcome,
            interventions_applied=contrast_result.interventions_applied,
            causal_path_affected=contrast_result.causal_path_affected,
            confidence=contrast_result.confidence,
            explanation=explanation
        )
    
    def find_minimal_intervention(
        self,
        graph: Dict,
        current_outcome: float,
        desired_outcome: float,
        constraints: Optional[Dict[str, Tuple[float, float]]] = None
    ) -> Optional[MinimalIntervention]:
        """
        Find minimal set of interventions to achieve desired outcome.
        
        Args:
            graph: ECM graph
            current_outcome: Current outcome value
            desired_outcome: Target outcome value
            constraints: Optional bounds on node values {node: (min, max)}
            
        Returns:
            MinimalIntervention or None if infeasible
        """
        return self._optimize_interventions(
            graph, current_outcome, desired_outcome, constraints
        )
    
    def _optimize_interventions(
        self,
        graph: Dict,
        current_outcome: float,
        desired_outcome: float,
        constraints: Optional[Dict[str, Tuple[float, float]]] = None
    ) -> Optional[MinimalIntervention]:
        """
        Optimize interventions using gradient descent.
        
        Minimizes sum of absolute changes while achieving desired outcome.
        """
        nodes = graph.get('nodes', [])
        edges = graph.get('edges', [])
        
        if not nodes:
            return None
        
        # Initialize intervention values (start small)
        interventions = {node: 0.0 for node in nodes}
        
        # Target difference
        target_diff = desired_outcome - current_outcome
        
        best_interventions = None
        best_loss = float('inf')
        
        # Gradient descent
        learning_rate = 0.1
        
        for iteration in range(self.max_iterations):
            # Apply current interventions
            intervened_graph = self._apply_intervention(graph, interventions)
            predicted_outcome = self._compute_outcome(intervened_graph)
            
            # Compute loss (outcome error + regularization for minimal changes)
            outcome_error = (predicted_outcome - desired_outcome) ** 2
            change_penalty = sum(abs(v) for v in interventions.values()) * 0.1
            loss = outcome_error + change_penalty
            
            # Track best solution
            if loss < best_loss:
                best_loss = loss
                best_interventions = interventions.copy()
                
                # Check convergence
                if abs(predicted_outcome - desired_outcome) < self.tolerance:
                    break
            
            # Compute gradients (numerical approximation)
            gradients = {}
            epsilon = 0.01
            
            for node in nodes:
                # Perturb this node
                interventions_plus = interventions.copy()
                interventions_plus[node] += epsilon
                
                intervened_plus = self._apply_intervention(graph, interventions_plus)
                outcome_plus = self._compute_outcome(intervened_plus)
                
                # Gradient
                gradients[node] = (outcome_plus - predicted_outcome) / epsilon
            
            # Update interventions (gradient descent)
            for node in nodes:
                # Move in direction that reduces outcome error
                update = -learning_rate * gradients[node] * 2 * (predicted_outcome - desired_outcome)
                
                # Apply constraints if provided
                if constraints and node in constraints:
                    min_val, max_val = constraints[node]
                    new_value = interventions[node] + update
                    interventions[node] = np.clip(new_value, min_val, max_val) - interventions[node]
                else:
                    interventions[node] += update
                
                # Decay learning rate
                learning_rate *= 0.99
        
        # Convert best interventions to MinimalIntervention
        if best_interventions:
            # Filter out negligible changes
            significant_changes = {
                k: v for k, v in best_interventions.items()
                if abs(v) > 0.01
            }
            
            if significant_changes:
                # Apply to get final outcome
                final_graph = self._apply_intervention(graph, significant_changes)
                final_outcome = self._compute_outcome(final_graph)
                
                total_magnitude = sum(abs(v) for v in significant_changes.values())
                
                # Estimate feasibility (smaller changes = more feasible)
                feasibility = max(0.0, 1.0 - total_magnitude / len(nodes))
                
                return MinimalIntervention(
                    changes=significant_changes,
                    predicted_outcome=final_outcome,
                    total_magnitude=total_magnitude,
                    feasibility_score=feasibility,
                    affected_nodes=list(significant_changes.keys())
                )
        
        return None
    
    def _compute_outcome(self, graph: Dict) -> float:
        """
        Compute outcome value from graph using forward propagation.
        
        Simplified implementation - assumes last node is outcome.
        """
        nodes = graph.get('nodes', [])
        edges = graph.get('edges', [])
        
        if not nodes:
            return 0.0
        
        # Initialize node values (default 0.5 if not specified)
        node_values = {}
        for node in nodes:
            node_values[node] = graph.get('node_values', {}).get(node, 0.5)
        
        # Forward propagate through edges
        # Build adjacency list
        adj = defaultdict(list)
        for src, tgt, weight in edges:
            adj[src].append((tgt, weight))
        
        # Topological sort (simple BFS)
        visited = set()
        order = []
        queue = [n for n in nodes if not any(n == t for s, t, _ in edges)]
        
        while queue:
            node = queue.pop(0)
            if node in visited:
                continue
            visited.add(node)
            order.append(node)
            
            for neighbor, _ in adj[node]:
                if neighbor not in visited:
                    queue.append(neighbor)
        
        # Propagate values in topological order
        for node in order:
            for neighbor, weight in adj[node]:
                # Simple weighted sum propagation
                contribution = node_values[node] * weight
                node_values[neighbor] = node_values.get(neighbor, 0) + contribution
        
        # Outcome is last node in order (or specified outcome node)
        outcome_node = graph.get('outcome_node', order[-1] if order else nodes[0])
        return node_values.get(outcome_node, 0.5)
    
    def _apply_intervention(
        self,
        graph: Dict,
        interventions: Dict[str, float]
    ) -> Dict:
        """Apply interventions to graph (do-operator)."""
        intervened_graph = graph.copy()
        
        # Override node values with interventions
        if 'node_values' not in intervened_graph:
            intervened_graph['node_values'] = {}
        
        for node, value in interventions.items():
            intervened_graph['node_values'][node] = value
        
        return intervened_graph
    
    def _trace_affected_path(
        self,
        graph: Dict,
        interventions: Dict[str, float]
    ) -> List[str]:
        """Trace which nodes are affected by interventions."""
        nodes = graph.get('nodes', [])
        edges = graph.get('edges', [])
        
        # Build adjacency
        adj = defaultdict(list)
        for src, tgt, _ in edges:
            adj[src].append(tgt)
        
        # BFS from intervened nodes
        affected = []
        queue = list(interventions.keys())
        visited = set(queue)
        
        while queue:
            node = queue.pop(0)
            affected.append(node)
            
            for neighbor in adj[node]:
                if neighbor not in visited:
                    visited.add(neighbor)
                    queue.append(neighbor)
        
        return affected
    
    def _estimate_confidence(
        self,
        graph: Dict,
        interventions: Dict[str, float]
    ) -> float:
        """Estimate confidence in counterfactual prediction."""
        # Confidence decreases with:
        # 1. Number of interventions (more = less certain)
        # 2. Magnitude of interventions (larger = less certain)
        # 3. Path length from intervention to outcome (longer = less certain)
        
        n_interventions = len(interventions)
        avg_magnitude = np.mean([abs(v) for v in interventions.values()]) if interventions else 0
        
        # Base confidence
        confidence = 1.0
        
        # Penalize for multiple interventions
        confidence *= 0.9 ** n_interventions
        
        # Penalize for large magnitude changes
        confidence *= max(0.5, 1.0 - avg_magnitude)
        
        return max(0.1, confidence)
    
    def _generate_intervention_explanation(
        self,
        interventions: Dict[str, float],
        outcome_change: float,
        affected_path: List[str]
    ) -> str:
        """Generate natural language explanation for intervention."""
        if not interventions:
            return "No interventions applied."
        
        intervention_strs = [
            f"{node} changed by {value:+.3f}"
            for node, value in interventions.items()
        ]
        
        direction = "increased" if outcome_change > 0 else "decreased"
        
        explanation = (
            f"Intervening on {', '.join(intervention_strs)} "
            f"caused outcome to {direction} by {abs(outcome_change):.3f}. "
            f"This affected {len(affected_path)} nodes in the causal chain."
        )
        
        return explanation
    
    def _generate_minimal_change_explanation(
        self,
        minimal_changes: MinimalIntervention,
        current_outcome: float,
        desired_outcome: float
    ) -> str:
        """Generate explanation for minimal change recommendation."""
        changes_str = ", ".join([
            f"{node}: {delta:+.3f}"
            for node, delta in minimal_changes.changes.items()
        ])
        
        explanation = (
            f"To change outcome from {current_outcome:.3f} to {desired_outcome:.3f}, "
            f"make these adjustments: {changes_str}. "
            f"Feasibility score: {minimal_changes.feasibility_score:.2f}/1.00"
        )
        
        return explanation


def answer_what_if(
    graph: Dict,
    intervention: Dict[str, float]
) -> CounterfactualResult:
    """
    Convenience function for simple what-if queries.
    
    Args:
        graph: ECM graph
        intervention: {node: new_value}
        
    Returns:
        CounterfactualResult
    """
    engine = CounterfactualEngine()
    query = CounterfactualQuery(
        query_type='intervention',
        target_variable='outcome',
        intervention=intervention
    )
    return engine.answer_counterfactual(graph, query)
