defmodule TiannaraOS.Governance.ReviewBoard do
  @moduledoc """
  ReviewBoard - Manage RFC review process.

  Assigns reviewers, collects review reports, aggregates decisions,
  and determines if RFCs proceed to community discussion.

  ## Archaeology

  - **purpose**: Orchestrate RFC review by qualified reviewers
  - **introduced_in**: Phase 14.1
  - **depends_on**: TiannaraOS.Governance.RFC, TiannaraOS.Governance.RFCRegistry
  - **constitution_reference**: PHASE14_1_RFC_SYSTEM_SPECIFICATION.md Section 3.3
  - **owner**: Governance Council

  ## Usage

      {:ok, assignment} = ReviewBoard.assign_reviewer(rfc_id, reviewer_id)
      {:ok, report} = ReviewBoard.submit_review(rfc_id, review_report)
      {:ok, decision} = ReviewBoard.aggregate_reviews(rfc_id)
  """

  use GenServer

  alias TiannaraOS.Governance.{RFC, RFCRegistry}

  @type rfc_id :: String.t()
  @type reviewer_id :: String.t()
  @type review_report :: map()

  # Client API

  @doc """
  Start the Review Board.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Assign a reviewer to an RFC.

  Returns {:ok, assignment} with assignment details.
  """
  @spec assign_reviewer(rfc_id(), reviewer_id()) :: {:ok, map()} | {:error, term()}
  def assign_reviewer(rfc_id, reviewer_id) do
    GenServer.call(__MODULE__, {:assign_reviewer, rfc_id, reviewer_id})
  end

  @doc """
  Submit a review report for an RFC.

  Returns {:ok, report} on success.
  """
  @spec submit_review(rfc_id(), review_report()) :: {:ok, review_report()} | {:error, term()}
  def submit_review(rfc_id, review_report) do
    GenServer.call(__MODULE__, {:submit_review, rfc_id, review_report})
  end

  @doc """
  Aggregate all reviews for an RFC and make recommendation.

  Returns {:ok, decision} with approve/revise/reject recommendation.
  """
  @spec aggregate_reviews(rfc_id()) :: {:ok, map()} | {:error, term()}
  def aggregate_reviews(rfc_id) do
    GenServer.call(__MODULE__, {:aggregate_reviews, rfc_id})
  end

  @doc """
  Get reviewer workload (how many RFCs they're reviewing).

  Returns {:ok, workload_map}.
  """
  @spec get_reviewer_workload() :: {:ok, map()}
  def get_reviewer_workload() do
    GenServer.call(__MODULE__, :get_workload)
  end

  @doc """
  Get all reviews for an RFC.

  Returns {:ok, [review_report]}.
  """
  @spec get_reviews(rfc_id()) :: {:ok, [review_report()]} | {:error, :not_found}
  def get_reviews(rfc_id) do
    GenServer.call(__MODULE__, {:get_reviews, rfc_id})
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    {:ok, %{
      assignments: %{},    # %{rfc_id => [reviewer_id]}
      reviews: %{},        # %{rfc_id => [review_report]}
      workload: %{}        # %{reviewer_id => count}
    }}
  end

  @impl true
  def handle_call({:assign_reviewer, rfc_id, reviewer_id}, _from, state) do
    # Verify RFC exists and is in review stage
    case RFCRegistry.get_rfc(rfc_id) do
      {:error, :not_found} ->
        {:reply, {:error, :rfc_not_found}, state}
      {:ok, %RFC{status: :review}} ->
        # Add assignment
        assignments = Map.update(state.assignments, rfc_id, [reviewer_id], &[reviewer_id | &1])
        
        # Update workload
        workload = Map.update(state.workload, reviewer_id, 1, &(&1 + 1))
        
        assignment = %{
          assignment_id: generate_assignment_id(),
          rfc_id: rfc_id,
          reviewer_id: reviewer_id,
          assigned_at: DateTime.utc_now(),
          status: :pending
        }
        
        {:reply, {:ok, assignment}, %{state | assignments: assignments, workload: workload}}
      
      {:ok, _rfc} ->
        {:reply, {:error, :rfc_not_in_review_stage}, state}
    end
  end

  @impl true
  def handle_call({:submit_review, rfc_id, review_report}, _from, state) do
    # Verify reviewer was assigned to this RFC
    reviewer_id = Map.get(review_report, :reviewer)
    
    case Map.get(state.assignments, rfc_id, []) do
      reviewers when is_list(reviewers) ->
        if reviewer_id in reviewers do
          # Add review
          reviews = Map.update(state.reviews, rfc_id, [review_report], &[review_report | &1])
          
          # Update assignment status
          updated_assignments = update_assignment_status(state.assignments, rfc_id, reviewer_id)
          
          # Update workload (decrement pending)
          workload = update_workload(state.workload, reviewer_id)
          
          {:reply, {:ok, review_report}, %{
            state | 
            reviews: reviews,
            assignments: updated_assignments,
            workload: workload
          }}
        else
          {:reply, {:error, :reviewer_not_assigned}, state}
        end
    end
  end

  @impl true
  def handle_call({:aggregate_reviews, rfc_id}, _from, state) do
    reviews = Map.get(state.reviews, rfc_id, [])
    
    if Enum.empty?(reviews) do
      {:reply, {:error, :no_reviews_submitted}, state}
    else
      # Aggregate recommendations
      recommendations = Enum.map(reviews, & &1.recommendation)
      approve_count = Enum.count(recommendations, &(&1 == :approve))
      revise_count = Enum.count(recommendations, &(&1 == :request_revision))
      reject_count = Enum.count(recommendations, &(&1 == :reject))
      total = length(reviews)
      
      # Determine overall recommendation (majority rules)
      overall_recommendation = determine_recommendation(approve_count, revise_count, reject_count, total)
      
      # Identify common issues
      all_issues = Enum.flat_map(reviews, &(&1.identified_issues || []))
      critical_issues = Enum.filter(all_issues, &(&1.severity == :critical))
      
      decision = %{
        rfc_id: rfc_id,
        total_reviews: total,
        approve_count: approve_count,
        revise_count: revise_count,
        reject_count: reject_count,
        overall_recommendation: overall_recommendation,
        critical_issues: critical_issues,
        aggregated_at: DateTime.utc_now()
      }
      
      {:reply, {:ok, decision}, state}
    end
  end

  @impl true
  def handle_call(:get_workload, _from, state) do
    {:reply, {:ok, state.workload}, state}
  end

  @impl true
  def handle_call({:get_reviews, rfc_id}, _from, state) do
    case Map.get(state.reviews, rfc_id) do
      nil -> {:reply, {:error, :not_found}, state}
      reviews -> {:reply, {:ok, reviews}, state}
    end
  end

  # Private helpers

  defp generate_assignment_id() do
    timestamp = System.system_time(:millisecond)
    random = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
    "ASSIGN-#{timestamp}-#{random}"
  end

  defp update_assignment_status(assignments, _rfc_id, _reviewer_id) do
    # Mark assignment as completed for this reviewer
    # In production: track per-reviewer status
    assignments
  end

  defp update_workload(workload, reviewer_id) do
    # Decrement pending review count
    Map.update(workload, reviewer_id, 0, &max(0, &1 - 1))
  end

  defp determine_recommendation(approve, revise, reject, total) do
    # Simple majority logic
    cond do
      reject > total / 2 -> :reject
      revise > total / 2 -> :request_revision
      approve > total / 2 -> :approve
      true -> :request_revision  # Default to revision if no clear majority
    end
  end
end
