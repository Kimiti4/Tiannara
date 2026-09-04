"""Multi-Domain Experiment with Cross-Domain Skill Transfer.

Tests overall system capability across:
1. Algorithm domain (sorting, search, optimization, graph)
2. Logic puzzle domain (patterns, boolean, sequences, deduction)
3. Reverse engineering domain (function inference, black-box recovery)
4. Causal system domain (x→y→z dependencies, interventions)
5. Temporal reasoning domain (time series, event sequences, periodicity)

Implements true cross-domain skill transfer through shared representations.
"""

import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.logic_domain import LogicPuzzleGenerator
from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.temporal_domain import TemporalTaskGenerator
from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
from tiannara_core.evaluation.logic_evolution_engine import LogicPuzzleEvolver
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver
from tiannara_core.evaluation.temporal_evolution_engine import TemporalEvolver
from tiannara_core.evaluation.evaluator import Evaluator
from tiannara_core.evaluation.error_tracker import ErrorTracker
import json
import time
import numpy as np
from datetime import datetime


class CrossDomainSkillMemory:
    """Shared skill memory across all domains for true cross-domain transfer."""
    
    def __init__(self):
        # Shared abstract skills (domain-agnostic patterns)
        self.abstract_skills = {
            "pattern_recognition": [],      # Works across all domains
            "sequential_reasoning": [],     # Algorithms, logic, causal chains
            "optimization_heuristics": [],  # Optimization, reverse engineering
            "causal_inference": [],         # Causal systems, reverse engineering
            "transformation_rules": []      # All domains involve transformations
        }
        
        # Domain-specific skills
        self.domain_skills = {
            "algorithm": [],
            "logic": [],
            "reverse_engineering": [],
            "causal": []
        }
        
        # Transfer history - which skills helped which domains
        self.transfer_log = []
        
        # Composition rules - define how skills can be combined
        self.composition_rules = {
            ("pattern_recognition", "sequential_reasoning"): "causal_chain_discovery",
            ("optimization_heuristics", "transformation_rules"): "function_approximation",
            ("causal_inference", "pattern_recognition"): "structural_learning",
            ("sequential_reasoning", "transformation_rules"): "iterative_refinement",
        }
        
        # Track composed skills
        self.composed_skills = []
        
        # Skill usage tracking - for decay mechanism
        self.skill_usage_count = {}  # skill_id -> number of times used
        self.last_used_episode = {}  # skill_id -> last episode number when used
        self.current_episode = 0
        self.next_skill_id = 0  # Auto-incrementing skill ID counter
        
        # Meta-learning statistics
        self.skill_effectiveness = {}  # (skill_id, domain) -> success_rate
        self.domain_skill_preferences = {}  # domain -> {skill_type: avg_success_rate}
        
        # ENSEMBLE PREDICTION SYSTEM
        self.ensemble_weights = {}  # (target_domain, source_domain) -> weight
        self.ensemble_history = []  # Track ensemble performance
        self.confidence_thresholds = {}  # domain -> confidence threshold for selection
        self.auto_learned_rules = []  # Automatically discovered composition rules
    
    def categorize_skill(self, domain: str, task_type: str, subtype: str = "") -> list:
        """Intelligently categorize a skill into multiple abstract categories.
        
        Returns list of relevant abstract skill types for this task.
        """
        categories = []
        
        # Pattern recognition - universal across all domains
        categories.append("pattern_recognition")
        
        # Sequential reasoning - algorithms (sorting/search), logic (sequences), causal (chains)
        if any(keyword in task_type.lower() for keyword in ["sort", "search", "sequence", "chain", "order"]):
            categories.append("sequential_reasoning")
        if any(keyword in subtype.lower() for keyword in ["linear", "polynomial", "arithmetic", "geometric"]):
            categories.append("sequential_reasoning")
        
        # Optimization heuristics - optimization problems, function approximation
        if any(keyword in task_type.lower() for keyword in ["optim", "knapsack", "matching", "maximize", "minimize"]):
            categories.append("optimization_heuristics")
        if any(keyword in subtype.lower() for keyword in ["fit", "approximate", "interpolate"]):
            categories.append("optimization_heuristics")
        
        # Causal inference - causal systems, deduction, rule extraction
        if any(keyword in task_type.lower() for keyword in ["causal", "intervention", "confound"]):
            categories.append("causal_inference")
        if any(keyword in subtype.lower() for keyword in ["deduction", "implication", "rule"]):
            categories.append("causal_inference")
        
        # Transformation rules - all domains involve input→output transformations
        if any(keyword in task_type.lower() for keyword in ["transform", "function", "mapping", "infer"]):
            categories.append("transformation_rules")
        if any(keyword in subtype.lower() for keyword in ["linear", "exponential", "logarithmic", "piecewise"]):
            categories.append("transformation_rules")
        
        return categories
    
    def _skill_to_vector(self, skill_data: dict) -> np.ndarray:
        """Convert skill data to a feature vector for similarity computation.
        
        Features:
        - Domain encoding (one-hot)
        - Task type encoding
        - Difficulty level (numeric)
        - Score (numeric)
        """
        # Domain encoding (4 dimensions)
        domain_map = {"algorithm": 0, "logic": 1, "reverse_engineering": 2, "causal": 3}
        domain_vec = np.zeros(4)
        domain_idx = domain_map.get(skill_data.get("domain", "algorithm"), 0)
        domain_vec[domain_idx] = 1.0
        
        # Task type features (8 dimensions - common task types)
        task_type = skill_data.get("task_type", "").lower()
        task_features = np.array([
            1.0 if "sort" in task_type else 0.0,
            1.0 if "search" in task_type else 0.0,
            1.0 if "optim" in task_type else 0.0,
            1.0 if "graph" in task_type else 0.0,
            1.0 if "pattern" in task_type else 0.0,
            1.0 if "sequence" in task_type else 0.0,
            1.0 if "function" in task_type or "infer" in task_type else 0.0,
            1.0 if "causal" in task_type else 0.0,
        ])
        
        # Subtype features (5 dimensions)
        subtype = skill_data.get("subtype", "").lower()
        subtype_features = np.array([
            1.0 if "linear" in subtype else 0.0,
            1.0 if "polynomial" in subtype else 0.0,
            1.0 if any(kw in subtype for kw in ["exponential", "logarithmic"]) else 0.0,
            1.0 if "piecewise" in subtype else 0.0,
            1.0 if any(kw in subtype for kw in ["deduction", "rule"]) else 0.0,
        ])
        
        # Difficulty encoding (3 dimensions - one-hot)
        difficulty_map = {"easy": 0, "medium": 1, "hard": 2}
        difficulty_vec = np.zeros(3)
        diff_idx = difficulty_map.get(skill_data.get("difficulty", "easy"), 0)
        difficulty_vec[diff_idx] = 1.0
        
        # Score (1 dimension)
        score = np.array([skill_data.get("score", 0.0)])
        
        # Concatenate all features
        return np.concatenate([domain_vec, task_features, subtype_features, difficulty_vec, score])
    
    def cosine_similarity(self, vec1: np.ndarray, vec2: np.ndarray) -> float:
        """Compute cosine similarity between two vectors."""
        dot_product = np.dot(vec1, vec2)
        norm1 = np.linalg.norm(vec1)
        norm2 = np.linalg.norm(vec2)
        
        if norm1 == 0 or norm2 == 0:
            return 0.0
        
        return dot_product / (norm1 * norm2)
    
    def get_semantically_relevant_skills(self, target_domain: str, task_type: str, 
                                        current_task_data: dict, top_k: int = 5) -> list:
        """Get skills using semantic similarity instead of keyword matching.
        
        Args:
            target_domain: The domain we're solving for
            task_type: Type of current task
            current_task_data: Current task metadata
            top_k: Number of most similar skills to return
        
        Returns:
            List of skills sorted by semantic similarity
        """
        # Create query vector from current task
        query_skill = {
            "domain": target_domain,
            "task_type": task_type,
            "subtype": current_task_data.get("subtype", ""),
            "difficulty": current_task_data.get("difficulty", "medium"),
            "score": 0.0  # Unknown yet
        }
        query_vec = self._skill_to_vector(query_skill)
        
        # Collect all skills from OTHER domains
        candidate_skills = []
        other_domains = [d for d in self.domain_skills.keys() if d != target_domain]
        
        for domain in other_domains:
            for skill_entry in self.domain_skills[domain]:
                skill_vec = self._skill_to_vector(skill_entry["skill"])
                similarity = self.cosine_similarity(query_vec, skill_vec)
                candidate_skills.append((skill_entry, similarity))
        
        # Also include abstract skills
        for category, skills in self.abstract_skills.items():
            for skill_entry in skills:
                skill_vec = self._skill_to_vector(skill_entry["skill"])
                similarity = self.cosine_similarity(query_vec, skill_vec) * 0.8  # Slight penalty for abstract
                candidate_skills.append((skill_entry, similarity))
        
        # Sort by similarity and return top_k
        candidate_skills.sort(key=lambda x: x[1], reverse=True)
        return [skill for skill, sim in candidate_skills[:top_k]]
    
    def compose_skills(self, skill1_categories: list, skill2_categories: list) -> list:
        """Compose two skills to create a more powerful composite strategy.
        
        Args:
            skill1_categories: List of abstract categories for first skill
            skill2_categories: List of abstract categories for second skill
        
        Returns:
            List of composed skill types that can be created
        """
        composed = []
        
        # Check all pairs of categories
        for cat1 in skill1_categories:
            for cat2 in skill2_categories:
                # Try both orderings
                key1 = (cat1, cat2)
                key2 = (cat2, cat1)
                
                if key1 in self.composition_rules:
                    composed.append(self.composition_rules[key1])
                elif key2 in self.composition_rules:
                    composed.append(self.composition_rules[key2])
        
        return list(set(composed))  # Remove duplicates
    
    def get_composite_strategies(self, target_domain: str, task_data: dict) -> list:
        """Get composite strategies by combining relevant skills.
        
        This enables emergent problem-solving by skill synergy.
        """
        # Get individual skills
        individual_skills = self.get_relevant_skills(
            target_domain,
            task_data.get("type", ""),
            current_task_data={
                "subtype": task_data.get("subtype", ""),
                "difficulty": task_data.get("difficulty", "medium")
            }
        )
        
        if len(individual_skills) < 2:
            return []
        
        # Try composing top skills
        composite_strategies = []
        
        # Get categories for top 2 skills
        if len(individual_skills) >= 2:
            skill1_cats = self.categorize_skill(
                individual_skills[0].get("source_domain", target_domain),
                individual_skills[0].get("skill", {}).get("task_type", ""),
                individual_skills[0].get("skill", {}).get("subtype", "")
            )
            skill2_cats = self.categorize_skill(
                individual_skills[1].get("source_domain", target_domain),
                individual_skills[1].get("skill", {}).get("task_type", ""),
                individual_skills[1].get("skill", {}).get("subtype", "")
            )
            
            # Compose
            composed_types = self.compose_skills(skill1_cats, skill2_cats)
            
            for comp_type in composed_types:
                composite_strategies.append({
                    "type": "composite",
                    "composition": comp_type,
                    "components": [skill1_cats, skill2_cats],
                    "confidence": 0.7  # Lower confidence than proven individual skills
                })
        
        return composite_strategies
    
    def track_skill_usage(self, skill_id: str, episode: int, success: bool):
        """Track when a skill is used and whether it was successful."""
        if skill_id in self.skill_usage_count:
            self.skill_usage_count[skill_id] += 1
            self.last_used_episode[skill_id] = episode
            
            # Track effectiveness for meta-learning
            key = (skill_id, episode % 4)  # Simplified domain tracking
            if key not in self.skill_effectiveness:
                self.skill_effectiveness[key] = {"successes": 0, "total": 0}
            self.skill_effectiveness[key]["total"] += 1
            if success:
                self.skill_effectiveness[key]["successes"] += 1
    
    def apply_skill_decay(self, current_episode: int, unused_threshold: int = 50):
        """Remove skills that haven't been used for >unused_threshold episodes.
        
        Args:
            current_episode: Current episode number
            unused_threshold: Number of episodes without use before removal
        
        Returns:
            Number of skills removed
        """
        self.current_episode = current_episode
        removed_count = 0
        
        # Identify skills to remove
        skills_to_remove = []
        for skill_id, last_used in self.last_used_episode.items():
            if current_episode - last_used > unused_threshold:
                skills_to_remove.append(skill_id)
        
        # Remove from domain-specific skills
        for domain in self.domain_skills.keys():
            original_count = len(self.domain_skills[domain])
            self.domain_skills[domain] = [
                s for s in self.domain_skills[domain]
                if s["skill"].get("skill_id") not in skills_to_remove
            ]
            removed_count += original_count - len(self.domain_skills[domain])
        
        # Remove from abstract skills
        for category in self.abstract_skills.keys():
            original_count = len(self.abstract_skills[category])
            self.abstract_skills[category] = [
                s for s in self.abstract_skills[category]
                if s["skill"].get("skill_id") not in skills_to_remove
            ]
            removed_count += original_count - len(self.abstract_skills[category])
        
        # Clean up tracking data
        for skill_id in skills_to_remove:
            del self.skill_usage_count[skill_id]
            del self.last_used_episode[skill_id]
        
        return removed_count
    
    def consolidate_similar_skills(self, similarity_threshold: float = 0.9):
        """Merge highly similar skills to prevent redundancy.
        
        Args:
            similarity_threshold: Cosine similarity threshold for merging
        
        Returns:
            Number of skills merged
        """
        merged_count = 0
        
        # Process each domain separately
        for domain in self.domain_skills.keys():
            skills = self.domain_skills[domain]
            if len(skills) < 2:
                continue
            
            # Compute pairwise similarities
            vectors = []
            for skill_entry in skills:
                vec = self._skill_to_vector(skill_entry["skill"])
                vectors.append(vec)
            
            # Find pairs to merge
            to_merge = set()
            for i in range(len(skills)):
                if i in to_merge:
                    continue
                for j in range(i + 1, len(skills)):
                    if j in to_merge:
                        continue
                    sim = self.cosine_similarity(vectors[i], vectors[j])
                    if sim > similarity_threshold:
                        to_merge.add(j)
            
            # Merge skills (keep first, remove others)
            if to_merge:
                indices_to_keep = [i for i in range(len(skills)) if i not in to_merge]
                self.domain_skills[domain] = [skills[i] for i in indices_to_keep]
                merged_count += len(to_merge)
        
        return merged_count
    
    def get_meta_learning_insights(self) -> dict:
        """Analyze skill effectiveness patterns across domains.
        
        Returns:
            Dictionary with meta-learning insights
        """
        insights = {
            "domain_preferences": {},
            "top_performing_skills": [],
            "skill_category_effectiveness": {}
        }
        
        # Analyze domain preferences
        for domain in self.domain_skills.keys():
            skills = self.domain_skills[domain]
            if not skills:
                continue
            
            # Calculate average success rate for this domain's skills
            total_usage = sum(self.skill_usage_count.get(s["skill"].get("skill_id", ""), 0) for s in skills)
            if total_usage > 0:
                insights["domain_preferences"][domain] = {
                    "total_skills": len(skills),
                    "total_usage": total_usage,
                    "avg_usage_per_skill": total_usage / len(skills)
                }
        
        # Find top performing skills (most used)
        sorted_skills = sorted(
            self.skill_usage_count.items(),
            key=lambda x: x[1],
            reverse=True
        )
        insights["top_performing_skills"] = [
            {"skill_id": sid, "usage_count": count}
            for sid, count in sorted_skills[:10]
        ]
        
        # Analyze category effectiveness
        for category, skills in self.abstract_skills.items():
            if not skills:
                continue
            
            total_usage = sum(
                self.skill_usage_count.get(s["skill"].get("skill_id", ""), 0)
                for s in skills
            )
            insights["skill_category_effectiveness"][category] = {
                "skill_count": len(skills),
                "total_usage": total_usage,
                "avg_usage": total_usage / len(skills) if skills else 0
            }
        
        return insights
    
    def get_adaptive_skill_recommendations(self, target_domain: str, task_data: dict) -> dict:
        """Get personalized skill recommendations based on meta-learning.
        
        Uses historical performance data to recommend the most effective skills.
        
        Args:
            target_domain: Domain we're solving for
            task_data: Current task metadata
        
        Returns:
            Dictionary with recommendations
        """
        insights = self.get_meta_learning_insights()
        
        # Get standard semantic matches
        semantic_skills = self.get_relevant_skills(
            target_domain,
            task_data.get("type", ""),
            current_task_data={
                "subtype": task_data.get("subtype", ""),
                "difficulty": task_data.get("difficulty", "medium")
            }
        )
        
        # Rank by usage frequency (proxy for effectiveness)
        ranked_skills = []
        for skill_entry in semantic_skills:
            skill_id = skill_entry.get("skill", {}).get("skill_id", "")
            usage = self.skill_usage_count.get(skill_id, 0)
            ranked_skills.append((skill_entry, usage))
        
        # Sort by usage (most used first)
        ranked_skills.sort(key=lambda x: x[1], reverse=True)
        
        return {
            "recommended_skills": [s for s, _ in ranked_skills[:5]],
            "meta_insights": insights,
            "reasoning": f"Ranked by historical usage frequency in {target_domain} domain"
        }
    
    def add_skill(self, domain: str, skill_type: str, skill_data: dict):
        """Add a skill to both domain-specific and abstract memory."""
        # Assign unique ID to skill
        skill_id = f"{domain}_{self.next_skill_id}"
        self.next_skill_id += 1
        skill_data["skill_id"] = skill_id
        
        # Initialize usage tracking
        self.skill_usage_count[skill_id] = 0
        self.last_used_episode[skill_id] = self.current_episode
        
        # Add to domain-specific
        self.domain_skills[domain].append({
            "skill": skill_data,
            "timestamp": datetime.now().isoformat(),
            "success_count": 1
        })
        
        # Map to abstract skill type(s) - can be multiple!
        if isinstance(skill_type, list):
            # Multiple categories
            for st in skill_type:
                if st in self.abstract_skills:
                    self.abstract_skills[st].append({
                        "source_domain": domain,
                        "skill": skill_data,
                        "timestamp": datetime.now().isoformat()
                    })
        elif skill_type in self.abstract_skills:
            # Single category (backward compatibility)
            self.abstract_skills[skill_type].append({
                "source_domain": domain,
                "skill": skill_data,
                "timestamp": datetime.now().isoformat()
            })
    
    def get_relevant_skills(self, target_domain: str, task_type: str, 
                           current_task_data: dict = None) -> list:
        """Get relevant skills from ALL domains using semantic matching.
        
        Uses cosine similarity for intelligent skill matching instead of keywords.
        """
        if current_task_data is None:
            # Fallback to old keyword-based method for backward compatibility
            return self._get_relevant_skills_keyword(target_domain, task_type)
        else:
            # Use new semantic matching
            return self.get_semantically_relevant_skills(
                target_domain, task_type, current_task_data, top_k=5
            )
    
    def _get_relevant_skills_keyword(self, target_domain: str, task_type: str) -> list:
        """Legacy keyword-based skill retrieval (for backward compatibility)."""
        relevant = []
        
        # Get domain-specific skills
        relevant.extend(self.domain_skills.get(target_domain, []))
        
        # Get abstract skills (cross-domain transfer!)
        if "pattern" in task_type or "infer" in task_type:
            relevant.extend(self.abstract_skills["pattern_recognition"])
        if "sequence" in task_type or "chain" in task_type:
            relevant.extend(self.abstract_skills["sequential_reasoning"])
        if "optim" in task_type or "recover" in task_type:
            relevant.extend(self.abstract_skills["optimization_heuristics"])
        if "causal" in task_type or "intervention" in task_type:
            relevant.extend(self.abstract_skills["causal_inference"])
        if "transform" in task_type or "function" in task_type:
            relevant.extend(self.abstract_skills["transformation_rules"])
        
        return relevant
    
    def log_transfer(self, source_domain: str, target_domain: str, success: bool):
        """Log skill transfer attempt."""
        self.transfer_log.append({
            "source": source_domain,
            "target": target_domain,
            "success": success,
            "timestamp": datetime.now().isoformat()
        })
    
    def get_ensemble_predictions(self, task: dict, domains: dict, evolvers: dict, episode: int) -> dict:
        """Generate predictions from multiple domain evolvers and combine them.
        
        This implements true hybrid collaboration where different domains
        contribute their specialized knowledge to solve a single task.
        
        Args:
            task: The task to solve
            domains: Dictionary of domain generators
            evolvers: Dictionary of domain evolvers
            episode: Current episode number
        
        Returns:
            Dictionary with ensemble prediction and confidence scores
        """
        target_domain = task.get("domain", "")
        predictions = []
        confidences = []
        
        # Get predictions from ALL domain evolvers (not just target)
        for domain_name, evolver in evolvers.items():
            try:
                # Create variant using this domain's evolver
                solution_func = evolver.create_variant(task, episode=episode)
                
                # Generate prediction
                output = solution_func(**task.get("inputs", {}))
                
                # Calculate confidence based on historical performance
                if domain_name == target_domain:
                    base_confidence = 0.8  # Higher confidence for target domain
                else:
                    # Cross-domain confidence based on ensemble weights
                    weight = self.ensemble_weights.get((target_domain, domain_name), 0.3)
                    base_confidence = weight
                
                predictions.append({
                    "domain": domain_name,
                    "prediction": output,
                    "confidence": base_confidence
                })
                confidences.append(base_confidence)
                
            except Exception as e:
                # Track error and skip domain
                error_tracker.record_error(
                    error_type=type(e).__name__,
                    message=str(e),
                    context={"domain": domain_name, "task_type": task.get("type", "")},
                    severity="warning"
                )
                continue
        
        if not predictions:
            return {"prediction": None, "confidence": 0.0, "method": "failed"}
        
        # Normalize confidences
        total_conf = sum(confidences)
        if total_conf > 0:
            normalized_confidences = [c / total_conf for c in confidences]
        else:
            normalized_confidences = [1.0 / len(confidences)] * len(confidences)
        
        # Check if all predictions are dicts or all are scalars
        all_dicts = all(isinstance(pred["prediction"], dict) for pred in predictions)
        all_scalars = all(not isinstance(pred["prediction"], dict) for pred in predictions)
        
        if all_dicts:
            # For dict outputs, merge with weighted averaging
            ensemble_output = {}
            all_keys = set()
            for pred in predictions:
                if isinstance(pred["prediction"], dict):
                    all_keys.update(pred["prediction"].keys())
            
            for key in all_keys:
                weighted_sum = 0.0
                for pred, conf in zip(predictions, normalized_confidences):
                    if isinstance(pred["prediction"], dict):
                        weighted_sum += conf * pred["prediction"].get(key, 0.0)
                ensemble_output[key] = weighted_sum
        elif all_scalars:
            # For scalar outputs, weighted average
            ensemble_output = sum(
                pred["prediction"] * conf 
                for pred, conf in zip(predictions, normalized_confidences)
            )
        else:
            # Mixed types - use first prediction as fallback
            ensemble_output = predictions[0]["prediction"]
        
        # Calculate overall confidence (max confidence among contributors)
        overall_confidence = max(normalized_confidences) if normalized_confidences else 0.0
        
        return {
            "prediction": ensemble_output,
            "confidence": overall_confidence,
            "contributing_domains": [p["domain"] for p in predictions],
            "method": "ensemble_weighted_average",
            "individual_predictions": predictions
        }
    
    def update_ensemble_weights(self, target_domain: str, contributing_domains: list, success: bool, score: float):
        """Update ensemble weights based on performance feedback.
        
        Reinforces successful cross-domain collaborations.
        """
        learning_rate = 0.1
        
        for domain in contributing_domains:
            key = (target_domain, domain)
            current_weight = self.ensemble_weights.get(key, 0.3)
            
            if success:
                # Boost weight for successful collaborations
                new_weight = current_weight + learning_rate * score
            else:
                # Slightly reduce weight for failures
                new_weight = max(0.1, current_weight - learning_rate * 0.5)
            
            self.ensemble_weights[key] = min(1.0, new_weight)
        
        # Log ensemble performance
        self.ensemble_history.append({
            "target_domain": target_domain,
            "contributing_domains": contributing_domains,
            "success": success,
            "score": score,
            "weights_used": {str(k): v for k, v in self.ensemble_weights.items()}
        })
    
    def get_confidence_threshold(self, domain: str) -> float:
        """Get adaptive confidence threshold for composite selection.
        
        Thresholds adapt based on domain difficulty and recent performance.
        """
        if domain not in self.confidence_thresholds:
            # Initialize with default thresholds per domain
            default_thresholds = {
                "algorithm": 0.6,
                "logic": 0.65,
                "reverse_engineering": 0.7,
                "causal": 0.75
            }
            self.confidence_thresholds[domain] = default_thresholds.get(domain, 0.65)
        
        return self.confidence_thresholds[domain]
    
    def update_confidence_threshold(self, domain: str, recent_success_rate: float):
        """Dynamically adjust confidence threshold based on recent performance.
        
        If success rate is high, lower threshold to be more aggressive.
        If success rate is low, raise threshold to be more selective.
        """
        current_threshold = self.get_confidence_threshold(domain)
        
        if recent_success_rate > 0.7:
            # High success - can afford to be less selective
            new_threshold = max(0.5, current_threshold - 0.05)
        elif recent_success_rate < 0.3:
            # Low success - need to be more selective
            new_threshold = min(0.9, current_threshold + 0.05)
        else:
            # Moderate success - keep current threshold
            new_threshold = current_threshold
        
        self.confidence_thresholds[domain] = new_threshold
    
    def learn_composition_rule(self, skill1_type: str, skill2_type: str, success: bool, context: dict):
        """Automatically discover new composition rules from successful combinations.
        
        Expands composition vocabulary by learning which skill combinations work.
        """
        rule_key = (skill1_type, skill2_type)
        
        # Track rule attempts
        if not hasattr(self, '_rule_attempts'):
            self._rule_attempts = {}  # rule_key -> {successes, total}
        
        if rule_key not in self._rule_attempts:
            self._rule_attempts[rule_key] = {"successes": 0, "total": 0}
        
        self._rule_attempts[rule_key]["total"] += 1
        if success:
            self._rule_attempts[rule_key]["successes"] += 1
        
        # If rule has proven effective (>60% success over >=5 attempts), add it
        stats = self._rule_attempts[rule_key]
        if stats["total"] >= 5 and stats["successes"] / stats["total"] > 0.6:
            # Generate rule name from context
            rule_name = f"auto_{skill1_type}_{skill2_type}"
            
            # Check if rule already exists
            existing_rules = set(self.composition_rules.values())
            if rule_name not in existing_rules:
                self.composition_rules[rule_key] = rule_name
                self.auto_learned_rules.append({
                    "rule": rule_name,
                    "components": [skill1_type, skill2_type],
                    "success_rate": stats["successes"] / stats["total"],
                    "attempts": stats["total"],
                    "learned_at_episode": self.current_episode,
                    "context": context
                })


def run_multi_domain_experiment(num_episodes=200):
    """Run experiment across all 4 domains with skill transfer."""
    
    # Initialize domain generators
    domains = {
        "algorithm": AlgorithmTaskGenerator(seed=42),
        "logic": LogicPuzzleGenerator(seed=43),
        "reverse_engineering": ReverseEngineeringGenerator(seed=44),
        "causal": CausalSystemGenerator(seed=45)
    }
    
    # Initialize evolvers (ALL DOMAINS NOW HAVE DEDICATED EVOLVERS!)
    evolvers = {
        "algorithm": AlgorithmEvolver(seed=123),
        "logic": LogicPuzzleEvolver(seed=124),
        "reverse_engineering": ReverseEngineeringEvolver(seed=125),
        "causal": CausalSystemEvolver(seed=126)
    }
    
    evaluator = Evaluator()
    skill_memory = CrossDomainSkillMemory()
    error_tracker = ErrorTracker(log_dir="logs/multi_domain")
    
    print("=" * 80)
    print("MULTI-DOMAIN EXPERIMENT WITH CROSS-DOMAIN SKILL TRANSFER")
    print("=" * 80)
    print(f"Episodes: {num_episodes}")
    print(f"Domains: {', '.join(domains.keys())}")
    print(f"Start Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Track results
    episode_results = []
    domain_stats = {domain: {"count": 0, "successes": 0, "scores": []} 
                    for domain in domains.keys()}
    
    # Synergy tracking - compare episodes with vs without composite strategies
    synergy_tracking = {
        "with_composites": {"episodes": 0, "successes": 0, "scores": []},
        "without_composites": {"episodes": 0, "successes": 0, "scores": []}
    }
    
    start_time = time.time()
    
    # Cycle through domains
    domain_list = list(domains.keys())
    
    for episode in range(1, num_episodes + 1):
        # Update current episode for skill memory
        skill_memory.current_episode = episode
        
        # Select domain (round-robin)
        domain_name = domain_list[(episode - 1) % len(domain_list)]
        domain_gen = domains[domain_name]
        
        # Generate task
        task = domain_gen.generate_task(episode=episode)
        task["domain"] = domain_name  # Add domain info to task
        domain_stats[domain_name]["count"] += 1
        
        # Get relevant skills from OTHER domains (cross-domain transfer with semantic matching)
        other_domains = [d for d in domain_list if d != domain_name]
        transferred_skills = []
        for other_domain in other_domains:
            # Use semantic matching instead of keyword matching
            skills = skill_memory.get_relevant_skills(
                other_domain, 
                task.get("type", ""),
                current_task_data={
                    "subtype": task.get("subtype", ""),
                    "difficulty": task.get("difficulty", "medium")
                }
            )
            transferred_skills.extend(skills[:2])  # Top 2 skills from each domain
        
        # Try to compose composite strategies from transferred skills
        composite_strategies = skill_memory.get_composite_strategies(domain_name, task)
        
        # DECISION: Use single-domain first, ensemble as fallback
        # Strategy: Try primary domain evolver first
        evolver = evolvers[domain_name]
        
        # NEW: Pass transferred skills to evolver for cross-domain learning
        solution_func = evolver.create_variant(task, episode=episode, external_skills=transferred_skills)
        
        # Evaluate primary solution
        result = evaluator.evaluate(solution_func, task["inputs"])
        correctness = result["metrics"]["correctness"]
        
        # Verify solution using domain-specific verifier
        try:
            output = solution_func(**task["inputs"])
            if isinstance(output, dict):
                output_value = output.get("output", output)
            else:
                output_value = output
            success = domain_gen.verify_solution(task, output_value)
        except Exception as e:
            error_tracker.record_error(
                error_type=type(e).__name__,
                message=str(e),
                context={
                    "domain": domain_name,
                    "task_type": task.get("type", ""),
                    "episode": episode
                },
                severity="error"
            )
            success = False
        
        # If primary failed AND we have composite strategies, try ensemble as fallback
        used_method = "single_domain"
        if not success and len(composite_strategies) > 0 and len(transferred_skills) >= 2:
            # ENSEMBLE FALLBACK MODE
            ensemble_result = skill_memory.get_ensemble_predictions(task, domains, evolvers, episode)
            
            # Create wrapper function that returns ensemble prediction
            def ensemble_solution_func(**kwargs):
                return ensemble_result["prediction"]
            
            # Re-evaluate with ensemble
            ensemble_result_eval = evaluator.evaluate(ensemble_solution_func, task["inputs"])
            
            try:
                ensemble_output = ensemble_solution_func(**task["inputs"])
                if isinstance(ensemble_output, dict):
                    ensemble_output_value = ensemble_output.get("output", ensemble_output)
                else:
                    ensemble_output_value = ensemble_output
                ensemble_success = domain_gen.verify_solution(task, ensemble_output_value)
            except Exception:
                ensemble_success = False
            
            # Use ensemble if it succeeds where primary failed
            if ensemble_success:
                result = ensemble_result_eval
                correctness = result["metrics"]["correctness"]
                output = ensemble_output
                output_value = ensemble_output_value
                success = ensemble_success
                used_method = "ensemble_fallback"
        
        # Update performance tracking
        domain_gen.update_performance(success)
        
        # Update evolver quality (for domains that support it)
        if hasattr(evolver, 'update_quality'):
            evolver.update_quality(success, correctness, solution_func)
        
        # Track statistics
        if success:
            domain_stats[domain_name]["successes"] += 1
        domain_stats[domain_name]["scores"].append(result["score"])
        
        # Update ensemble weights if ensemble was used
        if used_method == "ensemble_fallback" and 'ensemble_result' in locals():
            contributing_domains = ensemble_result.get("contributing_domains", [])
            skill_memory.update_ensemble_weights(domain_name, contributing_domains, success, result["score"])
        
        # Learn composition rules from successful combinations
        if success and len(composite_strategies) > 0:
            for comp_strategy in composite_strategies[:2]:  # Learn from top 2
                if "components" in comp_strategy:
                    skill1_cats, skill2_cats = comp_strategy["components"]
                    if skill1_cats and skill2_cats:
                        skill_memory.learn_composition_rule(
                            skill1_cats[0] if skill1_cats else "unknown",
                            skill2_cats[0] if skill2_cats else "unknown",
                            success,
                            {
                                "domain": domain_name,
                                "task_type": task.get("type", ""),
                                "episode": episode
                            }
                        )
        
        # Store successful skills with intelligent categorization
        if success:
            # Automatically categorize skill into multiple abstract categories
            skill_categories = skill_memory.categorize_skill(
                domain_name, 
                task.get("type", ""), 
                task.get("subtype", "")
            )
            
            skill_data = {
                "task_type": task.get("type", ""),
                "subtype": task.get("subtype", ""),
                "difficulty": task.get("difficulty", "easy"),
                "score": result["score"],
                "domain": domain_name
            }
            
            # Add skill to all relevant categories
            skill_memory.add_skill(domain_name, skill_categories, skill_data)
        
        # Track skill usage for transferred skills (meta-learning)
        for skill_entry in transferred_skills[:2]:  # Track top 2 used skills
            skill_id = skill_entry.get("skill", {}).get("skill_id", "")
            if skill_id:
                skill_memory.track_skill_usage(skill_id, episode, success)
        
        # Log episode
        episode_data = {
            "episode": episode,
            "domain": domain_name,
            "task_type": task.get("type", ""),
            "subtype": task.get("subtype", ""),
            "difficulty": task.get("difficulty", "easy"),
            "success": success,
            "score": result["score"],
            "correctness": correctness,
            "transferred_skills": len(transferred_skills),
            "composite_strategies": len(composite_strategies),
            "used_method": used_method,  # Track if ensemble or single-domain was used
            "timestamp": datetime.now().isoformat()
        }
        episode_results.append(episode_data)
        
        # Track synergy - episodes with vs without composite strategies
        if used_method == "ensemble_fallback":
            synergy_tracking["with_composites"]["episodes"] += 1
            if success:
                synergy_tracking["with_composites"]["successes"] += 1
            synergy_tracking["with_composites"]["scores"].append(result["score"])
        else:
            synergy_tracking["without_composites"]["episodes"] += 1
            if success:
                synergy_tracking["without_composites"]["successes"] += 1
            synergy_tracking["without_composites"]["scores"].append(result["score"])
        
        # Print progress every 20 episodes
        if episode % 20 == 0:
            elapsed = time.time() - start_time
            recent_success = sum(r["success"] for r in episode_results[-20:]) / 20
            
            # Update confidence thresholds based on recent performance
            skill_memory.update_confidence_threshold(domain_name, recent_success)
            
            print(f"Episode {episode}/{num_episodes} | "
                  f"Recent Success: {recent_success:.1%} | "
                  f"Skills Stored: {sum(len(v) for v in skill_memory.abstract_skills.values())} | "
                  f"Time: {elapsed:.1f}s")
        
        # Apply skill decay and consolidation every 50 episodes
        if episode % 50 == 0 and episode > 0:
            removed = skill_memory.apply_skill_decay(episode, unused_threshold=50)
            merged = skill_memory.consolidate_similar_skills(similarity_threshold=0.9)
            if removed > 0 or merged > 0:
                print(f"  [Cleanup] Removed {removed} unused skills, merged {merged} similar skills")
    
    total_elapsed = time.time() - start_time
    
    # Calculate overall statistics
    overall_success = sum(1 for r in episode_results if r["success"]) / len(episode_results)
    avg_score = sum(r["score"] for r in episode_results) / len(episode_results)
    
    print("\n" + "=" * 80)
    print("EXPERIMENT COMPLETE")
    print("=" * 80)
    print(f"Total Time: {total_elapsed:.2f}s")
    print(f"Overall Success Rate: {overall_success:.1%}")
    print(f"Average Intelligence Score: {avg_score:.4f}")
    print()
    
    # Domain breakdown
    print("DOMAIN BREAKDOWN:")
    print("-" * 80)
    for domain in domain_list:
        stats = domain_stats[domain]
        count = stats["count"]
        successes = stats["successes"]
        success_rate = successes / count if count > 0 else 0
        avg_domain_score = sum(stats["scores"]) / len(stats["scores"]) if stats["scores"] else 0
        
        print(f"  {domain.upper():25s}: {count:3d} tasks | Success: {success_rate:.1%} | Avg Score: {avg_domain_score:.4f}")
    print()
    
    # Cross-domain transfer analysis
    print("CROSS-DOMAIN SKILL TRANSFER ANALYSIS:")
    print("-" * 80)
    print(f"Abstract Skills Stored:")
    for skill_type, skills in skill_memory.abstract_skills.items():
        print(f"  {skill_type:30s}: {len(skills)} skills")
    print()
    
    print(f"Domain-Specific Skills:")
    for domain, skills in skill_memory.domain_skills.items():
        print(f"  {domain:25s}: {len(skills)} skills")
    print()
    
    # Composite strategies analysis
    total_composites = sum(r.get("composite_strategies", 0) for r in episode_results)
    avg_composites = total_composites / len(episode_results) if episode_results else 0
    
    # Count ensemble vs single-domain usage
    ensemble_count = sum(1 for r in episode_results if r.get("used_method") == "ensemble_fallback")
    single_count = sum(1 for r in episode_results if r.get("used_method") == "single_domain")
    
    print(f"Skill Composition:")
    print(f"  Total composite strategies generated: {total_composites}")
    print(f"  Average per episode: {avg_composites:.2f}")
    print(f"  Composition rules defined: {len(skill_memory.composition_rules)}")
    print(f"  Auto-learned rules: {len(skill_memory.auto_learned_rules)}")
    print()
    
    print(f"Prediction Method Distribution:")
    print(f"  Ensemble fallback (rescue): {ensemble_count} episodes ({ensemble_count/len(episode_results)*100:.1f}%)")
    print(f"  Single-domain predictions: {single_count} episodes ({single_count/len(episode_results)*100:.1f}%)")
    print()
    
    # Transfer effectiveness
    if skill_memory.transfer_log:
        transfer_success = sum(1 for t in skill_memory.transfer_log if t["success"]) / len(skill_memory.transfer_log)
        print(f"Skill Transfer Attempts: {len(skill_memory.transfer_log)}")
        print(f"Transfer Success Rate: {transfer_success:.1%}")
    print()
    
    # Error tracking summary
    error_summary = error_tracker.get_error_summary()
    if error_summary["total_errors"] > 0:
        print("ERROR TRACKING SUMMARY:")
        print("-" * 80)
        print(f"Total Errors: {error_summary['total_errors']}")
        print(f"Error Rate: {error_summary['error_rate']:.1%}")
        print(f"\nErrors by Type:")
        for error_type, count in sorted(error_summary["by_type"].items(), key=lambda x: -x[1]):
            print(f"  {error_type:30s}: {count}")
        print(f"\nErrors by Domain:")
        for domain, stats in sorted(error_summary["by_domain"].items()):
            rate = stats["errors"] / stats["total"] if stats["total"] > 0 else 0
            print(f"  {domain:25s}: {stats['errors']}/{stats['total']} ({rate:.1%})")
        print()
    
    # Meta-learning insights
    print("META-LEARNING INSIGHTS:")
    print("-" * 80)
    meta_insights = skill_memory.get_meta_learning_insights()
    
    print(f"Domain Skill Preferences:")
    for domain, stats in meta_insights["domain_preferences"].items():
        print(f"  {domain:25s}: {stats['total_skills']:3d} skills | "
              f"Total usage: {stats['total_usage']:4d} | "
              f"Avg/skill: {stats['avg_usage_per_skill']:.1f}")
    print()
    
    print(f"Top 10 Most Used Skills:")
    for i, skill_info in enumerate(meta_insights["top_performing_skills"], 1):
        print(f"  {i:2d}. {skill_info['skill_id']:30s} - Used {skill_info['usage_count']} times")
    print()
    
    print(f"Skill Category Effectiveness:")
    for category, stats in meta_insights["skill_category_effectiveness"].items():
        print(f"  {category:30s}: {stats['skill_count']:3d} skills | "
              f"Total usage: {stats['total_usage']:4d} | "
              f"Avg/skill: {stats['avg_usage']:.1f}")
    print()
    
    # Difficulty analysis
    print("DIFFICULTY DISTRIBUTION:")
    print("-" * 80)
    difficulty_stats = {}
    for r in episode_results:
        diff = r["difficulty"]
        if diff not in difficulty_stats:
            difficulty_stats[diff] = {"count": 0, "successes": 0}
        difficulty_stats[diff]["count"] += 1
        if r["success"]:
            difficulty_stats[diff]["successes"] += 1
    
    for diff in ["easy", "medium", "hard"]:
        if diff in difficulty_stats:
            stats = difficulty_stats[diff]
            rate = stats["successes"] / stats["count"] if stats["count"] > 0 else 0
            print(f"  {diff.upper():8s}: {stats['count']:3d} tasks | Success: {rate:.1%}")
    print()
    
    # Skill synergy analysis
    print("SKILL SYNERGY ANALYSIS:")
    print("-" * 80)
    with_comp = synergy_tracking["with_composites"]
    without_comp = synergy_tracking["without_composites"]
    
    with_rate = with_comp["successes"] / with_comp["episodes"] if with_comp["episodes"] > 0 else 0
    without_rate = without_comp["successes"] / without_comp["episodes"] if without_comp["episodes"] > 0 else 0
    
    with_avg_score = sum(with_comp["scores"]) / len(with_comp["scores"]) if with_comp["scores"] else 0
    without_avg_score = sum(without_comp["scores"]) / len(without_comp["scores"]) if without_comp["scores"] else 0
    
    print(f"Episodes WITH Composite Strategies:")
    print(f"  Count: {with_comp['episodes']} episodes")
    print(f"  Success Rate: {with_rate:.1%}")
    print(f"  Avg Intelligence Score: {with_avg_score:.4f}")
    print()
    
    print(f"Episodes WITHOUT Composite Strategies:")
    print(f"  Count: {without_comp['episodes']} episodes")
    print(f"  Success Rate: {without_rate:.1%}")
    print(f"  Avg Intelligence Score: {without_avg_score:.4f}")
    print()
    
    synergy_effect = with_rate - without_rate
    score_effect = with_avg_score - without_avg_score
    
    print(f"Synergy Effect:")
    print(f"  Success Rate Difference: {synergy_effect:+.1%} {'(POSITIVE)' if synergy_effect > 0 else '(NEGATIVE)'}")
    print(f"  Score Difference: {score_effect:+.4f} {'(POSITIVE)' if score_effect > 0 else '(NEGATIVE)'}")
    
    if synergy_effect > 0.05:
        print(f"  [STRONG] Composite strategies improve performance!")
    elif synergy_effect > 0:
        print(f"  [MODERATE] Some improvement from composite strategies")
    else:
        print(f"  [NOTE] Composite strategies not showing clear benefit yet")
    print()
    
    # Auto-learned composition rules
    if skill_memory.auto_learned_rules:
        print("AUTO-LEARNED COMPOSITION RULES:")
        print("-" * 80)
        for i, rule in enumerate(skill_memory.auto_learned_rules[:10], 1):  # Show top 10
            print(f"  {i}. {rule['rule']}")
            print(f"     Components: {rule['components']}")
            print(f"     Success Rate: {rule['success_rate']:.1%} ({rule['attempts']} attempts)")
            print(f"     Learned at episode: {rule['learned_at_episode']}")
            print()
    
    # Ensemble weight analysis
    if skill_memory.ensemble_weights:
        print("ENSEMBLE WEIGHT ANALYSIS (Top Cross-Domain Collaborations):")
        print("-" * 80)
        sorted_weights = sorted(
            skill_memory.ensemble_weights.items(),
            key=lambda x: x[1],
            reverse=True
        )
        for (target, source), weight in sorted_weights[:10]:
            if target != source:  # Only show cross-domain weights
                print(f"  {source:25s} -> {target:25s}: weight={weight:.3f}")
        print()
    
    # Save results
    output_file = Path("multi_domain_episodes.jsonl")
    with open(output_file, 'w', encoding='utf-8') as f:
        for result in episode_results:
            f.write(json.dumps(result) + "\n")
    
    print(f"Results saved to: {output_file}")
    print("=" * 80)
    
    return episode_results, skill_memory


if __name__ == "__main__":
    results, skills = run_multi_domain_experiment(num_episodes=200)
