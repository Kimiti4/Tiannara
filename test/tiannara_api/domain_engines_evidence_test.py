"""Evidence-bound tests for the public domain-engine adapters."""

from tiannara_api.engines.nlp import NLPEngine
from tiannara_api.engines.logic import LogicEngine
from tiannara_api.engines.causal import CausalEngine


def test_nlp_no_longer_returns_synthetic_pending_success():
    result = NLPEngine().process({"task": "sentiment", "text": "excellent work"})
    assert result["status"] == "success"
    assert result["result"]["sentiment"] > 0


def test_nlp_rejects_unknown_task():
    result = NLPEngine().process({"task": "unknown", "text": "hello"})
    assert result["status"] == "error"


def test_logic_proves_only_explicitly_derivable_fact():
    engine = LogicEngine()
    result = engine.process({
        "facts": ["rain"],
        "rules": [{"if": ["rain"], "then": "wet_ground"}],
        "question": "wet_ground",
    })
    assert result["status"] == "success"
    assert result["result"]["entailed"] is True
    assert result["result"]["proof"]


def test_logic_does_not_invent_unproved_conclusion():
    result = LogicEngine().process({"facts": ["rain"], "question": "sunny"})
    assert result["status"] == "success"
    assert result["result"]["entailed"] is False
    assert result["result"]["conclusion"] is None


def test_causal_missing_data_fails_closed():
    result = CausalEngine().process({
        "task": "estimate_effect",
        "treatment": "X",
        "outcome": "Y",
    })
    assert result["status"] == "error"
