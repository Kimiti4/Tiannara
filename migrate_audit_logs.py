"""
Database Migration Script for Audit Logs

Creates the audit_logs table for tracking all system actions.

Run this script once to set up audit logging.

Date: May 1, 2026
Status: Week 27 Day 5 - Audit Logging Implementation
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import create_engine, text
from tiannara_api.database import Base, engine
from tiannara_api.database.model_classes.audit_log import AuditLog

# Import User model from models.py file
import importlib.util
from pathlib import Path
spec = importlib.util.spec_from_file_location(
    "user_models",
    Path(__file__).parent / "tiannara_api" / "database" / "models.py"
)
user_models = importlib.util.module_from_spec(spec)
spec.loader.exec_module(user_models)
User = user_models.User


def create_audit_log_table():
    """Create audit_logs table in the database."""
    print("Creating audit_logs table...")
    
    try:
        # Create all tables (including users if not exists)
        Base.metadata.create_all(bind=engine)
        
        print("SUCCESS: Audit logs table created!")
        print("   - audit_logs")
        print("   - users (if not already exists)")
        
        return True
    
    except Exception as e:
        print(f"ERROR: Failed to create audit_logs table: {e}")
        import traceback
        traceback.print_exc()
        return False


def verify_audit_log_table():
    """Verify that the audit_logs table exists."""
    print("\nVerifying audit_logs table...")
    
    try:
        with engine.connect() as conn:
            result = conn.execute(text(
                "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'audit_logs');"
            ))
            
            exists = result.scalar()
            
            if exists:
                print("   SUCCESS: audit_logs table EXISTS")
                return True
            else:
                print("   ERROR: audit_logs table NOT FOUND")
                return False
    
    except Exception as e:
        print(f"   ERROR: {e}")
        return False


if __name__ == "__main__":
    print("=" * 60)
    print("Tiannara Audit Log Database Migration")
    print("=" * 60)
    
    success = create_audit_log_table()
    
    if success:
        verified = verify_audit_log_table()
        
        if verified:
            print("\n" + "=" * 60)
            print("SUCCESS: Audit log migration completed!")
            print("=" * 60)
            print("\nNext steps:")
            print("1. Restart your backend server")
            print("2. Test audit endpoints:")
            print("   - GET /api/v1/audit/logs - List audit logs")
            print("   - GET /api/v1/audit/workspace/{id}/activity - Workspace activity")
            print("   - GET /api/v1/audit/security/alerts - Security alerts (admin)")
            print("=" * 60)
        else:
            print("\nERROR: Migration verification failed!")
            sys.exit(1)
    else:
        print("\nERROR: Migration failed at table creation step")
        sys.exit(1)
