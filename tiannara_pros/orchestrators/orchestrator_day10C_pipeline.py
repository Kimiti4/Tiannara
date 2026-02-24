import json
from pathlib import Path

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


def load_limits():
    p = Path(__file__).resolve().parents[1] / "config" / "limits.json"
    return json.loads(p.read_text())


def feedback_to_outcome(feedback: dict) -> str:
    if not feedback.get("ok"):
        return "bad"
    return "good" if feedback.get("success") else "bad"


def main():
    cfg = load_limits()

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

    # ✅ Day 14: wire config-driven filters
    action_layer.smooth_alpha = cfg["filters"]["smooth_alpha"]
    action_layer.rate_limit_max_delta = cfg["filters"]["rate_limit_max_delta"]

    sim = ProstheticSimulator()

    inp = EMGInput()
    out = ConsoleOutput()
    motor = MotorController()
    retry = RetryController(max_retries=2)

    # ---- Bootstrap patterns ----
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

    print("\n=== Day 10C Pros Pipeline ===\n")

    step = 0
    max_steps = 60

    while step < max_steps:
        packet = inp.get_next()
        if packet is None:
            break

        step += 1
        tags = packet.get("tags", [])

        processed = processor.process(
            {"joint_angles": packet.get("joint_angles", []), "intent": "unknown"}
        )
        memory.store(processed, tags=tags)

        decision = decider.decide(memory.memory_store, tags)

        # 12.2C — runtime confidence gate
        if decision["confidence"] < cfg["safety"]["min_confidence"]:
            decision["_min_confidence_gate"] = True
            decision["intent"] = cfg["safety"]["fallback_intent"]
            decision["confidence"] = 0.0
            decision["reason"] = "min_confidence → safety fallback"
        else:
            decision["_min_confidence_gate"] = False

        action = action_layer.intent_to_action(
            decision["intent"], decision["confidence"], tags
        )

        sim.update_fatigue(decision["intent"], dt=cfg["loop"]["dt"])

        action_packet = build_action_packet(
            action=action,
            decision=decision,
            context_tags=tags,
            emg=packet.get("emg", {}),
            fatigue=sim.fatigue,
        )

        final_cmd, fb, retries_used = retry.run_retry_loop(
            motor=motor,
            command=action_packet["command"],
            validate_and_clip_fn=validate_and_clip,
            cfg=cfg,
        )

        action_packet["command"] = final_cmd
        action_packet["feedback"] = fb
        action_packet["safety"]["retries_used"] = retries_used

        outcome = feedback_to_outcome(fb)

        memory.store_outcome(tags, decision["intent"], decision["confidence"], outcome)

        chosen = decision.get("chosen_pattern")
        if chosen and chosen.get("type") == "pattern":
            delta = +0.05 if outcome == "good" else -0.05
            memory.adjust_pattern_importance(
                chosen.get("data", {}).get("intent"),
                chosen.get("tags", []),
                delta,
            )

        print("OUTCOME:", outcome)
        print("RETRIES_USED:", retries_used)
        print("SUCCESS:", fb.get("success"))

        out.send(action_packet)

    print("\nDone.")


if __name__ == "__main__":
    main()

    """What Day 14 gives you (confirmed)

Smooth transitions (no sudden jumps)

Rate-limited actuator targets (jerk protection)

Fully config-driven

Works with retries + feedback

Hardware-safe shaping layer complete"""