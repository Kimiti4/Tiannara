import logging

logger = logging.getLogger(__name__)

class EpistemicUncertaintyField:
    """
    L4 - Epistemic Uncertainty Field (EUF)
    Handles:
    - epistemic confidence
    - semantic reliability
    - ontology survivability
    
    Prevents "coherent semantic corruption" by tracking the uncertainty 
    and reliability of concepts over time.
    """
    
    def __init__(self):
        self.uncertainty_ledger = {}
        
    def calculate_confidence(self, query: str, context: list) -> float:
        """
        Estimates the epistemic confidence of a proposed query/action.
        Higher uncertainty means the semantic reliability is low.
        """
        # Simulated logic: longer context generally reduces uncertainty slightly
        base_confidence = 0.5
        context_boost = len(context) * 0.05
        return min(base_confidence + context_boost, 1.0)
        
    def record_survivability(self, concept_id: str, success: bool):
        """
        Records whether a concept survived the crucible or reality execution,
        adjusting its semantic reliability score.
        """
        if concept_id not in self.uncertainty_ledger:
            self.uncertainty_ledger[concept_id] = {"reliability": 0.5, "tests": 0}
            
        record = self.uncertainty_ledger[concept_id]
        record["tests"] += 1
        
        # Adjust reliability
        if success:
            record["reliability"] = min(1.0, record["reliability"] + 0.1)
        else:
            record["reliability"] = max(0.0, record["reliability"] - 0.2)
            
        logger.debug(f"EUF: Concept {concept_id} survivability updated. Reliability: {record['reliability']}")
