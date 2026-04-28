from dataclasses import dataclass, field
from typing import Dict, List


@dataclass
class ModuleNode:
    name: str
    active: bool = True
    weight: float = 1.0


@dataclass
class ModuleGraph:
    nodes: Dict[str, ModuleNode] = field(default_factory=dict)
    edges: Dict[str, List[str]] = field(default_factory=dict)

    def add_module(self, name):
        self.nodes[name] = ModuleNode(name=name)
        self.edges[name] = []

    def connect(self, a, b):
        if a in self.edges:
            self.edges[a].append(b)

    def deactivate(self, name):
        if name in self.nodes:
            self.nodes[name].active = False

    def activate(self, name):
        if name in self.nodes:
            self.nodes[name].active = True

    def get_active_path(self):
        return [n for n in self.nodes if self.nodes[n].active]