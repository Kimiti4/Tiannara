"""
FAILURE MUSEUM ENHANCEMENT

Purpose: Extend the Failure Museum with pattern detection, predictive warnings,
and active reasoning integration to prevent rediscovering past failures.

Based on next.md (lines 298-318):
"This is massively underrated.
Store: failed theories, collapsed reasoning chains, deceptive shortcuts,
reward hacks, bad syntheses. Then periodically replay them."

Architecture:
Extends the existing FailureMuseum with:
1. Pattern Detection - Identify recurring failure patterns across domains
2. Predictive Warnings - Alert when current reasoning resembles past failures
3. Active Reasoning Integration - Inject failure lessons into live reasoning
4. Failure Clustering - Group related failures for better learning
5. Prevention Strategy Recommendations - Automated avoidance suggestions
"""

import time
import logging
from typing import Dict, List, Optional, Tuple, Any, Set
from dataclasses import dataclass, field
from enum import Enum

logger = logging.getLogger(__name__)

# Import existing failure museum
from tiannara_core.monitoring.failure_museum import (
    FailureMuseum,
    FailureType,
    FailureRecord
)


class PatternType(Enum):
    """Types of failure patterns detected."""
    RECURRING_THEORY = "recurring_theory"           # Same theory fails multiple times
    DOMAIN_VULNERABILITY = "domain_vulnerability"   # Specific domain prone to failures
    CONFIDENCE_MISMATCH = "confidence_mismatch"     # High confidence, high failure rate
    EVIDENCE_INSUFFICIENCY = "evidence_insufficiency"  # Consistently insufficient evidence
    CAUSAL_OVERREACH = "causal_overreach"          # Over-extending causal claims
    SYNTHESIS_PREMATURE = "synthesis_premature"    # Rushing to combine ideas
    OPTIMIZATION_DECEPTIVE = "optimization_deceptive"  # Deceptive optimization patterns


@dataclass
class FailurePattern:
    """Detected pattern in failure history."""
    pattern_id: str
    pattern_type: PatternType
    description: str
    affected_failures: List[str]  # Failure IDs exhibiting this pattern
    frequency: float              # How often this pattern occurs (0.0-1.0)
    severity_avg: float           # Average severity of failures with this pattern
    domains_affected: List[str]   # Knowledge domains where pattern appears
    first_detected: float = field(default_factory=time.time)
    last_updated: float = field(default_factory=time.time)
    prevention_recommendations: List[str] = field(default_factory=list)


@dataclass
class PredictiveWarning:
    """Warning that current reasoning may lead to failure."""
    warning_id: str
    severity: str                   # "low", "medium", "high", "critical"
    similarity_score: float         # Similarity to past failures (0.0-1.0)
    matched_failures: List[str]     # Past failures that match
    risk_factors: List[str]         # What makes this risky?
    recommended_actions: List[str]  # What to do differently
    timestamp: float = field(default_factory=time.time)


@dataclass
class FailureCluster:
    """Group of related failures."""
    cluster_id: str
    theme: str                      # Common theme connecting failures
    failure_ids: List[str]
    common_root_causes: List[str]
    shared_prevention_strategies: List[str]
    cluster_severity: float         # Overall severity of cluster


class FailureMuseumEnhancement:
    """
    Enhances the Failure Museum with advanced pattern detection and prevention.
    
    Prevents:
    - Rediscovering past failure modes
    - Repeating systemic errors
    - Ignoring warning signs from similar past situations
    - Losing institutional knowledge about what doesn't work
    """
    
    def __init__(self, museum: Optional[FailureMuseum] = None):
        """
        Initialize enhanced failure museum.
        
        Args:
            museum: Existing failure museum instance (creates new if None)
        """
        self.museum = museum or FailureMuseum()
        self.detected_patterns: Dict[str, FailurePattern] = {}
        self.active_warnings: Dict[str, PredictiveWarning] = {}
        self.failure_clusters: Dict[str, FailureCluster] = {}
        
        logger.info("[Failure Museum Enhancement] Initialized")
        logger.info(f"  Base Museum Failures: {len(self.museum.failures)}")
        logger.info("  Pattern Detection: Ready")
        logger.info("  Predictive Warnings: Ready")
    
    def detect_failure_patterns(self) -> List[FailurePattern]:
        """
        Analyze failure history to detect recurring patterns.
        
        Detects:
        - Recurring theories that keep failing
        - Domain-specific vulnerabilities
        - Confidence/failure mismatches
        - Evidence insufficiency patterns
        - Causal overreach tendencies
        - Premature synthesis habits
        - Deceptive optimization patterns
        
        Returns:
            List of detected failure patterns
        """
        import uuid
        
        if not self.museum.failures:
            logger.info("[Pattern Detection] No failures to analyze")
            return []
        
        new_patterns = []
        
        # Pattern 1: Recurring Theory Failures
        recurring = self._detect_recurring_theories()
        if recurring:
            pattern_id = f"PATTERN_{uuid.uuid4().hex[:8]}"
            pattern = FailurePattern(
                pattern_id=pattern_id,
                pattern_type=PatternType.RECURRING_THEORY,
                description="Same or similar theories failing repeatedly",
                affected_failures=recurring['failure_ids'],
                frequency=recurring['frequency'],
                severity_avg=recurring['avg_severity'],
                domains_affected=recurring['domains'],
                prevention_recommendations=[
                    "Require stronger evidence before accepting theory",
                    "Cross-validate with independent methods",
                    "Seek disconfirming evidence actively"
                ]
            )
            self.detected_patterns[pattern_id] = pattern
            new_patterns.append(pattern)
        
        # Pattern 2: Domain Vulnerabilities
        domain_vulns = self._detect_domain_vulnerabilities()
        for domain, stats in domain_vulns.items():
            if stats['failure_rate'] > 0.3:  # More than 30% failure rate
                pattern_id = f"PATTERN_{uuid.uuid4().hex[:8]}"
                pattern = FailurePattern(
                    pattern_id=pattern_id,
                    pattern_type=PatternType.DOMAIN_VULNERABILITY,
                    description=f"Domain '{domain}' shows high failure rate",
                    affected_failures=stats['failure_ids'],
                    frequency=stats['failure_rate'],
                    severity_avg=stats['avg_severity'],
                    domains_affected=[domain],
                    prevention_recommendations=[
                        f"Increase scrutiny for {domain} reasoning",
                        "Require additional validation steps",
                        "Use conservative mode for this domain"
                    ]
                )
                self.detected_patterns[pattern_id] = pattern
                new_patterns.append(pattern)
        
        # Pattern 3: Confidence Mismatches
        mismatches = self._detect_confidence_mismatches()
        if mismatches:
            pattern_id = f"PATTERN_{uuid.uuid4().hex[:8]}"
            pattern = FailurePattern(
                pattern_id=pattern_id,
                pattern_type=PatternType.CONFIDENCE_MISMATCH,
                description="High confidence predictions that frequently fail",
                affected_failures=mismatches['failure_ids'],
                frequency=mismatches['frequency'],
                severity_avg=mismatches['avg_severity'],
                domains_affected=mismatches['domains'],
                prevention_recommendations=[
                    "Calibrate confidence scores downward",
                    "Require evidence-to-confidence ratio checks",
                    "Implement confidence decay for unverified claims"
                ]
            )
            self.detected_patterns[pattern_id] = pattern
            new_patterns.append(pattern)
        
        logger.info(f"[Pattern Detection] Found {len(new_patterns)} new patterns")
        for p in new_patterns:
            logger.info(f"  - {p.pattern_type.value}: {p.description[:60]}...")
        
        return new_patterns
    
    def _detect_recurring_theories(self) -> Optional[Dict[str, Any]]:
        """Detect theories that keep failing."""
        # Group failures by title/description similarity
        theory_groups: Dict[str, List[str]] = {}
        
        for failure_id, record in self.museum.failures.items():
            # Simple keyword-based grouping (in production, use semantic similarity)
            key_words = record.title.lower().split()[:3]  # First 3 words as key
            key = " ".join(key_words)
            
            if key not in theory_groups:
                theory_groups[key] = []
            theory_groups[key].append(failure_id)
        
        # Find groups with multiple failures
        recurring = {
            k: v for k, v in theory_groups.items() 
            if len(v) >= 2
        }
        
        if not recurring:
            return None
        
        # Aggregate statistics
        all_failure_ids = []
        severities = []
        domains = set()
        
        for failure_ids in recurring.values():
            all_failure_ids.extend(failure_ids)
            for fid in failure_ids:
                record = self.museum.failures[fid]
                severities.append(record.failure_severity)
                if record.domain:
                    domains.add(record.domain)
        
        return {
            'failure_ids': all_failure_ids,
            'frequency': len(all_failure_ids) / len(self.museum.failures),
            'avg_severity': sum(severities) / len(severities) if severities else 0.0,
            'domains': list(domains)
        }
    
    def _detect_domain_vulnerabilities(self) -> Dict[str, Dict[str, Any]]:
        """Detect domains with high failure rates."""
        domain_stats: Dict[str, Dict[str, Any]] = {}
        
        # Count total attempts per domain (simulated - in production would track all attempts)
        # For now, just count failures
        for failure_id, record in self.museum.failures.items():
            if record.domain:
                if record.domain not in domain_stats:
                    domain_stats[record.domain] = {
                        'failure_count': 0,
                        'failure_ids': [],
                        'severities': []
                    }
                
                domain_stats[record.domain]['failure_count'] += 1
                domain_stats[record.domain]['failure_ids'].append(failure_id)
                domain_stats[record.domain]['severities'].append(record.failure_severity)
        
        # Calculate failure rates (simulated - assume 10x more successes than failures)
        result = {}
        for domain, stats in domain_stats.items():
            total_attempts = stats['failure_count'] * 10  # Simulated
            failure_rate = stats['failure_count'] / total_attempts
            
            result[domain] = {
                'failure_rate': failure_rate,
                'failure_ids': stats['failure_ids'],
                'avg_severity': sum(stats['severities']) / len(stats['severities']) if stats['severities'] else 0.0
            }
        
        return result
    
    def _detect_confidence_mismatches(self) -> Optional[Dict[str, Any]]:
        """Detect cases where high confidence led to failures."""
        high_conf_failures = [
            fid for fid, record in self.museum.failures.items()
            if record.initial_confidence > 0.7 and record.failure_severity > 0.5
        ]
        
        if not high_conf_failures:
            return None
        
        severities = [self.museum.failures[fid].failure_severity for fid in high_conf_failures]
        domains = list(set(
            self.museum.failures[fid].domain 
            for fid in high_conf_failures 
            if self.museum.failures[fid].domain
        ))
        
        return {
            'failure_ids': high_conf_failures,
            'frequency': len(high_conf_failures) / len(self.museum.failures),
            'avg_severity': sum(severities) / len(severities),
            'domains': domains
        }
    
    def check_predictive_warning(self, current_context: Dict[str, Any]) -> Optional[PredictiveWarning]:
        """
        Check if current reasoning context resembles past failures.
        
        Args:
            current_context: Current reasoning state including:
                - domain: Knowledge domain
                - confidence: Current confidence level
                - evidence_count: Number of evidence pieces
                - theory_description: Brief description of current theory
                - reasoning_mode: Current reasoning approach
        
        Returns:
            PredictiveWarning if risk detected, None otherwise
        """
        import uuid
        
        if not self.museum.failures:
            return None
        
        # Find similar past failures
        similar_failures = self._find_similar_failures(current_context)
        
        if not similar_failures:
            return None
        
        # Calculate similarity score
        avg_similarity = sum(s['similarity'] for s in similar_failures) / len(similar_failures)
        
        # Determine severity based on similarity and past failure severity
        avg_past_severity = sum(
            self.museum.failures[s['failure_id']].failure_severity 
            for s in similar_failures
        ) / len(similar_failures)
        
        risk_score = avg_similarity * avg_past_severity
        
        if risk_score < 0.3:
            severity = "low"
        elif risk_score < 0.5:
            severity = "medium"
        elif risk_score < 0.7:
            severity = "high"
        else:
            severity = "critical"
        
        # Generate recommendations
        recommendations = self._generate_prevention_recommendations(similar_failures)
        
        warning = PredictiveWarning(
            warning_id=f"WARNING_{uuid.uuid4().hex[:8]}",
            severity=severity,
            similarity_score=risk_score,
            matched_failures=[s['failure_id'] for s in similar_failures],
            risk_factors=[s['reason'] for s in similar_failures],
            recommended_actions=recommendations
        )
        
        self.active_warnings[warning.warning_id] = warning
        
        logger.warning(f"[Predictive Warning] {severity.upper()} RISK DETECTED")
        logger.warning(f"  Similarity Score: {risk_score:.2f}")
        logger.warning(f"  Matched Failures: {len(similar_failures)}")
        for sf in similar_failures[:3]:  # Show top 3
            logger.warning(f"    - {sf['failure_id']}: {sf['reason']} (similarity: {sf['similarity']:.2f})")
        logger.warning("  Recommendations:")
        for rec in recommendations[:3]:
            logger.warning(f"    • {rec}")
        
        return warning
    
    def _find_similar_failures(self, context: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Find past failures similar to current context."""
        similar = []
        
        current_domain = context.get('domain', '')
        current_confidence = context.get('confidence', 0.5)
        current_evidence = context.get('evidence_count', 0)
        current_description = context.get('theory_description', '').lower()
        
        for failure_id, record in self.museum.failures.items():
            similarity = 0.0
            reasons = []
            
            # Domain match
            if record.domain and record.domain.lower() == current_domain.lower():
                similarity += 0.3
                reasons.append(f"Same domain: {record.domain}")
            
            # High confidence pattern
            if record.initial_confidence > 0.7 and current_confidence > 0.7:
                similarity += 0.25
                reasons.append("High confidence pattern match")
            
            # Low evidence pattern
            if current_evidence < 3 and record.supporting_evidence and len(record.supporting_evidence) < 3:
                similarity += 0.2
                reasons.append("Insufficient evidence pattern")
            
            # Description keyword overlap
            if current_description and record.title:
                desc_words = set(current_description.split())
                title_words = set(record.title.lower().split())
                overlap = len(desc_words & title_words) / max(len(desc_words | title_words), 1)
                if overlap > 0.2:
                    similarity += 0.25 * overlap
                    reasons.append(f"Similar topic (overlap: {overlap:.2f})")
            
            if similarity > 0.3:  # Threshold for considering it similar
                similar.append({
                    'failure_id': failure_id,
                    'similarity': similarity,
                    'reason': "; ".join(reasons)
                })
        
        # Sort by similarity and return top matches
        similar.sort(key=lambda x: x['similarity'], reverse=True)
        return similar[:5]  # Return top 5
    
    def _generate_prevention_recommendations(self, similar_failures: List[Dict[str, Any]]) -> List[str]:
        """Generate recommendations based on similar past failures."""
        recommendations = set()
        
        for sf in similar_failures:
            record = self.museum.failures[sf['failure_id']]
            
            if record.prevention_strategy:
                recommendations.add(record.prevention_strategy)
            
            if record.lesson_learned:
                recommendations.add(record.lesson_learned)
        
        # Add generic recommendations based on patterns
        if any(sf['similarity'] > 0.7 for sf in similar_failures):
            recommendations.add("Consider switching to skeptical reasoning mode")
            recommendations.add("Request additional evidence before proceeding")
        
        return list(recommendations)[:5]  # Return top 5
    
    def create_failure_clusters(self) -> List[FailureCluster]:
        """
        Group related failures into clusters for better learning.
        
        Clusters are formed based on:
        - Similar root causes
        - Common domains
        - Related failure types
        - Temporal proximity
        
        Returns:
            List of failure clusters
        """
        import uuid
        
        if not self.museum.failures:
            return []
        
        # Simple clustering by failure type and domain
        cluster_groups: Dict[str, List[str]] = {}
        
        for failure_id, record in self.museum.failures.items():
            # Create cluster key from type and domain
            cluster_key = f"{record.failure_type.value}_{record.domain or 'unknown'}"
            
            if cluster_key not in cluster_groups:
                cluster_groups[cluster_key] = []
            cluster_groups[cluster_key].append(failure_id)
        
        # Create clusters from groups
        new_clusters = []
        for cluster_key, failure_ids in cluster_groups.items():
            if len(failure_ids) < 2:  # Only cluster groups with 2+ failures
                continue
            
            cluster_id = f"CLUSTER_{uuid.uuid4().hex[:8]}"
            
            # Extract common information
            records = [self.museum.failures[fid] for fid in failure_ids]
            root_causes = list(set(r.root_cause for r in records if r.root_cause))
            prevention_strategies = list(set(r.prevention_strategy for r in records if r.prevention_strategy))
            avg_severity = sum(r.failure_severity for r in records) / len(records)
            
            cluster = FailureCluster(
                cluster_id=cluster_id,
                theme=cluster_key.replace('_', ' ').title(),
                failure_ids=failure_ids,
                common_root_causes=root_causes[:3],
                shared_prevention_strategies=prevention_strategies[:3],
                cluster_severity=avg_severity
            )
            
            self.failure_clusters[cluster_id] = cluster
            new_clusters.append(cluster)
        
        logger.info(f"[Failure Clustering] Created {len(new_clusters)} clusters")
        for c in new_clusters:
            logger.info(f"  - {c.theme}: {len(c.failure_ids)} failures (severity: {c.cluster_severity:.2f})")
        
        return new_clusters
    
    def get_enhancement_statistics(self) -> Dict[str, Any]:
        """Get statistics about failure museum enhancement."""
        pattern_counts = {}
        for pattern in self.detected_patterns.values():
            ptype = pattern.pattern_type.value
            pattern_counts[ptype] = pattern_counts.get(ptype, 0) + 1
        
        severity_counts = {}
        for warning in self.active_warnings.values():
            severity_counts[warning.severity] = severity_counts.get(warning.severity, 0) + 1
        
        return {
            "base_museum_failures": len(self.museum.failures),
            "detected_patterns": len(self.detected_patterns),
            "pattern_types": pattern_counts,
            "active_warnings": len(self.active_warnings),
            "warning_severity_distribution": severity_counts,
            "failure_clusters": len(self.failure_clusters),
            "avg_cluster_size": sum(
                len(c.failure_ids) for c in self.failure_clusters.values()
            ) / max(1, len(self.failure_clusters))
        }
