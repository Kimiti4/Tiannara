from collections import defaultdict
from statistics import mean

class MemoryConsolidator:
    """
    Groups similar memories and produces pattern summaries.
    For v1: group by intent + tags.
    """

    def consolidate(self, memory_store):
        # key: (intent, sorted_tags) -> list of memories
        buckets = defaultdict(list)

        for m in memory_store:
            intent = m["data"].get("intent", "unknown")
            tags = tuple(sorted(m.get("tags", [])))
            buckets[(intent, tags)].append(m)

        patterns = []
        for (intent, tags), memories in buckets.items():
            stabilities = [
                mm["data"].get("stability")
                for mm in memories
                if mm["data"].get("stability") is not None
            ]
            importances = [mm.get("importance", 1.0) for mm in memories]

            pattern = {
                "intent": intent,
                "tags": list(tags),
                "count": len(memories),
                "avg_importance": mean(importances) if importances else 1.0,
                "avg_stability": mean(stabilities) if stabilities else None,
            }
            patterns.append(pattern)

        # Sort patterns by (count, avg_importance) descending
        patterns.sort(key=lambda p: (p["count"], p["avg_importance"]), reverse=True)
        return patterns
