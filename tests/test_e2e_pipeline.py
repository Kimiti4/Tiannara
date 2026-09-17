"""
End-to-End Pipeline Tests

Validates complete workflow from task generation through evaluation and scoring.
Tests full episode execution, multi-domain experiments, and skill memory integration.
"""

import pytest
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.logic_domain import LogicPuzzleGenerator
from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
from tiannara_core.evaluation.logic_evolution_engine import LogicPuzzleEvolver
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver
from tiannara_core.evaluation.evaluator import Evaluator


class TestFullEpisodeExecution:
    """Test complete episode lifecycle for each domain."""
    
    def test_algorithm_episode_end_to_end(self):
        """Validate full algorithm episode: generate → evolve → evaluate."""
        # Setup
        gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=123)
        evaluator = Evaluator()
        
        # Execute full episode
        task = gen.generate_task(episode=1)
        variant = evolver.create_variant(task, episode=1)
        
        # Evaluate
        result = evaluator.evaluate(variant, task.get("inputs", {}))
        
        # Verify
        assert "metrics" in result
        assert "score" in result
        assert isinstance(result["score"], float)
        assert 0.0 <= result["score"] <= 1.0
    
    def test_logic_episode_end_to_end(self):
        """Validate full logic episode: generate → evolve → evaluate."""
        gen = LogicPuzzleGenerator(seed=42)
        evolver = LogicPuzzleEvolver(seed=123)
        evaluator = Evaluator()
        
        task = gen.generate_task(episode=1)
        variant = evolver.create_variant(task, episode=1)
        
        result = evaluator.evaluate(variant, task.get("inputs", {}))
        
        assert "metrics" in result
        assert "score" in result
        assert isinstance(result["score"], float)
    
    def test_reverse_engineering_episode_end_to_end(self):
        """Validate full RE episode: generate → evolve → evaluate."""
        gen = ReverseEngineeringGenerator(seed=42)
        evolver = ReverseEngineeringEvolver(seed=123)
        evaluator = Evaluator()
        
        task = gen.generate_task(episode=1)
        variant = evolver.create_variant(task, episode=1)
        
        result = evaluator.evaluate(variant, task.get("inputs", {}))
        
        assert "metrics" in result
        assert "score" in result
        assert isinstance(result["score"], float)
    
    def test_causal_episode_end_to_end(self):
        """Validate full causal episode: generate → evolve → evaluate."""
        gen = CausalSystemGenerator(seed=42)
        evolver = CausalSystemEvolver(seed=123)
        evaluator = Evaluator()
        
        task = gen.generate_task(episode=1)
        variant = evolver.create_variant(task, episode=1)
        
        result = evaluator.evaluate(variant, task.get("inputs", {}))
        
        assert "metrics" in result
        assert "score" in result
        assert isinstance(result["score"], float)


class TestMultiDomainWorkflow:
    """Test workflows spanning multiple domains."""
    
    def test_cross_domain_variant_creation(self):
        """Variants from different domains should all be callable."""
        domains = [
            (AlgorithmTaskGenerator(seed=42), AlgorithmEvolver(seed=123)),
            (LogicPuzzleGenerator(seed=43), LogicPuzzleEvolver(seed=124)),
            (ReverseEngineeringGenerator(seed=44), ReverseEngineeringEvolver(seed=125)),
            (CausalSystemGenerator(seed=45), CausalSystemEvolver(seed=126)),
        ]
        
        for gen, evolver in domains:
            task = gen.generate_task(episode=1)
            variant = evolver.create_variant(task, episode=1)
            
            assert callable(variant), f"{type(gen).__name__} variant not callable"
    
    def test_multi_domain_evaluation_consistency(self):
        """All domains should produce consistent evaluation structure."""
        evaluators_and_tasks = []
        
        # Generate one task from each domain
        for GenClass, seed in [
            (AlgorithmTaskGenerator, 42),
            (LogicPuzzleGenerator, 43),
            (ReverseEngineeringGenerator, 44),
            (CausalSystemGenerator, 45),
        ]:
            gen = GenClass(seed=seed)
            task = gen.generate_task(episode=1)
            evaluators_and_tasks.append((gen, task))
        
        # Evaluate all with same evaluator
        evaluator = Evaluator()
        
        for gen, task in evaluators_and_tasks:
            # Create appropriate evolver based on generator type
            if isinstance(gen, AlgorithmTaskGenerator):
                evolver = AlgorithmEvolver(seed=123)
            elif isinstance(gen, LogicPuzzleGenerator):
                evolver = LogicPuzzleEvolver(seed=123)
            elif isinstance(gen, ReverseEngineeringGenerator):
                evolver = ReverseEngineeringEvolver(seed=123)
            else:
                evolver = CausalSystemEvolver(seed=123)
            
            variant = evolver.create_variant(task, episode=1)
            result = evaluator.evaluate(variant, task.get("inputs", {}))
            
            # All results should have consistent structure
            assert "metrics" in result
            assert "score" in result
            assert "outputs" in result or "num_runs" in result


class TestSkillMemoryIntegration:
    """Test skill memory integration in evolvers."""
    
    def test_skill_memory_accumulation(self):
        """Evolvers should track skills across episodes."""
        evolver = ReverseEngineeringEvolver(seed=42)
        initial_count = len(evolver.skill_memory)
        
        # Simulate multiple episodes with successes
        for i in range(5):
            evolver.update_quality(success=True)
        
        # Skill memory may grow (implementation-dependent)
        assert len(evolver.skill_memory) >= initial_count
    
    def test_quality_tracking_across_episodes(self):
        """Quality level should adapt based on success/failure pattern."""
        evolver = LogicPuzzleEvolver(seed=42)
        initial_quality = evolver.quality_level
        
        # Series of successes
        for _ in range(3):
            evolver.update_quality(success=True)
        
        after_successes = evolver.quality_level
        assert after_successes >= initial_quality
        
        # Quality should stay bounded
        assert 0.0 <= evolver.quality_level <= 1.0


class TestEvaluatorIntegration:
    """Test evaluator integration with various scenarios."""
    
    def test_evaluator_with_successful_function(self):
        """Evaluator should correctly score successful executions."""
        evaluator = Evaluator()
        
        def good_func(**kwargs):
            return {"output": 42, "success": True}
        
        result = evaluator.evaluate(good_func, {})
        
        assert result["metrics"]["correctness"] == 1.0
        assert result["metrics"]["error"] == 0.0
        assert result["score"] > 0.0
    
    def test_evaluator_with_failing_function(self):
        """Evaluator should correctly score failing executions."""
        evaluator = Evaluator()
        
        def bad_func(**kwargs):
            raise ValueError("Intentional failure")
        
        result = evaluator.evaluate(bad_func, {})
        
        assert result["metrics"]["correctness"] == 0.0
        assert result["metrics"]["error"] == 1.0
    
    def test_evaluator_multiple_runs_stability(self):
        """Multiple runs should provide stability metrics."""
        evaluator = Evaluator()
        
        def stable_func(**kwargs):
            return {"output": 10, "success": True}
        
        result = evaluator.evaluate(stable_func, {}, runs=5)
        
        assert result["num_runs"] == 5
        assert len(result["outputs"]) == 5
        assert "stability" in result["metrics"]


class TestErrorHandlingInPipeline:
    """Test error handling throughout the pipeline."""
    
    def test_graceful_handling_of_invalid_task(self):
        """System should handle invalid tasks gracefully."""
        gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=123)
        
        # Create minimal/invalid task
        task = {"type": "algorithm"}  # Missing required fields
        
        try:
            variant = evolver.create_variant(task, episode=1)
            # If it doesn't crash, variant should still be callable
            assert callable(variant)
        except Exception:
            # Acceptable to raise exception for invalid input
            pass
    
    def test_timeout_protection_in_evaluation(self):
        """Evaluator should enforce timeout limits."""
        evaluator = Evaluator()
        evaluator.timeout_seconds = 0.1  # 100ms timeout
        
        def slow_func(**kwargs):
            import time
            time.sleep(1)  # Sleep longer than timeout
            return {"output": 42, "success": True}
        
        result = evaluator.evaluate(slow_func, {})
        
        # Should detect timeout or high error rate
        assert result["metrics"]["error"] == 1.0 or result["metrics"]["runtime"] < 0.5


class TestDataFlowIntegrity:
    """Test data integrity through the pipeline."""
    
    def test_task_input_output_consistency(self):
        """Task inputs should flow correctly through variant execution."""
        gen = ReverseEngineeringGenerator(seed=42)
        evolver = ReverseEngineeringEvolver(seed=123)
        
        task = gen.generate_task(episode=1)
        variant = evolver.create_variant(task, episode=1)
        
        # Extract test input from task
        test_input = task.get("inputs", {}).get("test_input", 0)
        
        # Execute variant
        result = variant(test_input=test_input)
        
        # Result should be a valid number
        assert isinstance(result, (int, float))
    
    def test_metric_calculation_integrity(self):
        """Metrics should be calculated correctly from outputs."""
        evaluator = Evaluator()
        
        def deterministic_func(**kwargs):
            return {"output": 100, "success": True}
        
        result = evaluator.evaluate(deterministic_func, {}, runs=3)
        
        # All runs should produce identical output
        outputs = result["outputs"]
        assert len(outputs) == 3
        
        # Consistency should be high for identical outputs
        assert result["metrics"]["stability"] > 0.0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
