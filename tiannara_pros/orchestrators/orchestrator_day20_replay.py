# tiannara_pros/orchestrators/orchestrator_day20_replay.py

import json
from pathlib import Path

from tiannara_pros.actuators.motor_controller import MotorController


def replay(path: str, max_steps: int = 50):
    p = Path(path)
    if not p.exists():
        raise FileNotFoundError(f"Run file not found: {p}")

    motor = MotorController()

    print(f"\n=== Day 20 Replay ===")
    print(f"file: {p}")
    print(f"max_steps: {max_steps}\n")

    step = 0
    with p.open("r", encoding="utf-8") as f:
        for line in f:
            if step >= max_steps:
                break
            line = line.strip()
            if not line:
                continue

            packet = json.loads(line)
            cmd = packet.get("command", {})
            ctx = (packet.get("context", {}) or {}).get("tags", [])
            decision = (packet.get("decision", {}) or {}).get("intent")
            conf = (packet.get("decision", {}) or {}).get("confidence")

            motor.send(cmd)
            fb = motor.read_feedback()

            step += 1
            print(
                f"Step {step:02d} | ctx={ctx} | decision={decision} conf={conf} "
                f"| cmd.intent={cmd.get('intent')} | success={fb.get('success')} metrics={fb.get('metrics')}"
            )

    print("\nReplay done.\n")


def main():
    # default replay file
    replay("runs/day10c_pipeline.jsonl", max_steps=60)


if __name__ == "__main__":
    main()