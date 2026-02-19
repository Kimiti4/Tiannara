class DecisionEngine:
    """
    Decision Engine v2.2 (Day 7/9 safety upgrade)

    Features:
    - Pattern-based decision selection
    - Confidence scoring (separation-based)
    - Confidence boost when at least 1 context tag matches
    - Safety fallback when confidence is low
    - Forced fallback when NO tags match any pattern (safer for unknown contexts)
    - Explanation output (score breakdown)
    """

    def __init__(self, min_confidence=0.30, safety_fallback_intent="stabilize"):
        self.min_confidence = min_confidence
        self.safety_fallback_intent = safety_fallback_intent

    def _score_pattern(self, pattern, context_tags):
        tags = pattern.get("tags", [])
        match_count = sum(1 for t in context_tags if t in tags)

        count = pattern.get("count", 1)
        importance = pattern.get("importance", 1.0)
        avg_stability = pattern.get("data", {}).get("avg_stability", 0.0) or 0.0

        score = (
            (match_count * 5.0) +
            (count * 1.5) +
            (importance * 1.0) +
            (avg_stability * 0.5)
        )

        breakdown = {
            "match_count": match_count,
            "count": count,
            "importance": importance,
            "avg_stability": avg_stability,
            "score": score,
        }

        return score, breakdown

    def decide(self, memory_store, context_tags):
        patterns = [m for m in memory_store if m.get("type") == "pattern"]

        if not patterns:
            return {
                "intent": self.safety_fallback_intent,
                "confidence": 0.0,
                "reason": "No pattern memories available.",
                "chosen_pattern": None,
                "runner_up": None,
            }

        # Score all patterns
        scored = []
        for p in patterns:
            score, breakdown = self._score_pattern(p, context_tags)
            scored.append((score, p, breakdown))

        scored.sort(key=lambda x: x[0], reverse=True)

        best_score, best_pattern, best_breakdown = scored[0]
        runner_up = scored[1] if len(scored) > 1 else None

        # Separation-based confidence
        if runner_up:
            second_score = runner_up[0]
            confidence = max(
                0.0,
                min(1.0, (best_score - second_score) / (best_score + 1e-9))
            )
        else:
            confidence = 1.0

        # Boost confidence if at least 1 tag match
        if best_breakdown["match_count"] > 0:
            confidence = min(1.0, confidence + 0.20)

        # ✅ Forced safety: if NOTHING matches context tags, fallback immediately
        if best_breakdown["match_count"] == 0:
            return {
                "intent": self.safety_fallback_intent,
                "confidence": confidence,
                "reason": "No tag match → safety fallback.",
                "chosen_pattern": best_pattern,
                "chosen_breakdown": best_breakdown,
                "runner_up": runner_up[1] if runner_up else None,
                "runner_up_breakdown": runner_up[2] if runner_up else None,
            }

        chosen_intent = best_pattern.get("data", {}).get("intent", "unknown")

        # Normal safety gate: low confidence fallback
        if confidence < self.min_confidence:
            return {
                "intent": self.safety_fallback_intent,
                "confidence": confidence,
                "reason": f"Low confidence ({confidence:.2f}) → safety fallback.",
                "chosen_pattern": best_pattern,
                "chosen_breakdown": best_breakdown,
                "runner_up": runner_up[1] if runner_up else None,
                "runner_up_breakdown": runner_up[2] if runner_up else None,
            }

        return {
            "intent": chosen_intent,
            "confidence": confidence,
            "reason": "Best matching pattern selected.",
            "chosen_pattern": best_pattern,
            "chosen_breakdown": best_breakdown,
            "runner_up": runner_up[1] if runner_up else None,
            "runner_up_breakdown": runner_up[2] if runner_up else None,
        }
