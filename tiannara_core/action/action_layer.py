class ActionLayer:
    """
    Converts high-level intent into low-level, prosthetic-safe control targets.
    Simulation output only (no hardware actuation).

    Includes:
    - per-mode smoothing (prevents stabilize->grip bleed)
    - per-mode rate limiting (prevents sudden jumps)
    """

    def __init__(self):
        self.max_grip_force = 1.0
        self.max_stiffness = 1.0
        self.max_damping = 1.0

        # Per-mode previous targets
        self.prev_targets_by_mode = {
            "hand_control": {},
            "stabilization": {},
            "safe_idle": {},
        }

    def smooth_targets(self, mode, targets, alpha=0.6):
        prev_targets = self.prev_targets_by_mode.get(mode, {})
        smoothed = {}

        for k, v in targets.items():
            prev = prev_targets.get(k, v)
            smoothed[k] = alpha * prev + (1 - alpha) * v

        self.prev_targets_by_mode[mode] = smoothed
        return smoothed

    def rate_limit_targets(self, mode, targets, max_delta=0.06):
        prev_targets = self.prev_targets_by_mode.get(mode, {})
        limited = {}

        for k, v in targets.items():
            prev = prev_targets.get(k, v)
            delta = v - prev

            if delta > max_delta:
                v = prev + max_delta
            elif delta < -max_delta:
                v = prev - max_delta

            limited[k] = v

        return limited

    def _post_process(self, mode, targets):
        targets = self.rate_limit_targets(mode, targets, max_delta=0.06)
        targets = self.smooth_targets(mode, targets, alpha=0.6)
        return targets

    def intent_to_action(self, intent, confidence, context_tags=None):
        context_tags = context_tags or []

        # Low confidence -> softer outputs
        scale = max(0.2, min(1.0, float(confidence)))

        if intent == "grip":
            if "precision" in context_tags:
                grip_force = 0.45 * scale
                stiffness = 0.75 * scale
                damping = 0.35 * scale
            else:
                grip_force = 0.65 * scale
                stiffness = 0.55 * scale
                damping = 0.35 * scale

            targets = {
                "grip_force": min(self.max_grip_force, grip_force),
                "stiffness": min(self.max_stiffness, stiffness),
                "damping": min(self.max_damping, damping),
            }
            targets = self._post_process("hand_control", targets)
            return {"mode": "hand_control", "intent": intent, "targets": targets}

        if intent == "release":
            targets = {
                "grip_force": 0.0,
                "stiffness": min(self.max_stiffness, 0.25 * scale),
                "damping": min(self.max_damping, 0.25 * scale),
            }
            targets = self._post_process("hand_control", targets)
            return {"mode": "hand_control", "intent": intent, "targets": targets}

        if intent == "stabilize":
            stabilize_scale = max(0.5, min(1.0, float(confidence)))
            if "unknown" in context_tags:
                stabilize_scale = max(stabilize_scale, 0.7)

            targets = {
                "damping": min(self.max_damping, 0.85 * stabilize_scale),
                "correction_gain": 0.75 * stabilize_scale,
                "tremor_filter": 0.70 * stabilize_scale,
            }
            targets = self._post_process("stabilization", targets)
            return {"mode": "stabilization", "intent": intent, "targets": targets}

        # Safest fallback
        targets = {"grip_force": 0.0, "stiffness": 0.20, "damping": 0.40}
        targets = self._post_process("safe_idle", targets)
        return {"mode": "safe_idle", "intent": "idle", "targets": targets}
