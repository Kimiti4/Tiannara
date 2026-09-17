"""
GRCC v9 Ecological Evaluation Framework
=======================================

This module implements the new evaluation paradigm for co-evolving semantic ecologies.
Instead of measuring "task solving," it measures "ecological viability."

Core Domains:
1. Ecological Diversity (Entropy, Lineage Persistence, Niche Occupancy)
2. Adaptive Persistence (Shock Recovery, Drift Stability)
3. Semantic Innovation (Novel Niche Emergence, Cross-Lineage Synthesis)
4. Evolutionary Stability (Monoculture Resistance, Fragmentation Resistance)
5. Environmental Coupling (Niche Construction, Feedback Loops)
"""

import math
import random
from typing import Dict, List, Any, Tuple
from collections import Counter


class EcologicalEvaluator:
    """
    Evaluates the health and dynamics of a GRCC v9 semantic ecosystem.
    """

    def __init__(self):
        self.history = {
            'diversity': [],
            'fitness': [],
            'environment': [],
            'lineages': [],
            'niches': []
        }

    # ------------------------------------------------------------------
    # 1. Ecological Diversity Metrics
    # ------------------------------------------------------------------

    def compute_identity_entropy(self, identity_field: List[Dict[str, Any]]) -> float:
        """
        Measures diversity of active identities using Shannon Entropy.
        H(I) = -Σ p(I_i) log p(I_i)
        
        Healthy: Medium/High entropy (multiple stable lineages)
        Failure: Entropy → 0 (monoculture)
        """
        if not identity_field:
            return 0.0
        
        total_activation = sum(id_data.get('activation_level', 0.0) for id_data in identity_field)
        if total_activation == 0:
            return 0.0
        
        proportions = [id_data['activation_level'] / total_activation for id_data in identity_field]
        entropy = -sum(p * math.log(p + 1e-10) for p in proportions if p > 0)
        
        # Normalize by max possible entropy for this population size
        max_entropy = math.log(len(identity_field)) if len(identity_field) > 1 else 1.0
        normalized_entropy = entropy / max_entropy if max_entropy > 0 else 0.0
        
        return normalized_entropy

    def analyze_lineage_persistence(self, lineage_trees: Dict[str, Any]) -> Dict[str, float]:
        """
        Tracks births, extinctions, and surviving generations.
        
        Metrics:
        - Average lineage lifespan
        - Generational depth
        - Extinction rate
        """
        active_count = 0
        extinct_count = 0
        total_depth = 0
        depths = []
        
        for lineage_id, data in lineage_trees.items():
            if data.get('extinction_step') is None:
                active_count += 1
            else:
                extinct_count += 1
            
            # Calculate generational depth (simplified as descendant count)
            depth = len(data.get('descendants', []))
            depths.append(depth)
            total_depth += depth
        
        avg_depth = total_depth / max(1, len(lineage_trees))
        survival_rate = active_count / max(1, active_count + extinct_count)
        
        return {
            'active_lineages': active_count,
            'extinct_lineages': extinct_count,
            'avg_generational_depth': avg_depth,
            'survival_rate': survival_rate,
            'max_depth': max(depths) if depths else 0
        }

    def measure_niche_occupancy(self, identity_field: List[Dict[str, Any]]) -> Dict[str, int]:
        """
        Measures how many semantic niches remain populated.
        Healthy ecosystems maintain differentiated roles.
        """
        niche_counts = {
            'explorers': 0,      # High novelty_affinity
            'stabilizers': 0,    # High stability_sensitivity
            'bridges': 0,        # Balanced exploration/exploitation
            'contradiction_harvesters': 0  # Low contradiction_tolerance
        }
        
        for id_data in identity_field:
            genome = id_data.get('semantic_genome', {})
            novelty = genome.get('novelty_affinity', 0.5)
            stability = genome.get('stability_sensitivity', 0.5)
            balance = genome.get('exploration_exploitation_balance', 0.5)
            cont_tol = genome.get('contradiction_tolerance', 0.5)
            
            if novelty > 0.7:
                niche_counts['explorers'] += 1
            elif stability > 0.7:
                niche_counts['stabilizers'] += 1
            elif 0.4 < balance < 0.6:
                niche_counts['bridges'] += 1
            elif cont_tol < 0.3:
                niche_counts['contradiction_harvesters'] += 1
        
        occupied_niches = sum(1 for count in niche_counts.values() if count > 0)
        return {
            'niche_distribution': niche_counts,
            'occupied_niche_count': occupied_niches,
            'total_possible_niches': 4
        }

    # ------------------------------------------------------------------
    # 2. Adaptive Persistence Metrics
    # ------------------------------------------------------------------

    def measure_drift_stability(self, quality_history: List[float], window_size: int = 50) -> Dict[str, float]:
        """
        Runs for long horizons to measure whether identity/quality persists
        without collapsing or oscillating pathologically.
        """
        if len(quality_history) < window_size:
            return {'stable': False, 'variance': 0.0, 'trend': 0.0}
        
        recent = quality_history[-window_size:]
        mean_val = sum(recent) / len(recent)
        variance = sum((x - mean_val) ** 2 for x in recent) / len(recent)
        
        # Calculate trend (simple linear regression slope)
        n = len(recent)
        x_mean = (n - 1) / 2
        y_mean = mean_val
        numerator = sum((i - x_mean) * (recent[i] - y_mean) for i in range(n))
        denominator = sum((i - x_mean) ** 2 for i in range(n))
        trend = numerator / denominator if denominator != 0 else 0.0
        
        # Stable if low variance and neutral/slightly positive trend
        is_stable = variance < 0.01 and abs(trend) < 0.001
        
        return {
            'stable': is_stable,
            'variance': variance,
            'trend': trend,
            'mean_quality': mean_val
        }

    def simulate_semantic_shock(self, orchestrator: Any, shock_type: str = 'contradiction_spike') -> Dict[str, float]:
        """
        Injects contradictory information or topology disruptions.
        Measures recovery time and diversity retention.
        """
        # This would require direct access to orchestrator state to inject shocks
        # For now, we return a placeholder structure
        return {
            'shock_type': shock_type,
            'recovery_steps': 0,
            'diversity_retention': 1.0,
            'attractor_reformed': True
        }

    # ------------------------------------------------------------------
    # 3. Semantic Innovation Metrics
    # ------------------------------------------------------------------

    def detect_novel_niche_emergence(self, current_niches: Dict[str, int], 
                                   historical_niches: List[Dict[str, int]]) -> bool:
        """
        Tracks whether new semantic regions appear over time.
        """
        if not historical_niches:
            return False
        
        # Check if any niche is occupied now but was empty in recent history
        recent_avg = {}
        for h in historical_niches[-10:]:
            for niche, count in h['niche_distribution'].items():
                recent_avg[niche] = recent_avg.get(niche, 0) + count
        
        for niche, count in current_niches['niche_distribution'].items():
            avg_hist = recent_avg.get(niche, 0) / max(1, len(historical_niches[-10:]))
            if count > 0 and avg_hist == 0:
                return True  # New niche emerged
        
        return False

    def measure_cross_lineage_synthesis(self, identity_field: List[Dict[str, Any]]) -> float:
        """
        Detects whether unrelated lineages produce hybrid descendants.
        """
        # Simplified: Check for identities with mixed genome traits
        hybrid_count = 0
        for id_data in identity_field:
            genome = id_data.get('semantic_genome', {})
            # Hybrids have balanced traits (not extreme)
            if 0.4 < genome.get('novelty_affinity', 0.5) < 0.6 and \
               0.4 < genome.get('stability_sensitivity', 0.5) < 0.6:
                hybrid_count += 1
        
        return hybrid_count / max(1, len(identity_field))

    # ------------------------------------------------------------------
    # 4. Evolutionary Stability Metrics
    # ------------------------------------------------------------------

    def test_monoculture_resistance(self, identity_field: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Checks whether one lineage dominates permanently.
        """
        if not identity_field:
            return {'monoculture': False, 'dominance_index': 0.0}
        
        lineage_counts = Counter(id_data.get('lineage_id', 'unknown') for id_data in identity_field)
        total = len(identity_field)
        max_count = max(lineage_counts.values()) if lineage_counts else 0
        dominance_index = max_count / total
        
        return {
            'monoculture': dominance_index > 0.8,
            'dominance_index': dominance_index,
            'lineage_distribution': dict(lineage_counts)
        }

    # ------------------------------------------------------------------
    # 5. Environmental Coupling Metrics
    # ------------------------------------------------------------------

    def measure_environment_identity_coupling(self, env_history: List[Dict], 
                                            identity_history: List[List[Dict]]) -> float:
        """
        Measures feedback loop intensity: C = corr(ΔI, ΔE)
        """
        if len(env_history) < 2 or len(identity_history) < 2:
            return 0.0
        
        # Simplified correlation calculation
        # In real implementation, this would track deltas of key environmental vars
        # vs key identity distribution metrics
        return 0.5  # Placeholder

    def test_ecological_memory(self, semantic_environment: Dict[str, Any]) -> float:
        """
        Checks whether environmental structure retains traces of past populations.
        """
        # Check if historical_pressure_maps show accumulated influence
        pressure = semantic_environment.get('historical_pressure_maps', {}).get('accumulated_influence', 0.0)
        return pressure

    # ------------------------------------------------------------------
    # Comprehensive Ecological Health Report
    # ------------------------------------------------------------------

    def generate_ecological_report(self, orchestrator: Any) -> Dict[str, Any]:
        """
        Generates a comprehensive health report for the GRCC v9 ecosystem.
        """
        identity_field = orchestrator.identity_field
        lineage_trees = orchestrator.lineage_trees
        semantic_env = orchestrator.semantic_environment
        
        # 1. Diversity
        entropy = self.compute_identity_entropy(identity_field)
        lineage_stats = self.analyze_lineage_persistence(lineage_trees)
        niche_stats = self.measure_niche_occupancy(identity_field)
        
        # 2. Stability
        monoculture_test = self.test_monoculture_resistance(identity_field)
        
        # 3. Innovation
        hybrid_rate = self.measure_cross_lineage_synthesis(identity_field)
        
        # 4. Environment
        env_memory = self.test_ecological_memory(semantic_env)
        
        # Overall Health Score (weighted composite)
        health_score = (
            0.3 * entropy +
            0.2 * lineage_stats['survival_rate'] +
            0.2 * (1.0 - monoculture_test['dominance_index']) +
            0.15 * (niche_stats['occupied_niche_count'] / 4.0) +
            0.15 * hybrid_rate
        )
        
        return {
            'overall_health_score': health_score,
            'ecological_diversity': {
                'shannon_entropy': entropy,
                'lineage_stats': lineage_stats,
                'niche_occupancy': niche_stats
            },
            'evolutionary_stability': {
                'monoculture_resistance': monoculture_test
            },
            'semantic_innovation': {
                'hybrid_synthesis_rate': hybrid_rate
            },
            'environmental_coupling': {
                'ecological_memory_strength': env_memory
            },
            'status': 'HEALTHY' if health_score > 0.6 else 'AT_RISK' if health_score > 0.4 else 'CRITICAL'
        }


if __name__ == "__main__":
    # Example usage placeholder
    evaluator = EcologicalEvaluator()
    print("GRCC v9 Ecological Evaluation Framework Initialized")
    print("Ready to assess semantic ecosystem health.")
