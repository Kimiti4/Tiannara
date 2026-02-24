# tiannara_pros/actuators/retry_controller.py

from __future__ import annotations
from typing import Dict, Any, Tuple


class RetryController:
    """
    Automatic corrective retries for prosthetic commands.

    Goals:
    - If slip risk is high -> increase damping and/or grip_force slightly
    - If crush risk is high -> reduce grip_force and stiffness
    - If jerk risk is high -> reduce stiffness or increase damping
    - For stabilization failures -> increase damping/correction_gain within limits

    This never "invents" new modes: it only adjusts existing targets safely.
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
        """
        Returns a modified command dict (same shape as action_packet["command"]).
        """
        mode = command.get("mode")
        intent = command.get("intent")
        targets = dict(command.get("targets", {}))
        metrics = feedback.get("metrics", {}) or {}

        # small attempt-based scaling (later retries make slightly stronger corrections)
        k = 1.0 + (0.15 * attempt)

        if mode == "hand_control":
            gf = float(targets.get("grip_force", 0.0))
            stiff = float(targets.get("stiffness", 0.0))
            damp = float(targets.get("damping", 0.0))

            slip = float(metrics.get("slip_risk", 0.0))
            crush = float(metrics.get("crush_risk", 0.0))
            jerk = float(metrics.get("jerk_risk", 0.0))

            # 1) If crushing risk -> soften immediately
            if crush > 0.15:
                gf = max(0.0, gf - (0.10 * k))
                stiff = max(0.0, stiff - (0.10 * k))
                damp = min(1.0, damp + (0.10 * k))

            # 2) If slip risk -> increase damping and gently increase grip
            if slip > 0.25:
                damp = min(1.0, damp + (0.12 * k))
                gf = min(1.0, gf + (0.06 * k))

            # 3) If jerk -> reduce stiffness and increase damping a bit
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

        # unknown mode -> no changes
        return command

    def run_retry_loop(
        self,
        motor,
        command: Dict[str, Any],
        validate_and_clip_fn,
        cfg: Dict[str, Any],
    ) -> Tuple[Dict[str, Any], Dict[str, Any], int]:
        """
        Returns: (final_command, final_feedback, retries_used)
        """
        retries_used = 0

        # send first time
        print(f"[RETRY] start cmd_in={command}")
        safe_cmd = validate_and_clip_fn(command, cfg)
        motor.send(safe_cmd)
        fb = motor.read_feedback()
        print(f"[RETRY] attempt=0 safe_cmd={safe_cmd}")
        print(f"[RETRY] attempt=0 feedback={fb}")

        while self.should_retry(fb) and retries_used < self.max_retries:
            retries_used += 1

            print(f"[RETRY] retry={retries_used} prev_safe_cmd={safe_cmd}")
            print(f"[RETRY] retry={retries_used} prev_feedback={fb}")

            fixed = self.propose_fix(safe_cmd, fb, retries_used)
            print(f"[RETRY] retry={retries_used} proposed_fix={fixed}")

            safe_cmd = validate_and_clip_fn(fixed, cfg)
            print(f"[RETRY] retry={retries_used} clipped_fix={safe_cmd}")


            motor.send(safe_cmd)
            fb = motor.read_feedback()
            print("[RETRY] should_retry?", bool(fb.get("ok")) and (fb.get("success") is False), "fb.success=", fb.get("success"))

            print(f"[RETRY] retry={retries_used} feedback={fb}")

        return safe_cmd, fb, retries_used