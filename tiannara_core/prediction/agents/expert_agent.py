"""
Expert Rules Agent - Domain knowledge and expert heuristics
"""

import time
from typing import List, Dict, Any
from .base_agent import (
    BasePredictionAgent,
    MatchContext,
    AgentPrediction,
)


class ExpertAgent(BasePredictionAgent):
    """
    Expert system prediction agent using domain knowledge:
    - Team motivation and match importance
    - Injury impact assessment
    - Tactical matchup analysis
    - Weather and environmental factors
    - Psychological factors (pressure, rivalry)
    """
    
    def __init__(self):
        super().__init__(name="Expert Analyst", agent_type="expert_rules")
        
        # Expert knowledge base
        self.expert_rules = {
            'injury_impact': {
                'key_player': 0.25,  # Losing key player reduces win probability by 25%
                'goalkeeper': 0.20,
                'striker': 0.18,
                'midfielder': 0.12,
                'defender': 0.15,
            },
            'motivation_factors': {
                'derby': 0.15,  # Derby matches are more unpredictable
                'relegation_battle': 0.20,
                'title_race': 0.18,
                'cup_final': 0.22,
            },
            'weather_impact': {
                'heavy_rain': -0.10,  # Reduces scoring
                'snow': -0.15,
                'extreme_heat': -0.08,
                'strong_wind': -0.12,
            },
        }
    
    def predict(self, match_context: MatchContext) -> AgentPrediction:
        start_time = time.time()
        
        # Apply expert rules
        home_score = self._evaluate_team(match_context.home_team, is_home=True, context=match_context)
        away_score = self._evaluate_team(match_context.away_team, is_home=False, context=match_context)
        
        # Calculate outcome probabilities
        total = home_score + away_score
        if total > 0:
            home_prob = home_score / total
            away_prob = away_score / total
        else:
            home_prob = 0.33
            away_prob = 0.33
        
        draw_prob = 1 - abs(home_prob - away_prob) * 0.7  # Draws more likely when teams are even
        
        # Normalize probabilities
        prob_sum = home_prob + away_prob + draw_prob
        home_prob /= prob_sum
        away_prob /= prob_sum
        draw_prob /= prob_sum
        
        # Determine outcome
        probs = {'home_win': home_prob, 'away_win': away_prob, 'draw': draw_prob}
        predicted_outcome = max(probs, key=probs.get)
        confidence = probs[predicted_outcome]
        
        # Predict score based on expert assessment
        predicted_score = self._predict_score_expert(match_context, home_prob, away_prob)
        
        processing_time = (time.time() - start_time) * 1000
        
        return AgentPrediction(
            agent_name=self.name,
            agent_type=self.agent_type,
            predicted_outcome=predicted_outcome,
            confidence=round(confidence, 3),
            predicted_score=predicted_score,
            reasoning=self.get_reasoning(match_context),
            key_factors=self._identify_key_factors(match_context),
            uncertainty_notes=self._assess_uncertainties(match_context),
            processing_time_ms=round(processing_time, 2)
        )
    
    def get_reasoning(self, match_context: MatchContext) -> List[str]:
        reasoning = []
        
        # Injury analysis
        home_injuries = len(match_context.home_team.injuries)
        away_injuries = len(match_context.away_team.injuries)
        
        if home_injuries > 0:
            injury_impact = self._assess_injury_impact(match_context.home_team)
            reasoning.append(f"Home team injuries: {home_injuries} players out (impact: {injury_impact:.0%})")
        
        if away_injuries > 0:
            injury_impact = self._assess_injury_impact(match_context.away_team)
            reasoning.append(f"Away team injuries: {away_injuries} players out (impact: {injury_impact:.0%})")
        
        # Match importance
        importance = match_context.match_importance
        if importance in ['high', 'critical']:
            reasoning.append(f"High-stakes match ({importance}) - expect cautious approach")
        
        # Motivation factors
        if 'derby' in match_context.competition.lower():
            reasoning.append("Derby match - form often goes out the window, expect intense battle")
        
        # Weather conditions
        weather = match_context.weather
        if weather:
            weather_factor = self._assess_weather_impact(weather)
            if weather_factor != 0:
                reasoning.append(f"Weather impact: {weather.get('condition', 'unknown')} (effect: {weather_factor:+.0%} on scoring)")
        
        # Tactical considerations
        home_possession = match_context.home_team.possession_avg
        away_possession = match_context.away_team.possession_avg
        
        if home_possession > 60:
            reasoning.append("Home team dominates possession - will control tempo")
        elif away_possession > 60:
            reasoning.append("Away team dominates possession - may struggle away from home")
        
        # Suspensions
        home_suspensions = len(match_context.home_team.suspensions)
        away_suspensions = len(match_context.away_team.suspensions)
        
        if home_suspensions > 0 or away_suspensions > 0:
            reasoning.append(f"Suspensions: Home {home_suspensions}, Away {away_suspensions}")
        
        # Form momentum
        home_recent = match_context.home_team.recent_form[:3]
        away_recent = match_context.away_team.recent_form[:3]
        
        home_wins = sum(1 for r in home_recent if r == 'W')
        away_wins = sum(1 for r in away_recent if r == 'W')
        
        if home_wins >= 2:
            reasoning.append(f"Home team on strong run ({home_wins}/3 wins) - high confidence")
        elif away_wins >= 2:
            reasoning.append(f"Away team on strong run ({away_wins}/3 wins) - dangerous opponent")
        
        return reasoning
    
    def _evaluate_team(self, team, is_home: bool, context: MatchContext) -> float:
        """Evaluate team strength using expert rules"""
        base_score = 1.0
        
        # Form evaluation
        form_score = self._evaluate_form(team.recent_form)
        base_score *= (0.7 + form_score * 0.3)
        
        # Home/away factor
        if is_home:
            record = team.home_record
            total = sum(record.values())
            if total > 0:
                home_strength = record['wins'] / total
                base_score *= (0.8 + home_strength * 0.4)
        else:
            record = team.away_record
            total = sum(record.values())
            if total > 0:
                away_strength = record['wins'] / total
                base_score *= (0.6 + away_strength * 0.4)
        
        # Injury impact
        injury_penalty = self._assess_injury_impact(team)
        base_score *= (1 - injury_penalty)
        
        # Suspension impact
        suspension_penalty = len(team.suspensions) * 0.08
        base_score *= (1 - suspension_penalty)
        
        # Goal-scoring ability
        goal_factor = min(team.goals_scored_avg / 2.0, 1.5)
        base_score *= goal_factor
        
        # Defensive solidity
        defense_factor = max(1 - (team.goals_conceded_avg / 3.0), 0.5)
        base_score *= defense_factor
        
        # Match importance adjustment
        if context.match_importance == 'critical':
            # Teams under pressure may underperform or overperform
            base_score *= 0.95  # Slight caution factor
        
        return max(0.3, base_score)
    
    def _evaluate_form(self, recent_form: List[str]) -> float:
        """Evaluate form with expert weighting"""
        if not recent_form:
            return 0.5
        
        # Expert rule: Last match matters most, but consistency is key
        weights = [0.4, 0.3, 0.2, 0.1][:len(recent_form)]
        
        score = 0
        for i, result in enumerate(recent_form[:4]):
            weight = weights[i]
            if result == 'W':
                score += weight
            elif result == 'D':
                score += weight * 0.5
        
        return score
    
    def _assess_injury_impact(self, team) -> float:
        """Assess cumulative injury impact"""
        if not team.injuries:
            return 0.0
        
        total_impact = 0
        for injury in team.injuries:
            position = injury.get('position', 'unknown').lower()
            importance = injury.get('importance', 'regular')
            
            if position in self.expert_rules['injury_impact']:
                base_impact = self.expert_rules['injury_impact'][position]
                
                # Adjust for player importance
                if importance == 'key':
                    base_impact *= 1.5
                elif importance == 'star':
                    base_impact *= 2.0
                
                total_impact += base_impact
        
        return min(total_impact, 0.5)  # Cap at 50% impact
    
    def _assess_weather_impact(self, weather: Dict[str, Any]) -> float:
        """Assess weather impact on match"""
        condition = weather.get('condition', '').lower()
        
        for weather_type, impact in self.expert_rules['weather_impact'].items():
            if weather_type.replace('_', ' ') in condition:
                return impact
        
        return 0.0
    
    def _predict_score_expert(self, context: MatchContext, home_prob: float, away_prob: float) -> Dict[str, int]:
        """Predict score using expert heuristics"""
        # Base expectations
        home_xg = context.home_team.goals_scored_avg
        away_xg = context.away_team.goals_scored_avg
        
        # Adjust for home advantage
        if context.venue == 'home':
            home_xg *= 1.2
            away_xg *= 0.85
        
        # Adjust for injuries
        home_injury_factor = 1 - self._assess_injury_impact(context.home_team)
        away_injury_factor = 1 - self._assess_injury_impact(context.away_team)
        
        home_xg *= home_injury_factor
        away_xg *= away_injury_factor
        
        # Adjust for weather
        weather_impact = self._assess_weather_impact(context.weather)
        home_xg *= (1 + weather_impact)
        away_xg *= (1 + weather_impact)
        
        # Round to integers
        home_goals = max(0, round(home_xg))
        away_goals = max(0, round(away_xg))
        
        # Ensure prediction aligns with outcome probability
        if home_prob > away_prob and home_goals <= away_goals:
            home_goals = away_goals + 1
        elif away_prob > home_prob and away_goals <= home_goals:
            away_goals = home_goals + 1
        
        return {'home': home_goals, 'away': away_goals}
    
    def _identify_key_factors(self, context: MatchContext) -> List[Dict[str, Any]]:
        """Identify key decision factors"""
        factors = []
        
        # Injuries
        home_injury_impact = self._assess_injury_impact(context.home_team)
        away_injury_impact = self._assess_injury_impact(context.away_team)
        
        if home_injury_impact > 0.1:
            factors.append({
                'factor': 'Home Team Injuries',
                'value': round(home_injury_impact, 3),
                'impact': 'negative'
            })
        
        if away_injury_impact > 0.1:
            factors.append({
                'factor': 'Away Team Injuries',
                'value': round(away_injury_impact, 3),
                'impact': 'negative'
            })
        
        # Form
        home_form = self._evaluate_form(context.home_team.recent_form)
        away_form = self._evaluate_form(context.away_team.recent_form)
        
        factors.append({'factor': 'Home Form', 'value': round(home_form, 3), 'impact': 'positive'})
        factors.append({'factor': 'Away Form', 'value': round(away_form, 3), 'impact': 'positive'})
        
        # Motivation
        if context.match_importance in ['high', 'critical']:
            factors.append({
                'factor': 'Match Importance',
                'value': context.match_importance,
                'impact': 'psychological'
            })
        
        return factors
    
    def _assess_uncertainties(self, context: MatchContext) -> List[str]:
        """Identify sources of uncertainty"""
        uncertainties = []
        
        # Limited data
        if len(context.home_team.recent_form) < 3:
            uncertainties.append("Insufficient recent form data for home team")
        
        if len(context.away_team.recent_form) < 3:
            uncertainties.append("Insufficient recent form data for away team")
        
        # High-impact injuries
        if self._assess_injury_impact(context.home_team) > 0.3:
            uncertainties.append("Major injuries could significantly impact home team performance")
        
        if self._assess_injury_impact(context.away_team) > 0.3:
            uncertainties.append("Major injuries could significantly impact away team performance")
        
        # Weather
        if context.weather:
            condition = context.weather.get('condition', '').lower()
            if any(w in condition for w in ['rain', 'snow', 'storm']):
                uncertainties.append("Adverse weather conditions add unpredictability")
        
        # High-stakes match
        if context.match_importance == 'critical':
            uncertainties.append("Critical match - psychological factors may override form")
        
        # Derby/rivalry
        if 'derby' in context.competition.lower() or 'rival' in context.competition.lower():
            uncertainties.append("Rivalry match - historical form less predictive")
        
        return uncertainties
