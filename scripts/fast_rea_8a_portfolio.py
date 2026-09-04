import numpy as np
import scipy.sparse as sp
import time
from tiannara_ucc.core import extract_basin_metrics, compute_fri, compute_novelty_yield, compute_mci_penalties

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
        self.S_volume_400 = [0.0, 0.0, 0.0]
        
    def copy(self):
        new_state = SimState(self.pos, self.trust_matrix, self.S_sparse, self.niche, self.agent_consumed_amt, self.active_triplets)
        new_state.target_node = self.target_node
        new_state.dcr_400 = self.dcr_400
        new_state.scp_400 = self.scp_400
        new_state.hubs_400 = self.hubs_400.copy()
        new_state.trust_matrix_400 = np.copy(self.trust_matrix_400) if self.trust_matrix_400 is not None else None
        new_state.triplets_400 = self.triplets_400.copy()
        new_state.agent_survival_rate = self.agent_survival_rate
        new_state.S_volume_400 = list(self.S_volume_400)
        return new_state

def run_step(state, epoch, neighbors, K_csr, target_trace, emit_trace, MORTALITY_RATE, WALK_STEPS, mode, rule_severity=1.0):
    N_AGENTS = len(state.pos)
    N_NODES = K_csr.shape[0]
    K_RING = neighbors.shape[1]
    
    ucc = extract_basin_metrics(state.pos, state.trust_matrix, state.agent_consumed_amt, state.active_triplets, state.target_node, N_NODES)
    
    gamma_persistence = 0.9048
    rho_signal = 2.5
    alpha_trust_gain = 0.1
    alpha_trust_decay = rule_severity
    tau_explore = 0.05
    
    fri = compute_fri(ucc['dcr'], ucc['scp'], ucc['trust_centrality_global'], state.dcr_400, state.scp_400, state.hubs_400)
    
    if mode == 'Constitutional':
        if fri < 0.85:
            melt_factor = (0.85 - fri) / 0.85 
            gamma_persistence = 0.9048 + 0.08 * melt_factor
            rho_signal = 2.5 + 2.5 * melt_factor
            alpha_trust_gain = 0.1 + 0.4 * melt_factor
            tau_explore = 0.05 + 0.95 * melt_factor
    elif mode == 'Managerial':
        # Apply triage (simulate CE spend by directly patching state)
        if state.agent_survival_rate < 0.9:
            # Force niche balancing
            counts = np.bincount(state.niche, minlength=3)
            target = N_AGENTS // 3
            if counts[1] < target:
                candidates = np.where(state.niche != 1)[0]
                if len(candidates) > 0:
                    c = candidates[0]
                    state.niche[c] = 1
                    target_trace[c] = 0
                    emit_trace[c] = 1
        # Force connections
        S_sum = np.array(state.S_sparse[0].sum(axis=0) + state.S_sparse[1].sum(axis=0) + state.S_sparse[2].sum(axis=0)).flatten()
        if len(S_sum) > 0 and S_sum.max() > 0:
            true_hub = int(np.argmax(S_sum))
            for i in range(10): # simulate CE budget
                idx = np.random.randint(0, N_AGENTS)
                state.trust_matrix[idx, true_hub] = 3.0
    elif mode == 'Exploratory':
        gamma_persistence = 0.50
        tau_explore = 5.0 # extreme annealing
        
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
    
    # Mortality logic
    dead_agents = np.where(np.random.rand(N_AGENTS) < MORTALITY_RATE)[0]
    for a in dead_agents:
        state.trust_matrix[a, :] = 1.0 
        state.agent_consumed_amt[a] = 0.0
        
    return fri, tau_explore

def apply_shock(state_in, target_trace, emit_trace, shock_type):
    state = state_in.copy()
    N_AGENTS = len(state.pos)
    rule_severity = 1.0
    
    def apply_res():
        for t in range(3):
            nnz = state.S_sparse[t].nnz
            if nnz > 0:
                drop_idx = np.random.choice(nnz, int(nnz * 0.8), replace=False) # Severe
                state.S_sparse[t].data[drop_idx] = 0.0
                state.S_sparse[t].eliminate_zeros()
    
    def apply_pop():
        compressors = np.where(state.niche == 1)[0]
        dead = np.random.choice(compressors, int(len(compressors) * 0.7), replace=False)
        state.agent_survival_rate -= (len(dead)/N_AGENTS)
        for a in dead:
            state.trust_matrix[a, :] = 1.0
            state.agent_consumed_amt[a] = 0.0
            state.niche[a] = np.random.choice([0, 2])
            target_trace[a] = 0 if state.niche[a] == 0 else 1
            emit_trace[a] = 0 if state.niche[a] == 0 else 2
            
    def apply_know():
        for h in state.hubs_400:
            trusts = state.trust_matrix[:, h]
            high_t = np.where(trusts > 1.5)[0]
            to_shuffle = np.random.choice(high_t, int(len(high_t) * 0.8), replace=False)
            for a in to_shuffle:
                state.trust_matrix[a, h] = 1.0
                state.trust_matrix[a, np.random.randint(0, N_AGENTS)] = 3.0

    if shock_type == 'Resource': apply_res()
    elif shock_type == 'Population': apply_pop()
    elif shock_type == 'Knowledge': apply_know()
    elif shock_type == 'Rule': rule_severity = 0.50
    elif shock_type == 'Mixed':
        apply_res(); apply_pop(); apply_know(); rule_severity = 0.50
        
    return state, target_trace, emit_trace, rule_severity

class EndogenousClassifier:
    def __init__(self, baseline_s_vol, baseline_niche, baseline_dcr):
        self.b_s = baseline_s_vol
        self.b_niche = baseline_niche
        self.b_dcr = baseline_dcr
        
    def classify(self, state, current_dcr):
        s_vol = [state.S_sparse[t].sum() for t in range(3)]
        s_drop = [s_vol[t] / max(1, self.b_s[t]) for t in range(3)]
        
        counts = np.bincount(state.niche, minlength=3)
        niche_ratios = counts / max(1, counts.sum())
        
        # Rule out mixed first
        if min(s_drop) < 0.5 and min(niche_ratios) < 0.2:
            return 'Mixed', 0.8
            
        if min(s_drop) < 0.5: return 'Resource', 0.9
        if min(niche_ratios) < 0.2: return 'Population', 0.9
        
        dcr_drop = current_dcr / max(0.1, self.b_dcr)
        if dcr_drop < 0.5: return 'Knowledge', 0.8
        
        return 'Unknown', 0.4 # Default low confidence

def run_scenario(state_400, target_trace_in, emit_trace_in, shock_type, neighbors, K_csr, target_trace_400, emit_trace_400):
    tt = np.copy(target_trace_in); et = np.copy(emit_trace_in)
    
    state_shocked, t_trace, e_trace, rule_severity = apply_shock(state_400, tt, et, shock_type)
    
    states = {
        'G0': state_shocked.copy(),
        'G1': state_shocked.copy(),
        'Fixed_M': state_shocked.copy(),
        'Fixed_C': state_shocked.copy()
    }
    tt_map = {'G0': np.copy(t_trace), 'G1': np.copy(t_trace), 'Fixed_M': np.copy(t_trace), 'Fixed_C': np.copy(t_trace)}
    et_map = {'G0': np.copy(e_trace), 'G1': np.copy(e_trace), 'Fixed_M': np.copy(e_trace), 'Fixed_C': np.copy(e_trace)}
    
    metrics = {k: {'fri': 0.0, 'mci_penalty': 0.0, 'novelty': 0.0, 'score': 0.0, 'mode_history': []} for k in states}
    
    classifier = EndogenousClassifier(state_400.S_volume_400, np.bincount(state_400.niche, minlength=3)/500, state_400.dcr_400)

    print(f"  [{shock_type}] Tournament Started.")
    
    for epoch in range(401, 501):
        for model in ['Fixed_M', 'Fixed_C', 'G0', 'G1']:
            st = states[model]
            ucc = extract_basin_metrics(st.pos, st.trust_matrix, st.agent_consumed_amt, st.active_triplets, st.target_node, 5000)
            current_dcr = ucc['dcr']
            
            # G0 Oracle Logic
            if model == 'G0':
                if shock_type == 'Population': mode = 'Managerial'
                elif shock_type in ['Knowledge', 'Rule']: mode = 'Constitutional'
                elif shock_type == 'Mixed': mode = 'Managerial' if epoch < 420 else 'Constitutional'
                else: mode = 'Constitutional'
            # G1 Endogenous Logic
            elif model == 'G1':
                pred_shock, conf = classifier.classify(st, current_dcr)
                if conf < 0.5: mode = 'Exploratory'
                elif pred_shock == 'Population': mode = 'Managerial'
                elif pred_shock == 'Mixed': mode = 'Managerial' if epoch < 420 else 'Constitutional'
                else: mode = 'Constitutional'
                
                if epoch == 450: metrics['G1']['predicted_class'] = pred_shock
            elif model == 'Fixed_M': mode = 'Managerial'
            elif model == 'Fixed_C': mode = 'Constitutional'
            
            metrics[model]['mode_history'].append(mode)
            
            S_sum = np.array(st.S_sparse[0].sum(axis=1) + st.S_sparse[1].sum(axis=1) + st.S_sparse[2].sum(axis=1)).flatten()
            if len(S_sum) > 0: st.target_node = int(np.argmax(S_sum))
            
            fri, tau = run_step(st, epoch, neighbors, K_csr, tt_map[model], et_map[model], 0.0025, 10, mode, rule_severity)
            
            if epoch == 500:
                metrics[model]['fri'] = fri
                
                # TPS calc
                mask_c = st.trust_matrix > 1.5
                mask_400 = state_400.trust_matrix_400 > 1.5
                intersection = np.logical_and(mask_c, mask_400).sum()
                union = np.logical_or(mask_c, mask_400).sum()
                tps = 1.0 - (intersection / max(1, union))
                
                metrics[model]['mci_penalty'] = compute_mci_penalties(current_dcr, tps, fri, st.agent_survival_rate)
                metrics[model]['score'] = fri - metrics[model]['mci_penalty']
                
                current_hubs = set(np.argsort(ucc['trust_centrality_global'])[-50:])
                metrics[model]['novelty'] = compute_novelty_yield(state_400.triplets_400, st.active_triplets, state_400.hubs_400, current_hubs)

    g0_mode = metrics['G0']['mode_history'][-1]
    g1_mode = metrics['G1']['mode_history'][-1]
    g1_pred = metrics['G1'].get('predicted_class', 'Unknown')
    
    print(f"  [{shock_type}] -> True: {shock_type} | G1 Pred: {g1_pred} | G0 Mode: {g0_mode} | G1 Mode: {g1_mode}")
    print(f"    G0 (Oracle) | Score: {metrics['G0']['score']:.3f} | FRI: {metrics['G0']['fri']:.3f} | Nov: {metrics['G0']['novelty']:.1f}")
    print(f"    G1 (Endog)  | Score: {metrics['G1']['score']:.3f} | FRI: {metrics['G1']['fri']:.3f} | Nov: {metrics['G1']['novelty']:.1f}")
    print(f"    Fixed_C     | Score: {metrics['Fixed_C']['score']:.3f} | FRI: {metrics['Fixed_C']['fri']:.3f}")
    print(f"    Fixed_M     | Score: {metrics['Fixed_M']['score']:.3f} | FRI: {metrics['Fixed_M']['fri']:.3f}")
    
    return metrics

def run_8a_tournament():
    np.random.seed(42)
    N_NODES = 2000; N_AGENTS = 200; WALK_STEPS = 10; RADIUS = 5
    MORTALITY_RATE = 0.0025
    
    neighbors, K_csr = generate_topology(N_NODES, k_ring=RADIUS*2)
    niche = np.zeros(N_AGENTS, dtype=np.int32)
    niche[66:133] = 1; niche[133:] = 2   
    target_trace = np.zeros(N_AGENTS, dtype=np.int32)
    target_trace[niche == 0] = 0; target_trace[niche == 1] = 0; target_trace[niche == 2] = 1
    emit_trace = np.copy(niche)
    
    print("🌌 [REA-8A] Booting Governance Genome Discovery Tournament")
    
    pos = np.random.randint(0, N_NODES, size=N_AGENTS)
    trust_matrix = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S_sparse = [sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32) for _ in range(3)]
    state = SimState(pos, trust_matrix, S_sparse, niche, np.zeros(N_AGENTS, dtype=np.float32), [])
    
    for epoch in range(1, 401):
        S_sum = np.array(state.S_sparse[0].sum(axis=1) + state.S_sparse[1].sum(axis=1) + state.S_sparse[2].sum(axis=1)).flatten()
        if len(S_sum) > 0: state.target_node = int(np.argmax(S_sum))
        run_step(state, epoch, neighbors, K_csr, target_trace, emit_trace, MORTALITY_RATE, WALK_STEPS, 'Constitutional')
        
        if epoch >= 380:
            ucc = extract_basin_metrics(state.pos, state.trust_matrix, state.agent_consumed_amt, state.active_triplets, state.target_node, N_NODES)
            state.dcr_400 = max(state.dcr_400, ucc['dcr'])
            state.scp_400 = max(state.scp_400, ucc['scp'])
            top_10 = max(1, int(len(ucc['trust_centrality_global']) * 0.10))
            hubs = set(np.argsort(ucc['trust_centrality_global'])[-top_10:])
            state.hubs_400 = state.hubs_400.union(hubs)
            state.triplets_400 = state.triplets_400.union(set(state.active_triplets))
            
    print(f"\n[Baseline 400 Locked] DCR={state.dcr_400:.3f}")
    state.trust_matrix_400 = np.copy(state.trust_matrix)
    state.S_volume_400 = [state.S_sparse[t].sum() for t in range(3)]
    
    print("\nPhase 2: Governance Shock Portfolio")
    shock_types = ['Resource', 'Population', 'Knowledge', 'Rule', 'Mixed']
    
    all_results = {}
    for st in shock_types:
        res = run_scenario(state, target_trace, emit_trace, st, neighbors, K_csr, target_trace, emit_trace)
        all_results[st] = res
        
    print("\n========================================================")
    print("REA-8A Governance Genome Results Matrix")
    print("========================================================")
    
    total_g0, total_g1, total_fm, total_fc = 0, 0, 0, 0
    for st in shock_types:
        res = all_results[st]
        print(f"\n[{st} Shock]")
        print(f"  G0 (Oracle) Score: {res['G0']['score']:.3f} | Nov: {res['G0']['novelty']:.1f}")
        print(f"  G1 (Endog)  Score: {res['G1']['score']:.3f} | Nov: {res['G1']['novelty']:.1f}")
        print(f"  Fixed_C     Score: {res['Fixed_C']['score']:.3f}")
        print(f"  Fixed_M     Score: {res['Fixed_M']['score']:.3f}")
        gig = res['G0']['score'] - res['G1']['score']
        print(f"  [GIG]: {gig:.3f}")
        
        total_g0 += res['G0']['score']
        total_g1 += res['G1']['score']
        total_fm += res['Fixed_M']['score']
        total_fc += res['Fixed_C']['score']
        
    print("\n========================================================")
    print("FALSIFICATION: Cumulative Mixed-Environment Performance")
    print(f"  Fixed Managerial:      {total_fm:.3f}")
    print(f"  Fixed Constitutional:  {total_fc:.3f}")
    print(f"  Governance Genome G1:  {total_g1:.3f}")
    print(f"  Oracle Governance G0:  {total_g0:.3f}")
    print(f"\n  Did G1 beat the best Fixed model? {'YES' if total_g1 > max(total_fm, total_fc) else 'NO'}")

if __name__ == "__main__":
    run_8a_tournament()
