"""
Database Migration Script for MAPE-K Security Tables

Creates the security event, analysis, defense plan, execution, and knowledge tables.

Run this script once to set up autonomous security infrastructure.

Date: May 1, 2026
Status: Week 28 Day 10 - MAPE-K Security Implementation
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from sqlalchemy import create_engine, text
from tiannara_api.database import Base, engine
from tiannara_api.database.model_classes.mapek_security import (
    SecurityEvent,
    SecurityAnalysis,
    DefensePlan,
    DefenseExecution,
    SecurityKnowledge,
)


def run_migration():
    """Create MAPE-K security tables."""
    print("=" * 70)
    print("MAPE-K Security Database Migration")
    print("=" * 70)
    print()
    
    try:
        # Create all MAPE-K security tables
        print("📊 Creating MAPE-K security tables...")
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
            ("security_events", SecurityEvent),
            ("security_analyses", SecurityAnalysis),
            ("defense_plans", DefensePlan),
            ("defense_executions", DefenseExecution),
            ("security_knowledge", SecurityKnowledge),
        ]
        
        created_count = 0
        skipped_count = 0
        
        for table_name, model_class in tables_to_create:
            if table_name in existing_tables:
                print(f"  ⏭️  Skipping {table_name} (already exists)")
                skipped_count += 1
            else:
                print(f"  ✅ Creating {table_name}...")
                model_class.__table__.create(engine, checkfirst=True)
                created_count += 1
        
        print()
        print("=" * 70)
        print(f"✅ Migration Complete!")
        print(f"   Created: {created_count} tables")
        print(f"   Skipped: {skipped_count} tables (already existed)")
        print("=" * 70)
        print()
        
        # Verify tables
        print("🔍 Verifying tables...")
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name LIKE 'security_%'
                ORDER BY table_name;
            """))
            tables = [row[0] for row in result.fetchall()]
            
            if tables:
                print(f"   Found {len(tables)} security tables:")
                for table in tables:
                    print(f"     - {table}")
            else:
                print("   ⚠️  No security tables found!")
        
        print()
        print("🎉 MAPE-K security infrastructure is ready!")
        print()
        print("Next steps:")
        print("  1. Start the API server: python -m uvicorn tiannara_api.main:app --reload")
        print("  2. Test endpoints at: http://localhost:8004/docs")
        print("  3. Monitor security dashboard: GET /api/v1/security/dashboard/summary")
        print()
        
        return True
    
    except Exception as e:
        print()
        print("=" * 70)
        print(f"❌ Migration Failed!")
        print(f"   Error: {str(e)}")
        print("=" * 70)
        print()
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
