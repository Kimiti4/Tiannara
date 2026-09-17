"""
Test script for Moderation Service

Tests the moderation API endpoints to ensure they work correctly
before JamiiLink integration.
"""

import requests
import json

# Configuration
BASE_URL = "http://localhost:8000"
MODERATION_ENDPOINT = f"{BASE_URL}/api/v1/moderate"


def test_health_check():
    """Test health check endpoint"""
    print("\n🔍 Testing Health Check...")
    
    response = requests.get(f"{MODERATION_ENDPOINT}/health")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Status: {data['status']}")
        print(f"   Service: {data['service']}")
        print(f"   Version: {data['version']}")
        return True
    else:
        print(f"❌ Failed with status {response.status_code}")
        return False


def test_safe_content():
    """Test moderation of safe content"""
    print("\n🔍 Testing Safe Content...")
    
    payload = {
        "content": "Hello community! I'm organizing a local cleanup event this Saturday at Central Park. Everyone is welcome to join us in making our neighborhood cleaner and greener!"
    }
    
    response = requests.post(MODERATION_ENDPOINT, json=payload)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Safe: {data['safe']}")
        print(f"   Toxicity: {data['toxicity_score']:.3f}")
        print(f"   Spam: {data['spam_probability']:.3f}")
        print(f"   Scam: {data['scam_probability']:.3f}")
        print(f"   Explanation: {data['explanation']}")
        
        if data['safe']:
            print("   ✅ Correctly identified as safe")
            return True
        else:
            print("   ⚠️  False positive detected")
            return False
    else:
        print(f"❌ Failed with status {response.status_code}")
        print(f"   Error: {response.text}")
        return False


def test_toxic_content():
    """Test moderation of toxic content"""
    print("\n🔍 Testing Toxic Content...")
    
    payload = {
        "content": "You stupid idiot! This is trash and you should die. All people like you are racist scum."
    }
    
    response = requests.post(MODERATION_ENDPOINT, json=payload)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Safe: {data['safe']}")
        print(f"   Toxicity: {data['toxicity_score']:.3f}")
        print(f"   Categories: {data['categories_flagged']}")
        print(f"   Explanation: {data['explanation']}")
        
        if not data['safe'] and 'toxicity' in data['categories_flagged']:
            print("   ✅ Correctly flagged as toxic")
            return True
        else:
            print("   ❌ Failed to detect toxicity")
            return False
    else:
        print(f"❌ Failed with status {response.status_code}")
        return False


def test_spam_content():
    """Test moderation of spam content"""
    print("\n🔍 Testing Spam Content...")
    
    payload = {
        "content": "CLICK HERE NOW!!! BUY NOW and earn FREE MONEY fast! Limited time offer! Act now! http://spam1.com http://spam2.com http://spam3.com MAKE QUICK CASH!!!"
    }
    
    response = requests.post(MODERATION_ENDPOINT, json=payload)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Safe: {data['safe']}")
        print(f"   Spam: {data['spam_probability']:.3f}")
        print(f"   Categories: {data['categories_flagged']}")
        print(f"   Explanation: {data['explanation']}")
        
        if not data['safe'] and 'spam' in data['categories_flagged']:
            print("   ✅ Correctly flagged as spam")
            return True
        else:
            print("   ❌ Failed to detect spam")
            return False
    else:
        print(f"❌ Failed with status {response.status_code}")
        return False


def test_scam_content():
    """Test moderation of scam content"""
    print("\n🔍 Testing Scam Content...")
    
    payload = {
        "content": "URGENT! You have won the lottery! Send your bank details and password immediately to claim your inheritance from the prince. Wire transfer required ASAP!"
    }
    
    response = requests.post(MODERATION_ENDPOINT, json=payload)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Safe: {data['safe']}")
        print(f"   Scam: {data['scam_probability']:.3f}")
        print(f"   Categories: {data['categories_flagged']}")
        print(f"   Explanation: {data['explanation']}")
        
        if not data['safe'] and 'scam' in data['categories_flagged']:
            print("   ✅ Correctly flagged as scam")
            return True
        else:
            print("   ❌ Failed to detect scam")
            return False
    else:
        print(f"❌ Failed with status {response.status_code}")
        return False


def test_batch_moderation():
    """Test batch moderation endpoint"""
    print("\n🔍 Testing Batch Moderation...")
    
    payload = {
        "contents": [
            "This is a normal post about community events",
            "You are stupid and should die",
            "Buy now! Free money! Click here!",
            "Send money to claim your prize"
        ]
    }
    
    response = requests.post(f"{MODERATION_ENDPOINT}/batch", json=payload)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Total analyzed: {data['total_analyzed']}")
        print(f"   Flagged count: {data['flagged_count']}")
        
        for i, result in enumerate(data['results']):
            status = "🚩 FLAGGED" if not result['safe'] else "✅ SAFE"
            print(f"   Item {i+1}: {status} - {result['explanation']}")
        
        if data['flagged_count'] == 3:  # Items 2, 3, 4 should be flagged
            print("   ✅ Correctly identified flagged items")
            return True
        else:
            print(f"   ⚠️  Expected 3 flagged, got {data['flagged_count']}")
            return False
    else:
        print(f"❌ Failed with status {response.status_code}")
        return False


def test_empty_content():
    """Test handling of empty content"""
    print("\n🔍 Testing Empty Content...")
    
    payload = {
        "content": ""
    }
    
    response = requests.post(MODERATION_ENDPOINT, json=payload)
    
    if response.status_code == 422:  # Validation error
        print("   ✅ Correctly rejected empty content")
        return True
    elif response.status_code == 200:
        data = response.json()
        if data['safe']:
            print("   ✅ Handled empty content gracefully")
            return True
        else:
            print("   ❌ Incorrectly flagged empty content")
            return False
    else:
        print(f"❌ Unexpected status {response.status_code}")
        return False


def main():
    """Run all tests"""
    print("=" * 60)
    print("🧪 MODERATION SERVICE TEST SUITE")
    print("=" * 60)
    
    # Check if server is running
    try:
        response = requests.get(f"{BASE_URL}/api/v1/health")
        if response.status_code != 200:
            print("\n❌ Tiannara API server is not running!")
            print("   Start it with: uvicorn tiannara_api.main:app --reload")
            return
    except requests.exceptions.ConnectionError:
        print("\n❌ Cannot connect to Tiannara API server!")
        print("   Make sure it's running on http://localhost:8000")
        return
    
    print("\n✅ Server is running\n")
    
    # Run tests
    results = []
    
    results.append(("Health Check", test_health_check()))
    results.append(("Safe Content", test_safe_content()))
    results.append(("Toxic Content", test_toxic_content()))
    results.append(("Spam Content", test_spam_content()))
    results.append(("Scam Content", test_scam_content()))
    results.append(("Batch Moderation", test_batch_moderation()))
    results.append(("Empty Content", test_empty_content()))
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 TEST SUMMARY")
    print("=" * 60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {name}")
    
    print("\n" + "-" * 60)
    print(f"Total: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed! Moderation service is ready for JamiiLink integration.")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed. Review the output above.")
    
    print("=" * 60)


if __name__ == "__main__":
    main()
