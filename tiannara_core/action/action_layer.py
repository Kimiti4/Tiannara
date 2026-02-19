class ActionLayer:
    """
    Converts high-level intent into low-level, prosthetic-safe control targets.
    This is simulation output only (no hardware actuation).
    """

    def __init__(self):
        # Default safe limits (tune later)
        self.max_grip_force = 1.0      # normalized 0..1
        self.max_stiffness = 1.0       # normalized 0..1
        self.max_damping = 1.0         # normalized 0..1
        self.prev_targets = {}
    def smooth_targets(self, targets, alpha=0.6):
        """
        Exponential smoothing to prevent sudden jumps.
        alpha closer to 1.0 = smoother (slower changes).
        """
        smoothed = {}
        for k, v in targets.items():
            prev = self.prev_targets.get(k, v)
            smoothed[k] = alpha * prev + (1 - alpha) * v
        self.prev_targets = smoothed
        return smoothed
    def rate_limit_targets(self, targets, max_delta=0.06):
        """
        Limits how fast each target can change per step.
        max_delta is per loop step (not per second).
        """
        limited = {}
        for k, v in targets.items():
            prev = self.prev_targets.get(k, v)
            delta = v - prev

            if delta > max_delta:
                v = prev + max_delta
            elif delta < -max_delta:
                v = prev - max_delta

            limited[k] = v

        return limited

    def intent_to_action(self, intent, confidence, context_tags=None):
        context_tags = context_tags or []

        # Safety scaling: low confidence -> softer outputs
        scale = max(0.2, min(1.0, confidence))

        if intent == "grip":
            # precision grip -> slightly lower force, higher stiffness
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
                }
            }
            result["targets"] = self.rate_limit_targets(result["targets"], max_delta=0.06)

            result["targets"] = self.smooth_targets(result["targets"])
            return result


        if intent == "release":
            result = {
                "mode": "hand_control",
                "intent": intent,
                "targets": {
                    "grip_force": 0.0,
                    "stiffness": 0.25 * scale,
                    "damping": 0.25 * scale,
                }
            }
            result["targets"] = self.rate_limit_targets(result["targets"], max_delta=0.06)

            result["targets"] = self.smooth_targets(result["targets"])
            return result


        if intent == "stabilize":
            # Stabilization should be strong even when confidence is low (safety action)
            stabilize_scale = max(0.5, min(1.0, confidence))

            # ✅ Extra safety when context is unknown
            if "unknown" in context_tags:
                stabilize_scale = max(stabilize_scale, 0.7)

            result = {
                "mode": "stabilization",
                "intent": intent,
                "targets": {
                    "damping": min(self.max_damping, 0.85 * stabilize_scale),
                    "correction_gain": 0.75 * stabilize_scale,
                    "tremor_filter": 0.70 * stabilize_scale,
                }
            }
            result["targets"] = self.rate_limit_targets(result["targets"], max_delta=0.06)

            result["targets"] = self.smooth_targets(result["targets"])
            return result




        # Unknown intent -> safest output
        result = {
            "mode": "safe_idle",
            "intent": "idle",
            "targets": {
                "grip_force": 0.0,
                "stiffness": 0.20,
                "damping": 0.40,
            }
        }
        result["targets"] = self.rate_limit_targets(result["targets"], max_delta=0.06)

        result["targets"] = self.smooth_targets(result["targets"])
        return result
