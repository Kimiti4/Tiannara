# Phase 14.1 — RFC Replay Model Specification

**Date**: July 3, 2026  
**Phase**: 14.1.0 (Architecture Review)  
**Status**: 🔒 PENDING FREEZE  

---

## Overview

This document defines the deterministic replay model for RFC proposals. Every proposal lifecycle must be reconstructable from ledger events alone, without any runtime GenServer state.

**Core Principle**: Same ledger + same seed = identical reconstructed state, always.

---

## Replay Architecture

### Components

```
ProposalLedger (canonical source)
    ↓
ProposalReplayEngine (reconstruction logic)
    ↓
DeterministicContext (seed + base_time)
    ↓
ReconstructedState (identical to original)
    ↓
VerificationModule (hash comparison)
```

### Replay Guarantees

✅ **Deterministic**: Identical inputs → identical outputs  
✅ **Complete**: All lifecycle stages reconstructable  
✅ **Verifiable**: Hash comparison validates correctness  
✅ **Trustless**: No runtime dependencies  
✅ **Archaeological**: Full explainability preserved  

---

## Replay Algorithm

### High-Level Flow

```elixir
defmodule TiannaraOS.Governance.ProposalReplayEngine do
  @doc """
  Reconstruct complete proposal lifecycle from ledger only.
  
  Args:
    proposal_id - Immutable proposal identifier
    seed - Deterministic seed for reconstruction
    base_time - Fixed timestamp for determinism
  
  Returns:
    {:ok, reconstructed_state} if successful
    {:error, reason} if replay fails
  """
  @spec replay_proposal(String.t(), integer(), DateTime.t()) ::
    {:ok, map()} | {:error, String.t()}
  def replay_proposal(proposal_id, seed, base_time) do
    # 1. Load all ledger events for this proposal
    events = ProposalLedger.get_events_for_proposal(proposal_id)
    
    if Enum.empty?(events) do
      {:error, "No ledger events found for proposal #{proposal_id}"}
    else
      # 2. Initialize deterministic context
      ctx = DeterministicContext.new(seed: seed, base_time: base_time)
      
      # 3. Replay events in chronological order
      reconstructed_state = Enum.reduce(events, initial_state(), fn event, acc ->
        apply_event(acc, event, ctx)
      end
      
      # 4. Verify reconstructed state
      case verify_replay(reconstructed_state, proposal_id) do
        :ok -> {:ok, reconstructed_state}
        {:error, reason} -> {:error, reason}
      end
    end
  end
  
  defp initial_state() do
    %{
      proposal: nil,
      discussion: [],
      reviews: [],
      simulations: [],
      votes: [],
      ratification_result: nil,
      migration: nil,
      deployment: nil,
      status: :draft
    }
  end
  
  defp apply_event(state, event, ctx) do
    case event.event_type do
      :proposal_submitted ->
        Map.put(state, :proposal, decode_proposal(event))
      
      :discussion_added ->
        update_discussion(state, event)
      
      :review_submitted ->
        update_reviews(state, event)
      
      :simulation_complete ->
        update_simulations(state, event)
      
      :vote_cast ->
        update_votes(state, event)
      
      :ratification_complete ->
        Map.put(state, :ratification_result, decode_ratification(event))
      
      :migration_started ->
        update_migration(state, event)
      
      :migration_complete ->
        update_deployment(state, event)
      
      _ ->
        state  # Ignore unknown events
    end
  end
  
  defp verify_replay(reconstructed, proposal_id) do
    # Load original certificate hash
    original_hash = get_original_certificate_hash(proposal_id)
    
    # Compute hash of reconstructed state
    reconstructed_hash = compute_state_hash(reconstructed)
    
    if original_hash == reconstructed_hash do
      :ok
    else
      {:error, "Hash mismatch: expected #{original_hash}, got #{reconstructed_hash}"}
    end
  end
end
```

---

## Event Application Logic

### 1. Proposal Submission

```elixir
defp decode_proposal(event) do
  %{
    proposal_id: event.proposal_id,
    rfc_id: event.rfc_id,
    version: 1,
    status: :submitted,
    proposal_genome: Jason.decode!(event.content),
    created_at: parse_timestamp(event.timestamp)
  }
end
```

### 2. Discussion Thread

```elixir
defp update_discussion(state, event) do
  discussion_item = %{
    event_id: event.event_id,
    actor_id: event.actor_id,
    content: event.content,
    timestamp: parse_timestamp(event.timestamp),
    parent_id: event.parent_event_id
  }
  
  %{state | discussion: state.discussion ++ [discussion_item]}
end
```

### 3. Review Decisions

```elixir
defp update_reviews(state, event) do
  review = %{
    event_id: event.event_id,
    review_board_id: event.review_board_id,
    reviewer_ids: event.reviewer_ids,
    decision: event.decision,
    rationale: event.rationale,
    conditions: event.conditions,
    timestamp: parse_timestamp(event.timestamp)
  }
  
  %{state | reviews: state.reviews ++ [review]}
end
```

### 4. Simulation Results

```elixir
defp update_simulations(state, event) do
  simulation = %{
    simulation_type: event.simulation_type,
    status: event.status,
    metrics: Jason.decode!(event.content),
    evidence_hash: event.evidence_artifact_hash,
    certificate_hash: event.certificate_hash,
    timestamp: parse_timestamp(event.timestamp)
  }
  
  %{state | simulations: state.simulations ++ [simulation]}
end
```

### 5. Vote Recording

```elixir
defp update_votes(state, event) do
  vote = %{
    event_id: event.event_id,
    institution_id: event.institution_id,
    voter_id: event.voter_id,
    vote: event.vote,
    rationale: event.rationale,
    timestamp: parse_timestamp(event.timestamp)
  }
  
  %{state | votes: state.votes ++ [vote]}
end
```

### 6. Migration Tracking

```elixir
defp update_migration(state, event) do
  migration = %{
    plan_hash: event.migration_plan_hash,
    started_at: parse_timestamp(event.timestamp),
    steps: decode_migration_steps(event)
  }
  
  %{state | migration: migration}
end

defp update_deployment(state, event) do
  deployment = %{
    completed_at: parse_timestamp(event.timestamp),
    success: event.success,
    rollback_available: event.rollback_available,
    deployment_log_hash: event.deployment_log_hash
  }
  
  %{state | deployment: deployment}
end
```

---

## Deterministic Context

### Purpose

Eliminate all sources of nondeterminism:

❌ Wall-clock time  
❌ Random numbers  
❌ Process IDs  
❌ Network timing  
❌ File system order  

✅ Explicit seed  
✅ Fixed base_time  
✅ Deterministic algorithms  

### Implementation

```elixir
defmodule TiannaraOS.Governance.DeterministicContext do
  @type t :: %__MODULE__{
    seed: integer(),
    base_time: DateTime.t(),
    random_stream: Enumerable.t()
  }

  defstruct [:seed, :base_time, :random_stream]

  @doc """
  Create deterministic context with fixed seed and time.
  """
  @spec new(seed: integer(), base_time: DateTime.t()) :: t()
  def new(seed: seed, base_time: base_time) do
    %__MODULE__{
      seed: seed,
      base_time: base_time,
      random_stream: random_stream(seed)
    }
  end

  @doc """
  Get next deterministic "random" value.
  
  Uses seed-based stream instead of :rand.uniform().
  """
  @spec next_random(t()) :: {float(), t()}
  def next_random(%__MODULE__{random_stream: stream} = ctx) do
    {value, new_stream} = Enum.split(stream, 1)
    {hd(value), %{ctx | random_stream: new_stream}}
  end

  @doc """
  Get deterministic timestamp offset from base_time.
  
  Instead of DateTime.utc_now(), use base_time + offset.
  """
  @spec timestamp_offset(t(), integer()) :: DateTime.t()
  def timestamp_offset(%__MODULE__{base_time: base}, offset_ms) do
    DateTime.add(base, offset_ms, :millisecond)
  end

  defp random_stream(seed) do
    # Use seeded PRNG for deterministic randomness
    :rand.seed(:exsplus, {seed, seed, seed})
    Stream.repeatedly(fn -> :rand.uniform() end)
  end
end
```

---

## Replay Verification

### Verification Steps

1. **Load Original Certificate**
   ```elixir
   original_cert = load_certificate(proposal_id)
   original_hash = original_cert.payload_hash
   ```

2. **Compute Reconstructed Hash**
   ```elixir
   reconstructed_json = Jason.encode!(reconstructed_state)
   reconstructed_hash = :crypto.hash(:sha256, reconstructed_json)
                      |> Base.encode16(case: :lower)
   ```

3. **Compare Hashes**
   ```elixir
   if original_hash == reconstructed_hash do
     {:ok, :verified}
   else
     {:error, "Hash mismatch"}
   end
   ```

### Verification Invariants

✅ **Invariant 1**: Same seed produces identical hash  
✅ **Invariant 2**: Ledger tampering detectable via hash mismatch  
✅ **Invariant 3**: Missing events cause reconstruction failure  
✅ **Invariant 4**: Event order matters (previous_hash chain)  

---

## Replay Scenarios

### Scenario 1: Complete Lifecycle Replay

**Input**: Proposal ID that reached FROZEN state  
**Expected**: Full reconstruction from DRAFT → FROZEN  
**Verification**: Final certificate hash matches  

```elixir
{:ok, state} = ProposalReplayEngine.replay_proposal(
  "abc123...",
  42,
  ~U[2026-01-01 00:00:00Z]
)

assert state.status == :frozen
assert state.ratification_result == :approved
assert length(state.simulations) == 8
assert length(state.votes) > 0
```

### Scenario 2: Partial Lifecycle Replay

**Input**: Proposal ID rejected during SIMULATING  
**Expected**: Reconstruction up to rejection point  
**Verification**: Status = :rejected, reason recorded  

```elixir
{:ok, state} = ProposalReplayEngine.replay_proposal(
  "def456...",
  42,
  ~U[2026-01-01 00:00:00Z]
)

assert state.status == :rejected
assert state.simulations |> Enum.any?(&(&1.status == :fail))
```

### Scenario 3: Superseded Proposal Replay

**Input**: Original proposal ID (superseded by new one)  
**Expected**: Reconstruction includes supersession event  
**Verification**: `superseded_by` field populated  

```elixir
{:ok, state} = ProposalReplayEngine.replay_proposal(
  "ghi789...",
  42,
  ~U[2026-01-01 00:00:00Z]
)

assert state.status == :superseded
assert state.superseded_by == "jkl012..."
```

### Scenario 4: Tampered Ledger Detection

**Input**: Proposal with modified ledger event  
**Expected**: Hash mismatch error  
**Verification**: Error message indicates tampering  

```elixir
{:error, reason} = ProposalReplayEngine.replay_proposal(
  "tampered...",
  42,
  ~U[2026-01-01 00:00:00Z]
)

assert reason =~ "Hash mismatch"
```

---

## Performance Considerations

### Replay Complexity

- **Time**: O(n) where n = number of ledger events
- **Space**: O(n) for reconstructed state
- **Typical n**: 50-500 events per proposal

### Optimization Strategies

1. **Event Indexing**
   - Index events by proposal_id for fast lookup
   - Binary search on timestamps

2. **State Snapshots**
   - Periodically save intermediate states
   - Resume from nearest snapshot instead of beginning

3. **Parallel Replay**
   - Independent proposals can replay in parallel
   - Same proposal must replay sequentially (event order matters)

### Benchmarks (Target)

| Proposal Complexity | Events | Replay Time | Memory |
|---------------------|--------|-------------|--------|
| Simple (additive) | 50 | < 10ms | < 1MB |
| Moderate (modificative) | 200 | < 50ms | < 5MB |
| Complex (structural) | 500 | < 200ms | < 10MB |

---

## Replay API

### Public Functions

```elixir
@doc """
Replay single proposal lifecycle.
"""
@spec replay_proposal(String.t(), integer(), DateTime.t()) ::
  {:ok, map()} | {:error, String.t()}

@doc """
Replay multiple proposals in parallel.
"""
@spec replay_proposals([String.t()], integer(), DateTime.t()) ::
  [{:ok, map()} | {:error, String.t()}]

@doc """
Verify replay integrity for proposal.
"""
@spec verify_replay(map(), String.t()) :: :ok | {:error, String.t()}

@doc """
Get replay statistics.
"""
@spec replay_stats(String.t()) :: %{
  events_processed: integer(),
  duration_ms: integer(),
  memory_bytes: integer(),
  hash_match: boolean()
}
```

---

## Edge Cases

### 1. Missing Events

**Problem**: Ledger gap (missing event in sequence)  
**Detection**: `previous_hash` chain broken  
**Action**: Return error with missing event ID  

```elixir
if event.previous_hash != last_event_hash do
  {:error, "Missing event between #{last_event.event_id} and #{event.event_id}"}
end
```

### 2. Duplicate Events

**Problem**: Same event_id appears twice  
**Detection**: Track seen event_ids  
**Action**: Skip duplicate or return error  

```elixir
if MapSet.member?(seen_ids, event.event_id) do
  Logger.warn("Duplicate event detected: #{event.event_id}")
  state  # Skip duplicate
else
  # Process normally
end
```

### 3. Out-of-Order Events

**Problem**: Events not in chronological order  
**Detection**: Timestamp regression  
**Action**: Sort by timestamp before replay  

```elixir
events = Enum.sort_by(events, & &1.timestamp, DateTime)
```

### 4. Unknown Event Types

**Problem**: New event type not recognized  
**Detection**: No matching case clause  
**Action**: Log warning, skip event (forward compatible)  

```elixir
defp apply_event(state, event, _ctx) do
  Logger.warn("Unknown event type: #{event.event_type}")
  state
end
```

---

## Testing Strategy

### Unit Tests

```elixir
test "replays simple proposal lifecycle" do
  {:ok, state} = replay_proposal("test1", 42, base_time())
  assert state.status == :frozen
  assert length(state.simulations) == 8
end

test "detects tampered ledger" do
  {:error, reason} = replay_proposal("tampered", 42, base_time())
  assert reason =~ "Hash mismatch"
end

test "handles missing events" do
  {:error, reason} = replay_proposal("incomplete", 42, base_time())
  assert reason =~ "Missing event"
end
```

### Property-Based Tests

```elixir
property "same seed produces identical replay" do
  check all seed <- integer() do
    state1 = replay_proposal("test", seed, base_time())
    state2 = replay_proposal("test", seed, base_time())
    assert state1 == state2
  end
end

property "different seeds produce different replays" do
  check all seed1 <- integer(), seed2 <- integer(), seed1 != seed2 do
    state1 = replay_proposal("test", seed1, base_time())
    state2 = replay_proposal("test", seed2, base_time())
    assert state1 != state2
  end
end
```

### Integration Tests

```elixir
test "full lifecycle replay matches original" do
  # Submit real proposal
  {:ok, proposal} = submit_test_proposal()
  
  # Wait for it to freeze
  wait_for_freeze(proposal.proposal_id)
  
  # Replay from ledger
  {:ok, reconstructed} = replay_proposal(
    proposal.proposal_id,
    42,
    proposal.created_at
  )
  
  # Verify match
  assert hashes_match?(proposal, reconstructed)
end
```

---

## Conclusion

This replay model ensures:

✅ **Deterministic reconstruction** - Same inputs → same outputs  
✅ **Ledger-only dependency** - No runtime state required  
✅ **Tamper detection** - Hash mismatches reveal corruption  
✅ **Complete archaeology** - Full lifecycle explainable  
✅ **Performance acceptable** - < 200ms for complex proposals  

**Next Step**: Implement replay engine after schema freeze.
