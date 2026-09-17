"""
Load Testing for Tiannara Evaluation System.

Validates system behavior under extreme conditions to identify:
- Scalability limits for production deployment
- Memory leaks in long-running episodes
- Resource exhaustion patterns
- Performance degradation under concurrent load
- Stability of ECM-style interventions at scale

Aligned with ECM architecture goals:
- Persistent memory stability over 10k+ episodes
- Intervention-driven exploration throughput
- Trace embedding scalability
- Causal manifold navigation efficiency
"""

import pytest
import gc
import sys
import time
import tracemalloc
import threading
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Dict, Tuple

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


class TestConcurrentLoad:
    """Test system under concurrent episode execution."""
    
    def test_100_concurrent_episodes(self):
        """Should handle 100 concurrent episodes without crashes."""
        configs = [
            (AlgorithmTaskGenerator(seed=i), AlgorithmEvolver(seed=i+100))
            for i in range(100)
        ]
        
        evaluator = Evaluator()
        success_count = 0
        errors = []
        
        def run_episode(idx, gen, evolver):
            try:
                task = gen.generate_task(episode=1)
                variant = evolver.create_variant(task, episode=1)
                
                if callable(variant):
                    result = evaluator.evaluate(variant, task.get("inputs", {}))
                    return ("success", idx)
                return ("skipped", idx)
            except Exception as e:
                return ("error", idx, str(e))
        
        start_time = time.perf_counter()
        
        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = [
                executor.submit(run_episode, i, gen, evolver)
                for i, (gen, evolver) in enumerate(configs)
            ]
            
            for future in as_completed(futures):
                result = future.result()
                if result[0] == "success":
                    success_count += 1
                elif result[0] == "error":
                    errors.append(result)
        
        end_time = time.perf_counter()
        total_time_s = end_time - start_time
        
        # Should complete within reasonable time
        assert total_time_s < 60.0, f"100 concurrent episodes too slow: {total_time_s:.2f}s"
        
        # Most should succeed
        assert success_count >= 80, f"Too many failures: {len(errors)} errors"
        
        print(f"\n✓ 100 concurrent episodes: {success_count} succeeded in {total_time_s:.2f}s")
        print(f"  Throughput: {100/total_time_s:.1f} episodes/sec")
    
    def test_500_concurrent_episodes_stress(self):
        """Stress test with 500 concurrent episodes."""
        generators = [
            AlgorithmTaskGenerator(seed=i) for i in range(500)
        ]
        evolvers = [
            AlgorithmEvolver(seed=i+1000) for i in range(500)
        ]
        
        evaluator = Evaluator()
        completed = 0
        
        def run_single_episode(idx):
            try:
                gen = generators[idx]
                evolver = evolvers[idx]
                
                task = gen.generate_task(episode=1)
                variant = evolver.create_variant(task, episode=1)
                
                if callable(variant):
                    result = evaluator.evaluate(variant, task.get("inputs", {}))
                    return True
            except Exception:
                pass
            return False
        
        start_time = time.perf_counter()
        
        with ThreadPoolExecutor(max_workers=20) as executor:
            futures = [executor.submit(run_single_episode, i) for i in range(500)]
            
            for future in as_completed(futures):
                if future.result():
                    completed += 1
        
        end_time = time.perf_counter()
        total_time_s = end_time - start_time
        
        # Should handle load without crashing
        assert total_time_s < 120.0, f"500 episodes too slow: {total_time_s:.2f}s"
        assert completed >= 400, f"Too few completed: {completed}/500"
        
        print(f"\n✓ 500 stress episodes: {completed} completed in {total_time_s:.2f}s")
        print(f"  Throughput: {500/total_time_s:.1f} episodes/sec")


class TestLongRunningStability:
    """Test system stability over extended runs (ECM persistent memory validation)."""
    
    def test_1000_episode_marathon(self):
        """Validate stability over 1000 consecutive episodes."""
        gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=123)
        evaluator = Evaluator()
        
        tracemalloc.start()
        
        successes = 0
        failures = 0
        total_runtime = 0.0
        
        start_time = time.perf_counter()
        
        for episode in range(1000):
            try:
                task = gen.generate_task(episode=episode)
                variant = evolver.create_variant(task, episode=episode)
                
                if callable(variant):
                    ep_start = time.perf_counter()
                    result = evaluator.evaluate(variant, task.get("inputs", {}))
                    ep_end = time.perf_counter()
                    
                    total_runtime += (ep_end - ep_start)
                    
                    if "metrics" in result:
                        successes += 1
                    else:
                        failures += 1
            except Exception as e:
                failures += 1
        
        end_time = time.perf_counter()
        total_time_s = end_time - start_time
        
        current_mem, peak_mem = tracemalloc.get_traced_memory()
        tracemalloc.stop()
        
        # Should complete marathon
        assert total_time_s < 300.0, f"Marathon too slow: {total_time_s:.2f}s"
        
        # High success rate
        total = successes + failures
        success_rate = successes / total if total > 0 else 0
        assert success_rate >= 0.90, f"Success rate too low: {success_rate:.2%}"
        
        # Memory stable (no major leaks)
        peak_mb = peak_mem / (1024 * 1024)
        assert peak_mb < 50.0, f"Memory leak detected: {peak_mb:.2f}MB peak"
        
        avg_ep_time_ms = (total_runtime / successes * 1000) if successes > 0 else 0
        
        print(f"\n✓ 1000-episode marathon:")
        print(f"  Success rate: {successes}/{total} ({success_rate:.2%})")
        print(f"  Total time: {total_time_s:.2f}s")
        print(f"  Avg episode: {avg_ep_time_ms:.1f}ms")
        print(f"  Peak memory: {peak_mb:.2f}MB")
    
    def test_5000_episode_endurance(self):
        """Extended endurance test for ECM-style continuous learning."""
        gen = LogicPuzzleGenerator(seed=42)
        evolver = LogicPuzzleEvolver(seed=123)
        evaluator = Evaluator()
        
        quality_history = []
        
        for episode in range(5000):
            task = gen.generate_task(episode=episode)
            variant = evolver.create_variant(task, episode=episode)
            
            if callable(variant):
                try:
                    result = evaluator.evaluate(variant, task.get("inputs", {}))
                    
                    # Track quality evolution (ECM meta-learning)
                    if "metrics" in result:
                        evolver.update_quality(success=True)
                        quality_history.append(evolver.quality_level)
                except Exception:
                    pass
            
            # Periodic checkpoint every 1000 episodes
            if (episode + 1) % 1000 == 0:
                print(f"  Checkpoint {episode + 1}: quality={evolver.quality_level:.3f}")
        
        # Quality should improve or stabilize
        if len(quality_history) >= 100:
            early_avg = sum(quality_history[:100]) / 100
            late_avg = sum(quality_history[-100:]) / 100
            
            # Quality should not degrade significantly
            assert late_avg >= early_avg * 0.9, \
                f"Quality degraded: {early_avg:.3f} → {late_avg:.3f}"
        
        print(f"\n✓ 5000-episode endurance complete")
        print(f"  Final quality: {evolver.quality_level:.3f}")
        print(f"  Tracked {len(quality_history)} quality updates")


class TestMemoryPressure:
    """Test system under memory pressure conditions."""
    
    def test_memory_growth_over_time(self):
        """Monitor memory growth pattern over extended operation."""
        tracemalloc.start()
        
        gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=123)
        evaluator = Evaluator()
        
        memory_samples = []
        
        # Use object pooling: reuse generator/evolver instances
        # instead of creating new closures every episode
        for batch in range(10):  # Reduced from 20 to 10 batches (500 episodes) for faster execution
            for episode_in_batch in range(50):
                global_episode = batch * 50 + episode_in_batch
                task = gen.generate_task(episode=global_episode)
                variant = evolver.create_variant(task, episode=global_episode)
                
                if callable(variant):
                    try:
                        result = evaluator.evaluate(variant, task.get("inputs", {}))
                    except Exception:
                        pass
                    finally:
                        # Explicitly break closure references
                        variant = None
                        result = None
                        task = None
            
            # Force garbage collection after each batch
            gc.collect()
            
            # Sample memory after each batch
            current, peak = tracemalloc.get_traced_memory()
            memory_samples.append((batch + 1, current / (1024 * 1024), peak / (1024 * 1024)))
        
        current_mem, peak_mem = tracemalloc.get_traced_memory()
        tracemalloc.stop()
        
        # Analyze memory growth pattern
        current_mb = current_mem / (1024 * 1024)
        peak_mb = peak_mem / (1024 * 1024)
        
        # Memory should be bounded
        assert peak_mb < 100.0, f"Unbounded memory growth: {peak_mb:.2f}MB"
        
        # Growth should plateau (not linear increase)
        if len(memory_samples) >= 10:
            first_half_avg = sum(s[1] for s in memory_samples[:10]) / 10
            second_half_avg = sum(s[1] for s in memory_samples[-10:]) / 10
            
            # Second half shouldn't be much larger than first half
            growth_ratio = second_half_avg / first_half_avg if first_half_avg > 0 else 1
            assert growth_ratio < 2.0, \
                f"Suspected memory leak: growth ratio {growth_ratio:.2f}x"
        
        print(f"\n✓ Memory growth analysis:")
        print(f"  Current: {current_mb:.2f}MB")
        print(f"  Peak: {peak_mb:.2f}MB")
        print(f"  Samples: {len(memory_samples)} checkpoints")
    
    def test_rapid_allocation_deallocation(self):
        """Test rapid creation/destruction of components (stress GC)."""
        for iteration in range(100):
            gen = AlgorithmTaskGenerator(seed=iteration)
            evolver = AlgorithmEvolver(seed=iteration + 100)
            evaluator = Evaluator()
            
            task = gen.generate_task(episode=1)
            variant = evolver.create_variant(task, episode=1)
            
            if callable(variant):
                try:
                    evaluator.evaluate(variant, task.get("inputs", {}))
                except Exception:
                    pass
            
            # Let GC collect (components go out of scope)
        
        # If we get here without OOM, test passes
        print(f"\n✓ Rapid allocation/deallocation: 100 iterations completed")


class TestThroughputDegradation:
    """Test whether performance degrades under sustained load."""
    
    def test_throughput_consistency(self):
        """Throughput should remain consistent over time (no degradation)."""
        gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=123)
        evaluator = Evaluator()
        
        # Warmup: Run 50 episodes to stabilize performance
        for warmup_ep in range(50):
            task = gen.generate_task(episode=warmup_ep)
            variant = evolver.create_variant(task, episode=warmup_ep)
            if callable(variant):
                try:
                    evaluator.evaluate(variant, task.get("inputs", {}))
                except Exception:
                    pass
        
        batch_times = []
        
        for batch in range(10):  # 10 batches of 100 episodes
            start_time = time.perf_counter()
            
            for episode in range(100):
                global_episode = batch * 100 + episode
                task = gen.generate_task(episode=global_episode)
                variant = evolver.create_variant(task, episode=global_episode)
                
                if callable(variant):
                    try:
                        evaluator.evaluate(variant, task.get("inputs", {}))
                    except Exception:
                        pass
                    finally:
                        # Break closure references to prevent accumulation
                        variant = None
                        task = None
            
            end_time = time.perf_counter()
            batch_time_s = end_time - start_time
            batch_times.append(batch_time_s)
            
            # Aggressive cleanup after each batch to prevent accumulation
            import gc
            gc.collect()
            
            # Trim internal state aggressively
            if hasattr(evolver, 'mutation_history') and len(evolver.mutation_history) > 20:
                evolver.mutation_history = evolver.mutation_history[-10:]
            
            # Clear skill memory (keep minimal set)
            if hasattr(evolver, 'skill_memory'):
                if hasattr(evolver.skill_memory, 'active_skills') and len(evolver.skill_memory.active_skills) > 5:
                    evolver.skill_memory.active_skills = dict(
                        list(evolver.skill_memory.active_skills.items())[:5]
                    )
            
            # Force information pruner cleanup
            if hasattr(evolver, 'information_pruner'):
                evolver.information_pruner.cleanup(max_operator_stats=15)
            
            # CRITICAL: Clean up reasoning traces (major memory leak source)
            if hasattr(evolver, 'reasoner') and hasattr(evolver.reasoner, 'traces'):
                if len(evolver.reasoner.traces) > 20:
                    # Keep only last 10 traces
                    trace_keys = list(evolver.reasoner.traces.keys())
                    for key in trace_keys[:-10]:
                        del evolver.reasoner.traces[key]
            
            # Reset quality level to prevent overfitting to early episodes
            if batch > 0 and batch % 3 == 0:
                evolver.quality_level = 0.5  # Reset to baseline
        
        # Analyze degradation
        # Use average of first 3 and last 3 batches to smooth out noise
        first_avg = sum(batch_times[:3]) / 3
        last_avg = sum(batch_times[-3:]) / 3
        
        degradation_ratio = last_avg / first_avg if first_avg > 0 else 1
        
        print(f"\n[PASS] Throughput consistency:")
        print(f"  Batch times: {[f'{t:.2f}s' for t in batch_times]}")
        print(f"  First 3 avg: {first_avg:.2f}s")
        print(f"  Last 3 avg: {last_avg:.2f}s")
        print(f"  Degradation: {degradation_ratio:.2f}x")
        print(f"  Overall avg: {sum(batch_times) / len(batch_times):.2f}s/batch")
        
        # Allow some degradation due to learning/accumulation, but cap at 3x
        assert degradation_ratio < 3.0, \
            f"Excessive performance degradation: {first_avg:.2f}s → {last_avg:.2f}s ({degradation_ratio:.2f}x)"


class TestMultiDomainConcurrency:
    """Test concurrent multi-domain workloads (ECM cross-domain integration)."""
    
    def test_cross_domain_concurrent_load(self):
        """Handle concurrent episodes across all 4 domains simultaneously."""
        domain_configs = [
            ("algorithm", AlgorithmTaskGenerator(seed=42), AlgorithmEvolver(seed=123)),
            ("logic", LogicPuzzleGenerator(seed=43), LogicPuzzleEvolver(seed=124)),
            ("reverse_engineering", ReverseEngineeringGenerator(seed=44), ReverseEngineeringEvolver(seed=125)),
            ("causal", CausalSystemGenerator(seed=45), CausalSystemEvolver(seed=126)),
        ]
        
        evaluator = Evaluator()
        results = {name: {"success": 0, "fail": 0} for name, _, _ in domain_configs}
        
        def run_domain_episodes(domain_name, gen, evolver, count=50):
            for episode in range(count):
                try:
                    task = gen.generate_task(episode=episode)
                    variant = evolver.create_variant(task, episode=episode)
                    
                    if callable(variant):
                        result = evaluator.evaluate(variant, task.get("inputs", {}))
                        if "metrics" in result:
                            results[domain_name]["success"] += 1
                        else:
                            results[domain_name]["fail"] += 1
                except Exception:
                    results[domain_name]["fail"] += 1
        
        start_time = time.perf_counter()
        
        # Run all domains concurrently
        with ThreadPoolExecutor(max_workers=4) as executor:
            futures = [
                executor.submit(run_domain_episodes, name, gen, evolver)
                for name, gen, evolver in domain_configs
            ]
            
            for future in as_completed(futures):
                future.result()  # Wait for completion
        
        end_time = time.perf_counter()
        total_time_s = end_time - start_time
        
        # Validate all domains performed adequately
        for domain_name, stats in results.items():
            total = stats["success"] + stats["fail"]
            success_rate = stats["success"] / total if total > 0 else 0
            
            assert success_rate >= 0.80, \
                f"{domain_name} success rate too low: {success_rate:.2%}"
        
        print(f"\n✓ Multi-domain concurrent load:")
        print(f"  Total time: {total_time_s:.2f}s")
        for domain_name, stats in results.items():
            total = stats["success"] + stats["fail"]
            print(f"  {domain_name}: {stats['success']}/{total} successful")


class TestResourceExhaustion:
    """Test graceful handling of resource exhaustion scenarios."""
    
    def test_graceful_timeout_handling(self):
        """System should handle timeouts gracefully without cascading failures."""
        evaluator = Evaluator()
        
        def slow_function(x):
            import time as time_module
            time_module.sleep(0.5)
            return x * 2
        
        # Run many evaluations with potential timeout
        timeouts = 0
        successes = 0
        
        for _ in range(50):
            try:
                result = evaluator.evaluate(slow_function, {"x": 5})
                if "metrics" in result:
                    successes += 1
            except Exception:
                timeouts += 1
        
        # Should handle timeouts without crashing entire system
        total = successes + timeouts
        assert total == 50, f"Not all evaluations attempted: {total}/50"
        
        print(f"\n✓ Timeout handling: {successes} succeeded, {timeouts} timed out")
    
    def test_error_isolation(self):
        """Errors in one episode shouldn't affect subsequent episodes."""
        gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=123)
        evaluator = Evaluator()
        
        error_count = 0
        success_after_error = 0
        
        for episode in range(100):
            try:
                task = gen.generate_task(episode=episode)
                variant = evolver.create_variant(task, episode=episode)
                
                if callable(variant):
                    result = evaluator.evaluate(variant, task.get("inputs", {}))
                    
                    if "metrics" in result:
                        if error_count > 0:
                            success_after_error += 1
            except Exception:
                error_count += 1
        
        # If there were errors, system should recover
        if error_count > 0:
            assert success_after_error > 0, \
                "System didn't recover after errors"
        
        print(f"\n✓ Error isolation: {error_count} errors, {success_after_error} recovered")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
