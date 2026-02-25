from tiannara_core.action.control_adapter import apply_closed_loop_adjustments


class ActionLayer:
    """
    Converts high-level intent into low-level, prosthetic-safe control targets.
    Applies smoothing + rate limiting (Day 14).
    Applies closed-loop adjustments using previous feedback (Day 17).
    """

    def __init__(self):
        # Default safe limits
        self.max_grip_force = 1.0
        self.max_stiffness = 1.0
        self.max_damping = 1.0

        # Filter state
        self.prev_targets = {}

        # Runtime-configurable filters (set by orchestrator)
        self.smooth_alpha = 0.6
        self.rate_limit_max_delta = 0.06

    # ---------- Filters ----------

    def smooth_targets(self, targets, alpha=0.6):
        """
        Exponential smoothing.
        alpha closer to 1.0 = smoother (slower changes).
        """
        smoothed = {}
        for k, v in targets.items():
            prev = self.prev_targets.get(k, v)
            smoothed[k] = alpha * prev + (1 - alpha) * v
        self.prev_targets = dict(smoothed)
        return smoothed

    def rate_limit_targets(self, targets, max_delta=0.06):
        """
        Rate limits per-step change to prevent jerk.
        """
        limited = {}
        for k, v in targets.items():
            prev = self.prev_targets.get(k, v)
            dv = v - prev

            if dv > max_delta:
                v = prev + max_delta
            elif dv < -max_delta:
                v = prev - max_delta

            limited[k] = v

        self.prev_targets = dict(limited)
        return limited

    def _apply_filters(self, targets):
        targets = self.smooth_targets(targets, alpha=self.smooth_alpha)
        targets = self.rate_limit_targets(targets, max_delta=self.rate_limit_max_delta)
        return targets

    # ---------- Intent Mapping ----------

    def intent_to_action(self, intent, confidence, context_tags=None, cfg=None, prev_feedback=None):
        context_tags = context_tags or []

        # Safety scaling
        scale = max(0.2, min(1.0, confidence))

        # ---- GRIP ----
        if intent == "grip":
            if "precision" in context_tags:
                grip_force = 0.45 * scale
                stiffness = 0.75 * scale
            else:
                grip_force = 0.65 * scale
                stiffness = 0.55 * scale

            result = {
                "mode": "hand_control",
                "intent": intent,
                "targets": {
                    "grip_force": min(self.max_grip_force, grip_force),
                    "stiffness": min(self.max_stiffness, stiffness),
                    "damping": 0.35 * scale,
                },
            }

            result["targets"] = self._apply_filters(result["targets"])

            # ✅ Day 17 closed-loop (uses previous feedback)
            if cfg is not None:
                result = apply_closed_loop_adjustments(result, prev_feedback, cfg)

            return result

        # ---- RELEASE ----
        if intent == "release":
            result = {
                "mode": "hand_control",
                "intent": intent,
                "targets": {
                    "grip_force": 0.0,
                    "stiffness": 0.25 * scale,
                    "damping": 0.25 * scale,
                },
            }

            result["targets"] = self._apply_filters(result["targets"])

            # ✅ Day 17 closed-loop
            if cfg is not None:
                result = apply_closed_loop_adjustments(result, prev_feedback, cfg)

            return result

        # ---- STABILIZE ----
        if intent == "stabilize":
            # runtime config floors (Day 14 / Day 17)
            stab_cfg = (cfg or {}).get("stabilization", {})
            stabilize_floor = float(stab_cfg.get("stabilize_scale_floor", 0.5))
            unknown_floor = float(stab_cfg.get("unknown_scale_floor", 0.7))

            stabilize_scale = max(stabilize_floor, min(1.0, confidence))
            if "unknown" in context_tags:
                stabilize_scale = max(stabilize_scale, unknown_floor)

            result = {
                "mode": "stabilization",
                "intent": intent,
                "targets": {
                    "damping": min(self.max_damping, 0.85 * stabilize_scale),
                    "correction_gain": 0.75 * stabilize_scale,
                    "tremor_filter": 0.70 * stabilize_scale,
                },
            }

            result["targets"] = self._apply_filters(result["targets"])

            # ✅ Day 17 closed-loop
            if cfg is not None:
                result = apply_closed_loop_adjustments(result, prev_feedback, cfg)

            return result

        # ---- SAFE IDLE ----
        result = {
            "mode": "safe_idle",
            "intent": "idle",
            "targets": {
                "grip_force": 0.0,
                "stiffness": 0.20,
                "damping": 0.40,
            },
        }

        result["targets"] = self._apply_filters(result["targets"])

        # ✅ Day 17 closed-loop
        if cfg is not None:
            result = apply_closed_loop_adjustments(result, prev_feedback, cfg)

        return result