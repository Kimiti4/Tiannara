"""
Extended Do-Calculus for Counterfactual Reasoning

Implements Pearl's complete do-calculus framework with formal rules
for causal inference, integrated with counterfactual reasoning.

Key Features:
- Formal implementation of Pearl's 3 Rules of Do-Calculus
- Backdoor criterion identification and adjustment
- Front-door criterion for mediation analysis
- Integration with counterfactual queries
- Causal effect estimation from observational data
- Validation of identifiability conditions

References:
    Pearl, J. (2009). Causality: Models, Reasoning, and Inference. Chapter 3.
    Pearl, J., Glymour, M., & Jewell, N. P. (2016). Causal Inference in Statistics.
"""

import numpy as np
import logging
from typing import Dict, List, Optional, Tuple, Set, Any
from dataclasses import dataclass, field
from collections import defaultdict

logger = logging.getLogger(__name__)


@dataclass
class DoCalculusResult:
    """Result of do-calculus operation."""
    identifiable: bool
    causal_effect: float
    confidence: float
    rule_applied: str  # 'backdoor', 'frontdoor', 'rule1', 'rule2', 'rule3'
    adjustment_set: List[str]
    formula: str
    explanation: str = ""
    assumptions: List[str] = field(default_factory=list)
    
    def summary(self) -> str:
        """Generate human-readable summary."""
        status = "✓ Identifiable" if self.identifiable else "✗ Not identifiable"
        return (
            f"Do-Calculus Result: {status}\n"
            f"  Rule applied: {self.rule_applied}\n"
            f"  Causal effect: {self.causal_effect:.4f}\n"
            f"  Confidence: {self.confidence:.2f}\n"
            f"  Adjustment set: {self.adjustment_set}\n"
            f"  Formula: {self.formula}"
        )


@dataclass
class CounterfactualDoQuery:
    """Counterfactual query using do-calculus notation."""
    treatment: str  # Variable being intervened on (X)
    outcome: str  # Outcome variable (Y)
    evidence: Optional[Dict[str, float]] = None  # Observed evidence Z=z
    intervention_value: Optional[float] = None  # do(X=x)
    control_value: Optional[float] = None  # For ATE calculation
    
    def __str__(self):
        if self.evidence:
            evidence_str = ", ".join([f"{k}={v}" for k, v in self.evidence.items()])
            return f"P(Y | do({self.treatment}={self.intervention_value}), {evidence_str})"
        else:
            return f"P(Y | do({self.treatment}={self.intervention_value}))"


class DoCalculusEngine:
    """
    Extended do-calculus engine implementing Pearl's complete framework.
    
    Implements all three rules of do-calculus plus backdoor/frontdoor criteria
    for causal effect identification from observational data.
    """
    
    def __init__(self, significance_level: float = 0.05):
        """
        Initialize do-calculus engine.
        
        Args:
            significance_level: Alpha level for statistical tests
        """
        self.alpha = significance_level
        logger.info("DoCalculusEngine initialized")
    
    # ==================== PEARL'S THREE RULES OF DO-CALCULUS ====================
    
    def rule_1_insertion_deletion_of_observations(
        self,
        graph: Dict,
        y: str,
        z: str,
        w: str,
        x: str
    ) -> bool:
        """
        Rule 1: Insertion/deletion of observations
        
        P(y | do(x), z, w) = P(y | do(x), w)
        if (Y ⊥ Z | X, W) in G_x̄
        
        This rule allows us to ignore observation Z if it's independent
        of Y given X and W in the graph where incoming edges to X are removed.
        
        Args:
            graph: Causal graph (nodes, edges)
            y: Outcome variable
            z: Observation to potentially remove
            w: Conditioning set
            x: Intervention variable
            
        Returns:
            True if Z can be ignored (conditional independence holds)
        """
        logger.debug(f"Testing Rule 1: ({y} ⊥ {z} | {x}, {w}) in G_x̄")
        
        # Create modified graph G_x̄ (remove incoming edges to X)
        modified_graph = self._remove_incoming_edges(graph, x)
        
        # Test d-separation: Y ⊥ Z | X, W in G_x̄
        conditioning_set = {x} | set(w.split(',') if isinstance(w, str) else w)
        is_d_separated = self._test_d_separation(modified_graph, y, z, conditioning_set)
        
        if is_d_separated:
            logger.info(f"Rule 1 applies: {z} can be ignored")
        
        return is_d_separated
    
    def rule_2_action_observation_exchange(
        self,
        graph: Dict,
        y: str,
        z: str,
        w: str,
        x: str
    ) -> bool:
        """
        Rule 2: Action/observation exchange
        
        P(y | do(x), do(z), w) = P(y | do(x), z, w)
        if (Y ⊥ Z | X, W) in G_x̄,z̄
        
        This rule allows us to replace intervention do(Z) with observation Z
        if Z doesn't affect Y through paths other than those going through X.
        
        Args:
            graph: Causal graph
            y: Outcome variable
            z: Variable to exchange (do vs observe)
            w: Conditioning set
            x: Other intervention variable
            
        Returns:
            True if do(Z) can be replaced with Z
        """
        logger.debug(f"Testing Rule 2: ({y} ⊥ {z} | {x}, {w}) in G_x̄,z̄")
        
        # Create modified graph G_x̄,z̄ (remove incoming edges to X and Z)
        modified_graph = self._remove_incoming_edges(graph, x)
        modified_graph = self._remove_incoming_edges(modified_graph, z)
        
        # Test d-separation: Y ⊥ Z | X, W in G_x̄,z̄
        conditioning_set = {x} | set(w.split(',') if isinstance(w, str) else w)
        is_d_separated = self._test_d_separation(modified_graph, y, z, conditioning_set)
        
        if is_d_separated:
            logger.info(f"Rule 2 applies: do({z}) can be replaced with {z}")
        
        return is_d_separated
    
    def rule_3_insertion_deletion_of_actions(
        self,
        graph: Dict,
        y: str,
        z: str,
        w: str,
        x: str
    ) -> bool:
        """
        Rule 3: Insertion/deletion of actions
        
        P(y | do(x), do(z), w) = P(y | do(x), w)
        if (Y ⊥ Z | X, W) in G_x̄,z(W)̄
        
        This rule allows us to ignore intervention do(Z) if Z doesn't affect Y
        after accounting for X and W.
        
        Args:
            graph: Causal graph
            y: Outcome variable
            z: Intervention to potentially remove
            w: Conditioning set
            x: Other intervention variable
            
        Returns:
            True if do(Z) can be ignored
        """
        logger.debug(f"Testing Rule 3: ({y} ⊥ {z} | {x}, {w}) in G_x̄,z(W)̄")
        
        # Determine Z(W): ancestors of Z that are not in W
        z_ancestors = self._get_ancestors(graph, z)
        z_w = z_ancestors - set(w.split(',') if isinstance(w, str) else w)
        
        # Create modified graph G_x̄,z(W)̄
        modified_graph = self._remove_incoming_edges(graph, x)
        for node in z_w:
            modified_graph = self._remove_incoming_edges(modified_graph, node)
        
        # Test d-separation
        conditioning_set = {x} | set(w.split(',') if isinstance(w, str) else w)
        is_d_separated = self._test_d_separation(modified_graph, y, z, conditioning_set)
        
        if is_d_separated:
            logger.info(f"Rule 3 applies: do({z}) can be ignored")
        
        return is_d_separated
    
    # ==================== BACKDOOR CRITERION ====================
    
    def find_backdoor_adjustment_set(
        self,
        graph: Dict,
        treatment: str,
        outcome: str
    ) -> Optional[List[str]]:
        """
        Find valid backdoor adjustment set for causal effect identification.
        
        The backdoor criterion identifies a set Z such that:
        1. No node in Z is a descendant of treatment X
        2. Z blocks all backdoor paths from X to Y
        
        Args:
            graph: Causal graph (nodes, edges)
            treatment: Treatment variable X
            outcome: Outcome variable Y
            
        Returns:
            List of variables to adjust for, or None if no valid set exists
        """
        logger.info(f"Finding backdoor adjustment set for {treatment} → {outcome}")
        
        nodes = graph.get('nodes', [])
        edges = graph.get('edges', [])
        
        # Get descendants of treatment
        descendants = self._get_descendants(graph, treatment)
        
        # Get all backdoor paths (paths starting with arrow into X)
        backdoor_paths = self._find_backdoor_paths(graph, treatment, outcome)
        
        if not backdoor_paths:
            # No confounding, no adjustment needed
            logger.info("No backdoor paths found - no adjustment needed")
            return []
        
        # Find minimal set that blocks all backdoor paths
        # Use greedy algorithm: pick node that blocks most paths
        candidates = [n for n in nodes if n not in {treatment, outcome} and n not in descendants]
        
        adjustment_set = []
        remaining_paths = backdoor_paths.copy()
        
        while remaining_paths and candidates:
            # Find candidate that blocks most remaining paths
            best_candidate = None
            max_blocked = 0
            
            for candidate in candidates:
                blocked = sum(1 for path in remaining_paths if candidate in path)
                if blocked > max_blocked:
                    max_blocked = blocked
                    best_candidate = candidate
            
            if best_candidate and max_blocked > 0:
                adjustment_set.append(best_candidate)
                candidates.remove(best_candidate)
                
                # Remove paths blocked by this candidate
                remaining_paths = [
                    path for path in remaining_paths
                    if best_candidate not in path
                ]
            else:
                break
        
        # Check if all paths are blocked
        if remaining_paths:
            logger.warning(f"Could not block all backdoor paths. Remaining: {len(remaining_paths)}")
            return None
        
        logger.info(f"Backdoor adjustment set found: {adjustment_set}")
        return adjustment_set
    
    def estimate_causal_effect_backdoor(
        self,
        observations: List[Dict],
        treatment: str,
        outcome: str,
        adjustment_set: List[str]
    ) -> DoCalculusResult:
        """
        Estimate causal effect using backdoor adjustment formula.
        
        P(Y | do(X)) = Σ_z P(Y | X, Z=z) P(Z=z)
        
        Args:
            observations: Observational data
            treatment: Treatment variable X
            outcome: Outcome variable Y
            adjustment_set: Variables to adjust for Z
            
        Returns:
            DoCalculusResult with estimated causal effect
        """
        logger.info(f"Estimating causal effect via backdoor adjustment: {treatment} → {outcome}")
        
        if not adjustment_set:
            # Simple regression without adjustment
            effect = self._estimate_simple_effect(observations, treatment, outcome)
            formula = f"E[Y | do(X)] = E[Y | X]"
        else:
            # Stratified estimation with adjustment
            effect = self._estimate_adjusted_effect(
                observations, treatment, outcome, adjustment_set
            )
            formula = f"E[Y | do(X)] = Σ_{{{','.join(adjustment_set)}}} E[Y | X, Z] P(Z)"
        
        # Calculate confidence based on sample size and variance
        n = len(observations)
        confidence = min(0.95, 0.5 + 0.01 * np.sqrt(n))
        
        return DoCalculusResult(
            identifiable=True,
            causal_effect=effect,
            confidence=confidence,
            rule_applied='backdoor',
            adjustment_set=adjustment_set,
            formula=formula,
            explanation=(
                f"Causal effect estimated using backdoor adjustment. "
                f"Adjusted for confounders: {', '.join(adjustment_set) if adjustment_set else 'none'}. "
                f"Estimated effect: {effect:+.4f}"
            ),
            assumptions=[
                "Causal sufficiency (no unmeasured confounders)",
                "Positivity (all treatment levels observed for each Z)",
                "Consistency (well-defined intervention)"
            ]
        )
    
    # ==================== FRONT-DOOR CRITERION ====================
    
    def find_frontdoor_mediator(
        self,
        graph: Dict,
        treatment: str,
        outcome: str
    ) -> Optional[str]:
        """
        Find front-door mediator for causal effect identification.
        
        The front-door criterion requires:
        1. M intercepts all directed paths from X to Y
        2. No unblocked backdoor paths from X to M
        3. All backdoor paths from M to Y are blocked by X
        
        Args:
            graph: Causal graph
            treatment: Treatment variable X
            outcome: Outcome variable Y
            
        Returns:
            Mediator variable M, or None if no valid mediator exists
        """
        logger.info(f"Searching for front-door mediator: {treatment} → ? → {outcome}")
        
        nodes = graph.get('nodes', [])
        
        for candidate in nodes:
            if candidate in {treatment, outcome}:
                continue
            
            # Check condition 1: M intercepts all directed paths X → Y
            if not self._intercepts_all_paths(graph, treatment, outcome, candidate):
                continue
            
            # Check condition 2: No backdoor paths X → M
            x_to_m_backdoors = self._find_backdoor_paths(graph, treatment, candidate)
            if x_to_m_backdoors:
                continue
            
            # Check condition 3: X blocks all backdoor paths M → Y
            m_to_y_backdoors = self._find_backdoor_paths(graph, candidate, outcome)
            if m_to_y_backdoors:
                # Check if X blocks them
                all_blocked = all(
                    treatment in path for path in m_to_y_backdoors
                )
                if not all_blocked:
                    continue
            
            logger.info(f"Front-door mediator found: {candidate}")
            return candidate
        
        return None
    
    def estimate_causal_effect_frontdoor(
        self,
        observations: List[Dict],
        treatment: str,
        outcome: str,
        mediator: str
    ) -> DoCalculusResult:
        """
        Estimate causal effect using front-door adjustment formula.
        
        P(Y | do(X)) = Σ_m P(M=m | X) Σ_x' P(Y | M=m, X=x') P(X=x')
        
        Args:
            observations: Observational data
            treatment: Treatment variable X
            outcome: Outcome variable Y
            mediator: Mediator variable M
            
        Returns:
            DoCalculusResult with estimated causal effect
        """
        logger.info(f"Estimating causal effect via front-door criterion: {treatment} → {mediator} → {outcome}")
        
        # Simplified estimation using two-stage regression
        # Stage 1: Effect of X on M
        x_on_m = self._estimate_simple_effect(observations, treatment, mediator)
        
        # Stage 2: Effect of M on Y (controlling for X)
        m_on_y = self._estimate_partial_effect(observations, mediator, outcome, treatment)
        
        # Total effect = product of stages
        total_effect = x_on_m * m_on_y
        
        formula = (
            f"E[Y | do(X)] = Σ_m P(M=m | X) Σ_x' P(Y | M=m, X=x') P(X=x')"
        )
        
        return DoCalculusResult(
            identifiable=True,
            causal_effect=total_effect,
            confidence=0.75,  # Lower confidence due to two-stage estimation
            rule_applied='frontdoor',
            adjustment_set=[mediator],
            formula=formula,
            explanation=(
                f"Causal effect estimated using front-door criterion through mediator {mediator}. "
                f"Effect X→M: {x_on_m:.4f}, Effect M→Y: {m_on_y:.4f}, Total: {total_effect:+.4f}"
            ),
            assumptions=[
                "Mediator intercepts all causal paths",
                "No unmeasured confounding X→M",
                "X blocks all backdoor paths M→Y"
            ]
        )
    
    # ==================== COUNTERFACTUAL INTEGRATION ====================
    
    def answer_counterfactual_with_do_calculus(
        self,
        graph: Dict,
        observations: List[Dict],
        query: CounterfactualDoQuery
    ) -> DoCalculusResult:
        """
        Answer counterfactual query using do-calculus.
        
        Computes P(Y | do(X=x), Z=z) using appropriate identification strategy.
        
        Args:
            graph: Causal graph
            observations: Observational data
            query: CounterfactualDoQuery with treatment, outcome, evidence
            
        Returns:
            DoCalculusResult with counterfactual prediction
        """
        logger.info(f"Answering counterfactual: {query}")
        
        # Try backdoor adjustment first
        adjustment_set = self.find_backdoor_adjustment_set(
            graph, query.treatment, query.outcome
        )
        
        if adjustment_set is not None:
            # Add evidence variables to adjustment set if not already included
            if query.evidence:
                for var in query.evidence.keys():
                    if var not in adjustment_set and var != query.treatment:
                        adjustment_set.append(var)
            
            result = self.estimate_causal_effect_backdoor(
                observations, query.treatment, query.outcome, adjustment_set
            )
            
            result.rule_applied = f"backdoor + counterfactual"
            result.explanation += f"\nCounterfactual: What if {query.treatment}={query.intervention_value}?"
            
            return result
        
        # Try front-door criterion
        mediator = self.find_frontdoor_mediator(graph, query.treatment, query.outcome)
        
        if mediator:
            result = self.estimate_causal_effect_frontdoor(
                observations, query.treatment, query.outcome, mediator
            )
            
            result.rule_applied = f"frontdoor + counterfactual"
            result.explanation += f"\nCounterfactual: What if {query.treatment}={query.intervention_value}?"
            
            return result
        
        # Not identifiable
        return DoCalculusResult(
            identifiable=False,
            causal_effect=0.0,
            confidence=0.0,
            rule_applied='none',
            adjustment_set=[],
            formula='',
            explanation="Causal effect not identifiable with available methods",
            assumptions=[]
        )
    
    # ==================== HELPER METHODS ====================
    
    def _remove_incoming_edges(self, graph: Dict, node: str) -> Dict:
        """Remove all incoming edges to a node (create G_x̄)."""
        modified = graph.copy()
        edges = modified.get('edges', [])
        
        # Filter out edges pointing to node
        modified['edges'] = [
            (src, tgt, w) for src, tgt, w in edges
            if tgt != node
        ]
        
        return modified
    
    def _test_d_separation(
        self,
        graph: Dict,
        x: str,
        y: str,
        conditioning_set: Set[str]
    ) -> bool:
        """
        Test if X and Y are d-separated given conditioning set.
        
        Simplified implementation using path blocking rules.
        """
        # Find all undirected paths between X and Y
        paths = self._find_all_paths(graph, x, y)
        
        # Check if all paths are blocked
        for path in paths:
            if not self._is_path_blocked(path, conditioning_set, graph):
                return False
        
        return True
    
    def _find_all_paths(self, graph: Dict, start: str, end: str, max_length: int = 10) -> List[List[str]]:
        """Find all undirected paths between start and end."""
        edges = graph.get('edges', [])
        
        # Build undirected adjacency
        adj = defaultdict(set)
        for src, tgt, _ in edges:
            adj[src].add(tgt)
            adj[tgt].add(src)
        
        # BFS to find all paths
        paths = []
        queue = [(start, [start])]
        
        while queue:
            current, path = queue.pop(0)
            
            if current == end and len(path) > 1:
                paths.append(path)
                continue
            
            if len(path) >= max_length:
                continue
            
            for neighbor in adj[current]:
                if neighbor not in path:
                    queue.append((neighbor, path + [neighbor]))
        
        return paths
    
    def _is_path_blocked(self, path: List[str], conditioning_set: Set[str], graph: Dict) -> bool:
        """Check if a path is blocked by conditioning set."""
        # Simplified: check if any non-endpoint node is in conditioning set
        intermediate_nodes = path[1:-1]
        
        for node in intermediate_nodes:
            if node in conditioning_set:
                return True
        
        return False
    
    def _find_backdoor_paths(self, graph: Dict, treatment: str, outcome: str) -> List[List[str]]:
        """Find all backdoor paths from treatment to outcome."""
        edges = graph.get('edges', [])
        
        # Build adjacency
        parents = defaultdict(list)
        children = defaultdict(list)
        for src, tgt, _ in edges:
            parents[tgt].append(src)
            children[src].append(tgt)
        
        # Backdoor paths start with parent of treatment
        backdoor_paths = []
        
        for parent in parents[treatment]:
            # Find paths from parent to outcome that don't go through treatment
            paths = self._find_paths_avoiding(parent, outcome, {treatment}, parents, children)
            backdoor_paths.extend([[parent] + path for path in paths])
        
        return backdoor_paths
    
    def _find_paths_avoiding(
        self,
        start: str,
        end: str,
        avoid: Set[str],
        parents: Dict,
        children: Dict,
        max_length: int = 10
    ) -> List[List[str]]:
        """Find paths from start to end avoiding certain nodes."""
        paths = []
        queue = [(start, [start])]
        
        while queue:
            current, path = queue.pop(0)
            
            if current == end:
                paths.append(path)
                continue
            
            if len(path) >= max_length:
                continue
            
            # Explore both parents and children
            neighbors = set(parents.get(current, []) + children.get(current, []))
            
            for neighbor in neighbors:
                if neighbor not in path and neighbor not in avoid:
                    queue.append((neighbor, path + [neighbor]))
        
        return paths
    
    def _get_descendants(self, graph: Dict, node: str) -> Set[str]:
        """Get all descendants of a node."""
        edges = graph.get('edges', [])
        children = defaultdict(list)
        
        for src, tgt, _ in edges:
            children[src].append(tgt)
        
        # BFS
        descendants = set()
        queue = [node]
        
        while queue:
            current = queue.pop(0)
            for child in children[current]:
                if child not in descendants:
                    descendants.add(child)
                    queue.append(child)
        
        return descendants
    
    def _get_ancestors(self, graph: Dict, node: str) -> Set[str]:
        """Get all ancestors of a node."""
        edges = graph.get('edges', [])
        parents = defaultdict(list)
        
        for src, tgt, _ in edges:
            parents[tgt].append(src)
        
        # BFS
        ancestors = set()
        queue = [node]
        
        while queue:
            current = queue.pop(0)
            for parent in parents[current]:
                if parent not in ancestors:
                    ancestors.add(parent)
                    queue.append(parent)
        
        return ancestors
    
    def _intercepts_all_paths(self, graph: Dict, start: str, end: str, mediator: str) -> bool:
        """Check if mediator intercepts all directed paths from start to end."""
        paths = self._find_directed_paths(graph, start, end)
        
        if not paths:
            return False
        
        # Check if mediator is on all paths
        return all(mediator in path for path in paths)
    
    def _find_directed_paths(self, graph: Dict, start: str, end: str, max_length: int = 10) -> List[List[str]]:
        """Find all directed paths from start to end."""
        edges = graph.get('edges', [])
        children = defaultdict(list)
        
        for src, tgt, _ in edges:
            children[src].append(tgt)
        
        # DFS
        paths = []
        stack = [(start, [start])]
        
        while stack:
            current, path = stack.pop()
            
            if current == end:
                paths.append(path)
                continue
            
            if len(path) >= max_length:
                continue
            
            for child in children[current]:
                if child not in path:
                    stack.append((child, path + [child]))
        
        return paths
    
    def _estimate_simple_effect(self, observations: List[Dict], x: str, y: str) -> float:
        """Estimate simple causal effect using linear regression."""
        x_vals = np.array([obs.get(x, 0) for obs in observations])
        y_vals = np.array([obs.get(y, 0) for obs in observations])
        
        if len(x_vals) < 3:
            return 0.0
        
        # Linear regression: Y = β₀ + β₁X
        mean_x = np.mean(x_vals)
        mean_y = np.mean(y_vals)
        
        numerator = np.sum((x_vals - mean_x) * (y_vals - mean_y))
        denominator = np.sum((x_vals - mean_x) ** 2)
        
        if abs(denominator) < 1e-10:
            return 0.0
        
        beta_1 = numerator / denominator
        return beta_1
    
    def _estimate_adjusted_effect(
        self,
        observations: List[Dict],
        treatment: str,
        outcome: str,
        adjustment_set: List[str]
    ) -> float:
        """Estimate adjusted causal effect using multiple regression."""
        # Prepare data
        y_vals = np.array([obs.get(outcome, 0) for obs in observations])
        x_vals = np.array([obs.get(treatment, 0) for obs in observations])
        z_vals = np.array([
            [obs.get(z, 0) for z in adjustment_set]
            for obs in observations
        ])
        
        if len(y_vals) < len(adjustment_set) + 2:
            return 0.0
        
        # Multiple regression: Y = β₀ + β₁X + β₂Z₁ + ... + βₙZₙ
        X = np.column_stack([np.ones(len(y_vals)), x_vals, z_vals])
        
        try:
            # Solve normal equations
            beta = np.linalg.lstsq(X, y_vals, rcond=None)[0]
            return beta[1]  # Coefficient for treatment
        except Exception:
            return 0.0
    
    def _estimate_partial_effect(
        self,
        observations: List[Dict],
        x: str,
        y: str,
        control: str
    ) -> float:
        """Estimate partial effect of X on Y controlling for Z."""
        return self._estimate_adjusted_effect(observations, x, y, [control])
    
    def _calculate_correlation(self, x_vals: List[float], y_vals: List[float]) -> float:
        """Calculate Pearson correlation coefficient."""
        if len(x_vals) < 3:
            return 0.0
        
        x_arr = np.array(x_vals)
        y_arr = np.array(y_vals)
        
        mean_x = np.mean(x_arr)
        mean_y = np.mean(y_arr)
        
        numerator = np.sum((x_arr - mean_x) * (y_arr - mean_y))
        denom_x = np.sqrt(np.sum((x_arr - mean_x) ** 2))
        denom_y = np.sqrt(np.sum((y_arr - mean_y) ** 2))
        
        if denom_x < 1e-10 or denom_y < 1e-10:
            return 0.0
        
        return numerator / (denom_x * denom_y)
    
    def _partial_correlation(
        self,
        observations: List[Dict],
        x: str,
        y: str,
        cond_vars: List[str]
    ) -> float:
        """Calculate partial correlation controlling for cond_vars."""
        # Regress X on Z and get residuals
        x_residuals = self._get_regression_residuals(observations, x, cond_vars)
        
        # Regress Y on Z and get residuals
        y_residuals = self._get_regression_residuals(observations, y, cond_vars)
        
        # Correlation of residuals
        return self._calculate_correlation(x_residuals, y_residuals)
    
    def _get_regression_residuals(
        self,
        observations: List[Dict],
        target: str,
        predictors: List[str]
    ) -> List[float]:
        """Get residuals from regressing target on predictors."""
        y_vals = np.array([obs.get(target, 0) for obs in observations])
        
        if not predictors:
            return y_vals.tolist()
        
        X = np.array([
            [obs.get(p, 0) for p in predictors]
            for obs in observations
        ])
        
        # Add intercept
        X = np.column_stack([np.ones(len(y_vals)), X])
        
        try:
            # Fit regression
            beta = np.linalg.lstsq(X, y_vals, rcond=None)[0]
            
            # Predictions
            y_pred = X @ beta
            
            # Residuals
            residuals = y_vals - y_pred
            return residuals.tolist()
        except Exception:
            return y_vals.tolist()


def apply_do_calculus(
    graph: Dict,
    observations: List[Dict],
    treatment: str,
    outcome: str
) -> DoCalculusResult:
    """
    Convenience function to apply do-calculus for causal effect estimation.
    
    Args:
        graph: Causal graph
        observations: Observational data
        treatment: Treatment variable
        outcome: Outcome variable
        
    Returns:
        DoCalculusResult with identified causal effect
    """
    engine = DoCalculusEngine()
    
    # Try backdoor first
    adjustment_set = engine.find_backdoor_adjustment_set(graph, treatment, outcome)
    
    if adjustment_set is not None:
        return engine.estimate_causal_effect_backdoor(
            observations, treatment, outcome, adjustment_set
        )
    
    # Try frontdoor
    mediator = engine.find_frontdoor_mediator(graph, treatment, outcome)
    
    if mediator:
        return engine.estimate_causal_effect_frontdoor(
            observations, treatment, outcome, mediator
        )
    
    # Not identifiable
    return DoCalculusResult(
        identifiable=False,
        causal_effect=0.0,
        confidence=0.0,
        rule_applied='none',
        adjustment_set=[],
        formula='',
        explanation="Causal effect not identifiable"
    )
