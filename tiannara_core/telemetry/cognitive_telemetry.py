"""
COGNITIVE TELEMETRY SYSTEM

Purpose: Longitudinal metric collection for identifying cognitive signatures,
instability precursors, and emergent coordination patterns.

Based on next.md (lines 641-667):
"Create Cognitive Telemetry - Log things like:
- contradiction density over time,
- synthesis convergence rates,
- confidence calibration,
- theory survival curves,
- communication entropy,
- causal consistency scores,
- epistemic recovery rates,
- memory reconstruction fidelity.

Over months, this becomes incredibly valuable.
You'll begin seeing:
- cognitive signatures,
- instability precursors,
- emergent coordination patterns,
- drift fingerprints.

That data becomes your real research asset."

Architecture:
Continuous telemetry collection with time-series storage, anomaly detection,
and export capabilities for long-term analysis.
"""

import time
import json
import sqlite3
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field, asdict
from datetime import datetime, timedelta
from enum import Enum
import statistics


class MetricType(Enum):
    """Types of cognitive metrics tracked."""
    CONTRADICTION_DENSITY = "contradiction_density"
    SYNTHESIS_CONVERGENCE = "synthesis_convergence"
    CONFIDENCE_CALIBRATION = "confidence_calibration"
    THEORY_SURVIVAL = "theory_survival"
    COMMUNICATION_ENTROPY = "communication_entropy"
    CAUSAL_CONSISTENCY = "causal_consistency"
    EPISTEMIC_RECOVERY = "epistemic_recovery"
    MEMORY_FIDELITY = "memory_fidelity"
    IDENTITY_DRIFT = "identity_drift"
    AGENT_COORDINATION = "agent_coordination"
    BELIEF_STABILITY = "belief_stability"


@dataclass
class TelemetryRecord:
    """Single telemetry data point."""
    record_id: str
    metric_type: MetricType
    value: float
    timestamp: float = field(default_factory=time.time)
    
    # Context
    domain: Optional[str] = None
    session_id: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    # Quality indicators
    confidence: float = 0.9
    sample_size: int = 1


@dataclass
class AnomalyDetection:
    """Detected anomaly in telemetry data."""
    anomaly_id: str
    metric_type: MetricType
    severity: str  # "low", "medium", "high", "critical"
    description: str
    current_value: float
    expected_range: Tuple[float, float]
    deviation_score: float  # How far from normal
    
    # Context
    window_size: int = 100  # Number of points analyzed
    detected_at: float = field(default_factory=time.time)
    affected_records: List[str] = field(default_factory=list)
    recommended_actions: List[str] = field(default_factory=list)


class CognitiveTelemetryCollector:
    """
    Continuous cognitive telemetry collection system.
    
    Tracks 8+ core metrics over time with:
    - Time-series storage (SQLite optimized)
    - Anomaly detection (statistical methods)
    - Export capabilities (CSV/JSON)
    - Query interface for analysis
    """
    
    def __init__(self, db_path: Optional[str] = None):
        """
        Initialize telemetry collector.
        
        Args:
            db_path: Path to SQLite database (default: runs/cognitive_telemetry.db)
        """
        self.db_path = db_path or "runs/cognitive_telemetry.db"
        self.records: List[TelemetryRecord] = []
        self.anomalies: List[AnomalyDetection] = []
        
        # Initialize database
        self._init_database()
        
        # Anomaly detection thresholds
        self.anomaly_thresholds = {
            MetricType.CONTRADICTION_DENSITY: {"std_multiplier": 2.0, "min_samples": 50},
            MetricType.SYNTHESIS_CONVERGENCE: {"std_multiplier": 1.5, "min_samples": 30},
            MetricType.CONFIDENCE_CALIBRATION: {"std_multiplier": 2.0, "min_samples": 100},
            MetricType.THEORY_SURVIVAL: {"std_multiplier": 1.5, "min_samples": 50},
            MetricType.COMMUNICATION_ENTROPY: {"std_multiplier": 2.5, "min_samples": 100},
            MetricType.CAUSAL_CONSISTENCY: {"std_multiplier": 2.0, "min_samples": 50},
            MetricType.EPISTEMIC_RECOVERY: {"std_multiplier": 1.5, "min_samples": 30},
            MetricType.MEMORY_FIDELITY: {"std_multiplier": 2.0, "min_samples": 50},
        }
    
    def _init_database(self):
        """Initialize SQLite database with optimized schema."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Create records table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS telemetry_records (
                record_id TEXT PRIMARY KEY,
                metric_type TEXT NOT NULL,
                value REAL NOT NULL,
                timestamp REAL NOT NULL,
                domain TEXT,
                session_id TEXT,
                metadata TEXT,
                confidence REAL DEFAULT 0.9,
                sample_size INTEGER DEFAULT 1
            )
        """)
        
        # Create anomalies table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS anomalies (
                anomaly_id TEXT PRIMARY KEY,
                metric_type TEXT NOT NULL,
                severity TEXT NOT NULL,
                description TEXT,
                detected_at REAL NOT NULL,
                current_value REAL NOT NULL,
                expected_min REAL NOT NULL,
                expected_max REAL NOT NULL,
                deviation_score REAL NOT NULL,
                window_size INTEGER DEFAULT 100,
                affected_records TEXT,
                recommended_actions TEXT
            )
        """)
        
        # Create indexes for performance
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_metric_type ON telemetry_records(metric_type)
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_timestamp ON telemetry_records(timestamp)
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_domain ON telemetry_records(domain)
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_session ON telemetry_records(session_id)
        """)
        
        conn.commit()
        conn.close()
    
    def record_metric(
        self,
        metric_type: MetricType,
        value: float,
        domain: Optional[str] = None,
        session_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        confidence: float = 0.9,
        sample_size: int = 1
    ) -> TelemetryRecord:
        """
        Record a single telemetry metric.
        
        Args:
            metric_type: Type of metric being recorded
            value: Metric value (typically 0.0-1.0)
            domain: Optional domain context
            session_id: Optional session identifier
            metadata: Additional contextual data
            confidence: Confidence in measurement (0.0-1.0)
            sample_size: Number of samples this represents
            
        Returns:
            The created TelemetryRecord
        """
        import uuid
        
        record = TelemetryRecord(
            record_id=f"TEL_{uuid.uuid4().hex[:12]}",
            metric_type=metric_type,
            value=value,
            domain=domain,
            session_id=session_id,
            metadata=metadata or {},
            confidence=confidence,
            sample_size=sample_size
        )
        
        # Store in memory
        self.records.append(record)
        
        # Persist to database
        self._save_record_to_db(record)
        
        # Check for anomalies
        self._check_for_anomalies(metric_type)
        
        return record
    
    def _save_record_to_db(self, record: TelemetryRecord):
        """Save record to SQLite database."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT OR REPLACE INTO telemetry_records 
            (record_id, metric_type, value, timestamp, domain, session_id, 
             metadata, confidence, sample_size)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            record.record_id,
            record.metric_type.value,
            record.value,
            record.timestamp,
            record.domain,
            record.session_id,
            json.dumps(record.metadata),
            record.confidence,
            record.sample_size
        ))
        
        conn.commit()
        conn.close()
    
    def query_metrics(
        self,
        metric_types: Optional[List[MetricType]] = None,
        time_range: Optional[Tuple[float, float]] = None,
        domain: Optional[str] = None,
        session_id: Optional[str] = None,
        limit: Optional[int] = None
    ) -> List[TelemetryRecord]:
        """
        Query telemetry records with filters.
        
        Args:
            metric_types: Filter by metric types (None = all)
            time_range: Filter by timestamp range (start, end)
            domain: Filter by domain
            session_id: Filter by session
            limit: Maximum number of records to return
            
        Returns:
            List of matching TelemetryRecords
        """
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        query = "SELECT * FROM telemetry_records WHERE 1=1"
        params = []
        
        if metric_types:
            placeholders = ",".join(["?"] * len(metric_types))
            query += f" AND metric_type IN ({placeholders})"
            params.extend([m.value for m in metric_types])
        
        if time_range:
            query += " AND timestamp BETWEEN ? AND ?"
            params.extend(time_range)
        
        if domain:
            query += " AND domain = ?"
            params.append(domain)
        
        if session_id:
            query += " AND session_id = ?"
            params.append(session_id)
        
        query += " ORDER BY timestamp DESC"
        
        if limit:
            query += " LIMIT ?"
            params.append(limit)
        
        cursor.execute(query, params)
        rows = cursor.fetchall()
        conn.close()
        
        # Convert to TelemetryRecord objects
        records = []
        for row in rows:
            record = TelemetryRecord(
                record_id=row[0],
                metric_type=MetricType(row[1]),
                value=row[2],
                timestamp=row[3],
                domain=row[4],
                session_id=row[5],
                metadata=json.loads(row[6]) if row[6] else {},
                confidence=row[7],
                sample_size=row[8]
            )
            records.append(record)
        
        return records
    
    def get_metric_statistics(
        self,
        metric_type: MetricType,
        window_size: int = 100
    ) -> Dict[str, float]:
        """
        Calculate statistics for a metric over recent window.
        
        Args:
            metric_type: Metric to analyze
            window_size: Number of recent records to include
            
        Returns:
            Dictionary with mean, std, min, max, median, trend
        """
        records = self.query_metrics(
            metric_types=[metric_type],
            limit=window_size
        )
        
        if not records:
            return {
                "mean": 0.0,
                "std": 0.0,
                "min": 0.0,
                "max": 0.0,
                "median": 0.0,
                "count": 0,
                "trend": "unknown"
            }
        
        values = [r.value for r in records]
        
        # Calculate trend (simple linear regression slope)
        trend = self._calculate_trend(values)
        
        return {
            "mean": statistics.mean(values),
            "std": statistics.stdev(values) if len(values) > 1 else 0.0,
            "min": min(values),
            "max": max(values),
            "median": statistics.median(values),
            "count": len(values),
            "trend": trend
        }
    
    def detect_anomalies(
        self,
        metric_type: MetricType,
        window_size: int = 100
    ) -> List[AnomalyDetection]:
        """
        Detect anomalies in metric using statistical methods.
        
        Uses z-score method: flags values beyond N standard deviations.
        
        Args:
            metric_type: Metric to analyze
            window_size: Window size for analysis
            
        Returns:
            List of detected anomalies
        """
        records = self.query_metrics(
            metric_types=[metric_type],
            limit=window_size
        )
        
        if len(records) < 10:  # Need minimum samples
            return []
        
        values = [r.value for r in records]
        mean = statistics.mean(values)
        std = statistics.stdev(values) if len(values) > 1 else 0.0
        
        if std == 0:
            return []
        
        # Get threshold configuration
        config = self.anomaly_thresholds.get(metric_type, {"std_multiplier": 2.0, "min_samples": 50})
        std_multiplier = config["std_multiplier"]
        
        # Detect anomalies (values beyond threshold)
        anomalies = []
        for record in records:
            z_score = abs(record.value - mean) / std
            
            if z_score > std_multiplier:
                # Determine severity based on deviation
                if z_score > std_multiplier * 2:
                    severity = "critical"
                elif z_score > std_multiplier * 1.5:
                    severity = "high"
                elif z_score > std_multiplier:
                    severity = "medium"
                else:
                    severity = "low"
                
                anomaly = AnomalyDetection(
                    anomaly_id=f"ANOM_{int(time.time())}_{len(anomalies)}",
                    metric_type=metric_type,
                    severity=severity,
                    description=f"{metric_type.value} anomaly detected: value {record.value:.3f} deviates {z_score:.2f} std from mean {mean:.3f}",
                    current_value=record.value,
                    expected_range=(mean - std_multiplier * std, mean + std_multiplier * std),
                    deviation_score=z_score,
                    window_size=len(records),
                    affected_records=[record.record_id],
                    recommended_actions=self._generate_recommendations(metric_type, severity, record.value, mean)
                )
                
                anomalies.append(anomaly)
                self.anomalies.append(anomaly)
                
                # Save to database
                self._save_anomaly_to_db(anomaly)
        
        return anomalies
    
    def _check_for_anomalies(self, metric_type: MetricType):
        """Check for anomalies after recording new metric."""
        config = self.anomaly_thresholds.get(metric_type, {"min_samples": 50})
        
        # Only check if we have enough samples
        stats = self.get_metric_statistics(metric_type, window_size=config["min_samples"])
        
        if stats["count"] >= 10:  # Minimum for anomaly detection
            self.detect_anomalies(metric_type, window_size=config["min_samples"])
    
    def _save_anomaly_to_db(self, anomaly: AnomalyDetection):
        """Save anomaly to database."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT OR REPLACE INTO anomalies
            (anomaly_id, metric_type, severity, description, detected_at,
             current_value, expected_min, expected_max, deviation_score,
             window_size, affected_records, recommended_actions)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            anomaly.anomaly_id,
            anomaly.metric_type.value,
            anomaly.severity,
            anomaly.description,
            anomaly.detected_at,
            anomaly.current_value,
            anomaly.expected_range[0],
            anomaly.expected_range[1],
            anomaly.deviation_score,
            anomaly.window_size,
            json.dumps(anomaly.affected_records),
            json.dumps(anomaly.recommended_actions)
        ))
        
        conn.commit()
        conn.close()
    
    def export_metrics(
        self,
        format: str = "csv",
        metric_types: Optional[List[MetricType]] = None,
        time_range: Optional[Tuple[float, float]] = None
    ) -> str:
        """
        Export telemetry data to CSV or JSON.
        
        Args:
            format: Export format ("csv" or "json")
            metric_types: Filter by metric types
            time_range: Filter by time range
            
        Returns:
            File path of exported data
        """
        records = self.query_metrics(
            metric_types=metric_types,
            time_range=time_range
        )
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        if format.lower() == "json":
            filename = f"runs/telemetry_export_{timestamp}.json"
            data = [asdict(r) for r in records]
            
            # Convert enums to strings
            for item in data:
                item['metric_type'] = item['metric_type'].value
            
            with open(filename, 'w') as f:
                json.dump(data, f, indent=2)
        
        else:  # CSV
            filename = f"runs/telemetry_export_{timestamp}.csv"
            
            with open(filename, 'w') as f:
                # Header
                f.write("record_id,metric_type,value,timestamp,domain,session_id,confidence,sample_size\n")
                
                # Data rows
                for r in records:
                    f.write(f"{r.record_id},{r.metric_type.value},{r.value},{r.timestamp},"
                           f"{r.domain or ''},{r.session_id or ''},{r.confidence},{r.sample_size}\n")
        
        return filename
    
    def get_dashboard_summary(self) -> Dict[str, Any]:
        """
        Get summary for dashboard display.
        
        Returns:
            Dashboard-ready summary with latest metrics and anomalies
        """
        summary = {
            "timestamp": time.time(),
            "total_records": len(self.records),
            "total_anomalies": len(self.anomalies),
            "metrics": {}
        }
        
        # Get latest statistics for each metric type
        for metric_type in MetricType:
            stats = self.get_metric_statistics(metric_type, window_size=100)
            recent_anomalies = [a for a in self.anomalies if a.metric_type == metric_type][-5:]
            
            summary["metrics"][metric_type.value] = {
                "latest_stats": stats,
                "recent_anomalies_count": len(recent_anomalies),
                "latest_anomalies": [
                    {
                        "severity": a.severity,
                        "description": a.description,
                        "detected_at": a.detected_at
                    }
                    for a in recent_anomalies
                ]
            }
        
        return summary
    
    def _calculate_trend(self, values: List[float]) -> str:
        """Calculate simple trend direction from values."""
        if len(values) < 5:
            return "insufficient_data"
        
        # Split into first half and second half
        mid = len(values) // 2
        first_half_mean = statistics.mean(values[:mid])
        second_half_mean = statistics.mean(values[mid:])
        
        # Calculate percentage change
        if first_half_mean == 0:
            return "stable"
        
        change = (second_half_mean - first_half_mean) / abs(first_half_mean)
        
        if change > 0.05:
            return "increasing"
        elif change < -0.05:
            return "decreasing"
        else:
            return "stable"
    
    def _generate_recommendations(
        self,
        metric_type: MetricType,
        severity: str,
        current_value: float,
        mean: float
    ) -> List[str]:
        """Generate actionable recommendations based on anomaly."""
        recommendations = []
        
        if metric_type == MetricType.CONTRADICTION_DENSITY:
            if current_value > mean:
                recommendations.append("Review active contradictions and prioritize resolution")
                recommendations.append("Check for contradiction suppression patterns")
            else:
                recommendations.append("Contradiction handling improving - maintain current practices")
        
        elif metric_type == MetricType.CONFIDENCE_CALIBRATION:
            if current_value < mean:
                recommendations.append("Recalibrate confidence estimates against evidence quality")
                recommendations.append("Review recent predictions for overconfidence")
        
        elif metric_type == MetricType.EPISTEMIC_RECOVERY:
            if current_value < mean:
                recommendations.append("Investigate slow recovery from recent failures")
                recommendations.append("Review failure museum for recurring patterns")
        
        elif metric_type == MetricType.IDENTITY_DRIFT:
            if current_value > mean:
                recommendations.append("URGENT: Review constitution adherence")
                recommendations.append("Check for goal drift or value misalignment")
        
        # Add severity-based recommendations
        if severity in ["high", "critical"]:
            recommendations.append(f"Consider pausing evolution until metric stabilizes")
            recommendations.append("Run diagnostic stress tests")
        
        return recommendations
    
    def cleanup_old_records(self, days_to_keep: int = 90):
        """
        Remove old records to manage database size.
        
        Args:
            days_to_keep: Number of days to retain
        """
        cutoff_time = time.time() - (days_to_keep * 24 * 3600)
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("DELETE FROM telemetry_records WHERE timestamp < ?", (cutoff_time,))
        deleted_count = cursor.rowcount
        
        conn.commit()
        conn.close()
        
        return deleted_count
