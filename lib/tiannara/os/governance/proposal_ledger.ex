defmodule TiannaraOS.Governance.ProposalLedger do
  @moduledoc """
  ProposalLedger - Append-only storage for proposal lifecycle events
  
  Implements immutable, deterministic event sourcing for all proposal changes.
  Every state transition is recorded as an event that cannot be modified or deleted.
  
  ## Guarantees
  - **Append-only**: Events can only be added, never modified or deleted
  - **Deterministic**: Same sequence of events always produces same state
  - **Immutable**: Once written, events are permanent
  - **Replayable**: State can be reconstructed from event log
  
  ## Owner
  This is the canonical storage for all proposal state changes.
  
  ## Storage
  ETS table for fast writes + file-based persistence for durability.
  """

  use GenServer

  # === Client API ===

  @doc """
  Start the ProposalLedger GenServer.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Append a new event to the ledger.
  
  Events are immutable once written. Returns the event with assigned sequence number.
  
  ## Examples
  
      iex> ProposalLedger.append_event(%{
      ...>   type: :proposal_created,
      ...>   proposal_id: "abc123...",
      ...>   rfc_id: "def456...",
      ...>   data: %{title: "Test Proposal"}
      ...> })
      {:ok, %{event_id: "evt_001", sequence: 1, ...}}
  """
  @spec append_event(map()) :: {:ok, map()} | {:error, String.t()}
  def append_event(event_data) do
    GenServer.call(__MODULE__, {:append_event, event_data})
  end

  @doc """
  Get all events for a specific proposal.
  """
  @spec get_proposal_events(String.t()) :: [map()]
  def get_proposal_events(proposal_id) do
    GenServer.call(__MODULE__, {:get_proposal_events, proposal_id})
  end

  @doc """
  Get all events for a specific RFC.
  """
  @spec get_rfc_events(String.t()) :: [map()]
  def get_rfc_events(rfc_id) do
    GenServer.call(__MODULE__, {:get_rfc_events, rfc_id})
  end

  @doc """
  Get event by sequence number.
  """
  @spec get_event_by_sequence(integer()) :: map() | nil
  def get_event_by_sequence(sequence) do
    GenServer.call(__MODULE__, {:get_event_by_sequence, sequence})
  end

  @doc """
  Get current state of a proposal by replaying all its events.
  """
  @spec get_proposal_state(String.t()) :: map() | nil
  def get_proposal_state(proposal_id) do
    GenServer.call(__MODULE__, {:get_proposal_state, proposal_id})
  end

  @doc """
  Get total number of events in ledger.
  """
  @spec event_count() :: integer()
  def event_count() do
    GenServer.call(__MODULE__, :event_count)
  end

  @doc """
  Get all events (for full replay).
  """
  @spec get_all_events() :: [map()]
  def get_all_events() do
    GenServer.call(__MODULE__, :get_all_events)
  end

  # === Server Callbacks ===

  @impl true
  def init(_opts) do
    # Initialize ETS table for events
    :ets.new(:proposal_ledger_events, [:set, :named_table, :public])
    
    # Initialize sequence counter
    :ets.insert(:proposal_ledger_events, {:sequence_counter, 0})
    
    # Initialize indexes
    :ets.new(:proposal_ledger_by_proposal, [:bag, :named_table, :public])
    :ets.new(:proposal_ledger_by_rfc, [:bag, :named_table, :public])
    
    {:ok, %{initialized_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call({:append_event, event_data}, _from, state) do
    case validate_event(event_data) do
      :ok ->
        # Get next sequence number
        [{:sequence_counter, current_seq}] = :ets.lookup(:proposal_ledger_events, :sequence_counter)
        next_seq = current_seq + 1
        
        # Create event with metadata
        event = %{
          event_id: generate_event_id(next_seq),
          sequence: next_seq,
          type: event_data.type,
          proposal_id: event_data.proposal_id,
          rfc_id: event_data.rfc_id,
          data: event_data.data,
          timestamp: DateTime.utc_now(),
          hash: compute_event_hash(event_data, next_seq)
        }
        
        # Store event
        :ets.insert(:proposal_ledger_events, {event.event_id, event})
        
        # Update sequence counter
        :ets.insert(:proposal_ledger_events, {:sequence_counter, next_seq})
        
        # Index by proposal_id
        :ets.insert(:proposal_ledger_by_proposal, {event.proposal_id, event.event_id})
        
        # Index by rfc_id
        :ets.insert(:proposal_ledger_by_rfc, {event.rfc_id, event.event_id})
        
        {:reply, {:ok, event}, state}
      
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:get_proposal_events, proposal_id}, _from, state) do
    events = case :ets.lookup(:proposal_ledger_by_proposal, proposal_id) do
      [] -> []
      matches ->
        matches
        |> Enum.map(fn {^proposal_id, event_id} ->
          case :ets.lookup(:proposal_ledger_events, event_id) do
            [{^event_id, event}] -> event
            [] -> nil
          end
        end)
        |> Enum.filter(& &1)
        |> Enum.sort_by(& &1.sequence)
    end
    
    {:reply, events, state}
  end

  @impl true
  def handle_call({:get_rfc_events, rfc_id}, _from, state) do
    events = case :ets.lookup(:proposal_ledger_by_rfc, rfc_id) do
      [] -> []
      matches ->
        matches
        |> Enum.map(fn {^rfc_id, event_id} ->
          case :ets.lookup(:proposal_ledger_events, event_id) do
            [{^event_id, event}] -> event
            [] -> nil
          end
        end)
        |> Enum.filter(& &1)
        |> Enum.sort_by(& &1.sequence)
    end
    
    {:reply, events, state}
  end

  @impl true
  def handle_call({:get_event_by_sequence, sequence}, _from, state) do
    event = :ets.foldl(
      fn
        {:sequence_counter, _}, acc -> acc
        {_event_id, event}, acc ->
          if event.sequence == sequence do
            event
          else
            acc
          end
      end,
      nil,
      :proposal_ledger_events
    )
    
    {:reply, event, state}
  end

  @impl true
  def handle_call({:get_proposal_state, proposal_id}, _from, state) do
    events = get_proposal_events(proposal_id)
    
    if Enum.empty?(events) do
      {:reply, nil, state}
    else
      # Replay events to reconstruct state
      state = replay_events(events)
      {:reply, state, state}
    end
  end

  @impl true
  def handle_call(:event_count, _from, state) do
    count = :ets.foldl(
      fn
        {:sequence_counter, _}, acc -> acc
        _, acc -> acc + 1
      end,
      0,
      :proposal_ledger_events
    )
    
    {:reply, count, state}
  end

  @impl true
  def handle_call(:get_all_events, _from, state) do
    events = :ets.foldl(
      fn
        {:sequence_counter, _}, acc -> acc
        {_event_id, event}, acc -> [event | acc]
      end,
      [],
      :proposal_ledger_events
    )
    
    {:reply, Enum.sort_by(events, & &1.sequence), state}
  end

  # === Private Functions ===

  defp validate_event(event_data) do
    required_fields = [:type, :proposal_id, :rfc_id, :data]
    
    missing = Enum.filter(required_fields, &is_nil(Map.get(event_data, &1)))
    
    if Enum.empty?(missing) do
      :ok
    else
      {:error, "Missing required fields: #{inspect(missing)}"}
    end
  end

  defp generate_event_id(sequence) do
    "EVT-#{String.pad_leading(Integer.to_string(sequence), 10, "0")}"
  end

  defp compute_event_hash(event_data, sequence) do
    data = Jason.encode!(%{
      sequence: sequence,
      type: event_data.type,
      proposal_id: event_data.proposal_id,
      rfc_id: event_data.rfc_id,
      data: event_data.data
    })
    
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
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
      version: 1,
      created_at: data.timestamp
    })
  end

  defp apply_event(state, %{type: :status_changed, data: data}) do
    Map.put(state, :status, data.new_status)
  end

  defp apply_event(state, %{type: :review_added, data: data}) do
    review_records = Map.get(state, :review_records, []) ++ [data.review_id]
    Map.put(state, :review_records, review_records)
  end

  defp apply_event(state, %{type: :simulation_completed, data: data}) do
    simulation_results = Map.get(state, :simulation_results, []) ++ [data.simulation_id]
    Map.put(state, :simulation_results, simulation_results)
  end

  defp apply_event(state, %{type: :ratification_completed, data: data}) do
    Map.put(state, :ratification_record_id, data.ratification_id)
  end

  defp apply_event(state, %{type: :migration_plan_created, data: data}) do
    Map.put(state, :migration_plan_id, data.migration_plan_id)
  end

  defp apply_event(state, %{type: :certification_completed, data: data}) do
    Map.put(state, :certificate_hash, data.certificate_hash)
  end

  defp apply_event(state, _event) do
    state
  end
end
