defmodule TiannaraOS.Governance.VoteEvent do
  @moduledoc """
  VoteEvent - Immutable record of institutional vote
  
  Captures a single institution's vote on a proposal during ratification.
  All fields are immutable once created (content-addressed).
  
  ## Owner
  ProposalLedger (append-only event storage)
  
  ## Guarantees
  - Immutable after creation
  - Content-addressed (SHA-256 hash)
  - Append-only to ledger
  - Vote is final (no edits)
  
  ## Usage
      iex> event = VoteEvent.create("vote_period_001", "inst_001", "voter_001", :yes)
      iex> VoteEvent.yes?(event)
      true
  """

  @typedoc """
  Vote event structure with all immutable fields.
  """
  @type t :: %__MODULE__{
    event_id: String.t(),
    vote_period_id: String.t(),
    proposal_id: String.t(),
    institution_id: String.t(),
    voter_id: String.t(),
    vote: :yes | :no | :abstain,
    timestamp: DateTime.t(),
    event_hash: String.t()
  }

  defstruct [
    :event_id,
    :vote_period_id,
    :proposal_id,
    :institution_id,
    :voter_id,
    :vote,
    :timestamp,
    :event_hash
  ]

  @doc """
  Create a new vote event (immutable).
  
  Computes event_hash from content for integrity verification.
  
  ## Parameters
  - `vote_period_id` - ID of voting period
  - `proposal_id` - ID of proposal being voted on
  - `institution_id` - ID of voting institution
  - `voter_id` - ID of individual voter
  - `vote` - :yes, :no, or :abstain
  
  ## Returns
  New immutable VoteEvent with computed hash
  """
  @spec create(String.t(), String.t(), String.t(), String.t(), :yes | :no | :abstain) :: t()
  def create(vote_period_id, proposal_id, institution_id, voter_id, vote)
      when vote in [:yes, :no, :abstain] do
    timestamp = DateTime.utc_now()

    # Compute content hash
    content = %{
      vote_period_id: vote_period_id,
      proposal_id: proposal_id,
      institution_id: institution_id,
      voter_id: voter_id,
      vote: vote,
      timestamp: DateTime.to_iso8601(timestamp)
    }

    event_hash = compute_hash(content)

    %__MODULE__{
      event_id: event_hash,
      vote_period_id: vote_period_id,
      proposal_id: proposal_id,
      institution_id: institution_id,
      voter_id: voter_id,
      vote: vote,
      timestamp: timestamp,
      event_hash: event_hash
    }
  end

  @doc """
  Check if vote was yes.
  """
  @spec yes?(t()) :: boolean()
  def yes?(%__MODULE__{vote: :yes}), do: true
  def yes?(%__MODULE__{}), do: false

  @doc """
  Check if vote was no.
  """
  @spec no?(t()) :: boolean()
  def no?(%__MODULE__{vote: :no}), do: true
  def no?(%__MODULE__{}), do: false

  @doc """
  Check if vote was abstain.
  """
  @spec abstained?(t()) :: boolean()
  def abstained?(%__MODULE__{vote: :abstain}), do: true
  def abstained?(%__MODULE__{}), do: false

  @doc """
  Verify event integrity by recomputing hash.
  
  Returns {:ok, true} if hash matches, {:error, reason} otherwise.
  """
  @spec verify_integrity(t()) :: {:ok, boolean()} | {:error, String.t()}
  def verify_integrity(%__MODULE__{} = event) do
    content = %{
      vote_period_id: event.vote_period_id,
      proposal_id: event.proposal_id,
      institution_id: event.institution_id,
      voter_id: event.voter_id,
      vote: event.vote,
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
  Convert vote event to JSON-compatible map.
  """
  @spec to_json_map(t()) :: map()
  def to_json_map(%__MODULE__{} = event) do
    %{
      event_id: event.event_id,
      vote_period_id: event.vote_period_id,
      proposal_id: event.proposal_id,
      institution_id: event.institution_id,
      voter_id: event.voter_id,
      vote: Atom.to_string(event.vote),
      timestamp: DateTime.to_iso8601(event.timestamp),
      event_hash: event.event_hash
    }
  end

  @doc """
  Create a test vote event for unit testing.
  """
  @spec test_event(:yes | :no | :abstain) :: t()
  def test_event(vote \\ :yes) do
    create(
      "test_vote_period_001",
      "test_proposal_001",
      "test_institution_001",
      "test_voter_001",
      vote
    )
  end

  # === Private Implementation ===

  defp compute_hash(content) do
    json = Jason.encode!(content)
    :crypto.hash(:sha256, json) |> Base.encode16(case: :lower)
  end

  def abstain?(_vote), do: false
end
