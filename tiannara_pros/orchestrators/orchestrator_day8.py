from tiannara_core.memory.memory_engine import MemoryEngine
from tiannara_core.cognition.context_processor import ContextProcessor
from tiannara_core.memory.consolidator import MemoryConsolidator
from tiannara_core.cognition.decision_engine import DecisionEngine
from tiannara_core.action.action_layer import ActionLayer


def main():
    memory = MemoryEngine()
    processor = ContextProcessor()
    consolidator = MemoryConsolidator()
    decider = DecisionEngine(min_confidence=0.30, safety_fallback_intent="stabilize")
    action_layer = ActionLayer()

    # Training experiences (episodic)
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

    # Consolidate -> store patterns
    patterns = consolidator.consolidate(memory.memory_store)
    for p in patterns:
        memory.store_pattern(p)

    # Test contexts → decision → action output
    test_contexts = [
        ["precision"],
        ["balance"],
        ["hand"],
        ["unknown"]
    ]

    for ctx in test_contexts:
        decision = decider.decide(memory.memory_store, ctx)
        action = action_layer.intent_to_action(
            intent=decision["intent"],
            confidence=decision["confidence"],
            context_tags=ctx
        )

        print(f"\n=== Context: {ctx} ===")
        print(f"Decision: {decision['intent']} | Confidence: {decision['confidence']:.2f}")
        print("Action Output:", action)


if __name__ == "__main__":
    main()

#Context
 # ↓
#Memory (episodic + pattern)
 # ↓
#Decision (with confidence + explanation)
 # ↓
#Action output (safe, bounded, explainable)
