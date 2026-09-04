import json

def encode_institution_genome(inst_id, lineage_id, epoch, metrics, tfi, fri, path_entropy, migration_persistence, lineage_age):
    """
    Encodes the extracted metrics into the canonical InstitutionGenome JSON.
    """
    genome = {
        "id": inst_id,
        "lineage_id": lineage_id,
        "epoch": epoch,
        "dcr": metrics['dcr'],
        "scp": metrics['scp'],
        "dci": metrics['dci'],
        "redundancy": metrics['mean_degree'],
        "entropy": path_entropy,
        "tfi": tfi,
        "fri": fri,
        "lineage_age": lineage_age,
        "migration_persistence": migration_persistence,
        "trust_centrality_top_10": _get_top_10_hubs(metrics['trust_centrality_global']),
        "radius_of_gyration": metrics['radius_of_gyration']
    }
    return genome

def encode_constitution_genome(const_id, epoch, thermo, spatial):
    """
    Encodes the laws of the universe into the ConstitutionGenome JSON.
    """
    genome = {
        "id": const_id,
        "epoch": epoch,
        "gamma_persistence": thermo['gamma_persistence'],
        "rho_signal": thermo['rho_signal'],
        "alpha_trust": thermo['alpha_trust'],
        "tau_explore": thermo['tau_explore'],
        "radius": spatial.get('radius', 5),
        "movement_budget": spatial.get('movement_budget', 1),
        "signal_horizon": spatial.get('signal_horizon', 5.0),
        "trust_horizon": spatial.get('trust_horizon', 1.5)
    }
    return genome

def _get_top_10_hubs(trust_centrality):
    import numpy as np
    top_10 = max(1, int(len(trust_centrality) * 0.10))
    current_hubs = np.argsort(trust_centrality)[-top_10:]
    return current_hubs.tolist()
