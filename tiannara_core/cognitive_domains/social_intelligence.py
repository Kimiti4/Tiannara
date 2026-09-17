"""
Social Intelligence Domain - Human-AI Interaction

Enables sophisticated human-AI interaction:
- Emotional understanding and empathy
- Communication style adaptation
- Social context awareness
- Relationship building and trust
"""

from typing import Dict, List, Optional
from datetime import datetime
from enum import Enum


class Emotion(Enum):
    """Basic emotions for social intelligence."""
    HAPPY = "happy"
    SAD = "sad"
    ANGRY = "angry"
    FEARFUL = "fearful"
    SURPRISED = "surprised"
    DISGUSTED = "disgusted"
    NEUTRAL = "neutral"
    CONFUSED = "confused"
    FRUSTRATED = "frustrated"


class CommunicationStyle(Enum):
    """Communication styles for adaptation."""
    FORMAL = "formal"
    CASUAL = "casual"
    TECHNICAL = "technical"
    SIMPLIFIED = "simplified"
    EMPATHETIC = "empathetic"
    DIRECT = "direct"


class UserInteraction:
    """Represents a user interaction session."""
    
    def __init__(self, user_id: str):
        self.user_id = user_id
        self.interaction_history = []
        self.emotional_state = Emotion.NEUTRAL
        self.preferred_style = CommunicationStyle.CASUAL
        self.trust_level = 0.5  # 0.0 to 1.0
        self.context = {}
    
    def add_interaction(self, user_message: str, ai_response: str, emotion: Emotion):
        """Record an interaction."""
        self.interaction_history.append({
            'user_message': user_message,
            'ai_response': ai_response,
            'emotion': emotion.value,
            'timestamp': datetime.utcnow().isoformat()
        })
        
        # Update emotional state
        self.emotional_state = emotion
        
        # Adjust trust based on emotion
        if emotion in [Emotion.HAPPY, Emotion.SURPRISED]:
            self.trust_level = min(1.0, self.trust_level + 0.05)
        elif emotion in [Emotion.ANGRY, Emotion.FRUSTRATED]:
            self.trust_level = max(0.0, self.trust_level - 0.05)


class SocialIntelligenceSystem:
    """
    System for managing human-AI social interactions.
    
    Features:
    - Emotion detection and response
    - Communication style adaptation
    - Context-aware interactions
    - Trust building and maintenance
    - Cultural sensitivity
    """
    
    def __init__(self):
        self.users: Dict[str, UserInteraction] = {}
        self.interaction_patterns = []
        self.social_metrics = {
            'total_interactions': 0,
            'avg_trust_level': 0.5,
            'positive_interactions': 0,
            'negative_interactions': 0
        }
    
    def register_user(self, user_id: str, preferences: Optional[Dict] = None) -> bool:
        """Register a new user with optional preferences."""
        if user_id in self.users:
            return False
        
        user = UserInteraction(user_id)
        
        if preferences:
            if 'communication_style' in preferences:
                try:
                    user.preferred_style = CommunicationStyle(preferences['communication_style'])
                except ValueError:
                    pass
            
            if 'context' in preferences:
                user.context = preferences['context']
        
        self.users[user_id] = user
        return True
    
    def analyze_emotion(self, text: str) -> Emotion:
        """Detect emotion from text (simplified implementation)."""
        text_lower = text.lower()
        
        # Simple keyword-based emotion detection
        emotion_indicators = {
            Emotion.HAPPY: ['happy', 'great', 'excellent', 'wonderful', 'love', 'good'],
            Emotion.SAD: ['sad', 'unfortunately', 'disappointed', 'regret', 'sorry'],
            Emotion.ANGRY: ['angry', 'frustrated', 'annoyed', 'terrible', 'horrible'],
            Emotion.FEARFUL: ['afraid', 'worried', 'concerned', 'anxious', 'scared'],
            Emotion.SURPRISED: ['wow', 'amazing', 'unexpected', 'surprising', 'incredible'],
            Emotion.FRUSTRATED: ['stuck', 'confused', 'difficult', 'hard', 'problem'],
        }
        
        detected_emotions = []
        for emotion, keywords in emotion_indicators.items():
            if any(keyword in text_lower for keyword in keywords):
                detected_emotions.append(emotion)
        
        if detected_emotions:
            return detected_emotions[0]  # Return first detected emotion
        
        return Emotion.NEUTRAL
    
    def adapt_communication(self, user_id: str, message: str, context: Optional[Dict] = None) -> Dict:
        """Adapt communication style based on user preferences and context."""
        if user_id not in self.users:
            self.register_user(user_id)
        
        user = self.users[user_id]
        
        # Analyze user's current emotional state
        detected_emotion = self.analyze_emotion(message)
        
        # Determine appropriate response style
        response_style = self._determine_response_style(user, detected_emotion, context)
        
        # Generate adapted response guidelines
        adaptation = {
            'user_id': user_id,
            'detected_emotion': detected_emotion.value,
            'recommended_style': response_style.value,
            'tone': self._get_tone_for_emotion(detected_emotion),
            'considerations': self._get_considerations(user, detected_emotion),
            'trust_level': user.trust_level
        }
        
        return adaptation
    
    def _determine_response_style(self, user: UserInteraction, emotion: Emotion, 
                                  context: Optional[Dict]) -> CommunicationStyle:
        """Determine the best communication style for the situation."""
        # If user is frustrated or confused, use empathetic and simplified
        if emotion in [Emotion.FRUSTRATED, Emotion.CONFUSED]:
            return CommunicationStyle.EMPATHETIC
        
        # If context indicates technical discussion
        if context and context.get('domain') == 'technical':
            return CommunicationStyle.TECHNICAL
        
        # Default to user's preferred style
        return user.preferred_style
    
    def _get_tone_for_emotion(self, emotion: Emotion) -> str:
        """Get appropriate tone for detected emotion."""
        tone_map = {
            Emotion.HAPPY: "enthusiastic and positive",
            Emotion.SAD: "gentle and supportive",
            Emotion.ANGRY: "calm and solution-focused",
            Emotion.FEARFUL: "reassuring and clear",
            Emotion.SURPRISED: "engaging and informative",
            Emotion.FRUSTRATED: "patient and helpful",
            Emotion.CONFUSED: "clear and structured",
            Emotion.NEUTRAL: "professional and friendly"
        }
        return tone_map.get(emotion, "professional")
    
    def _get_considerations(self, user: UserInteraction, emotion: Emotion) -> List[str]:
        """Generate considerations for the interaction."""
        considerations = []
        
        if user.trust_level < 0.3:
            considerations.append("Build trust through transparency and reliability")
        
        if emotion in [Emotion.ANGRY, Emotion.FRUSTRATED]:
            considerations.append("Acknowledge frustration and provide clear solutions")
        
        if len(user.interaction_history) < 3:
            considerations.append("New user - establish rapport and explain capabilities")
        
        if not considerations:
            considerations.append("Maintain consistent, helpful communication")
        
        return considerations
    
    def record_interaction(self, user_id: str, user_message: str, 
                          ai_response: str, emotion: Optional[Emotion] = None):
        """Record a complete interaction."""
        if user_id not in self.users:
            self.register_user(user_id)
        
        user = self.users[user_id]
        
        if emotion is None:
            emotion = self.analyze_emotion(user_message)
        
        user.add_interaction(user_message, ai_response, emotion)
        
        # Update metrics
        self.social_metrics['total_interactions'] += 1
        
        if emotion in [Emotion.HAPPY, Emotion.SURPRISED]:
            self.social_metrics['positive_interactions'] += 1
        elif emotion in [Emotion.ANGRY, Emotion.FRUSTRATED, Emotion.SAD]:
            self.social_metrics['negative_interactions'] += 1
        
        # Update average trust
        total_trust = sum(u.trust_level for u in self.users.values())
        self.social_metrics['avg_trust_level'] = total_trust / max(1, len(self.users))
    
    def get_user_profile(self, user_id: str) -> Optional[Dict]:
        """Get comprehensive user profile including interaction history."""
        if user_id not in self.users:
            return None
        
        user = self.users[user_id]
        
        return {
            'user_id': user_id,
            'preferred_style': user.preferred_style.value,
            'current_emotion': user.emotional_state.value,
            'trust_level': user.trust_level,
            'total_interactions': len(user.interaction_history),
            'recent_interactions': user.interaction_history[-5:],
            'context': user.context
        }
    
    def get_social_metrics(self) -> Dict:
        """Get overall social intelligence metrics."""
        return {
            **self.social_metrics,
            'registered_users': len(self.users),
            'avg_interactions_per_user': (
                self.social_metrics['total_interactions'] / 
                max(1, len(self.users))
            ),
            'sentiment_ratio': (
                self.social_metrics['positive_interactions'] / 
                max(1, self.social_metrics['positive_interactions'] + 
                    self.social_metrics['negative_interactions'])
            )
        }
