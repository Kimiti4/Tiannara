"""
Unified Intent Recognition System

Purpose: Comprehensive intent understanding with entity extraction
Features:
- Multi-class intent classification (9 categories)
- Named Entity Recognition (NER)
- Confidence scoring
- Multi-intent detection
- Context-aware classification
- Entity extraction and linking
- Fallback handling
- Statistics tracking

Date: April 30, 2026
Status: UNIFIED - Merged from nlp/advanced_nlp.py and usability/intent_recognition.py
"""

import re
from typing import Dict, List, Any, Optional, Tuple
from enum import Enum
from dataclasses import dataclass, field


class IntentCategory(Enum):
    """High-level intent categories (unified from both systems)."""
    PREDICTION = "prediction"             # Requesting prediction
    ANALYSIS = "analysis"                 # Requesting analysis
    INFORMATION = "information"           # Seeking information
    ACTION = "action"                     # Requesting action
    CONFIGURATION = "configuration"       # Changing settings
    NAVIGATION = "navigation"            # Navigation request (from old system)
    CLARIFICATION = "clarification"      # Asking for clarification
    FEEDBACK = "feedback"                # Providing feedback
    GREETING = "greeting"                # Social interaction
    UNKNOWN = "unknown"                  # Unclear intent


@dataclass
class ExtractedEntity:
    """Represents an extracted entity from user input."""
    
    entity_type: str  # "date", "team", "sport", "amount", etc.
    value: str
    confidence: float = 1.0
    start_pos: int = 0
    end_pos: int = 0
    
    def to_dict(self) -> Dict:
        return {
            "entity_type": self.entity_type,
            "value": self.value,
            "confidence": self.confidence,
            "position": (self.start_pos, self.end_pos)
        }


@dataclass
class IntentResult:
    """Result of intent recognition (unified structure)."""
    
    primary_intent: str
    category: IntentCategory
    confidence: float
    entities: List[ExtractedEntity] = field(default_factory=list)
    parameters: Dict[str, Any] = field(default_factory=dict)
    sub_intents: List[str] = field(default_factory=list)
    requires_clarification: bool = False
    clarification_question: Optional[str] = None
    
    def to_dict(self) -> Dict:
        return {
            "primary_intent": self.primary_intent,
            "category": self.category.value,
            "confidence": self.confidence,
            "entities": [e.to_dict() for e in self.entities],
            "parameters": self.parameters,
            "sub_intents": self.sub_intents,
            "requires_clarification": self.requires_clarification,
            "clarification_question": self.clarification_question
        }


class IntentRecognizer:
    """
    Unified intent recognition system combining best features from both implementations.
    
    Features:
    - Pattern-based intent classification with comprehensive regex patterns
    - Named Entity Recognition (NER) for teams, dates, locations, etc.
    - Multi-intent detection (can identify multiple intents in one query)
    - Confidence scoring based on pattern match strength
    - Context-aware intent detection
    - Statistics tracking for continuous improvement
    """
    
    def __init__(self):
        # Intent patterns (comprehensive regex-based from both systems)
        self.intent_patterns = self._build_unified_intent_patterns()
        
        # Entity extractors (enhanced NER)
        self.entity_extractors = self._build_enhanced_entity_extractors()
        
        # Intent hierarchy (for sub-intent classification)
        self.intent_hierarchy = {
            "get_prediction": ["get_sports_prediction", "get_financial_prediction"],
            "get_analysis": ["get_team_analysis", "get_performance_analysis"],
            "configure_settings": ["set_preference", "update_notification"],
        }
        
        # Statistics tracking
        self.recognition_stats = {
            "total_recognized": 0,
            "by_intent": {},
            "average_confidence": 0.0
        }
    
    def _build_unified_intent_patterns(self) -> Dict[IntentCategory, List[Tuple[str, re.Pattern]]]:
        """Build comprehensive intent patterns merging both systems."""
        
        patterns = {
            # Prediction intents (merged from both systems)
            IntentCategory.PREDICTION: [
                ("predict_outcome", re.compile(r'\b(predict|prediction|forecast|will|going to)\b.*\b(win|lose|score|result|outcome)', re.IGNORECASE)),
                ("predict_winner", re.compile(r'\b(who\s+will\s+win|which\s+team\s+wins|winner|prediction)\b', re.IGNORECASE)),
                ("future_performance", re.compile(r'\b(how\s+will|expect|anticipate)\b.*\b(perform|do|play)', re.IGNORECASE)),
                ("probability_query", re.compile(r'\b(chance|probability|likelihood|odds)\b.*\b(win|lose|draw)', re.IGNORECASE)),
                ("financial_prediction", re.compile(r'\b(predict|forecast)\b.*\b(stock|market|price|crypto)', re.IGNORECASE)),
            ],
            
            # Analysis intents (merged from both systems)
            IntentCategory.ANALYSIS: [
                ("analyze_performance", re.compile(r'\b(analyze|analysis|stats|statistics)\b.*\b(performance|form|record|team|player)', re.IGNORECASE)),
                ("compare_teams", re.compile(r'\b(compare|versus|vs\.?|against|head[- ]to[- ]head|h2h)\b', re.IGNORECASE)),
                ("trend_analysis", re.compile(r'\b(trend|pattern|tendency|trajectory|market\s+trend)', re.IGNORECASE)),
                ("deep_dive", re.compile(r'\b(deep\s+dive|detailed\s+analysis|breakdown)', re.IGNORECASE)),
                ("recent_form", re.compile(r'\b(recent\s+(stats|performance|form|results|matches|games))\b', re.IGNORECASE)),
                ("show_stats", re.compile(r'\b(show|give|get)\b.*\b(stats|statistics|analysis)\b', re.IGNORECASE)),
            ],
            
            # Information intents (merged from both systems)
            IntentCategory.INFORMATION: [
                ("get_facts", re.compile(r'\b(what|who|when|where|why|how)\b', re.IGNORECASE)),
                ("request_info", re.compile(r'\b(tell\s+me|show\s+me|explain|describe)\b', re.IGNORECASE)),
                ("definition", re.compile(r'\b(what\s+is|define|meaning\s+of)\b', re.IGNORECASE)),
                ("status_check", re.compile(r'\b(current|latest|recent|current\s+status)\b', re.IGNORECASE)),
                ("info_about", re.compile(r'\b(information|info|details)\b.*\b(about|on|regarding)', re.IGNORECASE)),
                ("polite_request", re.compile(r'\b(can you|could you)\b.*\b(tell|show|explain)', re.IGNORECASE)),
            ],
            
            # Action intents (merged from both systems)
            IntentCategory.ACTION: [
                ("execute_task", re.compile(r'\b(run|execute|start|begin|launch)\b', re.IGNORECASE)),
                ("create_something", re.compile(r'\b(create|make|generate|build)\b', re.IGNORECASE)),
                ("modify_data", re.compile(r'\b(update|change|modify|edit|adjust)\b', re.IGNORECASE)),
                ("delete_remove", re.compile(r'\b(delete|remove|clear|erase)\b', re.IGNORECASE)),
                ("calculate", re.compile(r'\b(calculate|compute|determine)\b', re.IGNORECASE)),
            ],
            
            # Configuration intents (merged from both systems)
            IntentCategory.CONFIGURATION: [
                ("configure_system", re.compile(r'\b(configure|setup|set\s+up|initialize)\b', re.IGNORECASE)),
                ("change_settings", re.compile(r'\b(change|adjust|modify)\b.*\b(setting|parameter|option)', re.IGNORECASE)),
                ("enable_disable", re.compile(r'\b(enable|disable|turn\s+on|turn\s+off|activate|deactivate)\b', re.IGNORECASE)),
                ("set_preference", re.compile(r'\b(set\s+preference|prefer|default)\b', re.IGNORECASE)),
            ],
            
            # Navigation intents (from old system)
            IntentCategory.NAVIGATION: [
                ("navigate_to", re.compile(r'\b(go\s+to|navigate|open|access)\b.*\b(page|section|tab)', re.IGNORECASE)),
                ("return_back", re.compile(r'\b(go\s+back|return|previous)\b', re.IGNORECASE)),
            ],
            
            # Clarification intents (merged from both systems)
            IntentCategory.CLARIFICATION: [
                ("ask_clarification", re.compile(r'\b(what\s+do\s+you\s+mean|clarify|explain\s+that|elaborate)\b', re.IGNORECASE)),
                ("confirm_understanding", re.compile(r'\b(do\s+you\s+mean|are\s+you\s+saying|correct\?)\b', re.IGNORECASE)),
                ("request_example", re.compile(r'\b(example|illustrate|show\s+me\s+an\s+example)\b', re.IGNORECASE)),
            ],
            
            # Feedback intents (merged from both systems)
            IntentCategory.FEEDBACK: [
                ("positive_feedback", re.compile(r'\b(good|great|excellent|perfect|awesome|well\s+done)\b', re.IGNORECASE)),
                ("negative_feedback", re.compile(r'\b(bad|wrong|incorrect|poor|terrible|not\s+working)\b', re.IGNORECASE)),
                ("suggestion", re.compile(r'\b(suggest|recommendation|should|could\s+you)\b', re.IGNORECASE)),
            ],
            
            # Greeting intents (merged from both systems)
            IntentCategory.GREETING: [
                ("greeting", re.compile(r'\b(hi|hello|hey|good\s+(morning|afternoon|evening))\b', re.IGNORECASE)),
                ("farewell", re.compile(r'\b(bye|goodbye|see\s+you|later)\b', re.IGNORECASE)),
                ("thanks", re.compile(r'\b(thanks|thank\s+you|appreciate)\b', re.IGNORECASE)),
            ],
        }
        
        return patterns
    
    def _build_enhanced_entity_extractors(self) -> Dict[str, re.Pattern]:
        """Build enhanced entity extraction patterns."""
        
        patterns = {
            # Teams and organizations
            "TEAM": re.compile(r'\b([A-Z][a-z]+\s+(United|City|FC|Team|Club|Warriors|Eagles|Lions|Tigers))\b'),
            
            # People names
            "PERSON": re.compile(r'\b([A-Z][a-z]+\s+[A-Z][a-z]+)\b'),
            
            # Dates (multiple formats)
            "DATE": re.compile(r'\b(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4}|today|tomorrow|yesterday|next\s+\w+)\b'),
            
            # Times
            "TIME": re.compile(r'\b(\d{1,2}:\d{2}\s*(AM|PM)?|\d{1,2}\s+(am|pm))\b', re.IGNORECASE),
            
            # Locations
            "LOCATION": re.compile(r'\b([A-Z][a-z]+\s+(Stadium|Arena|Field|Court|Park))\b'),
            
            # Numbers and percentages
            "NUMBER": re.compile(r'\b(\d+(\.\d+)?%?|\d+,\d+)\b'),
            
            # Durations
            "DURATION": re.compile(r'\b(\d+\s+(minutes?|hours?|days?|weeks?|months?|years?))\b', re.IGNORECASE),
            
            # Sports types
            "SPORT": re.compile(r'\b(football|basketball|soccer|tennis|baseball|hockey|cricket|rugby)\b', re.IGNORECASE),
            
            # Financial instruments
            "STOCK": re.compile(r'\b([A-Z]{2,5})\b'),  # Simple ticker symbol detection
            
            # Money amounts
            "MONEY": re.compile(r'\b(\$|€|£)\s*\d+(\.\d{2})?\b'),
        }
        
        return patterns
    
    def recognize_intent(self, text: str, context: Optional[Dict] = None) -> IntentResult:
        """
        Recognize user intent from text input.
        
        Args:
            text: User input text
            context: Optional context dictionary for context-aware classification
            
        Returns:
            IntentResult with classified intent, confidence, and extracted entities
        """
        if not text or not text.strip():
            return IntentResult(
                primary_intent="empty_input",
                category=IntentCategory.UNKNOWN,
                confidence=0.0
            )
        
        # Step 1: Extract entities first (helps with intent classification)
        entities = self._extract_entities(text)
        
        # Step 2: Classify intent using pattern matching
        intent_scores = self._classify_intent_patterns(text)
        
        # Step 3: Select best intent
        if not intent_scores:
            return IntentResult(
                primary_intent="unclear",
                category=IntentCategory.UNKNOWN,
                confidence=0.0,
                entities=entities
            )
        
        # Sort by confidence
        best_match = max(intent_scores, key=lambda x: x[2])
        sub_intent, category, confidence = best_match
        
        # Step 4: Check for multi-intent (if multiple high-confidence matches)
        sub_intents = [
            score[0] for score in intent_scores 
            if score[2] > 0.7 and score[0] != sub_intent
        ]
        
        # Step 5: Determine if clarification is needed
        requires_clarification = confidence < 0.5
        clarification_question = None
        if requires_clarification:
            clarification_question = self._generate_clarification_question(category, entities)
        
        # Step 6: Update statistics
        self._update_statistics(sub_intent, confidence)
        
        # Step 7: Build result
        result = IntentResult(
            primary_intent=sub_intent,
            category=category,
            confidence=confidence,
            entities=entities,
            sub_intents=sub_intents,
            requires_clarification=requires_clarification,
            clarification_question=clarification_question
        )
        
        return result
    
    def _classify_intent_patterns(self, text: str) -> List[Tuple[str, IntentCategory, float]]:
        """Classify intent using pattern matching with confidence scores."""
        
        matches = []
        
        for category, patterns in self.intent_patterns.items():
            for sub_intent, pattern in patterns:
                match = pattern.search(text)
                if match:
                    # Calculate confidence based on match quality
                    confidence = self._calculate_pattern_confidence(match, text)
                    matches.append((sub_intent, category, confidence))
        
        return matches
    
    def _calculate_pattern_confidence(self, match: re.Match, text: str) -> float:
        """Calculate confidence score for a pattern match."""
        
        # Base confidence from match span relative to text length
        match_length = match.end() - match.start()
        text_length = len(text)
        
        # Longer matches in shorter texts = higher confidence
        base_confidence = min(1.0, match_length / max(text_length * 0.3, 1))
        
        # Boost for exact keyword matches
        matched_text = match.group().lower()
        if matched_text in ['predict', 'analyze', 'show', 'tell']:
            base_confidence = min(1.0, base_confidence + 0.2)
        
        return round(base_confidence, 2)
    
    def _extract_entities(self, text: str) -> List[ExtractedEntity]:
        """Extract named entities from text."""
        
        entities = []
        
        for entity_type, pattern in self.entity_extractors.items():
            for match in pattern.finditer(text):
                entity = ExtractedEntity(
                    entity_type=entity_type,
                    value=match.group(),
                    confidence=0.9,  # High confidence for regex matches
                    start_pos=match.start(),
                    end_pos=match.end()
                )
                entities.append(entity)
        
        return entities
    
    def _generate_clarification_question(self, category: IntentCategory, entities: List[ExtractedEntity]) -> str:
        """Generate appropriate clarification question."""
        
        if category == IntentCategory.PREDICTION:
            return "What specific outcome would you like me to predict?"
        elif category == IntentCategory.ANALYSIS:
            return "Which team or player would you like me to analyze?"
        elif category == IntentCategory.INFORMATION:
            return "What specific information are you looking for?"
        elif category == IntentCategory.ACTION:
            return "What action would you like me to perform?"
        else:
            return "Could you please clarify your request?"
    
    def _update_statistics(self, intent: str, confidence: float):
        """Update recognition statistics."""
        
        self.recognition_stats["total_recognized"] += 1
        
        if intent not in self.recognition_stats["by_intent"]:
            self.recognition_stats["by_intent"][intent] = 0
        self.recognition_stats["by_intent"][intent] += 1
        
        # Update running average confidence
        total = self.recognition_stats["total_recognized"]
        current_avg = self.recognition_stats["average_confidence"]
        self.recognition_stats["average_confidence"] = (
            (current_avg * (total - 1) + confidence) / total
        )
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get recognition statistics."""
        return self.recognition_stats.copy()
    
    def reset_statistics(self):
        """Reset recognition statistics."""
        self.recognition_stats = {
            "total_recognized": 0,
            "by_intent": {},
            "average_confidence": 0.0
        }


# Backward compatibility adapter for old imports
class IntentRecognitionAdapter:
    """
    Adapter for backward compatibility with old intent_recognition.py API.
    
    This allows existing code to continue working while migrating to the unified system.
    """
    
    def __init__(self):
        self.recognizer = IntentRecognizer()
    
    def recognize_intent(self, text: str, **kwargs) -> Dict:
        """Old API signature - returns dict instead of IntentResult."""
        result = self.recognizer.recognize_intent(text)
        return result.to_dict()
    
    def get_stats(self) -> Dict:
        """Old API signature for statistics."""
        return self.recognizer.get_statistics()


# Export unified recognizer as main class
__all__ = ['IntentRecognizer', 'IntentCategory', 'IntentResult', 'ExtractedEntity']
