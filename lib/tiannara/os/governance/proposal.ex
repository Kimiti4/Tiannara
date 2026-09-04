defmodule TiannaraOS.Governance.Proposal do
  @moduledoc """
  Proposal - Specific version of an RFC's proposed changes
  
  A proposal is a concrete set of changes tied to a specific genome.
  Multiple proposals can exist under one RFC if amendments are made.
  
  ## Immutable Fields
  - `proposal_id` - SHA-256 hash (content-addressed)
  - `rfc_id` - Parent RFC reference
  - `created_at` - Fixed timestamp
  - `proposal_genome` - Measurable representation (embedded)
  
  ## Owner
  ProposalLedger is the canonical owner (append-only storage).
  
  ## Storage
  Ledger events only (no separate database).
  """

  @enforce_keys [:proposal_id, :rfc_id, :version, :status, :proposal_genome, :title, :description, :changes, :justification, :proposer, :created_at, :updated_at]
  
  defstruct [
    :proposal_id,
    :rfc_id,
    :version,
    :status,
    :proposal_genome,
    :title,
    :description,
    :changes,
    :justification,
    :proposer,
    :created_at,
    :updated_at,
    :review_records,
    :simulation_results,
    :ratification_record_id,
    :migration_plan_id,
    :certificate_hash,
    :replay_hash,
    :supersedes,
    :depends_on
  ]

  @type status :: 
    :draft | :submitted | :under_review | :simulating | :approved |
    :ratified | :executing | :completed | :certified | :rejected | :withdrawn

  @type t :: %__MODULE__{
    proposal_id: String.t(),
    rfc_id: String.t(),
    version: integer(),
    status: status(),
    proposal_genome: map(),
    title: String.t(),
    description: String.t(),
    changes: [map()],
    justification: String.t(),
    proposer: String.t(),
    created_at: DateTime.t(),
    updated_at: DateTime.t(),
    review_records: [String.t()],
    simulation_results: [String.t()],
    ratification_record_id: String.t() | nil,
    migration_plan_id: String.t() | nil,
    certificate_hash: String.t() | nil,
    replay_hash: String.t() | nil,
    supersedes: String.t() | nil,
    depends_on: [String.t()]
  }

  @doc """
  Create a new proposal with deterministic context.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) do
    with {:ok, validated} <- validate_new_attrs(attrs),
         {:ok, proposal_id} <- compute_proposal_id(validated),
         now <- get_timestamp(validated.deterministic_context) do
      proposal = %__MODULE__{
        proposal_id: proposal_id,
        rfc_id: validated.rfc_id,
        version: validated.version,
        status: :draft,
        proposal_genome: validated.proposal_genome,
        title: validated.title,
        description: validated.description,
        changes: validated.changes,
        justification: validated.justification,
        proposer: validated.proposer,
        created_at: now,
        updated_at: now,
        review_records: [],
        simulation_results: [],
        ratification_record_id: nil,
        migration_plan_id: nil,
        certificate_hash: nil,
        replay_hash: nil,
        supersedes: Map.get(validated, :supersedes),
        depends_on: Map.get(validated, :depends_on, [])
      }
      
      {:ok, proposal}
    end
  end

  @doc """
  Update proposal status (state transition).
  """
  @spec update_status(t(), status(), map()) :: {:ok, t()} | {:error, String.t()}
  def update_status(proposal, new_status, context \\ %{}) do
    with :ok <- validate_transition(proposal.status, new_status),
         now <- get_timestamp(context) do
      updated = %{proposal | status: new_status, updated_at: now}
      {:ok, updated}
    end
  end

  @doc """
  Add review record reference.
  """
  @spec add_review_record(t(), String.t()) :: {:ok, t()}
  def add_review_record(proposal, review_record_id) do
    updated = %{
      proposal |
      review_records: proposal.review_records ++ [review_record_id]
    }
    
    {:ok, updated}
  end

  @doc """
  Add simulation result reference.
  """
  @spec add_simulation_result(t(), String.t()) :: {:ok, t()}
  def add_simulation_result(proposal, simulation_result_id) do
    updated = %{
      proposal |
      simulation_results: proposal.simulation_results ++ [simulation_result_id]
    }
    
    {:ok, updated}
  end

  @doc """
  Set ratification record.
  """
  @spec set_ratification(t(), String.t()) :: {:ok, t()}
  def set_ratification(proposal, ratification_record_id) do
    updated = %{proposal | ratification_record_id: ratification_record_id}
    {:ok, updated}
  end

  @doc """
  Set migration plan.
  """
  @spec set_migration_plan(t(), String.t()) :: {:ok, t()}
  def set_migration_plan(proposal, migration_plan_id) do
    updated = %{proposal | migration_plan_id: migration_plan_id}
    {:ok, updated}
  end

  @doc """
  Validate proposal data structure.
  """
  @spec validate(t()) :: :ok | {:error, [String.t()]}
  def validate(proposal) do
    errors = []
    
    errors = if String.length(proposal.proposal_id) != 64 do
      ["proposal_id must be 64 characters (SHA-256 hex)"] ++ errors
    else
      errors
    end
    
    errors = if String.length(proposal.rfc_id) != 64 do
      ["rfc_id must be 64 characters (SHA-256 hex)"] ++ errors
    else
      errors
    end
    
    errors = if String.length(proposal.title) < 5 do
      ["title must be at least 5 characters"] ++ errors
    else
      errors
    end
    
    errors = if String.length(proposal.description) < 20 do
      ["description must be at least 20 characters"] ++ errors
    else
      errors
    end
    
    errors = if length(proposal.changes) == 0 do
      ["changes must have at least one change"] ++ errors
    else
      errors
    end
    
    errors = if String.length(proposal.justification) < 20 do
      ["justification must be at least 20 characters"] ++ errors
    else
      errors
    end
    
    errors = if not is_map(proposal.proposal_genome) do
      ["proposal_genome must be a map"] ++ errors
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
  Serialize proposal to JSON-compatible map.
  """
  @spec to_json(t()) :: map()
  def to_json(proposal) do
    %{
      proposal_id: proposal.proposal_id,
      rfc_id: proposal.rfc_id,
      version: proposal.version,
      status: Atom.to_string(proposal.status),
      proposal_genome: proposal.proposal_genome,
      title: proposal.title,
      description: proposal.description,
      changes: proposal.changes,
      justification: proposal.justification,
      proposer: proposal.proposer,
      created_at: DateTime.to_iso8601(proposal.created_at),
      updated_at: DateTime.to_iso8601(proposal.updated_at),
      review_records: proposal.review_records,
      simulation_results: proposal.simulation_results,
      ratification_record_id: proposal.ratification_record_id,
      migration_plan_id: proposal.migration_plan_id,
      certificate_hash: proposal.certificate_hash,
      replay_hash: proposal.replay_hash,
      supersedes: proposal.supersedes,
      depends_on: proposal.depends_on
    }
  end

  @doc """
  Deserialize proposal from JSON-compatible map.
  """
  @spec from_json(map()) :: {:ok, t()} | {:error, String.t()}
  def from_json(json) do
    try do
      proposal = %__MODULE__{
        proposal_id: json["proposal_id"],
        rfc_id: json["rfc_id"],
        version: json["version"],
        status: String.to_existing_atom(json["status"]),
        proposal_genome: json["proposal_genome"],
        title: json["title"],
        description: json["description"],
        changes: json["changes"],
        justification: json["justification"],
        proposer: json["proposer"],
        created_at: case DateTime.from_iso8601(json["created_at"]) do
          {:ok, dt} -> dt
          _ -> DateTime.utc_now()
        end,
        updated_at: case DateTime.from_iso8601(json["updated_at"]) do
          {:ok, dt} -> dt
          _ -> DateTime.utc_now()
        end,
        review_records: json["review_records"] || [],
        simulation_results: json["simulation_results"] || [],
        ratification_record_id: json["ratification_record_id"],
        migration_plan_id: json["migration_plan_id"],
        certificate_hash: json["certificate_hash"],
        replay_hash: json["replay_hash"],
        supersedes: json["supersedes"],
        depends_on: json["depends_on"] || []
      }
      
      {:ok, proposal}
    rescue
      e -> {:error, "Failed to deserialize proposal: #{inspect(e)}"}
    end
  end

  # === Private Functions ===

  defp validate_new_attrs(attrs) do
    required = [
      :rfc_id, :version, :title, :description, :changes,
      :justification, :proposer, :proposal_genome, :deterministic_context
    ]
    
    missing = Enum.filter(required, &is_nil(Map.get(attrs, &1)))
    
    if Enum.empty?(missing) do
      {:ok, attrs}
    else
      {:error, "Missing required fields: #{inspect(missing)}"}
    end
  end

  defp compute_proposal_id(attrs) do
    genome_json = Jason.encode!(attrs.proposal_genome)
    data = genome_json <> attrs.proposer <> DateTime.to_iso8601(attrs.deterministic_context.timestamp)
    hash = :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
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
      under_review: [:simulating, :rejected, :withdrawn],
      simulating: [:approved, :rejected],
      approved: [:ratified],
      ratified: [:executing],
      executing: [:completed],
      completed: [:certified],
      certified: [],
      rejected: [],
      withdrawn: []
    }
    
    targets = Map.get(allowed_transitions, from, [])
    if to in targets do
      :ok
    else
      {:error, "Invalid transition from #{from} to #{to}"}
    end
  end
end
