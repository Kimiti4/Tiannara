import numpy as np
import scipy.sparse as sp
import json
import os
import sys
sys.path.append('scripts')
from dynamics_extractor import (
    generate_topology, SimState, run_step, extract_10d_telemetry,
    get_kmeans_model, classify_attractor, get_boundary_distance
)
from tiannara_ucc.core import extract_basin_metrics
from collections import defaultdict

# -----------------------------------------------------------------------
# Navigator Archetype Constitutional Coordinates
# Each archetype is a fixed (gamma, rho, alpha_gain, tau) preset.
# These are the "pure policy identities" we are testing against each other.
# -----------------------------------------------------------------------
NAVIGATOR_ARCHETYPES = {
    'Settler':  (0.95, 2.5,  0.05, 0.01),  # High persistence, low exploration
    'Explorer': (0.60, 4.5,  0.10, 3.00),  # Low persistence, high exploration
    'Trader':   (0.85, 3.0,  0.50, 0.50),  # High trust gain, balanced
    'Survivor': (0.98, 1.5,  0.02, 0.01),  # Maximum boundary distance, min change
    'Phoenix':  (0.40, 5.00, 0.80, 5.00),  # Forced collapse/recovery cycle
}

N_NODES   = 1000
N_AGENTS  = 100
WALK_STEPS = 10
RADIUS     = 5
MORTALITY  = 0.0025
DECISION_INTERVAL = 5  # Steps between constitutional decisions
TRAJECTORY_EPOCHS = 30

def run_archetype_epoch(state, neighbors, K_csr, target_trace, emit_trace, coords):
    """Run one epoch under fixed constitutional coordinates."""
    gamma, rho, alpha_gain, tau = coords
    N = N_NODES

    state.agent_consumed_amt[:] = 0.0
    E_rows = [[], [], []]; E_cols = [[], [], []]; E_data = [[], [], []]
    C_rows = [[], [], []]; C_cols = [[], [], []]; C_data = [[], [], []]

    for step in range(WALK_STEPS):
        c_nodes = neighbors[state.pos]
        Phi_fields = [state.S_sparse[t].dot(state.trust_matrix.T) for t in range(3)]
        phi = np.zeros((N_AGENTS, RADIUS * 2), dtype=np.float32)
        for t in range(3):
            mask = (target_trace == t)
            if np.any(mask):
                agents_idx = np.where(mask)[0]
                phi[mask] = Phi_fields[t][c_nodes[mask], agents_idx[:, None]]

        noise = np.random.uniform(0, 0.05, size=(N_AGENTS, RADIUS * 2))
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
            authors = authors[sort_order]; available = available[sort_order]
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

    MAX_PHI = rho / 2.5
    for t in range(3):
        if len(C_data[t]) > 0:
            C_mat = sp.csr_matrix((C_data[t], (C_rows[t], C_cols[t])), shape=(N, N_AGENTS))
            state.S_sparse[t] = state.S_sparse[t] - C_mat
        if len(E_data[t]) > 0:
            E_mat = sp.csr_matrix((E_data[t], (E_rows[t], E_cols[t])), shape=(N, N_AGENTS))
            state.S_sparse[t] = state.S_sparse[t].multiply(gamma) + K_csr.dot(E_mat)
        else:
            state.S_sparse[t] = state.S_sparse[t].multiply(gamma)
        state.S_sparse[t].data = np.clip(state.S_sparse[t].data, 0.0, MAX_PHI)
        state.S_sparse[t].data[state.S_sparse[t].data < 1e-3] = 0.0
        state.S_sparse[t].eliminate_zeros()

    state.trust_matrix = np.maximum(1.0, state.trust_matrix * 1.0)
    dead = np.where(np.random.rand(N_AGENTS) < MORTALITY)[0]
    for a in dead:
        state.trust_matrix[a, :] = 1.0
        state.agent_consumed_amt[a] = 0.0


def build_policy_ensemble_archive():
    print("🌌 [Phase 11A.5] Policy Ensemble Archive")
    print("=" * 65)

    mean_geom, std_geom, centroids_geom = get_kmeans_model()
    neighbors, K_csr = generate_topology(N_NODES, k_ring=RADIUS * 2)

    np.random.seed(42)
    niche = np.zeros(N_AGENTS, dtype=np.int32)
    niche[33:66] = 1; niche[66:] = 2
    target_trace = np.zeros(N_AGENTS, dtype=np.int32)
    target_trace[niche == 0] = 0; target_trace[niche == 1] = 0; target_trace[niche == 2] = 1
    emit_trace = np.copy(niche)

    # Build baseline at epoch 400
    print("\n[1/3] Initializing baseline (400 epochs)...")
    pos = np.random.randint(0, N_NODES, size=N_AGENTS)
    trust = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S = [sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32) for _ in range(3)]
    baseline = SimState(pos, trust, S, niche, np.zeros(N_AGENTS), [])

    for epoch in range(1, 401):
        run_step(baseline, epoch, neighbors, K_csr, target_trace, emit_trace,
                 MORTALITY, WALK_STEPS, 'repair')
        if epoch >= 380:
            ucc = extract_basin_metrics(baseline.pos, baseline.trust_matrix,
                                        baseline.agent_consumed_amt, baseline.active_triplets,
                                        baseline.target_node, N_NODES)
            baseline.dcr_400 = max(baseline.dcr_400, ucc['dcr'])
            baseline.scp_400 = max(baseline.scp_400, ucc['scp'])
            baseline.hubs_400 = baseline.hubs_400.union(
                set(np.argsort(ucc['trust_centrality_global'])[-10:]))

    print(f"   Baseline locked: DCR={baseline.dcr_400:.3f}")

    # Define shocks
    shocks = {
        'Resource':   lambda st: _apply_resource_shock(st),
        'Population': lambda st: _apply_population_shock(st, niche, target_trace, emit_trace),
        'Mixed':      lambda st: (_apply_resource_shock(st), _apply_population_shock(st, niche, target_trace, emit_trace)),
        'Knowledge':  lambda st: _apply_knowledge_shock(st),
    }

    print("\n[2/3] Running Policy Ensemble (5 archetypes × 4 shocks × 30 epochs)...")
    ensemble_archive = []

    for shock_name, shock_fn in shocks.items():
        for archetype_name, coords in NAVIGATOR_ARCHETYPES.items():
            shocked = baseline.copy()
            tt = np.copy(target_trace); et = np.copy(emit_trace)
            shock_fn(shocked)

            S_sum = np.array(shocked.S_sparse[0].sum(axis=0) +
                             shocked.S_sparse[1].sum(axis=0) +
                             shocked.S_sparse[2].sum(axis=0)).flatten()
            if S_sum.max() > 0:
                shocked.target_node = int(np.argmax(S_sum))

            prev = shocked.copy()
            oi_history = []

            for epoch_i in range(TRAJECTORY_EPOCHS):
                run_archetype_epoch(shocked, neighbors, K_csr, tt, et, coords)

                S_sum = np.array(shocked.S_sparse[0].sum(axis=0) +
                                 shocked.S_sparse[1].sum(axis=0) +
                                 shocked.S_sparse[2].sum(axis=0)).flatten()
                if S_sum.max() > 0:
                    shocked.target_node = int(np.argmax(S_sum))

                telemetry = extract_10d_telemetry(prev, shocked, N_NODES)
                attractor  = classify_attractor(telemetry, mean_geom, std_geom, centroids_geom)
                bd         = get_boundary_distance(telemetry)

                e   = max(0.0, telemetry['adaptation_velocity'])
                rv  = max(0.0, bd) * e + 0.2
                h   = min(1.0, epoch_i / TRAJECTORY_EPOCHS)
                oi  = (0.4 * rv) + (0.3 * e) + (0.5 * max(0, bd)) + (0.2 * h)
                oi_history.append(oi)

                sv = oi - oi_history[max(0, epoch_i - 5)]
                mv = oi - oi_history[max(0, epoch_i - 15)]
                lv = oi - oi_history[0]
                doi_dt = 0.5 * sv + 0.3 * mv + 0.2 * lv

                prev_e = ensemble_archive[-1]['e'] if ensemble_archive and \
                         ensemble_archive[-1]['shock'] == shock_name and \
                         ensemble_archive[-1]['policy'] == archetype_name else e
                c = e - prev_e

                record = {
                    'shock': shock_name, 'policy': archetype_name,
                    'epoch': epoch_i,    'attractor': attractor,
                    'oi': oi, 'doi_dt': doi_dt, 'rv': rv, 'e': e,
                    'b': bd,  'h': h,             'c': c,
                }
                ensemble_archive.append(record)
                prev = shocked.copy()

            print(f"   [{shock_name:<12} / {archetype_name:<8}] Final: {attractor:<10} OI={oi:.3f}")

    # Save
    os.makedirs('data/archive', exist_ok=True)
    with open('data/archive/rea_ensemble_archive.json', 'w') as f:
        json.dump(ensemble_archive, f, indent=2)
    print(f"\n   ✅ Ensemble Archive: {len(ensemble_archive)} records")

    print("\n[3/3] Computing Policy Response Surface & Policy Curvature...")
    compute_policy_curvature(ensemble_archive)

    return ensemble_archive


def compute_policy_curvature(archive):
    """
    Policy Response Surface: for each (shock × epoch), compute ΔOI under each policy.
    Policy Curvature = std(ΔOI across policies) per state.
    High curvature → policy-sensitive region.
    Low curvature  → policy-invariant (geometry-determined) region.
    """
    print("\n" + "=" * 65)
    print("📐 POLICY RESPONSE SURFACE & POLICY CURVATURE")
    print("=" * 65)

    # Group by (shock, epoch)
    by_state = defaultdict(dict)
    for rec in archive:
        key = (rec['shock'], rec['epoch'])
        by_state[key][rec['policy']] = rec

    curvature_by_attractor = defaultdict(list)
    curvature_by_region = []
    limit_cycle_sigs = []

    for (shock, epoch), policy_map in sorted(by_state.items()):
        if len(policy_map) < len(NAVIGATOR_ARCHETYPES):
            continue
        oi_vals = [policy_map[p]['oi']  for p in NAVIGATOR_ARCHETYPES]
        rv_vals = [policy_map[p]['rv']  for p in NAVIGATOR_ARCHETYPES]
        attractors = [policy_map[p]['attractor'] for p in NAVIGATOR_ARCHETYPES]

        pc_oi = float(np.std(oi_vals))
        pc_rv = float(np.std(rv_vals))
        dominant = max(set(attractors), key=attractors.count)

        curvature_by_attractor[dominant].append(pc_oi)
        curvature_by_region.append({'shock': shock, 'epoch': epoch,
                                     'pc_oi': pc_oi, 'pc_rv': pc_rv,
                                     'dominant_attractor': dominant})

    # Report per-attractor policy curvature
    print(f"\n{'Dominant Attractor':<16} {'Avg PC(OI)':>12} {'Max PC(OI)':>12} {'N':>5} {'Interpretation'}")
    print("-" * 75)
    for attractor in ['Rigid', 'Brittle', 'Plastic', 'Explosive', 'Zombie']:
        vals = curvature_by_attractor.get(attractor, [])
        if not vals:
            print(f"{attractor:<16} {'—':>12} {'—':>12} {'0':>5}")
            continue
        avg_pc = np.mean(vals)
        max_pc = np.max(vals)
        interp = "Policy-SENSITIVE" if avg_pc > 0.05 else "Policy-INVARIANT"
        print(f"{attractor:<16} {avg_pc:>12.4f} {max_pc:>12.4f} {len(vals):>5}   {interp}")

    # Detect Limit Cycles within policy trajectories
    print("\n🔄 LIMIT CYCLE DETECTION (Cross-Policy)")
    for archetype in NAVIGATOR_ARCHETYPES:
        for shock in ['Resource', 'Population', 'Mixed', 'Knowledge']:
            traj = [r for r in archive if r['policy'] == archetype and r['shock'] == shock]
            traj.sort(key=lambda x: x['epoch'])
            seq = [r['attractor'] for r in traj]
            for length in range(2, 5):
                for start in range(len(seq) - length * 2):
                    if seq[start:start+length] == seq[start+length:start+length*2] and len(set(seq[start:start+length])) > 1:
                        cycle_str = ' → '.join(seq[start:start+length])
                        limit_cycle_sigs.append({'policy': archetype, 'shock': shock, 'cycle': cycle_str})
                        print(f"  ✅ [{archetype}/{shock}] Limit Cycle: {cycle_str}")
                        break

    if not limit_cycle_sigs:
        print("  ⚠️  No Limit Cycles found across any policy/shock combination.")
        print("     Trajectories converge to single attractor basins under all archetypes.")
        print("     Hypothesis: Limit Cycles require Meta-Navigation (policy switching).")
    else:
        print(f"\n  🌀 {len(limit_cycle_sigs)} Limit Cycle signatures found.")

    return curvature_by_region, limit_cycle_sigs


# -----------------------------------------------------------------------
# Shock application helpers
# -----------------------------------------------------------------------
def _apply_resource_shock(state):
    for t in range(3):
        nnz = state.S_sparse[t].nnz
        if nnz > 0:
            drop = np.random.choice(nnz, int(nnz * 0.85), replace=False)
            state.S_sparse[t].data[drop] = 0.0
            state.S_sparse[t].eliminate_zeros()

def _apply_population_shock(state, niche, target_trace, emit_trace):
    compressors = np.where(niche == 1)[0]
    if len(compressors) == 0: return
    dead = np.random.choice(compressors, max(1, int(len(compressors) * 0.7)), replace=False)
    state.agent_survival_rate -= len(dead) / N_AGENTS
    for a in dead:
        state.trust_matrix[a, :] = 1.0

def _apply_knowledge_shock(state):
    # Severe trust erosion (knowledge shock = loss of epistemic coherence)
    state.trust_matrix = np.where(
        np.random.rand(*state.trust_matrix.shape) < 0.7,
        1.0, state.trust_matrix)


if __name__ == "__main__":
    build_policy_ensemble_archive()
