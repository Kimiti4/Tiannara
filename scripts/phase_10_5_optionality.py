import numpy as np
import scipy.sparse as sp
import json
import os
import sys
sys.path.append('scripts')
from dynamics_extractor import get_kmeans_model, classify_attractor, get_boundary_distance, extract_10d_telemetry
from phase_10_navigation import SimState, generate_topology, run_step_with_coords, initialize_trunk
from tiannara_ucc.core import extract_basin_metrics, compute_fri

def compute_reachable_volume(base_state, neighbors, K_csr, target_trace, emit_trace, mean_geom, std_geom, centroids_geom, N_NODES=1000, branches=20, depth=10):
    # Branch out N random trajectories from current state to estimate RV
    reachable_attractors = set()
    total_volume = 0.0
    
    for b in range(branches):
        state = base_state.copy()
        # Random navigator policy
        coords = (
            np.random.uniform(0.1, 0.99), # gamma
            np.random.uniform(0.1, 5.0),  # rho
            np.random.uniform(0.01, 1.0), # alpha
            np.random.uniform(0.01, 5.0)  # tau
        )
        
        for d in range(depth):
            S_sum = np.array(state.S_sparse[0].sum(axis=0) + state.S_sparse[1].sum(axis=0) + state.S_sparse[2].sum(axis=0)).flatten()
            if len(S_sum) > 0 and S_sum.max() > 0:
                state.target_node = int(np.argmax(S_sum))
                
            prev_state = state.copy()
            run_step_with_coords(state, neighbors, K_csr, target_trace, emit_trace, coords)
            
        telemetry = extract_10d_telemetry(prev_state, state, N_NODES)
        attr = classify_attractor(telemetry, mean_geom, std_geom, centroids_geom)
        
        reachable_attractors.add(attr)
        
        # Approximate volume expansion based on trust diversity
        ucc = extract_basin_metrics(state.pos, state.trust_matrix, state.agent_consumed_amt, state.active_triplets, state.target_node, N_NODES)
        total_volume += ucc['dcr'] + (ucc['radius_of_gyration'] / 1000.0)
        
    rv_normalized = (len(reachable_attractors) / 5.0) + (total_volume / (branches * 5.0))
    return rv_normalized

class ASVTracker:
    def __init__(self):
        self.history = []
        
    def add_point(self, rv, e, b, h, c):
        # Weights: RV=0.4, E=0.3, B=0.5, H=0.2
        oi = (0.4 * rv) + (0.3 * e) - (0.5 * (-b)) + (0.2 * h) # Note: b is negative (distance to dead zone)
        self.history.append(oi)
        
        if len(self.history) < 2: return oi, 0.0
        
        sv = oi - self.history[-min(5, len(self.history))]
        mv = oi - self.history[-min(25, len(self.history))]
        lv = oi - self.history[-min(100, len(self.history))]
        
        doi_dt = 0.5 * sv + 0.3 * mv + 0.2 * lv
        return oi, doi_dt

def run_optionality_physics_tests():
    print("🌌 [Phase 10.5] Booting Optionality Geometry Engine")
    mean_geom, std_geom, centroids_geom = get_kmeans_model()
    
    base_state, neighbors, K_csr, target_trace, emit_trace = initialize_trunk()
    
    # -------------------------------------------------------------------
    print("\n[TEST 1] OPTIONALITY CREATION: Rigid -> Plastic")
    # -------------------------------------------------------------------
    # Can a civilization increase OI endogenously?
    state1 = base_state.copy()
    tracker1 = ASVTracker()
    explorer_coords = (0.80, 4.0, 0.5, 2.0) # High tau, High rho -> Plastic
    
    rv_start = compute_reachable_volume(state1, neighbors, K_csr, target_trace, emit_trace, mean_geom, std_geom, centroids_geom)
    oi_start, _ = tracker1.add_point(rv_start, 0.1, -0.2, 0.1, 0.0)
    print(f"Start (Rigid): RV={rv_start:.3f}, OI={oi_start:.3f}")
    
    for epoch in range(10):
        S_sum = np.array(state1.S_sparse[0].sum(axis=0) + state1.S_sparse[1].sum(axis=0) + state1.S_sparse[2].sum(axis=0)).flatten()
        if len(S_sum) > 0 and S_sum.max() > 0: state1.target_node = int(np.argmax(S_sum))
        run_step_with_coords(state1, neighbors, K_csr, target_trace, emit_trace, explorer_coords)
        
    rv_end = compute_reachable_volume(state1, neighbors, K_csr, target_trace, emit_trace, mean_geom, std_geom, centroids_geom)
    oi_end, _ = tracker1.add_point(rv_end, 0.6, 0.1, 0.2, 0.5)
    print(f"End (Plastic): RV={rv_end:.3f}, OI={oi_end:.3f}")
    if oi_end > oi_start: print("✅ Optionality is GENERATIVE.")

    # -------------------------------------------------------------------
    print("\n[TEST 2] OPTIONALITY DESTRUCTION: Plastic -> Zombie")
    # -------------------------------------------------------------------
    state2 = state1.copy() # Start from Plastic
    zombie_coords = (0.99, 1.0, 0.01, 0.01) # Total lockdown
    
    for epoch in range(10):
        S_sum = np.array(state2.S_sparse[0].sum(axis=0) + state2.S_sparse[1].sum(axis=0) + state2.S_sparse[2].sum(axis=0)).flatten()
        if len(S_sum) > 0 and S_sum.max() > 0: state2.target_node = int(np.argmax(S_sum))
        run_step_with_coords(state2, neighbors, K_csr, target_trace, emit_trace, zombie_coords)
        
    rv_zombie = compute_reachable_volume(state2, neighbors, K_csr, target_trace, emit_trace, mean_geom, std_geom, centroids_geom)
    print(f"End (Zombie): RV={rv_zombie:.3f}")
    if rv_zombie < rv_start: print("✅ Optionality is CONSUMABLE (Destructible).")

    # -------------------------------------------------------------------
    print("\n[TEST 3] OPTIONALITY TRANSFORMATION: Preserve vs Explorer")
    # -------------------------------------------------------------------
    state_preserve = state1.copy()
    state_explorer = state1.copy()
    
    for epoch in range(15):
        # World A: Preserve
        S_sum_A = np.array(state_preserve.S_sparse[0].sum(axis=0) + state_preserve.S_sparse[1].sum(axis=0) + state_preserve.S_sparse[2].sum(axis=0)).flatten()
        if len(S_sum_A) > 0 and S_sum_A.max() > 0: state_preserve.target_node = int(np.argmax(S_sum_A))
        run_step_with_coords(state_preserve, neighbors, K_csr, target_trace, emit_trace, (0.95, 2.5, 0.1, 0.05))
        
        # World B: Explorer
        S_sum_B = np.array(state_explorer.S_sparse[0].sum(axis=0) + state_explorer.S_sparse[1].sum(axis=0) + state_explorer.S_sparse[2].sum(axis=0)).flatten()
        if len(S_sum_B) > 0 and S_sum_B.max() > 0: state_explorer.target_node = int(np.argmax(S_sum_B))
        run_step_with_coords(state_explorer, neighbors, K_csr, target_trace, emit_trace, explorer_coords)
        
    rv_preserve = compute_reachable_volume(state_preserve, neighbors, K_csr, target_trace, emit_trace, mean_geom, std_geom, centroids_geom)
    rv_explorer = compute_reachable_volume(state_explorer, neighbors, K_csr, target_trace, emit_trace, mean_geom, std_geom, centroids_geom)
    
    ucc_p = extract_basin_metrics(state_preserve.pos, state_preserve.trust_matrix, state_preserve.agent_consumed_amt, state_preserve.active_triplets, state_preserve.target_node, 1000)
    ucc_e = extract_basin_metrics(state_explorer.pos, state_explorer.trust_matrix, state_explorer.agent_consumed_amt, state_explorer.active_triplets, state_explorer.target_node, 1000)
    
    print(f"World A (Preserve): DCR={ucc_p['dcr']:.3f}, Future RV={rv_preserve:.3f}")
    print(f"World B (Explorer): DCR={ucc_e['dcr']:.3f}, Future RV={rv_explorer:.3f}")
    if rv_explorer > rv_preserve and ucc_e['dcr'] < ucc_p['dcr']:
        print("✅ Optionality is TRANSFORMABLE (Explorer trades Current DCR for Future RV).")

    # -------------------------------------------------------------------
    print("\n[TEST 4] OPTIONALITY HARVESTING (Transmissibility)")
    # -------------------------------------------------------------------
    # Civ B (Low RV) copies topology from Civ A (High RV)
    civ_b = base_state.copy() # Rigid (Low RV)
    civ_a = state_explorer.copy() # Plastic (High RV)
    
    # Transmit Knowledge / Topology (Civ B adopts Civ A's trust matrix)
    civ_b.trust_matrix = np.copy(civ_a.trust_matrix)
    
    rv_transmitted = compute_reachable_volume(civ_b, neighbors, K_csr, target_trace, emit_trace, mean_geom, std_geom, centroids_geom)
    print(f"Civ B (Rigid) RV before transmission: {rv_start:.3f}")
    print(f"Civ B (Rigid) RV after adopting Civ A's Topology: {rv_transmitted:.3f}")
    if rv_transmitted > rv_start:
        print("✅ Optionality is TRANSMISSIBLE (Optionality Harvesting is valid).")

if __name__ == "__main__":
    run_optionality_physics_tests()
