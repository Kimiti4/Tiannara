"""
Database Migration Script for Analytics Tables

Creates the usage_metrics and custom_reports tables for advanced analytics.

Run this script once to set up analytics infrastructure.

Date: May 1, 2026
Status: Week 28 Day 6 - Advanced Analytics Implementation
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import create_engine, text
from tiannara_api.database import Base, engine
from tiannara_api.database.model_classes.analytics import UsageMetric, SavedReport

# Import User model from models.py file
import importlib.util
spec = importlib.util.spec_from_file_location(
    "user_models",
    Path(__file__).parent / "tiannara_api" / "database" / "models.py"
)
user_models = importlib.util.module_from_spec(spec)
spec.loader.exec_module(user_models)
User = user_models.User


def create_analytics_tables():
    """Create analytics tables in the database."""
    print("Creating analytics tables...")
    
    try:
        # Create all tables (including users if not exists)
        Base.metadata.create_all(bind=engine)
        
        print("SUCCESS: Analytics tables created!")
        print("   - usage_metrics")
        print("   - saved_reports")
        print("   - users (if not already exists)")
        
        return True
    
    except Exception as e:
        print(f"ERROR: Failed to create analytics tables: {e}")
        import traceback
        traceback.print_exc()
        return False


def verify_analytics_tables():
    """Verify that the analytics tables exist."""
    print("\nVerifying analytics tables...")
    
    try:
        with engine.connect() as conn:
            # Check usage_metrics
            result = conn.execute(text(
                "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'usage_metrics');"
            ))
            metrics_exists = result.scalar()
            
            # Check saved_reports
            result = conn.execute(text(
                "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'saved_reports');"
            ))
            reports_exists = result.scalar()
            
            if metrics_exists and reports_exists:
                print("   SUCCESS: usage_metrics table EXISTS")
                print("   SUCCESS: saved_reports table EXISTS")
                return True
            else:
                if not metrics_exists:
                    print("   ERROR: usage_metrics table NOT FOUND")
                if not reports_exists:
                    print("   ERROR: saved_reports table NOT FOUND")
                return False
    
    except Exception as e:
        print(f"   ERROR: {e}")
        return False


if __name__ == "__main__":
    print("=" * 60)
    print("Tiannara Analytics Database Migration")
    print("=" * 60)
    
    success = create_analytics_tables()
    
    if success:
        verified = verify_analytics_tables()
        
        if verified:
            print("\n" + "=" * 60)
            print("SUCCESS: Analytics migration completed!")
            print("=" * 60)
            print("\nNext steps:")
            print("1. Restart your backend server")
            print("2. Test analytics endpoints:")
            print("   - GET /api/v1/analytics/metrics - List metrics")
            print("   - POST /api/v1/analytics/reports - Create report")
            print("   - GET /api/v1/analytics/dashboard - Dashboard data")
            print("=" * 60)
        else:
            print("\nERROR: Migration verification failed!")
            sys.exit(1)
    else:
        print("\nERROR: Migration failed!")
        sys.exit(1)
