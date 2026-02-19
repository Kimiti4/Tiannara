# mindcache/orchestrator.py (Day 4)

from tiannara_core.memory.memory_engine import MemoryEngine
from tiannara_core.cognition.context_processor import ContextProcessor

def main():
    memory = MemoryEngine()
    processor = ContextProcessor()

    fake_input = [
        {'joint_angles': [10, 20, 30], 'intent': 'grip', 'tags': ['hand', 'precision']},
        {'joint_angles': [12, 18, 33], 'intent': 'release', 'tags': ['hand']},
        {'joint_angles': [15, 22, 35], 'intent': 'stabilize', 'tags': ['balance']},
    ]

    # Store memories (once each) with tags
    for data in fake_input:
        context = processor.process(data)
        memory.store(context, tags=data.get("tags", []))

    print("\n--- Initial Memory Store ---")
    for i, m in enumerate(memory.memory_store):
        print(i, m)

    # Simulate “usage”: user keeps doing grip, so we reinforce grip memories
    # We find the indices of memories with intent == "grip"
    grip_indices = [
        i for i, m in enumerate(memory.memory_store)
        if m["data"].get("intent") == "grip"
    ]

    # Reinforce those memories a few times
    for _ in range(3):
        for idx in grip_indices:
            memory.reinforce_memory(idx, amount=0.7)

    # Decay memories (simulates time passing)
    memory.decay_memories(decay_rate=0.2)

    print("\n--- After Reinforcement & Decay ---")
    for i, m in enumerate(memory.memory_store):
        print(i, m)

    precision_context = memory.recall_by_context(["precision"])
    balance_context = memory.recall_by_context(["balance"])

    print("\nPrecision Context:", [m["data"]["intent"] for m in precision_context])
    print("Balance Context:", [m["data"]["intent"] for m in balance_context])

if __name__ == "__main__":
    main()

#reinforces whichever intent appears most

#decays correctly

#prints “before vs after”

#doesn’t duplicate memory stores