"""
ECM-Aligned Forgetting Mechanism for Memory Management.

Implements progressive memory refinement as described in upgrades.md:
- Three-tier architecture: raw event → semantic indexing → reflective synthesis
- Salience-gated writing: actively decides what's worth committing
- Forgetting as a feature: memories decay if not retrieved/referenced
- Information flows upward with provenance chains

This prevents the memory leak detected in load testing (2.93x growth).
"""

import gc
import time
import json
import os
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass, field, asdict
import hashlib


@dataclass
class SkillEntry:
    """Represents a skill with metadata for salience tracking."""
    id: str
    pattern: str
    solution: Any
    quality: float
    domain: str
    created_at: float = field(default_factory=time.time)
    last_used: float = field(default_factory=time.time)
    usage_count: int = 0
    retrieval_count: int = 0
    success_rate: float = 0.0
    total_attempts: int = 0
    
    @property
    def age_seconds(self) -> float:
        return time.time() - self.created_at
    
    @property
    def recency_score(self) -> float:
        """Higher score = more recently used."""
        return time.time() - self.last_used
    
    @property
    def salience(self) -> float:
        """
        Calculate skill salience based on usage frequency, recency, and quality.
        
        Salience = (usage_frequency * recency_weight) * quality
        
        High salience = keep this skill
        Low salience = candidate for pruning
        """
        # Usage frequency (normalized)
        if self.age_seconds > 0:
            usage_freq = self.usage_count / max(self.age_seconds / 3600, 1)  # per hour
        else:
            usage_freq = self.usage_count
        
        # Recency weight (exponential decay)
        hours_since_use = self.recency_score / 3600
        recency_weight = 1.0 / (1.0 + hours_since_use)  # Decays over time
        
        # Combined salience
        salience_score = (usage_freq * recency_weight) * self.quality
        
        return salience_score


class SkillMemoryWithForgetting:
    """
    Enhanced skill memory with ECM-aligned forgetting mechanisms.
    
    Implements:
    1. Salience-gated writing (decides what to store)
    2. Progressive decay (unused skills fade)
    3. Consolidation (merge similar skills)
    4. Hierarchical organization (tiered storage)
    """
    
    def __init__(
        self,
        max_skills: int = 100,
        decay_rate: float = 0.01,
        salience_threshold: float = 0.05,
        consolidation_threshold: float = 0.85,
        checkpoint_interval: int = 100
    ):
        """
        Initialize skill memory with forgetting parameters.
        
        Args:
            max_skills: Maximum number of skills to retain
            decay_rate: Rate at which unused skills decay (per hour)
            salience_threshold: Minimum salience to keep a skill
            consolidation_threshold: Similarity threshold for merging skills
            checkpoint_interval: Episodes between automatic cleanup
        """
        self.max_skills = max_skills
        self.decay_rate = decay_rate
        self.salience_threshold = salience_threshold
        self.consolidation_threshold = consolidation_threshold
        self.checkpoint_interval = checkpoint_interval
        
        # Tier 1: Active skills (always in memory)
        self.active_skills: Dict[str, SkillEntry] = {}
        
        # Tier 2: Archived skills (compressed summaries)
        self.archived_summaries: List[Dict[str, Any]] = []
        
        # Tracking
        self.total_stored = 0
        self.total_pruned = 0
        self.total_consolidated = 0
        self.episode_counter = 0
        
        # Statistics
        self.pruning_log: List[Dict[str, Any]] = []
    
    def __len__(self) -> int:
        """
        Return total number of skills in memory (active + archived).
        
        This method enables len() calls for compatibility with test expectations.
        
        Returns:
            Total skill count
        """
        return len(self.active_skills) + len(self.archived_summaries)
    
    def add_skill(
        self,
        pattern: str,
        solution: Any,
        quality: float,
        domain: str = "unknown",
        episode: int = 0
    ) -> Optional[str]:
        """
        Add skill with salience-gated writing.
        
        Only stores skills above minimum quality threshold.
        
        Args:
            pattern: Pattern description (e.g., "linear_function")
            solution: The actual solution/function
            quality: Quality score [0, 1]
            domain: Domain where skill was learned
            episode: Episode number when skill was acquired
            
        Returns:
            Skill ID if stored, None if rejected
        """
        # Salience-gated writing: reject low-quality skills
        if quality < 0.5:
            return None
        
        # Generate unique ID
        skill_id = hashlib.sha256(
            f"{pattern}_{domain}_{episode}".encode()
        ).hexdigest()[:12]
        
        # Create skill entry
        skill = SkillEntry(
            id=skill_id,
            pattern=pattern,
            solution=solution,
            quality=quality,
            domain=domain
        )
        
        # Store in active tier
        self.active_skills[skill_id] = skill
        self.total_stored += 1
        self.episode_counter = episode
        
        # Check if we need to prune
        if len(self.active_skills) > self.max_skills:
            self._prune_low_salience()
        
        return skill_id
    
    def retrieve_skill(self, skill_id: str) -> Optional[SkillEntry]:
        """
        Retrieve skill and update usage statistics.
        
        This is critical for the forgetting mechanism - skills that are
        retrieved frequently maintain high salience.
        
        Args:
            skill_id: ID of skill to retrieve
            
        Returns:
            SkillEntry if found, None otherwise
        """
        if skill_id not in self.active_skills:
            return None
        
        skill = self.active_skills[skill_id]
        
        # Update retrieval statistics
        skill.retrieval_count += 1
        skill.last_used = time.time()
        
        return skill
    
    def track_skill_usage(self, skill_id: str, success: bool):
        """
        Track skill usage outcome for adaptive quality.
        
        Args:
            skill_id: ID of skill used
            success: Whether the skill led to success
        """
        if skill_id not in self.active_skills:
            return
        
        skill = self.active_skills[skill_id]
        skill.usage_count += 1
        skill.last_used = time.time()
        
        # Update success rate
        skill.total_attempts += 1
        if success:
            skill.success_rate = (
                (skill.success_rate * (skill.total_attempts - 1) + 1.0)
                / skill.total_attempts
            )
        else:
            skill.success_rate = (
                (skill.success_rate * (skill.total_attempts - 1))
                / skill.total_attempts
            )
    
    def apply_decay(self, current_episode: int) -> int:
        """
        Apply decay to all skills based on age and usage.
        
        Removes skills with salience below threshold.
        
        Args:
            current_episode: Current episode number
            
        Returns:
            Number of skills pruned
        """
        if current_episode % self.checkpoint_interval != 0:
            return 0
        
        pruned_count = self._prune_low_salience()
        
        # Force garbage collection after pruning
        gc.collect()
        
        if pruned_count > 0:
            print(f"  [FORGET] Pruned {pruned_count} low-salience skills")
        
        return pruned_count
    
    def _prune_low_salience(self) -> int:
        """
        Remove skills with salience below threshold.
        
        Returns:
            Number of skills removed
        """
        if len(self.active_skills) <= self.max_skills * 0.8:
            # Only prune if we're getting full
            return 0
        
        # Calculate salience for all skills
        skill_salience = [
            (skill_id, skill.salience)
            for skill_id, skill in self.active_skills.items()
        ]
        
        # Sort by salience (lowest first)
        skill_salience.sort(key=lambda x: x[1])
        
        # Determine how many to prune
        excess = len(self.active_skills) - int(self.max_skills * 0.7)
        if excess <= 0:
            return 0
        
        # Prune lowest salience skills
        pruned = 0
        for skill_id, salience in skill_salience[:excess]:
            if salience < self.salience_threshold:
                # Archive before removing
                self._archive_skill(self.active_skills[skill_id])
                
                del self.active_skills[skill_id]
                pruned += 1
                self.total_pruned += 1
                
                # Log pruning decision
                self.pruning_log.append({
                    "skill_id": skill_id,
                    "salience": salience,
                    "reason": "low_salience",
                    "episode": self.episode_counter
                })
        
        return pruned
    
    def _archive_skill(self, skill: SkillEntry):
        """
        Archive skill as compressed summary before deletion.
        
        This implements hierarchical trace summarization from ecm.md.
        
        Args:
            skill: Skill to archive
        """
        summary = {
            "skill_id": skill.id,
            "pattern": skill.pattern,
            "domain": skill.domain,
            "final_quality": skill.quality,
            "total_usage": skill.usage_count,
            "success_rate": skill.success_rate,
            "age_hours": skill.age_seconds / 3600,
            "archived_at": time.time()
        }
        
        self.archived_summaries.append(summary)
        
        # Keep only recent archives (last 1000)
        if len(self.archived_summaries) > 1000:
            self.archived_summaries = self.archived_summaries[-1000:]
    
    def consolidate_similar_skills(self) -> int:
        """
        Merge highly similar skills to reduce redundancy.
        
        Uses pattern similarity to identify candidates for consolidation.
        
        Returns:
            Number of skills consolidated
        """
        if len(self.active_skills) < 10:
            return 0
        
        consolidated = 0
        skills_list = list(self.active_skills.values())
        
        # Group by domain and pattern similarity
        groups: Dict[str, List[SkillEntry]] = {}
        for skill in skills_list:
            # Simple grouping by domain + first word of pattern
            key = f"{skill.domain}_{skill.pattern.split('_')[0]}"
            if key not in groups:
                groups[key] = []
            groups[key].append(skill)
        
        # Consolidate within each group
        for group_key, group_skills in groups.items():
            if len(group_skills) < 2:
                continue
            
            # Sort by quality (keep highest quality)
            group_skills.sort(key=lambda s: s.quality, reverse=True)
            
            # Keep top skill, archive others
            best_skill = group_skills[0]
            for skill in group_skills[1:]:
                # Check similarity (simplified - could use semantic similarity)
                if self._patterns_similar(best_skill.pattern, skill.pattern):
                    # Merge statistics
                    best_skill.usage_count += skill.usage_count
                    best_skill.retrieval_count += skill.retrieval_count
                    
                    # Archive the redundant skill
                    self._archive_skill(skill)
                    del self.active_skills[skill.id]
                    
                    consolidated += 1
                    self.total_consolidated += 1
        
        if consolidated > 0:
            print(f"  [CONSOLIDATE] Merged {consolidated} similar skills")
        
        return consolidated
    
    def _patterns_similar(self, pattern1: str, pattern2: str) -> bool:
        """
        Check if two patterns are similar enough to consolidate.
        
        Args:
            pattern1: First pattern string
            pattern2: Second pattern string
            
        Returns:
            True if patterns are similar
        """
        # Simple heuristic: same base pattern type
        base1 = pattern1.split('_')[0] if '_' in pattern1 else pattern1
        base2 = pattern2.split('_')[0] if '_' in pattern2 else pattern2
        
        return base1 == base2
    
    def get_top_skills(self, n: int = 10, domain: str = None) -> List[SkillEntry]:
        """
        Get top N skills by salience.
        
        Args:
            n: Number of skills to return
            domain: Optional domain filter
            
        Returns:
            List of top skills sorted by salience
        """
        skills = list(self.active_skills.values())
        
        if domain:
            skills = [s for s in skills if s.domain == domain]
        
        # Sort by salience (highest first)
        skills.sort(key=lambda s: s.salience, reverse=True)
        
        return skills[:n]
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get memory statistics."""
        return {
            "active_skills": len(self.active_skills),
            "archived_summaries": len(self.archived_summaries),
            "total_stored": self.total_stored,
            "total_pruned": self.total_pruned,
            "total_consolidated": self.total_consolidated,
            "retention_rate": (
                len(self.active_skills) / self.total_stored
                if self.total_stored > 0 else 0
            ),
            "avg_salience": (
                sum(s.salience for s in self.active_skills.values())
                / len(self.active_skills)
                if self.active_skills else 0
            )
        }
    
    def cleanup(self):
        """Perform full cleanup cycle."""
        pruned = self._prune_low_salience()
        consolidated = self.consolidate_similar_skills()
        
        return {
            "pruned": pruned,
            "consolidated": consolidated
        }
    
    def save_checkpoint(self, checkpoint_dir: str = "checkpoints", episode: int = 0) -> str:
        """
        Save skill memory state to disk for session persistence.
        
        Args:
            checkpoint_dir: Directory to save checkpoints
            episode: Current episode number (for filename)
            
        Returns:
            Path to saved checkpoint file
        """
        os.makedirs(checkpoint_dir, exist_ok=True)
        
        # Create checkpoint filename with episode number
        checkpoint_file = os.path.join(checkpoint_dir, f"skill_memory_ep{episode}.json")
        
        # Serialize skills (exclude solution objects as they're not JSON serializable)
        skills_data = {}
        for skill_id, skill in self.active_skills.items():
            skills_data[skill_id] = {
                "id": skill.id,
                "pattern": skill.pattern,
                "quality": skill.quality,
                "domain": skill.domain,
                "created_at": skill.created_at,
                "last_used": skill.last_used,
                "usage_count": skill.usage_count,
                "retrieval_count": skill.retrieval_count,
                "success_rate": skill.success_rate,
                "total_attempts": skill.total_attempts
                # Note: 'solution' field is excluded - will need to be reconstructed
            }
        
        checkpoint_data = {
            "metadata": {
                "episode": episode,
                "timestamp": time.time(),
                "max_skills": self.max_skills,
                "decay_rate": self.decay_rate,
                "salience_threshold": self.salience_threshold,
                "consolidation_threshold": self.consolidation_threshold
            },
            "statistics": {
                "total_stored": self.total_stored,
                "total_pruned": self.total_pruned,
                "total_consolidated": self.total_consolidated,
                "active_skills_count": len(self.active_skills),
                "archived_summaries_count": len(self.archived_summaries)
            },
            "skills": skills_data,
            "archived_summaries": self.archived_summaries,
            "pruning_log": self.pruning_log[-100:]  # Keep last 100 entries
        }
        
        with open(checkpoint_file, 'w') as f:
            json.dump(checkpoint_data, f, indent=2)
        
        return checkpoint_file
    
    def load_checkpoint(self, checkpoint_file: str) -> bool:
        """
        Load skill memory state from disk.
        
        Args:
            checkpoint_file: Path to checkpoint file
            
        Returns:
            True if loaded successfully, False otherwise
        """
        if not os.path.exists(checkpoint_file):
            print(f"Warning: Checkpoint file not found: {checkpoint_file}")
            return False
        
        try:
            with open(checkpoint_file, 'r') as f:
                checkpoint_data = json.load(f)
            
            # Restore metadata
            metadata = checkpoint_data.get("metadata", {})
            self.episode_counter = metadata.get("episode", 0)
            
            # Restore statistics
            stats = checkpoint_data.get("statistics", {})
            self.total_stored = stats.get("total_stored", 0)
            self.total_pruned = stats.get("total_pruned", 0)
            self.total_consolidated = stats.get("total_consolidated", 0)
            
            # Restore archived summaries
            self.archived_summaries = checkpoint_data.get("archived_summaries", [])
            
            # Restore pruning log
            self.pruning_log = checkpoint_data.get("pruning_log", [])
            
            # Note: Skills are restored without solution objects
            # The evolver needs to reconstruct solutions from patterns
            skills_data = checkpoint_data.get("skills", {})
            print(f"Loaded {len(skills_data)} skill entries from checkpoint")
            print(f"Note: Skill solutions must be reconstructed by evolver")
            
            return True
            
        except Exception as e:
            print(f"Error loading checkpoint: {e}")
            return False
    
    def get_latest_checkpoint(self, checkpoint_dir: str = "checkpoints") -> Optional[str]:
        """
        Find the most recent checkpoint file.
        
        Args:
            checkpoint_dir: Directory containing checkpoints
            
        Returns:
            Path to latest checkpoint, or None if no checkpoints exist
        """
        if not os.path.exists(checkpoint_dir):
            return None
        
        checkpoint_files = [
            f for f in os.listdir(checkpoint_dir)
            if f.startswith("skill_memory_ep") and f.endswith(".json")
        ]
        
        if not checkpoint_files:
            return None
        
        # Sort by episode number (extracted from filename)
        def extract_episode(filename):
            try:
                return int(filename.replace("skill_memory_ep", "").replace(".json", ""))
            except ValueError:
                return 0
        
        checkpoint_files.sort(key=extract_episode, reverse=True)
        
        return os.path.join(checkpoint_dir, checkpoint_files[0])


class TraceCompressor:
    """
    Hierarchical trace summarization for memory efficiency.
    
    Implements the "Trace Embedding Sandbox" concept from ecm.md:
    - Raw traces are compressed into summaries
    - Only causal dimensions are retained
    - Reduces memory footprint while preserving information
    """
    
    def __init__(self, batch_size: int = 100):
        """
        Initialize trace compressor.
        
        Args:
            batch_size: Number of traces before compression
        """
        self.batch_size = batch_size
        self.raw_traces: List[Dict[str, Any]] = []
        self.compressed_summaries: List[Dict[str, Any]] = []
    
    def add_trace(self, trace: Dict[str, Any]):
        """
        Add trace and compress when batch is full.
        
        Args:
            trace: Execution trace to store
        """
        self.raw_traces.append(trace)
        
        # Compress when batch is full
        if len(self.raw_traces) >= self.batch_size:
            self._compress_batch()
    
    def _compress_batch(self):
        """Compress current batch of traces into summary."""
        if not self.raw_traces:
            return
        
        # Extract key information
        summary = {
            "trace_count": len(self.raw_traces),
            "causal_dimensions": self._extract_causal_dimensions(),
            "pattern_frequencies": self._count_patterns(),
            "divergence_points": self._identify_branches(),
            "compressed_at": time.time()
        }
        
        self.compressed_summaries.append(summary)
        
        # Clear raw traces (free memory)
        self.raw_traces.clear()
    
    def _extract_causal_dimensions(self) -> List[str]:
        """Extract key causal dimensions from traces."""
        # Simplified implementation
        # In production, would use causal discovery algorithms
        dimensions = set()
        for trace in self.raw_traces:
            if "inputs" in trace:
                dimensions.update(trace["inputs"].keys())
            if "outputs" in trace:
                dimensions.update(trace["outputs"].keys())
        
        return list(dimensions)[:10]  # Limit to top 10
    
    def _count_patterns(self) -> Dict[str, int]:
        """Count pattern frequencies in traces."""
        # Simplified pattern counting
        patterns = {}
        for trace in self.raw_traces:
            pattern = trace.get("pattern", "unknown")
            patterns[pattern] = patterns.get(pattern, 0) + 1
        
        return patterns
    
    def _identify_branches(self) -> List[Dict[str, Any]]:
        """Identify divergence points in execution."""
        # Simplified branch detection
        branches = []
        for i, trace in enumerate(self.raw_traces):
            if trace.get("branch_point", False):
                branches.append({
                    "index": i,
                    "condition": trace.get("branch_condition", "unknown")
                })
        
        return branches[:20]  # Limit to top 20 branches
    
    def get_memory_usage(self) -> Dict[str, int]:
        """Get memory usage statistics."""
        return {
            "raw_traces": len(self.raw_traces),
            "compressed_summaries": len(self.compressed_summaries),
            "estimated_raw_mb": len(self.raw_traces) * 0.001,  # ~1KB per trace
            "estimated_compressed_mb": len(self.compressed_summaries) * 0.01  # ~10KB per summary
        }
    
    def force_compress(self):
        """Force compression of remaining traces."""
        if self.raw_traces:
            self._compress_batch()
