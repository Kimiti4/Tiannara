"""
Agents module for football prediction
"""

from .base_agent import (
    BasePredictionAgent,
    TeamStats,
    HeadToHead,
    MatchContext,
    AgentPrediction,
    ConsensusPrediction,
)
from .statistical_agent import StatisticalAgent
from .ml_agent import MLAgent
from .expert_agent import ExpertAgent

__all__ = [
    'BasePredictionAgent',
    'TeamStats',
    'HeadToHead',
    'MatchContext',
    'AgentPrediction',
    'ConsensusPrediction',
    'StatisticalAgent',
    'MLAgent',
    'ExpertAgent',
]
