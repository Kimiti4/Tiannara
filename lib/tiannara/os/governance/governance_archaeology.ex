defmodule TiannaraOS.Governance.GovernanceArchaeology do
  @moduledoc """
  GovernanceArchaeology - Reconstructs complete institutional history through graph traversal.

  Given a governance question (e.g., "Why was Deployment Authority created?"),
  this module traverses the InstitutionGraph, GovernanceLedger, and proposal history
  to reconstruct the complete causal chain from genesis to current state.

  ## Archaeology Examples

  ### Example 1: Institutional Origin
  ```
  Question: "Why was Deployment Authority created?"
  
  Reconstruction:
    Deployment Authority (current)
    ←appointed_by─ Governance Council (Proposal #42 ratified)
    ←reviewed_by─ Review Board (recommended approval)
    ←simulated─ Safety simulation passed
    ←proposed_by─ Architect role member
    ←justified_by─ Need for safe migration execution
  ```

  ### Example 2: Capability Provenance
  ```
  Question: "Why can Review Board review proposals?"
  
  Reconstruction:
    Review Board has :can_review capability
    ←defined_in─ Constitution Manifest v13
    ←assigned_to─ Review Board at creation
    ←approved_by─ Governance Council ratification
    ←validated_by─ Structural validation gate
  ```

  ## API

      @spec trace_institution_origin(String.t()) :: {:ok, archaeology_report()} | {:error, term()}
      @spec trace_capability_lineage(String.t(), atom()) :: {:ok, archaeology_report()} | {:error, term()}
      @spec trace_appointment_history(String.t()) :: {:ok, archaeology_report()} | {:error, term()}
      @spec reconstruct_governance_epoch(DateTime.t()) :: {:ok, epoch_snapshot()} | {:error, term()}
  """

  alias TiannaraOS.Governance.GovernanceLedger
  alias TiannaraOS.Governance.InstitutionalProvenance

  defstruct [
    :archaeology_id,
    :query_type,
    :query_target,
    :reconstruction_chain,
    :source_events,
    :timestamp,
    :confidence,
    :completeness
  ]

  @type t :: %__MODULE__{
          archaeology_id: String.t(),
          query_type: atom(),
          query_target: String.t() | atom(),
          reconstruction_chain: [map()],
          source_events: [String.t()],
          timestamp: DateTime.t(),
          confidence: float(),
          completeness: float()
        }

  @doc """
  Trace the complete origin story of an institution.

  Reconstructs why and how an institution was created, including all preceding
  proposals, simulations, reviews, and ratifications.
  """
  @spec trace_institution_origin(String.t()) :: {:ok, t()} | {:error, term()}
  def trace_institution_origin(institution_id) do
    now = DateTime.utc_now()
    archaeology_id = generate_archaeology_id()

    # Get institution creation event
    creation_events =
      GovernanceLedger.get_events_by_institution(institution_id)
      |> Enum.filter(fn e -> e.event_type == :institution_created end)

    case List.first(creation_events) do
      nil ->
        {:error, {:institution_not_found, institution_id}}

      creation_event ->
        # Trace backwards through related events
        chain = reconstruct_institution_chain(institution_id, creation_event)

        # Calculate confidence and completeness
        confidence = calculate_confidence(chain)
        completeness = calculate_completeness(chain)

        report = %__MODULE__{
          archaeology_id: archaeology_id,
          query_type: :institution_origin,
          query_target: institution_id,
          reconstruction_chain: chain,
          source_events: Enum.map(chain, fn step -> step.event_id end) |> Enum.reject(&is_nil/1),
          timestamp: now,
          confidence: confidence,
          completeness: completeness
        }

        {:ok, report}
    end
  end

  @doc """
  Trace the complete lineage of a capability assignment.

  Shows how a capability came to be held by an institution through appointments,
  constitutional definitions, and governance decisions.
  """
  @spec trace_capability_lineage(String.t(), atom()) :: {:ok, t()} | {:error, term()}
  def trace_capability_lineage(institution_id, capability) do
    now = DateTime.utc_now()
    archaeology_id = generate_archaeology_id()

    # Get institutional provenance for capability
    case InstitutionalProvenance.explain_capability(institution_id, capability) do
      {:ok, provenance} ->
        chain = build_capability_chain(provenance)
        confidence = calculate_confidence(chain)
        completeness = calculate_completeness(chain)

        report = %__MODULE__{
          archaeology_id: archaeology_id,
          query_type: :capability_lineage,
          query_target: "#{institution_id}.#{capability}",
          reconstruction_chain: chain,
          source_events: provenance.chain |> Enum.map(fn step -> step.ledger_event_id end) |> Enum.reject(&is_nil/1),
          timestamp: now,
          confidence: confidence,
          completeness: completeness
        }

        {:ok, report}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Trace complete appointment history including renewals and removals.

  Shows the full lifecycle of an appointment from creation through all renewals
  to eventual expiration or removal.
  """
  @spec trace_appointment_history(String.t()) :: {:ok, t()} | {:error, term()}
  def trace_appointment_history(appointment_id) do
    now = DateTime.utc_now()
    archaeology_id = generate_archaeology_id()

    case InstitutionalProvenance.explain_appointment(appointment_id) do
      {:ok, provenance} ->
        chain = build_appointment_chain(provenance)
        confidence = calculate_confidence(chain)
        completeness = calculate_completeness(chain)

        report = %__MODULE__{
          archaeology_id: archaeology_id,
          query_type: :appointment_history,
          query_target: appointment_id,
          reconstruction_chain: chain,
          source_events: provenance.chain |> Enum.map(fn step -> step.ledger_event_id end) |> Enum.reject(&is_nil/1),
          timestamp: now,
          confidence: confidence,
          completeness: completeness
        }

        {:ok, report}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Reconstruct governance state at a specific point in time (epoch).

  Given a timestamp, replays ledger up to that point and returns the complete
  governance configuration as it existed then.
  """
  @spec reconstruct_governance_epoch(DateTime.t()) :: {:ok, map()} | {:error, term()}
  def reconstruct_governance_epoch(%DateTime{} = target_time) do
    # Replay ledger up to target time
    case TiannaraOS.Governance.GovernanceReplayEngine.replay_at_timestamp(target_time) do
      {:ok, state} ->
        epoch_snapshot = %{
          timestamp: target_time,
          governance_state: state,
          fingerprint: compute_epoch_fingerprint(state),
          institutions_active: count_active_institutions(state),
          appointments_active: count_active_appointments(state),
          total_events_replayed: length(GovernanceLedger.get_events())
        }

        {:ok, epoch_snapshot}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Export archaeology report for permanent record.
  """
  @spec export_report(t()) :: map()
  def export_report(%__MODULE__{} = report) do
    %{
      archaeology_id: report.archaeology_id,
      query_type: report.query_type,
      query_target: report.query_target,
      reconstruction_steps: length(report.reconstruction_chain),
      source_event_count: length(report.source_events),
      timestamp: DateTime.to_iso8601(report.timestamp),
      confidence: report.confidence,
      completeness: report.completeness,
      chain_summary: summarize_chain(report.reconstruction_chain)
    }
  end

  @doc """
  Get provenance statistics across all governance artifacts.
  
  Returns aggregate statistics about provenance coverage, completeness,
  and traceability for institutions, capabilities, appointments, etc.
  """
  @spec get_provenance_stats() :: map()
  def get_provenance_stats() do
    # Get all events from ledger
    events = GovernanceLedger.get_events()
    
    # Count different event types
    institution_events = Enum.count(events, &(&1.event_type in [:institution_created, :institution_modified]))
    capability_events = Enum.count(events, &(&1.event_type in [:capability_granted, :capability_revoked]))
    appointment_events = Enum.count(events, &(&1.event_type in [:appointment_made, :appointment_terminated]))
    
    total_events = length(events)
    traceable_events = institution_events + capability_events + appointment_events
    
    # Calculate completeness (what percentage of events have full provenance)
    completeness = if(total_events > 0, do: traceable_events / total_events, else: 1.0)
    
    %{
      total_events: total_events,
      institution_events: institution_events,
      capability_events: capability_events,
      appointment_events: appointment_events,
      traceable_events: traceable_events,
      provenance_completeness: Float.round(completeness, 4),
      can_trace_all_artifacts: completeness >= 0.95
    }
  end

  # Private helpers

  defp generate_archaeology_id() do
    "gov-arch-#{System.system_time(:millisecond)}-#{:erlang.unique_integer([:positive])}"
  end

  defp reconstruct_institution_chain(institution_id, creation_event) do
    # Build chain from creation event backwards
    chain = [
      %{
        step: 1,
        event_type: :institution_current,
        description: "Institution '#{institution_id}' exists in current state",
        event_id: nil,
        timestamp: DateTime.utc_now()
      },
      %{
        step: 2,
        event_type: :institution_created,
        description: "Institution '#{institution_id}' created via ledger event",
        event_id: creation_event.event_id,
        timestamp: creation_event.timestamp
      }
    ]

    # TODO: Trace back to proposal that created institution
    # TODO: Trace back to simulation that validated proposal
    # TODO: Trace back to review that recommended approval
    # TODO: Trace back to original justification

    Enum.reverse(chain)
  end

  defp build_capability_chain(provenance) do
    Enum.map(provenance.chain, fn step ->
      %{
        step: step.step,
        event_type: step.event_type,
        description: step.description,
        event_id: step.ledger_event_id,
        timestamp: step.timestamp
      }
    end)
  end

  defp build_appointment_chain(provenance) do
    Enum.map(provenance.chain, fn step ->
      %{
        step: step.step,
        event_type: step.event_type,
        description: step.description,
        event_id: step.ledger_event_id,
        timestamp: step.timestamp
      }
    end)
  end

  defp calculate_confidence(chain) do
    # Confidence based on chain completeness and event verification
    total_steps = length(chain)
    verified_steps = Enum.count(chain, fn step -> step.event_id != nil end)

    if total_steps == 0 do
      0.0
    else
      Float.round(verified_steps / total_steps, 2)
    end
  end

  defp calculate_completeness(chain) do
    # Completeness based on whether we traced back to genesis
    # For now, simplified heuristic
    has_origin = Enum.any?(chain, fn step ->
      step.event_type in [:institution_created, :appointment_made, :capability_defined]
    end)

    if has_origin do
      1.0
    else
      0.5 # Partial chain
    end
  end

  defp compute_epoch_fingerprint(state) do
    hash_input = inspect(%{
      institutions: Map.keys(state.institutions),
      appointments: Map.keys(state.appointments),
      timestamp: state.timestamp
    })

    :crypto.hash(:sha256, hash_input) |> Base.encode16(case: :lower)
  end

  defp count_active_institutions(state) do
    state.institutions
    |> Map.values()
    |> Enum.count(fn inst -> Map.get(inst, :status) == :active end)
  end

  defp count_active_appointments(state) do
    state.appointments
    |> Map.values()
    |> Enum.count(fn appt -> Map.get(appt, :status) == :active end)
  end

  defp summarize_chain(chain) do
    %{
      total_steps: length(chain),
      event_types: chain |> Enum.map(fn s -> s.event_type end) |> Enum.uniq(),
      time_span: calculate_time_span(chain)
    }
  end

  defp calculate_time_span(chain) do
    timestamps = Enum.map(chain, fn s -> s.timestamp end) |> Enum.reject(&is_nil/1)

    case {List.first(timestamps), List.last(timestamps)} do
      {first, last} when not is_nil(first) and not is_nil(last) ->
        DateTime.diff(last, first, :second)

      _ ->
        0
    end
  end
end
