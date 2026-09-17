"""
INTERNAL THEORY FORMATION SYSTEM

Purpose: Enable Tiannara to create explanatory world models through theory objects
that contain assumptions, causal claims, evidence chains, and predictive success metrics.

This moves Tiannara from "evaluating outputs" to "creating explanations" - 
much closer to science than standard AI (per FINAL_AUDIT_COMPLETION_SUMMARY.md lines 770-810).

Based on audit.md recommendation for structural intelligence development.

Architecture:
Instead of:
    answer = model.predict(input)  # ❌ Just output, no explanation

Use:
    theory = Theory(
        name="Gravity causes objects to fall",
        assumptions=["Mass attracts mass", "Space is curved by energy"],
        causal_claims=[Claim("mass", "gravitational_force", strength=0.95)],
        evidence_chains=[Evidence(source="observation", confidence=0.9)],
        counterexamples=[],
        predictive_success=0.92
    )
    # ✅ Explanatory model with testable predictions

Components:
theory_engine/
├─ Theory.py                    # Core theory object with all metadata
├─ CausalClaim.py              # Individual causal relationship
├─ EvidenceChain.py            # Supporting/contradicting evidence
├─ TheoryCompetitor.py         # Compete theories based on evidence
├─ TheoryMerger.py             # Merge compatible theories
└─ TheoryEvolutionEngine.py    # Evolve theories over time
"""

import time
import math
from dataclasses import dataclass, field
from typing import List, Dict, Optional, Tuple
from enum import Enum


class TheoryStatus(Enum):
    """Lifecycle status of a theory."""
    HYPOTHESIS = "hypothesis"           # Newly proposed, untested
    TESTING = "testing"                 # Under active evaluation
    ESTABLISHED = "established"         # Supported by evidence
    CHALLENGED = "challenged"           # Facing contradictory evidence
    SUPERSEDED = "superseded"           # Replaced by better theory
    RETIRED = "retired"                 # No longer considered valid


class EvidenceType(Enum):
    """Types of evidence supporting or contradicting theories."""
    OBSERVATION = "observation"         # Direct empirical observation
    EXPERIMENT = "experiment"           # Controlled experimental result
    LOGICAL_DEDUCTION = "logical_deduction"  # Derived from other theories
    EXPERT_CONSENSUS = "expert_consensus"    # Agreement among experts
    STATISTICAL_CORRELATION = "statistical_correlation"  # Statistical pattern
    SIMULATION = "simulation"           # Computational simulation result


@dataclass
class CausalClaim:
    """
    Represents a single causal relationship within a theory.
    
    Example: "Increased temperature CAUSES increased pressure" 
    (with strength 0.85, direction positive)
    """
    cause: str                      # The causal factor
    effect: str                     # The resulting effect
    strength: float                 # Causal strength (0.0 - 1.0)
    direction: str = "positive"     # "positive", "negative", or "nonlinear"
    mechanism: Optional[str] = None # Explanation of how cause produces effect
    confidence: float = 0.5         # Confidence in this specific claim
    tested: bool = False            # Whether this claim has been empirically tested
    
    def __post_init__(self):
        """Validate causal claim parameters."""
        if not 0.0 <= self.strength <= 1.0:
            raise ValueError(f"Causal strength must be 0.0-1.0, got {self.strength}")
        if not 0.0 <= self.confidence <= 1.0:
            raise ValueError(f"Confidence must be 0.0-1.0, got {self.confidence}")
        if self.direction not in ["positive", "negative", "nonlinear"]:
            raise ValueError(f"Direction must be positive/negative/nonlinear, got {self.direction}")


@dataclass
class EvidenceItem:
    """Single piece of evidence for or against a theory."""
    evidence_id: str
    evidence_type: EvidenceType
    description: str
    supports_theory: bool           # True if supports, False if contradicts
    confidence: float               # Confidence in this evidence (0.0 - 1.0)
    source: str                     # Source of evidence (e.g., "experiment_42")
    timestamp: float = field(default_factory=time.time)
    reproducibility: float = 0.5    # How reproducible is this evidence (0.0 - 1.0)
    
    def __post_init__(self):
        """Validate evidence parameters."""
        if not 0.0 <= self.confidence <= 1.0:
            raise ValueError(f"Evidence confidence must be 0.0-1.0, got {self.confidence}")
        if not 0.0 <= self.reproducibility <= 1.0:
            raise ValueError(f"Reproducibility must be 0.0-1.0, got {self.reproducibility}")


@dataclass
class Counterexample:
    """
    A specific case where the theory fails or makes incorrect predictions.
    
    Critical for theory refinement and eventual retirement.
    """
    description: str                # Description of the counterexample
    severity: float                 # How severely it challenges the theory (0.0 - 1.0)
    frequency: str = "rare"         # "rare", "occasional", "common", "systematic"
    explained: bool = False         # Whether theory has been updated to explain this
    discovery_date: float = field(default_factory=time.time)
    
    def __post_init__(self):
        """Validate counterexample parameters."""
        if not 0.0 <= self.severity <= 1.0:
            raise ValueError(f"Severity must be 0.0-1.0, got {self.severity}")
        if self.frequency not in ["rare", "occasional", "common", "systematic"]:
            raise ValueError(f"Frequency must be rare/occasional/common/systematic")


@dataclass
class Prediction:
    """
    A testable prediction made by the theory.
    
    Theories gain credibility when predictions are confirmed.
    """
    prediction_id: str
    description: str                # What should happen
    conditions: Dict[str, any]      # Conditions under which prediction applies
    predicted_outcome: str          # Expected result
    confidence: float               # Theory's confidence in this prediction
    tested: bool = False            # Whether prediction has been tested
    confirmed: Optional[bool] = None  # None=untested, True=confirmed, False=refuted
    test_date: Optional[float] = None


@dataclass
class Theory:
    """
    Core theory object containing explanatory world model.
    
    A theory is more than a belief - it's a structured explanation with:
    - Assumptions (foundational premises)
    - Causal claims (mechanistic relationships)
    - Evidence chains (supporting/contradicting data)
    - Counterexamples (known failures)
    - Predictive success (track record)
    
    This enables theory competition, merging, and evolution.
    """
    theory_id: str
    name: str                       # Human-readable name
    domain: str                     # Domain of applicability (e.g., "physics", "biology")
    description: str                # Comprehensive explanation
    
    # Core components
    assumptions: List[str] = field(default_factory=list)
    causal_claims: List[CausalClaim] = field(default_factory=list)
    evidence_for: List[EvidenceItem] = field(default_factory=list)
    evidence_against: List[EvidenceItem] = field(default_factory=list)
    counterexamples: List[Counterexample] = field(default_factory=list)
    predictions: List[Prediction] = field(default_factory=list)
    
    # Metadata
    created_at: float = field(default_factory=time.time)
    last_updated: float = field(default_factory=time.time)
    status: TheoryStatus = TheoryStatus.HYPOTHESIS
    
    # Performance metrics
    predictive_success: float = 0.0     # Accuracy of predictions (0.0 - 1.0)
    explanatory_power: float = 0.0      # How much phenomena it explains (0.0 - 1.0)
    simplicity_score: float = 0.5       # Occam's razor: simpler is better (0.0 - 1.0)
    survival_duration: float = 0.0      # Days since creation
    
    # Relationships
    supersedes: List[str] = field(default_factory=list)  # Theories this replaces
    superseded_by: Optional[str] = None  # Better theory that replaced this
    compatible_with: List[str] = field(default_factory=list)  # Theories it works with
    
    def __post_init__(self):
        """Validate theory parameters and calculate initial metrics."""
        if not 0.0 <= self.predictive_success <= 1.0:
            raise ValueError(f"Predictive success must be 0.0-1.0, got {self.predictive_success}")
        
        # Calculate survival duration
        self.survival_duration = (time.time() - self.created_at) / 86400  # Days
        
        # Update status based on evidence
        self._update_status()
    
    def _update_status(self):
        """Update theory status based on evidence balance."""
        total_evidence = len(self.evidence_for) + len(self.evidence_against)
        
        if total_evidence == 0:
            self.status = TheoryStatus.HYPOTHESIS
            return
        
        # Calculate evidence ratio
        support_ratio = len(self.evidence_for) / total_evidence if total_evidence > 0 else 0
        
        # Check for systematic counterexamples
        has_systematic = any(ce.frequency == "systematic" for ce in self.counterexamples)
        
        if has_systematic:
            self.status = TheoryStatus.CHALLENGED
        elif support_ratio > 0.8 and len(self.evidence_for) >= 3:
            self.status = TheoryStatus.ESTABLISHED
        elif support_ratio < 0.3:
            self.status = TheoryStatus.CHALLENGED
        else:
            self.status = TheoryStatus.TESTING
    
    def add_evidence(self, evidence: EvidenceItem):
        """Add new evidence and update metrics."""
        if evidence.supports_theory:
            self.evidence_for.append(evidence)
        else:
            self.evidence_against.append(evidence)
        
        self.last_updated = time.time()
        self._update_status()
    
    def add_counterexample(self, counterexample: Counterexample):
        """Record a failure case."""
        self.counterexamples.append(counterexample)
        self.last_updated = time.time()
        self._update_status()
    
    def add_prediction(self, prediction: Prediction):
        """Add a testable prediction."""
        self.predictions.append(prediction)
    
    def confirm_prediction(self, prediction_id: str, confirmed: bool):
        """Update prediction status and recalculate predictive success."""
        for pred in self.predictions:
            if pred.prediction_id == prediction_id:
                pred.tested = True
                pred.confirmed = confirmed
                pred.test_date = time.time()
                break
        
        # Recalculate predictive success
        tested_predictions = [p for p in self.predictions if p.tested]
        if tested_predictions:
            confirmed_count = sum(1 for p in tested_predictions if p.confirmed)
            self.predictive_success = confirmed_count / len(tested_predictions)
        
        self.last_updated = time.time()
    
    def calculate_overall_credibility(self) -> float:
        """
        Calculate overall credibility score combining multiple factors.
        
        Formula:
        credibility = (predictive_success × 0.4) + 
                     (evidence_ratio × 0.3) + 
                     (explanatory_power × 0.2) + 
                     (simplicity × 0.1)
        """
        # Evidence ratio
        total_evidence = len(self.evidence_for) + len(self.evidence_against)
        evidence_ratio = len(self.evidence_for) / total_evidence if total_evidence > 0 else 0.5
        
        # Penalize for counterexamples
        counterexample_penalty = sum(
            ce.severity * (0.5 if ce.frequency == "rare" else 
                          0.7 if ce.frequency == "occasional" else
                          0.9 if ce.frequency == "common" else 1.0)
            for ce in self.counterexamples
            if not ce.explained
        )
        counterexample_penalty = min(1.0, counterexample_penalty / max(1, len(self.counterexamples)))
        
        adjusted_evidence = evidence_ratio * (1 - counterexample_penalty * 0.5)
        
        # Weighted combination
        credibility = (
            self.predictive_success * 0.4 +
            adjusted_evidence * 0.3 +
            self.explanatory_power * 0.2 +
            self.simplicity_score * 0.1
        )
        
        return max(0.0, min(1.0, credibility))
    
    def is_compatible_with(self, other: 'Theory') -> bool:
        """Check if this theory is compatible with another theory."""
        # Check if either supersedes the other
        if other.theory_id in self.supersedes or self.theory_id in other.supersedes:
            return False
        
        # Check for direct contradictions in causal claims
        for claim_a in self.causal_claims:
            for claim_b in other.causal_claims:
                if (claim_a.cause == claim_b.cause and 
                    claim_a.effect == claim_b.effect and
                    claim_a.direction != claim_b.direction):
                    return False
        
        return True
    
    def to_dict(self) -> Dict:
        """Convert theory to dictionary for serialization."""
        return {
            'theory_id': self.theory_id,
            'name': self.name,
            'domain': self.domain,
            'description': self.description,
            'assumptions': self.assumptions,
            'causal_claims': [
                {
                    'cause': c.cause,
                    'effect': c.effect,
                    'strength': c.strength,
                    'direction': c.direction
                }
                for c in self.causal_claims
            ],
            'evidence_for_count': len(self.evidence_for),
            'evidence_against_count': len(self.evidence_against),
            'counterexample_count': len(self.counterexamples),
            'prediction_count': len(self.predictions),
            'predictive_success': self.predictive_success,
            'explanatory_power': self.explanatory_power,
            'credibility': self.calculate_overall_credibility(),
            'status': self.status.value,
            'survival_duration_days': self.survival_duration,
            'created_at': self.created_at
        }


class TheoryCompetitor:
    """
    Manages competition between rival theories explaining the same phenomena.
    
    Theories compete based on:
    - Predictive accuracy
    - Evidence support
    - Explanatory power
    - Simplicity (Occam's razor)
    """
    
    def __init__(self):
        self.competition_history: List[Dict] = []
    
    def compete(self, theories: List[Theory]) -> Tuple[Theory, List[Theory]]:
        """
        Run competition between theories, return winner and ranking.
        
        Args:
            theories: List of competing theories
            
        Returns:
            Tuple of (winning_theory, ranked_list)
        """
        if not theories:
            raise ValueError("Must provide at least one theory")
        
        if len(theories) == 1:
            return theories[0], theories
        
        # Score each theory
        scored_theories = []
        for theory in theories:
            credibility = theory.calculate_overall_credibility()
            
            # Bonus for established status
            status_bonus = 0.1 if theory.status == TheoryStatus.ESTABLISHED else 0.0
            
            # Penalty for many counterexamples
            counterexample_penalty = len(theory.counterexamples) * 0.05
            
            final_score = credibility + status_bonus - counterexample_penalty
            final_score = max(0.0, min(1.0, final_score))
            
            scored_theories.append((theory, final_score))
        
        # Sort by score (descending)
        scored_theories.sort(key=lambda x: x[1], reverse=True)
        
        winner = scored_theories[0][0]
        ranked_list = [t for t, s in scored_theories]
        
        # Record competition
        self.competition_history.append({
            'timestamp': time.time(),
            'num_theories': len(theories),
            'winner_id': winner.theory_id,
            'winner_score': scored_theories[0][1],
            'scores': [(t.theory_id, s) for t, s in scored_theories]
        })
        
        return winner, ranked_list


class TheoryMerger:
    """
    Merges compatible theories into unified explanations.
    
    Useful when multiple theories explain different aspects of the same phenomenon.
    """
    
    def merge(self, theory_a: Theory, theory_b: Theory, merged_name: str) -> Optional[Theory]:
        """
        Attempt to merge two compatible theories.
        
        Args:
            theory_a: First theory
            theory_b: Second theory
            merged_name: Name for merged theory
            
        Returns:
            Merged theory or None if incompatible
        """
        # Check compatibility
        if not theory_a.is_compatible_with(theory_b):
            return None
        
        # Create merged theory
        merged = Theory(
            theory_id=f"merged_{theory_a.theory_id}_{theory_b.theory_id}",
            name=merged_name,
            domain=theory_a.domain,
            description=f"Merged theory combining {theory_a.name} and {theory_b.name}",
            assumptions=list(set(theory_a.assumptions + theory_b.assumptions)),
            causal_claims=theory_a.causal_claims + theory_b.causal_claims,
            evidence_for=theory_a.evidence_for + theory_b.evidence_for,
            evidence_against=theory_a.evidence_against + theory_b.evidence_against,
            counterexamples=theory_a.counterexamples + theory_b.counterexamples,
            predictions=theory_a.predictions + theory_b.predictions
        )
        
        # Calculate combined metrics (weighted average)
        total_evidence = len(merged.evidence_for) + len(merged.evidence_against)
        if total_evidence > 0:
            merged.predictive_success = (
                theory_a.predictive_success * len(theory_a.predictions) +
                theory_b.predictive_success * len(theory_b.predictions)
            ) / max(1, len(theory_a.predictions) + len(theory_b.predictions))
            
            merged.explanatory_power = min(1.0, 
                theory_a.explanatory_power + theory_b.explanatory_power
            )
        
        # Mark original theories as superseded
        theory_a.superseded_by = merged.theory_id
        theory_b.superseded_by = merged.theory_id
        merged.supersedes = [theory_a.theory_id, theory_b.theory_id]
        
        return merged


class TheoryEvolutionEngine:
    """
    Orchestrates theory lifecycle: creation, testing, competition, merging, retirement.
    
    This is the core of structural intelligence - learning HOW to think by evolving
    explanatory models over time.
    """
    
    def __init__(self):
        self.theory_registry: Dict[str, Theory] = {}
        self.competitor = TheoryCompetitor()
        self.merger = TheoryMerger()
        
        # Evolution statistics
        self.stats = {
            'theories_created': 0,
            'theories_retired': 0,
            'competitions_run': 0,
            'mergers_performed': 0
        }
    
    def register_theory(self, theory: Theory):
        """Register a new theory in the system."""
        self.theory_registry[theory.theory_id] = theory
        self.stats['theories_created'] += 1
    
    def get_theories_for_domain(self, domain: str) -> List[Theory]:
        """Get all active theories in a domain."""
        return [
            t for t in self.theory_registry.values()
            if t.domain == domain and t.status != TheoryStatus.RETIRED
        ]
    
    def run_competition(self, domain: str) -> Optional[Theory]:
        """
        Run competition between all theories in a domain.
        
        Returns winning theory or None if no theories exist.
        """
        theories = self.get_theories_for_domain(domain)
        
        if not theories:
            return None
        
        if len(theories) == 1:
            return theories[0]
        
        winner, ranking = self.competitor.compete(theories)
        self.stats['competitions_run'] += 1
        
        # Mark loser statuses
        for theory in ranking[1:]:  # All except winner
            if theory.calculate_overall_credibility() < 0.3:
                theory.status = TheoryStatus.SUPERSEDED
        
        return winner
    
    def attempt_merger(self, theory_id_a: str, theory_id_b: str, merged_name: str) -> Optional[Theory]:
        """Attempt to merge two theories."""
        theory_a = self.theory_registry.get(theory_id_a)
        theory_b = self.theory_registry.get(theory_id_b)
        
        if not theory_a or not theory_b:
            return None
        
        merged = self.merger.merge(theory_a, theory_b, merged_name)
        
        if merged:
            self.register_theory(merged)
            self.stats['mergers_performed'] += 1
            
            # Retire old theories
            theory_a.status = TheoryStatus.SUPERSEDED
            theory_b.status = TheoryStatus.SUPERSEDED
        
        return merged
    
    def retire_theory(self, theory_id: str, reason: str):
        """Retire a theory that's no longer useful."""
        theory = self.theory_registry.get(theory_id)
        if theory:
            theory.status = TheoryStatus.RETIRED
            self.stats['theories_retired'] += 1
    
    def get_evolution_report(self) -> Dict:
        """Generate report on theory evolution."""
        active_theories = [
            t for t in self.theory_registry.values()
            if t.status != TheoryStatus.RETIRED
        ]
        
        by_status = {}
        for theory in active_theories:
            status = theory.status.value
            by_status[status] = by_status.get(status, 0) + 1
        
        avg_credibility = (
            sum(t.calculate_overall_credibility() for t in active_theories) / len(active_theories)
            if active_theories else 0
        )
        
        return {
            'total_theories': len(self.theory_registry),
            'active_theories': len(active_theories),
            'by_status': by_status,
            'average_credibility': avg_credibility,
            'evolution_stats': self.stats.copy()
        }


# Example usage and testing
if __name__ == "__main__":
    print("="*80)
    print("INTERNAL THEORY FORMATION SYSTEM - DEMONSTRATION")
    print("="*80)
    
    # Initialize engine
    engine = TheoryEvolutionEngine()
    
    # Create competing theories about gravity
    print("\n[Scenario] Competing theories of gravitational attraction\n")
    
    # Theory 1: Newtonian gravity
    newton = Theory(
        theory_id="newton_gravity",
        name="Newtonian Gravity",
        domain="physics",
        description="Gravity is a force proportional to mass and inversely proportional to distance squared",
        assumptions=[
            "Mass attracts mass",
            "Force acts instantaneously across distance",
            "Space and time are absolute"
        ],
        causal_claims=[
            CausalClaim(
                cause="mass",
                effect="gravitational_force",
                strength=0.95,
                direction="positive",
                mechanism="Direct force proportional to product of masses"
            )
        ],
        evidence_for=[
            EvidenceItem(
                evidence_id="apple_fall",
                evidence_type=EvidenceType.OBSERVATION,
                description="Objects fall toward Earth",
                supports_theory=True,
                confidence=0.95,
                source="everyday_observation"
            ),
            EvidenceItem(
                evidence_id="planetary_orbits",
                evidence_type=EvidenceType.OBSERVATION,
                description="Planets orbit Sun in predictable paths",
                supports_theory=True,
                confidence=0.90,
                source="astronomical_data"
            )
        ],
        predictive_success=0.85,
        explanatory_power=0.80,
        simplicity_score=0.90
    )
    
    # Theory 2: Einstein's general relativity
    einstein = Theory(
        theory_id="einstein_gravity",
        name="General Relativity",
        domain="physics",
        description="Gravity is curvature of spacetime caused by mass-energy",
        assumptions=[
            "Spacetime is a 4-dimensional manifold",
            "Mass-energy curves spacetime",
            "Objects follow geodesics in curved spacetime"
        ],
        causal_claims=[
            CausalClaim(
                cause="mass_energy",
                effect="spacetime_curvature",
                strength=0.98,
                direction="positive",
                mechanism="Mass-energy tells spacetime how to curve"
            ),
            CausalClaim(
                cause="spacetime_curvature",
                effect="object_motion",
                strength=0.98,
                direction="positive",
                mechanism="Curved spacetime tells objects how to move"
            )
        ],
        evidence_for=[
            EvidenceItem(
                evidence_id="light_bending",
                evidence_type=EvidenceType.OBSERVATION,
                description="Starlight bends around Sun during eclipse",
                supports_theory=True,
                confidence=0.95,
                source="1919_eclipse_observation"
            ),
            EvidenceItem(
                evidence_id="mercury_precession",
                evidence_type=EvidenceType.OBSERVATION,
                description="Mercury's orbit precesses as predicted",
                supports_theory=True,
                confidence=0.92,
                source="astronomical_measurement"
            ),
            EvidenceItem(
                evidence_id="gravitational_waves",
                evidence_type=EvidenceType.EXPERIMENT,
                description="LIGO detected gravitational waves",
                supports_theory=True,
                confidence=0.98,
                source="LIGO_2015"
            )
        ],
        counterexamples=[
            Counterexample(
                description="Quantum mechanics incompatibility",
                severity=0.7,
                frequency="systematic",
                explained=False
            )
        ],
        predictive_success=0.95,
        explanatory_power=0.95,
        simplicity_score=0.60  # More complex than Newton
    )
    
    # Register theories
    engine.register_theory(newton)
    engine.register_theory(einstein)
    
    print(f"Registered theories:")
    print(f"  1. {newton.name}")
    print(f"  2. {einstein.name}")
    
    # Run competition
    print(f"\n[Competition] Running theory competition in physics domain...")
    winner = engine.run_competition("physics")
    
    if winner:
        print(f"\n🏆 Winner: {winner.name}")
        print(f"   Credibility: {winner.calculate_overall_credibility():.3f}")
        print(f"   Predictive success: {winner.predictive_success:.2f}")
        print(f"   Explanatory power: {winner.explanatory_power:.2f}")
    
    # Show ranking
    theories = engine.get_theories_for_domain("physics")
    print(f"\n[Ranking]")
    for i, theory in enumerate(theories, 1):
        credibility = theory.calculate_overall_credibility()
        print(f"  {i}. {theory.name}: credibility={credibility:.3f}, status={theory.status.value}")
    
    # Generate evolution report
    report = engine.get_evolution_report()
    print(f"\n[Evolution Report]")
    print(f"  Total theories: {report['total_theories']}")
    print(f"  Active theories: {report['active_theories']}")
    print(f"  Average credibility: {report['average_credibility']:.3f}")
    print(f"  Competitions run: {report['evolution_stats']['competitions_run']}")
    
    print(f"\n{'='*80}")
    print("✅ THEORY FORMATION SYSTEM OPERATIONAL")
    print(f"{'='*80}")
    print(f"\nTiannara can now:")
    print(f"  • Create explanatory world models (not just outputs)")
    print(f"  • Compete theories based on evidence and predictions")
    print(f"  • Merge compatible theories into unified explanations")
    print(f"  • Retire superseded theories")
    print(f"  • Evolve understanding over time through theory refinement")
    print(f"\nThis is structural intelligence - learning HOW to think.")
