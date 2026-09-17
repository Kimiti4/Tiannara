"""
Real Template Deployment Test

This script tests the complete template catalog by deploying and executing
actual templates through Tiannara Core engines with real data.

Tests:
1. Customer Intelligence (Starter)
2. Predictive Insights (Starter)
3. Fraud Detection Intelligence (Professional)
4. Business Intelligence Hub (Professional)
5. Historical Reconstruction Engine (Enterprise - WOW FACTOR)
"""

import asyncio
import sys
from pathlib import Path
from datetime import datetime, timezone

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent))

from tiannara_api.routes.workflow_executor import get_workflow_executor, ExecutionMode


def print_section(title: str):
    """Print a formatted section header."""
    print("\n" + "=" * 80)
    print(f"  {title}")
    print("=" * 80)


def print_subsection(title: str):
    """Print a formatted subsection header."""
    print(f"\n{'─' * 60}")
    print(f"  {title}")
    print(f"{'─' * 60}")


async def test_customer_intelligence():
    """Test Template #1: Customer Intelligence (Starter Tier)"""
    print_section("TEST 1: Customer Intelligence Template (Starter)")
    
    executor = get_workflow_executor()
    
    # Template workflow definition from workflow-templates.ts
    workflow_id = "customer_intelligence_test"
    nodes = [
        {
            "id": "data_1",
            "type": "text_input",
            "data": {
                "config": {
                    "label": "Customer Data",
                    "value": "Sample customer dataset with profiles, transactions, and interactions"
                }
            }
        },
        {
            "id": "pattern_1",
            "type": "nlp_analysis",
            "data": {
                "config": {
                    "analysis_type": "sentiment",
                    "language": "en",
                    "method": "clustering"
                }
            }
        },
        {
            "id": "causal_1",
            "type": "trend_analysis",
            "data": {
                "config": {
                    "analysis_type": "driver_analysis",
                    "domain": "causal_engine"
                }
            }
        },
        {
            "id": "predict_1",
            "type": "prediction_engine",
            "data": {
                "config": {
                    "model_type": "classification",
                    "prediction_horizon": 30,
                    "tasks": ["churn", "ltv"]
                }
            }
        },
        {
            "id": "recommend_1",
            "type": "anomaly_detection",
            "data": {
                "config": {
                    "detection_type": "recommendation",
                    "action_type": "campaigns"
                }
            }
        }
    ]
    
    edges = [
        {"source": "data_1", "target": "pattern_1"},
        {"source": "pattern_1", "target": "causal_1"},
        {"source": "causal_1", "target": "predict_1"},
        {"source": "predict_1", "target": "recommend_1"}
    ]
    
    input_data = {
        "text": "Customer behavior analysis: High-value customers show consistent engagement patterns with 85% retention rate. At-risk customers exhibit declining activity over 30-day period.",
        "historical_data": [
            {"date": "2026-01-01", "value": 100},
            {"date": "2026-01-02", "value": 105},
            {"date": "2026-01-03", "value": 98},
            {"date": "2026-01-04", "value": 110},
            {"date": "2026-01-05", "value": 115}
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
        print(f"   Execution ID: {result.execution_id}")
        print(f"   Total Time: {result.total_execution_time_ms:.2f}ms")
        
        print(f"\n📊 Node Execution Summary:")
        for node_id, node in result.nodes.items():
            status_icon = "✅" if node.status.value == "completed" else "❌"
            exec_time = node.execution_time_ms or 0
            print(f"   {status_icon} {node_id} ({node.type}): {node.status.value} ({exec_time:.2f}ms)")
            
            if node.error:
                print(f"      Error: {node.error}")
            elif node.result:
                if isinstance(node.result, dict):
                    keys = list(node.result.keys())[:3]
                    print(f"      Result keys: {keys}")
        
        return result.status == "completed"
        
    except Exception as e:
        print(f"\n❌ Exception: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_predictive_insights():
    """Test Template #2: Predictive Insights (Starter Tier)"""
    print_section("TEST 2: Predictive Insights Template (Starter)")
    
    executor = get_workflow_executor()
    
    workflow_id = "predictive_insights_test"
    nodes = [
        {
            "id": "data_1",
            "type": "text_input",
            "data": {
                "config": {
                    "label": "Historical Data",
                    "value": "Time-series metrics data for trend forecasting"
                }
            }
        },
        {
            "id": "temporal_1",
            "type": "trend_analysis",
            "data": {
                "config": {
                    "analysis_type": "temporal_patterns",
                    "decomposition": "trend_seasonal"
                }
            }
        },
        {
            "id": "causal_1",
            "type": "trend_analysis",
            "data": {
                "config": {
                    "analysis_type": "driver_analysis",
                    "method": "granger_causality"
                }
            }
        },
        {
            "id": "predict_1",
            "type": "prediction_engine",
            "data": {
                "config": {
                    "model_type": "time_series",
                    "prediction_horizon": 90,
                    "horizons": ["7d", "30d", "90d"]
                }
            }
        },
        {
            "id": "scenario_1",
            "type": "anomaly_detection",
            "data": {
                "config": {
                    "detection_type": "scenario_modeling",
                    "format": "charts"
                }
            }
        }
    ]
    
    edges = [
        {"source": "data_1", "target": "temporal_1"},
        {"source": "temporal_1", "target": "causal_1"},
        {"source": "causal_1", "target": "predict_1"},
        {"source": "predict_1", "target": "scenario_1"}
    ]
    
    input_data = {
        "text": "Market trends showing upward trajectory with seasonal variations. Key drivers include economic indicators and consumer sentiment.",
        "historical_data": [
            {"date": "2026-01-01", "value": 1000},
            {"date": "2026-01-02", "value": 1050},
            {"date": "2026-01-03", "value": 1025},
            {"date": "2026-01-04", "value": 1100},
            {"date": "2026-01-05", "value": 1150},
            {"date": "2026-01-06", "value": 1125},
            {"date": "2026-01-07", "value": 1200}
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
        print(f"   Execution ID: {result.execution_id}")
        print(f"   Total Time: {result.total_execution_time_ms:.2f}ms")
        
        print(f"\n📊 Node Execution Summary:")
        for node_id, node in result.nodes.items():
            status_icon = "✅" if node.status.value == "completed" else "❌"
            exec_time = node.execution_time_ms or 0
            print(f"   {status_icon} {node_id} ({node.type}): {node.status.value} ({exec_time:.2f}ms)")
        
        return result.status == "completed"
        
    except Exception as e:
        print(f"\n❌ Exception: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_fraud_detection():
    """Test Template #5: Fraud Detection Intelligence (Professional Tier)"""
    print_section("TEST 3: Fraud Detection Intelligence Template (Professional)")
    
    executor = get_workflow_executor()
    
    workflow_id = "fraud_detection_test"
    nodes = [
        {
            "id": "transactions_1",
            "type": "text_input",
            "data": {
                "config": {
                    "label": "Transaction Stream",
                    "value": "Real-time transaction monitoring data"
                }
            }
        },
        {
            "id": "anomaly_1",
            "type": "anomaly_detection",
            "data": {
                "config": {
                    "detection_type": "anomaly",
                    "domain": "reverse_engineering"
                }
            }
        },
        {
            "id": "pattern_1",
            "type": "nlp_analysis",
            "data": {
                "config": {
                    "analysis_type": "pattern_recognition",
                    "method": "signature_matching"
                }
            }
        },
        {
            "id": "score_1",
            "type": "prediction_engine",
            "data": {
                "config": {
                    "model_type": "classification",
                    "prediction_horizon": 1
                }
            }
        },
        {
            "id": "explain_1",
            "type": "trend_analysis",
            "data": {
                "config": {
                    "analysis_type": "explanation",
                    "format": "detailed_report"
                }
            }
        }
    ]
    
    edges = [
        {"source": "transactions_1", "target": "anomaly_1"},
        {"source": "anomaly_1", "target": "pattern_1"},
        {"source": "pattern_1", "target": "score_1"},
        {"source": "score_1", "target": "explain_1"}
    ]
    
    input_data = {
        "text": "Suspicious transaction pattern detected: Multiple high-value transfers from new account within 24-hour window. Unusual geographic distribution.",
        "historical_data": [
            {"transaction_id": "TXN001", "amount": 5000, "timestamp": "2026-01-01T10:00:00"},
            {"transaction_id": "TXN002", "amount": 7500, "timestamp": "2026-01-01T11:30:00"},
            {"transaction_id": "TXN003", "amount": 10000, "timestamp": "2026-01-01T14:00:00"}
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
        print(f"   Execution ID: {result.execution_id}")
        print(f"   Total Time: {result.total_execution_time_ms:.2f}ms")
        
        print(f"\n📊 Node Execution Summary:")
        for node_id, node in result.nodes.items():
            status_icon = "✅" if node.status.value == "completed" else "❌"
            exec_time = node.execution_time_ms or 0
            print(f"   {status_icon} {node_id} ({node.type}): {node.status.value} ({exec_time:.2f}ms)")
        
        return result.status == "completed"
        
    except Exception as e:
        print(f"\n❌ Exception: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_business_intelligence():
    """Test Template #7: Business Intelligence Hub (Professional Tier)"""
    print_section("TEST 4: Business Intelligence Hub Template (Professional)")
    
    executor = get_workflow_executor()
    
    workflow_id = "business_intelligence_test"
    nodes = [
        {
            "id": "data_1",
            "type": "text_input",
            "data": {
                "config": {
                    "label": "Business Data",
                    "value": "KPIs, metrics, and operational performance data"
                }
            }
        },
        {
            "id": "causal_1",
            "type": "trend_analysis",
            "data": {
                "config": {
                    "analysis_type": "driver_analysis",
                    "domain": "causal_engine"
                }
            }
        },
        {
            "id": "nlp_1",
            "type": "nlp_analysis",
            "data": {
                "config": {
                    "analysis_type": "summarization",
                    "task": "executive_summary"
                }
            }
        },
        {
            "id": "temporal_1",
            "type": "trend_analysis",
            "data": {
                "config": {
                    "analysis_type": "trend_tracking",
                    "domain": "temporal_engine"
                }
            }
        },
        {
            "id": "dashboard_1",
            "type": "anomaly_detection",
            "data": {
                "config": {
                    "detection_type": "insight_generation",
                    "format": "interactive"
                }
            }
        }
    ]
    
    edges = [
        {"source": "data_1", "target": "causal_1"},
        {"source": "causal_1", "target": "nlp_1"},
        {"source": "nlp_1", "target": "temporal_1"},
        {"source": "temporal_1", "target": "dashboard_1"}
    ]
    
    input_data = {
        "text": "Q4 business performance: Revenue up 15% YoY, customer acquisition cost decreased 8%, churn rate stable at 3.2%. Key growth drivers: enterprise segment expansion and product innovation.",
        "historical_data": [
            {"quarter": "Q1-2025", "revenue": 1000000, "customers": 500},
            {"quarter": "Q2-2025", "revenue": 1100000, "customers": 550},
            {"quarter": "Q3-2025", "revenue": 1250000, "customers": 620},
            {"quarter": "Q4-2025", "revenue": 1400000, "customers": 700}
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
        print(f"   Execution ID: {result.execution_id}")
        print(f"   Total Time: {result.total_execution_time_ms:.2f}ms")
        
        print(f"\n📊 Node Execution Summary:")
        for node_id, node in result.nodes.items():
            status_icon = "✅" if node.status.value == "completed" else "❌"
            exec_time = node.execution_time_ms or 0
            print(f"   {status_icon} {node_id} ({node.type}): {node.status.value} ({exec_time:.2f}ms)")
        
        return result.status == "completed"
        
    except Exception as e:
        print(f"\n❌ Exception: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_historical_reconstruction():
    """Test Template #11: Historical Reconstruction Engine (Enterprise - WOW FACTOR)"""
    print_section("TEST 5: Historical Reconstruction Engine Template (Enterprise - WOW FACTOR)")
    
    executor = get_workflow_executor()
    
    workflow_id = "historical_reconstruction_test"
    nodes = [
        {
            "id": "evidence_1",
            "type": "text_input",
            "data": {
                "config": {
                    "label": "Available Evidence",
                    "value": "Archaeological fragments, historical records, and artifact documentation"
                }
            }
        },
        {
            "id": "pattern_1",
            "type": "nlp_analysis",
            "data": {
                "config": {
                    "analysis_type": "pattern_extraction",
                    "method": "reconstruction"
                }
            }
        },
        {
            "id": "hypothesis_1",
            "type": "trend_analysis",
            "data": {
                "config": {
                    "analysis_type": "hypothesis_generation",
                    "domain": "memory_system"
                }
            }
        },
        {
            "id": "evolve_1",
            "type": "anomaly_detection",
            "data": {
                "config": {
                    "detection_type": "evolution",
                    "domain": "evolution_engine"
                }
            }
        },
        {
            "id": "experiment_1",
            "type": "prediction_engine",
            "data": {
                "config": {
                    "model_type": "experimental_design",
                    "prediction_horizon": 1
                }
            }
        }
    ]
    
    edges = [
        {"source": "evidence_1", "target": "pattern_1"},
        {"source": "pattern_1", "target": "hypothesis_1"},
        {"source": "hypothesis_1", "target": "evolve_1"},
        {"source": "evolve_1", "target": "experiment_1"}
    ]
    
    input_data = {
        "text": "Ancient technology reconstruction: Fragmented mechanical device with gear ratios suggesting astronomical calculation purpose. Inscriptions reference celestial cycles. Missing components hypothesized based on similar artifacts.",
        "historical_data": [
            {"artifact_id": "ART001", "component": "gear_assembly", "teeth_count": 48},
            {"artifact_id": "ART002", "component": "pointer_mechanism", "material": "bronze"},
            {"artifact_id": "ART003", "component": "inscription_fragment", "text": "lunar cycle"}
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
        print(f"   Execution ID: {result.execution_id}")
        print(f"   Total Time: {result.total_execution_time_ms:.2f}ms")
        
        print(f"\n📊 Node Execution Summary:")
        for node_id, node in result.nodes.items():
            status_icon = "✅" if node.status.value == "completed" else "❌"
            exec_time = node.execution_time_ms or 0
            print(f"   {status_icon} {node_id} ({node.type}): {node.status.value} ({exec_time:.2f}ms)")
            
            if node.result and isinstance(node.result, dict):
                result_type = node.result.get('type', 'unknown')
                print(f"      Type: {result_type}")
        
        return result.status == "completed"
        
    except Exception as e:
        print(f"\n❌ Exception: {e}")
        import traceback
        traceback.print_exc()
        return False


async def main():
    """Run all template deployment tests."""
    print("\n" + "=" * 80)
    print("  TIANNARA SAAS - REAL TEMPLATE DEPLOYMENT TEST")
    print("  Testing Complete Template Catalog with Tiannara Core Engines")
    print("=" * 80)
    print(f"\n  Start Time: {datetime.now(timezone.utc).isoformat()}")
    print(f"  Templates to Test: 5 (representing all tiers)")
    print("\n" + "=" * 80)
    
    results = {}
    
    # Test 1: Customer Intelligence (Starter)
    results['customer_intelligence'] = await test_customer_intelligence()
    
    # Test 2: Predictive Insights (Starter)
    results['predictive_insights'] = await test_predictive_insights()
    
    # Test 3: Fraud Detection (Professional)
    results['fraud_detection'] = await test_fraud_detection()
    
    # Test 4: Business Intelligence (Professional)
    results['business_intelligence'] = await test_business_intelligence()
    
    # Test 5: Historical Reconstruction (Enterprise - WOW FACTOR)
    results['historical_reconstruction'] = await test_historical_reconstruction()
    
    # Print final summary
    print_section("FINAL TEST SUMMARY")
    
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    
    print(f"\n  Templates Tested: {total}")
    print(f"  Passed: {passed}")
    print(f"  Failed: {total - passed}")
    print(f"  Success Rate: {(passed/total*100):.1f}%")
    
    print(f"\n  Detailed Results:")
    for template_name, success in results.items():
        status = "✅ PASSED" if success else "❌ FAILED"
        tier = ""
        if "customer" in template_name or "predictive" in template_name:
            tier = "(Starter)"
        elif "fraud" in template_name or "business" in template_name:
            tier = "(Professional)"
        elif "historical" in template_name:
            tier = "(Enterprise - WOW FACTOR)"
        print(f"    {status}: {template_name.replace('_', ' ').title()} {tier}")
    
    print(f"\n  End Time: {datetime.now(timezone.utc).isoformat()}")
    print("\n" + "=" * 80)
    
    if passed == total:
        print("\n🎉 ALL TEMPLATE TESTS PASSED! Template catalog is ready for production.")
    else:
        print(f"\n⚠️  {total - passed} template(s) failed. Review errors above.")
    
    print("\n" + "=" * 80)
    
    return passed == total


if __name__ == "__main__":
    try:
        success = asyncio.run(main())
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
