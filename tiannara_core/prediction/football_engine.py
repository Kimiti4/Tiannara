"""
Football Prediction Engine - Main orchestrator for multi-agent football predictions
"""

import logging
from typing import Dict, List, Any, Optional
from datetime import datetime

from .agents.base_agent import MatchContext, ConsensusPrediction
from .agents.statistical_agent import StatisticalAgent
from .agents.ml_agent import MLAgent
from .agents.expert_agent import ExpertAgent
from .coordinator import AgentCoordinator
from .data_sources.match_data_fetcher import MatchDataFetcher

logger = logging.getLogger(__name__)


class FootballPredictionEngine:
    """
    Main prediction engine that orchestrates:
    1. Data fetching (real-time team stats, form, injuries)
    2. Multi-agent prediction (3 competing agents)
    3. Agent debate and consensus building
    4. Result aggregation and confidence scoring
    
    Usage:
        engine = FootballPredictionEngine()
        prediction = engine.predict_match('match_id_123')
    """
    
    def __init__(self, use_mock_data: bool = True):
        logger.info("Initializing Football Prediction Engine")
        
        # Initialize data fetcher
        self.data_fetcher = MatchDataFetcher(use_mock_data=use_mock_data)
        
        # Initialize 3 prediction agents
        self.agents = [
            StatisticalAgent(),  # Agent 1: Statistical analysis
            MLAgent(),           # Agent 2: Machine learning
            ExpertAgent(),       # Agent 3: Expert rules
        ]
        
        # Initialize coordinator
        self.coordinator = AgentCoordinator(self.agents)
        
        # Prediction history
        self.prediction_history: List[Dict[str, Any]] = []
        
        logger.info(f"Football Prediction Engine ready with {len(self.agents)} agents")
    
    def predict_match(self, match_id: str) -> Optional[ConsensusPrediction]:
        """
        Generate prediction for a specific match
        
        Args:
            match_id: Unique identifier for the match
            
        Returns:
            ConsensusPrediction with all agent predictions and final consensus
        """
        try:
            logger.info(f"Generating prediction for match: {match_id}")
            
            # Step 1: Fetch match data
            match_context = self.data_fetcher.fetch_match_context(match_id)
            
            if not match_context:
                logger.error(f"Failed to fetch data for match: {match_id}")
                return None
            
            logger.info(
                f"Match context loaded: {match_context.home_team.team_name} vs "
                f"{match_context.away_team.team_name}"
            )
            
            # Step 2: Generate consensus prediction
            consensus = self.coordinator.generate_consensus(match_context)
            
            # Step 3: Store in history
            self.prediction_history.append({
                'match_id': match_id,
                'timestamp': datetime.now().isoformat(),
                'outcome': consensus.final_outcome,
                'confidence': consensus.overall_confidence,
                'agreement': consensus.agreement_score,
            })
            
            logger.info(
                f"Prediction complete: {consensus.final_outcome} "
                f"(confidence: {consensus.overall_confidence:.1%})"
            )
            
            return consensus
            
        except Exception as e:
            logger.error(f"Error predicting match {match_id}: {str(e)}", exc_info=True)
            return None
    
    def predict_multiple_matches(self, match_ids: List[str]) -> List[ConsensusPrediction]:
        """
        Generate predictions for multiple matches
        
        Args:
            match_ids: List of match identifiers
            
        Returns:
            List of ConsensusPredictions
        """
        predictions = []
        
        for match_id in match_ids:
            prediction = self.predict_match(match_id)
            if prediction:
                predictions.append(prediction)
        
        return predictions
    
    def get_upcoming_matches(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get list of upcoming matches available for prediction"""
        return self.data_fetcher.get_upcoming_matches(limit)
    
    def get_agent_stats(self) -> List[Dict[str, Any]]:
        """Get performance statistics for all agents"""
        return self.coordinator.get_agent_performance_stats()
    
    def get_prediction_history(self, limit: int = 50) -> List[Dict[str, Any]]:
        """Get recent prediction history"""
        return self.prediction_history[-limit:]
    
    def get_engine_status(self) -> Dict[str, Any]:
        """Get current engine status and metrics"""
        return {
            'status': 'operational',
            'agents_count': len(self.agents),
            'agent_names': [agent.name for agent in self.agents],
            'total_predictions': len(self.prediction_history),
            'agents_performance': self.get_agent_stats(),
            'data_source': 'mock' if self.data_fetcher.use_mock_data else 'live',
            'last_updated': datetime.now().isoformat(),
        }
    
    def reset_history(self):
        """Clear prediction history"""
        self.prediction_history.clear()
        logger.info("Prediction history cleared")
