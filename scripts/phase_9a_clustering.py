import json
import numpy as np
import os

def load_archive():
    archive_path = 'data/archive/rea_trajectories.json'
    if not os.path.exists(archive_path):
        print(f"Archive not found at {archive_path}")
        return []
    with open(archive_path, 'r') as f:
        return json.load(f)

def run_kmeans(X, k=5, max_iters=100):
    np.random.seed(42)
    # Initialize centroids randomly from data points
    centroids = X[np.random.choice(X.shape[0], k, replace=False)]
    
    for _ in range(max_iters):
        distances = np.linalg.norm(X[:, np.newaxis] - centroids, axis=2)
        labels = np.argmin(distances, axis=1)
        
        new_centroids = np.array([
            X[labels == i].mean(axis=0) if np.sum(labels == i) > 0 else centroids[i] 
            for i in range(k)
        ])
        
        if np.allclose(centroids, new_centroids):
            break
        centroids = new_centroids
        
    return labels, centroids

def cluster_adaptation_space():
    archive = load_archive()
    if not archive:
        return
        
    print(f"🌌 [Phase 9A] Clustering {len(archive)} Reachability Trajectories...")
    
    features = [
        'dcr_retention', 'scp_retention', 'mortality_rate', 'niche_skew',
        'trust_centralization_delta', 'path_entropy_delta', 'redundancy_delta',
        'novelty_rate', 'adaptation_velocity', 'control_effort_gradient'
    ]
    
    X_list = []
    recoverabilities = []
    
    for record in archive:
        vec = [record['telemetry'][f] for f in features]
        X_list.append(vec)
        recoverabilities.append(record.get('recoverability', 0.0))
        
    X = np.array(X_list)
    rec_arr = np.array(recoverabilities)
    
    # Normalize features for K-Means (Z-score)
    X_mean = X.mean(axis=0)
    X_std = X.std(axis=0) + 1e-8
    X_norm = (X - X_mean) / X_std
    
    # We hypothesize 4-6 archetypes. Let's run k=5
    k = 5
    labels, centroids_norm = run_kmeans(X_norm, k=k)
    
    # Un-normalize centroids for readability
    centroids = (centroids_norm * X_std) + X_mean
    
    print("\n========================================================")
    print("Discovered Adaptation Attractors (k=5)")
    print("========================================================")
    
    archetypes = ['Archetype A', 'Archetype B', 'Archetype C', 'Archetype D', 'Archetype E']
    
    for i in range(k):
        cluster_idx = np.where(labels == i)[0]
        size = len(cluster_idx)
        if size == 0:
            continue
            
        mean_rec = rec_arr[cluster_idx].mean()
        
        print(f"\n[{archetypes[i]}] (Size: {size} states | Avg Recoverability: {mean_rec:.3f})")
        print("Centroid Telemetry:")
        for j, f in enumerate(features):
            val = centroids[i, j]
            # Highlight extreme values (more than 1 standard deviation from global mean)
            std_diff = (val - X_mean[j]) / X_std[j]
            marker = "+++" if std_diff > 1.0 else "---" if std_diff < -1.0 else "   "
            print(f"  {marker} {f:<30}: {val:8.3f}")

if __name__ == "__main__":
    cluster_adaptation_space()
