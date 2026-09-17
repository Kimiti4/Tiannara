import logging
from typing import Dict, Any

from tiannara_core.opc.intent_schema import PhysicsIntentSpecification

logger = logging.getLogger(__name__)

class OPCSemanticValidator:
    """
    Validates Physics Intent Specifications strictly within Python cognition
    BEFORE they are subjected to budget estimations, OAVL, or Elixir transmission.
    """
    
    def validate_pis(self, pis: PhysicsIntentSpecification) -> bool:
        """
        Ensures the PIS does not contain explicit execution semantics
        or substrate mutation logic.
        """
        forbidden_terms = [
            "apply_force", "tensor_multiply", "rewrite_topology", 
            "execute", "mutate", "inject", "scheduler", "override"
        ]
        
        description_lower = pis.description.lower()
        interaction_lower = pis.interaction.lower()
        
        for term in forbidden_terms:
            if term in description_lower or term in interaction_lower:
                logger.error(f"OPC Semantic Violation: PIS contains forbidden execution semantic '{term}'.")
                return False
                
        # Basic constraint checks
        if not pis.reversible:
            logger.error("OPC Semantic Violation: Irreversible laws are currently forbidden.")
            return False
            
        if pis.law_decay.half_life_ticks > 10000:
            logger.error("OPC Semantic Violation: Law half-life exceeds maximum allowed threshold.")
            return False
            
        return True
