# tiannara_pros/io/run_recorder.py

from __future__ import annotations
import json
import time
import uuid
from pathlib import Path
from typing import Any, Dict, Optional


class RunRecorder:
    """
    Day 21: session recorder for JSONL packets + metadata snapshot.

    Writes:
      runs/<run_id>_<name>/
        - meta.json
        - packets.jsonl
    """

    def __init__(self, output_dir: str = "runs"):
        self.base_dir = Path(output_dir)
        self.base_dir.mkdir(parents=True, exist_ok=True)

        self.run_id: Optional[str] = None
        self.run_dir: Optional[Path] = None
        self.meta_path: Optional[Path] = None
        self.jsonl_path: Optional[Path] = None

        self._fh = None

    def start_run(self, name: str = "day10c_pipeline", metadata: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        self.run_id = str(uuid.uuid4())[:8]
        ts = time.strftime("%Y%m%d_%H%M%S")

        safe_name = "".join(c if c.isalnum() or c in ("-", "_") else "_" for c in name)
        self.run_dir = self.base_dir / f"{ts}_{self.run_id}_{safe_name}"
        self.run_dir.mkdir(parents=True, exist_ok=True)

        self.meta_path = self.run_dir / "meta.json"
        self.jsonl_path = self.run_dir / "packets.jsonl"

        meta = {
            "run_id": self.run_id,
            "name": name,
            "started_at": time.time(),
            "started_at_human": ts,
            "paths": {
                "run_dir": str(self.run_dir),
                "meta": str(self.meta_path),
                "jsonl": str(self.jsonl_path),
            },
            "metadata": metadata or {},
        }

        self.meta_path.write_text(json.dumps(meta, indent=2))
        self._fh = self.jsonl_path.open("a", encoding="utf-8")

        return meta

    def append_jsonl(self, packet: Dict[str, Any]) -> None:
        if not self._fh:
            raise RuntimeError("RunRecorder is not started. Call start_run() first.")
        self._fh.write(json.dumps(packet) + "\n")
        self._fh.flush()

    def close(self) -> None:
        if self._fh:
            try:
                self._fh.flush()
            finally:
                self._fh.close()
        self._fh = None