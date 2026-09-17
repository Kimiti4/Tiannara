"""
Intent Recognition System - DEPRECATED

⚠️  DEPRECATION NOTICE ⚠️
This module has been superseded by tiannara_core.nlp.intent_system.IntentRecognizer
Please migrate to the new unified intent system.

This file is kept for backward compatibility only and will be removed in v2.0.

Original Purpose: Understand user intent from natural language input
Migration Path: Replace imports with:
    from tiannara_core.nlp.intent_system import IntentRecognizer

Date: May 8, 2026 (Original) / April 30, 2026 (Deprecated)
Status: ⚠️  DEPRECATED - Use nlp/intent_system.py instead
"""

import warnings
from typing import Dict, List, Any, Optional, Tuple
from enum import Enum
from dataclasses import dataclass, field

# Import from new unified system
from tiannara_core.nlp.intent_system import (
    IntentRecognizer as UnifiedIntentRecognizer,
    IntentCategory,
    IntentResult,
    ExtractedEntity
)

# Show deprecation warning on import
warnings.warn(
    "tiannara_core.usability.intent_recognition is deprecated. "
    "Use tiannara_core.nlp.intent_system.IntentRecognizer instead.",
    DeprecationWarning,
    stacklevel=2
)

# Backward compatibility - re-export from unified system
IntentCategory = IntentCategory
IntentResult = IntentResult
ExtractedEntity = ExtractedEntity


class IntentRecognizer(UnifiedIntentRecognizer):
    """
    Deprecated: Use tiannara_core.nlp.intent_system.IntentRecognizer instead.
    
    This class is maintained for backward compatibility only.
    It inherits from the unified IntentRecognizer to ensure existing code works.
    """
    
    def __init__(self):
        super().__init__()
        warnings.warn(
            "IntentRecognizer from usability.intent_recognition is deprecated. "
            "Import from tiannara_core.nlp.intent_system instead.",
            DeprecationWarning,
            stacklevel=2
        )


# Export for backward compatibility
__all__ = ['IntentRecognizer', 'IntentCategory', 'IntentResult', 'ExtractedEntity']
