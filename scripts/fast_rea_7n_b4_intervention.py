import numpy as np
import scipy.sparse as sp
import time
from sklearn.ensemble import RandomForestClassifier

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
        self.migration_history = []
        
    def copy(self):
        new_state = SimulatorState(self.pos, self.trust_matrix, self.S_sparse, self.niche, self.agent_consumed_amt, self.active_triplets)
        new_state.migration_history = list(self.migration_history)
        return new_state

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
    
    local_dcr, local_triplets, ec_flow, cp_flow = 0.0, 0, 0.0, 0.0
    mean_degree, degree_variance, ev_centralization = 0.0, 0.0, 0.0
    supply_redundancy, dci = 0.0, 0.0
    spatial_entropy, radius_gyration, comp_overlap = 0.0, 0.0, 0.0
    
    if n_in_radius > 0:
        local_dcr = np.sum(state.agent_consumed_amt[agents_in_radius] >= 4.0) / n_in_radius
        agents_set = set(agents_in_radius)
        for (e, c, p_idx) in state.active_triplets:
            if e in agents_set and c in agents_set and p_idx in agents_set:
                local_triplets += 1
        ec_flow = np.sum(ec_matrix[np.ix_(agents_in_radius, agents_in_radius)])
        cp_flow = np.sum(cp_matrix[np.ix_(agents_in_radius, agents_in_radius)])

        trust_sub = state.trust_matrix[np.ix_(agents_in_radius, agents_in_radius)]
        trust_edges = (trust_sub > 1.5).astype(np.float32)
        degrees = np.sum(trust_edges, axis=1)
        mean_degree = np.mean(degrees)
        degree_variance = np.var(degrees)
        ev_cent = power_iteration(trust_edges)
        if len(ev_cent) > 0 and np.mean(ev_cent) > 0:
            ev_centralization = np.max(ev_cent) / np.mean(ev_cent)

        supply_redundancy = mean_degree
        consumptions = state.agent_consumed_amt[agents_in_radius]
        top_20 = max(1, int(n_in_radius * 0.20))
        total_cons = np.sum(consumptions)
        if total_cons > 0:
            dci = np.sum(np.sort(consumptions)[-top_20:]) / total_cons

        local_pos = state.pos[agents_in_radius]
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
    
    left = max(0, target_node - radius)
    right = min(N_NODES, target_node + radius + 1)
    target_dominant = np.argmax([state.S_sparse[0][left:right, :].sum(),
                                 state.S_sparse[1][left:right, :].sum(),
                                 state.S_sparse[2][left:right, :].sum()])
    for t in range(3):
        if t != target_dominant:
            comp_overlap += state.S_sparse[t][left:right, :].sum()

    institution_strength = state.S_sparse[target_dominant][left:right, :].sum() / max(1, (right-left))
    
    x_inst_v2 = np.array([
        local_dcr, local_triplets, lineage_age, ec_flow, cp_flow, institution_strength,
        mean_degree, degree_variance, ev_centralization,
        supply_redundancy, dci,
        spatial_entropy, radius_gyration, migration_persistence, comp_overlap
    ], dtype=np.float32)
    
    return x_inst_v2

def apply_interventions(state, target_node, radius=5):
    """
    Forks the state into 4 counterfactuals: Base, DCI Shock, Random Shock, Redundancy Boost.
    """
    s_base = state.copy()
    s_dci = state.copy()
    s_rand = state.copy()
    s_boost = state.copy()
    
    N_NODES = state.S_sparse[0].shape[0]
    N_AGENTS = len(state.pos)
    
    dists = np.abs(state.pos - target_node)
    dists = np.minimum(dists, N_NODES - dists)
    agents_in_radius = np.where(dists <= radius)[0]
    
    if len(agents_in_radius) == 0:
        return s_base, s_dci, s_rand, s_boost, 0.0
        
    # --- DCI Shock ---
    # Find top 5% hubs by incoming trust
    sub_trust = s_dci.trust_matrix[np.ix_(agents_in_radius, agents_in_radius)]
    in_trust = np.sum(np.maximum(0, sub_trust - 1.0), axis=0)
    top_5 = max(1, int(len(agents_in_radius) * 0.05))
    hub_local_indices = np.argsort(in_trust)[-top_5:]
    hub_global_indices = agents_in_radius[hub_local_indices]
    
    trust_removed = 0.0
    for hub_g in hub_global_indices:
        for a_g in agents_in_radius:
            if s_dci.trust_matrix[a_g, hub_g] > 1.0:
                trust_removed += (s_dci.trust_matrix[a_g, hub_g] - 1.0)
                s_dci.trust_matrix[a_g, hub_g] = 1.0

    # --- Random Shock ---
    # Remove random trust edges until exact `trust_removed` volume is achieved
    edges_to_reduce = []
    for a in agents_in_radius:
        for b in agents_in_radius:
            if s_rand.trust_matrix[a, b] > 1.0:
                edges_to_reduce.append((a, b))
    
    np.random.shuffle(edges_to_reduce)
    random_removed = 0.0
    for (a, b) in edges_to_reduce:
        if random_removed >= trust_removed:
            break
        val = s_rand.trust_matrix[a, b] - 1.0
        take = min(val, trust_removed - random_removed)
        s_rand.trust_matrix[a, b] -= take
        random_removed += take

    # --- Redundancy Boost ---
    # Add new edges to increase mean degree, normalize total mass
    base_mass = np.sum(s_boost.trust_matrix[np.ix_(agents_in_radius, agents_in_radius)] - 1.0)
    if base_mass > 0:
        # Increase edges
        edges_added = 0
        target_new_edges = int(len(agents_in_radius) * 1.5) # +1.5 mean degree
        while edges_added < target_new_edges:
            a = np.random.choice(agents_in_radius)
            b = np.random.choice(agents_in_radius)
            if a != b and s_boost.trust_matrix[a, b] == 1.0:
                s_boost.trust_matrix[a, b] += 2.0
                edges_added += 1
                
        new_mass = np.sum(s_boost.trust_matrix[np.ix_(agents_in_radius, agents_in_radius)] - 1.0)
        # Normalize
        ratio = base_mass / max(1e-6, new_mass)
        for a in agents_in_radius:
            for b in agents_in_radius:
                if s_boost.trust_matrix[a, b] > 1.0:
                    s_boost.trust_matrix[a, b] = 1.0 + (s_boost.trust_matrix[a, b] - 1.0) * ratio

    return s_base, s_dci, s_rand, s_boost, trust_removed


def run_b4_tournament():
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
    
    print("🌌 [REA-7N-B4] Booting Macro Intervention Tournament")
    
    # --- Pre-Train Phase (Universe 1) ---
    print("\nPhase 1: Pre-training InstitutionGenome_v2 model on baseline Universe 1...")
    pos = np.random.randint(0, N_NODES, size=N_AGENTS)
    trust_matrix = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S_sparse = [sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32) for _ in range(3)]
    state_u1 = SimulatorState(pos, trust_matrix, S_sparse, niche, np.zeros(N_AGENTS, dtype=np.float32), [])
    
    prev_target = None
    lineage_age = 0
    buffer_u1 = []
    
    X_train_100, Y_train_100 = [], []
    X_train_250, Y_train_250 = [], []
    
    for epoch in range(1, 651):
        _, _, ec, cp = run_simulation_step(state_u1, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS)
        lineage_age += 1
        S_sum = np.array(state_u1.S_sparse[0].sum(axis=1) + state_u1.S_sparse[1].sum(axis=1) + state_u1.S_sparse[2].sum(axis=1)).flatten()
        target_node = int(np.argmax(S_sum))
        
        if epoch > 100 and epoch % 5 == 0:
            x_inst = extract_features(state_u1, ec, cp, target_node, lineage_age, prev_target, RADIUS)
            buffer_u1.append((epoch, x_inst, target_node))
            
        for b in buffer_u1:
            if epoch - b[0] == 100:
                y = get_ternary_survival(state_u1, b[2], RADIUS)
                X_train_100.append(b[1])
                Y_train_100.append(1 if y > 0 else 0)
            elif epoch - b[0] == 250:
                y = get_ternary_survival(state_u1, b[2], RADIUS)
                X_train_250.append(b[1])
                Y_train_250.append(1 if y > 0 else 0)
                
        prev_target = target_node
        
    print(f"Training Baseline Random Forests... (Samples: D100={len(Y_train_100)}, D250={len(Y_train_250)})")
    rf_100 = RandomForestClassifier(n_estimators=50, random_state=42)
    rf_250 = RandomForestClassifier(n_estimators=50, random_state=42)
    if len(np.unique(Y_train_100)) > 1: rf_100.fit(X_train_100, Y_train_100)
    if len(np.unique(Y_train_250)) > 1: rf_250.fit(X_train_250, Y_train_250)
    
    # --- Intervention Phase (Universe 2) ---
    print("\nPhase 2: Running Target Universe to Epoch 400...")
    pos = np.random.randint(0, N_NODES, size=N_AGENTS)
    trust_matrix = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S_sparse = [sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32) for _ in range(3)]
    state = SimulatorState(pos, trust_matrix, S_sparse, niche, np.zeros(N_AGENTS, dtype=np.float32), [])
    prev_target = None
    lineage_age = 0
    
    for epoch in range(1, 401):
        dcr, scp, ec, cp = run_simulation_step(state, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS)
        lineage_age += 1
        S_sum = np.array(state.S_sparse[0].sum(axis=1) + state.S_sparse[1].sum(axis=1) + state.S_sparse[2].sum(axis=1)).flatten()
        target_node = int(np.argmax(S_sum))
        prev_target = target_node
        if epoch % 100 == 0:
            print(f"  Target Universe Epoch {epoch} | DCR: {dcr:.3f}")
            
    # Predict before shock
    x_inst = extract_features(state, ec, cp, target_node, lineage_age, prev_target, RADIUS)
    p100 = rf_100.predict_proba([x_inst])[0][1] if hasattr(rf_100, 'classes_') else 0.0
    p250 = rf_250.predict_proba([x_inst])[0][1] if hasattr(rf_250, 'classes_') else 0.0
    print(f"\n[Pre-Shock Prediction] RF Model Forecast for target basin at {target_node}:")
    print(f"  P(Survival at Δ100) = {p100:.2f}")
    print(f"  P(Survival at Δ250) = {p250:.2f}")
    
    # Fork State
    print("\nApplying Flow-Matched Topological Interventions...")
    s_base, s_dci, s_rand, s_boost, trust_rem = apply_interventions(state, target_node, RADIUS)
    print(f"  Micro-Trust Severed (Matched exactly between DCI & Random): {trust_rem:.2f}")
    
    states = {"Baseline": s_base, "DCI_Shock": s_dci, "Random_Shock": s_rand, "Redundancy_Boost": s_boost}
    results_d100 = {}
    results_d250 = {}
    
    for name, st in states.items():
        print(f"\nRunning {name} branch (Epoch 401-650)...")
        ptarget = target_node
        for epoch in range(401, 651):
            dcr, scp, _, _ = run_simulation_step(st, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS)
            S_sum = np.array(st.S_sparse[0].sum(axis=1) + st.S_sparse[1].sum(axis=1) + st.S_sparse[2].sum(axis=1)).flatten()
            ptarget = int(np.argmax(S_sum))
            
            if epoch == 500:
                y = get_ternary_survival(st, target_node, RADIUS) # measure against original anchor
                results_d100[name] = {"dcr": dcr, "surv": y}
                print(f"  Epoch 500 (Δ100) | DCR: {dcr:.3f} | Surv: {y}")
            elif epoch == 650:
                y = get_ternary_survival(st, target_node, RADIUS)
                results_d250[name] = {"dcr": dcr, "surv": y}
                print(f"  Epoch 650 (Δ250) | DCR: {dcr:.3f} | Surv: {y}")
                
    print("\n=============================================")
    print("REA-7N-B4 Causal Intervention Results (Δ100)")
    print("=============================================")
    print(f"Pre-Shock Genome Prediction: {p100:.2f} Survival Probability")
    print(f"{'Branch':<20} | {'DCR':<6} | {'Status (0=Col, 1=Deg, 2=Thr)'}")
    for name in ["Baseline", "Random_Shock", "Redundancy_Boost", "DCI_Shock"]:
        res = results_d100[name]
        print(f"{name:<20} | {res['dcr']:<6.3f} | {res['surv']}")

    print("\n=============================================")
    print("REA-7N-B4 Causal Intervention Results (Δ250)")
    print("=============================================")
    print(f"Pre-Shock Genome Prediction: {p250:.2f} Survival Probability")
    print(f"{'Branch':<20} | {'DCR':<6} | {'Status (0=Col, 1=Deg, 2=Thr)'}")
    for name in ["Baseline", "Random_Shock", "Redundancy_Boost", "DCI_Shock"]:
        res = results_d250[name]
        print(f"{name:<20} | {res['dcr']:<6.3f} | {res['surv']}")

if __name__ == "__main__":
    run_b4_tournament()
