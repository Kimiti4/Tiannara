# Tiannara Final Product Closure

## Product boundary

Tiannara is considered operationally usable when these paths work against real runtime state:

1. **Communicate** — `/dashboard/cognitive-workspace` → `/api/v1/chat`
2. **Research** — `/dashboard/research` → `/api/v1/chat/research`
3. **Observe** — Observatory Mission Control → live runtime/world/evidence endpoints
4. **Investigate worlds** — `/api/v1/worlds` → `TiannaraRuntime.WorldRegistry`
5. **Audit** — `python scripts/final_product_audit.py`

## Model modes

### Model-assisted
Set `OPENAI_API_KEY` and optionally `TIANNARA_CHAT_MODEL`. Conversation uses the configured model, while Tiannara supplies the epistemic/provenance boundary.

### Local bounded mode
Without a model key, conversation falls back to Tiannara's local DiscoveryEngine. It generates hypotheses and experiment plans but does not pretend that a language model answered the question.

## Research mode
The Research Lab uses Tiannara's WebDataFetcher and DuckDuckGo search integration. Each returned source retains title, URL, snippet/extracted text, fetch status and timestamp. External material is evidence input, not automatically verified truth.

## Runtime truth boundary
The multi-world API now reads `TiannaraRuntime.WorldRegistry`. The former hard-coded Observatory world response has been removed from the live `worlds` endpoint.

## Required local verification
From repository root:

```bash
python scripts/final_product_audit.py
```

Then run:

```bash
pytest -q
mix compile --warnings-as-errors
mix test
```

```bash
cd tiannara_saas
npm ci
npx tsc --noEmit
npm run build
```

```bash
cd tiannara_observatory/apps/observatory_ui
npm ci
npx tsc --noEmit
npm run build
```

## Known limitations

- This environment cannot execute the repository's Elixir/Node/PostgreSQL stack directly.
- GitHub-connected file operations can modify and inspect the repository, but they do not provide a local OS/container checkout.
- External web research depends on outbound HTTP access from the Tiannara runtime and may be rate-limited or blocked by source sites.
- Without a configured LLM provider, conversation is intentionally bounded rather than simulated.
- Existing historical/legacy subsystems still require continued truth-surface review; the release audit explicitly scans for known theatrical/mock indicators.

## Release gate
Do not label the product fully production-certified until the local audit is green and the CI matrix has passed on the exact release commit.