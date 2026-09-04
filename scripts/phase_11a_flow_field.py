import numpy as np
import json
import os
from collections import defaultdict

ARCHIVE_PATH = 'data/archive/rea_dynamics_archive.json'

ATTRACTOR_ORDER = ['Rigid', 'Brittle', 'Plastic', 'Explosive', 'Zombie']

def compute_oi(rv, e, b, h):
    # OI = 0.4*RV + 0.3*E - 0.5*(-B) + 0.2*H
    # b is boundary_distance; positive = away from dead zone
    return (0.4 * rv) + (0.3 * e) + (0.5 * max(0, b)) + (0.2 * h)

def load_archive_as_asvs():
    """Load the dynamics archive and compute ASV for every record."""
    with open(ARCHIVE_PATH, 'r') as f:
        archive = json.load(f)

    # Group by shock trajectory for velocity calculation
    by_shock = defaultdict(list)
    for r in archive:
        by_shock[r['shock']].append(r)

    all_asvs = []
    for shock, records in by_shock.items():
        records.sort(key=lambda x: x['epoch'])
        oi_history = []

        for i, rec in enumerate(records):
            rv_proxy = max(0.0, rec['boundary_distance']) * rec['elasticity'] + 0.2
            e = rec['elasticity']
            b = rec['boundary_distance']
            h = min(1.0, i / max(1, len(records)))  # Hysteresis proxy: how far along recovery path

            oi = compute_oi(rv_proxy, e, b, h)
            oi_history.append(oi)

            # Multi-scale dOI/dt
            sv = oi - oi_history[max(0, i-5)]
            mv = oi - oi_history[max(0, i-15)]
            lv = oi - oi_history[0]
            doi_dt = 0.5 * sv + 0.3 * mv + 0.2 * lv

            # Curvature C: rate of change of elasticity (from Phase 9E proxy)
            prev_e = records[max(0, i-1)]['elasticity']
            c = e - prev_e

            asv = {
                'shock': shock,
                'epoch': rec['epoch'],
                'attractor': rec['attractor'],
                'constitution': rec['constitution'],
                'oi': oi,
                'doi_dt': doi_dt,
                'rv': rv_proxy,
                'e': e,
                'b': b,
                'h': h,
                'c': c,
                'recoverability': rec['recoverability'],
            }
            all_asvs.append(asv)

    return all_asvs


def build_basin_atlas(asvs, n_oi_bins=4, n_rv_bins=4, n_e_bins=3):
    """
    Layer 1: Empirical Basin Atlas.
    Coarsely bins ASV space (OI x RV x E) and labels each bin
    by its dominant dynamics and basin type.
    """
    print("\n" + "=" * 60)
    print("📊 LAYER 1: EMPIRICAL BASIN ATLAS")
    print("=" * 60)

    oi_vals = [a['oi'] for a in asvs]
    rv_vals = [a['rv'] for a in asvs]
    e_vals  = [a['e'] for a in asvs]

    oi_edges = np.linspace(min(oi_vals), max(oi_vals) + 1e-9, n_oi_bins + 1)
    rv_edges = np.linspace(min(rv_vals), max(rv_vals) + 1e-9, n_rv_bins + 1)
    e_edges  = np.linspace(min(e_vals),  max(e_vals)  + 1e-9, n_e_bins  + 1)

    bins = defaultdict(list)
    for a in asvs:
        oi_bin = int(np.digitize(a['oi'], oi_edges) - 1)
        rv_bin = int(np.digitize(a['rv'], rv_edges) - 1)
        e_bin  = int(np.digitize(a['e'],  e_edges)  - 1)
        key = (
            min(oi_bin, n_oi_bins - 1),
            min(rv_bin, n_rv_bins - 1),
            min(e_bin,  n_e_bins  - 1),
        )
        bins[key].append(a)

    atlas = {}
    limit_cycle_candidates = []

    print(f"\n{'BIN (OI,RV,E)':<18} {'N':>4} {'Avg dOI/dt':>12} {'Avg B':>8} {'Dominant Attractor':<14} {'Basin Type'}")
    print("-" * 80)

    for key, records in sorted(bins.items()):
        avg_doi_dt = np.mean([r['doi_dt'] for r in records])
        avg_b      = np.mean([r['b']      for r in records])
        avg_c      = np.mean([r['c']      for r in records])
        avg_rv     = np.mean([r['rv']     for r in records])

        attractor_counts = defaultdict(int)
        for r in records:
            attractor_counts[r['attractor']] += 1
        dominant_attractor = max(attractor_counts, key=attractor_counts.get)

        # Basin classification
        if avg_rv < 0.1 or avg_b < -0.3:
            basin_type = "SINK"
        elif abs(avg_doi_dt) < 0.005 and avg_rv > 0.2:
            basin_type = "STABLE"
        elif avg_doi_dt > 0.01 and avg_c > 0:
            basin_type = "LAUNCH"
        elif avg_doi_dt > 0.005 and avg_b > 0:
            basin_type = "CORRIDOR"
        elif avg_doi_dt < -0.005 and avg_b < 0.05:
            basin_type = "SINK"
        else:
            basin_type = "TRANSITION"

        atlas[key] = {
            'basin_type': basin_type,
            'dominant_attractor': dominant_attractor,
            'avg_doi_dt': avg_doi_dt,
            'avg_rv': avg_rv,
            'avg_b': avg_b,
            'avg_c': avg_c,
            'n': len(records),
        }

        print(f"{str(key):<18} {len(records):>4} {avg_doi_dt:>12.4f} {avg_b:>8.3f} {dominant_attractor:<14} {basin_type}")

    return atlas


def detect_limit_cycles(asvs):
    """
    Layer 1 Inspection: Do civilizations exhibit Limit Cycles?
    Look for closed attractor sequences in each shock trajectory.
    """
    print("\n" + "=" * 60)
    print("🔄 LIMIT CYCLE DETECTION")
    print("=" * 60)

    by_shock = defaultdict(list)
    for a in asvs:
        by_shock[a['shock']].append(a)

    found_cycles = []
    for shock, records in by_shock.items():
        records.sort(key=lambda x: x['epoch'])
        sequence = [r['attractor'] for r in records]

        # Look for repeating subsequences of length 2-4
        for length in range(2, 5):
            for start in range(len(sequence) - length * 2):
                subseq = sequence[start:start + length]
                next_subseq = sequence[start + length:start + length * 2]
                if subseq == next_subseq and len(set(subseq)) > 1:
                    cycle_str = ' → '.join(subseq)
                    found_cycles.append({'shock': shock, 'cycle': cycle_str, 'start_epoch': records[start]['epoch']})
                    print(f"  ✅ [{shock}] Limit Cycle Detected at epoch {records[start]['epoch']}: {cycle_str}")
                    break

    if not found_cycles:
        print("  ⚠️  No repeating multi-basin sequences found in the archive.")
        print("     Civilizations appear to converge to single attractors rather than orbiting.")
        print("     Hypothesis: Limit Cycles may require longer trajectories or higher-energy shocks.")
    else:
        print(f"\n  🌀 RESULT: {len(found_cycles)} Limit Cycle signatures detected.")
        print("  The Trajectory Hypothesis is supported: healthy civilizations may orbit rather than settle.")

    return found_cycles


def train_flow_approximator(asvs):
    """
    Layer 2: Continuous Flow Approximator.
    Trains a simple linear regressor: ASV(t) + Constitution -> dASV/dt.
    Uses the archive trajectories as training data.
    """
    print("\n" + "=" * 60)
    print("🧠 LAYER 2: CONTINUOUS FLOW APPROXIMATOR")
    print("=" * 60)

    by_shock = defaultdict(list)
    for a in asvs:
        by_shock[a['shock']].append(a)

    X, Y = [], []
    const_map = {'preserve': 0, 'repair': 1, 'explore': 2, 'triage': 3}

    for shock, records in by_shock.items():
        records.sort(key=lambda x: x['epoch'])
        for i in range(len(records) - 1):
            r0, r1 = records[i], records[i + 1]
            c_enc = const_map.get(r0['constitution'], 0)
            x = [r0['oi'], r0['doi_dt'], r0['rv'], r0['e'], r0['b'], r0['h'], r0['c'], c_enc]
            # Target: change in OI, RV, E
            y = [r1['oi'] - r0['oi'], r1['rv'] - r0['rv'], r1['e'] - r0['e']]
            X.append(x); Y.append(y)

    if len(X) < 4:
        print("  ⚠️  Insufficient training data. Archive may need more trajectories.")
        return None

    X = np.array(X, dtype=np.float32)
    Y = np.array(Y, dtype=np.float32)

    # Simple least-squares solution: W = (X^T X)^-1 X^T Y
    W, _, _, _ = np.linalg.lstsq(X, Y, rcond=None)

    # Validation on last 20% of data
    split = int(len(X) * 0.8)
    X_val, Y_val = X[split:], Y[split:]
    Y_pred = X_val @ W
    rmse = np.sqrt(np.mean((Y_pred - Y_val) ** 2))

    print(f"  Training samples: {split}")
    print(f"  Validation RMSE:  {rmse:.4f}")
    print(f"  Flow Approximator trained. Input: ASV(t) + Constitution -> d(OI, RV, E)/dt")

    # Interpret the weights
    feature_names = ['OI', 'dOI/dt', 'RV', 'E', 'B', 'H', 'C', 'Constitution']
    target_names  = ['ΔOI', 'ΔRV', 'ΔE']
    print("\n  Feature Weights (most impactful on ΔOI):")
    oi_weights = sorted(zip(feature_names, W[:, 0]), key=lambda x: abs(x[1]), reverse=True)
    for name, w in oi_weights[:4]:
        print(f"    {name:<14} → {w:+.4f}")

    return W


def run_phase_11a():
    print("🌌 [Phase 11A] Hybrid Flow Field Architecture")
    print("=" * 60)

    print("\n[Loading Dynamics Archive and Computing ASV...]")
    asvs = load_archive_as_asvs()
    print(f"  Loaded {len(asvs)} ASV records across {len(set(a['shock'] for a in asvs))} shock types.")

    atlas = build_basin_atlas(asvs)

    print("\n[Basin Summary]")
    type_counts = defaultdict(int)
    for data in atlas.values():
        type_counts[data['basin_type']] += 1
    for btype, count in sorted(type_counts.items()):
        print(f"  {btype:<12} : {count} bins")

    cycles = detect_limit_cycles(asvs)

    W = train_flow_approximator(asvs)

    print("\n" + "=" * 60)
    print("✅ PHASE 11A COMPLETE")
    print(f"   Basin Atlas: {len(atlas)} bins classified")
    print(f"   Limit Cycles: {len(cycles)} detected")
    print(f"   Flow Approximator: {'Trained' if W is not None else 'Insufficient data'}")
    print("=" * 60)

    return atlas, cycles, W


if __name__ == "__main__":
    run_phase_11a()
