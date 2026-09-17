"""
Meta-Cognitive Monitor

Main orchestrator for Tiannara's self-awareness system.
Continuously monitors, evaluates, and improves all cognitive processes.
"""

from typing import Dict, List, Optional
from datetime import datetime

from .performance_tracker import DomainPerformanceTracker
from .quality_evaluator import ReasoningQualityEvaluator
from .gap_detector import KnowledgeGapDetector
from .self_reflection import SelfReflectionCycle


class MetaCognitiveMonitor:
    """
    Central meta-cognition system for Tiannara Core.
    
    Provides:
    - Continuous self-monitoring across all domains
    - Reasoning quality assessment
    - Knowledge gap detection
    - Periodic self-reflection cycles
    - Intelligent self-improvement recommendations
    """
    
    def __init__(self):
        # Initialize components
        self.performance_tracker = DomainPerformanceTracker()
        self.quality_evaluator = ReasoningQualityEvaluator()
        self.gap_detector = KnowledgeGapDetector()
        self.self_reflection = SelfReflectionCycle(reflection_interval_minutes=5)
        
        # Monitoring state
        self.is_monitoring = False
        self.monitoring_log: List[Dict] = []
        
        # Load historical data
        try:
            self.performance_tracker.load_state()
        except Exception as e:
            print(f"Warning: Could not load performance history: {e}")
    
    def start_monitoring(self):
        """Start continuous monitoring (would run in background thread)."""
        self.is_monitoring = True
        print("✅ Meta-cognitive monitoring started")
    
    def stop_monitoring(self):
        """Stop continuous monitoring."""
        self.is_monitoring = False
        print("⏸️  Meta-cognitive monitoring stopped")
    
    def continuous_self_assessment(self) -> Dict:
        """
        Perform comprehensive self-assessment.
        
        This is the core meta-cognitive function - should be called periodically
        (e.g., every 5 minutes) to maintain self-awareness.
        
        Returns:
            Complete assessment of Tiannara's current state
        """
        timestamp = datetime.utcnow().isoformat()
        
        # 1. Check all domain health
        domain_health = self.performance_tracker.get_all_domains_health()
        
        # 2. Detect any degradation
        degradation_alerts = []
        for domain in domain_health.keys():
            alert = self.performance_tracker.detect_degradation(domain)
            if alert:
                degradation_alerts.append(alert)
        
        # 3. Get knowledge gaps
        uncertainty_regions = self.gap_detector.get_uncertainty_regions()
        
        # 4. Check if reflection cycle needed
        reflection_results = None
        if self.self_reflection.should_reflect():
            # Gather recent decisions for reflection
            recent_decisions = self._gather_recent_decisions()
            reflection_results = self.self_reflection.perform_reflection(
                recent_decisions,
                {'domains': domain_health}
            )
        
        # 5. Compile comprehensive assessment
        assessment = {
            'timestamp': timestamp,
            'domain_health': domain_health,
            'degradation_alerts': degradation_alerts,
            'knowledge_gaps': {
                'uncertainty_regions': uncertainty_regions[:10],  # Top 10
                'total_unknown_areas': len(uncertainty_regions)
            },
            'self_reflection': reflection_results,
            'overall_status': self._determine_overall_status(domain_health, degradation_alerts),
            'recommended_actions': self._generate_action_plan(degradation_alerts, reflection_results)
        }
        
        # Log assessment
        self.monitoring_log.append({
            'timestamp': timestamp,
            'status': assessment['overall_status'],
            'alerts_count': len(degradation_alerts)
        })
        
        # Keep only last 1000 log entries
        if len(self.monitoring_log) > 1000:
            self.monitoring_log = self.monitoring_log[-1000:]
        
        # Save state
        try:
            self.performance_tracker.save_state()
        except Exception as e:
            print(f"Warning: Could not save performance history: {e}")
        
        return assessment
    
    def evaluate_decision_quality(self, decision_trace: Dict) -> Dict:
        """
        Evaluate the quality of a specific decision or reasoning process.
        
        Args:
            decision_trace: Dictionary containing decision details
        
        Returns:
            Quality assessment with scores and recommendations
        """
        return self.quality_evaluator.evaluate_reasoning_quality(decision_trace)
    
    def check_knowledge_readiness(self, query: str) -> Dict:
        """
        Check if Tiannara has sufficient knowledge to handle a query.
        
        Args:
            query: The question or task
        
        Returns:
            Readiness assessment with known/unknown areas
        """
        return self.gap_detector.detect_gaps(query)
    
    def record_domain_performance(self, domain: str, metric_type: str, value: float):
        """
        Record a performance metric for a domain.
        
        Should be called by domain engines after completing tasks.
        
        Args:
            domain: Domain name (e.g., 'temporal', 'combinatorial')
            metric_type: Type of metric ('success_rate', 'latency_ms', etc.)
            value: Metric value
        """
        self.performance_tracker.record_metric(domain, metric_type, value)
    
    def track_learning_progress(self, domain: str, improvement: float, evidence: str):
        """
        Track learning progress in a specific domain.
        
        Args:
            domain: Domain where learning occurred
            improvement: Confidence improvement (0-1)
            evidence: Description of what was learned
        """
        self.gap_detector.track_learning(domain, improvement, evidence)
    
    def get_monitoring_summary(self) -> Dict:
        """Get summary of monitoring activity."""
        return {
            'is_monitoring': self.is_monitoring,
            'total_assessments': len(self.monitoring_log),
            'recent_reflections': self.self_reflection.get_reflection_summary(),
            'last_assessment': self.monitoring_log[-1] if self.monitoring_log else None
        }
    
    def _gather_recent_decisions(self) -> List[Dict]:
        """Gather recent decisions for reflection (placeholder)."""
        # In production, this would pull from decision log/database
        # For now, return empty list
        return []
    
    def _determine_overall_status(self, domain_health: Dict, alerts: List[Dict]) -> str:
        """Determine overall system status."""
        if not domain_health:
            return 'unknown'
        
        # Check for critical issues
        critical_domains = sum(
            1 for h in domain_health.values()
            if h.get('status') == 'critical'
        )
        
        if critical_domains > 0 or len(alerts) > 3:
            return 'critical'
        elif len(alerts) > 0:
            return 'degraded'
        else:
            return 'healthy'
    
    def _generate_action_plan(self, alerts: List[Dict], reflection: Optional[Dict]) -> List[Dict]:
        """Generate prioritized action plan based on assessment."""
        actions = []
        
        # Add actions for degradation alerts
        for alert in alerts:
            actions.append({
                'priority': 'high',
                'type': 'fix_degradation',
                'domain': alert['domain'],
                'action': alert['recommendation'],
                'alerts': alert['alerts']
            })
        
        # Add actions from reflection
        if reflection and reflection.get('improvement_recommendations'):
            for rec in reflection['improvement_recommendations']:
                actions.append({
                    'priority': rec['priority'],
                    'type': 'improvement',
                    'action': rec['action'],
                    'reason': rec['reason']
                })
        
        # Sort by priority
        priority_order = {'high': 0, 'medium': 1, 'low': 2}
        actions.sort(key=lambda x: priority_order.get(x['priority'], 3))
        
        return actions[:10]  # Return top 10 actions
