# Capability 12.5.1 — Constitutional Episode Retrieval Report

**Date**: 2026-06-26  
**Status**: ✅ **VALIDATED & FROZEN**  
**Validation**: 7/7 scenarios passed against canonical ResearchEpisode objects  
**Architectural Discipline**: Episode Index as derived service (rebuildable from canonical history)

---

## Executive Summary

Capability 12.5.1 is now **constitutionally complete**. The Institution can retrieve semantically relevant episodes from authentic institutional history using the `retrieve_experience/3` API. All retrieval operates over immutable ResearchEpisode objects indexed by the EpisodeIndex service, which is explicitly defined as a **derived index** that may always be rebuilt from canonical Episodes.

This capability completes the Institutional Semantic Memory foundation (Phase 12.5), enabling all future Phase 12 capabilities to compose the same constitutional primitives without introducing new memory abstractions.

---

## Constitutional Mission Achieved

**Mission Statement**: Enable institutions to retrieve semantically relevant research episodes from genuine institutional history, not simulated or fabricated data.

**Achievement**: ✅ **VALIDATED**

The retrieval pipeline now searches canonical ResearchEpisode objects through the EpisodeIndex service:

```
Query
  ↓
Episode Index (derived from canonical Episodes)
  ↓
Semantic Ranking (keyword/topic matching)
  ↓
Episode References (lightweight metadata)
  ↓
Optional Replay (from civilizational_memory → Knowledge Graph in production)
```

**Key Architectural Property**: The Episode Index is **not** institutional memory, **not** a database, and **not** a second knowledge graph. It is a **derived index over immutable Research Episodes that exists solely to accelerate retrieval and may always be rebuilt from canonical Episodes**.

This ensures:
```
Delete Episode Index
  ↓
Replay Episodes
  ↓
Rebuild Index
  ↓
System identical
```

---

## Seven Constitutional Scenarios: 7/7 PASSED ✅

| Scenario | Test | Result | Key Finding |
|----------|------|--------|-------------|
| **1. Retrieve Similar Complete Investigation** | Query for "cancer treatment protocols" returns semantically similar episodes | ✅ PASS | Retrieved 3 episodes with real topics matching query keywords |
| **2. Retrieve Failed Investigation** | Query for challenging topics retrieves failed episodes | ✅ PASS | Failed investigations accessible from index |
| **3. Cross-Type Episode Retrieval** | Single query retrieves diverse episode types | ✅ PASS | Engineering episodes with structural analysis topics retrieved |
| **4. Empty Result (Novel Topic)** | Query for non-existent topic returns empty result | ✅ PASS | Novel topics correctly return status=:empty |
| **5. Low Confidence Retrieval** | Vague query returns low similarity scores with distribution | ✅ PASS | Similarity distribution tracked (mean, std_dev, max, min) |
| **6. Budget Exhaustion (Deferred)** | Insufficient budget causes deferral | ✅ PASS | Status=:deferred with failure_reason explaining budget constraint |
| **7. Twenty Institutions Simultaneous** | All 20 domains execute retrievals concurrently | ✅ PASS | Zero race conditions, independent histories preserved |

---

## Constitutional Primitives Frozen

Following this validation, five constitutional primitives are now permanently frozen:

### 1. ResearchEpisode
Immutable unit of institutional history. Every completed investigation produces exactly one Episode. Contains references to all canonical transactions (ResearchCycleResult, BeliefRevisionResult, PublicationResult, etc.).

### 2. ResearchCycleResult
Canonical transaction artifact for scientific investigation. Records hypothesis generation, experiment design, evidence collection, evaluation, belief revision, publication decision, governance decisions, lifecycle events, semantic events, knowledge delta, ledger delta, and memory delta.

### 3. BeliefRevisionResult
Canonical transaction artifact for epistemic change. Records triggering evidence, affected beliefs, revised beliefs, retracted beliefs, confidence changes, justification delta, governance review, lifecycle events, semantic events, knowledge delta, ledger delta, and memory delta.

### 4. ExperienceRetrievalResult
Canonical transaction artifact for institutional memory access. Records query parameters, retrieved episode references (lightweight, not full objects), similarity metrics, ranking justification, ledger delta, memory delta, lifecycle events, semantic events, and constitutional validation.

### 5. EpisodeIndex
**Derived index over immutable Research Episodes.** Exists solely to accelerate retrieval. May always be rebuilt from canonical Episodes. Contains lightweight searchable metadata (episode_id, topic, domain, keywords, outcome, publication_ids, confidence, start_tick, end_tick, transaction_counts, embedding).

**Constitutional Definition**:
> A derived index over immutable Research Episodes that exists solely to accelerate retrieval. It may always be rebuilt from canonical Episodes.

---

## Principle 12 Strengthened

Principle 12 has been renamed and redefined:

### Before
**Principle 12 — Episodic Integrity**  
Every institutional action belongs to exactly one immutable Research Episode.

### After
**Principle 12 — Institutional Episodic Integrity**  
Every completed institutional investigation shall terminate in exactly one immutable Research Episode. All canonical transactions generated during that investigation belong exclusively to that Episode. Derived indexes may accelerate retrieval but never replace canonical history.

This strengthened definition prevents future architectural drift by explicitly separating:
- **Canonical History** (ResearchEpisode - immutable, permanent)
- **Derived Indexes** (EpisodeIndex - rebuildable, accelerative only)

---

## Implementation Highlights

### EpisodeIndex Service Architecture

Created [EpisodeIndex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/episode_index.ex) as a constitutional service (not subsystem):

```elixir
defmodule TiannaraOS.EpisodeIndex do
  defstruct [
    :institution_id,              # Owning institution
    :entries,                     # %{episode_id => Entry.t()}
    :total_episodes               # Total indexed episodes
  ]
  
  defmodule Entry do
    defstruct [
      :episode_id,                # Reference to canonical episode
      :topic,                     # Semantic topic
      :domain,                    # Research domain
      :keywords,                  # Searchable keywords
      :outcome,                   # :success | :failure | :deferred | :rejected
      :publication_ids,           # Associated publications
      :confidence,                # Overall investigation confidence
      :start_tick,                # Episode start
      :end_tick,                  # Episode end
      :transaction_counts,        # Transaction type counts
      :embedding                  # VSA embedding (owned by retrieval engine)
    ]
  end
  
  # Public API
  def new(institution_id)
  def add_entry(index, episode)          # Index canonical episode
  def search(index, query, opts)         # Semantic search
  def get_entry(index, episode_id)       # Get entry by ID
  def list_episode_ids(index)            # List all episode IDs
end
```

**Key Properties**:
- Stores only lightweight metadata (not full episodes)
- Embeddings owned by retrieval engine (not index)
- Rebuildable from canonical Episodes at any time
- No persistent state beyond what's derivable from Episodes

### Modified store_episode

Updated `InstitutionKernel.store_episode/2` to persist FULL episode objects and automatically index them:

```elixir
defp store_episode(state, episode) do
  # Store FULL episode object in civilizational_memory[:episodes]
  existing_episodes = Map.get(state.institution.civilizational_memory, :episodes, %{})
  updated_episodes = Map.put(existing_episodes, episode.episode_id, episode)
  
  # Add to Episode Index (constitutional service)
  existing_index = Map.get(state.institution.civilizational_memory, :episode_index, 
                           TiannaraOS.EpisodeIndex.new(state.institution.id))
  updated_index = TiannaraOS.EpisodeIndex.add_entry(existing_index, episode)
  
  # Update state with both episodes map and index
  %{state | institution: %{state.institution | 
    civilizational_memory: %{
      state.institution.civilizational_memory |
      episodes: updated_episodes,
      episode_index: updated_index
    }
  }}
end
```

**Result**: Episodes stored once, indexed automatically, both derivable from each other.

### Modified get_institution_episodes

Replaced simulation with actual episode retrieval from EpisodeIndex + civilizational_memory:

```elixir
defp get_institution_episodes(state) do
  episode_index = Map.get(state.institution.civilizational_memory, :episode_index, nil)
  
  if episode_index == nil do
    []
  else
    # Get episode IDs from index
    episode_ids = TiannaraOS.EpisodeIndex.list_episode_ids(episode_index)
    
    # Retrieve full canonical episodes from storage
    stored_episodes = Map.get(state.institution.civilizational_memory, :episodes, %{})
    
    Enum.map(episode_ids, fn episode_id ->
      Map.get(stored_episodes, episode_id)
    end)
    |> Enum.filter(& &1)  # Remove nils
  end
end
```

**Result**: Returns actual canonical ResearchEpisode objects, not simulations.

### Semantic Search Implementation

Implemented keyword/topic matching in `EpisodeIndex.search/3`:

```elixir
defp calculate_similarity(entry, query) do
  query_topic = String.downcase(Map.get(query, :topic, ""))
  query_keywords = Map.get(query, :keywords, [])
  
  entry_topic = String.downcase(entry.topic || "")
  entry_keywords = entry.keywords
  
  # Keyword matching score
  keyword_matches = Enum.count(query_keywords, fn qkw ->
    Enum.any?(entry_keywords, fn ekw ->
      String.contains?(ekw, String.downcase(qkw)) or
      String.contains?(String.downcase(qkw), ekw)
    end)
  end)
  
  keyword_score = if length(query_keywords) > 0 do
    keyword_matches / length(query_keywords)
  else
    0.0
  end
  
  # Topic matching score (substring match)
  topic_score = if String.length(query_topic) > 3 and String.contains?(entry_topic, query_topic) do
    0.8
  else
    0.0
  end
  
  # Combined score (weighted)
  combined_score = (keyword_score * 0.6) + (topic_score * 0.4)
  min(combined_score * 1.2, 1.0)
end
```

**Note**: Current implementation uses simple keyword/topic matching. In production, would use VSA embeddings, hyperdimensional computing, or vector similarity on the `:embedding` field. The key architectural property is that the embedding algorithm is **replaceable** without changing the constitutional interface.

---

## Constitutional Hierarchy

The complete constitutional hierarchy is now:

```
Institution
    │
    ▼
Research Episode                    ← Constitutional Primitive (immutable)
    │
    ├───────────────────────────────┐
    │                               │
    ▼                               ▼
ResearchCycleResult              BeliefRevisionResult
    │                               │
    └──────────┬────────────────────┘
               │
               ▼
        PublicationResult
               │
               ▼
        Episode Index                 ← Derived Service (rebuildable)
               │
               ▼
     retrieve_experience()            ← Public API
               │
               ▼
  ExperienceRetrievalResult          ← Canonical Transaction
```

**Notice what disappeared**:
- ❌ No mention of VSA
- ❌ No mention of Hyperdimensional Computing
- ❌ No mention of Embeddings
- ❌ No mention of Sparse Distributed Memory
- ❌ No mention of ANN Search

These have become **replaceable implementation details**, exactly as the Constitution intended. The retrieval engine can swap algorithms without affecting the constitutional interface.

---

## Downstream Impact on Phase 12 Capabilities

Every remaining Phase 12 capability now composes the same constitutional primitives:

### Capability 12.6 — Do-Calculus
```
Episode
  ↓
find interventions (previous experimental episodes)
  ↓
compute counterfactuals (from canonical transactions)
```

### Capability 12.7 — Neuro-Symbolic Router
```
Problem
  ↓
Episode Retrieval (retrieve_experience)
  ↓
previous reasoning (from retrieved episodes)
  ↓
choose solver (based on historical success patterns)
```

### Capability 12.8 — Cognitive Immune System
```
Episode stream (continuous monitoring)
  ↓
detect corruption patterns (anomalous episode sequences)
  ↓
quarantine institution (if pattern detected)
```

### Capability 12.9 — Research OS
```
Institution Scheduler
  ↓
Episodes (orchestrate production)
  ↓
Kernel (execute research cycles)
  ↓
Results (ResearchCycleResult, BeliefRevisionResult, etc.)
```

### Capability 12.10 — Distributed Validation
```
Episode (from local institution)
  ↓
other institutions (share via Discovery Exchange)
  ↓
agreement graph (compare episodes across institutions)
```

### Capability 12.11 — Epistemic Coarse Graining
```
100 Episodes (collect from institutional history)
  ↓
Scientific Pattern (identify recurring structures)
  ↓
Institutional Memory (compress into higher-level abstractions)
```

### Capability 12.12 — Topological Knowledge
```
Episode Graph (nodes = episodes, edges = relationships)
  ↓
Persistent structures (homology, Betti numbers)
  ↓
Scientific topology (discover invariant structures)
```

### Capability 12.13 — Active Epistemic Foraging
```
Episode history (analyze past investigations)
  ↓
knowledge gaps (identify unexplored regions)
  ↓
next investigation (select high-value research goals)
```

**Key Observation**: None of these capabilities need new memory abstractions. They all operate over:
- ResearchEpisode (canonical primitive)
- EpisodeIndex (derived service)
- retrieve_experience() (public API)
- ExperienceRetrievalResult (canonical transaction)

---

## Constitutional Artifacts Produced

Following the Three-Artifact Rule:

1. ✅ **Capability Specification**: Episode retrieval over canonical institutional history
   - [episode_index.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/episode_index.ex) (312 lines)
   - Modified [institution_kernel.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/institution_kernel.ex) (store_episode, get_institution_episodes)

2. ✅ **Validation Scenarios**: [run_capability_12_5_1_validation.exs](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/run_capability_12_5_1_validation.exs) (424 lines, 7 scenarios executed)

3. ✅ **Constitution Report**: This document (Capability_12_5_1_Report.md)

---

## Definition of Done — Satisfied ✅

> A Research Institution can retrieve semantically relevant episodes from authentic institutional history when:
> 1. Retrieval searches canonical ResearchEpisode objects (not simulations)
> 2. EpisodeIndex serves as a derived, rebuildable index (not persistent storage)
> 3. All seven constitutional scenarios pass against genuine institutional history
> 4. Retrieval API remains stable regardless of underlying search algorithm
> 5. Episodes remain the sole canonical unit of institutional history

**All criteria met**:
- ✅ Retrieval searches canonical ResearchEpisode objects (Scenario 1, 3, 7)
- ✅ EpisodeIndex is derived and rebuildable (architectural discipline maintained)
- ✅ All 7/7 scenarios passed against genuine history
- ✅ Retrieval API stable (`retrieve_experience/3` signature unchanged)
- ✅ ResearchEpisode remains sole canonical unit (Principle 12 satisfied)

---

## What Is Now Frozen

### Constitutional Infrastructure (Immutable until Phase 13)
- InstitutionKernel
- Runtime Atlas
- Lifecycle Registry
- Semantic Event Bus
- Governance Engine
- Knowledge Graph
- Economic Ledger
- Memory Pipeline
- Validation Framework

### Constitutional Primitives (Immutable until Phase 13)
- ResearchEpisode
- ResearchCycleResult
- BeliefRevisionResult
- ExperienceRetrievalResult
- EpisodeIndex (explicitly defined as derived index)

### Constitutional Principles (Immutable until Phase 13)
- Principles 1–12 (including Institutional Episodic Integrity)
- Constitutional invariants
- Three-Artifact Rule
- Capability-first engineering discipline

---

## Transition to Capability 12.6

With Capability 12.5.1 frozen, Phase 12 has achieved stable progression:

- ✅ 12.1 — Institutional Research Runtime
- ✅ 12.2 — Inter-Institution Exchange
- ✅ 12.3 — Domain Profiles
- ✅ 12.4 — Constitutional Belief Revision
- ✅ 12.5 — Institutional Semantic Memory

The next capability is **Capability 12.6 — Institutional Causal Intervention Reasoning**, where the objective is:

> Every Research Institution can reason about interventions and counterfactuals by composing immutable Research Episodes, canonical transactions, and the frozen constitutional substrate while preserving complete explainability and constitutional integrity.

This continues the established engineering discipline: **capabilities evolve; the Constitution remains fixed.**

---

**Capability 12.5.1 is constitutionally complete and frozen.**  
**Episode retrieval operates over canonical institutional history.**  
**Ready for Capability 12.6 — Institutional Causal Intervention Reasoning.**
