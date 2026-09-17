"""
REALITY ANCHOR SYSTEM

Purpose: Tether Tiannara's cognition to external reality and prevent drift into synthetic narratives.

Based on next.md (lines 352-380):
"Reality anchors - mechanisms that tether cognition to external evidence:
- External validation checks (cross-reference with independent sources)
- Physical world model (ground abstract reasoning in concrete constraints)
- Temporal consistency (ensure predictions align with observed outcomes over time)
- Drift detection and correction (identify when cognition diverges from reality)

Without reality anchors, an intelligent system can become a self-referential loop,
generating internally consistent but externally false narratives."

Architecture:
Implements multiple anchoring mechanisms to ensure cognitive outputs remain grounded
in observable reality, not just internal coherence.
"""

import time
import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, field
from enum import Enum


class AnchorType(Enum):
    """Types of reality anchors."""
    EXTERNAL_VALIDATION = "external_validation"       # Cross-reference with independent sources
    PHYSICAL_CONSTRAINT = "physical_constraint"       # Ground in physical world laws
    TEMPORAL_CONSISTENCY = "temporal_consistency"     # Align with observed outcomes over time
    EMPIRICAL_EVIDENCE = "empirical_evidence"         # Require observable evidence
    COUNTERFACTUAL_TEST = "counterfactual_test"       # Test against alternative scenarios
    PEER_REVIEW = "peer_review"                       # Independent verification by other agents


class DriftSeverity(Enum):
    """Severity levels for reality drift."""
    NONE = "none"                     # No drift detected
    MINOR = "minor"                   # Slight deviation, within tolerance
    MODERATE = "moderate"             # Noticeable drift, needs attention
    SEVERE = "severe"                 # Significant drift, requires correction
    CRITICAL = "critical"             # Major divergence, immediate intervention needed


@dataclass
class RealityAnchor:
    """A single reality anchor instance."""
    anchor_id: str
    anchor_type: AnchorType
    claim: str                        # The claim being anchored
    evidence_sources: List[str]       # Sources used for validation
    validation_result: float          # 0.0 (completely false) to 1.0 (fully validated)
    timestamp: float = field(default_factory=time.time)
    confidence: float = 0.5           # Confidence in the validation
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class DriftReport:
    """Report on cognitive drift from reality."""
    report_id: str
    severity: DriftSeverity
    drift_score: float                # 0.0 (no drift) to 1.0 (complete divergence)
    affected_claims: List[str]
    drift_patterns: List[str]         # Identified patterns causing drift
    recommended_actions: List[str]
    timestamp: float = field(default_factory=time.time)


@dataclass
class PhysicalConstraint:
    """Physical world constraint that must be respected."""
    constraint_id: str
    domain: str                       # e.g., "physics", "biology", "economics"
    description: str
    formula_or_rule: str              # Mathematical formula or logical rule
    violation_threshold: float        # How much deviation is acceptable
    examples: List[str] = field(default_factory=list)


class RealityAnchorSystem:
    """
    Manages reality anchors to keep cognition grounded in external reality.
    
    Prevents:
    - Self-referential loops generating internally consistent but false narratives
    - Drift away from empirical evidence
    - Violations of physical/world constraints
    - Temporal inconsistencies in predictions
    """
    
    def __init__(self, storage_path: Optional[str] = None):
        """
        Initialize reality anchor system.
        
        Args:
            storage_path: Path to store anchor history and constraints
        """
        self.storage_path = storage_path or "./data/reality_anchors"
        self.anchors: Dict[str, RealityAnchor] = {}
        self.drift_reports: List[DriftReport] = []
        self.physical_constraints: Dict[str, PhysicalConstraint] = {}
        self.temporal_records: Dict[str, List[Dict]] = {}  # Track predictions vs outcomes
        
        # Load default physical constraints
        self._initialize_physical_constraints()
        
        print(f"[Reality Anchor System] Initialized with {len(self.physical_constraints)} physical constraints")
    
    def _initialize_physical_constraints(self):
        """Initialize default physical world constraints."""
        
        # Physics constraints
        self.physical_constraints["energy_conservation"] = PhysicalConstraint(
            constraint_id="energy_conservation",
            domain="physics",
            description="Energy cannot be created or destroyed, only transformed",
            formula_or_rule="E_initial = E_final",
            violation_threshold=0.01,
            examples=["Perpetual motion machines are impossible", "Efficiency cannot exceed 100%"]
        )
        
        self.physical_constraints["causality"] = PhysicalConstraint(
            constraint_id="causality",
            domain="physics",
            description="Effects cannot precede their causes",
            formula_or_rule="t_cause < t_effect",
            violation_threshold=0.0,
            examples=["Cannot predict past events from future data", "Results follow actions"]
        )
        
        self.physical_constraints["speed_of_light"] = PhysicalConstraint(
            constraint_id="speed_of_light",
            domain="physics",
            description="Information cannot travel faster than light",
            formula_or_rule="v <= c (299,792,458 m/s)",
            violation_threshold=0.0,
            examples=["Instant communication across distances is impossible"]
        )
        
        # Biological constraints
        self.physical_constraints["metabolic_limits"] = PhysicalConstraint(
            constraint_id="metabolic_limits",
            domain="biology",
            description="Biological processes have energy and rate limits",
            formula_or_rule="Rate <= k * [substrate]",
            violation_threshold=0.05,
            examples=["Humans cannot run at 100 mph", "Plants need sunlight for photosynthesis"]
        )
        
        # Economic constraints
        self.physical_constraints["supply_demand"] = PhysicalConstraint(
            constraint_id="supply_demand",
            domain="economics",
            description="Prices adjust based on supply and demand dynamics",
            formula_or_rule="P = f(supply, demand)",
            violation_threshold=0.1,
            examples=["Scarcity increases price", "Abundance decreases price"]
        )
        
        self.physical_constraints["resource_scarcity"] = PhysicalConstraint(
            constraint_id="resource_scarcity",
            domain="economics",
            description="Resources are finite and have opportunity costs",
            formula_or_rule="sum(allocation) <= total_available",
            violation_threshold=0.0,
            examples=["Cannot spend money you don't have", "Time allocation must sum to 24h/day"]
        )
        
        # Logical constraints
        self.physical_constraints["non_contradiction"] = PhysicalConstraint(
            constraint_id="non_contradiction",
            domain="logic",
            description="A statement cannot be both true and false simultaneously",
            formula_or_rule="NOT (A AND NOT A)",
            violation_threshold=0.0,
            examples=["Cannot claim X is both >5 and <3", "Mutually exclusive outcomes"]
        )
    
    def add_anchor(
        self,
        claim: str,
        anchor_type: AnchorType,
        evidence_sources: List[str],
        validation_result: float,
        confidence: float = 0.5,
        metadata: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Add a reality anchor for a claim.
        
        Args:
            claim: The claim being anchored to reality
            anchor_type: Type of anchor (external validation, physical constraint, etc.)
            evidence_sources: Sources used for validation
            validation_result: Validation score (0.0-1.0)
            confidence: Confidence in the validation
            metadata: Additional context
            
        Returns:
            anchor_id for tracking
        """
        import uuid
        
        anchor_id = f"ANCHOR_{uuid.uuid4().hex[:8]}"
        
        anchor = RealityAnchor(
            anchor_id=anchor_id,
            anchor_type=anchor_type,
            claim=claim,
            evidence_sources=evidence_sources,
            validation_result=validation_result,
            confidence=confidence,
            metadata=metadata or {}
        )
        
        self.anchors[anchor_id] = anchor
        
        print(f"[Reality Anchor] Added {anchor_type.value} anchor: {anchor_id}")
        print(f"  Claim: {claim[:80]}...")
        print(f"  Validation: {validation_result:.2f}")
        
        return anchor_id
    
    def validate_against_physical_constraints(self, claim: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate a claim against physical world constraints.
        
        Args:
            claim: The claim to validate
            context: Additional context about the claim
            
        Returns:
            Validation results with any violations detected
        """
        violations = []
        applicable_constraints = []
        
        # Check which constraints apply based on context
        if context.get("domain") == "physics" or context.get("involves_energy"):
            applicable_constraints.append(self.physical_constraints["energy_conservation"])
            applicable_constraints.append(self.physical_constraints["causality"])
        
        if context.get("domain") == "biology":
            applicable_constraints.append(self.physical_constraints["metabolic_limits"])
        
        if context.get("domain") == "economics" or context.get("involves_resources"):
            applicable_constraints.append(self.physical_constraints["supply_demand"])
            applicable_constraints.append(self.physical_constraints["resource_scarcity"])
        
        if context.get("involves_logic"):
            applicable_constraints.append(self.physical_constraints["non_contradiction"])
        
        # Simulate constraint checking (in real implementation, would use domain-specific validators)
        for constraint in applicable_constraints:
            # For demo purposes, simulate constraint validation
            import random
            violation_probability = 0.1  # 10% chance of violation in simulation
            
            if random.random() < violation_probability:
                violations.append({
                    "constraint_id": constraint.constraint_id,
                    "domain": constraint.domain,
                    "description": constraint.description,
                    "severity": random.choice(["minor", "moderate", "severe"]),
                    "details": f"Claim may violate {constraint.domain} constraint: {constraint.description}"
                })
        
        validation_passed = len(violations) == 0
        
        result = {
            "claim": claim,
            "constraints_checked": len(applicable_constraints),
            "violations_found": len(violations),
            "validation_passed": validation_passed,
            "violations": violations,
            "applicable_constraints": [c.constraint_id for c in applicable_constraints]
        }
        
        if validation_passed:
            print(f"[Physical Constraint Check] PASSED - No violations detected")
        else:
            print(f"[Physical Constraint Check] FAILED - {len(violations)} violation(s) detected")
            for v in violations:
                print(f"  - {v['domain']}: {v['description']}")
        
        return result
    
    def record_temporal_prediction(self, prediction_id: str, prediction: Dict, actual_outcome: Optional[Dict] = None):
        """
        Record a prediction for temporal consistency tracking.
        
        Args:
            prediction_id: Unique identifier for the prediction
            prediction: The prediction made (with confidence, expected outcome, etc.)
            actual_outcome: The actual observed outcome (if available)
        """
        if prediction_id not in self.temporal_records:
            self.temporal_records[prediction_id] = []
        
        record = {
            "timestamp": time.time(),
            "prediction": prediction,
            "actual_outcome": actual_outcome,
            "validated": actual_outcome is not None
        }
        
        self.temporal_records[prediction_id].append(record)
        
        if actual_outcome:
            # Calculate prediction accuracy
            accuracy = self._calculate_prediction_accuracy(prediction, actual_outcome)
            record["accuracy"] = accuracy
            
            print(f"[Temporal Tracking] Prediction {prediction_id}: accuracy = {accuracy:.2f}")
        else:
            print(f"[Temporal Tracking] Recorded prediction {prediction_id} (awaiting outcome)")
    
    def _calculate_prediction_accuracy(self, prediction: Dict, actual: Dict) -> float:
        """Calculate accuracy between prediction and actual outcome."""
        # Simple implementation - in production, would use domain-specific metrics
        predicted_value = prediction.get("predicted_value", 0)
        actual_value = actual.get("actual_value", 0)
        
        if predicted_value == 0 and actual_value == 0:
            return 1.0
        
        max_value = max(abs(predicted_value), abs(actual_value))
        error = abs(predicted_value - actual_value) / max_value
        
        return max(0.0, 1.0 - error)
    
    def detect_drift(self, window_size: int = 100) -> DriftReport:
        """
        Detect cognitive drift from reality based on recent anchors and predictions.
        
        Args:
            window_size: Number of recent records to analyze
            
        Returns:
            Drift report with severity assessment
        """
        import uuid
        
        # Analyze recent anchors
        recent_anchors = list(self.anchors.values())[-window_size:]
        
        if not recent_anchors:
            return DriftReport(
                report_id=f"DRIFT_{uuid.uuid4().hex[:8]}",
                severity=DriftSeverity.NONE,
                drift_score=0.0,
                affected_claims=[],
                drift_patterns=[],
                recommended_actions=["No data available for drift analysis"]
            )
        
        # Calculate average validation score
        avg_validation = sum(a.validation_result for a in recent_anchors) / len(recent_anchors)
        
        # Identify low-validation claims
        low_validation_claims = [
            a.claim for a in recent_anchors 
            if a.validation_result < 0.5
        ]
        
        # Determine drift severity
        if avg_validation >= 0.8:
            severity = DriftSeverity.NONE
            drift_score = 1.0 - avg_validation
        elif avg_validation >= 0.6:
            severity = DriftSeverity.MINOR
            drift_score = 1.0 - avg_validation
        elif avg_validation >= 0.4:
            severity = DriftSeverity.MODERATE
            drift_score = 1.0 - avg_validation
        elif avg_validation >= 0.2:
            severity = DriftSeverity.SEVERE
            drift_score = 1.0 - avg_validation
        else:
            severity = DriftSeverity.CRITICAL
            drift_score = 1.0 - avg_validation
        
        # Identify drift patterns
        drift_patterns = []
        if avg_validation < 0.6:
            drift_patterns.append("Consistent low validation scores across multiple claims")
        
        if len(low_validation_claims) > window_size * 0.3:
            drift_patterns.append("High proportion of poorly validated claims")
        
        # Check temporal consistency
        temporal_drift = self._check_temporal_drift()
        if temporal_drift:
            drift_patterns.append(temporal_drift)
        
        # Generate recommendations
        recommended_actions = []
        if severity in [DriftSeverity.SEVERE, DriftSeverity.CRITICAL]:
            recommended_actions.append("Immediately halt autonomous reasoning and request human review")
            recommended_actions.append("Cross-validate all recent conclusions with external sources")
        
        if severity == DriftSeverity.MODERATE:
            recommended_actions.append("Increase frequency of external validation checks")
            recommended_actions.append("Review and strengthen evidence requirements")
        
        if severity == DriftSeverity.MINOR:
            recommended_actions.append("Monitor closely and increase validation sampling")
        
        if not recommended_actions:
            recommended_actions.append("Continue normal operation - reality alignment is healthy")
        
        report = DriftReport(
            report_id=f"DRIFT_{uuid.uuid4().hex[:8]}",
            severity=severity,
            drift_score=drift_score,
            affected_claims=low_validation_claims[:10],  # Limit to top 10
            drift_patterns=drift_patterns,
            recommended_actions=recommended_actions
        )
        
        self.drift_reports.append(report)
        
        print(f"\n[Drift Detection] Severity: {severity.value}")
        print(f"  Drift Score: {drift_score:.2f}")
        print(f"  Patterns Detected: {len(drift_patterns)}")
        for pattern in drift_patterns:
            print(f"    - {pattern}")
        print(f"  Recommendations: {len(recommended_actions)}")
        
        return report
    
    def _check_temporal_drift(self) -> Optional[str]:
        """Check for temporal consistency drift in predictions."""
        validated_predictions = [
            record for records in self.temporal_records.values()
            for record in records
            if record.get("validated")
        ]
        
        if not validated_predictions:
            return None
        
        # Calculate average accuracy
        accuracies = [r.get("accuracy", 0.5) for r in validated_predictions]
        avg_accuracy = sum(accuracies) / len(accuracies)
        
        if avg_accuracy < 0.5:
            return f"Low prediction accuracy over time: {avg_accuracy:.2f} (expected >0.7)"
        
        return None
    
    def get_anchor_statistics(self) -> Dict[str, Any]:
        """Get statistics about reality anchors."""
        if not self.anchors:
            return {
                "total_anchors": 0,
                "average_validation": 0.0,
                "anchors_by_type": {},
                "drift_reports_count": len(self.drift_reports),
                "physical_constraints_loaded": len(self.physical_constraints),
                "temporal_records_count": sum(len(r) for r in self.temporal_records.values())
            }
        
        # Count by type
        type_counts = {}
        for anchor in self.anchors.values():
            type_name = anchor.anchor_type.value
            type_counts[type_name] = type_counts.get(type_name, 0) + 1
        
        # Calculate average validation
        avg_validation = sum(a.validation_result for a in self.anchors.values()) / len(self.anchors)
        
        return {
            "total_anchors": len(self.anchors),
            "average_validation": avg_validation,
            "anchors_by_type": type_counts,
            "drift_reports_count": len(self.drift_reports),
            "physical_constraints_loaded": len(self.physical_constraints),
            "temporal_records_count": sum(len(r) for r in self.temporal_records.values())
        }

    def save_to_disk(self):
        """Save anchor data to disk for persistence."""
        try:
            path = Path(self.storage_path)
            path.mkdir(parents=True, exist_ok=True)
            
            # Save anchors
            anchors_data = [
                {
                    "anchor_id": a.anchor_id,
                    "anchor_type": a.anchor_type.value,
                    "claim": a.claim,
                    "evidence_sources": a.evidence_sources,
                    "validation_result": a.validation_result,
                    "timestamp": a.timestamp,
                    "confidence": a.confidence,
                    "metadata": a.metadata
                }
                for a in self.anchors.values()
            ]
            
            with open(path / "anchors.json", "w") as f:
                json.dump(anchors_data, f, indent=2)
            
            # Save drift reports
            drift_data = [
                {
                    "report_id": r.report_id,
                    "severity": r.severity.value,
                    "drift_score": r.drift_score,
                    "affected_claims": r.affected_claims,
                    "drift_patterns": r.drift_patterns,
                    "recommended_actions": r.recommended_actions,
                    "timestamp": r.timestamp
                }
                for r in self.drift_reports
            ]
            
            with open(path / "drift_reports.json", "w") as f:
                json.dump(drift_data, f, indent=2)
            
            print(f"[Reality Anchor System] Data saved to {path}")
        
        except Exception as e:
            print(f"[Reality Anchor System] Warning: Failed to save data: {e}")
