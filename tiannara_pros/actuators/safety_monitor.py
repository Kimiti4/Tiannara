# tiannara_pros/actuators/safety_monitor.py

from __future__ import annotations
from collections import deque
from typing import Any, Dict, Optional


class SafetyMonitor:
    """
    Day 23: runtime watchdog for repeated failures / risky signals.

    Trips on:
      - too many failures in a rolling window
      - too many consecutive failures
      - too many retry_exhausted events
      - repeated crush risk high (optional)
    """

    def __init__(
        self,
        window: int = 20,
        max_failures_in_window: int = 8,
        max_consecutive_failures: int = 4,
        max_retry_exhausted_in_window: int = 4,
        crush_trip_threshold: float = 0.30,
        crush_trip_repeats: int = 3,
    ):
        self.window = int(window)
        self.max_failures_in_window = int(max_failures_in_window)
        self.max_consecutive_failures = int(max_consecutive_failures)
        self.max_retry_exhausted_in_window = int(max_retry_exhausted_in_window)

        self.crush_trip_threshold = float(crush_trip_threshold)
        self.crush_trip_repeats = int(crush_trip_repeats)

        self._success_hist = deque(maxlen=self.window)  # bool success
        self._retry_ex_hist = deque(maxlen=self.window)  # bool
        self._crush_hist = deque(maxlen=self.window)  # bool

        self._consecutive_failures = 0

    def update(self, action_packet: Dict[str, Any]) -> Dict[str, Any]:
        fb = action_packet.get("feedback", {}) or {}
        safety = action_packet.get("safety", {}) or {}
        metrics = fb.get("metrics", {}) or {}

        ok = bool(fb.get("ok"))
        success = fb.get("success")

        retry_exhausted = bool(safety.get("retry_exhausted", False))
        crush_risk = float(metrics.get("crush_risk", 0.0)) if metrics else 0.0
        crush_high = crush_risk >= self.crush_trip_threshold

        if ok and success is True:
            self._success_hist.append(True)
            self._consecutive_failures = 0
        elif ok and success is False:
            self._success_hist.append(False)
            self._consecutive_failures += 1
        else:
            # ok==False counts as failure signal
            self._success_hist.append(False)
            self._consecutive_failures += 1

        self._retry_ex_hist.append(retry_exhausted)
        self._crush_hist.append(crush_high)

        failures_in_window = sum(1 for x in self._success_hist if x is False)
        retry_ex_in_window = sum(1 for x in self._retry_ex_hist if x)
        crush_high_in_window = sum(1 for x in self._crush_hist if x)

        # trip rules
        if failures_in_window >= self.max_failures_in_window:
            return {"trip": True, "reason": f"failures_in_window={failures_in_window}>=max({self.max_failures_in_window})"}

        if self._consecutive_failures >= self.max_consecutive_failures:
            return {"trip": True, "reason": f"consecutive_failures={self._consecutive_failures}>=max({self.max_consecutive_failures})"}

        if retry_ex_in_window >= self.max_retry_exhausted_in_window:
            return {"trip": True, "reason": f"retry_exhausted_in_window={retry_ex_in_window}>=max({self.max_retry_exhausted_in_window})"}

        if crush_high_in_window >= self.crush_trip_repeats:
            return {"trip": True, "reason": f"crush_high_repeats={crush_high_in_window}>=max({self.crush_trip_repeats})"}

        return {
            "trip": False,
            "reason": None,
            "stats": {
                "failures_in_window": failures_in_window,
                "consecutive_failures": self._consecutive_failures,
                "retry_exhausted_in_window": retry_ex_in_window,
                "crush_high_in_window": crush_high_in_window,
            },
        }