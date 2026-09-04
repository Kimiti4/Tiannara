import numpy as np
import scipy.sparse as sp

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

class SimulatorState:
    def __init__(self, pos, trust_matrix, S_sparse, niche, agent_consumed_amt, active_triplets):
        self.pos = np.copy(pos)
        self.trust_matrix = np.copy(trust_matrix)
        self.S_sparse = [s.copy() for s in S_sparse] if S_sparse else []
        self.niche = np.copy(niche)
        self.agent_consumed_amt = np.copy(agent_consumed_amt)
        self.active_triplets = set(active_triplets)
        
        # Targets
        self.target_node = 0
        self.DCI_target = 0.0
        self.R_target = 0.0
        self.TFI_target = 0.0
        self.DCR_target = 0.0
        self.SCP_target = 0.0
        
    def copy(self):
        new_state = SimulatorState(self.pos, self.trust_matrix, self.S_sparse, self.niche, self.agent_consumed_amt, self.active_triplets)
        new_state.target_node = self.target_node
        new_state.DCI_target = self.DCI_target
        new_state.R_target = self.R_target
        new_state.TFI_target = self.TFI_target
        new_state.DCR_target = self.DCR_target
        new_state.SCP_target = self.SCP_target
        return new_state

def get_basin_metrics(state, target_node, radius=5):
    N_NODES = state.S_sparse[0].shape[0]
    N_AGENTS = len(state.pos)
    
    dists = np.abs(state.pos - target_node)
    dists = np.minimum(dists, N_NODES - dists)
    agents_in_radius = np.where(dists <= radius)[0]
    
    if len(agents_in_radius) == 0:
        return 0.0, 0.0, 0.0, 0, np.zeros(N_AGENTS), np.zeros(N_NODES)
        
    consumptions = state.agent_consumed_amt[agents_in_radius]
    n_in_radius = len(agents_in_radius)
    
    local_dcr = np.sum(consumptions >= 4.0) / n_in_radius
    
    local_triplets = 0
    agents_set = set(agents_in_radius)
    for (e, c, p_idx) in state.active_triplets:
        if e in agents_set and c in agents_set and p_idx in agents_set:
            local_triplets += 1
            
    sub_trust = state.trust_matrix[np.ix_(agents_in_radius, agents_in_radius)]
    trust_edges = (sub_trust > 1.5).astype(np.float32)
    degrees = np.sum(trust_edges, axis=1)
    mean_degree = np.mean(degrees)
    
    top_20 = max(1, int(n_in_radius * 0.20))
    total_cons = np.sum(consumptions)
    dci = 0.0
    if total_cons > 0:
        dci = np.sum(np.sort(consumptions)[-top_20:]) / total_cons
        
    global_in_trust = np.sum(state.trust_matrix > 1.5, axis=0)
    trust_centrality = global_in_trust
    
    counts = np.bincount(state.pos[agents_in_radius], minlength=N_NODES)
    
    return local_dcr, dci, mean_degree, local_triplets, trust_centrality, counts

def compute_tfi(dcr, scp, dci, r, counts, state, target_node, radius=5):
    N_NODES = state.S_sparse[0].shape[0]
    dists = np.abs(state.pos - target_node)
    dists = np.minimum(dists, N_NODES - dists)
    agents_in_radius = np.where(dists <= radius)[0]
    
    if len(agents_in_radius) == 0:
        return 0.0
        
    degrees = np.sum(state.trust_matrix[np.ix_(agents_in_radius, agents_in_radius)] > 1.5, axis=1)
    d_counts = np.bincount(degrees.astype(int))
    p = d_counts[d_counts > 0] / len(agents_in_radius)
    path_entropy = -np.sum(p * np.log2(p))
    
    congestion = np.max(counts) / len(agents_in_radius)
    
    topology_quality = r / (dci + congestion + 1e-6)
    tfi = dcr * scp * topology_quality * (1.0 / (path_entropy + 1e-6))
    return tfi

def run_simulation_step_c1(state, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS, world_mode='A'):
    N_AGENTS = len(state.pos)
    N_NODES = K_csr.shape[0]
    K_RING = neighbors.shape[1]
    
    dcr_val, dci_val, r_val, scp_val, trust_centrality, counts = get_basin_metrics(state, state.target_node)
    tfi_val = compute_tfi(dcr_val, scp_val, dci_val, r_val, counts, state, state.target_node)
    
    decay_rate = 0.99
    CE = 0.0 
    IVE = max(0.0, state.DCR_target - dcr_val)
    
    dci_error = 0.0
    red_error = 0.0
    
    if world_mode in ['B', 'C']:
        tfi_low = 0.8 * state.TFI_target
        tfi_high = 1.2 * state.TFI_target
        
        if not (tfi_low <= tfi_val <= tfi_high):
            # Dynamic lambda_2 (Topology Weighting)
            viability_ratio = min(1.0, dcr_val / (state.DCR_target + 1e-6))
            lambda_2 = viability_ratio  # scales from 0 to 1 based on viability
            
            raw_red_error = r_val - state.R_target
            if raw_red_error > 0.1:
                decay_rate = 1.0 - (0.01 * lambda_2) if world_mode == 'B' else np.random.choice([1.0 - 0.01*lambda_2, 1.0 + 0.01*lambda_2])
                CE += 10.0 * lambda_2
            elif raw_red_error < -0.1:
                decay_rate = 1.0 - (0.002 * lambda_2) if world_mode == 'B' else np.random.choice([1.0 - 0.002*lambda_2, 1.0 - 0.01*lambda_2])
                CE += 5.0 * lambda_2
                
            dci_error = max(0.0, dci_val - state.DCI_target) * lambda_2
        
    state.agent_consumed_amt[:] = 0.0
    E_rows = [[], [], []]; E_cols = [[], [], []]; E_data = [[], [], []]
    C_rows = [[], [], []]; C_cols = [[], [], []]; C_data = [[], [], []]
    state.active_triplets.clear()
    last_consumed_from = np.full(N_AGENTS, -1, dtype=np.int32)
    
    max_cent = max(1.0, np.max(trust_centrality))
    local_trust_all = np.sum(state.trust_matrix > 1.5, axis=1)
    t_norm_all = np.minimum(1.0, local_trust_all / 5.0)
    
    agents_arange = np.arange(N_AGENTS)
    
    for step in range(WALK_STEPS):
        c_nodes = neighbors[state.pos]
        Phi_fields = [state.S_sparse[t].dot(state.trust_matrix.T) for t in range(3)]
        
        phi = np.zeros((N_AGENTS, K_RING), dtype=np.float32)
        for t in range(3):
            mask = (target_trace == t)
            if np.any(mask):
                agents_idx = np.where(mask)[0]
                phi[mask] = Phi_fields[t][c_nodes[mask], agents_idx[:, None]]
                
        noise = np.random.uniform(0, 0.05, size=(N_AGENTS, K_RING))
        
        e_norm_all = np.minimum(1.0, state.agent_consumed_amt / 4.0)
        # Capped w_macro to prevent autoimmune overreach
        w_macro_all = np.minimum(0.4, (1.0 - e_norm_all) * (1.0 - t_norm_all))
        
        if world_mode in ['B', 'C']:
            if world_mode == 'C':
                safety_nodes = np.random.randint(0, N_NODES, size=(N_AGENTS, 1))
            else:
                safety_nodes = np.full((N_AGENTS, 1), state.target_node, dtype=np.int32)
                
            dists = np.abs(c_nodes - safety_nodes)
            dists = np.minimum(dists, N_NODES - dists)
            
            macro_phi = 5.0 / (dists + 1.0)
            node_density = counts[c_nodes]
            if world_mode == 'B':
                macro_phi -= 2.0 * (node_density / N_AGENTS)
            else:
                macro_phi -= 2.0 * np.random.uniform(0, 0.1, size=(N_AGENTS, K_RING))
                
            w_m = w_macro_all[:, None]
            mask_w = w_macro_all > 0.1
            CE += np.sum(w_macro_all[mask_w]) * 0.1 # scaled down effort tracking
            macro_phi[~mask_w] = 0.0
            
            total_phi = (1.0 - w_m) * phi + w_m * macro_phi + noise
        else:
            total_phi = phi + noise
            
        best_idx = np.argmax(total_phi, axis=1)
        state.pos = c_nodes[agents_arange, best_idx]
        counts = np.bincount(state.pos, minlength=N_NODES)
        
        agent_order = np.random.permutation(N_AGENTS)
        for a in agent_order:
            n_id = state.pos[a]
            t = target_trace[a]
            row = state.S_sparse[t].getrow(n_id)
            if row.nnz == 0: continue
            
            authors = row.indices
            available = row.data.copy()
            required = 5.0 - state.agent_consumed_amt[a]
            if required <= 0: continue
            
            if world_mode in ['B', 'C'] and dci_error > 0.02:
                w_macro = w_macro_all[a]
                if world_mode == 'B':
                    # Reduced K_p from 5.0 to 0.5
                    hub_penalties = 0.5 * (trust_centrality[authors] / max_cent) * dci_error * w_macro
                else:
                    hub_penalties = 0.5 * np.random.rand(len(authors)) * dci_error * w_macro
                    
                available_score = available - hub_penalties
                CE += np.sum(hub_penalties)
            else:
                available_score = available
                
            sort_order = np.argsort(-available_score)
            authors = authors[sort_order]
            available = available[sort_order]
            
            for idx, author in enumerate(authors):
                if required <= 0: break
                amt = available[idx]
                if amt <= 0: continue
                take = min(amt, required)
                
                C_rows[t].append(n_id); C_cols[t].append(author); C_data[t].append(take)
                required -= take
                state.agent_consumed_amt[a] += take
                
                if author != a:
                    state.trust_matrix[a, author] = min(5.0, state.trust_matrix[a, author] + 0.1)
                    last_consumed_from[a] = author
                    if state.niche[a] == 2 and state.niche[author] == 1:
                        e_author = last_consumed_from[author]
                        if e_author != -1 and state.niche[e_author] == 0:
                            state.active_triplets.add((e_author, author, a))
                            
        for a in range(N_AGENTS):
            t = emit_trace[a]
            n_id = state.pos[a]
            E_rows[t].append(n_id); E_cols[t].append(a); E_data[t].append(2.5)
            
    for t in range(3):
        if len(C_data[t]) > 0:
            C_mat = sp.csr_matrix((C_data[t], (C_rows[t], C_cols[t])), shape=(N_NODES, N_AGENTS))
            state.S_sparse[t] = state.S_sparse[t] - C_mat
        if len(E_data[t]) > 0:
            E_mat = sp.csr_matrix((E_data[t], (E_rows[t], E_cols[t])), shape=(N_NODES, N_AGENTS))
            state.S_sparse[t] = state.S_sparse[t].multiply(DECAY) + K_csr.dot(E_mat)
        else:
            state.S_sparse[t] = state.S_sparse[t].multiply(DECAY)
            
        state.S_sparse[t].data = np.clip(state.S_sparse[t].data, 0.0, MAX_PHI)
        state.S_sparse[t].data[state.S_sparse[t].data < 1e-3] = 0.0
        state.S_sparse[t].eliminate_zeros()
            
    state.trust_matrix = np.maximum(1.0, state.trust_matrix * decay_rate)
    dead_agents = np.where(np.random.rand(N_AGENTS) < MORTALITY_RATE)[0]
    for a in dead_agents:
        state.trust_matrix[a, :] = 1.0 
        state.agent_consumed_amt[a] = 0.0
        
    return CE, IVE, tfi_val

def apply_topological_shock(state, target_node, radius=5):
    s_shock = state.copy()
    N_NODES = s_shock.S_sparse[0].shape[0]
    dists = np.abs(s_shock.pos - target_node)
    dists = np.minimum(dists, N_NODES - dists)
    agents_in_radius = np.where(dists <= radius)[0]
    
    if len(agents_in_radius) > 0:
        sub_trust = s_shock.trust_matrix[np.ix_(agents_in_radius, agents_in_radius)]
        in_trust = np.sum(np.maximum(0, sub_trust - 1.0), axis=0)
        top_10 = max(1, int(len(agents_in_radius) * 0.10))
        hub_local_indices = np.argsort(in_trust)[-top_10:]
        hub_global_indices = agents_in_radius[hub_local_indices]
        for hub_g in hub_global_indices:
            for a_g in agents_in_radius:
                s_shock.trust_matrix[a_g, hub_g] = 1.0
                
        for a in agents_in_radius:
            for b in agents_in_radius:
                if s_shock.trust_matrix[a, b] > 1.0 and np.random.rand() < 0.2:
                    s_shock.trust_matrix[a, b] = 1.0
    return s_shock

def calc_functional_similarity(state_400, state_800):
    metrics_400 = get_basin_metrics(state_400, state_400.target_node)
    metrics_800 = get_basin_metrics(state_800, state_800.target_node)
    # 0: DCR, 1: DCI, 2: R, 3: SCP
    f_dcr = 1.0 - abs(metrics_800[0] - metrics_400[0])
    f_dci = 1.0 - abs(metrics_800[1] - metrics_400[1])
    f_r = 1.0 - abs(metrics_800[2] - metrics_400[2]) / max(1e-6, max(metrics_400[2], metrics_800[2]))
    f_scp = 1.0 - abs(metrics_800[3] - metrics_400[3]) / max(1e-6, max(metrics_400[3], metrics_800[3]))
    return max(0.0, (f_dcr + f_dci + f_r + f_scp) / 4.0)

def calc_iri(state_400, state_800):
    # Structural (Jaccard)
    edges_400 = (state_400.trust_matrix > 1.5)
    edges_800 = (state_800.trust_matrix > 1.5)
    intersection = np.logical_and(edges_400, edges_800).sum()
    union = np.logical_or(edges_400, edges_800).sum()
    S = intersection / max(1, union)
    
    # Functional
    F = calc_functional_similarity(state_400, state_800)
    
    # Lineage (0.5 * HubRetention + 0.5 * SCPRetention)
    _, _, _, scp_400, trust_400, _ = get_basin_metrics(state_400, state_400.target_node)
    _, _, _, scp_800, trust_800, _ = get_basin_metrics(state_800, state_800.target_node)
    
    top_10 = max(1, int(len(trust_400) * 0.10))
    hubs_400 = set(np.argsort(trust_400)[-top_10:])
    hubs_800 = set(np.argsort(trust_800)[-top_10:])
    hub_retention = len(hubs_400.intersection(hubs_800)) / len(hubs_400)
    
    scp_retention = min(1.0, scp_800 / max(1e-6, scp_400))
    L = 0.5 * hub_retention + 0.5 * scp_retention
    
    return 0.3 * S + 0.4 * F + 0.3 * L

def run_world_c1_tournament():
    np.random.seed(42)
    N_NODES = 10000; N_AGENTS = 1000; WALK_STEPS = 20; RADIUS = 5
    MORTALITY_RATE = 0.0025; MAX_PHI = 1.0; DECAY = np.exp(-0.10)
    
    neighbors, K_csr = generate_topology(N_NODES, k_ring=RADIUS*2)
    niche = np.zeros(N_AGENTS, dtype=np.int32)
    niche[333:666] = 1; niche[666:] = 2   
    target_trace = np.zeros(N_AGENTS, dtype=np.int32)
    target_trace[niche == 0] = 0; target_trace[niche == 1] = 0; target_trace[niche == 2] = 1
    emit_trace = np.copy(niche)
    
    print("🌌 [REA-7N-C.1] Booting Allostatic Governance Tournament")
    
    pos = np.random.randint(0, N_NODES, size=N_AGENTS)
    trust_matrix = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S_sparse = [sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32) for _ in range(3)]
    state = SimulatorState(pos, trust_matrix, S_sparse, niche, np.zeros(N_AGENTS, dtype=np.float32), [])
    
    print("\nPhase 1: Running Universal Baseline to Epoch 400...")
    max_dcr, max_dci, max_r, max_scp, max_tfi = 0.0, 0.0, 0.0, 0.0, 0.0
    for epoch in range(1, 401):
        S_sum = np.array(state.S_sparse[0].sum(axis=1) + state.S_sparse[1].sum(axis=1) + state.S_sparse[2].sum(axis=1)).flatten()
        state.target_node = int(np.argmax(S_sum))
        run_simulation_step_c1(state, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS, world_mode='A')
        
        if epoch >= 380:
            dcr, dci, r, scp, _, c = get_basin_metrics(state, state.target_node)
            tfi = compute_tfi(dcr, scp, dci, r, c, state, state.target_node)
            max_dcr = max(max_dcr, dcr)
            max_dci = max(max_dci, dci)
            max_r = max(max_r, r)
            max_scp = max(max_scp, scp)
            max_tfi = max(max_tfi, tfi)
            
        if epoch % 100 == 0:
            dcr, dci, r, scp, _, c = get_basin_metrics(state, state.target_node)
            tfi = compute_tfi(dcr, scp, dci, r, c, state, state.target_node)
            print(f"  Epoch {epoch} | DCR: {dcr:.3f} | DCI: {dci:.3f} | R: {r:.2f} | TFI: {tfi:.1f}")
            
    S_sum = np.array(state.S_sparse[0].sum(axis=1) + state.S_sparse[1].sum(axis=1) + state.S_sparse[2].sum(axis=1)).flatten()
    state.target_node = int(np.argmax(S_sum))
    
    state.DCR_target = max_dcr
    state.SCP_target = max_scp
    state.DCI_target = max_dci
    state.R_target = max_r * 1.10
    state.TFI_target = max(1.0, max_tfi)
    
    state_400 = state.copy()
    
    print(f"\n[Allostatic Attractor Locked]")
    print(f"  DCR_target = {state.DCR_target:.3f}")
    print(f"  TFI_target = {state.TFI_target:.1f} (Deadband: {0.8*state.TFI_target:.1f} to {1.2*state.TFI_target:.1f})")
    
    print("\nPhase 2: Applying Deep Topological Shock (Epoch 400)")
    state_shocked = apply_topological_shock(state, state.target_node)
    
    state_A = state_shocked.copy()
    state_B = state_shocked.copy()
    state_C = state_shocked.copy()
    
    print("\nPhase 3: Survival & Recovery Race (Epoch 401-800)")
    
    metrics = {
        'A': {'ce': 0.0, 'ive': 0.0, 'adapt_cost': 0.0, 'trh': -1},
        'B': {'ce': 0.0, 'ive': 0.0, 'adapt_cost': 0.0, 'trh': -1},
        'C': {'ce': 0.0, 'ive': 0.0, 'adapt_cost': 0.0, 'trh': -1}
    }
    
    for epoch in range(401, 801):
        for mode, st in zip(['A', 'B', 'C'], [state_A, state_B, state_C]):
            S_sum_m = np.array(st.S_sparse[0].sum(axis=1) + st.S_sparse[1].sum(axis=1) + st.S_sparse[2].sum(axis=1)).flatten()
            st.target_node = int(np.argmax(S_sum_m))
            
            ce, ive, tfi = run_simulation_step_c1(st, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS, world_mode=mode)
            metrics[mode]['ce'] += ce
            metrics[mode]['ive'] += ive
            
            f_sim = calc_functional_similarity(state_400, st)
            metrics[mode]['adapt_cost'] += (1.0 - f_sim)
            
            if metrics[mode]['trh'] == -1 and tfi >= 0.80 * state.TFI_target:
                metrics[mode]['trh'] = epoch - 400
                
        if epoch % 100 == 0:
            print(f"  Epoch {epoch} | CE -> A:{metrics['A']['ce']:.0f} B:{metrics['B']['ce']:.0f} C:{metrics['C']['ce']:.0f}")
            
    print("\n========================================================")
    print("REA-7N-C.1 Allostatic Governance Results")
    print("========================================================")
    
    for mode, st in zip(['A', 'B', 'C'], [state_A, state_B, state_C]):
        name = "World A (Micro Only)" if mode == 'A' else ("World B (Adaptive Reg)" if mode == 'B' else "World C (Random Reg)")
        dcr_final, _, _, _, _, _ = get_basin_metrics(st, st.target_node)
        surv = "High" if dcr_final > 0.8 else ("Low" if dcr_final > 0.2 else "Collapsed")
        iri = calc_iri(state_400, st)
        
        cai = metrics[mode]['ce'] / max(1.0, metrics[mode]['ive'])
        
        trh_str = 'Never Recovered' if metrics[mode]['trh'] == -1 else f"{metrics[mode]['trh']} epochs"
        
        print(f"\n[{name}]")
        print(f"  Survival:        {surv} (DCR={dcr_final:.2f})")
        print(f"  IRI:             {iri:.3f}")
        print(f"  Adaptation Cost: {metrics[mode]['adapt_cost']:.1f}")
        print(f"  TRH:             {trh_str}")
        print(f"  Total Effort:    {metrics[mode]['ce']:.0f}")
        print(f"  CAI:             {cai:.2f}")

if __name__ == "__main__":
    run_world_c1_tournament()
