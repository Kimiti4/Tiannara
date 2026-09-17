"""
Database Migration Script - Add MFA Columns to Users Table

This script adds Multi-Factor Authentication (MFA) support to the users table.
Run this after updating the User model with MFA fields.

Date: May 15, 2026
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from tiannara_api.database import engine
from sqlalchemy import text

def add_mfa_columns():
    """Add MFA columns to users table."""
    
    print("🔄 Adding MFA columns to users table...")
    
    with engine.connect() as conn:
        # Check if columns already exist
        result = conn.execute(text("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'users' 
            AND column_name IN ('mfa_enabled', 'mfa_secret', 'mfa_backup_codes')
        """))
        
        existing_columns = [row[0] for row in result.fetchall()]
        
        if len(existing_columns) == 3:
            print("✅ MFA columns already exist. No migration needed.")
            return
        
        # Add missing columns
        if 'mfa_enabled' not in existing_columns:
            print("  Adding mfa_enabled column...")
            conn.execute(text("""
                ALTER TABLE users 
                ADD COLUMN mfa_enabled BOOLEAN DEFAULT FALSE
            """))
            print("  ✅ Added mfa_enabled")
        
        if 'mfa_secret' not in existing_columns:
            print("  Adding mfa_secret column...")
            conn.execute(text("""
                ALTER TABLE users 
                ADD COLUMN mfa_secret VARCHAR NULL
            """))
            print("  ✅ Added mfa_secret")
        
        if 'mfa_backup_codes' not in existing_columns:
            print("  Adding mfa_backup_codes column...")
            conn.execute(text("""
                ALTER TABLE users 
                ADD COLUMN mfa_backup_codes VARCHAR NULL
            """))
            print("  ✅ Added mfa_backup_codes")
        
        conn.commit()
    
    print("✅ Migration completed successfully!")
    print("\n📋 Summary:")
    print("  - mfa_enabled: Boolean flag indicating if MFA is active")
    print("  - mfa_secret: TOTP secret key (encrypted)")
    print("  - mfa_backup_codes: Comma-separated backup codes")


if __name__ == "__main__":
    try:
        add_mfa_columns()
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
