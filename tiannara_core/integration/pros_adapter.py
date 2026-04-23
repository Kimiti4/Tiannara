from __future__ import annotations

from tiannara_pros.actuators.motor_controller import MotorController
from tiannara_pros.analytics.failure_reasons import classify_failure_reason


def _clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
    return max(low, min(high, float(value)))


def _candidate_from_agent(agent) -> dict[str, float]:
    probe = [0.15, -0.35, 0.65, -0.20, 0.40]
    output = [float(value) for value in agent.forward(probe)]
    if len(output) < 3:
        while len(output) < 3:
            output.append(output[len(output) % len(output)] if output else 0.0)
    scaled = [(value + 1.0) / 2.0 for value in output[:3]]
    return {
        "damping": round(_clamp(scaled[0]), 4),
        "stiffness": round(_clamp(scaled[1]), 4),
        "grip_force": round(_clamp(scaled[2]), 4),
    }


def evaluate_with_pros(agent=None, candidate: dict[str, float] | None = None) -> dict:
    if candidate is None:
        if agent is None:
            raise ValueError("Either an agent or candidate targets are required for PROS evaluation")
        targets = _candidate_from_agent(agent)
    else:
        targets = candidate
    controller = MotorController()
    controller.send({"mode": "hand_control", "targets": targets})
    feedback = controller.read_feedback()
    metrics = feedback.get("metrics", {}) or {}

    slip = float(metrics.get("slip_risk", 0.0) or 0.0)
    crush = float(metrics.get("crush_risk", 0.0) or 0.0)
    jerk = float(metrics.get("jerk_risk", 0.0) or 0.0)
    risk = _clamp((0.45 * slip) + (0.35 * crush) + (0.20 * jerk))

    return {
        "ok": bool(feedback.get("ok", False)),
        "success": bool(feedback.get("success", False)),
        "risk": round(risk, 4),
        "failure_reason": classify_failure_reason(feedback),
        "targets": targets,
        "feedback": feedback,
    }
