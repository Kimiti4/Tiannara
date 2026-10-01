import pytest

from tiannara_core.conversation.native_dialogue import NativeDialogueEngine


def test_native_dialogue_admits_unknowns():
    engine = NativeDialogueEngine()
    result = engine.respond("s1", "What is the true origin of this unknown phenomenon?")
    assert result.confidence <= 0.35
    assert "sufficient evidence" in result.text
    assert result.reasoning_summary["epistemic_status"] == "insufficient_evidence"
    assert result.reasoning_summary["next_action"] == "gather_evidence_then_compare_hypotheses"


def test_native_dialogue_uses_evidence():
    engine = NativeDialogueEngine()
    result = engine.respond(
        "s2",
        "What does the evidence indicate?",
        {"evidence": [{"quality": 0.9}, {"quality": 0.8}], "known_facts": ["fact-a"]},
    )
    assert result.confidence > 0.5
    assert result.reasoning_summary["evidence_used"] == 3
    assert result.reasoning_summary["epistemic_status"] == "evidence_supported"


def test_native_initiation_is_state_grounded():
    engine = NativeDialogueEngine()
    result = engine.initiate("s3", {"knowledge_gaps": ["causal mechanism"]})
    assert result.proactive is True
    assert "causal mechanism" in result.text
    assert result.reasoning_summary["epistemic_status"] == "state_grounded"
