defmodule Tiannara.Forecasting.Adapters.ResearchImpl do
  @moduledoc """
  D2 concrete implementation of `Tiannara.Forecasting.Adapters.Research`.

  Integrates EFDI signals with the Research Director (priority ingestion)
  without modifying Research Director behavior. Produces priority maps
  compatible with `Tiannara.Research.ResearchDirector.ingest_priorities/1`.
  """

  @behaviour Tiannara.Forecasting.Adapters.Research

  alias Tiannara.Forecasting.{Signal, SignalValue}
  alias Tiannara.Forecasting.Adapters.Research

  @impl Research
  @spec signal_to_priority(Signal.t()) :: {:ok, map()} | {:error, term()}
  def signal_to_priority(%Signal{} = signal) do
    {:ok,
     %{
       domain: signal.domain,
       signal: signal.id,
       score: priority_score(signal),
       id: "priority_#{signal.id}",
       rationale: "EFDI signal #{signal.id} prioritized for #{signal.domain}"
     }}
  end

  @impl Research
  @spec signals_to_priorities([Signal.t()]) :: {:ok, [map()]}
  def signals_to_priorities(signals) when is_list(signals) do
    {:ok, Enum.map(signals, fn s -> elem(signal_to_priority(s), 1) end)}
  end

  @impl Research
  @spec information_gain_estimate(Signal.t(), [map()]) :: {:ok, float()} | {:error, :insufficient_data}
  def information_gain_estimate(%Signal{} = signal, existing) when is_list(existing) do
    case SignalValue.measure(signal) do
      %{information_gain: g} when is_number(g) ->
        {:ok, g}

      _ ->
        if existing == [] do
          {:error, :insufficient_data}
        else
          {:ok, 1.0 / length(existing)}
        end
    end
  end

  @impl Research
  @spec under_observed_regions([Signal.t()]) :: {:ok, [map()]}
  def under_observed_regions(signals) when is_list(signals) do
    by_domain =
      Enum.group_by(signals, & &1.domain)
      |> Enum.map(fn {domain, sigs} -> %{domain: domain, signal_count: length(sigs)} end)

    {:ok, by_domain}
  end

  defp priority_score(%Signal{relevance: r, reliability: rel, predictive_value: pv}) do
    vals = [r, rel, pv] |> Enum.reject(&(&1 == nil or &1 == :unknown))
    if vals == [], do: 0.5, else: Enum.sum(vals) / length(vals)
  end
end