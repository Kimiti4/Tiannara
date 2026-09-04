"""Simple profiler - writes results to file."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
import time

output_file = Path("profile_results.txt")

task_gen = AlgorithmTaskGenerator(seed=42)
evolver = AlgorithmEvolver(seed=123)

with open(output_file, 'w', encoding='utf-8') as f:
    f.write("=" * 80 + "\n")
    f.write("MUTATION FUNCTION PROFILING RESULTS\n")
    f.write("=" * 80 + "\n\n")
    
    task_types_to_test = ["sorting", "arithmetic", "string_transform", "search", "optimization", "graph"]
    
    for task_type in task_types_to_test:
        f.write(f"\nTesting: {task_type.upper()}\n")
        f.write("-" * 80 + "\n")
        
        # Generate task
        task_gen.task_types = [task_type]
        task = task_gen.generate_task()
        
        f.write(f"Task: {task['description']}\n")
        
        # Time mutation creation
        start = time.time()
        try:
            solution_func = evolver.create_variant(task, 0)
            create_time = time.time() - start
            
            f.write(f"✅ Mutation created: {create_time:.4f}s\n")
            
            # Time execution
            exec_start = time.time()
            result = solution_func(**task["inputs"])
            exec_time = time.time() - exec_start
            
            f.write(f"✅ Execution: {exec_time:.4f}s\n")
            f.write(f"   Result type: {type(result)}\n")
            
            if create_time > 1.0 or exec_time > 1.0:
                f.write(f"   ⚠️  SLOW (>1 second)\n")
                
        except Exception as e:
            elapsed = time.time() - start
            f.write(f"❌ ERROR after {elapsed:.4f}s: {type(e).__name__}: {str(e)[:200]}\n")
        
        f.write("\n")
    
    f.write("\n" + "=" * 80 + "\n")
    f.write("Profiling complete!\n")
    f.write("=" * 80 + "\n")

print(f"Results written to {output_file}")
print("Reading results...")
with open(output_file) as f:
    print(f.read())
