FORCE_FAIL = False  # set True only for testing
class MotorController:
    """
    Hardware stub.
    Later: replace internals with CAN, UART, BLE, ROS2, etc.
    """
    
    def __init__(self):
        self.last_command = None

    def send(self, command: dict):
        """
        Accepts action_packet["command"] dict.
        """
        self.last_command = command
        # For now: just pretend we sent it.
        return True
    def read_feedback(self) -> dict:
        """
        Hardware stub feedback.
        Later this would come from sensors/encoders/current draw/IMU, etc.
        """
        if not self.last_command:
            return {"ok": False, "error": "no_command_sent"}

        mode = self.last_command.get("mode")
        targets = self.last_command.get("targets", {})

        # Very rough “simulated” feedback signals
        if mode == "hand_control":
            gf = float(targets.get("grip_force", 0.0))
            stiffness = float(targets.get("stiffness", 0.0))   
            damping = float(targets.get("damping", 0.0))
            # TEST ONLY: force slip failure
            #damping = 0.05
            #gf = 0.20
            # 🚨 TEST ONLY: force a failure condition
            #gf = 0.95
            #stiffness = 0.95
            # damping can stay as-is
            if FORCE_FAIL:
                gf = 0.95
                stiffness = 0.95
            # pretend we measure slippage / grip success
            slip_risk = max(0.0, 0.35 - damping) + max(0.0, 0.25 - gf)
            success = slip_risk < 0.25
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
                }
            }

        if mode == "stabilization":
            damping = float(targets.get("damping", 0.0))
            corr = float(targets.get("correction_gain", 0.0))

            # pretend we measure residual tremor after applying stabilization
            residual_tremor = max(0.0, 0.6 - (0.6 * damping) - (0.3 * corr))
            success = residual_tremor < 0.25

            return {
                "ok": True,
                "mode": mode,
                "success": success,
                "metrics": {
                    "residual_tremor": round(residual_tremor, 3),
                }
            }

        return {"ok": True, "mode": mode, "success": True, "metrics": {}}
