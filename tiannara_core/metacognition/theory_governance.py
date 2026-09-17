"""
THEORY GOVERNANCE SYSTEM

Purpose: Provide governance infrastructure for synthesized cognition to prevent:
- Synthesis drift (concepts blur over repeated merges)
- Dominant perspective capture (one style dominates)
- Recursive hybrid explosion (fragment counts explode)
- False coherence (premature convergence)

Components:
1. Theory Objects - Structured representation of synthesized ideas
2. Theory Graveyard - Archive failed theories for future revival
3. Contradiction Persistence Engine - Track unresolved contradictions
4. Epistemic Integrity Tracker - Monitor traceability, provenance, uncertainty

Based on strategic analysis in synth.md (lines 200-381).
"""

import sys
import time
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Set
from dataclasses import dataclass, field
from enum import Enum

# Add project root to path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from tiannara_core.metacognition.theory_engine import (
    Theory,
    CausalClaim,
    EvidenceItem,
    EvidenceType,
    Prediction,
)


class TheoryStatus(Enum):
    """Lifecycle status of a theory."""
    ACTIVE = "active"                    # Currently in use
    ARCHIVED = "archived"                # Moved to graveyard
    REVIVED = "revived"                  # Brought back from graveyard
    DEPRECATED = "deprecated"            # Explicitly retired
    MERGED = "merged"                    # Incorporated into another theory


class ContradictionStatus(Enum):
    """Status of tracked contradictions."""
    ACTIVE = "active"                    # Currently unresolved
    RESOLVED = "resolved"                # Successfully resolved
    ACCEPTED = "accepted"                # Deliberately kept unresolved
    PENDING = "pending"                  # Under investigation


@dataclass
class TheoryMetadata:
    """Enhanced metadata for theory governance."""
    
    # Provenance tracking
    created_at: float = field(default_factory=time.time)
    last_modified: float = field(default_factory=time.time)
    contributing_agents: List[str] = field(default_factory=list)
    synthesis_session_id: Optional[str] = None
    
    # Evolution tracking
    parent_theories: List[str] = field(default_factory=list)  # Theories this was synthesized from
    child_theories: List[str] = field(default_factory=list)   # Theories derived from this one
    merge_count: int = 0                                      # How many times merged
    
    # Quality metrics
    confidence: float = 0.5
    predictive_power: float = 0.0
    survival_duration: float = 0.0  # Time since creation
    usage_count: int = 0
    
    # Status
    status: TheoryStatus = TheoryStatus.ACTIVE
    deprecation_reason: Optional[str] = None
    
    def update_last_modified(self):
        """Update last modified timestamp."""
        self.last_modified = time.time()
    
    def calculate_age(self) -> float:
        """Calculate theory age in seconds."""
        return time.time() - self.created_at


@dataclass
class TrackedContradiction:
    """A contradiction between theories or within a theory."""
    
    contradiction_id: str
    description: str
    theory_a_id: str
    theory_b_id: Optional[str] = None  # None if internal contradiction
    conflicting_claims: List[str] = field(default_factory=list)
    
    # Status tracking
    status: ContradictionStatus = ContradictionStatus.ACTIVE
    discovered_at: float = field(default_factory=time.time)
    resolved_at: Optional[float] = None
    resolution_method: Optional[str] = None
    
    # Severity and impact
    severity: float = 0.5  # 0.0-1.0, how severely it impacts coherence
    impact_description: Optional[str] = None
    
    # Resolution attempts
    resolution_attempts: int = 0
    last_attempt_at: Optional[float] = None
    
    def record_resolution_attempt(self, method: str):
        """Record an attempt to resolve this contradiction."""
        self.resolution_attempts += 1
        self.last_attempt_at = time.time()
    
    def resolve(self, method: str):
        """Mark contradiction as resolved."""
        self.status = ContradictionStatus.RESOLVED
        self.resolved_at = time.time()
        self.resolution_method = method
    
    def accept_as_unresolved(self, reason: str):
        """Deliberately keep contradiction unresolved."""
        self.status = ContradictionStatus.ACCEPTED
        self.impact_description = reason


@dataclass
class EpistemicIntegrityReport:
    """Report on epistemic integrity of a theory or system."""
    
    # Traceability
    full_provenance_chain: bool = True
    all_contributors_tracked: bool = True
    
    # Contradiction tracking
    active_contradictions: int = 0
    accepted_contradictions: int = 0
    unresolved_severe_contradictions: int = 0
    
    # Uncertainty preservation
    uncertainty_documented: bool = True
    confidence_calibrated: bool = True
    
    # Reversibility
    synthesis_reversible: bool = True
    parent_theories_preserved: bool = True
    
    # Overall score
    integrity_score: float = 1.0  # 0.0-1.0
    
    issues: List[str] = field(default_factory=list)
    
    def add_issue(self, issue: str):
        """Add an integrity issue."""
        self.issues.append(issue)
        self.integrity_score = max(0.0, self.integrity_score - 0.1)


class TheoryGraveyard:
    """
    Archive for failed/deprecated theories.
    
    Rationale (from synth.md):
    "Do NOT delete failed theories. Archive them.
    Future contexts may revive previously failed ideas.
    Human science works this way too."
    """
    
    def __init__(self):
        self.graveyard: Dict[str, Theory] = {}
        self.archival_metadata: Dict[str, Dict] = {}
    
    def archive_theory(
        self,
        theory: Theory,
        reason: str,
        archived_by: Optional[str] = None
    ) -> str:
        """
        Archive a theory to the graveyard.
        
        Args:
            theory: Theory to archive
            reason: Why it's being archived
            archived_by: Who/what archived it
            
        Returns:
            Archive ID
        """
        archive_id = f"graveyard_{theory.theory_id}_{int(time.time())}"
        
        # Store theory
        self.graveyard[archive_id] = theory
        
        # Store metadata
        self.archival_metadata[archive_id] = {
            'original_id': theory.theory_id,
            'theory_name': theory.name,
            'domain': theory.domain,
            'archived_at': time.time(),
            'reason': reason,
            'archived_by': archived_by,
            'final_confidence': theory.calculate_overall_credibility(),
            'evidence_count': len(theory.evidence_for),
            'contradiction_count': len(theory.counterexamples),
        }
        
        print(f"[GRAVEYARD] Archived theory '{theory.name}' (ID: {archive_id})")
        print(f"  Reason: {reason}")
        print(f"  Final confidence: {self.archival_metadata[archive_id]['final_confidence']:.3f}")
        
        return archive_id
    
    def revive_theory(self, archive_id: str, new_context: str) -> Optional[Theory]:
        """
        Revive a theory from the graveyard.
        
        Args:
            archive_id: Archive ID of theory to revive
            new_context: Why it's being revived
            
        Returns:
            Revived theory or None if not found
        """
        if archive_id not in self.graveyard:
            print(f"[GRAVEYARD] Warning: Archive ID {archive_id} not found")
            return None
        
        theory = self.graveyard[archive_id]
        metadata = self.archival_metadata[archive_id]
        
        print(f"[GRAVEYARD] Reviving theory '{theory.name}' from archive")
        print(f"  Original context: {metadata['reason']}")
        print(f"  New context: {new_context}")
        
        # Update theory status
        theory.description += f"\n\n[REVIVED] Previously archived: {metadata['reason']}. Revived for: {new_context}"
        
        return theory
    
    def search_graveyard(
        self,
        domain: Optional[str] = None,
        min_confidence: float = 0.0,
        keyword: Optional[str] = None
    ) -> List[Tuple[str, Theory]]:
        """
        Search archived theories.
        
        Args:
            domain: Filter by domain
            min_confidence: Minimum final confidence
            keyword: Search in theory name/description
            
        Returns:
            List of (archive_id, theory) tuples
        """
        results = []
        
        for archive_id, theory in self.graveyard.items():
            metadata = self.archival_metadata[archive_id]
            
            # Apply filters
            if domain and metadata['domain'] != domain:
                continue
            
            if metadata['final_confidence'] < min_confidence:
                continue
            
            if keyword:
                keyword_lower = keyword.lower()
                if (keyword_lower not in theory.name.lower() and
                    keyword_lower not in theory.description.lower()):
                    continue
            
            results.append((archive_id, theory))
        
        return results
    
    def get_statistics(self) -> Dict:
        """Get graveyard statistics."""
        if not self.graveyard:
            return {
                'total_archived': 0,
                'by_domain': {},
                'avg_confidence': 0.0,
            }
        
        # Count by domain
        domain_counts = {}
        total_confidence = 0.0
        
        for archive_id, theory in self.graveyard.items():
            metadata = self.archival_metadata[archive_id]
            domain = metadata['domain']
            domain_counts[domain] = domain_counts.get(domain, 0) + 1
            total_confidence += metadata['final_confidence']
        
        return {
            'total_archived': len(self.graveyard),
            'by_domain': domain_counts,
            'avg_confidence': total_confidence / len(self.graveyard),
        }


class ContradictionPersistenceEngine:
    """
    Engine for tracking and managing contradictions.
    
    Rationale (from synth.md):
    "Do not force all contradictions to resolve.
    Some contradictions should remain: active, tracked, unresolved.
    This prevents premature convergence.
    One of the biggest problems in intelligence systems is: false coherence"
    """
    
    def __init__(self):
        self.contradictions: Dict[str, TrackedContradiction] = {}
        self.contradiction_counter = 0
    
    def register_contradiction(
        self,
        description: str,
        theory_a_id: str,
        theory_b_id: Optional[str] = None,
        conflicting_claims: List[str] = None,
        severity: float = 0.5
    ) -> str:
        """
        Register a new contradiction.
        
        Args:
            description: Description of the contradiction
            theory_a_id: First theory involved
            theory_b_id: Second theory (optional for internal contradictions)
            conflicting_claims: Specific claims that conflict
            severity: Severity level (0.0-1.0)
            
        Returns:
            Contradiction ID
        """
        self.contradiction_counter += 1
        contradiction_id = f"contradiction_{self.contradiction_counter}"
        
        contradiction = TrackedContradiction(
            contradiction_id=contradiction_id,
            description=description,
            theory_a_id=theory_a_id,
            theory_b_id=theory_b_id,
            conflicting_claims=conflicting_claims or [],
            severity=severity
        )
        
        self.contradictions[contradiction_id] = contradiction
        
        print(f"[CONTRADICTION] Registered: {description[:80]}...")
        print(f"  ID: {contradiction_id}")
        print(f"  Severity: {severity:.2f}")
        
        return contradiction_id
    
    def attempt_resolution(
        self,
        contradiction_id: str,
        resolution_method: str
    ) -> bool:
        """
        Attempt to resolve a contradiction.
        
        Args:
            contradiction_id: ID of contradiction to resolve
            resolution_method: Method used for resolution
            
        Returns:
            True if resolution successful
        """
        if contradiction_id not in self.contradictions:
            print(f"[CONTRADICTION] Warning: ID {contradiction_id} not found")
            return False
        
        contradiction = self.contradictions[contradiction_id]
        contradiction.record_resolution_attempt(resolution_method)
        
        # Simulate resolution success (in real implementation, this would involve actual reasoning)
        # Higher severity contradictions are harder to resolve
        success_probability = max(0.1, 1.0 - contradiction.severity * 0.7)
        import random
        success = random.random() < success_probability
        
        if success:
            contradiction.resolve(resolution_method)
            print(f"[CONTRADICTION] Resolved: {contradiction.description[:60]}...")
            print(f"  Method: {resolution_method}")
        else:
            print(f"[CONTRADICTION] Resolution attempt failed: {contradiction.description[:60]}...")
            print(f"  Attempts so far: {contradiction.resolution_attempts}")
        
        return success
    
    def accept_unresolved(
        self,
        contradiction_id: str,
        reason: str
    ):
        """
        Deliberately accept a contradiction as unresolved.
        
        Args:
            contradiction_id: ID of contradiction
            reason: Why it's being kept unresolved
        """
        if contradiction_id not in self.contradictions:
            print(f"[CONTRADICTION] Warning: ID {contradiction_id} not found")
            return
        
        contradiction = self.contradictions[contradiction_id]
        contradiction.accept_as_unresolved(reason)
        
        print(f"[CONTRADICTION] Accepted as unresolved: {contradiction.description[:60]}...")
        print(f"  Reason: {reason}")
    
    def get_active_contradictions(self) -> List[TrackedContradiction]:
        """Get all active (unresolved) contradictions."""
        return [
            c for c in self.contradictions.values()
            if c.status == ContradictionStatus.ACTIVE
        ]
    
    def get_severe_unresolved(self, threshold: float = 0.7) -> List[TrackedContradiction]:
        """Get severe contradictions that remain unresolved."""
        return [
            c for c in self.contradictions.values()
            if c.status == ContradictionStatus.ACTIVE and c.severity >= threshold
        ]
    
    def get_statistics(self) -> Dict:
        """Get contradiction statistics."""
        stats = {
            'total': len(self.contradictions),
            'active': 0,
            'resolved': 0,
            'accepted': 0,
            'avg_severity': 0.0,
        }
        
        if not self.contradictions:
            return stats
        
        total_severity = 0.0
        
        for contradiction in self.contradictions.values():
            if contradiction.status == ContradictionStatus.ACTIVE:
                stats['active'] += 1
            elif contradiction.status == ContradictionStatus.RESOLVED:
                stats['resolved'] += 1
            elif contradiction.status == ContradictionStatus.ACCEPTED:
                stats['accepted'] += 1
            
            total_severity += contradiction.severity
        
        stats['avg_severity'] = total_severity / len(self.contradictions)
        
        return stats


class EpistemicIntegrityTracker:
    """
    Tracker for epistemic integrity metrics.
    
    Monitors:
    - Traceability (full provenance chains)
    - Contradiction tracking
    - Uncertainty preservation
    - Reversibility of synthesis
    """
    
    def __init__(self):
        self.theory_metadata: Dict[str, TheoryMetadata] = {}
        self.integrity_reports: List[EpistemicIntegrityReport] = []
    
    def register_theory(
        self,
        theory: Theory,
        contributing_agents: List[str] = None,
        synthesis_session_id: Optional[str] = None,
        parent_theories: List[str] = None
    ):
        """Register a theory for integrity tracking."""
        metadata = TheoryMetadata(
            contributing_agents=contributing_agents or [],
            synthesis_session_id=synthesis_session_id,
            parent_theories=parent_theories or []
        )
        
        self.theory_metadata[theory.theory_id] = metadata
        
        print(f"[INTEGRITY] Registered theory: {theory.name}")
        print(f"  Contributors: {len(metadata.contributing_agents)}")
        print(f"  Parents: {len(metadata.parent_theories)}")
    
    def assess_integrity(self, theory: Theory) -> EpistemicIntegrityReport:
        """
        Assess epistemic integrity of a theory.
        
        Args:
            theory: Theory to assess
            
        Returns:
            Integrity report
        """
        report = EpistemicIntegrityReport()
        
        # Check provenance
        if theory.theory_id not in self.theory_metadata:
            report.add_issue("Theory not registered in integrity tracker")
            report.full_provenance_chain = False
        else:
            metadata = self.theory_metadata[theory.theory_id]
            
            # Check contributor tracking
            if not metadata.contributing_agents:
                report.add_issue("No contributing agents tracked")
                report.all_contributors_tracked = False
            
            # Check parent preservation
            if metadata.parent_theories and not metadata.parent_theories:
                report.add_issue("Parent theories not preserved")
                report.parent_theories_preserved = False
        
        # Check uncertainty documentation
        credibility = theory.calculate_overall_credibility()
        if credibility <= 0.0 or credibility >= 1.0:
            report.add_issue("Credibility not properly calibrated (should be 0.0-1.0 exclusive)")
            report.confidence_calibrated = False
        
        # Check evidence base
        if len(theory.evidence_for) == 0:
            report.add_issue("No supporting evidence documented")
        
        # Calculate overall score
        issue_count = len(report.issues)
        report.integrity_score = max(0.0, 1.0 - issue_count * 0.15)
        
        # Store report
        self.integrity_reports.append(report)
        
        return report
    
    def get_system_integrity_summary(self) -> Dict:
        """Get summary of system-wide epistemic integrity."""
        if not self.integrity_reports:
            return {
                'total_assessments': 0,
                'avg_integrity_score': 0.0,
                'common_issues': [],
            }
        
        # Calculate average integrity
        avg_score = sum(r.integrity_score for r in self.integrity_reports) / len(self.integrity_reports)
        
        # Find common issues
        issue_counts = {}
        for report in self.integrity_reports:
            for issue in report.issues:
                issue_counts[issue] = issue_counts.get(issue, 0) + 1
        
        common_issues = sorted(issue_counts.items(), key=lambda x: x[1], reverse=True)[:5]
        
        return {
            'total_assessments': len(self.integrity_reports),
            'avg_integrity_score': avg_score,
            'common_issues': common_issues,
        }


class TheoryGovernanceSystem:
    """
    Complete theory governance system.
    
    Integrates:
    - Theory lifecycle management
    - Theory graveyard
    - Contradiction persistence
    - Epistemic integrity tracking
    """
    
    def __init__(self):
        self.graveyard = TheoryGraveyard()
        self.contradiction_engine = ContradictionPersistenceEngine()
        self.integrity_tracker = EpistemicIntegrityTracker()
        
        self.active_theories: Dict[str, Theory] = {}
    
    def register_synthesized_theory(
        self,
        theory: Theory,
        contributing_agents: List[str],
        synthesis_session_id: str,
        parent_theories: List[str] = None
    ):
        """Register a newly synthesized theory."""
        self.active_theories[theory.theory_id] = theory
        
        # Register for integrity tracking
        self.integrity_tracker.register_theory(
            theory=theory,
            contributing_agents=contributing_agents,
            synthesis_session_id=synthesis_session_id,
            parent_theories=parent_theories or []
        )
        
        print(f"[GOVERNANCE] Registered synthesized theory: {theory.name}")
        print(f"  ID: {theory.theory_id}")
        print(f"  Contributors: {', '.join(contributing_agents)}")
    
    def detect_and_register_contradiction(
        self,
        theory_a: Theory,
        theory_b: Theory,
        description: str,
        conflicting_claims: List[str] = None,
        severity: float = 0.5
    ) -> str:
        """Detect and register contradiction between two theories."""
        return self.contradiction_engine.register_contradiction(
            description=description,
            theory_a_id=theory_a.theory_id,
            theory_b_id=theory_b.theory_id,
            conflicting_claims=conflicting_claims,
            severity=severity
        )
    
    def archive_theory(self, theory_id: str, reason: str) -> bool:
        """Archive a theory to the graveyard."""
        if theory_id not in self.active_theories:
            print(f"[GOVERNANCE] Warning: Theory {theory_id} not found")
            return False
        
        theory = self.active_theories[theory_id]
        
        # Archive to graveyard
        self.graveyard.archive_theory(
            theory=theory,
            reason=reason,
            archived_by="governance_system"
        )
        
        # Update status
        theory.description += f"\n\n[ARCHIVED] {reason}"
        
        # Remove from active
        del self.active_theories[theory_id]
        
        return True
    
    def assess_theory_integrity(self, theory_id: str) -> EpistemicIntegrityReport:
        """Assess integrity of a specific theory."""
        if theory_id not in self.active_theories:
            print(f"[GOVERNANCE] Warning: Theory {theory_id} not found")
            return EpistemicIntegrityReport()
        
        theory = self.active_theories[theory_id]
        return self.integrity_tracker.assess_integrity(theory)
    
    def get_governance_report(self) -> Dict:
        """Generate comprehensive governance report."""
        return {
            'active_theories': len(self.active_theories),
            'graveyard_stats': self.graveyard.get_statistics(),
            'contradiction_stats': self.contradiction_engine.get_statistics(),
            'integrity_summary': self.integrity_tracker.get_system_integrity_summary(),
            'severe_unresolved_contradictions': len(
                self.contradiction_engine.get_severe_unresolved()
            ),
        }


def main():
    """Demonstrate theory governance system."""
    print("="*80)
    print("THEORY GOVERNANCE SYSTEM DEMONSTRATION")
    print("="*80)
    
    governance = TheoryGovernanceSystem()
    
    # Create sample theories
    from tiannara_core.metacognition.theory_engine import Theory, CausalClaim, EvidenceItem, EvidenceType
    
    theory1 = Theory(
        theory_id="theory_energy_storage",
        name="Advanced Energy Storage Theory",
        domain="energy",
        description="Novel approach to grid-scale energy storage using hybrid systems",
        assumptions=["Battery costs will continue to decline", "Grid demand is predictable"],
        causal_claims=[
            CausalClaim(
                cause="Increased battery capacity",
                effect="Reduced grid instability",
                strength=0.8
            )
        ],
        evidence_for=[
            EvidenceItem(
                evidence_id="evid_001",
                evidence_type=EvidenceType.EXPERIMENT,
                description="Pilot study showing 40% improvement",
                supports_theory=True,
                confidence=0.85,
                source="Field trial 2025"
            )
        ]
    )
    
    theory2 = Theory(
        theory_id="theory_demand_response",
        name="Dynamic Demand Response Theory",
        domain="energy",
        description="Real-time demand adjustment through smart pricing",
        assumptions=["Consumers respond to price signals", "Smart meters are ubiquitous"],
        causal_claims=[
            CausalClaim(
                cause="Dynamic pricing",
                effect="Peak load reduction",
                strength=0.7
            )
        ],
        evidence_for=[
            EvidenceItem(
                evidence_id="evid_002",
                evidence_type=EvidenceType.STATISTICAL_CORRELATION,
                description="Correlation between pricing and consumption",
                supports_theory=True,
                confidence=0.75,
                source="Market analysis 2025"
            )
        ]
    )
    
    print("\n" + "="*80)
    print("PHASE 1: Registering Synthesized Theories")
    print("="*80 + "\n")
    
    # Register theories
    governance.register_synthesized_theory(
        theory=theory1,
        contributing_agents=["Analytical", "Creative"],
        synthesis_session_id="session_001",
        parent_theories=[]
    )
    
    governance.register_synthesized_theory(
        theory=theory2,
        contributing_agents=["Conservative", "Optimizer"],
        synthesis_session_id="session_002",
        parent_theories=[]
    )
    
    print("\n" + "="*80)
    print("PHASE 2: Detecting Contradictions")
    print("="*80 + "\n")
    
    # Register contradiction
    governance.detect_and_register_contradiction(
        theory_a=theory1,
        theory_b=theory2,
        description="Storage theory assumes predictable demand, but demand response theory assumes variable demand",
        conflicting_claims=[
            "Grid demand is predictable (storage theory)",
            "Demand varies significantly and can be influenced (demand response)"
        ],
        severity=0.6
    )
    
    print("\n" + "="*80)
    print("PHASE 3: Attempting Contradiction Resolution")
    print("="*80 + "\n")
    
    # Get active contradictions
    active = governance.contradiction_engine.get_active_contradictions()
    for contradiction in active:
        print(f"Attempting resolution for: {contradiction.description[:60]}...")
        governance.contradiction_engine.attempt_resolution(
            contradiction_id=contradiction.contradiction_id,
            resolution_method="Hybrid model combining both approaches"
        )
    
    print("\n" + "="*80)
    print("PHASE 4: Assessing Epistemic Integrity")
    print("="*80 + "\n")
    
    # Assess integrity
    report1 = governance.assess_theory_integrity("theory_energy_storage")
    print(f"\nTheory 1 Integrity Score: {report1.integrity_score:.2f}")
    if report1.issues:
        print("Issues found:")
        for issue in report1.issues:
            print(f"  - {issue}")
    
    report2 = governance.assess_theory_integrity("theory_demand_response")
    print(f"\nTheory 2 Integrity Score: {report2.integrity_score:.2f}")
    if report2.issues:
        print("Issues found:")
        for issue in report2.issues:
            print(f"  - {issue}")
    
    print("\n" + "="*80)
    print("PHASE 5: Archiving Theory (Simulating Failure)")
    print("="*80 + "\n")
    
    # Archive a theory
    governance.archive_theory(
        theory_id="theory_demand_response",
        reason="Insufficient empirical validation in diverse market conditions"
    )
    
    print("\n" + "="*80)
    print("PHASE 6: Searching Graveyard")
    print("="*80 + "\n")
    
    # Search graveyard
    results = governance.graveyard.search_graveyard(domain="energy")
    print(f"Found {len(results)} archived theories in energy domain")
    
    for archive_id, theory in results:
        print(f"  - {theory.name} (archived: {governance.graveyard.archival_metadata[archive_id]['reason'][:50]}...)")
    
    print("\n" + "="*80)
    print("PHASE 7: Generating Governance Report")
    print("="*80 + "\n")
    
    # Generate report
    report = governance.get_governance_report()
    
    print(f"Active Theories: {report['active_theories']}")
    print(f"\nGraveyard Statistics:")
    print(f"  Total Archived: {report['graveyard_stats']['total_archived']}")
    print(f"  By Domain: {report['graveyard_stats']['by_domain']}")
    print(f"  Avg Confidence: {report['graveyard_stats']['avg_confidence']:.2f}")
    
    print(f"\nContradiction Statistics:")
    print(f"  Total: {report['contradiction_stats']['total']}")
    print(f"  Active: {report['contradiction_stats']['active']}")
    print(f"  Resolved: {report['contradiction_stats']['resolved']}")
    print(f"  Accepted: {report['contradiction_stats']['accepted']}")
    print(f"  Avg Severity: {report['contradiction_stats']['avg_severity']:.2f}")
    
    print(f"\nIntegrity Summary:")
    print(f"  Total Assessments: {report['integrity_summary']['total_assessments']}")
    print(f"  Avg Integrity Score: {report['integrity_summary']['avg_integrity_score']:.2f}")
    print(f"  Common Issues: {len(report['integrity_summary']['common_issues'])}")
    
    print(f"\nSevere Unresolved Contradictions: {report['severe_unresolved_contradictions']}")
    
    print("\n" + "="*80)
    print("✅ THEORY GOVERNANCE SYSTEM OPERATIONAL")
    print("="*80)
    
    return 0


if __name__ == "__main__":
    exit(main())
