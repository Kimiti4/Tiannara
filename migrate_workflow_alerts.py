"""
Database Migration Script for Workflow Execution and Alert Rules Tables

Creates tables:
- workflows
- workflow_executions
- alert_rules
- alert_triggers

Run this script once to set up workflow and alert persistence.

Date: April 30, 2026
Status: Week 30 - Production Workflow & Alert System
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from sqlalchemy import create_engine, text
from tiannara_api.database import Base, engine
from tiannara_api.database.model_classes.workflow_execution import (
    Workflow,
    WorkflowExecution,
    AlertRule,
    AlertTrigger,
)


def create_workflow_alert_tables():
    """Create workflow and alert tables in the database."""
    print("=" * 70)
    print("Workflow Execution & Alert Rules Database Migration")
    print("=" * 70)
    print()
    
    try:
        # Create all tables (SQLAlchemy will handle dependencies)
        print("📊 Creating workflow and alert tables...")
        print()
        
        # Check which tables already exist
        inspector = None
        try:
            from sqlalchemy import inspect as sql_inspect
            inspector = sql_inspect(engine)
            existing_tables = inspector.get_table_names()
        except Exception:
            existing_tables = []
        
        tables_to_create = [
            ("workflows", Workflow),
            ("workflow_executions", WorkflowExecution),
            ("alert_rules", AlertRule),
            ("alert_triggers", AlertTrigger),
        ]
        
        new_tables = []
        for table_name, model in tables_to_create:
            if table_name not in existing_tables:
                new_tables.append((table_name, model))
                print(f"   Creating: {table_name}")
            else:
                print(f"   ✓ Already exists: {table_name}")
        
        # Create new tables
        if new_tables:
            print()
            Base.metadata.create_all(bind=engine)
        
        print()
        print("✅ Workflow and alert tables created successfully!")
        print("   - workflows")
        print("   - workflow_executions")
        print("   - alert_rules")
        print("   - alert_triggers")
        
        return True
    
    except Exception as e:
        print(f"❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False


def verify_tables():
    """Verify tables were created correctly."""
    print("\n🔍 Verifying tables...")
    
    try:
        from sqlalchemy import inspect as sql_inspect
        inspector = sql_inspect(engine)
        existing_tables = inspector.get_table_names()
        
        required_tables = ["workflows", "workflow_executions", "alert_rules", "alert_triggers"]
        all_exist = all(table in existing_tables for table in required_tables)
        
        if all_exist:
            print("   ✅ All tables verified!")
            
            # Show row counts
            from sqlalchemy.orm import Session
            session = Session(engine)
            
            try:
                workflow_count = session.query(Workflow).count()
                execution_count = session.query(WorkflowExecution).count()
                alert_count = session.query(AlertRule).count()
                trigger_count = session.query(AlertTrigger).count()
                
                print(f"   📊 Current data:")
                print(f"      - Workflows: {workflow_count}")
                print(f"      - Workflow Executions: {execution_count}")
                print(f"      - Alert Rules: {alert_count}")
                print(f"      - Alert Triggers: {trigger_count}")
            finally:
                session.close()
            
            return True
        else:
            print("   ❌ ERROR: Some tables are missing!")
            for table in required_tables:
                if table not in existing_tables:
                    print(f"       Missing: {table}")
            return False
    
    except Exception as e:
        print(f"   ❌ ERROR: {e}")
        return False


if __name__ == "__main__":
    success = create_workflow_alert_tables()
    
    if success:
        verified = verify_tables()
        
        if verified:
            print("\n" + "=" * 70)
            print("SUCCESS: Workflow & Alert migration completed!")
            print("=" * 70)
            print("\nNext steps:")
            print("1. Restart your backend server")
            print("2. Test workflow execution endpoints:")
            print("   - POST /api/v1/workflows/{id}/run - Execute workflow through Tiannara Core")
            print("   - GET /api/v1/workflows/{id}/executions - Get execution history")
            print("3. Test alert rule endpoints:")
            print("   - POST /api/v1/alerts - Create custom alert rule")
            print("   - POST /api/v1/alerts/evaluate - Evaluate all rules")
            print("   - GET /api/v1/alerts/history - View alert history")
            print("=" * 70)
        else:
            print("\nERROR: Migration verification failed!")
            sys.exit(1)
    else:
        print("\nERROR: Migration failed!")
        sys.exit(1)
