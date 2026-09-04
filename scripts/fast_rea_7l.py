import numpy as np
import scipy.sparse as sp
from scipy.sparse.csgraph import connected_components
import time
import multiprocessing

def generate_topology(n_nodes, k_ring=10, radius_0=False):
    rows, cols, data = [], [], []
    neighbors = np.zeros((n_nodes, k_ring), dtype=np.int32)
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
                if not radius_0:
                    rows.append(i)
                    cols.append(n)
                    data.append(0.5488)
    if radius_0:
        K_csr = sp.eye(n_nodes, format='csr')
    else:
        K_csr = sp.csr_matrix((data, (rows, cols)), shape=(n_nodes, n_nodes))
    return neighbors, K_csr

def run_condition(cond):
    np.random.seed(42 + ord(cond[-1]))
    N_NODES = 1000
    N_AGENTS = 100
    N_EPOCHS = 2000
    WALK_STEPS = 50
    MORTALITY_RATE = 0.0025
    MAX_PHI = 1.0
    
    if cond == 'L2':
        DECAY = 0.0
        neighbors, K_csr = generate_topology(N_NODES, radius_0=True)
    else:
        DECAY = np.exp(-0.10)
        neighbors, K_csr = generate_topology(N_NODES, radius_0=False)
        
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
    active_triplets = {}
    
    deaths = 0
    recovery_times = []
    agent_dead_since = np.full(N_AGENTS, -1, dtype=np.int32)
    
    ccr_queue = []
    ccr_survived = 0
    ccr_total = 0
    lcc_sizes = []
    
    for epoch in range(1, N_EPOCHS + 1):
        E = np.zeros((3, N_NODES, N_AGENTS), dtype=np.float32)
        
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
                
                required = 5.0
                intensities = available[authors_with_traces]
                sorted_authors = authors_with_traces[np.argsort(-intensities)]
                
                for author in sorted_authors:
                    if required <= 0: break
                    amt = available[author]
                    if amt == 0: continue
                    take = min(amt, required)
                    available[author] -= take
                    required -= take
                    
                    if author != a:
                        if cond != 'L3':
                            trust_matrix[a, author] = min(5.0, trust_matrix[a, author] + 0.1)
                        last_consumed_from[a] = author
                        
                        if niche[a] == 2 and niche[author] == 1:
                            e_author = last_consumed_from[author]
                            if e_author != -1 and niche[e_author] == 0:
                                triplet = (e_author, author, a)
                                if triplet not in active_triplets:
                                    active_triplets[triplet] = {'first': epoch, 'last': epoch, 'activations': 0}
                                active_triplets[triplet]['activations'] += 1
                                active_triplets[triplet]['last'] = epoch
                                
                                for agent_idx in triplet:
                                    if agent_dead_since[agent_idx] != -1:
                                        rrt = epoch - agent_dead_since[agent_idx]
                                        recovery_times.append(rrt)
                                        agent_dead_since[agent_idx] = -1
                                        
                S[t_target, n_id, :] = available
            drop_amt = 2.5
            E[emit_trace, pos, np.arange(N_AGENTS)] += drop_amt
            
        E_flat = E.transpose(1, 0, 2).reshape(N_NODES, -1)
        S_flat = S.transpose(1, 0, 2).reshape(N_NODES, -1)
        S_new_flat = S_flat * DECAY + K_csr.dot(E_flat)
        S_new_flat = np.clip(S_new_flat, 0.0, MAX_PHI)
        S = S_new_flat.reshape(N_NODES, 3, N_AGENTS).transpose(1, 0, 2)
        
        if cond != 'L3':
            trust_matrix = np.maximum(1.0, trust_matrix * 0.99)
        
        adj = np.zeros((N_AGENTS, N_AGENTS), dtype=np.int32)
        for triplet, data in active_triplets.items():
            if data['last'] >= epoch - 1:
                adj[triplet[0], triplet[1]] = 1
                adj[triplet[1], triplet[0]] = 1
                adj[triplet[1], triplet[2]] = 1
                adj[triplet[2], triplet[1]] = 1
                
        n_components, labels = connected_components(csgraph=sp.csr_matrix(adj), directed=False, return_labels=True)
        if n_components > 0:
            unique, counts = np.unique(labels, return_counts=True)
            lcc_sizes.append(np.max(counts))
        else:
            lcc_sizes.append(0)
            
        surviving_queue = []
        for item in ccr_queue:
            if item['check_epoch'] == epoch:
                ccr_total += 1
                trip = item['triplet']
                if trip in active_triplets and active_triplets[trip]['last'] >= epoch - 1:
                    ccr_survived += 1
            else:
                surviving_queue.append(item)
        ccr_queue = surviving_queue
        
        dead_agents = np.where(np.random.rand(N_AGENTS) < MORTALITY_RATE)[0]
        for a in dead_agents:
            deaths += 1
            for triplet, data in active_triplets.items():
                if a in triplet and data['last'] >= epoch - 1:
                    ccr_queue.append({'check_epoch': epoch + 5, 'triplet': triplet})
            
            if cond == 'L1':
                pos[a] = np.random.randint(0, N_NODES)
            elif cond == 'L4':
                pos[a] = (pos[a] + np.random.randint(-5, 6)) % N_NODES
            
            if cond != 'L3':
                trust_matrix[a, :] = 1.0 # Wipe memory (alpha = 0)
                
            last_consumed_from[a] = -1
            agent_dead_since[a] = epoch
            
    ccr = ccr_survived / max(1, ccr_total)
    rrt = np.mean(recovery_times) if len(recovery_times) > 0 else 0.0
    scp = np.mean([t['last'] - t['first'] for t in active_triplets.values()]) if len(active_triplets) > 0 else 0.0
    mean_lcc = np.mean(lcc_sizes)
    
    return cond, deaths, ccr, rrt, scp, mean_lcc

if __name__ == "__main__":
    conds = ['L0', 'L1', 'L2', 'L3', 'L4']
    print("🌌 [REA-7L Python Engine] Booting Ablation Sweep...")
    start = time.time()
    with multiprocessing.Pool(5) as pool:
        results = pool.map(run_condition, conds)
        
    print(f"Sweep completed in {time.time() - start:.2f} seconds\n")
    print("="*65)
    print(f"{'Condition':<9} | {'Deaths':<8} | {'CCR':<6} | {'RRT':<6} | {'SCP':<6} | {'Mean LCC':<10}")
    print("-" * 65)
    for res in results:
        cond, deaths, ccr, rrt, scp, mean_lcc = res
        print(f"{cond:<9} | {deaths:<8} | {ccr:<6.3f} | {rrt:<6.1f} | {scp:<6.1f} | {mean_lcc:<10.1f}")
