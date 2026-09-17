"""Test admin login and endpoints (requires running API + ADMIN_PASSWORD)."""
import os
import json
import requests

BASE_URL = os.getenv("API_BASE_URL", "http://127.0.0.1:8004/api/v1")
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "admin@tiannara.com")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD")


def test_admin_login():
    if not ADMIN_PASSWORD:
        print("Set ADMIN_PASSWORD to run this test.")
        return None

    print("Testing admin login...")
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
        timeout=10,
    )
    if response.status_code != 200:
        print(f"Login failed: {response.status_code} {response.text}")
        return None

    data = response.json()
    token = (data.get("data") or {}).get("token") or data.get("token")
    if token:
        print("Login successful.")
        return token
    print(f"No token in response: {json.dumps(data, indent=2)}")
    return None


def test_admin_metrics(token: str):
    print("Testing /admin/metrics...")
    response = requests.get(
        f"{BASE_URL}/admin/metrics",
        headers={"Authorization": f"Bearer {token}"},
        timeout=10,
    )
    print(f"Status: {response.status_code}")
    if response.ok:
        print("Admin metrics OK.")
    else:
        print(response.text[:500])


if __name__ == "__main__":
    t = test_admin_login()
    if t:
        test_admin_metrics(t)
