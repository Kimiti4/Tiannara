defmodule TiannaraOS.Governance.ReplayCertificate do
  @moduledoc """
  ReplayCertificate - Proof of deterministic replay
  
  Certifies that a proposal's lifecycle can be deterministically replayed
  from ledger events, producing identical state.
  
  ## Immutable Fields
  - `certificate_id` - SHA-256 hash (content-addressed)
  - `proposal_id` - Proposal being certified
  - `created_at` - Fixed timestamp
  
  ## Owner
  ReplayEngine is the canonical owner.
  
  ## Storage
  Ledger events only (append-only).
  """

  @enforce_keys [:certificate_id, :proposal_id, :seed, :events_replayed, :event_ids, :determinism_verified, :original_state_hash, :replayed_state_hash, :replay_duration_ms, :events_per_second, :all_events_valid, :started_at, :completed_at, :created_at]
  
  defstruct [
    :certificate_id,
    :proposal_id,
    :seed,
    :events_replayed,
    :event_ids,
    :determinism_verified,
    :original_state_hash,
    :replayed_state_hash,
    :state_match,
    :replay_duration_ms,
    :events_per_second,
    :all_events_valid,
    :invalid_events,
    :missing_events,
    :started_at,
    :completed_at,
    :created_at,
    :evidence_refs
  ]

  @type t :: %__MODULE__{
    certificate_id: String.t(),
    proposal_id: String.t(),
    seed: integer(),
    events_replayed: integer(),
    event_ids: [String.t()],
    determinism_verified: boolean(),
    original_state_hash: String.t(),
    replayed_state_hash: String.t(),
    state_match: boolean(),
    replay_duration_ms: integer(),
    events_per_second: float(),
    all_events_valid: boolean(),
    invalid_events: [map()],
    missing_events: [String.t()],
    started_at: DateTime.t(),
    completed_at: DateTime.t(),
    created_at: DateTime.t(),
    evidence_refs: [String.t()]
  }

  @doc """
  Create a new replay certificate.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) do
    with {:ok, validated} <- validate_new_attrs(attrs),
         {:ok, certificate_id} <- compute_certificate_id(validated),
         now <- get_timestamp(validated.deterministic_context) do
      cert = %__MODULE__{
        certificate_id: certificate_id,
        proposal_id: validated.proposal_id,
        seed: validated.seed,
        events_replayed: validated.events_replayed,
        event_ids: validated.event_ids,
        determinism_verified: validated.determinism_verified,
        original_state_hash: validated.original_state_hash,
        replayed_state_hash: validated.replayed_state_hash,
        state_match: validated.original_state_hash == validated.replayed_state_hash,
        replay_duration_ms: validated.replay_duration_ms,
        events_per_second: validated.events_per_second,
        all_events_valid: validated.all_events_valid,
        invalid_events: validated.invalid_events || [],
        missing_events: validated.missing_events || [],
        started_at: validated.started_at,
        completed_at: validated.completed_at,
        created_at: now,
        evidence_refs: validated.evidence_refs || []
      }
      
      {:ok, cert}
    end
  end

  @doc """
  Validate replay certificate structure.
  """
  @spec validate(t()) :: :ok | {:error, [String.t()]}
  def validate(cert) do
    errors = []
    
    errors = if String.length(cert.certificate_id) != 64 do
      ["certificate_id must be 64 characters"] ++ errors
    else
      errors
    end
    
    errors = if String.length(cert.proposal_id) != 64 do
      ["proposal_id must be 64 characters"] ++ errors
    else
      errors
    end
    
    errors = if not is_integer(cert.seed) do
      ["seed must be integer"] ++ errors
    else
      errors
    end
    
    errors = if not is_integer(cert.events_replayed) or cert.events_replayed <= 0 do
      ["events_replayed must be positive integer"] ++ errors
    else
      errors
    end
    
    errors = if length(cert.event_ids) == 0 do
      ["event_ids must have at least one event"] ++ errors
    else
      errors
    end
    
    errors = if not is_boolean(cert.determinism_verified) do
      ["determinism_verified must be boolean"] ++ errors
    else
      errors
    end
    
    errors = if String.length(cert.original_state_hash) != 64 do
      ["original_state_hash must be 64 characters"] ++ errors
    else
      errors
    end
    
    errors = if String.length(cert.replayed_state_hash) != 64 do
      ["replayed_state_hash must be 64 characters"] ++ errors
    else
      errors
    end
    
    errors = if not is_integer(cert.replay_duration_ms) or cert.replay_duration_ms <= 0 do
      ["replay_duration_ms must be positive integer"] ++ errors
    else
      errors
    end
    
    errors = if not is_boolean(cert.all_events_valid) do
      ["all_events_valid must be boolean"] ++ errors
    else
      errors
    end
    
    if Enum.empty?(errors) do
      :ok
    else
      {:error, Enum.reverse(errors)}
    end
  end

  @doc """
  Serialize to JSON-compatible map.
  """
  @spec to_json(t()) :: map()
  def to_json(cert) do
    %{
      certificate_id: cert.certificate_id,
      proposal_id: cert.proposal_id,
      seed: cert.seed,
      events_replayed: cert.events_replayed,
      event_ids: cert.event_ids,
      determinism_verified: cert.determinism_verified,
      original_state_hash: cert.original_state_hash,
      replayed_state_hash: cert.replayed_state_hash,
      state_match: cert.state_match,
      replay_duration_ms: cert.replay_duration_ms,
      events_per_second: cert.events_per_second,
      all_events_valid: cert.all_events_valid,
      invalid_events: cert.invalid_events,
      missing_events: cert.missing_events,
      started_at: DateTime.to_iso8601(cert.started_at),
      completed_at: DateTime.to_iso8601(cert.completed_at),
      created_at: DateTime.to_iso8601(cert.created_at),
      evidence_refs: cert.evidence_refs
    }
  end

  @doc """
  Deserialize from JSON-compatible map.
  """
  @spec from_json(map()) :: {:ok, t()} | {:error, String.t()}
  def from_json(json) do
    try do
      cert = %__MODULE__{
        certificate_id: json["certificate_id"],
        proposal_id: json["proposal_id"],
        seed: json["seed"],
        events_replayed: json["events_replayed"],
        event_ids: json["event_ids"],
        determinism_verified: json["determinism_verified"],
        original_state_hash: json["original_state_hash"],
        replayed_state_hash: json["replayed_state_hash"],
        state_match: json["state_match"],
        replay_duration_ms: json["replay_duration_ms"],
        events_per_second: json["events_per_second"],
        all_events_valid: json["all_events_valid"],
        invalid_events: json["invalid_events"] || [],
        missing_events: json["missing_events"] || [],
        started_at: case DateTime.from_iso8601(json["started_at"]) do
          {:ok, dt} -> dt
          _ -> DateTime.utc_now()
        end,
        completed_at: case DateTime.from_iso8601(json["completed_at"]) do
          {:ok, dt} -> dt
          _ -> DateTime.utc_now()
        end,
        created_at: case DateTime.from_iso8601(json["created_at"]) do
          {:ok, dt} -> dt
          _ -> DateTime.utc_now()
        end,
        evidence_refs: json["evidence_refs"] || []
      }
      
      {:ok, cert}
    rescue
      e -> {:error, "Failed to deserialize replay certificate: #{inspect(e)}"}
    end
  end

  # === Private Functions ===

  defp validate_new_attrs(attrs) do
    required = [
      :proposal_id, :seed, :events_replayed, :event_ids,
      :determinism_verified, :original_state_hash, :replayed_state_hash,
      :replay_duration_ms, :events_per_second, :all_events_valid,
      :started_at, :completed_at, :deterministic_context
    ]
    
    missing = Enum.filter(required, &is_nil(Map.get(attrs, &1)))
    
    if Enum.empty?(missing) do
      {:ok, attrs}
    else
      {:error, "Missing required fields: #{inspect(missing)}"}
    end
  end

  defp compute_certificate_id(attrs) do
    data = attrs.proposal_id <> Integer.to_string(attrs.seed) <> Jason.encode!(attrs.event_ids) <> DateTime.to_iso8601(attrs.deterministic_context.timestamp)
    hash = :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
    {:ok, hash}
  end

  defp get_timestamp(%{deterministic_context: %{timestamp: ts}}) do
    ts
  end
  
  defp get_timestamp(_context) do
    DateTime.utc_now()
  end
end
