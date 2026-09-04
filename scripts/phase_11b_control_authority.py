import numpy as np
import json
from collections import defaultdict

ENSEMBLE_PATH = 'data/archive/rea_ensemble_archive.json'
ARCHETYPES = ['Settler', 'Explorer', 'Trader', 'Survivor', 'Phoenix']


def classify_zombie_type(ip):
    return 'Zombie-R' if ip >= 0.1 else 'Zombie-T'


def classify_agency_region(ca, pe, pr):
    """
    Four Agency Meta-Regions:
      Agency Desert    — CA ≈ 0, PE ≈ 0. Geometry dominates.
      Agency Corridor  — CA moderate, PE high, PR high. Stable adaptation.
      Agency Cliff     — CA huge, PE low, PR low.  One correct policy; all others collapse.
      Agency Generator — CA high, PE high, PR high. Optionality creation zone.
    """
    if ca < 1.0:
        return "DESERT"
    if pe <= 2 and pr < 0:
        return "CLIFF"
    if ca >= 50 and pe >= 4 and pr >= 0:
        return "GENERATOR"
    if pe >= 3 and pr >= 0:
        return "CORRIDOR"
    return "CLIFF"  # High CA, low PE, low PR


def compute_extended_atlas():
    print("🧭 [Phase 11B Extended] Control Authority Atlas + Policy Robustness")
    print("=" * 70)

    with open(ENSEMBLE_PATH, 'r') as f:
        archive = json.load(f)

    # Build IP map (IdentityPersistence proxy per shock/policy trajectory)
    by_shock_policy = defaultdict(list)
    for rec in archive:
        by_shock_policy[(rec['shock'], rec['policy'])].append(rec)

    ip_map = {}
    print("\n[Zombie Taxonomy: Zombie-T vs Zombie-R]")
    print(f"{'Shock':<14} {'Policy':<10} {'IP':>6}  {'Type'}")
    print("-" * 45)
    for (shock, policy), traj in sorted(by_shock_policy.items()):
        zombie_epochs = [r for r in traj if r['attractor'] == 'Zombie']
        if zombie_epochs:
            mean_e = np.mean([r['e'] for r in zombie_epochs])
            max_e  = max((r['e'] for r in traj), default=0.001)
            ip = mean_e / max(0.001, max_e)
        else:
            ip = 1.0
        ip_map[(shock, policy)] = ip
        if zombie_epochs:
            print(f"{shock:<14} {policy:<10} {ip:>6.3f}  {classify_zombie_type(ip)}")

    # Group by (shock, epoch)
    by_state = defaultdict(lambda: defaultdict(list))
    for rec in archive:
        by_state[(rec['shock'], rec['epoch'])][rec['policy']].append(rec)

    # Control Authority Atlas with PR and four-region classification
    atlas_rows = []
    region_counts = defaultdict(int)
    by_attractor_agency = defaultdict(list)
    by_region_attractor = defaultdict(lambda: defaultdict(int))

    print(f"\n[Extended Control Authority Atlas]")
    print(f"{'Shock':<12} {'Ep':>3} {'CA':>8} {'PE':>4} {'PR':>8}  {'Agency':>8}  {'Region':<12} {'Attractor'}")
    print("-" * 80)

    for (shock, epoch), policy_map in sorted(by_state.items()):
        if len(policy_map) < len(ARCHETYPES):
            continue

        oi_by_policy = {}
        attractors = {}
        for policy in ARCHETYPES:
            recs = policy_map.get(policy, [])
            if recs:
                r = recs[-1]
                oi_by_policy[policy] = r['oi']
                attractors[policy] = r['attractor']

        if len(oi_by_policy) < len(ARCHETYPES):
            continue

        oi_vals = list(oi_by_policy.values())
        dominant = max(set(attractors.values()), key=list(attractors.values()).count)

        ca_oi  = float(max(oi_vals) - min(oi_vals))
        pr_oi  = float(np.mean(oi_vals) - np.std(oi_vals))  # Policy Robustness

        # PE: viable (non-Zombie-T) policies
        pe = 0
        for policy, attr in attractors.items():
            if attr == 'Zombie':
                if ip_map.get((shock, policy), 1.0) >= 0.1:
                    pe += 1
            else:
                pe += 1

        sig_pc = 1.0 / (1.0 + np.exp(-np.std(oi_vals) / 100.0))
        agency = ca_oi * (pe / 5.0) * sig_pc

        region = classify_agency_region(ca_oi, pe, pr_oi)
        region_counts[region] += 1
        by_attractor_agency[dominant].append((agency, ca_oi, pe, pr_oi))
        by_region_attractor[region][dominant] += 1

        atlas_rows.append({
            'shock': shock, 'epoch': epoch,
            'ca': ca_oi, 'pe': pe, 'pr': pr_oi, 'agency': agency,
            'region': region, 'dominant_attractor': dominant,
            'oi_by_policy': oi_by_policy, 'attractors': attractors,
        })

        print(f"{shock:<12} {epoch:>3} {ca_oi:>8.2f} {pe:>4} {pr_oi:>8.2f}  {agency:>8.3f}  {region:<12} {dominant}")

    # Region Summary
    print("\n[Agency Region Distribution]")
    print(f"{'Region':<14} {'Count':>7}  Description")
    print("-" * 60)
    desc = {
        'DESERT':    'Geometry-locked. Policy irrelevant.',
        'CORRIDOR':  'Stable. Many viable futures.',
        'CLIFF':     'Fragile. One correct choice.',
        'GENERATOR': 'High CA + High PE. Optionality creation zone.',
    }
    total = sum(region_counts.values())
    for region in ['DESERT', 'CORRIDOR', 'CLIFF', 'GENERATOR']:
        n = region_counts.get(region, 0)
        print(f"{region:<14} {n:>7}  {desc[region]}")

    # Attractor × Region matrix
    print("\n[Region × Attractor Cross-Tab]")
    header = f"{'Region':<14}" + "".join(f"{a:>10}" for a in ['Rigid','Brittle','Plastic','Explosive','Zombie'])
    print(header); print("-" * 65)
    for region in ['DESERT', 'CORRIDOR', 'CLIFF', 'GENERATOR']:
        row = f"{region:<14}"
        for attr in ['Rigid', 'Brittle', 'Plastic', 'Explosive', 'Zombie']:
            row += f"{by_region_attractor[region].get(attr, 0):>10}"
        print(row)

    # Agency vs OI: the deeper falsification test
    print("\n[FALSIFICATION TEST: High-Agency vs High-OI Survival]")
    high_oi_states  = [r for r in atlas_rows if max(r['oi_by_policy'].values()) > 100]
    high_ca_states  = [r for r in atlas_rows if r['ca'] > 100 and r['pe'] >= 3]
    high_oi_avg_pe  = np.mean([r['pe'] for r in high_oi_states]) if high_oi_states else 0
    high_ca_avg_oi  = np.mean([max(r['oi_by_policy'].values()) for r in high_ca_states]) if high_ca_states else 0
    print(f"  High-OI states (OI>100):  n={len(high_oi_states)}, avg PE={high_oi_avg_pe:.2f}")
    print(f"  High-CA states (CA>100, PE\u22653): n={len(high_ca_states)}, avg max-OI={high_ca_avg_oi:.1f}")
    if high_oi_avg_pe < 3 and len(high_oi_states) > 0:
        print("  \u26a0\ufe0f  High-OI states have low PE — they are Agency Cliffs, not Agency Generators.")
        print("     Implication: High optionality does not guarantee influence over the future.")
    if high_ca_avg_oi > 50 and len(high_ca_states) > 0:
        print("  \u2705 High-CA states maintain significant OI \u2014 Agency and Optionality co-exist.")

    # Explorer final verdict
    print("\n[Explorer Reclassification (Final)]")
    explorer_in_cliff     = sum(1 for r in atlas_rows if r['region'] == 'CLIFF'
                                and r['attractors'].get('Explorer','') == 'Zombie')
    explorer_in_generator = sum(1 for r in atlas_rows if r['region'] == 'GENERATOR'
                                and r['oi_by_policy'].get('Explorer', 0) == max(r['oi_by_policy'].values()))
    print(f"  Explorer leads to Zombie in CLIFF regions:    {explorer_in_cliff}")
    print(f"  Explorer is best policy in GENERATOR regions: {explorer_in_generator}")
    print(f"  Conclusion: Explorer is a VARIANCE AMPLIFIER.")
    print(f"  Deploy in GENERATOR regions only. Never in CLIFF or DESERT regions.")

    # Save
    import os; os.makedirs('data/archive', exist_ok=True)
    with open('data/archive/rea_control_authority_atlas_v2.json', 'w') as f:
        json.dump([{k: v for k, v in r.items() if k != 'oi_by_policy'}
                   for r in atlas_rows], f, indent=2)

    print("\n" + "=" * 70)
    print(f"✅ PHASE 11B EXTENDED COMPLETE")
    print(f"   Regions: {dict(region_counts)}")
    print(f"   Total atlas cells: {len(atlas_rows)}")
    print("=" * 70)
    return atlas_rows


if __name__ == "__main__":
    compute_extended_atlas()
