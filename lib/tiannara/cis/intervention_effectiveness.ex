defmodule Tiannara.Cis.InterventionEffectiveness do
  @moduledoc """
  Tracks intervention effectiveness and predicts collapse probabilities.
  """

  @telemetry_prefix "tiannara.cis.intervention_effectiveness"

  use GenServer

  @type intervention_id :: String.t()
  @type intervention_record :: %{
          id: intervention_id(),
          before_state: map(),
          after_state: map(),
          success: boolean(),
          timestamp: DateTime.t(),
          effectiveness_score: float()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec record_intervention(intervention_record()) :: {:ok, intervention_id()} | {:error, term()}
  def record_intervention(intervention) do
    GenServer.call(__MODULE__, {:record_intervention, intervention})
  end

  @spec get_intervention(intervention_id()) :: {:ok, intervention_record()} | {:error, :not_found}
  def get_intervention(intervention_id) do
    GenServer.call(__MODULE__, {:get_intervention, intervention_id})
  end

  @spec calculate_collapse_probability(map()) :: {:ok, float()} | {:error, term()}
  def calculate_collapse_probability(metrics) do
    entropy_trend = metrics[:entropy_trend]
    dominance_trend = metrics[:dominance_trend]
    niche_loss_rate = metrics[:niche_loss_rate]
    oscillation_frequency = metrics[:oscillation_frequency]
    drift_velocity = metrics[:drift_velocity]

    # Placeholder calculation
    collapse_probability =
      (entropy_trend + dominance_trend + niche_loss_rate + oscillation_frequency + drift_velocity) /
        5.0

    {:ok, collapse_probability}
  end

  @spec emit_telemetry(map()) :: :ok
  def emit_telemetry(metadata) do
    :telemetry.execute([:tiannara, :cis, :collapse_forecast], %{}, metadata)
  end
end
