defmodule TiannaraOS.Governance.ProposalHistory do
  @moduledoc """
  ProposalHistory - Detailed change history explainer
  
  Provides granular explanation of every state change:
  - What changed (field-level diffs)
  - Why it changed (reason/justification)
  - Who authorized it (decision makers)
  - When it happened (precise timestamps)
  - Evidence supporting the change
  
  ## Owner
  Read-only historical analysis engine.
  
  ## Use Cases
  - Audit trails
  - Compliance reporting
  - Debugging unexpected states
  - Understanding decision rationale
  """

  alias TiannaraOS.Governance.ProposalLedger

  # === Public API ===

  @doc """
  Get complete change history for a proposal.
  """
  @spec get_change_history(String.t()) :: {:ok, [map()]} | {:error, String.t()}
  def get_change_history(proposal_id) do
    with {:ok, events} <- fetch_events(proposal_id) do
      history = Enum.map(events, fn event ->
        build_change_record(event)
      end)
      
      {:ok, history}
    end
  end

  @doc """
  Get field-level diff between two points in time.
  """
  @spec get_diff(String.t(), DateTime.t(), DateTime.t()) :: {:ok, map()} | {:error, String.t()}
  def get_diff(proposal_id, time1, time2) do
    with {:ok, state1} <- get_state_at_time(proposal_id, time1),
         {:ok, state2} <- get_state_at_time(proposal_id, time2) do
      
      diff = compute_diff(state1, state2)
      
      {:ok, %{
        proposal_id: proposal_id,
        time1: time1,
        time2: time2,
        state_before: state1,
        state_after: state2,
        changes: diff
      }}
    end
  end

  @doc """
  Explain a specific state transition.
  """
  @spec explain_transition(String.t(), atom(), atom()) :: {:ok, map()} | {:error, String.t()}
  def explain_transition(proposal_id, from_status, to_status) do
    with {:ok, events} <- fetch_events(proposal_id) do
      transition_event = Enum.find(events, fn event ->
        event.type == :status_changed &&
        event.data.old_status == from_status &&
        event.data.new_status == to_status
      end)
      
      case transition_event do
        nil ->
          {:error, "Transition #{from_status} → #{to_status} not found"}
        
        event ->
          {:ok, %{
            proposal_id: proposal_id,
            from: from_status,
            to: to_status,
            timestamp: event.timestamp,
            reason: event.data.reason,
            sequence: event.sequence,
            authorized_by: determine_authority(event),
            evidence: collect_transition_evidence(events, event.sequence)
          }}
      end
    end
  end

  @doc """
  Get all status transitions.
  """
  @spec get_transitions(String.t()) :: {:ok, [map()]} | {:error, String.t()}
  def get_transitions(proposal_id) do
    with {:ok, events} <- fetch_events(proposal_id) do
      transitions = events
        |> Enum.filter(&(&1.type == :status_changed))
        |> Enum.map(fn event ->
          %{
            sequence: event.sequence,
            timestamp: event.timestamp,
            from: event.data.old_status,
            to: event.data.new_status,
            reason: event.data.reason,
            duration_from_previous: nil  # Would calculate in production
          }
        end)
      
      {:ok, transitions}
    end
  end

  @doc """
  Get decision trail (who made what decisions).
  """
  @spec get_decision_trail(String.t()) :: {:ok, [map()]} | {:error, String.t()}
  def get_decision_trail(proposal_id) do
    with {:ok, events} <- fetch_events(proposal_id) do
      _decisions = []
      
      # Review decisions
      review_decisions = events
        |> Enum.filter(&(&1.type == :review_added))
        |> Enum.map(fn event ->
          %{
            type: :review_decision,
            timestamp: event.timestamp,
            decision_maker: event.data.reviewer_id,
            decision: event.data.decision,
            rationale: event.data.rationale
          }
        end)
      
      # Ratification decisions
      ratification_decisions = events
        |> Enum.filter(&(&1.type == :ratification_completed))
        |> Enum.map(fn event ->
          %{
            type: :ratification_decision,
            timestamp: event.timestamp,
            decision_makers: event.data.approving_institutions,
            threshold_met: event.data.threshold_met,
            voting_power: event.data.total_voting_power
          }
        end)
      
      {:ok, review_decisions ++ ratification_decisions}
    end
  end

  @doc """
  Get evidence chain for a proposal.
  """
  @spec get_evidence_chain(String.t()) :: {:ok, [map()]} | {:error, String.t()}
  def get_evidence_chain(proposal_id) do
    with {:ok, events} <- fetch_events(proposal_id) do
      _evidence = []
      
      # Simulation evidence
      sim_evidence = events
        |> Enum.filter(&(&1.type == :simulation_completed))
        |> Enum.map(fn event ->
          %{
            type: :simulation,
            id: event.data.simulation_id,
            scenario: event.data.scenario,
            result: if(event.data.passed, do: :passed, else: :failed),
            timestamp: event.timestamp,
            metrics: %{
              fitness_delta: event.data.fitness_delta,
              entropy_delta: event.data.entropy_delta
            }
          }
        end)
      
      # Review evidence
      review_evidence = events
        |> Enum.filter(&(&1.type == :review_added))
        |> Enum.map(fn event ->
          %{
            type: :review,
            id: event.data.review_id,
            decision: event.data.decision,
            reviewer: event.data.reviewer_id,
            rationale: event.data.rationale,
            timestamp: event.timestamp
          }
        end)
      
      # Certification evidence
      cert_evidence = events
        |> Enum.filter(&(&1.type == :certification_completed))
        |> Enum.map(fn event ->
          %{
            type: :certification,
            certificate_hash: event.data.certificate_hash,
            timestamp: event.timestamp
          }
        end)
      
      {:ok, sim_evidence ++ review_evidence ++ cert_evidence}
    end
  end

  @doc """
  Generate audit trail report.
  """
  @spec generate_audit_trail(String.t()) :: {:ok, map()} | {:error, String.t()}
  def generate_audit_trail(proposal_id) do
    with {:ok, history} <- get_change_history(proposal_id),
         {:ok, transitions} <- get_transitions(proposal_id),
         {:ok, decisions} <- get_decision_trail(proposal_id),
         {:ok, evidence} <- get_evidence_chain(proposal_id) do
      
      {:ok, %{
        proposal_id: proposal_id,
        generated_at: DateTime.utc_now(),
        total_events: length(history),
        total_transitions: length(transitions),
        total_decisions: length(decisions),
        total_evidence_items: length(evidence),
        change_history: history,
        transitions: transitions,
        decisions: decisions,
        evidence_chain: evidence
      }}
    end
  end

  # === Private Functions ===

  defp build_change_record(event) do
    %{
      sequence: event.sequence,
      timestamp: event.timestamp,
      event_type: event.type,
      description: describe_change(event),
      fields_changed: extract_changed_fields(event),
      metadata: extract_metadata(event)
    }
  end

  defp describe_change(%{type: :proposal_created}), do: "Proposal created"
  defp describe_change(%{type: :status_changed, data: data}), do: "Status changed from #{data.old_status} to #{data.new_status}"
  defp describe_change(%{type: :review_added, data: data}), do: "Review added with decision: #{data.decision}"
  defp describe_change(%{type: :simulation_completed, data: data}), do: "Simulation completed (#{data.scenario}): #{if data.passed, do: "PASSED", else: "FAILED"}"
  defp describe_change(%{type: :ratification_completed}), do: "Ratification completed"
  defp describe_change(%{type: :migration_plan_created}), do: "Migration plan created"
  defp describe_change(%{type: :execution_started}), do: "Execution started"
  defp describe_change(%{type: :execution_completed, data: data}), do: "Execution #{if data.success, do: "succeeded", else: "failed"}"
  defp describe_change(%{type: :certification_completed}), do: "Certification completed"
  defp describe_change(%{type: :proposal_superseded}), do: "Proposal superseded"
  defp describe_change(%{type: :proposal_archived}), do: "Proposal archived"
  defp describe_change(_), do: "Unknown change"

  defp extract_changed_fields(%{type: :proposal_created, data: data}) do
    Map.keys(data)
  end
  defp extract_changed_fields(%{type: :status_changed}), do: [:status]
  defp extract_changed_fields(%{type: :review_added}), do: [:review_records]
  defp extract_changed_fields(%{type: :simulation_completed}), do: [:simulation_results]
  defp extract_changed_fields(%{type: :ratification_completed}), do: [:ratification_record_id]
  defp extract_changed_fields(%{type: :migration_plan_created}), do: [:migration_plan_id]
  defp extract_changed_fields(%{type: :certification_completed}), do: [:certificate_hash]
  defp extract_changed_fields(_), do: []

  defp extract_metadata(event) do
    %{
      event_id: event.event_id,
      hash: event.hash
    }
  end

  defp get_state_at_time(proposal_id, timestamp) do
    events = ProposalLedger.get_proposal_events(proposal_id)
    
    historical_events = Enum.filter(events, fn event ->
      DateTime.compare(event.timestamp, timestamp) in [:lt, :eq]
    end)
    
    if Enum.empty?(historical_events) do
      {:error, "No events before #{timestamp}"}
    else
      state = replay_events(historical_events)
      {:ok, state}
    end
  end

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

  defp apply_event(state, _event), do: state

  defp compute_diff(state1, state2) do
    all_keys = Enum.uniq(Map.keys(state1) ++ Map.keys(state2))
    
    Enum.flat_map(all_keys, fn key ->
      val1 = Map.get(state1, key)
      val2 = Map.get(state2, key)
      
      if val1 != val2 do
        [%{field: key, before: val1, after: val2}]
      else
        []
      end
    end)
  end

  defp determine_authority(event) do
    case event.type do
      :status_changed -> :system
      :review_added -> event.data.reviewer_id
      :ratification_completed -> :institutions
      _ -> :unknown
    end
  end

  defp collect_transition_evidence(events, sequence) do
    events
    |> Enum.filter(&(&1.sequence < sequence))
    |> Enum.map(fn event ->
      %{event_type: event.type, sequence: event.sequence}
    end)
  end

  defp fetch_events(proposal_id) do
    events = ProposalLedger.get_proposal_events(proposal_id)
    
    if Enum.empty?(events) do
      {:error, "No events found for proposal #{proposal_id}"}
    else
      {:ok, events}
    end
  end
end
