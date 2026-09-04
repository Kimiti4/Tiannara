import numpy as np
import scipy.sparse as sp
import json
import os
from tiannara_ucc.core import extract_basin_metrics, compute_fri
import sys; sys.path.append('scripts')
from dynamics_extractor import get_kmeans_model, classify_attractor, get_boundary_distance, extract_10d_telemetry

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
        self.agent_survival_rate = 1.0
        self.ce_spent = 0.0
        
    def copy(self):
        new_state = SimState(self.pos, self.trust_matrix, self.S_sparse, self.niche, self.agent_consumed_amt, self.active_triplets)
        new_state.target_node = self.target_node
        new_state.dcr_400 = self.dcr_400
        new_state.scp_400 = self.scp_400
        new_state.hubs_400 = self.hubs_400.copy()
        new_state.agent_survival_rate = self.agent_survival_rate
        new_state.ce_spent = self.ce_spent
        return new_state

def run_step_with_coords(state, neighbors, K_csr, target_trace, emit_trace, coords):
    N_AGENTS = len(state.pos)
    N_NODES = K_csr.shape[0]
    K_RING = neighbors.shape[1]
    
    gamma, rho, alpha_gain, tau = coords
    alpha_decay = 1.0
    
    state.agent_consumed_amt[:] = 0.0
    E_rows = [[], [], []]; E_cols = [[], [], []]; E_data = [[], [], []]
    C_rows = [[], [], []]; C_cols = [[], [], []]; C_data = [[], [], []]
    
    for step in range(10): # 10 walk steps per epoch
        c_nodes = neighbors[state.pos]
        Phi_fields = [state.S_sparse[t].dot(state.trust_matrix.T) for t in range(3)]
        phi = np.zeros((N_AGENTS, K_RING), dtype=np.float32)
        for t in range(3):
            mask = (target_trace == t)
            if np.any(mask):
                agents_idx = np.where(mask)[0]
                phi[mask] = Phi_fields[t][c_nodes[mask], agents_idx[:, None]]
        
        noise = np.random.uniform(0, 0.05, size=(N_AGENTS, K_RING))
        state.pos = c_nodes[np.arange(N_AGENTS), np.argmax(phi + noise, axis=1)]
        
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
            
            explore_score = available + tau * np.random.gumbel(size=len(authors))
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
                    state.trust_matrix[a, author] = min(5.0, state.trust_matrix[a, author] + alpha_gain)
                            
        for a in range(N_AGENTS):
            t = emit_trace[a]
            E_rows[t].append(state.pos[a]); E_cols[t].append(a); E_data[t].append(rho)
            
    MAX_PHI = 1.0 * (rho / 2.5) 
    for t in range(3):
        if len(C_data[t]) > 0:
            C_mat = sp.csr_matrix((C_data[t], (C_rows[t], C_cols[t])), shape=(N_NODES, N_AGENTS))
            state.S_sparse[t] = state.S_sparse[t] - C_mat
        if len(E_data[t]) > 0:
            E_mat = sp.csr_matrix((E_data[t], (E_rows[t], E_cols[t])), shape=(N_NODES, N_AGENTS))
            state.S_sparse[t] = state.S_sparse[t].multiply(gamma) + K_csr.dot(E_mat)
        else:
            state.S_sparse[t] = state.S_sparse[t].multiply(gamma)
            
        state.S_sparse[t].data = np.clip(state.S_sparse[t].data, 0.0, MAX_PHI)
        state.S_sparse[t].data[state.S_sparse[t].data < 1e-3] = 0.0
        state.S_sparse[t].eliminate_zeros()
            
    state.trust_matrix = np.maximum(1.0, state.trust_matrix * alpha_decay)
    dead_agents = np.where(np.random.rand(N_AGENTS) < 0.0025)[0]
    for a in dead_agents:
        state.trust_matrix[a, :] = 1.0 
        state.agent_consumed_amt[a] = 0.0

class ConstitutionalNavigatorGenome:
    def __init__(self, weights=None):
        # 7 Inputs: Attractor, Recoverability, Elasticity, E_Gradient, Bound_Dist, Velocity, Momentum
        # 5 Outputs: Delta(gamma, rho, alpha, tau, mu)
        if weights is None:
            self.weights = np.random.randn(5, 7) * 0.1
        else:
            self.weights = weights
            
    def mutate(self, rate=0.1):
        mask = np.random.rand(5, 7) < rate
        mutations = np.random.randn(5, 7) * 0.5
        new_weights = np.copy(self.weights)
        new_weights[mask] += mutations[mask]
        return ConstitutionalNavigatorGenome(new_weights)
        
    def navigate(self, nav_state, current_coords, mu):
        # nav_state: [attractor_idx, rec, el, el_grad, dist, vel, mu]
        x = np.array(nav_state, dtype=np.float32)
        out = np.tanh(self.weights.dot(x))
        
        # Unpack outputs
        d_gamma, d_rho, d_alpha, d_tau, d_mu = out
        
        # Apply Momentum constraints
        # Max mutation is 0.05. Momentum (mu) resists change.
        fluidity = (1.0 - mu)
        d_gamma *= 0.05 * fluidity
        d_rho *= 0.10 * fluidity  # rho scale is larger (up to 5.0)
        d_alpha *= 0.05 * fluidity
        d_tau *= 0.20 * fluidity  # tau scale is larger (up to 5.0)
        
        d_mu *= 0.05 # Genome can mutate its own momentum
        
        # Apply deltas
        new_gamma = np.clip(current_coords[0] + d_gamma, 0.1, 0.99)
        new_rho = np.clip(current_coords[1] + d_rho, 0.1, 5.0)
        new_alpha = np.clip(current_coords[2] + d_alpha, 0.01, 1.0)
        new_tau = np.clip(current_coords[3] + d_tau, 0.01, 5.0)
        new_mu = np.clip(mu + d_mu, 0.0, 1.0)
        
        return (new_gamma, new_rho, new_alpha, new_tau), new_mu

def initialize_trunk():
    np.random.seed(42)
    N_NODES = 1000; N_AGENTS = 100; RADIUS = 5
    neighbors, K_csr = generate_topology(N_NODES, k_ring=RADIUS*2)
    
    niche = np.zeros(N_AGENTS, dtype=np.int32)
    niche[33:66] = 1; niche[66:] = 2   
    target_trace = np.zeros(N_AGENTS, dtype=np.int32)
    target_trace[niche == 0] = 0; target_trace[niche == 1] = 0; target_trace[niche == 2] = 1
    emit_trace = np.copy(niche)
    
    pos = np.random.randint(0, N_NODES, size=N_AGENTS)
    trust_matrix = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S_sparse = [sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32) for _ in range(3)]
    state = SimState(pos, trust_matrix, S_sparse, niche, np.zeros(N_AGENTS, dtype=np.float32), [])
    
    # Fast forward to Epoch 400 using greedy oracle equivalent (repair)
    coords = (0.95, 2.5, 0.3, 0.50)
    for epoch in range(1, 401):
        S_sum = np.array(state.S_sparse[0].sum(axis=0) + state.S_sparse[1].sum(axis=0) + state.S_sparse[2].sum(axis=0)).flatten()
        if len(S_sum) > 0 and S_sum.max() > 0:
            state.target_node = int(np.argmax(S_sum))
            
        run_step_with_coords(state, neighbors, K_csr, target_trace, emit_trace, coords)
        if epoch >= 380:
            ucc = extract_basin_metrics(state.pos, state.trust_matrix, state.agent_consumed_amt, state.active_triplets, state.target_node, N_NODES)
            state.dcr_400 = max(state.dcr_400, ucc['dcr'])
            state.scp_400 = max(state.scp_400, ucc['scp'])
            state.hubs_400 = state.hubs_400.union(set(np.argsort(ucc['trust_centrality_global'])[-10:]))
            
    print(f"🌍 [Rigid Trunk Initialized] DCR={state.dcr_400:.3f}")
    
    # Apply Massive Shock (Push to Brittle)
    for t in range(3):
        nnz = state.S_sparse[t].nnz
        if nnz > 0:
            drop_idx = np.random.choice(nnz, int(nnz * 0.9), replace=False) # 90% resource wipe
            state.S_sparse[t].data[drop_idx] = 0.0
            state.S_sparse[t].eliminate_zeros()
            
    return state, neighbors, K_csr, target_trace, emit_trace

def run_tournament():
    print("🧬 [Phase 10] Booting Institutional Evolution Engine (IEE)")
    mean_geom, std_geom, centroids_geom = get_kmeans_model()
    attractor_map = {"Rigid": 0, "Brittle": 1, "Plastic": 2, "Explosive": 3, "Zombie": 4}
    
    base_state, neighbors, K_csr, target_trace, emit_trace = initialize_trunk()
    
    POPULATION_SIZE = 20
    GENERATIONS = 5
    EPOCHS_PER_EVAL = 50
    DECISION_INTERVAL = 5
    N_NODES = 1000
    
    population = [ConstitutionalNavigatorGenome() for _ in range(POPULATION_SIZE)]
    
    for gen in range(GENERATIONS):
        print(f"\n================ GENERATION {gen+1} ================")
        fitness_scores = []
        archetype_counts = {a: 0 for a in attractor_map.keys()}
        
        for idx, genome in enumerate(population):
            state = base_state.copy()
            coords = (0.9048, 2.5, 0.1, 0.05) # Default 'preserve' coords
            mu = 0.8 # Initial high momentum
            
            el = 0.0
            el_grad = 0.0
            rec = 0.2
            dist = -0.178
            vel = 0.0
            attr = "Brittle"
            
            total_elasticity = 0.0
            zombie_time = 0
            
            prev_state = state.copy()
            
            trajectory = []
            
            for epoch in range(0, EPOCHS_PER_EVAL, DECISION_INTERVAL):
                for step in range(DECISION_INTERVAL):
                    S_sum = np.array(state.S_sparse[0].sum(axis=0) + state.S_sparse[1].sum(axis=0) + state.S_sparse[2].sum(axis=0)).flatten()
                    if len(S_sum) > 0 and S_sum.max() > 0:
                        state.target_node = int(np.argmax(S_sum))
                    run_step_with_coords(state, neighbors, K_csr, target_trace, emit_trace, coords)
                    
                # Measure Geometry at Decision Interval
                telemetry = extract_10d_telemetry(prev_state, state, N_NODES)
                new_attr = classify_attractor(telemetry, mean_geom, std_geom, centroids_geom)
                new_dist = get_boundary_distance(telemetry)
                
                # Approximate Elasticity (To save compute during evolution, we approximate AE via DCR retention)
                ucc = extract_basin_metrics(state.pos, state.trust_matrix, state.agent_consumed_amt, state.active_triplets, state.target_node, N_NODES)
                dcr_ret = ucc['dcr'] / max(0.1, state.dcr_400)
                new_el = max(0.0, dcr_ret - 0.2) # Proxy
                
                vel = new_dist - dist
                el_grad = new_el - el
                attr = new_attr
                dist = new_dist
                el = new_el
                
                # Navigator Vector
                nav_state = [attractor_map[attr]/4.0, rec, el, el_grad, dist, vel, mu]
                
                # Mutate Constitution
                coords, mu = genome.navigate(nav_state, coords, mu)
                
                prev_state = state.copy()
                
                total_elasticity += el
                if attr == 'Zombie': zombie_time += 1
                if attr == 'Brittle': zombie_time += 0.5
                trajectory.append(attr)
                
            # Evaluate Fitness: Maximize elasticity, penalize dead zones
            fitness = total_elasticity - (zombie_time * 0.1)
            fitness_scores.append(fitness)
            
            final_attr = trajectory[-1]
            archetype_counts[final_attr] += 1
            
        # Select & Breed
        best_indices = np.argsort(fitness_scores)[-10:] # Top 25%
        best_genomes = [population[i] for i in best_indices]
        
        print(f"Gen {gen+1} | Max Fit: {np.max(fitness_scores):.3f} | Mean Fit: {np.mean(fitness_scores):.3f}")
        print(f"Outcomes: {archetype_counts}")
        print(f"Champion Final Coords: γ={coords[0]:.2f}, ρ={coords[1]:.2f}, α={coords[2]:.2f}, τ={coords[3]:.2f}, μ={mu:.2f}")
        
        # Breed next gen
        new_population = []
        for _ in range(POPULATION_SIZE):
            parent = np.random.choice(best_genomes)
            new_population.append(parent.mutate(rate=0.2))
            
        population = new_population

if __name__ == "__main__":
    run_tournament()
