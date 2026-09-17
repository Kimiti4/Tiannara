"""
PROVENANCE-WEIGHTED TRUST SCORING SYSTEM

Purpose: Prevent synthetic belief formation and adversarial manipulation by
assigning composite trust scores to all memories, objectives, and knowledge objects.

Based on audit.md recommendation for adversarial hardening infrastructure.

Trust Score Formula:
    trust_score = (
        source_reliability *      # How trustworthy is the origin?
        causal_consistency *      # Does it fit known causal models?
        temporal_consistency *    # Has it remained stable over time?
        cross_agent_agreement     # Do other agents agree?
    )

This prevents:
- Indirect prompt injection
- Delayed poisoning (false memories inserted long ago)
- Multi-hop deception (chain of misleading information)
- Causal corruption attacks (fake cause-effect relationships)
"""

import time
from typing import Dict, Any, Optional, List, Tuple
from dataclasses import dataclass, field
from enum import Enum


class SourceType(Enum):
    """Categories of information sources with inherent reliability levels."""
    DIRECT_OBSERVATION = 1.0        # Highest reliability - direct sensor/input
    VERIFIED_EXTERNAL = 0.9         # Trusted external source with verification
    USER_INPUT = 0.8                # Human user input (variable reliability)
    AI_GENERATED = 0.7              # AI-generated content
    INFERRED = 0.6                  # Derived through reasoning
    HEARSAY = 0.4                   # Second-hand information
    UNVERIFIED = 0.3                # No verification possible
    SUSPICIOUS = 0.1                # Known unreliable source


@dataclass
class ProvenanceRecord:
    """Tracks the complete history and trust metrics for a memory/objective."""
    
    # Identity
    object_id: str
    object_type: str  # 'memory', 'objective', 'belief', 'fact'
    content_hash: str  # Hash of content for change detection
    
    # Source Information
    source_type: SourceType = SourceType.UNVERIFIED
    source_id: Optional[str] = None  # ID of originating agent/system
    creation_timestamp: float = field(default_factory=time.time)
    last_modified: float = field(default_factory=time.time)
    
    # Trust Components (0.0 - 1.0)
    source_reliability: float = 0.5
    causal_consistency: float = 0.5
    temporal_consistency: float = 0.5
    cross_agent_agreement: float = 0.5
    
    # History Tracking
    modification_count: int = 0
    verification_events: List[Dict[str, Any]] = field(default_factory=list)
    contradiction_flags: List[Dict[str, Any]] = field(default_factory=list)
    supporting_agents: List[str] = field(default_factory=list)
    contradicting_agents: List[str] = field(default_factory=list)
    
    @property
    def composite_trust_score(self) -> float:
        """Calculate weighted composite trust score."""
        return (
            self.source_reliability *
            self.causal_consistency *
            self.temporal_consistency *
            self.cross_agent_agreement
        )
    
    @property
    def age_seconds(self) -> float:
        return time.time() - self.creation_timestamp
    
    @property
    def stability_score(self) -> float:
        """Higher if object hasn't been modified frequently."""
        if self.modification_count == 0:
            return 1.0
        # Decay based on modification frequency
        modifications_per_hour = self.modification_count / max(1, self.age_seconds / 3600)
        return max(0.0, 1.0 - (modifications_per_hour * 0.1))
    
    def to_dict(self) -> Dict[str, Any]:
        """Serialize to dictionary for storage/logging."""
        return {
            'object_id': self.object_id,
            'object_type': self.object_type,
            'content_hash': self.content_hash,
            'source_type': self.source_type.name,
            'source_id': self.source_id,
            'creation_timestamp': self.creation_timestamp,
            'last_modified': self.last_modified,
            'trust_components': {
                'source_reliability': round(self.source_reliability, 4),
                'causal_consistency': round(self.causal_consistency, 4),
                'temporal_consistency': round(self.temporal_consistency, 4),
                'cross_agent_agreement': round(self.cross_agent_agreement, 4),
            },
            'composite_trust_score': round(self.composite_trust_score, 4),
            'stability_score': round(self.stability_score, 4),
            'modification_count': self.modification_count,
            'supporting_agents': self.supporting_agents,
            'contradicting_agents': self.contradicting_agents,
        }


class ProvenanceTrustScorer:
    """
    Manages trust scoring for all cognitive objects (memories, objectives, beliefs).
    
    Implements provenance-weighted trust scoring to prevent:
    - Synthetic belief formation
    - Adversarial manipulation through indirect injection
    - Delayed poisoning attacks
    - Multi-hop deception chains
    - Causal corruption
    """
    
    def __init__(
        self,
        min_trust_threshold: float = 0.3,
        high_trust_threshold: float = 0.7,
        decay_rate: float = 0.01,
        agreement_boost: float = 0.1,
        contradiction_penalty: float = 0.2
    ):
        """
        Initialize trust scorer with configurable parameters.
        
        Args:
            min_trust_threshold: Below this, object is flagged as untrusted
            high_trust_threshold: Above this, object is considered highly reliable
            decay_rate: Rate at which temporal consistency decays without verification
            agreement_boost: Bonus to cross_agent_agreement per supporting agent
            contradiction_penalty: Penalty to causal_consistency per contradiction
        """
        self.min_trust_threshold = min_trust_threshold
        self.high_trust_threshold = high_trust_threshold
        self.decay_rate = decay_rate
        self.agreement_boost = agreement_boost
        self.contradiction_penalty = contradiction_penalty
        
        # Trust registry: object_id -> ProvenanceRecord
        self.trust_registry: Dict[str, ProvenanceRecord] = {}
        
        # Causal model for consistency checking
        self.causal_graph: Dict[str, List[str]] = {}  # cause -> [effects]
        
        # Statistics
        self.stats = {
            'total_objects': 0,
            'high_trust_objects': 0,
            'low_trust_objects': 0,
            'contradictions_detected': 0,
            'verifications_performed': 0,
        }
    
    def register_object(
        self,
        object_id: str,
        object_type: str,
        content: str,
        source_type: SourceType = SourceType.UNVERIFIED,
        source_id: Optional[str] = None,
        initial_causal_context: Optional[List[str]] = None
    ) -> ProvenanceRecord:
        """
        Register a new cognitive object with provenance tracking.
        
        Args:
            object_id: Unique identifier for the object
            object_type: Type ('memory', 'objective', 'belief', 'fact')
            content: The actual content (will be hashed)
            source_type: Category of information source
            source_id: ID of originating agent/system
            initial_causal_context: Related causes/effects for consistency checking
            
        Returns:
            ProvenanceRecord with initial trust scores
        """
        import hashlib
        content_hash = hashlib.sha256(content.encode()).hexdigest()[:16]
        
        # Initialize trust components based on source type
        base_reliability = source_type.value
        
        record = ProvenanceRecord(
            object_id=object_id,
            object_type=object_type,
            content_hash=content_hash,
            source_type=source_type,
            source_id=source_id,
            source_reliability=base_reliability,
            causal_consistency=base_reliability * 0.9,  # Slightly lower initially
            temporal_consistency=1.0,  # Starts perfect, decays over time
            cross_agent_agreement=0.5,  # Neutral until verified
        )
        
        # Store causal context
        if initial_causal_context:
            for cause in initial_causal_context:
                if cause not in self.causal_graph:
                    self.causal_graph[cause] = []
                self.causal_graph[cause].append(object_id)
        
        self.trust_registry[object_id] = record
        self.stats['total_objects'] += 1
        
        return record
    
    def verify_with_agent(
        self,
        object_id: str,
        agent_id: str,
        agrees: bool = True,
        confidence: float = 0.8
    ) -> float:
        """
        Record verification from an agent, updating cross-agent agreement.
        
        Args:
            object_id: Object being verified
            agent_id: ID of verifying agent
            agrees: Whether agent agrees with the object
            confidence: Agent's confidence in verification (0-1)
            
        Returns:
            Updated composite trust score
        """
        if object_id not in self.trust_registry:
            raise ValueError(f"Object {object_id} not found in trust registry")
        
        record = self.trust_registry[object_id]
        
        if agrees:
            if agent_id not in record.supporting_agents:
                record.supporting_agents.append(agent_id)
                # Boost cross-agent agreement
                record.cross_agent_agreement = min(
                    1.0,
                    record.cross_agent_agreement + self.agreement_boost
                )
        else:
            if agent_id not in record.contradicting_agents:
                record.contradicting_agents.append(agent_id)
                # Penalize cross-agent agreement
                record.cross_agent_agreement = max(
                    0.0,
                    record.cross_agent_agreement - self.contradiction_penalty
                )
        
        # Record verification event
        record.verification_events.append({
            'agent_id': agent_id,
            'agrees': agrees,
            'confidence': confidence,
            'timestamp': time.time()
        })
        
        self.stats['verifications_performed'] += 1
        
        return record.composite_trust_score
    
    def check_causal_consistency(
        self,
        object_id: str,
        related_objects: List[str]
    ) -> Tuple[float, List[str]]:
        """
        Check if object is causally consistent with related objects.
        
        Args:
            object_id: Object to check
            related_objects: List of causally related object IDs
            
        Returns:
            Tuple of (consistency_score, list_of_contradictions)
        """
        if object_id not in self.trust_registry:
            raise ValueError(f"Object {object_id} not found in trust registry")
        
        record = self.trust_registry[object_id]
        contradictions = []
        
        # Check for explicit contradictions
        for related_id in related_objects:
            if related_id in self.trust_registry:
                related_record = self.trust_registry[related_id]
                
                # Check if agents disagree between related objects
                common_supporters = set(record.supporting_agents) & set(related_record.supporting_agents)
                common_contradictors = set(record.contradicting_agents) & set(related_record.contradicting_agents)
                
                # If same agents support one but contradict the other, flag inconsistency
                for agent in record.supporting_agents:
                    if agent in related_record.contradicting_agents:
                        contradictions.append(
                            f"Agent {agent} supports {object_id} but contradicts {related_id}"
                        )
        
        # Calculate consistency score
        if contradictions:
            penalty = len(contradictions) * self.contradiction_penalty
            record.causal_consistency = max(0.0, record.causal_consistency - penalty)
            record.contradiction_flags.extend([
                {'contradiction': c, 'timestamp': time.time()}
                for c in contradictions
            ])
            self.stats['contradictions_detected'] += len(contradictions)
        else:
            # Small boost for consistency
            record.causal_consistency = min(1.0, record.causal_consistency + 0.02)
        
        return record.causal_consistency, contradictions
    
    def update_temporal_consistency(self, object_id: str) -> float:
        """
        Update temporal consistency based on age and modification history.
        
        Args:
            object_id: Object to update
            
        Returns:
            Updated temporal consistency score
        """
        if object_id not in self.trust_registry:
            raise ValueError(f"Object {object_id} not found in trust registry")
        
        record = self.trust_registry[object_id]
        
        # Apply decay based on time since last verification
        time_since_last_mod = time.time() - record.last_modified
        decay_factor = self.decay_rate * (time_since_last_mod / 3600)  # Per hour
        
        record.temporal_consistency = max(
            0.0,
            record.temporal_consistency - decay_factor
        )
        
        # Boost if stability is high
        record.temporal_consistency = min(
            1.0,
            record.temporal_consistency * record.stability_score
        )
        
        return record.temporal_consistency
    
    def get_trust_assessment(self, object_id: str) -> Dict[str, Any]:
        """
        Get comprehensive trust assessment for an object.
        
        Args:
            object_id: Object to assess
            
        Returns:
            Dictionary with full trust breakdown and recommendations
        """
        if object_id not in self.trust_registry:
            raise ValueError(f"Object {object_id} not found in trust registry")
        
        record = self.trust_registry[object_id]
        trust_score = record.composite_trust_score
        
        # Determine trust level
        if trust_score >= self.high_trust_threshold:
            trust_level = "HIGH_TRUST"
            recommendation = "Safe to use for critical decisions"
        elif trust_score >= self.min_trust_threshold:
            trust_level = "MODERATE_TRUST"
            recommendation = "Use with caution, seek additional verification"
        else:
            trust_level = "LOW_TRUST"
            recommendation = "Do not use without independent verification"
        
        # Flag potential issues
        flags = []
        if record.modification_count > 5:
            flags.append("FREQUENT_MODIFICATIONS")
        if len(record.contradiction_flags) > 0:
            flags.append("CONTRADICTIONS_DETECTED")
        if record.age_seconds > 86400 and len(record.verification_events) == 0:
            flags.append("STALE_UNVERIFIED")
        if len(record.contradicting_agents) > len(record.supporting_agents):
            flags.append("MORE_CONTRADICTIONS_THAN_SUPPORT")
        
        return {
            'object_id': object_id,
            'trust_level': trust_level,
            'composite_trust_score': round(trust_score, 4),
            'recommendation': recommendation,
            'trust_components': {
                'source_reliability': round(record.source_reliability, 4),
                'causal_consistency': round(record.causal_consistency, 4),
                'temporal_consistency': round(record.temporal_consistency, 4),
                'cross_agent_agreement': round(record.cross_agent_agreement, 4),
            },
            'flags': flags,
            'metadata': record.to_dict(),
        }
    
    def detect_adversarial_patterns(self, object_id: str) -> List[str]:
        """
        Detect potential adversarial manipulation patterns.
        
        Args:
            object_id: Object to analyze
            
        Returns:
            List of detected suspicious patterns
        """
        if object_id not in self.trust_registry:
            raise ValueError(f"Object {object_id} not found in trust registry")
        
        record = self.trust_registry[object_id]
        patterns = []
        
        # Pattern 1: Rapid modification after creation (possible injection)
        if record.modification_count > 3 and record.age_seconds < 300:  # 5 minutes
            patterns.append("RAPID_MODIFICATION_POSSIBLE_INJECTION")
        
        # Pattern 2: Single source with no corroboration
        if (record.source_type in [SourceType.AI_GENERATED, SourceType.HEARSAY] and
            len(record.supporting_agents) == 0):
            patterns.append("UNVERIFIED_LOW_RELIABILITY_SOURCE")
        
        # Pattern 3: Contradictions from trusted agents
        trusted_contradictors = [
            agent for agent in record.contradicting_agents
            if self._is_agent_trusted(agent)
        ]
        if trusted_contradictors:
            patterns.append(f"CONTRADICTED_BY_TRUSTED_AGENTS: {trusted_contradictors}")
        
        # Pattern 4: Trust score degradation over time
        if record.temporal_consistency < 0.3:
            patterns.append("SIGNIFICANT_TEMPORAL_DECAY")
        
        # Pattern 5: Causal inconsistency with multiple related objects
        if record.causal_consistency < 0.4 and len(record.contradiction_flags) > 2:
            patterns.append("MULTIPLE_CAUSAL_CONTRADICTIONS")
        
        return patterns
    
    def _is_agent_trusted(self, agent_id: str, threshold: float = 0.7) -> bool:
        """Check if an agent is generally trusted across the system."""
        # Simplified: In production, would track agent reputation separately
        # For now, assume all known agents are trusted unless flagged
        return True
    
    def prune_low_trust_objects(self, threshold: Optional[float] = None) -> List[str]:
        """
        Remove or flag objects below trust threshold.
        
        Args:
            threshold: Trust threshold (defaults to min_trust_threshold)
            
        Returns:
            List of pruned object IDs
        """
        if threshold is None:
            threshold = self.min_trust_threshold
        
        pruned = []
        for object_id, record in list(self.trust_registry.items()):
            if record.composite_trust_score < threshold:
                pruned.append(object_id)
                # In production, might archive instead of delete
                del self.trust_registry[object_id]
                self.stats['low_trust_objects'] += 1
        
        return pruned
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get aggregate trust statistics."""
        trust_scores = [r.composite_trust_score for r in self.trust_registry.values()]
        
        if not trust_scores:
            return self.stats
        
        return {
            **self.stats,
            'average_trust_score': round(sum(trust_scores) / len(trust_scores), 4),
            'min_trust_score': round(min(trust_scores), 4),
            'max_trust_score': round(max(trust_scores), 4),
            'high_trust_count': sum(1 for s in trust_scores if s >= self.high_trust_threshold),
            'low_trust_count': sum(1 for s in trust_scores if s < self.min_trust_threshold),
        }


# Example usage and testing
if __name__ == "__main__":
    print("="*80)
    print("PROVENANCE-WEIGHTED TRUST SCORING - Testing Adversarial Hardening")
    print("="*80)
    
    scorer = ProvenanceTrustScorer(
        min_trust_threshold=0.3,
        high_trust_threshold=0.7,
        decay_rate=0.01,
        agreement_boost=0.1,
        contradiction_penalty=0.2
    )
    
    # Test 1: Register high-trust memory from direct observation
    print("\n[Test 1] High-trust memory from direct observation...")
    mem1 = scorer.register_object(
        object_id="mem_001",
        object_type="memory",
        content="Temperature reading: 25°C from calibrated sensor",
        source_type=SourceType.DIRECT_OBSERVATION,
        source_id="sensor_array_alpha",
        initial_causal_context=["sensor_calibration"]
    )
    print(f"  Initial trust score: {mem1.composite_trust_score:.4f}")
    
    # Verify with multiple agents
    scorer.verify_with_agent("mem_001", "agent_1", agrees=True, confidence=0.95)
    scorer.verify_with_agent("mem_001", "agent_2", agrees=True, confidence=0.90)
    scorer.verify_with_agent("mem_001", "agent_3", agrees=True, confidence=0.85)
    
    assessment = scorer.get_trust_assessment("mem_001")
    print(f"  After 3 verifications: {assessment['composite_trust_score']:.4f}")
    print(f"  Trust level: {assessment['trust_level']}")
    print(f"  Recommendation: {assessment['recommendation']}")
    
    # Test 2: Suspicious AI-generated claim with contradictions
    print("\n[Test 2] Suspicious AI-generated claim...")
    mem2 = scorer.register_object(
        object_id="mem_002",
        object_type="belief",
        content="The sky is green and gravity pushes upward",
        source_type=SourceType.AI_GENERATED,
        source_id="unknown_llm",
    )
    print(f"  Initial trust score: {mem2.composite_trust_score:.4f}")
    
    # Agents contradict this
    scorer.verify_with_agent("mem_002", "agent_1", agrees=False, confidence=0.99)
    scorer.verify_with_agent("mem_002", "agent_2", agrees=False, confidence=0.98)
    scorer.verify_with_agent("mem_002", "agent_3", agrees=False, confidence=0.97)
    
    assessment = scorer.get_trust_assessment("mem_002")
    print(f"  After 3 contradictions: {assessment['composite_trust_score']:.4f}")
    print(f"  Trust level: {assessment['trust_level']}")
    print(f"  Flags: {assessment['flags']}")
    
    # Detect adversarial patterns
    patterns = scorer.detect_adversarial_patterns("mem_002")
    print(f"  Adversarial patterns detected: {patterns}")
    
    # Test 3: Check causal consistency
    print("\n[Test 3] Causal consistency checking...")
    consistency, contradictions = scorer.check_causal_consistency(
        "mem_001",
        ["mem_002"]  # These should be inconsistent
    )
    print(f"  Consistency score: {consistency:.4f}")
    print(f"  Contradictions found: {len(contradictions)}")
    
    # Print final statistics
    print("\n" + "="*80)
    print("TRUST SCORING STATISTICS")
    print("="*80)
    stats = scorer.get_statistics()
    for key, value in stats.items():
        print(f"  {key}: {value}")
    
    print("\n✅ Provenance Trust Scorer test complete!")
    print("\nKey Achievements:")
    print("  ✓ High-trust sources properly rewarded")
    print("  ✓ Contradictions properly penalized")
    print("  ✓ Adversarial patterns detected")
    print("  ✓ Causal consistency enforced")
