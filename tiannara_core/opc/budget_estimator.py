import logging
from typing import Dict, Any

from tiannara_core.opc.intent_schema import ResourceProfile, PhysicsCategory

logger = logging.getLogger(__name__)

class OPCBudgetEstimator:
    """
    Stage 2: Budget Estimator
    
    Predicts the URCL runtime cost (branch factor, entropy, topology, stabilization)
    for a proposed physics intent. Ensures no observer can propose physics that 
    will instantly bankrupt the topological budget.
    """
    
    def estimate_profile(self, category: PhysicsCategory, interaction: str) -> ResourceProfile:
        """
        Generates a ResourceProfile projection based on the category and interaction type.
        """
        # Baseline
        branch_factor = 1.0
        entropy = "low"
        topology = "low"
        stability_cost = "bounded"
        
        interaction_lower = interaction.lower()
        
        # Adjust based on interaction complexity
        if "repel" in interaction_lower or "conflict" in interaction_lower:
            entropy = "high"
            stability_cost = "high"
            branch_factor += 0.5
            
        if "attract" in interaction_lower or "merge" in interaction_lower:
            topology = "medium"
            stability_cost = "bounded"
            branch_factor += 0.2
            
        # Adjust based on physics category
        if category == PhysicsCategory.CAUSAL:
            topology = "extreme"
            stability_cost = "extreme"
            branch_factor += 1.0  # Causal changes cause massive branching
            
        elif category == PhysicsCategory.TOPOLOGICAL:
            topology = "high"
            
        # Hard limits
        branch_factor = min(branch_factor, 3.0)
        
        profile = ResourceProfile(
            expected_branch_factor=branch_factor,
            entropy_impact=entropy,
            topology_pressure=topology,
            stabilization_cost=stability_cost
        )
        
        logger.info(f"OPC Budget Estimator: Projected profile for {category.value} / {interaction} -> Branch={branch_factor}, Topology={topology}")
        return profile
