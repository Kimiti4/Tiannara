"""
Millennium Problem Phase-Space Engine

This module models the 7 Millennium Prize Problems as dynamical energy landscapes.
Civilizations do not 'solve' them; they explore the mathematical phase-space and 
find stable structural attractors.
"""

import math
import random
from typing import Dict, List, Tuple

class FieldSurface:
    def __init__(self, name: str, dimensions: int = 8):
        self.name = name
        self.dimensions = dimensions
        # Energy landscape grid (flattened)
        self.grid = [random.random() for _ in range(dimensions * dimensions)]
        self.velocity = [(random.random() - 0.5) * 0.1 for _ in range(dimensions * dimensions)]
        self.attractors: List[Tuple[float, float, float]] = []
        self.repellers: List[Tuple[float, float, float]] = []
        
        # Initialize some stable attractors (solutions/lemmas)
        for _ in range(random.randint(1, 3)):
            self.attractors.append(
                ((random.random() - 0.5) * 10, (random.random() - 0.5) * 10, (random.random() - 0.5) * 10)
            )

    def compute_energy_at(self, x: float, y: float, z: float) -> float:
        """Computes continuous energy at a point using attractors/repellers."""
        energy = sum(self.grid) / len(self.grid) # base energy
        
        # Attractors lower energy
        for ax, ay, az in self.attractors:
            dist = math.sqrt((x-ax)**2 + (y-ay)**2 + (z-az)**2)
            energy -= 1.0 / (dist + 0.1)
            
        # Repellers increase energy
        for rx, ry, rz in self.repellers:
            dist = math.sqrt((x-rx)**2 + (y-ry)**2 + (z-rz)**2)
            energy += 1.0 / (dist + 0.1)
            
        return energy

class MillenniumDynamicalSystem:
    def __init__(self):
        # 1. Initialize the 7 fields
        self.fields: Dict[str, FieldSurface] = {
            "p_vs_np": FieldSurface("p_vs_np"),
            "riemann": FieldSurface("riemann"),
            "navier_stokes": FieldSurface("navier_stokes"),
            "yang_mills": FieldSurface("yang_mills"),
            "poincare": FieldSurface("poincare"),
            "bsd": FieldSurface("bsd"),
            "hodge": FieldSurface("hodge")
        }
        
        # 2. Define cross-problem coupling matrix
        self.coupling_matrix = {
            "riemann": {"hodge": 0.6, "bsd": 0.7},
            "navier_stokes": {"yang_mills": 0.4},
            "p_vs_np": {"p_vs_np": 1.0}, # Base self-coupling, influences all slowly
            "poincare": {"hodge": 0.8},
            "bsd": {},
            "hodge": {},
            "yang_mills": {}
        }
        
    def step_evolution(self, dt: float = 0.1):
        """
        Evolves the mathematical landscapes.
        dE_i/dt = Laplacian(E_i) + sum(alpha_ij(E_j - E_i))
        """
        # A simple placeholder evolution simulating fluid mechanics on the energy grid
        for name, field in self.fields.items():
            for i in range(len(field.grid)):
                # Decay velocity
                field.velocity[i] *= 0.99 
                
                # Update grid
                field.grid[i] += field.velocity[i] * dt
                
                # Keep within bounds
                field.grid[i] = max(0.0, min(1.0, field.grid[i]))
                
    def compute_civilization_reward(self, 
                                    civ_id: str, 
                                    field_name: str, 
                                    civ_position: Tuple[float, float, float],
                                    consistency_gain: float,
                                    novelty_score: float) -> float:
        """
        R = \lambda_1 C + \lambda_2 S + \lambda_3 D + \lambda_4 I
        Where:
        C = Consistency Gain
        S = Structure Formation (energy minimization)
        D = Distance Reduction to Attractor
        I = Insight Novelty
        """
        if field_name not in self.fields:
            return 0.0
            
        field = self.fields[field_name]
        
        # 1. Consistency Gain (C)
        C = consistency_gain
        
        # 2. Structure Formation (S) - based on current energy landscape
        x, y, z = civ_position
        energy = field.compute_energy_at(x, y, z)
        S = -energy # Lower energy = higher reward (stable structure)
        
        # 3. Distance Reduction to Attractor (D)
        # Find closest attractor
        D = 0.0
        if field.attractors:
            min_dist = float('inf')
            for ax, ay, az in field.attractors:
                dist = math.sqrt((x-ax)**2 + (y-ay)**2 + (z-az)**2)
                min_dist = min(min_dist, dist)
            D = 1.0 / (min_dist + 0.1) # Reward proximity
            
        # 4. Insight Novelty (I)
        I = novelty_score
        
        # Weights
        lambda_1, lambda_2, lambda_3, lambda_4 = 1.0, 1.5, 2.0, 0.8
        
        # Total Reward
        total_reward = (lambda_1 * C) + (lambda_2 * S) + (lambda_3 * D) + (lambda_4 * I)
        
        return total_reward
        
    def extract_state(self) -> Dict:
        """Extracts the state for the WebSocket stream."""
        state = {}
        for name, field in self.fields.items():
            state[name] = {
                "id": name,
                "grid": field.grid.copy(),
                "velocity": field.velocity.copy(),
                "entropy": sum(field.grid) / len(field.grid), # Rough entropy
                "attractors": field.attractors.copy(),
                "repellers": field.repellers.copy(),
                "couplingWeights": self.coupling_matrix.get(name, {})
            }
        return state
