# tiannara_pros/io/jsonl_logger.py

from __future__ import annotations
import json
from pathlib import Path
from typing import Any, Dict, Optional


class JsonlLogger:
    """
    Writes each action_packet as a single JSON line.
    Use for grep/search + replay (Day 20).
    """

    def __init__(self, path: str):
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)

    def log(self, packet: Dict[str, Any]) -> None:
        with self.path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(packet, ensure_ascii=False) + "\n")