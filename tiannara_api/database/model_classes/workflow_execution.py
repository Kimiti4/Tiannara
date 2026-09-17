"""
Database models for workflow execution and alert rules.

Stores workflow executions, node results, alert rules, and alert history.

Date: April 30, 2026
Status: Week 30 - Database Persistence Layer
"""

from sqlalchemy import Column, String, Boolean, DateTime, Integer, Float, Text, JSON, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
import uuid
from datetime import datetime, timezone
from enum import Enum

from tiannara_api.database import Base


class WorkflowExecutionStatus(str, Enum):
    """Status of a workflow execution."""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class AlertRuleType(str, Enum):
    """Types of alert rules."""
    THRESHOLD = "threshold"
    ANOMALY = "anomaly"
    PATTERN = "pattern"
    SCHEDULED = "scheduled"


class AlertCondition(str, Enum):
    """Alert condition types."""
    GREATER_THAN = "greater_than"
    LESS_THAN = "less_than"
    EQUALS = "equals"
    NOT_EQUALS = "not_equals"
    CHANGE_PERCENT = "change_percent"
    ANOMALY_DETECTED = "anomaly_detected"


class Workflow(Base):
    """
    Stores user-created workflows.
    
    Each workflow has nodes and edges defining the execution graph.
    """
    __tablename__ = "workflows"
    
    id = Column(String, primary_key=True, default=lambda: f"wf_{uuid.uuid4().hex[:16]}")
    user_id = Column(String, nullable=False, index=True)
    name = Column(String, nullable=False)
    description = Column(Text, default="")
    nodes = Column(JSON, default=[])  # Array of node definitions
    edges = Column(JSON, default=[])  # Array of edge definitions
    status = Column(String, default="draft")  # draft, active, paused, archived
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    last_run = Column(DateTime, nullable=True)
    run_count = Column(Integer, default=0)
    
    # Relationships
    executions = relationship("WorkflowExecution", back_populates="workflow")


class WorkflowExecution(Base):
    """
    Stores individual workflow execution runs.
    
    Each execution has detailed node-level results.
    """
    __tablename__ = "workflow_executions"
    
    id = Column(String, primary_key=True, default=lambda: f"exec_{uuid.uuid4().hex[:16]}")
    workflow_id = Column(String, ForeignKey("workflows.id"), nullable=False, index=True)
    user_id = Column(String, nullable=False, index=True)
    status = Column(SQLEnum(WorkflowExecutionStatus), default=WorkflowExecutionStatus.PENDING)
    execution_mode = Column(String, default="sequential")  # sequential, parallel, hybrid
    node_results = Column(JSON, default={})  # Dict of node_id -> result
    started_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    completed_at = Column(DateTime, nullable=True)
    total_execution_time_ms = Column(Float, nullable=True)
    error = Column(Text, nullable=True)
    
    # Relationships
    workflow = relationship("Workflow", back_populates="executions")


class AlertRule(Base):
    """
    Custom alert rules created by users.
    
    Defines conditions that trigger notifications.
    """
    __tablename__ = "alert_rules"
    
    id = Column(String, primary_key=True, default=lambda: f"alert_{uuid.uuid4().hex[:16]}")
    user_id = Column(String, nullable=False, index=True)
    name = Column(String, nullable=False)
    description = Column(Text, default="")
    alert_type = Column(SQLEnum(AlertRuleType), nullable=False)
    metric = Column(String, nullable=False)
    condition = Column(SQLEnum(AlertCondition), nullable=False)
    threshold = Column(Float, nullable=True)
    notification_channels = Column(JSON, default=["dashboard"])  # ["dashboard", "email", "webhook"]
    enabled = Column(Boolean, default=True)
    cooldown_minutes = Column(Integer, default=60)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    last_triggered = Column(DateTime, nullable=True)
    trigger_count = Column(Integer, default=0)
    
    # Relationships
    alerts = relationship("AlertTrigger", back_populates="rule")


class AlertTrigger(Base):
    """
    Alert trigger history.
    
    Each time an alert rule is triggered, a record is created here.
    """
    __tablename__ = "alert_triggers"
    
    id = Column(String, primary_key=True, default=lambda: f"trigger_{uuid.uuid4().hex[:16]}")
    rule_id = Column(String, ForeignKey("alert_rules.id"), nullable=False, index=True)
    user_id = Column(String, nullable=False, index=True)
    metric = Column(String, nullable=False)
    current_value = Column(Float, nullable=False)
    threshold = Column(Float, nullable=True)
    condition = Column(String, nullable=False)
    triggered_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    notification_sent = Column(JSON, default={})  # Tracks which channels were notified
    
    # Relationships
    rule = relationship("AlertRule", back_populates="alerts")
