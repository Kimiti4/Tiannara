defmodule Tiannara.RRG.RateLimiter do
  @moduledoc """
  Rate Limiter - Core constraint enforcement for ontological throughput.
  Implements the mathematical formula: ΔO ≤ (C × K × S) / (1 + E)
  Where:
  - ΔO = allowed ontology updates
  - C = cognitive capacity of observer set
  - K = kernel stability factor (from MSCL)
  - S = system coherence score (from OLEF)
  - E = prior exposure entropy (RRG memory)
  """

  @max_delta 100.0

  defstruct [
    :cognitive_capacity,
    :kernel_stability,
    :system_coherence,
    :exposure_entropy,
    :max_allowed_delta
  ]

  def new(opts \\ []) do
    %__MODULE__{
      cognitive_capacity: Keyword.get(opts, :cognitive_capacity, 1.0),
      kernel_stability: Keyword.get(opts, :kernel_stability, 1.0),
      system_coherence: Keyword.get(opts, :system_coherence, 1.0),
      exposure_entropy: Keyword.get(opts, :exposure_entropy, 0.0),
      max_allowed_delta: Keyword.get(opts, :max_allowed_delta, @max_delta)
    }
  end

  def allow?(ontology_delta, state) when is_number(ontology_delta) and is_map(state) do
    exposure = Map.get(state, :exposure_entropy, 0.0)
    coherence = Map.get(state, :coherence, 1.0)
    capacity = Map.get(state, :cognitive_capacity, 1.0)
    stability = Map.get(state, :kernel_stability, 1.0)

    limit = calculate_limit(capacity, coherence, stability, exposure)

    ontology_delta <= min(limit, @max_delta)
  end

  def allow?(ontology_delta, %__MODULE__{} = rate_limiter) when is_number(ontology_delta) do
    limit = calculate_limit(
      rate_limiter.cognitive_capacity,
      rate_limiter.system_coherence,
      rate_limiter.kernel_stability,
      rate_limiter.exposure_entropy
    )

    ontology_delta <= min(limit, rate_limiter.max_allowed_delta)
  end

  defp calculate_limit(cognitive_capacity, system_coherence, kernel_stability, exposure_entropy) do
    (cognitive_capacity * system_coherence * kernel_stability) / (1 + exposure_entropy)
  end

  def update_cognitive_capacity(rate_limiter, new_capacity) when is_number(new_capacity) do
    %{rate_limiter | cognitive_capacity: new_capacity}
  end

  def update_kernel_stability(rate_limiter, new_stability) when is_number(new_stability) do
    %{rate_limiter | kernel_stability: new_stability}
  end

  def update_system_coherence(rate_limiter, new_coherence) when is_number(new_coherence) do
    %{rate_limiter | system_coherence: new_coherence}
  end

  def update_exposure_entropy(rate_limiter, new_entropy) when is_number(new_entropy) do
    %{rate_limiter | exposure_entropy: new_entropy}
  end

  def get_current_limit(rate_limiter) do
    calculate_limit(
      rate_limiter.cognitive_capacity,
      rate_limiter.system_coherence,
      rate_limiter.kernel_stability,
      rate_limiter.exposure_entropy
    )
  end

  def get_effective_limit(rate_limiter) do
    min(get_current_limit(rate_limiter), rate_limiter.max_allowed_delta)
  end

  def get_status(rate_limiter, current_delta) when is_number(current_delta) do
    effective_limit = get_effective_limit(rate_limiter)
    allowed = current_delta <= effective_limit
    
    %{
      allowed: allowed,
      current_delta: current_delta,
      effective_limit: effective_limit,
      theoretical_limit: get_current_limit(rate_limiter),
      max_delta: rate_limiter.max_allowed_delta,
      utilization: if(effective_limit > 0, do: current_delta / effective_limit, else: :infinity)
    }
  end
end
