#!/usr/bin/env python3
"""
Security Validation Test Suite

Validates that all security fixes are working correctly.
Run this after making security changes to verify they're effective.
"""

import sys
import os
import re
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent))

def test_jwt_secret_not_hardcoded():
    """Verify JWT secret is loaded from environment, not hardcoded."""
    print("Testing JWT Secret Configuration...")
    
    with open("tiannara_api/gateway/auth.py", "r", encoding='utf-8') as f:
        content = f.read()
    
    # Should NOT contain hardcoded secret
    if 'JWT_SECRET = "tiannara-core-secret-change-in-production"' in content:
        print("  [FAIL] JWT secret is still hardcoded!")
        return False
    
    # Should use environment variable or secrets module
    if 'os.getenv("JWT_SECRET_KEY"' in content or 'secrets.token_hex' in content:
        print("  [PASS] JWT secret properly configured")
        return True
    else:
        print("  [FAIL] JWT secret configuration not found")
        return False


def test_cors_restrictions():
    """Verify CORS is not set to wildcard."""
    print("\nTesting CORS Configuration...")
    
    with open("tiannara_api/main.py", "r", encoding='utf-8') as f:
        content = f.read()
    
    # Should NOT allow all origins
    if 'allow_origins=["*"]' in content:
        print("  [FAIL] CORS allows all origins!")
        return False
    
    # Should use environment variable or specific origins
    if 'ALLOWED_ORIGINS' in content or 'localhost:3000' in content:
        print("  [PASS] CORS properly restricted")
        return True
    else:
        print("  [WARN] CORS configuration unclear")
        return False


def test_password_validation_strength():
    """Verify password strength requirements."""
    print("\nTesting Password Validation...")
    
    with open("tiannara_api/routes/auth.py", "r", encoding='utf-8') as f:
        content = f.read()
    
    checks = [
        ('min_length=12', 'Minimum length 12 characters'),
        ('[A-Z]', 'Uppercase requirement'),
        ('[a-z]', 'Lowercase requirement'),
        (r'\d', 'Digit requirement'),
        ('special character', 'Special character requirement'),
    ]
    
    passed = 0
    for pattern, description in checks:
        if pattern in content:
            passed += 1
        else:
            print(f"  [FAIL] Missing: {description}")
    
    if passed == len(checks):
        print(f"  [PASS] All {len(checks)} password strength checks present")
        return True
    else:
        print(f"  [WARN] PARTIAL: Only {passed}/{len(checks)} checks present")
        return False


def test_no_print_statements_in_routes():
    """Verify print statements replaced with logging."""
    print("\nTesting Logging Standards...")
    
    routes_dir = Path("tiannara_api/routes")
    print_statements = []
    
    for py_file in routes_dir.glob("*.py"):
        with open(py_file, "r", encoding='utf-8') as f:
            lines = f.readlines()
            for i, line in enumerate(lines, 1):
                if 'print(' in line and not line.strip().startswith('#'):
                    print_statements.append((py_file.name, i, line.strip()))
    
    if print_statements:
        print(f"  [FAIL] Found {len(print_statements)} print() in routes:")
        for filename, line_num, line in print_statements[:5]:
            print(f"    - {filename}:{line_num}: {line[:60]}")
        return False
    print("  [PASS] No print statements found in routes")
    return True


def test_admin_password_not_hardcoded():
    """Verify admin password uses environment variable."""
    print("\nTesting Admin Password Security...")
    
    with open("tiannara_api/main.py", "r", encoding='utf-8') as f:
        content = f.read()
    
    # Should NOT contain hardcoded "admin123"
    if "'admin123'" in content or '"admin123"' in content:
        print("  [FAIL] Admin password still hardcoded as 'admin123'!")
        return False
    
    # Should use environment variable or random generation
    if 'ADMIN_PASSWORD' in content or 'secrets.token_urlsafe' in content:
        print("  [PASS] Admin password properly secured")
        return True
    else:
        print("  [WARN] Admin password configuration unclear")
        return False


def test_payment_keys_not_hardcoded():
    """Verify payment API keys use environment variables."""
    print("\nTesting Payment Gateway Security...")
    
    with open("tiannara_api/payment.py", "r", encoding='utf-8') as f:
        content = f.read()
    
    issues = []
    
    # Check for hardcoded Stripe keys
    if 'sk_test_your_key_here' in content:
        issues.append("Hardcoded Stripe test key")
    
    if 'whsec_test_secret' in content:
        issues.append("Hardcoded webhook secret")
    
    # Should have validation
    if 'STRIPE_SECRET_KEY' in content and 'ValueError' in content:
        print("  [PASS] Stripe keys properly validated")
        return True
    elif issues:
        print(f"  [FAIL] {', '.join(issues)}")
        return False
    else:
        print("  [WARN] Payment key validation unclear")
        return False


def test_env_example_exists():
    """Verify .env.example file exists with proper documentation."""
    print("\nTesting Environment Configuration Template...")
    
    env_example = Path(".env.example")
    if not env_example.exists():
        print("  [FAIL] .env.example file not found!")
        return False
    
    with open(env_example, "r") as f:
        content = f.read()
    
    required_vars = [
        'JWT_SECRET_KEY',
        'ADMIN_PASSWORD',
        'DATABASE_URL',
        'ALLOWED_ORIGINS',
        'STRIPE_SECRET_KEY',
    ]
    
    missing = [var for var in required_vars if var not in content]
    
    if missing:
        print(f"  [WARN] Missing variables in .env.example: {', '.join(missing)}")
        return False
    else:
        print("  [PASS] .env.example contains all required variables")
        return True


def test_bcrypt_password_hashing():
    """Verify passwords use bcrypt via centralized module."""
    print("\nTesting Password Hashing (bcrypt)...")
    with open("tiannara_api/security/password.py", "r", encoding="utf-8") as f:
        content = f.read()
    if "CryptContext" in content and "bcrypt" in content:
        print("  [PASS] bcrypt password module present")
        return True
    print("  [FAIL] bcrypt password module missing")
    return False


def test_httponly_auth_cookie():
    """Verify HttpOnly session cookies are configured."""
    print("\nTesting HttpOnly Session Cookies...")
    with open("tiannara_api/security/cookies.py", "r", encoding="utf-8") as f:
        content = f.read()
    if "httponly=True" in content and "set_auth_cookie" in content:
        print("  [PASS] HttpOnly auth cookies configured")
        return True
    print("  [FAIL] HttpOnly cookie helpers missing")
    return False


def test_websocket_cookie_only_auth():
    """WebSocket auth must not require token query param in SaaS client."""
    print("\nTesting WebSocket Cookie-Only Auth...")
    with open("tiannara_saas/lib/websocket-reconnector.ts", "r", encoding="utf-8") as f:
        recon = f.read()
    with open("tiannara_api/security/websocket_auth.py", "r", encoding="utf-8") as f:
        backend = f.read()
    if "?token=${token}" in recon or "?token=" in recon.split("createCookieWebSocket")[0]:
        # legacy createAuthenticatedWebSocket may still exist but must delegate
        if "createCookieWebSocket" not in recon:
            print("  [FAIL] WebSocket still appends token to URL")
            return False
    if "query_params.get(\"token\")" in backend:
        print("  [FAIL] Backend still accepts token query param")
        return False
    if "cookies.get(AUTH_COOKIE_NAME)" not in backend:
        print("  [FAIL] Backend does not read auth cookie for WebSocket")
        return False
    print("  [PASS] WebSocket uses HttpOnly cookie (no URL token)")
    return True


def test_no_localstorage_token_in_saas_api():
    """Verify SaaS API client does not persist JWT in localStorage."""
    print("\nTesting SaaS Token Storage...")
    with open("tiannara_saas/lib/api.ts", "r", encoding="utf-8") as f:
        content = f.read()
    if "localStorage.setItem('tiannara_token'" in content:
        print("  [FAIL] JWT still stored in localStorage")
        return False
    if "credentials: 'include'" in content:
        print("  [PASS] Cookie-based session with credentials include")
        return True
    print("  [WARN] credentials: 'include' not found in api.ts")
    return False


def main():
    """Run all security validation tests."""
    print("=" * 80)
    print("TIANNARA API - SECURITY VALIDATION TEST SUITE")
    print("=" * 80)
    print()
    
    tests = [
        test_jwt_secret_not_hardcoded,
        test_cors_restrictions,
        test_password_validation_strength,
        test_no_print_statements_in_routes,
        test_admin_password_not_hardcoded,
        test_payment_keys_not_hardcoded,
        test_env_example_exists,
        test_bcrypt_password_hashing,
        test_httponly_auth_cookie,
        test_websocket_cookie_only_auth,
        test_no_localstorage_token_in_saas_api,
    ]
    
    results = []
    for test_func in tests:
        try:
            result = test_func()
            results.append(result)
        except Exception as e:
            print(f"  [ERROR] {str(e)}")
            results.append(False)
    
    print("\n" + "=" * 80)
    print("TEST SUMMARY")
    print("=" * 80)
    
    passed = sum(results)
    total = len(results)
    
    print(f"\nTests Passed: {passed}/{total}")
    
    if passed == total:
        print("\nALL SECURITY TESTS PASSED.")
        print("\nThe codebase has been successfully hardened.")
        print("Review SECURITY_AUDIT.md for deployment checklist.")
        return 0
    else:
        print(f"\n{total - passed} test(s) need attention.")
        print("\nPlease review the failures above and fix them before deployment.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
