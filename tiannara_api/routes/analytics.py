"""
Analytics Routes for Tiannara API

Endpoints for usage metrics, custom reports, and dashboard data.
Provides advanced analytics and insights.

Date: May 1, 2026
Status: Week 28 Day 6 - Advanced Analytics Implementation
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, Response
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta
import json

from tiannara_api.database import get_db
from tiannara_api.database.model_classes.analytics import (
    UsageMetric,
    SavedReport,
    MetricType,
    ReportFormat,
    record_metric,
)
from tiannara_api.routes.auth import get_current_user
from tiannara_api.services.report_exporter import ReportExporter

router = APIRouter(prefix="/analytics", tags=["Analytics"])


# ==================== Request/Response Models ====================

from pydantic import BaseModel, Field
from typing import Dict, Any


class RecordMetricRequest(BaseModel):
    """Request to record a usage metric."""
    metric_type: str
    resource_type: Optional[str] = None
    resource_id: Optional[str] = None
    value: float = 1.0
    granularity: str = "hour"
    metadata: Optional[Dict[str, Any]] = None


class CreateReportRequest(BaseModel):
    """Request to create a saved report."""
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    metrics: List[str]  # List of metric types to include
    filters: Optional[Dict[str, Any]] = None
    group_by: Optional[str] = None
    time_range: str = "7d"  # 1d, 7d, 30d, 90d
    chart_type: str = "line"  # line, bar, pie, table
    is_public: bool = False


class UpdateReportRequest(BaseModel):
    """Request to update a saved report."""
    name: Optional[str] = None
    description: Optional[str] = None
    metrics: Optional[List[str]] = None
    filters: Optional[Dict[str, Any]] = None
    group_by: Optional[str] = None
    time_range: Optional[str] = None
    chart_type: Optional[str] = None
    is_public: Optional[bool] = None


# ==================== Metrics Endpoints ====================

@router.post("/metrics", status_code=status.HTTP_201_CREATED)
async def record_usage_metric(
    request: RecordMetricRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Record a usage metric."""
    try:
        # Validate metric type
        try:
            metric_type = MetricType(request.metric_type)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid metric type: {request.metric_type}. Valid types: {[m.value for m in MetricType]}"
            )
        
        # Record the metric
        metric = record_metric(
            db_session=db,
            metric_type=metric_type,
            resource_type=request.resource_type,
            resource_id=request.resource_id,
            value=request.value,
            granularity=request.granularity,
            metadata=request.metadata,
        )
        
        return {
            "success": True,
            "message": "Metric recorded successfully",
            "data": metric.to_dict(),
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to record metric: {str(e)}"
        )


@router.get("/metrics")
async def list_metrics(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    metric_type: Optional[str] = Query(None, description="Filter by metric type"),
    resource_type: Optional[str] = Query(None, description="Filter by resource type"),
    start_date: Optional[str] = Query(None, description="Start date (ISO format)"),
    end_date: Optional[str] = Query(None, description="End date (ISO format)"),
    granularity: Optional[str] = Query(None, description="Filter by granularity"),
    limit: int = Query(100, ge=1, le=1000, description="Number of results"),
    offset: int = Query(0, ge=0, description="Offset for pagination")
):
    """List usage metrics with filtering."""
    try:
        query = db.query(UsageMetric)
        
        # Apply filters
        if metric_type:
            try:
                metric_enum = MetricType(metric_type)
                query = query.filter(UsageMetric.metric_type == metric_enum)
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid metric type: {metric_type}"
                )
        
        if resource_type:
            query = query.filter(UsageMetric.resource_type == resource_type)
        
        if start_date:
            start_dt = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
            query = query.filter(UsageMetric.period_start >= start_dt)
        
        if end_date:
            end_dt = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
            query = query.filter(UsageMetric.period_end <= end_dt)
        
        if granularity:
            query = query.filter(UsageMetric.granularity == granularity)
        
        # Order by most recent first
        query = query.order_by(UsageMetric.period_start.desc())
        
        # Get total count
        total = query.count()
        
        # Apply pagination
        metrics = query.offset(offset).limit(limit).all()
        
        return {
            "success": True,
            "total": total,
            "limit": limit,
            "offset": offset,
            "data": [m.to_dict() for m in metrics],
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list metrics: {str(e)}"
        )


@router.get("/metrics/summary")
async def get_metrics_summary(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    period: str = Query("7d", description="Time period: 1d, 7d, 30d, 90d")
):
    """Get aggregated metrics summary for a time period."""
    try:
        # Parse period
        now = datetime.now()
        if period == "1d":
            start = now - timedelta(days=1)
        elif period == "7d":
            start = now - timedelta(days=7)
        elif period == "30d":
            start = now - timedelta(days=30)
        elif period == "90d":
            start = now - timedelta(days=90)
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid period. Use: 1d, 7d, 30d, 90d"
            )
        
        # Aggregate by metric type
        metrics_by_type = {}
        all_metrics = db.query(UsageMetric).filter(
            UsageMetric.period_start >= start
        ).all()
        
        for metric in all_metrics:
            type_key = metric.metric_type.value
            if type_key not in metrics_by_type:
                metrics_by_type[type_key] = {
                    "count": 0,
                    "total_value": 0.0,
                    "min_value": float('inf'),
                    "max_value": float('-inf'),
                }
            
            metrics_by_type[type_key]["count"] += metric.count
            metrics_by_type[type_key]["total_value"] += metric.value
            metrics_by_type[type_key]["min_value"] = min(
                metrics_by_type[type_key]["min_value"],
                metric.min_value or metric.value
            )
            metrics_by_type[type_key]["max_value"] = max(
                metrics_by_type[type_key]["max_value"],
                metric.max_value or metric.value
            )
        
        # Convert inf values
        for type_data in metrics_by_type.values():
            if type_data["min_value"] == float('inf'):
                type_data["min_value"] = 0
            if type_data["max_value"] == float('-inf'):
                type_data["max_value"] = 0
        
        return {
            "success": True,
            "period": period,
            "start_date": start.isoformat(),
            "end_date": now.isoformat(),
            "summary": metrics_by_type,
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get metrics summary: {str(e)}"
        )


# ==================== Reports Endpoints ====================

@router.post("/reports", response_model=dict, status_code=status.HTTP_201_CREATED)
async def create_report(
    request: CreateReportRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new saved report."""
    try:
        user_id = current_user.get("user", {}).get("id")
        
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User ID not found in token"
            )
        
        # Validate metric types
        valid_metrics = []
        for metric_str in request.metrics:
            try:
                MetricType(metric_str)
                valid_metrics.append(metric_str)
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid metric type: {metric_str}"
                )
        
        # Create report
        report = SavedReport(
            name=request.name,
            description=request.description,
            user_id=user_id,
            metrics=json.dumps(valid_metrics),
            filters=json.dumps(request.filters) if request.filters else None,
            group_by=request.group_by,
            time_range=request.time_range,
            chart_type=request.chart_type,
            is_public=request.is_public,
        )
        
        db.add(report)
        db.commit()
        db.refresh(report)
        
        return {
            "success": True,
            "message": "Report created successfully",
            "data": report.to_dict(),
        }
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create report: {str(e)}"
        )


@router.get("/reports")
async def list_reports(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    include_public: bool = Query(False, description="Include public reports")
):
    """List saved reports."""
    try:
        user_id = current_user.get("user", {}).get("id")
        
        query = db.query(SavedReport).filter(
            (SavedReport.user_id == user_id) | 
            (SavedReport.is_public == True and include_public == True)
        )
        
        reports = query.order_by(SavedReport.created_at.desc()).all()
        
        return {
            "success": True,
            "total": len(reports),
            "data": [r.to_dict() for r in reports],
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list reports: {str(e)}"
        )


@router.get("/reports/{report_id}")
async def get_report(
    report_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get a specific saved report."""
    try:
        report = db.query(SavedReport).filter(
            SavedReport.id == report_id
        ).first()
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Report not found"
            )
        
        # Check permissions
        user_id = current_user.get("user", {}).get("id")
        if report.user_id != user_id and not report.is_public:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to view this report"
            )
        
        return {
            "success": True,
            "data": report.to_dict(),
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get report: {str(e)}"
        )


@router.put("/reports/{report_id}")
async def update_report(
    report_id: str,
    request: UpdateReportRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update a saved report."""
    try:
        report = db.query(SavedReport).filter(
            SavedReport.id == report_id
        ).first()
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Report not found"
            )
        
        # Check ownership
        user_id = current_user.get("user", {}).get("id")
        if report.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the owner can update this report"
            )
        
        # Update fields
        if request.name is not None:
            report.name = request.name
        if request.description is not None:
            report.description = request.description
        if request.metrics is not None:
            # Validate metrics
            for metric_str in request.metrics:
                try:
                    MetricType(metric_str)
                except ValueError:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Invalid metric type: {metric_str}"
                    )
            report.metrics = json.dumps(request.metrics)
        if request.filters is not None:
            report.filters = json.dumps(request.filters)
        if request.group_by is not None:
            report.group_by = request.group_by
        if request.time_range is not None:
            report.time_range = request.time_range
        if request.chart_type is not None:
            report.chart_type = request.chart_type
        if request.is_public is not None:
            report.is_public = request.is_public
        
        db.commit()
        db.refresh(report)
        
        return {
            "success": True,
            "message": "Report updated successfully",
            "data": report.to_dict(),
        }
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update report: {str(e)}"
        )


@router.delete("/reports/{report_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_report(
    report_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a saved report."""
    try:
        report = db.query(SavedReport).filter(
            SavedReport.id == report_id
        ).first()
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Report not found"
            )
        
        # Check ownership
        user_id = current_user.get("user", {}).get("id")
        if report.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the owner can delete this report"
            )
        
        db.delete(report)
        db.commit()
        
        return None
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete report: {str(e)}"
        )


# ==================== Dashboard Endpoint ====================

@router.get("/dashboard")
async def get_dashboard_data(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get comprehensive dashboard data with key metrics."""
    try:
        now = datetime.now()
        
        # Get metrics for different time periods
        periods = {
            "today": now - timedelta(days=1),
            "week": now - timedelta(days=7),
            "month": now - timedelta(days=30),
        }
        
        dashboard_data = {}
        
        for period_name, start_date in periods.items():
            metrics = db.query(UsageMetric).filter(
                UsageMetric.period_start >= start_date
            ).all()
            
            # Aggregate by type
            summary = {}
            for metric in metrics:
                type_key = metric.metric_type.value
                if type_key not in summary:
                    summary[type_key] = {
                        "count": 0,
                        "total_value": 0.0,
                    }
                summary[type_key]["count"] += metric.count
                summary[type_key]["total_value"] += metric.value
            
            dashboard_data[period_name] = {
                "start_date": start_date.isoformat(),
                "end_date": now.isoformat(),
                "metrics": summary,
            }
        
        # Get recent reports
        user_id = current_user.get("user", {}).get("id")
        recent_reports = db.query(SavedReport).filter(
            SavedReport.user_id == user_id
        ).order_by(SavedReport.created_at.desc()).limit(5).all()
        
        dashboard_data["recent_reports"] = [r.to_dict() for r in recent_reports]
        
        return {
            "success": True,
            "data": dashboard_data,
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get dashboard data: {str(e)}"
        )


# ==================== Export Endpoints ====================

@router.get("/reports/{report_id}/export")
async def export_report(
    report_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    format: str = Query("csv", description="Export format: csv, json")
):
    """
    Export a saved report in the specified format.
    
    Args:
        report_id: Report ID
        current_user: Authenticated user
        db: Database session
        format: Export format (csv or json)
        
    Returns:
        File download with report data
    """
    try:
        # Get report
        report = db.query(SavedReport).filter(
            SavedReport.id == report_id
        ).first()
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Report not found"
            )
        
        # Check permissions
        user_id = current_user.get("user", {}).get("id")
        if report.user_id != user_id and not report.is_public:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to export this report"
            )
        
        # Create exporter
        exporter = ReportExporter(db)
        
        # Generate export based on format
        if format.lower() == "csv":
            content = exporter.export_report_to_csv(report)
            media_type = "text/csv"
            filename = exporter.get_export_filename(report.name, "csv")
        elif format.lower() == "json":
            content = exporter.export_report_to_json(report, pretty=True)
            media_type = "application/json"
            filename = exporter.get_export_filename(report.name, "json")
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported format: {format}. Use 'csv' or 'json'."
            )
        
        # Return file download
        return Response(
            content=content,
            media_type=media_type,
            headers={
                "Content-Disposition": f"attachment; filename={filename}"
            }
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to export report: {str(e)}"
        )


@router.get("/metrics/export")
async def export_metrics(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    format: str = Query("csv", description="Export format: csv, json"),
    metric_type: Optional[str] = Query(None, description="Filter by metric type"),
    start_date: Optional[str] = Query(None, description="Start date (ISO format)"),
    end_date: Optional[str] = Query(None, description="End date (ISO format)"),
    limit: int = Query(1000, ge=1, le=10000, description="Number of records")
):
    """
    Export raw metrics data in the specified format.
    
    Args:
        current_user: Authenticated user
        db: Database session
        format: Export format (csv or json)
        metric_type: Filter by metric type
        start_date: Start date filter
        end_date: End date filter
        limit: Maximum number of records
        
    Returns:
        File download with metrics data
    """
    try:
        # Build query
        query = db.query(UsageMetric)
        
        # Apply filters
        if metric_type:
            try:
                metric_enum = MetricType(metric_type)
                query = query.filter(UsageMetric.metric_type == metric_enum)
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid metric type: {metric_type}"
                )
        
        if start_date:
            start_dt = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
            query = query.filter(UsageMetric.period_start >= start_dt)
        
        if end_date:
            end_dt = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
            query = query.filter(UsageMetric.period_end <= end_dt)
        
        # Order by most recent first
        query = query.order_by(UsageMetric.period_start.desc())
        
        # Limit results
        metrics = query.limit(limit).all()
        
        # Create exporter
        exporter = ReportExporter(db)
        
        # Generate export based on format
        if format.lower() == "csv":
            content = exporter.export_to_csv(metrics)
            media_type = "text/csv"
            filename = f"metrics_export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
        elif format.lower() == "json":
            content = exporter.export_to_json(metrics, pretty=True)
            media_type = "application/json"
            filename = f"metrics_export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported format: {format}. Use 'csv' or 'json'."
            )
        
        # Return file download
        return Response(
            content=content,
            media_type=media_type,
            headers={
                "Content-Disposition": f"attachment; filename={filename}"
            }
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to export metrics: {str(e)}"
        )
