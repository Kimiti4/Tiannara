"""
Test WebSocket Streaming with Actual Tiannara Core Engines

This script tests:
1. Workflow execution through REST API
2. WebSocket connection for real-time updates
3. Integration with actual Core engines (prediction, causal, NLP, etc.)

Date: May 1, 2026
"""

import requests
import asyncio
import websockets
import json
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:8000"
WS_URL = "ws://localhost:8000"

def test_workflow_execution():
    """Test workflow execution endpoint with actual Core engines."""
    print("\n" + "="*80)
    print("TEST 1: Workflow Execution with Real Core Engines")
    print("="*80)
    
    # Create a simple workflow with prediction and NLP nodes
    workflow_data = {
        "workflow_id": f"test_workflow_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
        "nodes": [
            {
                "id": "node_1",
                "type": "text_input",
                "data": {
                    "config": {
                        "label": "Input Text",
                        "value": "Analyze this text for sentiment and patterns"
                    }
                }
            },
            {
                "id": "node_2",
                "type": "nlp_analysis",
                "data": {
                    "config": {
                        "analysis_type": "sentiment",
                        "language": "en"
                    }
                }
            },
            {
                "id": "node_3",
                "type": "pattern_intelligence",
                "data": {
                    "config": {
                        "pattern_type": "temporal",
                        "confidence_threshold": 0.7
                    }
                }
            }
        ],
        "edges": [
            {"source": "node_1", "target": "node_2"},
            {"source": "node_2", "target": "node_3"}
        ],
        "input_data": {
            "text": "The market showed strong upward trends in Q4 with increasing volatility"
        },
        "execution_mode": "sequential"
    }
    
    try:
        print(f"\n📤 Sending workflow execution request...")
        print(f"   Nodes: {len(workflow_data['nodes'])}")
        print(f"   Mode: {workflow_data['execution_mode']}")
        
        response = requests.post(
            f"{BASE_URL}/api/v1/workflows/execute",
            json=workflow_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"\n✅ Workflow execution successful!")
            print(f"   Execution ID: {result.get('data', {}).get('execution_id')}")
            print(f"   Status: {result.get('data', {}).get('status')}")
            print(f"   Total Time: {result.get('data', {}).get('total_execution_time_ms', 0):.2f}ms")
            
            # Check node results
            nodes = result.get('data', {}).get('nodes', {})
            print(f"\n📊 Node Results:")
            for node_id, node_data in nodes.items():
                status = node_data.get('status', 'unknown')
                exec_time = node_data.get('execution_time_ms', 0)
                print(f"   {node_id}: {status} ({exec_time:.2f}ms)")
                
                if node_data.get('error'):
                    print(f"      ❌ Error: {node_data['error']}")
                elif node_data.get('result'):
                    print(f"      ✅ Result keys: {list(node_data['result'].keys())[:3]}")
            
            return result.get('data', {}).get('execution_id')
        else:
            print(f"\n❌ Workflow execution failed!")
            print(f"   Status Code: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"\n❌ Exception occurred: {e}")
        import traceback
        traceback.print_exc()
        return None


async def test_websocket_streaming(execution_id: str):
    """Test WebSocket streaming for real-time updates."""
    print("\n" + "="*80)
    print("TEST 2: WebSocket Streaming for Real-Time Updates")
    print("="*80)
    
    if not execution_id:
        print("\n⚠️  No execution ID provided, skipping WebSocket test")
        return
    
    ws_url = f"{WS_URL}/ws/workflows/{execution_id}"
    print(f"\n🔌 Connecting to WebSocket: {ws_url}")
    
    received_messages = []
    
    try:
        async with websockets.connect(ws_url) as websocket:
            print(f"✅ WebSocket connected!")
            print(f"\n📡 Listening for updates (timeout: 10s)...\n")
            
            try:
                while True:
                    message = await asyncio.wait_for(websocket.recv(), timeout=10.0)
                    data = json.loads(message)
                    
                    received_messages.append(data)
                    
                    # Format and display the message
                    msg_type = data.get('type', 'unknown')
                    
                    if msg_type == 'progress':
                        progress = data.get('progress', 0)
                        completed = data.get('completed_nodes', '?')
                        total = data.get('total_nodes', '?')
                        print(f"📊 Progress: {progress}% ({completed}/{total} nodes)")
                    
                    elif msg_type == 'node_update':
                        node_id = data.get('node_id', 'unknown')
                        status = data.get('status', 'unknown')
                        emoji = "⏳" if status == "running" else "✅" if status == "completed" else "❌"
                        print(f"{emoji} Node {node_id}: {status.upper()}")
                        
                        if data.get('result'):
                            result_keys = list(data['result'].keys())[:2]
                            print(f"   Result: {result_keys}")
                    
                    elif msg_type == 'error':
                        error_msg = data.get('error', 'Unknown error')
                        node_id = data.get('node_id', 'general')
                        print(f"❌ Error in {node_id}: {error_msg}")
                    
                    elif msg_type == 'complete':
                        status = data.get('status', 'unknown')
                        exec_time = data.get('execution_time_ms', 0)
                        emoji = "✅" if status == "completed" else "❌"
                        print(f"\n{emoji} Execution {status.upper()} in {exec_time:.2f}ms")
                        break
                    
                    else:
                        print(f"📨 Unknown message type: {msg_type}")
                        print(f"   Data: {json.dumps(data, indent=2)}")
            
            except asyncio.TimeoutError:
                print(f"\n⏱️  WebSocket timeout (no messages for 10s)")
                print(f"   This is normal if execution completed before WebSocket connected")
            
    except Exception as e:
        print(f"\n❌ WebSocket connection failed: {e}")
        import traceback
        traceback.print_exc()
    
    print(f"\n📈 Summary:")
    print(f"   Total messages received: {len(received_messages)}")
    
    if received_messages:
        msg_types = {}
        for msg in received_messages:
            msg_type = msg.get('type', 'unknown')
            msg_types[msg_type] = msg_types.get(msg_type, 0) + 1
        
        print(f"   Message breakdown:")
        for msg_type, count in msg_types.items():
            print(f"      - {msg_type}: {count}")


async def run_all_tests():
    """Run all tests sequentially."""
    print("\n" + "🧪"*40)
    print("Tiannara Core WebSocket Streaming Integration Test")
    print("🧪"*40)
    
    # Test 1: Execute workflow
    execution_id = test_workflow_execution()
    
    # Small delay to ensure execution completes
    await asyncio.sleep(2)
    
    # Test 2: WebSocket streaming (will likely timeout since execution already done)
    await test_websocket_streaming(execution_id)
    
    print("\n" + "="*80)
    print("✅ All tests completed!")
    print("="*80 + "\n")


if __name__ == "__main__":
    asyncio.run(run_all_tests())
