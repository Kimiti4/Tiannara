"""Conversational and research gateway for the Tiannara Core.

The gateway deliberately separates:
- conversational processing through TiannaraCore;
- external evidence acquisition through WebDataFetcher;
- optional external LLM synthesis when explicitly configured.

No external result is represented as a Tiannara-generated fact without source
metadata. Research responses always preserve the URLs returned by the search
provider and the local analysis report.
"""

from __future__ import annotations

import os
import secrets
from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from tiannara_api.security.auth_deps import require_auth
from tiannara_core.core import create_tiannara
from tiannara_core.integration.web_fetcher import WebDataFetcher

router = APIRouter(prefix="/chat", tags=["Tiannara Conversation"], dependencies=[Depends(require_auth)])

_CORE = None
_CONVERSATIONS: dict[str, list[dict[str, str]]] = {}


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=12000)
    conversation_id: str | None = Field(default=None, max_length=128)
    context: dict[str, Any] = Field(default_factory=dict)


class ResearchRequest(BaseModel):
    query: str = Field(min_length=2, max_length=500)
    num_results: int = Field(default=6, ge=1, le=10)
    fetch_sources: bool = True


def _core():
    global _CORE
    if _CORE is None:
        _CORE = create_tiannara(
            enable_evolution=False,
            enable_ecm=True,
            enable_multi_agent=True,
            enable_plugins=True,
            enable_goals=True,
            enable_telemetry=True,
        )
    return _CORE


def _conversation_id(value: str | None) -> str:
    return value or f"conv_{secrets.token_urlsafe(12)}"


@router.post("")
async def chat(req: ChatRequest):
    conversation_id = _conversation_id(req.conversation_id)
    history = _CONVERSATIONS.setdefault(conversation_id, [])
    history.append({"role": "user", "content": req.message})
    history[:] = history[-20:]

    try:
        result = _core().process_intent(
            req.message,
            {
                **req.context,
                "conversation_id": conversation_id,
                "history": history[:-1],
            },
        )
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Tiannara core processing failed: {exc}") from exc

    response = _humanize_core_result(req.message, result)
    history.append({"role": "assistant", "content": response})
    history[:] = history[-20:]

    return {
        "conversation_id": conversation_id,
        "response": response,
        "result": result,
        "metadata": {
            "provider": "tiannara_core",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        },
    }


@router.post("/research")
async def research(req: ResearchRequest):
    async with WebDataFetcher(
        timeout=float(os.getenv("RESEARCH_HTTP_TIMEOUT", "20")),
        max_retries=2,
        rate_limit_rps=float(os.getenv("RESEARCH_RATE_LIMIT_RPS", "3")),
        cache_ttl=120,
        user_agent="Tiannara-Research/1.0",
    ) as fetcher:
        search = await fetcher.search_web(req.query, req.num_results)

        sources = []
        for item in search.results[: req.num_results]:
            entry = {
                "title": item.get("title", ""),
                "url": item.get("link", ""),
                "snippet": item.get("snippet", ""),
            }
            if req.fetch_sources and entry["url"]:
                fetched = await fetcher.fetch_url(entry["url"], use_cache=True)
                entry["fetched"] = bool(fetched.success)
                entry["text"] = (fetched.text_content or "")[:12000]
                entry["status_code"] = fetched.status_code
            sources.append(entry)

    source_text = "\n\n".join(
        f"SOURCE {i+1}: {s['title']}\n{s.get('text') or s.get('snippet','')}"
        for i, s in enumerate(sources)
    )

    try:
        analysis = _core().process_intent(
            f"Research question: {req.query}",
            {"research": True, "source_count": len(sources), "source_text": source_text},
        )
    except Exception as exc:
        analysis = {
            "success": False,
            "error": str(exc),
            "provenance": "research_acquisition_only",
        }

    return {
        "query": req.query,
        "searched_at": datetime.now(timezone.utc).isoformat(),
        "search_engine": search.search_engine,
        "sources": sources,
        "analysis": analysis,
        "epistemic_note": (
            "Search results are external evidence candidates, not verified facts. "
            "Tiannara must preserve source provenance and distinguish fetched evidence "
            "from its own analysis."
        ),
    }


def _humanize_core_result(message: str, result: dict[str, Any]) -> str:
    if result.get("success") and result.get("result"):
        return str(result["result"])

    if result.get("fallback_type"):
        return (
            f"I processed: {message!r}. Tiannara could not complete the requested "
            f"execution path, so it recorded a bounded fallback: "
            f"{result.get('fallback_type')}. I will not represent that as a completed result."
        )

    if result.get("error"):
        return f"Tiannara could not complete that request: {result['error']}"

    return (
        f"I received your request: {message!r}. Tiannara completed its available "
        "reasoning pipeline, but no directly executable result was produced."
    )
