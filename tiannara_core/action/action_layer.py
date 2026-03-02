# tiannara_core/action/action_layer.py
from __future__ import annotations
from typing import Dict, Any, List, Optional

from tiannara_core.action.control_adapter import apply_closed_loop_adjustments


class ActionLayer:
    """
    Converts high-level intent into low-level, prosthetic-safe control targets.

    Day 14:
      - smoothing + rate limiting filters

    Day 18:
      - closed-loop next-step shaping using previous actuator feedback
        (via apply_closed_loop_adjustments)

    Runtime config:
      - max limits
      - filter params
      - stabilize floors
      - closed_loop thresholds/steps
    """

    def __init__(self):
        # Default safe limits (can be overridden by cfg at runtime)
        self.max_grip_force = 1.0
        self.max_stiffness = 1.0
        self.max_damping = 1.0

        # Filter state
        self.prev_targets: Dict[str, float] = {}

        # Filter params (can be overridden by cfg at runtime)
        self.smooth_alpha = 0.6
        self.rate_limit_max_delta = 0.06

        # Stabilize scaling floors (can be overridden by cfg at runtime)
        self.stabilize_scale_floor = 0.5
        self.unknown_scale_floor = 0.7

    # ---------- Config ingestion ----------

    def apply_runtime_config(self, cfg: Optional[Dict[str, Any]]):
        if not cfg:
            return

        # Max limits
        hc = cfg.get("hand_control", {}) or {}
        self.max_grip_force = float(hc.get("max_grip_force", self.max_grip_force))
        self.max_stiffness = float(hc.get("max_stiffness", self.max_stiffness))
        self.max_damping = float(hc.get("max_damping", self.max_damping))

        # Stabilize floors
        stab = cfg.get("stabilization", {}) or {}
        self.stabilize_scale_floor = float(stab.get("stabilize_scale_floor", self.stabilize_scale_floor))
        self.unknown_scale_floor = float(stab.get("unknown_scale_floor", self.unknown_scale_floor))

        # Filters
        filt = cfg.get("filters", {}) or {}
        self.smooth_alpha = float(filt.get("smooth_alpha", self.smooth_alpha))
        self.rate_limit_max_delta = float(filt.get("rate_limit_max_delta", self.rate_limit_max_delta))

    # ---------- Filters ----------

    def smooth_targets(self, targets: Dict[str, float], alpha: float) -> Dict[str, float]:
        smoothed: Dict[str, float] = {}
        for k, v in targets.items():
            prev = self.prev_targets.get(k, float(v))
            smoothed[k] = alpha * float(prev) + (1.0 - alpha) * float(v)
        self.prev_targets = dict(smoothed)
        return smoothed

    def rate_limit_targets(self, targets: Dict[str, float], max_delta: float) -> Dict[str, float]:
        limited: Dict[str, float] = {}
        for k, v in targets.items():
            prev = self.prev_targets.get(k, float(v))
            dv = float(v) - float(prev)

            if dv > max_delta:
                v = float(prev) + max_delta
            elif dv < -max_delta:
                v = float(prev) - max_delta

            limited[k] = float(v)

        self.prev_targets = dict(limited)
        return limited

    def _apply_filters(self, targets: Dict[str, float]) -> Dict[str, float]:
        targets = self.smooth_targets(targets, alpha=self.smooth_alpha)
        targets = self.rate_limit_targets(targets, max_delta=self.rate_limit_max_delta)
        return targets

    # ---------- Intent Mapping ----------

    def intent_to_action(
        self,
        intent: str,
        confidence: float,
        context_tags: Optional[List[str]] = None,
        cfg: Optional[Dict[str, Any]] = None,
        prev_feedback: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        cfg: runtime config dict (limits.json)
        prev_feedback: previous actuator feedback dict (Day 18 shaping)
        """
        context_tags = context_tags or []
        self.apply_runtime_config(cfg)

        # Safety scaling
        scale = max(0.2, min(1.0, float(confidence)))

        # ---- GRIP ----
        if intent == "grip":
            if "precision" in context_tags:
                grip_force = 0.45 * scale
                stiffness = 0.75 * scale
            else:
                grip_force = 0.65 * scale
                stiffness = 0.55 * scale

            cmd = {
                "mode": "hand_control",
                "intent": intent,
                "targets": {
                    "grip_force": min(self.max_grip_force, grip_force),
                    "stiffness": min(self.max_stiffness, stiffness),
                    "damping": 0.35 * scale,
                },
            }

            # Day 18: shape next-step command using previous feedback
            cmd = apply_closed_loop_adjustments(cmd, prev_feedback, cfg)

            # Day 14 filters
            cmd["targets"] = self._apply_filters(cmd["targets"])
            return cmd

        # ---- RELEASE ----
        if intent == "release":
            cmd = {
                "mode": "hand_control",
                "intent": intent,
                "targets": {
                    "grip_force": 0.0,
                    "stiffness": 0.25 * scale,
                    "damping": 0.25 * scale,
                },
            }

            cmd = apply_closed_loop_adjustments(cmd, prev_feedback, cfg)
            cmd["targets"] = self._apply_filters(cmd["targets"])
            return cmd

        # ---- STABILIZE ----
        if intent == "stabilize":
            stabilize_scale = max(self.stabilize_scale_floor, min(1.0, float(confidence)))

            if "unknown" in context_tags:
                stabilize_scale = max(stabilize_scale, self.unknown_scale_floor)

            cmd = {
                "mode": "stabilization",
                "intent": intent,
                "targets": {
                    "damping": min(self.max_damping, 0.85 * stabilize_scale),
                    "correction_gain": 0.75 * stabilize_scale,
                    "tremor_filter": 0.70 * stabilize_scale,
                },
            }

            cmd = apply_closed_loop_adjustments(cmd, prev_feedback, cfg)
            cmd["targets"] = self._apply_filters(cmd["targets"])
            return cmd

        # ---- SAFE IDLE ----
        cmd = {
            "mode": "safe_idle",
            "intent": "idle",
            "targets": {
                "grip_force": 0.0,
                "stiffness": 0.20,
                "damping": 0.40,
            },
        }

        cmd["targets"] = self._apply_filters(cmd["targets"])
        return cmd