defmodule Tiannara.MCAL.Memory do
  @moduledoc """
  MCAL: Epistemic Memory Architecture.
  
  Stores the history of cognition over time. Rather than raw state,
  it stores frame transitions, abstractions, and the CIS feedback loop.
  This is the foundation for MCAL v2 Recursive Identity.
  """
  
  use GenServer
  require Logger

  defstruct [
    frame_history: [],
    abstraction_snapshots: [],
    cis_feedback_log: [],
    transition_graph: %{},
    failure_archive: [],
    success_patterns: [],
    cross_world_mappings: %{}
  ]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  @doc """
  Records a cognitive frame transition.
  """
  def record_transition(from_frame, to_frame, trigger_reason) do
    GenServer.cast(__MODULE__, {:record_transition, from_frame, to_frame, trigger_reason})
  end

  @doc """
  Archives a rejected cognitive structure into the immune learning dataset.
  """
  def archive_failure(abstraction, reason) do
    GenServer.cast(__MODULE__, {:archive_failure, abstraction, reason})
  end
  
  @doc """
  Records an abstraction snapshot for telemetry analysis.
  """
  def snapshot_abstraction(abstraction) do
    GenServer.cast(__MODULE__, {:snapshot_abstraction, abstraction})
  end
  
  @doc """
  Retrieves the current epistemic memory state.
  """
  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  @impl true
  def init(state) do
    Logger.info("🧠 [MCAL Memory] Epistemic Storage System online. Initializing self-aware cognition logs.")
    {:ok, state}
  end

  @impl true
  def handle_cast({:record_transition, from_frame, to_frame, reason}, state) do
    Logger.debug("🧠 [MCAL Memory] Recorded frame transition: #{inspect(from_frame)} -> #{inspect(to_frame)}")
    
    transition = %{from: from_frame, to: to_frame, reason: reason, timestamp: :os.system_time(:millisecond)}
    history = [transition | state.frame_history]
    
    # Update transition graph counts
    graph_key = {from_frame, to_frame}
    graph = Map.update(state.transition_graph, graph_key, 1, &(&1 + 1))
    
    {:noreply, %{state | frame_history: history, transition_graph: graph}}
  end

  @impl true
  def handle_cast({:archive_failure, abstraction, reason}, state) do
    Logger.warning("🧠 [MCAL Memory] Archiving failed cognitive structure to immune dataset. Reason: #{reason}")
    
    archive_entry = %{abstraction: abstraction, failure_reason: reason, timestamp: :os.system_time(:millisecond)}
    archive = [archive_entry | state.failure_archive]
    
    {:noreply, %{state | failure_archive: archive}}
  end
  
  @impl true
  def handle_cast({:snapshot_abstraction, abstraction}, state) do
    snapshots = [abstraction | state.abstraction_snapshots] |> Enum.take(100) # Keep last 100
    {:noreply, %{state | abstraction_snapshots: snapshots}}
  end
  
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
