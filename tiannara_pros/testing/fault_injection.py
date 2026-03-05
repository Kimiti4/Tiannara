# tiannara_pros/testing/fault_injection.py

from __future__ import annotations
from dataclasses import dataclass
from typing import Any, Dict, Optional, List
import copy
import random


@dataclass
class FaultConfig:
    enabled: bool = False
    seed: int = 123
    profile: str = "none"   # "none" | "slip_spike" | "crush_spike" | "dropout" | "random_mix"
    probability: float = 0.2  # chance per step to inject (for profiles that use it)

    # Targeted injections
    slip_damping_cap: float = 0.06
    crush_gf_floor: float = 0.90
    crush_stiff_floor: float = 0.90

    # Dropout
    dropout_ok: bool = False

    # Tag noise (optional)
    tag_noise_probability: float = 0.0
    tag_noise_to: str = "unknown"


class FaultInjector:
    """
    Deterministic fault injector for:
      - command mutation (before sending)
      - feedback mutation (after read)
      - optional tag noise

    Use cfg["fault_injection"] to control.
    """

    def __init__(self, cfg: Optional[Dict[str, Any]] = None):
        cfg = cfg or {}
        self.cfg = FaultConfig(
            enabled=bool(cfg.get("enabled", False)),
            seed=int(cfg.get("seed", 123)),
            profile=str(cfg.get("profile", "none")),
            probability=float(cfg.get("probability", 0.2)),
            slip_damping_cap=float(cfg.get("slip_damping_cap", 0.06)),
            crush_gf_floor=float(cfg.get("crush_gf_floor", 0.90)),
            crush_stiff_floor=float(cfg.get("crush_stiff_floor", 0.90)),
            dropout_ok=bool(cfg.get("dropout_ok", False)),
            tag_noise_probability=float(cfg.get("tag_noise_probability", 0.0)),
            tag_noise_to=str(cfg.get("tag_noise_to", "unknown")),
        )
        self.rng = random.Random(self.cfg.seed)
        self.last_injection: Optional[Dict[str, Any]] = None

    def _coin(self, p: float) -> bool:
        return self.rng.random() < max(0.0, min(1.0, p))

    def maybe_corrupt_tags(self, tags: List[str], step: int) -> List[str]:
        if not self.cfg.enabled:
            return tags
        if self.cfg.tag_noise_probability <= 0:
            return tags
        if self._coin(self.cfg.tag_noise_probability):
            self.last_injection = {"type": "tag_noise", "step": step, "to": self.cfg.tag_noise_to}
            return [self.cfg.tag_noise_to]
        return tags

    def apply_to_command(self, command: Dict[str, Any], step: int) -> Dict[str, Any]:
        """
        Return a possibly modified command (deep-copied).
        """
        self.last_injection = None

        if not self.cfg.enabled or self.cfg.profile == "none":
            return command

        cmd = copy.deepcopy(command)
        mode = cmd.get("mode")
        targets = cmd.get("targets", {}) or {}

        # Decide if we inject this step
        inject = self._coin(self.cfg.probability) if self.cfg.profile in ("random_mix", "slip_spike", "crush_spike", "dropout") else False
        if not inject:
            return cmd

        if self.cfg.profile == "dropout":
            # command unchanged; feedback will be corrupted in apply_to_feedback
            self.last_injection = {"type": "dropout", "step": step}
            return cmd

        if mode == "hand_control":
            if self.cfg.profile == "slip_spike":
                # Reduce damping so slip risk increases
                targets["damping"] = min(float(targets.get("damping", 0.0)), self.cfg.slip_damping_cap)
                cmd["targets"] = targets
                self.last_injection = {"type": "slip_spike", "step": step, "damping_cap": self.cfg.slip_damping_cap}
                return cmd

            if self.cfg.profile == "crush_spike":
                targets["grip_force"] = max(float(targets.get("grip_force", 0.0)), self.cfg.crush_gf_floor)
                targets["stiffness"] = max(float(targets.get("stiffness", 0.0)), self.cfg.crush_stiff_floor)
                cmd["targets"] = targets
                self.last_injection = {"type": "crush_spike", "step": step}
                return cmd

            if self.cfg.profile == "random_mix":
                # Randomly pick slip or crush
                if self._coin(0.5):
                    targets["damping"] = min(float(targets.get("damping", 0.0)), self.cfg.slip_damping_cap)
                    self.last_injection = {"type": "slip_spike", "step": step}
                else:
                    targets["grip_force"] = max(float(targets.get("grip_force", 0.0)), self.cfg.crush_gf_floor)
                    targets["stiffness"] = max(float(targets.get("stiffness", 0.0)), self.cfg.crush_stiff_floor)
                    self.last_injection = {"type": "crush_spike", "step": step}
                cmd["targets"] = targets
                return cmd

        # For stabilization you can add tremor spike later if you want.
        return cmd

    def apply_to_feedback(self, feedback: Dict[str, Any], step: int) -> Dict[str, Any]:
        """
        Return a possibly modified feedback (deep-copied).
        Used mainly for dropout profile.
        """
        if not self.cfg.enabled or self.cfg.profile == "none":
            return feedback

        if self.last_injection and self.last_injection.get("type") == "dropout":
            fb = copy.deepcopy(feedback)
            fb["ok"] = bool(self.cfg.dropout_ok)
            fb["success"] = False
            fb["error"] = "fault_injection_dropout"
            fb["metrics"] = fb.get("metrics", {}) or {}
            return fb

        return feedback