from __future__ import annotations

import json
import time
import uuid
from pathlib import Path
from typing import Any, Dict, List, Optional


class DiscoveryMemory:
    """
    Very simple persistent memory for discovery reports.
    Stores one JSON object per line (JSONL).
    """

    def __init__(self, filepath: str = "runs/discovery_memory.jsonl"):
        self.path = Path(filepath)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        if not self.path.exists():
            self.path.touch()

    def save_report(
        self,
        *,
        question: str,
        source: str,
        report: Dict[str, Any],
        tags: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        record = {
            "id": str(uuid.uuid4()),
            "ts": time.time(),
            "question": question,
            "source": source,
            "tags": tags or [],
            "report": report,
        }

        with self.path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(record) + "\n")

        return record

    def list_reports(self, limit: int = 50) -> List[Dict[str, Any]]:
        items: List[Dict[str, Any]] = []

        with self.path.open("r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    items.append(json.loads(line))
                except json.JSONDecodeError:
                    continue

        items.sort(key=lambda x: x.get("ts", 0), reverse=True)
        return items[:limit]

    def get_report(self, report_id: str) -> Optional[Dict[str, Any]]:
        with self.path.open("r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    item = json.loads(line)
                except json.JSONDecodeError:
                    continue

                if item.get("id") == report_id:
                    return item

        return None