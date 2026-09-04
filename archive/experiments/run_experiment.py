"""
Main Experiment Runner - 100 Episode Algorithm Domain Test.

Runs complete evaluation loop with:
- Algorithm task generation
- Evolution/mutation engine
- Evaluator system
- Causal observation
- Full logging
- Feedback loops
- Progress monitoring
"""

import sys
import os
import time

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from tiannara_core.evaluation import Evaluator
from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
from tiannara_core.evaluation.causal_observer import CausalObserver
from tiannara_core.evaluation.episode_logger import EpisodeLogger


def run_experiment(num_episodes: int = 100, seed: int = 42):
    """
    Run complete evaluation experiment on algorithm domain.
    
    Args:
        num_episodes: Number of episodes to run (default: 100)
        seed: Random seed for reproducibility
    """
    print("=" * 80)
    print("ADVANCED EVALUATION SYSTEM - ALGORITHM DOMAIN EXPERIMENT")
    print("=" * 80)
    print(f"\nConfiguration:")
    print(f"  Episodes: {num_episodes}")
    print(f"  Domain: Algorithm Tasks (sorting, arithmetic, string, search)")
    print(f"  Seed: {seed}")
    print(f"  Logging: JSONL format")
    print(f"  Feedback Loops: Evolution + Causal\n")
    print("=" * 80)
    
    # Initialize all components
    evaluator = Evaluator()
    task_generator = AlgorithmTaskGenerator(seed=seed)
    evolver = AlgorithmEvolver(seed=seed)
    causal_observer = CausalObserver()
    logger = EpisodeLogger()
    
    # Clear previous logs
    logger.clear_logs()
    
    print("\nStarting experiment...\n")
    start_time = time.time()
    
    scores_history = []
    
    for episode in range(num_episodes):
        # FIX 5: Phase-based adaptive weights
        if episode < 30:
            # Phase 1: Exploration
            evaluator.update_weights({
                "correctness": 0.20,
                "efficiency": 0.10,
                "stability": 0.20,
                "novelty": 0.40,
                "error_penalty": 0.10,
            })
        elif episode < 70:
            # Phase 2: Learning
            evaluator.update_weights({
                "correctness": 0.40,
                "efficiency": 0.15,
                "stability": 0.30,
                "novelty": 0.10,
                "error_penalty": 0.05,
            })
        else:
            # Phase 3: Mastery
            evaluator.update_weights({
                "correctness": 0.60,
                "efficiency": 0.20,
                "stability": 0.20,
                "novelty": 0.00,
                "error_penalty": 0.00,
            })
        
        # STEP 1: Generate task
        task = task_generator.generate_task()
        
        # STEP 2: Create mutated variant (evolution)
        solution_func = evolver.create_variant(task, episode)
        
        # STEP 3: Execute and evaluate
        try:
            # Option D: Use 5 runs per episode for more reliable correctness measurement
            evaluation = evaluator.evaluate(solution_func, task["inputs"], runs=5)
            
            score = evaluation["score"]
            metrics = evaluation["metrics"]
            outputs = evaluation["outputs"]
            
            # Determine if solution was correct
            # Check first output for correctness
            first_output = outputs[0] if outputs else {}
            actual_output = first_output.get("output")
            success = task_generator.verify_solution(task, actual_output) if actual_output is not None else False
            
        except Exception as e:
            # Handle evaluation errors
            score = 0.0
            metrics = {
                "correctness": 0.0,
                "runtime": 0.0,
                "error": 1.0,
                "stability": 0.0,
                "novelty": 0.0
            }
            success = False
            evaluation = {"score": score, "metrics": metrics}
        
        # STEP 4: Log everything (CRITICAL)
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
            "num_runs": 5,  # Option D: 5 runs per episode
        }
        
        logger.log_episode(log_entry)
        
        # STEP 5: Feed into causal observer
        causal_observer.observe(
            episode=episode,
            metrics=metrics,
            score=score,
            task_type=task["type"],
            success=success
        )
        
        # FIX 7: Causal learning hook - extract patterns every 20 episodes
        if (episode + 1) % 20 == 0:
            causal_summary = causal_observer.get_causal_summary()
            metric_insights = causal_summary.get('metric_insights', {})
            
            # Log causal insights
            print(f"\n  [CAUSAL] Insights at episode {episode + 1}:")
            for metric, insight in list(metric_insights.items())[:3]:
                corr = insight['correlation_with_score']
                print(f"    {metric}: r={corr:+.3f}")
        
        # STEP 6: Feedback loop - update evolution based on score
        evolver.update_from_score(
            score=score,
            correctness=metrics.get("correctness", 0.0),
            current_solution=solution_func
        )
        
        # Track scores
        scores_history.append(score)
        
        # STEP 7: Monitor progress (every 10 episodes)
        if (episode + 1) % 10 == 0 or episode == 0:
            elapsed = time.time() - start_time
            
            # Get statistics
            stats = evaluator.get_history_statistics()
            evolver_stats = evolver.get_statistics()
            causal_summary = causal_observer.get_causal_summary()
            
            print(f"\n{'='*80}")
            print(f"EPISODE {episode + 1}/{num_episodes}")
            print(f"{'='*80}")
            print(f"Current Score: {score:.4f}")
            print(f"Task Type: {task['type']}")
            print(f"Success: {'✓' if success else '✗'}")
            print(f"\n--- Evaluation Statistics ---")
            print(f"Average Score (all): {stats['average_score']:.4f}")
            print(f"Best Score: {stats['best_score']:.4f}")
            print(f"Worst Score: {stats['worst_score']:.4f}")
            print(f"Trend: {stats['trend'].upper()}")
            print(f"Improvement Rate: {stats['improvement_rate']:+.4f}")
            print(f"\n--- Evolution Statistics ---")
            print(f"Current Quality: {evolver_stats['current_quality']:.4f}")
            print(f"Avg Mutation Score: {evolver_stats['avg_score']:.4f}")
            print(f"Total Mutations: {evolver_stats['total_mutations']}")
            print(f"\n--- Recent Performance (last 10) ---")
            recent_avg = sum(scores_history[-10:]) / min(10, len(scores_history))
            print(f"Average: {recent_avg:.4f}")
            print(f"\nElapsed Time: {elapsed:.1f}s")
            print(f"{'='*80}\n")
    
    # Final analysis
    total_time = time.time() - start_time
    
    print("\n" + "=" * 80)
    print("EXPERIMENT COMPLETE - FINAL ANALYSIS")
    print("=" * 80)
    
    # Overall statistics
    final_stats = evaluator.get_history_statistics()
    evolver_final = evolver.get_statistics()
    causal_final = causal_observer.get_causal_summary()
    
    print(f"\n📊 OVERALL RESULTS")
    print(f"{'─' * 80}")
    print(f"Total Episodes: {num_episodes}")
    print(f"Total Time: {total_time:.2f}s")
    print(f"Avg Time/Episode: {total_time/num_episodes:.3f}s")
    
    print(f"\n📈 SCORE ANALYSIS")
    print(f"{'─' * 80}")
    print(f"Final Average Score: {final_stats['average_score']:.4f}")
    print(f"Best Score: {final_stats['best_score']:.4f}")
    print(f"Worst Score: {final_stats['worst_score']:.4f}")
    print(f"Overall Trend: {final_stats['trend'].upper()}")
    print(f"Improvement Rate: {final_stats['improvement_rate']:+.4f}")
    
    # First half vs second half comparison
    mid = num_episodes // 2
    first_half_avg = sum(scores_history[:mid]) / mid
    second_half_avg = sum(scores_history[mid:]) / (num_episodes - mid)
    
    print(f"\n📉 LEARNING DYNAMICS")
    print(f"{'─' * 80}")
    print(f"First Half Average: {first_half_avg:.4f}")
    print(f"Second Half Average: {second_half_avg:.4f}")
    print(f"Improvement: {second_half_avg - first_half_avg:+.4f}")
    
    if second_half_avg > first_half_avg + 0.05:
        print("✅ POSITIVE: System is learning and improving!")
    elif second_half_avg < first_half_avg - 0.05:
        print("❌ WARNING: System performance is degrading")
    else:
        print("⚠️  NEUTRAL: System is stable but not improving significantly")
    
    print(f"\n🧬 EVOLUTION RESULTS")
    print(f"{'─' * 80}")
    print(f"Final Quality Level: {evolver_final['current_quality']:.4f}")
    print(f"Average Mutation Score: {evolver_final['avg_score']:.4f}")
    print(f"Best Mutation Score: {evolver_final['best_score']:.4f}")
    
    print(f"\n🔬 CAUSAL INSIGHTS")
    print(f"{'─' * 80}")
    print(f"Success Rate: {causal_final.get('success_rate', 0):.2%}")
    print(f"Causal Trend: {causal_final.get('trend', 'unknown').upper()}")
    
    task_perf = causal_final.get('task_performance', {})
    if task_perf:
        print(f"\nPerformance by Task Type:")
        for task_type, perf in task_perf.items():
            print(f"  {task_type:20s}: avg_score={perf['avg_score']:.4f} (n={perf['count']})")
    
    metric_insights = causal_final.get('metric_insights', {})
    if metric_insights:
        print(f"\nMetric Correlations with Score:")
        for metric, insight in metric_insights.items():
            corr = insight['correlation_with_score']
            direction = "positive" if corr > 0.1 else ("negative" if corr < -0.1 else "neutral")
            print(f"  {metric:20s}: r={corr:+.3f} ({direction})")
    
    print(f"\n💾 LOGGING")
    print(f"{'─' * 80}")
    print(f"Log File: {logger.get_log_path()}")
    print(f"Episodes Logged: {logger.get_episode_count()}")
    print(f"Format: JSONL (ready for GNN training)")
    
    # Key findings
    print(f"\n🎯 KEY FINDINGS")
    print(f"{'─' * 80}")
    
    findings = []
    
    if final_stats['trend'] == 'improving':
        findings.append("✅ Score trend is IMPROVING - learning signal detected")
    elif final_stats['trend'] == 'stable':
        findings.append("⚠️  Score trend is STABLE - may need weight adjustment")
    else:
        findings.append("❌ Score trend is DECLINING - investigate mutation strategy")
    
    if evolver_final['current_quality'] > 0.7:
        findings.append("✅ Evolution quality converged to high level")
    
    if causal_final.get('success_rate', 0) > 0.6:
        findings.append("✅ High success rate indicates effective mutations")
    
    novelty_scores = [r['metrics']['novelty'] for r in evaluator.history.records[-20:]]
    avg_recent_novelty = sum(novelty_scores) / len(novelty_scores)
    
    if avg_recent_novelty < 0.5:
        findings.append("✅ Novelty decreasing - system converging (good sign)")
    else:
        findings.append("⚠️  Novelty still high - system exploring widely")
    
    for finding in findings:
        print(finding)
    
    print(f"\n{'='*80}")
    print("EXPERIMENT SUMMARY")
    print(f"{'='*80}")
    print(f"\nThe evaluation system successfully:")
    print(f"  ✓ Ran {num_episodes} episodes on algorithm domain")
    print(f"  ✓ Tracked multi-dimensional metrics")
    print(f"  ✓ Fed scores into evolution feedback loop")
    print(f"  ✓ Observed causal patterns")
    print(f"  ✓ Logged all data for GNN training")
    print(f"  ✓ Detected learning trends")
    print(f"\nNext steps:")
    print(f"  1. Analyze log file: {logger.get_log_path()}")
    print(f"  2. Train GNN on logged data")
    print(f"  3. Refine weights based on causal insights")
    print(f"  4. Expand to additional domains")
    print(f"{'='*80}\n")
    
    return {
        "evaluator": evaluator,
        "evolver": evolver,
        "causal_observer": causal_observer,
        "logger": logger,
        "scores_history": scores_history,
        "final_stats": final_stats,
    }


if __name__ == "__main__":
    try:
        results = run_experiment(num_episodes=100, seed=42)
        print("\n✅ Experiment completed successfully!")
    except Exception as e:
        print(f"\n❌ Experiment failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
