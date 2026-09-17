import logging
import random

logger = logging.getLogger(__name__)

class CognitiveImmuneSystem:
    """
    L2 - Cognitive Immune System (CIS)
    Handles:
    - collapse prediction
    - ecological regulation
    - anomaly response
    - immune memory
    """
    
    def __init__(self):
        self.immune_memory = []
        self.monoculture_threshold = 0.85
        
    def predict_collapse(self, query: str, context: list) -> float:
        """
        Estimates the probability that executing this query/branch 
        will lead to an ontological collapse (paradox, infinite loop, etc.).
        """
        # Heuristic: deep synthesis queries might have higher collapse risk
        if "quantum" in query.lower() or "paradox" in query.lower():
            return 0.45
            
        return random.uniform(0.01, 0.15)
        
    def apply_anti_monoculture_pressure(self, query: str) -> str:
        """
        If the system detects semantic stagnation (monoculture),
        it injects perturbations to force the Discovery Engine out of local minima.
        """
        # In a real system, this checks the OCM (Ontology Consensus Mesh)
        # For now, we simulate an active perturbation 10% of the time.
        if random.random() > 0.9:
            logger.warning("CIS: Injecting anti-monoculture perturbation.")
            return query + " [Perturbation: Consider nonlinear or asymmetric topological factors]"
        return query
        
    def regulate_ecology(self, query: str, context: list) -> bool:
        """
        Main hook for L2 stabilization.
        Returns True if the operation is permitted, False if it must be quarantined.
        """
        collapse_risk = self.predict_collapse(query, context)
        
        if collapse_risk > 0.8:
            logger.error(f"CIS: Quarantine activated. Collapse risk {collapse_risk} too high.")
            self.immune_memory.append({"query": query, "risk": collapse_risk, "action": "quarantine"})
            return False
            
        logger.info(f"CIS: Operation permitted. Collapse risk: {collapse_risk:.2f}")
        return True
