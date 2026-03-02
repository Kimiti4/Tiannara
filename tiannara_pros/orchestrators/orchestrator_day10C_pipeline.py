# tiannara_pros/orchestrators/orchestrator_day10C_pipeline.py

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
from tiannara_pros.io.jsonl_logger import JsonlLogger

from tiannara_pros.actuators.motor_controller import MotorController
from tiannara_pros.actuators.command_safety import validate_and_clip
from tiannara_pros.actuators.retry_controller import RetryController
from tiannara_pros.actuators.actuator_memory import ActuatorMemory


CORE_VERSION = "1.0.0"


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

    # Day 14 runtime-configured filters
    action_layer.smooth_alpha = cfg["filters"]["smooth_alpha"]
    action_layer.rate_limit_max_delta = cfg["filters"]["rate_limit_max_delta"]

    sim = ProstheticSimulator()

    inp = EMGInput()
    out = ConsoleOutput()
    motor = MotorController()
    retry = RetryController(max_retries=2)

    # Day 15 actuator memory
    act_mem = ActuatorMemory(bias_alpha=cfg["actuator_memory"]["bias_alpha"])

    # Day 19 logger
    logger = JsonlLogger("runs/day10c_pipeline.jsonl")

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

    print("\n=== Day 10C Pros Pipeline (Day 18–20) ===\n")

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

        # Day 12.2C runtime confidence gate
        if decision["confidence"] < cfg["safety"]["min_confidence"]:
            decision["_min_confidence_gate"] = True
            decision["intent"] = cfg["safety"]["fallback_intent"]
            decision["confidence"] = 0.0
            decision["reason"] = "min_confidence → safety fallback"
        else:
            decision["_min_confidence_gate"] = False

        # Action
        action = action_layer.intent_to_action(
            decision["intent"], decision["confidence"], tags
        )

        sim.update_fatigue(decision["intent"], dt=cfg["loop"]["dt"])

        # Build action packet (schema wrapper)
        action_packet = build_action_packet(
            action=action,
            decision=decision,
            context_tags=tags,
            emg=packet.get("emg", {}),
            fatigue=sim.fatigue,
        )

        # Add core version (useful for replay/debug)
        action_packet["core_version"] = CORE_VERSION

        # Day 15: apply actuator-memory bias BEFORE retry loop
        memory_used = act_mem.has_memory(action_packet["command"])
        action_packet["command"] = act_mem.apply_bias(action_packet["command"])
        action_packet["safety"]["actuator_memory_used"] = bool(memory_used)

        # Day 13 + Day 18: retry loop (closed-loop corrections inside)
        final_cmd, fb, retries_used = retry.run_retry_loop(
            motor=motor,
            command=action_packet["command"],
            validate_and_clip_fn=validate_and_clip,
            cfg=cfg,
            debug=False,  # set True if you want retry prints
        )

        action_packet["command"] = final_cmd
        action_packet["feedback"] = fb
        action_packet["safety"]["retries_used"] = retries_used
        action_packet["safety"]["retry_exhausted"] = (
            fb.get("success") is False and retries_used >= retry.max_retries
        )

        outcome = feedback_to_outcome(fb)

        # Day 16: feedback learning -> SkillMemory update
        updated_bias = skill.update(
            intent=decision["intent"],
            context_tags=tags,
            outcome=outcome,
            metrics=fb.get("metrics", {}) if fb else {},
        )
        skill.decay_step()
        action_packet["safety"]["skill_bias_updated"] = updated_bias

        # Day 15: update actuator-memory if success
        updated = act_mem.update_from_feedback(final_cmd, fb)
        action_packet["safety"]["actuator_memory_updated"] = bool(updated)

        # Store outcome (episodic)
        memory.store_outcome(tags, decision["intent"], decision["confidence"], outcome)

        # Reinforce/penalize chosen pattern
        chosen = decision.get("chosen_pattern")
        if chosen and chosen.get("type") == "pattern":
            delta = +0.05 if outcome == "good" else -0.05
            memory.adjust_pattern_importance(
                chosen.get("data", {}).get("intent"),
                chosen.get("tags", []),
                delta,
            )

        # Console summary
        print("OUTCOME:", outcome)
        print("RETRIES_USED:", retries_used)
        print("SUCCESS:", fb.get("success"))
        print("ACT_MEM_USED:", action_packet["safety"].get("actuator_memory_used"))
        print("ACT_MEM_UPDATED:", action_packet["safety"].get("actuator_memory_updated"))
        print("SKILL_UPDATE:", updated_bias)

        # Output sinks
        out.send(action_packet)
        logger.log(action_packet)

    print("\nDone.")


if __name__ == "__main__":
    main()