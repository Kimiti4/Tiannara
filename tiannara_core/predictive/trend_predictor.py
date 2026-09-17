"""
Trend Predictor - Trend prediction and anomaly detection

Forecasts user interest shifts, identifies emerging topics,
and detects unusual patterns using time-series analysis.
"""

import logging
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from collections import defaultdict

logger = logging.getLogger(__name__)


@dataclass
class TrendForecast:
    """Forecast for a trend."""
    topic: str
    direction: str  # 'increasing', 'decreasing', 'stable'
    confidence: float
    predicted_value: float
    time_horizon: str
    factors: List[str] = field(default_factory=list)


@dataclass
class AnomalyAlert:
    """Alert for detected anomaly."""
    alert_id: str
    description: str
    severity: str  # 'low', 'medium', 'high'
    timestamp: datetime
    metric_name: str
    actual_value: float
    expected_value: float


class TrendPredictor:
    """Trend prediction and anomaly detection system.
    
    Features:
    - Forecast user interest shifts
    - Identify emerging topics and patterns
    - Alert on unusual activity patterns
    - Seasonal trend detection
    - Time-series forecasting
    
    Example:
        >>> predictor = TrendPredictor()
        >>> forecast = predictor.forecast_trend("user_queries")
    """
    
    def __init__(self):
        self.time_series_data: Dict[str, List[Tuple[datetime, float]]] = defaultdict(list)
        self.baselines: Dict[str, Dict[str, float]] = {}
        self.alerts: List[AnomalyAlert] = []
        
        logger.info("Initialized TrendPredictor")
    
    def add_data_point(self, metric_name: str, value: float, 
                      timestamp: Optional[datetime] = None):
        """Add a data point to time series.
        
        Args:
            metric_name: Name of the metric
            value: Metric value
            timestamp: Timestamp (defaults to now)
        """
        ts = timestamp or datetime.now()
        self.time_series_data[metric_name].append((ts, value))
        
        # Keep only recent data (last 1000 points)
        if len(self.time_series_data[metric_name]) > 1000:
            self.time_series_data[metric_name] = self.time_series_data[metric_name][-1000:]
        
        logger.debug(f"Added data point for {metric_name}: {value}")
    
    def forecast_trend(self, metric_name: str, horizon: str = "7d") -> Optional[TrendForecast]:
        """Forecast trend for a metric.
        
        Args:
            metric_name: Name of the metric to forecast
            horizon: Forecast horizon (e.g., "7d", "30d")
            
        Returns:
            TrendForecast or None if insufficient data
        """
        data = self.time_series_data.get(metric_name, [])
        if len(data) < 10:
            logger.warning(f"Insufficient data for forecasting {metric_name}")
            return None
        
        # Calculate trend direction
        values = [v for _, v in data[-20:]]  # Last 20 points
        recent_avg = sum(values[-5:]) / 5
        older_avg = sum(values[:5]) / 5
        
        if recent_avg > older_avg * 1.1:
            direction = 'increasing'
        elif recent_avg < older_avg * 0.9:
            direction = 'decreasing'
        else:
            direction = 'stable'
        
        # Simple linear extrapolation for prediction
        if len(values) >= 2:
            slope = (values[-1] - values[0]) / len(values)
            predicted_value = values[-1] + (slope * 7)  # 7-day projection
        else:
            predicted_value = values[-1] if values else 0
        
        # Calculate confidence based on data quality
        confidence = min(len(data) / 100.0, 0.9)
        
        forecast = TrendForecast(
            topic=metric_name,
            direction=direction,
            confidence=confidence,
            predicted_value=predicted_value,
            time_horizon=horizon,
            factors=['historical_pattern', 'recent_trend']
        )
        
        logger.info(f"Forecast for {metric_name}: {direction} (confidence: {confidence:.2f})")
        return forecast
    
    def detect_anomalies(self, metric_name: str, 
                        threshold_std: float = 2.0) -> List[AnomalyAlert]:
        """Detect anomalies in metric data.
        
        Args:
            metric_name: Name of the metric
            threshold_std: Number of standard deviations for anomaly
            
        Returns:
            List of AnomalyAlert objects
        """
        data = self.time_series_data.get(metric_name, [])
        if len(data) < 20:
            return []
        
        values = [v for _, v in data[-50:]]  # Last 50 points
        
        # Calculate statistics
        mean = sum(values) / len(values)
        variance = sum((x - mean) ** 2 for x in values) / len(values)
        std_dev = variance ** 0.5
        
        if std_dev == 0:
            return []
        
        # Detect anomalies
        alerts = []
        for timestamp, value in data[-10:]:  # Check last 10 points
            z_score = abs(value - mean) / std_dev
            
            if z_score > threshold_std:
                severity = 'high' if z_score > 3.0 else 'medium' if z_score > 2.5 else 'low'
                
                alert = AnomalyAlert(
                    alert_id=f"anomaly_{metric_name}_{timestamp.strftime('%Y%m%d%H%M%S')}",
                    description=f"Unusual {metric_name} value: {value:.2f} (expected ~{mean:.2f})",
                    severity=severity,
                    timestamp=timestamp,
                    metric_name=metric_name,
                    actual_value=value,
                    expected_value=mean
                )
                alerts.append(alert)
        
        self.alerts.extend(alerts)
        logger.info(f"Detected {len(alerts)} anomalies for {metric_name}")
        
        return alerts
    
    def detect_seasonality(self, metric_name: str) -> Dict[str, Any]:
        """Detect seasonal patterns in data.
        
        Args:
            metric_name: Name of the metric
            
        Returns:
            Dictionary with seasonality information
        """
        data = self.time_series_data.get(metric_name, [])
        if len(data) < 100:
            return {'seasonal': False, 'reason': 'insufficient_data'}
        
        # Simple seasonality detection (check for repeating patterns)
        values = [v for _, v in data]
        
        # Check autocorrelation at different lags
        n = len(values)
        max_lag = min(n // 2, 50)
        
        best_lag = None
        best_correlation = 0
        
        for lag in range(7, max_lag):  # Check weekly patterns
            correlation = self._calculate_autocorrelation(values, lag)
            if correlation > best_correlation:
                best_correlation = correlation
                best_lag = lag
        
        is_seasonal = best_correlation > 0.5
        
        return {
            'seasonal': is_seasonal,
            'period': best_lag if is_seasonal else None,
            'strength': best_correlation,
            'metric': metric_name
        }
    
    def _calculate_autocorrelation(self, values: List[float], lag: int) -> float:
        """Calculate autocorrelation at a given lag."""
        n = len(values)
        if lag >= n:
            return 0.0
        
        mean = sum(values) / n
        
        numerator = sum((values[i] - mean) * (values[i + lag] - mean) 
                       for i in range(n - lag))
        denominator = sum((x - mean) ** 2 for x in values)
        
        if denominator == 0:
            return 0.0
        
        return numerator / denominator
    
    def get_recent_alerts(self, limit: int = 10) -> List[AnomalyAlert]:
        """Get recent anomaly alerts.
        
        Args:
            limit: Maximum number of alerts to return
            
        Returns:
            List of recent AnomalyAlert objects
        """
        sorted_alerts = sorted(self.alerts, key=lambda a: a.timestamp, reverse=True)
        return sorted_alerts[:limit]


# Convenience function
def create_predictor() -> TrendPredictor:
    """Create a new trend predictor."""
    return TrendPredictor()
