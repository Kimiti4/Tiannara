import time

def run_test():
    with open('scripts/fast_rea_7n_c_world_b.py', 'r') as f:
        code = f.read()
    
    code = code.replace("for epoch in range(1, 401):", 
"""for epoch in range(1, 4):
        import time
        t0 = time.time()
        S_sum = np.array(state.S_sparse[0].sum(axis=1) + state.S_sparse[1].sum(axis=1) + state.S_sparse[2].sum(axis=1)).flatten()
        state.target_node = int(np.argmax(S_sum))
        t1 = time.time()
        run_simulation_step_c(state, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS, world_mode='A')
        t2 = time.time()
        print(f"Epoch {epoch} finished. target_node logic: {t1-t0:.4f}s, run_simulation_step_c: {t2-t1:.4f}s")
        if epoch % 1 == 0:
            dcr, dci, r, scp, _, c = get_basin_metrics(state, state.target_node)
            tfi = compute_tfi(dcr, scp, dci, r, c, state, state.target_node)
            print(f"  Epoch {epoch} | DCR: {dcr:.3f} | DCI: {dci:.3f} | R: {r:.2f} | TFI: {tfi:.1f}")
""")

    code = code.replace("def run_simulation_step_c", 
"""def run_simulation_step_c(state, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS, world_mode='A'):
    import time
    t0 = time.time()
    dcr_val, dci_val, r_val, scp_val, trust_centrality, counts = get_basin_metrics(state, state.target_node)
    t1 = time.time()
    
    decay_rate = 0.99
    dci_error = 0.0
    red_error = 0.0
    CE = 0.0
    
    if world_mode in ['B', 'C'] and state.R_target > 0:
        red_error = r_val - state.R_target
        if red_error > 0.1:
            decay_rate = 0.97 if world_mode == 'B' else np.random.choice([0.97, 1.01])
            CE += 100.0
        elif red_error < -0.1:
            decay_rate = 0.998 if world_mode == 'B' else np.random.choice([0.998, 0.98])
            CE += 50.0
        dci_error = max(0.0, dci_val - state.DCI_target)
        
    state.agent_consumed_amt[:] = 0.0
    E_rows = [[], [], []]; E_cols = [[], [], []]; E_data = [[], [], []]
    C_rows = [[], [], []]; C_cols = [[], [], []]; C_data = [[], [], []]
    state.active_triplets.clear()
    last_consumed_from = np.full(len(state.pos), -1, dtype=np.int32)
    max_cent = max(1.0, np.max(trust_centrality))
    
    t_walk = 0.0
    t_consume = 0.0
    
    for step in range(WALK_STEPS):
        tw0 = time.time()
        cands = neighbors[state.pos] 
        best_idx = np.zeros(len(state.pos), dtype=np.int32)
        Phi_fields = [state.S_sparse[t].dot(state.trust_matrix.T) for t in range(3)]
        local_trust_all = np.sum(state.trust_matrix > 1.5, axis=1)
        
        for a in range(len(state.pos)):
            c_nodes = cands[a]
            t = target_trace[a]
            phi = Phi_fields[t][c_nodes, a]
            
            e_norm = min(1.0, state.agent_consumed_amt[a] / 4.0)
            local_trust = local_trust_all[a]
            t_norm = min(1.0, local_trust / 5.0)
            w_macro = (1.0 - e_norm) * (1.0 - t_norm)
            
            macro_phi = np.zeros_like(phi)
            if world_mode in ['B', 'C'] and w_macro > 0.1:
                safety_node = state.target_node if world_mode == 'B' else np.random.randint(0, K_csr.shape[0])
                dists = np.abs(c_nodes - safety_node)
                dists = np.minimum(dists, K_csr.shape[0] - dists)
                macro_phi += 5.0 / (dists + 1.0)
                node_density = counts[c_nodes]
                if world_mode == 'B':
                    macro_phi -= 2.0 * (node_density / len(state.pos))
                else:
                    macro_phi -= 2.0 * np.random.uniform(0, 0.1, size=c_nodes.shape)
                CE += w_macro * 1.0
                
            noise = np.random.uniform(0, 0.05, size=phi.shape)
            best_idx[a] = np.argmax((1.0 - w_macro) * phi + w_macro * macro_phi + noise)
            
        state.pos = cands[np.arange(len(state.pos)), best_idx]
        counts = np.bincount(state.pos, minlength=K_csr.shape[0])
        tw1 = time.time()
        t_walk += (tw1 - tw0)
        
        tc0 = time.time()
        agent_order = np.random.permutation(len(state.pos))
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
                e_norm = min(1.0, state.agent_consumed_amt[a] / 4.0)
                local_trust = local_trust_all[a]
                t_norm = min(1.0, local_trust / 5.0)
                w_macro = (1.0 - e_norm) * (1.0 - t_norm)
                
                if world_mode == 'B':
                    hub_penalties = 5.0 * (trust_centrality[authors] / max_cent) * dci_error * w_macro
                else:
                    hub_penalties = 5.0 * np.random.rand(len(authors)) * dci_error * w_macro
                    
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
                            
        for a in range(len(state.pos)):
            t = emit_trace[a]
            n_id = state.pos[a]
            E_rows[t].append(n_id); E_cols[t].append(a); E_data[t].append(2.5)
        tc1 = time.time()
        t_consume += (tc1 - tc0)
        
    t2 = time.time()
    for t in range(3):
        if len(C_data[t]) > 0:
            C_mat = sp.csr_matrix((C_data[t], (C_rows[t], C_cols[t])), shape=(K_csr.shape[0], len(state.pos)))
            state.S_sparse[t] = state.S_sparse[t] - C_mat
        if len(E_data[t]) > 0:
            E_mat = sp.csr_matrix((E_data[t], (E_rows[t], E_cols[t])), shape=(K_csr.shape[0], len(state.pos)))
            state.S_sparse[t] = state.S_sparse[t].multiply(DECAY) + K_csr.dot(E_mat)
        else:
            state.S_sparse[t] = state.S_sparse[t].multiply(DECAY)
            
        state.S_sparse[t].data = np.clip(state.S_sparse[t].data, 0.0, MAX_PHI)
        state.S_sparse[t].data[state.S_sparse[t].data < 1e-3] = 0.0
        state.S_sparse[t].eliminate_zeros()
            
    state.trust_matrix = np.maximum(1.0, state.trust_matrix * decay_rate)
    dead_agents = np.where(np.random.rand(len(state.pos)) < MORTALITY_RATE)[0]
    for a in dead_agents:
        state.trust_matrix[a, :] = 1.0 
        state.agent_consumed_amt[a] = 0.0
        
    t3 = time.time()
    print(f"  get_basin_metrics: {t1-t0:.4f}s | walk_loop: {t_walk:.4f}s | consume_loop: {t_consume:.4f}s | S_sparse_update: {t3-t2:.4f}s")
    return CE
def original_run_simulation_step_c""")

    with open('scripts/test_perf.py', 'w') as f:
        f.write(code)

if __name__ == "__main__":
    run_test()
