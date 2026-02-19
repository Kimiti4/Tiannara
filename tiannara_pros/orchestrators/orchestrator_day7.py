from tiannara_core.memory.memory_engine import MemoryEngine
from tiannara_core.cognition.context_processor import ContextProcessor
from tiannara_core.memory.consolidator import MemoryConsolidator
from tiannara_core.cognition.decision_engine import DecisionEngine


def main():
    memory = MemoryEngine()
    processor = ContextProcessor()
    consolidator = MemoryConsolidator()

    # Slightly more varied experiences
    fake_input = [
        {"joint_angles": [10, 20, 30], "intent": "grip", "tags": ["hand", "precision"]},
        {"joint_angles": [11, 21, 31], "intent": "grip", "tags": ["hand", "precision"]},
        {"joint_angles": [9, 19, 29], "intent": "grip", "tags": ["hand", "precision"]},
        {"joint_angles": [15, 22, 35], "intent": "stabilize", "tags": ["balance"]},
        {"joint_angles": [16, 23, 36], "intent": "stabilize", "tags": ["balance"]},
        {"joint_angles": [12, 18, 33], "intent": "release", "tags": ["hand"]},
    ]

    # Store episodic memories
    for data in fake_input:
        context = processor.process(data)
        memory.store(context, tags=data.get("tags", []))

    # Consolidate -> store pattern memories
    patterns = consolidator.consolidate(memory.memory_store)
    for p in patterns:
        memory.store_pattern(p)

    # Decision Engine v2
    decider = DecisionEngine(min_confidence=0.30, safety_fallback_intent="stabilize")

    # Test contexts
    test_contexts = [
        ["precision"],
        ["balance"],
        ["hand"],                 # more ambiguous
        ["precision", "balance"], # conflicting context on purpose
        ["unknown"],              # no match
    ]

    for ctx in test_contexts:
        decision = decider.decide(memory.memory_store, ctx)

        print(f"\n=== Context: {ctx} ===")
        print(f"Decision: {decision['intent']} | Confidence: {decision['confidence']:.2f}")
        print("Reason:", decision["reason"])

        if decision.get("chosen_pattern"):
            print("Chosen pattern intent:", decision["chosen_pattern"]["data"]["intent"])
            print("Chosen breakdown:", decision.get("chosen_breakdown"))

        if decision.get("runner_up"):
            print("Runner-up intent:", decision["runner_up"]["data"]["intent"])
            print("Runner-up breakdown:", decision.get("runner_up_breakdown"))


if __name__ == "__main__":
    main()

# It selects the correct intent for clear contexts:

    #['precision'] → grip

    #['hand'] → grip

# It explains the choice with score breakdowns

# It uses a safety fallback when the context is ambiguous/unknown

# The dev container environment is running it cleanly