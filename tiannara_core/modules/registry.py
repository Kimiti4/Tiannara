from __future__ import annotations
from dataclasses import dataclass, field
from typing import Dict, Any, Optional

from tiannara_core.modules.base import ModuleBase


@dataclass
class ModuleRegistry:
    modules: Dict[str, ModuleBase] = field(default_factory=dict)
    enabled: Dict[str, bool] = field(default_factory=dict)

    def register(self, module: ModuleBase) -> None:
        name = module.manifest.name
        self.modules[name] = module
        self.enabled.setdefault(name, True)

    def set_enabled(self, name: str, enabled: bool) -> None:
        if name not in self.modules:
            raise KeyError(f"Unknown module: {name}")
        self.enabled[name] = bool(enabled)

    def list(self) -> Dict[str, Any]:
        out = {}
        for name, m in self.modules.items():
            out[name] = {
                "enabled": bool(self.enabled.get(name, False)),
                "manifest": {
                    "name": m.manifest.name,
                    "version": m.manifest.version,
                    "risk_tier": m.manifest.risk_tier,
                    "permissions": list(m.manifest.permissions),
                    "description": m.manifest.description,
                }
            }
        return out

    def get(self, name: str) -> Optional[ModuleBase]:
        if name not in self.modules:
            return None
        if not self.enabled.get(name, False):
            return None
        return self.modules[name]