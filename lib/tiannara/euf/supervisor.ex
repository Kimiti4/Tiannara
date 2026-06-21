defmodule Tiannara.EUF.Supervisor do
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_) do
    {:ok, %{ontologies: %{}, observer_consensus: %{}, theory_survival: %{}, config: %{consensus_threshold: 0.7}}}
  end

  def register_ontology(ontology_id, concepts) do
    GenServer.cast(__MODULE__, {:register_ontology, ontology_id, concepts})
  end

  def record_observer_belief(observer_id, concept_id, confidence) do
    GenServer.cast(__MODULE__, {:record_belief, observer_id, concept_id, confidence})
  end

  def evaluate_theory(theory_id, test_results) do
    GenServer.call(__MODULE__, {:evaluate_theory, theory_id, test_results})
  end

  def get_ontology_confidence(ontology_id) do
    GenServer.call(__MODULE__, {:get_confidence, ontology_id})
  end

  def handle_cast({:register_ontology, ontology_id, concepts}, state) do
    metrics = %{ontology_id: ontology_id, concept_count: length(concepts), avg_confidence: 0.5}
    new_ontologies = Map.put(state.ontologies, ontology_id, metrics)
    Logger.info("EUF: Registered ontology #{ontology_id}")
    {:noreply, %{state | ontologies: new_ontologies}}
  end

  def handle_cast({:record_belief, observer_id, concept_id, confidence}, state) do
    beliefs = Map.get(state.observer_consensus, concept_id, [])
    new_belief = {observer_id, confidence}
    recent_beliefs = [new_belief | Enum.take(beliefs, 99)]
    new_consensus = Map.put(state.observer_consensus, concept_id, recent_beliefs)
    {:noreply, %{state | observer_consensus: new_consensus}}
  end

  def handle_call({:evaluate_theory, theory_id, test_results}, _from, state) do
    successes = Enum.count(test_results, fn {_, passed} -> passed end)
    success_rate = if Enum.empty?(test_results), do: 0.0, else: successes / length(test_results)
    existing = Map.get(state.theory_survival, theory_id, [])
    new_entry = %{theory_id: theory_id, success_rate: success_rate, test_count: length(test_results)}
    new_history = [new_entry | existing]
    result = %{theory_id: theory_id, success_rate: success_rate, age_ticks: length(existing), confidence: success_rate}
    {:reply, {:ok, result}, %{state | theory_survival: Map.put(state.theory_survival, theory_id, new_history)}}
  end

  def handle_call({:get_confidence, ontology_id}, _from, state) do
    ontology = Map.get(state.ontologies, ontology_id)
    if is_nil(ontology) do
      {:reply, {:error, :not_found}, state}
    else
      all_confidences = state.observer_consensus |> Enum.flat_map(fn {_, beliefs} -> Enum.map(beliefs, fn {_, conf} -> conf end) end)
      confidence = if Enum.empty?(all_confidences), do: 0.5, else: Enum.sum(all_confidences) / length(all_confidences)
      result = %{ontology_id: ontology_id, epistemic_confidence: confidence, observer_count: length(all_confidences)}
      {:reply, {:ok, result}, state}
    end
  end
end
