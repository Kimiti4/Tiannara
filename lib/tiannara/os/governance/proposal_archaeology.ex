defmodule TiannaraOS.Governance.ProposalArchaeology do
  @moduledoc """
  ProposalArchaeology - Historical query engine for proposal evolution
  
  Provides archaeological explainability by querying the complete history
  of proposal state changes from the immutable event ledger.
  
  ## Capabilities
  - Reconstruct proposal state at any point in time
  - Trace complete lineage of changes
  - Explain why/when/who made each change
  - Query historical states without affecting current state
  
  ## Owner
  Read-only interface to ProposalLedger events.
  """

  alias TiannaraOS.Governance.ProposalLedger

  # === Historical State Reconstruction ===

  @doc """
  Get proposal state at a specific point in time.
  
  Replays all events up to the given timestamp to reconstruct historical state.
  """
  @spec state_at_time(String.t(), DateTime.t()) :: map() | nil
  def state_at_time(proposal_id, timestamp) do
    events = ProposalLedger.get_proposal_events(proposal_id)
    
    historical_events = Enum.filter(events, fn event ->
      DateTime.compare(event.timestamp, timestamp) in [:lt, :eq]
    end)
    
    if Enum.empty?(historical_events) do
      nil
    else
      replay_events(historical_events)
    end
  end

  @doc """
  Get all state transitions for a proposal.
  """
  @spec get_transitions(String.t()) :: [map()]
  def get_transitions(proposal_id) do
    events = ProposalLedger.get_proposal_events(proposal_id)
    
    Enum.filter(events, fn event ->
      event.type == :status_changed
    end)
    |> Enum.map(fn event ->
      %{
        sequence: event.sequence,
        timestamp: event.timestamp,
        from: event.data.old_status,
        to: event.data.new_status,
        reason: event.data.reason
      }
    end)
  end

  @doc """
  Get complete timeline of a proposal's lifecycle.
  """
  @spec get_timeline(String.t()) :: [map()]
  def get_timeline(proposal_id) do
    events = ProposalLedger.get_proposal_events(proposal_id)
    
    Enum.map(events, fn event ->
      %{
        sequence: event.sequence,
        timestamp: event.timestamp,
        event_type: event.type,
        summary: summarize_event(event)
      }
    end)
  end

  # === Lineage Tracing ===

  @doc """
  Get parent RFC for a proposal.
  """
  @spec get_parent_rfc(String.t()) :: String.t() | nil
  def get_parent_rfc(proposal_id) do
    events = ProposalLedger.get_proposal_events(proposal_id)
    
    case Enum.find(events, &(&1.type == :proposal_created)) do
      nil -> nil
      event -> event.rfc_id
    end
  end

  @doc """
  Get all child proposals under an RFC.
  """
  @spec get_child_proposals(String.t()) :: [String.t()]
  def get_child_proposals(rfc_id) do
    events = ProposalLedger.get_rfc_events(rfc_id)
    
    events
    |> Enum.filter(&(&1.type == :proposal_created))
    |> Enum.map(& &1.proposal_id)
    |> Enum.uniq()
  end

  @doc """
  Get supersedes relationship chain.
  """
  @spec get_supersedes_chain(String.t()) :: [String.t()]
  def get_supersedes_chain(proposal_id) do
    events = ProposalLedger.get_proposal_events(proposal_id)
    
    case Enum.find(events, &(&1.type == :proposal_superseded)) do
      nil -> []
      event ->
        superseded_by = event.data.superseded_by
        [superseded_by | get_supersedes_chain(superseded_by)]
    end
  end

  # === Explanation Queries ===

  @doc """
  Explain why a proposal has its current status.
  """
  @spec explain_status(String.t()) :: {:ok, map()} | {:error, String.t()}
  def explain_status(proposal_id) do
    transitions = get_transitions(proposal_id)
    
    if Enum.empty?(transitions) do
      {:error, "No status transitions found"}
    else
      latest = List.last(transitions)
      
      {:ok, %{
        current_status: latest.to,
        changed_at: latest.timestamp,
        reason: latest.reason,
        transition_count: length(transitions),
        full_history: transitions
      }}
    end
  end

  @doc """
  Explain when a proposal reached a specific status.
  """
  @spec explain_when_reached(String.t(), atom()) :: {:ok, DateTime.t()} | {:error, String.t()}
  def explain_when_reached(proposal_id, target_status) do
    transitions = get_transitions(proposal_id)
    
    case Enum.find(transitions, &(&1.to == target_status)) do
      nil -> {:error, "Proposal never reached status #{target_status}"}
      transition -> {:ok, transition.timestamp}
    end
  end

  @doc """
  Get all review decisions for a proposal.
  """
  @spec get_review_history(String.t()) :: [map()]
  def get_review_history(proposal_id) do
    events = ProposalLedger.get_proposal_events(proposal_id)
    
    events
    |> Enum.filter(&(&1.type == :review_added))
    |> Enum.map(fn event ->
      %{
        review_id: event.data.review_id,
        decision: event.data.decision,
        reviewer_id: event.data.reviewer_id,
        rationale: event.data.rationale,
        timestamp: event.timestamp
      }
    end)
  end

  @doc """
  Get all simulation results for a proposal.
  """
  @spec get_simulation_history(String.t()) :: [map()]
  def get_simulation_history(proposal_id) do
    events = ProposalLedger.get_proposal_events(proposal_id)
    
    events
    |> Enum.filter(&(&1.type == :simulation_completed))
    |> Enum.map(fn event ->
      %{
        simulation_id: event.data.simulation_id,
        scenario: event.data.scenario,
        passed: event.data.passed,
        fitness_delta: event.data.fitness_delta,
        entropy_delta: event.data.entropy_delta,
        timestamp: event.timestamp
      }
    end)
  end

  # === Aggregate Queries ===

  @doc """
  Get statistics for all proposals in an RFC.
  """
  @spec rfc_statistics(String.t()) :: map()
  def rfc_statistics(rfc_id) do
    proposal_ids = get_child_proposals(rfc_id)
    
    stats = Enum.map(proposal_ids, fn proposal_id ->
      events = ProposalLedger.get_proposal_events(proposal_id)
      
      %{
        proposal_id: proposal_id,
        event_count: length(events),
        status: get_current_status(events),
        review_count: count_events(events, :review_added),
        simulation_count: count_events(events, :simulation_completed)
      }
    end)
    
    %{
      rfc_id: rfc_id,
      proposal_count: length(proposal_ids),
      proposals: stats
    }
  end

  @doc """
  Get activity timeline across all proposals.
  """
  @spec global_activity_timeline() :: [map()]
  def global_activity_timeline() do
    all_events = ProposalLedger.get_all_events()
    
    all_events
    |> Enum.group_by(&DateTime.to_date(&1.timestamp))
    |> Enum.map(fn {date, events} ->
      %{
        date: date,
        event_count: length(events),
        event_types: events |> Enum.map(& &1.type) |> Enum.uniq()
      }
    end)
    |> Enum.sort_by(& &1.date)
  end

  # === Private Functions ===

  defp replay_events(events) do
    Enum.reduce(events, %{}, fn event, acc ->
      apply_event(acc, event)
    end)
  end

  defp apply_event(state, %{type: :proposal_created, data: data}) do
    Map.merge(state, %{
      proposal_id: data.proposal_id,
      rfc_id: data.rfc_id,
      status: :draft,
      version: 1
    })
  end

  defp apply_event(state, %{type: :status_changed, data: data}) do
    Map.put(state, :status, data.new_status)
  end

  defp apply_event(state, _event) do
    state
  end

  defp summarize_event(%{type: :proposal_created}), do: "Proposal created"
  defp summarize_event(%{type: :status_changed, data: data}), do: "Status changed: #{data.old_status} → #{data.new_status}"
  defp summarize_event(%{type: :review_added}), do: "Review added"
  defp summarize_event(%{type: :simulation_completed}), do: "Simulation completed"
  defp summarize_event(%{type: :ratification_completed}), do: "Ratification completed"
  defp summarize_event(%{type: :migration_plan_created}), do: "Migration plan created"
  defp summarize_event(%{type: :execution_started}), do: "Execution started"
  defp summarize_event(%{type: :execution_completed}), do: "Execution completed"
  defp summarize_event(%{type: :certification_completed}), do: "Certification completed"
  defp summarize_event(%{type: :proposal_superseded}), do: "Proposal superseded"
  defp summarize_event(%{type: :proposal_archived}), do: "Proposal archived"
  defp summarize_event(_), do: "Unknown event"

  defp get_current_status(events) do
    case Enum.reverse(events) |> Enum.find(&(&1.type == :status_changed)) do
      nil -> :draft
      event -> event.data.new_status
    end
  end

  defp count_events(events, type) do
    Enum.count(events, &(&1.type == type))
  end
end
