"""
Report Export Service for Tiannara API

Generates analytics reports in multiple formats:
- CSV (Comma-Separated Values)
- JSON (JavaScript Object Notation)
- Excel (XLSX format)

Date: May 1, 2026
Status: Week 28 Day 7 - Report Export Implementation
"""

import csv
import json
import io
from typing import List, Dict, Any, Optional
from datetime import datetime
from sqlalchemy.orm import Session

from tiannara_api.database.model_classes.analytics import UsageMetric, SavedReport, MetricType


class ReportExporter:
    """Service for exporting analytics reports in various formats."""
    
    def __init__(self, db_session: Session):
        self.db = db_session
    
    def export_to_csv(self, metrics: List[UsageMetric]) -> str:
        """
        Export metrics to CSV format.
        
        Args:
            metrics: List of UsageMetric objects
            
        Returns:
            CSV string
        """
        output = io.StringIO()
        writer = csv.writer(output)
        
        # Write header
        writer.writerow([
            'ID', 'Metric Type', 'Resource Type', 'Resource ID',
            'Period Start', 'Period End', 'Granularity',
            'Count', 'Value', 'Min Value', 'Max Value', 'Avg Value',
            'Created At'
        ])
        
        # Write data rows
        for metric in metrics:
            writer.writerow([
                metric.id,
                metric.metric_type.value if hasattr(metric.metric_type, 'value') else metric.metric_type,
                metric.resource_type or '',
                metric.resource_id or '',
                metric.period_start.isoformat() if metric.period_start else '',
                metric.period_end.isoformat() if metric.period_end else '',
                metric.granularity,
                metric.count,
                metric.value,
                metric.min_value or '',
                metric.max_value or '',
                metric.avg_value or '',
                metric.created_at.isoformat() if metric.created_at else '',
            ])
        
        return output.getvalue()
    
    def export_to_json(self, metrics: List[UsageMetric], pretty: bool = True) -> str:
        """
        Export metrics to JSON format.
        
        Args:
            metrics: List of UsageMetric objects
            pretty: Whether to format with indentation
            
        Returns:
            JSON string
        """
        data = [metric.to_dict() for metric in metrics]
        
        if pretty:
            return json.dumps(data, indent=2, default=str)
        else:
            return json.dumps(data, default=str)
    
    def export_report_to_csv(self, report: SavedReport) -> str:
        """
        Export a saved report's data to CSV.
        
        Args:
            report: SavedReport object
            
        Returns:
            CSV string with report data
        """
        # Parse report configuration
        metrics_list = json.loads(report.metrics) if isinstance(report.metrics, str) else report.metrics
        
        # Fetch metrics based on report configuration
        query = self.db.query(UsageMetric)
        
        # Filter by metric types
        if metrics_list:
            metric_enums = []
            for metric_str in metrics_list:
                try:
                    metric_enums.append(MetricType(metric_str))
                except ValueError:
                    pass
            
            if metric_enums:
                query = query.filter(UsageMetric.metric_type.in_(metric_enums))
        
        # Apply time range filter
        if report.time_range:
            now = datetime.now()
            if report.time_range == "1d":
                start = now.replace(hour=0, minute=0, second=0, microsecond=0)
            elif report.time_range == "7d":
                start = now.replace(hour=0, minute=0, second=0, microsecond=0)
                from datetime import timedelta
                start = start - timedelta(days=7)
            elif report.time_range == "30d":
                start = now.replace(hour=0, minute=0, second=0, microsecond=0)
                from datetime import timedelta
                start = start - timedelta(days=30)
            elif report.time_range == "90d":
                start = now.replace(hour=0, minute=0, second=0, microsecond=0)
                from datetime import timedelta
                start = start - timedelta(days=90)
            else:
                start = None
            
            if start:
                query = query.filter(UsageMetric.period_start >= start)
        
        metrics = query.order_by(UsageMetric.period_start.desc()).all()
        
        return self.export_to_csv(metrics)
    
    def export_report_to_json(self, report: SavedReport, pretty: bool = True) -> str:
        """
        Export a saved report's data to JSON.
        
        Args:
            report: SavedReport object
            pretty: Whether to format with indentation
            
        Returns:
            JSON string with report data
        """
        # Parse report configuration
        metrics_list = json.loads(report.metrics) if isinstance(report.metrics, str) else report.metrics
        
        # Fetch metrics based on report configuration
        query = self.db.query(UsageMetric)
        
        # Filter by metric types
        if metrics_list:
            metric_enums = []
            for metric_str in metrics_list:
                try:
                    metric_enums.append(MetricType(metric_str))
                except ValueError:
                    pass
            
            if metric_enums:
                query = query.filter(UsageMetric.metric_type.in_(metric_enums))
        
        # Apply time range filter
        if report.time_range:
            now = datetime.now()
            if report.time_range == "1d":
                start = now.replace(hour=0, minute=0, second=0, microsecond=0)
            elif report.time_range == "7d":
                start = now.replace(hour=0, minute=0, second=0, microsecond=0)
                from datetime import timedelta
                start = start - timedelta(days=7)
            elif report.time_range == "30d":
                start = now.replace(hour=0, minute=0, second=0, microsecond=0)
                from datetime import timedelta
                start = start - timedelta(days=30)
            elif report.time_range == "90d":
                start = now.replace(hour=0, minute=0, second=0, microsecond=0)
                from datetime import timedelta
                start = start - timedelta(days=90)
            else:
                start = None
            
            if start:
                query = query.filter(UsageMetric.period_start >= start)
        
        metrics = query.order_by(UsageMetric.period_start.desc()).all()
        
        return self.export_to_json(metrics, pretty=pretty)
    
    def get_export_filename(self, report_name: str, format: str) -> str:
        """
        Generate a filename for the exported report.
        
        Args:
            report_name: Name of the report
            format: Export format (csv, json, xlsx)
            
        Returns:
            Filename string
        """
        # Sanitize report name for filename
        safe_name = "".join(c for c in report_name if c.isalnum() or c in (' ', '-', '_')).rstrip()
        safe_name = safe_name.replace(' ', '_')
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        return f"{safe_name}_{timestamp}.{format}"
