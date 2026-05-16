"""
System Integrity Monitor - 1,000-Step Mission

Tracks cognitive health metrics to prevent AI degradation over extended operation:
1. Identity Drift - Deviation from core identity/constraints
2. Causal Degradation - Quality of causal reasoning over time
3. Memory Corruption - Data integrity issues in memory systems
4. Confidence Inflation - Overconfidence in predictions/decisions
5. Contradiction Accumulation - Logical inconsistencies

Provides early warning system for system degradation and automated remediation triggers.
"""

import logging
from typing import Dict, Any, List, Optional
from datetime import datetime
import numpy as np

from tiannara_core.cache.redis_cache import cache

logger = logging.getLogger(__name__)


class IntegrityMonitor:
    """
    Monitors Tiannara Core system integrity across 5 critical dimensions.
    
    Implements the "1,000-step mission" tracking system to ensure
    long-term cognitive stability and prevent degradation.
    """
    
    def __init__(self):
        self.metrics_history = {
            "identity_drift": [],
            "causal_degradation": [],
            "memory_corruption": [],
            "confidence_inflation": [],
            "contradiction_accumulation": []
        }
        
        logger.info("✅ Integrity Monitor initialized (1,000-step mission tracking)")
    
    # =========================================================================
    # METRIC CALCULATION METHODS
    # =========================================================================
    
    async def check_identity_drift(self, current_state: Dict[str, Any]) -> float:
        """
        Measure deviation from core identity and operational constraints.
        
        Checks:
        - Constitutional adherence (safety constraints)
        - Goal alignment (mission consistency)
        - Behavioral patterns (expected vs actual)
        
        Args:
            current_state: Current system state snapshot
        
        Returns:
            Drift score (0-1, higher = more drift)
        """
        drift_score = 0.0
        
        try:
            # Check constitutional adherence
            if "constitution_violations" in current_state:
                violations = current_state["constitution_violations"]
                drift_score += min(len(violations) * 0.1, 0.5)
            
            # Check goal alignment
            if "goal_deviation" in current_state:
                drift_score += min(current_state["goal_deviation"], 0.3)
            
            # Check behavioral anomalies
            if "behavioral_anomalies" in current_state:
                anomalies = current_state["behavioral_anomalies"]
                drift_score += min(len(anomalies) * 0.05, 0.2)
            
            # Normalize to 0-1
            drift_score = min(drift_score, 1.0)
            
            # Record metric
            await cache.record_integrity_metric("identity_drift", drift_score)
            
            if drift_score > 0.6:
                logger.warning(f"⚠️  High identity drift detected: {drift_score:.2f}")
            
            return drift_score
            
        except Exception as e:
            logger.error(f"Failed to check identity drift: {e}")
            return 0.5  # Conservative estimate on error
    
    async def check_causal_degradation(self, recent_decisions: List[Dict]) -> float:
        """
        Assess quality of causal reasoning over time.
        
        Checks:
        - Causal chain completeness
        - Counterfactual reasoning quality
        - Intervention effect prediction accuracy
        
        Args:
            recent_decisions: List of recent decision records with outcomes
        
        Returns:
            Degradation score (0-1, higher = worse reasoning)
        """
        degradation_score = 0.0
        
        try:
            if not recent_decisions:
                return 0.0  # No data = no degradation detected
            
            # Check causal chain completeness
            incomplete_chains = sum(
                1 for d in recent_decisions 
                if d.get("causal_chain_complete", True) == False
            )
            degradation_score += (incomplete_chains / len(recent_decisions)) * 0.4
            
            # Check prediction accuracy (if outcomes available)
            if all("predicted_outcome" in d and "actual_outcome" in d for d in recent_decisions):
                accuracies = [
                    1.0 if d["predicted_outcome"] == d["actual_outcome"] else 0.0
                    for d in recent_decisions
                ]
                avg_accuracy = sum(accuracies) / len(accuracies)
                
                # Low accuracy suggests causal degradation
                if avg_accuracy < 0.6:
                    degradation_score += (1.0 - avg_accuracy) * 0.4
            
            # Check counterfactual quality
            poor_counterfactuals = sum(
                1 for d in recent_decisions
                if d.get("counterfactual_quality", 1.0) < 0.5
            )
            degradation_score += (poor_counterfactuals / len(recent_decisions)) * 0.2
            
            # Normalize
            degradation_score = min(degradation_score, 1.0)
            
            # Record metric
            await cache.record_integrity_metric("causal_degradation", degradation_score)
            
            if degradation_score > 0.6:
                logger.warning(f"⚠️  Causal reasoning degradation: {degradation_score:.2f}")
            
            return degradation_score
            
        except Exception as e:
            logger.error(f"Failed to check causal degradation: {e}")
            return 0.5
    
    async def check_memory_corruption(self, memory_samples: List[Dict]) -> float:
        """
        Detect data integrity issues in memory systems.
        
        Checks:
        - Data schema violations
        - Referential integrity (broken links)
        - Temporal consistency (timestamp ordering)
        - Value range violations
        
        Args:
            memory_samples: Sample of memory entries to validate
        
        Returns:
            Corruption score (0-1, higher = more corruption)
        """
        corruption_score = 0.0
        
        try:
            if not memory_samples:
                return 0.0
            
            # Check schema violations
            schema_violations = sum(
                1 for m in memory_samples
                if not self._validate_memory_schema(m)
            )
            corruption_score += (schema_violations / len(memory_samples)) * 0.4
            
            # Check temporal consistency
            temporal_issues = sum(
                1 for i in range(1, len(memory_samples))
                if memory_samples[i].get("timestamp", "") < memory_samples[i-1].get("timestamp", "")
            )
            corruption_score += min(temporal_issues * 0.1, 0.3)
            
            # Check for null/invalid values
            null_values = sum(
                1 for m in memory_samples
                if any(v is None for v in m.values() if isinstance(v, (str, int, float)))
            )
            corruption_score += (null_values / (len(memory_samples) * max(len(memory_samples[0]), 1))) * 0.3
            
            # Normalize
            corruption_score = min(corruption_score, 1.0)
            
            # Record metric
            await cache.record_integrity_metric("memory_corruption", corruption_score)
            
            if corruption_score > 0.5:
                logger.warning(f"⚠️  Memory corruption detected: {corruption_score:.2f}")
            
            return corruption_score
            
        except Exception as e:
            logger.error(f"Failed to check memory corruption: {e}")
            return 0.5
    
    async def check_confidence_inflation(self, predictions: List[Dict]) -> float:
        """
        Detect overconfidence in predictions and decisions.
        
        Checks:
        - Confidence vs accuracy calibration
        - Confidence distribution skew
        - Extreme confidence frequency
        
        Args:
            predictions: List of prediction records with confidence and outcomes
        
        Returns:
            Inflation score (0-1, higher = more overconfident)
        """
        inflation_score = 0.0
        
        try:
            if not predictions:
                return 0.0
            
            # Check calibration (confidence should match accuracy)
            if all("confidence" in p and "correct" in p for p in predictions):
                high_conf_correct = sum(
                    1 for p in predictions
                    if p["confidence"] > 0.8 and p["correct"]
                )
                high_conf_total = sum(
                    1 for p in predictions
                    if p["confidence"] > 0.8
                )
                
                if high_conf_total > 0:
                    high_conf_accuracy = high_conf_correct / high_conf_total
                    
                    # If claiming 90%+ confidence but only 60% accurate = inflation
                    avg_high_conf = sum(p["confidence"] for p in predictions if p["confidence"] > 0.8) / high_conf_total
                    
                    if avg_high_conf > 0.85 and high_conf_accuracy < 0.7:
                        inflation_score += 0.4
            
            # Check confidence distribution skew
            confidences = [p.get("confidence", 0.5) for p in predictions]
            if confidences:
                avg_confidence = sum(confidences) / len(confidences)
                
                # Systematically high confidence is suspicious
                if avg_confidence > 0.85:
                    inflation_score += 0.3
                
                # Low variance in confidence (always confident) is also suspicious
                if len(confidences) > 10:
                    conf_variance = np.var(confidences)
                    if conf_variance < 0.01:  # Very low variance
                        inflation_score += 0.2
            
            # Check extreme confidence frequency
            extreme_conf = sum(1 for c in confidences if c > 0.95)
            if extreme_conf > len(predictions) * 0.3:  # More than 30% extremely confident
                inflation_score += 0.2
            
            # Normalize
            inflation_score = min(inflation_score, 1.0)
            
            # Record metric
            await cache.record_integrity_metric("confidence_inflation", inflation_score)
            
            if inflation_score > 0.6:
                logger.warning(f"⚠️  Confidence inflation detected: {inflation_score:.2f}")
            
            return inflation_score
            
        except Exception as e:
            logger.error(f"Failed to check confidence inflation: {e}")
            return 0.5
    
    async def check_contradiction_accumulation(self, knowledge_base: List[Dict]) -> float:
        """
        Detect logical inconsistencies and contradictions.
        
        Checks:
        - Direct contradictions (A and not-A)
        - Temporal contradictions (facts changing without explanation)
        - Cross-domain contradictions
        
        Args:
            knowledge_base: Sample of knowledge entries to check
        
        Returns:
            Contradiction score (0-1, higher = more contradictions)
        """
        contradiction_score = 0.0
        
        try:
            if not knowledge_base or len(knowledge_base) < 2:
                return 0.0
            
            # Check for direct contradictions
            contradictions_found = 0
            total_comparisons = 0
            
            for i in range(len(knowledge_base)):
                for j in range(i + 1, min(i + 10, len(knowledge_base))):  # Check nearby entries
                    total_comparisons += 1
                    
                    entry_i = knowledge_base[i]
                    entry_j = knowledge_base[j]
                    
                    # Check if same topic but opposite claims
                    if (entry_i.get("topic") == entry_j.get("topic") and
                        entry_i.get("claim") and entry_j.get("claim")):
                        
                        claim_i = entry_i["claim"].lower()
                        claim_j = entry_j["claim"].lower()
                        
                        # Simple contradiction detection
                        if ("not" in claim_i and "not" not in claim_j) or \
                           ("not" in claim_j and "not" not in claim_i):
                            if any(word in claim_i for word in claim_j.split() if len(word) > 3):
                                contradictions_found += 1
            
            if total_comparisons > 0:
                contradiction_ratio = contradictions_found / total_comparisons
                contradiction_score += min(contradiction_ratio * 10, 0.5)  # Scale up
            
            # Check temporal contradictions (facts changing)
            topic_versions = {}
            for entry in knowledge_base:
                topic = entry.get("topic")
                if topic:
                    if topic not in topic_versions:
                        topic_versions[topic] = []
                    topic_versions[topic].append(entry.get("claim"))
            
            # Topics with many different claims suggest instability
            unstable_topics = sum(
                1 for claims in topic_versions.values()
                if len(set(claims)) > 3  # More than 3 different versions
            )
            contradiction_score += min(unstable_topics * 0.1, 0.3)
            
            # Normalize
            contradiction_score = min(contradiction_score, 1.0)
            
            # Record metric
            await cache.record_integrity_metric("contradiction_accumulation", contradiction_score)
            
            if contradiction_score > 0.5:
                logger.warning(f"⚠️  Contradiction accumulation: {contradiction_score:.2f}")
            
            return contradiction_score
            
        except Exception as e:
            logger.error(f"Failed to check contradictions: {e}")
            return 0.5
    
    def _validate_memory_schema(self, entry: Dict) -> bool:
        """Validate memory entry has required fields."""
        required_fields = ["id", "timestamp", "content"]
        return all(field in entry for field in required_fields)
    
    # =========================================================================
    # COMPREHENSIVE INTEGRITY CHECK
    # =========================================================================
    
    async def run_full_integrity_check(self, system_state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Run comprehensive integrity check across all 5 metrics.
        
        Args:
            system_state: Complete system state snapshot including:
                - constitution_violations
                - recent_decisions
                - memory_samples
                - predictions
                - knowledge_base
        
        Returns:
            Complete integrity report with all metrics and recommendations
        """
        logger.info("🔍 Running full integrity check (1,000-step mission)...")
        
        start_time = datetime.now()
        
        # Run all 5 checks in parallel conceptually (sequential here for simplicity)
        identity_drift = await self.check_identity_drift(system_state)
        causal_degradation = await self.check_causal_degradation(
            system_state.get("recent_decisions", [])
        )
        memory_corruption = await self.check_memory_corruption(
            system_state.get("memory_samples", [])
        )
        confidence_inflation = await self.check_confidence_inflation(
            system_state.get("predictions", [])
        )
        contradiction_accumulation = await self.check_contradiction_accumulation(
            system_state.get("knowledge_base", [])
        )
        
        elapsed = (datetime.now() - start_time).total_seconds()
        
        # Get summary from cache
        summary = await cache.get_integrity_metrics_summary()
        
        # Generate recommendations
        recommendations = self._generate_recommendations({
            "identity_drift": identity_drift,
            "causal_degradation": causal_degradation,
            "memory_corruption": memory_corruption,
            "confidence_inflation": confidence_inflation,
            "contradiction_accumulation": contradiction_accumulation
        })
        
        report = {
            "timestamp": datetime.now().isoformat(),
            "check_duration_seconds": round(elapsed, 2),
            "metrics": {
                "identity_drift": {
                    "value": identity_drift,
                    "status": cache._assess_metric_status("identity_drift", identity_drift)
                },
                "causal_degradation": {
                    "value": causal_degradation,
                    "status": cache._assess_metric_status("causal_degradation", causal_degradation)
                },
                "memory_corruption": {
                    "value": memory_corruption,
                    "status": cache._assess_metric_status("memory_corruption", memory_corruption)
                },
                "confidence_inflation": {
                    "value": confidence_inflation,
                    "status": cache._assess_metric_status("confidence_inflation", confidence_inflation)
                },
                "contradiction_accumulation": {
                    "value": contradiction_accumulation,
                    "status": cache._assess_metric_status("contradiction_accumulation", contradiction_accumulation)
                }
            },
            "overall_health": summary.get("overall_health", {}),
            "recommendations": recommendations,
            "action_required": any(r["priority"] == "high" for r in recommendations)
        }
        
        if report["action_required"]:
            logger.warning("⚠️  Integrity check requires action - see recommendations")
        else:
            logger.info("✅ System integrity healthy")
        
        return report
    
    def _generate_recommendations(self, metrics: Dict[str, float]) -> List[Dict[str, Any]]:
        """Generate actionable recommendations based on metric values."""
        recommendations = []
        
        if metrics["identity_drift"] > 0.6:
            recommendations.append({
                "metric": "identity_drift",
                "priority": "high",
                "action": "Review constitutional constraints and realign goals",
                "details": "Significant drift from core identity detected"
            })
        
        if metrics["causal_degradation"] > 0.6:
            recommendations.append({
                "metric": "causal_degradation",
                "priority": "high",
                "action": "Retrain causal reasoning models with recent data",
                "details": "Causal reasoning quality has degraded"
            })
        
        if metrics["memory_corruption"] > 0.5:
            recommendations.append({
                "metric": "memory_corruption",
                "priority": "high",
                "action": "Run memory integrity scan and repair corrupted entries",
                "details": "Memory corruption exceeds safe threshold"
            })
        
        if metrics["confidence_inflation"] > 0.6:
            recommendations.append({
                "metric": "confidence_inflation",
                "priority": "medium",
                "action": "Recalibrate confidence scoring using recent accuracy data",
                "details": "System showing signs of overconfidence"
            })
        
        if metrics["contradiction_accumulation"] > 0.5:
            recommendations.append({
                "metric": "contradiction_accumulation",
                "priority": "medium",
                "action": "Run contradiction resolution pass on knowledge base",
                "details": "Logical inconsistencies accumulating"
            })
        
        # If all metrics are healthy
        if not recommendations:
            recommendations.append({
                "metric": "all",
                "priority": "low",
                "action": "Continue monitoring - system healthy",
                "details": "All integrity metrics within normal range"
            })
        
        return recommendations
    
    async def auto_remediate(self, report: Dict[str, Any]) -> Dict[str, Any]:
        """
        Automatically apply remediation based on integrity report.
        
        Args:
            report: Output from run_full_integrity_check()
            
        Returns:
            Remediation actions taken and their results
        """
        metrics = report.get('metrics', {})
        recommendations = report.get('recommendations', [])
        
        actions_taken = []
        
        # Check for critical issues requiring immediate action
        critical_metrics = [
            m for m in metrics.values() 
            if m.get('status') == 'critical'
        ]
        
        if critical_metrics:
            logger.warning("🚨 CRITICAL: Initiating emergency remediation")
            
            # Reset confidence calibration
            await self._reset_confidence_calibration()
            actions_taken.append({
                'action': 'reset_confidence_calibration',
                'status': 'completed',
                'reason': 'Critical confidence inflation detected'
            })
            
            # Trigger memory consolidation
            await self._trigger_memory_consolidation()
            actions_taken.append({
                'action': 'trigger_memory_consolidation',
                'status': 'completed',
                'reason': 'Memory corruption above threshold'
            })
            
            # Flag for human review
            await cache.record_integrity_metric('human_review_required', 1.0)
            actions_taken.append({
                'action': 'flag_human_review',
                'status': 'completed',
                'reason': 'Critical system degradation requires manual inspection'
            })
        
        # Handle high-priority recommendations
        high_priority = [r for r in recommendations if r.get('priority') == 'high']
        if high_priority and not critical_metrics:
            logger.info("⚠️ HIGH RISK: Scheduling maintenance tasks")
            
            for rec in high_priority:
                metric = rec.get('metric', '')
                
                if metric == 'identity_drift':
                    await cache.record_integrity_metric('alignment_check_pending', 1.0)
                    actions_taken.append({
                        'action': 'queue_identity_alignment',
                        'status': 'queued',
                        'reason': 'Identity drift detected'
                    })
                
                elif metric == 'causal_degradation':
                    await cache.record_integrity_metric('causal_rebuild_pending', 1.0)
                    actions_taken.append({
                        'action': 'schedule_causal_rebuild',
                        'status': 'scheduled',
                        'reason': 'Causal degradation detected'
                    })
                
                elif metric == 'memory_corruption':
                    await self._trigger_memory_consolidation()
                    actions_taken.append({
                        'action': 'trigger_memory_consolidation',
                        'status': 'completed',
                        'reason': 'Memory corruption detected'
                    })
        
        # Handle medium-priority recommendations
        medium_priority = [r for r in recommendations if r.get('priority') == 'medium']
        if medium_priority:
            logger.info("📊 MEDIUM RISK: Enabling enhanced monitoring")
            
            await cache.record_integrity_metric('enhanced_monitoring', 1.0)
            actions_taken.append({
                'action': 'enable_enhanced_monitoring',
                'status': 'active',
                'reason': 'Moderate degradation signals'
            })
        
        return {
            'actions_taken': actions_taken,
            'next_check': datetime.now().isoformat(),
            'recommendation': 'Monitor system closely' if actions_taken else 'Normal operation resumed'
        }
    
    async def _reset_confidence_calibration(self):
        """Reset confidence calibration to prevent overconfidence."""
        try:
            # Store current calibration state
            await cache.record_integrity_metric(
                'previous_calibration',
                1.0,
                timestamp=datetime.now()
            )
            
            # Reset to conservative baseline
            await cache.record_integrity_metric(
                'confidence_baseline',
                0.5  # Baseline value
            )
            
            logger.info("✅ Confidence calibration reset to conservative baseline")
        except Exception as e:
            logger.error(f"❌ Failed to reset confidence calibration: {e}")
    
    async def _trigger_memory_consolidation(self):
        """Trigger memory consolidation to repair corruption."""
        try:
            # Signal memory engine to run consolidation
            await cache.record_integrity_metric(
                'consolidation_requested',
                1.0,
                timestamp=datetime.now()
            )
            
            logger.info("✅ Memory consolidation triggered")
        except Exception as e:
            logger.error(f"❌ Failed to trigger memory consolidation: {e}")


# Singleton instance
monitor = IntegrityMonitor()
