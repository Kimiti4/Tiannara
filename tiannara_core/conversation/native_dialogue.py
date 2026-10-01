"""Native Tiannara dialogue engine.

No generative-model dependency. Combines deterministic intent analysis,
dialogue state, evidence classification, epistemic gap detection, goal
formation and response planning.

It exposes a reasoning summary rather than private chain-of-thought:
what was observed, what evidence was available, what is inferred, what is
unknown, and what Tiannara proposes doing next.
"""
from __future__ import annotations
import re
from dataclasses import dataclass
from typing import Any
from tiannara_core.nlp.intent_tracker import IntentTracker, IntentCategory
from tiannara_core.nlp.dialogue_state import DialogueStateManager

@dataclass
class CognitiveResponse:
    text: str
    intent: str
    confidence: float
    reasoning_summary: dict[str, Any]
    next_questions: list[str]
    proactive: bool = False

    def as_dict(self) -> dict[str, Any]:
        return {
            "response": self.text,
            "intent": self.intent,
            "confidence": self.confidence,
            "reasoning_summary": self.reasoning_summary,
            "next_questions": self.next_questions,
            "proactive": self.proactive,
            "provider": "tiannara_native_cognition",
        }

class NativeDialogueEngine:
    """Bounded cognitive dialogue loop built from Tiannara subsystems."""

    def __init__(self) -> None:
        self.state = DialogueStateManager()
        self.intents = IntentTracker()

    def respond(self, session_id: str, message: str, context: dict[str, Any] | None = None) -> CognitiveResponse:
        context = context or {}
        self.state.get_session(session_id) or self.state.create_session(
            session_id, str(context.get("user_id", "operator"))
        )
        intent = self.intents.track_session(session_id, message, context)
        self.state.add_user_turn(session_id, message, intent.category.value, intent.entities)

        evidence = list(context.get("evidence", []))
        explicit_unknowns = list(context.get("unknowns", []))
        knowledge = context.get("known_facts", [])
        contradictions = list(context.get("contradictions", []))

        evidence_quality = self._evidence_quality(evidence)
        knowledge_support = min(1.0, len(knowledge) / 4.0)
        contradiction_penalty = min(0.7, len(contradictions) * 0.15)
        confidence = max(
            0.05,
            min(0.95, 0.25 + 0.45 * evidence_quality + 0.30 * knowledge_support - contradiction_penalty),
        )

        if not evidence and not knowledge:
            unknown = "I do not currently have sufficient evidence in my knowledge state to establish that."
            action = self._next_action(intent.category)
            text = (
                f"I understand the question as: {message}\n\n{unknown}\n"
                f"I won't manufacture an answer. My next justified step is '{action}'. "
                "I can turn that into an investigation plan or gather external evidence."
            )
            confidence = min(confidence, 0.35)
        else:
            text = self._compose_supported_response(
                message, evidence, knowledge, contradictions, intent.category
            )

        if explicit_unknowns:
            text += "\n\nKnown gaps: " + "; ".join(str(x) for x in explicit_unknowns[:4]) + "."

        summary = {
            "observation": f"Operator input received as a {intent.category.value}: {message[:240]}",
            "interpretation": f"Intent classifier confidence: {intent.confidence:.2f}.",
            "evidence_used": len(evidence) + len(knowledge),
            "contradictions_seen": len(contradictions),
            "epistemic_status": "insufficient_evidence" if not evidence and not knowledge else "evidence_supported",
            "confidence_basis": {
                "evidence_quality": round(evidence_quality, 3),
                "knowledge_support": round(knowledge_support, 3),
                "contradiction_penalty": round(contradiction_penalty, 3),
            },
            "next_action": self._next_action(intent.category),
        }
        followups = self._followups(intent.category)
        response = CognitiveResponse(text, intent.category.value, confidence, summary, followups)
        self.state.add_assistant_turn(session_id, text, summary)
        return response

    def initiate(self, session_id: str, context: dict[str, Any] | None = None) -> CognitiveResponse:
        context = context or {}
        anomalies = list(context.get("anomalies", []))
        goals = list(context.get("goals", []))
        gaps = list(context.get("knowledge_gaps", []))

        if anomalies:
            lead = f"I noticed {len(anomalies)} unresolved signal(s) in my current state."
            question = "Would you like me to investigate the highest-impact one?"
        elif gaps:
            lead = f"I currently have {len(gaps)} identified knowledge gap(s)."
            question = f"The most useful open thread is: {gaps[0]}. Shall I investigate it?"
        elif goals:
            lead = f"I have {len(goals)} active objective(s) in context."
            question = "Which objective should receive attention first, or should I inspect their dependencies?"
        else:
            lead = "I have no high-priority unresolved signal that I can currently justify elevating."
            question = "We can investigate a question, inspect my internal state, or start an independent research thread."

        text = (
            f"{lead}\n\n{question}\n\n"
            "I will distinguish observations from inferences and mark unknowns rather than filling them with invented certainty."
        )
        return CognitiveResponse(
            text, "proactive_initiation",
            0.8 if (anomalies or goals or gaps) else 0.6,
            {
                "observation": lead,
                "interpretation": "Conversation selected from current system state rather than a random greeting.",
                "evidence_used": len(anomalies) + len(goals) + len(gaps),
                "epistemic_status": "state_grounded",
                "next_action": "await_operator_direction",
            },
            [question], True
        )

    @staticmethod
    def _evidence_quality(evidence: list[Any]) -> float:
        if not evidence:
            return 0.0
        scores = []
        for item in evidence:
            if isinstance(item, dict):
                scores.append(float(item.get("quality", item.get("confidence", 0.5))))
            else:
                scores.append(0.4)
        return max(0.0, min(1.0, sum(scores) / len(scores)))

    @staticmethod
    def _next_action(category: IntentCategory) -> str:
        if category in {IntentCategory.QUERY, IntentCategory.EXPLORATION}:
            return "gather_evidence_then_compare_hypotheses"
        if category == IntentCategory.DEBUGGING:
            return "request_reproduction_and_inspect_failure_evidence"
        if category == IntentCategory.COMMAND:
            return "validate_authority_and_preconditions_before_execution"
        if category == IntentCategory.PROBLEM_SOLVING:
            return "decompose_problem_and_test_constraints"
        return "clarify_intent_or_continue_contextual_dialogue"

    @staticmethod
    def _compose_supported_response(message, evidence, knowledge, contradictions, category):
        support = len(evidence) + len(knowledge)
        text = (
            f"I interpret this as a {category.value} request. "
            f"I currently have {support} supporting knowledge/evidence item(s)."
        )
        if contradictions:
            text += f" I also see {len(contradictions)} contradiction(s), so I will not collapse them into a single conclusion."
        return text + (
            "\n\nI can give you the evidence-backed assessment now, then test the remaining uncertainty "
            "rather than treating confidence as certainty."
        )

    @staticmethod
    def _followups(category):
        if category in {IntentCategory.QUERY, IntentCategory.EXPLORATION}:
            return ["What evidence would change the conclusion?", "Should I investigate this externally?"]
        if category == IntentCategory.DEBUGGING:
            return ["Can you provide the failure trace or reproduction conditions?"]
        if category == IntentCategory.COMMAND:
            return ["Should I only plan this, or is execution explicitly authorized?"]
        return ["What aspect should Tiannara pursue next?"]
