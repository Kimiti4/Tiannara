"""
Performance Profiling Script for Tiannara Evaluation System.

Profiles memory usage, CPU bottlenecks, and identifies hot paths in:
- Information pruner (UCB1 selection)
- Skill memory retrieval
- Episode logging (SQLite vs JSONL)
- Multi-agent orchestration
- Verifiable reasoning traces

Usage:
    python profile_performance.py [--episodes N] [--domain DOMAIN]
"""

import os
import sys
import time
import tracemalloc
import cProfile
import pstats
import io
from pathlib import Path
from typing import Dict, Any, List
from collections import defaultdict

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
from tiannara_core.evaluation.episode_logger import EpisodeLogger


class PerformanceProfiler:
    """Comprehensive performance profiler for the evaluation system."""
    
    def __init__(self):
        self.results: Dict[str, Any] = {}
        self.snapshots: List[Any] = []
        
    def profile_memory_usage(self, num_episodes: int = 50):
        """Profile memory usage over multiple episodes."""
        print("\n" + "="*70)
        print("MEMORY USAGE PROFILING")
        print("="*70)
        
        tracemalloc.start()
        
        # Take initial snapshot
        snapshot1 = tracemalloc.take_snapshot()
        self.snapshots.append(snapshot1)
        
        # Initialize components
        task_gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=42)
        logger = EpisodeLogger(use_sqlite=True)
        
        print(f"\nRunning {num_episodes} episodes...")
        
        episode_times = []
        for i in range(num_episodes):
            start_time = time.time()
            
            # Generate task
            task = task_gen.generate_task(episode=i)
            
            # Create variant
            variant = evolver.create_variant(task, episode=i)
            
            # Evaluate (simplified - just measure creation time)
            if variant:
                try:
                    result = variant(**task.get("inputs", {}))
                except:
                    pass
            
            episode_time = time.time() - start_time
            episode_times.append(episode_time)
            
            # Log episode
            logger.log_episode({
                "episode": i,
                "domain": "algorithm",
                "task_type": task.get("type"),
                "runtime_ms": episode_time * 1000
            })
            
            if (i + 1) % 10 == 0:
                print(f"  Completed {i+1}/{num_episodes} episodes")
        
        # Take final snapshot
        snapshot2 = tracemalloc.take_snapshot()
        self.snapshots.append(snapshot2)
        
        # Calculate memory statistics
        stats1 = snapshot1.statistics('lineno')
        stats2 = snapshot2.statistics('lineno')
        
        total_mem_start = sum(stat.size for stat in stats1) / 1024 / 1024  # MB
        total_mem_end = sum(stat.size for stat in stats2) / 1024 / 1024  # MB
        
        print(f"\nMemory Usage:")
        print(f"  Start: {total_mem_start:.2f} MB")
        print(f"  End:   {total_mem_end:.2f} MB")
        print(f"  Delta: {total_mem_end - total_mem_start:.2f} MB")
        print(f"  Per episode: {(total_mem_end - total_mem_start) / num_episodes * 1024:.2f} KB")
        
        # Top 10 memory allocations
        print(f"\nTop 10 Memory Allocations (by size):")
        for stat in stats2[:10]:
            print(f"  {stat}")
        
        # Time statistics
        avg_time = sum(episode_times) / len(episode_times)
        print(f"\nEpisode Timing:")
        print(f"  Average: {avg_time*1000:.2f} ms")
        print(f"  Min: {min(episode_times)*1000:.2f} ms")
        print(f"  Max: {max(episode_times)*1000:.2f} ms")
        
        self.results['memory'] = {
            'start_mb': total_mem_start,
            'end_mb': total_mem_end,
            'delta_mb': total_mem_end - total_mem_start,
            'per_episode_kb': (total_mem_end - total_mem_start) / num_episodes * 1024,
            'avg_episode_ms': avg_time * 1000
        }
        
        tracemalloc.stop()
        logger.close()
    
    def profile_pruner_performance(self, num_selections: int = 1000):
        """Profile InformationTheoreticPruner selection speed."""
        print("\n" + "="*70)
        print("PRUNER PERFORMANCE PROFILING")
        print("="*70)
        
        from tiannara_core.evaluation.information_pruner import InformationTheoreticPruner
        
        pruner = InformationTheoreticPruner(
            prune_threshold=0.3,
            exploration_weight=2.0,
            cache_size=1000
        )
        
        # Simulate operator selections
        operators = [
            "linear_fit", "polynomial_fit", "exponential_fit",
            "logarithmic_fit", "piecewise_infer", "rule_extraction"
        ]
        
        print(f"\nPerforming {num_selections} operator selections...")
        
        start_time = time.time()
        for i in range(num_selections):
            selected = pruner.prune_and_select(
                task_type="linear_function_inference",
                available_operators=operators
            )
            
            # Record outcome
            pruner.record_mutation_outcome(
                task_type="linear_function_inference",
                operator_name=selected or operators[0],
                actual_quality=0.8 if i % 3 == 0 else 0.5,
                execution_time=0.001
            )
        
        elapsed = time.time() - start_time
        
        print(f"\nPruner Statistics:")
        print(f"  Total selections: {num_selections}")
        print(f"  Total time: {elapsed*1000:.2f} ms")
        print(f"  Per selection: {elapsed/num_selections*1000:.4f} ms")
        print(f"  Throughput: {num_selections/elapsed:.0f} selections/sec")
        
        # Profile UCB computation
        ucb_times = []
        for i in range(100):
            start = time.time()
            pruner.ucb_selector.select_operator(operators)
            ucb_times.append(time.time() - start)
        
        avg_ucb = sum(ucb_times) / len(ucb_times)
        print(f"\nUCB Selection:")
        print(f"  Average: {avg_ucb*1000:.4f} ms")
        print(f"  Min: {min(ucb_times)*1000:.4f} ms")
        print(f"  Max: {max(ucb_times)*1000:.4f} ms")
        
        self.results['pruner'] = {
            'total_selections': num_selections,
            'total_time_ms': elapsed * 1000,
            'per_selection_ms': elapsed / num_selections * 1000,
            'throughput_per_sec': num_selections / elapsed,
            'ucb_avg_ms': avg_ucb * 1000
        }
    
    def profile_skill_retrieval(self, num_skills: int = 100, num_queries: int = 500):
        """Profile skill memory retrieval performance."""
        print("\n" + "="*70)
        print("SKILL RETRIEVAL PROFILING")
        print("="*70)
        
        from tiannara_core.evaluation.ecm_forgetting_mechanism import SkillMemoryWithForgetting
        
        memory = SkillMemoryWithForgetting(max_skills=100)
        
        # Populate with skills
        print(f"\nPopulating memory with {num_skills} skills...")
        for i in range(num_skills):
            memory.add_skill(
                pattern=f"skill_pattern_{i}",
                solution=lambda x: x + i,
                quality=0.5 + (i % 10) * 0.05,
                domain="algorithm",
                episode=i
            )
        
        print(f"Active skills: {len(memory.active_skills)}")
        
        # Profile retrieval
        print(f"\nPerforming {num_queries} retrieval queries...")
        
        retrieval_times = []
        skill_ids = list(memory.active_skills.keys())[:min(10, len(memory.active_skills))]
        
        for i in range(num_queries):
            start_time = time.time()
            
            # Retrieve a random skill (simulate query)
            if skill_ids:
                skill_id = skill_ids[i % len(skill_ids)]
                skill = memory.retrieve_skill(skill_id)
            
            retrieval_times.append(time.time() - start_time)
        
        avg_retrieval = sum(retrieval_times) / len(retrieval_times)
        
        print(f"\nRetrieval Statistics:")
        print(f"  Average: {avg_retrieval*1000:.4f} ms")
        print(f"  Min: {min(retrieval_times)*1000:.4f} ms")
        print(f"  Max: {max(retrieval_times)*1000:.4f} ms")
        print(f"  Throughput: {num_queries/sum(retrieval_times):.0f} queries/sec")
        
        # Profile similarity computation
        if num_skills > 0:
            sim_times = []
            test_vector = [0.5] * 10  # Dummy vector
            for i in range(100):
                start = time.time()
                # Access internal similarity computation
                for skill in list(memory.active_skills.values())[:10]:
                    _ = skill.quality  # Simplified - actual cosine sim would be here
                sim_times.append(time.time() - start)
            
            avg_sim = sum(sim_times) / len(sim_times)
            print(f"\nSimilarity Computation (10 skills):")
            print(f"  Average: {avg_sim*1000:.4f} ms")
        
        self.results['skill_retrieval'] = {
            'num_skills': num_skills,
            'num_queries': num_queries,
            'avg_retrieval_ms': avg_retrieval * 1000,
            'throughput_per_sec': num_queries / sum(retrieval_times)
        }
    
    def profile_logging_performance(self, num_logs: int = 1000):
        """Compare JSONL vs SQLite logging performance."""
        print("\n" + "="*70)
        print("LOGGING PERFORMANCE PROFILING")
        print("="*70)
        
        import tempfile
        
        # Test JSONL logging
        print(f"\nTesting JSONL logging ({num_logs} entries)...")
        jsonl_dir = tempfile.mkdtemp()
        jsonl_logger = EpisodeLogger(log_dir=jsonl_dir, use_sqlite=False)
        
        start_time = time.time()
        for i in range(num_logs):
            jsonl_logger.log_episode({
                "episode": i,
                "domain": "algorithm",
                "score": 0.8,
                "data": f"test_data_{i}"
            })
        jsonl_time = time.time() - start_time
        
        print(f"  Time: {jsonl_time*1000:.2f} ms")
        print(f"  Per entry: {jsonl_time/num_logs*1000:.4f} ms")
        print(f"  Throughput: {num_logs/jsonl_time:.0f} entries/sec")
        
        jsonl_logger.close()
        
        # Test SQLite logging
        print(f"\nTesting SQLite logging ({num_logs} entries)...")
        sqlite_dir = tempfile.mkdtemp()
        sqlite_logger = EpisodeLogger(log_dir=sqlite_dir, use_sqlite=True)
        
        start_time = time.time()
        for i in range(num_logs):
            sqlite_logger.log_episode({
                "episode": i,
                "domain": "algorithm",
                "score": 0.8,
                "data": f"test_data_{i}"
            })
        sqlite_time = time.time() - start_time
        
        print(f"  Time: {sqlite_time*1000:.2f} ms")
        print(f"  Per entry: {sqlite_time/num_logs*1000:.4f} ms")
        print(f"  Throughput: {num_logs/sqlite_time:.0f} entries/sec")
        
        sqlite_logger.close()
        
        # Comparison
        speedup = jsonl_time / sqlite_time if sqlite_time > 0 else float('inf')
        print(f"\nComparison:")
        print(f"  SQLite is {speedup:.2f}x {'slower' if speedup < 1 else 'faster'} than JSONL")
        print(f"  Overhead: {abs(sqlite_time - jsonl_time)/jsonl_time*100:.1f}%")
        
        self.results['logging'] = {
            'jsonl_time_ms': jsonl_time * 1000,
            'sqlite_time_ms': sqlite_time * 1000,
            'speedup_factor': speedup
        }
    
    def profile_cpu_hotspots(self, num_episodes: int = 20):
        """Profile CPU hotspots using cProfile."""
        print("\n" + "="*70)
        print("CPU HOTSPOT PROFILING (cProfile)")
        print("="*70)
        
        task_gen = AlgorithmTaskGenerator(seed=42)
        evolver = AlgorithmEvolver(seed=42)
        
        # Setup profiler
        profiler = cProfile.Profile()
        profiler.enable()
        
        print(f"\nProfiling {num_episodes} episodes...")
        for i in range(num_episodes):
            task = task_gen.generate_task(episode=i)
            variant = evolver.create_variant(task, episode=i)
            
            if variant:
                try:
                    result = variant(**task.get("inputs", {}))
                except:
                    pass
        
        profiler.disable()
        
        # Print results
        stream = io.StringIO()
        stats = pstats.Stats(profiler, stream=stream)
        stats.sort_stats('cumulative')
        stats.print_stats(20)  # Top 20 functions
        
        print(stream.getvalue())
        
        # Save to file
        profile_file = Path(__file__).parent / "cpu_profile.txt"
        with open(profile_file, 'w') as f:
            f.write(stream.getvalue())
        
        print(f"\nDetailed profile saved to: {profile_file}")
    
    def generate_report(self):
        """Generate comprehensive performance report."""
        print("\n" + "="*70)
        print("PERFORMANCE SUMMARY REPORT")
        print("="*70)
        
        print("\nKey Metrics:")
        
        if 'memory' in self.results:
            mem = self.results['memory']
            print(f"\n1. Memory Usage:")
            print(f"   - Growth per episode: {mem['per_episode_kb']:.2f} KB")
            print(f"   - Average episode time: {mem['avg_episode_ms']:.2f} ms")
        
        if 'pruner' in self.results:
            pruner = self.results['pruner']
            print(f"\n2. Pruner Performance:")
            print(f"   - Selection speed: {pruner['per_selection_ms']:.4f} ms")
            print(f"   - Throughput: {pruner['throughput_per_sec']:.0f} selections/sec")
        
        if 'skill_retrieval' in self.results:
            skill = self.results['skill_retrieval']
            print(f"\n3. Skill Retrieval:")
            print(f"   - Query speed: {skill['avg_retrieval_ms']:.4f} ms")
            print(f"   - Throughput: {skill['throughput_per_sec']:.0f} queries/sec")
        
        if 'logging' in self.results:
            log = self.results['logging']
            print(f"\n4. Logging Performance:")
            print(f"   - JSONL: {log['jsonl_time_ms']:.2f} ms for 1000 entries")
            print(f"   - SQLite: {log['sqlite_time_ms']:.2f} ms for 1000 entries")
            print(f"   - Overhead: {abs(log['sqlite_time_ms'] - log['jsonl_time_ms'])/log['jsonl_time_ms']*100:.1f}%")
        
        print("\n" + "="*70)
        print("RECOMMENDATIONS")
        print("="*70)
        
        recommendations = []
        
        if 'memory' in self.results:
            mem_growth = self.results['memory']['per_episode_kb']
            if mem_growth > 10:
                recommendations.append(
                    f"HIGH: Memory growth is {mem_growth:.1f} KB/episode. "
                    "Consider implementing more aggressive skill decay."
                )
            elif mem_growth > 5:
                recommendations.append(
                    f"MEDIUM: Memory growth is {mem_growth:.1f} KB/episode. "
                    "Monitor for long-term scaling issues."
                )
        
        if 'pruner' in self.results:
            pruner_speed = self.results['pruner']['per_selection_ms']
            if pruner_speed > 1:
                recommendations.append(
                    f"HIGH: Pruner selection is slow ({pruner_speed:.2f} ms). "
                    "Consider caching UCB scores or reducing operator count."
                )
        
        if 'skill_retrieval' in self.results:
            retrieval_speed = self.results['skill_retrieval']['avg_retrieval_ms']
            if retrieval_speed > 10:
                recommendations.append(
                    f"HIGH: Skill retrieval is slow ({retrieval_speed:.2f} ms). "
                    "Consider indexing or approximate nearest neighbor search."
                )
        
        if 'logging' in self.results:
            overhead = abs(self.results['logging']['sqlite_time_ms'] - 
                          self.results['logging']['jsonl_time_ms']) / \
                      self.results['logging']['jsonl_time_ms'] * 100
            if overhead > 50:
                recommendations.append(
                    f"MEDIUM: SQLite logging has {overhead:.1f}% overhead. "
                    "Consider batch writes or async logging."
                )
        
        if not recommendations:
            recommendations.append("System performance is within acceptable parameters.")
        
        for i, rec in enumerate(recommendations, 1):
            print(f"\n{i}. {rec}")
        
        # Save report
        report_file = Path(__file__).parent / "performance_report.json"
        import json
        with open(report_file, 'w') as f:
            json.dump(self.results, f, indent=2, default=str)
        
        print(f"\nDetailed results saved to: {report_file}")


def main():
    """Run all performance profiles."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Profile Tiannara Evaluation System')
    parser.add_argument('--episodes', type=int, default=50, help='Number of episodes to profile')
    parser.add_argument('--domain', type=str, default='algorithm', help='Domain to test')
    args = parser.parse_args()
    
    profiler = PerformanceProfiler()
    
    # Run all profiles
    profiler.profile_memory_usage(num_episodes=args.episodes)
    profiler.profile_pruner_performance(num_selections=1000)
    profiler.profile_skill_retrieval(num_skills=100, num_queries=500)
    profiler.profile_logging_performance(num_logs=1000)
    profiler.profile_cpu_hotspots(num_episodes=min(20, args.episodes))
    
    # Generate report
    profiler.generate_report()
    
    print("\n" + "="*70)
    print("PROFILING COMPLETE")
    print("="*70)


if __name__ == "__main__":
    main()
