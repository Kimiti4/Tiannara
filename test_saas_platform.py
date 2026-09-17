"""
Comprehensive Test Suite for Tiannara SaaS Platform

Tests:
1. OTP generation and verification
2. User signup flow
3. Login authentication
4. Rate limiting
5. API endpoint availability
6. Load testing (concurrent requests)
"""

import asyncio
import httpx
import time
import json
from typing import Dict, Any
from concurrent.futures import ThreadPoolExecutor, as_completed

API_BASE = "http://localhost:8003/api/v1"


class TiannaraTestSuite:
    """Comprehensive test suite for Tiannara platform."""
    
    def __init__(self):
        self.client = httpx.AsyncClient(timeout=30.0)
        self.results = []
        self.test_user_email = f"test_{int(time.time())}@tiannara.ai"
        self.otp_code = None  # Will be captured from dev mode
        
    async def cleanup(self):
        await self.client.aclose()
    
    def log_result(self, test_name: str, success: bool, details: str = ""):
        """Log test result."""
        status = "[PASS]" if success else "[FAIL]"
        print(f"\n{status} | {test_name}")
        if details:
            print(f"       {details}")
        
        self.results.append({
            "test": test_name,
            "success": success,
            "details": details
        })
    
    async def test_health_check(self):
        """Test 1: Health check endpoint."""
        try:
            response = await self.client.get("http://localhost:8003/health")
            success = response.status_code == 200
            self.log_result(
                "Health Check",
                success,
                f"Status: {response.status_code}, Version: {response.json().get('version', 'N/A')}"
            )
        except Exception as e:
            self.log_result("Health Check", False, str(e))
    
    async def test_otp_request(self):
        """Test 2: Request OTP for email verification."""
        try:
            response = await self.client.post(
                f"{API_BASE}/auth/request-otp",
                params={"email": self.test_user_email}
            )
            
            data = response.json()
            success = response.status_code == 200 and data.get("success")
            
            # In dev mode, OTP is returned in response
            if data.get("dev_mode"):
                self.otp_code = data.get("otp_code")
                print(f"       [DEV] OTP: {self.otp_code}")
            
            self.log_result(
                "OTP Request",
                success,
                f"Message: {data.get('message', 'N/A')}"
            )
        except Exception as e:
            self.log_result("OTP Request", False, str(e))
    
    async def test_signup_initiation(self):
        """Test 3: Initiate user signup."""
        try:
            payload = {
                "name": "Test User",
                "email": self.test_user_email,
                "password": "TestPassword123!",
                "tier": "starter"
            }
            
            response = await self.client.post(
                f"{API_BASE}/auth/signup",
                json=payload
            )
            
            data = response.json()
            
            # Expect 409 if already exists (from previous test)
            success = response.status_code in [200, 409]
            
            # Capture OTP code from dev mode
            if data.get("dev_mode"):
                self.otp_code = data.get("otp_code")
                print(f"       [DEV] Signup OTP: {self.otp_code}")
            
            self.log_result(
                "Signup Initiation",
                success,
                f"Status: {response.status_code}, Message: {data.get('message', 'N/A')}"
            )
        except Exception as e:
            self.log_result("Signup Initiation", False, str(e))
    
    async def test_otp_verification(self):
        """Test 4: Verify OTP code."""
        if not self.otp_code:
            self.log_result("OTP Verification", False, "No OTP code available (run OTP request first)")
            return
        
        try:
            payload = {
                "email": self.test_user_email,
                "otp_code": self.otp_code
            }
            
            response = await self.client.post(
                f"{API_BASE}/auth/verify-otp",
                json=payload
            )
            
            data = response.json()
            success = response.status_code == 200 and data.get("success")
            
            if success:
                self.auth_token = data.get("token")
                print(f"       🔑 Token received: {self.auth_token[:20]}...")
            
            self.log_result(
                "OTP Verification",
                success,
                f"Message: {data.get('message', 'N/A')}"
            )
        except Exception as e:
            self.log_result("OTP Verification", False, str(e))
    
    async def test_login(self):
        """Test 5: User login."""
        try:
            payload = {
                "email": self.test_user_email,
                "password": "TestPassword123!"
            }
            
            response = await self.client.post(
                f"{API_BASE}/auth/login",
                json=payload
            )
            
            data = response.json()
            success = response.status_code == 200 and data.get("success")
            
            if success:
                self.auth_token = data.get("token")
            
            self.log_result(
                "User Login",
                success,
                f"Message: {data.get('message', 'N/A')}"
            )
        except Exception as e:
            self.log_result("User Login", False, str(e))
    
    async def test_get_profile(self):
        """Test 6: Get user profile with JWT token."""
        if not hasattr(self, 'auth_token'):
            self.log_result("Get Profile", False, "No auth token (login first)")
            return
        
        try:
            response = await self.client.get(
                f"{API_BASE}/auth/me",
                headers={"Authorization": f"Bearer {self.auth_token}"}
            )
            
            data = response.json()
            success = response.status_code == 200 and data.get("success")
            
            self.log_result(
                "Get Profile",
                success,
                f"User: {data.get('user', {}).get('email', 'N/A')}"
            )
        except Exception as e:
            self.log_result("Get Profile", False, str(e))
    
    async def test_rate_limiting(self):
        """Test 7: Rate limiting on OTP requests."""
        try:
            # Send 5 rapid requests (limit is 3 per 5 min)
            responses = []
            for i in range(5):
                response = await self.client.post(
                    f"{API_BASE}/auth/request-otp",
                    params={"email": f"ratelimit_test_{i}@tiannara.ai"}
                )
                responses.append(response.status_code)
            
            # At least one should be rate limited (429)
            rate_limited = any(status == 429 for status in responses)
            
            self.log_result(
                "Rate Limiting",
                rate_limited,
                f"Responses: {responses} (429 = rate limited)"
            )
        except Exception as e:
            self.log_result("Rate Limiting", False, str(e))
    
    async def test_api_endpoints(self):
        """Test 8: Check all major API endpoints are accessible."""
        endpoints = [
            "/autonomous/cycle",
            "/discovery/analyze",
            "/evolution/run",
            "/memory/store",
            "/modules/list",
            "/payment/plans",
            "/efficiency/health",
            "/monitoring/health",
        ]
        
        results = []
        for endpoint in endpoints:
            try:
                response = await self.client.get(f"{API_BASE}{endpoint}")
                # Some might require auth or POST, so just check they exist
                exists = response.status_code != 404
                results.append((endpoint, exists, response.status_code))
            except Exception as e:
                results.append((endpoint, False, str(e)))
        
        all_accessible = all(r[1] for r in results)
        
        details = ", ".join([f"{e}: {s}" for e, s, _ in results])
        self.log_result(
            "API Endpoints",
            all_accessible,
            details
        )
    
    async def test_concurrent_requests(self):
        """Test 9: Handle concurrent requests (load test)."""
        try:
            async def make_request(i: int):
                try:
                    response = await self.client.get(f"{API_BASE}/health")
                    return response.status_code == 200
                except Exception:
                    return False
            
            # Send 50 concurrent requests
            tasks = [make_request(i) for i in range(50)]
            results = await asyncio.gather(*tasks)
            
            success_count = sum(results)
            success_rate = success_count / len(results) * 100
            
            self.log_result(
                "Concurrent Requests (50)",
                success_rate >= 95,
                f"Success rate: {success_rate:.1f}% ({success_count}/{len(results)})"
            )
        except Exception as e:
            self.log_result("Concurrent Requests", False, str(e))
    
    async def test_invalid_credentials(self):
        """Test 10: Reject invalid login credentials."""
        try:
            payload = {
                "email": "nonexistent@tiannara.ai",
                "password": "wrongpassword"
            }
            
            response = await self.client.post(
                f"{API_BASE}/auth/login",
                json=payload
            )
            
            # Should return 401
            success = response.status_code == 401
            
            self.log_result(
                "Invalid Credentials Rejected",
                success,
                f"Status: {response.status_code} (expected 401)"
            )
        except Exception as e:
            self.log_result("Invalid Credentials", False, str(e))
    
    async def run_all_tests(self):
        """Run complete test suite."""
        print("\n" + "="*80)
        print("TIANNARA SAAS PLATFORM - COMPREHENSIVE TEST SUITE")
        print("="*80)
        print(f"\nStarted at: {time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"API Base: {API_BASE}")
        print(f"Test User: {self.test_user_email}")
        print("\n" + "-"*80)
        
        start_time = time.time()
        
        # Run tests in logical order
        await self.test_health_check()
        await self.test_otp_request()
        await self.test_signup_initiation()
        await self.test_otp_verification()
        await self.test_login()
        await self.test_get_profile()
        await self.test_rate_limiting()
        await self.test_api_endpoints()
        await self.test_concurrent_requests()
        await self.test_invalid_credentials()
        
        elapsed = time.time() - start_time
        
        # Print summary
        print("\n" + "="*80)
        print("TEST SUMMARY")
        print("="*80)
        
        passed = sum(1 for r in self.results if r["success"])
        failed = len(self.results) - passed
        total = len(self.results)
        
        print(f"\nTotal Tests: {total}")
        print(f"Passed: {passed} [OK]")
        print(f"Failed: {failed} [FAIL]")
        print(f"Success Rate: {passed/total*100:.1f}%")
        print(f"Time Elapsed: {elapsed:.2f}s")
        
        if failed > 0:
            print("\nFailed Tests:")
            for r in self.results:
                if not r["success"]:
                    print(f"  [FAIL] {r['test']}: {r['details']}")
        
        print("\n" + "="*80)
        
        await self.cleanup()
        
        return passed == total


async def main():
    """Main test runner."""
    test_suite = TiannaraTestSuite()
    all_passed = await test_suite.run_all_tests()
    
    if all_passed:
        print("\n*** All tests passed! System is production-ready.")
        return 0
    else:
        print("\n[WARN] Some tests failed. Review issues above.")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    exit(exit_code)
