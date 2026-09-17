"""
Reasoning Quality Evaluator

Assesses the quality of Tiannara's reasoning processes, including:
- Logical consistency
- Evidence coverage
- Bias detection
- Confidence calibration
"""

from typing import Dict, List, Optional


class ReasoningQualityEvaluator:
    """Evaluates the quality of reasoning and decision-making."""
    
    def __init__(self):
        # Bias detection patterns
        self.bias_patterns = {
            'confirmation_bias': {
                'description': 'Favoring information that confirms existing beliefs',
                'indicators': ['selective_evidence', 'ignoring_contradictions']
            },
            'availability_heuristic': {
                'description': 'Overweighting readily available information',
                'indicators': ['recent_examples_dominant', 'lack_of_diverse_sources']
            },
            'anchoring_bias': {
                'description': 'Relying too heavily on first piece of information',
                'indicators': ['initial_estimate_persistent', 'insufficient_adjustment']
            },
            'overconfidence': {
                'description': 'Excessive confidence in predictions or conclusions',
                'indicators': ['high_confidence_low_accuracy', 'narrow_confidence_intervals']
            }
        }
    
    def evaluate_reasoning_quality(self, decision_trace: Dict) -> Dict:
        """
        Evaluate the quality of a reasoning process.
        
        Args:
            decision_trace: Dictionary containing:
                - question: The question being answered
                - hypotheses: List of hypotheses considered
                - evidence_used: Evidence referenced
                - conclusion: Final conclusion
                - confidence: Confidence level (0-1)
                - reasoning_steps: List of reasoning steps taken
        
        Returns:
            Quality assessment with scores and recommendations
        """
        assessment = {
            'logical_consistency': self._assess_logical_consistency(decision_trace),
            'evidence_coverage': self._assess_evidence_coverage(decision_trace),
            'bias_indicators': self._detect_biases(decision_trace),
            'confidence_calibration': self._assess_confidence_calibration(decision_trace),
            'overall_quality': 0.0,
            'recommendation': ''
        }
        
        # Calculate overall quality score
        scores = [
            assessment['logical_consistency']['score'],
            assessment['evidence_coverage']['score'],
            1.0 - len(assessment['bias_indicators']) * 0.2,  # Penalize for biases
            assessment['confidence_calibration']['score']
        ]
        
        assessment['overall_quality'] = round(sum(scores) / len(scores), 2)
        
        # Generate recommendation
        assessment['recommendation'] = self._generate_recommendation(assessment)
        
        return assessment
    
    def _assess_logical_consistency(self, trace: Dict) -> Dict:
        """Check if reasoning is logically consistent."""
        reasoning_steps = trace.get('reasoning_steps', [])
        
        if not reasoning_steps:
            return {
                'score': 0.5,
                'issues': ['No reasoning steps provided'],
                'strengths': []
            }
        
        issues = []
        strengths = []
        
        # Check for contradictions
        for i, step in enumerate(reasoning_steps):
            for j, other_step in enumerate(reasoning_steps[i+1:], i+1):
                if self._are_contradictory(step, other_step):
                    issues.append(f"Contradiction between steps {i+1} and {j+1}")
        
        # Check for logical flow
        if len(reasoning_steps) > 1:
            strengths.append("Multi-step reasoning demonstrated")
        
        # Check for fallacies (simplified)
        if any('assume' in step.lower() for step in reasoning_steps):
            issues.append("Potential unsupported assumptions")
        
        score = max(0.0, min(1.0, 1.0 - len(issues) * 0.2))
        
        return {
            'score': round(score, 2),
            'issues': issues,
            'strengths': strengths
        }
    
    def _assess_evidence_coverage(self, trace: Dict) -> Dict:
        """Assess how well evidence supports the conclusion."""
        evidence_used = trace.get('evidence_used', [])
        hypotheses = trace.get('hypotheses', [])
        
        if not evidence_used:
            return {
                'score': 0.3,
                'issues': ['No evidence cited'],
                'strengths': []
            }
        
        issues = []
        strengths = []
        
        # Check evidence diversity
        evidence_types = set()
        for ev in evidence_used:
            if isinstance(ev, dict):
                evidence_types.add(ev.get('type', 'unknown'))
            else:
                evidence_types.add('text')
        
        if len(evidence_types) >= 3:
            strengths.append("Diverse evidence sources used")
        elif len(evidence_types) == 1:
            issues.append("Limited evidence diversity")
        
        # Check if evidence addresses all hypotheses
        if hypotheses and len(evidence_used) < len(hypotheses):
            issues.append("Insufficient evidence for number of hypotheses")
        
        score = max(0.0, min(1.0, 0.5 + len(evidence_types) * 0.15 - len(issues) * 0.2))
        
        return {
            'score': round(score, 2),
            'issues': issues,
            'strengths': strengths
        }
    
    def _detect_biases(self, trace: Dict) -> List[Dict]:
        """Detect cognitive biases in reasoning."""
        detected_biases = []
        
        # Check for confirmation bias
        if self._check_confirmation_bias(trace):
            detected_biases.append({
                'bias_type': 'confirmation_bias',
                'severity': 'medium',
                'description': self.bias_patterns['confirmation_bias']['description'],
                'evidence': self._get_bias_evidence(trace, 'confirmation_bias')
            })
        
        # Check for overconfidence
        confidence = trace.get('confidence', 0.5)
        if confidence > 0.9 and trace.get('actual_accuracy', 1.0) < 0.7:
            detected_biases.append({
                'bias_type': 'overconfidence',
                'severity': 'high',
                'description': self.bias_patterns['overconfidence']['description'],
                'evidence': f"Confidence {confidence} but accuracy suggests lower confidence warranted"
            })
        
        return detected_biases
    
    def _assess_confidence_calibration(self, trace: Dict) -> Dict:
        """Assess if confidence levels match actual performance."""
        stated_confidence = trace.get('confidence', 0.5)
        actual_accuracy = trace.get('actual_accuracy', None)
        
        if actual_accuracy is None:
            return {
                'score': 0.7,
                'status': 'unknown',
                'message': 'Cannot assess without actual accuracy data'
            }
        
        # Calculate calibration error
        calibration_error = abs(stated_confidence - actual_accuracy)
        
        if calibration_error < 0.1:
            status = 'well_calibrated'
            score = 0.95
        elif calibration_error < 0.2:
            status = 'reasonably_calibrated'
            score = 0.8
        elif calibration_error < 0.3:
            status = 'somewhat_miscalibrated'
            score = 0.6
        else:
            status = 'poorly_calibrated'
            score = 0.4
        
        direction = 'overconfident' if stated_confidence > actual_accuracy else 'underconfident'
        
        return {
            'score': round(score, 2),
            'status': status,
            'calibration_error': round(calibration_error, 2),
            'direction': direction,
            'stated_confidence': stated_confidence,
            'actual_accuracy': actual_accuracy
        }
    
    def _check_confirmation_bias(self, trace: Dict) -> bool:
        """Simple check for confirmation bias indicators."""
        hypotheses = trace.get('hypotheses', [])
        evidence_used = trace.get('evidence_used', [])
        
        # If only one hypothesis and all evidence supports it, potential confirmation bias
        if len(hypotheses) == 1 and len(evidence_used) > 0:
            # Check if any contradictory evidence was ignored
            return True  # Simplified - would need more sophisticated analysis
        
        return False
    
    def _get_bias_evidence(self, trace: Dict, bias_type: str) -> str:
        """Get evidence supporting bias detection."""
        return "Pattern detected in reasoning structure"
    
    def _are_contradictory(self, step1: str, step2: str) -> bool:
        """Check if two reasoning steps contradict each other."""
        # Simplified contradiction detection
        contradiction_pairs = [
            ('increase', 'decrease'),
            ('always', 'never'),
            ('all', 'none'),
            ('true', 'false')
        ]
        
        step1_lower = step1.lower()
        step2_lower = step2.lower()
        
        for word1, word2 in contradiction_pairs:
            if word1 in step1_lower and word2 in step2_lower:
                return True
            if word2 in step1_lower and word1 in step2_lower:
                return True
        
        return False
    
    def _generate_recommendation(self, assessment: Dict) -> str:
        """Generate actionable recommendation based on assessment."""
        if assessment['overall_quality'] >= 0.9:
            return "Excellent reasoning quality - continue current approach"
        elif assessment['overall_quality'] >= 0.7:
            return "Good reasoning quality - minor improvements possible"
        elif assessment['overall_quality'] >= 0.5:
            issues = []
            if assessment['logical_consistency']['score'] < 0.7:
                issues.append("improve logical consistency")
            if assessment['evidence_coverage']['score'] < 0.7:
                issues.append("expand evidence base")
            if assessment['bias_indicators']:
                issues.append("address cognitive biases")
            
            return f"Moderate quality - consider: {', '.join(issues)}"
        else:
            return "Low quality - significant improvement needed in reasoning process"
