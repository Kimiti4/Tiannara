class DecisionEngine:
    """
    Decision Engine v2.2

    Features:
    - Pattern-based decision selection
    - Scoring + breakdown for explainability
    - Confidence scoring (separation-based)
    - Confidence boost when there is at least 1 tag match
    - Hard fallback when there is NO tag match at all
    - Safety fallback when confidence is below min_confidence
    - Optional SkillMemory bias
    - Adds chosen_breakdown["matched"] = True/False
    """

    def __init__(self, min_confidence=0.30, safety_fallback_intent="stabilize", skill_memory=None):
        self.min_confidence = float(min_confidence)
        self.safety_fallback_intent = safety_fallback_intent
        self.skill_memory = skill_memory

    def _get_skill_bias(self, intent, context_tags):
        if not self.skill_memory:
            return 0.0

        for name in ("bias", "get_bias", "bias_for", "score_bias"):
            fn = getattr(self.skill_memory, name, None)
            if callable(fn):
                try:
                    return float(fn(intent, context_tags))
                except TypeError:
                    try:
                        return float(fn(intent))
                    except Exception:
                        return 0.0
                except Exception:
                    return 0.0
        return 0.0

    def _score_pattern(self, pattern, context_tags):
        tags = pattern.get("tags", [])
        match_count = sum(1 for t in (context_tags or []) if t in tags)

        count = pattern.get("count", 1)
        importance = pattern.get("importance", 1.0)

        data = pattern.get("data", {}) or {}
        avg_stability = data.get("avg_stability", 0.0) or 0.0
        intent = data.get("intent", "unknown")

        skill_bias = self._get_skill_bias(intent, context_tags)

        score = (
            (match_count * 3.0) +
            (count * 1.5) +
            (importance * 1.0) +
            (avg_stability * 0.5) +
            (skill_bias * 1.0)
        )

        breakdown = {
            "match_count": match_count,
            "count": count,
            "importance": importance,
            "avg_stability": avg_stability,
            "skill_bias": skill_bias,
            "score": score,
        }
        return score, breakdown

    def decide(self, memory_store, context_tags):
        context_tags = context_tags or []
        patterns = [m for m in memory_store if m.get("type") == "pattern"]

        if not patterns:
            return {
                "intent": self.safety_fallback_intent,
                "confidence": 0.0,
                "reason": "No pattern memories available.",
                "chosen_pattern": None,
                "chosen_breakdown": None,
                "runner_up": None,
                "runner_up_breakdown": None,
            }

        scored = []
        for p in patterns:
            score, breakdown = self._score_pattern(p, context_tags)
            scored.append((score, p, breakdown))

        scored.sort(key=lambda x: x[0], reverse=True)

        best_score, best_pattern, best_breakdown = scored[0]
        runner_up = scored[1] if len(scored) > 1 else None

        # Tag-match flag for downstream logging/feedback logic
        best_breakdown["matched"] = (best_breakdown.get("match_count", 0) > 0)

        # HARD SAFETY: no tag match -> immediate fallback
        if best_breakdown["match_count"] == 0:
            best_breakdown["matched"] = False
            return {
                "intent": self.safety_fallback_intent,
                "confidence": 0.0,
                "reason": "No tag match → safety fallback.",
                "chosen_pattern": best_pattern,
                "chosen_breakdown": best_breakdown,
                "runner_up": runner_up[1] if runner_up else None,
                "runner_up_breakdown": runner_up[2] if runner_up else None,
            }

        # Confidence calculation (separation-based)
        if runner_up:
            second_score = runner_up[0]
            confidence = max(0.0, min(1.0, (best_score - second_score) / (best_score + 1e-9)))
        else:
            confidence = 1.0

        # Confidence boost if at least one tag match
        confidence = min(1.0, confidence + 0.20)

        chosen_intent = best_pattern.get("data", {}).get("intent", "unknown")

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