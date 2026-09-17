defmodule Tiannara.CivilizationState do
  defstruct [
    :id,
    :world,
    :agents,                # List of %Tiannara.Agent{}
    :memory_graph,          # %Tiannara.MemoryGraph{}
    :epistemic_energy,      # Resource budget
    :cultural_identity,     # %{exploration_bias: 0.8, conservatism: 0.2, ...}
    :cognitive_coherence,   # Alignment between castes
    :factions,              # e.g., %{rationalists: 0.4, expansionists: 0.6}
    :reward_history,
    :collapse_risk,
    :theorem_reserve,
    :policy_state,
    :diplomatic_relations,
    :historical_events,
    :status                 # :active, :ruin
  ]
end

defmodule Tiannara.CivilizationServer do
  @moduledoc """
  Adaptive intelligence cluster inside a world.
  Represents persistent epistemic organisms with internal memory, factions, and culture.
  """
  use GenServer
  alias Tiannara.CivilizationState
  alias Tiannara.Agent
  alias Tiannara.MemoryGraph
  alias Tiannara.CivilizationRuin

  # API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via(opts[:id]))
  end

  # INIT
  def init(opts) do
    id = opts[:id]
    
    # 2. Cultural Identities Start Semi-Randomized
    culture = %{
      exploration_bias: 0.2 + (:rand.uniform() * 0.6),
      conservatism: 0.2 + (:rand.uniform() * 0.6),
      contradiction_tolerance: :rand.uniform(),
      theorem_sharing: :rand.uniform(),
      synthesis_preference: :rand.uniform(),
      memory_preservation: 0.5 + (:rand.uniform() * 0.5)
    }

    # Generate agents based on culture
    agents = generate_agents(100, culture)

    # Initialize factions based on agents
    factions = %{
      rationalists: 0.2,
      expansionists: 0.2,
      purifiers: 0.2,
      archivists: 0.2,
      synthesizers: 0.2
    }

    state = %CivilizationState{
      id: id,
      world: opts[:world],
      agents: agents,
      memory_graph: MemoryGraph.new(),
      epistemic_energy: 100.0,
      cultural_identity: culture,
      cognitive_coherence: 1.0,
      factions: factions,
      reward_history: [],
      collapse_risk: 0.0,
      theorem_reserve: 10.0,
      policy_state: :explore,
      diplomatic_relations: %{},
      historical_events: [],
      status: :active
    }

    {:ok, state}
  end

  # MAIN TICK (8-STEP ORDER)
  def handle_cast(:civ_tick, %CivilizationState{status: :ruin} = state) do
    # Ruins do not evolve, they just radiate decay
    {:noreply, state}
  end

  def handle_cast(:civ_tick, state) do
    new_state =
      state
      |> step1_resource_accounting()
      |> step2_internal_faction_updates()
      |> step3_agent_action_phase()
      |> step4_reward_computation()
      |> step5_memory_consolidation()
      |> step6_coherence_recalculation()
      |> step6b_recursive_self_modeling()
      |> step7_collapse_checks()
      |> step8_telemetry_emission()

    {:noreply, new_state}
  end

  # 8-STEP IMPLEMENTATION
  
  defp step1_resource_accounting(state) do
    # Base energy drain just for existing
    new_energy = state.epistemic_energy - (length(state.agents) * 0.01)
    %{state | epistemic_energy: max(0.0, new_energy)}
  end

  defp step2_internal_faction_updates(state) do
    # Shifts faction dominance based on cultural drift
    state
  end

  defp step3_agent_action_phase(state) do
    # PASSIVE MODE: Agents do not mutate or consume energy
    {updated_agents, total_cost, _total_reward} =
      Enum.reduce(state.agents, {[], 0.0, 0.0}, fn agent, {acc_agents, acc_cost, acc_reward} ->
        # {new_agent, reward, cost, _action} = Agent.act(agent)
        {[agent | acc_agents], acc_cost, acc_reward}
      end)
      
    # Deduct cost from civilization energy
    new_energy = state.epistemic_energy - total_cost
    
    %{state | agents: updated_agents, epistemic_energy: max(0.0, new_energy)}
  end

  defp step4_reward_computation(state) do
    # Recharge energy via discovery
    recharge = :rand.uniform() * 5.0
    %{state | epistemic_energy: state.epistemic_energy + recharge}
  end

  defp step5_memory_consolidation(state) do
    # Probability of consolidation based on tick or energy
    if :rand.uniform() > 0.9 do
      new_graph = MemoryGraph.consolidate(state.memory_graph)
      %{state | memory_graph: new_graph}
    else
      state
    end
  end

  defp step6_coherence_recalculation(state) do
    # Coherence = D_internal + E * S_shared
    shared_semantics = map_size(state.memory_graph.lemmas) * 0.01
    internal_divergence = :rand.uniform() * 0.2
    
    coherence = shared_semantics - internal_divergence
    coherence = max(0.0, min(1.0, coherence))
    
    %{state | cognitive_coherence: coherence}
  end

  defp step6b_recursive_self_modeling(state) do
    # RECURSIVE SELF-MODELING
    # The civilization looks at its own state to predict collapse.
    if state.epistemic_energy < 10.0 and state.cognitive_coherence < 0.3 do
      # Predicted collapse trajectory detected!
      # Rewrite policy to survive: override all agents to become Provers to stabilize the structure.
      emergency_agents = Enum.map(state.agents, fn a -> %{a | caste: :prover} end)
      
      event = %{
        type: :recursive_policy_rewrite,
        civ_id: state.id,
        reason: "Predicted collapse trajectory. Shifting all agents to Prover caste to maximize stabilization.",
        timestamp: System.os_time(:second)
      }
      
      # Burst emission for major self-modeling event
      GenServer.cast(via_universe(:alpha_universe), {:burst_event, event})

      %{state | agents: emergency_agents, policy_state: :emergency_stabilization, historical_events: [event | state.historical_events]}
    else
      state
    end
  end

  defp step7_collapse_checks(state) do
    # If energy is 0 and coherence is near 0, we risk collapse
    if state.epistemic_energy <= 0.0 and state.cognitive_coherence < 0.2 do
      risk = state.collapse_risk + 0.1
      if risk > 1.0 do
        # 6. Collapse should produce "Ruins", not wipes.
        IO.puts("CIVILIZATION COLLAPSE: #{state.id} has fallen.")
        
        event = %{
          type: :civilization_collapse,
          civ_id: state.id,
          timestamp: System.os_time(:second)
        }
        GenServer.cast(via_universe(:alpha_universe), {:burst_event, event})
        
        %CivilizationState{state | status: :ruin, collapse_risk: 0.0, agents: []}
      else
        %{state | collapse_risk: risk}
      end
    else
      %{state | collapse_risk: max(0.0, state.collapse_risk - 0.05)}
    end
  end

  defp step8_telemetry_emission(state) do
    # Step 1: Civilizations emit internally (NOT external HTTP).
    # Civilization -> UniverseAggregator
    GenServer.cast(via_universe(:alpha_universe), {:civilization_telemetry, state})
    state
  end

  # HELPERS
  
  defp generate_agents(count, _culture) do
    Enum.map(1..count, fn _ ->
      # Assign caste based on culture bias (simplified here)
      caste = Enum.random([:prover, :falsifier, :explorer, :synthesizer, :historian])
      field = Enum.random([:p_vs_np, :riemann, :navier_stokes, :yang_mills, :poincare, :bsd, :hodge])
      Agent.new(caste, field)
    end)
  end

  defp via(id), do: {:via, Registry, {Tiannara.Registry, {:civilization, id}}}
  defp via_universe(id), do: {:via, Registry, {Tiannara.Registry, {:universe, id}}}
end
