"""Profile mutation functions to find exact bottlenecks."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
import cProfile
import pstats
import io
import time

task_gen = AlgorithmTaskGenerator(seed=42)
evolver = AlgorithmEvolver(seed=123)

print("=" * 80)
print("MUTATION FUNCTION PROFILING")
print("=" * 80)
print()

# Test each task type separately
task_types_to_test = ["sorting", "arithmetic", "string_transform", "search", "optimization", "graph"]

for task_type in task_types_to_test:
    print(f"\n{'='*80}")
    print(f"Testing: {task_type.upper()}")
    print(f"{'='*80}")
    
    # Generate a task of this type
    task_gen.task_types = [task_type]
    task = task_gen.generate_task()
    
    print(f"Task: {task['description']}")
    print(f"Inputs: {list(task['inputs'].keys())}")
    print()
    
    # Profile mutation creation
    profiler = cProfile.Profile()
    profiler.enable()
    
    start_time = time.time()
    try:
        solution_func = evolver.create_variant(task, 0)
        create_elapsed = time.time() - start_time
        
        profiler.disable()
        
        print(f"✅ Mutation created successfully in {create_elapsed:.4f}s")
        
        # Profile execution
        exec_profiler = cProfile.Profile()
        exec_profiler.enable()
        
        exec_start = time.time()
        result = solution_func(**task["inputs"])
        exec_elapsed = time.time() - exec_start
        
        exec_profiler.disable()
        
        print(f"✅ Execution completed in {exec_elapsed:.4f}s")
        print(f"   Result: {result}")
        
        # Show profiling stats for creation
        if create_elapsed > 0.1:  # Only show if significant time
            print(f"\n📊 Creation Profile (top 10 functions):")
            stream = io.StringIO()
            ps = pstats.Stats(profiler, stream=stream)
            ps.sort_stats('cumulative')
            ps.print_stats(10)
            print(stream.getvalue())
        
        # Show profiling stats for execution
        if exec_elapsed > 0.1:  # Only show if significant time
            print(f"\n📊 Execution Profile (top 10 functions):")
            stream = io.StringIO()
            ps = pstats.Stats(exec_profiler, stream=stream)
            ps.sort_stats('cumulative')
            ps.print_stats(10)
            print(stream.getvalue())
        
    except Exception as e:
        profiler.disable()
        elapsed = time.time() - start_time
        print(f"❌ ERROR after {elapsed:.4f}s: {type(e).__name__}: {e}")
        
        # Show profile even on error
        print(f"\n📊 Profile up to error (top 10 functions):")
        stream = io.StringIO()
        ps = pstats.Stats(profiler, stream=stream)
        ps.sort_stats('cumulative')
        ps.print_stats(10)
        print(stream.getvalue())

print("\n" + "=" * 80)
print("Profiling complete!")
print("=" * 80)
