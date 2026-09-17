"""
Tiannara MindCache API - Main Application Entry Point

This is the production-ready version with payment processing enabled.
"""

from __future__ import annotations

import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from tiannara_api.routes.autonomous import router as autonomous_router
from tiannara_api.routes.discovery import router as discovery_router
from tiannara_api.routes.evolution import router as evolution_router
from tiannara_api.routes.memory import router as memory_router
from tiannara_api.routes.modules import router as modules_router
from tiannara_api.routes.status import router as status_router
from tiannara_api.routes.autonomy import router as autonomy_router
from tiannara_api.routes.explanations import router as explanations_router
from tiannara_api.routes.payment import router as payment_router  # NEW: Payment processing

from tiannara_core.autonomous.orchestrator import Orchestrator
from tiannara_core.discovery.engine import DiscoveryEngine
from tiannara_core.evolution.evolution import evolve as run_evolution
from tiannara_core.evolution.evolution_loop import EvolutionLoop
from tiannara_core.memory.discovery_memory import DiscoveryMemory
from tiannara_core.memory.experience_db import ExperienceDB
from tiannara_core.memory.knowledge_store import KnowledgeStore
from tiannara_core.mission.alignment import AlignmentScorer
from tiannara_core.mission.constitution import TiannaraConstitution
from tiannara_core.modules.base import ModuleBase, ModuleManifest
from tiannara_core.modules.registry import ModuleRegistry
from tiannara_core.safety.gate import SafetyGate
from tiannara_core.safety.policy import SafetyPolicy


APP_VERSION = "1.4.0-monetization"

app = FastAPI(title="Tiannara MindCache API", version=APP_VERSION)

_allowed_origins = os.getenv(
    "ALLOWED_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000"
).split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in _allowed_origins if o.strip()],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-API-Key"],
)


class CallableModule(ModuleBase):
    def __init__(self, *, name: str, version: str, risk_tier: str, permissions: list[str], description: str, run_fn):
        super().__init__(
            ModuleManifest(
                name=name,
                version=version,
                risk_tier=risk_tier,
                permissions=permissions,
                description=description,
            )
        )
        self._run_fn = run_fn

    def run(self, payload):
        return self._run_fn(payload)


def build_safety_gate() -> SafetyGate:
    return SafetyGate(
        constitution=TiannaraConstitution(),
        policy=SafetyPolicy(),
        scorer=AlignmentScorer(),
        min_alignment=0.35,
    )


REGISTRY = ModuleRegistry()
SAFETY_GATE = build_safety_gate()
DISCOVERY_ENGINE = DiscoveryEngine(store=KnowledgeStore(), gate=SAFETY_GATE)
DISCOVERY_MEMORY = DiscoveryMemory()
EXPERIENCE_DB = ExperienceDB()
EVOLUTION_LOOP = EvolutionLoop()
AUTONOMOUS_ORCHESTRATOR = Orchestrator(
    store=KnowledgeStore(),
    gate=SAFETY_GATE,
    memory=EXPERIENCE_DB,
    evolution=EVOLUTION_LOOP,
)

REGISTRY.register(
    CallableModule(
        name="discovery",
        version="1.0",
        risk_tier="low",
        permissions=["read_user_text"],
        description="Scientific discovery engine for claims, hypotheses, and experiment design.",
        run_fn=lambda payload: DISCOVERY_ENGINE.analyze(
            question=payload.get("question", ""),
            text=payload.get("text"),
            source=payload.get("source", "user_input"),
        ),
    )
)
REGISTRY.register(
    CallableModule(
        name="evolution",
        version="1.0",
        risk_tier="low",
        permissions=["simulate_parameter_search"],
        description="Evolution loop with adversarial simulation and graph or neural genomes.",
        run_fn=lambda payload: run_evolution(
            question=payload.get("question", "Optimize prosthetic grip stability"),
            population_size=payload.get("population_size", 24),
            generations=payload.get("generations", 12),
            fitness_function=payload.get("fitness_function", "grip_stability"),
            genome_type=payload.get("genome_type", "neural"),
        ),
    )
)
REGISTRY.register(
    CallableModule(
        name="autonomous",
        version="1.0",
        risk_tier="medium",
        permissions=["read_user_text", "simulate_parameter_search", "write_memory"],
        description="DEAA cycle with distributed evolution, adversarial environments, memory, and LLM-guided meta mutation.",
        run_fn=lambda payload: AUTONOMOUS_ORCHESTRATOR.run_cycle(
            question=payload.get("question", "Optimize prosthetic grip stability"),
            text=payload.get("text"),
            source=payload.get("source", "module_runner"),
            population_size=payload.get("population_size", 24),
            generations=payload.get("generations", 12),
            fitness_function=payload.get("fitness_function", "grip_stability"),
            workers=payload.get("workers", 4),
            genome_type=payload.get("genome_type", "mixed"),
        ),
    )
)

# Register all routers
app.include_router(status_router)
app.include_router(modules_router)
app.include_router(discovery_router)
app.include_router(evolution_router)
app.include_router(autonomous_router)
app.include_router(memory_router)
app.include_router(autonomy_router)
app.include_router(explanations_router, prefix="/api/v1")
app.include_router(payment_router, prefix="/api/v1")  # NEW: Payment routes


@app.get("/")
def root():
    """Root endpoint with API information."""
    return {
        "name": "Tiannara MindCache API",
        "version": APP_VERSION,
        "status": "operational",
        "features": [
            "Cross-domain reasoning (Algorithm, Logic, RE, Causal)",
            "Skill transfer (>97% success rate)",
            "Stagnation detection & adaptive strategies",
            "Payment processing (Stripe integration)",
            "EU AI Act compliance"
        ],
        "docs": "/docs",
        "pricing": "/api/v1/payment/plans"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
