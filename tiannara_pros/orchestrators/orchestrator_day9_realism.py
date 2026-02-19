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

    # Base experiences
    base_input = [
        {"joint_angles": [10, 20, 30], "intent": "grip", "tags": ["hand", "precision"]},
        {"joint_angles": [15, 22, 35], "intent": "stabilize", "tags": ["balance"]},
        {"joint_angles": [12, 18, 33], "intent": "release", "tags": ["hand"]},
    ]

    # Build episodic memories with tremor noise (realism)
    for _ in range(10):
        for d in base_input:
            noisy_angles = sim.add_tremor(d["joint_angles"], intensity=1.2)
            data = dict(d)
            data["joint_angles"] = noisy_angles

            context = processor.process(data)

            # Apply fatigue penalty to stability if present
            if "stability" in context:
                context["stability"] = max(0.0, context["stability"] - sim.stability_penalty())

            memory.store(context, tags=data.get("tags", []))

    # Consolidate -> patterns
    patterns = consolidator.consolidate(memory.memory_store)
    for p in patterns:
        memory.store_pattern(p)

    # Run a short realistic control session
    session_contexts = [["precision"], ["precision"], ["hand"], ["balance"], ["precision"], ["unknown"]]

    for i, ctx in enumerate(session_contexts, start=1):
        decision = decider.decide(memory.memory_store, ctx)
        action = action_layer.intent_to_action(decision["intent"], decision["confidence"], ctx)
        # Fatigue reduces grip force slightly (realism)
        if action["mode"] == "hand_control" and action["intent"] == "grip":
            fatigue_factor = max(0.6, 1.0 - (sim.fatigue * 0.4))  # down to 0.6
            action["targets"]["grip_force"] *= fatigue_factor

        sim.update_fatigue(decision["intent"])

        print(f"\n--- Step {i} ---")
        print("Context:", ctx)
        print("Decision:", decision["intent"], "Conf:", f"{decision['confidence']:.2f}")
        print("Fatigue:", f"{sim.fatigue:.2f}")
        print("Action:", action)



if __name__ == "__main__":
    main()
