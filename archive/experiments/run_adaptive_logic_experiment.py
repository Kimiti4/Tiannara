"""Run experiment with adaptive difficulty on logic puzzle domain."""
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.logic_domain import LogicPuzzleGenerator
from tiannara_core.evaluation.logic_evolution_engine import LogicPuzzleEvolver
from tiannara_core.evaluation.evaluator import Evaluator
from tiannara_core.evaluation.causal_observer import CausalObserver
import json
import time
from datetime import datetime

def run_adaptive_logic_experiment(num_episodes=100):
    """Run experiment with adaptive difficulty scaling on logic puzzles."""
    
    # Initialize components
    task_gen = LogicPuzzleGenerator(seed=42)
    evolver = LogicPuzzleEvolver(seed=123)
    evaluator = Evaluator()
    causal = CausalObserver()
    
    print("=" * 80)
    print("ADAPTIVE DIFFICULTY EXPERIMENT - LOGIC PUZZLE DOMAIN")
    print("=" * 80)
    print(f"Episodes: {num_episodes}")
    print(f"Start Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Track results
    episode_results = []
    difficulty_distribution = {"easy": 0, "medium": 0, "hard": 0}
    success_by_difficulty = {"easy": [], "medium": [], "hard": []}
    
    start_time = time.time()
    
    for episode in range(1, num_episodes + 1):
        # Generate task with adaptive difficulty
        task = task_gen.generate_task(episode=episode)
        
        # Track difficulty distribution
        difficulty = task.get("difficulty", "easy")
        difficulty_distribution[difficulty] += 1
        
        # Create mutation
        solution_func = evolver.create_variant(task, episode=episode)
        
        # Evaluate
        result = evaluator.evaluate(solution_func, task)
        
        # Check success (correctness is in metrics sub-dict)
        correctness = result["metrics"]["correctness"]
        success = correctness > 0.9
        
        # Update task generator performance history
        task_gen.update_performance(success)
        
        # Track by difficulty
        success_by_difficulty[difficulty].append(1 if success else 0)
        
        # Log episode
        episode_data = {
            "episode": episode,
            "task_type": task["type"],
            "difficulty": difficulty,
            "success": success,
            "score": result["score"],
            "correctness": correctness,
            "timestamp": datetime.now().isoformat()
        }
        episode_results.append(episode_data)
        
        # Print progress every 10 episodes
        if episode % 10 == 0:
            elapsed = time.time() - start_time
            recent_success = sum(r["success"] for r in episode_results[-10:]) / 10 if len(episode_results) >= 10 else 0
            
            print(f"Episode {episode}/{num_episodes} | "
                  f"Difficulty: {difficulty} | "
                  f"Recent Success: {recent_success:.1%} | "
                  f"Time: {elapsed:.1f}s")
    
    total_elapsed = time.time() - start_time
    
    # Calculate statistics
    overall_success = sum(1 for r in episode_results if r["success"]) / len(episode_results)
    avg_score = sum(r["score"] for r in episode_results) / len(episode_results)
    
    print("\n" + "=" * 80)
    print("EXPERIMENT COMPLETE")
    print("=" * 80)
    print(f"Total Time: {total_elapsed:.2f}s")
    print(f"Overall Success Rate: {overall_success:.1%}")
    print(f"Average Intelligence Score: {avg_score:.4f}")
    print()
    
    # Difficulty breakdown
    print("DIFFICULTY DISTRIBUTION:")
    print("-" * 80)
    for diff in ["easy", "medium", "hard"]:
        count = difficulty_distribution[diff]
        if success_by_difficulty[diff]:
            success_rate = sum(success_by_difficulty[diff]) / len(success_by_difficulty[diff])
            print(f"  {diff.upper():8s}: {count:3d} tasks | Success Rate: {success_rate:.1%}")
        else:
            print(f"  {diff.upper():8s}: {count:3d} tasks | No data yet")
    print()
    
    # Save results
    output_file = Path("logic_adaptive_episodes.jsonl")
    with open(output_file, 'w', encoding='utf-8') as f:
        for result in episode_results:
            f.write(json.dumps(result) + "\n")
    
    print(f"Results saved to: {output_file}")
    print("=" * 80)
    
    return episode_results

if __name__ == "__main__":
    results = run_adaptive_logic_experiment(num_episodes=100)
