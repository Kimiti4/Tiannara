defmodule TiannaraOS.Governance.ReviewBehaviour do
  @moduledoc """
  ReviewBehaviour - Contract for institutional review boards
  
  Defines the interface that all review boards must implement.
  Each board evaluates proposals from their domain expertise perspective.
  
  ## Owner
  GovernanceValidationLaboratory (existing, frozen)
  
  ## Review Boards
  1. **DomainReviewBoard** - Domain-specific technical expertise
  2. **ConstitutionalReviewBoard** - Governance compliance verification
  3. **ScientificReviewBoard** - Methodology soundness assessment
  
  ## Guarantees
  - All review boards implement this behaviour
  - Quorum checking enforced
  - Review certificates use separated structure
  - Decisions are immutable once recorded
  
  ## Usage
      defmodule MyReviewBoard do
        @behaviour TiannaraOS.Governance.ReviewBehaviour
        
        @impl true
        def submit_review(board_id, proposal_id) do
          # Implementation
        end
      end
  """

  @doc """
  Submit a review for a proposal.
  
  Executes the review process and records the decision.
  
  ## Parameters
  - `board_id` - ID of review board
  - `proposal_id` - ID of proposal being reviewed
  
  ## Returns
  {:ok, %ReviewEvent{}} on success, {:error, reason} on failure
  """
  @callback submit_review(String.t(), String.t()) ::
              {:ok, TiannaraOS.Governance.ReviewEvent.t()} | {:error, String.t()}

  @doc """
  Check if quorum has been met for a set of reviews.
  
  Determines if enough reviews have been collected and what the outcome is.
  
  ## Parameters
  - `reviews` - List of ReviewEvent structs
  
  ## Returns
  Map with quorum status and vote counts
  """
  @callback check_quorum([TiannaraOS.Governance.ReviewEvent.t()]) :: %{
              quorum_met: boolean(),
              approvals: integer(),
              rejections: integer()
            }

  @doc """
  Generate review certificate proving review process completed.
  
  Creates separated certificate structure (payload + signature).
  
  ## Parameters
  - `reviews` - List of all review events
  
  ## Returns
  {:ok, %{payload_path, sig_path}} or {:error, [reasons]}
  """
  @callback generate_review_certificate([TiannaraOS.Governance.ReviewEvent.t()]) ::
              {:ok, map()} | {:error, [String.t()]}

  @optional_callbacks generate_review_certificate: 1
end
