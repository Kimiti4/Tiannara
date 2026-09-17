defmodule Tiannara.Meta.TestHelpers do
  @moduledoc """
  Test helpers for Phase 5F.2 Observer Collapse Governor integration tests.
  
  Provides utilities for:
  - Creating realistic observer manifolds
  - Simulating CTN interference patterns
  - Generating test scenarios
  - Validating OSS computations
  """
  
  @doc """
  Creates a realistic observer manifold with specified stability characteristics.
  
  ## Parameters
  - `stability`: :dominant | :stable | :marginal | :unstable
  - `interference_level`: :low | :medium | :high
  
  ## Returns
  A map representing an observer manifold ready for OCG/OCAL testing
  """
  def create_observer(observer_id, stability \\ :stable, interference_level \\ :medium) do
    base_values = case stability do
      :dominant ->
        %{coherence: 0.85, msf: 0.80, prediction: 0.90}
      :stable ->
        %{coherence: 0.75, msf: 0.70, prediction: 0.80}
      :marginal ->
        %{coherence: 0.55, msf: 0.50, prediction: 0.60}
      :unstable ->
        %{coherence: 0.20, msf: 0.15, prediction: 0.25}
    end
    
    interference = case interference_level do
      :low -> 0.15
      :medium -> 0.35
      :high -> 0.80
    end
    
    Map.merge(base_values, %{
      observer_id: observer_id,
      interference: interference,
      causality_graph: generate_causality_graph(stability),
      time_vector: generate_time_vector(),
      physics_compiler: Enum.random(["GLSL", "WASM", "HybridDSL"]),
      entropy_field: generate_entropy_field(stability),
      ctn_interference: generate_ctn_field(interference_level)
    })
  end
  
  @doc """
  Creates a pair of observers designed to trigger specific arbitration outcomes.
  
  ## Outcomes
  - `:merge` - Similar OSS, high interference
  - `:suppress` - Different OSS, both stable
  - `:collapse` - One stable, one critically unstable
  """
  def create_arbitration_pair(outcome) do
    case outcome do
      :merge ->
        {
          create_observer("merge_a", :stable, :high),
          create_observer("merge_b", :stable, :high)
        }
      
      :suppress ->
        {
          create_observer("suppress_high", :dominant, :low),
          create_observer("suppress_low", :marginal, :medium)
        }
      
      :collapse ->
        {
          create_observer("collapse_stable", :dominant, :low),
          create_observer("collapse_unstable", :unstable, :high)
        }
    end
  end
  
  @doc """
  Generates a population of observers for ecosystem simulation.
  
  ## Parameters
  - `count`: Number of observers to create
  - `distribution`: Mix of stability levels
  
  ## Returns
  List of observer maps
  """
  def create_observer_population(count, distribution \\ :mixed) do
    stabilities = case distribution do
      :mixed -> [:dominant, :stable, :stable, :marginal, :unstable]
      :stable -> [:stable, :stable, :dominant]
      :chaotic -> [:unstable, :marginal, :unstable]
    end
    
    for i <- 1..count do
      stability = Enum.random(stabilities)
      interference = Enum.random([:low, :medium, :high])
      create_observer("pop_#{i}", stability, interference)
    end
  end
  
  @doc """
  Calculates expected OSS for an observer given its parameters.
  
  Formula: OSS = (coherence × msf × prediction) / (interference + ε)
  """
  def expected_oss(observer) do
    coherence = Map.get(observer, :coherence, 0.5)
    msf = Map.get(observer, :msf, 0.5)
    prediction = Map.get(observer, :prediction, 0.5)
    interference = Map.get(observer, :interference, 0.5)
    
    raw = (coherence * msf * prediction) / (interference + 0.001)
    min(raw, 1.0)
  end
  
  @doc """
  Validates that an observer map has all required fields.
  """
  def validate_observer(observer) do
    required_fields = [:observer_id, :coherence, :msf, :prediction, :interference]
    
    missing = Enum.filter(required_fields, fn field ->
      not Map.has_key?(observer, field)
    end)
    
    if Enum.empty?(missing) do
      :ok
    else
      {:error, "Missing fields: #{inspect(missing)}"}
    end
  end
  
  @doc """
  Simulates CTN interference between two observers.
  
  Returns interference density value (0.0 - 1.0)
  """
  def simulate_ctn_interference(observer_a, observer_b) do
    # Simplified model: interference based on field overlap
    ctn_a = Map.get(observer_a, :ctn_interference, [])
    ctn_b = Map.get(observer_b, :ctn_interference, [])
    
    if Enum.empty?(ctn_a) or Enum.empty?(ctn_b) do
      0.3  # Default moderate interference
    else
      # Calculate overlap as average of element-wise products
      len = min(length(ctn_a), length(ctn_b))
      a_slice = Enum.take(ctn_a, len)
      b_slice = Enum.take(ctn_b, len)
      
      overlap = Enum.zip(a_slice, b_slice)
                |> Enum.map(fn {a, b} -> a * b end)
                |> Enum.sum()
      
      min(overlap / len, 1.0)
    end
  end
  
  @doc """
  Creates a chimera observer from two parents (for testing merge outcomes).
  """
  def create_chimera(parent_a, parent_b, blend_weight \\ 0.5) do
    chimera_id = "CHIMERA-#{parent_a.observer_id}-#{parent_b.observer_id}"
    
    %{
      observer_id: chimera_id,
      coherence: blend_scalar(parent_a.coherence, parent_b.coherence, blend_weight),
      msf: blend_scalar(parent_a.msf, parent_b.msf, blend_weight),
      prediction: blend_scalar(parent_a.prediction, parent_b.prediction, blend_weight),
      interference: max(parent_a.interference, parent_b.interference),
      causality_graph: merge_causality_graphs(parent_a.causality_graph, parent_b.causality_graph),
      time_vector: blend_vectors(parent_a.time_vector, parent_b.time_vector, blend_weight),
      physics_compiler: if(parent_a.msf >= parent_b.msf, do: parent_a.physics_compiler, else: parent_b.physics_compiler),
      entropy_field: blend_vectors(parent_a.entropy_field, parent_b.entropy_field, blend_weight),
      ctn_interference: superpose_fields(parent_a.ctn_interference, parent_b.ctn_interference),
      chimera: true,
      parent_ids: [parent_a.observer_id, parent_b.observer_id]
    }
  end
  
  # Private helper functions
  
  defp generate_causality_graph(:unstable) do
    # Unstable observers have cyclic graphs
    [
      %{from: "A", to: "B", weight: 0.8},
      %{from: "B", to: "C", weight: 0.7},
      %{from: "C", to: "A", weight: 0.9}  # Cycle!
    ]
  end
  
  defp generate_causality_graph(_) do
    # Stable observers have acyclic graphs
    [
      %{from: "A", to: "B", weight: 0.8},
      %{from: "B", to: "C", weight: 0.7}
    ]
  end
  
  defp generate_time_vector do
    # Random normalized 3D vector
    v = for _ <- 1..3, do: :rand.uniform() - 0.5
    norm = :math.sqrt(Enum.sum(Enum.map(v, &(&1 * &1))))
    Enum.map(v, &(&1 / (norm + 0.001)))
  end
  
  defp generate_entropy_field(:unstable) do
    # High entropy variance
    for _ <- 1..5, do: 0.5 + (:rand.uniform() - 0.5) * 0.8
  end
  
  defp generate_entropy_field(_) do
    # Low entropy variance
    for _ <- 1..5, do: 0.5 + (:rand.uniform() - 0.5) * 0.3
  end
  
  defp generate_ctn_field(:high) do
    # Strong CTN interference pattern
    for _ <- 1..4, do: 0.7 + :rand.uniform() * 0.3
  end
  
  defp generate_ctn_field(:medium) do
    for _ <- 1..4, do: 0.4 + :rand.uniform() * 0.4
  end
  
  defp generate_ctn_field(:low) do
    for _ <- 1..4, do: 0.1 + :rand.uniform() * 0.2
  end
  
  defp blend_scalar(a, b, w) when is_number(a) and is_number(b) do
    a * w + b * (1.0 - w)
  end
  
  defp blend_vectors(vec_a, vec_b, w) when is_list(vec_a) and is_list(vec_b) do
    max_len = max(length(vec_a), length(vec_b))
    a_pad = vec_a ++ List.duplicate(0.0, max_len - length(vec_a))
    b_pad = vec_b ++ List.duplicate(0.0, max_len - length(vec_b))
    
    Enum.zip(a_pad, b_pad)
    |> Enum.map(fn {va, vb} -> va * w + vb * (1.0 - w) end)
  end
  
  defp merge_causality_graphs(graph_a, graph_b) do
    graph_a ++ graph_b
  end
  
  defp superpose_fields(field_a, field_b) when is_list(field_a) and is_list(field_b) do
    max_len = max(length(field_a), length(field_b))
    a_pad = field_a ++ List.duplicate(0.0, max_len - length(field_a))
    b_pad = field_b ++ List.duplicate(0.0, max_len - length(field_b))
    
    Enum.zip(a_pad, b_pad)
    |> Enum.map(fn {a, b} -> a + b * 0.5 end)
  end
end
