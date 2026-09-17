"""
Payment routes for Tiannara MindCache API.

Handles subscription creation, consulting payments, and webhook processing.
"""

from fastapi import APIRouter, Request, HTTPException, Header
from tiannara_api.payment import payment_processor
import os

router = APIRouter(
    prefix="/payment",
    tags=["payment"]
)


@router.get("/plans")
def list_plans():
    """List all available pricing plans."""
    return payment_processor.list_all_plans()


@router.get("/providers")
def list_providers():
    """List available payment providers and current default."""
    from tiannara_api.payment import PAYMENT_PROVIDER
    
    return {
        "available_providers": ["lemon_squeezy", "stripe"],
        "default_provider": PAYMENT_PROVIDER,
        "provider_info": {
            "lemon_squeezy": {
                "name": "Lemon Squeezy",
                "description": "No business registration required, handles taxes/VAT",
                "fees": "5% + $0.50 per transaction",
                "best_for": "Unregistered businesses, global SaaS"
            },
            "stripe": {
                "name": "Stripe",
                "description": "Individual accounts allowed, lower fees",
                "fees": "2.9% + $0.30 per transaction",
                "best_for": "Developers familiar with Stripe"
            }
        }
    }


@router.get("/plans/{plan}")
def get_plan_details(plan: str):
    """Get details for a specific pricing plan."""
    return payment_processor.get_plan_details(plan)


@router.post("/subscribe")
def create_subscription(
    plan: str,
    success_url: str,
    cancel_url: str,
    customer_email: str = None,
    provider: str = None  # Optional: 'stripe' or 'lemon_squeezy'
):
    """
    Create a subscription checkout session.
    
    Args:
        plan: Pricing plan (starter, professional, enterprise)
        success_url: Redirect URL after successful payment
        cancel_url: Redirect URL if payment cancelled
        customer_email: Optional customer email
        provider: Optional payment provider ('stripe' or 'lemon_squeezy'). 
                  If not specified, uses PAYMENT_PROVIDER from .env
        
    Returns:
        Checkout session ID and URL with provider info
    """
    return payment_processor.create_checkout_session(
        plan=plan,
        success_url=success_url,
        cancel_url=cancel_url,
        customer_email=customer_email,
        provider=provider  # Pass provider preference
    )


@router.post("/consulting")
def create_consulting_payment(
    package: str,
    success_url: str,
    cancel_url: str,
    customer_email: str = None,
    custom_amount: int = None
):
    """
    Create a one-time payment for consulting services.
    
    Args:
        package: Consulting package name
        success_url: Redirect URL after successful payment
        cancel_url: Redirect URL if payment cancelled
        customer_email: Optional customer email
        custom_amount: Optional custom amount in cents
        
    Returns:
        Checkout session ID and URL
    """
    return payment_processor.create_consulting_payment(
        package=package,
        success_url=success_url,
        cancel_url=cancel_url,
        customer_email=customer_email,
        custom_amount=custom_amount
    )


@router.post("/webhook")
async def payment_webhook(
    request: Request,
    stripe_signature: str = Header(None, alias="stripe-signature"),
    x_paystack_signature: str = Header(None, alias="x-paystack-signature"),
    x_signature: str = Header(None, alias="x-signature")
):
    """
    Handle webhook events from payment providers.
    
    Auto-detects provider based on signature headers:
    - Stripe: stripe-signature header
    - Lemon Squeezy: x-signature header
    - Paystack: x-paystack-signature header
    
    This endpoint receives events when:
    - Subscription is created
    - Payment succeeds
    - Subscription is cancelled
    
    IMPORTANT: Configure this URL in your payment provider dashboard under Webhooks.
    """
    payload = await request.body()
    
    # Determine provider and get signature
    if stripe_signature:
        provider = "stripe"
        signature = stripe_signature
    elif x_signature:
        provider = "lemon_squeezy"
        signature = x_signature
    elif x_paystack_signature:
        provider = "paystack"
        signature = x_paystack_signature
    else:
        raise HTTPException(status_code=400, detail="Missing payment provider signature")
    
    try:
        result = payment_processor.handle_webhook(payload, signature, provider)
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/consulting-packages")
def list_consulting_packages():
    """List all available consulting packages."""
    from tiannara_api.payment import CONSULTING_PACKAGES
    
    return {
        "packages": {
            pkg: {
                k: v for k, v in details.items() 
                if k != "amount_cents"
            }
            for pkg, details in CONSULTING_PACKAGES.items()
        }
    }


@router.post("/admin/process-downgrades")
def process_subscription_downgrades():
    """
    Admin endpoint to manually trigger subscription downgrade processing.
    
    Checks for users with cancel_at_period_end=True whose billing period has ended
    and downgrades them to free tier.
    
    This should typically be run as a daily cron job, but can also be triggered
    manually for testing or immediate processing.
    
    Returns:
        Number of users downgraded and timestamp
    """
    # TODO: Add admin authentication check here
    # from tiannara_api.auth import verify_admin_user
    # verify_admin_user(current_user)
    
    return payment_processor.check_and_process_downgrades()
