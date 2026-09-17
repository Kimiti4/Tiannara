"""Reset admin password — requires ADMIN_PASSWORD in the environment."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, timezone

from tiannara_api.database import SessionLocal
from tiannara_api.database.models import User
from tiannara_api.security.password import hash_password

admin_password = os.getenv("ADMIN_PASSWORD")
if not admin_password:
    raise SystemExit("Set ADMIN_PASSWORD before running this script.")

db = SessionLocal()
try:
    admin = db.query(User).filter(User.email == "admin@tiannara.com").first()
    if admin:
        admin.password_hash = hash_password(admin_password)
        db.commit()
        print("Admin password updated for admin@tiannara.com")
    else:
        new_admin = User(
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
        db.add(new_admin)
        db.commit()
        print("Created admin@tiannara.com with password from ADMIN_PASSWORD")
finally:
    db.close()
