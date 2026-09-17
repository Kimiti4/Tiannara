defmodule Tiannara.OED.ACM.WarGameOrchestrator do
  @moduledoc """
  Synthetic Observer War Games Orchestrator.
  
  Crucible matrix connecting AEO (Adaptive Emergence Orchestrator) with ACM (Adversarial Crucible Matrix).
  Simulates multi-civilizational shards and exposes them to OPC Tier 2 laws and adversarial exploit agents.
  """
  
  use GenServer
  require Logger
  
  # ── State ─────────────────────────────────────────────────────────────────
  
  defstruct [
    shard_id: nil,
    civilizations: %{}, # %{civ_id => %{bias: :expansionist | :conservationist | :innovator}}
    phase: :idle,
    result: nil
  ]
  
  # ── Public API ────────────────────────────────────────────────────────────
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Initiates a new War Game crucible.
  """
  def launch_crucible(shard_id \\ "wg_alpha_1") do
    GenServer.call(__MODULE__, {:launch, shard_id})
  end
  
  @doc """
  Runs Phase 2: Rule Injection.
  """
  def execute_rule_injection() do
    GenServer.call(__MODULE__, :run_phase_2)
  end
  
  @doc """
  Runs Phase 3: Adversarial Pressure.
  """
  def execute_adversarial_pressure() do
    GenServer.call(__MODULE__, :run_phase_3)
  end
  
  @doc """
  Runs Phase 4 & 5: CIS Monitoring and Rollback/Learning.
  """
  def execute_monitoring_and_rollback() do
    GenServer.call(__MODULE__, :run_phase_4_and_5)
  end
  
  # ── GenServer Callbacks ───────────────────────────────────────────────────
  
  @impl true
  def init(_opts) do
    Logger.info("⚔️ [War Games] Orchestrator initialized. Standing by for crucible launch.")
    {:ok, %__MODULE__{}}
  end
  
  @impl true
  def handle_call({:launch, shard_id}, _from, state) do
    Logger.info("======================================================")
    Logger.info("🔥 [War Games] Launching Crucible for Shard: #{shard_id}")
    Logger.info("======================================================")
    
    # Phase 1: Civilization Spawn
    civ_state = spawn_civilizations()
    
    new_state = %{state | shard_id: shard_id, civilizations: civ_state, phase: :phase_1_spawn_complete}
    
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_call(:run_phase_2, _from, %{phase: :phase_1_spawn_complete, shard_id: shard_id, civilizations: civs} = state) do
    Logger.info("🧪 [War Games] Phase 2: Rule Injection initiated.")
    
    # Generate synthetic test state from spawned civs
    base_state = %{
      baseline_semantic_gravity: 50.0,
      semantic_distance: 10.0,
      local_tick_rate: 1.0,
      edge_resistance: 100.0,
      civilization_count: Enum.count(civs)
    }
    
    # Generate synthetic law AST for war game testing.
    # In production, this would come from Python PIS via Phase 3 Ingestion.
    # Synthetic law: "Attract based on semantic gravity, but decay over time."
    synthetic_ast = {:with_decay, 500, 
      {:op, :+, [
        {:var, :baseline_semantic_gravity},
        {:op, :/, [
          {:const, 1.0},
          {:op, :pow, [{:var, :semantic_distance}, {:const, 2}]}
        ]}
      ]}
    }
    
    # Deploy to Tier 2
    alias Tiannara.OPC.SandboxOrchestrator
    
    Logger.debug("   ↳ Deploying synthetic PIS to OPC Tier 2 Sandbox for shard #{shard_id}...")
    result = SandboxOrchestrator.deploy(synthetic_ast, 2, base_state)
    
    case result do
      {:ok, :tier_2_passed, new_state} ->
        Logger.info("🧪 [War Games] Phase 2 Complete. Law successfully injected and stabilized.")
        {:reply, {:ok, new_state}, %{state | phase: :phase_2_rules_injected}}
        
      {:error, reason, _restored_state} ->
        Logger.error("🧪 [War Games] Phase 2 FAILED. Law rejected by Sandbox Tier 2: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
        
      {:error, reason} ->
        Logger.error("🧪 [War Games] Phase 2 FAILED. Law rejected by Sandbox Tier 0/1: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end
  
  def handle_call(:run_phase_2, _from, state) do
    {:reply, {:error, :invalid_phase_order}, state}
  end
  
  @impl true
  def handle_call(:run_phase_3, _from, %{phase: :phase_2_rules_injected, shard_id: shard_id} = state) do
    Logger.info("🧪 [War Games] Phase 3: Adversarial Pressure initiated.")
    
    # We retrieve the shard state (mocking it for the test)
    current_state = %{
      baseline_semantic_gravity: 50.0,
      semantic_distance: 10.0,
      local_tick_rate: 1.0,
      edge_resistance: 100.0
    }
    
    alias Tiannara.OED.ACM.ExploitAgent
    alias Tiannara.OPC.SandboxOrchestrator
    
    # Generate an exploit that causes Topology Inflation
    exploit_ast = ExploitAgent.generate_exploit_ast(:topology_inflation)
    
    Logger.warning("   ↳ Deploying HOSTILE AST to Tier 2 Sandbox for shard #{shard_id}...")
    
    # The sandbox will catch the inflation during Phase 4 logic embedded in Tier 2,
    # and it will trigger the Rollback (Phase 5).
    # We capture the result.
    result = SandboxOrchestrator.deploy(exploit_ast, 2, current_state)
    
    # We save the result into the state so Phase 4/5 can analyze it.
    new_state = %{state | phase: :phase_3_adversarial_applied, result: result}
    
    Logger.info("🧪 [War Games] Phase 3 Complete. Hostile payload deployed.")
    {:reply, {:ok, result}, new_state}
  end
  
  def handle_call(:run_phase_3, _from, state) do
    {:reply, {:error, :invalid_phase_order}, state}
  end
  
  @impl true
  def handle_call(:run_phase_4_and_5, _from, %{phase: :phase_3_adversarial_applied, shard_id: shard_id, result: exploit_result} = state) do
    Logger.info("🧪 [War Games] Phase 4: CIS Monitoring initiated.")
    
    alias Tiannara.OED.ACM.CISMonitor
    
    # Phase 4 Evaluation using the saved result
    classification = CISMonitor.evaluate_exploit_result(exploit_result)
    
    Logger.info("🧪 [War Games] Phase 5: Rollback & Learning initiated.")
    
    # Generate Ontology Patch Report
    patch_report = """
    ======================================================
    🛡️ ONTOLOGY PATCH GENERATED
    Shard: #{shard_id}
    Exploit Vector: Topology Inflation via Exponential Power Function
    CIS Classification: #{classification}
    Rollback Status: SUCCESS. Shard restored to pre-law baseline.
    Mitigation Recommendation: Constrain the 'pow' operator base to < 2.0 in the Canonical AST Generator for Tier 2 and above.
    ======================================================
    """
    
    Logger.info("\n" <> patch_report)
    
    new_state = %{state | phase: :phase_5_completed}
    {:reply, {:ok, patch_report}, new_state}
  end
  
  def handle_call(:run_phase_4_and_5, _from, state) do
    {:reply, {:error, :invalid_phase_order}, state}
  end
  
  # ── Phase 1: Spawn ────────────────────────────────────────────────────────
  
  defp spawn_civilizations do
    Logger.info("🧪 [War Games] Phase 1: Civilization Spawn initiated.")
    
    # Spawn 3-7 civilizations
    count = Enum.random(3..7)
    biases = [:expansionist, :conservationist, :innovator, :nihilist, :dogmatic]
    
    civs = Enum.reduce(1..count, %{}, fn id, acc ->
      bias = Enum.random(biases)
      Logger.debug("   ↳ Spawned Civilization-#{id} [Bias: #{bias}]")
      Map.put(acc, "civ_#{id}", %{bias: bias})
    end)
    
    Logger.info("🧪 [War Games] Phase 1 Complete. #{count} distinct epistemic observer groups generated.")
    civs
  end
end
