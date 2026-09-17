"""Synthetic Causal System Domain - x→y→z Dependencies with Controllable Ground Truth.

This domain tests the system's ability to:
1. Discover causal relationships in synthetic systems
2. Infer dependency chains (x causes y, y causes z)
3. Predict outcomes under interventions

Best for causality testing and ACDR (Algorithmic Compression Discovery Reasoning).
"""

import random
from typing import Dict, Any, List, Tuple


class CausalSystemGenerator:
    """Generates synthetic causal system tasks."""
    
    def __init__(self, seed: int = None):
        self.rng = random.Random(seed)
        
        # Adaptive difficulty tracking
        self.episode_count = 0
        self.difficulty_level = "easy"
        self.success_history = []
    
    def _get_difficulty_params(self, episode: int = None) -> Dict[str, Any]:
        """Calculate difficulty parameters based on episode and performance."""
        if episode is not None:
            self.episode_count = episode
        
        # Base difficulty from episode progression
        if self.episode_count < 30:
            base_difficulty = "easy"
        elif self.episode_count < 70:
            base_difficulty = "medium"
        else:
            base_difficulty = "hard"
        
        # Adjust based on recent performance
        if len(self.success_history) >= 10:
            recent_success = sum(self.success_history[-10:]) / len(self.success_history[-10:])
            
            if recent_success > 0.7 and base_difficulty != "hard":
                if base_difficulty == "easy":
                    base_difficulty = "medium"
                elif base_difficulty == "medium":
                    base_difficulty = "hard"
            elif recent_success < 0.3 and base_difficulty != "easy":
                if base_difficulty == "hard":
                    base_difficulty = "medium"
                elif base_difficulty == "medium":
                    base_difficulty = "easy"
        
        self.difficulty_level = base_difficulty
        
        # Define parameters for each difficulty level
        params = {
            "easy": {
                "num_variables": 3,     # x, y, z
                "chain_length": 2,      # x → y → z
                "num_observations": 5   # Few observations
            },
            "medium": {
                "num_variables": 4,
                "chain_length": 3,
                "num_observations": 8
            },
            "hard": {
                "num_variables": 5,
                "chain_length": 4,
                "num_observations": 12
            }
        }
        
        return params[base_difficulty]
    
    def update_performance(self, success: bool):
        """Record task outcome for adaptive difficulty."""
        self.success_history.append(1 if success else 0)
        if len(self.success_history) > 20:
            self.success_history.pop(0)
    
    def generate_task(self, episode: int = None) -> Dict[str, Any]:
        """Generate a causal system task."""
        diff_params = self._get_difficulty_params(episode)
        
        task_type = self.rng.choice([
            "linear_causal_chain",
            "branching_causal",
            "confounded_system",
            "intervention_prediction"
        ])
        
        if task_type == "linear_causal_chain":
            return self._generate_linear_chain(diff_params)
        elif task_type == "branching_causal":
            return self._generate_branching(diff_params)
        elif task_type == "confounded_system":
            return self._generate_confounded(diff_params)
        else:  # intervention_prediction
            return self._generate_intervention(diff_params)
    
    def _generate_linear_chain(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate linear causal chain: x → y → z"""
        num_vars = diff_params["num_variables"]
        chain_length = diff_params["chain_length"]
        num_obs = diff_params["num_observations"]
        
        # Generate causal coefficients
        coeffs = [self.rng.uniform(0.5, 2.0) for _ in range(chain_length)]
        intercepts = [self.rng.uniform(-2, 2) for _ in range(chain_length)]
        
        # Variable names
        var_names = ['x', 'y', 'z', 'w', 'v'][:num_vars]
        
        # Generate observations
        observations = []
        for _ in range(num_obs):
            obs = {}
            # Start with root variable
            obs[var_names[0]] = self.rng.uniform(-5, 5)
            
            # Propagate through chain
            for i in range(chain_length):
                parent = var_names[i]
                child = var_names[i + 1]
                obs[child] = coeffs[i] * obs[parent] + intercepts[i]
            
            observations.append(obs)
        
        # Generate intervention query
        intervention_var = var_names[0]
        intervention_value = self.rng.uniform(-5, 5)
        
        # Calculate expected outcome at end of chain
        current_value = intervention_value
        for i in range(chain_length):
            current_value = coeffs[i] * current_value + intercepts[i]
        
        expected_outcome = current_value
        
        return {
            "type": "causal_system",
            "subtype": "linear_causal_chain",
            "inputs": {
                "observations": observations,
                "intervention": {
                    "variable": intervention_var,
                    "value": intervention_value
                },
                "target_variable": var_names[-1]
            },
            "expected_output": expected_outcome,
            "description": f"Predict {var_names[-1]} when {intervention_var}={intervention_value:.2f}",
            "difficulty": self.difficulty_level,
            "hidden_params": {
                "coefficients": coeffs,
                "intercepts": intercepts,
                "chain": " → ".join(var_names[:chain_length+1])
            }
        }
    
    def _generate_branching(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate branching causal structure: x → y, x → z"""
        num_obs = diff_params["num_observations"]
        
        # Generate coefficients for branching
        coeff_y = self.rng.uniform(0.5, 2.0)
        coeff_z = self.rng.uniform(0.5, 2.0)
        intercept_y = self.rng.uniform(-2, 2)
        intercept_z = self.rng.uniform(-2, 2)
        
        # Generate observations
        observations = []
        for _ in range(num_obs):
            x = self.rng.uniform(-5, 5)
            y = coeff_y * x + intercept_y
            z = coeff_z * x + intercept_z
            observations.append({"x": x, "y": y, "z": z})
        
        # Intervention query
        intervention_x = self.rng.uniform(-5, 5)
        expected_y = coeff_y * intervention_x + intercept_y
        expected_z = coeff_z * intervention_x + intercept_z
        
        # Ask for one of the outcomes
        target = self.rng.choice(["y", "z"])
        expected_output = expected_y if target == "y" else expected_z
        
        return {
            "type": "causal_system",
            "subtype": "branching_causal",
            "inputs": {
                "observations": observations,
                "intervention": {
                    "variable": "x",
                    "value": intervention_x
                },
                "target_variable": target
            },
            "expected_output": expected_output,
            "description": f"Predict {target} when x={intervention_x:.2f} (branching system)",
            "difficulty": self.difficulty_level,
            "hidden_params": {
                "coeff_y": coeff_y,
                "coeff_z": coeff_z,
                "structure": "x → y, x → z"
            }
        }
    
    def _generate_confounded(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate confounded system: u → x, u → y (spurious correlation)"""
        num_obs = diff_params["num_observations"]
        
        # Hidden confounder
        coeff_ux = self.rng.uniform(0.5, 2.0)
        coeff_uy = self.rng.uniform(0.5, 2.0)
        
        # Generate observations
        observations = []
        for _ in range(num_obs):
            u = self.rng.uniform(-5, 5)  # Hidden confounder
            x = coeff_ux * u + self.rng.uniform(-1, 1)  # Add noise
            y = coeff_uy * u + self.rng.uniform(-1, 1)
            observations.append({"x": x, "y": y})
        
        # Query: What happens to y when we intervene on x?
        # Answer: Nothing! (no causal link, only correlation through u)
        intervention_x = self.rng.uniform(-5, 5)
        
        # Expected: y doesn't change (or changes minimally due to noise)
        # For simplicity, return mean of observed y values
        mean_y = sum(obs["y"] for obs in observations) / len(observations)
        expected_output = mean_y
        
        return {
            "type": "causal_system",
            "subtype": "confounded_system",
            "inputs": {
                "observations": observations,
                "intervention": {
                    "variable": "x",
                    "value": intervention_x
                },
                "target_variable": "y"
            },
            "expected_output": expected_output,
            "description": f"Predict y when x={intervention_x:.2f} (watch for confounding!)",
            "difficulty": self.difficulty_level,
            "hidden_params": {
                "confounder": "u",
                "structure": "u → x, u → y (no x → y link)"
            }
        }
    
    def _generate_intervention(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate intervention prediction task."""
        num_obs = diff_params["num_observations"]
        
        # Simple causal: x → y with known relationship
        coeff = self.rng.uniform(0.5, 2.0)
        intercept = self.rng.uniform(-2, 2)
        
        # Generate observational data
        observations = []
        for _ in range(num_obs):
            x = self.rng.uniform(-5, 5)
            y = coeff * x + intercept
            observations.append({"x": x, "y": y})
        
        # Counterfactual query
        observed_x = self.rng.uniform(-5, 5)
        observed_y = coeff * observed_x + intercept
        
        # What if x had been different?
        counterfactual_x = observed_x + self.rng.uniform(-3, 3)
        counterfactual_y = coeff * counterfactual_x + intercept
        
        return {
            "type": "causal_system",
            "subtype": "intervention_prediction",
            "inputs": {
                "observations": observations,
                "observed": {"x": observed_x, "y": observed_y},
                "counterfactual": {"x": counterfactual_x},
                "target_variable": "y"
            },
            "expected_output": counterfactual_y,
            "description": f"Counterfactual: If x={counterfactual_x:.2f} instead of {observed_x:.2f}, what is y?",
            "difficulty": self.difficulty_level,
            "hidden_params": {
                "coefficient": coeff,
                "intercept": intercept
            }
        }
    
    def verify_solution(self, task: Dict[str, Any], output: Any) -> bool:
        """Verify if predicted output matches expected (with tolerance for float)."""
        expected = task["expected_output"]
        return abs(output - expected) < 0.1  # Allow some tolerance for float operations


# Example usage
if __name__ == "__main__":
    generator = CausalSystemGenerator(seed=42)
    
    print("=" * 80)
    print("CAUSAL SYSTEM DOMAIN - SAMPLE TASKS")
    print("=" * 80)
    print()
    
    for i in range(5):
        task = generator.generate_task(episode=i+1)
        print(f"Task {i+1}: {task['description']}")
        print(f"  Type: {task['subtype']}")
        print(f"  Difficulty: {task['difficulty']}")
        print(f"  Observations: {len(task['inputs']['observations'])}")
        print(f"  Expected Output: {task['expected_output']:.4f}")
        print()
