from tiannara_core.memory.memory_engine import MemoryEngine
from tiannara_core.cognition.context_processor import ContextProcessor
from tiannara_core.memory.consolidator import MemoryConsolidator


def main():
    memory = MemoryEngine()
    processor = ContextProcessor()
    consolidator = MemoryConsolidator()

    # Simulated repeated prosthetic experiences
    fake_input = [
        {"joint_angles": [10, 20, 30], "intent": "grip", "tags": ["hand", "precision"]},
        {"joint_angles": [11, 21, 31], "intent": "grip", "tags": ["hand", "precision"]},
        {"joint_angles": [9, 19, 29], "intent": "grip", "tags": ["hand", "precision"]},
        {"joint_angles": [15, 22, 35], "intent": "stabilize", "tags": ["balance"]},
        {"joint_angles": [16, 23, 36], "intent": "stabilize", "tags": ["balance"]},
        {"joint_angles": [12, 18, 33], "intent": "release", "tags": ["hand"]},
    ]

    # Store memories
    for data in fake_input:
        context = processor.process(data)
        memory.store(context, tags=data.get("tags", []))

    print("\n--- Raw Memories (sample) ---")
    for m in memory.memory_store[:6]:
        print(m)

    # Consolidate into patterns
    patterns = consolidator.consolidate(memory.memory_store)

    print("\n--- Consolidated Patterns ---")
    for p in patterns:
        print(p)

    # Optional: store patterns back into memory
    for p in patterns:
         memory.store_pattern(p)

    print("\n--- Stored Pattern Memories ---")
    for m in memory.memory_store:
        if m.get("type") == "pattern":
            print(m)


if __name__ == "__main__":
    main()
#“Grip with precision happens a lot (count 3) and has typical stability ~0.33”

#“Stabilize happens sometimes (count 2) with stability ~0.31”

#“Release happens less (count 1) with stability ~0.22