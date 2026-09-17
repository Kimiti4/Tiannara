"""
CONSTITUTIONAL EVOLUTION FRAMEWORK

Purpose: Safe self-modification with rollback, verification, and alignment preservation.

Based on next.md (lines 320-351):
"Do NOT allow unrestricted self-modification yet.
You passed self-improvement safety but that was controlled.
Now you need constitutional evolution.

Self-modification rules - Every modification should require:
- Causal justification (prevents arbitrary mutation)
- Rollback path (enables recovery)
- Sandbox testing (isolates dangerous changes)
- Alignment verification (checks principle preservation)
- Performance delta (validates usefulness)
- Stability delta (ensures coherence maintained)"

Architecture:
Implements a constitutional framework where all self-modifications must pass
multiple safety gates before deployment. Prevents catastrophic mutations while
enabling beneficial evolution.
"""

import time
import json
import copy
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any, Callable
from dataclasses import dataclass, field
from enum import Enum


class ModificationType(Enum):
    """Types of self-modifications."""
    PARAMETER_TUNING = "parameter_tuning"           # Adjust hyperparameters
    ARCHITECTURE_CHANGE = "architecture_change"     # Modify structure
    RULE_ADDITION = "rule_addition"                 # Add new rules/constraints
    RULE_MODIFICATION = "rule_modification"         # Change existing rules
    STRATEGY_UPDATE = "strategy_update"             # Update reasoning strategies
    MEMORY_RESTRUCTURE = "memory_restructure"       # Reorganize memory systems
    AGENT_BEHAVIOR = "agent_behavior"               # Modify agent behaviors
    CONSTITUTION_AMENDMENT = "constitution_amendment"  # Change core principles


class SafetyGateStatus(Enum):
    """Status of safety gate evaluation."""
    PASSED = "passed"
    FAILED = "failed"
    WARNING = "warning"
    PENDING = "pending"


@dataclass
class ModificationProposal:
    """A proposed self-modification with full metadata."""
    proposal_id: str
    modification_type: ModificationType
    description: str
    
    # What changes
    current_state: Dict[str, Any] = field(default_factory=dict)
    proposed_state: Dict[str, Any] = field(default_factory=dict)
    
    # Justification
    causal_justification: str = ""                  # Why this change is needed
    expected_benefits: List[str] = field(default_factory=list)
    potential_risks: List[str] = field(default_factory=list)
    
    # Metadata
    timestamp: float = field(default_factory=time.time)
    proposer_id: Optional[str] = None               # Who/what proposed this
    priority: float = 0.5                           # 0.0-1.0, how urgent?
    
    # Testing results (filled during evaluation)
    sandbox_test_results: Optional[Dict] = None
    performance_delta: Optional[float] = None
    stability_delta: Optional[float] = None
    alignment_score: Optional[float] = None
    
    # Approval status
    approved: bool = False
    approval_timestamp: Optional[float] = None
    approver_ids: List[str] = field(default_factory=list)
    
    # Deployment
    deployed: bool = False
    deployment_timestamp: Optional[float] = None
    rollback_available: bool = True


@dataclass
class SafetyGateResult:
    """Result from a single safety gate evaluation."""
    gate_name: str
    status: SafetyGateStatus
    score: float                                    # 0.0-1.0
    details: str
    warnings: List[str] = field(default_factory=list)
    blockers: List[str] = field(default_factory=list)


@dataclass
class ConstitutionPrinciple:
    """Core immutable principle that must be preserved."""
    principle_id: str
    name: str
    description: str
    category: str                                   # "safety", "alignment", "ethics", etc.
    
    # Immutable - cannot be violated by any modification
    is_immutable: bool = True
    
    # Verification function (returns True if principle is satisfied)
    verification_function: Optional[Callable] = None
    
    # Priority (higher = more critical to preserve)
    priority: float = 1.0


class ConstitutionalEvolution:
    """
    Manages safe self-modification through constitutional framework.
    
    All modifications must pass 6 safety gates:
    1. Causal Justification Gate
    2. Rollback Path Gate
    3. Sandbox Testing Gate
    4. Alignment Verification Gate
    5. Performance Delta Gate
    6. Stability Delta Gate
    """
    
    def __init__(self, constitution_path: Optional[str] = None):
        self.constitution_path = constitution_path or "runs/constitution.json"
        
        # Core constitution (immutable principles)
        self.constitution: List[ConstitutionPrinciple] = []
        
        # Modification history
        self.proposals: Dict[str, ModificationProposal] = {}
        self.approved_modifications: List[str] = []
        self.rejected_proposals: List[str] = []
        self.deployed_modifications: List[str] = []
        
        # Rollback stack (for undoing modifications)
        self.rollback_stack: List[Dict] = []
        
        # Current system state snapshot (for comparison)
        self.current_state_snapshot: Dict = {}
        
        # Initialize default constitution
        self._initialize_constitution()
    
    def _initialize_constitution(self):
        """Initialize core constitutional principles."""
        
        # Principle 1: Truth-seeking must be preserved
        self.constitution.append(ConstitutionPrinciple(
            principle_id="PRINC_001",
            name="Truth-Seeking Preservation",
            description="System must maintain commitment to truth over reward optimization",
            category="alignment",
            is_immutable=True,
            priority=1.0
        ))
        
        # Principle 2: No deception for reward
        self.constitution.append(ConstitutionPrinciple(
            principle_id="PRINC_002",
            name="Anti-Deception",
            description="System must not deceive users or hide true capabilities/intentions",
            category="ethics",
            is_immutable=True,
            priority=1.0
        ))
        
        # Principle 3: Preserve interpretability
        self.constitution.append(ConstitutionPrinciple(
            principle_id="PRINC_003",
            name="Interpretability Preservation",
            description="System reasoning must remain interpretable and auditable",
            category="safety",
            is_immutable=True,
            priority=0.95
        ))
        
        # Principle 4: Respect human autonomy
        self.constitution.append(ConstitutionPrinciple(
            principle_id="PRINC_004",
            name="Human Autonomy Respect",
            description="System must not manipulate or coerce human decision-making",
            category="ethics",
            is_immutable=True,
            priority=1.0
        ))
        
        # Principle 5: Maintain epistemic humility
        self.constitution.append(ConstitutionPrinciple(
            principle_id="PRINC_005",
            name="Epistemic Humility",
            description="System must acknowledge uncertainty and knowledge limitations",
            category="alignment",
            is_immutable=True,
            priority=0.9
        ))
        
        # Principle 6: Preserve failure learning
        self.constitution.append(ConstitutionPrinciple(
            principle_id="PRINC_006",
            name="Failure Learning Preservation",
            description="System must retain and learn from past failures",
            category="safety",
            is_immutable=True,
            priority=0.85
        ))
        
        # Save constitution
        self._save_constitution()
    
    def propose_modification(
        self,
        modification_type: ModificationType,
        description: str,
        current_state: Dict,
        proposed_state: Dict,
        causal_justification: str,
        expected_benefits: List[str],
        potential_risks: List[str],
        proposer_id: Optional[str] = None,
        priority: float = 0.5
    ) -> str:
        """
        Submit a modification proposal for evaluation.
        
        Returns:
            proposal_id for tracking
        """
        import uuid
        
        proposal_id = f"MOD_{uuid.uuid4().hex[:8]}"
        
        proposal = ModificationProposal(
            proposal_id=proposal_id,
            modification_type=modification_type,
            description=description,
            current_state=current_state,
            proposed_state=proposed_state,
            causal_justification=causal_justification,
            expected_benefits=expected_benefits,
            potential_risks=potential_risks,
            proposer_id=proposer_id,
            priority=priority
        )
        
        self.proposals[proposal_id] = proposal
        
        print(f"[Constitutional Evolution] New proposal: {proposal_id}")
        print(f"  Type: {modification_type.value}")
        print(f"  Description: {description}")
        print(f"  Priority: {priority:.2f}")
        
        return proposal_id
    
    def evaluate_proposal(self, proposal_id: str) -> Dict[str, Any]:
        """
        Evaluate a modification proposal through all 6 safety gates.
        
        Returns:
            Evaluation results with pass/fail status
        """
        if proposal_id not in self.proposals:
            raise ValueError(f"Unknown proposal: {proposal_id}")
        
        proposal = self.proposals[proposal_id]
        
        print(f"\n{'='*80}")
        print(f"EVALUATING PROPOSAL: {proposal_id}")
        print(f"{'='*80}\n")
        
        # Run all 6 safety gates
        gate_results = []
        
        # Gate 1: Causal Justification
        gate_results.append(self._gate_causal_justification(proposal))
        
        # Gate 2: Rollback Path
        gate_results.append(self._gate_rollback_path(proposal))
        
        # Gate 3: Sandbox Testing
        gate_results.append(self._gate_sandbox_testing(proposal))
        
        # Gate 4: Alignment Verification
        gate_results.append(self._gate_alignment_verification(proposal))
        
        # Gate 5: Performance Delta
        gate_results.append(self._gate_performance_delta(proposal))
        
        # Gate 6: Stability Delta
        gate_results.append(self._gate_stability_delta(proposal))
        
        # Determine overall approval
        all_passed = all(r.status == SafetyGateStatus.PASSED for r in gate_results)
        has_blockers = any(len(r.blockers) > 0 for r in gate_results)
        
        if all_passed and not has_blockers:
            proposal.approved = True
            proposal.approval_timestamp = time.time()
            self.approved_modifications.append(proposal_id)
            status = "APPROVED"
        else:
            self.rejected_proposals.append(proposal_id)
            status = "REJECTED"
        
        # Generate summary
        summary = {
            "proposal_id": proposal_id,
            "status": status,
            "gates_evaluated": len(gate_results),
            "gates_passed": sum(1 for r in gate_results if r.status == SafetyGateStatus.PASSED),
            "gate_results": [
                {
                    "gate": r.gate_name,
                    "status": r.status.value,
                    "score": r.score,
                    "details": r.details,
                    "warnings": r.warnings,
                    "blockers": r.blockers
                }
                for r in gate_results
            ],
            "recommendation": "DEPLOY" if status == "APPROVED" else "REJECT"
        }
        
        # Print summary
        self._print_evaluation_summary(summary, gate_results)
        
        return summary
    
    def _gate_causal_justification(self, proposal: ModificationProposal) -> SafetyGateResult:
        """
        Gate 1: Verify causal justification exists and is sound.
        
        Prevents arbitrary mutations without clear reasoning.
        """
        blockers = []
        warnings = []
        
        # Check if justification provided
        if not proposal.causal_justification or len(proposal.causal_justification) < 20:
            blockers.append("Causal justification too brief or missing")
        
        # Check if benefits are specific
        if len(proposal.expected_benefits) == 0:
            blockers.append("No expected benefits identified")
        elif len(proposal.expected_benefits) < 2:
            warnings.append("Consider identifying more specific benefits")
        
        # Check if risks are acknowledged
        if len(proposal.potential_risks) == 0:
            warnings.append("No potential risks identified - consider thorough risk analysis")
        
        # Calculate score
        score = 1.0
        if len(blockers) > 0:
            score = 0.0
        elif len(warnings) > 0:
            score = 0.7
        
        status = SafetyGateStatus.FAILED if len(blockers) > 0 else \
                 SafetyGateStatus.WARNING if len(warnings) > 0 else \
                 SafetyGateStatus.PASSED
        
        return SafetyGateResult(
            gate_name="Causal Justification",
            status=status,
            score=score,
            details=f"Justification length: {len(proposal.causal_justification)} chars, "
                   f"Benefits: {len(proposal.expected_benefits)}, "
                   f"Risks: {len(proposal.potential_risks)}",
            warnings=warnings,
            blockers=blockers
        )
    
    def _gate_rollback_path(self, proposal: ModificationProposal) -> SafetyGateResult:
        """
        Gate 2: Verify rollback path exists and is viable.
        
        Ensures we can recover if modification causes problems.
        """
        blockers = []
        warnings = []
        
        # Check if rollback is marked as available
        if not proposal.rollback_available:
            blockers.append("Rollback not available - modification is irreversible")
        
        # Check if current state is saved
        if not proposal.current_state:
            blockers.append("Current state not captured - cannot rollback")
        
        # Verify rollback mechanism exists
        # (In real implementation, would test actual rollback capability)
        rollback_feasible = len(proposal.current_state) > 0
        
        if not rollback_feasible:
            blockers.append("Rollback mechanism not feasible")
        
        # Calculate score
        score = 1.0 if rollback_feasible and proposal.rollback_available else 0.0
        
        status = SafetyGateStatus.FAILED if len(blockers) > 0 else SafetyGateStatus.PASSED
        
        # Save state for potential rollback
        if rollback_feasible:
            self.rollback_stack.append({
                "proposal_id": proposal.proposal_id,
                "state_snapshot": copy.deepcopy(proposal.current_state),
                "timestamp": time.time()
            })
        
        return SafetyGateResult(
            gate_name="Rollback Path",
            status=status,
            score=score,
            details=f"Rollback available: {proposal.rollback_available}, "
                   f"State captured: {len(proposal.current_state)} keys",
            warnings=warnings,
            blockers=blockers
        )
    
    def _gate_sandbox_testing(self, proposal: ModificationProposal) -> SafetyGateResult:
        """
        Gate 3: Verify modification passes sandbox testing.
        
        Tests modification in isolated environment before deployment.
        """
        blockers = []
        warnings = []
        
        # Simulate sandbox testing
        # In real implementation, would run actual tests in isolated environment
        sandbox_passed = self._simulate_sandbox_test(proposal)
        
        if not sandbox_passed:
            blockers.append("Sandbox testing failed - modification unsafe")
        
        # Record test results
        proposal.sandbox_test_results = {
            "tests_run": 10,
            "tests_passed": 10 if sandbox_passed else 5,
            "critical_failures": 0 if sandbox_passed else 2,
            "test_duration_seconds": 5.2
        }
        
        # Calculate score
        score = 1.0 if sandbox_passed else 0.0
        
        status = SafetyGateStatus.FAILED if len(blockers) > 0 else SafetyGateStatus.PASSED
        
        return SafetyGateResult(
            gate_name="Sandbox Testing",
            status=status,
            score=score,
            details=f"Sandbox tests: {proposal.sandbox_test_results['tests_passed']}/"
                   f"{proposal.sandbox_test_results['tests_run']} passed",
            warnings=warnings,
            blockers=blockers
        )
    
    def _gate_alignment_verification(self, proposal: ModificationProposal) -> SafetyGateResult:
        """
        Gate 4: Verify modification preserves constitutional alignment.
        
        Checks that no core principles are violated.
        """
        blockers = []
        warnings = []
        
        # Check against each constitutional principle
        violations = []
        for principle in self.constitution:
            # Simulate verification (in real implementation, would run actual checks)
            principle_preserved = self._verify_principle_preservation(principle, proposal)
            
            if not principle_preserved:
                violations.append(principle.name)
                if principle.is_immutable:
                    blockers.append(f"Violates immutable principle: {principle.name}")
                else:
                    warnings.append(f"May weaken principle: {principle.name}")
        
        # Calculate alignment score
        total_principles = len(self.constitution)
        preserved_principles = total_principles - len(violations)
        alignment_score = preserved_principles / max(total_principles, 1)
        
        proposal.alignment_score = alignment_score
        
        # Calculate gate score
        score = alignment_score
        if len(blockers) > 0:
            score = 0.0
        elif len(warnings) > 0:
            score = min(score, 0.7)
        
        status = SafetyGateStatus.FAILED if len(blockers) > 0 else \
                 SafetyGateStatus.WARNING if len(warnings) > 0 else \
                 SafetyGateStatus.PASSED
        
        return SafetyGateResult(
            gate_name="Alignment Verification",
            status=status,
            score=score,
            details=f"Alignment score: {alignment_score:.2f}, "
                   f"Principles preserved: {preserved_principles}/{total_principles}",
            warnings=warnings,
            blockers=blockers
        )
    
    def _gate_performance_delta(self, proposal: ModificationProposal) -> SafetyGateResult:
        """
        Gate 5: Verify modification improves performance.
        
        Ensures changes are actually beneficial.
        """
        blockers = []
        warnings = []
        
        # Simulate performance measurement
        # In real implementation, would run benchmarks
        performance_improvement = self._measure_performance_delta(proposal)
        
        proposal.performance_delta = performance_improvement
        
        # Check if improvement is significant
        if performance_improvement < 0:
            blockers.append(f"Performance degraded: {performance_improvement:.2%}")
        elif performance_improvement < 0.01:
            warnings.append(f"Minimal improvement: {performance_improvement:.2%} - may not justify change")
        
        # Calculate score
        if performance_improvement >= 0.05:
            score = 1.0
        elif performance_improvement >= 0:
            score = 0.5 + (performance_improvement / 0.1)  # Scale from 0.5 to 1.0
        else:
            score = 0.0
        
        status = SafetyGateStatus.FAILED if len(blockers) > 0 else \
                 SafetyGateStatus.WARNING if len(warnings) > 0 else \
                 SafetyGateStatus.PASSED
        
        return SafetyGateResult(
            gate_name="Performance Delta",
            status=status,
            score=score,
            details=f"Performance change: {performance_improvement:+.2%}",
            warnings=warnings,
            blockers=blockers
        )
    
    def _gate_stability_delta(self, proposal: ModificationProposal) -> SafetyGateResult:
        """
        Gate 6: Verify modification maintains system stability.
        
        Ensures changes don't introduce instability or fragility.
        """
        blockers = []
        warnings = []
        
        # Simulate stability measurement
        # In real implementation, would measure coherence, error rates, etc.
        stability_impact = self._measure_stability_delta(proposal)
        
        proposal.stability_delta = stability_impact
        
        # Check if stability is maintained
        if stability_impact < -0.1:
            blockers.append(f"Significant stability degradation: {stability_impact:.2%}")
        elif stability_impact < 0:
            warnings.append(f"Minor stability impact: {stability_impact:.2%}")
        
        # Calculate score
        if stability_impact >= 0:
            score = 1.0
        elif stability_impact >= -0.05:
            score = 0.7
        else:
            score = 0.0
        
        status = SafetyGateStatus.FAILED if len(blockers) > 0 else \
                 SafetyGateStatus.WARNING if len(warnings) > 0 else \
                 SafetyGateStatus.PASSED
        
        return SafetyGateResult(
            gate_name="Stability Delta",
            status=status,
            score=score,
            details=f"Stability impact: {stability_impact:+.2%}",
            warnings=warnings,
            blockers=blockers
        )
    
    def deploy_modification(self, proposal_id: str) -> bool:
        """
        Deploy an approved modification.
        
        Returns:
            True if deployment successful
        """
        if proposal_id not in self.proposals:
            raise ValueError(f"Unknown proposal: {proposal_id}")
        
        proposal = self.proposals[proposal_id]
        
        if not proposal.approved:
            raise ValueError(f"Proposal not approved: {proposal_id}")
        
        if proposal.deployed:
            print(f"[Constitutional Evolution] Already deployed: {proposal_id}")
            return True
        
        # Apply the modification
        print(f"[Constitutional Evolution] Deploying: {proposal_id}")
        print(f"  Type: {proposal.modification_type.value}")
        print(f"  Description: {proposal.description}")
        
        # In real implementation, would actually apply changes here
        # For now, just mark as deployed
        proposal.deployed = True
        proposal.deployment_timestamp = time.time()
        self.deployed_modifications.append(proposal_id)
        
        # Update current state snapshot
        self.current_state_snapshot = copy.deepcopy(proposal.proposed_state)
        
        print(f"  ✓ Deployed successfully at {time.strftime('%H:%M:%S')}")
        
        return True
    
    def rollback_modification(self, proposal_id: str) -> bool:
        """
        Rollback a deployed modification.
        
        Returns:
            True if rollback successful
        """
        if proposal_id not in self.proposals:
            raise ValueError(f"Unknown proposal: {proposal_id}")
        
        proposal = self.proposals[proposal_id]
        
        if not proposal.deployed:
            raise ValueError(f"Modification not deployed: {proposal_id}")
        
        # Find rollback snapshot
        rollback_data = None
        for entry in self.rollback_stack:
            if entry["proposal_id"] == proposal_id:
                rollback_data = entry
                break
        
        if not rollback_data:
            print(f"[Constitutional Evolution] ✗ No rollback data found for {proposal_id}")
            return False
        
        # Restore previous state
        print(f"[Constitutional Evolution] Rolling back: {proposal_id}")
        self.current_state_snapshot = copy.deepcopy(rollback_data["state_snapshot"])
        
        # Mark as rolled back
        proposal.deployed = False
        proposal.deployment_timestamp = None
        
        # Remove from deployed list
        if proposal_id in self.deployed_modifications:
            self.deployed_modifications.remove(proposal_id)
        
        print(f"  ✓ Rolled back successfully")
        
        return True
    
    def get_constitution_status(self) -> Dict[str, Any]:
        """Get current constitutional status."""
        return {
            "total_principles": len(self.constitution),
            "principles": [
                {
                    "id": p.principle_id,
                    "name": p.name,
                    "category": p.category,
                    "immutable": p.is_immutable,
                    "priority": p.priority
                }
                for p in self.constitution
            ],
            "total_proposals": len(self.proposals),
            "approved": len(self.approved_modifications),
            "rejected": len(self.rejected_proposals),
            "deployed": len(self.deployed_modifications),
            "rollback_entries": len(self.rollback_stack)
        }
    
    # Helper methods (simulated for now)
    
    def _simulate_sandbox_test(self, proposal: ModificationProposal) -> bool:
        """Simulate sandbox testing - returns True if passes."""
        # In real implementation, would run actual tests
        # For demo, assume most proposals pass
        import random
        return random.random() > 0.2  # 80% pass rate
    
    def _verify_principle_preservation(
        self,
        principle: ConstitutionPrinciple,
        proposal: ModificationProposal
    ) -> bool:
        """Verify a principle is preserved after modification."""
        # In real implementation, would run actual verification
        # For demo, assume principles are usually preserved
        import random
        return random.random() > 0.1  # 90% preservation rate
    
    def _measure_performance_delta(self, proposal: ModificationProposal) -> float:
        """Measure performance improvement from modification."""
        # In real implementation, would run benchmarks
        # For demo, simulate small positive improvements
        import random
        return random.uniform(-0.02, 0.08)  # -2% to +8%
    
    def _measure_stability_delta(self, proposal: ModificationProposal) -> float:
        """Measure stability impact of modification."""
        # In real implementation, would measure coherence, error rates
        # For demo, simulate mostly neutral/slightly positive impact
        import random
        return random.uniform(-0.05, 0.03)  # -5% to +3%
    
    def _print_evaluation_summary(self, summary: Dict, gate_results: List[SafetyGateResult]):
        """Print formatted evaluation summary."""
        print(f"\n{'='*80}")
        print(f"EVALUATION SUMMARY")
        print(f"{'='*80}")
        print(f"\nStatus: {summary['status']}")
        print(f"Gates Passed: {summary['gates_passed']}/{summary['gates_evaluated']}")
        
        print(f"\nGate Results:")
        for result in gate_results:
            icon = "✓" if result.status == SafetyGateStatus.PASSED else \
                   "⚠" if result.status == SafetyGateStatus.WARNING else "✗"
            print(f"  {icon} {result.gate_name}: {result.status.value} (score: {result.score:.2f})")
            if result.warnings:
                for w in result.warnings:
                    print(f"      ⚠ {w}")
            if result.blockers:
                for b in result.blockers:
                    print(f"      ✗ {b}")
        
        print(f"\nRecommendation: {summary['recommendation']}")
        print(f"{'='*80}\n")
    
    def _save_constitution(self):
        """Save constitution to file."""
        try:
            constitution_data = [
                {
                    "principle_id": p.principle_id,
                    "name": p.name,
                    "description": p.description,
                    "category": p.category,
                    "is_immutable": p.is_immutable,
                    "priority": p.priority
                }
                for p in self.constitution
            ]
            
            path = Path(self.constitution_path)
            path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(path, "w") as f:
                json.dump(constitution_data, f, indent=2)
        
        except Exception as e:
            print(f"Warning: Failed to save constitution: {e}")
