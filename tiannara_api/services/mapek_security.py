"""
MAPE-K Security Service for Tiannara Core

Implements the autonomous security loop:
- Monitor: Detect threats and anomalies
- Analyze: Causal analysis of attacks  
- Plan: Generate defensive strategies
- Execute: Deploy countermeasures
- Knowledge: Learn and store security patterns

Based on: tiannara_api/sec-evolve.md (Phase 15)

Date: May 1, 2026
Status: Week 28 Day 10 - MAPE-K Security Implementation
"""

import json
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime, timezone, timedelta
from sqlalchemy.orm import Session

from tiannara_api.database.model_classes.mapek_security import (
    SecurityEvent,
    SecurityAnalysis,
    DefensePlan,
    DefenseExecution,
    SecurityKnowledge,
    ThreatLevel,
    AttackType,
    DefenseAction,
    create_security_event,
    create_security_analysis,
)

logger = logging.getLogger(__name__)


class MAPEKSecurityEngine:
    """
    Autonomous Adversarial Security Intelligence Engine.
    
    Implements continuous security evolution through MAPE-K loop.
    """
    
    def __init__(self, db_session: Session):
        self.db = db_session
    
    # ==================== MONITOR LAYER ====================
    
    def detect_threat(
        self,
        event_type: str,
        description: str,
        attack_type: Optional[AttackType] = None,
        threat_level: ThreatLevel = ThreatLevel.LOW,
        source_agent_id: Optional[str] = None,
        source_ip: Optional[str] = None,
        user_id: Optional[str] = None,
        workspace_id: Optional[str] = None,
        payload_sample: Optional[str] = None,
        target_component: Optional[str] = None,
        confidence_score: float = 0.5
    ) -> SecurityEvent:
        """
        Monitor: Detect and record a security threat.
        
        This is the entry point for the MAPE-K loop.
        """
        logger.info(f"🔍 MONITOR: Detected {event_type} (threat_level={threat_level.value})")
        
        event = create_security_event(
            db_session=self.db,
            event_type=event_type,
            description=description,
            attack_type=attack_type,
            threat_level=threat_level,
            source_agent_id=source_agent_id,
            source_ip=source_ip,
            user_id=user_id,
            workspace_id=workspace_id,
            payload_sample=payload_sample,
            target_component=target_component,
            confidence_score=confidence_score,
        )
        
        # Trigger analysis automatically for medium+ threats
        if threat_level in [ThreatLevel.MEDIUM, ThreatLevel.HIGH, ThreatLevel.CRITICAL]:
            self.analyze_threat(event.id)
        
        return event
    
    def check_known_patterns(self, event: SecurityEvent) -> Optional[SecurityKnowledge]:
        """Check if this matches any known attack patterns."""
        # Search for similar events in knowledge base
        similar_knowledge = self.db.query(SecurityKnowledge).filter(
            SecurityKnowledge.knowledge_type == "attack_pattern",
            SecurityKnowledge.is_active == True
        ).all()
        
        for knowledge in similar_knowledge:
            # Simple pattern matching (in production, use embeddings/similarity)
            if knowledge.title.lower() in event.description.lower():
                logger.info(f"✅ Matched known pattern: {knowledge.title}")
                return knowledge
        
        return None
    
    # ==================== ANALYZE LAYER ====================
    
    def analyze_threat(self, event_id: str) -> SecurityAnalysis:
        """
        Analyze: Perform causal analysis on security event.
        
        Uses causal intelligence to find root causes and attack chains.
        """
        logger.info(f"🧠 ANALYZE: Starting causal analysis for event {event_id}")
        
        event = self.db.query(SecurityEvent).filter(
            SecurityEvent.id == event_id
        ).first()
        
        if not event:
            raise ValueError(f"Event {event_id} not found")
        
        # Check for known patterns first
        known_pattern = self.check_known_patterns(event)
        
        # Perform causal analysis
        root_cause = self._identify_root_cause(event)
        attack_chain = self._reconstruct_attack_chain(event)
        vulnerability_type = self._classify_vulnerability(event)
        
        # Create analysis record
        analysis = create_security_analysis(
            db_session=self.db,
            event_id=event_id,
            root_cause=root_cause,
            attack_chain=json.dumps(attack_chain) if attack_chain else None,
            vulnerability_type=vulnerability_type,
            actual_severity=self._calculate_severity(event, known_pattern),
            potential_impact=self._assess_potential_impact(event),
        )
        
        logger.info(f"✅ Analysis complete: root_cause='{root_cause[:100]}...'")
        
        # Trigger planning
        self.plan_defense(analysis.id)
        
        return analysis
    
    def _identify_root_cause(self, event: SecurityEvent) -> str:
        """Identify the root cause of the security event."""
        # Simplified root cause identification
        # In production, this would use causal inference engine
        
        if event.attack_type == AttackType.PROMPT_INJECTION:
            return "Insufficient input validation allowing instruction override"
        elif event.attack_type == AttackType.JAILBREAK:
            return "Safety constraints bypassed through semantic manipulation"
        elif event.attack_type == AttackType.MEMORY_POISONING:
            return "Memory write permissions too permissive without validation"
        elif event.attack_type == AttackType.TOOL_ABUSE:
            return "Tool access controls insufficiently granular"
        else:
            return f"Unknown vulnerability in {event.target_component or 'system'}"
    
    def _reconstruct_attack_chain(self, event: SecurityEvent) -> List[Dict]:
        """Reconstruct the sequence of attack steps."""
        # Simplified chain reconstruction
        return [
            {
                "step": 1,
                "action": "initial_access",
                "method": event.attack_type.value if event.attack_type else "unknown",
                "timestamp": event.detected_at.isoformat() if event.detected_at else None
            }
        ]
    
    def _classify_vulnerability(self, event: SecurityEvent) -> str:
        """Classify the type of vulnerability exploited."""
        vulnerability_map = {
            AttackType.PROMPT_INJECTION: "input_validation_bypass",
            AttackType.JAILBREAK: "safety_constraint_weakness",
            AttackType.MEMORY_POISONING: "memory_integrity_failure",
            AttackType.TOOL_ABUSE: "authorization_bypass",
            AttackType.SANDBOX_ESCAPE: "isolation_failure",
        }
        
        return vulnerability_map.get(event.attack_type, "unknown_vulnerability")
    
    def _calculate_severity(self, event: SecurityEvent, known_pattern: Optional[SecurityKnowledge]) -> float:
        """Calculate actual severity score (0.0 to 1.0)."""
        base_severity = {
            ThreatLevel.LOW: 0.2,
            ThreatLevel.MEDIUM: 0.5,
            ThreatLevel.HIGH: 0.75,
            ThreatLevel.CRITICAL: 0.95,
        }.get(event.threat_level, 0.5)
        
        # Adjust based on confidence
        adjusted = base_severity * event.confidence_score
        
        # If known pattern, increase severity (we've seen this before)
        if known_pattern:
            adjusted = min(1.0, adjusted * 1.2)
        
        return round(adjusted, 2)
    
    def _assess_potential_impact(self, event: SecurityEvent) -> str:
        """Assess what could have happened if attack succeeded."""
        impact_map = {
            AttackType.PROMPT_INJECTION: "Unauthorized instruction execution, data exfiltration",
            AttackType.JAILBREAK: "Safety bypass, harmful content generation",
            AttackType.MEMORY_POISONING: "Long-term system corruption, persistent backdoor",
            AttackType.TOOL_ABUSE: "Unauthorized API access, resource abuse",
            AttackType.SANDBOX_ESCAPE: "System compromise, lateral movement",
        }
        
        return impact_map.get(event.attack_type, "Unknown impact")
    
    # ==================== PLAN LAYER ====================
    
    def plan_defense(self, analysis_id: str) -> DefensePlan:
        """
        Plan: Generate defensive strategy based on analysis.
        
        Creates actionable defense plans with implementation details.
        """
        logger.info(f"📋 PLAN: Generating defense plan for analysis {analysis_id}")
        
        analysis = self.db.query(SecurityAnalysis).filter(
            SecurityAnalysis.id == analysis_id
        ).first()
        
        if not analysis:
            raise ValueError(f"Analysis {analysis_id} not found")
        
        # Determine appropriate defense action
        defense_action = self._select_defense_action(analysis)
        
        # Generate implementation plan
        implementation_plan = self._generate_implementation_plan(analysis, defense_action)
        
        # Create defense plan
        plan = DefensePlan(
            analysis_id=analysis_id,
            defense_action=defense_action,
            description=f"Defense against {analysis.vulnerability_type}",
            target_component=analysis.event.target_component or "system",
            implementation_plan=json.dumps(implementation_plan),
            estimated_risk=self._estimate_defense_risk(defense_action),
            validation_criteria=self._define_validation_criteria(defense_action),
            rollback_plan=self._create_rollback_plan(defense_action),
            status="planned",
            approved_by="auto",  # Auto-approved for now
        )
        
        self.db.add(plan)
        self.db.commit()
        self.db.refresh(plan)
        
        logger.info(f"✅ Defense plan created: {defense_action.value}")
        
        # Trigger execution
        self.execute_defense(plan.id)
        
        return plan
    
    def _select_defense_action(self, analysis: SecurityAnalysis) -> DefenseAction:
        """Select the most appropriate defense action."""
        vulnerability_to_defense = {
            "input_validation_bypass": DefenseAction.PROMPT_PATCH,
            "safety_constraint_weakness": DefenseAction.CONSTITUTIONAL_CONSTRAINT_ADD,
            "memory_integrity_failure": DefenseAction.MEMORY_RETRIEVAL_MUTATE,
            "authorization_bypass": DefenseAction.TOOL_PERMISSION_MODIFY,
            "isolation_failure": DefenseAction.MODULE_ISOLATION,
        }
        
        return vulnerability_to_defense.get(
            analysis.vulnerability_type,
            DefenseAction.POLICY_REWRITE
        )
    
    def _generate_implementation_plan(self, analysis: SecurityAnalysis, action: DefenseAction) -> Dict:
        """Generate step-by-step implementation plan."""
        plans = {
            DefenseAction.PROMPT_PATCH: {
                "steps": [
                    "Identify vulnerable prompt templates",
                    "Add input sanitization rules",
                    "Implement instruction boundary markers",
                    "Test with adversarial examples"
                ]
            },
            DefenseAction.CONSTITUTIONAL_CONSTRAINT_ADD: {
                "steps": [
                    "Define new constitutional constraint",
                    "Add to constraint engine",
                    "Verify constraint cannot be bypassed",
                    "Monitor for false positives"
                ]
            },
            DefenseAction.MEMORY_RETRIEVAL_MUTATE: {
                "steps": [
                    "Audit memory write permissions",
                    "Add validation layer",
                    "Implement integrity checks",
                    "Enable anomaly detection"
                ]
            },
        }
        
        return plans.get(action, {"steps": ["Review and harden security policies"]})
    
    def _estimate_defense_risk(self, action: DefenseAction) -> float:
        """Estimate risk of breaking functionality."""
        risk_levels = {
            DefenseAction.POLICY_REWRITE: 0.3,
            DefenseAction.PROMPT_PATCH: 0.2,
            DefenseAction.TOOL_PERMISSION_MODIFY: 0.4,
            DefenseAction.MODULE_ISOLATION: 0.5,
            DefenseAction.CONSTITUTIONAL_CONSTRAINT_ADD: 0.1,
        }
        
        return risk_levels.get(action, 0.3)
    
    def _define_validation_criteria(self, action: DefenseAction) -> str:
        """Define how to verify defense success."""
        criteria = {
            DefenseAction.PROMPT_PATCH: "Passes all injection test cases",
            DefenseAction.CONSTITUTIONAL_CONSTRAINT_ADD: "Constraint enforced in 100% of test cases",
            DefenseAction.MEMORY_RETRIEVAL_MUTATE: "No unauthorized writes detected",
        }
        
        return criteria.get(action, "Defense deployed without errors")
    
    def _create_rollback_plan(self, action: DefenseAction) -> str:
        """Create rollback instructions."""
        return f"Revert {action.value} changes and restore previous configuration"
    
    # ==================== EXECUTE LAYER ====================
    
    def execute_defense(self, plan_id: str) -> DefenseExecution:
        """
        Execute: Deploy the planned defense.
        
        Actually implements the countermeasure.
        """
        logger.info(f"⚡ EXECUTE: Deploying defense plan {plan_id}")
        
        plan = self.db.query(DefensePlan).filter(
            DefensePlan.id == plan_id
        ).first()
        
        if not plan:
            raise ValueError(f"Plan {plan_id} not found")
        
        # Mark as executing
        plan.status = "executing"
        self.db.commit()
        
        try:
            # Simulate defense deployment
            # In production, this would actually modify system configuration
            execution_result = self._deploy_defense(plan)
            
            # Record execution
            execution = DefenseExecution(
                plan_id=plan_id,
                execution_result=execution_result,
                changes_applied=json.dumps({"action": plan.defense_action.value}),
                validation_passed=(execution_result == "success"),
                started_at=datetime.now(timezone.utc),
                completed_at=datetime.now(timezone.utc),
            )
            
            self.db.add(execution)
            
            # Update plan status
            plan.status = "completed" if execution_result == "success" else "failed"
            plan.executed_at = datetime.now(timezone.utc)
            
            self.db.commit()
            self.db.refresh(execution)
            
            logger.info(f"✅ Defense executed: {execution_result}")
            
            # Consolidate knowledge
            self.consolidate_knowledge(plan.analysis_id, execution)
            
            return execution
        
        except Exception as e:
            logger.error(f"❌ Defense execution failed: {str(e)}")
            
            # Record failure
            execution = DefenseExecution(
                plan_id=plan_id,
                execution_result="failed",
                execution_log=str(e),
                started_at=datetime.now(timezone.utc),
                completed_at=datetime.now(timezone.utc),
            )
            
            self.db.add(execution)
            plan.status = "failed"
            self.db.commit()
            
            raise
    
    def _deploy_defense(self, plan: DefensePlan) -> str:
        """Actually deploy the defense (simulated for now)."""
        # In production, this would:
        # - Modify prompt templates
        # - Update constitutional constraints
        # - Change tool permissions
        # - Isolate modules
        # etc.
        
        # For now, simulate successful deployment
        return "success"
    
    # ==================== KNOWLEDGE LAYER ====================
    
    def consolidate_knowledge(self, analysis_id: str, execution: DefenseExecution):
        """
        Knowledge: Learn from the security incident.
        
        Stores patterns, effectiveness, and insights for future use.
        """
        logger.info(f"📚 KNOWLEDGE: Consolidating security knowledge")
        
        analysis = self.db.query(SecurityAnalysis).filter(
            SecurityAnalysis.id == analysis_id
        ).first()
        
        if not analysis:
            return
        
        # Create/update attack pattern knowledge
        attack_knowledge = SecurityKnowledge(
            knowledge_type="attack_pattern",
            title=f"{analysis.event.attack_type.value if analysis.event.attack_type else 'Unknown'} Pattern",
            description=analysis.root_cause or "Observed attack pattern",
            content_json=json.dumps({
                "attack_type": analysis.event.attack_type.value if analysis.event.attack_type else None,
                "vulnerability": analysis.vulnerability_type,
                "severity": analysis.actual_severity,
            }),
            confidence=analysis.actual_severity,
            occurrence_count=1,
            last_observed=datetime.now(timezone.utc),
            related_attack_types=json.dumps([analysis.event.attack_type.value]) if analysis.event.attack_type else None,
            is_verified=(execution.execution_result == "success"),
        )
        
        self.db.add(attack_knowledge)
        
        # Create defense effectiveness knowledge
        defense_knowledge = SecurityKnowledge(
            knowledge_type="defense_effectiveness",
            title=f"Defense: {analysis.defenses[0].defense_action.value if analysis.defenses else 'Unknown'}",
            description=f"Effectiveness of {analysis.defenses[0].defense_action.value if analysis.defenses else 'unknown'} defense",
            content_json=json.dumps({
                "defense_action": analysis.defenses[0].defense_action.value if analysis.defenses else None,
                "success_rate": 1.0 if execution.execution_result == "success" else 0.0,
                "risk_level": analysis.defenses[0].estimated_risk if analysis.defenses else 0.3,
            }),
            confidence=0.8 if execution.execution_result == "success" else 0.3,
            occurrence_count=1,
            last_observed=datetime.now(timezone.utc),
            is_verified=(execution.execution_result == "success"),
        )
        
        self.db.add(defense_knowledge)
        self.db.commit()
        
        logger.info(f"✅ Knowledge consolidated: 2 entries created")
    
    def query_knowledge(self, query_type: str, limit: int = 10) -> List[Dict]:
        """Query security knowledge base."""
        knowledge_entries = self.db.query(SecurityKnowledge).filter(
            SecurityKnowledge.knowledge_type == query_type,
            SecurityKnowledge.is_active == True
        ).order_by(
            SecurityKnowledge.confidence.desc()
        ).limit(limit).all()
        
        return [k.to_dict() for k in knowledge_entries]
    
    # ==================== SECURITY DREAM CYCLE ====================
    
    def run_security_dream_cycle(self):
        """
        During idle time: replay attacks, mutate them, test defenses.
        
        This is autonomous immune training.
        """
        logger.info("💭 SECURITY DREAM CYCLE: Starting autonomous training")
        
        # Get recent unresolved events
        recent_events = self.db.query(SecurityEvent).filter(
            SecurityEvent.is_resolved == False
        ).order_by(
            SecurityEvent.detected_at.desc()
        ).limit(5).all()
        
        for event in recent_events:
            # Replay and mutate
            logger.info(f"  Replaying event: {event.id}")
            # TODO: Implement mutation and re-testing
            
        logger.info("✅ Security dream cycle complete")
