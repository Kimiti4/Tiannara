"""Check strategy selection for modulo tasks."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

gen = ReverseEngineeringGenerator(seed=44)
evolver = ReverseEngineeringEvolver(seed=125)

print("Checking strategy selection for modulo tasks")
print("=" * 80)

modulo_count = 0
for episode in range(1, 101):
    task = gen.generate_task(episode=episode)
    subtype = task.get("subtype", "unknown")
    
    if subtype == "modulo_pattern":
        modulo_count += 1
        
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
        
        # Check conditions for rule_extraction
        unique_outputs = len(set(outputs))
        output_range = max(outputs) - min(outputs) if outputs else 0
        all_small_ints = all(isinstance(o, (int, float)) and o >= 0 and o == int(o) for o in outputs)
        
        # Check what strategy would be selected
        strategy = evolver._select_best_strategy(inputs, outputs, "modulo_pattern")
        
        print(f"\nEpisode {episode}:")
        print(f"  Examples: {len(examples)} total, {len(unique_examples)} unique")
        print(f"  Inputs: {inputs}")
        print(f"  Outputs: {outputs}")
        print(f"  Unique outputs: {unique_outputs}")
        print(f"  Output range: {output_range}")
        print(f"  All small ints: {all_small_ints}")
        print(f"  Strategy selected: {strategy}")
        
        if modulo_count >= 8:
            break
