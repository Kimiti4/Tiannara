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
    """Levels of execution confidence with qualitative descriptions."""
    CRITICAL = "critical"      # Very low confidence, do not execute
    LOW = "low"               # Low confidence, use fallback
    MEDIUM = "medium"         # Medium confidence, proceed with caution
    HIGH = "high"             # High confidence, execute normally
    EXCELLENT = "excellent"   # Excellent confidence, execute with minimal checks


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
    """Result of confidence evaluation."""
    confidence: float          # 0.0 to 1.0
    level: ConfidenceLevel     # Qualitative level
    reasoning: list[str]       # Explanation for the confidence score
    should_retry: bool         # Whether to retry if execution fails
    should_evolve: bool        # Whether to trigger evolution
    should_fallback: bool      # Whether to use fallback
    max_retries: int = 3       # Maximum number of retries allowed


class ConfidenceScorer:
    """
    Calculates execution confidence based on multiple factors.
    Helps make intelligent execution decisions.
    """
    
    def __init__(self):
        self.default_min_confidence = 0.3
        self.evolve_threshold = 0.4
        self.fallback_threshold = 0.25
        self.weights = {
            "llm_availability": 0.30,
            "historical_performance": 0.20,
            "tool_reliability": 0.15,
            "plan_specificity": 0.15,
            "intent_clarity": 0.10,
            "context_support": 0.10
        }
    
    def score_execution(self, 
                       intent: str,
                       has_llm_plan: bool,
                       has_fallback_plan: bool,
                       context: Optional[Dict[str, Any]] = None) -> ConfidenceResult:
        """
        Score the confidence for executing a plan.
        
        Args:
            intent: Original user intent
            has_llm_plan: Whether an LLM-generated plan exists
            has_fallback_plan: Whether a fallback plan exists
            context: Additional context information
            
        Returns:
            ConfidenceResult with confidence score and recommendations
        """
        context = context or {}
        reasons = []
        
        # Calculate base confidence based on plan availability and intent clarity
        base_confidence = self._calculate_base_confidence(intent, has_llm_plan, has_fallback_plan, context)
        
        # Adjust based on context and intent
        adjusted_confidence = self._adjust_for_context(base_confidence, intent, context)
        
        # Generate reasoning
        reasons = self._generate_reasoning(intent, has_llm_plan, has_fallback_plan, context, adjusted_confidence)
        
        # Determine if we should retry, evolve, or fallback
        should_retry = adjusted_confidence < self.default_min_confidence and context.get('attempt_number', 1) < 3
        should_evolve = adjusted_confidence < self.evolve_threshold
        should_fallback = adjusted_confidence < self.fallback_threshold
        
        # Determine confidence level
        if adjusted_confidence >= 0.8:
            level = ConfidenceLevel.EXCELLENT
        elif adjusted_confidence >= 0.6:
            level = ConfidenceLevel.HIGH
        elif adjusted_confidence >= 0.4:
            level = ConfidenceLevel.MEDIUM
        elif adjusted_confidence >= 0.2:
            level = ConfidenceLevel.LOW
        else:
            level = ConfidenceLevel.CRITICAL
        
        return ConfidenceResult(
            confidence=adjusted_confidence,
            level=level,
            reasoning=reasons,
            should_retry=should_retry,
            should_evolve=should_evolve,
            should_fallback=should_fallback
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
    
    def _calculate_base_confidence(
        self,
        intent: str,
        has_llm_plan: bool,
        has_fallback_plan: bool,
        context: Dict[str, Any]
    ) -> float:
        """Calculate base confidence based on plan availability and intent clarity."""
        base_score = 0.0
        
        # Reward having an LLM plan
        if has_llm_plan:
            base_score += 0.4
        
        # Reward having a fallback plan
        if has_fallback_plan:
            base_score += 0.3
        
        # Evaluate intent clarity (simple heuristics)
        intent_words = intent.split()
        if len(intent_words) < 2:
            # Very short intent, likely low confidence
            base_score -= 0.2
        elif len(intent_words) > 20:
            # Very long intent, might be confusing
            base_score -= 0.1
        else:
            # Reasonable length, good
            base_score += 0.1
        
        # Check for specific keywords that indicate clear intent
        clear_keywords = [
            "save", "write", "create", "read", "list", "delete", 
            "search", "find", "calculate", "compute", "show"
        ]
        if any(keyword in intent.lower() for keyword in clear_keywords):
            base_score += 0.2
        
        # Check for context that might help
        if context.get('file_path') or context.get('target_object'):
            base_score += 0.1
        
        # Plan specificity check
        if has_llm_plan and context.get('plan_steps'):
            try:
                steps = int(context.get('plan_steps', 0))
                if 2 <= steps <= 7:  # Optimal number of steps
                    base_score += 0.15
                elif steps > 10:  # Too many steps can reduce reliability
                    base_score -= 0.1
            except ValueError:
                pass  # If plan_steps isn't a number, skip this check
        
        # Ensure confidence is between 0 and 1
        return max(0.0, min(1.0, base_score))
    
    def _adjust_for_context(
        self,
        base_confidence: float,
        intent: str,
        context: Dict[str, Any]
    ) -> float:
        """Adjust confidence based on context information."""
        adjusted = base_confidence
        
        # Adjust for previous failures
        if 'previous_failures' in context:
            failure_count = context['previous_failures']
            if failure_count > 0:
                adjusted -= 0.1 * failure_count
                # But don't drop too low if we have a good plan
                adjusted = max(adjusted, 0.2 if context.get('has_good_plan') else 0.05)
        
        # Adjust for critical operations
        critical_operations = ['delete', 'remove', 'format', 'destroy', 'kill']
        if any(op in intent.lower() for op in critical_operations):
            # Reduce confidence slightly for critical ops to be more careful
            adjusted = min(adjusted, 0.7)
        
        # Adjust for safety context
        if context.get('safety_mode', False):
            adjusted = min(adjusted, 0.6)  # Be more conservative in safety mode
        
        # Adjust for high-priority tasks
        if context.get('priority') == 'high':
            adjusted = max(adjusted, 0.5)  # Don't let confidence get too low for high-priority tasks
        
        # Adjust for time-sensitive operations
        if context.get('time_critical', False):
            adjusted = max(adjusted, 0.4)  # Minimum confidence for time-sensitive tasks
        
        return adjusted
    
    # Removed _determine_level since we now determine the level directly in score_execution
    
    def _generate_reasoning(self, 
                          intent: str,
                          has_llm_plan: bool,
                          has_fallback_plan: bool,
                          context: Dict[str, Any],
                          confidence: float) -> list[str]:
        """Generate human-readable reasoning for confidence score."""
        reasoning = []
        
        if has_llm_plan and confidence > 0.7:
            reasoning.append("LLM plan available and intent is clear")
        elif has_fallback_plan:
            reasoning.append("Fallback plan available as safety net")
        else:
            reasoning.append("No viable execution plan available")
        
        if confidence < 0.3:
            reasoning.append("Low confidence due to unclear intent or missing plan")
        
        # Check for specific intent characteristics
        intent_lower = intent.lower()
        
        # Indicate if we're dealing with a critical operation
        critical_ops = ['delete', 'remove', 'format', 'destroy', 'kill']
        if any(op in intent_lower for op in critical_ops):
            reasoning.append("Critical operation detected")
        
        # Indicate if we have helpful context
        if context.get('file_path') or context.get('target_object'):
            reasoning.append("Specific target identified in context")
        
        # Indicate if we have plan specificity information
        if context.get('plan_steps'):
            try:
                steps = int(context['plan_steps'])
                if steps > 10:
                    reasoning.append("Plan has excessive number of steps")
                elif steps < 2:
                    reasoning.append("Plan has insufficient number of steps")
            except ValueError:
                pass  # Skip if plan_steps isn't a number
        
        # Add information about context factors
        if context.get('safety_mode', False):
            reasoning.append("Safety mode is active")
        
        if context.get('time_critical', False):
            reasoning.append("Operation is time-sensitive")
        
        return reasoning
    
    # Removed _make_decisions since we now make decisions directly in score_execution
    
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
    
    # Kept as is since it's not directly related to plan reliability evaluation


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
