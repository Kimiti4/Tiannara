defmodule Tiannara.Stabilization.OCM.ConsensusManager do
  @moduledoc """
  Manages consensus sessions and coordination across ontologies.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start_consensus_session(ontology_ids, opts \\ []) do
    GenServer.call(__MODULE__, {:start_consensus_session, ontology_ids, opts})
  end

  def get_active_sessions() do
    GenServer.call(__MODULE__, :get_active_sessions)
  end

  def get_session_status(session_id) do
    GenServer.call(__MODULE__, {:get_session_status, session_id})
  end

  def end_session(session_id, result \\ :completed) do
    GenServer.call(__MODULE__, {:end_session, session_id, result})
  end

  def get_consensus_history() do
    GenServer.call(__MODULE__, :get_consensus_history)
  end

  def get_session_stats() do
    GenServer.call(__MODULE__, :get_session_stats)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for session management
    :ets.new(:consensus_sessions, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:session_history, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:session_metadata, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    Logger.info("Consensus manager initialized")
    
    {:ok, %{
      active_sessions: 0,
      total_sessions: 0,
      completed_sessions: 0,
      failed_sessions: 0,
      last_session: 0,
      concurrent_limit: 10
    }}
  end

  @impl true
  def handle_call({:start_consensus_session, ontology_ids, opts}, _from, state) do
    # Check concurrency limit
    if state.active_sessions >= state.concurrent_limit do
      {:reply, {:error, :concurrency_limit_exceeded}, state}
    end

    # Validate ontology IDs
    case validate_ontology_ids(ontology_ids) do
      :ok ->
        # Create session
        session_id = generate_session_id()
        session_opts = normalize_session_opts(opts)
        
        session = %{
          id: session_id,
          ontology_ids: ontology_ids,
          status: :active,
          started_at: System.system_time(:millisecond),
          timeout: session_opts.timeout,
          consensus_threshold: session_opts.threshold,
          participants: length(ontology_ids),
          votes_collected: 0,
          conflicts: []
        }

        # Store session
        :ets.insert(:consensus_sessions, {session_id, session})
        :ets.insert(:session_metadata, {session_id, session_opts})

        Logger.info("Started consensus session #{session_id} with #{length(ontology_ids)} participants")

        # Start timeout timer
        Process.send_after(self(), {:timeout_session, session_id}, session.timeout)

        {:reply, {:ok, session_id}, 
         %{state | 
           active_sessions: state.active_sessions + 1,
           total_sessions: state.total_sessions + 1,
           last_session: System.system_time(:millisecond)
         }}

      {:error, reason} ->
        Logger.error("Cannot start consensus session: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:get_active_sessions, _from, state) do
    sessions = :ets.tab2list(:consensus_sessions)
    |> Enum.filter(fn {_, session} -> session.status == :active end)
    |> Enum.map(fn {session_id, session} ->
      %{session | id: session_id}
    end)

    {:reply, {:ok, sessions}, state}
  end

  @impl true
  def handle_call({:get_session_status, session_id}, _from, state) do
    case :ets.lookup(:consensus_sessions, session_id) do
      [{^session_id, session}] ->
        {:reply, {:ok, session}, state}
      [] ->
        {:reply, {:error, :session_not_found}, state}
    end
  end

  @impl true
  def handle_call({:end_session, session_id, result}, _from, state) do
    case :ets.lookup(:consensus_sessions, session_id) do
      [{^session_id, session}] ->
        # Update session status
        ended_session = %{session | 
          status: result,
          ended_at: System.system_time(:millisecond),
          duration: System.system_time(:millisecond) - session.started_at
        }

        # Store in history
        :ets.insert(:session_history, {System.system_time(:millisecond), session_id, ended_session})
        :ets.delete(:consensus_sessions, session_id)

        Logger.info("Ended consensus session #{session_id} with status: #{result}")

        # Update statistics
        new_state = update_session_stats(state, result)

        {:reply, {:ok, ended_session}, new_state}

      [] ->
        {:reply, {:error, :session_not_found}, state}
    end
  end

  @impl true
  def handle_call(:get_consensus_history, _from, state) do
    history = :ets.tab2list(:session_history)
    |> Enum.map(fn {timestamp, session_id, session} ->
      %{timestamp: timestamp, session_id: session_id, session: session}
    end)
    |> Enum.sort_by(& &1.timestamp, :desc)

    {:reply, {:ok, history}, state}
  end

  @impl true
  def handle_call(:get_session_stats, _from, state) do
    stats = %{
      active_sessions: state.active_sessions,
      total_sessions: state.total_sessions,
      completed_sessions: state.completed_sessions,
      failed_sessions: state.failed_sessions,
      last_session: state.last_session,
      concurrent_limit: state.concurrent_limit,
      success_rate: calculate_success_rate(state)
    }

    {:reply, {:ok, stats}, state}
  end

  @impl true
  def handle_info({:timeout_session, session_id}, state) do
    # Handle session timeout
    case :ets.lookup(:consensus_sessions, session_id) do
      [{^session_id, _session}] ->
        Logger.warning("Session #{session_id} timed out")
        end_session(session_id, :timeout)
      [] ->
        # Session already ended
        :ok
    end

    {:noreply, state}
  end

  # Helper functions
  defp validate_ontology_ids(ontology_ids) when is_list(ontology_ids) do
    case length(ontology_ids) do
      0 -> {:error, :no_ontologies}
      n when n > 20 -> {:error, :too_many_ontologies}
      _ -> :ok
    end
  end

  defp validate_ontology_ids(_), do: {:error, :invalid_input}

  defp normalize_session_opts(opts) do
    %{
      timeout: Keyword.get(opts, :timeout, 30_000),  # 30 seconds
      threshold: Keyword.get(opts, :threshold, 0.75),  # 75% agreement
      max_retries: Keyword.get(opts, :max_retries, 3),
      voting_strategy: Keyword.get(opts, :voting_strategy, :weighted)
    }
  end

  defp generate_session_id() do
    "consensus_#{System.system_time(:millisecond)}_#{:crypto.strong_rand_bytes(8) |> Base.url_encode64()}"
  end

  defp update_session_stats(state, result) do
    case result do
      :completed -> %{state | 
        completed_sessions: state.completed_sessions + 1,
        active_sessions: state.active_sessions - 1
      }
      :failed -> %{state | 
        failed_sessions: state.failed_sessions + 1,
        active_sessions: state.active_sessions - 1
      }
      :timeout -> %{state | 
        failed_sessions: state.failed_sessions + 1,
        active_sessions: state.active_sessions - 1
      }
      _ -> state
    end
  end

  defp calculate_success_rate(state) do
    total = state.total_sessions
    if total > 0 do
      state.completed_sessions / total
    else
      0.0
    end
  end
end
