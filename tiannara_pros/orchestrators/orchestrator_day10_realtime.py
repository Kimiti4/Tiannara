import time

from tiannara_core.memory.memory_engine import MemoryEngine
from tiannara_core.cognition.context_processor import ContextProcessor
from tiannara_core.memory.consolidator import MemoryConsolidator
from tiannara_core.cognition.decision_engine import DecisionEngine
from tiannara_core.action.action_layer import ActionLayer
from tiannara_core.sim.simulator import ProstheticSimulator


def main():
    memory = MemoryEngine()
    processor = ContextProcessor()
    consolidator = MemoryConsolidator()
    decider = DecisionEngine(min_confidence=0.30, safety_fallback_intent="stabilize")
    action_layer = ActionLayer()
    sim = ProstheticSimulator()

    dt = 0.05  # 50ms (20Hz loop)

    # Training episodes (build patterns)
    base_input = [
        {"joint_angles": [10, 20, 30], "intent": "grip", "tags": ["hand", "precision"]},
        {"joint_angles": [15, 22, 35], "intent": "stabilize", "tags": ["balance"]},
        {"joint_angles": [12, 18, 33], "intent": "release", "tags": ["hand"]},
    ]

    for _ in range(12):
        for d in base_input:
            noisy_angles = sim.add_tremor(d["joint_angles"], intensity=1.2)
            data = dict(d)
            data["joint_angles"] = noisy_angles

            context = processor.process(data)

            if "stability" in context:
                context["stability"] = max(0.0, context["stability"] - sim.stability_penalty())

            memory.store(context, tags=data.get("tags", []))

    patterns = consolidator.consolidate(memory.memory_store)
    for p in patterns:
        memory.store_pattern(p)

    # Real-time contexts stream (simulated)
    context_stream = (
        [["precision"]] * 10 +
        [["hand"]] * 6 +
        [["balance"]] * 8 +
        [["unknown"]] * 6 +
        [["precision"]] * 8
    )

    print("\n=== Day 10A Real-time Loop (20Hz) ===")
    print("steps:", len(context_stream), "dt:", dt, "sec\n")

    for step, ctx in enumerate(context_stream, start=1):
        # Decide + act
        decision = decider.decide(memory.memory_store, ctx)
        action = action_layer.intent_to_action(decision["intent"], decision["confidence"], ctx)

        # Fatigue-aware grip weakening (realism)
        # Debug: ensure targets contain expected keys
        # print("DEBUG action:", action)

        if action.get("mode") == "hand_control" and action.get("intent") == "grip":
            fatigue_factor = max(0.6, 1.0 - (sim.fatigue * 0.4))  # down to 0.6
        if "grip_force" in action.get("targets", {}):
            action["targets"]["grip_force"] *= fatigue_factor


        # Update fatigue using dt
        sim.update_fatigue(decision["intent"], dt=dt)

        # Telemetry print
        print(f"Step {step:02d} | ctx={ctx} | intent={decision['intent']} "
              f"| conf={decision['confidence']:.2f} | fatigue={sim.fatigue:.2f} "
              f"| targets={action['targets']}")

        time.sleep(dt)

    print("\nDone.")


if __name__ == "__main__":
    main()
