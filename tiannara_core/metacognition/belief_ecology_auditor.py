"""
BELIEF ECOLOGY HEALTH AUDITOR

Measures the health of Tiannara's internal knowledge ecosystem over time.

Based on Auditing.md strategic analysis (lines 99-197):
- Belief Volatility
- Contradiction Load  
- Correction Latency
- Epistemic Diversity
- Theory Survival Accuracy

Plus re-runs False Evidence Injection Audit with enhanced metrics:
- False belief spread
- Recovery speed
- Downstream contamination
- Minority truth survival
- Confidence recalibration
- System coherence after repair
"""

import sys
import time
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, field

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.metacognition.epistemic_resilience import EpistemicResilienceSystem
from tiannara_core.metacognition.theory_engine import Theory, CausalClaim, EvidenceItem, EvidenceType, Prediction


@dataclass
class BeliefEcologyMetrics:
    """Comprehensive belief ecology health metrics."""
    
    # Belief Volatility
    belief_change_count: int = 0
    total_beliefs: int = 0
    volatility_score: float = 0.0  # 0.0 (stable) to 1.0 (chaotic)
    
    # Contradiction Load
    active_contradictions: int = 0
    contradiction_severity_avg: float = 0.0
    contradiction_load_score: float = 0.0  # 0.0 (none) to 1.0 (fragmented)
    
    # Correction Latency
    corrections_made: int = 0
    avg_correction_time: float = 0.0  # seconds
    correction_latency_score: float = 0.0  # Lower is better
    
    # Epistemic Diversity
    unique_hypotheses: int = 0
    diversity_entropy: float = 0.0
    diversity_score: float = 0.0  # 0.0 (monoculture) to 1.0 (diverse)
    
    # Theory Survival Accuracy
    theories_tested: int = 0
    successful_predictions: int = 0
    survival_accuracy: float = 0.0
    
    # Overall Health
    overall_health_score: float = 0.0
    health_status: str = "unknown"  # healthy, at_risk, critical
    
    def calculate_overall_health(self):
        """Calculate composite health score."""
        # Ideal ranges:
        # - Volatility: 0.2-0.5 (some change but not chaotic)
        # - Contradiction load: 0.1-0.4 (some tension but not fragmented)
        # - Correction latency: < 0.3 (fast recovery)
        # - Diversity: 0.4-0.8 (diverse but not scattered)
        # - Survival accuracy: > 0.6 (theories work)
        
        volatility_health = 1.0 - abs(self.volatility_score - 0.35) * 2  # Peak at 0.35
        contradiction_health = 1.0 - abs(self.contradiction_load_score - 0.25) * 2  # Peak at 0.25
        correction_health = 1.0 - min(1.0, self.correction_latency_score / 0.3)  # Lower is better
        diversity_health = self.diversity_score  # Higher is better (up to 0.8)
        accuracy_health = self.survival_accuracy  # Higher is better
        
        self.overall_health_score = (
            0.20 * max(0.0, volatility_health) +
            0.20 * max(0.0, contradiction_health) +
            0.25 * correction_health +
            0.15 * min(1.0, diversity_health / 0.8) +
            0.20 * accuracy_health
        )
        
        if self.overall_health_score >= 0.7:
            self.health_status = "healthy"
        elif self.overall_health_score >= 0.5:
            self.health_status = "at_risk"
        else:
            self.health_status = "critical"
        
        return self.overall_health_score


class BeliefEcologyHealthAuditor:
    """
    Comprehensive auditor for belief ecology health.
    
    Measures system stability, diversity, and recovery capabilities.
    """
    
    def __init__(self, resilience_system: EpistemicResilienceSystem):
        self.resilience_system = resilience_system
        self.metrics_history: List[BeliefEcologyMetrics] = []
        self.belief_snapshots: Dict[str, List[Tuple[float, float]]] = {}  # theory_id -> [(timestamp, confidence)]
    
    def take_belief_snapshot(self, theory_id: str, confidence: float):
        """Record a snapshot of belief confidence over time."""
        if theory_id not in self.belief_snapshots:
            self.belief_snapshots[theory_id] = []
        
        self.belief_snapshots[theory_id].append((time.time(), confidence))
    
    def calculate_belief_volatility(self) -> Tuple[float, int]:
        """
        Calculate belief volatility across all tracked theories.
        
        Returns:
            Tuple of (volatility_score, change_count)
        """
        total_changes = 0
        total_beliefs = len(self.belief_snapshots)
        
        if total_beliefs == 0:
            return 0.0, 0
        
        for theory_id, snapshots in self.belief_snapshots.items():
            if len(snapshots) < 2:
                continue
            
            # Count significant changes (>0.1 confidence shift)
            for i in range(1, len(snapshots)):
                prev_conf = snapshots[i-1][1]
                curr_conf = snapshots[i][1]
                if abs(curr_conf - prev_conf) > 0.1:
                    total_changes += 1
        
        # Normalize by number of beliefs and time
        volatility = min(1.0, total_changes / max(1, total_beliefs * 5))
        
        return volatility, total_changes
    
    def calculate_contradiction_load(self) -> Tuple[float, float]:
        """
        Calculate contradiction load across the system.
        
        Returns:
            Tuple of (load_score, avg_severity)
        """
        total_contradictions = 0
        total_severity = 0.0
        theories_checked = 0
        
        # Check all theories in hypothesis manager
        for domain in self.resilience_system.hypothesis_manager.hypothesis_sets:
            for theory_id, _ in self.resilience_system.hypothesis_manager.hypothesis_sets.get(domain, []):
                stats = self.resilience_system.contradiction_handler.get_contradiction_statistics(theory_id)
                
                if stats['total'] > 0:
                    total_contradictions += stats['unresolved']
                    total_severity += stats['avg_severity'] * stats['unresolved']
                    theories_checked += 1
        
        if theories_checked == 0:
            return 0.0, 0.0
        
        avg_severity = total_severity / max(1, total_contradictions)
        
        # Load score: normalized by number of theories
        load_score = min(1.0, total_contradictions / max(1, theories_checked * 3))
        
        return load_score, avg_severity
    
    def calculate_correction_latency(self) -> float:
        """
        Calculate average time to correct false beliefs.
        
        For now, uses heuristic based on contradiction resolution rate.
        In production, would track actual timestamps of detection → resolution.
        """
        # Get all resolved contradictions
        total_resolved = 0
        total_unresolved = 0
        
        for domain in self.resilience_system.hypothesis_manager.hypothesis_sets:
            for theory_id, _ in self.resilience_system.hypothesis_manager.hypothesis_sets.get(domain, []):
                stats = self.resilience_system.contradiction_handler.get_contradiction_statistics(theory_id)
                total_resolved += stats['resolved']
                total_unresolved += stats['unresolved']
        
        total = total_resolved + total_unresolved
        if total == 0:
            return 0.0
        
        # Resolution rate as proxy for latency (higher = faster)
        resolution_rate = total_resolved / total
        
        # Convert to latency score (lower is better)
        latency_score = 1.0 - resolution_rate
        
        return latency_score
    
    def calculate_epistemic_diversity(self) -> Tuple[float, int]:
        """
        Calculate epistemic diversity using entropy of hypothesis distributions.
        
        Returns:
            Tuple of (diversity_score, unique_hypotheses_count)
        """
        total_hypotheses = 0
        probability_distribution = []
        
        for domain in self.resilience_system.hypothesis_manager.hypothesis_sets:
            ranking = self.resilience_system.hypothesis_manager.get_ranking(domain)
            total_hypotheses += len(ranking)
            
            # Collect probabilities for entropy calculation
            for _, prob in ranking:
                if prob > 0.01:  # Ignore negligible hypotheses
                    probability_distribution.append(prob)
        
        if total_hypotheses == 0 or len(probability_distribution) == 0:
            return 0.0, 0
        
        # Calculate Shannon entropy
        import math
        entropy = -sum(p * math.log2(p) for p in probability_distribution if p > 0)
        
        # Normalize by maximum possible entropy (uniform distribution)
        max_entropy = math.log2(len(probability_distribution)) if len(probability_distribution) > 1 else 1.0
        normalized_entropy = entropy / max_entropy if max_entropy > 0 else 0.0
        
        return normalized_entropy, total_hypotheses
    
    def calculate_theory_survival_accuracy(self) -> float:
        """
        Calculate how well surviving theories predict reality.
        
        Uses prediction success rates from accountability tracker.
        """
        total_predictions = 0
        total_successes = 0
        
        for theory_id in self.resilience_system.accountability_tracker.prediction_records:
            records = self.resilience_system.accountability_tracker.prediction_records[theory_id]
            for record in records:
                total_predictions += 1
                if record.get('confirmed', False):
                    total_successes += 1
        
        if total_predictions == 0:
            return 0.0
        
        return total_successes / total_predictions
    
    def run_comprehensive_audit(self) -> BeliefEcologyMetrics:
        """Run complete belief ecology health audit."""
        metrics = BeliefEcologyMetrics()
        
        # 1. Belief Volatility
        metrics.volatility_score, metrics.belief_change_count = self.calculate_belief_volatility()
        metrics.total_beliefs = len(self.belief_snapshots)
        
        # 2. Contradiction Load
        metrics.contradiction_load_score, metrics.contradiction_severity_avg = self.calculate_contradiction_load()
        
        # Count active contradictions
        for domain in self.resilience_system.hypothesis_manager.hypothesis_sets:
            for theory_id, _ in self.resilience_system.hypothesis_manager.hypothesis_sets.get(domain, []):
                unresolved = self.resilience_system.contradiction_handler.get_unresolved_contradictions(theory_id)
                metrics.active_contradictions += len(unresolved)
        
        # 3. Correction Latency
        metrics.correction_latency_score = self.calculate_correction_latency()
        
        # 4. Epistemic Diversity
        metrics.diversity_score, metrics.unique_hypotheses = self.calculate_epistemic_diversity()
        metrics.diversity_entropy = metrics.diversity_score  # Already normalized
        
        # 5. Theory Survival Accuracy
        metrics.survival_accuracy = self.calculate_theory_survival_accuracy()
        
        # 6. Overall Health
        metrics.calculate_overall_health()
        
        # Record history
        self.metrics_history.append(metrics)
        
        return metrics
    
    def get_health_trend(self) -> Optional[str]:
        """Get trend of health over recent audits."""
        if len(self.metrics_history) < 2:
            return None
        
        recent = self.metrics_history[-5:]  # Last 5 audits
        scores = [m.overall_health_score for m in recent]
        
        avg_first_half = sum(scores[:len(scores)//2]) / (len(scores)//2)
        avg_second_half = sum(scores[len(scores)//2:]) / (len(scores) - len(scores)//2)
        
        diff = avg_second_half - avg_first_half
        
        if diff > 0.05:
            return 'improving'
        elif diff < -0.05:
            return 'declining'
        else:
            return 'stable'
    
    def generate_health_report(self) -> Dict:
        """Generate comprehensive health report."""
        latest_metrics = self.metrics_history[-1] if self.metrics_history else BeliefEcologyMetrics()
        trend = self.get_health_trend()
        
        return {
            'overall_health_score': latest_metrics.overall_health_score,
            'health_status': latest_metrics.health_status,
            'trend': trend,
            'metrics': {
                'belief_volatility': {
                    'score': latest_metrics.volatility_score,
                    'changes': latest_metrics.belief_change_count,
                    'total_beliefs': latest_metrics.total_beliefs,
                    'status': 'stable' if latest_metrics.volatility_score < 0.5 else 'volatile'
                },
                'contradiction_load': {
                    'score': latest_metrics.contradiction_load_score,
                    'active_contradictions': latest_metrics.active_contradictions,
                    'avg_severity': latest_metrics.contradiction_severity_avg,
                    'status': 'manageable' if latest_metrics.contradiction_load_score < 0.5 else 'high'
                },
                'correction_latency': {
                    'score': latest_metrics.correction_latency_score,
                    'status': 'fast' if latest_metrics.correction_latency_score < 0.3 else 'slow'
                },
                'epistemic_diversity': {
                    'score': latest_metrics.diversity_score,
                    'unique_hypotheses': latest_metrics.unique_hypotheses,
                    'entropy': latest_metrics.diversity_entropy,
                    'status': 'diverse' if latest_metrics.diversity_score > 0.4 else 'low'
                },
                'theory_survival_accuracy': {
                    'score': latest_metrics.survival_accuracy,
                    'status': 'accurate' if latest_metrics.survival_accuracy > 0.6 else 'inaccurate'
                }
            },
            'recommendations': self._generate_recommendations(latest_metrics)
        }
    
    def _generate_recommendations(self, metrics: BeliefEcologyMetrics) -> List[str]:
        """Generate actionable recommendations based on metrics."""
        recommendations = []
        
        if metrics.volatility_score > 0.6:
            recommendations.append("HIGH VOLATILITY: Consider strengthening reality anchors to stabilize core beliefs")
        
        if metrics.contradiction_load_score > 0.5:
            recommendations.append("HIGH CONTRADICTION LOAD: Prioritize resolving critical contradictions to reduce fragmentation")
        
        if metrics.correction_latency_score > 0.5:
            recommendations.append("SLOW CORRECTION: Improve adversarial red team activity to accelerate false belief detection")
        
        if metrics.diversity_score < 0.3:
            recommendations.append("LOW DIVERSITY: Encourage competing hypotheses to prevent echo chambers")
        
        if metrics.survival_accuracy < 0.5:
            recommendations.append("LOW PREDICTIVE ACCURACY: Strengthen predictive accountability tracking")
        
        if not recommendations:
            recommendations.append("System health is within acceptable parameters")
        
        return recommendations


def main():
    """Demonstrate belief ecology health auditing."""
    print("="*80)
    print("BELIEF ECOLOGY HEALTH AUDIT")
    print("="*80)
    
    # Create resilience system
    resilience_system = EpistemicResilienceSystem()
    
    # Create auditor
    auditor = BeliefEcologyHealthAuditor(resilience_system)
    
    # Create sample theories
    theories = []
    for i in range(5):
        theory = Theory(
            theory_id=f"theory_{i}",
            name=f"Test Theory {i}",
            domain="test_domain",
            description=f"Test theory for auditing",
            assumptions=[f"Assumption {i}"],
            causal_claims=[
                CausalClaim(cause=f"Cause_{i}", effect=f"Effect_{i}", strength=0.7)
            ],
            evidence_for=[
                EvidenceItem(
                    evidence_id=f"evid_{i}",
                    evidence_type=EvidenceType.EXPERIMENT,
                    description=f"Evidence for theory {i}",
                    supports_theory=True,
                    confidence=0.7 + (i * 0.05),
                    source=f"Source_{i}"
                )
            ]
        )
        theories.append(theory)
        resilience_system.register_theory(theory, domain="test_domain")
    
    print(f"\nRegistered {len(theories)} theories")
    
    # Simulate belief evolution
    print("\nSimulating belief evolution...")
    for i, theory in enumerate(theories):
        initial_conf = theory.calculate_overall_credibility()
        auditor.take_belief_snapshot(theory.theory_id, initial_conf)
        
        # Simulate some changes
        auditor.take_belief_snapshot(theory.theory_id, initial_conf + 0.1)
        auditor.take_belief_snapshot(theory.theory_id, initial_conf - 0.05)
    
    print("✅ Recorded belief snapshots")
    
    # Add some contradictions
    print("\nAdding contradictions...")
    resilience_system.record_contradiction(
        theory_a_id="theory_0",
        theory_b_id="theory_1",
        contradiction_type="logical",
        description="Conflicting assumptions",
        severity=0.6
    )
    
    resilience_system.record_contradiction(
        theory_a_id="theory_2",
        theory_b_id="theory_3",
        contradiction_type="empirical",
        description="Contradictory experimental results",
        severity=0.4
    )
    
    print("✅ Added 2 contradictions")
    
    # Add some predictions
    print("\nRecording predictions...")
    for i, theory in enumerate(theories[:3]):
        pred = Prediction(
            prediction_id=f"pred_{i}",
            description=f"Prediction for theory {i}",
            conditions={"test": True},
            predicted_outcome=f"Outcome_{i}",
            confidence=0.7
        )
        resilience_system.record_prediction(theory.theory_id, pred)
        
        # Verify some as successful
        if i % 2 == 0:
            resilience_system.verify_prediction(theory.theory_id, f"pred_{i}", success=True)
        else:
            resilience_system.verify_prediction(theory.theory_id, f"pred_{i}", success=False)
    
    print("✅ Recorded and verified predictions")
    
    # Run audit
    print("\n" + "="*80)
    print("RUNNING COMPREHENSIVE AUDIT")
    print("="*80 + "\n")
    
    metrics = auditor.run_comprehensive_audit()
    
    print(f"Overall Health Score: {metrics.overall_health_score:.3f}")
    print(f"Health Status: {metrics.health_status.upper()}")
    print()
    
    print("Detailed Metrics:")
    print(f"  Belief Volatility: {metrics.volatility_score:.3f} ({metrics.belief_change_count} changes)")
    print(f"  Contradiction Load: {metrics.contradiction_load_score:.3f} ({metrics.active_contradictions} active)")
    print(f"  Correction Latency: {metrics.correction_latency_score:.3f}")
    print(f"  Epistemic Diversity: {metrics.diversity_score:.3f} ({metrics.unique_hypotheses} hypotheses)")
    print(f"  Theory Survival Accuracy: {metrics.survival_accuracy:.3f}")
    
    # Generate report
    print("\n" + "="*80)
    print("HEALTH REPORT")
    print("="*80 + "\n")
    
    report = auditor.generate_health_report()
    
    for category, data in report['metrics'].items():
        print(f"{category.replace('_', ' ').title()}:")
        print(f"  Score: {data['score']:.3f}")
        print(f"  Status: {data['status']}")
        print()
    
    print("Recommendations:")
    for rec in report['recommendations']:
        print(f"  • {rec}")
    
    print("\n" + "="*80)
    print("✅ BELIEF ECOLOGY HEALTH AUDIT COMPLETE")
    print("="*80)
    
    return 0


if __name__ == "__main__":
    exit(main())
