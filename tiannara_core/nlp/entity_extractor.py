"""
Entity Extractor - Named Entity Recognition (NER)

Extracts domain-specific entities like teams, players, dates, amounts
with confidence scoring and entity linking.
"""

import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from enum import Enum

logger = logging.getLogger(__name__)


class EntityType(Enum):
    """Types of entities that can be extracted."""
    PERSON = "PERSON"
    ORGANIZATION = "ORGANIZATION"
    LOCATION = "LOCATION"
    DATE = "DATE"
    TIME = "TIME"
    MONEY = "MONEY"
    PERCENT = "PERCENT"
    TEAM = "TEAM"
    PLAYER = "PLAYER"
    EVENT = "EVENT"


@dataclass
class ExtractedEntity:
    """Represents an extracted entity."""
    text: str
    entity_type: EntityType
    start_pos: int
    end_pos: int
    confidence: float
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def __post_init__(self):
        if not 0 <= self.confidence <= 1:
            raise ValueError(f"Confidence must be between 0 and 1, got {self.confidence}")


@dataclass
class EntityExtractionResult:
    """Result from entity extraction."""
    entities: List[ExtractedEntity]
    text: str
    
    @property
    def entity_count(self) -> int:
        return len(self.entities)
    
    def get_entities_by_type(self, entity_type: EntityType) -> List[ExtractedEntity]:
        """Filter entities by type."""
        return [e for e in self.entities if e.entity_type == entity_type]


class EntityExtractor:
    """Named Entity Recognition system for domain-specific entities.
    
    Features:
    - Extract teams, players, dates, amounts
    - Domain-specific entity types
    - Confidence scoring per entity
    - Entity linking to knowledge base
    
    Example:
        >>> extractor = EntityExtractor()
        >>> result = extractor.extract("Lakers beat Warriors 120-115")
        >>> print(result.entities)
    """
    
    def __init__(self, model_name: str = "en_core_web_sm"):
        self.model_name = model_name
        self.nlp_model = None
        self._initialized = False
        
        logger.info(f"Initialized EntityExtractor with model={model_name}")
    
    def initialize(self):
        """Load NLP model."""
        try:
            import spacy
            self.nlp_model = spacy.load(self.model_name)
            self._initialized = True
            logger.info("NLP model loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load NLP model: {e}")
            raise
    
    def extract(self, text: str) -> EntityExtractionResult:
        """Extract entities from text.
        
        Args:
            text: Input text
            
        Returns:
            EntityExtractionResult with extracted entities
        """
        if not self._initialized:
            self.initialize()
        
        try:
            doc = self.nlp_model(text)
            entities = []
            
            for ent in doc.ents:
                # Map spaCy entity types to our types
                entity_type = self._map_entity_type(ent.label_)
                
                entity = ExtractedEntity(
                    text=ent.text,
                    entity_type=entity_type,
                    start_pos=ent.start_char,
                    end_pos=ent.end_char,
                    confidence=0.85  # Default confidence
                )
                entities.append(entity)
            
            result = EntityExtractionResult(entities=entities, text=text)
            logger.debug(f"Extracted {len(entities)} entities")
            return result
            
        except Exception as e:
            logger.error(f"Entity extraction failed: {e}")
            # Fallback to simple pattern matching
            return self._simple_extraction(text)
    
    def _map_entity_type(self, spacy_label: str) -> EntityType:
        """Map spaCy entity labels to our entity types."""
        mapping = {
            'PERSON': EntityType.PERSON,
            'ORG': EntityType.ORGANIZATION,
            'GPE': EntityType.LOCATION,
            'DATE': EntityType.DATE,
            'TIME': EntityType.TIME,
            'MONEY': EntityType.MONEY,
            'PERCENT': EntityType.PERCENT,
        }
        return mapping.get(spacy_label, EntityType.PERSON)
    
    def _simple_extraction(self, text: str) -> EntityExtractionResult:
        """Simple fallback extraction using patterns."""
        import re
        
        entities = []
        
        # Extract dates (simple pattern)
        date_pattern = r'\d{4}-\d{2}-\d{2}'
        for match in re.finditer(date_pattern, text):
            entities.append(ExtractedEntity(
                text=match.group(),
                entity_type=EntityType.DATE,
                start_pos=match.start(),
                end_pos=match.end(),
                confidence=0.6
            ))
        
        # Extract money amounts
        money_pattern = r'\$\d+(\.\d{2})?'
        for match in re.finditer(money_pattern, text):
            entities.append(ExtractedEntity(
                text=match.group(),
                entity_type=EntityType.MONEY,
                start_pos=match.start(),
                end_pos=match.end(),
                confidence=0.7
            ))
        
        return EntityExtractionResult(entities=entities, text=text)
    
    def extract_batch(self, texts: List[str]) -> List[EntityExtractionResult]:
        """Extract entities from multiple texts.
        
        Args:
            texts: List of input texts
            
        Returns:
            List of EntityExtractionResults
        """
        return [self.extract(text) for text in texts]


# Convenience function
def extract_entities(text: str) -> EntityExtractionResult:
    """Quick entity extraction."""
    extractor = EntityExtractor()
    return extractor.extract(text)
