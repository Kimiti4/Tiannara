import json

with open('tiannara_core/logs/evaluation_episodes.jsonl') as f:
    lines = f.readlines()

print("First 20 episodes - correctness values:")
for i, line in enumerate(lines[:20]):
    data = json.loads(line)
    print(f"Episode {data['episode']:2d}: correctness={data['metrics']['correctness']:.2f}, score={data['score']:.3f}")

print("\nChecking for any episodes with correctness >= 0.6...")
high_correctness = []
for line in lines:
    data = json.loads(line)
    if data['metrics']['correctness'] >= 0.6:
        high_correctness.append(data)

if high_correctness:
    print(f"\nFound {len(high_correctness)} episodes with correctness >= 0.6:")
    for d in high_correctness[:5]:
        print(f"  Episode {d['episode']}: correctness={d['metrics']['correctness']:.2f}")
else:
    print("\nNo episodes reached correctness >= 0.6")
    print("\nCorrectness distribution:")
    correctness_values = [json.loads(l)['metrics']['correctness'] for l in lines]
    print(f"  Min: {min(correctness_values):.2f}")
    print(f"  Max: {max(correctness_values):.2f}")
    print(f"  Avg: {sum(correctness_values)/len(correctness_values):.2f}")
