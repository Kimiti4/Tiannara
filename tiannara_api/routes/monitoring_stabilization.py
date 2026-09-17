"""
Monitoring & Stabilization API Routes

Provides REST endpoints for Tiannara's cognitive monitoring and stabilization systems:
- Cognitive Bandwidth Monitoring (communication health)
- Failure Museum (failure pattern preservation)
- Cognitive Immune System (anomaly detection)
- Deliberate Friction (anti-optimization)

Based on tiannara_core/monitoring/ modules.
"""

from fastapi import APIRouter, HTTPException
from typing import Dict, Any, Optional, List
from pydantic import BaseModel
import time

router = APIRouter(prefix="/monitoring", tags=["Monitoring & Stabilization"])

# Initialize health monitor
from tiannara_core.monitoring.health_metrics import CognitiveHealthMonitor
health_monitor = CognitiveHealthMonitor()

# Initialize reality anchor system
from tiannara_core.monitoring.reality_anchors import RealityAnchorSystem
reality_anchor_system = RealityAnchorSystem()


# Request/Response Models
class BandwidthEventRequest(BaseModel):
    event_id: str
    sender_id: str
    receiver_id: str
    comm_type: str  # "useful", "redundant", "contradictory", etc.
    message_size: int
    topic: Optional[str] = None
    novelty_score: Optional[float] = 0.5
    processing_time_ms: Optional[float] = None


class FailureRecordRequest(BaseModel):
    failure_id: str
    failure_type: str  # "failed_theory", "reward_hack", etc.
    title: str
    description: str
    domain: Optional[str] = None
    failure_severity: float = 0.5
    lesson_learned: Optional[str] = None
    prevention_strategy: Optional[str] = None
    tags: List[str] = []


class AnomalyCheckRequest(BaseModel):
    theory_id: str
    confidence: float
    evidence_count: int
    recent_predictions: Optional[List[bool]] = []
    total_contradictions: Optional[int] = 0


class HealthMetricsRequest(BaseModel):
    """Request model for health metrics calculation."""
    # Epistemic Integrity
    total_beliefs: int = 0
    verified_beliefs: int = 0
    contradicted_beliefs: int = 0
    evidence_quality_avg: float = 0.5
    
    # Contradiction Handling
    total_contradictions: int = 0
    resolved_contradictions: int = 0
    avg_resolution_time_hours: float = 24
    suppression_incidents: int = 0
    
    # Calibration
    predictions: List[Dict[str, float]] = []
    actual_outcomes: List[bool] = []
    
    # Causal Robustness
    total_causal_claims: int = 0
    validated_claims: int = 0
    refuted_claims: int = 0
    avg_causal_depth: float = 0.5
    
    # Diversity
    total_theories: int = 0
    unique_perspectives: int = 0
    minority_theories_retained: int = 0
    consensus_dominance_ratio: float = 0.5
    
    # Recovery
    total_failures: int = 0
    successful_recoveries: int = 0
    avg_recovery_time_hours: float = 12
    repeated_failures: int = 0
    
    # Uncertainty
    uncertain_predictions: int = 0
    total_predictions: int = 0
    uncertainty_appropriateness: float = 0.7
    acknowledged_contradictions: Optional[int] = 0
    reward_correlation: Optional[float] = None
    causal_depth: Optional[float] = None


# Initialize monitoring systems (singleton instances)
_bandwidth_monitor = None
_failure_museum = None
_cognitive_immune = None
_deliberate_friction = None


def get_bandwidth_monitor():
    """Get or initialize bandwidth monitor."""
    global _bandwidth_monitor
    if _bandwidth_monitor is None:
        try:
            from tiannara_core.monitoring.cognitive_bandwidth import CognitiveBandwidthMonitor
            _bandwidth_monitor = CognitiveBandwidthMonitor(window_size_seconds=60.0)
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"Bandwidth monitor unavailable: {str(e)}")
    return _bandwidth_monitor


def get_failure_museum():
    """Get or initialize failure museum."""
    global _failure_museum
    if _failure_museum is None:
        try:
            from tiannara_core.monitoring.failure_museum import FailureMuseum
            _failure_museum = FailureMuseum()
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"Failure museum unavailable: {str(e)}")
    return _failure_museum


def get_cognitive_immune():
    """Get or initialize cognitive immune system."""
    global _cognitive_immune
    if _cognitive_immune is None:
        try:
            from tiannara_core.monitoring.cognitive_immune import CognitiveImmuneSystem
            _cognitive_immune = CognitiveImmuneSystem()
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"Cognitive immune system unavailable: {str(e)}")
    return _cognitive_immune


def get_deliberate_friction():
    """Get or initialize deliberate friction system."""
    global _deliberate_friction
    if _deliberate_friction is None:
        try:
            from tiannara_core.monitoring.deliberate_friction import DeliberateFrictionSystem
            _deliberate_friction = DeliberateFrictionSystem()
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"Deliberate friction system unavailable: {str(e)}")
    return _deliberate_friction


# ========== BANDWIDTH MONITORING ENDPOINTS ==========

@router.post("/bandwidth/event")
async def record_bandwidth_event(event: BandwidthEventRequest):
    """
    Record a communication event for bandwidth monitoring.
    
    Tracks signal-to-noise ratio in multi-agent coordination.
    """
    try:
        monitor = get_bandwidth_monitor()
        
        from tiannara_core.monitoring.cognitive_bandwidth import CommunicationEvent, CommunicationType
        
        # Map string to enum
        comm_type_map = {
            'useful': CommunicationType.USEFUL,
            'redundant': CommunicationType.REDUNDANT,
            'contradictory': CommunicationType.CONTRADICTORY,
            'coordination': CommunicationType.COORDINATION,
            'query': CommunicationType.QUERY,
            'response': CommunicationType.RESPONSE
        }
        
        comm_type = comm_type_map.get(event.comm_type.lower(), CommunicationType.USEFUL)
        
        comm_event = CommunicationEvent(
            event_id=event.event_id,
            sender_id=event.sender_id,
            receiver_id=event.receiver_id,
            comm_type=comm_type,
            message_size=event.message_size,
            topic=event.topic,
            novelty_score=event.novelty_score or 0.5,
            processing_time_ms=event.processing_time_ms
        )
        
        monitor.record_communication(comm_event)
        
        return {
            'success': True,
            'message': 'Communication event recorded',
            'event_id': event.event_id
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to record event: {str(e)}")


@router.get("/bandwidth/metrics")
async def get_bandwidth_metrics():
    """
    Get current bandwidth metrics and health status.
    
    Returns signal-to-noise ratio, latency, coordination entropy, etc.
    """
    try:
        monitor = get_bandwidth_monitor()
        
        # Compute current metrics
        metrics = monitor.compute_metrics()
        
        # Detect alerts
        alerts = monitor.detect_alerts(metrics)
        
        # Get health report
        health = monitor.get_health_report()
        
        return {
            'success': True,
            'metrics': {
                'total_messages': metrics.total_messages,
                'signal_ratio': metrics.signal_ratio,
                'redundancy_ratio': metrics.redundancy_ratio,
                'contradiction_ratio': metrics.contradiction_ratio,
                'avg_latency_ms': metrics.avg_latency_ms,
                'coordination_entropy': metrics.coordination_entropy,
                'throughput_msgs_per_sec': metrics.throughput_msgs_per_sec
            },
            'health_status': health['status'],
            'active_alerts': len(alerts),
            'alerts': alerts
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get metrics: {str(e)}")


# ========== FAILURE MUSEUM ENDPOINTS ==========

@router.post("/failure-museum/archive")
async def archive_failure(failure: FailureRecordRequest):
    """
    Archive a failure in the failure museum.
    
    Stores failed theories, collapsed reasoning, reward hacks, etc.
    """
    try:
        museum = get_failure_museum()
        
        from tiannara_core.monitoring.failure_museum import FailureRecord, FailureType
        
        # Map string to enum
        type_map = {
            'failed_theory': FailureType.FAILED_THEORY,
            'collapsed_reasoning': FailureType.COLLAPSED_REASONING,
            'deceptive_shortcut': FailureType.DECEPTIVE_SHORTCUT,
            'reward_hack': FailureType.REWARD_HACK,
            'bad_synthesis': FailureType.BAD_SYNTHESIS,
            'hallucinated_causality': FailureType.HALLUCINATED_CAUSALITY,
            'contradiction_suppression': FailureType.CONTRADICTION_SUPPRESSION,
            'overconfidence_spike': FailureType.OVERCONFIDENCE_SPIKE
        }
        
        failure_type = type_map.get(failure.failure_type.lower(), FailureType.FAILED_THEORY)
        
        failure_record = FailureRecord(
            failure_id=failure.failure_id,
            failure_type=failure_type,
            title=failure.title,
            description=failure.description,
            domain=failure.domain,
            failure_severity=failure.failure_severity,
            lesson_learned=failure.lesson_learned,
            prevention_strategy=failure.prevention_strategy,
            tags=failure.tags
        )
        
        museum.archive_failure(failure_record)
        
        return {
            'success': True,
            'message': 'Failure archived successfully',
            'failure_id': failure.failure_id
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to archive failure: {str(e)}")


@router.get("/failure-museum/statistics")
async def get_failure_museum_stats():
    """
    Get failure museum statistics and analytics.
    
    Returns counts by type, severity distribution, replay stats, etc.
    """
    try:
        museum = get_failure_museum()
        
        stats = museum.get_statistics()
        
        return {
            'success': True,
            'statistics': stats
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get statistics: {str(e)}")


@router.get("/failure-museum/tour")
async def conduct_museum_tour(
    failure_type: Optional[str] = None,
    domain: Optional[str] = None,
    max_failures: int = 10
):
    """
    Conduct a guided tour through failures for learning.
    
    Returns curated list of failures to review.
    """
    try:
        museum = get_failure_museum()
        
        from tiannara_core.monitoring.failure_museum import FailureType
        
        # Map string to enum if provided
        ft_enum = None
        if failure_type:
            type_map = {
                'failed_theory': FailureType.FAILED_THEORY,
                'reward_hack': FailureType.REWARD_HACK,
                'collapsed_reasoning': FailureType.COLLAPSED_REASONING,
            }
            ft_enum = type_map.get(failure_type.lower())
        
        tour_results = museum.conduct_museum_tour(
            failure_type=ft_enum,
            domain=domain,
            max_failures=max_failures
        )
        
        return {
            'success': True,
            'tour_results': tour_results,
            'count': len(tour_results)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to conduct tour: {str(e)}")


# ========== COGNITIVE IMMUNE SYSTEM ENDPOINTS ==========

@router.post("/immune/check")
async def check_cognitive_anomalies(check_request: AnomalyCheckRequest):
    """
    Run cognitive immune system check on a theory.
    
    Detects overconfidence, self-confirming loops, reward hacking, etc.
    """
    try:
        immune = get_cognitive_immune()
        
        # Prepare theory data
        theory_data = {
            'theory_id': check_request.theory_id,
            'confidence': check_request.confidence,
            'evidence_count': check_request.evidence_count,
            'recent_predictions': check_request.recent_predictions or [],
            'total_contradictions': check_request.total_contradictions or 0,
            'acknowledged_contradictions': check_request.acknowledged_contradictions or 0,
        }
        
        # Add optional fields if provided
        if check_request.reward_correlation is not None:
            theory_data['reward_correlation'] = check_request.reward_correlation
        if check_request.causal_depth is not None:
            theory_data['causal_depth'] = check_request.causal_depth
        
        # Run full audit
        anomalies = immune.run_full_audit(theory_data)
        
        return {
            'success': True,
            'theory_id': check_request.theory_id,
            'anomalies_detected': len(anomalies),
            'anomalies': [a.to_dict() for a in anomalies],
            'severity_summary': {
                'high': sum(1 for a in anomalies if a.severity > 0.7),
                'medium': sum(1 for a in anomalies if 0.4 < a.severity <= 0.7),
                'low': sum(1 for a in anomalies if a.severity <= 0.4)
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Immune check failed: {str(e)}")


@router.get("/immune/health")
async def get_immune_health_report():
    """
    Get cognitive immune system health report.
    
    Returns overall cognitive health status and recent anomalies.
    """
    try:
        immune = get_cognitive_immune()
        
        report = immune.get_health_report()
        
        return {
            'success': True,
            'health_report': report
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get health report: {str(e)}")


# ========== DELIBERATE FRICTION ENDPOINTS ==========

@router.post("/friction/evaluate")
async def evaluate_with_friction(
    conclusion: str,
    available_evidence: int,
    supporting_sources: int,
    total_sources: int,
    mode: str = "conservative",
    alternative_hypotheses: Optional[List[str]] = None,
    contradiction_count: int = 0,
    initial_confidence: float = 0.5
):
    """
    Evaluate a conclusion with deliberate friction applied.
    
    Implements anti-optimization architecture with multiple reasoning modes.
    """
    try:
        friction = get_deliberate_friction()
        
        from tiannara_core.monitoring.deliberate_friction import ReasoningMode
        
        # Map string to enum
        mode_map = {
            'exploratory': ReasoningMode.EXPLORATORY,
            'skeptical': ReasoningMode.SKEPTICAL,
            'conservative': ReasoningMode.CONSERVATIVE,
            'creative': ReasoningMode.CREATIVE,
            'arbitration': ReasoningMode.ARBITRATION
        }
        
        reasoning_mode = mode_map.get(mode.lower(), ReasoningMode.CONSERVATIVE)
        
        # Set mode
        friction.set_mode(reasoning_mode)
        
        # Evaluate with friction
        decision = friction.evaluate_with_friction(
            conclusion=conclusion,
            available_evidence=available_evidence,
            supporting_sources=supporting_sources,
            total_sources=total_sources,
            alternative_hypotheses=alternative_hypotheses or [],
            contradiction_count=contradiction_count,
            initial_confidence=initial_confidence
        )
        
        return {
            'success': True,
            'decision': decision.to_dict(),
            'mode_used': mode,
            'recommendation': 'accept' if decision.conclusion_accepted else 'reject_or_revise'
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Friction evaluation failed: {str(e)}")


@router.get("/friction/modes")
async def get_available_modes():
    """
    Get information about available reasoning modes.
    
    Returns configuration for each mode (evidence requirements, thresholds, etc.).
    """
    try:
        from tiannara_core.monitoring.deliberate_friction import MODE_CONFIGS
        
        modes_info = {}
        for mode, config in MODE_CONFIGS.items():
            modes_info[mode.value] = config.to_dict()
        
        return {
            'success': True,
            'modes': modes_info
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get modes: {str(e)}")


@router.get("/friction/statistics")
async def get_friction_statistics():
    """
    Get deliberate friction system statistics.
    
    Returns mode usage, acceptance rates, decision history.
    """
    try:
        friction = get_deliberate_friction()
        
        stats = friction.get_mode_statistics()
        
        return {
            'success': True,
            'statistics': stats
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get statistics: {str(e)}")


# ========== COMBINED MONITORING DASHBOARD ==========

@router.get("/dashboard/overview")
async def get_monitoring_dashboard_overview():
    """
    Get comprehensive monitoring dashboard overview.
    
    Combines data from all monitoring systems for unified view.
    """
    try:
        # Get bandwidth metrics
        bandwidth_monitor = get_bandwidth_monitor()
        bandwidth_health = bandwidth_monitor.get_health_report()
        
        # Get immune system health
        immune = get_cognitive_immune()
        immune_health = immune.get_health_report()
        
        # Get failure museum stats
        museum = get_failure_museum()
        museum_stats = museum.get_statistics()
        
        # Get friction stats
        friction = get_deliberate_friction()
        friction_stats = friction.get_mode_statistics()
        
        return {
            'success': True,
            'timestamp': time.time(),
            'bandwidth': {
                'status': bandwidth_health.get('status', 'UNKNOWN'),
                'total_events': bandwidth_health.get('total_events_tracked', 0),
                'active_alerts': bandwidth_health.get('alert_count', 0)
            },
            'immune_system': {
                'status': immune_health.get('status', 'UNKNOWN'),
                'total_anomalies': immune_health.get('total_anomalies', 0),
                'critical_count': immune_health.get('critical_count', 0)
            },
            'failure_museum': {
                'total_failures': museum_stats.get('total_failures', 0),
                'total_replays': museum_stats.get('total_replays', 0),
                'by_type': museum_stats.get('by_type', {})
            },
            'deliberate_friction': {
                'current_mode': friction_stats.get('current_mode', 'unknown'),
                'total_decisions': friction_stats.get('total_decisions', 0),
                'mode_usage': friction_stats.get('mode_usage', {})
            },
            'overall_health': 'HEALTHY' if (
                bandwidth_health.get('status') in ['HEALTHY', 'NO_DATA'] and
                immune_health.get('status') in ['HEALTHY', 'MONITORING'] and
                museum_stats.get('total_failures', 0) < 100
            ) else 'NEEDS_ATTENTION'
        }
    except Exception as e:
        logger.error(f"Error getting stabilization status: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# HEALTH METRICS ENDPOINTS
# ============================================================================

@router.post("/health/calculate", response_model=Dict[str, Any])
async def calculate_health_metrics(request: HealthMetricsRequest):
    """
    Calculate comprehensive cognitive health metrics.
    
    Tracks 7 dimensions:
    - Epistemic integrity
    - Contradiction handling
    - Calibration accuracy
    - Causal robustness
    - Diversity preservation
    - Recovery quality
    - Uncertainty quality
    """
    try:
        # Convert request to metrics_data dict
        metrics_data = request.dict()
        
        # Generate health report
        report = health_monitor.generate_health_report(metrics_data)
        
        return {
            'success': True,
            'report_id': report.report_id,
            'overall_health_score': report.overall_health_score,
            'health_status': report.health_status,
            'health_trend': report.health_trend,
            'dimensions': {
                dim.value: {
                    'score': metric.score,
                    'trend': metric.trend,
                    'sample_size': metric.sample_size,
                    'warning_signals': metric.warning_signals
                }
                for dim, metric in report.dimensions.items()
            },
            'weakest_dimension': report.weakest_dimension.value if report.weakest_dimension else None,
            'strongest_dimension': report.strongest_dimension.value if report.strongest_dimension else None,
            'active_alerts': report.active_alerts,
            'recommendations': report.recommendations
        }
    
    except Exception as e:
        logger.error(f"Error calculating health metrics: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health/summary", response_model=Dict[str, Any])
async def get_health_summary():
    """Get current cognitive health summary."""
    try:
        summary = health_monitor.get_health_summary()
        
        return {
            'success': True,
            'data': summary
        }
    
    except Exception as e:
        logger.error(f"Error getting health summary: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health/history", response_model=Dict[str, Any])
async def get_health_history(limit: int = 10):
    """Get historical health reports."""
    try:
        # Get last N reports
        reports = health_monitor.metrics_history[-limit:]
        
        history = []
        for report in reports:
            history.append({
                'report_id': report.report_id,
                'timestamp': report.timestamp,
                'overall_score': report.overall_health_score,
                'status': report.health_status,
                'trend': report.health_trend
            })
        
        return {
            'success': True,
            'count': len(history),
            'data': history
        }
    
    except Exception as e:
        logger.error(f"Error getting health history: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# REALITY GROUNDING ENDPOINTS
# ============================================================================

@router.get("/reality/grounding", response_model=Dict[str, Any])
async def get_reality_grounding_status():
    """
    Get reality grounding status - external validation and drift detection.
    
    Shows:
    - External verification status per domain
    - Causal confidence scores
    - Failed predictions with root cause
    - World-model accuracy
    - Physical plausibility checks
    - Temporal consistency
    """
    try:
        # Get anchor statistics
        anchor_stats = reality_anchor_system.get_anchor_statistics()
        
        # Get recent drift reports
        drift_reports = reality_anchor_system.drift_reports[-10:]  # Last 10
        
        # Calculate overall grounding score
        total_anchors = len(reality_anchor_system.anchors)
        if total_anchors > 0:
            avg_validation = sum(a.validation_result for a in reality_anchor_system.anchors.values()) / total_anchors
        else:
            avg_validation = 1.0  # No anchors = no evidence of drift
        
        # Check for critical drift
        critical_drifts = [r for r in drift_reports if r.severity.value in ['severe', 'critical']]
        
        return {
            'success': True,
            'timestamp': time.time(),
            'overall_grounding_score': avg_validation,
            'drift_risk_level': 'CRITICAL' if len(critical_drifts) > 0 else 'LOW' if avg_validation > 0.8 else 'MODERATE',
            'external_verification': {
                'total_anchors': total_anchors,
                'average_validation': round(avg_validation, 3),
                'anchors_by_type': anchor_stats.get('anchors_by_type', {})
            },
            'temporal_consistency': {
                'total_records': anchor_stats.get('temporal_records_count', 0),
                'consistency_score': 0.94 if total_anchors > 0 else 1.0  # Placeholder calculation
            },
            'physical_constraints': {
                'loaded_constraints': anchor_stats.get('physical_constraints_loaded', 0),
                'violations_detected': 0  # Would need to track violations separately
            },
            'recent_drift_reports': [
                {
                    'report_id': r.report_id,
                    'severity': r.severity.value,
                    'drift_score': r.drift_score,
                    'affected_claims_count': len(r.affected_claims),
                    'timestamp': r.timestamp
                }
                for r in drift_reports
            ],
            'failed_predictions': [],  # Would integrate with prediction tracking
            'world_model_accuracy': 0.89 if total_anchors > 0 else None  # Placeholder
        }
    
    except Exception as e:
        logger.error(f"Error getting reality grounding status: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/reality/anchor", response_model=Dict[str, Any])
async def create_reality_anchor(anchor_data: Dict[str, Any]):
    """
    Create a new reality anchor to validate a claim against external evidence.
    
    Request body should include:
    - claim: The claim to validate
    - anchor_type: Type of anchor (external_validation, physical_constraint, etc.)
    - evidence_sources: List of sources used for validation
    """
    try:
        from tiannara_core.monitoring.reality_anchors import AnchorType
        
        # Map string to enum
        type_map = {
            'external_validation': AnchorType.EXTERNAL_VALIDATION,
            'physical_constraint': AnchorType.PHYSICAL_CONSTRAINT,
            'temporal_consistency': AnchorType.TEMPORAL_CONSISTENCY,
            'empirical_evidence': AnchorType.EMPIRICAL_EVIDENCE,
            'counterfactual_test': AnchorType.COUNTERFACTUAL_TEST,
            'peer_review': AnchorType.PEER_REVIEW
        }
        
        anchor_type_str = anchor_data.get('anchor_type', 'external_validation')
        anchor_type = type_map.get(anchor_type_str, AnchorType.EXTERNAL_VALIDATION)
        
        # Create anchor
        anchor = reality_anchor_system.create_anchor(
            claim=anchor_data.get('claim', ''),
            anchor_type=anchor_type,
            evidence_sources=anchor_data.get('evidence_sources', []),
            validation_result=anchor_data.get('validation_result', 0.5),
            confidence=anchor_data.get('confidence', 0.5)
        )
        
        return {
            'success': True,
            'anchor_id': anchor.anchor_id,
            'message': 'Reality anchor created successfully'
        }
    
    except Exception as e:
        logger.error(f"Error creating reality anchor: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/reality/drift-reports", response_model=Dict[str, Any])
async def get_drift_reports(limit: int = 20):
    """Get recent drift detection reports."""
    try:
        drift_reports = reality_anchor_system.drift_reports[-limit:]
        
        reports_data = [
            {
                'report_id': r.report_id,
                'severity': r.severity.value,
                'drift_score': r.drift_score,
                'affected_claims': r.affected_claims,
                'drift_patterns': r.drift_patterns,
                'recommended_actions': r.recommended_actions,
                'timestamp': r.timestamp
            }
            for r in drift_reports
        ]
        
        return {
            'success': True,
            'count': len(reports_data),
            'data': reports_data
        }
    
    except Exception as e:
        logger.error(f"Error getting drift reports: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# EPISTEMIC HEALTH DASHBOARD ENDPOINT (Combined View)
# ============================================================================

@router.get("/epistemic-health/dashboard", response_model=Dict[str, Any])
async def get_epistemic_health_dashboard():
    """
    Comprehensive epistemic health dashboard - AI vital signs monitor.
    
    Integrates:
    - Health metrics (7 dimensions)
    - Reality grounding status
    - Drift detection alerts
    - Calibration curves
    - Evidence quality distribution
    """
    try:
        # Get current health summary
        health_summary = health_monitor.get_health_summary()
        
        # Get reality grounding
        grounding_status = await get_reality_grounding_status()
        
        # Get recent health history for trends
        health_history_resp = await get_health_history(limit=20)
        health_history = health_history_resp.get('data', [])
        
        # Calculate calibration accuracy (placeholder - would need actual prediction data)
        calibration_accuracy = health_summary.get('dimensions', {}).get('calibration_accuracy', {}).get('score', 0.85)
        
        # Calculate hallucination probability (inverse of epistemic integrity)
        epistemic_score = health_summary.get('dimensions', {}).get('epistemic_integrity', {}).get('score', 0.9)
        hallucination_probability = max(0, 1 - epistemic_score)
        
        # Get dissent diversity (from diversity preservation dimension)
        dissent_diversity = health_summary.get('dimensions', {}).get('diversity_preservation', {}).get('score', 0.75)
        
        # Synthesis stability (based on contradiction handling)
        contradiction_score = health_summary.get('dimensions', {}).get('contradiction_handling', {}).get('score', 0.8)
        synthesis_stability = contradiction_score
        
        # Evidence quality average
        evidence_quality = health_summary.get('dimensions', {}).get('epistemic_integrity', {}).get('contributing_factors', {}).get('evidence_quality_avg', 0.78)
        
        return {
            'success': True,
            'timestamp': time.time(),
            'vital_signs': {
                'calibration_accuracy': round(calibration_accuracy, 3),
                'drift_risk_score': round(1 - grounding_status.get('overall_grounding_score', 0.9), 3),
                'hallucination_probability': round(hallucination_probability, 3),
                'evidence_quality_avg': round(evidence_quality, 3),
                'synthesis_stability': round(synthesis_stability, 3),
                'dissent_diversity_index': round(dissent_diversity, 3)
            },
            'health_dimensions': health_summary.get('dimensions', {}),
            'reality_grounding': grounding_status,
            'trend_analysis': {
                'health_history': health_history,
                'overall_trend': health_summary.get('health_trend', 'stable'),
                'weakest_dimension': health_summary.get('weakest_dimension'),
                'strongest_dimension': health_summary.get('strongest_dimension')
            },
            'alerts': health_summary.get('active_alerts', []),
            'recommendations': health_summary.get('recommendations', [])
        }
    
    except Exception as e:
        logger.error(f"Error getting epistemic health dashboard: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Dashboard overview failed: {str(e)}")
