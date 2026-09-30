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
from tiannara_core.conversation.native_dialogue import NativeDialogueEngine

_NATIVE_DIALOGUE = NativeDialogueEngine()


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

    response, result = await _reply(
        req.message,
        history[:-1],
        req.context,
    )
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

@router.post("/initiate")
async def initiate(context: dict[str, Any] | None = None):
    """Ask native Tiannara what deserves attention now, grounded in current state."""
    response = _NATIVE_DIALOGUE.initiate(
        f"proactive_{secrets.token_urlsafe(8)}",
        context or {},
    )
    return response.as_dict()


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

    evidence = [
        {
            "source": s["url"],
            "title": s["title"],
            "snippet": s["snippet"],
            "quality": 0.5 if s.get("fetched") else 0.25,
        }
        for s in sources
    ]
    native = _NATIVE_DIALOGUE.respond(
        f"Research question: {req.query}",
        _NATIVE_DIALOGUE.state.get_conversation_history("research")[-10:],
        {
            "evidence": evidence,
            "known_facts": [],
            "unknowns": ["independent verification of fetched claims"],
            "source_text": source_text,
        },
    )
    analysis = native.as_dict()

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


async def _reply(message: str, history: list[dict[str, str]], context: dict[str, Any]):
    """Native conversation path; no generative-model dependency."""
    session_id = str(context.get("conversation_id", "default"))
    response = _NATIVE_DIALOGUE.respond(session_id, message, context)
    return response.text, response.as_dict()


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
