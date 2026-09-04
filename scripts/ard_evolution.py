import json
import numpy as np

class AdaptationGenome:
    def __init__(self, recoverability_weights=None, regime_weights=None):
        # 10D Telemetry -> 1D Recoverability
        self.w_rec = recoverability_weights if recoverability_weights is not None else np.random.randn(10)
        # 10D Telemetry -> 4D Regimes
        self.w_reg = regime_weights if regime_weights is not None else np.random.randn(4, 10)
        self.fitness = 0.0

    def predict(self, telemetry_vector):
        x = np.array(list(telemetry_vector.values()))
        
        # Stage 1: Recoverability (Sigmoid bounds it 0.0 -> 1.0)
        raw_rec = np.dot(self.w_rec, x)
        pred_rec = 1.0 / (1.0 + np.exp(-raw_rec))
        
        # Stage 2: Regimes (Softmax for mixture)
        raw_reg = np.dot(self.w_reg, x)
        exp_reg = np.exp(raw_reg - np.max(raw_reg))
        pred_intensities = exp_reg / np.sum(exp_reg)
        
        return pred_rec, pred_intensities

    def mutate(self, mutation_rate=0.1, mutation_scale=0.2):
        new_w_rec = self.w_rec.copy()
        new_w_reg = self.w_reg.copy()
        
        if np.random.rand() < mutation_rate:
            new_w_rec += np.random.randn(10) * mutation_scale
            
        for i in range(4):
            for j in range(10):
                if np.random.rand() < mutation_rate:
                    new_w_reg[i, j] += np.random.randn() * mutation_scale
                    
        return AdaptationGenome(new_w_rec, new_w_reg)

def load_archive():
    with open('data/archive/rea_trajectories.json', 'r') as f:
        return json.load(f)

def evaluate_genome(genome, archive):
    total_score = 0.0
    
    for record in archive:
        true_rec = record['recoverability']
        
        pred_rec, pred_int = genome.predict(record['telemetry'])
        
        # Interpolate outcome surface
        fri = 0.0
        novelty = 0.0
        regimes = ['preserve', 'repair', 'explore', 'triage']
        for i, reg in enumerate(regimes):
            fri += pred_int[i] * record['outcomes'][reg]['fri']
            novelty += pred_int[i] * record['outcomes'][reg]['novelty']
            
        # Recoverability Head Penalty (MSE)
        rec_error = (pred_rec - true_rec) ** 2
        
        # Calculate Meta-Fitness
        raw_fitness = 0.35 * fri + 0.25 * (novelty / max(1.0, novelty + 10.0))
        # Simple control volatility proxy: higher triage/explore weights = higher volatility
        control_volatility = (pred_int[2] + pred_int[3]) * 0.20 
        
        # Genome Score
        score = (raw_fitness - control_volatility) * (1.0 / max(0.1, true_rec))
        
        # Deduct error in predicting recoverability
        score -= rec_error * 2.0 
        
        total_score += score
        
    return total_score

def crossover(g1, g2):
    w_rec = np.where(np.random.rand(10) > 0.5, g1.w_rec, g2.w_rec)
    w_reg = np.where(np.random.rand(4, 10) > 0.5, g1.w_reg, g2.w_reg)
    return AdaptationGenome(w_rec, w_reg)

def evolve_ard(generations=1000, pop_size=100):
    archive = load_archive()
    print(f"🌌 Launching ARD Evolution over {len(archive)} causal trajectory blocks...")
    
    population = [AdaptationGenome() for _ in range(pop_size)]
    
    best_genome = None
    best_fitness = -float('inf')
    
    for gen in range(generations):
        for g in population:
            g.fitness = evaluate_genome(g, archive)
            
        population.sort(key=lambda x: x.fitness, reverse=True)
        
        if population[0].fitness > best_fitness:
            best_fitness = population[0].fitness
            best_genome = population[0]
            
        if gen % 100 == 0:
            print(f"Generation {gen:04d} | Best Fitness: {best_fitness:.3f}")
            
        # Elitism
        next_pop = [population[0], population[1]]
        
        # Tournament Selection
        while len(next_pop) < pop_size:
            p1 = population[np.random.randint(0, pop_size//2)]
            p2 = population[np.random.randint(0, pop_size//2)]
            child = crossover(p1, p2)
            child = child.mutate()
            next_pop.append(child)
            
        population = next_pop
        
    print(f"\n✅ ARD Evolution Complete. Final Fitness: {best_fitness:.3f}")
    
    # Save the apex genome
    with open('data/apex_adaptation_genome.json', 'w') as f:
        json.dump({
            'recoverability_weights': best_genome.w_rec.tolist(),
            'regime_weights': best_genome.w_reg.tolist()
        }, f, indent=2)

if __name__ == "__main__":
    evolve_ard()
