"""
Example: Using Tier-Based Access Control in Tiannara API Routes.

This file demonstrates how to protect routes based on user subscription tier.
"""

from fastapi import APIRouter, Request
from tiannara_api.middleware.tier_access_control import (
    require_tier,
    require_active_subscription,
    check_feature_access,
    require_professional,
    require_enterprise
)

router = APIRouter(
    prefix="/examples",
    tags=["tier-examples"]
)


# ============================================================================
# Example 1: Basic Tier Requirement
# ============================================================================

@router.get("/basic-analytics")
@require_tier("starter")
async def get_basic_analytics(request: Request):
    """
    Basic analytics - available to Starter tier and above.
    
    This route is protected so only users with Starter, Professional, 
    or Enterprise tier can access it.
    """
    user = request.state.user  # User object injected by decorator
    
    return {
        "message": "Basic analytics data",
        "user_tier": user.tier,
        "data": {
            "total_requests": user.monthly_request_count,
            "insights_count": 5
        }
    }


# ============================================================================
# Example 2: Professional Tier Only
# ============================================================================

@router.get("/advanced-workflows")
@require_professional
async def get_advanced_workflows(request: Request):
    """
    Advanced workflow orchestration - Professional tier only.
    
    Uses the convenience decorator @require_professional which is 
    equivalent to @require_tier("professional").
    """
    user = request.state.user
    
    return {
        "message": "Advanced workflow features",
        "user_tier": user.tier,
        "features": [
            "Real-time orchestration",
            "Priority processing",
            "Team collaboration",
            "Webhooks & integrations"
        ]
    }


# ============================================================================
# Example 3: Enterprise Tier Only
# ============================================================================

@router.get("/compliance-reports")
@require_enterprise
async def get_compliance_reports(request: Request):
    """
    Compliance and audit reports - Enterprise tier only.
    
    Highly restricted feature only available to Enterprise customers.
    """
    user = request.state.user
    
    return {
        "message": "Enterprise compliance reports",
        "user_tier": user.tier,
        "reports": [
            "SOC 2 Type II",
            "GDPR Compliance",
            "HIPAA Audit Trail",
            "Data Processing Records"
        ]
    }


# ============================================================================
# Example 4: Feature-Based Access Control
# ============================================================================

@router.get("/team-management")
@check_feature_access("team_collaboration")
async def get_team_management(request: Request):
    """
    Team management features - requires team_collaboration feature access.
    
    Based on FEATURE_ACCESS mapping:
    - Professional: ✅ Has access
    - Enterprise: ✅ Has access
    - Starter: ❌ No access
    - Free: ❌ No access
    """
    user = request.state.user
    
    return {
        "message": "Team collaboration features",
        "user_tier": user.tier,
        "team_size_limit": 10 if user.tier == "professional" else "unlimited"
    }


# ============================================================================
# Example 5: Active Subscription Required
# ============================================================================

@router.get("/priority-support")
@require_active_subscription()
async def get_priority_support(request: Request):
    """
    Priority support channel - requires any active subscription.
    
    Available to all paid tiers (Starter, Professional, Enterprise)
    but NOT free tier or cancelled subscriptions.
    """
    user = request.state.user
    
    response_time = {
        "starter": "48 hours",
        "professional": "24 hours",
        "enterprise": "24/7 dedicated"
    }
    
    return {
        "message": "Priority support access",
        "user_tier": user.tier,
        "subscription_status": user.subscription_status,
        "response_time": response_time.get(user.tier, "N/A")
    }


# ============================================================================
# Example 6: Multiple Tier Checks in One Route
# ============================================================================

@router.get("/workflow-templates")
async def get_workflow_templates(request: Request):
    """
    Workflow templates - different templates for different tiers.
    
    Instead of blocking access, this route returns different content
    based on user's tier level.
    """
    from tiannara_api.database import SessionLocal
    from tiannara_api.database.models import User
    
    user_id = getattr(request.state, 'user_id', None)
    
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_id).first()
        
        # All users get basic templates
        templates = [
            {"name": "Data Classification", "tier": "free"},
            {"name": "Sentiment Analysis", "tier": "free"}
        ]
        
        # Starter and above get additional templates
        if user.tier in ["starter", "professional", "enterprise"]:
            templates.extend([
                {"name": "Customer Segmentation", "tier": "starter"},
                {"name": "Research Automation", "tier": "starter"}
            ])
        
        # Professional and above get advanced templates
        if user.tier in ["professional", "enterprise"]:
            templates.extend([
                {"name": "Fraud Detection Pipeline", "tier": "professional"},
                {"name": "Predictive Analytics System", "tier": "professional"}
            ])
        
        # Enterprise gets exclusive templates
        if user.tier == "enterprise":
            templates.extend([
                {"name": "Compliance Automation", "tier": "enterprise"},
                {"name": "Enterprise Risk Analysis", "tier": "enterprise"}
            ])
        
        return {
            "templates": templates,
            "user_tier": user.tier,
            "total_available": len(templates)
        }
    finally:
        db.close()


# ============================================================================
# Example 7: Graceful Degradation (Show Upgrade Prompt)
# ============================================================================

@router.get("/premium-dashboard")
async def get_premium_dashboard(request: Request):
    """
    Premium dashboard - shows limited view for lower tiers with upgrade prompt.
    
    Instead of blocking access completely, this provides a taste of premium
    features and encourages upgrade.
    """
    from tiannara_api.database import SessionLocal
    from tiannara_api.database.models import User
    
    user_id = getattr(request.state, 'user_id', None)
    
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_id).first()
        
        # Base metrics available to all
        dashboard_data = {
            "basic_metrics": {
                "total_requests": user.monthly_request_count,
                "success_rate": "95%"
            }
        }
        
        # Add premium metrics if user has access
        if user.tier in ["professional", "enterprise"]:
            dashboard_data["premium_metrics"] = {
                "real_time_analytics": True,
                "custom_dashboards": True,
                "export_data": True
            }
        else:
            # Show upgrade prompt for non-professional users
            dashboard_data["upgrade_prompt"] = {
                "message": "Upgrade to Professional for real-time analytics",
                "features_locked": [
                    "Real-time dashboards",
                    "Custom visualizations",
                    "Data export"
                ],
                "upgrade_url": "/billing?plan=professional"
            }
        
        return dashboard_data
    finally:
        db.close()


# ============================================================================
# Usage Guide
# ============================================================================

"""
QUICK REFERENCE: Which Decorator to Use?

1. Simple tier requirement:
   @require_tier("professional")
   → Blocks access if user tier < professional

2. Convenience decorators:
   @require_starter / @require_professional / @require_enterprise
   → Same as above but cleaner syntax

3. Feature-based access:
   @check_feature_access("team_collaboration")
   → Checks FEATURE_ACCESS mapping for allowed tiers

4. Any paid subscription:
   @require_active_subscription()
   → Blocks free tier and cancelled/past_due subscriptions

5. Custom logic:
   Don't use decorator, manually check request.state.user.tier
   → For complex scenarios like Example 6 & 7

BEST PRACTICES:

✅ DO:
- Use decorators for simple access control
- Return helpful error messages with upgrade links
- Log access denied attempts for monitoring
- Test with different tier levels

❌ DON'T:
- Hardcode tier checks in route logic (use decorators)
- Expose sensitive data before checking tier
- Forget to handle missing user_id gracefully
- Block all access when graceful degradation is better

ERROR MESSAGE EXAMPLES:

Good:
"This feature requires Professional tier. Your current tier: Starter. 
Upgrade at /billing"

Bad:
"Access denied" or "403 Forbidden"
"""
