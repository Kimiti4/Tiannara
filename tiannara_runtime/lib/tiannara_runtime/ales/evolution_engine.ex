defmodule TiannaraRuntime.ALES.EvolutionEngine do
  @moduledoc """
  Adaptive Law Evolution System (ALES) - Evolution Engine.

  Allows safety limits, critical thresholds, and regulatory equations to evolve
  adaptively. Rather than keeping them static, ALES registers system variables,
  proposes mutations, evaluates their fitness (survival time and outcomes),
  and promotes highly fit variants to prevent rigidity.
  """

  use GenServer
  require Logger

  @fitness_threshold 0.70
  @min_survival_ticks 100

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Register a system parameter or limit as an evolvable law.
  """
  def register_law(law_id, initial_value, range) when is_atom(law_id) and is_number(initial_value) and is_tuple(range) do
    GenServer.cast(__MODULE__, {:register, law_id, initial_value, range})
  end

  @doc """
  Propose a delta mutation for an evolvable law.
  """
  def propose_mutation(law_id, delta) when is_atom(law_id) and is_number(delta) do
    GenServer.call(__MODULE__, {:propose, law_id, delta})
  end

  @doc """
  Evaluate and record fitness of a parameter variant. Returns if the variant is promoted.
  """
  def evaluate_fitness(law_id, survival_ticks, outcome_metrics) when is_atom(law_id) and is_number(survival_ticks) do
    GenServer.call(__MODULE__, {:evaluate, law_id, survival_ticks, outcome_metrics})
  end

  @doc """
  Get active value of an evolvable law.
  """
  def get_active_value(law_id) do
    GenServer.call(__MODULE__, {:get_value, law_id})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    Logger.info("🧬 [ALES Evolution Engine] Initialized")
    {:ok, initial_state()}
  end

  @impl true
  def handle_cast({:register, law_id, initial_value, {min_val, max_val}}, state) do
    law = %{
      current_value: initial_value,
      min: min_val,
      max: max_val,
      variants: []
    }

    new_laws = Map.put(state.laws, law_id, law)
    {:noreply, %{state | laws: new_laws}}
  end

  @impl true
  def handle_cast(:reset, _state) do
    {:noreply, initial_state()}
  end

  @impl true
  def handle_call({:propose, law_id, delta}, _from, state) do
    case Map.get(state.laws, law_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      law ->
        new_val = max(law.min, min(law.max, law.current_value + delta))
        variant = %{value: new_val, delta: delta, fitness: 0.0, status: :observing}

        # Keep last 3 variants
        updated_variants = Enum.take([variant | law.variants], 3)
        updated_law = %{law | variants: updated_variants}

        Logger.info("🧬 [ALES] Proposed mutation for #{law_id}: #{law.current_value} -> #{new_val}")
        {:reply, {:ok, new_val}, %{state | laws: Map.put(state.laws, law_id, updated_law)}}
    end
  end

  @impl true
  def handle_call({:evaluate, law_id, survival_ticks, outcome_metrics}, _from, state) do
    case Map.get(state.laws, law_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      law ->
        survival_score = min(1.0, survival_ticks / @min_survival_ticks)
        stability = Map.get(outcome_metrics, :stability, 1.0)
        coherence = Map.get(outcome_metrics, :coherence, 1.0)
        outcome_quality = (stability + coherence) / 2.0

        fitness = survival_score * outcome_quality

        # If fitness is high, promote the newest variant to be the current law value
        {status, final_val, updated_variants} =
          case law.variants do
            [newest | rest] ->
              if fitness >= @fitness_threshold do
                Logger.info("🎉 [ALES] Law #{law_id} variant promoted to active: #{newest.value} (fitness: #{Float.round(fitness, 4)})")
                {:promoted, newest.value, [%{newest | fitness: fitness, status: :promoted} | rest]}
              else
                {:retained, law.current_value, [%{newest | fitness: fitness, status: :failed} | rest]}
              end

            [] ->
              {:retained, law.current_value, []}
          end

        updated_law = %{law | current_value: final_val, variants: updated_variants}
        {:reply, {:ok, status, final_val}, %{state | laws: Map.put(state.laws, law_id, updated_law)}}
    end
  end

  @impl true
  def handle_call({:get_value, law_id}, _from, state) do
    case Map.get(state.laws, law_id) do
      nil -> {:reply, {:error, :not_found}, state}
      law -> {:reply, {:ok, law.current_value}, state}
    end
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, initial_state()}
  end

  # ==================== Helper Functions ====================

  defp initial_state do
    %{
      laws: %{}
    }
  end
end
