"""
Analytics Models for Tiannara API

Tracks usage metrics, generates reports, and provides insights.
Supports custom report building and data export.

Date: May 1, 2026
Status: Week 28 Day 6 - Advanced Analytics Implementation
"""

from sqlalchemy import Column, String, Boolean, DateTime, Integer, Float, ForeignKey, Text, Enum as SQLEnum
from sqlalchemy.orm import relationship
import uuid
from datetime import datetime, timezone
from enum import Enum

from tiannara_api.database import Base


class MetricType(str, Enum):
    """Types of metrics that can be tracked."""
    # Usage Metrics
    API_CALLS = "api_calls"
    WORKSPACE_CREATIONS = "workspace_creations"
    MEMBER_INVITATIONS = "member_invitations"
    PREDICTIONS_RUN = "predictions_run"
    
    # Performance Metrics
    RESPONSE_TIME = "response_time"
    ERROR_RATE = "error_rate"
    UPTIME = "uptime"
    
    # Business Metrics
    REVENUE = "revenue"
    ACTIVE_USERS = "active_users"
    CONVERSION_RATE = "conversion_rate"


class ReportFormat(str, Enum):
    """Supported report export formats."""
    JSON = "json"
    CSV = "csv"
    PDF = "pdf"
    EXCEL = "excel"


class UsageMetric(Base):
    """
    Stores aggregated usage metrics by time period.
    
    Enables trend analysis and reporting.
    """
    __tablename__ = "usage_metrics"
    
    id = Column(String, primary_key=True, default=lambda: f"metric_{uuid.uuid4().hex[:16]}")
    
    # Metric identification
    metric_type = Column(SQLEnum(MetricType), nullable=False, index=True)
    resource_type = Column(String(50), nullable=True)  # workspace, user, api_endpoint
    resource_id = Column(String, nullable=True, index=True)
    
    # Time period
    period_start = Column(DateTime, nullable=False, index=True)
    period_end = Column(DateTime, nullable=False)
    granularity = Column(String(20), default="hour")  # minute, hour, day, week, month
    
    # Metric values
    count = Column(Integer, default=0)
    value = Column(Float, default=0.0)  # For metrics like response time
    min_value = Column(Float, nullable=True)
    max_value = Column(Float, nullable=True)
    avg_value = Column(Float, nullable=True)
    
    # Metadata
    metric_metadata = Column("metadata", Text, nullable=True)  # JSON string with additional context
    
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    
    def __repr__(self):
        return f"<UsageMetric(type={self.metric_type.value}, period={self.period_start})>"
    
    def to_dict(self):
        """Convert metric to dictionary."""
        return {
            "id": self.id,
            "metric_type": self.metric_type.value,
            "resource_type": self.resource_type,
            "resource_id": self.resource_id,
            "period_start": self.period_start.isoformat() if self.period_start else None,
            "period_end": self.period_end.isoformat() if self.period_end else None,
            "granularity": self.granularity,
            "count": self.count,
            "value": self.value,
            "min_value": self.min_value,
            "max_value": self.max_value,
            "avg_value": self.avg_value,
            "metadata": self.metric_metadata,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class SavedReport(Base):
    """
    User-saved custom report configurations.
    
    Allows users to create and reuse custom report templates.
    """
    __tablename__ = "saved_reports"
    
    id = Column(String, primary_key=True, default=lambda: f"report_{uuid.uuid4().hex[:16]}")
    
    # Report identification
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    
    # Owner
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    
    # Report configuration (stored as JSON)
    metrics = Column(Text, nullable=False)  # List of metrics to include
    filters = Column(Text, nullable=True)  # Filter criteria
    group_by = Column(String(100), nullable=True)  # Grouping field
    time_range = Column(String(50), default="last_30_days")  # Time range preset
    chart_type = Column(String(50), default="line")  # line, bar, pie, table
    
    # Sharing
    is_public = Column(Boolean, default=False)
    shared_with = Column(Text, nullable=True)  # JSON list of user IDs
    
    # Timestamps
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    last_run_at = Column(DateTime, nullable=True)
    
    # Relationships
    user = relationship("User", backref="saved_reports")
    
    def __repr__(self):
        return f"<SavedReport(name='{self.name}', user={self.user_id})>"
    
    def to_dict(self):
        """Convert report to dictionary."""
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "user_id": self.user_id,
            "metrics": self.metrics,
            "filters": self.filters,
            "group_by": self.group_by,
            "time_range": self.time_range,
            "chart_type": self.chart_type,
            "is_public": self.is_public,
            "shared_with": self.shared_with,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "last_run_at": self.last_run_at.isoformat() if self.last_run_at else None,
        }


def record_metric(
    db_session,
    metric_type: MetricType,
    resource_type: str = None,
    resource_id: str = None,
    value: float = 1.0,
    period_start: datetime = None,
    period_end: datetime = None,
    granularity: str = "hour",
    metadata: dict = None
) -> UsageMetric:
    """
    Record a usage metric.
    
    Args:
        db_session: Database session
        metric_type: Type of metric
        resource_type: Resource category
        resource_id: Specific resource ID
        value: Metric value
        period_start: Start of measurement period
        period_end: End of measurement period
        granularity: Time granularity
        metadata: Additional context
        
    Returns:
        Created UsageMetric object
    """
    import json
    from datetime import timedelta
    
    if not period_start:
        period_start = datetime.now(timezone.utc)
    if not period_end:
        if granularity == "hour":
            period_end = period_start + timedelta(hours=1)
        elif granularity == "day":
            period_end = period_start + timedelta(days=1)
        else:
            period_end = period_start + timedelta(hours=1)
    
    metric = UsageMetric(
        metric_type=metric_type,
        resource_type=resource_type,
        resource_id=resource_id,
        period_start=period_start,
        period_end=period_end,
        granularity=granularity,
        count=1,
        value=value,
        min_value=value,
        max_value=value,
        avg_value=value,
        metric_metadata=json.dumps(metadata) if metadata else None,
    )
    
    db_session.add(metric)
    db_session.commit()
    db_session.refresh(metric)
    
    return metric
