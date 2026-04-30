"""Debug script to test mutation engine directly."""
import sys
sys.path.insert(0, 'c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic')

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
from tiannara_core.evaluation.evaluator import Evaluator

# Create instances
task_gen = AlgorithmTaskGenerator(seed=42)
evolver = AlgorithmEvolver(seed=42+12345)
evaluator = Evaluator()

print("Testing mutation engine with hybrid fixes...\n")

# Generate a task and mutate it
for i in range(5):
    task = task_gen.generate_task()
    solution_func = evolver.create_variant(task, episode=i)
    
    # Run the solution multiple times
    results = []
    for run in range(5):
        result = solution_func()
        results.append(result)
    
    # Evaluate
    evaluation = evaluator.evaluate(solution_func, task["inputs"], runs=5)
    
    print(f"Episode {i}: Task={task['type']}")
    print(f"  Correctness: {evaluation['metrics']['correctness']:.2f}")
    print(f"  Score: {evaluation['score']:.3f}")
    print(f"  Quality: {evolver.quality_level:.2f}")
    print(f"  Results: {[r.get('success', False) for r in results]}")
    print()
