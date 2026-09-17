"""
Content Moderation Service for JamiiLink Integration

Provides AI-powered content analysis for:
- Toxicity detection
- Spam identification
- Scam pattern recognition
- Unsafe content flagging

This service wraps Tiannara Core's NLP and reasoning capabilities
behind a clean API for external consumption.
"""

import re
from typing import Dict, Any, List
from dataclasses import dataclass, asdict


@dataclass
class ModerationResult:
    """Structured moderation result"""
    safe: bool
    toxicity_score: float
    spam_probability: float
    scam_probability: float
    categories_flagged: List[str]
    confidence: float
    explanation: str


class ModerationService:
    """
    Content moderation service that analyzes text for harmful content.
    
    Uses pattern matching, keyword analysis, and heuristic scoring
    to identify potentially problematic content.
    
    In production, this would integrate with:
    - Tiannara Core's NLP domain
    - Causal analysis engine
    - Behavioral pattern detection
    """
    
    # Toxicity keywords (simplified - would use ML models in production)
    TOXICITY_KEYWORDS = [
        'hate', 'kill', 'die', 'stupid', 'idiot', 'trash',
        'racist', 'sexist', 'discriminate', 'harass', 'threat'
    ]
    
    # Spam indicators
    SPAM_INDICATORS = [
        r'\b(buy now|click here|limited time|act now)\b',
        r'\b(free.*money|earn.*fast|make.*quick)\b',
        r'\b(winner|congratulations.*selected)\b',
        r'(http[s]?://\S+){3,}',  # Multiple URLs
        r'[A-Z]{10,}',  # ALL CAPS words
    ]
    
    # Scam patterns
    SCAM_PATTERNS = [
        r'\b(send.*money|wire.*transfer|gift.*card)\b',
        r'\b(personal.*information|bank.*details|password)\b',
        r'\b(urgent.*action|immediate.*response)\b',
        r'\b(prince|lottery.*winner|inheritance)\b',
    ]
    
    def __init__(self):
        """Initialize moderation service"""
        self.toxicity_threshold = 0.7
        self.spam_threshold = 0.6
        self.scam_threshold = 0.65
    
    def analyze_content(self, content: str) -> Dict[str, Any]:
        """
        Analyze content for moderation.
        
        Args:
            content: Text content to analyze
            
        Returns:
            Dictionary with moderation scores and flags
        """
        if not content or not content.strip():
            return self._empty_result()
        
        # Calculate individual scores
        toxicity_score = self._calculate_toxicity(content)
        spam_score = self._calculate_spam(content)
        scam_score = self._calculate_scam(content)
        
        # Determine if content is safe
        is_safe = (
            toxicity_score < self.toxicity_threshold and
            spam_score < self.spam_threshold and
            scam_score < self.scam_threshold
        )
        
        # Identify flagged categories
        categories = []
        if toxicity_score >= self.toxicity_threshold:
            categories.append("toxicity")
        if spam_score >= self.spam_threshold:
            categories.append("spam")
        if scam_score >= self.scam_threshold:
            categories.append("scam")
        
        # Calculate overall confidence
        confidence = self._calculate_confidence([toxicity_score, spam_score, scam_score])
        
        # Generate explanation
        explanation = self._generate_explanation(categories, toxicity_score, spam_score, scam_score)
        
        result = ModerationResult(
            safe=is_safe,
            toxicity_score=round(toxicity_score, 3),
            spam_probability=round(spam_score, 3),
            scam_probability=round(scam_score, 3),
            categories_flagged=categories,
            confidence=round(confidence, 3),
            explanation=explanation
        )
        
        return asdict(result)
    
    def _calculate_toxicity(self, content: str) -> float:
        """Calculate toxicity score (0.0 - 1.0)"""
        content_lower = content.lower()
        
        # Check for toxic keywords
        keyword_matches = sum(1 for word in self.TOXICITY_KEYWORDS if word in content_lower)
        keyword_score = min(keyword_matches / 5.0, 1.0)  # Normalize
        
        # Check for aggressive language patterns
        aggressive_patterns = [
            r'\b(you.*should|must.*do|have.*to)\b',  # Commanding language
            r'[!?]{3,}',  # Excessive punctuation
            r'\b(stfu|shut.*up|piss.*off)\b',  # Aggressive phrases
        ]
        
        pattern_score = 0.0
        for pattern in aggressive_patterns:
            if re.search(pattern, content_lower):
                pattern_score += 0.2
        
        # Combine scores
        toxicity = (keyword_score * 0.7) + (pattern_score * 0.3)
        return min(toxicity, 1.0)
    
    def _calculate_spam(self, content: str) -> float:
        """Calculate spam probability (0.0 - 1.0)"""
        content_lower = content.lower()
        
        # Check spam indicators
        indicator_matches = 0
        for pattern in self.SPAM_INDICATORS:
            if re.search(pattern, content_lower):
                indicator_matches += 1
        
        indicator_score = min(indicator_matches / 3.0, 1.0)
        
        # Check for excessive links
        url_count = len(re.findall(r'http[s]?://\S+', content))
        link_score = min(url_count / 5.0, 1.0)
        
        # Check for repetitive content
        words = content_lower.split()
        if len(words) > 10:
            unique_ratio = len(set(words)) / len(words)
            repetition_score = 1.0 - unique_ratio
        else:
            repetition_score = 0.0
        
        # Combine scores
        spam = (indicator_score * 0.5) + (link_score * 0.3) + (repetition_score * 0.2)
        return min(spam, 1.0)
    
    def _calculate_scam(self, content: str) -> float:
        """Calculate scam probability (0.0 - 1.0)"""
        content_lower = content.lower()
        
        # Check scam patterns
        pattern_matches = 0
        for pattern in self.SCAM_PATTERNS:
            if re.search(pattern, content_lower):
                pattern_matches += 1
        
        pattern_score = min(pattern_matches / 3.0, 1.0)
        
        # Check for urgency manipulation
        urgency_words = ['urgent', 'immediately', 'right now', 'asap', 'deadline']
        urgency_count = sum(1 for word in urgency_words if word in content_lower)
        urgency_score = min(urgency_count / 3.0, 1.0)
        
        # Check for financial requests
        money_words = ['money', 'payment', 'transfer', 'deposit', 'fee', 'charge']
        money_count = sum(1 for word in money_words if word in content_lower)
        money_score = min(money_count / 4.0, 1.0)
        
        # Combine scores
        scam = (pattern_score * 0.5) + (urgency_score * 0.25) + (money_score * 0.25)
        return min(scam, 1.0)
    
    def _calculate_confidence(self, scores: List[float]) -> float:
        """Calculate confidence in the moderation decision"""
        # Higher confidence when scores are extreme (very safe or very unsafe)
        max_score = max(scores)
        if max_score > 0.8 or max_score < 0.2:
            return 0.9
        elif max_score > 0.6 or max_score < 0.4:
            return 0.7
        else:
            return 0.5
    
    def _generate_explanation(
        self,
        categories: List[str],
        toxicity: float,
        spam: float,
        scam: float
    ) -> str:
        """Generate human-readable explanation"""
        if not categories:
            return "Content appears safe. No significant issues detected."
        
        explanations = []
        if "toxicity" in categories:
            explanations.append(f"High toxicity detected ({toxicity:.1%})")
        if "spam" in categories:
            explanations.append(f"Spam indicators found ({spam:.1%})")
        if "scam" in categories:
            explanations.append(f"Potential scam patterns ({scam:.1%})")
        
        return "; ".join(explanations)
    
    def _empty_result(self) -> Dict[str, Any]:
        """Return result for empty content"""
        return asdict(ModerationResult(
            safe=True,
            toxicity_score=0.0,
            spam_probability=0.0,
            scam_probability=0.0,
            categories_flagged=[],
            confidence=1.0,
            explanation="Empty content"
        ))
