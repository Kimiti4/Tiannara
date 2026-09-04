"""Run experiment on hybrid domain to test cross-domain transfer."""
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.hybrid_domain import HybridTaskGenerator
from tiannara_core.evaluation.hybrid_evolution_engine import HybridEvolver
from tiannara_core.evaluation.evaluator import Evaluator
import json
import time
from datetime import datetime

def run_hybrid_experiment(num_episodes=100):
    """Run experiment on hybrid domain (algorithm + logic)."""
    
    # Initialize components
    task_gen = HybridTaskGenerator(seed=42)
    evolver = HybridEvolver(seed=123)
    evaluator = Evaluator()
    
    print("=" * 80)
    print("HYBRID DOMAIN EXPERIMENT - CROSS-DOMAIN TRANSFER TEST")
    print("=" * 80)
    print(f"Episodes: {num_episodes}")
    print(f"Domain Mix: 50% Algorithm, 50% Logic")
    print(f"Start Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Track results
    episode_results = []
    domain_stats = {
        "algorithm": {"count": 0, "successes": 0, "scores": []},
        "logic": {"count": 0, "successes": 0, "scores": []}
    }
    difficulty_distribution = {"easy": 0, "medium": 0, "hard": 0}
    
    start_time = time.time()
    
    for episode in range(1, num_episodes + 1):
        # Generate hybrid task
        task = task_gen.generate_task(episode=episode)
        
        # Track domain and difficulty
        source = task["source_domain"]
        difficulty = task.get("difficulty", "easy")
        domain_stats[source]["count"] += 1
        difficulty_distribution[difficulty] += 1
        
        # Create mutation using hybrid evolver
        solution_func = evolver.create_variant(task, episode=episode)
        
        # Evaluate
        result = evaluator.evaluate(solution_func, task)
        
        # Check success
        correctness = result["metrics"]["correctness"]
        success = correctness > 0.9
        
        # Update performance tracking
        task_gen.update_performance(success)
        
        # Track by domain
        if success:
            domain_stats[source]["successes"] += 1
        domain_stats[source]["scores"].append(result["score"])
        
        # Log episode
        episode_data = {
            "episode": episode,
            "source_domain": source,
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
            recent_success = sum(r["success"] for r in episode_results[-10:]) / 10
            
            algo_count = sum(1 for r in episode_results[-10:] if r["source_domain"] == "algorithm")
            logic_count = 10 - algo_count
            
            print(f"Episode {episode}/{num_episodes} | "
                  f"Recent Success: {recent_success:.1%} | "
                  f"Algo: {algo_count}, Logic: {logic_count} | "
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
    
    # Domain breakdown
    print("DOMAIN BREAKDOWN:")
    print("-" * 80)
    for domain in ["algorithm", "logic"]:
        stats = domain_stats[domain]
        count = stats["count"]
        successes = stats["successes"]
        success_rate = successes / count if count > 0 else 0
        avg_domain_score = sum(stats["scores"]) / len(stats["scores"]) if stats["scores"] else 0
        
        print(f"  {domain.upper():12s}: {count:3d} tasks | Success Rate: {success_rate:.1%} | Avg Score: {avg_domain_score:.4f}")
    print()
    
    # Difficulty breakdown
    print("DIFFICULTY DISTRIBUTION:")
    print("-" * 80)
    for diff in ["easy", "medium", "hard"]:
        count = difficulty_distribution[diff]
        diff_successes = sum(1 for r in episode_results if r["difficulty"] == diff and r["success"])
        diff_rate = diff_successes / count if count > 0 else 0
        print(f"  {diff.upper():8s}: {count:3d} tasks | Success Rate: {diff_rate:.1%}")
    print()
    
    # Cross-domain transfer analysis
    print("CROSS-DOMAIN TRANSFER ANALYSIS:")
    print("-" * 80)
    
    # Compare first half vs second half performance by domain
    first_half = episode_results[:50]
    second_half = episode_results[50:]
    
    for domain in ["algorithm", "logic"]:
        first_domain = [r for r in first_half if r["source_domain"] == domain]
        second_domain = [r for r in second_half if r["source_domain"] == domain]
        
        if first_domain and second_domain:
            first_rate = sum(1 for r in first_domain if r["success"]) / len(first_domain)
            second_rate = sum(1 for r in second_domain if r["success"]) / len(second_domain)
            improvement = second_rate - first_rate
            
            print(f"  {domain.upper()} Tasks:")
            print(f"    First 50 episodes:  {first_rate:.1%} success")
            print(f"    Second 50 episodes: {second_rate:.1%} success")
            print(f"    Improvement: {improvement:+.1%} {'UP' if improvement > 0 else 'DOWN'}")
            print()
    
    # Save results
    output_file = Path("hybrid_adaptive_episodes.jsonl")
    with open(output_file, 'w', encoding='utf-8') as f:
        for result in episode_results:
            f.write(json.dumps(result) + "\n")
    
    print(f"Results saved to: {output_file}")
    print("=" * 80)
    
    return episode_results

if __name__ == "__main__":
    results = run_hybrid_experiment(num_episodes=100)
