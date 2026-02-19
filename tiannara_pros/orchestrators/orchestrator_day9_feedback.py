from tiannara_core.memory.memory_engine import MemoryEngine
from tiannara_core.cognition.context_processor import ContextProcessor
from tiannara_core.memory.consolidator import MemoryConsolidator
from tiannara_core.cognition.decision_engine import DecisionEngine
from tiannara_core.action.action_layer import ActionLayer


def simulate_outcome(intent, action_targets):
    if intent == "grip":
        gf = action_targets.get("grip_force", 0.0)
        d = action_targets.get("damping", 0.0)
        return "good" if (0.15 <= d <= 0.6 and gf <= 0.7) else "bad"

    if intent == "stabilize":
        d = action_targets.get("damping", 0.0)
        return "good" if d >= 0.3 else "bad"

    if intent == "release":
        return "good"

    return "bad"


def main():
    memory = MemoryEngine()
    processor = ContextProcessor()
    consolidator = MemoryConsolidator()
    decider = DecisionEngine(min_confidence=0.30, safety_fallback_intent="stabilize")
    action_layer = ActionLayer()

    # --- Training experiences ---
    fake_input = [
        {"joint_angles": [10, 20, 30], "intent": "grip", "tags": ["hand", "precision"]},
        {"joint_angles": [11, 21, 31], "intent": "grip", "tags": ["hand", "precision"]},
        {"joint_angles": [15, 22, 35], "intent": "stabilize", "tags": ["balance"]},
        {"joint_angles": [12, 18, 33], "intent": "release", "tags": ["hand"]},
    ]

    for data in fake_input:
        context = processor.process(data)
        memory.store(context, tags=data.get("tags", []))

    # --- Consolidate to patterns ---
    patterns = consolidator.consolidate(memory.memory_store)
    for p in patterns:
        memory.store_pattern(p)

    test_contexts = [["precision"], ["balance"], ["hand"], ["unknown"]]

    # --- Feedback learning loop ---
    for step in range(1, 6):
        print(f"\n===== FEEDBACK LOOP STEP {step} =====")

        for ctx in test_contexts:
            decision = decider.decide(memory.memory_store, ctx)
            action = action_layer.intent_to_action(
                decision["intent"], decision["confidence"], ctx
            )

            outcome = simulate_outcome(decision["intent"], action["targets"])
            memory.store_outcome(ctx, decision["intent"], decision["confidence"], outcome)

            # Context-aware reinforcement
            if decision.get("chosen_pattern"):
                chosen = decision["chosen_pattern"]
                chosen_intent = chosen["data"]["intent"]
                chosen_tags = chosen.get("tags", [])

                context_match = any(t in chosen_tags for t in ctx)

                if context_match:
                    delta = 0.1 * decision["confidence"]
                    if outcome == "good":
                        memory.adjust_pattern_importance(
                            chosen_intent, chosen_tags, delta=+delta
                        )
                    else:
                        memory.adjust_pattern_importance(
                            chosen_intent, chosen_tags, delta=-delta
                        )

            print(f"\nContext: {ctx}")
            print("Decision:", decision["intent"], "Conf:", f"{decision['confidence']:.2f}")
            print("Outcome:", outcome)
            print("Action:", action)

    # --- Final pattern state ---
    print("\n--- Final Pattern Importances ---")
    for m in memory.memory_store:
        if m.get("type") == "pattern":
            print(
                m["data"]["intent"],
                m["tags"],
                "importance=",
                round(m["importance"], 3),
                "count=",
                m.get("count"),
            )


if __name__ == "__main__":
    main()
