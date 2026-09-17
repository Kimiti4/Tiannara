"""
Tiannara Reasoning Layer (Phase 5)

This module represents the Cognitive Engine that observes the Elixir ecosystem,
computes latent representations, and suggests evolutionary pressure updates 
back to the substrate.
"""

from typing import Dict, Any, List
import math

class CognitiveReasoningEngine:
    def __init__(self):
        self.latent_memory = []
        
    def observe_phase_space(self, phase_space_state: Dict[str, Any]):
        """
        Step 1: Observe streams from Elixir runtime (injected here as phase_space_state).
        """
        # Step 2: Model latent representations
        latent_state = self._compute_latent_representation(phase_space_state)
        self.latent_memory.append(latent_state)
        
        # Keep memory bounded
        if len(self.latent_memory) > 100:
            self.latent_memory.pop(0)
            
    def _compute_latent_representation(self, state: Dict[str, Any]) -> Dict[str, float]:
        """
        Condenses the high-dimensional Millennium Fields and civilization 
        positions into a latent cognitive vector.
        """
        fields = state.get("fields", {})
        civilizations = state.get("civilizations", [])
        
        # Calculate global epistemic energy
        total_energy = 0.0
        for f in fields.values():
            total_energy += sum(f["grid"]) / len(f["grid"])
            
        # Calculate cross-system divergence risk (entropy)
        total_entropy = sum(f["entropy"] for f in fields.values()) / max(1, len(fields))
        
        # Calculate civilization convergence
        avg_temp = sum(c["explorationTemperature"] for c in civilizations) / max(1, len(civilizations))
        
        return {
            "time": state.get("time", 0.0),
            "epistemic_energy": total_energy,
            "divergence_risk": total_entropy,
            "convergence_rate": 1.0 - avg_temp
        }
        
    def suggest_pressure_updates(self) -> Dict[str, float]:
        """
        Step 4: Suggest evolutionary pressure updates based on the latent state.
        This is passed back to Elixir's WorldServer / UniverseServer.
        """
        if not self.latent_memory:
            return {"global_pressure": 1.0, "mutation_rate": 0.01}
            
        current = self.latent_memory[-1]
        
        # If divergence risk is high, increase evolutionary pressure to force convergence
        # If divergence risk is low, increase mutation rate to explore new topologies
        
        global_pressure = 1.0 + (current["divergence_risk"] * 2.0)
        mutation_rate = 0.01 + (1.0 - current["convergence_rate"]) * 0.05
        
        return {
            "global_pressure": global_pressure,
            "mutation_rate": mutation_rate,
            "recommended_action": "stabilize" if current["divergence_risk"] > 0.7 else "explore"
        }

# Global singleton
REASONING_ENGINE = CognitiveReasoningEngine()
