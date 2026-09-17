"""
Direct Backend Test for WebSocket Streaming with Tiannara Core Engines

This script tests the workflow executor directly without HTTP authentication,
allowing us to verify WebSocket streaming works with actual Core engines.

Date: May 1, 2026
"""

import asyncio
import sys
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent))

from tiannara_api.routes.workflow_executor import get_workflow_executor, ExecutionMode


async def test_simple_workflow():
    """Test simple workflow execution with actual Core engines."""
    print("\n" + "="*80)
    print("TEST: Direct Workflow Execution with Real Core Engines")
    print("="*80)
    
    # Get workflow executor instance
    executor = get_workflow_executor()
    
    # Create a simple workflow definition
    workflow_id = "test_direct_execution"
    nodes = [
        {
            "id": "node_1",
            "type": "text_input",
            "data": {
                "config": {
                    "label": "Input Text",
                    "value": "Test input for NLP analysis"
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
        }
    ]
    
    edges = [
        {"source": "node_1", "target": "node_2"}
    ]
    
    input_data = {
        "text": "The market showed strong upward trends in Q4 with increasing volatility"
    }
    
    print(f"\n📤 Executing workflow...")
    print(f"   Workflow ID: {workflow_id}")
    print(f"   Nodes: {len(nodes)}")
    print(f"   Edges: {len(edges)}")
    print(f"   Mode: sequential")
    print(f"   Input: {input_data['text'][:50]}...")
    
    try:
        # Execute workflow
        result = await executor.execute_workflow(
            workflow_id=workflow_id,
            nodes=nodes,
            edges=edges,
            input_data=input_data,
            execution_mode=ExecutionMode.SEQUENTIAL
        )
        
        print(f"\n✅ Workflow execution completed!")
        print(f"   Execution ID: {result.execution_id}")
        print(f"   Status: {result.status}")
        print(f"   Total Time: {result.total_execution_time_ms:.2f}ms")
        
        # Display node results
        print(f"\n📊 Node Results:")
        for node_id, node in result.nodes.items():
            status = node.status.value
            exec_time = node.execution_time_ms or 0
            print(f"\n   {node_id}:")
            print(f"      Type: {node.type}")
            print(f"      Status: {status}")
            print(f"      Execution Time: {exec_time:.2f}ms")
            
            if node.error:
                print(f"      ❌ Error: {node.error}")
            elif node.result:
                print(f"      ✅ Result type: {type(node.result).__name__}")
                if isinstance(node.result, dict):
                    print(f"      Result keys: {list(node.result.keys())[:3]}")
        
        return result.execution_id
        
    except Exception as e:
        print(f"\n❌ Exception occurred: {e}")
        import traceback
        traceback.print_exc()
        return None


async def test_prediction_workflow():
    """Test workflow with prediction engine."""
    print("\n" + "="*80)
    print("TEST: Prediction Engine Integration")
    print("="*80)
    
    executor = get_workflow_executor()
    
    workflow_id = "test_prediction_engine"
    nodes = [
        {
            "id": "node_1",
            "type": "prediction_engine",
            "data": {
                "config": {
                    "model_type": "linear_regression",
                    "prediction_horizon": 7
                }
            }
        }
    ]
    
    edges = []
    input_data = {
        "historical_data": [100, 105, 110, 108, 115, 120, 118]
    }
    
    print(f"\n📤 Testing prediction engine...")
    
    try:
        result = await executor.execute_workflow(
            workflow_id=workflow_id,
            nodes=nodes,
            edges=edges,
            input_data=input_data,
            execution_mode=ExecutionMode.SEQUENTIAL
        )
        
        print(f"\n✅ Prediction workflow completed!")
        print(f"   Status: {result.status}")
        print(f"   Total Time: {result.total_execution_time_ms:.2f}ms")
        
        for node_id, node in result.nodes.items():
            print(f"\n   {node_id}:")
            print(f"      Status: {node.status.value}")
            if node.result:
                print(f"      Result: {str(node.result)[:200]}")
        
        return result.execution_id
        
    except Exception as e:
        print(f"\n❌ Prediction test failed: {e}")
        import traceback
        traceback.print_exc()
        return None


async def run_all_tests():
    """Run all direct backend tests."""
    print("\n" + "="*80)
    print("Tiannara Core Direct Backend Tests")
    print("="*80)
    
    # Test 1: Simple NLP workflow
    exec_id_1 = await test_simple_workflow()
    
    # Test 2: Prediction engine
    exec_id_2 = await test_prediction_workflow()
    
    print("\n" + "="*80)
    print("✅ All direct backend tests completed!")
    print("="*80 + "\n")
    
    print("Summary:")
    print(f"  - NLP Workflow: {'✅ PASSED' if exec_id_1 else '❌ FAILED'}")
    print(f"  - Prediction Workflow: {'✅ PASSED' if exec_id_2 else '❌ FAILED'}")
    print()


if __name__ == "__main__":
    asyncio.run(run_all_tests())
