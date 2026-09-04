defmodule TiannaraOS.Governance.GovernanceLedger do
  @moduledoc """
  GovernanceLedger - Immutable append-only ledger for all governance events.

  This is the canonical source of truth for institutional state. Instead of
  maintaining mutable institutional records, the system reconstructs state
  deterministically from the ledger using replay.

  ## Conservation Laws

  INV-031: Institution Conservation - No institution disappears
  INV-032: Appointment Conservation - All appointments immutable
  INV-033: Capability Provenance - Every capability derives from appointment

  ## Event Types

  ### Institutional Events
  - `:institution_created` - New institution established
  - `:institution_merged` - Two institutions merged
  - `:institution_split` - Institution split into multiple
  - `:institution_retired` - Institution permanently retired
  - `:institution_updated` - Institution metadata updated

  ### Role Events
  - `:role_granted` - Role assigned to member
  - `:role_revoked` - Role removed from member
  - `:role_updated` - Role capabilities modified

  ### Appointment Events
  - `:appointment_made` - New appointment created
  - `:appointment_renewed` - Appointment term extended
  - `:appointment_expired` - Appointment term ended naturally
  - `:appointment_removed` - Appointment terminated early

  ### Capability Events
  - `:capability_granted` - New capability added to role/institution
  - `:capability_revoked` - Capability removed from role/institution
  - `:capability_graph_updated` - Capability graph structure changed

  ## API

      @spec append_event(event_type(), map()) :: {:ok, event()} | {:error, term()}
      @spec get_events() :: [event()]
      @spec get_events_by_type(event_type()) :: [event()]
      @spec get_events_by_institution(String.t()) :: [event()]
      @spec reconstruct_state() :: GovernanceState.t()
  """

  defstruct [
    :event_id,
    :event_type,
    :timestamp,
    :data,
    :provenance,
    :sequence_number,
    :previous_hash,
    :current_hash
  ]

  @type t :: %__MODULE__{
          event_id: String.t(),
          event_type: event_type(),
          timestamp: DateTime.t(),
          data: map(),
          provenance: map(),
          sequence_number: non_neg_integer(),
          previous_hash: String.t() | nil,
          current_hash: String.t()
        }

  @type event_type ::
          # Institutional events
          :institution_created |
          :institution_merged |
          :institution_split |
          :institution_retired |
          :institution_updated |
          # Role events
          :role_granted |
          :role_revoked |
          :role_updated |
          # Appointment events
          :appointment_made |
          :appointment_renewed |
          :appointment_expired |
          :appointment_removed |
          # Capability events
          :capability_granted |
          :capability_revoked |
          :capability_graph_updated

  # Agent-based ledger storage (will be replaced with persistent storage in production)
  use GenServer

  @doc """
  Start the GovernanceLedger GenServer.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Append a new event to the ledger.

  This is the ONLY way to modify governance state. All state changes flow through
  the ledger, ensuring immutability and replayability.

  ## Example

      GovernanceLedger.append_event(:institution_created, %{
        institution_id: "inst_governance_council",
        name: "Governance Council",
        domains: [:replay, :ledger, :science],
        capabilities: [:can_ratify, :can_appoint]
      })
  """
  @spec append_event(event_type(), map()) :: {:ok, t()} | {:error, term()}
  def append_event(event_type, data) when is_atom(event_type) and is_map(data) do
    GenServer.call(__MODULE__, {:append_event, event_type, data})
  end

  @doc """
  Get all events in the ledger (ordered by sequence number).
  """
  @spec get_events() :: [t()]
  def get_events() do
    GenServer.call(__MODULE__, :get_events)
  end

  @doc """
  Get all ledger events (alias for get_events/0).
  """
  @spec get_all_events() :: [t()]
  def get_all_events() do
    get_events()
  end

  @doc """
  Get events filtered by type.
  """
  @spec get_events_by_type(event_type()) :: [t()]
  def get_events_by_type(event_type) do
    GenServer.call(__MODULE__, {:get_events_by_type, event_type})
  end

  @doc """
  Get events related to a specific institution.
  """
  @spec get_events_by_institution(String.t()) :: [t()]
  def get_events_by_institution(institution_id) do
    GenServer.call(__MODULE__, {:get_events_by_institution, institution_id})
  end

  @doc """
  Get events related to a specific appointment.
  """
  @spec get_events_by_appointment(String.t()) :: [t()]
  def get_events_by_appointment(appointment_id) do
    GenServer.call(__MODULE__, {:get_events_by_appointment, appointment_id})
  end

  @doc """
  Reconstruct current governance state from ledger.

  This is the deterministic replay function that rebuilds institutional state
  from the complete event history.
  """
  @spec reconstruct_state() :: map()
  def reconstruct_state() do
    GenServer.call(__MODULE__, :reconstruct_state)
  end

  @doc """
  Get ledger statistics.
  """
  @spec get_stats() :: map()
  def get_stats() do
    GenServer.call(__MODULE__, :get_stats)
  end

  @doc """
  Verify ledger integrity (hash chain validation).
  """
  @spec verify_integrity() :: :valid | {:invalid, String.t()}
  def verify_integrity() do
    GenServer.call(__MODULE__, :verify_integrity)
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    state = %{
      events: [],
      sequence_counter: 0,
      last_hash: nil
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:append_event, event_type, data}, _from, state) do
    now = DateTime.utc_now()
    sequence = state.sequence_counter + 1
    previous_hash = state.last_hash

    event = %__MODULE__{
      event_id: generate_event_id(sequence),
      event_type: event_type,
      timestamp: now,
      data: data,
      provenance: build_provenance(event_type, data),
      sequence_number: sequence,
      previous_hash: previous_hash,
      current_hash: compute_hash(sequence, event_type, data, previous_hash, now)
    }

    new_state = %{
      state
      | events: state.events ++ [event],
        sequence_counter: sequence,
        last_hash: event.current_hash
    }

    {:reply, {:ok, event}, new_state}
  end

  @impl true
  def handle_call(:get_events, _from, state) do
    {:reply, state.events, state}
  end

  @impl true
  def handle_call({:get_events_by_type, event_type}, _from, state) do
    filtered = Enum.filter(state.events, fn e -> e.event_type == event_type end)
    {:reply, filtered, state}
  end

  @impl true
  def handle_call({:get_events_by_institution, institution_id}, _from, state) do
    filtered = Enum.filter(state.events, fn e ->
      case e.data do
        %{institution_id: ^institution_id} -> true
        %{institution_id: inst_id} when inst_id == institution_id -> true
        _ -> false
      end
    end)

    {:reply, filtered, state}
  end

  @impl true
  def handle_call({:get_events_by_appointment, appointment_id}, _from, state) do
    filtered = Enum.filter(state.events, fn e ->
      case e.data do
        %{appointment_id: ^appointment_id} -> true
        %{appointment_id: appt_id} when appt_id == appointment_id -> true
        _ -> false
      end
    end)

    {:reply, filtered, state}
  end

  @impl true
  def handle_call(:reconstruct_state, _from, state) do
    reconstructed = replay_events(state.events)
    {:reply, reconstructed, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_events: length(state.events),
      sequence_number: state.sequence_counter,
      event_types: count_event_types(state.events),
      institutions: extract_unique_institutions(state.events),
      appointments: extract_unique_appointments(state.events)
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_call(:verify_integrity, _from, state) do
    case verify_hash_chain(state.events) do
      :valid -> {:reply, :valid, state}
      {:invalid, reason} -> {:reply, {:invalid, reason}, state}
    end
  end

  # Private helpers

  defp generate_event_id(sequence) do
    "gov-event-#{String.pad_leading(Integer.to_string(sequence), 6, "0")}-#{System.system_time(:millisecond)}"
  end

  defp build_provenance(event_type, data) do
    %{
      event_type: event_type,
      created_at: DateTime.utc_now(),
      data_keys: Map.keys(data),
      # TODO: Add actor_id, institution_id, proposal_id context when available
      metadata: %{
        system_version: "14.0.5",
        phase: "Phase 14.0.75 - Governance Observability Freeze"
      }
    }
  end

  defp compute_hash(sequence, event_type, data, previous_hash, timestamp) do
    hash_input = "#{sequence}:#{event_type}:#{inspect(data)}:#{previous_hash}:#{timestamp}"
    :crypto.hash(:sha256, hash_input) |> Base.encode16(case: :lower)
  end

  defp replay_events(events) do
    # Fold over all events to reconstruct current state
    initial_state = %{
      institutions: %{},
      roles: %{},
      appointments: %{},
      capabilities: %{},
      active_members: %{}
    }

    Enum.reduce(events, initial_state, fn event, acc ->
      apply_event(event, acc)
    end)
  end

  defp apply_event(%__MODULE__{event_type: :institution_created, data: data}, acc) do
    institution_id = data.institution_id
    institution = %{
      id: institution_id,
      name: data.name,
      domains: data.domains || [],
      capabilities: data.capabilities || [],
      status: :active,
      created_at: data.timestamp
    }

    put_in(acc, [:institutions, institution_id], institution)
  end

  defp apply_event(%__MODULE__{event_type: :institution_updated, data: data}, acc) do
    institution_id = data.institution_id

    case get_in(acc, [:institutions, institution_id]) do
      nil -> acc
      institution ->
        updated = Map.merge(institution, data.updates)
        put_in(acc, [:institutions, institution_id], updated)
    end
  end

  defp apply_event(%__MODULE__{event_type: :institution_retired, data: data}, acc) do
    institution_id = data.institution_id

    case get_in(acc, [:institutions, institution_id]) do
      nil -> acc
      institution ->
        updated = %{institution | status: :retired}
        put_in(acc, [:institutions, institution_id], updated)
    end
  end

  defp apply_event(%__MODULE__{event_type: :appointment_made, data: data}, acc) do
    appointment_id = data.appointment_id

    appointment = %{
      id: appointment_id,
      member_id: data.member_id,
      institution_id: data.institution_id,
      role_id: data.role_id,
      status: :active,
      term_start: data.term_start,
      term_end: data.term_end,
      appointed_by: data.appointed_by
    }

    acc
    |> put_in([:appointments, appointment_id], appointment)
    |> update_active_member(data.member_id, data.institution_id, :add)
  end

  defp apply_event(%__MODULE__{event_type: :appointment_renewed, data: data}, acc) do
    appointment_id = data.appointment_id

    case get_in(acc, [:appointments, appointment_id]) do
      nil -> acc
      appointment ->
        updated = %{
          appointment
          | term_start: data.new_term_start,
            term_end: data.new_term_end,
            status: :active
        }

        put_in(acc, [:appointments, appointment_id], updated)
    end
  end

  defp apply_event(%__MODULE__{event_type: :appointment_expired, data: data}, acc) do
    appointment_id = data.appointment_id

    case get_in(acc, [:appointments, appointment_id]) do
      nil -> acc
      appointment ->
        updated = %{appointment | status: :expired}
        acc
        |> put_in([:appointments, appointment_id], updated)
        |> update_active_member(appointment.member_id, appointment.institution_id, :remove)
    end
  end

  defp apply_event(%__MODULE__{event_type: :appointment_removed, data: data}, acc) do
    appointment_id = data.appointment_id

    case get_in(acc, [:appointments, appointment_id]) do
      nil -> acc
      appointment ->
        updated = %{appointment | status: :removed, removal_reason: data.reason}
        acc
        |> put_in([:appointments, appointment_id], updated)
        |> update_active_member(appointment.member_id, appointment.institution_id, :remove)
    end
  end

  defp apply_event(%__MODULE__{event_type: :role_granted, data: data}, acc) do
    member_id = data.member_id
    role_id = data.role_id

    acc
    |> update_in([:roles, member_id], fn
      nil -> [role_id]
      roles -> Enum.uniq(roles ++ [role_id])
    end)
  end

  defp apply_event(%__MODULE__{event_type: :role_revoked, data: data}, acc) do
    member_id = data.member_id
    role_id = data.role_id

    update_in(acc, [:roles, member_id], fn
      nil -> []
      roles -> List.delete(roles, role_id)
    end)
  end

  defp apply_event(_event, acc), do: acc

  defp update_active_member(acc, member_id, institution_id, action) do
    update_in(acc, [:active_members, member_id], fn
      nil ->
        case action do
          :add -> [institution_id]
          :remove -> []
        end

      institutions ->
        case action do
          :add -> Enum.uniq(institutions ++ [institution_id])
          :remove -> List.delete(institutions, institution_id)
        end
    end)
  end

  defp count_event_types(events) do
    events
    |> Enum.group_by(fn e -> e.event_type end)
    |> Enum.map(fn {type, list} -> {type, length(list)} end)
    |> Enum.into(%{})
  end

  defp extract_unique_institutions(events) do
    events
    |> Enum.flat_map(fn e ->
      case e.data do
        %{institution_id: id} -> [id]
        _ -> []
      end
    end)
    |> Enum.uniq()
    |> length()
  end

  defp extract_unique_appointments(events) do
    events
    |> Enum.flat_map(fn e ->
      case e.data do
        %{appointment_id: id} -> [id]
        _ -> []
      end
    end)
    |> Enum.uniq()
    |> length()
  end

  defp verify_hash_chain([]), do: :valid

  defp verify_hash_chain([first | rest]) do
    # First event should have nil previous_hash
    if first.previous_hash != nil do
      {:invalid, "First event has non-nil previous_hash"}
    else
      verify_chain(rest, first)
    end
  end

  defp verify_chain([], _prev), do: :valid

  defp verify_chain([current | rest], prev) do
    expected_previous = prev.current_hash

    if current.previous_hash == expected_previous do
      verify_chain(rest, current)
    else
      {:invalid, "Hash chain broken at sequence #{current.sequence_number}"}
    end
  end
end
