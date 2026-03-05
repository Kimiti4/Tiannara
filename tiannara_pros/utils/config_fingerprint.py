# tiannara_pros/utils/config_fingerprint.py

from __future__ import annotations
from typing import Any, Dict
import json
import hashlib


def fingerprint_config(cfg: Dict[str, Any]) -> str:
    """
    Stable config fingerprint:
    - canonical JSON (sorted keys)
    - SHA256 hex, shortened for convenience
    """
    canonical = json.dumps(cfg, sort_keys=True, separators=(",", ":"), ensure_ascii=True)
    h = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    return h[:12]