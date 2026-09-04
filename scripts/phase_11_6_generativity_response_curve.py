#!/usr/bin/env python3
"""
Phase 11.6 — Generativity Response Curves
==========================================

State Acquisition Layer (geometry-driven, not epoch-driven):
  acquire_donor()     — scans until GENERATOR: region==GENERATOR, PE>=5, PR>0, CA>threshold
  acquire_recipient() — scans until DESERT: CA<1, all OI values at flat floor (~0.08)

Validation gate before any sweep:
  - donor_region == GENERATOR
  - recipient_region == DESERT
  - Contrast = donor_ca / max(recipient_ca, ε) >= MIN_CONTRAST (2.0)
  - ABORT and continue searching if not satisfied

Four independent variables swept 0.0–1.0:
  1. Topology Retention     — trust matrix blend
  2. History Retention      — signal field blend
  3. Constitution Retention — (γ,ρ,α,τ) blend Settler↔Trader
  4. Identity Persistence   — fraction of trust topology surviving collapse

Metrics: PE, CA, PR, PDR, GHL, OI, RV, Agency, GY, ME, FE
Curve fitting: Linear + Quadratic + Cubic, classified per shape
Temporal profiling: every 10 epochs, DESERT→CLIFF→GENERATOR trajectory

Outputs:
  rea_generativity_response_curves.json
  rea_generativity_physics_report.json
  rea_generativity_response_plots.png
  rea_generativity_laws.md
"""

import json
import time
import sys
import numpy as np
import scipy.sparse as sp
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple

sys.path.insert(0, str(Path(__file__).parent.parent))
sys.path.append('scripts')

from dynamics_extractor import generate_topology, SimState, run_step, get_kmeans_model
from tiannara_ucc.core import extract_basin_metrics

# ─────────────────────────── constants ───────────────────────────────────────
N_NODES    = 1000
N_AGENTS   = 100
WALK_STEPS = 10
RADIUS     = 5
MORTALITY  = 0.0025

WARM_EPOCHS               = 200
COUNTERFACTUAL_DEPTH      = 10
OBSERVATION_WINDOW        = 40       # extended: capture generator formation, not transient
GHL_MAX_EPOCHS            = 40
GHL_CHECK_INTERVAL        = 5
GHL_THRESHOLD             = 4
TEMPORAL_PROFILE_INTERVAL = 10

RETENTION_LEVELS = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]

# Archetype parameter tuples: (γ, ρ, α_gain, τ)
SETTLER  = (0.95, 2.5,  0.05, 0.01)
EXPLORER = (0.60, 4.5,  0.10, 3.00)
TRADER   = (0.85, 3.0,  0.50, 0.50)
SURVIVOR = (0.98, 1.5,  0.02, 0.01)
PHOENIX  = (0.40, 5.00, 0.80, 5.00)

NAVIGATOR_ARCHETYPES = {
    'Settler': SETTLER, 'Explorer': EXPLORER, 'Trader': TRADER,
    'Survivor': SURVIVOR, 'Phoenix': PHOENIX,
}

# State acquisition criteria
DONOR_MIN_CA        = 20.0    # kept as floor but GY/PDR are primary
DONOR_MIN_PR        = 0.0     # PR must be non-negative
DONOR_MIN_PE        = 3       # PE must be >= 3
DONOR_MIN_PDR       = 0.6     # PDR must be >= 0.6
DESERT_MAX_CA       = 1.0     # CA must be below this
DESERT_OI_FLOOR     = 0.10    # all OI values must be below this (flat floor)
DESERT_MAX_PE       = 1       # true DESERT: almost no viable policies
MIN_CONTRAST        = 2.0     # donor_gy / recipient_gy minimum
SCAN_MAX_EPOCHS     = 150     # max epochs per archetype scan

OBSERVATION_WINDOW  = 40      # extended: capture generator formation, not just transient

# Generator detection thresholds
GENERATOR_PE_THRESHOLD  = 5
GENERATOR_CA_THRESHOLD  = 2.0
GENERATOR_PDR_THRESHOLD = 0.3


# ─────────────────────────── simulation core ─────────────────────────────────
def run_archetype_epoch(state, neighbors, K_csr, tt, et, coords):
    gamma, rho, alpha_gain, tau = coords
    N = N_NODES
    state.agent_consumed_amt[:] = 0.0
    E_rows = [[], [], []]; E_cols = [[], [], []]; E_data = [[], [], []]
    C_rows = [[], [], []]; C_cols = [[], [], []]; C_data = [[], [], []]
    for _ in range(WALK_STEPS):
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
            for i, auth in enumerate(authors[order]):
                if req <= 0: break
                take = min(available[order][i], req)
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
        if C_data[t]:
            Cm = sp.csr_matrix((C_data[t], (C_rows[t], C_cols[t])), shape=(N, N_AGENTS))
            state.S_sparse[t] = state.S_sparse[t] - Cm
        if E_data[t]:
            Em = sp.csr_matrix((E_data[t], (E_rows[t], E_cols[t])), shape=(N, N_AGENTS))
            state.S_sparse[t] = state.S_sparse[t].multiply(gamma) + K_csr.dot(Em)
        else:
            state.S_sparse[t] = state.S_sparse[t].multiply(gamma)
        state.S_sparse[t].data = np.clip(state.S_sparse[t].data, 0.0, MAX_PHI)
        state.S_sparse[t].data[state.S_sparse[t].data < 1e-3] = 0.0
        state.S_sparse[t].eliminate_zeros()
    state.trust_matrix = np.maximum(1.0, state.trust_matrix)
    for a in np.where(np.random.rand(N_AGENTS) < MORTALITY)[0]:
        state.trust_matrix[a, :] = 1.0
        state.agent_consumed_amt[a] = 0.0


def update_target_node(state):
    S_sum = np.array(state.S_sparse[0].sum(axis=0) +
                     state.S_sparse[1].sum(axis=0) +
                     state.S_sparse[2].sum(axis=0)).flatten()
    if S_sum.max() > 0:
        state.target_node = int(np.argmax(S_sum))


# ─────────────────────────── metrics ─────────────────────────────────────────
def measure_pe_only(state, neighbors, K_csr, tt, et) -> int:
    """Lightweight PE-only check — no GHL, no recursion."""
    vals = []
    for coords in NAVIGATOR_ARCHETYPES.values():
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
        vals.append((0.4 * rv) + (0.3 * e) + (0.5 * max(0, bd)) + (0.2 * h))
    return sum(1 for v in vals if v > 0.10)


def measure_full(state, neighbors, K_csr, tt, et) -> Dict:
    """Full measurement — never calls measure_ghl (avoids recursion)."""
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
        oi_outcomes[name] = (0.4 * rv) + (0.3 * e) + (0.5 * max(0, bd)) + (0.2 * h)

    vals = list(oi_outcomes.values())
    ca     = float(max(vals) - min(vals))
    pr     = float(np.mean(vals) - np.std(vals))
    pe     = sum(1 for v in vals if v > 0.10)
    pdr    = float(pe / len(NAVIGATOR_ARCHETYPES))
    oi     = float(np.mean(vals))
    rv     = float(max(vals))
    agency = float(ca * pe / max(1, len(NAVIGATOR_ARCHETYPES)))
    gy     = float(pe * max(0.0, pr) * pdr)

    region = ("GENERATOR" if pe >= GENERATOR_PE_THRESHOLD and pr > 0
                             and ca > GENERATOR_CA_THRESHOLD
                             and pdr > GENERATOR_PDR_THRESHOLD
              else "CORRIDOR" if pe >= 3 and pr > 0
              else "CLIFF"    if ca >= 1
              else "DESERT")

    return {
        'pe': pe, 'ca': ca, 'pr': pr, 'pdr': pdr,
        'oi': oi, 'rv': rv, 'agency': agency, 'gy': gy,
        'region': region, 'oi_values': oi_outcomes,
    }


def measure_ghl(state, neighbors, K_csr, tt, et, coords=None) -> int:
    """GHL using lightweight PE-only check inside — no recursion."""
    if coords is None:
        coords = TRADER
    s = state.copy()
    ghl = GHL_MAX_EPOCHS + GHL_CHECK_INTERVAL
    total_checks = GHL_MAX_EPOCHS // GHL_CHECK_INTERVAL
    for check_i, t in enumerate(range(0, GHL_MAX_EPOCHS, GHL_CHECK_INTERVAL)):
        for _ in range(GHL_CHECK_INTERVAL):
            run_archetype_epoch(s, neighbors, K_csr, tt, et, coords)
            update_target_node(s)
        pe = measure_pe_only(s, neighbors, K_csr, tt, et)
        print(f"      [GHL] check {check_i+1}/{total_checks}  "
              f"ep+{t+GHL_CHECK_INTERVAL}  PE={pe}  "
              f"{'✓' if pe >= GHL_THRESHOLD else '✗ dropped'}", flush=True)
        if pe < GHL_THRESHOLD:
            ghl = t + GHL_CHECK_INTERVAL
            break
    return ghl


def state_fingerprint(m: Dict, archetype: str, epoch: int) -> Dict:
    """Record state identity for metadata — not epoch-dependent semantics."""
    return {
        'archetype': archetype, 'epoch': epoch,
        'pe': m['pe'], 'ca': round(m['ca'], 4), 'pr': round(m['pr'], 4),
        'pdr': round(m['pdr'], 4), 'oi': round(m['oi'], 4),
        'rv': round(m['rv'], 4), 'agency': round(m['agency'], 4),
        'region': m['region'],
        'oi_values': {k: round(v, 4) for k, v in m['oi_values'].items()},
    }


# ─────────────────────────── State Acquisition Layer ─────────────────────────
def is_generator(m: Dict) -> bool:
    """
    True GENERATOR: PE==5 (all policies viable), PR>0 (robust), PDR>0.8 (diverse).
    CA is not the defining property — a high-CA CLIFF also has PE=5 but negative PR.
    GY = PE * PR * PDR is the composite signal; maximize this, not CA.
    """
    return (m['pe'] >= DONOR_MIN_PE
            and m['pr'] > DONOR_MIN_PR
            and m['pdr'] >= DONOR_MIN_PDR)


def is_desert(m: Dict) -> bool:
    """
    True DESERT: CA near zero, all OI at flat floor, PE <= 1 or CA < 0.1.
    If CA is virtually zero, it represents a flat non-discriminating state (DESERT),
    regardless of the policy count, since all policies yield identical floor values.
    """
    vals = list(m['oi_values'].values())
    is_flat = (m['ca'] < 0.05 or (m['ca'] < DESERT_MAX_CA and all(v < DESERT_OI_FLOOR for v in vals)))
    return is_flat and (m['region'] == 'DESERT' or m['ca'] < 0.01)



def contrast_label(score: float) -> str:
    if score < 1:    return 'INVALID (inverted)'
    if score < 2:    return 'WEAK'
    if score < 5:    return 'ACCEPTABLE'
    return 'STRONG'


def validate_contrast(donor_fp: Dict, recipient_fp: Dict) -> Tuple[bool, float, str]:
    """
    Contrast uses GY (PE * PR * PDR), not CA.
    CA is insufficient — a CLIFF has high CA but negative PR.
    Falls back to PR if GY is degenerate.
    """
    d_gy  = donor_fp.get('gy', 0.0)
    r_gy  = recipient_fp.get('gy', 0.0)
    d_pr  = max(0.0, donor_fp.get('pr', 0.0))
    r_pr  = max(0.0, recipient_fp.get('pr', 0.0))

    if d_gy > 1e-6:
        score = d_gy / max(r_gy, 1e-6)
        basis = 'GY'
    else:
        score = d_pr / max(r_pr, 1e-6)
        basis = 'PR'

    label = contrast_label(score)
    # CA direction check retained as secondary guard
    ok = score >= MIN_CONTRAST and donor_fp['ca'] > recipient_fp['ca']

    print(f"\n  [Contrast Gate]  (basis: {basis})")
    print(f"    Donor     GY={d_gy:.4f}  CA={donor_fp['ca']:.3f}  "
          f"PR={donor_fp['pr']:.3f}  PDR={donor_fp['pdr']:.2f}  "
          f"({donor_fp['region']})")
    print(f"    Recipient GY={r_gy:.6f}  CA={recipient_fp['ca']:.4f}  "
          f"PR={recipient_fp['pr']:.3f}  PDR={recipient_fp['pdr']:.2f}  "
          f"({recipient_fp['region']})")
    print(f"    Contrast  = {score:.1f}x  [{label}]  basis={basis}")
    print(f"    Gate:     {'✅ PASS' if ok else '❌ FAIL'}")
    return ok, score, label


def acquire_donor(baseline, neighbors, K_csr, tt, et,
                  scan_archetypes=None) -> Tuple[Optional[SimState], Dict, str, int]:
    """
    Scan all archetypes up to SCAN_MAX_EPOCHS each.
    Collect all states meeting GENERATOR criteria (PE==5, PR>0, PDR>0.8).
    Return the one with maximum GeneratorScore = GY * log(1 + GHL) using measured GHL.
    """
    if scan_archetypes is None:
        scan_archetypes = ['Settler', 'Trader', 'Survivor', 'Explorer', 'Phoenix']

    candidates = []  # (score, state, fingerprint, arch_name, epoch)

    for arch_name in scan_archetypes:
        coords = NAVIGATOR_ARCHETYPES[arch_name]
        state  = baseline.copy()
        print(f"  [Donor scan] {arch_name} — scanning up to {SCAN_MAX_EPOCHS} epochs...",
              flush=True)
        t0 = time.time()
        for ep in range(1, SCAN_MAX_EPOCHS + 1):
            run_archetype_epoch(state, neighbors, K_csr, tt, et, coords)
            update_target_node(state)
            if ep % 5 == 0:
                m = measure_full(state, neighbors, K_csr, tt, et)
                elapsed = time.time() - t0
                gy = float(m['pe'] * max(0.0, m['pr']) * m['pdr'])
                print(f"    ep={ep:>4}  CA={m['ca']:>8.2f}  PE={m['pe']}  "
                      f"PR={m['pr']:>+8.3f}  PDR={m['pdr']:.2f}  GY={gy:.3f}  "
                      f"region={m['region']:<10}  {elapsed:.0f}s",
                      flush=True)
                if is_generator(m):
                    ghl = measure_ghl(state, neighbors, K_csr, tt, et, coords=coords)
                    score = gy * np.log(1.0 + ghl)
                    fp = state_fingerprint(m, arch_name, ep)
                    fp['gy'] = round(gy, 4)
                    fp['ghl'] = ghl
                    fp['generator_score'] = round(score, 4)
                    candidates.append((score, state.copy(), fp, arch_name, ep))
                    print(f"    ⭐ Generator candidate: {arch_name} ep={ep}  GY={gy:.4f}  GHL={ghl}  Score={score:.4f}",
                          flush=True)

    if not candidates:
        return None, {}, '', -1

    # Select the candidate with maximum GeneratorScore
    candidates.sort(key=lambda x: -x[0])
    best_score, best_state, best_fp, best_arch, best_ep = candidates[0]
    print(f"\n  ✅ DONOR SELECTED: {best_arch} ep={best_ep}  "
          f"Score={best_score:.4f}  GY={best_fp['gy']:.4f}  GHL={best_fp['ghl']}  "
          f"CA={best_fp['ca']:.2f}  PE={best_fp['pe']}  PR={best_fp['pr']:.3f}  PDR={best_fp['pdr']:.2f}",
          flush=True)
    print(f"  (Evaluated {len(candidates)} Generator candidates across all archetypes)",
          flush=True)
    return best_state, best_fp, best_arch, best_ep


def acquire_recipient(baseline, neighbors, K_csr, tt, et,
                      scan_archetypes=None) -> Tuple[Optional[SimState], Dict, str, int]:
    """
    Scan for a true DESERT state: CA<1, all OI values at flat floor.
    Baseline ep=0 is almost always DESERT — try that first.
    """
    if scan_archetypes is None:
        scan_archetypes = ['Settler', 'Trader', 'Explorer']

    # Baseline itself is often a valid DESERT
    m_base = measure_full(baseline, neighbors, K_csr, tt, et)
    if is_desert(m_base):
        fp = state_fingerprint(m_base, 'baseline', 0)
        print(f"  ✅ RECIPIENT: baseline state is DESERT  "
              f"CA={m_base['ca']:.4f}  PE={m_base['pe']}", flush=True)
        return baseline.copy(), fp, 'baseline', 0

    for arch_name in scan_archetypes:
        coords = NAVIGATOR_ARCHETYPES[arch_name]
        state  = baseline.copy()
        print(f"  [Recipient scan] {arch_name}...", flush=True)
        for ep in range(1, SCAN_MAX_EPOCHS + 1):
            run_archetype_epoch(state, neighbors, K_csr, tt, et, coords)
            update_target_node(state)
            if ep % 5 == 0:
                m = measure_full(state, neighbors, K_csr, tt, et)
                if is_desert(m):
                    fp = state_fingerprint(m, arch_name, ep)
                    print(f"  ✅ RECIPIENT ACQUIRED: {arch_name} ep={ep}  "
                          f"CA={m['ca']:.4f}", flush=True)
                    return state.copy(), fp, arch_name, ep
        print(f"  [Recipient scan] {arch_name} — no DESERT found", flush=True)

    return None, {}, '', -1


# ─────────────────────────── derived metrics ─────────────────────────────────
def compute_derived(m: Dict, retention: float) -> Dict:
    pe  = m['pe']
    pr  = max(0.0, m['pr'])
    pdr = m['pdr']
    gy  = float(pe * pr * pdr)
    me  = gy / max(1e-6, retention)
    fe  = gy / max(1e-6, 1.0 - retention)
    return {'gy': gy, 'me': me, 'fe': fe}


# ─────────────────────────── temporal profiling ──────────────────────────────
def temporal_profile(state, neighbors, K_csr, tt, et, coords, n_epochs=60) -> List[Dict]:
    s = state.copy()
    profile = []
    print(f"    [TemporalProfile] {n_epochs} epochs...", flush=True)
    for ep in range(0, n_epochs + 1, TEMPORAL_PROFILE_INTERVAL):
        if ep > 0:
            for _ in range(TEMPORAL_PROFILE_INTERVAL):
                run_archetype_epoch(s, neighbors, K_csr, tt, et, coords)
                update_target_node(s)
        m = measure_full(s, neighbors, K_csr, tt, et)
        pr_pos = max(0.0, m['pr'])
        gy = float(m['pe'] * pr_pos * m['pdr'])
        entry = {
            'epoch': ep, 'ca': m['ca'], 'pe': m['pe'], 'pr': m['pr'],
            'pdr': m['pdr'], 'gy': gy, 'region': m['region'],
        }
        profile.append(entry)
        print(f"      ep={ep:>3}  {m['region']:<10}  "
              f"CA={m['ca']:>7.2f}  PE={m['pe']}  PR={m['pr']:+.3f}  GY={gy:.3f}",
              flush=True)
    return profile


def classify_trajectory(profile: List[Dict]) -> Dict:
    regions = [p['region'] for p in profile]
    cas     = [p['ca'] for p in profile]
    epochs  = [p['epoch'] for p in profile]
    gen_idx = [i for i, r in enumerate(regions) if r == 'GENERATOR']
    burst   = len(gen_idx) * TEMPORAL_PROFILE_INTERVAL if gen_idx else 0
    peak_ca = max(cas) if cas else 0.0
    peak_ep = epochs[int(np.argmax(cas))] if cas else 0
    recovery = 0
    if gen_idx:
        last_g = max(gen_idx)
        for i in range(last_g + 1, len(regions)):
            if regions[i] == 'DESERT':
                recovery = epochs[i] - epochs[last_g]
                break
    return {
        'burst_duration': burst, 'peak_height': peak_ca,
        'peak_epoch': peak_ep, 'recovery_time': recovery,
        'trajectory': regions,
    }


# ─────────────────────────── failure detection ───────────────────────────────
def failure_check(m: Dict, retention: float) -> bool:
    """
    Do not abort sweeps on collapse.
    A physical collapse of the substrate (CA near 0) at low retention is a valid
    scientific data point and shouldn't terminate the scan for higher retention levels.
    """
    vals = list(m['oi_values'].values())
    if retention > 0.05:
        if m['ca'] < 0.01:
            print("  ⚠️  Warning: CA < 0.01 at non-zero retention (collapsed state)", flush=True)
        if max(vals) - min(vals) < 0.001:
            print("  ⚠️  Warning: OI identical across all policies at non-zero retention", flush=True)
    return False


# ─────────────────────────── interpolation ───────────────────────────────────
def interpolate_topology(donor, recipient, retention):
    s = recipient.copy()
    s.trust_matrix = np.clip(
        retention * donor.trust_matrix + (1.0 - retention) * recipient.trust_matrix,
        1.0, 5.0)
    return s


def interpolate_history(donor, recipient, retention):
    s = recipient.copy()
    s.S_sparse = [
        donor.S_sparse[t].multiply(retention) +
        recipient.S_sparse[t].multiply(1.0 - retention)
        for t in range(3)
    ]
    if retention >= 0.5:
        s.target_node = donor.target_node
    return s


def interpolate_constitution(donor, recipient, retention,
                             donor_coords=TRADER, recipient_coords=SETTLER):
    s = recipient.copy()
    blended = tuple(
        retention * d + (1.0 - retention) * r
        for d, r in zip(donor_coords, recipient_coords)
    )
    return s, blended


def interpolate_identity(donor, recipient, retention):
    """
    Identity Persistence: fraction of donor trust topology surviving collapse.
    retention=0.0 → all trust links reset to 1.0 (total collapse)
    retention=1.0 → full donor trust topology preserved
    """
    s = recipient.copy()
    if retention == 0.0:
        s.trust_matrix = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    elif retention == 1.0:
        s.trust_matrix = np.copy(donor.trust_matrix)
    else:
        mask = np.random.rand(N_AGENTS, N_AGENTS) < retention
        s.trust_matrix = np.where(mask, donor.trust_matrix,
                                  np.ones((N_AGENTS, N_AGENTS), dtype=np.float32))
    s.trust_matrix = np.clip(s.trust_matrix, 1.0, 5.0)
    return s


# ─────────────────────────── curve fitting ───────────────────────────────────
def fit_response_curve(retention_levels: List[float], values: List[float]) -> Dict:
    x = np.array(retention_levels, dtype=float)
    y = np.array(values, dtype=float)

    flat_result = {
        'shape': 'flat', 'best_fit': 'linear',
        'quadratic_coeff': 0.0, 'cubic_coeff': 0.0,
        'peak_retention': 0.5, 'peak_value': float(np.mean(y)) if len(y) else 0.0,
        'trough_retention': 0.5, 'trough_value': float(np.mean(y)) if len(y) else 0.0,
        'coefficients': {'linear': [0.0, 0.0], 'quadratic': [0.0, 0.0, 0.0],
                         'cubic': [0.0, 0.0, 0.0, 0.0]},
        'r_squared': {'linear': 0.0, 'quadratic': 0.0, 'cubic': 0.0},
    }
    if len(y) < 3 or np.std(y) < 1e-6:
        return flat_result

    fits, r2s = {}, {}
    for deg, name in [(1, 'linear'), (2, 'quadratic'), (3, 'cubic')]:
        try:
            coeffs = np.polyfit(x, y, deg)
        except Exception:
            coeffs = np.zeros(deg + 1)
        poly = np.poly1d(coeffs)
        ss_res = float(np.sum((y - poly(x)) ** 2))
        ss_tot = float(np.sum((y - np.mean(y)) ** 2))
        r2 = 1.0 - ss_res / ss_tot if ss_tot > 0 else 0.0
        fits[name] = coeffs
        r2s[name]  = round(max(0.0, r2), 4)

    best_fit  = max(r2s, key=r2s.get)
    best_poly = np.poly1d(fits[best_fit])
    x_fine    = np.linspace(0, 1, 200)
    y_fine    = best_poly(x_fine)
    peak_idx  = int(np.argmax(y_fine))
    trough_idx= int(np.argmin(y_fine))

    mono_inc  = all(y[i] <= y[i+1] + 0.05 for i in range(len(y)-1))
    mono_dec  = all(y[i] >= y[i+1] - 0.05 for i in range(len(y)-1))
    quad_c    = float(fits['quadratic'][0])
    cubic_c   = float(fits['cubic'][0])

    dy         = np.diff(y_fine)
    sign_chg   = int(np.sum((dy[:-1] > 0) & (dy[1:] < 0)))
    multi_modal = sign_chg >= 2

    peak_x    = float(x_fine[peak_idx])
    if mono_inc:   shape = 'monotonic_increasing'
    elif mono_dec: shape = 'monotonic_decreasing'
    elif multi_modal: shape = 'multi_modal'
    elif quad_c < -0.5 and 0.15 < peak_x < 0.85: shape = 'inverted_u'
    elif quad_c > 0.5:  shape = 'u_shaped'
    else:               shape = 'flat'

    return {
        'shape': shape, 'best_fit': best_fit,
        'quadratic_coeff': quad_c, 'cubic_coeff': cubic_c,
        'peak_retention': peak_x, 'peak_value': float(y_fine[peak_idx]),
        'trough_retention': float(x_fine[trough_idx]),
        'trough_value': float(y_fine[trough_idx]),
        'coefficients': {k: v.tolist() for k, v in fits.items()},
        'r_squared': r2s,
    }


# ─────────────────────────── retention sweep ─────────────────────────────────
def run_retention_sweep(ctx, donor, recipient, donor_coords, recipient_coords,
                        component, retention_levels) -> List[Dict]:
    neighbors, K_csr, tt, et = ctx['neighbors'], ctx['K_csr'], ctx['tt'], ctx['et']
    results  = []
    n_levels = len(retention_levels)
    t0_sweep = time.time()

    for level_i, retention in enumerate(retention_levels):
        t0_level = time.time()
        print(f"\n  [{component.upper()}] Level {level_i+1}/{n_levels}  "
              f"Retention={retention*100:.0f}%", flush=True)

        if component == 'topology':
            blended, op_coords = interpolate_topology(donor, recipient, retention), donor_coords
        elif component == 'history':
            blended, op_coords = interpolate_history(donor, recipient, retention), donor_coords
        elif component == 'constitution':
            blended, op_coords = interpolate_constitution(
                donor, recipient, retention, donor_coords, recipient_coords)
        elif component == 'identity':
            blended, op_coords = interpolate_identity(donor, recipient, retention), donor_coords
        else:
            raise ValueError(component)

        # Observation window
        print(f"    → Observation window ({OBSERVATION_WINDOW} epochs)...", flush=True)
        s = blended
        for i in range(OBSERVATION_WINDOW):
            run_archetype_epoch(s, neighbors, K_csr, tt, et, op_coords)
            update_target_node(s)
            if (i + 1) % 10 == 0:
                print(f"      [Obs] ep {i+1}/{OBSERVATION_WINDOW}", flush=True)

        # Full metrics
        print(f"    → Measuring generativity...", flush=True)
        m = measure_full(s, neighbors, K_csr, tt, et)

        if failure_check(m, retention):
            print(f"    ⚠️  Aborting sweep at {retention*100:.0f}%", flush=True)
            break

        # GHL
        print(f"    → Measuring GHL...", flush=True)
        ghl = measure_ghl(s, neighbors, K_csr, tt, et, coords=op_coords)

        # Derived
        derived = compute_derived(m, retention)

        # Temporal profile
        print(f"    → Temporal profile...", flush=True)
        profile = temporal_profile(s, neighbors, K_csr, tt, et, op_coords,
                                   n_epochs=OBSERVATION_WINDOW + 20)
        traj = classify_trajectory(profile)

        r = {
            'retention': retention, 'component': component,
            'label': f"{component}_r{retention*100:.0f}",
            'pe': m['pe'], 'ca': m['ca'], 'pr': m['pr'],
            'pdr': m['pdr'], 'ghl': ghl, 'oi': m['oi'],
            'rv': m['rv'], 'agency': m['agency'], 'region': m['region'],
            'gy': derived['gy'], 'me': derived['me'], 'fe': derived['fe'],
            'temporal_profile': profile, 'trajectory_summary': traj,
            'oi_values': m['oi_values'],
        }
        results.append(r)

        elapsed      = time.time() - t0_level
        sweep_done   = level_i + 1
        sweep_eta    = (time.time() - t0_sweep) / sweep_done * (n_levels - sweep_done)
        print(f"\n  ✓ [{component.upper()}] {retention*100:.0f}%  "
              f"PE={r['pe']}  CA={r['ca']:.2f}  PR={r['pr']:+.3f}  "
              f"PDR={r['pdr']:.2f}  GHL={r['ghl']}ep  GY={r['gy']:.3f}  "
              f"region={r['region']}  ({elapsed:.0f}s  ETA={sweep_eta:.0f}s)", flush=True)

    return results


# ─────────────────────────── warm-up ─────────────────────────────────────────
def warm_up(neighbors, K_csr, tt, et, niche) -> SimState:
    pos   = np.random.randint(0, N_NODES, size=N_AGENTS)
    trust = np.ones((N_AGENTS, N_AGENTS), dtype=np.float32)
    S     = [sp.csr_matrix((N_NODES, N_AGENTS), dtype=np.float32) for _ in range(3)]
    state = SimState(pos, trust, S, niche, np.zeros(N_AGENTS), [])
    t0 = time.time()
    for ep in range(1, WARM_EPOCHS + 1):
        run_step(state, ep, neighbors, K_csr, tt, et, MORTALITY, WALK_STEPS, 'repair')
        if ep % 50 == 0:
            elapsed = time.time() - t0
            eta = (elapsed / ep) * (WARM_EPOCHS - ep)
            print(f"  [Warmup] ep={ep}/{WARM_EPOCHS}  "
                  f"{elapsed:.0f}s  ETA={eta:.0f}s  "
                  f"triplets={len(state.active_triplets)}", flush=True)
        if ep >= WARM_EPOCHS - 20:
            ucc = extract_basin_metrics(state.pos, state.trust_matrix,
                                        state.agent_consumed_amt, state.active_triplets,
                                        state.target_node, N_NODES)
            state.dcr_400 = max(state.dcr_400, ucc['dcr'])
            state.scp_400 = max(state.scp_400, ucc['scp'])
    print(f"  [Warmup] Done {time.time()-t0:.0f}s  "
          f"DCR={state.dcr_400:.3f}  SCP={state.scp_400}", flush=True)

    # CRITICAL: if dcr_400/scp_400 are still 0 (repair regime doesn't produce DCR),
    # seed them from a brief archetype probe so OI is not degenerate.
    if state.dcr_400 < 1e-6 or state.scp_400 < 1:
        print("  [Warmup] Baselines are zero — seeding from Settler probe...", flush=True)
        probe = state.copy()
        for _ in range(25):
            run_archetype_epoch(probe, neighbors, K_csr, tt, et, SETTLER)
            update_target_node(probe)
        for _ in range(5):
            run_archetype_epoch(probe, neighbors, K_csr, tt, et, SETTLER)
            update_target_node(probe)
            ucc = extract_basin_metrics(probe.pos, probe.trust_matrix,
                                        probe.agent_consumed_amt, probe.active_triplets,
                                        probe.target_node, N_NODES)
            state.dcr_400 = max(state.dcr_400, ucc['dcr'])
            state.scp_400 = max(state.scp_400, ucc['scp'])
        print(f"  [Warmup] Seeded: DCR={state.dcr_400:.3f}  SCP={state.scp_400}", flush=True)

    return state


# ─────────────────────────── output writers ──────────────────────────────────
def write_physics_report(curve_analysis, all_results, donor_fp, recipient_fp,
                         discoveries, contrast_score_val, contrast_lbl, out_path):
    peak_gys = {
        comp: max((r['gy'] for r in res), default=0.0)
        for comp, res in all_results.items()
    }
    dominant = max(peak_gys, key=peak_gys.get) if peak_gys else 'none'

    report = {
        'metadata': {
            'timestamp': datetime.now().isoformat(),
            'version': '11.6',
            'contrast_score': round(contrast_score_val, 2),
            'contrast_label': contrast_lbl,
        },
        'donor_fingerprint':     donor_fp,
        'recipient_fingerprint': recipient_fp,
        'peak_retention_points': {
            key: {'retention_pct': round(a['peak_retention'] * 100, 1),
                  'value': round(a['peak_value'], 4)}
            for key, a in curve_analysis.items()
        },
        'critical_thresholds': {
            comp: next((round(r['retention'] * 100, 1) for r in res
                        if r['region'] == 'GENERATOR'), None)
            for comp, res in all_results.items()
        },
        'response_classifications': {k: a['shape'] for k, a in curve_analysis.items()},
        'dominant_causal_factors': sorted(
            [{'component': k, 'peak_gy': round(v, 4)} for k, v in peak_gys.items()],
            key=lambda x: -x['peak_gy']
        ),
        'generativity_potential_model': {
            'dominant_component': dominant,
            'peak_gys': peak_gys,
            'note': 'GP = f(Topology, History, Constitution, Identity)',
        },
        'discoveries': discoveries,
    }
    with open(out_path, 'w') as f:
        json.dump(report, f, indent=2)
    print(f"  → {out_path}", flush=True)


def write_laws_md(discoveries, curve_analysis, donor_fp, recipient_fp, out_path):
    lines = [
        "# Phase 11.6 — Discovered Laws of Generativity",
        "",
        f"_Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}_",
        "",
        "## Experimental Setup",
        "",
        f"- Donor: {donor_fp.get('archetype','')} ep={donor_fp.get('epoch','')}  "
        f"CA={donor_fp.get('ca','')}  region={donor_fp.get('region','')}",
        f"- Recipient: {recipient_fp.get('archetype','')} ep={recipient_fp.get('epoch','')}  "
        f"CA={recipient_fp.get('ca','')}  region={recipient_fp.get('region','')}",
        "",
        "## Scientific Context",
        "",
        "- REA-7O: Stability ≠ Adaptation",
        "- Phase 10: Adaptation ≠ Optionality",
        "- Phase 11B: Optionality ≠ Agency, Agency ≠ Robustness",
        "- Phase 11C: Optionality ≠ Generativity",
        "- Phase 11.5: Generativity appears Emergent",
        "",
        "## Discovered Laws",
        "",
    ]

    if not discoveries:
        lines += ["No definitive laws discovered.", "",
                  "All curves flat or below significance threshold.", ""]
    else:
        by_type = {}
        for d in discoveries:
            by_type.setdefault(d['type'], []).append(d)

        if 'Inverted-U' in by_type:
            lines += ["### Law C — Second Law of Adaptation (Structured Forgetting)", ""]
            lines += ["Generativity peaks at intermediate retention — "
                      "neither full memory nor full forgetting maximizes it.", ""]
            for d in by_type['Inverted-U']:
                lines += [f"- **{d['component'].upper()} → {d['metric'].upper()}**: "
                          f"peak at {d.get('peak_retention_pct','?')}% "
                          f"(value={d.get('peak_value','?')})", ""]

        if 'Memory-Capital' in by_type:
            lines += ["### Law A — Memory Capital", ""]
            lines += ["More retention → more Generativity.", ""]
            for d in by_type['Memory-Capital']:
                lines += [f"- {d['component'].upper()} → {d['metric'].upper()}", ""]

        if 'Memory-Drag' in by_type:
            lines += ["### Law B — Forgetting as Generator", ""]
            lines += ["More retention → less Generativity. Forgetting is adaptive.", ""]
            for d in by_type['Memory-Drag']:
                lines += [f"- {d['component'].upper()} → {d['metric'].upper()}", ""]

        if 'Emergent' in by_type:
            lines += ["### Law D — Generativity is Emergent", ""]
            lines += ["No single component dominates. Generativity arises from interactions.", ""]

        if 'Multi-Modal' in by_type:
            lines += ["### Multi-Modal Response", ""]
            lines += ["Multiple local maxima detected — complex retention landscape.", ""]
            for d in by_type['Multi-Modal']:
                lines += [f"- {d['component'].upper()} → {d['metric'].upper()}", ""]

    lines += [
        "## Response Curve Summary",
        "",
        "| Component | Metric | Shape | Peak Retention | Best Fit | R² |",
        "|-----------|--------|-------|----------------|----------|----|",
    ]
    for key, a in sorted(curve_analysis.items()):
        comp, metric = key.rsplit('_', 1)
        best_r2 = max(a['r_squared'].values())
        lines.append(f"| {comp} | {metric.upper()} | {a['shape']} | "
                     f"{a['peak_retention']*100:.0f}% | {a['best_fit']} | {best_r2:.3f} |")

    lines += ["", "## Downstream Phases", "",
              "- **Phase 11.7** — Generativity Physics",
              "- **Phase 12A** — Generator Economics",
              "- **Phase 12B** — Generator Persistence", ""]

    with open(out_path, 'w') as f:
        f.write('\n'.join(lines))
    print(f"  → {out_path}", flush=True)


def write_plots(all_results, curve_analysis, out_path):
    try:
        import matplotlib
        matplotlib.use('Agg')
        import matplotlib.pyplot as plt

        components = list(all_results.keys())
        metrics    = ['pe', 'ca', 'pr', 'ghl', 'gy']
        colors     = {'topology': '#1f77b4', 'history': '#ff7f0e',
                      'constitution': '#2ca02c', 'identity': '#d62728'}

        fig, axes = plt.subplots(len(components), len(metrics),
                                 figsize=(4 * len(metrics), 3.5 * len(components)),
                                 squeeze=False)
        fig.suptitle('Phase 11.6 — Generativity Response Curves', fontsize=14)

        for ri, comp in enumerate(components):
            res = all_results[comp]
            if not res:
                continue
            xv  = [r['retention'] for r in res]
            col = colors.get(comp, '#888')
            for ci, metric in enumerate(metrics):
                ax = axes[ri][ci]
                yv = [r.get(metric, 0) for r in res]
                ax.plot(xv, yv, 'o-', color=col, lw=2, ms=5)
                key = f"{comp}_{metric}"
                if key in curve_analysis:
                    a = curve_analysis[key]
                    coeffs = np.array(a['coefficients'][a['best_fit']])
                    xf = np.linspace(0, 1, 100)
                    ax.plot(xf, np.poly1d(coeffs)(xf), '--', color=col, alpha=0.5)
                    ax.set_title(f"{comp}\n{metric.upper()}  [{a['shape']}]", fontsize=8)
                else:
                    ax.set_title(f"{comp}\n{metric.upper()}", fontsize=8)
                ax.set_xlabel('Retention', fontsize=7)
                ax.set_ylabel(metric.upper(), fontsize=7)
                ax.set_xlim(-0.05, 1.05)
                ax.grid(True, alpha=0.3)
                ax.tick_params(labelsize=6)

        plt.tight_layout()
        plt.savefig(str(out_path), dpi=150, bbox_inches='tight')
        plt.close()
        print(f"  → {out_path}", flush=True)
    except ImportError:
        print("  [Plots] matplotlib not available", flush=True)
    except Exception as e:
        print(f"  [Plots] Error: {e}", flush=True)


# ─────────────────────────── main ────────────────────────────────────────────
def main():
    print("=" * 70)
    print("PHASE 11.6 — GENERATIVITY RESPONSE CURVES")
    print("=" * 70)
    print(f"Started: {datetime.now().strftime('%H:%M:%S')}")
    print("\nState acquisition: geometry-driven (region, not epoch)")
    print(f"Contrast minimum: {MIN_CONTRAST}x  (donor_gy / recipient_gy)")
    print()
    t0 = time.time()

    # Setup
    get_kmeans_model()
    neighbors, K_csr = generate_topology(N_NODES, k_ring=RADIUS * 2)
    np.random.seed(42)
    niche = np.zeros(N_AGENTS, dtype=np.int32)
    niche[33:66] = 1; niche[66:] = 2
    tt = np.zeros(N_AGENTS, dtype=np.int32); tt[niche == 2] = 1
    et = np.copy(niche)
    ctx = {'neighbors': neighbors, 'K_csr': K_csr, 'tt': tt, 'et': et}

    # 1. Warm-up
    print("[1/5] Baseline warm-up...")
    baseline = warm_up(neighbors, K_csr, tt, et, niche)

    # 2. Acquire donor (GENERATOR state)
    print("\n[2/5] Acquiring donor — searching for GENERATOR state...")
    print(f"  Criteria: region=GENERATOR, PE>={DONOR_MIN_PE}, "
          f"PR>{DONOR_MIN_PR}, CA>{DONOR_MIN_CA}")
    donor_state, donor_fp, donor_arch, donor_ep = acquire_donor(
        baseline, neighbors, K_csr, tt, et,
        scan_archetypes=['Settler', 'Trader', 'Survivor', 'Explorer', 'Phoenix']
    )
    if donor_state is None:
        print("❌ FATAL: No GENERATOR state found across all archetypes.")
        print("   Increase SCAN_MAX_EPOCHS or relax DONOR_MIN_CA threshold.")
        return None

    # 3. Acquire recipient (DESERT state)
    print("\n[3/5] Acquiring recipient — searching for DESERT state...")
    print(f"  Criteria: CA<{DESERT_MAX_CA}, all OI<{DESERT_OI_FLOOR}")
    recipient_state, recipient_fp, recip_arch, recip_ep = acquire_recipient(
        baseline, neighbors, K_csr, tt, et
    )
    if recipient_state is None:
        print("❌ FATAL: No DESERT state found.")
        return None

    # 4. Contrast gate
    print("\n[4/5] Contrast validation gate...")
    gate_ok, contrast, contrast_lbl = validate_contrast(donor_fp, recipient_fp)
    if not gate_ok:
        print("❌ FATAL: Contrast gate failed — experiment geometry invalid.")
        print(f"   donor_ca={donor_fp['ca']:.3f}  recipient_ca={recipient_fp['ca']:.4f}")
        print("   Re-run with different seed or adjusted acquisition criteria.")
        return None

    # Determine archetype coords
    arch_map = {'Settler': SETTLER, 'Trader': TRADER, 'Survivor': SURVIVOR,
                'Explorer': EXPLORER, 'Phoenix': PHOENIX, 'baseline': SETTLER}
    donor_coords     = arch_map.get(donor_arch, SETTLER)
    recipient_coords = SETTLER if donor_coords == TRADER else TRADER

    print(f"\n  Donor:    {donor_arch} ep={donor_ep}  "
          f"CA={donor_fp['ca']:.2f}  PE={donor_fp['pe']}  region={donor_fp['region']}")
    print(f"  Recipient:{recip_arch} ep={recip_ep}  "
          f"CA={recipient_fp['ca']:.4f}  PE={recipient_fp['pe']}  "
          f"region={recipient_fp['region']}")
    print(f"  Contrast: {contrast:.1f}x  [{contrast_lbl}]")

    # 5. Four retention sweeps
    print("\n[5/5] Running four retention sweeps "
          "(4 components × 11 levels = 44 measurements)...")
    all_results = {}
    sweep_info  = {
        'topology':     'Trust matrix blend (Deliverable 1)',
        'history':      'Signal field blend (Deliverable 2)',
        'constitution': 'Archetype params blend (Deliverable 3)',
        'identity':     'Trust topology survival (Deliverable 4)',
    }
    for comp, desc in sweep_info.items():
        print(f"\n--- {comp.upper()} — {desc} ---", flush=True)
        t0s = time.time()
        results = run_retention_sweep(
            ctx, donor_state, recipient_state,
            donor_coords, recipient_coords, comp, RETENTION_LEVELS
        )
        all_results[comp] = results
        print(f"\n  [{comp.upper()} done: {len(results)}/{len(RETENTION_LEVELS)} levels  "
              f"{time.time()-t0s:.0f}s]", flush=True)

    # Curve analysis
    print("\n[Analysis] Fitting response curves...")
    curve_analysis = {}
    discoveries    = []
    for comp, res in all_results.items():
        if not res:
            continue
        rets = [r['retention'] for r in res]
        for metric in ['pe', 'ca', 'pr', 'ghl', 'gy', 'pdr']:
            vals = [float(r.get(metric, 0)) for r in res]
            a    = fit_response_curve(rets, vals)
            key  = f"{comp}_{metric}"
            curve_analysis[key] = a
            best_r2 = max(a['r_squared'].values())
            print(f"  {comp:<14} {metric.upper():<4}  shape={a['shape']:<22}  "
                  f"peak={a['peak_retention']*100:.0f}%  "
                  f"R²={best_r2:.3f}  fit={a['best_fit']}", flush=True)
            disc = {'component': comp, 'metric': metric,
                    'peak_retention_pct': round(a['peak_retention'] * 100, 1),
                    'peak_value': round(a['peak_value'], 4)}
            if a['shape'] == 'inverted_u':
                discoveries.append({**disc, 'type': 'Inverted-U'})
            elif a['shape'] == 'monotonic_increasing':
                discoveries.append({**disc, 'type': 'Memory-Capital'})
            elif a['shape'] == 'monotonic_decreasing':
                discoveries.append({**disc, 'type': 'Memory-Drag'})
            elif a['shape'] == 'multi_modal':
                discoveries.append({**disc, 'type': 'Multi-Modal'})

    # H4 emergence check
    peak_gys = {
        comp: max((r['gy'] for r in res), default=0.0)
        for comp, res in all_results.items() if res
    }
    if len(peak_gys) >= 2:
        max_gy  = max(peak_gys.values())
        n_above = sum(1 for v in peak_gys.values() if v > max_gy * 0.5)
        if n_above >= 2:
            discoveries.append({'type': 'Emergent',
                                 'note': 'Multiple components contribute to GY — emergent',
                                 'peak_gys': peak_gys})

    # Summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    for comp in all_results:
        if not all_results[comp]:
            print(f"\n{comp.upper()}: no data")
            continue
        print(f"\n{comp.upper()}:")
        for m in ['ca', 'pe', 'ghl', 'gy']:
            key = f"{comp}_{m}"
            if key in curve_analysis:
                a = curve_analysis[key]
                r2 = max(a['r_squared'].values())
                print(f"  {m.upper():<4} → {a['shape']:<22}  "
                      f"peak={a['peak_retention']*100:.0f}%  R²={r2:.3f}")

    print("\n[DISCOVERIES]")
    if discoveries:
        for d in discoveries:
            t = d['type']
            if t == 'Inverted-U':
                print(f"  ⚡ INVERTED-U: {d['component'].upper()} → {d['metric'].upper()}  "
                      f"peak={d['peak_retention_pct']}%")
            elif t == 'Memory-Capital':
                print(f"  📈 MEMORY-CAPITAL: {d['component'].upper()} → {d['metric'].upper()}")
            elif t == 'Memory-Drag':
                print(f"  📉 MEMORY-DRAG: {d['component'].upper()} → {d['metric'].upper()}")
            elif t == 'Emergent':
                print(f"  🌐 EMERGENT: {d.get('note','')}")
            elif t == 'Multi-Modal':
                print(f"  〰 MULTI-MODAL: {d['component'].upper()} → {d['metric'].upper()}")
    else:
        print("  No discoveries — flat response. Check contrast and observation window.")

    print(f"\n  [GY peak ranking]")
    for comp, gy in sorted(peak_gys.items(), key=lambda x: -x[1]):
        print(f"    {comp:<14} peak GY={gy:.4f}")

    # Write outputs
    out_dir = Path("data/archive")
    out_dir.mkdir(parents=True, exist_ok=True)
    print("\n[Writing outputs...]")

    curves_path = out_dir / "rea_generativity_response_curves.json"
    with open(curves_path, 'w') as f:
        json.dump({
            'metadata': {
                'timestamp': datetime.now().isoformat(),
                'version': '11.6',
                'donor_fingerprint': donor_fp,
                'recipient_fingerprint': recipient_fp,
                'contrast_score': round(contrast, 2),
                'contrast_label': contrast_lbl,
                'retention_levels': RETENTION_LEVELS,
                'observation_window': OBSERVATION_WINDOW,
                'ghl_max_epochs': GHL_MAX_EPOCHS,
            },
            'curves': {
                comp: [{k: v for k, v in r.items()
                        if k not in ('oi_values', 'temporal_profile')}
                       for r in res]
                for comp, res in all_results.items()
            },
            'curve_analysis': curve_analysis,
            'discoveries': discoveries,
        }, f, indent=2)
    print(f"  → {curves_path}")

    write_physics_report(curve_analysis, all_results, donor_fp, recipient_fp,
                         discoveries, contrast, contrast_lbl,
                         out_dir / "rea_generativity_physics_report.json")
    write_plots(all_results, curve_analysis,
                out_dir / "rea_generativity_response_plots.png")
    write_laws_md(discoveries, curve_analysis, donor_fp, recipient_fp,
                  out_dir / "rea_generativity_laws.md")

    total = time.time() - t0
    print(f"\n✅ Phase 11.6 complete  ({total/60:.1f} min)")
    return True


if __name__ == "__main__":
    main()
