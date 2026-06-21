defmodule Tiannara.ASC.Crucible.TransferEcology do
  @moduledoc """
  Transfer Ecology — observes, tracks, and analyzes cross-project knowledge transfer.

  Transforms transfer from isolated events into an ecological system that can be:
  - Studied (success matrix)
  - Measured (diffusion rates)
  - Used for law discovery (transfer-based candidate laws)

  Tracks:
  - Transfer success matrix (source × target classification)
  - Classification transferability scores
  - Knowledge diffusion rates
  - Semantic distance distributions
  - Repair lineage transferability
  """

  use GenServer

  alias Tiannara.ASC.Crucible.{TransferObservation, TransferMatrix, KnowledgeDiffusion, TransferAdaptation}
  alias Tiannara.ASC.Laws.QueryEngine
  alias Tiannara.ASC.Crucible.SpeciesFitness  # Phase 5C.6 - Species fitness tracking

  defstruct [
    observations: [],
    transfer_matrix: %{},
    strategy_efficiency: %{},
    classification_transferability: %{},
    semantic_distance_buckets: %{
      "0.0-0.2" => %{attempts: 0, successes: 0},
      "0.2-0.4" => %{attempts: 0, successes: 0},
      "0.4-0.6" => %{attempts: 0, successes: 0},
      "0.6-0.8" => %{attempts: 0, successes: 0},
      "0.8-1.0" => %{attempts: 0, successes: 0}
    },
    total_attempts: 0,
    total_successes: 0,
    aborted_attempts: 0,
    started_at: nil,
    # Phase 5C.3 - Ecological Diversity Metrics
    source_classifications: MapSet.new(),
    target_classifications: MapSet.new(),
    same_class_transfers: 0,
    cross_class_transfers: 0,
    cross_class_successes: 0,
    # Phase 5C.4 - Domain Entropy Tracking
    domain_distribution: %{},
    # Phase 5C.6 - Species Ecology Tracking
    species_births: %{},           # %{species_id => count}
    species_survivals: %{},        # %{species_id => count}
    species_extinctions: %{},      # %{species_id => count}
    species_repairs_attempted: %{}, # %{species_id => count}
    species_repairs_successful: %{}, # %{species_id => count}
    species_transfers_attempted: %{}, # %{species_id => count}
    species_transfers_successful: %{}, # %{species_id => count}
    species_fitness_scores: %{},   # %{species_id => fitness_score}
    current_species_budgets: %{}   # %{species_id => budget_percentage}
  ]

  @law_min_support 10 # Minimum events required to mint a candidate Law

  # ---------------------------------------------------------------------------
  # Phase 5F: Active Hypothesis Testing (Experiment Designer API)
  # ---------------------------------------------------------------------------

  @doc """
  Phase 5F: Exposes the statistical gaps in the transfer matrix 
  to allow the ExperimentDesigner to target weak hypotheses.
  """
  def get_hypothesis_gaps do
    GenServer.call(__MODULE__, :get_hypothesis_gaps)
  end


  @doc """
  Start the Transfer Ecology observer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %__MODULE__{started_at: DateTime.utc_now()}, name: __MODULE__)
  end

  @doc """
  Record a transfer observation.

  Every transfer attempt becomes a first-class scientific observation.
  """
  def record_observation(observation) do
    GenServer.call(__MODULE__, {:record_observation, observation}, 5000)
  end

  @doc """
  Phase 8B: Target function for Reality Anchoring optimization.
  """
  def get_events_by_domain(_domain) do
    # Intentionally slow unoptimized lookup for Phase 8B benchmark
    Enum.reduce(1..100, [], fn x, acc -> [x | acc] end)
  end

  @doc """
  Phase 5G: Attempts a transfer, but first consults the Epistemic Router.
  If the laws of physics dictate the transfer is doomed, it aborts early 
  to conserve compute cycles.
  """
  def attempt_transfer_with_routing(source_pattern, target_failure) do
    context = build_transfer_context(source_pattern, target_failure)
    
    result = QueryEngine.evaluate_transfer(context)
    case result.viability do
      :doomed ->
        record_aborted_transfer(context, result.penalties)
        {:aborted, result.penalties}
        
      :viable ->
        execute_organic_transfer(source_pattern, target_failure)
    end
  end

  defp build_transfer_context(source, target) do
    src_domain = get_in(source, [Access.key(:failure_classification, %{}), Access.key(:domain)]) || :unknown
    tgt_domain = get_in(target, [Access.key(:domain)]) || :unknown
    
    mock_obs = %{origin: :implementation, evidence: Map.get(target, :evidence, "")}
    target_class = try do
      Tiannara.ASC.Crucible.FailureClassifier.classify(mock_obs)
    rescue
      _ -> %{domain: tgt_domain, category: :unknown, subcategory: :unknown}
    end

    %{
      source_domain: src_domain,
      target_domain: target_class.domain,
      semantic_distance: TransferAdaptation.semantic_distance(source.failure_classification || %{domain: :unknown, category: :unknown, subcategory: :unknown}, target_class),
      target_constraints: target.constraints || []
    }
  end

  defp record_aborted_transfer(_context, _reasons) do
    GenServer.cast(__MODULE__, :record_aborted)
  end

  defp execute_organic_transfer(source, target) do
    case TransferAdaptation.attempt_transfer(source, target, "routing_campaign") do
      {:ok, record} ->
        obs = %TransferObservation{
          id: record.id,
          source_classification: record.source_classification,
          target_classification: record.target_classification,
          adaptation_strategy: record.adaptation_strategy,
          semantic_distance: record.transfer_distance,
          target_constraints: record.target_constraints,
          reuse_count: record.reuse_count,
          number_of_steps: record.number_of_steps,
          success: record.success,
          created_at: record.created_at || DateTime.utc_now()
        }
        record_observation(obs)
        if record.success, do: {:success, record}, else: {:failure, record}
      err ->
        {:failure, err}
    end
  end

  @doc """
  Get current transfer ecology metrics.
  """
  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  @doc """
  Get transfer success matrix.
  """
  def get_transfer_matrix do
    GenServer.call(__MODULE__, :get_transfer_matrix)
  end

  @doc """
  Get all recorded transfer events (observations).
  """
  def get_all_events do
    GenServer.call(__MODULE__, :get_all_events)
  end

  @doc """
  Get classification transferability scores.
  """
  def get_classification_transferability do
    GenServer.call(__MODULE__, :get_classification_transferability)
  end

  @doc """
  Get semantic distance distribution analysis.
  """
  def get_semantic_distance_distribution do
    GenServer.call(__MODULE__, :get_semantic_distance_distribution)
  end

  @doc """
  Generate transfer-based law candidates.
  Phase 5E: Analyzes historical transfer event log to discover stable engineering principles.
  """
  def generate_law_candidates do
    GenServer.call(__MODULE__, :generate_law_candidates)
  end

  # Callbacks

  @impl true
  def init(state) do
    IO.puts("✅ Transfer Ecology observer initialized")
    {:ok, state}
  end

  @impl true
  def handle_cast(:record_aborted, state) do
    {:noreply, %{state | aborted_attempts: state.aborted_attempts + 1}}
  end

  @impl true
  def handle_call({:record_observation, observation}, _from, state) do
    # Add observation
    updated_observations = [observation | state.observations] |> Enum.take(1000)

    # Update transfer matrix
    updated_matrix = update_transfer_matrix(state.transfer_matrix, observation)

    # Update classification transferability
    updated_transferability = update_classification_transferability(
      state.classification_transferability,
      observation
    )

    # Update strategy efficiency
    updated_strategy = update_strategy_efficiency(
      Map.get(state, :strategy_efficiency, %{}),
      observation
    )

    # Update semantic distance buckets
    updated_buckets = update_semantic_distance_buckets(state.semantic_distance_buckets, observation)

    # Phase 5C.3 - Track ecological diversity
    source_sig = get_classification_signature(observation.source_classification)
    target_sig = get_classification_signature(observation.target_classification)
    
    updated_source_classes = MapSet.put(state.source_classifications, source_sig)
    updated_target_classes = MapSet.put(state.target_classifications, target_sig)
    
    # Track same-class vs cross-class transfers
    is_same_class = source_sig == target_sig
    updated_same_class = if is_same_class, do: state.same_class_transfers + 1, else: state.same_class_transfers
    updated_cross_class = if not is_same_class, do: state.cross_class_transfers + 1, else: state.cross_class_transfers
    updated_cross_class_successes = if (not is_same_class) and observation.success, do: state.cross_class_successes + 1, else: state.cross_class_successes
    
    # Phase 5C.4 - Track domain distribution for entropy calculation
    # Extract domain from target classification signature (e.g., "implementation.concurrency.deadlock" -> :concurrency)
    target_sig = get_classification_signature(observation.target_classification)
    failure_domain = extract_domain_from_signature(target_sig)
    
    # Debug logging for first 10 observations
    if state.total_attempts < 10 do
      IO.puts("🔍 [DEBUG] target_sig=#{inspect(target_sig)}, failure_domain=#{inspect(failure_domain)}")
    end
    
    updated_domain_dist = Map.update(state.domain_distribution, failure_domain, 1, &(&1 + 1))
    
    # Phase 5C.6 - Track species ecology
    # Extract species from target classification (same as domain for now)
    species_id = failure_domain
    
    # Track species birth (every new transfer attempt is a "birth")
    updated_species_births = Map.update(state.species_births, species_id, 1, &(&1 + 1))
    
    # Track species survival (successful transfer = survival)
    updated_species_survivals = if observation.success do
      Map.update(state.species_survivals, species_id, 1, &(&1 + 1))
    else
      state.species_survivals
    end
    
    # Track species transfers
    updated_species_transfers_attempted = Map.update(state.species_transfers_attempted, species_id, 1, &(&1 + 1))
    updated_species_transfers_successful = if observation.success do
      Map.update(state.species_transfers_successful, species_id, 1, &(&1 + 1))
    else
      state.species_transfers_successful
    end

    # Update totals
    new_state = %{
      state
      | observations: updated_observations,
        transfer_matrix: updated_matrix,
        strategy_efficiency: updated_strategy,
        classification_transferability: updated_transferability,
        semantic_distance_buckets: updated_buckets,
        total_attempts: state.total_attempts + 1,
        total_successes: if(observation.success, do: state.total_successes + 1, else: state.total_successes),
        # Phase 5C.3 - Ecological diversity metrics
        source_classifications: updated_source_classes,
        target_classifications: updated_target_classes,
        same_class_transfers: updated_same_class,
        cross_class_transfers: updated_cross_class,
        cross_class_successes: updated_cross_class_successes,
        # Phase 5C.4 - Domain distribution
        domain_distribution: updated_domain_dist,
        # Phase 5C.6 - Species ecology tracking
        species_births: updated_species_births,
        species_survivals: updated_species_survivals,
        species_transfers_attempted: updated_species_transfers_attempted,
        species_transfers_successful: updated_species_transfers_successful
    }

    # Log every 10 observations
    if rem(new_state.total_attempts, 10) == 0 do
      success_rate = if new_state.total_attempts > 0, do: new_state.total_successes / new_state.total_attempts, else: 0.0
      IO.puts("🌍 [TransferEcology] #{new_state.total_attempts} attempts, #{Float.round(success_rate * 100, 1)}% success rate")
    end

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_hypothesis_gaps, _from, state) do
    events = state.observations
    
    distance_buckets = 
      events
      |> Enum.group_by(fn e -> 
        case Map.get(e, :semantic_distance, 0.5) do
          d when d < 0.3 -> :close
          d when d < 0.7 -> :medium
          _ -> :far
        end
      end)
      |> Enum.map(fn {k, v} -> {k, length(v)} end)
      |> Map.new()
      |> Map.put_new(:close, 0)
      |> Map.put_new(:medium, 0)
      |> Map.put_new(:far, 0)

    domain_buckets = 
      events
      |> Enum.group_by(fn e -> 
        src_domain = get_in(e, [Access.key(:source_classification, %{}), Access.key(:domain)])
        tgt_domain = get_in(e, [Access.key(:target_classification, %{}), Access.key(:domain)])
        if src_domain == tgt_domain and not is_nil(src_domain), do: :in_domain, else: :cross_domain 
      end)
      |> Enum.map(fn {k, v} -> {k, length(v)} end)
      |> Map.new()
      |> Map.put_new(:in_domain, 0)
      |> Map.put_new(:cross_domain, 0)

    gaps = %{
      distance_buckets: distance_buckets,
      domain_buckets: domain_buckets,
      total_events: length(events)
    }

    {:reply, gaps, state}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    # Phase 5C.3 - Calculate comprehensive ecological metrics
    source_class_count = MapSet.size(state.source_classifications)
    target_class_count = MapSet.size(state.target_classifications)
    
    # Calculate classification distributions for entropy
    source_distribution = calculate_classification_distribution(state.observations, :source)
    target_distribution = calculate_classification_distribution(state.observations, :target)
    
    source_entropy = calculate_entropy(source_distribution)
    target_entropy = calculate_entropy(target_distribution)
    
    # Matrix density
    possible_cells = source_class_count * target_class_count
    matrix_density = if possible_cells > 0 do
      map_size(state.transfer_matrix) / possible_cells * 100
    else
      0.0
    end
    
    # Cross-class transfer rates
    cross_class_rate = if state.total_attempts > 0 do
      state.cross_class_transfers / state.total_attempts * 100
    else
      0.0
    end
    
    cross_class_success_rate = if state.cross_class_transfers > 0 do
      state.cross_class_successes / state.cross_class_transfers * 100
    else
      0.0
    end
    
    same_class_rate = if state.total_attempts > 0 do
      state.same_class_transfers / state.total_attempts * 100
    else
      0.0
    end
    
    # Phase 5C.4 - Domain entropy
    domain_entropy = calculate_entropy(state.domain_distribution)
    unique_domains = map_size(state.domain_distribution)
    
    # Phase 5C.6 - Species fitness calculation
    species_fitness_map = calculate_species_fitness_map(state)
    species_entropy = SpeciesFitness.calculate_species_entropy(species_fitness_map)
    dominant_species = SpeciesFitness.get_dominant_species(species_fitness_map)
    declining_species = SpeciesFitness.get_declining_species(species_fitness_map)
    extinction_watch_species = SpeciesFitness.get_extinction_watch_species(species_fitness_map)

    metrics = %{
      # Basic metrics
      total_attempts: state.total_attempts,
      total_successes: state.total_successes,
      transfer_success_rate: if(state.total_attempts > 0, do: state.total_successes / state.total_attempts, else: 0.0),
      matrix_cells_populated: map_size(state.transfer_matrix),
      strategy_efficiency: calculate_strategy_efficiency(Map.get(state, :strategy_efficiency, %{})),
      classifications_tracked: map_size(state.classification_transferability),
      knowledge_diffusion_rate: calculate_knowledge_diffusion_rate(state),

      # Phase 5G - Compute Conservation
      aborted_attempts: state.aborted_attempts,
      compute_conservation_ratio: calculate_ccr(state.aborted_attempts, state.total_attempts),
      
      # Phase 5C.3 - Ecological Diversity Metrics
      unique_source_classes: source_class_count,
      unique_target_classes: target_class_count,
      source_entropy: Float.round(source_entropy, 3),
      target_entropy: Float.round(target_entropy, 3),
      matrix_density: Float.round(matrix_density, 2),
      
      # Phase 5C.4 - Domain Entropy Metrics
      domain_entropy: Float.round(domain_entropy, 3),
      unique_domains: unique_domains,
      domain_distribution: state.domain_distribution,
      
      # Cross-class transfer metrics
      same_class_transfers: state.same_class_transfers,
      cross_class_transfers: state.cross_class_transfers,
      cross_class_successes: state.cross_class_successes,
      same_class_rate: Float.round(same_class_rate, 2),
      cross_class_rate: Float.round(cross_class_rate, 2),
      cross_class_success_rate: Float.round(cross_class_success_rate, 2)
    }

    {:reply, metrics, state}
  end

  @impl true
  def handle_call(:get_transfer_matrix, _from, state) do
    {:reply, state.transfer_matrix, state}
  end

  @impl true
  def handle_call(:get_all_events, _from, state) do
    {:reply, state.observations, state}
  end

  @impl true
  def handle_call(:get_classification_transferability, _from, state) do
    {:reply, state.classification_transferability, state}
  end

  @impl true
  def handle_call(:get_semantic_distance_distribution, _from, state) do
    distribution = calculate_distance_weighted_success_rates(state.semantic_distance_buckets)
    {:reply, distribution, state}
  end

  @impl true
  def handle_call(:generate_law_candidates, _from, state) do
    candidates = generate_candidates(state)
    {:reply, candidates, state}
  end

  # Private helpers

  defp calculate_ccr(aborted, executed) do
    total = aborted + executed
    if total > 0 do
      Float.round(aborted / total, 3)
    else
      0.0
    end
  end

  defp update_transfer_matrix(matrix, observation) do
    source_class = get_classification_key(observation.source_classification)
    target_class = get_classification_key(observation.target_classification)

    key = "#{source_class} → #{target_class}"

    current = Map.get(matrix, key, %{attempts: 0, successes: 0})

    updated = %{
      current
      | attempts: current.attempts + 1,
        successes: if(observation.success, do: current.successes + 1, else: current.successes)
    }

    Map.put(matrix, key, updated)
  end

  defp update_classification_transferability(transferability, observation) do
    source_class = get_classification_key(observation.source_classification)

    current = Map.get(transferability, source_class, %{attempts: 0, successes: 0})

    updated = %{
      current
      | attempts: current.attempts + 1,
        successes: if(observation.success, do: current.successes + 1, else: current.successes)
    }

    Map.put(transferability, source_class, updated)
  end

  defp update_strategy_efficiency(strategy_efficiency, observation) do
    strategy = Map.get(observation, :adaptation_strategy, :unknown)

    current = Map.get(strategy_efficiency, strategy, %{attempts: 0, successes: 0})

    updated = %{
      current
      | attempts: current.attempts + 1,
        successes: if(observation.success, do: current.successes + 1, else: current.successes)
    }

    Map.put(strategy_efficiency, strategy, updated)
  end
  
  defp calculate_strategy_efficiency(strategy_efficiency) do
    for {strategy, data} <- strategy_efficiency, into: %{} do
      rate = if data.attempts > 0, do: data.successes / data.attempts, else: 0.0
      {strategy, %{
        attempts: data.attempts,
        successes: data.successes,
        efficiency_rate: Float.round(rate, 3)
      }}
    end
  end

  defp update_semantic_distance_buckets(buckets, observation) do
    distance = observation.semantic_distance || 0.5

    bucket_key = get_bucket_key(distance)

    current = Map.get(buckets, bucket_key, %{attempts: 0, successes: 0})

    updated = %{
      current
      | attempts: current.attempts + 1,
        successes: if(observation.success, do: current.successes + 1, else: current.successes)
    }

    Map.put(buckets, bucket_key, updated)
  end

  defp get_bucket_key(distance) when distance < 0.2, do: "0.0-0.2"
  defp get_bucket_key(distance) when distance < 0.4, do: "0.2-0.4"
  defp get_bucket_key(distance) when distance < 0.6, do: "0.4-0.6"
  defp get_bucket_key(distance) when distance < 0.8, do: "0.6-0.8"
  defp get_bucket_key(_distance), do: "0.8-1.0"

  defp get_classification_key(%{domain: domain, category: category, subcategory: subcategory}) do
    "#{domain}.#{category}.#{subcategory}"
  end

  defp get_classification_key(classification) when is_map(classification) do
    domain = Map.get(classification, :domain, :unknown)
    category = Map.get(classification, :category, :unknown)
    "#{domain}.#{category}"
  end

  defp get_classification_key(_), do: "unknown.unknown"

  defp calculate_distance_weighted_success_rates(buckets) do
    for {bucket, data} <- buckets, into: %{} do
      rate = if data.attempts > 0, do: data.successes / data.attempts, else: 0.0
      {bucket, %{
        attempts: data.attempts,
        successes: data.successes,
        success_rate: Float.round(rate, 3)
      }}
    end
  end

  defp calculate_knowledge_diffusion_rate(state) do
    # Simplified: successful transfers / total attempts
    if state.total_attempts > 0 do
      state.total_successes / state.total_attempts
    else
      0.0
    end
  end

  defp generate_candidates(state) do
    events = state.observations

    if length(events) < @law_min_support do
      []
    else
      candidates = [
        discover_distance_decay_law(events),
        discover_domain_resonance_law(events),
        discover_complexity_penalty_law(events),
        discover_portable_repairs_law(events),
        discover_simplicity_law(events),
        discover_adaptation_strategy_law(events),
        discover_transfer_saturation_law(events),
        discover_repair_diversity_law(events, state)
      ]

      candidates
      |> Enum.reject(&is_nil/1)
      |> Enum.filter(fn candidate -> candidate.support_count >= @law_min_support end)
    end
  end

  # --- Private Law Discovery Algorithms ---

  defp discover_distance_decay_law(events) do
    # Bucket events by semantic distance: Close (<0.3), Medium (0.3-0.7), Far (>0.7)
    buckets =
      events
      |> Enum.group_by(fn e ->
        case e.semantic_distance do
          d when d < 0.3 -> :close
          d when d < 0.7 -> :medium
          _ -> :far
        end
      end)
      |> Enum.map(fn {bucket, evts} ->
        successes = Enum.count(evts, & &1.success)
        total = length(evts)
        {bucket, successes / max(total, 1), total}
      end)
      |> Map.new(fn {k, rate, count} -> {k, %{rate: rate, count: count}} end)

    close_rate = get_in(buckets, [:close, :rate]) || 0.0
    medium_rate = get_in(buckets, [:medium, :rate]) || 0.0
    far_rate = get_in(buckets, [:far, :rate]) || 0.0

    # The Law holds if success rate strictly degrades as distance increases
    if close_rate > medium_rate and medium_rate > far_rate and close_rate > 0.0 do
      total_events = length(events)
      confidence = (close_rate - far_rate) # Higher delta = higher confidence

      %{
        law: "Transfer Success Declines With Semantic Distance",
        evidence: "Close: #{Float.round(close_rate * 100, 1)}% | Medium: #{Float.round(medium_rate * 100, 1)}% | Far: #{Float.round(far_rate * 100, 1)}%",
        support_count: total_events,
        contradiction_count: Enum.count(events, fn e -> e.semantic_distance >= 0.7 and e.success end),
        confidence: Float.round(confidence, 3),
        tags: [:semantic_distance, :transfer_physics]
      }
    else
      nil
    end
  end

  defp discover_domain_resonance_law(events) do
    {in_domain, cross_domain} =
      Enum.split_with(events, fn e ->
        e.source_classification.domain == e.target_classification.domain
      end)

    in_domain_rate = calculate_success_rate(in_domain)
    cross_domain_rate = calculate_success_rate(cross_domain)

    # The Law holds if in-domain transfers are significantly more successful
    if in_domain_rate > cross_domain_rate + 0.15 do # At least 15% delta
      %{
        law: "Domain Resonance Amplifies Transfer Efficacy",
        evidence: "In-Domain: #{Float.round(in_domain_rate * 100, 1)}% vs Cross-Domain: #{Float.round(cross_domain_rate * 100, 1)}%",
        support_count: length(events),
        contradiction_count: Enum.count(cross_domain, & &1.success),
        confidence: Float.round(in_domain_rate - cross_domain_rate, 3),
        tags: [:domain_affinity, :transfer_physics]
      }
    else
      nil
    end
  end

  defp discover_complexity_penalty_law(events) do
    # Group by target complexity (Low: <3 constraints, High: >=3 constraints)
    {low_complexity, high_complexity} =
      Enum.split_with(events, fn e -> length(e.target_constraints || []) < 3 end)

    low_rate = calculate_success_rate(low_complexity)
    high_rate = calculate_success_rate(high_complexity)

    if low_rate > high_rate + 0.20 do # 20% delta
      %{
        law: "Target Architectural Complexity Imposes a Transfer Penalty",
        evidence: "Low Complexity: #{Float.round(low_rate * 100, 1)}% vs High Complexity: #{Float.round(high_rate * 100, 1)}%",
        support_count: length(events),
        contradiction_count: Enum.count(high_complexity, & &1.success),
        confidence: Float.round(low_rate - high_rate, 3),
        tags: [:complexity, :transfer_physics]
      }
    else
      nil
    end
  end

  defp discover_portable_repairs_law(events) do
    {portable, specialized} =
      Enum.split_with(events, fn e -> (e.reuse_count || 0) >= 3 end)

    portable_rate = calculate_success_rate(portable)
    specialized_rate = calculate_success_rate(specialized)

    if portable_rate > specialized_rate + 0.15 do
      %{
        law: "Portable Repairs Outlive Specialized Repairs",
        evidence: "Portable (>3 reuses): #{Float.round(portable_rate * 100, 1)}% vs Specialized: #{Float.round(specialized_rate * 100, 1)}%",
        support_count: length(events),
        contradiction_count: Enum.count(specialized, & &1.success),
        confidence: Float.round(portable_rate - specialized_rate, 3),
        tags: [:portability, :survival]
      }
    else
      nil
    end
  end

  defp discover_simplicity_law(events) do
    {simple, complex} =
      Enum.split_with(events, fn e -> (e.number_of_steps || 0) <= 2 end)

    simple_rate = calculate_success_rate(simple)
    complex_rate = calculate_success_rate(complex)

    if simple_rate > complex_rate + 0.15 do
      %{
        law: "Repair Simplicity Improves Transferability",
        evidence: "Simple (<=2 steps): #{Float.round(simple_rate * 100, 1)}% vs Complex: #{Float.round(complex_rate * 100, 1)}%",
        support_count: length(events),
        contradiction_count: Enum.count(complex, & &1.success),
        confidence: Float.round(simple_rate - complex_rate, 3),
        tags: [:simplicity, :modularity]
      }
    else
      nil
    end
  end

  defp discover_adaptation_strategy_law(events) do
    by_strategy = Enum.group_by(events, & &1.adaptation_strategy)

    rates = Enum.map(by_strategy, fn {strat, evts} ->
      {strat, calculate_success_rate(evts), length(evts)}
    end)
    |> Enum.filter(fn {_, _, count} -> count >= 5 end)
    |> Enum.sort_by(fn {_, rate, _} -> rate end, :desc)

    case rates do
      [{best_strat, best_rate, _}, {runner_up_strat, runner_up_rate, _} | _] when best_rate > runner_up_rate + 0.15 ->
        %{
          law: "#{humanize_strategy(best_strat)} Outperforms #{humanize_strategy(runner_up_strat)}",
          evidence: "#{humanize_strategy(best_strat)}: #{Float.round(best_rate * 100, 1)}% vs #{humanize_strategy(runner_up_strat)}: #{Float.round(runner_up_rate * 100, 1)}%",
          support_count: length(events),
          contradiction_count: 0, # approximation
          confidence: Float.round(best_rate - runner_up_rate, 3),
          tags: [:adaptation_strategy, :mechanisms]
        }
      _ ->
        nil
    end
  end

  defp calculate_success_rate([]), do: 0.0
  defp calculate_success_rate(events) do
    Enum.count(events, & &1.success) / length(events)
  end

  defp humanize_strategy(:parameter_adaptation), do: "Parameter Adaptation"
  defp humanize_strategy(:constraint_adaptation), do: "Constraint Adaptation"
  defp humanize_strategy(:classification_adaptation), do: "Classification Adaptation"
  defp humanize_strategy(:decomposition_adaptation), do: "Decomposition Adaptation"
  defp humanize_strategy(other), do: inspect(other)

  defp get_classification_signature(%{signature: sig}) when is_binary(sig), do: sig
  defp get_classification_signature(%{domain: d, category: c, subcategory: s}) do
    "#{d}.#{c}.#{s}"
  end
  defp get_classification_signature(_), do: "unknown.unknown.unknown"

  def calculate_entropy(distribution) when is_map(distribution) do
    total = Map.values(distribution) |> Enum.sum()
    
    if total == 0 do
      0.0
    else
      distribution
      |> Map.values()
      |> Enum.map(fn count ->
        p = count / total
        if p > 0, do: -p * :math.log2(p), else: 0.0
      end)
      |> Enum.sum()
    end
  end

  def calculate_entropy(list) when is_list(list) do
    list |> Enum.frequencies() |> calculate_entropy()
  end

  defp discover_transfer_saturation_law(events) do
    total = length(events)
    if total < 60 do
      nil
    else
      {early, late} = Enum.split(events, div(total, 2))
      early_rate = calculate_success_rate(early)
      late_rate = calculate_success_rate(late)

      if late_rate > early_rate + 0.10 do
        %{
          law: "Transfer Saturation Law: Larger Ecology Improves Transferability",
          evidence: "Early Rate: #{Float.round(early_rate * 100, 1)}% vs Late Rate: #{Float.round(late_rate * 100, 1)}%",
          support_count: total,
          contradiction_count: Enum.count(early, & &1.success),
          confidence: Float.round(late_rate - early_rate, 3),
          tags: [:ecology_saturation, :transfer_physics]
        }
      else
        nil
      end
    end
  end

  defp discover_repair_diversity_law(events, state) do
    entropy = calculate_entropy(state.domain_distribution || %{})
    
    if entropy > 1.5 do
      success_rate = calculate_success_rate(events)
      if success_rate > 0.20 do
        %{
          law: "Repair Diversity Law: Higher Entropy Accelerates Adaptation",
          evidence: "Entropy: #{Float.round(entropy, 2)} -> Success Rate: #{Float.round(success_rate * 100, 1)}%",
          support_count: length(events),
          contradiction_count: Enum.count(events, fn e -> not e.success end),
          confidence: Float.round(success_rate, 3),
          tags: [:repair_diversity, :transfer_physics]
        }
      else
        nil
      end
    else
      nil
    end
  end

  # Phase 5C.3 - Helper functions for ecological metrics

  defp calculate_classification_distribution(observations, type) do
    observations
    |> Enum.map(fn obs ->
      case type do
        :source -> get_classification_signature(obs.source_classification)
        :target -> get_classification_signature(obs.target_classification)
      end
    end)
    |> Enum.frequencies()
  end
  
  # Phase 5C.6 - Calculate species fitness map from ecology state
  defp calculate_species_fitness_map(state) do
    # Get all unique species IDs
    all_species_ids = Map.keys(state.species_births)
    
    # Calculate fitness for each species
    Enum.map(all_species_ids, fn species_id ->
      births = Map.get(state.species_births, species_id, 0)
      survivals = Map.get(state.species_survivals, species_id, 0)
      repairs_attempted = Map.get(state.species_repairs_attempted, species_id, 0)
      repairs_successful = Map.get(state.species_repairs_successful, species_id, 0)
      transfers_attempted = Map.get(state.species_transfers_attempted, species_id, 0)
      transfers_successful = Map.get(state.species_transfers_successful, species_id, 0)
      extinctions = Map.get(state.species_extinctions, species_id, 0)
      
      species_data = %{
        species_id: species_id,
        generation: 1,  # Simplified for now
        births: births,
        survivals: survivals,
        extinctions: extinctions,
        repairs_attempted: repairs_attempted,
        repairs_successful: repairs_successful,
        transfers_attempted: transfers_attempted,
        transfers_successful: transfers_successful,
        average_recovery_latency_ms: 0.0  # Not tracked yet
      }
      
      fitness_record = SpeciesFitness.calculate_fitness(species_data)
      {species_id, fitness_record.fitness_score}
    end)
    |> Enum.into(%{})
  end
  
  # Phase 5C.4 - Extract ecological domain from classification signature
  # e.g., "implementation.concurrency.deadlock" or "implementation:concurrency:deadlock" -> :concurrency
  defp extract_domain_from_signature(sig) when is_binary(sig) do
    cond do
      String.contains?(sig, ".security.") or String.contains?(sig, ":security:") -> :security
      String.contains?(sig, ".data.") or String.contains?(sig, ":data:") -> :data
      String.contains?(sig, ".concurrency.") or String.contains?(sig, ":concurrency:") -> :concurrency
      String.contains?(sig, ".performance.") or String.contains?(sig, ":performance:") -> :performance
      String.contains?(sig, ".dependency.") or String.contains?(sig, ":dependency:") -> :dependency
      String.contains?(sig, ".interface.") or String.contains?(sig, ":interface:") -> :interface
      String.contains?(sig, ".boundary.") or String.contains?(sig, ":boundary:") or String.contains?(sig, ".null_safety.") or String.contains?(sig, ":null_safety:") -> :logic
      String.contains?(sig, ".resource.") or String.contains?(sig, ":resource:") -> :resource
      String.contains?(sig, ".consistency.") or String.contains?(sig, ":consistency:") -> :consistency
      String.contains?(sig, ".state.") or String.contains?(sig, ":state:") -> :state
      true -> :unknown
    end
  end
  defp extract_domain_from_signature(_), do: :unknown
end
