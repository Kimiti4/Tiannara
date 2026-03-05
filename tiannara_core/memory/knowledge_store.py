from __future__ import annotations
from dataclasses import dataclass, field
from typing import Dict, Any, List, Optional
import time
import uuid


@dataclass
class KnowledgeItem:
    id: str
    ts: float
    source: str
    kind: str  # "chunk" | "claim" | "hypothesis" | "experiment" | "report"
    payload: Dict[str, Any]
    trust: float = 0.50  # 0..1 (poisoning resistance later)


@dataclass
class KnowledgeStore:
    """
    Simple in-memory store. Later: persist to SQLite / Postgres / vector store.
    """
    items: List[KnowledgeItem] = field(default_factory=list)

    def add(self, source: str, kind: str, payload: Dict[str, Any], trust: float = 0.50) -> KnowledgeItem:
        item = KnowledgeItem(
            id=str(uuid.uuid4()),
            ts=time.time(),
            source=source,
            kind=kind,
            payload=payload,
            trust=max(0.0, min(1.0, float(trust))),
        )
        self.items.append(item)
        return item

    def list(self, kind: Optional[str] = None) -> List[KnowledgeItem]:
        if kind is None:
            return list(self.items)
        return [x for x in self.items if x.kind == kind]

    def clear(self) -> None:
        self.items.clear()