"""Canonical subscription tier names across API, gateway, and database."""

from __future__ import annotations

TIER_ALIASES = {
    "pro": "professional",
    "professional": "professional",
    "starter": "starter",
    "free": "free",
    "enterprise": "enterprise",
}

CANONICAL_TIERS = frozenset(TIER_ALIASES.values())


def normalize_tier(tier: str | None) -> str:
    """Map tier aliases (e.g. pro) to canonical names (professional)."""
    if not tier:
        return "starter"
    return TIER_ALIASES.get(tier.lower().strip(), tier.lower().strip())
