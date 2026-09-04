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

def run_telemetry():
    np.random.seed(42)
    
    N_NODES = 10000
    N_AGENTS = 100
    N_EPOCHS = 2000
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
    
    last_consumed_from = np.full(N_AGENTS, -1, dtype=np.int32)
    
    # UCC Thermodynamic Tracking Arrays
    S_ema = np.zeros((3, N_NODES), dtype=np.float32)
    S_variance = np.zeros((3, N_NODES), dtype=np.float32)
    S_flux_ema = np.zeros((3, N_NODES), dtype=np.float32)
    S_old_collapsed = np.zeros((3, N_NODES), dtype=np.float32)
    
    alpha_ema = 0.01
    STABILITY_THRESHOLD = 0.5
    VOLATILITY_TOLERANCE = 0.5
    FLUX_THRESHOLD = 0.1
    
    # Basin Tracking State
    basin_presence = np.zeros(N_NODES, dtype=np.int32)
    basin_absence = np.zeros(N_NODES, dtype=np.int32)
    
    print(f"🌌 [REA UCC Telemetry] Booting 2,000 Epoch Basin Extraction Test...")
    start_time = time.time()
    
    for epoch in range(1, N_EPOCHS + 1):
        E = np.zeros((3, N_NODES, N_AGENTS), dtype=np.float32)
        agent_consumed_amt = np.zeros(N_AGENTS, dtype=np.float32)
        
        for step in range(WALK_STEPS):
            cands = neighbors[pos]
            T = S[target_trace[:, None], cands, :]
            W = trust_matrix[:, None, :]
            Phi = np.sum(T * W, axis=2)
            noise = np.random.uniform(0, 0.05, size=Phi.shape)
            best_idx = np.argmax(Phi + noise, axis=1)
            pos = cands[np.arange(N_AGENTS), best_idx]
            
            agent_order = np.random.permutation(N_AGENTS)
            for a in agent_order:
                n_id = pos[a]
                t_target = target_trace[a]
                available = S[t_target, n_id, :]
                authors_with_traces = np.where(available > 0.001)[0]
                if len(authors_with_traces) == 0: continue
                
                required = 5.0 - agent_consumed_amt[a]
                if required <= 0: continue
                
                intensities = available[authors_with_traces]
                sorted_authors = authors_with_traces[np.argsort(-intensities)]
                
                for author in sorted_authors:
                    if required <= 0: break
                    amt = available[author]
                    if amt == 0: continue
                    take = min(amt, required)
                    available[author] -= take
                    required -= take
                    agent_consumed_amt[a] += take
                    if author != a:
                        trust_matrix[a, author] = min(5.0, trust_matrix[a, author] + 0.1)
                        last_consumed_from[a] = author
                                
                S[t_target, n_id, :] = available
            
            drop_amt = 2.5
            E[emit_trace, pos, np.arange(N_AGENTS)] += drop_amt
            
        # Update Stigmergy
        E_flat = E.transpose(1, 0, 2).reshape(N_NODES, -1)
        S_flat = S.transpose(1, 0, 2).reshape(N_NODES, -1)
        S_new_flat = S_flat * DECAY + K_csr.dot(E_flat)
        S_new_flat = np.clip(S_new_flat, 0.0, MAX_PHI)
        S = S_new_flat.reshape(N_NODES, 3, N_AGENTS).transpose(1, 0, 2)
        
        trust_matrix = np.maximum(1.0, trust_matrix * 0.99)
        
        dead_agents = np.where(np.random.rand(N_AGENTS) < MORTALITY_RATE)[0]
        for a in dead_agents:
            pos[a] = pos[a] 
            trust_matrix[a, :] = 1.0 
            last_consumed_from[a] = -1
            
        # --- UCC THERMODYNAMIC TRACKING ---
        # Sum traces across authors to get total intensity at node
        S_sum = np.sum(S, axis=2) 
        
        S_ema = (1 - alpha_ema) * S_ema + alpha_ema * S_sum
        S_variance = (1 - alpha_ema) * S_variance + alpha_ema * (S_sum - S_ema)**2
        
        S_flux = np.abs(S_sum - S_old_collapsed)
        S_flux_ema = (1 - alpha_ema) * S_flux_ema + alpha_ema * S_flux
        S_old_collapsed = np.copy(S_sum)
        
        # stable_mask shape: (3, N_NODES) -> Flatten to just N_NODES (any trace type stable)
        stable_mask = (S_ema > STABILITY_THRESHOLD) & (S_variance < VOLATILITY_TOLERANCE) & (S_flux_ema < FLUX_THRESHOLD)
        stable_nodes = np.unique(np.where(stable_mask)[1])
        
        # ETS Absence/Presence Decay Simulation
        all_nodes = np.arange(N_NODES)
        absent_nodes = np.setdiff1d(all_nodes, stable_nodes)
        
        basin_presence[stable_nodes] += 1
        basin_absence[stable_nodes] = 0
        
        basin_absence[absent_nodes] += 1
        # Absence decay > 50 epochs deletes the basin
        dead_basins = basin_absence > 50
        basin_presence[dead_basins] = 0
        
        if epoch % 100 == 0:
            active_count = np.sum(basin_presence > 0)
            level_1_count = np.sum(basin_presence > 500)
            print(f"Epoch {epoch}: {active_count} active basins. {level_1_count} basins crossed Level 1 (Age > 500).", flush=True)

    print(f"\n--- Final Telemetry Report ---")
    active_indices = np.where(basin_presence > 0)[0]
    ages = basin_presence[active_indices]
    
    if len(ages) == 0:
        print("0 institutions emerged.")
    else:
        print(f"Total Level 0 Basins: {len(ages)}")
        print(f"Total Level 1 Basins (Age > 500): {np.sum(ages > 500)}")
        print(f"Max Basin Age: {np.max(ages)}")
        
        # Print top 10 oldest basins
        sorted_indices = np.argsort(-ages)
        print("\nTop 10 Oldest Basins:")
        for i in range(min(10, len(ages))):
            idx = active_indices[sorted_indices[i]]
            age = ages[sorted_indices[i]]
            
            # Approximate Basin Size (Agents currently on the node or immediate neighbors)
            # Simplistic size estimation
            agents_in_radius = np.sum(np.abs(pos - idx) <= RADIUS)
            print(f" - Node {idx:<5} | Age: {age:<4} | Approx Agents: {agents_in_radius}")
            
    print(f"\nTelemetry completed in {time.time() - start_time:.2f} seconds")

if __name__ == "__main__":
    run_telemetry()
