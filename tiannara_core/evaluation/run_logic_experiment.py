"""Run experiment on Logic Puzzle domain."""
import sys
sys.path.insert(0, 'c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic')

from tiannara_core.evaluation.logic_domain import LogicPuzzleGenerator
from tiannara_core.evaluation.logic_evolution_engine import LogicPuzzleEvolver
from tiannara_core.evaluation.evaluator import Evaluator
from tiannara_core.evaluation.episode_logger import EpisodeLogger
from tiannara_core.evaluation.causal_observer import CausalObserver

def run_logic_experiment(num_episodes=100):
    """Run 100 episodes on logic puzzle domain."""
    
    # Initialize components
    task_gen = LogicPuzzleGenerator(seed=42)
    evolver = LogicPuzzleEvolver(seed=42)
    evaluator = Evaluator()
    logger = EpisodeLogger("tiannara_core/logs/logic_puzzle_episodes.jsonl")
    causal = CausalObserver()
    
    print("=" * 80)
    print("LOGIC PUZZLE DOMAIN EXPERIMENT")
    print("=" * 80)
    print(f"\nConfiguration:")
    print(f"  Episodes: {num_episodes}")
    print(f"  Domain: Logic Puzzles (pattern, boolean, sequence, deduction)")
    print(f"  Seed: 42")
    print(f"\nStarting experiment...\n")
    
    scores = []
    successes = 0
    
    for episode in range(num_episodes):
        # Generate task
        task = task_gen.generate_task()
        
        # Create solution variant
        solution_func = evolver.create_variant(task, episode)
        
        # Evaluate
        evaluation = evaluator.evaluate(solution_func, task["inputs"], runs=5)
        score = evaluation["score"]
        metrics = evaluation["metrics"]
        
        # Verify solution
        try:
            result = solution_func(**task["inputs"])
            success = task_gen.verify_solution(task, result.get("output"))
        except:
            success = False
        
        if success:
            successes += 1
        
        # Update evolution
        evolver.update_from_score(score, metrics["correctness"], solution_func)
        
        # Track causality
        causal.observe(episode, metrics, score, task["type"], success)
        
        # Log
        log_entry = {
            "episode": episode,
            "task_type": task["type"],
            "task_description": task["description"],
            "inputs": task["inputs"],
            "expected_output": task["expected_output"],
            "score": score,
            "metrics": metrics,
            "success": success,
            "mutation_quality": evolver.quality_level,
            "num_runs": 5,
        }
        logger.log_episode(log_entry)
        
        scores.append(score)
        
        # Progress reporting
        if (episode + 1) % 10 == 0 or episode == 0:
            avg_score = sum(scores) / len(scores)
            print(f"Episode {episode+1}/{num_episodes}: "
                  f"task={task['type']:25s} "
                  f"score={score:.3f} "
                  f"correctness={metrics['correctness']:.2f} "
                  f"quality={evolver.quality_level:.2f} "
                  f"success={'✓' if success else '✗'}")
    
    # Final analysis
    print("\n" + "=" * 80)
    print("EXPERIMENT COMPLETE - RESULTS")
    print("=" * 80)
    
    avg_score = sum(scores) / len(scores)
    best_score = max(scores)
    worst_score = min(scores)
    success_rate = successes / num_episodes * 100
    
    print(f"\n📊 OVERALL RESULTS")
    print(f"  Total Episodes: {num_episodes}")
    print(f"  Average Score: {avg_score:.4f}")
    print(f"  Best Score: {best_score:.4f}")
    print(f"  Worst Score: {worst_score:.4f}")
    print(f"  Success Rate: {success_rate:.1f}% ({successes}/{num_episodes})")
    
    print(f"\n🧬 EVOLUTION RESULTS")
    print(f"  Final Quality: {evolver.quality_level:.2f}")
    print(f"  Skills Stored: {len(evolver.skill_library)}")
    print(f"  Mode: {evolver.mode}")
    
    # Task type breakdown
    print(f"\n📈 PERFORMANCE BY TASK TYPE")
    task_stats = {}
    with open('tiannara_core/logs/logic_puzzle_episodes.jsonl') as f:
        import json
        for line in f:
            data = json.loads(line)
            ttype = data['task_type']
            if ttype not in task_stats:
                task_stats[ttype] = {'scores': [], 'success': 0, 'total': 0}
            task_stats[ttype]['scores'].append(data['score'])
            task_stats[ttype]['total'] += 1
            if data['success']:
                task_stats[ttype]['success'] += 1
    
    for ttype, stats in sorted(task_stats.items()):
        avg = sum(stats['scores']) / len(stats['scores'])
        sr = stats['success'] / stats['total'] * 100
        print(f"  {ttype:25s}: avg_score={avg:.4f} success_rate={sr:.1f}% (n={stats['total']})")
    
    # Causal insights
    print(f"\n🔬 CAUSAL INSIGHTS")
    correlations = causal.get_correlations()
    for metric, corr in correlations.items():
        direction = "+" if corr >= 0 else ""
        print(f"  {metric:20s}: r={direction}{corr:.3f}")
    
    print(f"\n💾 LOG FILE")
    print(f"  tiannara_core/logs/logic_puzzle_episodes.jsonl")
    print(f"  Episodes logged: {num_episodes}")
    
    print("\n" + "=" * 80)
    print("✅ Logic puzzle experiment completed!")
    print("=" * 80)

if __name__ == "__main__":
    run_logic_experiment(100)
