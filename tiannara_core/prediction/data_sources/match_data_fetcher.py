"""
Match Data Fetcher - Real-time and mock data integration
"""

from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
import random

from ..agents.base_agent import TeamStats, HeadToHead, MatchContext


class MatchDataFetcher:
    """
    Fetches real-time match data from various sources.
    Currently uses mock data for demonstration.
    Can be extended to integrate with real APIs (SofaScore, Football-Data.org, etc.)
    """
    
    def __init__(self, use_mock_data: bool = True):
        self.use_mock_data = use_mock_data
        self.cache: Dict[str, MatchContext] = {}
        self.cache_ttl = 300  # 5 minutes cache
    
    def fetch_match_context(self, match_id: str) -> Optional[MatchContext]:
        """Fetch complete match context"""
        
        # Check cache first
        if match_id in self.cache:
            cached = self.cache[match_id]
            age = (datetime.now() - cached.timestamp).total_seconds()
            if age < self.cache_ttl:
                return cached
        
        # Fetch fresh data
        if self.use_mock_data:
            context = self._generate_mock_match(match_id)
        else:
            context = self._fetch_real_match_data(match_id)
        
        # Cache the result
        self.cache[match_id] = context
        
        return context
    
    def get_upcoming_matches(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get list of upcoming matches"""
        if self.use_mock_data:
            return self._get_mock_upcoming_matches(limit)
        else:
            return self._fetch_real_upcoming_matches(limit)
    
    def _generate_mock_match(self, match_id: str) -> MatchContext:
        """Generate realistic mock match data"""
        
        # Define some realistic teams
        teams = {
            'man_city': {
                'name': 'Manchester City',
                'form': ['W', 'W', 'D', 'W', 'W'],
                'goals_scored': 2.4,
                'goals_conceded': 0.8,
                'possession': 65.2,
                'shots_on_target': 6.8,
                'pass_accuracy': 89.5,
                'home_record': {'wins': 12, 'draws': 2, 'losses': 1},
                'away_record': {'wins': 9, 'draws': 3, 'losses': 3},
            },
            'liverpool': {
                'name': 'Liverpool',
                'form': ['W', 'W', 'W', 'L', 'W'],
                'goals_scored': 2.6,
                'goals_conceded': 1.0,
                'possession': 61.8,
                'shots_on_target': 7.2,
                'pass_accuracy': 85.3,
                'home_record': {'wins': 11, 'draws': 2, 'losses': 2},
                'away_record': {'wins': 8, 'draws': 4, 'losses': 3},
            },
            'arsenal': {
                'name': 'Arsenal',
                'form': ['W', 'D', 'W', 'W', 'D'],
                'goals_scored': 2.2,
                'goals_conceded': 0.9,
                'possession': 58.5,
                'shots_on_target': 6.1,
                'pass_accuracy': 87.2,
                'home_record': {'wins': 10, 'draws': 3, 'losses': 2},
                'away_record': {'wins': 7, 'draws': 5, 'losses': 3},
            },
            'chelsea': {
                'name': 'Chelsea',
                'form': ['D', 'W', 'L', 'W', 'D'],
                'goals_scored': 1.8,
                'goals_conceded': 1.2,
                'possession': 56.3,
                'shots_on_target': 5.4,
                'pass_accuracy': 84.7,
                'home_record': {'wins': 8, 'draws': 4, 'losses': 3},
                'away_record': {'wins': 6, 'draws': 4, 'losses': 5},
            },
            'man_utd': {
                'name': 'Manchester United',
                'form': ['L', 'W', 'D', 'L', 'W'],
                'goals_scored': 1.6,
                'goals_conceded': 1.4,
                'possession': 54.2,
                'shots_on_target': 5.0,
                'pass_accuracy': 82.1,
                'home_record': {'wins': 7, 'draws': 5, 'losses': 3},
                'away_record': {'wins': 5, 'draws': 4, 'losses': 6},
            },
            'tottenham': {
                'name': 'Tottenham',
                'form': ['W', 'L', 'W', 'W', 'L'],
                'goals_scored': 2.0,
                'goals_conceded': 1.3,
                'possession': 55.7,
                'shots_on_target': 5.8,
                'pass_accuracy': 83.9,
                'home_record': {'wins': 9, 'draws': 3, 'losses': 3},
                'away_record': {'wins': 6, 'draws': 3, 'losses': 6},
            },
        }
        
        # Select teams based on match_id or randomly
        team_keys = list(teams.keys())
        if 'city' in match_id.lower():
            home_key, away_key = 'man_city', 'liverpool'
        elif 'arsenal' in match_id.lower():
            home_key, away_key = 'arsenal', 'chelsea'
        elif 'united' in match_id.lower():
            home_key, away_key = 'man_utd', 'tottenham'
        else:
            home_key, away_key = random.sample(team_keys, 2)
        
        home_data = teams[home_key]
        away_data = teams[away_key]
        
        # Create team stats
        home_team = TeamStats(
            team_id=home_key,
            team_name=home_data['name'],
            recent_form=home_data['form'],
            goals_scored_avg=home_data['goals_scored'],
            goals_conceded_avg=home_data['goals_conceded'],
            possession_avg=home_data['possession'],
            shots_on_target_avg=home_data['shots_on_target'],
            pass_accuracy=home_data['pass_accuracy'],
            home_record=home_data['home_record'],
            away_record=home_data['away_record'],
            injuries=self._generate_mock_injuries(home_key),
            suspensions=self._generate_mock_suspensions(home_key),
        )
        
        away_team = TeamStats(
            team_id=away_key,
            team_name=away_data['name'],
            recent_form=away_data['form'],
            goals_scored_avg=away_data['goals_scored'],
            goals_conceded_avg=away_data['goals_conceded'],
            possession_avg=away_data['possession'],
            shots_on_target_avg=away_data['shots_on_target'],
            pass_accuracy=away_data['pass_accuracy'],
            home_record=away_data['home_record'],
            away_record=away_data['away_record'],
            injuries=self._generate_mock_injuries(away_key),
            suspensions=self._generate_mock_suspensions(away_key),
        )
        
        # Generate H2H record
        h2h = self._generate_mock_h2h(home_key, away_key)
        
        # Determine match importance
        importance = random.choice(['normal', 'normal', 'normal', 'high', 'critical'])
        
        # Weather conditions
        weather_options = [
            {'condition': 'clear', 'temperature': 18, 'humidity': 45},
            {'condition': 'light_rain', 'temperature': 15, 'humidity': 70},
            {'condition': 'cloudy', 'temperature': 16, 'humidity': 55},
            {'condition': 'heavy_rain', 'temperature': 12, 'humidity': 85},
        ]
        weather = random.choice(weather_options)
        
        return MatchContext(
            match_id=match_id,
            home_team=home_team,
            away_team=away_team,
            head_to_head=h2h,
            venue='home',
            weather=weather,
            competition='Premier League',
            match_importance=importance,
            referee=random.choice(['Michael Oliver', 'Anthony Taylor', 'Martin Atkinson']),
        )
    
    def _generate_mock_injuries(self, team_key: str) -> List[Dict[str, str]]:
        """Generate mock injury data"""
        injuries = []
        
        # Some teams have more injuries
        injury_probability = {
            'man_city': 0.1,
            'liverpool': 0.15,
            'arsenal': 0.2,
            'chelsea': 0.25,
            'man_utd': 0.3,
            'tottenham': 0.2,
        }
        
        prob = injury_probability.get(team_key, 0.2)
        
        if random.random() < prob:
            num_injuries = random.randint(1, 3)
            positions = ['striker', 'midfielder', 'defender', 'goalkeeper']
            importance_levels = ['regular', 'key', 'star']
            
            for _ in range(num_injuries):
                injuries.append({
                    'player': f'Player {random.randint(1, 25)}',
                    'position': random.choice(positions),
                    'importance': random.choice(importance_levels),
                    'expected_return': f'{random.randint(1, 4)} weeks',
                })
        
        return injuries
    
    def _generate_mock_suspensions(self, team_key: str) -> List[Dict[str, str]]:
        """Generate mock suspension data"""
        suspensions = []
        
        if random.random() < 0.15:  # 15% chance of suspension
            suspensions.append({
                'player': f'Player {random.randint(1, 25)}',
                'reason': 'yellow_cards',
                'matches_remaining': random.randint(1, 3),
            })
        
        return suspensions
    
    def _generate_mock_h2h(self, team_a: str, team_b: str) -> HeadToHead:
        """Generate mock head-to-head record"""
        total = random.randint(3, 15)
        wins_a = random.randint(1, total - 1)
        wins_b = random.randint(1, total - wins_a)
        draws = total - wins_a - wins_b
        
        # Generate last 5 meetings
        last_5 = []
        for i in range(min(5, total)):
            winner = random.choice(['home', 'away', 'draw'])
            last_5.append({
                'date': (datetime.now() - timedelta(days=random.randint(30, 365))).isoformat(),
                'winner': winner,
                'score': f"{random.randint(0, 4)}-{random.randint(0, 4)}",
            })
        
        return HeadToHead(
            total_matches=total,
            team_a_wins=wins_a,
            team_b_wins=wins_b,
            draws=draws,
            last_5_meetings=last_5,
            avg_goals_per_match=round(random.uniform(2.0, 3.5), 1),
        )
    
    def _get_mock_upcoming_matches(self, limit: int) -> List[Dict[str, Any]]:
        """Get mock upcoming matches"""
        matches = [
            {
                'match_id': 'match_city_liverpool',
                'home_team': 'Manchester City',
                'away_team': 'Liverpool',
                'competition': 'Premier League',
                'kickoff': (datetime.now() + timedelta(days=2)).isoformat(),
                'venue': 'Etihad Stadium',
            },
            {
                'match_id': 'match_arsenal_chelsea',
                'home_team': 'Arsenal',
                'away_team': 'Chelsea',
                'competition': 'Premier League',
                'kickoff': (datetime.now() + timedelta(days=2, hours=3)).isoformat(),
                'venue': 'Emirates Stadium',
            },
            {
                'match_id': 'match_united_tottenham',
                'home_team': 'Manchester United',
                'away_team': 'Tottenham',
                'competition': 'Premier League',
                'kickoff': (datetime.now() + timedelta(days=3)).isoformat(),
                'venue': 'Old Trafford',
            },
        ]
        
        return matches[:limit]
    
    def _fetch_real_match_data(self, match_id: str) -> MatchContext:
        """
        Placeholder for real API integration.
        Can integrate with:
        - SofaScore API
        - Football-Data.org
        - API-Football
        - SportRadar
        """
        raise NotImplementedError("Real API integration not yet implemented")
    
    def _fetch_real_upcoming_matches(self, limit: int) -> List[Dict[str, Any]]:
        """Placeholder for real upcoming matches API"""
        raise NotImplementedError("Real API integration not yet implemented")
