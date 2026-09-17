"""
Self-Reflection Cycle

Periodic self-assessment that reviews recent decisions,
identifies patterns in failures, and updates Tiannara's self-model.
"""

from typing import Dict, List, Optional
from datetime import datetime, timedelta


class SelfReflectionCycle:
    """Manages periodic self-assessment and improvement cycles."""
    
    def __init__(self, reflection_interval_minutes: int = 5):
        self.reflection_interval = timedelta(minutes=reflection_interval_minutes)
        self.last_reflection_time: Optional[datetime] = None
        
        # Reflection history
        self.reflection_history: List[Dict] = []
        
        # Self-model (Tiannara's understanding of its own capabilities)
        self.self_model = {
            'strengths': [],
            'weaknesses': [],
            'learning_rate': 0.0,
            'confidence_calibration': 'unknown',
            'last_updated': None
        }
    
    def should_reflect(self) -> bool:
        """Check if it's time for a reflection cycle."""
        if self.last_reflection_time is None:
            return True
        
        time_since_last = datetime.utcnow() - self.last_reflection_time
        return time_since_last >= self.reflection_interval
    
    def perform_reflection(self, recent_decisions: List[Dict], performance_data: Dict) -> Dict:
        """
        Perform a complete self-reflection cycle.
        
        Args:
            recent_decisions: List of recent decision traces
            performance_data: Performance metrics from all domains
        
        Returns:
            Reflection results with insights and recommendations
        """
        self.last_reflection_time = datetime.utcnow()
        
        reflection = {
            'timestamp': self._get_timestamp(),
            'decisions_reviewed': len(recent_decisions),
            'performance_summary': self._summarize_performance(performance_data),
            'patterns_identified': self._identify_patterns(recent_decisions),
            'failure_analysis': self._analyze_failures(recent_decisions),
            'self_model_updates': self._update_self_model(recent_decisions, performance_data),
            'improvement_recommendations': self._generate_improvements(recent_decisions, performance_data)
        }
        
        # Store in history
        self.reflection_history.append(reflection)
        
        # Keep only last 100 reflections
        if len(self.reflection_history) > 100:
            self.reflection_history = self.reflection_history[-100:]
        
        return reflection
    
    def _summarize_performance(self, performance_data: Dict) -> Dict:
        """Summarize overall performance across domains."""
        domains = performance_data.get('domains', {})
        
        total_success_rate = 0.0
        domain_count = 0
        declining_domains = []
        
        for domain_name, health in domains.items():
            success_rate = health.get('success_rate', 0.0)
            total_success_rate += success_rate
            domain_count += 1
            
            if health.get('trend') == 'declining':
                declining_domains.append(domain_name)
        
        avg_success_rate = total_success_rate / domain_count if domain_count > 0 else 0.0
        
        return {
            'average_success_rate': round(avg_success_rate, 2),
            'total_domains': domain_count,
            'declining_domains': declining_domains,
            'overall_trend': 'improving' if not declining_domains else 'mixed'
        }
    
    def _identify_patterns(self, decisions: List[Dict]) -> List[Dict]:
        """Identify recurring patterns in decision-making."""
        patterns = []
        
        # Analyze decision types
        decision_types = {}
        for decision in decisions:
            dtype = decision.get('type', 'unknown')
            if dtype not in decision_types:
                decision_types[dtype] = {'count': 0, 'success': 0}
            
            decision_types[dtype]['count'] += 1
            if decision.get('success', False):
                decision_types[dtype]['success'] += 1
        
        # Identify high-success patterns
        for dtype, stats in decision_types.items():
            if stats['count'] >= 3:
                success_rate = stats['success'] / stats['count']
                if success_rate >= 0.9:
                    patterns.append({
                        'pattern_type': 'high_success',
                        'decision_type': dtype,
                        'success_rate': round(success_rate, 2),
                        'sample_size': stats['count'],
                        'insight': f"Consistently successful at {dtype}"
                    })
                elif success_rate <= 0.5:
                    patterns.append({
                        'pattern_type': 'low_success',
                        'decision_type': dtype,
                        'success_rate': round(success_rate, 2),
                        'sample_size': stats['count'],
                        'insight': f"Struggling with {dtype} - needs improvement"
                    })
        
        return patterns
    
    def _analyze_failures(self, decisions: List[Dict]) -> Dict:
        """Analyze recent failures to identify root causes."""
        failures = [d for d in decisions if not d.get('success', True)]
        
        if not failures:
            return {
                'failure_count': 0,
                'common_causes': [],
                'severity': 'none'
            }
        
        # Categorize failures
        failure_causes = {}
        for failure in failures:
            cause = failure.get('failure_reason', 'unknown')
            if cause not in failure_causes:
                failure_causes[cause] = 0
            failure_causes[cause] += 1
        
        # Sort by frequency
        sorted_causes = sorted(failure_causes.items(), key=lambda x: x[1], reverse=True)
        
        return {
            'failure_count': len(failures),
            'common_causes': [
                {'cause': cause, 'count': count}
                for cause, count in sorted_causes[:5]
            ],
            'severity': 'high' if len(failures) > 10 else 'medium' if len(failures) > 5 else 'low'
        }
    
    def _update_self_model(self, decisions: List[Dict], performance_data: Dict) -> Dict:
        """Update Tiannara's self-understanding based on recent experience."""
        # Calculate learning rate
        if len(decisions) >= 2:
            recent_success = sum(1 for d in decisions[-10:] if d.get('success', False))
            older_success = sum(1 for d in decisions[-20:-10] if d.get('success', False))
            
            learning_rate = (recent_success - older_success) / 10.0
        else:
            learning_rate = 0.0
        
        # Update strengths and weaknesses
        strengths = []
        weaknesses = []
        
        # Analyze domain performance
        domains = performance_data.get('domains', {})
        for domain_name, health in domains.items():
            if health.get('success_rate', 0) >= 95:
                strengths.append(domain_name)
            elif health.get('success_rate', 0) < 80:
                weaknesses.append(domain_name)
        
        self.self_model.update({
            'strengths': strengths,
            'weaknesses': weaknesses,
            'learning_rate': round(learning_rate, 3),
            'last_updated': self._get_timestamp()
        })
        
        return self.self_model.copy()
    
    def _generate_improvements(self, decisions: List[Dict], performance_data: Dict) -> List[Dict]:
        """Generate actionable improvement recommendations."""
        recommendations = []
        
        # Check for declining domains
        domains = performance_data.get('domains', {})
        for domain_name, health in domains.items():
            if health.get('trend') == 'declining':
                recommendations.append({
                    'priority': 'high',
                    'action': f'investigate_{domain_name}_degradation',
                    'reason': f'{domain_name} performance is declining',
                    'suggested_steps': [
                        f'Review recent changes to {domain_name}',
                        f'Run diagnostic tests on {domain_name}',
                        f'Compare with baseline performance'
                    ]
                })
        
        # Check for knowledge gaps
        failure_analysis = self._analyze_failures(decisions)
        if failure_analysis['failure_count'] > 5:
            recommendations.append({
                'priority': 'medium',
                'action': 'address_recurring_failures',
                'reason': f"{failure_analysis['failure_count']} failures detected",
                'suggested_steps': [
                    'Analyze common failure causes',
                    'Develop targeted fixes',
                    'Implement preventive measures'
                ]
            })
        
        # Check confidence calibration
        if self.self_model.get('confidence_calibration') == 'overconfident':
            recommendations.append({
                'priority': 'medium',
                'action': 'recalibrate_confidence',
                'reason': 'Confidence levels may not match actual performance',
                'suggested_steps': [
                    'Review confidence vs accuracy data',
                    'Adjust confidence estimation algorithm',
                    'Implement confidence monitoring'
                ]
            })
        
        return recommendations
    
    def get_reflection_summary(self, num_recent: int = 5) -> Dict:
        """Get summary of recent reflection cycles."""
        recent = self.reflection_history[-num_recent:]
        
        if not recent:
            return {
                'total_reflections': 0,
                'message': 'No reflection cycles completed yet'
            }
        
        # Aggregate insights
        total_decisions_reviewed = sum(r['decisions_reviewed'] for r in recent)
        all_recommendations = []
        for r in recent:
            all_recommendations.extend(r.get('improvement_recommendations', []))
        
        return {
            'total_reflections': len(self.reflection_history),
            'recent_reflections': num_recent,
            'total_decisions_reviewed': total_decisions_reviewed,
            'pending_recommendations': len(all_recommendations),
            'last_reflection': recent[-1]['timestamp'] if recent else None
        }
    
    def _get_timestamp(self) -> str:
        """Get current timestamp."""
        return datetime.utcnow().isoformat()
