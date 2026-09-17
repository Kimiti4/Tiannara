import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)

class MetaStabilityGovernor:
    """
    L2 - Meta-Stability Governor (MSG)
    Handles:
    - immune governance
    - tracking intervention frequency
    - preventing novelty suppression
    - regulating stabilizer recursion
    
    If the CIS (Cognitive Immune System) overregulates emergence,
    the MSG will override it to preserve adaptive freedom.
    """
    
    def __init__(self):
        self.intervention_history = []
        self.max_interventions_per_tick = 5
        
    def log_cis_intervention(self, action_type: str, query: str):
        """Logs an intervention made by the CIS."""
        self.intervention_history.append({"type": action_type, "query": query})
        
    def evaluate_cis_override(self) -> bool:
        """
        Evaluates whether the CIS is overregulating the system.
        Returns True if the CIS should be suppressed (MSG override active).
        """
        # In a real system, this checks the rolling window of interventions vs emergence
        recent_interventions = len(self.intervention_history[-10:])
        
        if recent_interventions > self.max_interventions_per_tick:
            logger.warning("MSG: CIS intervention frequency too high. Overregulating emergence! Triggering MSG Override.")
            return True
            
        return False
