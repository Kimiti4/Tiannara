"""
Phase 11.5 v4: Generativity Causality — Live State Capture
============================================================

Root cause of v1/v2/v3 failures:
  The OI discriminator only fires during brief Generator-burst windows
  (specific epochs where signals concentrate at target_node).
  Outside those windows, OI=0.0800 (constant floor).

  Previous attempts measured from a state cultivated AWAY from the warm-up,
  and then did agency measurement 10 epochs LATER, by which point the
  generator burst had collapsed.

v4 fix: Re-run Phase 11C's exact loop, capture live state AT the Generator epoch,
  and immediately run the transfer experiments from that live state.

  Donor:    Trader at epoch 40 (CA=75.7, PE=5, PR high) — verified Generator burst
  Recipient: Trader at epoch 10 (CA=0, DESERT) — same archetype, different history
             (acts as the "low-CA" control for causal isolation)

  Alternative: Settler at epoch 5 (CA=107, GENERATOR!) for a CLIFF→GENERATOR test

Phase 11C showed Generator epochs:
  Trader:   ep=45, 85 (sparse)
  Settler:  ep=5, 65, 75, 95, 125 (many — Settler is actually the dominant Generator!)
  Survivor: ep=25, 45, 50 (moderate)

Experimental design (same A–L as planned, just with live-captured states):
  Transfer tests (what CREATES Generativity from DESERT):
    A  - Trust topology only (Donor's trust matrix → Recipient)
    B  - Constitution only (run Recipient under Trader coords for 20 epochs)
    C  - Signal fields only (Donor's S_sparse → Recipient)
    D  - History proxy (trust density rescaling)
    E  - Null control (Recipient + nothing)
  Compositional:
    F, G, H (weighted mixes)
  Destruction (what is NECESSARY in a Generator state):
    I  - Destroy topology in Donor Generator state
    J  - Destroy constitution in Donor Generator state
    K  - Destroy history in Donor Generator state
  Relational:
    L  - Coexistence: Donor + Recipient in same world, 5% signal coupling
"""

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

# ─────────────────────────── constants ──────────────────────────────────────
N_NODES    = 1000
N_AGENTS   = 100
WALK_STEPS = 10
RADIUS     = 5
MORTALITY  = 0.0025

WARM_EPOCHS          = 400
COUNTERFACTUAL_DEPTH = 10    # Phase 11C-proven depth
CONSTITUTION_EPOCHS  = 20
OBSERVATION_WINDOW   = 30
GHL_MAX_EPOCHS       = 80
GHL_CHECK_INTERVAL   = 5
COEXIST_COUPLING     = 0.05

# Capture targets from Phase 11C archive analysis
# Donor: Trader at epoch 40 (verified CA=75.7 in archive)
# Recipient: Trader at epoch 10 (CA=0, DESERT baseline)
DONOR_ARCHETYPE     = 'Trader'
DONOR_EPOCH         = 40      # first high-CA epoch for Trader
RECIPIENT_ARCHETYPE = 'Trader'
RECIPIENT_EPOCH     = 10      # DESERT epoch (CA=0)

# Fallback: Settler at ep=5 has CA=107 if Trader ep=40 doesn't fire today
ALT_DONOR_ARCHETYPE = 'Settler'
ALT_DONOR_EPOCH     = 5

NAVIGATOR_ARCHETYPES = {
    'Settler':  (0.95, 2.5,  0.05, 0.01),
    'Explorer': (0.60, 4.5,  0.10, 3.00),
    'Trader':   (0.85, 3.0,  0.50, 0.50),
    'Survivor': (0.98, 1.5,  0.02, 0.01),
    'Phoenix':  (0.40, 5.00, 0.80, 5.00),
}


# ─────────────────────────── simulation ──────────────────────────────────────
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
                    state.trust_matrix[a, auth] = min(5.0,
                        state.trust_matrix[a, auth] + alpha_gain)
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


def update_target_node(state):
    S_sum = np.array(state.S_sparse[0].sum(axis=0) +
                     state.S_sparse[1].sum(axis=0) +
                     state.S_sparse[2].sum(axis=0)).flatten()
    if S_sum.max() > 0:
        state.target_node = int(np.argmax(S_sum))


# ─────────────────────────── agency measurement (Phase 11C exact) ────────────
def compute_agency(state, neighbors, K_csr, tt, et):
    oi_outcomes = {}
    for name, coords in NAVIGATOR_ARCHETYPES.items():
        branch = state.copy()
        for _ in range(COUNTERFACTUAL_DEPTH):
            run_archetype_epoch(branch, neighbors, K_csr, tt, et, coords)
        ucc = extract_basin_metrics(branch.pos, branch.trust_matrix,
                                    branch.agent_consumed_amt, branch.active_triplets,
                                    branch.target_node, N_NODES)
        bd = ucc['scp'] / max(1, state.scp_400) - 0.178
        e  = max(0.0, ucc['dcr'] - state.dcr_400)
        rv = max(0.0, bd) * e + 0.2
        h  = min(1.0, ucc['radius_of_gyration'] / 500.0)
        oi = (0.4 * rv) + (0.3 * e) + (0.5 * max(0, bd)) + (0.2 * h)
        oi_outcomes[name] = oi
    vals = list(oi_outcomes.values())
    ca = float(max(vals) - min(vals))
    pr = float(np.mean(vals) - np.std(vals))
    pe = sum(1 for v in vals if v > 0.05)
    region = ("GENERATOR" if ca >= 5 and pe >= 4 and pr >= 0 else
              "CORRIDOR"  if pe >= 3 and pr >= 0 else
              "CLIFF"     if ca >= 1 else "DESERT")
    return ca, pe, pr, region, oi_outcomes


def is_discriminating(oi_outcomes):
    vals = list(oi_outcomes.values())
    return (max(vals) - min(vals)) > 0.01


# ─────────────────────────── live state capture ───────────────────────────────
def capture_live_state(baseline, archetype_name, target_epoch,
                       neighbors, K_csr, tt, et):
    """
    Re-run Phase 11C's exact loop up to target_epoch.
    Return the live state at that epoch with valid target_node.
    Also return CA at that epoch as validation.
    """
    coords = NAVIGATOR_ARCHETYPES[archetype_name]
    state = baseline.copy()
    ca_at_epoch = 0.0
    region_at = 'DESERT'
    oi_at = {}

    print(f"   Capturing {archetype_name} at epoch {target_epoch}...")
    for ep in range(target_epoch + 1):
        run_archetype_epoch(state, neighbors, K_csr, tt, et, coords)
        S_sum = np.array(state.S_sparse[0].sum(axis=0) +
                         state.S_sparse[1].sum(axis=0) +
                         state.S_sparse[2].sum(axis=0)).flatten()
        if S_sum.max() > 0:
            state.target_node = int(np.argmax(S_sum))

        # Measure immediately after target_node refresh (exactly like Phase 11C)
        if ep == target_epoch:
            ca_at_epoch, pe, pr, region_at, oi_at = compute_agency(
                state, neighbors, K_csr, tt, et)
            ok = is_discriminating(oi_at)
            print(f"   {archetype_name} ep={ep}: CA={ca_at_epoch:.2f} PE={pe} "
                  f"region={region_at}  discriminating={'✅' if ok else '❌'}")
            if not ok:
                print(f"   OI: {oi_at}")
            return state, ca_at_epoch, region_at, ok

    return state, ca_at_epoch, region_at, False


def scan_for_generator_epoch(baseline, archetype_name, scan_epochs,
                              neighbors, K_csr, tt, et):
    """
    Scan multiple epochs to find one with high CA (≥5) live.
    This handles stochasticity — the exact Generator epoch may shift with seed.
    """
    coords = NAVIGATOR_ARCHETYPES[archetype_name]
    state = baseline.copy()
    best_state = None; best_ca = 0.0; best_ep = -1; best_region = 'DESERT'

    print(f"   Scanning {archetype_name} epochs {scan_epochs}...")
    for ep in range(max(scan_epochs) + 1):
        run_archetype_epoch(state, neighbors, K_csr, tt, et, coords)
        S_sum = np.array(state.S_sparse[0].sum(axis=0) +
                         state.S_sparse[1].sum(axis=0) +
                         state.S_sparse[2].sum(axis=0)).flatten()
        if S_sum.max() > 0:
            state.target_node = int(np.argmax(S_sum))
        if ep in scan_epochs:
            ca, pe, pr, region, oi = compute_agency(state, neighbors, K_csr, tt, et)
            disc = is_discriminating(oi)
            print(f"     ep={ep:>4}  CA={ca:>8.2f}  PE={pe}  region={region:<10} "
                  f"{'✅' if disc else '  '}")
            if ca > best_ca and disc:
                best_ca = ca; best_ep = ep; best_region = region
                best_state = state.copy()
    return best_state, best_ca, best_ep, best_region


# ─────────────────────────── GHL ─────────────────────────────────────────────
def measure_ghl(state, neighbors, K_csr, tt, et, op_coords):
    s = state.copy()
    ghl = GHL_MAX_EPOCHS + GHL_CHECK_INTERVAL
    trace = []
    for t in range(0, GHL_MAX_EPOCHS, GHL_CHECK_INTERVAL):
        for _ in range(GHL_CHECK_INTERVAL):
            run_archetype_epoch(s, neighbors, K_csr, tt, et, op_coords)
            update_target_node(s)
        _, pe, _, _, _ = compute_agency(s, neighbors, K_csr, tt, et)
        trace.append(pe)
        if pe < 4:
            ghl = t + GHL_CHECK_INTERVAL
            break
    return ghl, trace


# ─────────────────────────── transfer helpers ─────────────────────────────────
def blend_trust(base, donor, alpha):
    return (1.0 - alpha) * np.asarray(base) + alpha * np.asarray(donor)

def blend_signals(base_S, donor_S, alpha):
    return [(1.0 - alpha) * base_S[t] + alpha * donor_S[t] for t in range(3)]

def inject_history_proxy(recipient, donor, alpha):
    donor_density = np.mean(donor.trust_matrix, axis=1)
    recip_density = np.mean(recipient.trust_matrix, axis=1) + 1e-6
    scale = 1.0 + alpha * (donor_density / recip_density - 1.0)
    recipient.trust_matrix = np.clip(
        recipient.trust_matrix * scale[:, None], 1.0, 5.0)

def destroy_topology(state):
    state.trust_matrix = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)

def destroy_history(state):
    m = np.mean(state.trust_matrix, axis=1, keepdims=True)
    state.trust_matrix = np.clip(
        np.ones((N_AGENTS, N_AGENTS), dtype=np.float32) * m, 1.0, 5.0)


# ─────────────────────────── classification ──────────────────────────────────
def conservation_verdict(pe_rcv_before, pe_rcv_after, pe_don_before,
                         pe_don_after, pe_null):
    gained = (pe_rcv_after - pe_rcv_before) > 0
    donor_lost = (pe_don_after - pe_don_before) < -0.5
    if pe_null >= 4:
        return "🌱 CATALYTIC — Null recipient self-generated"
    if not gained:
        return "❌ NON-TRANSMISSIBLE"
    if gained and donor_lost:
        return "🔄 CONSERVED — Zero-sum"
    return "✅ REPLICABLE — Donor retained; recipient gained"

def assign_roles(contrib, necessity):
    mapping = [('Topology','A','I'), ('Constitution','B','J'),
               ('Signals','C',None), ('History','D','K')]
    roles = {}
    for name, xk, dk in mapping:
        c = contrib.get(xk, 0); n = necessity.get(dk, 0) if dk else 0
        if c > 0.60 and n < -0.5:   roles[name] = 'Sufficient + Necessary'
        elif c > 0.60:               roles[name] = 'Sufficient'
        elif n < -0.5:               roles[name] = 'Structural Scaffold'
        elif c > 0.15:               roles[name] = 'Amplifier'
        else:                        roles[name] = 'Inert'
    return roles

def global_type(contrib, necessity, relational):
    if relational:
        return "Emergent-Relational", "Generativity Ecosystems"
    if necessity.get('K', 0) < -0.5 and contrib.get('D', 0) > 0.60:
        return "Memory", "Cultivation Networks"
    if any(contrib.get(k, 0) > 0.60 for k in ['A','B','C']):
        return "Asset/Capability", "Markets or Generator Academy"
    if necessity.get('K', 0) < -0.5:
        return "Memory-Hybrid", "Cultivation + amplification"
    if sum(contrib.values()) > 0.4:
        return "Hybrid", "Partial markets + Cultivation"
    return "Emergent", "World-generation — not decomposable"


# ─────────────────────────── main ────────────────────────────────────────────
def run_causality_v4():
    print("🔬 [Phase 11.5 v4] Generativity Causality — Live State Capture")
    print("  KEY FIX: Re-run Phase 11C loop, capture live state at Generator epoch")
    print("  OI only fires in brief bursts — measure DURING the burst, not after")
    print("=" * 76)

    mean_g, std_g, centroids_g = get_kmeans_model()
    neighbors, K_csr = generate_topology(N_NODES, k_ring=RADIUS * 2)

    np.random.seed(42)
    niche = np.zeros(N_AGENTS, dtype=np.int32)
    niche[33:66] = 1; niche[66:] = 2
    tt = np.zeros(N_AGENTS, dtype=np.int32); tt[niche == 2] = 1
    et = np.copy(niche)
    trader_coords  = NAVIGATOR_ARCHETYPES['Trader']
    settler_coords = NAVIGATOR_ARCHETYPES['Settler']

    # ── 1. Warm-up (exact Phase 11C) ────────────────────────────────────────
    print(f"\n[1/5] Baseline warm-up ({WARM_EPOCHS} epochs)...")
    pos   = np.random.randint(0, N_NODES, size=N_AGENTS)
    trust = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S     = [sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32) for _ in range(3)]
    baseline = SimState(pos, trust, S, niche, np.zeros(N_AGENTS), [])
    for ep in range(1, WARM_EPOCHS + 1):
        run_step(baseline, ep, neighbors, K_csr, tt, et, MORTALITY, WALK_STEPS, 'repair')
        if ep >= WARM_EPOCHS - 20:
            ucc = extract_basin_metrics(baseline.pos, baseline.trust_matrix,
                                        baseline.agent_consumed_amt, baseline.active_triplets,
                                        baseline.target_node, N_NODES)
            baseline.dcr_400 = max(baseline.dcr_400, ucc['dcr'])
            baseline.scp_400 = max(baseline.scp_400, ucc['scp'])
    print(f"   Baseline: DCR={baseline.dcr_400:.3f}, SCP={baseline.scp_400}, "
          f"triplets={len(baseline.active_triplets)}")

    # ── 2. Capture donor (Generator state) ──────────────────────────────────
    print(f"\n[2/5] Capturing donor Generator state...")
    # Scan known Generator epochs (from Phase 11C archive) + nearby
    # Primary: Trader at epochs 35-50; Fallback: Settler at epochs 3-8
    trader_scan_epochs = set(range(30, 55, 5)) | set(range(80, 95, 5))
    donor_state, donor_ca, donor_ep, donor_ok = scan_for_generator_epoch(
        baseline, 'Trader', trader_scan_epochs, neighbors, K_csr, tt, et)

    if not donor_ok or donor_ca < 5.0:
        print(f"   Trader didn't fire at expected epochs. Scanning Settler...")
        settler_scan_epochs = set(range(3, 12, 2)) | set(range(60, 80, 5)) | set(range(90, 100, 5))
        donor_state, donor_ca, donor_ep, donor_ok = scan_for_generator_epoch(
            baseline, 'Settler', settler_scan_epochs, neighbors, K_csr, tt, et)
        donor_archetype = 'Settler'
    else:
        donor_archetype = 'Trader'

    if not donor_ok:
        print("\n❌ FATAL: No Generator burst found in either Trader or Settler scan.")
        print("   The Generator state is stochastic. Try changing the random seed.")
        return None

    print(f"\n   ✅ Donor captured: {donor_archetype} at epoch {donor_ep}")
    print(f"      CA={donor_ca:.2f}")
    _, pe_don, pr_don, reg_don, oi_don = compute_agency(donor_state, neighbors, K_csr, tt, et)
    print(f"      PE={pe_don}, PR={pr_don:.3f}, Region={reg_don}")
    print(f"      OI: { {k: round(v,3) for k,v in oi_don.items()} }")

    # ── 3. Capture recipient (DESERT state) ──────────────────────────────────
    print(f"\n[3/5] Capturing recipient DESERT state ({donor_archetype} ep=10)...")
    # Ep=10 is consistently DESERT (CA=0) in the archive for all archetypes
    recip_state, recip_ca, recip_ep, _ = capture_live_state(
        baseline, donor_archetype, 10, neighbors, K_csr, tt, et)
    _, pe_rcv0, pr_rcv0, reg_rcv0, _ = compute_agency(recip_state, neighbors, K_csr, tt, et)
    print(f"   Recipient: CA={recip_ca:.2f}, PE={pe_rcv0}, Region={reg_rcv0}")

    # ── 4. Full transfer reference ───────────────────────────────────────────
    print(f"\n[4/5] REFERENCE: Full donor state transplant → Recipient...")
    rcv_full = recip_state.copy()
    rcv_full.trust_matrix = np.copy(donor_state.trust_matrix)
    rcv_full.S_sparse = [s.copy() for s in donor_state.S_sparse]
    rcv_full.target_node = donor_state.target_node
    # Run under donor's archetype to activate the constitutional transfer
    donor_coords = NAVIGATOR_ARCHETYPES[donor_archetype]
    for _ in range(OBSERVATION_WINDOW):
        run_archetype_epoch(rcv_full, neighbors, K_csr, tt, et, donor_coords)
        update_target_node(rcv_full)
    _, pe_full, _, reg_full, oi_full = compute_agency(rcv_full, neighbors, K_csr, tt, et)
    pe_ceiling = pe_full
    denom = max(0.01, pe_ceiling - pe_rcv0)
    print(f"   Full Transfer: Region={reg_full}, PE={pe_full}")
    print(f"   OI ceiling: { {k: round(v,3) for k,v in oi_full.items()} }")
    print(f"   denom={denom:.2f}")

    def contrib(pe_after):
        return max(0.0, (pe_after - pe_rcv0) / denom)

    # ── 5. All experiments ───────────────────────────────────────────────────
    print(f"\n[5/5] Running experiments A–L...")
    print("=" * 76)
    results  = {}
    ghl_data = {}

    def xfer(label, state_fn, desc, op_coords=None):
        if op_coords is None: op_coords = donor_coords  # run under donor's regime
        print(f"\n  [{label}] {desc}")
        s = state_fn()
        for _ in range(OBSERVATION_WINDOW):
            run_archetype_epoch(s, neighbors, K_csr, tt, et, op_coords)
            update_target_node(s)
        ca, pe, pr, region, oi = compute_agency(s, neighbors, K_csr, tt, et)
        c = contrib(pe)
        ghl, _ = measure_ghl(s, neighbors, K_csr, tt, et, op_coords)
        print(f"        Region={region:9s}  PE={pe}  CA={ca:6.2f}  PR={pr:7.3f}"
              f"  contrib={c:.2f}  GHL={ghl}ep")
        print(f"        OI: { {k: round(v,3) for k,v in oi.items()} }")
        results[label] = {'ca': ca, 'pe': pe, 'pr': pr, 'region': region,
                          'contrib': c, 'ghl': ghl, 'desc': desc, 'kind': 'transfer'}
        ghl_data[label] = ghl
        return pe

    def destr(label, state_fn, desc):
        print(f"\n  [{label}] {desc}")
        s = state_fn()
        for _ in range(OBSERVATION_WINDOW):
            run_archetype_epoch(s, neighbors, K_csr, tt, et, donor_coords)
            update_target_node(s)
        ca, pe, pr, region, _ = compute_agency(s, neighbors, K_csr, tt, et)
        nec = float(pe - pe_don)
        print(f"        Region={region:9s}  PE={pe}  (donor was {pe_don})"
              f"  ΔPE={nec:+.1f}  {'✅ NECESSARY' if nec < -0.5 else '❌ not necessary'}")
        results[label] = {'ca': ca, 'pe': pe, 'pr': pr, 'region': region,
                          'necessity_score': nec, 'desc': desc, 'kind': 'destruction'}
        return nec

    # Transfer
    xfer('E', lambda: recip_state.copy(), "Null — Recipient + nothing (Catalytic test)")
    pe_null = results['E']['pe']

    xfer('A', lambda: _t(recip_state, donor_state), "Topology → Recipient (Donor trust matrix)")
    xfer('B', lambda: _c(recip_state, donor_coords, neighbors, K_csr, tt, et),
         f"Constitution → Recipient ({CONSTITUTION_EPOCHS} epochs donor coords)")
    xfer('C', lambda: _s(recip_state, donor_state), "Signals → Recipient (Donor S-fields)")
    xfer('D', lambda: _h(recip_state, donor_state), "History proxy → Recipient")

    # Compositional
    xfer('F', lambda: _mx(recip_state, donor_state, donor_coords, neighbors, K_csr, tt, et,
                           0.5, 10, 0.0, 0.0), "F: 50% topology + 50% constitution")
    xfer('G', lambda: _mx(recip_state, donor_state, donor_coords, neighbors, K_csr, tt, et,
                           0.25, 0, 0.75, 0.0), "G: 75% history + 25% topology")
    xfer('H', lambda: _mx(recip_state, donor_state, donor_coords, neighbors, K_csr, tt, et,
                           0.33, 7, 0.0, 0.33), "H: 33% topology + 33% constitution + 33% signals")

    # Destruction
    destr('I', lambda: _di(donor_state), "Destroy topology — reset donor trust → uniform")
    destr('J', lambda: _dj(donor_state, NAVIGATOR_ARCHETYPES['Phoenix'],
                           neighbors, K_csr, tt, et), "Destroy constitution — Phoenix coords")
    destr('K', lambda: _dk(donor_state), "Destroy history — flatten trust density")

    # Relational
    print(f"\n  [L] Relational — Donor + Recipient coexist (5% signal coupling)")
    don_cx = donor_state.copy(); rcv_cx = recip_state.copy()
    for _ in range(OBSERVATION_WINDOW):
        run_archetype_epoch(don_cx, neighbors, K_csr, tt, et, donor_coords)
        run_archetype_epoch(rcv_cx, neighbors, K_csr, tt, et, donor_coords)
        update_target_node(don_cx); update_target_node(rcv_cx)
        for t in range(3):
            leak = don_cx.S_sparse[t].multiply(COEXIST_COUPLING)
            rcv_cx.S_sparse[t] = rcv_cx.S_sparse[t] + leak
            rcv_cx.S_sparse[t].data = np.clip(
                rcv_cx.S_sparse[t].data, 0.0, donor_coords[1] / 2.5)
            rcv_cx.S_sparse[t].eliminate_zeros()
    _, pe_don_cx, _, reg_don_cx, _ = compute_agency(don_cx, neighbors, K_csr, tt, et)
    _, pe_rcv_cx, _, reg_rcv_cx, _ = compute_agency(rcv_cx, neighbors, K_csr, tt, et)
    relational = (pe_rcv_cx > pe_rcv0) and (pe_don_cx >= pe_don - 0.5)
    both_up    = relational and (pe_rcv_cx >= 4)
    ghl_L, _  = measure_ghl(rcv_cx, neighbors, K_csr, tt, et, donor_coords)
    print(f"        Donor:  Region={reg_don_cx}, PE={pe_don_cx} (was {pe_don})")
    print(f"        Recip:  Region={reg_rcv_cx}, PE={pe_rcv_cx} (was {pe_rcv0})")
    print(f"        {'🌐 RELATIONAL SIGNAL' if both_up else '→ No relational signal'}")
    results['L'] = {'pe_donor': pe_don_cx, 'pe_recip': pe_rcv_cx,
                    'relational': bool(both_up), 'ghl': ghl_L,
                    'desc': 'Coexistence', 'kind': 'relational'}
    ghl_data['L'] = ghl_L

    # ── Summary ───────────────────────────────────────────────────────────────
    print(f"\n{'='*76}")
    print("PHASE 11.5 v4 SUMMARY")
    print(f"{'='*76}")
    print(f"\n  Donor:  {donor_archetype} ep={donor_ep}  CA={donor_ca:.2f}  PE={pe_don}  Region={reg_don}")
    print(f"  Recipient: {donor_archetype} ep=10  CA={recip_ca:.2f}  PE={pe_rcv0}  Region={reg_rcv0}")
    print(f"  Full Transfer ceiling: PE={pe_full}  Range={denom:.2f}")

    print(f"\n[Transfer — ranked by GHL then ΔPE]")
    print(f"{'Exp':<4} {'Desc':<42} {'Rgn':<10} {'PE':<4} {'CA':>6} {'Ctb':>6} {'GHL'}")
    print("-" * 76)
    for k in ['E','A','B','C','D','F','G','H']:
        r = results[k]
        print(f"  {k:<3} {r['desc'][:42]:<42} {r['region']:<10} {r['pe']:<4}"
              f" {r['ca']:>6.2f} {r['contrib']:>6.2f} {r['ghl']}ep")
    print(f"  REF {'Full Transfer':<42} {reg_full:<10} {pe_full:<4}          1.00")

    print(f"\n[Destruction — what is NECESSARY?]")
    for k in ['I','J','K']:
        r = results[k]
        nec = "✅ YES" if r['necessity_score'] < -0.5 else "❌ No"
        print(f"  [{k}] {r['desc'][:50]:<50}  ΔPE={r['necessity_score']:+.1f}  {nec}")

    contrib_scores = {k: results[k]['contrib'] for k in ['A','B','C','D']}
    nec_scores     = {k: results[k]['necessity_score'] for k in ['I','J','K']}

    # Priority rankings
    names = {'A':'Topology', 'B':'Constitution', 'C':'Signals', 'D':'History'}
    by_ghl  = sorted(['A','B','C','D'], key=lambda k: -results[k]['ghl'])
    by_pe   = sorted(['A','B','C','D'], key=lambda k: -results[k]['pe'])
    by_ctb  = sorted(['A','B','C','D'], key=lambda k: -results[k]['contrib'])

    print(f"\n[Priority Rankings]")
    ghl_strs = [f'{names[k]}={results[k]["ghl"]}ep' for k in by_ghl]
    print(f"  1st (GHL):    {ghl_strs}")
    pe_strs = [f'{names[k]}=PE{results[k]["pe"]}' for k in by_pe]
    print(f"  2nd (ΔPE):    {pe_strs}")
    ctb_strs = [f'{names[k]}={results[k]["contrib"]:.2f}' for k in by_ctb]
    print(f"  3rd (Contrib):{ctb_strs}")

    roles = assign_roles(contrib_scores, nec_scores)
    gen_type, arch = global_type(contrib_scores, nec_scores, bool(both_up))
    verdict = conservation_verdict(pe_rcv0, max(results[k]['pe'] for k in ['A','B','C','D']),
                                   pe_don, results.get('_post_pe', pe_don), pe_null)

    print(f"\n[Causal Roles]")
    for comp, role in roles.items():
        print(f"  {comp:<16} → {role}")
    if both_up:
        print(f"  {'Interaction':<16} → Emergent-Relational")

    print(f"\n[Conservation]: {verdict}")
    print(f"[Type]: {gen_type}")
    print(f"[Architecture]: {arch}")

    # Catalytic
    if pe_null >= 4:
        print(f"\n  ⭐ CATALYTIC: Null recipient PE={pe_null} ≥ 4")
    if both_up:
        print(f"\n  🌐 RELATIONAL: Recipient improved ({pe_rcv0}→{pe_rcv_cx}) with coupling only")

    # Save
    os.makedirs('data/archive', exist_ok=True)
    out = {
        'version': '11.5-v4',
        'metadata': {
            'donor': {'archetype': donor_archetype, 'epoch': donor_ep,
                      'pe': pe_don, 'ca': donor_ca, 'region': reg_don},
            'recipient': {'archetype': donor_archetype, 'epoch': 10,
                          'pe': pe_rcv0, 'ca': recip_ca, 'region': reg_rcv0},
            'full_transfer': {'pe': pe_full, 'region': reg_full},
            'pe_ceiling': pe_ceiling, 'pe_null': pe_null, 'denom': denom,
        },
        'experiments': {k: v for k, v in results.items()},
        'contrib_scores': contrib_scores,
        'necessity_scores': nec_scores,
        'causal_roles': roles,
        'conservation_verdict': verdict,
        'generativity_type': gen_type,
        'architecture_implication': arch,
        'relational_signal': bool(both_up),
    }
    with open('data/archive/rea_generativity_causality.json', 'w') as f:
        json.dump(out, f, indent=2)
    print(f"\n✅ PHASE 11.5 v4 COMPLETE → data/archive/rea_generativity_causality.json")
    return out


# ── experiment constructors ────────────────────────────────────────────────────
def _t(rcv, don):
    s = rcv.copy(); s.trust_matrix = np.copy(don.trust_matrix); return s

def _c(rcv, dc, neighbors, K_csr, tt, et):
    s = rcv.copy()
    for _ in range(CONSTITUTION_EPOCHS):
        run_archetype_epoch(s, neighbors, K_csr, tt, et, dc)
    return s

def _s(rcv, don):
    s = rcv.copy(); s.S_sparse = [x.copy() for x in don.S_sparse]
    s.target_node = don.target_node; return s

def _h(rcv, don):
    s = rcv.copy(); inject_history_proxy(s, don, alpha=1.0); return s

def _mx(rcv, don, dc, neighbors, K_csr, tt, et, ta, ce, ha, sa):
    s = rcv.copy()
    if ta > 0: s.trust_matrix = blend_trust(rcv.trust_matrix, don.trust_matrix, ta)
    if sa > 0: s.S_sparse = blend_signals(rcv.S_sparse, don.S_sparse, sa)
    if ha > 0: inject_history_proxy(s, don, alpha=ha)
    for _ in range(ce):
        run_archetype_epoch(s, neighbors, K_csr, tt, et, dc)
    return s

def _di(don):
    s = don.copy(); destroy_topology(s); return s

def _dj(don, pc, neighbors, K_csr, tt, et):
    s = don.copy()
    for _ in range(CONSTITUTION_EPOCHS):
        run_archetype_epoch(s, neighbors, K_csr, tt, et, pc)
    return s

def _dk(don):
    s = don.copy(); destroy_history(s); return s


if __name__ == "__main__":
    run_causality_v4()
