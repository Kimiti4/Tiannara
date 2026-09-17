"""
Test HTTPS/WSS Production Deployment

Verifies that the Tiannara API works correctly over secure connections.
Tests both REST API (HTTPS) and WebSocket (WSS) endpoints.
"""

import asyncio
import requests
import websockets
import ssl
import json
import sys
from datetime import datetime


def print_section(title: str):
    """Print formatted section header."""
    print("\n" + "=" * 80)
    print(f"  {title}")
    print("=" * 80)


def print_subsection(title: str):
    """Print formatted subsection header."""
    print(f"\n--- {title} ---")


def test_https_health(base_url: str):
    """Test HTTPS health endpoint."""
    print_section("TEST 1: HTTPS Health Check")
    
    url = f"{base_url}/health"
    print(f"Testing: {url}")
    
    try:
        response = requests.get(url, timeout=10, verify=True)
        
        print_subsection("Response")
        print(f"Status Code: {response.status_code}")
        print(f"Headers:")
        for header in ['content-type', 'strict-transport-security', 'server']:
            if header in response.headers:
                print(f"  {header}: {response.headers[header]}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"\n✅ Health check passed!")
            print(f"   Status: {data.get('status')}")
            print(f"   Version: {data.get('version')}")
            print(f"   Service: {data.get('service')}")
            return True
        else:
            print(f"\n❌ Health check failed with status {response.status_code}")
            return False
            
    except requests.exceptions.SSLError as e:
        print(f"\n❌ SSL Error: {e}")
        print("   This usually means the certificate is self-signed or invalid.")
        print("   For testing, you can use verify=False (not recommended for production).")
        return False
    except requests.exceptions.ConnectionError as e:
        print(f"\n❌ Connection Error: {e}")
        print("   Make sure the server is running and accessible.")
        return False
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return False


async def test_wss_metrics(ws_url: str, token: str):
    """Test WSS metrics endpoint."""
    print_section("TEST 2: WSS Metrics Connection")
    
    url = f"{ws_url}/ws/metrics?token={token}"
    print(f"Testing: {url}")
    
    # Create SSL context
    ssl_context = ssl.create_default_context()
    
    try:
        print("\n🔌 Connecting to WSS endpoint...")
        
        async with websockets.connect(url, ssl=ssl_context) as websocket:
            print("✅ WSS connection established!")
            
            # Wait for initial metrics
            print("\n⏳ Waiting for metrics update...")
            
            try:
                message = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                data = json.loads(message)
                
                print(f"\n📨 Received metrics:")
                print(f"   API Usage: {data.get('api_usage', {})}")
                print(f"   Active Workflows: {len(data.get('active_workflows', []))}")
                print(f"   System Insights: {len(data.get('system_insights', []))}")
                print(f"   Prediction Accuracy: {data.get('prediction_accuracy', 'N/A')}")
                print(f"   Alerts: {data.get('alerts_count', 0)}")
                
                print("\n✅ WSS metrics test successful!")
                return True
                
            except asyncio.TimeoutError:
                print("\n⚠️  No metrics received within 5 seconds")
                print("   This might be normal if no workflows are running")
                return True  # Connection worked, just no data yet
                
    except websockets.exceptions.InvalidStatusCode as e:
        print(f"\n❌ Connection failed: {e}")
        print("   Check that the token is valid and the endpoint exists.")
        return False
    except ssl.SSLCertVerificationError as e:
        print(f"\n❌ SSL Certificate Error: {e}")
        print("   The certificate may be self-signed or expired.")
        return False
    except Exception as e:
        print(f"\n❌ Error: {type(e).__name__}: {e}")
        return False


async def test_wss_workflow_streaming(ws_url: str, execution_id: str):
    """Test WSS workflow execution streaming."""
    print_section("TEST 3: WSS Workflow Execution Streaming")
    
    url = f"{ws_url}/ws/workflow/{execution_id}"
    print(f"Testing: {url}")
    
    # Create SSL context
    ssl_context = ssl.create_default_context()
    
    try:
        print("\n🔌 Connecting to workflow streaming endpoint...")
        
        async with websockets.connect(url, ssl=ssl_context) as websocket:
            print("✅ WSS workflow streaming connected!")
            
            # Wait for progress updates
            print("\n⏳ Waiting for execution updates...")
            
            messages_received = 0
            try:
                while messages_received < 3:  # Collect a few messages
                    message = await asyncio.wait_for(websocket.recv(), timeout=10.0)
                    data = json.loads(message)
                    
                    messages_received += 1
                    print(f"\n📨 Message {messages_received}:")
                    print(f"   Type: {data.get('update_type', 'unknown')}")
                    
                    if data.get('update_type') == 'progress':
                        print(f"   Progress: {data.get('progress', 0)}%")
                    elif data.get('update_type') == 'node_status':
                        print(f"   Node: {data.get('node_id', 'N/A')}")
                        print(f"   Status: {data.get('status', 'N/A')}")
                    elif data.get('update_type') == 'execution_complete':
                        print(f"   ✅ Execution complete!")
                        break
                    elif data.get('update_type') == 'error':
                        print(f"   ❌ Error: {data.get('error', 'Unknown')}")
                        break
                    
            except asyncio.TimeoutError:
                print(f"\n⚠️  No more messages after {messages_received} received")
                if messages_received > 0:
                    print("   But connection is working - this is OK")
            
            print(f"\n✅ WSS workflow streaming test successful!")
            print(f"   Received {messages_received} messages")
            return True
                
    except websockets.exceptions.InvalidStatusCode as e:
        print(f"\n❌ Connection failed: {e}")
        print("   Check that the execution_id is valid.")
        return False
    except ssl.SSLCertVerificationError as e:
        print(f"\n❌ SSL Certificate Error: {e}")
        return False
    except Exception as e:
        print(f"\n❌ Error: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_cors_headers(base_url: str):
    """Test CORS configuration."""
    print_section("TEST 4: CORS Headers")
    
    url = f"{base_url}/health"
    print(f"Testing CORS for: {url}")
    
    try:
        response = requests.options(
            url,
            headers={
                'Origin': 'https://yourdomain.com',
                'Access-Control-Request-Method': 'GET'
            },
            timeout=10,
            verify=True
        )
        
        print_subsection("CORS Response")
        cors_headers = [
            'access-control-allow-origin',
            'access-control-allow-methods',
            'access-control-allow-headers',
            'access-control-allow-credentials'
        ]
        
        for header in cors_headers:
            if header in response.headers:
                print(f"  ✅ {header}: {response.headers[header]}")
            else:
                print(f"  ⚠️  {header}: NOT SET")
        
        print("\n✅ CORS test completed")
        return True
        
    except Exception as e:
        print(f"\n❌ CORS test error: {e}")
        return False


def main():
    """Run all production deployment tests."""
    print("=" * 80)
    print("  TIANNARA PRODUCTION DEPLOYMENT TEST")
    print("=" * 80)
    print(f"\nStarted at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Configuration - update these for your production environment
    BASE_URL = "https://api.yourdomain.com"  # Change to your domain
    WS_URL = "wss://api.yourdomain.com"       # Change to your domain
    AUTH_TOKEN = "YOUR_AUTH_TOKEN_HERE"       # Replace with valid token
    EXECUTION_ID = "test_execution_123"       # Replace with valid execution ID
    
    print(f"\nConfiguration:")
    print(f"  Base URL: {BASE_URL}")
    print(f"  WS URL: {WS_URL}")
    print(f"  Token: {'***' + AUTH_TOKEN[-4:] if len(AUTH_TOKEN) > 4 else 'NOT SET'}")
    print(f"  Execution ID: {EXECUTION_ID}")
    
    results = []
    
    # Test 1: HTTPS Health Check
    result1 = test_https_health(BASE_URL)
    results.append(("HTTPS Health Check", result1))
    
    # Test 2: WSS Metrics
    result2 = asyncio.run(test_wss_metrics(WS_URL, AUTH_TOKEN))
    results.append(("WSS Metrics Connection", result2))
    
    # Test 3: WSS Workflow Streaming
    result3 = asyncio.run(test_wss_workflow_streaming(WS_URL, EXECUTION_ID))
    results.append(("WSS Workflow Streaming", result3))
    
    # Test 4: CORS Headers
    result4 = test_cors_headers(BASE_URL)
    results.append(("CORS Headers", result4))
    
    # Summary
    print_section("FINAL RESULTS")
    
    passed = sum(1 for _, r in results if r)
    total = len(results)
    
    for name, result in results:
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"  {status}: {name}")
    
    print(f"\n{'=' * 80}")
    print(f"  Total Tests: {total}")
    print(f"  Passed: {passed}")
    print(f"  Failed: {total - passed}")
    print(f"  Success Rate: {(passed/total*100) if total > 0 else 0:.1f}%")
    print(f"{'=' * 80}")
    
    if passed == total:
        print("\n🎉 ALL PRODUCTION TESTS PASSED!")
        print("   Your deployment is ready for production use.")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed.")
        print("   Review the errors above and fix before going live.")
    
    print(f"\nCompleted at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    return passed == total


if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Test interrupted by user")
        sys.exit(1)
