import numpy as np
import scipy.sparse as sp
from scipy.sparse.csgraph import connected_components
import time
import multiprocessing
import csv
import os

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

def run_condition(params):
    n_nodes, walk_steps, radius = params
    np.random.seed(42 + int(n_nodes % 100) + walk_steps + radius)
    
    N_AGENTS = 100
    N_EPOCHS = 500
    MORTALITY_RATE = 0.0025
    MAX_PHI = 1.0
    DECAY = np.exp(-0.10)
    
    k_ring = radius * 2
    neighbors, K_csr = generate_topology(n_nodes, k_ring=k_ring)
    
    niche = np.zeros(N_AGENTS, dtype=np.int32)
    niche[33:66] = 1 # 33 Compressors
    niche[66:] = 2   # 34 Predictors
    
    target_trace = np.zeros(N_AGENTS, dtype=np.int32)
    target_trace[niche == 0] = 0
    target_trace[niche == 1] = 0
    target_trace[niche == 2] = 1
    emit_trace = np.copy(niche)
    
    pos = np.random.randint(0, n_nodes, size=N_AGENTS)
    trust_matrix = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S = np.zeros((3, n_nodes, N_AGENTS), dtype=np.float32)
    
    last_consumed_from = np.full(N_AGENTS, -1, dtype=np.int32)
    active_triplets = {}
    
    agent_dead_since = np.full(N_AGENTS, -1, dtype=np.int32)
    
    total_EC_encounters = 0
    total_CP_encounters = 0
    
    edd_history = []
    cnf_history = []
    lcc_sizes = []
    ncc_sizes = []
    
    ttc = -1
    
    for epoch in range(1, N_EPOCHS + 1):
        E = np.zeros((3, n_nodes, N_AGENTS), dtype=np.float32)
        
        satisfied_heterotrophs = 0
        total_heterotrophs = 67
        
        agent_consumed_amt = np.zeros(N_AGENTS, dtype=np.float32)
        
        for step in range(walk_steps):
            if k_ring > 0:
                cands = neighbors[pos]
            else:
                cands = pos[:, None] 
                
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
                            total_EC_encounters += 1
                        if niche[a] == 2 and niche[author] == 1:
                            total_CP_encounters += 1
                        
                        if niche[a] == 2 and niche[author] == 1:
                            e_author = last_consumed_from[author]
                            if e_author != -1 and niche[e_author] == 0:
                                triplet = (e_author, author, a)
                                if triplet not in active_triplets:
                                    active_triplets[triplet] = {'first': epoch, 'last': epoch}
                                active_triplets[triplet]['last'] = epoch
                                
                S[t_target, n_id, :] = available
            
            drop_amt = 2.5
            E[emit_trace, pos, np.arange(N_AGENTS)] += drop_amt
            
        satisfied_heterotrophs = np.sum(agent_consumed_amt[niche > 0] >= 4.99)
        edd = satisfied_heterotrophs / total_heterotrophs
        edd_history.append(edd)
        
        if edd < 0.5 and ttc == -1:
            ttc = epoch
        
        cnf = np.sum(agent_consumed_amt > 0) / N_AGENTS
        cnf_history.append(cnf)
        
        E_flat = E.transpose(1, 0, 2).reshape(n_nodes, -1)
        S_flat = S.transpose(1, 0, 2).reshape(n_nodes, -1)
        S_new_flat = S_flat * DECAY + K_csr.dot(E_flat)
        S_new_flat = np.clip(S_new_flat, 0.0, MAX_PHI)
        S = S_new_flat.reshape(n_nodes, 3, N_AGENTS).transpose(1, 0, 2)
        
        trust_matrix = np.maximum(1.0, trust_matrix * 0.99)
        
        adj = np.zeros((N_AGENTS, N_AGENTS), dtype=np.int32)
        for triplet, data in active_triplets.items():
            if data['last'] >= epoch - 1:
                adj[triplet[0], triplet[1]] = 1
                adj[triplet[1], triplet[0]] = 1
                adj[triplet[1], triplet[2]] = 1
                adj[triplet[2], triplet[1]] = 1
                
        n_components, labels = connected_components(csgraph=sp.csr_matrix(adj), directed=False, return_labels=True)
        ncc_sizes.append(n_components)
        if n_components > 0:
            unique, counts = np.unique(labels, return_counts=True)
            lcc_sizes.append(np.max(counts))
        else:
            lcc_sizes.append(0)
            
        dead_agents = np.where(np.random.rand(N_AGENTS) < MORTALITY_RATE)[0]
        for a in dead_agents:
            pos[a] = pos[a] 
            trust_matrix[a, :] = 1.0 
            last_consumed_from[a] = -1
            agent_dead_since[a] = epoch
            
    lam_ec = total_EC_encounters / (33 * N_EPOCHS)
    lam_cp = total_CP_encounters / (34 * N_EPOCHS)
    mean_edd = np.mean(edd_history)
    mean_cnf = np.mean(cnf_history)
    mean_lcc = np.mean(lcc_sizes)
    mean_ncc = np.mean(ncc_sizes)
    scp = np.mean([t['last'] - t['first'] for t in active_triplets.values()]) if len(active_triplets) > 0 else 0.0
    
    return [n_nodes, walk_steps, radius, lam_ec, lam_cp, mean_edd, ttc, mean_cnf, mean_lcc, mean_ncc, scp]

if __name__ == "__main__":
    n_nodes_list = [1000, 10000, 100000, 1000000]
    walk_steps_list = [50, 20, 10, 5, 1]
    radius_list = [1, 3, 5, 10]
    
    params_list = [(n, w, r) for n in n_nodes_list for w in walk_steps_list for r in radius_list]
    
    print(f"🌌 [REA-7M Python Engine] Booting 80-Condition Sweep with TTC and Fragmentation...")
    
    pool_size = min(4, multiprocessing.cpu_count())
    
    start_time = time.time()
    
    artifact_dir = r"C:\Users\user\.gemini\antigravity-ide\brain\4f44a4dd-4439-4e47-9ab1-a3e3778b44dd"
    csv_path = os.path.join(artifact_dir, "rea_7m_phase_space.csv")
    
    with open(csv_path, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["N_NODES", "WALK_STEPS", "SENSING_RADIUS", "Lam_EC", "Lam_CP", "EDD", "TTC", "CNF", "Mean_LCC", "Mean_NCC", "SCP"])
        
        with multiprocessing.Pool(pool_size) as pool:
            for i, res in enumerate(pool.imap_unordered(run_condition, params_list), 1):
                writer.writerow(res)
                f.flush()
                # Use string formatting to handle TTC which could be -1
                ttc_str = f"{res[6]}" if res[6] != -1 else "Inf"
                print(f"[{i}/80] N:{res[0]} Stp:{res[1]} Rad:{res[2]} | LEC={res[3]:.2f} LCP={res[4]:.2f} TTC={ttc_str} NCC={res[9]:.1f}")
                
    print(f"\nSweep completed in {time.time() - start_time:.2f} seconds.")
    print(f"Data written to {csv_path}")
