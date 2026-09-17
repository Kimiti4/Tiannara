"""
Suggestion Engine - Proactive suggestion generation

Generates context-aware recommendations using collaborative filtering,
history-based predictions, and A/B testing framework.
"""

import logging
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field
from datetime import datetime
from collections import defaultdict
import random

logger = logging.getLogger(__name__)


@dataclass
class Suggestion:
    """A proactive suggestion for the user."""
    suggestion_id: str
    text: str
    category: str
    confidence: float
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)
    
    def __post_init__(self):
        if not 0 <= self.confidence <= 1:
            raise ValueError(f"Confidence must be between 0 and 1, got {self.confidence}")


@dataclass
class SuggestionContext:
    """Context for generating suggestions."""
    user_id: str
    current_action: str
    recent_actions: List[str] = field(default_factory=list)
    user_preferences: Dict[str, Any] = field(default_factory=dict)
    time_of_day: Optional[str] = None


class SuggestionEngine:
    """Proactive suggestion generation engine.
    
    Features:
    - Context-aware recommendations
    - Collaborative filtering from similar users
    - History-based prediction suggestions
    - Real-time suggestion ranking
    - A/B testing framework
    
    Example:
        >>> engine = SuggestionEngine()
        >>> suggestions = engine.generate_suggestions(context)
    """
    
    def __init__(self):
        self.suggestion_templates: Dict[str, List[str]] = self._load_templates()
        self.user_history: Dict[str, List[str]] = {}
        self.ab_test_variants: Dict[str, Dict[str, Any]] = {}
        
        logger.info("Initialized SuggestionEngine")
    
    def _load_templates(self) -> Dict[str, List[str]]:
        """Load suggestion templates by category."""
        return {
            'help': [
                "You might also want to check out {related_topic}",
                "Based on your activity, consider exploring {feature}",
                "Users who did this also found {action} helpful",
            ],
            'prediction': [
                "Would you like a prediction for {topic}?",
                "Similar users are interested in {trend}",
                "Based on history, you might ask about {subject}",
            ],
            'optimization': [
                "Consider adjusting {parameter} for better results",
                "You could improve accuracy by {action}",
                "Try {alternative} for faster processing",
            ],
        }
    
    def generate_suggestions(self, context: SuggestionContext, 
                           max_suggestions: int = 3) -> List[Suggestion]:
        """Generate proactive suggestions based on context.
        
        Args:
            context: User context information
            max_suggestions: Maximum number of suggestions to return
            
        Returns:
            List of Suggestion objects
        """
        suggestions = []
        
        # Generate history-based suggestions
        history_suggestions = self._generate_history_based(context)
        suggestions.extend(history_suggestions)
        
        # Generate collaborative filtering suggestions
        collab_suggestions = self._generate_collaborative(context)
        suggestions.extend(collab_suggestions)
        
        # Generate template-based suggestions
        template_suggestions = self._generate_from_templates(context)
        suggestions.extend(template_suggestions)
        
        # Rank and select top suggestions
        suggestions.sort(key=lambda s: s.confidence, reverse=True)
        selected = suggestions[:max_suggestions]
        
        logger.info(f"Generated {len(selected)} suggestions for user {context.user_id}")
        return selected
    
    def _generate_history_based(self, context: SuggestionContext) -> List[Suggestion]:
        """Generate suggestions based on user's history."""
        suggestions = []
        
        # Get user's frequent actions
        user_actions = self.user_history.get(context.user_id, [])
        if not user_actions:
            return suggestions
        
        action_counts = Counter(user_actions)
        most_common = action_counts.most_common(3)
        
        for action, count in most_common:
            if count >= 2:  # Only suggest if done multiple times
                confidence = min(count / 10.0, 0.9)
                suggestion = Suggestion(
                    suggestion_id=f"hist_{context.user_id}_{action}",
                    text=f"You often perform '{action}'. Would you like to do it again?",
                    category='history',
                    confidence=confidence,
                    metadata={'action': action, 'frequency': count}
                )
                suggestions.append(suggestion)
        
        return suggestions
    
    def _generate_collaborative(self, context: SuggestionContext) -> List[Suggestion]:
        """Generate suggestions using collaborative filtering."""
        suggestions = []
        
        # Simulate collaborative filtering (in production, use real user similarity)
        similar_actions = ['view_predictions', 'analyze_trends', 'export_data']
        
        for action in similar_actions:
            if action not in context.recent_actions:
                confidence = random.uniform(0.5, 0.8)
                suggestion = Suggestion(
                    suggestion_id=f"collab_{context.user_id}_{action}",
                    text=f"Similar users also {action.replace('_', ' ')}",
                    category='collaborative',
                    confidence=confidence,
                    metadata={'action': action}
                )
                suggestions.append(suggestion)
        
        return suggestions
    
    def _generate_from_templates(self, context: SuggestionContext) -> List[Suggestion]:
        """Generate suggestions from templates."""
        suggestions = []
        
        # Choose template category based on context
        if 'predict' in context.current_action.lower():
            category = 'prediction'
        elif 'help' in context.current_action.lower():
            category = 'help'
        else:
            category = 'optimization'
        
        templates = self.suggestion_templates.get(category, [])
        if templates:
            template = random.choice(templates)
            
            # Fill in template variables
            filled_text = template.format(
                related_topic='related features',
                feature='advanced options',
                action='checking documentation',
                topic='upcoming events',
                trend='market trends',
                subject='performance metrics',
                parameter='your settings',
                alternative='batch processing'
            )
            
            suggestion = Suggestion(
                suggestion_id=f"tmpl_{context.user_id}_{category}",
                text=filled_text,
                category=category,
                confidence=random.uniform(0.4, 0.7),
                metadata={'template_category': category}
            )
            suggestions.append(suggestion)
        
        return suggestions
    
    def track_user_action(self, user_id: str, action: str):
        """Track user action for future suggestions.
        
        Args:
            user_id: User identifier
            action: Action performed
        """
        if user_id not in self.user_history:
            self.user_history[user_id] = []
        
        self.user_history[user_id].append(action)
        
        # Keep only recent history
        if len(self.user_history[user_id]) > 100:
            self.user_history[user_id] = self.user_history[user_id][-100:]
        
        logger.debug(f"Tracked action for user {user_id}: {action}")
    
    def start_ab_test(self, test_name: str, variants: List[Dict[str, Any]]):
        """Start an A/B test for suggestion strategies.
        
        Args:
            test_name: Name of the test
            variants: List of variant configurations
        """
        self.ab_test_variants[test_name] = {
            'variants': variants,
            'assignments': {},
            'results': defaultdict(lambda: {'impressions': 0, 'clicks': 0})
        }
        
        logger.info(f"Started A/B test: {test_name} with {len(variants)} variants")
    
    def get_variant_for_user(self, test_name: str, user_id: str) -> Dict[str, Any]:
        """Get assigned variant for a user in an A/B test."""
        if test_name not in self.ab_test_variants:
            raise ValueError(f"A/B test '{test_name}' not found")
        
        test = self.ab_test_variants[test_name]
        
        # Assign variant if not already assigned
        if user_id not in test['assignments']:
            variant_idx = hash(user_id) % len(test['variants'])
            test['assignments'][user_id] = variant_idx
        
        variant_idx = test['assignments'][user_id]
        return test['variants'][variant_idx]


# Import Counter at module level
from collections import Counter


# Convenience function
def create_engine() -> SuggestionEngine:
    """Create a new suggestion engine."""
    return SuggestionEngine()
