# tiannara_pros/actuators/retry_controller.py

from __future__ import annotations
from typing import Dict, Any, Tuple


class RetryController:
    """
    Automatic corrective retries for prosthetic commands.

    Returns initial feedback (attempt 0) so analytics can compare:
      - initial success rate (before retries)
      - final success rate (after retries)
    """

    def __init__(self, max_retries: int = 2):
        self.max_retries = max_retries

    def should_retry(self, feedback: Dict[str, Any]) -> bool:
        return bool(feedback.get("ok")) and (feedback.get("success") is False)

    def propose_fix(
        self,
        command: Dict[str, Any],
        feedback: Dict[str, Any],
        attempt: int,
    ) -> Dict[str, Any]:
        mode = command.get("mode")
        intent = command.get("intent")
        targets = dict(command.get("targets", {}))
        metrics = feedback.get("metrics", {}) or {}

        k = 1.0 + (0.15 * attempt)

        if mode == "hand_control":
            gf = float(targets.get("grip_force", 0.0))
            stiff = float(targets.get("stiffness", 0.0))
            damp = float(targets.get("damping", 0.0))

            slip = float(metrics.get("slip_risk", 0.0))
            crush = float(metrics.get("crush_risk", 0.0))
            jerk = float(metrics.get("jerk_risk", 0.0))

            # crush -> soften
            if crush > 0.15:
                gf *= (0.85 / k)
                stiff *= (0.80 / k)
                damp = min(1.0, damp + (0.10 * k))

            # slip -> increase damping + a bit more grip
            if slip > 0.25:
                damp = min(1.0, damp + (0.12 * k))
                gf = min(1.0, gf + (0.06 * k))

            # jerk -> reduce stiffness + increase damping
            if jerk > 0.05:
                stiff *= (0.88 / k)
                damp = min(1.0, damp + (0.08 * k))

            targets["grip_force"] = max(0.0, min(1.0, gf))
            targets["stiffness"] = max(0.0, min(1.0, stiff))
            targets["damping"] = max(0.0, min(1.0, damp))

            return {"mode": mode, "intent": intent, "targets": targets}

        if mode == "stabilization":
            damp = float(targets.get("damping", 0.0))
            corr = float(targets.get("correction_gain", 0.0))
            tf = float(targets.get("tremor_filter", 0.0))
            residual = float(metrics.get("residual_tremor", 0.0))

            if residual >= 0.25:
                damp = min(1.0, damp + (0.10 * k))
                corr = min(1.0, corr + (0.08 * k))
                tf = min(1.0, tf + (0.06 * k))

            targets["damping"] = damp
            targets["correction_gain"] = corr
            targets["tremor_filter"] = tf

            return {"mode": mode, "intent": intent, "targets": targets}

        return command

    def run_retry_loop(
        self,
        motor,
        command: Dict[str, Any],
        validate_and_clip_fn,
        cfg: Dict[str, Any],
    ) -> Tuple[Dict[str, Any], Dict[str, Any], int, Dict[str, Any]]:
        """
        Returns:
          (final_command, final_feedback, retries_used, feedback_initial)
        """
        retries_used = 0

        # attempt 0
        safe_cmd = validate_and_clip_fn(command, cfg)
        motor.send(safe_cmd)
        fb = motor.read_feedback()
        fb_initial = dict(fb) if isinstance(fb, dict) else {"ok": False, "error": "bad_feedback"}

        # retries
        while self.should_retry(fb) and retries_used < self.max_retries:
            retries_used += 1
            fixed = self.propose_fix(safe_cmd, fb, retries_used)
            safe_cmd = validate_and_clip_fn(fixed, cfg)
            motor.send(safe_cmd)
            fb = motor.read_feedback()

        return safe_cmd, fb, retries_used, fb_initial