"""
Enterprise Module - Enterprise-grade features and compliance

Provides SSO, RBAC, audit logging, data encryption,
and compliance tools for enterprise deployments.
"""

from .auth_manager import AuthenticationManager, AuthConfig
from .rbac_engine import RBACEngine, Role, Permission
from .audit_logger import AuditLogger, AuditEvent
from .compliance_checker import ComplianceChecker, ComplianceReport

__all__ = [
    'AuthenticationManager',
    'AuthConfig',
    'RBACEngine',
    'Role',
    'Permission',
    'AuditLogger',
    'AuditEvent',
    'ComplianceChecker',
    'ComplianceReport'
]

__version__ = "1.0.0"
