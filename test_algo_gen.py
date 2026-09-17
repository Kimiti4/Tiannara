import sys
from pathlib import Path
sys.path.insert(0, str(Path.cwd()))

from tiannara_core.evaluation.algorithm_domain import AlgorithmTaskGenerator

gen = AlgorithmTaskGenerator(seed=42)

for i in range(5):
    task = gen.generate_task(episode=i)
    print(f'Episode {i}: type={task.get("type")}, inputs_keys={list(task.get("inputs", {}).keys())[:3]}')
