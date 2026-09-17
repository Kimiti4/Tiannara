defmodule Tiannara.GodLoop.Supervisor do
  @moduledoc """
  God-Loop: Engine Supervisor.
  
  Executes the mutually recursive loop between MCAL, OPC, and CIS.
  """
  
  use GenServer
  require Logger
  
  alias Tiannara.GodLoop.{GradientField, MCALInterface, OPCInterface, CISInterface}

  def start_link(init_state \\ []) do
    GenServer.start_link(__MODULE__, init_state, name: __MODULE__)
  end
  
  def tick() do
    GenServer.cast(__MODULE__, :tick)
  end
  
  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  @impl true
  def init(_) do
    Logger.info("🌌 [God-Loop Engine] Booting Self-Rewriting Cognitive Substrate...")
    
    state = %{
      iteration: 0,
      mc_state: %{identity_diversity: 0.2, static_epochs: 10, reasoning_mode: :stabilization},
      opc_state: %{paradox_density: 0.1, rule_volatility: 0.2, conservation_strictness: 0.9},
      cis_state: %{tension: 0.2, rigidity: 0.8} # High rigidity leads to Immune Tyranny
    }
    
    {:ok, state}
  end

  @impl true
  def handle_cast(:tick, state) do
    Logger.info("\n=======================================================")
    Logger.info("🔄 [God-Loop] Commencing Recursive Iteration #{state.iteration}")
    
    # 1. Evaluate field gradients
    gradients = GradientField.evaluate(state.mc_state, state.opc_state, state.cis_state)
    
    # 2. Mutually self-rewrite
    new_mc = MCALInterface.evolve(state.mc_state, gradients)
    new_opc = OPCInterface.mutate(state.opc_state, new_mc, gradients)
    new_cis = CISInterface.self_adjust(state.cis_state, new_opc, gradients)
    
    Logger.info("✅ [God-Loop] Iteration #{state.iteration} complete. Reality rules updated.")
    
    {:noreply,
     %{state |
       iteration: state.iteration + 1,
       mc_state: new_mc,
       opc_state: new_opc,
       cis_state: new_cis}}
  end
  
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
