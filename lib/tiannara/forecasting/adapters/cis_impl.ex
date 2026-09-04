defmodule Tiannara.Forecasting.Adapters.CISImpl do
  @moduledoc """
  D2 concrete implementation of `Tiannara.Forecasting.Adapters.CIS`.

  Provides a forecast-consumption interface to the Cognitive Immune System.
  CIS retains constitutional authority over safety/stability regulation; EFDI
  provides epistemic prediction only. Forecast confidence is NOT authorization.
  """

  @behaviour Tiannara.Forecasting.Adapters.CIS

  alias Tiannara.Forecasting.{Signal}
  alias Tiannara.Forecasting.Adapters.CIS

  @impl CIS
  @spec signal_to_telemetry(Signal.t()) :: {:ok, map()} | {:error, term()}
  def signal_to_telemetry(%Signal{} = s) do
    {:ok,
     %{
       source: s.source,
       domain: s.domain,
       reliability: s.source_reliability,
       timestamp: s.timestamp
     }}
  end

  @impl CIS
  @spec forecast_to_collapse_probability(map()) :: {:ok, float()} | {:error, term()}
  def forecast_to_collapse_probability(%{distribution: dist}) when is_list(dist) do
    # epistemic only: collapse proxy = excess tail weight beyond the mode
    {:ok, collapse_proxy(dist)}
  end

  def forecast_to_collapse_probability(%{probabilities: probs}) when is_list(probs) do
    {:ok, collapse_proxy(probs)}
  end

  def forecast_to_collapse_probability(_), do: {:error, :missing_distribution}

  @impl CIS
  @spec signal_conflict_to_pathogen([Signal.t()]) :: {:ok, map()} | {:error, term()}
  def signal_conflict_to_pathogen(signals) when is_list(signals) and length(signals) < 2 do
    {:error, :insufficient_signals}
  end

  def signal_conflict_to_pathogen(signals) when is_list(signals) do
    {:ok,
     %{
       pathogen_id: "pathogen_#{System.unique_integer([:positive])}",
       conflicting_signal_ids: Enum.map(signals, & &1.id),
       degeneracy_observed: true,
       note: "degeneracy flagged for CIS review; EFDI makes no regulatory decision"
     }}
  end

  defp collapse_proxy(dist) when is_list(dist) and dist != [] do
    max_p = Enum.max(dist)
    total = Enum.sum(dist)
    if total == 0, do: 0.0, else: max(0.0, 1.0 - max_p / total)
  end

  defp collapse_proxy(_), do: 0.0
end