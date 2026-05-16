"""
Sports Data Integration Layer - Phase 2

Integrates multiple sports data sources for real-time match information:
- API-Football (primary)
- SportRadar (fallback)
- Custom webhook receivers
- WebSocket live updates

Provides unified interface regardless of data source.
"""

import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import asyncio

logger = logging.getLogger(__name__)

try:
    import aiohttp
    AIOHTTP_AVAILABLE = True
except ImportError:
    AIOHTTP_AVAILABLE = False
    logger.warning("⚠️  aiohttp not available - sports API in demo mode")

from tiannara_core.cache.redis_cache import cache

logger = logging.getLogger(__name__)


class SportsAPIClient:
    """
    Unified sports data client supporting multiple providers.
    
    Automatically handles:
    - Rate limiting
    - Failover between providers
    - Response normalization
    - Caching strategies
    """
    
    def __init__(self, api_football_key: str = None, sportradar_key: str = None):
        self.api_football_key = api_football_key
        self.sportradar_key = sportradar_key
        
        # Provider configuration
        self.providers = {
            'api_football': {
                'base_url': 'https://v3.football.api-sports.io',
                'headers': {'x-rapidapi-key': api_football_key} if api_football_key else {},
                'rate_limit': 100,  # requests per minute
                'priority': 1
            },
            'sportradar': {
                'base_url': 'https://api.sportradar.com/soccer/trial/v4/en',
                'headers': {'apikey': sportradar_key} if sportradar_key else {},
                'rate_limit': 50,
                'priority': 2
            }
        }
        
        # Rate limiting state
        self.request_counts = {provider: 0 for provider in self.providers}
        self.last_reset = datetime.now()
        
        logger.info("✅ Sports API client initialized")
    
    async def get_upcoming_matches(self, league_id: int = None, days: int = 7) -> List[Dict[str, Any]]:
        """
        Fetch upcoming matches from primary provider.
        
        Args:
            league_id: Filter by specific league (None = all leagues)
            days: Number of days ahead to fetch
            
        Returns:
            List of normalized match objects
        """
        try:
            # Try primary provider first
            matches = await self._fetch_from_provider('api_football', league_id, days)
            
            if not matches:
                logger.warning("⚠️ Primary provider returned no results, trying fallback...")
                matches = await self._fetch_from_provider('sportradar', league_id, days)
            
            # Cache results
            if matches:
                cache_key = f"upcoming_matches:{league_id or 'all'}:{days}"
                await cache.set(cache_key, matches, ttl=3600)  # 1 hour cache
                logger.info(f"📊 Cached {len(matches)} upcoming matches")
            
            return matches
            
        except Exception as e:
            logger.error(f"❌ Failed to fetch upcoming matches: {e}")
            return []
    
    async def get_live_match_data(self, match_id: str) -> Optional[Dict[str, Any]]:
        """
        Fetch real-time match statistics.
        
        Args:
            match_id: Unique match identifier
            
        Returns:
            Normalized live match data with stats
        """
        try:
            # Check cache first (30s TTL for live data)
            cached = await cache.get(f"live_match:{match_id}")
            if cached:
                return cached
            
            # Fetch from provider
            data = await self._fetch_live_stats(match_id)
            
            if data:
                # Normalize response
                normalized = self._normalize_live_data(data)
                
                # Cache with short TTL
                await cache.set(f"live_match:{match_id}", normalized, ttl=30)
                
                return normalized
            
            return None
            
        except Exception as e:
            logger.error(f"❌ Failed to fetch live match {match_id}: {e}")
            return None
    
    async def get_odds_history(self, match_id: str, bookmaker: str = "bet365") -> List[Dict[str, Any]]:
        """
        Fetch historical odds movements for a match.
        
        Args:
            match_id: Match identifier
            bookmaker: Specific bookmaker (default: bet365)
            
        Returns:
            List of odds snapshots with timestamps
        """
        try:
            # Check cache
            cached = await cache.get(f"odds_history:{match_id}:{bookmaker}")
            if cached:
                return cached
            
            # Fetch odds data
            odds_data = await self._fetch_odds(match_id, bookmaker)
            
            if odds_data:
                # Normalize
                normalized = self._normalize_odds(odds_data)
                
                # Cache for 60 seconds
                await cache.set(f"odds_history:{match_id}:{bookmaker}", normalized, ttl=60)
                
                return normalized
            
            return []
            
        except Exception as e:
            logger.error(f"❌ Failed to fetch odds for match {match_id}: {e}")
            return []
    
    async def _fetch_from_provider(self, provider: str, league_id: int, days: int) -> List[Dict]:
        """Fetch matches from specific provider."""
        if not AIOHTTP_AVAILABLE:
            logger.warning("⚠️  Demo mode: aiohttp not available, returning sample data")
            return self._get_sample_matches()
        
        config = self.providers[provider]
        
        # Check rate limit
        if not self._check_rate_limit(provider):
            logger.warning(f"⚠️ Rate limit exceeded for {provider}")
            return []
        
        try:
            async with aiohttp.ClientSession() as session:
                if provider == 'api_football':
                    url = f"{config['base_url']}/fixtures"
                    params = {
                        'next': days * 10,  # Approximate matches
                        'timezone': 'UTC'
                    }
                    if league_id:
                        params['league'] = league_id
                    
                    async with session.get(url, headers=config['headers'], params=params) as resp:
                        if resp.status == 200:
                            data = await resp.json()
                            self.request_counts[provider] += 1
                            return data.get('response', [])
                
                elif provider == 'sportradar':
                    # SportRadar implementation
                    pass
                
        except Exception as e:
            logger.error(f"❌ Error fetching from {provider}: {e}")
        
        return []
    
    async def _fetch_live_stats(self, match_id: str) -> Optional[Dict]:
        """Fetch live match statistics."""
        config = self.providers['api_football']
        
        try:
            async with aiohttp.ClientSession() as session:
                url = f"{config['base_url']}/fixtures/statistics"
                params = {'fixture': match_id}
                
                async with session.get(url, headers=config['headers'], params=params) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        return data.get('response')
        
        except Exception as e:
            logger.error(f"❌ Error fetching live stats: {e}")
        
        return None
    
    async def _fetch_odds(self, match_id: str, bookmaker: str) -> Optional[Dict]:
        """Fetch odds data for a match."""
        config = self.providers['api_football']
        
        try:
            async with aiohttp.ClientSession() as session:
                url = f"{config['base_url']}/odds"
                params = {'fixture': match_id, 'bookmaker': bookmaker}
                
                async with session.get(url, headers=config['headers'], params=params) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        return data.get('response')
        
        except Exception as e:
            logger.error(f"❌ Error fetching odds: {e}")
        
        return None
    
    def _normalize_live_data(self, raw_data: Dict) -> Dict[str, Any]:
        """Normalize live match data to standard format."""
        if not raw_data or len(raw_data) < 2:
            return {}
        
        home_stats = raw_data[0].get('statistics', [])
        away_stats = raw_data[1].get('statistics', [])
        
        def extract_stat(stats_list: List, stat_type: str) -> int:
            for stat in stats_list:
                if stat.get('type') == stat_type:
                    value = stat.get('value')
                    return int(value) if value and value != 'N/A' else 0
            return 0
        
        return {
            'shots_home': extract_stat(home_stats, 'Total Shots'),
            'shots_away': extract_stat(away_stats, 'Total Shots'),
            'shots_on_target_home': extract_stat(home_stats, 'Shots on Goal'),
            'shots_on_target_away': extract_stat(away_stats, 'Shots on Goal'),
            'dangerous_attacks_home': extract_stat(home_stats, 'Dangerous Attacks'),
            'dangerous_attacks_away': extract_stat(away_stats, 'Dangerous Attacks'),
            'possession_home': extract_stat(home_stats, 'Ball Possession'),
            'possession_away': 100 - extract_stat(home_stats, 'Ball Possession'),
            'red_cards': extract_stat(home_stats, 'Red Cards') + extract_stat(away_stats, 'Red Cards'),
            'timestamp': datetime.now().isoformat()
        }
    
    def _normalize_odds(self, raw_data: Dict) -> List[Dict[str, Any]]:
        """Normalize odds data to standard format."""
        if not raw_data:
            return []
        
        normalized = []
        for item in raw_data:
            bookmakers = item.get('bookmakers', [])
            for bookmaker in bookmakers:
                markets = bookmaker.get('bets', [])
                for market in markets:
                    if market.get('name') == 'Match Winner':
                        values = market.get('values', [])
                        odds_snapshot = {
                            'timestamp': datetime.now().isoformat(),
                            'odds_home': float(values[0].get('value', 0)) if len(values) > 0 else 0,
                            'odds_draw': float(values[1].get('value', 0)) if len(values) > 1 else 0,
                            'odds_away': float(values[2].get('value', 0)) if len(values) > 2 else 0
                        }
                        normalized.append(odds_snapshot)
        
        return normalized
    
    def _check_rate_limit(self, provider: str) -> bool:
        """Check if rate limit allows request."""
        now = datetime.now()
        
        # Reset counters every minute
        if (now - self.last_reset).total_seconds() > 60:
            self.request_counts = {p: 0 for p in self.providers}
            self.last_reset = now
        
        config = self.providers[provider]
        return self.request_counts[provider] < config['rate_limit']
    
    def _get_sample_matches(self) -> List[Dict]:
        """Return sample match data for demo/testing mode."""
        now = datetime.now()
        return [
            {
                'fixture': {
                    'id': 12345,
                    'date': (now + timedelta(days=1)).isoformat(),
                    'status': {'long': 'Not Started'}
                },
                'teams': {
                    'home': {'name': 'Arsenal', 'logo': 'arsenal.png'},
                    'away': {'name': 'Chelsea', 'logo': 'chelsea.png'}
                },
                'league': {'name': 'Premier League', 'country': 'England'}
            },
            {
                'fixture': {
                    'id': 12346,
                    'date': (now + timedelta(days=2)).isoformat(),
                    'status': {'long': 'Not Started'}
                },
                'teams': {
                    'home': {'name': 'Manchester United', 'logo': 'manutd.png'},
                    'away': {'name': 'Liverpool', 'logo': 'liverpool.png'}
                },
                'league': {'name': 'Premier League', 'country': 'England'}
            }
        ]


# Global instance
sports_api = SportsAPIClient()
