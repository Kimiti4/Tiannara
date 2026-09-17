"""
FAILURE MUSEUM SYSTEM

Purpose: Store and periodically replay failed theories, collapsed reasoning chains,
deceptive shortcuts, reward hacks, and bad syntheses to prevent rediscovering
past failure modes.

Based on next.md (lines 298-318):
"This is massively underrated.
Store:
- failed theories,
- collapsed reasoning chains,
- deceptive shortcuts,
- reward hacks,
- bad syntheses.

Then periodically replay them.

Why?
Because advanced systems forget past failure modes and rediscover them later.
Human civilization does this constantly."

Architecture:
The Failure Museum maintains a curated collection of:
1. Failed Theories - Hypotheses that were disproven
2. Collapsed Reasoning Chains - Logic that broke down
3. Deceptive Shortcuts - Optimization hacks that bypass true understanding
4. Reward Hacks - Exploits of evaluation metrics
5. Bad Syntheses - Poor integrations of multiple perspectives

Each failure is tagged with metadata for retrieval and learning.
Periodic "museum tours" replay failures to reinforce avoidance patterns.
"""

import time
import json
import logging
from pathlib import Path

logger = logging.getLogger(__name__)
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum


class FailureType(Enum):
    """Categories of cognitive failures."""
    FAILED_THEORY = "failed_theory"               # Disproven hypothesis
    COLLAPSED_REASONING = "collapsed_reasoning"   # Broken logic chain
    DECEPTIVE_SHORTCUT = "deceptive_shortcut"     # Surface-level optimization
    REWARD_HACK = "reward_hack"                   # Metric exploitation
    BAD_SYNTHESIS = "bad_synthesis"               # Poor integration
    HALLUCINATED_CAUSALITY = "hallucinated_causality"  # False causal claims
    CONTRADICTION_SUPPRESSION = "contradiction_suppression"  # Ignored conflicts
    OVERCONFIDENCE_SPIKE = "overconfidence_spike" # Unwarranted certainty


@dataclass
class FailureRecord:
    """Complete record of a cognitive failure."""
    failure_id: str
    failure_type: FailureType
    title: str                      # Brief description
    description: str                # Detailed explanation
    
    # Context
    timestamp: float = field(default_factory=time.time)
    domain: Optional[str] = None    # Knowledge domain
    mission_id: Optional[str] = None  # Associated mission/task
    
    # Failure details
    initial_confidence: float = 0.0  # Confidence when failure occurred
    failure_severity: float = 0.0    # How severe was the failure? (0.0-1.0)
    
    # Evidence
    supporting_evidence: List[str] = field(default_factory=list)  # What led to belief
    contradicting_evidence: List[str] = field(default_factory=list)  # What disproved it
    failure_trigger: Optional[str] = None  # What revealed the failure?
    
    # Lessons
    root_cause: Optional[str] = None  # Why did this fail?
    lesson_learned: Optional[str] = None  # What should we remember?
    prevention_strategy: Optional[str] = None  # How to avoid in future?
    
    # Metadata
    tags: List[str] = field(default_factory=list)
    related_failures: List[str] = field(default_factory=list)  # Similar failures
    recovery_actions: List[str] = field(default_factory=list)  # Steps taken to recover
    
    # Tracking
    replay_count: int = 0           # How many times replayed for learning
    last_replayed: Optional[float] = None
    
    def to_dict(self) -> Dict:
        return {
            'failure_id': self.failure_id,
            'failure_type': self.failure_type.value,
            'title': self.title,
            'description': self.description,
            'timestamp': self.timestamp,
            'domain': self.domain,
            'mission_id': self.mission_id,
            'initial_confidence': self.initial_confidence,
            'failure_severity': self.failure_severity,
            'supporting_evidence': self.supporting_evidence,
            'contradicting_evidence': self.contradicting_evidence,
            'failure_trigger': self.failure_trigger,
            'root_cause': self.root_cause,
            'lesson_learned': self.lesson_learned,
            'prevention_strategy': self.prevention_strategy,
            'tags': self.tags,
            'related_failures': self.related_failures,
            'recovery_actions': self.recovery_actions,
            'replay_count': self.replay_count,
            'last_replayed': self.last_replayed
        }
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'FailureRecord':
        return cls(
            failure_id=data['failure_id'],
            failure_type=FailureType(data['failure_type']),
            title=data['title'],
            description=data['description'],
            timestamp=data.get('timestamp', time.time()),
            domain=data.get('domain'),
            mission_id=data.get('mission_id'),
            initial_confidence=data.get('initial_confidence', 0.0),
            failure_severity=data.get('failure_severity', 0.0),
            supporting_evidence=data.get('supporting_evidence', []),
            contradicting_evidence=data.get('contradicting_evidence', []),
            failure_trigger=data.get('failure_trigger'),
            root_cause=data.get('root_cause'),
            lesson_learned=data.get('lesson_learned'),
            prevention_strategy=data.get('prevention_strategy'),
            tags=data.get('tags', []),
            related_failures=data.get('related_failures', []),
            recovery_actions=data.get('recovery_actions', []),
            replay_count=data.get('replay_count', 0),
            last_replayed=data.get('last_replayed')
        )


class FailureMuseum:
    """
    Curated repository of cognitive failures for continuous learning.
    
    Prevents the system from rediscovering known failure modes by:
    1. Archiving all significant failures with rich metadata
    2. Enabling similarity search to detect approaching known failures
    3. Periodically replaying failures to reinforce avoidance
    4. Tracking failure patterns across domains and time
    """
    
    def __init__(self, storage_path: Optional[str] = None):
        """
        Initialize failure museum.
        
        Args:
            storage_path: Path to persist failures (None = memory only)
        """
        self.failures: Dict[str, FailureRecord] = {}
        self.storage_path = Path(storage_path) if storage_path else None
        
        # Indexing structures
        self.type_index: Dict[FailureType, List[str]] = {ft: [] for ft in FailureType}
        self.domain_index: Dict[str, List[str]] = {}
        self.tag_index: Dict[str, List[str]] = {}
        
        # Load existing failures if storage path provided
        if self.storage_path and self.storage_path.exists():
            self._load_from_disk()
    
    def archive_failure(self, failure: FailureRecord):
        """
        Archive a new failure in the museum.
        
        Args:
            failure: Complete failure record to preserve
        """
        self.failures[failure.failure_id] = failure
        
        # Update indexes
        self.type_index[failure.failure_type].append(failure.failure_id)
        
        if failure.domain:
            if failure.domain not in self.domain_index:
                self.domain_index[failure.domain] = []
            self.domain_index[failure.domain].append(failure.failure_id)
        
        for tag in failure.tags:
            if tag not in self.tag_index:
                self.tag_index[tag] = []
            self.tag_index[tag].append(failure.failure_id)
        
        # Persist to disk if configured
        if self.storage_path:
            self._save_to_disk()
    
    def get_failure(self, failure_id: str) -> Optional[FailureRecord]:
        """Retrieve a specific failure record."""
        return self.failures.get(failure_id)
    
    def search_by_type(self, failure_type: FailureType) -> List[FailureRecord]:
        """Get all failures of a specific type."""
        ids = self.type_index.get(failure_type, [])
        return [self.failures[fid] for fid in ids if fid in self.failures]
    
    def search_by_domain(self, domain: str) -> List[FailureRecord]:
        """Get all failures in a specific domain."""
        ids = self.domain_index.get(domain, [])
        return [self.failures[fid] for fid in ids if fid in self.failures]
    
    def search_by_tags(self, tags: List[str]) -> List[FailureRecord]:
        """Get failures matching any of the specified tags."""
        matching_ids = set()
        for tag in tags:
            if tag in self.tag_index:
                matching_ids.update(self.tag_index[tag])
        return [self.failures[fid] for fid in matching_ids if fid in self.failures]
    
    def find_similar_failures(self, current_context: Dict, 
                             max_results: int = 5) -> List[Tuple[FailureRecord, float]]:
        """
        Find failures similar to current situation (preventive warning).
        
        Args:
            current_context: Current state/context to match against
            max_results: Maximum number of similar failures to return
            
        Returns:
            List of (failure_record, similarity_score) tuples
        """
        scored_failures = []
        
        for failure in self.failures.values():
            score = self._compute_similarity(failure, current_context)
            if score > 0.3:  # Only return moderately similar failures
                scored_failures.append((failure, score))
        
        # Sort by similarity descending
        scored_failures.sort(key=lambda x: x[1], reverse=True)
        
        return scored_failures[:max_results]
    
    def replay_failure(self, failure_id: str) -> Optional[Dict]:
        """
        Replay a failure for learning reinforcement.
        
        This simulates "visiting" the failure in the museum to remind
        the system why this approach failed.
        
        Args:
            failure_id: ID of failure to replay
            
        Returns:
            Replay summary or None if failure not found
        """
        if failure_id not in self.failures:
            return None
        
        failure = self.failures[failure_id]
        
        # Update replay tracking
        failure.replay_count += 1
        failure.last_replayed = time.time()
        
        # Generate replay summary
        replay_summary = {
            'failure_id': failure_id,
            'title': failure.title,
            'failure_type': failure.failure_type.value,
            'lesson': failure.lesson_learned,
            'prevention': failure.prevention_strategy,
            'root_cause': failure.root_cause,
            'severity': failure.failure_severity,
            'times_replayed': failure.replay_count,
            'warning': f"AVOID: {failure.title} - {failure.lesson_learned}"
        }
        
        # Persist updated replay count
        if self.storage_path:
            self._save_to_disk()
        
        return replay_summary
    
    def conduct_museum_tour(self, failure_type: Optional[FailureType] = None,
                           domain: Optional[str] = None,
                           max_failures: int = 10) -> List[Dict]:
        """
        Conduct a guided tour through relevant failures for learning.
        
        Args:
            failure_type: Focus on specific failure type (None = all types)
            domain: Focus on specific domain (None = all domains)
            max_failures: Maximum failures to include in tour
            
        Returns:
            List of replay summaries for toured failures
        """
        # Select failures for tour
        if failure_type:
            candidates = self.search_by_type(failure_type)
        elif domain:
            candidates = self.search_by_domain(domain)
        else:
            candidates = list(self.failures.values())
        
        # Prioritize by severity and recency (never replayed first)
        candidates.sort(
            key=lambda f: (f.failure_severity, -f.replay_count, -f.timestamp),
            reverse=True
        )
        
        # Take top N
        selected = candidates[:max_failures]
        
        # Replay each
        tour_results = []
        for failure in selected:
            replay = self.replay_failure(failure.failure_id)
            if replay:
                tour_results.append(replay)
        
        return tour_results
    
    def get_statistics(self) -> Dict:
        """
        Get comprehensive statistics about the failure museum.
        
        Returns:
            Dictionary with museum statistics
        """
        total_failures = len(self.failures)
        
        # Count by type
        type_counts = {
            ft.value: len(ids) for ft, ids in self.type_index.items()
        }
        
        # Count by domain
        domain_counts = {
            domain: len(ids) for domain, ids in self.domain_index.items()
        }
        
        # Severity distribution
        severity_buckets = {'low': 0, 'medium': 0, 'high': 0, 'critical': 0}
        for failure in self.failures.values():
            if failure.failure_severity < 0.3:
                severity_buckets['low'] += 1
            elif failure.failure_severity < 0.6:
                severity_buckets['medium'] += 1
            elif failure.failure_severity < 0.8:
                severity_buckets['high'] += 1
            else:
                severity_buckets['critical'] += 1
        
        # Replay statistics
        total_replays = sum(f.replay_count for f in self.failures.values())
        never_replayed = sum(1 for f in self.failures.values() if f.replay_count == 0)
        
        return {
            'total_failures': total_failures,
            'by_type': type_counts,
            'by_domain': domain_counts,
            'severity_distribution': severity_buckets,
            'total_replays': total_replays,
            'never_replayed': never_replayed,
            'most_replayed': self._get_most_replayed_failures(3),
            'recent_additions': self._get_recent_failures(5)
        }
    
    def _compute_similarity(self, failure: FailureRecord, 
                           context: Dict) -> float:
        """
        Compute similarity between a failure and current context.
        
        Simple heuristic based on:
        - Domain match
        - Tag overlap
        - Description keyword overlap
        
        Args:
            failure: Historical failure record
            context: Current situation context
            
        Returns:
            Similarity score (0.0-1.0)
        """
        score = 0.0
        
        # Domain match (strong signal)
        if failure.domain and context.get('domain') == failure.domain:
            score += 0.4
        
        # Tag overlap
        context_tags = set(context.get('tags', []))
        failure_tags = set(failure.tags)
        if context_tags and failure_tags:
            overlap = len(context_tags.intersection(failure_tags))
            total = len(context_tags.union(failure_tags))
            tag_similarity = overlap / total if total > 0 else 0.0
            score += 0.3 * tag_similarity
        
        # Keyword overlap in description
        context_text = context.get('description', '').lower()
        failure_text = failure.description.lower()
        
        if context_text and failure_text:
            context_words = set(context_text.split())
            failure_words = set(failure_text.split())
            
            # Filter out common words
            stop_words = {'the', 'a', 'an', 'is', 'are', 'was', 'were', 'in', 'on', 'at'}
            context_words -= stop_words
            failure_words -= stop_words
            
            if context_words and failure_words:
                overlap = len(context_words.intersection(failure_words))
                total = len(context_words.union(failure_words))
                keyword_similarity = overlap / total if total > 0 else 0.0
                score += 0.3 * keyword_similarity
        
        return min(score, 1.0)
    
    def _get_most_replayed_failures(self, n: int) -> List[Dict]:
        """Get the N most frequently replayed failures."""
        sorted_failures = sorted(
            self.failures.values(),
            key=lambda f: f.replay_count,
            reverse=True
        )
        return [
            {
                'failure_id': f.failure_id,
                'title': f.title,
                'replay_count': f.replay_count
            }
            for f in sorted_failures[:n]
        ]
    
    def _get_recent_failures(self, n: int) -> List[Dict]:
        """Get the N most recently added failures."""
        sorted_failures = sorted(
            self.failures.values(),
            key=lambda f: f.timestamp,
            reverse=True
        )
        return [
            {
                'failure_id': f.failure_id,
                'title': f.title,
                'failure_type': f.failure_type.value,
                'timestamp': f.timestamp
            }
            for f in sorted_failures[:n]
        ]
    
    def _save_to_disk(self):
        """Persist failures to disk."""
        if not self.storage_path:
            return
        
        self.storage_path.parent.mkdir(parents=True, exist_ok=True)
        
        data = {
            'failures': {fid: f.to_dict() for fid, f in self.failures.items()},
            'metadata': {
                'total_failures': len(self.failures),
                'last_updated': time.time()
            }
        }
        
        with open(self.storage_path, 'w') as f:
            json.dump(data, f, indent=2)
    
    def _load_from_disk(self):
        """Load failures from disk."""
        if not self.storage_path or not self.storage_path.exists():
            return
        
        try:
            with open(self.storage_path, 'r') as f:
                data = json.load(f)
            
            for fid, fdata in data.get('failures', {}).items():
                failure = FailureRecord.from_dict(fdata)
                self.failures[fid] = failure
                
                # Rebuild indexes
                self.type_index[failure.failure_type].append(fid)
                
                if failure.domain:
                    if failure.domain not in self.domain_index:
                        self.domain_index[failure.domain] = []
                    self.domain_index[failure.domain].append(fid)
                
                for tag in failure.tags:
                    if tag not in self.tag_index:
                        self.tag_index[tag] = []
                    self.tag_index[tag].append(fid)
        
        except Exception as e:
            logger.warning(f"Failed to load failure museum from {self.storage_path}: {e}")
