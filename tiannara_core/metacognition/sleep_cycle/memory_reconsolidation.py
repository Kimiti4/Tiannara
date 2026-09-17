"""
MEMORY RECONSOLIDATION CYCLES - Sleep-Inspired Contradiction Resolution

Purpose: Resolve accumulated contradictions, compress redundant memories,
reconcile conflicting beliefs, and decay stale information through periodic
"sleep cycles" inspired by biological memory consolidation.

Based on audit.md recommendation for temporal coherence hardening.

Addresses remaining weaknesses in Temporal Coherence audit (4/5):
- Slow contradiction accumulation (unresolved conflicts build up)
- Stale assumptions (outdated beliefs persist)
- Unresolved historical conflicts (memory fragmentation)

Architecture:
sleep_cycle/
├── contradiction_resolver.py      # Find and resolve conflicting memories
├── memory_compressor.py           # Compress redundant information
├── narrative_synthesizer.py       # Create coherent story from fragments
├── stale_memory_decay.py          # Fade unused/obsolete memories
└── belief_reconciliation.py       # Update beliefs based on new evidence
"""

import time
from typing import Dict, Any, Optional, List, Tuple, Set
from dataclasses import dataclass, field
from enum import Enum


class ReconciliationAction(Enum):
    """Actions taken during belief reconciliation."""
    MERGE = "merge"                    # Combine compatible beliefs
    SUPPRESS = "suppress"              # Suppress weaker contradictory belief
    FLAG = "flag"                      # Flag for human review
    DELETE = "delete"                  # Remove obsolete/stale memory
    UPDATE = "update"                  # Update with newer evidence
    SPLIT = "split"                    # Split into context-specific beliefs


@dataclass
class ContradictionPair:
    """Represents a detected contradiction between two memories/beliefs."""
    memory_a_id: str
    memory_b_id: str
    contradiction_type: str  # 'direct', 'causal', 'temporal', 'logical'
    severity: float  # 0.0 - 1.0 (higher = more severe)
    detection_timestamp: float = field(default_factory=time.time)
    resolution_action: Optional[ReconciliationAction] = None
    resolution_timestamp: Optional[float] = None
    confidence: float = 0.8  # Confidence in contradiction detection


@dataclass
class MemoryCluster:
    """Group of related memories that can be compressed/synthesized."""
    cluster_id: str
    member_ids: List[str]
    theme: str  # Common topic/theme
    redundancy_score: float  # 0.0 - 1.0 (higher = more redundant)
    synthesis_available: bool = False
    synthesized_summary: Optional[str] = None
    created_at: float = field(default_factory=time.time)


@dataclass
class SleepCycleReport:
    """Comprehensive report of sleep cycle operations."""
    cycle_id: str
    start_time: float
    end_time: float
    duration_seconds: float
    
    # Statistics
    memories_processed: int = 0
    contradictions_found: int = 0
    contradictions_resolved: int = 0
    memories_compressed: int = 0
    memories_decayed: int = 0
    beliefs_reconciled: int = 0
    narratives_synthesized: int = 0
    
    # Quality metrics
    coherence_improvement: float = 0.0
    redundancy_reduction: float = 0.0
    contradiction_resolution_rate: float = 0.0
    
    # Actions taken
    actions_taken: List[Dict[str, Any]] = field(default_factory=list)
    
    @property
    def elapsed_time(self) -> float:
        return self.end_time - self.start_time


class ContradictionResolver:
    """Detects and resolves contradictions between memories/beliefs."""
    
    def __init__(self, trust_scorer=None):
        """
        Initialize contradiction resolver.
        
        Args:
            trust_scorer: Optional ProvenanceTrustScorer for trust-weighted resolution
        """
        self.trust_scorer = trust_scorer
        self.detected_contradictions: List[ContradictionPair] = []
        self.resolution_history: List[Dict[str, Any]] = []
        
        # PERFORMANCE OPTIMIZATION: Sparse consolidation tracking
        self.stability_threshold = 0.95  # Memories above this are considered stable
        self.volatile_memory_cache: set = set()  # Cache of recently modified memories
    
    def detect_contradictions(
        self,
        memory_registry: Dict[str, Any],
        similarity_threshold: float = 0.7
    ) -> List[ContradictionPair]:
        """
        Scan memory registry for contradictions.
        
        Args:
            memory_registry: Dictionary of memory_id -> memory_data
            similarity_threshold: Threshold for considering memories related
            
        Returns:
            List of detected contradiction pairs
        """
        contradictions = []
        memory_ids = list(memory_registry.keys())
        
        # Compare all pairs (optimized: only compare related memories)
        for i in range(len(memory_ids)):
            for j in range(i + 1, len(memory_ids)):
                mem_a_id = memory_ids[i]
                mem_b_id = memory_ids[j]
                
                mem_a = memory_registry[mem_a_id]
                mem_b = memory_registry[mem_b_id]
                
                # Check for direct contradictions
                if self._are_contradictory(mem_a, mem_b, similarity_threshold):
                    severity = self._calculate_contradiction_severity(mem_a, mem_b)
                    
                    contradiction = ContradictionPair(
                        memory_a_id=mem_a_id,
                        memory_b_id=mem_b_id,
                        contradiction_type=self._classify_contradiction(mem_a, mem_b),
                        severity=severity
                    )
                    contradictions.append(contradiction)
        
        self.detected_contradictions.extend(contradictions)
        return contradictions
    
    def detect_contradictions_sparse(
        self,
        memory_registry: Dict[str, Any],
        similarity_threshold: float = 0.7
    ) -> List[ContradictionPair]:
        """
        PERFORMANCE OPTIMIZATION: Sparse contradiction detection.
        
        Instead of O(N^2) pairwise comparison of ALL memories, only compare:
        - Volatile memories (recently modified)
        - Memories with unresolved contradictions
        - High-centrality memories
        
        This reduces complexity from O(N^2) to O(K^2) where K << N.
        
        Args:
            memory_registry: Dictionary of memory_id -> memory_data
            similarity_threshold: Threshold for considering memories related
            
        Returns:
            List of detected contradiction pairs
        """
        contradictions = []
        
        # PERFORMANCE OPTIMIZATION: Identify volatile subset
        volatile_memories = self._identify_volatile_memories(memory_registry)
        
        if not volatile_memories:
            print("✅ No volatile memories - skipping contradiction detection")
            return []
        
        print(f"🔍 Sparse detection: Processing {len(volatile_memories)} volatile memories out of {len(memory_registry)} total")
        
        # Only compare volatile memories against all others (not all-vs-all)
        volatile_ids = list(volatile_memories.keys())
        all_ids = list(memory_registry.keys())
        
        for vol_id in volatile_ids:
            vol_mem = volatile_memories[vol_id]
            
            for other_id in all_ids:
                if other_id == vol_id:
                    continue
                
                other_mem = memory_registry[other_id]
                
                # Check for direct contradictions
                if self._are_contradictory(vol_mem, other_mem, similarity_threshold):
                    severity = self._calculate_contradiction_severity(vol_mem, other_mem)
                    
                    contradiction = ContradictionPair(
                        memory_a_id=vol_id,
                        memory_b_id=other_id,
                        contradiction_type=self._classify_contradiction(vol_mem, other_mem),
                        severity=severity
                    )
                    contradictions.append(contradiction)
        
        self.detected_contradictions.extend(contradictions)
        return contradictions
    
    def _identify_volatile_memories(self, memory_registry: Dict[str, Any]) -> Dict[str, Any]:
        """
        PERFORMANCE OPTIMIZATION: Identify volatile (unstable) memories.
        
        A memory is volatile if:
        - Recently modified (within last N cycles)
        - Has low confidence or high variance
        - Has unresolved contradictions
        - Is high-centrality (affects many other memories)
        """
        volatile = {}
        current_time = time.time()
        
        for mem_id, memory in memory_registry.items():
            is_volatile = False
            
            # Check 1: Recently modified
            if hasattr(memory, 'last_modified'):
                age = current_time - memory.last_modified
                if age < 3600:  # Modified within last hour
                    is_volatile = True
            
            # Check 2: Low confidence or high variance
            if hasattr(memory, 'confidence'):
                if memory.confidence < self.stability_threshold:
                    is_volatile = True
            
            # Check 3: Has contradictions
            if hasattr(memory, 'contradiction_count'):
                if memory.contradiction_count > 0:
                    is_volatile = True
            
            # Check 4: High centrality (many connections)
            if hasattr(memory, 'connection_count'):
                if memory.connection_count > 10:  # Highly connected
                    is_volatile = True
            
            if is_volatile:
                volatile[mem_id] = memory
                self.volatile_memory_cache.add(mem_id)
        
        return volatile
    
    def resolve_contradiction(
        self,
        contradiction: ContradictionPair,
        memory_registry: Dict[str, Any]
    ) -> Tuple[ReconciliationAction, str]:
        """
        Resolve a single contradiction using trust-weighted logic.
        
        Args:
            contradiction: The contradiction to resolve
            memory_registry: Current memory state
            
        Returns:
            Tuple of (action_taken, explanation)
        """
        mem_a = memory_registry.get(contradiction.memory_a_id)
        mem_b = memory_registry.get(contradiction.memory_b_id)
        
        if not mem_a or not mem_b:
            return ReconciliationAction.DELETE, "One or both memories missing"
        
        # Get trust scores if available
        trust_a = self._get_trust_score(mem_a) if self.trust_scorer else 0.5
        trust_b = self._get_trust_score(mem_b) if self.trust_scorer else 0.5
        
        # Decision logic based on trust differential
        trust_diff = abs(trust_a - trust_b)
        
        if trust_diff > 0.3:
            # Large trust difference - suppress lower-trust memory
            if trust_a > trust_b:
                action = ReconciliationAction.SUPPRESS
                explanation = f"Suppressed {contradiction.memory_b_id} (trust {trust_b:.2f}) in favor of {contradiction.memory_a_id} (trust {trust_a:.2f})"
                self._suppress_memory(contradiction.memory_b_id, memory_registry)
            else:
                action = ReconciliationAction.SUPPRESS
                explanation = f"Suppressed {contradiction.memory_a_id} (trust {trust_a:.2f}) in favor of {contradiction.memory_b_id} (trust {trust_b:.2f})"
                self._suppress_memory(contradiction.memory_a_id, memory_registry)
        
        elif contradiction.contradiction_type == 'temporal':
            # Temporal contradictions - keep newer evidence
            age_a = time.time() - mem_a.get('creation_timestamp', 0)
            age_b = time.time() - mem_b.get('creation_timestamp', 0)
            
            if age_a < age_b:
                action = ReconciliationAction.UPDATE
                explanation = f"Updated older memory with newer evidence"
                self._merge_into_newer(contradiction.memory_b_id, contradiction.memory_a_id, memory_registry)
            else:
                action = ReconciliationAction.UPDATE
                explanation = f"Updated older memory with newer evidence"
                self._merge_into_newer(contradiction.memory_a_id, contradiction.memory_b_id, memory_registry)
        
        elif contradiction.severity < 0.5:
            # Low severity - flag for human review
            action = ReconciliationAction.FLAG
            explanation = f"Low-severity contradiction flagged for manual review"
        
        else:
            # High severity, similar trust - split into context-specific beliefs
            action = ReconciliationAction.SPLIT
            explanation = f"Split into context-specific beliefs to preserve both perspectives"
            self._split_belief(contradiction, memory_registry)
        
        # Record resolution
        contradiction.resolution_action = action
        contradiction.resolution_timestamp = time.time()
        
        self.resolution_history.append({
            'contradiction': contradiction,
            'action': action,
            'explanation': explanation,
            'timestamp': time.time()
        })
        
        return action, explanation
    
    def _are_contradictory(self, mem_a: Dict, mem_b: Dict, threshold: float) -> bool:
        """Check if two memories are contradictory."""
        # Simplified contradiction detection
        # In production, would use NLP semantic analysis
        
        # Direct content contradiction
        if mem_a.get('content') and mem_b.get('content'):
            content_a = mem_a['content'].lower()
            content_b = mem_b['content'].lower()
            
            # Check for negation patterns
            negation_words = ['not', 'no', 'never', 'false', 'incorrect']
            has_negation_a = any(word in content_a for word in negation_words)
            has_negation_b = any(word in content_b for word in negation_words)
            
            # If one has negation and they share key terms, likely contradictory
            if has_negation_a != has_negation_b:
                shared_terms = set(content_a.split()) & set(content_b.split())
                if len(shared_terms) > 2:  # Significant overlap
                    return True
        
        # Trust-based contradiction (if agents disagree)
        if self.trust_scorer:
            agents_a = set(mem_a.get('supporting_agents', []))
            agents_b = set(mem_b.get('contradicting_agents', []))
            if agents_a & agents_b:  # Same agent supports one, contradicts other
                return True
        
        return False
    
    def _calculate_contradiction_severity(self, mem_a: Dict, mem_b: Dict) -> float:
        """Calculate severity of contradiction (0.0 - 1.0)."""
        severity = 0.5  # Base severity
        
        # Increase severity if high-trust sources conflict
        if self.trust_scorer:
            trust_a = self._get_trust_score(mem_a)
            trust_b = self._get_trust_score(mem_b)
            if trust_a > 0.7 and trust_b > 0.7:
                severity += 0.3  # High-trust contradiction is severe
        
        # Increase severity if many agents involved
        agents_involved = len(set(mem_a.get('supporting_agents', [])) | 
                             set(mem_b.get('supporting_agents', [])))
        if agents_involved > 5:
            severity += 0.2
        
        return min(1.0, severity)
    
    def _classify_contradiction(self, mem_a: Dict, mem_b: Dict) -> str:
        """Classify type of contradiction."""
        if mem_a.get('object_type') == 'belief' and mem_b.get('object_type') == 'belief':
            return 'logical'
        elif 'timestamp' in mem_a and 'timestamp' in mem_b:
            return 'temporal'
        elif 'causal_context' in mem_a or 'causal_context' in mem_b:
            return 'causal'
        else:
            return 'direct'
    
    def _get_trust_score(self, memory: Dict) -> float:
        """Get trust score for memory."""
        if self.trust_scorer and 'object_id' in memory:
            try:
                assessment = self.trust_scorer.get_trust_assessment(memory['object_id'])
                return assessment.get('composite_trust_score', 0.5)
            except:
                return 0.5
        return memory.get('trust_score', 0.5)
    
    def _suppress_memory(self, memory_id: str, registry: Dict):
        """Suppress a memory (mark as inactive but don't delete)."""
        if memory_id in registry:
            registry[memory_id]['status'] = 'suppressed'
            registry[memory_id]['suppression_reason'] = 'contradiction_resolution'
    
    def _merge_into_newer(self, older_id: str, newer_id: str, registry: Dict):
        """Merge older memory content into newer memory."""
        if older_id in registry and newer_id in registry:
            older_content = registry[older_id].get('content', '')
            registry[newer_id]['content'] += f"\n[Historical context: {older_content}]"
            registry[older_id]['status'] = 'archived'
    
    def _split_belief(self, contradiction: ContradictionPair, registry: Dict):
        """Split contradictory belief into context-specific versions."""
        # In production, would create contextual variants
        # For now, just flag both for review
        if contradiction.memory_a_id in registry:
            registry[contradiction.memory_a_id]['requires_context_split'] = True
        if contradiction.memory_b_id in registry:
            registry[contradiction.memory_b_id]['requires_context_split'] = True


class MemoryCompressor:
    """Compresses redundant memories while preserving essential information."""
    
    def __init__(self):
        self.compression_clusters: List[MemoryCluster] = []
    
    def find_redundant_clusters(
        self,
        memory_registry: Dict[str, Any],
        redundancy_threshold: float = 0.8
    ) -> List[MemoryCluster]:
        """
        Identify clusters of redundant memories.
        
        Args:
            memory_registry: Dictionary of memory_id -> memory_data
            redundancy_threshold: Similarity threshold for clustering
            
        Returns:
            List of memory clusters with high redundancy
        """
        clusters = []
        processed = set()
        memory_ids = list(memory_registry.keys())
        
        for i in range(len(memory_ids)):
            if memory_ids[i] in processed:
                continue
            
            cluster_members = [memory_ids[i]]
            theme = memory_registry[memory_ids[i]].get('theme', 'general')
            
            # Find similar memories
            for j in range(i + 1, len(memory_ids)):
                if memory_ids[j] in processed:
                    continue
                
                similarity = self._calculate_similarity(
                    memory_registry[memory_ids[i]],
                    memory_registry[memory_ids[j]]
                )
                
                if similarity >= redundancy_threshold:
                    cluster_members.append(memory_ids[j])
                    processed.add(memory_ids[j])
            
            if len(cluster_members) > 1:
                cluster = MemoryCluster(
                    cluster_id=f"cluster_{len(clusters)}",
                    member_ids=cluster_members,
                    theme=theme,
                    redundancy_score=self._calculate_cluster_redundancy(
                        cluster_members, memory_registry
                    )
                )
                clusters.append(cluster)
                processed.add(memory_ids[i])
        
        self.compression_clusters = clusters
        return clusters
    
    def compress_cluster(
        self,
        cluster: MemoryCluster,
        memory_registry: Dict[str, Any]
    ) -> Optional[str]:
        """
        Compress a cluster of redundant memories into a summary.
        
        Args:
            cluster: Memory cluster to compress
            memory_registry: Current memory state
            
        Returns:
            ID of synthesized memory, or None if compression failed
        """
        if len(cluster.member_ids) < 2:
            return None
        
        # Extract key information from all members
        contents = []
        timestamps = []
        
        for mem_id in cluster.member_ids:
            if mem_id in memory_registry:
                mem = memory_registry[mem_id]
                contents.append(mem.get('content', ''))
                timestamps.append(mem.get('creation_timestamp', 0))
        
        if not contents:
            return None
        
        # Create synthesized summary
        synthesized_content = self._synthesize_summary(contents, cluster.theme)
        
        # Create new compressed memory
        compressed_id = f"compressed_{cluster.cluster_id}"
        memory_registry[compressed_id] = {
            'object_id': compressed_id,
            'object_type': 'synthesized_memory',
            'content': synthesized_content,
            'theme': cluster.theme,
            'source_members': cluster.member_ids,
            'creation_timestamp': max(timestamps),
            'compression_ratio': len(cluster.member_ids),
            'status': 'active'
        }
        
        # Mark original members as compressed
        for mem_id in cluster.member_ids:
            if mem_id in memory_registry:
                memory_registry[mem_id]['status'] = 'compressed'
                memory_registry[mem_id]['compressed_into'] = compressed_id
        
        cluster.synthesis_available = True
        cluster.synthesized_summary = synthesized_content
        
        return compressed_id
    
    def _calculate_similarity(self, mem_a: Dict, mem_b: Dict) -> float:
        """Calculate similarity between two memories."""
        content_a = mem_a.get('content', '').lower()
        content_b = mem_b.get('content', '').lower()
        
        if not content_a or not content_b:
            return 0.0
        
        # Simple word overlap similarity
        words_a = set(content_a.split())
        words_b = set(content_b.split())
        
        if not words_a or not words_b:
            return 0.0
        
        intersection = words_a & words_b
        union = words_a | words_b
        
        return len(intersection) / len(union) if union else 0.0
    
    def _calculate_cluster_redundancy(self, member_ids: List[str], registry: Dict) -> float:
        """Calculate average redundancy within cluster."""
        if len(member_ids) < 2:
            return 0.0
        
        similarities = []
        for i in range(len(member_ids)):
            for j in range(i + 1, len(member_ids)):
                sim = self._calculate_similarity(
                    registry.get(member_ids[i], {}),
                    registry.get(member_ids[j], {})
                )
                similarities.append(sim)
        
        return sum(similarities) / len(similarities) if similarities else 0.0
    
    def _synthesize_summary(self, contents: List[str], theme: str) -> str:
        """Create summary from multiple similar contents."""
        # Simple synthesis: extract common elements
        if not contents:
            return ""
        
        # Take the longest content as base (usually most detailed)
        base_content = max(contents, key=len)
        
        # Add note about compression
        summary = f"[Synthesized from {len(contents)} related memories]\n{base_content}"
        
        return summary


class StaleMemoryDecay:
    """Implements time-based decay for unused/obsolete memories."""
    
    def __init__(
        self,
        decay_rate: float = 0.05,  # Per day
        half_life_days: float = 30,
        min_retention_score: float = 0.1
    ):
        """
        Initialize decay controller.
        
        Args:
            decay_rate: Daily decay rate
            half_life_days: Days until memory strength halves
            min_retention_score: Minimum score before archival/deletion
        """
        self.decay_rate = decay_rate
        self.half_life_days = half_life_days
        self.min_retention_score = min_retention_score
    
    def apply_decay(
        self,
        memory_registry: Dict[str, Any],
        current_time: Optional[float] = None
    ) -> List[str]:
        """
        Apply temporal decay to all memories.
        
        Args:
            memory_registry: Dictionary of memory_id -> memory_data
            current_time: Current timestamp (defaults to now)
            
        Returns:
            List of memory IDs that fell below retention threshold
        """
        if current_time is None:
            current_time = time.time()
        
        decayed_memories = []
        
        for mem_id, memory in memory_registry.items():
            # Skip already archived/compressed memories
            if memory.get('status') in ['archived', 'compressed', 'suppressed']:
                continue
            
            # Calculate age
            creation_time = memory.get('creation_timestamp', current_time)
            age_days = (current_time - creation_time) / 86400  # Convert to days
            
            # Get current retention score
            retention_score = memory.get('retention_score', 1.0)
            
            # Apply exponential decay
            decay_factor = 2 ** (-age_days / self.half_life_days)
            new_retention_score = retention_score * decay_factor
            
            # Boost if recently accessed
            last_accessed = memory.get('last_accessed', creation_time)
            days_since_access = (current_time - last_accessed) / 86400
            if days_since_access < 1:  # Accessed today
                new_retention_score = min(1.0, new_retention_score + 0.1)
            
            # Update memory
            memory['retention_score'] = new_retention_score
            memory['age_days'] = age_days
            
            # Check if below threshold
            if new_retention_score < self.min_retention_score:
                decayed_memories.append(mem_id)
                memory['status'] = 'pending_archival'
        
        return decayed_memories
    
    def archive_memories(
        self,
        memory_ids: List[str],
        memory_registry: Dict[str, Any],
        archive_storage: Optional[Dict] = None
    ) -> int:
        """
        Archive decayed memories to long-term storage.
        
        Args:
            memory_ids: IDs of memories to archive
            memory_registry: Active memory registry
            archive_storage: Optional external archive storage
            
        Returns:
            Number of memories archived
        """
        archived_count = 0
        
        for mem_id in memory_ids:
            if mem_id in memory_registry:
                memory = memory_registry[mem_id]
                
                # Move to archive
                if archive_storage is not None:
                    archive_storage[mem_id] = memory
                
                # Remove from active registry
                del memory_registry[mem_id]
                archived_count += 1
        
        return archived_count


class MemoryReconsolidationEngine:
    """
    Main engine orchestrating sleep-cycle memory reconsolidation.
    
    Combines contradiction resolution, compression, decay, and synthesis
    into periodic maintenance cycles.
    """
    
    def __init__(self, trust_scorer=None):
        """
        Initialize reconsolidation engine.
        
        Args:
            trust_scorer: Optional ProvenanceTrustScorer for trust-weighted operations
        """
        self.trust_scorer = trust_scorer
        self.contradiction_resolver = ContradictionResolver(trust_scorer)
        self.memory_compressor = MemoryCompressor()
        self.stale_decay = StaleMemoryDecay()
        
        self.sleep_history: List[SleepCycleReport] = []
        self.cycle_count = 0
    
    def run_sleep_cycle(
        self,
        memory_registry: Dict[str, Any],
        archive_storage: Optional[Dict] = None,
        verbose: bool = True
    ) -> SleepCycleReport:
        """
        Execute complete sleep cycle for memory reconsolidation.
        
        Args:
            memory_registry: Active memory registry to process
            archive_storage: Optional long-term archive storage
            verbose: Print progress updates
            
        Returns:
            Comprehensive sleep cycle report
        """
        self.cycle_count += 1
        cycle_id = f"sleep_cycle_{self.cycle_count}"
        
        if verbose:
            print(f"\n{'='*80}")
            print(f"SLEEP CYCLE {self.cycle_count} - Memory Reconsolidation")
            print(f"{'='*80}")
        
        report = SleepCycleReport(
            cycle_id=cycle_id,
            start_time=time.time(),
            end_time=0,
            duration_seconds=0
        )
        
        initial_memory_count = len(memory_registry)
        
        # Phase 1: Contradiction Resolution
        if verbose:
            print("\n[Phase 1] Detecting and resolving contradictions...")
        
        # PERFORMANCE OPTIMIZATION: Use sparse detection for long-horizon tests
        # Only process volatile memories instead of O(N^2) all-vs-all comparison
        contradictions = self.contradiction_resolver.detect_contradictions_sparse(memory_registry)
        report.contradictions_found = len(contradictions)
        
        resolved_count = 0
        for contradiction in contradictions:
            action, explanation = self.contradiction_resolver.resolve_contradiction(
                contradiction, memory_registry
            )
            if action != ReconciliationAction.FLAG:
                resolved_count += 1
            report.actions_taken.append({
                'phase': 'contradiction_resolution',
                'action': action.value,
                'explanation': explanation
            })
        
        report.contradictions_resolved = resolved_count
        
        if verbose:
            print(f"  Found {len(contradictions)} contradictions, resolved {resolved_count}")
        
        # Phase 2: Redundancy Compression
        if verbose:
            print("\n[Phase 2] Finding and compressing redundant memories...")
        
        clusters = self.memory_compressor.find_redundant_clusters(memory_registry)
        compressed_count = 0
        
        for cluster in clusters:
            compressed_id = self.memory_compressor.compress_cluster(cluster, memory_registry)
            if compressed_id:
                compressed_count += 1
                report.actions_taken.append({
                    'phase': 'compression',
                    'action': 'compressed_cluster',
                    'cluster_id': cluster.cluster_id,
                    'members_compressed': len(cluster.member_ids),
                    'synthesized_id': compressed_id
                })
        
        report.memories_compressed = compressed_count
        
        if verbose:
            print(f"  Found {len(clusters)} redundant clusters, compressed {compressed_count}")
        
        # Phase 3: Stale Memory Decay
        if verbose:
            print("\n[Phase 3] Applying temporal decay to stale memories...")
        
        decayed_ids = self.stale_decay.apply_decay(memory_registry)
        archived_count = self.stale_decay.archive_memories(
            decayed_ids, memory_registry, archive_storage
        )
        
        report.memories_decayed = archived_count
        
        if verbose:
            print(f"  Decayed {len(decayed_ids)} memories, archived {archived_count}")
        
        # Phase 4: Narrative Synthesis (future enhancement)
        if verbose:
            print("\n[Phase 4] Synthesizing coherent narratives...")
            print("  (Narrative synthesis - future enhancement)")
        
        # Finalize report
        report.end_time = time.time()
        report.duration_seconds = report.elapsed_time
        report.memories_processed = initial_memory_count
        
        final_memory_count = len(memory_registry)
        report.coherence_improvement = self._estimate_coherence_improvement(
            contradictions, resolved_count
        )
        report.redundancy_reduction = (initial_memory_count - final_memory_count) / max(1, initial_memory_count)
        report.contradiction_resolution_rate = resolved_count / max(1, len(contradictions))
        
        self.sleep_history.append(report)
        
        if verbose:
            print(f"\n{'='*80}")
            print(f"SLEEP CYCLE COMPLETE")
            print(f"{'='*80}")
            print(f"  Duration: {report.duration_seconds:.2f}s")
            print(f"  Memories processed: {report.memories_processed}")
            print(f"  Contradictions resolved: {report.contradictions_resolved}/{report.contradictions_found}")
            print(f"  Memories compressed: {report.memories_compressed}")
            print(f"  Memories archived: {report.memories_decayed}")
            print(f"  Final memory count: {final_memory_count} (was {initial_memory_count})")
            print(f"  Coherence improvement: {report.coherence_improvement:.2%}")
            print(f"  Redundancy reduction: {report.redundancy_reduction:.2%}")
        
        return report
    
    def _estimate_coherence_improvement(self, contradictions: List, resolved: int) -> float:
        """Estimate improvement in memory coherence."""
        if not contradictions:
            return 0.0
        
        # Each resolved contradiction improves coherence
        resolution_impact = resolved / len(contradictions)
        
        # Weighted by average severity
        avg_severity = sum(c.severity for c in contradictions) / len(contradictions)
        
        return resolution_impact * avg_severity
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get aggregate statistics across all sleep cycles."""
        if not self.sleep_history:
            return {'total_cycles': 0}
        
        total_contradictions = sum(r.contradictions_found for r in self.sleep_history)
        total_resolved = sum(r.contradictions_resolved for r in self.sleep_history)
        total_compressed = sum(r.memories_compressed for r in self.sleep_history)
        total_archived = sum(r.memories_decayed for r in self.sleep_history)
        
        return {
            'total_cycles': len(self.sleep_history),
            'total_contradictions_detected': total_contradictions,
            'total_contradictions_resolved': total_resolved,
            'overall_resolution_rate': total_resolved / max(1, total_contradictions),
            'total_memories_compressed': total_compressed,
            'total_memories_archived': total_archived,
            'average_cycle_duration': sum(r.duration_seconds for r in self.sleep_history) / len(self.sleep_history),
        }


# Example usage and testing
if __name__ == "__main__":
    print("="*80)
    print("MEMORY RECONSOLIDATION ENGINE - Testing Sleep Cycles")
    print("="*80)
    
    # Create sample memory registry with contradictions and redundancies
    memory_registry = {
        'mem_001': {
            'object_id': 'mem_001',
            'object_type': 'belief',
            'content': 'The sky is blue during daytime',
            'theme': 'weather',
            'creation_timestamp': time.time() - 86400 * 10,  # 10 days ago
            'last_accessed': time.time() - 3600,  # Accessed 1 hour ago
            'retention_score': 0.9,
            'status': 'active',
            'trust_score': 0.85,
            'supporting_agents': ['agent_1', 'agent_2', 'agent_3']
        },
        'mem_002': {
            'object_id': 'mem_002',
            'object_type': 'belief',
            'content': 'The sky is NOT blue during daytime',  # Contradiction!
            'theme': 'weather',
            'creation_timestamp': time.time() - 86400 * 5,  # 5 days ago
            'last_accessed': time.time() - 86400 * 2,  # Accessed 2 days ago
            'retention_score': 0.7,
            'status': 'active',
            'trust_score': 0.45,  # Lower trust
            'supporting_agents': ['agent_4']
        },
        'mem_003': {
            'object_id': 'mem_003',
            'object_type': 'memory',
            'content': 'The sky is blue during daytime',  # Redundant with mem_001
            'theme': 'weather',
            'creation_timestamp': time.time() - 86400 * 8,
            'last_accessed': time.time() - 86400 * 7,
            'retention_score': 0.6,
            'status': 'active',
            'trust_score': 0.80
        },
        'mem_004': {
            'object_id': 'mem_004',
            'object_type': 'fact',
            'content': 'Water boils at 100°C at sea level',
            'theme': 'physics',
            'creation_timestamp': time.time() - 86400 * 60,  # 60 days old
            'last_accessed': time.time() - 86400 * 50,  # Not accessed recently
            'retention_score': 0.3,  # Low due to age and no access
            'status': 'active',
            'trust_score': 0.95
        },
        'mem_005': {
            'object_id': 'mem_005',
            'object_type': 'memory',
            'content': 'Temperature reading: 25°C',
            'theme': 'sensor_data',
            'creation_timestamp': time.time() - 3600,  # 1 hour ago
            'last_accessed': time.time() - 300,  # Accessed 5 min ago
            'retention_score': 0.95,
            'status': 'active',
            'trust_score': 0.90
        }
    }
    
    archive_storage = {}
    
    # Run sleep cycle
    engine = MemoryReconsolidationEngine()
    report = engine.run_sleep_cycle(
        memory_registry,
        archive_storage,
        verbose=True
    )
    
    # Print final statistics
    print("\n" + "="*80)
    print("RECONSOLIDATION STATISTICS")
    print("="*80)
    stats = engine.get_statistics()
    for key, value in stats.items():
        print(f"  {key}: {value}")
    
    print("\nRemaining active memories:")
    for mem_id, mem in memory_registry.items():
        print(f"  {mem_id}: {mem['content'][:50]}... (score: {mem.get('retention_score', 0):.2f}, status: {mem.get('status', 'unknown')})")
    
    print("\nArchived memories:")
    for mem_id in archive_storage:
        print(f"  {mem_id}: {archive_storage[mem_id]['content'][:50]}...")
    
    print("\n✅ Memory Reconsolidation Engine test complete!")
