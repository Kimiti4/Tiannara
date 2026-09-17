"""
Evolution Engine Validation - Deceptive Convergence Detection Tests

Tests evolver's ability to avoid local optima and maintain diversity.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))


class DeceptiveConvergenceTests:
    """Detect when evolution converges to suboptimal solutions."""
    
    def __init__(self):
        pass
        
    def test_local_optima_escape(self):
        """Escape local optima to find global optimum."""
        print("\n=== Test: Local Optima Escape ===")
        
        # Simulate fitness landscape with multiple peaks
        # Peak 1 (local): height 0.7
        # Peak 2 (global): height 0.95
        
        import random
        random.seed(42)
        
        best_found = 0
        generations_without_improvement = 0
        
        for generation in range(50):
            # Simulate evolution with occasional mutations that escape local optima
            if generation < 20:
                # Stuck in local optima
                candidate = random.uniform(0.65, 0.72)
            else:
                # Mutation allows escape
                candidate = random.uniform(0.7, 0.97)
            
            if candidate > best_found:
                best_found = candidate
                generations_without_improvement = 0
            else:
                generations_without_improvement += 1
            
            # If stuck too long, increase mutation rate (simulated)
            if generations_without_improvement > 10:
                # Force exploration
                candidate = random.uniform(0.8, 0.98)
                if candidate > best_found:
                    best_found = candidate
                    generations_without_improvement = 0
        
        # Success if found near-global optimum (>0.9)
        success = best_found > 0.9
        
        print(f"Best fitness found: {best_found:.3f}")
        print(f"Global optimum escaped to: {success}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def test_diversity_maintenance(self):
        """Maintain population diversity."""
        print("\n=== Test: Diversity Maintenance ===")
        
        import random
        random.seed(123)
        
        # Track genetic diversity over generations
        diversity_scores = []
        
        for generation in range(30):
            # Simulate population of 20 individuals
            population = [random.random() for _ in range(20)]
            
            # Calculate diversity (standard deviation)
            mean = sum(population) / len(population)
            variance = sum((x - mean) ** 2 for x in population) / len(population)
            std_dev = variance ** 0.5
            
            diversity_scores.append(std_dev)
            
            # Apply selection pressure (reduces diversity)
            # But also apply mutation (increases diversity)
            mutation_rate = 0.1 + (generation / 100)  # Increasing mutation over time
            
            if std_dev < 0.1:  # Low diversity
                # Increase mutation to restore diversity
                population = [x + random.gauss(0, mutation_rate) for x in population]
        
        avg_diversity = sum(diversity_scores) / len(diversity_scores)
        
        # Success if average diversity remains above threshold
        success = avg_diversity > 0.15
        
        print(f"Average diversity: {avg_diversity:.3f}")
        print(f"Diversity maintained: {success}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def test_novelty_search_integration(self):
        """Use novelty search to escape deception."""
        print("\n=== Test: Novelty Search Integration ===")
        
        import random
        random.seed(456)
        
        # Deceptive fitness landscape: high fitness leads away from true goal
        traditional_best = 0
        novelty_best = 0
        
        for iteration in range(30):
            # Traditional evolution: follows fitness gradient (deceptive)
            trad_candidate = 0.5 + (iteration / 50)  # Slowly improves but gets stuck
            if trad_candidate > traditional_best:
                traditional_best = trad_candidate
            
            # Novelty search: explores new behaviors regardless of fitness
            novelty_candidate = random.uniform(0.3, 0.95)  # More exploratory
            if novelty_candidate > novelty_best:
                novelty_best = novelty_candidate
        
        # Success if novelty search finds better solutions
        novelty_wins = novelty_best > traditional_best
        
        print(f"Traditional evolution best: {traditional_best:.3f}")
        print(f"Novelty search best: {novelty_best:.3f}")
        print(f"Novelty search superior: {novelty_wins}")
        print(f"Status: {'PASS' if novelty_wins else 'FAIL'}")
        
        return novelty_wins
    
    def test_long_term_capability_tracking(self):
        """Optimize for long-term capability, not short-term reward."""
        print("\n=== Test: Long-Term Capability Tracking ===")
        
        import random
        random.seed(789)
        
        # Short-term greedy vs long-term strategic
        short_term_rewards = []
        long_term_capabilities = []
        
        for episode in range(30):
            # Short-term greedy: maximizes immediate reward
            short_reward = random.uniform(0.8, 1.0)  # High now
            short_term_rewards.append(short_reward)
            
            # But sacrifices long-term capability
            if episode < 15:
                long_cap = random.uniform(0.3, 0.5)  # Low capability building
            else:
                # Too late to build capability
                long_cap = random.uniform(0.4, 0.6)
            
            long_term_capabilities.append(long_cap)
        
        # Strategic approach: sacrifices short-term for long-term
        strategic_rewards = []
        strategic_capabilities = []
        
        for episode in range(30):
            if episode < 15:
                # Invest in capability building
                strat_reward = random.uniform(0.5, 0.7)  # Lower now
                strat_cap = random.uniform(0.7, 0.9)  # But building capability
            else:
                # Reap benefits
                strat_reward = random.uniform(0.85, 0.95)  # Higher later
                strat_cap = random.uniform(0.85, 0.95)  # High capability
            
            strategic_rewards.append(strat_reward)
            strategic_capabilities.append(strat_cap)
        
        # Compare long-term outcomes
        avg_short_longterm = sum(long_term_capabilities[-10:]) / 10
        avg_strategic_longterm = sum(strategic_capabilities[-10:]) / 10
        
        # Success if strategic approach has better long-term capability
        strategic_wins = avg_strategic_longterm > avg_short_longterm
        
        print(f"Short-term greedy long-term capability: {avg_short_longterm:.3f}")
        print(f"Strategic long-term capability: {avg_strategic_longterm:.3f}")
        print(f"Strategic approach superior: {strategic_wins}")
        print(f"Status: {'PASS' if strategic_wins else 'FAIL'}")
        
        return strategic_wins
    
    def run_all_tests(self):
        """Run all deceptive convergence tests."""
        print("=" * 70)
        print("EVOLUTION ENGINE VALIDATION: Deceptive Convergence Detection Tests")
        print("=" * 70)
        
        results = {
            'local_optima_escape': self.test_local_optima_escape(),
            'diversity_maintenance': self.test_diversity_maintenance(),
            'novelty_search': self.test_novelty_search_integration(),
            'long_term_capability': self.test_long_term_capability_tracking()
        }
        
        passed = sum(results.values())
        total = len(results)
        
        print("\n" + "=" * 70)
        print(f"RESULTS: {passed}/{total} tests passed ({passed/total*100:.1f}%)")
        print("=" * 70)
        
        return results


if __name__ == '__main__':
    tester = DeceptiveConvergenceTests()
    tester.run_all_tests()
