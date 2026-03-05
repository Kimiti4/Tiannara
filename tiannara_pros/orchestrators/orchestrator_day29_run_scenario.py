# tiannara_pros/orchestrators/orchestrator_day29_run_scenario.py

import argparse
import json
from pathlib import Path

from tiannara_pros.orchestrators.orchestrator_day10C_pipeline import (
    load_limits,
    deep_merge,
    run_pipeline,
)


def main():
    ap = argparse.ArgumentParser(description="Run a scenario (overrides config in-memory)")
    ap.add_argument("--scenario", required=True, help="Path to scenario JSON")
    ap.add_argument("--max-steps", type=int, default=60, help="Steps to run")
    ap.add_argument("--label", default="day29_scenario", help="Run folder label suffix")
    args = ap.parse_args()

    base_cfg = load_limits()

    sp = Path(args.scenario).expanduser().resolve()
    if not sp.exists():
        raise SystemExit(f"Scenario not found: {sp}")

    scenario_cfg = json.loads(sp.read_text(encoding="utf-8"))

    cfg = deep_merge(base_cfg, scenario_cfg)
    run_dir = run_pipeline(cfg, max_steps=args.max_steps, run_label=args.label)

    print("\nScenario:", str(sp))
    print("Run dir:", str(run_dir))
    print("Packets:", str(Path(run_dir) / "packets.jsonl"))
    print()


if __name__ == "__main__":
    main()