import numpy as np
import scipy.sparse as sp
import time
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import r2_score
import math

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
    def __init__(self, pos, trust_matrix, S, niche, agent_consumed_amt, active_triplets):
        self.pos = np.copy(pos)
        self.trust_matrix = np.copy(trust_matrix)
        self.S = np.copy(S)
        self.niche = np.copy(niche)
        self.agent_consumed_amt = np.copy(agent_consumed_amt)
        self.active_triplets = set(active_triplets)
        
def run_simulation_step(state, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS):
    N_AGENTS = len(state.pos)
    N_NODES = state.S.shape[1]
    
    E = np.zeros((3, N_NODES, N_AGENTS), dtype=np.float32)
    ec_matrix = np.zeros((N_AGENTS, N_AGENTS), dtype=np.float32)
    cp_matrix = np.zeros((N_AGENTS, N_AGENTS), dtype=np.float32)
    state.active_triplets.clear()
    last_consumed_from = np.full(N_AGENTS, -1, dtype=np.int32)
    
    for step in range(WALK_STEPS):
        cands = neighbors[state.pos]
        T = state.S[target_trace[:, None], cands, :]
        W = state.trust_matrix[:, None, :]
        Phi = np.sum(T * W, axis=2)
        noise = np.random.uniform(0, 0.05, size=Phi.shape)
        best_idx = np.argmax(Phi + noise, axis=1)
        state.pos = cands[np.arange(N_AGENTS), best_idx]
        
        agent_order = np.random.permutation(N_AGENTS)
        for a in agent_order:
            n_id = state.pos[a]
            t_target = target_trace[a]
            available = state.S[t_target, n_id, :]
            authors = np.where(available > 0.001)[0]
            if len(authors) == 0: continue
            
            required = 5.0 - state.agent_consumed_amt[a]
            if required <= 0: continue
            
            intensities = available[authors]
            sorted_authors = authors[np.argsort(-intensities)]
            
            for author in sorted_authors:
                if required <= 0: break
                amt = available[author]
                if amt == 0: continue
                take = min(amt, required)
                state.S[t_target, n_id, author] -= take
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
                            
        E[emit_trace, state.pos, np.arange(N_AGENTS)] += 2.5
        
    E_flat = E.transpose(1, 0, 2).reshape(N_NODES, -1)
    S_flat = state.S.transpose(1, 0, 2).reshape(N_NODES, -1)
    S_new_flat = S_flat * DECAY + K_csr.dot(E_flat)
    S_new_flat = np.clip(S_new_flat, 0.0, MAX_PHI)
    state.S = S_new_flat.reshape(N_NODES, 3, N_AGENTS).transpose(1, 0, 2)
    
    state.trust_matrix = np.maximum(1.0, state.trust_matrix * 0.99)
    
    dead_agents = np.where(np.random.rand(N_AGENTS) < MORTALITY_RATE)[0]
    for a in dead_agents:
        state.trust_matrix[a, :] = 1.0 
        state.agent_consumed_amt[a] = 0.0
        
    dcr = np.sum(state.agent_consumed_amt[state.niche > 0] >= 4.0) / max(1, np.sum(state.niche > 0))
    scp = len(state.active_triplets)
    return dcr, scp, ec_matrix, cp_matrix

def extract_features(state, ec_matrix, cp_matrix, target_node, lineage_age, radius=25):
    N_NODES = state.S.shape[1]
    
    dists = np.abs(state.pos - target_node)
    dists = np.minimum(dists, N_NODES - dists)
    agents_in_radius = np.where(dists <= radius)[0]
    
    # 1. Predictor B: Institution Genome
    local_dcr = np.sum(state.agent_consumed_amt[agents_in_radius] >= 4.0) / max(1, len(agents_in_radius))
    
    local_triplets = 0
    agents_set = set(agents_in_radius)
    for (e, c, p_idx) in state.active_triplets:
        if e in agents_set and c in agents_set and p_idx in agents_set:
            local_triplets += 1
            
    ec_flow = np.sum(ec_matrix[np.ix_(agents_in_radius, agents_in_radius)]) if len(agents_in_radius) > 0 else 0
    cp_flow = np.sum(cp_matrix[np.ix_(agents_in_radius, agents_in_radius)]) if len(agents_in_radius) > 0 else 0
    
    # Target node basin strength (EMA of S approximated by sum)
    left = max(0, target_node - radius)
    right = min(N_NODES, target_node + radius + 1)
    institution_strength = np.sum(state.S[:, left:right, :]) / max(1, (right-left))
    
    x_inst = np.array([local_dcr, local_triplets, lineage_age, institution_strength, ec_flow, cp_flow], dtype=np.float32)
    
    # 2. Predictor A: Microstate
    if len(agents_in_radius) > 0:
        pos_feat = state.pos[agents_in_radius].astype(np.float32) / N_NODES
        cons_feat = state.agent_consumed_amt[agents_in_radius]
        trust_feat = state.trust_matrix[np.ix_(agents_in_radius, agents_in_radius)].flatten()
        pos_pad = np.pad(pos_feat, (0, 100 - len(pos_feat)))[:100]
        cons_pad = np.pad(cons_feat, (0, 100 - len(cons_feat)))[:100]
        trust_pad = np.pad(trust_feat, (0, 10000 - len(trust_feat)))[:10000]
        x_micro = np.concatenate([pos_pad, cons_pad, trust_pad])
    else:
        x_micro = np.zeros(10200, dtype=np.float32)
        
    # 3. Predictor D: Geography Baseline
    S_local = state.S[:, left:right, :].sum(axis=2).flatten()
    if len(S_local) < 3 * (2 * radius + 1):
        S_local = np.pad(S_local, (0, 3 * (2 * radius + 1) - len(S_local)))
    x_geo = np.concatenate([[len(agents_in_radius)], S_local])
    
    # 4. Predictor C: Random Macro
    x_rand = np.random.rand(6).astype(np.float32)
    
    return x_micro, x_inst, x_rand, x_geo

def run_cce_test():
    np.random.seed(42)
    N_NODES = 10000
    N_AGENTS = 100
    WALK_STEPS = 50
    RADIUS = 10
    MORTALITY_RATE = 0.0025
    MAX_PHI = 1.0
    DECAY = np.exp(-0.10)
    
    k_ring = RADIUS * 2
    neighbors, K_csr = generate_topology(N_NODES, k_ring=k_ring)
    
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
    agent_consumed_amt = np.zeros(N_AGENTS, dtype=np.float32)
    
    state = SimulatorState(pos, trust_matrix, S, niche, agent_consumed_amt, [])
    
    print("🌌 [REA-7N-B] Booting CCE 4-Way Prediction Tournament")
    print("Burn-in period (0 -> 1000 epochs)...")
    
    for epoch in range(1, 1001):
        dcr, scp, ec, cp = run_simulation_step(state, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS)
        
    print("Burn-in complete. Collecting historical training data (1000 -> 1800)...")
    
    buffer = []
    deltas = [10, 50, 100, 250, 500]
    training_data = {d: {'X_m':[], 'X_i':[], 'X_r':[], 'X_g':[], 'Y':[]} for d in deltas}
    
    target_node = int(np.median(state.pos))
    lineage_age = 500
    
    for epoch in range(1001, 1801):
        dcr, scp, ec, cp = run_simulation_step(state, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS)
        target_node = int(np.median(state.pos))
        lineage_age += 1
        
        if epoch % 10 == 0:
            xm, xi, xr, xg = extract_features(state, ec, cp, target_node, lineage_age)
            buffer.append((epoch, xm, xi, xr, xg))
            
        for d in deltas:
            for b in buffer:
                if epoch - b[0] == d:
                    training_data[d]['X_m'].append(b[1])
                    training_data[d]['X_i'].append(b[2])
                    training_data[d]['X_r'].append(b[3])
                    training_data[d]['X_g'].append(b[4])
                    training_data[d]['Y'].append(dcr)
                    
        buffer = [b for b in buffer if epoch - b[0] <= max(deltas)]
        
    print("\nTraining Random Forest Regressors...")
    models = {}
    r2_scores = {'Micro': {}, 'Inst': {}, 'Rand': {}, 'Geo': {}}
    
    for d in deltas:
        if len(training_data[d]['Y']) < 5: continue
        
        rf_m = RandomForestRegressor(n_estimators=50, random_state=42)
        rf_i = RandomForestRegressor(n_estimators=50, random_state=42)
        rf_r = RandomForestRegressor(n_estimators=50, random_state=42)
        rf_g = RandomForestRegressor(n_estimators=50, random_state=42)
        
        rf_m.fit(training_data[d]['X_m'], training_data[d]['Y'])
        rf_i.fit(training_data[d]['X_i'], training_data[d]['Y'])
        rf_r.fit(training_data[d]['X_r'], training_data[d]['Y'])
        rf_g.fit(training_data[d]['X_g'], training_data[d]['Y'])
        
        r2_m = max(0, r2_score(training_data[d]['Y'], rf_m.predict(training_data[d]['X_m'])))
        r2_i = max(0, r2_score(training_data[d]['Y'], rf_i.predict(training_data[d]['X_i'])))
        r2_r = max(0, r2_score(training_data[d]['Y'], rf_r.predict(training_data[d]['X_r'])))
        r2_g = max(0, r2_score(training_data[d]['Y'], rf_g.predict(training_data[d]['X_g'])))
        
        r2_scores['Micro'][d] = r2_m
        r2_scores['Inst'][d] = r2_i
        r2_scores['Rand'][d] = r2_r
        r2_scores['Geo'][d] = r2_g
        models[d] = {'rf_m': rf_m, 'rf_i': rf_i, 'rf_r': rf_r, 'rf_g': rf_g}
        
    print("\n--- Test 1: Compression Ratio (CR) ---")
    xm, xi, xr, xg = extract_features(state, ec, cp, target_node, lineage_age)
    cr = len(xm) / len(xi)
    print(f"Microstate Dims: {len(xm)}")
    print(f"Institution Dims: {len(xi)}")
    print(f"CR = {cr:.1f}x")

    print("\n--- Test 2: Predictive Retention (PR) ---")
    print(f"{'Horizon':<10} | {'Micro':<8} | {'Geo':<8} | {'Inst':<8} | {'Rand':<8} | {'PR (Inst/Micro)':<15}")
    for d in deltas:
        m = r2_scores['Micro'].get(d, 0)
        i = r2_scores['Inst'].get(d, 0)
        g = r2_scores['Geo'].get(d, 0)
        r = r2_scores['Rand'].get(d, 0)
        pr = i / m if m > 0 else 0
        print(f"Delta={d:<4} | {m:<8.3f} | {g:<8.3f} | {i:<8.3f} | {r:<8.3f} | {pr:<15.3f}")
        
    print("\n--- Test 3: Resilience Perturbation ---")
    
    target_d = 250
    if target_d not in models:
        print("Not enough data for Delta 250.")
        return
        
    branches = {
        "Baseline": SimulatorState(state.pos, state.trust_matrix, state.S, state.niche, state.agent_consumed_amt, state.active_triplets),
        "A_10%": SimulatorState(state.pos, state.trust_matrix, state.S, state.niche, state.agent_consumed_amt, state.active_triplets),
        "B_25%": SimulatorState(state.pos, state.trust_matrix, state.S, state.niche, state.agent_consumed_amt, state.active_triplets),
        "C1_Kill_Agents": SimulatorState(state.pos, state.trust_matrix, state.S, state.niche, state.agent_consumed_amt, state.active_triplets),
        "C2_Kill_All": SimulatorState(state.pos, state.trust_matrix, state.S, state.niche, state.agent_consumed_amt, state.active_triplets)
    }
    
    target_node = int(np.median(state.pos))
    dists = np.abs(state.pos - target_node)
    dists = np.minimum(dists, N_NODES - dists)
    agents_in_radius = np.where(dists <= 25)[0]
    
    np.random.shuffle(agents_in_radius)
    n_10 = int(len(agents_in_radius) * 0.10)
    n_25 = int(len(agents_in_radius) * 0.25)
    
    for a in agents_in_radius[:n_10]:
        branches["A_10%"].pos[a] = (branches["A_10%"].pos[a] + 5000) % N_NODES
        branches["A_10%"].trust_matrix[a, :] = 1.0
    
    for a in agents_in_radius[:n_25]:
        branches["B_25%"].pos[a] = (branches["B_25%"].pos[a] + 5000) % N_NODES
        branches["B_25%"].trust_matrix[a, :] = 1.0
        
    for a in agents_in_radius:
        branches["C1_Kill_Agents"].pos[a] = (branches["C1_Kill_Agents"].pos[a] + 5000) % N_NODES
        branches["C1_Kill_Agents"].trust_matrix[a, :] = 1.0
        branches["C2_Kill_All"].pos[a] = (branches["C2_Kill_All"].pos[a] + 5000) % N_NODES
        branches["C2_Kill_All"].trust_matrix[a, :] = 1.0
        
    left = max(0, target_node - 25)
    right = min(N_NODES, target_node + 26)
    branches["C2_Kill_All"].S[:, left:right, :] = 0.0
        
    predictions = {}
    for name, b_state in branches.items():
        xm, xi, xr, xg = extract_features(b_state, ec, cp, target_node, lineage_age)
        pred_m = models[target_d]['rf_m'].predict([xm])[0]
        pred_i = models[target_d]['rf_i'].predict([xi])[0]
        predictions[name] = {'pred_m': pred_m, 'pred_i': pred_i}
        
    actuals = {}
    for name, b_state in branches.items():
        for _ in range(250):
            dcr, scp, _, _ = run_simulation_step(b_state, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS)
        actuals[name] = dcr
        
    print(f"{'Branch':<15} | {'Actual DCR':<12} | {'Micro Pred':<12} | {'Inst Pred':<12} | {'Micro Err':<12} | {'Inst Err':<12}")
    errs = {}
    for name in branches.keys():
        act = actuals[name]
        p_m = predictions[name]['pred_m']
        p_i = predictions[name]['pred_i']
        e_m = abs(act - p_m)
        e_i = abs(act - p_i)
        errs[name] = e_i
        print(f"{name:<15} | {act:<12.3f} | {p_m:<12.3f} | {p_i:<12.3f} | {e_m:<12.3f} | {e_i:<12.3f}")
        
    print("\n--- Test 4: Emergence Index (EI) ---")
    pr_250 = r2_scores['Inst'].get(250, 0) / max(0.001, r2_scores['Micro'].get(250, 0))
    
    # Resilience Factor based on C1 and Baseline error ratio
    # If C1 error is equal to Baseline error, RF = 1.0
    rf = errs['Baseline'] / max(0.001, errs['C1_Kill_Agents'])
    
    ei = (pr_250 - 1) * rf * math.log(cr)
    
    print(f"EI = (PR250 - 1) * RF * log(CR)")
    print(f"EI = ({pr_250:.3f} - 1) * {rf:.3f} * log({cr:.1f})")
    print(f"EI = {ei:.3f}")

if __name__ == "__main__":
    run_cce_test()
