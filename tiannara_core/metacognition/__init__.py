"""
Meta-Cognition Domain for Tiannara Core

Enables self-awareness, self-monitoring, and autonomous improvement.
"""

from .monitor import MetaCognitiveMonitor
from .performance_tracker import DomainPerformanceTracker
from .quality_evaluator import ReasoningQualityEvaluator
from .gap_detector import KnowledgeGapDetector
from .self_reflection import SelfReflectionCycle

__all__ = [
    'MetaCognitiveMonitor',
    'DomainPerformanceTracker',
    'ReasoningQualityEvaluator',
    'KnowledgeGapDetector',
    'SelfReflectionCycle'
]
