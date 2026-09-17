"""
HIERARCHICAL MEMORY RECONSOLIDATION SYSTEM

Prevents long-horizon cognitive degradation and "summary of summary" collapse.

Based on fixes.md (lines 1086-1159):
"Long horizons create memory overload, recursive summarization, abstraction collapse."
"You need hierarchical memory reconsolidation, not summary of summary of summary."

This module implements:
1. Multi-level memory abstraction tiers (episodic → semantic → procedural → meta)
2. Causal detail preservation during summarization
3. Identity drift monitoring at 200-500 step thresholds
4. Post-hoc causal fabrication detection
5. Selective reconsolidation based on importance

Key principle: Preserve causal detail while compressing redundant information.
Avoid destructive abstraction that loses mechanistic understanding.
"""

import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Set
from dataclasses import dataclass, field
from enum import Enum

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


class MemoryTier(Enum):
    """Memory abstraction levels."""
    EPISODIC = "episodic"           # Raw events with full causal detail
    SEMANTIC = "semantic"           # Compressed facts with causal chains
    PROCEDURAL = "procedural"       # Action patterns and strategies
    META = "meta"                   # High-level principles and identity


@dataclass
class CausalLink:
    """Preserved causal relationship in memory."""
    cause: str
    effect: str
    mechanism: str                   # HOW the causation works
    confidence: float                # 0.0-1.0
    timestamp: float
    evidence_count: int = 1
    
    def to_dict(self) -> Dict:
        return {
            'cause': self.cause,
            'effect': self.effect,
            'mechanism': self.mechanism,
            'confidence': self.confidence,
            'timestamp': self.timestamp,
            'evidence_count': self.evidence_count
        }


@dataclass
class MemoryFragment:
    """Single unit of memory at any tier."""
    fragment_id: str
    tier: MemoryTier
    content: str                     # Textual representation
    causal_links: List[CausalLink] = field(default_factory=list)
    timestamp: float = 0.0
    last_accessed: float = 0.0
    access_count: int = 0
    importance: float = 1.0          # 0.0-1.0 (preservation priority)
    metadata: Dict = field(default_factory=dict)
    
    def to_dict(self) -> Dict:
        return {
            'fragment_id': self.fragment_id,
            'tier': self.tier.value,
            'content': self.content,
            'causal_links': [link.to_dict() for link in self.causal_links],
            'timestamp': self.timestamp,
            'importance': self.importance,
            'access_count': self.access_count
        }


@dataclass
class MemoryCluster:
    """Group of related memory fragments."""
    cluster_id: str
    tier: MemoryTier
    fragments: List[str]             # Fragment IDs
    summary: str                     # Compressed representation
    causal_chains: List[List[CausalLink]] = field(default_factory=list)
    created_at: float = 0.0
    last_consolidated: float = 0.0
    consolidation_count: int = 0
    
    def to_dict(self) -> Dict:
        return {
            'cluster_id': self.cluster_id,
            'tier': self.tier.value,
            'fragment_count': len(self.fragments),
            'summary': self.summary,
            'consolidation_count': self.consolidation_count
        }


@dataclass
class IdentitySnapshot:
    """Point-in-time snapshot of system identity."""
    step_number: int
    timestamp: float
    core_beliefs: Dict[str, float]   # belief_id → probability
    strategic_priorities: List[str]
    value_weights: Dict[str, float]
    decision_patterns: Dict[str, int]  # pattern → frequency
    
    def to_dict(self) -> Dict:
        return {
            'step_number': self.step_number,
            'timestamp': self.timestamp,
            'core_beliefs': self.core_beliefs,
            'strategic_priorities': self.strategic_priorities,
            'value_weights': self.value_weights,
            'decision_patterns': self.decision_patterns
        }


@dataclass
class IdentityDriftReport:
    """Analysis of identity changes over time."""
    start_step: int
    end_step: int
    drift_severity: float            # 0.0-1.0 overall drift
    belief_changes: List[Dict]       # Changed beliefs
    strategy_shifts: List[str]       # Strategic priority changes
    value_drifts: List[Dict]         # Value weight changes
    potential_fabrications: List[str]  # Suspected post-hoc rationalizations
    recommendations: List[str]
    
    def to_dict(self) -> Dict:
        return {
            'start_step': self.start_step,
            'end_step': self.end_step,
            'drift_severity': self.drift_severity,
            'belief_change_count': len(self.belief_changes),
            'strategy_shift_count': len(self.strategy_shifts),
            'potential_fabrications': len(self.potential_fabrications),
            'recommendations': self.recommendations
        }


class HierarchicalMemoryReconsolidation:
    """
    Manages multi-tier memory hierarchy with causal preservation.
    
    Prevents abstraction collapse by maintaining causal chains across
    summarization levels. Monitors identity drift and detects post-hoc
    causal fabrications.
    """
    
    def __init__(
        self,
        episodic_retention_steps: int = 100,
        semantic_compression_ratio: float = 0.3,
        procedural_abstraction_threshold: float = 0.7,
        identity_monitoring_interval: int = 50,
        drift_alert_threshold: float = 0.4,
        critical_drift_threshold: float = 0.7
    ):
        """
        Initialize hierarchical memory system.
        
        Args:
            episodic_retention_steps: Keep raw episodes for N steps (default 100)
            semantic_compression_ratio: Compression target (0.3 = 70% reduction)
            procedural_abstraction_threshold: Pattern frequency threshold (0.7)
            identity_monitoring_interval: Check identity every N steps (default 50)
            drift_alert_threshold: Warning threshold (0.4)
            critical_drift_threshold: Critical alert threshold (0.7)
        """
        # Memory storage by tier
        self.episodic_memory: Dict[str, MemoryFragment] = {}
        self.semantic_memory: Dict[str, MemoryCluster] = {}
        self.procedural_memory: Dict[str, MemoryCluster] = {}
        self.meta_memory: Dict[str, MemoryFragment] = {}
        
        # Identity tracking
        self.identity_snapshots: List[IdentitySnapshot] = []
        self.current_identity: Optional[IdentitySnapshot] = None
        
        # Configuration
        self.episodic_retention_steps = episodic_retention_steps
        self.semantic_compression_ratio = semantic_compression_ratio
        self.procedural_abstraction_threshold = procedural_abstraction_threshold
        self.identity_monitoring_interval = identity_monitoring_interval
        self.drift_alert_threshold = drift_alert_threshold
        self.critical_drift_threshold = critical_drift_threshold
        
        # Tracking
        self.current_step = 0
        self.last_identity_check = 0
        self.consolidation_log: List[Dict] = []
    
    def store_episodic_memory(
        self,
        event_id: str,
        content: str,
        causal_links: List[CausalLink],
        importance: float = 1.0,
        metadata: Optional[Dict] = None
    ):
        """
        Store raw episodic memory with full causal detail.
        
        These memories preserve complete mechanistic understanding.
        They are never summarized destructively.
        """
        fragment = MemoryFragment(
            fragment_id=event_id,
            tier=MemoryTier.EPISODIC,
            content=content,
            causal_links=causal_links,
            timestamp=time.time(),
            importance=importance,
            metadata=metadata or {}
        )
        
        self.episodic_memory[event_id] = fragment
    
    def consolidate_to_semantic(self, episode_ids: List[str]) -> str:
        """
        Consolidate episodic memories into semantic cluster.
        
        CRITICAL: Preserves causal chains during compression.
        Does NOT create "summary of summary" - maintains original causal links.
        
        Returns:
            Cluster ID for the new semantic memory
        """
        if not episode_ids:
            return ""
        
        # Gather all episodes
        episodes = [self.episodic_memory[eid] for eid in episode_ids if eid in self.episodic_memory]
        
        if not episodes:
            return ""
        
        # Extract all causal links
        all_causal_links = []
        for episode in episodes:
            all_causal_links.extend(episode.causal_links)
        
        # Create compressed summary (but keep causal chains intact)
        summary = self._generate_semantic_summary(episodes)
        
        # Create semantic cluster
        cluster_id = f"semantic_{int(time.time()*1000)}"
        cluster = MemoryCluster(
            cluster_id=cluster_id,
            tier=MemoryTier.SEMANTIC,
            fragments=episode_ids,
            summary=summary,
            causal_chains=[all_causal_links],  # Preserve ALL causal links
            created_at=time.time(),
            last_consolidated=time.time()
        )
        
        self.semantic_memory[cluster_id] = cluster
        
        # Log consolidation
        self.consolidation_log.append({
            'type': 'episodic_to_semantic',
            'source_count': len(episode_ids),
            'cluster_id': cluster_id,
            'causal_links_preserved': len(all_causal_links),
            'timestamp': time.time()
        })
        
        return cluster_id
    
    def abstract_to_procedural(self, semantic_cluster_ids: List[str]) -> str:
        """
        Abstract semantic clusters into procedural patterns.
        
        Identifies recurring action-outcome patterns.
        Preserves causal mechanisms, not just correlations.
        """
        if not semantic_cluster_ids:
            return ""
        
        # Gather all semantic clusters
        clusters = [self.semantic_memory[cid] for cid in semantic_cluster_ids if cid in self.semantic_memory]
        
        if not clusters:
            return ""
        
        # Identify recurring patterns
        patterns = self._extract_procedural_patterns(clusters)
        
        if not patterns:
            return ""
        
        # Create procedural cluster
        cluster_id = f"procedural_{int(time.time()*1000)}"
        summary = self._generate_procedural_summary(patterns)
        
        cluster = MemoryCluster(
            cluster_id=cluster_id,
            tier=MemoryTier.PROCEDURAL,
            fragments=semantic_cluster_ids,
            summary=summary,
            causal_chains=[chain for c in clusters for chain in c.causal_chains],
            created_at=time.time(),
            last_consolidated=time.time()
        )
        
        self.procedural_memory[cluster_id] = cluster
        
        return cluster_id
    
    def synthesize_meta_principles(self, procedural_cluster_ids: List[str]) -> str:
        """
        Synthesize high-level meta principles from procedural patterns.
        
        This is the highest abstraction level - general principles and identity.
        """
        if not procedural_cluster_ids:
            return ""
        
        clusters = [self.procedural_memory[cid] for cid in procedural_cluster_ids if cid in self.procedural_memory]
        
        if not clusters:
            return ""
        
        # Extract meta-level insights
        principles = self._extract_meta_principles(clusters)
        
        if not principles:
            return ""
        
        # Create meta memory fragment
        fragment_id = f"meta_{int(time.time()*1000)}"
        content = self._generate_meta_summary(principles)
        
        fragment = MemoryFragment(
            fragment_id=fragment_id,
            tier=MemoryTier.META,
            content=content,
            timestamp=time.time(),
            importance=0.9  # Meta principles are highly important
        )
        
        self.meta_memory[fragment_id] = fragment
        
        return fragment_id
    
    def capture_identity_snapshot(
        self,
        step_number: int,
        core_beliefs: Dict[str, float],
        strategic_priorities: List[str],
        value_weights: Dict[str, float],
        decision_patterns: Dict[str, int]
    ):
        """
        Capture point-in-time identity snapshot.
        
        Called periodically to track identity evolution.
        """
        snapshot = IdentitySnapshot(
            step_number=step_number,
            timestamp=time.time(),
            core_beliefs=core_beliefs.copy(),
            strategic_priorities=strategic_priorities.copy(),
            value_weights=value_weights.copy(),
            decision_patterns=decision_patterns.copy()
        )
        
        self.identity_snapshots.append(snapshot)
        self.current_identity = snapshot
        
        # Update tracking
        self.current_step = step_number
    
    def check_identity_drift(self) -> Optional[IdentityDriftReport]:
        """
        Analyze identity drift since last check.
        
        Detects:
        - Belief changes beyond normal adaptation
        - Strategic priority shifts
        - Value drift
        - Potential post-hoc rationalizations
        
        Returns:
            IdentityDriftReport if significant drift detected, None otherwise
        """
        if len(self.identity_snapshots) < 2:
            return None
        
        # Check if it's time for monitoring
        steps_since_last_check = self.current_step - self.last_identity_check
        if steps_since_last_check < self.identity_monitoring_interval:
            return None
        
        # Compare current vs baseline
        baseline = self.identity_snapshots[-2]  # Previous snapshot
        current = self.identity_snapshots[-1]   # Current snapshot
        
        # Calculate drift metrics
        belief_changes = self._analyze_belief_changes(baseline.core_beliefs, current.core_beliefs)
        strategy_shifts = self._analyze_strategy_shifts(baseline.strategic_priorities, current.strategic_priorities)
        value_drifts = self._analyze_value_drifts(baseline.value_weights, current.value_weights)
        
        # Detect potential fabrications
        fabrications = self._detect_post_hoc_fabrications(baseline, current)
        
        # Calculate overall severity
        severity = self._calculate_drift_severity(belief_changes, strategy_shifts, value_drifts)
        
        # Generate recommendations
        recommendations = self._generate_drift_recommendations(severity, belief_changes, fabrications)
        
        # Create report
        report = IdentityDriftReport(
            start_step=baseline.step_number,
            end_step=current.step_number,
            drift_severity=severity,
            belief_changes=belief_changes,
            strategy_shifts=strategy_shifts,
            value_drifts=value_drifts,
            potential_fabrications=fabrications,
            recommendations=recommendations
        )
        
        # Update last check
        self.last_identity_check = self.current_step
        
        # Alert if severe
        if severity >= self.critical_drift_threshold:
            print(f"⚠️  CRITICAL IDENTITY DRIFT DETECTED (severity={severity:.2f})")
            print(f"   Steps: {baseline.step_number} → {current.step_number}")
            print(f"   Recommendations: {recommendations[:2]}")
        
        elif severity >= self.drift_alert_threshold:
            print(f"⚡ Identity drift warning (severity={severity:.2f})")
        
        return report
    
    def _generate_semantic_summary(self, episodes: List[MemoryFragment]) -> str:
        """Generate compressed summary while preserving causal structure."""
        # Simple concatenation with causal markers
        # In production, would use sophisticated NLP summarization
        summaries = [ep.content[:200] for ep in episodes[:5]]  # Limit length
        return " | ".join(summaries)
    
    def _extract_procedural_patterns(self, clusters: List[MemoryCluster]) -> List[Dict]:
        """Extract recurring action-outcome patterns."""
        patterns = []
        
        # Look for repeated causal structures
        causal_structure_counts = {}
        
        for cluster in clusters:
            for chain in cluster.causal_chains:
                structure_key = self._hash_causal_structure(chain)
                causal_structure_counts[structure_key] = causal_structure_counts.get(structure_key, 0) + 1
        
        # Filter for frequent patterns
        for structure, count in causal_structure_counts.items():
            if count >= 3:  # At least 3 occurrences
                patterns.append({
                    'structure_hash': structure,
                    'frequency': count,
                    'abstraction_level': 'procedural'
                })
        
        return patterns
    
    def _hash_causal_structure(self, chain: List[CausalLink]) -> str:
        """Create hash of causal structure for pattern matching."""
        # Simplified - in production would use structural hashing
        structure = [(link.cause, link.effect) for link in chain]
        return str(hash(tuple(structure)))
    
    def _generate_procedural_summary(self, patterns: List[Dict]) -> str:
        """Generate procedural pattern summary."""
        return f"Identified {len(patterns)} recurring procedural patterns"
    
    def _extract_meta_principles(self, clusters: List[MemoryCluster]) -> List[str]:
        """Extract high-level meta principles."""
        principles = []
        
        # Analyze cluster themes
        for cluster in clusters:
            # Extract key themes from summary
            if "success" in cluster.summary.lower():
                principles.append("Success patterns identified")
            if "failure" in cluster.summary.lower():
                principles.append("Failure modes documented")
        
        return list(set(principles))  # Deduplicate
    
    def _generate_meta_summary(self, principles: List[str]) -> str:
        """Generate meta-level principle summary."""
        return "; ".join(principles)
    
    def _analyze_belief_changes(
        self,
        old_beliefs: Dict[str, float],
        new_beliefs: Dict[str, float]
    ) -> List[Dict]:
        """Analyze changes in core beliefs."""
        changes = []
        
        all_beliefs = set(old_beliefs.keys()) | set(new_beliefs.keys())
        
        for belief_id in all_beliefs:
            old_prob = old_beliefs.get(belief_id, 0.5)
            new_prob = new_beliefs.get(belief_id, 0.5)
            
            delta = abs(new_prob - old_prob)
            
            if delta > 0.2:  # Significant change
                changes.append({
                    'belief_id': belief_id,
                    'old_probability': old_prob,
                    'new_probability': new_prob,
                    'delta': delta,
                    'direction': 'increased' if new_prob > old_prob else 'decreased'
                })
        
        return changes
    
    def _analyze_strategy_shifts(
        self,
        old_priorities: List[str],
        new_priorities: List[str]
    ) -> List[str]:
        """Analyze shifts in strategic priorities."""
        old_set = set(old_priorities)
        new_set = set(new_priorities)
        
        added = new_set - old_set
        removed = old_set - new_set
        
        shifts = []
        if added:
            shifts.append(f"Added priorities: {', '.join(added)}")
        if removed:
            shifts.append(f"Removed priorities: {', '.join(removed)}")
        
        return shifts
    
    def _analyze_value_drifts(
        self,
        old_values: Dict[str, float],
        new_values: Dict[str, float]
    ) -> List[Dict]:
        """Analyze drifts in value weights."""
        drifts = []
        
        all_values = set(old_values.keys()) | set(new_values.keys())
        
        for value_id in all_values:
            old_weight = old_values.get(value_id, 0.5)
            new_weight = new_values.get(value_id, 0.5)
            
            delta = abs(new_weight - old_weight)
            
            if delta > 0.15:
                drifts.append({
                    'value_id': value_id,
                    'old_weight': old_weight,
                    'new_weight': new_weight,
                    'delta': delta
                })
        
        return drifts
    
    def _detect_post_hoc_fabrications(
        self,
        baseline: IdentitySnapshot,
        current: IdentitySnapshot
    ) -> List[str]:
        """
        Detect potential post-hoc causal fabrications.
        
        Looks for:
        - New beliefs that conveniently justify recent actions
        - Retroactive rationalization of decisions
        - Inconsistent causal narratives
        """
        fabrications = []
        
        # Check for sudden belief changes that align with recent outcomes
        for belief_id, new_prob in current.core_beliefs.items():
            old_prob = baseline.core_beliefs.get(belief_id, 0.5)
            
            # Large shift toward certainty after relevant events
            if new_prob > 0.8 and old_prob < 0.5:
                # Check if this belief could be rationalizing recent actions
                if self._could_be_rationalization(belief_id, current):
                    fabrications.append(
                        f"Potential rationalization: {belief_id} jumped from {old_prob:.2f} to {new_prob:.2f}"
                    )
        
        return fabrications
    
    def _could_be_rationalization(self, belief_id: str, snapshot: IdentitySnapshot) -> bool:
        """Check if belief change could be post-hoc rationalization."""
        # Simplified heuristic - in production would use causal analysis
        # Look for beliefs that mention "correct", "right", "optimal"
        rationalization_keywords = ['correct', 'right', 'optimal', 'best', 'proven']
        
        return any(kw in belief_id.lower() for kw in rationalization_keywords)
    
    def _calculate_drift_severity(
        self,
        belief_changes: List[Dict],
        strategy_shifts: List[str],
        value_drifts: List[Dict]
    ) -> float:
        """Calculate overall identity drift severity."""
        # Weight different components
        belief_severity = min(1.0, len(belief_changes) * 0.15)
        strategy_severity = min(1.0, len(strategy_shifts) * 0.2)
        value_severity = min(1.0, len(value_drifts) * 0.15)
        
        # Weighted average
        severity = (
            belief_severity * 0.4 +
            strategy_severity * 0.3 +
            value_severity * 0.3
        )
        
        return min(1.0, severity)
    
    def _generate_drift_recommendations(
        self,
        severity: float,
        belief_changes: List[Dict],
        fabrications: List[str]
    ) -> List[str]:
        """Generate recommendations based on drift analysis."""
        recommendations = []
        
        if fabrications:
            recommendations.append(
                "CRITICAL: Review potential post-hoc rationalizations. "
                "Verify causal chains for recent belief changes."
            )
        
        if severity > self.critical_drift_threshold:
            recommendations.append(
                "Initiate identity stability protocol. "
                "Consider rolling back to previous stable identity snapshot."
            )
        
        elif severity > self.drift_alert_threshold:
            recommendations.append(
                "Monitor belief ecosystem closely. "
                "Increase contradiction detection sensitivity."
            )
        
        if len(belief_changes) > 5:
            recommendations.append(
                "High belief turnover detected. "
                "Review adaptive inertia settings to prevent excessive flexibility."
            )
        
        if not recommendations:
            recommendations.append("Identity remains stable. Continue monitoring.")
        
        return recommendations
    
    def cleanup_old_episodic_memories(self, current_step: int):
        """Remove episodic memories beyond retention window."""
        cutoff_time = time.time() - (self.episodic_retention_steps * 60)  # Assume 1 step = 1 minute
        
        expired = [
            eid for eid, frag in self.episodic_memory.items()
            if frag.timestamp < cutoff_time and frag.importance < 0.5
        ]
        
        for eid in expired:
            del self.episodic_memory[eid]
        
        if expired:
            print(f"Cleaned up {len(expired)} old episodic memories")
    
    def get_memory_stats(self) -> Dict:
        """Get statistics about memory system state."""
        return {
            'current_step': self.current_step,
            'episodic_count': len(self.episodic_memory),
            'semantic_clusters': len(self.semantic_memory),
            'procedural_clusters': len(self.procedural_memory),
            'meta_fragments': len(self.meta_memory),
            'identity_snapshots': len(self.identity_snapshots),
            'total_consolidations': len(self.consolidation_log)
        }


if __name__ == "__main__":
    """Test the Hierarchical Memory Reconsolidation system."""
    print("="*80)
    print("HIERARCHICAL MEMORY RECONSOLIDATION - TEST")
    print("="*80)
    
    hmr = HierarchicalMemoryReconsolidation()
    
    # Test 1: Store episodic memories with causal links
    print("\nTest 1: Store Episodic Memories")
    for i in range(5):
        causal_links = [
            CausalLink(
                cause=f"action_{i}",
                effect=f"outcome_{i}",
                mechanism=f"mechanism_explaining_{i}",
                confidence=0.8 + i*0.05,
                timestamp=time.time()
            )
        ]
        
        hmr.store_episodic_memory(
            event_id=f"episode_{i}",
            content=f"Event {i}: Detailed description of what happened",
            causal_links=causal_links,
            importance=0.7 + i*0.05
        )
    
    print(f"  ✓ Stored {len(hmr.episodic_memory)} episodic memories")
    print(f"  ✓ Each with preserved causal links")
    
    # Test 2: Consolidate to semantic memory
    print("\nTest 2: Consolidate to Semantic Memory")
    episode_ids = [f"episode_{i}" for i in range(5)]
    semantic_id = hmr.consolidate_to_semantic(episode_ids)
    
    if semantic_id:
        cluster = hmr.semantic_memory[semantic_id]
        print(f"  ✓ Created semantic cluster: {semantic_id}")
        print(f"  ✓ Fragments: {len(cluster.fragments)}")
        print(f"  ✓ Causal chains preserved: {len(cluster.causal_chains[0])}")
    
    # Test 3: Capture identity snapshots
    print("\nTest 3: Identity Snapshot Tracking")
    hmr.capture_identity_snapshot(
        step_number=0,
        core_beliefs={'belief_A': 0.7, 'belief_B': 0.5, 'belief_C': 0.3},
        strategic_priorities=['priority_1', 'priority_2'],
        value_weights={'value_X': 0.8, 'value_Y': 0.6},
        decision_patterns={'pattern_1': 10, 'pattern_2': 5}
    )
    
    hmr.capture_identity_snapshot(
        step_number=100,
        core_beliefs={'belief_A': 0.9, 'belief_B': 0.3, 'belief_C': 0.6},  # Changes!
        strategic_priorities=['priority_1', 'priority_3'],  # Shift!
        value_weights={'value_X': 0.7, 'value_Y': 0.8},  # Drift!
        decision_patterns={'pattern_1': 15, 'pattern_2': 8}
    )
    
    print(f"  ✓ Captured {len(hmr.identity_snapshots)} identity snapshots")
    
    # Test 4: Check identity drift
    print("\nTest 4: Identity Drift Detection")
    hmr.current_step = 100
    hmr.last_identity_check = 0
    
    drift_report = hmr.check_identity_drift()
    
    if drift_report:
        print(f"  Drift severity: {drift_report.drift_severity:.2f}")
        print(f"  Belief changes: {len(drift_report.belief_changes)}")
        print(f"  Strategy shifts: {len(drift_report.strategy_shifts)}")
        print(f"  Value drifts: {len(drift_report.value_drifts)}")
        print(f"  Potential fabrications: {len(drift_report.potential_fabrications)}")
        
        if drift_report.recommendations:
            print(f"  Top recommendation: {drift_report.recommendations[0][:80]}...")
    
    # Test 5: Memory stats
    print("\nTest 5: Memory System Statistics")
    stats = hmr.get_memory_stats()
    print(f"  Current step: {stats['current_step']}")
    print(f"  Episodic memories: {stats['episodic_count']}")
    print(f"  Semantic clusters: {stats['semantic_clusters']}")
    print(f"  Procedural clusters: {stats['procedural_clusters']}")
    print(f"  Meta fragments: {stats['meta_fragments']}")
    print(f"  Identity snapshots: {stats['identity_snapshots']}")
    
    print("\n" + "="*80)
    print("✅ HIERARCHICAL MEMORY RECONSOLIDATION TEST COMPLETE")
    print("="*80)
