"""Debug Strategy Selection in RE Evolver."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.reverse_engineering_domain import ReverseEngineeringGenerator
from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

def test_strategy_selection():
    """Test what strategies are selected for different task types."""
    
    gen = ReverseEngineeringGenerator(seed=42)
    evolver = ReverseEngineeringEvolver(seed=42)
    
    # Generate 50 tasks and track strategy selection
    strategy_counts = {}
    success_by_type = {}
    
    for i in range(50):
        task = gen.generate_task(episode=i)
        subtype = task.get("subtype", "unknown")
        
        # Extract inputs/outputs
        examples = task["inputs"]["examples"]
        inputs = [ex["input"] for ex in examples]
        outputs = [ex["output"] for ex in examples]
        
        # Get selected strategy
        strategy = evolver._select_best_strategy(inputs, outputs, subtype)
        
        # Track counts
        key = f"{subtype} -> {strategy}"
        strategy_counts[key] = strategy_counts.get(key, 0) + 1
        
        # Test if it works
        variant = evolver.create_variant(task, episode=i)
        test_input = task["inputs"]["test_input"]
        predicted = variant(test_input=test_input)
        expected = task["expected_output"]
        success = abs(predicted - expected) < 0.01
        
        # Track success by type
        if subtype not in success_by_type:
            success_by_type[subtype] = {"success": 0, "total": 0}
        success_by_type[subtype]["total"] += 1
        if success:
            success_by_type[subtype]["success"] += 1
    
    print("=" * 80)
    print("STRATEGY SELECTION ANALYSIS")
    print("=" * 80)
    print("\nStrategy Distribution:")
    for key, count in sorted(strategy_counts.items()):
        print(f"  {key:50s}: {count}")
    
    print("\n" + "=" * 80)
    print("SUCCESS RATES BY FUNCTION TYPE")
    print("=" * 80)
    for subtype, stats in sorted(success_by_type.items()):
        rate = stats["success"] / stats["total"] * 100
        print(f"  {subtype:20s}: {rate:5.1f}% ({stats['success']}/{stats['total']})")

if __name__ == "__main__":
    test_strategy_selection()
