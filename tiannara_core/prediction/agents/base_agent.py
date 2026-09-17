"""
Base Prediction Agent - Abstract interface for all prediction agents
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Dict, List, Any, Optional
from datetime import datetime


@dataclass
class TeamStats:
    """Team statistics and form data"""
    team_id: str
    team_name: str
    recent_form: List[str] = field(default_factory=list)  # ['W', 'D', 'L']
    goals_scored_avg: float = 0.0
    goals_conceded_avg: float = 0.0
    possession_avg: float = 50.0
    shots_on_target_avg: float = 0.0
    pass_accuracy: float = 0.0
    home_record: Dict[str, int] = field(default_factory=lambda: {'wins': 0, 'draws': 0, 'losses': 0})
    away_record: Dict[str, int] = field(default_factory=lambda: {'wins': 0, 'draws': 0, 'losses': 0})
    injuries: List[Dict[str, str]] = field(default_factory=list)
    suspensions: List[Dict[str, str]] = field(default_factory=list)


@dataclass
class HeadToHead:
    """Historical head-to-head record"""
    total_matches: int = 0
    team_a_wins: int = 0
    team_b_wins: int = 0
    draws: int = 0
    last_5_meetings: List[Dict[str, Any]] = field(default_factory=list)
    avg_goals_per_match: float = 0.0


@dataclass
class MatchContext:
    """Complete match context for prediction"""
    match_id: str
    home_team: TeamStats
    away_team: TeamStats
    head_to_head: HeadToHead
    venue: str = "neutral"
    weather: Dict[str, Any] = field(default_factory=dict)
    competition: str = ""
    match_importance: str = "normal"  # normal, high, critical
    referee: Optional[str] = None
    timestamp: datetime = field(default_factory=datetime.now)


@dataclass
class AgentPrediction:
    """Individual agent prediction result"""
    agent_name: str
    agent_type: str
    predicted_outcome: str  # 'home_win', 'away_win', 'draw'
    confidence: float  # 0.0 to 1.0
    predicted_score: Optional[Dict[str, int]] = None  # {'home': 2, 'away': 1}
    reasoning: List[str] = field(default_factory=list)
    key_factors: List[Dict[str, Any]] = field(default_factory=list)
    uncertainty_notes: List[str] = field(default_factory=list)
    processing_time_ms: float = 0.0
    timestamp: datetime = field(default_factory=datetime.now)
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'agent_name': self.agent_name,
            'agent_type': self.agent_type,
            'predicted_outcome': self.predicted_outcome,
            'confidence': self.confidence,
            'predicted_score': self.predicted_score,
            'reasoning': self.reasoning,
            'key_factors': self.key_factors,
            'uncertainty_notes': self.uncertainty_notes,
            'processing_time_ms': self.processing_time_ms,
            'timestamp': self.timestamp.isoformat(),
        }


@dataclass
class ConsensusPrediction:
    """Final consensus prediction from all agents"""
    match_id: str
    final_outcome: str
    overall_confidence: float
    agent_predictions: List[AgentPrediction]
    agreement_score: float  # How much agents agree (0-1)
    debate_summary: List[str] = field(default_factory=list)
    dissenting_opinions: List[Dict[str, Any]] = field(default_factory=list)
    recommended_bet: Optional[Dict[str, Any]] = None
    risk_assessment: str = "medium"  # low, medium, high
    generated_at: datetime = field(default_factory=datetime.now)
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'match_id': self.match_id,
            'final_outcome': self.final_outcome,
            'overall_confidence': self.overall_confidence,
            'agent_predictions': [p.to_dict() for p in self.agent_predictions],
            'agreement_score': self.agreement_score,
            'debate_summary': self.debate_summary,
            'dissenting_opinions': self.dissenting_opinions,
            'recommended_bet': self.recommended_bet,
            'risk_assessment': self.risk_assessment,
            'generated_at': self.generated_at.isoformat(),
        }


class BasePredictionAgent(ABC):
    """Abstract base class for all prediction agents"""
    
    def __init__(self, name: str, agent_type: str):
        self.name = name
        self.agent_type = agent_type
        self.prediction_count = 0
        self.avg_confidence = 0.0
    
    @abstractmethod
    def predict(self, match_context: MatchContext) -> AgentPrediction:
        """Generate prediction for a match"""
        pass
    
    @abstractmethod
    def get_reasoning(self, match_context: MatchContext) -> List[str]:
        """Explain the reasoning behind predictions"""
        pass
    
    def calculate_confidence(self, factors: List[float]) -> float:
        """Calculate confidence score from multiple factors"""
        if not factors:
            return 0.5
        
        # Weighted average with diminishing returns
        weights = [0.4, 0.3, 0.2, 0.1][:len(factors)]
        weighted_sum = sum(f * w for f, w in zip(factors, weights))
        
        # Normalize to 0-1 range
        confidence = min(max(weighted_sum, 0.0), 1.0)
        
        # Update running average
        self.prediction_count += 1
        self.avg_confidence = (
            (self.avg_confidence * (self.prediction_count - 1) + confidence) / 
            self.prediction_count
        )
        
        return confidence
    
    def get_agent_stats(self) -> Dict[str, Any]:
        """Get agent performance statistics"""
        return {
            'name': self.name,
            'type': self.agent_type,
            'prediction_count': self.prediction_count,
            'avg_confidence': round(self.avg_confidence, 3),
        }
