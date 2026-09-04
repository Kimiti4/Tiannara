"""
Sample Users Setup Script

This script creates sample users for testing the admin dashboard.
Run this after setup_admin.py to populate the system with test users.
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

import hashlib
import secrets
from datetime import datetime, timedelta

# Import the user store from auth module
from tiannara_api.routes.auth import user_store


def hash_password(password: str) -> str:
    """Hash password using SHA-256 with salt."""
    salt = secrets.token_hex(16)
    hashed = hashlib.sha256(f"{salt}{password}".encode()).hexdigest()
    return f"{salt}:{hashed}"


def create_sample_user(email: str, password: str, name: str, tier: str = "starter", is_admin: bool = False, days_ago: int = 0):
    """Create a sample user with specified parameters."""
    
    # Check if user already exists
    if email in user_store:
        print(f"⚠️  User {email} already exists, skipping...")
        return False
    
    # Hash password
    password_hash = hash_password(password)
    
    # Create user
    user_id = f"user_{secrets.token_hex(8)}"
    created_at = (datetime.utcnow() - timedelta(days=days_ago)).isoformat()
    
    user_store[email] = {
        "id": user_id,
        "email": email,
        "name": name,
        "password_hash": password_hash,
        "tier": tier,
        "is_verified": True,
        "is_admin": is_admin,
        "created_at": created_at,
        "total_requests": secrets.randbelow(10000),
        "api_keys": []
    }
    
    print(f"✅ Created user: {name} ({email}) - {tier}")
    return True


if __name__ == "__main__":
    print("=" * 60)
    print(" CREATING SAMPLE USERS FOR ADMIN DASHBOARD")
    print("=" * 60)
    print()
    
    # Define sample users
    sample_users = [
        # Enterprise users
        {
            "email": "sarah.johnson@techcorp.com",
            "password": "password123",
            "name": "Sarah Johnson",
            "tier": "enterprise",
            "days_ago": 45
        },
        {
            "email": "michael.chen@innovate.io",
            "password": "password123",
            "name": "Michael Chen",
            "tier": "enterprise",
            "days_ago": 30
        },
        # Professional users
        {
            "email": "emily.rodriguez@startup.co",
            "password": "password123",
            "name": "Emily Rodriguez",
            "tier": "professional",
            "days_ago": 20
        },
        {
            "email": "david.kim@analytics.com",
            "password": "password123",
            "name": "David Kim",
            "tier": "professional",
            "days_ago": 15
        },
        {
            "email": "lisa.thompson@dataworks.io",
            "password": "password123",
            "name": "Lisa Thompson",
            "tier": "professional",
            "days_ago": 10
        },
        # Starter users
        {
            "email": "alex.martinez@freelance.com",
            "password": "password123",
            "name": "Alex Martinez",
            "tier": "starter",
            "days_ago": 7
        },
        {
            "email": "jessica.lee@research.edu",
            "password": "password123",
            "name": "Jessica Lee",
            "tier": "starter",
            "days_ago": 5
        },
        {
            "email": "james.wilson@devstudio.com",
            "password": "password123",
            "name": "James Wilson",
            "tier": "starter",
            "days_ago": 3
        },
        {
            "email": "maria.garcia@mlteam.org",
            "password": "password123",
            "name": "Maria Garcia",
            "tier": "starter",
            "days_ago": 2
        },
        {
            "email": "robert.brown@ai-lab.net",
            "password": "password123",
            "name": "Robert Brown",
            "tier": "starter",
            "days_ago": 1
        }
    ]
    
    # Create all sample users
    created_count = 0
    for user_data in sample_users:
        if create_sample_user(**user_data):
            created_count += 1
    
    print()
    print("=" * 60)
    print(f"🎉 SAMPLE USER SETUP COMPLETE!")
    print("=" * 60)
    print(f"Created: {created_count} sample users")
    print(f"Total users in system: {len(user_store)}")
    print()
    print("Sample User Credentials:")
    print("-" * 60)
    for user_data in sample_users:
        print(f"📧 {user_data['name']}")
        print(f"   Email:    {user_data['email']}")
        print(f"   Password: {user_data['password']}")
        print(f"   Tier:     {user_data['tier']}")
        print()
    print("=" * 60)
    print("📋 Next Steps:")
    print("1. Navigate to http://localhost:3000/admin/users")
    print("2. You should see all users listed")
    print("3. Test filtering, searching, and pagination")
    print("=" * 60)
