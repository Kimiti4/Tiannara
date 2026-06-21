defmodule Tiannara.Sentinel.EpistemologyRecord do
  defstruct [
    civilization_id: nil,
    genome: nil,
    discoveries: [],
    prediction_accuracy: 0.0,
    acm_survival_rate: 0.0,
    disease_resistance: 0.0,
    lineage_depth: 0,
    continuity_score: 0.0,
    collapse_signature: nil,
    fitness_score: 0.0,
    truth_retention_score: 0.0,
    operators: []
  ]
end

defmodule Tiannara.Sentinel.EpistemologyArchive do
  @moduledoc """
  SEA-1: The core historian of civilizational cognition.
  Records EpistemologyRecords when civilizations collapse.
  Computes collapse signatures based on objective REL facts.
  """
  use GenServer
  require Logger

  alias Tiannara.Sentinel.EpistemologyRecord

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Records a civilization's collapse and archives its epistemology."
  def record_collapse(budget, genome, operators \\ []) do
    GenServer.cast(__MODULE__, {:record_collapse, budget, genome, operators})
  end
  
  @doc "Retrieves all archived records."
  def get_all_records do
    GenServer.call(__MODULE__, :get_all_records)
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting Sentinel Epistemology Archive (SEA)")
    {:ok, %{records: []}}
  end

  @impl true
  def handle_call(:get_all_records, _from, state) do
    {:reply, state.records, state}
  end

  @impl true
  def handle_cast({:record_collapse, budget, genome, operators}, state) do
    civ_id = budget.civilization_id
    discoveries = Tiannara.REL.DiscoveryLedger.get_known_discoveries(civ_id)
    stable = Enum.count(discoveries, fn d -> Map.get(d, :stability, 0.5) >= 0.8 end)
    unstable = length(discoveries) - stable
    disease_count = Enum.count(discoveries, fn d -> String.starts_with?(d.id, "disease_") end)
    
    outcome = %Tiannara.REL.EconomicOutcome{
      civilization_id: civ_id,
      shard_id: budget.shard_id,
      energy: 0,
      dormant: true,
      unstable_discoveries: unstable,
      stable_discoveries: stable,
      compute_wasted: 0,
      prediction_accuracy: 0.1,
      disease_count: disease_count,
      age: 100
    }
    
    signature = compute_collapse_signature(outcome)
    
    record = %EpistemologyRecord{
      civilization_id: outcome.civilization_id,
      genome: genome,
      discoveries: discoveries,
      prediction_accuracy: outcome.prediction_accuracy,
      acm_survival_rate: 0.0,
      disease_resistance: 0.0,
      lineage_depth: 1,
      continuity_score: 1.0,
      collapse_signature: signature,
      fitness_score: 0.0,
      truth_retention_score: compute_truth_retention(discoveries),
      operators: operators
    }
    
    Logger.info("🏛️ [SEA] Archived collapse of #{outcome.civilization_id}. Operators: #{inspect(operators)}. Signature: #{signature}")
    
    {:noreply, %{state | records: [record | state.records]}}
  end

  # --- Interpretation Logic ---
  
  defp compute_collapse_signature(outcome) do
    total_discoveries = outcome.stable_discoveries + outcome.unstable_discoveries
    
    cond do
      outcome.disease_count > 2 ->
        :epistemic_disease
        
      total_discoveries > 0 and (outcome.unstable_discoveries / total_discoveries) > 0.75 and outcome.prediction_accuracy < 0.3 ->
        :infinite_novelty_spiral
        
      total_discoveries < 2 and outcome.age > 100 ->
        :conservative_lock_in
        
      outcome.compute_wasted > 5000 ->
        :acm_predator_exhaustion
        
      true ->
        :resource_exhaustion
    end
  end
  
  defp compute_truth_retention(discoveries) do
    if length(discoveries) == 0 do
      0.0
    else
      stable_count = Enum.count(discoveries, fn d -> Map.get(d, :stability, 0.5) >= 0.8 end)
      stable_count / length(discoveries)
    end
  end
end
