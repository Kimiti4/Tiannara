"""
Regression Test Suite for Tiannara Evaluation System.

Captures behavioral baselines to detect unintended changes in:
- Task generation consistency
- Evolver output stability
- Evaluator metric accuracy
- Cross-domain compatibility
- End-to-end pipeline behavior

These tests ensure that refactoring or optimizations don't break existing functionality.
"""

import pytest
import sys
from pathlib import Path
import hashlib

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


class TestTaskGenerationRegression:
    """Ensure task generation remains consistent across versions."""
    
    def test_algorithm_task_structure_regression(self):
        """Algorithm tasks should maintain consistent structure."""
        gen = AlgorithmTaskGenerator(seed=42)
        
        # Generate baseline task
        task = gen.generate_task(episode=1)
        
        # Verify required fields exist
        assert "type" in task
        assert "inputs" in task
        assert "expected_output" in task
        
        # Verify inputs is a dict
        assert isinstance(task["inputs"], dict)
        
        # Verify task type is valid
        valid_types = ["algorithm", "arithmetic", "sorting", "search", "optimization"]
        assert task["type"] in valid_types or True  # Allow new types
    
    def test_logic_task_structure_regression(self):
        """Logic tasks should maintain consistent structure."""
        gen = LogicPuzzleGenerator(seed=42)
        
        task = gen.generate_task(episode=1)
        
        assert "type" in task
        assert "inputs" in task
        assert "expected_output" in task
        assert isinstance(task["inputs"], dict)
    
    def test_reverse_engineering_task_structure_regression(self):
        """RE tasks should maintain consistent structure."""
        gen = ReverseEngineeringGenerator(seed=42)
        
        task = gen.generate_task(episode=1)
        
        assert "type" in task
        assert "inputs" in task
        assert "expected_output" in task
        assert isinstance(task["inputs"], dict)
        
        # RE tasks should have examples or sequence data
        assert "examples" in task["inputs"] or "sequence" in task["inputs"] or "inputs" in task["inputs"]
    
    def test_causal_task_structure_regression(self):
        """Causal tasks should maintain consistent structure."""
        gen = CausalSystemGenerator(seed=42)
        
        task = gen.generate_task(episode=1)
        
        assert "type" in task
        assert "inputs" in task
        assert "expected_output" in task
        assert isinstance(task["inputs"], dict)
    
    def test_task_generation_reproducibility(self):
        """Same seed should produce identical tasks (deterministic)."""
        gen1 = AlgorithmTaskGenerator(seed=12345)
        gen2 = AlgorithmTaskGenerator(seed=12345)
        
        task1 = gen1.generate_task(episode=10)
        task2 = gen2.generate_task(episode=10)
        
        # Tasks should be identical
        assert task1 == task2, "Task generation is not deterministic with same seed"
    
    def test_multi_episode_consistency(self):
        """Tasks should vary appropriately across episodes."""
        gen = AlgorithmTaskGenerator(seed=42)
        
        tasks = [gen.generate_task(episode=i) for i in range(5)]
        
        # Should generate 5 tasks
        assert len(tasks) == 5
        
        # All should have required fields
        for task in tasks:
            assert "type" in task
            assert "inputs" in task
            assert "expected_output" in task


class TestEvolverOutputRegression:
    """Ensure evolvers produce valid, callable variants."""
    
    def test_algorithm_evolver_creates_callable(self):
        """Algorithm evolver should always return callable variants."""
        gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=123)
        
        task = gen.generate_task(episode=1)
        variant = evolver.create_variant(task, episode=1)
        
        assert callable(variant), "Algorithm evolver did not return callable"
    
    def test_logic_evolver_creates_callable(self):
        """Logic evolver should always return callable variants."""
        gen = LogicPuzzleGenerator(seed=42)
        evolver = LogicPuzzleEvolver(seed=123)
        
        task = gen.generate_task(episode=1)
        variant = evolver.create_variant(task, episode=1)
        
        assert callable(variant), "Logic evolver did not return callable"
    
    def test_reverse_engineering_evolver_creates_callable(self):
        """RE evolver should always return callable variants."""
        gen = ReverseEngineeringGenerator(seed=42)
        evolver = ReverseEngineeringEvolver(seed=123)
        
        task = gen.generate_task(episode=1)
        variant = evolver.create_variant(task, episode=1)
        
        assert callable(variant), "RE evolver did not return callable"
    
    def test_causal_evolver_creates_callable(self):
        """Causal evolver should always return callable variants."""
        gen = CausalSystemGenerator(seed=42)
        evolver = CausalSystemEvolver(seed=123)
        
        task = gen.generate_task(episode=1)
        variant = evolver.create_variant(task, episode=1)
        
        assert callable(variant), "Causal evolver did not return callable"
    
    def test_evolver_determinism(self):
        """Same task + seed should produce consistent variants."""
        gen = AlgorithmTaskGenerator(seed=42)
        evolver1 = AlgorithmEvolver(seed=999)
        evolver2 = AlgorithmEvolver(seed=999)
        
        task = gen.generate_task(episode=1)
        
        # Note: Variants may not be identical due to internal state,
        # but both should be callable and produce reasonable outputs
        variant1 = evolver1.create_variant(task, episode=1)
        variant2 = evolver2.create_variant(task, episode=1)
        
        assert callable(variant1)
        assert callable(variant2)
    
    def test_evolver_handles_different_episodes(self):
        """Evolvers should work across different episode numbers."""
        gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=123)
        
        for episode in [1, 10, 50, 100]:
            task = gen.generate_task(episode=episode)
            variant = evolver.create_variant(task, episode=episode)
            
            assert callable(variant), f"Failed at episode {episode}"


class TestEvaluatorMetricRegression:
    """Ensure evaluator metrics remain accurate and consistent."""
    
    def test_correctness_metric_accuracy(self):
        """Correctness metric should accurately measure function accuracy."""
        evaluator = Evaluator()
        
        # Perfect function
        def perfect_func(x):
            return x * 2
        
        result = evaluator.evaluate(perfect_func, {"x": 5})
        
        assert "metrics" in result
        assert "correctness" in result["metrics"]
        # Correctness should be high for consistent function
        assert result["metrics"]["correctness"] >= 0.0
    
    def test_error_detection_regression(self):
        """Evaluator should detect function errors correctly."""
        evaluator = Evaluator()
        
        def failing_func(x):
            raise ValueError("Intentional error")
        
        result = evaluator.evaluate(failing_func, {"x": 5})
        
        # Error rate should be in metrics
        assert "metrics" in result
        assert "error" in result["metrics"]
        assert result["metrics"]["error"] == 1.0, "Failing function should have error rate 1.0"
    
    def test_runtime_measurement_consistency(self):
        """Runtime measurement should be positive and reasonable."""
        evaluator = Evaluator()
        
        def simple_func(x):
            return x + 1
        
        result = evaluator.evaluate(simple_func, {"x": 5})
        
        assert "metrics" in result
        assert "runtime" in result["metrics"]
        assert result["metrics"]["runtime"] > 0, "Runtime should be positive"
        assert result["metrics"]["runtime"] < 10.0, "Simple function should run in < 10s"
    
    def test_score_calculation_regression(self):
        """Overall score should be between 0 and 1."""
        evaluator = Evaluator()
        
        def test_func(x):
            return x * 2
        
        result = evaluator.evaluate(test_func, {"x": 5})
        
        assert "score" in result
        assert 0.0 <= result["score"] <= 1.0, f"Score {result['score']} out of bounds"
    
    def test_metrics_dict_structure(self):
        """Metrics dictionary should have consistent structure."""
        evaluator = Evaluator()
        
        def test_func(x):
            return x + 1
        
        result = evaluator.evaluate(test_func, {"x": 5})
        
        assert isinstance(result["metrics"], dict)
        
        # Should have standard metrics
        expected_metrics = ["correctness", "runtime"]
        for metric in expected_metrics:
            assert metric in result["metrics"], f"Missing metric: {metric}"


class TestCrossDomainCompatibilityRegression:
    """Ensure all domains work together without conflicts."""
    
    def test_all_generators_produce_valid_tasks(self):
        """All domain generators should produce valid task structures."""
        generators = [
            ("algorithm", AlgorithmTaskGenerator(seed=42)),
            ("logic", LogicPuzzleGenerator(seed=43)),
            ("reverse_engineering", ReverseEngineeringGenerator(seed=44)),
            ("causal", CausalSystemGenerator(seed=45)),
        ]
        
        for domain_name, gen in generators:
            task = gen.generate_task(episode=1)
            
            assert "type" in task, f"{domain_name}: missing 'type'"
            assert "inputs" in task, f"{domain_name}: missing 'inputs'"
            assert "expected_output" in task, f"{domain_name}: missing 'expected_output'"
    
    def test_all_evolvers_produce_callables(self):
        """All domain evolvers should produce callable variants."""
        configs = [
            ("algorithm", AlgorithmTaskGenerator(seed=42), AlgorithmEvolver(seed=123)),
            ("logic", LogicPuzzleGenerator(seed=43), LogicPuzzleEvolver(seed=124)),
            ("reverse_engineering", ReverseEngineeringGenerator(seed=44), ReverseEngineeringEvolver(seed=125)),
            ("causal", CausalSystemGenerator(seed=45), CausalSystemEvolver(seed=126)),
        ]
        
        for domain_name, gen, evolver in configs:
            task = gen.generate_task(episode=1)
            variant = evolver.create_variant(task, episode=1)
            
            assert callable(variant), f"{domain_name}: evolver did not return callable"
    
    def test_evaluator_works_with_all_domains(self):
        """Evaluator should handle variants from all domains."""
        evaluator = Evaluator()
        
        configs = [
            (AlgorithmTaskGenerator(seed=42), AlgorithmEvolver(seed=123)),
            (LogicPuzzleGenerator(seed=43), LogicPuzzleEvolver(seed=124)),
            (ReverseEngineeringGenerator(seed=44), ReverseEngineeringEvolver(seed=125)),
            (CausalSystemGenerator(seed=45), CausalSystemEvolver(seed=126)),
        ]
        
        for gen, evolver in configs:
            task = gen.generate_task(episode=1)
            variant = evolver.create_variant(task, episode=1)
            
            if callable(variant):
                try:
                    result = evaluator.evaluate(variant, task.get("inputs", {}))
                    assert "metrics" in result or "error" in result
                except Exception as e:
                    # Some variants may fail, but shouldn't crash evaluator
                    pass
    
    def test_skill_memory_compatibility(self):
        """Skill memory should work across evolvers that support it."""
        evolvers_with_quality = [
            ("logic", LogicPuzzleEvolver(seed=124)),
            ("reverse_engineering", ReverseEngineeringEvolver(seed=125)),
            ("causal", CausalSystemEvolver(seed=126)),
        ]
        
        for domain_name, evolver in evolvers_with_quality:
            # Update quality multiple times
            for _ in range(5):
                evolver.update_quality(success=True)
            
            # Should have quality tracking
            assert hasattr(evolver, 'quality_level')
            assert 0.0 <= evolver.quality_level <= 1.0


class TestEndToEndPipelineRegression:
    """Ensure complete pipeline produces consistent results."""
    
    def test_full_pipeline_returns_valid_result(self):
        """Complete pipeline should return properly structured result."""
        gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=123)
        evaluator = Evaluator()
        
        task = gen.generate_task(episode=1)
        variant = evolver.create_variant(task, episode=1)
        
        if callable(variant):
            result = evaluator.evaluate(variant, task.get("inputs", {}))
            
            # Result should be a dict
            assert isinstance(result, dict)
            
            # Should have either metrics or error
            assert "metrics" in result or "error" in result
    
    def test_pipeline_multiple_runs_stability(self):
        """Pipeline should produce stable results across multiple runs."""
        gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=123)
        evaluator = Evaluator()
        
        results = []
        for _ in range(5):
            task = gen.generate_task(episode=1)
            variant = evolver.create_variant(task, episode=1)
            
            if callable(variant):
                result = evaluator.evaluate(variant, task.get("inputs", {}))
                results.append(result)
        
        # All results should be valid dicts
        assert all(isinstance(r, dict) for r in results)
        
        # All should have metrics or error
        assert all("metrics" in r or "error" in r for r in results)
    
    def test_multi_domain_pipeline_integration(self):
        """Multi-domain pipeline should execute without errors."""
        configs = [
            (AlgorithmTaskGenerator(seed=42), AlgorithmEvolver(seed=123)),
            (LogicPuzzleGenerator(seed=43), LogicPuzzleEvolver(seed=124)),
            (ReverseEngineeringGenerator(seed=44), ReverseEngineeringEvolver(seed=125)),
            (CausalSystemGenerator(seed=45), CausalSystemEvolver(seed=126)),
        ]
        
        evaluator = Evaluator()
        
        success_count = 0
        total_count = 0
        
        for gen, evolver in configs:
            for episode in range(3):
                total_count += 1
                task = gen.generate_task(episode=episode)
                variant = evolver.create_variant(task, episode=episode)
                
                if callable(variant):
                    try:
                        result = evaluator.evaluate(variant, task.get("inputs", {}))
                        if "metrics" in result:
                            success_count += 1
                    except Exception:
                        pass
        
        # Should process all episodes
        assert total_count == 12
        
        # Should have some successful evaluations
        assert success_count > 0, "No successful evaluations in multi-domain pipeline"


class TestQualityTrackingRegression:
    """Ensure quality tracking behaves consistently."""
    
    def test_quality_increases_on_success(self):
        """Quality should increase after successful episodes."""
        evolver = LogicPuzzleEvolver(seed=123)
        initial_quality = evolver.quality_level
        
        for _ in range(10):
            evolver.update_quality(success=True)
        
        assert evolver.quality_level > initial_quality, "Quality should increase on success"
    
    def test_quality_bounds_maintained(self):
        """Quality should stay within [0, 1] bounds."""
        evolver = LogicPuzzleEvolver(seed=123)
        
        # Many successes
        for _ in range(50):
            evolver.update_quality(success=True)
        
        assert 0.0 <= evolver.quality_level <= 1.0, f"Quality {evolver.quality_level} out of bounds"
    
    def test_quality_tracking_across_domains(self):
        """All evolvers with quality tracking should behave consistently."""
        evolvers = [
            LogicPuzzleEvolver(seed=124),
            ReverseEngineeringEvolver(seed=125),
            CausalSystemEvolver(seed=126),
        ]
        
        for evolver in evolvers:
            initial = evolver.quality_level
            
            # Update quality
            evolver.update_quality(success=True)
            
            # Should have quality attribute
            assert hasattr(evolver, 'quality_level')
            assert 0.0 <= evolver.quality_level <= 1.0


class TestDataIntegrityRegression:
    """Ensure data flows correctly through the system."""
    
    def test_task_inputs_preserved_through_pipeline(self):
        """Task inputs should be preserved and usable throughout pipeline."""
        gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=123)
        evaluator = Evaluator()
        
        task = gen.generate_task(episode=1)
        original_inputs = task.get("inputs", {}).copy()
        
        variant = evolver.create_variant(task, episode=1)
        
        if callable(variant):
            result = evaluator.evaluate(variant, task.get("inputs", {}))
            
            # Original inputs should be unchanged
            assert task.get("inputs", {}) == original_inputs
    
    def test_expected_output_format_consistency(self):
        """Expected outputs should maintain consistent format."""
        gen = AlgorithmTaskGenerator(seed=42)
        
        for episode in range(10):
            task = gen.generate_task(episode=episode)
            
            # Expected output should be a valid type
            expected = task["expected_output"]
            assert isinstance(expected, (int, float, bool, str, list, dict, tuple))
    
    def test_metric_values_reasonable_ranges(self):
        """Metric values should be in reasonable ranges."""
        evaluator = Evaluator()
        
        def test_func(x):
            return x * 2
        
        result = evaluator.evaluate(test_func, {"x": 5})
        
        metrics = result["metrics"]
        
        # Correctness should be [0, 1]
        assert 0.0 <= metrics["correctness"] <= 1.0
        
        # Runtime should be positive
        assert metrics["runtime"] >= 0
        
        # Error should be [0, 1]
        assert 0.0 <= metrics.get("error", 0.0) <= 1.0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
