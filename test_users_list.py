"""Quick test: admin login and user list (requires API + ADMIN_PASSWORD)."""
import os
import sys
import requests

BASE_URL = os.getenv("API_BASE_URL", "http://127.0.0.1:8004/api/v1")
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "admin@tiannara.com")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD")

if not ADMIN_PASSWORD:
    print("Set ADMIN_PASSWORD to run this test.")
    sys.exit(1)

print("Logging in...")
login_resp = requests.post(
    f"{BASE_URL}/auth/login",
    json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
    timeout=10,
)
if login_resp.status_code != 200:
    print(f"Login failed: {login_resp.text}")
    sys.exit(1)

token = login_resp.json().get("data", {}).get("token")
print("Logged in.\n")

print("Fetching users...")
users_resp = requests.get(
    f"{BASE_URL}/admin/users?page=1&limit=50",
    headers={"Authorization": f"Bearer {token}"},
    timeout=10,
)
if users_resp.status_code != 200:
    print(f"Failed: {users_resp.text}")
    sys.exit(1)

data = users_resp.json()
print(f"Total users: {data.get('pagination', {}).get('total', 0)}")
for user in data.get("users", []):
    print(f"  - {user['name']} ({user['email']}) tier={user['tier']} admin={user['is_admin']}")
