import json
import numpy as np

def load_archive():
    with open('data/archive/rea_trajectories.json', 'r') as f:
        return json.load(f)

def run_kmeans(X, k=5, max_iters=100):
    np.random.seed(42)
    centroids = X[np.random.choice(X.shape[0], k, replace=False)]
    for _ in range(max_iters):
        distances = np.linalg.norm(X[:, np.newaxis] - centroids, axis=2)
        labels = np.argmin(distances, axis=1)
        new_centroids = np.array([X[labels == i].mean(axis=0) if np.sum(labels == i) > 0 else centroids[i] for i in range(k)])
        if np.allclose(centroids, new_centroids): break
        centroids = new_centroids
    return labels

def analyze_curvature():
    archive = load_archive()
    
    features = ['dcr_retention', 'scp_retention', 'mortality_rate', 'niche_skew',
                'trust_centralization_delta', 'path_entropy_delta', 'redundancy_delta',
                'novelty_rate', 'adaptation_velocity', 'control_effort_gradient']
                
    X_list = []
    for record in archive:
        X_list.append([record['telemetry'][f] for f in features])
    X = np.array(X_list)
    
    # Re-run kmeans to get cluster labels
    X_norm = (X - X.mean(axis=0)) / (X.std(axis=0) + 1e-8)
    labels = run_kmeans(X_norm, k=5)
    
    archetypes = {
        0: "Rigid / Stable",
        1: "Brittle / Near-Dead Zone",
        2: "Plastic / Regenerative",
        3: "Explosive",
        4: "Zombie / Dead Zone"
    }
    
    print("\n========================================================")
    print("Phase 9E: Adaptation Curvature & Adaptive Elasticity (AE)")
    print("========================================================")
    
    for i in range(5):
        cluster_idx = np.where(labels == i)[0]
        if len(cluster_idx) == 0: continue
        
        ae_scores = []
        friction_scores = []
        
        for idx in cluster_idx:
            record = archive[idx]
            outcomes = record['outcomes']
            
            # Baseline: "Do nothing" (Preserve)
            baseline_fri = outcomes['preserve']['fri']
            
            # Active Interventions
            active_fris = [outcomes['repair']['fri'], outcomes['explore']['fri'], outcomes['triage']['fri']]
            max_active_fri = max(active_fris)
            
            # Adaptive Elasticity (AE): How much recoverability is gained by intervening instead of preserving?
            ae = max_active_fri - baseline_fri
            
            # If AE < 0, intervention causes friction.
            if ae < 0:
                friction_scores.append(abs(ae))
                ae_scores.append(0.0)
            else:
                friction_scores.append(0.0)
                ae_scores.append(ae)
                
        mean_ae = np.mean(ae_scores)
        mean_friction = np.mean(friction_scores)
        
        print(f"\n[{archetypes[i]}]")
        print(f"Mean Adaptive Elasticity (AE) : {mean_ae:8.3f}")
        print(f"Mean Intervention Friction    : {mean_friction:8.3f}")
        
        if mean_ae > 0.1:
            print("Curvature: ELASTIC (Intervention yields massive gains)")
        elif mean_ae > 0.0:
            print("Curvature: INELASTIC (Intervention yields marginal gains)")
        else:
            print("Curvature: TRAP (Intervention actively damages the system)")

if __name__ == "__main__":
    analyze_curvature()
