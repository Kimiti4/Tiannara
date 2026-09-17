import logging
import json
from typing import Dict, Any, Optional

from tiannara_core.opc.intent_schema import PhysicsIntentSpecification, PhysicsCategory, LawDecay, ObserverSignature, ResourceProfile
from tiannara_core.opc.semantic_validator import OPCSemanticValidator
from tiannara_core.opc.budget_estimator import OPCBudgetEstimator
from tiannara_core.coherence.euf import EpistemicUncertaintyField

logger = logging.getLogger(__name__)

class OPCBridge:
    """
    Observer Physics Compiler (OPC) Bridge - Stage 1 & 2
    
    Responsible solely for constructing the declarative Physics Intent Specification (PIS).
    No deployment, no execution ASTs.
    """
    
    def __init__(self):
        self.validator = OPCSemanticValidator()
        self.budget_estimator = OPCBudgetEstimator()
        self.euf = EpistemicUncertaintyField()
        
    def generate_pis(
        self, 
        observer_id: str, 
        ontology_class: str,
        category: PhysicsCategory,
        domain: str,
        interaction: str,
        target: str,
        description: str
    ) -> Optional[PhysicsIntentSpecification]:
        """
        Generates a declarative PIS based on observer intent.
        """
        signature = ObserverSignature(
            observer_id=observer_id,
            lineage=f"{observer_id}_v1",
            ontology_class=ontology_class,
            trust_score=0.8
        )
        
        decay = LawDecay(
            half_life_ticks=1000,
            renewal_mode="survivability_based"
        )
        
        # Stage 2: Integrate EUF Confidence and URCL Budget Profile
        resource_profile = self.budget_estimator.estimate_profile(category, interaction)
        # Fake a context list for the EUF score based on domain/interaction
        epistemic_confidence = self.euf.calculate_confidence(description, [domain, interaction, target])
        
        pis = PhysicsIntentSpecification(
            category=category,
            domain=domain,
            interaction=interaction,
            target=target,
            law_decay=decay,
            observer_signature=signature,
            resource_profile=resource_profile,
            epistemic_confidence=epistemic_confidence,
            description=description
        )
        
        # Stage 1: Basic Declarative Validation
        if self.validator.validate_pis(pis):
            logger.info(f"OPC Bridge: Generated valid PIS [{pis.intent_id}] for observer {observer_id}")
            return pis
        else:
            logger.error(f"OPC Bridge: PIS generation failed semantic constraints.")
            return None
            
    def export_pis_to_json(self, pis: PhysicsIntentSpecification) -> str:
        """Exports the PIS to a generic format suitable for transmission to Elixir."""
        return pis.model_dump_json()
