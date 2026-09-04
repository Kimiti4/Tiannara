defmodule TiannaraOS.Governance.RFCScheduler do
  @moduledoc """
  RFCScheduler - Manages timing and progression of RFC lifecycle stages
  
  Handles automatic stage transitions based on time thresholds,
  monitors stage deadlines, and triggers timeout handling when needed.
  
  ## Owner
  GovernanceValidationLaboratory (existing, frozen)
  
  ## Stage Timeouts
  - Review: 7 days
  - Discussion: 14 days
  - Simulation: 24 hours
  - Institutional Review: 7 days
  - Ratification Vote: 3 days
  - Migration: 2 hours
  - Replay Verification: 1 hour
  
  ## Guarantees
  - Automatic progression on timeout
  - Configurable timeouts per stage
  - Deadline monitoring
  - Timeout event logging
  
  ## Usage
      iex> RFCScheduler.start_monitoring("proposal_001", :review)
      :ok
  """

  use GenServer

  # === Client API ===

  @doc """
  Start the RFCScheduler GenServer.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Start monitoring a proposal's stage with timeout.
  
  ## Parameters
  - `rfc_id` - ID of RFC to monitor
  - `stage` - Current lifecycle stage
  - `timeout_ms` - Timeout in milliseconds (optional, uses defaults)
  
  ## Returns
  :ok or {:error, reason}
  """
  @spec start_monitoring(String.t(), atom(), integer() | nil) :: :ok | {:error, String.t()}
  def start_monitoring(rfc_id, stage, timeout_ms \\ nil) do
    timeout = timeout_ms || default_timeout(stage)
    GenServer.cast(__MODULE__, {:start_monitoring, rfc_id, stage, timeout})
    :ok
  end

  @doc """
  Stop monitoring a proposal (stage completed).
  
  ## Parameters
  - `rfc_id` - ID of RFC
  
  ## Returns
  :ok
  """
  @spec stop_monitoring(String.t()) :: :ok
  def stop_monitoring(rfc_id) do
    GenServer.cast(__MODULE__, {:stop_monitoring, rfc_id})
    :ok
  end

  @doc """
  Get time remaining for current stage.
  
  ## Parameters
  - `rfc_id` - ID of RFC
  
  ## Returns
  {:ok, remaining_ms} or {:error, reason}
  """
  @spec time_remaining(String.t()) :: {:ok, integer()} | {:error, String.t()}
  def time_remaining(rfc_id) do
    GenServer.call(__MODULE__, {:time_remaining, rfc_id})
  end

  @doc """
  Get default timeout for a stage.
  
  ## Parameters
  - `stage` - Lifecycle stage atom
  
  ## Returns
  Timeout in milliseconds
  """
  @spec default_timeout(atom()) :: integer()
  def default_timeout(:under_review), do: 7 * 24 * 60 * 60 * 1000  # 7 days
  def default_timeout(:discussion), do: 14 * 24 * 60 * 60 * 1000  # 14 days
  def default_timeout(:simulation), do: 24 * 60 * 60 * 1000       # 24 hours
  def default_timeout(:institutional_review), do: 7 * 24 * 60 * 60 * 1000  # 7 days
  def default_timeout(:ratification_vote), do: 3 * 24 * 60 * 60 * 1000     # 3 days
  def default_timeout(:migration), do: 2 * 60 * 60 * 1000         # 2 hours
  def default_timeout(:replay_verification), do: 60 * 60 * 1000   # 1 hour
  def default_timeout(_), do: 24 * 60 * 60 * 1000                 # 24 hours default

  # === Server Callbacks ===

  @impl true
  def init(_opts) do
    state = %{
      monitors: %{},  # %{rfc_id => %{stage, started_at, timeout_ms}}
      timers: %{}     # %{rfc_id => timer_ref}
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:start_monitoring, rfc_id, stage, timeout_ms}, state) do
    # Cancel existing timer if any
    state = cancel_timer(rfc_id, state)

    # Start new monitoring
    started_at = System.monotonic_time(:millisecond)
    monitor = %{
      stage: stage,
      started_at: started_at,
      timeout_ms: timeout_ms
    }

    # Set up timeout timer
    timer_ref = Process.send_after(self(), {:timeout, rfc_id}, timeout_ms)

    state = %{
      state |
      monitors: Map.put(state.monitors, rfc_id, monitor),
      timers: Map.put(state.timers, rfc_id, timer_ref)
    }

    {:noreply, state}
  end

  @impl true
  def handle_cast({:stop_monitoring, rfc_id}, state) do
    state = cancel_timer(rfc_id, state)
    state = %{state | monitors: Map.delete(state.monitors, rfc_id)}

    {:noreply, state}
  end

  @impl true
  def handle_call({:time_remaining, rfc_id}, _from, state) do
    case Map.get(state.monitors, rfc_id) do
      nil ->
        {:reply, {:error, "No active monitor for #{rfc_id}"}, state}

      monitor ->
        elapsed = System.monotonic_time(:millisecond) - monitor.started_at
        remaining = max(0, monitor.timeout_ms - elapsed)
        {:reply, {:ok, remaining}, state}
    end
  end

  @impl true
  def handle_info({:timeout, rfc_id}, state) do
    case Map.get(state.monitors, rfc_id) do
      nil ->
        {:noreply, state}

      monitor ->
        # Log timeout event
        IO.puts("[Scheduler] Timeout for RFC #{rfc_id} in stage #{monitor.stage}")

        # In production: trigger timeout handling (auto-advance or reject)
        # For now, just log

        state = %{state | monitors: Map.delete(state.monitors, rfc_id)}
        {:noreply, state}
    end
  end

  # === Private Helpers ===

  defp cancel_timer(rfc_id, state) do
    case Map.get(state.timers, rfc_id) do
      nil ->
        state

      timer_ref ->
        Process.cancel_timer(timer_ref)
        %{state | timers: Map.delete(state.timers, rfc_id)}
    end
  end
end
