"""Check what variables are in observations."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.causal_system_domain import CausalSystemGenerator

def check_observation_vars():
    """Check what variables are present in observations."""
    gen = CausalSystemGenerator(seed=42)
    
    print("Checking Observation Variables")
    print("=" * 80)
    
    for i in range(1, 6):
        task = gen.generate_task(i)
        
        print(f"\nTask {i}: {task.get('subtype')}")
        print(f"  Target variable: {task['inputs'].get('target_variable', 'N/A')}")
        
        observations = task['inputs']['observations']
        if observations:
            first_obs = observations[0]
            print(f"  Variables in observations: {list(first_obs.keys())}")
            print(f"  First observation: {first_obs}")
            
            # Check if target variable is in observations
            target = task['inputs'].get('target_variable', 'y')
            if target in first_obs:
                print(f"  ✅ Target '{target}' IS in observations")
            else:
                print(f"  ❌ Target '{target}' NOT in observations!")

if __name__ == "__main__":
    check_observation_vars()
