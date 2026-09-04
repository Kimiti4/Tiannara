"""Create admin user — requires ADMIN_PASSWORD environment variable."""
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from datetime import datetime, timezone

from tiannara_api.database import get_db, init_db
from tiannara_api.database.models import User
from tiannara_api.security.password import hash_password


def create_admin():
    admin_password = os.getenv("ADMIN_PASSWORD")
    if not admin_password:
        raise SystemExit("Set ADMIN_PASSWORD before running this script.")

    init_db()
    db = next(get_db())
    email = "admin@tiannara.com"

    try:
        existing = db.query(User).filter(User.email == email).first()
        if existing:
            print(f"Admin user {email} already exists.")
            if not existing.is_admin:
                existing.is_admin = True
                db.commit()
                print("Upgraded to admin.")
            return

        admin = User(
            email=email,
            name="Admin User",
            password_hash=hash_password(admin_password),
            tier="enterprise",
            is_verified=True,
            is_admin=True,
            created_at=datetime.now(timezone.utc),
        )
        db.add(admin)
        db.commit()
        print(f"Admin user created: {email}")
    finally:
        db.close()


if __name__ == "__main__":
    create_admin()
