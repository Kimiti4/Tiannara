from __future__ import annotations
from dataclasses import dataclass, field
from typing import Dict, Any, List, Optional


@dataclass
class ModuleManifest:
    name: str
    version: str
    risk_tier: str  # "low" | "medium" | "high"
    permissions: List[str] = field(default_factory=list)
    description: str = ""


class ModuleBase:
    """
    Base interface for Tiannara modules.
    Later: signatures, capability sandboxing, per-module safety contracts.
    """

    manifest: ModuleManifest

    def __init__(self, manifest: ModuleManifest):
        self.manifest = manifest

    def run(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        raise NotImplementedError