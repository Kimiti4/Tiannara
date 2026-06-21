defmodule Tiannara.REA.MetaMemoryTensor do
  @derive Jason.Encoder
  defstruct [
    :successful_species,      # list of strings (species IDs)
    :failed_species,          # list of strings
    :selection_history,       # list of maps tracking generations
    :world_contexts,          # list of context maps: %{volatility: float, complexity: float}
    :confidence_scores,       # map of species_id => float (0.0 to 1.0)
    :transferability_scores,  # map of species_id => float (0.0 to 1.0)
    :trust_weights            # map of species_id => float (0.0 to 1.0)
  ]
end

defmodule Tiannara.REA.MetaMemoryExtractor do
  @moduledoc """
  Builds Meta-Memory Tensors from Orbit Memory Ecology population archives.
  Tracks species performance, extinction thresholds, and historical success.
  """

  alias Tiannara.REA.MetaMemoryTensor

  @doc """
  Extracts memory meta-data from a list of species to initialize a MetaMemoryTensor.
  """
  def extract(species_list) do
    # Group species by performance
    successful =
      species_list
      |> Enum.filter(fn s -> s.fitness >= 0.70 and s.population > 30 end)
      |> Enum.map(& &1.species_id)

    failed =
      species_list
      |> Enum.filter(fn s -> s.fitness < 0.40 or s.extinction_risk >= 0.70 end)
      |> Enum.map(& &1.species_id)

    # Base scores
    confidences = Map.new(species_list, & {&1.species_id, &1.mpp})
    transferabilities = Map.new(species_list, & {&1.species_id, &1.functor_retention})
    
    # Initialize trust weights equally at 0.50, except root or known strong/weak ones
    trusts =
      Map.new(species_list, fn s ->
        initial_trust =
          cond do
            s.species_id in successful -> 0.75
            s.species_id in failed -> 0.15
            true -> 0.50
          end
        {s.species_id, initial_trust}
      end)

    contexts = [
      %{volatility: 0.10, complexity: 0.60, label: "Stable Basin"},
      %{volatility: 0.35, complexity: 0.80, label: "High Volatility Shift"},
      %{volatility: 0.05, complexity: 0.90, label: "High Complexity Matrix"}
    ]

    %MetaMemoryTensor{
      successful_species: successful,
      failed_species: failed,
      selection_history: [],
      world_contexts: contexts,
      confidence_scores: confidences,
      transferability_scores: transferabilities,
      trust_weights: trusts
    }
  end
end

defmodule Tiannara.REA.MetaMemoryLearner do
  @moduledoc """
  Implements Law MM1 (Trust Formation), Law MM2 (Obsolete Forgetting), and Law MM3 (Meta-Transfer).
  """

  @doc """
  Learns from feedback: updates trust weights based on success or failure outcomes (Law MM1).
  """
  def learn(tensor, species_id, context, success?) do
    current_trust = Map.get(tensor.trust_weights, species_id, 0.50)
    current_conf = Map.get(tensor.confidence_scores, species_id, 0.50)

    # Adjust trust based on performance feedback
    {new_trust, new_conf} =
      if success? do
        # Growth: P(Success | Species, Context) increases trust
        learning_rate = 0.15
        t = current_trust + learning_rate * (1.0 - current_trust)
        c = min(1.0, current_conf + 0.05)
        {Float.round(t, 4), Float.round(c, 4)}
      else
        # Penalty: failed execution decreases trust
        penalty_rate = 0.20
        t = max(0.01, current_trust - penalty_rate * current_trust)
        c = max(0.01, current_conf - 0.10)
        {Float.round(t, 4), Float.round(c, 4)}
      end

    # Update successful/failed lists dynamically
    updated_success =
      if success? and species_id not in tensor.successful_species do
        [species_id | tensor.successful_species]
      else
        tensor.successful_species
      end

    updated_failed =
      if not success? and species_id not in tensor.failed_species do
        [species_id | tensor.failed_species]
      else
        tensor.failed_species
      end

    updated_success = if not success?, do: List.delete(updated_success, species_id), else: updated_success
    updated_failed = if success?, do: List.delete(updated_failed, species_id), else: updated_failed

    # Update contexts log
    updated_contexts = [context | tensor.world_contexts] |> Enum.uniq() |> Enum.take(10)

    %{tensor |
      trust_weights: Map.put(tensor.trust_weights, species_id, new_trust),
      confidence_scores: Map.put(tensor.confidence_scores, species_id, new_conf),
      successful_species: updated_success,
      failed_species: updated_failed,
      world_contexts: updated_contexts
    }
  end

  @doc """
  Implements Law MM2: Forgetting. Obsolete memories decay in trust over time when not active.
  """
  def decay_trust(tensor, species_id, decay_factor \\ 0.05) do
    current_trust = Map.get(tensor.trust_weights, species_id, 0.50)
    new_trust = Float.round(max(0.01, current_trust * (1.0 - decay_factor)), 4)

    %{tensor |
      trust_weights: Map.put(tensor.trust_weights, species_id, new_trust)
    }
  end

  @doc """
  Implements Law MM3: Meta-Transfer. Transfers trust in a memory across mismatching worlds.
  Adjusts trust by target world coordinate scaling factors.
  """
  def transfer_trust(tensor, species_id, target_world_scale) do
    current_trust = Map.get(tensor.trust_weights, species_id, 0.50)
    trans_factor = Map.get(tensor.transferability_scores, species_id, 0.50)

    # Trust translates successfully proportional to the transferability score
    transferred_trust = Float.round(current_trust * trans_factor * target_world_scale, 4)

    %{tensor |
      trust_weights: Map.put(tensor.trust_weights, species_id, transferred_trust)
    }
  end
end

defmodule Tiannara.REA.MetaMemoryPredictor do
  @moduledoc """
  Predicts which memory species should be used before execution.
  Implements Law MM4 (Meta-Generalization) and Law MM5 (Meta-Learning).
  """

  @doc """
  Recommends the best memory species for a given world context.
  Context format: %{volatility: float, complexity: float}
  """
  def recommend(tensor, context) do
    volatility = Map.get(context, :volatility, 0.10)
    complexity = Map.get(context, :complexity, 0.50)

    # Generalists favored under high volatility or multi-domain environments
    # Specialists favored under low volatility, high complexity environments
    recommended_species =
      if volatility >= 0.25 do
        # Recommend generalist species
        "generalist_species_upsilon"
      else
        # Recommend specialist species
        if complexity >= 0.70 do
          "specialist_species_sigma"
        else
          "stability_species_alpha"
        end
      end

    # Retrieve current trust
    base_trust = Map.get(tensor.trust_weights, recommended_species, 0.50)
    
    # Predict confidence score combining trust weight and context suitability
    confidence = 
      if volatility >= 0.25 do
        base_trust * (1.0 - (volatility - 0.25) * 0.4)
      else
        base_trust * (1.0 - complexity * 0.2)
      end

    %{
      recommended_species: recommended_species,
      confidence: Float.round(max(0.10, min(0.99, confidence)), 4)
    }
  end
end

defmodule Tiannara.REA.MetaMemoryCurriculum do
  @moduledoc """
  Manages reusable adaptation knowledge mapping.
  """

  @doc """
  Generates a graph representing the adaptation knowledge curriculum.
  """
  def get_adaptation_knowledge_graph(tensor) do
    # Define Nodes
    nodes = [
      %{id: "volatile_env", label: "Volatile Environment (V >= 0.25)", type: :context},
      %{id: "stable_env", label: "Stable Environment (V < 0.25)", type: :context},
      %{id: "generalist_strategy", label: "Generalist Strategy (Upsilon)", type: :strategy},
      %{id: "specialist_strategy", label: "Specialist Strategy (Sigma)", type: :strategy},
      %{id: "stability_strategy", label: "Stability Strategy (Alpha)", type: :strategy}
    ]

    # Calculate weights dynamically based on current trust weights
    w_upsilon = Map.get(tensor.trust_weights, "generalist_species_upsilon", 0.50)
    w_sigma = Map.get(tensor.trust_weights, "specialist_species_sigma", 0.50)
    w_alpha = Map.get(tensor.trust_weights, "stability_species_alpha", 0.50)

    edges = [
      %{from: "volatile_env", to: "generalist_strategy", weight: w_upsilon, label: "Highly Trusted"},
      %{from: "stable_env", to: "specialist_strategy", weight: w_sigma, label: "Optimal for Complexity"},
      %{from: "stable_env", to: "stability_strategy", weight: w_alpha, label: "Baseline Safe"}
    ]

    %{
      nodes: nodes,
      edges: edges
    }
  end
end
