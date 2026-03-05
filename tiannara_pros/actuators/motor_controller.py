# tiannara_pros/actuators/motor_controller.py

from __future__ import annotations
from typing import Dict, Any, Optional
import random


class MotorController:
    """
    Hardware stub.
    Later: replace internals with CAN, UART, BLE, ROS2, etc.
    """

    def __init__(self, rng: Optional[random.Random] = None):
        self.last_command: Optional[Dict[str, Any]] = None
        self.rng = rng or random.Random(123)

    def send(self, command: dict) -> bool:
        """
        Accepts action_packet["command"] dict.
        """
        self.last_command = command
        return True

    def read_feedback(self) -> dict:
        """
        Stub feedback generated from last_command targets.
        """
        if not self.last_command:
            return {"ok": False, "error": "no_command_sent"}

        mode = self.last_command.get("mode")
        targets = self.last_command.get("targets", {}) or {}

        if mode == "hand_control":
            gf = float(targets.get("grip_force", 0.0))
            stiffness = float(targets.get("stiffness", 0.0))
            damping = float(targets.get("damping", 0.0))

            slip_risk = max(0.0, 0.35 - damping) + max(0.0, 0.25 - gf)
            crush_risk = max(0.0, gf - 0.75) + max(0.0, stiffness - 0.85)
            jerk_risk = max(0.0, stiffness - 0.8) * max(0.0, 0.3 - damping)

            success = (slip_risk < 0.25) and (crush_risk < 0.15) and (jerk_risk < 0.05)

            return {
                "ok": True,
                "mode": mode,
                "success": success,
                "metrics": {
                    "slip_risk": round(slip_risk, 3),
                    "crush_risk": round(crush_risk, 3),
                    "jerk_risk": round(jerk_risk, 3),
                    "measured_grip_force": round(gf * 0.95, 3),
                },
            }

        if mode == "stabilization":
            damping = float(targets.get("damping", 0.0))
            corr = float(targets.get("correction_gain", 0.0))
            tf = float(targets.get("tremor_filter", 0.0))

            residual_tremor = max(0.0, 0.6 - (0.6 * damping) - (0.3 * corr) - (0.15 * tf))
            success = residual_tremor < 0.25

            return {
                "ok": True,
                "mode": mode,
                "success": success,
                "metrics": {"residual_tremor": round(residual_tremor, 3)},
            }

        return {"ok": True, "mode": mode, "success": True, "metrics": {}}