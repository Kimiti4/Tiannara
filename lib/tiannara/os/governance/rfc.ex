defmodule TiannaraOS.Governance.RFC do
  @moduledoc """
  RFC - Request for Constitution
  
  Top-level container for constitutional evolution proposals.
  
  An RFC tracks the complete lifecycle from draft to freeze,
  potentially containing multiple proposal versions if amendments
  are made during review.
  
  ## Immutable Fields
  - `rfc_id` - SHA-256 hash of initial proposal genome (content-addressed)
  - `created_at` - Fixed timestamp from deterministic context
  
  ## Mutable Fields
  - `status` - Lifecycle state (see t:status/0)
  - `updated_at` - Last state change timestamp
  - `superseded_by` - If replaced by another RFC
  - `certificate_hash` - Final certification hash
  - `replay_hash` - Replay verification hash
  - `archived` - True if frozen/archived
  
  ## Owner
  RFCRegistry is the canonical owner.
  
  ## Storage
  ETS table for fast lookup + ledger events for archaeology.
  """

  @enforce_keys [:rfc_id, :status, :title, :description, :proposer, :created_at, :updated_at]
  
  defstruct [
    :rfc_id,
    :status,
    :title,
    :description,
    :proposer,
    :created_at,
    :updated_at,
    :current_proposal_id,
    :proposal_ids,
    :superseded_by,
    :certificate_hash,
    :replay_hash,
    :archived,
    :tags,
    :related_rfc_ids
  ]

  @type status :: 
    :draft | :submitted | :under_review | :simulation | :approved |
    :ratified | :executing | :completed | :certified | :frozen |
    :rejected | :withdrawn | :superseded

  @type t :: %__MODULE__{
    rfc_id: String.t(),
    status: status(),
    title: String.t(),
    description: String.t(),
    proposer: String.t(),
    created_at: DateTime.t(),
    updated_at: DateTime.t(),
    current_proposal_id: String.t() | nil,
    proposal_ids: [String.t()],
    superseded_by: String.t() | nil,
    certificate_hash: String.t() | nil,
    replay_hash: String.t() | nil,
    archived: boolean(),
    tags: [atom()],
    related_rfc_ids: [String.t()]
  }

  @doc """
  Create a new RFC with deterministic context.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) do
    with {:ok, validated} <- validate_new_attrs(attrs),
         {:ok, rfc_id} <- compute_rfc_id(validated.proposal_genome),
         now <- get_timestamp(validated.deterministic_context) do
      rfc = %__MODULE__{
        rfc_id: rfc_id,
        status: :draft,
        title: validated.title,
        description: validated.description,
        proposer: validated.proposer,
        created_at: now,
        updated_at: now,
        current_proposal_id: nil,
        proposal_ids: [],
        superseded_by: nil,
        certificate_hash: nil,
        replay_hash: nil,
        archived: false,
        tags: Map.get(validated, :tags, []),
        related_rfc_ids: Map.get(validated, :related_rfc_ids, [])
      }
      
      {:ok, rfc}
    end
  end

  @doc """
  Update RFC status (state transition).
  """
  @spec update_status(t(), status(), map()) :: {:ok, t()} | {:error, String.t()}
  def update_status(rfc, new_status, context \\ %{}) do
    with :ok <- validate_transition(rfc.status, new_status),
         now <- get_timestamp(context) do
      updated = %{rfc | status: new_status, updated_at: now}
      {:ok, updated}
    end
  end

  @doc """
  Add a proposal to this RFC.
  """
  @spec add_proposal(t(), String.t()) :: {:ok, t()} | {:error, String.t()}
  def add_proposal(rfc, proposal_id) do
    updated = %{
      rfc |
      current_proposal_id: proposal_id,
      proposal_ids: rfc.proposal_ids ++ [proposal_id]
    }
    
    {:ok, updated}
  end

  @doc """
  Supersede this RFC with a newer one.
  """
  @spec supersede(t(), String.t(), map()) :: {:ok, t()} | {:error, String.t()}
  def supersede(rfc, new_rfc_id, context \\ %{}) do
    with :ok <- validate_transition(rfc.status, :superseded),
         now <- get_timestamp(context) do
      updated = %{
        rfc |
        status: :superseded,
        superseded_by: new_rfc_id,
        updated_at: now
      }
      
      {:ok, updated}
    end
  end

  @doc """
  Archive/freeze this RFC (final state).
  """
  @spec archive(t(), map()) :: {:ok, t()} | {:error, String.t()}
  def archive(rfc, context \\ %{}) do
    with :ok <- validate_transition(rfc.status, :frozen),
         now <- get_timestamp(context) do
      updated = %{
        rfc |
        status: :frozen,
        archived: true,
        updated_at: now
      }
      
      {:ok, updated}
    end
  end

  @doc """
  Validate RFC data structure.
  """
  @spec validate(t()) :: :ok | {:error, [String.t()]}
  def validate(rfc) do
    errors = []
    
    errors = if String.length(rfc.rfc_id) != 64 do
      ["rfc_id must be 64 characters (SHA-256 hex)"] ++ errors
    else
      errors
    end
    
    errors = if String.length(rfc.title) < 5 do
      ["title must be at least 5 characters"] ++ errors
    else
      errors
    end
    
    errors = if String.length(rfc.description) < 20 do
      ["description must be at least 20 characters"] ++ errors
    else
      errors
    end
    
    errors = if length(rfc.proposal_ids) > 0 and is_nil(rfc.current_proposal_id) do
      ["current_proposal_id required when proposal_ids present"] ++ errors
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
  Serialize RFC to JSON-compatible map.
  """
  @spec to_json(t()) :: map()
  def to_json(rfc) do
    %{
      rfc_id: rfc.rfc_id,
      status: Atom.to_string(rfc.status),
      title: rfc.title,
      description: rfc.description,
      proposer: rfc.proposer,
      created_at: DateTime.to_iso8601(rfc.created_at),
      updated_at: DateTime.to_iso8601(rfc.updated_at),
      current_proposal_id: rfc.current_proposal_id,
      proposal_ids: rfc.proposal_ids,
      superseded_by: rfc.superseded_by,
      certificate_hash: rfc.certificate_hash,
      replay_hash: rfc.replay_hash,
      archived: rfc.archived,
      tags: Enum.map(rfc.tags, &Atom.to_string/1),
      related_rfc_ids: rfc.related_rfc_ids
    }
  end

  @doc """
  Deserialize RFC from JSON-compatible map.
  """
  @spec from_json(map()) :: {:ok, t()} | {:error, String.t()}
  def from_json(json) do
    try do
      rfc = %__MODULE__{
        rfc_id: json["rfc_id"],
        status: String.to_existing_atom(json["status"]),
        title: json["title"],
        description: json["description"],
        proposer: json["proposer"],
        created_at: case DateTime.from_iso8601(json["created_at"]) do
          {:ok, dt} -> dt
          _ -> DateTime.utc_now()
        end,
        updated_at: case DateTime.from_iso8601(json["updated_at"]) do
          {:ok, dt} -> dt
          _ -> DateTime.utc_now()
        end,
        current_proposal_id: json["current_proposal_id"],
        proposal_ids: json["proposal_ids"],
        superseded_by: json["superseded_by"],
        certificate_hash: json["certificate_hash"],
        replay_hash: json["replay_hash"],
        archived: json["archived"],
        tags: Enum.map(json["tags"] || [], &String.to_existing_atom/1),
        related_rfc_ids: json["related_rfc_ids"] || []
      }
      
      {:ok, rfc}
    rescue
      e -> {:error, "Failed to deserialize RFC: #{inspect(e)}"}
    end
  end

  # === Private Functions ===

  defp validate_new_attrs(attrs) do
    required = [:title, :description, :proposer, :proposal_genome, :deterministic_context]
    
    missing = Enum.filter(required, &is_nil(Map.get(attrs, &1)))
    
    if Enum.empty?(missing) do
      {:ok, attrs}
    else
      {:error, "Missing required fields: #{inspect(missing)}"}
    end
  end

  defp compute_rfc_id(proposal_genome) do
    genome_json = Jason.encode!(proposal_genome)
    hash = :crypto.hash(:sha256, genome_json) |> Base.encode16(case: :lower)
    {:ok, hash}
  end

  defp get_timestamp(%{deterministic_context: %{timestamp: ts}}) do
    ts
  end
  
  defp get_timestamp(_context) do
    DateTime.utc_now()
  end

  defp validate_transition(from, to) do
    allowed_transitions = %{
      draft: [:submitted, :withdrawn],
      submitted: [:under_review, :withdrawn],
      under_review: [:simulation, :rejected, :withdrawn],
      simulation: [:approved, :rejected],
      approved: [:ratified],
      ratified: [:executing],
      executing: [:completed],
      completed: [:certified],
      certified: [:frozen],
      rejected: [],
      withdrawn: [],
      superseded: [],
      frozen: []
    }
    
    targets = Map.get(allowed_transitions, from, [])
    if to in targets do
      :ok
    else
      {:error, "Invalid transition from #{from} to #{to}"}
    end
  end
end
