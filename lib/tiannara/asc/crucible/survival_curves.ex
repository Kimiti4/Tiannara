defmodule Tiannara.ASC.Crucible.SurvivalCurves do
  @moduledoc """
  Survival Curves — tracks survival rates across generations to identify architectural longevity patterns.

  Instead of static averages like `survival_rate = 0.73`, this module tracks:
  - Generation 1 → 0.82
  - Generation 2 → 0.79
  - Generation 3 → 0.76
  - ...

  Then fits survival(t) curves to discover:
  - Short-lived architectures (rapid decay)
  - Long-lived architectures (slow decay)
  - Immortal architectures (stable or improving)

  ## Example

      iex> curves = %Tiannara.ASC.Crucible.SurvivalCurves{}
      iex> {:ok, updated} = Tiannara.ASC.Crucible.SurvivalCurves.record_generation(updated, "gen_001", 0.82)
      iex> {:ok, updated} = Tiannara.ASC.Crucible.SurvivalCurves.record_generation(updated, "gen_002", 0.79)
      iex> analysis = Tiannara.ASC.Crucible.SurvivalCurves.analyze_trends(updated)
      iex> analysis.longevity_class
      :long_lived

  """

  @derive Jason.Encoder
  defstruct [
    # Survival data points
    generation_data: [],        # [%{generation_id, generation_number, survival_rate, timestamp}]

    # Fitted curve parameters
    curve_type: nil,            # :exponential_decay | :logistic | :stable | :improving
    decay_rate: 0.0,            # Rate of survival decline (if decaying)
    half_life: 0.0,             # Generations until 50% survival (if applicable)
    asymptote: 0.0,             # Long-term survival rate

    # Classification
    longevity_class: nil,       # :short_lived | :long_lived | :immortal
    stability_score: 0.0,       # How stable is survival (0.0-1.0, higher = more stable)

    # Predictions
    predicted_survival_at_gen_10: 0.0,
    predicted_survival_at_gen_50: 0.0,
    predicted_survival_at_gen_100: 0.0,

    # Metadata
    total_generations_tracked: 0,
    first_generation_at: nil,
    last_updated_at: nil
  ]

  @typedoc "Survival curves tracker"
  @type t :: %__MODULE__{
          generation_data: [map()],
          curve_type: atom() | nil,
          decay_rate: float(),
          half_life: float(),
          asymptote: float(),
          longevity_class: atom() | nil,
          stability_score: float(),
          predicted_survival_at_gen_10: float(),
          predicted_survival_at_gen_50: float(),
          predicted_survival_at_gen_100: float(),
          total_generations_tracked: non_neg_integer(),
          first_generation_at: DateTime.t() | nil,
          last_updated_at: DateTime.t() | nil
        }

  @doc """
  Initialize a new survival curves tracker.
  """
  def new do
    %__MODULE__{
      first_generation_at: DateTime.utc_now(),
      last_updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Record survival rate for a generation.
  """
  def record_generation(%__MODULE__{} = curves, generation_id, survival_rate, generation_number \\ nil) do
    data_point = %{
      generation_id: generation_id,
      generation_number: generation_number || length(curves.generation_data) + 1,
      survival_rate: survival_rate,
      timestamp: DateTime.utc_now()
    }

    updated_curves = %{
      curves
      | generation_data: [data_point | curves.generation_data],
        total_generations_tracked: curves.total_generations_tracked + 1,
        last_updated_at: DateTime.utc_now()
    }

    # Refit curve if enough data
    updated_curves =
      if updated_curves.total_generations_tracked >= 3 do
        fit_curve(updated_curves)
      else
        updated_curves
      end

    {:ok, updated_curves}
  end

  @doc """
  Analyze survival trends and classify longevity.
  """
  def analyze_trends(%__MODULE__{} = curves) do
    if length(curves.generation_data) < 3 do
      %{
        status: :insufficient_data,
        message: "Need at least 3 generations for trend analysis",
        generations_tracked: curves.total_generations_tracked
      }
    else
      # Sort by generation number
      sorted_data = Enum.sort_by(curves.generation_data, & &1.generation_number)

      # Calculate trend
      trend = calculate_trend(sorted_data)

      # Classify longevity
      longevity_class = classify_longevity(trend, curves.decay_rate, curves.asymptote)

      # Calculate stability
      stability_score = calculate_stability(sorted_data)

      # Make predictions
      predictions = predict_future_survival(curves, sorted_data)

      %{
        status: :analyzed,
        trend: trend,
        longevity_class: longevity_class,
        stability_score: stability_score,
        decay_rate: curves.decay_rate,
        half_life: curves.half_life,
        asymptote: curves.asymptote,
        predictions: predictions,
        generations_analyzed: length(sorted_data)
      }
    end
  end

  @doc """
  Get survival rate at specific generation.
  """
  def get_survival_at_generation(%__MODULE__{} = curves, generation_number) do
    case Enum.find(curves.generation_data, &(&1.generation_number == generation_number)) do
      nil -> nil
      data -> data.survival_rate
    end
  end

  @doc """
  Get all survival data points sorted by generation.
  """
  def get_sorted_data(%__MODULE__{} = curves) do
    Enum.sort_by(curves.generation_data, & &1.generation_number)
  end

  @doc """
  Calculate mean survival rate across all generations.
  """
  def mean_survival_rate(%__MODULE__{} = curves) do
    if length(curves.generation_data) == 0 do
      0.0
    else
      rates = Enum.map(curves.generation_data, & &1.survival_rate)
      Float.round(Enum.sum(rates) / length(rates), 3)
    end
  end

  @doc """
  Calculate survival rate variance (measure of volatility).
  """
  def survival_variance(%__MODULE__{} = curves) do
    if length(curves.generation_data) < 2 do
      0.0
    else
      rates = Enum.map(curves.generation_data, & &1.survival_rate)
      mean = Enum.sum(rates) / length(rates)
      variance = Enum.sum_by(rates, fn r -> :math.pow(r - mean, 2) end) / length(rates)
      Float.round(variance, 4)
    end
  end

  # Private helpers

  defp calculate_trend(sorted_data) do
    # Simple linear regression on survival rates
    n = length(sorted_data)
    x_values = Enum.map(sorted_data, & &1.generation_number)
    y_values = Enum.map(sorted_data, & &1.survival_rate)

    x_mean = Enum.sum(x_values) / n
    y_mean = Enum.sum(y_values) / n

    numerator = Enum.zip(x_values, y_values)
                |> Enum.map(fn {x, y} -> (x - x_mean) * (y - y_mean) end)
                |> Enum.sum()

    denominator = Enum.map(x_values, fn x -> :math.pow(x - x_mean, 2) end)
                  |> Enum.sum()

    slope = if denominator > 0, do: numerator / denominator, else: 0.0

    cond do
      slope > 0.01 -> :improving
      slope < -0.01 -> :declining
      true -> :stable
    end
  end

  defp fit_curve(%__MODULE__{} = curves) do
    sorted_data = Enum.sort_by(curves.generation_data, & &1.generation_number)
    rates = Enum.map(sorted_data, & &1.survival_rate)

    # Determine curve type based on pattern
    curve_type = determine_curve_type(rates)

    # Fit parameters
    {decay_rate, half_life, asymptote} = fit_parameters(rates, curve_type)

    %{
      curves
      | curve_type: curve_type,
        decay_rate: Float.round(decay_rate, 4),
        half_life: Float.round(half_life, 2),
        asymptote: Float.round(asymptote, 3)
    }
  end

  defp determine_curve_type(rates) do
    # Check if improving
    if Enum.at(rates, -1) > Enum.at(rates, 0) + 0.05 do
      :improving
    else
      # Check if stable
      variance = survival_variance_from_rates(rates)
      if variance < 0.01 do
        :stable
      else
        # Assume exponential decay
        :exponential_decay
      end
    end
  end

  defp fit_parameters(rates, curve_type) do
    case curve_type do
      :exponential_decay ->
        # Fit S(t) = S0 * e^(-λt)
        initial = Enum.at(rates, 0) || 1.0
        final = List.last(rates) || 0.5

        # Estimate decay rate
        n = length(rates)
        if final > 0 && initial > 0 do
          decay_rate = -(:math.log(final / initial) / n)
          half_life = :math.log(2) / decay_rate
          {decay_rate, half_life, 0.0}
        else
          {0.1, 7.0, 0.0}
        end

      :stable ->
        # Stable around mean
        mean = Enum.sum(rates) / length(rates)
        {0.0, :infinity, mean}

      :improving ->
        # Improving toward 1.0
        {0.0, :infinity, 1.0}

      _ ->
        {0.1, 7.0, 0.5}
    end
  end

  defp classify_longevity(trend, decay_rate, asymptote) do
    cond do
      trend == :improving ->
        :immortal

      trend == :stable && asymptote > 0.7 ->
        :immortal

      trend == :stable ->
        :long_lived

      decay_rate > 0.2 ->
        :short_lived

      decay_rate > 0.05 ->
        :long_lived

      true ->
        :long_lived
    end
  end

  defp calculate_stability(sorted_data) do
    if length(sorted_data) < 2 do
      1.0
    else
      rates = Enum.map(sorted_data, & &1.survival_rate)
      variance = survival_variance_from_rates(rates)

      # Convert variance to stability score (lower variance = higher stability)
      stability = 1.0 / (1.0 + variance * 10)
      Float.round(stability, 3)
    end
  end

  defp predict_future_survival(curves, sorted_data) do
    case curves.curve_type do
      :exponential_decay ->
        # S(t) = S0 * e^(-λt)
        initial = Enum.at(sorted_data, 0).survival_rate
        lambda = curves.decay_rate

        %{
          gen_10: Float.round(initial * :math.exp(-lambda * 10), 3),
          gen_50: Float.round(initial * :math.exp(-lambda * 50), 3),
          gen_100: Float.round(initial * :math.exp(-lambda * 100), 3)
        }

      :stable ->
        # Constant at asymptote
        %{
          gen_10: curves.asymptote,
          gen_50: curves.asymptote,
          gen_100: curves.asymptote
        }

      :improving ->
        # Approaching 1.0
        current = List.last(sorted_data).survival_rate
        %{
          gen_10: min(current + 0.05, 1.0),
          gen_50: min(current + 0.15, 1.0),
          gen_100: min(current + 0.25, 1.0)
        }

      _ ->
        %{gen_10: 0.5, gen_50: 0.5, gen_100: 0.5}
    end
  end

  defp survival_variance_from_rates(rates) do
    if length(rates) < 2 do
      0.0
    else
      mean = Enum.sum(rates) / length(rates)
      variance = Enum.sum_by(rates, fn r -> :math.pow(r - mean, 2) end) / length(rates)
      variance
    end
  end
end
