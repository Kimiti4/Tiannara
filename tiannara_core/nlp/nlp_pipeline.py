"""
NLP Pipeline - Orchestration pipeline for NLP components

Coordinates intent classification, entity extraction, sentiment analysis,
and semantic search with error handling and performance monitoring.
"""

import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from datetime import datetime

from .intent_classifier import IntentClassifier, IntentResult
from .entity_extractor import EntityExtractor, EntityExtractionResult
from .sentiment_analyzer import SentimentAnalyzer, SentimentResult
from .semantic_search import SemanticSearch, SearchResult

logger = logging.getLogger(__name__)


@dataclass
class NLPConfig:
    """Configuration for NLP pipeline."""
    enable_intent: bool = True
    enable_entities: bool = True
    enable_sentiment: bool = True
    enable_semantic_search: bool = False
    confidence_threshold: float = 0.7
    max_processing_time_ms: int = 500


@dataclass
class NLPResult:
    """Complete result from NLP pipeline."""
    text: str
    intent: Optional[IntentResult] = None
    entities: Optional[EntityExtractionResult] = None
    sentiment: Optional[SentimentResult] = None
    semantic_matches: Optional[SearchResult] = None
    processing_time_ms: float = 0.0
    timestamp: datetime = field(default_factory=datetime.now)
    
    @property
    def overall_confidence(self) -> float:
        """Calculate overall confidence across all analyses."""
        confidences = []
        if self.intent:
            confidences.append(self.intent.confidence)
        if self.entities and self.entities.entities:
            avg_entity_conf = sum(e.confidence for e in self.entities.entities) / len(self.entities.entities)
            confidences.append(avg_entity_conf)
        if self.sentiment:
            confidences.append(self.sentiment.confidence)
        
        return sum(confidences) / len(confidences) if confidences else 0.0


class NLPPipeline:
    """Orchestration pipeline coordinating all NLP components.
    
    Features:
    - Coordinate intent classification, NER, sentiment analysis
    - Pipeline configuration and customization
    - Error handling and graceful degradation
    - Performance monitoring and metrics
    
    Example:
        >>> pipeline = NLPPipeline()
        >>> result = pipeline.process("I'm happy with Lakers winning!")
        >>> print(result.intent, result.sentiment)
    """
    
    def __init__(self, config: Optional[NLPConfig] = None):
        self.config = config or NLPConfig()
        self.intent_classifier = IntentClassifier() if self.config.enable_intent else None
        self.entity_extractor = EntityExtractor() if self.config.enable_entities else None
        self.sentiment_analyzer = SentimentAnalyzer() if self.config.enable_sentiment else None
        self.semantic_search = SemanticSearch() if self.config.enable_semantic_search else None
        
        logger.info("Initialized NLPPipeline")
    
    def process(self, text: str, context: Optional[Dict[str, Any]] = None) -> NLPResult:
        """Process text through NLP pipeline.
        
        Args:
            text: Input text to analyze
            context: Optional context information
            
        Returns:
            NLPResult with all analysis results
        """
        start_time = datetime.now()
        result = NLPResult(text=text)
        
        try:
            # Intent Classification
            if self.config.enable_intent and self.intent_classifier:
                try:
                    result.intent = self.intent_classifier.classify(text)
                    logger.debug(f"Intent: {result.intent.intent} ({result.intent.confidence:.2f})")
                except Exception as e:
                    logger.error(f"Intent classification failed: {e}")
            
            # Entity Extraction
            if self.config.enable_entities and self.entity_extractor:
                try:
                    result.entities = self.entity_extractor.extract(text)
                    logger.debug(f"Entities: {result.entities.entity_count}")
                except Exception as e:
                    logger.error(f"Entity extraction failed: {e}")
            
            # Sentiment Analysis
            if self.config.enable_sentiment and self.sentiment_analyzer:
                try:
                    result.sentiment = self.sentiment_analyzer.analyze(text)
                    logger.debug(f"Sentiment: {result.sentiment.sentiment.value}")
                    
                    # Track user sentiment if user_id provided
                    if context and 'user_id' in context:
                        self.sentiment_analyzer.track_user_sentiment(
                            context['user_id'], 
                            text
                        )
                except Exception as e:
                    logger.error(f"Sentiment analysis failed: {e}")
            
            # Semantic Search (if enabled and context provided)
            if self.config.enable_semantic_search and self.semantic_search and context:
                try:
                    if 'historical_queries' in context:
                        result.semantic_matches = self.semantic_search.get_similar_queries(
                            text,
                            context['historical_queries']
                        )
                except Exception as e:
                    logger.error(f"Semantic search failed: {e}")
            
            # Calculate processing time
            end_time = datetime.now()
            result.processing_time_ms = (end_time - start_time).total_seconds() * 1000
            
            # Check if processing exceeded threshold
            if result.processing_time_ms > self.config.max_processing_time_ms:
                logger.warning(
                    f"Processing time {result.processing_time_ms:.0f}ms "
                    f"exceeded threshold {self.config.max_processing_time_ms}ms"
                )
            
            logger.info(
                f"NLP pipeline completed in {result.processing_time_ms:.0f}ms "
                f"(confidence: {result.overall_confidence:.2f})"
            )
            
            return result
            
        except Exception as e:
            logger.error(f"NLP pipeline failed: {e}")
            result.processing_time_ms = (datetime.now() - start_time).total_seconds() * 1000
            return result
    
    def process_batch(self, texts: List[str]) -> List[NLPResult]:
        """Process multiple texts through pipeline.
        
        Args:
            texts: List of input texts
            
        Returns:
            List of NLPResults
        """
        return [self.process(text) for text in texts]
    
    def get_pipeline_stats(self) -> Dict[str, Any]:
        """Get pipeline statistics and status."""
        return {
            'enabled_components': {
                'intent': self.config.enable_intent,
                'entities': self.config.enable_entities,
                'sentiment': self.config.enable_sentiment,
                'semantic_search': self.config.enable_semantic_search,
            },
            'config': {
                'confidence_threshold': self.config.confidence_threshold,
                'max_processing_time_ms': self.config.max_processing_time_ms,
            }
        }


# Convenience function
def process_text(text: str, config: Optional[NLPConfig] = None) -> NLPResult:
    """Quick text processing through NLP pipeline."""
    pipeline = NLPPipeline(config)
    return pipeline.process(text)
