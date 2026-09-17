"""Centralized password hashing with bcrypt and legacy SHA-256 support."""

from __future__ import annotations

import hashlib
import secrets
import bcrypt

_LEGACY_PREFIX = "sha256:"


def hash_password(password: str) -> str:
    """Hash password with bcrypt."""
    password_bytes = password.encode("utf-8")[:72]
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password_bytes, salt).decode("utf-8")


def verify_password(password: str, stored_hash: str) -> bool:
    """Verify password; supports bcrypt and legacy salt:hex SHA-256 hashes."""
    if not stored_hash:
        return False
    if stored_hash.startswith(_LEGACY_PREFIX):
        return _verify_legacy_sha256(password, stored_hash[len(_LEGACY_PREFIX) :])
    if ":" in stored_hash and not stored_hash.startswith("$"):
        return _verify_legacy_sha256(password, stored_hash)
    
    try:
        password_bytes = password.encode("utf-8")[:72]
        return bcrypt.checkpw(password_bytes, stored_hash.encode("utf-8"))
    except Exception:
        return False


def needs_rehash(stored_hash: str) -> bool:
    """True if hash should be upgraded to bcrypt on next successful login."""
    if not stored_hash:
        return False
    if stored_hash.startswith(_LEGACY_PREFIX) or (
        ":" in stored_hash and not stored_hash.startswith("$")
    ):
        return True
    if not (stored_hash.startswith("$2a$") or stored_hash.startswith("$2b$") or stored_hash.startswith("$2y$")):
        return True
    return False


def _verify_legacy_sha256(password: str, stored_hash: str) -> bool:
    try:
        salt, hash_value = stored_hash.split(":", 1)
        computed = hashlib.sha256(f"{salt}{password}".encode()).hexdigest()
        return secrets.compare_digest(computed, hash_value)
    except (ValueError, AttributeError):
        return False

