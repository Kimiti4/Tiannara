# mindcache/orchestrator.py (Pre-Day 4)

from tiannara_core.memory.memory_engine import MemoryEngine
from tiannara_core.cognition.context_processor import ContextProcessor

def main():
    memory = MemoryEngine()
    processor = ContextProcessor()

    # Simulated prosthetic input
    fake_input = [
        {'joint_angles': [10, 20, 30], 'intent': 'grip', 'tags': ['hand', 'precision']},
        {'joint_angles': [12, 18, 33], 'intent': 'release', 'tags': ['hand']},
        {'joint_angles': [15, 22, 35], 'intent': 'stabilize', 'tags': ['balance']},
    ]

    # Store memories with tags
    for data in fake_input:
        context = processor.process(data)
        memory.store(context, tags=data.get("tags", []))

    print("\n--- Memory Store ---")
    for m in memory.memory_store:
        print(m)

    # Optional: contextual recall (Day 3 feature)
    precision_context = memory.recall_by_context(["precision"])
    balance_context = memory.recall_by_context(["balance"])

    print("\nPrecision Context:", [m["data"]["intent"] for m in precision_context])
    print("Balance Context:", [m["data"]["intent"] for m in balance_context])

if __name__ == "__main__":
    main()
