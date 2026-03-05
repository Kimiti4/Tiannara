# tiannara_pros/analytics/failure_reasons.py

from typing import Any, Dict, Optional


def classify_failure_reason(
    feedback: Dict[str, Any],
    cfg: Optional[Dict[str, Any]] = None,
) -> str:
    """
    Returns one of:
      slip | crush | jerk | tremor | dropout | unknown

    Uses metrics + optional cfg thresholds.
    """
    if not isinstance(feedback, dict):
        return "unknown"

    ok = feedback.get("ok", None)
    if ok is False:
        return "dropout"

    if not bool(ok):
        return "unknown"

    # If success True -> not a failure
    if bool(feedback.get("success")):
        return "unknown"

    metrics = feedback.get("metrics") or {}
    slip = metrics.get("slip_risk", None)
    crush = metrics.get("crush_risk", None)
    jerk = metrics.get("jerk_risk", None)
    trem = metrics.get("residual_tremor", None)

    # thresholds (defaults align with your retry logic)
    cl = (cfg or {}).get("closed_loop", {}) if isinstance(cfg, dict) else {}
    slip_hi = float(cl.get("slip_high", 0.25))
    crush_hi = float(cl.get("crush_high", 0.15))
    jerk_hi = float(cl.get("jerk_high", 0.05))
    trem_hi = float(cl.get("tremor_high", 0.25))

    try:
        if trem is not None and float(trem) >= trem_hi:
            return "tremor"
    except Exception:
        pass

    try:
        if crush is not None and float(crush) >= crush_hi:
            return "crush"
    except Exception:
        pass

    try:
        if jerk is not None and float(jerk) >= jerk_hi:
            return "jerk"
    except Exception:
        pass

    try:
        if slip is not None and float(slip) >= slip_hi:
            return "slip"
    except Exception:
        pass

    return "unknown"