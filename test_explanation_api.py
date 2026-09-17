"""
Explanation API Test Script

Tests the REST API endpoints for EU AI Act compliance.

Usage:
    python test_explanation_api.py
    
Note: Requires FastAPI server running on http://localhost:8000
"""

import requests
import json
from typing import Dict, Any

BASE_URL = "http://localhost:8000/api/v1/explanations"


def test_health():
    """Test health check endpoint."""
    print("\n" + "=" * 80)
    print("TEST 1: Health Check")
    print("=" * 80)
    
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    assert response.status_code == 200
    assert response.json()['status'] in ['healthy', 'unhealthy']
    
    print("\n[PASS] Health check working")
    return True


def test_explain_decision():
    """Test decision explanation endpoint."""
    print("\n" + "=" * 80)
    print("TEST 2: Explain Decision")
    print("=" * 80)
    
    request_data = {
        "target_node": "final_outcome",
        "audience": "end_user",
        "include_counterfactuals": True,
        "include_uncertainty": True,
        "user_id": "test_user_001",
        "ecm_graph": {
            "nodes": ["skill_memory", "pattern_recognition", "solution_quality", "final_outcome"],
            "edges": [
                ["skill_memory", "pattern_recognition", 0.85],
                ["pattern_recognition", "solution_quality", 0.90],
                ["solution_quality", "final_outcome", 0.80]
            ]
        }
    }
    
    response = requests.post(f"{BASE_URL}/explain", json=request_data)
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"\nExplanation Type: {result['explanation_type']}")
        print(f"Target Node: {result['target_node']}")
        print(f"Confidence: {result['confidence']:.3f}")
        print(f"Record ID: {result['record_id']}")
        print(f"\nExplanation (first 200 chars):")
        print(f"  {result['explanation_text'][:200]}...")
        
        assert result['success'] is True
        assert len(result['explanation_text']) > 0
        
        print("\n[PASS] Decision explanation working")
        return True
    else:
        print(f"ERROR: {response.text}")
        return False


def test_counterfactual():
    """Test counterfactual endpoint."""
    print("\n" + "=" * 80)
    print("TEST 3: Counterfactual Analysis")
    print("=" * 80)
    
    request_data = {
        "question": "What if skill_memory increased by 0.2?",
        "audience": "technical",
        "user_id": "test_user_002"
    }
    
    response = requests.post(f"{BASE_URL}/counterfactual", json=request_data)
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"\nExplanation Type: {result['explanation_type']}")
        print(f"Record ID: {result['record_id']}")
        print(f"\nCounterfactual (first 200 chars):")
        print(f"  {result['explanation_text'][:200]}...")
        
        assert result['success'] is True
        
        print("\n[PASS] Counterfactual analysis working")
        return True
    else:
        print(f"ERROR: {response.text}")
        return False


def test_audit_trail():
    """Test audit trail retrieval."""
    print("\n" + "=" * 80)
    print("TEST 4: Audit Trail")
    print("=" * 80)
    
    response = requests.get(f"{BASE_URL}/audit?limit=10")
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"\nTotal Records: {result['total_records']}")
        print(f"Success: {result['success']}")
        
        if result['records']:
            print(f"\nFirst Record:")
            print(f"  ID: {result['records'][0]['record_id']}")
            print(f"  Type: {result['records'][0]['explanation_type']}")
            print(f"  Target: {result['records'][0]['target_node']}")
        
        assert result['success'] is True
        
        print("\n[PASS] Audit trail retrieval working")
        return True
    else:
        print(f"ERROR: {response.text}")
        return False


def test_statistics():
    """Test statistics endpoint."""
    print("\n" + "=" * 80)
    print("TEST 5: Statistics")
    print("=" * 80)
    
    response = requests.get(f"{BASE_URL}/statistics")
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"\nCache Size: {result['cache_size']}")
        print(f"Success: {result['success']}")
        
        if 'audit_trail_stats' in result:
            stats = result['audit_trail_stats']
            print(f"Audit Records: {stats.get('total_records', 0)}")
        
        assert result['success'] is True
        
        print("\n[PASS] Statistics retrieval working")
        return True
    else:
        print(f"ERROR: {response.text}")
        return False


def main():
    """Run all API tests."""
    print("\n" + "=" * 80)
    print("EXPLANATION API TEST SUITE")
    print("=" * 80)
    print("\nNote: Requires FastAPI server running on http://localhost:8000")
    print("Start server with: uvicorn tiannara_api.main:app --reload\n")
    
    # Check if server is running
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=2)
    except requests.exceptions.ConnectionError:
        print("ERROR: Cannot connect to server. Is it running?")
        print("Start with: uvicorn tiannara_api.main:app --reload")
        return False
    
    tests = [
        ("Health Check", test_health),
        ("Explain Decision", test_explain_decision),
        ("Counterfactual", test_counterfactual),
        ("Audit Trail", test_audit_trail),
        ("Statistics", test_statistics),
    ]
    
    passed = 0
    failed = 0
    
    for name, test_func in tests:
        try:
            if test_func():
                passed += 1
            else:
                failed += 1
        except Exception as e:
            print(f"\nERROR: {name} failed with exception: {e}")
            import traceback
            traceback.print_exc()
            failed += 1
    
    print("\n" + "=" * 80)
    print(f"RESULTS: {passed} passed, {failed} failed out of {len(tests)} tests")
    print("=" * 80)
    
    if failed == 0:
        print("\nALL TESTS PASSED!")
        return True
    else:
        print(f"\n{failed} test(s) failed")
        return False


if __name__ == "__main__":
    import sys
    success = main()
    sys.exit(0 if success else 1)
