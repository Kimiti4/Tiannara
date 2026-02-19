from tiannara_core.memory.memory_engine import MemoryEngine
from tiannara_core.cognition.context_processor import ContextProcessor
from tiannara_core.memory.consolidator import MemoryConsolidator
from tiannara_core.cognition.decision_engine import DecisionEngine


def main():
    memory = MemoryEngine()
    processor = ContextProcessor()
    consolidator = MemoryConsolidator()
    decider = DecisionEngine()

    # Simulated experiences (episodic)
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

    # Consolidate -> pattern memories
    patterns = consolidator.consolidate(memory.memory_store)
    for p in patterns:
        memory.store_pattern(p)

    # Test two contexts
    for context_tags in [["precision"], ["balance"]]:
        best = decider.select_best_pattern(memory.memory_store, context_tags)

        print(f"\n=== Context: {context_tags} ===")
        if best:
            print("Selected Pattern Memory:")
            print(best)
            print("Suggested intent:", best["data"]["intent"])
        else:
            print("No pattern found.")

if __name__ == "__main__":
    main()
# Decision engine returns a pattern
# Pattern matches context
# Printed “Suggested intent” is correct
# Works for multiple contexts