"""Create admin user in PostgreSQL — password from --password or ADMIN_PASSWORD env."""

import argparse
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from datetime import datetime, timezone

from tiannara_api.database import SessionLocal, init_db
from tiannara_api.database.models import User
from tiannara_api.security.password import hash_password


def create_admin_user(email: str, password: str, name: str):
    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.email == email).first()
        if existing:
            if not existing.is_admin:
                existing.is_admin = True
                db.commit()
                print(f"Upgraded {email} to admin.")
            else:
                print(f"User {email} already exists as admin.")
            return

        user = User(
            email=email,
            name=name,
            password_hash=hash_password(password),
            tier="enterprise",
            is_verified=True,
            is_admin=True,
            is_active=True,
            created_at=datetime.now(timezone.utc),
        )
        db.add(user)
        db.commit()
        print(f"Admin user created: {email}")
    finally:
        db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create admin user for Tiannara")
    parser.add_argument("--email", default="admin@tiannara.com")
    parser.add_argument("--password", default=None, help="Admin password (or set ADMIN_PASSWORD)")
    parser.add_argument("--name", default="Admin User")
    args = parser.parse_args()
    password = args.password or os.getenv("ADMIN_PASSWORD")
    if not password:
        raise SystemExit("Provide --password or set ADMIN_PASSWORD.")
    init_db()
    create_admin_user(args.email, password, args.name)
