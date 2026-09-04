import numpy as np
import scipy.sparse as sp
import json
import os
import sys
sys.path.append('scripts')
from dynamics_extractor import (
    generate_topology, SimState, run_step,
    get_kmeans_model, classify_attractor
)
from tiannara_ucc.core import extract_basin_metrics
from collections import defaultdict

N_NODES    = 1000
N_AGENTS   = 100
WALK_STEPS = 10
RADIUS     = 5
MORTALITY  = 0.0025
VERIFY_EPOCHS   = 15   # Counterfactual depth to measure PE/PR
TRANSFER_EPOCHS = 30   # Post-transfer observation window

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
        Phi = [state.S_sparse[t].dot(state.trust_matrix.T) for t in range(3)]
        phi = np.zeros((N_AGENTS, RADIUS * 2), dtype=np.float32)
        for t in range(3):
            mask = (tt == t)
            if np.any(mask):
                idx = np.where(mask)[0]
                phi[mask] = Phi[t][c_nodes[mask], idx[:, None]]
        noise = np.random.uniform(0, 0.05, size=(N_AGENTS, RADIUS * 2))
        state.pos = c_nodes[np.arange(N_AGENTS), np.argmax(phi + noise, axis=1)]
        for a in np.random.permutation(N_AGENTS):
            n_id = state.pos[a]; t = tt[a]
            row = state.S_sparse[t].getrow(n_id)
            if row.nnz == 0: continue
            authors, available = row.indices, row.data.copy()
            req = 5.0 - state.agent_consumed_amt[a]
            if req <= 0: continue
            score = available + tau * np.random.gumbel(size=len(authors))
            order = np.argsort(-score)
            authors, available = authors[order], available[order]
            for i, auth in enumerate(authors):
                if req <= 0: break
                take = min(available[i], req)
                C_rows[t].append(n_id); C_cols[t].append(auth); C_data[t].append(take)
                req -= take; state.agent_consumed_amt[a] += take
                if auth != a:
                    state.trust_matrix[a, auth] = min(5.0, state.trust_matrix[a, auth] + alpha_gain)
        for a in range(N_AGENTS):
            t = et[a]
            E_rows[t].append(state.pos[a]); E_cols[t].append(a); E_data[t].append(rho)
    MAX_PHI = rho / 2.5
    for t in range(3):
        if len(C_data[t]) > 0:
            Cm = sp.csr_matrix((C_data[t], (C_rows[t], C_cols[t])), shape=(N, N_AGENTS))
            state.S_sparse[t] = state.S_sparse[t] - Cm
        if len(E_data[t]) > 0:
            Em = sp.csr_matrix((E_data[t], (E_rows[t], E_cols[t])), shape=(N, N_AGENTS))
            state.S_sparse[t] = state.S_sparse[t].multiply(gamma) + K_csr.dot(Em)
        else:
            state.S_sparse[t] = state.S_sparse[t].multiply(gamma)
        state.S_sparse[t].data = np.clip(state.S_sparse[t].data, 0.0, MAX_PHI)
        state.S_sparse[t].data[state.S_sparse[t].data < 1e-3] = 0.0
        state.S_sparse[t].eliminate_zeros()
    state.trust_matrix = np.maximum(1.0, state.trust_matrix)
    for a in np.where(np.random.rand(N_AGENTS) < MORTALITY)[0]:
        state.trust_matrix[a, :] = 1.0; state.agent_consumed_amt[a] = 0.0


def measure_agency(state, neighbors, K_csr, tt, et):
    """Branch all 5 policies for VERIFY_EPOCHS. Return CA, PE, PR, oi_by_policy."""
    oi_by = {}
    for name, coords in NAVIGATOR_ARCHETYPES.items():
        br = state.copy()
        for _ in range(VERIFY_EPOCHS):
            run_archetype_epoch(br, neighbors, K_csr, tt, et, coords)
        ucc = extract_basin_metrics(br.pos, br.trust_matrix, br.agent_consumed_amt,
                                    br.active_triplets, br.target_node, N_NODES)
        bd = (ucc['scp'] / max(1, state.scp_400)) - 0.178
        e  = max(0.0, ucc['dcr'] - state.dcr_400)
        rv = max(0.0, bd) * e + 0.2
        h  = min(1.0, ucc['radius_of_gyration'] / 500.0)
        oi_by[name] = (0.4 * rv) + (0.3 * e) + (0.5 * max(0, bd)) + (0.2 * h)
    vals = list(oi_by.values())
    ca = float(max(vals) - min(vals))
    pr = float(np.mean(vals) - np.std(vals))
    pe = sum(1 for v in vals if v > 0.05)
    region = ("GENERATOR" if ca >= 5 and pe >= 4 and pr >= 0 else
              "CORRIDOR"  if pe >= 3 and pr >= 0 else
              "CLIFF"     if ca >= 1 else "DESERT")
    return ca, pe, pr, region, oi_by


def run_generator_economics():
    print("🔬 [Phase 12A] Generator Economics: Is Generativity Transmissible?")
    print("=" * 70)

    mean_g, std_g, centroids_g = get_kmeans_model()
    neighbors, K_csr = generate_topology(N_NODES, k_ring=RADIUS * 2)

    np.random.seed(42)
    niche = np.zeros(N_AGENTS, dtype=np.int32)
    niche[33:66] = 1; niche[66:] = 2
    tt = np.zeros(N_AGENTS, dtype=np.int32); tt[niche == 2] = 1
    et = np.copy(niche)

    print("\n[1/4] Building shared baseline (400 epochs)...")
    pos = np.random.randint(0, N_NODES, size=N_AGENTS)
    trust = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S = [sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32) for _ in range(3)]
    baseline = SimState(pos, trust, S, niche, np.zeros(N_AGENTS), [])
    for ep in range(1, 401):
        run_step(baseline, ep, neighbors, K_csr, tt, et, MORTALITY, WALK_STEPS, 'repair')
        if ep >= 380:
            ucc = extract_basin_metrics(baseline.pos, baseline.trust_matrix,
                                        baseline.agent_consumed_amt, baseline.active_triplets,
                                        baseline.target_node, N_NODES)
            baseline.dcr_400 = max(baseline.dcr_400, ucc['dcr'])
            baseline.scp_400 = max(baseline.scp_400, ucc['scp'])
    print(f"   Baseline locked: DCR={baseline.dcr_400:.3f}")

    # Step 2: Grow a Trader into a Generator burst
    print("\n[2/4] Cultivating Trader into Generator state (45 epochs)...")
    trader_state = baseline.copy()
    trader_coords = NAVIGATOR_ARCHETYPES['Trader']
    for ep in range(45):
        run_archetype_epoch(trader_state, neighbors, K_csr, tt, et, trader_coords)
        S_sum = np.array(trader_state.S_sparse[0].sum(axis=0) +
                         trader_state.S_sparse[1].sum(axis=0) +
                         trader_state.S_sparse[2].sum(axis=0)).flatten()
        if S_sum.max() > 0: trader_state.target_node = int(np.argmax(S_sum))

    ca_pre, pe_pre, pr_pre, region_pre, oi_pre = measure_agency(
        trader_state, neighbors, K_csr, tt, et)
    print(f"   Trader Pre-Transfer: Region={region_pre}, CA={ca_pre:.2f}, PE={pe_pre}, PR={pr_pre:.3f}")
    print(f"   OI by policy: { {k: round(v,2) for k,v in oi_pre.items()} }")

    # Step 3: Build Phoenix in DESERT
    print("\n[3/4] Cultivating Phoenix into DESERT state (45 epochs)...")
    phoenix_state = baseline.copy()
    phoenix_coords = NAVIGATOR_ARCHETYPES['Phoenix']
    for ep in range(45):
        run_archetype_epoch(phoenix_state, neighbors, K_csr, tt, et, phoenix_coords)
        S_sum = np.array(phoenix_state.S_sparse[0].sum(axis=0) +
                         phoenix_state.S_sparse[1].sum(axis=0) +
                         phoenix_state.S_sparse[2].sum(axis=0)).flatten()
        if S_sum.max() > 0: phoenix_state.target_node = int(np.argmax(S_sum))

    ca_px_pre, pe_px_pre, pr_px_pre, region_px_pre, oi_px_pre = measure_agency(
        phoenix_state, neighbors, K_csr, tt, et)
    print(f"   Phoenix Pre-Transfer: Region={region_px_pre}, CA={ca_px_pre:.2f}, PE={pe_px_pre}, PR={pr_px_pre:.3f}")

    # Step 4: Transfer — three modes
    print("\n[4/4] Generativity Transfer Experiments...")
    print("=" * 70)

    # --- Mode A: Full Trust Topology Transfer ---
    print("\n[Mode A] Full Trust Topology Transfer (Phoenix adopts Trader's trust matrix)")
    px_a = phoenix_state.copy()
    px_a.trust_matrix = np.copy(trader_state.trust_matrix)  # Transfer trust topology
    ca_a, pe_a, pr_a, region_a, oi_a = measure_agency(px_a, neighbors, K_csr, tt, et)

    # Check donor retention
    ca_tr_a, pe_tr_a, pr_tr_a, region_tr_a, _ = measure_agency(
        trader_state, neighbors, K_csr, tt, et)

    print(f"   Recipient (Phoenix+Trader Trust):  Region={region_a}, CA={ca_a:.2f}, PE={pe_a}, PR={pr_a:.3f}")
    print(f"   Donor    (Trader after transfer):  Region={region_tr_a}, CA={ca_tr_a:.2f}, PE={pe_tr_a}, PR={pr_tr_a:.3f}")
    _report_transfer("Mode A: Trust Topology", pe_px_pre, pe_a, pe_pre, pe_tr_a)

    # --- Mode B: Constitutional Adoption (Phoenix switches to Trader coordinates) ---
    print("\n[Mode B] Constitutional Adoption (Phoenix switches to Trader coordinates, 20 epochs)")
    px_b = phoenix_state.copy()
    for ep in range(20):
        run_archetype_epoch(px_b, neighbors, K_csr, tt, et, trader_coords)
    ca_b, pe_b, pr_b, region_b, oi_b = measure_agency(px_b, neighbors, K_csr, tt, et)

    print(f"   Recipient (Phoenix→Trader coords):  Region={region_b}, CA={ca_b:.2f}, PE={pe_b}, PR={pr_b:.3f}")
    _report_transfer("Mode B: Constitutional Switch", pe_px_pre, pe_b, pe_pre, pe_pre)

    # --- Mode C: Signal Field Transplant (Trader's signal fields → Phoenix's world) ---
    print("\n[Mode C] Signal Field Transplant (Trader's S fields transplanted into Phoenix)")
    px_c = phoenix_state.copy()
    px_c.S_sparse = [s.copy() for s in trader_state.S_sparse]
    ca_c, pe_c, pr_c, region_c, oi_c = measure_agency(px_c, neighbors, K_csr, tt, et)

    print(f"   Recipient (Phoenix+Trader Signals): Region={region_c}, CA={ca_c:.2f}, PE={pe_c}, PR={pr_c:.3f}")
    _report_transfer("Mode C: Signal Field", pe_px_pre, pe_c, pe_pre, pe_pre)

    # Final summary
    print("\n" + "=" * 70)
    print("PHASE 12A SUMMARY: Generativity Transfer Results")
    print("=" * 70)
    print(f"{'Mode':<30} {'Donor Region':<14} {'Recip Region':<14} {'ΔPFE'}")
    print("-" * 70)
    for label, r_donor, r_recip, dpe in [
        ("A: Trust Topology",     region_tr_a, region_a, pe_a - pe_px_pre),
        ("B: Constitutional",     "N/A",        region_b, pe_b - pe_px_pre),
        ("C: Signal Field",       "N/A",        region_c, pe_c - pe_px_pre),
    ]:
        print(f"{label:<30} {r_donor:<14} {r_recip:<14} {dpe:+.0f}")

    os.makedirs('data/archive', exist_ok=True)
    with open('data/archive/rea_generator_economics.json', 'w') as f:
        json.dump({'mode_a': {'region': region_a, 'ca': ca_a, 'pe': pe_a, 'pr': pr_a},
                   'mode_b': {'region': region_b, 'ca': ca_b, 'pe': pe_b, 'pr': pr_b},
                   'mode_c': {'region': region_c, 'ca': ca_c, 'pe': pe_c, 'pr': pr_c},
                   'donor_retention': {'region': region_tr_a, 'ca': ca_tr_a, 'pe': pe_tr_a}}, f, indent=2)
    print("\n✅ PHASE 12A COMPLETE.")


def _report_transfer(label, pe_before, pe_after, pe_donor_before, pe_donor_after):
    delta = pe_after - pe_before
    donor_delta = pe_donor_after - pe_donor_before
    result = "UNKNOWN"
    if delta > 0 and donor_delta >= 0:
        result = "✅ COPYABLE — Generativity was duplicated (not conserved)"
    elif delta > 0 and donor_delta < 0:
        result = "🔄 ZERO-SUM — Generativity transferred but donor lost it"
    elif delta <= 0 and pe_after >= 4:
        result = "🔒 INTRINSIC — Recipient already had it; no change needed"
    else:
        result = "❌ NON-TRANSMISSIBLE — Transfer had no effect"
    print(f"   → {label}: ΔPE(recipient)={delta:+.0f}, ΔPE(donor)={donor_delta:+.0f} | {result}")


if __name__ == "__main__":
    run_generator_economics()
