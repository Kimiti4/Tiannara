"""
Agent Coordinator - Manages multi-agent debate and consensus
"""

import time
from typing import List, Dict, Any
from datetime import datetime

from .agents.base_agent import (
    BasePredictionAgent,
    MatchContext,
    AgentPrediction,
    ConsensusPrediction,
)


class AgentCoordinator:
    """
    Coordinates multiple prediction agents to reach consensus through:
    1. Independent predictions from each agent
    2. Cross-agent validation and debate
    3. Weighted ensemble aggregation
    4. Confidence calibration
    """
    
    def __init__(self, agents: List[BasePredictionAgent]):
        self.agents = agents
        self.agent_weights = {agent.name: 1.0 / len(agents) for agent in agents}
        self.debate_history: List[Dict[str, Any]] = []
    
    def generate_consensus(self, match_context: MatchContext) -> ConsensusPrediction:
        """Generate consensus prediction from all agents"""
        start_time = time.time()
        
        # Step 1: Get independent predictions from all agents
        agent_predictions = []
        for agent in self.agents:
            try:
                prediction = agent.predict(match_context)
                agent_predictions.append(prediction)
            except Exception as e:
                # If an agent fails, use fallback prediction
                agent_predictions.append(self._create_fallback_prediction(agent, str(e)))
        
        # Step 2: Analyze agreement/disagreement
        agreement_score = self._calculate_agreement(agent_predictions)
        
        # Step 3: Conduct debate (analyze differences)
        debate_summary = self._conduct_debate(agent_predictions, match_context)
        
        # Step 4: Calculate weighted consensus
        final_outcome, overall_confidence = self._aggregate_predictions(
            agent_predictions, agreement_score
        )
        
        # Step 5: Identify dissenting opinions
        dissenting_opinions = self._identify_dissenters(agent_predictions, final_outcome)
        
        # Step 6: Assess risk
        risk_assessment = self._assess_risk(agent_predictions, agreement_score)
        
        # Step 7: Generate recommendation
        recommended_bet = self._generate_recommendation(
            final_outcome, overall_confidence, risk_assessment
        )
        
        processing_time = (time.time() - start_time) * 1000
        
        consensus = ConsensusPrediction(
            match_id=match_context.match_id,
            final_outcome=final_outcome,
            overall_confidence=round(overall_confidence, 3),
            agent_predictions=agent_predictions,
            agreement_score=round(agreement_score, 3),
            debate_summary=debate_summary,
            dissenting_opinions=dissenting_opinions,
            recommended_bet=recommended_bet,
            risk_assessment=risk_assessment,
        )
        
        # Log the debate
        self.debate_history.append({
            'match_id': match_context.match_id,
            'timestamp': datetime.now().isoformat(),
            'processing_time_ms': round(processing_time, 2),
            'outcome': final_outcome,
            'confidence': overall_confidence,
        })
        
        return consensus
    
    def _calculate_agreement(self, predictions: List[AgentPrediction]) -> float:
        """Calculate how much agents agree (0-1)"""
        if not predictions:
            return 0.0
        
        # Count outcome frequencies
        outcome_counts = {}
        total_weight = 0
        
        for pred in predictions:
            outcome = pred.predicted_outcome
            weight = self.agent_weights.get(pred.agent_name, 1.0)
            
            if outcome not in outcome_counts:
                outcome_counts[outcome] = 0
            outcome_counts[outcome] += weight
            total_weight += weight
        
        # Agreement = max proportion
        if total_weight > 0:
            max_agreement = max(outcome_counts.values()) / total_weight
            return max_agreement
        
        return 0.0
    
    def _conduct_debate(self, predictions: List[AgentPrediction], 
                       context: MatchContext) -> List[str]:
        """Simulate agent debate and extract key insights"""
        debate_points = []
        
        # Find points of agreement
        outcomes = [p.predicted_outcome for p in predictions]
        unique_outcomes = set(outcomes)
        
        if len(unique_outcomes) == 1:
            debate_points.append(
                f"✓ All agents agree on {unique_outcomes.pop()} - strong consensus"
            )
        else:
            # Analyze disagreements
            for outcome in unique_outcomes:
                supporting_agents = [p for p in predictions if p.predicted_outcome == outcome]
                agent_names = [p.agent_name for p in supporting_agents]
                
                avg_confidence = sum(p.confidence for p in supporting_agents) / len(supporting_agents)
                
                debate_points.append(
                    f"• {outcome.upper()}: Supported by {', '.join(agent_names)} "
                    f"(avg confidence: {avg_confidence:.1%})"
                )
        
        # Extract key reasoning from highest confidence prediction
        best_prediction = max(predictions, key=lambda p: p.confidence)
        debate_points.append(f"\nHighest confidence prediction: {best_prediction.agent_name}")
        debate_points.append(f"Key insight: {best_prediction.reasoning[0] if best_prediction.reasoning else 'N/A'}")
        
        # Note major disagreements
        if len(unique_outcomes) > 1:
            confidences = [p.confidence for p in predictions]
            confidence_spread = max(confidences) - min(confidences)
            
            if confidence_spread > 0.3:
                debate_points.append(
                    f"\n⚠ Significant confidence spread ({confidence_spread:.1%}) - high uncertainty"
                )
        
        # Highlight critical factors mentioned by multiple agents
        factor_mentions = {}
        for pred in predictions:
            for factor in pred.key_factors:
                factor_name = factor['factor']
                if factor_name not in factor_mentions:
                    factor_mentions[factor_name] = 0
                factor_mentions[factor_name] += 1
        
        common_factors = [f for f, count in factor_mentions.items() if count >= 2]
        if common_factors:
            debate_points.append(f"\nCommon critical factors: {', '.join(common_factors[:3])}")
        
        return debate_points
    
    def _aggregate_predictions(self, predictions: List[AgentPrediction],
                              agreement_score: float) -> tuple:
        """Aggregate predictions using weighted voting with confidence adjustment"""
        
        # Weighted vote counting
        outcome_scores = {}
        
        for pred in predictions:
            outcome = pred.predicted_outcome
            weight = self.agent_weights.get(pred.agent_name, 1.0)
            
            # Adjust weight by confidence
            adjusted_weight = weight * pred.confidence
            
            if outcome not in outcome_scores:
                outcome_scores[outcome] = 0
            outcome_scores[outcome] += adjusted_weight
        
        # Select outcome with highest score
        final_outcome = max(outcome_scores, key=outcome_scores.get)
        
        # Calculate overall confidence
        total_score = sum(outcome_scores.values())
        if total_score > 0:
            raw_confidence = outcome_scores[final_outcome] / total_score
        else:
            raw_confidence = 0.5
        
        # Adjust confidence based on agreement
        # Higher agreement → higher confidence
        agreement_bonus = (agreement_score - 0.5) * 0.2
        overall_confidence = min(max(raw_confidence + agreement_bonus, 0.1), 0.95)
        
        return final_outcome, overall_confidence
    
    def _identify_dissenters(self, predictions: List[AgentPrediction],
                            consensus_outcome: str) -> List[Dict[str, Any]]:
        """Identify agents that disagree with consensus"""
        dissenters = []
        
        for pred in predictions:
            if pred.predicted_outcome != consensus_outcome:
                dissenters.append({
                    'agent_name': pred.agent_name,
                    'predicted_outcome': pred.predicted_outcome,
                    'confidence': pred.confidence,
                    'reasoning': pred.reasoning[:2] if pred.reasoning else [],
                })
        
        return dissenters
    
    def _assess_risk(self, predictions: List[AgentPrediction],
                    agreement_score: float) -> str:
        """Assess prediction risk level"""
        
        # Low risk: High agreement, high confidence
        if agreement_score > 0.8:
            avg_confidence = sum(p.confidence for p in predictions) / len(predictions)
            if avg_confidence > 0.7:
                return 'low'
        
        # High risk: Low agreement or low confidence
        if agreement_score < 0.5:
            return 'high'
        
        avg_confidence = sum(p.confidence for p in predictions) / len(predictions)
        if avg_confidence < 0.5:
            return 'high'
        
        # Medium risk: Everything else
        return 'medium'
    
    def _generate_recommendation(self, outcome: str, confidence: float,
                                risk: str) -> Dict[str, Any]:
        """Generate betting recommendation"""
        
        # Map outcome to bet type
        bet_types = {
            'home_win': 'Home Win (1)',
            'away_win': 'Away Win (2)',
            'draw': 'Draw (X)',
        }
        
        bet_type = bet_types.get(outcome, 'Unknown')
        
        # Calculate suggested stake based on confidence and risk
        base_stake = confidence * 10  # Scale to 0-10
        
        if risk == 'low':
            stake_multiplier = 1.0
        elif risk == 'medium':
            stake_multiplier = 0.7
        else:  # high risk
            stake_multiplier = 0.4
        
        suggested_stake = round(base_stake * stake_multiplier, 1)
        
        # Value assessment
        if confidence > 0.7:
            value_rating = 'High Value'
        elif confidence > 0.55:
            value_rating = 'Moderate Value'
        else:
            value_rating = 'Low Value / Avoid'
        
        return {
            'bet_type': bet_type,
            'confidence': confidence,
            'risk_level': risk,
            'suggested_stake': suggested_stake,
            'value_rating': value_rating,
            'note': f"{'Strong recommendation' if confidence > 0.7 else 'Proceed with caution' if confidence > 0.5 else 'Not recommended'}",
        }
    
    def _create_fallback_prediction(self, agent: BasePredictionAgent,
                                   error: str) -> AgentPrediction:
        """Create fallback prediction when agent fails"""
        return AgentPrediction(
            agent_name=agent.name,
            agent_type=agent.agent_type,
            predicted_outcome='draw',
            confidence=0.33,
            reasoning=[f"Agent failed: {error}", "Fallback to neutral prediction"],
            uncertainty_notes=["Agent execution failed"],
            processing_time_ms=0.0,
        )
    
    def get_agent_performance_stats(self) -> List[Dict[str, Any]]:
        """Get performance statistics for all agents"""
        return [agent.get_agent_stats() for agent in self.agents]
