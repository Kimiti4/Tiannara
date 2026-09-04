import numpy as np
import scipy.sparse as sp
import json
import os
from tiannara_ucc.core import extract_basin_metrics, compute_fri, compute_novelty_yield

# --- Phase 9A Clustering Logic to Classify Attractors ---
def get_kmeans_model():
    with open('data/archive/rea_trajectories.json', 'r') as f:
        archive = json.load(f)
        
    features = ['dcr_retention', 'scp_retention', 'mortality_rate', 'niche_skew',
                'trust_centralization_delta', 'path_entropy_delta', 'redundancy_delta',
                'novelty_rate', 'adaptation_velocity', 'control_effort_gradient']
                
    X_list = [[record['telemetry'][f] for f in features] for record in archive]
    X = np.array(X_list)
    
    mean = X.mean(axis=0)
    std = X.std(axis=0) + 1e-8
    X_norm = (X - mean) / std
    
    np.random.seed(42)
    k = 5
    centroids = X_norm[np.random.choice(X_norm.shape[0], k, replace=False)]
    for _ in range(100):
        distances = np.linalg.norm(X_norm[:, np.newaxis] - centroids, axis=2)
        labels = np.argmin(distances, axis=1)
        new_centroids = np.array([X_norm[labels == i].mean(axis=0) if np.sum(labels == i) > 0 else centroids[i] for i in range(k)])
        if np.allclose(centroids, new_centroids): break
        centroids = new_centroids
        
    return mean, std, centroids

def classify_attractor(telemetry, mean, std, centroids):
    features = ['dcr_retention', 'scp_retention', 'mortality_rate', 'niche_skew',
                'trust_centralization_delta', 'path_entropy_delta', 'redundancy_delta',
                'novelty_rate', 'adaptation_velocity', 'control_effort_gradient']
    x = np.array([telemetry[f] for f in features])
    x_norm = (x - mean) / std
    distances = np.linalg.norm(centroids - x_norm, axis=1)
    label = np.argmin(distances)
    
    archetypes = {
        0: "Rigid",
        1: "Brittle",
        2: "Plastic",
        3: "Explosive",
        4: "Zombie"
    }
    return archetypes[label]

def get_boundary_distance(telemetry):
    # Phase 9B boundary: Plastic Regenerative Horizon is SCP > 0.178
    return telemetry['scp_retention'] - 0.178

# --- Base Simulation Logic ---
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

class SimState:
    def __init__(self, pos, trust_matrix, S_sparse, niche, agent_consumed_amt, active_triplets):
        self.pos = np.copy(pos)
        self.trust_matrix = np.copy(trust_matrix)
        self.S_sparse = [s.copy() for s in S_sparse] if S_sparse else []
        self.niche = np.copy(niche)
        self.agent_consumed_amt = np.copy(agent_consumed_amt)
        self.active_triplets = set(active_triplets)
        
        self.target_node = 0
        self.dcr_400 = 0.0
        self.scp_400 = 0.0
        self.hubs_400 = set()
        self.trust_matrix_400 = None
        self.triplets_400 = set()
        self.agent_survival_rate = 1.0
        self.ce_spent = 0.0
        
    def copy(self):
        new_state = SimState(self.pos, self.trust_matrix, self.S_sparse, self.niche, self.agent_consumed_amt, self.active_triplets)
        new_state.target_node = self.target_node
        new_state.dcr_400 = self.dcr_400
        new_state.scp_400 = self.scp_400
        new_state.hubs_400 = self.hubs_400.copy()
        new_state.trust_matrix_400 = np.copy(self.trust_matrix_400) if self.trust_matrix_400 is not None else None
        new_state.triplets_400 = self.triplets_400.copy()
        new_state.agent_survival_rate = self.agent_survival_rate
        new_state.ce_spent = self.ce_spent
        return new_state

def run_step(state, epoch, neighbors, K_csr, target_trace, emit_trace, MORTALITY_RATE, WALK_STEPS, regime, rule_severity=1.0):
    N_AGENTS = len(state.pos)
    N_NODES = K_csr.shape[0]
    K_RING = neighbors.shape[1]
    
    gamma_persistence = 0.9048
    rho_signal = 2.5
    alpha_trust_gain = 0.1
    alpha_trust_decay = rule_severity
    tau_explore = 0.05
    
    if regime == 'preserve':
        tau_explore = 0.01
    elif regime == 'repair':
        tau_explore = 0.50
        gamma_persistence = 0.95
        alpha_trust_gain = 0.3
    elif regime == 'explore':
        tau_explore = 5.0
        gamma_persistence = 0.50
    elif regime == 'triage':
        if state.agent_survival_rate < 0.9:
            counts = np.bincount(state.niche, minlength=3)
            if counts[1] < N_AGENTS // 3:
                candidates = np.where(state.niche != 1)[0]
                if len(candidates) > 0:
                    c = candidates[0]
                    state.niche[c] = 1
                    target_trace[c] = 0
                    emit_trace[c] = 1
                    state.ce_spent += 5.0
        S_sum = np.array(state.S_sparse[0].sum(axis=0) + state.S_sparse[1].sum(axis=0) + state.S_sparse[2].sum(axis=0)).flatten()
        if len(S_sum) > 0 and S_sum.max() > 0:
            true_hub = int(np.argmax(S_sum))
            for i in range(10): 
                idx = np.random.randint(0, N_AGENTS)
                state.trust_matrix[idx, true_hub] = 3.0
                state.ce_spent += 1.0

    state.agent_consumed_amt[:] = 0.0
    E_rows = [[], [], []]; E_cols = [[], [], []]; E_data = [[], [], []]
    C_rows = [[], [], []]; C_cols = [[], [], []]; C_data = [[], [], []]
    last_consumed_from = np.full(N_AGENTS, -1, dtype=np.int32)
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
        best_idx = np.argmax(phi + noise, axis=1)
        state.pos = c_nodes[agents_arange, best_idx]
        
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
            
            explore_score = available + tau_explore * np.random.gumbel(size=len(authors))
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
            E_rows[t].append(state.pos[a]); E_cols[t].append(a); E_data[t].append(rho_signal)
            
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

def extract_10d_telemetry(state_prev, state_curr, n_nodes):
    ucc_curr = extract_basin_metrics(state_curr.pos, state_curr.trust_matrix, state_curr.agent_consumed_amt, state_curr.active_triplets, state_curr.target_node, n_nodes)
    ucc_prev = extract_basin_metrics(state_prev.pos, state_prev.trust_matrix, state_prev.agent_consumed_amt, state_prev.active_triplets, state_prev.target_node, n_nodes)
    
    dcr_retention = ucc_curr['dcr'] / max(0.1, state_curr.dcr_400)
    scp_retention = ucc_curr['scp'] / max(1, state_curr.scp_400)
    mortality = 1.0 - state_curr.agent_survival_rate
    counts = np.bincount(state_curr.niche, minlength=3)
    niche_skew = np.std(counts / max(1, counts.sum()))
    trust_cent_curr = np.std(ucc_curr['trust_centrality_global'])
    trust_cent_prev = np.std(ucc_prev['trust_centrality_global'])
    
    return {
        'dcr_retention': float(dcr_retention),
        'scp_retention': float(scp_retention),
        'mortality_rate': float(mortality),
        'niche_skew': float(niche_skew),
        'trust_centralization_delta': float(trust_cent_curr - trust_cent_prev),
        'path_entropy_delta': float(ucc_curr['spatial_entropy'] - ucc_prev['spatial_entropy']),
        'redundancy_delta': float(ucc_curr['redundancy'] - ucc_prev['redundancy']),
        'novelty_rate': float(len(set(state_curr.active_triplets) - set(state_prev.active_triplets)) / max(1.0, len(state_prev.active_triplets))),
        'adaptation_velocity': float(dcr_retention - (ucc_prev['dcr'] / max(0.1, state_curr.dcr_400))),
        'control_effort_gradient': float(state_curr.ce_spent - state_prev.ce_spent)
    }

def calculate_outcome(state_400, state_curr, n_nodes):
    ucc_curr = extract_basin_metrics(state_curr.pos, state_curr.trust_matrix, state_curr.agent_consumed_amt, state_curr.active_triplets, state_curr.target_node, n_nodes)
    fri = compute_fri(ucc_curr['dcr'], ucc_curr['scp'], ucc_curr['trust_centrality_global'], state_curr.dcr_400, state_curr.scp_400, state_curr.hubs_400)
    return fri

def extract_dynamics():
    mean_geom, std_geom, centroids_geom = get_kmeans_model()
    
    np.random.seed(42)
    N_NODES = 1000; N_AGENTS = 100; WALK_STEPS = 10; RADIUS = 5; MORTALITY_RATE = 0.0025
    
    neighbors, K_csr = generate_topology(N_NODES, k_ring=RADIUS*2)
    niche = np.zeros(N_AGENTS, dtype=np.int32)
    niche[33:66] = 1; niche[66:] = 2   
    target_trace = np.zeros(N_AGENTS, dtype=np.int32)
    target_trace[niche == 0] = 0; target_trace[niche == 1] = 0; target_trace[niche == 2] = 1
    emit_trace = np.copy(niche)
    
    print("🌌 [Phase 9C/10] Booting Dynamics Archive Extractor")
    
    pos = np.random.randint(0, N_NODES, size=N_AGENTS)
    trust_matrix = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S_sparse = [sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32) for _ in range(3)]
    state = SimState(pos, trust_matrix, S_sparse, niche, np.zeros(N_AGENTS, dtype=np.float32), [])
    
    for epoch in range(1, 401):
        run_step(state, epoch, neighbors, K_csr, target_trace, emit_trace, MORTALITY_RATE, WALK_STEPS, 'repair')
        if epoch >= 380:
            ucc = extract_basin_metrics(state.pos, state.trust_matrix, state.agent_consumed_amt, state.active_triplets, state.target_node, N_NODES)
            state.dcr_400 = max(state.dcr_400, ucc['dcr'])
            state.scp_400 = max(state.scp_400, ucc['scp'])
            state.hubs_400 = state.hubs_400.union(set(np.argsort(ucc['trust_centrality_global'])[-max(1, int(N_AGENTS * 0.10)):]))
            state.triplets_400 = state.triplets_400.union(set(state.active_triplets))
            
    print(f"\n[Baseline 400 Locked] DCR={state.dcr_400:.3f}")
    state_400 = state.copy()
    
    shocks = ['Resource', 'Population', 'Knowledge', 'Mixed']
    dynamics_archive = []
    
    for shock in shocks:
        print(f"\n[Extracting High-Res Dynamics: {shock}]")
        st = state_400.copy()
        tt = np.copy(target_trace); et = np.copy(emit_trace)
        
        # Apply Shock
        if shock in ['Resource', 'Mixed']:
            for t in range(3):
                nnz = st.S_sparse[t].nnz
                if nnz > 0:
                    drop_idx = np.random.choice(nnz, int(nnz * 0.8), replace=False)
                    st.S_sparse[t].data[drop_idx] = 0.0
                    st.S_sparse[t].eliminate_zeros()
        if shock in ['Population', 'Mixed']:
            compressors = np.where(st.niche == 1)[0]
            dead = np.random.choice(compressors, int(len(compressors) * 0.7), replace=False)
            st.agent_survival_rate -= (len(dead)/N_AGENTS)
            for a in dead:
                st.trust_matrix[a, :] = 1.0
                st.niche[a] = np.random.choice([0, 2])
                tt[a] = 0 if st.niche[a] == 0 else 1
                et[a] = 0 if st.niche[a] == 0 else 2
                
        prev_trunk = st.copy()
        
        # Epoch-by-Epoch Extraction
        for step in range(30): # 30 epochs high resolution to capture drift velocity
            current_epoch = 400 + step + 1
            
            # Branch counterfactuals from prev_trunk to find the greedy oracle
            best_fri = -1; best_regime = None
            active_fris = []
            baseline_fri = 0.0
            
            for regime in ['preserve', 'repair', 'explore', 'triage']:
                branch = prev_trunk.copy()
                for _ in range(10):
                    run_step(branch, current_epoch + _, neighbors, K_csr, tt, et, MORTALITY_RATE, WALK_STEPS, regime)
                fri = calculate_outcome(state_400, branch, N_NODES)
                if regime == 'preserve': baseline_fri = fri
                else: active_fris.append(fri)
                if fri > best_fri:
                    best_fri = fri
                    best_regime = regime
                    
            recoverability = best_fri
            elasticity = max(0, max(active_fris) - baseline_fri)
            
            # Step the main trunk forward by 1 using the oracle strategy to trace the actual Phase 9 path
            current_trunk = prev_trunk.copy()
            run_step(current_trunk, current_epoch, neighbors, K_csr, tt, et, MORTALITY_RATE, WALK_STEPS, best_regime)
            
            telemetry = extract_10d_telemetry(prev_trunk, current_trunk, N_NODES)
            attractor = classify_attractor(telemetry, mean_geom, std_geom, centroids_geom)
            bd = get_boundary_distance(telemetry)
            
            record = {
                'epoch': current_epoch,
                'shock': shock,
                'telemetry': telemetry,
                'constitution': best_regime, # The required regime coordinate
                'attractor': attractor,
                'recoverability': recoverability,
                'elasticity': elasticity,
                'boundary_distance': bd
            }
            dynamics_archive.append(record)
            print(f"  Epoch {current_epoch} | Attractor: {attractor:<10} | Rec: {recoverability:.3f} | AE: {elasticity:.3f} | Dist: {bd:.3f}")
            
            prev_trunk = current_trunk
            
    with open('data/archive/rea_dynamics_archive.json', 'w') as f:
        json.dump(dynamics_archive, f, indent=2)
    print("\n✅ Dynamics Archive Complete. Stored 120 high-res sliding windows.")

if __name__ == "__main__":
    extract_dynamics()
