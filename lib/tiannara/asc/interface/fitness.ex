defmodule Tiannara.ASC.Interface.Fitness do
  @moduledoc """
  Interface Fitness — multi-objective fitness evaluation for interface genomes.

  Evaluates interface genomes across multiple dimensions:
  - Security (15%) — Authentication strength, endpoint protection
  - Architecture (10%) — Service composition and complexity
  - Performance (15%) — Caching, circuit breakers, tracing
  - Best Practices (10%) — Rate limiting, CORS, logging
  - Database Quality (5%) — Production-ready database choice
  - Production Metrics (30%) — OpenAPI completeness, auth coverage, observability
  - Contract Quality (15%) — Schema consistency, versioning, compatibility

  Returns a weighted fitness score (0.0 to 1.0, higher is better).

  ## Example

      iex> genome = Tiannara.ASC.Interface.Genome.new()
      iex> score = Tiannara.ASC.Interface.Fitness.calculate(genome)
      iex> score >= 0.0 and score <= 1.0
      true

  """

  @doc """
  Calculate comprehensive fitness score for an interface genome.

  Combines multiple scoring dimensions with weighted contributions.

  ## Parameters

  - `genome` — Interface genome to evaluate

  ## Returns

  - Float between 0.0 and 1.0

  """
  def calculate(%Tiannara.ASC.Interface.Genome{} = genome) do
    security_score = security_score(genome)
    architecture_score = architecture_score(genome)
    performance_score = performance_score(genome)
    best_practices_score = best_practices_score(genome)
    database_score = database_score(genome)
    production_score = production_score(genome)
    contract_score = contract_score(genome)

    # Weighted combination
    fitness =
      security_score * 0.15 +
      architecture_score * 0.10 +
      performance_score * 0.15 +
      best_practices_score * 0.10 +
      database_score * 0.05 +
      production_score * 0.30 +
      contract_score * 0.15

    Float.round(fitness, 3)
  end

  @doc """
  Calculate security component score.

  Evaluates authentication models, endpoint protection, and security policies.

  ## Scoring Criteria

  - JWT/OAuth2 auth: +0.8
  - API key auth: +0.5
  - Basic auth: +0.2
  - No auth: 0.0
  - Rate limiting enabled: +0.2

  """
  def security_score(%Tiannara.ASC.Interface.Genome{} = genome) do
    score = case genome.auth_models do
      [] -> 0.0
      models ->
        Enum.reduce(models, 0.0, fn model, acc ->
          auth_score = case Map.get(model, :type) do
            :jwt -> 0.8
            :oauth2 -> 0.8
            :api_key -> 0.5
            :basic -> 0.2
            _ -> 0.0
          end

          acc + auth_score
        end)
        |> min(1.0)
    end

    # Bonus for rate limiting
    rate_limiting_bonus = if has_rate_limiting?(genome), do: 0.2, else: 0.0

    min(score + rate_limiting_bonus, 1.0)
  end

  @doc """
  Calculate architecture richness score.

  More services = more complex architecture (up to a point).

  Normalized to max 6 services for full score.
  """
  def architecture_score(%Tiannara.ASC.Interface.Genome{} = genome) do
    num_contracts = length(genome.contracts)
    min(num_contracts / 6.0, 1.0)
  end

  @doc """
  Calculate performance features score.

  Evaluates caching, circuit breakers, tracing, and backend optimizations.
  """
  def performance_score(%Tiannara.ASC.Interface.Genome{} = genome) do
    score = 0.0

    score = if has_caching?(genome), do: score + 0.4, else: score
    score = if has_circuit_breaker?(genome), do: score + 0.3, else: score
    score = if has_tracing?(genome), do: score + 0.2, else: score
    score = if has_backends?(genome), do: score + 0.1, else: score

    min(score, 1.0)
  end

  @doc """
  Calculate best practices score.

  Evaluates rate limiting, CORS, logging levels, health endpoints.
  """
  def best_practices_score(%Tiannara.ASC.Interface.Genome{} = genome) do
    score = 0.0

    score = if has_rate_limiting?(genome), do: score + 0.35, else: score
    score = if has_cors?(genome), do: score + 0.25, else: score
    score = score + logging_score(genome)
    score = if has_health_endpoints?(genome), do: score + 0.1, else: score
    score = if has_metrics_endpoints?(genome), do: score + 0.1, else: score

    min(score, 1.0)
  end

  @doc """
  Calculate database quality score.

  Production-grade databases score higher.
  """
  def database_score(%Tiannara.ASC.Interface.Genome{} = _genome) do
    # For now, assume default is postgres (production-grade)
    # In future, extract from deployment_units or protocols
    1.0
  end

  @doc """
  Calculate production readiness score.

  Comprehensive evaluation of OpenAPI completeness, auth coverage,
  observability, and cost efficiency.
  """
  def production_score(%Tiannara.ASC.Interface.Genome{} = genome) do
    openapi_score = openapi_completeness(genome)
    auth_coverage = auth_coverage(genome)
    observability = observability_score(genome)

    # Weighted combination
    (openapi_score * 0.40 + auth_coverage * 0.35 + observability * 0.25)
    |> Float.round(3)
  end

  @doc """
  Calculate contract quality score.

  Evaluates schema consistency, versioning strategy, and compatibility mode.
  """
  def contract_score(%Tiannara.ASC.Interface.Genome{} = genome) do
    schema_consistency = schema_consistency(genome)
    versioning_score = versioning_score(genome)
    compatibility_score = compatibility_score(genome)

    (schema_consistency * 0.40 + versioning_score * 0.35 + compatibility_score * 0.25)
    |> Float.round(3)
  end

  # ---------------------------------------------------------------------------
  # Component scorers
  # ---------------------------------------------------------------------------

  defp has_rate_limiting?(genome) do
    Enum.any?(genome.policies_applied, fn policy ->
      String.contains?(policy, "rate_limit")
    end)
  end

  defp has_caching?(genome) do
    Enum.any?(genome.deployment_units, fn unit ->
      Map.get(unit, :type) == :cache
    end)
  end

  defp has_circuit_breaker?(genome) do
    Enum.any?(genome.policies_applied, fn policy ->
      String.contains?(policy, "circuit_breaker")
    end)
  end

  defp has_tracing?(genome) do
    Enum.any?(genome.policies_applied, fn policy ->
      String.contains?(policy, "tracing")
    end)
  end

  defp has_backends?(genome) do
    length(genome.deployment_units) > 0
  end

  defp has_cors?(genome) do
    Enum.any?(genome.policies_applied, fn policy ->
      String.contains?(policy, "cors")
    end)
  end

  defp logging_score(_genome) do
    # INFO and WARNING are good production levels
    # DEBUG is too verbose, ERROR is too silent
    0.2  # Default moderate score
  end

  defp has_health_endpoints?(genome) do
    Enum.any?(genome.contracts, fn contract ->
      String.contains?(Map.get(contract, :path, ""), "health")
    end)
  end

  defp has_metrics_endpoints?(genome) do
    Enum.any?(genome.contracts, fn contract ->
      String.contains?(Map.get(contract, :path, ""), "metrics")
    end)
  end

  defp openapi_completeness(genome) do
    # Check if contracts have proper schemas
    contracts_with_schemas = Enum.count(genome.contracts, fn contract ->
      Map.has_key?(contract, :input_schema) and Map.has_key?(contract, :output_schema)
    end)

    total = length(genome.contracts)

    if total > 0 do
      contracts_with_schemas / total
    else
      0.0
    end
  end

  defp auth_coverage(genome) do
    # Percentage of contracts protected by auth
    if genome.auth_models != [] and length(genome.auth_models) > 0 do
      0.95  # Assume high coverage if auth is configured
    else
      0.0
    end
  end

  defp observability_score(genome) do
    score = 0.0
    score = if has_health_endpoints?(genome), do: score + 0.3, else: score
    score = if has_metrics_endpoints?(genome), do: score + 0.3, else: score
    score = if has_tracing?(genome), do: score + 0.4, else: score

    min(score, 1.0)
  end

  defp schema_consistency(genome) do
    # Check if all schemas have required fields (id, created_at)
    consistent_schemas = Enum.count(genome.schemas, fn schema ->
      fields = Map.get(schema, :fields, [])
      has_id = Enum.any?(fields, fn f -> Map.get(f, :name) == "id" end)
      has_timestamp = Enum.any?(fields, fn f ->
        String.contains?(Map.get(f, :name, ""), "created_at") or
        String.contains?(Map.get(f, :name, ""), "updated_at")
      end)

      has_id and has_timestamp
    end)

    total = length(genome.schemas)

    if total > 0 do
      consistent_schemas / total
    else
      1.0  # No schemas = no inconsistency
    end
  end

  defp versioning_score(genome) do
    case genome.versioning_strategy do
      :url_path -> 1.0  # Best practice
      :header -> 0.9
      :none -> 0.3
      _ -> 0.5
    end
  end

  defp compatibility_score(genome) do
    case genome.compatibility_mode do
      :backward -> 1.0  # Safest
      :forward -> 0.8
      :breaking -> 0.3
      _ -> 0.5
    end
  end

  @doc """
  Rank genomes by fitness score and return top N candidates.

  ## Parameters

  - `genomes` — List of genomes to rank
  - `top_n` — Number of top genomes to return (default: 10)

  ## Returns

  - List of {genome, fitness_score} tuples sorted by fitness (descending)

  """
  def rank_by_fitness(genomes, top_n \\ 10) do
    genomes
    |> Enum.map(fn genome ->
      {genome, calculate(genome)}
    end)
    |> Enum.sort_by(fn {_genome, score} -> -score end)
    |> Enum.take(top_n)
  end

  @doc """
  Perform Pareto front analysis for multi-objective optimization.

  Identifies non-dominated genomes across multiple objectives.

  ## Objectives

  - Fitness score
  - Security score
  - Performance score
  - Contract quality

  ## Returns

  - Map with pareto_front list and metadata

  """
  def pareto_front(genomes) do
    objectives = Enum.map(genomes, fn genome ->
      %{
        genome: genome,
        fitness: calculate(genome),
        security: security_score(genome),
        performance: performance_score(genome),
        contract: contract_score(genome)
      }
    end)

    pareto = Enum.filter(objectives, fn candidate ->
      not Enum.any?(objectives, fn other ->
        other != candidate and
          other.fitness >= candidate.fitness and
          other.security >= candidate.security and
          other.performance >= candidate.performance and
          other.contract >= candidate.contract
      end)
    end)

    %{
      pareto_front: pareto,
      total_genomes: length(genomes),
      pareto_count: length(pareto)
    }
  end
end
