"""
PostgreSQL Database Migration Script for Tiannara SaaS

Run once after PostgreSQL is configured. Requires ADMIN_PASSWORD for admin user.
"""

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import secrets
from datetime import datetime, timezone

from sqlalchemy import text
from sqlalchemy.orm import Session

from tiannara_api.database import init_db, SessionLocal
from tiannara_api.database.models import User
from tiannara_api.security.password import hash_password


def verify_database_connection() -> bool:
    print("Testing PostgreSQL connection...")
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
        print("PostgreSQL connection successful.")
        return True
    except Exception as e:
        print(f"Database connection failed: {e}")
        print("Set DATABASE_URL or DB_* variables in .env")
        return False


def create_admin_user(db: Session) -> None:
    admin_password = os.getenv("ADMIN_PASSWORD")
    if not admin_password:
        print("Set ADMIN_PASSWORD to create the admin user.")
        return

    admin_email = "admin@tiannara.com"
    existing = db.query(User).filter(User.email == admin_email).first()
    if existing:
        print(f"Admin user already exists: {admin_email}")
        return

    admin_user = User(
        id=f"user_{secrets.token_hex(8)}",
        email=admin_email,
        name="Tiannara Admin",
        password_hash=hash_password(admin_password),
        tier="enterprise",
        is_verified=True,
        is_admin=True,
        is_active=True,
        created_at=datetime.now(timezone.utc),
        total_requests=0,
        api_keys=[],
    )
    db.add(admin_user)
    db.commit()
    print(f"Admin user created: {admin_email}")


def create_sample_users(db: Session) -> None:
    if os.getenv("CREATE_SAMPLE_USERS", "").lower() != "true":
        print("Skipping sample users (set CREATE_SAMPLE_USERS=true to enable).")
        return

    sample_password = os.getenv("SAMPLE_USER_PASSWORD", "ChangeMe-Sample-2026!")
    samples = [
        ("sarah.johnson@techcorp.com", "Sarah Johnson", "enterprise"),
        ("emily.rodriguez@startup.co", "Emily Rodriguez", "professional"),
        ("alex.martinez@freelance.com", "Alex Martinez", "starter"),
    ]
    created = 0
    for email, name, tier in samples:
        if db.query(User).filter(User.email == email).first():
            continue
        db.add(
            User(
                id=f"user_{secrets.token_hex(8)}",
                email=email,
                name=name,
                password_hash=hash_password(sample_password),
                tier=tier,
                is_verified=True,
                is_admin=False,
                is_active=True,
                created_at=datetime.now(timezone.utc),
                total_requests=0,
                api_keys=[],
            )
        )
        created += 1
    db.commit()
    print(f"Created {created} sample users.")


def main() -> None:
    print("=" * 60)
    print("Tiannara - PostgreSQL Migration")
    print("=" * 60)

    if not verify_database_connection():
        sys.exit(1)

    init_db()

    db = SessionLocal()
    try:
        create_admin_user(db)
        create_sample_users(db)
        total = db.query(User).count()
        print(f"\nTotal users: {total}")
        print("Next: uvicorn tiannara_api.main:app --reload --port 8004")
    finally:
        db.close()


if __name__ == "__main__":
    main()
