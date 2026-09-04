"""
PostgreSQL Database Setup and Migration Script

This script:
1. Creates the Tiannara database in PostgreSQL
2. Creates all tables
3. Migrates existing in-memory users to PostgreSQL
4. Verifies the migration

Run this ONCE to set up PostgreSQL for Tiannara.
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

import os

import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from sqlalchemy import create_engine, text

# PostgreSQL connection details (set in environment or .env — never commit secrets)
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_NAME = os.getenv("DB_NAME", "tiannara")

if not DB_PASSWORD:
    raise SystemExit(
        "DB_PASSWORD environment variable is required. "
        "Example: set DB_PASSWORD=your_password && python setup_postgresql.py"
    )


def create_database():
    """Create the Tiannara database if it doesn't exist."""
    print("=" * 60)
    print(" CREATING POSTGRESQL DATABASE")
    print("=" * 60)
    
    try:
        # Connect to PostgreSQL server (without database)
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            dbname="postgres"  # Connect to default postgres database
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        # Check if database exists
        cursor.execute("SELECT 1 FROM pg_database WHERE datname = %s", (DB_NAME,))
        exists = cursor.fetchone()
        
        if exists:
            print(f" Database '{DB_NAME}' already exists")
        else:
            # Create database
            cursor.execute(f'CREATE DATABASE "{DB_NAME}"')
            print(f"✅ Database '{DB_NAME}' created successfully!")
        
        cursor.close()
        conn.close()
        return True
        
    except psycopg2.Error as e:
        print(f" Failed to create database: {e}")
        print("\n Troubleshooting:")
        print("1. Make sure PostgreSQL is running")
        print("2. Check your username/password")
        print("3. Verify port 5432 is correct")
        return False


def initialize_tables():
    """Create all tables in the database."""
    print("\n" + "=" * 60)
    print(" INITIALIZING DATABASE TABLES")
    print("=" * 60)
    
    try:
        from tiannara_api.database import init_db
        init_db()
        return True
    except Exception as e:
        print(f" Failed to initialize tables: {e}")
        return False


def migrate_users():
    """Migrate in-memory users to PostgreSQL."""
    print("\n" + "=" * 60)
    print(" MIGRATING USERS TO POSTGRESQL")
    print("=" * 60)
    
    try:
        # Import in-memory user store
        from tiannara_api.routes.auth import user_store
        from tiannara_api.database.models import User
        from tiannara_api.database import SessionLocal
        from datetime import datetime
        
        if not user_store:
            print("⚠️  No users in memory to migrate")
            print("   Run setup_admin.py and setup_sample_users.py first")
            return True
        
        db = SessionLocal()
        migrated_count = 0
        
        for email, user_data in user_store.items():
            # Check if user already exists in database
            existing = db.query(User).filter(User.email == email).first()
            
            if existing:
                print(f"⚠️  User {email} already in database, skipping...")
                continue
            
            # Create new user record
            new_user = User(
                id=user_data.get("id", f"user_{email.split('@')[0]}"),
                email=email,
                name=user_data.get("name", "Unknown"),
                password_hash=user_data.get("password_hash", ""),
                tier=user_data.get("tier", "starter"),
                is_verified=user_data.get("is_verified", False),
                is_admin=user_data.get("is_admin", False),
                is_active=user_data.get("is_active", True),
                created_at=datetime.fromisoformat(user_data.get("created_at")) if user_data.get("created_at") else datetime.utcnow(),
                total_requests=user_data.get("total_requests", 0),
                api_keys=user_data.get("api_keys", [])
            )
            
            db.add(new_user)
            migrated_count += 1
            print(f"✅ Migrated: {user_data.get('name')} ({email})")
        
        db.commit()
        db.close()
        
        print(f"\n🎉 Migration complete!")
        print(f"   Migrated: {migrated_count} users")
        print(f"   Total users in database: {migrated_count}")
        
        return True
        
    except Exception as e:
        print(f" Failed to migrate users: {e}")
        import traceback
        traceback.print_exc()
        return False


def verify_migration():
    """Verify users were migrated correctly."""
    print("\n" + "=" * 60)
    print(" VERIFYING MIGRATION")
    print("=" * 60)
    
    try:
        from tiannara_api.database.models import User
        from tiannara_api.database import SessionLocal
        
        db = SessionLocal()
        total_users = db.query(User).count()
        admin_users = db.query(User).filter(User.is_admin == True).count()
        
        print(f"✅ Total users in database: {total_users}")
        print(f"✅ Admin users: {admin_users}")
        
        # List all users
        users = db.query(User).all()
        print("\n Users in database:")
        print("-" * 60)
        for user in users:
            role = "👑 ADMIN" if user.is_admin else "👤 User"
            print(f"{role} | {user.name:20} | {user.email:35} | {user.tier}")
        print("-" * 60)
        
        db.close()
        return True
        
    except Exception as e:
        print(f" Failed to verify: {e}")
        return False


def create_env_file():
    """Create .env file with PostgreSQL configuration."""
    print("\n" + "=" * 60)
    print(" CREATING .ENV FILE")
    print("=" * 60)
    
    env_content = f"""# Tiannara Environment Configuration
# Generated on: {__import__('datetime').datetime.now().isoformat()}

# PostgreSQL Database
DATABASE_URL=postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}

# API Configuration
API_BASE_URL=http://localhost:8004

# Authentication
JWT_SECRET_KEY={__import__('secrets').token_urlsafe(32)}
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Environment
ENVIRONMENT=development
LOG_LEVEL=INFO
"""
    
    env_path = Path(__file__).parent / ".env"
    env_path.write_text(env_content)
    print(f"✅ Created .env file at: {env_path}")
    print("⚠️  IMPORTANT: Never commit .env to version control!")
    
    return True


if __name__ == "__main__":
    print("\n" + "🚀" * 30)
    print(" TIANNARA POSTGRESQL SETUP")
    print("🚀" * 30 + "\n")
    
    # Step 1: Create database
    if not create_database():
        print("\n❌ Database creation failed. Please fix the issues above.")
        sys.exit(1)
    
    # Step 2: Initialize tables
    if not initialize_tables():
        print("\n❌ Table initialization failed. Please fix the issues above.")
        sys.exit(1)
    
    # Step 3: Migrate users
    if not migrate_users():
        print("\n❌ User migration failed. Please fix the issues above.")
        sys.exit(1)
    
    # Step 4: Verify migration
    if not verify_migration():
        print("\n❌ Migration verification failed.")
        sys.exit(1)
    
    # Step 5: Create .env file
    if not create_env_file():
        print("\n⚠️  Failed to create .env file, but database is ready.")
    
    # Success!
    print("\n" + "✅" * 30)
    print(" POSTGRESQL SETUP COMPLETE!")
    print("✅" * 30)
    print("\n Next Steps:")
    print("1. Restart your backend server")
    print("2. Users will now persist across restarts!")
    print("3. No need to run setup_admin.py anymore")
    print("\n Database Info:")
    print(f"  Host: {DB_HOST}")
    print(f"  Port: {DB_PORT}")
    print(f"  Database: {DB_NAME}")
    print(f"  User: {DB_USER}")
    print("=" * 60)
