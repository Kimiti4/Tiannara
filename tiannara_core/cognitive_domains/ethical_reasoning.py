"""
Ethical Reasoning Domain - Safety and Alignment

Ensures safe and ethical AI behavior:
- Moral decision-making frameworks
- Bias detection and mitigation
- Safety constraint enforcement
- Ethical impact assessment
- Alignment with human values
"""

from typing import Dict, List, Optional, Tuple
from datetime import datetime
from enum import Enum


class EthicalPrinciple(Enum):
    """Core ethical principles."""
    BENEFICENCE = "beneficence"  # Do good
    NON_MALEFICENCE = "non_maleficence"  # Do no harm
    AUTONOMY = "autonomy"  # Respect user autonomy
    JUSTICE = "justice"  # Fairness and equity
    TRANSPARENCY = "transparency"  # Openness and explainability
    PRIVACY = "privacy"  # Protect user privacy
    ACCOUNTABILITY = "accountability"  # Take responsibility


class RiskLevel(Enum):
    """Risk assessment levels."""
    MINIMAL = "minimal"
    LOW = "low"
    MODERATE = "moderate"
    HIGH = "high"
    CRITICAL = "critical"


class EthicalConcern:
    """Represents an identified ethical concern."""
    
    def __init__(self, principle: EthicalPrinciple, description: str, 
                 severity: float, mitigation: str):
        self.principle = principle
        self.description = description
        self.severity = severity  # 0.0 to 1.0
        self.mitigation = mitigation
        self.timestamp = datetime.utcnow().isoformat()
    
    def to_dict(self) -> Dict:
        return {
            'principle': self.principle.value,
            'description': self.description,
            'severity': self.severity,
            'mitigation': self.mitigation,
            'timestamp': self.timestamp
        }


class EthicalReasoningEngine:
    """
    Engine for ethical reasoning and safety assurance.
    
    Features:
    - Ethical principle evaluation
    - Risk assessment and mitigation
    - Bias detection
    - Decision justification
    - Safety constraint enforcement
    """
    
    def __init__(self):
        self.ethical_guidelines = self._initialize_guidelines()
        self.decision_history = []
        self.concern_log = []
        self.safety_metrics = {
            'total_decisions': 0,
            'ethical_violations': 0,
            'bias_incidents': 0,
            'safety_interventions': 0
        }
    
    def _initialize_guidelines(self) -> Dict[EthicalPrinciple, List[str]]:
        """Initialize ethical guidelines for each principle."""
        return {
            EthicalPrinciple.BENEFICENCE: [
                "Maximize positive outcomes for users",
                "Provide helpful and accurate information",
                "Promote user well-being"
            ],
            EthicalPrinciple.NON_MALEFICENCE: [
                "Avoid causing harm or distress",
                "Prevent misuse of capabilities",
                "Flag potentially dangerous content"
            ],
            EthicalPrinciple.AUTONOMY: [
                "Respect user choices and preferences",
                "Provide options rather than mandates",
                "Enable informed decision-making"
            ],
            EthicalPrinciple.JUSTICE: [
                "Treat all users fairly and equitably",
                "Avoid discriminatory patterns",
                "Ensure balanced representation"
            ],
            EthicalPrinciple.TRANSPARENCY: [
                "Explain reasoning processes",
                "Disclose limitations and uncertainties",
                "Provide clear justifications"
            ],
            EthicalPrinciple.PRIVACY: [
                "Protect user data and confidentiality",
                "Minimize data collection",
                "Obtain consent for data usage"
            ],
            EthicalPrinciple.ACCOUNTABILITY: [
                "Take responsibility for outputs",
                "Acknowledge and correct errors",
                "Maintain audit trails"
            ]
        }
    
    def evaluate_decision(self, action: str, context: Dict, 
                         stakeholders: List[str]) -> Dict:
        """
        Evaluate the ethical implications of a proposed action.
        
        Args:
            action: Description of the proposed action
            context: Contextual information
            stakeholders: List of affected stakeholders
            
        Returns:
            Ethical evaluation with concerns and recommendations
        """
        concerns = []
        risk_assessment = self._assess_risk(action, context)
        
        # Check against each ethical principle
        for principle, guidelines in self.ethical_guidelines.items():
            principle_concerns = self._check_principle_violation(
                principle, action, context, guidelines
            )
            concerns.extend(principle_concerns)
        
        # Calculate overall ethical score
        if concerns:
            avg_severity = sum(c.severity for c in concerns) / len(concerns)
            ethical_score = max(0.0, 1.0 - avg_severity)
        else:
            ethical_score = 1.0
        
        # Generate recommendations
        recommendations = self._generate_recommendations(concerns, risk_assessment)
        
        # Record decision
        decision_record = {
            'action': action,
            'context': context,
            'stakeholders': stakeholders,
            'concerns': [c.to_dict() for c in concerns],
            'risk_level': risk_assessment['level'],
            'ethical_score': ethical_score,
            'recommendations': recommendations,
            'timestamp': datetime.utcnow().isoformat(),
            'approved': ethical_score >= 0.7 and risk_assessment['level'] != RiskLevel.CRITICAL
        }
        
        self.decision_history.append(decision_record)
        self.safety_metrics['total_decisions'] += 1
        
        if concerns:
            self.safety_metrics['ethical_violations'] += len(concerns)
            self.concern_log.extend(concerns)
        
        return decision_record
    
    def _assess_risk(self, action: str, context: Dict) -> Dict:
        """Assess the risk level of an action."""
        risk_keywords = {
            RiskLevel.CRITICAL: ['harm', 'dangerous', 'illegal', 'violent'],
            RiskLevel.HIGH: ['sensitive', 'private', 'discriminatory'],
            RiskLevel.MODERATE: ['controversial', 'uncertain', 'complex'],
            RiskLevel.LOW: ['routine', 'standard', 'common'],
            RiskLevel.MINIMAL: ['safe', 'benign', 'neutral']
        }
        
        action_lower = action.lower()
        
        for level, keywords in risk_keywords.items():
            if any(keyword in action_lower for keyword in keywords):
                return {'level': level, 'confidence': 0.8}
        
        return {'level': RiskLevel.LOW, 'confidence': 0.6}
    
    def _check_principle_violation(self, principle: EthicalPrinciple, 
                                   action: str, context: Dict,
                                   guidelines: List[str]) -> List[EthicalConcern]:
        """Check if action violates a specific ethical principle."""
        violations = []
        
        # Simplified violation detection (would use more sophisticated NLP in production)
        action_lower = action.lower()
        
        if principle == EthicalPrinciple.NON_MALEFICENCE:
            harm_keywords = [
                'harm', 'damage', 'hurt', 'kill', 'destroy', 'attack', 
                'weapon', 'violence', 'autonomous weapons', 'deploy weapons'
            ]
            if any(word in action_lower for word in harm_keywords):
                violations.append(EthicalConcern(
                    principle=principle,
                    description="Action may cause harm or involve weapons",
                    severity=0.9,
                    mitigation="Modify action to prevent potential harm and avoid weapon deployment"
                ))
        
        elif principle == EthicalPrinciple.PRIVACY:
            if any(word in action_lower for word in ['collect', 'share', 'expose']):
                if 'data' in action_lower or 'information' in action_lower:
                    violations.append(EthicalConcern(
                        principle=principle,
                        description="Action may compromise privacy",
                        severity=0.7,
                        mitigation="Ensure proper consent and data protection"
                    ))
        
        elif principle == EthicalPrinciple.JUSTICE:
            if any(word in action_lower for word in ['biased', 'unfair', 'discriminate']):
                violations.append(EthicalConcern(
                    principle=principle,
                    description="Action may be unfair or biased",
                    severity=0.75,
                    mitigation="Review for bias and ensure fairness"
                ))
        
        return violations
    
    def _generate_recommendations(self, concerns: List[EthicalConcern], 
                                 risk_assessment: Dict) -> List[str]:
        """Generate actionable recommendations based on concerns."""
        recommendations = []
        
        if not concerns:
            recommendations.append("Action appears ethically sound")
            return recommendations
        
        # Add mitigations from concerns
        for concern in concerns:
            recommendations.append(f"{concern.mitigation} (addresses {concern.principle.value})")
        
        # Add risk-based recommendations
        if risk_assessment['level'] in [RiskLevel.HIGH, RiskLevel.CRITICAL]:
            recommendations.append("Consider alternative approaches with lower risk")
            recommendations.append("Consult with ethics review board")
        
        return recommendations
    
    def detect_bias(self, content: str, context: Optional[Dict] = None) -> Dict:
        """Detect potential biases in content."""
        bias_indicators = {
            'gender_bias': ['he always', 'she never', 'men are', 'women are'],
            'racial_bias': ['they always', 'those people', 'their kind'],
            'age_bias': ['too old', 'too young', 'kids these days', 'back in my day'],
            'confirmation_bias': ['obviously', 'clearly', 'everyone knows']
        }
        
        detected_biases = []
        content_lower = content.lower()
        
        for bias_type, indicators in bias_indicators.items():
            if any(indicator in content_lower for indicator in indicators):
                detected_biases.append({
                    'type': bias_type,
                    'confidence': 0.6,
                    'examples': [i for i in indicators if i in content_lower]
                })
        
        if detected_biases:
            self.safety_metrics['bias_incidents'] += len(detected_biases)
        
        return {
            'content_analyzed': True,
            'biases_detected': detected_biases,
            'bias_count': len(detected_biases),
            'recommendation': "Review content for potential bias" if detected_biases else "No significant bias detected"
        }
    
    def get_ethical_report(self) -> Dict:
        """Generate comprehensive ethical reasoning report."""
        recent_decisions = self.decision_history[-10:]
        
        approval_rate = (
            sum(1 for d in recent_decisions if d.get('approved', False)) / 
            max(1, len(recent_decisions))
        )
        
        return {
            'metrics': self.safety_metrics,
            'recent_decisions': recent_decisions,
            'approval_rate': approval_rate,
            'active_concerns': len([c for c in self.concern_log[-20:]]),
            'ethical_framework': {p.value: len(g) for p, g in self.ethical_guidelines.items()}
        }
    
    def enforce_safety_constraints(self, action: str) -> Dict:
        """Enforce safety constraints on an action."""
        blocked_actions = [
            'harm', 'violence', 'illegal', 'exploit', 'manipulate'
        ]
        
        action_lower = action.lower()
        
        if any(blocked in action_lower for blocked in blocked_actions):
            self.safety_metrics['safety_interventions'] += 1
            return {
                'allowed': False,
                'reason': "Action violates safety constraints",
                'blocked_keywords': [b for b in blocked_actions if b in action_lower]
            }
        
        return {
            'allowed': True,
            'reason': "Action passes safety checks"
        }
