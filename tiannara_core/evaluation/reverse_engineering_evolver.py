"""Reverse Engineering Evolution Engine - Function Inference Mutations.

Implements mutations for discovering hidden functions from input-output examples.
Supports polynomial fitting, piecewise functions, and black-box recovery.
"""

import random
from typing import Callable, Dict, Any, List, Optional
from tiannara_core.evaluation.ecm_forgetting_mechanism import SkillMemoryWithForgetting, TraceCompressor
from tiannara_core.evaluation.information_pruner import InformationTheoreticPruner
from tiannara_core.evaluation.unified_skill_representation import (
    UniversalSkill,
    SkillType,
    AbstractionLevel,
    SkillConverter,
    UnifiedSkillMemory
)
from tiannara_core.evaluation.stagnation_detection import StagnationDetector, AdaptiveStrategySelector


class ReverseEngineeringEvolver:
    """Creates mutations for reverse engineering tasks."""
    
    def __init__(self, seed: int = None):
        self.rng = random.Random(seed)
        
        # Quality tracking (adaptive) - start HIGH for reverse engineering
        self.quality_level = 0.95  # Start high - needs exact function recovery
        self.success_count = 0
        self.total_attempts = 0
        
        # ECM-aligned skill memory with forgetting
        self.skill_memory = SkillMemoryWithForgetting(
            max_skills=100,
            decay_rate=0.01,
            salience_threshold=0.05,
            checkpoint_interval=50
        )
        
        # Trace compressor for execution traces
        self.trace_compressor = TraceCompressor(batch_size=50)
        
        # ECM Layer 4: Information-Theoretic Pruner
        self.information_pruner = InformationTheoreticPruner(
            prune_threshold=0.3,
            exploration_weight=2.0,
            cache_size=1000
        )
        
        # Cross-domain skill transfer memory (unified representation)
        self.unified_skill_memory = UnifiedSkillMemory()
        
        # Skill counter for auto-ID generation
        self.skill_counter = 0
        
        # Stagnation detection and adaptive strategy selection
        self.stagnation_detector = StagnationDetector(window_size=20, threshold=0.02)
        self.strategy_selector = AdaptiveStrategySelector([
            "polynomial_fit", "piecewise_infer", "linear_fit",
            "rule_extraction", "pattern_generalize", "exponential_fit"
        ])
        self.last_strategy = None
        self.last_success = False
        self.last_quality = 0.0
        
    def update_quality(self, success: bool, correctness: float = None, current_solution = None, task: Dict[str, Any] = None, episode: int = 0):
        """Update quality based on performance and extract skills from successes.
        
        Args:
            success: Whether the solution was correct
            correctness: Quality score (0.0-1.0)
            current_solution: The solution function
            task: Task dictionary (optional, for skill extraction)
            episode: Episode number (optional, for skill tracking)
        """
        # STAGNATION DETECTION: Record episode for monitoring
        if self.last_strategy:
            self.stagnation_detector.record_episode(
                episode, success, correctness or 0.0, self.last_strategy
            )
        
        if success:
            # Boost quality aggressively for reverse engineering (needs exact answers)
            self.quality_level = min(0.99, self.quality_level + 0.08)
            
            # Extract skill from successful solution
            if current_solution is not None and task is not None:
                self._extract_skill_from_success(current_solution, task, episode, correctness or 1.0)
        else:
            # Don't decay on failure - maintain current quality
            pass
        
        # Track for next episode
        self.last_success = success
        self.last_quality = correctness or 0.0
        
        # ECM Layer 4: Update information-theoretic pruner
        func_type = getattr(current_solution, '_func_type', 'unknown') if current_solution else 'unknown'
        self.information_pruner.record_mutation_outcome(
            task_type=func_type,
            operator_name="function_inference",
            actual_quality=correctness if correctness is not None else (1.0 if success else 0.0),
            execution_time=0.0
        )
    
    def _extract_function_type(self, task: Dict[str, Any]) -> str:
        """Determine the type of function to infer.
        
        FIXED: Use 'subtype' field instead of non-existent 'function_type'.
        ENHANCED: Detect algorithmic vs mathematical patterns.
        """
        # Try subtype first (used by domain generator)
        func_type = task.get("subtype", "linear")
        
        # Map subtype names to simpler function type names
        type_mapping = {
            "linear_function": "linear",
            "polynomial": "polynomial",
            "piecewise": "piecewise",
            "modulo_pattern": "modulo",
            "exponential": "exponential",
            "logarithmic": "logarithmic",
            "algorithm_recognition": "algorithm_recognition",  # Keep as-is for special handling
            "edge_case": "linear"  # Default for edge cases
        }
        
        mapped_type = type_mapping.get(func_type, func_type)
        
        # NOVEL: Detect if this is actually an algorithmic pattern (not mathematical)
        # Check if inputs are complex structures (lists, tuples) rather than scalars
        inputs = task.get("inputs", {}).get("examples", [])
        if inputs and len(inputs) > 0:
            first_input = inputs[0].get("input", None) if isinstance(inputs[0], dict) else inputs[0][0]
            # If input is a list/tuple (not scalar), it's likely algorithmic
            if isinstance(first_input, (list, tuple)) and len(first_input) > 1:
                # This is algorithmic - use ensemble approach
                return "algorithm_recognition"
        
        return mapped_type
    
    def _select_best_strategy(self, inputs: List[float], outputs: List[float], func_type: str) -> str:
        """Intelligently select the best mutation strategy based on data patterns.
        
        IMPROVED: Better polynomial detection with R² analysis and enhanced modulo detection.
        FIXED: Check polynomial BEFORE piecewise to avoid misclassification.
        ENHANCED: Consider transferred skills from other domains for augmentation.
        """
        if len(inputs) < 2:
            return "nearest_neighbor"
        
        # CROSS-DOMAIN AUGMENTATION: Check if transferred skills suggest a specific approach
        if hasattr(self, '_transferred_skills_cache') and self._transferred_skills_cache:
            # Analyze transferred skills for hints
            skill_hints = self._analyze_transferred_skills_for_hints()
            if skill_hints:
                # Use skill hints to bias strategy selection
                return self._apply_skill_hints(skill_hints, inputs, outputs, func_type)
        
        # Check for modulo pattern - small integer outputs in limited range
        unique_outputs = len(set(outputs))
        output_range = max(outputs) - min(outputs) if outputs else 0
        all_ints = all(isinstance(o, (int, float)) and o == int(o) for o in outputs)
        
        # IMPROVED: More sensitive modulo detection
        # If outputs are small non-negative integers with limited unique values
        if len(outputs) >= 3 and all_ints:
            all_small = all(0 <= o <= 10 for o in outputs)
            if all_small and unique_outputs <= 8 and output_range <= 10:
                return "rule_extraction"  # Likely modulo or threshold
        
        # FIXED: Check piecewise BEFORE polynomial (piecewise functions can have high polynomial R²)
        if len(inputs) >= 4 and self._is_piecewise(inputs, outputs):
            return "piecewise_infer" if self.quality_level > 0.5 else "linear_fit"
        
        # Check polynomial fit (only if not already detected as piecewise)
        if len(inputs) >= 4:
            # Check linearity first
            is_linear = self._is_linear(inputs, outputs, threshold=0.99)
            
            if not is_linear:
                # Try polynomial fit and check R²
                poly_r_squared = self._check_polynomial_fit(inputs, outputs)
                
                # If polynomial fits well, use it
                if poly_r_squared > 0.95:
                    return "polynomial_fit" if self.quality_level > 0.5 else "linear_fit"
        
        # Check for linear relationship
        if self._is_linear(inputs, outputs, threshold=0.95):
            return "linear_fit" if self.quality_level > 0.5 else "linear_fit_bug"
        
        # Check for exponential growth
        if self._is_exponential(inputs, outputs):
            return "exponential_fit" if self.quality_level > 0.6 else "linear_fit"
        
        # Check for logarithmic pattern
        if self._is_logarithmic(inputs, outputs):
            return "logarithmic_fit" if self.quality_level > 0.6 else "linear_fit"
        
        # Default fallback
        if len(inputs) >= 4:
            return "polynomial_fit" if self.quality_level > 0.5 else "wrong_degree"
        
        return "pattern_generalize" if self.quality_level > 0.6 else "partial_fit"
    
    def _extract_skill_from_success(self, solution: Callable, task: Dict[str, Any], episode: int, correctness: float):
        """Extract a universal skill from a successful solution.
        
        Analyzes the solution to determine what pattern/strategy it uses,
        then stores it in unified format for cross-domain transfer.
        """
        func_type = self._extract_function_type(task)
        
        # Map function types to universal skill types
        skill_type_map = {
            "linear": SkillType.TRANSFORMATION_RULE,
            "polynomial": SkillType.PATTERN_RECOGNITION,
            "piecewise": SkillType.DECOMPOSITION,
            "modulo": SkillType.CONSTRAINT_SATISFACTION,
            "exponential": SkillType.PREDICTION,
            "logarithmic": SkillType.PATTERN_RECOGNITION
        }
        
        skill_type = skill_type_map.get(func_type, SkillType.PATTERN_RECOGNITION)
        
        # Determine abstraction level based on complexity
        if func_type in ["linear", "modulo"]:
            abstraction = AbstractionLevel.CONCRETE
        elif func_type in ["polynomial", "exponential", "logarithmic"]:
            abstraction = AbstractionLevel.ABSTRACT
        else:  # piecewise
            abstraction = AbstractionLevel.META
        
        # Generate unique skill ID
        self.skill_counter += 1
        skill_id = f"re_{func_type}_{self.skill_counter}"
        
        # Create universal skill
        skill = UniversalSkill(
            skill_id=skill_id,
            skill_type=skill_type,
            abstraction_level=abstraction,
            name=f"{func_type.title()} Function Inference",
            description=f"Strategy for inferring {func_type} functions from input-output examples",
            embedding=self._compute_skill_embedding(func_type, task),
            applicability_domains=["reverse_engineering", "algorithm", "causal"],
            origin_domain="reverse_engineering",
            origin_task_type=func_type,
            created_episode=episode,
            implementation=solution,
            metadata={
                "function_type": func_type,
                "task_subtype": task.get("subtype", "unknown")
            }
        )
        
        # Add to unified memory
        self.unified_skill_memory.add_skill(skill)
        
        # Record performance
        self.unified_skill_memory.update_skill_performance(
            skill_id, correctness, episode, "reverse_engineering"
        )
    
    def _compute_skill_embedding(self, func_type: str, task: Dict[str, Any]) -> 'np.ndarray':
        """Compute skill embedding (simplified - would use real embeddings in production)."""
        import numpy as np
        # In production, use sentence transformers or similar
        # For now, create a simple hash-based embedding
        seed = hash(f"{func_type}_{task.get('subtype', '')}") % (2**32)
        rng = np.random.RandomState(seed)
        return rng.randn(768)
    
    def _apply_transferred_skills(self, task: Dict[str, Any], episode: int) -> Optional[Callable]:
        """Try to apply transferred skills from other domains.
        
        Returns a callable if a relevant skill is found, None otherwise.
        """
        # Retrieve relevant skills using unified memory
        relevant_skills = self.unified_skill_memory.retrieve_relevant_skills(
            task=task,
            target_domain="reverse_engineering",
            max_skills=3
        )
        
        if not relevant_skills:
            return None
        
        # Use the best skill's implementation
        best_skill = relevant_skills[0]
        
        # Convert to reverse engineering format if needed
        re_format = SkillConverter.convert_to_domain(best_skill, "reverse_engineering")
        
        # Return the skill's implementation if available
        if best_skill.implementation:
            return best_skill.implementation
        
        return None
    
    def _analyze_transferred_skills_for_hints(self) -> Dict[str, Any]:
        """Analyze transferred skills to extract strategy hints.
        
        Returns a dictionary with hints like:
        - 'preferred_strategy': suggested mutation type
        - 'confidence': how confident we are in this hint (0.0-1.0)
        - 'reasoning': explanation of why this hint was generated
        """
        if not hasattr(self, '_transferred_skills_cache') or not self._transferred_skills_cache:
            return {}
        
        # Analyze the top transferred skill
        best_skill = self._transferred_skills_cache[0]
        
        # Map universal skill types to RE strategies
        skill_to_strategy_map = {
            SkillType.PATTERN_RECOGNITION: "polynomial_fit",
            SkillType.TRANSFORMATION_RULE: "linear_fit",
            SkillType.DECOMPOSITION: "piecewise_infer",
            SkillType.CONSTRAINT_SATISFACTION: "rule_extraction",
            SkillType.SEQUENTIAL_REASONING: "pattern_generalize",
            SkillType.PREDICTION: "exponential_fit"
        }
        
        suggested_strategy = skill_to_strategy_map.get(best_skill.skill_type)
        
        if not suggested_strategy:
            return {}
        
        # Calculate confidence based on skill's success rate and transfer probability
        skill_success_rate = best_skill.success_rate
        transfer_prob = self.unified_skill_memory.feedback_loop.get_transfer_probability(
            best_skill.skill_type, "reverse_engineering"
        )
        
        # Combined confidence
        confidence = 0.6 * skill_success_rate + 0.4 * transfer_prob
        
        # Only provide hints with reasonable confidence
        # OPTIMIZED: Lowered from 0.5 to 0.4 based on empirical data (>97% transfer success)
        if confidence < 0.4:
            return {}
        
        return {
            'preferred_strategy': suggested_strategy,
            'confidence': confidence,
            'reasoning': f"Transferred {best_skill.skill_type.value} skill from {best_skill.origin_domain} (success_rate={skill_success_rate:.2f}, transfer_prob={transfer_prob:.2f})"
        }
    
    def _apply_skill_hints(self, hints: Dict[str, Any], inputs: List[float], outputs: List[float], func_type: str) -> str:
        """Apply skill hints to bias strategy selection.
        
        Uses the hint as a strong signal but still validates against data patterns.
        """
        preferred = hints.get('preferred_strategy')
        confidence = hints.get('confidence', 0.0)
        
        if not preferred or confidence < 0.5:
            # Fall back to normal selection if hint is weak
            return self._select_best_strategy_no_hints(inputs, outputs, func_type)
        
        # For high-confidence hints, use the preferred strategy directly
        # But only if it makes sense for the data
        if confidence > 0.7:
            return preferred
        
        # For medium confidence, validate against data patterns
        # If the hint conflicts strongly with data, ignore it
        if preferred == "polynomial_fit":
            poly_r2 = self._check_polynomial_fit(inputs, outputs)
            if poly_r2 > 0.8:  # Hint aligns with data
                return preferred
        elif preferred == "piecewise_infer":
            if self._is_piecewise(inputs, outputs):
                return preferred
        elif preferred == "linear_fit":
            if self._is_linear(inputs, outputs, threshold=0.9):
                return preferred
        
        # If hint doesn't align well, fall back to normal selection
        return self._select_best_strategy_no_hints(inputs, outputs, func_type)
    
    def _select_best_strategy_no_hints(self, inputs: List[float], outputs: List[float], func_type: str) -> str:
        """Original strategy selection logic without skill hints.
        
        This is the baseline logic that runs when no transferred skills are available
        or when hints have low confidence.
        """
        if len(inputs) < 2:
            return "nearest_neighbor"
        
        # Check for modulo pattern - small integer outputs in limited range
        unique_outputs = len(set(outputs))
        output_range = max(outputs) - min(outputs) if outputs else 0
        all_ints = all(isinstance(o, (int, float)) and o == int(o) for o in outputs)
        
        # IMPROVED: More sensitive modulo detection
        if len(outputs) >= 3 and all_ints:
            all_small = all(0 <= o <= 10 for o in outputs)
            if all_small and unique_outputs <= 8 and output_range <= 10:
                return "rule_extraction"
        
        # FIXED: Check piecewise BEFORE polynomial
        if len(inputs) >= 4 and self._is_piecewise(inputs, outputs):
            return "piecewise_infer" if self.quality_level > 0.5 else "linear_fit"
        
        # Check polynomial fit
        if len(inputs) >= 4:
            is_linear = self._is_linear(inputs, outputs, threshold=0.99)
            
            if not is_linear:
                poly_r_squared = self._check_polynomial_fit(inputs, outputs)
                if poly_r_squared > 0.95:
                    return "polynomial_fit" if self.quality_level > 0.5 else "linear_fit"
        
        # Check for linear relationship
        if self._is_linear(inputs, outputs, threshold=0.95):
            return "linear_fit" if self.quality_level > 0.5 else "linear_fit_bug"
        
        # Check for exponential growth
        if self._is_exponential(inputs, outputs):
            return "exponential_fit" if self.quality_level > 0.6 else "linear_fit"
        
        # Check for logarithmic pattern
        if self._is_logarithmic(inputs, outputs):
            return "logarithmic_fit" if self.quality_level > 0.6 else "linear_fit"
        
        # Default fallback
        if len(inputs) >= 4:
            return "polynomial_fit" if self.quality_level > 0.5 else "wrong_degree"
        
        return "pattern_generalize" if self.quality_level > 0.6 else "partial_fit"
    
    def create_variant(self, task: Dict[str, Any], episode: int, external_skills: list = None) -> Callable:
        """
        Create a mutated variant for reverse engineering task with ECM-aligned forgetting.
        
        Automatically triggers cleanup every 50 episodes.
        Integrates cross-domain skill transfer from unified memory.
        """
        # Apply periodic cleanup
        if episode > 0 and episode % 50 == 0:
            self.skill_memory.apply_decay(episode)
            self.skill_memory.consolidate_similar_skills()
            
            # Save checkpoint every 100 episodes
            if episode % 100 == 0:
                try:
                    self.skill_memory.save_checkpoint(episode=episode)
                    self.information_pruner.save_checkpoint(episode=episode)
                except Exception as e:
                    print(f"Warning: Failed to save checkpoint at episode {episode}: {e}")
        
        # CROSS-DOMAIN SKILL TRANSFER: Retrieve relevant skills for augmentation
        # Store for potential use in mutation strategies (not direct replacement)
        self._transferred_skills_cache = []
        if episode > 15:  # OPTIMIZED: Lowered from 20 based on empirical data (skills accumulate quickly)
            transferred_skills = self.unified_skill_memory.retrieve_relevant_skills(
                task=task,
                target_domain="reverse_engineering",
                max_skills=2
            )
            self._transferred_skills_cache = transferred_skills
        
        func_type = self._extract_function_type(task)
        
        # Extract examples from task inputs
        task_inputs = task.get("inputs", {})
        examples = task_inputs.get("examples", [])
        
        # Extract unique inputs and outputs from examples (remove duplicates)
        seen = set()
        unique_examples = []
        for ex in examples:
            key = (ex["input"], ex["output"])
            if key not in seen:
                seen.add(key)
                unique_examples.append(ex)
        
        inputs = [ex["input"] for ex in unique_examples]
        outputs = [ex["output"] for ex in unique_examples]
        
        # Intelligently select mutation strategy based on data patterns
        base_strategy = self._select_best_strategy(inputs, outputs, func_type)
        
        # STAGNATION DETECTION: Override strategy if stagnation detected
        if episode > 20 and self.last_strategy:  # Only after initial learning
            adaptive_strategy = self.strategy_selector.select_strategy(
                episode, self.last_success, self.last_quality, base_strategy
            )
            if adaptive_strategy != base_strategy:
                base_strategy = adaptive_strategy
        
        # Track current strategy for next episode
        self.last_strategy = base_strategy
        
        # ECM Layer 4: Use information-theoretic pruner for operator selection
        # Map function types to operators
        operators_map = {
            "linear": ["linear_fit", "wrong_slope", "off_by_constant", "identity"],
            "polynomial": ["polynomial_fit", "wrong_degree", "missing_term", "constant"],
            "piecewise": ["piecewise_infer", "wrong_boundary", "single_function", "random"],
            "exponential": ["exponential_fit", "linear_approx", "logarithmic", "constant"],
            "logarithmic": ["logarithmic_fit", "exponential_approx", "linear", "constant"],
            "modulo": ["rule_extraction", "pattern_generalize", "nearest_neighbor", "random"]
        }
        
        available_operators = operators_map.get(func_type, [base_strategy, "linear_fit", "polynomial_fit", "nearest_neighbor"])
        
        # Use pruner to select best operator (or keep base strategy if pruner suggests it)
        selected_operator = self.information_pruner.prune_and_select(
            task_type=func_type,
            available_operators=available_operators
        )
        
        # If all operators pruned, use base strategy as fallback
        mutation_type = selected_operator if selected_operator else base_strategy
        
        def variant(**kwargs):
            # Extract test input from kwargs
            x = kwargs.get("test_input", kwargs.get("x", 0))
            
            try:
                if mutation_type == "polynomial_fit":
                    return self._polynomial_fit(inputs, outputs, x)
                
                elif mutation_type == "piecewise_infer":
                    return self._piecewise_infer(inputs, outputs, x)
                
                elif mutation_type == "pattern_generalize":
                    return self._pattern_generalize(inputs, outputs, x)
                
                elif mutation_type == "linear_fit":
                    return self._linear_fit(inputs, outputs, x)
                
                elif mutation_type == "rule_extraction":
                    return self._rule_extraction(inputs, outputs, x)
                
                elif mutation_type == "exponential_fit":
                    return self._exponential_fit(inputs, outputs, x)
                
                elif mutation_type == "logarithmic_fit":
                    return self._logarithmic_fit(inputs, outputs, x)
                
                elif mutation_type == "ratio_analysis":
                    return self._ratio_analysis(inputs, outputs, x)
                
                elif mutation_type == "nearest_neighbor":
                    return self._nearest_neighbor(inputs, outputs, x)
                
                # NOVEL: Algorithm Recognition - Ensemble Meta-Strategy
                elif mutation_type == "algorithm_recognition":
                    return self._algorithm_recognition_ensemble(inputs, outputs, x)
                
                elif mutation_type == "linear_fit_bug":
                    # Subtle bug: off-by-one in slope calculation
                    return self._linear_fit_bug(inputs, outputs, x)
                
                elif mutation_type == "wrong_degree":
                    # Subtle bug: wrong polynomial degree
                    return self._wrong_degree(inputs, outputs, x)
                
                else:  # partial_fit
                    # Subtle bug: only uses subset of examples
                    return self._partial_fit(inputs, outputs, x)
                    
            except Exception as e:
                # Fallback: return closest known output
                if outputs:
                    return outputs[-1]
                return 0
        
        return variant
    
    def _linear_fit(self, inputs: List[float], outputs: List[float], x: float) -> float:
        """Fit a linear function y = mx + b.
        
        ENHANCED: Added robust fitting for noisy data using RANSAC-like approach.
        """
        if len(inputs) < 2:
            return outputs[0] if outputs else 0
        
        # NOVEL: Detect and handle noisy data
        if self._is_noisy_data(inputs, outputs):
            return self._robust_linear_fit(inputs, outputs, x)
        
        # Calculate slope using first two points
        m = (outputs[1] - outputs[0]) / (inputs[1] - inputs[0]) if inputs[1] != inputs[0] else 0
        b = outputs[0] - m * inputs[0]
        
        return m * x + b
    
    def _is_noisy_data(self, inputs: List[float], outputs: List[float]) -> bool:
        """Detect if data has significant noise/outliers."""
        if len(inputs) < 3:
            return False
        
        # Check residuals from simple linear fit
        m = (outputs[1] - outputs[0]) / (inputs[1] - inputs[0]) if inputs[1] != inputs[0] else 0
        b = outputs[0] - m * inputs[0]
        residuals = [abs(out - (m * inp + b)) for inp, out in zip(inputs, outputs)]
        
        # If average residual is large relative to output range, it's noisy
        output_range = max(outputs) - min(outputs) if outputs else 1
        avg_residual = sum(residuals) / len(residuals)
        
        return avg_residual > 0.1 * abs(output_range) if output_range != 0 else avg_residual > 0.1
    
    def _robust_linear_fit(self, inputs: List[float], outputs: List[float], x: float) -> float:
        """Robust linear fit using iterative outlier removal (RANSAC-like).
        
        Removes outliers and refits to handle noisy data gracefully.
        """
        if len(inputs) < 2:
            return outputs[0] if outputs else 0
        
        current_inputs = list(inputs)
        current_outputs = list(outputs)
        
        # Iterative refinement: remove worst outliers
        for iteration in range(3):  # Max 3 iterations
            if len(current_inputs) < 2:
                break
            
            # Fit line to current data
            m = (current_outputs[1] - current_outputs[0]) / (current_inputs[1] - current_inputs[0]) if current_inputs[1] != current_inputs[0] else 0
            b = current_outputs[0] - m * current_inputs[0]
            
            # Calculate residuals
            residuals = [(inp, out, abs(out - (m * inp + b))) 
                        for inp, out in zip(current_inputs, current_outputs)]
            
            # Remove worst outlier (highest residual)
            residuals.sort(key=lambda r: r[2], reverse=True)
            
            # Keep only good points (remove top 10% worst)
            num_to_remove = max(1, len(residuals) // 10)
            filtered = residuals[num_to_remove:]
            
            if len(filtered) >= 2:
                current_inputs = [r[0] for r in filtered]
                current_outputs = [r[1] for r in filtered]
        
        # Final fit on cleaned data
        m = (current_outputs[1] - current_outputs[0]) / (current_inputs[1] - current_inputs[0]) if current_inputs[1] != current_inputs[0] else 0
        b = current_outputs[0] - m * current_inputs[0]
        
        return m * x + b
    
    def _linear_fit_bug(self, inputs: List[float], outputs: List[float], x: float) -> float:
        """Linear fit with subtle off-by-one error."""
        if len(inputs) < 2:
            return outputs[0] if outputs else 0
        
        # Bug: use last two points instead of first two (may be wrong for non-linear)
        m = (outputs[-1] - outputs[-2]) / (inputs[-1] - inputs[-2]) if inputs[-1] != inputs[-2] else 0
        b = outputs[-2] - m * inputs[-2]
        
        return m * x + b  # Feasible but potentially suboptimal
    
    def _check_polynomial_fit(self, inputs: List[float], outputs: List[float]) -> float:
        """Check how well a polynomial fits the data. Returns R² value.
        
        IMPROVED: Tests multiple degrees and returns best R².
        """
        if len(inputs) < 3:
            return 0.0
        
        best_r_squared = 0.0
        max_degree = min(len(inputs) - 1, 4)  # Cap at degree 4 for stability
        
        for degree in range(2, max_degree + 1):
            coeffs = self._fit_polynomial(inputs, outputs, degree)
            if coeffs is not None:
                # Calculate R²
                predictions = [self._eval_poly(coeffs, x) for x in inputs]
                mean_y = sum(outputs) / len(outputs)
                ss_tot = sum((y - mean_y) ** 2 for y in outputs)
                ss_res = sum((y - pred) ** 2 for y, pred in zip(outputs, predictions))
                
                if ss_tot > 0:
                    r_squared = 1 - (ss_res / ss_tot)
                    best_r_squared = max(best_r_squared, r_squared)
        
        return best_r_squared
    
    def _polynomial_fit(self, inputs: List[float], outputs: List[float], x: float) -> float:
        """Proper polynomial fitting using least squares.
        
        IMPROVED: Use Lagrange interpolation for small datasets (< 6 points)
        to avoid overfitting and oscillation issues.
        For larger datasets, use degree-limited least squares.
        """
        if len(inputs) < 2:
            return outputs[0] if outputs else 0
        
        # FIXED: For small datasets (<= 5 points), use exact interpolation
        # This avoids the oscillation problem with least squares on few points
        if len(inputs) <= 5:
            return self._lagrange_interpolation(inputs, outputs, x)
        
        # For larger datasets, use degree-limited least squares
        max_degree = min(len(inputs) - 1, 4)  # Cap at degree 4 to prevent overfitting
        
        # Try increasing degrees and pick best fit by cross-validation
        best_error = float('inf')
        best_coeffs = None
        best_degree = 1
        
        for degree in range(1, max_degree + 1):
            coeffs = self._fit_polynomial(inputs, outputs, degree)
            if coeffs is not None:
                # Calculate leave-one-out error for better generalization
                loo_error = self._loo_error(inputs, outputs, coeffs, degree)
                if loo_error < best_error:
                    best_error = loo_error
                    best_coeffs = coeffs
                    best_degree = degree
        
        if best_coeffs is not None:
            return self._eval_poly(best_coeffs, x)
        else:
            # Fallback to linear fit
            return self._linear_fit(inputs, outputs, x)
    
    def _fit_polynomial(self, xs: List[float], ys: List[float], degree: int) -> List[float]:
        """Fit polynomial coefficients using normal equations."""
        n = len(xs)
        if n <= degree:
            return None
        
        # Build Vandermonde matrix
        import numpy as np
        try:
            X = np.vander(xs, degree + 1)
            y = np.array(ys)
            
            # Solve normal equations: (X^T X) coeffs = X^T y
            coeffs = np.linalg.lstsq(X, y, rcond=None)[0]
            return coeffs.tolist()
        except Exception:
            return None
    
    def _eval_poly(self, coeffs: List[float], x: float) -> float:
        """Evaluate polynomial with given coefficients at x.
        Coefficients are in descending order (highest degree first)."""
        # Use Horner's method - coefficients should be in descending order
        result = 0.0
        for coeff in coeffs:  # Don't reverse - numpy vander gives descending order
            result = result * x + coeff
        return result
    
    def _lagrange_interpolation(self, xs: List[float], ys: List[float], x: float) -> float:
        """Lagrange polynomial interpolation for exact fit on small datasets.
        
        This avoids the oscillation problem of least squares on few points.
        Returns the interpolated value at x.
        """
        n = len(xs)
        if n == 0:
            return 0
        if n == 1:
            return ys[0]
        
        result = 0.0
        for i in range(n):
            # Calculate Lagrange basis polynomial L_i(x)
            term = ys[i]
            for j in range(n):
                if i != j:
                    # Avoid division by zero
                    if abs(xs[i] - xs[j]) < 1e-10:
                        term = 0
                        break
                    term *= (x - xs[j]) / (xs[i] - xs[j])
            result += term
        
        return result
    
    def _loo_error(self, xs: List[float], ys: List[float], coeffs: List[float], degree: int) -> float:
        """Calculate leave-one-out cross-validation error.
        
        For each data point, fit polynomial without that point and measure error.
        This helps prevent overfitting.
        """
        n = len(xs)
        if n <= degree + 1:
            return float('inf')  # Not enough points
        
        total_error = 0.0
        for i in range(n):
            # Leave out point i
            xs_train = xs[:i] + xs[i+1:]
            ys_train = ys[:i] + ys[i+1:]
            
            # Fit on remaining points
            train_coeffs = self._fit_polynomial(xs_train, ys_train, degree)
            if train_coeffs is None:
                continue
            
            # Predict left-out point
            pred = self._eval_poly(train_coeffs, xs[i])
            total_error += (pred - ys[i]) ** 2
        
        return total_error / n
    

    

    
    def _piecewise_infer(self, inputs: List[float], outputs: List[float], x: float) -> float:
        """Infer piecewise function from examples.
        
        PHASE 2 IMPROVEMENT: Enhanced with binary segmentation for better
        breakpoint detection and multi-segment support.
        """
        if len(inputs) < 3:
            return self._linear_fit(inputs, outputs, x)
        
        # Sort data points
        sorted_pairs = sorted(zip(inputs, outputs))
        
        # Special case: exactly 3 points - middle point is likely the breakpoint
        if len(sorted_pairs) == 3:
            x0, y0 = sorted_pairs[0]
            x1, y1 = sorted_pairs[1]
            x2, y2 = sorted_pairs[2]
            
            # Use left segment for x <= x1, right segment for x > x1
            if x <= x1:
                # Linear interpolation/extrapolation from left segment
                if x1 != x0:
                    slope_left = (y1 - y0) / (x1 - x0)
                    return y0 + slope_left * (x - x0)
                else:
                    return y0
            else:
                # Linear interpolation/extrapolation from right segment
                if x2 != x1:
                    slope_right = (y2 - y1) / (x2 - x1)
                    return y1 + slope_right * (x - x1)
                else:
                    return y1
        
        # PHASE 2 IMPROVEMENT: Try binary segmentation for better breakpoint detection
        # FIXED: Use min_segment_size=2 to allow more split points
        breakpoints = self._binary_segmentation(sorted_pairs, min_segment_size=2)
        
        if breakpoints:
            # Use detected breakpoints for multi-segment prediction
            return self._predict_with_breakpoints(sorted_pairs, breakpoints, x)
        
        # Fallback: Original brute-force breakpoint search
        return self._piecewise_brute_force(sorted_pairs, x)
        
        # For 4+ points, find best breakpoint by trying all possible splits
        best_breakpoint_idx = None
        best_r_squared_total = -float('inf')
        
        # Try each possible breakpoint position
        for i in range(2, len(sorted_pairs) - 1):
            left_inputs = [p[0] for p in sorted_pairs[:i]]
            left_outputs = [p[1] for p in sorted_pairs[:i]]
            right_inputs = [p[0] for p in sorted_pairs[i:]]
            right_outputs = [p[1] for p in sorted_pairs[i:]]
            
            if len(left_inputs) >= 2 and len(right_inputs) >= 2:
                # Fit lines to both segments
                m1, b1 = self._fit_line(left_inputs, left_outputs)
                m2, b2 = self._fit_line(right_inputs, right_outputs)
                
                # Calculate R² for left segment
                mean_y_left = sum(left_outputs) / len(left_outputs)
                ss_tot_left = sum((y - mean_y_left) ** 2 for y in left_outputs)
                ss_res_left = sum((y - (m1 * x + b1)) ** 2 for x, y in zip(left_inputs, left_outputs))
                r_squared_left = 1 - (ss_res_left / ss_tot_left) if ss_tot_left > 0 else 1.0
                
                # Calculate R² for right segment
                mean_y_right = sum(right_outputs) / len(right_outputs)
                ss_tot_right = sum((y - mean_y_right) ** 2 for y in right_outputs)
                ss_res_right = sum((y - (m2 * x + b2)) ** 2 for x, y in zip(right_inputs, right_outputs))
                r_squared_right = 1 - (ss_res_right / ss_tot_right) if ss_tot_right > 0 else 1.0
                
                # Combined R² (weighted by number of points)
                n_left = len(left_inputs)
                n_right = len(right_inputs)
                r_squared_total = (n_left * r_squared_left + n_right * r_squared_right) / (n_left + n_right)
                
                if r_squared_total > best_r_squared_total:
                    best_r_squared_total = r_squared_total
                    best_breakpoint_idx = i
        
        # Use the best breakpoint if it gives good fit
        if best_breakpoint_idx is not None and best_r_squared_total > 0.7:
            left_inputs = [p[0] for p in sorted_pairs[:best_breakpoint_idx]]
            left_outputs = [p[1] for p in sorted_pairs[:best_breakpoint_idx]]
            right_inputs = [p[0] for p in sorted_pairs[best_breakpoint_idx:]]
            right_outputs = [p[1] for p in sorted_pairs[best_breakpoint_idx:]]
            
            breakpoint_x = sorted_pairs[best_breakpoint_idx][0]
            
            if x <= breakpoint_x:
                return self._linear_fit(left_inputs, left_outputs, x)
            else:
                return self._linear_fit(right_inputs, right_outputs, x)
        
        # No clear breakpoint, try ensemble approach: combine piecewise and polynomial
        # This handles cases where breakpoint detection is uncertain
        poly_result = self._polynomial_fit(inputs, outputs, x)
        
        # If we have a potential breakpoint but low confidence, blend predictions
        if best_breakpoint_idx is not None:
            left_inputs = [p[0] for p in sorted_pairs[:best_breakpoint_idx]]
            left_outputs = [p[1] for p in sorted_pairs[:best_breakpoint_idx]]
            right_inputs = [p[0] for p in sorted_pairs[best_breakpoint_idx:]]
            right_outputs = [p[1] for p in sorted_pairs[best_breakpoint_idx:]]
            
            breakpoint_x = sorted_pairs[best_breakpoint_idx][0]
            
            # Get predictions from both segments
            if x <= breakpoint_x:
                piecewise_result = self._linear_fit(left_inputs, left_outputs, x)
            else:
                piecewise_result = self._linear_fit(right_inputs, right_outputs, x)
            
            # Blend based on distance from breakpoint (closer to breakpoint = trust piecewise more)
            distance_from_bp = abs(x - breakpoint_x)
            input_range = max(inputs) - min(inputs) if inputs else 1
            
            if input_range > 0:
                # Weight: closer to breakpoint = higher weight for piecewise
                piecewise_weight = max(0.3, 1.0 - distance_from_bp / input_range)
                poly_weight = 1.0 - piecewise_weight
                return piecewise_weight * piecewise_result + poly_weight * poly_result
            else:
                return piecewise_result
        
        # Fallback to polynomial if no breakpoint found
        return poly_result
    
    def _piecewise_brute_force(self, sorted_pairs: list, x: float) -> float:
        """Brute-force breakpoint search for piecewise functions.
        
        IMPROVED: Better handling of extrapolation and multi-segment detection.
        """
        if len(sorted_pairs) < 4:
            return self._linear_fit([p[0] for p in sorted_pairs], [p[1] for p in sorted_pairs], x)
        
        # Find best breakpoint by trying all possible splits
        best_breakpoint_idx = None
        best_r_squared_total = -float('inf')
        
        # Try each possible breakpoint position
        for i in range(2, len(sorted_pairs) - 1):
            left_inputs = [p[0] for p in sorted_pairs[:i]]
            left_outputs = [p[1] for p in sorted_pairs[:i]]
            right_inputs = [p[0] for p in sorted_pairs[i:]]
            right_outputs = [p[1] for p in sorted_pairs[i:]]
            
            if len(left_inputs) >= 2 and len(right_inputs) >= 2:
                # Fit lines to both segments
                m1, b1 = self._fit_line(left_inputs, left_outputs)
                m2, b2 = self._fit_line(right_inputs, right_outputs)
                
                # Calculate R² for left segment
                mean_y_left = sum(left_outputs) / len(left_outputs)
                ss_tot_left = sum((y - mean_y_left) ** 2 for y in left_outputs)
                ss_res_left = sum((y - (m1 * x + b1)) ** 2 for x, y in zip(left_inputs, left_outputs))
                r_squared_left = 1 - (ss_res_left / ss_tot_left) if ss_tot_left > 0 else 1.0
                
                # Calculate R² for right segment
                mean_y_right = sum(right_outputs) / len(right_outputs)
                ss_tot_right = sum((y - mean_y_right) ** 2 for y in right_outputs)
                ss_res_right = sum((y - (m2 * x + b2)) ** 2 for x, y in zip(right_inputs, right_outputs))
                r_squared_right = 1 - (ss_res_right / ss_tot_right) if ss_tot_right > 0 else 1.0
                
                # Combined R² (weighted by number of points)
                n_left = len(left_inputs)
                n_right = len(right_inputs)
                r_squared_total = (n_left * r_squared_left + n_right * r_squared_right) / (n_left + n_right)
                
                if r_squared_total > best_r_squared_total:
                    best_r_squared_total = r_squared_total
                    best_breakpoint_idx = i
        
        # Use the best breakpoint if it gives good fit
        if best_breakpoint_idx is not None and best_r_squared_total > 0.7:
            left_inputs = [p[0] for p in sorted_pairs[:best_breakpoint_idx]]
            left_outputs = [p[1] for p in sorted_pairs[:best_breakpoint_idx]]
            right_inputs = [p[0] for p in sorted_pairs[best_breakpoint_idx:]]
            right_outputs = [p[1] for p in sorted_pairs[best_breakpoint_idx:]]
            
            breakpoint_x = sorted_pairs[best_breakpoint_idx][0]
            
            # FIXED: Handle extrapolation better
            if x <= breakpoint_x:
                result = self._linear_fit(left_inputs, left_outputs, x)
            else:
                result = self._linear_fit(right_inputs, right_outputs, x)
            
            return result
        
        # No clear breakpoint found - fallback to linear interpolation
        return self._linear_fit([p[0] for p in sorted_pairs], [p[1] for p in sorted_pairs], x)
        """Original brute-force breakpoint search (fallback method)."""
        # For 4+ points, find best breakpoint by trying all possible splits
        best_breakpoint_idx = None
        best_r_squared_total = -float('inf')
        
        # Try each possible breakpoint position
        for i in range(2, len(sorted_pairs) - 1):
            left_inputs = [p[0] for p in sorted_pairs[:i]]
            left_outputs = [p[1] for p in sorted_pairs[:i]]
            right_inputs = [p[0] for p in sorted_pairs[i:]]
            right_outputs = [p[1] for p in sorted_pairs[i:]]
            
            if len(left_inputs) >= 2 and len(right_inputs) >= 2:
                # Fit lines to both segments
                m1, b1 = self._fit_line(left_inputs, left_outputs)
                m2, b2 = self._fit_line(right_inputs, right_outputs)
                
                # Calculate R² for left segment
                mean_y_left = sum(left_outputs) / len(left_outputs)
                ss_tot_left = sum((y - mean_y_left) ** 2 for y in left_outputs)
                ss_res_left = sum((y - (m1 * x + b1)) ** 2 for x, y in zip(left_inputs, left_outputs))
                r_squared_left = 1 - (ss_res_left / ss_tot_left) if ss_tot_left > 0 else 1.0
                
                # Calculate R² for right segment
                mean_y_right = sum(right_outputs) / len(right_outputs)
                ss_tot_right = sum((y - mean_y_right) ** 2 for y in right_outputs)
                ss_res_right = sum((y - (m2 * x + b2)) ** 2 for x, y in zip(right_inputs, right_outputs))
                r_squared_right = 1 - (ss_res_right / ss_tot_right) if ss_tot_right > 0 else 1.0
                
                # Combined R² (weighted by number of points)
                n_left = len(left_inputs)
                n_right = len(right_inputs)
                r_squared_total = (n_left * r_squared_left + n_right * r_squared_right) / (n_left + n_right)
                
                if r_squared_total > best_r_squared_total:
                    best_r_squared_total = r_squared_total
                    best_breakpoint_idx = i
        
        # Use the best breakpoint if it gives good fit
        inputs = [p[0] for p in sorted_pairs]
        outputs = [p[1] for p in sorted_pairs]
        
        if best_breakpoint_idx is not None and best_r_squared_total > 0.7:
            # Get predictions from both segments
            left_inputs = [p[0] for p in sorted_pairs[:best_breakpoint_idx]]
            left_outputs = [p[1] for p in sorted_pairs[:best_breakpoint_idx]]
            right_inputs = [p[0] for p in sorted_pairs[best_breakpoint_idx:]]
            right_outputs = [p[1] for p in sorted_pairs[best_breakpoint_idx:]]
            
            breakpoint_x = sorted_pairs[best_breakpoint_idx][0]
            
            if x <= breakpoint_x:
                piecewise_result = self._linear_fit(left_inputs, left_outputs, x)
            else:
                piecewise_result = self._linear_fit(right_inputs, right_outputs, x)
            
            # Blend with polynomial prediction
            poly_result = self._polynomial_fit(inputs, outputs, x)
            
            distance_from_bp = abs(x - breakpoint_x)
            input_range = max(inputs) - min(inputs) if inputs else 1
            
            if input_range > 0:
                piecewise_weight = max(0.3, 1.0 - distance_from_bp / input_range)
                poly_weight = 1.0 - piecewise_weight
                return piecewise_weight * piecewise_result + poly_weight * poly_result
            else:
                return piecewise_result
        
        # Fallback to polynomial if no breakpoint found
        return self._polynomial_fit(inputs, outputs, x)
    
    def _binary_segmentation(self, sorted_pairs: list, min_segment_size: int = 2) -> list:
        """PHASE 2: Binary segmentation for change-point detection.
        
        Recursively finds breakpoints where the linear relationship changes significantly.
        
        Args:
            sorted_pairs: List of (x, y) tuples sorted by x
            min_segment_size: Minimum number of points per segment
            
        Returns:
            List of breakpoint indices
        """
        if len(sorted_pairs) < 2 * min_segment_size:
            return []
        
        # Find best split point by minimizing total RSS
        best_cost = float('inf')
        best_split = None
        
        # Calculate baseline cost (single line fit)
        xs = [p[0] for p in sorted_pairs]
        ys = [p[1] for p in sorted_pairs]
        m_base, b_base = self._fit_line(xs, ys)
        baseline_rss = sum((y - (m_base * x + b_base))**2 for x, y in zip(xs, ys))
        
        # Try all possible split points
        for split in range(min_segment_size, len(sorted_pairs) - min_segment_size):
            left = sorted_pairs[:split]
            right = sorted_pairs[split:]
            
            # Calculate RSS for each segment
            left_xs = [p[0] for p in left]
            left_ys = [p[1] for p in left]
            m1, b1 = self._fit_line(left_xs, left_ys)
            rss_left = sum((y - (m1 * x + b1))**2 for x, y in zip(left_xs, left_ys))
            
            right_xs = [p[0] for p in right]
            right_ys = [p[1] for p in right]
            m2, b2 = self._fit_line(right_xs, right_ys)
            rss_right = sum((y - (m2 * x + b2))**2 for x, y in zip(right_xs, right_ys))
            
            total_cost = rss_left + rss_right
            
            if total_cost < best_cost:
                best_cost = total_cost
                best_split = split
        
        # Check if split provides significant improvement
        # Use penalty term to avoid over-segmentation
        penalty = 2 * len(sorted_pairs)  # Simple BIC-like penalty
        
        if best_split is not None and best_cost < baseline_rss - penalty:
            # Recurse on both segments
            left_breakpoints = self._binary_segmentation(sorted_pairs[:best_split], min_segment_size)
            right_breakpoints = self._binary_segmentation(sorted_pairs[best_split:], min_segment_size)
            
            # Adjust right breakpoints to account for offset
            right_breakpoints = [bp + best_split for bp in right_breakpoints]
            
            return left_breakpoints + [best_split] + right_breakpoints
        
        return []
    
    def _predict_with_breakpoints(self, sorted_pairs: list, breakpoints: list, x: float) -> float:
        """PHASE 2: Predict using detected breakpoints for multi-segment piecewise function.
        
        Args:
            sorted_pairs: List of (x, y) tuples sorted by x
            breakpoints: List of breakpoint indices
            x: Input value to predict
            
        Returns:
            Predicted output value
        """
        if not breakpoints:
            # No breakpoints - use single linear fit
            xs = [p[0] for p in sorted_pairs]
            ys = [p[1] for p in sorted_pairs]
            return self._linear_fit(xs, ys, x)
        
        # Add start and end boundaries
        all_boundaries = [0] + breakpoints + [len(sorted_pairs)]
        
        # Find which segment x falls into
        x_val = x
        for i in range(len(all_boundaries) - 1):
            seg_start = all_boundaries[i]
            seg_end = all_boundaries[i + 1]
            
            segment = sorted_pairs[seg_start:seg_end]
            seg_xs = [p[0] for p in segment]
            
            # Check if x is in this segment
            if seg_start == 0:
                # First segment: x <= first point of next segment
                if seg_end < len(sorted_pairs):
                    next_x = sorted_pairs[seg_end][0]
                    if x_val <= next_x:
                        return self._linear_fit(seg_xs, [p[1] for p in segment], x_val)
                else:
                    # Last segment
                    return self._linear_fit(seg_xs, [p[1] for p in segment], x_val)
            elif seg_end == len(sorted_pairs):
                # Last segment: x >= last point of previous segment
                prev_x = sorted_pairs[seg_start - 1][0]
                if x_val >= prev_x:
                    return self._linear_fit(seg_xs, [p[1] for p in segment], x_val)
            else:
                # Middle segment
                prev_x = sorted_pairs[seg_start - 1][0]
                next_x = sorted_pairs[seg_end][0]
                if prev_x <= x_val <= next_x:
                    return self._linear_fit(seg_xs, [p[1] for p in segment], x_val)
        
        # Fallback: extrapolate from nearest segment
        # Find closest segment
        min_dist = float('inf')
        best_seg = None
        
        for i in range(len(all_boundaries) - 1):
            seg_start = all_boundaries[i]
            seg_end = all_boundaries[i + 1]
            segment = sorted_pairs[seg_start:seg_end]
            seg_xs = [p[0] for p in segment]
            
            # Distance to segment
            if x_val < min(seg_xs):
                dist = min(seg_xs) - x_val
            elif x_val > max(seg_xs):
                dist = x_val - max(seg_xs)
            else:
                dist = 0
            
            if dist < min_dist:
                min_dist = dist
                best_seg = segment
        
        if best_seg:
            return self._linear_fit([p[0] for p in best_seg], [p[1] for p in best_seg], x_val)
        
        # Ultimate fallback
        xs = [p[0] for p in sorted_pairs]
        ys = [p[1] for p in sorted_pairs]
        return self._linear_fit(xs, ys, x_val)
    
    def _pattern_generalize(self, inputs: List[float], outputs: List[float], x: float) -> float:
        """Generalize pattern from examples (e.g., arithmetic sequences)."""
        if len(inputs) < 2:
            return outputs[0] if outputs else 0
        
        # Check for arithmetic sequence in outputs
        if len(outputs) >= 3:
            diffs = [outputs[i+1] - outputs[i] for i in range(len(outputs)-1)]
            # If differences are constant, it's arithmetic
            if all(abs(d - diffs[0]) < 1e-6 for d in diffs):
                # Extend the pattern
                step = diffs[0]
                # Find position of x in input sequence
                if len(inputs) >= 2:
                    input_step = inputs[1] - inputs[0]
                    if input_step != 0:
                        position = (x - inputs[0]) / input_step
                        return outputs[0] + position * step
        
        # Fall back to linear fit
        return self._linear_fit(inputs, outputs, x)
    
    def _rule_extraction(self, inputs: List[float], outputs: List[float], x: float) -> float:
        """Extract simple rules from examples (if-then patterns, modulo, etc.)."""
        if len(inputs) < 2:
            return outputs[0] if outputs else 0
        
        # PHASE 1 IMPROVEMENT 1: Extended modulo search range (2-7 → 2-15)
        # Check for modulo pattern: outputs are small integers, repeating
        unique_outputs = sorted(set(outputs))
        if len(unique_outputs) <= 15 and all(isinstance(o, (int, float)) and o == int(o) for o in unique_outputs):
            max_output = max(unique_outputs)
            min_output = min(unique_outputs)
            
            # If outputs are in range [0, n-1] for small n, likely modulo
            if min_output >= 0 and max_output <= 14 and len(unique_outputs) >= 2:
                # Try different moduli - extended range up to 15
                for n in range(2, 16):
                    if all(abs(out - (inp % n)) < 1e-6 for inp, out in zip(inputs, outputs)):
                        # Found matching modulus!
                        return x % n
        
        # PHASE 1 IMPROVEMENT 2: Affine modulo detection f(x) = (a*x + b) % n
        # Check for affine modulo patterns
        if len(inputs) >= 3 and all(isinstance(o, (int, float)) and o == int(o) for o in outputs):
            unique_outputs = sorted(set(outputs))
            max_output = max(unique_outputs)
            
            # Try small moduli with affine transformation
            for n in range(2, 11):  # Modulus 2-10
                if max_output < n:  # Outputs must be in valid range
                    # Try different values of a and b
                    for a in range(1, 6):  # Coefficient a: 1-5
                        for b in range(0, n):  # Offset b: 0 to n-1
                            predicted = [(a * inp + b) % n for inp in inputs]
                            if all(abs(pred - out) < 1e-6 for pred, out in zip(predicted, outputs)):
                                # Found affine modulo pattern!
                                return (a * x + b) % n
        
        # Look for threshold-based rules
        sorted_pairs = sorted(zip(inputs, outputs))
        
        # Check if there's a clear threshold
        for i in range(1, len(sorted_pairs)):
            if abs(sorted_pairs[i][1] - sorted_pairs[i-1][1]) > 1.0:
                # Found a jump - might be a threshold rule
                threshold = (sorted_pairs[i][0] + sorted_pairs[i-1][0]) / 2
                if x < threshold:
                    return sorted_pairs[i-1][1]
                else:
                    return sorted_pairs[i][1]
        
        # No clear threshold, use linear fit
        return self._linear_fit(inputs, outputs, x)
    
    def _algorithm_recognition_ensemble(self, inputs: List[float], outputs: List[float], x: float) -> float:
        """NOVEL: Ensemble meta-strategy for algorithm recognition.
        
        Uses multiple approaches in parallel and votes on the best result:
        1. Lookup table with interpolation for exact matches
        2. Pattern matching for common algorithms (sort, search, fibonacci, etc.)
        3. Nearest neighbor for unknown patterns
        4. Statistical similarity scoring
        
        This handles both scalar and complex input structures.
        """
        if not inputs or not outputs:
            return 0
        
        # NOVEL APPROACH 1: Direct lookup with intelligent interpolation
        # For algorithmic patterns, exact examples are more reliable than fitted functions
        
        # Check if x exactly matches any training input
        for inp, out in zip(inputs, outputs):
            if isinstance(inp, (list, tuple)) and isinstance(x, (list, tuple)):
                # Compare sequences
                if list(inp) == list(x):
                    return out
            elif inp == x:
                return out
        
        # NOVEL APPROACH 2: Pattern-based algorithm detection
        # Detect common algorithmic patterns from behavior
        
        # Check for sorting behavior: output is sorted version of input
        if isinstance(x, (list, tuple)) and len(x) > 1:
            # Try to detect if this is a sorting algorithm
            sorted_x = sorted(x)
            # Check if any training example shows sorting
            for inp, out in zip(inputs, outputs):
                if isinstance(inp, (list, tuple)) and isinstance(out, (list, tuple)):
                    if list(out) == sorted(list(inp)):
                        # This is a sorting algorithm!
                        return sorted_x
            
            # Check for searching behavior: returns index
            if isinstance(x, tuple) and len(x) == 2:
                # Binary search pattern: (sorted_list, target) -> index
                search_list, target = x
                if isinstance(search_list, (list, tuple)):
                    try:
                        idx = list(search_list).index(target)
                        return idx
                    except ValueError:
                        return -1  # Not found
            
            # Check for fibonacci-like sequence generation
            if isinstance(x, (int, float)):
                # Look for fibonacci pattern in outputs
                fib_pattern = False
                for inp, out in zip(inputs, outputs):
                    if isinstance(out, (list, tuple)) and len(out) >= 3:
                        # Check if it's fibonacci
                        is_fib = True
                        for i in range(2, len(out)):
                            if abs(out[i] - (out[i-1] + out[i-2])) > 1e-6:
                                is_fib = False
                                break
                        if is_fib:
                            fib_pattern = True
                            # Generate fibonacci up to position x
                            fib = [0, 1]
                            for i in range(2, int(x) + 1):
                                fib.append(fib[-1] + fib[-2])
                            return fib[int(x)] if int(x) < len(fib) else fib[-1]
                
                # Check for factorial pattern
                if not fib_pattern:
                    import math
                    for inp, out in zip(inputs, outputs):
                        if isinstance(inp, (int, float)) and isinstance(out, (int, float)):
                            if abs(out - math.factorial(int(inp))) < 1e-6:
                                # Factorial detected
                                return math.factorial(int(x))
                    
                    # Check for power/exponential pattern
                    for inp, out in zip(inputs, outputs):
                        if isinstance(inp, (list, tuple)) and len(inp) == 2:
                            base, exp_val = inp
                            if isinstance(out, (int, float)) and abs(out - base**exp_val) < 1e-6:
                                # Power function detected
                                if isinstance(x, (list, tuple)) and len(x) == 2:
                                    return x[0]**x[1]
        
        # NOVEL APPROACH 3: Statistical similarity voting
        # If no clear pattern, use weighted voting from multiple strategies
        candidates = []
        
        # Strategy A: Nearest neighbor
        nn_result = self._nearest_neighbor(inputs, outputs, x)
        candidates.append((nn_result, 0.4))  # 40% weight
        
        # Strategy B: Linear interpolation (if applicable)
        if all(isinstance(i, (int, float)) for i in inputs):
            linear_result = self._linear_fit(inputs, outputs, x)
            candidates.append((linear_result, 0.3))  # 30% weight
        
        # Strategy C: Pattern generalization
        pattern_result = self._pattern_generalize(inputs, outputs, x)
        candidates.append((pattern_result, 0.3))  # 30% weight
        
        # Weighted average of candidates
        if candidates:
            total_weight = sum(w for _, w in candidates)
            weighted_sum = sum(r * w for r, w in candidates)
            return weighted_sum / total_weight if total_weight > 0 else candidates[0][0]
        
        # Fallback: nearest neighbor
        return nn_result
    

    
    def _exponential_fit(self, inputs: List[float], outputs: List[float], x: float) -> float:
        """Fit exponential function y = a * e^(bx)."""
        if len(inputs) < 2:
            return outputs[0] if outputs else 0
        
        # Check if outputs are all positive (required for log transform)
        if any(y <= 0 for y in outputs):
            return self._linear_fit(inputs, outputs, x)
        
        # Transform to linear: ln(y) = ln(a) + bx
        import math
        try:
            log_outputs = [math.log(y) for y in outputs]
            # Fit linear to transformed data
            m, b = self._fit_line(inputs, log_outputs)
            # Convert back: y = e^b * e^(mx)
            a = math.exp(b)
            return a * math.exp(m * x)
        except (ValueError, OverflowError):
            return self._linear_fit(inputs, outputs, x)
    
    def _logarithmic_fit(self, inputs: List[float], outputs: List[float], x: float) -> float:
        """Fit logarithmic function y = a + b * ln(x)."""
        if len(inputs) < 2:
            return outputs[0] if outputs else 0
        
        # Check if inputs are all positive
        if any(xi <= 0 for xi in inputs):
            return self._linear_fit(inputs, outputs, x)
        
        import math
        try:
            log_inputs = [math.log(xi) for xi in inputs]
            # Fit linear to transformed data
            m, b = self._fit_line(log_inputs, outputs)
            # y = b + m * ln(x)
            return b + m * math.log(x) if x > 0 else 0
        except (ValueError, OverflowError):
            return self._linear_fit(inputs, outputs, x)
    
    def _ratio_analysis(self, inputs: List[float], outputs: List[float], x: float) -> float:
        """Analyze output/input ratios to detect patterns."""
        if len(inputs) < 2:
            return outputs[0] if outputs else 0
        
        # Calculate ratios
        ratios = []
        for i, o in zip(inputs, outputs):
            if i != 0:
                ratios.append(o / i)
        
        if not ratios:
            return self._linear_fit(inputs, outputs, x)
        
        # Check if ratios are constant (proportional relationship)
        avg_ratio = sum(ratios) / len(ratios)
        if all(abs(r - avg_ratio) < 0.1 * abs(avg_ratio) for r in ratios):
            return avg_ratio * x
        
        # Otherwise use linear fit
        return self._linear_fit(inputs, outputs, x)
    
    def _nearest_neighbor(self, inputs: List[float], outputs: List[float], x: float) -> float:
        """Use nearest neighbor interpolation (simple but effective)."""
        if not inputs:
            return 0
        
        # Find closest input
        min_dist = float('inf')
        closest_output = outputs[0]
        
        for inp, out in zip(inputs, outputs):
            dist = abs(inp - x)
            if dist < min_dist:
                min_dist = dist
                closest_output = out
        
        return closest_output
    
    def _fit_line(self, xs: List[float], ys: List[float]) -> tuple:
        """Fit a line y = mx + b, return (m, b)."""
        n = len(xs)
        if n < 2:
            return (0, ys[0] if ys else 0)
        
        sum_x = sum(xs)
        sum_y = sum(ys)
        sum_xy = sum(x * y for x, y in zip(xs, ys))
        sum_x2 = sum(x * x for x in xs)
        
        denom = n * sum_x2 - sum_x * sum_x
        if abs(denom) < 1e-10:
            return (0, sum_y / n)
        
        m = (n * sum_xy - sum_x * sum_y) / denom
        b = (sum_y - m * sum_x) / n
        
        return (m, b)
    
    def _is_perfectly_linear(self, inputs: List[float], outputs: List[float]) -> bool:
        """Check if data is PERFECTLY linear (R² ≈ 1.0)."""
        if len(inputs) < 2:
            return False
        
        m, b = self._fit_line(inputs, outputs)
        
        # Check R-squared - must be nearly perfect
        mean_y = sum(outputs) / len(outputs)
        ss_tot = sum((y - mean_y) ** 2 for y in outputs)
        ss_res = sum((y - (m * x + b)) ** 2 for x, y in zip(inputs, outputs))
        
        if ss_tot == 0:
            return True  # All points have same y value
        
        r_squared = 1 - (ss_res / ss_tot)
        return r_squared > 0.999  # Nearly perfect linear fit
    
    def _is_linear(self, inputs: List[float], outputs: List[float], threshold: float = 0.95) -> bool:
        """Check if data follows a linear pattern."""
        if len(inputs) < 2:
            return False
        
        m, b = self._fit_line(inputs, outputs)
        
        # Check R-squared
        mean_y = sum(outputs) / len(outputs)
        ss_tot = sum((y - mean_y) ** 2 for y in outputs)
        ss_res = sum((y - (m * x + b)) ** 2 for x, y in zip(inputs, outputs))
        
        if ss_tot == 0:
            return True
        
        r_squared = 1 - (ss_res / ss_tot)
        return r_squared > threshold
    
    def _is_exponential(self, inputs: List[float], outputs: List[float], threshold: float = 0.9) -> bool:
        """Check if data follows an exponential pattern."""
        import math
        
        # All outputs must be positive
        if any(y <= 0 for y in outputs):
            return False
        
        try:
            log_outputs = [math.log(y) for y in outputs]
            return self._is_linear(inputs, log_outputs, threshold)
        except (ValueError, OverflowError):
            return False
    
    def _is_logarithmic(self, inputs: List[float], outputs: List[float], threshold: float = 0.9) -> bool:
        """Check if data follows a logarithmic pattern."""
        import math
        
        # All inputs must be positive
        if any(x <= 0 for x in inputs):
            return False
        
        try:
            log_inputs = [math.log(x) for x in inputs]
            return self._is_linear(log_inputs, outputs, threshold)
        except (ValueError, OverflowError):
            return False
    
    def _is_piecewise(self, inputs: List[float], outputs: List[float]) -> bool:
        """Check if data shows piecewise behavior (different slopes in different regions).
        
        IMPROVED: Lowered threshold from 1.0x to 0.5x for better sensitivity.
        FIXED: Added polynomial check to avoid false positives on curved functions.
        IMPROVED: Check multiple split points for robustness.
        """
        if len(inputs) < 3:
            return False
        
        # Sort by input
        sorted_pairs = sorted(zip(inputs, outputs))
        
        # For 3 points, check if middle point doesn't lie on line between endpoints
        if len(sorted_pairs) == 3:
            x0, y0 = sorted_pairs[0]
            x1, y1 = sorted_pairs[1]
            x2, y2 = sorted_pairs[2]
            
            # Expected y at x1 if linear
            if x2 != x0:
                expected_y1 = y0 + (y2 - y0) * (x1 - x0) / (x2 - x0)
                # If actual y1 differs significantly from expected, likely piecewise
                # Use relative threshold based on output range
                output_range = max(outputs) - min(outputs)
                if output_range > 0 and abs(y1 - expected_y1) > 0.3 * output_range:
                    return True
            return False
        
        # For 4+ points, check multiple split points
        # IMPROVED: Try quartile splits instead of just midpoint
        best_slope_diff = 0
        max_avg_slope = 0
        
        for split_ratio in [0.33, 0.5, 0.67]:
            split_idx = int(len(sorted_pairs) * split_ratio)
            if split_idx < 2 or split_idx >= len(sorted_pairs) - 1:
                continue
            
            first_part = sorted_pairs[:split_idx]
            second_part = sorted_pairs[split_idx:]
            
            if len(first_part) < 2 or len(second_part) < 2:
                continue
            
            m1, b1 = self._fit_line([p[0] for p in first_part], [p[1] for p in first_part])
            m2, b2 = self._fit_line([p[0] for p in second_part], [p[1] for p in second_part])
            
            slope_diff = abs(m1 - m2)
            avg_slope_mag = (abs(m1) + abs(m2)) / 2
            
            best_slope_diff = max(best_slope_diff, slope_diff)
            max_avg_slope = max(max_avg_slope, avg_slope_mag)
        
        # FIXED: Compare slope difference to average slope magnitude
        # If slopes differ by more than 50% of their average magnitude, it's piecewise
        if max_avg_slope > 0:
            return best_slope_diff > 0.5 * max_avg_slope
        else:
            # Both slopes near zero - check absolute difference
            return best_slope_diff > 1.0
    
    def store_skill(self, pattern: str, solution: Any, episode: int = 0):
        """Store a successful pattern with ECM-aligned forgetting."""
        skill_id = self.skill_memory.add_skill(
            pattern=pattern,
            solution=solution,
            quality=self.quality_level,
            domain="reverse_engineering",
            episode=episode
        )
        
        # Apply periodic cleanup
        if episode > 0 and episode % 50 == 0:
            self.skill_memory.apply_decay(episode)
            self.skill_memory.consolidate_similar_skills()
    
    def get_relevant_skills(self, task: Dict[str, Any]) -> List[Dict]:
        """Get skills relevant to current task using salience ranking."""
        func_type = task.get("function_type", "")
        
        # Get top skills by salience
        top_skills = self.skill_memory.get_top_skills(n=5, domain="reverse_engineering")
        
        # Filter by pattern relevance
        relevant = []
        for skill in top_skills:
            if func_type.lower() in skill.pattern.lower():
                relevant.append({
                    "pattern": skill.pattern,
                    "solution": skill.solution,
                    "quality": skill.quality,
                    "salience": skill.salience
                })
        
        return relevant
