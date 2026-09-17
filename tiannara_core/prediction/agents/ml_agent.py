"""
ML-Based Agent - Uses machine learning features for predictions
"""

import time
import math
from typing import List, Dict, Any
from .base_agent import (
    BasePredictionAgent,
    MatchContext,
    AgentPrediction,
)


class MLAgent(BasePredictionAgent):
    """
    Machine Learning prediction agent that uses:
    - Feature engineering from team statistics
    - Weighted feature importance scoring
    - Pattern recognition in historical data
    - Ensemble of simple ML models (simulated)
    """
    
    def __init__(self):
        super().__init__(name="ML Predictor", agent_type="machine_learning")
        # Feature weights learned from training (simulated)
        self.feature_weights = {
            'form_score': 0.18,
            'goal_diff': 0.15,
            'home_advantage': 0.12,
            'possession': 0.08,
            'shots_accuracy': 0.10,
            'pass_accuracy': 0.07,
            'h2h_dominance': 0.13,
            'recent_momentum': 0.10,
            'defensive_strength': 0.07,
        }
    
    def predict(self, match_context: MatchContext) -> AgentPrediction:
        start_time = time.time()
        
        # Extract and engineer features
        features = self._extract_features(match_context)
        
        # Apply ML model (weighted sum simulation)
        home_score = self._apply_model(features, is_home=True)
        away_score = self._apply_model(features, is_home=False)
        
        # Calculate probabilities using softmax
        probabilities = self._softmax([home_score, away_score, (home_score + away_score) / 2])
        
        # Determine outcome based on highest probability
        outcomes = ['home_win', 'away_win', 'draw']
        max_prob_idx = probabilities.index(max(probabilities))
        predicted_outcome = outcomes[max_prob_idx]
        confidence = probabilities[max_prob_idx]
        
        # Predict score using Poisson distribution approximation
        home_goals = self._poisson_predict(features['home_expected_goals'])
        away_goals = self._poisson_predict(features['away_expected_goals'])
        
        processing_time = (time.time() - start_time) * 1000
        
        return AgentPrediction(
            agent_name=self.name,
            agent_type=self.agent_type,
            predicted_outcome=predicted_outcome,
            confidence=round(confidence, 3),
            predicted_score={'home': home_goals, 'away': away_goals},
            reasoning=self.get_reasoning(match_context),
            key_factors=[
                {'factor': 'Form Score Impact', 'value': round(features['form_score'] * self.feature_weights['form_score'], 3)},
                {'factor': 'Goal Difference', 'value': round(features['goal_diff'] * self.feature_weights['goal_diff'], 3)},
                {'factor': 'Home Advantage', 'value': round(features['home_advantage'] * self.feature_weights['home_advantage'], 3)},
                {'factor': 'H2H Dominance', 'value': round(features['h2h_dominance'] * self.feature_weights['h2h_dominance'], 3)},
                {'factor': 'Momentum', 'value': round(features['recent_momentum'] * self.feature_weights['recent_momentum'], 3)},
            ],
            uncertainty_notes=self._assess_uncertainty(probabilities, match_context),
            processing_time_ms=round(processing_time, 2)
        )
    
    def get_reasoning(self, match_context: MatchContext) -> List[str]:
        features = self._extract_features(match_context)
        
        reasoning = [
            "ML Model Analysis (Feature Importance):",
            f"  - Form differential: {features['form_score']:.3f} (weight: {self.feature_weights['form_score']})",
            f"  - Goal difference: {features['goal_diff']:.3f} (weight: {self.feature_weights['goal_diff']})",
            f"  - Home advantage factor: {features['home_advantage']:.3f} (weight: {self.feature_weights['home_advantage']})",
            f"  - H2H dominance: {features['h2h_dominance']:.3f} (weight: {self.feature_weights['h2h_dominance']})",
            f"  - Recent momentum: {features['recent_momentum']:.3f} (weight: {self.feature_weights['recent_momentum']})",
        ]
        
        # Top contributing features
        sorted_features = sorted(
            self.feature_weights.items(),
            key=lambda x: x[1],
            reverse=True
        )
        
        top_3 = sorted_features[:3]
        reasoning.append(f"\nTop 3 predictive features: {', '.join([f[0] for f in top_3])}")
        
        return reasoning
    
    def _extract_features(self, match_context: MatchContext) -> Dict[str, float]:
        """Extract and normalize features from match context"""
        
        # Form score (-1 to 1)
        home_form = self._calculate_weighted_form(match_context.home_team.recent_form)
        away_form = self._calculate_weighted_form(match_context.away_team.recent_form)
        form_score = (home_form - away_form) / 2  # Normalize to -1 to 1
        
        # Goal difference
        home_goal_diff = match_context.home_team.goals_scored_avg - match_context.home_team.goals_conceded_avg
        away_goal_diff = match_context.away_team.goals_scored_avg - match_context.away_team.goals_conceded_avg
        goal_diff = (home_goal_diff - away_goal_diff) / 4  # Normalize
        
        # Home advantage
        home_record = match_context.home_team.home_record
        total_home = sum(home_record.values())
        home_advantage = home_record['wins'] / total_home if total_home > 0 else 0.5
        
        # Possession differential
        possession_diff = (match_context.home_team.possession_avg - 50) / 50
        
        # Shots accuracy
        home_shots = match_context.home_team.shots_on_target_avg / 10  # Normalize
        away_shots = match_context.away_team.shots_on_target_avg / 10
        shots_accuracy = (home_shots - away_shots) / 2
        
        # Pass accuracy
        pass_diff = (match_context.home_team.pass_accuracy - match_context.away_team.pass_accuracy) / 100
        
        # H2H dominance
        h2h = match_context.head_to_head
        if h2h.total_matches > 0:
            h2h_dominance = (h2h.team_a_wins - h2h.team_b_wins) / h2h.total_matches
        else:
            h2h_dominance = 0.0
        
        # Recent momentum (last 3 matches trend)
        home_momentum = self._calculate_momentum(match_context.home_team.recent_form[:3])
        away_momentum = self._calculate_momentum(match_context.away_team.recent_form[:3])
        recent_momentum = (home_momentum - away_momentum) / 2
        
        # Defensive strength
        home_defense = 1 - (match_context.home_team.goals_conceded_avg / 3)  # Normalize
        away_defense = 1 - (match_context.away_team.goals_conceded_avg / 3)
        defensive_strength = (home_defense - away_defense) / 2
        
        # Expected goals
        home_xg = match_context.home_team.goals_scored_avg * 1.15  # Home boost
        away_xg = match_context.away_team.goals_scored_avg * 0.90  # Away penalty
        
        return {
            'form_score': form_score,
            'goal_diff': goal_diff,
            'home_advantage': home_advantage,
            'possession': possession_diff,
            'shots_accuracy': shots_accuracy,
            'pass_accuracy': pass_diff,
            'h2h_dominance': h2h_dominance,
            'recent_momentum': recent_momentum,
            'defensive_strength': defensive_strength,
            'home_expected_goals': home_xg,
            'away_expected_goals': away_xg,
        }
    
    def _apply_model(self, features: Dict[str, float], is_home: bool) -> float:
        """Apply weighted model to features"""
        score = 0.0
        
        if is_home:
            score += features['form_score'] * self.feature_weights['form_score']
            score += features['goal_diff'] * self.feature_weights['goal_diff']
            score += features['home_advantage'] * self.feature_weights['home_advantage']
            score += features['h2h_dominance'] * self.feature_weights['h2h_dominance']
            score += features['recent_momentum'] * self.feature_weights['recent_momentum']
            score += features['defensive_strength'] * self.feature_weights['defensive_strength']
            score += features['possession'] * self.feature_weights['possession']
            score += features['shots_accuracy'] * self.feature_weights['shots_accuracy']
            score += features['pass_accuracy'] * self.feature_weights['pass_accuracy']
        else:
            # Invert features for away team
            score -= features['form_score'] * self.feature_weights['form_score']
            score -= features['goal_diff'] * self.feature_weights['goal_diff']
            score += (1 - features['home_advantage']) * self.feature_weights['home_advantage']
            score -= features['h2h_dominance'] * self.feature_weights['h2h_dominance']
            score -= features['recent_momentum'] * self.feature_weights['recent_momentum']
            score -= features['defensive_strength'] * self.feature_weights['defensive_strength']
            score -= features['possession'] * self.feature_weights['possession']
            score -= features['shots_accuracy'] * self.feature_weights['shots_accuracy']
            score -= features['pass_accuracy'] * self.feature_weights['pass_accuracy']
        
        return score
    
    def _softmax(self, values: List[float]) -> List[float]:
        """Apply softmax to convert scores to probabilities"""
        # Subtract max for numerical stability
        max_val = max(values)
        exp_values = [math.exp(v - max_val) for v in values]
        sum_exp = sum(exp_values)
        return [e / sum_exp for e in exp_values]
    
    def _poisson_predict(self, expected_goals: float) -> int:
        """Predict goals using Poisson distribution approximation"""
        # Simple approximation: round to nearest integer with some randomness
        import random
        lambda_param = max(0.5, expected_goals)
        
        # Use cumulative distribution to sample
        k = 0
        p = math.exp(-lambda_param)
        cumulative = p
        
        rand_val = random.random()
        while cumulative < rand_val and k < 6:
            k += 1
            p *= lambda_param / k
            cumulative += p
        
        return min(k, 5)  # Cap at 5 goals
    
    def _calculate_weighted_form(self, results: List[str]) -> float:
        """Calculate weighted form score"""
        if not results:
            return 0.0
        
        points = 0
        total_weight = 0
        
        for i, result in enumerate(results):
            weight = 1.0 / (i + 1)
            total_weight += weight
            
            if result == 'W':
                points += weight
            elif result == 'D':
                points += weight * 0.5
        
        return points / total_weight if total_weight > 0 else 0.0
    
    def _calculate_momentum(self, recent_results: List[str]) -> float:
        """Calculate momentum from recent results (-1 to 1)"""
        if not recent_results:
            return 0.0
        
        # Assign values: W=1, D=0, L=-1
        values = []
        for r in recent_results:
            if r == 'W':
                values.append(1)
            elif r == 'D':
                values.append(0)
            else:
                values.append(-1)
        
        # Weighted average with more recent having higher weight
        weighted_sum = sum(v * (i + 1) for i, v in enumerate(reversed(values)))
        total_weight = sum(range(1, len(values) + 1))
        
        return weighted_sum / total_weight if total_weight > 0 else 0.0
    
    def _assess_uncertainty(self, probabilities: List[float], match_context: MatchContext) -> List[str]:
        """Assess prediction uncertainty"""
        uncertainties = []
        
        # Check probability spread
        max_prob = max(probabilities)
        if max_prob < 0.5:
            uncertainties.append("Low confidence - all outcomes relatively equally likely")
        
        # Check for close probabilities
        sorted_probs = sorted(probabilities, reverse=True)
        if sorted_probs[0] - sorted_probs[1] < 0.1:
            uncertainties.append("Very close prediction - small margin between top outcomes")
        
        # Data quality issues
        if not match_context.home_team.recent_form:
            uncertainties.append("No recent form data for home team")
        
        if not match_context.away_team.recent_form:
            uncertainties.append("No recent form data for away team")
        
        if match_context.head_to_head.total_matches < 2:
            uncertainties.append("Limited H2H history")
        
        return uncertainties
