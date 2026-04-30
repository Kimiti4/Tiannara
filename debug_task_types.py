"""Debug script to analyze task-specific failures."""
import json

with open('tiannara_core/logs/evaluation_episodes.jsonl') as f:
    lines = f.readlines()

# Analyze by task type
task_stats = {}
for line in lines:
    data = json.loads(line)
    task_type = data['task_type']
    
    if task_type not in task_stats:
        task_stats[task_type] = {
            'scores': [],
            'correctness': [],
            'success_count': 0,
            'total': 0
        }
    
    task_stats[task_type]['scores'].append(data['score'])
    task_stats[task_type]['correctness'].append(data['metrics']['correctness'])
    task_stats[task_type]['total'] += 1
    
    # Check if success flag is set (from task_generator.verify_solution)
    if data.get('success', False):
        task_stats[task_type]['success_count'] += 1

print("=" * 80)
print("TASK TYPE ANALYSIS")
print("=" * 80)

for task_type, stats in sorted(task_stats.items()):
    avg_score = sum(stats['scores']) / len(stats['scores']) if stats['scores'] else 0
    avg_correctness = sum(stats['correctness']) / len(stats['correctness']) if stats['correctness'] else 0
    success_rate = stats['success_count'] / stats['total'] * 100 if stats['total'] > 0 else 0
    
    print(f"\n{task_type}:")
    print(f"  Episodes: {stats['total']}")
    print(f"  Avg Score: {avg_score:.4f}")
    print(f"  Avg Correctness: {avg_correctness:.4f}")
    print(f"  Success Rate: {success_rate:.1f}% ({stats['success_count']}/{stats['total']})")
    
    # Show score distribution
    non_zero_scores = [s for s in stats['scores'] if s > 0]
    zero_scores = [s for s in stats['scores'] if s == 0]
    print(f"  Zero scores: {len(zero_scores)} | Non-zero scores: {len(non_zero_scores)}")
    
    if non_zero_scores:
        print(f"  Non-zero range: {min(non_zero_scores):.4f} - {max(non_zero_scores):.4f}")

# Find episodes with high correctness but low score
print("\n" + "=" * 80)
print("EPISODES WITH HIGH CORRECTNESS BUT LOW SCORE")
print("=" * 80)

high_correct_low_score = []
for line in lines:
    data = json.loads(line)
    if data['metrics']['correctness'] >= 0.6 and data['score'] < 0.5:
        high_correct_low_score.append(data)

if high_correct_low_score:
    print(f"\nFound {len(high_correct_low_score)} episodes:")
    for d in high_correct_low_score[:10]:
        print(f"  Episode {d['episode']:3d}: task={d['task_type']:20s} correctness={d['metrics']['correctness']:.2f} score={d['score']:.3f} success={d.get('success', False)}")
else:
    print("\nNo episodes found with high correctness but low score.")
