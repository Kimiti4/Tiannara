from __future__ import annotations
from dataclasses import dataclass
from typing import List, Dict
import re

from tiannara_core.memory.knowledge_store import KnowledgeStore


@dataclass
class Ingestor:
    store: KnowledgeStore

    def chunk_text(self, text: str, max_chars: int = 800) -> List[str]:
        """
        Very simple chunker:
        - split by blank lines
        - then further split if too long
        """
        text = (text or "").strip()
        if not text:
            return []

        blocks = re.split(r"\n\s*\n+", text)
        chunks: List[str] = []

        for b in blocks:
            b = b.strip()
            if not b:
                continue
            if len(b) <= max_chars:
                chunks.append(b)
            else:
                # split long blocks by sentences
                parts = re.split(r"(?<=[.!?])\s+", b)
                buf = ""
                for p in parts:
                    if len(buf) + len(p) + 1 <= max_chars:
                        buf = (buf + " " + p).strip()
                    else:
                        if buf:
                            chunks.append(buf)
                        buf = p.strip()
                if buf:
                    chunks.append(buf)

        return chunks

    def ingest_text(self, source: str, text: str) -> List[Dict]:
        chunks = self.chunk_text(text)
        out = []
        for c in chunks:
            item = self.store.add(source=source, kind="chunk", payload={"text": c})
            out.append({"id": item.id, "text": c})
        return out