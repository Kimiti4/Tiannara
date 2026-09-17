"""
Mobile Module - Mobile application support and optimization

Provides mobile-specific optimizations, offline capabilities,
push notifications, and responsive design patterns.
"""

from .mobile_optimizer import MobileOptimizer, MobileConfig
from .offline_manager import OfflineManager, CachedResponse
from .push_notifications import PushNotificationService, NotificationPayload
from .responsive_adapter import ResponsiveAdapter, DeviceProfile

__all__ = [
    'MobileOptimizer',
    'MobileConfig',
    'OfflineManager',
    'CachedResponse',
    'PushNotificationService',
    'NotificationPayload',
    'ResponsiveAdapter',
    'DeviceProfile'
]

__version__ = "1.0.0"
