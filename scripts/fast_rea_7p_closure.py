import numpy as np
import scipy.sparse as sp
import time
from tiannara_ucc.core import extract_basin_metrics, compute_fri

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
        
    def copy(self):
        new_state = SimState(self.pos, self.trust_matrix, self.S_sparse, self.niche, self.agent_consumed_amt, self.active_triplets)
        new_state.target_node = self.target_node
        new_state.dcr_400 = self.dcr_400
        new_state.scp_400 = self.scp_400
        new_state.hubs_400 = self.hubs_400.copy()
        new_state.trust_matrix_400 = np.copy(self.trust_matrix_400) if self.trust_matrix_400 is not None else None
        return new_state

def run_step(state, epoch, neighbors, K_csr, target_trace, emit_trace, MORTALITY_RATE, WALK_STEPS, world_mode='C', ce_budget=0.0, shock_type=None, rule_severity=1.0):
    N_AGENTS = len(state.pos)
    N_NODES = K_csr.shape[0]
    K_RING = neighbors.shape[1]
    
    ucc = extract_basin_metrics(state.pos, state.trust_matrix, state.agent_consumed_amt, state.active_triplets, state.target_node, N_NODES)
    
    gamma_persistence = 0.9048
    rho_signal = 2.5
    alpha_trust_gain = 0.1
    alpha_trust_decay = 0.99
    tau_explore = 0.05
    
    if shock_type == 'Rule':
        alpha_trust_decay = rule_severity
        
    CE_spent = 0.0
    fri = compute_fri(ucc['dcr'], ucc['scp'], ucc['trust_centrality_global'], state.dcr_400, state.scp_400, state.hubs_400)
    
    if world_mode == 'C':
        if fri < 0.85:
            melt_factor = (0.85 - fri) / 0.85 
            gamma_persistence = 0.9048 + 0.08 * melt_factor
            if shock_type == 'Knowledge':
                gamma_persistence = 0.80 
            rho_signal = 2.5 + 2.5 * melt_factor
            alpha_trust_gain = 0.1 + 0.4 * melt_factor
            alpha_trust_decay_c = 0.99 - 0.09 * melt_factor
            if shock_type != 'Rule':
                alpha_trust_decay = alpha_trust_decay_c
            tau_explore = 0.05 + 0.95 * melt_factor
            CE_spent = 50.0 * melt_factor
        elif fri >= 0.95:
            gamma_persistence = 0.85
            tau_explore = 0.01
            CE_spent = 5.0
            
    if world_mode == 'M' and ce_budget > 0:
        budget = ce_budget
        if shock_type == 'Resource':
            poor = np.where(state.agent_consumed_amt < 1.0)[0]
            for a in poor:
                if budget <= 0: break
                state.agent_consumed_amt[a] += 1.0
                budget -= 1.0
                CE_spent += 1.0
        elif shock_type == 'Population':
            counts = np.bincount(state.niche, minlength=3)
            target = N_AGENTS // 3
            while budget >= 5.0 and (counts[1] < target):
                candidates = np.where(state.niche != 1)[0]
                if len(candidates) > 0:
                    c = candidates[0]
                    state.niche[c] = 1
                    target_trace[c] = 0
                    emit_trace[c] = 1
                    counts[1] += 1
                    budget -= 5.0
                    CE_spent += 5.0
                else:
                    break
        elif shock_type == 'Knowledge':
            # Competent M: Identify deceptive edges, remove them, recompute true hubs
            S_sum = np.array(state.S_sparse[0].sum(axis=0) + state.S_sparse[1].sum(axis=0) + state.S_sparse[2].sum(axis=0)).flatten()
            true_hubs = np.argsort(S_sum)[-10:] # nodes with most resources generated
            for i in range(N_AGENTS):
                if budget <= 0: break
                high_edges = np.where(state.trust_matrix[i] > 1.5)[0]
                for he in high_edges:
                    if budget <= 0: break
                    # If target has no resources, it's deceptive
                    if S_sum[he] < 1.0:
                        state.trust_matrix[i, he] = 1.0 # sever
                        budget -= 0.5
                        CE_spent += 0.5
                        
                        # Recompute to a true hub
                        if len(true_hubs) > 0:
                            new_hub = np.random.choice(true_hubs)
                            state.trust_matrix[i, new_hub] = 3.0
                            budget -= 0.5
                            CE_spent += 0.5
                            
        elif shock_type == 'Rule':
            # Competent M: Detects decay dropped to 0.80. Counteracts explicitly
            # by adding 0.20 to all edges that were high-trust in epoch 400
            diff = 0.99 - rule_severity
            if diff > 0 and state.trust_matrix_400 is not None:
                old_edges = np.where(state.trust_matrix_400 > 1.5)
                for i, j in zip(old_edges[0], old_edges[1]):
                    if budget <= 0: break
                    state.trust_matrix[i, j] += diff
                    budget -= diff
                    CE_spent += diff
                
    state.agent_consumed_amt[:] = 0.0
    E_rows = [[], [], []]; E_cols = [[], [], []]; E_data = [[], [], []]
    C_rows = [[], [], []]; C_cols = [[], [], []]; C_data = [[], [], []]
    state.active_triplets.clear()
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
        total_phi = phi + noise
        
        best_idx = np.argmax(total_phi, axis=1)
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
            
            gumbel_noise = np.random.gumbel(size=len(authors))
            explore_score = available + tau_explore * gumbel_noise
                
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
        
    return CE_spent, fri, tau_explore

def apply_shock(state_in, target_trace, emit_trace, shock_type, severity_level):
    state = state_in.copy()
    N_AGENTS = len(state.pos)
    
    if shock_type == 'Resource':
        frac = {'Moderate': 0.3, 'Severe': 0.7, 'Existential': 0.95}[severity_level]
        for t in range(3):
            nnz = state.S_sparse[t].nnz
            if nnz > 0:
                drop_idx = np.random.choice(nnz, int(nnz * frac), replace=False)
                state.S_sparse[t].data[drop_idx] = 0.0
                state.S_sparse[t].eliminate_zeros()
                
    elif shock_type == 'Population':
        frac = {'Moderate': 0.3, 'Severe': 0.7, 'Existential': 0.95}[severity_level]
        compressors = np.where(state.niche == 1)[0]
        kill_count = int(len(compressors) * frac)
        dead = np.random.choice(compressors, kill_count, replace=False)
        for a in dead:
            state.trust_matrix[a, :] = 1.0
            state.agent_consumed_amt[a] = 0.0
            state.niche[a] = np.random.choice([0, 2])
            target_trace[a] = 0 if state.niche[a] == 0 else 1
            emit_trace[a] = 0 if state.niche[a] == 0 else 2
            
    elif shock_type == 'Knowledge':
        frac = {'Moderate': 0.3, 'Severe': 0.7, 'Existential': 0.95}[severity_level]
        for h in state.hubs_400:
            trusts = state.trust_matrix[:, h]
            high_t = np.where(trusts > 1.5)[0]
            shuffle_count = int(len(high_t) * frac)
            if shuffle_count > 0:
                to_shuffle = np.random.choice(high_t, shuffle_count, replace=False)
                for a in to_shuffle:
                    state.trust_matrix[a, h] = 1.0
                    fake_target = np.random.randint(0, N_AGENTS)
                    state.trust_matrix[a, fake_target] = 3.0
                    
    elif shock_type == 'Rule':
        pass 
        
    return state, target_trace, emit_trace

def compute_ae(trust_matrix, trust_matrix_400, fri_final):
    mask_c = trust_matrix > 1.5
    mask_400 = trust_matrix_400 > 1.5
    intersection = np.logical_and(mask_c, mask_400).sum()
    union = np.logical_or(mask_c, mask_400).sum()
    iri = intersection / max(1, union)
    tps = 1.0 - iri
    ae = fri_final / max(0.01, tps)
    return ae, tps

def run_scenario(state_400, target_trace_in, emit_trace_in, shock_type, severity, neighbors, K_csr):
    target_trace = np.copy(target_trace_in)
    emit_trace = np.copy(emit_trace_in)
    
    state_shocked, t_trace, e_trace = apply_shock(state_400, target_trace, emit_trace, shock_type, severity)
    
    state_C = state_shocked.copy()
    state_M = state_shocked.copy()
    
    metrics = {
        'C': {'ce': 0.0, 'trh': -1, 'tau_int': 0.0, 'min_fri': 1.0, 'fri_final': 0.0, 'epistemic_flex': -1},
        'M': {'ce': 0.0, 'trh': -1, 'tau_int': 0.0, 'min_fri': 1.0, 'fri_final': 0.0, 'epistemic_flex': -1}
    }
    
    rule_severity = {'Moderate': 0.95, 'Severe': 0.80, 'Existential': 0.50}[severity] if shock_type == 'Rule' else 1.0

    print(f"  [{shock_type} | {severity}] Fork Started.")
    
    for epoch in range(401, 601):
        S_sum_c = np.array(state_C.S_sparse[0].sum(axis=1) + state_C.S_sparse[1].sum(axis=1) + state_C.S_sparse[2].sum(axis=1)).flatten()
        state_C.target_node = int(np.argmax(S_sum_c))
        ce_spent_c, fri_c, tau_c = run_step(state_C, epoch, neighbors, K_csr, t_trace, e_trace, 0.0025, 20, 'C', 0.0, shock_type, rule_severity)
        
        S_sum_m = np.array(state_M.S_sparse[0].sum(axis=1) + state_M.S_sparse[1].sum(axis=1) + state_M.S_sparse[2].sum(axis=1)).flatten()
        state_M.target_node = int(np.argmax(S_sum_m))
        ce_spent_m, fri_m, tau_m = run_step(state_M, epoch, neighbors, K_csr, t_trace, e_trace, 0.0025, 20, 'M', ce_spent_c, shock_type, rule_severity)
        
        metrics['C']['ce'] += ce_spent_c
        metrics['C']['tau_int'] += max(0.0, tau_c - 0.05)
        metrics['C']['min_fri'] = min(metrics['C']['min_fri'], fri_c)
        if metrics['C']['trh'] == -1 and fri_c >= 0.85:
            metrics['C']['trh'] = epoch - 400
        if shock_type == 'Knowledge' and metrics['C']['epistemic_flex'] == -1 and fri_c > 0.6:
            metrics['C']['epistemic_flex'] = epoch - 400
            
        metrics['M']['ce'] += ce_spent_m
        metrics['M']['tau_int'] += max(0.0, tau_m - 0.05)
        metrics['M']['min_fri'] = min(metrics['M']['min_fri'], fri_m)
        if metrics['M']['trh'] == -1 and fri_m >= 0.85:
            metrics['M']['trh'] = epoch - 400
        if shock_type == 'Knowledge' and metrics['M']['epistemic_flex'] == -1 and fri_m > 0.6:
            metrics['M']['epistemic_flex'] = epoch - 400
            
        metrics['C']['fri_final'] = fri_c
        metrics['M']['fri_final'] = fri_m
            
    for m, state in [('C', state_C), ('M', state_M)]:
        metrics[m]['ee'] = (metrics[m]['fri_final'] - metrics[m]['min_fri']) / max(1e-6, metrics[m]['tau_int'])
        metrics[m]['ge'] = metrics[m]['fri_final'] / max(1.0, metrics[m]['ce'])
        ae, tps = compute_ae(state.trust_matrix, state_400.trust_matrix_400, metrics[m]['fri_final'])
        metrics[m]['ae'] = ae
        metrics[m]['tps'] = tps
        
    winner = "Constitutional" if metrics['C']['fri_final'] > metrics['M']['fri_final'] else "Managerial"
    print(f"  [{shock_type} | {severity}] Winner: {winner} | FRI_C={metrics['C']['fri_final']:.3f} FRI_M={metrics['M']['fri_final']:.3f}")
    
    return metrics

def run_world_p_tournament():
    np.random.seed(42)
    N_NODES = 5000; N_AGENTS = 500; WALK_STEPS = 20; RADIUS = 5
    MORTALITY_RATE = 0.0025
    
    neighbors, K_csr = generate_topology(N_NODES, k_ring=RADIUS*2)
    niche = np.zeros(N_AGENTS, dtype=np.int32)
    niche[166:333] = 1; niche[333:] = 2   
    target_trace = np.zeros(N_AGENTS, dtype=np.int32)
    target_trace[niche == 0] = 0; target_trace[niche == 1] = 0; target_trace[niche == 2] = 1
    emit_trace = np.copy(niche)
    
    print("🌌 [REA-7P] Booting Constitutional vs Managerial Tournament")
    
    pos = np.random.randint(0, N_NODES, size=N_AGENTS)
    trust_matrix = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S_sparse = [sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32) for _ in range(3)]
    state = SimState(pos, trust_matrix, S_sparse, niche, np.zeros(N_AGENTS, dtype=np.float32), [])
    
    print("\nPhase 1: Running Universal Baseline to Epoch 400...")
    for epoch in range(1, 401):
        S_sum = np.array(state.S_sparse[0].sum(axis=1) + state.S_sparse[1].sum(axis=1) + state.S_sparse[2].sum(axis=1)).flatten()
        state.target_node = int(np.argmax(S_sum))
        run_step(state, epoch, neighbors, K_csr, target_trace, emit_trace, MORTALITY_RATE, WALK_STEPS, world_mode='C', ce_budget=0.0)
        
        if epoch >= 380:
            ucc = extract_basin_metrics(state.pos, state.trust_matrix, state.agent_consumed_amt, state.active_triplets, state.target_node, N_NODES)
            state.dcr_400 = max(state.dcr_400, ucc['dcr'])
            state.scp_400 = max(state.scp_400, ucc['scp'])
            top_10 = max(1, int(len(ucc['trust_centrality_global']) * 0.10))
            hubs = set(np.argsort(ucc['trust_centrality_global'])[-top_10:])
            state.hubs_400 = state.hubs_400.union(hubs)
            
        if epoch % 100 == 0:
            print(f"  Epoch {epoch} | Baseline Computing...")
            
    print(f"\n[Baseline Attractor Locked]")
    print(f"  DCR_400 = {state.dcr_400:.3f}")
    print(f"  SCP_400 = {state.scp_400}")
    state.trust_matrix_400 = np.copy(state.trust_matrix)
    
    print("\nPhase 2: Shock Forking Engine (12 Scenarios, Equal CE Budget)")
    
    shock_types = ['Resource', 'Population', 'Knowledge', 'Rule']
    severities = ['Moderate', 'Severe', 'Existential']
    
    all_results = {}
    
    for st in shock_types:
        for sev in severities:
            res = run_scenario(state, target_trace, emit_trace, st, sev, neighbors, K_csr)
            all_results[(st, sev)] = res
            
    print("\n========================================================")
    print("REA-7P Final Falsification Matrix")
    print("========================================================")
    
    for st in shock_types:
        for sev in severities:
            res = all_results[(st, sev)]
            winner = "Constitutional" if res['C']['fri_final'] > res['M']['fri_final'] else "Managerial"
            print(f"\n[{st} Shock | {sev}] -> Winner: {winner}")
            print(f"  Constitutional (C) | FRI: {res['C']['fri_final']:.3f} | GE: {res['C']['ge']:.5f} | EE: {res['C']['ee']:.4f} | AE: {res['C']['ae']:.3f} | TPS: {res['C']['tps']:.3f} | TRH: {res['C']['trh']}")
            print(f"  Managerial (M)     | FRI: {res['M']['fri_final']:.3f} | GE: {res['M']['ge']:.5f} | EE: {res['M']['ee']:.4f} | AE: {res['M']['ae']:.3f} | TPS: {res['M']['tps']:.3f} | TRH: {res['M']['trh']}")
            
            if st == 'Rule' and sev in ['Severe', 'Existential']:
                print(f"  [Falsification Test] -> Passed: {winner == 'Constitutional'}")

if __name__ == "__main__":
    run_world_p_tournament()
