# tiannara_pros/io/action_schema.py
import time
import uuid


TIANNARA_ACTION_SCHEMA = "tiannara.pros.action.v1"
TIANNARA_CORE_VERSION = "1.0.0"  # Day 20: Freeze v1.0 marker


def build_action_packet(action, decision, context_tags, emg=None, fatigue=None, safety=None):
    """
    Wraps low-level action targets into a versioned, stable packet.
    """

    return {
        "schema": TIANNARA_ACTION_SCHEMA,
        "core_version": TIANNARA_CORE_VERSION,

        "id": str(uuid.uuid4()),
        "ts": time.time(),

        "context": {
            "tags": context_tags,
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
            "targets": action.get("targets", {}),
        },

        # safety + validation
        "safety": safety or {
            "fallback_used": action.get("intent") != decision.get("intent"),
            "min_confidence_gate": decision.get("_min_confidence_gate", None),
        },

        "transport": {
            "topic": "tiannara/pros/command",
            "priority": 1,
        },
    }