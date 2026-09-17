"""
Statistical Agent - Analyzes historical data, form, and head-to-head records
"""

import time
from typing import List, Dict, Any
from .base_agent import (
    BasePredictionAgent,
    MatchContext,
    AgentPrediction,
)


class StatisticalAgent(BasePredictionAgent):
    """
    Statistical prediction agent that analyzes:
    - Recent team form (last 5-10 matches)
    - Head-to-head historical records
    - Home/away performance patterns
    - Goal scoring/conceding trends
    """
    
    def __init__(self):
        super().__init__(name="Statistical Analyst", agent_type="statistical")
    
    def predict(self, match_context: MatchContext) -> AgentPrediction:
        start_time = time.time()
        
        # Calculate form scores
        home_form_score = self._calculate_form_score(match_context.home_team)
        away_form_score = self._calculate_form_score(match_context.away_team)
        
        # Calculate home advantage
        home_advantage = self._calculate_home_advantage(match_context)
        
        # Analyze head-to-head
        h2h_factor = self._analyze_head_to_head(match_context)
        
        # Goal expectancy analysis
        home_goals_expected = self._estimate_goals(match_context.home_team, is_home=True)
        away_goals_expected = self._estimate_goals(match_context.away_team, is_home=False)
        
        # Combine factors for prediction
        home_strength = (home_form_score * 0.35 + 
                        home_advantage * 0.25 + 
                        h2h_factor * 0.20 + 
                        home_goals_expected * 0.20)
        
        away_strength = (away_form_score * 0.40 + 
                        h2h_factor * 0.20 + 
                        away_goals_expected * 0.40)
        
        # Determine outcome
        strength_diff = home_strength - away_strength
        
        if strength_diff > 0.15:
            predicted_outcome = 'home_win'
            confidence_factors = [home_form_score, home_advantage, h2h_factor]
        elif strength_diff < -0.15:
            predicted_outcome = 'away_win'
            confidence_factors = [away_form_score, abs(h2h_factor), away_goals_expected]
        else:
            predicted_outcome = 'draw'
            confidence_factors = [abs(strength_diff) * 2, 0.6, 0.5]
        
        confidence = self.calculate_confidence(confidence_factors)
        
        # Predict score
        predicted_score = {
            'home': max(0, round(home_goals_expected)),
            'away': max(0, round(away_goals_expected))
        }
        
        processing_time = (time.time() - start_time) * 1000
        
        return AgentPrediction(
            agent_name=self.name,
            agent_type=self.agent_type,
            predicted_outcome=predicted_outcome,
            confidence=round(confidence, 3),
            predicted_score=predicted_score,
            reasoning=self.get_reasoning(match_context),
            key_factors=[
                {'factor': 'Home Form', 'value': round(home_form_score, 3), 'weight': 0.35},
                {'factor': 'Away Form', 'value': round(away_form_score, 3), 'weight': 0.35},
                {'factor': 'Home Advantage', 'value': round(home_advantage, 3), 'weight': 0.25},
                {'factor': 'H2H Record', 'value': round(h2h_factor, 3), 'weight': 0.20},
                {'factor': 'Expected Goals (Home)', 'value': round(home_goals_expected, 2)},
                {'factor': 'Expected Goals (Away)', 'value': round(away_goals_expected, 2)},
            ],
            uncertainty_notes=self._identify_uncertainties(match_context),
            processing_time_ms=round(processing_time, 2)
        )
    
    def get_reasoning(self, match_context: MatchContext) -> List[str]:
        reasoning = []
        
        # Form analysis
        home_wins = sum(1 for r in match_context.home_team.recent_form if r == 'W')
        away_wins = sum(1 for r in match_context.away_team.recent_form if r == 'W')
        
        reasoning.append(
            f"Home team recent form: {home_wins} wins in last {len(match_context.home_team.recent_form)} matches"
        )
        reasoning.append(
            f"Away team recent form: {away_wins} wins in last {len(match_context.away_team.recent_form)} matches"
        )
        
        # Head-to-head
        h2h = match_context.head_to_head
        if h2h.total_matches > 0:
            reasoning.append(
                f"Historical H2H: {h2h.team_a_wins} wins for home, "
                f"{h2h.team_b_wins} wins for away, {h2h.draws} draws "
                f"(avg {h2h.avg_goals_per_match:.1f} goals/match)"
            )
        
        # Home/Away records
        home_record = match_context.home_team.home_record
        reasoning.append(
            f"Home team home record: {home_record['wins']}W-{home_record['draws']}D-{home_record['losses']}L"
        )
        
        away_record = match_context.away_team.away_record
        reasoning.append(
            f"Away team away record: {away_record['wins']}W-{away_record['draws']}D-{away_record['losses']}L"
        )
        
        # Goal statistics
        reasoning.append(
            f"Goal averages: Home {match_context.home_team.goals_scored_avg:.2f} scored, "
            f"{match_context.home_team.goals_conceded_avg:.2f} conceded | "
            f"Away {match_context.away_team.goals_scored_avg:.2f} scored, "
            f"{match_context.away_team.goals_conceded_avg:.2f} conceded"
        )
        
        return reasoning
    
    def _calculate_form_score(self, team) -> float:
        """Calculate form score from recent results (0-1)"""
        if not team.recent_form:
            return 0.5
        
        points = 0
        for i, result in enumerate(team.recent_form):
            weight = 1.0 / (i + 1)  # More recent matches weighted higher
            if result == 'W':
                points += 3 * weight
            elif result == 'D':
                points += 1 * weight
        
        max_points = sum(3.0 / (i + 1) for i in range(len(team.recent_form)))
        return points / max_points if max_points > 0 else 0.5
    
    def _calculate_home_advantage(self, match_context: MatchContext) -> float:
        """Calculate home advantage factor (0-1)"""
        home_record = match_context.home_team.home_record
        total_home = home_record['wins'] + home_record['draws'] + home_record['losses']
        
        if total_home == 0:
            return 0.5
        
        win_rate = home_record['wins'] / total_home
        # Typical home advantage is around 0.6-0.7
        return min(max(win_rate, 0.4), 0.8)
    
    def _analyze_head_to_head(self, match_context: MatchContext) -> float:
        """Analyze H2H record (-1 to 1, positive favors home)"""
        h2h = match_context.head_to_head
        
        if h2h.total_matches == 0:
            return 0.0
        
        # Recent meetings weighted more
        recent_weight = 0
        total_weight = 0
        
        for i, meeting in enumerate(h2h.last_5_meetings):
            weight = 1.0 / (i + 1)
            total_weight += weight
            
            if meeting.get('winner') == 'home':
                recent_weight += weight
            elif meeting.get('winner') == 'away':
                recent_weight -= weight
        
        if total_weight > 0:
            return recent_weight / total_weight
        
        # Fallback to overall record
        return (h2h.team_a_wins - h2h.team_b_wins) / h2h.total_matches
    
    def _estimate_goals(self, team, is_home: bool) -> float:
        """Estimate expected goals"""
        base_goals = team.goals_scored_avg
        
        # Adjust for home/away
        if is_home:
            adjustment = 1.15  # Home teams typically score 15% more
        else:
            adjustment = 0.90  # Away teams typically score 10% less
        
        # Factor in opponent's defensive strength (simplified)
        expected = base_goals * adjustment
        
        return max(0.5, min(expected, 4.0))
    
    def _identify_uncertainties(self, match_context: MatchContext) -> List[str]:
        """Identify sources of uncertainty"""
        uncertainties = []
        
        if len(match_context.home_team.recent_form) < 5:
            uncertainties.append("Limited recent form data for home team")
        
        if len(match_context.away_team.recent_form) < 5:
            uncertainties.append("Limited recent form data for away team")
        
        if match_context.head_to_head.total_matches < 3:
            uncertainties.append("Small H2H sample size")
        
        if match_context.home_team.injuries:
            uncertainties.append(f"Home team has {len(match_context.home_team.injuries)} injuries")
        
        if match_context.away_team.injuries:
            uncertainties.append(f"Away team has {len(match_context.away_team.injuries)} injuries")
        
        return uncertainties
