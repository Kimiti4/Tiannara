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

N_NODES    = 1000
N_AGENTS   = 100
WALK_STEPS = 10
RADIUS     = 5
MORTALITY  = 0.0025
FLOURISH_EPOCHS    = 150   # Long unshocked run to sample "flourishing space"
COUNTERFACTUAL_DEPTH = 10  # Steps per policy branch to measure outcomes

NAVIGATOR_ARCHETYPES = {
    'Settler':  (0.95, 2.5,  0.05, 0.01),
    'Explorer': (0.60, 4.5,  0.10, 3.00),
    'Trader':   (0.85, 3.0,  0.50, 0.50),
    'Survivor': (0.98, 1.5,  0.02, 0.01),
    'Phoenix':  (0.40, 5.00, 0.80, 5.00),
}

def run_archetype_epoch(state, neighbors, K_csr, tt, et, coords):
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
            mask = (tt == t)
            if np.any(mask):
                agents_idx = np.where(mask)[0]
                phi[mask] = Phi_fields[t][c_nodes[mask], agents_idx[:, None]]
        noise = np.random.uniform(0, 0.05, size=(N_AGENTS, RADIUS * 2))
        state.pos = c_nodes[np.arange(N_AGENTS), np.argmax(phi + noise, axis=1)]
        agent_order = np.random.permutation(N_AGENTS)
        for a in agent_order:
            n_id = state.pos[a]; t = tt[a]
            row = state.S_sparse[t].getrow(n_id)
            if row.nnz == 0: continue
            authors = row.indices; available = row.data.copy()
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
                required -= take; state.agent_consumed_amt[a] += take
                if author != a:
                    state.trust_matrix[a, author] = min(5.0, state.trust_matrix[a, author] + alpha_gain)
        for a in range(N_AGENTS):
            t = et[a]
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
        state.S_sparse[t].data = np.clip(state.S_sparse[t].data, 0.0, rho / 2.5)
        state.S_sparse[t].data[state.S_sparse[t].data < 1e-3] = 0.0
        state.S_sparse[t].eliminate_zeros()
    state.trust_matrix = np.maximum(1.0, state.trust_matrix)
    dead = np.where(np.random.rand(N_AGENTS) < MORTALITY)[0]
    for a in dead:
        state.trust_matrix[a, :] = 1.0; state.agent_consumed_amt[a] = 0.0


def compute_cross_policy_agency(state, neighbors, K_csr, tt, et, mean_g, std_g, centroids_g):
    """Branch 5 policies from current state for COUNTERFACTUAL_DEPTH epochs. Return CA, PE, PR."""
    oi_outcomes = {}
    for archetype, coords in NAVIGATOR_ARCHETYPES.items():
        branch = state.copy()
        for _ in range(COUNTERFACTUAL_DEPTH):
            run_archetype_epoch(branch, neighbors, K_csr, tt, et, coords)
        ucc = extract_basin_metrics(branch.pos, branch.trust_matrix, branch.agent_consumed_amt,
                                    branch.active_triplets, branch.target_node, N_NODES)
        # OI proxy from ucc
        bd = ucc['scp'] / max(1, state.scp_400) - 0.178
        e  = max(0.0, ucc['dcr'] - state.dcr_400)
        rv = max(0.0, bd) * e + 0.2
        h  = min(1.0, ucc['radius_of_gyration'] / 500.0)
        oi = (0.4 * rv) + (0.3 * e) + (0.5 * max(0, bd)) + (0.2 * h)
        oi_outcomes[archetype] = oi
    oi_vals = list(oi_outcomes.values())
    ca = float(max(oi_vals) - min(oi_vals))
    pr = float(np.mean(oi_vals) - np.std(oi_vals))
    pe = sum(1 for v in oi_vals if v > 0.05)
    return ca, pe, pr, oi_outcomes


def classify_agency_region(ca, pe, pr):
    if ca < 1.0:
        return "DESERT"
    if pe <= 2 and pr < 0:
        return "CLIFF"
    if ca >= 5.0 and pe >= 4 and pr >= 0:
        return "GENERATOR"
    if pe >= 3 and pr >= 0:
        return "CORRIDOR"
    return "CLIFF"


def run_generator_search():
    print("🌱 [Phase 11C] Generator Search — Sampling Flourishing Space")
    print("=" * 65)
    print("Hypothesis: Generator states exist but the crisis archive never sampled them.")
    print("Method: Long (150-epoch) unshocked baselines under all 5 archetypes.\n")

    mean_g, std_g, centroids_g = get_kmeans_model()
    neighbors, K_csr = generate_topology(N_NODES, k_ring=RADIUS * 2)

    np.random.seed(42)
    niche = np.zeros(N_AGENTS, dtype=np.int32)
    niche[33:66] = 1; niche[66:] = 2
    tt = np.zeros(N_AGENTS, dtype=np.int32); tt[niche == 2] = 1
    et = np.copy(niche)

    # Shared warm-start baseline
    print("[1/2] Warming up baseline (400 epochs)...")
    pos = np.random.randint(0, N_NODES, size=N_AGENTS)
    trust = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S = [sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32) for _ in range(3)]
    baseline = SimState(pos, trust, S, niche, np.zeros(N_AGENTS), [])
    for epoch in range(1, 401):
        run_step(baseline, epoch, neighbors, K_csr, tt, et, MORTALITY, WALK_STEPS, 'repair')
        if epoch >= 380:
            ucc = extract_basin_metrics(baseline.pos, baseline.trust_matrix,
                                        baseline.agent_consumed_amt, baseline.active_triplets,
                                        baseline.target_node, N_NODES)
            baseline.dcr_400 = max(baseline.dcr_400, ucc['dcr'])
            baseline.scp_400 = max(baseline.scp_400, ucc['scp'])
    print(f"   Baseline locked: DCR={baseline.dcr_400:.3f}, SCP={baseline.scp_400}")

    print("\n[2/2] Flourishing-space search (NO SHOCKS)...")
    print(f"{'Archetype':<10} {'Ep':>4} {'CA':>8} {'PE':>4} {'PR':>8}  {'Region':<12} {'Best Policy':<12} {'Best OI':>8}")
    print("-" * 85)

    all_results = []
    generator_states = []
    corridor_states  = []
    region_counts    = {'DESERT': 0, 'CLIFF': 0, 'CORRIDOR': 0, 'GENERATOR': 0}

    for archetype_name, coords in NAVIGATOR_ARCHETYPES.items():
        state = baseline.copy()
        oi_history = []

        for epoch_i in range(FLOURISH_EPOCHS):
            run_archetype_epoch(state, neighbors, K_csr, tt, et, coords)
            S_sum = np.array(state.S_sparse[0].sum(axis=0) +
                             state.S_sparse[1].sum(axis=0) +
                             state.S_sparse[2].sum(axis=0)).flatten()
            if S_sum.max() > 0: state.target_node = int(np.argmax(S_sum))

            # Only measure Agency every 5 epochs (expensive counterfactual)
            if epoch_i % 5 == 0:
                ca, pe, pr, oi_outcomes = compute_cross_policy_agency(
                    state, neighbors, K_csr, tt, et, mean_g, std_g, centroids_g)

                region = classify_agency_region(ca, pe, pr)
                region_counts[region] += 1

                best_policy = max(oi_outcomes, key=oi_outcomes.get)
                best_oi = oi_outcomes[best_policy]

                rec = {'archetype': archetype_name, 'epoch': epoch_i, 'ca': ca,
                       'pe': pe, 'pr': pr, 'region': region, 'best_policy': best_policy,
                       'best_oi': best_oi, 'oi_outcomes': oi_outcomes}
                all_results.append(rec)

                if region == 'GENERATOR':
                    generator_states.append(rec)
                elif region == 'CORRIDOR':
                    corridor_states.append(rec)

                print(f"{archetype_name:<10} {epoch_i:>4} {ca:>8.3f} {pe:>4} {pr:>8.3f}  {region:<12} {best_policy:<12} {best_oi:>8.3f}")

    # Summary
    print("\n[Region Distribution — Flourishing Space]")
    print(f"{'Region':<14} {'Count':>7}  Description")
    print("-" * 60)
    desc = {
        'DESERT':    'Geometry-locked. Policy irrelevant.',
        'CORRIDOR':  'Stable. Many viable futures.',
        'CLIFF':     'Fragile. One correct choice.',
        'GENERATOR': 'High CA + High PE + Positive PR. Optionality creation zone.',
    }
    for region in ['DESERT', 'CORRIDOR', 'CLIFF', 'GENERATOR']:
        n = region_counts.get(region, 0)
        print(f"{region:<14} {n:>7}  {desc[region]}")

    # Verdict
    print("\n[GENERATOR SEARCH VERDICT]")
    if generator_states:
        print(f"  ✅ GENERATOR STATES FOUND: {len(generator_states)}")
        print("  Interpretation: Robust Agency exists in flourishing (unshocked) space.")
        print("  Generator states are REAL — the crisis archive simply never visited them.")
        print("\n  Generator State Coordinates (ASV++):")
        for gs in generator_states[:3]:
            print(f"    [{gs['archetype']}/Epoch {gs['epoch']}] CA={gs['ca']:.2f}, PE={gs['pe']}, PR={gs['pr']:.2f}")
            print(f"      OI by policy: { {k: round(v,2) for k,v in gs['oi_outcomes'].items()} }")
    elif corridor_states:
        print(f"  ⚠️  NO GENERATOR STATES FOUND, but {len(corridor_states)} CORRIDOR states detected.")
        print("  Interpretation: Robust Agency exists but at lower intensity.")
        print("  Generator states may require longer flourishing periods or policy switching.")
        for cs in corridor_states[:3]:
            print(f"    [{cs['archetype']}/Epoch {cs['epoch']}] CA={cs['ca']:.2f}, PE={cs['pe']}, PR={cs['pr']:.2f}")
    else:
        print("  ❌ NO GENERATOR OR CORRIDOR STATES FOUND.")
        print("  Interpretation: Adaptation space may be fundamentally DESERT + CLIFF.")
        print("  All adaptation is intrinsically fragile. Agency is cliff-like by nature.")
        print("  Implication: Meta-Navigation (policy switching) may be REQUIRED to create Generators.")

    os.makedirs('data/archive', exist_ok=True)
    with open('data/archive/rea_generator_search.json', 'w') as f:
        json.dump(all_results, f, indent=2)

    print(f"\n✅ PHASE 11C COMPLETE. {len(all_results)} states sampled.")
    return all_results, generator_states, corridor_states


if __name__ == "__main__":
    run_generator_search()
