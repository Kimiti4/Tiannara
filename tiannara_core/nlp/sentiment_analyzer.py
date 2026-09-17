"""
Sentiment Analyzer - Sentiment and emotion detection

Detects positive/negative/neutral sentiments and fine-grained emotions.
Adjusts response tone and tracks sentiment trends over time.
"""

import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from enum import Enum
from datetime import datetime

logger = logging.getLogger(__name__)


class SentimentType(Enum):
    """Types of sentiment."""
    POSITIVE = "positive"
    NEGATIVE = "negative"
    NEUTRAL = "neutral"


class EmotionType(Enum):
    """Fine-grained emotion types."""
    JOY = "joy"
    ANGER = "anger"
    SADNESS = "sadness"
    FEAR = "fear"
    SURPRISE = "surprise"
    DISGUST = "disgust"
    TRUST = "trust"
    ANTICIPATION = "anticipation"


@dataclass
class SentimentResult:
    """Result from sentiment analysis."""
    sentiment: SentimentType
    confidence: float
    emotion: Optional[EmotionType] = None
    emotion_confidence: float = 0.0
    scores: Dict[str, float] = field(default_factory=dict)
    
    def __post_init__(self):
        if not 0 <= self.confidence <= 1:
            raise ValueError(f"Confidence must be between 0 and 1, got {self.confidence}")


@dataclass
class SentimentTrend:
    """Tracks sentiment over time."""
    user_id: str
    trend_data: List[Dict[str, Any]] = field(default_factory=list)
    
    def add_reading(self, sentiment: SentimentResult, timestamp: Optional[datetime] = None):
        """Add a sentiment reading."""
        self.trend_data.append({
            'timestamp': timestamp or datetime.now(),
            'sentiment': sentiment.sentiment.value,
            'confidence': sentiment.confidence,
            'emotion': sentiment.emotion.value if sentiment.emotion else None
        })
    
    def get_average_sentiment(self) -> float:
        """Calculate average sentiment score."""
        if not self.trend_data:
            return 0.0
        
        score_map = {'positive': 1.0, 'neutral': 0.0, 'negative': -1.0}
        scores = [score_map.get(d['sentiment'], 0.0) for d in self.trend_data]
        return sum(scores) / len(scores)


class SentimentAnalyzer:
    """Sentiment and emotion detection system.
    
    Features:
    - Detect positive/negative/neutral sentiments
    - Fine-grained emotion detection
    - Adjust response tone based on sentiment
    - Track sentiment trends over time
    - Flag frustrated users for escalation
    
    Example:
        >>> analyzer = SentimentAnalyzer()
        >>> result = analyzer.analyze("I'm really happy with this!")
        >>> print(result.sentiment, result.emotion)
    """
    
    def __init__(self):
        self.model = None
        self._initialized = False
        self.user_trends: Dict[str, SentimentTrend] = {}
        
        logger.info("Initialized SentimentAnalyzer")
    
    def initialize(self):
        """Load sentiment analysis model."""
        try:
            from transformers import pipeline
            self.model = pipeline("sentiment-analysis")
            self._initialized = True
            logger.info("Sentiment model loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load sentiment model: {e}")
            # Will use rule-based fallback
    
    def analyze(self, text: str) -> SentimentResult:
        """Analyze sentiment of text.
        
        Args:
            text: Input text
            
        Returns:
            SentimentResult with sentiment and emotion
        """
        if not self._initialized:
            try:
                self.initialize()
            except Exception:
                pass  # Use rule-based fallback
        
        if self.model:
            try:
                result = self.model(text)[0]
                sentiment_str = result['label'].lower()
                confidence = result['score']
                
                # Map to our sentiment type
                if 'pos' in sentiment_str:
                    sentiment = SentimentType.POSITIVE
                elif 'neg' in sentiment_str:
                    sentiment = SentimentType.NEGATIVE
                else:
                    sentiment = SentimentType.NEUTRAL
                
                # Detect emotion (simplified)
                emotion = self._detect_emotion(text, sentiment)
                
                return SentimentResult(
                    sentiment=sentiment,
                    confidence=confidence,
                    emotion=emotion,
                    emotion_confidence=0.7 if emotion else 0.0,
                    scores={'positive': confidence if sentiment == SentimentType.POSITIVE else 0.0,
                           'negative': confidence if sentiment == SentimentType.NEGATIVE else 0.0}
                )
            except Exception as e:
                logger.error(f"Sentiment analysis failed: {e}")
        
        # Fallback to rule-based
        return self._rule_based_analysis(text)
    
    def _detect_emotion(self, text: str, sentiment: SentimentType) -> Optional[EmotionType]:
        """Detect fine-grained emotion from text."""
        text_lower = text.lower()
        
        emotion_keywords = {
            EmotionType.JOY: ['happy', 'glad', 'excited', 'love', 'great', 'wonderful'],
            EmotionType.ANGER: ['angry', 'hate', 'terrible', 'awful', 'worst'],
            EmotionType.SADNESS: ['sad', 'unhappy', 'disappointed', 'depressed'],
            EmotionType.FEAR: ['afraid', 'scared', 'worried', 'anxious'],
            EmotionType.SURPRISE: ['wow', 'amazing', 'incredible', 'unexpected'],
        }
        
        for emotion, keywords in emotion_keywords.items():
            if any(kw in text_lower for kw in keywords):
                return emotion
        
        return None
    
    def _rule_based_analysis(self, text: str) -> SentimentResult:
        """Rule-based sentiment analysis fallback."""
        text_lower = text.lower()
        
        positive_words = ['good', 'great', 'excellent', 'happy', 'love', 'best', 'wonderful']
        negative_words = ['bad', 'terrible', 'awful', 'hate', 'worst', 'poor', 'horrible']
        
        pos_count = sum(1 for word in positive_words if word in text_lower)
        neg_count = sum(1 for word in negative_words if word in text_lower)
        
        if pos_count > neg_count:
            sentiment = SentimentType.POSITIVE
            confidence = min(0.6 + (pos_count * 0.1), 0.95)
        elif neg_count > pos_count:
            sentiment = SentimentType.NEGATIVE
            confidence = min(0.6 + (neg_count * 0.1), 0.95)
        else:
            sentiment = SentimentType.NEUTRAL
            confidence = 0.5
        
        emotion = self._detect_emotion(text, sentiment)
        
        return SentimentResult(
            sentiment=sentiment,
            confidence=confidence,
            emotion=emotion,
            emotion_confidence=0.6 if emotion else 0.0
        )
    
    def track_user_sentiment(self, user_id: str, text: str):
        """Track sentiment for a user over time.
        
        Args:
            user_id: User identifier
            text: User's text input
        """
        if user_id not in self.user_trends:
            self.user_trends[user_id] = SentimentTrend(user_id=user_id)
        
        result = self.analyze(text)
        self.user_trends[user_id].add_reading(result)
        
        # Check if user is frustrated (multiple negative sentiments)
        if result.sentiment == SentimentType.NEGATIVE and result.confidence > 0.8:
            recent = self.user_trends[user_id].trend_data[-5:]
            negative_count = sum(1 for d in recent if d['sentiment'] == 'negative')
            
            if negative_count >= 3:
                logger.warning(f"User {user_id} showing frustration - consider escalation")
    
    def get_user_trend(self, user_id: str) -> Optional[SentimentTrend]:
        """Get sentiment trend for a user."""
        return self.user_trends.get(user_id)


# Convenience function
def analyze_sentiment(text: str) -> SentimentResult:
    """Quick sentiment analysis."""
    analyzer = SentimentAnalyzer()
    return analyzer.analyze(text)
