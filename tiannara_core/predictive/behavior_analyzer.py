"""
Behavior Analyzer - User behavior pattern analysis and tracking

Tracks user interactions, identifies patterns, and predicts next actions
using Markov chains and sequence analysis.
"""

import logging
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field
from collections import defaultdict, Counter
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)


@dataclass
class UserEvent:
    """Represents a user interaction event."""
    user_id: str
    event_type: str
    timestamp: datetime
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class BehaviorPattern:
    """Identified behavior pattern."""
    pattern_id: str
    description: str
    frequency: int
    confidence: float
    last_seen: datetime


@dataclass
class Prediction:
    """Prediction of next user action."""
    predicted_action: str
    confidence: float
    reasoning: str


class BehaviorAnalyzer:
    """Analyzes user behavior patterns and makes predictions.
    
    Features:
    - Track interaction patterns
    - Identify common query sequences  
    - Predict next likely request
    - Learn user preferences
    
    Example:
        >>> analyzer = BehaviorAnalyzer()
        >>> analyzer.track_event(UserEvent(...))
        >>> prediction = analyzer.predict_next_action("user123")
    """
    
    def __init__(self, window_size: int = 100):
        self.window_size = window_size
        self.user_events: Dict[str, List[UserEvent]] = defaultdict(list)
        self.patterns: Dict[str, List[BehaviorPattern]] = defaultdict(list)
        self.transition_matrix: Dict[str, Counter] = defaultdict(Counter)
        
        logger.info("Initialized BehaviorAnalyzer")
    
    def track_event(self, event: UserEvent):
        """Track a user event.
        
        Args:
            event: User event to track
        """
        user_events = self.user_events[event.user_id]
        user_events.append(event)
        
        # Keep only recent events
        if len(user_events) > self.window_size:
            self.user_events[event.user_id] = user_events[-self.window_size:]
        
        # Update transition matrix
        if len(user_events) >= 2:
            prev_event = user_events[-2]
            self.transition_matrix[prev_event.event_type][event.event_type] += 1
        
        logger.debug(f"Tracked event for user {event.user_id}: {event.event_type}")
    
    def analyze_patterns(self, user_id: str) -> List[BehaviorPattern]:
        """Analyze behavior patterns for a user.
        
        Args:
            user_id: User ID to analyze
            
        Returns:
            List of identified patterns
        """
        events = self.user_events.get(user_id, [])
        if not events:
            return []
        
        # Count event frequencies
        event_counts = Counter(e.event_type for e in events)
        
        # Identify patterns
        patterns = []
        for event_type, count in event_counts.most_common(10):
            if count >= 3:  # Minimum frequency threshold
                pattern = BehaviorPattern(
                    pattern_id=f"{user_id}_{event_type}",
                    description=f"Frequently performs {event_type}",
                    frequency=count,
                    confidence=min(count / 10.0, 1.0),
                    last_seen=events[-1].timestamp
                )
                patterns.append(pattern)
        
        self.patterns[user_id] = patterns
        logger.info(f"Found {len(patterns)} patterns for user {user_id}")
        
        return patterns
    
    def predict_next_action(self, user_id: str) -> Optional[Prediction]:
        """Predict the next likely action for a user.
        
        Args:
            user_id: User ID to predict for
            
        Returns:
            Prediction of next action, or None if insufficient data
        """
        events = self.user_events.get(user_id, [])
        if len(events) < 2:
            return None
        
        # Get most recent event
        last_event = events[-1].event_type
        
        # Use transition matrix to predict next
        transitions = self.transition_matrix.get(last_event, {})
        if not transitions:
            return None
        
        # Get most likely next action
        next_action = transitions.most_common(1)[0][0]
        total_transitions = sum(transitions.values())
        confidence = transitions[next_action] / total_transitions
        
        prediction = Prediction(
            predicted_action=next_action,
            confidence=confidence,
            reasoning=f"Based on {total_transitions} transitions from '{last_event}'"
        )
        
        logger.debug(f"Predicted next action for {user_id}: {next_action} (confidence: {confidence:.2f})")
        return prediction
    
    def get_user_profile(self, user_id: str) -> Dict[str, Any]:
        """Get comprehensive user behavior profile.
        
        Args:
            user_id: User ID
            
        Returns:
            Dictionary with user behavior insights
        """
        events = self.user_events.get(user_id, [])
        patterns = self.analyze_patterns(user_id)
        
        return {
            'user_id': user_id,
            'total_events': len(events),
            'event_types': list(set(e.event_type for e in events)),
            'patterns': [p.__dict__ for p in patterns],
            'most_common_action': Counter(e.event_type for e in events).most_common(1)[0][0] if events else None,
            'first_seen': events[0].timestamp if events else None,
            'last_seen': events[-1].timestamp if events else None,
        }


# Convenience functions
def create_analyzer(window_size: int = 100) -> BehaviorAnalyzer:
    """Create a new behavior analyzer."""
    return BehaviorAnalyzer(window_size)
