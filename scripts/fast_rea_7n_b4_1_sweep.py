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

class SimulatorState:
    def __init__(self, pos, trust_matrix, S_sparse, niche, agent_consumed_amt, active_triplets):
        self.pos = np.copy(pos)
        self.trust_matrix = np.copy(trust_matrix)
        self.S_sparse = [s.copy() for s in S_sparse] if S_sparse else []
        self.niche = np.copy(niche)
        self.agent_consumed_amt = np.copy(agent_consumed_amt)
        self.active_triplets = set(active_triplets)
        
    def copy(self):
        return SimulatorState(self.pos, self.trust_matrix, self.S_sparse, self.niche, self.agent_consumed_amt, self.active_triplets)

def run_simulation_step(state, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS):
    N_AGENTS = len(state.pos)
    N_NODES = K_csr.shape[0]
    
    state.agent_consumed_amt[:] = 0.0
    E_rows = [[], [], []]; E_cols = [[], [], []]; E_data = [[], [], []]
    C_rows = [[], [], []]; C_cols = [[], [], []]; C_data = [[], [], []]
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
            
    state.trust_matrix = np.maximum(1.0, state.trust_matrix * 0.99)
    dead_agents = np.where(np.random.rand(N_AGENTS) < MORTALITY_RATE)[0]
    for a in dead_agents:
        state.trust_matrix[a, :] = 1.0 
        state.agent_consumed_amt[a] = 0.0
        
    dcr = np.sum(state.agent_consumed_amt[state.niche > 0] >= 4.0) / max(1, np.sum(state.niche > 0))
    scp = len(state.active_triplets)
    return dcr, scp

def get_local_metrics(state, target_node, radius=5):
    N_NODES = state.S_sparse[0].shape[0]
    dists = np.abs(state.pos - target_node)
    dists = np.minimum(dists, N_NODES - dists)
    agents_in_radius = np.where(dists <= radius)[0]
    
    if len(agents_in_radius) == 0:
        return 0.0, 0, 0
        
    local_dcr = np.sum(state.agent_consumed_amt[agents_in_radius] >= 4.0) / max(1, len(agents_in_radius))
    
    local_triplets = 0
    agents_set = set(agents_in_radius)
    for (e, c, p_idx) in state.active_triplets:
        if e in agents_set and c in agents_set and p_idx in agents_set:
            local_triplets += 1
            
    surv = 0
    if local_dcr < 0.5 or local_triplets == 0:
        surv = 0
    elif local_dcr > 0.8 and local_triplets >= 2:
        surv = 2
    else:
        surv = 1
        
    return local_dcr, local_triplets, surv

def apply_redundancy_boost(state, target_node, pct_boost, radius=5):
    s_boost = state.copy()
    if pct_boost == 0.0:
        return s_boost
        
    N_NODES = state.S_sparse[0].shape[0]
    dists = np.abs(state.pos - target_node)
    dists = np.minimum(dists, N_NODES - dists)
    agents_in_radius = np.where(dists <= radius)[0]
    
    if len(agents_in_radius) == 0:
        return s_boost
        
    base_mass = np.sum(s_boost.trust_matrix[np.ix_(agents_in_radius, agents_in_radius)] - 1.0)
    if base_mass > 0:
        edges_added = 0
        target_new_edges = int(len(agents_in_radius) * pct_boost) 
        while edges_added < target_new_edges:
            a = np.random.choice(agents_in_radius)
            b = np.random.choice(agents_in_radius)
            if a != b and s_boost.trust_matrix[a, b] == 1.0:
                s_boost.trust_matrix[a, b] += 2.0
                edges_added += 1
                
        new_mass = np.sum(s_boost.trust_matrix[np.ix_(agents_in_radius, agents_in_radius)] - 1.0)
        ratio = base_mass / max(1e-6, new_mass)
        for a in agents_in_radius:
            for b in agents_in_radius:
                if s_boost.trust_matrix[a, b] > 1.0:
                    s_boost.trust_matrix[a, b] = 1.0 + (s_boost.trust_matrix[a, b] - 1.0) * ratio
    return s_boost

def run_b4_1_sweep():
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
    target_trace[niche == 0] = 0; target_trace[niche == 1] = 0; target_trace[niche == 2] = 1
    emit_trace = np.copy(niche)
    
    print("🌌 [REA-7N-B4.1] Booting Redundancy Sweep Tournament")
    
    pos = np.random.randint(0, N_NODES, size=N_AGENTS)
    trust_matrix = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S_sparse = [sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32) for _ in range(3)]
    state = SimulatorState(pos, trust_matrix, S_sparse, niche, np.zeros(N_AGENTS, dtype=np.float32), [])
    
    print("\nPhase 1: Running Target Universe to Epoch 400...")
    for epoch in range(1, 401):
        dcr, scp = run_simulation_step(state, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS)
        if epoch % 100 == 0:
            print(f"  Target Universe Epoch {epoch} | DCR: {dcr:.3f} | SCP: {scp}")
            
    S_sum = np.array(state.S_sparse[0].sum(axis=1) + state.S_sparse[1].sum(axis=1) + state.S_sparse[2].sum(axis=1)).flatten()
    target_node = int(np.argmax(S_sum))
    
    print(f"\nPhase 2: Applying Redundancy Sweeps at dominant basin {target_node}")
    boosts = {"Baseline": 0.0, "Boost_05": 0.05, "Boost_10": 0.10, "Boost_20": 0.20, "Boost_40": 0.40, "Boost_80": 0.80}
    
    results = {}
    
    for name, pct in boosts.items():
        print(f"\nExecuting {name} (+{pct*100:.0f}%)...")
        st = apply_redundancy_boost(state, target_node, pct, RADIUS)
        
        d100_res, d250_res = None, None
        
        for epoch in range(401, 651):
            dcr, scp = run_simulation_step(st, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS)
            
            if epoch == 500:
                ldcr, ltrips, surv = get_local_metrics(st, target_node, RADIUS)
                d100_res = (ldcr, ltrips, surv)
                print(f"  Epoch 500 (Δ100) | Local DCR: {ldcr:.3f} | Triplets: {ltrips} | Surv: {surv}")
            elif epoch == 650:
                ldcr, ltrips, surv = get_local_metrics(st, target_node, RADIUS)
                d250_res = (ldcr, ltrips, surv)
                print(f"  Epoch 650 (Δ250) | Local DCR: {ldcr:.3f} | Triplets: {ltrips} | Surv: {surv}")
                
        results[name] = {"d100": d100_res, "d250": d250_res}
        
    print("\n========================================================")
    print("REA-7N-B4.1 Institutional Fitness vs Redundancy Curve")
    print("========================================================")
    print(f"{'Branch':<15} | {'D100 Surv':<9} | {'D100 Trip':<9} | {'D250 Surv':<9} | {'D250 Trip':<9}")
    for name in boosts.keys():
        d100 = results[name]["d100"]
        d250 = results[name]["d250"]
        print(f"{name:<15} | {d100[2]:<9} | {d100[1]:<9} | {d250[2]:<9} | {d250[1]:<9}")

if __name__ == "__main__":
    run_b4_1_sweep()
