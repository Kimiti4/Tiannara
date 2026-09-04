defmodule TiannaraOS.Governance.ReviewEvent do
  @moduledoc """
  ReviewEvent - Immutable record of institutional review
  
  Captures a single review board's decision on a proposal.
  All fields are immutable once created (content-addressed).
  
  ## Owner
  ProposalLedger (append-only event storage)
  
  ## Guarantees
  - Immutable after creation
  - Content-addressed (SHA-256 hash)
  - Append-only to ledger
  - Decision is final (no edits)
  
  ## Usage
      iex> event = ReviewEvent.create("board_001", "proposal_001", :approve, "Strong proposal")
      iex> ReviewEvent.approved?(event)
      true
  """

  @typedoc """
  Review event structure with all immutable fields.
  """
  @type t :: %__MODULE__{
    event_id: String.t(),
    proposal_id: String.t(),
    board_id: String.t(),
    decision: :approve | :reject | :abstain,
    rationale: String.t(),
    reviewer_ids: [String.t()],
    timestamp: DateTime.t(),
    event_hash: String.t()
  }

  defstruct [
    :event_id,
    :proposal_id,
    :board_id,
    :decision,
    :rationale,
    :reviewer_ids,
    :timestamp,
    :event_hash
  ]

  @doc """
  Create a new review event (immutable).
  
  Computes event_hash from content for integrity verification.
  
  ## Parameters
  - `board_id` - ID of review board
  - `proposal_id` - ID of proposal being reviewed
  - `decision` - :approve, :reject, or :abstain
  - `rationale` - Explanation of decision
  - `reviewer_ids` - List of reviewer IDs who participated
  
  ## Returns
  New immutable ReviewEvent with computed hash
  """
  @spec create(String.t(), String.t(), :approve | :reject | :abstain, String.t(), [String.t()]) ::
          t()
  def create(board_id, proposal_id, decision, rationale, reviewer_ids \\ [])
      when decision in [:approve, :reject, :abstain] do
    timestamp = DateTime.utc_now()

    # Compute content hash
    content = %{
      board_id: board_id,
      proposal_id: proposal_id,
      decision: decision,
      rationale: rationale,
      reviewer_ids: reviewer_ids,
      timestamp: DateTime.to_iso8601(timestamp)
    }

    event_hash = compute_hash(content)

    %__MODULE__{
      event_id: event_hash,
      proposal_id: proposal_id,
      board_id: board_id,
      decision: decision,
      rationale: rationale,
      reviewer_ids: reviewer_ids,
      timestamp: timestamp,
      event_hash: event_hash
    }
  end

  @doc """
  Check if review approved the proposal.
  """
  @spec approved?(t()) :: boolean()
  def approved?(%__MODULE__{decision: :approve}), do: true
  def approved?(%__MODULE__{}), do: false

  @doc """
  Check if review rejected the proposal.
  """
  @spec rejected?(t()) :: boolean()
  def rejected?(%__MODULE__{decision: :reject}), do: true
  def rejected?(%__MODULE__{}), do: false

  @doc """
  Check if review abstained.
  """
  @spec abstained?(t()) :: boolean()
  def abstained?(%__MODULE__{decision: :abstain}), do: true
  def abstained?(%__MODULE__{}), do: false

  @doc """
  Verify event integrity by recomputing hash.
  
  Returns {:ok, true} if hash matches, {:error, reason} otherwise.
  """
  @spec verify_integrity(t()) :: {:ok, boolean()} | {:error, String.t()}
  def verify_integrity(%__MODULE__{} = event) do
    content = %{
      board_id: event.board_id,
      proposal_id: event.proposal_id,
      decision: event.decision,
      rationale: event.rationale,
      reviewer_ids: event.reviewer_ids,
      timestamp: DateTime.to_iso8601(event.timestamp)
    }

    computed_hash = compute_hash(content)

    if computed_hash == event.event_hash do
      {:ok, true}
    else
      {:error, "Hash mismatch: expected #{event.event_hash}, got #{computed_hash}"}
    end
  end

  @doc """
  Convert review event to JSON-compatible map.
  """
  @spec to_json_map(t()) :: map()
  def to_json_map(%__MODULE__{} = event) do
    %{
      event_id: event.event_id,
      proposal_id: event.proposal_id,
      board_id: event.board_id,
      decision: Atom.to_string(event.decision),
      rationale: event.rationale,
      reviewer_ids: event.reviewer_ids,
      timestamp: DateTime.to_iso8601(event.timestamp),
      event_hash: event.event_hash
    }
  end

  @doc """
  Create a test review event for unit testing.
  """
  @spec test_event(:approve | :reject | :abstain) :: t()
  def test_event(decision \\ :approve) do
    create(
      "test_board_001",
      "test_proposal_001",
      decision,
      "Test rationale for unit testing",
      ["reviewer_001", "reviewer_002"]
    )
  end

  # === Private Implementation ===

  defp compute_hash(content) do
    json = Jason.encode!(content)
    :crypto.hash(:sha256, json) |> Base.encode16(case: :lower)
  end
end
