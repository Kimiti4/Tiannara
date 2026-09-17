"""Check strategy selection for piecewise tasks."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

gen = ReverseEngineeringGenerator(seed=44)
evolver = ReverseEngineeringEvolver(seed=125)

print("Checking strategy selection for piecewise tasks")
print("=" * 80)

piecewise_count = 0
for episode in range(1, 101):
    task = gen.generate_task(episode=episode)
    subtype = task.get("subtype", "unknown")
    
    if subtype == "piecewise":
        piecewise_count += 1
        
        # Extract examples
        examples = task["inputs"].get("examples", [])
        
        # Deduplicate
        seen = set()
        unique_examples = []
        for ex in examples:
            key = (ex["input"], ex["output"])
            if key not in seen:
                seen.add(key)
                unique_examples.append(ex)
        
        inputs = [ex["input"] for ex in unique_examples]
        outputs = [ex["output"] for ex in unique_examples]
        
        # Check what strategy would be selected
        strategy = evolver._select_best_strategy(inputs, outputs, "piecewise")
        
        print(f"\nEpisode {episode}:")
        print(f"  Examples: {len(examples)} total, {len(unique_examples)} unique")
        print(f"  Inputs: {inputs}")
        print(f"  Outputs: {outputs}")
        print(f"  Is perfectly linear: {evolver._is_perfectly_linear(inputs, outputs)}")
        print(f"  Strategy selected: {strategy}")
        
        if piecewise_count >= 5:
            break
