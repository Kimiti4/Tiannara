"""
Create default admin user for Tiannara Core dashboard.
Requires ADMIN_PASSWORD in the environment.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, timezone

from tiannara_api.database import SessionLocal, engine, Base
from tiannara_api.database.models import User
from tiannara_api.security.password import hash_password


def create_admin_user():
    """Create default admin user if it doesn't exist."""
    admin_password = os.getenv("ADMIN_PASSWORD")
    if not admin_password:
        raise SystemExit("Set ADMIN_PASSWORD before running this script.")

    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.email == "admin@tiannara.com").first()
        if existing:
            print("Admin user already exists:", existing.email)
            return

        admin_user = User(
            id="admin_001",
            email="admin@tiannara.com",
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
        print("Admin user created: admin@tiannara.com")
    except Exception as e:
        db.rollback()
        print(f"Failed to create admin user: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    Base.metadata.create_all(bind=engine)
    create_admin_user()
