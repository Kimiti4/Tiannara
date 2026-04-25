"""
Execution Confidence Scoring System

Provides confidence scoring for execution decisions,
helping the system determine when to retry, evolve, or fallback.
"""

from typing import Dict, Any, Optional, List
from dataclasses import dataclass, field
from enum import Enum
import time
import statistics


class ConfidenceLevel(Enum):
    CRITICAL = 0.0      # System will fallback immediately
    LOW = 0.25         # Consider retry, then fallback
    MEDIUM = 0.50      # Normal execution with monitoring
    HIGH = 0.75        # Proceed with confidence
    EXCELLENT = 0.95   # Full speed ahead


@dataclass
class ConfidenceFactors:
    """Factors that influence confidence scoring."""
    llm_plan_available: bool = False
    fallback_plan_used: bool = False
    historical_success_rate: float = 0.5
    tool_reliability: float = 0.5
    complexity_score: float = 0.5
    risk_score: float = 0.5
    memory_support: float = 0.0
    recent_failures: int = 0
    recent_successes: int = 0


@dataclass
class ConfidenceResult:
    """Result of confidence scoring."""
    confidence: float
    level: ConfidenceLevel
    factors: ConfidenceFactors
    reasoning: List[str]
    should_retry: bool
    should_evolve: bool
    should_fallback: bool
    max_retries: int = 3


class ConfidenceScorer:
    """
    Calculates execution confidence based on multiple factors.
    Helps make intelligent execution decisions.
    """
    
    def __init__(self, 
                 min_confidence: float = 0.30,
                 evolution_threshold: float = 0.40,
                 fallback_threshold: float = 0.20):
        self.min_confidence = float(min_confidence)
        self.evolution_threshold = float(evolution_threshold)
        self.fallback_threshold = float(fallback_threshold)
        
        # Factor weights (sum to 1.0)
        self.weights = {
            "llm_availability": 0.25,
            "historical_performance": 0.20,
            "tool_reliability": 0.15,
            "complexity": 0.10,
            "risk": 0.10,
            "memory_support": 0.10,
            "recent_trend": 0.10
        }
    
    def score_execution(self, 
                       intent: str,
                       has_llm_plan: bool,
                       has_fallback_plan: bool,
                       context: Optional[Dict[str, Any]] = None) -> ConfidenceResult:
        """
        Calculate confidence score for execution decision.
        """
        context = context or {}
        
        # Extract factors
        factors = self._extract_factors(intent, has_llm_plan, has_fallback_plan, context)
        
        # Calculate base confidence
        confidence = self._calculate_base_confidence(factors)
        
        # Apply adjustments
        confidence = self._apply_adjustments(confidence, factors, intent)
        
        # Determine level and decisions
        level = self._determine_level(confidence)
        reasoning = self._generate_reasoning(factors, confidence)
        decisions = self._make_decisions(confidence, level, factors)
        
        return ConfidenceResult(
            confidence=confidence,
            level=level,
            factors=factors,
            reasoning=reasoning,
            **decisions
        )
    
    def _extract_factors(self, 
                        intent: str,
                        has_llm_plan: bool,
                        has_fallback_plan: bool,
                        context: Dict[str, Any]) -> ConfidenceFactors:
        """Extract confidence factors from context."""
        
        return ConfidenceFactors(
            llm_plan_available=has_llm_plan,
            fallback_plan_used=has_fallback_plan and not has_llm_plan,
            historical_success_rate=context.get("success_rate", 0.5),
            tool_reliability=context.get("tool_reliability", 0.5),
            complexity_score=self._estimate_complexity(intent),
            risk_score=self._estimate_risk(intent, context),
            memory_support=context.get("memory_support", 0.0),
            recent_failures=context.get("recent_failures", 0),
            recent_successes=context.get("recent_successes", 0)
        )
    
    def _calculate_base_confidence(self, factors: ConfidenceFactors) -> float:
        """Calculate base confidence from factors."""
        
        # LLM availability (big boost)
        llm_score = 0.9 if factors.llm_plan_available else 0.3
        if factors.fallback_plan_used:
            llm_score = 0.4  # Fallback gives minimal confidence
        
        # Historical performance
        hist_score = factors.historical_success_rate
        
        # Tool reliability
        tool_score = factors.tool_reliability
        
        # Complexity (inverse - lower complexity = higher confidence)
        complexity_score = 1.0 - factors.complexity_score
        
        # Risk (inverse - lower risk = higher confidence)
        risk_score = 1.0 - factors.risk_score
        
        # Memory support
        memory_score = min(1.0, factors.memory_support)
        
        # Recent trend
        total_recent = factors.recent_failures + factors.recent_successes
        if total_recent > 0:
            trend_score = factors.recent_successes / total_recent
        else:
            trend_score = 0.5
        
        # Weighted combination
        confidence = (
            llm_score * self.weights["llm_availability"] +
            hist_score * self.weights["historical_performance"] +
            tool_score * self.weights["tool_reliability"] +
            complexity_score * self.weights["complexity"] +
            risk_score * self.weights["risk"] +
            memory_score * self.weights["memory_support"] +
            trend_score * self.weights["recent_trend"]
        )
        
        return max(0.0, min(1.0, confidence))
    
    def _apply_adjustments(self, 
                          confidence: float, 
                          factors: ConfidenceFactors, 
                          intent: str) -> float:
        """Apply contextual adjustments to confidence."""
        
        # Boost for simple, common operations
        simple_keywords = ["save", "read", "list", "help", "status"]
        if any(keyword in intent.lower() for keyword in simple_keywords):
            confidence += 0.1
        
        # Penalty for complex operations
        complex_keywords = ["deploy", "build", "migrate", "delete", "remove"]
        if any(keyword in intent.lower() for keyword in complex_keywords):
            confidence -= 0.15
        
        # Penalty for recent failures
        if factors.recent_failures > factors.recent_successes:
            confidence -= 0.1 * (factors.recent_failures - factors.recent_successes)
        
        # Boost for recent successes
        if factors.recent_successes > factors.recent_failures:
            confidence += 0.05 * min(3, factors.recent_successes - factors.recent_failures)
        
        return max(0.0, min(1.0, confidence))
    
    def _determine_level(self, confidence: float) -> ConfidenceLevel:
        """Determine confidence level from score."""
        if confidence < self.fallback_threshold:
            return ConfidenceLevel.CRITICAL
        elif confidence < self.evolution_threshold:
            return ConfidenceLevel.LOW
        elif confidence < self.min_confidence:
            return ConfidenceLevel.MEDIUM
        elif confidence < 0.75:
            return ConfidenceLevel.HIGH
        else:
            return ConfidenceLevel.EXCELLENT
    
    def _generate_reasoning(self, factors: ConfidenceFactors, confidence: float) -> List[str]:
        """Generate human-readable reasoning for confidence score."""
        reasoning = []
        
        if factors.llm_plan_available:
            reasoning.append("LLM plan available (+confidence)")
        elif factors.fallback_plan_used:
            reasoning.append("Using fallback plan (-confidence)")
        else:
            reasoning.append("No plan available (-confidence)")
        
        if factors.historical_success_rate > 0.7:
            reasoning.append("Strong historical success rate")
        elif factors.historical_success_rate < 0.3:
            reasoning.append("Poor historical success rate")
        
        if factors.tool_reliability > 0.8:
            reasoning.append("High tool reliability")
        elif factors.tool_reliability < 0.5:
            reasoning.append("Low tool reliability")
        
        if factors.complexity_score > 0.7:
            reasoning.append("High complexity detected")
        elif factors.complexity_score < 0.3:
            reasoning.append("Low complexity (simple operation)")
        
        if factors.risk_score > 0.6:
            reasoning.append("High risk operation")
        elif factors.risk_score < 0.4:
            reasoning.append("Low risk operation")
        
        if factors.memory_support > 0.5:
            reasoning.append("Strong memory support")
        
        if factors.recent_failures > factors.recent_successes:
            reasoning.append("Recent failure trend")
        elif factors.recent_successes > factors.recent_failures:
            reasoning.append("Recent success trend")
        
        return reasoning
    
    def _make_decisions(self, 
                       confidence: float, 
                       level: ConfidenceLevel, 
                       factors: ConfidenceFactors) -> Dict[str, Any]:
        """Make execution decisions based on confidence."""
        
        should_retry = confidence >= self.evolution_threshold
        should_evolve = confidence < self.evolution_threshold and confidence >= self.fallback_threshold
        should_fallback = confidence < self.fallback_threshold
        
        # Determine max retries based on confidence
        if level == ConfidenceLevel.EXCELLENT:
            max_retries = 1
        elif level == ConfidenceLevel.HIGH:
            max_retries = 2
        elif level == ConfidenceLevel.MEDIUM:
            max_retries = 3
        else:
            max_retries = 0  # No retries for low confidence
        
        return {
            "should_retry": should_retry,
            "should_evolve": should_evolve,
            "should_fallback": should_fallback,
            "max_retries": max_retries
        }
    
    def _estimate_complexity(self, intent: str) -> float:
        """Estimate complexity of intent (0.0 = simple, 1.0 = complex)."""
        intent_lower = intent.lower()
        
        # Simple operations
        simple_ops = ["save", "read", "list", "show", "help", "status", "get"]
        if any(op in intent_lower for op in simple_ops):
            return 0.2
        
        # Medium complexity
        medium_ops = ["create", "write", "search", "find", "test", "run"]
        if any(op in intent_lower for op in medium_ops):
            return 0.5
        
        # Complex operations
        complex_ops = ["deploy", "build", "migrate", "integrate", "optimize", "analyze"]
        if any(op in intent_lower for op in complex_ops):
            return 0.8
        
        # Very complex operations
        very_complex_ops = ["refactor", "redesign", "architecture", "system"]
        if any(op in intent_lower for op in very_complex_ops):
            return 1.0
        
        # Default complexity
        return 0.5
    
    def _estimate_risk(self, intent: str, context: Dict[str, Any]) -> float:
        """Estimate risk level of intent (0.0 = safe, 1.0 = risky)."""
        intent_lower = intent.lower()
        
        # High-risk operations
        risky_ops = ["delete", "remove", "destroy", "format", "clean", "wipe"]
        if any(op in intent_lower for op in risky_ops):
            return 0.9
        
        # Medium-risk operations
        medium_risky_ops = ["deploy", "migrate", "modify", "change", "update"]
        if any(op in intent_lower for op in medium_risky_ops):
            return 0.6
        
        # Low-risk operations
        safe_ops = ["read", "list", "show", "help", "status", "get", "save"]
        if any(op in intent_lower for op in safe_ops):
            return 0.1
        
        # Check for system paths in context
        if context:
            paths = str(context.values()).lower()
            if any(system_path in paths for system_path in ["system32", "windows", "program files"]):
                return 0.8
        
        # Default risk
        return 0.3
    
    def update_from_result(self, 
                          result: Dict[str, Any], 
                          success: bool):
        """Update scoring based on execution results."""
        # This would update historical success rates and trends
        # Implementation depends on how we store execution history
        pass


# Global confidence scorer instance
_confidence_scorer = None

def get_confidence_scorer() -> ConfidenceScorer:
    """Get or create the global confidence scorer instance."""
    global _confidence_scorer
    if _confidence_scorer is None:
        _confidence_scorer = ConfidenceScorer()
    return _confidence_scorer

def score_execution_confidence(intent: str,
                             has_llm_plan: bool,
                             has_fallback_plan: bool,
                             context: Optional[Dict[str, Any]] = None) -> ConfidenceResult:
    """
    Quick access function for confidence scoring.
    This is the main entry point for confidence evaluation.
    """
    scorer = get_confidence_scorer()
    return scorer.score_execution(intent, has_llm_plan, has_fallback_plan, context)
