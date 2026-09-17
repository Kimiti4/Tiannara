"""
Predictive Assistance Module - Proactive user assistance

Provides behavior analysis, proactive suggestions, trend prediction,
and personalization for intelligent user experiences.
"""

from .behavior_analyzer import BehaviorAnalyzer, UserEvent, BehaviorPattern, Prediction
from .suggestion_engine import SuggestionEngine, Suggestion
from .trend_predictor import TrendPredictor, TrendForecast
from .personalization import PersonalizationEngine, UserProfile

__all__ = [
    'BehaviorAnalyzer',
    'UserEvent',
    'BehaviorPattern',
    'Prediction',
    'SuggestionEngine',
    'Suggestion',
    'TrendPredictor',
    'TrendForecast',
    'PersonalizationEngine',
    'UserProfile'
]

__version__ = "1.0.0"
