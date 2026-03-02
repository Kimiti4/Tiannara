# tiannara_core/action/control_adapter.py

from __future__ import annotations
from typing import Dict, Any


def _clamp(x: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return max(lo, min(hi, float(x)))


def apply_closed_loop_adjustments(
    command: Dict[str, Any],
    feedback: Dict[str, Any],
    cfg: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Day 18: Closed-loop corrective adjustments based on actuator feedback metrics.

    This does NOT change mode/intent. It only nudges targets slightly
    using cfg["closed_loop"] thresholds + step sizes.

    Expected cfg["closed_loop"] keys:
      slip_high, crush_high, jerk_high, tremor_high
      step_damping, step_grip_force, step_stiffness
      step_correction_gain, step_tremor_filter
    """
    if not command or not feedback or not feedback.get("ok"):
        return command

    cl = cfg.get("closed_loop", {}) or {}
    mode = command.get("mode")
    targets = dict(command.get("targets", {}) or {})
    metrics = feedback.get("metrics", {}) or {}

    # thresholds
    slip_high = float(cl.get("slip_high", 0.25))
    crush_high = float(cl.get("crush_high", 0.15))
    jerk_high = float(cl.get("jerk_high", 0.05))
    tremor_high = float(cl.get("tremor_high", 0.25))

    # steps
    step_d = float(cl.get("step_damping", 0.04))
    step_g = float(cl.get("step_grip_force", 0.03))
    step_s = float(cl.get("step_stiffness", 0.03))
    step_c = float(cl.get("step_correction_gain", 0.03))
    step_t = float(cl.get("step_tremor_filter", 0.02))

    if mode == "hand_control":
        gf = float(targets.get("grip_force", 0.0))
        st = float(targets.get("stiffness", 0.0))
        dp = float(targets.get("damping", 0.0))

        slip = float(metrics.get("slip_risk", 0.0))
        crush = float(metrics.get("crush_risk", 0.0))
        jerk = float(metrics.get("jerk_risk", 0.0))

        # If slip high -> increase damping and gently increase grip force
        if slip >= slip_high:
            dp += step_d
            gf += step_g

        # If crush high -> reduce grip force and stiffness, increase damping a bit
        if crush >= crush_high:
            gf -= step_g
            st -= step_s
            dp += (step_d * 0.5)

        # If jerk high -> reduce stiffness, increase damping a bit
        if jerk >= jerk_high:
            st -= step_s
            dp += (step_d * 0.5)

        targets["grip_force"] = _clamp(gf)
        targets["stiffness"] = _clamp(st)
        targets["damping"] = _clamp(dp)

        out = dict(command)
        out["targets"] = targets
        return out

    if mode == "stabilization":
        dp = float(targets.get("damping", 0.0))
        cg = float(targets.get("correction_gain", 0.0))
        tf = float(targets.get("tremor_filter", 0.0))

        residual = float(metrics.get("residual_tremor", 0.0))

        if residual >= tremor_high:
            dp += step_d
            cg += step_c
            tf += step_t

        targets["damping"] = _clamp(dp)
        targets["correction_gain"] = _clamp(cg)
        targets["tremor_filter"] = _clamp(tf)

        out = dict(command)
        out["targets"] = targets
        return out

    return command