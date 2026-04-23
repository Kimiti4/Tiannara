from __future__ import annotations

import json
import time
import uuid
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional


@dataclass
class ExperienceDB:
    filepath: str = "runs/autonomous_experience.jsonl"
    path: Path = field(init=False)

    def __post_init__(self) -> None:
        self.path = Path(self.filepath)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        if not self.path.exists():
            self.path.touch()

    def store(self, payload: Dict[str, Any], kind: str = "autonomous_cycle") -> Dict[str, Any]:
        record = {
            "id": str(uuid.uuid4()),
            "ts": time.time(),
            "kind": kind,
            **payload,
        }
        with self.path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(record) + "\n")
        return record

    def append(self, payload: Dict[str, Any], kind: str = "autonomous_cycle") -> Dict[str, Any]:
        return self.store(payload=payload, kind=kind)

    def add(self, payload: Dict[str, Any], kind: str = "autonomous_cycle") -> Dict[str, Any]:
        return self.store(payload=payload, kind=kind)

    def get_all(self, limit: Optional[int] = None, kind: Optional[str] = None) -> List[Dict[str, Any]]:
        items: List[Dict[str, Any]] = []
        with self.path.open("r", encoding="utf-8") as handle:
            for line in handle:
                line = line.strip()
                if not line:
                    continue
                try:
                    item = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if kind is None or item.get("kind") == kind:
                    items.append(item)

        items.sort(key=lambda item: item.get("ts", 0), reverse=True)
        return items if limit is None else items[:limit]

    def list_entries(self, limit: int = 50, kind: Optional[str] = None) -> List[Dict[str, Any]]:
        return self.get_all(limit=limit, kind=kind)

    def latest(self) -> Optional[Dict[str, Any]]:
        items = self.get_all(limit=1)
        return items[0] if items else None
