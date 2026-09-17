"""
Test script for Tiannara payment integration.

Run this to verify Stripe integration is working correctly.
"""

import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def test_stripe_configuration():
    """Test that Stripe is configured correctly."""
    print("=" * 60)
    print("TIANNARA PAYMENT INTEGRATION TEST")
    print("=" * 60)
    
    # Check environment variables
    print("\n1. Checking environment variables...")
    
    required_vars = [
        "STRIPE_SECRET_KEY",
        "STRIPE_PUBLISHABLE_KEY",
        "STRIPE_WEBHOOK_SECRET",
        "STRIPE_STARTER_PRICE_ID",
        "STRIPE_PRO_PRICE_ID",
        "STRIPE_ENTERPRISE_PRICE_ID"
    ]
    
    missing = []
    for var in required_vars:
        value = os.getenv(var)
        if not value or value.startswith("sk_test_your") or value.startswith("pk_test_your"):
            missing.append(var)
            print(f"   ❌ {var}: Not configured (using placeholder)")
        else:
            print(f"   ✅ {var}: Configured")
    
    if missing:
        print(f"\n⚠️  WARNING: {len(missing)} environment variable(s) not configured:")
        for var in missing:
            print(f"   - {var}")
        print("\nTo fix:")
        print("   1. Copy .env.example to .env")
        print("   2. Fill in your actual Stripe keys")
        print("   3. Run this test again")
        return False
    
    print("\n✅ All environment variables configured!")
    return True


def test_stripe_connection():
    """Test connection to Stripe API."""
    print("\n2. Testing Stripe API connection...")
    
    try:
        import stripe
        stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
        
        # Try to list products (simple API call)
        products = stripe.Product.list(limit=1)
        print(f"   ✅ Successfully connected to Stripe API")
        print(f"   Found {products.data.__len__() if products.data else 0} products in your account")
        return True
        
    except Exception as e:
        print(f"   ❌ Failed to connect to Stripe API")
        print(f"   Error: {str(e)}")
        print("\nTroubleshooting:")
        print("   - Check your STRIPE_SECRET_KEY is correct")
        print("   - Make sure you're using sk_test_ for testing")
        print("   - Verify your internet connection")
        return False


def test_price_ids():
    """Verify price IDs exist in Stripe."""
    print("\n3. Verifying price IDs...")
    
    try:
        import stripe
        stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
        
        price_ids = {
            "Starter": os.getenv("STRIPE_STARTER_PRICE_ID"),
            "Professional": os.getenv("STRIPE_PRO_PRICE_ID"),
            "Enterprise": os.getenv("STRIPE_ENTERPRISE_PRICE_ID")
        }
        
        all_valid = True
        for plan, price_id in price_ids.items():
            try:
                price = stripe.Price.retrieve(price_id)
                print(f"   ✅ {plan}: {price_id} (valid)")
            except Exception as e:
                print(f"   ❌ {plan}: {price_id} (invalid)")
                print(f"      Error: {str(e)}")
                all_valid = False
        
        if all_valid:
            print("\n✅ All price IDs are valid!")
        else:
            print("\n⚠️  Some price IDs are invalid. Create them in Stripe Dashboard.")
        
        return all_valid
        
    except Exception as e:
        print(f"   ❌ Error checking price IDs: {str(e)}")
        return False


def test_payment_module():
    """Test the payment processor module."""
    print("\n4. Testing payment processor module...")
    
    try:
        from tiannara_api.payment import PaymentProcessor, PRICING_PLANS
        
        processor = PaymentProcessor()
        
        # Test listing plans
        plans = processor.list_all_plans()
        print(f"   ✅ Payment processor initialized")
        print(f"   Found {len(plans['plans'])} pricing plans:")
        
        for plan_name, plan_details in plans['plans'].items():
            if plan_details.get('amount_cents'):
                amount = plan_details['amount_cents'] / 100
                print(f"      - {plan_name}: ${amount}/month")
            else:
                print(f"      - {plan_name}: Free")
        
        return True
        
    except Exception as e:
        print(f"   ❌ Failed to initialize payment processor")
        print(f"   Error: {str(e)}")
        return False


def test_api_routes():
    """Test that API routes are registered."""
    print("\n5. Testing API route registration...")
    
    try:
        from tiannara_api.main_production import app
        
        routes = [route.path for route in app.routes]
        payment_routes = [r for r in routes if 'payment' in r]
        
        if payment_routes:
            print(f"   ✅ Found {len(payment_routes)} payment routes:")
            for route in payment_routes:
                print(f"      - {route}")
            return True
        else:
            print(f"   ❌ No payment routes found!")
            return False
            
    except Exception as e:
        print(f"   ❌ Error checking routes: {str(e)}")
        return False


def run_local_server_test():
    """Offer to start local server for manual testing."""
    print("\n6. Local server test...")
    print("\nWould you like to start the API server locally? (y/n)")
    
    choice = input("> ").strip().lower()
    
    if choice == 'y':
        print("\nStarting local server on http://localhost:8000...")
        print("Press Ctrl+C to stop\n")
        
        import uvicorn
        from tiannara_api.main_production import app
        
        uvicorn.run(app, host="0.0.0.0", port=8000)
    else:
        print("\nSkipping local server test.")
        print("\nTo test manually later:")
        print("   uvicorn tiannara_api.main_production:app --reload --port 8000")
        print("   Then visit: http://localhost:8000/docs")


def main():
    """Run all tests."""
    print("\n🧪 Running Tiannara Payment Integration Tests...\n")
    
    results = []
    
    # Run tests
    results.append(("Environment Variables", test_stripe_configuration()))
    results.append(("Stripe Connection", test_stripe_connection()))
    results.append(("Price IDs", test_price_ids()))
    results.append(("Payment Module", test_payment_module()))
    results.append(("API Routes", test_api_routes()))
    
    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed! Your payment integration is ready.")
        print("\nNext steps:")
        print("   1. Deploy to cloud platform (see LAUNCH_CHECKLIST.md)")
        print("   2. Set up Stripe webhook endpoint")
        print("   3. Start client outreach campaign")
    else:
        print("\n⚠️  Some tests failed. Fix the issues above before deploying.")
    
    # Optional: Start local server
    if passed == total:
        run_local_server_test()


if __name__ == "__main__":
    main()
