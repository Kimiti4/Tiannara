"""
Database Migration Script for Team Workspaces

Creates tables:
- workspaces
- workspace_members
- invitations

Run this script once to set up workspace functionality.

Date: May 1, 2026
Status: Week 27 Day 3 - Team Workspaces Implementation
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import create_engine, text
from tiannara_api.database import Base, engine
from tiannara_api.database.model_classes.workspace import Workspace, WorkspaceMember, Invitation

# Import User model from models.py (before models/ package was created)
import importlib.util
spec = importlib.util.spec_from_file_location("user_models", Path(__file__).parent / "tiannara_api" / "database" / "models.py")
user_models = importlib.util.module_from_spec(spec)
spec.loader.exec_module(user_models)
User = user_models.User


def create_workspace_tables():
    """Create workspace-related tables in the database."""
    print("🔧 Creating workspace tables...")
    
    try:
        # Create all tables (SQLAlchemy will handle dependencies)
        Base.metadata.create_all(bind=engine)
        
        print("✅ Workspace tables created successfully!")
        print("   - workspaces")
        print("   - workspace_members")
        print("   - invitations")
        print("   - users (if not already exists)")
        
        return True
    
    except Exception as e:
        print(f"❌ Failed to create workspace tables: {e}")
        import traceback
        traceback.print_exc()
        return False


def verify_tables():
    """Verify that workspace tables exist."""
    print("\n🔍 Verifying workspace tables...")
    
    try:
        from tiannara_api.database import SessionLocal
        
        db = SessionLocal()
        
        # Check if tables exist by querying them
        tables_to_check = ['workspaces', 'workspace_members', 'invitations']
        
        for table_name in tables_to_check:
            result = db.execute(text(f"SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = '{table_name}')"))
            exists = result.scalar()
            
            if exists:
                print(f"   ✅ {table_name} - EXISTS")
            else:
                print(f"   ❌ {table_name} - MISSING")
                return False
        
        db.close()
        print("\n✅ All workspace tables verified!")
        return True
    
    except Exception as e:
        print(f"❌ Verification failed: {e}")
        return False


def create_sample_workspace():
    """Create a sample workspace for testing."""
    print("\n📝 Creating sample workspace...")
    
    try:
        from tiannara_api.database import SessionLocal
        from tiannara_api.database.models.workspace import create_workspace, WorkspaceRole
        from tiannara_api.database.models import User
        import uuid
        
        db = SessionLocal()
        
        # Get or create a test user
        test_email = "admin@tiannara.com"
        user = db.query(User).filter(User.email == test_email).first()
        
        if not user:
            print(f"   ⚠️  Test user '{test_email}' not found. Skipping sample workspace.")
            db.close()
            return False
        
        # Check if workspace already exists
        existing = db.query(Workspace).filter(Workspace.name == "Sample Team").first()
        
        if existing:
            print(f"   ℹ️  Sample workspace already exists: {existing.id}")
            db.close()
            return True
        
        # Create sample workspace
        workspace = create_workspace(
            db_session=db,
            name="Sample Team",
            owner_id=user.id,
            description="A sample workspace for testing team features",
            tier="team",
        )
        
        print(f"   ✅ Sample workspace created: {workspace.name} ({workspace.id})")
        print(f"      Owner: {user.email}")
        print(f"      Tier: {workspace.tier}")
        
        db.close()
        return True
    
    except Exception as e:
        print(f"   ❌ Failed to create sample workspace: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    print("=" * 60)
    print("Tiannara Workspace Database Migration")
    print("=" * 60)
    
    # Step 1: Create tables
    if not create_workspace_tables():
        print("\n❌ Migration failed at table creation step")
        sys.exit(1)
    
    # Step 2: Verify tables
    if not verify_tables():
        print("\n❌ Migration failed at verification step")
        sys.exit(1)
    
    # Step 3: Create sample data (optional)
    create_sample_workspace()
    
    print("\n" + "=" * 60)
    print("✅ Workspace migration completed successfully!")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Restart your backend server")
    print("2. Test workspace endpoints:")
    print("   - POST /api/v1/workspaces - Create workspace")
    print("   - GET /api/v1/workspaces - List workspaces")
    print("   - POST /api/v1/workspaces/{id}/invite - Invite member")
    print("=" * 60)
