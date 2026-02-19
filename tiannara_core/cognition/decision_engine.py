"""
tiannara_core/cognition/decision_engine.py

Decision Engine v2.2 (Day 10B)
- Pattern-based intent selection
- Confidence scoring (separation-based)
- Confidence boost if at least 1 context tag matches best pattern
- Hard safety fallback if there is ZERO tag match
- Soft safety fallback if confidence < min_confidence
- Optional SkillMemory bias (online learning signal) to nudge scores
- Returns rich debug/explanation fields for safety + debugging
"""


class DecisionEngine:
    def __init__(self, min_confidence=0.30, safety_fallback_intent="stabilize", skill_memory=None):
        self.min_confidence = float(min_confidence)
        self.safety_fallback_intent = safety_fallback_intent
        self.skill_memory = skill_memory  # optional (tiannara_core/cognition/skill_memory.py)

    def _score_pattern(self, pattern, context_tags):
        """
        Compute a tunable score for a pattern memory given current context tags.
        Pattern memory format (expected):
        {
            "type": "pattern",
            "data": {"intent": "...", "avg_stability": 0.0..1.0},
            "tags": [...],
            "importance": float,
            "count": int
        }
        """
        tags = pattern.get("tags", []) or []
        match_count = sum(1 for t in (context_tags or []) if t in tags)

        count = int(pattern.get("count", 1) or 1)
        importance = float(pattern.get("importance", 1.0) or 1.0)

        avg_stability = pattern.get("data", {}).get("avg_stability", 0.0)
        avg_stability = float(avg_stability or 0.0)

        intent = pattern.get("data", {}).get("intent", "unknown")

        # Optional skill-learning bias (small nudge, never dominates)
        skill_bias = 0.0
        if self.skill_memory is not None:
            try:
                skill_bias = float(self.skill_memory.bias(context_tags or [], intent))
            except Exception:
                skill_bias = 0.0

        # Weighted score (tune later)
        score = (
            (match_count * 3.0) +      # tag match is king
            (count * 1.5) +            # frequency matters
            (importance * 1.0) +       # learned importance matters
            (avg_stability * 0.5) +    # stability nudges
            skill_bias                  # learned skill nudge
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
        """
        Returns dict:
        {
          "intent": "...",
          "confidence": 0..1,
          "reason": "...",
          "chosen_pattern": <pattern mem or None>,
          "chosen_breakdown": {...} or None,
          "runner_up": <pattern mem or None>,
          "runner_up_breakdown": {...} or None
        }
        """
        context_tags = context_tags or []

        patterns = [m for m in (memory_store or []) if m.get("type") == "pattern"]

        # No learned patterns → safest possible behavior
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

        # Score all patterns
        scored = []
        for p in patterns:
            score, breakdown = self._score_pattern(p, context_tags)
            scored.append((score, p, breakdown))

        scored.sort(key=lambda x: x[0], reverse=True)

        best_score, best_pattern, best_breakdown = scored[0]
        runner_up = scored[1] if len(scored) > 1 else None

        # HARD SAFETY: If nothing matches the context at all, force fallback
        if best_breakdown["match_count"] == 0:
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
            # separation ratio in [0..1]
            confidence = (best_score - second_score) / (abs(best_score) + 1e-9)
            confidence = max(0.0, min(1.0, confidence))
        else:
            confidence = 1.0

        # Boost confidence if there is at least 1 tag match
        if best_breakdown["match_count"] > 0:
            confidence = min(1.0, confidence + 0.20)

        chosen_intent = best_pattern.get("data", {}).get("intent", "unknown")

        # SOFT SAFETY: If confidence too low, fallback
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
