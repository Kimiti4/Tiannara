from __future__ import annotations
from fastapi import FastAPI

from tiannara_core.mission.constitution import TiannaraConstitution
from tiannara_core.mission.alignment import AlignmentScorer
from tiannara_core.safety.policy import SafetyPolicy
from tiannara_core.safety.gate import SafetyGate
from tiannara_core.memory.knowledge_store import KnowledgeStore
from tiannara_core.discovery.ingest import Ingestor
from tiannara_core.discovery.extract import Extractor
from tiannara_core.discovery.hypothesize import Hypothesizer
from tiannara_core.discovery.experiment import ExperimentDesigner
from tiannara_core.discovery.report import DiscoveryReporter
from tiannara_core.modules.registry import ModuleRegistry
from tiannara_core.modules.base import ModuleBase, ModuleManifest

from tiannara_api.routes.status import router as status_router
from tiannara_api.routes.modules import router as modules_router
from tiannara_api.routes.discovery import router as discovery_router


app = FastAPI(title="Tiannara API", version="1.0.0-week1")

# Global singletons (simple for now)
REGISTRY = ModuleRegistry()
DISCOVERY_ENGINE = {}


class DiscoveryModule(ModuleBase):
    def __init__(self, analyze_fn):
        super().__init__(ModuleManifest(
            name="discovery",
            version="1.0",
            risk_tier="low",
            permissions=["read_user_text"],
            description="Scientific discovery engine (claims, hypotheses, experiments).",
        ))
        self._analyze_fn = analyze_fn

    def run(self, payload):
        return self._analyze_fn(
            question=payload.get("question", ""),
            text=payload.get("text"),
            source=payload.get("source", "user_input"),
        )


def build_discovery_engine():
    constitution = TiannaraConstitution()
    policy = SafetyPolicy()
    scorer = AlignmentScorer()
    gate = SafetyGate(constitution=constitution, policy=policy, scorer=scorer, min_alignment=0.35)

    store = KnowledgeStore()
    ingestor = Ingestor(store=store)
    extractor = Extractor(store=store)
    hypoth = Hypothesizer(store=store)
    exp = ExperimentDesigner(store=store)
    reporter = DiscoveryReporter(store=store, gate=gate)

    def analyze(question: str, text: str | None, source: str):
        # clear store per request (keeps it simple + deterministic for now)
        store.clear()

        if text:
            ingestor.ingest_text(source=source, text=text)
            extractor.extract_from_chunks(source=source)

        hypoth.generate(question=question)
        exp.design(question=question)

        report = reporter.build_report(question=question)
        return report

    return {"analyze": analyze}


# Initialize
DISCOVERY_ENGINE = build_discovery_engine()
REGISTRY.register(DiscoveryModule(analyze_fn=DISCOVERY_ENGINE["analyze"]))

# Routes
app.include_router(status_router)
app.include_router(modules_router)
app.include_router(discovery_router)