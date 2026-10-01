from tiannara_core.conversation.native_dialogue import NativeDialogueEngine


def test_native_dialogue_marks_missing_evidence_as_unknown():
    engine = NativeDialogueEngine()
    result = engine.respond("s1", "Can you prove a new physical law?", {})
    assert result.confidence <= 0.35
    assert "sufficient evidence" in result.text.lower() or "won't manufacture" in result.text.lower()
    assert result.reasoning_summary["epistemic_status"] == "insufficient_evidence"


def test_native_dialogue_uses_supplied_evidence_without_calling_an_llm():
    engine = NativeDialogueEngine()
    result = engine.respond(
        "s2",
        "Research this",
        {"evidence": [{"source": "paper-a", "quality": 0.9}], "known_facts": ["bounded fact"]},
    )
    assert result.confidence > 0.35
    assert result.reasoning_summary["evidence_used"] == 2


def test_native_initiation_is_state_driven():
    engine = NativeDialogueEngine()
    result = engine.initiate("s3", {"knowledge_gaps": ["verify world genome persistence"]})
    assert result.proactive is True
    assert "genome" in result.text.lower()
