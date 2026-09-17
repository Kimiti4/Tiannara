"""
Stagnation Detection Module for Tiannara Autonomy

Detects performance plateaus in learning systems and triggers
automatic recovery mechanisms to maintain continuous improvement.

Key Features:
- Performance plateau detection (>N episodes without improvement)
- Learning curve analysis with trend detection
- Stagnation severity scoring (mild/moderate/severe)
- Automatic logging to SQLite for historical analysis
- Integration with evolution loop for strategy switching

Usage:
    from tiannara_core.autonomy.stagnation_detector import StagnationDetector
    
    detector = StagnationDetection(window_size=50, threshold=0.01)
    
    # After each episode
    detector.record_episode(episode_num, success_rate, quality_score)
    
    # Check for stagnation
    if detector.is_stagnant():
        severity = detector.get_severity()
        detector.log_stagnation_event()
"""

import numpy as np
import logging
import sqlite3
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum

logger = logging.getLogger(__name__)


class StagnationSeverity(Enum):
    """Severity levels for detected stagnation."""
    NONE = "none"
    MILD = "mild"           # Slight plateau, may recover naturally
    MODERATE = "moderate"   # Clear plateau, intervention recommended
    SEVERE = "severe"       # Extended plateau, immediate action required


@dataclass
class StagnationEvent:
    """Record of a detected stagnation event."""
    timestamp: str
    episode_number: int
    severity: StagnationSeverity
    window_size: int
    improvement_rate: float  # Rate of improvement (negative = decline)
    current_performance: float
    peak_performance: float
    performance_drop_pct: float
    duration_episodes: int  # How long stagnation has persisted
    metadata: Dict = field(default_factory=dict)


@dataclass
class LearningCurveStats:
    """Statistics about the learning curve."""
    mean_performance: float
    std_performance: float
    trend_slope: float  # Positive = improving, negative = declining
    recent_improvement: float  # Improvement over last N episodes
    volatility: float  # Performance variability
    episodes_analyzed: int


class StagnationDetector:
    """
    Detects stagnation in learning systems and provides recovery recommendations.
    
    Monitors performance metrics over time to identify plateaus where
    the system stops improving. Triggers alerts and logs events for
    automated recovery mechanisms.
    
    Attributes:
        window_size: Number of episodes to analyze for plateau detection
        threshold: Minimum improvement rate to avoid stagnation flag
        min_episodes: Minimum episodes before detection activates
        severity_thresholds: Performance drop percentages for severity levels
    """
    
    def __init__(
        self,
        window_size: int = 50,
        threshold: float = 0.01,
        min_episodes: int = 20,
        db_path: Optional[str] = None
    ):
        """
        Initialize stagnation detector.
        
        Args:
            window_size: Episodes to analyze for plateau detection (default: 50)
            threshold: Min improvement rate to avoid stagnation (default: 0.01 = 1%)
            min_episodes: Min episodes before detection activates (default: 20)
            db_path: Path to SQLite database for logging (optional)
        """
        self.window_size = window_size
        self.threshold = threshold
        self.min_episodes = min_episodes
        
        # Performance history
        self.episode_history: List[Dict] = []
        self.performance_series: List[float] = []
        self.episode_numbers: List[int] = []
        
        # Stagnation tracking
        self.current_stagnation_start: Optional[int] = None
        self.peak_performance: float = 0.0
        self.peak_episode: int = 0
        
        # Severity thresholds (performance drop percentages)
        self.severity_thresholds = {
            StagnationSeverity.MILD: 0.05,      # 5% drop
            StagnationSeverity.MODERATE: 0.10,  # 10% drop
            StagnationSeverity.SEVERE: 0.20     # 20% drop
        }
        
        # Database setup
        self.db_path = db_path
        if db_path:
            self._init_database(db_path)
        
        logger.info(
            f"StagnationDetector initialized: window={window_size}, "
            f"threshold={threshold}, min_episodes={min_episodes}"
        )
    
    def record_episode(
        self,
        episode_num: int,
        success_rate: float,
        quality_score: Optional[float] = None,
        **metrics
    ):
        """
        Record episode results for stagnation analysis.
        
        Args:
            episode_num: Episode number
            success_rate: Success rate (0.0-1.0) or primary performance metric
            quality_score: Optional secondary quality metric
            **metrics: Additional metrics to track
        """
        record = {
            'episode': episode_num,
            'success_rate': success_rate,
            'quality_score': quality_score,
            'timestamp': datetime.now().isoformat(),
            **metrics
        }
        
        self.episode_history.append(record)
        self.performance_series.append(success_rate)
        self.episode_numbers.append(episode_num)
        
        # Update peak performance
        if success_rate > self.peak_performance:
            self.peak_performance = success_rate
            self.peak_episode = episode_num
            self.current_stagnation_start = None  # Reset stagnation on improvement
        
        logger.debug(
            f"Recorded episode {episode_num}: success_rate={success_rate:.3f}, "
            f"peak={self.peak_performance:.3f}"
        )
    
    def is_stagnant(self) -> bool:
        """
        Check if the system is currently stagnant.
        
        Returns:
            True if performance has plateaued beyond threshold
        """
        if len(self.performance_series) < self.min_episodes:
            return False
        
        # Get recent window
        recent = self._get_recent_window()
        if len(recent) < self.window_size:
            return False
        
        # Calculate trend
        stats = self._analyze_learning_curve(recent)
        
        # Check if improvement rate is below threshold
        is_plateau = abs(stats.trend_slope) < self.threshold
        
        # Also check if performance has dropped significantly from peak
        current_avg = np.mean(recent[-10:])  # Last 10 episodes
        drop_from_peak = (self.peak_performance - current_avg) / max(self.peak_performance, 0.01)
        
        is_declining = drop_from_peak > self.severity_thresholds[StagnationSeverity.MILD]
        
        stagnant = is_plateau or is_declining
        
        if stagnant and self.current_stagnation_start is None:
            self.current_stagnation_start = self.episode_numbers[-1]
            logger.warning(
                f"⚠️  STAGNATION DETECTED at episode {self.episode_numbers[-1]}: "
                f"trend_slope={stats.trend_slope:.4f}, "
                f"drop_from_peak={drop_from_peak*100:.1f}%"
            )
        
        return stagnant
    
    def get_severity(self) -> StagnationSeverity:
        """
        Get the severity level of current stagnation.
        
        Returns:
            StagnationSeverity enum value
        """
        if not self.is_stagnant():
            return StagnationSeverity.NONE
        
        if self.current_stagnation_start is None:
            return StagnationSeverity.NONE
        
        # Calculate performance drop from peak
        recent = self._get_recent_window()
        current_avg = np.mean(recent[-10:])
        drop_from_peak = (self.peak_performance - current_avg) / max(self.peak_performance, 0.01)
        
        # Determine severity based on drop percentage
        if drop_from_peak >= self.severity_thresholds[StagnationSeverity.SEVERE]:
            return StagnationSeverity.SEVERE
        elif drop_from_peak >= self.severity_thresholds[StagnationSeverity.MODERATE]:
            return StagnationSeverity.MODERATE
        elif drop_from_peak >= self.severity_thresholds[StagnationSeverity.MILD]:
            return StagnationSeverity.MILD
        else:
            return StagnationSeverity.MILD
    
    def get_learning_curve_stats(self) -> LearningCurveStats:
        """
        Get comprehensive statistics about the learning curve.
        
        Returns:
            LearningCurveStats with trend analysis
        """
        if len(self.performance_series) == 0:
            return LearningCurveStats(
                mean_performance=0.0,
                std_performance=0.0,
                trend_slope=0.0,
                recent_improvement=0.0,
                volatility=0.0,
                episodes_analyzed=0
            )
        
        recent = self._get_recent_window()
        return self._analyze_learning_curve(recent)
    
    def log_stagnation_event(self, metadata: Optional[Dict] = None) -> Optional[StagnationEvent]:
        """
        Log a stagnation event to database and return event details.
        
        Args:
            metadata: Additional context about the stagnation
            
        Returns:
            StagnationEvent if stagnation detected, None otherwise
        """
        if not self.is_stagnant():
            return None
        
        severity = self.get_severity()
        recent = self._get_recent_window()
        current_perf = np.mean(recent[-10:])
        
        # Calculate duration
        duration = 0
        if self.current_stagnation_start is not None:
            duration = self.episode_numbers[-1] - self.current_stagnation_start
        
        # Calculate improvement rate
        stats = self._analyze_learning_curve(recent)
        
        event = StagnationEvent(
            timestamp=datetime.now().isoformat(),
            episode_number=self.episode_numbers[-1],
            severity=severity,
            window_size=self.window_size,
            improvement_rate=stats.trend_slope,
            current_performance=current_perf,
            peak_performance=self.peak_performance,
            performance_drop_pct=(self.peak_performance - current_perf) / max(self.peak_performance, 0.01),
            duration_episodes=duration,
            metadata=metadata or {}
        )
        
        # Log to database if available
        if self.db_path:
            self._save_to_database(event)
        
        # Log to logger
        logger.warning(
            f"📉 STAGNATION EVENT LOGGED:\n"
            f"  Severity: {severity.value}\n"
            f"  Episode: {event.episode_number}\n"
            f"  Duration: {duration} episodes\n"
            f"  Current performance: {current_perf:.3f}\n"
            f"  Peak performance: {self.peak_performance:.3f}\n"
            f"  Drop: {event.performance_drop_pct*100:.1f}%\n"
            f"  Trend slope: {stats.trend_slope:.4f}"
        )
        
        return event
    
    def get_recovery_recommendations(self) -> List[str]:
        """
        Get recommendations for recovering from stagnation.
        
        Returns:
            List of recommended actions based on severity
        """
        severity = self.get_severity()
        
        if severity == StagnationSeverity.NONE:
            return []
        
        recommendations = []
        
        # Base recommendations for all stagnation
        recommendations.append("Increase exploration rate (reduce exploitation)")
        recommendations.append("Inject diversity into mutation operators")
        
        # Severity-specific recommendations
        if severity in [StagnationSeverity.MODERATE, StagnationSeverity.SEVERE]:
            recommendations.append("Switch to alternative mutation strategies")
            recommendations.append("Reset skill memory to force new learning")
            recommendations.append("Increase difficulty to escape local optima")
        
        if severity == StagnationSeverity.SEVERE:
            recommendations.append("CRITICAL: Consider architecture modification")
            recommendations.append("Perform extensive parameter sweep")
            recommendations.append("Evaluate if task distribution needs adjustment")
        
        return recommendations
    
    def _get_recent_window(self) -> List[float]:
        """Get the most recent performance window."""
        if len(self.performance_series) <= self.window_size:
            return self.performance_series
        return self.performance_series[-self.window_size:]
    
    def _analyze_learning_curve(self, series: List[float]) -> LearningCurveStats:
        """
        Analyze learning curve statistics.
        
        Args:
            series: Performance time series
            
        Returns:
            LearningCurveStats with trend analysis
        """
        if len(series) == 0:
            return LearningCurveStats(0.0, 0.0, 0.0, 0.0, 0.0, 0)
        
        arr = np.array(series)
        
        # Basic statistics
        mean_perf = np.mean(arr)
        std_perf = np.std(arr)
        
        # Trend analysis using linear regression
        x = np.arange(len(arr))
        if len(arr) > 1:
            slope, _ = np.polyfit(x, arr, 1)
        else:
            slope = 0.0
        
        # Recent improvement (last 20% vs first 20% of window)
        split = max(1, len(arr) // 5)
        if len(arr) >= split * 2:
            recent_improvement = np.mean(arr[-split:]) - np.mean(arr[:split])
        else:
            recent_improvement = 0.0
        
        # Volatility (coefficient of variation)
        volatility = std_perf / max(mean_perf, 0.01)
        
        return LearningCurveStats(
            mean_performance=float(mean_perf),
            std_performance=float(std_perf),
            trend_slope=float(slope),
            recent_improvement=float(recent_improvement),
            volatility=float(volatility),
            episodes_analyzed=len(arr)
        )
    
    def _init_database(self, db_path: str):
        """Initialize SQLite database for stagnation event logging."""
        self.db_path = db_path
        Path(db_path).parent.mkdir(parents=True, exist_ok=True)
        
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS stagnation_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                episode_number INTEGER NOT NULL,
                severity TEXT NOT NULL,
                window_size INTEGER NOT NULL,
                improvement_rate REAL NOT NULL,
                current_performance REAL NOT NULL,
                peak_performance REAL NOT NULL,
                performance_drop_pct REAL NOT NULL,
                duration_episodes INTEGER NOT NULL,
                metadata TEXT
            )
        ''')
        
        conn.commit()
        conn.close()
        
        logger.info(f"Stagnation event database initialized: {db_path}")
    
    def _save_to_database(self, event: StagnationEvent):
        """Save stagnation event to SQLite database."""
        if not self.db_path:
            return
        
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            import json
            cursor.execute('''
                INSERT INTO stagnation_events 
                (timestamp, episode_number, severity, window_size, 
                 improvement_rate, current_performance, peak_performance,
                 performance_drop_pct, duration_episodes, metadata)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                event.timestamp,
                event.episode_number,
                event.severity.value,
                event.window_size,
                event.improvement_rate,
                event.current_performance,
                event.peak_performance,
                event.performance_drop_pct,
                event.duration_episodes,
                json.dumps(event.metadata)
            ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            logger.error(f"Failed to save stagnation event to database: {e}")
    
    def reset(self):
        """Reset detector state (useful after successful recovery)."""
        self.current_stagnation_start = None
        logger.info("Stagnation detector reset")


# Convenience function for quick integration
def check_stagnation(
    detector: StagnationDetector,
    episode_num: int,
    success_rate: float,
    auto_log: bool = True
) -> Dict:
    """
    Quick-check helper for stagnation detection.
    
    Args:
        detector: StagnationDetector instance
        episode_num: Current episode number
        success_rate: Current success rate
        auto_log: Automatically log if stagnation detected
        
    Returns:
        Dict with stagnation status and recommendations
    """
    # Record episode
    detector.record_episode(episode_num, success_rate)
    
    # Check stagnation
    stagnant = detector.is_stagnant()
    severity = detector.get_severity()
    
    result = {
        'stagnant': stagnant,
        'severity': severity.value,
        'recommendations': []
    }
    
    if stagnant and auto_log:
        event = detector.log_stagnation_event()
        if event:
            result['event'] = event
            result['recommendations'] = detector.get_recovery_recommendations()
    
    return result
