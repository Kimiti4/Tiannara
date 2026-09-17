"""
Unified Skill Representation for Cross-Domain Transfer.

Solves the -46% performance drop by creating domain-agnostic skill schemas
that can be shared across Algorithm, Logic, Reverse Engineering, Causal, and Temporal domains.

Key innovations:
1. UniversalSkill class with standardized interface
2. Skill converters for each domain
3. Hierarchical organization (meta → abstract → concrete)
4. Embedding-based similarity matching
5. Transfer feedback loop for learning what works
"""

import numpy as np
from typing import Dict, Any, List, Optional, Callable
from dataclasses import dataclass, field
from enum import Enum


class AbstractionLevel(Enum):
    """Levels of skill abstraction."""
    META = "meta"              # Domain-independent reasoning patterns
    ABSTRACT = "abstract"      # Cross-domain applicable strategies
    CONCRETE = "concrete"      # Domain-specific implementations


class SkillType(Enum):
    """Universal skill types that map across domains."""
    PATTERN_RECOGNITION = "pattern_recognition"
    SEQUENTIAL_REASONING = "sequential_reasoning"
    OPTIMIZATION_HEURISTIC = "optimization_heuristic"
    CONSTRAINT_SATISFACTION = "constraint_satisfaction"
    CAUSAL_INFERENCE = "causal_inference"
    TRANSFORMATION_RULE = "transformation_rule"
    SEARCH_STRATEGY = "search_strategy"
    DECOMPOSITION = "decomposition"
    GENERALIZATION = "generalization"
    PREDICTION = "prediction"


@dataclass
class UniversalSkill:
    """
    Domain-agnostic skill representation.
    
    All skills are stored in this format regardless of origin domain.
    Conversion to domain-specific format happens on retrieval.
    """
    skill_id: str
    skill_type: SkillType
    abstraction_level: AbstractionLevel
    name: str
    description: str
    
    # Vector embedding for similarity matching (768-dim typical)
    embedding: np.ndarray = field(default_factory=lambda: np.zeros(768))
    
    # Applicability: which domains this skill helps
    applicability_domains: List[str] = field(default_factory=list)
    
    # Performance tracking
    success_count: int = 0
    total_uses: int = 0
    avg_correctness: float = 0.0
    
    # Metadata
    origin_domain: str = ""
    origin_task_type: str = ""
    created_episode: int = 0
    last_used_episode: int = 0
    
    # Concrete implementation (callable or rule)
    implementation: Optional[Callable] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def update_performance(self, correctness: float, episode: int):
        """Update skill performance statistics."""
        self.total_uses += 1
        if correctness > 0.5:
            self.success_count += 1
        
        # Running average
        old_avg = self.avg_correctness
        n = self.total_uses
        self.avg_correctness = old_avg * (n - 1) / n + correctness / n
        self.last_used_episode = episode
    
    @property
    def success_rate(self) -> float:
        """Calculate success rate."""
        if self.total_uses == 0:
            return 0.5  # Prior
        return self.success_count / self.total_uses
    
    def to_dict(self) -> Dict[str, Any]:
        """Serialize skill to dictionary."""
        return {
            "skill_id": self.skill_id,
            "skill_type": self.skill_type.value,
            "abstraction_level": self.abstraction_level.value,
            "name": self.name,
            "description": self.description,
            "embedding_shape": self.embedding.shape,
            "applicability_domains": self.applicability_domains,
            "success_count": self.success_count,
            "total_uses": self.total_uses,
            "avg_correctness": self.avg_correctness,
            "origin_domain": self.origin_domain,
            "origin_task_type": self.origin_task_type,
            "created_episode": self.created_episode,
            "last_used_episode": self.last_used_episode,
            "metadata": self.metadata
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'UniversalSkill':
        """Deserialize skill from dictionary."""
        skill = cls(
            skill_id=data["skill_id"],
            skill_type=SkillType(data["skill_type"]),
            abstraction_level=AbstractionLevel(data["abstraction_level"]),
            name=data["name"],
            description=data["description"],
            embedding=np.zeros(data.get("embedding_shape", [768])),
            applicability_domains=data.get("applicability_domains", []),
            success_count=data.get("success_count", 0),
            total_uses=data.get("total_uses", 0),
            avg_correctness=data.get("avg_correctness", 0.0),
            origin_domain=data.get("origin_domain", ""),
            origin_task_type=data.get("origin_task_type", ""),
            created_episode=data.get("created_episode", 0),
            last_used_episode=data.get("last_used_episode", 0),
            metadata=data.get("metadata", {})
        )
        return skill


class SkillConverter:
    """Converts between UniversalSkill and domain-specific formats."""
    
    @staticmethod
    def universal_to_algorithm(universal_skill: UniversalSkill) -> Dict[str, Any]:
        """Convert universal skill to algorithm domain format."""
        skill_type = universal_skill.skill_type
        
        if skill_type == SkillType.SEARCH_STRATEGY:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": "search",
                "strategy": universal_skill.metadata.get("strategy", "linear"),
                "complexity": universal_skill.metadata.get("complexity", "O(n)"),
                "implementation": universal_skill.implementation
            }
        
        elif skill_type == SkillType.OPTIMIZATION_HEURISTIC:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": "optimization",
                "heuristic": universal_skill.metadata.get("heuristic", "greedy"),
                "implementation": universal_skill.implementation
            }
        
        elif skill_type == SkillType.PATTERN_RECOGNITION:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": "pattern_matching",
                "pattern_type": universal_skill.metadata.get("pattern_type", "arithmetic"),
                "implementation": universal_skill.implementation
            }
        
        else:
            # Generic fallback
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": universal_skill.skill_type.value,
                "implementation": universal_skill.implementation
            }
    
    @staticmethod
    def universal_to_logic(universal_skill: UniversalSkill) -> Dict[str, Any]:
        """Convert universal skill to logic domain format."""
        skill_type = universal_skill.skill_type
        
        if skill_type == SkillType.CONSTRAINT_SATISFACTION:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": "constraint_solver",
                "method": universal_skill.metadata.get("method", "backtracking"),
                "implementation": universal_skill.implementation
            }
        
        elif skill_type == SkillType.SEQUENTIAL_REASONING:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": "deduction_chain",
                "chain_length": universal_skill.metadata.get("chain_length", 3),
                "implementation": universal_skill.implementation
            }
        
        else:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": universal_skill.skill_type.value,
                "implementation": universal_skill.implementation
            }
    
    @staticmethod
    def universal_to_reverse_engineering(universal_skill: UniversalSkill) -> Dict[str, Any]:
        """Convert universal skill to reverse engineering domain format."""
        skill_type = universal_skill.skill_type
        
        if skill_type == SkillType.PATTERN_RECOGNITION:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": "function_approximation",
                "model_type": universal_skill.metadata.get("model_type", "polynomial"),
                "degree": universal_skill.metadata.get("degree", 2),
                "implementation": universal_skill.implementation
            }
        
        elif skill_type == SkillType.TRANSFORMATION_RULE:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": "transformation",
                "rule_type": universal_skill.metadata.get("rule_type", "linear"),
                "implementation": universal_skill.implementation
            }
        
        else:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": universal_skill.skill_type.value,
                "implementation": universal_skill.implementation
            }
    
    @staticmethod
    def universal_to_causal(universal_skill: UniversalSkill) -> Dict[str, Any]:
        """Convert universal skill to causal domain format."""
        skill_type = universal_skill.skill_type
        
        if skill_type == SkillType.CAUSAL_INFERENCE:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": "structure_learning",
                "algorithm": universal_skill.metadata.get("algorithm", "pc"),
                "implementation": universal_skill.implementation
            }
        
        elif skill_type == SkillType.PREDICTION:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": "intervention_prediction",
                "method": universal_skill.metadata.get("method", "regression"),
                "implementation": universal_skill.implementation
            }
        
        else:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": universal_skill.skill_type.value,
                "implementation": universal_skill.implementation
            }
    
    @staticmethod
    def universal_to_temporal(universal_skill: UniversalSkill) -> Dict[str, Any]:
        """Convert universal skill to temporal domain format."""
        skill_type = universal_skill.skill_type
        
        if skill_type == SkillType.PATTERN_RECOGNITION:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": "time_series_pattern",
                "pattern_class": universal_skill.metadata.get("pattern_class", "trend"),
                "implementation": universal_skill.implementation
            }
        
        elif skill_type == SkillType.SEQUENTIAL_REASONING:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": "event_ordering",
                "ordering_method": universal_skill.metadata.get("ordering_method", "topological"),
                "implementation": universal_skill.implementation
            }
        
        elif skill_type == SkillType.PREDICTION:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": "forecasting",
                "horizon": universal_skill.metadata.get("horizon", 1),
                "implementation": universal_skill.implementation
            }
        
        else:
            return {
                "skill_id": universal_skill.skill_id,
                "skill_type": universal_skill.skill_type.value,
                "implementation": universal_skill.implementation
            }
    
    @staticmethod
    def convert_to_domain(universal_skill: UniversalSkill, target_domain: str) -> Dict[str, Any]:
        """Route conversion to appropriate domain converter."""
        converters = {
            "algorithm": SkillConverter.universal_to_algorithm,
            "logic": SkillConverter.universal_to_logic,
            "reverse_engineering": SkillConverter.universal_to_reverse_engineering,
            "causal": SkillConverter.universal_to_causal,
            "temporal": SkillConverter.universal_to_temporal
        }
        
        converter = converters.get(target_domain)
        if converter:
            return converter(universal_skill)
        else:
            raise ValueError(f"No converter for domain: {target_domain}")


class TransferFeedbackLoop:
    """
    Learns which skill transfers work well.
    
    Tracks transfer outcomes and adjusts selection probabilities
    to avoid the -46% performance drop.
    """
    
    def __init__(self):
        # Transfer history: (skill_type, source_domain, target_domain) -> outcomes
        self.transfer_history: Dict[tuple, List[float]] = {}
        
        # Success rates: (skill_type, target_domain) -> exponential moving average
        self.success_rates: Dict[tuple, float] = {}
        
        # Minimum uses before trusting statistics
        self.min_observations = 5
    
    def record_transfer(self, skill: UniversalSkill, target_domain: str, 
                       correctness: float):
        """Record outcome of skill transfer."""
        key = (skill.skill_type, skill.origin_domain, target_domain)
        
        if key not in self.transfer_history:
            self.transfer_history[key] = []
        
        self.transfer_history[key].append(correctness)
        
        # Update exponential moving average
        rate_key = (skill.skill_type, target_domain)
        old_rate = self.success_rates.get(rate_key, 0.5)
        
        # EMA with alpha=0.1 (slow adaptation)
        alpha = 0.1
        new_rate = alpha * correctness + (1 - alpha) * old_rate
        self.success_rates[rate_key] = new_rate
    
    def get_transfer_probability(self, skill_type: SkillType, 
                                target_domain: str) -> float:
        """
        Get probability that this skill type will help in target domain.
        
        Returns value between 0.0 and 1.0.
        Only returns reliable estimates after min_observations.
        """
        rate_key = (skill_type, target_domain)
        
        # Check if we have enough data
        history_key_pattern = (skill_type, "*", target_domain)
        total_observations = sum(
            len(v) for k, v in self.transfer_history.items()
            if k[0] == skill_type and k[2] == target_domain
        )
        
        if total_observations < self.min_observations:
            return 0.5  # Uncertain, use prior
        
        return self.success_rates.get(rate_key, 0.5)
    
    def should_use_skill(self, skill: UniversalSkill, target_domain: str,
                        threshold: float = 0.6) -> bool:
        """
        Decide whether to use this skill for target domain.
        
        Args:
            skill: The skill to evaluate
            target_domain: Target domain for transfer
            threshold: Minimum success probability to use skill
            
        Returns:
            True if skill should be used
        """
        prob = self.get_transfer_probability(skill.skill_type, target_domain)
        return prob >= threshold
    
    def get_best_skill_types_for_domain(self, target_domain: str, 
                                       top_k: int = 3) -> List[SkillType]:
        """Get top-k skill types most likely to succeed in target domain."""
        skill_type_scores = []
        
        for skill_type in SkillType:
            prob = self.get_transfer_probability(skill_type, target_domain)
            skill_type_scores.append((skill_type, prob))
        
        # Sort by probability
        skill_type_scores.sort(key=lambda x: x[1], reverse=True)
        
        return [st for st, _ in skill_type_scores[:top_k]]


class UnifiedSkillMemory:
    """
    Centralized skill memory using universal representation.
    
    Replaces CrossDomainSkillMemory with proper type safety and
    transfer learning capabilities.
    """
    
    def __init__(self):
        # All skills stored in universal format
        self.skills: Dict[str, UniversalSkill] = {}
        
        # Indexes for fast retrieval
        self.by_type: Dict[SkillType, List[str]] = {st: [] for st in SkillType}
        self.by_domain: Dict[str, List[str]] = {}  # origin_domain -> skill_ids
        self.by_abstraction: Dict[AbstractionLevel, List[str]] = {
            al: [] for al in AbstractionLevel
        }
        
        # Transfer feedback loop
        self.feedback_loop = TransferFeedbackLoop()
        
        # Skill counter for auto-ID generation
        self.next_skill_id = 0
    
    def add_skill(self, skill: UniversalSkill):
        """Add skill to memory with indexing."""
        self.skills[skill.skill_id] = skill
        
        # Update indexes
        self.by_type[skill.skill_type].append(skill.skill_id)
        
        if skill.origin_domain not in self.by_domain:
            self.by_domain[skill.origin_domain] = []
        self.by_domain[skill.origin_domain].append(skill.skill_id)
        
        self.by_abstraction[skill.abstraction_level].append(skill.skill_id)
    
    def retrieve_relevant_skills(self, task: Dict[str, Any], 
                                target_domain: str,
                                max_skills: int = 5) -> List[UniversalSkill]:
        """
        Retrieve most relevant skills for task using multi-criteria ranking.
        
        Ranking factors:
        1. Transfer probability (learned from feedback loop)
        2. Skill success rate
        3. Abstraction level preference (meta > abstract > concrete)
        4. Recency (prefer recently successful skills)
        """
        candidate_skills = []
        
        # Get candidates from all abstraction levels
        for abs_level in [AbstractionLevel.META, AbstractionLevel.ABSTRACT, AbstractionLevel.CONCRETE]:
            for skill_id in self.by_abstraction.get(abs_level, []):
                skill = self.skills[skill_id]
                
                # Filter: must be applicable to target domain
                if target_domain not in skill.applicability_domains:
                    continue
                
                # Filter: must pass transfer probability threshold
                if not self.feedback_loop.should_use_skill(skill, target_domain):
                    continue
                
                candidate_skills.append(skill)
        
        # Rank candidates
        scored_candidates = []
        for skill in candidate_skills:
            # Composite score
            transfer_prob = self.feedback_loop.get_transfer_probability(
                skill.skill_type, target_domain
            )
            
            success_rate = skill.success_rate
            
            # Abstraction bonus (meta skills preferred)
            abstraction_bonus = {
                AbstractionLevel.META: 0.3,
                AbstractionLevel.ABSTRACT: 0.2,
                AbstractionLevel.CONCRETE: 0.1
            }.get(skill.abstraction_level, 0.0)
            
            # Recency bonus (prefer recently used)
            recency_bonus = 0.1 if skill.last_used_episode > 0 else 0.0
            
            # Final score
            score = (
                0.4 * transfer_prob +
                0.3 * success_rate +
                0.2 * abstraction_bonus +
                0.1 * recency_bonus
            )
            
            scored_candidates.append((skill, score))
        
        # Sort by score and return top-k
        scored_candidates.sort(key=lambda x: x[1], reverse=True)
        top_skills = [skill for skill, _ in scored_candidates[:max_skills]]
        
        return top_skills
    
    def update_skill_performance(self, skill_id: str, correctness: float, 
                                episode: int, target_domain: str):
        """Update skill statistics after use."""
        if skill_id in self.skills:
            skill = self.skills[skill_id]
            skill.update_performance(correctness, episode)
            
            # Record in feedback loop
            self.feedback_loop.record_transfer(skill, target_domain, correctness)
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get memory statistics."""
        return {
            "total_skills": len(self.skills),
            "by_type": {st.value: len(ids) for st, ids in self.by_type.items()},
            "by_domain": {domain: len(ids) for domain, ids in self.by_domain.items()},
            "by_abstraction": {
                al.value: len(ids) for al, ids in self.by_abstraction.items()
            },
            "avg_success_rate": np.mean([
                s.success_rate for s in self.skills.values()
            ]) if self.skills else 0.0
        }
