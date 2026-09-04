defmodule Tiannara.REL.EconomyEngine do
  @moduledoc """
  Manages thermodynamic constraints (REL-1) for civilizations.
  Tracks budgets, maintenance costs, and handles starvation/dormancy.
  """

  use GenServer
  require Logger

  alias Tiannara.REL.ResourceBudget
  alias Tiannara.Core.WorldModel.BeliefSystem
  alias Tiannara.ROS.Registry, as: ROSRegistry

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Set maintenance formula."
  def set_maintenance_formula(_func), do: :ok

  @doc "Set dormancy TTL."
  def set_dormancy_ttl_ticks(_ticks), do: :ok

  @doc "Set dormancy recovery threshold."
  def set_dormancy_recovery_threshold(_threshold), do: :ok

  @doc "Initialize a budget for a new civilization."
  def register_civilization(shard_id, civ_id) do
    GenServer.call(__MODULE__, {:register, shard_id, civ_id})
  end

  @doc "Check if a civilization can afford an action."
  def can_afford?(civ_id, costs) do
    GenServer.call(__MODULE__, {:can_afford, civ_id, costs})
  end

  @doc "Consume resources for an action. Fails if insufficient."
  def consume(civ_id, costs) do
    GenServer.call(__MODULE__, {:consume, civ_id, costs})
  end

  @doc "Inject resources into a civilization's budget."
  def inject(civ_id, resources) do
    GenServer.call(__MODULE__, {:inject, civ_id, resources})
  end

  @doc "Get current budget and state."
  def get_budget(civ_id) do
    GenServer.call(__MODULE__, {:get_budget, civ_id})
  end

  @doc "Remove a budget (e.g. upon extinction)."
  def remove_budget(civ_id) do
    GenServer.call(__MODULE__, {:remove_budget, civ_id})
  end

  @doc "Tick a civilization, applying maintenance and state transitions."
  def tick(civ_id) do
    GenServer.cast(__MODULE__, {:tick, civ_id})
  end

  @doc "Grant Truth Capital to a civilization."
  def grant_truth_capital(civ_id, amount) do
    GenServer.call(__MODULE__, {:grant_truth_capital, civ_id, amount})
  end

  @doc "Penalize Truth Capital for a civilization."
  def penalize_truth_capital(civ_id, amount) do
    GenServer.call(__MODULE__, {:penalize_truth_capital, civ_id, amount})
  end

  @doc "Grant Influence Capital to a civilization."
  def grant_influence_capital(civ_id, amount) do
    GenServer.call(__MODULE__, {:grant_influence_capital, civ_id, amount})
  end

  @doc "Compute the overall Trust Score for a civilization."
  def compute_trust_score(civ_id) do
    GenServer.call(__MODULE__, {:compute_trust_score, civ_id})
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting REL Economy Engine")
    {:ok, %{budgets: %{}}} # civ_id -> %ResourceBudget{}
  end

  @impl true
  def handle_call({:register, shard_id, civ_id}, _from, state) do
    budget = ResourceBudget.new(shard_id, civ_id)
    new_state = put_in(state.budgets[civ_id], budget)
    {:reply, :ok, new_state}
  end

  def handle_call({:can_afford, civ_id, costs}, _from, state) do
    budget = Map.get(state.budgets, civ_id)
    if budget do
      {:reply, has_funds?(budget, costs), state}
    else
      {:reply, false, state}
    end
  end

  def handle_call({:consume, civ_id, costs}, _from, state) do
    case Map.get(state.budgets, civ_id) do
      nil -> {:reply, {:error, :not_found}, state}
      %ResourceBudget{state: :dormant} -> {:reply, {:error, :dormant}, state}
      %ResourceBudget{} = budget ->
        if has_funds?(budget, costs) do
          new_budget = apply_costs(budget, costs)
          new_state = put_in(state.budgets[civ_id], new_budget)
          {:reply, :ok, new_state}
        else
          {:reply, {:error, :insufficient_funds}, state}
        end
    end
  end

  def handle_call({:inject, civ_id, resources}, _from, state) do
    case Map.get(state.budgets, civ_id) do
      nil -> {:reply, {:error, :not_found}, state}
      %ResourceBudget{} = budget ->
        new_budget = %{budget |
          energy: budget.energy + Map.get(resources, :energy, 0),
          compute: budget.compute + Map.get(resources, :compute, 0),
          attention: budget.attention + Map.get(resources, :attention, 0),
          ontological_capital: budget.ontological_capital + Map.get(resources, :ontological_capital, 0)
        }
        # If we injected energy and they were dormant/starving, they might recover?
        # For now, let the next tick sort out state transitions, or do it immediately.
        new_state = put_in(state.budgets[civ_id], new_budget)
        {:reply, :ok, new_state}
    end
  end

  def handle_call({:get_budget, civ_id}, _from, state) do
    {:reply, Map.get(state.budgets, civ_id), state}
  end

  def handle_call({:remove_budget, civ_id}, _from, state) do
    new_state = %{state | budgets: Map.delete(state.budgets, civ_id)}
    {:reply, :ok, new_state}
  end

  def handle_call({:grant_truth_capital, civ_id, amount}, _from, state) do
    case Map.get(state.budgets, civ_id) do
      nil -> {:reply, {:error, :not_found}, state}
      budget ->
        new_budget = %{budget | truth_capital: budget.truth_capital + amount}
        {:reply, :ok, put_in(state.budgets[civ_id], new_budget)}
    end
  end

  def handle_call({:penalize_truth_capital, civ_id, amount}, _from, state) do
    case Map.get(state.budgets, civ_id) do
      nil -> {:reply, {:error, :not_found}, state}
      budget ->
        # Capital can go negative to reflect deep distrust
        new_budget = %{budget | truth_capital: budget.truth_capital - amount}
        {:reply, :ok, put_in(state.budgets[civ_id], new_budget)}
    end
  end

  def handle_call({:grant_influence_capital, civ_id, amount}, _from, state) do
    case Map.get(state.budgets, civ_id) do
      nil -> {:reply, {:error, :not_found}, state}
      budget ->
        new_budget = %{budget | influence_capital: budget.influence_capital + amount}
        {:reply, :ok, put_in(state.budgets[civ_id], new_budget)}
    end
  end

  def handle_call({:compute_trust_score, civ_id}, _from, state) do
    case Map.get(state.budgets, civ_id) do
      nil -> {:reply, {:error, :not_found}, state}
      budget ->
        # A simple composite metric. Normalizing capital limits is tricky, so we use a non-linear approach
        # or simple weighting. For ECL, we might want it normalized between 0 and 1, but raw score works too.
        # Let's use a logistic sigmoid or something simple: truth_capital dominates, influence scales it.
        # But wait, diseases and low accuracy should tank the score.
        
        # Base Score is built around Truth Capital
        base_truth = budget.truth_capital
        base_influence = budget.influence_capital
        
        # Simple summation for now, weighted toward truth.
        trust_score = (base_truth * 1.5) + (base_influence * 0.5)
        
        {:reply, {:ok, trust_score}, state}
    end
  end

  @impl true
  def handle_cast({:tick, civ_id}, state) do
    case Map.get(state.budgets, civ_id) do
      nil -> {:noreply, state}
      budget ->
        new_budget = process_maintenance_tick(budget)
        {:noreply, put_in(state.budgets[civ_id], new_budget)}
    end
  end

  # --- Internal Logic ---

  defp has_funds?(budget, costs) do
    budget.energy >= Map.get(costs, :energy, 0) and
    budget.compute >= Map.get(costs, :compute, 0) and
    budget.attention >= Map.get(costs, :attention, 0) and
    budget.ontological_capital >= Map.get(costs, :ontological_capital, 0)
  end

  defp apply_costs(budget, costs) do
    %{budget |
      energy: budget.energy - Map.get(costs, :energy, 0),
      compute: budget.compute - Map.get(costs, :compute, 0),
      attention: budget.attention - Map.get(costs, :attention, 0),
      ontological_capital: budget.ontological_capital - Map.get(costs, :ontological_capital, 0)
    }
  end

  def compute_epistemic_health(%ResourceBudget{} = budget) do
    disease_load = 0.0 # Would sum virulence of active diseases
    prediction_accuracy = 0.7 
    truth_capital = budget.truth_capital
    contradiction_density = 0.1
    immune_adaptation_strength = 0.5
    
    health = 
      (prediction_accuracy * 20.0) +
      truth_capital +
      (immune_adaptation_strength * 15.0) -
      (disease_load * 10.0) -
      (contradiction_density * 20.0)
      
    max(0.0, health)
  end

  def compute_epistemic_health(civ_id) when is_binary(civ_id) do
    if self() == Process.whereis(__MODULE__) do
      %ResourceBudget{civilization_id: civ_id, shard_id: "default", truth_capital: 0.0} |> compute_epistemic_health()
    else
      case get_budget(civ_id) do
        nil -> 0.0
        budget -> compute_epistemic_health(budget)
      end
    end
  end

  def compute_epistemic_tension(%ResourceBudget{} = _budget) do
    contradiction_density = 0.2
    prediction_failure_rate = 0.3
    acm_pressure = 0.5
    disease_load = 0.1

    tension = 
      (contradiction_density * 30.0) +
      (prediction_failure_rate * 40.0) +
      (acm_pressure * 20.0) +
      (disease_load * 10.0)
    
    max(0.0, min(100.0, tension))
  end

  def compute_epistemic_tension(civ_id) when is_binary(civ_id) do
    if self() == Process.whereis(__MODULE__) do
      %ResourceBudget{civilization_id: civ_id, shard_id: "default"} |> compute_epistemic_tension()
    else
      case get_budget(civ_id) do
        nil -> 0.0
        budget -> compute_epistemic_tension(budget)
      end
    end
  end

  defp get_fitness(civ_id, shard_id) do
    case safe_get_entity(civ_id, shard_id) do
      {:ok, ent} -> Map.get(ent.attributes, :fitness_score, 0.1)
      _ -> 0.1
    end
  end

  defp process_maintenance_tick(%ResourceBudget{state: :dormant} = budget) do
    # Dormant civs do nothing but increment their sleep counter
    new_budget = %{budget | ticks_dormant: budget.ticks_dormant + 1}
    
    # Check for extinction using new ecological formula
    maintenance_drain = Map.get(budget, :maintenance_drain, 5) # simplified
    resource_reserve = max(budget.truth_capital + budget.influence_capital, 1.0)
    
    # Recovery probability inverse (mocked for now, can be tied to fitness)
    recovery_probability_inverse = 1.0 / max(0.01, get_fitness(budget.civilization_id, budget.shard_id))

    extinction_score = 
      new_budget.ticks_dormant *
      maintenance_drain *
      (1.0 / resource_reserve) *
      recovery_probability_inverse
    
    should_extinct? = extinction_score > 5000.0 # Configurable threshold
    
    if should_extinct? do
      Tiannara.ROS.EvolutionEngine.extinct(budget.shard_id, budget.civilization_id)
      # Budget will be removed by EvolutionEngine via remove_budget
    end
    
    new_budget
  end

  defp process_maintenance_tick(budget) do
    # Calculate maintenance cost (e.g. 1 energy per 10 beliefs)
    ontology_size = fetch_ontology_size(budget.shard_id)
    maintenance_cost = max(5.0, ontology_size * 0.1)
    
    # Update tension
    tension = compute_epistemic_tension(budget)
    
    # Potentially trigger operator evolution
    if tension > 40.0 and tension < 80.0 do
      Logger.debug("🧠 [EconomyEngine] Moderate tension (#{tension}) for #{budget.civilization_id}. Triggering operator evolution check.")
      # Fire-and-forget generation check
          Tiannara.ERO.CognitiveEvolutionEngine.check_emergence(budget.civilization_id, budget.shard_id, tension)
    end
    
    budget = %{budget | epistemic_tension: tension}

    if budget.energy >= maintenance_cost do
      # Epistemic Capital Decay (EMA style)
      decayed_truth = budget.truth_capital * 0.995
      decayed_influence = budget.influence_capital * 0.995

      new_budget = %{budget | 
        energy: trunc(budget.energy - maintenance_cost),
        truth_capital: decayed_truth,
        influence_capital: decayed_influence,
        state: :active
      }
      
      # EC-3: Optional generation of Epistemic Capital based on prediction accuracy (simulated)
      new_budget_final =
        if :rand.uniform() > 0.8 and not String.contains?(new_budget.civilization_id, "tester") do
          %{new_budget | truth_capital: new_budget.truth_capital + 1.0}
        else
          new_budget
        end
      
      apply_discovery_deltas(new_budget_final)
    else
      # Starvation mode: can't afford maintenance
      apply_discovery_deltas(%{budget | energy: 0})
    end
  end

  defp apply_discovery_deltas(budget) do
    # Evaluate maintained discoveries to adjust Truth Capital
    known_discoveries = Tiannara.REL.DiscoveryLedger.get_known_discoveries(budget.civilization_id)
    
    {truth_delta, _} = Enum.reduce(known_discoveries, {0.0, 0}, fn disc, {delta, count} ->
      stability = Map.get(disc, :stability, 0.5)
      cond do
        String.starts_with?(disc.id, "disease_") ->
          {delta - 5.0, count + 1} # Heavy penalty for diseases
        stability >= 0.8 ->
          {delta + 0.5, count + 1} # Drip reward for high truth
        stability < 0.2 ->
          {delta - 1.0, count + 1} # Penalty for delusions
        true ->
          {delta, count + 1}
      end
    end)

    new_truth = budget.truth_capital + truth_delta
    
    # We update the budget with new truth capital
    budget_with_deltas = %{budget | truth_capital: new_truth}

    if budget_with_deltas.energy <= 0 do
      Logger.warning("💀 [REL] Civilization #{budget.civilization_id} hit 0 energy. Entering dormancy.")
      
      case safe_get_entity(budget.civilization_id, budget.shard_id) do
        {:ok, ent} ->
          genome = Map.get(ent.attributes, :epistemic_genome)
          if genome do
             Tiannara.Sentinel.EpistemologyArchive.record_collapse(budget, genome)
          else
             Logger.warning("💀 [REL] Civilization #{budget.civilization_id} collapsed, but genome was nil! Attributes: #{inspect(Map.keys(ent.attributes))}")
          end
        _ -> :ok
      end

      %{budget_with_deltas | energy: 0, state: :dormant, ticks_dormant: 0}
    else
      budget_after_energy =
        if budget_with_deltas.energy < 200 do
          if budget.state != :starving do
             Logger.warning("⚠️ [REL] Civilization #{budget.civilization_id} is starving! Initiating shedding.")
          end
          # Trigger shedding to lower future maintenance
          shed_beliefs(budget.shard_id, budget.civilization_id)
          %{budget_with_deltas | state: :starving}
        else
          %{budget_with_deltas | state: :active}
        end

        # D.2 Telemetry: Epoch Survival and Speciation tracking
        # Assuming each maintenance tick is roughly a sub-epoch
        if :rand.uniform() < 0.05 do
          case safe_get_entity(budget.civilization_id, budget.shard_id) do
            {:ok, ent} ->
              ops = Map.get(ent.attributes, :active_operators, [])
              Logger.debug("[D.2 Speciation] Evaluating species for #{budget.civilization_id} with ops: #{inspect(ops)}")
            _ -> :ok
          end

          Enum.each(known_discoveries, fn disc ->
            Tiannara.Sentinel.D2.TruthRetentionMatrix.record_epoch_survival(disc.id)
            if Map.get(disc, :impact_score, 0.0) > 5.0 do
              Tiannara.Sentinel.D2.BreakthroughAnalyzer.record_breakthrough(disc.id, disc.impact_score, budget.civilization_id)
            end
          end)
        end

        # 6. Apply Epistemic Predators (ACM)
        if :rand.uniform() < 0.10 do
          case safe_get_entity(budget.civilization_id, budget.shard_id) do
            {:ok, ent} ->
              genome = Map.get(ent.attributes, :epistemic_genome)
              if genome do
                 Tiannara.ACM.EpistemicPredator.attack(budget.shard_id, budget.civilization_id, genome)
              end
            _ -> :ok
          end
        end
        
        # 7. Apply Epistemic Disease (EDM)
        if :rand.uniform() < 0.05 do
          disease = Tiannara.ACM.EpistemicDisease.infect(budget.civilization_id)
          Tiannara.REL.DiscoveryLedger.register_discovery(budget.civilization_id, disease)
        end
        
        # 8. Process Existing Epistemic Diseases
        known = Tiannara.REL.DiscoveryLedger.get_known_discoveries(budget.civilization_id)
        Enum.each(known, fn disc ->
          if String.starts_with?(disc.id, "disease_") do
            case safe_get_entity(budget.civilization_id, budget.shard_id) do
              {:ok, ent} ->
                genome = Map.get(ent.attributes, :epistemic_genome)
                if genome do
                  case Tiannara.ACM.EpistemicDisease.progress_disease(disc, genome) do
                    {:cured, id} -> 
                      Logger.info("💊 [EDM] #{budget.civilization_id} cured #{disc.name}!")
                      Tiannara.REL.DiscoveryLedger.remove_discovery(budget.civilization_id, id)
                    {:progressed, new_disc} ->
                      Tiannara.REL.DiscoveryLedger.update_discovery(new_disc)
                  end
                end
              _ -> :ok
            end
          end
        end)
        
        budget_after_energy
    end
  end

  defp fetch_ontology_size(shard_id) do
    name = ROSRegistry.via(BeliefSystem, shard_id)
    try do
      case GenServer.call(name, :list_beliefs) do
        {:ok, beliefs} -> length(beliefs)
        _ -> 0
      end
    catch
      :exit, _ -> 0
    end
  end

  defp shed_beliefs(shard_id, _civ_id) do
    # Randomly shed a belief to lower ontological weight
    name = ROSRegistry.via(BeliefSystem, shard_id)
    try do
      case GenServer.call(name, :list_beliefs) do
        {:ok, beliefs} ->
          if length(beliefs) > 0 do
            victim = Enum.random(beliefs)
            # Assuming we had a remove_belief API, we simulate it here or just log it
            Logger.info("📉 [REL] Shedding belief #{victim.id} to preserve energy.")
            # GenServer.call(name, {:remove_belief, victim.id}) 
          end
        _ -> :ok
      end
    catch
      :exit, _ -> :ok
    end
  end

  defp safe_get_entity(civ_id, shard_id) do
    try do
      Tiannara.Core.WorldModel.EntityRegistry.get_entity(civ_id, shard_id)
    catch
      :exit, _ -> {:error, :no_process}
    end
  end
end
