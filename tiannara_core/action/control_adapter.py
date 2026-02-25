def _clip(x: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return max(lo, min(hi, float(x)))


def apply_closed_loop_adjustments(action: dict, prev_feedback: dict, cfg: dict) -> dict:
    """
    Day 17: Closed-loop adjustment layer.
    Uses *previous* actuator feedback metrics to nudge the *next* command.

    - If slip_risk high -> increase damping + small grip_force
    - If crush_risk high -> reduce grip_force + stiffness, increase damping slightly
    - If jerk_risk high -> reduce stiffness, increase damping slightly
    - If stabilization residual tremor high -> increase damping + correction_gain + tremor_filter
    """
    if not prev_feedback or not prev_feedback.get("ok"):
        return action

    cl = (cfg or {}).get("closed_loop", {}) or {}
    metrics = prev_feedback.get("metrics", {}) or {}

    slip_high = float(cl.get("slip_high", 0.25))
    crush_high = float(cl.get("crush_high", 0.15))
    jerk_high = float(cl.get("jerk_high", 0.05))
    tremor_high = float(cl.get("tremor_high", 0.25))

    step_damping = float(cl.get("step_damping", 0.04))
    step_grip = float(cl.get("step_grip_force", 0.03))
    step_stiff = float(cl.get("step_stiffness", 0.03))
    step_corr = float(cl.get("step_correction_gain", 0.03))
    step_tf = float(cl.get("step_tremor_filter", 0.02))

    mode = action.get("mode")
    targets = dict(action.get("targets", {}))

    # ---- HAND CONTROL CLOSED-LOOP ----
    if mode == "hand_control":
        gf = float(targets.get("grip_force", 0.0))
        stiff = float(targets.get("stiffness", 0.0))
        damp = float(targets.get("damping", 0.0))

        slip = float(metrics.get("slip_risk", 0.0))
        crush = float(metrics.get("crush_risk", 0.0))
        jerk = float(metrics.get("jerk_risk", 0.0))

        # Priority order: crush > jerk > slip
        if crush > crush_high:
            gf -= step_grip
            stiff -= step_stiff
            damp += (0.5 * step_damping)

        if jerk > jerk_high:
            stiff -= step_stiff
            damp += (0.5 * step_damping)

        if slip > slip_high:
            damp += step_damping
            gf += step_grip

        targets["grip_force"] = _clip(gf)
        targets["stiffness"] = _clip(stiff)
        targets["damping"] = _clip(damp)

        action["targets"] = targets
        return action

    # ---- STABILIZATION CLOSED-LOOP ----
    if mode == "stabilization":
        damp = float(targets.get("damping", 0.0))
        corr = float(targets.get("correction_gain", 0.0))
        tf = float(targets.get("tremor_filter", 0.0))

        residual = float(metrics.get("residual_tremor", 0.0))

        if residual > tremor_high:
            damp += step_damping
            corr += step_corr
            tf += step_tf

        targets["damping"] = _clip(damp)
        targets["correction_gain"] = _clip(corr)
        targets["tremor_filter"] = _clip(tf)

        action["targets"] = targets
        return action

    return action