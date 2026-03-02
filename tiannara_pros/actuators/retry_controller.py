# tiannara_pros/actuators/retry_controller.py

from __future__ import annotations
from typing import Dict, Any, Tuple

from tiannara_core.action.control_adapter import apply_closed_loop_adjustments


class RetryController:
    """
    Day 13: corrective retries
    Day 18: closed-loop correction (config-driven) integrated into retries

    Behavior:
    - Send command -> read feedback
    - If fail: apply closed-loop adjustments + validate/clip -> resend
    - Repeat up to max_retries
    """

    def __init__(self, max_retries: int = 2):
        self.max_retries = max_retries

    def should_retry(self, feedback: Dict[str, Any]) -> bool:
        return bool(feedback.get("ok")) and (feedback.get("success") is False)

    def run_retry_loop(
        self,
        motor,
        command: Dict[str, Any],
        validate_and_clip_fn,
        cfg: Dict[str, Any],
        debug: bool = False,
    ) -> Tuple[Dict[str, Any], Dict[str, Any], int]:
        """
        Returns: (final_command, final_feedback, retries_used)
        """
        retries_used = 0

        # send attempt 0
        safe_cmd = validate_and_clip_fn(command, cfg)
        motor.send(safe_cmd)
        fb = motor.read_feedback()

        if debug:
            print(f"[RETRY] attempt=0 safe_cmd={safe_cmd}")
            print(f"[RETRY] attempt=0 feedback={fb}")

        # retry loop (closed-loop corrections)
        while self.should_retry(fb) and retries_used < self.max_retries:
            retries_used += 1

            # Day 18: adjust command using feedback + cfg["closed_loop"]
            fixed = apply_closed_loop_adjustments(safe_cmd, fb, cfg)

            # clip again
            safe_cmd = validate_and_clip_fn(fixed, cfg)

            if debug:
                print(f"[RETRY] retry={retries_used} closed_loop_fix={fixed}")
                print(f"[RETRY] retry={retries_used} clipped_fix={safe_cmd}")

            motor.send(safe_cmd)
            fb = motor.read_feedback()

            if debug:
                print(f"[RETRY] retry={retries_used} feedback={fb}")

        return safe_cmd, fb, retries_used