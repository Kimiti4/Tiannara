# tiannara_pros/actuators/interfaces.py

from __future__ import annotations
from typing import Protocol, Dict, Any


class ActuatorInterface(Protocol):
    def send(self, command: Dict[str, Any]) -> bool: ...
    def read_feedback(self) -> Dict[str, Any]: ...