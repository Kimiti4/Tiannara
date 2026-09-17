defmodule Tiannara.MCAL.CognitiveKernel do
  @moduledoc """
  MCAL: Cognitive Kernel.
  
  The "brain stem" of MCAL. Receives raw state, triggers abstraction,
  selects reasoning frames, and passes the synthesized meta-cognition
  to the CognitionRouter.
  """
  
  use GenServer
  require Logger
  
  alias Tiannara.MCAL.{
    FrameSelector, 
    AbstractionEngine, 
    MetaReasoner, 
    CognitionRouter,
    Telemetry,
    Memory,
    CISEvolutionLoop
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Processes a raw ecological state or mutation trace through the cognitive pipeline.
  """
  def process_state(trace_state) do
    GenServer.cast(__MODULE__, {:process_state, trace_state})
  end

  @impl true
  def init(_) do
    Logger.info("🧠 [MCAL Kernel] Initialized. Awaiting raw substrate states for abstraction.")
    {:ok, %{active_context: nil, abstraction_depth: 1}}
  end

  @impl true
  def handle_cast({:process_state, grcc_state}, state) do
    Logger.debug("🧠 [MCAL Kernel] Intercepted new ecological state. Beginning cognitive abstraction cycle...")
    
    # 1. Decide HOW to think (and record transition)
    frame = FrameSelector.select(grcc_state)
    
    if state.active_context do
      Memory.record_transition(state.active_context.frame, frame, :ecological_shift)
    end
    
    # 2. Extract structural meaning
    abstraction = AbstractionEngine.abstract(grcc_state, frame)
    Memory.snapshot_abstraction(abstraction)
    
    # 3. Telemetry: Self-Awareness of thinking
    memory_state = Memory.get_state()
    {telemetry_status, telemetry_data} = Telemetry.snapshot(memory_state, abstraction)
    
    # If telemetry detects high internal instability, we force a frame shift
    adjusted_abstraction = if telemetry_status == :unstable do
      %{abstraction | frame: :safe_mode}
    else
      abstraction
    end
    
    # 4. CIS Co-Evolution Loop (Immune check)
    immune_cognition = CISEvolutionLoop.cycle(adjusted_abstraction, grcc_state)
    
    # 5. Think about thinking (reason over the finalized immune-checked abstraction)
    meta = MetaReasoner.reason(immune_cognition)
    
    # 6. Route the cognitive mandate (to OPC / CTL / AEO)
    CognitionRouter.route(meta, grcc_state)

    # Attach frame to meta for memory tracking
    final_context = Map.put(meta, :frame, immune_cognition.frame)
    {:noreply, %{state | active_context: final_context}}
  end
end
