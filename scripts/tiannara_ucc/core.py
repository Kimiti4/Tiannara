import numpy as np
import scipy.sparse as sp
import time

def extract_basin_metrics(pos, trust_matrix, agent_consumed_amt, active_triplets, target_node, n_nodes, radius=5):
    """
    Core macrostate extraction logic.
    Identifies the institutional basin around a target coordinate and extracts topological and functional metrics.
    """
    N_AGENTS = len(pos)
    
    # 1. Spatial Basin Detection
    dists = np.abs(pos - target_node)
    dists = np.minimum(dists, n_nodes - dists)
    agents_in_radius = np.where(dists <= radius)[0]
    
    if len(agents_in_radius) == 0:
        return {
            'dcr': 0.0, 'dci': 0.0, 'mean_degree': 0.0, 'scp': 0,
            'trust_centrality_global': np.zeros(N_AGENTS),
            'node_counts': np.zeros(n_nodes),
            'radius_of_gyration': 0.0,
            'spatial_entropy': 0.0,
            'redundancy': 0.0
        }
        
    n_in_radius = len(agents_in_radius)
    consumptions = agent_consumed_amt[agents_in_radius]
    
    # 2. Dynamic Caloric Retention (DCR)
    dcr = np.sum(consumptions >= 4.0) / n_in_radius
    
    # 3. Supply Chain Persistence (SCP)
    scp = 0
    agents_set = set(agents_in_radius)
    for (e, c, p_idx) in active_triplets:
        if e in agents_set and c in agents_set and p_idx in agents_set:
            scp += 1
            
    # 4. Topological Density
    sub_trust = trust_matrix[np.ix_(agents_in_radius, agents_in_radius)]
    trust_edges = (sub_trust > 1.5).astype(np.float32)
    degrees = np.sum(trust_edges, axis=1)
    mean_degree = np.mean(degrees)
    
    # 5. Distributed Caloric Inequality (DCI)
    top_20 = max(1, int(n_in_radius * 0.20))
    total_cons = np.sum(consumptions)
    dci = 0.0
    if total_cons > 0:
        dci = np.sum(np.sort(consumptions)[-top_20:]) / total_cons
        
    # 6. Global Trust Centrality (Identity of Hubs)
    trust_centrality_global = np.sum(trust_matrix > 1.5, axis=0)
    
    # 7. Spatial Distribution
    node_counts = np.bincount(pos[agents_in_radius], minlength=n_nodes)
    
    # 8. Radius of Gyration (spatial spread of the institution)
    # Using 1D periodic boundary distances from center of mass (target_node)
    rg_sq = np.sum((dists[agents_in_radius] ** 2)) / n_in_radius
    radius_of_gyration = np.sqrt(rg_sq)
    
    # 9. Spatial Entropy
    p_nodes = node_counts[node_counts > 0] / n_in_radius
    spatial_entropy = float(-np.sum(p_nodes * np.log2(p_nodes)))
    
    return {
        'dcr': float(dcr),
        'dci': float(dci),
        'mean_degree': float(mean_degree),
        'scp': int(scp),
        'trust_centrality_global': trust_centrality_global,
        'node_counts': node_counts,
        'radius_of_gyration': float(radius_of_gyration),
        'spatial_entropy': spatial_entropy,
        'redundancy': 0.0
    }

def compute_tfi(dcr, scp, dci, r, node_counts, pos, trust_matrix, target_node, n_nodes, radius=5):
    """
    Topological Functional Index (TFI)
    """
    dists = np.abs(pos - target_node)
    dists = np.minimum(dists, n_nodes - dists)
    agents_in_radius = np.where(dists <= radius)[0]
    
    if len(agents_in_radius) == 0:
        return 0.0, 0.0
        
    # Path Entropy
    degrees = np.sum(trust_matrix[np.ix_(agents_in_radius, agents_in_radius)] > 1.5, axis=1)
    d_counts = np.bincount(degrees.astype(int))
    p = d_counts[d_counts > 0] / len(agents_in_radius)
    path_entropy = float(-np.sum(p * np.log2(p)))
    
    # Congestion
    congestion = np.max(node_counts) / len(agents_in_radius)
    
    topology_quality = r / (dci + congestion + 1e-6)
    tfi = dcr * scp * topology_quality * (1.0 / (path_entropy + 1e-6))
    
    return float(tfi), float(path_entropy)

def compute_fri(dcr, scp, trust_centrality, dcr_baseline, scp_baseline, hubs_baseline):
    """
    Functional Retention Index (FRI)
    """
    dcr_ret = dcr / max(1e-6, dcr_baseline)
    scp_ret = scp / max(1e-6, scp_baseline)
    
    top_10 = max(1, int(len(trust_centrality) * 0.10))
    current_hubs = set(np.argsort(trust_centrality)[-top_10:])
    
    if len(hubs_baseline) == 0:
        lineage_ret = 1.0
    else:
        lineage_ret = len(hubs_baseline.intersection(current_hubs)) / len(hubs_baseline)
        
    fri = 0.4 * min(1.0, dcr_ret) + 0.4 * min(1.0, scp_ret) + 0.2 * lineage_ret
    return float(fri)

def compute_novelty_yield(historical_triplets, current_triplets, historical_hubs, current_hubs):
    """
    NoveltyYield = 0.4 * NewTriplets + 0.3 * NewTrustMotifs + 0.3 * NewInstitutionStates
    """
    new_triplets = len(current_triplets - historical_triplets)
    new_hubs = len(current_hubs - historical_hubs)
    
    # Simple proxies for trust motifs and institution states
    return (0.4 * new_triplets) + (0.3 * new_hubs) + (0.3 * 0.0) # Institution states handled via GIG

def compute_mci_penalties(dcr, tps, fri, agent_survival_rate):
    """
    Computes Meta-Constitutional Invariant (MCI) soft penalties.
    MCI-1: Observer Floor (Agent survival)
    MCI-2: Novelty Floor (TPS > 0)
    MCI-3: Diversity Floor (Niche balance implicit in SCP)
    MCI-4: Anti-Monopoly Floor (DCR spread)
    """
    penalty = 0.0
    if agent_survival_rate < 0.20:
        penalty += 0.50 # MCI-1 Violation
    if tps < 0.01:
        penalty += 0.10 # MCI-2 Violation
    if fri < 0.10:
        penalty += 0.30 # MCI-3 Violation
        
    return penalty
