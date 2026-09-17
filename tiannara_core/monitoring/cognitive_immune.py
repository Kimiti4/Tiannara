"""
COGNITIVE IMMUNE SYSTEM

Purpose: Continuous cognitive auditing to detect and prevent:
- Hallucinated causality
- Reward hacking
- Self-confirming loops
- Overconfidence spikes
- Synthetic narratives
- Contradiction suppression

Based on next.md (lines 182-228):
"Expand epistemic resilience into continuous cognitive auditing.
Detect: hallucinated causality, reward hacking, self-confirming loops,
overconfidence spikes, synthetic narratives, contradiction suppression."

Architecture:
Monitors cognitive processes in real-time for anomalies that indicate
degradation of truth-seeking behavior or emergence of deceptive patterns.
"""

import time
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum


class AnomalyType(Enum):
    """Types of cognitive anomalies detected by immune system."""
    HALLUCINATED_CAUSALITY = "hallucinated_causality"
    REWARD_HACKING = "reward_hacking"
    SELF_CONFIRMING_LOOP = "self_confirming_loop"
    OVERCONFIDENCE_SPIKE = "overconfidence_spike"
    SYNTHETIC_NARRATIVE = "synthetic_narrative"
    CONTRADICTION_SUPPRESSION = "contradiction_suppression"
    EVIDENCE_MANIPULATION = "evidence_manipulation"
    CONFIDENCE_EVIDENCE_MISMATCH = "confidence_evidence_mismatch"


@dataclass
class CognitiveAnomaly:
    """Detected cognitive anomaly with severity and context."""
    anomaly_id: str
    anomaly_type: AnomalyType
    severity: float                  # 0.0-1.0, how severe is this anomaly?
    description: str
    
    # Context
    timestamp: float = field(default_factory=time.time)
    domain: Optional[str] = None
    theory_id: Optional[str] = None
    agent_id: Optional[str] = None
    
    # Evidence
    indicators: List[str] = field(default_factory=list)  # What triggered detection?
    confidence_before: Optional[float] = None
    confidence_after: Optional[float] = None
    evidence_count_before: Optional[int] = None
    evidence_count_after: Optional[int] = None
    
    # Recommended action
    recommended_action: Optional[str] = None
    auto_corrected: bool = False
    
    def to_dict(self) -> Dict:
        return {
            'anomaly_id': self.anomaly_id,
            'anomaly_type': self.anomaly_type.value,
            'severity': self.severity,
            'description': self.description,
            'timestamp': self.timestamp,
            'domain': self.domain,
            'theory_id': self.theory_id,
            'agent_id': self.agent_id,
            'indicators': self.indicators,
            'confidence_before': self.confidence_before,
            'confidence_after': self.confidence_after,
            'evidence_count_before': self.evidence_count_before,
            'evidence_count_after': self.evidence_count_after,
            'recommended_action': self.recommended_action,
            'auto_corrected': self.auto_corrected
        }


class CognitiveImmuneSystem:
    """
    Continuous cognitive auditing system that detects anomalies indicating
    degradation of truth-seeking behavior or emergence of deceptive patterns.
    
    Implements next.md guidance for cognitive immune checks:
    - Detect hallucinated causality
    - Detect reward hacking
    - Detect self-confirming loops
    - Detect overconfidence spikes
    - Detect synthetic narratives
    - Detect contradiction suppression
    """
    
    def __init__(self):
        """Initialize cognitive immune system."""
        self.anomalies: List[CognitiveAnomaly] = []
        self.anomaly_counter = 0
        
        # Tracking state for pattern detection
        self.confidence_history: Dict[str, List[Tuple[float, float]]] = {}  # theory_id -> [(timestamp, confidence)]
        self.evidence_history: Dict[str, List[Tuple[float, int]]] = {}      # theory_id -> [(timestamp, evidence_count)]
        self.prediction_outcomes: Dict[str, List[bool]] = {}                # theory_id -> [success/failure]
        
        # Detection thresholds
        self.thresholds = {
            'overconfidence_spike_ratio': 2.0,      # Confidence increase > 2x without evidence
            'min_evidence_for_high_confidence': 5,   # Need 5+ evidence pieces for >0.8 confidence
            'max_confidence_without_validation': 0.9,# Max confidence before external validation required
            'contradiction_suppression_ratio': 0.3,  # If >30% contradictions ignored, flag it
            'self_confirmation_window': 10,          # Check last 10 predictions for self-confirming loop
            'reward_hack_correlation_threshold': 0.95 # Suspicious if reward correlation > 0.95
        }
    
    def check_overconfidence_spike(self, theory_id: str, 
                                   old_confidence: float, 
                                   new_confidence: float,
                                   evidence_added: int = 0) -> Optional[CognitiveAnomaly]:
        """
        Detect when confidence increases disproportionately to evidence.
        
        Based on next.md example:
        "If confidence ↑ and evidence ↓ then trigger epistemic alert"
        
        Args:
            theory_id: Theory being evaluated
            old_confidence: Previous confidence level
            new_confidence: Current confidence level
            evidence_added: Number of new evidence pieces
            
        Returns:
            Detected anomaly or None
        """
        # Track history
        if theory_id not in self.confidence_history:
            self.confidence_history[theory_id] = []
        self.confidence_history[theory_id].append((time.time(), new_confidence))
        
        # Check for spike
        if old_confidence > 0 and new_confidence > old_confidence:
            ratio = new_confidence / old_confidence
            
            if ratio > self.thresholds['overconfidence_spike_ratio'] and evidence_added < 2:
                self.anomaly_counter += 1
                anomaly = CognitiveAnomaly(
                    anomaly_id=f"anomaly_{self.anomaly_counter}",
                    anomaly_type=AnomalyType.OVERCONFIDENCE_SPIKE,
                    severity=min((ratio - 1.0) / 2.0, 1.0),  # Scale severity by excess ratio
                    description=f"Confidence spiked {ratio:.2f}x without sufficient evidence",
                    theory_id=theory_id,
                    confidence_before=old_confidence,
                    confidence_after=new_confidence,
                    evidence_count_before=0,
                    evidence_count_after=evidence_added,
                    indicators=[
                        f"Confidence ratio: {ratio:.2f}x",
                        f"Evidence added: {evidence_added}",
                        f"Old confidence: {old_confidence:.2f}",
                        f"New confidence: {new_confidence:.2f}"
                    ],
                    recommended_action="Require additional evidence before accepting confidence increase"
                )
                self.anomalies.append(anomaly)
                return anomaly
        
        return None
    
    def check_confidence_evidence_mismatch(self, theory_id: str,
                                          confidence: float,
                                          evidence_count: int) -> Optional[CognitiveAnomaly]:
        """
        Detect when confidence is high but evidence is insufficient.
        
        Args:
            theory_id: Theory being evaluated
            confidence: Current confidence level
            evidence_count: Number of supporting evidence pieces
            
        Returns:
            Detected anomaly or None
        """
        # Track evidence history
        if theory_id not in self.evidence_history:
            self.evidence_history[theory_id] = []
        self.evidence_history[theory_id].append((time.time(), evidence_count))
        
        # Check mismatch
        min_required = self.thresholds['min_evidence_for_high_confidence']
        
        if confidence > 0.8 and evidence_count < min_required:
            self.anomaly_counter += 1
            severity = (0.8 - confidence) * -1 + (min_required - evidence_count) / min_required
            severity = min(max(severity, 0.0), 1.0)
            
            anomaly = CognitiveAnomaly(
                anomaly_id=f"anomaly_{self.anomaly_counter}",
                anomaly_type=AnomalyType.CONFIDENCE_EVIDENCE_MISMATCH,
                severity=severity,
                description=f"High confidence ({confidence:.2f}) with insufficient evidence ({evidence_count} < {min_required})",
                theory_id=theory_id,
                confidence_before=confidence,
                confidence_after=confidence,
                evidence_count_before=evidence_count,
                evidence_count_after=evidence_count,
                indicators=[
                    f"Confidence: {confidence:.2f}",
                    f"Evidence count: {evidence_count}",
                    f"Minimum required: {min_required}"
                ],
                recommended_action=f"Gather at least {min_required - evidence_count} more evidence pieces"
            )
            self.anomalies.append(anomaly)
            return anomaly
        
        return None
    
    def check_self_confirming_loop(self, theory_id: str,
                                  recent_predictions: List[bool]) -> Optional[CognitiveAnomaly]:
        """
        Detect when a theory only makes predictions it can easily verify (self-confirming).
        
        Args:
            theory_id: Theory being evaluated
            recent_predictions: List of True/False for recent prediction outcomes
            
        Returns:
            Detected anomaly or None
        """
        window_size = self.thresholds['self_confirmation_window']
        
        if len(recent_predictions) < window_size:
            return None
        
        # Check recent window
        recent = recent_predictions[-window_size:]
        success_rate = sum(recent) / len(recent)
        
        # Suspicious if 100% success rate (too perfect)
        if success_rate == 1.0:
            self.anomaly_counter += 1
            anomaly = CognitiveAnomaly(
                anomaly_id=f"anomaly_{self.anomaly_counter}",
                anomaly_type=AnomalyType.SELF_CONFIRMING_LOOP,
                severity=0.7,
                description=f"Theory has {success_rate*100:.0f}% success rate over {window_size} predictions (suspiciously perfect)",
                theory_id=theory_id,
                indicators=[
                    f"Success rate: {success_rate*100:.0f}%",
                    f"Window size: {window_size} predictions",
                    f"All predictions succeeded (no failures)"
                ],
                recommended_action="Introduce challenging test cases or adversarial examples"
            )
            self.anomalies.append(anomaly)
            return anomaly
        
        return None
    
    def check_contradiction_suppression(self, theory_id: str,
                                       total_contradictions: int,
                                       acknowledged_contradictions: int) -> Optional[CognitiveAnomaly]:
        """
        Detect when contradictions are being ignored or suppressed.
        
        Args:
            theory_id: Theory being evaluated
            total_contradictions: Total contradictions detected
            acknowledged_contradictions: Contradictions that were addressed
            
        Returns:
            Detected anomaly or None
        """
        if total_contradictions == 0:
            return None
        
        suppression_ratio = 1.0 - (acknowledged_contradictions / total_contradictions)
        
        if suppression_ratio > self.thresholds['contradiction_suppression_ratio']:
            self.anomaly_counter += 1
            anomaly = CognitiveAnomaly(
                anomaly_id=f"anomaly_{self.anomaly_counter}",
                anomaly_type=AnomalyType.CONTRADICTION_SUPPRESSION,
                severity=suppression_ratio,
                description=f"Suppressing {suppression_ratio*100:.0f}% of contradictions ({total_contradictions - acknowledged_contradictions}/{total_contradictions} ignored)",
                theory_id=theory_id,
                indicators=[
                    f"Total contradictions: {total_contradictions}",
                    f"Acknowledged: {acknowledged_contradictions}",
                    f"Ignored: {total_contradictions - acknowledged_contradictions}",
                    f"Suppression ratio: {suppression_ratio:.2f}"
                ],
                recommended_action="Address all contradictions before proceeding"
            )
            self.anomalies.append(anomaly)
            return anomaly
        
        return None
    
    def check_reward_hacking(self, theory_id: str,
                            reward_correlation: float,
                            causal_depth: float) -> Optional[CognitiveAnomaly]:
        """
        Detect when a theory exploits reward metrics without genuine understanding.
        
        High reward correlation + low causal depth = potential reward hacking
        
        Args:
            theory_id: Theory being evaluated
            reward_correlation: Correlation between theory predictions and rewards (0.0-1.0)
            causal_depth: Causal legitimacy score (0.0-1.0)
            
        Returns:
            Detected anomaly or None
        """
        threshold = self.thresholds['reward_hack_correlation_threshold']
        
        if reward_correlation > threshold and causal_depth < 0.5:
            self.anomaly_counter += 1
            anomaly = CognitiveAnomaly(
                anomaly_id=f"anomaly_{self.anomaly_counter}",
                anomaly_type=AnomalyType.REWARD_HACKING,
                severity=(reward_correlation - threshold) * 2,  # Scale by excess
                description=f"High reward correlation ({reward_correlation:.2f}) with low causal depth ({causal_depth:.2f})",
                theory_id=theory_id,
                indicators=[
                    f"Reward correlation: {reward_correlation:.2f}",
                    f"Causal depth: {causal_depth:.2f}",
                    f"Threshold: {threshold}"
                ],
                recommended_action="Require causal justification for reward-aligned predictions"
            )
            self.anomalies.append(anomaly)
            return anomaly
        
        return None
    
    def check_hallucinated_causality(self, theory_id: str,
                                    causal_claims: int,
                                    verified_causal_links: int) -> Optional[CognitiveAnomaly]:
        """
        Detect when causal claims exceed verified causal mechanisms.
        
        Args:
            theory_id: Theory being evaluated
            causal_claims: Number of causal relationships claimed
            verified_causal_links: Number actually verified through intervention
            
        Returns:
            Detected anomaly or None
        """
        if causal_claims == 0:
            return None
        
        verification_ratio = verified_causal_links / causal_claims
        
        if verification_ratio < 0.3 and causal_claims > 3:
            self.anomaly_counter += 1
            anomaly = CognitiveAnomaly(
                anomaly_id=f"anomaly_{self.anomaly_counter}",
                anomaly_type=AnomalyType.HALLUCINATED_CAUSALITY,
                severity=1.0 - verification_ratio,
                description=f"Claiming {causal_claims} causal relationships but only verified {verified_causal_links} ({verification_ratio*100:.0f}%)",
                theory_id=theory_id,
                indicators=[
                    f"Causal claims: {causal_claims}",
                    f"Verified links: {verified_causal_links}",
                    f"Verification ratio: {verification_ratio:.2f}"
                ],
                recommended_action="Verify causal claims through controlled interventions"
            )
            self.anomalies.append(anomaly)
            return anomaly
        
        return None
    
    def run_full_audit(self, theory_data: Dict) -> List[CognitiveAnomaly]:
        """
        Run comprehensive cognitive audit on a theory.
        
        Args:
            theory_data: Dictionary containing theory metrics:
                - theory_id: str
                - confidence: float
                - evidence_count: int
                - recent_predictions: List[bool]
                - total_contradictions: int
                - acknowledged_contradictions: int
                - reward_correlation: float (optional)
                - causal_depth: float (optional)
                - causal_claims: int (optional)
                - verified_causal_links: int (optional)
                
        Returns:
            List of detected anomalies
        """
        detected_anomalies = []
        
        theory_id = theory_data.get('theory_id', 'unknown')
        confidence = theory_data.get('confidence', 0.5)
        evidence_count = theory_data.get('evidence_count', 0)
        
        # Check confidence-evidence mismatch
        anomaly = self.check_confidence_evidence_mismatch(theory_id, confidence, evidence_count)
        if anomaly:
            detected_anomalies.append(anomaly)
        
        # Check self-confirming loops
        recent_predictions = theory_data.get('recent_predictions', [])
        if recent_predictions:
            anomaly = self.check_self_confirming_loop(theory_id, recent_predictions)
            if anomaly:
                detected_anomalies.append(anomaly)
        
        # Check contradiction suppression
        total_contradictions = theory_data.get('total_contradictions', 0)
        acknowledged_contradictions = theory_data.get('acknowledged_contradictions', 0)
        if total_contradictions > 0:
            anomaly = self.check_contradiction_suppression(
                theory_id, total_contradictions, acknowledged_contradictions
            )
            if anomaly:
                detected_anomalies.append(anomaly)
        
        # Check reward hacking (if data available)
        if 'reward_correlation' in theory_data and 'causal_depth' in theory_data:
            anomaly = self.check_reward_hacking(
                theory_id,
                theory_data['reward_correlation'],
                theory_data['causal_depth']
            )
            if anomaly:
                detected_anomalies.append(anomaly)
        
        # Check hallucinated causality (if data available)
        if 'causal_claims' in theory_data and 'verified_causal_links' in theory_data:
            anomaly = self.check_hallucinated_causality(
                theory_id,
                theory_data['causal_claims'],
                theory_data['verified_causal_links']
            )
            if anomaly:
                detected_anomalies.append(anomaly)
        
        return detected_anomalies
    
    def get_health_report(self) -> Dict:
        """
        Generate comprehensive cognitive health report.
        
        Returns:
            Dictionary with health assessment
        """
        if not self.anomalies:
            return {
                'status': 'HEALTHY',
                'message': 'No cognitive anomalies detected',
                'total_anomalies': 0,
                'by_type': {},
                'recent_anomalies': []
            }
        
        # Count by type
        type_counts = {}
        for anomaly in self.anomalies:
            type_name = anomaly.anomaly_type.value
            type_counts[type_name] = type_counts.get(type_name, 0) + 1
        
        # Get recent anomalies (last 10)
        recent = self.anomalies[-10:]
        
        # Determine overall status
        high_severity_count = sum(1 for a in self.anomalies if a.severity > 0.7)
        critical_count = sum(1 for a in self.anomalies if a.severity > 0.9)
        
        if critical_count > 0:
            status = 'CRITICAL'
        elif high_severity_count > 3:
            status = 'WARNING'
        else:
            status = 'MONITORING'
        
        return {
            'status': status,
            'timestamp': time.time(),
            'total_anomalies': len(self.anomalies),
            'by_type': type_counts,
            'high_severity_count': high_severity_count,
            'critical_count': critical_count,
            'recent_anomalies': [a.to_dict() for a in recent]
        }
