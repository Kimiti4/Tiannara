# tiannara_pros/actuators/actuator_memory.py

from __future__ import annotations
from typing import Dict, Any


class ActuatorMemory:
    """
    Stores last known GOOD commands and uses them to bias future commands.

    - Keyed by (mode, intent)
    - update_from_feedback(): saves command when feedback.success == True
    - apply_bias(): nudges current command targets toward remembered good targets
    """

    def __init__(self, bias_alpha: float = 0.35):
        # alpha closer to 1.0 -> stronger pull toward remembered targets
        self.bias_alpha = float(bias_alpha)
        self._memory: Dict[str, Dict[str, Any]] = {}

    def _key(self, command: Dict[str, Any]) -> str:
        mode = command.get("mode", "unknown")
        intent = command.get("intent", "unknown")
        return f"{mode}::{intent}"

    def update_from_feedback(self, command: Dict[str, Any], feedback: Dict[str, Any]) -> bool:
        """
        Save the command targets if feedback indicates success.
        Returns True if updated.
        """
        if not feedback.get("ok"):
            return False
        if feedback.get("success") is not True:
            return False

        k = self._key(command)
        self._memory[k] = {
            "mode": command.get("mode"),
            "intent": command.get("intent"),
            "targets": dict(command.get("targets", {})),
        }
        return True

    def has_memory(self, command: Dict[str, Any]) -> bool:
        return self._key(command) in self._memory

    def apply_bias(self, command: Dict[str, Any]) -> Dict[str, Any]:
        """
        Blend command targets toward stored successful targets for same mode+intent.
        If no memory exists, returns command unchanged.
        """
        k = self._key(command)
        if k not in self._memory:
            return command

        stored = self._memory[k]
        stored_targets = stored.get("targets", {}) or {}
        targets = dict(command.get("targets", {}))

        blended = {}
        for name, value in targets.items():
            if name in stored_targets:
                prev_good = float(stored_targets[name])
                cur = float(value)
                a = self.bias_alpha
                blended[name] = (a * prev_good) + ((1 - a) * cur)
            else:
                blended[name] = value

        out = dict(command)
        out["targets"] = blended
        return out

    def snapshot(self) -> Dict[str, Any]:
        """
        For logging/debugging.
        """
        return {"bias_alpha": self.bias_alpha, "keys": list(self._memory.keys())}