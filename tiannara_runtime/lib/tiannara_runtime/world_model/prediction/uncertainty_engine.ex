defmodule TiannaraRuntime.WorldModel.Prediction.UncertaintyEngine do
  @moduledoc """
  Phase 17.4.4 — UncertaintyEngine: propagates parameter, measurement, and
  structural uncertainty through a forecast to produce an UncertaintyDistribution.
  """
  alias TiannaraRuntime.WorldModel.Ontology.{WorldModel, Parameter}
  alias TiannaraRuntime.WorldModel.Prediction.{Forecast, UncertaintyDistribution}

  @spec propagate(WorldModel.t(), Forecast.t(), keyword()) ::
    {:ok, UncertaintyDistribution.t()}
  def propagate(%WorldModel{} = world_model, _forecast, opts \\ []) do
    pu = parameter_uncertainty(world_model)
    mu = measurement_uncertainty(world_model)
    su = structure_uncertainty(world_model)

    variance = pu + mu + su
    std_dev = :math.sqrt(variance)
    entropy = compute_entropy(variance)
    sources = ["parameter", "measurement", "structure"]

    UncertaintyDistribution.new(
      variance: variance,
      std_deviation: std_dev,
      distribution_type: :normal,
      entropy: entropy,
      sources: sources,
      metadata: Keyword.get(opts, :metadata, %{})
    )
  end

  @spec parameter_uncertainty(WorldModel.t()) :: float()
  def parameter_uncertainty(%WorldModel{parameters: params}) do
    variances =
      params
      |> Enum.map(fn %Parameter{distribution: dist} ->
        extract_variance(dist)
      end)
      |> Enum.reject(&is_nil/1)

    case variances do
      [] -> 0.01
      vs -> Enum.sum(vs) / length(vs)
    end
  end

  @spec measurement_uncertainty(WorldModel.t()) :: float()
  def measurement_uncertainty(%WorldModel{observation_model: nil}), do: 0.01

  def measurement_uncertainty(%WorldModel{observation_model: obs}) do
    noise = Map.get(obs, :noise_distribution)
    extract_variance(noise)
  end

  @spec structure_uncertainty(WorldModel.t()) :: float()
  def structure_uncertainty(%WorldModel{causal_graph: nil}), do: 0.05

  def structure_uncertainty(%WorldModel{causal_graph: %{edges: edges}}) do
    confidences =
      Enum.map(edges, fn e ->
        Map.get(e, :confidence, 0.5)
      end)

    case confidences do
      [] -> 0.05
      cs ->
        avg_conf = Enum.sum(cs) / length(cs)
        1.0 - avg_conf
    end
  end

  defp extract_variance(nil), do: nil

  defp extract_variance(%{type: :normal, parameters: params}) do
    std = Map.get(params, "std", Map.get(params, :std, 0.1))
    std * std
  end

  defp extract_variance(%{type: :uniform, parameters: params}) do
    low = Map.get(params, "low", Map.get(params, :low, 0.0))
    high = Map.get(params, "high", Map.get(params, :high, 1.0))
    ((high - low) ** 2) / 12.0
  end

  defp extract_variance(_), do: 0.01

  defp compute_entropy(variance) when variance <= 0.0, do: 0.0

  defp compute_entropy(variance) do
    # Entropy of N(μ,σ²): 0.5 * ln(2πeσ²); clamp to 0.0 for narrow distributions
    entropy = 0.5 * :math.log(2.0 * :math.pi() * :math.exp(1.0) * variance)
    if entropy < 0.0, do: 0.0, else: entropy
  end
end
