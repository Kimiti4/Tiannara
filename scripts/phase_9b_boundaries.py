import json
import numpy as np
import os

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
        if np.allclose(centroids, new_centroids):
            break
        centroids = new_centroids
    return labels

def find_best_split(X, y, feature_names):
    # Depth 1 Decision Stump
    best_acc = 0
    best_rule = ""
    best_mask_left = None
    best_mask_right = None
    
    n_features = X.shape[1]
    for i in range(n_features):
        thresholds = np.unique(X[:, i])
        for t in thresholds:
            # Left branch (<= t) predicts class 1
            pred = (X[:, i] <= t).astype(int)
            acc = np.mean(pred == y)
            if acc > best_acc:
                best_acc = acc
                best_rule = f"{feature_names[i]} <= {t:.3f}"
                best_mask_left = (X[:, i] <= t)
                best_mask_right = (X[:, i] > t)
                
            # Right branch (> t) predicts class 1
            pred = (X[:, i] > t).astype(int)
            acc = np.mean(pred == y)
            if acc > best_acc:
                best_acc = acc
                best_rule = f"{feature_names[i]} > {t:.3f}"
                best_mask_left = (X[:, i] > t)
                best_mask_right = (X[:, i] <= t)
                
    return best_rule, best_acc, best_mask_left, best_mask_right

def extract_boundary(name, X, y, feature_names):
    print(f"\n========================================================")
    print(f"Extracting Laws for: {name}")
    print(f"========================================================")
    
    # Try finding a simple 2-depth rule
    rule1, acc1, mask_L1, mask_R1 = find_best_split(X, y, feature_names)
    
    if acc1 == 1.0:
        print(f"LAW: IF {rule1} -> Target Attractor (Accuracy: 100%)")
        return
        
    # If not 100%, split again on the subset that failed
    # Find secondary split for the branch that predicts 1 (Target)
    X_sub = X[mask_L1]
    y_sub = y[mask_L1]
    if len(np.unique(y_sub)) > 1:
        rule2, acc2, _, _ = find_best_split(X_sub, y_sub, feature_names)
        print(f"LAW: IF ({rule1}) AND ({rule2}) -> Target Attractor")
        # Calc combined accuracy
        pred = np.zeros_like(y)
        # Apply composite rule
        # Parse rules roughly
        def eval_rule(r, x_data):
            feat_idx = feature_names.index(r.split(' ')[0])
            op = r.split(' ')[1]
            val = float(r.split(' ')[2])
            if op == '<=': return x_data[:, feat_idx] <= val
            else: return x_data[:, feat_idx] > val
            
        m1 = eval_rule(rule1, X)
        m2 = eval_rule(rule2, X)
        pred[m1 & m2] = 1
        final_acc = np.mean(pred == y)
        print(f"     (Composite Accuracy: {final_acc*100:.1f}%)")
    else:
        print(f"LAW: IF {rule1} -> Target Attractor (Accuracy: {acc1*100:.1f}%)")


def run_phase_9b():
    archive = load_archive()
    features = ['dcr_retention', 'scp_retention', 'mortality_rate', 'niche_skew',
                'trust_centralization_delta', 'path_entropy_delta', 'redundancy_delta',
                'novelty_rate', 'adaptation_velocity', 'control_effort_gradient']
                
    X_list = []
    for record in archive:
        X_list.append([record['telemetry'][f] for f in features])
    X = np.array(X_list)
    
    X_norm = (X - X.mean(axis=0)) / (X.std(axis=0) + 1e-8)
    labels = run_kmeans(X_norm, k=5)
    
    # Archetype indices (based on Phase 9A outputs)
    # 0 = Rigid (Healthy)
    # 1 = Brittle
    # 2 = Plastic/Regenerative
    # 3 = Explosive
    # 4 = Zombie
    
    healthy_idx = 0
    brittle_idx = 1
    plastic_idx = 2
    zombie_idx = 4
    
    # Boundary 1: Healthy <-> Brittle
    # Target = Brittle (1), Healthy = 0
    mask_1 = (labels == healthy_idx) | (labels == brittle_idx)
    X_1 = X[mask_1]
    y_1 = (labels[mask_1] == brittle_idx).astype(int)
    extract_boundary("Healthy vs Brittle (Collapse Boundary)", X_1, y_1, features)
    
    # Boundary 2: Brittle <-> Zombie
    # Target = Zombie (1), Brittle = 0
    mask_2 = (labels == brittle_idx) | (labels == zombie_idx)
    X_2 = X[mask_2]
    y_2 = (labels[mask_2] == zombie_idx).astype(int)
    extract_boundary("Brittle vs Zombie (Terminal Boundary)", X_2, y_2, features)
    
    # Boundary 3: Brittle <-> Plastic
    # Target = Plastic (1), Brittle = 0
    mask_3 = (labels == brittle_idx) | (labels == plastic_idx)
    X_3 = X[mask_3]
    y_3 = (labels[mask_3] == plastic_idx).astype(int)
    extract_boundary("Brittle vs Plastic (Regenerative Boundary)", X_3, y_3, features)

if __name__ == "__main__":
    print("🌌 [Phase 9B] Discovering Dead Zone Boundaries and Adaptation Laws...")
    run_phase_9b()
