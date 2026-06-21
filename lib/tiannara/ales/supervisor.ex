defmodule Tiannara.ALES.Supervisor do
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_) do
    {:ok, %{laws: %{}, law_history: [], fitness_scores: %{}, config: %{min_survival_time: 1000, fitness_threshold: 0.7}}}
  end

  def register_evolvable_law(law_id, initial_value, {min_val, max_val}) do
    GenServer.cast(__MODULE__, {:register_law, law_id, initial_value, min_val, max_val})
  end

  def propose_law_mutation(law_id, mutation_delta) do
    GenServer.cast(__MODULE__, {:propose_mutation, law_id, mutation_delta})
  end

  def evaluate_law_fitness(law_id, survival_time, metrics) do
    GenServer.call(__MODULE__, {:evaluate_fitness, law_id, survival_time, metrics})
  end

  def handle_cast({:register_law, law_id, initial_value, min_val, max_val}, state) do
    law = %{law_id: law_id, current_value: initial_value, min: min_val, max: max_val, variants: []}
    Logger.info("ALES: Registered evolvable law #{law_id}")
    {:noreply, %{state | laws: Map.put(state.laws, law_id, law)}}
  end

  def handle_cast({:propose_mutation, law_id, delta}, state) do
    law = Map.get(state.laws, law_id)
    if is_nil(law) do
      {:noreply, state}
    else
      new_value = max(law.min, min(law.max, law.current_value + delta))
      variant = %{law_id: law_id, value: new_value, delta: delta, fitness: 0.0, status: :running}
      new_variants = Enum.take([variant | law.variants], 3)
      updated_law = %{law | variants: new_variants}
      Logger.info("ALES: Proposed mutation for #{law_id}: #{law.current_value} -> #{new_value}")
      {:noreply, %{state | laws: Map.put(state.laws, law_id, updated_law)}}
    end
  end

  def handle_call({:evaluate_fitness, law_id, survival_time, metrics}, _from, state) do
    law = Map.get(state.laws, law_id)
    if is_nil(law) do
      {:reply, {:error, :not_found}, state}
    else
      surviv_score = min(1.0, survival_time / state.config.min_survival_time)
      outcome_quality = Map.get(metrics, :stability, 0.5) * 0.5 + Map.get(metrics, :coherence, 0.5) * 0.5
      fitness = surviv_score * outcome_quality
      status = if fitness > state.config.fitness_threshold, do: :promoted, else: :under_observation
      result = %{law_id: law_id, fitness: fitness, status: status}
      {:reply, {:ok, result}, state}
    end
  end
end
