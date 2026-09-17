"""
Test Interpretability Engine Integration

Tests that workflow executor generates human-readable explanations for predictions,
trend analysis, and anomaly detection using the ExplanationEngine from Tiannara Core.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from tiannara_api.routes.workflow_executor import TiannaraWorkflowExecutor
from tiannara_api.routes.workflow_executor import ExecutionMode


def print_section(title: str):
    print("\n" + "=" * 80)
    print(f"  {title}")
    print("=" * 80)


def print_subsection(title: str):
    print(f"\n--- {title} ---")


async def test_prediction_explanation():
    """Test prediction nodes generate explanations."""
    print_section("TEST 1: Prediction Explanation (Forecasting)")
    
    executor = TiannaraWorkflowExecutor()
    
    workflow_id = "prediction_explanation_test"
    nodes = [
        {
            "id": "data_1",
            "type": "text_input",
            "data": {
                "config": {
                    "label": "Historical Sales Data",
                    "value": "Monthly sales data for past 6 months"
                }
            }
        },
        {
            "id": "forecast_1",
            "type": "prediction_engine",
            "data": {
                "config": {
                    "model_type": "exponential_smoothing",
                    "prediction_horizon": 3,
                    "task": "forecast"
                }
            }
        }
    ]
    
    edges = [
        {"source": "data_1", "target": "forecast_1"}
    ]
    
    input_data = {
        "historical_data": [
            {"date": "2026-01-01", "value": 100},
            {"date": "2026-02-01", "value": 115},
            {"date": "2026-03-01", "value": 108},
            {"date": "2026-04-01", "value": 125},
            {"date": "2026-05-01", "value": 130},
            {"date": "2026-06-01", "value": 142}
        ]
    }
    
    try:
        result = await executor.execute_workflow(
            workflow_id=workflow_id,
            nodes=nodes,
            edges=edges,
            input_data=input_data,
            execution_mode=ExecutionMode.SEQUENTIAL
        )
        
        print_subsection("Execution Results")
        print(f"✅ Status: {result.status}")
        print(f"   Total Time: {result.total_execution_time_ms:.2f}ms")
        
        # Check forecast node
        forecast_node = result.nodes.get("forecast_1")
        if forecast_node:
            print(f"\n📊 Forecast Node:")
            print(f"   Status: {forecast_node.status.value}")
            
            if forecast_node.result:
                result_data = forecast_node.result
                
                # Check for explanation
                if "explanation" in result_data:
                    print(f"   ✅ EXPLANATION GENERATED!")
                    print(f"   Type: {result_data['explanation'].get('type', 'N/A')}")
                    print(f"   Confidence: {result_data['explanation'].get('confidence', 0):.0%}")
                    print(f"   Model Used: {result_data['explanation'].get('model_used', 'N/A')}")
                    print(f"\n   📝 Explanation Text:")
                    expl_text = result_data['explanation'].get('explanation', '')
                    # Print with word wrapping
                    words = expl_text.split()
                    line = ""
                    for word in words:
                        if len(line) + len(word) + 1 > 70:
                            print(f"      {line}")
                            line = word
                        else:
                            line = f"{line} {word}" if line else word
                    if line:
                        print(f"      {line}")
                    
                    return True
                else:
                    print(f"   ❌ NO EXPLANATION FOUND")
                    print(f"   Result keys: {list(result_data.keys())}")
                    return False
        
        return False
        
    except Exception as e:
        print(f"\n❌ Exception: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_classification_explanation():
    """Test classification predictions generate explanations."""
    print_section("TEST 2: Classification Explanation")
    
    executor = TiannaraWorkflowExecutor()
    
    workflow_id = "classification_explanation_test"
    nodes = [
        {
            "id": "features_1",
            "type": "text_input",
            "data": {
                "config": {
                    "label": "Customer Features",
                    "value": "Age, income, purchase history features"
                }
            }
        },
        {
            "id": "classify_1",
            "type": "prediction_engine",
            "data": {
                "config": {
                    "model_type": "logistic_regression",
                    "task": "classify",
                    "classes": ["churn", "retain"]
                }
            }
        }
    ]
    
    edges = [
        {"source": "features_1", "target": "classify_1"}
    ]
    
    input_data = {
        "training_data": [
            {"features": [25, 50000, 10], "label": 0},
            {"features": [45, 80000, 50], "label": 0},
            {"features": [30, 40000, 5], "label": 1},
            {"features": [50, 90000, 60], "label": 0},
            {"features": [28, 35000, 3], "label": 1},
            {"features": [55, 100000, 80], "label": 0}
        ],
        "predict_data": [
            {"age": 35, "income": 60000, "purchases": 20}
        ]
    }
    
    try:
        result = await executor.execute_workflow(
            workflow_id=workflow_id,
            nodes=nodes,
            edges=edges,
            input_data=input_data,
            execution_mode=ExecutionMode.SEQUENTIAL
        )
        
        print_subsection("Execution Results")
        print(f"✅ Status: {result.status}")
        
        classify_node = result.nodes.get("classify_1")
        if classify_node and classify_node.result:
            result_data = classify_node.result
            
            if "explanation" in result_data:
                print(f"   ✅ EXPLANATION GENERATED!")
                print(f"   Type: {result_data['explanation'].get('type', 'N/A')}")
                print(f"   Confidence: {result_data['explanation'].get('confidence', 0):.0%}")
                print(f"\n   📝 Explanation Text:")
                expl_text = result_data['explanation'].get('explanation', '')
                words = expl_text.split()
                line = ""
                for word in words:
                    if len(line) + len(word) + 1 > 70:
                        print(f"      {line}")
                        line = word
                    else:
                        line = f"{line} {word}" if line else word
                if line:
                    print(f"      {line}")
                
                return True
            else:
                print(f"   ❌ NO EXPLANATION FOUND")
                return False
        
        return False
        
    except Exception as e:
        print(f"\n❌ Exception: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_trend_explanation():
    """Test trend analysis generates explanations."""
    print_section("TEST 3: Trend Analysis Explanation")
    
    executor = TiannaraWorkflowExecutor()
    
    workflow_id = "trend_explanation_test"
    nodes = [
        {
            "id": "data_1",
            "type": "text_input",
            "data": {
                "config": {
                    "label": "Performance Metrics",
                    "value": "Weekly performance data"
                }
            }
        },
        {
            "id": "trend_1",
            "type": "trend_analysis",
            "data": {
                "config": {
                    "analysis_type": "trend_tracking",
                    "domain": "temporal_engine"
                }
            }
        }
    ]
    
    edges = [
        {"source": "data_1", "target": "trend_1"}
    ]
    
    input_data = {
        "historical_data": [
            {"date": "2026-01-01", "value": 50},
            {"date": "2026-01-08", "value": 55},
            {"date": "2026-01-15", "value": 62},
            {"date": "2026-01-22", "value": 68},
            {"date": "2026-01-29", "value": 75},
            {"date": "2026-02-05", "value": 82}
        ]
    }
    
    try:
        result = await executor.execute_workflow(
            workflow_id=workflow_id,
            nodes=nodes,
            edges=edges,
            input_data=input_data,
            execution_mode=ExecutionMode.SEQUENTIAL
        )
        
        print_subsection("Execution Results")
        print(f"✅ Status: {result.status}")
        
        trend_node = result.nodes.get("trend_1")
        if trend_node and trend_node.result:
            result_data = trend_node.result
            
            if "explanation" in result_data:
                print(f"   ✅ EXPLANATION GENERATED!")
                print(f"   Type: {result_data['explanation'].get('type', 'N/A')}")
                print(f"   Confidence: {result_data['explanation'].get('confidence', 0):.0%}")
                print(f"   Trend Direction: {result_data.get('trend_direction', 'N/A')}")
                print(f"\n   📝 Explanation Text:")
                expl_text = result_data['explanation'].get('explanation', '')
                words = expl_text.split()
                line = ""
                for word in words:
                    if len(line) + len(word) + 1 > 70:
                        print(f"      {line}")
                        line = word
                    else:
                        line = f"{line} {word}" if line else word
                if line:
                    print(f"      {line}")
                
                return True
            else:
                print(f"   ❌ NO EXPLANATION FOUND")
                return False
        
        return False
        
    except Exception as e:
        print(f"\n❌ Exception: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_anomaly_explanation():
    """Test anomaly detection generates explanations."""
    print_section("TEST 4: Anomaly Detection Explanation")
    
    executor = TiannaraWorkflowExecutor()
    
    workflow_id = "anomaly_explanation_test"
    nodes = [
        {
            "id": "data_1",
            "type": "text_input",
            "data": {
                "config": {
                    "label": "Transaction Data",
                    "value": "Financial transaction records"
                }
            }
        },
        {
            "id": "anomaly_1",
            "type": "anomaly_detection",
            "data": {
                "config": {
                    "detection_type": "fraud",
                    "domain": "reverse_engineering"
                }
            }
        }
    ]
    
    edges = [
        {"source": "data_1", "target": "anomaly_1"}
    ]
    
    input_data = {
        "historical_data": [
            {"date": "2026-01-01", "amount": 100},
            {"date": "2026-01-02", "amount": 150},
            {"date": "2026-01-03", "amount": 120},
            {"date": "2026-01-04", "amount": 110},
            {"date": "2026-01-05", "amount": 130},
            {"date": "2026-01-06", "amount": 1000},  # Anomaly!
            {"date": "2026-01-07", "amount": 140},
            {"date": "2026-01-08", "amount": 125}
        ]
    }
    
    try:
        result = await executor.execute_workflow(
            workflow_id=workflow_id,
            nodes=nodes,
            edges=edges,
            input_data=input_data,
            execution_mode=ExecutionMode.SEQUENTIAL
        )
        
        print_subsection("Execution Results")
        print(f"✅ Status: {result.status}")
        
        anomaly_node = result.nodes.get("anomaly_1")
        if anomaly_node and anomaly_node.result:
            result_data = anomaly_node.result
            
            if "explanation" in result_data:
                print(f"   ✅ EXPLANATION GENERATED!")
                print(f"   Type: {result_data['explanation'].get('type', 'N/A')}")
                print(f"   Confidence: {result_data['explanation'].get('confidence', 0):.0%}")
                print(f"   Anomalies Detected: {result_data.get('anomalies_detected', 0)}")
                print(f"\n   📝 Explanation Text:")
                expl_text = result_data['explanation'].get('explanation', '')
                words = expl_text.split()
                line = ""
                for word in words:
                    if len(line) + len(word) + 1 > 70:
                        print(f"      {line}")
                        line = word
                    else:
                        line = f"{line} {word}" if line else word
                if line:
                    print(f"      {line}")
                
                return True
            else:
                print(f"   ❌ NO EXPLANATION FOUND")
                return False
        
        return False
        
    except Exception as e:
        print(f"\n❌ Exception: {e}")
        import traceback
        traceback.print_exc()
        return False


async def main():
    """Run all interpretability tests."""
    print("=" * 80)
    print("  INTERPRETABILITY ENGINE INTEGRATION TESTS")
    print("=" * 80)
    print("\nTesting explanation generation for predictions, trends, and anomalies...")
    
    results = []
    
    # Test 1: Forecasting explanation
    result1 = await test_prediction_explanation()
    results.append(("Prediction Explanation (Forecasting)", result1))
    
    # Test 2: Classification explanation
    result2 = await test_classification_explanation()
    results.append(("Classification Explanation", result2))
    
    # Test 3: Trend explanation
    result3 = await test_trend_explanation()
    results.append(("Trend Analysis Explanation", result3))
    
    # Test 4: Anomaly explanation
    result4 = await test_anomaly_explanation()
    results.append(("Anomaly Detection Explanation", result4))
    
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
        print("\n🎉 ALL INTERPRETABILITY TESTS PASSED!")
        print("   Explanations are being generated for all prediction types.")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed. Review output above.")
    
    return passed == total


if __name__ == "__main__":
    import asyncio
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
