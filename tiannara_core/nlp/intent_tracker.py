"""
Intent Tracker Module

Tracks and classifies user intents across conversation turns for persistent
conversational cognition in the NLP domain.
"""

from dataclasses import dataclass, field
from typing import List, Dict, Optional, Tuple
from enum import Enum
from datetime import datetime


class IntentCategory(Enum):
    """High-level intent categories."""
    QUERY = "query"  # Information seeking
    COMMAND = "command"  # Action request
    DISCUSSION = "discussion"  # Conversational exchange
    PROBLEM_SOLVING = "problem_solving"  # Technical challenge
    EXPLORATION = "exploration"  # Discovery/learning
    DEBUGGING = "debugging"  # Error resolution


@dataclass
class Intent:
    """Represents a classified user intent."""
    category: IntentCategory
    description: str
    confidence: float
    entities: Dict[str, str] = field(default_factory=dict)
    timestamp: datetime = field(default_factory=datetime.now)
    
    def to_dict(self) -> dict:
        return {
            'category': self.category.value,
            'description': self.description,
            'confidence': self.confidence,
            'entities': self.entities,
            'timestamp': self.timestamp.isoformat()
        }


@dataclass
class IntentHistory:
    """Tracks intent evolution across conversation turns."""
    session_id: str
    intents: List[Intent] = field(default_factory=list)
    dominant_intent: Optional[IntentCategory] = None
    intent_shifts: List[Tuple[datetime, IntentCategory, IntentCategory]] = field(default_factory=list)
    
    def add_intent(self, intent: Intent):
        """Add new intent and track shifts."""
        if self.intents:
            previous_category = self.intents[-1].category
            if previous_category != intent.category:
                self.intent_shifts.append((
                    intent.timestamp,
                    previous_category,
                    intent.category
                ))
        
        self.intents.append(intent)
        self._update_dominant_intent()
    
    def _update_dominant_intent(self):
        """Calculate the most frequent intent category."""
        if not self.intents:
            return
        
        category_counts = {}
        for intent in self.intents:
            cat = intent.category
            category_counts[cat] = category_counts.get(cat, 0) + 1
        
        self.dominant_intent = max(category_counts, key=category_counts.get)
    
    def get_recent_intents(self, n: int = 5) -> List[Intent]:
        """Get the last n intents."""
        return self.intents[-n:]
    
    def detect_pattern(self) -> Optional[str]:
        """Detect recurring intent patterns."""
        if len(self.intents) < 3:
            return None
        
        # Check for alternating patterns
        recent = self.intents[-6:]
        categories = [i.category for i in recent]
        
        # Detect query-command alternation (typical troubleshooting)
        if len(categories) >= 4:
            if all(categories[i] == IntentCategory.QUERY for i in range(0, len(categories), 2)) and \
               all(categories[i] == IntentCategory.COMMAND for i in range(1, len(categories), 2)):
                return "troubleshooting_cycle"
        
        # Detect sustained focus
        if len(set(categories)) == 1:
            return f"sustained_{categories[0].value}"
        
        return None


class IntentTracker:
    """Tracks and analyzes user intents across conversations."""
    
    def __init__(self):
        self.session_histories: Dict[str, IntentHistory] = {}
    
    def classify_intent(self, message: str, context: Optional[Dict] = None) -> Intent:
        """
        Classify the intent of a user message.
        
        Args:
            message: User's message text
            context: Optional conversation context
            
        Returns:
            Classified intent with confidence score
        """
        message_lower = message.lower()
        
        # Simple rule-based classification (can be enhanced with ML model)
        if any(word in message_lower for word in ['what', 'how', 'why', 'when', 'where', 'who']):
            category = IntentCategory.QUERY
            confidence = 0.85
            description = "Information seeking query"
            
        elif any(word in message_lower for word in ['run', 'execute', 'build', 'create', 'deploy', 'test']):
            category = IntentCategory.COMMAND
            confidence = 0.90
            description = "Action command"
            
        elif any(word in message_lower for word in ['error', 'bug', 'fail', 'crash', 'issue']):
            category = IntentCategory.DEBUGGING
            confidence = 0.88
            description = "Debugging request"
            
        elif any(word in message_lower for word in ['optimize', 'improve', 'enhance', 'refactor']):
            category = IntentCategory.PROBLEM_SOLVING
            confidence = 0.87
            description = "Optimization problem"
            
        elif any(word in message_lower for word in ['explore', 'discover', 'learn', 'understand']):
            category = IntentCategory.EXPLORATION
            confidence = 0.82
            description = "Exploratory learning"
            
        else:
            category = IntentCategory.DISCUSSION
            confidence = 0.75
            description = "General discussion"
        
        # Extract simple entities
        entities = self._extract_entities(message)
        
        return Intent(
            category=category,
            description=description,
            confidence=confidence,
            entities=entities
        )
    
    def _extract_entities(self, message: str) -> Dict[str, str]:
        """Extract key entities from message."""
        entities = {}
        message_lower = message.lower()
        
        # Extract technical terms (simplified)
        tech_keywords = ['algorithm', 'database', 'api', 'model', 'function', 'class']
        for keyword in tech_keywords:
            if keyword in message_lower:
                entities['technical_domain'] = keyword
                break
        
        # Extract action verbs
        action_keywords = ['sort', 'search', 'optimize', 'analyze', 'generate']
        for keyword in action_keywords:
            if keyword in message_lower:
                entities['action'] = keyword
                break
        
        return entities
    
    def track_session(self, session_id: str, message: str, 
                     context: Optional[Dict] = None) -> Intent:
        """
        Track intent for a conversation session.
        
        Args:
            session_id: Unique session identifier
            message: User's message
            context: Optional context
            
        Returns:
            Classified intent
        """
        # Get or create session history
        if session_id not in self.session_histories:
            self.session_histories[session_id] = IntentHistory(session_id=session_id)
        
        # Classify intent
        intent = self.classify_intent(message, context)
        
        # Track in history
        self.session_histories[session_id].add_intent(intent)
        
        return intent
    
    def get_session_summary(self, session_id: str) -> Optional[Dict]:
        """Get summary of intent patterns for a session."""
        if session_id not in self.session_histories:
            return None
        
        history = self.session_histories[session_id]
        pattern = history.detect_pattern()
        
        return {
            'session_id': session_id,
            'total_turns': len(history.intents),
            'dominant_intent': history.dominant_intent.value if history.dominant_intent else None,
            'intent_shifts': len(history.intent_shifts),
            'pattern': pattern,
            'recent_categories': [i.category.value for i in history.get_recent_intents(5)]
        }
    
    def predict_next_intent(self, session_id: str) -> Optional[IntentCategory]:
        """Predict likely next intent based on conversation pattern."""
        if session_id not in self.session_histories:
            return None
        
        history = self.session_histories[session_id]
        
        if not history.intents:
            return None
        
        # Simple prediction based on pattern
        pattern = history.detect_pattern()
        
        if pattern == "troubleshooting_cycle":
            # If last was query, expect command; if command, expect query
            last_intent = history.intents[-1].category
            return IntentCategory.COMMAND if last_intent == IntentCategory.QUERY else IntentCategory.QUERY
        
        elif pattern and pattern.startswith("sustained_"):
            # Continue same pattern
            return history.dominant_intent
        
        else:
            # Default to continuation of dominant intent
            return history.dominant_intent
