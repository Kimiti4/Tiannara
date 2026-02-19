import time


class MemoryEngine:
    def __init__(self):
        self.memory_store = []

    # --- Base storage ---
    def store(self, data, tags=None):
        memory = {
            "timestamp": time.time(),
            "data": data,
            "tags": tags or [],
            "importance": 1.0
        }
        self.memory_store.append(memory)

    def recall_by_context(self, context_tags, top_k=5):
        if not context_tags:
            return []

        filtered = [
            m for m in self.memory_store
            if any(tag in m.get("tags", []) for tag in context_tags)
        ]

        return sorted(filtered, key=lambda x: x.get("importance", 1.0), reverse=True)[:top_k]

    # --- Day 4: reinforcement + decay ---
    def reinforce_memory(self, memory_index, amount=0.5):
        if 0 <= memory_index < len(self.memory_store):
            self.memory_store[memory_index]["importance"] = self.memory_store[memory_index].get("importance", 1.0) + amount

    def decay_memories(self, decay_rate=0.1):
        for m in self.memory_store[:]:
            m["importance"] = m.get("importance", 1.0) - decay_rate
            if m["importance"] <= 0.1:
                self.memory_store.remove(m)

    # --- Day 5: store semantic pattern memories ---
    def store_pattern(self, pattern):
        self.memory_store.append({
            "timestamp": pattern.get("timestamp", None),
            "data": {
                "intent": pattern["intent"],
                "avg_stability": pattern.get("avg_stability")
            },
            "tags": pattern.get("tags", []),
            "importance": pattern.get("avg_importance", 1.0),
            "type": "pattern",
            "count": pattern.get("count", 1)
        })

    # --- Day 9: feedback learning ---
    def adjust_pattern_importance(self, intent, tags, delta):
        tags_set = set(tags)

        for m in self.memory_store:
            if m.get("type") == "pattern":
                same_intent = m.get("data", {}).get("intent") == intent
                same_tags = set(m.get("tags", [])) == tags_set

                if same_intent and same_tags:
                    m["importance"] = max(0.1, m.get("importance", 1.0) + delta)
                    return True

        return False

    def store_outcome(self, context_tags, chosen_intent, confidence, outcome):
        self.memory_store.append({
            "timestamp": time.time(),
            "data": {
                "type": "outcome",
                "chosen_intent": chosen_intent,
                "confidence": confidence,
                "outcome": outcome
            },
            "tags": context_tags,
            "importance": 1.0
        })
