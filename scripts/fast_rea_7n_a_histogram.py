import numpy as np
import scipy.sparse as sp
import time

def generate_topology(n_nodes, k_ring=10):
    rows, cols, data = [], [], []
    neighbors = np.zeros((n_nodes, k_ring), dtype=np.int32)
    weight = 0.5488 
    for i in range(n_nodes):
        idx = 0
        rows.append(i)
        cols.append(i)
        data.append(1.0)
        for offset in range(1, k_ring // 2 + 1):
            for sign in [-1, 1]:
                n = (i + sign * offset) % n_nodes
                neighbors[i, idx] = n
                idx += 1
                rows.append(i)
                cols.append(n)
                data.append(weight)
    K_csr = sp.csr_matrix((data, (rows, cols)), shape=(n_nodes, n_nodes))
    return neighbors, K_csr

def calculate_fingerprint(pos, trust_matrix, niche, ec_matrix, cp_matrix, active_triplets, center_node, radius, n_nodes):
    dists = np.abs(pos - center_node)
    dists = np.minimum(dists, n_nodes - dists)
    agents_in_radius = np.where(dists <= radius)[0]
    
    if len(agents_in_radius) == 0:
        return np.zeros(5, dtype=np.float32)
        
    n_E = np.sum(niche[agents_in_radius] == 0)
    n_C = np.sum(niche[agents_in_radius] == 1)
    n_P = np.sum(niche[agents_in_radius] == 2)
    total = n_E + n_C + n_P
    
    p = np.array([n_E, n_C, n_P], dtype=np.float32) / total
    p = p[p > 0]
    niche_entropy = -np.sum(p * np.log(p)) if len(p) > 0 else 0.0
    
    if len(agents_in_radius) > 1:
        sub_trust = trust_matrix[np.ix_(agents_in_radius, agents_in_radius)]
        average_trust = (np.sum(sub_trust) - len(agents_in_radius)) / (len(agents_in_radius) * (len(agents_in_radius) - 1))
    else:
        average_trust = 0.0
        
    ec_flow = np.sum(ec_matrix[np.ix_(agents_in_radius, agents_in_radius)])
    cp_flow = np.sum(cp_matrix[np.ix_(agents_in_radius, agents_in_radius)])
    
    local_triplets = 0
    agents_set = set(agents_in_radius)
    for (e, c, p_idx) in active_triplets:
        if e in agents_set and c in agents_set and p_idx in agents_set:
            local_triplets += 1
            
    triplet_density = local_triplets / total if total > 0 else 0.0
    
    return np.array([triplet_density, ec_flow, cp_flow, niche_entropy, average_trust], dtype=np.float32)

def cosine_similarity(v1, v2):
    dot = np.dot(v1, v2)
    mag1 = np.linalg.norm(v1)
    mag2 = np.linalg.norm(v2)
    if mag1 * mag2 == 0.0:
        return 0.0
    return dot / (mag1 * mag2)

def run_histogram_test():
    np.random.seed(42)
    
    N_NODES = 10000
    N_AGENTS = 100
    N_EPOCHS = 2000
    WALK_STEPS = 50
    RADIUS = 10
    MORTALITY_RATE = 0.0025
    MAX_PHI = 1.0
    DECAY = np.exp(-0.10)
    
    k_ring = RADIUS * 2
    neighbors, K_csr = generate_topology(N_NODES, k_ring=k_ring)
    
    niche = np.zeros(N_AGENTS, dtype=np.int32)
    niche[33:66] = 1 
    niche[66:] = 2   
    
    target_trace = np.zeros(N_AGENTS, dtype=np.int32)
    target_trace[niche == 0] = 0
    target_trace[niche == 1] = 0
    target_trace[niche == 2] = 1
    emit_trace = np.copy(niche)
    
    pos = np.random.randint(0, N_NODES, size=N_AGENTS)
    trust_matrix = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S = np.zeros((3, N_NODES, N_AGENTS), dtype=np.float32)
    last_consumed_from = np.full(N_AGENTS, -1, dtype=np.int32)
    active_triplets = set()
    
    S_ema = np.zeros((3, N_NODES), dtype=np.float32)
    S_variance = np.zeros((3, N_NODES), dtype=np.float32)
    S_flux_ema = np.zeros((3, N_NODES), dtype=np.float32)
    S_old_collapsed = np.zeros((3, N_NODES), dtype=np.float32)
    
    alpha_ema = 0.01
    STABILITY_THRESHOLD = 0.5
    VOLATILITY_TOLERANCE = 0.5
    FLUX_THRESHOLD = 0.1
    
    basin_presence = np.zeros(N_NODES, dtype=np.int32)
    basin_absence = np.zeros(N_NODES, dtype=np.int32)
    
    # Internal BasinTracker State
    ghosts = {}  # id -> {node, age, fp, death_epoch}
    active_lineages = {} # node -> {id, age, fp}
    lineage_counter = 0
    
    similarity_histogram = {
        "0.95-1.00": 0,
        "0.90-0.95": 0,
        "0.85-0.90": 0,
        "0.80-0.85": 0,
        "0.70-0.80": 0,
        "<0.70": 0
    }
    
    print(f"🌌 [REA-7N-A] Booting Local Lineage Stitching Histogram Test...")
    start_time = time.time()
    
    for epoch in range(1, N_EPOCHS + 1):
        E = np.zeros((3, N_NODES, N_AGENTS), dtype=np.float32)
        agent_consumed_amt = np.zeros(N_AGENTS, dtype=np.float32)
        ec_matrix = np.zeros((N_AGENTS, N_AGENTS), dtype=np.float32)
        cp_matrix = np.zeros((N_AGENTS, N_AGENTS), dtype=np.float32)
        active_triplets.clear()
        
        for step in range(WALK_STEPS):
            cands = neighbors[pos]
            T = S[target_trace[:, None], cands, :]
            W = trust_matrix[:, None, :]
            Phi = np.sum(T * W, axis=2)
            noise = np.random.uniform(0, 0.05, size=Phi.shape)
            best_idx = np.argmax(Phi + noise, axis=1)
            pos = cands[np.arange(N_AGENTS), best_idx]
            
            agent_order = np.random.permutation(N_AGENTS)
            for a in agent_order:
                n_id = pos[a]
                t_target = target_trace[a]
                available = S[t_target, n_id, :]
                authors_with_traces = np.where(available > 0.001)[0]
                if len(authors_with_traces) == 0: continue
                
                required = 5.0 - agent_consumed_amt[a]
                if required <= 0: continue
                
                intensities = available[authors_with_traces]
                sorted_authors = authors_with_traces[np.argsort(-intensities)]
                
                for author in sorted_authors:
                    if required <= 0: break
                    amt = available[author]
                    if amt == 0: continue
                    take = min(amt, required)
                    available[author] -= take
                    required -= take
                    agent_consumed_amt[a] += take
                    if author != a:
                        trust_matrix[a, author] = min(5.0, trust_matrix[a, author] + 0.1)
                        last_consumed_from[a] = author
                        if niche[a] == 1 and niche[author] == 0:
                            ec_matrix[a, author] += take
                        if niche[a] == 2 and niche[author] == 1:
                            cp_matrix[a, author] += take
                            e_author = last_consumed_from[author]
                            if e_author != -1 and niche[e_author] == 0:
                                active_triplets.add((e_author, author, a))
                S[t_target, n_id, :] = available
            E[emit_trace, pos, np.arange(N_AGENTS)] += 2.5
            
        E_flat = E.transpose(1, 0, 2).reshape(N_NODES, -1)
        S_flat = S.transpose(1, 0, 2).reshape(N_NODES, -1)
        S_new_flat = S_flat * DECAY + K_csr.dot(E_flat)
        S_new_flat = np.clip(S_new_flat, 0.0, MAX_PHI)
        S = S_new_flat.reshape(N_NODES, 3, N_AGENTS).transpose(1, 0, 2)
        trust_matrix = np.maximum(1.0, trust_matrix * 0.99)
        
        dead_agents = np.where(np.random.rand(N_AGENTS) < MORTALITY_RATE)[0]
        for a in dead_agents:
            pos[a] = pos[a] 
            trust_matrix[a, :] = 1.0 
            last_consumed_from[a] = -1
            
        S_sum = np.sum(S, axis=2) 
        S_ema = (1 - alpha_ema) * S_ema + alpha_ema * S_sum
        S_variance = (1 - alpha_ema) * S_variance + alpha_ema * (S_sum - S_ema)**2
        S_flux = np.abs(S_sum - S_old_collapsed)
        S_flux_ema = (1 - alpha_ema) * S_flux_ema + alpha_ema * S_flux
        S_old_collapsed = np.copy(S_sum)
        
        stable_mask = (S_ema > STABILITY_THRESHOLD) & (S_variance < VOLATILITY_TOLERANCE) & (S_flux_ema < FLUX_THRESHOLD)
        stable_nodes = np.unique(np.where(stable_mask)[1])
        all_nodes = np.arange(N_NODES)
        absent_nodes = np.setdiff1d(all_nodes, stable_nodes)
        new_basins = (basin_presence == 0) & (np.isin(all_nodes, stable_nodes))
        
        basin_presence[stable_nodes] += 1
        basin_absence[stable_nodes] = 0
        basin_absence[absent_nodes] += 1
        dead_basins_mask = (basin_presence > 0) & (basin_absence > 50)
        
        # Prune ghosts
        keys_to_del = [g_id for g_id, g in ghosts.items() if (epoch - g['death_epoch']) > 50]
        for k in keys_to_del: del ghosts[k]
        
        # Handle Basin Birth (Stitching Test)
        for node in np.where(new_basins)[0]:
            fp = calculate_fingerprint(pos, trust_matrix, niche, ec_matrix, cp_matrix, active_triplets, node, RADIUS, N_NODES)
            
            # Find ghosts in radius 25
            cands = []
            for g_id, g in ghosts.items():
                dist = abs(g['node'] - node)
                dist = min(dist, N_NODES - dist)
                if dist <= 25:
                    cands.append((g_id, g))
                    
            best_match_id = None
            best_match_ghost = None
            
            for g_id, g in cands:
                sim = cosine_similarity(g['fp'], fp)
                
                if sim >= 0.95: similarity_histogram["0.95-1.00"] += 1
                elif sim >= 0.90: similarity_histogram["0.90-0.95"] += 1
                elif sim >= 0.85: similarity_histogram["0.85-0.90"] += 1
                elif sim >= 0.80: similarity_histogram["0.80-0.85"] += 1
                elif sim >= 0.70: similarity_histogram["0.70-0.80"] += 1
                else: similarity_histogram["<0.70"] += 1
                
                # We stitch the strongest > 0.85
                if sim >= 0.85:
                    if best_match_ghost is None or sim > best_match_ghost['sim']:
                        best_match_id = g_id
                        best_match_ghost = g
                        best_match_ghost['sim'] = sim
                        
            if best_match_id is not None:
                del ghosts[best_match_id]
                active_lineages[node] = {'id': best_match_id, 'age': best_match_ghost['age'], 'fp': fp}
            else:
                lineage_counter += 1
                l_id = f"L_{lineage_counter}"
                active_lineages[node] = {'id': l_id, 'age': 1, 'fp': fp}

        # Update active lineages
        update_mask = (basin_presence > 0) & (basin_presence % 50 == 0) & (basin_absence == 0)
        for node in np.where(update_mask)[0]:
            if node in active_lineages:
                fp = calculate_fingerprint(pos, trust_matrix, niche, ec_matrix, cp_matrix, active_triplets, node, RADIUS, N_NODES)
                active_lineages[node]['age'] += 50
                active_lineages[node]['fp'] = fp
                
        # Handle deaths
        for node in np.where(dead_basins_mask)[0]:
            if node in active_lineages:
                l_info = active_lineages.pop(node)
                ghosts[l_info['id']] = {'node': node, 'age': l_info['age'], 'fp': l_info['fp'], 'death_epoch': epoch}
                
        basin_presence[dead_basins_mask] = 0
        
        if epoch % 200 == 0:
            print(f"Epoch {epoch} | Active Lineages: {len(active_lineages)} | Stitches Attempted: {sum(similarity_histogram.values())}", flush=True)

    print(f"\\n--- REA-7N-A Similarity Histogram Report ---")
    total = sum(similarity_histogram.values())
    print(f"Total Stitches Evaluated: {total}")
    if total > 0:
        for k, v in similarity_histogram.items():
            print(f"  {k}: {v} ({v/total*100:.1f}%)")
    else:
        print("No stitches were evaluated (no overlapping ghost encounters).")
        
    print(f"\\nSimulation completed in {time.time() - start_time:.2f} seconds")

if __name__ == "__main__":
    run_histogram_test()
