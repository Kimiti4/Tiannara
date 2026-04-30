"""Debug arithmetic and search mutations directly."""
import sys
sys.path.insert(0, 'c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic')

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
from tiannara_core.evaluation.evaluator import Evaluator

# Create instances
task_gen = AlgorithmTaskGenerator(seed=42)
evolver = AlgorithmEvolver(seed=42+12345)
evaluator = Evaluator()

print("Testing arithmetic and search mutations...\n")

# Test arithmetic tasks
print("=" * 80)
print("ARITHMETIC TASKS")
print("=" * 80)

for i in range(5):
    # Generate tasks until we get an arithmetic one
    while True:
        task = task_gen.generate_task()
        if task['type'] == 'arithmetic':
            break
    
    solution_func = evolver.create_variant(task, episode=i)
    
    # Run the solution multiple times
    results = []
    for run in range(5):
        try:
            result = solution_func(**task["inputs"])
            results.append(result)
        except Exception as e:
            results.append({"error": str(e), "success": False})
    
    # Evaluate
    evaluation = evaluator.evaluate(solution_func, task["inputs"], runs=5)
    
    print(f"\nEpisode {i}: Task={task['type']}")
    print(f"  Operation: {task['inputs']['operation']}")
    print(f"  Numbers: {task['inputs']['numbers']}")
    print(f"  Expected: {task['expected_output']}")
    print(f"  Correctness: {evaluation['metrics']['correctness']:.2f}")
    print(f"  Score: {evaluation['score']:.3f}")
    print(f"  Quality: {evolver.quality_level:.2f}")
    print(f"  Results: {[(r.get('output', 'ERROR'), r.get('success', False)) for r in results]}")

# Test search tasks
print("\n" + "=" * 80)
print("SEARCH TASKS")
print("=" * 80)

for i in range(5):
    # Generate tasks until we get a search one
    while True:
        task = task_gen.generate_task()
        if task['type'] == 'search':
            break
    
    solution_func = evolver.create_variant(task, episode=i+5)
    
    # Run the solution multiple times
    results = []
    for run in range(5):
        try:
            result = solution_func(**task["inputs"])
            results.append(result)
        except Exception as e:
            results.append({"error": str(e), "success": False})
    
    # Evaluate
    evaluation = evaluator.evaluate(solution_func, task["inputs"], runs=5)
    
    print(f"\nEpisode {i+5}: Task={task['type']}")
    print(f"  Data length: {len(task['inputs']['data'])}")
    print(f"  Target: {task['inputs']['target']}")
    print(f"  Expected: {task['expected_output']}")
    print(f"  Correctness: {evaluation['metrics']['correctness']:.2f}")
    print(f"  Score: {evaluation['score']:.3f}")
    print(f"  Quality: {evolver.quality_level:.2f}")
    print(f"  Results: {[(r.get('output', 'ERROR'), r.get('success', False)) for r in results]}")
