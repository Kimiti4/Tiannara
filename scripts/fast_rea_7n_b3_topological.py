import numpy as np
import scipy.sparse as sp
import time
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import train_test_split
import warnings
warnings.filterwarnings("ignore")

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
        self.S_sparse = S_sparse  
        self.niche = np.copy(niche)
        self.agent_consumed_amt = np.copy(agent_consumed_amt)
        self.active_triplets = set(active_triplets)
        self.migration_history = []

def run_simulation_step(state, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS):
    N_AGENTS = len(state.pos)
    N_NODES = K_csr.shape[0]
    
    state.agent_consumed_amt[:] = 0.0
    
    E_rows = [[], [], []]
    E_cols = [[], [], []]
    E_data = [[], [], []]
    
    C_rows = [[], [], []]
    C_cols = [[], [], []]
    C_data = [[], [], []]
    
    ec_matrix = np.zeros((N_AGENTS, N_AGENTS), dtype=np.float32)
    cp_matrix = np.zeros((N_AGENTS, N_AGENTS), dtype=np.float32)
    state.active_triplets.clear()
    last_consumed_from = np.full(N_AGENTS, -1, dtype=np.int32)
    
    for step in range(WALK_STEPS):
        cands = neighbors[state.pos] 
        best_idx = np.zeros(N_AGENTS, dtype=np.int32)
        
        Phi_fields = [state.S_sparse[t].dot(state.trust_matrix.T) for t in range(3)]
        
        for a in range(N_AGENTS):
            c_nodes = cands[a]
            t = target_trace[a]
            phi = Phi_fields[t][c_nodes, a]
            noise = np.random.uniform(0, 0.05, size=phi.shape)
            best_idx[a] = np.argmax(phi + noise)
            
        state.pos = cands[np.arange(N_AGENTS), best_idx]
        
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
            
            sort_order = np.argsort(-available)
            authors = authors[sort_order]
            available = available[sort_order]
            
            for idx, author in enumerate(authors):
                if required <= 0: break
                amt = available[idx]
                if amt == 0: continue
                take = min(amt, required)
                
                C_rows[t].append(n_id)
                C_cols[t].append(author)
                C_data[t].append(take)
                
                required -= take
                state.agent_consumed_amt[a] += take
                
                if author != a:
                    state.trust_matrix[a, author] = min(5.0, state.trust_matrix[a, author] + 0.1)
                    last_consumed_from[a] = author
                    if state.niche[a] == 1 and state.niche[author] == 0:
                        ec_matrix[a, author] += take
                    if state.niche[a] == 2 and state.niche[author] == 1:
                        cp_matrix[a, author] += take
                        e_author = last_consumed_from[author]
                        if e_author != -1 and state.niche[e_author] == 0:
                            state.active_triplets.add((e_author, author, a))
                            
        for a in range(N_AGENTS):
            t = emit_trace[a]
            n_id = state.pos[a]
            E_rows[t].append(n_id)
            E_cols[t].append(a)
            E_data[t].append(2.5)
            
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
            
    state.trust_matrix = np.maximum(1.0, state.trust_matrix * 0.99)
    
    dead_agents = np.where(np.random.rand(N_AGENTS) < MORTALITY_RATE)[0]
    for a in dead_agents:
        state.trust_matrix[a, :] = 1.0 
        state.agent_consumed_amt[a] = 0.0
        
    dcr = np.sum(state.agent_consumed_amt[state.niche > 0] >= 4.0) / max(1, np.sum(state.niche > 0))
    scp = len(state.active_triplets)
    return dcr, scp, ec_matrix, cp_matrix

def get_ternary_survival(state, target_node, radius=5):
    N_NODES = state.S_sparse[0].shape[0]
    dists = np.abs(state.pos - target_node)
    dists = np.minimum(dists, N_NODES - dists)
    agents_in_radius = np.where(dists <= radius)[0]
    
    if len(agents_in_radius) == 0:
        return 0 
        
    local_dcr = np.sum(state.agent_consumed_amt[agents_in_radius] >= 4.0) / max(1, len(agents_in_radius))
    
    local_triplets = 0
    agents_set = set(agents_in_radius)
    for (e, c, p_idx) in state.active_triplets:
        if e in agents_set and c in agents_set and p_idx in agents_set:
            local_triplets += 1
            
    if local_dcr < 0.5 or local_triplets == 0:
        return 0
    elif local_dcr > 0.8 and local_triplets >= 2:
        return 2
    else:
        return 1

def power_iteration(A, num_simulations=5):
    n = A.shape[0]
    if n == 0: return np.array([])
    b_k = np.ones(n) / np.sqrt(n)
    for _ in range(num_simulations):
        b_k1 = A.dot(b_k)
        norm = np.linalg.norm(b_k1)
        if norm < 1e-8: break
        b_k = b_k1 / norm
    return b_k

def extract_features(state, ec_matrix, cp_matrix, target_node, lineage_age, prev_target, radius=5):
    N_NODES = state.S_sparse[0].shape[0]
    N_AGENTS = len(state.pos)
    
    dists = np.abs(state.pos - target_node)
    dists = np.minimum(dists, N_NODES - dists)
    agents_in_radius = np.where(dists <= radius)[0]
    n_in_radius = len(agents_in_radius)
    
    # ---------------------------
    # 1. State Layer
    # ---------------------------
    local_dcr = 0.0
    local_triplets = 0
    ec_flow = 0.0
    cp_flow = 0.0
    
    if n_in_radius > 0:
        local_dcr = np.sum(state.agent_consumed_amt[agents_in_radius] >= 4.0) / n_in_radius
        agents_set = set(agents_in_radius)
        for (e, c, p_idx) in state.active_triplets:
            if e in agents_set and c in agents_set and p_idx in agents_set:
                local_triplets += 1
        ec_flow = np.sum(ec_matrix[np.ix_(agents_in_radius, agents_in_radius)])
        cp_flow = np.sum(cp_matrix[np.ix_(agents_in_radius, agents_in_radius)])

    # ---------------------------
    # 2. Trust Topology Layer
    # ---------------------------
    mean_degree = 0.0
    degree_variance = 0.0
    ev_centralization = 0.0
    
    if n_in_radius > 0:
        trust_sub = state.trust_matrix[np.ix_(agents_in_radius, agents_in_radius)]
        trust_edges = (trust_sub > 1.5).astype(np.float32)
        degrees = np.sum(trust_edges, axis=1)
        
        mean_degree = np.mean(degrees)
        degree_variance = np.var(degrees)
        
        ev_cent = power_iteration(trust_edges)
        if len(ev_cent) > 0 and np.mean(ev_cent) > 0:
            ev_centralization = np.max(ev_cent) / np.mean(ev_cent)

    # ---------------------------
    # 3. Dependency Topology Layer
    # ---------------------------
    supply_redundancy = mean_degree
    dci = 0.0
    if n_in_radius > 0:
        consumptions = state.agent_consumed_amt[agents_in_radius]
        top_20 = max(1, int(n_in_radius * 0.20))
        total_cons = np.sum(consumptions)
        if total_cons > 0:
            dci = np.sum(np.sort(consumptions)[-top_20:]) / total_cons

    # ---------------------------
    # 4. Spatial-Kinematic Layer
    # ---------------------------
    spatial_entropy = 0.0
    radius_gyration = 0.0
    comp_overlap = 0.0
    
    if n_in_radius > 0:
        local_pos = state.pos[agents_in_radius]
        # Align positions to center to avoid ring wrap issues
        aligned_pos = (local_pos - target_node + N_NODES // 2) % N_NODES
        counts = np.bincount(aligned_pos, minlength=N_NODES)
        p = counts[counts > 0] / n_in_radius
        spatial_entropy = -np.sum(p * np.log2(p))
        
        dists_to_center = np.abs(local_pos - target_node)
        dists_to_center = np.minimum(dists_to_center, N_NODES - dists_to_center)
        radius_gyration = np.sqrt(np.mean(dists_to_center**2))
        
    migration_vel = 0.0
    if prev_target is not None:
        dist_m = abs(target_node - prev_target)
        migration_vel = min(dist_m, N_NODES - dist_m)
        state.migration_history.append(migration_vel)
        if len(state.migration_history) > 50:
            state.migration_history.pop(0)
            
    migration_persistence = np.mean(state.migration_history) if len(state.migration_history) > 0 else 0.0
    
    # Competitive overlap (trace from other basins)
    left = max(0, target_node - radius)
    right = min(N_NODES, target_node + radius + 1)
    
    target_dominant = np.argmax([state.S_sparse[0][left:right, :].sum(),
                                 state.S_sparse[1][left:right, :].sum(),
                                 state.S_sparse[2][left:right, :].sum()])
    for t in range(3):
        if t != target_dominant:
            comp_overlap += state.S_sparse[t][left:right, :].sum()

    institution_strength = state.S_sparse[target_dominant][left:right, :].sum() / max(1, (right-left))
    
    # Pack v2 Genome
    x_inst_v2 = np.array([
        local_dcr, local_triplets, lineage_age, ec_flow, cp_flow, institution_strength, # State
        mean_degree, degree_variance, ev_centralization, # Trust Topology
        supply_redundancy, dci, # Dependency
        spatial_entropy, radius_gyration, migration_persistence, comp_overlap # Kinematic
    ], dtype=np.float32)
    
    # ---------------------------
    # Microstate & Geo Baseline
    # ---------------------------
    if n_in_radius > 0:
        pos_feat = state.pos[agents_in_radius].astype(np.float32) / N_NODES
        cons_feat = state.agent_consumed_amt[agents_in_radius]
        trust_feat = np.mean(state.trust_matrix[np.ix_(agents_in_radius, agents_in_radius)], axis=1)
        
        pos_pad = np.pad(pos_feat, (0, N_AGENTS - len(pos_feat)))[:N_AGENTS]
        cons_pad = np.pad(cons_feat, (0, N_AGENTS - len(cons_feat)))[:N_AGENTS]
        trust_pad = np.pad(trust_feat, (0, N_AGENTS - len(trust_feat)))[:N_AGENTS]
        x_micro = np.concatenate([pos_pad, cons_pad, trust_pad])
    else:
        x_micro = np.zeros(N_AGENTS * 3, dtype=np.float32)
        
    geo_density = n_in_radius
    geo_field_vol = institution_strength
    
    left_side = state.pos[state.pos < target_node]
    right_side = state.pos[state.pos > target_node]
    density_grad = len(right_side) - len(left_side)
    
    x_geo = np.array([geo_density, geo_field_vol, migration_persistence, density_grad], dtype=np.float32)
    x_rand = np.random.rand(15).astype(np.float32)
    
    return x_micro, x_inst_v2, x_rand, x_geo

def run_topological_tournament():
    np.random.seed(42)
    
    N_NODES = 10000
    N_AGENTS = 1000
    WALK_STEPS = 20
    RADIUS = 5
    MORTALITY_RATE = 0.0025
    MAX_PHI = 1.0
    DECAY = np.exp(-0.10)
    
    k_ring = RADIUS * 2
    neighbors, K_csr = generate_topology(N_NODES, k_ring=k_ring)
    
    niche = np.zeros(N_AGENTS, dtype=np.int32)
    niche[333:666] = 1 
    niche[666:] = 2   
    
    target_trace = np.zeros(N_AGENTS, dtype=np.int32)
    target_trace[niche == 0] = 0
    target_trace[niche == 1] = 0
    target_trace[niche == 2] = 1
    emit_trace = np.copy(niche)
    
    print("🌌 [REA-7N-B3] Booting Topological Institution Genome Tournament")
    print(f"Parameters: N_NODES={N_NODES}, N_AGENTS={N_AGENTS}, WALK_STEPS={WALK_STEPS}")
    
    deltas = [10, 50, 100, 250, 500]
    data_X = {d: {'X_m':[], 'X_i':[], 'X_r':[], 'X_g':[], 'Y':[]} for d in deltas}
    
    for env in range(3): 
        print(f"Running Universe {env+1}/3...")
        start_t = time.time()
        pos = np.random.randint(0, N_NODES, size=N_AGENTS)
        trust_matrix = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
        
        S_sparse = [
            sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32),
            sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32),
            sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32)
        ]
        
        agent_consumed_amt = np.zeros(N_AGENTS, dtype=np.float32)
        state = SimulatorState(pos, trust_matrix, S_sparse, niche, agent_consumed_amt, [])
        
        prev_target = None
        lineage_age = 0
        
        for epoch in range(100):
            run_simulation_step(state, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS)
            
        buffer = []
        
        for epoch in range(101, 801): 
            dcr, scp, ec, cp = run_simulation_step(state, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS)
            lineage_age += 1
            
            S_sum = np.array(state.S_sparse[0].sum(axis=1) + state.S_sparse[1].sum(axis=1) + state.S_sparse[2].sum(axis=1)).flatten()
            target_node = int(np.argmax(S_sum))
            
            if epoch % 2 == 0:
                xm, xi, xr, xg = extract_features(state, ec, cp, target_node, lineage_age, prev_target, RADIUS)
                buffer.append((epoch, xm, xi, xr, xg, target_node))
                
            prev_target = target_node
                
            for d in deltas:
                for b in buffer:
                    if epoch - b[0] == d:
                        old_target = b[5]
                        hazard_label = get_ternary_survival(state, old_target, RADIUS)
                        data_X[d]['X_m'].append(b[1])
                        data_X[d]['X_i'].append(b[2])
                        data_X[d]['X_r'].append(b[3])
                        data_X[d]['X_g'].append(b[4])
                        data_X[d]['Y'].append(hazard_label)
                        
            buffer = [b for b in buffer if epoch - b[0] <= max(deltas)]
            
            if epoch % 100 == 0:
                print(f"  Epoch {epoch} | DCR: {dcr:.3f} | Target: {target_node} | Time: {time.time() - start_t:.1f}s")
                start_t = time.time()
                
    print("\nTraining Random Forest Classifiers on Train/Test Splits (Multi-Class AUC OVR)...")
    print(f"{'Horizon':<10} | {'Micro':<8} | {'Geo':<8} | {'Inst':<8} | {'Rand':<8} | {'Classes (0/1/2)'}")
    
    for d in deltas:
        if len(data_X[d]['Y']) < 50: continue
        
        Y_all = np.array(data_X[d]['Y'])
        c0 = np.sum(Y_all == 0)
        c1 = np.sum(Y_all == 1)
        c2 = np.sum(Y_all == 2)
        
        classes_present = len(np.unique(Y_all))
        if classes_present < 2:
            print(f"Delta={d:<4} | No variance in collapse (all {c0}/{c1}/{c2})")
            continue
            
        X_m_tr, X_m_te, Y_tr, Y_te = train_test_split(data_X[d]['X_m'], data_X[d]['Y'], test_size=0.25, random_state=42)
        X_i_tr, X_i_te, _, _ = train_test_split(data_X[d]['X_i'], data_X[d]['Y'], test_size=0.25, random_state=42)
        X_r_tr, X_r_te, _, _ = train_test_split(data_X[d]['X_r'], data_X[d]['Y'], test_size=0.25, random_state=42)
        X_g_tr, X_g_te, _, _ = train_test_split(data_X[d]['X_g'], data_X[d]['Y'], test_size=0.25, random_state=42)
        
        rf_m = RandomForestClassifier(n_estimators=50, random_state=42)
        rf_i = RandomForestClassifier(n_estimators=50, random_state=42)
        rf_r = RandomForestClassifier(n_estimators=50, random_state=42)
        rf_g = RandomForestClassifier(n_estimators=50, random_state=42)
        
        rf_m.fit(X_m_tr, Y_tr)
        rf_i.fit(X_i_tr, Y_tr)
        rf_r.fit(X_r_tr, Y_tr)
        rf_g.fit(X_g_tr, Y_tr)
        
        try:
            auc_m = roc_auc_score(Y_te, rf_m.predict_proba(X_m_te), multi_class='ovr') if classes_present > 2 else roc_auc_score(Y_te, rf_m.predict_proba(X_m_te)[:, 1])
            auc_i = roc_auc_score(Y_te, rf_i.predict_proba(X_i_te), multi_class='ovr') if classes_present > 2 else roc_auc_score(Y_te, rf_i.predict_proba(X_i_te)[:, 1])
            auc_r = roc_auc_score(Y_te, rf_r.predict_proba(X_r_te), multi_class='ovr') if classes_present > 2 else roc_auc_score(Y_te, rf_r.predict_proba(X_r_te)[:, 1])
            auc_g = roc_auc_score(Y_te, rf_g.predict_proba(X_g_te), multi_class='ovr') if classes_present > 2 else roc_auc_score(Y_te, rf_g.predict_proba(X_g_te)[:, 1])
            
            print(f"Delta={d:<4} | {auc_m:<8.3f} | {auc_g:<8.3f} | {auc_i:<8.3f} | {auc_r:<8.3f} | {c0}/{c1}/{c2}")
        except Exception as e:
            print(f"Delta={d:<4} | Error computing AUC: {str(e)}")

if __name__ == "__main__":
    run_topological_tournament()
