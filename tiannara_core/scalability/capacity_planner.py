"""
Capacity Planner - Resource forecasting and capacity planning

Predicts future resource needs based on growth trends,
current utilization, and projected demand increases.
"""

import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from datetime import datetime, timedelta
import math

logger = logging.getLogger(__name__)


@dataclass
class CapacityForecast:
    """Forecast for resource capacity needs."""
    resource_type: str
    current_usage_percent: float
    predicted_usage_30d: float
    predicted_usage_90d: float
    recommended_capacity: str
    urgency: str  # 'low', 'medium', 'high', 'critical'
    estimated_cost_increase: float
    recommendations: List[str] = field(default_factory=list)


class CapacityPlanner:
    """Intelligent capacity planning system.
    
    Features:
    - Growth trend analysis
    - Future capacity prediction
    - Cost estimation
    - Scaling recommendations
    - Risk assessment
    """
    
    def __init__(self):
        self.utilization_history: List[Dict[str, Any]] = []
        self.resource_limits: Dict[str, float] = {
            'cpu_cores': 32,
            'memory_gb': 128,
            'storage_tb': 10,
            'concurrent_users': 10000
        }
        
    def record_utilization(self, metrics: Dict[str, float]):
        """Record current resource utilization."""
        entry = {
            'timestamp': datetime.now(),
            **metrics
        }
        self.utilization_history.append(entry)
        logger.debug(f"Recorded utilization: {list(metrics.keys())}")
    
    def forecast_capacity(self, resource_type: str) -> CapacityForecast:
        """Generate capacity forecast for a specific resource.
        
        Args:
            resource_type: Type of resource ('cpu', 'memory', 'storage', 'users')
            
        Returns:
            CapacityForecast with predictions and recommendations
        """
        history = self._get_resource_history(resource_type)
        
        if len(history) < 2:
            return self._insufficient_data_forecast(resource_type)
        
        current_usage = history[-1]['usage_percent']
        growth_rate = self._calculate_growth_rate(history)
        
        # Predict future usage
        usage_30d = min(current_usage * (1 + growth_rate * 30), 100)
        usage_90d = min(current_usage * (1 + growth_rate * 90), 100)
        
        # Determine urgency
        urgency = self._assess_urgency(current_usage, usage_30d, usage_90d)
        
        # Generate recommendations
        recommendations = self._generate_recommendations(
            resource_type, current_usage, usage_30d, urgency
        )
        
        # Estimate cost impact
        cost_increase = self._estimate_cost_increase(resource_type, urgency)
        
        return CapacityForecast(
            resource_type=resource_type,
            current_usage_percent=current_usage,
            predicted_usage_30d=usage_30d,
            predicted_usage_90d=usage_90d,
            recommended_capacity=self._recommend_capacity(resource_type, usage_90d),
            urgency=urgency,
            estimated_cost_increase=cost_increase,
            recommendations=recommendations
        )
    
    def get_scaling_plan(self) -> Dict[str, Any]:
        """Generate comprehensive scaling plan for all resources."""
        resources = ['cpu', 'memory', 'storage', 'users']
        forecasts = {r: self.forecast_capacity(r) for r in resources}
        
        critical_resources = [
            r for r, f in forecasts.items() 
            if f.urgency in ['high', 'critical']
        ]
        
        return {
            'generated_at': datetime.now().isoformat(),
            'forecasts': forecasts,
            'critical_actions_needed': critical_resources,
            'estimated_monthly_cost_increase': sum(
                f.estimated_cost_increase for f in forecasts.values()
            ),
            'immediate_actions': self._get_immediate_actions(forecasts)
        }
    
    def _get_resource_history(self, resource_type: str) -> List[Dict]:
        """Extract historical data for a specific resource."""
        return [
            h for h in self.utilization_history 
            if f'{resource_type}_usage_percent' in h
        ]
    
    def _calculate_growth_rate(self, history: List[Dict]) -> float:
        """Calculate daily growth rate from historical data."""
        if len(history) < 2:
            return 0.01  # Default 1% daily growth
        
        first = history[0]['usage_percent']
        last = history[-1]['usage_percent']
        days = max((history[-1]['timestamp'] - history[0]['timestamp']).days, 1)
        
        return (last - first) / (first * days) if first > 0 else 0.01
    
    def _assess_urgency(self, current: float, pred_30d: float, pred_90d: float) -> str:
        """Assess urgency level based on current and predicted usage."""
        if pred_90d > 90 or current > 85:
            return 'critical'
        elif pred_90d > 75 or current > 70:
            return 'high'
        elif pred_30d > 65:
            return 'medium'
        else:
            return 'low'
    
    def _generate_recommendations(
        self, resource_type: str, current: float, pred_30d: float, urgency: str
    ) -> List[str]:
        """Generate actionable recommendations."""
        recs = []
        
        if urgency in ['high', 'critical']:
            recs.append(f"Immediate scaling required for {resource_type}")
            recs.append(f"Current usage: {current:.1f}%, predicted 30-day: {pred_30d:.1f}%")
        
        if resource_type == 'cpu':
            recs.append("Consider horizontal scaling or CPU optimization")
        elif resource_type == 'memory':
            recs.append("Review memory leaks and optimize caching strategy")
        elif resource_type == 'storage':
            recs.append("Implement data archival and compression")
        elif resource_type == 'users':
            recs.append("Prepare auto-scaling configuration for user load")
        
        return recs
    
    def _estimate_cost_increase(self, resource_type: str, urgency: str) -> float:
        """Estimate monthly cost increase for scaling."""
        base_costs = {
            'cpu': 100,
            'memory': 80,
            'storage': 50,
            'users': 200
        }
        
        urgency_multipliers = {
            'low': 0.1,
            'medium': 0.3,
            'high': 0.6,
            'critical': 1.0
        }
        
        return base_costs.get(resource_type, 100) * urgency_multipliers.get(urgency, 0.5)
    
    def _recommend_capacity(self, resource_type: str, predicted_usage: float) -> str:
        """Recommend new capacity level."""
        limits = self.resource_limits
        
        if resource_type == 'cpu':
            if predicted_usage > 80:
                return f"{int(limits['cpu_cores'] * 1.5)} cores"
            elif predicted_usage > 60:
                return f"{int(limits['cpu_cores'] * 1.25)} cores"
            else:
                return f"{limits['cpu_cores']} cores (current)"
        elif resource_type == 'memory':
            if predicted_usage > 80:
                return f"{int(limits['memory_gb'] * 1.5)} GB"
            elif predicted_usage > 60:
                return f"{int(limits['memory_gb'] * 1.25)} GB"
            else:
                return f"{limits['memory_gb']} GB (current)"
        else:
            return "Monitor and reassess"
    
    def _insufficient_data_forecast(self, resource_type: str) -> CapacityForecast:
        """Return forecast when insufficient historical data."""
        return CapacityForecast(
            resource_type=resource_type,
            current_usage_percent=0,
            predicted_usage_30d=0,
            predicted_usage_90d=0,
            recommended_capacity="Insufficient data",
            urgency="low",
            estimated_cost_increase=0,
            recommendations=["Collect more utilization data for accurate forecasting"]
        )
    
    def _get_immediate_actions(self, forecasts: Dict[str, CapacityForecast]) -> List[str]:
        """Get list of immediate actions needed."""
        actions = []
        for resource, forecast in forecasts.items():
            if forecast.urgency in ['high', 'critical']:
                actions.append(
                    f"[{forecast.urgency.upper()}] Scale {resource}: "
                    f"{forecast.recommended_capacity}"
                )
        return actions
