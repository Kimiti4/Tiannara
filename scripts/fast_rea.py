import numpy as np
import scipy.sparse as sp
import time

def generate_topology(n_nodes, k_ring=10):
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
                rows.append(i)
                cols.append(n)
                data.append(0.5488) # Radius 1 broadcast weight
                
    K_csr = sp.csr_matrix((data, (rows, cols)), shape=(n_nodes, n_nodes))
    return neighbors, K_csr

def run_simulation():
    np.random.seed(42)
    
    N_NODES = 1000
    N_AGENTS = 100
    N_EPOCHS = 2000
    WALK_STEPS = 50
    DECAY = np.exp(-0.10)
    MAX_PHI = 1.0
    
    # Niches: 0=Explorer, 1=Compressor, 2=Predictor
    niche = np.zeros(N_AGENTS, dtype=np.int32)
    niche[33:66] = 1
    niche[66:] = 2
    
    # Heterotrophic Chain Traces
    target_trace = np.zeros(N_AGENTS, dtype=np.int32)
    target_trace[niche == 0] = 0 
    target_trace[niche == 1] = 0 
    target_trace[niche == 2] = 1 
    emit_trace = np.copy(niche)
    
    pos = np.random.randint(0, N_NODES, size=N_AGENTS)
    energy = np.zeros(N_AGENTS, dtype=np.float32)
    trust_matrix = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    
    S = np.zeros((3, N_NODES, N_AGENTS), dtype=np.float32)
    neighbors, K_csr = generate_topology(N_NODES)
    
    # --- REA-7J TELEMETRY STATE ---
    last_consumed_from = np.full(N_AGENTS, -1, dtype=np.int32)
    partner_success_count = np.zeros((N_AGENTS, N_AGENTS), dtype=np.int32)
    active_triplets = {} # (E, C, P) -> {'first', 'last', 'activations'}
    
    print("🌌 [REA-7J Python Engine] Booting...")
    start_time = time.time()
    
    for epoch in range(1, N_EPOCHS + 1):
        E = np.zeros((3, N_NODES, N_AGENTS), dtype=np.float32)
        
        encounters = 0
        cross_niche_encounters = 0
        
        # Telemetry per epoch
        ate_this_epoch = np.zeros(N_AGENTS, dtype=bool)
        
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
                if len(authors_with_traces) == 0:
                    continue
                    
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
                        encounters += 1
                        if niche[a] != niche[author]:
                            cross_niche_encounters += 1
                        trust_matrix[a, author] = min(5.0, trust_matrix[a, author] + 0.1)
                        
                        # --- REA-7J Telemetry Updates ---
                        partner_success_count[a, author] += 1
                        last_consumed_from[a] = author
                        ate_this_epoch[a] = True
                        
                        # Recursive Triplet Lookup
                        if niche[a] == 2 and niche[author] == 1:
                            e_author = last_consumed_from[author]
                            if e_author != -1 and niche[e_author] == 0:
                                triplet = (e_author, author, a)
                                if triplet not in active_triplets:
                                    active_triplets[triplet] = {'first': epoch, 'last': epoch, 'activations': 0}
                                active_triplets[triplet]['activations'] += 1
                                active_triplets[triplet]['last'] = epoch
                                
                S[t_target, n_id, :] = available
                
            drop_amt = 2.5
            E[emit_trace, pos, np.arange(N_AGENTS)] += drop_amt
            
        E_flat = E.transpose(1, 0, 2).reshape(N_NODES, -1)
        S_flat = S.transpose(1, 0, 2).reshape(N_NODES, -1)
        S_new_flat = S_flat * DECAY + K_csr.dot(E_flat)
        S_new_flat = np.clip(S_new_flat, 0.0, MAX_PHI)
        S = S_new_flat.reshape(N_NODES, 3, N_AGENTS).transpose(1, 0, 2)
        
        trust_matrix = np.maximum(1.0, trust_matrix * 0.99)
        
        if epoch % 500 == 0 or epoch == N_EPOCHS:
            cnf = cross_niche_encounters / max(1, encounters)
            
            # Compute DCR-1
            dcr_1 = np.sum(ate_this_epoch[niche != 0]) / np.sum(niche != 0)
            
            # Compute SCP and SCC
            if len(active_triplets) > 0:
                lifespans = [t['last'] - t['first'] for t in active_triplets.values()]
                scp = np.mean(lifespans)
                
                activations = np.array([t['activations'] for t in active_triplets.values()])
                total_activations = np.sum(activations)
                if total_activations > 0:
                    p = activations / total_activations
                    H_S = -np.sum(p * np.log(p))
                    max_entropy = np.log(len(active_triplets)) if len(active_triplets) > 1 else 1.0
                    scc = 1.0 - (H_S / max_entropy)
                else:
                    scc = 0.0
            else:
                scp = 0.0
                scc = 0.0
                
            print(f"Epoch {epoch:<4} | Encounters: {encounters:<6} | CNF: {cnf:.3f} | DCR-1: {dcr_1:.3f} | SCP: {scp:.1f} | SCC: {scc:.3f} | Unique Triplets: {len(active_triplets)}")

    print(f"Simulation completed in {time.time() - start_time:.2f} seconds")

if __name__ == "__main__":
    run_simulation()
