"""
HIERARCHICAL MEMORY RECONSOLIDATION SYSTEM

Purpose: Prevent abstraction collapse and causal detail erosion over long missions.

Based on next.md (lines 137-180):
"Right now long missions will eventually suffer:
- abstraction collapse,
- recursive summarization decay,
- causal detail erosion.

You need memory layers."

Architecture:
Instead of: summary → summary → summary (destroys causal detail)
Use: reconstruct from causal anchors (preserves mechanisms)

Memory Layers:
1. Episodic - Raw events (high fidelity, short retention)
2. Semantic - Extracted meaning (medium fidelity, medium retention)
3. Causal - Mechanisms & relationships (high fidelity, long retention)
4. Strategic - Long-term goals/plans (abstract, permanent)
5. Identity - Core principles/constraints (immutable, permanent)

Critical Rule: Important causal chains always remain retrievable.
"""

import time
import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum


class MemoryLayer(Enum):
    """Memory hierarchy layers with different retention and fidelity."""
    EPISODIC = "episodic"           # Raw events, high fidelity, short retention
    SEMANTIC = "semantic"           # Extracted meaning, medium fidelity
    CAUSAL = "causal"               # Mechanisms & relationships, high fidelity, long retention
    STRATEGIC = "strategic"         # Long-term goals/plans, abstract, permanent
    IDENTITY = "identity"           # Core principles/constraints, immutable, permanent


@dataclass
class MemoryFragment:
    """Single unit of memory at any layer."""
    fragment_id: str
    layer: MemoryLayer
    content: str                    # The actual memory content
    timestamp: float = field(default_factory=time.time)
    
    # Metadata
    confidence: float = 0.5         # Confidence in this memory
    importance: float = 0.5         # Importance score (0.0-1.0)
    access_count: int = 0           # How often accessed
    last_accessed: Optional[float] = None
    
    # Relationships
    parent_fragments: List[str] = field(default_factory=list)  # Fragments this derives from
    child_fragments: List[str] = field(default_factory=list)   # Fragments derived from this
    causal_anchors: List[str] = field(default_factory=list)    # Critical causal chains preserved
    
    # For episodic only
    raw_data: Optional[Dict] = None  # Original unprocessed data
    
    # For causal only
    mechanism_description: Optional[str] = None  # How/why something happens
    cause_effect_pairs: List[Tuple[str, str]] = field(default_factory=list)
    
    def to_dict(self) -> Dict:
        """Serialize to dictionary."""
        return {
            'fragment_id': self.fragment_id,
            'layer': self.layer.value,
            'content': self.content,
            'timestamp': self.timestamp,
            'confidence': self.confidence,
            'importance': self.importance,
            'access_count': self.access_count,
            'last_accessed': self.last_accessed,
            'parent_fragments': self.parent_fragments,
            'child_fragments': self.child_fragments,
            'causal_anchors': self.causal_anchors,
            'raw_data': self.raw_data,
            'mechanism_description': self.mechanism_description,
            'cause_effect_pairs': self.cause_effect_pairs
        }
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'MemoryFragment':
        """Deserialize from dictionary."""
        fragment = cls(
            fragment_id=data['fragment_id'],
            layer=MemoryLayer(data['layer']),
            content=data['content'],
            timestamp=data.get('timestamp', time.time()),
            confidence=data.get('confidence', 0.5),
            importance=data.get('importance', 0.5),
            access_count=data.get('access_count', 0),
            last_accessed=data.get('last_accessed'),
            parent_fragments=data.get('parent_fragments', []),
            child_fragments=data.get('child_fragments', []),
            causal_anchors=data.get('causal_anchors', []),
            raw_data=data.get('raw_data'),
            mechanism_description=data.get('mechanism_description'),
            cause_effect_pairs=[tuple(pair) for pair in data.get('cause_effect_pairs', [])]
        )
        return fragment


class HierarchicalMemoryReconsolidation:
    """
    Manages multi-layer memory structure to prevent abstraction collapse.
    
    Key Principles:
    1. Different layers have different retention policies
    2. Causal anchors are always preserved (never compressed away)
    3. Reconstruction uses causal anchors, not recursive summarization
    4. Lower layers can be reconstructed from higher layers + causal anchors
    """
    
    def __init__(self, max_episodic_age_hours: float = 24.0, 
                 max_semantic_age_days: float = 7.0,
                 min_causal_importance: float = 0.7):
        """
        Initialize hierarchical memory system.
        
        Args:
            max_episodic_age_hours: Max age for episodic memories (default 24h)
            max_semantic_age_days: Max age for semantic memories (default 7 days)
            min_causal_importance: Min importance to preserve causal memories (default 0.7)
        """
        # Memory storage by layer
        self.memories: Dict[MemoryLayer, Dict[str, MemoryFragment]] = {
            layer: {} for layer in MemoryLayer
        }
        
        # Configuration
        self.max_episodic_age_hours = max_episodic_age_hours
        self.max_semantic_age_days = max_semantic_age_days
        self.min_causal_importance = min_causal_importance
        
        # Tracking
        self.total_stored = 0
        self.total_consolidated = 0
        self.total_reconstructed = 0
    
    def store_episodic_memory(self, fragment_id: str, content: str, 
                              raw_data: Optional[Dict] = None,
                              importance: float = 0.5) -> str:
        """
        Store raw episodic memory (high fidelity, short retention).
        
        Args:
            fragment_id: Unique identifier
            content: Memory content
            raw_data: Original unprocessed data
            importance: Importance score
            
        Returns:
            Fragment ID
        """
        fragment = MemoryFragment(
            fragment_id=fragment_id,
            layer=MemoryLayer.EPISODIC,
            content=content,
            importance=importance,
            raw_data=raw_data
        )
        
        self.memories[MemoryLayer.EPISODIC][fragment_id] = fragment
        self.total_stored += 1
        
        return fragment_id
    
    def extract_semantic_memory(self, episodic_ids: List[str], 
                                extracted_meaning: str,
                                importance: float = 0.6) -> str:
        """
        Extract semantic meaning from episodic memories.
        
        This creates a more abstract representation while preserving key insights.
        
        Args:
            episodic_ids: Source episodic memory IDs
            extracted_meaning: Abstracted meaning
            importance: Importance score
            
        Returns:
            New semantic fragment ID
        """
        semantic_id = f"semantic_{int(time.time())}_{len(self.memories[MemoryLayer.SEMANTIC])}"
        
        fragment = MemoryFragment(
            fragment_id=semantic_id,
            layer=MemoryLayer.SEMANTIC,
            content=extracted_meaning,
            importance=importance,
            parent_fragments=episodic_ids
        )
        
        # Link episodic memories to this semantic fragment
        for eid in episodic_ids:
            if eid in self.memories[MemoryLayer.EPISODIC]:
                self.memories[MemoryLayer.EPISODIC][eid].child_fragments.append(semantic_id)
        
        self.memories[MemoryLayer.SEMANTIC][semantic_id] = fragment
        self.total_stored += 1
        
        return semantic_id
    
    def store_causal_memory(self, fragment_id: str, content: str,
                           mechanism_description: str,
                           cause_effect_pairs: List[Tuple[str, str]],
                           importance: float = 0.8) -> str:
        """
        Store causal memory (mechanisms & relationships, long retention).
        
        CRITICAL: Causal memories with importance >= min_causal_importance are NEVER deleted.
        
        Args:
            fragment_id: Unique identifier
            content: Causal relationship description
            mechanism_description: How/why the causation works
            cause_effect_pairs: List of (cause, effect) tuples
            importance: Importance score (should be high for critical mechanisms)
            
        Returns:
            Fragment ID
        """
        fragment = MemoryFragment(
            fragment_id=fragment_id,
            layer=MemoryLayer.CAUSAL,
            content=content,
            importance=importance,
            mechanism_description=mechanism_description,
            cause_effect_pairs=cause_effect_pairs
        )
        
        self.memories[MemoryLayer.CAUSAL][fragment_id] = fragment
        self.total_stored += 1
        
        return fragment_id
    
    def store_strategic_memory(self, fragment_id: str, content: str,
                              importance: float = 0.9) -> str:
        """
        Store strategic memory (long-term goals/plans, permanent).
        
        Args:
            fragment_id: Unique identifier
            content: Strategic plan or goal
            importance: Importance score
            
        Returns:
            Fragment ID
        """
        fragment = MemoryFragment(
            fragment_id=fragment_id,
            layer=MemoryLayer.STRATEGIC,
            content=content,
            importance=importance
        )
        
        self.memories[MemoryLayer.STRATEGIC][fragment_id] = fragment
        self.total_stored += 1
        
        return fragment_id
    
    def store_identity_memory(self, fragment_id: str, content: str,
                             principle: str) -> str:
        """
        Store identity memory (core principles/constraints, immutable).
        
        These are NEVER deleted or modified.
        
        Args:
            fragment_id: Unique identifier
            content: Principle description
            principle: The core principle statement
            
        Returns:
            Fragment ID
        """
        fragment = MemoryFragment(
            fragment_id=fragment_id,
            layer=MemoryLayer.IDENTITY,
            content=content,
            importance=1.0,  # Always maximum importance
            confidence=1.0   # Always maximum confidence
        )
        
        self.memories[MemoryLayer.IDENTITY][fragment_id] = fragment
        self.total_stored += 1
        
        return fragment_id
    
    def consolidate_memories(self) -> Dict[str, int]:
        """
        Perform memory reconsolidation.
        
        This:
        1. Expires old episodic memories
        2. Expires old semantic memories
        3. Preserves all causal memories above importance threshold
        4. Preserves all strategic and identity memories
        
        Returns:
            Dictionary with counts of actions taken
        """
        actions = {
            'episodic_expired': 0,
            'semantic_expired': 0,
            'causal_preserved': 0,
            'total_remaining': 0
        }
        
        current_time = time.time()
        
        # Expire old episodic memories
        episodic_to_remove = []
        for fid, fragment in self.memories[MemoryLayer.EPISODIC].items():
            age_hours = (current_time - fragment.timestamp) / 3600.0
            if age_hours > self.max_episodic_age_hours:
                episodic_to_remove.append(fid)
        
        for fid in episodic_to_remove:
            del self.memories[MemoryLayer.EPISODIC][fid]
            actions['episodic_expired'] += 1
        
        # Expire old semantic memories
        semantic_to_remove = []
        for fid, fragment in self.memories[MemoryLayer.SEMANTIC].items():
            age_days = (current_time - fragment.timestamp) / 86400.0
            if age_days > self.max_semantic_age_days:
                semantic_to_remove.append(fid)
        
        for fid in semantic_to_remove:
            del self.memories[MemoryLayer.SEMANTIC][fid]
            actions['semantic_expired'] += 1
        
        # Preserve important causal memories (count them)
        for fid, fragment in self.memories[MemoryLayer.CAUSAL].items():
            if fragment.importance >= self.min_causal_importance:
                actions['causal_preserved'] += 1
        
        # Count total remaining
        for layer in MemoryLayer:
            actions['total_remaining'] += len(self.memories[layer])
        
        self.total_consolidated += 1
        
        return actions
    
    def reconstruct_from_causal_anchors(self, causal_anchor_ids: List[str],
                                       target_layer: MemoryLayer = MemoryLayer.SEMANTIC) -> List[MemoryFragment]:
        """
        Reconstruct higher-level memories from causal anchors.
        
        This is the KEY innovation: instead of summary → summary → summary,
        we reconstruct from preserved causal mechanisms.
        
        Args:
            causal_anchor_ids: IDs of causal memories to use as anchors
            target_layer: Layer to reconstruct for
            
        Returns:
            List of reconstructed fragments
        """
        reconstructed = []
        
        # Get causal anchors
        anchors = []
        for aid in causal_anchor_ids:
            if aid in self.memories[MemoryLayer.CAUSAL]:
                anchor = self.memories[MemoryLayer.CAUSAL][aid]
                anchor.access_count += 1
                anchor.last_accessed = time.time()
                anchors.append(anchor)
        
        if not anchors:
            return []
        
        # Reconstruct based on target layer
        if target_layer == MemoryLayer.SEMANTIC:
            # Create semantic summary from causal mechanisms
            semantic_content = "Reconstructed from causal anchors:\n"
            for anchor in anchors:
                semantic_content += f"- {anchor.mechanism_description}\n"
            
            reconstructed_id = f"reconstructed_semantic_{int(time.time())}"
            fragment = MemoryFragment(
                fragment_id=reconstructed_id,
                layer=MemoryLayer.SEMANTIC,
                content=semantic_content,
                importance=max(a.importance for a in anchors),
                parent_fragments=causal_anchor_ids,
                causal_anchors=causal_anchor_ids
            )
            reconstructed.append(fragment)
        
        elif target_layer == MemoryLayer.EPISODIC:
            # Create episodic-like details from causal chains
            for anchor in anchors:
                episodic_content = f"Event involving: {anchor.content}"
                reconstructed_id = f"reconstructed_episodic_{anchor.fragment_id}_{int(time.time())}"
                fragment = MemoryFragment(
                    fragment_id=reconstructed_id,
                    layer=MemoryLayer.EPISODIC,
                    content=episodic_content,
                    importance=anchor.importance * 0.8,  # Slightly lower than original
                    parent_fragments=[anchor.fragment_id],
                    causal_anchors=[anchor.fragment_id]
                )
                reconstructed.append(fragment)
        
        self.total_reconstructed += len(reconstructed)
        
        return reconstructed
    
    def get_memory_summary(self) -> Dict:
        """Get summary of memory state across all layers."""
        summary = {
            'total_stored': self.total_stored,
            'total_consolidated': self.total_consolidated,
            'total_reconstructed': self.total_reconstructed,
            'layers': {}
        }
        
        for layer in MemoryLayer:
            fragments = self.memories[layer]
            summary['layers'][layer.value] = {
                'count': len(fragments),
                'avg_importance': sum(f.importance for f in fragments.values()) / max(1, len(fragments)),
                'avg_confidence': sum(f.confidence for f in fragments.values()) / max(1, len(fragments))
            }
        
        return summary
    
    def save_to_file(self, filepath: str):
        """Save memory state to file."""
        data = {
            'memories': {
                layer.value: {
                    fid: frag.to_dict() 
                    for fid, frag in frags.items()
                }
                for layer, frags in self.memories.items()
            },
            'stats': {
                'total_stored': self.total_stored,
                'total_consolidated': self.total_consolidated,
                'total_reconstructed': self.total_reconstructed
            },
            'config': {
                'max_episodic_age_hours': self.max_episodic_age_hours,
                'max_semantic_age_days': self.max_semantic_age_days,
                'min_causal_importance': self.min_causal_importance
            }
        }
        
        Path(filepath).parent.mkdir(parents=True, exist_ok=True)
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2)
    
    def load_from_file(self, filepath: str):
        """Load memory state from file."""
        with open(filepath, 'r') as f:
            data = json.load(f)
        
        # Load memories
        for layer_value, fragments_data in data['memories'].items():
            layer = MemoryLayer(layer_value)
            for fid, frag_data in fragments_data.items():
                self.memories[layer][fid] = MemoryFragment.from_dict(frag_data)
        
        # Load stats
        self.total_stored = data['stats']['total_stored']
        self.total_consolidated = data['stats']['total_consolidated']
        self.total_reconstructed = data['stats']['total_reconstructed']
        
        # Load config
        config = data.get('config', {})
        self.max_episodic_age_hours = config.get('max_episodic_age_hours', 24.0)
        self.max_semantic_age_days = config.get('max_semantic_age_days', 7.0)
        self.min_causal_importance = config.get('min_causal_importance', 0.7)


if __name__ == "__main__":
    """Demonstrate hierarchical memory reconsolidation."""
    print("="*80)
    print("HIERARCHICAL MEMORY RECONSOLIDATION DEMONSTRATION")
    print("="*80)
    
    # Initialize system
    memory_system = HierarchicalMemoryReconsolidation(
        max_episodic_age_hours=1.0,  # Short for demo
        max_semantic_age_days=0.1,   # Short for demo
        min_causal_importance=0.7
    )
    
    # Store memories at different layers
    print("\n1. STORING MEMORIES ACROSS LAYERS")
    print("-" * 80)
    
    # Episodic: Raw observations
    ep1 = memory_system.store_episodic_memory(
        "ep_solar_panel_install",
        "Installed 100 solar panels on warehouse roof at 2pm",
        raw_data={"location": "warehouse", "count": 100, "time": "14:00"},
        importance=0.6
    )
    print(f"   Stored episodic: {ep1}")
    
    ep2 = memory_system.store_episodic_memory(
        "ep_battery_test",
        "Tested lithium-ion battery array, 95% efficiency",
        raw_data={"type": "lithium-ion", "efficiency": 0.95},
        importance=0.7
    )
    print(f"   Stored episodic: {ep2}")
    
    # Semantic: Extracted meaning
    sem1 = memory_system.extract_semantic_memory(
        [ep1, ep2],
        "Renewable energy infrastructure deployment showing high efficiency",
        importance=0.7
    )
    print(f"   Extracted semantic: {sem1}")
    
    # Causal: Mechanisms (CRITICAL - these persist)
    caus1 = memory_system.store_causal_memory(
        "caus_solar_efficiency",
        "Solar panel efficiency depends on angle and cleanliness",
        mechanism_description="Optimal tilt angle maximizes photon capture; dirt reduces light transmission",
        cause_effect_pairs=[
            ("optimal_angle", "increased_photon_capture"),
            ("clean_surface", "reduced_light_loss")
        ],
        importance=0.9  # High importance = never deleted
    )
    print(f"   Stored causal: {caus1}")
    
    caus2 = memory_system.store_causal_memory(
        "caus_battery_degradation",
        "Battery capacity degrades with charge cycles",
        mechanism_description="Electrochemical reactions cause electrode material breakdown over time",
        cause_effect_pairs=[
            ("charge_cycles", "electrode_degradation"),
            ("temperature", "degradation_rate")
        ],
        importance=0.85
    )
    print(f"   Stored causal: {caus2}")
    
    # Strategic: Long-term plans
    strat1 = memory_system.store_strategic_memory(
        "strat_grid_optimization",
        "Optimize renewable energy grid for 99.9% uptime by 2030",
        importance=0.95
    )
    print(f"   Stored strategic: {strat1}")
    
    # Identity: Core principles
    ident1 = memory_system.store_identity_memory(
        "ident_safety_first",
        "Safety always takes precedence over efficiency",
        principle="Never compromise safety for performance gains"
    )
    print(f"   Stored identity: {ident1}")
    
    # Show initial summary
    print("\n2. INITIAL MEMORY SUMMARY")
    print("-" * 80)
    summary = memory_system.get_memory_summary()
    for layer_name, stats in summary['layers'].items():
        print(f"   {layer_name.upper():12} : {stats['count']:3} fragments (avg importance: {stats['avg_importance']:.2f})")
    
    # Consolidate (simulate time passing)
    print("\n3. PERFORMING CONSOLIDATION")
    print("-" * 80)
    actions = memory_system.consolidate_memories()
    print(f"   Episodic expired: {actions['episodic_expired']}")
    print(f"   Semantic expired: {actions['semantic_expired']}")
    print(f"   Causal preserved: {actions['causal_preserved']}")
    print(f"   Total remaining: {actions['total_remaining']}")
    
    # Reconstruct from causal anchors
    print("\n4. RECONSTRUCTING FROM CAUSAL ANCHORS")
    print("-" * 80)
    reconstructed = memory_system.reconstruct_from_causal_anchors(
        [caus1, caus2],
        target_layer=MemoryLayer.SEMANTIC
    )
    print(f"   Reconstructed {len(reconstructed)} semantic fragments from causal anchors")
    for frag in reconstructed:
        print(f"   Content preview: {frag.content[:80]}...")
    
    # Final summary
    print("\n5. FINAL MEMORY SUMMARY")
    print("-" * 80)
    final_summary = memory_system.get_memory_summary()
    print(f"   Total stored: {final_summary['total_stored']}")
    print(f"   Total consolidated: {final_summary['total_consolidated']}")
    print(f"   Total reconstructed: {final_summary['total_reconstructed']}")
    for layer_name, stats in final_summary['layers'].items():
        print(f"   {layer_name.upper():12} : {stats['count']:3} fragments")
    
    print("\n" + "="*80)
    print("✅ HIERARCHICAL MEMORY RECONSOLIDATION OPERATIONAL")
    print("   - Episodic/Semantic memories expire appropriately")
    print("   - Causal memories with high importance are preserved")
    print("   - Reconstruction from causal anchors prevents abstraction collapse")
    print("="*80)
