"""
COGNITIVE BANDWIDTH MONITORING SYSTEM

Purpose: Track signal-to-noise ratio in multi-agent coordination to prevent
communication overload and cognitive fragmentation at scale.

Based on next.md (lines 1128-1159) and fixes.md guidance:
"At 20, 50, 100 agents, measure signal-to-noise ratio.
Specifically:
- useful communication,
- redundant communication,
- contradictory communication,
- coordination latency.

You may discover cognitive bandwidth limits."

Architecture:
Monitors communication patterns across agent swarms to detect:
1. Signal quality degradation (useful vs noise ratio)
2. Coordination entropy (fragmentation risk)
3. Communication bottlenecks (latency spikes)
4. Redundancy overload (duplicate messages)
5. Contradiction density (conflicting signals)

This enables early detection of scalability limits before system collapse.
"""

import time
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum


class CommunicationType(Enum):
    """Types of inter-agent communication."""
    USEFUL = "useful"                   # Novel, actionable information
    REDUNDANT = "redundant"             # Duplicate/repeated information
    CONTRADICTORY = "contradictory"     # Conflicting with existing knowledge
    COORDINATION = "coordination"       # Task allocation/synchronization
    QUERY = "query"                     # Information requests
    RESPONSE = "response"               # Answers to queries


@dataclass
class CommunicationEvent:
    """Single communication event between agents."""
    event_id: str
    sender_id: str
    receiver_id: str
    comm_type: CommunicationType
    message_size: int                   # Approximate size in tokens/chars
    timestamp: float = field(default_factory=time.time)
    
    # Quality metrics
    novelty_score: float = 0.5          # How novel is this information? (0.0-1.0)
    actionability: float = 0.5          # How actionable is it? (0.0-1.0)
    relevance: float = 0.5              # Relevance to current task (0.0-1.0)
    
    # Metadata
    topic: Optional[str] = None         # Subject matter
    priority: float = 0.5               # Priority level (0.0-1.0)
    processing_time_ms: Optional[float] = None  # Time to process
    
    def to_dict(self) -> Dict:
        return {
            'event_id': self.event_id,
            'sender_id': self.sender_id,
            'receiver_id': self.receiver_id,
            'comm_type': self.comm_type.value,
            'message_size': self.message_size,
            'timestamp': self.timestamp,
            'novelty_score': self.novelty_score,
            'actionability': self.actionability,
            'relevance': self.relevance,
            'topic': self.topic,
            'priority': self.priority,
            'processing_time_ms': self.processing_time_ms
        }


@dataclass
class BandwidthMetrics:
    """Aggregated bandwidth metrics for a time window."""
    window_start: float
    window_end: float
    
    # Volume metrics
    total_messages: int = 0
    total_bytes: int = 0
    avg_message_size: float = 0.0
    
    # Quality metrics
    signal_ratio: float = 0.0           # Useful / Total (higher is better)
    redundancy_ratio: float = 0.0       # Redundant / Total (lower is better)
    contradiction_ratio: float = 0.0    # Contradictory / Total (lower is better)
    avg_novelty: float = 0.5            # Average novelty score
    avg_actionability: float = 0.5      # Average actionability
    
    # Performance metrics
    avg_latency_ms: float = 0.0         # Average processing latency
    max_latency_ms: float = 0.0         # Worst-case latency
    throughput_msgs_per_sec: float = 0.0
    
    # Health indicators
    coordination_entropy: float = 0.0   # Measure of fragmentation (0.0-1.0)
    bottleneck_detected: bool = False   # Is there a communication bottleneck?
    
    def to_dict(self) -> Dict:
        return {
            'window_start': self.window_start,
            'window_end': self.window_end,
            'total_messages': self.total_messages,
            'total_bytes': self.total_bytes,
            'avg_message_size': self.avg_message_size,
            'signal_ratio': self.signal_ratio,
            'redundancy_ratio': self.redundancy_ratio,
            'contradiction_ratio': self.contradiction_ratio,
            'avg_novelty': self.avg_novelty,
            'avg_actionability': self.avg_actionability,
            'avg_latency_ms': self.avg_latency_ms,
            'max_latency_ms': self.max_latency_ms,
            'throughput_msgs_per_sec': self.throughput_msgs_per_sec,
            'coordination_entropy': self.coordination_entropy,
            'bottleneck_detected': self.bottleneck_detected
        }


class CognitiveBandwidthMonitor:
    """
    Monitor cognitive bandwidth and communication health in multi-agent systems.
    
    Detects early warning signs of:
    - Communication overload
    - Signal degradation
    - Coordination fragmentation
    - Bottleneck formation
    """
    
    def __init__(self, window_size_seconds: float = 60.0):
        """
        Initialize bandwidth monitor.
        
        Args:
            window_size_seconds: Time window for metric aggregation
        """
        self.window_size = window_size_seconds
        self.events: List[CommunicationEvent] = []
        self.metrics_history: List[BandwidthMetrics] = []
        
        # Tracking structures
        self.message_hashes: Dict[str, int] = {}  # For redundancy detection
        self.agent_activity: Dict[str, int] = {}   # Messages per agent
        self.topic_distribution: Dict[str, int] = {}  # Topic frequency
        
        # Alert thresholds
        self.thresholds = {
            'min_signal_ratio': 0.3,        # Below this = too much noise
            'max_redundancy_ratio': 0.4,    # Above this = too repetitive
            'max_contradiction_ratio': 0.3, # Above this = too conflicting
            'max_avg_latency_ms': 1000.0,   # Above this = bottleneck
            'max_coordination_entropy': 0.7,# Above this = fragmentation risk
        }
    
    def record_communication(self, event: CommunicationEvent):
        """
        Record a communication event for monitoring.
        
        Args:
            event: Communication event to track
        """
        self.events.append(event)
        
        # Update tracking structures
        self._update_agent_activity(event.sender_id)
        self._update_agent_activity(event.receiver_id)
        
        if event.topic:
            self.topic_distribution[event.topic] = \
                self.topic_distribution.get(event.topic, 0) + 1
        
        # Check for redundancy (simple hash-based dedup)
        msg_hash = f"{event.sender_id}:{event.receiver_id}:{event.topic}"
        self.message_hashes[msg_hash] = self.message_hashes.get(msg_hash, 0) + 1
    
    def compute_metrics(self, window_start: Optional[float] = None, 
                       window_end: Optional[float] = None) -> BandwidthMetrics:
        """
        Compute aggregated metrics for a time window.
        
        Args:
            window_start: Start of time window (None = earliest event)
            window_end: End of time window (None = now)
            
        Returns:
            Aggregated bandwidth metrics
        """
        if window_end is None:
            window_end = time.time()
        if window_start is None:
            window_start = window_end - self.window_size
        
        # Filter events in window
        window_events = [
            e for e in self.events
            if window_start <= e.timestamp <= window_end
        ]
        
        if not window_events:
            return BandwidthMetrics(
                window_start=window_start,
                window_end=window_end
            )
        
        # Compute metrics
        metrics = self._aggregate_metrics(window_events, window_start, window_end)
        
        # Store in history
        self.metrics_history.append(metrics)
        
        return metrics
    
    def detect_alerts(self, metrics: BandwidthMetrics) -> List[Dict]:
        """
        Check metrics against thresholds and generate alerts.
        
        Args:
            metrics: Current bandwidth metrics
            
        Returns:
            List of alert dictionaries
        """
        alerts = []
        
        # Check signal quality
        if metrics.signal_ratio < self.thresholds['min_signal_ratio']:
            alerts.append({
                'type': 'LOW_SIGNAL_QUALITY',
                'severity': 'HIGH',
                'message': f"Signal ratio {metrics.signal_ratio:.2f} below threshold {self.thresholds['min_signal_ratio']}",
                'recommendation': 'Reduce message frequency or improve filtering'
            })
        
        # Check redundancy
        if metrics.redundancy_ratio > self.thresholds['max_redundancy_ratio']:
            alerts.append({
                'type': 'HIGH_REDUNDANCY',
                'severity': 'MEDIUM',
                'message': f"Redundancy ratio {metrics.redundancy_ratio:.2f} above threshold {self.thresholds['max_redundancy_ratio']}",
                'recommendation': 'Implement message deduplication or caching'
            })
        
        # Check contradictions
        if metrics.contradiction_ratio > self.thresholds['max_contradiction_ratio']:
            alerts.append({
                'type': 'HIGH_CONTRADICTION',
                'severity': 'HIGH',
                'message': f"Contradiction ratio {metrics.contradiction_ratio:.2f} above threshold {self.thresholds['max_contradiction_ratio']}",
                'recommendation': 'Resolve conflicting beliefs or partition agent groups'
            })
        
        # Check latency
        if metrics.avg_latency_ms > self.thresholds['max_avg_latency_ms']:
            alerts.append({
                'type': 'LATENCY_BOTTLENECK',
                'severity': 'CRITICAL',
                'message': f"Average latency {metrics.avg_latency_ms:.0f}ms exceeds threshold {self.thresholds['max_avg_latency_ms']}ms",
                'recommendation': 'Scale horizontally or reduce coordination complexity'
            })
        
        # Check coordination entropy
        if metrics.coordination_entropy > self.thresholds['max_coordination_entropy']:
            alerts.append({
                'type': 'COORDINATION_FRAGMENTATION',
                'severity': 'HIGH',
                'message': f"Coordination entropy {metrics.coordination_entropy:.2f} indicates fragmentation risk",
                'recommendation': 'Introduce hierarchical coordination or subgroup specialization'
            })
        
        return alerts
    
    def get_health_report(self) -> Dict:
        """
        Generate comprehensive health report.
        
        Returns:
            Dictionary with overall health assessment
        """
        if not self.metrics_history:
            return {
                'status': 'NO_DATA',
                'message': 'No metrics collected yet'
            }
        
        latest_metrics = self.metrics_history[-1]
        alerts = self.detect_alerts(latest_metrics)
        
        # Determine overall status
        critical_alerts = [a for a in alerts if a['severity'] == 'CRITICAL']
        high_alerts = [a for a in alerts if a['severity'] == 'HIGH']
        
        if critical_alerts:
            status = 'CRITICAL'
        elif high_alerts:
            status = 'WARNING'
        else:
            status = 'HEALTHY'
        
        return {
            'status': status,
            'timestamp': time.time(),
            'metrics': latest_metrics.to_dict(),
            'alerts': alerts,
            'alert_count': len(alerts),
            'total_events_tracked': len(self.events),
            'windows_analyzed': len(self.metrics_history)
        }
    
    def _update_agent_activity(self, agent_id: str):
        """Track message count per agent."""
        self.agent_activity[agent_id] = self.agent_activity.get(agent_id, 0) + 1
    
    def _aggregate_metrics(self, events: List[CommunicationEvent],
                          window_start: float, window_end: float) -> BandwidthMetrics:
        """Aggregate individual events into summary metrics."""
        total_messages = len(events)
        total_bytes = sum(e.message_size for e in events)
        
        # Count by type
        type_counts = {}
        for e in events:
            type_counts[e.comm_type] = type_counts.get(e.comm_type, 0) + 1
        
        # Compute ratios
        useful_count = type_counts.get(CommunicationType.USEFUL, 0)
        redundant_count = type_counts.get(CommunicationType.REDUNDANT, 0)
        contradictory_count = type_counts.get(CommunicationType.CONTRADICTORY, 0)
        
        signal_ratio = useful_count / total_messages if total_messages > 0 else 0.0
        redundancy_ratio = redundant_count / total_messages if total_messages > 0 else 0.0
        contradiction_ratio = contradictory_count / total_messages if total_messages > 0 else 0.0
        
        # Average scores
        avg_novelty = sum(e.novelty_score for e in events) / total_messages
        avg_actionability = sum(e.actionability for e in events) / total_messages
        
        # Latency metrics
        latencies = [e.processing_time_ms for e in events if e.processing_time_ms is not None]
        avg_latency = sum(latencies) / len(latencies) if latencies else 0.0
        max_latency = max(latencies) if latencies else 0.0
        
        # Throughput
        duration = window_end - window_start
        throughput = total_messages / duration if duration > 0 else 0.0
        
        # Coordination entropy (simplified: based on topic distribution uniformity)
        topic_counts = list(self.topic_distribution.values())
        if topic_counts:
            total_topics = sum(topic_counts)
            probabilities = [c / total_topics for c in topic_counts]
            # Shannon entropy normalized to [0, 1]
            import math
            entropy = -sum(p * math.log2(p) for p in probabilities if p > 0)
            max_entropy = math.log2(len(topic_counts)) if len(topic_counts) > 1 else 1.0
            coordination_entropy = entropy / max_entropy if max_entropy > 0 else 0.0
        else:
            coordination_entropy = 0.0
        
        # Bottleneck detection
        bottleneck = avg_latency > self.thresholds['max_avg_latency_ms']
        
        return BandwidthMetrics(
            window_start=window_start,
            window_end=window_end,
            total_messages=total_messages,
            total_bytes=total_bytes,
            avg_message_size=total_bytes / total_messages if total_messages > 0 else 0.0,
            signal_ratio=signal_ratio,
            redundancy_ratio=redundancy_ratio,
            contradiction_ratio=contradiction_ratio,
            avg_novelty=avg_novelty,
            avg_actionability=avg_actionability,
            avg_latency_ms=avg_latency,
            max_latency_ms=max_latency,
            throughput_msgs_per_sec=throughput,
            coordination_entropy=coordination_entropy,
            bottleneck_detected=bottleneck
        )
