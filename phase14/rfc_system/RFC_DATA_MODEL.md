# Phase 14.1 — RFC Data Model Specification

**Date**: July 3, 2026  
**Phase**: 14.1.0 (Architecture Review)  
**Status**: 🔒 SCHEMA FREEZE PENDING  

---

## Overview

This document defines all immutable schemas for the RFC system. Every field is typed, documented, and frozen before implementation. All IDs are content-addressed (SHA-256) for immutability.

---

## Core Entity Schemas

### 1. RFC (Request for Constitution)

**Owner**: `RFCRegistry`  
**Immutable ID**: SHA-256(initial_proposal_genome_json)  
**Storage**: ETS table + ledger events  

```elixir
defmodule TiannaraOS.Governance.RFC do
  @typedoc """
  RFC - Top-level container for constitutional evolution proposals
  
  An RFC tracks the complete lifecycle from draft to freeze,
  potentially containing multiple proposal versions if amendments
  are made during review.
  """
  @type t :: %__MODULE__{
    rfc_id: String.t(),
    title: String.t(),
    description: String.t(),
    proposer_id: String.t(),
    proposer_institution: String.t(),
    status: status(),
    version: integer(),
    created_at: DateTime.t(),
    updated_at: DateTime.t(),
    superseded_by: String.t() | nil,
    proposal_genome_hash: String.t(),
    current_proposal_id: String.t(),
    certificate_hash: String.t() | nil,
    replay_hash: String.t() | nil,
    archived: boolean()
  }

  defstruct [
    :rfc_id,
    :title,
    :description,
    :proposer_id,
    :proposer_institution,
    :status,
    :version,
    :created_at,
    :updated_at,
    :superseded_by,
    :proposal_genome_hash,
    :current_proposal_id,
    :certificate_hash,
    :replay_hash,
    :archived
  ]

  @type status ::
    :draft |
    :submitted |
    :under_review |
    :simulating |
    :institutional_review |
    :ratification_vote |
    :approved |
    :migrating |
    :deployed |
    :replay_verified |
    :frozen |
    :rejected

  @doc """
  Generate immutable RFC ID from initial proposal genome.
  
  This ensures deterministic, content-addressed identification.
  Same genome → same ID always.
  """
  @spec generate_id(ProposalGenome.t()) :: String.t()
  def generate_id(genome) do
    genome_json = Jason.encode!(genome)
    :crypto.hash(:sha256, genome_json)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Validate RFC structure before submission.
  """
  @spec validate(t()) :: {:ok, t()} | {:error, [String.t()]}
  def validate(%__MODULE__{} = rfc) do
    errors = []
    
    errors = if String.length(rfc.title) < 10 do
      ["Title must be at least 10 characters"] ++ errors
    else
      errors
    end
    
    errors = if String.length(rfc.description) < 50 do
      ["Description must be at least 50 characters"] ++ errors
    else
      errors
    end
    
    errors = if not Enum.member?(statuses(), rfc.status) do
      ["Invalid status: #{inspect(rfc.status)}"] ++ errors
    else
      errors
    end
    
    if Enum.empty?(errors) do
      {:ok, rfc}
    else
      {:error, Enum.reverse(errors)}
    end
  end

  defp statuses do
    [:draft, :submitted, :under_review, :simulating,
     :institutional_review, :ratification_vote, :approved,
     :migrating, :deployed, :replay_verified, :frozen, :rejected]
  end
end
```

---

### 2. Proposal

**Owner**: `ProposalLedger`  
**Immutable ID**: SHA-256(proposal_genome_json + proposer_id + timestamp)  
**Storage**: Ledger events only (no separate storage)  

```elixir
defmodule TiannaraOS.Governance.Proposal do
  @typedoc """
  Proposal - Specific version of an RFC's proposed changes
  
  A proposal is a concrete set of changes tied to a specific genome.
  Multiple proposals can exist under one RFC if amendments are made.
  """
  @type t :: %__MODULE__{
    proposal_id: String.t(),
    rfc_id: String.t(),
    version: integer(),
    status: status(),
    proposal_genome: ProposalGenome.t(),
    discussion_thread: [String.t()],
    reviews: [String.t()],
    simulations: [SimulationResult.t()],
    votes: [String.t()],
    ratification_result: ratification_result(),
    migration_plan_hash: String.t() | nil,
    deployment_log_hash: String.t() | nil,
    superseded_by: String.t() | nil,
    created_at: DateTime.t(),
    frozen_at: DateTime.t() | nil,
    certificate_hash: String.t() | nil
  }

  defstruct [
    :proposal_id,
    :rfc_id,
    :version,
    :status,
    :proposal_genome,
    :discussion_thread,
    :reviews,
    :simulations,
    :votes,
    :ratification_result,
    :migration_plan_hash,
    :deployment_log_hash,
    :superseded_by,
    :created_at,
    :frozen_at,
    :certificate_hash
  ]

  @type status ::
    :draft |
    :submitted |
    :under_review |
    :simulating |
    :approved |
    :rejected |
    :superseded

  @type ratification_result :: :approved | :rejected | nil

  @doc """
  Generate immutable proposal ID.
  
  Combines genome hash, proposer, and timestamp for uniqueness.
  """
  @spec generate_id(ProposalGenome.t(), String.t(), DateTime.t()) :: String.t()
  def generate_id(genome, proposer_id, timestamp) do
    content = "#{Jason.encode!(genome)}#{proposer_id}#{DateTime.to_iso8601(timestamp)}"
    :crypto.hash(:sha256, content)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Check if proposal can transition to next state.
  """
  @spec can_transition(t(), status()) :: boolean()
  def can_transition(%__MODULE__{status: :draft}, :submitted), do: true
  def can_transition(%__MODULE__{status: :submitted}, :under_review), do: true
  def can_transition(%__MODULE__{status: :under_review}, :simulating), do: true
  def can_transition(%__MODULE__{status: :simulating}, :approved), do: true
  def can_transition(%__MODULE__{status: :approved}, :superseded), do: true
  def can_transition(_, _), do: false
end
```

---

### 3. ProposalGenome (Measurable Representation)

**Owner**: `Proposal` (embedded)  
**Immutable**: Yes (part of proposal ID generation)  
**Purpose**: Quantifiable representation of proposal intent and impact  

```elixir
defmodule TiannaraOS.Governance.ProposalGenome do
  @typedoc """
  ProposalGenome - Measurable, quantifiable representation of a proposal
  
  This is the canonical form used for simulation, comparison, and
  impact assessment. Every field is measurable and trackable.
  """
  @type t :: %__MODULE__{
    # Intent and scope
    intent: String.t(),
    affected_domains: [atom()],
    affected_kernel: boolean(),
    affected_governance: boolean(),
    affected_science: boolean(),
    
    # Expected impacts (measurable)
    expected_fitness_delta: float(),
    expected_entropy_delta: float(),
    expected_cost: float(),
    expected_replay_impact: replay_impact(),
    expected_migration_cost: float(),
    expected_scientific_capital_change: float(),
    expected_archaeology_impact: archaeology_impact(),
    expected_complexity_score: float(),
    
    # Risk assessment
    risk_score: float(),
    safety_score: float(),
    migration_difficulty: difficulty(),
    rollback_difficulty: difficulty(),
    replay_difficulty: difficulty(),
    
    # Graph impact
    graph_impact: graph_impact(),
    
    # Dependency impact
    dependency_impact: [String.t()]
  }

  defstruct [
    # Intent and scope
    :intent,
    :affected_domains,
    :affected_kernel,
    :affected_governance,
    :affected_science,
    
    # Expected impacts (measurable)
    :expected_fitness_delta,
    :expected_entropy_delta,
    :expected_cost,
    :expected_replay_impact,
    :expected_migration_cost,
    :expected_scientific_capital_change,
    :expected_archaeology_impact,
    :expected_complexity_score,
    
    # Risk assessment
    :risk_score,
    :safety_score,
    :migration_difficulty,
    :rollback_difficulty,
    :replay_difficulty,
    
    # Graph impact
    :graph_impact,
    
    # Dependency impact
    :dependency_impact
  ]

  @type replay_impact :: :none | :minor | :major | :breaking
  @type archaeology_impact :: :none | :minor | :major
  @type difficulty :: :trivial | :easy | :moderate | :hard | :extreme

  @type graph_impact :: %{
    nodes_added: integer(),
    nodes_removed: integer(),
    edges_added: integer(),
    edges_removed: integer()
  }

  @doc """
  Validate genome has all required fields populated.
  """
  @spec validate(t()) :: {:ok, t()} | {:error, [String.t()]}
  def validate(%__MODULE__{} = genome) do
    errors = []
    
    errors = if String.length(genome.intent) < 20 do
      ["Intent must be at least 20 characters"] ++ errors
    else
      errors
    end
    
    errors = if Enum.empty?(genome.affected_domains) do
      ["Must specify at least one affected domain"] ++ errors
    else
      errors
    end
    
    errors = if genome.expected_fitness_delta < -1.0 or genome.expected_fitness_delta > 1.0 do
      ["Fitness delta must be between -1.0 and 1.0"] ++ errors
    else
      errors
    end
    
    errors = if genome.risk_score < 0.0 or genome.risk_score > 1.0 do
      ["Risk score must be between 0.0 and 1.0"] ++ errors
    else
      errors
    end
    
    errors = if genome.safety_score < 0.0 or genome.safety_score > 1.0 do
      ["Safety score must be between 0.0 and 1.0"] ++ errors
    else
      errors
    end
    
    if Enum.empty?(errors) do
      {:ok, genome}
    else
      {:error, Enum.reverse(errors)}
    end
  end

  @doc """
  Calculate overall proposal score (weighted combination of metrics).
  
  Higher is better. Used for ranking and prioritization.
  """
  @spec calculate_score(t()) :: float()
  def calculate_score(%__MODULE__{} = genome) do
    weights = %{
      fitness: 0.3,
      safety: 0.25,
      low_risk: 0.2,
      low_complexity: 0.15,
      low_cost: 0.1
    }
    
    score = 
      weights.fitness * max(0, genome.expected_fitness_delta + 1.0) / 2.0 +
      weights.safety * genome.safety_score +
      weights.low_risk * (1.0 - genome.risk_score) +
      weights.low_complexity * (1.0 - genome.expected_complexity_score) +
      weights.low_cost * (1.0 - min(genome.expected_cost / 1000.0, 1.0))
    
    Float.round(score, 3)
  end
end
```

---

### 4. DiscussionEvent (Ledger Event)

**Owner**: `ProposalLedger`  
**Immutable ID**: SHA-256(event_content + timestamp)  
**Storage**: Append-only ledger  

```elixir
defmodule TiannaraOS.Governance.DiscussionEvent do
  @typedoc """
  DiscussionEvent - Immutable record of discussion activity
  
  All discussions are ledger events, ensuring complete
  archaeological reconstruction capability.
  """
  @type t :: %__MODULE__{
    event_id: String.t(),
    proposal_id: String.t(),
    actor_id: String.t(),
    institution_id: String.t() | nil,
    event_type: event_type(),
    content: String.t(),
    parent_event_id: String.t() | nil,
    timestamp: DateTime.t(),
    event_hash: String.t(),
    previous_hash: String.t(),
    signature: String.t()
  }

  defstruct [
    :event_id,
    :proposal_id,
    :actor_id,
    :institution_id,
    :event_type,
    :content,
    :parent_event_id,
    :timestamp,
    :event_hash,
    :previous_hash,
    :signature
  ]

  @type event_type :: :comment | :question | :clarification | :amendment

  @doc """
  Generate event ID and hashes.
  """
  @spec create(String.t(), String.t(), event_type(), String.t(), String.t() | nil) :: t()
  def create(proposal_id, actor_id, type, content, parent_id \\ nil) do
    timestamp = DateTime.utc_now()
    
    event = %__MODULE__{
      event_id: "",  # Will be set after hashing
      proposal_id: proposal_id,
      actor_id: actor_id,
      institution_id: nil,
      event_type: type,
      content: content,
      parent_event_id: parent_id,
      timestamp: timestamp,
      event_hash: "",
      previous_hash: "",  # Will be set by ledger
      signature: ""  # Will be signed by EvidenceSigner
    }
    
    # Compute event hash
    content_hash = compute_content_hash(event)
    
    %__MODULE__{event |
      event_id: content_hash,
      event_hash: content_hash
    }
  end

  defp compute_content_hash(event) do
    content = "#{event.proposal_id}#{event.actor_id}#{Atom.to_string(event.event_type)}#{event.content}#{DateTime.to_iso8601(event.timestamp)}"
    :crypto.hash(:sha256, content)
    |> Base.encode16(case: :lower)
  end
end
```

---

### 5. ReviewEvent (Ledger Event)

**Owner**: `ProposalLedger`  
**Immutable ID**: SHA-256(review_content + board_id + timestamp)  

```elixir
defmodule TiannaraOS.Governance.ReviewEvent do
  @typedoc """
  ReviewEvent - Institutional review decision
  
  Captures formal review outcomes from review boards.
  """
  @type t :: %__MODULE__{
    event_id: String.t(),
    proposal_id: String.t(),
    review_board_id: String.t(),
    reviewer_ids: [String.t()],
    decision: decision(),
    rationale: String.t(),
    conditions: [String.t()] | nil,
    timestamp: DateTime.t(),
    event_hash: String.t(),
    previous_hash: String.t(),
    signature: String.t()
  }

  defstruct [
    :event_id,
    :proposal_id,
    :review_board_id,
    :reviewer_ids,
    :decision,
    :rationale,
    :conditions,
    :timestamp,
    :event_hash,
    :previous_hash,
    :signature
  ]

  @type decision :: :approve | :reject | :request_changes

  @doc """
  Create review event with institutional signature.
  """
  @spec create(String.t(), String.t(), [String.t()], decision(), String.t(), [String.t()] | nil) :: t()
  def create(proposal_id, board_id, reviewer_ids, decision, rationale, conditions \\ nil) do
    timestamp = DateTime.utc_now()
    
    event = %__MODULE__{
      event_id: "",
      proposal_id: proposal_id,
      review_board_id: board_id,
      reviewer_ids: reviewer_ids,
      decision: decision,
      rationale: rationale,
      conditions: conditions,
      timestamp: timestamp,
      event_hash: "",
      previous_hash: "",
      signature: ""
    }
    
    content_hash = compute_content_hash(event)
    
    %__MODULE__{event |
      event_id: content_hash,
      event_hash: content_hash
    }
  end

  defp compute_content_hash(event) do
    content = "#{event.proposal_id}#{event.review_board_id}#{Atom.to_string(event.decision)}#{event.rationale}#{DateTime.to_iso8601(event.timestamp)}"
    :crypto.hash(:sha256, content)
    |> Base.encode16(case: :lower)
  end
end
```

---

### 6. VoteEvent (Ledger Event)

**Owner**: `ProposalLedger`  

```elixir
defmodule TiannaraOS.Governance.VoteEvent do
  @typedoc """
  VoteEvent - Individual institutional vote on proposal
  """
  @type t :: %__MODULE__{
    event_id: String.t(),
    proposal_id: String.t(),
    institution_id: String.t(),
    voter_id: String.t(),
    vote: vote(),
    rationale: String.t() | nil,
    timestamp: DateTime.t(),
    event_hash: String.t(),
    previous_hash: String.t(),
    signature: String.t()
  }

  defstruct [
    :event_id,
    :proposal_id,
    :institution_id,
    :voter_id,
    :vote,
    :rationale,
    :timestamp,
    :event_hash,
    :previous_hash,
    :signature
  ]

  @type vote :: :yes | :no | :abstain

  @doc """
  Create vote event.
  """
  @spec create(String.t(), String.t(), String.t(), vote(), String.t() | nil) :: t()
  def create(proposal_id, institution_id, voter_id, vote, rationale \\ nil) do
    timestamp = DateTime.utc_now()
    
    event = %__MODULE__{
      event_id: "",
      proposal_id: proposal_id,
      institution_id: institution_id,
      voter_id: voter_id,
      vote: vote,
      rationale: rationale,
      timestamp: timestamp,
      event_hash: "",
      previous_hash: "",
      signature: ""
    }
    
    content_hash = compute_content_hash(event)
    
    %__MODULE__{event |
      event_id: content_hash,
      event_hash: content_hash
    }
  end

  defp compute_content_hash(event) do
    content = "#{event.proposal_id}#{event.institution_id}#{event.voter_id}#{Atom.to_string(event.vote)}#{DateTime.to_iso8601(event.timestamp)}"
    :crypto.hash(:sha256, content)
    |> Base.encode16(case: :lower)
  end
end
```

---

### 7. SimulationResult (Evidence Artifact)

**Owner**: `GovernanceValidationLaboratory`  
**Storage**: Content-addressed evidence store  

```elixir
defmodule TiannaraOS.Governance.SimulationResult do
  @typedoc """
  SimulationResult - Outcome of mandatory simulation test
  
  Each proposal must pass 8 simulations before approval.
  Results are stored as evidence artifacts.
  """
  @type t :: %__MODULE__{
    simulation_type: simulation_type(),
    proposal_id: String.t(),
    status: :pass | :fail,
    metrics: map(),
    evidence_artifact_hash: String.t(),
    certificate_hash: String.t(),
    timestamp: DateTime.t()
  }

  defstruct [
    :simulation_type,
    :proposal_id,
    :status,
    :metrics,
    :evidence_artifact_hash,
    :certificate_hash,
    :timestamp
  ]

  @type simulation_type ::
    :structural |
    :safety |
    :governance |
    :scientific |
    :economic |
    :performance |
    :migration |
    :replay

  @doc """
  Check if all required simulations passed.
  """
  @spec all_passed?([t()]) :: boolean()
  def all_passed?(results) do
    required_types = [:structural, :safety, :governance, :scientific,
                      :economic, :performance, :migration, :replay]
    
    Enum.all?(required_types, fn type ->
      Enum.any?(results, fn r ->
        r.simulation_type == type and r.status == :pass
      end)
    end)
  end
end
```

---

### 8. MigrationPlan

**Owner**: `MigrationPlanner`  

```elixir
defmodule TiannaraOS.Governance.MigrationPlan do
  @typedoc """
  MigrationPlan - Detailed plan for deploying proposal changes
  """
  @type t :: %__MODULE__{
    proposal_id: String.t(),
    migration_type: migration_type(),
    steps: [MigrationStep.t()],
    rollback_plan: RollbackPlan.t() | nil,
    estimated_downtime: integer(),
    estimated_cost: float(),
    risk_level: risk_level(),
    pre_migration_checks: [Check.t()],
    post_migration_verification: [Verification.t()]
  }

  defstruct [
    :proposal_id,
    :migration_type,
    :steps,
    :rollback_plan,
    :estimated_downtime,
    :estimated_cost,
    :risk_level,
    :pre_migration_checks,
    :post_migration_verification
  ]

  @type migration_type :: :additive | :modificative | :removal | :structural
  @type risk_level :: :low | :medium | :high | :critical

  @type MigrationStep.t() :: %{
    step_number: integer(),
    description: String.t(),
    command: String.t(),
    timeout_ms: integer(),
    rollback_command: String.t() | nil
  }

  @type RollbackPlan.t() :: %{
    strategy: :automatic | :manual | :impossible,
    steps: [String.t()],
    estimated_time_ms: integer()
  }

  @type Check.t() :: %{
    name: String.t(),
    check_function: atom(),
    must_pass: boolean()
  }

  @type Verification.t() :: %{
    name: String.t(),
    verify_function: atom(),
    tolerance: float()
  }
end
```

---

## Certificate Schemas

All certificates follow Phase 14 separated payload/signature structure.

### ProposalCertificate

```json
{
  "payload": {
    "certificate_type": "proposal_certification",
    "proposal_id": "...",
    "rfc_id": "...",
    "version": 1,
    "timestamp": "2026-07-03T00:00:00Z",
    "genome_hash": "...",
    "proposer_id": "...",
    "status": "frozen"
  },
  "signature": null
}
```

Saved as:
- `proposal_certificate.json` (payload)
- `proposal_certificate.sha256` (signature)

---

## Schema Validation Rules

### Immutable Fields

Once set, these fields **CANNOT** be modified:

- `rfc_id`
- `proposal_id`
- `event_id`
- `event_hash`
- `previous_hash`
- `created_at`
- `proposal_genome` (embedded in proposal)

### Mutable Fields

These fields can change during lifecycle:

- `status`
- `updated_at`
- `superseded_by`
- `certificate_hash`
- `replay_hash`

### Required Fields

All fields marked without `| nil` are **REQUIRED**.

---

## Schema Evolution Policy

### Adding Fields

✅ Allowed if:
- New field has default value
- Backward compatible
- Does not break existing queries

### Removing Fields

❌ Never allowed (breaks archaeology)

### Modifying Fields

❌ Never allowed (creates inconsistency)

### Deprecation Strategy

1. Mark field as `@deprecated`
2. Continue supporting for 2 major versions
3. Document migration path
4. Only remove after all references updated

---

## Conclusion

This data model specification defines all schemas with:

✅ **Complete typing** - Every field typed and documented  
✅ **Immutability guarantees** - Clear which fields are frozen  
✅ **Content-addressed IDs** - SHA-256 based for determinism  
✅ **Validation rules** - Pre-submission checks defined  
✅ **Evolution policy** - Safe schema changes only  

**Next Step**: Freeze these schemas before implementing any logic.
