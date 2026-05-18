"""
ARCHITECTURAL BREAKTHROUGH v21: Phase 2 Python Simulation Cortex

Python GRCC v10/v11 simulation engine that connects to NATS event bus.

This module implements the "simulation cortex" layer that:
- Receives simulation step requests from Elixir via NATS
- Runs GRCC ecological dynamics (lineage evolution, entropy computation)
- Emits results back to Elixir for CIS evaluation
- Accepts CIS interventions and adjusts simulation parameters

Design Rule: Python computes simulation state but NEVER enforces system integrity.
Elixir owns orchestration; Python owns computation.
"""

import asyncio
import json
import time
from typing import Dict, Any, Optional
from datetime import datetime

try:
    import nats
    from nats.aio.client import Client as NATSClient
    NATS_AVAILABLE = True
except ImportError:
    NATS_AVAILABLE = False
    print("⚠️  NATS library not installed. Install with: pip install nats-py")


class GRCCSimulationCortex:
    """
    Python simulation cortex that runs GRCC v10/v11 ecological dynamics.
    
    This is the "voluntary cortex" - it computes lineage evolution, entropy,
    niche generation, but does NOT manage system state or enforce invariants.
    """
    
    def __init__(self, nats_url: str = "nats://localhost:4222"):
        self.nats_url = nats_url
        self.nc: Optional[NATSClient] = None
        self.simulation_state = {
            'step_count': 0,
            'lineage_population': {},
            'entropy': 0.5,
            'dominance': 0.0,
            'niche_map': {},
            'anomalies': []
        }
        
        # Simulation parameters (can be modified by CIS interventions)
        self.params = {
            'mutation_rate': 0.1,
            'reproduction_threshold': 0.7,
            'extinction_pressure': 0.05,
            'niche_generation_rate': 0.2
        }
    
    async def connect(self):
        """Connect to NATS server."""
        if not NATS_AVAILABLE:
            print("❌ NATS not available. Cannot connect.")
            return False
        
        try:
            self.nc = NATSClient()
            await self.nc.connect(self.nats_url)
            print(f"✅ Python Cortex connected to NATS: {self.nats_url}")
            
            # Subscribe to Elixir events
            await self.nc.subscribe("grcc.sim.step.request", cb=self.handle_step_request)
            await self.nc.subscribe("cis.intervention.trigger", cb=self.handle_intervention)
            
            print("📥 Subscribed to: grcc.sim.step.request, cis.intervention.trigger")
            return True
            
        except Exception as e:
            print(f"❌ Failed to connect to NATS: {e}")
            return False
    
    async def handle_step_request(self, msg):
        """
        Handle simulation step request from Elixir.
        
        Flow:
        1. Receive step request
        2. Run GRCC simulation step
        3. Compute metrics (entropy, dominance, niches)
        4. Publish results to NATS
        """
        try:
            # Decode request
            data = json.loads(msg.data.decode())
            step_params = data.get('params', {})
            
            print(f"🧠 Received simulation step request: {data.get('timestamp')}")
            
            # Run simulation step
            result = self.run_simulation_step(step_params)
            
            # Publish result
            await self.publish_step_result(result)
            
        except Exception as e:
            print(f"❌ Error handling step request: {e}")
    
    async def handle_intervention(self, msg):
        """
        Handle CIS intervention from Elixir.
        
        Adjusts simulation parameters based on immune system feedback.
        """
        try:
            data = json.loads(msg.data.decode())
            intervention_type = data.get('intervention')
            params = data.get('params', {})
            
            print(f"🛡️ Received CIS intervention: {intervention_type}")
            
            # Apply intervention
            self.apply_intervention(intervention_type, params)
            
            # Acknowledge
            response = {
                'type': 'intervention_acknowledged',
                'intervention': intervention_type,
                'new_params': self.params,
                'timestamp': datetime.utcnow().isoformat()
            }
            
            await self.nc.publish(
                "cis.intervention.ack",
                json.dumps(response).encode()
            )
            
        except Exception as e:
            print(f"❌ Error handling intervention: {e}")
    
    def run_simulation_step(self, step_params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Run one GRCC simulation step.
        
        This is where the actual ecological dynamics happen:
        - Lineage evolution (birth/death/mutation)
        - Entropy computation (Shannon diversity)
        - Niche generation
        - Anomaly detection
        
        Returns result dict for publishing to NATS.
        """
        # Increment step counter
        self.simulation_state['step_count'] += 1
        step_num = self.simulation_state['step_count']
        
        print(f"⚙️ Running simulation step {step_num}...")
        
        # TODO: Replace with actual GRCC v10/v11 simulation logic
        # For now, simulate basic ecological dynamics
        
        # Simulate lineage population changes
        self._evolve_lineages()
        
        # Compute entropy
        entropy = self._compute_entropy()
        
        # Compute dominance
        dominance = self._compute_dominance()
        
        # Generate/update niches
        niche_map = self._update_niches()
        
        # Detect anomalies
        anomalies = self._detect_anomalies()
        
        # Update state
        self.simulation_state.update({
            'entropy': entropy,
            'dominance': dominance,
            'niche_map': niche_map,
            'anomalies': anomalies
        })
        
        # Build result
        result = {
            'step_number': step_num,
            'lineage_state': self.simulation_state['lineage_population'],
            'entropy': entropy,
            'dominance': dominance,
            'niche_map': niche_map,
            'anomalies': anomalies,
            'params': self.params.copy(),
            'timestamp': datetime.utcnow().isoformat()
        }
        
        print(f"✓ Step {step_num} complete: entropy={entropy:.3f}, dominance={dominance:.3f}")
        
        return result
    
    async def publish_step_result(self, result: Dict[str, Any]):
        """Publish simulation step result to NATS."""
        if not self.nc:
            print("❌ Cannot publish: NATS not connected")
            return
        
        payload = json.dumps(result).encode()
        
        # Publish to main result topic
        await self.nc.publish("grcc.sim.step.result", payload)
        
        # Also publish to python-specific topic for debugging
        await self.nc.publish("python.sim.result", payload)
        
        print(f"📤 Published step result to NATS")
    
    def _evolve_lineages(self):
        """Simulate lineage evolution (birth/death/mutation)."""
        # Placeholder - replace with actual GRCC v10 evolutionary dynamics
        # This would integrate with test_long_horizon_goal_integrity.py logic
        
        # Simple simulation: add/remove lineages randomly
        current_lineages = list(self.simulation_state['lineage_population'].keys())
        
        # Birth new lineage (10% chance)
        if len(current_lineages) < 10 and hash(str(time.time())) % 10 == 0:
            new_id = f"lineage_{len(current_lineages) + 1}"
            self.simulation_state['lineage_population'][new_id] = {
                'population': 10,
                'fitness': 0.5,
                'birth_step': self.simulation_state['step_count']
            }
            print(f"  🧬 New lineage born: {new_id}")
        
        # Remove weak lineage (5% chance per lineage)
        for lineage_id in current_lineages:
            if hash(lineage_id + str(time.time())) % 20 == 0:
                del self.simulation_state['lineage_population'][lineage_id]
                print(f"  💀 Lineage extinct: {lineage_id}")
    
    def _compute_entropy(self) -> float:
        """Compute Shannon diversity entropy."""
        import math
        
        populations = [
            info['population'] 
            for info in self.simulation_state['lineage_population'].values()
        ]
        
        total = sum(populations)
        if total == 0:
            return 0.0
        
        # Calculate Shannon entropy
        probabilities = [p / total for p in populations]
        entropy = -sum(p * math.log(p) for p in probabilities if p > 0)
        
        # Normalize to [0, 1] range
        max_entropy = math.log(len(populations)) if len(populations) > 1 else 1.0
        normalized_entropy = entropy / max_entropy if max_entropy > 0 else 0.0
        
        return normalized_entropy
    
    def _compute_dominance(self) -> float:
        """Compute maximum lineage dominance (population share)."""
        populations = [
            info['population'] 
            for info in self.simulation_state['lineage_population'].values()
        ]
        
        total = sum(populations)
        if total == 0:
            return 0.0
        
        max_population = max(populations) if populations else 0
        dominance = max_population / total
        
        return dominance
    
    def _update_niches(self) -> Dict[str, Any]:
        """Update niche map."""
        # Placeholder - replace with actual niche generation logic
        niche_count = max(2, len(self.simulation_state['lineage_population']) // 2)
        
        return {
            f"niche_{i}": {
                'occupancy': hash(f"niche_{i}{time.time()}") % 100,
                'resources': 0.5 + (hash(f"resources_{i}") % 50) / 100
            }
            for i in range(niche_count)
        }
    
    def _detect_anomalies(self) -> list:
        """Detect ecological anomalies."""
        anomalies = []
        
        # Check for extreme dominance
        if self.simulation_state['dominance'] > 0.9:
            anomalies.append({
                'type': 'extreme_dominance',
                'value': self.simulation_state['dominance'],
                'threshold': 0.9
            })
        
        # Check for entropy collapse
        if self.simulation_state['entropy'] < 0.1:
            anomalies.append({
                'type': 'entropy_collapse',
                'value': self.simulation_state['entropy'],
                'threshold': 0.1
            })
        
        return anomalies
    
    def apply_intervention(self, intervention_type: str, params: Dict[str, Any]):
        """
        Apply CIS intervention by adjusting simulation parameters.
        
        Interventions:
        - heavy_suppression: Reduce dominant lineage advantage
        - entropy_injection: Boost mutation rates to increase diversity
        - mild_diversity_boost: Slight parameter adjustments
        """
        if intervention_type == "heavy_suppression":
            # Increase mutation rate to break monoculture
            self.params['mutation_rate'] = min(0.5, self.params['mutation_rate'] + params.get('mutation_boost', 0.2))
            print(f"  🛡️ Applied heavy suppression: mutation_rate={self.params['mutation_rate']}")
        
        elif intervention_type == "entropy_injection":
            # Dramatically increase mutation and reduce selection pressure
            self.params['mutation_rate'] = min(0.6, self.params['mutation_rate'] + 0.3)
            self.params['extinction_pressure'] = max(0.01, self.params['extinction_pressure'] - 0.03)
            print(f"  🛡️ Applied entropy injection: mutation_rate={self.params['mutation_rate']}")
        
        elif intervention_type == "mild_diversity_boost":
            # Slight mutation rate increase
            self.params['mutation_rate'] = min(0.3, self.params['mutation_rate'] + params.get('mutation_rate_increase', 0.05))
            print(f"  🛡️ Applied mild diversity boost: mutation_rate={self.params['mutation_rate']}")
        
        else:
            print(f"  ⚠️ Unknown intervention type: {intervention_type}")
    
    async def disconnect(self):
        """Disconnect from NATS."""
        if self.nc:
            await self.nc.close()
            print("🔌 Disconnected from NATS")


async def main():
    """Main entry point for Python simulation cortex."""
    print("🧠 Starting Python GRCC Simulation Cortex...")
    
    # Get NATS URL from environment or use default
    nats_url = "nats://localhost:4222"
    
    # Create and connect cortex
    cortex = GRCCSimulationCortex(nats_url=nats_url)
    
    if not await cortex.connect():
        print("❌ Failed to connect to NATS. Exiting.")
        return
    
    print("✅ Python Cortex ready. Waiting for simulation step requests...")
    
    try:
        # Keep running indefinitely
        while True:
            await asyncio.sleep(1)
    
    except KeyboardInterrupt:
        print("\n🛑 Shutting down Python Cortex...")
    
    finally:
        await cortex.disconnect()


if __name__ == "__main__":
    asyncio.run(main())
