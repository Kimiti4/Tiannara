"""Quick test to identify which task type causes hangs."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
import time

task_gen = AlgorithmTaskGenerator(seed=42)
evolver = AlgorithmEvolver(seed=123)

print("Testing each task type for performance issues...")
print("=" * 80)

for i in range(20):
    task = task_gen.generate_task()
    task_type = task["type"]
    
    start = time.time()
    try:
        solution_func = evolver.create_variant(task, i)
        elapsed = time.time() - start
        
        # Try executing it
        exec_start = time.time()
        result = solution_func(**task["inputs"])
        exec_elapsed = time.time() - exec_start
        
        status = "✓" if exec_elapsed < 1.0 else "⚠️ SLOW"
        print(f"{i+1:2d}. {task_type:20s} | Create: {elapsed:.3f}s | Exec: {exec_elapsed:.3f}s | {status}")
        
    except Exception as e:
        elapsed = time.time() - start
        print(f"{i+1:2d}. {task_type:20s} | ERROR after {elapsed:.3f}s: {e}")
    
    if elapsed > 5.0:
        print(f"\n❌ HANG DETECTED on task {i+1} ({task_type})")
        break

print("\n" + "=" * 80)
print("Test complete!")
