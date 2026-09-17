"""
Personalization Engine - User preference learning and adaptive experiences

Learns user preferences, adapts response styles, and provides
customized dashboards with intelligent defaults.
"""

import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from datetime import datetime
from collections import defaultdict

logger = logging.getLogger(__name__)


@dataclass
class UserProfile:
    """User profile with preferences and settings."""
    user_id: str
    preferences: Dict[str, Any] = field(default_factory=dict)
    interaction_count: int = 0
    created_at: datetime = field(default_factory=datetime.now)
    last_updated: datetime = field(default_factory=datetime.now)
    
    def update_preference(self, key: str, value: Any):
        """Update a preference."""
        self.preferences[key] = value
        self.last_updated = datetime.now()


@dataclass
class PersonalizationConfig:
    """Configuration for personalization engine."""
    learning_rate: float = 0.1
    min_interactions: int = 5
    preference_decay: float = 0.95


class PersonalizationEngine:
    """Personalization engine for adaptive user experiences.
    
    Features:
    - User preference learning from interactions
    - Adaptive response styles based on user profile
    - Customized dashboard configurations
    - Intelligent defaults per user segment
    - Privacy-preserving personalization
    
    Example:
        >>> engine = PersonalizationEngine()
        >>> engine.learn_from_interaction("user123", "prefers_dark_mode")
        >>> profile = engine.get_user_profile("user123")
    """
    
    def __init__(self, config: Optional[PersonalizationConfig] = None):
        self.config = config or PersonalizationConfig()
        self.user_profiles: Dict[str, UserProfile] = {}
        self.interaction_history: Dict[str, List[Dict[str, Any]]] = defaultdict(list)
        self.segment_rules: Dict[str, Dict[str, Any]] = self._initialize_segments()
        
        logger.info("Initialized PersonalizationEngine")
    
    def _initialize_segments(self) -> Dict[str, Dict[str, Any]]:
        """Initialize user segment rules."""
        return {
            'power_user': {
                'min_interactions': 50,
                'features': ['advanced_analytics', 'custom_dashboards', 'api_access']
            },
            'casual_user': {
                'min_interactions': 10,
                'features': ['basic_analytics', 'simple_dashboard']
            },
            'new_user': {
                'min_interactions': 0,
                'features': ['onboarding_tour', 'guided_experience']
            }
        }
    
    def get_or_create_profile(self, user_id: str) -> UserProfile:
        """Get existing profile or create new one.
        
        Args:
            user_id: User identifier
            
        Returns:
            UserProfile object
        """
        if user_id not in self.user_profiles:
            self.user_profiles[user_id] = UserProfile(user_id=user_id)
            logger.info(f"Created new profile for user {user_id}")
        
        return self.user_profiles[user_id]
    
    def learn_from_interaction(self, user_id: str, signal: str, 
                              value: float = 1.0):
        """Learn from user interaction.
        
        Args:
            user_id: User identifier
            signal: Interaction signal (e.g., 'clicked_feature_x')
            value: Signal strength (0.0 to 1.0)
        """
        profile = self.get_or_create_profile(user_id)
        
        # Record interaction
        interaction = {
            'signal': signal,
            'value': value,
            'timestamp': datetime.now()
        }
        self.interaction_history[user_id].append(interaction)
        
        # Update preferences using exponential moving average
        current_pref = profile.preferences.get(signal, 0.0)
        new_pref = (self.config.learning_rate * value + 
                   (1 - self.config.learning_rate) * current_pref)
        
        profile.preferences[signal] = new_pref
        profile.interaction_count += 1
        profile.last_updated = datetime.now()
        
        logger.debug(f"Learned from interaction: {user_id} - {signal} = {new_pref:.2f}")
    
    def get_personalized_defaults(self, user_id: str) -> Dict[str, Any]:
        """Get personalized default settings for a user.
        
        Args:
            user_id: User identifier
            
        Returns:
            Dictionary of personalized defaults
        """
        profile = self.get_or_create_profile(user_id)
        segment = self._determine_user_segment(user_id)
        
        defaults = {
            'theme': profile.preferences.get('theme', 'light'),
            'dashboard_layout': profile.preferences.get('layout', 'default'),
            'notifications_enabled': profile.preferences.get('notifications', True),
            'items_per_page': profile.preferences.get('page_size', 20),
            'sort_order': profile.preferences.get('sort', 'recent'),
        }
        
        # Apply segment-specific defaults
        if segment == 'power_user':
            defaults.update({
                'show_advanced_features': True,
                'enable_api_access': True,
                'dashboard_complexity': 'advanced'
            })
        elif segment == 'new_user':
            defaults.update({
                'show_tutorials': True,
                'simplified_view': True,
                'enable_guided_tour': True
            })
        
        logger.debug(f"Generated personalized defaults for {user_id} (segment: {segment})")
        return defaults
    
    def adapt_response_style(self, user_id: str, content_type: str) -> Dict[str, Any]:
        """Adapt response style based on user preferences.
        
        Args:
            user_id: User identifier
            content_type: Type of content (e.g., 'explanation', 'summary')
            
        Returns:
            Style configuration dictionary
        """
        profile = self.get_or_create_profile(user_id)
        
        style = {
            'detail_level': profile.preferences.get('detail_level', 'medium'),
            'format': profile.preferences.get('format', 'text'),
            'tone': profile.preferences.get('tone', 'professional'),
        }
        
        # Adjust based on interaction history
        if profile.interaction_count > 50:
            style['detail_level'] = 'detailed'
            style['include_examples'] = True
        
        logger.debug(f"Adapted response style for {user_id}: {style}")
        return style
    
    def _determine_user_segment(self, user_id: str) -> str:
        """Determine which segment a user belongs to.
        
        Args:
            user_id: User identifier
            
        Returns:
            Segment name
        """
        profile = self.user_profiles.get(user_id)
        if not profile:
            return 'new_user'
        
        interaction_count = profile.interaction_count
        
        if interaction_count >= self.segment_rules['power_user']['min_interactions']:
            return 'power_user'
        elif interaction_count >= self.segment_rules['casual_user']['min_interactions']:
            return 'casual_user'
        else:
            return 'new_user'
    
    def get_user_insights(self, user_id: str) -> Dict[str, Any]:
        """Get comprehensive insights about a user.
        
        Args:
            user_id: User identifier
            
        Returns:
            Dictionary with user insights
        """
        profile = self.get_or_create_profile(user_id)
        segment = self._determine_user_segment(user_id)
        
        # Calculate top preferences
        sorted_prefs = sorted(
            profile.preferences.items(),
            key=lambda x: x[1],
            reverse=True
        )
        top_preferences = sorted_prefs[:5]
        
        return {
            'user_id': user_id,
            'segment': segment,
            'interaction_count': profile.interaction_count,
            'top_preferences': dict(top_preferences),
            'created_at': profile.created_at.isoformat(),
            'last_active': profile.last_updated.isoformat(),
            'personalization_score': min(profile.interaction_count / 100.0, 1.0)
        }
    
    def apply_privacy_filter(self, user_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Apply privacy filter to user data before sharing.
        
        Args:
            user_id: User identifier
            data: User data to filter
            
        Returns:
            Filtered data with PII removed
        """
        # Remove sensitive fields
        sensitive_fields = ['email', 'phone', 'address', 'ip_address']
        filtered = {k: v for k, v in data.items() if k not in sensitive_fields}
        
        logger.debug(f"Applied privacy filter for user {user_id}")
        return filtered


# Convenience function
def create_engine(config: Optional[PersonalizationConfig] = None) -> PersonalizationEngine:
    """Create a new personalization engine."""
    return PersonalizationEngine(config)
