"""
Test Multi-Domain System with NLP Integration.

Tests all 5 domains working together:
1. Algorithm (sorting, search, optimization)
2. Logic (patterns, deduction)
3. Reverse Engineering (function inference)
4. Causal (causal structure learning)
5. NLP (email writing, report generation, code explanation) [NEW]

With cross-domain skill transfer and unified evaluation.
"""

import sys
from pathlib import Path
import json
import time
from datetime import datetime

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator
from tiannara_core.evaluation.logic_domain import LogicPuzzleGenerator
from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator
from tiannara_core.sim.nlp_domain import NLPTaskGenerator  # NEW NLP DOMAIN

from tiannara_core.evaluation.evolution_engine import AlgorithmEvolver
from tiannara_core.evaluation.logic_evolution_engine import LogicPuzzleEvolver
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver
from tiannara_core.evaluation.causal_system_evolver import CausalSystemEvolver
from tiannara_core.sim.nlp_domain import NLPEvolver  # NEW NLP EVOLVER

from tiannara_core.evaluation.evaluator import Evaluator


def run_nlp_domain_test():
    """Test NLP domain independently first."""
    print("\n" + "=" * 80)
    print("TEST 1: NLP Domain Independent Test")
    print("=" * 80)
    
    generator = NLPTaskGenerator()
    evolver = NLPEvolver()
    evaluator = Evaluator()
    
    task_types = [
        "email_writing",
        "report_generation", 
        "code_explanation",
        "text_summarization",
        "sentiment_analysis",
        "intent_recognition"
    ]
    
    results = []
    
    for task_type in task_types:
        print(f"\nTesting {task_type}...")
        
        # Generate task
        task = generator.generate_task(task_type=task_type, difficulty="medium")
        
        # Create solution
        variant = evolver.create_variant(task, episode=1)
        
        # Execute solution
        if task_type == "email_writing":
            output = variant(recipient="John Doe")
        elif task_type == "report_generation":
            output = variant()
        elif task_type == "code_explanation":
            output = variant()
        elif task_type == "text_summarization":
            output = variant(text=task["inputs"]["text"])
        elif task_type == "sentiment_analysis":
            output = variant(text=task["inputs"]["text"])
        elif task_type == "intent_recognition":
            output = variant(utterance=task["inputs"]["utterance"])
        else:
            output = variant()
        
        # Evaluate
        result = evaluator.evaluate(variant, task.get("inputs", {}))
        
        print(f"   ✓ Task type: {task_type}")
        print(f"   ✓ Output length: {len(str(output))} chars")
        print(f"   ✓ Score: {result.get('score', 0):.2f}")
        
        results.append({
            "task_type": task_type,
            "success": result.get("success", False),
            "score": result.get("score", 0)
        })
    
    # Summary
    success_count = sum(1 for r in results if r["success"])
    avg_score = sum(r["score"] for r in results) / len(results) if results else 0
    
    print(f"\n{'='*80}")
    print(f"NLP Domain Results:")
    print(f"  Tasks tested: {len(results)}")
    print(f"  Success rate: {success_count}/{len(results)} ({success_count/len(results)*100:.1f}%)")
    print(f"  Average score: {avg_score:.4f}")
    print(f"{'='*80}")
    
    return results


def run_multi_domain_with_nlp(num_episodes=50):
    """Run experiment across all 5 domains including NLP."""
    
    # Initialize domain generators
    domains = {
        "algorithm": AlgorithmTaskGenerator(seed=42),
        "logic": LogicPuzzleGenerator(seed=43),
        "reverse_engineering": ReverseEngineeringGenerator(seed=44),
        "causal": CausalSystemGenerator(seed=45),
        "nlp": NLPTaskGenerator()  # NEW NLP DOMAIN
    }
    
    # Initialize evolvers
    evolvers = {
        "algorithm": AlgorithmEvolver(seed=123),
        "logic": LogicPuzzleEvolver(seed=124),
        "reverse_engineering": ReverseEngineeringEvolver(seed=125),
        "causal": CausalSystemEvolver(seed=126),
        "nlp": NLPEvolver()  # NEW NLP EVOLVER
    }
    
    evaluator = Evaluator()
    
    print("\n" + "=" * 80)
    print("MULTI-DOMAIN EXPERIMENT WITH NLP INTEGRATION")
    print("=" * 80)
    print(f"Episodes: {num_episodes}")
    print(f"Domains: {', '.join(domains.keys())}")
    print(f"Start Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Track results
    episode_results = []
    domain_stats = {domain: {"count": 0, "successes": 0, "scores": []} 
                    for domain in domains.keys()}
    
    start_time = time.time()
    
    # Cycle through domains
    domain_list = list(domains.keys())
    
    for episode in range(1, num_episodes + 1):
        # Select domain (round-robin)
        domain_name = domain_list[(episode - 1) % len(domain_list)]
        domain_gen = domains[domain_name]
        domain_evolver = evolvers[domain_name]
        
        # Generate task
        if domain_name == "nlp":
            task = domain_gen.generate_task(difficulty="medium")
        else:
            task = domain_gen.generate_task(episode=episode)
        task["domain"] = domain_name
        domain_stats[domain_name]["count"] += 1
        
        # Create solution
        try:
            variant = domain_evolver.create_variant(task, episode=episode)
            
            # Execute based on domain
            if domain_name == "nlp":
                # Handle NLP-specific execution
                task_type = task.get("type", "")
                if task_type == "email_writing":
                    output = variant(recipient="Test User")
                elif task_type == "report_generation":
                    output = variant()
                elif task_type == "code_explanation":
                    output = variant()
                elif task_type == "text_summarization":
                    output = variant(text=task["inputs"]["text"])
                elif task_type == "sentiment_analysis":
                    output = variant(text=task["inputs"]["text"])
                elif task_type == "intent_recognition":
                    output = variant(utterance=task["inputs"]["utterance"])
                else:
                    output = variant()
            else:
                # Standard execution for other domains
                output = variant(**task.get("inputs", {}))
            
            # Evaluate
            result = evaluator.evaluate(variant, task.get("inputs", {}))
            
            success = result.get("success", False)
            score = result.get("score", 0)
            
            domain_stats[domain_name]["successes"] += 1 if success else 0
            domain_stats[domain_name]["scores"].append(score)
            
            episode_result = {
                "episode": episode,
                "domain": domain_name,
                "task_type": task.get("type", ""),
                "difficulty": task.get("difficulty", "medium"),
                "success": success,
                "score": score,
                "timestamp": datetime.now().isoformat()
            }
            episode_results.append(episode_result)
            
            # Print progress every 10 episodes
            if episode % 10 == 0:
                elapsed = time.time() - start_time
                print(f"Episode {episode}/{num_episodes} | Elapsed: {elapsed:.1f}s | "
                      f"Current: {domain_name} | Success: {'✓' if success else '✗'} | "
                      f"Score: {score:.4f}")
        
        except Exception as e:
            print(f"Episode {episode} ERROR in {domain_name}: {e}")
            domain_stats[domain_name]["scores"].append(0)
    
    elapsed_total = time.time() - start_time
    
    # Print results
    print("\n" + "=" * 80)
    print("RESULTS SUMMARY")
    print("=" * 80)
    
    for domain_name in domain_list:
        stats = domain_stats[domain_name]
        count = stats["count"]
        successes = stats["successes"]
        scores = stats["scores"]
        avg_score = sum(scores) / len(scores) if scores else 0
        success_rate = successes / count if count > 0 else 0
        
        print(f"\n{domain_name.upper()}:")
        print(f"  Episodes: {count}")
        print(f"  Successes: {successes} ({success_rate*100:.1f}%)")
        print(f"  Avg Score: {avg_score:.4f}")
    
    # Overall statistics
    total_episodes = sum(s["count"] for s in domain_stats.values())
    total_successes = sum(s["successes"] for s in domain_stats.values())
    overall_success_rate = total_successes / total_episodes if total_episodes > 0 else 0
    
    all_scores = []
    for s in domain_stats.values():
        all_scores.extend(s["scores"])
    overall_avg_score = sum(all_scores) / len(all_scores) if all_scores else 0
    
    print(f"\n{'='*80}")
    print(f"OVERALL STATISTICS:")
    print(f"  Total Episodes: {total_episodes}")
    print(f"  Total Successes: {total_successes}")
    print(f"  Overall Success Rate: {overall_success_rate*100:.1f}%")
    print(f"  Overall Avg Score: {overall_avg_score:.4f}")
    print(f"  Total Time: {elapsed_total:.1f}s")
    print(f"{'='*80}")
    
    # Save results
    output_file = Path("multi_domain_nlp_episodes.jsonl")
    with open(output_file, 'w', encoding='utf-8') as f:
        for result in episode_results:
            f.write(json.dumps(result) + "\n")
    
    print(f"\nResults saved to: {output_file}")
    
    return episode_results, domain_stats


if __name__ == "__main__":
    print("Starting NLP Domain Integration Tests...\n")
    
    # Test 1: NLP domain independently
    nlp_results = run_nlp_domain_test()
    
    # Test 2: Multi-domain with NLP
    multi_results, domain_stats = run_multi_domain_with_nlp(num_episodes=50)
    
    print("\n✅ All tests complete!")
