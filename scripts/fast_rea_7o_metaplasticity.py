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
        
        self.target_node = 0
        self.DCI_target = 0.0
        self.R_target = 0.0
        self.TFI_target = 0.0
        
        self.dcr_400 = 0.0
        self.scp_400 = 0.0
        self.hubs_400 = set()
        
    def copy(self):
        new_state = SimulatorState(self.pos, self.trust_matrix, self.S_sparse, self.niche, self.agent_consumed_amt, self.active_triplets)
        new_state.target_node = self.target_node
        new_state.DCI_target = self.DCI_target
        new_state.R_target = self.R_target
        new_state.TFI_target = self.TFI_target
        new_state.dcr_400 = self.dcr_400
        new_state.scp_400 = self.scp_400
        new_state.hubs_400 = self.hubs_400.copy()
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

def calc_fri(state, dcr_val, scp_val, trust_centrality):
    dcr_ret = dcr_val / max(1e-6, state.dcr_400)
    scp_ret = scp_val / max(1e-6, state.scp_400)
    
    top_10 = max(1, int(len(trust_centrality) * 0.10))
    current_hubs = set(np.argsort(trust_centrality)[-top_10:])
    
    if len(state.hubs_400) == 0:
        lineage_ret = 1.0
    else:
        lineage_ret = len(state.hubs_400.intersection(current_hubs)) / len(state.hubs_400)
        
    fri = 0.4 * min(1.0, dcr_ret) + 0.4 * min(1.0, scp_ret) + 0.2 * lineage_ret
    return fri

def run_simulation_step_7o(state, epoch, neighbors, K_csr, target_trace, emit_trace, MORTALITY_RATE, WALK_STEPS, world_mode='A'):
    N_AGENTS = len(state.pos)
    N_NODES = K_csr.shape[0]
    K_RING = neighbors.shape[1]
    
    dcr_val, dci_val, r_val, scp_val, trust_centrality, counts = get_basin_metrics(state, state.target_node)
    tfi_val = compute_tfi(dcr_val, scp_val, dci_val, r_val, counts, state, state.target_node)
    
    # Base Thermodynamics
    gamma_persistence = 0.9048
    rho_signal = 2.5
    alpha_trust_gain = 0.1
    alpha_trust_decay = 0.99
    tau_explore = 0.05
    
    CE = 0.0 
    
    dci_error = 0.0
    red_error = 0.0
    w_macro_scale = 0.0
    
    # World B: Structural Fetishist (C.1 Controller)
    if world_mode == 'B':
        tfi_low = 0.8 * state.TFI_target
        tfi_high = 1.2 * state.TFI_target
        if not (tfi_low <= tfi_val <= tfi_high):
            viability_ratio = min(1.0, dcr_val / (state.dcr_400 + 1e-6))
            lambda_2 = viability_ratio
            
            raw_red_error = r_val - state.R_target
            if raw_red_error > 0.1:
                alpha_trust_decay = 1.0 - (0.01 * lambda_2)
                CE += 10.0 * lambda_2
            elif raw_red_error < -0.1:
                alpha_trust_decay = 1.0 - (0.002 * lambda_2)
                CE += 5.0 * lambda_2
                
            dci_error = max(0.0, dci_val - state.DCI_target) * lambda_2
            w_macro_scale = 0.4
            
    # World C: Metaplastic Constitution (Feedback Loop)
    if world_mode == 'C':
        fri = calc_fri(state, dcr_val, scp_val, trust_centrality)
        
        if fri < 0.85:
            melt_factor = (0.85 - fri) / 0.85 
            gamma_persistence = 0.9048 + 0.08 * melt_factor
            rho_signal = 2.5 + 2.5 * melt_factor
            alpha_trust_gain = 0.1 + 0.4 * melt_factor
            alpha_trust_decay = 0.99 - 0.09 * melt_factor
            tau_explore = 0.05 + 0.95 * melt_factor
            CE += 50.0 * melt_factor
            
        elif fri >= 0.95:
            gamma_persistence = 0.85
            rho_signal = 2.5
            alpha_trust_gain = 0.1
            alpha_trust_decay = 0.995
            tau_explore = 0.01
            CE += 5.0
            
    # World D: Open-Loop Annealing (No Feedback)
    if world_mode == 'D':
        if 401 <= epoch <= 500:
            melt_factor = 1.0
        elif 501 <= epoch <= 600:
            melt_factor = max(0.0, 1.0 - (epoch - 500) / 100.0)
        else:
            melt_factor = 0.0
            
        if melt_factor > 0:
            gamma_persistence = 0.9048 + 0.08 * melt_factor
            rho_signal = 2.5 + 2.5 * melt_factor
            alpha_trust_gain = 0.1 + 0.4 * melt_factor
            alpha_trust_decay = 0.99 - 0.09 * melt_factor
            tau_explore = 0.05 + 0.95 * melt_factor
        else:
            gamma_persistence = 0.85
            rho_signal = 2.5
            alpha_trust_gain = 0.1
            alpha_trust_decay = 0.995
            tau_explore = 0.01
            
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
        
        if world_mode == 'B':
            w_macro_all = np.minimum(w_macro_scale, (1.0 - e_norm_all) * (1.0 - t_norm_all))
            safety_nodes = np.full((N_AGENTS, 1), state.target_node, dtype=np.int32)
            dists = np.abs(c_nodes - safety_nodes)
            dists = np.minimum(dists, N_NODES - dists)
            
            macro_phi = 5.0 / (dists + 1.0)
            node_density = counts[c_nodes]
            macro_phi -= 2.0 * (node_density / N_AGENTS)
                
            w_m = w_macro_all[:, None]
            mask_w = w_macro_all > 0.1
            CE += np.sum(w_macro_all[mask_w]) * 0.1
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
            
            if world_mode == 'B' and dci_error > 0.02:
                w_macro = w_macro_all[a]
                hub_penalties = 0.5 * (trust_centrality[authors] / max_cent) * dci_error * w_macro
                available_score = available - hub_penalties
                CE += np.sum(hub_penalties)
            else:
                available_score = available
                
            # Metaplastic Lever: Exploration Temperature
            gumbel_noise = np.random.gumbel(size=len(authors))
            explore_score = available_score + tau_explore * gumbel_noise
                
            sort_order = np.argsort(-explore_score)
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
                    state.trust_matrix[a, author] = min(5.0, state.trust_matrix[a, author] + alpha_trust_gain)
                    last_consumed_from[a] = author
                    if state.niche[a] == 2 and state.niche[author] == 1:
                        e_author = last_consumed_from[author]
                        if e_author != -1 and state.niche[e_author] == 0:
                            state.active_triplets.add((e_author, author, a))
                            
        for a in range(N_AGENTS):
            t = emit_trace[a]
            n_id = state.pos[a]
            E_rows[t].append(n_id); E_cols[t].append(a); E_data[t].append(rho_signal)
            
    MAX_PHI = 1.0 * (rho_signal / 2.5) 
    
    for t in range(3):
        if len(C_data[t]) > 0:
            C_mat = sp.csr_matrix((C_data[t], (C_rows[t], C_cols[t])), shape=(N_NODES, N_AGENTS))
            state.S_sparse[t] = state.S_sparse[t] - C_mat
        if len(E_data[t]) > 0:
            E_mat = sp.csr_matrix((E_data[t], (E_rows[t], E_cols[t])), shape=(N_NODES, N_AGENTS))
            state.S_sparse[t] = state.S_sparse[t].multiply(gamma_persistence) + K_csr.dot(E_mat)
        else:
            state.S_sparse[t] = state.S_sparse[t].multiply(gamma_persistence)
            
        state.S_sparse[t].data = np.clip(state.S_sparse[t].data, 0.0, MAX_PHI)
        state.S_sparse[t].data[state.S_sparse[t].data < 1e-3] = 0.0
        state.S_sparse[t].eliminate_zeros()
            
    state.trust_matrix = np.maximum(1.0, state.trust_matrix * alpha_trust_decay)
    dead_agents = np.where(np.random.rand(N_AGENTS) < MORTALITY_RATE)[0]
    for a in dead_agents:
        state.trust_matrix[a, :] = 1.0 
        state.agent_consumed_amt[a] = 0.0
        
    ive = max(0.0, state.dcr_400 - dcr_val)
    return CE, ive, tfi_val, gamma_persistence, rho_signal, alpha_trust_gain, tau_explore

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

def calc_iri(state_400, state_800):
    edges_400 = (state_400.trust_matrix > 1.5)
    edges_800 = (state_800.trust_matrix > 1.5)
    intersection = np.logical_and(edges_400, edges_800).sum()
    union = np.logical_or(edges_400, edges_800).sum()
    S = intersection / max(1, union)
    return S

def run_world_o_tournament():
    np.random.seed(42)
    N_NODES = 10000; N_AGENTS = 1000; WALK_STEPS = 20; RADIUS = 5
    MORTALITY_RATE = 0.0025
    
    neighbors, K_csr = generate_topology(N_NODES, k_ring=RADIUS*2)
    niche = np.zeros(N_AGENTS, dtype=np.int32)
    niche[333:666] = 1; niche[666:] = 2   
    target_trace = np.zeros(N_AGENTS, dtype=np.int32)
    target_trace[niche == 0] = 0; target_trace[niche == 1] = 0; target_trace[niche == 2] = 1
    emit_trace = np.copy(niche)
    
    print("🌌 [REA-7O] Booting Metaplastic Governance Tournament")
    
    pos = np.random.randint(0, N_NODES, size=N_AGENTS)
    trust_matrix = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S_sparse = [sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32) for _ in range(3)]
    state = SimulatorState(pos, trust_matrix, S_sparse, niche, np.zeros(N_AGENTS, dtype=np.float32), [])
    
    print("\nPhase 1: Running Universal Baseline to Epoch 400...")
    max_dcr, max_dci, max_r, max_scp, max_tfi = 0.0, 0.0, 0.0, 0.0, 0.0
    for epoch in range(1, 401):
        S_sum = np.array(state.S_sparse[0].sum(axis=1) + state.S_sparse[1].sum(axis=1) + state.S_sparse[2].sum(axis=1)).flatten()
        state.target_node = int(np.argmax(S_sum))
        run_simulation_step_7o(state, epoch, neighbors, K_csr, target_trace, emit_trace, MORTALITY_RATE, WALK_STEPS, world_mode='A')
        
        if epoch >= 380:
            dcr, dci, r, scp, trust_centrality, c = get_basin_metrics(state, state.target_node)
            tfi = compute_tfi(dcr, scp, dci, r, c, state, state.target_node)
            max_dcr = max(max_dcr, dcr)
            max_dci = max(max_dci, dci)
            max_r = max(max_r, r)
            max_scp = max(max_scp, scp)
            max_tfi = max(max_tfi, tfi)
            
            top_10 = max(1, int(len(trust_centrality) * 0.10))
            hubs = set(np.argsort(trust_centrality)[-top_10:])
            state.hubs_400 = state.hubs_400.union(hubs)
            
        if epoch % 100 == 0:
            dcr, dci, r, scp, _, c = get_basin_metrics(state, state.target_node)
            tfi = compute_tfi(dcr, scp, dci, r, c, state, state.target_node)
            print(f"  Epoch {epoch} | DCR: {dcr:.3f} | SCP: {scp} | R: {r:.2f}")
            
    S_sum = np.array(state.S_sparse[0].sum(axis=1) + state.S_sparse[1].sum(axis=1) + state.S_sparse[2].sum(axis=1)).flatten()
    state.target_node = int(np.argmax(S_sum))
    
    state.dcr_400 = max_dcr
    state.scp_400 = max_scp
    
    state.DCR_target = max_dcr
    state.DCI_target = max_dci
    state.R_target = max_r * 1.10
    state.TFI_target = max(1.0, max_tfi)
    
    state_400 = state.copy()
    
    print(f"\n[Baseline Attractor Locked]")
    print(f"  DCR_400 = {state.dcr_400:.3f}")
    print(f"  SCP_400 = {state.scp_400}")
    
    print("\nPhase 2: Applying Deep Topological Shock (Epoch 400)")
    state_shocked = apply_topological_shock(state, state.target_node)
    
    state_A = state_shocked.copy()
    state_B = state_shocked.copy()
    state_C = state_shocked.copy()
    state_D = state_shocked.copy()
    
    print("\nPhase 3: Survival & Recovery Race (Epoch 401-800)")
    
    metrics = {
        'A': {'ce': 0.0, 'ive': 0.0, 'trh': -1, 'tau_int': 0.0, 'min_fri': 1.0},
        'B': {'ce': 0.0, 'ive': 0.0, 'trh': -1, 'tau_int': 0.0, 'min_fri': 1.0},
        'C': {'ce': 0.0, 'ive': 0.0, 'trh': -1, 'tau_int': 0.0, 'min_fri': 1.0},
        'D': {'ce': 0.0, 'ive': 0.0, 'trh': -1, 'tau_int': 0.0, 'min_fri': 1.0}
    }
    
    # Store trajectories
    lever_log_C = []
    lever_log_D = []
    
    for epoch in range(401, 801):
        for mode, st in zip(['A', 'B', 'C', 'D'], [state_A, state_B, state_C, state_D]):
            S_sum_m = np.array(st.S_sparse[0].sum(axis=1) + st.S_sparse[1].sum(axis=1) + st.S_sparse[2].sum(axis=1)).flatten()
            st.target_node = int(np.argmax(S_sum_m))
            
            ce, ive, _, g_p, r_s, a_t, tau = run_simulation_step_7o(st, epoch, neighbors, K_csr, target_trace, emit_trace, MORTALITY_RATE, WALK_STEPS, world_mode=mode)
            
            metrics[mode]['ce'] += ce
            metrics[mode]['ive'] += ive
            metrics[mode]['tau_int'] += max(0.0, tau - 0.05)
            
            dcr_val, _, _, scp_val, trust_centrality, _ = get_basin_metrics(st, st.target_node)
            fri = calc_fri(st, dcr_val, scp_val, trust_centrality)
            
            metrics[mode]['min_fri'] = min(metrics[mode]['min_fri'], fri)
            
            if metrics[mode]['trh'] == -1 and fri >= 0.80:
                metrics[mode]['trh'] = epoch - 400
                
            if mode == 'C' and epoch % 50 == 0:
                lever_log_C.append((epoch, g_p, r_s, a_t, tau))
            if mode == 'D' and epoch % 50 == 0:
                lever_log_D.append((epoch, g_p, r_s, a_t, tau))
                
        if epoch % 100 == 0:
            print(f"  Epoch {epoch} | CE -> A:{metrics['A']['ce']:.0f} B:{metrics['B']['ce']:.0f} C:{metrics['C']['ce']:.0f} D:{metrics['D']['ce']:.0f}")
            
    print("\n========================================================")
    print("REA-7O Metaplastic Governance Results")
    print("========================================================")
    
    results = {}
    for mode, st in zip(['A', 'B', 'C', 'D'], [state_A, state_B, state_C, state_D]):
        name = "World A (Baseline)" if mode == 'A' else ("World B (Fetishist)" if mode == 'B' else ("World C (Cyber-Anneal)" if mode == 'C' else "World D (Open-Loop)"))
        dcr_final, _, _, scp_final, trust_centrality, _ = get_basin_metrics(st, st.target_node)
        
        fri_final = calc_fri(st, dcr_final, scp_final, trust_centrality)
        iri = calc_iri(state_400, st)
        tps = max(0.0, 1.0 - iri)
        cai = metrics[mode]['ce'] / max(1.0, metrics[mode]['ive'])
        rq = fri_final * tps * (1.0 / (1.0 + cai))
        trh = metrics[mode]['trh']
        if trh == -1: trh = 400
        
        delta_fri = fri_final - metrics[mode]['min_fri']
        ee = delta_fri / max(1e-6, metrics[mode]['tau_int']) if metrics[mode]['tau_int'] > 0 else 0.0
        
        results[mode] = {'fri': fri_final, 'trh': trh, 'rq': rq, 'dcr': dcr_final, 'ce': metrics[mode]['ce'], 'ee': ee}
        
        print(f"\n[{name}]")
        print(f"  Survival (DCR):  {dcr_final:.2f}")
        print(f"  FRI:             {fri_final:.3f}")
        print(f"  IRI (Jaccard):   {iri:.3f}")
        print(f"  TPS:             {tps:.3f}")
        print(f"  RQ:              {rq:.4f}")
        print(f"  TRH:             {trh} epochs")
        print(f"  Total Effort:    {metrics[mode]['ce']:.0f}")
        print(f"  CAI:             {cai:.2f}")
        print(f"  EE:              {ee:.6f}")

    ag_B = (results['A']['trh'] - results['B']['trh']) / float(results['A']['trh'])
    ag_C = (results['A']['trh'] - results['C']['trh']) / float(results['A']['trh'])
    ag_D = (results['A']['trh'] - results['D']['trh']) / float(results['A']['trh'])
    
    print("\n[Adaptive Gain]")
    print(f"  World B: {ag_B:+.3f}")
    print(f"  World C: {ag_C:+.3f}")
    print(f"  World D: {ag_D:+.3f}")
    
    print("\n[Lever Trajectories (World C - Cybernetic)]")
    for epoch, g_p, r_s, a_t, tau in lever_log_C:
        print(f"  Epoch {epoch:3d} | gamma:{g_p:.3f} | rho:{r_s:.2f} | alpha_gain:{a_t:.2f} | tau:{tau:.3f}")

    print("\n[Lever Trajectories (World D - Open-Loop)]")
    for epoch, g_p, r_s, a_t, tau in lever_log_D:
        print(f"  Epoch {epoch:3d} | gamma:{g_p:.3f} | rho:{r_s:.2f} | alpha_gain:{a_t:.2f} | tau:{tau:.3f}")
        
    outcome = ""
    if results['C']['fri'] > results['A']['fri'] and results['C']['trh'] < results['A']['trh'] and ag_C > 0 and results['C']['rq'] > results['D']['rq'] and results['C']['ee'] > results['D']['ee']:
        outcome = "Strong Success (Institutions improve adaptation via cybernetic intelligence)"
    elif results['C']['fri'] > results['A']['fri'] and results['C']['trh'] < results['A']['trh'] and ag_C > 0 and results['C']['ee'] <= results['D']['ee']:
        outcome = "Weak Success (Annealing works, but cybernetic feedback underperformed open-loop)"
    else:
        outcome = "Failure (Substrate self-organization is superior to macro-annealing)"
        
    print(f"\n[Pre-Registered Result Falsification]")
    print(f"  Result: {outcome}")

if __name__ == "__main__":
    run_world_o_tournament()
