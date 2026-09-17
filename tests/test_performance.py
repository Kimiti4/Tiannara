"""
Performance Benchmarks for Tiannara Evaluation System.

Measures execution time, memory usage, and scalability of critical operations.
Establishes baselines to detect performance regressions.
"""

import pytest
import time
import sys
import tracemalloc
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


class TestTaskGenerationPerformance:
    """Benchmark task generation speed across all domains."""
    
    def test_algorithm_task_generation_speed(self):
        """Algorithm task generation should complete within 100ms."""
        gen = AlgorithmTaskGenerator(seed=42)
        
        start_time = time.perf_counter()
        for i in range(10):
            task = gen.generate_task(episode=i)
        end_time = time.perf_counter()
        
        avg_time_ms = ((end_time - start_time) / 10) * 1000
        
        # Should generate tasks quickly (< 100ms per task)
        assert avg_time_ms < 100, f"Algorithm task generation too slow: {avg_time_ms:.2f}ms"
    
    def test_logic_task_generation_speed(self):
        """Logic puzzle generation should complete within 100ms."""
        gen = LogicPuzzleGenerator(seed=42)
        
        start_time = time.perf_counter()
        for i in range(10):
            task = gen.generate_task(episode=i)
        end_time = time.perf_counter()
        
        avg_time_ms = ((end_time - start_time) / 10) * 1000
        
        assert avg_time_ms < 100, f"Logic task generation too slow: {avg_time_ms:.2f}ms"
    
    def test_reverse_engineering_task_generation_speed(self):
        """RE task generation should complete within 100ms."""
        gen = ReverseEngineeringGenerator(seed=42)
        
        start_time = time.perf_counter()
        for i in range(10):
            task = gen.generate_task(episode=i)
        end_time = time.perf_counter()
        
        avg_time_ms = ((end_time - start_time) / 10) * 1000
        
        assert avg_time_ms < 100, f"RE task generation too slow: {avg_time_ms:.2f}ms"
    
    def test_causal_task_generation_speed(self):
        """Causal task generation should complete within 150ms (more complex)."""
        gen = CausalSystemGenerator(seed=42)
        
        start_time = time.perf_counter()
        for i in range(10):
            task = gen.generate_task(episode=i)
        end_time = time.perf_counter()
        
        avg_time_ms = ((end_time - start_time) / 10) * 1000
        
        # Causal is more complex, allow slightly more time
        assert avg_time_ms < 150, f"Causal task generation too slow: {avg_time_ms:.2f}ms"
    
    def test_multi_domain_task_generation_throughput(self):
        """Should generate 100 tasks across all domains within 5 seconds."""
        generators = [
            AlgorithmTaskGenerator(seed=42),
            LogicPuzzleGenerator(seed=43),
            ReverseEngineeringGenerator(seed=44),
            CausalSystemGenerator(seed=45),
        ]
        
        start_time = time.perf_counter()
        
        total_tasks = 0
        for gen in generators:
            for i in range(25):
                task = gen.generate_task(episode=i)
                total_tasks += 1
        
        end_time = time.perf_counter()
        total_time_s = end_time - start_time
        
        assert total_tasks == 100
        assert total_time_s < 5.0, f"Multi-domain generation too slow: {total_time_s:.2f}s for 100 tasks"
        print(f"\n✓ Generated {total_tasks} tasks in {total_time_s:.2f}s ({total_tasks/total_time_s:.1f} tasks/sec)")


class TestEvolverPerformance:
    """Benchmark evolver variant creation speed."""
    
    def test_algorithm_evolver_speed(self):
        """Algorithm evolver should create variants within 50ms."""
        gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=123)
        
        task = gen.generate_task(episode=1)
        
        start_time = time.perf_counter()
        for _ in range(10):
            variant = evolver.create_variant(task, episode=1)
        end_time = time.perf_counter()
        
        avg_time_ms = ((end_time - start_time) / 10) * 1000
        
        assert avg_time_ms < 50, f"Algorithm evolver too slow: {avg_time_ms:.2f}ms"
    
    def test_logic_evolver_speed(self):
        """Logic evolver should create variants within 50ms."""
        gen = LogicPuzzleGenerator(seed=42)
        evolver = LogicPuzzleEvolver(seed=123)
        
        task = gen.generate_task(episode=1)
        
        start_time = time.perf_counter()
        for _ in range(10):
            variant = evolver.create_variant(task, episode=1)
        end_time = time.perf_counter()
        
        avg_time_ms = ((end_time - start_time) / 10) * 1000
        
        assert avg_time_ms < 50, f"Logic evolver too slow: {avg_time_ms:.2f}ms"
    
    def test_reverse_engineering_evolver_speed(self):
        """RE evolver should create variants within 50ms."""
        gen = ReverseEngineeringGenerator(seed=42)
        evolver = ReverseEngineeringEvolver(seed=123)
        
        task = gen.generate_task(episode=1)
        
        start_time = time.perf_counter()
        for _ in range(10):
            variant = evolver.create_variant(task, episode=1)
        end_time = time.perf_counter()
        
        avg_time_ms = ((end_time - start_time) / 10) * 1000
        
        assert avg_time_ms < 50, f"RE evolver too slow: {avg_time_ms:.2f}ms"
    
    def test_causal_evolver_speed(self):
        """Causal evolver should create variants within 100ms (complex analysis)."""
        gen = CausalSystemGenerator(seed=42)
        evolver = CausalSystemEvolver(seed=123)
        
        task = gen.generate_task(episode=1)
        
        start_time = time.perf_counter()
        for _ in range(10):
            variant = evolver.create_variant(task, episode=1)
        end_time = time.perf_counter()
        
        avg_time_ms = ((end_time - start_time) / 10) * 1000
        
        # Causal involves PC algorithm, allow more time
        assert avg_time_ms < 100, f"Causal evolver too slow: {avg_time_ms:.2f}ms"


class TestEvaluatorPerformance:
    """Benchmark evaluator execution speed."""
    
    def test_evaluator_simple_function_speed(self):
        """Evaluator should execute simple functions within 200ms."""
        evaluator = Evaluator()
        
        def simple_func(x):
            return x * 2 + 1
        
        inputs = {"x": 5}
        
        start_time = time.perf_counter()
        for _ in range(10):
            result = evaluator.evaluate(simple_func, inputs)
        end_time = time.perf_counter()
        
        avg_time_ms = ((end_time - start_time) / 10) * 1000
        
        assert avg_time_ms < 200, f"Evaluator too slow for simple function: {avg_time_ms:.2f}ms"
    
    def test_evaluator_complex_function_speed(self):
        """Evaluator should handle complex functions within 500ms."""
        evaluator = Evaluator()
        
        def complex_func(x, y):
            result = 0
            for i in range(100):
                result += (x * i) ** 2 + (y * i) ** 2
            return result
        
        inputs = {"x": 3, "y": 4}
        
        start_time = time.perf_counter()
        for _ in range(10):
            result = evaluator.evaluate(complex_func, inputs)
        end_time = time.perf_counter()
        
        avg_time_ms = ((end_time - start_time) / 10) * 1000
        
        assert avg_time_ms < 500, f"Evaluator too slow for complex function: {avg_time_ms:.2f}ms"
    
    def test_evaluator_timeout_overhead(self):
        """Evaluator should have minimal overhead for function calls."""
        evaluator = Evaluator()
        
        def fast_func(x):
            return x * 2
        
        inputs = {"x": 5}
        
        # Measure evaluation time
        start_time = time.perf_counter()
        for _ in range(10):
            result = evaluator.evaluate(fast_func, inputs)
        end_time = time.perf_counter()
        
        avg_time_ms = ((end_time - start_time) / 10) * 1000
        
        # Should be very fast (< 50ms per evaluation)
        assert avg_time_ms < 50, f"Evaluator overhead too high: {avg_time_ms:.2f}ms"
        print(f"\n✓ Evaluator overhead: {avg_time_ms:.2f}ms per call")


class TestMemoryUsage:
    """Benchmark memory consumption patterns."""
    
    def test_task_generation_memory_stability(self):
        """Task generation should not leak memory over 100 episodes."""
        tracemalloc.start()
        
        gen = AlgorithmTaskGenerator(seed=42)
        
        # Generate many tasks
        for i in range(100):
            task = gen.generate_task(episode=i)
        
        current, peak = tracemalloc.get_traced_memory()
        tracemalloc.stop()
        
        # Peak memory should be reasonable (< 10MB for 100 tasks)
        peak_mb = peak / (1024 * 1024)
        assert peak_mb < 10.0, f"Memory usage too high: {peak_mb:.2f}MB"
        print(f"\n✓ Task generation peak memory: {peak_mb:.2f}MB")
    
    def test_evaluator_memory_stability(self):
        """Evaluator should not leak memory over multiple evaluations."""
        tracemalloc.start()
        
        evaluator = Evaluator()
        
        def test_func(x):
            return x * 2
        
        # Run many evaluations
        for i in range(100):
            result = evaluator.evaluate(test_func, {"x": i})
        
        current, peak = tracemalloc.get_traced_memory()
        tracemalloc.stop()
        
        peak_mb = peak / (1024 * 1024)
        assert peak_mb < 10.0, f"Evaluator memory usage too high: {peak_mb:.2f}MB"
        print(f"\n✓ Evaluator peak memory: {peak_mb:.2f}MB")
    
    def test_evolver_memory_stability(self):
        """Evolver should not leak memory during variant creation."""
        tracemalloc.start()
        
        gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=123)
        
        task = gen.generate_task(episode=1)
        
        # Create many variants
        for i in range(50):
            variant = evolver.create_variant(task, episode=i)
        
        current, peak = tracemalloc.get_traced_memory()
        tracemalloc.stop()
        
        peak_mb = peak / (1024 * 1024)
        assert peak_mb < 15.0, f"Evolver memory usage too high: {peak_mb:.2f}MB"
        print(f"\n✓ Evolver peak memory: {peak_mb:.2f}MB")


class TestScalability:
    """Test system behavior under increased load."""
    
    def test_concurrent_episode_simulation(self):
        """Should handle simulated concurrent episodes efficiently."""
        generators = [
            AlgorithmTaskGenerator(seed=i) for i in range(10)
        ]
        evolvers = [
            AlgorithmEvolver(seed=i+100) for i in range(10)
        ]
        evaluator = Evaluator()
        
        start_time = time.perf_counter()
        
        total_episodes = 0
        for gen, evolver in zip(generators, evolvers):
            for episode in range(10):
                task = gen.generate_task(episode=episode)
                variant = evolver.create_variant(task, episode=episode)
                
                # Evaluate if variant is callable
                if callable(variant):
                    try:
                        result = evaluator.evaluate(variant, task.get("inputs", {}))
                    except Exception:
                        pass  # Some variants may fail, that's ok
                
                total_episodes += 1
        
        end_time = time.perf_counter()
        total_time_s = end_time - start_time
        
        assert total_episodes == 100
        assert total_time_s < 10.0, f"Concurrent simulation too slow: {total_time_s:.2f}s"
        print(f"\n✓ Processed {total_episodes} episodes in {total_time_s:.2f}s ({total_episodes/total_time_s:.1f} eps/sec)")
    
    def test_long_running_stability(self):
        """System should remain stable over 500+ episodes."""
        gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=123)
        evaluator = Evaluator()
        
        start_time = time.perf_counter()
        
        success_count = 0
        for episode in range(500):
            task = gen.generate_task(episode=episode)
            variant = evolver.create_variant(task, episode=episode)
            
            if callable(variant):
                try:
                    result = evaluator.evaluate(variant, task.get("inputs", {}))
                    if result.get("metrics", {}).get("correctness", 0) > 0:
                        success_count += 1
                except Exception:
                    pass
        
        end_time = time.perf_counter()
        total_time_s = end_time - start_time
        
        # Should complete 500 episodes in reasonable time
        assert total_time_s < 60.0, f"Long-running test too slow: {total_time_s:.2f}s"
        print(f"\n✓ Completed {success_count}/500 successful episodes in {total_time_s:.2f}s")


class TestEndToEndPipelinePerformance:
    """Benchmark complete pipeline execution."""
    
    def test_full_pipeline_single_episode(self):
        """Complete pipeline (generate → evolve → evaluate) should complete within 500ms."""
        gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=123)
        evaluator = Evaluator()
        
        start_time = time.perf_counter()
        
        task = gen.generate_task(episode=1)
        variant = evolver.create_variant(task, episode=1)
        
        if callable(variant):
            result = evaluator.evaluate(variant, task.get("inputs", {}))
        
        end_time = time.perf_counter()
        total_time_ms = (end_time - start_time) * 1000
        
        assert total_time_ms < 500, f"Full pipeline too slow: {total_time_ms:.2f}ms"
        print(f"\n✓ Single episode pipeline: {total_time_ms:.2f}ms")
    
    def test_multi_domain_pipeline_throughput(self):
        """Multi-domain pipeline should process 50 episodes within 15 seconds."""
        configs = [
            (AlgorithmTaskGenerator(seed=42), AlgorithmEvolver(seed=123)),
            (LogicPuzzleGenerator(seed=43), LogicPuzzleEvolver(seed=124)),
            (ReverseEngineeringGenerator(seed=44), ReverseEngineeringEvolver(seed=125)),
            (CausalSystemGenerator(seed=45), CausalSystemEvolver(seed=126)),
        ]
        
        evaluator = Evaluator()
        
        start_time = time.perf_counter()
        
        total_episodes = 0
        for gen, evolver in configs:
            for episode in range(12):  # ~12 episodes per domain = 48 total
                task = gen.generate_task(episode=episode)
                variant = evolver.create_variant(task, episode=episode)
                
                if callable(variant):
                    try:
                        result = evaluator.evaluate(variant, task.get("inputs", {}))
                    except Exception:
                        pass
                
                total_episodes += 1
        
        end_time = time.perf_counter()
        total_time_s = end_time - start_time
        
        assert total_episodes >= 48
        assert total_time_s < 15.0, f"Multi-domain pipeline too slow: {total_time_s:.2f}s"
        print(f"\n✓ Multi-domain pipeline: {total_episodes} episodes in {total_time_s:.2f}s ({total_episodes/total_time_s:.1f} eps/sec)")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
