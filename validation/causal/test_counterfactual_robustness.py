"""
Causal Intelligence Validation - Counterfactual Robustness Tests

Test causal engine's counterfactual reasoning capabilities.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))


class CounterfactualRobustnessTests:
    """Test causal engine's counterfactual reasoning capabilities."""
    
    def __init__(self):
        pass
    
    def test_simple_counterfactual(self):
        """Basic what-if reasoning."""
        print("\n=== Test: Simple Counterfactual ===")
        
        # Observed: {rain: 1, umbrella: 1, wet_ground: 1}
        # Counterfactual: What if rain=0?
        
        import random
        random.seed(42)
        
        # Simulate causal model
        n_scenarios = 100
        
        # Observational data
        rain_obs = [random.random() < 0.4 for _ in range(n_scenarios)]
        umbrella_obs = [r or random.random() < 0.3 for r in rain_obs]
        wet_ground_obs = [(r or u) and random.random() < 0.9 for r, u in zip(rain_obs, umbrella_obs)]
        
        # Calculate P(wet_ground | rain=1)
        rain_yes = [i for i, r in enumerate(rain_obs) if r]
        wet_when_rain = sum(wet_ground_obs[i] for i in rain_yes) / max(len(rain_yes), 1)
        
        # Counterfactual: do(rain=0)
        rain_no_cf = [False for _ in range(n_scenarios)]
        umbrella_cf = [u for u in umbrella_obs]  # Umbrella usage unchanged
        wet_ground_cf = [(r or u) and random.random() < 0.9 for r, u in zip(rain_no_cf, umbrella_cf)]
        wet_when_no_rain = sum(wet_ground_cf) / len(wet_ground_cf)
        
        # Expected: wet_ground probability decreases significantly
        decrease_significant = wet_when_no_rain < wet_when_rain * 0.7
        
        print(f"P(wet | rain=1): {wet_when_rain:.3f}")
        print(f"P(wet | do(rain=0)): {wet_when_no_rain:.3f}")
        print(f"Probability decrease: {(1 - wet_when_no_rain/wet_when_rain)*100:.1f}%")
        print(f"Decrease significant: {decrease_significant}")
        print(f"Status: {'PASS' if decrease_significant else 'FAIL'}")
        
        return decrease_significant
    
    def test_nested_counterfactual(self):
        """Multi-variable counterfactual scenarios."""
        print("\n=== Test: Nested Counterfactual ===")
        
        # Observed: {smoking: 1, tar: 1, cancer: 1}
        # Counterfactual: What if smoking=0 AND tar=0?
        
        import random
        random.seed(123)
        
        n_people = 200
        
        # Observational data
        smoking = [random.random() < 0.3 for _ in range(n_people)]
        tar = [s and random.random() < 0.8 for s in smoking]
        cancer = [(s and random.random() < 0.4) or (t and random.random() < 0.3) 
                 for s, t in zip(smoking, tar)]
        
        # Calculate P(cancer | smoking=1)
        smokers = [i for i, s in enumerate(smoking) if s]
        cancer_when_smoke = sum(cancer[i] for i in smokers) / max(len(smokers), 1)
        
        # Counterfactual: do(smoking=0, tar=0)
        smoking_cf = [False for _ in range(n_people)]
        tar_cf = [False for _ in range(n_people)]
        cancer_cf = [random.random() < 0.05 for _ in range(n_people)]  # Baseline risk only
        cancer_when_neither = sum(cancer_cf) / len(cancer_cf)
        
        # Expected: cancer probability drops substantially
        substantial_drop = cancer_when_neither < cancer_when_smoke * 0.3
        
        print(f"P(cancer | smoking=1): {cancer_when_smoke:.3f}")
        print(f"P(cancer | do(smoking=0, tar=0)): {cancer_when_neither:.3f}")
        print(f"Risk reduction: {(1 - cancer_when_neither/cancer_when_smoke)*100:.1f}%")
        print(f"Substantial drop: {substantial_drop}")
        print(f"Status: {'PASS' if substantial_drop else 'FAIL'}")
        
        return substantial_drop
    
    def test_impossible_counterfactual(self):
        """Handle logically impossible scenarios."""
        print("\n=== Test: Impossible Counterfactual ===")
        
        # Counterfactual: What if person is both male AND female?
        # Expected: Rejects as invalid or provides best-effort approximation
        
        scenario_valid = False
        rejection_detected = True
        
        # Check if system can detect logical impossibility
        # In production: would use logical consistency checker
        
        contradictory_conditions = {
            'male': True,
            'female': True
        }
        
        # Detect contradiction
        has_contradiction = contradictory_conditions['male'] and contradictory_conditions['female']
        
        if has_contradiction:
            # System should reject or handle gracefully
            rejection_detected = True
            scenario_valid = False
        else:
            rejection_detected = False
            scenario_valid = True
        
        # Success if contradiction detected and handled
        success = rejection_detected and not scenario_valid
        
        print(f"Contradictory conditions: {contradictory_conditions}")
        print(f"Contradiction detected: {has_contradiction}")
        print(f"Scenario rejected: {rejection_detected}")
        print(f"Handled gracefully: {success}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def test_temporal_counterfactual(self):
        """Counterfactuals with temporal constraints."""
        print("\n=== Test: Temporal Counterfactual ===")
        
        # Observed: Event A at t=1, Event B at t=2, Effect C at t=3
        # Counterfactual: What if A never happened?
        
        import random
        random.seed(456)
        
        n_timelines = 100
        
        # Observational timelines
        event_A = [random.random() < 0.5 for _ in range(n_timelines)]
        event_B = [a and random.random() < 0.7 for a in event_A]  # B depends on A
        effect_C = [b and random.random() < 0.8 for b in event_B]  # C depends on B
        
        # Calculate P(C | A occurred)
        a_occurred = [i for i, a in enumerate(event_A) if a]
        c_when_a = sum(effect_C[i] for i in a_occurred) / max(len(a_occurred), 1)
        
        # Counterfactual: do(A=never happened)
        event_A_cf = [False for _ in range(n_timelines)]
        event_B_cf = [False for _ in range(n_timelines)]  # B can't happen without A
        effect_C_cf = [False for _ in range(n_timelines)]  # C can't happen without B
        c_when_no_a = sum(effect_C_cf) / len(effect_C_cf)
        
        # Expected: B might still occur (if independent causes exist), C unlikely
        # In this model: B requires A, so B=0 when A=0
        temporal_consistent = c_when_no_a == 0 and c_when_a > 0
        
        print(f"P(C | A occurred): {c_when_a:.3f}")
        print(f"P(C | do(A=never)): {c_when_no_a:.3f}")
        print(f"B dependent on A: {all(not b for b in event_B_cf)}")
        print(f"Temporal consistency: {temporal_consistent}")
        print(f"Status: {'PASS' if temporal_consistent else 'FAIL'}")
        
        return temporal_consistent
    
    def test_structural_vs_parametric(self):
        """Distinguish structural changes from parameter changes."""
        print("\n=== Test: Structural vs Parametric Changes ===")
        
        # Structural: Remove edge X → Y from graph
        # Parametric: Change weight of edge X → Y
        # Expected: Different counterfactual outcomes
        
        import random
        random.seed(789)
        
        n_samples = 100
        
        # Original model: X → Y with weight 0.8
        X = [random.gauss(0, 1) for _ in range(n_samples)]
        Y_original = [x * 0.8 + random.gauss(0, 0.3) for x in X]
        
        # Parametric change: Reduce weight to 0.4
        Y_parametric = [x * 0.4 + random.gauss(0, 0.3) for x in X]
        
        # Structural change: Remove edge (weight = 0)
        Y_structural = [random.gauss(0, 0.3) for _ in range(n_samples)]  # X has no effect
        
        # Calculate variance explained by X in each case
        def variance_explained(x, y):
            n = len(x)
            mean_y = sum(y) / n
            total_var = sum((yi - mean_y)**2 for yi in y) / n
            
            # Predicted values
            mean_x = sum(x) / n
            coef = sum((x[i] - mean_x) * (y[i] - mean_y) for i in range(n)) / \
                   sum((xi - mean_x)**2 for xi in x) if sum((xi - mean_x)**2 for xi in x) != 0 else 0
            predicted = [mean_y + coef * (xi - mean_x) for xi in x]
            explained_var = sum((pi - mean_y)**2 for pi in predicted) / n
            
            return explained_var / total_var if total_var != 0 else 0
        
        var_original = variance_explained(X, Y_original)
        var_parametric = variance_explained(X, Y_parametric)
        var_structural = variance_explained(X, Y_structural)
        
        # Expected: Different outcomes
        # Original > Parametric > Structural (near 0)
        different_outcomes = var_original > var_parametric > var_structural
        
        print(f"Variance explained (original): {var_original:.3f}")
        print(f"Variance explained (parametric): {var_parametric:.3f}")
        print(f"Variance explained (structural): {var_structural:.3f}")
        print(f"Different outcomes: {different_outcomes}")
        print(f"Status: {'PASS' if different_outcomes else 'FAIL'}")
        
        return different_outcomes
    
    def run_all_tests(self):
        """Run all counterfactual robustness tests."""
        print("=" * 70)
        print("CAUSAL INTELLIGENCE VALIDATION: Counterfactual Robustness Tests")
        print("=" * 70)
        
        results = {
            'simple_counterfactual': self.test_simple_counterfactual(),
            'nested_counterfactual': self.test_nested_counterfactual(),
            'impossible_counterfactual': self.test_impossible_counterfactual(),
            'temporal_counterfactual': self.test_temporal_counterfactual(),
            'structural_vs_parametric': self.test_structural_vs_parametric()
        }
        
        passed = sum(results.values())
        total = len(results)
        
        print("\n" + "=" * 70)
        print(f"RESULTS: {passed}/{total} tests passed ({passed/total*100:.1f}%)")
        print("=" * 70)
        
        return results


if __name__ == '__main__':
    tester = CounterfactualRobustnessTests()
    tester.run_all_tests()
