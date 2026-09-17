"""
TIA_FORENSIC_RECON_ENGINE — source_inventory collector.

Move 0. AST-light extraction for .ex / .exs / .py files in the T0_TRACKED
bucket. Identifies candidate "contract signals" (function names matching
verify_/assert_/test_/check_ patterns; @spec returns; defdelegate).

This is the FACT layer per master.md. Interpretation is deferred to a
future Move 2+ capability_detector analyzer (out of scope here).

READ-ONLY. No file content is read for files >5 MB.
"""
from __future__ import annotations

import os
from typing import Any, Dict, List

from . import _common as C

MAX_TEXT_FILE_BYTES = 5 * 1024 * 1024  # do not parse files >5 MB
EXTS_FOR_PARSING = {".ex", ".exs", ".py"}


def _read_text_safely(path: str) -> str:
    try:
        size = os.path.getsize(path)
    except OSError:
        return ""
    if size > MAX_TEXT_FILE_BYTES:
        return ""
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return ""


def _is_test_file(posix: str) -> bool:
    parts = posix.split("/")
    if "test" in parts or "tests" in parts:
        return True
    base = parts[-1] if parts else ""
    return base.endswith("_test.exs") or base.endswith("_test.ex") or base.endswith("_test.py")


def collect(repo: str, items: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Return the source_inventory evidence bundle.

    Parameters
    ----------
    repo : str
        Path to the T0 worktree.
    items : list[dict]
        The repo_inventory items (we only process T0_TRACKED .ex/.exs/.py).
    """
    by_ext: Dict[str, int] = {".ex": 0, ".exs": 0, ".py": 0}
    parsed_count = 0
    skipped_size = 0
    test_file_count = 0
    parsed_files: List[Dict[str, Any]] = []

    for it in items:
        if it["bucket"] != "T0_TRACKED":
            continue
        path = it["path"]
        ext = os.path.splitext(path)[1].lower()
        if ext not in EXTS_FOR_PARSING:
            continue
        by_ext[ext] = by_ext.get(ext, 0) + 1
        if _is_test_file(path):
            test_file_count += 1
        full = os.path.join(repo, path)
        text = _read_text_safely(full)
        if not text:
            skipped_size += 1
            continue
        parsed_count += 1
        if ext in (".ex", ".exs"):
            sig = C.extract_elixir_signals(text)
        elif ext == ".py":
            sig = C.extract_python_signals(text)
        else:
            continue
        # Record ONLY the structural facts. No interpretation.
        parsed_files.append({
            "path": path,
            "size_bytes": it["size_bytes"],
            "sha256": it.get("sha256"),
            "extension": ext,
            "is_test": _is_test_file(path),
            "signals": sig,
        })

    return {
        "schema_version": "1.0.0",
        "evidence_kind": "source_inventory",
        "produced_by": {"collector": "source_inventory", "contract_version": C.CONTRACT_VERSION},
        "produced_at_t0": C.T0_COMMIT,
        "summary": {
            "tracked_source_files_by_ext": by_ext,
            "tracked_test_files": test_file_count,
            "files_parsed": parsed_count,
            "files_skipped_size_or_io": skipped_size,
        },
        "items": parsed_files,
    }
