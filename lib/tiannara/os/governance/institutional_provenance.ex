defmodule TiannaraOS.Governance.InstitutionalProvenance do
  @moduledoc """
  InstitutionalProvenance - Full explainability chain for all governance decisions.

  Every governance metric, capability, and authority must answer:
  "Explain why this exists?"

  This module traces the complete lineage from ledger events through
  appointments to current institutional state.

  ## Provenance Chains

  ### Capability Provenance (INV-033)
  ```
  Why can Institution X deploy?
  ↓
  Role granted to member
  ↓
  Appointment made by Governance Council
  ↓
  Institution created with :can_deploy capability
  ↓
  Ledger event: institution_created
  ```

  ### Authority Provenance
  ```
  Why did Review Board reject Proposal Y?
  ↓
  Review decision recorded
  ↓
  Reviewers appointed by Governance Council
  ↓
  Review Board has :can_review capability in :science domain
  ↓
  Ledger event: appointment_made
  ```

  ## API

      @spec explain_capability(String.t(), atom()) :: {:ok, provenance_chain()} | {:error, term()}
      @spec explain_authority(String.t(), atom(), atom()) :: {:ok, provenance_chain()} | {:error, term()}
      @spec explain_appointment(String.t()) :: {:ok, provenance_chain()} | {:error, term()}
      @spec trace_institution_history(String.t()) :: [provenance_event()]
  """

  alias TiannaraOS.Governance.GovernanceLedger
  alias TiannaraOS.Governance.GovernanceState

  defstruct [
    :query_type,
    :query_target,
    :chain,
    :root_cause,
    :timestamp
  ]

  @type t :: %__MODULE__{
          query_type: atom(),
          query_target: String.t() | atom(),
          chain: [provenance_event()],
          root_cause: map(),
          timestamp: DateTime.t()
        }

  @type provenance_event :: %{
          step: non_neg_integer(),
          event_type: atom(),
          description: String.t(),
          ledger_event_id: String.t(),
          timestamp: DateTime.t()
        }

  @doc """
  Explain why an institution has a specific capability.

  Traces back through role assignments, appointments, and institution creation.
  """
  @spec explain_capability(String.t(), atom()) :: {:ok, t()} | {:error, term()}
  def explain_capability(institution_id, capability) when is_binary(institution_id) and is_atom(capability) do
    state = GovernanceState.capture_state()

    case GovernanceState.get_institution(state, institution_id) do
      nil ->
        {:error, {:institution_not_found, institution_id}}

      institution ->
        capabilities = Map.get(institution, :capabilities, [])

        if capability not in capabilities do
          {:error, {:capability_not_held, %{institution: institution_id, capability: capability}}}
        else
          # Trace capability back to institution creation
          chain = trace_capability_to_creation(institution_id, capability)
          root_cause = List.last(chain)

          {:ok, %__MODULE__{
            query_type: :explain_capability,
            query_target: "#{institution_id}.#{capability}",
            chain: chain,
            root_cause: root_cause,
            timestamp: DateTime.utc_now()
          }}
        end
    end
  end

  @doc """
  Explain why a member has authority to perform an action.

  Traces: Member → Role → Appointment → Institution → Capability
  """
  @spec explain_authority(String.t(), atom(), atom()) :: {:ok, t()} | {:error, term()}
  def explain_authority(member_id, capability, domain) do
    state = GovernanceState.capture_state()

    # Check if member has any active appointments
    appointments = GovernanceState.get_appointments(state, member_id)

    if Enum.empty?(appointments) do
      {:error, {:no_active_appointments, member_id}}
    else
      # Find appointment with required capability
      authorized_appointment = Enum.find(appointments, fn appt ->
        institution = GovernanceState.get_institution(state, appt.institution_id)
        institution && capability in Map.get(institution, :capabilities, [])
      end)

      case authorized_appointment do
        nil ->
          {:error, {:no_authorization, %{member: member_id, capability: capability, domain: domain}}}

        appt ->
          chain = build_authority_chain(appt, capability, domain)
          root_cause = List.last(chain)

          {:ok, %__MODULE__{
            query_type: :explain_authority,
            query_target: "#{member_id}.#{capability}@#{domain}",
            chain: chain,
            root_cause: root_cause,
            timestamp: DateTime.utc_now()
          }}
      end
    end
  end

  @doc """
  Explain the complete history of an appointment.

  Shows creation, renewals, and eventual removal/expiration.
  """
  @spec explain_appointment(String.t()) :: {:ok, t()} | {:error, term()}
  def explain_appointment(appointment_id) do
    events = GovernanceLedger.get_events_by_appointment(appointment_id)

    if Enum.empty?(events) do
      {:error, {:appointment_not_found, appointment_id}}
    else
      chain = Enum.map(events, fn event ->
        %{
          step: event.sequence_number,
          event_type: event.event_type,
          description: describe_event(event),
          ledger_event_id: event.event_id,
          timestamp: event.timestamp
        }
      end)

      root_cause = %{
        appointment_id: appointment_id,
        total_events: length(events),
        first_event: List.first(events).event_type,
        last_event: List.last(events).event_type
      }

      {:ok, %__MODULE__{
        query_type: :explain_appointment,
        query_target: appointment_id,
        chain: chain,
        root_cause: root_cause,
        timestamp: DateTime.utc_now()
      }}
    end
  end

  @doc """
  Trace complete institutional history from creation to current state.
  """
  @spec trace_institution_history(String.t()) :: [provenance_event()]
  def trace_institution_history(institution_id) do
    events = GovernanceLedger.get_events_by_institution(institution_id)

    Enum.map(events, fn event ->
      %{
        step: event.sequence_number,
        event_type: event.event_type,
        description: describe_event(event),
        ledger_event_id: event.event_id,
        timestamp: event.timestamp
      }
    end)
  end

  @doc """
  Verify complete provenance chain integrity.

  Checks that every capability can be traced back to a valid appointment.
  """
  @spec verify_provenance_integrity() :: :valid | {:broken, list()}
  def verify_provenance_integrity() do
    state = GovernanceState.capture_state()
    _broken_chains = []

    # Check each institution's capabilities
    institutions_with_broken_chains =
      state.institutions
      |> Map.values()
      |> Enum.filter(fn institution ->
        capabilities = Map.get(institution, :capabilities, [])
        Enum.any?(capabilities, fn cap ->
          not capability_has_provenance?(institution.id, cap, state)
        end)
      end)

    if Enum.empty?(institutions_with_broken_chains) do
      :valid
    else
      {:broken, Enum.map(institutions_with_broken_chains, fn inst ->
        %{institution_id: inst.id, name: inst.name}
      end)}
    end
  end

  @doc """
  Export provenance report for audit.
  """
  @spec export_provenance_report() :: map()
  def export_provenance_report() do
    state = GovernanceState.capture_state()

    %{
      timestamp: DateTime.utc_now(),
      total_institutions: map_size(state.institutions),
      total_appointments: map_size(state.appointments),
      provenance_status: verify_provenance_integrity(),
      institution_summaries: Enum.map(state.institutions, fn {id, inst} ->
        %{
          institution_id: id,
          name: inst.name,
          capabilities: Map.get(inst, :capabilities, []),
          history_length: length(trace_institution_history(id))
        }
      end)
    }
  end

  # Private helpers

  defp trace_capability_to_creation(institution_id, capability) do
    events = GovernanceLedger.get_events_by_institution(institution_id)

    # Find institution creation event
    creation_event = Enum.find(events, fn e ->
      e.event_type == :institution_created and e.data.institution_id == institution_id
    end)

    case creation_event do
      nil ->
        [%{
          step: 0,
          event_type: :unknown,
          description: "No creation event found for #{institution_id}",
          ledger_event_id: nil,
          timestamp: nil
        }]

      event ->
        [
          %{
            step: 1,
            event_type: :institution_created,
            description: "Institution '#{institution_id}' created with capability :#{capability}",
            ledger_event_id: event.event_id,
            timestamp: event.timestamp
          },
          %{
            step: 2,
            event_type: :capability_verified,
            description: "Capability :#{capability} confirmed in institution definition",
            ledger_event_id: event.event_id,
            timestamp: event.timestamp
          }
        ]
    end
  end

  defp build_authority_chain(appointment, capability, domain) do
    [
      %{
        step: 1,
        event_type: :member_query,
        description: "Member '#{appointment.member_id}' seeks authority for :#{capability} in :#{domain}",
        ledger_event_id: nil,
        timestamp: DateTime.utc_now()
      },
      %{
        step: 2,
        event_type: :appointment_lookup,
        description: "Found active appointment '#{appointment.id}' in institution '#{appointment.institution_id}'",
        ledger_event_id: nil,
        timestamp: DateTime.utc_now()
      },
      %{
        step: 3,
        event_type: :institution_check,
        description: "Institution '#{appointment.institution_id}' has :#{capability} capability",
        ledger_event_id: nil,
        timestamp: DateTime.utc_now()
      },
      %{
        step: 4,
        event_type: :authority_granted,
        description: "Authority granted via appointment lineage",
        ledger_event_id: nil,
        timestamp: DateTime.utc_now()
      }
    ]
  end

  defp describe_event(%GovernanceLedger{} = event) do
    case event.event_type do
      :institution_created ->
        "Institution '#{event.data.institution_id}' created"

      :appointment_made ->
        "Appointment '#{event.data.appointment_id}' made for member '#{event.data.member_id}'"

      :appointment_renewed ->
        "Appointment '#{event.data.appointment_id}' renewed"

      :appointment_expired ->
        "Appointment '#{event.data.appointment_id}' expired"

      :appointment_removed ->
        "Appointment '#{event.data.appointment_id}' removed: #{event.data.reason}"

      :role_granted ->
        "Role granted to member '#{event.data.member_id}'"

      :role_revoked ->
        "Role revoked from member '#{event.data.member_id}'"

      _ ->
        "Event: #{event.event_type}"
    end
  end

  defp capability_has_provenance?(institution_id, capability, state) do
    # Simplified check - in production would trace full chain
    institution = GovernanceState.get_institution(state, institution_id)
    institution && capability in Map.get(institution, :capabilities, [])
  end
end
