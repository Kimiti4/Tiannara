# tiannara_pros/io/action_schema.py

import time
import uuid
from typing import Any, Dict, Optional

from tiannara_pros.version import PROS_VERSION


REQUIRED_ACTION_KEYS = ("mode", "intent", "targets")
REQUIRED_DECISION_KEYS = ("intent", "confidence", "reason")


def _require_keys(obj: Dict[str, Any], keys, name: str):
    missing = [k for k in keys if k not in obj]
    if missing:
        raise ValueError(f"{name} missing required keys: {missing}")


def build_action_packet(
    action: Dict[str, Any],
    decision: Dict[str, Any],
    context_tags,
    emg: Optional[Dict[str, Any]] = None,
    fatigue: Any = None,
    safety: Optional[Dict[str, Any]] = None,
    *,
    core_version: str = "1.0.0",
) -> Dict[str, Any]:
    """
    Wraps low-level action targets into a versioned, stable packet.
    Adds:
      - pros_version
      - basic schema validation
    """
    action = action or {}
    decision = decision or {}

    _require_keys(action, REQUIRED_ACTION_KEYS, "action")
    _require_keys(decision, REQUIRED_DECISION_KEYS, "decision")

    pkt = {
        "schema": "tiannara.pros.action.v1",
        "pros_version": PROS_VERSION,
        "core_version": core_version,
        "id": str(uuid.uuid4()),
        "ts": time.time(),

        "context": {
            "tags": list(context_tags or []),
            "emg": emg or {},
            "fatigue": fatigue,
        },

        "decision": {
            "intent": decision.get("intent"),
            "confidence": float(decision.get("confidence", 0.0)),
            "reason": decision.get("reason", ""),
            "chosen_breakdown": decision.get("chosen_breakdown", None),
        },

        "command": {
            "mode": action.get("mode"),
            "intent": action.get("intent"),
            "targets": action.get("targets", {}) or {},
        },

        "safety": safety or {
            "fallback_used": action.get("intent") != decision.get("intent"),
            "min_confidence_gate": decision.get("_min_confidence_gate", None),
        },

        "transport": {
            "topic": "tiannara/pros/command",
            "priority": 1
        },
    }

    return pkt