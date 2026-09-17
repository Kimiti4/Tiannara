"""
Advanced NLP Engine - REFACTORED

Purpose: Specialized NLP capabilities beyond basic intent recognition
Features:
- Sentiment analysis (unique)
- Semantic similarity search (unique)
- Knowledge base management (unique)
- Intent classification delegated to unified intent_system.py

Date: May 8, 2026 (Original) / April 30, 2026 (Refactored)
Status: ✅ REFACTORED - Delegates intent/entity to nlp/intent_system.py
"""

import re
from typing import Dict, List, Optional, Tuple, Any
from datetime import datetime
from enum import Enum
from dataclasses import dataclass, field

# Import unified intent system for delegation
from tiannara_core.nlp.intent_system import (
    IntentRecognizer,
    IntentCategory as UnifiedIntentCategory,
    IntentResult as UnifiedIntentResult,
    ExtractedEntity
)


# Keep local enums for backward compatibility but map to unified ones
class IntentCategory(Enum):
    """High-level intent categories (deprecated - use unified system)."""
    PREDICTION = "prediction"
    ANALYSIS = "analysis"
    INFORMATION = "information"
    ACTION = "action"
    CONFIGURATION = "configuration"
    CLARIFICATION = "clarification"
    FEEDBACK = "feedback"
    GREETING = "greeting"
    UNKNOWN = "unknown"


@dataclass
class NEREntity:
    """Named Entity Recognition result (legacy format)."""
    
    entity_type: str  # PERSON, TEAM, DATE, LOCATION, etc.
    text: str
    start_pos: int
    end_pos: int
    confidence: float = 0.9
    
    @staticmethod
    def from_unified(entity: ExtractedEntity) -> 'NEREntity':
        """Convert from unified ExtractedEntity format."""
        return NEREntity(
            entity_type=entity.entity_type,
            text=entity.value,
            start_pos=entity.start_pos,
            end_pos=entity.end_pos,
            confidence=entity.confidence
        )


@dataclass
class IntentResult:
    """Intent classification result (legacy format with sentiment)."""
    
    category: IntentCategory
    sub_intent: str
    confidence: float
    entities: List[NEREntity] = field(default_factory=list)
    sentiment: Optional[float] = None  # -1.0 to 1.0
    raw_scores: Dict[str, float] = field(default_factory=dict)
    
    @staticmethod
    def from_unified(unified_result: UnifiedIntentResult, sentiment: float = 0.0) -> 'IntentResult':
        """Convert from unified IntentResult format."""
        # Map unified category to legacy category
        try:
            legacy_category = IntentCategory(unified_result.category.value)
        except ValueError:
            legacy_category = IntentCategory.UNKNOWN
        
        # Convert entities
        legacy_entities = [NEREntity.from_unified(e) for e in unified_result.entities]
        
        return IntentResult(
            category=legacy_category,
            sub_intent=unified_result.primary_intent,
            confidence=unified_result.confidence,
            entities=legacy_entities,
            sentiment=sentiment,
            raw_scores={"primary": unified_result.confidence}
        )


@dataclass
class SemanticMatch:
    """Semantic similarity match result."""
    
    query: str
    matched_text: str
    similarity_score: float
    metadata: Dict[str, Any] = field(default_factory=dict)


class AdvancedNLPEngine:
    """
    Advanced NLP Engine with specialized capabilities.
    
    DELEGATION STRATEGY:
    - Intent classification: Delegated to tiannara_core.nlp.intent_system.IntentRecognizer
    - Entity extraction: Delegated to tiannara_core.nlp.intent_system.IntentRecognizer
    - Sentiment analysis: Implemented here (unique feature)
    - Semantic search: Implemented here (unique feature)
    
    This avoids code duplication while maintaining backward compatibility.
    """
    
    def __init__(self):
        # Delegate intent recognition to unified system
        self.intent_recognizer = IntentRecognizer()
        
        # Unique features implemented here
        self.sentiment_lexicon = self._build_sentiment_lexicon()
        
        # Knowledge base for semantic search
        self.knowledge_base: List[Dict[str, Any]] = []
    
    def classify_intent(self, text: str) -> IntentResult:
        """
        Classify user intent from text (delegates to unified system).
        
        Args:
            text: User input text
            
        Returns:
            IntentResult with category, confidence, entities, AND sentiment
        """
        # Step 1: Delegate to unified intent system
        unified_result = self.intent_recognizer.recognize_intent(text)
        
        # Step 2: Analyze sentiment (unique feature)
        sentiment = self.analyze_sentiment(text)
        
        # Step 3: Convert to legacy format with sentiment added
        legacy_result = IntentResult.from_unified(unified_result, sentiment)
        
        return legacy_result
    
    def detect_multi_intent(self, text: str) -> List[str]:
        """
        Detect multiple intents in text (delegation wrapper for backward compatibility).
        
        This method was moved to the unified intent system. This wrapper maintains
        API compatibility for existing code.
        
        Args:
            text: Input text
            
        Returns:
            List of detected intent strings
        """
        result = self.intent_recognizer.recognize_intent(text)
        # Return sub-intents if detected, otherwise just primary intent
        return result.sub_intents if result.sub_intents else [result.primary_intent]
    
    def extract_entities(self, text: str) -> List[NEREntity]:
        """
        Extract named entities from text (delegates to unified system).
        
        Args:
            text: Input text
            
        Returns:
            List of NEREntity objects
        """
        # Delegate to unified system
        unified_result = self.intent_recognizer.recognize_intent(text)
        
        # Convert to legacy format
        return [NEREntity.from_unified(e) for e in unified_result.entities]
    
    def analyze_sentiment(self, text: str) -> float:
        """
        Analyze sentiment of text (UNIQUE FEATURE - kept here).
        
        Args:
            text: Input text
            
        Returns:
            Sentiment score from -1.0 (very negative) to 1.0 (very positive)
        """
        words = text.lower().split()
        
        total_score = 0.0
        word_count = 0
        
        for word in words:
            # Remove punctuation
            clean_word = re.sub(r'[^\w]', '', word)
            
            if clean_word in self.sentiment_lexicon:
                total_score += self.sentiment_lexicon[clean_word]
                word_count += 1
        
        if word_count == 0:
            return 0.0  # Neutral
        
        # Normalize to [-1, 1] range
        avg_score = total_score / word_count
        return max(-1.0, min(1.0, avg_score))
    
    def semantic_search(self, query: str, top_k: int = 5) -> List[SemanticMatch]:
        """
        Perform semantic similarity search against knowledge base (UNIQUE FEATURE).
        
        Uses TF-IDF-like approach for semantic matching.
        
        Args:
            query: Search query
            top_k: Number of results to return
            
        Returns:
            List of SemanticMatch objects sorted by similarity
        """
        if not self.knowledge_base:
            return []
        
        # Tokenize query
        query_tokens = set(re.findall(r'\w+', query.lower()))
        
        matches = []
        
        for item in self.knowledge_base:
            text = item.get('text', '')
            tokens = set(re.findall(r'\w+', text.lower()))
            
            if not tokens or not query_tokens:
                continue
            
            # Calculate Jaccard similarity
            intersection = query_tokens.intersection(tokens)
            union = query_tokens.union(tokens)
            
            similarity = len(intersection) / len(union) if union else 0.0
            
            if similarity > 0.0:
                match = SemanticMatch(
                    query=query,
                    matched_text=text,
                    similarity_score=similarity,
                    metadata=item.get('metadata', {})
                )
                matches.append(match)
        
        # Sort by similarity descending
        matches.sort(key=lambda m: m.similarity_score, reverse=True)
        
        return matches[:top_k]
    
    def add_to_knowledge_base(self, text: str, metadata: Dict[str, Any] = None):
        """
        Add item to knowledge base for semantic search.
        
        Args:
            text: Text content
            metadata: Optional metadata dictionary
        """
        item = {
            'text': text,
            'metadata': metadata or {},
            'added_at': datetime.now().isoformat()
        }
        self.knowledge_base.append(item)
    
    def clear_knowledge_base(self):
        """Clear all items from knowledge base."""
        self.knowledge_base.clear()
    
    def get_knowledge_base_size(self) -> int:
        """Get number of items in knowledge base."""
        return len(self.knowledge_base)
    
    def _build_sentiment_lexicon(self) -> Dict[str, float]:
        """Build comprehensive sentiment lexicon (UNIQUE FEATURE)."""
        
        lexicon = {
            # Positive words
            'good': 0.7, 'great': 0.9, 'excellent': 1.0, 'perfect': 1.0,
            'awesome': 0.9, 'fantastic': 0.95, 'wonderful': 0.85, 'amazing': 0.9,
            'happy': 0.7, 'pleased': 0.7, 'satisfied': 0.6, 'impressive': 0.8,
            'success': 0.8, 'win': 0.7, 'victory': 0.85, 'achieve': 0.7,
            'love': 0.9, 'like': 0.5, 'enjoy': 0.7, 'best': 0.9,
            'helpful': 0.7, 'useful': 0.6, 'clear': 0.5, 'accurate': 0.7,
            
            # Negative words
            'bad': -0.7, 'terrible': -0.95, 'awful': -0.9, 'horrible': -0.95,
            'poor': -0.6, 'weak': -0.5, 'fail': -0.8, 'failure': -0.85,
            'loss': -0.7, 'defeat': -0.75, 'disappointing': -0.7, 'wrong': -0.6,
            'hate': -0.9, 'dislike': -0.6, 'confusing': -0.5, 'unclear': -0.5,
            'inaccurate': -0.7, 'incorrect': -0.6, 'error': -0.7, 'problem': -0.6,
            
            # Neutral/Context-dependent
            'okay': 0.1, 'average': 0.0, 'normal': 0.0, 'standard': 0.0,
            'maybe': 0.0, 'possibly': 0.0, 'perhaps': 0.0,
        }
        
        return lexicon
    
    def get_nlp_stats(self) -> Dict[str, Any]:
        """Get NLP engine statistics."""
        return {
            'knowledge_base_size': len(self.knowledge_base),
            'sentiment_lexicon_size': len(self.sentiment_lexicon),
            'intent_recognizer_stats': self.intent_recognizer.get_statistics()
        }


# Export main class
__all__ = ['AdvancedNLPEngine', 'IntentCategory', 'IntentResult', 'NEREntity', 'SemanticMatch']
