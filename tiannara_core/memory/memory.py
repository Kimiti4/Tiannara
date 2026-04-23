from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List


@dataclass
class Memory:
    items: List[Dict[str, Any]] = field(default_factory=list)

    def add(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        self.items.append(payload)
        return payload

    def list(self) -> List[Dict[str, Any]]:
        return list(self.items)

    def clear(self) -> None:
        self.items.clear()


memory = Memory()
