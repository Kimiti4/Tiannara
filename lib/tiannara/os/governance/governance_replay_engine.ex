defmodule TiannaraOS.Governance.GovernanceReplayEngine do
  @moduledoc """
  GovernanceReplayEngine - Deterministic reconstruction of governance state.

  Given a GovernanceLedger, seed configuration, and ConstitutionManifest,
  this engine reconstructs institutional state exactly as it existed at any
  point in time. This is INV-034 (Institution Replay).

  ## Replay Invariants

  INV-034: Institution Replay - State reconstructs exactly from ledger + seed
  INV-035: Authority Separation - Observatory never deploys, Deployment never ratifies

  ## Replay Modes

  - `:full` - Reconstruct complete state from genesis
  - `:incremental` - Apply events from specific sequence number
  - `:point_in_time` - Reconstruct state at specific timestamp
  - `:verification` - Compare replay against captured state

  ## API

      @spec replay_full() :: {:ok, GovernanceState.t()} | {:error, term()}
      @spec replay_at_timestamp(DateTime.t()) :: {:ok, GovernanceState.t()} | {:error, term()}
      @spec verify_replay(GovernanceState.t(), GovernanceState.t()) :: :match | {:mismatch, map()}
  """

  alias TiannaraOS.Governance.GovernanceLedger
  alias TiannaraOS.Governance.GovernanceState

  @doc """
  Perform full replay from genesis to current state.

  Replays all events in sequence order to reconstruct current governance state.
  """
  @spec replay_full() :: {:ok, GovernanceState.t()} | {:error, term()}
  def replay_full() do
    events = GovernanceLedger.get_events()

    if Enum.empty?(events) do
      {:error, :no_events_to_replay}
    else
      state = GovernanceState.from_ledger(events)
      {:ok, state}
    end
  end

  @doc """
  Replay events up to a specific timestamp.

  Useful for historical analysis and archaeology.
  """
  @spec replay_at_timestamp(DateTime.t()) :: {:ok, GovernanceState.t()} | {:error, term()}
  def replay_at_timestamp(%DateTime{} = target_time) do
    events = GovernanceLedger.get_events()

    filtered = Enum.filter(events, fn event ->
      DateTime.compare(event.timestamp, target_time) != :gt
    end)

    if Enum.empty?(filtered) do
      {:error, :no_events_before_timestamp}
    else
      state = GovernanceState.from_ledger(filtered)
      {:ok, %{state | metadata: Map.put(state.metadata, :replay_mode, :point_in_time)}}
    end
  end

  @doc """
  Replay events from a specific sequence number.

  Useful for incremental state updates.
  """
  @spec replay_from_sequence(non_neg_integer()) :: {:ok, GovernanceState.t()} | {:error, term()}
  def replay_from_sequence(from_seq) when is_integer(from_seq) and from_seq > 0 do
    events = GovernanceLedger.get_events()

    filtered = Enum.filter(events, fn event ->
      event.sequence_number >= from_seq
    end)

    if Enum.empty?(filtered) do
      {:error, :no_events_from_sequence}
    else
      # First need base state before from_seq
      base_events = Enum.filter(events, fn event ->
        event.sequence_number < from_seq
      end)

      base_state =
        if Enum.empty?(base_events) do
          initial_state()
        else
          GovernanceState.from_ledger(base_events)
        end

      # Apply incremental events
      incremental_state = apply_incremental_events(base_state, filtered)
      {:ok, %{incremental_state | metadata: Map.put(incremental_state.metadata, :replay_mode, :incremental)}}
    end
  end

  @doc """
  Verify that replay matches a previously captured state.

  This is the determinism check - replay should produce identical state.
  """
  @spec verify_replay(GovernanceState.t(), GovernanceState.t()) :: :match | {:mismatch, map()}
  def verify_replay(%GovernanceState{} = expected, %GovernanceState{} = actual) do
    mismatches = []

    # Check institutions match
    mismatches =
      if expected.institutions == actual.institutions do
        mismatches
      else
        mismatches ++ [:institutions]
      end

    # Check appointments match
    mismatches =
      if expected.appointments == actual.appointments do
        mismatches
      else
        mismatches ++ [:appointments]
      end

    # Check roles match
    mismatches =
      if expected.roles == actual.roles do
        mismatches
      else
        mismatches ++ [:roles]
      end

    # Check fitness within tolerance
    fitness_delta = abs(expected.fitness - actual.fitness)
    mismatches =
      if fitness_delta < 0.001 do
        mismatches
      else
        mismatches ++ [:fitness]
      end

    # Check entropy within tolerance
    entropy_delta = abs(expected.entropy - actual.entropy)
    mismatches =
      if entropy_delta < 0.001 do
        mismatches
      else
        mismatches ++ [:entropy]
      end

    if Enum.empty?(mismatches) do
      :match
    else
      {:mismatch, %{
        mismatched_fields: mismatches,
        expected: summarize_state(expected),
        actual: summarize_state(actual)
      }}
    end
  end

  @doc """
  Verify authority separation invariants (INV-035).

  Checks that:
  - Observatory may never deploy
  - Deployment Authority may never ratify
  - Review Board may never appoint
  """
  @spec verify_authority_separation(GovernanceState.t()) :: :valid | {:violation, list()}
  def verify_authority_separation(%GovernanceState{} = state) do
    _violations = []

    # Check Observatory has no deployment capability
    observatory_violations = check_institution_capability(
      state,
      "observatory-001",
      :can_deploy,
      "Observatory must not have :can_deploy capability"
    )

    # Check Deployment Authority has no ratification capability
    deployment_violations = check_institution_capability(
      state,
      "deploy-auth-001",
      :can_ratify,
      "Deployment Authority must not have :can_ratify capability"
    )

    # Check Review Board has no appointment capability
    review_violations = check_institution_capability(
      state,
      "review-board-001",
      :can_appoint_institutional_members,
      "Review Board must not have :can_appoint_institutional_members capability"
    )

    violations = observatory_violations ++ deployment_violations ++ review_violations

    if Enum.empty?(violations) do
      :valid
    else
      {:violation, violations}
    end
  end

  @doc """
  Get replay statistics.
  """
  @spec get_replay_stats() :: map()
  def get_replay_stats() do
    events = GovernanceLedger.get_events()

    %{
      total_events: length(events),
      first_event: List.first(events),
      last_event: List.last(events),
      event_types: count_event_types(events),
      institutions_involved: extract_institutions(events),
      appointments_involved: extract_appointments(events)
    }
  end

  @doc """
  Export replay log for audit trail.
  """
  @spec export_replay_log() :: [map()]
  def export_replay_log() do
    events = GovernanceLedger.get_events()

    Enum.map(events, fn event ->
      %{
        sequence_number: event.sequence_number,
        event_id: event.event_id,
        event_type: event.event_type,
        timestamp: DateTime.to_iso8601(event.timestamp),
        data_summary: summarize_event_data(event.data),
        hash: event.current_hash
      }
    end)
  end

  # Private helpers

  defp initial_state() do
    %GovernanceState{
      timestamp: DateTime.utc_now(),
      institutions: %{},
      roles: %{},
      appointments: %{},
      capabilities: %{},
      active_proposals: 0,
      pending_reviews: 0,
      pending_deployments: 0,
      pending_rollbacks: 0,
      budget: %{},
      fitness: 0.0,
      entropy: 0.0,
      health: 0.0,
      metadata: %{source: "initial_state"}
    }
  end

  defp apply_incremental_events(_base_state, events) do
    # For now, delegate to GovernanceState.from_ledger/1
    # In production, this would apply events incrementally on top of base_state
    GovernanceState.from_ledger(events)
  end

  defp check_institution_capability(state, institution_id, forbidden_capability, violation_message) do
    case GovernanceState.get_institution(state, institution_id) do
      nil -> []
      institution ->
        capabilities = Map.get(institution, :capabilities, [])

        if forbidden_capability in capabilities do
          [%{
            institution_id: institution_id,
            violation: violation_message,
            forbidden_capability: forbidden_capability
          }]
        else
          []
        end
    end
  end

  defp count_event_types(events) do
    events
    |> Enum.group_by(fn e -> e.event_type end)
    |> Enum.map(fn {type, list} -> {type, length(list)} end)
    |> Enum.into(%{})
  end

  defp extract_institutions(events) do
    events
    |> Enum.flat_map(fn e ->
      case e.data do
        %{institution_id: id} -> [id]
        _ -> []
      end
    end)
    |> Enum.uniq()
  end

  defp extract_appointments(events) do
    events
    |> Enum.flat_map(fn e ->
      case e.data do
        %{appointment_id: id} -> [id]
        _ -> []
      end
    end)
    |> Enum.uniq()
  end

  defp summarize_state(state) do
    %{
      institutions: map_size(state.institutions),
      appointments: map_size(state.appointments),
      roles: map_size(state.roles),
      fitness: state.fitness,
      entropy: state.entropy,
      health: state.health
    }
  end

  defp summarize_event_data(data) do
    data
    |> Map.take([:institution_id, :appointment_id, :member_id, :role_id])
    |> Enum.filter(fn {_k, v} -> v != nil end)
    |> Enum.into(%{})
  end
end
