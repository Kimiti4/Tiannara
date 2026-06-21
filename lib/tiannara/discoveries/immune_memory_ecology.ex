defmodule Tiannara.REA.Epistemic.ImmuneMemory do
  @derive {Jason.Encoder, only: [:pathogen_family, :detection_accuracy, :recovery_speed, :false_positive_rate, :last_seen_epoch, :adaptation_generation, :strategy_weights]}
  defstruct [
    :pathogen_family,
    :detection_accuracy,
    :recovery_speed,
    :false_positive_rate,
    :last_seen_epoch,
    :adaptation_generation,
    :strategy_weights # map of strategy name (atom) => weight (float)
  ]
end

defmodule Tiannara.REA.Epistemic.ImmuneStrategy do
  @derive {Jason.Encoder, only: [:name, :quarantine_threshold, :scrutiny_rate, :rollback_trigger_bounds, :rebalance_intensity, :fitness, :history]}
  defstruct [
    :name,
    :quarantine_threshold,
    :scrutiny_rate,
    :rollback_trigger_bounds,
    :rebalance_intensity,
    :fitness,
    :history
  ]
end

defmodule Tiannara.REA.Epistemic.ImmuneMemoryEcology do
  use GenServer
  alias Tiannara.REA.Epistemic.{ImmuneMemory, ImmuneStrategy}

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  # --- PUBLIC API ---

  def register_memory(%ImmuneMemory{} = memory) do
    GenServer.call(__MODULE__, {:register_memory, memory})
  end

  def get_memories do
    GenServer.call(__MODULE__, :get_memories)
  end

  def get_strategies do
    GenServer.call(__MODULE__, :get_strategies)
  end

  def best_strategy do
    GenServer.call(__MODULE__, :best_strategy)
  end

  @doc "Evaluates the fitness of active strategies and runs replicator dynamics on strategy weights."
  def evaluate_fitness(telemetry) do
    GenServer.call(__MODULE__, {:evaluate_fitness, telemetry})
  end

  @doc "Decays immune memory accuracy and recovery speed for unused profiles (Law P5)."
  def apply_drift_decay(current_epoch, drift_constant \\ 0.02) do
    GenServer.call(__MODULE__, {:apply_drift_decay, current_epoch, drift_constant})
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # --- CALLBACKS ---

  @impl true
  def init(_opts) do
    {:ok, default_state()}
  end

  @impl true
  def handle_call({:register_memory, memory}, _from, state) do
    new_m = Map.put(state.memories, memory.pathogen_family, memory)
    {:reply, :ok, %{state | memories: new_m}}
  end

  @impl true
  def handle_call(:get_memories, _from, state) do
    {:reply, Map.values(state.memories), state}
  end

  @impl true
  def handle_call(:get_strategies, _from, state) do
    {:reply, Map.values(state.strategies), state}
  end

  @impl true
  def handle_call(:best_strategy, _from, state) do
    best = Map.values(state.strategies) |> Enum.max_by(& &1.fitness, fn -> nil end)
    {:reply, best, state}
  end

  @impl true
  def handle_call({:evaluate_fitness, telemetry}, _from, state) do
    # 1. Update fitness of each strategy based on threat resolution and collateral damage
    updated_strategies =
      state.strategies
      |> Map.new(fn {name, strat} ->
        fitness = compute_strategy_fitness(name, telemetry)
        updated = %{strat | fitness: fitness, history: [fitness | Enum.take(strat.history || [], 19)]}
        {name, updated}
      end)

    # 2. Run replicator dynamics on strategy weights in each ImmuneMemory
    updated_memories =
      state.memories
      |> Map.new(fn {fam, mem} ->
        weights = mem.strategy_weights
        
        # Calculate numerator: weight * strategy_fitness
        weighted_fitness =
          Map.new(weights, fn {strat_name, w} ->
            f = Map.get(updated_strategies, strat_name).fitness
            {strat_name, w * max(0.01, f)}
          end)

        sum = Enum.sum(Map.values(weighted_fitness))

        new_weights =
          if sum > 0 do
            Map.new(weighted_fitness, fn {name, val} -> {name, val / sum} end)
          else
            weights
          end

        # Evolve detection accuracy slightly if this pathogen family was active and resolved
        fam_active? = Map.get(telemetry, :active_pathogen_family) == fam
        resolved? = Map.get(telemetry, :threat_resolved, false)

        new_acc =
          if fam_active? and resolved? do
            min(0.99, mem.detection_accuracy + 0.05)
          else
            mem.detection_accuracy
          end

        new_generation = if fam_active?, do: mem.adaptation_generation + 1, else: mem.adaptation_generation

        evolved_memory = %{
          mem |
          strategy_weights: new_weights,
          detection_accuracy: new_acc,
          adaptation_generation: new_generation,
          last_seen_epoch: if(fam_active?, do: Map.get(telemetry, :epoch, mem.last_seen_epoch), else: mem.last_seen_epoch)
        }

        {fam, evolved_memory}
      end)

    new_state = %{state | strategies: updated_strategies, memories: updated_memories}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:apply_drift_decay, current_epoch, drift_constant}, _from, state) do
    # Evolve memories: if a pathogen hasn't been seen for more than 10 epochs, decay its accuracy and recovery speed (Law P5)
    decayed_memories =
      state.memories
      |> Map.new(fn {fam, mem} ->
        epochs_since_seen = current_epoch - mem.last_seen_epoch
        
        if epochs_since_seen > 10 do
          decayed_acc = max(0.1, mem.detection_accuracy - drift_constant)
          decayed_rec = max(0.1, mem.recovery_speed - drift_constant)
          {fam, %{mem | detection_accuracy: decayed_acc, recovery_speed: decayed_rec}}
        else
          {fam, mem}
        end
      end)

    {:reply, :ok, %{state | memories: decayed_memories}}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, default_state()}
  end

  # --- PRIVATE HELPERS ---

  defp default_state do
    strategies = Map.new(default_strategies(), &{&1.name, &1})
    memories = Map.new(default_memories(), &{&1.pathogen_family, &1})
    %{
      strategies: strategies,
      memories: memories
    }
  end

  defp default_strategies do
    [
      %ImmuneStrategy{name: :aggressive_quarantine, quarantine_threshold: 0.3, scrutiny_rate: 0.9, rollback_trigger_bounds: %{integrity_limit: 0.35}, rebalance_intensity: 0.8, fitness: 1.0, history: []},
      %ImmuneStrategy{name: :conservative_quarantine, quarantine_threshold: 0.6, scrutiny_rate: 0.4, rollback_trigger_bounds: %{integrity_limit: 0.20}, rebalance_intensity: 0.3, fitness: 1.0, history: []},
      %ImmuneStrategy{name: :rollback_first, quarantine_threshold: 0.8, scrutiny_rate: 0.5, rollback_trigger_bounds: %{integrity_limit: 0.45}, rebalance_intensity: 0.1, fitness: 1.0, history: []},
      %ImmuneStrategy{name: :observation_first, quarantine_threshold: 0.9, scrutiny_rate: 0.1, rollback_trigger_bounds: %{integrity_limit: 0.10}, rebalance_intensity: 0.05, fitness: 1.0, history: []},
      %ImmuneStrategy{name: :rebalance_first, quarantine_threshold: 0.5, scrutiny_rate: 0.6, rollback_trigger_bounds: %{integrity_limit: 0.25}, rebalance_intensity: 0.9, fitness: 1.0, history: []}
    ]
  end

  defp default_memories do
    default_weights = %{
      aggressive_quarantine: 0.2,
      conservative_quarantine: 0.2,
      rollback_first: 0.2,
      observation_first: 0.2,
      rebalance_first: 0.2
    }

    [
      # Theory families
      %ImmuneMemory{pathogen_family: :authority_lock, detection_accuracy: 0.8, recovery_speed: 0.75, false_positive_rate: 0.1, last_seen_epoch: 0, adaptation_generation: 0, strategy_weights: default_weights},
      %ImmuneMemory{pathogen_family: :confirmation_collapse, detection_accuracy: 0.75, recovery_speed: 0.8, false_positive_rate: 0.08, last_seen_epoch: 0, adaptation_generation: 0, strategy_weights: default_weights},
      %ImmuneMemory{pathogen_family: :fitness_hacking, detection_accuracy: 0.85, recovery_speed: 0.7, false_positive_rate: 0.12, last_seen_epoch: 0, adaptation_generation: 0, strategy_weights: default_weights},
      
      # Portfolio families
      %ImmuneMemory{pathogen_family: :monoculture_capture, detection_accuracy: 0.9, recovery_speed: 0.85, false_positive_rate: 0.05, last_seen_epoch: 0, adaptation_generation: 0, strategy_weights: default_weights},
      %ImmuneMemory{pathogen_family: :dependency_cascade, detection_accuracy: 0.8, recovery_speed: 0.8, false_positive_rate: 0.07, last_seen_epoch: 0, adaptation_generation: 0, strategy_weights: default_weights},
      
      # Civilization families
      %ImmuneMemory{pathogen_family: :constitutional_erosion, detection_accuracy: 0.95, recovery_speed: 0.9, false_positive_rate: 0.02, last_seen_epoch: 0, adaptation_generation: 0, strategy_weights: default_weights}
    ]
  end

  defp compute_strategy_fitness(name, telemetry) do
    # Threat resolution rate
    threat_resolved = Map.get(telemetry, :threat_resolved, false)
    resolution_time = Map.get(telemetry, :resolution_time, 10.0) # Lower is better
    
    # Autoimmune collateral damage (lower yields or high CFR are bad)
    yield_drop = Map.get(telemetry, :yield_drop, 0.0)
    cfr = Map.get(telemetry, :cfr, 0.0)
    false_positives = Map.get(telemetry, :false_positives, 0.0)

    # Base values depending on the strategy name to provide default environmental niches
    base_fit =
      case name do
        :aggressive_quarantine -> if(threat_resolved, do: 0.8, else: 0.3)
        :conservative_quarantine -> if(threat_resolved, do: 0.7, else: 0.4)
        :rollback_first -> if(threat_resolved, do: 0.5, else: 0.2)
        :observation_first -> if(threat_resolved, do: 0.3, else: 0.6)
        :rebalance_first -> if(threat_resolved, do: 0.9, else: 0.5)
      end

    # Apply penalties
    penalty = (yield_drop * 0.4) + (cfr * 0.3) + (false_positives * 0.3)
    # Speed bonus: 1.0 / resolution_time
    speed_bonus = if(threat_resolved, do: 10.0 / max(1.0, resolution_time), else: 0.0)

    max(0.05, min(1.5, base_fit + speed_bonus - penalty))
  end
end
