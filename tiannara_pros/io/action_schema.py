import time
import uuid


def build_action_packet(action, decision, context_tags, emg=None, fatigue=None, safety=None):
    """
    Wraps low-level action targets into a versioned, stable packet.
    """
    return {
        "schema": "tiannara.pros.action.v1",
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

        "safety": (safety if safety is not None else {
            "fallback_used": bool(decision.get("_forced_fallback", False)),
            "min_confidence_gate": decision.get("_min_confidence_gate", None),
            
        }),

        "transport": {
            "topic": "tiannara/pros/command",
            "priority": 1
        }
    }