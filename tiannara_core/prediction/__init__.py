"""
Football Prediction Domain - Multi-Agent Prediction System

Provides real-time football match predictions using 3 competing AI agents:
- Statistical Agent: Historical data analysis
- ML-Based Agent: Machine learning predictions  
- Expert Rules Agent: Domain knowledge reasoning
"""

from .football_engine import FootballPredictionEngine
from .agents.base_agent import BasePredictionAgent
from .agents.statistical_agent import StatisticalAgent
from .agents.ml_agent import MLAgent
from .agents.expert_agent import ExpertAgent
from .coordinator import AgentCoordinator
from .data_sources import MatchDataFetcher

__all__ = [
    'FootballPredictionEngine',
    'BasePredictionAgent',
    'StatisticalAgent',
    'MLAgent',
    'ExpertAgent',
    'AgentCoordinator',
    'MatchDataFetcher',
]
