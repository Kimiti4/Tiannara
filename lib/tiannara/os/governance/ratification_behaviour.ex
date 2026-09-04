defmodule TiannaraOS.Governance.RatificationBehaviour do
  @moduledoc """
  RatificationBehaviour - Contract for institutional voting
  
  Defines the interface for formal institutional ratification process.
  Handles vote opening, casting, tallying, and certificate generation.
  
  ## Owner
  GovernanceValidationLaboratory (existing, frozen)
  
  ## Ratification Types
  1. **Supermajority** - 66% approval required (standard proposals)
  2. **Unanimous** - 100% approval required (constitutional amendments)
  
  ## Guarantees
  - Votes are immutable once cast
  - Threshold enforcement is strict
  - Ratification certificates use separated structure
  - Vote tallying is deterministic
  
  ## Usage
      defmodule MyRatificationSystem do
        @behaviour TiannaraOS.Governance.RatificationBehaviour
        
        @impl true
        def open_vote(proposal_id, threshold) do
          # Implementation
        end
      end
  """

  @doc """
  Open a new voting period for a proposal.
  
  Initializes the ratification process with specified threshold.
  
  ## Parameters
  - `proposal_id` - ID of proposal to be voted on
  - `threshold` - :supermajority (66%) or :unanimous (100%)
  
  ## Returns
  {:ok, vote_period_id} on success, {:error, reason} on failure
  """
  @callback open_vote(String.t(), :supermajority | :unanimous) ::
              {:ok, String.t()} | {:error, String.t()}

  @doc """
  Cast a vote in an active voting period.
  
  Records an institution's vote on the proposal.
  
  ## Parameters
  - `vote_period_id` - ID of voting period
  - `institution_id` - ID of voting institution
  - `voter_id` - ID of individual voter within institution
  - `vote` - :yes, :no, or :abstain
  
  ## Returns
  {:ok, %VoteEvent{}} on success, {:error, reason} on failure
  """
  @callback cast_vote(String.t(), String.t(), String.t(), :yes | :no | :abstain) ::
              {:ok, TiannaraOS.Governance.VoteEvent.t()} | {:error, String.t()}

  @doc """
  Tally votes at the end of voting period.
  
  Counts all votes and determines if threshold was met.
  
  ## Parameters
  - `vote_period_id` - ID of voting period to tally
  
  ## Returns
  Map with vote counts and approval status
  """
  @callback tally_votes(String.t()) ::
              {:ok, %{
                yes: integer(),
                no: integer(),
                abstain: integer(),
                approved: boolean()
              }} | {:error, String.t()}

  @doc """
  Generate ratification certificate proving vote completed.
  
  Creates separated certificate structure (payload + signature).
  
  ## Parameters
  - `votes` - List of all vote events
  - `approved` - Whether proposal was approved
  
  ## Returns
  {:ok, %{payload_path, sig_path}} or {:error, [reasons]}
  """
  @callback generate_ratification_certificate(
              [TiannaraOS.Governance.VoteEvent.t()],
              boolean()
            ) :: {:ok, map()} | {:error, [String.t()]}

  @optional_callbacks generate_ratification_certificate: 2
end
