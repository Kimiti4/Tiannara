from __future__ import annotations
from typing import Dict, Any, Optional
from tiannara_core.discovery.ingest import Ingestor
from tiannara_core.discovery.extract import Extractor
from tiannara_core.discovery.hypothesize import Hypothesizer
from tiannara_core.discovery.experiment import ExperimentDesigner
from tiannara_core.discovery.report import DiscoveryReporter
from tiannara_core.memory.knowledge_store import KnowledgeStore
from tiannara_core.safety.gate import SafetyGate


class DiscoveryEngine:
    def __init__(self, store: KnowledgeStore, gate: SafetyGate):
        self.store = store
        self.gate = gate
        self.ingestor = Ingestor(store=store)
        self.extractor = Extractor(store=store)
        self.hypoth = Hypothesizer(store=store)
        self.exp = ExperimentDesigner(store=store)
        self.reporter = DiscoveryReporter(store=store, gate=gate)

    def analyze(self, question: str, text: Optional[str] = None, source: str = "user_input") -> Dict[str, Any]:
        self.store.clear()

        if text:
            self.ingestor.ingest_text(source=source, text=text)
            self.extractor.extract_from_chunks(source=source)

        self.hypoth.generate(question=question)
        self.exp.design(question=question)

        report = self.reporter.build_report(question=question)
        return report