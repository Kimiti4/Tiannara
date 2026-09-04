"""Run refined experiment with enhanced algorithm domain (6 task types)."""
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
from tiannara_core.evaluation.evaluator import Evaluator
from tiannara_core.evaluation.causal_observer import CausalObserver
import json
import time
from datetime import datetime

def run_refined_experiment(num_episodes=100):
    """Run experiment with refined algorithm domain."""
    
    # Initialize components
    task_gen = AlgorithmTaskGenerator(seed=42)
    evolver = AlgorithmEvolver(seed=123)  # Quality is set internally to 0.85
    evaluator = Evaluator()
    causal = CausalObserver()
    
    print("=" * 80)
    print("REFINED ALGORITHM DOMAIN EXPERIMENT")
    print("=" * 80)
    print(f"Task Types: {task_gen.task_types}")
    print(f"Episodes: {num_episodes}")
    print(f"Starting Quality: {evolver.quality_level:.2f}")
    print("=" * 80)
    
    # Open log file
    log_path = Path(__file__).parent / "logs" / "refined_algorithm_episodes.jsonl"
    log_path.parent.mkdir(exist_ok=True)
    
    scores = []
    successes = []
    task_type_stats = {}
    
    start_time = time.time()
    
    for episode in range(num_episodes):
        # Generate task
        task = task_gen.generate_task()
        
        # Create variant
        solution_func = evolver.create_variant(task, episode)
        
        # Evaluate
        evaluation = evaluator.evaluate(solution_func, task["inputs"], runs=5)
        
        score = evaluation["score"]
        metrics = evaluation["metrics"]
        
        # Verify solution
        try:
            result = solution_func(**task["inputs"])
            success = task_gen.verify_solution(task, result.get("output"))
        except Exception as e:
            success = False
        
        # Update evolver
        evolver.update_from_score(score, metrics["correctness"], solution_func)
        
        # Observe causally
        causal.observe(episode, metrics, score, task["type"], success)
        
        # Log
        log_entry = {
            "episode": episode,
            "timestamp": datetime.now().isoformat(),
            "task_type": task["type"],
            "score": round(score, 4),
            "metrics": {k: round(v, 4) for k, v in metrics.items()},
            "quality": round(evolver.quality_level, 4),
            "mode": evolver.mode,
            "success": success,
            "skills_stored": len(evolver.skill_library),
            "description": task["description"]
        }
        
        with open(log_path, 'a') as f:
            f.write(json.dumps(log_entry) + '\n')
        
        scores.append(score)
        successes.append(success)
        
        # Track task type stats
        task_type = task["type"]
        if task_type not in task_type_stats:
            task_type_stats[task_type] = {"count": 0, "scores": [], "successes": 0}
        task_type_stats[task_type]["count"] += 1
        task_type_stats[task_type]["scores"].append(score)
        if success:
            task_type_stats[task_type]["successes"] += 1
        
        # Progress
        if (episode + 1) % 10 == 0 or episode == 0:
            avg_score = sum(scores[-10:]) / min(len(scores), 10)
            recent_success = sum(successes[-10:]) / min(len(successes), 10)
            print(f"Episode {episode+1:3d}/{num_episodes}: "
                  f"Avg Score={avg_score:.3f}, Success={recent_success:.0%}, "
                  f"Quality={evolver.quality_level:.2f}, Mode={evolver.mode}, "
                  f"Skills={len(evolver.skill_library)}")
    
    elapsed = time.time() - start_time
    
    # Final analysis
    print("\n" + "=" * 80)
    print("FINAL RESULTS - REFINED ALGORITHM DOMAIN")
    print("=" * 80)
    print(f"Total Episodes: {num_episodes}")
    print(f"Average Score: {sum(scores)/len(scores):.4f}")
    print(f"Success Rate: {sum(successes)}/{num_episodes} = {sum(successes)/num_episodes*100:.1f}%")
    print(f"Final Quality: {evolver.quality_level:.2f}")
    print(f"Final Mode: {evolver.mode}")
    print(f"Skills Stored: {len(evolver.skill_library)}")
    print(f"Time Elapsed: {elapsed:.1f}s")
    
    print("\n" + "-" * 80)
    print("TASK TYPE BREAKDOWN:")
    print("-" * 80)
    for task_type, stats in sorted(task_type_stats.items()):
        avg_score = sum(stats["scores"]) / len(stats["scores"])
        success_rate = stats["successes"] / stats["count"] * 100
        print(f"{task_type:20s}: {stats['count']:3d} episodes, "
              f"Avg Score={avg_score:.3f}, Success={success_rate:.1f}%")
    
    print("\n" + "-" * 80)
    print("CAUSAL OBSERVATIONS:")
    print("-" * 80)
    obs = causal.observations
    if obs:
        latest = obs[-1]
        print(f"Latest correlations (episode {latest['episode']}):")
        for metric, corr in latest['correlations'].items():
            print(f"  {metric:20s}: {corr:+.3f}")
    
    print("\n" + "=" * 80)
    print("Experiment complete! Logs saved to:", log_path)
    print("=" * 80)

if __name__ == "__main__":
    run_refined_experiment()
