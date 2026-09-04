"""
Database Migration Script for White-label Tables

Creates the white_label_configs and domain_verifications tables.

Run this script once to set up white-label infrastructure.

Date: May 1, 2026
Status: Week 28 Day 8-9 - White-label Implementation
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import create_engine, text
from tiannara_api.database import Base, engine
from tiannara_api.database.model_classes.white_label import WhiteLabelConfig, DomainVerification


def create_white_label_tables():
    """Create white-label tables in the database."""
    print("Creating white-label tables...")
    
    try:
        # Create all tables (including dependencies)
        Base.metadata.create_all(bind=engine)
        
        print("SUCCESS: White-label tables created!")
        print("   - white_label_configs")
        print("   - domain_verifications")
        print("   - workspaces (if not already exists)")
        print("   - users (if not already exists)")
        
        return True
    
    except Exception as e:
        print(f"ERROR: Failed to create white-label tables: {e}")
        import traceback
        traceback.print_exc()
        return False


def verify_white_label_tables():
    """Verify that the white-label tables exist."""
    print("\nVerifying white-label tables...")
    
    try:
        with engine.connect() as conn:
            # Check white_label_configs
            result = conn.execute(text(
                "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'white_label_configs');"
            ))
            configs_exists = result.scalar()
            
            # Check domain_verifications
            result = conn.execute(text(
                "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'domain_verifications');"
            ))
            verifications_exists = result.scalar()
            
            if configs_exists and verifications_exists:
                print("   SUCCESS: white_label_configs table EXISTS")
                print("   SUCCESS: domain_verifications table EXISTS")
                return True
            else:
                if not configs_exists:
                    print("   ERROR: white_label_configs table NOT FOUND")
                if not verifications_exists:
                    print("   ERROR: domain_verifications table NOT FOUND")
                return False
    
    except Exception as e:
        print(f"   ERROR: {e}")
        return False


if __name__ == "__main__":
    print("=" * 60)
    print("Tiannara White-label Database Migration")
    print("=" * 60)
    
    success = create_white_label_tables()
    
    if success:
        verified = verify_white_label_tables()
        
        if verified:
            print("\n" + "=" * 60)
            print("SUCCESS: White-label migration completed!")
            print("=" * 60)
            print("\nNext steps:")
            print("1. Restart your backend server")
            print("2. Test white-label endpoints:")
            print("   - GET /api/v1/whitelabel/config - Get config")
            print("   - POST /api/v1/whitelabel/config - Create config")
            print("   - POST /api/v1/whitelabel/domains - Add domain")
            print("   - GET /api/v1/whitelabel/preview - Branding preview")
            print("=" * 60)
        else:
            print("\nERROR: Migration verification failed!")
            sys.exit(1)
    else:
        print("\nERROR: Migration failed!")
        sys.exit(1)
