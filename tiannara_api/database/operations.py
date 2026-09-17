"""
Database Operations for User Management

Provides database-backed user operations to replace in-memory user_store.
"""
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional, Dict, List

from tiannara_api.database.models import User
from tiannara_api.security.password import hash_password, verify_password

__all__ = ["hash_password", "verify_password", "create_user"]


def create_user(
    db: Session,
    email: str,
    password: str,
    name: str,
    tier: str = "starter",
    is_admin: bool = False,
    is_verified: bool = False
) -> User:
    """Create a new user in the database."""
    password_hash = hash_password(password)
    
    user = User(
        email=email,
        name=name,
        password_hash=password_hash,
        tier=tier,
        is_admin=is_admin,
        is_verified=is_verified,
        is_active=True,
        created_at=datetime.utcnow(),
        total_requests=0,
        api_keys=[]
    )
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return user


def get_user_by_email(db: Session, email: str) -> Optional[User]:
    """Get user by email address."""
    return db.query(User).filter(User.email == email).first()


def get_user_by_id(db: Session, user_id: str) -> Optional[User]:
    """Get user by ID."""
    return db.query(User).filter(User.id == user_id).first()


def get_all_users(
    db: Session,
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = None,
    tier: Optional[str] = None
) -> tuple[List[User], int]:
    """
    Get all users with pagination and filtering.
    
    Returns:
        Tuple of (users_list, total_count)
    """
    query = db.query(User)
    
    # Apply search filter
    if search:
        search_lower = f"%{search.lower()}%"
        query = query.filter(
            (User.email.ilike(search_lower)) |
            (User.name.ilike(search_lower))
        )
    
    # Apply tier filter
    if tier:
        query = query.filter(User.tier == tier)
    
    # Get total count before pagination
    total = query.count()
    
    # Apply pagination
    users = query.order_by(User.created_at.desc()).offset(skip).limit(limit).all()
    
    return users, total


def update_user(
    db: Session,
    user_id: str,
    updates: Dict
) -> Optional[User]:
    """Update user fields."""
    user = get_user_by_id(db, user_id)
    if not user:
        return None
    
    # Update allowed fields
    for key, value in updates.items():
        if hasattr(user, key) and key not in ['id', 'password_hash', 'email']:
            setattr(user, key, value)
    
    user.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(user)
    
    return user


def delete_user(db: Session, user_id: str) -> bool:
    """Delete a user from the database."""
    user = get_user_by_id(db, user_id)
    if not user:
        return False
    
    db.delete(user)
    db.commit()
    return True


def count_users(db: Session) -> int:
    """Get total number of users."""
    return db.query(User).count()


def count_admins(db: Session) -> int:
    """Get number of admin users."""
    return db.query(User).filter(User.is_admin == True).count()
