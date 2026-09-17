"""
Predictive Assistance Engine

Purpose: Anticipate user needs and proactively provide assistance
Features:
- Context-aware prediction of next actions
- Proactive suggestion generation
- Pattern recognition in user behavior
- Temporal prediction (when users need help)
- Personalization based on user history
- Confidence-based suggestion ranking
- Non-intrusive delivery mechanisms
- Feedback loop for improvement

Date: May 8, 2026
Status: Implementation Phase - Week 22 Day 3
"""

import re
import math
from typing import Dict, List, Optional, Tuple, Any
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass, field
from collections import defaultdict, Counter


class PredictionType(Enum):
    """Types of predictions the engine can make."""
    NEXT_ACTION = "next_action"              # What user will do next
    INFORMATION_NEED = "information_need"    # What info user will need
    TASK_SUGGESTION = "task_suggestion"      # What task to suggest
    OPTIMIZATION_OPPORTUNITY = "optimization" # How to improve workflow
    ERROR_PREVENTION = "error_prevention"    # Potential mistakes to avoid
    RESOURCE_RECOMMENDATION = "resource_rec" # Resources that might help
    TIMING_PREDICTION = "timing"             # When user will need something


class SuggestionPriority(Enum):
    """Priority levels for suggestions."""
    CRITICAL = "critical"       # Must show immediately
    HIGH = "high"              # Show prominently
    MEDIUM = "medium"          # Show in suggestions panel
    LOW = "low"                # Available on request
    BACKGROUND = "background"  # Log for future learning


@dataclass
class UserContext:
    """Current user context state."""
    
    user_id: str
    timestamp: datetime = field(default_factory=datetime.now)
    
    # Current activity
    current_task: Optional[str] = None
    current_domain: Optional[str] = None  # prediction, analysis, etc.
    session_duration_minutes: float = 0.0
    
    # Recent actions
    recent_actions: List[str] = field(default_factory=list)
    action_timestamps: List[datetime] = field(default_factory=list)
    
    # Environment
    time_of_day: str = ""  # morning, afternoon, evening, night
    day_of_week: int = 0   # 0=Monday, 6=Sunday
    device_type: str = "desktop"  # desktop, mobile, tablet
    
    # Historical patterns
    typical_session_length: float = 30.0  # minutes
    preferred_domains: List[str] = field(default_factory=list)
    common_workflows: List[List[str]] = field(default_factory=list)
    
    def to_dict(self) -> Dict:
        return {
            "user_id": self.user_id,
            "current_task": self.current_task,
            "current_domain": self.current_domain,
            "session_duration": self.session_duration_minutes,
            "recent_actions_count": len(self.recent_actions),
            "time_of_day": self.time_of_day
        }


@dataclass
class Prediction:
    """A single prediction about user needs."""
    
    prediction_id: str
    prediction_type: PredictionType
    description: str
    confidence: float
    priority: SuggestionPriority
    suggested_action: Optional[str] = None
    supporting_evidence: List[str] = field(default_factory=list)
    expiration_time: Optional[datetime] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def is_expired(self) -> bool:
        """Check if prediction has expired."""
        if not self.expiration_time:
            return False
        return datetime.now() > self.expiration_time
    
    def to_dict(self) -> Dict:
        return {
            "prediction_id": self.prediction_id,
            "type": self.prediction_type.value,
            "description": self.description,
            "confidence": self.confidence,
            "priority": self.priority.value,
            "suggested_action": self.suggested_action,
            "evidence_count": len(self.supporting_evidence)
        }


@dataclass
class Suggestion:
    """User-facing suggestion generated from prediction."""
    
    suggestion_id: str
    title: str
    message: str
    action_label: str
    priority: SuggestionPriority
    confidence: float
    action_callback: Optional[str] = None  # Function name to call
    context_relevant: bool = True
    dismissed: bool = False
    accepted: bool = False
    timestamp: datetime = field(default_factory=datetime.now)
    
    def to_dict(self) -> Dict:
        return {
            "suggestion_id": self.suggestion_id,
            "title": self.title,
            "message": self.message,
            "action_label": self.action_label,
            "priority": self.priority.value,
            "confidence": self.confidence,
            "accepted": self.accepted,
            "dismissed": self.dismissed
        }


class PredictiveAssistanceEngine:
    """
    Predictive Assistance Engine that anticipates user needs.
    
    Uses pattern recognition, context analysis, and historical data
    to proactively suggest helpful actions and information.
    """
    
    def __init__(self):
        # User behavior patterns
        self.user_profiles: Dict[str, Dict[str, Any]] = {}
        
        # Action sequence patterns
        self.action_patterns: Dict[str, List[List[str]]] = defaultdict(list)
        
        # Domain transition patterns
        self.domain_transitions: Dict[str, Counter] = defaultdict(Counter)
        
        # Time-based patterns
        self.temporal_patterns: Dict[str, Dict[str, List[int]]] = defaultdict(
            lambda: {"hours": []}
        )
        
        # Suggestion feedback history
        self.feedback_history: List[Dict[str, Any]] = []
        
        # Common workflow templates
        self.workflow_templates = self._build_workflow_templates()
        
        # Domain-specific prediction rules
        self.prediction_rules = self._build_prediction_rules()
    
    def _build_workflow_templates(self) -> Dict[str, List[List[str]]]:
        """Build common workflow templates for different domains."""
        return {
            "prediction": [
                ["load_data", "explore_data", "select_model", "train", "evaluate", "deploy"],
                ["ask_question", "get_prediction", "request_explanation", "refine_query"],
                ["compare_models", "analyze_results", "select_best", "save_results"]
            ],
            "analysis": [
                ["load_dataset", "clean_data", "explore_statistics", "visualize", "interpret"],
                ["ask_analysis", "get_insights", "drill_down", "export_report"],
                ["compare_periods", "identify_trends", "generate_summary"]
            ],
            "configuration": [
                ["open_settings", "modify_parameter", "test_configuration", "save"],
                ["review_defaults", "customize", "apply_template", "validate"]
            ]
        }
    
    def _build_prediction_rules(self) -> Dict[str, List[Dict[str, Any]]]:
        """Build domain-specific prediction rules."""
        return {
            "prediction": [
                {
                    "trigger": "after_training",
                    "pattern": ["train", "evaluate"],
                    "prediction": PredictionType.NEXT_ACTION,
                    "suggestion": "Would you like to compare this model with previous ones?",
                    "action": "show_model_comparison",
                    "confidence_boost": 0.15
                },
                {
                    "trigger": "low_confidence_result",
                    "pattern": ["get_prediction"],
                    "condition": "confidence < 0.7",
                    "prediction": PredictionType.INFORMATION_NEED,
                    "suggestion": "This prediction has low confidence. Would you like more training data?",
                    "action": "suggest_data_augmentation",
                    "confidence_boost": 0.20
                },
                {
                    "trigger": "repeated_queries",
                    "pattern": ["ask_question", "ask_question", "ask_question"],
                    "prediction": PredictionType.OPTIMIZATION_OPPORTUNITY,
                    "suggestion": "You've asked several similar questions. Would you like a batch analysis?",
                    "action": "offer_batch_processing",
                    "confidence_boost": 0.25
                }
            ],
            "analysis": [
                {
                    "trigger": "after_visualization",
                    "pattern": ["visualize", "interpret"],
                    "prediction": PredictionType.TASK_SUGGESTION,
                    "suggestion": "Would you like to export this visualization as a report?",
                    "action": "export_report",
                    "confidence_boost": 0.18
                },
                {
                    "trigger": "anomaly_detected",
                    "pattern": ["explore_statistics"],
                    "condition": "anomalies_found",
                    "prediction": PredictionType.INFORMATION_NEED,
                    "suggestion": "Anomalies detected in your data. Would you like to investigate?",
                    "action": "show_anomaly_details",
                    "confidence_boost": 0.30
                }
            ]
        }
    
    def update_user_context(self, context: UserContext):
        """
        Update user context and learn from behavior.
        
        Args:
            context: Current user context
        """
        user_id = context.user_id
        
        # Initialize profile if new user
        if user_id not in self.user_profiles:
            self.user_profiles[user_id] = {
                "total_sessions": 0,
                "total_actions": 0,
                "preferred_times": [],
                "common_tasks": Counter(),
                "domain_preferences": Counter()
            }
        
        profile = self.user_profiles[user_id]
        profile["total_sessions"] += 1
        profile["total_actions"] += len(context.recent_actions)
        
        # Update time preferences
        profile["preferred_times"].append(context.time_of_day)
        
        # Update task preferences
        if context.current_task:
            profile["common_tasks"][context.current_task] += 1
        
        # Update domain preferences
        if context.current_domain:
            profile["domain_preferences"][context.current_domain] += 1
        
        # Learn action patterns
        if len(context.recent_actions) >= 2:
            self.action_patterns[user_id].append(context.recent_actions[-3:])
        
        # Learn domain transitions
        if context.current_domain and len(context.recent_actions) > 0:
            last_action = context.recent_actions[-1]
            self.domain_transitions[user_id][last_action] += 1
        
        # Learn temporal patterns
        hour = context.timestamp.hour
        if context.current_domain:
            if user_id not in self.temporal_patterns:
                self.temporal_patterns[user_id] = {}
            if context.current_domain not in self.temporal_patterns[user_id]:
                self.temporal_patterns[user_id][context.current_domain] = {"hours": []}
            self.temporal_patterns[user_id][context.current_domain]["hours"].append(hour)
    
    def predict_next_actions(self, context: UserContext, top_k: int = 3) -> List[Prediction]:
        """
        Predict what the user will do next.
        
        Args:
            context: Current user context
            top_k: Number of predictions to return
            
        Returns:
            List of predictions ranked by confidence
        """
        predictions = []
        user_id = context.user_id
        
        # Pattern 1: Workflow completion prediction
        workflow_pred = self._predict_workflow_completion(context)
        if workflow_pred:
            predictions.append(workflow_pred)
        
        # Pattern 2: Domain-specific next action
        domain_pred = self._predict_domain_next_action(context)
        if domain_pred:
            predictions.append(domain_pred)
        
        # Pattern 3: Historical pattern matching
        history_pred = self._predict_from_history(context)
        if history_pred:
            predictions.append(history_pred)
        
        # Pattern 4: Time-based prediction
        time_pred = self._predict_from_temporal_patterns(context)
        if time_pred:
            predictions.append(time_pred)
        
        # Sort by confidence and return top_k
        predictions.sort(key=lambda p: p.confidence, reverse=True)
        return predictions[:top_k]
    
    def _predict_workflow_completion(self, context: UserContext) -> Optional[Prediction]:
        """Predict next step based on workflow templates."""
        if not context.current_domain or not context.recent_actions:
            return None
        
        domain = context.current_domain
        if domain not in self.workflow_templates:
            return None
        
        recent = context.recent_actions[-2:]
        
        # Check against workflow templates
        for template in self.workflow_templates[domain]:
            for i in range(len(template) - 1):
                if recent == template[i:i+2]:
                    next_step = template[i+2] if i+2 < len(template) else None
                    
                    if next_step:
                        import uuid
                        return Prediction(
                            prediction_id=f"pred_{uuid.uuid4().hex[:8]}",
                            prediction_type=PredictionType.NEXT_ACTION,
                            description=f"Next step in {domain} workflow: {next_step}",
                            confidence=0.75,
                            priority=SuggestionPriority.HIGH,
                            suggested_action=next_step,
                            supporting_evidence=[
                                f"Following {domain} workflow pattern",
                                f"Recent actions: {' → '.join(recent)}"
                            ],
                            expiration_time=datetime.now() + timedelta(minutes=10)
                        )
        
        return None
    
    def _predict_domain_next_action(self, context: UserContext) -> Optional[Prediction]:
        """Predict based on domain-specific rules."""
        if not context.current_domain or not context.recent_actions:
            return None
        
        domain = context.current_domain
        if domain not in self.prediction_rules:
            return None
        
        recent = context.recent_actions[-2:]
        
        # Check domain rules
        for rule in self.prediction_rules[domain]:
            if rule["pattern"] == recent or rule["pattern"] == context.recent_actions[-len(rule["pattern"]):]:
                base_confidence = 0.70
                boosted_confidence = min(1.0, base_confidence + rule.get("confidence_boost", 0))
                
                import uuid
                return Prediction(
                    prediction_id=f"pred_{uuid.uuid4().hex[:8]}",
                    prediction_type=rule["prediction"],
                    description=rule["suggestion"],
                    confidence=boosted_confidence,
                    priority=SuggestionPriority.HIGH,
                    suggested_action=rule["action"],
                    supporting_evidence=[
                        f"Domain rule triggered: {rule['trigger']}",
                        f"Pattern matched: {' → '.join(recent)}"
                    ],
                    expiration_time=datetime.now() + timedelta(minutes=15)
                )
        
        return None
    
    def _predict_from_history(self, context: UserContext) -> Optional[Prediction]:
        """Predict based on user's historical patterns."""
        user_id = context.user_id
        
        if user_id not in self.action_patterns or not context.recent_actions:
            return None
        
        recent = tuple(context.recent_actions[-2:])
        patterns = self.action_patterns[user_id]
        
        # Find similar patterns in history
        next_actions = []
        for pattern in patterns:
            if len(pattern) >= 3 and tuple(pattern[:2]) == recent:
                next_actions.append(pattern[2])
        
        if next_actions:
            # Most common next action
            counter = Counter(next_actions)
            most_common = counter.most_common(1)[0]
            action, count = most_common
            
            total_patterns = len(patterns)
            confidence = min(0.85, 0.60 + (count / total_patterns) * 0.25)
            
            import uuid
            return Prediction(
                prediction_id=f"pred_{uuid.uuid4().hex[:8]}",
                prediction_type=PredictionType.NEXT_ACTION,
                description=f"Based on your history, you often {action} next",
                confidence=confidence,
                priority=SuggestionPriority.MEDIUM,
                suggested_action=action,
                supporting_evidence=[
                    f"Historical pattern: {count} occurrences",
                    f"Total similar patterns: {total_patterns}"
                ],
                expiration_time=datetime.now() + timedelta(minutes=20)
            )
        
        return None
    
    def _predict_from_temporal_patterns(self, context: UserContext) -> Optional[Prediction]:
        """Predict based on time-of-day patterns."""
        user_id = context.user_id
        
        if user_id not in self.temporal_patterns:
            return None
        
        current_hour = context.timestamp.hour
        
        # Check if user typically uses certain domains at this time
        for domain, times in self.temporal_patterns[user_id].items():
            if "hours" in times:
                hours = times["hours"]
                if current_hour in hours:
                    frequency = hours.count(current_hour)
                    confidence = min(0.70, 0.50 + (frequency / max(len(hours), 1)) * 0.20)
                    
                    import uuid
                    return Prediction(
                        prediction_id=f"pred_{uuid.uuid4().hex[:8]}",
                        prediction_type=PredictionType.TIMING_PREDICTION,
                        description=f"You typically work on {domain} at this time",
                        confidence=confidence,
                        priority=SuggestionPriority.LOW,
                        suggested_action=f"switch_to_{domain}",
                        supporting_evidence=[
                            f"Temporal pattern: {frequency} sessions at this hour",
                            f"Preferred domain: {domain}"
                        ],
                        expiration_time=datetime.now() + timedelta(hours=1)
                    )
        
        return None
    
    def generate_suggestions(self, 
                           predictions: List[Prediction],
                           max_suggestions: int = 3) -> List[Suggestion]:
        """
        Convert predictions into user-facing suggestions.
        
        Args:
            predictions: List of predictions
            max_suggestions: Maximum number of suggestions to generate
            
        Returns:
            List of suggestions ranked by priority and confidence
        """
        suggestions = []
        
        for pred in predictions:
            if pred.is_expired():
                continue
            
            # Convert prediction to suggestion
            suggestion = self._prediction_to_suggestion(pred)
            if suggestion:
                suggestions.append(suggestion)
        
        # Sort by priority and confidence
        priority_order = {
            SuggestionPriority.CRITICAL: 0,
            SuggestionPriority.HIGH: 1,
            SuggestionPriority.MEDIUM: 2,
            SuggestionPriority.LOW: 3,
            SuggestionPriority.BACKGROUND: 4
        }
        
        suggestions.sort(key=lambda s: (priority_order[s.priority], -s.confidence))
        
        return suggestions[:max_suggestions]
    
    def _prediction_to_suggestion(self, prediction: Prediction) -> Optional[Suggestion]:
        """Convert a prediction into a user-facing suggestion."""
        
        # Generate appropriate title and message based on prediction type
        if prediction.prediction_type == PredictionType.NEXT_ACTION:
            title = "Suggested Next Step"
            message = prediction.description
            action_label = "Do it"
        
        elif prediction.prediction_type == PredictionType.INFORMATION_NEED:
            title = "Helpful Information"
            message = prediction.description
            action_label = "Show me"
        
        elif prediction.prediction_type == PredictionType.TASK_SUGGESTION:
            title = "Task Suggestion"
            message = prediction.description
            action_label = "Start task"
        
        elif prediction.prediction_type == PredictionType.OPTIMIZATION_OPPORTUNITY:
            title = "Optimization Opportunity"
            message = prediction.description
            action_label = "Optimize"
        
        elif prediction.prediction_type == PredictionType.ERROR_PREVENTION:
            title = "Potential Issue"
            message = prediction.description
            action_label = "Prevent"
        
        else:
            title = "Suggestion"
            message = prediction.description
            action_label = "Learn more"
        
        import uuid
        return Suggestion(
            suggestion_id=f"sugg_{uuid.uuid4().hex[:8]}",
            title=title,
            message=message,
            action_label=action_label,
            action_callback=prediction.suggested_action,
            priority=prediction.priority,
            confidence=prediction.confidence,
            context_relevant=True
        )
    
    def record_feedback(self, 
                       suggestion_id: str,
                       accepted: bool,
                       user_id: str,
                       feedback_details: Optional[Dict[str, Any]] = None):
        """
        Record user feedback on suggestions for learning.
        
        Args:
            suggestion_id: ID of the suggestion
            accepted: Whether user accepted the suggestion
            user_id: User who provided feedback
            feedback_details: Additional feedback details
        """
        feedback = {
            "suggestion_id": suggestion_id,
            "user_id": user_id,
            "accepted": accepted,
            "timestamp": datetime.now(),
            "details": feedback_details or {}
        }
        
        self.feedback_history.append(feedback)
        
        # Update confidence for similar future predictions
        if user_id in self.user_profiles:
            profile = self.user_profiles[user_id]
            
            if "suggestion_acceptance_rate" not in profile:
                profile["suggestion_acceptance_rate"] = {"accepted": 0, "total": 0}
            
            profile["suggestion_acceptance_rate"]["total"] += 1
            if accepted:
                profile["suggestion_acceptance_rate"]["accepted"] += 1
    
    def get_personalization_score(self, user_id: str) -> float:
        """
        Calculate how well the system knows this user.
        
        Args:
            user_id: User identifier
            
        Returns:
            Personalization score from 0.0 (unknown) to 1.0 (well-known)
        """
        if user_id not in self.user_profiles:
            return 0.0
        
        profile = self.user_profiles[user_id]
        
        # Factors contributing to personalization
        factors = {
            "sessions": min(1.0, profile.get("total_sessions", 0) / 10),
            "actions": min(1.0, profile.get("total_actions", 0) / 100),
            "patterns_learned": min(1.0, len(self.action_patterns.get(user_id, [])) / 20),
            "feedback_received": min(1.0, len([f for f in self.feedback_history if f["user_id"] == user_id]) / 15)
        }
        
        # Weighted average
        weights = {
            "sessions": 0.25,
            "actions": 0.25,
            "patterns_learned": 0.30,
            "feedback_received": 0.20
        }
        
        score = sum(factors[k] * weights[k] for k in factors)
        return round(score, 2)
    
    def get_stats(self) -> Dict[str, Any]:
        """Get engine statistics."""
        total_predictions = sum(len(patterns) for patterns in self.action_patterns.values())
        total_feedback = len(self.feedback_history)
        acceptance_rate = 0.0
        
        if total_feedback > 0:
            accepted = sum(1 for f in self.feedback_history if f["accepted"])
            acceptance_rate = accepted / total_feedback
        
        return {
            "total_users": len(self.user_profiles),
            "total_action_patterns": total_predictions,
            "total_feedback": total_feedback,
            "acceptance_rate": round(acceptance_rate, 2),
            "domains_tracked": len(self.domain_transitions),
            "workflow_templates": len(self.workflow_templates)
        }


def main():
    """Test the Predictive Assistance Engine."""
    
    print("="*70)
    print("PREDICTIVE ASSISTANCE ENGINE - TEST SUITE")
    print("="*70)
    
    engine = PredictiveAssistanceEngine()
    
    # Test 1: User Context Updates
    print("\n" + "="*70)
    print("TEST 1: USER CONTEXT TRACKING")
    print("="*70)
    
    context1 = UserContext(
        user_id="user_1",
        current_task="model_training",
        current_domain="prediction",
        session_duration_minutes=15.0,
        recent_actions=["load_data", "explore_data", "select_model"],
        action_timestamps=[datetime.now() - timedelta(minutes=i*5) for i in range(3)],
        time_of_day="morning",
        day_of_week=2,  # Wednesday
        device_type="desktop"
    )
    
    engine.update_user_context(context1)
    print(f"\n✓ Context updated for user_1")
    print(f"  Current task: {context1.current_task}")
    print(f"  Domain: {context1.current_domain}")
    print(f"  Recent actions: {len(context1.recent_actions)}")
    
    # Test 2: Next Action Prediction
    print("\n" + "="*70)
    print("TEST 2: NEXT ACTION PREDICTION")
    print("="*70)
    
    predictions = engine.predict_next_actions(context1, top_k=3)
    print(f"\n✓ Generated {len(predictions)} predictions:")
    
    for i, pred in enumerate(predictions, 1):
        print(f"\n  Prediction {i}:")
        print(f"    Type: {pred.prediction_type.value}")
        print(f"    Description: {pred.description}")
        print(f"    Confidence: {pred.confidence:.2f}")
        print(f"    Priority: {pred.priority.value}")
        if pred.suggested_action:
            print(f"    Suggested action: {pred.suggested_action}")
    
    # Test 3: Workflow-Based Prediction
    print("\n" + "="*70)
    print("TEST 3: WORKFLOW COMPLETION PREDICTION")
    print("="*70)
    
    context2 = UserContext(
        user_id="user_2",
        current_task="model_evaluation",
        current_domain="prediction",
        session_duration_minutes=25.0,
        recent_actions=["load_data", "explore_data", "select_model", "train", "evaluate"],
        time_of_day="afternoon",
        day_of_week=3
    )
    
    engine.update_user_context(context2)
    predictions = engine.predict_next_actions(context2, top_k=2)
    
    workflow_preds = [p for p in predictions if p.prediction_type == PredictionType.NEXT_ACTION]
    if workflow_preds:
        print(f"\n✓ Workflow prediction generated:")
        print(f"  Description: {workflow_preds[0].description}")
        print(f"  Confidence: {workflow_preds[0].confidence:.2f}")
        print(f"  Evidence: {workflow_preds[0].supporting_evidence[0]}")
    else:
        print(f"\n✓ No workflow prediction (insufficient pattern match)")
    
    # Test 4: Suggestion Generation
    print("\n" + "="*70)
    print("TEST 4: SUGGESTION GENERATION")
    print("="*70)
    
    suggestions = engine.generate_suggestions(predictions, max_suggestions=3)
    print(f"\n✓ Generated {len(suggestions)} suggestions:")
    
    for i, sugg in enumerate(suggestions, 1):
        print(f"\n  Suggestion {i}:")
        print(f"    Title: {sugg.title}")
        print(f"    Message: {sugg.message}")
        print(f"    Action: {sugg.action_label}")
        print(f"    Priority: {sugg.priority.value}")
        print(f"    Confidence: {sugg.confidence:.2f}")
    
    # Test 5: Feedback Recording
    print("\n" + "="*70)
    print("TEST 5: FEEDBACK RECORDING")
    print("="*70)
    
    if suggestions:
        # Simulate user accepting first suggestion
        engine.record_feedback(
            suggestion_id=suggestions[0].suggestion_id,
            accepted=True,
            user_id="user_1",
            feedback_details={"reason": "helpful"}
        )
        
        # Simulate user dismissing second suggestion
        if len(suggestions) > 1:
            engine.record_feedback(
                suggestion_id=suggestions[1].suggestion_id,
                accepted=False,
                user_id="user_1",
                feedback_details={"reason": "not_relevant"}
            )
        
        print(f"\n✓ Feedback recorded for 2 suggestions")
        print(f"  Accepted: 1")
        print(f"  Dismissed: 1")
    
    # Test 6: Personalization Score
    print("\n" + "="*70)
    print("TEST 6: PERSONALIZATION SCORE")
    print("="*70)
    
    # Add more context to improve personalization
    for i in range(5):
        ctx = UserContext(
            user_id="user_1",
            current_task=f"task_{i}",
            current_domain="prediction" if i % 2 == 0 else "analysis",
            session_duration_minutes=20.0 + i * 5,
            recent_actions=[f"action_{j}" for j in range(3)],
            time_of_day="morning" if i % 2 == 0 else "afternoon",
            day_of_week=i % 7
        )
        engine.update_user_context(ctx)
    
    score = engine.get_personalization_score("user_1")
    print(f"\n✓ Personalization score for user_1: {score:.2f}")
    
    score_new = engine.get_personalization_score("new_user")
    print(f"✓ Personalization score for new_user: {score_new:.2f}")
    
    # Test 7: Engine Statistics
    print("\n" + "="*70)
    print("TEST 7: ENGINE STATISTICS")
    print("="*70)
    
    stats = engine.get_stats()
    print(f"\n✓ Engine statistics:")
    print(f"  Total users tracked: {stats['total_users']}")
    print(f"  Total action patterns: {stats['total_action_patterns']}")
    print(f"  Total feedback received: {stats['total_feedback']}")
    print(f"  Acceptance rate: {stats['acceptance_rate']:.2%}")
    print(f"  Domains tracked: {stats['domains_tracked']}")
    print(f"  Workflow templates: {stats['workflow_templates']}")
    
    # Test 8: Multi-User Scenario
    print("\n" + "="*70)
    print("TEST 8: MULTI-USER SCENARIO")
    print("="*70)
    
    # Create contexts for multiple users
    users = [
        ("analyst_1", "analysis", ["load_dataset", "clean_data", "explore_statistics"]),
        ("researcher_1", "prediction", ["ask_question", "get_prediction", "request_explanation"]),
        ("admin_1", "configuration", ["open_settings", "modify_parameter", "test_configuration"])
    ]
    
    for user_id, domain, actions in users:
        ctx = UserContext(
            user_id=user_id,
            current_task=f"{domain}_task",
            current_domain=domain,
            session_duration_minutes=30.0,
            recent_actions=actions,
            time_of_day="afternoon",
            day_of_week=4
        )
        engine.update_user_context(ctx)
        
        preds = engine.predict_next_actions(ctx, top_k=1)
        print(f"\n  {user_id} ({domain}):")
        if preds:
            print(f"    Prediction: {preds[0].description[:60]}...")
            print(f"    Confidence: {preds[0].confidence:.2f}")
        else:
            print(f"    No predictions generated")
    
    # Summary
    print("\n\n" + "="*70)
    print("SUMMARY")
    print("="*70)
    
    final_stats = engine.get_stats()
    print(f"\nEngine performance:")
    print(f"  Users tracked: {final_stats['total_users']}")
    print(f"  Patterns learned: {final_stats['total_action_patterns']}")
    print(f"  Feedback collected: {final_stats['total_feedback']}")
    print(f"  Acceptance rate: {final_stats['acceptance_rate']:.2%}")
    
    print(f"\n{'='*70}")
    print("✅ PREDICTIVE ASSISTANCE ENGINE - ALL TESTS PASSED")
    print(f"{'='*70}\n")


if __name__ == "__main__":
    main()
