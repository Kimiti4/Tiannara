# tiannara_pros/orchestrators/orchestrator_day10C_pipeline.py

import argparse
import json
import time
import uuid
from pathlib import Path
from typing import Any, Dict

from tiannara_core.memory.memory_engine import MemoryEngine
from tiannara_core.cognition.context_processor import ContextProcessor
from tiannara_core.memory.consolidator import MemoryConsolidator
from tiannara_core.cognition.skill_memory import SkillMemory
from tiannara_core.cognition.decision_engine import DecisionEngine
from tiannara_core.action.action_layer import ActionLayer
from tiannara_core.sim.simulator import ProstheticSimulator

from tiannara_pros.io.emg_input import EMGInput
from tiannara_pros.io.console_output import ConsoleOutput
from tiannara_pros.io.action_schema import build_action_packet

from tiannara_pros.actuators.motor_controller import MotorController
from tiannara_pros.actuators.command_safety import validate_and_clip
from tiannara_pros.actuators.retry_controller import RetryController
from tiannara_pros.actuators.actuator_memory import ActuatorMemory


def load_limits() -> Dict[str, Any]:
    p = Path(__file__).resolve().parents[1] / "config" / "limits.json"
    return json.loads(p.read_text())


def deep_merge(base: Dict[str, Any], override: Dict[str, Any]) -> Dict[str, Any]:
    """
    Recursively merges override into base (without mutating base).
    """
    if not isinstance(base, dict):
        return override
    out = dict(base)
    for k, v in (override or {}).items():
        if k in out and isinstance(out[k], dict) and isinstance(v, dict):
            out[k] = deep_merge(out[k], v)
        else:
            out[k] = v
    return out


def feedback_to_outcome(feedback: dict) -> str:
    if not feedback.get("ok"):
        return "bad"
    return "good" if feedback.get("success") else "bad"


def make_run_dir(run_label: str = "day10c_pipeline") -> Path:
    runs_dir = Path("runs")
    runs_dir.mkdir(exist_ok=True)

    stamp = time.strftime("%Y%m%d_%H%M%S")
    run_id = f"{stamp}_{str(uuid.uuid4())[:12]}_{run_label}"
    run_dir = runs_dir / run_id
    run_dir.mkdir(parents=True, exist_ok=True)
    return run_dir


def run_pipeline(cfg: Dict[str, Any], *, max_steps: int = 60, run_label: str = "day10c_pipeline") -> Path:
    """
    Runs the pipeline and returns the run directory path.
    """
    # ---- Run directory + packets.jsonl ----
    run_dir = make_run_dir(run_label=run_label)
    packets_path = run_dir / "packets.jsonl"

    print("\n=== Day 10C Pros Pipeline ===")
    print("Run folder:", str(run_dir))
    print("Packets file:", str(packets_path))
    print()

    memory = MemoryEngine()
    processor = ContextProcessor()
    consolidator = MemoryConsolidator()
    skill = SkillMemory()

    decider = DecisionEngine(
        min_confidence=cfg["safety"]["min_confidence"],
        safety_fallback_intent=cfg["safety"]["fallback_intent"],
        skill_memory=skill,
    )

    action_layer = ActionLayer()

    # Day 14 runtime-configured filters
    if "filters" in cfg:
        action_layer.smooth_alpha = cfg["filters"].get("smooth_alpha", action_layer.smooth_alpha)
        action_layer.rate_limit_max_delta = cfg["filters"].get(
            "rate_limit_max_delta", action_layer.rate_limit_max_delta
        )

    sim = ProstheticSimulator()

    inp = EMGInput()
    out = ConsoleOutput()
    motor = MotorController()
    retry = RetryController(max_retries=2)

    # Day 15 actuator memory
    bias_alpha = cfg.get("actuator_memory", {}).get("bias_alpha", 0.35)
    act_mem = ActuatorMemory(bias_alpha=bias_alpha)

    # Bootstrap patterns
    bootstrap = [
        {"joint_angles": [10, 20, 30], "intent": "grip", "tags": ["hand", "precision"]},
        {"joint_angles": [15, 22, 35], "intent": "stabilize", "tags": ["balance"]},
        {"joint_angles": [12, 18, 33], "intent": "release", "tags": ["hand"]},
    ]

    for d in bootstrap:
        ctx = processor.process(d)
        memory.store(ctx, tags=d["tags"])

    patterns = consolidator.consolidate(memory.memory_store)
    for p in patterns:
        memory.store_pattern(p)

    step = 0

    with packets_path.open("a", encoding="utf-8") as fjsonl:
        while step < max_steps:
            packet = inp.get_next()
            if packet is None:
                break

            step += 1
            tags = packet.get("tags", [])

            # Context processing
            processed = processor.process(
                {"joint_angles": packet.get("joint_angles", []), "intent": "unknown"}
            )
            memory.store(processed, tags=tags)

            # Decision
            decision = decider.decide(memory.memory_store, tags)

            # Runtime confidence gate
            if decision["confidence"] < cfg["safety"]["min_confidence"]:
                decision["_min_confidence_gate"] = True
                decision["intent"] = cfg["safety"]["fallback_intent"]
                decision["confidence"] = 0.0
                decision["reason"] = (
                    f"min_confidence<{cfg['safety']['min_confidence']:.2f} → safety fallback"
                )
            else:
                decision["_min_confidence_gate"] = False

            # Action mapping
            action = action_layer.intent_to_action(
                decision["intent"], decision["confidence"], tags
            )

            # Realism hooks
            sim.update_fatigue(decision["intent"], dt=cfg["loop"]["dt"])

            # Build action packet
            action_packet = build_action_packet(
                action=action,
                decision=decision,
                context_tags=tags,
                emg=packet.get("emg", {}),
                fatigue=sim.fatigue,
                core_version="1.0.0",
            )

            # include step in context (useful for reports/replay)
            action_packet.setdefault("context", {})
            action_packet["context"]["step"] = step

            # Day 15: actuator-memory bias BEFORE retry loop
            memory_used = act_mem.has_memory(action_packet["command"])
            action_packet["command"] = act_mem.apply_bias(action_packet["command"])
            action_packet.setdefault("safety", {})
            action_packet["safety"]["actuator_memory_used"] = bool(memory_used)

            # Retry loop with initial feedback capture (expects your updated retry_controller)
            final_cmd, fb, retries_used, fb_initial = retry.run_retry_loop(
                motor=motor,
                command=action_packet["command"],
                validate_and_clip_fn=validate_and_clip,
                cfg=cfg,
            )

            action_packet["command"] = final_cmd
            action_packet["feedback"] = fb
            action_packet["feedback_initial"] = fb_initial

            action_packet["safety"]["retries_used"] = retries_used
            action_packet["safety"]["retry_exhausted"] = (
                fb.get("success") is False and retries_used >= retry.max_retries
            )
            action_packet["safety"]["initial_success"] = (
                bool(fb_initial.get("ok")) and bool(fb_initial.get("success"))
            )

            # Outcome
            outcome = feedback_to_outcome(fb)

            # Day 16: skill update (optional)
            updated_bias = {}
            try:
                updated_bias = skill.update(
                    intent=decision["intent"],
                    context_tags=tags,
                    outcome=outcome,
                    metrics=fb.get("metrics", {}) if fb else {},
                ) or {}
                if hasattr(skill, "decay_step"):
                    skill.decay_step()
            except Exception:
                updated_bias = {}

            action_packet["safety"]["skill_bias_updated"] = updated_bias

            # Day 15: update actuator memory if success
            updated = act_mem.update_from_feedback(final_cmd, fb)
            action_packet["safety"]["actuator_memory_updated"] = bool(updated)

            # Episodic outcome store
            try:
                memory.store_outcome(tags, decision["intent"], decision["confidence"], outcome)
            except Exception:
                pass

            # Pattern reinforcement
            chosen = decision.get("chosen_pattern")
            if chosen and chosen.get("type") == "pattern":
                delta = +0.05 if outcome == "good" else -0.05
                try:
                    memory.adjust_pattern_importance(
                        chosen.get("data", {}).get("intent"),
                        chosen.get("tags", []),
                        delta,
                    )
                except Exception:
                    pass

            # Compact console line
            metrics = (fb or {}).get("metrics", {}) or {}
            print(
                f"Step {step:02d} | ctx={tags} | decision={decision['intent']} "
                f"conf={decision['confidence']:.3f} | cmd.intent={final_cmd.get('intent')} "
                f"| success={fb.get('success')} metrics={metrics}"
            )

            out.send(action_packet)
            fjsonl.write(json.dumps(action_packet) + "\n")

    print("\nDone.")
    return run_dir


def main():
    ap = argparse.ArgumentParser(description="Day 10C pipeline (supports scenario override)")
    ap.add_argument("--scenario", default=None, help="Path to scenario JSON (in-memory override)")
    ap.add_argument("--max-steps", type=int, default=60, help="Max steps")
    ap.add_argument("--label", default="day10c_pipeline", help="Run folder label suffix")
    args = ap.parse_args()

    cfg = load_limits()

    if args.scenario:
        sp = Path(args.scenario).expanduser().resolve()
        if not sp.exists():
            raise SystemExit(f"Scenario not found: {sp}")
        scenario_cfg = json.loads(sp.read_text(encoding="utf-8"))
        cfg = deep_merge(cfg, scenario_cfg)

    run_pipeline(cfg, max_steps=args.max_steps, run_label=args.label)


if __name__ == "__main__":
    main()