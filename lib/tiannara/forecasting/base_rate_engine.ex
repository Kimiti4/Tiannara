defmodule Tiannara.Forecasting.BaseRateEngine do
  @moduledoc """
  D2 base-rate interface.

  Represents a reference-class base rate (historical frequency) and exposes it so
  a forecast can be compared against it WITHOUT automatically privileging either
  the base rate or current evidence.

  Records explicitly when base-rate data is unavailable (in which case
  `historical_frequency` is `:unknown`, distinct from `0.0`).
  """

  alias Tiannara.Forecasting.Contracts.BaseRate
  alias Tiannara.Constraints

  @type t :: BaseRate.t()

  @spec new(map() | Keyword.t()) :: BaseRate.t()
  def new(attrs) when is_map(attrs) or is_list(attrs) do
    m = Map.new(attrs)
    %BaseRate{
      reference_class: Map.get(m, :reference_class),
      historical_frequency: Map.get(m, :historical_frequency) || :unknown,
      sample_size: Map.get(m, :sample_size),
      selection_conditions: Map.get(m, :selection_conditions),
      regime_conditions: Map.get(m, :regime_conditions),
      confidence: Map.get(m, :confidence),
      source: Map.get(m, :source),
      data_quality: Map.get(m, :data_quality),
      base_rate_uncertainty: Map.get(m, :base_rate_uncertainty)
    }
  end

  @doc "Returns {:ok, valid_base_rate} or {:error, reason}."
  @spec validate(BaseRate.t()) :: {:ok, BaseRate.t()} | {:error, term()}
  def validate(%BaseRate{} = br) do
    cond do
      is_nil(br.reference_class) ->
        {:error, :missing_reference_class}

      br.historical_frequency != :unknown and not is_number(br.historical_frequency) ->
        {:error, :invalid_historical_frequency}

      br.historical_frequency != :unknown and
          (br.historical_frequency < 0 or br.historical_frequency > 1) ->
        {:error, :frequency_out_of_bounds}

      true ->
        {:ok, br}
    end
  end

  @doc "True when base-rate data exists (historical_frequency is a number)."
  @spec available?(BaseRate.t()) :: boolean()
  def available?(%BaseRate{historical_frequency: f}) when is_number(f), do: true
  def available?(_), do: false

  @doc """
  Returns base rate and current evidence frequencies side by side, without
  preferring either. Each is `number | :unknown`.
  """
  @spec compare(BaseRate.t(), number() | :unknown) :: map()
  def compare(%BaseRate{} = br, current_evidence_freq) do
    %{
      base_rate: br.historical_frequency,
      current_evidence: current_evidence_freq,
      data_quality: br.data_quality,
      base_rate_uncertainty: br.base_rate_uncertainty
    }
  end

  @doc "Normalizes a base-rate historical frequency into [0,1] (evidence map)."
  @spec normalize_frequency(BaseRate.t()) :: map()
  def normalize_frequency(%BaseRate{historical_frequency: f}) when is_number(f) do
    Constraints.normalize_to([f], 1.0) |> Constraints.evidence_report()
  end

  def normalize_frequency(_), do: %{status: :unknown, result: :unknown}
end
