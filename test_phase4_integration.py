#!/usr/bin/env python3
"""
Phase 4 Backend Integration Test Suite

Tests all REST API endpoints and verifies backend connectivity.
Run after starting backend services.
"""

import asyncio
import httpx
import sys
from typing import Dict, Any
from datetime import datetime

# Configuration
API_BASE_URL = "http://localhost:8000/api/v1"
WS_URL = "ws://localhost:4000/socket/websocket"

# Test results tracking
tests_passed = 0
tests_failed = 0
tests_skipped = 0


def print_header(text: str):
    """Print formatted test header."""
    print(f"\n{'='*60}")
    print(f"  {text}")
    print(f"{'='*60}\n")


def print_test(name: str):
    """Print test name."""
    print(f"🧪 Testing: {name}...", end=" ")


def print_success(detail: str = ""):
    """Print success message."""
    global tests_passed
    tests_passed += 1
    print(f"✅ PASS {detail}")


def print_failure(error: str):
    """Print failure message."""
    global tests_failed
    tests_failed += 1
    print(f"❌ FAIL: {error}")


def print_skip(reason: str):
    """Print skip message."""
    global tests_skipped
    tests_skipped += 1
    print(f"⏭️  SKIP: {reason}")


async def test_health_check():
    """Test observatory health endpoint."""
    print_test("Observatory Health Check")
    
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{API_BASE_URL}/observatory/health")
            
            if response.status_code == 200:
                data = response.json()
                
                if data.get("status") in ["healthy", "degraded"]:
                    print_success(f"(Status: {data['status']})")
                    
                    # Check runtime backend status
                    runtime_status = data.get("runtime_backend", "unknown")
                    if runtime_status == "connected":
                        print(f"   📡 Runtime Backend: Connected")
                    else:
                        print(f"   ⚠️  Runtime Backend: {runtime_status} (may need to start Tiannara Runtime)")
                    
                    # Check WebSocket channels
                    channels = data.get("websocket_channels", [])
                    print(f"   🔌 WebSocket Channels: {len(channels)} available")
                    for channel in channels:
                        print(f"      - {channel}")
                else:
                    print_failure(f"Unexpected status: {data.get('status')}")
            else:
                print_failure(f"HTTP {response.status_code}: {response.text}")
    except httpx.ConnectError:
        print_failure("Cannot connect to Tiannara API (port 8000)")
        print("   → Start API: cd tiannara_api && uvicorn main:app --reload --port 8000")
    except Exception as e:
        print_failure(str(e))


async def test_node_inspector():
    """Test node inspector endpoint."""
    print_test("Node Inspector Data Retrieval")
    
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{API_BASE_URL}/observatory/nodes/C_ALPHA")
            
            if response.status_code == 200:
                data = response.json()
                
                required_fields = ["node_id", "coherence", "entropy", "stability_score", "members"]
                missing = [f for f in required_fields if f not in data]
                
                if not missing:
                    print_success(f"(Node: {data['node_id']}, Coherence: {data['coherence']:.2f})")
                else:
                    print_failure(f"Missing fields: {', '.join(missing)}")
            else:
                print_failure(f"HTTP {response.status_code}")
    except Exception as e:
        print_failure(str(e))


async def test_predictions():
    """Test predictive overlay endpoint."""
    print_test("Predictive Overlay Forecasts")
    
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{API_BASE_URL}/observatory/predictions")
            
            if response.status_code == 200:
                data = response.json()
                
                predictions = data.get("predictions", [])
                if len(predictions) > 0:
                    print_success(f"({len(predictions)} coalition(s) with predictions)")
                    
                    # Show first prediction details
                    pred = predictions[0]
                    future_states = pred.get("future_states", [])
                    print(f"   Coalition: {pred['coalition_id']}")
                    print(f"   Future States: {len(future_states)}")
                    
                    if future_states:
                        first_state = future_states[0]
                        print(f"   Next State (t+{first_state['timestamp'] - pred['timestamp']:.0f}s):")
                        print(f"      Coherence: {first_state['predicted_coherence']:.2f}")
                        print(f"      Probability: {first_state['probability']:.2%}")
                        print(f"      Collapse Risk: {first_state['collapse_risk']:.2%}")
                else:
                    print_success("(No active predictions)")
            else:
                print_failure(f"HTTP {response.status_code}")
    except Exception as e:
        print_failure(str(e))


async def test_causal_chain():
    """Test causal chain retrieval."""
    print_test("Causal Chain Exploration")
    
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{API_BASE_URL}/observatory/causality/test_trace_001")
            
            if response.status_code == 200:
                data = response.json()
                
                events = data.get("events", [])
                if len(events) > 0:
                    print_success(f"({len(events)} events in causal chain)")
                    
                    # Show event types
                    event_types = {}
                    for event in events:
                        event_type = event.get("type", "unknown")
                        event_types[event_type] = event_types.get(event_type, 0) + 1
                    
                    print(f"   Event Types:")
                    for etype, count in event_types.items():
                        print(f"      - {etype}: {count}")
                else:
                    print_success("(Empty causal chain)")
            else:
                print_failure(f"HTTP {response.status_code}")
    except Exception as e:
        print_failure(str(e))


async def test_meta_control():
    """Test meta-control state endpoint."""
    print_test("Meta-Control Dashboard State")
    
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{API_BASE_URL}/observatory/meta-control")
            
            if response.status_code == 200:
                data = response.json()
                
                required_sections = ["cis", "cal", "stability_metrics", "stability_score"]
                missing = [s for s in required_sections if s not in data]
                
                if not missing:
                    print_success(f"(Stability Score: {data['stability_score']:.2f})")
                    
                    # Show CIS parameters
                    cis = data.get("cis", {})
                    print(f"   CIS Parameters:")
                    for param, value in cis.items():
                        print(f"      - {param}: {value:.2f}")
                    
                    # Show CAL parameters
                    cal = data.get("cal", {})
                    print(f"   CAL Parameters:")
                    for param, value in cal.items():
                        print(f"      - {param}: {value:.2f}")
                    
                    # Show stability metrics
                    metrics = data.get("stability_metrics", {})
                    print(f"   Stability Metrics:")
                    for metric, value in metrics.items():
                        print(f"      - {metric}: {value:.2f}")
                else:
                    print_failure(f"Missing sections: {', '.join(missing)}")
            else:
                print_failure(f"HTTP {response.status_code}")
    except Exception as e:
        print_failure(str(e))


async def test_timeline():
    """Test timeline snapshots endpoint."""
    print_test("Timeline Replay Snapshots")
    
    try:
        now = datetime.utcnow().timestamp()
        start_time = now - 3600  # 1 hour ago
        end_time = now
        
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(
                f"{API_BASE_URL}/observatory/timeline",
                params={"start": start_time, "end": end_time}
            )
            
            if response.status_code == 200:
                data = response.json()
                
                snapshots = data.get("snapshots", [])
                total_count = data.get("total_count", 0)
                
                if total_count > 0:
                    print_success(f"({total_count} snapshots retrieved)")
                    
                    if snapshots:
                        first = snapshots[0]
                        last = snapshots[-1]
                        print(f"   Time Range: {first['timestamp']:.0f} → {last['timestamp']:.0f}")
                        print(f"   Duration: {(last['timestamp'] - first['timestamp']) / 60:.1f} minutes")
                        
                        # Show coalition count
                        if first.get("coalitions"):
                            print(f"   Coalitions per Snapshot: ~{len(first['coalitions'])}")
                else:
                    print_success("(No snapshots in time range)")
            else:
                print_failure(f"HTTP {response.status_code}")
    except Exception as e:
        print_failure(str(e))


async def test_universe_state():
    """Test WebGL universe state endpoint."""
    print_test("WebGL Universe State")
    
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{API_BASE_URL}/observatory/universe")
            
            if response.status_code == 200:
                data = response.json()
                
                agents = data.get("agents", [])
                coalitions = data.get("coalitions", [])
                cis_fields = data.get("cis_fields", [])
                cal_decisions = data.get("cal_decisions", [])
                
                print_success(f"({len(agents)} agents, {len(coalitions)} coalitions)")
                
                print(f"   Agents: {len(agents)}")
                print(f"   Coalitions: {len(coalitions)}")
                print(f"   CIS Fields: {len(cis_fields)}")
                print(f"   CAL Decisions: {len(cal_decisions)}")
                
                # Show sample agent
                if agents:
                    agent = agents[0]
                    print(f"   Sample Agent ({agent['id']}):")
                    print(f"      Position: [{agent['position'][0]:.2f}, {agent['position'][1]:.2f}, {agent['position'][2]:.2f}]")
                    print(f"      Status: {agent['status']}")
                    print(f"      Coherence: {agent['coherence']:.2f}")
            else:
                print_failure(f"HTTP {response.status_code}")
    except Exception as e:
        print_failure(str(e))


async def test_websocket_connectivity():
    """Test WebSocket channel connectivity."""
    print_test("WebSocket Channel Connectivity")
    
    try:
        import websockets
        
        channels_to_test = [
            "visualization:stream",
            "predictive:futures",
            "causality:traces",
            "metacontrol:dashboard",
            "identity:taxonomy"
        ]
        
        connected_channels = 0
        
        for channel in channels_to_test:
            try:
                async with websockets.connect(WS_URL) as websocket:
                    # Send join message
                    join_msg = {
                        "topic": channel,
                        "event": "phx_join",
                        "payload": {},
                        "ref": "1"
                    }
                    await websocket.send(str(join_msg).replace("'", '"'))
                    
                    # Wait for response
                    try:
                        response = await asyncio.wait_for(websocket.recv(), timeout=2.0)
                        connected_channels += 1
                    except asyncio.TimeoutError:
                        pass
            except Exception:
                pass
        
        if connected_channels > 0:
            print_success(f"({connected_channels}/{len(channels_to_test)} channels connected)")
        else:
            print_skip("Tiannara Runtime not running (port 4000)")
            print("   → Start Runtime: cd tiannara_runtime && mix phx.server")
    except ImportError:
        print_skip("websockets library not installed")
        print("   → Install: pip install websockets")
    except Exception as e:
        print_skip(f"WebSocket connection failed: {str(e)}")


async def run_all_tests():
    """Run complete test suite."""
    print_header("Phase 4 Backend Integration Test Suite")
    
    print(f"Testing endpoints at: {API_BASE_URL}")
    print(f"Testing WebSocket at: {WS_URL}")
    print(f"Time: {datetime.utcnow().isoformat()}")
    
    # Run all tests
    await test_health_check()
    await test_node_inspector()
    await test_predictions()
    await test_causal_chain()
    await test_meta_control()
    await test_timeline()
    await test_universe_state()
    await test_websocket_connectivity()
    
    # Print summary
    print_header("Test Summary")
    
    total = tests_passed + tests_failed + tests_skipped
    
    print(f"Total Tests:  {total}")
    print(f"✅ Passed:    {tests_passed}")
    print(f"❌ Failed:    {tests_failed}")
    print(f"⏭️  Skipped:   {tests_skipped}")
    print()
    
    if tests_failed == 0 and tests_passed > 0:
        print("🎉 All tests passed! Phase 4 backend integration is working correctly.")
        return 0
    elif tests_failed > 0:
        print("⚠️  Some tests failed. Check error messages above.")
        return 1
    else:
        print("⚠️  No tests were executed. Ensure backend services are running.")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(run_all_tests())
    sys.exit(exit_code)
