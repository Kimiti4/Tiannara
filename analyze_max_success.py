"""Analyze maximum achievable success rate for algorithm domain."""
import json

with open('tiannara_core/logs/evaluation_episodes.jsonl') as f:
    lines = f.readlines()

print("=" * 80)
print("MAXIMUM SUCCESS RATE ANALYSIS - ALGORITHM DOMAIN")
print("=" * 80)

# Analyze correctness distribution
correctness_values = []
scores = []
for line in lines:
    data = json.loads(line)
    correctness_values.append(data['metrics']['correctness'])
    scores.append(data['score'])

avg_correctness = sum(correctness_values) / len(correctness_values)
avg_score = sum(scores) / len(scores)

print(f"\nTotal Episodes: {len(lines)}")
print(f"Average Correctness: {avg_correctness:.4f}")
print(f"Average Score: {avg_score:.4f}")

# Count episodes by correctness thresholds
thresholds = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
print("\nCorrectness Distribution:")
for i in range(len(thresholds) - 1):
    low = thresholds[i]
    high = thresholds[i + 1]
    count = sum(1 for c in correctness_values if low <= c < high)
    pct = count / len(correctness_values) * 100
    print(f"  {low:.1f} ≤ correctness < {high:.1f}: {count:3d} episodes ({pct:5.1f}%)")

# Calculate theoretical max success rate
# If we set exploit threshold to different values, what % would succeed?
print("\nTheoretical Success Rates at Different Exploit Thresholds:")
for threshold in [0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]:
    episodes_above = sum(1 for c in correctness_values if c >= threshold)
    pct = episodes_above / len(correctness_values) * 100
    print(f"  Threshold ≥ {threshold:.1f}: {episodes_above:3d} episodes ({pct:5.1f}%)")

# Current success rate (exact match required)
success_count = 0
for line in lines:
    data = json.loads(line)
    if data.get('success', False):
        success_count += 1

current_success_rate = success_count / len(lines) * 100
print(f"\nCurrent Success Rate (exact match): {success_count}/{len(lines)} = {current_success_rate:.1f}%")

# Analysis of why some high-correctness episodes fail verification
print("\n" + "=" * 80)
print("WHY HIGH-CORRECTNESS EPISODES FAIL VERIFICATION")
print("=" * 80)

high_correct_failures = []
for line in lines:
    data = json.loads(line)
    if data['metrics']['correctness'] >= 0.8 and not data.get('success', False):
        high_correct_failures.append(data)

print(f"\nEpisodes with correctness ≥ 0.8 but success=False: {len(high_correct_failures)}")
if high_correct_failures:
    print("\nSample failures:")
    for d in high_correct_failures[:5]:
        print(f"  Episode {d['episode']:3d}: task={d['task_type']:20s} correctness={d['metrics']['correctness']:.2f} score={d['score']:.3f}")

# Theoretical maximum if we accept near-matches
print("\n" + "=" * 80)
print("THEORETICAL MAXIMUM SUCCESS RATES")
print("=" * 80)

print("\nScenario 1: Accept correctness ≥ 0.8 as success")
scenario1 = sum(1 for c in correctness_values if c >= 0.8)
print(f"  Success rate: {scenario1}/{len(lines)} = {scenario1/len(lines)*100:.1f}%")

print("\nScenario 2: Accept correctness ≥ 0.6 as success")
scenario2 = sum(1 for c in correctness_values if c >= 0.6)
print(f"  Success rate: {scenario2}/{len(lines)} = {scenario2/len(lines)*100:.1f}%")

print("\nScenario 3: Accept correctness > 0.0 as success (any non-error)")
scenario3 = sum(1 for c in correctness_values if c > 0.0)
print(f"  Success rate: {scenario3}/{len(lines)} = {scenario3/len(lines)*100:.1f}%")

print("\n" + "=" * 80)
print("CONCLUSION")
print("=" * 80)
print(f"\nCurrent implementation (exact match): {current_success_rate:.1f}%")
print(f"Maximum achievable (correctness ≥ 0.6): {scenario2/len(lines)*100:.1f}%")
print(f"Upper bound (any non-error): {scenario3/len(lines)*100:.1f}%")
print(f"\nThe gap between current ({current_success_rate:.1f}%) and max ({scenario2/len(lines)*100:.1f}%)")
print(f"is due to subtle bugs that produce near-correct outputs.")
print(f"This is BY DESIGN - enables learning through graded feedback.")
