"""
Setup PostgreSQL Users - Direct Database Insertion

This script creates users directly in PostgreSQL database,
bypassing the in-memory user_store issue.

Run this AFTER setup_postgresql.py to populate the database.
"""

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from datetime import datetime, timedelta
from tiannara_api.database import SessionLocal
from tiannara_api.database.operations import create_user


def setup_admin():
    """Create admin user in PostgreSQL."""
    print("=" * 60)
    print(" CREATING ADMIN USER IN POSTGRESQL")
    print("=" * 60)
    
    db = SessionLocal()
    try:
        from tiannara_api.database.operations import get_user_by_email
        
        # Check if admin exists
        existing = get_user_by_email(db, "admin@tiannara.com")
        
        if existing:
            print("⚠️  Admin user already exists, skipping...")
            return True
        
        admin_password = os.getenv("ADMIN_PASSWORD")
        if not admin_password:
            print("Set ADMIN_PASSWORD to create the admin user.")
            return False

        admin = create_user(
            db=db,
            email="admin@tiannara.com",
            password=admin_password,
            name="Admin User",
            tier="enterprise",
            is_admin=True,
            is_verified=True,
        )

        print(f"Admin user created: {admin.name} ({admin.email})")
        print(f"   Role: ADMIN 👑")
        
        return True
        
    except Exception as e:
        db.rollback()
        print(f"❌ Failed to create admin: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        db.close()


def setup_sample_users():
    """Create sample users in PostgreSQL."""
    print("\n" + "=" * 60)
    print(" CREATING SAMPLE USERS IN POSTGRESQL")
    print("=" * 60)
    
    db = SessionLocal()
    try:
        from tiannara_api.database.operations import get_user_by_email
        
        sample_users = [
            # Enterprise users
            {"email": "sarah.johnson@techcorp.com", "password": "password123", "name": "Sarah Johnson", "tier": "enterprise", "days_ago": 45},
            {"email": "michael.chen@innovate.io", "password": "password123", "name": "Michael Chen", "tier": "enterprise", "days_ago": 30},
            # Professional users
            {"email": "emily.rodriguez@startup.co", "password": "password123", "name": "Emily Rodriguez", "tier": "professional", "days_ago": 20},
            {"email": "david.kim@analytics.com", "password": "password123", "name": "David Kim", "tier": "professional", "days_ago": 15},
            {"email": "lisa.thompson@dataworks.io", "password": "password123", "name": "Lisa Thompson", "tier": "professional", "days_ago": 10},
            # Starter users
            {"email": "alex.martinez@freelance.com", "password": "password123", "name": "Alex Martinez", "tier": "starter", "days_ago": 7},
            {"email": "jessica.lee@research.edu", "password": "password123", "name": "Jessica Lee", "tier": "starter", "days_ago": 5},
            {"email": "james.wilson@devstudio.com", "password": "password123", "name": "James Wilson", "tier": "starter", "days_ago": 3},
            {"email": "maria.garcia@mlteam.org", "password": "password123", "name": "Maria Garcia", "tier": "starter", "days_ago": 2},
            {"email": "robert.brown@ai-lab.net", "password": "password123", "name": "Robert Brown", "tier": "starter", "days_ago": 1},
        ]
        
        created_count = 0
        skipped_count = 0
        
        for user_data in sample_users:
            # Check if user exists
            existing = get_user_by_email(db, user_data["email"])
            
            if existing:
                print(f"️  Skipped: {user_data['name']} (already exists)")
                skipped_count += 1
                continue
            
            # Create user
            user = create_user(
                db=db,
                email=user_data["email"],
                password=user_data["password"],
                name=user_data["name"],
                tier=user_data["tier"],
                is_verified=True
            )
            
            created_count += 1
            print(f"✅ Created: {user.name} ({user.email}) - {user.tier}")
        
        print("\n" + "=" * 60)
        print(" SAMPLE USER SETUP COMPLETE")
        print("=" * 60)
        print(f"✅ Created: {created_count} users")
        print(f"⏭️  Skipped: {skipped_count} users")
        print(f" Total: {created_count + skipped_count} users")
        
        return True
        
    except Exception as e:
        db.rollback()
        print(f"\n❌ Failed to create sample users: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        db.close()


def verify_database():
    """Verify users in database."""
    print("\n" + "=" * 60)
    print(" VERIFYING DATABASE")
    print("=" * 60)
    
    db = SessionLocal()
    try:
        from tiannara_api.database.operations import count_users, count_admins, get_all_users
        
        total = count_users(db)
        admins = count_admins(db)
        
        print(f"✅ Total users in database: {total}")
        print(f"✅ Admin users: {admins}")
        
        if total > 0:
            users, _ = get_all_users(db, limit=20)
            print("\n Users in database:")
            print("-" * 60)
            for user in users:
                role = " ADMIN" if user.is_admin else "👤 User"
                print(f"{role} | {user.name:20} | {user.email:35} | {user.tier}")
            print("-" * 60)
        
        return True
        
    except Exception as e:
        print(f"❌ Verification failed: {e}")
        return False
    finally:
        db.close()


if __name__ == "__main__":
    print("\n" + "🚀" * 30)
    print(" TIANNARA POSTGRESQL USER SETUP")
    print("🚀" * 30 + "\n")
    
    # Step 1: Create admin
    if not setup_admin():
        print("\n❌ Admin setup failed")
        sys.exit(1)
    
    # Step 2: Create sample users
    if not setup_sample_users():
        print("\n❌ Sample user setup failed")
        sys.exit(1)
    
    # Step 3: Verify
    if not verify_database():
        print("\n❌ Verification failed")
        sys.exit(1)
    
    # Success!
    print("\n" + "✅" * 30)
    print(" POSTGRESQL USER SETUP COMPLETE!")
    print("✅" * 30)
    print("\n Next Steps:")
    print("1. Users are now persisted in PostgreSQL")
    print("2. They will survive backend restarts!")
    print("3. No need to run setup scripts again")
    print("\n Login Credentials:")
    print("  Admin: admin@tiannara.com (password from ADMIN_PASSWORD)")
    print("  All sample users use password: password123")
    print("=" * 60)
