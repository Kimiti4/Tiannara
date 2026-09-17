"""
MAPE-K Security Models for Tiannara Core

Implements autonomous adversarial security intelligence:
- Threat monitoring and detection
- Causal attack analysis
- Defensive evolution planning
- Countermeasure execution
- Security knowledge memory

Based on: tiannara_api/sec-evolve.md (Phase 15)

Date: May 1, 2026
Status: Week 28 Day 10 - MAPE-K Security Implementation
"""

from sqlalchemy import Column, String, Boolean, DateTime, Integer, Float, Text, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
import uuid
from datetime import datetime, timezone
from enum import Enum

from tiannara_api.database import Base


class ThreatLevel(str, Enum):
    """Threat severity levels."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class AttackType(str, Enum):
    """Categories of attacks."""
    PROMPT_INJECTION = "prompt_injection"
    JAILBREAK = "jailbreak"
    TOOL_ABUSE = "tool_abuse"
    MEMORY_POISONING = "memory_poisoning"
    SANDBOX_ESCAPE = "sandbox_escape"
    MULTI_AGENT_COORDINATION = "multi_agent_coordination"
    SELF_MODIFICATION_EXPLOIT = "self_modification_exploit"
    RESOURCE_EXHAUSTION = "resource_exhaustion"
    REFLECTION_POISONING = "reflection_poisoning"
    NOVEL_EMERGENT = "novel_emergent"


class DefenseAction(str, Enum):
    """Types of defensive actions."""
    POLICY_REWRITE = "policy_rewrite"
    PROMPT_PATCH = "prompt_patch"
    AGENT_ROUTING_CHANGE = "agent_routing_change"
    TOOL_PERMISSION_MODIFY = "tool_permission_modify"
    MODULE_ISOLATION = "module_isolation"
    MEMORY_RETRIEVAL_MUTATE = "memory_retrieval_mutate"
    ORCHESTRATION_HARDEN = "orchestration_harden"
    CONSTITUTIONAL_CONSTRAINT_ADD = "constitutional_constraint_add"


class SecurityEvent(Base):
    """
    Records all security-related events.
    
    This is the Monitor layer of MAPE-K.
    """
    __tablename__ = "security_events"
    
    id = Column(String, primary_key=True, default=lambda: f"se_{uuid.uuid4().hex[:16]}")
    
    # Event classification
    event_type = Column(String(100), nullable=False)  # attack_detected, defense_deployed, etc.
    attack_type = Column(SQLEnum(AttackType), nullable=True)
    threat_level = Column(SQLEnum(ThreatLevel), default=ThreatLevel.LOW)
    
    # Source information
    source_agent_id = Column(String(255), nullable=True)
    source_ip = Column(String(45), nullable=True)
    user_id = Column(String, nullable=True, index=True)  # Removed FK to avoid circular dependency
    workspace_id = Column(String, nullable=True, index=True)  # Removed FK to avoid circular dependency
    
    # Event details
    description = Column(Text, nullable=False)
    payload_sample = Column(Text, nullable=True)  # Sanitized attack payload
    target_component = Column(String(255), nullable=True)  # Which component was targeted
    
    # Detection metadata
    detection_method = Column(String(100), nullable=True)  # signature, anomaly, behavioral
    confidence_score = Column(Float, default=0.0)  # 0.0 to 1.0
    false_positive_probability = Column(Float, default=0.0)
    
    # Timestamps
    detected_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False, index=True)
    resolved_at = Column(DateTime, nullable=True)
    
    # Status
    is_resolved = Column(Boolean, default=False)
    resolution_action = Column(String(255), nullable=True)
    
    # Relationships (lazy-loaded to avoid circular imports)
    analyses = relationship("SecurityAnalysis", back_populates="event")
    
    def __repr__(self):
        return f"<SecurityEvent(type={self.event_type}, level={self.threat_level.value})>"
    
    def to_dict(self):
        """Convert to dictionary."""
        return {
            "id": self.id,
            "event_type": self.event_type,
            "attack_type": self.attack_type.value if self.attack_type else None,
            "threat_level": self.threat_level.value,
            "source_agent_id": self.source_agent_id,
            "source_ip": self.source_ip,
            "user_id": self.user_id,
            "workspace_id": self.workspace_id,
            "description": self.description,
            "payload_sample": self.payload_sample,
            "target_component": self.target_component,
            "detection_method": self.detection_method,
            "confidence_score": self.confidence_score,
            "false_positive_probability": self.false_positive_probability,
            "detected_at": self.detected_at.isoformat() if self.detected_at else None,
            "resolved_at": self.resolved_at.isoformat() if self.resolved_at else None,
            "is_resolved": self.is_resolved,
            "resolution_action": self.resolution_action,
        }


class SecurityAnalysis(Base):
    """
    Causal analysis of security events.
    
    This is the Analyze layer of MAPE-K.
    Uses causal intelligence to find root causes.
    """
    __tablename__ = "security_analyses"
    
    id = Column(String, primary_key=True, default=lambda: f"sa_{uuid.uuid4().hex[:16]}")
    
    # Linkage
    event_id = Column(String, ForeignKey("security_events.id"), nullable=False, index=True)
    
    # Analysis results
    root_cause = Column(Text, nullable=True)  # Identified root cause
    attack_chain = Column(Text, nullable=True)  # JSON array of attack steps
    vulnerability_type = Column(String(255), nullable=True)
    exploit_prerequisites = Column(Text, nullable=True)  # JSON list
    
    # Causal graph
    causal_graph_json = Column(Text, nullable=True)  # Full causal graph as JSON
    hidden_dependencies = Column(Text, nullable=True)  # Discovered dependencies
    
    # Severity assessment
    actual_severity = Column(Float, default=0.0)  # Calculated severity
    potential_impact = Column(Text, nullable=True)  # What could have happened
    
    # Analysis metadata
    analysis_method = Column(String(100), default="causal_inference")
    completed_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
    # Relationships
    event = relationship("SecurityEvent", back_populates="analyses")
    defenses = relationship("DefensePlan", back_populates="analysis")
    
    def __repr__(self):
        return f"<SecurityAnalysis(event={self.event_id}, severity={self.actual_severity})>"
    
    def to_dict(self):
        """Convert to dictionary."""
        return {
            "id": self.id,
            "event_id": self.event_id,
            "root_cause": self.root_cause,
            "attack_chain": self.attack_chain,
            "vulnerability_type": self.vulnerability_type,
            "exploit_prerequisites": self.exploit_prerequisites,
            "causal_graph_json": self.causal_graph_json,
            "hidden_dependencies": self.hidden_dependencies,
            "actual_severity": self.actual_severity,
            "potential_impact": self.potential_impact,
            "analysis_method": self.analysis_method,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
        }


class DefensePlan(Base):
    """
    Planned defensive actions.
    
    This is the Plan layer of MAPE-K.
    """
    __tablename__ = "defense_plans"
    
    id = Column(String, primary_key=True, default=lambda: f"dp_{uuid.uuid4().hex[:16]}")
    
    # Linkage
    analysis_id = Column(String, ForeignKey("security_analyses.id"), nullable=False, index=True)
    
    # Defense strategy
    defense_action = Column(SQLEnum(DefenseAction), nullable=False)
    description = Column(Text, nullable=False)
    target_component = Column(String(255), nullable=False)
    
    # Implementation details
    implementation_plan = Column(Text, nullable=True)  # Step-by-step plan
    required_permissions = Column(Text, nullable=True)  # JSON list
    estimated_risk = Column(Float, default=0.0)  # Risk of breaking functionality
    
    # Validation
    validation_criteria = Column(Text, nullable=True)  # How to verify success
    rollback_plan = Column(Text, nullable=True)  # How to undo if needed
    
    # Status
    status = Column(String(50), default="planned")  # planned, approved, executing, completed, failed
    approved_by = Column(String(255), nullable=True)  # Who approved (auto/human)
    
    # Timestamps
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    executed_at = Column(DateTime, nullable=True)
    
    # Relationships
    analysis = relationship("SecurityAnalysis", back_populates="defenses")
    executions = relationship("DefenseExecution", back_populates="plan")
    
    def __repr__(self):
        return f"<DefensePlan(action={self.defense_action.value}, status={self.status})>"
    
    def to_dict(self):
        """Convert to dictionary."""
        return {
            "id": self.id,
            "analysis_id": self.analysis_id,
            "defense_action": self.defense_action.value,
            "description": self.description,
            "target_component": self.target_component,
            "implementation_plan": self.implementation_plan,
            "required_permissions": self.required_permissions,
            "estimated_risk": self.estimated_risk,
            "validation_criteria": self.validation_criteria,
            "rollback_plan": self.rollback_plan,
            "status": self.status,
            "approved_by": self.approved_by,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "executed_at": self.executed_at.isoformat() if self.executed_at else None,
        }


class DefenseExecution(Base):
    """
    Records actual defense deployments.
    
    This is the Execute layer of MAPE-K.
    """
    __tablename__ = "defense_executions"
    
    id = Column(String, primary_key=True, default=lambda: f"de_{uuid.uuid4().hex[:16]}")
    
    # Linkage
    plan_id = Column(String, ForeignKey("defense_plans.id"), nullable=False, index=True)
    
    # Execution details
    execution_result = Column(String(50), nullable=False)  # success, partial, failed
    changes_applied = Column(Text, nullable=True)  # JSON of what changed
    execution_log = Column(Text, nullable=True)  # Detailed log
    
    # Validation results
    validation_passed = Column(Boolean, default=False)
    validation_details = Column(Text, nullable=True)
    
    # Side effects
    unintended_consequences = Column(Text, nullable=True)
    performance_impact = Column(Float, nullable=True)  # Performance change percentage
    
    # Timestamps
    started_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    completed_at = Column(DateTime, nullable=True)
    
    # Relationships
    plan = relationship("DefensePlan", back_populates="executions")
    
    def __repr__(self):
        return f"<DefenseExecution(plan={self.plan_id}, result={self.execution_result})>"
    
    def to_dict(self):
        """Convert to dictionary."""
        return {
            "id": self.id,
            "plan_id": self.plan_id,
            "execution_result": self.execution_result,
            "changes_applied": self.changes_applied,
            "execution_log": self.execution_log,
            "validation_passed": self.validation_passed,
            "validation_details": self.validation_details,
            "unintended_consequences": self.unintended_consequences,
            "performance_impact": self.performance_impact,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
        }


class SecurityKnowledge(Base):
    """
    Long-term security memory.
    
    This is the Knowledge layer of MAPE-K.
    Stores learned patterns, attack signatures, defense effectiveness.
    """
    __tablename__ = "security_knowledge"
    
    id = Column(String, primary_key=True, default=lambda: f"sk_{uuid.uuid4().hex[:16]}")
    
    # Knowledge type
    knowledge_type = Column(String(100), nullable=False)  # attack_pattern, defense_effectiveness, vulnerability
    
    # Content
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    content_json = Column(Text, nullable=True)  # Structured knowledge as JSON
    
    # Metadata
    confidence = Column(Float, default=0.0)  # How confident we are in this knowledge
    occurrence_count = Column(Integer, default=1)  # How many times observed
    last_observed = Column(DateTime, nullable=True)
    
    # Related entities
    related_attack_types = Column(Text, nullable=True)  # JSON list of AttackType values
    related_defenses = Column(Text, nullable=True)  # JSON list of defense IDs
    
    # Status
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)  # Has this been validated?
    
    # Timestamps
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    def __repr__(self):
        return f"<SecurityKnowledge(type={self.knowledge_type}, title='{self.title}')>"
    
    def to_dict(self):
        """Convert to dictionary."""
        return {
            "id": self.id,
            "knowledge_type": self.knowledge_type,
            "title": self.title,
            "description": self.description,
            "content_json": self.content_json,
            "confidence": self.confidence,
            "occurrence_count": self.occurrence_count,
            "last_observed": self.last_observed.isoformat() if self.last_observed else None,
            "related_attack_types": self.related_attack_types,
            "related_defenses": self.related_defenses,
            "is_active": self.is_active,
            "is_verified": self.is_verified,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


# Helper functions

def create_security_event(
    db_session,
    event_type: str,
    description: str,
    attack_type: AttackType = None,
    threat_level: ThreatLevel = ThreatLevel.LOW,
    **kwargs
) -> SecurityEvent:
    """Create a new security event."""
    event = SecurityEvent(
        event_type=event_type,
        description=description,
        attack_type=attack_type,
        threat_level=threat_level,
        **kwargs
    )
    
    db_session.add(event)
    db_session.commit()
    db_session.refresh(event)
    
    return event


def create_security_analysis(
    db_session,
    event_id: str,
    root_cause: str = None,
    **kwargs
) -> SecurityAnalysis:
    """Create security analysis for an event."""
    analysis = SecurityAnalysis(
        event_id=event_id,
        root_cause=root_cause,
        **kwargs
    )
    
    db_session.add(analysis)
    db_session.commit()
    db_session.refresh(analysis)
    
    return analysis
