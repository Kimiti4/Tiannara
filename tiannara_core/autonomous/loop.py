from __future__ import annotations

import time
from dataclasses import dataclass
from typing import Any, Dict, List

from tiannara_core.autonomous.orchestrator import Orchestrator


@dataclass
class AutonomousLoop:
    orchestrator: Orchestrator
    running: bool = False

    def step(self, question: str, text: str | None = None, **kwargs: Any) -> Dict[str, Any]:
        return self.orchestrator.run_cycle(question=question, text=text, **kwargs)

    def run(
        self,
        *,
        question: str,
        text: str | None = None,
        iterations: int = 1,
        sleep_seconds: float = 0.0,
        **kwargs: Any,
    ) -> List[Dict[str, Any]]:
        self.running = True
        results: List[Dict[str, Any]] = []

        for index in range(max(1, int(iterations))):
            if not self.running:
                break
            results.append(self.step(question=question, text=text, **kwargs))
            if sleep_seconds > 0 and index < iterations - 1 and self.running:
                time.sleep(sleep_seconds)

        self.running = False
        return results

    def stop(self) -> None:
        self.running = False
