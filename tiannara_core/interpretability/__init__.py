"""
Tiannara Core Interpretability Module

Provides explainable AI capabilities for Executable Causal Manifolds,
including causal path tracing, counterfactual reasoning, and natural
language explanation generation.

EU AI Act Compliance: Supports Articles 13-15 (Right to Explanation)
"""

from .causal_path_tracer import (
    CausalPathTracer,
    CausalPath,
    PathExplanation,
    InterventionRecord,
    trace_causal_path
)
from .counterfactual_engine import (
    CounterfactualEngine,
    CounterfactualQuery,
    CounterfactualResult,
    MinimalIntervention,
    answer_what_if
)
from .nlg import (
    NaturalLanguageGenerator,
    NarrativeExplanation,
    AudienceLevel,
    generate_explanation
)
from .confidence_calibration import (
    ConfidenceCalibration,
    CalibrationResult,
    ReliabilityDiagram,
    calibrate_causal_claim
)
from .audit_trail import (
    ExplanationAuditTrail,
    AuditRecord,
    create_audit_trail
)
from .explanation_engine import (
    ExplanationEngine,
    ComprehensiveExplanation,
    create_explanation_engine
)

__all__ = [
    'CausalPathTracer',
    'CausalPath',
    'PathExplanation',
    'InterventionRecord',
    'trace_causal_path',
    'CounterfactualEngine',
    'CounterfactualQuery',
    'CounterfactualResult',
    'MinimalIntervention',
    'answer_what_if',
    'NaturalLanguageGenerator',
    'NarrativeExplanation',
    'AudienceLevel',
    'generate_explanation',
    'ConfidenceCalibration',
    'CalibrationResult',
    'ReliabilityDiagram',
    'calibrate_causal_claim',
    'ExplanationAuditTrail',
    'AuditRecord',
    'create_audit_trail',
    'ExplanationEngine',
    'ComprehensiveExplanation',
    'create_explanation_engine'
]
