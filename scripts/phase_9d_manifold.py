import json
import numpy as np

def load_archive():
    with open('data/archive/rea_trajectories.json', 'r') as f:
        return json.load(f)

def load_apex_genome():
    with open('data/apex_adaptation_genome.json', 'r') as f:
        return json.load(f)

def predict_regimes(telemetry, genome):
    features = ['dcr_retention', 'scp_retention', 'mortality_rate', 'niche_skew',
                'trust_centralization_delta', 'path_entropy_delta', 'redundancy_delta',
                'novelty_rate', 'adaptation_velocity', 'control_effort_gradient']
                
    x = np.array([telemetry[f] for f in features])
    w_reg = np.array(genome['regime_weights'])
    
    raw_reg = np.dot(w_reg, x)
    exp_reg = np.exp(raw_reg - np.max(raw_reg))
    return exp_reg / np.sum(exp_reg)

def map_manifold():
    archive = load_archive()
    genome = load_apex_genome()
    
    features = ['dcr_retention', 'scp_retention', 'mortality_rate', 'niche_skew',
                'trust_centralization_delta', 'path_entropy_delta', 'redundancy_delta',
                'novelty_rate', 'adaptation_velocity', 'control_effort_gradient']
                
    X_list = []
    for record in archive:
        X_list.append([record['telemetry'][f] for f in features])
    X = np.array(X_list)
    
    # Re-run kmeans to get cluster labels
    np.random.seed(42)
    k = 5
    X_norm = (X - X.mean(axis=0)) / (X.std(axis=0) + 1e-8)
    centroids = X_norm[np.random.choice(X_norm.shape[0], k, replace=False)]
    for _ in range(100):
        distances = np.linalg.norm(X_norm[:, np.newaxis] - centroids, axis=2)
        labels = np.argmin(distances, axis=1)
        new_centroids = np.array([X_norm[labels == i].mean(axis=0) if np.sum(labels == i) > 0 else centroids[i] for i in range(k)])
        if np.allclose(centroids, new_centroids): break
        centroids = new_centroids
        
    archetypes = {
        0: "Rigid / Stable",
        1: "Brittle / Near-Dead Zone",
        2: "Plastic / Regenerative",
        3: "Explosive",
        4: "Zombie / Dead Zone"
    }
    
    # Mapping discrete regimes to implicit parameter coordinates based on REA-7O
    # Preserve -> High gamma, low tau
    # Repair -> High alpha, High rho
    # Explore -> High tau, low gamma
    # Triage -> Low gamma, Low alpha
    
    print("\n========================================================")
    print("Phase 9D: Constraint Manifold Coordinates")
    print("========================================================")
    
    regimes = ['Preserve', 'Repair', 'Explore', 'Triage']
    
    for i in range(k):
        cluster_idx = np.where(labels == i)[0]
        if len(cluster_idx) == 0: continue
        
        cluster_intensities = []
        for idx in cluster_idx:
            intensities = predict_regimes(archive[idx]['telemetry'], genome)
            cluster_intensities.append(intensities)
            
        mean_intensities = np.mean(cluster_intensities, axis=0)
        
        # Derive conceptual coordinates
        # gamma (Persistence) = Preserve - Explore - Triage
        gamma = mean_intensities[0] - mean_intensities[2] - mean_intensities[3]
        # tau (Exploration) = Explore - Preserve
        tau = mean_intensities[2] - mean_intensities[0]
        # alpha (Plasticity) = Repair + Explore
        alpha = mean_intensities[1] + mean_intensities[2]
        
        print(f"\n[{archetypes[i]}]")
        print(f"Optimal Regime Mixture : " + " | ".join([f"{regimes[j]}: {mean_intensities[j]:.2f}" for j in range(4)]))
        
        coord = []
        coord.append("High γ" if gamma > 0.3 else "Low γ" if gamma < -0.3 else "Medium γ")
        coord.append("High τ" if tau > 0.3 else "Low τ" if tau < -0.3 else "Medium τ")
        coord.append("High α" if alpha > 0.6 else "Low α" if alpha < 0.3 else "Medium α")
        
        print(f"Constitutional Manifold: {', '.join(coord)}")

if __name__ == "__main__":
    map_manifold()
