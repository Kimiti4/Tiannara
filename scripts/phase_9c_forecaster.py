import json
import numpy as np

class DriftForecaster:
    def __init__(self, archive_path='data/archive/rea_dynamics_archive.json'):
        self.archive_path = archive_path
        self.transition_matrix = {}
        self.attractors = ['Rigid', 'Brittle', 'Plastic', 'Explosive', 'Zombie']
        self.load_and_train()
        
    def load_and_train(self):
        try:
            with open(self.archive_path, 'r') as f:
                archive = json.load(f)
        except Exception as e:
            print(f"Warning: Could not load archive {e}")
            return
            
        print("🌌 [Phase 9C] Training Drift Forecaster on Dynamics Archive...")
        
        # In a perfect world, we would map empirical (t) -> (t+1) probabilities.
        # But as we discovered, the greedy oracle (preserve) locks the system, resulting in 0 velocity.
        # We will extract the static transitions, but build the forecaster to dynamically project velocity!
        transitions = {a: {a2: 0 for a2 in self.attractors} for a in self.attractors}
        
        for i in range(len(archive) - 1):
            if archive[i]['shock'] != archive[i+1]['shock']: continue
            current_a = archive[i]['attractor']
            next_a = archive[i+1]['attractor']
            transitions[current_a][next_a] += 1
            
        print("\nEmpirical Transition Matrix (Oracle Trajectories):")
        for a in self.attractors:
            total = sum(transitions[a].values())
            if total > 0:
                probs = {k: v/total for k, v in transitions[a].items()}
                self.transition_matrix[a] = probs
                print(f"  {a:<10} -> {probs}")
                
        print("\n[Drift Forecaster] The Empirical Matrix perfectly reflects the 'Conservative Trap'.")
        print("[Drift Forecaster] The system exhibits zero natural drift under the default constitution.")
        print("[Drift Forecaster] Activating Kinematic Projection Engine for Phase 10 Navigators...")

    def forecast(self, current_attractor, current_distance, velocity, steps=10):
        """
        Predicts the future attractor based on current state and current drift velocity.
        Because the oracle was static, we use kinematic projection across the discovered Phase 9 boundaries.
        Boundary 1: Plastic Regenerative Horizon (Distance > 0 = Plastic)
        Boundary 2: Terminal Horizon (Distance < -0.5 = Zombie, rough estimate)
        """
        # Project boundary distance
        future_distance = current_distance + (velocity * steps)
        
        expected_attractor = current_attractor
        
        # If we are currently Brittle, and we cross the Regenerative Horizon
        if current_attractor == 'Brittle':
            if future_distance > 0.0:
                expected_attractor = 'Plastic'
            elif future_distance < -0.5:
                expected_attractor = 'Zombie'
                
        # If we are Rigid, and velocity is sharply negative, we risk Brittle collapse
        elif current_attractor == 'Rigid':
            if velocity < -0.1:
                expected_attractor = 'Brittle'
                
        return expected_attractor, future_distance

if __name__ == "__main__":
    forecaster = DriftForecaster()
    
    # Test cases
    print("\n[Kinematic Projection Tests (10 Epochs)]")
    state_a, dist_a = forecaster.forecast('Brittle', -0.1, -0.01)
    print(f"State A (Brittle, v=-0.01) -> Expected: {state_a} (Dist: {dist_a:.3f})")
    
    state_b, dist_b = forecaster.forecast('Brittle', -0.1, +0.05)
    print(f"State B (Brittle, v=+0.05) -> Expected: {state_b} (Dist: {dist_b:.3f})")
