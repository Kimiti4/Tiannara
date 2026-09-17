import requests
import time

BASE_URL = "http://localhost:8004"

endpoints_to_test = [
    ("/health", "GET", None),
    ("/api/v1/discovery/memory", "GET", None),
    ("/api/v1/observatory/calibration/worlds", "GET", None),
    ("/api/v1/observatory/calibration/reports", "GET", None),
    ("/api/v1/chat", "POST", {"message": "Hello, how do I fix my wifi?", "conversation_id": "test_1"}),
    ("/api/v1/chat", "POST", {"message": "Design a post-scarcity economy based on thermal gradients", "conversation_id": "test_2"}),
    ("/api/v1/gateway/health", "GET", None),
    ("/api/v1/gateway/metrics", "GET", None),
    ("/api/v1/admin/metrics", "GET", None),
    ("/api/v1/auth/me", "GET", None)
]

def scan_endpoints():
    print(f"Starting System Integration Scan against {BASE_URL}...")
    errors = 0
    passed = 0
    
    for endpoint, method, payload in endpoints_to_test:
        url = f"{BASE_URL}{endpoint}"
        print(f"Testing {method} {url} ...", end=" ")
        
        try:
            if method == "GET":
                response = requests.get(url, timeout=5)
            else:
                response = requests.post(url, json=payload, timeout=5)
                
            status = response.status_code
            if status >= 500:
                print(f"FAILED (Status {status})")
                print(f"Response: {response.text}")
                errors += 1
            else:
                print(f"OK (Status {status})")
                passed += 1
                if endpoint == "/api/v1/chat":
                    data = response.json()
                    print(f"  -> Chat response: {data.get('response', '')[:100]}...")
                    print(f"  -> Cognitive layer: {data.get('metadata', {}).get('cognitive_layer', 'Unknown')}")
                    
        except requests.exceptions.RequestException as e:
            print(f"FAILED (Connection Error: {e})")
            errors += 1
            
        time.sleep(0.2)
        
    print("\n--- Scan Complete ---")
    print(f"Total Routes Tested: {len(endpoints_to_test)}")
    print(f"Passed: {passed}")
    print(f"Failed (500s or Connection Errors): {errors}")
    
if __name__ == "__main__":
    scan_endpoints()
