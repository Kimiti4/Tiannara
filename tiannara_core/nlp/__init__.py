"""
NLP Module - Natural Language Processing for Tiannara Core

Provides transformer-based intent classification, entity extraction,
sentiment analysis, semantic search, and episodic memory capabilities.
"""

from .intent_classifier import IntentClassifier, IntentResult, IntentClassifierConfig
from .entity_extractor import EntityExtractor, ExtractedEntity
from .sentiment_analyzer import SentimentAnalyzer, SentimentResult
from .semantic_search import SemanticSearch, SearchQuery
from .nlp_pipeline import NLPPipeline, NLPConfig
from .dialogue_state import DialogueStateManager, ConversationContext, DialogueTurn
from .intent_tracker import IntentTracker, Intent, IntentCategory, IntentHistory
from .semantic_memory import SemanticMemory, MemoryNode, TemporalIndex

__all__ = [
    'IntentClassifier',
    'IntentResult', 
    'IntentClassifierConfig',
    'EntityExtractor',
    'ExtractedEntity',
    'SentimentAnalyzer',
    'SentimentResult',
    'SemanticSearch',
    'SearchQuery',
    'NLPPipeline',
    'NLPConfig',
    'DialogueStateManager',
    'ConversationContext',
    'DialogueTurn',
    'IntentTracker',
    'Intent',
    'IntentCategory',
    'IntentHistory',
    'SemanticMemory',
    'MemoryNode',
    'TemporalIndex'
]

__version__ = "1.0.0"
